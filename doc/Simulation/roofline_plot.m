%% Parameter
ctc = 0:0.001:100;
f = 0.1;
dsp = 112;
hp = 2;
BW = 16;
Npar = 8;
Nnp = 2;
max_mem = 5570e3;
%% Computation
roof = roofline(f, dsp, BW, hp, ctc);
%%
f = figure('visible','on');
hold on;
xlabel('CTC ratio (FLOP/Byte)')
ylabel('Attainable performance (GFLOPS)')
title('Cyclone V SE 5CSEBA6U23I7 roofline');
plot(ctc, roof, 'linewidth', 2)
saveas(f,'rooflineFPGA.pdf');
system('pdfcrop rooflineFPGA.pdf rooflineFPGA.pdf');
%% Do the DSE
for Tixy = [1 7 14 28 56 112 224]
    if (internal_mem(Tixy, Npar, Nnp, BW) <= max_mem)
    end
end