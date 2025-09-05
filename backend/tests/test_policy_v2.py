# tests/test_policy_v2.py
import copy
import pytest

# Adjust to your actual module path:
# from backend.api.assess import assess_tokens
from backend.assess import assess_tokens


@pytest.fixture
def policy_v2():
    return {
        "version": "2.0",
        "meta": {"name": "FoodScanner Policy", "updated": "2025-09-05", "locale": "en"},
        "normalization": {"lowercase": True, "trim": True, "unicode": "NFKC"},
        "matching": {"mode": "exact", "fuzzy": False},
        "tokens": {
            "major_allergens": ["milk", "peanut", "egg", "wheat", "soy", "fish", "shellfish", "tree nut"],
            "animal_tokens": ["chicken", "beef", "pork", "gelatin", "lard", "fish"],
            "additives": [
                {"id": "E951", "names": ["e951", "aspartame"]},
            ],
            "default_unsafe_tokens": [
                "soap", "detergent", "bleach", "ammonia",
                "antifreeze", "kerosene", "lamp oil",
                "machine oil", "motor oil",
                "sulfuric acid", "hydrochloric acid", "battery acid",
                "lye", "sodium hydroxide", "drain cleaner",
                "isopropyl alcohol (non-food-grade)"
            ],
            "hazardous_chemicals": [
                "benzalkonium chloride",
                "chlorine dioxide",
                "formaldehyde",
                "ethylene glycol"
            ],
            "unsafe_allowlist": [
                "citric acid", "ascorbic acid", "lactic acid", "malic acid",
                "tartaric acid", "fumaric acid", "acetic acid", "phosphoric acid"
            ]
        },
        "patterns": {
            "deny_patterns": [],
            "allow_patterns": []
        },
        "overrides": {
            "hard_avoid_codes": ["DEFAULT_UNSAFE", "HAZARDOUS_CHEM"],
            "hard_avoid_tokens": []
        },
        "scoring": {
            "weights": {
                "ALLERGEN_MATCH": 5,
                "VEGAN_CONFLICT": 3,
                "ADDITIVE_FLAG": 2,
                "UNKNOWN": 1,
                "DEFAULT_UNSAFE": 1000,
                "HAZARDOUS_CHEM": 1000
            },
            "thresholds": {"caution": 3, "avoid": 10}
        },
        "messages": {
            "ALLERGEN_MATCH": "Contains a major allergen.",
            "VEGAN_CONFLICT": "Contains animal-derived ingredient.",
            "ADDITIVE_FLAG": "Contains flagged additive: {param}.",
            "DEFAULT_UNSAFE": "Contains an inedible/product-safety substance: {param}.",
            "HAZARDOUS_CHEM": "Contains a hazardous chemical: {param}.",
            "UNKNOWN": "No specific concerns matched; limited information."
        }
    }


# ----------------------------
# Hard-override behavior
# ----------------------------

def test_default_unsafe_hard_override(policy_v2):
    score, verdict, reasons = assess_tokens(["Soap"], policy_v2)
    assert verdict == "avoid"
    assert len(reasons) == 1
    assert reasons[0]["code"] == "DEFAULT_UNSAFE"
    assert score >= policy_v2["scoring"]["weights"]["DEFAULT_UNSAFE"]


def test_hazardous_chem_hard_override(policy_v2):
    score, verdict, reasons = assess_tokens(["benzalkonium chloride"], policy_v2)
    assert verdict == "avoid"
    assert len(reasons) == 1
    assert reasons[0]["code"] == "HAZARDOUS_CHEM"
    assert "benzalkonium chloride" in reasons[0]["param"].lower()


def test_hard_override_short_circuits_other_reasons(policy_v2):
    score, verdict, reasons = assess_tokens(["soap", "milk", "gelatin", "aspartame"], policy_v2)
    assert verdict == "avoid"
    # hard-override returns early; only one reason present
    assert len(reasons) == 1 and reasons[0]["code"] in {"DEFAULT_UNSAFE", "HAZARDOUS_CHEM"}


def test_overrides_hard_avoid_tokens_extra(policy_v2):
    pol = copy.deepcopy(policy_v2)
    pol["overrides"]["hard_avoid_tokens"] = ["denatonium benzoate"]
    score, verdict, reasons = assess_tokens(["Denatonium Benzoate", "milk"], pol)
    assert verdict == "avoid"
    assert len(reasons) == 1  # early return
    assert reasons[0]["code"] in {"DEFAULT_UNSAFE", "HAZARDOUS_CHEM"}


# ----------------------------
# Allowlist behavior
# ----------------------------

@pytest.mark.parametrize("acid", ["citric acid", "lactic acid", "acetic acid", "phosphoric acid"])
def test_allowlist_food_acids_are_safe(policy_v2, acid):
    score, verdict, reasons = assess_tokens([acid], policy_v2)
    # Should not be treated as unsafe; no hard override
    assert verdict == "safe"
    assert all(r["code"] != "DEFAULT_UNSAFE" and r["code"] != "HAZARDOUS_CHEM" for r in reasons)
    assert any(r["code"] == "UNKNOWN" for r in reasons)


# ----------------------------
# Patterns (deny/allow regex)
# ----------------------------

def test_deny_pattern_triggers_and_is_hard_avoid(policy_v2):
    pol = copy.deepcopy(policy_v2)
    pol["patterns"]["deny_patterns"] = [r"^(?:lamp|motor|machine) oil$"]
    score, verdict, reasons = assess_tokens(["lamp oil"], pol)
    assert verdict == "avoid"
    assert len(reasons) == 1
    assert reasons[0]["code"] == "DEFAULT_UNSAFE"  # pattern maps to DEFAULT_UNSAFE in impl


def test_allow_pattern_exempts_deny(policy_v2):
    pol = copy.deepcopy(policy_v2)
    pol["patterns"]["deny_patterns"] = [r"^[a-z ]+ oil$"]
    pol["patterns"]["allow_patterns"] = [r"^olive oil$"]
    score, verdict, reasons = assess_tokens(["olive oil"], pol)
    # Allowed by allow_patterns => falls through to UNKNOWN
    assert verdict == "safe"
    assert any(r["code"] == "UNKNOWN" for r in reasons)
    assert all(r["code"] != "DEFAULT_UNSAFE" for r in reasons)


# ----------------------------
# Additives with IDs/aliases (inc. Unicode NFKC)
# ----------------------------

def test_additive_alias_by_name(policy_v2):
    score, verdict, reasons = assess_tokens(["aspartame"], policy_v2)
    assert any(r["code"] == "ADDITIVE_FLAG" and r["param"] == "E951" for r in reasons)
    # 2 < caution(3) => verdict safe
    assert verdict == "safe"


def test_additive_alias_by_id(policy_v2):
    score, verdict, reasons = assess_tokens(["E951"], policy_v2)
    assert any(r["code"] == "ADDITIVE_FLAG" and r["param"] == "E951" for r in reasons)


def test_additive_unicode_fullwidth_id_normalizes(policy_v2):
    # "ｅ９５１" (fullwidth) should NFKC-normalize to "e951"
    fullwidth = "ｅ９５１"
    score, verdict, reasons = assess_tokens([fullwidth], policy_v2)
    assert any(r["code"] == "ADDITIVE_FLAG" and r["param"] == "E951" for r in reasons)


# ----------------------------
# Allergens, vegan, unknown, thresholds
# ----------------------------

def test_allergen_caution(policy_v2):
    score, verdict, reasons = assess_tokens(["peanut"], policy_v2)
    assert any(r["code"] == "ALLERGEN_MATCH" for r in reasons)
    assert verdict == "caution"
    assert score >= policy_v2["scoring"]["thresholds"]["caution"]


def test_vegan_conflict_caution(policy_v2):
    score, verdict, reasons = assess_tokens(["gelatin"], policy_v2)
    assert any(r["code"] == "VEGAN_CONFLICT" for r in reasons)
    assert verdict == "caution"


def test_unknown_safe(policy_v2):
    score, verdict, reasons = assess_tokens(["water"], policy_v2)
    assert any(r["code"] == "UNKNOWN" for r in reasons)
    assert verdict == "safe"


def test_scores_accumulate_to_avoid(policy_v2):
    # 5 (allergen) + 3 (vegan) + 2 (additive) = 10 -> "avoid"
    score, verdict, reasons = assess_tokens(["milk", "gelatin", "aspartame"], policy_v2)
    assert verdict == "avoid"
    assert score >= policy_v2["scoring"]["thresholds"]["avoid"]


# ----------------------------
# Normalization (lower/trim)
# ----------------------------

def test_case_and_whitespace_normalization(policy_v2):
    score, verdict, reasons = assess_tokens(["  PeAnUt  "], policy_v2)
    assert any(r["code"] == "ALLERGEN_MATCH" for r in reasons)
    assert verdict == "caution"
