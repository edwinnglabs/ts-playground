import sys
from ts_playground.pypi_downloads.common import get_pypi_stats
from ts_playground.pypi_downloads.utils import generate_timestamp, build_big_query_json


dir = sys.argv[0]
private_key_id = sys.argv[1]
private_key = sys.argv[2]
client_email = sys.argv[3]
client_id = sys.argv[4]

build_big_query_json(
    private_key_id=private_key_id,
    private_key=private_key,
    client_email=client_email,
    client_id=client_id,
    path="temp.json",
)

# df = get_pypi_stats()
# ts = generate_timestamp()
# print("Saving result as csv file...")
# df.to_csv("{}/orbit-ml-download-{}.csv".format(dir, ts), index=False)
# print("Done.")
