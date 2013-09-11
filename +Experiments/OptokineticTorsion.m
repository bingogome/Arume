classdef OptokineticTorsion < ArumeCore.Session
    %OPTOKINETICTORSION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        checkerBoardImg = [];
        checkerBoardTexture = [];
    end
    
    methods ( Access = protected )
        
        
        function parameters = getParameters( this, parameters  ) 
            
            parameters.trialDuration = 40; %seconds
            
            parameters.fixRad   = 10;
            parameters.fixColor = [255 0 0];
            
        end
        
        function [conditionVars, randomVars] = getVariables( this ) 
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars{i}.name   = 'Speed';
            conditionVars{i}.values = [2];
            
            i = i+1;
            conditionVars{i}.name   = 'Direction';
            conditionVars{i}.values = {'ClockWise' 'CounterClockWise' };
            
            randomVars = {};
        end
        
        
        function trialResult = runPreTrial(this, variables ) 
            Enum = ArumeCore.Session.getEnum();
            
            imgFile = fullfile( this.project.stimuliPath, 'radialCheckerBoardImage.mat');
            if ( exist( imgFile, 'file' ) )
                dat = load(imgFile);
                this.checkerBoardImg = dat.radialCheckerBoardImage;
            else
                width = 1080;  % Height of the screen
                fringe = 12;  % Width of the ramped fringe
                width = width - fringe;
                
                radialCheckerBoardImage = double(RadialCheckerBoard([width/2 0], [-180 180], [7 5]));
                save( imgFile, 'radialCheckerBoardImage');
                this.checkerBoardImg = radialCheckerBoardImage;
            end
            
            
            
            this.checkerBoardTexture = Screen('MakeTexture', this.Graph.window, this.checkerBoardImg, 1);
            
            
            trialResult =  Enum.trialResult.CORRECT;
        end
        
        function trialResult = runTrial( this, variables ) 
            
            Enum = ArumeCore.Session.getEnum();
            
            
            graph = this.Graph;
            parameters = this.ExperimentDesign.Parameters;
            
            trialResult = Enum.trialResult.CORRECT;
            
            
            %-- add here the trial code
            Screen('FillRect', graph.window, 128);
            lastFlipTime        = Screen('Flip', graph.window);
            secondsRemaining    = parameters.trialDuration;
            
            
            
            startLoopTime = lastFlipTime;
                        
            while secondsRemaining > 0
                
                secondsElapsed      = GetSecs - startLoopTime;
                secondsRemaining    = parameters.trialDuration - secondsElapsed;
                
                % -----------------------------------------------------------------
                % --- Drawing of stimulus -----------------------------------------
                % -----------------------------------------------------------------
                
                
                %-- Find the center of the screen
                [mx, my] = RectCenter(graph.wRect);
                
                %-- Draw image
                
                if ( secondsElapsed > 5 )
                    turnangle = (secondsElapsed-5)*30;
                else
                    turnangle = 0;
                end
                imageRect = CenterRectOnPointd( [0 0 1200 1200], mx, my );
                Screen('DrawTexture', graph.window, this.checkerBoardTexture, [], imageRect, turnangle);
                
                
                %-- Draw fixation spot
                fixRect = [0 0 5 5];
                fixRect = CenterRectOnPointd( fixRect, mx, my );
                Screen('FillOval', graph.window, parameters.fixColor, fixRect);
                
                % -----------------------------------------------------------------
                % --- END Drawing of stimulus -------------------------------------
                % -----------------------------------------------------------------
                
                
                
                % -----------------------------------------------------------------
                % -- Flip buffers to refresh screen -------------------------------
                % -----------------------------------------------------------------
                this.Graph.Flip();
                % -----------------------------------------------------------------
                
                
                % -----------------------------------------------------------------
                % --- Collecting responses  ---------------------------------------
                % -----------------------------------------------------------------
                
                % -----------------------------------------------------------------
                % --- END Collecting responses  -----------------------------------
                % -----------------------------------------------------------------
                
            end
            
                        

        end
        
        function trialOutput = runPostTrial(this)  
            trialOutput = [];
        end
        
        
        
    end
    
end

function img = RadialCheckerBoard(radius, sector, chsz, propel)
%img = RadialCheckerBoard(radius, sector, chsz, propel)
% Returns a bitmap image of a radial checkerboard pattern.
% The image is a square of 2*OuterRadius pixels.
%
% Parameters of wedge:
%   radius :    eccentricity of radii in pixels = [outer, inner] 
%   sector :    polar angles in degrees = [start, end] from -180 to 180
%   chsz :      size of checks in log factors & degrees respectively = [eccentricity, angle]
%   propel :    Optional, if defined there are two wedges, one in each hemifield
%

checkerboard = [0 255; 255 0];
img = ones(2*radius(1), 2*radius(1)) * 127;

for x = -radius : radius 
    for y = -radius : radius 
        [th r] = cart2pol(x,y);
        th = th * 180/pi;     
        if th >= sector(1) && th < sector(2) && r < radius(1) && r > radius(2)
            img(y+radius(1)+1,x+radius(1)+1) = checkerboard(mod(floor(log(r)*chsz(1)),2) + 1, mod(floor((th + sector(1))/chsz(2)),2) + 1); 
        end
    end
end

img = flipud(img);

if nargin > 3
    rotimg = flipud(fliplr(img));
    non_grey_pixels = find(rotimg ~= 127);
    img(non_grey_pixels) = rotimg(non_grey_pixels);
end

img = uint8(img);
end

