function PlotInfo(fileID)

line = fgets(fileID);
seg = strsplit(line);
time = str2num(fscanf(seg(1), '%s'));
temp = str2num(fscanf(seg(2), '%s'));
h1 = str2num(fscanf(seg(3), '%s'));
h2 = str2num(fscanf(seg(4), '%s'));

if exist(filename)
    ax1 = subplot(2,1,1)
    plot(x,temp,'ro')
    %polyfit(x,temp,1)
    title(ax1,'Furnace Temperature')
    xlabel(ax1, 'Time')
    ylabel(ax1, 'Temperature')
    hold all;
    
    ax2 = subplot(2,1,2)
    plot(x,h1,'ko',x,h2,'ro');
    title(ax2,'Hydrogen Levels')
    xlabel(ax2,'Time')
    ylabel(ax2,'Hydrogen Level')
    hold all;
else
    CreateFile()
end

end