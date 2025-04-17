#!/bin/bash
cd $1

echo ".html file:"
find . -name "*/*_report.research.html" | while read -r file; do
  grep -v -e 'Requisition Approved:' -e 'Date of Report:' "$file" | md5sum
done | sort -V

echo ".json file:"
find . -name "*/*_report.json" | while read -r file; do
  # Remove known datetime fields using jq
  jq 'del(.core.extract_time, .plugins.case_overview.results.requisition_approved)' "$file" | md5sum
done | sort -V