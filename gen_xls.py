#!/usr/bin/env python2
import os, re, string, urllib2
import numpy as np
#import matplotlib
#matplotlib.use('Agg')
#import matplotlib.pyplot as plt
from PIL import Image

from copy import deepcopy
from string import atoi,atof
from time import localtime, strftime, time, struct_time

from pyExcelerator import *
import traceback

round = lambda f,i=0: float(int(f*(10**i) + 0.5))/(10**i) if f > 0 else float(int(f*(10**i) - 0.5))/(10**i)


def wt_xls(dir_name):
    w = Workbook()

    font = Font()
    alignment = Alignment()
    alignment.horz = Alignment.HORZ_CENTER

    style = XFStyle()
    style.font = font
    style.alignment = alignment
##############################
    style.borders.left = 0
    style.borders.right = 0
    style.borders.top = 0
    style.borders.bottom = 0
##############################

    style0 = deepcopy(style)
    style0.font.bold = True
    style0.num_format_str = '0.00'

    stylef1 = deepcopy(style)
    stylef1.num_format_str = '0.0'

    stylef2 = deepcopy(style)
    stylef2.num_format_str = '0.00'

    stylep0 = deepcopy(style)
    stylep0.num_format_str = '0%'

    stylep2 = deepcopy(style)
    stylep2.num_format_str = '0.00%'

    styleim = deepcopy(style)
    styleim.num_format_str = '$#,##0'

    stylei = deepcopy(style)
    stylei.num_format_str = '#,##0'

    stylet = deepcopy(style0)
    stylet.font.height = 18*20

    stylel1 = deepcopy(style)
    stylel1.font.bold = True
    stylel1.pattern.pattern = Pattern.SOLID_PATTERN
    stylel1.pattern.pattern_fore_colour = 0x33
    stylel1.borders.right = 1
    stylel1.borders.bottom = 1

    stylel2_4 = deepcopy(style)
    stylel2_4.font.bold = True
    stylel2_4.pattern.pattern = Pattern.SOLID_PATTERN
    stylel2_4.pattern.pattern_fore_colour = 0x33
    stylel2_4.borders.right = 1

    stylel2 = deepcopy(stylel2_4)
    stylel2.borders.top = 1
    stylel2l = deepcopy(stylel2)
    stylel2l.borders.left = 1

    stylel3 = deepcopy(stylel2_4)
    stylel3l = deepcopy(stylel3)
    stylel3l.borders.left = 1

    stylel4 = deepcopy(stylel2_4)
    stylel4.borders.bottom = 1
    stylel4l = deepcopy(stylel4)
    stylel4l.borders.left = 1

#    col_wl = [10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10 ,10, 10, 10, 10, 10]
    col_wl = [(0.46/0.8)*10,(0.52/0.8)*10,(1.41/0.8)*10,(1.41/0.8)*10,(1.31/0.8)*10,
	    (0.85/0.8)*10,(0.47/0.8)*10,(0.43/0.8)*10,(0.43/0.8)*10,(0.45/0.8)*10,(0.45/0.8)*10,(0.43/0.8)*10,(0.45/0.8)*10,(0.46/0.8)*10,(0.51/0.8)*10,(0.51/0.8)*10,(0.61/0.8)*10,(0.40/0.8)*10,(0.51/0.8)*10,(0.51/0.8)*10,(0.51/0.8)*10,(0.54/0.8)*10,(0.56/0.8)*10,(0.66/0.8)*10,(0.50/0.8)*10,(0.50/0.8)*10,(0.80/0.8)*10,(0.80/0.8)*10]

#    ws = w.add_sheet(s)

    res=[]
    for root, directory, files in os.walk(sys.argv[1]):
        for filename in files:
            name, suf = os.path.splitext(filename)
            if suf == '.dat':
                res.append(os.path.join(root, filename))
    for file in res:
        data_list = (l[:-1].strip().split(' ') for l in open(file))
        xls_list = data_to_xls_l(data_list)

        base_name = os.path.basename(file.replace('.dat', ''))
        sheet_name = base_name + '_data'
        sca = [x[0] for x in xls_list[1:]]
        iops = [string.atof(x[1]) for x in xls_list[1:]]

        im = Image.open(file.replace('.dat', '.png'))
        im = im.convert('RGB')
        im.save("/tmp/iops.bmp")
        ws = w.add_sheet(base_name + '_figure')
        ws.insert_bitmap('/tmp/iops.bmp', 0, 0)
        plt.close(1)

        ws = w.add_sheet(sheet_name)
        ws.write(0, 0, 'Scheduler', stylel1)
        ws.write(0, 1, 'IOPS', stylel1)

        for row,line in enumerate(xls_list):
            for col,item in enumerate(line):
                try:
                    item_w = string.atof(item)
                except Exception,ex:
                    item_w = item
                ws.write(row + 1, col, item_w, style)

    xls_file_name = sys.argv[1] + '/orion.xls'
    w.save(xls_file_name)
    print xls_file_name

def data_to_xls_l(data_list):
    xls_list = list()
    pl = [None]
    for l in data_list:
        xls_list.append(l)
    return xls_list


wt_xls(sys.argv[1])
