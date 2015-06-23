function varargout = BitebarGUI(varargin)
% BITEBARGUI MATLAB code for BitebarGUI.fig
%      BITEBARGUI, by itself, creates a new BITEBARGUI or raises the existing
%      singleton*.
%
%      H = BITEBARGUI returns the handle to a new BITEBARGUI or the handle to
%      the existing singleton*.
%
%      BITEBARGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BITEBARGUI.M with the given input arguments.
%
%      BITEBARGUI('Property','Value',...) creates a new BITEBARGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before BitebarGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to BitebarGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help BitebarGUI

% Last Modified by GUIDE v2.5 01-Apr-2014 11:24:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @BitebarGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @BitebarGUI_OutputFcn, ...
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


% --- Executes just before BitebarGUI is made visible.
function BitebarGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to BitebarGUI (see VARARGIN)

% Choose default command line output for BitebarGUI
handles.output = hObject;

handles.bitebar = ArumeHardware.BiteBarMotor

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes BitebarGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = BitebarGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in butUpright.
function butUpright_Callback(hObject, eventdata, handles)
% hObject    handle to butUpright (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.bitebar.GoUpright();


% --- Executes on button press in butLED20.
function butLED20_Callback(hObject, eventdata, handles)
% hObject    handle to butLED20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.bitebar.TiltLeft(20);

% --- Executes on button press in butRED20.
function butRED20_Callback(hObject, eventdata, handles)
% hObject    handle to butRED20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.bitebar.TiltRight(20);

% --- Executes on button press in butHome.
function butHome_Callback(hObject, eventdata, handles)
% hObject    handle to butHome (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

choice = questdlg('Are you sure!!!!?', ...
    'Tilting to Home', ...
    'Yes','No','No');
switch choice
    case 'Yes'
        handles.bitebar.GoHome();
end


% --- Executes on button press in butLED30.
function butLED30_Callback(hObject, eventdata, handles)
% hObject    handle to butLED30 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.bitebar.TiltLeft(30);

% --- Executes on button press in butRED30.
function butRED30_Callback(hObject, eventdata, handles)
% hObject    handle to butRED30 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.bitebar.TiltRight(30);