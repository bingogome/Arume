function arumeController = Arume(command, param)

% Persistent variable to keep the singleton to make sure there is only one
% arume controller loaded at any point in time. That way we can open the UI
% and then also call arume in the command line to get a reference to the
% controller and write scripts working with the current project.
persistent arumeSingleton;

if ( isempty( arumeSingleton ) )
    % The persistent variable gets deleted with clear all. However,
    % variables within the UI do not until UI is closed. So, we can search
    % for the handle of the UI window and get the controller from there.
    % This way we avoid problems if clear all is called with the UI open
    % and then Arume is called again.
    h = findall(0,'tag','Arume');
    if ( ~isempty(h) )
        arumeSingleton = h.UserData.arumeController;
    end
end
    

useGui = 1;

% option to clear the singleton
if ( exist('command','var') )
    switch (command )
        case 'clear'             % clear the persistent variable
            clear arumeSingleton;
            arumeController = [];
            return;
            
        case 'open'
            if ( exist('param','var') )
                projectPath = param;
            end
            
        case 'nogui'
            if ( exist('param','var') )
                projectPath = param;
            end
            useGui = 0;
    end
end

if isempty(arumeSingleton)
    % Initialization, object is created automatically
    % (this is the constructor) and then initialized
    
    arumeSingleton = ArumeCore.ArumeController();
    arumeSingleton.init();
end

if ( exist('projectPath','var') )
    arumeSingleton.loadProject( projectPath );
end

if ( useGui )
    if ( isempty(arumeSingleton.gui) )
        % Load the GUI
        arumeSingleton.gui = ArumeCore.ArumeGui( arumeSingleton );
    end
    % make sure the Arume gui is on the front and update
    figure(arumeSingleton.gui.figureHandle)
    arumeSingleton.gui.updateGui();
end

arumeController = arumeSingleton;
