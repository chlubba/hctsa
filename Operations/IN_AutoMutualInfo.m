% ------------------------------------------------------------------------------
% IN_AutoMutualInfo
% ------------------------------------------------------------------------------
% 
% Decided to implement some more rigorous mutual information estimators
% from the information dynamics toolkit.
% 
%---INPUTS:
%
% y: input time series
% 
% timeDelay: time lag for automutual information calculation
% 
% estMethod: the estimation method used to compute the mutual information:
%           (*) 'gaussian'
%           (*) 'kernel'
%           (*) 'kraskov1'
%           (*) 'kraskov2'
% 
% cf. Kraskov, A., Stoegbauer, H., Grassberger, P., Estimating mutual
% information: http://dx.doi.org/10.1103/PhysRevE.69.066138
% 
%---HISTORY
% Ben Fulcher, 2015-03-27
% 
% ------------------------------------------------------------------------------
% Copyright (C) 2013,  Ben D. Fulcher <ben.d.fulcher@gmail.com>,
% <http://www.benfulcher.com>
%
% If you use this code for your research, please cite:
% B. D. Fulcher, M. A. Little, N. S. Jones, "Highly comparative time-series
% analysis: the empirical structure of time series and their methods",
% J. Roy. Soc. Interface 10(83) 20130048 (2010). DOI: 10.1098/rsif.2013.0048
%
% This function is free software: you can redistribute it and/or modify it under
% the terms of the GNU General Public License as published by the Free Software
% Foundation, either version 3 of the License, or (at your option) any later
% version.
% 
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
% details.
% 
% You should have received a copy of the GNU General Public License along with
% this program.  If not, see <http://www.gnu.org/licenses/>.
% ------------------------------------------------------------------------------

function out = IN_AutoMutualInfo(y,timeDelay,estMethod,extraParam)

% ------------------------------------------------------------------------------
% Check inputs:
% ------------------------------------------------------------------------------
if nargin < 2 || isempty(timeDelay)
    timeDelay = 1;
end
if strcmp(timeDelay,'tau')
    timeDelay = CO_FirstZero(y,'ac');
    fprintf(1,'timeDelay = %u set to fist zero-crossing of ACF\n',timeDelay);
end

if nargin < 3 || isempty(estMethod)
    estMethod = 'kernel';
end

if nargin < 4
    extraParam = [];
end

N = length(y);

% ------------------------------------------------------------------------------
switch estMethod
case 'gaussian'
    implementingClass = 'infodynamics.measures.continuous.gaussian.MutualInfoCalculatorMultiVariateGaussian';
case 'kernel'
    implementingClass = 'infodynamics.measures.continuous.kernel.MutualInfoCalculatorMultiVariateKernel';
case 'kraskov1' % algorithm 1
    implementingClass = 'infodynamics.measures.continuous.kraskov.MutualInfoCalculatorMultiVariateKraskov1';
case 'kraskov2' % algorithm 2
    implementingClass = 'infodynamics.measures.continuous.kraskov.MutualInfoCalculatorMultiVariateKraskov2';    
end
% ------------------------------------------------------------------------------

miCalc = javaObject(implementingClass);

% Specify a univariate calculation:
miCalc.initialise(1,1);

% Add neighest neighbor option for KSG estimator
if ismember(estMethod,'kraskov2')
    if ~isempty(extraParam)
        miCalc.setProperty('k', extraParam); % 4th input specifies number of nearest neighbors for KSG estimator
    else
        miCalc.setProperty('k', '3'); % use 3 nearest neighbors for KSG estimator as default
    end
end

% Loop over time delays if a vector
numTimeDelays = length(timeDelay);
amis = zeros(numTimeDelays,1);
for k = 1:numTimeDelays
    
    if timeDelay(k) > N
        error('time delay too long');
    end
    
    % ------------------------------------------------------------------------------
    % Form the time-delay vectors y1 and y2
    y1 = y(1:end-timeDelay(k));
    y2 = y(1+timeDelay(k):end);

    % Set observations to time-delayed versions of the time series:
    miCalc.setObservations(y1, y2);

    % Compute:
    amis(k) = miCalc.computeAverageLocalOfObservations();
end

% ------------------------------------------------------------------------------
% Make outputs:

if numTimeDelays == 1
    % output a scalar
    out = amis;
else
    % Output a structure:
    for k = 1:numTimeDelays
        out.(sprintf('ami%u',timeDelay(k))) = amis(k);
    end
end



end