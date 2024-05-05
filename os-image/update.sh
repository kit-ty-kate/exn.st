#!/bin/sh

set -e
set -o pipefail

source ./env.sh

echo
echo "Backing-up the previous image..."
gsutil mv "gs://${PROJECT_NAME}/image.tar.gz" "gs://${PROJECT_NAME}/image-old.tar.gz" || true
echo
echo "Uploading the new image..."
gsutil cp image.tar.gz "gs://${PROJECT_NAME}/image.tar.gz"

echo
echo "Deleting the image..."
echo | gcloud compute images delete "${IMAGE_NAME}" || true
echo
echo "Recreating the image..."
gcloud compute images create "${IMAGE_NAME}" --source-uri "gs://${PROJECT_NAME}/image.tar.gz"

echo
echo "Deleting the instance..."
echo | gcloud compute instances delete "${INSTANCE_NAME}" --zone "${ZONE}" || true
echo
echo "Recreating the instance..."
gcloud compute instances create "${INSTANCE_NAME}" --image "${IMAGE_NAME}" --address "${ADDRESS_NAME}" --zone "${ZONE}" --machine-type f1-micro --network "${NETWORK_NAME}"

echo
echo "Clean up the previous image"
gsutil rm "gs://${PROJECT_NAME}/image-old.tar.gz"
