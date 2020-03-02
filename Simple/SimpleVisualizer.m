   function rubble2(seed)
   % Rubble Rescue Robot
   % P. Kominsky, 13 September 2012

   drillcost = 20;
   movelimit = 20;
   fuelratio = 10;


   rng(seed)
   fieldstart = randomgrid();

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
   fuel        = fuelstart;
   location(:) = botstart;
   field(:, :) = fieldstart;
   crumb(:, :) = crumbstart;
   notdone     = 1;
   plotit(field, survivor, location, fuel)

   while notdone
      go = input(' next? (enter to continue, anything to quit) ', 's');
      if ~strcmp(go, '')
         break
      end

      row = location(1);
      col = location(2);

      direction = survivor - location(:);
      sensors   = sensor(field(:, :), location(:));
      crumbs    = sensor(crumb(:, :), location(:));
      fuelleft  = fuel;
      turns     = sum(sum(crumb(:, :)));

      if location(1) == survivor(1) && location(2) == survivor(2)
         notdone = 0;
         move = 0;
      else
         move = SimpleRobot(direction, sensors, crumbs, turns, fuelleft, fuelstart);
      end

      % update crumb after move determination
      crumb(row, col) = crumb(row, col) + 1;

      if fuel <= 0
         disp(' No fuel')
         notdone = 0;
      elseif move==1   % North
         if row>1      % not at edge
            if moveok(field(row-1, col), movelimit) % can move through
               row = row - 1;
               fuel = fuel - field(row, col); % terrain cost
               disp(' Moved North')
            else
               disp(' Cannot move North')
            end
         else
               disp(' Cannot move North (edge)')
         end
      elseif move==2   % East
         if col<colmax % not at edge
            if moveok(field(row, col+1), movelimit) % can move through
               col = col + 1;
               fuel = fuel - field(row, col); % terrain cost
               disp(' Moved East')
            else
               disp(' Cannot move East')
            end
         else
               disp(' Cannot move East (edge)')
         end
      elseif move==3   % South
         if row<rowmax % not at edge
            if moveok(field(row+1, col), movelimit) % can move through
               row = row + 1;
               fuel = fuel - field(row, col); % terrain cost
               disp(' Moved South')
            else
               disp(' Cannot move South')
            end
         else
               disp(' Cannot move South (edge)')
         end
      elseif move==0
            disp(' Waited')
      else
            disp(' Invalid command')
      end
      location(:) = [row; col];
      if notdone
         fuel = fuel - 1; % always costs 1
         if fuel <= 0
            notdone = 0;
         end
      end
      if location(1) == survivor(1) && location(2) == survivor(2)
         disp(' At survivor!!!')
         notdone = 0;
      end
      if fuel>=0
         plotit(field, survivor, location, fuel)
      end
   end

   % fuel = max(0, fuel);

   if fuel > 0
      disp([' Final fuel = ' num2str(fuel)])
   else
      disp(' Failure, ran out of fuel')
   end

   function plotit(field, survivor, location, fuel)
      % fixed values
      survival  = 30000; % for color only
      robotval  = 2000; % for color only, needs to be far from field if scaled

      view = 40 + field(:, :);
      view(survivor(1), survivor(2)) = survival;
      view(location(1), location(2)) = robotval;
      image(view)
      title([' fuel = ' num2str(fuel)])

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
