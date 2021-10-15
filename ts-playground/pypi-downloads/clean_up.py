import os
import pathlib
import pandas as pd
from datetime import date


def list_all_csv(path):
    files = os.listdir(path)
    target_dir = os.path.abspath(path)
    csv_files = [os.path.join(target_dir, f) for f in files if pathlib.Path(f).suffix == '.csv']
    return csv_files


if __name__ != 'main':
    csv_files = list_all_csv('../../source/raw')
    print("combining these files:", csv_files)
    combined_all_csv = pd.concat(
        [pd.read_csv(f, delimiter=',') for f in csv_files],
        ignore_index=True
    )
    combined_all_csv = combined_all_csv[~combined_all_csv['week'].isnull()].reset_index(drop=True)
    combined_all_csv['update_rank'] = combined_all_csv.groupby('week')['update_date'].rank(method='min',
                                                                                           ascending=False)
    print("deduping...")
    # in case conflicts happen
    combined_all_csv = combined_all_csv[combined_all_csv['update_rank'] == 1].reset_index(drop=True)
    combined_all_csv = combined_all_csv.groupby(['week', 'update_date'])['num_downloads'].max().reset_index()
    combined_all_csv = combined_all_csv.sort_values(by=['week'])
    combined_all_csv.to_csv("../../source/clean/orbit-ml-download-clean.csv", index=False)
    print("saving clean result...")
    lhs = combined_all_csv.shape[0]
    rhs = len(combined_all_csv['week'].unique())
    assert lhs == rhs
    # re-arrange columns
    combined_all_csv = combined_all_csv[['week', 'num_downloads', 'update_date']]
    combined_all_csv.to_csv("../../source/clean/orbit-ml-download-clean.csv", index=False)
