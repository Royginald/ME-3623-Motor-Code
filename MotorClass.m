
classdef MotorClass
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
        function obj = MotorClass(max_voltage, min_voltage, dir)
            if nargin < 3
                dir = false;
            end
            obj.max_voltage = max_voltage;
            obj.min_voltage = min_voltage;
            obj.flip_direction = dir;
            obj.position_scale = 1 / max_voltage * 2 * pi; % rad / volt
            
            try
                [~, obj.handle] = LabJack.LJM.OpenS('T4', 'ANY', 'ANY', obj.handle);
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
        
        function writeVoltage(obj, pin, value)
            try
                LabJack.LJM.eWriteName(obj.handle, pin, value);
            catch ME
                disp(ME.message);
            end
        end
        
        function value = readVoltage(obj, pin)
            try
                [~, value] = LabJack.LJM.eReadName(obj.handle, pin);
            catch ME
                disp(ME.message);
                value = NaN;
            end
        end
        
        function current = getCurrentFeedback(obj)
            try
                current = LabJack.LJM.eReadName(obj.handle, obj.Current_feedback_pin, 0) * obj.current_scale;
            catch ME
                disp(ME.message);
                current = NaN;
            end
        end
        
        function speed = getSpeedFeedback(obj)
            try
                [~, value]= LabJack.LJM.eReadName(obj.handle, obj.Speed_feedback_pin, 0);
                speed = value * obj.speed_scale;
            catch ME
                disp(ME.message);
                speed = NaN;
            end
        end
        
        function position = getPositionFeedback(obj)
            try
                position = LabJack.LJM.eReadName(obj.handle, obj.Position_feedback_pin) * obj.position_scale;
            catch ME
                disp(ME.message);
                position = NaN;
            end
        end
        
        function setMotorVoltage(obj, voltage)
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
                config = floor(voltage / obj.max_voltage * obj.clock_roll_value);
                
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
    end
end
