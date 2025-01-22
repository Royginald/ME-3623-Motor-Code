
clear
clc

motor = MotorClass(10, 1);

num_plot_points = 200;
plot_data = zeros([2, num_plot_points]);
time_step = 0.05;

% -------------------- Local Variables -------------------- 

setpoint = 100;

% --------------------  End Variables  -------------------- 


tic;

while(true)
    speed = motor.getSpeedFeedback();
    new_time = toc;

    % -------------------- Control Algorithm -------------------- 

    u = 5;

    % --------------------   End Algorithm   -------------------- 

    motor.setMotorVoltage(u)

    plot_data(:, 1:num_plot_points - 1) = plot_data(:, 2:num_plot_points);
    plot_data(:, num_plot_points) = [new_time; speed];

    plot(plot_data(1, :), plot_data(2, :))
end

motor.shutdown();