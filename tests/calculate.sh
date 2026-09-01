#!/bin/bash
cd "$1"
find . -name "*.tar.gz" | sort -V | while read -r tarball; do
  echo "$(tar -tzf "$tarball" | wc -l)"
done