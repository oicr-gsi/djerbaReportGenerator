#!/bin/bash
cd $1

find . -name "*_report.research.html" | while read -r file; do
  grep -v -e 'Requisition Approved:' -e 'Date of Report:' "$file" | md5sum
done | sort -V
