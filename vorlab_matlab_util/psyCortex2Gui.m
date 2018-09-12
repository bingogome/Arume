function varargout = psyCortex2Gui(varargin)
% psyCortex2Gui M-file for psyCortex2Gui.fig
%      psyCortex2Gui, by itself, creates a new psyCortex2Gui or raises the
%      existing
%      singleton*.
%
%      H = psyCortex2Gui returns the handle to a new psyCortex2Gui or the handle to
%      the existing singleton*.
%
%      psyCortex2Gui('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in psyCortex2Gui.M with the given input arguments.
%
%      psyCortex2Gui('Property','Value',...) creates a new psyCortex2Gui or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before psyCortex2Gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to psyCortex2Gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help psyCortex2Gui

% Last Modified by GUIDE v2.5 04-Dec-2009 12:30:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @psyCortex2Gui_OpeningFcn, ...
    'gui_OutputFcn',  @psyCortex2Gui_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before psyCortex2Gui is made visible.
function psyCortex2Gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to psyCortex2Gui (see VARARGIN)

% Choose default command line output for psyCortex2Gui
handles.output = hObject;

if ( ~isfield( handles, 'this' ) )
    handles.this = [];
end

set(handles.figure1,'CloseRequestFcn',@closeGUI);

update_gui( hObject, handles )

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes psyCortex2Gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = psyCortex2Gui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function closeGUI(src,evnt)
%this function is called when the user attempts to close the GUI window
 

%this command brings up the close window dialog
selection = questdlg('Do you want to close the GUI?',...
                     'Close Request Function',...
                     'Yes','No','Yes');
 
%if user clicks yes, the GUI window is closed, otherwise
%nothing happens
switch selection,
   case 'Yes',
    delete(gcf)
   case 'No'
     return
end


% --- Executes on button press in butRun.
function butRun_Callback(hObject, eventdata, handles)
% hObject    handle to butRun (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


handles = runSession( handles );
    
update_gui(hObject, handles);
% Update handles structure
guidata(hObject, handles);



% --- Executes on button press in butResume.
function butResume_Callback(hObject, eventdata, handles)
% hObject    handle to butResume (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

mnuRunResume_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function butClose_CreateFcn(hObject, eventdata, handles)
% hObject    handle to butClose (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --------------------------------------------------------------------
function mnuExperimentExit_Callback(hObject, eventdata, handles)
% hObject    handle to mnuExperimentExit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

close(handles.figure1);

% --------------------------------------------------------------------
function mnuExperiment_Callback(hObject, eventdata, handles)
% hObject    handle to mnuExperiment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function mnuExperimentEditExperimentConfiguration_Callback(hObject, eventdata, handles)
% hObject    handle to mnuExperimentEditExperimentConfiguration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


if ( isempty( handles.this ) )
    msgbox('It is necessary to first load an experiment','Error','error')
    return;
end

stats = handles.this.GetStats();

if ( stats.totalTrials > 0 )
    msgbox('You have to close the current session to edit the parameters','Error','error')
    return;
end

% TODO TODO TODO TODO if experiment is modified, a session cannot be
% resumed, only started

S = handles.this.ExperimentInfo.Parameters;
S.trialSequence = { {'Sequential', 'Random', 'Random with repetition'}};
S.trialSequence{1}{find(streq(S.trialSequence{1},handles.this.ExperimentInfo.Parameters.trialSequence))} = ['{' handles.this.ExperimentInfo.Parameters.trialSequence '}'];

S.trialAbortAction = { {'Repeat', 'Delay', 'Drop'}};
S.trialAbortAction{1}{find(streq(S.trialAbortAction{1},handles.this.ExperimentInfo.Parameters.trialAbortAction))} = ['{' handles.this.ExperimentInfo.Parameters.trialAbortAction '}'];


res = StructDlg(S, 'Edit Experiment parameters', [], get(handles.figure1,'position').*[1.2 1.2 1 1]);

if ( isempty(res) )
    return;
end

handles.this.ExperimentInfo.Parameters = res;

update_gui(hObject, handles);
guidata(hObject, handles);


% --------------------------------------------------------------------
function mnuSession_Callback(hObject, eventdata, handles)
% hObject    handle to mnuSession (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function mnuSessionStartNewSession_Callback(hObject, eventdata, handles)
% hObject    handle to mnuSessionStartNewSession (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ( ~isempty( handles.this ) )
    result = questdlg('There is current session open, continue?', 'Question', 'Yes', 'No', 'Yes');
    if ( isequal( result, 'No') )
        return;
    end
end

lastExperiment = getpref('psycortex','lastexperiment', 'FVScotoma');

S.Experiment = {};
psycortex_folder = fileparts(mfilename('fullpath'));
d = dir([psycortex_folder '\+PsyCortexExperiments\@*']);
for i = 1:length(d)
    name = d(i).name;
    if ( isempty(strfind(name,'PsyCortexExperiment')) )
        if ( ~isequal(lastExperiment, name(2:end)))
            S.Experiment {end+1} = name(2:end);
        else
            S.Experiment {end+1} = ['{' name(2:end) '}'];
        end
    end
    
end
S.Experiment = {S.Experiment};
pos = get(gcf,'position');
S = StructDlg(S, 'Select an experiment',[],pos+[10 10 0 0]);
if ( isempty( S ) )
    return;
end
handles = clear_gui( hObject, handles );
handles.this = feval(['PsyCortexExperiments.' S.Experiment '']);

update_gui( hObject, handles ); 
guidata(hObject, handles);


setpref('psycortex','lastexperiment', S.Experiment);


% --------------------------------------------------------------------
function mnuSessionLoadSession_Callback(hObject, eventdata, handles)
% hObject    handle to mnuSessionLoadSession (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ( ~isempty( handles.this ) )
    result = questdlg('There is current session open, continue?', 'Question', 'Yes', 'No', 'Yes')
    if ( isequal( result, 'No') )
        return;
    end
end

orig_dir = pwd;
path = getpref('psyCortex', 'loadSessionFile', [pwd filesep]);
cd(path);
[filename, pathname] = uigetfile( ...
    {'*.mat','Mat file with session information (*.mat)';}, ...
    'Select a session to load');
cd(orig_dir);
if isequal(filename,0) || isequal(pathname,0)
    return
end
setpref('psyCortex', 'loadSessionFile', pathname);

load(fullfile(pathname, filename) )
[path filename ext ] = fileparts(filename)

if ( ~exist('this','var' ) )
    eval(['this = ' filename ';']);
end
if ( ~exist('this','var' ) )
    error( 'Experiment varible not found in the file');
end
    

handles = clear_gui( hObject, handles );

handles.this = this;

update_gui(hObject, handles);

% TODO update message saying the session was started before and when

% Update handles structure
guidata(hObject, handles);

% --------------------------------------------------------------------
function mnuSessionSaveSession_Callback(hObject, eventdata, handles)
% hObject    handle to mnuSessionSaveSession (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


if ( isempty( handles.this ) )
    msgbox('It is necessary to first load an experiment','Error','error')
    return;
end

[filename, pathname] = uiputfile( ...
    {'*.mat','Mat file with session information (*.mat)';}, ...
    'Save as');

if isequal(filename,0) || isequal(pathname,0)
    return
end

this = handles.this;

save( fullfile( pathname, filename ), 'this' );

% --------------------------------------------------------------------
function mnuSessionCloseSession_Callback(hObject, eventdata, handles)
% hObject    handle to mnuSessionCloseSession (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


if ( isempty( handles.this) )
    msgbox('There is no session open to close','Error','error')
    return;
end

if ( isfield( handles.this, 'CurrentRun' ) )
    result = questdlg('There is current session open, continue?', 'Question', 'Yes', 'No', 'Yes');
    if ( isequal( result, 'No') )
        return;
    end
end

handles = clear_gui( hObject, handles );
update_gui(hObject, handles);

guidata(hObject, handles);

% TODO update message saying the session was started before and when

% Update handles structure
guidata(hObject, handles);

% --------------------------------------------------------------------
function mnuRun_Callback(hObject, eventdata, handles)
% hObject    handle to mnuRun (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function mnuConfig_Callback(hObject, eventdata, handles)
% hObject    handle to mnuConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function mnuTools_Callback(hObject, eventdata, handles)
% hObject    handle to mnuTools (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function mnuToolsViewLog_Callback(hObject, eventdata, handles)
% hObject    handle to mnuToolsViewLog (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --------------------------------------------------------------------
function mnuConfigLoadConfiguration_Callback(hObject, eventdata, handles)
% hObject    handle to mnuConfigLoadConfiguration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function mnuConfigSaveConfiguration_Callback(hObject, eventdata, handles)
% hObject    handle to mnuConfigSaveConfiguration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function mnuConfigEditConfiguration_Callback(hObject, eventdata, handles)
% hObject    handle to mnuConfigEditConfiguration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


if ( isempty( handles.this ) )
    msgbox('It is necessary to first load an experiment','Error','error')
    return;
end

stats = handles.this.GetStats();

if ( stats.totalTrials > 0 )
    msgbox('You have to close the current session to edit the configuration','Error','error')
    return;
end

S = handles.this.Config;

if ( S.UsingEyelink )
    S.UsingEyelink = { {'0','{1}'} };
else
    S.UsingEyelink = { {'{0}','1'} };
end
if ( S.Debug )
    S.Debug = { {'0','{1}'} };
else
    S.Debug = { {'{0}','1'} };
end

res = StructDlg(S, 'Edit Configuration', [], get(handles.figure1,'position').*[1.2 1.2 1 1]);

if ( isempty(res) )
    return;
end

handles.this.Config = res;

update_gui(hObject, handles);
guidata(hObject, handles);

% --------------------------------------------------------------------
function mnuRunStart_Callback(hObject, eventdata, handles)
% hObject    handle to mnuRunStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = runSession( handles );
    
update_gui(hObject, handles);
% Update handles structure
guidata(hObject, handles);


function handles = runSession( handles )

stats = handles.this.GetStats();

if ( isempty( handles.this ) )
    msgbox('It is necessary to first load an experiment','Error','error')
    return;
end

if ( stats.totalTrials > 0 ) % already started
    %this command brings up the close window dialog
    selection = questdlg('Some trials have already been run, are you sure you want to restart?',...
        'Restart?',...
        'Yes','No','No');

    %if user clicks yes, the GUI window is closed, otherwise
    %nothing happens
    switch selection,
        case 'Yes',
            % TODO: get values from gui and test if this is empty or not, ask if
            % subject is sure does not want to resume
            handles.this = psyCortex('restart session', handles.this);

        case 'No'
            return
    end
else
    name = get(handles.txtSubject,'string');
    if ( length(name) ~= 3 )
        msgbox('Subject code should have 3 characters','Error','error')
        return
    end
    session = get(handles.txtSession,'string');
    if ( length(session) ~= 1 )
        msgbox('Session code should have only 1 characters','Error','error')
        return
    end
    % TODO: get values from gui and test if this is empty or not
    handles.this.StartSession( name, session );
end

% --------------------------------------------------------------------
function mnuRunResume_Callback(hObject, eventdata, handles)
% hObject    handle to mnuRunResume (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 
stats = handles.this.GetStats();

if ( isempty( handles.this ) || ( stats.totalTrials == 0 ) )
    msgbox('There is no session started to resume, load a session','Error','error')
    return;
end
handles.this.ResumeSession();

update_gui(hObject, handles);
% Update handles structure
guidata(hObject, handles);


function update_gui( hObject, handles )


if ( ~isempty( handles.this ) )
    stats = handles.this.GetStats();
    set(handles.lblExperiment,'string', handles.this.Name);
    set(handles.txtSubject,'string', handles.this.SubjectCode)
    set(handles.txtSession,'string', handles.this.SessionSuffix)
    
    set(handles.lblCorrectTrials,'string', ...
        sprintf('%d/%d (%d/%d)',stats.sessionTrialsCorrect,handles.this.ExperimentInfo.Parameters.trialsPerSession,stats.trialsCorrect,stats.trialsInExperiment));
    
    set(handles.lblAbortTrials,'string', ...
        sprintf('%d (%d)',stats.sessionTrialsAbort,stats.trialsAbort ) )
    set(handles.lblTotalTrialsToRun,'string',  ...
        sprintf('%d (%d)',stats.sessionTotalTrials,stats.totalTrials ) )
    
    set(handles.lblBlock,'string',  ...
        sprintf('%d - %d/%d',stats.currentBlockID,stats.currentBlock,stats.blocksInExperiment ) )
    
    set(handles.lblCurrentSession,'string',  ...
        sprintf('%d / %d',stats.currentSession,stats.SessionsToRun ) )
end

set(handles.butRun,'Enable','off')
set(handles.butResume,'Enable','off')
set(handles.mnuRunStart,'Enable','off')
set(handles.mnuRunResume,'Enable','off')

set(handles.txtSession,'Enable','on')
set(handles.txtSubject,'Enable','on')

if (~isempty( handles.this ) )
    stats = handles.this.GetStats();

    if ( stats.totalTrials > 0 )
        if ( stats.trialsToFinishExperiment > 0 )
            set(handles.butResume,'Enable','on');
        end
        set(handles.mnuRunResume,'Enable','on');
        set(handles.txtSession,'Enable','off')
        set(handles.txtSubject,'Enable','off')
    else
        set(handles.butRun,'Enable','on');
        set(handles.mnuRunStart,'Enable','on');
    end
    
    
end



function handles = clear_gui( hObject, handles )


set(handles.lblExperiment,'string', '')
set(handles.txtSubject,'string', '000')
set(handles.txtSession,'string', 'Z')

set(handles.lblTotalTrialsToRun,'string', '0')
set(handles.lblCorrectTrials,'string', '0/1 (0/1)')
set(handles.lblAbortTrials,'string', '0')
set(handles.lblBlock,'string', '1 - 1/1')
set(handles.lblCurrentSession,'string', '1/1')

handles.this = [];

% TODO update message saying the session was started before and when

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in butSave.
function butSave_Callback(hObject, eventdata, handles)
% hObject    handle to butSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

mnuSessionSaveSession_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function butSave_CreateFcn(hObject, eventdata, handles)
% hObject    handle to butSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



% --- Executes during object creation, after setting all properties.
function butRun_CreateFcn(hObject, eventdata, handles)
% hObject    handle to butRun (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



function txtSubject_Callback(hObject, eventdata, handles)
% hObject    handle to txtSubject (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtSubject as text
%        str2double(get(hObject,'String')) returns contents of txtSubject as a double


% --- Executes during object creation, after setting all properties.
function txtSubject_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtSubject (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtSession_Callback(hObject, eventdata, handles)
% hObject    handle to txtSession (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtSession as text
%        str2double(get(hObject,'String')) returns contents of txtSession as a double


% --- Executes during object creation, after setting all properties.
function txtSession_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtSession (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function butResume_CreateFcn(hObject, eventdata, handles)
% hObject    handle to butResume (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in butSave.
function pushbutton9_Callback(hObject, eventdata, handles)
% hObject    handle to butSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in butRun.
function pushbutton10_Callback(hObject, eventdata, handles)
% hObject    handle to butRun (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in butResume.
function pushbutton11_Callback(hObject, eventdata, handles)
% hObject    handle to butResume (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit6_Callback(hObject, eventdata, handles)
% hObject    handle to txtSubject (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtSubject as text
%        str2double(get(hObject,'String')) returns contents of txtSubject as a double


% --- Executes during object creation, after setting all properties.
function edit6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtSubject (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit7_Callback(hObject, eventdata, handles)
% hObject    handle to txtSession (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtSession as text
%        str2double(get(hObject,'String')) returns contents of txtSession as a double


% --- Executes during object creation, after setting all properties.
function edit7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtSession (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1


% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on mouse press over figure background.
function figure1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
