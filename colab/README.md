# TIPy — Colab Notebooks

Self-contained Google Colab experiments for single and double inverted pendulum
control. **No local installation required** — all notebooks install their own
dependencies on first run.

---

## Single Pendulum

| Notebook | Method | Runtime |
|---|---|---|
| `single/classical/swingup_pid_lqr.ipynb` | Energy swing-up → PID or LQR stabilizer | CPU |
| `single/dqn/train.ipynb` | JAX/Flax DQN | GPU |
| `single/qlearning/train.ipynb` | Tabular Q-learning | CPU |
| `single/actor_critic/train.ipynb` | JAX/Flax Advantage Actor-Critic | GPU |

## Double Pendulum

| Notebook | Method | Runtime |
|---|---|---|
| `double/ppo/train_ppo_mjx_gpu.ipynb` | PPO + MJX GPU — 2048 parallel envs, `lax.scan` rollout | **GPU ★** |
| `double/dqn/train_mjx_gpu.ipynb` | Double-DQN + MJX GPU — reference paper parameters | **GPU ★** |
| `double/dqn/train.ipynb` | DQN, CPU-only, legacy parameters | CPU (broken) |
| `double/ppo/train_ppo.ipynb` | PPO, CPU-only, legacy | CPU (legacy) |
| `double/imitation/TIPy_double_mjx_imitation_then_ppo.ipynb` | Imitation learning → PPO fine-tune | GPU |

---

## Usage

1. Open any notebook in Google Colab.
2. Set runtime: **Runtime → Change runtime type → GPU** (T4, L4, or A100).
3. Run all cells top-to-bottom. The first cell installs all dependencies.

Checkpoints, metrics, and replay videos are saved to
`/content/drive/MyDrive/ProjectsRuns/TIPy/runs/<system>/<method>/run-001/`.

---

## Models

The MuJoCo XML models for the Colab notebooks live in `models/`:

| File | System |
|---|---|
| `models/single.xml` | Single pendulum on cart |
| `models/double.xml` | Double pendulum on cart |

The MJX notebooks embed the model XML inline (no file I/O required at runtime).

---

## Output Directory Structure

Each training run creates:

```
run-001/
├── checkpoints/          # Atomic pkl snapshots (latest.pkl + numbered)
├── metrics.csv           # Per-update training metrics
├── dashboard.png         # Static training dashboard
└── replay.mp4            # Greedy evaluation video
```
