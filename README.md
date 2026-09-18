# TIPy — Inverted Pendulum Control

> A model-oriented control research project exploring classical and deep reinforcement learning approaches to single and double inverted pendulum stabilization. Each physical system owns its MuJoCo model, editable parameters, and a suite of controllers ranging from energy-shaping + LQR to GPU-accelerated PPO and DQN trained with MuJoCo's JAX backend (MJX).

---

## Notebooks at a Glance

| Notebook | System | Method | Status |
|---|---|---|---|
| `colab/single/classical/swingup_pid_lqr.ipynb` | Single | Energy swing-up → PID / LQR | ✅ Working |
| `colab/single/dqn/train.ipynb` | Single | DQN (discrete actions) | 🔧 Basic |
| `colab/single/qlearning/train.ipynb` | Single | Tabular Q-learning | 🔧 Basic |
| `colab/single/actor_critic/train.ipynb` | Single | Actor-Critic | 🔧 Basic |
| `colab/double/ppo/train_ppo_mjx_gpu.ipynb` | Double | PPO + MJX GPU (vectorized) | ✅ Working |
| `colab/double/dqn/train_mjx_gpu.ipynb` | Double | Double-DQN + MJX GPU | 🆕 New |
| `colab/double/dqn/train.ipynb` | Double | DQN (CPU, legacy) | ⚠️ Broken |
| `colab/double/ppo/train_ppo.ipynb` | Double | PPO (CPU, legacy) | 🗄️ Legacy |
| `colab/double/imitation/TIPy_double_mjx_imitation_then_ppo.ipynb` | Double | Imitation → PPO | 🔬 Experimental |

---

## Physical Systems

### Single Inverted Pendulum on a Cart

A single rigid pole mounted on a cart, controlled by a horizontal force.

| Parameter | Value |
|---|---|
| Cart mass | 2 kg |
| Pole mass | 0.7 kg |
| Pole length | 0.6 m |
| Rail limits | ±2.2 m |
| Actuator limits | ±100 N |

**Goal:** swing the pole up from hanging and balance it upright.

---

### Double Inverted Pendulum on a Cart

Two serial rigid poles (links) mounted on a cart. Significantly more unstable than the single case.

Two parameter sets are used across experiments:

| Parameter | PPO / Original | DQN MJX / Reference |
|---|---|---|
| Cart mass | 2 kg | 0.4 kg |
| Pole mass (each) | 0.5 kg | 0.15 kg |
| Pole length (each, full) | 0.3 m | 0.5 m |
| Actuator limits | ±100 N | ±40 N |
| Rail limits | ±2.0 m | ±1.5 m |

The **reference paper parameters** (DQN MJX) match the Double-Inverted-Pendulum-Cart MATLAB reference implementation. The **PPO parameters** were tuned for sample efficiency in the GPU training runs.

---

## Quick Start

All interactive experiments run on **Google Colab** (GPU runtime recommended) or **Kaggle**.

1. Open any notebook via the badge links or directly in Colab:

   ```
   https://colab.research.google.com/github/<your-username>/TIPy/blob/main/<path-to-notebook>.ipynb
   ```

2. Set runtime to **GPU** (T4, A100, or L4):
   `Runtime → Change runtime type → Hardware accelerator → GPU`

3. The first cell in each notebook installs dependencies:

   ```python
   !pip install mujoco mujoco-mjx jax[cuda12] flax optax
   ```

4. Run all cells top-to-bottom. MJX notebooks will compile JAX kernels on first run — this takes ~1–2 minutes.

> **Local use:** Install with `uv sync` (Python 3.12+) and launch Jupyter normally. CUDA 12 is required for MJX GPU training.

---

## Control Approaches

### Classical Control

**Energy Swing-Up → PID Stabilizer** (`colab/single/classical/`)

An energy-based controller pumps energy into the pendulum until it nears the upright equilibrium, then a PID controller takes over. Simple and interpretable; works fine (not my finest but suf. as a poc) for the single pendulum.

**Energy Swing-Up → LQR Stabilizer** (`colab/single/classical/`)

Same swing-up phase, but the stabilizer is a Linear Quadratic Regulator (LQR) designed via the Continuous Algebraic Riccati Equation (CARE). Provides optimal linear stabilization around the upright fixed point.

---

### Reinforcement Learning — PPO (Proximal Policy Optimization)

**`colab/double/ppo/train_ppo_mjx_gpu.ipynb`** ✅

Fully GPU-vectorized training using JAX + MJX:

- **2 048 parallel environments** stepped in lockstep via `vmap` + `jit` + `lax.scan`
- **Policy:** tanh-squashed Gaussian (continuous force output)
- **Advantage estimation:** Generalized Advantage Estimation (GAE, λ = 0.95)
- **Network:** MLP via Flax (linen), optimized with Optax
- Entire rollout + update loop runs on-device with no Python overhead

---

### Reinforcement Learning — DQN (Deep Q-Network)

**`colab/double/dqn/train_mjx_gpu.ipynb`** 🆕

Double-DQN with MJX-batched environment stepping:

- **Discrete action space:** fixed set of force magnitudes applied to the cart
- **Double-DQN:** decoupled action selection and value estimation to reduce overestimation
- **Reference parameters** matching the MATLAB paper (mc = 0.4 kg, m = 0.15 kg, L = 0.5 m)
- GPU-accelerated environment transitions via MJX

---

### Reference: MATLAB Energy Shaping + Linear MPC

**`references/Double-Inverted-Pendulum-Cart/`**

A MATLAB implementation (not authored here) that derives analytical dynamics via Lagrangian mechanics and applies energy-shaping swing-up followed by Linear Model Predictive Control (LMPC) for stabilization. Used as a physical parameter reference for the DQN MJX notebook.

---

## GPU Training Notes

| Requirement | Details |
|---|---|
| JAX backend | `jax[cuda12]` — CUDA 12 required |
| MJX | `mujoco-mjx` — MuJoCo's JAX physics backend |
| Recommended GPU | Colab A100 / L4, or any CUDA 12 GPU with ≥ 8 GB VRAM |
| Compilation | First-run JAX JIT compilation adds ~1–2 min; subsequent steps are fast |
| Vectorization | 2 048 envs in PPO; scales with available VRAM |

Training runs are designed to be **self-contained within a single notebook cell group** — no external config files are needed.

---

## Repository Structure

```
TIPy/
├── colab/                          # Interactive Colab notebooks (primary experiments)
│   ├── models/
│   │   ├── single.xml              # MuJoCo single pendulum model
│   │   └── double.xml              # MuJoCo double pendulum model
│   ├── single/
│   │   ├── classical/
│   │   │   └── swingup_pid_lqr.ipynb   ✅ Energy swing-up + PID/LQR
│   │   ├── dqn/
│   │   │   └── train.ipynb
│   │   ├── qlearning/
│   │   │   └── train.ipynb
│   │   └── actor_critic/
│   │       └── train.ipynb
│   └── double/
│       ├── ppo/
│       │   ├── train_ppo_mjx_gpu.ipynb ✅ GPU PPO + MJX (primary)
│       │   └── train_ppo.ipynb         🗄️ CPU PPO (legacy)
│       ├── dqn/
│       │   ├── train_mjx_gpu.ipynb     🆕 Double-DQN + MJX GPU
│       │   └── train.ipynb             ⚠️ Legacy (broken)
│       └── imitation/
│           └── TIPy_double_mjx_imitation_then_ppo.ipynb
├── src/                            # Standalone Python source (local use)
│   ├── single/
│   │   ├── model.xml
│   │   ├── pid/controller.py
│   │   └── lqr/
│   └── double/
│       ├── model.xml
│       └── lqr/
├── references/
│   └── Double-Inverted-Pendulum-Cart/  # Reference MATLAB implementation
│       ├── README.md
│       └── code/
│           ├── shared/             # Dynamics derivations, LMPC
│           └── energy_shaping/     # Energy-based swing-up
└── pyproject.toml
```

---

## Tech Stack

| Library | Role |
|---|---|
| [MuJoCo 3.x](https://mujoco.readthedocs.io) | Physics simulation, model definition |
| [MJX](https://mujoco.readthedocs.io/en/stable/mjx.html) | JAX-native batched physics (GPU) |
| [JAX](https://jax.readthedocs.io) | Accelerated array ops, `vmap`, `jit`, `lax.scan` |
| [Flax 0.12 (linen)](https://flax.readthedocs.io) | Neural network definitions |
| [Optax](https://optax.readthedocs.io) | Gradient-based optimizers |
| [NumPy / SciPy](https://scipy.org) | Classical control math, CARE solver |
| [Gymnasium](https://gymnasium.farama.org) | RL environment interface |

---

## References

- **Double-Inverted-Pendulum-Cart** — MATLAB reference implementation of energy-shaping swing-up and Linear MPC stabilization. Physical parameters used as ground-truth for the DQN MJX experiments. Included under `references/`.

- Todorov, E., Erez, T., & Tassa, Y. (2012). **MuJoCo: A physics engine for model-based control.** *IROS 2012.*

- Schulman, J., et al. (2017). **Proximal Policy Optimization Algorithms.** *arXiv:1707.06347.*

- Mnih, V., et al. (2015). **Human-level control through deep reinforcement learning.** *Nature, 518*, 529–533.

- van Hasselt, H., Guez, A., & Silver, D. (2016). **Deep Reinforcement Learning with Double Q-learning.** *AAAI 2016.*

---

*Built with JAX + MJX. Developed as a Physical AI research portfolio project.*
