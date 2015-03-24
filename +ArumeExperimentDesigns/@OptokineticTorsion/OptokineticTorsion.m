classdef OptokineticTorsion < ArumeCore.ExperimentDesign
    %OPTOKINETICTORSION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        checkerBoardImg = [];
        checkerBoardTexture = [];
        
        eyeTracker = [];
        
        
        fixRad
        fixColor
    end
    
    % ---------------------------------------------------------------------
    % Options to set at runtime
    % ---------------------------------------------------------------------
    methods ( Static = true )
    end
    
    methods ( Access = public )
        
        function dlg = GetOptionsDialog( this )
            dlg.UseEyeTracker = { {'{0}' '1'} };
            dlg.TrialDuration = { 30 '* (seconds)' [1 100] };
        end
    end

    methods ( Access = protected )
        
        function initNewCreatedSession( this  )
            
            if ( ~isfield( this.ExperimentOptions, 'TrialDuration') )
                this.trialDuration = 20; %seconds
            else
                this.trialDuration = this.ExperimentOptions.TrialDuration; %seconds
            end
            
            % default parameters of any experiment
            this.trialSequence = 'Sequential';      % Sequential, Random, Random with repetition, ...
            this.trialAbortAction = 'Repeat';    % Repeat, Delay, Drop
            this.trialsPerSession = this.NumberOfConditions;
            
            %%-- Blocking
            this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.numberOfTimesRepeatBlockSequence = 1;
            this.blocksToRun              = 1;
            this.blocks(1).fromCondition  = 1;
            this.blocks(1).toCondition    = this.NumberOfConditions;
            this.blocks(1).trialsToRun    = this.NumberOfConditions;
                        
            this.fixRad   = 20;
            this.fixColor = [255 0 0];
            
            this.HitKeyBeforeTrial =1;
        end
        
        %% run initialization before the first trial is run
        function initBeforeRunning( this )
            
            if ( this.ExperimentOptions.UseEyeTracker )
                if ( exist('C:\secure\Code\EyeTracker\bin\Debug','file') )
                    asm = NET.addAssembly('C:\secure\Code\EyeTracker\bin\Debug\EyeTrackerRemoteClient.dll');
                    this.eyeTracker = ArumeHardware.VOG();
                    this.eyeTracker.Connect('127.0.0.1', 9000);
                else
                    asm = NET.addAssembly('D:\Code\Debug\EyeTrackerRemoteClient.dll');
                    this.eyeTracker = ArumeHardware.VOG();
                    this.eyeTracker.Connect('10.17.101.57', 9000);
                end
                
                this.eyeTracker.SetSessionName(this.Session.name);
            end
            
        end
        
        function [conditionVars] = getConditionVariables( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'Speed';
            conditionVars(i).values = [30 30 20 10 0];
            
            i = i+1;
            conditionVars(i).name   = 'Direction';
            conditionVars(i).values = {'ClockWise'  'CounterClockWise'};
        end
        
        function [ randomVars] = getRandomVariables( this )
            randomVars = {};
        end
        
        function trialResult = runPreTrial(this, variables )
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            forcenew = false;
            imgFile = fullfile( this.Project.stimuliPath, 'radialCheckerBoardImage.mat');
            if ( exist( imgFile, 'file' ) && ~forcenew)
                dat = load(imgFile);
                this.checkerBoardImg = dat.radialCheckerBoardImage;
            else
                width = 1080;  % Height of the screen
                fringe = 12;  % Width of the ramped fringe
                width = width - fringe;
                
                radialCheckerBoardImage = double(RadialCheckerBoard([width/2 0], [-180 180], [0 20]));
                save( imgFile, 'radialCheckerBoardImage');
                this.checkerBoardImg = radialCheckerBoardImage;
            end
            
            
            if ( ~isempty(this.eyeTracker) )
                if ( ~this.eyeTracker.IsRecording())
                    this.eyeTracker.StartRecording();
                    pause(1);
                end
                this.eyeTracker.RecordEvent(num2str(size(this.Session.CurrentRun.pastConditions,1)));
            end
            
            this.checkerBoardTexture = Screen('MakeTexture', this.Graph.window, this.checkerBoardImg, 1);
            
            trialResult =  Enum.trialResult.CORRECT;
        end
        
        function trialResult = runTrial( this, variables )
            
            try
                
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            
            graph = this.Graph;
            
            trialResult = Enum.trialResult.CORRECT;
            
            
            %-- add here the trial code
            Screen('FillRect', graph.window, 128);
            lastFlipTime        = Screen('Flip', graph.window);
            secondsRemaining    = this.trialDuration;
            
            
            
            startLoopTime = lastFlipTime;
            
            while secondsRemaining > 0
                
                secondsElapsed      = GetSecs - startLoopTime;
                secondsRemaining    = this.trialDuration - secondsElapsed;
                
                % -----------------------------------------------------------------
                % --- Drawing of stimulus -----------------------------------------
                % -----------------------------------------------------------------
                
                %-- Find the center of the screen
                [mx, my] = RectCenter(graph.wRect);
                
                %-- Draw image
                
                if ( secondsElapsed > 0 )
                    switch(variables.Direction)
                        case 'ClockWise'  
                            turnangle = (secondsElapsed-0)*variables.Speed;
                        case 'CounterClockWise'
                            turnangle = (-secondsElapsed-0)*variables.Speed;
                    end
                else
                    turnangle = 0;
                end
                imageRect = CenterRectOnPointd( [0 0 1200 1200], mx, my );
                Screen('DrawTexture', graph.window, this.checkerBoardTexture, [], imageRect, turnangle);
%                 Screen('DrawTexture', graph.window, this.checkerBoardTexture, [], imageRect2, turnangle);
                
                %-- Draw center black disk
%                 fixRect = [0 0 200 200];
%                 fixRect = CenterRectOnPointd( fixRect, mx-graph.wRect(3)/4, my );
%                 Screen('FillOval', graph.window, [0 0 0], fixRect);
                
                %-- Draw fixation spot
                fixRect = [0 0 5 5];
                fixRect = CenterRectOnPointd( fixRect, mx, my );
                Screen('FillOval', graph.window, this.fixColor, fixRect);
                
                
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
            catch ex
                if ( ~isempty( this.eyeTracker ) )
                    this.eyeTracker.StopRecording();
                end
                
                rethrow(ex)
            end
            
            if ( ~isempty( this.eyeTracker ) )
                this.eyeTracker.StopRecording();
            end
            
        end
        
        function trialOutput = runPostTrial(this)
            trialOutput = [];
        end
        
        function runAfterSessionCompleted(this)
        end
        
        function cleanAfterRunning(this)
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


function test()
%% plot torsion
pathfiles = 'C:\secure\Data\Raw\Torsion\DataTest';
oldpath = pwd;
cd(pathfiles);
files = uigetfile('*.txt', 'MultiSelect', 'on');

colors = ['b' 'r' 'g' 'k'];

figure
hold
for i=1:length(files)
    d=load(files{i});
    %d(d(:,2)<-15 | d(:,2) >15,2) = nan;
    plot((1:length(d))/33,d(:,2),colors(i));
end
xlabel('Time (s)')
ylabel('Torsion (deg)');
legend({'30 deg/s' '20 deg/s' '10 deg/s' '0 deg/s'})
cd(oldpath)

set(gca,'xlim',[0 10])
set(gca,'ylim',[-10 10])
end

