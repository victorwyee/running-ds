import json
import os
import string
import urllib.request  # alternately, use the `requests` package

import pandas as pd

# CONSTANTS
TTT2018_CSV = 'data/20180521/tabula-TildenToughTen2018PDF.csv'
LCTC2018_JSON = 'data/20180611/lake-chabot-trail-challenge-2018-results.json'
LCTC2018_URL = 'https://runsignup.com/Race/Results/21928/?resultSetId=117702&page=1&num=10000&search='
PUNCT_STRIP_TABLE = str.maketrans(dict.fromkeys(string.punctuation))


# CONFIG
pd.set_option('display.expand_frame_repr', False)  # prevents DF repr from wrapping around
pd.set_option('display.max_rows', 200)             # prevents columns from being hidden
pd.set_option('display.max_columns', 200)
pd.set_option('display.width', 9999)


# FUNCTIONS
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
    name = full_name.strip().translate(PUNCT_STRIP_TABLE)
    name_parts = name.split(' ')
    i = 0 if first_or_last == 'first' else len(name_parts) - 1
    return name_parts[i][0:block_size].upper()


def format_timedelta(td):
    return '{0}:{1}:{2}.{3}'.format(
        '{:0>2d}'.format(td.components.hours),
        '{:0>2d}'.format(td.components.minutes),
        '{:0>2d}'.format(td.components.seconds),
        '{:0>2d}'.format(int(str(td.components.milliseconds)[:2])))  # LC times precise to hundredths.


# READ
ttt2018_df = read_ttt(TTT2018_CSV)
lctc2018_df = read_lctc(LCTC2018_URL, LCTC2018_JSON)

# BLOCKING
ttt2018_df['ag'] = list(map(get_age_group, ttt2018_df['age']))
lctc2018_df['ag'] = list(map(lambda x: x.split(' ')[1], lctc2018_df['division']))
ttt2018_df['nb'] = [(get_name_block(full_name, 1, 'first'), get_name_block(full_name, 2, 'last'))
                    for full_name in ttt2018_df['name_full']]
lctc2018_df['nb'] = [(get_name_block(full_name, 1, 'first'), get_name_block(full_name, 2, 'last'))
                     for full_name in lctc2018_df['name_full']]


# MERGE
# 3 different pairs of people share the same initials, age_group, and gender!
# 1 pair of people share the same first initial, first 2 letters of their last name, and age_group!
# 10 different pairs of people share the same first initial, first 2 letters of their last name, and gender!
# Turns out that blocking is good enough for correct merging! No additional linkage techniques required.
inmerge2018_df = ttt2018_df.merge(lctc2018_df,
                                  how='inner',
                                  left_on=['nb', 'ag', 'gender'],
                                  right_on=['nb', 'ag', 'gender'],
                                  suffixes=['_ttt', '_lc'])
outmerge2018_df = ttt2018_df.merge(lctc2018_df,
                                   how='outer',
                                   left_on=['nb', 'ag', 'gender'],
                                   right_on=['nb', 'ag', 'gender'],
                                   suffixes=['_ttt', '_lc'])


# Using TTT names and cities because they're better and more consistently formatted
# Only gun time is available for TTT. Chip and gun times for LC are the same.
inmerge2018_df = inmerge2018_df[
    ['name_full_ttt', 'city_ttt', 'gender', 'age', 'division',
     'position_ttt', 'time_gun_ttt', 'position_lc', 'time_gun_lc']]\
    .rename(columns={'name_full_ttt': 'name',
                     'city_ttt': 'city'})
outmerge2018_df = outmerge2018_df[
    ['name_full_ttt', 'name_full_lc', 'city_ttt', 'city_lc', 'gender', 'age', 'division',
     'position_ttt', 'time_gun_ttt', 'position_lc', 'time_gun_lc']]\
    .rename(columns={'age': 'age_ttt',
                     'division': 'division_lc'})

# Convert times from string to timedelta
inmerge2018_df['time_gun_ttt'] = list(map(pd.to_timedelta, inmerge2018_df['time_gun_ttt']))
inmerge2018_df['time_gun_lc'] = list(map(pd.to_timedelta, inmerge2018_df['time_gun_lc']))

# Sum up total time
inmerge2018_df['time_total'] = [format_timedelta(td)
                                for td in inmerge2018_df['time_gun_ttt'] + inmerge2018_df['time_gun_lc']]

# Format gun times to hundredths for display purposes
inmerge2018_df['time_gun_ttt'] = [format_timedelta(td) for td in inmerge2018_df['time_gun_ttt']]
inmerge2018_df['time_gun_lc'] = [format_timedelta(td) for td in inmerge2018_df['time_gun_lc']]

# Sort
inmerge2018_df.sort_values(by=['time_total'], inplace=True)
inmerge2018_df.reset_index(drop=True, inplace=True)

# Write out
outmerge2018_df.to_csv('out/20180611/triple_crown_2018_allresults_20180611.csv', encoding='utf-8')
inmerge2018_df.to_csv('out/20180611/triple_crown_2018_innerjoin_20180611.csv', encoding='utf-8')