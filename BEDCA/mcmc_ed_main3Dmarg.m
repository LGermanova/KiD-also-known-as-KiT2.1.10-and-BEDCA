function [mcmcparams, mcmcrun, mcmcruntheta, mcmcrunphi]=mcmc_ed_main3Dmarg(X,algparams)
% [mcmcparams, mcmcrun, mcmcruntheta]=mcmc_ed_main3Dmarg(X,algparams)
  %
  % This is an MCMC algorithm for 3D inflation removal from Euclidean distance measurements. Uses a marginalised form, integrating over phi_i. Uses RW proposals.
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
  % algparams.savangles =1 Save angles theta.
  % Returns mcmcrun with variable samples and mcmcruntheta the theta samples
  %
  % Related mcmc_ed_main3D
  % NJB May 2017

% algorithm params
dtheta=0.75;
%rwphi=0.025; % Walk size
maxphi=0.5;
minphi=0.0125; % Min and max allowed sd of phi proposal
sampcnt=0;
savangles=algparams.savangles;  % Save angles

%
if algparams.verbose
disp('BEDCA: MCMC for anisotropic inflation model. marginal Li. Author: Burroughs, Warwick.');
disp(['Steps ' num2str(algparams.n)]);
end

% switch variable on/off for debugging
muon=1;
%tauxon=1;
tauzon=1;
%phion=1;
thetaon=1;

if sum([muon tauzon thetaon])<3
if muon disp('mu/taux is ON **'); else disp('mu is OFF'); end
%if tauxon disp('taux is ON **'); else disp('taux is OFF'); end
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

if algparams.verbose
disp(['data set size ' num2str(N)]);
end

% Priors
[params typ]=get_priorparams(algparams.priors,'mu');
mu0=params(1);mupp=1/params(2);  % mean and precision
[params typ]=get_priorparams(algparams.priors,'taux');
ataux=params(1);ktaux=params(2);
[params typ]=get_priorparams(algparams.priors,'tauz');
atauz=params(1);ktauz=params(2);

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

% Save initial conditions
savcnt=1;
mcmcrun=zeros(floor(n/subsample),3);
mcmcruntheta=zeros(floor(n/subsample),N);

mcmcrun(savcnt,:)=[mu, taux, tauz];
mcmcruntheta(savcnt,:)=thetai;  %  Angular variables thetai
%mcmcrunphi(savcnt,:)=phi;       %  Angular variables phi

% Set up burnin and blocks for rw
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

% Initial directions are mu, taux
  V=[1 0; 0 1]; % First diection is mu
  w=[2.5 0.1/50^2];  % initial step sizes in mu and taux

% Alg stats
muf=0;
acceg=[0 0];

for bk=2:length(nblok)
  for k=(nblok(bk-1)+1):nblok(bk) % main loop with k steps

% Update mu. Normal.
if muon 
		% random walk. (mu tau)^\prime = (mu tau)+ N(0,si) vi
   for i=1:2
	   pd=[mu taux]'+normrnd(0,w(i))*V(:,i); %' Proposed position

	   if pd(1)>0 & pd(2)>0 % Ratio of likelihoods. Involves Bessel functions
	   bpar=rpxy.*si;
bparp=pd(1)*pd(2)*bpar;bpar=mu*taux*bpar;
Iprod=prod(besseli(0,bparp,1)./besseli(0,bpar,1));
a=-ktaux*(pd(2)-taux)-0.5*((pd(1)-mu0)^2-(mu-mu0)^2)*mupp+sum(bparp-bpar)-0.5*pd(2)*(sum((pd(1)*si).^2)+sumSqrpxy)+0.5*taux*(sum((mu*si).^2)+sumSqrpxy)-0.5*tauz*(pd(1)-mu)*sum(ci.*((pd(1)+mu)*ci-2*rpz)); 
a=exp(a)*(pd(2)/taux)^(N+ataux-1)*Iprod;

if a>1 | a>rand()
mu=pd(1);taux=pd(2);
acceg(i)=acceg(i)+1;
end
		end
end %i
		
end % muon


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

alpha=sip./si; % Geometric effect. Uniform theta prior.alpha.
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

J=thetap>0 & thetap<pi & alpha>rand(1,N);  % Reject if negative.
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

if savangles
mcmcruntheta(savcnt,:)=thetai;  % Angular variables thetai
%mcmcrunphi(savcnt,:)=phi;  % Angular varaibles thetai
else
  lastthetai=thetai;
end

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

if algparams.verbose
disp(['Evaluating mu-taux covariance matrix on ' num2str(bk) 'th block']);
end
rg=(nblok(bk-1)+1):nblok(bk);
C(1,1)=(sum(musq(rg))-sum(mus(rg))^2/(nblok(bk)-nblok(bk-1)))/(nblok(bk)-nblok(bk-1)-1);
C(2,2)=(sum(tauxsq(rg))-sum(tauxs(rg))^2/(nblok(bk)-nblok(bk-1)))/(nblok(bk)-nblok(bk-1)-1);
C(1,2)=sum(prdmutau(rg))-sum(mus(rg))*sum(tauxs(rg))/(nblok(bk)-nblok(bk-1));
C(1,2)=C(1,2)/(nblok(bk)-nblok(bk-1)-1);
%C(1,2)=C(1,2)/sqrt(C(1,1)*C(2,2));
C(2,1)=C(1,2);

%C  % Uncomment if you want to see cov matrix every block
if algparams.verbose
disp(['Correlation ' num2str(C(1,2)/sqrt(C(1,1)*C(2,2)))])
end
  
[V D]=eig(C); % Eigenvectors are columns of V

rwstats.C(bk-1,:,:)=C;
rwstats.EV(bk-1,:)=[D(1,1) D(2,2)];

% New directions V(:,1), V(:,2)
  w=sqrt([D(1,1) D(2,2)]);  % sd in these directions

% Acceptance stats
rwstats.acc(bk-1,:)=[acceg acceg/(nblok(bk)-nblok(bk-1))]; 
acceg=[0 0];

end
end %b

mcmcparams.alg='Eucl. Inflation correction: marhginal Li';
mcmcparams.initstate=algparams.init;
mcmcparams.variables={'mu','taux','tauz'};
mcmcparams.priors=algparams.priors;
mcmcparams.data=X;
mcmcparams.runparams=[algparams.n algparams.subsample];
%mcmcparams.stats={'mu reject',muf,muf/algparams.n,a,b};
mcmcparams.mutaurw.stats=rwstats;
mcmcparams.mutaurw.burnindat=[mus tauxs musq tauxsq prdmutau];  

mcmcparams.laststate=mcmcrun(end,:); %[mu 1/sqrt(taux) 1/sqrt(tauz)]; % In init form. Stores the last saved entry
mcmcparams.laststate(2:3)=1./sqrt(mcmcparams.laststate(2:3));


% Priors
%
% Gamma G(a,b) has mean a/b, var a/b^2. Rel error is 1/sqrt(a).
  % Priors are gaussian, Gamma, Gamma
  mcmcparams.posteriorprior=posteriorprioranalysis(mcmcparams,mcmcrun(burnin:end,:),[mu0 1/mupp; ataux/ktaux ataux/ktaux^2; atauz/ktauz atauz/ktauz^2]);

mcmcparams.relprecisionxz=mean(mcmcrun(burnin:end,2))/mean(mcmcrun(burnin:end,3));
if mcmcparams.relprecisionxz<1
disp(' ');
disp('***Warning: x precision too low relative to z');
end

% Total warnings.
mcmcparams.runwarnings=(mcmcparams.relprecisionxz<1)+mcmcparams.posteriorprior.warnings;

if savangles
mcmcparams.laststatethetas=squeeze(mcmcruntheta(savcnt,:))';  %' Angular variables thetai
else
mcmcparams.laststatethetas=lastthetai'; %'
end

mcmcrunphi=[];


