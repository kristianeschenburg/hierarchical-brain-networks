function M = FinRMTc(C,T)
% Adapted from https://www.mathworks.com/matlabcentral/fileexchange/49011-random-matrix-theory-rmt-filtering-of-financial-time-series-for-community-detection
%% FinRMT
% FinRMT uses Random Matrix Theory (RMT) to create a filtered correlation 
% matrix from a set of financial time series price data, for example the
% daily closing prices of the stocks in the S&P
%% Syntax
% M=FinRMT(TS)
%
%% Description
% This function eigendecomposes a correlation matrix of time series
% and splits it into three components, Crandom, Cgroup and Cmarket,
% according to techniques from literature (See, "Systematic Identification
% of Group Identification in Stock Markets, Kim & Jeong, (2008).") and
% returns a filtered correlation matrix containging only the Cgroup
% components.
% The function is intended to be used in conjunction with a community
% detection algorithm (such as the Louvain method) to allow for community 
% detecion on time series based networks.
%
%
%% Inputs arguments:
% priceTS : an mxn matrix containing timeseries' of stock prices. Each column
% should be a time series for one financial instrument and each row should 
% correspond to the value of each instrument at a point in time. For example
% 32.00   9.43   127.25   ...
% 32.07   9.48   126.98   ...
% 32.08   9.53   126.99   ...
%  ...    ...     ....    ...
% No header columns or timestamp columns should be included
%
%% Outputs:
% M : The filtered correlation matrix. This matrix can be passed directly to 
% a community detection algorithm in place of the modularity matrix 
%
%% Example:
% ModularityMatrix = FinRMT(myPriceData)
%  ...
% Communities = myCommunityDectionAlg(ModularityMatrix)
% 
%% Issues & Comments
% Note that the output of this function can serve as the Modularity
% Matrix (Not the Adjacency matrix) for a generalized Community Detection 
% Algorithm. Specifically, one which does not rely on properties of the 
% Adjaceny Matrix to create the Modularity Matrix. The Louvain Method 
% and methods based on spectral decompositon are examples of such.
%
%%
% Copyright (c) 2012, Mel
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
% 
% * Redistributions of source code must retain the above copyright notice, this
%   list of conditions and the following disclaimer.
% 
% * Redistributions in binary form must reproduce the above copyright notice,
%   this list of conditions and the following disclaimer in the documentation
%   and/or other materials provided with the distribution
% * Neither the name of University of Leiden nor the names of its
%   contributors may be used to endorse or promote products derived from this
%   software without specific prior written permission.
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
% OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

N = size(C,2);
    
% Decompose the correlation matrix into its eigenvalues and eigenvectors,
% store the indices of which columns the sorted eigenvalues come from
% and arrange the columns in this order
[V,D] = eig(C);
[eigvals, ind]=sort(diag(D),'ascend'); 
V = V(:,ind);
D=diag(sort(diag(D),'ascend')); 
% Find the index of the predicted lambda_max, ensuring to check boundary
% conditions
Q=T/N;
sigma = 1 - max(eigvals)/N;
RMTmaxEig = sigma*(1 + (1.0/Q) + 2*sqrt(1/Q));
RMTmaxIndex = find(eigvals > RMTmaxEig);
if isempty(RMTmaxIndex)
    RMTmaxIndex = N;
else
    RMTmaxIndex = RMTmaxIndex(1);
end
% Find the index of the predicted lambda_min, ensuring the check boundary
% conditions
RMTminEig = sigma*(1 + (1.0/Q) - 2*sqrt(1/Q));
RMTminIndex = find(eigvals < RMTminEig);
if isempty(RMTminIndex)
    RMTminIndex = 1;
else
    RMTminIndex = RMTminIndex(end);
end
% Determine the average Eigenvalue to rebalance the matrix after removing
% Any of the noise and/or market mode components
avgEigenValue = mean(eigvals(1:RMTmaxIndex));
% Build a new diagonal matrix consisting of the group eigenvalues
Dg = zeros(N,N);
% Replace the random component with average values.
Dg(1 : (N+1) : (RMTmaxIndex-1)*(N+1)) = avgEigenValue;
% Add the group component. The N+1 here is just used to increment to the 
% next diagonal element in the matrix
Dg(1+(N+1)*(RMTmaxIndex-1) : (N+1) : end-(N+1)) = D(1+(N+1)*(RMTmaxIndex-1) : (N+1) : end-(N+1));
% Build the component correlation matrix from the new diagonal eigenvalue
% matrix and eigenvector matrix. The eigenvectors corresponding to zero
% valued eigenvalue entries in Dg will not contribute to M
M = V * Dg * V.';
% Replace the diagonals with 1s
M = M - diag(diag(M)) + eye(N);
end
