function tests = test_mujoco_mapping()
%TEST_MUJOCO_MAPPING Round-trip the model-local state conversion.
%
%   Verifies that converting the absolute-angle state to MuJoCo relative
%   angles and back recovers the original state exactly.

    addpath(fullfile(fileparts(fileparts(mfilename('fullpath')))));
    tests = functiontests(localfunctions());
end

function test_round_trip(testCase)
    x = [0.1; 0.05; -0.03; 0.02; -0.2; 0.4; -0.5; 0.1];
    [q_mj, dq_mj] = state_to_mujoco(x);
    x_rec = state_from_mujoco(q_mj, dq_mj);
    verifyEqual(testCase, x_rec, x, 'AbsTol', 1e-12);
end

function test_upright_at_origin(testCase)
    % Upright corresponds to phi = 0 and thus q_mj = [x, 0, 0, 0]^T.
    x = [0; 0; 0; 0; 0; 0; 0; 0];
    [q_mj, dq_mj] = state_to_mujoco(x);
    verifyEqual(testCase, q_mj(2:4), [0;0;0], 'AbsTol', 1e-12);
    verifyEqual(testCase, dq_mj(2:4), [0;0;0], 'AbsTol', 1e-12);
end

function test_hanging_angles_are_direct_and_relative(testCase)
    x = [0; pi; pi; pi; 0; 0; 0; 0];
    [q_mj, dq_mj] = state_to_mujoco(x);
    verifyEqual(testCase, q_mj, [0; pi; 0; 0], 'AbsTol', 1e-12);
    verifyEqual(testCase, dq_mj, zeros(4,1), 'AbsTol', 1e-12);
    verifyEqual(testCase, state_from_mujoco(q_mj, dq_mj), x, ...
        'AbsTol', 1e-12);
end
