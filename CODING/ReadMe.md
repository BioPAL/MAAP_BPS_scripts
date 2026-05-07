# MAAP_BPS_scripts

Scripts and notebooks for installation and running the ESA BPS on the MAAP-CODING  (__[ESA MAAP](https://biomass.pal.maap.eo.esa.int/)__).

---

## ⚠️ Prerequisites: Check Your RAM Limit and Storage

Before installing the BPS environment, you must check how much memory your container has available. Run the following commands in the Terminal:

```bash
# Check the real memory limit of your container (cgroup)
echo "$(($(cat /sys/fs/cgroup/memory.max) / 1024 / 1024)) MB"
```

**Important:** According to Section 4.1 of the BPS SUM v4.4.1, the official hardware requirements are:

**Memory:**
* Minimum RAM: 20 GB
* Recommended RAM: 64 GB (4 GB/core ratio)

**Storage:**
* Local storage (for installation): 1 GB
* Local storage (for output data): 25 GB (peak usage: Stack Processor, TOM phase)
* Shared memory (for intermediate data): 10 GB (peak usage: L1 Processor, delete-on-consume activated)

On the ESA MAAP Coding environment, your container RAM limit may be much lower than the minimum required. If your limit is below 20 GB, the conda solver will crash (core dump) when trying to install all packages at once. In that case, please open a support ticket to the MAAP helpdesk to request an increase of your container RAM limit before proceeding with the installation.

---

## 📁 Repository Structure

The SCRIPTS folder has the following structure:

```
SCRIPTS/
├── 0_BPS_installation.ipynb          ← Step 1: install BPS from bundle
├── 1_BPS_inputs_download.ipynb       ← Step 2: Downloads the raw satellite data you want to process
├── 2_BPS_Run.ipynb                   ← Step 3: run the full processing chain
├── BiomassProduct.py                 ← Internal library: parses Biomass product metadata (MPH, EOF, …)
├── config.ini                        ← Paths to templates, static AUX files and AUX directories
├── JOBuilder.py                      ← Generates JobOrder XML files for each processing level
├── BPS_inputs_download.py            ← Library that supports the download of raw input products                                                                    
│
├── CONFIGURATION_FILE/
│   ├── set_environment.bash          ← Activates the BPS conda environment and sets library paths
│   ├── AUX_442/                      ← Example of default AUX files for BPS v4.4.2 (INS, PP1, PP2, PPS, …)
│   └── JO_TEMPLATE/                  ← Templates for generating the JobOrder XML files
│       ├── BIO_L1F_P_TEMPLATE_JobOrder.xml
│       ├── BIO_L1_P_TEMPLATE_JobOrder.xml
│       ├── ...
│       ├── ...
│
└── l0_footprint_generator/            ← Scripts for computing and visualising L0 footprints on a map

```

> ℹ️ On the MAAP Coding environment, the `SCRIPTS/` folder is mapped to `/home/jovyan/SCRIPTS/`. 

---
## 🚀 Quick Start: The Three Steps to Get Results

Before diving into the details, here is the big picture:

| Step | Notebook | What it does |
|------|----------|--------------|
| **0** | `0_BPS_installation.ipynb` | Installs BPS on your MAAP container (do this only once) |
| **1** | `1_BPS_inputs_download.ipynb` | Downloads the raw data you want to process |
| **2** | `2_BPS_Run.ipynb` | Runs the full processing chain from L1F to L2A output |

---
## 📖 Step-by-Step Guide

### Step 0 — Install BPS (`0_BPS_installation.ipynb`)

This notebook installs the BPS Processor Suite into a dedicated conda environment. You can install multiple BPS versions side by side:  each version gets its own conda environment (e.g. BPS_443, BPS_450). You only need to re-run this notebook if you want to install a new version.

**Before opening the notebook, place the BPS bundle tarball in the right location:**

```
/home/jovyan/SW/BPS_V443/
└── bps-bundle-v4.4.3.tar.gz      ← download from https://service.aresys.it/downloads/
```

**Inside the notebook, set the BPS version at the top of cell 0:**

```python
BPS_VERSION = "4.4.3"   # ← change this to match your tarball
```

Everything else is derived automatically. The notebook then:

1. Extracts the tarball into `bundle/`
2. Creates a conda environment (e.g. `BPS_443`) with Python 3.12
3. Builds a local conda channel from the bundle packages
4. Installs all BPS processors (`bps-l1_processor`, `bps-l1_framing_processor`, `bps-stack_processor`, `bps-l2a_processor`, …)
5. Creates a version-specific configuration folder under ~/SCRIPTS/CONFIGURATION_FILE/:
```
CONFIGURATION_FILE/
└── BPS_443/
    └── set_environment.bash    ← patched automatically with the correct paths for this version
```
Patches set_environment.bash with the correct paths for the installed version (bundle dir, conda env name, library paths). 

Adds a shell alias to ~/.bashrc so you can source the BPS environment from the terminal in one command:
```
# added automatically to ~/.bashrc
alias bps443='source /home/jovyan/SCRIPTS/CONFIGURATION_FILE/BPS_443/set_environment.bash'
```
The alias allows you to activate the BPS environment directly from the terminal :  useful if you want to run a processor manually without going through the notebook. Just open a Terminal and type bps443 to load the environment.

6. Verifies the installation by running `--help` on every processor

---


### 🔴 What to do if the installation fails

If the installation fails or gets interrupted mid-way, the conda environment may have been partially created. Before retrying, you need to clean it up first, otherwise the installer will find a broken environment and fail again.

**Step 1 — Open a Terminal** in JupyterLab (`File → New → Terminal`)

**Step 2 — Check if the environment was partially created:**
```bash
conda env list
```
If you see `BPS_443` (or the version you were trying to install) in the list, the environment exists and must be removed.

**Step 3 — Remove the broken environment:**
```bash
conda env remove --name BPS_443
```

**Step 4 — Verify it is gone:**
```bash
conda env list
# BPS_443 should no longer appear
```

**Step 5 — Go back to the notebook and re-run from Step 0 (cell 0)**

> ℹ️ If the installation fails again at the same point, your RAM limit is most likely the cause. Check your current limit with:
> ```bash
> echo "$(($(cat /sys/fs/cgroup/memory.max) / 1024 / 1024)) MB"
> ```
> If it is below 20 GB, open a support ticket to the MAAP helpdesk before retrying.

---

### Step 1 — Download Input Products (`1_BPS_inputs_download.ipynb`)

This notebook downloads all the raw Biomass products needed to run the processing chain, given a single RAW_0S product ID.

**Where do I find a RAW_0S product ID?**
Go to the [ESA MAAP Explorer](https://explorer.maap.eo.esa.int/), search for a Biomass Level 0 product over your area of interest and copy the product ID. It looks like this:

```
BIO_S1_RAW__0S_20251121T095253_20251121T095450_T_G01_M01_C01_T006_F062_01_DNG988
```

The product ID encodes useful information:

| Field | Example | Meaning |
|-------|---------|---------|
| Swath | `S1` | Swath identifier |
| Start time | `20251121T095253` | Acquisition start (UTC) |
| Stop time | `20251121T095450` | Acquisition stop (UTC) |
| Global cycle | `G01` | Global coverage ID |
| Major cycle | `M01` | Major cycle ID |
| Repeat cycle | `C01` | Repeat cycle number (1 to 7) |
| Track | `T006` | Track number |
| Frame | `F062` | Frame number |


**Before running the notebook, set the output path** where all products will be downloaded:

```python
output_path = '/home/jovyan/test/'   # ← change this to your desired output folder
```

> ℹ️ The folder is created automatically if it does not exist. All products will be extracted into `output_path/Inputs/`.

**Two download modes are available:**

#### Mode 1 — Single Repeat Cycle (one acquisition)

Use this when you only want to test the L1F/L1 chain on a single pass, or when you are exploring the data for the first time.

Downloads **5 products** for the selected acquisition: `RAW_0S` · `RAW_0M` · `AUX_ORB` · `AUX_ATT` · `AUX_TEC`

#### Mode 2 — Full Major Cycle (all 7 repeat passes over the same area)

Use this when you want to run the **complete chain** including STA (stack processor) and L2A (biomass estimate).

The STA step requires multiple repeat acquisitions over the **same geographic frame**. A full major cycle consists of **7 repeat passes** (C01 to C07), acquired every 3 days over the same track and frame. Downloads **7 × 5 = 35 products** in total.

**After a full major cycle download, your `Inputs/` folder will look like this:**

```
Inputs/
├── BIO_AUX_ATT____20251121T094455_20251121T095757_01_DIGNJT   ← ATT repeat cycle 1
├── BIO_AUX_ATT____20251124T094456_20251124T095759_01_DIM8IK   ← ATT repeat cycle 2
├── BIO_AUX_ATT____20251127T094458_20251127T095801_01_DIRRTH
├── BIO_AUX_ATT____20251130T094500_20251130T095803_01_DIXBFI
├── BIO_AUX_ATT____20251203T094502_20251203T095805_01_DJ304W
├── BIO_AUX_ATT____20251206T094504_20251206T095807_01_DJ8HPU
├── BIO_AUX_ATT____20251209T094505_20251209T095809_01_DJE2V5   ← ATT repeat cycle 7
│
├── BIO_AUX_ORB____20251121T094455_20251121T095757_01_DIGNJT   ← ORB repeat cycle 1
├── ...                                                         (7 ORB files)
├── BIO_AUX_ORB____20251209T094505_20251209T095809_01_DJE2V4   ← ORB repeat cycle 7
│
├── BIO_AUX_TEC____20251121T000000_20251121T235959_01_DIFMBZ   ← TEC day 1 (covers full day)
├── ...                                                         (7 TEC files, one per day)
├── BIO_AUX_TEC____20251209T000000_20251209T235959_01_DJCYBJ   ← TEC day 7
│
├── BIO_S1_RAW__0M_20251121T094510_20251121T095758_..._C01_...  ← RAW_0M repeat cycle 1
├── ...                                                          (7 RAW_0M files)
├── BIO_S1_RAW__0M_20251209T094521_20251209T095809_..._C07_...  ← RAW_0M repeat cycle 7
│
├── BIO_S1_RAW__0S_20251121T095253_20251121T095450_..._C01_T006_F062_...  ← RAW_0S repeat cycle 1
├── ...                                                                     (7 RAW_0S files)
└── BIO_S1_RAW__0S_20251209T095304_20251209T095501_..._C07_T006_F062_...  ← RAW_0S repeat cycle 7
```

> ℹ️ All 7 RAW_0S files share the same track (`T006`) and frame (`F062`), acquired 3 days apart from each other. This is exactly the stack of acquisitions the STA processor needs.
----
### Step 2 — Run the Processing Chain (`2_BPS_Run.ipynb`)

This is the main processing notebook. It takes the products you downloaded in Step 1 and produces L2A output.

#### 2.0 — Configuration (edit before running anything)

Open cell 0 and set at minimum these two variables:

```python
INPUT_FOLDER      = "/home/jovyan/my_data/run_001"   # ← your data folder
PROCESSOR_VERSION = "04.43"                           # ← your BPS version (format XX.XX)
MISSION_PHASE     = "TOMOGRAPHIC"                     # ← TOMOGRAPHIC or INTERFEROMETRIC
```

All other paths (conda envs, config dirs, JOBuilder path) are derived automatically.

#### 2.0.1 — Download and Configure AUX Files

Before running any processing step, you need to download the AUX files matching your BPS version.
Go to the [Biomass DISC Release Notes](https://biomass-disc.info/release_note) page, find the release matching your BPS version (e.g. v4.4.3) and download the AUX package.

```bash
cd /home/jovyan/SCRIPTS/CONFIGURATION_FILE
mkdir AUX_443
unzip BIO_AUX_*.ZIP -d AUX_443/
rm *ZIP
```

The folder should look like this:
```
CONFIGURATION_FILE/
└── AUX_443/
    ├── BIO_AUX_INS____...
    ├── BIO_AUX_PP1____...
    ├── BIO_AUX_PP2_2A_...
    └── BIO_AUX_PPS____...
```
Open `/home/jovyan/SCRIPTS/config.ini` and update `AUX_DEFAULT_DIR` to point to your new folder:

```ini
[AUX]
AUX_DEFAULT_DIR = /home/jovyan/SCRIPTS/CONFIGURATION_FILE/AUX_443   # ← update this
```

#### 2.1 — Check Environment

This cell checks whether the `biofetch` conda environment exists. If not, it creates it automatically from `biofetch.yml`. The `biofetch` environment is a lightweight Python environment used only to run `JOBuilder.py` (it does **not** need the full BPS install).

#### 2.2 — Check Input Folder

A quick sanity check that `INPUT_FOLDER/Inputs/` exists and is not empty. If it shows `⚠️ Inputs/ not found`, go back to Step 1 and download the products first.

#### 2.3 — L1F Chain (Framing)

**What it does:** Reads the raw ISP packets (RAW_0S), determines frame boundaries and produces framed L1 virtual products (EOF files, one per frame).

Under the hood this cell:
1. Calls `JOBuilder.py L1F` to generate one JobOrder XML per RAW_0S file, saved in `INPUT_FOLDER/`
2. Runs `bps_l1_framing_processor` on each JobOrder
3. Displays an interactive **folium map** showing the geographic footprint of each detected frame

After the map is displayed, you can choose which frames to process downstream:

```python
SELECTED_FRAMES = []           # empty list = process ALL frames
SELECTED_FRAMES = ["306", "307"]  # specific frame IDs to process
```

The frame IDs visible on the map correspond to the EOF filenames produced inside the `frames_<RAW_0S_name>/` subfolder.

#### 2.4 — L1 Chain (SLC Focusing)

**What it does:** Focuses each selected frame from raw data into a Single Look Complex (SLC) product (`SCS__1S`).

This step requires the additional AUX files (AUX_INS, AUX_PP1) which are looked up automatically by `JOBuilder.py` in the following priority order:
1. `INPUT_FOLDER/Inputs/` (if you placed them there manually)
2. `AUX_USER_DIR` (as configured in `config.ini`)
3. `AUX_DEFAULT_DIR` (as configured in `config.ini`)

Output products are written to `INPUT_FOLDER/OUTPUT_L1/`.

#### 2.5 — STA Chain (Stack Processor)

**What it does:** Stacks multiple SLC products from different repeat cycles that cover the same geographic frame, and produces coherence/interferometric stack products (`STA__1S`).

> ⚠️ This step requires **multiple acquisitions** over the same frame. If you only downloaded a single repeat cycle (Mode 1 above), the STA step will either fail or produce a degenerate result. Use Mode 2 (full major cycle download) for the complete chain.

The `MISSION_PHASE` variable set in cell 0 determines whether the stack is processed as `TOMOGRAPHIC` or `INTERFEROMETRIC`.

Output products are written to `INPUT_FOLDER/OUTPUT_STA_<frame>_V<version>/`.

#### 2.6 — L2A Chain (Biomass Estimation)

**What it does:** Reads the STA stack products and estimates the L2A products for each frame.

Requires the `AUX_PP2_2A_*` file to be present in the AUX directory configured in `config.ini`.

Output products are written to `INPUT_FOLDER/OUTPUT_L2A_<frame>_V<version>/`.

---
## 🔧 Supporting Scripts

### `JOBuilder.py` — JobOrder Generator

This script is called automatically by `2_BPS_Run.ipynb` but can also be run directly from the Terminal if you need fine-grained control.

```bash
python JOBuilder.py <processing_type> <processor_version> <input_folder> [mission_phase]
```

| Argument | Description | Example |
|----------|-------------|---------|
| `processing_type` | One of: `L1F`, `L1`, `L1_chain`, `STA`, `STA_chain`, `L2A`, `L2A_chain` | `L1F` |
| `processor_version` | Format `XX.XX` | `04.43` |
| `input_folder` | Your root processing folder | `/home/jovyan/my_data/run_001` |
| `mission_phase` | Required only for STA/STA_chain | `TOMOGRAPHIC` |

**Examples:**

```bash
# Generate L1F JobOrders
python JOBuilder.py L1F 04.43 /home/jovyan/my_data/run_001

# Generate L1 JobOrders (chain mode, uses EOF frames from L1F output)
python JOBuilder.py L1_chain 04.43 /home/jovyan/my_data/run_001

# Generate STA JobOrders
python JOBuilder.py STA_chain 04.43 /home/jovyan/my_data/run_001 TOMOGRAPHIC

# Generate L2A JobOrders
python JOBuilder.py L2A_chain 04.43 /home/jovyan/my_data/run_001
```

`JOBuilder.py` reads its configuration from `config.ini`, which must be in the **same directory** as `JOBuilder.py`. The config file defines:
- Paths to the XML JobOrder templates (one per processing level)
- Paths to static AUX files (DEM, FNF, GMF, IRI)
- Paths to the AUX directories (default and user-override)

### `config.ini` — Configuration File

```ini
[TEMPLATE_JO]
L1F = /home/jovyan/SCRIPTS/CONFIGURATION_FILE/JO_TEMPLATE/BIO_L1F_P_TEMPLATE_JobOrder.xml
L1  = /home/jovyan/SCRIPTS/CONFIGURATION_FILE/JO_TEMPLATE/BIO_L1_P_TEMPLATE_JobOrder.xml
STA = /home/jovyan/SCRIPTS/CONFIGURATION_FILE/JO_TEMPLATE/BIO_STA_P_TEMPLATE_JobOrder.xml
L2A = /home/jovyan/SCRIPTS/CONFIGURATION_FILE/JO_TEMPLATE/BIO_L2A_P_ALL_TEMPLATE_JobOrder.xml

[AUX_STATIC]
DEM = /home/jovyan/bps/internal_resources/DEM
FNF = /home/jovyan/bps/internal_resources/FNF/
GMF = /home/jovyan/SCRIPTS/CONFIGURATION_FILE/GMF_14
IRI = /home/jovyan/bps/internal_resources/IRI

[AUX]
AUX_DEFAULT_DIR = /home/jovyan/SCRIPTS/CONFIGURATION_FILE/AUX_442
AUX_USER_DIR    = /home/jovyan/SCRIPTS/CONFIGURATION_FILE/AUX_USER
```

> ℹ️ If you installed a different BPS version, update `AUX_DEFAULT_DIR` to point to the matching AUX directory (e.g. `AUX_443` for version 4.4.3).

### `set_environment.bash` — BPS Environment Script

This script activates the BPS conda environment and sets the required `LD_LIBRARY_PATH` for the native L1 framing processor library. It is sourced automatically by the `%%bash` cells inside `2_BPS_Run.ipynb`. You should not need to edit it unless you install a new BPS version.

If you install a new version, update these two lines at the top:

```bash
BPS_DOCKER_TAG="04.43"
BPS_PYTHON_ENV=BPS_443
```

### `footprint_generic_start_stop.py` — Footprint Visualisation

This script is called internally by `2_BPS_Run.ipynb` after the L1F chain to display frame footprints on an interactive map. You can also call it directly from the terminal for a single frame:

```bash
# Compute footprint for a custom time interval
python footprint_generic_start_stop.py \
  --raw_0s   /path/to/Inputs/BIO_S1_RAW__0S_... \
  --aux_orb  /path/to/Inputs/BIO_AUX_ORB___... \
  --start_time 2025-11-21T09:52:53.000000 \
  --stop_time  2025-11-21T09:54:50.000000
```

The script prints the four corner coordinates (lat/lon) of the footprint.

---


## ❓ Common Issues

**The conda solver crashes during installation**
→ Your container RAM is below 20 GB. Request more RAM from the MAAP helpdesk before retrying.

**`❌ No L1F JobOrder files found`**
→ `JOBuilder.py` failed silently. Check `processing_L1F.log` in your `INPUT_FOLDER` for the error. Most likely cause: `config.ini` points to a wrong template path, or there is no `RAW__0S` file in `Inputs/`.

**`⚠️ AUX_INS___ not found`**
→ The `AUX_INS` file is not in `Inputs/`, `AUX_USER_DIR` or `AUX_DEFAULT_DIR`. Make sure `config.ini` points to the correct AUX version folder for your BPS version.

**`No packets found in the specified time interval`** (footprint script)
→ The start/stop times you specified do not overlap with the packets in the RAW_0S file. Check that the times are in the format `YYYY-MM-DDTHH:MM:SS.000000` and fall within the acquisition window.

**The STA step produces an error about insufficient products**
→ You downloaded only a single repeat cycle. The STA stack processor requires multiple acquisitions. Re-download using `get_raws_major_cycle()` instead of `get_raw_repeat_cycle()`.

**`biofetch` environment not found and creation fails**
→ Make sure `biofetch.yml` is present in `~/SCRIPTS/`. This file defines the lightweight Python environment used by `JOBuilder.py`.

