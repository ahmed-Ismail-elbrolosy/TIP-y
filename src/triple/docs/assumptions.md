# Assumptions And Parameters

## Coordinates

The state is
`[x, phi1, phi2, phi3, dx, dphi1, dphi2, dphi3]^T`. Each `phi` is an
absolute link angle relative to the upward vertical; upright is zero.

MuJoCo uses relative hinge coordinates:

```text
q_mj = [x, phi1, phi2-phi1, phi3-phi2]
```

The generated reference pose starts all links hanging with absolute angles
`[pi, pi, pi]`, represented by relative joints `[pi, 0, 0]`. Pole hinges are
continuous; controller angle errors are wrapped to `[-pi, pi]`.

## Editable values

`base_model.json` controls:

- cart mass, viscous damping, Coulomb friction loss, and rail limit;
- each pole's mass, length, width, depth, damping, and friction loss;
- gravity, timestep, force limit, initial state, target cart position, and
  target angles.

COM is always `length/2`. Inertia is calculated as a uniform box from mass
and dimensions, preventing inconsistent values after changing pole length.

## Friction

Viscous damping is represented in both analytical and MuJoCo models.
MuJoCo `frictionloss` is editable but is nonsmooth and is not included in the
analytical LQR model. Keep friction loss at zero for exact cross-model
validation and linearization; use nonzero values for robustness experiments.

The rail limit is enforced by MuJoCo. The analytical equations are a local,
unconstrained model and do not implement hard-stop impacts.

## Actuation

All generated models use direct cart force limited by
`actuator.force_limit`. This allows PID, LQR, PPO, and future controllers to
act on the same physical input.

The cart-position target may be changed for LQR. LQR target angles must remain
upright (`0 rad`) because arbitrary static link angles are not an unforced
equilibrium of this underactuated plant.
