
clear
clc
close all

% Set up motor
motor = labjack_T4_functions(3, 10);

% Plotting Settings
num_plot_points = 200;
plot_data = zeros([2, num_plot_points]);
time_step = 0.05;
end_loop = false;
fig = figure('KeyPressFcn', @keyPressCallback);
y_range = [0, 0];

% -------------------- Local Variables -------------------- 

K_c = 0.0382;
K_i = 0.4684;

save_data = true;
setpoint = 100; % rad/s

sum = 0;

% --------------------  End Variables  -------------------- 

% Get start Time
tic;

while(not(end_loop))
    % Get time and current speed
    new_time = toc;
    speed = motor.get_speed_feedback(); % Returns speed in radians per second
    position = motor.get_position_feedback();
    current = motor.get_current_feedback();

    % -------------------- Control Algorithm -------------------- 

    error = setpoint - speed;
    sum = sum + error * time_step;
    control_action = error * K_c + sum * K_i;

    % --------------------   End Algorithm   -------------------- 

    % Set voltage applied to motor
    motor.set_motor_voltage(control_action)

    % Update data to be plotted
    plot_data(:, 1:num_plot_points - 1) = plot_data(:, 2:num_plot_points);
    plot_data(:, num_plot_points) = [new_time; speed];
    
    % Plot new data
    plot(plot_data(1, :), plot_data(2, :))

    y_range = [min([y_range(1), plot_data(2, :)]), max([y_range(2), plot_data(2, :)])];
    axis([plot_data(1, 1) plot_data(1, end) y_range(1)*1.1 y_range(2)*1.1])
    grid on
    drawnow;

    %  Wait until time_step time has passed
    pause(time_step - toc + new_time)
end

% Turn off motor
motor.shutdown();

% Save data
if save_data
    writematrix(plot_data', 'Motor_data.csv')
end

% Function to check if q key is pressed from figure
function keyPressCallback(~, event)
    if event.Key == 'q'
        assignin('base', 'end_loop', true);
    end
end

