# main.py -- put your code here!
from ws2812 import WS2812
import pyb
import time

data = [
    (0, 0, 0),
    (0, 0, 0),
    (0, 0, 0),
    (0, 0, 0),
    (0, 0, 0),
    (0, 0, 0),
    (0, 0, 0)
]

palette = [
	(128, 255, 0),   #0
	(0,   255, 128), #1
	(0,   255, 255), #2
	(0,   128, 255), #3
	(0,   0,   255), #4
	(128, 0,   255), #5
	(255, 0,   255), #6
	(255, 0,   128), #7
	(255, 0,   0),   #8
	(255, 128, 0),   #9
	(255, 255, 0),   #10
]


chain = WS2812(spi_bus=1, led_count=7)
accel = pyb.Accel()
events = []

#const 
alpha = 0.1
max_acc = 10
illum_ind = 0.2

mea_delay_ms            = 100    #100us
mea_averaging_time_ms   = 30000   #5 seconds
x = 0
filt_x = 0
filt_y = 0
filt_z = 0
prev_filt_x = 0
prev_filt_y = 0
prev_filt_z = 0

col_index = 0

f = open('log.txt', 'w')
f.write('time, x, filt_x, y, filt_y, z, filt_z, cold_index\n')

print (len(palette))

while True:
    x = accel.x()
    y = accel.y()
    z = accel.z()
		
    prev_filt_x = filt_x
    filt_x = prev_filt_x + alpha * (x - prev_filt_x) 
    dx = filt_x - prev_filt_x

    prev_filt_y = filt_y
    filt_y = prev_filt_y + alpha * (y - prev_filt_y) 
    dy = filt_y - prev_filt_y

    prev_filt_z = filt_z
    filt_z = prev_filt_z + alpha * (z - prev_filt_z) 
    dz = filt_z - prev_filt_z

    v = abs(dx) + abs(dy) + abs(dz)
    v = min(max_acc, v)                                        # cutting tops
    	
    col_index = int(v * len(palette) // max_acc)
    col_index = min(len(palette)-1, col_index)

    events.append( (v, dx, filt_x, dy, filt_y, dz, filt_z) )
    if len(events) >  mea_averaging_time_ms // mea_delay_ms:    # don't exceed 30 seconds
    	events.pop(0)
    	
    #print([x[0] for x in events])
    v_avg = sum([x[0] for x in events]) / float(len(events))
    
    print (time.ticks_ms(), v, v_avg, "dX:", dx, filt_x, " dY:", dy, filt_y, "dZ:", dz, filt_z, col_index)
    f.write("{0},{1},{2},{3},{4},{5},{6},{7}\n".format(time.ticks_ms(), x, filt_x, y, filt_y, z, filt_z, col_index))

    p = palette[col_index]
    if v_avg > 0.5:
    	illum_co = illum_ind
    else:
    	illum_co = 0
    	
    pixel = (int(p[0] * illum_co), int(p[1] * illum_co), int(p[2] * illum_co))
    for i in range(len(data)):
        data[i] = pixel
        #print(data[i])
	
    chain.show(data)
    pyb.delay(mea_delay_ms)


f.close()
