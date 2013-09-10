classdef EyeTrackerEyeLink < EyeTrackers.EyeTrackerAbstract
    %EYETRACKEREYELINK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        el = [];
        v = '';
        vs = '';
        edfFileName = '';
        calibDriftBackgroundColor = []; %can be only black or white
        
    end
    
    methods
        %% EyeTrackerEyeLink
        %------------------------------------------------------------------
        %--------
        function this = EyeTrackerEyeLink( exper )
            %TODO: work with Screen graph
            
            % Initialization of the connection with the Eyelink Gazetracker.
            % exit program if this fails.
            
            experParameters = exper.ExperimentInfo.Parameters;
            
            if Eyelink('Initialize') ~= 0; %
                result = screenDlgSelect( exper.Graph.window, 'Eyelink initialization failed, choose an option:', {'c' 'd' 'q'}, ...
                    { 'Continue without eyelink' 'Dummy', 'Quit'}, [], [], [200 0 0] );
                switch( result )
                    case 'c'
                        this = [];
                        return
                    case 'd'
                        EyelinkInit(1);
                    case {'q' 0}
                        error( 'Eyelink initialization failed');
                end
            end;
            
            if ( ~isempty( exper.Graph) )
                % Provide Eyelink with details about the Graphics environment
                % and perform some initializations. The information is returned
                % in a structure that also contains useful defaults
                % and control codes (e.g. tracker state bit and Eyelink key values).
                this.el = EyelinkInitDefaults(exper.Graph.window);
                
                if isfield(experParameters, 'calibDriftBackgroundColor')
                    
                    switch  experParameters.calibDriftBackgroundColor
                        
                        case 'black'
                            this.el.backgroundcolour = BlackIndex(this.el.window);
                            this.el.foregroundcolour = WhiteIndex(this.el.window);
                        case 'white'
                            this.el.backgroundcolour = WhiteIndex(this.el.window);
                            this.el.foregroundcolour = BlackIndex(this.el.window);
                        case 'grey'
                            this.el.backgroundcolour = [128 128 128];
                            this.el.foregroundcolour = WhiteIndex(this.el.window);
                        otherwise
                            this.el.backgroundcolour = WhiteIndex(this.el.window);
                            this.el.foregroundcolour = BlackIndex(this.el.window);
                    end
                    
                else
                    this.el.backgroundcolour = WhiteIndex(this.el.window);
                    this.el.foregroundcolour = BlackIndex(this.el.window);
                end
            end
            
            % make sure that we get gaze data from the Eyelink
            Eyelink('Command', 'link_sample_data = LEFT, RIGHT, GAZE');
            Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,AREA,GAZERES,HREF,PUPIL,STATUS,INPUT,HMARKER');
            Eyelink('Command', 'file_sample_data = LEFT, RIGHT, GAZE, GAZERES, HREF, AREA, BUTTON, STATUS');
            %
            %              % set EDF file contents
            %     Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
            %     Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,AREA,GAZERES,HREF,PUPIL,STATUS,INPUT,HMARKER');
            %     % set link data (used for gaze cursor)
            Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
            %     Eyelink('command', 'link_event_filter = LEFT,RIGHT');
            
            
            Eyelink('Command', 'select_eye_after_validation = NO');
            Eyelink('Command', 'binocular_enabled = YES');
            Eyelink('Command', 'heuristic_filter = 1 0');
            
            [this.v this.vs] = Eyelink('GetTrackerVersion');
            
            fprintf('Running experiment on a ''%s'' tracker.\n', this.vs );
            
            % create filename % TODO: improve
            % if ( ~isfield(eyelink, 'edfFileName') )
            % % % % % % % % % % % % %               this.edfFileName = psyCortex_generateDosFilename( exper.SubjectCode, exper.SessionSuffix, 'EDF');
            this.edfFileName = psyCortex_generateDosFilename( exper.SubjectCode, exper.SessionSuffix, 'E');
            this.edfFileName = [this.edfFileName num2str(length(exper.EyeTrackerFiles)+1)];
            % open file to record data to
            Eyelink('Openfile', this.edfFileName );
            % else
            %     this.edfFileName{end+1} = psyCortex_generateDosFilename( this.Subject.subjectCode, this.Subject.sessionSuffix, 'EDF');
            %     % open file to record data to
            %     Eyelink('Openfile', this.edfFileName{end});
            % end
        end
        
        
        %% Calibration
        %--------------------------------------------------------------------------
        function [calibrationResult] = Calibration(this, graph)
            
            % psycortex_EyeLinkCalibration
            % performs calibration and validation using eyelink. It includes screen
            % messages and options to repeat or cancel.
            
            RESULT_SUCCESS = 1;
            RESULT_FAILURE = 0;
            
            CALIBRATION = 1;
            VALIDATION  = 2;
            SUCCESS     = 3;
            CANCEL      = 4;
            calibration_state = CALIBRATION;
            
            while(1)
                switch ( calibration_state )
                    
                    case CALIBRATION
                        dlgResult = graph.DlgYesNo( 'Continue to calibration?',[],[]);
                        if ( ~dlgResult )
                            calibration_state = CANCEL;
                        else
                            if (  EyelinkDoCalibrationValidation( this.el, 'c' ) )
                                dlgResult = graph.DlgYesNo( 'Repeat calibration?' ,[],[]);
                                if ( ~dlgResult )
                                    calibration_state = CANCEL;
                                end
                            else
                                calibration_state = VALIDATION;
                            end
                        end
                        
                    case VALIDATION
                        dlgResult = graph.DlgYesNo( 'Calibration was successful. Continue to validation?',[],[] );
                        if ( ~dlgResult )
                            calibration_state = CANCEL;
                        else
                            if ( EyelinkDoCalibrationValidation( this.el, 'v' ) )
                                dlgResult = graph.DlgYesNo( 'Validation failed. Repeat validation?',[],[] );
                                if ( ~dlgResult )
                                    calibration_state = CALIBRATION;
                                end
                            else
                                calibration_state = SUCCESS;
                            end
                        end
                        
                    case SUCCESS
                        dlgResult = graph.DlgYesNo( 'Validation was successful, continue with experiment?',[],[] );
                        if ( ~dlgResult )
                            calibration_state = CANCEL;
                        else
                            calibrationResult = RESULT_SUCCESS;
                            break;
                        end
                        
                    case CANCEL
                        calibrationResult = RESULT_FAILURE;
                        break;
                end
            end
        end
        
        %% DriftCorrection
        %--------------------------------------------------------------------------
        function [driftCorrectResult] = DriftCorrection(this, graph)
            % TODO: finish
            %%%%%%%%%%%%%%%%%%%%%%%%% START OLD
            % % % %                         % Drift Correction
            % % % %                         %             dlgResult = screenDlgYesNo( graph.window, 'Ready for drift correction (look at the dot)?' );
            % % % %                         %             if ( dlgResult )
            % % % %                         driftCorrectResult = EyelinkDoDriftCorrection( this.el );
            % % % %                         %% TODO handle bad drift correction
            % % % %                         %                 if ( ~driftCorrectResult )
            % % % %                         %                 end
            % % % %                         %             else
            % % % %                         %                 driftCorrectResult = 0;
            % % % %                         %                 return
            % % % %                         %             end
            % % % %                         driftCorrectResult = 1;
            %%%%%%%%%%%%%%%%%%%%%%%%% END OLD
            
            RESULT_SUCCESS = 1;
            RESULT_FAILURE = 0;
            
            DRIFTCORRECT = 1;
            SUCCESS     = 2;
            CANCEL      = 3;
            drift_correct_state = DRIFTCORRECT;
            
            numTrys = 0;
            while(1)
                
                
                switch ( drift_correct_state )
                    
                    case DRIFTCORRECT
                        %if its the first time, display this
                        if numTrys == 0;
                            dlgResult = graph.DlgYesNo( 'Continue with drift correction?',[],[]);
                        else
                            dlgResult = 1;
                        end
                        
                        if ( ~dlgResult )
                            drift_correct_state = CANCEL;
                        else
                            
                            current_result = EyelinkDriftCorrect( this.el, 'd' );
                            
                            numTrys = numTrys + 1;
                            if current_result
                                
                                dlgResult = graph.DlgYesNo( 'Repeat drift correction?' ,[],[]);
                                
                                if ( ~dlgResult )
                                    drift_correct_state = CANCEL;
                                else
                                    drift_correct_state = DRIFTCORRECT;
                                end
                                
                            else
                                drift_correct_state = SUCCESS;
                            end
                        end
                        
                    case SUCCESS
                        dlgResult = graph.DlgYesNo( 'Drift correction was successful, continue with experiment?',[],[] );
                        if ( ~dlgResult )
                            drift_correct_state = CANCEL;
                        else
                            driftCorrectResult = RESULT_SUCCESS;
                            break;
                        end
                        
                    case CANCEL
                        driftCorrectResult = RESULT_FAILURE;
                        break;
                end
                
            end
        end
        %% StartRecording
        %--------------------------------------------------------------------------
        function StartRecording( this )
            Eyelink('StartRecording', 1, 1, 1, 1);
        end
        
        %% StopRecording
        %--------------------------------------------------------------------------
        function StopRecording( this )
            if ( this.CheckRecording() ~= 0 )
                this.StopRecording();
                throw(MException('PSYCORTEX:EYELINKERROR', ''));
            end
            Eyelink('StopRecording');
        end
        
        %% SendMessage
        %--------------------------------------------------------------------------
        function SendMessage( this, string, varargin )
            str = ['Eyelink(''Message'', ''' string ''''];
            for i=1:length(varargin)
                str = [str ', varargin{' num2str(i) '}'];
            end
            str = [str ');'];
            eval(str);
        end

        %% ChangeStatusMessage
        %--------------------------------------------------------------------------
        function ChangeStatusMessage( this, string, varargin )
%                                     Eyelink('Command', 'record_status_message "HELLOOO hi %d"',34);

            str = ['Eyelink(''Command'', ''record_status_message "' string '"'''];
            for i=1:length(varargin)
                str = [str ', varargin{' num2str(i) '}'];
            end
            str = [str ');'];
            eval(str);
        end
            
        %% GetCurrentTimestamp
        %------------------------------------------------------------------
        function [tStamp, tReq, tRecv] = GetCurrentTimestamp( this )
            
            t0 = clock;
            t1 = tic;
            if Eyelink('RequestTime') ~= 0
                ts = -1;
                return; %Refine this when I understand errors better
            end
            tReq = toc(t1);
            
            t2=tic;
            tStamp = Eyelink('ReadTime');
            %Wait a maximum of 50 milliseconds for response
            while tStamp == 0 && etime(clock, t0) < 5e-2
                tStamp = Eyelink('ReadTime');
            end
            tRecv = toc(t2);
            
        end
        
        %% GetCurrentPosition
        function [x y] = GetCurrentPosition( this )
            if ~isempty(this.el)
                eye_used = Eyelink('EyeAvailable'); % get eye that's tracked
                if eye_used == this.el.BINOCULAR; % if both eyes are tracked
                    eye_used = this.el.LEFT_EYE; % use left eye
                end
            end
            
            if ~isempty(this.el)
                if ( Eyelink( 'NewFloatSampleAvailable') > 0 )
                    % get the sample in the form of an event structure
                    evt = Eyelink( 'NewestFloatSample');
                    
                    % if we do, get current gaze position from sample
                    x = evt.gx(eye_used+1); % +1 as we're accessing MATLAB array
                    y = evt.gy(eye_used+1);
                else
                    [x, y, buttons] = GetMouse; %(w);
                end
            else
                [x, y, buttons] = GetMouse; %(w);
            end
        end
        
        %% CheckRecording
        %--------------------------------------------------------------------------
        function error = CheckRecording( this, varargin )
            error = Eyelink('CheckRecording');
        end
        
        %% GetFile
        %--------------------------------------------------------------------------
        function filename = GetFile( this, path)
            Eyelink('CloseFile');
            try
                fprintf('Receiving data file ''%s'' ... \n', this.edfFileName );
                % % % % % % % % %                 c = strfind(lower(this.edfFileName),'.edf');
                % % % % % % % % %                 localfilename = [this.edfFileName(1:c-1) this.edfFileName(c+4:end) '.edf']
                c = strfind(lower(this.edfFileName),'.e');
                localfilename = [this.edfFileName(1:c-1) this.edfFileName(c+2:end) '.edf']
                
                filename = [path '\' localfilename];
                status = Eyelink('ReceiveFile', this.edfFileName, filename );
                if status > 0
                    % TODO: not sure what this status means
                    fprintf('EDF data file received, status %d\n', status);
                end
                
            catch
                receiving_error = psychlasterror;
                disp(['ERROR RECEIVING EYELINK DATA: ' receiving_error.message]);
                filename = '';
            end
        end
        
        %% Close
        %--------------------------------------------------------------------------
        function Close(this)
            Eyelink('CloseFile');
            Eyelink('ShutDown');
        end
    end
    
end

function result=EyelinkDoCalibrationValidation(el, sendkey)

% USAGE: result=EyelinkDoCalibrationValidation(el, sendkey)
%
%		el: Eyelink default values
%		sendkey: set to go directly into a particular mode
% 				'v', start validation
% 				'c', start calibration
% 				'd', start driftcorrection
% 				13, or el.ENTER_KEY, show 'eye' setup image

%
% 02-06-01	fwc removed use of global el, as suggest by John Palmer.
%				el is now passed as a variable, we also initialize Tracker state bit
%				and Eyelink key values in 'initeyelinkdefaults.m'
% 15-10-02	fwc	added sendkey variable that allows to go directly into a particular mode
%
%   22-06-06    fwc OSX-ed

result=-1;
if nargin < 2
    error( 'USAGE: result=EyelinkDoCalibrationValidation(el sendkey)' );
end

Eyelink( 'StartSetup' );		% start setup mode
Eyelink( 'WaitForModeReady', el.waitformodereadytime );  % time for mode change

EyelinkClearCalDisplay(el);	% setup_cal_display()
key=1;
while key~= 0
    key=EyelinkGetKey(el);		% dump old keys
end

% go directly into a particular mode
if el.allowlocalcontrol==1
    switch lower(sendkey)
        case{ 'c', 'v', 'd', el.ENTER_KEY}
            %forcedkey=BITAND(sendkey(1,1),255);
            forcedkey=double(sendkey(1,1));
            Eyelink('SendKeyButton', forcedkey, 0, el.KB_PRESS );
    end
end


%fprintf ('%s\n', 'dotrackersetup: in targetmodedisplay' );
result = EyelinkTargetModeDisplay(el);

return;

end

function result = EyelinkDriftCorrect(el, sendkey)

% USAGE: result=dodriftcorrect(el, x, y, draw, allowsetup)
%
%		el: eyelink default values
%		x,y: position of driftcorrection target
%		draw: set to 1 to draw driftcorrection target
%	allowsetup: set to 1 to allow to go in to go to trackersetup
%

% /********* PERFORM DRIFT CORRECTION ON TRACKER  *******/
%	/* Performs a drift correction, with target at (x,y). */
%	/* We are explicitly entering a tracker subfunction, */
%	/* so we have to handle link output explicitly. */
%	/* When we finish or abort the drift correction on the tracker, */
%	/* it won't go to another mode until we tell it to. */
%	/* For drift coorection, we can use the */
%	/* drift correction result message to tell when it's done, */
%	/* and what the result was. */

%	/*  Here we display the target ourselves (ignore target updates), */
%	/* wait for local spacebar or for operator trigger or */
%	/* ESC key abort. */
%	/* If operator aborts with ESC, we assume there's a setup */
%	/* problem and go to the setup menu. */

%	/* RETURNS: 0 if OK, 27 if Setup menu was called. */
%

% Eyelink Toolbox version
% 12-05-01	fwc created first version
% 12-05-01	fwc disabled unconditional erasing of screen
% 02-06-01	fwc removed use of global el, as suggested by John Palmer.
% 18-10-02	fwc	made sure missing variables were filled in with defaults

Eyelink( 'StartSetup' );		% start setup mode
Eyelink( 'WaitForModeReady', el.waitformodereadytime );  % time for mode change

EyelinkClearCalDisplay(el);	% setup_cal_display()
key=1;
while key~= 0
    key=EyelinkGetKey(el);		% dump old keys
end

% go directly into a particular mode
if el.allowlocalcontrol==1
    switch lower(sendkey)
        case{  'd', el.ENTER_KEY}
            %forcedkey=BITAND(sendkey(1,1),255);
            forcedkey=double(sendkey(1,1));
            Eyelink('SendKeyButton', forcedkey, 0, el.KB_PRESS );
    end
end

%fprintf ('%s\n', 'dotrackersetup: in targetmodedisplay' );
result = EyelinkTargetModeDisplay(el);

end
%% function psyCortex_generateFilename
%--------------------------------------------------------------------------
function filename = psyCortex_generateDosFilename( subjectCode, sessionSuffix, extension )

% filename format
% 3 characters for subject code
% 1 characters for year
% 1 letter for month (A is january, L is december)
% 2 characters for day number
% 1 letter for session
date = datevec(now);
filename = sprintf( ['%s%c%c%0.2d%c.' extension], subjectCode,  char('A' + date(1)-2000 - 1), char('A' + date(2) - 1), date(3), sessionSuffix );
end