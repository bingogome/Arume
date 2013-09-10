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
        function graph = Display( exper )
            
            
            Screen('Preference', 'SkipSyncTests', 0);
            
            experParameters = exper.ExperimentInfo.Parameters;
            %-- screens
            
            graph.screens = Screen('Screens');
            
            if ( max(graph.screens)== 0)
                graph.selectedScreen = 0;%; %% IMPROVE
            else
                graph.selectedScreen = 1;%; %% IMPROVE
            end
            %             graph.selectedScreen = 2;
            %             Screen('Preference', 'SkipSyncTests', 1);
            
            %-- window
            [graph.window, graph.wRect] = Screen('OpenWindow', graph.selectedScreen);
            
            %-- color
            
            graph.black = BlackIndex( graph.window );
            graph.white = WhiteIndex( graph.window );
            
            
            if isfield(experParameters, 'dlgTextColor')
                graph.dlgTextColor = experParameters.dlgTextColor;
            else
                graph.dlgTextColor =  graph.black;
            end
            if isfield(experParameters, 'dlgBackgroundScreenColor')
                graph.dlgBackgroundScreenColor = experParameters.dlgBackgroundScreenColor;
            else
                graph.dlgBackgroundScreenColor =  graph.white;
            end
            
            
            %-- font
            Screen('TextSize', graph.window, 18);
            
            
            %-- frame rate
            graph.frameRate         = Screen('FrameRate', graph.selectedScreen);
            graph.nominalFrameRate  = Screen('NominalFrameRate', graph.selectedScreen);
            
            %-- size
            [graph.reportedmmWidth, graph.reportedmmHeight] = Screen('DisplaySize', graph.selectedScreen);
            [graph.pxWidth, graph.pxHeight]                 = Screen('WindowSize', graph.window)
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
        end
        
        %% Flip
        %--------------------------------------------------------------------------
        function fliptime = Flip( this, exper, trial )
            
            global Enum;
            
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
            this.fliptimes{end}(this.NumFlips) = fliptime;
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
            
            char = GetChar;
            switch(char)
                
                case ESCAPE
                    result = 0;
                    
                otherwise
                    result = char;
            end
            
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
        
        %% DlgSelectMouse
        
        function result = DlgSelectMouse( this, message, optionLetters, optionDescriptions, next, varargin )
            
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
            N = imread( char(next) , 'BMP' );
           
            trial.nextTexture = Screen('MakeTexture', this.window, N, 1);
            % draw options
            text = message;%
            result = 0;
            [mx, my] = RectCenter(this.wRect);
                 
            cornerEx = mx + 300;
            cornerEy = my + 300;
            DrawFormattedText( this.window,  text, mx-500, my-180);
            
            %            DrawFormattedText( this.window, text, varargin{:} );
            
            Screen('FrameOval', this.window, [0 0 255] ,[mx-400; my-100; mx-380; my-80], 30);
            DrawFormattedText( this.window,  ['(' optionLetters{1} ')' optionDescriptions{1}], mx-360, my-104);
            Screen('FrameOval', this.window, [0 0 255] ,[mx-400; my-70; mx-380; my-50], 30);
            DrawFormattedText( this.window,  ['(' optionLetters{2} ')' optionDescriptions{2}], mx-360, my-74);
            Screen('FrameOval', this.window, [0 0 255] ,[mx-400; my-40; mx-380; my-20], 30);
            DrawFormattedText( this.window,  ['(' optionLetters{3} ')' optionDescriptions{3}], mx-360, my-44);
            Screen('FrameOval', this.window, [0 0 255] ,[mx-400; my-10; mx-380; my+10], 30);
            DrawFormattedText( this.window,  ['(' optionLetters{4} ')' optionDescriptions{4}], mx-360, my-14);
            ShowCursor('Hand');
            Screen('DrawTexture', this.window, trial.nextTexture, [], [cornerEx+20; cornerEy+50; cornerEx+170;cornerEy+100], 0);
            Screen('Flip', this.window);
          
            while(1) % while no valid key is pressed
                
                [x,y,buttons] = GetMouse;
                if buttons(1)
                     Screen('DrawTexture', this.window, trial.nextTexture, [], [cornerEx+20; cornerEy+50; cornerEx+170;cornerEy+100], 0);
                    DrawFormattedText( this.window,  text, mx-500, my-180);
                    Screen('FrameOval', this.window, [0 0 255] ,[mx-400; my-100; mx-380; my-80], 30);
                    DrawFormattedText( this.window,  ['(' optionLetters{1} ')' optionDescriptions{1}], mx-360, my-104);
                    Screen('FrameOval', this.window, [0 0 255] ,[mx-400; my-70; mx-380; my-50], 30);
                    DrawFormattedText( this.window,  ['(' optionLetters{2} ')' optionDescriptions{2}], mx-360, my-74);
                    Screen('FrameOval', this.window, [0 0 255] ,[mx-400; my-40; mx-380; my-20], 30);
                    DrawFormattedText( this.window,  ['(' optionLetters{3} ')' optionDescriptions{3}], mx-360, my-44);
                    Screen('FrameOval', this.window, [0 0 255] ,[mx-400; my-10; mx-380; my+10], 30);
                    DrawFormattedText( this.window,  ['(' optionLetters{4} ')' optionDescriptions{4}], mx-360, my-14);
                  
                    if y > my-100 && y <my-80
                        result = '1';
                        Screen('FrameOval', this.window, [255 0 0] ,[mx-400; my-100; mx-380; my-80], 30);
                        %                         DrawFormattedText( this.window,  sprintf('You chose # %c. If that is right, press ENTER.\n Otherwise press any other key to select again.', result), mx/2-120, my/2+600);
                        %                         Screen('Flip', this.window);
                         Screen('Flip', this.window);
                    else if y > my-70 && y <my-50
                            result = '2';
                            Screen('FrameOval', this.window, [255 0 0] ,[mx-400; my-70; mx-380; my-50], 30);
                            %                         DrawFormattedText( this.window,  sprintf('You chose # %c. If that is right, press ENTER.\n Otherwise press any other key to select again.', result), mx/2-120, my/2+600);
                            %                         Screen('Flip', this.window);
                             Screen('Flip', this.window);
                        else if y > my-40 && y <my-20
                                result = '3';
                                Screen('FrameOval', this.window, [255 0 0] ,[mx-400; my-40; mx-380; my-20], 30);
                                %                                 DrawFormattedText( this.window,  sprintf('You chose # %c. If that is right, press ENTER.\n Otherwise press any other key to select again.', result), mx/2-120, my/2+600);
                                %                                 Screen('Flip', this.window);
                                 Screen('Flip', this.window);
                            else if y > my-10 && y <my+10
                                    result = '4';
                                    Screen('FrameOval', this.window, [255 0 0] ,[mx-400; my-10; mx-380; my+10], 30);
                                    %                                     DrawFormattedText( this.window,  sprintf('You chose # %c. If that is right, press ENTER.\n Otherwise press any other key to select again.', result), mx/2-120, my/2+600);
                                    %                                     Screen('Flip', this.window);
                                     Screen('Flip', this.window);
                                end
                            end
                        end
                    end
                    
                    if x > cornerEx+20 && y > cornerEy+50 && x< cornerEx+170 && y< cornerEy+100 && result~=0
                        break;
                        
                    end
                end
               
               
            end
            
            Screen( 'TextColor', this.window, oldDefaultColor); % recover previous default color
           
            HideCursor;
        end
        
        %% DlgSelectMouse
        
        function result = DlgSelectMouse2( this, message, optionLetters, optionDescriptions, varargin )
            
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
            
            ShowCursor('Hand');
            
            prevbutton = 1;
            drawing = 1;
            while(1) % while no valid key is pressed
                
                option_selected = 0;
                
                [x,y,buttons] = GetMouse;
                
                % write the options highlighting the selected option
                % if there is one
                [mx, my] = RectCenter(this.wRect);
                DrawFormattedText( this.window,  message, mx/2+135, my-180);
                for i=1:length(optionLetters)
                    if ( y > my-130+30*i && y <my-110+30*i && x > mx-200 && x < mx)
                        Screen('FrameOval', this.window, [255 0 0] ,[mx-200; my-130+30*i; mx-180; my-110+30*i], 30);
                        option_selected = i;
                    else
                        Screen('FrameOval', this.window, [0 0 255] ,[mx-200; my-130+30*i; mx-180; my-110+30*i], 30);
                    end
                    DrawFormattedText( this.window,  ['(' optionLetters{i} ')' optionDescriptions{i}], mx-120, my-134+30*i);
                end
                
                % exit if the button is clicked (and was not clicked in the
                % previous itteration), and the cursor is over one of the
                % options.
                if ( buttons(1) && ~prevbutton && option_selected  >0 );
                    result = optionLetters{option_selected};
                    drawing =1;
                    break;
                end
                prevbutton = buttons(1);
                
                
                %-- Check for keyboard press and exit with scape throwing
                %the exception
                [keyIsDown,secs,keyCode] = KbCheck;
                if keyCode(ESCAPE)
                    Screen( 'TextColor', this.window, oldDefaultColor); % recover previous default color
                    HideCursor;
                    throw(MException('PSYCORTEX:USERQUIT', ''));
                end
                if drawing
                    Screen('Flip', this.window);
                    drawing = 0;
                end
            end
            
            Screen( 'TextColor', this.window, oldDefaultColor); % recover previous default color
            Screen('Flip', this.window);
            HideCursor;
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
        
        
        
        %% DlgScroll
        function answer = DlgScroll( this, message, varargin )
            
            %DlgScroll rates one parameter. Use DlgScales for several rates
            %message = Message to show. If picture is shown then leave it empty ''
            %bottomlimit = bottom limit for scale. i.e 0 for scale (0-...)
            %limit = top limit for scale. i.e 10 for scale (...10)
            %bars = number of tick bars to show
            %rate = label for the parameter rated
            %next = button next picture
            %fullpicturepath = full path for the picture (manekins)
            
            
            if nargin < 1
                error('DlgHitKey: Must provide at least the first argument.');
            end
            
            if ( nargin < 2 || isempty(message) )
                message = '';
            end
            
            if ( nargin < 3  )
                bottomlimit = 1;
            else
                bottomlimit = varargin{1};
            end
            
            if ( nargin < 4  )
                limit = 10;
            else
                limit = varargin{2};
            end
            
            if ( nargin < 5  )
                bars = 5;
            else
                bars = varargin{3};
            end
            if ( nargin < 6  )
                rate= [];
            else
                rate = varargin{4};
            end
            
            if ( nargin < 7  )
                next = [];
            else
                next = varargin(5);
            end
            
            if ( nargin < 8  )
                picture = [];
            else
                picture = varargin(6);
            end
            
            oldDefaultColor = Screen( 'TextColor', this.window); % recover previous default color
            
            [mx, my] = RectCenter(this.wRect)
            cornerEx = mx + 300
            cornerEy = my + 300
            ESCAPE = 27;
            ENTER = {13,3,10};
            DELETE = 8;
            
            if ~isempty(picture)
                distance = 170;
                I = imread( char(picture) , 'BMP' );
                trial.imageTexture = Screen('MakeTexture', this.window, I, 1);
                length = size(I,2);
                height = size(I,1);
                scrollx = mx - length/2 + 135;%35;
                scrolly = my + height/2 + 100;
                selectionx = mx;%(2*scrollx + (bars*distance) )/2;
                selectiony = my + height/2 + 100;
            else
                distance = 120;
                scrollx = mx/2-200;
                scrolly = my/2+200;
                selectionx = (2*scrollx + (bars*distance) )/2; %mx -20;
                selectiony = my/2+200;
            end
            ending = scrollx+(bars*distance);
            
            [x,y,buttons] = GetMouse;
            FlushEvents('mouseDown');
            FlushEvents('keyDown');
            
            ShowCursor('Hand');
            N = imread( char(next) , 'BMP' );
            
            trial.nextTexture = Screen('MakeTexture', this.window, N, 1);
            
            Screen('Flip', this.window);
            exitcase = 0;
            go_next = 0;
            drawing = 1;
            while(1)
                [x,y,buttons] = GetMouse;
                if buttons(1)
                    
                    if x > scrollx && x <ending && y > scrolly-300 && y <scrolly+20
                        selectionx = x;
                        if ~isempty(picture)
                            selectiony = my + height/2 + 100;
                        else
                            selectiony = my/2+200;
                        end
                        
                    end
                    if x > cornerEx+50 && y > cornerEy+70 && x< cornerEx+200 && y< cornerEy+120
                        exitcase = 0;
                        HideCursor;
                        break;
                        
                    end
                    drawing = 1;
                end
                [keyIsDown,secs,keyCode] = KbCheck;
                if keyIsDown
                    keyCode = find(keyCode);
                    if size(keyCode,2)>1
                        keyCode = keyCode(1);
                    end
                    switch keyCode
                        case ESCAPE, % <scape>
                            answer  = -1;
                            exitcase = 1;
                            break;
                        case ENTER
                            if go_next
                                exitcase = 0;
                                break;
                            end
                        otherwise
                            FlushEvents('keyDown');
                            exitcase = 0;
                    end
                end
                
                Screen('DrawTexture', this.window, trial.nextTexture, [], [cornerEx+50; cornerEy+70; cornerEx+200;cornerEy+120], 0);
                DrawFormattedText( this.window, message, scrollx-80, scrolly-60);
                if isempty(picture)
                    DrawFormattedText( this.window, num2str(bottomlimit), scrollx-28 ,scrolly-10 );
                    DrawFormattedText( this.window, num2str(limit), ending+25,scrolly-10 );
                    DrawFormattedText( this.window, ['un' char(rate)], scrollx-90, scrolly+15 );
                    DrawFormattedText( this.window, char(rate), scrollx+(bars*distance)-50,scrolly+15 );
                end
                if ~isempty(picture)
                    Screen('DrawTexture', this.window, trial.imageTexture, [], [], 0);
                end
                Screen('DrawLine', this.window, [26 128 204] ,scrollx, scrolly, scrollx+(bars*distance), scrolly, 8);
                
                for indexbar = scrollx:distance:ending
                    Screen('DrawLine', this.window, [26 128 204] ,indexbar, scrolly+10, indexbar, scrolly-10, 8);
                end
                Screen('FrameOval', this.window, [0 0 0] ,[selectionx-10; selectiony-15; selectionx+10; selectiony+15], 40);
                % Screen('FrameOval', this.window, [0 255 255] ,[10; 10; 50;50], 30);
                
                if drawing
                    Screen('Flip', this.window);
                    drawing = 0;
                end
                
            end
            
            Screen( 'TextColor', this.window, oldDefaultColor); % recover previous default color
            Screen('Flip', this.window);
            
            FlushEvents('keyDown');
            
            temp = (100*(selectionx-scrollx))/(ending-scrollx);
            
            if ~exitcase
                answer = round(bottomlimit+(temp*(limit-bottomlimit))/100);
            end
            
            
            
        end
        
        
        %% DlgScales
        function answer = DlgScales( this, message, varargin )
            
            %DlgScales
            %message = Message to show.
            %rates = the labels for all the scale ratings. The length
            %establishes how many scales will be shown
            %limit = how many ticks the scale has (9 = 0 - 8)
            %next = full path for the next button
            %side = adds the text 'less/more' on the sides of the labels
            
            if nargin < 1
                error('DlgHitKey: Must provide at least the first argument.');
            end
            
            if ( nargin < 2 || isempty(message) )
                message = '';
            end
            
            if ( nargin < 3  )
                rates = [];
            else
                rates = varargin{1};
            end
            
            if ( nargin < 4  )
                limit =9;
            else
                limit = varargin{2};
            end
            
            if ( nargin < 5  )
                next = [];
            else
                next = varargin{3};
            end
            
            if ( nargin < 6  )
                side = [];
            else
                side = varargin{4};
            end
            
            if ( nargin < 7  )
                how_text = {'not at all', 'somewhat', 'extremely'};
            else
                how_text = varargin{5};
            end
            if ( nargin < 8  )
                this.dlgTextColor = [255 255 255];
            else
                this.dlgTextColor = varargin{6};
            end
             oldDefaultColor = Screen( 'TextColor', this.window); 
%              this.dlgTextColor = [255 255 255];            
             Screen( 'TextColor', this.window, this.dlgTextColor);
%             % recover previous default color
            N = imread( char(next) , 'BMP' );
            drawing = 1;
            trial.nextTexture = Screen('MakeTexture', this.window, N, 1);
            [mx, my] = RectCenter(this.wRect);
            cornerEx = mx + 300;
            cornerEy = my + 300;
            ESCAPE = 27;
            ENTER = {13,3,10};
            DELETE = 8;
            start = 300;%500
            ending = 1100;%1300
            for ind=1:length(rates)
                selectionx(ind) = (start+ending)/2;
            end
            [x,y,buttons] = GetMouse;
            FlushEvents('mouseDown');
            FlushEvents('keyDown');
            
            ShowCursor('Hand');
            
            
            Screen('Flip', this.window);
            exitcase = 0;
            go_next = 0;
            while(1)
                
                
                [keyIsDown,secs,keyCode] = KbCheck;
                if keyIsDown
                    keyCode = find(keyCode);
                    if size(keyCode,2)>1
                        keyCode = keyCode(1);
                    end
                    switch keyCode
                        case ESCAPE, % <scape>
                            answer  = -1;
                            exitcase = 1;
                            break;
                        case ENTER
                            if go_next
                                exitcase = 0;
                                break;
                            end
                        otherwise
                            FlushEvents('keyDown');
                            exitcase = 0;
                    end
                end
                
                %Draw text and button next
               
                DrawFormattedText( this.window, message, 30, 50);
                Screen('DrawTexture', this.window, trial.nextTexture, [], [cornerEx+70; cornerEy+120; cornerEx+220;cornerEy+170], 0);
                
                % Draw the numbers for the scale and the indications
                if ~side
                    for index=0:1:limit-1
                        DrawFormattedText( this.window, num2str(index), index*100+start-10, 130);
                    end
                end
                DrawFormattedText( this.window, cell2mat(how_text(1)), start-80, 150);
                DrawFormattedText( this.window, cell2mat(how_text(2)), (start+ending)/2-50, 150);
                DrawFormattedText( this.window, cell2mat(how_text(3)), ending-80, 150);
                
                % Draw the scales
                for loc=1:length(rates)
                    
                    if side
                        % originally the 2 first lines were used 
                        %DrawFormattedText( this.window, ['less ' char(rates(loc))], start-180 ,100+loc*100 );
                        %DrawFormattedText( this.window, ['more ' char(rates(loc))], ending+20,100+loc*100 );
                        DrawFormattedText( this.window, char(rates(loc)), start-160, 100+loc*100 + 11);
                    else
                        DrawFormattedText( this.window, char(rates(loc)), start-160 ,100+loc*100 - 5 );
                    end
                    
                    Screen('DrawLine', this.window, [26 128 204] ,start, 100+loc*100, ending, 100+loc*100, 8);
                    
                    for indexbar = start:100:ending
                        Screen('DrawLine', this.window, [26 128 204] ,indexbar, 100+loc*100-10 , indexbar, 100+loc*100+10, 8);
                    end
                    
                    Screen('FrameOval', this.window, [26 26 255] ,[selectionx(loc)-10; 100+loc*100-15; selectionx(loc)+10; 100+loc*100+15], 40);
                    
                end
                
                
                [x,y,buttons] = GetMouse;
                %Updates the selections after clicks
                if buttons(1)
                    for loc=1:length(rates)
                        
                        if x > start && x <ending && y > 100+loc*100-20  && y < 180+loc*100
                            selectionx(loc) = x;
                        end
                    end
                    
                    if x > cornerEx+70 && y > cornerEy+120 && x< cornerEx+220 && y< cornerEy+170
                        for loc =1:length(rates)
                            answer(loc) =floor(  (selectionx(loc)-start) / ((ending-start)/limit));
                        end
                        break;
                    end
                    
                    drawing = 1;
                end
                if drawing
                    Screen('Flip', this.window);
                    drawing = 0;
                end
            end
            HideCursor;
            
             Screen( 'TextColor', this.window, oldDefaultColor); % recover previous default color
            Screen('Flip', this.window);
            
            
            
            
            FlushEvents('keyDown');
            FlushEvents('MouseDown');
            
        end
        
        %% DlgSAM
        function [happy shocked controlled] = DlgSAM( this, message, varargin )
            
            %DlgSAM(win, tstring , limit, fullpicturepath
            %message = Message to show. If picture is shown then leave it empty ''
            %limit = top limit for scale. i.e 9 for scale (0-8)
            %nimages = number of panels to click within the image
            %picture = full path for the picture (manekins)
            %next = full path for the button next
            
            
            if nargin < 1
                error('DlgHitKey: Must provide at least the first argument.');
            end
            
            if ( nargin < 2 || isempty(message) )
                message = '';
            end
            
            if ( nargin < 3  )
                limit = 9;
            else
                limit = varargin{1};
            end
            
            if ( nargin < 4  )
                nimages = 5;
            else
                nimages = varargin{2};
            end
            
            if ( nargin < 5  )
                picture = [];
            else
                picture = varargin(3);
            end
            
            if ( nargin < 6  )
                next = [];
            else
                next = varargin(4);
            end
            
            happy = 0;
            shocked = 0;
            controlled = 0;
            oldDefaultColor = Screen( 'TextColor', this.window); % recover previous default color
            
            [mx, my] = RectCenter(this.wRect);
            
            ESCAPE = 27;
            ENTER = {13,3,10};
            DELETE = 8;
            
            I = imread( char(picture) , 'BMP' );
            N = imread( char(next) , 'BMP' );
            trial.imageTexture = Screen('MakeTexture', this.window, I, 1);
            trial.nextTexture = Screen('MakeTexture', this.window, N, 1);
            width = size(I,2);
            height = size(I,1);
            cornerx = mx - width/2;
            cornery = my - height/2;
            cornerEx = mx + width/2;
            cornerEy = my + height/2;
            
            [x,y,buttons] = GetMouse;
            FlushEvents('mouseDown');
            FlushEvents('keyDown');
            
            ShowCursor('Hand');
            
            drawing = 1;
            Screen('Flip', this.window);
            exitcase = 0;
            go_next = 0;
            while(1)
                [x,y,buttons] = GetMouse;
                if buttons(1)
                    
                    if x > cornerx && x <cornerEx && y > cornery && y <cornerEy
                        
                        selection = ceil((x-cornerx)/spacex);
                        
                        if y < cornery + spacey
                            %happy
                            happy = selection;
                            
                        else if y > cornery + spacey && y < cornery+2*spacey
                                %shocked
                                shocked = selection;
                                
                            else if y < cornerEy
                                    %controlled
                                    controlled = selection;
                                    
                                end
                            end
                        end
                        drawing = 1;
                        
                    end
                    
                    if x > cornerEx+20 && y > cornerEy+50 && x< cornerEx+170 && y< cornerEy+100
                        
                        if happy >0 && shocked>0 
                            
                            break;
                        end
                        
                    end
                    
                end
                [keyIsDown,secs,keyCode] = KbCheck;
                if keyIsDown
                    keyCode = find(keyCode);
                    if size(keyCode,2)>1
                        keyCode = keyCode(1);
                    end
                    switch keyCode
                        case ESCAPE, % <scape>
                            happy  = -1;
                            exitcase = 1;
                            break;
                            
                        otherwise
                            FlushEvents('keyDown');
                            exitcase = 0;
                    end
                end
                
                
                Screen('DrawTexture', this.window, trial.imageTexture, [], [], 0);
                Screen('DrawTexture', this.window, trial.nextTexture, [], [cornerEx-20; cornerEy+50; cornerEx+130;cornerEy+100], 0);
                
                
                
                spacex = (width-10)/limit;
                spacey = height/nimages;
                
                if happy>0
                    Screen('FrameOval', this.window, [26 128 204] ,[floor(cornerx + happy*spacex - spacex); floor(cornery)+126 ; floor(cornerx + happy*spacex) ; floor(cornery + spacey)], 20);
                end
                if shocked>0
                    Screen('FrameOval', this.window, [128 204 76] ,[floor(cornerx + shocked*spacex - spacex); floor(cornery +spacey)+125; floor(cornerx + shocked*spacex) ; floor(cornery + 10 + 2*spacey)], 20);
                end
                if controlled>0
                    Screen('FrameOval', this.window, [230 51 51] ,[floor(cornerx + controlled*spacex - spacex); floor(cornery +2*spacey)+125; floor(cornerx + controlled*spacex) ; floor(cornery + 25+ 3*spacey)], 20);
                end
                
                if drawing
                    Screen('Flip', this.window);
                    drawing = 0;
                end
                
                
            end            
            
            HideCursor;
            
            Screen( 'TextColor', this.window, oldDefaultColor); % recover previous default color
            Screen('Flip', this.window);
            
            FlushEvents('keyDown');
            
        end
        
        %% Dlg Keypad
        function [finalNumber secondsElapsed] = DlgKeypad( this, message, varargin )
            
            %DlgSAM(win, tstring , limit, fullpicturepath
            %message = Message to show. If picture is shown then leave it empty ''
            %limit = top limit for scale. i.e 9 for scale (0-8)
            %nimages = number of panels to click within the image
            %picture = full path for the picture (keypad)
            
            if nargin < 1
                error('DlgHitKey: Must provide at least the first argument.');
            end
            
            if ( nargin < 2 || isempty(message) )
                message = '';
            end
            
            if ( nargin < 3  )
                limit = 4;
            else
                limit = varargin{1};
            end
            
            if ( nargin < 4  )
                nimages = 3;
            else
                nimages = varargin{2};
            end
            
            if ( nargin < 5  )
                picture = [];
            else
                picture = varargin(3);
            end  
            
            if ( nargin < 6  )
                timeout = 5;
            else
                timeout = varargin(4);
            end 
            
            finalNumber = '';
            number = 0;
            next = 0;
            oldDefaultColor = Screen( 'TextColor', this.window); % recover previous default color
            
            [mx, my] = RectCenter(this.wRect);
            
            ESCAPE = 27;
            ENTER = {13,3,10};
            DELETE = 8;
            
            I = imread( char(picture) , 'JPG' ); 
            secondsRemaining = cell2mat(timeout);
            
             trial.imageTexture = Screen('MakeTexture', this.window, I, 1);      
            
            width = size(I,2);
            height = size(I,1);
            cornerx = mx - width/2;
            cornery = my - height/2;
            cornerEx = mx + width/2;
            cornerEy = my + height/2;
            
%             [x,y,buttons] = GetMouse;
            FlushEvents('mouseDown');
            FlushEvents('keyDown');
            
            ShowCursor('Hand');
            drawing = 1;
%             Screen('Flip', this.window);
            selection = -1;
            
            secondsRemaining    = cell2mat(timeout);
            pressed = 0;
            
            lastFlipTime        = Screen('Flip', this.window);
            startLoopTime = lastFlipTime;
            spacex = (width-10)/limit;
            spacey = height/nimages;
            
            while secondsRemaining > 0
                
%                    Screen('DrawTexture', this.window, trial.imageTexture, [], [], 0);
%                     DrawFormattedText( this.window, finalNumber, mx-250, 120, [255 255 255]);
%                     DrawFormattedText( this.window, message, mx-250, 90);                    
                    
                secondsElapsed      = GetSecs - startLoopTime;
                secondsRemaining    = cell2mat(timeout) - secondsElapsed;
                
                delete = 0;
                [x,y,buttons] = GetMouse;
                
                if buttons(1)
                    
                    if x > cornerx && x <cornerEx && y > cornery && y <cornerEy
                        
                        selection = ceil((x-cornerx)/spacex);
                        
                        if y < cornery + spacey
                            %789
                            number = selection+6;
                            
                        else if y > cornery + spacey && y < cornery+2*spacey
                                %456
                                number = selection+3;
                                
                            else if  y > cornery + spacey && y < cornery+3*spacey
                                    %123
                                    number = selection;
                                    
                                else if y < cornerEy
                                        %0CN
                                        switch selection
                                            case 1
                                                number = 0;
                                            case 2
                                                delete = 1;
                                            case 3
                                                next = 1;
                                        end
                                        
                                    end
                                    
                                end
                            end
                        end
                        
                        pressed = 1;
                        
                    end
                    
                    if (next==1) 
                        
                        if(~isempty(finalNumber ))
                        %finalNumber = -1;                       
                            break;
                        else
                            disp('not yet!');                            
                            pressed = 0;  
                            next = 0;
                        end
                    end
                    
                end
                [keyIsDown,secs,keyCode] = KbCheck;
                if keyIsDown
                    keyCode = find(keyCode);
                    if size(keyCode,2)>1
                        keyCode = keyCode(1);
                    end
                    switch keyCode
                        case ESCAPE, % <scape>
                            finalNumber = '-2';
                            exitcase = 1;
                            break;
                            
                        otherwise
                            FlushEvents('keyDown');
                            exitcase = 0;
                    end
                end
                
                if delete && pressed
                    finalNumber = finalNumber(1:end-1);
                    delete = 0;
                    pressed = 0;
%                     DrawFormattedText( this.window, finalNumber, mx-250, 140, [255 255 255]);
%                      DrawFormattedText( this.window, message, mx-250, 110);        
                    drawing = 1;
                else
                    
                    if pressed && ~buttons(1)
                        drawing = 1;
                        pressed = 0;
                        
                        if selection>0
                            if strcmp(finalNumber,'-1')
                                finalNumber = [];
                            end
                            finalNumber = cat(2, finalNumber, num2str(number));
                        end
%                         DrawFormattedText( this.window, finalNumber, mx-250, 140, [255 255 255]);
%                          DrawFormattedText( this.window, message, mx-250, 110);        
                    end
                end
                
                
                if drawing
                     Screen('DrawTexture', this.window, trial.imageTexture, [], [], 0);
                     DrawFormattedText( this.window, finalNumber, mx-250, 148, [0 0 0]);
                     DrawFormattedText( this.window, message, mx-250, 110, [255 255 255]);                  
                     %DrawFormattedText( this.window, message, varargin{:});                  
                    drawing = 0;
                    Screen('Flip', this.window);
                end
               
            end
            
              
            
            HideCursor;
            
            Screen( 'TextColor', this.window, oldDefaultColor); % recover previous default color
            Screen('Flip', this.window);
            
            FlushEvents('keyDown');
            
        end
        
        
        
    end
end


% ROTATE: Given a configuration of points, rotates a 2D configuration about
%         a given point by a specified angle (in radians).
%
%     Usage: [newpts,pivot] = rotate(pts,theta,{pivot},{doplot})
%
%         pts =    [N x 2] matrix of coordinates of point configuration.
%         theta =  angle by which configuration is to be rotated; a positive
%                    angle rotates the configuration counterclockwise, a
%                    negative angle rotates it clockwise.
%         pivot =  optional 2-element vector of coordinates of the pivot point
%                    [default = centroid].
%         doplot = optional boolean variable indicating, if true, that plots
%                    are to be produced depicting the point configuration before
%                    and after rotation [default = 0].
%         ----------------------------------------------------------------------
%         newpts = [N x 2] matrix of registered & rotated points.
%         pivot =  [1 x 2] vector of coordinates of pivot point.
%

% RE Strauss, 6/26/96
%   5/6/03 - return pivot point.
%   5/14/03 - added optional plots.

function [newpts,pivot] = rotate(pts,theta,pivot)
if (~nargin) help rotate; return; end;

if (nargin < 3) pivot = []; end;


N = size(pts,1);                        % Number of points

if (isempty(pivot))
    [area,perim,pivot] = polyarea(pts);   % Use centroid for pivot
else
    pivot = pivot(:)';
    if (length(pivot)~=2)
        error('  Rotate: pivot point must be vector of length 2.');
    end;
end;

savepts = pts;
pts = pts - ones(N,1)*pivot;            % Zero-center on pivot
dev = anglerotation([0 0],[1,0],pts,1); % Angular deviations of pts from horizontal
dev = dev + theta;                      % Add angle of rotation to deviations
r = sqrt(pts(:,1).^2 + pts(:,2).^2);    % Distances of pts from origin

newpts = zeros(size(pts));
newpts(:,1) = r.*cos(dev) + pivot(1);   % New rectangular coordinates,
newpts(:,2) = r.*sin(dev) + pivot(2);   %   restoring pivot
i = find(~isfinite(rowsum(newpts)));
if (~isempty(i))
    newpts(i,:) = ones(length(i),1)*pivot;
end;

return;

end
