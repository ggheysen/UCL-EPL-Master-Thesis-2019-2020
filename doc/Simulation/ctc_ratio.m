function ctc_ratio = ctc_ratio(Nixy, Nif, Nof, Tixy, t, S, Nnp, Npar, BW)
%BW_ROOF Summary of this function goes here
%   Detailed explanation goes here
%% Dimension
Noxy = Nixy / S;
Toxy = Tixy / S;
K = 3;
%% Compute number of operation for the layer
Expand = Nixy*Nixy * Nif * t * Nnp * ceil(Nif/Npar);
DSC = (K*K*t*Nif*Noxy*Noxy) + (Noxy*Noxy * Nof * Nnp * ceil(t*Nif/Npar));
Nop = 2 *(Expand + DSC); % 2 because Comp + Add
%% Computation of B, data fetched from external memory to fill the on chip memory
B_i = Nif * Tixy * Tixy;
B_k = Nif * t * Nif + Nif * t * K * K + Nif * t * Nof;
B_o = Nof * Toxy * Toxy;
%% Computation of alpha, number of time we fectch from external mem
alpha_i = ceil(Noxy / Toxy) * ceil(Noxy / Toxy);
alpha_k = alpha_i;
alpha_o = ceil(Noxy / Toxy) * ceil(Noxy / Toxy);
%% Computation of accesses
access_i = alpha_i * B_i;
access_k = alpha_k * B_k;
write_o = alpha_o * B_o;
%% Computation of ctc ratio
ctc_ratio = Nop / ((access_i + access_k + write_o) * (BW/8));
end