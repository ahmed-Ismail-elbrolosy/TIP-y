function tests = test_simulink()
%TEST_SIMULINK Build and compile the generated Simulink model.
    tests = functiontests(localfunctions());
end

function setupOnce(testCase)
    modelRoot = fileparts(fileparts(mfilename('fullpath')));
    testCase.TestData.modelRoot = modelRoot;
    addpath(modelRoot, fullfile(modelRoot, 'lqr'));
end

function test_model_builds_and_compiles(testCase)
    assumeTrue(testCase, license('test', 'Simulink'), ...
        'Simulink license is unavailable.');
    assumeTrue(testCase, license('test', 'Control_Toolbox'), ...
        'Control System Toolbox license is unavailable.');

    model = 'tipy_triple_pendulum';
    modelFile = fullfile(testCase.TestData.modelRoot, 'lqr', [model '.slx']);
    cleanup = onCleanup(@() cleanup_model(model, modelFile)); %#ok<NASGU>
    build_simulink('Open', false);
    verifyTrue(testCase, isfile(modelFile));
    load_system(model);
    set_param(model, 'SimulationCommand', 'update');
    verifyEqual(testCase, get_param([model '/Plant'], 'FunctionName'), ...
        'plant_sfun');
end

function test_mujoco_model_builds_and_compiles(testCase)
    assumeTrue(testCase, license('test', 'Simulink'), ...
        'Simulink license is unavailable.');
    assumeTrue(testCase, exist('mj_sfun', 'file') == 3, ...
        'MuJoCo Simulink Blockset is unavailable.');

    model = 'tipy_triple_mujoco';
    modelFile = fullfile(testCase.TestData.modelRoot, [model '.slx']);
    cleanup = onCleanup(@() cleanup_model(model, modelFile)); %#ok<NASGU>
    build_mujoco_simulink('Open', false);
    verifyTrue(testCase, isfile(modelFile));
    load_system(model);
    set_param(model, 'SimulationCommand', 'update');
    verifyEqual(testCase, get_param([model '/MuJoCo Plant'], 'ReferenceBlock'), ...
        'mjLib/MuJoCo Plant');
    verifyEqual(testCase, get_param([model '/MuJoCo Plant'], 'xmlFileRel'), ...
        fullfile(testCase.TestData.modelRoot, 'model.xml'));
end

function cleanup_model(model, modelFile)
    if bdIsLoaded(model)
        close_system(model, 0);
    end
    if isfile(modelFile)
        delete(modelFile);
    end
end
