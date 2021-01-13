#!/bin/bash

set -e
set -u
set -x

docker build -t srt-diff-dev -f srtdf_h_dev_dockerfile.txt .
