# 05 — MATLAB ↔ MuJoCo bridge

Two layers connect the MATLAB plant to MuJoCo.

## Layer 1: state conversion

`state_to_mujoco.m` and `state_from_mujoco.m` implement:

```
q_mj(1) = x
q_mj(2) = phi1
q_mj(3) = phi2 - phi1
q_mj(4) = phi3 - phi2

dq_mj(1) = dx
dq_mj(2) = dphi1
dq_mj(3) = dphi2 - dphi1
dq_mj(4) = dphi3 - dphi2
```

The MuJoCo XML `model.xml` keeps q=0 for all hinges to represent upright.
Its hinge axes use the same positive-angle direction as the MATLAB model.

## Layer 2: MuJoCo Simulink Blockset

The MathWorks MuJoCo Simulink Blockset provides the MuJoCo Plant block.
`build_mujoco_simulink.m` configures it with `model.xml`, exposes the named
joint sensors, reconstructs the direct-sign absolute-angle state, and limits
cart force to +/-20 N. Install and build the blockset in MATLAB before
generating the model.

The generated MJCF reference pose starts physically hanging while reporting
`q = [0, pi, 0, 0]`: the first pole body carries the hanging base orientation,
the first hinge reference is `pi`, and downstream relative references are
zero. The builder applies a short bounded cart-force pulse to break the exact
downward equilibrium. No custom initialization S-function is required.

## Layer 3: model alignment

The generated `model.xml` matches the analytical plant when friction loss is zero:

- explicit body inertials (`inertiafromgeom="false"`),
- a force motor with `ctrlrange` and `forcerange` set to +/-20 N,
- viscous joint damping on each hinge,
- configurable Coulomb friction loss (zero for analytical validation),
- step size 0.005 s with RK4 integrator.

The host validator compared accelerations at 50 sampled states with maximum
absolute error `2.786e-11`.
