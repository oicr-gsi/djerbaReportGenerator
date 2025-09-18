#!/bin/bash

set -euo pipefail

input_dir="$1"

if [[ ! -d "$input_dir" ]]; then
  echo "Error: '$input_dir' is not a directory or not accessible"
  exit 1
fi

cd "$input_dir"

find . -name "*_report.*.html" | while read -r file; do
  if [[ -f "$file" && -r "$file" ]]; then
    grep -v -e 'Requisition Approved:' -e 'Date of Report:' "$file" | md5sum
  else
    echo "Skipping unreadable or non-file: $file" >&2
  fi
done | sort -V
