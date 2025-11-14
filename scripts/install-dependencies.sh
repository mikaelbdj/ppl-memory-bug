#!/bin/bash
# PPL Memory Bug Reproduction Minimal Build Script
# Author: Mikael Dahlsen-Jensen (based on https://github.com/imitator-model-checker/imitator/blob/develop/.github/scripts/build.sh)
# License: GPL-3.0-only

set -e

OCAML_VERSION="4.14.2"
SWITCH_NAME="ppl-memory-bug"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PATCH_FOLDER="$(dirname $SCRIPT_DIR)/"

echo "[INFO] Installing system dependencies..."
if [[ "$(uname)" == "Linux" ]]; then
  sudo apt-get update -qq
  sudo apt-get install -y -qq build-essential m4 g++ wget curl opam libgmp-dev libmpfr-dev libppl-dev autoconf libtool
elif [[ "$(uname)" == "Darwin" ]]; then
  brew install gmp ppl opam
else
  echo "[ERROR] Unsupported OS."
  exit 1
fi

echo "[INFO] Initializing opam..."
opam init -a --disable-sandboxing -y &>/dev/null || true

if ! opam switch list | grep -q "$SWITCH_NAME"; then
  echo "[INFO] Creating opam switch ($SWITCH_NAME, OCaml $OCAML_VERSION)..."
  opam switch create "$SWITCH_NAME" ocaml.$OCAML_VERSION -y
fi

echo "[INFO] Switching to $SWITCH_NAME"
opam switch $SWITCH_NAME
eval "$(opam env --switch=$SWITCH_NAME)"

echo "[INFO] Installing dune ..."
opam install -y dune

echo "[INFO] Installing mlgmp..."
if [[ -f "$SCRIPT_DIR/install-mlgmp.sh" ]]; then
  bash "$SCRIPT_DIR/install-mlgmp.sh"
else
  echo "[WARN] install-mlgmp.sh not found — skipping."
fi

echo "[INFO] Installing PPL..."
if [[ -f "$SCRIPT_DIR/install-ppl.sh" ]]; then
  bash "$SCRIPT_DIR/install-ppl.sh"
else
  echo "[WARN] install-ppl.sh not found — skipping."
fi

echo "[INFO] Cleaning old builds"
dune clean

echo "[SUCCESS] Dependencies installed."
