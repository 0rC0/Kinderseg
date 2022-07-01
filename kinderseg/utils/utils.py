
import numpy as np
import pandas as pd
import nibabel as nib
import os
from dateutil.relativedelta import relativedelta
from datetime import datetime
import pydicom

def date_absdiff(date1, date2, fmt='%Y%m%d'):

    d = relativedelta(datetime.strptime(date1, fmt),
                      datetime.strptime(date2, fmt))
    return abs((d.days + d.months * 30 + d.years * 365))/365


def age_from_dicoms(dp):
    #print(dp)
    f = pydicom.read_file(dp)
    return date_absdiff(f.PatientBirthDate,
                        f.AcquisitionDate)


def nii2mgz(nii_path):
    """
    Convert nifti to mgz, generate an orig.mgz in the same directory of the .nii
    :param nii_path: path of the .nii file
    :return: path and filename for the mgz file
    """
    path = os.path.dirname(nii_path)
    nii_obj = nib.load(nii_path)
    mgh_obg = nib.MGHImage(nii_obj.get_fdata(), affine=nii_obj.affine, header=nii_obj.header)
    dest_path = os.path.join(path, 'orig.mgz')
    nib.save(mgh_obg, dest_path)
    return dest_path


def find_outliers(df, var='both'):
    """
    Find outliers in each column of a given dataframe.
    Each column is a series.
    Outliers: value < media - 2.698 stddev (var= low or both) or
              value > media - 2.698 stddev  (var = high or both)
    :param df: Dataframe
    :return:
    """
    d = dict()
    for col in df.columns:
        #try:
        series = df[col].values
        median = np.nanmedian(series)
        std = np.nanstd(series)
        if var == 'both':
            d[col] = (series < median - 2.698 * std) | (series > median + 2.698 * std)
        elif var == 'low':
            d[col] = (series < median - 2.698 * std)
        elif var == 'high':
            d[col] = (series > median + 2.698 * std)
        # except:
        #         print('Skip: ', col)
    return d
