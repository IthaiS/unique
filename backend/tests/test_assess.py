import json, os, importlib
def test_assess_thresholds(tmp_path, monkeypatch):
    pdir = tmp_path / "policies"; pdir.mkdir()
    (pdir/"policy_v1.json").write_text(json.dumps({
        "scoring":{"weights":{"ALLERGEN_MATCH":40,"ADDITIVE_FLAG":20,"VEGAN_CONFLICT":30,"UNKNOWN":10},
                  "thresholds":{"avoid":60,"caution":30}},
        "animal_tokens":["gelatin"]
    }))
    monkeypatch.setenv("POLICY_DIR", str(pdir))
    assess = importlib.import_module("backend.assess")
    score, verdict, reasons = assess.assess_tokens(["milk","sugar"], assess.load_policy())
    assert verdict in ("caution","avoid")
    assert score >= 40
