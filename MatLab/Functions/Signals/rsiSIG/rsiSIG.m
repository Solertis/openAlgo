function [s,r,sh,ri,ma,thresh] = rsiSIG(price,M,thresh,type,bigPoint,cost,scaling)
%RSISIG RSI signal generator from relStrIdx.m
% RSISIG trading strategy.  Note that the trading signal is generated when the
% RSI value is above/below the upper/lower threshold.
% M serves as a detrending function
%
%   NOTE: It is important to consider that an RSI signal generator really has 3 states.
%           Above Threshold is Overbought
%           Below Threshold is Oversold
%           There is also a neutral region between +/- Threshold and 50%
%
%   This should be considered prior to adding or removing any Echos to this output.
%   For calculating a direct PNL, the signal should first be cleaned with remEcho_mex.
%

%   [signal,r,sh,ri,ma,thresh] = RSISIG(price,M,thresh,type,scaling,cost,bigPoint)
%   INPUTS:
%           price       an array of any [C] or [O | C] or [O | H | L | C]
%           M           observation lookback period
%           thresh      threshold of overbought / oversold (X | [X 100-X] is submitted)
%           type        Type of average used for smoothing
%           scaling     sharpe ratio adjuster
%           cost        round turn commission cost for proper P&L calculation
%           bigPoint    Full tick dollar value of security
%   OUTPUTS:
%           s       	The generated output SIGNAL (also a STATE)
%           r           Return generated by the derived signal
%           sh          Sharpe ratio generated by the derived signal
%           ri          RSI values generated by the call to rsindex.m
%           ma          Moving average values used in the detrender (primarily for debugging)
%           thresh      Echos the input threshold value (primarily for debugging)
%

coder.extrinsic('remEchos_mex','movAvg_mex','OHLCSplitter','relStrIdx','calcProfitLoss','sharpe')

%% Defaults and parsing

% Check if multiple elements are passed.
% The second element is number of bars to pass to rsindex
% The default for N (2nd element) is 14
% If detrender is set to a negative value we will also use the default of 15 * RSIBars
% This is done so we can test both 0 = No detrending & -1 = Default detrending in a sweep
% With this adjustment we can sweep [-1:1:14] which will test detrenders 1 through 15 as
% well as none.

if numel(thresh) == 1 % scalar value
    thresh = [100-thresh, thresh];
else
    if thresh(1) > thresh(2)
        thresh = thresh(2:-1:1);
    end %if
end %if

if numel(M) > 1
    N = M(1);
    if M(2) < 0
        M = 15 * N;
    else
        M = M(2);
    end; %if
else
    % M is the detrend average
    % It would appear we are taking a multiple of M below
    % to capture a longer moving average to detrend
    N = M(1);
    M = 15*N;
end

% Preallocate so we can MEX
rows = size(price,1);
fClose = zeros(rows,1);                                     %#ok<NASGU>
fOpen = zeros(rows,1);                                      %#ok<NASGU>
s = zeros(rows,1);
ri = zeros(rows,1);                                         %#ok<NASGU>

[fOpen,fClose] = OHLCSplitter(price);

%% Check if detrender is larger than number of observations
%  If so, reduce the detrender to a factor of 1/3 the number of observations.
%  (1/3 was an arbitrary choice)
%  This can happen on a parametric sweep when the data set is split between
%  a validation and test set.
if M > rows
    % Mtemp = M;
    M = round(rows/3);
    %% IMPORTANT
    % fprintf('Warning: The RSI detrender M (%0.f) resulted in a smoothing value input (%.0f) which is larger \nthan the number of provided observations (%.0f). ',N,Mtemp,rows);
    % fprintf('The smoothing value was adjusted to (%.0f).\n\n',M);
end; %if

%% Detrend with a moving average
if M == 0
    ma = zeros(length(fClose),1);
else
    ma = movAvg_mex(fClose,M,M,type);
end

%ri = rsindex(fClose - ma, N);
ri = relStrIdx(fClose - ma, N);                 % RSI

%% Generate SIGNAL
% Crossing the lower threshold (oversold)
indx    = ri < thresh(1);
% Unknown Matlab adjuster
% indx    = [false; indx(1:end-1) & ~indx(2:end)];
% NOTE: Notice we are producing a 'buy signal' when the condition is oversold
s(indx) = 1.5;

% Crossing the upper threshold (overbought)
indx    = ri > thresh(2);
% Unknown Matlab adjuster
% indx    = [false; indx(1:end-1) & ~indx(2:end)];
% NOTE: Notice we are producing a 'sell signal' when the condition is overbought
s(indx) = -1.5;

% Set the first position to 1 lot
% Make sure we have at least one trade first
if ~isempty(find(s,1))
    % Clean up repeating information so we can calculate a PNL
    s = remEchos_mex(s);
    
    %% PNL Caclulation
    [~,~,~,r] = calcProfitLoss([fOpen fClose],s,bigPoint,cost);
    sh = scaling*sharpe(r,0);
else
    % No signal - no return or sharpe
    r = zeros(length(fClose),1);
    sh = 0;
end; %if

%%
%   -------------------------------------------------------------------------
%                                  _    _ 
%         ___  _ __   ___ _ __    / \  | | __ _  ___   ___  _ __ __ _ 
%        / _ \| '_ \ / _ \ '_ \  / _ \ | |/ _` |/ _ \ / _ \| '__/ _` |
%       | (_) | |_) |  __/ | | |/ ___ \| | (_| | (_) | (_) | | | (_| |
%        \___/| .__/ \___|_| |_/_/   \_\_|\__, |\___(_)___/|_|  \__, |
%             |_|                         |___/                 |___/
%   -------------------------------------------------------------------------
%        This code is distributed in the hope that it will be useful,
%
%                      	   WITHOUT ANY WARRANTY
%
%                  WITHOUT CLAIM AS TO MERCHANTABILITY
%
%                  OR FITNESS FOR A PARTICULAR PURPOSE
%
%                          expressed or implied.
%
%   Use of this code, pseudocode, algorithmic or trading logic contained
%   herein, whether sound or faulty for any purpose is the sole
%   responsibility of the USER. Any such use of these algorithms, coding
%   logic or concepts in whole or in part carry no covenant of correctness
%   or recommended usage from the AUTHOR or any of the possible
%   contributors listed or unlisted, known or unknown.
%
%   Any reference of this code or to this code including any variants from
%   this code, or any other credits due this AUTHOR from this code shall be
%   clearly and unambiguously cited and evident during any use, whether in
%   whole or in part.
%
%   The public sharing of this code does not relinquish, reduce, restrict or
%   encumber any rights the AUTHOR has in respect to claims of intellectual
%   property.
%
%   IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY
%   DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
%   DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
%   OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
%   HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
%   STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
%   ANY WAY OUT OF THE USE OF THIS SOFTWARE, CODE, OR CODE FRAGMENT(S), EVEN
%   IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
%   -------------------------------------------------------------------------
%
%                             ALL RIGHTS RESERVED
%
%   -------------------------------------------------------------------------
%
%   Author:        Mark Tompkins
%   Revision:      4906.24976
%   Copyright:     (c)2013
%


