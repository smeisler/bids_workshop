# Pre-Reading: Why is this important?

One of the most frustrating things in research is being given access to a dataset and having **no idea** what you are looking at. File names may be completely unintuitive, and even slight naming convention changes may render your favorite processing code useless. And that's just for __raw__ data! The preprocessed data may even have **weirder** names, and it may be completely unclear how these files were made.

Enter BIDS (the Brain Imaging Data Structure).

By adopting the BIDS standard, researchers can:
- **Organize data systematically:** A clear folder structure and naming conventions eliminate confusion, making it easier to locate and process files.
- **Enhance compatibility:** Tools and pipelines like [fMRIPrep](https://fmriprep.org/) and [qsiprep](https://qsiprep.readthedocs.io/) are built to leverage the consistency provided by BIDS, reducing the need for manual adjustments.
- **Improve reproducibility:** A standard structure helps ensure that analyses are transparent and that results can be reliably replicated by other researchers.

For example, fMRIPrep relies on the consistent organization of BIDS datasets to automate preprocessing steps, minimizing manual intervention and reducing errors. This consistency is essential for ensuring that neuroimaging workflows are both robust and reproducible.

For further insights into the design and benefits of BIDS—and the evidence supporting standardized data formats in neuroimaging—consider {cite}`gorgolewski2016brain`, {cite}`gorgolewski2017bids`, and {cite}`poldrack2024past`.

```{bibliography}
```