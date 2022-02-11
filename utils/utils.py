
import numpy as np
import pandas as pd

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
