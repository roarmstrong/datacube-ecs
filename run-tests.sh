#! /usr/bin/env bash
# Pass the URL of the service to this script
# requires jq https://github.com/stedolan/jq

# newman doesn't accept multiple data files yet
# process the json to add the service url
cat tests/${WORKSPACE}/${WORKSPACE}-data.json\
    | jq --arg SERVICEURL "$1" '[.[] | .path = $SERVICEURL]'\
    > "${WORKSPACE}-data.json"

newman run tests/${WORKSPACE}/${WORKSPACE}.postman_collection.json -d ${WORKSPACE}-data.json
rm "${WORKSPACE}-data.json"