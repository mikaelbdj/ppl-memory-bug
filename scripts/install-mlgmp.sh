#!/bin/bash
# Install GMP with OCaml interface (for ppl-memory-bug)
# Edited by: Mikael Dahlsen-Jensen (based on https://github.com/imitator-model-checker/imitator/blob/develop/.github/scripts/install-mlgmp.sh)
# License: GPL-3.0-only

# clone mlgmp from github
git clone https://github.com/monniaux/mlgmp.git || warning "mlgmp already exists, skipping cloning"
cd mlgmp

# apply patch for Ocaml > 4.05.0
echo "Applying patch for Ocaml"
git apply "../scripts/gmp.patch"

# clean previous builds
echo "Cleaning previous builds"
make clean

# compile and install
echo "Compiling mlgmp"
make -s || {
    error "An issue has occured while compiling mlgmp."
    cd ..
    rm -rf mlgmp
    exit 1
}

echo "Installing mlgmp"
make install -s || {
    error "An issue has occured while installing mlgmp."
    cd ..
    rm -rf mlgmp
    exit 1
}

cd ..
rm -rf mlgmp

# copy META file
cp METAS/META.gmp "$(opam var lib)/gmp/META" || {
    error "An issue has occured while copying META file."
    exit 1
}

exit 0