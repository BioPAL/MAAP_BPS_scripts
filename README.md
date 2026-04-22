# MAAP_BPS_scripts

Scripts and notebooks for installation and running the ESA BPS on the ESA MAAP CODING ([ESA MAAP](https://biomass.pal.maap.eo.esa.int/)).

---

## ⚠️ Prerequisites: Check Your RAM Limit and Storage

Before installing the BPS environment, you must check how much memory your container has available.
Run the following commands in the Terminal:

```bash
# Check the real memory limit of your container (cgroup)
echo "$(($(cat /sys/fs/cgroup/memory.max) / 1024 / 1024)) MB"

```

> **Important**: 
> According to **Section 4.1 of the BPS SUM v4.4.1**, the official hardware requirements are:
>
> **Memory:**
> - Minimum RAM: 20 GB
> - Recommended RAM: 64 GB (4 GB/core ratio)
>
> **Storage:**
> - Local storage (for installation): 1 GB
> - Local storage (for output data): 25 GB (peak usage: Stack Processor, TOM phase)
> - Shared memory (for intermediate data): 10 GB (peak usage: L1 Processor, delete-on-consume activated)*
>
> On the ESA MAAP Coding environment, your container RAM limit may be much lower than the minimum required.
> If your limit is below 20 GB, the conda solver will crash (core dump) when trying to install all packages at once.
> In that case, please **open a support ticket to the MAAP helpdesk** to request an increase of your container RAM limit before proceeding with the installation.
