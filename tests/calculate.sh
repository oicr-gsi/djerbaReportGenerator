#!/bin/bash
set -euo pipefail

SEARCH_DIR="${1:-.}"

# Find tarballs deterministically
find "$SEARCH_DIR" -type f -name "*.tar.gz" | sort -V | while read -r tarball; do
  mapfile -t html_paths < <(tar -tzf "$tarball" | grep -E '_report\.(research|clinical)\.html$' || true)

  if [[ "${#html_paths[@]}" -eq 0 ]]; then
    echo "WARN: No *_report.research.html found in: $tarball" >&2
    continue
  fi

  for html in "${html_paths[@]}"; do
    tar -xOf "$tarball" "$html" \
      | grep -v -e 'Requisition Approved:' -e 'Date of Report:' \
      | md5sum \
      | awk -v t="$tarball" -v h="$html" '{print $1, t ":" h}'
  done

done | sort
