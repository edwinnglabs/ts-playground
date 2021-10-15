from google.cloud import bigquery
import os
import pypistats
from datetime import datetime
from datetime import date


def generate_timestamp():
    now = datetime.now()
    ts_str = now.strftime("%Y%m%d-%H%M%S")
    return ts_str


def download_pypistats(source='pypistats', start_date='2020-09-01', end_date='2020-12-31'):
    """
    Parameters
    ----------
    source : str
        either 'pypistats' or 'bigquery'
    start_date : str
    end_date : str
    Returns
    -------
    pd.DataFrame
    """
    if source == 'pypistats':
        print("Calling pypistats...")
        df = pypistats.overall('orbit-ml', total=True, format="pandas")
    elif source == 'big-query':
        # pip install --upgrade 'google-cloud-bigquery[bqstorage,pandas]' to have the .to_dataframe() properties
        os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = "../../orbit-ml-downloads-keys.json"
        client = bigquery.Client(project="orbit-ml-downloads")
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

    else:
        raise Exception("Invalid source.")

    ts = generate_timestamp()
    update_date = date.today()
    df["update_date"] = update_date
    print("Saving result as csv file...")
    df.to_csv("orbit-ml-download-{}.csv".format(ts), index=False)
    print("Done.")


# TODO: refactor as a module make file path, query, project name, package arbitrary

if __name__ != 'main':
    # when you need to download from raw
    download_pypistats(source='big-query', start_date='2021-01-01', end_date='2021-03-31')

