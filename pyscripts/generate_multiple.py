import pandas as pd
import numpy as np
import subprocess as su
from pathlib import Path
import yaml
import sys

from case_naming import with_shock_velocity

#load required values

velocities = [0.8, 1, 1.5]
sizes = [[50, 200]]
binder_widths = [8, 16]
poro = [0.3, 0.6]

shock_direction = 1000
perpendicular = 100
dim = 2

#set the binder range to be fix for now
binder_max = 90

#data for submission
nodes = 2
cores = 256
days = 2
hours = 12
app = "ml"
account = "alta"
partition = "cpu"
queue = "normal"
full_outputs = "YES"

#iterate over options
for v in velocities:
    for size in sizes:
        for binder in binder_widths:
            for p in poro:

                #replace in the template
                with open('./yaml/template.yaml', 'r') as f:
                    template = f.read()

                #replace
                replaced = template.replace('{UP}', str(v))
                replaced = replaced.replace('{SIZE1}', str(size[0]))
                replaced = replaced.replace('{SIZE2}', str(size[1]))
                replaced = replaced.replace('{BINDER_MAX}', str(binder_max))
                replaced = replaced.replace('{BINDER_WIDTH}', str(binder))
                replaced = replaced.replace('{POROSITY}', str(p))
                replaced = replaced.replace('{ELEM_SHOCK}', str(shock_direction))
                replaced = replaced.replace('{ELEM_PERP}', str(perpendicular))
                replaced = replaced.replace('{DAYS}', str(days))
                replaced = replaced.replace('{HOURS}', str(hours))
                replaced = replaced.replace('{CORES}', str(cores))
                replaced = replaced.replace('{NODES}', str(nodes))
                replaced = replaced.replace('{DIM}', str(dim))            
                replaced = replaced.replace('{OUTPUTS}', str(full_outputs))
                replaced = replaced.replace('{PART}', str(partition))
                microstructure_name = f'{dim}Dporo{str(p)}size{size[0]}_{size[1]}binder{str(binder)}'
                name = with_shock_velocity(microstructure_name, v)

                replaced = replaced.replace('{NAME}', name)
                
                #write file
                with open(f'./yaml/{name}.yaml', 'w') as current:
                    current.write(replaced)

                #run the generate input script

                su.run([sys.executable, 'generate_input.py', f'./yaml/{name}.yaml'], check=True)
                print(60 * "=")
                print(f"Generated file {name} !")
