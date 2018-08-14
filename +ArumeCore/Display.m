classdef Display < handle
    %DISPLAY Summary of this class goes here
    %   Detailed explanation goes here
    properties
        screens = [];
        selectedScreen = 1;
        
        window = [];
        wRect = [];
        
        black = [];
        white = [];
        
        dlgTextColor = [];
        dlgBackgroundScreenColor = [];
        
        frameRate = [];
        nominalFrameRate = [];
        
        
        reportedmmWidth = [];
        reportedmmHeight = [];
        
        pxWidth = [];
        pxHeight = [];
        
        windiwInfo = [];
        
        mmWidth = [];
        mmHeight = [];
        
        distanceToMonitor = [];
        
        fliptimes = {};
        NumFlips = 0;
    end
    
    properties(Access=private)
        lastfliptime = 0;
    end
    
    methods
        
        %% Display
        function graph = Display( )
        end
        
        function Init( graph, exper)
            
            Screen('Preference', 'SkipSyncTests', 1);
            Screen('Preference', 'VisualDebugLevel', 0);
            
            %-- screens
            
            graph.screens = Screen('Screens');
            screens=Screen('Screens');
         	graph.selectedScreen=max(screens);
%           	graph.selectedScreen=1;
    
            %-- window
            Screen('Preference', 'ConserveVRAM', 64);
            [graph.window, graph.wRect] = Screen('OpenWindow', graph.selectedScreen, 0, [], [], [], 0, 10);
%             [graph.window, graph.wRect] = Screen('OpenWindow', graph.selectedScreen, 0, [], [], [], 0);
         
            %-- color
            
            graph.black = BlackIndex( graph.window );
            graph.white = WhiteIndex( graph.window );
            
            graph.dlgTextColor = exper.ForegroundColor;
            graph.dlgBackgroundScreenColor = exper.BackgroundColor;
            
            
            
            
            %-- font
            Screen('TextSize', graph.window, 18);
            
            
            %-- frame rate
            graph.frameRate         = Screen('FrameRate', graph.selectedScreen);
            graph.nominalFrameRate  = Screen('NominalFrameRate', graph.selectedScreen);
            
            %-- size
            [graph.reportedmmWidth, graph.reportedmmHeight] = Screen('DisplaySize', graph.selectedScreen);
            [graph.pxWidth, graph.pxHeight]                 = Screen('WindowSize', graph.window);
            graph.windiwInfo                                = Screen('GetWindowInfo',graph.window);
            %TODO: force resolution and refresh rate
            
            
            if ( ~isempty( exper ) )
                
                %-- physical dimensions
                graph.mmWidth           = exper.Config.Graphical.mmMonitorWidth;
                graph.mmHeight          = exper.Config.Graphical.mmMonitorHeight;
                graph.distanceToMonitor = exper.Config.Graphical.mmDistanceToMonitor; % mm
                
                
                %-- scale
                horPixPerDva = graph.pxWidth/2 / (atan(graph.mmWidth/2/graph.distanceToMonitor)*180/pi);
                verPixPerDva = graph.pxHeight/2 / (atan(graph.mmHeight/2/graph.distanceToMonitor)*180/pi);
                
                
                
                %-- if we are resuming an experiment, test if graph set up is the same
                
                if ( ~isempty( exper.Graph ) )
                    
                    % TODO improve
                    if ( graph.wRect(3) ~= exper.Graph.wRect(3) || graph.wRect(4) ~= exper.Graph.wRect(4) )
                        error( 'monitor resoluting is different from the first run, recommended to change settings or to restart the experiment');
                    end
                end
            end
            
            
            % draw a fixation spot in the center;
            [mx, my] = RectCenter(graph.wRect);
            fixRect = [0 0 10 10];
            fixRect = CenterRectOnPointd( fixRect, mx, my );
            Screen('FillOval', graph.window,  255, fixRect);
            fliptime = Screen('Flip', graph.window);
        end
        
        function ResetBackground( this )
            Screen('FillRect', this.window, this.dlgBackgroundScreenColor);
        end
        
        %% Flip
        %--------------------------------------------------------------------------
        function fliptime = Flip( this, exper, trial )
            
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            fliptime = Screen('Flip', this.window);
            
            %-- Check for keyboard press
            [keyIsDown,secs,keyCode] = KbCheck;
            if keyCode(Enum.keys.ESCAPE)
                if nargin == 2
                    exper.abortExperiment();
                elseif nargin == 3
                    exper.abortExperiment(trial);
                else
                    throw(MException('PSYCORTEX:USERQUIT', ''));
                end
            end
            
            this.NumFlips = this.NumFlips + 1;
           % this.fliptimes{end}(this.NumFlips) = fliptime;
            %             this.fliptimes{end} = this.fliptimes{end} + histc(fliptime-this.lastfliptime,0:.005:.100);
            %             fliptime-this.lastfliptime
            %             this.lastfliptime = fliptime;
            
        end
        
        %% Make hist of flips
        function hist_of_flips = flips_hist(this)
            
            hist_of_flips =  histc(diff(this.fliptimes{end}(1:this.NumFlips)),0:.005:.100);
            %             this.fliptime_hist = hist_of_flips;
            
            
        end
        
        %% dva2pix
        %--------------------------------------------------------------------------
        function pix = dva2pix( this, dva )
            
            horPixPerDva = this.pxWidth/2 / (atan(this.mmWidth/2/this.distanceToMonitor)*180/pi);
            %             verPixPerDva = this.pxHeight/2 / (atan(this.mmHeight/2/this.distanceToMonitor)*180/pi);
            
            pix = round( horPixPerDva * dva );
            
            % TODO: improve
            
            % function pix = psyCortex_dva2pixExact( graph, poit1, point2 )
            %
            % distanceToCenter = min
            %
            % horPixPerDva = graph.pxWidth / atan(graph.mmWidth/2/graph.distanceToMonitor)*180/pi;
            % verPixPerDva = graph.pxHeight / atan(graph.mmHeight/2/graph.distanceToMonitor)*180/pi;
        end
        
        %% pix2dva
        function dva = pix2dva( this, pix )
            
            horPixPerDva = this.pxWidth/2 / (atan(this.mmWidth/2/this.distanceToMonitor)*180/pi);
            %             verPixPerDva = this.pxHeight/2 / (atan(this.mmHeight/2/this.distanceToMonitor)*180/pi);
            
            %dont need to round dva
            dva =    pix/ horPixPerDva ;
            
            % TODO: improve
            
            % function pix = psyCortex_dva2pixExact( graph, poit1, point2 )
            %
            % distanceToCenter = min
            %
            % horPixPerDva = graph.pxWidth / atan(graph.mmWidth/2/graph.distanceToMonitor)*180/pi;
            % verPixPerDva = graph.pxHeight / atan(graph.mmHeight/2/graph.distanceToMonitor)*180/pi;
        end
        
        %% rotatePointCenter
        %--------------------------------------------------------------------------
        function [x y] = rotatePointCenter( graph, point, angle )
            
            [mx, my] = RectCenter(graph.wRect);
            
            
            p = rotatePoint( point, angle/180*pi, [mx my]);
            
            x = p(1);
            y = p(2);
        end
        
        %------------------------------------------------------------------
        %% Dialog Functions  ----------------------------------------------
        %------------------------------------------------------------------
        
        %% DlgHitKey
        function result = DlgHitKey( this, message, varargin )
            % DlgHitKey(window, message, [, sx][, sy][, color][, wrapat][, flipHorizontal][, flipVertical])
            
            
            if nargin < 1
                error('DlgHitKey: Must provide at least the first argument.');
            end
            
            if ( nargin < 2 || isempty(message) )
                message = 'Hit a key to continue';
            end
            
            if ( nargin < 3 || isempty(varargin{1}) )
                varargin{1} = 'center';
            end
            if ( nargin < 4 || isempty(varargin{2}) )
                varargin{2} = 'center';
            end
            
            oldDefaultColor = Screen( 'TextColor', this.window); % recover previous default color
            Screen( 'TextColor', this.window, this.dlgTextColor);
            % relevant keycodes
            ESCAPE = 27;
            
            % remove previous key presses
            FlushEvents('keyDown');
            
            DrawFormattedText( this.window, message, varargin{:} );
            Screen('Flip', this.window);
            disp( sprintf(['\n' message]));
            
            while(1)
                
                try
                    g = ArumeHardware.GamePad();
                    [ direction, left, right, a, b, x, y] = g.Query;

                    if ( a | b | x | y)
                        result = char('a');
                        break;
                    end
                    
                    [x,y,buttons] = GetMouse();
                    
                    if buttons(2) % wait for release
                        
                        result = char('a');
                        break
                    end
                    
                catch
                end
                
                [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
                if ( keyIsDown )
                    keys = find(keyCode);
                    result = keyCode(keys(1));
                    break;
                end
                
                
            end
            
%             char = GetChar;
%             switch(char)
%                 
%                 case ESCAPE
%                     result = 0;
%                     
%                 otherwise
%                     result = char;
%             end
%             
            
            Screen( 'TextColor', this.window, oldDefaultColor); % recover previous default color
        end
        
        
        %% DlgHitMouse
        function result = DlgHitMouse( this, message, varargin )
            % DlgHitMouse(window, message, [, sx][, sy][, color][, wrapat][, flipHorizontal][, flipVertical])
            
            
            if nargin < 1
                error('DlgHitMouse: Must provide at least the first argument.');
            end
            
            if ( nargin < 2 || isempty(message) )
                message = 'Click to continue';
            end
            
            if ( nargin < 3 || isempty(varargin{1}) )
                varargin{1} = 'center';
            end
            if ( nargin < 4 || isempty(varargin{2}) )
                varargin{2} = 'center';
            end
            
            oldDefaultColor = Screen( 'TextColor', this.window); % recover previous default color
            Screen( 'TextColor', this.window, this.dlgTextColor);
            % relevant keycodes
            ESCAPE = 27;
            
            % remove previous key presses
            FlushEvents('keyDown');
            
            DrawFormattedText( this.window, message, varargin{:} );
            Screen('Flip', this.window);
            buttons(1) = 0;
            
            while(~buttons(1))
                [x,y,buttons] = GetMouse;
                result = buttons(1);
            end
            
            Screen( 'TextColor', this.window, oldDefaultColor); % recover previous default color
        end
        
        %% DlgYesNo
        function result = DlgYesNo( this, message, yesText, noText, varargin )
            % DlgYesNo(window, message, yesText, noText, [, sx][, sy][, color][, wrapat][, flipHorizontal][, flipVertical])
            
            
            if nargin < 2
                error('DlgYesNo: Must provide at least the first two arguments.');
            end
            
            if ( nargin < 3 || isempty(yesText) )
                yesText = 'Yes';
            end
            
            if ( nargin < 4 || isempty(noText) )
                noText = 'No';
            end
            
            oldDefaultColor = Screen( 'TextColor', this.window); % recover previous default color
            Screen( 'TextColor', this.window, this.dlgTextColor);
            % possible results
            YES = 1;
            NO  = 0;
            
            % relevant keycodes
            ESCAPE  = 27;
            ENTER   = {13,3,10};
            
            % remove previous key presses
            FlushEvents('keyDown');
            
            DrawFormattedText(this.window, [message ' ' yesText ' (enter), ' noText ' (escape)'], varargin{:});
            Screen('Flip', this.window);
            disp( sprintf( ['\n' message ' ' yesText ' (enter), ' noText ' (escape)']));
            
            while(1)
                char = GetChar;
                switch(char)
                    
                    case ENTER
                        result = YES;
                        break;
                        
                    case ESCAPE
                        result = NO;
                        break;
                end
            end
            
            Screen( 'TextColor', this.window, oldDefaultColor); % recover previous default color
        end
        
        
        %% DlgTimer
        function result = DlgTimer( this, message, maxTime, varargin )
            % DlgTimer(window, message [, maxTime][, sx][, sy][, color][, wrapat][, flipHorizontal][, flipVertical])
            
            
            if nargin < 1
                error('DlgHitKey: Must provide at least the first argument.');
            end
            
            if ( nargin < 2 || isempty(message) )
                message = 'Hit a key to continue';
            end
            
            if ( nargin < 3 || isempty(maxTime) )
                maxTime = 90;
            end
            
            oldDefaultColor = Screen( 'TextColor', this.window); % recover previous default color
            Screen( 'TextColor', this.window, this.dlgTextColor);
            
            % relevant keycodes
            ESCAPE = 27;
            
            % remove previous key presses
            FlushEvents('keyDown');
            
            tini = getSecs;
            while(1)
                t = getSecs-tini;
                DrawFormattedText( this.window, sprintf('%s - %d'' %4.1f seconds',message,floor(t/60),mod(t,60)), varargin{:} );
                Screen('Flip', this.window);
                
                if ( CharAvail )
                    char = GetChar;
                    switch(char)
                        
                        case ESCAPE
                            result = 0;
                            break;
                    end
                end
                if ( maxTime > 0 && (getSecs-tini> maxTime ) )
                    break
                end
            end
            
            Screen( 'TextColor', this.window, oldDefaultColor); % recover previous default color
        end
        
        %% DlgSelect
        function result = DlgSelect( this, message, optionLetters, optionDescriptions, varargin )
            
            %DlgInput(window, message, optionLetters, optionDescriptions, tstring [, sx][, sy][, color][, wrapat][, flipHorizontal][, flipVertical])
            if nargin < 3
                error('DlgSelect: Must provide at least the first three arguments.');
            end
            
            if ( nargin < 4 || isempty(optionDescriptions) )
                optionDescriptions = optionLetters;
            end
            
            if ( length(optionLetters) ~= length(optionDescriptions) )
                error('DlgSelect: the number of options does not match the number of letters.');
            end
            
            oldDefaultColor = Screen( 'TextColor', this.window); % recover previous default color
            Screen( 'TextColor', this.window, this.dlgTextColor);
            
            ESCAPE = 27;
            ENTER   = {13,3,10};
            DOWN = 40;
            UP = 38;
            
            % remove previous key presses
            FlushEvents('keyDown');
            
            % draw options
            text = message;
            for i=1:length(optionLetters)
                text = [text '\n\n( ' optionLetters{i} ' ) ' optionDescriptions{i}];
            end
            
            selection = 0;
            DrawFormattedText( this.window, text, varargin{:} );
            Screen('Flip', this.window);
            disp( sprintf(['\n'  text]));
            
            while(1) % while no valid key is pressed
                
                c = GetChar;
                
                switch(c)
                    
                    case ESCAPE
                        result = 0;
                        break;
                        
                    case ENTER
                        if ( selection > 0 )
                            result = optionLetters{1};
                            break;
                        else
                            continue;
                        end
                    case {'a' 'z'}
                        if ( c=='a' )
                            selection = mod(selection-1-1,length(optionLetters))+1;
                        else
                            selection = mod(selection+1-1,length(optionLetters))+1;
                        end
                        text = message;
                        for i=1:length(optionLetters)
                            if ( i==selection )
                                text = [text '\n\n ->( ' optionLetters{i} ' ) ' optionDescriptions{i}];
                            else
                                text = [text '\n\n ( ' optionLetters{i} ' ) ' optionDescriptions{i}];
                            end
                        end
                        
                        DrawFormattedText( this.window, text, varargin{:} );
                        Screen('Flip', this.window);
                        
                    otherwise
                        if ( ~isempty( intersect( upper(optionLetters), upper( char(c) ) ) ) )
                            
                            result = optionLetters( streq( upper(optionLetters), upper( char(c) ) ) );
                            if ( iscell(result) )
                                result = result{1};
                            end
                            break;
                        end
                end
            end
            Screen( 'TextColor', this.window, oldDefaultColor); % recover previous default color
        end
        
        
        %% DlgInput
        function answer = DlgInput( this, message, varargin )
            
            %DlgInput(win, tstring [, sx][, sy][, color][, wrapat][, flipHorizontal][, flipVertical])
            
            if nargin < 1
                error('DlgHitKey: Must provide at least the first argument.');
            end
            
            if ( nargin < 2 || isempty(message) )
                message = '';
            end
            
            oldDefaultColor = Screen( 'TextColor', this.window); % recover previous default color
            Screen( 'TextColor', this.window, this.dlgTextColor);
            
            ESCAPE = 27;
            ENTER = {13,3,10};
            DELETE = 8;
            
            answer = '';
            
            FlushEvents('keyDown');
            
            while(1)
                text = [message ' ' answer ];
                
                DrawFormattedText( this.window, text, varargin{:} );
                Screen('Flip', this.window);
                
                
                char=GetChar;
                switch(abs(char))
                    
                    case ENTER,	% <return> or <enter>
                        break;
                        
                    case ESCAPE, % <scape>
                        answer  = '';
                        break;
                        
                    case DELETE,			% <delete>
                        if ~isempty(answer)
                            answer(end) = [];
                        end
                        
                    otherwise,
                        answer = [answer char];
                end
            end
            
            Screen( 'TextColor', this.window, oldDefaultColor); % recover previous default color
            
        end
        
    end
end


