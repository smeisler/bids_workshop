import os
import pydicom

def remove_fields_from_dicom(dicom_file):
    try:
        # Read the DICOM file
        ds = pydicom.dcmread(dicom_file)
        
        # Remove fields if they exist.
        # Adjust the field names as needed.
        for field in ["operator", "acq_time", "OperatorsName", "AcquisitionTime"]:
            if field in ds:
                del ds[field]
                print(f"Removed {field} from {dicom_file}")

        # Alternatively, if the standard DICOM attribute names are used (for example, "OperatorsName" or "AcquisitionTime")
        # you might use:
        # if hasattr(ds, 'OperatorsName'):
        #     del ds.OperatorsName
        # if hasattr(ds, 'AcquisitionTime'):
        #     del ds.AcquisitionTime

        # Save the modified file (this overwrites the original)
        ds.save_as(dicom_file)
    except Exception as e:
        print(f"Error processing {dicom_file}: {e}")

# Specify the root directory that contains your DICOM folders.
root_dir = "/users/PAS2965/smeisler/workshop/shared_data/ef_example/sourcedata/"

for subdir, dirs, files in os.walk(root_dir):
    for file in files:
        # Modify this if your DICOM files don't have a ".dcm" extension.
        if file.lower().endswith(".dcm"):
            full_path = os.path.join(subdir, file)
            remove_fields_from_dicom(full_path)

