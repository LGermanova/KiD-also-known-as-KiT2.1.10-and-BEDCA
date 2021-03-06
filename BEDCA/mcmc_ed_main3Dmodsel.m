function [mcmcparams, mcmcrun, mcmcruntheta, mcmcrunphi]=mcmc_ed_main3Dmodesel(X,algparams)
% [mcmcparams, mcmcrun, mcmcruntheta]=mcmc_ed_main3Dmodsel(X,algparams)
  %
  % This is an MCMC algorithm for 3D inflation removal from Euclidean distance measurements. Uses a marginalised form, integrating over phi_i. Uses RW proposals for mu, taux in these parameter directions (cf twisting in mcmc_ed_main3Dmarg) with a mixed prior on mu with weight at mu=0
  %
  % Data X is matrix of (d,theta_X) (3d spherical coordinates r theta), N x 2
  %
  % Parameters mu, sigx, sigz
  % Angular distribution assumed uniform
  %
  % algparams.n Number steps
  % algparams.init Initial conditions mu sigmax sigmax
  % algparams.SAVDIR  Save runs to file periodically
  % algparams.priors Priors on mu and sigmax, sigmaz
  % alparams.bloks Number blocks to use during burnin to calculate covariance
%
    % Returns mcmcrun with variable samples and mcmcruntheta the theta samples
    %
    % Related mcmc_ed_main3Dmarg
  % NJB May 2017

% algorithm params
dtheta=0.75;
%rwphi=0.025; % Walk size
maxphi=0.5;
minphi=0.0125; % Min and max allowed sd of phi proposal
sampcnt=0;

EXPANDF=1.4;
SHRINKF=0.61;


%
disp('MCMC for anisotropic inflation model. marginal Li. v1 NJB2017');
disp(['Steps ' num2str(algparams.n)]);

% switch variable on/off for debugging
muon=0;
tauxon=1;
tauzon=1;
%phion=1;
thetaon=1;

if sum([muon tauzon thetaon])<4
if muon disp('mu/taux is ON **'); else disp('mu is OFF'); end
if tauxon disp('taux is ON **'); else disp('taux is OFF'); end
if tauzon disp('tauz is ON **'); else disp('tauz is OFF'); end
%if phion disp('phi_i is ON **'); else disp('phi_i is OFF'); end
if thetaon disp('theta_i is ON **'); else disp('theta_i is OFF'); end
end

%
% Set up algorithm MC
%
N=size(X,1);halfN=N/2; % Number data points
n=algparams.n; % MCMC steps
subsample=algparams.subsample;

disp(['data set size ' num2str(N)]);

% Priors
[params typ]=get_priorparams(algparams.priors,'mu');
mu0=params(1);mupp=1/params(2);  % mean and precision
[params typ]=get_priorparams(algparams.priors,'taux');
ataux=params(1);ktaux=params(2);
[params typ]=get_priorparams(algparams.priors,'tauz');
atauz=params(1);ktauz=params(2);

% Mixed prior on mu
%wtmuzero=algparams.modpriors(1);
%wtmunonzero=1-wtmuzero;

% MCM variables
thetai=zeros(1,N);phi=zeros(1,N);

% Data
rX=X(:,1)';     % Radial coord
thetaX=X(:,2)'; % Theta angle

% Summary stats
rpxy=rX.*sin(thetaX); % Projected to xy (positive)
rpz=rX.*cos(thetaX);  % Projected to z (which can be negative)

sumSqrpxy=sum(rpxy.^2);
sumSqrpz=sum(rpz.^2);

% Initialise MC from given initialisation
mu=algparams.init(1);
sigx=algparams.init(2);taux=1/sigx^2;
sigz=algparams.init(3);tauz=1/sigz^2;
thetai=algparams.initthetas';
%phi=algparams.initphis';

if (0==1) % initialisation done in mcmc_ed
% Initialise MCMC. 'True', 'Priors' draw from prior. 'OverDispersed'
switch algparams.initialise
case 'True'

case 'Randomise'

otherwise
disp('Something has gone wrong in initialisation of MC: ABORT');
return;
end
end

% Create accessory variables of mcmc hidden variables 
si=sin(thetai);
ci=cos(thetai);
cphi=cos(phi);
muind=1;        % Index for mu state. =1 mu is nonzero

% Save initial conditions
savcnt=1;
mcmcrun=zeros(floor(n/subsample),3);
mcmcruntheta=zeros(floor(n/subsample),N);

mcmcrun(savcnt,:)=[mu, taux, tauz];
mcmcruntheta(savcnt,:)=thetai;  %  Angular variables thetai
%mcmcrunphi(savcnt,:)=phi;       %  Angular variables phi

% Set up burnin and blocks for rw (tuning)
C=eye(2);
burnin=algparams.burnin;
bloks=algparams.bloks;
nblok=floor((burnin-1)/bloks)*ones(bloks,1);
nblok=[0; nblok; algparams.n-sum(nblok)];
nblok=cumsum(nblok);
rwstats.blocks=nblok;

prdmutau=zeros(burnin,1);
musq=zeros(burnin,1);
tauxsq=zeros(burnin,1);
mus=zeros(burnin,1);
tauxs=zeros(burnin,1);

% Directions are mu, taux
V=[1 0; 0 1]; % First diection is mu
w=[2.5 0.1/50^2];

% Alg stats
muf=0;
acceg=[0 0];

for bk=2:length(nblok)
  for k=(nblok(bk-1)+1):nblok(bk) % main loop with k steps

% Update mu. Normal.
if muon 
		% random walk. (mu tau)^\prime = (mu tau)+ N(0,si) vi

		pd(1)=mu+normrnd(0,w(1)); % Proposed position
		pd(2)=taux;

if pd(1)>0  % Ratio of likelihoods. Involves Bessel functions
			bpar=rpxy.*si;
                        bparp=pd(1)*pd(2)*bpar;bpar=mu*taux*bpar;
                        Iprod=prod(besseli(0,bparp,1)./besseli(0,bpar,1));
a=-ktaux*(pd(2)-taux)-0.5*((pd(1)-mu0)^2-(mu-mu0)^2)*mupp+sum(bparp-bpar)-0.5*pd(2)*(sum((pd(1)*si).^2)+sumSqrpxy)+0.5*taux*(sum((mu*si).^2)+sumSqrpxy)-0.5*tauz*(pd(1)-mu)*sum(ci.*((pd(1)+mu)*ci-2*rpz)); 
a=exp(a)*(pd(2)/taux)^(N+ataux-1)*Iprod;

if a>1 | a>rand()
mu=pd(1);%taux=pd(2);
acceg(1)=acceg(1)+1;
end

end		
end % muon


if tauxon 
		% random walk. (mu tau)^\prime = (mu tau)+ N(0,si) vi

		pd(1)=mu; % Proposed position
		pd(2)=taux+normrnd(0,w(2));
		if pd(2)>0  % Ratio of likelihoods. Involves Bessel functions
			bpar=rpxy.*si;
                        bparp=pd(1)*pd(2)*bpar;bpar=mu*taux*bpar;
                        Iprod=prod(besseli(0,bparp,1)./besseli(0,bpar,1));
a=-ktaux*(pd(2)-taux)-0.5*((pd(1)-mu0)^2-(mu-mu0)^2)*mupp+sum(bparp-bpar)-0.5*pd(2)*(sum((pd(1)*si).^2)+sumSqrpxy)+0.5*taux*(sum((mu*si).^2)+sumSqrpxy)-0.5*tauz*(pd(1)-mu)*sum(ci.*((pd(1)+mu)*ci-2*rpz)); 
a=exp(a)*(pd(2)/taux)^(N+ataux-1)*Iprod;

if a>1 | a>rand()
%mu=pd(1);
taux=pd(2);
acceg(2)=acceg(2)+1;
end

end
end


% Update sigz Gamma
if tauzon
   tauz=gamrnd(atauz+halfN-1.5,1/(ktauz+0.5*sum((mu*ci-rpz).^2)));
end

%
%
% Update theta_i. A random walk (untuned)
%
if thetaon 

%thetap=thetaX+normrnd(0,1./sqrt(rpxy*taux+rpz*tauz));
%thetap=thetap-2*pi*round(thetap/(2*pi)); % Places in (-pi,pi)

thetap=thetai+normrnd(0,dtheta*ones(1,N)); % random walk
sip=sin(thetap);
cip=cos(thetap);

alpha=sin(thetap)./sin(thetai);
alpha=alpha.*besseli(0,mu*taux*rpxy.*sip)./besseli(0,mu*taux*rpxy.*si);
alpha=alpha.*exp(-0.5*(taux*mu^2*(sip.^2-si.^2)+tauz*((mu*cip-rpz).^2-(mu*ci-rpz).^2)));

if sum(~isreal(thetap)) >0
taux, tauz
  figure; hold on
  plot(rpxy*taux+rpz*tauz)
    disp(['Count <= 0 =' num2str(sum(rpxy*taux+rpz*tauz<0))])
  return;
end

%size(thetap),size(rpxy.*cphi),size(thetai)
%figure;hist(thetap-thetai,100);xlabel('dtheta')
%figure;hist((mu*sip-rpxy.*cphi).^2-(mu*si-rpxy.*cphi).^2,100);
%figure;
%[Y I]=sort(alpha);
%plot(alpha(I));
%[min(alpha), max(alpha)]

J=thetap>0 & alpha>rand(1,N);  % Reject if negative.
if ~isempty(J)
thetai(J)=thetap(J);
ci(J)=cip(J);si(J)=sip(J); % Update variabels and associated data.
end

end % thetaon

% Save data periodically
sampcnt=sampcnt+1;
if sampcnt>=subsample
savcnt=savcnt+1;
mcmcrun(savcnt,:)=[mu, taux, tauz];
mcmcruntheta(savcnt,:)=thetai;  % Angular varaibles thetai
%mcmcrunphi(savcnt,:)=phi;  % Angular varaibles thetai
sampcnt=0;
end

if k<burnin
prdmutau(k)=mu*taux;
musq(k)=mu^2;
tauxsq(k)=taux^2;
mus(k)=mu;
tauxs(k)=taux;
end

end % k

% Compute covariance matrix (unbiased).
if bk<length(nblok)

rg=(nblok(bk-1)+1):nblok(bk);

% Acceptance stats
rts=acceg/(nblok(bk)-nblok(bk-1));
rwstats.acc(bk-1,:)=[acceg rts]; 
acceg=[0 0];

disp(['Evaluating acceptance rates on ' num2str(bk) 'th block, ' num2str(rts(1)) ', ' num2str(rts(2))]);

% New rw step sizes
for i=1:2
if rts(i)>0.5
w(i)=w(i)*EXPANDF;
end
if rts(i)>0.5
w(i)=w(i)*SHRINKF;
end
end

rwstats.wts(bk-1,:)=w;

end
end %b

mcmcparams.alg='Eucl. Inflation correction: marginal Li';
mcmcparams.initstate=algparams.init;
mcmcparams.variables={'mu','taux','tauz'};
mcmcparams.priors=algparams.priors;
mcmcparams.data=X;
mcmcparams.runparams=[algparams.n algparams.subsample];
%mcmcparams.stats={'mu reject',muf,muf/algparams.n,a,b};
mcmcparams.mutaurw.stats=rwstats;
mcmcparams.mutaurw.burnindat=[mus tauxs musq tauxsq prdmutau];  

mcmcrunphi=[];
