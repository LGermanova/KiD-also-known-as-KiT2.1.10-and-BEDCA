function [dats treatments nams]=loadDistData(FileName,typ,filterpars,SAVFILESTEM)
  % [dats treatments nams]=loadDistData(FileName,typ,filterpars,SAVFILESTEM)
  % 
  % This loads 3D distance coord data for 2 fluorophore vectors (in microns)
  % Scaling microns -> nm is at end of function
  %
  % typ='all' Returns all distance data, 'tax'/'tax15min' Taxol treated, 'DMSO'/'untreated' untreated, 'noc'/'noc2hr' Nocodazole treated.
  % typ='columns' loads a column file of 3D distances in form [Delta3D theta]. TO DO
  %
  % Searches for these strings in the fields (except 'column')
  %
  % Add any other categories into switch statement below
  %
  % filterpars is zfilterz and  max 3D distance filter, .zfilterz .filterdist
  % If not wanted leave off field or make []
  %
  % Returns a multiple structure dats{k}.3Ddat .treatment
  % Distance in nms
  %
  % NJB July 2017. Revised 2018.

dats=[];
nams={};
% Extract filters
if isfield(filterpars,'filterdist') & ~isempty(filterpars.filterdist)
filterdist=filterpars.filterdist;
filteron=1;
 else
   filteron=0;
end


if isfield(filterpars,'zfilterz') & ~isempty(filterpars.zfilterz)
zfilterz=filterpars.zfilterz;
 else
   zfilterz=Inf;
end
  

A=load(FileName);
disp(['Loading data file ' FileName]);

fstr=fields(A);

% Add other categories to list below
switch typ

case 'column' % Data assumed to be a 
bob

case 'all'

nams=fieldnames(A);
disp(['Loading all ' num2str(length(nams)) ' treatments.']);
nams

for k=1:length(nams)

if ~isempty(strfind(lower(nams{k}),'tax'))
treatments{k}='Taxol';
 else
   if ~isempty(strfind(lower(nams{k}),'noc'))
treatments{k}='Nocod';
 else
   treatments{k}='DMSO';
end
end

ff=getfield(A,nams{k});
dats{k}=extract_sphericalcoords(ff.microscope.raw.delta,zfilterz,[SAVFILESTEM treatments{k}]);

end %k


case {'tax','tax15min'}

searchstr='tax15min';

J=strfind(lower(fstr),searchstr);
fndstr=zeros(1,length(fstr));
for k=1:length(fstr) fndstr(k)=~isempty(J{k}); end

if sum(fndstr)~=1
  disp(['Error in finding treatment ' typ ', search string ' searchstr ', in ' FileName '. ABORT.']);
disp('Fields are:')
fstr

return;
end

treatments{1}='Taxol15min';
ff=getfield(A,fstr{find(fndstr)});
dats{1}=extract_sphericalcoords(ff.microscope.raw.delta,zfilterz,[SAVFILESTEM treatments{1}]);

case {'noc','noc2hr'}

searchstr='noc2hr';

J=strfind(lower(fstr),searchstr);
fndstr=zeros(1,length(fstr));
for k=1:length(fstr) fndstr(k)=~isempty(J{k}); end

if sum(fndstr)~=1
  disp(['Error in finding treatment ' typ ', search string ' searchstr ', in ' FileName '. ABORT.']);
disp('Fields are:')
fstr

return;
end

treatments{1}='Nocod2hr';
ff=getfield(A,fstr{find(fndstr)});
dats{1}=extract_sphericalcoords(ff.microscope.raw.delta,zfilterz,[SAVFILESTEM treatments{1}]);

 case {'untreated','DMSO','dmso'} % Special case searching with alternative strings

searchstr1='dmso';
searchstr2='untreated';

J1=strfind(lower(fstr),searchstr1);J2=strfind(lower(fstr),searchstr2);
fndstr=zeros(1,length(fstr));
for k=1:length(fstr) fndstr(k)=~isempty(J1{k}) + ~isempty(J2{k}); end

if sum(fndstr)~=1
  disp(['Error in finding treatment ' typ ', search strings ' searchstr1 ', ' searchstr2 ', in ' FileName '. ABORT.']);
disp('Fields are:')
fstr

return;
end

treatments{1}='DMSO';
ff=getfield(A,fstr{find(fndstr)});
dats{1}=extract_sphericalcoords(ff.microscope.raw.delta,zfilterz,[SAVFILESTEM treatments{1}]);

case 'DMSOMG'

searchstr='dmsomg';

J=strfind(lower(fstr),searchstr);
fndstr=zeros(1,length(fstr));
for k=1:length(fstr) fndstr(k)=~isempty(J{k}); end

if sum(fndstr)~=1
  disp(['Error in finding treatment ' typ ', search string ' searchstr ', in ' FileName '. ABORT.']);
disp('Fields are:')
fstr

return;
end

treatments{1}='DMSOMG';
ff=getfield(A,fstr{find(fndstr)});
dats{1}=extract_sphericalcoords(ff.microscope.raw.delta,zfilterz,[SAVFILESTEM treatments{1}]); % [str2num(ff.label(:,3:4));str2num(ff.label(:,3:4))] [str2num(ff.label(:,5:7));str2num(ff.label(:,5:7))]];

case '3uMnocMG'

searchstr='3umnocmg';

J=strfind(lower(fstr),searchstr);
fndstr=zeros(1,length(fstr));
for k=1:length(fstr) fndstr(k)=~isempty(J{k}); end

if sum(fndstr)~=1
  disp(['Error in finding treatment ' typ ', search string ' searchstr ', in ' FileName '. ABORT.']);
disp('Fields are:')
fstr

return;
end

treatments{1}='3uMnocMG';
ff=getfield(A,fstr{find(fndstr)});
dats{1}=extract_sphericalcoords(ff.microscope.raw.delta,zfilterz,[SAVFILESTEM treatments{1}]); % [str2num(ff.label(:,3:4));str2num(ff.label(:,3:4))] [str2num(ff.label(:,5:7));str2num(ff.label(:,5:7))]];


case '3uMnocRevMG'

searchstr='3umnocrevmg';

J=strfind(lower(fstr),searchstr);
fndstr=zeros(1,length(fstr));
for k=1:length(fstr) fndstr(k)=~isempty(J{k}); end

if sum(fndstr)~=1
  disp(['Error in finding treatment ' typ ', search string ' searchstr ', in ' FileName '. ABORT.']);
disp('Fields are:')
fstr

return;
end

treatments{1}='3uMnocRevMG';
ff=getfield(A,fstr{find(fndstr)});
dats{1}=extract_sphericalcoords(ff.microscope.raw.delta,zfilterz,[SAVFILESTEM treatments{1}]); % [str2num(ff.label(:,3:4));str2num(ff.label(:,3:4))] [str2num(ff.label(:,5:7));str2num(ff.label(:,5:7))]];


end % switch

%
% Changes microns to nm
%
for k=1:length(dats)
	dats{k}(:,1)=dats{k}(:,1)*1000;


if filteron & ~isempty(dats{k})
J=find(dats{k}(:,1)<=filterdist);
dats{k}=dats{k}(J,:);
end

end



