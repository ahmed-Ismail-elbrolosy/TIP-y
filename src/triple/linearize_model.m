function L = linearize_model()
%LINEARIZE_UPRIGHT Linearize the TIPy plant around the upright equilibrium.
%   L = LINEARIZE_UPRIGHT() computes central finite-difference Jacobians of
%   dynamics. The linear and nonlinear models therefore share
%   one implementation of the equations of motion.
%
%   State ordering:
%     x = [cart_x, phi1, phi2, phi3, cart_dx, phi1_dot, phi2_dot, phi3_dot]^T
%   where phi_k = theta_k - pi  (angle from the upward vertical).
%   Upright equilibrium: x_e = zeros(8,1), u_e = 0.
%
%   Returns:
%     L.A, L.B, L.C, L.D, L.x_e, L.u_e, L.Ts, L.notes
%     L.Ad, L.Bd                    - exact discrete-time equivalents
%     L.controllability_rank        - rank(ctrb(L.A, L.B))

    p = load_base_model();
    x_e = p.target_state;
    u_e = 0;
    if p.cart_friction ~= 0 || any(p.joint_friction ~= 0)
        error('linearize_model:NonSmoothFriction', ...
            'Set friction_loss to zero before analytical linearization.');
    end
    if norm(dynamics(x_e, u_e, p), inf) > 1e-9
        error('linearize_model:TargetNotEquilibrium', ...
            'Configured target angles are not an unforced equilibrium. Use upright angles for LQR.');
    end
    step = 1e-6;
    A = zeros(8, 8);
    for k = 1:8
        delta = zeros(8, 1);
        delta(k) = step;
        A(:, k) = (dynamics(x_e + delta, u_e, p) - ...
                   dynamics(x_e - delta, u_e, p)) / (2 * step);
    end
    B = (dynamics(x_e, u_e + step, p) - ...
         dynamics(x_e, u_e - step, p)) / (2 * step);
    L = struct();
    L.A   = A;
    L.B   = B;
    L.C   = eye(8);
    L.D   = zeros(8,1);
    L.x_e = x_e;
    L.u_e = u_e;
    L.Ts  = p.Ts;
    L.notes = ['State x = [x, phi1, phi2, phi3, dx, dphi1, dphi2, dphi3]. ', ...
               'phi_k measured from the upward vertical (phi=0 at upright).'];

    % Exact discretization via matrix exponential.
    n = size(A,1);
    M = expm([A, B; zeros(1,n), zeros(1,1)] * p.Ts);
    L.Ad = M(1:n, 1:n);
    L.Bd = M(1:n, n+1:end);
    L.controllability_rank = rank(ctrb(A, B));

    save(fullfile(fileparts(mfilename('fullpath')), 'linear_model.mat'), '-struct', 'L');
end
