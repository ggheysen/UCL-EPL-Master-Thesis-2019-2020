function mem = internal_mem( Toxy, Npar, Nnp, BW )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
Nixy = [224 112 112 56 56 28 28 14 14 14 14  7   7   7    7    1];
Nif  = [3   32  16  24 24 32 32 64 64 96 96  160 160 320  1280 1280];
Nof  = [32  16  24  24 32 32 64 64 96 96 160 160 320 1280 1280 1000];
t    = [    1   6   6  6  6  6  6  6  6  6   6   6];
S    = [2   1   2   1  2  1  2  1  1  1  2   1   1   1    1    1 ];
Ngr_max = max(Nif(2:13) ./ Npar);
Nkxy = 3;
mem = 0;
Tixy = max(Nkxy +  S.*(Toxy - 1) );
disp(Tixy)
%% FMI BUFFER
nelem = 0;
bw_elem = BW;
mem = mem + nelem*bw_elem;
%% FMO BUFFER
nelem = 0;
for i = 1:length(Nixy)
    nelem = max(nelem, Nof(i) * min(Tixy, Nixy(i)) * min(Tixy, Nixy(i)));
end
bw_elem = BW;
mem = mem + nelem*bw_elem;
%% KEX BUFFER
nelem = Nnp * Ngr_max * Npar;
bw_elem = BW + ceil(log2(Npar));
mem = mem + nelem*bw_elem;
%% FMINT Buffer
nelem = Tixy * Tixy * Npar;
bw_elem = BW;
mem = mem + nelem*bw_elem;
%% KDW BUFFER
nelem = Nkxy * Nkxy * Npar;
bw_elem = BW;
mem = mem + nelem*bw_elem;
%% KPW BUFFER
nelem = Nnp * max(Nof);
bw_elem = BW + ceil(log2(Npar));
mem = mem + nelem*bw_elem;
end

