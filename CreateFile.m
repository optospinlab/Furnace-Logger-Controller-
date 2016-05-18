function fileID = CreateFile(string)
    global chnNames;
    global chnUnits;

    filename = ['Logs\AnnealData_' string '.txt'];
    
    header = '';
    
    if ~exist(filename, 'file')    % If the file does not exist, fill the header with something. (there's probably a better way to do this)
        for k = 1:length(chnNames)
            if isempty(chnUnits{k})
                header = [header chnNames{k} ' \t'];
            else
                header = [header chnNames{k} ' (' chnUnits{k} ') \t'];
            end
        end
    end
    
    fileID = fopen(filename,'a+t');
    fprintf(fileID, [header '\n']);
end

