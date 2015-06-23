classdef DisplayCmdLine < ArumeCore.Display
    %DISPLAY Summary of this class goes here
    %   Detailed explanation goes here
    properties   
    end
    
    properties(Access=private)
    end
    
    methods
        
        %% Display
        function graph = DisplayCmdLine( exper )
        end
        
        function graph = Init( graph, exper )
            commandwindow
        end
            
        
        function ResetBackground( this )
            
        end
        
        %% Flip
        %--------------------------------------------------------------------------
        function fliptime = Flip( this, exper, trial )
            
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            pause(0.010);
            fliptime = GetSecs;
            
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
            
            if ( this.NumFlips == 1) 
                fprintf('\nRunning....');
            end
            if ( mod(this.NumFlips,100) == 0 )
                fprintf('\b|');
            end
            if ( mod(this.NumFlips,100) == 25 )
                fprintf('\b/');
            end
            if ( mod(this.NumFlips,100) == 50 )
                fprintf('\b-');
            end
            if ( mod(this.NumFlips,100) == 75 )
                fprintf('\b\\');
            end
        end
        
        %% Make hist of flips
        function hist_of_flips = flips_hist(this)
            
            hist_of_flips =  histc(diff(this.fliptimes{end}(1:this.NumFlips)),0:.005:.100);
            %             this.fliptime_hist = hist_of_flips;
            
            
        end
                
        %------------------------------------------------------------------
        %% Dialog Functions  ----------------------------------------------
        %------------------------------------------------------------------
        
        %% DlgHitKey
        function result = DlgHitKey( this, message, varargin )
            % DlgHitKey(window, message, [, sx][, sy][, color][, wrapat][, flipHorizontal][, flipVertical])
            
            commandwindow
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
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
            
            % remove previous key presses
            FlushEvents('keyDown');
            
            disp( sprintf(['\n' message]));
            pause;
            
            char = GetChar;
            switch(char)
                
                case Enum.keys.ESCAPE
                    result = 0;
                    
                otherwise
                    result = char;
            end
        end
        
        %% DlgYesNo
        function result = DlgYesNo( this, message, yesText, noText, varargin )
            % DlgYesNo(window, message, yesText, noText, [, sx][, sy][, color][, wrapat][, flipHorizontal][, flipVertical])
            
            
            commandwindow
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            if nargin < 2
                error('DlgYesNo: Must provide at least the first two arguments.');
            end
            
            if ( nargin < 3 || isempty(yesText) )
                yesText = 'Yes';
            end
            
            if ( nargin < 4 || isempty(noText) )
                noText = 'No';
            end
            
            % possible results
            YES = 1;
            NO  = 0;
            
            % relevant keycodes
            ESCAPE  = 27;
            ENTER   = {13,3,10};
            
            % remove previous key presses
            FlushEvents('keyDown');
            
            disp( sprintf( ['\n' message ' ' yesText ' (enter), ' noText ' (escape)']));
            pause;
            
            while(1)
                char = GetChar;
                switch(char)
                    
                    case ENTER
                        result = YES;
                        break;
                        
                    case Enum.keys.ESCAPE
                        result = NO;
                        break;
                end
            end
        end
        
        %% DlgSelect
        function result = DlgSelect( this, message, optionLetters, optionDescriptions, varargin )
            
            commandwindow
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
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
            disp( sprintf(['\n'  text]));
            pause;
            
            while(1) % while no valid key is pressed
                
                c = GetChar;
                
                switch(c)
                    
                    case Enum.keys.ESCAPE
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
                        
                        disp( sprintf(['\n'  text]));
                        pause;
                        
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
        end
        
        
        %% DlgInput
        function answer = DlgInput( this, message, varargin )
            
            commandwindow
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            %DlgInput(win, tstring [, sx][, sy][, color][, wrapat][, flipHorizontal][, flipVertical])
            
            if nargin < 1
                error('DlgHitKey: Must provide at least the first argument.');
            end
            
            if ( nargin < 2 || isempty(message) )
                message = '';
            end
            
            
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
