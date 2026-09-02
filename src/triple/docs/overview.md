# Overview

The triple model is self-contained under `src/triple/`.

## Shared model

- `base_model.json` - editable physical, simulation, actuator, and target values.
- `load_base_model.m` - MATLAB JSON loader; derives COM and inertia.
- `model.xml` - MuJoCo model generated from the JSON file.
- `dynamics.m`, `mass_matrix.m`, `bias_forces.m` - analytical plant.
- `linearize_model.m` - finite-difference state-space model.
- `state_to_mujoco.m`, `state_from_mujoco.m` - coordinate conversion.
- `validate.py` - analytical-versus-MuJoCo acceleration comparison.
- `build_mujoco_simulink.m` - generated Simulink model using the MuJoCo
  Simulink Blockset.

## LQR controller

`lqr/` contains `controller.m`, `run_lqr.m`, `plant_sfun.m`, and
`build_simulink.m`. `plant_sfun.m` is retained as the analytical reference
plant; `build_mujoco_simulink.m` uses the MuJoCo blockset plant.

## Documentation and tests

Detailed notes are in `docs/`; MATLAB tests are in `tests/`.
