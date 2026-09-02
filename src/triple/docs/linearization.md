# 03 - Upright linearization

Equilibrium: `x_e = zeros(8,1)`, `u_e = 0`.

`linearize_model` computes central finite-difference Jacobians of `dynamics`. This
removes the former duplicate Python dynamics
and guarantees that controller design uses the nonlinear plant implementation.

The method also computes exact zero-order-hold discrete matrices with a block
matrix exponential using the configured timestep and saves `linear_model.mat`
beside the shared model code.

Host-side verification of the corrected equations gives:

```
B(5:8) = [0.466088; 1.965408; -0.527435; 0.172714]
rank(ctrb(A,B)) = 8
max(real(eig(A))) = 12.807680
```

The nonzero angular entries in `B` are required: cart force immediately
couples into all link accelerations through the mass matrix.
