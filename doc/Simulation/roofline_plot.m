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
N_NP = {[2], [1 2 4 6 8], [2 4 8 12 16], [2]};
F = {{100}, {99.57, 103.36, 85.03, 82.61, 79.85}, {97.68, 82.65, 76.31, 66.01, 65.16}, {75.79}};
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
best_ctc = 0;
best_perf = 0;
best_Npar = 0;
best_Nnp = 1;
best_toxy = 0;
best_tixy = 0;
best_pixy = 0;
best_pkexf = 0;
best_pgri = 0;
best_poxy = 0;
best_pof = 0;
best_frec = 0;
%K_Npar = 1:Nif;
%n_npar = K_Npar(rem(Nif, K_Npar)==0);
%disp(length(n_npar))
n_par = [4 8 16 32];
for i_Npar = 1:length(n_par)
    Npar = n_par(i_Npar);
    disp('new npar')
    disp(Npar)
    %K_np = 1:Npar;
    %n_np = K_Npar(rem(Npar, K_Npar)==0);
    n_np = N_NP{i_Npar};
    for i_Nnp = 1:length(n_np)
        Nnp = n_np(i_Nnp);
        if ((Nnp/Npar) > best_Nnp)
            break
        end
        f_par_np = F{i_Npar}{i_Nnp}/1000;
        for Toxy_i = [1 7 14 28 56 112 224]
            Tixy = max(Nkxy +  S.*(Toxy_i - 1) );
            Toxy = Tixy - Nkxy + 2;
            if (internal_mem(Tixy, Toxy, Npar, Nnp, BW) <= max_mem)
                ctc = ctc_ratio(Noxy, Nif,  Nof, Toxy_i, t, S2, Nnp, Npar, BW);
                % 2: loop over the unrolling parameters
                K_Tixy = 1:Tixy;
                n_pix = K_Tixy(rem(Tixy, K_Tixy) == 0);
                for pixy = n_pix
                    K_par = 1:Npar;
                    for pkexf = K_par(rem(Npar, K_par) == 0)
                        Ngri = 1;
                        K_gri = 1:Ngri;
                        for pgri = K_gri(rem(Ngri, K_gri) == 0)
                            K_Toxy = 1:Toxy;
                            for poxy = K_Toxy(rem(Toxy, K_Toxy) == 0)
                                K_nof = 1:Nof;
                                for pof = K_nof(rem(Nof, K_nof) == 0)
                                    comp = comp_roof(Nixy, Tixy, Nif, Nof, Nnp, Npar, ...
                                       pixy, pkexf, pgri, pof, poxy, ...
                                       t, S2, f_par_np);
                                   perf = min(comp, ctc*f_par_np*(32/8));
                                   if (sum(perf <= roof) > 1)
                                       scatter(ctc, min(comp, ctc*f_par_np*(32/8)), 'filled');
%                                        if (perf > best_perf)
%                                            best_perf = perf;
%                                            best_ctc = ctc;
%                                            best_Npar = Npar;
%                                            best_Nnp = Nnp;
%                                            best_toxy = Toxy;
%                                            best_tixy = Tixy;
%                                            best_pixy = pixy;
%                                            best_pkexf = pkexf;
%                                            best_pgri = pgri;
%                                            best_poxy = poxy;
%                                            best_pof = pof;
%                                            best_freq = f_par_np;
%                                        elseif (perf == best_perf && ctc > best_ctc)
%                                            best_perf = perf;
%                                            best_ctc = ctc;
%                                            best_Npar = Npar;
%                                            best_Nnp = Nnp;
%                                            best_toxy = Toxy;
%                                            best_tixy = Tixy;
%                                            best_pixy = pixy;
%                                            best_pkexf = pkexf;
%                                            best_pgri = pgri;
%                                            best_poxy = poxy;
%                                            best_pof = pof;
%                                        else
                                       if (perf - best_perf > 0.1 && (Npar > best_Npar ...
                                               || (Nnp/Npar) < best_Nnp))
                                           best_perf = perf;
                                           best_ctc = ctc;
                                           best_Npar = Npar;
                                           best_Nnp = Nnp/Npar;
                                           best_toxy = Toxy;
                                           best_tixy = Tixy;
                                           best_pixy = pixy;
                                           best_pkexf = pkexf;
                                           best_pgri = pgri;
                                           best_poxy = poxy;
                                           best_pof = pof;
                                           best_frec = f_par_np;
                                       elseif (perf > best_perf && (Npar >= best_Npar ...
                                               || (Nnp/Npar) <= best_Nnp))
                                           best_perf = perf;
                                           best_ctc = ctc;
                                           best_Npar = Npar;
                                           best_Nnp = Nnp/Npar;
                                           best_toxy = Toxy;
                                           best_tixy = Tixy;
                                           best_pixy = pixy;
                                           best_pkexf = pkexf;
                                           best_pgri = pgri;
                                           best_poxy = poxy;
                                           best_pof = pof;
                                           best_frec = f_par_np;
                                       elseif (perf == best_perf && (Npar >= best_Npar ...
                                               || (Nnp/Npar) <= best_Nnp && ctc < best_ctc))
                                           best_perf = perf;
                                           best_ctc = ctc;
                                           best_Npar = Npar;
                                           best_Nnp = Nnp/Npar;
                                           best_toxy = Toxy;
                                           best_tixy = Tixy;
                                           best_pixy = pixy;
                                           best_pkexf = pkexf;
                                           best_pgri = pgri;
                                           best_poxy = poxy;
                                           best_pof = pof;
                                           best_frec = f_par_np;
                                      end
                                   end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    disp('current best res')
    disp(best_Npar)
    disp(best_Nnp)
    disp(best_perf)
end
%%
save('data.mat', 'best_ctc', 'best_perf', 'best_Npar', 'best_Nnp', 'best_toxy', ...
    'best_tixy', 'best_pixy', 'best_pkexf', 'best_pgri', 'best_poxy', 'best_pof', ...
    'best_frec');
saveas(fig,'rooflineFPGA.pdf');
system('pdfcrop rooflineFPGA.pdf rooflineFPGA.pdf');