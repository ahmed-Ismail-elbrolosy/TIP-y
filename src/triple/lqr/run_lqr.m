function [t_open, x_open, t_lqr, x_lqr, u_lqr, K] = run_lqr()
%RUN_DEMO  Open-loop and closed-loop rollouts of the TIPy plant in MATLAB.
%
%   Simulates two rollouts of the analytical TIPy plant using
%   dynamics and ode45:
%     1. zero-input response from a small perturbation around upright;
%     2. LQR-regulated response from a larger perturbation.
%
%   Outputs:
%     t         - simulation time vector (s)
%     x_open    - state trajectory for the open-loop rollout
%     x_lqr     - state trajectory for the LQR-regulated rollout
%     u_lqr     - applied control sequence for the LQR rollout
%     K         - LQR gain matrix

    p = load_base_model();
    L = linearize_model();
    K = controller();

    %% Open-loop: zero input, perturbed initial state.
    t_end = 1.0;
    x0_open = [0; 0.10; 0.05; 0.05; 0; 0; 0; 0];
    odefun_open = @(t,x) dynamics(x, 0.0, p);
    sol = ode45(odefun_open, [0 t_end], x0_open);
    t_open = sol.x;
    x_open = sol.y;

    %% Closed-loop: LQR with saturation.
    x0_lqr = [0; 0.20; 0.15; 0.10; 0; 0; 0; 0];
    t_lqr = (0:p.Ts:5.0)';
    x_lqr = zeros(8, numel(t_lqr));
    u_lqr = zeros(1, numel(t_lqr));
    xk = x0_lqr;
    for k = 1:numel(t_lqr)
        x_lqr(:,k) = xk;
        dx = xk - L.x_e;
        u = -K * dx;
        u = max(min(u, p.u_max), -p.u_max);
        u_lqr(k) = u;
        if k < numel(t_lqr)
            sol = ode45(@(t,x) dynamics(x, u, p), ...
                        [t_lqr(k) t_lqr(k+1)], xk);
            xk = deval(sol, t_lqr(k+1));
        end
    end

    %% Plots.
    figure('Color','w');
    subplot(2,1,1);
    plot(t_open, x_open([2 3 4],:).'); grid on; hold on;
    ylabel('open-loop pole angles (rad)');
    legend('\phi_1','\phi_2','\phi_3');

    subplot(2,1,2);
    plot(t_lqr, x_lqr([2 3 4],:).', t_lqr, x_lqr(1,:));
    grid on;
    ylabel('LQR-regulated response');
    xlabel('time (s)');
    legend('\phi_1','\phi_2','\phi_3','x');
end
