function arumeController = Arume(command, param)


% persistent variable to keep the singleton
persistent arumeSingleton;
arumeController = arumeSingleton;

% option to clear the singleton
if ( exist('command','var') )
    switch (command )
        case 'clear'
            % clear the persistent variable
            clear arumeSingleton;
            arumeController = [];
            return;
            
        case 'open'
            if ( exist('param','var') )
                projectPath = param;
            end
    end
end

if isempty(arumeSingleton)
    % Initialization, object is created automatically
    % (this is the constructor) and then initialized
    
    arumeSingleton = ArumeCore.ArumeController();
    arumeSingleton.init();
    arumeController = arumeSingleton;
end

% Load the GUI
gui = ArumeGui( arumeSingleton );

if ( exist('projectPath','var') )
    arumeSingleton.loadProject( projectPath )
    gui.updateGui();
end