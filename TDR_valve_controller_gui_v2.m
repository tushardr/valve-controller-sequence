function varargout = TDR_valve_controller_gui_v2(varargin)
% TDR_VALVE_CONTROLLER_GUI_V2 MATLAB code for TDR_valve_controller_gui_v2.fig
%      TDR_VALVE_CONTROLLER_GUI_V2, by itself, creates a new TDR_VALVE_CONTROLLER_GUI_V2 or raises the existing
%      singleton*.
%
%      H = TDR_VALVE_CONTROLLER_GUI_V2 returns the handle to a new TDR_VALVE_CONTROLLER_GUI_V2 or the handle to
%      the existing singleton*.
%
%      TDR_VALVE_CONTROLLER_GUI_V2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TDR_VALVE_CONTROLLER_GUI_V2.M with the given input arguments.
%
%      TDR_VALVE_CONTROLLER_GUI_V2('Property','Value',...) creates a new TDR_VALVE_CONTROLLER_GUI_V2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before TDR_valve_controller_gui_v2_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to TDR_valve_controller_gui_v2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help TDR_valve_controller_gui_v2

% Last Modified by GUIDE v2.5 28-Mar-2013 16:28:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TDR_valve_controller_gui_v2_OpeningFcn, ...
                   'gui_OutputFcn',  @TDR_valve_controller_gui_v2_OutputFcn, ...
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


% --- Executes just before TDR_valve_controller_gui_v2 is made visible.
function TDR_valve_controller_gui_v2_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to TDR_valve_controller_gui_v2 (see VARARGIN)

% Choose default command line output for TDR_valve_controller_gui_v2
handles.output = hObject;


% UIWAIT makes TDR_valve_controller_gui_v2 wait for user response (see UIRESUME)
% uiwait(handles.figure1);

%*************************************************************************
handles.valves_per_box=24;
handles.number_of_boxes=1;
handles.total_number_of_valves=handles.valves_per_box*handles.number_of_boxes;
handles.available_valves=[1:handles.total_number_of_valves];
%*************************************************************************
%if ~libisloaded('FTD2XX')
%    loadlibrary('FTD2XX', 'myFTD2XX.h');
%end;
%*************************************************************************

%*************************************************************************
handles.dev_handle = uint32(0);
flag = uint32(1);  % flag=1    =>  Open by serial number
                   % flag=2    =>  Open by description
                   % flag=4    =>  Open by Location 

% Retrieve the controller box information and generate a handle for the
% controller box
    serial_number=get(handles.dev_ser_number,'String');    
    
    %serial_number='ELQR4X8Q';                                  
    [FT_status, handles.dev_handle] = usbio24_open_setup_by_sn(serial_number);   
    if FT_status==0
        set(handles.status_message,'String','Controller box opened successfully')
    else
        Error_mesg=valve_controller_error_decoder(FT_status);
        set(handles.status_message,'String',strcat('Error in opening controller box. Error mesg:',Error_mesg))
    end
%*************************************************************************

%*************************************************************************
[FT_status, current_valve_status] = usbio24_get_bits(handles.dev_handle,[0:handles.valves_per_box-1]);
if FT_status==0
    % Show closed valves in solid squares
    plot(handles.valve_status,[find(current_valve_status)],ones(size(find(current_valve_status))),'s','MarkerFaceColor','g')
    hold(handles.valve_status,'on')
    % Show open valves in transparent squares
    plot(handles.valve_status,[find(~current_valve_status)],ones(size(find(~current_valve_status))),'s')
    axis(handles.valve_status,[0 25 0.8 1.2])
    set(handles.valve_status,'xtick',[0:25])
    hold(handles.valve_status,'off')
else
    Error_mesg=valve_controller_error_decoder(FT_status);
    set(handles.status_message,'String',strcat('Error in retrieving valve status. Error mesg:',Error_mesg))
end
%*************************************************************************

% Disable some buttons to begin with so that the user cannot erroneously
% use them without providing required data
set(handles.execute_seq,'Visible','off')
set(handles.interrupt_seq,'Visible','off')
set(handles.sequence_input,'Visible','off')
set(handles.sequence_info_text,'Visible','off')
set(handles.valves_to_close_at_end_of_seq,'Visible','off')
set(handles.valves_to_close_at_end_of_seq_text,'Visible','off')
%*************************************************************************

%*************************************************************************
% Initialize a flag to interrupt sequence if requested by user
setappdata(handles.figure1,'interrupt_seq_flag',false)
%*************************************************************************

% Update handles structure
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = TDR_valve_controller_gui_v2_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;




% --- Executes on button press in close_valves.
function close_valves_Callback(hObject, eventdata, handles)
% hObject    handle to close_valves (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%*************************************************************************
% First read the required status of all the valves from the checkboxes on
% the GUI
for valve=1:handles.valves_per_box
    eval(strcat('reqd_valve_status(',num2str(valve),')=get(handles.v',num2str(valve),',''Value'');'))
end

% Write the required bit pattern to the valve controller chip
FT_status=usbio24_set_bits(handles.dev_handle, [0:(handles.valves_per_box-1)], reqd_valve_status);
if FT_status==0
    set(handles.status_message,'String','Requested valves closed successfully')
else
    Error_mesg=valve_controller_error_decoder(FT_status);
    set(handles.status_message,'String',strcat('Error in closing the valves. Error mesg:',Error_mesg))
end    
%*************************************************************************

%*************************************************************************
% Refresh valve status
refresh_valve_status_Callback(hObject, eventdata, handles);
%*************************************************************************

% Update handles structure
guidata(hObject, handles);


function seq_valve_pool_Callback(hObject, eventdata, handles)
% hObject    handle to seq_valve_pool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of seq_valve_pool as text
%        str2double(get(hObject,'String')) returns contents of seq_valve_pool as a double

%*************************************************************************
handles.seq_valves=get(handles.seq_valve_pool,'String');
handles.seq_valves=str2num(handles.seq_valves);
if isempty(handles.seq_valves)
    Error_mesg='Enter numbers only for valves you moron!';
    set(handles.status_message,'String',Error_mesg);
    handles.seq_valves_valid=0;
elseif find(~ismember(handles.seq_valves,handles.available_valves))                                                 
    Error_mesg=strcat(['Valve numbers range from 1 to ',handles.valves_per_box,' only. Cant close a valve which doesnt exist in my record']);
    set(handles.status_message,'String',Error_mesg);
    handles.seq_valves_valid=0;
else
    set(handles.status_message,'String','Valves in the sequence valid. Please paste the sequence in the box below.');
    handles.seq_valves_valid=1;
    set(handles.sequence_input,'Visible','on')
    set(handles.sequence_info_text,'Visible','on')    
    set(handles.valves_to_close_at_end_of_seq,'Visible','on')
    set(handles.valves_to_close_at_end_of_seq,'String',num2str(handles.seq_valves))
    % Default seq end valves are the same as the valves from the sequence
    % pool, just in case user doesn't enter any seq end valves
    handles.seq_end_valves=handles.seq_valves;
end
%*************************************************************************

% Update handles structure
guidata(hObject, handles);

function sequence_input_Callback(hObject, eventdata, handles)
% hObject    handle to sequence_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sequence_input as text
%        str2double(get(hObject,'String')) returns contents of sequence_input as a double

%*************************************************************************
handles.seq_string=get(handles.sequence_input,'String');
handles.valves_closed_by_default=get(handles.valves_closed_by_default_box,'Value');
[handles.valve_closure_seq,handles.wait_time_seq,handles.seq_valid,Error_mesg]=process_sequence_input_ver2p1(handles.seq_string,handles.seq_valves,handles.valves_closed_by_default);
if ~handles.seq_valid
    set(handles.status_message,'String',Error_mesg)    
else
    set(handles.status_message,'String','Sequence input is valid')
    set(handles.execute_seq,'Visible','on')
end
%*************************************************************************

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in read_sequence_file.
function read_sequence_file_Callback(hObject, eventdata, handles)
% hObject    handle to read_sequence_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[seq_input_file,seq_input_file_dir]=uigetfile('*.xls;*.xlslx','Pick the excel file containing valve sequence information');
cd(seq_input_file_dir)
seq_input_file=strcat(seq_input_file_dir,seq_input_file);

[handles.valve_closure_seq,handles.wait_time_seq,handles.seq_end_valves,handles.seq_valid,Error_mesg]= read_sequence_input_file(seq_input_file,handles.available_valves);

if ~handles.seq_valid
    set(handles.status_message,'String',Error_mesg);    
else
    set(handles.status_message,'String','Sequence file read successfully');
    set(handles.execute_seq,'Visible','on');
end

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in execute_seq.
function execute_seq_Callback(hObject, eventdata, handles)
% hObject    handle to execute_seq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%*************************************************************************
%Freeze all other gui options while running the sequence except interrupt
%seq
set(handles.dev_ser_number_change,'Enable','off')
set(handles.close_valves,'Enable','off')
set(handles.refresh_valve_status,'Enable','off')
set(handles.seq_valve_pool,'Enable','off')
set(handles.sequence_input,'Enable','off')
set(handles.read_sequence_file,'Enable','off')
set(handles.valves_to_close_at_end_of_seq,'Enable','off')
set(handles.valves_closed_by_default_box,'Enable','off')
set(handles.time_log_on,'Enable','off')
set(handles.valve_update_on,'Enable','off')
set(handles.seq_rep_count,'Enable','off')


set(handles.interrupt_seq,'Visible','on')
set(handles.execute_seq,'Visible','off')
%*************************************************************************
handles.interrupt_seq_flag=getappdata(handles.figure1,'interrupt_seq_flag')

time_log_on=get(handles.time_log_on,'Value');
if time_log_on
    [handles.time_log_data_file,time_log_file_dir]=uigetfile('*.txt','Pick a file to save the sequence time log data');
    handles.time_log_data_file=strcat([time_log_file_dir,handles.time_log_data_file]);
end
valve_update_on=get(handles.valve_update_on,'Value');

set(handles.status_message,'String','Running sequence now');
seq_rep_count=str2num(get(handles.seq_rep_count,'String'));
total_seq_steps=length(handles.valve_closure_seq);
if isempty(seq_rep_count)
    set(handles.status_message,'String','Sequence repeat count can only be a number')
else
    if time_log_on
        tic; % to prevent any error during first execution
        for current_seq_rep=1:seq_rep_count
            % check if we need to interrupt_sequence
            if handles.interrupt_seq_flag
                break;
            end
           
            for seq_step=1:total_seq_steps
                % Pause statement required to make sure the interrupting
                % button callback executes even when this loop is running
                %pause(0.01)
                drawnow()
                handles.interrupt_seq_flag=getappdata(handles.figure1,'interrupt_seq_flag')
                if handles.interrupt_seq_flag
                    break;
                end
                reqd_valve_status=zeros(handles.valves_per_box,1);
                % turn on all the valves to be closed during this step
                reqd_valve_status(handles.valve_closure_seq(seq_step).valve_set)=1;
                % Write the required bit pattern to the valve controller chip
                FT_status=usbio24_set_bits(handles.dev_handle, [0:(handles.valves_per_box-1)], reqd_valve_status);
                % First time log data point in this array is random but the later
                % data points are as close as we can measure to the actual time between two valve actuations 
                time_log_data((current_seq_rep-1)*total_seq_steps+seq_step,1:2)=[toc,FT_status];
                tic  % start measuring wait time
                % Update the valve status
                if valve_update_on
                    refresh_valve_status_Callback(hObject, eventdata, handles)
%                     [FT_status, current_valve_status] = usbio24_get_bits(handles.dev_handle,[0:(handles.valves_per_box-1)]);
%                     if FT_status==0
%                         % Show closed valves in solid squares
%                         plot(handles.valve_status,[find(current_valve_status)],ones(size(find(current_valve_status))),'s','MarkerFaceColor','g')
%                         hold on
%                         % Show open valves in transparent squares
%                         plot(handles.valve_status,[find(~current_valve_status)],ones(size(find(~current_valve_status))),'s')
%                         hold off
%                     else
%                         Error_mesg=valve_controller_error_decoder(FT_status);
%                         set(handles.status_message,'String',strcat('Error in retrieving valve status. Error mesg:',Error_mesg))
%                     end
                end
                % Keep measuring time until the next step
                end_wait_time=false;
                while ~end_wait_time 
                    %Keep checking time and end loop after wait time ends
                    if toc>handles.wait_time_seq(seq_step)
                        end_wait_time=true;
                    end
                end
            end
        end
        
        if ~handles.interrupt_seq_flag 
            %Last FT_status is not useful but the time from toc is
            % Do this only if the sequence wasn't interrupted
            time_log_data(seq_rep_count*total_seq_steps+1,1:2)=[toc,FT_status];
        end

        %*************************************************************************
        % Save time log data to a file if the variable time_log_data exists
        % the variable doesn't exist of sequence is interrupted without
        % completing a single step
        if exist('time_log_data')
            
            % Generate the cell array to write
            seq_reps_executed=mod(size(time_log_data,1),total_seq_steps);
            for seq_rep=1:seq_reps_executed+1
                for seq_step=1:total_seq_steps
                    executed_seq_steps((seq_rep-1)*total_seq_steps+seq_step,1)={num2str(handles.valve_closure_seq(seq_step).valve_set)};
                    executed_seq_steps((seq_rep-1)*total_seq_steps+seq_step,2)={handles.wait_time_seq(seq_step)};
                end
            end
            
            % Truncate executed_seq_steps array to actual number of steps
            % that were executed
            executed_seq_steps=executed_seq_steps(1:size(time_log_data,1),1:2);
            time_log_fid=fopen(handles.time_log_data_file,'w');
            fprintf(time_log_fid,'valves_closed \t seq_wait_time \t actual_wait_time \t valve_actuation_status \n');
            fprintf(time_log_fid,'%s \t %6.6f \t %6.6f \t %6.6f',[executed_seq_steps(:,1) executed_seq_steps(:,2) time_log_data(:,1) time_log_data(:,2)]);
            fclose(time_log_fid)
            % all the variables above will be deleted as soon as function
            % returns control. so no need to delete them.
            %dlmwrite(handles.time_log_data_file,time_log_data,'delimiter','\t','precision',6)
        end
    else
        % This mode is for very high speed valve actuation with minimal
        % overhead from other tasks between other valve actuations
        for current_seq_rep=1:seq_rep_count
            % check if we need to interrupt_sequence
            if handles.interrupt_seq_flag
                break;
            end
            
            for seq_step=1:total_seq_steps
                % Pause statement required to make sure the interrupting
                % button callback executes even when this loop is running
                %pause(0.01)
                drawnow()
                handles.interrupt_seq_flag=getappdata(handles.figure1,'interrupt_seq_flag')
                if handles.interrupt_seq_flag
                    break;
                end
                reqd_valve_status=zeros(handles.valves_per_box,1);
                reqd_valve_status(handles.valve_closure_seq(seq_step).valve_set)=1;
                % Write the required bit pattern to the valve controller chip
                FT_status=usbio24_set_bits(handles.dev_handle, [0:(handles.valves_per_box-1)], reqd_valve_status);
                tic  % start measuring wait time
                % Keep measuring time until the next step
                end_wait_time=false;
                while ~end_wait_time 
                    %Keep checking time and end loop after wait time ends
                    if toc>handles.wait_time_seq(seq_step)
                        end_wait_time=true;
                    end
                end
            end
        end                 
    end        
end

%*************************************************************************
% Close the valves requested to be closed at the end of the sequence
%*************************************************************************
reqd_valve_status=zeros(handles.valves_per_box,1);
% turn on all the valves to be closed
reqd_valve_status(handles.seq_end_valves)=1;
% Write the required bit pattern to the valve controller chip
FT_status=usbio24_set_bits(handles.dev_handle, [0:(handles.valves_per_box-1)], reqd_valve_status);

if FT_status==0
    if handles.interrupt_seq_flag
        set(handles.status_message,'String','Sequence interrupted and sequence end valves closed successfully')
    else
        set(handles.status_message,'String','Sequence ended and sequence end valves closed successfully')
    end
else
    Error_mesg=valve_controller_error_decoder(FT_status);
    set(handles.status_message,'String',strcat('Error in closing sequence end valves. Error mesg:',Error_mesg))
end    


%*************************************************************************
% Refresh valve status in case valve update was disabled
refresh_valve_status_Callback(hObject, eventdata, handles);
%*************************************************************************

% Clear sequence related fields from the handles structure
rmfield(handles,'valve_closure_seq');
rmfield(handles,'wait_time_seq');


%*************************************************************************
%Reenable all other gui options after the sequence is over 
set(handles.dev_ser_number_change,'Enable','on')
set(handles.close_valves,'Enable','on')
set(handles.refresh_valve_status,'Enable','on')
set(handles.seq_valve_pool,'Enable','on')
set(handles.sequence_input,'Enable','on')
set(handles.read_sequence_file,'Enable','on')
set(handles.valves_closed_by_default_box,'Enable','on')
set(handles.valves_to_close_at_end_of_seq,'Enable','on')
set(handles.time_log_on,'Enable','on')
set(handles.valve_update_on,'Enable','on')
set(handles.seq_rep_count,'Enable','on')


set(handles.sequence_info_text,'Visible','off')
set(handles.sequence_input,'Visible','off')
set(handles.valves_to_close_at_end_of_seq,'Visible','off')
set(handles.valves_to_close_at_end_of_seq_text,'Visible','off')
set(handles.interrupt_seq,'Visible','off')
set(handles.execute_seq,'Visible','off')
%*************************************************************************

% Reinitialize interrupt sequence flag 
setappdata(handles.figure1,'interrupt_seq_flag',false)


% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in interrupt_seq.
function interrupt_seq_Callback(hObject, eventdata, handles)
% hObject    handle to interrupt_seq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

setappdata(handles.figure1,'interrupt_seq_flag',true)

% Update handles structure
guidata(hObject, handles);


function valves_to_close_at_end_of_seq_Callback(hObject, eventdata, handles)
% hObject    handle to valves_to_close_at_end_of_seq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of valves_to_close_at_end_of_seq as text
%        str2double(get(hObject,'String')) returns contents of valves_to_close_at_end_of_seq as a double


%*************************************************************************
seq_end_valves=get(handles.valves_to_close_at_end_of_seq,'String');
seq_end_valves=str2num(seq_end_valves);

if isempty(handles.seq_valves)
    Error_mesg='Enter numbers only for sequence end valves you moron!';
    set(handles.status_message,'String',Error_mesg);
elseif find(~ismember(seq_end_valves,handles.available_valves))                                                 
    Error_mesg=strcat(['Valve numbers range from 1 to ',handles.valves_per_box,' only. Cant close valves which doesnt exist in my record after the sequence ends']);
    set(handles.status_message,'String',Error_mesg);
else
    set(handles.status_message,'String','Valves to close at the end of sequence valid.');
    handles.seq_end_valves=seq_end_valves;    
end
%*************************************************************************

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in refresh_valve_status.
function refresh_valve_status_Callback(hObject, eventdata, handles)
% hObject    handle to refresh_valve_status (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%*************************************************************************
%Assuming we have only one box need to change if more
%than one box is used
[FT_status, current_valve_status] = usbio24_get_bits(handles.dev_handle,[0:(handles.valves_per_box-1)]);

if FT_status==0
    cla(handles.valve_status) % clear the valve status axes
    if isempty(find(current_valve_status))
        plot(handles.valve_status,[find(~current_valve_status)],ones(size(find(~current_valve_status))),'s')
    else
        % Show closed valves in solid squares
        plot(handles.valve_status,[find(current_valve_status)],ones(size(find(current_valve_status))),'s','MarkerFaceColor','g')
        hold(handles.valve_status,'on')
        % Show open valves in transparent squares
        plot(handles.valve_status,[find(~current_valve_status)],ones(size(find(~current_valve_status))),'s')
        hold(handles.valve_status,'off')
    end
else
    Error_mesg=valve_controller_error_decoder(FT_status);
    set(handles.status_message,'String',strcat('Error in retrieving valve status. Error mesg:',Error_mesg))
end
%*************************************************************************



% --- Executes on button press in term_program.
function term_program_Callback(hObject, eventdata, handles)
% hObject    handle to term_program (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%*************************************************************************
% open all the valves before shutting down the controller box
FT_status=usbio24_set_bits(handles.dev_handle, [0:(handles.valves_per_box-1)], zeros(handles.valves_per_box,1));

if FT_status~=0
    Error_mesg=valve_controller_error_decoder(FT_status);
    set(handles.status_message,'String',strcat('Error in opening valves. Error mesg:',Error_mesg))
end

[FT_status] = calllib('ftd2xx', 'FT_Close', handles.dev_handle);

if FT_status==0
    set(handles.status_message,'String','Valve controller box closed successfully')
else
    Error_mesg=valve_controller_error_decoder(FT_status);
    set(handles.status_message,'String',strcat('Error in opening valves. Error mesg:',Error_mesg))    
end
%*************************************************************************



% --- Executes during object creation, after setting all properties.
function sequence_input_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sequence_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dev_ser_number_Callback(hObject, eventdata, handles)
% hObject    handle to dev_ser_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dev_ser_number as text
%        str2double(get(hObject,'String')) returns contents of dev_ser_number as a double


% --- Executes during object creation, after setting all properties.
function dev_ser_number_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dev_ser_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in dev_ser_number_change.
function dev_ser_number_change_Callback(hObject, eventdata, handles)
% hObject    handle to dev_ser_number_change (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)






% --- Executes during object creation, after setting all properties.
function seq_valve_pool_CreateFcn(hObject, eventdata, handles)
% hObject    handle to seq_valve_pool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in v1.
function v1_Callback(hObject, eventdata, handles)
% hObject    handle to v1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of v1


% --- Executes on button press in v2.
function v2_Callback(hObject, eventdata, handles)
% hObject    handle to v2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of v2


% --- Executes on button press in v3.
function v3_Callback(hObject, eventdata, handles)
% hObject    handle to v3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of v3


% --- Executes on button press in v4.
function v4_Callback(hObject, eventdata, handles)
% hObject    handle to v4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of v4


% --- Executes on button press in v5.
function v5_Callback(hObject, eventdata, handles)
% hObject    handle to v5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of v5


% --- Executes on button press in v6.
function v6_Callback(hObject, eventdata, handles)
% hObject    handle to v6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of v6


% --- Executes on button press in v7.
function v7_Callback(hObject, eventdata, handles)
% hObject    handle to v7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of v7


% --- Executes on button press in v8.
function v8_Callback(hObject, eventdata, handles)
% hObject    handle to v8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of v8


% --- Executes on button press in v9.
function v9_Callback(hObject, eventdata, handles)
% hObject    handle to v9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of v9


% --- Executes on button press in v10.
function v10_Callback(hObject, eventdata, handles)
% hObject    handle to v10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of v10


% --- Executes on button press in v11.
function v11_Callback(hObject, eventdata, handles)
% hObject    handle to v11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of v11


% --- Executes on button press in v12.
function v12_Callback(hObject, eventdata, handles)
% hObject    handle to v12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of v12


% --- Executes on button press in v13.
function v13_Callback(hObject, eventdata, handles)
% hObject    handle to v13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of v13


% --- Executes on button press in v14.
function v14_Callback(hObject, eventdata, handles)
% hObject    handle to v14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of v14


% --- Executes on button press in v15.
function v15_Callback(hObject, eventdata, handles)
% hObject    handle to v15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of v15


% --- Executes on button press in v16.
function v16_Callback(hObject, eventdata, handles)
% hObject    handle to v16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of v16


% --- Executes on button press in v17.
function v17_Callback(hObject, eventdata, handles)
% hObject    handle to v17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of v17


% --- Executes on button press in v18.
function v18_Callback(hObject, eventdata, handles)
% hObject    handle to v18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of v18


% --- Executes on button press in v19.
function v19_Callback(hObject, eventdata, handles)
% hObject    handle to v19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of v19


% --- Executes on button press in v20.
function v20_Callback(hObject, eventdata, handles)
% hObject    handle to v20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of v20


% --- Executes on button press in v21.
function v21_Callback(hObject, eventdata, handles)
% hObject    handle to v21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of v21


% --- Executes on button press in v22.
function v22_Callback(hObject, eventdata, handles)
% hObject    handle to v22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of v22


% --- Executes on button press in v23.
function v23_Callback(hObject, eventdata, handles)
% hObject    handle to v23 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of v23


% --- Executes on button press in v24.
function v24_Callback(hObject, eventdata, handles)
% hObject    handle to v24 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of v24



function seq_rep_count_Callback(hObject, eventdata, handles)
% hObject    handle to seq_rep_count (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of seq_rep_count as text
%        str2double(get(hObject,'String')) returns contents of seq_rep_count as a double


% --- Executes during object creation, after setting all properties.
function seq_rep_count_CreateFcn(hObject, eventdata, handles)
% hObject    handle to seq_rep_count (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in time_log_on.
function time_log_on_Callback(hObject, eventdata, handles)
% hObject    handle to time_log_on (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of time_log_on


% --- Executes on button press in valve_update_on.
function valve_update_on_Callback(hObject, eventdata, handles)
% hObject    handle to valve_update_on (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of valve_update_on


% --- Executes on button press in valves_closed_by_default_box.
function valves_closed_by_default_box_Callback(hObject, eventdata, handles)
% hObject    handle to valves_closed_by_default_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of valves_closed_by_default_box





% --- Executes during object creation, after setting all properties.
function valves_to_close_at_end_of_seq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to valves_to_close_at_end_of_seq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

