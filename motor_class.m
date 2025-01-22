
% Labjack U3-HV can read 10.3893 volts at max from AIN channels

classdef motor_class < handle
    properties
        ljasm = NET.addAssembly('LJUDDotNet');
        ljudObj = LabJack.LabJackUD.LJUD;
        lj_handle
        aEnableTimers
        aTimerModes
        timerClockBaseIndex
        aTimerValues
        max_voltage
    end

    methods
        function init_U3(obj) 
            try
                % Open the first found LabJack U3.
                [~, ljh] = obj.ljudObj.OpenLabJackS('LJ_dtU3', 'LJ_ctUSB', '0', true, 0);
                obj.lj_handle = ljh;
            
                % assignments are in the factory default condition.
                obj.ljudObj.ePutS(obj.lj_handle, 'LJ_ioPIN_CONFIGURATION_RESET', 0, 0, 0);
                disp("Connected to U3")
            catch E
                disp(['Error: ' E.message])
            end

            obj.aEnableTimers = NET.createArray('System.Int32', 2);
            obj.aTimerModes = NET.createArray('System.Int32', 2);

            obj.aEnableTimers(1) = 1;  % Enable Timer0 (uses FIO4).
            obj.aEnableTimers(2) = 1;  % Enable Timer1 (uses FIO5).

            obj.timerClockBaseIndex = obj.ljudObj.StringToConstant('LJ_tc12MHZ');  % Base clock is 48 MHz with divisor support, so Counter0 is not available.

            obj.aTimerModes(1) = obj.ljudObj.StringToConstant('LJ_tmPWM16');  % Timer0 is 8-bit PWM output. Frequency is 1M/256 = 3906 Hz.
            obj.aTimerModes(2) = obj.ljudObj.StringToConstant('LJ_tmPWM16');  % Timer1 is 8-bit PWM output. Frequency is 1M/256 = 3906 Hz.

            obj.aTimerValues(1) = 0;  % Set PWM8 duty-cycle to 0%.
            obj.aTimerValues(2) = 0;  % Set PWM8 duty-cycle to 0%.

            obj.ljudObj.eTCConfig(obj.lj_handle, obj.aEnableTimers, 0, 4, obj.timerClockBaseIndex, 1, obj.aTimerModes, obj.aTimerValues, 0, 0);

            disp('Timers enabled.')
        end

        function set_max_voltage(obj, max_V)
            obj.max_voltage = max_V;
        end
        
        % % Enable voltage control of motor
        % function motor_on(obj)
        %     disp(obj)
        %     obj.ljudObj.eDAC(obj.lj_handle, 1, 5, 0, 0, 0);
        % end
        % 
        % % Disable voltage control of motor
        % function motor_off(obj)
        %     obj.ljudObj.eDAC(obj.lj_handle, 1, 0, 0, 0, 0);
        % end
        % 
        % % Set voltage control of motor
        % function motor_set(obj, state)
        %     if state
        %         obj.ljudObj.eDAC(obj.lj_handle, 1, 5, 0, 0, 0);
        %     else
        %         obj.ljudObj.eDAC(obj.lj_handle, 1, 0, 0, 0, 0);
        %     end
        % end
        
        % Set voltage applied to motor using DAC 0 and 1
        function set_voltage(obj, voltage)
            if voltage > 0
                obj.ljudObj.eDAC(obj.lj_handle, 0, abs(voltage)*5/12, 0, 0, 0);
                obj.ljudObj.eDAC(obj.lj_handle, 1, 0, 0, 0, 0);
            else
                obj.ljudObj.eDAC(obj.lj_handle, 0, 0, 0, 0, 0);
                obj.ljudObj.eDAC(obj.lj_handle, 1, abs(voltage)*5/12, 0, 0, 0);
            end
        end

        % Set PWM signal to motor using FIO 4 and 5
        function set_PWM(obj, voltage)
            if voltage < 0
                obj.aTimerValues(1) = int32( 65535 - 65535 * abs(voltage) / obj.max_voltage );
                obj.aTimerValues(2) = 65535;
            else
                obj.aTimerValues(1) = 65535;
                obj.aTimerValues(2) = int32( 65535 - 65535 * abs(voltage) / obj.max_voltage );
            end

            obj.ljudObj.eTCConfig(obj.lj_handle, obj.aEnableTimers, 0, 4, obj.timerClockBaseIndex, 48, obj.aTimerModes, obj.aTimerValues, 0, 0);
        end
        
        function speed = get_speed(obj) 
            % will be connected to AIN0
            voltage = 0.0;
            [~, voltage] = obj.ljudObj.eAIN(obj.lj_handle, 0, 31, voltage, 0, 0, 0, 0);
            speed = voltage / -0.0286; % Rad/s
        end

        function speed = get_speed_voltage(obj) 
            % will be connected to AIN0
            voltage = 0.0;
            [~, voltage] = obj.ljudObj.eAIN(obj.lj_handle, 0, 31, voltage, 0, 0, 0, 0);
            speed = -voltage; % Volts
        end
        
        function position = get_position(obj)
            % will be connected to AIN1
            voltage = 0.0;
            [~, voltage] = obj.ljudObj.eAIN(obj.lj_handle, 1, 31, voltage, 0, 0, 0, 0);
            position = voltage / 4.77; % Radians
        end

        function position = get_position_voltage(obj)
            % will be connected to AIN1
            voltage = 0.0;
            [~, voltage] = obj.ljudObj.eAIN(obj.lj_handle, 1, 31, voltage, 0, 0, 0, 0);
            position = voltage; % Volts
        end
        
        function current = get_current(obj)
            % positive channel is 2, negative channel is 3 (differential meansurement)
            voltage_p = 0.0;
            voltage_n = 0.0;
            [~, voltage_p] = obj.ljudObj.eAIN(obj.lj_handle, 2, 31, voltage_p, 0, 0, 0, 0);
            [~, voltage_n] = obj.ljudObj.eAIN(obj.lj_handle, 3, 31, voltage_n, 0, 0, 0, 0);
            current = ( voltage_p - voltage_n ) / 0.5; % Amps
        end
    end
end

    