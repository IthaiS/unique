#!/bin/bash

# Enable Windows desktop support
flutter config --enable-windows-desktop

# Create platform folders if missing
flutter create .

echo "Windows desktop support enabled. You can now run:"
echo "flutter run -d windows --dart-define=BACKEND_BASE_URL=http://127.0.0.1:8000"