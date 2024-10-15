#!/bin/bash

# Variables
#SERVICE_CODE="mobius-utility-service"  # Provided service code
#K8_REPO_ACCESS_SECRET="$K8_REPO_ACCESS_SECRET"  # Access secret from environment variable
#REPO_URL="https://api.github.com/repos/gaiangroup/k8s-files-master/contents/helm/"  # Provided repo URL
#K8S_FILES_PATH="helm/$SERVICE_CODE/values.yaml"  # Path to values.yaml in the repository
#BACKUP_FILE="values_backup.yaml"  # Backup file for restoration

SERVICE_CODE=$service_code
K8_REPO_ACCESS_SECRET=$k8_repo_access_secret
REPO_URL=$repo_url
K8S_FILES_PATH=$k8s_files_path
BACKUP_FILE=$backup_file

# Function to exit with an error message
function exit_with_error() {
    echo "ERROR: $1"
    exit 1
}

# Ensure the script is running in a Git repository
if [ ! -d ".git" ]; then
    exit_with_error "This is not a Git repository. Please run the script in the correct directory."
fi

# Ensure the K8_REPO_ACCESS_SECRET is set
if [ -z "$K8_REPO_ACCESS_SECRET" ]; then
    exit_with_error "K8_REPO_ACCESS_SECRET environment variable is not set. Please set it before running the script."
fi

# Revert the code to the previous commit
echo "Reverting code to the previous commit due to failure..."
git fetch --all || exit_with_error "Failed to fetch the latest changes from the remote repository."
git reset --hard HEAD~1 || exit_with_error "Failed to reset the repository to the previous commit."
git push --force || exit_with_error "Failed to push the reverted commit to the remote repository."

# Check if the backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    exit_with_error "Backup file $BACKUP_FILE not found. Cannot restore values.yaml."
fi

# Restore values.yaml from the backup
echo "Restoring values.yaml from the backup file..."
SHA=$(curl -s -H "Authorization: Bearer $K8_REPO_ACCESS_SECRET" \
              -H "Accept: application/vnd.github.v3+json" \
              "$REPO_URL/$K8S_FILES_PATH?ref=prod" | jq -r .sha)

if [ -z "$SHA" ]; then
    exit_with_error "Failed to fetch the SHA of the existing values.yaml file from the GitHub repository."
fi

# Base64 encode the backup file
NEW_CONTENT=$(base64 -w 0 "$BACKUP_FILE")
if [ -z "$NEW_CONTENT" ]; then
    exit_with_error "Failed to encode the backup file."
fi

# Update the values.yaml in the GitHub repository
UPDATE_RESPONSE=$(curl -s -X PUT \
  -H "Authorization: Bearer $K8_REPO_ACCESS_SECRET" \
  -H "Content-Type: application/json" \
  "$REPO_URL/$K8S_FILES_PATH" \
  -d "{\"message\": \"Reverting values.yaml to backup\", \"content\": \"$NEW_CONTENT\", \"sha\": \"$SHA\", \"branch\": \"prod\"}")

# Check if the update was successful
if echo "$UPDATE_RESPONSE" | grep -q '"commit"'; then
    echo "Successfully reverted values.yaml to the backup version."
else
    exit_with_error "Failed to update values.yaml in the repository. Response: $UPDATE_RESPONSE"
fi
