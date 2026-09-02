# 02 — Lagrangian derivation

## Generalized coordinates

q = (x, phi1, phi2, phi3),  dq = (dx, dphi1, dphi2, dphi3).

The cart position is x.  The pole angles are measured from the upward
vertical (see `01_assumptions`).

## Positions

```
x_1 = x - c1 sin(phi1)
y_1 = +c1 cos(phi1)
x_2 = x - l1 sin(phi1) - c2 sin(phi2)
y_2 = +l1 cos(phi1) + c2 cos(phi2)
x_3 = x - l1 sin(phi1) - l2 sin(phi2) - c3 sin(phi3)
y_3 = +l1 cos(phi1) + l2 cos(phi2) + c3 cos(phi3)
```

## Kinetic energy

```
T = 1/2 m_c dx^2
  + sum_k 1/2 m_k (dx_k^2 + dy_k^2) + 1/2 I_{yy,k} dphi_k^2
```

evaluated by `generate_dynamics.py` and emitted to `mass_matrix.m`.

## Potential energy

```
V = sum_k m_k g y_k
  = g [m1 (c1 cos phi1)
      + m2 (l1 cos phi1 + c2 cos phi2)
      + m3 (l1 cos phi1 + l2 cos phi2 + c3 cos phi3)]
```

## Euler–Lagrange

The equations of motion take the standard form

```
M(q) qddot + h(q, dq) = B u,       B = [1, 0, 0, 0]^T
```

with `h = C(q, dq) dq + D dq + dV/dq` and

```
D = [ dc              0       0        0
      0    d_{q,1}+d_{q,2}  -d_{q,2}    0
      0       -d_{q,2}   d_{q,2}+d_{q,3} -d_{q,3}
      0         0         -d_{q,3}      d_{q,3} ]
```

The off-diagonal entries arise from the relative-angle friction that
MuJoCo applies on each hinge.  In the absolute-angle representation they
become the symmetric block shown above.

## Sign of the gravity term

`dV/dphi_i = -g (...) sin(phi_i)`. At upright this term is zero, but its
derivative is negative. Since acceleration uses `M\(Bu-h)`, the resulting
state Jacobian has unstable positive modes. See `03_linearization`.

## Mass matrix (symbolic)

`M = [[m1+m2+m3+m_c,
       -(c1 m1 + l1 m2 + l1 m3) cos phi1,
       -(c2 m2 + l2 m3) cos phi2,
       -c3 m3 cos phi3],
      [...symmetric...,
       I1 + c1^2 m1 + l1^2 m2 + l1^2 m3,
       l1 (c2 m2 + l2 m3) cos(phi1 - phi2),
       c3 l1 m3 cos(phi1 - phi3)],
      [...,
       I2 + c2^2 m2 + l2^2 m3,
       c3 l2 m3 cos(phi2 - phi3)],
      [...,
       I3 + c3^2 m3]]`

The full expanded form is emitted to `mass_matrix.m`.
