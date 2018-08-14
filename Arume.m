function arumeController = Arume(command, param)

% persistent variable to keep the singleton
persistent arumeSingleton;
arumeController = arumeSingleton;

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
    arumeController = arumeSingleton;
else
    arumeController = arumeSingleton;
end

if ( useGui && isempty(arumeController.gui))
    % Load the GUI
    gui = ArumeCore.ArumeGui( arumeSingleton );
    arumeController.gui = gui;
else
    gui = arumeController.gui;
end

if ( exist('projectPath','var') )
    arumeSingleton.loadProject( projectPath )
end

if ( useGui )
    gui.updateGui();
end
