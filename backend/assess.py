from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict, Iterable, Tuple
import json, os, re, unicodedata

router = APIRouter()

# ---------- API models ----------
class AssessReq(BaseModel):
    ingredients: List[str]
    profileId: Optional[str] = None

class AssessResp(BaseModel):
    score: int
    verdict: str
    reasons: List[Dict]

# ---------- Policy loader ----------
def load_policy() -> dict:
    import os, json
    pdir = os.getenv("POLICY_DIR", "backend/policies")
    explicit = os.getenv("POLICY_FILE")
    candidates = [explicit] if explicit else ["policy_v2.json", "policy_v1.json"]
    for name in candidates:
        if not name:
            continue
        path = os.path.join(pdir, name)
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8") as f:
                return json.load(f)
    raise FileNotFoundError(f"No policy file found in {pdir} (tried: {candidates})")


# ---------- Normalization helpers ----------
def _normalize_token(tok: str, policy: Dict) -> str:
    norm = policy.get("normalization", {}) or {}
    s = tok if isinstance(tok, str) else str(tok)
    if (norm.get("unicode") or "").upper() in {"NFKC", "NFC", "NFKD", "NFD"}:
        s = unicodedata.normalize(norm["unicode"].upper(), s)
    if norm.get("trim", True):
        s = s.strip()
    if norm.get("lowercase", True):
        s = s.lower()
    return s

def _normalize_tokens(tokens: List[str], policy: Dict) -> List[str]:
    return [_normalize_token(t, policy) for t in tokens or []]

def _norm(s: str) -> str:
    return (s or "").strip().lower()

def _as_set(items: Iterable[str]) -> set:
    return {_norm(x) for x in (items or [])}

def _get_set(policy: Dict, flat_key: str, nested_key: str = None, default: Iterable[str] = ()) -> set:
    """
    Read a set from EITHER flat (policy[flat_key]) OR nested (policy['tokens'][nested_key or flat_key]).
    Merge both if present. Fall back to 'default' if neither given.
    """
    nested_key = nested_key or flat_key
    flat_vals = policy.get(flat_key)
    nested_vals = (policy.get("tokens", {}) or {}).get(nested_key)
    merged = set()
    if flat_vals:
        merged |= _as_set(flat_vals)
    if nested_vals:
        merged |= _as_set(nested_vals)
    if not merged and default:
        merged = _as_set(default)
    return merged

def _exists_in_policy(policy: Dict, flat_key: str, nested_key: str = None) -> bool:
    """Return True if the key is explicitly present (non-empty) in flat or nested schema."""
    nested_key = nested_key or flat_key
    if flat_key in policy and policy.get(flat_key):
        return True
    tokens = policy.get("tokens", {})
    return isinstance(tokens, dict) and tokens.get(nested_key) not in (None, [], {})

def _get_additives(policy: Dict) -> List[Dict]:
    """
    Pull additives from flat (policy['additives']) and/or nested (policy['tokens']['additives']).
    Each item: {"id":"E951","names":["e951","aspartame"]}
    """
    flat = policy.get("additives") or []
    nested = (policy.get("tokens", {}) or {}).get("additives") or []
    return list(flat) + list(nested)

def _get_overrides_tokens(policy: Dict, key: str) -> set:
    return _as_set((policy.get("overrides", {}) or {}).get(key) or [])

def _build_syn_map(policy: Dict) -> Dict[str, str]:
    """
    Build {alias -> canonical} from tokens.synonyms in the policy.
    Canonical keys should be the English/base tokens your rules use.
    """
    syn = ((policy.get("tokens") or {}).get("synonyms") or {})
    rev: Dict[str, str] = {}
    for canonical, aliases in syn.items():
        c = _norm(canonical)
        rev[c] = c  # map canonical to itself
        for a in aliases or []:
            rev[_norm(a)] = c
    return rev

def _apply_synonyms(tokens: List[str], syn_map: Dict[str, str]) -> List[str]:
    """Replace any alias token with its canonical form if present in the map."""
    if not syn_map:
        return tokens
    return [syn_map.get(_norm(t), t) for t in tokens]


# ---------- Sensible defaults ----------
_DEFAULT_MAJOR_ALLERGENS = {
    "milk", "peanut", "egg", "wheat", "soy", "fish", "shellfish", "tree nut"
}
_DEFAULT_ANIMAL_TOKENS = {"chicken", "beef", "pork", "gelatin", "lard", "fish"}
_DEFAULT_UNSAFE = {"soap", "detergent"}
_DEFAULT_BIOCIDES = {
    "benzalkonium chloride",
    "chlorine dioxide",
    "formaldehyde",
    "ethylene glycol",
}
_DEFAULT_ALLOWLIST = {
    "citric acid", "ascorbic acid", "lactic acid", "malic acid",
    "tartaric acid", "fumaric acid", "acetic acid", "phosphoric acid",
}
_DEFAULT_ADD_SYNONYMS = {"aspartame"}  # additive fallback if no configured list
_E_NUM_RE = re.compile(r"^e\d{3}[a-z]?$", re.IGNORECASE)

def _compile_patterns(patterns):
    out = []
    for p in (patterns or []):
        try:
            out.append(re.compile(p, re.IGNORECASE))
        except re.error:
            continue
    return out

# ---------- Core logic ----------
def assess_tokens(tokens: List[str], policy: Dict) -> Tuple[int, str, List[Dict]]:
    score = 0
    reasons: List[Dict] = []

    # Normalize per-policy
    toks = _normalize_tokens(tokens, policy)
    toks = [_norm(t) for t in toks if t]

    # --- Synonyms collapse (multilingual -> canonical) ---
    syn_map = _build_syn_map(policy)
    if syn_map:
        toks = _apply_synonyms(toks, syn_map)

    # Weights / thresholds
    scoring = policy.get("scoring", {}) or {}
    weights = scoring.get("weights", {}) or {}
    thresholds = scoring.get("thresholds", {}) or {}
    w_allergen   = int(weights.get("ALLERGEN_MATCH", 5))
    w_vegan      = int(weights.get("VEGAN_CONFLICT", 3))
    w_add        = int(weights.get("ADDITIVE_FLAG", 2))
    w_trace      = int(weights.get("TRACE_ALLERGEN", 0))  # new soft rule
    w_unknown    = int(weights.get("UNKNOWN", 1))
    w_def_unsafe = int(weights.get("DEFAULT_UNSAFE", 1000))
    w_haz_chem   = int(weights.get("HAZARDOUS_CHEM", 1000))
    caution_th   = int(thresholds.get("caution", 3))
    avoid_th     = int(thresholds.get("avoid", 10))

    # Policy sets
    allowlist         = _get_set(policy, "unsafe_allowlist", default=_DEFAULT_ALLOWLIST)
    default_unsafe    = _get_set(policy, "default_unsafe_tokens", default=_DEFAULT_UNSAFE)
    hazardous_chems   = _get_set(policy, "hazardous_chemicals", default=_DEFAULT_BIOCIDES)
    major_allergens   = _get_set(policy, "major_allergens", default=_DEFAULT_MAJOR_ALLERGENS)
    animal_tokens     = _get_set(policy, "animal_tokens",   default=_DEFAULT_ANIMAL_TOKENS)
    additives_cfg     = _get_additives(policy)
    hard_extra_tokens = _get_overrides_tokens(policy, "hard_avoid_tokens")
    hard_codes        = set((policy.get("overrides", {}) or {}).get("hard_avoid_codes") or [])

    # Patterns (top-level + trace)
    patterns_cfg   = policy.get("patterns", {}) or {}
    deny_patterns  = _compile_patterns(patterns_cfg.get("deny_patterns"))
    trace_patterns = _compile_patterns(patterns_cfg.get("trace_allergen_patterns"))  # new
    allow_patterns = _compile_patterns(patterns_cfg.get("allow_patterns"))

    # Is hazardous list explicitly provided?
    haz_is_explicit = _exists_in_policy(policy, "hazardous_chemicals")

    # ---------- 1) HARD OVERRIDES ----------
    # exact hits
    hard_hits_def = [t for t in toks if t in default_unsafe and t not in allowlist]
    hard_hits_haz = [t for t in toks if t in hazardous_chems and t not in allowlist]
    hard_hits_ext = [t for t in toks if t in hard_extra_tokens and t not in allowlist]

    # substring hazardous (e.g., "... benzalkonium chloride")
    substr_haz_hits = []
    if hazardous_chems:
        for t in toks:
            if t in allowlist:
                continue
            for hz in hazardous_chems:
                if hz and hz in t:
                    substr_haz_hits.append(hz)
        substr_haz_hits = sorted(set(substr_haz_hits))

    hazard_hits = sorted(set(hard_hits_haz) | set(substr_haz_hits))

    if hard_hits_def:
        reasons.append({"code": "DEFAULT_UNSAFE", "param": ", ".join(sorted(set(hard_hits_def)))})
        score += w_def_unsafe
        if "DEFAULT_UNSAFE" in hard_codes:
            return score, "avoid", reasons

    if hazard_hits:
        code = "HAZARDOUS_CHEM" if haz_is_explicit else "DEFAULT_UNSAFE"
        reasons.append({"code": code, "param": ", ".join(hazard_hits)})
        score += (w_haz_chem if code == "HAZARDOUS_CHEM" else w_def_unsafe)
        if code in hard_codes:
            return score, "avoid", reasons

    if hard_hits_ext:
        reasons.append({"code": "DEFAULT_UNSAFE", "param": ", ".join(sorted(set(hard_hits_ext)))})
        score += w_def_unsafe
        if "DEFAULT_UNSAFE" in hard_codes:
            return score, "avoid", reasons

    if any(r["code"] in {"DEFAULT_UNSAFE", "HAZARDOUS_CHEM"} for r in reasons):
        return score, "avoid", reasons

    # Build a combined deny_all set for regex phases
    deny_all = (default_unsafe | hazardous_chems | hard_extra_tokens)

    # ---------- 2) REGEX TRACE (caution) ----------
    # TRACE_ALLERGEN (non-hard): e.g. "may contain nuts", "kan sporen bevatten van noten"
    if trace_patterns:
        trace_hits = []
        for t in toks:
            if (t in allowlist) or (t in deny_all):
                continue
            if any(p.search(t) for p in trace_patterns):
                if not any(ap.search(t) for ap in allow_patterns) if allow_patterns else True:
                    trace_hits.append(t)
        if trace_hits:
            reasons.append({
                "code": "TRACE_ALLERGEN",
                "param": ", ".join(sorted(set(trace_hits))),
            })
            score += w_trace  # soft score only, no short-circuit

    # ---------- 2b) REGEX DENY (hard if configured) ----------
    regex_hits = []
    if deny_patterns:
        for t in toks:
            if t in allowlist:
                continue
            if t in deny_all:
                continue
            matched = any(p.search(t) for p in deny_patterns)
            allowed = any(ap.search(t) for ap in allow_patterns) if allow_patterns else False
            if matched and not allowed:
                regex_hits.append(t)
        if regex_hits:
            reasons.append({"code": "DEFAULT_UNSAFE", "param": ", ".join(sorted(set(regex_hits)))})
            score += w_def_unsafe
            if "DEFAULT_UNSAFE" in hard_codes:
                return score, "avoid", reasons
            return score, "avoid", reasons

    # ---------- 3) SOFT SCORING ----------
    if any(t in major_allergens for t in toks):
        reasons.append({"code": "ALLERGEN_MATCH", "param": "major_allergen"})
        score += w_allergen

    if any(t in animal_tokens for t in toks):
        reasons.append({"code": "VEGAN_CONFLICT", "param": "animal"})
        score += w_vegan

    # Additives (configured)
    additive_matched = False
    for add in additives_cfg:
        raw_id = (add.get("id") or "").strip()
        canonical_id = raw_id.upper() if raw_id else "UNKNOWN"
        names_lower = _as_set(add.get("names") or [])
        if raw_id:
            names_lower.add(_norm(raw_id))
        if any(t in names_lower for t in toks):
            reasons.append({"code": "ADDITIVE_FLAG", "param": canonical_id})
            score += w_add
            additive_matched = True
            break

    # Additives (generic fallback)
    if not additive_matched:
        for t in toks:
            if _E_NUM_RE.match(t) or t in _DEFAULT_ADD_SYNONYMS:
                param = t.upper() if _E_NUM_RE.match(t) else t
                reasons.append({"code": "ADDITIVE_FLAG", "param": param})
                score += w_add
                break

    # ---------- 4) UNKNOWN ----------
    if not reasons:
        reasons.append({"code": "UNKNOWN", "param": "none"})
        score += w_unknown

    # ---------- 5) Verdict ----------
    if score >= avoid_th:
        verdict = "avoid"
    elif score >= caution_th:
        verdict = "caution"
    else:
        verdict = "safe"

    return score, verdict, reasons

# ---------- API routes ----------
@router.post("/v1/assess", response_model=AssessResp)
def post_assess(req: AssessReq):
    if not req.ingredients:
        raise HTTPException(400, "ingredients required")
    policy = load_policy()
    score, verdict, reasons = assess_tokens(req.ingredients, policy)
    # IMPORTANT: do NOT attach human-readable messages here; frontend will localize.
    return AssessResp(score=score, verdict=verdict, reasons=reasons)



@router.get("/health", include_in_schema=False)
def health():
    return {"status": "ok"}
