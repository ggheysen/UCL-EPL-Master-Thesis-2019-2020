%% Memory parameters
ntotlayers = 21;
nsclayers = 1;
nbclayers = 17;
nt11clayers = 2;
bw_li = 8+8+11+11+1+3+11+11+2+(32*6);
max_fmi = 112*112*32;
max_fmo = 112*112*32;
max_k11 = 320*1280;
max_kdw = 3*3*6*160;
max_kpw = 160*6*320;
max_ksc = 3*3*32;
Npar = 1280;
Nnp = 1280;
alpha = Nnp/Npar;
%%  Axis
bw = 1:32;
maxmem = zeros(1, length(bw));
for i = 1: length(bw)
    maxmem(i) = (ntotlayers * bw_li) + ...
                (max_fmi * bw(i)) + ...
                (max_fmo * bw(i)) + ...
                (nsclayers * max_ksc * bw(i)) + ...
                (nbclayers * max_kdw * bw(i)) + ...
                (nbclayers * max_kpw  * alpha * (bw(i) + log2(Npar))) + ...
                ((nt11clayers + nbclayers) * alpha * max_k11 * (bw(i) + log2(Npar)));
end
maxmem = maxmem ./ (8*1024*1024);
disp(maxmem(16));
%%
f = figure('visible','off');
hold on;
xlabel('BW_{pixel}, BW_{weight}')
ylabel('Maximum external memory required [MB]')
plot(bw, maxmem)
saveas(f,'maxmem.pdf');
system('pdfcrop maxmem.pdf maxmem.pdf');