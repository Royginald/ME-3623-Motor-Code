
# need the matplotlib module: pip install matplotlib
# need the keyboard module: pip3 install keyboard
# need the labjack module: python -m pip install labjack-ljm
# https://support.labjack.com/docs/python-for-ljm-windows-mac-linux


from labjack_T4_functions import motor_class

import keyboard
import matplotlib.pyplot as plt
import time
import csv
from numpy import zeros, concatenate, savetxt, transpose, sin, cos

# Set up motor
motor = motor_class(3, 10)

# Plotting Settings
plt.close()
num_plot_points = 900
plot_data = zeros((3, num_plot_points))
time_step = 0.05
plt.ion()
fig = plt.figure() 
# fig.set_size_inches(16, 9)
mngr = plt.get_current_fig_manager()
mngr.window.setGeometry(50,100,1800,900)

# fig.canvas.manager.window.attributes('-topmost', 1)
ax = fig.add_subplot(111) 
ax.grid(True)
line1, = ax.plot(plot_data[0][:], plot_data[1][:], 'b-')
line2, = ax.plot(plot_data[0][:], plot_data[2][:], 'r-')
y_range = [0, 0]

fig.tight_layout()

# -------------------- Local Variables -------------------- 

K_c = 0.0599
K_i = 0.4808

save_data = True
# setpoint = 100; # rad/s

sum = 0

ts = [5, 10, 15, 20, 25, 27.5, 28.75]

def setpoint(t):
    if t > ts[6]:
        return 30*cos(0.05*(t-ts[6]) + 0.1*(t-ts[6])**2 ) + 120
    elif t > ts[5]:
        return 60 + 72*(t-ts[5]) # end at 150
    elif t > ts[4]:
        return 150 - 36*(t-ts[4]) # end at 60
    elif t > ts[3]:
        return 60 + 18*(t-ts[3]) # end at 150
    elif t > ts[2]:
        return 60
    elif t > ts[1]:
        return 120
    elif t > ts[0]:
        return 80
    else:
        return 100


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

    error = setpoint(new_time) - speed
    sum += error * time_step
    control_action = K_c * error + K_i * sum

    # --------------------   End Algorithm   -------------------- 

    # Set voltage applied to motor
    motor.set_motor_voltage(control_action)

    # Update data to be plotted
    plot_data[:, :-1] = plot_data[:, 1:]
    plot_data[:, -1] = [new_time, speed, setpoint(new_time)]

    # Plot new data
    line1.set_xdata(plot_data[0, :])
    line1.set_ydata(plot_data[1, :])
    line2.set_xdata(plot_data[0, :])
    line2.set_ydata(plot_data[2, :])
    
    ax.set_xlim(plot_data[0][0], plot_data[0][-1])
    y_range = [min(concatenate( ([y_range[0]], plot_data[1][:]) )), max(concatenate( ([y_range[1]], plot_data[1][:]) ))]
    ax.set_ylim(y_range[0]*1.1, y_range[1]*1.1)
    
    fig.canvas.draw() 
    fig.canvas.flush_events() 
    plt.show()
    
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



