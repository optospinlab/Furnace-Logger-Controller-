clear all; close all; clc

s = serial('/dev/cu.usbmodem1421');
set(s,'BaudRate',9600);
fopen(s);

global num_measure; 
num_measure = 4;

while true
    if ~exist('fileID') %if file doesn't exist (new day), create new file
        CreateFile();
        today = datetime('today'); %reset dates
        yesterday = datetime('yesterday');
    end
    
    while strcmp(today, datetime('today')) == true
        data = fscanf(s, '%c', 5*num_measure); %reads in data from serial
        if ~isempty(data) %if string is not empty, writes to text file
            fprintf(fileID, data);
        end
        PlotInfo(fileID);
    end
    
    fclose(fileID);
end
    
fclose(s);