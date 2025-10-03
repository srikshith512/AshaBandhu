#!/bin/bash

# Install Flutter SDK
if [ ! -d "flutter" ] ; then
  git clone https://github.com/flutter/flutter.git
fi
export PATH="$PATH:`pwd`/flutter/bin"

# Run Flutter build
flutter pub get
flutter build web --release
