function PlotInfo(a1,a2,a3,p1,p2,p3,p4,p5,p6,p7,p8,p9,data,zoomCheckbox, numVar)
%     global fileID_today;
%     data_today = dlmread(strcat('Logs\AnnealData_',datestr(datetime('today')),'.txt'), '\t', 2,1);
%     data_yesterday = dlmread(strcat('Logs\AnnealData_',datestr(datetime('yesterday')),'.txt'), '\t', 2,1);
%     data = [data_yesterday; data_today];
%     data = [data_today; data_today];

tic
    x = data(1:60:end,numVar);
%% Temperature Plot
    
    y1 = data(1:60:end,2);
    y2 = data(1:60:end,3);
    y3 = data(1:60:end,4);
    
    p1 = animatedline(x,y1);
    p1.Parent = a1; 
    p1.Color = 'r';
    hold(a1,'on');
    
    p2 = animatedline(x,y2);
    p2.Parent = a1;
    p2.Color = 'b';
    hold(a1,'on');
    
    p3 = animatedline(x,y3);
    p3.Parent = a1;
    hold(a1,'on');

    a1.XLimMode = 'manual';

    if (get(zoomCheckbox,'Value') == get(zoomCheckbox,'Max'))
        xData = linspace(now-.04,now,24);
    else
        xData = linspace(now-1,now,24);
    end

    a1.XTick = xData;
    datetick(a1,'x','HH:MM','keepticks');

    a1.Title.String = 'Furnace Temperature';
    a1.XLabel.String ='Time';
    a1.YLabel.String = 'Temperature (Degrees Fahrenheit)';
    hold(a1,'on');

    legend(a1,'Temperature','Setpoint', 'Duty Cycle','Location','bestoutside');
%% Hydrogen Sensor Plot    
%         plot(a2,data(:, numVar),data(:,5),'b');
%         plot(a2,data(:, numVar),data(:,6),'r');
%         plot(a2,data(:, numVar),data(:,7),'g');
%         plot(a2,data(:, numVar),data(:,8),'m');
%         plot(a2,data(:, numVar),data(:,9),'c');
%           
%         if (get(zoomCheckbox,'Value') == get(zoomCheckbox,'Max'))
%             a2.XLim = [now-.04 now];
%         else
%             a2.XLim = [now-1 now];
%         end

    y4 = data(1:60:end,5);
    y5 = data(1:60:end,6);
    y6 = data(1:60:end,7);
    y7 = data(1:60:end,8);
    y8 = data(1:60:end,9);
    
    p4 = plot(a2,x,y4);
    hold(a2,'on');
    p5 = plot(a2,x,y5);
    hold(a2,'on');
    p6 = plot(a2,x,y6);
    hold(a2,'on');
    p7 = plot(a2,x,y7);
    hold(a2,'on');
    p8 = plot(a2,x,y8);
    hold(a2,'on');

    a2.XLimMode = 'manual';
    
    a2.XTick = xData;
    datetick(a2,'x','HH:MM','keepticks');
        
    a2.Title.String = 'Hydrogen Levels';
    a2.XLabel.String ='Time';
    a2.YLabel.String = 'Hydrogen Level';
    hold(a2,'on');
    
    legend(a2,'Hydrogen 1','Hydrogen 2','Hydrogen 3','Hydrogen 4','Hydrogen 5','Location','bestoutside');

%% Pressure Plot
%         plot(a3,data(1:60:end, numVar),data(1:60:end,1));
%         
%         if (get(zoomCheckbox,'Value') == get(zoomCheckbox,'Max'))
%             a3.XLim = [now-.04 now];
%         else
%             a3.XLim = [now-1 now];
%         end     
         
    y9 = data(1:60:end,10);
    
    p9 = plot(a3,x,y9);
    hold(a3,'on') 

    a3.XLimMode = 'manual';
    
    a3.XTick = xData;
    datetick(a3,'x','HH:MM','keepticks');
    
    a3.Title.String = 'Vacuum Pump Pressure';
    a3.XLabel.String ='Time';
    a3.YLabel.String = 'Pressure (Torr)';
    hold(a3,'on');
    
    legend(a3,'Pressure (Torr)','Location','bestoutside');
%% 
% else
%         CreateFile();
%     end
% end
toc