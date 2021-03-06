function ppa=posteriorprioranalysis(mcmcpars,mcmcrun,priormoments)
  % posteriorprioranalysis(mcmcpars)
  %
  % This analyses the degree of compresion of the posterior relative to the prior
  % Variance ratio
  % z = diff mu/var
  %
  % NJB Oct 2019


  mns=mean(mcmcrun,1);
vars=var(mcmcrun,0,1);


  for i=1:length(mcmcpars.variables)

	  varrats(i)=vars(i)/priormoments(i,2);
z(i)=(mns(i)-priormoments(i,1))/sqrt(vars(i)+priormoments(i,2));

	  end

	  ppa.varianceratio=varrats;
ppa.z=z;
ppa.warnings=sum(varrats>0.5)+sum(abs(z)>1.65);

warnmat=[varrats > 0.5; abs(z)>1.65];

J=find(sum(warnmat,1));

  if ~isempty(J)
 
disp(' ');
disp('Posterior, prior moments analysis:');
disp(ppa)

for j=J
  disp(['***Warning: ' mcmcpars.variables{j} ' prior is too strong or inappropriate.' ]);
end

disp(' ');
end
