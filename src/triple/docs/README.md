# Triple Model Documentation

- [[overview]] - structure and files.
- [[assumptions]] - coordinates, editable parameters, and friction model.
- [[derivation]] - Lagrangian analytical dynamics.
- [[equilibrium]] - upright equilibrium calculation.
- [[linearization]] and [[linear_model]] - state-space construction and values.
- [[lqr]] and [[lqr_gain]] - controller design and numerical gain.
- [[mujoco_bridge]] - coordinate conversion and MuJoCo Simulink Blockset.
- [[simulink]] - generated LQR simulation model.
- [[validation]] - tests and measured cross-model agreement.
- [[regeneration]] - parameter and generated-file workflow.

The editable source of physical and target parameters is
`src/triple/base_model.json`.
