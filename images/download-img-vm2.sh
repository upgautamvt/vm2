#!/bin/bash

# Set the URL and file name
URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
DOWNLOAD_FILE="noble-server-cloudimg-amd64.img"
NEW_FILE_NAME="noble-server-cloudimg-amd64-vm2.img"

# Check if the new file already exists
if [ -f "$NEW_FILE_NAME" ]; then
  echo "File '$NEW_FILE_NAME' already exists. Skipping download."
else
  # Download the image
  echo "Downloading Ubuntu cloud image..."
  wget $URL -O $DOWNLOAD_FILE

  # Rename the file
  echo "Renaming file..."
  mv $DOWNLOAD_FILE $NEW_FILE_NAME

  # Confirm completion
  if [ -f "$NEW_FILE_NAME" ]; then
    echo "Download and rename successful. File saved as: $NEW_FILE_NAME"
    qemu-img resize "$NEW_FILE_NAME" +70G
  else
    echo "Error: The file was not renamed successfully."
  fi
fi
