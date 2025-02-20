clear
clc

step_data = readmatrix("Motor_data Sys 2 5V step.csv");

respOpt = RespConfig("Amplitude", 5);

% Sys 2
R_m = 7.8;
L_m = 0.485/1000;
J = 258.5965222;
B_real = 3.58328*10^-5;
K_t = 0.0038164;
K_m = 1/27.788722305;

tau = J/(B_real + K_t * K_m / R_m);
K_p = K_t / (R_m*B_real + K_t*K_m);

s = tf('s');

T = K_p / (tau * s + 1);

A = K_t / L_m * J^-1;
B = ( L_m*B_real + R_m * J ) / L_m / J;
C = ( R_m * B_real + K_t * K_m ) / L_m / J;

H = tf(A, [1, B, C]);

figure(1)
step(H, respOpt)

figure(2)
plot(step_data(:,1), step_data(:,2))









