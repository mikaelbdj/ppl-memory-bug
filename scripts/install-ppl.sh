#!/bin/bash
# Install PPL with OCaml interface (for ppl-memory-bug)
# Author: Mikael Dahlsen-Jensen (based on https://github.com/imitator-model-checker/imitator/blob/develop/.github/scripts/install-ppl.sh)
# License: GPL-3.0-only

set -e

REPO_URL="git@github.com:BUGSENG/PPL.git"
REPO_DIR="PPL"
OPAM_PREFIX=$(opam var prefix)
GMP_LIB=$(opam var lib)/gmp

echo "[INFO] Installing PPL with OCaml interface..."

if [[ -d "$REPO_DIR" ]]; then
  echo "[INFO] Found existing PPL directory, skipping clone."
else
  echo "[INFO] Cloning PPL repository..."
  git clone "$REPO_URL" "$REPO_DIR"
fi

cd "$REPO_DIR"

echo "[INFO] Checking out master..."
git fetch origin master
git checkout master

echo "[INFO] Bootstrapping build system..."
autoreconf -i

echo "[INFO] Configuring build..."
./configure -q \
  --prefix="$OPAM_PREFIX" \
  --with-mlgmp="$GMP_LIB" \
  --disable-documentation \
  --enable-interfaces=ocaml \
  --enable-shared \
  --disable-static

echo "[INFO] Building PPL (including OCaml interface)..."
make -j$(nproc 2>/dev/null || echo 4)

echo "[INFO] Installing PPL..."
make install

cd ..

META_SRC="METAS/META.ppl"
META_DEST="$(opam var lib)/ppl/META"

if [[ -f "$META_SRC" ]]; then
  echo "[INFO] Copying META.ppl to $META_DEST"
  mkdir -p "$(dirname "$META_DEST")"
  cp "$META_SRC" "$META_DEST"
else
  echo "[WARN] META.ppl not found at $META_SRC — skipping."
fi

echo "[SUCCESS] PPL installation complete."
exit 0