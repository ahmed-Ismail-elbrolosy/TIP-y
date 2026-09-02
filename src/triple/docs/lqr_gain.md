# 10 - Calculations: LQR gain

Weights:

```
Q = diag([30, 20, 15, 10, 1, 1, 0.7, 0.5])
R = 0.05
```

Independent host computation gives approximately:

```
K = [-21.1843, 1258.0743, -3652.0500, 2646.9947,
     -31.0747, 0.5707, -74.3205, 163.2414]
max(abs(eig(Ad - Bd*K))) = 0.991072
```

The corrected controller is linearly stable. Equal angle errors of `0.05 rad`
request about `12.65 N`; equal errors of `0.10 rad` request about `25.3 N` and
therefore saturate at `20 N`.
