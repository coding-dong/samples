#!/usr/bin/env bash
# Idempotent environment setup for the flutter/samples monorepo.
# Installs the Flutter stable SDK (matching the Dart <3.0.0 SDK constraints
# used across the samples) plus the Linux desktop build dependencies, and
# exposes `flutter`/`dart` on the default PATH.
set -euo pipefail

FLUTTER_VERSION="3.7.12"
FLUTTER_HOME="/opt/flutter"
FLUTTER_TARBALL="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${FLUTTER_TARBALL}"

echo "== Installing Linux build dependencies =="
sudo apt-get update -qq
sudo apt-get install -y -qq \
  curl git unzip xz-utils \
  clang cmake ninja-build pkg-config libgtk-3-dev

if [ ! -x "${FLUTTER_HOME}/bin/flutter" ]; then
  echo "== Downloading Flutter ${FLUTTER_VERSION} =="
  tmp_tarball="$(mktemp --suffix=.tar.xz)"
  curl -fSL --retry 4 -o "${tmp_tarball}" "${FLUTTER_URL}"
  echo "== Extracting Flutter to ${FLUTTER_HOME} =="
  sudo rm -rf "${FLUTTER_HOME}"
  sudo tar -xf "${tmp_tarball}" -C /opt
  sudo chown -R "$(id -u):$(id -g)" "${FLUTTER_HOME}"
  rm -f "${tmp_tarball}"
else
  echo "== Flutter already present at ${FLUTTER_HOME}, skipping download =="
fi

# Flutter runs git against its own checkout; mark it safe for any user.
git config --global --add safe.directory "${FLUTTER_HOME}" || true

# Expose flutter/dart on the default PATH regardless of shell profile.
sudo ln -sf "${FLUTTER_HOME}/bin/flutter" /usr/local/bin/flutter
sudo ln -sf "${FLUTTER_HOME}/bin/dart" /usr/local/bin/dart

export PATH="${FLUTTER_HOME}/bin:${PATH}"

echo "== Configuring Flutter =="
flutter config --no-analytics >/dev/null 2>&1 || true
flutter config --enable-web >/dev/null 2>&1 || true

echo "== Warming build artifacts (web + linux) =="
flutter precache --web --linux >/dev/null 2>&1 || true

echo "== flutter doctor =="
flutter doctor -v || true

echo "== Flutter setup complete =="
