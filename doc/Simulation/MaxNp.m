Npar = 1:32;
Nnp = zeros(1, length(Npar));
BS = 16;
for i = 1:length(Npar)
    if (Npar(i) * BS)/(log2(Npar(i)) +  BS) - floor((Npar(i) * BS)/(log2(Npar(i)) +  BS)) == 0
         Nnp(i) = ((Npar(i) * BS)/(log2(Npar(i)) +  BS)) - 1;
    else
         Nnp(i) = floor((Npar(i) * BS)/(log2(Npar(i)) +  BS));
    end
end
figure;
hold on;
xlabel('Npar')
ylabel('Maximum Nnp')
plot(Npar, Nnp);
saveas(gca,'MaxNP.pdf');
system('pdfcrop MaxNP.pdf MaxNP.pdf');