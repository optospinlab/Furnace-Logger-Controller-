function PlotInfo(a1,a2,a3,zoomCheckbox, numVar)
    global fileID;
    data_today = dlmread(strcat('Logs\AnnealData_',datestr(datetime('today')),'.txt'), '\t', 2,1);
    data_yesterday = dlmread(strcat('Logs\AnnealData_',datestr(datetime('yesterday')),'.txt'), '\t', 2,1);
%     data = [data_yesterday; data_today];
    data = [data_today; data_today];
    
    % ** Instead of 9, put in len(vars)+2
    
    tic
     if fileID > 0
%         disp('tick')
        plot(a1,data(1:60:end, numVar),data(1:60:end,2),'b');
        plot(a1,data(1:60:end, numVar),data(1:60:end,3),'r');
        plot(a1,data(1:60:end, numVar),data(1:60:end,4),'g');
        datetick(a1,'x','HH:MM');
        if (get(zoomCheckbox,'Value') == get(zoomCheckbox,'Max'))
            a1.XLim = [now-.04 now];
        else
            a1.XLim = [now-1 now];
        end
        legend(a1,'Temperature','Setpoint', 'Duty Cycle','Location','bestoutside');
        
        plot(a2,data(:, numVar),data(:,5),'b');
        plot(a2,data(:, numVar),data(:,6),'r');
        plot(a2,data(:, numVar),data(:,7),'g');
        plot(a2,data(:, numVar),data(:,8),'m');
        plot(a2,data(:, numVar),data(:,9),'c');
        datetick(a2,'x','HH:MM');
        if (get(zoomCheckbox,'Value') == get(zoomCheckbox,'Max'))
            a2.XLim = [now-.04 now];
        else
            a2.XLim = [now-1 now];
        end
        legend(a2,'Hydrogen 1','Hydrogen 2','Hydrogen 3','Hydrogen 4','Hydrogen 5','Location','bestoutside');
        
        plot(a3,data(1:60:end, numVar),data(1:60:end,1));
        datetick(a3,'x','HH:MM');
        if (get(zoomCheckbox,'Value') == get(zoomCheckbox,'Max'))
            a3.XLim = [now-.04 now];
        else
            a3.XLim = [now-1 now];
        end
        legend(a3,'Pressure (Torr)','Location','bestoutside');
    else
        CreateFile();
    end
    toc
end