#!/bin/bash -e

#
# If building a tag other than 'latest' run like:
#   TAG=":ppc64le" ./check-and-rebuild-image.sh 
#
TAG=${TAG:-":latest"}

#
# Check container to see if there are repos that require rebuild
#
set +e
docker run jjhursey/pmix-xver-tester${TAG} /home/pmixer/bin/check-for-updates.py
NUM_REBUILD=$?
set -e
if [ 0 == $NUM_REBUILD ] ; then
    echo "Nothing to rebuild"
    exit 0
fi

#
# If so, then rebuild the image and push upstream
# Note: Currently this rebuilds all of the release branches not just the one
#       that was updated. So it may take longer than is strictly required.
#       This should be improved in the future.
#
date > .build-timestamp
time docker build -t jjhursey/pmix-xver-tester${TAG} .

#
# Push the new version to Docker Hub
#
docker push jjhursey/pmix-xver-tester${TAG}

exit 0
