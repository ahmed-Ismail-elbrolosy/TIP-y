function xdot = dynamics(x, u, p)
%NONLINEAR_DYNAMICS  Continuous-time dynamics of the TIPy plant.
%   xdot = NONLINEAR_DYNAMICS(x, u, p) returns dx/dt for the TIPy cart plus
%   triple pendulum under cart force u, using the parameters p from
%   load_base_model().
%
%   State x = [x; phi1; phi2; phi3; dx; dphi1; dphi2; dphi3]
%   with phi_k measured from the upward vertical (phi = 0 at upright).
%   Input u is a scalar cart force, |u| <= p.u_max.

    if nargin < 3
        p = load_base_model();
    end
    q  = x(1:4);
    dq = x(5:8);
    M = mass_matrix(q, dq, p);
    h = bias_forces(q, dq, p);
    B = [1; 0; 0; 0];
    acc = M \ (B*u - h);
    xdot = [dq; acc];
end
