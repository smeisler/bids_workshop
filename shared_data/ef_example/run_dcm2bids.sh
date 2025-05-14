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
