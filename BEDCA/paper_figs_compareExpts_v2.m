function paper_figs_compareExpts_v2(exptnums,runtreatment,server,options)
% paper_figs_compareExpts_v2(exptnums,runtreatment,server,options)
%
% This plots the posteriors across different experiments (flourophores) for a given treatment
%
% Give  experiment numbers from ExpData_List 
% eg  paper_figs_compareExpt({5,6},'DMSO',[],[])
%
% Give treatment to plot from 'DMSO','taxol' or 'Nocod'
%
% server offers option of using Ceres. Leave as [] to use local directories/files
% server = 'McAinshLabindiv' or server= 'McAinshLabpool'
%
% options to control plot
% options.boxs options.linewidth options.xmax (maximum of x in plot,
% default 150, also allows options.xmax='auto' for autoscaling)
% options.xlim = [xlow xhigh] is passed to xlim
% options.legend == 0 turns off legends. On by default.
% options.raw ==1 also plot 3D data
    %
% This plots figures for paper and saves in Figures in Expt directory as PFig_CompareExptsPost
%
  % Related paper_figs, paper_figs_compare (across treatments)
% NJB June 2019

% set renderer
set(0,'DefaultFigureRendererMode','manual')
set(0,'DefaultFigureRenderer','OpenGl')
  
% plot defaults
  plotraw=0;
  unts={'nm','rad','rad'}; % Assumed original data is in microns

fontsize=20;
linewidth=2;
boxs=25;
if ~isempty(options)
if isfield(options,'boxs')
boxs=options.boxs;
end
if isfield(options,'linewidth')
linewidth=options.linewidth;
end
end

% Load Expt list

% From EuclDist_Driver
ExptData_list

if exist('MCMCruns','dir')==7
RunDIR='MCMCruns'; % Different NJB '../MCMCruns', Emanuele 'MCMCruns'
else
RunDIR='../MCMCruns';
end

FigDIR='Figures';

if ~isempty(server)
    switch server
        case {'McAinshLabindiv','Ceresindiv'}
            RunDIR=McAinshLabDIR;
            case {'McAinshLabpool','Cerespool','McAinshLabpooled','Cerespooled'}
            RunDIR=McAinshLabDIRpooled;
        otherwise
            disp('Problem with server name:ABORTING')
            return;
    end
end
            
algstr='EDC';


%
% Run over experiments
%

H=figure;
hold on;
y=[0 1]; % range
cnt=1;
col={'k','r','b','g','m','c'};

for k=1:length(exptnums)
	exptnum=exptnums{k};
	dataid={exptnum,runtreatment};  % First is id below in FileNames{}, Second category is 'tax'/'tax15min', 'noc'/'noc2hr', 'DMSO'/'untreated', 'all'(Not done yet).  Load extra categories associated with new treatments in loadDistData.m

brkstr=max(strfind(FileNames{dataid{1}},'/'));
if ~isempty(brkstr) & brkstr(end)==length(FileNames{dataid{1}})
  brkstr(end)=[];
end

if ~isempty(brkstr)
FileNameSh=[FileNames{dataid{1}}((brkstr(end)+1):(end-4)) '_' algstr]; % Creates a Short file name (Last Part Of FileName), removing .mat
 else
   FileNameSh=[FileNames{dataid{1}}(1:(end-4)) '_' algstr];
end
     
% Build treatment name
treatnam=gettreatname(runtreatment,TreatmentLib);

if isempty(treatnam)
disp(['Failed to find treatment ' runtreatment ' in TreatmentLib']);
disp('Check name against TreatmentLib in ExptData_List');
disp('ABORTING');
return;
end

ExptDat=ExptDats{dataid{1}};
%disp(['Loading Expt ' FileNames{dataid{1}}]);
%disp(['under treatment ' treatnam]);


%						      
% Saving directory for mcmcruns
%
SAVDIR=['Expt_' FileNameSh '_' treatnam '/'];
SAVDIR=[RunDIR '/' SAVDIR];

disp(['Loading rundata for ' SAVDIR]);

load([SAVDIR 'MCMCStats_chain1.mat']);      % Load stats of first chain
load([SAVDIR 'MCMC_EuclDistMargoutput1.mat']); % Load first chain 

paramnams=mcmcparams.variables;
truevalues=mcmcparams.truevalues;
burnin=mcmcparams.burnin;
mcmcrun=mcmcrun(burnin:end,:); % Delete burnin
dat=mcmcparams.datafile;

%
% Plot data and estimated mu
%

% mu posterior
j=1;
[h x]=hist(mcmcrun(:,j),boxs);
plot(x,h/max(h),col{k},'LineWidth',linewidth);
str{cnt}=ExptDats{exptnums{k}}.name;cnt=cnt+1;

% Plot means

plot(tab.means(1)*[1 1],y,[col{k} ':'],'LineWidth',linewidth); % 
str{cnt}='Mean';
cnt=cnt+1;

if ~isempty(options)  && isfield(options,'raw') &&  options.raw==1
  plotraw=1;
if isfield(options,'zfilter') && options.zfilter==0 
  J=1:size(dat,1);
str{cnt}='Expt 3D';cnt=cnt+1;
else
    J=find(dat(:,6));
str{cnt}='Expt 3D (filtered)';cnt=cnt+1;
end
[h x]=hist(dat(J,1),boxs);
%[h x]=hist(dat(:,1),boxs);
plot(x,h/max(h),[col{k} '--'],'LineWidth',linewidth); % 3D raw data

plot(mean(dat(J,1))*[1 1],y,[col{k} '-.'],'LineWidth',linewidth);
str{cnt}='Mean data';cnt=cnt+1;
% Stats
y=ylim;
%plot(median(dat(J,1))*[1 1],y,'c--');
end

if k==1
SAVDIR1=SAVDIR;
end

end % k

if isempty(options) || ~isfield(options,'legend') || options.legend==1
  legend(str);
end

if plotraw
title('3D measurements and \Delta_{EC} across Expts','FontSize',fontsize)
 else
   title('\Delta_{EC} across Expts','FontSize',fontsize)
     end

xlabel('3D distance','FontSize',fontsize)
set(gca,'FontSize',fontsize);
if ~isempty(options) && isfield(options,'xmax')
    if strcmp(options.xmax,'auto')==0
    xlim([0 options.xmax]);
    end
end

if ~isempty(options) && isfield(options,'xlim')
xlim(options.xlim);
end

if ~isempty(SAVDIR)
  saveas(gcf,[SAVDIR1 'Figures/PFig_CompareExptsPost.fig'],'fig');
  print('-depsc',[SAVDIR1 'Figures/PFig_CompareExptsPost.eps']);
  print('-painters','-dsvg',[SAVDIR1 'Figures/PFig_CompareExptsPost.svg']);
  print('-painters','-dpdf',[SAVDIR1 'Figures/PFig_CompareExptsPost.pdf']);
end


return;
% PLot sd in xy/z

figure;hold on;

% taux posterior
j=2;
[h x]=hist(1./sqrt(mcmcrun(:,j)),boxs);
plot(x,h/(max(h)*(x(2)-x(1))),'r','LineWidth',linewidth);
hm=max(h);

j=3;
[h x]=hist(1./sqrt(mcmcrun(:,j)),boxs);
     plot(x,h/(max(h)*(x(2)-x(1))),'b','LineWidth',linewidth);

y=ylim();
% Plot means
plot(tab.means(4)*[1 1],y,'r:','LineWidth',linewidth);
plot(tab.means(5)*[1 1],y,'b:','LineWidth',linewidth);

if isempty(options) || ~isfield(options,'legend') || options.legend==1
legend('sd_x','sd_z','mean sdxy','mean sdz');
end

title('Spot centre accuracy','FontSize',fontsize)
xlabel('standard deviation, nm','FontSize',fontsize)
set(gca,'FontSize',fontsize);

if ~isempty(SAVDIR)
  saveas(gcf,[SAVDIR 'Figures/PFig_SpotAccPostEsts.fig'],'fig');
print('-depsc',[SAVDIR 'Figures/PFig_SpotAccPostEsts.eps']);
print('-painters','-dsvg',[SAVDIR 'Figures/PFig_SpotAccPostEsts.svg']);
print('-painters','-dpdf',[SAVDIR 'Figures/PFig_SpotAccPostEsts.pdf']);
end
