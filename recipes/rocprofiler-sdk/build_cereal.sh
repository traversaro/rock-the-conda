#!/bin/bash
set -euo pipefail

mkdir -p "$PREFIX/include"
cp -a "$SRC_DIR/external/cereal/include/cereal" "$PREFIX/include/"
