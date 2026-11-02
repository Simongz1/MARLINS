import csv
rows = list(csv.DictReader(open('stationary_out.csv')))
assert len(rows) == 11
assert all(abs(float(row['contact_error'])) < 1e-12 for row in rows)
print('Stationary density contact preserved.')
