# FoodLabel AI — Super Release (v0.6.0, Guarded)

This bundle contains **everything** to build, test, and deploy:
- Flutter mobile app (OCR scanning, ingredient extraction, i18n en/nl-BE/fr-BE)
- FastAPI backend with simple policy evaluator
- Terraform (Workload Identity Federation + full stack infra)
- GitHub Actions (guarded auth + hardened YAML)
- Tests (Flutter + Pytest), helper scripts, and integrity checks

---

## 1) Unpack and commit to your repo

```bash
unzip foodlabel_ai_SUPER_RELEASE_FULL_GUARDED_*.zip -d .
chmod +x commit_super_release.sh scripts/*.sh foodlabel-ai/mobile/scripts/bootstrap_mobile.sh
./commit_super_release.sh --repo-root . --branch main --remote https://github.com/IthaiS/unique.git
./scripts/self_check.sh .           # verifies all key files exist
./scripts/verify_bundle.sh .        # verifies CHECKSUMS.txt hashes
```

> If the remote mismatches, pass `--remote <expected>` to `commit_super_release.sh` or update your `origin`.

---

## 2) Configure GitHub Actions (secrets/vars)

**Repository → Settings → Secrets and variables → Actions**

**Variables** (optional defaults):
- `GCP_REGION = europe-west1`
- `CLOUD_RUN_SERVICE = foodlabel-backend`
- `BACKEND_BASE_URL = https://<your-cloud-run-url>` (for Android build job)

**Secrets** (choose ONE path that matches your WIF setup):

**Shared WIF (usable by all workflows)**
- `GCP_PROJECT_ID`
- `GCP_WORKLOAD_IDENTITY_PROVIDER`
- `GCP_SERVICE_ACCOUNT_EMAIL`

**OR Environment-specific (preferred if you split envs)**
- Dev:  `GCP_WIF_PROVIDER_DEV`, `GCP_SA_DEV`
- Prod: `GCP_WIF_PROVIDER_PROD`, `GCP_SA_PROD`

**Sentry (optional)**
- `SENTRY_AUTH_TOKEN`, `SENTRY_ORG`, `SENTRY_PROJECT`

---

## 3) First pipeline run (idempotent)

Order:
1. **Infra Stack (Terraform)** — provisions WIF pool/provider, AR repo, optional Firestore, etc.
2. **Deploy Backend (dev)** on branch `develop` or **Deploy Backend (prod)** on `main`
3. **Sentry Release (versioned)** after prod deployment

You can also trigger **Deploy Backend (manual)** from the Actions UI at any time.

---

## 4) Mobile app (Flutter)

```bash
cd foodlabel-ai/mobile
./scripts/bootstrap_mobile.sh
flutter pub get
flutter test
# During development (no backend): runs with local assessment fallback
flutter run
# Against your backend:
flutter run --dart-define=BACKEND_BASE_URL=https://<cloud-run-url>
```

---

## 5) Backend (local dev)

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r backend/requirements.txt
uvicorn backend.api:app --reload
# test
pytest -q
```

---

## 6) Terraform (locally, optional)

```bash
cd foodlabel-ai/infra/stack
cp terraform.tfvars.example terraform.tfvars   # edit project_id, etc.
terraform init -upgrade
terraform plan
terraform apply
```

---

## 7) Release helper

```bash
make tag TAG=v0.6.0
make release TAG=v0.6.0
```

---

## Troubleshooting

- **Auth error ("must specify exactly one of workload_identity_provider or credentials_json")**: set the required WIF secrets. Workflows include guards and will fail early with a clear message if missing.
- **YAML syntax errors**: all YAML avoids inline maps; if an error persists, copy the workflow from this bundle again.
- **Mobile camera permission**: `bootstrap_mobile.sh` injects the CAMERA permission into `AndroidManifest.xml` if missing.
