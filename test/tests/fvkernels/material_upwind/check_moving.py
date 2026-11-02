import csv

def final_error(path):
    with open(path) as stream:
        return float(list(csv.DictReader(stream))[-1]['contact_error'])

assert final_error('moving_minmod_out.csv') < final_error('moving_first_out.csv')
print('Limited reconstruction reduces moving-contact error.')
