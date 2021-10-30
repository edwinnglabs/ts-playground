import os
import pathlib
import pandas as pd
import json
from datetime import date
from enum import Enum


class BIG_QUERY_REQUIREMENT(Enum):
    TYPE = "type"
    PROJECT_ID = "project_id"
    PRIVATE_KEY_ID = "private_key_id"
    PRIVATE_KEY = "private_key"
    CLIENT_EMAIL = "client_email"
    CLIENT_ID = "client_id"
    AUTH_URL = "auth_uri"
    TOKEN_URL = "token_uri"
    AUTH_PROVIDER = "auth_provider_x509_cert_url"
    CLIENT_URL = "client_x509_cert_url"


def generate_timestamp():
    now = datetime.now()
    ts_str = now.strftime("%Y%m%d-%H%M%S")
    return ts_str


def list_all_csv(path):
    """
    Parameters
    ----------
    path : str

    Returns
    -------
    list all the *.csv files given specific path
    """
    files = os.listdir(path)
    target_dir = os.path.abspath(path)
    csv_files = [os.path.join(target_dir, f) for f in files if pathlib.Path(f).suffix == '.csv']
    return csv_files


def build_json(input_dict, path):
    """
    Parameters
    ----------
    """
    with open(path, "w") as f:
        json.dump(input_dict, f, indent=4)


def build_big_query_json(private_key_id,
                         private_key,
                         client_email,
                         client_id,
                         path="temp.json"
                         ):
    """
    Parameters
    ----------

    Other Parameters
    ----------
    path : str
    """
    # default
    input_dict = {BIG_QUERY_REQUIREMENT.TYPE.value: "service_account",
                  BIG_QUERY_REQUIREMENT.PROJECT_ID.value: "orbit-ml-downloads",
                  BIG_QUERY_REQUIREMENT.PRIVATE_KEY_ID.value: private_key_id,
                  BIG_QUERY_REQUIREMENT.PRIVATE_KEY.value: private_key,
                  BIG_QUERY_REQUIREMENT.CLIENT_EMAIL.value: client_email,
                  BIG_QUERY_REQUIREMENT.CLIENT_ID.value: client_id,
                  BIG_QUERY_REQUIREMENT.AUTH_URL.value: "https://accounts.google.com/o/oauth2/auth",
                  BIG_QUERY_REQUIREMENT.TOKEN_URL.value: "https://oauth2.googleapis.com/token",
                  BIG_QUERY_REQUIREMENT.AUTH_PROVIDER.value: "https://www.googleapis.com/oauth2/v1/certs",
                  BIG_QUERY_REQUIREMENT.CLIENT_URL.value: "https://www.googleapis.com/robot/v1/metadata/x509/orbit-downloads-"
                                                          "551%40orbit-ml-downloads.iam.gserviceaccount.com"}
    build_json(input_dict=input_dict, path=path)

# if __name__ != 'main':
# # test build json
# build_big_query_json(
#     private_key_id="1234",
#     private_key="1234",
#     client_email="orbit-downloads-551@orbit-ml-downloads.iam.gserviceaccount.com",
#     client_id="1234",
#     path="temp.json",
# )

# csv_files = list_all_csv('../../source/raw')
# print("combining these files:", csv_files)
# combined_all_csv = pd.concat(
#     [pd.read_csv(f, delimiter=',') for f in csv_files],
#     ignore_index=True
# )
# combined_all_csv = combined_all_csv[~combined_all_csv['week'].isnull()].reset_index(drop=True)
# combined_all_csv['update_rank'] = combined_all_csv.groupby('week')['update_date'].rank(method='min',
#                                                                                        ascending=False)
# print("deduping...")
# # in case conflicts happen
# combined_all_csv = combined_all_csv[combined_all_csv['update_rank'] == 1].reset_index(drop=True)
# combined_all_csv = combined_all_csv.groupby(['week', 'update_date'])['num_downloads'].max().reset_index()
# combined_all_csv = combined_all_csv.sort_values(by=['week'])
# combined_all_csv.to_csv("../../source/clean/orbit-ml-download-clean.csv", index=False)
# print("saving clean result...")
# lhs = combined_all_csv.shape[0]
# rhs = len(combined_all_csv['week'].unique())
# assert lhs == rhs
# # re-arrange columns
# combined_all_csv = combined_all_csv[['week', 'num_downloads', 'update_date']]
# combined_all_csv.to_csv("../../source/clean/orbit-ml-download-clean.csv", index=False)
