
# need the matplotlib module: pip install matplotlib
# need the keyboard module: pip3 install keyboard
# need the labjack module: python -m pip install labjack-ljm
# https://support.labjack.com/docs/python-for-ljm-windows-mac-linux


from labjack_T4_functions import motor_class

import keyboard
import matplotlib.pyplot as plt
import time
from numpy import zeros

# Set up motor
motor = motor_class(1, 10)

# Plotting Settings
num_plot_points = 200
plot_data = zeros((3, num_plot_points))
time_step = 0.05
plt.ion()
fig = plt.figure() 
ax = fig.add_subplot(111) 
ax.grid(True)
line1, = ax.plot(plot_data[0][:], plot_data[1][:], 'b-')
line2, = ax.plot(plot_data[0][:], plot_data[2][:], 'r-')

# -------------------- Local Variables -------------------- 

setpoint = 100

# --------------------  End Variables  -------------------- 

# Get start Time
start_time = time.time()

while(True):
    # Get time and current speed
    # motor.loop_function()
    speed = motor.get_speed_feedback() # Returns speed in radians per second
    voltage = motor.get_voltage_feedback()
    new_time = time.time() - start_time

    # -------------------- Control Algorithm -------------------- 

    u = 5

    # --------------------   End Algorithm   -------------------- 

    # Set voltage applied to motor
    motor.set_motor_voltage(u)

    # Update data to be plotted
    plot_data[:, :-1] = plot_data[:, 1:]
    plot_data[:, -1] = [new_time, speed, voltage]

    # Plot new data
     
    line1.set_xdata(plot_data[0, :])
    line1.set_ydata(plot_data[1, :])
    line2.set_xdata(plot_data[0, :])
    line2.set_ydata(plot_data[2, :])
    ax.set_xlim(plot_data[0][0], plot_data[0][-1])
    ax.set_ylim(min(plot_data[1][:]), max(plot_data[1][:]))
    # ax.set_ylim(0, 10)
    
    fig.canvas.draw() 
    fig.canvas.flush_events() 
    

    # End loop if q key is pressed
    if keyboard.is_pressed("q"):
        break

    # Wait until time_step time has passed
    while( (time.time() - start_time - new_time) < time_step ):
        pass

# Turn off motor
motor.shutdown()








