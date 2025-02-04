
classdef labjack_T4_functions
    properties
        handle = 0;
        SLP_pin = 'DIO5';
        IN1_pin = 'DIO7';
        IN2_pin = 'DIO6';
        
        Current_feedback_pin = 'AIN2';
        Speed_feedback_pin = 'AIN0';
        Position_feedback_pin = 'AIN3';
        
        max_voltage
        min_voltage
        flip_direction
        current_scale = 100; % mA / A
        speed_scale = 1 / 0.0286; % rad/s / volt
        position_scale
        clock_roll_value = 8000;
        max_FIO_voltage = 3.3;
    end
    
    methods
        function obj = labjack_T4_functions(min_voltage, max_voltage, dir)
            if nargin < 3
                dir = false;
            end
            obj.max_voltage = max_voltage;
            obj.min_voltage = min_voltage;
            obj.flip_direction = dir;
            obj.position_scale = 1 / max_voltage * 2 * pi; % rad / volt
            
            try
                [~, obj.handle] = LabJack.LJM.OpenS('ANY', 'ANY', 'ANY', obj.handle);
            catch ME
                disp(ME.message);
                disp('No LabJack Found');
                return;
            end
            
            try
                LabJack.LJM.eWriteName(obj.handle, 'DIO_EF_CLOCK0_ENABLE', 0);
                LabJack.LJM.eWriteName(obj.handle, 'DIO_EF_CLOCK0_DIVISOR', 1);
                LabJack.LJM.eWriteName(obj.handle, 'DIO_EF_CLOCK0_ROLL_VALUE', obj.clock_roll_value);
                LabJack.LJM.eWriteName(obj.handle, 'DIO_EF_CLOCK0_ENABLE', 1);
                disp("LabJack T4 Connected")
            catch ME
                disp(ME.message);
            end
        end

        function serial_number = get_serial_number(obj)
            try
                [~, serial_number] = LabJack.LJM.eReadName(obj.handle, "SERIAL_NUMBER", 0);
            catch ME
                disp(ME.message);
                serial_number = NaN;
            end
        end
        
        function write_voltage(obj, pin, value)
            try
                LabJack.LJM.eWriteName(obj.handle, pin, value);
            catch ME
                disp(ME.message);
            end
        end
        
        function value = read_voltage(obj, pin)
            try
                [~, value] = LabJack.LJM.eReadName(obj.handle, pin, 0);
            catch ME
                disp(ME.message);
                value = NaN;
            end
        end

        function current = get_current_feedback(obj)
            try
                current = LabJack.LJM.eReadName(obj.handle, obj.Current_feedback_pin, 0) * obj.current_scale;
            catch ME
                disp(ME.message);
                current = NaN;
            end
        end
        
        function speed = get_speed_feedback(obj)
            try
                [~, value] = LabJack.LJM.eReadName(obj.handle, obj.Speed_feedback_pin, 0);
                speed = value * obj.speed_scale;
            catch ME
                disp(ME.message);
                speed = NaN;
            end
        end
        
        function position = get_position_feedback(obj)
            try
                [~, value] = LabJack.LJM.eReadName(obj.handle, obj.Position_feedback_pin, 0) ;
                position = value * obj.position_scale;
            catch ME
                disp(ME.message);
                position = NaN;
            end
        end
        
        function set_motor_voltage(obj, voltage)
            if xor(voltage > 0, obj.flip_direction)
                pin_on = obj.IN1_pin;
                pin_off = obj.IN2_pin;
            else
                pin_on = obj.IN2_pin;
                pin_off = obj.IN1_pin;
            end
            
            voltage = abs(voltage);
            
            if voltage > obj.max_voltage
                voltage = obj.max_voltage;
            end
            
            if voltage < obj.min_voltage
                try
                    LabJack.LJM.eWriteName(obj.handle, obj.SLP_pin, 0); % Sleep mode
                catch ME
                    disp(ME.message);
                end
            else
                switch obj.get_serial_number()
                    case 440010323.0
                        poly = @(x) obj.poly_1(x);
                    case 440010328.0
                        poly = @(x) obj.poly_2(x);
                    case 440010347.0
                        poly = @(x) obj.poly_3(x);
                    case 440011438.0
                        poly = @(x) obj.poly_4(x);
                    otherwise
                        poly = 0;
                        disp("Error: Labjack not Recognised")
                end

                config = floor(poly(voltage) / obj.max_voltage * obj.clock_roll_value);
                
                try
                    LabJack.LJM.eWriteName(obj.handle, obj.SLP_pin, 1); % Normal mode
                    
                    LabJack.LJM.eWriteName(obj.handle, [pin_off, '_EF_ENABLE'], 0);
                    LabJack.LJM.eWriteName(obj.handle, pin_off, 0);
                    
                    LabJack.LJM.eWriteName(obj.handle, [pin_on, '_EF_ENABLE'], 0);
                    LabJack.LJM.eWriteName(obj.handle, [pin_on, '_EF_INDEX'], 0);
                    LabJack.LJM.eWriteName(obj.handle, [pin_on, '_EF_CONFIG_A'], config);
                    LabJack.LJM.eWriteName(obj.handle, [pin_on, '_EF_ENABLE'], 1);
                catch ME
                    disp(ME.message);
                end
            end
        end
        
        function shutdown(obj)
            try
                LabJack.LJM.eWriteName(obj.handle, [obj.IN1_pin, '_EF_ENABLE'], 0);
                LabJack.LJM.eWriteName(obj.handle, [obj.IN2_pin, '_EF_ENABLE'], 0);
                LabJack.LJM.eWriteName(obj.handle, obj.IN1_pin, 0);
                LabJack.LJM.eWriteName(obj.handle, obj.IN2_pin, 0);
                LabJack.LJM.eWriteName(obj.handle, obj.SLP_pin, 0);
                LabJack.LJM.Close(obj.handle);
                LabJack.LJM.CloseAll();
            catch ME
                disp(ME.message);
            end
        end
        
        function v = poly_1(obj, x)
            v = 0.0908*x^3 - 2.0504*x^2 + 15.659*x - 31.945;
        end

        function v = poly_2(obj, x)
            v = 0.0745*x^3 - 1.6086*x^2 + 12.040*x - 23.039;
        end

        function v = poly_3(obj, x)
            v = 0.0867*x^3 - 2.0122*x^2 + 15.854*x - 33.577;
        end

        function v = poly_4(obj, x)
            v = -0.0334*x^4 + 1.0316*x^3 - 11.762*x^2 + 59.018*x - 101.96;
        end

        function v = poly_test(obj, x)
            v = x;
        end
    end
end
