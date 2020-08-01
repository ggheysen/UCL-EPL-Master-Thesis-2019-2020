%% Parameter
ctc = 0:0.001:100;
f = 0.05;
dsp = 112;
hp = 1;
BW = 32;
%% Computation
roof = roofline(f, dsp, BW, hp, ctc);
%%
f = figure('visible','off');
hold on;
xlabel('CTC ratio (FLOP/Byte)')
ylabel('Attainable performance (GFLOPS)')
title('Cyclone V SE 5CSEBA6U23I7 roofline');
plot(ctc, roof)
saveas(f,'rooflineFPGA.pdf');
system('pdfcrop rooflineFPGA.pdf rooflineFPGA.pdf');