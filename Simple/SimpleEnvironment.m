
function [ObsInfo, ActInfo, StepFcn, ResetFcn] = EnvironmentSetup()

    % https://www.mathworks.com/help/reinforcement-learning/ref/rl.util.rlfinitesetspec.html
    % https://www.mathworks.com/help/reinforcement-learning/ref/rl.util.rlnumericspec.html
    ObsInfo = rlNumericSpec([3, 3, 5]);
    ObsInfo.Name = "Observation";
    ObsInfo.Description = "";

    ActInfo = rlFiniteSetSpec([1: 4]);
    ActInfo.Name = "Action";
    ActInfo.Description = "Probabilities of move decision: 1:4 - Move NESW, 5:8 - Mine NESW";

    StepFcn = @stepSimulation; 
    ResetFcn = @resetSimulation;
end

function [InitialObservation, LoggedSignals] = resetSimulation()

    
    persistent fieldstart;
    numfields = 2;
    if isempty(fieldstart)
        for k = 1:numfields 
            fieldstart{k} = randomgrid();
        end
    end
    field = fieldstart{floor(rand * numfields) + 1}; 
    
  
    % Init conditions
    fuelratio = 10;
    [rowmax colmax] = size(field);
    crumbstart = zeros(rowmax, colmax);
    
    % find and clear start and survivor locations
    botstart = findit(field, -1);
    field(botstart(1), botstart(2)) = 0;
    survivor = findit(field, -2);
    field(survivor(1), survivor(2)) = 0;
    fuelstart = (rowmax + colmax) * fuelratio; 
    fuel        = fuelstart;
    location(:) = botstart;
    crumb(:, :) = crumbstart;
    
    LoggedSignals.fuelstart = fuelstart;
    LoggedSignals.survivor = survivor;
    LoggedSignals.rowmax = rowmax;
    LoggedSignals.colmax = colmax;
    LoggedSignals.fuel        = fuelstart;
    LoggedSignals.location(:) = botstart;
    LoggedSignals.field(:, :) = field;
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
    
    
    % Place a debugger breakpoint here and set this variable to 1 to enable
    % vizualizer
    persistent vizualizerToggle;
    if vizualizerToggle == 1
        plotit(field, survivor, location, fuelleft);
    end 
    
    time = time + 1;
    row = location(1);
    col = location(2);

    move = Action;
    persistent movestats;
    if isempty(movestats)
        movestats(1) = 0;
        movestats(2) = 0;
        movestats(3) = 0;
        movestats(4) = 0;
    end

    movestats(move) = movestats(move) + 1;
    
    
    % Update crumb after move determination, but before we'ved moved
    crumb(row, col) = crumb(row, col) + 1;

    invalidMovePenalty = -.6;
    invaldMoveFuelCost = 0;
    switch move
        case 1   % North
            if row > 1  && moveok(field(row - 1, col))   
                row = row - 1;
                fuelspent = fuelspent + field(row, col);
            else
                fuelspent = fuelspent - invaldMoveFuelCost;
                Reward = Reward + invalidMovePenalty;
            end
        case 2   % East
            if col < colmax  && moveok(field(row, col + 1))
                col = col + 1;
                fuelspent = fuelspent + field(row, col); 
            else
                fuelspent = fuelspent - invaldMoveFuelCost;
                Reward = Reward + invalidMovePenalty;
            end
        case 3   % South
            if row < rowmax && moveok(field(row + 1, col)) 
                row = row + 1;
                fuelspent = fuelspent + field(row, col); 
            else
                fuelspent = fuelspent - invaldMoveFuelCost;
                Reward = Reward + invalidMovePenalty;
            end
        case 4      % West
            if col > 1 && moveok(field(row, col - 1))    
                col = col - 1;
                fuelspent = fuelspent + field(row, col); 
            else
                fuelspent = fuelspent - invaldMoveFuelCost;
                Reward = Reward + invalidMovePenalty;
            end
        otherwise
            disp('Robot: Invalid command')
    end
    
    location(:) = [row; col];
    fuelspent = fuelspent + 1; 
    fuelleft = fuelleft - fuelspent;    
    
    IsDone = fuelleft <= 0;
    if location(1) == survivor(1) && location(2) == survivor(2)
        fprintf('Fuel left: %d\n', fuelleft);
        IsDone = 1;
    end

    direction = norm(survivor - location(:));
    startDistance = norm(survivor - botstart);
    distanceRatio = startDistance / (.25 + direction);

    % define reward
    Reward = Reward + distanceRatio;

        
    
    % Repack for refactor 
    LoggedSignals.fuel = fuelleft;
    LoggedSignals.location = location;
    LoggedSignals.field = field;
    LoggedSignals.crumb = crumb;
    LoggedSignals.time = time;
    
    Observation = normalizeObservation(field, crumb, survivor, location, botstart, fuelleft / fuelstart);
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
    movelimit = 20;
    out = (value <= movelimit);
end 

function plotit(field, survivor, location, fuel)
    % fixed values
    survival  = 2000; % for color only
    robotval  = 1000; % for color only, needs to be far from field if scaled

    view = 40 + field(:, :);
    view(survivor(1), survivor(2)) = survival;
    view(location(1), location(2)) = robotval;
    image(view)
    title([' fuel = ' num2str(fuel)])
end
