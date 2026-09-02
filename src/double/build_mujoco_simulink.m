function build_mujoco_simulink(varargin)
%BUILD_MUJOCO_SIMULINK Create the double-pendulum MuJoCo Plant model.
%
%   The generated model uses the MathWorks MuJoCo Simulink Blockset. Its
%   State output is [x, phi1, phi2, dx, dphi1, dphi2], where pole angles
%   are wrapped absolute, direct-sign angles reconstructed from MuJoCo
%   joints. A short force pulse breaks symmetry at the hanging start.

    open_flag = true;
    for k = 1:2:numel(varargin)
        switch varargin{k}
            case 'Open'
                open_flag = logical(varargin{k + 1});
            otherwise
                error('build_mujoco_simulink: unknown option %s', varargin{k});
        end
    end

    here = fileparts(mfilename('fullpath'));
    sys = 'tipy_double_mujoco';
    model_path = fullfile(here, 'model.xml');
    slx_path = fullfile(here, [sys '.slx']);
    config = jsondecode(fileread(fullfile(here, 'base_model.json')));
    sample_time = config.timestep;
    force_limit = config.actuator.force_limit;
    kick_force = 1.0;
    kick_duration = 0.05;
    sensors = strjoin({ ...
        'cart_position', 'pole1_relative_angle', 'pole2_relative_angle', ...
        'cart_velocity', 'pole1_relative_velocity', 'pole2_relative_velocity'}, ',');

    if bdIsLoaded(sys)
        close_system(sys, 0);
    end
    if isfile(slx_path)
        delete(slx_path);
    end

    load_system('simulink');
    load_system('mjLib');
    new_system(sys);
    set_param(sys, 'SolverType', 'Fixed-step', 'Solver', 'FixedStepDiscrete', ...
        'FixedStep', num2str(sample_time, 17), 'StopTime', '10');

    add_block('mjLib/MuJoCo Plant', [sys '/MuJoCo Plant'], ...
        'Position', [450 170 600 260]);
    set_param([sys '/MuJoCo Plant'], ...
        'xmlFileRel', model_path, 'depthOutOption', 'off');

    add_block('simulink/Sources/Step', [sys '/Kick on'], ...
        'Time', '0', 'Before', '0', 'After', num2str(kick_force, 17), ...
        'Position', [180 175 230 205]);
    add_block('simulink/Sources/Step', [sys '/Kick off'], ...
        'Time', num2str(kick_duration, 17), 'Before', '0', ...
        'After', num2str(-kick_force, 17), 'Position', [180 225 230 255]);
    add_block('simulink/Math Operations/Sum', [sys '/Startup kick'], ...
        'Inputs', '++', 'Position', [270 195 300 225]);
    add_block('simulink/Discontinuities/Saturation', [sys '/Force limit'], ...
        'UpperLimit', num2str(force_limit, 17), ...
        'LowerLimit', num2str(-force_limit, 17), ...
        'Position', [350 190 400 230]);
    add_line(sys, 'Kick on/1', 'Startup kick/1');
    add_line(sys, 'Kick off/1', 'Startup kick/2');
    add_line(sys, 'Startup kick/1', 'Force limit/1');
    add_line(sys, 'Force limit/1', 'MuJoCo Plant/1');

    add_block('simulink/Signal Routing/Bus Selector', [sys '/Sensors'], ...
        'OutputSignals', sensors, 'Position', [670 155 760 285]);
    add_line(sys, 'MuJoCo Plant/1', 'Sensors/1');

    add_block('simulink/Math Operations/Sum', [sys '/phi2'], ...
        'Inputs', '++', 'Position', [830 195 860 225]);
    add_block('simulink/Math Operations/Sum', [sys '/dphi2'], ...
        'Inputs', '++', 'Position', [830 255 860 285]);
    add_line(sys, 'Sensors/2', 'phi2/1');
    add_line(sys, 'Sensors/3', 'phi2/2');
    add_line(sys, 'Sensors/5', 'dphi2/1');
    add_line(sys, 'Sensors/6', 'dphi2/2');

    add_block('simulink/User-Defined Functions/Fcn', [sys '/Wrap phi1'], ...
        'Expr', 'atan2(sin(u),cos(u))', 'Position', [880 170 950 200]);
    add_block('simulink/User-Defined Functions/Fcn', [sys '/Wrap phi2'], ...
        'Expr', 'atan2(sin(u),cos(u))', 'Position', [880 210 950 240]);
    add_line(sys, 'Sensors/2', 'Wrap phi1/1');
    add_line(sys, 'phi2/1', 'Wrap phi2/1');

    add_block('simulink/Signal Routing/Mux', [sys '/State'], ...
        'Inputs', '6', 'Position', [990 170 995 300]);
    add_line(sys, 'Sensors/1', 'State/1');
    add_line(sys, 'Wrap phi1/1', 'State/2');
    add_line(sys, 'Wrap phi2/1', 'State/3');
    add_line(sys, 'Sensors/4', 'State/4');
    add_line(sys, 'Sensors/5', 'State/5');
    add_line(sys, 'dphi2/1', 'State/6');

    add_block('simulink/Sinks/Scope', [sys '/State Scope'], ...
        'Position', [1070 170 1100 200]);
    add_block('simulink/Sinks/To Workspace', [sys '/State Log'], ...
        'VariableName', 'tipy_double_state', 'SaveFormat', 'Array', ...
        'Position', [1060 250 1150 280]);
    add_line(sys, 'State/1', 'State Scope/1');
    add_line(sys, 'State/1', 'State Log/1');

    save_system(sys, slx_path);
    if open_flag
        open_system(sys);
    else
        close_system(sys, 0);
    end
end
