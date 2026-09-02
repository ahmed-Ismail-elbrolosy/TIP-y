function [q_mj, dq_mj] = state_to_mujoco(x)
%TO_MUJOCO_STATE Convert direct absolute angles to MuJoCo relative joints.
%
%   TIPy state x uses absolute angles measured from the upward vertical
%   (phi_k = 0 corresponds to upright).
%   MuJoCo XML stores relative joint angles around each hinge. Positive
%   angles have the same direction in both representations.
%
%   Conversion (cart position unchanged):
%     q_mj(1)   = x(1)                       (cart position)
%     q_mj(2)   = x(2)                        (hinge 1)
%     q_mj(3)   = x(3) - x(2)                 (hinge 2)
%     q_mj(4)   = x(4) - x(3)                 (hinge 3)
%     dq_mj(k)  = time derivative of q_mj(k)
%
%   The cart-force actuator maps directly between MATLAB and MuJoCo.
    q  = x(1:4);
    dq = x(5:8);
    q_mj   = zeros(4,1);
    dq_mj  = zeros(4,1);
    q_mj(1)  = q(1);
    q_mj(2)  = q(2);
    q_mj(3)  = q(3) - q(2);
    q_mj(4)  = q(4) - q(3);
    dq_mj(1) = dq(1);
    dq_mj(2) = dq(2);
    dq_mj(3) = dq(3) - dq(2);
    dq_mj(4) = dq(4) - dq(3);
end
