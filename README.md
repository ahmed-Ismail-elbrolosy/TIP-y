# TIPy

TIPy is a model-oriented inverted-pendulum control project. Each physical
system owns its MuJoCo model, editable parameters, controllers, code, tests,
and documentation.

## Layout

```text
src/
  single/   base model plus PID, LQR, and PPO controller workspaces
  double/   base model plus model-specific controller workspaces
  triple/   analytical dynamics, MuJoCo bridge, LQR, tests, and docs
```

Controller folders consume the shared `base_model.json` in their model
folder. Do not add all model directories to the MATLAB path simultaneously;
add one model and one controller folder for the experiment being run.

## Editable model parameters

Each `base_model.json` controls cart mass, viscous damping, friction loss,
rail limit, pole mass and dimensions, joint damping and friction, gravity,
timestep, actuator limit, hanging initial state, target cart position, and
target pole angles. Pole hinges are continuous and use direct-sign angles:
upright is zero and hanging downward is `pi`.

After editing parameters, regenerate MuJoCo XML:

```bash
uv run python src/build_model.py all
```

COM positions and inertias are derived from mass and dimensions. They should
not be entered independently.

## Run MuJoCo

```bash
uv run python src/single/view.py
uv run python src/double/view.py
uv run python src/triple/view.py
```

MuJoCo rendering uses the host OpenGL driver. The Quadro M1200 is supported
for rendering, but its compute capability 5.0 is below JAX CUDA 12's minimum
5.2. Local PPO training therefore uses JAX on CPU. PPO training code is still
a placeholder.

## MATLAB and Simulink

MATLAB runs in a separate, generic container. Mount this repository at
`/home/matlab/work/Tipy` and install the MathWorks MuJoCo Simulink Blockset
in the container's persistent MATLAB documents directory. The double and
triple models provide `build_mujoco_simulink` functions that generate
blockset-based MuJoCo Plant models.

Blockset source and build instructions:
`https://github.com/mathworks-robotics/mujoco-simulink-blockset`.

Triple-model instructions and derivations are in `src/triple/README.md` and
`src/triple/docs/`.
