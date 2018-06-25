import json
import os
import string
import urllib.request  # alternately, use the `requests` package
import pandas as pd


def read_ttt(path):
    """Read Tilden Tough Ten data"""
    return pd.read_csv(path) \
        .rename(columns={'Position': 'position',
                         'Bib': 'bib',
                         'Name': 'name_full',
                         'Time': 'time_gun',
                         'Age': 'age',
                         'Gender': 'gender',
                         'City': 'city'})


def read_lctc(url, cache_path):
    """Read Lake Chabot Trail Challenge 2018 data with urllib.request"""
    if os.path.exists(cache_path):
        with open(cache_path) as f:
            resp_json = json.load(f)
    else:
        headers = {'Accept': 'application/json'}
        req = urllib.request.Request(url=url, data=None, headers=headers)
        with urllib.request.urlopen(req) as response:
            resp = response.read()
            resp_json = json.loads(resp.decode('utf-8'))
            with open(cache_path, 'a') as f:
                json.dump(resp_json, f)
    headings = [heading['key'] for heading in resp_json['headings']]
    return pd.DataFrame(resp_json['resultSet']['results'], columns=headings) \
        .rename(columns={'race_placement': 'position',
                         'bib_num': 'bib',
                         'name': 'name_full',
                         'gender': 'gender',
                         'city': 'city',
                         'state': 'state',
                         'countrycode': 'country',
                         'clock_time': 'time_gun',
                         'chip_time': 'time_chip',
                         'avg_pace': 'avg_pace',
                         'division_place': 'division_place',
                         'division': 'division'})


def read_wm(path):
    return pd.read_csv(path, sep='\t', header=0) \
        .rename(columns={'Place': 'position_handicap',
                         'Name': 'name_full',
                         'City': 'city',
                         'Bib': 'bib',
                         'Age': 'age',
                         'Gender': 'gender',
                         'Actual Time': 'time_gun',
                         'Handicap': 'handicap',
                         'Net Time': 'time_handicap'})


def convert_wm_td(df):
    def convert_to_td(x): return pd.to_timedelta('0:' + x if len(x) == 7 else x)
    df['time_gun'] = list(map(convert_to_td, df['time_gun']))
    df['time_handicap'] = list(map(convert_to_td, df['time_handicap']))
    df['position_gun'] = df['time_gun'].rank(ascending=True).astype(int)
    return df


def get_age_group(age):
    if age < 18:
        return '1-17'
    elif 18 <= age <= 29:
        return '18-29'
    elif 30 <= age <= 34:
        return '30-34'
    elif 35 <= age <= 39:
        return '35-39'
    elif 40 <= age <= 44:
        return '40-44'
    elif 45 <= age <= 49:
        return '45-49'
    elif 50 <= age <= 54:
        return '50-54'
    elif 55 <= age <= 59:
        return '55-59'
    elif 60 <= age <= 64:
        return '60-64'
    elif 65 <= age <= 69:
        return '65-69'
    else:
        return '70-99'


def get_name_block(full_name, block_size, first_or_last):
    punct_strip_table = str.maketrans(dict.fromkeys(string.punctuation))
    name = full_name.strip().translate(punct_strip_table)
    name_parts = name.split(' ')
    i = 0 if first_or_last == 'first' else len(name_parts) - 1
    return name_parts[i][0:block_size].upper()


def format_timedelta(td):
    if pd.isnull(td): return
    return '{0}:{1}:{2}.{3}'.format(
        '{:0>2d}'.format(td.components.hours),
        '{:0>2d}'.format(td.components.minutes),
        '{:0>2d}'.format(td.components.seconds),
        '{:0>2d}'.format(int(str(td.components.milliseconds)[:2])))  # LC times precise to hundredths.
