function tests = test_linearization()
%TEST_LINEARIZATION Validate the model-local upright linearization.
%
%   The A and B matrices are finite-difference Jacobians of the nonlinear
%   plant. These tests verify controllability and closed-loop stability.

    modelRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(modelRoot, fullfile(modelRoot, 'lqr'));
    tests = functiontests(localfunctions());
end

function test_controllable(testCase)
    L = linearize_model();
    verifyEqual(testCase, L.controllability_rank, 8);
end

function test_open_loop_unstable(testCase)
    L = linearize_model();
    eigs = eig(L.A);
    verifyGreaterThan(testCase, max(real(eigs)), 0.0);
end

function test_input_couples_to_angles(testCase)
    L = linearize_model();
    verifyGreaterThan(testCase, norm(L.B(6:8)), 1e-3);
end

function test_linearization_matches_nonlinear_plant(testCase)
    p = load_base_model();
    L = linearize_model();
    dx = [1; -2; 1; -1; 0.5; -0.5; 0.25; -0.25] * 1e-5;
    du = 2e-5;
    actual = dynamics(L.x_e + dx, L.u_e + du, p);
    predicted = L.A * dx + L.B * du;
    verifyLessThan(testCase, norm(actual - predicted, inf), 1e-7);
end

function test_lqr_stable(testCase)
    K = controller();
    L = linearize_model();
    cl = eig(L.Ad - L.Bd * K);
    verifyLessThan(testCase, max(abs(cl)), 1.0);
end
