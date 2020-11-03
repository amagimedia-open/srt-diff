#!/bin/bash

set -e
set -u
set -x

docker build -t srt-diff -f srtdf_h_dockerfile.txt .
