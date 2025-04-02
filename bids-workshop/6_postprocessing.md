# Step 4: Using BABS to Postprocess Data

Now we can use our pre-processed data directly as inputs into out postprocessing apps!

Let's start with QSIRecon. Our `babs-init` run will appear similar, but you may notice one difference:
```bash
babs init \
babs_qsirecon \
--datasets qsiprep=$BABS/babs_qsiprep/merge_ds \
--container_ds $BABS/containers_datalad/qsirecon-container/ \
--container_name qsirecon-1-0-0 \
--container_config $BABS/configs/qsirecon-1.0.0.yaml \
--processing_level subject \
--queue slurm
```
That is, our input to that data is coming directly from the merged outputs of QSIPrep. We also name this input as `qsiprep` when ingressing it.
```{note}
We won't worry about this for the workshop, but the naming of inputs does become important if you have multiple things you are ingressing. For example, if I also needed to add FreeSurfer outputs for QSIrecon, I would have an additional
`--input freesurfer /path/to/freesurfer`
line, and then I can reference `freesurfer` in my config `.yaml`. If you have questions about these more advanced configurations, please let me know!
```

Similar to before, we need to copy our FreeSurfer license file in, and also for this app, a pre-defined `recon_spec`. I show it below in case you are interested, but it short it makes tractography and lots of scalar maps, and returns bundle-wise scalar avergaes in tabular format. These are ready to analyze files!
<details>
    <summary>The recon spec</summary>

```bash
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

Like before, lets make the working directory and put the necessary files into our project with:
```bash
mkdir -p /fs/scratch/PAS2965/workshop/babs_tmp/qsirecon
cp ${FS_LICENSE_FILE} $BABS/babs_qsirecon/analysis/code/license.txt
cp ${RECON_SPEC} $BABS/babs_qsirecon/analysis/code/recon_spec.yaml
datalad save -d $BABS/babs_qsirecon/analysis -m "add FS license and recon spec"
cd $BABS/babs_qsirecon/analysis
datalad push --to input 
```

babs init \
babs_xcpd \
--datasets fmriprep=$BABS/babs_fmriprep/merge_ds \
--container_ds $BABS/containers_datalad/xcpd-container/ \
--container_name xcpd-0-10-6 \
--container_config $BABS/configs/xcpd-0.10.6.yaml \
--processing_level subject \
--queue slurm