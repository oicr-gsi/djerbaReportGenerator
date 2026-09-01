#!/bin/bash
cd "$1"
count=$(find . -name "*.tar.gz" | wc -l)
echo "$1: $count"