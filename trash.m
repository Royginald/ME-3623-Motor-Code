clear
clc

respOpt = RespConfig("Amplitude", 5.14);

J = 256.7837629;
B_real = 0.000005; %1.220292891;
K_m = 1/19.309;
K_t = 0.0038164;
R_m = 6.4;
L_m = 0.446 /1000;


tau = J/(B_real + K_t * K_m / R_m);
K_p = K_t / (R_m*B_real + K_t*K_m);

s = tf('s');

T = K_p / (tau * s + 1);

G = tf(K_t / R_m, [J, K_t * K_m / R_m]);

A = K_t / L_m * J^-1;
B = ( L_m*B_real + R_m * J ) / L_m / J;
C = ( R_m * B_real + K_t * K_m ) / L_m / J;

H = tf(A, [1, B, C]);

step(H, respOpt)







