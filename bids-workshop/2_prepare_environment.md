# Step 0: Setting Up the Computational Environment

In this step, we install and configure the necessary tools for the workshop. We use **Miniforge** (a minimal Conda installer) with **Mamba** for package management, create a dedicated Conda environment, install additional Python packages, and build container images with Apptainer. But if you have your own Anaconda installation, you can use that.

```{note}
You should NOT be using a shared Anaconda installation, i.e., a module on a computing cluster. You may get permission issues when installing packages, and certain libraries may be unavailble or have various versions available.
```

---

## 1. Install Miniforge
```{note}
You can skip this if you have Anaconda personally insatlled. We like Mamba because it is faster than Anaconda and also has a more permissive license. But you can use your OWN Anaconda installation too.
```

Open your terminal and run the following commands to install Miniforge:

```bash
cd ~
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash Miniforge3-Linux-x86_64.sh
rm Miniforge3-Linux-x86_64.sh
```
Follow the prompts when running `bash Miniforge3-Linux-x86_64.sh`, keeping in mind you can choose where to install Miniforge. You will have to restart your terminal for changes to take effect.

```{note}
The `$(uname)` should not need to be adjusted, but if you’re on a different platform (e.g., macOS), adjust the `Linux` installer name accordingly.
```

## 2. Update All Packages
Update your packages to ensure you have the latest versions:

```bash
mamba update --all
```

## 3. Create a Workshop Environment
Create a new environment (here named `workshop`, but you can name it anything) with the essential packages:

```bash
mamba create -n workshop -c conda-forge pip dcm2bids dcm2niix git git-annex deno nano pydicom tree
```
After the environment is created, clean up the Mamba cache:

```bash
mamba clean --all
```

Now we have to install some additional packages with `pip`.
```bash
mamba activate workshop
pip install CuBIDS pydeface babs
pip cache purge
```

## 4. Configure Git
Since we will be using `git` tools, it is helpful to configure `git` now. That includes running the following two lines (replacing it with your information):
```bash
git config --global user.name "YOUR NAME"
git config --global user.email "YOUR EMAIL"
```

## 5. Build BIDS-Apps Containers
```{note}
Workshop participants can just use the conatiners I have already built. This is more for just your information, or other users. Keep in mind that the versions listed here may not be most up-to-date and you should be encouraged to use the most recent stable versions.
```
To build the BIDS-Apps containers, we will use `apptainer`. Here is the code used to build the containers used in this workshop:
```bash
apptainer build qsiprep-1.0.0.sif docker://pennlinc/qsiprep:1.0.0
apptainer build qsirecon-1.0.0.sif docker://pennlinc/qsirecon:1.0.0
apptainer build fmriprep-24.1.1.sif docker://nipreps/fmriprep:24.1.1
apptainer build xcpd-0.10.6.sif docker://pennlinc/xcp_d:0.10.6
apptainer cache clean
```
These commands pull images from Docker registries and convert them into Apptainer SIF files.

Now you are ready to go!
```{warning}
Keep in mind you will need to `mamba activate workshop` whenever you are working on this entering a new terminal.
```

## 6. Find the Shared Data
```{note}
This is only available for the workshop participants. External users are encouraged to use their own data
```
We will be referencing some shared data I've centralized for this workshop. This contains datasets, code, and the containers we will be using. Run the following command so you can have the path saved to a variable that we can reference later:
```bash
export SHARED_DATA_DIR="/path/to/shared_data"
```
```{warning}
This will have to be defined again if you enter a new terminal.
```
```{note}
This is only available for the workshop participants. External users are encouraged to use their own data.
```