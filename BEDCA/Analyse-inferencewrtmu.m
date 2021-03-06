

%
% This runs the MCMC and analyses the output for 10 simulations of various mu values.
%

NOT USED. See Master_SimTests

% Set renderer
set(0,'DefaultFigureRendererMode','manual')
set(0,'DefaultFigureRenderer','OpenGl')


% Simulations generated in simulateEucl
for k=5:14
	[algparams convergencediagnos]=RunMCMC_ECsimulateddata(k,'','',[],struct('a',3));
end

%
% Analysis
% Mean E[\mu], median, skew, interquartile and standard deviation with respect to mu 
% Mean E[\tau_xz], median, skew, interquartile and standard deviation with respect to mu 
%

  %
  % Loop over MCMC runs, loading 1st run of each set.
  %

  FilesArray={{'Sim_simInflation_sample1000_v6_muvar_EDC_mu=','_a3',10:10:80},{'Sim_simInflation_sample1000_v6_smallm_EDC_mu=','_a3',0:2:8}};

muv=[0:2:8 10:10:80]; % mu values

mumean=[];
musd=[];
muiq=[];
tauxm=[];
tauxsd=[];
tauzm=[];
tauzsd=[];
for j=1:length(muv)

	% Find file
	for k=1:length(FilesArray)
		J=find(FilesArray{k}{3}==muv(j));
if ~isempty(J)
break;
end
end %for k

if isempty(J)
disp(['Cannot find mu=' num2str(muv(j) '. ABORT.'])
     return;
     end


     % Pair (k,J)


     


	end %j
