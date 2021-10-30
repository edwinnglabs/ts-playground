from google.cloud import bigquery
import os
import pypistats
from datetime import datetime
from datetime import date
from google.oauth2 import service_account
from .utils import build_big_query_json


def generate_timestamp():
    now = datetime.now()
    ts_str = now.strftime("%Y%m%d-%H%M%S")
    return ts_str


def get_pypi_stats(source='big-query', start_date='2020-09-01', end_date='2020-09-10', big_query_meta=None):
    """
    Parameters
    ----------
    source : str
        either 'pypi-stats' or 'big-query'
    start_date : str
    end_date : str
    big_query_meta : dict
        all metas required for query credential
    Returns
    -------
    pd.DataFrame
    """
    if source == 'pypi-stats':
        print("Calling pypi-stats...")
        df = pypistats.overall('orbit-ml', total=True, format="pandas")
    elif source == 'big-query' and big_query_meta is not None:
        print("Calling big-query...")
        # pip install --upgrade 'google-cloud-bigquery[bqstorage,pandas]' to have the .to_dataframe() properties
        # os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = "../../orbit-ml-downloads-keys.json"

        build_big_query_json(path="temp.json", **big_query_meta)
        try:
            credentials = service_account.Credentials.from_service_account_file(
                "temp.json",
                scopes=["https://www.googleapis.com/auth/cloud-platform"],
            )
            client = bigquery.Client(credentials=credentials, project="orbit-ml-downloads")
            print("Running query...")
            query_job = client.query(
                """
                    SELECT DATE_TRUNC(DATE(timestamp), WEEK) AS `week`, COUNT(*) AS num_downloads
                    FROM `bigquery-public-data.pypi.file_downloads`
                    WHERE file.project = 'orbit-ml'
                    AND DATE(timestamp) BETWEEN 
                        DATE_TRUNC(DATE('{:s}'), WEEK) AND DATE_TRUNC(DATE('{:s}'), WEEK) 
                    GROUP BY `week`
                    ORDER BY `week` DESC
                """.format(start_date, end_date)
            )
            df = query_job.to_dataframe()
        finally:
            print("Removing temp file.")
            os.remove("temp.json")
    else:
        raise Exception("Invalid source.")

    update_date = date.today()
    df["update_date"] = update_date
    print("Done.")
    return df


def download_pypi_stats(path='./', **kwargs):
    df = get_pypi_stats(**kwargs)
    ts = generate_timestamp()
    print("Saving result as csv file...")
    df.to_csv("{}/orbit-ml-download-{}.csv".format(path, ts), index=False)
    print("Done.")


if __name__ != 'main':
    download_pypi_stats()
