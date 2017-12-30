#!/usr/bin/env bash
set -e

dir=packed
arch="$(node -p process.arch)"
tag="$(git describe --tags)"

mkdir -p "${dir}"

pkg bin/retropie-profiles \
  --config package.json \
  --output "${dir}/retropie-profiles-v${tag}" \
  -t node9-alpine,node9-linux,node9-macos,node9-win

for fullpath in "${dir}"/*; do
  ext=""
  if [ "${fullpath: -4}" = ".exe" ]; then
    ext=".exe"
  fi

  dest="${dir}/$(basename "${fullpath}" "${ext}")-${arch}${ext}"

  mv -v "${fullpath}" "${dest}"
done
