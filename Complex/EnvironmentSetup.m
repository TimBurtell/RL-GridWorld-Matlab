
function [ObsInfo, ActInfo, StepFcn, ResetFcn] = EnvironmentSetup()

    % https://www.mathworks.com/help/reinforcement-learning/ref/rl.util.rlfinitesetspec.html
    % https://www.mathworks.com/help/reinforcement-learning/ref/rl.util.rlnumericspec.html
    ObsInfo = rlNumericSpec([3, 3, 5]);
    ObsInfo.Name = "Observation";
    ObsInfo.Description = "field, crumb, row, col, fuel, fuelstart, moves";

    ActInfo = rlFiniteSetSpec([1: 8]);
    ActInfo.Name = "Action";
    ActInfo.Description = "Probabilities of move decision: 1:4 - Move NESW, 5:8 - Mine NESW";

    StepFcn = @stepSimulation; 
    ResetFcn = @resetSimulation;
end

function [InitialObservation, LoggedSignals] = resetSimulation()

    testfile = [];
    persistent seed;
    if isempty(seed)
        %  seeds = 4000:5183;
        seed = 4000;        
    end
    if isempty(testfile)
        rng(seed);
        seed = seed + 1;
        fieldstart = randomgrid();
    else
        fieldstart = load(testfile);
    end
    
    % Init conditions
    fuelratio = 10;
    [rowmax colmax] = size(fieldstart);
    crumbstart = zeros(rowmax, colmax);
    
    
    % find and clear start and survivor locations
    botstart = findit(fieldstart, -1);
    fieldstart(botstart(1), botstart(2)) = 0;
    survivor = findit(fieldstart, -2);
    fieldstart(survivor(1), survivor(2)) = 0;
    fuelstart = (rowmax + colmax) * fuelratio; 
    fuel        = fuelstart;
    location(:) = botstart;
    field(:, :) = fieldstart;
    crumb(:, :) = crumbstart;

    % initial fuel = 10 per (row + col)
    
    LoggedSignals.fuelstart = fuelstart;
    LoggedSignals.survivor = survivor;
    LoggedSignals.rowmax = rowmax;
    LoggedSignals.colmax = colmax;
    LoggedSignals.fuel        = fuelstart;
    LoggedSignals.location(:) = botstart;
    LoggedSignals.field(:, :) = fieldstart;
    LoggedSignals.crumb(:, :) = crumbstart;
    LoggedSignals.time = 0;
    LoggedSignals.botstart = botstart;

    
    InitialObservation = normalizeObservation(field, crumb, survivor, location, botstart, fuel / fuelstart);

end



function [Observation, Reward, IsDone, LoggedSignals] = stepSimulation(Action, LoggedSignals)

    IsDone = 0;
    Reward = 0;
    fuelspent = 0;

    % Simulation parameters
    drillcost = 20;
    movelimit = 10;

    % Unpack for refactor 
    fuelstart = LoggedSignals.fuelstart;
    survivor = LoggedSignals.survivor; 
    rowmax = LoggedSignals.rowmax;    
    colmax = LoggedSignals.colmax;    
    fuelleft = LoggedSignals.fuel;
    location = LoggedSignals.location;
    field = LoggedSignals.field;
    crumb = LoggedSignals.crumb;
    time = LoggedSignals.time;
    botstart = LoggedSignals.botstart;
    
    time = time + 1;
    row = location(1);
    col = location(2);

    %move = robot(direction, sensors, crumbs, turns, fuelleft, fuelstart);
    % Neural network output is a [1x8] softmax. Use this to randomly decide on a move

    % Action = abs(Action);
    % x = cumsum([0 Action(:).'/sum(Action(:))]);
    % x(end) = 1e3 * eps + x(end);
    % [move  move] = histc(rand, x);
    move = Action;
    
    % update crumb after move determination, but before we'ved moved
    crumb(row, col) = crumb(row, col) + 1;

    invalidMovePenalty = -30;
    if fuelleft <= 0
        %No fuel
        IsDone = 1;
    elseif move == 1   % North
        if row > 1      % not at edge
            if moveok(field(row - 1, col), movelimit) % can move through
                row = row - 1;
                fuelspent = fuelspent + field(row, col); % terrain cost
                %Moved North
            else
                Reward = Reward + invalidMovePenalty;
                %Cannot move North
            end
        else
            Reward = Reward + invalidMovePenalty;
            %Cannot move North (edge)
        end
    elseif move == 2   % East
        if col < colmax % not at edge
            if moveok(field(row, col+1), movelimit) % can move through
                col = col + 1;
                fuelspent = fuelspent + field(row, col); % terrain cost
                %Moved East
            else
                Reward = Reward + invalidMovePenalty;
                %Cannot move East
            end
        else
                 Reward = Reward + invalidMovePenalty;
                %Cannot move East (edge)
        end
    elseif move == 3   % South
        if row < rowmax % not at edge
            if moveok(field(row + 1, col), movelimit) % can move through
                row = row + 1;
                fuelspent = fuelspent + field(row, col); % terrain cost
                %Moved South
            else
                Reward = Reward + invalidMovePenalty;
                %Cannot move South
            end
        else
            Reward = Reward + invalidMovePenalty;
            %Cannot move South (edge)
        end
    elseif move == 4   % West
        if col > 1      % not at edge
            if moveok(field(row, col - 1), movelimit) % can move through
                col = col - 1;
                fuelspent = fuelspent + field(row, col); % terrain cost
                %Moved West
            else
                Reward = Reward + invalidMovePenalty;
                %Cannot move West
            end
        else
            Reward = Reward + invalidMovePenalty;
            %Cannot move West (edge)
        end
    elseif move == 5   % Drill North
        fuelspent = fuelspent + drillcost;
        if row > 1      % not at edge
            field(row - 1, col) = 0;
            %Drilled North
        else
            Reward = Reward + invalidMovePenalty;            
            %Cannot drill North
        end
    elseif move == 6   % Drill East
        fuelspent = fuelspent + drillcost;
        if col < colmax % not at edge
            field(row, col + 1) = 0;
            %Drilled East
        else
            Reward = Reward + invalidMovePenalty;
            %Cannot drill East
        end
    elseif move == 7   % Drill South
        fuelspent = fuelspent + drillcost;
        if row < rowmax % not at edge
            field(row + 1, col) = 0;
            %Drilled South
        else
            Reward = Reward + invalidMovePenalty;
            %Cannot drill South
        end
    elseif move == 8   % Drill West
        fuelspent = fuelspent + drillcost;
        if col > 1      % not at edge
            field(row, col - 1) = 0;
            %Drilled West
        else
            Reward = Reward + invalidMovePenalty;            
            %Cannot drill West
        end
    else
        disp('Robot: Invalid command')
    end
    
    location(:) = [row; col];
    
    % always costs 1
    fuelspent = fuelspent + 1; 

    fuelleft = fuelleft - fuelspent;    
    
    if fuelleft <= 0
        IsDone = 1;
    end
    if location(1) == survivor(1) && location(2) == survivor(2)
        %At survivor!!!
        disp('At Surivor!');
        IsDone = 1;
    end

    direction = norm(survivor - location(:));
    startDistance = norm(survivor - botstart);
    % Negative reward for spending fuel
    % Reward = Reward + (10 - fuelspent);
    Reward = Reward + 10 * (1 - direction/startDistance);
    %Reward = Reward - exp(.001 * time);
        
    
    Observation = normalizeObservation(field, crumb, survivor, location, botstart, fuelleft / fuelstart);


    % Repack for refactor 
    LoggedSignals.fuel = fuelleft;
    LoggedSignals.location = location;
    LoggedSignals.field = field;
    LoggedSignals.crumb = crumb;
    LoggedSignals.time = time;

end


function [Observation] = normalizeObservation(field, crumb, direction, location, botstart, fuelPercent) 

    direction = direction/norm(direction); 
    sens = sensor(field(:, :), location(:)); 
    crum = sensor(crumb(:, :), location(:));
    
    Observation(:,:,1) = sens / 20; 
    Observation(:,:,2) = crum ~= zeros(size(crum));
    Observation(:,:,3) = direction(1) * eye(3);
    Observation(:,:,4) = direction(2) * eye(3);
    Observation(:,:,5) = fuelPercent * eye(3);
    % DV Matrix: % eye(3) or ones(3,3)?
end

function out = sensor(f, location)
    fbo = 99 * ones(size(f) + 2);
    fbo(2:end - 1, 2:end - 1) = f;
    row = location(1) + 1;
    col = location(2) + 1;
    out = fbo(row - 1:row + 1, col - 1:col + 1);
end 

function out = findit(f, value)
    out = [-1; -1];
    for r = 1:size(f, 1)
        for c = 1:size(f, 2)
            if f(r,c) == value
                out = [r; c];
                return
            end
        end
    end
end 

function out = moveok(value, movelimit)
    out = (value <= movelimit);
end 

