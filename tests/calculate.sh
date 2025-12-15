#!/bin/bash
cd "$1"

find . -name "*.tar.gz" | sort -V | while read -r tarball; do
  while IFS= read -r html; do
    tar -xOf "$tarball" "$html" \
      | grep -v -e 'Requisition Approved:' -e 'Date of Report:' \
      | md5sum \
      | awk -v t="$tarball" -v h="$html" '{print $1, t ":" h}'
  done < <(tar -tzf "$tarball" | grep -E '_report\.(research|clinical)\.html$' || true)
done

