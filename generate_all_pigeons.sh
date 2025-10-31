#!/bin/zsh

INPUT_DIR="./pigeons"

for file in "$INPUT_DIR"/*.dart; do
  echo "Generating pigeon file for $file"
  dart run pigeon --input "$file"
done
