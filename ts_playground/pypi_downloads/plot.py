import pandas as pd
import matplotlib.pyplot as plt

if __name__ != 'main':
    fig, ax = plt.subplots(1, 1, figsize=(16, 8))
    df = pd.read_csv('../../source/clean/orbit-ml-download-clean.csv', parse_dates=['week'])
    df['cum_downloads'] = df['num_downloads'].cumsum()
    ax.plot(df['week'].values, df['cum_downloads'].values)
    fig.show()
