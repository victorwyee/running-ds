import pandas as pd

from triplecrown.src.py import helpers

# CONSTANTS
TTT2018_CSV = 'data/20180521/tilden_tough_ten/tabula-TildenToughTen2018PDF.csv'
LCTC2018_JSON = 'data/20180611/lake_chabot/lake-chabot-trail-challenge-2018-results.json'
LCTC2018_URL = 'https://runsignup.com/Race/Results/21928/?resultSetId=117702&page=1&num=10000&search='
WM2018_TSV = 'data/20180624/woodmonster/woodmonster-2018-handicap.tsv'

# CONFIG
pd.set_option('display.expand_frame_repr', False)  # prevents DF repr from wrapping around
pd.set_option('display.max_rows', 200)  # prevents columns from being hidden
pd.set_option('display.max_columns', 200)
pd.set_option('display.width', 9999)

# READ
ttt2018_df = helpers.read_ttt(TTT2018_CSV)
lctc2018_df = helpers.read_lctc(LCTC2018_URL, LCTC2018_JSON)
wm2018_df = helpers.read_wm(WM2018_TSV)
wm2018_df = helpers.convert_wm_td(wm2018_df)

# BLOCKING
ttt2018_df['ag'] = list(map(helpers.get_age_group, ttt2018_df['age']))
lctc2018_df['ag'] = list(map(lambda x: x.split(' ')[1], lctc2018_df['division']))
wm2018_df['ag'] = list(map(helpers.get_age_group, wm2018_df['age']))
ttt2018_df['nb'] = [(helpers.get_name_block(full_name, 1, 'first'), helpers.get_name_block(full_name, 3, 'last'))
                    for full_name in ttt2018_df['name_full']]
lctc2018_df['nb'] = [(helpers.get_name_block(full_name, 1, 'first'), helpers.get_name_block(full_name, 3, 'last'))
                     for full_name in lctc2018_df['name_full']]
wm2018_df['nb'] = [(helpers.get_name_block(full_name, 1, 'first'), helpers.get_name_block(full_name, 3, 'last'))
                   for full_name in wm2018_df['name_full']]

# MERGE
# 3 different pairs of people share the same initials, age_group, and gender!
# 1 pair of people share the same first initial, first 2 letters of their last name, and age_group!
# 10 different pairs of people share the same first initial, first 2 letters of their last name, and gender!
# Turns out that there's a Samuel Wang and Stephen Way, both Male 46yo. No loss in linkage with first 3 of last name.
# Turns out that blocking is good enough for correct merging! No additional linkage techniques required.
outmerge2018_1_df = ttt2018_df.merge(lctc2018_df,
                                     how='outer',
                                     left_on=['nb', 'ag', 'gender'],
                                     right_on=['nb', 'ag', 'gender'],
                                     suffixes=['_ttt', '_lc'])
outmerge2018_2_df = outmerge2018_1_df.merge(wm2018_df,
                                            how='outer',
                                            left_on=['nb', 'ag', 'gender'],
                                            right_on=['nb', 'ag', 'gender'],
                                            suffixes=['', '_wm'])
inmerge2018_1_df = ttt2018_df.merge(lctc2018_df,
                                    how='inner',
                                    left_on=['nb', 'ag', 'gender'],
                                    right_on=['nb', 'ag', 'gender'],
                                    suffixes=['_ttt', '_lc'])
inmerge2018_2_df = inmerge2018_1_df.merge(wm2018_df,
                                          how='inner',
                                          left_on=['nb', 'ag', 'gender'],
                                          right_on=['nb', 'ag', 'gender'],
                                          suffixes=['', '_wm'])

# Using TTT names and cities because they're better and more consistently formatted
# Only gun time is available for TTT. Chip and gun times for LC are the same.
inmerge2018_df = inmerge2018_2_df[
    ['name_full_ttt', 'city_ttt', 'gender', 'age', 'division',
     'position_ttt', 'time_gun_ttt', 'position_lc', 'time_gun_lc',
     'position_handicap', 'position_gun', 'time_gun']] \
    .rename(columns={'name_full_ttt': 'name',
                     'city_ttt': 'city',
                     'time_gun': 'time_gun_wm',
                     'position_handicap': 'position_handicap_wm',
                     'position_gun': 'position_gun_wm'})
outmerge2018_df = outmerge2018_2_df[
    ['name_full_ttt', 'name_full_lc', 'name_full',
     'city_ttt', 'city_lc', 'city',
     'gender', 'age', 'age_wm', 'division',
     'position_ttt', 'time_gun_ttt', 'position_lc', 'time_gun_lc',
     'position_handicap', 'position_gun', 'time_gun']] \
    .rename(columns={'name_full': 'name_full_wm',
                     'age': 'age_ttt',
                     'division': 'division_lc',
                     'city': 'city_wm',
                     'position_handicap': 'position_handicap_wm',
                     'position_gun': 'position_gun_wm',
                     'time_gun': 'time_gun_wm'})

# Convert times from string to timedelta

for tcol in ['time_gun_ttt', 'time_gun_lc', 'time_gun_wm']:
    inmerge2018_df[tcol] = list(map(pd.to_timedelta, inmerge2018_df[tcol]))
    outmerge2018_df[tcol] = list(map(pd.to_timedelta, outmerge2018_df[tcol]))

# Sum up total time
inmerge2018_df['time_total'] = [td for td in
                                inmerge2018_df['time_gun_ttt'] +
                                inmerge2018_df['time_gun_lc'] +
                                inmerge2018_df['time_gun_wm']]


# Format gun times to hundredths for display purposes
for tcol in ['time_gun_ttt', 'time_gun_lc', 'time_gun_wm']:
    inmerge2018_df[tcol] = [helpers.format_timedelta(td) for td in inmerge2018_df[tcol]]
    outmerge2018_df[tcol] = [helpers.format_timedelta(td) for td in outmerge2018_df[tcol]]


inmerge2018_df['time_total'] = [helpers.format_timedelta(td) for td in inmerge2018_df['time_total']]

# Sort
inmerge2018_df.sort_values(by=['time_total'], inplace=True)
inmerge2018_df.reset_index(drop=True, inplace=True)

# Add position
inmerge2018_df.insert(0, 'position_total', inmerge2018_df['time_total'].rank().astype(int))

# Write out
out_dir = 'triplecrown/out/20180625/'
outmerge2018_df.to_csv(out_dir + 'triple_crown_2018_allresults_20180625.csv', index=False, encoding='utf-8')
inmerge2018_df.to_csv(out_dir + '/triple_crown_2018_innerjoin_20180625.csv',  index=False, encoding='utf-8')

# Clean up
del inmerge2018_1_df, inmerge2018_2_df
del outmerge2018_1_df, outmerge2018_2_df
del tcol, out_dir