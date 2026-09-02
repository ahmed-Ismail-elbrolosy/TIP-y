function p = load_base_model()
%LOAD_BASE_MODEL Load canonical triple-pendulum parameters from JSON.
%   p = parameters() returns a struct with the constants used throughout the
%   MATLAB model, the Simulink model and the controller design. All fields are
%   dimensionless unless the name implies otherwise.
%
%   Conventions:
%     * q     = [x, phi1, phi2, phi3]^T   cart position (m) and pole angles
%                                       measured from the upward vertical
%                                       (rad). phi = 0 corresponds to the
%                                       upright configuration.
%     * Upright equilibrium: q_e = [0; 0; 0; 0], all velocities zero.
%     * MuJoCo stores relative joint angles with q=0 representing upright;
%       the conversion is implemented in state_to_mujoco.m.
%
%   See also dynamics, linearize, state_to_mujoco.

    path = fullfile(fileparts(mfilename('fullpath')), 'base_model.json');
    raw = jsondecode(fileread(path));
    p = struct();
    p.mc = raw.cart.mass;
    p.dc = raw.cart.damping;
    p.cart_friction = raw.cart.friction_loss;
    p.rail = raw.cart.rail_limit;
    p.m = raw.links.mass(:);
    p.l = raw.links.length(:);
    p.width = raw.links.width(:);
    p.depth = raw.links.depth(:);
    p.com = 0.5 .* p.l;
    p.Iyy = (1/12) .* p.m .* (p.width.^2 + p.l.^2);
    p.dq = raw.links.damping(:);
    p.joint_friction = raw.links.friction_loss(:);
    p.g = raw.gravity;
    p.u_max = raw.actuator.force_limit;
    p.Ts = raw.timestep;
    p.target_x = raw.target.cart_position;
    p.target_angles = raw.target.angles(:);
    p.target_state = [p.target_x; p.target_angles; zeros(4, 1)];
end
