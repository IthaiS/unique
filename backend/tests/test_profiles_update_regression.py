# backend/tests/test_profiles_update_regression.py
from __future__ import annotations
from typing import Dict, Any, List

def _id(p: Dict[str, Any]) -> int:
    return p.get("id") or p.get("profile_id")

def _name(p: Dict[str, Any]) -> str:
    return p.get("name") or p.get("profileName") or p.get("label") or "Unnamed"

def _list(d: Dict[str, Any], *keys) -> List[Any]:
    for k in keys:
        v = d.get(k)
        if isinstance(v, list):
            return v
    return []

def _payload(name: str, allergens: List[str], avoid: List[str]) -> Dict[str, Any]:
    # send both snake_case & camelCase to be resilient to backend schema
    return {
        "name": name,
        "allergens": allergens,
        "avoid_ingredients": avoid,
        "avoidIngredients": avoid,
    }

def _create_or_pick_profile(client, headers):
    # Try to create
    pr = client.post(
        "/profiles",
        json=_payload("Regression Kid", ["PEANUTS"], ["E102"]),
        headers=headers,
    )
    if pr.status_code in (200, 201):
        return pr.json()

    # If creation not available or disabled, just pick first existing
    gr = client.get("/profiles", headers=headers)
    assert gr.status_code == 200, f"/profiles GET failed: {gr.status_code} {gr.text}"
    items = gr.json() or []
    assert items, "No profiles available to test against"
    return items[0]

def test_profiles_update_allergens_and_avoid(client, auth_headers):
    prof = _create_or_pick_profile(client, auth_headers)
    pid = _id(prof)
    assert pid, f"Profile id missing in {prof}"

    # Toggle values
    new_name = _name(prof) + " - rt"
    current_allergens = set(_list(prof, "allergens"))
    current_avoid = set(_list(prof, "avoid_ingredients", "avoidIngredients"))

    # Flip one allergen, one additive
    new_allergens = sorted((current_allergens ^ {"PEANUTS", "MILK"}) or {"MILK"})
    new_avoid = sorted((current_avoid ^ {"E102", "E129"}) or {"E129"})

    ur = client.put(
        f"/profiles/{pid}",
        json=_payload(new_name, new_allergens, new_avoid),
        headers=auth_headers,
    )
    assert ur.status_code in (200, 204), f"PUT /profiles/{pid} failed: {ur.status_code} {ur.text}"

    # Read-back
    rr = client.get(f"/profiles/{pid}", headers=auth_headers)
    assert rr.status_code == 200, f"GET /profiles/{pid} failed: {rr.status_code} {rr.text}"
    updated = rr.json()

    got_allergens = set(_list(updated, "allergens"))
    got_avoid = set(_list(updated, "avoid_ingredients", "avoidIngredients"))
    assert got_allergens == set(new_allergens), f"allergens mismatch: {got_allergens} != {set(new_allergens)}"
    assert got_avoid == set(new_avoid), f"avoid_ingredients mismatch: {got_avoid} != {set(new_avoid)}"
