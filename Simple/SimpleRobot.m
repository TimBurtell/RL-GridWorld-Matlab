function move = robot(direction, sensors, crumbs, time, fuel, fuelstart)

   persistent agent;
   if isempty(agent)
      load agent; 
   end
   
   
    dirNorm = direction/norm(direction);
    Observation(:,:,1) = sensors / 20; 
    Observation(:,:,2) = crumbs ~= zeros(size(crumbs));
    Observation(:,:,3) = dirNorm(1) * eye(3);
    Observation(:,:,4) = dirNorm(2) * eye(3);
    Observation(:,:,5) = fuel / fuelstart * eye(3);
   move = agent.getAction(Observation);
end
