clear;
load('data.mat');
%% Parameters
Nixy = [112 112 56 56 28 28 14 14 14 14  7 7];
S    = [1   2   1  2  1  2  1  1  1  2   1 1];
Noxy = Nixy ./ S;
Nif  = [32  16  24 24 32 32 64 64 96 96  160 160];
Nof  = [16  24  24 32 32 64 64 96 96 160 160 320];
t    = [1   6   6  6  6  6  6  6  6  6   6   6];
n    = [1   1   1  1  2  1  3  1  2  1   2   1];
Nkxy = 3;
ncycle = 0;
Tixy = best_tixy;
Toxy = best_toxy;
Pixy = best_pixy;
Pkexf = best_pkexf;
Pgri = best_pgri;
Pof = best_pof;
Npar = best_Npar;
Poxy = best_poxy;
%% 
for i = 1:length(Nixy)
    % Compute # cycles for each layer
    Ngrint = t(i) * Nif(i)/(Npar);
    Ngri = Nif(i)/(Npar);
    %% compute intertile cycle
    intertile_exp = ceil(Nixy(i)/Tixy) * ceil(Nixy(i)/Tixy);
    intertile_dsc = ceil(Noxy(i)/Toxy) * ceil(Noxy(i)/Toxy) * 2;
    %% compute intratile cycle
    intratile_exp = ceil(Tixy/Pixy) * ceil(Tixy/Pixy) * ceil(Npar/Pkexf) * ceil(Ngri/Pgri);
    intratile_dsc = ceil(Toxy/Poxy) * ceil(Toxy/Poxy) * (2 +  ceil(Nof(i)/Pof));
    %% Compute number of cycle
    Expand = intertile_exp * intratile_exp;
    DSC = intertile_dsc * intratile_dsc;
    Ncycle = (Expand + DSC) * Ngrint;
    %
    ncycle = ncycle + Ncycle;
end
disp(ncycle)


