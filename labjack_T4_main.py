
# need the matplotlib module: pip install matplotlib
# need the keyboard module: pip3 install keyboard
# need the labjack module: python -m pip install labjack-ljm
# https://support.labjack.com/docs/python-for-ljm-windows-mac-linux


from labjack_T4_functions import motor_class

import keyboard
import matplotlib.pyplot as plt
import time
import csv
from numpy import zeros, concatenate, savetxt, transpose

# Set up motor
motor = motor_class(3, 10)

# Plotting Settings
num_plot_points = 200
plot_data = zeros((2, num_plot_points))
time_step = 0.05
plt.ion()
fig = plt.figure() 
ax = fig.add_subplot(111) 
ax.grid(True)
line1, = ax.plot(plot_data[0][:], plot_data[1][:], 'b-')
y_range = [0, 0]

# -------------------- Local Variables -------------------- 

save_data = True
setpoint = 100

# --------------------  End Variables  -------------------- 

# Get start Time
start_time = time.time()

while(True):
    # Get time and current speed
    new_time = time.time() - start_time
    speed = motor.get_speed_feedback() # Returns speed in radians per second
    position = motor.get_position_feedback()
    current = motor.get_current_feedback()

    # -------------------- Control Algorithm -------------------- 

    u = 5

    # --------------------   End Algorithm   -------------------- 

    # Set voltage applied to motor
    motor.set_motor_voltage(u)

    # Update data to be plotted
    plot_data[:, :-1] = plot_data[:, 1:]
    plot_data[:, -1] = [new_time, speed]

    # Plot new data
    line1.set_xdata(plot_data[0, :])
    line1.set_ydata(plot_data[1, :])
    ax.set_xlim(plot_data[0][0], plot_data[0][-1])
    y_range = [min(concatenate( ([y_range[0]], plot_data[1][:]) )), max(concatenate( ([y_range[1]], plot_data[1][:]) ))]
    ax.set_ylim(y_range[0]*1.1, y_range[1]*1.1)
    
    fig.canvas.draw() 
    fig.canvas.flush_events() 
    
    # End loop if q key is pressed
    if keyboard.is_pressed("q"):
        break

    if plot_data[0, 0] != 0:
        break

    # Wait until time_step time has passed
    while( (time.time() - start_time - new_time) < time_step ):
        pass

# Turn off motor
motor.shutdown()

# Save data
if save_data:
    savetxt('Motor_data.csv', transpose(plot_data), delimiter=',')



