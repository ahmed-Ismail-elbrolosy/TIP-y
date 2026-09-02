function K = controller(varargin)
%DESIGN_LQR  Design a discrete-time LQR gain for the TIPy plant.
%
%   K = controller() uses default weighting matrices.
%   K = controller('Q', Q, 'R', R) accepts custom 8x8 Q and scalar R.
%
%   The gain regulates deviations dx = x - x_e to zero with the discrete LQR
%   law  u = -K dx + u_e.
%
%   Default weights:
%     Q = diag([ 30,   20, 15, 10,    1,   1, 0.7, 0.5 ])
%         (cart position, each pole angle, cart velocity, each pole rate)
%     R = 0.05      (scaled to keep |u| < 20 N for typical initial errors)
%
%   The angle state components use phi_k = theta_k - pi, so a value of pi in
%   the original convention is a zero in the regulation state.

    L = linearize_model();
    defaults = struct( ...
        'Q', diag([30, 20, 15, 10, 1, 1, 0.7, 0.5]), ...
        'R', 0.05);
    for k = 1:2:numel(varargin)
        defaults.(varargin{k}) = varargin{k+1};
    end
    Q = defaults.Q;
    R = defaults.R;
    if isscalar(R)
        R = R * eye(1);
    end

    K = dlqr(L.Ad, L.Bd, Q, R);

    out = struct();
    out.K = K;
    out.Q = Q;
    out.R = R;
    out.notes = 'LQR law: u = -K*(x - x_e) + u_e.  phi = theta - pi, upright at phi=0.';
    out.closed_loop_eigs = eig(L.Ad - L.Bd * K);
    out.max_control_dphi_05 = max(abs(K * [0; 0.05; 0.05; 0.05; 0; 0; 0; 0]));
    out.max_control_dphi_10 = max(abs(K * [0; 0.10; 0.10; 0.10; 0; 0; 0; 0]));

    save(fullfile(fileparts(mfilename('fullpath')), 'lqr_gain.mat'), ...
         '-struct', 'out');
end
