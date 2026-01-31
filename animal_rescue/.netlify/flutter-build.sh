#!/usr/bin/env bash
set -e

echo "Installing Flutter..."

FLUTTER_VERSION="3.16.5"   # change to your local version

git clone https://github.com/flutter/flutter.git -b $FLUTTER_VERSION --depth 1

export PATH="$PWD/flutter/bin:$PATH"

flutter doctor

flutter clean
flutter pub get

flutter build web --release --web-renderer html
