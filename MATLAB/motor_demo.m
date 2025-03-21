
clc
clear
close all

%% User changable parameters

Setpoint = 5; % Units depend on simulink model
Motor_voltage = Setpoint;
% setpoint = @(t) static_sp(Setpoint, t);
setpoint = @(t) step_sp(7, 3, 2,t);

sp_plot = 4;

max_voltage = 10; % Volts, max voltage motor can run at
marker_size = 5; % Thinkness of lines in plot
num_data_points = 50; % Number of data points to display

R = 2.8; % Ohm
L = 0.005; % Henrys
J_m = 0.0000031777; % kg/m^2

mass = 400; % grams
radis = 0.080; % Meters
J_t = 1/2 * mass * radis^2; 

% K = 0.55;    % Controller gain 
K = 0.007; 
K_v = 305 * 2 * pi / 60; % rad/s / V, Motor voltage constant 
K_b = 1 / K_v;
K_m = 0.0374262; % Nm/A, Motor torque constant

N1 = 30;
N2 = 60;
N3 = 90;
N4 = 120;

Se = 4.77;
Sg = 0.0286;

sim_model_name = "motor_model";
sim_index = 10;

%% Inital Set up

% Set up motor
motor = motor_class;
motor.init_U3();
motor.set_max_voltage(max_voltage);
motor.set_PWM(0);
n = 0;
step = max_voltage /  4.77 * 360 / ( 2 * pi ) ;

% Make figure
fig = figure('Name', 'Measured Data', 'units', 'normalized', 'outerposition', [0 0 1 1]);
fontsize(fig, 24, "points")
pause(1)

% Make data storage array and its indexes
data = zeros(8, num_data_points);

time_pos             = 1;
speed_meas_pos       = 2;
turret_pos_meas_pos  = 3;
motor_voltage_pos    = 4;
speed_theo_pos       = 5;
position_theo_pos    = 6;
setpoint_pos         = 7;
encoder_voltage_pos  = 8;

% Simulink Model Parameters
Speed_feedback = 0;
Position_feedback = 0;
Speed_feedback_voltage = 0;
Position_feedback_voltage = 0;
Voltage_feedback = 0;


sim_voltage_pos = 1;
sim_speed_pos = 2;
% sim_position_pos = 4;
% sim_setpoint_pos = 1;

% Set up simulation from Simulink model
% simIn = Simulink.SimulationInput(sim_model_name);
% simIn = setModelParameter(simIn, 'StartTime', '0', 'StopTime', '0.3', 'SolverType', 'Fixed-step', 'Solver', 'ode4', 'FixedStep', string(0.01), FastRestart="off", SimulationMode="accelerator");

load_system(sim_model_name);
io = getlinio(sim_model_name);
sys_tf = linearize(sim_model_name, io);

sim_time = 0:0.1:1;
one_array = ones(1, length(sim_time));

tic
while(true)
    % Shift old data back in time
    data(:, 1:num_data_points-1) = data(:, 2:num_data_points);    

    % Read voltages from system
    Speed_feedback_voltage     = motor.get_speed_voltage();
    Position_feedback_voltage  = motor.get_position_voltage();

    % Calculate Measured values
    data(time_pos, num_data_points)            =  toc;
    data(speed_meas_pos, num_data_points)      =  Speed_feedback_voltage / Sg * 60 / ( 2 * pi ); % RPM
    data(turret_pos_meas_pos, num_data_points) = -Position_feedback_voltage / Se * N4 / N3 * 360 / (2 * pi); % Degrees
    data(encoder_voltage_pos, num_data_points) =  Position_feedback_voltage;
    % data(position_meas_pos, num_data_points)  = motor.get_position() * 360 / ( 2 * pi ); % Degrees
    data(setpoint_pos, num_data_points)        = setpoint(data(time_pos, num_data_points));

    % Simulate system
    sim_data = lsim(sys_tf, [data(setpoint_pos, num_data_points)  * one_array; Speed_feedback_voltage * one_array; ], 1:length(sim_time), [Speed_feedback_voltage / Sg, data(motor_voltage_pos, num_data_points) - 1 ]);
    
    % Simple Control Algorithum
    sim_data(sim_index, sim_voltage_pos) = data(setpoint_pos, num_data_points)* 2 * pi / 60 * Sg - Speed_feedback_voltage;

    % Get theoretical data from Transfer function
    data(motor_voltage_pos, num_data_points)  = sim_data(sim_index, sim_voltage_pos);
    data(speed_theo_pos, num_data_points)     = sim_data(sim_index, sim_speed_pos) * 60 / ( 2 * pi ); % RPM

    % Limit control action if too large
    if abs( data(motor_voltage_pos, num_data_points) ) > max_voltage
        data(motor_voltage_pos, num_data_points) = sign( data(motor_voltage_pos, num_data_points) ) * max_voltage;
    end
    
    % Send control action to motor
    motor.set_PWM(data(motor_voltage_pos, num_data_points));

    % % Set parameters for use in Simulink
    % Speed_feedback    = data(speed_meas_pos, num_data_points);
    % Position_feedback = data(position_meas_pos, num_data_points);
    % Voltage_feedback  = data(voltage_pos, num_data_points);
    
    % Plot results 
    figure(fig)

    subplot(2,2,1)
    hold on;
    plot(data(time_pos, :), data(speed_meas_pos, :), 'b', 'LineWidth', marker_size)
    % plot(data(time_pos, :), data(speed_theo_pos, :), 'c', 'LineWidth', marker_size)
    grid on
    xlim([ data(time_pos, 1) data(time_pos, end) ])
    ylabel("Motor Speed - RPM")
    xlabel("Time - Seconds", 'FontSize', 24)
    % legend({"Speed - Measured", "Speed - Theoretical"}, 'Location', 'southwest')
    % legend({"Speed - Measured"}, 'Location', 'southwest')
    ax = gca; 
    ax.FontSize = 16; 

    % subplot(2,2,2)
    % hold on;
    % plot(data(time_pos, :), data(turret_pos_meas_pos, :) * -N1/N2, 'r', 'LineWidth', marker_size)
    % % plot(data(time_pos, :), data(position_theo_pos, :), 'm', 'LineWidth', marker_size)
    % grid on
    % xlim([ data(time_pos, 1) data(time_pos, end) ])
    % ylim([ 0 80 ])
    % ylabel("Motor Position - degrees")
    % xlabel("Time - Seconds")
    % % legend({"Position - Measured", "Position - Theoretical"}, 'Location', 'southwest')
    % % legend({"Position - Measured"}, 'Location', 'southwest')
    % ax = gca; 
    % ax.FontSize = 16; 

    subplot(2,2,3)
    plot(data(time_pos, :), data(motor_voltage_pos, :), 'g', 'LineWidth', marker_size)
    grid on
    xlim([ data(time_pos, 1) data(time_pos, end) ])
    ylabel("Motor Voltage - Volts")
    xlabel("Time - Seconds")
    % legend({"Voltage"}, 'Location', 'southwest')
    ax = gca; 
    ax.FontSize = 16; 

    subplot(2,2,2)
    hold on;
    plot(data(time_pos, :), data(turret_pos_meas_pos, :), 'm', 'LineWidth', marker_size)
    % plot(data(time_pos, :), data(position_theo_pos, :), 'm', 'LineWidth', marker_size)
    grid on
    xlim([ data(time_pos, 1) data(time_pos, end) ])
    ylim([ -160 0 ])
    ylabel("Turret Position - degrees")
    xlabel("Time - Seconds")
    ax = gca; 
    ax.FontSize = 16; 

    subplot(2,2,4)
    hold on;
    plot(data(time_pos, :), data(encoder_voltage_pos, :), 'r', 'LineWidth', marker_size)
    % plot(data(time_pos, :), data(position_theo_pos, :), 'm', 'LineWidth', marker_size)
    grid on
    xlim([ data(time_pos, 1) data(time_pos, end) ])
    ylim([ 0 10 ])
    ylabel("Encoder voltage - Volts")
    xlabel("Time - Seconds")
    ax = gca; 
    ax.FontSize = 16; 

    subplot(2,2,sp_plot)
    plot(data(time_pos, :), data(setpoint_pos, :), 'k', 'LineWidth', marker_size)

    % legend({"Position - Measured", "Position - Theoretical"}, 'Location', 'southwest')
    % legend({"Position - Measured"}, 'Location', 'southwest')
    % plot(data(time_pos, :), data(setpoint_pos, :), "MarkerFaceColor", '#77AC30', 'LineWidth', marker_size)
    % grid on
    % xlim([ data(time_pos, 1) data(time_pos, end) ])
    % ylabel("Setpoint")
    % xlabel("Time - Seconds")
    % legend({"Setpoint"}, 'Location', 'southwest')
end


%% Functions

function sp = static_sp(sp, t)
    % sp = sp;
end

function sp = step_sp(max_sp, min_sp, period, t)
    % period is how long (is s) it takes to switch from max to min
    if mod(t, period * 2) > period
        sp = max_sp;
    else
        sp = min_sp;
    end
end




 


