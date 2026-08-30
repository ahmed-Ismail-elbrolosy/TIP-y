#!/usr/bin/env bash
# GPU passthrough smoke test for the TIPy MATLAB stack.
# Run from /home/orca/prjs/TIPy/matlab once NVIDIA Container Toolkit is configured.
set -euo pipefail

docker run --rm --gpus all \
  nvidia/cuda:12.2.2-base-ubuntu22.04 nvidia-smi

docker compose run --rm --no-deps matlab -batch "ver"
