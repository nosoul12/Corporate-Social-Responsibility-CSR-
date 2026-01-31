#!/usr/bin/env bash
set -e

echo "Installing Flutter..."

FLUTTER_DIR="$HOME/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  git clone --depth 1 https://github.com/flutter/flutter.git -b stable "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$FLUTTER_DIR/bin/cache/dart-sdk/bin:$PATH"

flutter --version

echo "Enabling web..."
flutter config --enable-web

echo "Getting packages..."
flutter pub get

echo "Building Flutter Web..."
flutter build web --release
