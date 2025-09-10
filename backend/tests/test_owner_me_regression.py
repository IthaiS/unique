# backend/tests/test_owner_me_regression.py
from __future__ import annotations
from typing import Any, Dict

def _get(d: Dict[str, Any], *keys, default=None):
    for k in keys:
        if k in d:
            return d[k]
    return default

def test_owner_me_roundtrip(client, auth_headers):
    # GET current owner account
    r = client.get("/auth/me", headers=auth_headers)
    assert r.status_code == 200, f"/auth/me GET failed: {r.status_code} {r.text}"
    current = r.json()

    # Prepare an update (email & country are known-good per your app)
    new_country = "US" if _get(current, "country") != "US" else "CA"
    base_email = _get(current, "email", default="owner.test+regression@example.com")
    if "+" in base_email:
        local, rest = base_email.split("+", 1)
        local = local.split("@")[0]
        domain = base_email.split("@", 1)[1]
        new_email = f"{local}+rt@example.com" if "@" not in rest else f"{local}+rt@{domain}"
    else:
        new_email = base_email

    payload = {
        # Prefer snake_case but also include camelCase in case your Pydantic model accepts either
        "email": new_email,
        "country": new_country,
        "owner_name": _get(current, "owner_name", "Owner Regression"),
        "state": _get(current, "state", "CA"),
        "ownerName": _get(current, "owner_name", "Owner Regression"),
    }

    r = client.put("/auth/me", json=payload, headers=auth_headers)
    assert r.status_code in (200, 204), f"/auth/me PUT failed: {r.status_code} {r.text}"

    # Read-back and verify
    r = client.get("/auth/me", headers=auth_headers)
    assert r.status_code == 200
    updated = r.json()

    assert _get(updated, "email") == new_email
    assert _get(updated, "country") == new_country
    # Don’t hard-fail on state/name if backend ignores them, but check if set sticks when supported
    if "state" in updated:
        assert updated["state"] in ("CA", "US-CA", payload["state"])
    if _get(updated, "owner_name") or _get(updated, "ownerName"):
        assert _get(updated, "owner_name", "x") == _get(payload, "owner_name", default="Owner Regression") or \
               _get(updated, "ownerName", "x") == _get(payload, "ownerName", default="Owner Regression")
