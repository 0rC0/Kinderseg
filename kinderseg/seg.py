

import os
import nibabel as nib
import numpy as np
import pandas as pd
import sys
import subprocess
from utils.utils import nii2mgz, age_from_dicoms

fastsurfer_home='/home/orco/software/FastSurfer'
os.environ['FASTSURFER_HOME'] = fastsurfer_home
os.environ['FREESURFER_HOME'] = '/usr/local/freesurfer_6'
freesurfer_home = '/usr/local/freesurfer_6'
this_path = '/home/orco/nora_work/Kinderseg/kinderseg' # ToDo: change

norm_table = os.path.join(this_path,'data/norm_table.csv')

def main(args):

    t1_path = os.path.abspath(args[0])
    print('t1_path {}'.format(t1_path))

    dcm_path = args[1]
    print('dcm path {}'.format(dcm_path))
    sid = os.path.basename(t1_path) + '.fastsurfer'
    #sd = '/'.join(t1_path.split('/')[:-2])
    sd = os.path.dirname(t1_path)
    os.environ['SUBJECTS_DIR'] = sd
    print('SUBJECTS_DIR = {}'.format(sd))
    # 0) convert T1 to mgz for fastsurfer
    mgz = nii2mgz(t1_path)
    # 1) Segment T1 with Fastsurfer
    fastsurfer_cmd = '''{fastsurfer_home}/run_fastsurfer.sh --seg_only \
                          --sd {subject_dir} \
                          --sid {subject_id} \
                          --t1 {mgz_path} \
                          --parallel --threads 20 --vol_segstats'''.format(freesurfer_home=freesurfer_home,
                                                                           fastsurfer_home=fastsurfer_home,
                                                                           subject_dir=sd,
                                                                           subject_id=sid,
                                                                           mgz_path=mgz)

    try: # Sometimes Fastsurfer returns an exit code != 0, but is possible to continue
        print('****** Fastsurfer********')
        print(fastsurfer_cmd)
        subprocess.run(fastsurfer_cmd.split())
    except:
        pass

    # calculate etiv
    print('****** eTIV********')
    etiv_cmd = "mri_segstats --etiv-only --subject  {sid} | grep eTIV ".format(sid=sid)
    print(etiv_cmd)
    etiv = subprocess.Popen([etiv_cmd], shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    etiv = etiv.stdout.read()
    etiv = str(etiv).split(' ')[3]
    print('etiv', float(etiv))
    # 2) Extract data
    print('****** Volume Table********')
    print('DICOM: {}'.format(os.path.join(dcm_path, os.listdir(dcm_path)[0])))
    patient_age = age_from_dicoms(os.path.join(dcm_path, os.listdir(dcm_path)[0])) #ToDo: possible list out of range
    print('patient age: {age}'.format(age=patient_age))
    table_file = sd + '/stats_table.csv'
    print('Table file: {}'.format(table_file))

    seg2table_cmd = '''asegstats2table --common-segs --meas volume --all-segs\
                --tablefile {tablefile} \
                --statsfile={sd}/{sid}/stats/aparc.DKTatlas+aseg.deep.volume.stats \
                --subjects {sid}'''.format(tablefile= table_file,
                                         sd=sd,
                                         sid=sid)
    print('seg2tabel cmd: {}'.format(seg2table_cmd))
    subprocess.run(seg2table_cmd, shell=True)

    # Add age to table
    print(table_file)
    table = pd.read_csv(table_file, sep='\t')
    table.rename(columns = {'Measure:volume':'ids'}, inplace = True)
    table['age'] = patient_age
    table['eTIV'] = etiv
    table.to_csv(table_file, sep='\t')

    # # 3) Compare data with database
    print('Executing: {}'.format(os.path.join(this_path,'R_scripts/compare_with_db.R')))
    sys.path.append('/home/orco/anaconda3/envs/R_ks/bin')
    r_cmd = '/home/orco/anaconda3/envs/R_ks/bin/Rscript {R_script_abspath} {table} {norm_table}'.format(R_script_abspath=os.path.join(this_path,'R_scripts/compare_with_db.R'),
                                                                                                        table = table_file,
                                                                                                        norm_table=norm_table)
    subprocess.run([r_cmd], shell=True)


if __name__ == '__main__':
    main(sys.argv[1:])
