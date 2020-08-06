%% Parameters
alpha = 1e-4 : 1e-4 : 1;
Nkx = 3;
Nky = 3;
Nof = [32;16;24;32;64;96;160;320;1280];
Nof = sort(Nof, 'descend');
res = zeros(1, length(alpha));
col = {'black'; [0.4 0.4 0.4]; [0.4940, 0.1840, 0.5560]; 'blue'; 'cyan';...
    'green'; 'yellow'; 'magenta'; [0.8500, 0.3250, 0.0980]};
res_5 = zeros(length(Nof), 1);
%% Figure properties
f = figure('visible','off');
set(gca,'yscale','log')
hold on;
xlabel('alpha')
ylabel('Reduction factors')
lgd = legend('show');
%% Fill the figure
for j = 1:length(Nof)
    const = Nkx * Nky / Nof(j);
    for i = 1 : length(alpha)
        res(i) = (const + 1)/(const + alpha(i));
        if (alpha(i) == 0.25)
            res_5(j) = res(i);
        end
    end
    plot(alpha, res, 'Color', col{j}, 'DisplayName', ['Nof = ', num2str(Nof(j))]);
    drawnow
end

%% Save figure
saveas(f,'RedFactor.pdf');
system('pdfcrop RedFactor.pdf RedFactor.pdf');