#!/usr/bin/env bash
# Use the conda/MPICH stack that built this executable; run serially by default.
set -eo pipefail
source /apps/external/apps/conda/2024.09/etc/profile.d/conda.sh
conda activate /home/gonz1075/.conda/envs/moose
unset CPATH LIBRARY_PATH
export LD_LIBRARY_PATH="$CONDA_PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
cd /home/gonz1075/projects/ml
exec ./ml-opt -i inputs/eulerian_fv_pore_1d_upwind.i "$@"
