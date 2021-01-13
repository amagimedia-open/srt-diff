#!/bin/bash

set -e
set -u
set -x

docker build -t srt-diff-rel -f srtdf_h_rel_dockerfile.txt .
