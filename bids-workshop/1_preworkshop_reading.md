# Pre-Reading: Why is this important?

One of the most frustrating things in research is being given access to a dataset and having **no idea** what you are looking at. File names may be completely unintuitive, and even slight naming convention changes may render your favorite processing code useless. And that's just for __raw__ data! The preprocessed data may even have **weirder** names, and it may be completely unclear how these files were made.

Enter BIDS (the Brain Imaging Data Structure).

By adopting the BIDS standard, researchers can:

- **Organize data systematically:** A clear folder structure and naming conventions eliminate confusion, making it easier to locate and process files.
- **Enhance compatibility:** Tools and pipelines like [fMRIPrep](https://fmriprep.org/) and [qsiprep](https://qsiprep.readthedocs.io/) are built to leverage the consistency provided by BIDS, reducing the need for manual adjustments.
- **Improve reproducibility:** A standard structure helps ensure that analyses are transparent and that results can be reliably replicated by other researchers.

For example, fMRIPrep relies on the consistent organization of BIDS datasets to automate preprocessing steps, minimizing manual intervention and reducing errors. This consistency is essential for ensuring that neuroimaging workflows are both robust and reproducible.

---

## Why BIDS Matters for You, Your Lab, and Society

### For You (the Researcher)
- **Reduced Frustration:** No more guessing where files are or how they were named—BIDS makes data organization straightforward.
- **Streamlined Workflows:** Preprocessing tools like fMRIPrep or qsiprep “just work” when your data follow the BIDS conventions.
- **Saved Time:** Less time spent on manual data wrangling means more time for actual scientific discovery.

### For Your Lab
- **Consistency Among Team Members:** Everyone uses the same data structure, making collaboration smoother and preventing mislabeling or misplacement of files.
- **Easier Onboarding:** New lab members quickly learn where to find data and how to process it, accelerating their productivity.
- **Fewer Errors:** Standardized data reduces confusion and mistakes, improving the overall quality of your lab’s research output.

### For Society
- **Facilitates Open Science:** Sharing data in a standard format allows other researchers to replicate or extend findings, fostering transparency and trust.
- **Enables Large-Scale Analyses:** Consistent organization paves the way for meta-analyses and multi-site collaborations, potentially leading to more robust scientific insights.
- **Promotes Scientific Progress:** By making it easier to share, validate, and build upon existing work, BIDS helps accelerate discoveries that can benefit the broader field and, ultimately, public health.

For further insights into the design and benefits of BIDS—and the evidence supporting standardized data formats in neuroimaging—consider {cite}`gorgolewski2016brain`, {cite}`gorgolewski2017bids`, and {cite}`poldrack2024past`. You can also refer to the [official BIDS specification](https://bids-specification.readthedocs.io/en/stable/).

## The Softwares We Will Be Using
[CuBIDS](https://cubids.readthedocs.io/en/latest/) / {cite}`covitz2022curation`

[BABS](https://pennlinc-babs.readthedocs.io/en/stable/index.html) / {cite}`zhao2024reproducible`

[fMRIPrep](https://fmriprep.org/en/stable/) / {cite}`esteban_fmriprep_2019`

[XCPD](https://xcp-d.readthedocs.io/en/latest/) /  {cite}`mehta2024xcp`

[QSIPrep](https://qsiprep.readthedocs.io/en/latest/usage.html) / {cite}`cieslak2021qsiprep`

[QSIRecon](https://qsirecon.readthedocs.io/en/latest/) / (same citation as qsiprep paper)