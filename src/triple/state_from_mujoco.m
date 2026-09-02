function x = state_from_mujoco(q_mj, dq_mj)
%STATE_FROM_MUJOCO Convert MuJoCo relative joints to direct absolute angles.

    phi1 = q_mj(2);
    phi2 = q_mj(2) + q_mj(3);
    phi3 = q_mj(2) + q_mj(3) + q_mj(4);
    x = zeros(8,1);
    x(1) = q_mj(1);
    x(2) = phi1;
    x(3) = phi2;
    x(4) = phi3;
    x(5) = dq_mj(1);
    x(6) = dq_mj(2);
    x(7) = dq_mj(2) + dq_mj(3);
    x(8) = dq_mj(2) + dq_mj(3) + dq_mj(4);
end
