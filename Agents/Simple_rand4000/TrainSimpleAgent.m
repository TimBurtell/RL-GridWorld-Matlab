
%% Create the Environment for the actor. This replaces the map load/ and timestepping behavior 
% https://www.mathworks.com/help/reinforcement-learning/ref/rl.env.rlfunctionenv.html
[observationInfo, actionInfo, stepFunction, resetFunction] = SimpleEnvironment();
env = rlFunctionEnv(observationInfo, actionInfo, stepFunction, resetFunction);


%% Create the Actor. This replaces the robot() function
% Create network 
inputDimensions = observationInfo.Dimension;
numActions = 4;
actorNetwork =                                                                           ...
    [                                                                                    ...
        imageInputLayer(inputDimensions, 'Normalization', 'none', 'Name', 'state'),       ...
        fullyConnectedLayer(50, 'Name', 'H1'),                                          ... 
        leakyReluLayer,                                                                       ...
        fullyConnectedLayer(50, 'Name', 'H2'),                                           ...  
        leakyReluLayer,                                                                       ...
        fullyConnectedLayer(numActions, 'Name', 'H3'),                                            ... 
        leakyReluLayer,                                                                       ...
        softmaxLayer('Name', 'action')
    ];         
actorOptions = rlRepresentationOptions(...
                                        'LearnRate', 1e-2,        ...
                                       'GradientThreshold', .1,   ...
                                       'L2RegularizationFactor',0.0005, ...
                                       'UseDevice', "gpu");
actorOptions.OptimizerParameters.Epsilon = 1e-7;
actorOptions.OptimizerParameters.GradientDecayFactor = 0.9;
actorOptions.OptimizerParameters.SquaredGradientDecayFactor = 0.990;
actorOptions.OptimizerParameters.Momentum = .09;

actor = rlRepresentation(actorNetwork, actorOptions, ...
        'Observation', {'state'}, observationInfo,           ... 
        'Action', {'action'}, actionInfo);


%% Create agent using the actor
agentOptions = rlPGAgentOptions(  ...
        'UseBaseline', false,     ...
        'EntropyLossWeight', .9,      ...
        'DiscountFactor', .9);
agent = rlPGAgent(actor, agentOptions);

%% Train the network 
trainOptions = rlTrainingOptions(              ...
            'MaxEpisodes', 100000,                   ...
            'MaxStepsPerEpisode', 80,               ...
            'Verbose', 0,                            ...
            'SaveAgentDirectory', pwd  + "agents");


trainResults = train(agent, env, trainOptions);
save agent
%SimpleVisualizer(4000);
 