#!/bin/sh

set -e

echo "This isn't meant to be executed. Please read the code instead and follow it line by line"
exit 1

# A rough outline of how to setup a GCE instance

source ./env.sh

# Create a project
gcloud projects create "${PROJECT_NAME}"
gcloud config set project "${PROJECT_NAME}"

# Upload the image
gsutil mb "gs://${PROJECT_NAME}"
gsutil cp image.tar.gz "gs://${PROJECT_NAME}/"
gcloud compute images create "${IMAGE_NAME}" --source-uri "gs://${PROJECT_NAME}/image.tar.gz"

# Set the network rules
gcloud compute networks create "${NETWORK_NAME}"
gcloud compute firewall-rules create ping --allow icmp --network "${NETWORK_NAME}"
gcloud compute firewall-rules create letsencrypt-http --allow tcp:80 --network "${NETWORK_NAME}"
gcloud compute firewall-rules create http --allow tcp:8080 --network "${NETWORK_NAME}"
gcloud compute firewall-rules create https --allow tcp:4433 --network "${NETWORK_NAME}"

# Create an IPv4 address
gcloud compute addresses create "${ADDRESS_NAME}" --region "${REGION}"

# Start the instance
gcloud compute instances create "${INSTANCE_NAME}" --image "${IMAGE_NAME}" --address "${ADDRESS_NAME}" --zone "${ZONE}" --machine-type f1-micro --network "${NETWORK_NAME}"
