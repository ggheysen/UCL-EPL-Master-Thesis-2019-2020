%% 
start = -7;
ecart = 0.0001;
en = 7;
interval = start:ecart:en;
figure, hold on;
plot(interval, tanh(interval), 'b', 'DisplayName', 'tanh', 'LineWidth',2);
plot(interval, sigmoid(interval), '-.r', 'DisplayName', 'sigmoid', 'LineWidth',2);
plot(interval, relu(interval), '--g', 'DisplayName', 'ReLU', 'LineWidth',2);
plot(interval, relu6(interval), ':k', 'DisplayName', 'ReLU6', 'LineWidth',2);
%%
function res = sigmoid(x)
    res = 1./(1 + exp(-x));
end

function res = relu(x)
    res = zeros(length(x), 1);
    res(x>0) = x(x>0);
end

function res = relu6(x)
    res = zeros(length(x), 1);
    res(x>0) = x(x>0);
    res(x>6) = 6;
end