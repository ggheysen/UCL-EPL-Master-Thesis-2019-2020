%% Parameter
ctc = 0:0.001:100;
f = 0.1;
dsp = 112;
hp = 2;
BW = 16;
%Npar = 8;
%Nnp = 2;
Nixy = 7;
max_mem = 5570e3;
S    = [2   1   2   1  2  1  2  1  1  1  2   1   1   1    1    1 ];
Nkxy = 3;
Nif = 32;
Nof = 64;
Noxy = 7;
t = 6;
S2 = 1;
%% Computation
roof = roofline(f, dsp, BW, hp, ctc);
%%
fig = figure('visible','on');
hold on;
xlabel('CTC ratio (FLOP/Byte)')
ylabel('Attainable performance (GFLOPS)')
title('Cyclone V SE 5CSEBA6U23I7 roofline');
plot(ctc, roof, 'linewidth', 2)
%% Do the DSE
% 1: loop over the tiling parameters
K_Npar = 1:Nif;
for Npar = K_Npar(rem(Nif, K_Npar)==0)
    K_np = 1:Npar;
    for Nnp = K_np(rem(Npar, K_np)==0)
        for Toxy_i = [1 7 14 28 56 112 224]
            Tixy = max(Nkxy +  S.*(Toxy_i - 1) );
            Toxy = Tixy - Nkxy + 2;
            if (internal_mem(Tixy, Toxy, Npar, Nnp, BW) <= max_mem)
                ctc = ctc_ratio(Noxy, Nif,  Nof, Toxy_i, t, S2, Nnp, Npar, BW);
                % 2: loop over the unrolling parameters
                K_Tixy = 1:Tixy;
                for pixy = K_Tixy(rem(Tixy, K_Tixy) == 0)
                    K_par = 1:Npar;
                    for pkexf = K_par(rem(Npar, K_par) == 0)
                        Ngri = ceil(t*Nif/Npar);
                        K_gri = 1:Ngri;
                        for pgri = K_gri(rem(Ngri, K_gri) == 0)
                            K_Toxy = 1:Toxy;
                            for poxy = K_Toxy(rem(Toxy, K_Toxy) == 0)
                                K_nof = 1:Nof;
                                for pof = K_nof(rem(Nof, K_nof) == 0)
                                    comp = comp_roof(Nixy, Tixy, Nif, Nof, Nnp, Npar, ...
                                       pixy, pkexf, pgri, pof, poxy, ...
                                       t, S2, f);
                                   plot(ctc, min(comp, ctc*f*(32/8)), '*')
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
%%
saveas(fig,'rooflineFPGA.pdf');
system('pdfcrop rooflineFPGA.pdf rooflineFPGA.pdf');