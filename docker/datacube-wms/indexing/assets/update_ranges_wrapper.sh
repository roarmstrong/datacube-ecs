#!/bin/bash
# Wraps the update_ranges.sh script by passing in environment variables
# from the Docker's environment variables

./update_ranges.sh -b "$DC_S3_INDEX_BUCKET" -p "$DC_S3_INDEX_PREFIX"