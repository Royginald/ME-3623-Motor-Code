
from labjack import ljm
import sys
from numpy import pi

class motor_class:

    def __init__(self, min_voltage, max_voltage, dir=False):
        try:
            self.handle = ljm.openS("ANY","ANY","ANY")
        except Exception as e:
            print(e)
            print("Error: No Labjack Found")
            sys.exit()

        self.SLP_pin = "DIO5"
        self.IN1_pin = "DIO7"
        self.IN2_pin = "DIO6"

        self.Speed_feedback_pin = "AIN0"
        self.Position_feedback_pin = "AIN3"
        self.Current_feedback_pin = "AIN4"

        self.max_voltage = max_voltage
        self.min_voltage = min_voltage
        self.flip_direction = dir
 
        self.current_scale = 10000 / 1.011667 / 2000 # A / V           
        self.speed_scale = 1/0.0286                  # rad/s / volt
        self.position_scale = 1/max_voltage * 2 * pi # rad / volt

        self.clock_roll_value = 8000

        self.max_FIO_voltage = 3.3

        try: # Set up PWM clock values
            ljm.eWriteName(self.handle, "DIO_EF_CLOCK0_ENABLE", 0)
            ljm.eWriteName(self.handle, "DIO_EF_CLOCK0_DIVISOR", 1 )
            ljm.eWriteName(self.handle, "DIO_EF_CLOCK0_ROLL_VALUE", self.clock_roll_value)
            ljm.eWriteName(self.handle, "DIO_EF_CLOCK0_ENABLE", 1)

            ljm.eReadName(self.handle, self.Current_feedback_pin)
        except Exception as e:
            print(e)

    def get_serial_number(self):
        try:
            return ljm.eReadName(self.handle, "SERIAL_NUMBER")
        except Exception as e:
            print(e)

    def write_voltage(self, pin, value): # Write voltage to DAC pins
        try:
            ljm.eWriteName(self.handle, pin, value)
        except Exception as e:
            print(e)

    def read_voltage(self, pin): # Read voltage from AIN pins
        try:
            return ljm.eReadName(self.handle, pin)
        except Exception as e:
            print(e)
    
    def get_current_feedback(self): # Read motor current in amps
        try:
            return ljm.eReadName(self.handle, self.Current_feedback_pin) * self.current_scale
        except Exception as e:
            print(e)
    
    def get_speed_feedback(self): # Read speed in radians per second
        try:
            return ljm.eReadName(self.handle, self.Speed_feedback_pin) * self.speed_scale
        except Exception as e:
            print(e)
    
    def get_position_feedback(self): # Read position in radians
        try:
            return ljm.eReadName(self.handle, self.Position_feedback_pin) * self.position_scale
        except Exception as e:
            print(e)

    def set_motor_voltage(self, voltage): # Write voltage applied to the motor
        if (voltage > 0) ^ self.flip_direction:
            pin_on = self.IN1_pin
            pin_off = self.IN2_pin
        else:
            pin_on = self.IN2_pin
            pin_off = self.IN1_pin

        voltage = abs(voltage)

        if abs(voltage) > self.max_voltage:
            voltage = self.max_voltage

        self.Voltage_setpoint = voltage

        if voltage < self.min_voltage:
            try:
                ljm.eWriteName(self.handle, self.SLP_pin, 1) # Set motor driver to sleep mode

                ljm.eWriteName(self.handle, pin_off + "_EF_ENABLE", 0)
                ljm.eWriteName(self.handle, pin_off + "_EF_INDEX", 0)
                ljm.eWriteName(self.handle, pin_off + "_EF_CONFIG_A", 0)
                ljm.eWriteName(self.handle, pin_off + "_EF_ENABLE", 1)

                ljm.eWriteName(self.handle, pin_on + "_EF_ENABLE", 0)
                ljm.eWriteName(self.handle, pin_on + "_EF_INDEX", 0)
                ljm.eWriteName(self.handle, pin_on + "_EF_CONFIG_A", 0)
                ljm.eWriteName(self.handle, pin_on + "_EF_ENABLE", 1)
            except Exception as e:
                print(e)
        else:
            match self.get_serial_number(): # Pick the right voltage correction polynomial
                case 440010323.0:
                    poly = self.poly_1
                case 440010328.0:
                    poly = self.poly_2
                case 440010347.0:
                    poly = self.poly_3
                case 440011438.0:
                    poly = self.poly_4
                case _:
                    poly = 0
                    print("Error: Labjack not Recognised")

            config = int(poly(voltage) / self.max_voltage * self.clock_roll_value)

            try:
                ljm.eWriteName(self.handle, self.SLP_pin, 1) # Set motor driver to normal mode

                ljm.eWriteName(self.handle, pin_off + "_EF_ENABLE", 0)
                ljm.eWriteName(self.handle, pin_off, 0)

                ljm.eWriteName(self.handle, pin_on + "_EF_ENABLE", 0)
                ljm.eWriteName(self.handle, pin_on + "_EF_INDEX", 0)
                ljm.eWriteName(self.handle, pin_on + "_EF_CONFIG_A", config)
                ljm.eWriteName(self.handle, pin_on + "_EF_ENABLE", 1)
            except Exception as e:
                print(e)
    
    def shutdown(self): # shutdown the Labjack
        try:
            ljm.eWriteName(self.handle, self.IN1_pin + "_EF_ENABLE", 0)
            ljm.eWriteName(self.handle, self.IN2_pin + "_EF_ENABLE", 0)
            ljm.eWriteName(self.handle, self.IN1_pin, 0)
            ljm.eWriteName(self.handle, self.IN2_pin, 0)
            ljm.eWriteName(self.handle, self.SLP_pin, 0)
            ljm.close(self.handle)
        except Exception as e:
            print(e)

    def poly_1(self, x):
        return 0.0908*x**3 - 2.0504*x**2 + 15.659*x - 31.945
    
    def poly_2(self, x):
        return 0.0745*x**3 - 1.6086*x**2 + 12.040*x - 23.039
    
    def poly_3(self, x):
        return 0.0867*x**3 - 2.0122*x**2 + 15.854*x - 33.577
    
    def poly_4(self, x):
        return -0.0334*x**4 + 1.0316*x**3 - 11.762*x**2 + 59.018*x - 101.96
    
    def poly_test(self, x):
        return x

    
        
