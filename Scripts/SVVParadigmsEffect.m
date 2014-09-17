%%
warning('off','stats:glmfit:PerfectSeparation')
warning('off','stats:glmfit:IterationLimit')

arume = Arume;

subjects = {'BM' 'SI' 'LN'};
sessions = {'A' 'B'};
headPositions = {'upright' 'RED'};
repeatitions = [1 2 3 4 5];

% 
% subjects = { 'EI' 'UM'};
% sessions = {'A' 'B' 'C'};
% headPositions = {'RED'};
% repeatitions = [3];


Subject = {};
Experiment = {};
HeadPosition = {};
Repetition = [];
SVV = [];
SVVTrialToTrialVariability = [];
SVVVariability= [];
SVVth = [];
Offset = [];

n=0;
for isubj=1:length(subjects)
    for isess = 1:length(sessions)
        for ihead = 1:length(headPositions)
            for i=repeatitions
                % build the session name
                sessionName = [sessions{isess} headPositions{ihead} num2str(i)];
                
                % find the session data
                session = arume.currentProject.findSession(subjects{isubj},sessionName);
                disp(session.name)
                
                % get the angles presented
                angles = session.experiment.GetAngles();
                
                % get the responses (tilt left or tilt right)
                responses = session.experiment.GetLeftRightResponses();
                responses(responses==2) = 0;
                
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
                Offset(n) = session.experiment.ExperimentOptions.offset;
                
%                 
%                 switch(session.experiment.Name)
%                     case 'SVVCWCCWRandom'
%                         SVVtime = zeros(1,16);
%                         for i=1:16
%                             idx = (1:18)+18*(i-1);
%                             [SVV1, a, p, allAngles, allResponses,trialCounts, SVVth1] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( angles(idx), responses(idx));
%                             SVVtime(i) = SVV1;
%                         end
%                         SVVTrialToTrialVariability(n) = mean(abs(diff(SVVtime)));
%                         SVVVariability(n) = std(SVVtime);
%                     case 'SVVCWCCW'
%                         SVVtime = zeros(1,16);
%                         for i=1:16
%                             idx = (1:17)+17*(i-1);
%                             [SVV1, a, p, allAngles, allResponses,trialCounts, SVVth1] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( angles(idx), responses(idx));
%                             SVVtime(i) = SVV1;
%                         end
%                         SVVTrialToTrialVariability(n) = mean(abs(diff(SVVtime)));
%                         SVVVariability(n) = std(SVVtime);
%                     case 'SVVLineAdaptFixed'
%                         SVVtime = zeros(1,5);
%                         for i=6:10
%                             idx = (1:10)+10*(i-1);
%                             [SVV1, a, p, allAngles, allResponses,trialCounts, SVVth1] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( angles(idx), responses(idx));
%                             SVVtime(i-5) = SVV1;
%                         end
%                         SVVTrialToTrialVariability(n) = mean(abs(diff(SVVtime)));
%                         SVVVariability(n) = std(SVVtime);
%                 end
            end
        end
    end
end

% build the dataset
% ds = dataset(Subject', Experiment', HeadPosition', Repetition', SVV', SVVth', SVVTrialToTrialVariability', SVVVariability');
% ds.Properties.VarNames = {'Subject' 'Experiment' 'HeadPosition' 'Repetition' 'SVV' 'SVVth' 'SVVTrialToTrialVariability' 'SVVVariability'};
ds = dataset(Subject', Experiment', HeadPosition', Repetition', SVV', SVVth', Offset');
ds.Properties.VarNames = {'Subject' 'Experiment' 'HeadPosition' 'Repetition' 'SVV' 'SVVth' 'Offset'};
ds.Subject = nominal(ds.Subject,  unique(ds.Subject));
ds.HeadPosition = nominal(ds.HeadPosition,  unique(ds.HeadPosition));
ds.Experiment = nominal(ds.Experiment,  unique(ds.Experiment));
return

%%

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

subjects = {'BM' 'SI' 'LN'};
sessions = {'A' 'B'};
headPositions = {'upright' 'RED'};
repeatitions = [1 2 3 4 5];
experiments = {'SVVCWCCW' 'SVVLineAdaptFixed'};

figure('color','white')
n=0;
for ihead = 1:2
    for iexp=1:2
        n = n+1;
        subplot(2,2,n,'nextplot','add');
        title([experiments{iexp} ' - ' headPositions{ihead}]);
        dsOffsetRight = ds( ds.Experiment == experiments{iexp} & ds.HeadPosition == headPositions{ihead} & ds.Offset > 0, {'Subject', 'SVV'});
        dsOffsetLeft = ds( ds.Experiment == experiments{iexp} & ds.HeadPosition == headPositions{ihead} & ds.Offset < 0,  {'Subject', 'SVV'});
        dsNoOffset = ds( ds.Experiment == experiments{iexp} & ds.HeadPosition == headPositions{ihead} & ds.Offset == 0,  {'Subject', 'SVV'});
        
        % normalize each subject
        SVV = zeros(length(subjects),3);
        for isubj=1:length(subjects)
            SVV(isubj,1) = mean(dsOffsetLeft.SVV(dsOffsetLeft.Subject==subjects{isubj}));
            SVV(isubj,2) = mean(dsNoOffset.SVV(dsNoOffset.Subject==subjects{isubj}));
            SVV(isubj,3) = mean(dsOffsetRight.SVV(dsOffsetRight.Subject==subjects{isubj}));
        end
        
        set(gca,'xlim',[0 4])
        plot(SVV','markersize',5,'marker','o','MarkerFaceColor','w');
        
        set(gca,'xtick',1:3,'xticklabel',{'Offset left', 'No offset', 'Offset right'});
        
        ylabel('SVV (normalized,deg)')
    end
end

%%
figure('color','white')
n=0;

for ihead = 1:2
    for iexp=1:2
        n = n+1;
        subplot(2,2,n,'nextplot','add');
        title([experiments{iexp} ' - ' headPositions{ihead}]);
        dsOffsetRight = ds( ds.Experiment == experiments{iexp} & ds.HeadPosition == headPositions{ihead} & ds.Offset > 0, {'Subject', 'SVV'});
        dsOffsetLeft = ds( ds.Experiment == experiments{iexp} & ds.HeadPosition == headPositions{ihead} & ds.Offset < 0,  {'Subject', 'SVV'});
        dsNoOffset = ds( ds.Experiment == experiments{iexp} & ds.HeadPosition == headPositions{ihead} & ds.Offset == 0,  {'Subject', 'SVV'});
        
        % normalize each subject
        for isubj=1:length(subjects)
            dsOffsetRight.SVV(dsOffsetRight.Subject==subjects{isubj}) = dsOffsetRight.SVV(dsOffsetRight.Subject==subjects{isubj}) - mean(dsNoOffset.SVV(dsNoOffset.Subject==subjects{isubj}));
            dsOffsetLeft.SVV(dsOffsetLeft.Subject==subjects{isubj}) = dsOffsetLeft.SVV(dsOffsetLeft.Subject==subjects{isubj}) - mean(dsNoOffset.SVV(dsNoOffset.Subject==subjects{isubj}));
            dsNoOffset.SVV(dsNoOffset.Subject==subjects{isubj}) = dsNoOffset.SVV(dsNoOffset.Subject==subjects{isubj}) - mean(dsNoOffset.SVV(dsNoOffset.Subject==subjects{isubj}));
        end
        
        SVV = zeros(3,1);
        SVVstd = zeros(3,1);
        
        [SVV(1) SVVstd(1)] = Means(dsOffsetLeft.SVV);
        [SVV(2) SVVstd(2)] = Means(dsNoOffset.SVV);
        [SVV(3) SVVstd(3)] = Means(dsOffsetRight.SVV);
        set(gca,'xlim',[0 4],'ylim',[-5 5])
        errorbar(SVV, SVVstd,'linewidth',2);
        plot(SVV,'markersize',5,'marker','o','MarkerFaceColor','w');
        
        set(gca,'xtick',1:3,'xticklabel',{'Offset left', 'No offset', 'Offset right'});
        
        ylabel('SVV (normalized,deg)')
    end
end
    

