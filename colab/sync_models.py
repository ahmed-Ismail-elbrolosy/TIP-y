"""Keep self-contained Colab/Kaggle notebooks aligned with TIPy's models."""

from __future__ import annotations

import json
from pathlib import Path


COLAB_ROOT = Path(__file__).resolve().parent
TIPY_ROOT = COLAB_ROOT.parent
NOTEBOOK_MODELS = {
    "single/qlearning/train.ipynb": "single",
    "single/dqn/train.ipynb": "single",
    "single/actor_critic/train.ipynb": "single",
    "single/classical/swingup_pid_lqr.ipynb": "single",
    "double/dqn/train.ipynb": "double",
    "double/ppo/train_ppo.ipynb": "double",
}
NEURAL_NOTEBOOKS = {
    "single/dqn/train.ipynb",
    "single/actor_critic/train.ipynb",
    "double/dqn/train.ipynb",
}

CPU_SETUP = '''from pathlib import Path
import os
import subprocess
import sys

try:
    from google.colab import drive
except ImportError:
    IN_COLAB = False
else:
    IN_COLAB = True
    drive.mount("/content/drive")

IN_KAGGLE = "KAGGLE_KERNEL_RUN_TYPE" in os.environ
if IN_COLAB or IN_KAGGLE:
    subprocess.run([
        sys.executable, "-m", "pip", "install", "--upgrade", "-q",
        "mujoco>=3.2", "gymnasium>=1.0", "pandas>=2.0", "matplotlib>=3.8",
        "imageio>=2.34", "imageio-ffmpeg>=0.5", "scipy>=1.11",
    ], check=True)

# Native MuJoCo dynamics are CPU-based; EGL uses the hosted NVIDIA GPU for video rendering.
os.environ.setdefault("MUJOCO_GL", "egl")
print("Runtime:", "Colab" if IN_COLAB else "Kaggle" if IN_KAGGLE else "local")
'''

GPU_SETUP = '''from pathlib import Path
import os
import subprocess
import sys

try:
    from google.colab import drive
except ImportError:
    IN_COLAB = False
else:
    IN_COLAB = True
    drive.mount("/content/drive")

IN_KAGGLE = "KAGGLE_KERNEL_RUN_TYPE" in os.environ
if IN_COLAB or IN_KAGGLE:
    subprocess.run([
        sys.executable, "-m", "pip", "install", "--upgrade", "-q",
        "jax[cuda12]", "mujoco>=3.2", "gymnasium>=1.0", "flax==0.12.8", "optax==0.2.8",
        "pandas>=2.0", "matplotlib>=3.8", "imageio>=2.34", "imageio-ffmpeg>=0.5",
    ], check=True)

# Keep learning arrays resident on the accelerator and use EGL for GPU-backed video rendering.
os.environ.setdefault("MUJOCO_GL", "egl")
os.environ.setdefault("XLA_PYTHON_CLIENT_PREALLOCATE", "true")
os.environ.setdefault("XLA_PYTHON_CLIENT_MEM_FRACTION", "0.85")

import flax
import jax
import jax.numpy as jnp
import optax

gpu_devices = [device for device in jax.devices() if device.platform == "gpu"]
print(f"JAX {jax.__version__} | Flax {flax.__version__} | Optax {optax.__version__}")
print("JAX backend:", jax.default_backend(), "| devices:", jax.devices())
if (IN_COLAB or IN_KAGGLE) and not gpu_devices:
    raise RuntimeError(
        "GPU accelerator required: enable a GPU in the Colab or Kaggle notebook settings, "
        "restart the runtime, and run all cells again."
    )
if (IN_COLAB or IN_KAGGLE) and flax.__version__ != "0.12.8":
    raise RuntimeError("Restart the notebook runtime, then run all cells again.")

accelerator_probe = jax.jit(lambda x: x @ x)(jnp.ones((64, 64), dtype=jnp.float32))
accelerator_probe.block_until_ready()
probe_device = next(iter(accelerator_probe.devices()))
if (IN_COLAB or IN_KAGGLE) and probe_device.platform != "gpu":
    raise RuntimeError("GPU accelerator required, but the JIT probe ran on " + str(probe_device))
print("JIT accelerator probe:", probe_device)
'''


def replace_model_xml(source: str, xml: str) -> str:
    marker = 'MODEL_XML = r"""'
    start = source.index(marker) + len(marker)
    end = source.index('"""', start)
    return source[:start] + "\n" + xml.rstrip() + "\n" + source[end:]


def update_notebook(relative_path: str, model_name: str) -> None:
    path = COLAB_ROOT / relative_path
    notebook = json.loads(path.read_text())
    model_xml = (COLAB_ROOT / "models" / f"{model_name}.xml").read_text()
    found_model = False
    found_setup = False

    for cell in notebook["cells"]:
        if cell["cell_type"] != "code":
            continue
        source = "".join(cell["source"])
        if "MODEL_XML = r\"\"\"" in source:
            cell["source"] = replace_model_xml(source, model_xml)
            found_model = True
        if 'os.environ.setdefault("MUJOCO_GL"' in source:
            cell["source"] = GPU_SETUP if relative_path in NEURAL_NOTEBOOKS else CPU_SETUP
            found_setup = True

    if not found_model or not found_setup:
        raise RuntimeError(f"{relative_path}: expected model and setup cells")

    # Larger device batches amortize host-to-GPU transfers while MuJoCo generates experience.
    for cell in notebook["cells"]:
        if cell["cell_type"] != "code":
            continue
        source = "".join(cell["source"])
        if relative_path == "single/dqn/train.ipynb":
            source = source.replace(
                "LEARNING_RATE, GAMMA, BATCH_SIZE = 3e-4, 0.99, 64",
                "LEARNING_RATE, GAMMA, BATCH_SIZE = 3e-4, 0.99, 256",
            )
        elif relative_path == "single/actor_critic/train.ipynb":
            source = source.replace(
                "GAMMA, N_STEPS, ACTOR_LR, CRITIC_LR, ENTROPY_COEF = .99, 128,",
                "GAMMA, N_STEPS, ACTOR_LR, CRITIC_LR, ENTROPY_COEF = .99, 512,",
            )
        elif relative_path == "double/dqn/train.ipynb":
            source = source.replace(
                "LEARNING_RATE, GAMMA, BATCH_SIZE = 3e-4, 0.99, 128",
                "LEARNING_RATE, GAMMA, BATCH_SIZE = 3e-4, 0.99, 512",
            )
        cell["source"] = source

    path.write_text(json.dumps(notebook, indent=1, ensure_ascii=False) + "\n")
    print(f"updated {relative_path} from models/{model_name}.xml")


def main() -> None:
    for model_name in set(NOTEBOOK_MODELS.values()):
        source = TIPY_ROOT / "src" / model_name / "model.xml"
        snapshot = COLAB_ROOT / "models" / f"{model_name}.xml"
        if source.exists():
            snapshot.write_text(source.read_text())
        elif not snapshot.exists():
            raise FileNotFoundError(f"missing canonical model: {source} or {snapshot}")
    for notebook_path, model_name in NOTEBOOK_MODELS.items():
        update_notebook(notebook_path, model_name)


if __name__ == "__main__":
    main()
