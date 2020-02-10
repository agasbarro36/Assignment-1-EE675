%% Computation for Transmission Line Geometry #3 %%
%% Anthony Gasbarro                              %%
%% EE 675                                        %%    

clearvars;
close all;
clc;
%% Given Data Parameters %%

%Dimensions of TL
    height = 2; %overall height given as 2.02, rounded down to 2
    width= 7;  %overall width

%Conductor Parameters
    widthConductor = 1.00; 
    thicknessConductor = 0; %Assume thickness to be zero
    heightDielectric = 1.00; %dielectric height per given data
    er = 1.0;



%% Adjustable parameters %%

%potential of the conductor 
    phiConductor = 10.00; 

%size of mesh
    h = 0.1;
    
%Contour Distance from Center Conductor
    contourdh = 5;
    contourdv = 7;
    
%designate potential for edges
    leftPotential = 0;
    rightPotential = 0;
    topPotential = 0;
    bottomPotential = 0;

%% Generation of Matrices A and B %%

%dimensions of points for phi matrix
    colMax = (width/h)-1;
    rowMax = (height/h)-1; 

%determine 'n' for A matrix    
    nodesTotal = rowMax*colMax;
    
%determine given parameter dimensions as nodes in the phi matrix
    
    %height of dielectric nodes along y axis, and section above
        yDielectric = (heightDielectric/h);
        yAboveDielectric = rowMax - yDielectric;
        
    %width of conductor nodes along x axis, and sections to side
        xConductorWidth = (widthConductor/h) + 1;
        xNextToConductor = (colMax - xConductorWidth)/2;
    
% generate 'A' Matrix with diagonal -4's, along with empty 'B' matrix
Amatrix = eye(nodesTotal, nodesTotal)*-4;
Bmatrix = zeros(nodesTotal, 1);


% iterate through each row to fill in 'A' and 'B' matrices
% 'i' is used as the iterator throughout the 'A' and 'B' matrices
% x,y are used to determine position within the phi matrix
for i = 1:nodesTotal
    
    %create an x,y point for reference in the phi matrix
    %y is determined as the modulus of x since, y-axis for tables are inversed from typical i,j notation
    x = mod(i,colMax);
    y = fix(i/colMax)+1; 
   
    %account for rows that are divisible by rmax
    if(x == 0)
        x = colMax;
        y = y-1;
    end
    
    %Conditional flags for special conditions
    %above, below, left, right of, and at conductor
    %left, right, top, bottom edges of mesh
    %conditional flags are set by if statements below 
    %all flags are initialized to zero at each loop iteration
    
        aboveConductor = 0; %current x-position is just above conductor
        belowConductor = 0; %current x-position is just below conductor
        onConductor = 0; %current x,y position is on top of the conductor
        leftOfConductor = 0;
        rightOfConductor = 0;
        leftEdge = 0;
        rightEdge = 0;
        topEdge = 0;
        bottomEdge = 0;
    
    % The following computations are broken into two major sections
    % when at the dielectric interface and when not at the interface
    % Base case is when not at dielectric interface
    if(y ~= yAboveDielectric+1)
        
        %Determine if at nodes above/below conductor
        %first check if x-position is within conductor bounds
        %then check if at a node directly above or below and mark flag
        %then finally calculate value stored in Bmatrix by subtracting
        if((x > xNextToConductor) && (x <= xNextToConductor + xConductorWidth))
            if(y == yAboveDielectric)
                aboveConductor = 1;
                Bmatrix(i) = Bmatrix(i) - phiConductor;
            elseif(y == yAboveDielectric + 2)
                belowConductor = 1;
                Bmatrix(i) = Bmatrix(i) - phiConductor;
            end
        end 
        
        % This section determines if at an Edge in the phi matrix
        % and subtracts potential from 'B' matrix element 
        % first a flag is set to determine if at a boundary,
        % then potential is updated based on input values above  
        if(x == 1)
            leftEdge = 1;
            Bmatrix(i) = Bmatrix(i) - leftPotential;
        end
        
        if(x == colMax)
            rightEdge=1;
            Bmatrix(i) = Bmatrix(i) - rightPotential;
        end
        
        if(y == 1)
            topEdge=1;
            Bmatrix(i) = Bmatrix(i) - topPotential;
        end
        
        if(y == rowMax)
            bottomEdge=1;
            Bmatrix(i) = Bmatrix(i) - bottomPotential;
        end
        
        %The set the 1's if no edge or conductor nearby
        if(leftEdge == 0)
            Amatrix(i,i-1) = 1;
        end
        if(rightEdge == 0)
            Amatrix(i,i+1) = 1;
        end
        if(topEdge == 0 && belowConductor == 0)
            Amatrix(i, i-colMax) = 1;
        end
        if(bottomEdge == 0 && aboveConductor == 0)
            Amatrix(i, i+colMax) = 1;
        end
    
        
    % The 'else' case below handles second major section where 
    % 'y' is AT THE DIELECTRIC INTERFACE
    % this section is broken into the following cases: 
    %   -between conductor and edge 
    %   -on the conductor 
    %   -directly to the left/right of conductor,
    %   -and at an matrix edge 
    %   -if at interface with no edge or conductor
    else
        
        % Determine NOT if on the conductor and compute potential
        if(x <= xNextToConductor || x>xConductorWidth+xNextToConductor)
            Amatrix(i,i) = -4*(er + 1);
            
        % if ON conductor set flag and set 'A' and 'B' matrix values  
        else
            onConductor = 1;
            Amatrix(i,i) = 1;
            Bmatrix(i) = phiConductor;

        end
        
        % The following section accounts for if directly to the left then if
        % directly to the right of the conductor 
        if(onConductor == 0)
            if(x == xNextToConductor) 
                leftOfConductor = 1;
                Bmatrix(i) = Bmatrix(i) - (er + 1)*phiConductor;
                
            elseif(x == (xConductorWidth + xNextToConductor + 1))
                rightOfConductor = 1;
                Bmatrix(i) = Bmatrix(i) - (er + 1)*phiConductor;  
            end
            
            % The next section is for determining edge calculations 
            % while at the dielectric interface
            if(x == 1)
                leftEdge = 1;
                Bmatrix(i) = Bmatrix(i) - (er + 1)*leftPotential;
            end
            
            if(x == colMax)
                rightEdge = 1;
                Bmatrix(i) = Bmatrix(i) - (er + 1)*rightPotential;
            end
            
            if(y == 1)
                topEdge = 1;
                Bmatrix(i) = Bmatrix(i) - topPotential*2;
            end 
            
            if(y == rowMax)
                bottomEdge = 1;
                Bmatrix(i) = (i) - er*bottomPotential*2;
            end
           
            %The next section handles cases where there is no conductor and
            %no edge adjacent to the node
            if(leftEdge == 0 && rightOfConductor == 0) 
                Amatrix(i, i-1) = er+1; 
            end
            if(rightEdge == 0 && leftOfConductor == 0)
                Amatrix(i, i+1) = er+1;
            end
            if(topEdge == 0)
                Amatrix(i, i-colMax) = 2;
            end
            if(bottomEdge == 0)
                Amatrix(i, i+colMax) = er*2;
            end
        end
    end
end

%% Generate phi Matrix and 

