function diagnostic=convergence_diagnosticGR(mcmcdat,burnin)
% diagnostic=convergence_diagnosticGR(mcmcdat,burnin)
%
% This computes Gelman-Rubin R diagnostic on all variables in mcmcdat 
% Returns diagnostic.varnames .m .n .R .d (degrees of freedom)
%
%
  % Related: compute_convergencediagExpt computes this and saves across an expt.
% NJB July 2013

m=length(mcmcdat);

if isempty(burnin)
  burnin=mcmcdat(1).mcmcparams.burnin;
end

%burnin=1;

if m<3
diagnostic=[];
disp('Too few runs for convergence diagnostics');
return;
end

diagnostic.varnames=mcmcdat(1).mcmcparams.varnames;
diagnostic.m=m;
diagnostic.n=0;
diagnostic.burnin=burnin;

for j=1:length(diagnostic.varnames)

  dat=[];
  for r=1:m
  dat=[dat mcmcdat(r).mcmcrun(burnin+1:end,j)];

end %r

n=size(dat,1);

%
% mu=mean(dat(:));
% Compute Between and within
% From Gelman Rubin Stat Sci 1992; 457.
%
Bn=var(mean(dat,1)); % Between variance on means per run.
W=mean(var(dat,0,1));

sigsqr=(n-1)*W/n+Bn;
V=sigsqr+Bn/m; % Need variance estimate of V 
covarianceterm=(cov(var(dat,0,1),mean(dat,1).^2)-2*mean(dat(:))*cov(var(dat,0,1),mean(dat,1)));
varV=(1-1/n)^2*var(var(dat,0,1))/m+2*(1+1/m)^2*Bn^2/(m-1)+(1+1/m)*(1-1/n)*covarianceterm(1,2)/m;

d=2*V/varV;

diagnostic.Rc(j)=((d+3)/(d+1))*V/W;
diagnostic.R(j)=V/W;

diagnostic.W(j)=W;diagnostic.B(j)=n*Bn;diagnostic.d(j)=d;

end %j


% Compute matrix versions

cv=0;bv=0;
for r=1:m

cv=cv+cov(mcmcdat(r).mcmcrun(burnin+1:end,:)); % Averaging over chains.

b(r,:)=mean(mcmcdat(r).mcmcrun(burnin+1:end,:),1);

end %r

ndW=cv/m;
ndBn=cov(b);

ev=eig(ndBn,ndW);

diagnostic.ndW=ndW;
diagnostic.ndBn=ndBn;
diagnostic.eigenvalues=ev;
diagnostic.MPSRF=(n-1)/n+max(ev)*(m+1)/m;

diagnostic.n=n;
