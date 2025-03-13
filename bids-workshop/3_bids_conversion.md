# Step 1: Converting Dicoms to a BIDS Dataset
One of the first steps in any BIDS-based neuroimaging workflow is converting your raw DICOM files into the standardized BIDS format. This step ensures that your data are organized in a consistent, predictable way, making downstream processing much more straightforward.

For this, we will be using the Python-based software [dcm2bids](https://github.com/UNFmontreal/Dcm2Bids). This is one that I am particularly used to, works well, and is actively maintained. There are certainly alternatives though, such as [BIDSCoin](https://github.com/Donders-Institute/bidscoin) and [heudiconv](https://github.com/nipy/heudiconv) are also fine choices!

We have already installed `dcm2bids` and it's dependencies in to our computational environment earlier in [Step 0](2_prepare_environment.md#create-a-workshop-environment). However, it can also be run via an Apptainer/Docker container.

## Prepare a BIDS Directory
First, lets create a BIDS directory scaffold that contains empty files and folders that we can amend later.

If not already active, activate your computational environment.
```bash
mamba activate workshop
```

We can start by defining, creating, and entering what will become our `dcm2bids` example BIDS directory. We will assign it to a variable name that we will reference throughout, so feel free to put it whereever makes sense for you!

```bash
export BIDS=/path/to/your/dcm2bids_example/
mkdir -p $BIDS
cd $BIDS
```
```{warning}
`$BIDS` will need to be redefined if you enter a new terminal
```
Using `dcm2bids` we will now create the scaffold (empty BIDS-standard files and folders).
```bash
dcm2bids_scaffold
```
```{warning}
This command is only meant to be run on an **EMPTY** folder. Running this on a non-empty folder may delete/overwrite files!
```
You should see the following files/folders were created (revealed by running `tree $BIDS`):
```bash
├── CHANGES
├── README
├── code
├── dataset_description.json
├── derivatives
├── participants.json
├── participants.tsv
├── sourcedata
└── tmp_dcm2bids
    └── log
        └── scaffold_20250312-230726.log
```
```{note}
There are more files that *can* be in BIDS datasets, described in detail [here.](https://bids-specification.readthedocs.io/en/stable/modality-agnostic-files.html). But these are ones that minimally required and/or commonly used.
```
Very briefly:
- `CHANGES` is meant to describe how your dataset has changed over time (e.g., different versions, if data were reconverted, etc.)
- `README` is a document meant to describe the dataset and provide other information that would help a user (e.g., explaining why a subject is missing a scan). It is also fairly commonplace to put the [BIDS-validator](https://github.com/bids-standard/bids-validator) log in the `README`.
- `code` is where your code goes. It is helpful to have subfolders within `code` for each process.
- `dataset_description.json` contains fields that describe that dataset, and these fields (which ones are required or optional) are defined [here.](https://bids-specification.readthedocs.io/en/stable/modality-agnostic-files.html#dataset_descriptionjson)
- `derivatives` contains outputs derived from processing workflows.
```{note}
Although, since many BIDS-apps now output BIDS-valid directories as outputs, it is now being encouraged to put derivatives outside of the raw BIDS root directory. This makes tracking data provenance and sharing easier, among other advantages. See more [here.](https://nipoppy.readthedocs.io/en/latest/#nipoppy).
```
- `participants.tsv` and `participants.tsv` contain tabular data about your subjects.
```{warning}
The TSV will contain placeholder subject names and data that will have to be updated when you actually make your dataset. Mismatches in subject IDswill lead to BIDS validation errors.
```
- `sourcedata` is a folder in which you should put the data used to create what goes into your BIDS subject folders. This should definitely include dicoms, but also things like scanner logs that can be used to create [events files for task fMRI](https://bids-specification.readthedocs.io/en/stable/modality-specific-files/task-events.html).
```{note}
There are no strict BIDS convention for how data are organized within `code` or `sourcedata`. Still it is important to make it as human readable and intuitive as possible.
```
- `tmp_dcm2bids` is a folder that contains temporary outputs and logs from `dcm2bids` processes. This can be safely deleted when conversion is done.
```{note}
`tmp_dcm2bids` is not a BIDS-valid folder name, but `dcm2bids` automatically puts it in a `.bidsignore` file, which is present in your dataset (but invisible because it starts with a `.`). It is generally considered good practice to *minimize* the amount of files/folders in `.bidsignore`, and strive to make everything as BIDS valid as possible.
```

The only thing left to make now are the subject folders!

## Copy the Sourcedata Dicoms
For this part of the workshop we will just be converting one subject (with two sessions of data) to BIDS format, while creating the necessary dataset-level files that are necessary for BIDS. The metadata from these dicoms have been anonymized.

Since Dicom sets are large, we can just create *symlinks* (or shortcuts) to the centralized files, so we aren't wasting storage space.

```bash
ln -s ${SHARED_DATA_DIR}/ef_example/sourcedata/dicoms ${BIDS}/sourcedata/dicoms
```

I made everything in `${SHARED_DATA_DIR}` read-only, which is all you'll need for this workshop. If you want your own copy that you have more permissions to play around with, you can instead run:

```bash
cp -r ${SHARED_DATA_DIR}/ef_example/sourcedata/dicoms ${BIDS}/sourcedata/dicoms
```

## Make a `dcm2bids` Configuration File
`dcm2bids` in short does the following under-the-hood
1. Runs `dcm2niix` on your dicoms to convert the dicoms to NIFTIS and JSONS.
2. Reads in a configuration file **you** make, that pairs criterion defined on metadata (that is, in the JSONS) to what BIDS file type you want.
3. Renames and reorganizes data based on the criterion-matching and specific naming elements you define.

### Run the Helper
For Step 2, you need to parse through a set of `dcm2niix` to know what metadata are in the json files.

To create this, run:
```bash
cd $BIDS
dcm2bids_helper -d sourcedata/dicoms/sub-22473/ses-01/
```
After a while, you will see a set of niftis (`*.nii.gz`) and jsons (`*.json`) in `$BIDS/tmp_dcm2bids/helper`, for example by running `ls $SHARED_DATA_DIR/ef_example/tmp_dcm2bids/helper`.
```{raw} html
<div style="overflow-y: auto; max-height: 200px;">
<pre>
001_ses-01_anat-scout_20220312111910_i00001.json
001_ses-01_anat-scout_20220312111910_i00001.nii.gz
001_ses-01_anat-scout_20220312111910_i00002.json
001_ses-01_anat-scout_20220312111910_i00002.nii.gz
001_ses-01_anat-scout_20220312111910_i00003.json
001_ses-01_anat-scout_20220312111910_i00003.nii.gz
002_ses-01_anat_acq-vnavsetter-BodyCoil_T1w_20220312111910.json
002_ses-01_anat_acq-vnavsetter-BodyCoil_T1w_20220312111910.nii.gz
003_ses-01_anat_T1w_20220312111910_i00001.json
003_ses-01_anat_T1w_20220312111910_i00001.nii.gz
003_ses-01_anat_T1w_20220312111910_i00033.json
003_ses-01_anat_T1w_20220312111910_i00033.nii.gz
003_ses-01_anat_T1w_20220312111910_i00065.json
003_ses-01_anat_T1w_20220312111910_i00065.nii.gz
003_ses-01_anat_T1w_20220312111910_i00097.json
003_ses-01_anat_T1w_20220312111910_i00097.nii.gz
003_ses-01_anat_T1w_20220312111910_i00129.json
003_ses-01_anat_T1w_20220312111910_i00129.nii.gz
003_ses-01_anat_T1w_20220312111910_i00161.json
003_ses-01_anat_T1w_20220312111910_i00161.nii.gz
003_ses-01_anat_T1w_20220312111910_i00193.json
003_ses-01_anat_T1w_20220312111910_i00193.nii.gz
003_ses-01_anat_T1w_20220312111910_i00225.json
003_ses-01_anat_T1w_20220312111910_i00225.nii.gz
003_ses-01_anat_T1w_20220312111910_i00257.json
003_ses-01_anat_T1w_20220312111910_i00257.nii.gz
003_ses-01_anat_T1w_20220312111910_i00289.json
003_ses-01_anat_T1w_20220312111910_i00289.nii.gz
003_ses-01_anat_T1w_20220312111910_i00321.json
003_ses-01_anat_T1w_20220312111910_i00321.nii.gz
003_ses-01_anat_T1w_20220312111910_i00353.json
003_ses-01_anat_T1w_20220312111910_i00353.nii.gz
003_ses-01_anat_T1w_20220312111910_i00385.json
003_ses-01_anat_T1w_20220312111910_i00385.nii.gz
003_ses-01_anat_T1w_20220312111910_i00417.json
003_ses-01_anat_T1w_20220312111910_i00417.nii.gz
003_ses-01_anat_T1w_20220312111910_i00449.json
003_ses-01_anat_T1w_20220312111910_i00449.nii.gz
003_ses-01_anat_T1w_20220312111910_i00481.json
003_ses-01_anat_T1w_20220312111910_i00481.nii.gz
003_ses-01_anat_T1w_20220312111910_i00513.json
003_ses-01_anat_T1w_20220312111910_i00513.nii.gz
003_ses-01_anat_T1w_20220312111910_i00545.json
003_ses-01_anat_T1w_20220312111910_i00545.nii.gz
003_ses-01_anat_T1w_20220312111910_i00577.json
003_ses-01_anat_T1w_20220312111910_i00577.nii.gz
003_ses-01_anat_T1w_20220312111910_i00609.json
003_ses-01_anat_T1w_20220312111910_i00609.nii.gz
003_ses-01_anat_T1w_20220312111910_i00641.json
003_ses-01_anat_T1w_20220312111910_i00641.nii.gz
003_ses-01_anat_T1w_20220312111910_i00673.json
003_ses-01_anat_T1w_20220312111910_i00673.nii.gz
003_ses-01_anat_T1w_20220312111910_i00705.json
003_ses-01_anat_T1w_20220312111910_i00705.nii.gz
003_ses-01_anat_T1w_20220312111910_i00737.json
003_ses-01_anat_T1w_20220312111910_i00737.nii.gz
003_ses-01_anat_T1w_20220312111910_i00769.json
003_ses-01_anat_T1w_20220312111910_i00769.nii.gz
003_ses-01_anat_T1w_20220312111910_i00801.json
003_ses-01_anat_T1w_20220312111910_i00801.nii.gz
003_ses-01_anat_T1w_20220312111910_i00833.json
003_ses-01_anat_T1w_20220312111910_i00833.nii.gz
003_ses-01_anat_T1w_20220312111910_i00865.json
003_ses-01_anat_T1w_20220312111910_i00865.nii.gz
003_ses-01_anat_T1w_20220312111910_i00897.json
003_ses-01_anat_T1w_20220312111910_i00897.nii.gz
003_ses-01_anat_T1w_20220312111910_i00929.json
003_ses-01_anat_T1w_20220312111910_i00929.nii.gz
003_ses-01_anat_T1w_20220312111910_i00961.json
003_ses-01_anat_T1w_20220312111910_i00961.nii.gz
003_ses-01_anat_T1w_20220312111910_i00993.json
003_ses-01_anat_T1w_20220312111910_i00993.nii.gz
003_ses-01_anat_T1w_20220312111910_i01025.json
003_ses-01_anat_T1w_20220312111910_i01025.nii.gz
003_ses-01_anat_T1w_20220312111910_i01057.json
003_ses-01_anat_T1w_20220312111910_i01057.nii.gz
003_ses-01_anat_T1w_20220312111910_i01089.json
003_ses-01_anat_T1w_20220312111910_i01089.nii.gz
003_ses-01_anat_T1w_20220312111910_i01121.json
003_ses-01_anat_T1w_20220312111910_i01121.nii.gz
003_ses-01_anat_T1w_20220312111910_i01153.json
003_ses-01_anat_T1w_20220312111910_i01153.nii.gz
003_ses-01_anat_T1w_20220312111910_i01185.json
003_ses-01_anat_T1w_20220312111910_i01185.nii.gz
003_ses-01_anat_T1w_20220312111910_i01217.json
003_ses-01_anat_T1w_20220312111910_i01217.nii.gz
003_ses-01_anat_T1w_20220312111910_i01249.json
003_ses-01_anat_T1w_20220312111910_i01249.nii.gz
003_ses-01_anat_T1w_20220312111910_i01281.json
003_ses-01_anat_T1w_20220312111910_i01281.nii.gz
003_ses-01_anat_T1w_20220312111910_i01313.json
003_ses-01_anat_T1w_20220312111910_i01313.nii.gz
003_ses-01_anat_T1w_20220312111910_i01345.json
003_ses-01_anat_T1w_20220312111910_i01345.nii.gz
003_ses-01_anat_T1w_20220312111910_i01377.json
003_ses-01_anat_T1w_20220312111910_i01377.nii.gz
003_ses-01_anat_T1w_20220312111910_i01409.json
003_ses-01_anat_T1w_20220312111910_i01409.nii.gz
003_ses-01_anat_T1w_20220312111910_i01441.json
003_ses-01_anat_T1w_20220312111910_i01441.nii.gz
003_ses-01_anat_T1w_20220312111910_i01473.json
003_ses-01_anat_T1w_20220312111910_i01473.nii.gz
003_ses-01_anat_T1w_20220312111910_i01505.json
003_ses-01_anat_T1w_20220312111910_i01505.nii.gz
003_ses-01_anat_T1w_20220312111910_i01537.json
003_ses-01_anat_T1w_20220312111910_i01537.nii.gz
003_ses-01_anat_T1w_20220312111910_i01569.json
003_ses-01_anat_T1w_20220312111910_i01569.nii.gz
003_ses-01_anat_T1w_20220312111910_i01601.json
003_ses-01_anat_T1w_20220312111910_i01601.nii.gz
003_ses-01_anat_T1w_20220312111910_i01633.json
003_ses-01_anat_T1w_20220312111910_i01633.nii.gz
003_ses-01_anat_T1w_20220312111910_i01665.json
003_ses-01_anat_T1w_20220312111910_i01665.nii.gz
003_ses-01_anat_T1w_20220312111910_i01697.json
003_ses-01_anat_T1w_20220312111910_i01697.nii.gz
003_ses-01_anat_T1w_20220312111910_i01729.json
003_ses-01_anat_T1w_20220312111910_i01729.nii.gz
003_ses-01_anat_T1w_20220312111910_i01761.json
003_ses-01_anat_T1w_20220312111910_i01761.nii.gz
003_ses-01_anat_T1w_20220312111910_i01793.json
003_ses-01_anat_T1w_20220312111910_i01793.nii.gz
003_ses-01_anat_T1w_20220312111910_i01825.json
003_ses-01_anat_T1w_20220312111910_i01825.nii.gz
003_ses-01_anat_T1w_20220312111910_i01857.json
003_ses-01_anat_T1w_20220312111910_i01857.nii.gz
003_ses-01_anat_T1w_20220312111910_i01889.json
003_ses-01_anat_T1w_20220312111910_i01889.nii.gz
003_ses-01_anat_T1w_20220312111910_i01921.json
003_ses-01_anat_T1w_20220312111910_i01921.nii.gz
003_ses-01_anat_T1w_20220312111910_i01953.json
003_ses-01_anat_T1w_20220312111910_i01953.nii.gz
003_ses-01_anat_T1w_20220312111910_i01985.json
003_ses-01_anat_T1w_20220312111910_i01985.nii.gz
003_ses-01_anat_T1w_20220312111910_i02017.json
003_ses-01_anat_T1w_20220312111910_i02017.nii.gz
003_ses-01_anat_T1w_20220312111910_i02049.json
003_ses-01_anat_T1w_20220312111910_i02049.nii.gz
003_ses-01_anat_T1w_20220312111910_i02081.json
003_ses-01_anat_T1w_20220312111910_i02081.nii.gz
003_ses-01_anat_T1w_20220312111910_i02113.json
003_ses-01_anat_T1w_20220312111910_i02113.nii.gz
003_ses-01_anat_T1w_20220312111910_i02145.json
003_ses-01_anat_T1w_20220312111910_i02145.nii.gz
003_ses-01_anat_T1w_20220312111910_i02177.json
003_ses-01_anat_T1w_20220312111910_i02177.nii.gz
003_ses-01_anat_T1w_20220312111910_i02209.json
003_ses-01_anat_T1w_20220312111910_i02209.nii.gz
003_ses-01_anat_T1w_20220312111910_i02241.json
003_ses-01_anat_T1w_20220312111910_i02241.nii.gz
003_ses-01_anat_T1w_20220312111910_i02273.json
003_ses-01_anat_T1w_20220312111910_i02273.nii.gz
003_ses-01_anat_T1w_20220312111910_i02305.json
003_ses-01_anat_T1w_20220312111910_i02305.nii.gz
003_ses-01_anat_T1w_20220312111910_i02337.json
003_ses-01_anat_T1w_20220312111910_i02337.nii.gz
003_ses-01_anat_T1w_20220312111910_i02369.json
003_ses-01_anat_T1w_20220312111910_i02369.nii.gz
003_ses-01_anat_T1w_20220312111910_i02401.json
003_ses-01_anat_T1w_20220312111910_i02401.nii.gz
003_ses-01_anat_T1w_20220312111910_i02433.json
003_ses-01_anat_T1w_20220312111910_i02433.nii.gz
003_ses-01_anat_T1w_20220312111910_i02465.json
003_ses-01_anat_T1w_20220312111910_i02465.nii.gz
003_ses-01_anat_T1w_20220312111910_i02497.json
003_ses-01_anat_T1w_20220312111910_i02497.nii.gz
003_ses-01_anat_T1w_20220312111910_i02529.json
003_ses-01_anat_T1w_20220312111910_i02529.nii.gz
003_ses-01_anat_T1w_20220312111910_i02561.json
003_ses-01_anat_T1w_20220312111910_i02561.nii.gz
003_ses-01_anat_T1w_20220312111910_i02593.json
003_ses-01_anat_T1w_20220312111910_i02593.nii.gz
003_ses-01_anat_T1w_20220312111910_i02625.json
003_ses-01_anat_T1w_20220312111910_i02625.nii.gz
003_ses-01_anat_T1w_20220312111910_i02657.json
003_ses-01_anat_T1w_20220312111910_i02657.nii.gz
003_ses-01_anat_T1w_20220312111910_i02689.json
003_ses-01_anat_T1w_20220312111910_i02689.nii.gz
003_ses-01_anat_T1w_20220312111910_i02721.json
003_ses-01_anat_T1w_20220312111910_i02721.nii.gz
003_ses-01_anat_T1w_20220312111910_i02753.json
003_ses-01_anat_T1w_20220312111910_i02753.nii.gz
003_ses-01_anat_T1w_20220312111910_i02785.json
003_ses-01_anat_T1w_20220312111910_i02785.nii.gz
003_ses-01_anat_T1w_20220312111910_i02817.json
003_ses-01_anat_T1w_20220312111910_i02817.nii.gz
003_ses-01_anat_T1w_20220312111910_i02849.json
003_ses-01_anat_T1w_20220312111910_i02849.nii.gz
003_ses-01_anat_T1w_20220312111910_i02881.json
003_ses-01_anat_T1w_20220312111910_i02881.nii.gz
003_ses-01_anat_T1w_20220312111910_i02913.json
003_ses-01_anat_T1w_20220312111910_i02913.nii.gz
003_ses-01_anat_T1w_20220312111910_i02945.json
003_ses-01_anat_T1w_20220312111910_i02945.nii.gz
003_ses-01_anat_T1w_20220312111910_i02977.json
003_ses-01_anat_T1w_20220312111910_i02977.nii.gz
003_ses-01_anat_T1w_20220312111910_i03009.json
003_ses-01_anat_T1w_20220312111910_i03009.nii.gz
003_ses-01_anat_T1w_20220312111910_i03041.json
003_ses-01_anat_T1w_20220312111910_i03041.nii.gz
003_ses-01_anat_T1w_20220312111910_i03073.json
003_ses-01_anat_T1w_20220312111910_i03073.nii.gz
003_ses-01_anat_T1w_20220312111910_i03105.json
003_ses-01_anat_T1w_20220312111910_i03105.nii.gz
003_ses-01_anat_T1w_20220312111910_i03137.json
003_ses-01_anat_T1w_20220312111910_i03137.nii.gz
003_ses-01_anat_T1w_20220312111910_i03169.json
003_ses-01_anat_T1w_20220312111910_i03169.nii.gz
003_ses-01_anat_T1w_20220312111910_i03201.json
003_ses-01_anat_T1w_20220312111910_i03201.nii.gz
003_ses-01_anat_T1w_20220312111910_i03233.json
003_ses-01_anat_T1w_20220312111910_i03233.nii.gz
003_ses-01_anat_T1w_20220312111910_i03265.json
003_ses-01_anat_T1w_20220312111910_i03265.nii.gz
003_ses-01_anat_T1w_20220312111910_i03297.json
003_ses-01_anat_T1w_20220312111910_i03297.nii.gz
003_ses-01_anat_T1w_20220312111910_i03329.json
003_ses-01_anat_T1w_20220312111910_i03329.nii.gz
003_ses-01_anat_T1w_20220312111910_i03361.json
003_ses-01_anat_T1w_20220312111910_i03361.nii.gz
003_ses-01_anat_T1w_20220312111910_i03393.json
003_ses-01_anat_T1w_20220312111910_i03393.nii.gz
003_ses-01_anat_T1w_20220312111910_i03425.json
003_ses-01_anat_T1w_20220312111910_i03425.nii.gz
003_ses-01_anat_T1w_20220312111910_i03457.json
003_ses-01_anat_T1w_20220312111910_i03457.nii.gz
003_ses-01_anat_T1w_20220312111910_i03489.json
003_ses-01_anat_T1w_20220312111910_i03489.nii.gz
003_ses-01_anat_T1w_20220312111910_i03521.json
003_ses-01_anat_T1w_20220312111910_i03521.nii.gz
003_ses-01_anat_T1w_20220312111910_i03553.json
003_ses-01_anat_T1w_20220312111910_i03553.nii.gz
003_ses-01_anat_T1w_20220312111910_i03585.json
003_ses-01_anat_T1w_20220312111910_i03585.nii.gz
003_ses-01_anat_T1w_20220312111910_i03617.json
003_ses-01_anat_T1w_20220312111910_i03617.nii.gz
003_ses-01_anat_T1w_20220312111910_i03649.json
003_ses-01_anat_T1w_20220312111910_i03649.nii.gz
003_ses-01_anat_T1w_20220312111910_i03681.json
003_ses-01_anat_T1w_20220312111910_i03681.nii.gz
003_ses-01_anat_T1w_20220312111910_i03713.json
003_ses-01_anat_T1w_20220312111910_i03713.nii.gz
003_ses-01_anat_T1w_20220312111910_i03745.json
003_ses-01_anat_T1w_20220312111910_i03745.nii.gz
003_ses-01_anat_T1w_20220312111910_i03777.json
003_ses-01_anat_T1w_20220312111910_i03777.nii.gz
003_ses-01_anat_T1w_20220312111910_i03809.json
003_ses-01_anat_T1w_20220312111910_i03809.nii.gz
003_ses-01_anat_T1w_20220312111910_i03841.json
003_ses-01_anat_T1w_20220312111910_i03841.nii.gz
003_ses-01_anat_T1w_20220312111910_i03873.json
003_ses-01_anat_T1w_20220312111910_i03873.nii.gz
003_ses-01_anat_T1w_20220312111910_i03905.json
003_ses-01_anat_T1w_20220312111910_i03905.nii.gz
003_ses-01_anat_T1w_20220312111910_i03937.json
003_ses-01_anat_T1w_20220312111910_i03937.nii.gz
003_ses-01_anat_T1w_20220312111910_i03969.json
003_ses-01_anat_T1w_20220312111910_i03969.nii.gz
003_ses-01_anat_T1w_20220312111910_i04001.json
003_ses-01_anat_T1w_20220312111910_i04001.nii.gz
003_ses-01_anat_T1w_20220312111910_i04033.json
003_ses-01_anat_T1w_20220312111910_i04033.nii.gz
003_ses-01_anat_T1w_20220312111910_i04065.json
003_ses-01_anat_T1w_20220312111910_i04065.nii.gz
003_ses-01_anat_T1w_20220312111910_i04097.json
003_ses-01_anat_T1w_20220312111910_i04097.nii.gz
003_ses-01_anat_T1w_20220312111910_i04129.json
003_ses-01_anat_T1w_20220312111910_i04129.nii.gz
003_ses-01_anat_T1w_20220312111910_i04161.json
003_ses-01_anat_T1w_20220312111910_i04161.nii.gz
003_ses-01_anat_T1w_20220312111910_i04193.json
003_ses-01_anat_T1w_20220312111910_i04193.nii.gz
003_ses-01_anat_T1w_20220312111910_i04225.json
003_ses-01_anat_T1w_20220312111910_i04225.nii.gz
003_ses-01_anat_T1w_20220312111910_i04257.json
003_ses-01_anat_T1w_20220312111910_i04257.nii.gz
003_ses-01_anat_T1w_20220312111910_i04289.json
003_ses-01_anat_T1w_20220312111910_i04289.nii.gz
003_ses-01_anat_T1w_20220312111910_i04321.json
003_ses-01_anat_T1w_20220312111910_i04321.nii.gz
003_ses-01_anat_T1w_20220312111910_i04353.json
003_ses-01_anat_T1w_20220312111910_i04353.nii.gz
003_ses-01_anat_T1w_20220312111910_i04385.json
003_ses-01_anat_T1w_20220312111910_i04385.nii.gz
003_ses-01_anat_T1w_20220312111910_i04417.json
003_ses-01_anat_T1w_20220312111910_i04417.nii.gz
003_ses-01_anat_T1w_20220312111910_i04449.json
003_ses-01_anat_T1w_20220312111910_i04449.nii.gz
003_ses-01_anat_T1w_20220312111910_i04481.json
003_ses-01_anat_T1w_20220312111910_i04481.nii.gz
003_ses-01_anat_T1w_20220312111910_i04513.json
003_ses-01_anat_T1w_20220312111910_i04513.nii.gz
003_ses-01_anat_T1w_20220312111910_i04545.json
003_ses-01_anat_T1w_20220312111910_i04545.nii.gz
003_ses-01_anat_T1w_20220312111910_i04577.json
003_ses-01_anat_T1w_20220312111910_i04577.nii.gz
004_ses-01_anat_T1w_20220312111910.json
004_ses-01_anat_T1w_20220312111910.nii.gz
005_ses-01_anat_acq-vnavsetter_T2w_20220312111910.json
005_ses-01_anat_acq-vnavsetter_T2w_20220312111910.nii.gz
006_ses-01_anat_T2w_20220312111910_i00001.json
006_ses-01_anat_T2w_20220312111910_i00001.nii.gz
006_ses-01_anat_T2w_20220312111910_i00033.json
006_ses-01_anat_T2w_20220312111910_i00033.nii.gz
006_ses-01_anat_T2w_20220312111910_i00065.json
006_ses-01_anat_T2w_20220312111910_i00065.nii.gz
006_ses-01_anat_T2w_20220312111910_i00097.json
006_ses-01_anat_T2w_20220312111910_i00097.nii.gz
006_ses-01_anat_T2w_20220312111910_i00129.json
006_ses-01_anat_T2w_20220312111910_i00129.nii.gz
006_ses-01_anat_T2w_20220312111910_i00161.json
006_ses-01_anat_T2w_20220312111910_i00161.nii.gz
006_ses-01_anat_T2w_20220312111910_i00193.json
006_ses-01_anat_T2w_20220312111910_i00193.nii.gz
006_ses-01_anat_T2w_20220312111910_i00225.json
006_ses-01_anat_T2w_20220312111910_i00225.nii.gz
006_ses-01_anat_T2w_20220312111910_i00257.json
006_ses-01_anat_T2w_20220312111910_i00257.nii.gz
006_ses-01_anat_T2w_20220312111910_i00289.json
006_ses-01_anat_T2w_20220312111910_i00289.nii.gz
006_ses-01_anat_T2w_20220312111910_i00321.json
006_ses-01_anat_T2w_20220312111910_i00321.nii.gz
006_ses-01_anat_T2w_20220312111910_i00353.json
006_ses-01_anat_T2w_20220312111910_i00353.nii.gz
006_ses-01_anat_T2w_20220312111910_i00385.json
006_ses-01_anat_T2w_20220312111910_i00385.nii.gz
006_ses-01_anat_T2w_20220312111910_i00417.json
006_ses-01_anat_T2w_20220312111910_i00417.nii.gz
006_ses-01_anat_T2w_20220312111910_i00449.json
006_ses-01_anat_T2w_20220312111910_i00449.nii.gz
006_ses-01_anat_T2w_20220312111910_i00481.json
006_ses-01_anat_T2w_20220312111910_i00481.nii.gz
006_ses-01_anat_T2w_20220312111910_i00513.json
006_ses-01_anat_T2w_20220312111910_i00513.nii.gz
006_ses-01_anat_T2w_20220312111910_i00545.json
006_ses-01_anat_T2w_20220312111910_i00545.nii.gz
006_ses-01_anat_T2w_20220312111910_i00577.json
006_ses-01_anat_T2w_20220312111910_i00577.nii.gz
006_ses-01_anat_T2w_20220312111910_i00609.json
006_ses-01_anat_T2w_20220312111910_i00609.nii.gz
006_ses-01_anat_T2w_20220312111910_i00641.json
006_ses-01_anat_T2w_20220312111910_i00641.nii.gz
006_ses-01_anat_T2w_20220312111910_i00673.json
006_ses-01_anat_T2w_20220312111910_i00673.nii.gz
006_ses-01_anat_T2w_20220312111910_i00705.json
006_ses-01_anat_T2w_20220312111910_i00705.nii.gz
006_ses-01_anat_T2w_20220312111910_i00737.json
006_ses-01_anat_T2w_20220312111910_i00737.nii.gz
006_ses-01_anat_T2w_20220312111910_i00769.json
006_ses-01_anat_T2w_20220312111910_i00769.nii.gz
006_ses-01_anat_T2w_20220312111910_i00801.json
006_ses-01_anat_T2w_20220312111910_i00801.nii.gz
006_ses-01_anat_T2w_20220312111910_i00833.json
006_ses-01_anat_T2w_20220312111910_i00833.nii.gz
006_ses-01_anat_T2w_20220312111910_i00865.json
006_ses-01_anat_T2w_20220312111910_i00865.nii.gz
006_ses-01_anat_T2w_20220312111910_i00897.json
006_ses-01_anat_T2w_20220312111910_i00897.nii.gz
006_ses-01_anat_T2w_20220312111910_i00929.json
006_ses-01_anat_T2w_20220312111910_i00929.nii.gz
006_ses-01_anat_T2w_20220312111910_i00961.json
006_ses-01_anat_T2w_20220312111910_i00961.nii.gz
006_ses-01_anat_T2w_20220312111910_i00993.json
006_ses-01_anat_T2w_20220312111910_i00993.nii.gz
006_ses-01_anat_T2w_20220312111910_i01025.json
006_ses-01_anat_T2w_20220312111910_i01025.nii.gz
006_ses-01_anat_T2w_20220312111910_i01057.json
006_ses-01_anat_T2w_20220312111910_i01057.nii.gz
006_ses-01_anat_T2w_20220312111910_i01089.json
006_ses-01_anat_T2w_20220312111910_i01089.nii.gz
006_ses-01_anat_T2w_20220312111910_i01121.json
006_ses-01_anat_T2w_20220312111910_i01121.nii.gz
006_ses-01_anat_T2w_20220312111910_i01153.json
006_ses-01_anat_T2w_20220312111910_i01153.nii.gz
006_ses-01_anat_T2w_20220312111910_i01185.json
006_ses-01_anat_T2w_20220312111910_i01185.nii.gz
006_ses-01_anat_T2w_20220312111910_i01217.json
006_ses-01_anat_T2w_20220312111910_i01217.nii.gz
006_ses-01_anat_T2w_20220312111910_i01249.json
006_ses-01_anat_T2w_20220312111910_i01249.nii.gz
006_ses-01_anat_T2w_20220312111910_i01281.json
006_ses-01_anat_T2w_20220312111910_i01281.nii.gz
006_ses-01_anat_T2w_20220312111910_i01313.json
006_ses-01_anat_T2w_20220312111910_i01313.nii.gz
006_ses-01_anat_T2w_20220312111910_i01345.json
006_ses-01_anat_T2w_20220312111910_i01345.nii.gz
006_ses-01_anat_T2w_20220312111910_i01377.json
006_ses-01_anat_T2w_20220312111910_i01377.nii.gz
006_ses-01_anat_T2w_20220312111910_i01409.json
006_ses-01_anat_T2w_20220312111910_i01409.nii.gz
006_ses-01_anat_T2w_20220312111910_i01441.json
006_ses-01_anat_T2w_20220312111910_i01441.nii.gz
006_ses-01_anat_T2w_20220312111910_i01473.json
006_ses-01_anat_T2w_20220312111910_i01473.nii.gz
006_ses-01_anat_T2w_20220312111910_i01505.json
006_ses-01_anat_T2w_20220312111910_i01505.nii.gz
006_ses-01_anat_T2w_20220312111910_i01537.json
006_ses-01_anat_T2w_20220312111910_i01537.nii.gz
006_ses-01_anat_T2w_20220312111910_i01569.json
006_ses-01_anat_T2w_20220312111910_i01569.nii.gz
006_ses-01_anat_T2w_20220312111910_i01601.json
006_ses-01_anat_T2w_20220312111910_i01601.nii.gz
006_ses-01_anat_T2w_20220312111910_i01633.json
006_ses-01_anat_T2w_20220312111910_i01633.nii.gz
006_ses-01_anat_T2w_20220312111910_i01665.json
006_ses-01_anat_T2w_20220312111910_i01665.nii.gz
006_ses-01_anat_T2w_20220312111910_i01697.json
006_ses-01_anat_T2w_20220312111910_i01697.nii.gz
006_ses-01_anat_T2w_20220312111910_i01729.json
006_ses-01_anat_T2w_20220312111910_i01729.nii.gz
006_ses-01_anat_T2w_20220312111910_i01761.json
006_ses-01_anat_T2w_20220312111910_i01761.nii.gz
006_ses-01_anat_T2w_20220312111910_i01793.json
006_ses-01_anat_T2w_20220312111910_i01793.nii.gz
006_ses-01_anat_T2w_20220312111910_i01825.json
006_ses-01_anat_T2w_20220312111910_i01825.nii.gz
006_ses-01_anat_T2w_20220312111910_i01857.json
006_ses-01_anat_T2w_20220312111910_i01857.nii.gz
006_ses-01_anat_T2w_20220312111910_i01889.json
006_ses-01_anat_T2w_20220312111910_i01889.nii.gz
006_ses-01_anat_T2w_20220312111910_i01921.json
006_ses-01_anat_T2w_20220312111910_i01921.nii.gz
006_ses-01_anat_T2w_20220312111910_i01953.json
006_ses-01_anat_T2w_20220312111910_i01953.nii.gz
006_ses-01_anat_T2w_20220312111910_i01985.json
006_ses-01_anat_T2w_20220312111910_i01985.nii.gz
006_ses-01_anat_T2w_20220312111910_i02017.json
006_ses-01_anat_T2w_20220312111910_i02017.nii.gz
006_ses-01_anat_T2w_20220312111910_i02049.json
006_ses-01_anat_T2w_20220312111910_i02049.nii.gz
006_ses-01_anat_T2w_20220312111910_i02081.json
006_ses-01_anat_T2w_20220312111910_i02081.nii.gz
006_ses-01_anat_T2w_20220312111910_i02113.json
006_ses-01_anat_T2w_20220312111910_i02113.nii.gz
006_ses-01_anat_T2w_20220312111910_i02145.json
006_ses-01_anat_T2w_20220312111910_i02145.nii.gz
006_ses-01_anat_T2w_20220312111910_i02177.json
006_ses-01_anat_T2w_20220312111910_i02177.nii.gz
006_ses-01_anat_T2w_20220312111910_i02209.json
006_ses-01_anat_T2w_20220312111910_i02209.nii.gz
006_ses-01_anat_T2w_20220312111910_i02241.json
006_ses-01_anat_T2w_20220312111910_i02241.nii.gz
006_ses-01_anat_T2w_20220312111910_i02273.json
006_ses-01_anat_T2w_20220312111910_i02273.nii.gz
006_ses-01_anat_T2w_20220312111910_i02305.json
006_ses-01_anat_T2w_20220312111910_i02305.nii.gz
006_ses-01_anat_T2w_20220312111910_i02337.json
006_ses-01_anat_T2w_20220312111910_i02337.nii.gz
006_ses-01_anat_T2w_20220312111910_i02369.json
006_ses-01_anat_T2w_20220312111910_i02369.nii.gz
006_ses-01_anat_T2w_20220312111910_i02401.json
006_ses-01_anat_T2w_20220312111910_i02401.nii.gz
006_ses-01_anat_T2w_20220312111910_i02433.json
006_ses-01_anat_T2w_20220312111910_i02433.nii.gz
006_ses-01_anat_T2w_20220312111910_i02465.json
006_ses-01_anat_T2w_20220312111910_i02465.nii.gz
006_ses-01_anat_T2w_20220312111910_i02497.json
006_ses-01_anat_T2w_20220312111910_i02497.nii.gz
006_ses-01_anat_T2w_20220312111910_i02529.json
006_ses-01_anat_T2w_20220312111910_i02529.nii.gz
006_ses-01_anat_T2w_20220312111910_i02561.json
006_ses-01_anat_T2w_20220312111910_i02561.nii.gz
006_ses-01_anat_T2w_20220312111910_i02593.json
006_ses-01_anat_T2w_20220312111910_i02593.nii.gz
006_ses-01_anat_T2w_20220312111910_i02625.json
006_ses-01_anat_T2w_20220312111910_i02625.nii.gz
006_ses-01_anat_T2w_20220312111910_i02657.json
006_ses-01_anat_T2w_20220312111910_i02657.nii.gz
006_ses-01_anat_T2w_20220312111910_i02689.json
006_ses-01_anat_T2w_20220312111910_i02689.nii.gz
006_ses-01_anat_T2w_20220312111910_i02721.json
006_ses-01_anat_T2w_20220312111910_i02721.nii.gz
006_ses-01_anat_T2w_20220312111910_i02753.json
006_ses-01_anat_T2w_20220312111910_i02753.nii.gz
006_ses-01_anat_T2w_20220312111910_i02785.json
006_ses-01_anat_T2w_20220312111910_i02785.nii.gz
006_ses-01_anat_T2w_20220312111910_i02817.json
006_ses-01_anat_T2w_20220312111910_i02817.nii.gz
006_ses-01_anat_T2w_20220312111910_i02849.json
006_ses-01_anat_T2w_20220312111910_i02849.nii.gz
006_ses-01_anat_T2w_20220312111910_i02881.json
006_ses-01_anat_T2w_20220312111910_i02881.nii.gz
006_ses-01_anat_T2w_20220312111910_i02913.json
006_ses-01_anat_T2w_20220312111910_i02913.nii.gz
006_ses-01_anat_T2w_20220312111910_i02945.json
006_ses-01_anat_T2w_20220312111910_i02945.nii.gz
006_ses-01_anat_T2w_20220312111910_i02977.json
006_ses-01_anat_T2w_20220312111910_i02977.nii.gz
006_ses-01_anat_T2w_20220312111910_i03009.json
006_ses-01_anat_T2w_20220312111910_i03009.nii.gz
006_ses-01_anat_T2w_20220312111910_i03041.json
006_ses-01_anat_T2w_20220312111910_i03041.nii.gz
006_ses-01_anat_T2w_20220312111910_i03073.json
006_ses-01_anat_T2w_20220312111910_i03073.nii.gz
006_ses-01_anat_T2w_20220312111910_i03105.json
006_ses-01_anat_T2w_20220312111910_i03105.nii.gz
006_ses-01_anat_T2w_20220312111910_i03137.json
006_ses-01_anat_T2w_20220312111910_i03137.nii.gz
006_ses-01_anat_T2w_20220312111910_i03169.json
006_ses-01_anat_T2w_20220312111910_i03169.nii.gz
006_ses-01_anat_T2w_20220312111910_i03201.json
006_ses-01_anat_T2w_20220312111910_i03201.nii.gz
006_ses-01_anat_T2w_20220312111910_i03233.json
006_ses-01_anat_T2w_20220312111910_i03233.nii.gz
006_ses-01_anat_T2w_20220312111910_i03265.json
006_ses-01_anat_T2w_20220312111910_i03265.nii.gz
006_ses-01_anat_T2w_20220312111910_i03297.json
006_ses-01_anat_T2w_20220312111910_i03297.nii.gz
006_ses-01_anat_T2w_20220312111910_i03329.json
006_ses-01_anat_T2w_20220312111910_i03329.nii.gz
006_ses-01_anat_T2w_20220312111910_i03361.json
006_ses-01_anat_T2w_20220312111910_i03361.nii.gz
006_ses-01_anat_T2w_20220312111910_i03393.json
006_ses-01_anat_T2w_20220312111910_i03393.nii.gz
007_ses-01_anat_T2w_20220312111910.json
007_ses-01_anat_T2w_20220312111910.nii.gz
008_ses-01_anat_T2w_20220312111910.json
008_ses-01_anat_T2w_20220312111910.nii.gz
009_ses-01_dwi_acq-multishell_dir-AP_dwi_20220312111910.bval
009_ses-01_dwi_acq-multishell_dir-AP_dwi_20220312111910.bvec
009_ses-01_dwi_acq-multishell_dir-AP_dwi_20220312111910.json
009_ses-01_dwi_acq-multishell_dir-AP_dwi_20220312111910.nii.gz
010_ses-01_fmap_acq-dMRIdistmap_dir-PA_epi_20220312111910.bval
010_ses-01_fmap_acq-dMRIdistmap_dir-PA_epi_20220312111910.bvec
010_ses-01_fmap_acq-dMRIdistmap_dir-PA_epi_20220312111910.json
010_ses-01_fmap_acq-dMRIdistmap_dir-PA_epi_20220312111910.nii.gz
011_ses-01_fmap_acq-dMRIdistmap_dir-AP_epi_20220312111910.bval
011_ses-01_fmap_acq-dMRIdistmap_dir-AP_epi_20220312111910.bvec
011_ses-01_fmap_acq-dMRIdistmap_dir-AP_epi_20220312111910.json
011_ses-01_fmap_acq-dMRIdistmap_dir-AP_epi_20220312111910.nii.gz
012_ses-01_func_task-rest_run-01_20220312111910.json
012_ses-01_func_task-rest_run-01_20220312111910.nii.gz
014_ses-01_func_task-fracnoback_run-02_20220312111910.json
014_ses-01_func_task-fracnoback_run-02_20220312111910.nii.gz
016_ses-01_fmap_acq-fMRIdistmap_dir-PA_epi_20220312111910.json
016_ses-01_fmap_acq-fMRIdistmap_dir-PA_epi_20220312111910.nii.gz
017_ses-01_fmap_acq-fMRIdistmap_dir-AP_epi_20220312111910.json
017_ses-01_fmap_acq-fMRIdistmap_dir-AP_epi_20220312111910.nii.gz
018_ses-01_func_task-rest_run-03_20220312111910.json
018_ses-01_func_task-rest_run-03_20220312111910.nii.gz
020_ses-01_asl_acq-3dspiralv20unbalanced_asl_20220312111910.json
020_ses-01_asl_acq-3dspiralv20unbalanced_asl_20220312111910.nii.gz
021_ses-01_asl_acq-3dspiralv20unbalanced_asl_20220312111910.json
021_ses-01_asl_acq-3dspiralv20unbalanced_asl_20220312111910.nii.gz
022_ses-01_asl_acq-3dspiralv20unbalanced_asl_20220312111910.json
022_ses-01_asl_acq-3dspiralv20unbalanced_asl_20220312111910.nii.gz
023_ses-01_qsm_acq-1.5mm_GRE_20220312111910_e1.json
023_ses-01_qsm_acq-1.5mm_GRE_20220312111910_e1.nii.gz
023_ses-01_qsm_acq-1.5mm_GRE_20220312111910_e2.json
023_ses-01_qsm_acq-1.5mm_GRE_20220312111910_e2.nii.gz
023_ses-01_qsm_acq-1.5mm_GRE_20220312111910_e3.json
023_ses-01_qsm_acq-1.5mm_GRE_20220312111910_e3.nii.gz
023_ses-01_qsm_acq-1.5mm_GRE_20220312111910_e4.json
023_ses-01_qsm_acq-1.5mm_GRE_20220312111910_e4.nii.gz
024_ses-01_qsm_acq-1.5mm_GRE_20220312111910_e1_ph.json
024_ses-01_qsm_acq-1.5mm_GRE_20220312111910_e1_ph.nii.gz
024_ses-01_qsm_acq-1.5mm_GRE_20220312111910_e2_ph.json
024_ses-01_qsm_acq-1.5mm_GRE_20220312111910_e2_ph.nii.gz
024_ses-01_qsm_acq-1.5mm_GRE_20220312111910_e3_ph.json
024_ses-01_qsm_acq-1.5mm_GRE_20220312111910_e3_ph.nii.gz
024_ses-01_qsm_acq-1.5mm_GRE_20220312111910_e4_ph.json
024_ses-01_qsm_acq-1.5mm_GRE_20220312111910_e4_ph.nii.gz
</pre>
</div>
```

When you run this on your own dicoms, hopefully the filenames are as informative as the ones in this example dataset.

### User the Helper to Define the Configuration
We know that all the files here aren't going into the BIDS folder. For example, the anatomical scout is not something we typically save out. Files that are accepted into BIDS may be found [here.](https://bids-specification.readthedocs.io/en/stable/modality-specific-files/magnetic-resonance-imaging-data.html)

For the sake of this exercise, we will only be converting:
1. Anatomicals (T1w + T2w)
2. Functional MRI (BOLD)
3. Diffusion MRI (DWI)
4. Fieldmaps

However, other types of files in the dataset, such as arterial spin labeling (ASL) are BIDS valid, and filetypes are constantly being proposed and added to BIDS.

Documentation of how to make a `dcm2bids` configuration file are [here.](https://unfmontreal.github.io/Dcm2Bids/latest/how-to/create-config-file/#configuration-file-example).

Let's start with the T1w image. For those, we tend to use the primary image, which may or may not normalized off the scanner. That is typically the last and largest file derived from the T1w image, in this case `004_ses-01_anat_T1w_20220312111910.nii.gz/.json`. Looking at `004_ses-01_anat_T1w_20220312111910.json` we see several fields:
```{raw} html
<div style="overflow-y: auto; max-height: 200px;">
<pre>
{
	"Modality": "MR",
	"MagneticFieldStrength": 3,
	"ImagingFrequency": 123.192397,
	"Manufacturer": "Siemens",
	"ManufacturersModelName": "Prisma_fit",
	"InstitutionName": "HUP",
	"InstitutionAddress": "Spruce Street 3400,Philadelphia,Pennsylvania,US,19104",
	"DeviceSerialNumber": "167024",
	"StationName": "HUP FNDBA MR2",
	"BodyPart": "BRAIN",
	"PatientPosition": "HFS",
	"ProcedureStepDescription": "MR HEAD WO IV CONTRAST",
	"SoftwareVersions": "syngo MR E11",
	"MRAcquisitionType": "3D",
	"StudyDescription": "BRAIN RESEARCH^SATTERTHWAITE",
	"SeriesDescription": "anat_T1w",
	"ProtocolName": "anat_T1w",
	"ScanningSequence": "GR\\IR",
	"SequenceVariant": "SK\\SP\\MP",
	"ScanOptions": "IR\\WE",
	"SequenceName": "tfl3d1_16ns",
	"ImageType": ["ORIGINAL", "PRIMARY", "M", "ND", "NORM", "MAGNITUDE"],
	"NonlinearGradientCorrection": false,
	"DeidentificationMethod": ["Penn_BSC_profile_v3.0"],
	"SeriesNumber": 4,
	"AcquisitionNumber": 1,
	"ImageComments": "22473_12097@BBL:EFR01",
	"SliceThickness": 1,
	"SAR": 0.0426183,
	"TablePosition": [
		0,
		0,
		-0	],
	"EchoTime": 0.0029,
	"RepetitionTime": 2.5,
	"SpoilingState": true,
	"InversionTime": 1.07,
	"FlipAngle": 8,
	"PartialFourier": 1,
	"BaseResolution": 256,
	"ShimSetting": [
		1860,
		-3906,
		-217,
		412,
		66,
		-212,
		110,
		-160	],
	"TxRefAmp": 250.994,
	"PhaseResolution": 1,
	"ReceiveCoilName": "Head_32",
	"ReceiveCoilActiveElements": "HEA;HEP",
	"PulseSequenceDetails": "%CustomerSeq%\\tfl_mgh_epinav_ABCD",
	"WipMemBlock": "Prisma_epi_moco_navigator_ABCD_tfl.prot",
	"RefLinesPE": 32,
	"CoilCombinationMethod": "Adaptive Combine",
	"ConsistencyInfo": "N4_VE11C_LATEST_20160120",
	"MatrixCoilMode": "GRAPPA",
	"PercentPhaseFOV": 100,
	"PercentSampling": 100,
	"PhaseEncodingSteps": 255,
	"AcquisitionMatrixPE": 256,
	"ReconMatrixPE": 256,
	"ParallelReductionFactorInPlane": 2,
	"PixelBandwidth": 240,
	"ImageOrientationPatientDICOM": [
		0,
		1,
		0,
		0,
		0,
		-1	],
	"InPlanePhaseEncodingDirectionDICOM": "ROW",
	"BidsGuess": ["anat","_acq-tfl3_run-4_T1w"],
	"ConversionSoftware": "dcm2niix",
	"ConversionSoftwareVersion": "v1.0.20241211"
}
</pre>
</div>
```

The goal here is to find a minimal set of json fields that uniquely identify the image. For most cases **`SeriesDescription`** is a good place to start (and in many cases is enough)! But for the anatomical images, we also need something like the image type to not capture all of the non-primary images (e.g., `003_ses-01_anat_T1w_20220312111910_i0*.nii.gz/.json`).

```{warning}
I do ***NOT** recommend using `SeriesNumber` (which is the order a scan was acquired in) as a criterion, as if you skip or repeat a certain sequence during acquisition it will throw all subsequent scans out of compliance with the rest of your subjects.
```

Following the documentation for how to make a configuration item, we can now define the T1w image like so:

```json
{
    "datatype": "anat",
    "suffix": "T1w",
    "criteria": {
        "SeriesDescription": "anat_T1w",
        "ImageType": ["ORIGINAL", "PRIMARY", "M", "ND", "NORM", "MAGNITUDE"]
    }
}
```
You can see that it will be placed in the `anat` folder (by defining `datatype`), with the suffix `T1w`, and the image is correctly identified as the only one with the `"SeriesDescription":"anat_T1w"` and `"ImageType"; ["ORIGINAL", "PRIMARY", "M", "ND", "NORM", "MAGNITUDE"]` fields in the jsons across all the images.

For non-anatomicals, we will only need the `SeriesDescription` (for this dataset `ProtocolName` is defined the same), so for the sake of non-redundancy I won't run through all the JSONS.

I will now show you the resulting final configuration file after completing this process for all the images. Note this may also be found in the GitHub repo [here (PUTLINKHERELATER)](PUTLINKHERELATER), and locally at `$SHARED_DATA_DIR/ef_example/code/dcm2bids_config.json`

```json
{
    "descriptions": [
        {
            "datatype": "anat",
            "suffix": "T1w",
            "criteria": {
                "SeriesDescription": "anat_T1w",
                "ImageType": ["ORIGINAL", "PRIMARY", "M", "ND", "NORM", "MAGNITUDE"]
            }
        },
        {
            "datatype": "anat",
            "suffix": "T2w",
            "criteria": {
                "SeriesDescription": "anat_T2w",
                "ImageType": ["ORIGINAL", "PRIMARY", "M", "ND", "NORM", "MAGNITUDE"]
            }
        },
        {
            "id": "dwi",
            "datatype": "dwi",
            "suffix": "dwi",
            "custom_entities": "dir-AP",
            "criteria": {
                "SeriesDescription": "dwi_acq-multishell_dir-AP_dwi"
            },
            "sidecar_changes": {
                "IntendedFor": "dwi",
                "B0FieldSource": "dwi_fmap"
            }
        },
        {
            "id": "dwi-fmap-PA",
            "datatype": "fmap",
            "suffix": "epi",
            "custom_entities": "acq-dwi_dir-PA",
            "criteria": {
                "SeriesDescription": "fmap_acq-dMRIdistmap_dir-PA_epi"
            },
            "sidecar_changes": {
                "IntendedFor": "dwi",
                "B0FieldIdentifier": "dwi_fmap"
            }
        },
        {
            "id": "dwi-fmap-AP",
            "datatype": "fmap",
            "suffix": "epi",
            "custom_entities": "acq-dwi_dir-AP",
            "criteria": {
                "SeriesDescription": "fmap_acq-dMRIdistmap_dir-AP_epi"
            },
            "sidecar_changes": {
                "IntendedFor": "dwi",
                "B0FieldIdentifier": "dwi_fmap"
            }
        },
        {
            "id": "func-rest",
            "datatype": "func",
            "suffix": "bold",
            "custom_entities": "task-rest",
            "criteria": {
                "SeriesDescription": "func_task-rest*"
            },
            "sidecar_changes": {
                "TaskName": "rest",
                "B0FieldSource": "fmri_fmap"
            }
        },
        {
            "id": "func-task",
            "datatype": "func",
            "suffix": "bold",
            "custom_entities": "task-fracnoback",
            "criteria": {
                "SeriesDescription": "func_task-fracnoback*"
            },
            "sidecar_changes": {
                "TaskName": "Fractional 0-Back",
                "B0FieldSource": "fmri_fmap"
            }
        },
        {
            "id": "fmri-fmap-PA",
            "datatype": "fmap",
            "suffix": "epi",
            "custom_entities": "acq-fmri_dir-PA",
            "criteria": {
                "SeriesDescription": "fmap_acq-fMRIdistmap_dir-PA_epi"
            },
            "sidecar_changes": {
                "IntendedFor": ["func-rest","func-task"],
                "B0FieldIdentifier": "fmri_fmap"
            }
        },
        {
            "id": "fmri-fmap-AP",
            "datatype": "fmap",
            "suffix": "epi",
            "custom_entities": "acq-fmri_dir-AP",
            "criteria": {
                "SeriesDescription": "fmap_acq-fMRIdistmap_dir-AP_epi"
            },
            "sidecar_changes": {
                "IntendedFor": ["func-rest","func-task"],
                "B0FieldIdentifier": "fmri_fmap"
            }
        }
    ],
    "bids_uri": "relative",
    "post_op": [
        {
            "cmd": "pydeface --outfile dst_file src_file",
            "datatype": "anat",
            "suffix": [
                "T1w",
                "T2w"
            ],
            "custom_entities": "rec-defaced"
        }
    ]
}
```
Now we can discuss some of the other configuration element items. You can see that in many of them I added `custom_entities` such as the `acq-<>` and `dir-<>` labels. These, while not always required, are helpful to readers to know what kind of data they are dealing with. For example, the fieldmaps having the labels `acq-dwi` tells the reader the fieldmap is intended to correct the DWI files. For this file, the `dir-<>` label is required, because the phase encoding direction is necessary information to correct for distortions using this style of fieldmap. More valid custom entitites can be found in the [BIDS specification.](https://bids-specification.readthedocs.io/en/stable/modality-specific-files/magnetic-resonance-imaging-data.html).

The `TaskName` being added to the BOLD jsons is required for BIDS datasets.

You can see at the end, in the `post_op` section, that we are going to be defacing the anatomical files, and adding a `rec-defaced` label to them. When you work with your own data, you may choose to delete the original non-defaced files when done, or you can filter them out when running BIDS apps.

### Set up Fieldmap Pairings
We use two different methods here for assigning fieldmaps for correction:
1. Relative path (legacy) `IntendedFor`.
- - In this method, the fieldmaps have a json field called `IntendedFor`, in which each elements is the path to EPI file (e.g., DWI or BOLD file) that it is intended to correct, **relative** to the subject folder (so beginning with the session-level, or modality-level folder if no session level is present).
```{note}
While this is not the official BIDS recommended way anymore, in favor of the BIDS URI which has the full (not relative) path, many BIDS apps still accept the legacy / relative path version and some are not set up for the BIDS URI yet. This includes QSIPrep (at least as of this time / version 1.0.0)!
```
2. `B0FieldIdentifier`/`B0FieldSource` pairings.
- - In this method, you give a fieldmap a name with the `B0FieldIdentifier` field in the fieldmap json. It can be anything, but you will want to make it intuitive such as `fmap_dwi`. Then in the EPI file you want to correct, e.g., the DWI json in this case, you would add `"B0FieldSource":"fmap_dwi"`.
```{note}
It is fine to have **both** of these pairing methods defined. fMRIPrep will always use the `B0*` naming fields over `IntendedFor` however.
```

In the `dcm2bids`, we give the EPI files an `id`, like `"func-rest"`, and `"func-task"`. Then in the `fmap` configuration items, we add (in the case of the fieldmaps for fMRI):
```json
"sidecar_changes": {
                "IntendedFor": ["func-rest","func-task"]
}
```
When `dcm2bids` parses that, it will add the `IntendedFor` to the fieldmap jsons going to those ID'd files (the two BOLD files). Also note that we add `"bids_uri": "relative",` to the configuration so it writes out the relative path version (by default it will use the full BIDS URI).

To add the `B0*` fields to the jsons, we just specify additional `"sidecar_changes"`. Note that this doesn't use the `id` field, that is special for `IntendedFor` in the `dcm2bids` software.

## Run `dcm2bids`

Now that we have our configuration file ready to go, we can convert the files to BIDS!

I have prepared the following example code for you to run the software which can be found in the GitHub repo [here(PUTLINKINLATE)](PUTLINKINLATER) and found locally at `${SHARED_DATA_DIR}/ef_example/code/run_dcm2bids.sh`. Note you will be prompted for subject and session IDs, but you can leave that blank to process all subjects and/or all sessions. For this example it is just one subject and two sessions.

You can run this with `bash ${SHARED_DATA_DIR}/ef_example/code/run_dcm2bids.sh`.

```{note}
For this case, `BIDS` must be defined as an environment variable (e.g., with `export BIDS=.......`). Also, `dcm2bids` does take a decently long time, and I encourgae you to adapt this to be parallelized over your computing cluster. AI tools like ChatGPT tend to make easy work of this. It is how I made the script below, in fact!
```

```bash
#!/bin/bash

# Ensure that BIDS is set.
if [ -z "$BIDS" ]; then
  echo "Error: BIDS environment variable is not set."
  exit 1
fi

# Define the DICOM root directory relative to BIDS.
DICOM_ROOT="$BIDS/sourcedata/dicoms"

# Prompt for subject ID (expects folder names like sub-01).
read -p "Enter subject ID (e.g., sub-01) or leave blank to process all subjects: " subject_input

# If no subject provided, get all subject directories under DICOM_ROOT.
if [ -z "$subject_input" ]; then
  subjects=($(find "$DICOM_ROOT" -maxdepth 1 -mindepth 1 -type d -printf "%f\n"))
else
  subjects=("$subject_input")
fi

# Prompt for session ID once (expects folder names like ses-01).
read -p "Enter session ID (e.g., ses-01) or leave blank to process all sessions: " session_input

# Loop over each subject.
for subject in "${subjects[@]}"; do
  # Remove the 'sub-' prefix for dcm2bids -p argument.
  subject_clean="${subject#sub-}"
  subject_path="$DICOM_ROOT/$subject"

  if [ ! -d "$subject_path" ]; then
    echo "Warning: $subject_path is not a directory. Skipping."
    continue
  fi

  # Determine sessions:
  # - If a session was specified, use it.
  # - Otherwise, process all session directories within the subject.
  if [ -z "$session_input" ]; then
    sessions=($(find "$subject_path" -maxdepth 1 -mindepth 1 -type d -printf "%f\n"))
  else
    sessions=("$session_input")
  fi

  # Loop over each session.
  for session in "${sessions[@]}"; do
    # Remove the 'ses-' prefix for dcm2bids -s argument.
    session_clean="${session#ses-}"
    session_path="$subject_path/$session"

    if [ ! -d "$session_path" ]; then
      echo "Warning: $session_path is not a directory. Skipping."
      continue
    fi

    # Build the dcm2bids command.
    cmd=(dcm2bids \
         -d "$session_path" \
         -p "$subject_clean" \
         -s "$session_clean" \
         -c "$BIDS/code/dcm2bids_config.json" \
         --force_dcm2bids \
         --clobber)

    # Display and execute the command.
    echo "Running command: ${cmd[*]}"
    "${cmd[@]}"
    echo "-----------------------------------"
  done
done
```

## Checking BIDS Validation
Now you should see the `sub-22473` folder with the following files, if all ran successfully! Revealed with `tree $BIDS/sub-22473`:
```bash
sub-22473/
├── ses-01
│   ├── anat
│   │   ├── sub-22473_ses-01_rec-defaced_T1w.json
│   │   ├── sub-22473_ses-01_rec-defaced_T1w.nii.gz
│   │   ├── sub-22473_ses-01_rec-defaced_T2w.json
│   │   ├── sub-22473_ses-01_rec-defaced_T2w.nii.gz
│   │   ├── sub-22473_ses-01_T1w.json
│   │   ├── sub-22473_ses-01_T1w.nii.gz
│   │   ├── sub-22473_ses-01_T2w.json
│   │   └── sub-22473_ses-01_T2w.nii.gz
│   ├── dwi
│   │   ├── sub-22473_ses-01_dir-AP_dwi.bval
│   │   ├── sub-22473_ses-01_dir-AP_dwi.bvec
│   │   ├── sub-22473_ses-01_dir-AP_dwi.json
│   │   └── sub-22473_ses-01_dir-AP_dwi.nii.gz
│   ├── fmap
│   │   ├── sub-22473_ses-01_acq-dwi_dir-AP_epi.bval
│   │   ├── sub-22473_ses-01_acq-dwi_dir-AP_epi.bvec
│   │   ├── sub-22473_ses-01_acq-dwi_dir-AP_epi.json
│   │   ├── sub-22473_ses-01_acq-dwi_dir-AP_epi.nii.gz
│   │   ├── sub-22473_ses-01_acq-dwi_dir-PA_epi.bval
│   │   ├── sub-22473_ses-01_acq-dwi_dir-PA_epi.bvec
│   │   ├── sub-22473_ses-01_acq-dwi_dir-PA_epi.json
│   │   ├── sub-22473_ses-01_acq-dwi_dir-PA_epi.nii.gz
│   │   ├── sub-22473_ses-01_acq-fmri_dir-AP_epi.json
│   │   ├── sub-22473_ses-01_acq-fmri_dir-AP_epi.nii.gz
│   │   ├── sub-22473_ses-01_acq-fmri_dir-PA_epi.json
│   │   └── sub-22473_ses-01_acq-fmri_dir-PA_epi.nii.gz
│   └── func
│       ├── sub-22473_ses-01_task-fracnoback_bold.json
│       ├── sub-22473_ses-01_task-fracnoback_bold.nii.gz
│       ├── sub-22473_ses-01_task-rest_run-01_bold.json
│       ├── sub-22473_ses-01_task-rest_run-01_bold.nii.gz
│       ├── sub-22473_ses-01_task-rest_run-02_bold.json
│       └── sub-22473_ses-01_task-rest_run-02_bold.nii.gz
└── ses-02
    ├── anat
    │   ├── sub-22473_ses-02_rec-defaced_T1w.json
    │   ├── sub-22473_ses-02_rec-defaced_T1w.nii.gz
    │   ├── sub-22473_ses-02_rec-defaced_T2w.json
    │   ├── sub-22473_ses-02_rec-defaced_T2w.nii.gz
    │   ├── sub-22473_ses-02_T1w.json
    │   ├── sub-22473_ses-02_T1w.nii.gz
    │   ├── sub-22473_ses-02_T2w.json
    │   └── sub-22473_ses-02_T2w.nii.gz
    ├── dwi
    │   ├── sub-22473_ses-02_dir-AP_dwi.bval
    │   ├── sub-22473_ses-02_dir-AP_dwi.bvec
    │   ├── sub-22473_ses-02_dir-AP_dwi.json
    │   └── sub-22473_ses-02_dir-AP_dwi.nii.gz
    ├── fmap
    │   ├── sub-22473_ses-02_acq-dwi_dir-AP_epi.bval
    │   ├── sub-22473_ses-02_acq-dwi_dir-AP_epi.bvec
    │   ├── sub-22473_ses-02_acq-dwi_dir-AP_epi.json
    │   ├── sub-22473_ses-02_acq-dwi_dir-AP_epi.nii.gz
    │   ├── sub-22473_ses-02_acq-dwi_dir-PA_epi.bval
    │   ├── sub-22473_ses-02_acq-dwi_dir-PA_epi.bvec
    │   ├── sub-22473_ses-02_acq-dwi_dir-PA_epi.json
    │   ├── sub-22473_ses-02_acq-dwi_dir-PA_epi.nii.gz
    │   ├── sub-22473_ses-02_acq-fmri_dir-AP_epi.json
    │   ├── sub-22473_ses-02_acq-fmri_dir-AP_epi.nii.gz
    │   ├── sub-22473_ses-02_acq-fmri_dir-PA_epi.json
    │   └── sub-22473_ses-02_acq-fmri_dir-PA_epi.nii.gz
    └── func
        ├── sub-22473_ses-02_task-fracnoback_bold.json
        ├── sub-22473_ses-02_task-fracnoback_bold.nii.gz
        ├── sub-22473_ses-02_task-rest_run-01_bold.json
        ├── sub-22473_ses-02_task-rest_run-01_bold.nii.gz
        ├── sub-22473_ses-02_task-rest_run-02_bold.json
        └── sub-22473_ses-02_task-rest_run-02_bold.nii.gz
```
We can now check the BIDS validation status by running the BIDS validator with `deno run -ERWN jsr:@bids/validator $BIDS`, resulting in the following report:

```{raw} html
<div style="overflow-y: auto; max-height: 200px;">
<pre>
	[WARNING] UNKNOWN_BIDS_VERSION The BIDSVersion field of 'dataset_description.json' does not match a known release.
The BIDS Schema used for validation may be out of date.

		/dataset_description.json

	Please visit https://neurostars.org/search?q=UNKNOWN_BIDS_VERSION for existing conversations about this issue.

	[WARNING] TOO_FEW_AUTHORS The 'Authors' field of 'dataset_description.json' should contain an array of values -
with one author per value.
This was triggered based on the presence of only one author field.
Please ignore if all contributors are already properly listed.

		/dataset_description.json

	Please visit https://neurostars.org/search?q=TOO_FEW_AUTHORS for existing conversations about this issue.

	[WARNING] EMPTY_DATASET_NAME The Name field of dataset_description.json is present but empty of visible characters.

		/dataset_description.json

	Please visit https://neurostars.org/search?q=EMPTY_DATASET_NAME for existing conversations about this issue.

	[WARNING] JSON_KEY_RECOMMENDED A JSON file is missing a key listed as recommended.
		DatasetType
		/dataset_description.json

		GeneratedBy
		/dataset_description.json

		SourceDatasets
		/dataset_description.json

	Please visit https://neurostars.org/search?q=JSON_KEY_RECOMMENDED for existing conversations about this issue.

	[WARNING] README_FILE_SMALL The recommended file '/README' is very small.
Please consider expanding it with additional information about the dataset.

		/README

	Please visit https://neurostars.org/search?q=README_FILE_SMALL for existing conversations about this issue.

	[WARNING] SIDECAR_KEY_RECOMMENDED A data file's JSON sidecar is missing a key listed as recommended.
		GradientSetType
		/sub-22473/ses-02/dwi/sub-22473_ses-02_dir-AP_dwi.nii.gz
		/sub-22473/ses-02/fmap/sub-22473_ses-02_acq-dwi_dir-PA_epi.nii.gz

		22 more files with the same issue

		MRTransmitCoilSequence
		/sub-22473/ses-02/dwi/sub-22473_ses-02_dir-AP_dwi.nii.gz
		/sub-22473/ses-02/fmap/sub-22473_ses-02_acq-dwi_dir-PA_epi.nii.gz

		22 more files with the same issue

		MatrixCoilMode
		/sub-22473/ses-02/dwi/sub-22473_ses-02_dir-AP_dwi.nii.gz
		/sub-22473/ses-02/func/sub-22473_ses-02_task-rest_run-01_bold.nii.gz

		6 more files with the same issue

		PulseSequenceType
		/sub-22473/ses-02/dwi/sub-22473_ses-02_dir-AP_dwi.nii.gz
		/sub-22473/ses-02/fmap/sub-22473_ses-02_acq-dwi_dir-PA_epi.nii.gz

		22 more files with the same issue

		MTState
		/sub-22473/ses-02/dwi/sub-22473_ses-02_dir-AP_dwi.nii.gz
		/sub-22473/ses-02/fmap/sub-22473_ses-02_acq-dwi_dir-PA_epi.nii.gz

		22 more files with the same issue

		SpoilingType
		/sub-22473/ses-02/dwi/sub-22473_ses-02_dir-AP_dwi.nii.gz
		/sub-22473/ses-02/dwi/sub-22473_ses-02_dir-AP_dwi.bvec

		28 more files with the same issue

		NumberShots
		/sub-22473/ses-02/dwi/sub-22473_ses-02_dir-AP_dwi.nii.gz
		/sub-22473/ses-02/fmap/sub-22473_ses-02_acq-dwi_dir-PA_epi.nii.gz

		22 more files with the same issue

		ParallelReductionFactorInPlane
		/sub-22473/ses-02/dwi/sub-22473_ses-02_dir-AP_dwi.nii.gz
		/sub-22473/ses-02/fmap/sub-22473_ses-02_acq-dwi_dir-PA_epi.nii.gz

		14 more files with the same issue

		ParallelReductionFactorOutOfPlane
		/sub-22473/ses-02/dwi/sub-22473_ses-02_dir-AP_dwi.nii.gz
		/sub-22473/ses-02/fmap/sub-22473_ses-02_acq-dwi_dir-PA_epi.nii.gz

		22 more files with the same issue

		ParallelAcquisitionTechnique
		/sub-22473/ses-02/dwi/sub-22473_ses-02_dir-AP_dwi.nii.gz
		/sub-22473/ses-02/fmap/sub-22473_ses-02_acq-dwi_dir-PA_epi.nii.gz

		22 more files with the same issue

		PartialFourierDirection
		/sub-22473/ses-02/dwi/sub-22473_ses-02_dir-AP_dwi.nii.gz
		/sub-22473/ses-02/fmap/sub-22473_ses-02_acq-dwi_dir-PA_epi.nii.gz

		22 more files with the same issue

		MixingTime
		/sub-22473/ses-02/dwi/sub-22473_ses-02_dir-AP_dwi.nii.gz
		/sub-22473/ses-02/fmap/sub-22473_ses-02_acq-dwi_dir-PA_epi.nii.gz

		22 more files with the same issue

		InversionTime
		/sub-22473/ses-02/dwi/sub-22473_ses-02_dir-AP_dwi.nii.gz
		/sub-22473/ses-02/fmap/sub-22473_ses-02_acq-dwi_dir-PA_epi.nii.gz

		18 more files with the same issue

		DwellTime
		/sub-22473/ses-02/dwi/sub-22473_ses-02_dir-AP_dwi.nii.gz
		/sub-22473/ses-02/fmap/sub-22473_ses-02_acq-dwi_dir-PA_epi.nii.gz

		22 more files with the same issue

		SliceEncodingDirection
		/sub-22473/ses-02/dwi/sub-22473_ses-02_dir-AP_dwi.nii.gz
		/sub-22473/ses-02/fmap/sub-22473_ses-02_acq-dwi_dir-PA_epi.nii.gz

		14 more files with the same issue

		InstitutionalDepartmentName
		/sub-22473/ses-02/dwi/sub-22473_ses-02_dir-AP_dwi.nii.gz
		/sub-22473/ses-02/fmap/sub-22473_ses-02_acq-dwi_dir-PA_epi.nii.gz

		22 more files with the same issue

		SliceTiming
		/sub-22473/ses-02/fmap/sub-22473_ses-02_acq-dwi_dir-PA_epi.nii.gz
		/sub-22473/ses-02/fmap/sub-22473_ses-02_acq-dwi_dir-AP_epi.nii.gz

		6 more files with the same issue

		NumberOfVolumesDiscardedByScanner
		/sub-22473/ses-02/func/sub-22473_ses-02_task-rest_run-01_bold.nii.gz
		/sub-22473/ses-02/func/sub-22473_ses-02_task-fracnoback_bold.nii.gz

		4 more files with the same issue

		NumberOfVolumesDiscardedByUser
		/sub-22473/ses-02/func/sub-22473_ses-02_task-rest_run-01_bold.nii.gz
		/sub-22473/ses-02/func/sub-22473_ses-02_task-fracnoback_bold.nii.gz

		4 more files with the same issue

		DelayTime
		/sub-22473/ses-02/func/sub-22473_ses-02_task-rest_run-01_bold.nii.gz
		/sub-22473/ses-02/func/sub-22473_ses-02_task-fracnoback_bold.nii.gz

		4 more files with the same issue

		AcquisitionDuration
		/sub-22473/ses-02/func/sub-22473_ses-02_task-rest_run-01_bold.nii.gz
		/sub-22473/ses-02/func/sub-22473_ses-02_task-fracnoback_bold.nii.gz

		4 more files with the same issue

		DelayAfterTrigger
		/sub-22473/ses-02/func/sub-22473_ses-02_task-rest_run-01_bold.nii.gz
		/sub-22473/ses-02/func/sub-22473_ses-02_task-fracnoback_bold.nii.gz

		4 more files with the same issue

		Instructions
		/sub-22473/ses-02/func/sub-22473_ses-02_task-rest_run-01_bold.nii.gz
		/sub-22473/ses-02/func/sub-22473_ses-02_task-fracnoback_bold.nii.gz

		4 more files with the same issue

		TaskDescription
		/sub-22473/ses-02/func/sub-22473_ses-02_task-rest_run-01_bold.nii.gz
		/sub-22473/ses-02/func/sub-22473_ses-02_task-fracnoback_bold.nii.gz

		4 more files with the same issue

		CogAtlasID
		/sub-22473/ses-02/func/sub-22473_ses-02_task-rest_run-01_bold.nii.gz
		/sub-22473/ses-02/func/sub-22473_ses-02_task-fracnoback_bold.nii.gz

		4 more files with the same issue

		CogPOID
		/sub-22473/ses-02/func/sub-22473_ses-02_task-rest_run-01_bold.nii.gz
		/sub-22473/ses-02/func/sub-22473_ses-02_task-fracnoback_bold.nii.gz

		4 more files with the same issue

		SpoilingState
		/sub-22473/ses-02/func/sub-22473_ses-02_task-rest_run-01_bold.nii.gz
		/sub-22473/ses-02/func/sub-22473_ses-02_task-fracnoback_bold.nii.gz

		4 more files with the same issue

		EffectiveEchoSpacing
		/sub-22473/ses-02/anat/sub-22473_ses-02_rec-defaced_T1w.nii.gz
		/sub-22473/ses-02/anat/sub-22473_ses-02_T1w.nii.gz

		6 more files with the same issue

		PhaseEncodingDirection
		/sub-22473/ses-02/anat/sub-22473_ses-02_rec-defaced_T1w.nii.gz
		/sub-22473/ses-02/anat/sub-22473_ses-02_T1w.nii.gz

		6 more files with the same issue

		TotalReadoutTime
		/sub-22473/ses-02/anat/sub-22473_ses-02_rec-defaced_T1w.nii.gz
		/sub-22473/ses-02/anat/sub-22473_ses-02_T1w.nii.gz

		6 more files with the same issue

		MultibandAccelerationFactor
		/sub-22473/ses-02/anat/sub-22473_ses-02_rec-defaced_T1w.nii.gz
		/sub-22473/ses-02/anat/sub-22473_ses-02_T1w.nii.gz

		6 more files with the same issue

	Please visit https://neurostars.org/search?q=SIDECAR_KEY_RECOMMENDED for existing conversations about this issue.

	[WARNING] EVENTS_TSV_MISSING Task scans should have a corresponding 'events.tsv' file.
If this is a resting state scan you can ignore this warning or rename the task to include the word "rest".

		/sub-22473/ses-02/func/sub-22473_ses-02_task-fracnoback_bold.nii.gz
		/sub-22473/ses-01/func/sub-22473_ses-01_task-fracnoback_bold.nii.gz

	Please visit https://neurostars.org/search?q=EVENTS_TSV_MISSING for existing conversations about this issue.

	[ERROR] PARTICIPANT_ID_MISMATCH Participant labels found in this dataset did not match the values in participant_id column
found in the participants.tsv file.

		/participants.tsv

	Please visit https://neurostars.org/search?q=PARTICIPANT_ID_MISMATCH for existing conversations about this issue.

	[ERROR] EMPTY_FILE Empty files not allowed.
		/README

	Please visit https://neurostars.org/search?q=EMPTY_FILE for existing conversations about this issue.


          Summary:                         Available Tasks:         Available Modalities:
          65 Files, 1.8 GB                 rest                     MRI
          1 - Subjects 2 - Sessions        Fractional 0-Back

	If you have any questions, please post on https://neurostars.org/tags/bids.
</pre>
</div>
```

While this may seem like something went wrong, **that's not the case!** There is just missing data that is dataset specific (such as things that go in `dataset_description.json` and `README`) that you have to provide yourself. Also the `participants.tsv` file just has placeholder names, that is also something you have to make sure matches with the actual subject names.

There are also mentions of missing metadata in the jsons, but it turns out none of the ones listed are vital. However, that's not always the case, so make sure to see if any of them are important!

Finally, the task BOLD files are missing an events descriptor, which is also something you should make yourself. See specifics [here.](https://bids-specification.readthedocs.io/en/stable/modality-specific-files/task-events.html)

Now that we have a BIDS valid dataset, we will now work on the act of curating it!