#!/bin/bash (source)

set -uo pipefail

BPS_DOCKER_TAG="04.43"
BPS_PYTHON_ENV=BPS_443

BPS_TEST_PLAN_PATH=/home/jovyan/SW/BPS_V443

BPS_BUNDLE_DIR=/home/jovyan/SW/BPS_V443/bundle
BPS_CONDA_CHANNEL=/home/jovyan/SW/BPS_V443/bundle/bps_conda_channel

BPS_TDS_PATH=/home/jovyan/BPS/BPS_V443
BPS_TEST_CASES_PATH=${BPS_TEST_PLAN_PATH}/test_cases
BPS_CONF_FILES_PATH=${BPS_TEST_PLAN_PATH}/configuration_files
BPS_SCRIPTS_PATH=${BPS_TEST_PLAN_PATH}/tools/scripts

if [ -f /opt/anaconda3/etc/profile.d/conda.sh ]; then
    source /opt/anaconda3/etc/profile.d/conda.sh
elif [ -f /opt/conda/etc/profile.d/conda.sh ]; then
    source /opt/conda/etc/profile.d/conda.sh
elif [ -f /opt/miniconda3/etc/profile.d/conda.sh ]; then
    source /opt/miniconda3/etc/profile.d/conda.sh
fi

set -e
conda activate ${BPS_PYTHON_ENV}
set +e

set +u
BPS_L1F_LIBRARIES_PATH=${BPS_BUNDLE_DIR}/l1_framing_processor/lib
export LD_LIBRARY_PATH=${BPS_L1F_LIBRARIES_PATH}:${LD_LIBRARY_PATH:-}
set -u

USE_LOCAL_EXEC=false
if [ "${USE_LOCAL_EXEC}" = true ]; then
    USE_LOCAL_BIN=/path/to/executables/bin
    USE_LOCAL_LIB=/path/to/executables/lib
    export PATH="${USE_LOCAL_BIN}:${PATH}"
    export LD_LIBRARY_PATH="${USE_LOCAL_LIB}:${LD_LIBRARY_PATH:-}"
fi

BPS_L1F_MEMORY_LIMIT="2048m"
BPS_L1_MEMORY_LIMIT="25600m"
BPS_STA_MEMORY_LIMIT="65536m"
BPS_L2A_MEMORY_LIMIT="30720m"
BPS_L2B_FH_MEMORY_LIMIT="9216m"
BPS_L2B_FD_MEMORY_LIMIT="9216m"
BPS_L2B_AGB_MEMORY_LIMIT="65536m"

BPS_L1_TMPFS_MEMORY_SIZE="15360m"

BPS_L1F_CPU_LIMIT="1000000"
BPS_L1_CPU_LIMIT="6000000"
BPS_STA_CPU_LIMIT="7000000"
BPS_L2A_CPU_LIMIT="8000000"
BPS_L2B_FH_CPU_LIMIT="4000000"
BPS_L2B_FD_CPU_LIMIT="4000000"
BPS_L2B_AGB_CPU_LIMIT="4000000"
