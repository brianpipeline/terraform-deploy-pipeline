#!/bin/bash
# This submission should create a cloud storage bucket and run Terraform with the bucket as the backend.
buildId=$(echo $RANDOM | md5sum | head -c 8)
topicName="topic_$buildId"
subscriptionName="subscription-$buildId"
if ! gcloud pubsub topics create "$topicName"; then
    echo "Topic $topicName already exists"
fi

if ! gcloud pubsub subscriptions create "$subscriptionName" --topic "$topicName"; then
    echo "Subscription $subscriptionName already exists"
fi

gcloud builds submit . --config cloudbuild.yaml --substitutions "_GIT_CLONE_URL=https://github.com/brianpipeline/test-terraform.git,_GIT_REPOSITORY_NAME="test-terraform",_GIT_REF="refs/heads/main",_GIT_HEAD_SHA="ee163d212fa06f111f2f2c133d4b3bbb42035e55",_REPLY_TOPIC=\"projects/cloud-build-pipeline-396819/topics/$topicName\"" --region=us-central1

message=$(gcloud pubsub subscriptions pull --auto-ack "$subscriptionName" --format='value(message.data)' 2>/dev/null)
gcloud pubsub topics delete "$topicName"
gcloud pubsub subscriptions delete "$subscriptionName"
if [[ "$message" == "Pipeline succeeded." ]]; then
    echo "Received Message: $message"
else
    exit 1
fi