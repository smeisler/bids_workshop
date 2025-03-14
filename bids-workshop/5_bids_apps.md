# Step 3: Processing Data with BIDS-Apps

[BIDS App Bootstrap (BABS)](https://pennlinc-babs.readthedocs.io/en/stable/overview.html) is a user-friendly and generalizable Python package for reproducible image processing at scale. BABS facilitates the reproducible application of BIDS Apps to large-scale datasets.

It is helpful not just for streamlining the parallelization of BIDS apps, but also helps track provenance (that is, knowing what apps produced what data). One of the inputs for BABS is a DataLad-tracked dataset, which we already have from CuBIDS in the previous step! Because of that, we can start with this part of the [BABS Documentation.](https://pennlinc-babs.readthedocs.io/en/stable/preparation_container.html#prepare-containerized-bids-app-as-a-datalad-dataset)

Lets make a folder called `babs` where we will put relevant files for this process. We will assign it to a variable to reference throughout.
```bash
export BABS=/where/you/want/babs
mkdir -p $BABS
```
```{warning}
Do NOT have a lagging slash after `babs/`. It causes some strange issues with DataLad down the line.
```

## Prepare the Containers
I have already built the containers needed for this workshop at `${SHARED_DATA_DIR}/containers/`. 
```bash
ls ${SHARED_DATA_DIR}/containers/
fmriprep-24.1.1.sif  qsiprep-1.0.0.sif  qsirecon-1.0.0.sif  xcpd-0.10.6.sif
```
We will be version tracking these too, so we need to operate them with DataLad. Let's create a place for these conatiners to go, and enter that folder:
```bash
mkdir -p $BABS/containers_datalad/
cd $BABS/containers_datalad/
```
For example, for fMRIPrep we can run:
```bash
datalad create -D "fmriprep container" fmriprep-container
cd fmriprep-container
datalad containers-add \
    --url ${SHARED_DATA_DIR}/containers/fmriprep-24.1.1.sif \
    fmriprep-24-1-1
cd ../
```
```{note}
Note that the last argument for `containers-add` only has dashes, not periods.
```
Do the same for the rest of the containers now.
```bash
datalad create -D "qsiprep container" qsiprep-container
cd qsiprep-container
datalad containers-add \
    --url ${SHARED_DATA_DIR}/containers/qsiprep-1.0.0.sif \
    qsiprep-1-0-0
cd ../

datalad create -D "xcpd container" xcpd-container
cd xcpd-container
datalad containers-add \
    --url ${SHARED_DATA_DIR}/containers/xcpd-0.10.6.sif \
    xcpd-0-10-6
cd ../

datalad create -D "qsirecon container" qsirecon-container
cd qsirecon-container
datalad containers-add \
    --url ${SHARED_DATA_DIR}/containers/qsirecon-1.0.0.sif \
    qsirecon-1-0-0
cd ../
```

## Prepare the Processing YAML Configurations
Now we have to tell `BABS` how we want to run the software. This will be comprehensive, including everything from command line arguments to computational requirements (e.g., memory and CPUs). More documentation about the config file can be found [here](https://pennlinc-babs.readthedocs.io/en/stable/preparation_config_yaml_file.html#) and I encourage you to look through it. But for now we can use ones I have created for this workshop. They can be found on the GitHub repo [herePUTLINKIN](PUTLINKIN) and locally at `${SHARED_DATA_DIR}/PUTLOCATION`.

```bash
# This is an example config yaml file for:
#   BIDS App:         fMRIPrep ("fmriprep")
#   BIDS App version: 24.1.1
#   Task:             regular use
#   Which system:     Slurm

# WARNING!!!
#   This is only an example, which may not necessarily fit your purpose,
#   or be an optimized solution for your case,
#   or be compatible to the BIDS App version you're using.
#   Therefore, please change and tailor it for your case before use it!!!

# Arguments in `singularity run`:
singularity_run:
    -w: "$BABS_TMPDIR"
    --stop-on-first-crash: ""
    --fs-license-file: "code/license.txt"
    --output-spaces: "MNI152NLin2009cAsym:res-2"
    --skip-bids-validation: ""
    -vv: ""
    --cifti-output: "91k"
    --n_cpus: "$SLURM_CPUS_PER_TASK"
    --mem-mb: "$SLURM_MEM_PER_NODE"

# Output foldername(s) to be zipped, and the BIDS App version to be included in the zip filename(s):
#   As fMRIPrep will use BIDS output layout, we need to ask BABS to create a folder 'fmriprep_anat' to wrap all derivatives:
zip_foldernames:
    $TO_CREATE_FOLDER: "true"
    fmriprep: "24-1-1"   # folder 'fmriprep' will be zipped into 'sub-xx_(ses-yy_)fmriprep-24-1-1.zip'

# How much cluster resources it needs:
cluster_resources:
    interpreting_shell: "/bin/bash"
    hard_runtime_limit: "24:00:00"
    customized_text: |
        #SBATCH --nodes=1 
        #SBATCH --ntasks=1
        #SBATCH --cpus-per-task=4
        #SBATCH --mem=30G
        #SBATCH --propagate=NONE
        #SBATCH --account=PAS2965

# Where to run the jobs:
job_compute_space: "/users/PAS2965/smeisler/workshop/tmp/babs_tmp/fmriprep"   # [FIX ME] replace "/path/to/temporary_compute_space" with yours

# Below is to filter out subjects (or sessions). Only those with required files will be kept.
required_files:
    $INPUT_DATASET_#1:
        - "func/*_bold.nii*"
        - "anat/*_T1w.nii*"

# Alert messages that might be found in log files of failed jobs:
#   These messages may be helpful for debugging errors in failed jobs.
alert_log_messages:
    stdout:
        - "Excessive topologic defect encountered"
        - "Cannot allocate memory"
        - "mris_curvature_stats: Could not open file"
        - "Numerical result out of range"
        - "fMRIPrep failed"
```
```{warning}
Workshop users will need to change the `#SBATCH --account=PAS2965` to match your project code on the OSC. Also, you should change `job_compute_space: "/users/PAS2965/smeisler/workshop/tmp/babs_tmp/fmriprep"` to a place where you have storage/scratch space.
```

## Run `babs-init`
### Define TemplateFlow
Many BIDS-Apps use a centralized collection of brain templates called [TemplateFlow](https://github.com/templateflow/templateflow) which is a DataLad dataset. Before running `babs-init`, we need to create a copy of this and tell `BABS` where to find it.
```bash
cd $BABS
datalad clone https://github.com/templateflow/templateflow.git
datalad siblings -d "$BABS/templateflow" enable -s public-s3
export TEMPLATEFLOW_HOME=$BABS/templateflow
```
We can now create the BABS dataset in which we will run all of the processing with the following command (the following is an exmaple for `fmriprep`):
```{note}
Make sure `BIDS` is still defined as the datalad BIDS dataset we created in the previous step!
```

```bash
babs-init \
--where-project $BABS \
--project-name babs_fmriprep \
--input BIDS $BIDS \
--container_ds $BABS/containers_datalad/fmriprep-container/ \
--container_name fmriprep-24-1-1 \
--container_config_yaml_file $BABS/configs/fmriprep-24.1.1.yaml \
--type-session single-ses \
--type-system slurm 
```

Since we defined `--fs-license-file: "code/license.txt"` in the config, we have to move our FreeSurfer license file to `$BABS/babs_fmriprep/analysis/code/`.
```{note}
Make sure `FS_LICENSE_FILE` is defined.
```
```bash
cp ${FS_LICENSE_FILE} $BABS/babs_fmriprep/analysis/code/license.txt
datalad save -d $BABS/babs_fmriprep/analysis -m "add FS license"
cd $BABS/babs_fmriprep/analysis
datalad push --to input 
```
Let's make sure everything is ready to go by running
```bash
babs-check-setup --project_root $BABS/babs_fmriprep --job_test
```

### Run a Test Job
We can now try to run a single test job! We do this with:
```bash
babs-submit --project-root $BABS/babs_fmriprep
```