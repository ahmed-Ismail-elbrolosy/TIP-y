# 04 — Discrete LQR controller

## Discrete model

```
x_{k+1} = Ad x_k + Bd u_k,       y_k = x_k
```

`Ad`, `Bd` are produced from the continuous `A`, `B` by exact matrix
exponential:

```
[ Ad  Bd ]    =  expm( [ A  B ] * T_s )
[  0    I  ]       [ 0  0 ]
```

## Cost

```
J = sum_k (dx_k^T Q dx_k + u_k^T R u_k)
```

with `dx_k = x_k - x_e`.

## Default weights

```
Q = diag([ 30,  20, 15, 10,    1,   1, 0.7, 0.5 ])
R = 0.05
```

Rationale:

- Cart position weight (30) and pole angles (20, 15, 10) prioritize keeping
  the poles upright before the cart recenters.
- Cart velocity (1) and pole rates (1, 0.7, 0.5) lightly penalize effort.
- R = 0.05 gives a stabilizing controller, but equal 0.1 rad angle errors
  request about 25 N and therefore hit the +/-20 N saturation.

## Gain (host, hand-checked after first build)

`controller()` produces K and saves `lqr/lqr_gain.mat`, including the
closed-loop poles. The
closed-loop eigenvalues of `Ad - Bd*K` must lie strictly inside the unit
circle for stability.  See `07_validation`.

## Saturation

A `Saturation` block in the generated Simulink model enforces
`u = clamp(-K dx, -u_max, +u_max)`.  No anti-windup is implemented; if
saturation becomes persistent the closed-loop response will degrade and
should be re-tuned by raising `R`.

LQR has no integrator, so classical anti-windup is not required. Saturation
still makes the response nonlinear and limits the useful region of attraction.
