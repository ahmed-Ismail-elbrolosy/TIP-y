# Regeneration Workflow

1. Edit `src/triple/base_model.json`.
2. Regenerate MuJoCo XML:

```bash
uv run python src/build_model.py triple
```

3. If analytical equation structure changes, regenerate MATLAB expressions:

```bash
uv run --with sympy python src/triple/generate_dynamics.py
```

4. Validate the current parameters and XML:

```bash
uv run --with mujoco==3.11.0 python src/triple/validate.py
```

5. In MATLAB:

```matlab
modelRoot = fullfile(pwd, 'src', 'triple');
addpath(modelRoot, fullfile(modelRoot, 'lqr'));
L = linearize_model();
K = controller();
run_lqr();
build_simulink('Open', false);
build_mujoco_simulink('Open', false);
```

`load_base_model` reads JSON each time it is called, so a future parameter
panel can edit the JSON, regenerate/reload MuJoCo, and rerun the controller
without changing source code.
