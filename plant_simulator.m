clc
clf

system_num = 4;

T_s = 2.5; % sec
PO = 14; % percent

z = abs(log(PO/100))/(pi^2 + log(PO/100)^2)^0.5

file_name = append("Motor_data Sys ", string(system_num), " 5V step.csv");

step_data = readmatrix(file_name);

respOpt = RespConfig("Amplitude", 5);

switch system_num
    case 1
        % Sys 1
        R_m = 10.9;
        L_m = 0.458/1000;
        J = 8.23525 * 10^-5;
        B_real = 1.25236 * 10^-4;
        K_t = 0.038164;
        K_m = 1/27.788722305;

    case 2
        % Sys 2
        R_m = 7.8;
        L_m = 0.485/1000;
        J = 0.0002585965222;
        B_real = 3.58328 * 10^-4;
        K_t = 0.038164;
        K_m = 1/27.788722305;

    case 3
        % Sys 3
        R_m = 7.8;
        L_m = 0.468/1000;
        J = 8.23525 * 10^-5;
        B_real = 4.4448 * 10^-4;
        K_t = 0.038164;
        K_m = 1/27.788722305;

    case 4
        % Sys 4
        R_m = 7.6;
        L_m = 0.446/1000;
        J = 0.0002585965222;
        B_real = 4.55109 * 10^-4;
        K_t = 0.038164;
        K_m = 1/27.788722305;
end

tau = J/(B_real + K_t * K_m / R_m);
K_p = K_t / (R_m*B_real + K_t*K_m);

% First order
s = tf('s');
T = K_p / (tau * s + 1);

% Second order
A = K_t / L_m / J;
B = ( L_m*B_real + R_m * J ) / L_m / J;
C = ( R_m * B_real + K_t * K_m ) / L_m / J;
H = tf(A, [1, B, C]);

[y, t] = step(H, step_data(end,1), respOpt);

K_i = 16 * tau / (T_s^2 * z^2 * K_p)
K_c = ( 8 * tau / T_s - 1 ) / K_p

respOpt = RespConfig("Amplitude", 50);

controld = feedback((K_c + K_i/s) * T, 1)

test = 1/ (0.3278 * s^2 + 2.622 * s + 15.01)

[y, t] = step(controld, respOpt);
stepinfo(y, t)

% max(y)/50

hold on
% plot(step_data(:,1), step_data(:,2))
plot(t, y)
grid on









