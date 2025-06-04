#!/bin/bash
cd "$1" || exit 1

find . -name "*_report.json" | while read -r file; do
  # Remove known volatile fields
  jq 'del(
    .core.extract_time,
    .plugins.case_overview.results.requisition_approved
  )' "$file" | md5sum
done | sort -V
