# 10 — Calculations: equilibrium

Upright equilibrium: `phi_k = 0`, all velocities zero, `u = 0`.

## Position

```
x_1 = 0, y_1 = +c1
x_2 = 0, y_2 = +l1 + c2
x_3 = 0, y_3 = +l1 + l2 + c3
```

With the chosen parameters `c_k = 0.15 m`, `l_k = 0.3 m`:

```
y_1 = 0.15 m
y_2 = 0.45 m
y_3 = 0.75 m
```

## Potential energy at upright

```
V_e = m1 g c1 + m2 g (l1 + c2) + m3 g (l1 + l2 + c3)
    = 0.5*9.81*0.15 + 0.5*9.81*(0.3+0.15) + 0.5*9.81*(0.3+0.3+0.15)
    = 0.736 + 2.207 + 3.679
    = 6.621 J
```

## Linearization at the equilibrium

The Jacobian of `xdot` with respect to `(x, phi, dx, dphi)` is given in
`03_linearization`. The bottom-left block is `-M_eq^{-1} K_eq` and is dense
because cart and link accelerations are inertially coupled. The corrected
continuous model has unstable real eigenvalues approximately `4.686`,
`8.444`, and `12.808`.
