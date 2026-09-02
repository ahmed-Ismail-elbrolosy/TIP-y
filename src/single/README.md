# Single Inverted Pendulum

`base_model.json` is the shared parameter and target definition. Run
`uv run python src/build_model.py single` after editing it, then launch the
model with `uv run python src/single/view.py`.

The generated model starts hanging with `phi = pi`, uses `phi = 0` for
upright, and exposes direct-sign position/velocity sensors for the MuJoCo
Simulink Blockset. The pole hinge is continuous for swing-up experiments.

Controllers are isolated by approach:

- `pid/` - conventional PID controller work.
- `lqr/` - linear-quadratic regulator work.
- `ppo/` - JAX PPO training on CPU.

The current controller files are placeholders; the MuJoCo model remains the
starting point for single-pendulum implementation.
