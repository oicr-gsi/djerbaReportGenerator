#!/bin/bash
cd $1

find . -name "*_report.json" | while read -r file; do
  # Remove known datetime fields using jq
  jq 'del(.core.extract_time, .plugins.case_overview.results.requisition_approved)' "$file" | md5sum
done | sort -V