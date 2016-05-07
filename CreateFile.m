filename = ['AnnealData_', date, '.txt'];
fileID = fopen(filename,'a+');
if isempty('fileID')
    fprintf(fileID,'%10s %22s %25s %25s\n','time', 'temp', 'hydrogen level 1', 'hydrogen level 2');
end