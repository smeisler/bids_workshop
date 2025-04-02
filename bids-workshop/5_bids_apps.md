# Step 3: Preprocessing Data with BIDS-Apps

[BIDS App Bootstrap (BABS)](https://pennlinc-babs.readthedocs.io/en/stable/overview.html) {cite}`zhao2024reproducible` is a user-friendly and generalizable Python package for reproducible image processing at scale. BABS facilitates the reproducible application of BIDS Apps to large-scale datasets.

It is helpful not just for streamlining the parallelization of BIDS apps, but also helps track provenance (that is, knowing what apps produced what data). One of the inputs for BABS is a DataLad-tracked dataset, which we already have from CuBIDS in the previous step! Because of that, we can start with this part of the [BABS Documentation.](https://pennlinc-babs.readthedocs.io/en/stable/preparation_container.html#prepare-containerized-bids-app-as-a-datalad-dataset)

Lets make a folder called `babs` where we will put relevant files for this process. We will assign it to a variable to reference throughout.
```bash
export BABS=/where/you/want/babs
mkdir -p $BABS
```
```{warning}
Do NOT have a lagging slash after `babs/`. It causes some strange issues with DataLad down the line.
```

For this part of the workshop we will first deal with *pre*-processing data. Post-processing will be next!

## Prepare the Containers
I have already built the containers needed for this workshop at `${SHARED_DATA_DIR}/containers/`. 
```bash
ls ${SHARED_DATA_DIR}/containers/
fmriprep-25.0.0.sif  qsiprep-1.0.0.sif  qsirecon-1.0.0.sif  xcpd-0.10.6.sif
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
    --url ${SHARED_DATA_DIR}/containers/fmriprep-25.0.0.sif \
    fmriprep-25-0-0
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
#   BIDS App version: 25.0.0
#   Task:             regular use
#   Which system:     Slurm

# WARNING!!!
#   This is only an example, which may not necessarily fit your purpose,
#   or be an optimized solution for your case,
#   or be compatible to the BIDS App version you're using.
#   Therefore, please change and tailor it for your case before use it!!!

# Files to be copied into the datalad dataset:
imported_files:
    # Change original_path to the path to the file on your local machine
    - original_path: "/users/PAS2965/smeisler/workshop/license.txt"
      analysis_path: "code/license.txt"

# Arguments in `singularity run`:
bids_app_args:
    -w: "$BABS_TMPDIR"
    --stop-on-first-crash: ""
    --fs-license-file: "code/license.txt"
    --output-spaces: "MNI152NLin2009cAsym:res-2"
    --slice-time-ref: "start"
    --skip-bids-validation: ""
    -vv: ""
    --cifti-output: "91k"
    --n_cpus: "$SLURM_CPUS_PER_TASK"
    --mem-mb: "$SLURM_MEM_PER_NODE"

# Arguments that are passed directly to singularity/apptainer:
singularity_args:
    - --containall
    - --writable-tmpfs

# Output foldername(s) to be zipped, and the BIDS App version to be included in the zip filename(s):
#   This fMRIPrep version (25.0.0) generates two folders, 'fmriprep' and 'freesurfer'.
zip_foldernames:
    fmriprep: "25-0-0" # folder 'fmriprep' will be zipped into 'sub-xx_(ses-yy_)fmriprep-25-0-0.zip'

# How much cluster resources it needs:
cluster_resources:
    interpreting_shell: "/bin/bash"
    hard_runtime_limit: "24:00:00"
    customized_text: |
        #SBATCH --nodes=1
        #SBATCH --ntasks=1
        #SBATCH --cpus-per-task=4
        #SBATCH --mem=32G
        #SBATCH --propagate=NONE
        #SBATCH --account=PAS2965

# Activate environment so we have access to Datalad
script_preamble: |
    source ${MAMBA_ROOT_PREFIX}/bin/activate workshop

# Where to run the jobs:
job_compute_space: "/fs/scratch/PAS2965/workshop/babs_tmp/fmriprep"

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
Workshop users will need to change the `#SBATCH --account=PAS2965` line to match your project code on the OSC. Also, you should change `job_compute_space: "/users/PAS2965/smeisler/workshop/tmp/babs_tmp/fmriprep"` to a place where you have storage/scratch space.
```

## Define TemplateFlow
Many BIDS-Apps use a centralized collection of brain templates called [TemplateFlow](https://github.com/templateflow/templateflow) which is a DataLad dataset. Before running `babs-init`, we need to create a copy of this and tell `BABS` where to find it.
```bash
cd $BABS
datalad clone https://github.com/templateflow/templateflow.git
datalad siblings -d "$BABS/templateflow" enable -s public-s3
export TEMPLATEFLOW_HOME=$BABS/templateflow
```

## Run `babs-init`
We can now create the BABS dataset in which we will run all of the processing with the following command (the following is an exmaple for `fmriprep`):
```{note}
Make sure `BIDS` is still defined as the datalad BIDS dataset we created in the previous step!
```

```bash
babs init \
babs_fmriprep \
--datasets BIDS=$BIDS \
--container_ds $BABS/containers_datalad/fmriprep-container/ \
--container_name fmriprep-25-0-0 \
--container_config $BABS/configs/fmriprep-25.0.0.yaml \
--processing_level subject \
--queue slurm 
```

Let's make sure everything is ready to go by running
```bash
babs check-setup --project_root $BABS/babs_fmriprep --job_test
```

### Run a Test Job
Now we can run a test job this with:
```bash
babs submit --project-root $BABS/babs_fmriprep
```

```{warning}
You should complete fMRIPrep before trying to `babs init` XCP_D, and similarly finish QSIPrep before starting with QSIRecon. Both XCP_D and QSIRecon rely on preprocessed data as inputs.
```
You can use the `cat` command to look at the log outputs in `$BABS/babs_fmriprep/analysis/logs` to see progress of the run. More information on job monitoring and status are [here.](https://pennlinc-babs.readthedocs.io/en/stable/jobs.html#)

We can submit all the remaining jobs with
```bash
babs-submit --project-root $BABS/babs_fmriprep --all
```

### Try this yourself!
Now try to do this for QSIPrep. You can borrow the `.yaml` configuration I have made if you are unfamiliar with QSIPrep command line arguents, but try to do the rest of the setup on your own. If you get stuck, an answer key is below:

<details>
    <summary>The `.yaml`</summary>

```bash
# This is an example config yaml file for:
#   BIDS App:         QSIPrep ("qsiprep")
#   BIDS App version: 1.0.0
#   Task:             regular use
#   Which system:     Slurm

# Files to be copied into the datalad dataset:
imported_files:
    # Change original_path to the path to the file on your local machine
    - original_path: "/users/PAS2965/smeisler/workshop/license.txt"
      analysis_path: "code/license.txt"

# Arguments in `singularity run`:
bids_app_args:
    -w: "$BABS_TMPDIR"
    --stop-on-first-crash: ""
    --fs-license-file: "code/license.txt"
    -vv: ""
    --unringing-method: "rpg"
    --output-resolution: "1.5"
    --notrack: ""
    --nthreads: "$SLURM_CPUS_PER_TASK"
    --mem-mb: "$SLURM_MEM_PER_NODE"
    --skip-bids-validation: ""

# Arguments that are passed directly to singularity/apptainer:
singularity_args:
    - --containall
    - --writable-tmpfs

# Output foldername(s) to be zipped, and the BIDS App version to be included in the zip filename(s):
#   As fMRIPrep will use BIDS output layout, we need to ask BABS to create a folder 'qsiprep' to wrap all derivatives:
all_results_in_one_zip: true
zip_foldernames:
    qsiprep: "1-0-0" # folder 'qsiprep' will be zipped into 'sub-xx_(ses-yy_)qsiprep-1-0-0.zip'

# How much cluster resources it needs:
cluster_resources:
    interpreting_shell: "/bin/bash"
    hard_runtime_limit: "24:00:00"
    customized_text: |
        #SBATCH --nodes=1
        #SBATCH --ntasks=1
        #SBATCH --cpus-per-task=4
        #SBATCH --mem=32G
        #SBATCH --propagate=NONE
        #SBATCH --account=PAS2965

# Activate environment so we have access to Datalad
script_preamble: |
    source ${MAMBA_ROOT_PREFIX}/bin/activate workshop

# Where to run the jobs:
job_compute_space: "/fs/scratch/PAS2965/workshop/babs_tmp/qsiprep"

# Below is to filter out subjects (or sessions). Only those with required files will be kept.
required_files:
    $INPUT_DATASET_#1:
        - "dwi/*_dwi.nii*"
        - "anat/*_T1w.nii*"
```
</details>

<details>
    <summary>The rest of the code</summary>

```bash
babs init \
babs_qsiprep \
--datasets BIDS=$BIDS \
--container_ds $BABS/containers_datalad/qsiprep-container/ \
--container_name qsiprep-1-0-0 \
--container_config $BABS/configs/qsiprep-1.0.0.yaml \
--processing_level subject \
--queue slurm

babs check-setup --project_root $BABS/babs_qsiprep --job_test

babs submit --project-root $BABS/babs_qsiprep
```
</details>

### After Jobs have Finished
When all the jobs are done, you can create the zip files for all of the outputs by running
```bash
babs merge --project_root $BABS/babs_fmriprep
```

You can now see the zip files with 
```bash
ls $BABS/babs_fmriprep/merge_ds/
```
and these can be cloned to anywhere with
```bash
datalad clone \
    ria+file://$BABS/babs_fmriprep/output_ria#~data \
    /your/outpath
```
In the directory where you cloned the outputs, you will see the `.zip` files again, but they will just be symlinks you can retrieve the zip files with
```bash
datalad get *.zip # or use the exact filename if you only want a particular file
```
When you are done with those files you can then drop them (saving storage) with
```bash
datalad drop *.zip # or use the exact filename if you only want a particular file
```

Now that we finished fMRIPrep and QSIPrep preprocessing, we will now use those outputs for postprocessing with XCP_D and QSIRecon!