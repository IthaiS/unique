import json, os, importlib

def test_assess_thresholds(tmp_path, monkeypatch):
    p=tmp_path/"policies"; p.mkdir();
    (p/"policy_v1.json").write_text(json.dumps({"scoring":{"weights":{"ALLERGEN_MATCH":40,"ADDITIVE_FLAG":20,"VEGAN_CONFLICT":30,"UNKNOWN":10},"thresholds":{"avoid":60,"caution":30}},"animal_tokens":["gelatin"]}))
    monkeypatch.setenv("POLICY_DIR", str(p))
    assess=importlib.import_module("backend.assess")
    score, verdict, _ = assess.assess_tokens(["milk","sugar"], assess.load_policy())
    assert verdict in ("caution","avoid") and score>=40
