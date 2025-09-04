# Setup Guide (macOS/Windows/Android/iOS)

## 0) Prereqs
- GCP project + billing, Terraform >= 1.5
- Python 3.11, Docker, git
- Flutter 3.22+
  - macOS: `flutter config --enable-macos-desktop`
  - Windows: `flutter config --enable-windows-desktop`

## 1) Bootstrap
```bash
bash scripts/bootstrap_all.sh
```

## 2) Infra (GCP)
```bash
cd foodlabel-ai/infra/stack
cp terraform.tfvars.example terraform.tfvars   # set project_id
terraform init -upgrade
terraform apply
```

## 3) Export outputs & sync GitHub secrets/vars
```bash
cd ../../..
./scripts/write_env_from_tf.sh
REPO=IthaiS/unique ./scripts/gh_sync_secrets.sh .env.ci
```

## 4) Backend (local)
```bash
python -m venv .venv && source .venv/bin/activate
pip install -r backend/requirements.txt
uvicorn backend.api:app --reload
```

## 5) Run Flutter
- macOS (desktop): `flutter run -d macos 
--dart-define=BACKEND_BASE_URL=http://127.0.0.1:8000`
- Windows (desktop): `flutter run -d windows 
--dart-define=BACKEND_BASE_URL=http://127.0.0.1:8000`
- Android (emulator): 
`--dart-define=BACKEND_BASE_URL=http://10.0.2.2:8000`

## 6) Live OCR test (Cloud Vision via backend)
```bash
LIVE_OCR=1 pytest backend/tests/test_ocr_live.py -q
```
