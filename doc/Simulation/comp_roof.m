function comp_roof = comp_roof(Nixy, Tixy, Nif, Nof, Nnp, Npar, ...
                               Pix, Piy, Pkexf, Pgri, Pdwf, Pof, ...
                               t, S, f)
%COMP_ROOF Summary of this function goes here
%   Detailed explanation goes here
%% Dimension
Noxy = Nixy / S;
Toxy = Tixy / S;
K = 3;
Ngri = ceil(Nif/Npar);
Ngrint = ceil(t*Nif/Npar);
%% Compute number of operation
Expand = Nixy*Nixy * Nif * t * Nnp * Ngri;
DSC = (K*K*t*Nif*Noxy*Noxy) + (Noxy*Noxy * Nof * Nnp * Ngrint);
Nop = 2 *(Expand + DSC); % 2 because Comp + Add
%% compute intertile cycle
intertile_exp = ceil(Nixy/Tixy) * ceil(Nixy/Tixy) * Ngrint;
intertile_dsc = ceil(Noxy/Toxy) * ceil(Noxy/Toxy) * Ngrint * 2;
%% compute intratile cycle
intratile_exp = ceil(Tixy/Pix) * ceil(Tixy/Piy) * ceil(Npar/Pkexf) * ceil(Ngri/Pgri);
intratile_dsc = ceil(Toxy/Pix) * ceil(Toxy/Piy) * (ceil(Npar/Pdwf) + 2 * ceil(Nof/Pof));
%% Compute number of cycle
Expand = intertile_exp * intratile_exp;
DSC = intertile_dsc * intratile_dsc;
Ncycle = Expand + DSC;
%% compute computation roof
comp_roof = (Nop / Ncycle) * f;
end

