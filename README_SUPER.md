# FoodLabel AI — SELF-CONTAINED SUPER RELEASE (Everything-in-one)

This archive contains the **entire repo contents**: mobile app sources, backend, tests, Terraform infra, CI/CD, Makefile, and helpers.

## First-time setup (exact order)
1. **Unzip in your repo root**
```bash
git clone https://github.com/IthaiS/unique.git
cd unique
unzip foodlabel_ai_SUPER_RELEASE_EVERYTHING_*.zip -d .
chmod +x commit_super_release.sh scripts/create_release.sh foodlabel-ai/mobile/scripts/bootstrap_mobile.sh || true
```
2. **Commit to the repo**
```bash
./commit_super_release.sh --repo-root . --branch main --remote https://github.com/IthaiS/unique.git
```
3. **Configure GitHub → Settings → Actions**
- **Variables:** `GCP_REGION=europe-west1`, `CLOUD_RUN_SERVICE=foodlabel-backend`
- **Secrets (shared or env-specific):**  
  - Shared: `GCP_PROJECT_ID`, `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_SERVICE_ACCOUNT_EMAIL`  
  - Or Env-specific: `GCP_WIF_PROVIDER_DEV`, `GCP_SA_DEV`, `GCP_WIF_PROVIDER_PROD`, `GCP_SA_PROD`  
  - Sentry: `SENTRY_AUTH_TOKEN`, `SENTRY_ORG`, `SENTRY_PROJECT`

4. **Run Infra once (idempotent)**
- GitHub → Actions → **Infra Stack (Terraform)** → *Run workflow* (or push infra files).

5. **Deploy**
- Push to `develop` → **Deploy Backend (dev)** creates/updates `<service>-dev`.  
- Push to `main` → **Deploy Backend (prod)** creates/updates `<service>`.  
- **Sentry Release** runs after a successful prod deploy or when `VERSION` changes.

6. **Mobile app**
```bash
cd foodlabel-ai/mobile
./scripts/bootstrap_mobile.sh   # idempotently creates android/ios/macos/web skeletons
flutter pub get
# Optional: set backend URL
flutter run --dart-define=BACKEND_BASE_URL=https://<cloud-run-url>
```

## Idempotency
- **Terraform** plan detects drift and applies only when needed.
- **Deploy workflows** create Cloud Run service only if missing, then update.
- **Mobile bootstrap** checks and creates platform folders only once.

See `README_CODE_COMPLETE.md` and `docs/ARCHITECTURE.md` for more details.
