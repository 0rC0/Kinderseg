import pandas as pd
import os
import re

FreeSurferColorLUT = '/usr/local/freesurfer_6/FreeSurferColorLUT.txt'
rx = re.compile(r'(?P<roinum>\d*)\s*(?P<roiname>[a-zA-Z-_]*)\s*\d*\s\d*\s\d*\s\d{1}')

def parse_freesurfercolorlut():
    with open(FreeSurferColorLUT, 'r') as fin:
        raw_data = fin.read()
        int_lines = [{i.group('roinum'): i.group('roiname')} for i in rx.finditer(raw_data)]
        int_lines_clean = [i for i in int_lines if list(i.keys())[0] and list(i.values())[0]]
        int_lines_dict = dict()
        for i in int_lines_clean:
            int_lines_dict.update(i)
        return int_lines_dict


def summarize_rois(csv_table):
    pass