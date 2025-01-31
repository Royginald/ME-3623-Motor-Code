
clear
clc
close all

motor = MotorClass(10, 1);

num_plot_points = 200;
plot_data = zeros([2, num_plot_points]);
time_step = 0.05;
end_loop = false;
fig = figure('KeyPressFcn', @keyPressCallback);

% -------------------- Local Variables -------------------- 

setpoint = 100;

% --------------------  End Variables  -------------------- 

tic;

while(not(end_loop))
    new_time = toc;
    speed = motor.getSpeedFeedback();

    % -------------------- Control Algorithm -------------------- 

    u = 5;

    % --------------------   End Algorithm   -------------------- 

    motor.setMotorVoltage(u)

    plot_data(:, 1:num_plot_points - 1) = plot_data(:, 2:num_plot_points);
    plot_data(:, num_plot_points) = [new_time; speed];

    plot(plot_data(1, :), plot_data(2, :))
    grid on
    drawnow;

    pause(time_step - toc + new_time)
end

% close(fig)
motor.shutdown();

% Function to check if q key is pressed from figure
function keyPressCallback(~, event)
    if event.Key == 'q'
        assignin('base', 'end_loop', true);
    end
end

