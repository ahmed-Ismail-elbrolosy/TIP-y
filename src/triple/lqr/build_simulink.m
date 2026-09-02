function build_simulink(varargin)
%BUILD_SIMULINK Generate the Simulink model for the triple-pendulum LQR.
%
%   build_simulink() opens and regenerates tipy_triple_pendulum.slx.
%   build_simulink('Open', false) does not open it after building.
%
%   The model contains:
%     - a MATLAB-function S-function plant (`plant_sfun`) implementing dynamics.
%     - a controller subsystem that computes the current LQR gain and
%       applies u = -K*(x - x_e) + u_e, with saturation to |u_max|.
%     - scopes for each state and the control.
%
%   The model is generated programmatically so it is reproducible: re-running
%   build_simulink produces the same structure. State ordering is
%   x = [x, phi1, phi2, phi3, dx, dphi1, dphi2, dphi3].

    here      = fileparts(mfilename('fullpath'));
    sys       = 'tipy_triple_pendulum';
    slx_path  = fullfile(here, 'tipy_triple_pendulum.slx');
    open_flag = true;
    for k = 1:2:numel(varargin)
        switch varargin{k}
            case 'Open', open_flag = logical(varargin{k+1});
            otherwise, error('build_simulink: unknown option %s', varargin{k});
        end
    end

    p = load_base_model();
    L = linearize_model();
    K = controller();
    x0 = [0.05; 0.10; 0.05; 0.05; 0; 0; 0; 0];

    if bdIsLoaded(sys)
        close_system(sys, 0);
    end
    if exist(slx_path,'file')
        delete(slx_path);
    end
    load_system('simulink');
    new_system(sys);

    %% Step block: fixed-step solver.
    set_param(sys, 'SolverType', 'Fixed-step', ...
                   'Solver',     'ode4', ...
                   'FixedStep',  num2str(p.Ts), ...
                   'StopTime',  '10');
    open_system(sys);

    %% Plant block: Level-2 MATLAB S-function.
    add_block('simulink/User-Defined Functions/Level-2 MATLAB S-Function', ...
              [sys '/Plant'], ...
              'FunctionName', 'plant_sfun', ...
              'Parameters', mat2str(x0));

    %% Reference (upright) input and controller.
    add_block('simulink/Sources/Constant', [sys '/x_e'], ...
              'Value', mat2str(L.x_e, 8));
    add_block('simulink/Math Operations/Sum', [sys '/Sum_x'], ...
              'Inputs', '+-', 'ShowName', 'off');
    add_block('simulink/Math Operations/Gain', [sys '/LQR_K'], ...
              'Gain', mat2str(-K), 'Multiplication', 'Matrix(K*u)');
    add_block('simulink/Discontinuities/Saturation', [sys '/Sat'], ...
              'UpperLimit', num2str(p.u_max), ...
              'LowerLimit', num2str(-p.u_max));
    add_block('simulink/Sinks/Scope', [sys '/Scope_u']);

    add_line(sys, 'Plant/1', 'Sum_x/1');
    add_line(sys, 'x_e/1', 'Sum_x/2');
    add_line(sys, 'Sum_x/1', 'LQR_K/1');
    add_line(sys, 'LQR_K/1', 'Sat/1');
    add_line(sys, 'Sat/1', 'Plant/1');
    add_line(sys, 'Sat/1', 'Scope_u/1');

    %% Logging outputs.
    add_block('simulink/Sinks/To Workspace', [sys '/ToWS_state'], ...
              'VariableName', 'tipy_state', 'SaveFormat', 'Array');
    add_line(sys, 'Plant/1', 'ToWS_state/1');

    %% Demux and per-state scopes.
    add_block('simulink/Signal Routing/Demux', [sys '/Demux'], ...
              'Outputs', '8');
    add_line(sys, 'Plant/1', 'Demux/1');
    for k = 1:8
        add_block('simulink/Sinks/Scope', [sys sprintf('/Scope_x%d', k)]);
        add_line(sys, sprintf('Demux/%d', k), sprintf('Scope_x%d/1', k));
    end

    save_system(sys, slx_path);
    if ~open_flag
        bdclose(sys);
    end
end
