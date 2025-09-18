#!/bin/bash

find . -name "*.tar.gz" -exec md5sum {} + | sort -V