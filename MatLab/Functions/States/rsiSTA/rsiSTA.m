function [state,ri,ma] = rsiSTA(price,M,thresh,type)
%RSISTA returns a logical STATE for from 'relStrIdx.m'
% RSISTA returns a logical STATE for from 'relStrIdx.m'
% which is a value that is above/below an upper/lower threshold intended to locate
% overbought and oversold conditions.  
% M serves as a detrending function
%   NOTE: It is important to consider that an RSI STATE really has 3 states.
%            1      Above upper threshold is overbought
%           -1      Below lower threshold is oversold
%            0      There is also a neutral region between thresholds and 50%
%   
%   This function may also be used as a STATE function, although it would be equally
%   appropriate to call the 'rsindex' function directly.  
%   The output from the function is in a state form.
%
%   [signal,r,sh,ri,ma,thresh] = RSISIG(price,M,thresh,type)
%
%           signal	The generated output SIGNAL (also a STATE)
%           ri      RSI values generated by the call to rsindex.m

%% MEX code to be skipped
coder.extrinsic('movAvg_mex','OHLCSplitter','relStrIdx')

%% Defaults and parsing

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
	end; % if
else
    % M is the detrend average
    % It would appear we are taking a multiple of M below
    % to capture a longer moving average to detrend
    N = M(1);
    M = 15*M(1);
end
    
% Preallocate so we can MEX
rows = size(price,1);
fClose = zeros(rows,1);                                     %#ok<NASGU>
state = zeros(rows,1);
ri = zeros(rows,1);                                         %#ok<NASGU>

fClose = OHLCSplitter(price);

%% Check if detrender is larger than number of observations
%  If so, reduce the detrender to a factor of 1/3 the number of observations.
%  (1/3 was an arbitrary choice)
%  This can happen on a parametric sweep when the data set is split between
%  a validation and test set.
if M > rows
    %Mtemp = M;
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
ri = relStrIdx(fClose - ma, N);

%% Generate STATE

% Crossing the lower threshold (oversold)
indx    = ri < thresh(1);
% Unknown Matlab adjuster
% indx    = [false; indx(1:end-1) & ~indx(2:end)];
% NOTE: Notice we are producing a '1' when the condition is oversold
state(indx) = 1;

% Crossing the upper threshold (overbought)
indx    = ri > thresh(2);
% Unknown Matlab adjuster
% indx    = [false; indx(1:end-1) & ~indx(2:end)];
% NOTE: Notice we are producing a '-1' when the condition is overbought
state(indx) = -1;

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

