function fieldstart=randomgrid
% fieldstart=random creates a random grid for rubble function
% grid size is also random (min size is 10x10), percentage of
% boulders is randomized but has a maximum percentage

% determine size of grid
rows=ceil(rand*20);
while rows<10;
   rows=ceil(rand*20);
end
cols=ceil(rand*20);
while cols<10;
   cols=ceil(rand*20);
end
% create grid with random terrain values from 0-10 but no boulders
field = ceil(rand([rows cols])*11)-1;
% define minimum and maximum percentage of boulders allowed
minpercentbould=rand;
maxpercentbould=.75;
% make sure the minpercentbould<maxpercentbould, rand function gives
% you a random number between 0 and 1, could be greater than
% maxpercentbould
while minpercentbould>maxpercentbould
    minpercentbould=rand;
end
% determine grid locations to be made to have boulders
if minpercentbould==0
    boulders=ceil(rand([rows cols])*20);
    bouldloc=find(boulders==20);
elseif minpercentbould>0
    boulders=rand([rows cols]);
    x=.01;
    while (length(find(boulders<x))/(rows*cols))<minpercentbould
        x=x+.01;
    end
    bouldloc=find(boulders<x);
end
% get a random start position for robot and survivor
robrow=ceil(rand*rows);
robcol=ceil(rand*cols);
survrow=ceil(rand*rows);
survcol=ceil(rand*cols);
while (abs(robrow-survrow) + abs(robcol-survcol)) < (rows+cols)/2
   robrow=ceil(rand*rows);
   robcol=ceil(rand*cols);
   survrow=ceil(rand*rows);
   survcol=ceil(rand*cols);
end
% randomize whether I'll change the survivor row or survivor
% column if robot row and col match survivor row and col from above
check=ceil(rand*2);
% make sure robot and survivor aren't at same location
if check==1
    while survrow==robrow
        survrow=ceil(rand*rows);
    end
else
    while survcol==robcol
        survcol=ceil(rand*cols);
    end
end
% put in boulders as well as robot and survivor start positions into grid
field(bouldloc)=20;
field(robrow,robcol)=-1;
field(survrow,survcol)=-2;
fieldstart=field;
