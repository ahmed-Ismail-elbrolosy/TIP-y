function tests = test_dynamics()
%TEST_DYNAMICS  Smoke tests for the analytical TIPy plant.
%
%   Validates equilibrium behavior and basic mass-matrix properties.
%
%   Run with: runtests(fullfile('src', 'triple', 'tests', 'test_dynamics.m'))

    addpath(fullfile(fileparts(fileparts(mfilename('fullpath')))));
    tests = functiontests(localfunctions());
end

function test_equilibrium_zero(testCase)
    p = load_base_model();
    x = zeros(8,1);
    xdot = dynamics(x, 0.0, p);
    verifyEqual(testCase, max(abs(xdot)), 0, 'AbsTol', 1e-12);
end

function test_perturbation_unstable(testCase)
    p = load_base_model();
    x = [0; 0.01; 0.0; 0.0; 0; 0; 0; 0];
    xdot = dynamics(x, 0.0, p);
    % phi1 should grow (upright is unstable).
    verifyGreaterThan(testCase, xdot(6), 0.0);
end

function test_inputs_change_dynamics(testCase)
    p = load_base_model();
    x = zeros(8,1);
    xdot0 = dynamics(x, 0.0, p);
    xdot1 = dynamics(x, 5.0, p);
    % Applying force changes cart acceleration.
    verifyNotEqual(testCase, xdot0(5), xdot1(5));
end

function test_mass_pd(testCase)
    p = load_base_model();
    q = [0; 0.1; 0.2; 0.3];
    dq = [0.5; 0.2; 0.1; 0.0];
    M = mass_matrix(q, dq, p);
    eigvals = eig(M);
    verifyEqual(testCase, M, M.', 'AbsTol', 1e-12);
    verifyGreaterThan(testCase, min(real(eigvals)), 1e-6);
end
