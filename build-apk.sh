#!/bin/bash
flutter build apk --release --dart-define=ENVIRONMENT=production --dart-define=BASE_URL=https://ai-miniprogram.fancyzh.top --obfuscate --split-debug-info=./debug-info
