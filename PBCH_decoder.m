function a_hat = PBCH_decoder(f_tilde, A, L, min_sum)
% PCBH_DECODER Public Broadcast Channel (PBCH) polar decoder from 3GPP New
% Radio, as specified in Section 7.1 of TS 38.212 v1.0.1...
% http://www.3gpp.org/ftp/TSG_RAN/WG1_RL1/TSGR1_AH/NR_AH_1709/Docs/R1-1716928.zip
%   a_hat = PBCH_DECODER(f_tilde, A, L, min_sum) decodes the encoded LLR sequence 
%   f_tilde, in order to obtain the recovered information bit sequence 
%   a_hat.
%
%   f_tilde should be a real row vector comprising E number of Logarithmic
%   Likelihood Ratios (LLRS), each having a value obtained as LLR =
%   ln(P(bit=0)/P(bit=1)).
%
%   A should be an integer scalar. It specifies the number of bits in the
%   information bit sequence, where A should be less than E and should be 
%   no greater than 200.
%
%   L should be a scalar integer. It specifies the list size to use during
%   Successive Cancellation List (SCL) decoding.
%
%   min_sum shoular be a scalar logical. If it is true, then the SCL
%   decoding process will be completed using the min-sum approximation.
%   Otherwise, the log-sum-product will be used. The log-sum-product gives
%   better error correction capability than the min-sum, but it has higher
%   complexity.
%
%   a_hat will be a binary row vector comprising A number of bits, each 
%   having the value 0 or 1.
%
%   See also PBCH_ENCODER
%
% Copyright � 2017 Robert G. Maunder. This program is free software: you 
% can redistribute it and/or modify it under the terms of the GNU General 
% Public License as published by the Free Software Foundation, either 
% version 3 of the License, or (at your option) any later version. This 
% program is distributed in the hope that it will be useful, but WITHOUT 
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or 
% FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for 
% more details.

addpath 'components'

E = length(f_tilde);

% E is always 864 in PBCH
if E ~= 864
    error('polar_3gpp_matlab:UnsupportedBlockLength','E should be 864.');
end

% The CRC polynomial used in 3GPP PBCH and PDCCH channel is
% D^24 + D^23 + D^21 + D^20 + D^17 + D^15 + D^13 + D^12 + D^8 + D^4 + D^2 + D + 1
crc_polynomial_pattern = [1 1 0 1 1 0 0 1 0 1 0 1 1 0 0 0 1 0 0 0 1 0 1 1 1];

% The CRC has P bits. P-min(P2,log2(L)) of these are used for error
% detection, where L is the list size. Meanwhile, min(P2,log2(L)) of
% them are used to improve error correction. So the CRC needs to be
% min(P2,log2(L)) number of bits longer than CRCs used in other codes,
% in order to achieve the same error detection capability.
P = length(crc_polynomial_pattern)-1;
P2 = 3;

% Determine the number of information and CRC bits.
K = A+P;

% Determine the number of bits used at the input and output of the polar
% encoder kernal.
N = get_3GPP_N(K,E,9); % n_max = 9 is used in PBCH and PDCCH channels

% Get the 3GPP CRC interleaver pattern.
crc_interleaver_pattern = get_3GPP_crc_interleaver_pattern(K);

% Get the 3GPP rate matching pattern.
[rate_matching_pattern, mode] = get_3GPP_rate_matching_pattern(K,N,E);

% Get the 3GPP sequence pattern.
Q_N = get_3GPP_sequence_pattern(N);

% Get the 3GPP information bit pattern.
info_bit_pattern = get_3GPP_info_bit_pattern(K, Q_N, rate_matching_pattern, mode);

% Perform Distributed-CRC-Aided polar decoding.
a_hat = DCA_polar_decoder(f_tilde,crc_polynomial_pattern,crc_interleaver_pattern,info_bit_pattern,rate_matching_pattern,mode,L,min_sum,P2);
