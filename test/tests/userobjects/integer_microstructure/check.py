import csv
import math
import sys
from pathlib import Path

recovered = '--recovered' in sys.argv
filename = next((a for a in sys.argv[1:] if a != '--recovered'), 'integer_ids_out.csv')
fields = ['time','elements','mean_density','mean_fraction','mean_id'] if recovered else None
rows = list(csv.DictReader(Path(filename).open(), fieldnames=fields))
assert len(rows) >= (2 if recovered else 5), 'Missing saved time steps'
counts = [int(float(row['elements'])) for row in rows]
if recovered:
    assert all(n == 3 for n in counts), counts
    assert all(float(row['time']) > 0.4 for row in rows), rows
else:
    assert min(counts) == 3 and max(counts) == 12, counts
    assert sum(a != b for a,b in zip(counts,counts[1:])) >= 2, counts
for row in rows:
    for name, expected in [('mean_id',67), ('mean_density',1.44), ('mean_fraction',5/6)]:
        assert math.isclose(float(row[name]),expected,rel_tol=1e-10,abs_tol=1e-10), (name,row)
print('Integer labels and table-derived values survive repeated refinement/coarsening.')
