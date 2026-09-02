# 07 - Validation

## MATLAB tests

Run from the project root inside MATLAB:

```matlab
modelRoot = fullfile(pwd, 'src', 'triple');
addpath(modelRoot, fullfile(modelRoot, 'lqr'));
results = runtests(fullfile(modelRoot, 'tests'));
assertSuccess(results);
```

The tests cover equilibrium, mass-matrix symmetry and positive definiteness,
input coupling, local nonlinear-versus-linear agreement, controllability,
closed-loop poles, and coordinate conversion.
When Simulink and Control System Toolbox licenses are available, the suite
also builds the generated model and runs a model-update compile.

## MuJoCo cross-check

Run on the host:

```bash
uv run --with "mujoco==3.11.0" python src/triple/validate.py
```

On 2026-09-02, 50 deterministic sampled states produced a maximum absolute
acceleration difference of `2.786e-11` between the analytical equations and
`src/triple/model.xml`.

## Remaining runtime verification

The MuJoCo Simulink Blockset C-MEX components compile with MATLAB R2026a.
Blockset model generation and MATLAB test execution must be run in the
licensed matlab-proxy session because a second batch process cannot acquire
the active license.
