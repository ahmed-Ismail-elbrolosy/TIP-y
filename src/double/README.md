# Double Inverted Pendulum

`base_model.json` is the shared parameter and target definition. Run
`uv run python src/build_model.py double` after editing it, then launch the
model with `uv run python src/double/view.py`.

Add each controller under its own folder (`pid/`, `lqr/`, `ppo/`) while
keeping physical parameters and shared dynamics at this model root.

## Simulink MuJoCo plant

After installing the MathWorks MuJoCo Simulink Blockset, run
`build_mujoco_simulink` for the CPU-safe, headless model. Run
`build_mujoco_simulink_gpu` for `tipy_double_mujoco_gpu.slx`, which opens the
MuJoCo hardware-rendered window. Both models start hanging, apply a short
symmetry-breaking force pulse, and log the direct-sign absolute state:

```text
[x, phi1, phi2, dx, dphi1, dphi2]
```

Replace the `Startup kick` source only after confirming the sensor-state
output in open loop.
