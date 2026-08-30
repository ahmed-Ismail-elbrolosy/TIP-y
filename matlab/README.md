# MATLAB Container (TIPy)

R2024a image with GPU passthrough for the inverted-pendulum (TIPy) project.

## One-time host setup (sudo required)

```
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg2
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
  | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

## Verify GPU passthrough

```
docker run --rm --gpus all nvidia/cuda:12.2.2-base-ubuntu22.04 nvidia-smi
./scripts/gpu-smoke.sh
```

## Start MATLAB

```
cd /home/orca/prjs/TIPy/matlab
docker compose up -d matlab
```

Open <http://localhost:8888> and sign in with your MathWorks account
(Individual/Campus license).

## Notes

* Image pinned to `r2024a`; the Quadro M1200 (compute 5.0) is the highest
  release MathWorks officially supports for GPU compute.
* `./workspace` is the scratch area for new TIPy MATLAB scripts.
* `../` is mounted read/write at `/home/matlab/work/TIPy`.
* License is acquired interactively through the browser; no credentials
  are stored on disk.
