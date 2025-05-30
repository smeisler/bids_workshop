# Step 4: Using BABS to Postprocess Data

Now we can use our pre-processed data directly as inputs into out postprocessing apps!

## QSIRecon
Let's start with QSIRecon. Our `babs init` run will appear similar.
```bash
cd $BABS
babs init babs_qsirecon --container_ds $BABS/containers_datalad/qsirecon-container/ --container_name qsirecon-1-1-0 --container_config $BABS/configs/qsirecon-1.1.0.yaml --processing_level subject --queue slurm
```
The YAML is below (and also in GitHub and on the cluster):
<details>
    <summary>The YAML file</summary>

```yaml
# This is an example config yaml file for:
#   BIDS App:         QSIRecon ("qsirecon")
#   BIDS App version: 1.1.0
#   Task:             regular use
#   Which system:     Slurm

input_datasets:
    qsiprep:
        required_files:
            - "*_qsiprep*.zip"
        is_zipped: true
        origin_url: "/users/PAS2965/smeisler/workshop/babs/babs_qsiprep/merge_ds"
        path_in_babs: inputs/data/qsiprep
        unzipped_path_containing_subject_dirs: "qsiprep"

# Files to be copied into the datalad dataset:
imported_files:
    # Change original_path to the path to the file on your local machine
    - original_path: "/users/PAS2965/smeisler/workshop/babs/configs/recon_spec.yaml"
      analysis_path: "code/recon_spec.yaml"
    - original_path: ""/fs/ess/PAS2965/shared_data/license.txt""
      analysis_path: "code/license.txt"

# Arguments in `singularity run`:
bids_app_args:
    -w: "$BABS_TMPDIR"
    --fs-license-file: "code/license.txt"
    -vv: ""
    --input-type: "qsiprep"
    --recon-spec: '"${PWD}"/code/recon_spec.yaml'
    --output-resolution: "1.5"
    --nthreads: "$SLURM_CPUS_PER_TASK"
    --mem-mb: "$SLURM_MEM_PER_NODE"

# Arguments that are passed directly to singularity/apptainer:
singularity_args:
    - --containall
    - --writable-tmpfs
    - -B /users/PAS2965/smeisler/workshop/babs/configs/recon_spec.yaml:/code/recon_spec.yaml

# Output foldername(s) to be zipped, and the BIDS App version to be included in the zip filename(s):
#   As qsirecon will use BIDS output layout, we need to ask BABS to create a folder 'qsirecon' to wrap all derivatives:
all_results_in_one_zip: true
zip_foldernames:
    # folder 'qsirecon' will be zipped into 'sub-xx_(ses-yy_)qsirecon-1-1-0.zip'
    qsirecon: "1-1-0"

# How much cluster resources it needs:
cluster_resources:
    interpreting_shell: "/bin/bash"
    hard_runtime_limit: "24:00:00"
    customized_text: |
        #SBATCH --nodes=1
        #SBATCH --ntasks=1
        #SBATCH --cpus-per-task=8
        #SBATCH --mem=32G
        #SBATCH --propagate=NONE
        #SBATCH --account=PAS2965

# Activate environment so we have access to Datalad
script_preamble: |
    source ${MAMBA_ROOT_PREFIX}/bin/activate workshop

# Where to run the jobs:
job_compute_space: "/fs/scratch/PAS2965/workshop/babs_tmp/qsirecon"
```
</details>

You'll notice that our input to that data is coming directly from the merged outputs of QSIPrep. We also name this input as `qsiprep` when ingressing it.
```{note}
We won't worry about this for the workshop, but the naming of inputs does become important if you have multiple things you are ingressing. For example, if I also needed to add FreeSurfer outputs for QSIRecon, I would have an additional input line for freesurfer in the yaml. If you have questions about these more advanced configurations, please let me know!
```

The reconstruction spec I share produces just about every possible metric one could want to analyze for multi-shell DWI data! In short it makes tractography and lots of scalar maps, and returns bundle-wise scalar avergaes in tabular format. These are ready to analyze files!
<details>
    <summary>The recon spec</summary>

```yaml
description: DKI, NODDI, MAPMRI, MSMT CSD, GQI Scalars, AutoTrack (with MSMT CSD)
name: workshop_recon_spec
space: T1w
nodes:

    # Run DKI from DIPY
-   action: DKI_reconstruction
    input: qsirecon
    name: dipy_dki
    parameters:
        write_fibgz: false
        write_mif: false
    qsirecon_suffix: DIPYDKI
    software: Dipy

    # Fit NODDI for WM and GM
-   action: fit_noddi
    input: qsirecon
    name: fit_noddi_wm
    parameters:
        dIso: 0.003
        dPar: 0.0017
        isExvivo: false
    qsirecon_suffix: wmNODDI
    software: AMICO
-   action: fit_noddi
    input: qsirecon
    name: fit_noddi_gm
    parameters:
        dIso: 0.003
        dPar: 0.0011
        isExvivo: false
    qsirecon_suffix: gmNODDI
    software: AMICO

    # Run MAPMRI
-   action: MAPMRI_reconstruction
    input: qsirecon
    name: mapmri_recon
    parameters:
        anisotropic_scaling: false
        bval_threshold: 2000
        dti_scale_estimation: false
        laplacian_regularization: true
        laplacian_weighting: 0.2
        radial_order: 6
        write_fibgz: false
        write_mif: false
    qsirecon_suffix: MAPMRI
    software: Dipy

    # Fit the actual GQI model to the data
-   action: reconstruction
    input: qsirecon
    name: dsistudio_gqi
    parameters:
        method: gqi
    qsirecon_suffix: DSIStudioGQI
    software: DSI Studio

    # Get 3D images of DSI Studio's scalar maps
-   action: export
    input: dsistudio_gqi
    name: gqi_scalars
    qsirecon_suffix: DSIStudioGQI
    software: DSI Studio

    # Perform the registration using the GQI-based QA+ISO
-   action: autotrack_registration
    input: dsistudio_gqi
    name: autotrack_gqi_registration
    # qsirecon_suffix: Don't include here - the map.gz is saved in autotrack
    software: DSI Studio

    # Run MSMT CSD
-   action: csd
    input: qsirecon
    name: msmt_csd
    parameters:
        fod:
            algorithm: msmt_csd
            max_sh:
            - 8
            - 8
            - 8
        mtnormalize: true
        response:
            algorithm: dhollander
    qsirecon_suffix: MSMTAutoTrack
    software: MRTrix3

    # Run Tractography
-   action: fod_fib_merge
    name: create_fod_fib
    # to include the fib file AND the map file
    input: autotrack_gqi_registration
    csd_input: msmt_csd
    # outputs include the FOD fib file and the map file is passed through
    qsirecon_suffix: MSMTAutoTrack
    parameters:
        model: msmt
-   action: autotrack
    input: create_fod_fib
    name: autotrack_fod
    parameters:
        tolerance: 22,26,30
        track_id: Association,Projection,Commissure,Cerebellum
        track_voxel_ratio: 2.0
        yield_rate: 1.0e-06
        model: msmt
    qsirecon_suffix: MSMTAutoTrack
    software: DSI Studio

    # Average scalars in bundles
-   action: bundle_map
    input: autotrack_fod
    name: bundle_means
    scalars_from:
    - gqi_scalars
    - dipy_dki
    - mapmri_recon
    - fit_noddi_wm
    software: qsirecon

    # Map scalars to MNI
-   action: template_map
    input: qsirecon
    name: template_map
    parameters:
        interpolation: NearestNeighbor
    scalars_from:
    - gqi_scalars
    - dipy_dki
    - mapmri_recon
    - fit_noddi_wm
    - fit_noddi_gm
    software: qsirecon
```
</details>

Now, for this application, due to a current bug in QSIRecon, we have to make a quick change to the script. This gives us a good opportunity to show how to make changes in a BABS project (though we plan to fix this bug soon)!

In `$BABS/babs_qsirecon/analysis/code/qsirecon-1-1-0_zip.sh`, add the following line before you see `singularity run`:
```bash
set +e -u -x
```
Then, after the end of that `singularity run` command, reset the default behavior by adding
```bash
set -e -u -x
```
This temporary change will allow the code to continue running even though QSIRecon will have a meaningless error. To save the code, run the following:
```bash
cd $BABS/babs_qsirecon
babs sync-code
```

When this is all done, we can `babs submit` and `babs merge` just as we did before, and you will have all the DWI outputs you could possibly ask for!

## XCP_D
For completeness, the below code can be used to create your XCP_D BABS object.
```bash
cd $BABS
babs init babs_xcpd --container_ds $BABS/containers_datalad/xcpd-container/ --container_name xcpd-0-10-7 --container_config $BABS/configs/xcpd-0.10.7.yaml --processing_level subject --queue slurm
```

<details>
    <summary>The XCP_D YAML</summary>

```yaml
# This is an example config yaml file for:
#   BIDS App:         XCP_D ("xcpd")
#   BIDS App version: 0.10.7
#   Task:             regular use
#   Which system:     Slurm

# Define the input datasets
input_datasets:
    fmriprep:
        required_files:
            - "*_fmriprep*.zip"
        is_zipped: true
        origin_url: "/users/PAS2965/smeisler/workshop/babs/babs_fmriprep/merge_ds"
        unzipped_path_containing_subject_dirs: "fmriprep"
        path_in_babs: inputs/data/fmriprep

# Files to be copied into the datalad dataset:
imported_files:
    # Change original_path to the path to the file on your local machine
    - original_path: "/fs/ess/PAS2965/shared_data/license.txt"
      analysis_path: "code/license.txt"

# Arguments in `singularity run`:
bids_app_args:
    -w: "$BABS_TMPDIR"
    --stop-on-first-crash: ""
    --fs-license-file: "code/license.txt"
    -vv: ""
    --mode: "linc"
    --input-type: "fmriprep"
    --nthreads: "$SLURM_CPUS_PER_TASK"
    --mem-gb: "32"
    --atlases:
        "4S456Parcels \
        Glasser \
        HCP \
        MIDB \
        Tian"

# Arguments that are passed directly to singularity/apptainer:
singularity_args:
    - --containall
    - --writable-tmpfs

# Output foldername(s) to be zipped, and the BIDS App version to be included in the zip filename(s):
#   As fMRIPrep will use BIDS output layout, we need to ask BABS to create a folder 'xcpd' to wrap all derivatives:
all_results_in_one_zip: true
zip_foldernames:
    xcpd: "0-10-7" # folder 'xcpd' will be zipped into 'sub-xx_(ses-yy_)xcpd-0-10-7.zip'

# How much cluster resources it needs:
cluster_resources:
    interpreting_shell: "/bin/bash"
    hard_runtime_limit: "24:00:00"
    customized_text: |
        #SBATCH --nodes=1
        #SBATCH --ntasks=1
        #SBATCH --cpus-per-task=8
        #SBATCH --mem=32G
        #SBATCH --propagate=NONE
        #SBATCH --account=PAS2965

# Activate environment so we have access to Datalad
script_preamble: |
    source ${MAMBA_ROOT_PREFIX}/bin/activate workshop

# Where to run the jobs:
job_compute_space: "/fs/scratch/PAS2965/workshop/babs_tmp/xcpd"
```
</details>

With XCP_D you will have fully postprocessed fMRI data along with connectivity matrices! Note that for other applications like seed-based connectivity and task-based general linear models, I recommend Nilearn, which cannot be run in BABS since it is not a BIDS-app. I am happy to provide suggestions about how to do this outside of BABS though!

## You're Done!!!
With all of your data postprocessed, you are ready to begin your analysis, with the confidence that you have processed your data in a quick, efficient, state-of-the-art, and fully transparent way. Happy neuroimaging!!!!!
