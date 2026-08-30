% Smoke test: confirms MATLAB in the container can see the host NVIDIA GPU.
% Run with: docker compose exec matlab matlab -batch "run('/home/matlab/work/TIPy/matlab/scripts/gpu_check.m')"

ver
canUseGPU
gpuDevice
gpuDeviceTable
