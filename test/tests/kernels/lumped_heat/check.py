import csv
import math
from pathlib import Path

with Path("heterogeneous_out.csv").open() as stream:
    row = list(csv.DictReader(stream))[-1]
for name, expected in {"left": 0.1, "middle": 0.05, "right": 1 / 30}.items():
    actual = float(row[name])
    assert math.isclose(actual, expected, rel_tol=1e-8, abs_tol=1e-12), (name, actual, expected)
# Integrated storage increment equals integrated source over the timestep.
energy = float(row["left"]) + 4 * float(row["middle"]) + 3 * float(row["right"])
assert math.isclose(energy, 0.4, rel_tol=1e-8)
print("Heterogeneous lumped nodal temperatures and energy balance passed.")
