
# need the keyboard module: pip3 install keyboard
# need the labjack module: python -m pip install labjack-ljm
# https://support.labjack.com/docs/python-for-ljm-windows-mac-linux


from labjack_T4_functions import motor_class

import keyboard

motor = motor_class()

while(True):
    speed = motor.get_speed_feedback()

    # -------------------- Control Algorithm -------------------- 

    u = 5

    # -------------------- End Algorithm -------------------- 

    motor.set_motor_voltage(u)
    print(u)

    if keyboard.is_pressed("q"):
        break

motor.shutdown()
