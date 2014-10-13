%%
ds = load('C:\secure\Code\arume\Scripts\dsVariability2.mat');

% ds.Properties.VarNames = {'Subject' 'Experiment' 'HeadPosition' 'Repetition' 'SVV' 'SVVth' };

ds =ds.ds;

meanSVV = grpstats(ds,{'Subject','HeadPosition','Experiment'},'mean','DataVars',{'SVV'});

%%
experiments = {'SVVCWCCW' 'SVVLineAdaptFixed'};

    options.nextplot = 'add';
    options.ylim = [-30 30]';
    options.xlim = [0.8 3.2]';
    options.ygrid = 'on';
    options.fontsize = 14;
    options.xtick = 1:3;
    options.ytick = -30:10:30;
    options.xticklabel = [];
    options.yticklabel = [];
    

figure('color','w','position',[100 100 800 500])
for i=1:2
    subplot(2,2,i)
    set(gca,options);
    
    head = 'RED';
    for isubj=1:length(subjects)
        subs = ds(ds.Subject == subjects{isubj} & ds.HeadPosition == head & ds.Experiment == experiments{i} ,:);
        plot(subs.SVV,'o-','MarkerFaceColor','w','color',colors_array(isubj,:),'linewidth',2)
    end
    
    if ( i==1)
        set(gca,'xticklabelmode','auto', 'yticklabelmode','auto');
        xlabel('Repetition');
        ylabel('SVV (deg)');
    end
    
    if ( i==3)
        text(3.5, 0, 'Right ear down','Rotation',-90,'HorizontalAlignment','center','fontsize',14)
    end
end


options.ylim = [-15 15];
options.ytick = -15:5:15;

for i=1:2
    subplot(2,2,2+i)
    set(gca,options);
    head = 'RED';
    for isubj=1:length(subjects)
        subs = ds(ds.Subject == subjects{isubj} & ds.HeadPosition == head & ds.Experiment == experiments{i} ,:);
        plot(subs.SVV-subs.SVV(1),'o-','MarkerFaceColor','w','color',colors_array(isubj,:),'linewidth',2)
    end
    
    if ( i==1)
        set(gca,'xticklabelmode','auto', 'yticklabelmode','auto');
        xlabel('Repetition');
        ylabel('SVV - SVV first rep. (deg)');
    end
    
    if ( i==3)
        text(3.5, 0, 'Right ear down','Rotation',-90,'HorizontalAlignment','center','fontsize',14)
    end
end


%%



figure('color','w','position',[300 400 1000 400])
subplot(1,2,1);
h = plot(dsmean(dsmean.Experiment == 'SVVCWCCW' & dsmean.HeadPosition == 'RED','mean_SVV'),dsmean(dsmean.Experiment == 'SVVLineAdaptFixed' & dsmean.HeadPosition == 'RED','mean_SVV'),'o')
set(h,'markersize',10,'markerfacecolor',[0.7 0.7 0.7], 'color',[0.50 0.50 0.5],'linewidth',2)
set(gca,'xlim',[-25 5],'ylim',[-25 5],'fontsize',18)
line([-25 25],[-25 25],'color',[0.5 0.5 0.5])

subplot(1,2,2);
h = plot(dsmean(dsmean.Experiment == 'SVVCWCCW' & dsmean.HeadPosition == 'RED','std_SVV'),dsmean(dsmean.Experiment == 'SVVLineAdaptFixed' & dsmean.HeadPosition == 'RED','std_SVV'),'o')
set(h,'markersize',10,'markerfacecolor',[0.7 0.7 0.7], 'color',[0.50 0.50 0.5],'linewidth',2)
set(gca,'xlim',[-0 5],'ylim',[-0 5],'fontsize',18)
line([-25 25],[-25 25],'color',[0.5 0.5 0.5])


figure('color','w','position',[300 400 1000 400])
subplot(1,2,1);
h = plot(dsmean(dsmean.Experiment == 'SVVCWCCW' & dsmean.HeadPosition == 'RED','mean_SVV'),dsmean(dsmean.Experiment == 'SVVCWCCWRandom' & dsmean.HeadPosition == 'RED','mean_SVV'),'o')
set(h,'markersize',10,'markerfacecolor',[0.7 0.7 0.7], 'color',[0.50 0.50 0.5],'linewidth',2)
set(gca,'xlim',[-25 5],'ylim',[-25 5],'fontsize',18)
line([-25 25],[-25 25],'color',[0.5 0.5 0.5])

subplot(1,2,2);
h = plot(dsmean(dsmean.Experiment == 'SVVCWCCW' & dsmean.HeadPosition == 'RED','std_SVV'),dsmean(dsmean.Experiment == 'SVVCWCCWRandom' & dsmean.HeadPosition == 'RED','std_SVV'),'o')
set(h,'markersize',10,'markerfacecolor',[0.7 0.7 0.7], 'color',[0.50 0.50 0.5],'linewidth',2)
set(gca,'xlim',[-0 5],'ylim',[-0 5],'fontsize',18)
line([-25 25],[-25 25],'color',[0.5 0.5 0.5])


%%
ds.hyst = ds.SVVfromLeft - ds.SVVfromRight;
dsmean = grpstats(ds,{'Subject','HeadPosition','Experiment'},{'mean' 'std'},'DataVars',{'SVV' 'hyst' 'SVVfromRight' 'SVVfromLeft'});
dsmean1 = grpstats(ds,{'Subject','Experiment'},{'mean' 'std'},'DataVars',{'SVV' 'hyst' 'SVVfromRight' 'SVVfromLeft'});
dsmean2 = grpstats(ds,{'Experiment'},{'mean' 'sem'},'DataVars',{'SVV' 'hyst' 'SVVfromRight'  'SVVfromLeft'});

figure
h = errorbar(dsmean2.mean_hyst([1 3]),dsmean2.sem_hyst([1 3]),'o');

set(h,'markersize',10,'markerfacecolor',[0.7 0.7 0.7], 'color',[0.50 0.50 0.5],'linewidth',2);

set(gca,'xtick',[1 2],'xticklabel',{'Sequential', 'Adaptive'},'fontsize',18)
ylabel({'Difference in SVV ' 'from left - from right (deg)'})

line(get(gca,'xlim'),[0 0],'color','k')

