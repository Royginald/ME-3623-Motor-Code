
from labjack import ljm
import sys

class motor_class:

    def __init__(self, max_voltage, min_voltage, dir=False):
        try:
            self.handle = ljm.openS("ANY","ANY","ANY")
        except Exception as e:
            print(e)
            print("No Labjack Found")
            sys.exit()

        self.SLP_pin = "DIO5"
        self.IN1_pin = "DIO7"
        self.IN2_pin = "DIO6"

        self.Current_feedback_pin = "AIN2"
        self.Speed_feedback_pin = "AIN0"
        self.Position_feedback_pin = "AIN3"

        self.current_scale = 100 # mA / A
        self.speed_scale = 1/0.0286 # rad/s / volt
        self.position_scale = 4.77 # rad / volt

        self.clock_roll_value = 8000

        self.flip_direction = dir
        self.max_FIO_voltage = 3.3
        self.max_voltage = max_voltage
        self.min_voltage = min_voltage

        try:
            ljm.eWriteName(self.handle, "DIO_EF_CLOCK0_ENABLE", 0)
            ljm.eWriteName(self.handle, "DIO_EF_CLOCK0_DIVISOR", 1 )
            ljm.eWriteName(self.handle, "DIO_EF_CLOCK0_ROLL_VALUE", self.clock_roll_value)
            ljm.eWriteName(self.handle, "DIO_EF_CLOCK0_ENABLE", 1)
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

        if voltage > self.max_voltage:
            voltage = self.max_voltage

        if voltage < self.min_voltage:
            try:
                ljm.eWriteName(self.handle, self.SLP_pin, 0) # Set motor driver to sleep mode
            except Exception as e:
                print(e)
        else:
            config = int(voltage / self.max_voltage * self.clock_roll_value)

            try:
                ljm.eWriteName(self.handle, self.SLP_pin, 1)# Set motor driver to normal mode

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

    
        
