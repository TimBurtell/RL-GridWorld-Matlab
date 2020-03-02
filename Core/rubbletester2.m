function score = rubbleRunner()
% this function runs rubble3 on every grid in the testgrids folder
% the function also runs rubble3 on a bunch of random grids based on seeds.
% the total is added and it returns the total amount of fuel remaining
% for a set of robot algorithms

numbots   = 4;
robotfuel = zeros(1, numbots); % numbots

in = 'testgrids';
   % in is a folder name
   files = dir(in);
   for i = 1:length(files)
      if ~files(i).isdir
         testfile = [in '/' files(i).name];
         fuel = rubble3(testfile, numbots);
         robotfuel = robotfuel + fuel;
      end
   end
robotfuelsav = robotfuel;

in = 4000:5183;
   % in is a vector of random seeds
   for i = 1:length(in)
      rng(in(i));
      fuel = rubble3('random', numbots);
      %if fuel(4) > fuel(2)+30
      %   [in(i) fuel fuel(4)-fuel(2)]
      %end
      robotfuel = robotfuel + fuel;
   end

metric = robotfuel - 200000;
score  = min(60, round(metric/1680));
%score  = max(0, score);
fprintf('\nBots:                           robot      robot2   robot3   robot4')
fprintf('\nFuel remaining after testgrids: %8i %8i %8i %8i', robotfuelsav)
fprintf('\nFuel remaining on random grids: %8i %8i %8i %8i', robotfuel - robotfuelsav)
fprintf('\nTotal fuel remaining:           %8i %8i %8i %8i', robotfuel)
fprintf('\nImprovement over initial:       %8i %8i %8i %8i', metric)
fprintf('\nResulting score:                %8i %8i %8i %8i', score)
fprintf('\n')


function [fuel] = rubble3(testfile, numbots)
% Rubble Rescue Robot
% P. Kominsky, 13 September 2012
% Modified by Dan Becker to support bulk trials

drillcost = 20;
movelimit = 10;
fuelratio = 10;


% rubble field
%testfile   = input(' Test file? ', 's');
if strcmp(testfile, 'random')
    fieldstart = randomgrid();
else
    fieldstart = load(testfile);
end
[rowmax colmax] = size(fieldstart);
crumbstart = zeros(rowmax, colmax);

% find and clear start and survivor locations
botstart = findit(fieldstart, -1);
fieldstart(botstart(1), botstart(2)) = 0;
survivor = findit(fieldstart, -2);
fieldstart(survivor(1), survivor(2)) = 0;

% initial fuel = 10 per (row + col)
fuelstart = (rowmax+colmax)*fuelratio;

% set up bots
for bot=1:numbots
   fuel(bot)        = fuelstart;
   location(:, bot) = botstart;
   field(:, :, bot) = fieldstart;
   crumb(:, :, bot) = crumbstart;
   notdone(bot)     = 1;
end

while (any(notdone))
   %go = input(' next? (enter to continue, anything to quit) ', 's');
   %if ~strcmp(go, '')
   %   break
   %end
   for bot=1:numbots
      %fprintf('Bot %i ', bot)
      row = location(1, bot);
      col = location(2, bot);

      direction = survivor - location(:, bot);
      sensors   = sensor(field(:, :, bot), location(:, bot));
      crumbs    = sensor(crumb(:, :, bot), location(:, bot));
      fuelleft  = fuel(bot);
      turns     = sum(sum(crumb(:, :, bot)));

      if location(1, bot) == survivor(1) && location(2, bot) == survivor(2)
         notdone(bot) = 0;
         move = 0;
      elseif bot==1
         move = robot(direction, sensors, crumbs, turns, fuelleft, fuelstart);
      elseif bot==2
         move = robot2(direction, sensors, crumbs, turns, fuelleft, fuelstart);
      elseif bot==3
         move = robot3(direction, sensors, crumbs, turns, fuelleft, fuelstart);
      elseif bot==4
         move = robot4(direction, sensors, crumbs, turns, fuelleft, fuelstart);
      end

      % update crumb after move determination
      crumb(row, col, bot) = crumb(row, col, bot) + 1;

      if fuel(bot) <= 0
         %disp(' No fuel')
         notdone(bot) = 0;
      elseif move==1   % North
         if row>1      % not at edge
            if moveok(field(row-1, col, bot), movelimit) % can move through
               row = row - 1;
               fuel(bot) = fuel(bot) - field(row, col, bot); % terrain cost
               %disp(' Moved North')
            else
               %disp(' Cannot move North')
            end
         else
               %disp(' Cannot move North (edge)')
         end
      elseif move==2   % East
         if col<colmax % not at edge
            if moveok(field(row, col+1, bot), movelimit) % can move through
               col = col + 1;
               fuel(bot) = fuel(bot) - field(row, col, bot); % terrain cost
               %disp(' Moved East')
            else
               %disp(' Cannot move East')
            end
         else
               %disp(' Cannot move East (edge)')
         end
      elseif move==3   % South
         if row<rowmax % not at edge
            if moveok(field(row+1, col, bot), movelimit) % can move through
               row = row + 1;
               fuel(bot) = fuel(bot) - field(row, col, bot); % terrain cost
               %disp(' Moved South')
            else
               %disp(' Cannot move South')
            end
         else
               %disp(' Cannot move South (edge)')
         end
      elseif move==4   % West
         if col>1      % not at edge
            if moveok(field(row, col-1, bot), movelimit) % can move through
               col = col - 1;
               fuel(bot) = fuel(bot) - field(row, col, bot); % terrain cost
               %disp(' Moved West')
            else
               %disp(' Cannot move West')
            end
         else
              % disp(' Cannot move West (edge)')
         end
      elseif move==5   % Drill North
         fuel(bot) = fuel(bot) - drillcost;
         if row>1      % not at edge
            field(row-1, col, bot) = 0;
            %disp(' Drilled North')
         else
            %disp(' Cannot drill North')
         end
      elseif move==6   % Drill East
         fuel(bot) = fuel(bot) - drillcost;
         if col<colmax % not at edge
            field(row, col+1, bot) = 0;
            %disp(' Drilled East')
         else
            %disp(' Cannot drill East')
         end
      elseif move==7   % Drill South
         fuel(bot) = fuel(bot) - drillcost;
         if row<rowmax % not at edge
            field(row+1, col, bot) = 0;
            %disp(' Drilled South')
         else
            %disp(' Cannot drill South')
         end
      elseif move==8   % Drill West
         fuel(bot) = fuel(bot) - drillcost;
         if col>1      % not at edge
            field(row, col-1, bot) = 0;
            %disp(' Drilled West')
         else
            %disp(' Cannot drill West')
         end
      elseif move==0
            %disp(' Waited')
      else
            %disp(' Invalid command')
      end
      location(:, bot) = [row; col];
      if notdone(bot)
         fuel(bot) = fuel(bot) - 1; % always costs 1
         if fuel(bot) <= 0
            notdone(bot) = 0;
         end
      end
      if location(1, bot) == survivor(1) && location(2, bot) == survivor(2)
         %disp(' At survivor!!!')
         notdone(bot) = 0;
      end
      %plotit(field, survivor, location, fuel, bot, numbots)
   end
end

fuel = max(zeros(1,numbots), fuel);

%if fuel > 0
%   disp([' Success, final fuel = ' num2str(fuel)])
%else
%   disp(' Failure, ran out of fuel')
%end


function out = sensor(f, location)
   fbo = 99*ones(size(f)+2);
   fbo(2:end-1, 2:end-1) = f;
   row = location(1)+1;
   col = location(2)+1;
   out = fbo(row-1:row+1,col-1:col+1);

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

function out = moveok(value, movelimit)
   out = (value <= movelimit);
