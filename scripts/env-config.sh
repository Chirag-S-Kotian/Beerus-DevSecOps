#!/bin/bash

# Script to process Kubernetes manifests with environment variables
# Usage: ./scripts/env-config.sh [environment] [path_to_env_file]
# Example: ./scripts/env-config.sh dev .env.dev

set -e

# Check if environment and env file are provided
if [ "$#" -lt 2 ]; then
  echo "Usage: $0 [environment] [path_to_env_file]"
  echo "Example: $0 dev .env.dev"
  exit 1
fi

ENVIRONMENT=$1
ENV_FILE=$2
OUTPUT_DIR="k8s/processed-${ENVIRONMENT}"

# Check if env file exists
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: Environment file $ENV_FILE not found"
  exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "Processing Kubernetes manifests for $ENVIRONMENT environment using $ENV_FILE"

# Load environment variables
source "$ENV_FILE"

# Process k8s manifests
process_directory() {
  local src_dir=$1
  local dest_dir=$2
  
  mkdir -p "$dest_dir"
  
  for file in "$src_dir"/*.yaml "$src_dir"/*.yml; do
    if [ -f "$file" ]; then
      filename=$(basename "$file")
      echo "Processing $file"
      
      # Create a temporary file for envsubst to process
      envsubst < "$file" > "$dest_dir/$filename"
    fi
  done
  
  # Process subdirectories
  for dir in "$src_dir"/*/; do
    if [ -d "$dir" ]; then
      dirname=$(basename "$dir")
      process_directory "$dir" "$dest_dir/$dirname"
    fi
  done
}

# Start processing from the base directory
process_directory "k8s/base" "$OUTPUT_DIR"

# Process environment-specific overlays if they exist
if [ -d "k8s/overlays/$ENVIRONMENT" ]; then
  echo "Applying overlays for $ENVIRONMENT environment"
  process_directory "k8s/overlays/$ENVIRONMENT" "$OUTPUT_DIR"
fi

echo "Kubernetes manifests have been processed and saved to $OUTPUT_DIR"
echo "To apply these manifests, run: kubectl apply -f $OUTPUT_DIR" 