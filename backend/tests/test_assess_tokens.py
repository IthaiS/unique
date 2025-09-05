# tests/test_assess_tokens.py
import pytest

# If your function lives elsewhere, adjust the import accordingly:
# from backend.api.assess import assess_tokens
from backend.assess import assess_tokens  # <-- change to your actual module path


@pytest.fixture
def policy():
    return {
        "default_unsafe_tokens": [
            "soap",
            "detergent",
            "bleach",
            "ammonia",
            "antifreeze",
            "kerosene",
            "lamp oil",
            "machine oil",
            "motor oil",
            "sulfuric acid",
            "hydrochloric acid",
            "battery acid",
            "lye",
            "sodium hydroxide",
            "drain cleaner",
            "isopropyl alcohol (non-food-grade)",
        ],
        "unsafe_allowlist": [
            "citric acid",
            "ascorbic acid",
            "lactic acid",
            "malic acid",
            "tartaric acid",
            "fumaric acid",
            "acetic acid",
            "phosphoric acid",
        ],
        "animal_tokens": ["chicken", "beef", "pork", "gelatin", "lard", "fish"],
        "scoring": {
            "weights": {
                "ALLERGEN_MATCH": 5,
                "VEGAN_CONFLICT": 3,
                "ADDITIVE_FLAG": 2,
                "UNKNOWN": 1,
                "DEFAULT_UNSAFE": 1000,
            },
            "thresholds": {
                "caution": 3,
                "avoid": 10,
            },
        },
    }


def test_default_unsafe_hard_override(policy):
    score, verdict, reasons = assess_tokens(["Soap", "milk"], policy)
    assert verdict == "avoid"
    assert any(r["code"] == "DEFAULT_UNSAFE" for r in reasons)
    # Hard override should short-circuit: only DEFAULT_UNSAFE reason present
    assert len(reasons) == 1
    assert score >= policy["scoring"]["weights"]["DEFAULT_UNSAFE"]


@pytest.mark.parametrize("token", ["citric acid", "lactic acid", "acetic acid", "phosphoric acid"])
def test_allowlist_acids_not_flagged(policy, token):
    score, verdict, reasons = assess_tokens([token], policy)
    # Should not trip DEFAULT_UNSAFE
    assert all(r["code"] != "DEFAULT_UNSAFE" for r in reasons)
    # With only UNKNOWN weight=1, thresholds caution=3, avoid=10 -> verdict safe
    assert verdict == "safe"
    assert any(r["code"] == "UNKNOWN" for r in reasons)


@pytest.mark.parametrize("token", ["milk", "peanut", "egg", "wheat", "soy", "fish", "shellfish", "tree nut"])
def test_allergen_match_scores_and_cautions(policy, token):
    score, verdict, reasons = assess_tokens([token], policy)
    assert any(r["code"] == "ALLERGEN_MATCH" for r in reasons)
    # weight 5 >= caution 3 => "caution"
    assert verdict == "caution"
    assert score >= policy["scoring"]["thresholds"]["caution"]


def test_vegan_conflict_triggers(policy):
    score, verdict, reasons = assess_tokens(["gelatin"], policy)
    assert any(r["code"] == "VEGAN_CONFLICT" for r in reasons)
    # weight 3 == caution threshold
    assert verdict == "caution"


def test_additive_flag(policy):
    score, verdict, reasons = assess_tokens(["E951"], policy)
    assert any(r["code"] == "ADDITIVE_FLAG" for r in reasons)
    # weight 2 < caution 3 => "safe"
    assert verdict == "safe"


def test_unknown_when_no_matches(policy):
    score, verdict, reasons = assess_tokens(["water"], policy)
    assert any(r["code"] == "UNKNOWN" for r in reasons)
    assert verdict == "safe"


def test_case_and_whitespace_insensitivity(policy):
    score, verdict, reasons = assess_tokens(["  PeAnUt  "], policy)
    assert any(r["code"] == "ALLERGEN_MATCH" for r in reasons)
    assert verdict == "caution"


def test_multiple_reasons_accumulate_to_avoid(policy):
    # 5 (allergen) + 3 (vegan) + 2 (additive) = 10 -> "avoid"
    score, verdict, reasons = assess_tokens(["milk", "gelatin", "aspartame"], policy)
    codes = {r["code"] for r in reasons}
    assert {"ALLERGEN_MATCH", "VEGAN_CONFLICT", "ADDITIVE_FLAG"}.issubset(codes)
    assert verdict == "avoid"
    assert score >= policy["scoring"]["thresholds"]["avoid"]


def test_hard_override_stops_other_reasons(policy):
    # If hard-override is implemented, seeing "soap" should prevent adding allergen reasons
    score, verdict, reasons = assess_tokens(["soap", "milk", "gelatin", "E951"], policy)
    assert verdict == "avoid"
    assert len(reasons) == 1
    assert reasons[0]["code"] == "DEFAULT_UNSAFE"

def test_benzalkonium_chloride_flagged(policy):
    score, verdict, reasons = assess_tokens(["benzalkonium chloride"], policy)
    assert verdict == "avoid"
    assert len(reasons) == 1
    assert reasons[0]["code"] == "DEFAULT_UNSAFE"
    assert "benzalkonium chloride" in reasons[0]["param"].lower()
    assert score >= policy["scoring"]["weights"]["DEFAULT_UNSAFE"]


@pytest.mark.parametrize("biocide", [
    "Benzalkonium chloride",
    "chlorine dioxide",
    "formaldehyde",
    "ethylene glycol",
])
def test_biocides_flagged_avoid_case_insensitive(policy, biocide):
    score, verdict, reasons = assess_tokens([biocide], policy)
    assert verdict == "avoid"
    assert any(r["code"] == "DEFAULT_UNSAFE" for r in reasons)
    assert len(reasons) == 1  # hard-override short-circuits


def test_biocide_short_circuits_other_reasons(policy):
    # Even if other tokens would add reasons, hard-override should return early
    score, verdict, reasons = assess_tokens(
        ["benzalkonium chloride", "milk", "gelatin", "aspartame"],
        policy
    )
    assert verdict == "avoid"
    assert len(reasons) == 1
    assert reasons[0]["code"] == "DEFAULT_UNSAFE"


def test_biocide_not_affected_by_allowlist(policy):
    # Ensure acids in allowlist do not suppress the unsafe verdict
    score, verdict, reasons = assess_tokens(
        ["benzalkonium chloride", "citric acid"],
        policy
    )
    assert verdict == "avoid"
    assert len(reasons) == 1
    assert reasons[0]["code"] == "DEFAULT_UNSAFE"
