function PlotInfo(a1,a2,zoomCheckbox)
%     tic
    global fileID;
    data_today = dlmread(strcat('Logs\AnnealData_',datestr(datetime('today')),'.txt'), '\t', 2,1);
    data_yesterday = dlmread(strcat('Logs\AnnealData_',datestr(datetime('yesterday')),'.txt'), '\t', 2,1);
    data = [data_yesterday; data_today];
%     toc
   
    % ** Instead of 9, put in len(vars)+2
    
    tic
     if fileID > 0
%         disp('tick')
        plot(a1,data(1:60:end, 9),data(1:60:end,1),'b');
        plot(a1,data(1:60:end, 9),data(1:60:end,2),'r');
        plot(a1,data(1:60:end, 9),data(1:60:end,3),'g');
        datetick(a1,'x','HH:MM');
        if (get(zoomCheckbox,'Value') == get(zoomCheckbox,'Max'))
            a1.XLim = [now-.04 now];
        else
            a1.XLim = [now-1 now];
        end
        legend(a1,'Temperature','Setpoint', 'Duty Cycle','Location','bestoutside');
        
%         plot(a2,data(:, 9),data(:,4),'b');
%         plot(a2,data(:, 9),data(:,5),'r');
%         plot(a2,data(:, 9),data(:,6),'g');
%         plot(a2,data(:, 9),data(:,7),'m');
%         plot(a2,data(:, 9),data(:,8),'c');
%         datetick(a2,'x','HH:MM');
%         if (get(zoomCheckbox,'Value') == get(zoomCheckbox,'Max'))
%             a2.XLim = [now-.04 now];
%         else
%             a2.XLim = [now-1 now];
%         end
%         legend(a2,'Hydrogen 1','Hydrogen 2','Hydrogen 3','Hydrogen 4','Hydrogen 5','Location','bestoutside');

    else
        CreateFile();
    end
    toc
end