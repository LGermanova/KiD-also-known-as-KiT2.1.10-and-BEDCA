function divs =diversitymeasure(X,dispon)
  % divs =diversitymeasure(X,dispon)
  %
  % This calculates the simpson index for effective number of cells
  % Give vector of cell numbers for each KT-pair
  % display is on if dispon=1
  %
  % WARNING: This assumes all KT are paired in call
  %
  % NJB Dec 2018



[cellids IA IC]=unique(X); % cels(:)=cellids(IC)
cnts=hist(IC,1:max(IC)); % counts of KT pairs per cell
SI=sum((cnts/sum(cnts)).^2);

if dispon
disp(['Number cells ' num2str(length(cellids)) ', number KTpairs ' num2str(length(X)) ', average KTs/cell ' num2str(length(X)/length(cellids))]);
disp(['Effective (cell) sample size is ' num2str(1/SI)]);
end

ncells=length(cellids);
nKTpairs=length(X);

divs=[SI ncells nKTpairs];
