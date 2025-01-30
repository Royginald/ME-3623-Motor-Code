
clear
clc

opengl software
motor = MotorClass(10, 1);

num_plot_points = 200;
plot_data = zeros([2, num_plot_points]);
time_step = 0.05;
end_loop = false;

% -------------------- Local Variables -------------------- 

setpoint = 100;

% --------------------  End Variables  -------------------- 


tic;

while(not(end_loop))
    speed = motor.getSpeedFeedback();
    % disp(speed)
    new_time = toc;

    % -------------------- Control Algorithm -------------------- 

    u = -5;

    % --------------------   End Algorithm   -------------------- 

    motor.setMotorVoltage(u)

    plot_data(:, 1:num_plot_points - 1) = plot_data(:, 2:num_plot_points);
    plot_data(:, num_plot_points) = [new_time; speed];

    plot(plot_data(1, :), plot_data(2, :))
    drawnow;

    pause(0.5)

end

motor.shutdown();

function end_program()
    end_loop = true;
end