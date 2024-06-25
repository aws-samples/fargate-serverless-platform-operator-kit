#!/bin/bash
aws ecr batch-delete-image --region $1 \
    --repository-name $2 \
    --image-ids "$(aws ecr list-images --region $1 --repository-name $2 --query 'imageIds[*]' --output json
)" || true