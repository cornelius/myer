#!/usr/bin/python

import sys
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.dates as mdates

if len(sys.argv) != 2:
  print "Usage: plot-data.py <csv-file>"
  sys.exit(1)

csv_file = sys.argv[1]

days, values = np.loadtxt(csv_file, unpack=True, delimiter=",",
  converters={ 0: mdates.strpdate2num('%Y-%m-%d')})

fmt = mdates.DateFormatter('%Y-%m-%d')
loc = mdates.WeekdayLocator(byweekday=mdates.MONDAY)

ax = plt.axes()
ax.xaxis.set_major_formatter(fmt)
ax.xaxis.set_major_locator(loc)

plt.bar(days, values, align="center", linewidth=0, width=0.6, color="green",
        antialiased=True)

plt.grid(True)

fig = plt.figure(1)
fig.autofmt_xdate()

plt.show()
