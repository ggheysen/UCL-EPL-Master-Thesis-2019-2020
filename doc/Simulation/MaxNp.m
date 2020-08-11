Npar = 2:1280;
Nnp = zeros(1, length(Npar));
BS = 16;
for i = 1:length(Npar)
    Nnp(i) = (Npar(i) * BS)/(log2(Npar(i)) +  BS);
end
f = figure('visible','off');
hold on;
xlabel('Npar')
ylabel('Maximum Nnp')
plot(Npar(1:64), Nnp(1:64));
saveas(f,'MaxNP.pdf');
system('pdfcrop MaxNP.pdf MaxNP.pdf');
%% Min compression possible 
min_compr = 1 - (Nnp ./ Npar);
f = figure('visible','off');
hold on;
xlabel('Npar')
ylabel('Minimal ratio of pruned weights')
plot(Npar(min_compr < 1), min_compr(min_compr < 1));
saveas(f,'MinCompr.pdf');
system('pdfcrop MinCompr.pdf MinCompr.pdf');