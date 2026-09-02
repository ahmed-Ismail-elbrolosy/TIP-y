# 10 - Calculations: linear model

For state ordering `[x, phi1, phi2, phi3, dx, dphi1, dphi2, dphi3]`, the
corrected continuous input matrix is:

```
B = [0; 0; 0; 0; 0.466088; 1.965408; -0.527435; 0.172714]
```

Continuous eigenvalues are approximately:

```
0, -29.6310, -12.1139, 12.8077, -4.7902, 8.4442, 4.6864, -0.02857
```

The upright system has three unstable real modes. The controllability matrix
has rank 8; its two smallest singular values are approximately `0.2872` and
`0.2783`.

These values were computed independently on the host from the analytical
mass and bias equations. MATLAB regenerates its own `A`, `B`, `Ad`, and `Bd`
through `linearize_model`.
