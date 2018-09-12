function arumeController = Arume(command, param)

% persistent variable to keep the singleton
persistent arumeSingleton;

if ( isempty( arumeSingleton ) )
    h = findall(0,'tag','Arume');
    if ( ~isempty(h) )
        arumeSingleton = h.UserData.arumeController;
    end
end
    


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
    arumeController.gui = ArumeCore.ArumeGui( arumeSingleton );
end

if ( exist('projectPath','var') )
    arumeSingleton.loadProject( projectPath );
end

if ( useGui )
    % make sure the Arume gui is on th front and update
    figure(arumeController.gui.figureHandle)
    arumeController.gui.updateGui();
end
