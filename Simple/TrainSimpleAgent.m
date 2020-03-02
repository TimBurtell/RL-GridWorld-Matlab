

%parametername = 
%for parameter = 1:.01:10;

    %% Create the Environment for the actor. This replaces the map load/ and timestepping behavior 
    % https://www.mathworks.com/help/reinforcement-learning/ref/rl.env.rlfunctionenv.html
    [observationInfo, actionInfo, stepFunction, resetFunction] = SimpleEnvironment();
    env = rlFunctionEnv(observationInfo, actionInfo, stepFunction, resetFunction);


    %% Create the Actor. This replaces the robot() function
    % Create network 
    inputDimensions = observationInfo.Dimension;
    numActions = 4;
    actorNetwork = ...
    [ ...
        imageInputLayer(inputDimensions, 'Normalization', 'none', 'Name', 'state'), ...
        fullyConnectedLayer(50, 'Name', 'H1'), ... 
        reluLayer, ...
        dropoutLayer(.5), ...        
        fullyConnectedLayer(50, 'Name', 'H2') ...  
        reluLayer, ...
        dropoutLayer(.5), ...
        fullyConnectedLayer(numActions, 'Name', 'H3'), ... 
        reluLayer, ...
        softmaxLayer('Name', 'action')
    ];         

    % https://www.mathworks.com/help/reinforcement-learning/ref/rlrepresentationoptions.html
    actorOptions = rlRepresentationOptions;
    actorOptions.LearnRate = 0.01;
    actorOptions.Optimizer = 'adam';
    actorOptions.OptimizerParameters.Epsilon = 1e-7;
    actorOptions.OptimizerParameters.GradientDecayFactor = 0.9; 
    actorOptions.OptimizerParameters.SquaredGradientDecayFactor = 0.999;
    actorOptions.GradientThreshold = Inf; % .01
    actorOptions.L2RegularizationFactor = 0.0001;
    actorOptions.UseDevice = "gpu";

    actor = rlRepresentation(actorNetwork, actorOptions, ...
            'Observation', {'state'}, observationInfo, ... 
            'Action', {'action'}, actionInfo);

    % https://www.mathworks.com/help/reinforcement-learning/ref/rlpgagentoptions.html
    agentOptions = rlPGAgentOptions; 
    agentOptions.EntropyLossWeight = .9;
    agentOptions.DiscountFactor = .9;
    agentOptions.UseBaseline = false;
    
    %% Train the network 
    global agent;
    agent = rlPGAgent(actor, agentOptions);
    trainOptions = rlTrainingOptions;
    trainOptions.ScoreAveragingWindowLength = 50;
    trainOptions.MaxEpisodes = 100000;
    trainOptions.MaxStepsPerEpisode = 60;
    trainOptions.Verbose = 0;


    trainResults = train(agent, env, trainOptions);
    filename = sprintf('%s_%f_%s.mat', parametername, parameter, datestr('SS:MM:HH:dd:mm'));
    save(filename, 'agent', 'trainResults');
%end