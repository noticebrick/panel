#!/usr/bin/env bash

set -euo pipefail

UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/pterodactyl/panel}"
UPSTREAM_REF="${UPSTREAM_REF:-}"
DATE_OVERRIDE="${DATE_OVERRIDE:-}"
PATCH_DIR="${PATCH_DIR:-$GITHUB_WORKSPACE/patches}"
WORK_DIR="${WORK_DIR:-$RUNNER_TEMP/panel-src}"
DIST_DIR="${DIST_DIR:-$GITHUB_WORKSPACE/dist}"

rm -rf "$WORK_DIR"
git clone --filter=blob:none "$UPSTREAM_URL" "$WORK_DIR"

if [[ -n "$UPSTREAM_REF" ]]; then
  git -C "$WORK_DIR" fetch --force origin "$UPSTREAM_REF"
  git -C "$WORK_DIR" checkout --force FETCH_HEAD
fi

cd "$WORK_DIR"

BASE_VERSION="$(sed -nE 's/^## v([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' CHANGELOG.md | head -n1)"
if [[ -z "$BASE_VERSION" ]]; then
  echo "Failed to parse base version from CHANGELOG.md" >&2
  exit 1
fi

if [[ -n "$DATE_OVERRIDE" ]]; then
  if [[ ! "$DATE_OVERRIDE" =~ ^[0-9]{8}$ ]]; then
    echo "DATE_OVERRIDE must be in YYYYMMDD format" >&2
    exit 1
  fi
  RELEASE_DATE="$DATE_OVERRIDE"
else
  RELEASE_DATE="$(date -u +%Y%m%d)"
fi

RELEASE_TAG="v${BASE_VERSION}-${RELEASE_DATE}"
ARCHIVE_NAME="panel_${RELEASE_TAG}.tar.gz"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "base_version=${BASE_VERSION}"
    echo "release_date=${RELEASE_DATE}"
    echo "release_tag=${RELEASE_TAG}"
    echo "archive_name=${ARCHIVE_NAME}"
  } >> "$GITHUB_OUTPUT"
fi

if [[ -d "$PATCH_DIR" ]]; then
  shopt -s nullglob
  patch_files=("$PATCH_DIR"/*.patch)
  shopt -u nullglob
  IFS=$'\n' patch_files=($(printf '%s\n' "${patch_files[@]}" | sort))
  unset IFS

  # Guardrail: this patch should stay large; sudden shrink usually means
  # partial regeneration from the wrong diff scope.
  MIN_0002_LINES="${MIN_0002_LINES:-7000}"

  if (( ${#patch_files[@]} == 0 )); then
    echo "No patch files found in $PATCH_DIR; continuing without patch application."
  fi

  for patch in "${patch_files[@]}"; do
    if [[ ! -s "$patch" ]]; then
      echo "Skipping empty patch file: $patch"
      continue
    fi

    patch_name="$(basename "$patch")"
    if [[ "$patch_name" == "0002-zhtw-localization.patch" ]]; then
      patch_lines="$(wc -l < "$patch")"
      if (( patch_lines < MIN_0002_LINES )); then
        echo "Patch $patch_name is unexpectedly small (${patch_lines} lines < ${MIN_0002_LINES})." >&2
        exit 1
      fi
    fi

    echo "Validating patch: $patch_name"
    git apply --check --whitespace=nowarn "$patch"

    echo "Applying patch: $patch_name"
    git apply --whitespace=nowarn "$patch"
  done
else
  echo "Patch directory $PATCH_DIR does not exist; continuing without patch application."
fi

echo "Linting critical translation files"
php -l resources/lang/en/literals.php
php -l resources/lang/zh_TW/literals.php

echo "Installing JS dependencies"
corepack enable
corepack yarn install --frozen-lockfile

echo "Building production assets"
corepack yarn build:production

mkdir -p "$DIST_DIR"

echo "Creating release archive: $ARCHIVE_NAME"
tar \
  --exclude-vcs \
  --exclude='node_modules' \
  --exclude='vendor' \
  --exclude='.env' \
  --exclude='storage/logs/*' \
  --exclude='storage/framework/cache/*' \
  -czf "$DIST_DIR/$ARCHIVE_NAME" \
  -C "$WORK_DIR" \
  .

chmod 644 "$DIST_DIR/$ARCHIVE_NAME"

echo "Creating SHA256SUMS"
(cd "$DIST_DIR" && sha256sum "$ARCHIVE_NAME" > SHA256SUMS)

echo "Built release artifact for tag: $RELEASE_TAG"
