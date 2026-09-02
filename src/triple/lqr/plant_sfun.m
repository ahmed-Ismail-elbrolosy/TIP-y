function plant_sfun(block)
%TRIPLE_PENDULUM_SFUN  Level-2 MATLAB S-function implementing the TIPy plant.
%
%   Inputs (block.InputPort(1).Data): u [scalar cart force]
%   States (block.ContStates.Data): 8-element vector in TIPy convention
%   Outputs (block.OutputPort(1).Data): same 8-element state vector

    setup(block);
end

function setup(block)
    %% Register dialog parameter: initial state x0.
    block.NumDialogPrms = 1;

    %% Ports.
    block.NumInputPorts  = 1;
    block.NumOutputPorts = 1;
    block.SetPreCompInpPortInfoToDynamic;
    block.SetPreCompOutPortInfoToDynamic;
    block.InputPort(1).Dimensions = 1;
    block.InputPort(1).DirectFeedthrough = false;
    block.OutputPort(1).Dimensions = 8;

    %% Sample times.
    block.SampleTimes = [0 0];

    %% States.
    block.NumContStates = 8;

    %% Functions.
    block.RegBlockMethod('InitializeConditions', @init_conditions);
    block.RegBlockMethod('Derivatives',         @derivatives);
    block.RegBlockMethod('Outputs',             @outputs);
end

function init_conditions(block)
    x0 = block.DialogPrm(1).Data;
    validateattributes(x0, {'numeric'}, {'real', 'finite', 'vector', 'numel', 8});
    block.ContStates.Data = x0(:);
end

function derivatives(block)
    x = block.ContStates.Data;
    u = block.InputPort(1).Data;
    p = load_base_model();
    block.Derivatives.Data = dynamics(x, u, p);
end

function outputs(block)
    block.OutputPort(1).Data = block.ContStates.Data;
end
