function Furnace_Logger_Main(varargin)
%     clear all; close all; clc

    delete(instrfind)
    delete(findall(0, 'Type', 'figure'))

%% Create and set up serial connection with Arduino    
    s = serial('COM4');
%     s = serial('/dev/cu.usbmodem1421');
    set(s,'BaudRate',74880);
    fopen(s);               % **Do error checking here to make sure the serial connection was made...

%% Create and set up serial connection with vacuum pump    
    spump = serial('COM1');
    set(spump,'BaudRate',9600);
    fopen(spump);

%% Variable set up    
    global chnNames;        % This cell array contains the name of each of the channels that we measure.
    global chnUnits;        % This cell array contains the corresponding units.
    chnNames = {'Time', 'Pressure', 'Temperature',  'Setpoint',  'Duty Cycle', 'H1',    'H2',    'H3',    'H4',    'H5',    'TimeMATLAB'};
    chnUnits = {'',     'mbar',     'deg C',        'deg C',     'percent',    'Volts', 'Volts', 'Volts', 'Volts', 'Volts', '' };
%                             Note that the first, second, and last cells will always be
%                             interpreted as the readable timestamp and the
%                             MATLAB timestamp, no matter what is contained in
%                             these cells

    numVar = length(chnNames) - 1;
    global message;         % If this string is nonempty, the contents will be sent to the Arduino
    message = '';
    
    running = true;
%% To close program correctly...    
    function closeCallback(~,~)
        disp('Closing...')
        running = false;

        fclose(s);                              % Close the serial connection after everything is done.
        
        fclose('all');

        close(f)                                % Can't remember which works best...
        delete(f)                               
        delete(instrfind)
        delete(findall(0, 'Type', 'figure'))
    end
 
%% Anneal setpoint function
    function setSetpoint(setpoint)              % Sends list of setpoints (predetermined txt files) to Arduino
        message = ['s ' num2str(setpoint)];
    end                                         % **Check whether multiple messages are being sent at the same time?

%% Start anneal function
    function startAnneal(fname)
%         fname
        fid = fopen(fname, 'r');
        if fid ~= -1 %exist(fname, 'file')

            str = '';

            fgetl(fid); % Read header

            line = fgets(fid);

            while ischar(line)
                str = [str line];       % **Not sure if this is the best way to do things...
                line = fgets(fid);
            end

            if ~isempty(str)
                message = ['a ' str];
            end
            
            fclose(fid);
        end
    end    

%% Setpoint/Start Callbacks
    function setSetpointCallback(~,~)
        setSetpoint(setpointField.String)
    end

    function startAnnealCallback(~,~)
        [fname, pname] = uigetfile({'*.txt', '*.*'}, 'Choose an Annealing Recipe...', 'MultiSelect', 'off');
        startAnneal([pname fname]);
    end

%% Create files for today/yesterday
    global fileID_today; %create fileID
    global fileID_yesterday;
    fileID_today = 0;
    fileID_yesterday = 0;

    filename_yesterday = strcat('Logs\AnnealData_',datestr(datetime('yesterday')),'.txt');
    filename_today = strcat('Logs\AnnealData_',datestr(datetime('today')),'.txt');
    
    % Set dates
    today = datestr(datetime('today')); 
    yesterday = datestr(datetime('yesterday'));
    
    % If yesterday's file doesn't exist, create it
    if exist(strcat('Logs\AnnealData_',datestr(datetime('yesterday')),'.txt'),'file')
        disp('yesterday file exists!');
    else
        fileID_yesterday = CreateFile(yesterday);
    end
    fileID_yesterday = fopen(filename_yesterday, 'r'); %set fileID_yesterday to be yesterday's file; read only
    
    % If today's file doesn't exist, create it    
    if exist(strcat('Logs\AnnealData_',datestr(datetime('today')),'.txt'),'file')
        disp('today file exists!');
    else
        fileID_today = CreateFile(today);
    end
    fileID_today = fopen(filename_today, 'a+t'); %set fileID_yesterday to be today's file; appendable

%% Create data figure
    f = figure('Name', 'Furnace Control Logger', 'NumberTitle', 'off', 'CloseRequestFcn', @closeCallback);
    
    %Setpoint Button
    setpointField =     uicontrol(f, 'Style', 'edit',       'Position', [50 50 100 25],  'String',  0);
    setpointButton =    uicontrol(f, 'Style', 'pushbutton', 'Position', [150 50 100 25], 'String', 'Set Setpoint', 'Callback', @setSetpointCallback);
    
    %Start Button
    startAnnealButton = uicontrol(f, 'Style', 'pushbutton', 'Position', [150 75 100 25], 'String', 'Start Anneal', 'Callback', @startAnnealCallback);
    
    %Allows zooming into last hour on graph
    global zoomCheckbox;
    zoomCheckbox = uicontrol(f, 'Style', 'checkbox', 'Position', [300 75 100 25], 'String', 'Zoom In');
    
    % Format axes
%     a1 = axes('Parent', f, 'Position', [.1 .8 .8 .16]); 
%     a2 = axes('Parent', f, 'Position', [.1 .3 .8 .16]);
%     a3 = axes('Parent', f, 'Position', [.1 .55 .8 .16]); 

    a1 = subplot(3,1,1,'Parent', f); 
    a2 = subplot(3,1,2,'Parent', f);
    a3 = subplot(3,1,3,'Parent', f); 
    

    % ** MAKE YESTERDAY'S FILE
    % ** FIX DAY SWITCHING!!!
%% Pressure reading/writing
    
  % command =           [0x02, 0x80, 'WIN', 0x30, 0x03, CRC, CRC]       % This reads the window 'WIN' (three numeric chars) from the pump.
  % command =           [0x02, 0x80, 'WIN', 0x31, data, 0x03, CRC, CRC]	% This writes 'data' to the window 'WIN'.
%     readPressure =      [2, 128, '224', 48, 3, '87']
%     readPressureSetpnt= [2,    128,  '162', 48];
%     setPressureUnits =  [2 '€'  '163' 49 0 3 '85']       % 0 = mbar, 1 = Pa, 2 = Torr
    readPressure = '€224087';
%     setPressureUnits = '€16310.0000B5'

%     fprintf(spump, readPressure);
%   
%     answer = fread(spump)
%     pressurestr = [answer(7:16); ' '];
%     pressure = str2num(pressurestr');
%  

    set(spump,'Timeout',.1);       % Temporary fix to allow pump to be off.
    
%% Create data matrix
            
            data_today = dlmread(strcat('Logs\AnnealData_',datestr(datetime('today')),'.txt'), '\t', 1,1);
            data_yesterday = dlmread(strcat('Logs\AnnealData_',datestr(datetime('yesterday')),'.txt'), '\t', 1,1);
            data = [data_yesterday(:,1:numVar); data_today(:,1:numVar)];
             
%             % Populate matrix with zeros - 172800 seconds in two days
%             data = NaN(172800,20);
%             size(data)
%             
%             % Read in data files
%             data_today = dlmread(strcat('Logs\AnnealData_',datestr(datetime('today')),'.txt'), '\t', 1,1);
%             data_yesterday = dlmread(strcat('Logs\AnnealData_',datestr(datetime('yesterday')),'.txt'), '\t', 1,1);
%             
%             % Find length of data files
%             length_today = length(data_today(:,1))
%             size(data_today)
%             length_yesterday = length(data_yesterday(:,1))
%             size(data_yesterday)
%             
%             % Populate matix with data
%             data(1:size(data_yesterday,1),1:size(data_yesterday,2)) = [data_yesterday];
%             data(86400:86399+size(data_today,1),1:size(data_today,2)) = [data_today];
          
%% Initial Plotting    
    global p1; global p2; global p3; global p4; global p5; global p6; global p7; global p8; global p9; 
    PlotInfo(a1,a2,a3,p1,p2,p3,p4,p5,p6,p7,p8,p9,data,zoomCheckbox,numVar);
%%   
    while running    
        while strcmp(today, datestr(datetime('today'))) && running       % var == true is redundant
            data = fscanf(s, '%f');         
            try
                fprintf(spump, readPressure);
                answer = fread(spump, 19);
                pressurestr = [answer(7:16); ' '];
                pressure = str2double(pressurestr');
            catch
                pressure = -1;
            end
%% Write to today's file            
            if ~isempty(data) && ~isempty(data)                       % if data is not empty, writes to text file
                fprintf(fileID_today, '%s\t', datestr(now, 'HH:MM:SS'));
                fprintf(fileID_today, '%1.1E\t', pressure);
                fprintf(fileID_today, '%.2f\t', data);
                fprintf(fileID_today, '%.11f\t', now);
                fprintf(fileID_today, '\n');
                fprintf(fileID_today, '\n');
            end
            
%% Update plotting            
%     PlotUpdate(a1,a2,a3,p1,p2,p3,p4,p5,p6,p7,p8,p9,data_today,zoomCheckbox,numVar);
%     x_new = data_today(end,numVar);
%     y_new = data_today(end,2);
%     addpoints(p1,x_new,y_new);
        % addpoints function not working -- need to work on this to update plot
        % constantly at low cost
%% Send message to serial             
            fprintf(s, message);
            message = '';
%% Pause
            pause(.01);
        end
        fclose('all');
    end
end
