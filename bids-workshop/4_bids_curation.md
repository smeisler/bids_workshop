# Step 2: Curating a BIDS Dataset

Curation of neuroimaging datasets is a critical step in ensuring that your data are well-organized, accurate, and ready for processing by standardized pipelines. [**CuBIDS**](https://cubids.readthedocs.io/en/latest/) {cite}`covitz2022curation` is a specialized tool designed to facilitate the curation of BIDS datasets by automatically identifying and flagging potential issues. Here’s why this step is essential:

1. Quality Assurance and Consistency

- **Standardization:**  
  CuBIDS verifies that every element of your dataset adheres to the BIDS specification. This includes checking file naming, folder structures, and associated metadata, which helps maintain consistency across large, multi-site or multi-session datasets.

- **Error Detection:**  
  By automatically identifying inconsistencies, missing files, or mislabeling, CuBIDS allows you to address problems early—preventing errors from propagating through your data processing pipelines.

2. Enhanced Reproducibility

- **Reliable Analyses:**  
  A curated dataset minimizes the risk of errors that could compromise your neuroimaging analyses. When all files are in a predictable, standardized format, downstream tools like fMRIPrep or qsiprep can operate more reliably, ultimately leading to reproducible results.

- **Transparent Documentation:**  
  Automated curation provides a record of detected issues and the corrections applied. This level of documentation is crucial for ensuring transparency in your research methods and for facilitating reproducibility by other researchers.

3. Facilitating Collaboration and Data Sharing

- **Interoperability:**  
  Standardized datasets are easier to share with collaborators and integrate into multi-site studies. When everyone adheres to the same conventions, the barrier to entry for using and analyzing shared data is greatly reduced.

- **User Confidence:**  
  Well-curated data build confidence among lab members and external collaborators, ensuring that analyses are based on high-quality, standardized inputs.

## Step 1: Let's look at our data
For the rest of this workshop (unless you want to look at your own data), we will be using a different dataset that I have pre-BIDSified. It can be found in `${SHARED_DATA_DIR}/grmpy_bids/bids_orig`. I only made a few modifications after dicom conversion. Those were:
1. Deleting original non-defaced anatomicals and dicoms (for privacy)
2. Removing some protected health information (PHI; for privacy)
3. Alphabetizing the json metadata fields (for convenience / readability)
4. Added some information to the `dataset_description.json` and `README`
5. Added participant names to `participants.tsv` (false information for privacy)

The first thing you will do is to create your own copy (*not a symlink*) of the data, then we will redefine this as `BIDS`.
```bash
cp -r $SHARED_DATA_DIR/grmpy_bids/bids_orig /path/where/you/want/BIDS_Dataset_DataLad
export BIDS=/path/where/you/want/bids_orig/
```
From here we will essentially be following the [great CuBIDS documentation.](https://cubids.readthedocs.io/en/latest/example.html)

We will be using [DataLad](https://www.datalad.org/) to version control our dataset. It is a pretty amazing tool. But before we version control everything, lets confirm that there is no PHI that we should remove. We can run the following, which prints out all available json metadata fields:
```bash
cubids print-metadata-fields $BIDS
```
which returns:
```{raw} html
<div style="overflow-y: auto; max-height: 200px;">
<pre>
Loading BIDS schema version: 0.11.3. BIDS version: 1.10.0
Acknowledgments
AcquisitionMatrixPE
AcquisitionNumber
AcquisitionTime
Authors
B0FieldIdentifier
B0FieldSource
BIDSVersion
BandwidthPerPixelPhaseEncode
BaseResolution
BidsGuess
BodyPartExamined
CoilCombinationMethod
ConsistencyInfo
ConversionSoftware
ConversionSoftwareVersion
DatasetDOI
Dcm2bidsVersion
DerivedVendorReportedEchoSpacing
DeviceSerialNumber
DiffusionScheme
DwellTime
EchoNumber
EchoTime
EchoTime1
EchoTime2
EchoTrainLength
EffectiveEchoSpacing
FlipAngle
Funding
HowToAcknowledge
ImageComments
ImageOrientationPatientDICOM
ImageOrientationText
ImageType
ImagingFrequency
InPlanePhaseEncodingDirectionDICOM
InstitutionAddress
InstitutionName
InstitutionalDepartmentName
IntendedFor
InversionTime
License
MRAcquisitionType
MagneticFieldStrength
Manufacturer
ManufacturersModelName
MatrixCoilMode
Modality
MultibandAccelerationFactor
Name
NonlinearGradientCorrection
ParallelReductionFactorInPlane
PartialFourier
PatientName
PatientPosition
PercentPhaseFOV
PercentSampling
PhaseEncodingDirection
PhaseEncodingSteps
PhaseResolution
PixelBandwidth
ProcedureStepDescription
ProtocolName
PulseSequenceDetails
ReceiveCoilActiveElements
ReceiveCoilName
ReconMatrixPE
RefLinesPE
ReferencesAndLinks
RepetitionTime
SAR
ScanOptions
ScanningSequence
SequenceName
SequenceVariant
SeriesDescription
SeriesNumber
ShimSetting
SliceThickness
SliceTiming
SoftwareVersions
SpacingBetweenSlices
SpoilingState
StationName
TaskName
TotalReadoutTime
TxRefAmp
VariableFlipAngleFlag
WipMemBlock
age
group
sex
</pre>
</div>
```

```{note}
The lowercase `age` and `sex` are from the `participants.json` file.
```

For this exercise, I added a fake `PatientName` to one of the files, which is **DEFINITELY** PHI that should be removed. We can remove it with:

```bash
cubids remove-metadata-fields $BIDS --fields PatientName
```
Rerunning the `print-metadata-fields` command now should reveal that `PatientName` is no longer present.

## Step 2: Check the Dataset into DataLad
Now we are going to create a version-controlled version of our dataset, starting with initializing an empty directory:
```bash
datalad create -c text2git /path/where/you/want/BIDS_Dataset_DataLad
```
Now let's copy our files from the original BIDS directory to the tracked version:
```bash
cp -r $BIDS/* /path/where/you/want/BIDS_Dataset_DataLad
```
When that's done we can safely remove our original BIDS data and redefine `BIDS` to be our tracked version moving forward:
```bash
rm -rf $BIDS/
export BIDS=/path/where/you/want/BIDS_Dataset_DataLad
```

We can see that in our tracked version, we now have new data that is waiting to be saved. `cd $BIDS && datalad status` returns:
```bash
untracked: CHANGES (file)
untracked: README (file)
untracked: dataset_description.json (file)
untracked: participants.json (file)
untracked: participants.tsv (file)
untracked: sub-20017 (directory)
untracked: sub-20153 (directory)
untracked: sub-20326 (directory)
untracked: sub-20461 (directory)
untracked: sub-20589 (directory)
untracked: sub-20649 (directory)
untracked: sub-20809 (directory)
untracked: sub-20888 (directory)
untracked: sub-20963 (directory)
untracked: sub-21016 (directory)
untracked: task-fracback_acq-singleband_events.tsv (file)
```

Let's save these initial versions of our data now:
```bash
datalad save -d $BIDS -m "checked dataset into datalad"
```

We can see this is now tracked when we run ``cd $BIDS && git log``:
```bash
commit 3f1d126550fe8ccec2d143ee3c8347e64f807aa4 (HEAD -> master)
Author: Steven Meisler <steven.meisler@pennmedicine.upenn.edu>
Date:   Thu Mar 13 14:28:27 2025 -0400

    checked dataset into datalad

commit 91e457485db085252ee7a1d04dc010393537f24d
Author: Steven Meisler <steven.meisler@pennmedicine.upenn.edu>
Date:   Thu Mar 13 14:23:29 2025 -0400

    Instruct annex to add text files to Git

commit e6ebaab0c0740518425091398d5cf940b41618ff
Author: Steven Meisler <steven.meisler@pennmedicine.upenn.edu>
Date:   Thu Mar 13 14:23:27 2025 -0400

    [DATALAD] new dataset
```
### Step 3: Add NIFTI data to the JSONS
Next, we seek to add more image parameters to our sidecars so that we can better define our Entity Sets. Historically, only a subset of parameters in the NIfTI image header have been included in a BIDS sidecar… Parameters such as image dimensions, number of volumes, image obliquity, and voxel sizes — all important data that can change how our pipelines will eventually run!

To add them to the sidecar metadata, run:
```bash
cubids add-nifti-info $BIDS --use-datalad
```
The `--use-datalad` flag saves the changes for you! Now we can see the following fields were added to our image files:
```bash
Dim1Size
Dim2Size
Dim3Size
NumVolumes
Obliquity
VoxelSizeDim1
VoxelSizeDim2
VoxelSizeDim3
```
### Step 4: Run CuBIDS Validation
`CuBIDS` uses the BIDS validator output to create tabular summaries of validation errors and warnings. We already know our dataset here is valid, and we are not concerned with any of the warnings, but this is still good to have.
```bash
cubids validate $BIDS v0
```
This validates the data and creates validation summaries in `$BIDS/code/CuBIDS/`.

If there were errors (e.g., a scan was missing too many volumes from being stopped early) and you wanted to safely purge the volume from the dataset, while updating the `IntendedFor` accordingly, refer to the `cubids purge` function documented [here.](https://cubids.readthedocs.io/en/latest/example.html#bids-validation)

Now that we added the `v0` validation summaries to the `code` directory, we have to `datalad save` our status before we proceed:
```bash
datalad save -d $BIDS -m "Ran v0 validation"
```

### Step 5: Check for Variant Groups
Using the metadata of the images, `CuBIDS` will check for images that have variants in fields such as voxel dimensions, repetition times, and other important fields. To do that, we run:
```bash
cubids group $BIDS v0
```
Now let's look at the outputs with `cat $BIDS/code/CuBIDS/v0_AcqGroupInfo.txt`:
```bash
1 9 ('datatype-anat_reconstruction-defaced_suffix-T1w', 1) ('datatype-anat_reconstruction-defaced_suffix-T2w', 1) ('datatype-dwi_direction-AP_suffix-dwi_acquisition-multiband', 1) ('datatype-fmap_direction-PA_fmap-epi_suffix-epi_acquisition-multiband', 1) ('datatype-fmap_fmap-magnitude1_suffix-magnitude1', 1) ('datatype-fmap_fmap-magnitude2_suffix-magnitude2', 1) ('datatype-fmap_fmap-phasediff_suffix-phasediff', 1) ('datatype-func_suffix-bold_task-fracback_acquisition-singleband', 1) ('datatype-func_suffix-bold_task-rest_acquisition-multiband', 1) ('datatype-func_suffix-bold_task-rest_acquisition-singleband', 1)
2 1 ('datatype-anat_reconstruction-defaced_suffix-T1w', 1) ('datatype-anat_reconstruction-defaced_suffix-T2w', 1) ('datatype-dwi_direction-AP_suffix-dwi_acquisition-multiband', 1) ('datatype-fmap_direction-PA_fmap-epi_suffix-epi_acquisition-multiband', 1) ('datatype-fmap_fmap-magnitude1_suffix-magnitude1', 1) ('datatype-fmap_fmap-magnitude2_suffix-magnitude2', 2) ('datatype-fmap_fmap-phasediff_suffix-phasediff', 2) ('datatype-func_suffix-bold_task-fracback_acquisition-singleband', 2) ('datatype-func_suffix-bold_task-rest_acquisition-multiband', 2) ('datatype-func_suffix-bold_task-rest_acquisition-singleband', 2)
```
We can see that there are two groups of this data. A dominant group with 9 subjects, and another group with one subject that had variant BOLD runs and a magnitude2 and phasediff fieldmap file. We see with `cat $BIDS/code/CuBIDS/v0_AcqGrouping.tsv` that the subject is `sub-20017`.

How were these files different? 
Looking at `cat $BIDS/code/CuBIDS/v0_summary.tsv`, we see that the variants have names: 
```bash
datatype-fmap_fmap-magnitude2_suffix-magnitude2_acquisition-VARIANTMultibandAccelerationFactor2
datatype-fmap_fmap-phasediff_suffix-phasediff_acquisition-VARIANTMultibandAccelerationFactor2
datatype-func_suffix-bold_task-fracback_acquisition-singlebandVARIANTObliquityFalse
datatype-func_suffix-bold_task-rest_acquisition-multibandVARIANTObliquityFalse
datatype-func_suffix-bold_task-rest_acquisition-singlebandVARIANTObliquityFalse
```
This implies that our variant subject's fieldmaps had different Multiband Acceleration Factors and BOLD files that were not acquired obliquely.
```{note}
This is an odd dataset in which non-oblique was variant. Most data isn't collected obliquely! Note that `fMRIPrep` and `QSIPrep` can handle oblique files fine, but it has to make adjustments, so this is good to note.
```

Following instructions [here](https://cubids.readthedocs.io/en/latest/example.html#visualizing-metadata-heterogeneity), we can decide how we want these variants renamed and whether we want to keep them in the dataset. But for the sake of this exercise, we will use the default renaming scheme and not do any purging.

We save our progress before proceeding:
```bash
datalad save -d $BIDS -m "run cubids grouping"
```

## Apply the Variant Renaming
Now we want to rename our files to indicate the variant groups. Note that if we were to do this manually, we might miss important details like updating paths in `IntendedFor` entries, and `CuBIDS` takes care of this for us! We can apply our renaming with:

```bash
cubids apply $BIDS v0_summary.tsv v0_files.tsv v1 --use-datalad
```
```{note}
This step can take a long time on large datasets, and could be worth submitting to a compute node.
```

When this finishes, we see that the variant subject's files have been renamed, with `ls $BIDS/sub-20017/ses-1/func`:
```bash
sub-20017_ses-1_task-fracback_acq-singlebandVARIANTObliquityFalse_bold.json    sub-20017_ses-1_task-rest_acq-multibandVARIANTObliquityFalse_bold.nii.gz
sub-20017_ses-1_task-fracback_acq-singlebandVARIANTObliquityFalse_bold.nii.gz  sub-20017_ses-1_task-rest_acq-singlebandVARIANTObliquityFalse_bold.json
sub-20017_ses-1_task-rest_acq-multibandVARIANTObliquityFalse_bold.json         sub-20017_ses-1_task-rest_acq-singlebandVARIANTObliquityFalse_bold.nii.gz
```
and in the fieldmaps, we see, with `cat $BIDS/sub-20017/ses-1/fmap/sub-20017_ses-1_phasediff.json`:
```json
{
"IntendedFor": [
        "ses-1/func/sub-20017_ses-1_task-fracback_acq-singlebandVARIANTObliquityFalse_bold.nii.gz",
        "ses-1/func/sub-20017_ses-1_task-rest_acq-multibandVARIANTObliquityFalse_bold.nii.gz",
        "ses-1/func/sub-20017_ses-1_task-rest_acq-singlebandVARIANTObliquityFalse_bold.nii.gz"
    ]
}
```

`CuBIDS` errantly put a file called `v1_full_cmd.sh` in the BIDS root directory. Let's move it to the code directory:
```bash
mv $BIDS/v1_full_cmd.sh $BIDS/code/CuBIDS/
```
Rerunning the BIDS validator (while ignoring warnings) reveals the dataset is still valid:
```bash
deno run -ERWN jsr:@bids/validator $PWD --ignoreWarnings

This dataset appears to be BIDS compatible.

          Summary:                          Available Tasks:        Available Modalities:
          246 Files, 7.95 GB                Fractal N-Back          MRI
          10 - Subjects 1 - Sessions        Resting State

	If you have any questions, please post on https://neurostars.org/tags/bids.
```

If wanted to be *really* careful, we can create an exemplar dataset that has one subject per variant group to test our pipelines. That could be helpful for large datasets with several variants. But for our purposes, we will just proceed with processing everyone.