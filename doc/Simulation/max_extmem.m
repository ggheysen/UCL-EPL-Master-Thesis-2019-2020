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
%% BW
bw = 1:32;
maxmem = zeros(1, length(bw));
%% Determine max alpha possible
alpha = zeros(1, length(bw));
NPAR = zeros(1, length(bw));
for i = 1:length(bw)
    for j = 2:1280
        a = bw(i)/(bw(i) + log2(j));
        if isinteger(a*j)
            np_max = (a*j) - 1;
        else
            np_max = floor(a*j);
        end
        if (np_max / j) > alpha(i)
            alpha(i) = (np_max / j);
            NPAR(i) = j;
        end
    end
end

%%  Axis
for i = 1: length(bw)
    maxmem(i) = (ntotlayers * bw_li) + ...
                (max_fmi * bw(i)) + ...
                (max_fmo * bw(i)) + ...
                (nsclayers * max_ksc * bw(i)) + ...
                (nbclayers * max_kdw * bw(i)) + ...
                (nbclayers * max_kpw  * alpha(i) * (bw(i) + log2(NPAR(i)))) + ...
                ((nt11clayers + nbclayers) * alpha(i) * max_k11 * (bw(i) + log2(NPAR(i))));
end
maxmem = maxmem ./ (8*1024*1024);
%%
f = figure('visible','on');
hold on;
xlabel('BW_{pixel}, BW_{weight}')
ylabel('Maximum external memory required [MB]')
plot(bw, maxmem)
saveas(f,'maxmem.pdf');
system('pdfcrop maxmem.pdf maxmem.pdf');