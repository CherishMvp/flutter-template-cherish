#!/bin/bash
flutter build ipa --release --dart-define=ENVIRONMENT=production --dart-define=BASE_URL=https://ai-miniprogram.fancyzh.top --obfuscate --split-debug-info=./debug-info
