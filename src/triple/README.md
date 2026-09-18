# Triple Inverted Pendulum

This folder contains the shared triple-pendulum model and controller-specific
subfolders. `base_model.json` is the canonical editable configuration.

## Parameter workflow

1. Edit `base_model.json`.
2. Run `uv run python src/build_model.py triple` to update `model.xml`.
3. Run `uv run --with mujoco==3.11.0 python src/triple/validate.py`.
4. In MATLAB, call `load_base_model`; no generated parameter file is needed.
5. Call `build_mujoco_simulink` for the CPU-safe, headless MuJoCo model.
6. Call `build_mujoco_simulink_gpu` for the hardware-rendered model.

Both variants start hanging, apply a short force pulse, and log the wrapped,
direct-sign MuJoCo state
`[x, phi1, phi2, phi3, dx, dphi1, dphi2, dphi3]`. The existing
`lqr/build_simulink` remains the analytical reference model.

Pole COM and inertia are derived from pole dimensions. Viscous damping is
represented by the analytical model and MuJoCo. `friction_loss` is editable
for MuJoCo experiments, but keep it at zero when comparing against or
linearizing the smooth analytical model.

## MATLAB LQR

```matlab
modelRoot = fullfile(pwd, 'src', 'triple');
addpath(modelRoot, fullfile(modelRoot, 'lqr'));
L = linearize_model();
K = controller();
run_lqr();
build_simulink('Open', false);
```

The target cart position comes from `base_model.json`. Triple LQR requires
upright target angles because a single cart force cannot hold arbitrary static
link angles. Nonzero angle targets remain available for future trajectory,
PID, or learning controllers but `linearize_model` rejects them.

## Tests

```matlab
modelRoot = fullfile(pwd, 'src', 'triple');
addpath(modelRoot, fullfile(modelRoot, 'lqr'));
results = runtests(fullfile(modelRoot, 'tests'));
assertSuccess(results);
```

Detailed assumptions, derivation, linearization, validation results, and
regeneration instructions are maintained in `docs/`.
