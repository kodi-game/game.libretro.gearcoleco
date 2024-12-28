#!/bin/bash
################################################################################
# Copyright (C) 2024 Team Kodi
# SPDX-License-Identifier: GPL-2.0-or-later
################################################################################

#
# Script to update the EMULATOR_BUILD version in a patch file based on the
# latest Git tag from a specified repository.
#
# The script:
#
#   - Reads the repository URL and commit hash from a configuration file
#   - Clones the repository
#   - Determines the latest tag leading up to the specified commit
#   - Updates the patch file with the new version
#
# Run this script and commit the result when new versions are tagged upstream.
#

# Load the gearcoleco.txt file
FILE_PATH="./depends/common/gearcoleco/gearcoleco.txt"

if [[ ! -f "${FILE_PATH}" ]]; then
  echo "File not found: ${FILE_PATH}"
  exit 1
fi

# Extract the base URL and the hash from the file
REPO_URL=$(awk '{print $2}' "${FILE_PATH}" | sed 's/\/archive\/.*//')
COMMIT_HASH=$(awk -F '/' '{print $NF}' "${FILE_PATH}" | sed 's/.tar.gz//')

# Clone the repository to a temporary directory
TMP_DIR=$(mktemp -d)

# Set up a trap to clean up the temporary directory on exit
trap 'rm -rf "${TMP_DIR}"' EXIT

git clone "${REPO_URL}" "${TMP_DIR}"

# Navigate to the cloned repository
cd "${TMP_DIR}" || exit

# Fetch all tags and history
git fetch --tags

# Find the latest tag leading up to the commit hash
LATEST_TAG=$(git describe --tags --abbrev=0 "${COMMIT_HASH}")

if [[ -z "${LATEST_TAG}" ]]; then
  echo "No tag found leading up to the commit hash: ${COMMIT_HASH}"
  exit 1
fi

echo "Latest tag leading up to ${COMMIT_HASH} is ${LATEST_TAG}"

# Navigate back to the original repository
cd - || exit

# Update the patch file with the latest tag
PATCH_FILE="./depends/common/gearcoleco/0001-Explicitly-set-version-variable.patch"
sed -i "s/+.*CXXFLAGS += -DEMULATOR_BUILD=.*/+	CXXFLAGS += -DEMULATOR_BUILD=\\\\\"${LATEST_TAG}\\\\\"/" "${PATCH_FILE}"

echo "Updated ${PATCH_FILE} with EMULATOR_BUILD=${LATEST_TAG}"
