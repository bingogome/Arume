%%
COLORS.MEDIUM_BLUE		= [.1 .5 .8];
COLORS.MEDIUM_RED		= [.9 .2 .2];
COLORS.MEDIUM_GREEN		= [.5 .8 .3];
COLORS.MEDIUM_GOLD      = [.9 .7 .1];
COLORS.MEDIUM_PURPLE	= [.7 .4 .9];
COLORS.MEDIUM_PINK		= [1 0.5 0.8];
COLORS.MEDIUM_BLUE_GREEN= [.1 .8 .7];
COLORS.MEDIUM_ORANGE	= [1 .6 .15];
COLORS.LIGHT_BLUE		= [.1 .5 .8];
COLORS.LIGHT_RED		= [1 .75 .75];
COLORS.LIGHT_GREEN		= [.5 .8 .3];
COLORS.LIGHT_ORANGE     = [.9 .7 .1];
COLORS.DARK_GREEN		= [.0 .6 .3];
COLORS.WHITE			= [1 1 1];
COLORS.DARK_BLUE        = [0 20/255 80/255];
COLORS.DARK_RED         = [130 10 0]/255;
COLORS.MEDIUM_BROWN        = [155 102 50]/255;
COLORS.GREY = [.5 .5 .5];
COLORS.DARK_BROWN = [0.3961 0.2627 0.1294];
COLORS.LIGHT_BROWN = [0.9608 0.8706 0.7020];
COLORS.LIGHT_PINK = [1 0.8000 0.9000];
COLORS.MAGENTA = [1 0 1];
COLORS.DEEP_SKY_BLUE = [0 0.6039 0.8039];
COLORS.DARK_KHAKI = [0.8039 0.7765 0.4510];
COLORS.MEDIUM_KHAKI= [0.9333 0.9020 0.5216];
COLORS.ROYAL_BLUE = [0.2549 0.4118 0.8824];
COLORS.SALMON = [0.7765 0.4431 0.4431];
            
fields = fieldnames(COLORS);
for i=1:length(fields)
	colors_array(i,:) = COLORS.(fields{i});
end

%%
arume = Arume;

subjects = {'BL' 'KP' 'BX' 'BM' 'EI' 'UM'};
sessions = {'A' 'B' 'C'};
headPositions = {'upright' 'RED'};
repeatitions = [1 2 3];

Subject = {};
Experiment = {};
HeadPosition = {};
Repetition = [];
SVV = [];
SVVth = [];

n=0;
for isubj=1:length(subjects)
    for isess = 1:length(sessions)
        for ihead = 1:length(headPositions)
            for i=repeatitions
                % build the session name
                sessionName = [sessions{isess} headPositions{ihead} num2str(i)];
                % find the session data
                session = arume.currentProject.findSession(subjects{isubj},sessionName);
                
                % get the angles presented
                angles = session.experiment.GetAngles();
                
                % get the responses (tilt left or tilt right)
                responses = session.experiment.GetLeftRightResponses();
                
                % remove aborts
                angles(responses<0 | responses>1 ) = [];
                responses(responses<0 | responses>1) = [];

                % fit the responses to get the SVV
                [SVV1, a, p, allAngles, allResponses,trialCounts, SVVth1] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( angles, responses);
                
                % collect all the SVVs
                n=n+1;
                Subject{n} = subjects{isubj};
                Experiment{n} = session.experiment.Name;
                HeadPosition{n} = headPositions{ihead};
                Repetition(n) = i;
                
                SVV(n) = SVV1;
                SVVth(n) = SVVth1;
            end
        end
    end
end

% build the dataset
ds = dataset(Subject', Experiment', HeadPosition', Repetition', SVV', SVVth');
ds.Properties.VarNames = {'Subject' 'Experiment' 'HeadPosition' 'Repetition' 'SVV' 'SVVth'};
ds.Subject = nominal(ds.Subject,  unique(ds.Subject));
ds.HeadPosition = nominal(ds.HeadPosition,  unique(ds.HeadPosition));
ds.Experiment = nominal(ds.Experiment,  unique(ds.Experiment));

%% SVV PLOTS
experiments = {'SVVCWCCW' 'SVVCWCCWRandom' 'SVVLineAdaptFixed'};

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
for i=1:3
    
    subplot(2,3,i);
    set(gca,options);
    
    head = 'upright';
    for isubj=1:length(subjects)
        subs = ds(ds.Subject == subjects{isubj} & ds.HeadPosition == head & ds.Experiment == experiments{i} ,:);
        plot(subs.SVV,'o-','MarkerFaceColor','w','color',colors_array(isubj,:),'linewidth',2)
    end
    title(experiments{i})
    
    if ( i==3)
        text(3.5, 0, 'Upright','Rotation',-90,'HorizontalAlignment','center','fontsize',14)
    end
    
    
    subplot(2,3,3+i)
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

figure('color','w','position',[100 100 800 500])
for i=1:3
    subplot(2,3,i);
    set(gca,options);
    
    head = 'upright';
    for isubj=1:length(subjects)
        subs = ds(ds.Subject == subjects{isubj} & ds.HeadPosition == head & ds.Experiment == experiments{i} ,:);
        plot(subs.SVV-subs.SVV(1),'o-','MarkerFaceColor','w','color',colors_array(isubj,:),'linewidth',2)
    end
    title(experiments{i})
    
    if ( i==3)
        text(3.5, 0, 'Upright','Rotation',-90,'HorizontalAlignment','center','fontsize',14)
    end
    
    subplot(2,3,3+i)
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
 

%% SLOPE PLOTS
experiments = {'SVVCWCCW' 'SVVCWCCWRandom' 'SVVLineAdaptFixed'};

    options.nextplot = 'add';
    options.ylim = [0 10]';
    options.xlim = [0.8 3.2]';
    options.ygrid = 'on';
    options.fontsize = 14;
    options.xtick = 1:3;
    options.ytick = -10:2:10;
    options.xticklabel = [];
    options.yticklabel = [];
    

figure('color','w','position',[100 100 800 500])
for i=1:3
    
    subplot(2,3,i);
    set(gca,options);
    
    head = 'upright';
    for isubj=1:length(subjects)
        subs = ds(ds.Subject == subjects{isubj} & ds.HeadPosition == head & ds.Experiment == experiments{i} ,:);
        plot(subs.SVVth,'o-','MarkerFaceColor','w','color',colors_array(isubj,:),'linewidth',2)
    end
    title(experiments{i})
    
    if ( i==3)
        text(3.5, 0, 'Upright','Rotation',-90,'HorizontalAlignment','center','fontsize',14)
    end
    
    
    subplot(2,3,3+i)
    set(gca,options);
    
    head = 'RED';
    for isubj=1:length(subjects)
        subs = ds(ds.Subject == subjects{isubj} & ds.HeadPosition == head & ds.Experiment == experiments{i} ,:);
        plot(subs.SVVth,'o-','MarkerFaceColor','w','color',colors_array(isubj,:),'linewidth',2)
    end
    
    if ( i==1)
        set(gca,'xticklabelmode','auto', 'yticklabelmode','auto');
        xlabel('Repetition');
        ylabel('SVV slope (deg)');
    end
    
    if ( i==3)
        text(3.5, 0, 'Right ear down','Rotation',-90,'HorizontalAlignment','center','fontsize',14)
    end
end


options.ylim = [-5 5];
options.ytick = -5:1:5;

figure('color','w','position',[100 100 800 500])
for i=1:3
    subplot(2,3,i);
    set(gca,options);
    
    head = 'upright';
    for isubj=1:length(subjects)
        subs = ds(ds.Subject == subjects{isubj} & ds.HeadPosition == head & ds.Experiment == experiments{i} ,:);
        plot(subs.SVVth-subs.SVVth(1),'o-','MarkerFaceColor','w','color',colors_array(isubj,:),'linewidth',2)
    end
    title(experiments{i})
    
    if ( i==3)
        text(3.5, 0, 'Upright','Rotation',-90,'HorizontalAlignment','center','fontsize',14)
    end
    
    subplot(2,3,3+i)
    set(gca,options);
    head = 'RED';
    for isubj=1:length(subjects)
        subs = ds(ds.Subject == subjects{isubj} & ds.HeadPosition == head & ds.Experiment == experiments{i} ,:);
        plot(subs.SVVth-subs.SVVth(1),'o-','MarkerFaceColor','w','color',colors_array(isubj,:),'linewidth',2)
    end
    
    if ( i==1)
        set(gca,'xticklabelmode','auto', 'yticklabelmode','auto');
        xlabel('Repetition');
        ylabel('SVV slope - SVV slope first rep. (deg)');
    end
    
    if ( i==3)
        text(3.5, 0, 'Right ear down','Rotation',-90,'HorizontalAlignment','center','fontsize',14)
    end
end