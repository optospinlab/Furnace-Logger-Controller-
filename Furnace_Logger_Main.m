function Furnace_Logger_Main(varargin)
    clear all; close all; clc

    delete(instrfind)
    delete(findall(0, 'Type', 'figure'))
    
    s = serial('COM4');
%     s = serial('/dev/cu.usbmodem1421');
    set(s,'BaudRate',74880);
    fopen(s);               % **Do error checking here to make sure the serial connection was made...

    global chnNames;        % This cell array contains the name of each of the channels that we measure.
    global chnUnits;        % This cell array contains the corresponding units.
    chnNames = {'Time', 'Temperature',  'Setpoint',  'Duty Cycle', 'H1',    'H2',    'H3',    'H4',    'H5',    'TimeMATLAB'};
    chnUnits = {'',     'deg C',        'deg C',     'percent',    'Volts', 'Volts', 'Volts', 'Volts', 'Volts', '' };
%                             Note that the first and last cells will always be
%                             interpreted as the readable timestamp and the
%                             MATLAB timestamp, no matter what is contained in
%                             these cells

    global message;         % If this string is nonempty, the contents will be sent to the Arduino
    message = '';
    
    
    
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
 
    function setSetpoint(setpoint)          % **Check whether multiple messages are being sent at the same time?
        message = ['s ' num2str(setpoint)];
    end

    function startAnneal(fname)
        fname
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

    function setSetpointCallback(~,~)
        setSetpoint(setpointField.String)
    end

    function startAnnealCallback(~,~)
        [fname, pname] = uigetfile({'*.txt', '*.*'}, 'Choose an Annealing Recipe...', 'MultiSelect', 'off');
        startAnneal([pname fname]);
    end

    f = figure('Name', 'Furnace Control Logger', 'NumberTitle', 'off', 'CloseRequestFcn', @closeCallback);
    
    setpointField =     uicontrol(f, 'Style', 'edit',       'Position', [50 50 100 25],  'String',  0);
    setpointButton =    uicontrol(f, 'Style', 'pushbutton', 'Position', [150 50 100 25], 'String', 'Set Setpoint', 'Callback', @setSetpointCallback);

    startAnnealButton = uicontrol(f, 'Style', 'pushbutton', 'Position', [150 75 100 25], 'String', 'Start Anneal', 'Callback', @startAnnealCallback);
    
    global zoomCheckbox;
    zoomCheckbox = uicontrol(f, 'Style', 'checkbox', 'Position', [300 75 100 25], 'String', 'Zoom In');
    
    today = datestr(datetime('today')); % Set dates
    yesterday = datestr(datetime('yesterday'));

    running = true;
    global fileID;
    fileID = 0;
        
    a1 = axes('Parent', f, 'Position', [.1 .68 .8 .27]); 
    a2 = axes('Parent', f, 'Position', [.1 .3 .8 .27]);

    a1.XLimMode = 'manual';
    a1.Title.String = 'Furnace Temperature';
    a1.XLabel.String ='Time';
    a1.YLabel.String = 'Temperature';
    hold(a1,'on');

    a2.XLimMode = 'manual';
    a2.Title.String = 'Hydrogen Levels';
    a2.XLabel.String ='Time';
    a2.YLabel.String = 'Hydrogen Level';
    hold(a2,'on');
    
    % ** MAKE YESTERDAY'S FILE
    % ** FIX DAY SWITCHING!!!

    while running
        if ~fileID           % If file doesn't exist (new day), create new file.
            today = datestr(datetime('today')); % Reset dates.
            yesterday = datestr(datetime('yesterday'));
            fileID = CreateFile(today); % Check that fileID is actually filled?
        end
        
        while strcmp(today, datestr(datetime('today'))) && running       % var == true is redundant
            data = fscanf(s, '%f');

            if ~isempty(data)                       %if string is not empty, writes to text file
                fprintf(fileID, datestr(now, 'HH:MM:SS'));
                fprintf(fileID, ' \t%.2f', data);
                fprintf(fileID, '\t%.15f', now);
                fprintf(fileID, '\n');
            end

%             PlotInfo(a1,a2,zoomCheckbox);
            
            fprintf(s, message);
            message = '';

            pause(.5)
        end

        fclose('all');
    end
    
end
