# Mobile (Flutter)

OCR powered scanning + ingredient parsing + assessment call.

## Run
```bash
cd foodlabel-ai/mobile
./scripts/bootstrap_mobile.sh
flutter pub get
flutter test
flutter run --dart-define=BACKEND_BASE_URL=https://<cloud-run-url>
```
