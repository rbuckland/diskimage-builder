#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo ":: cloing a copy of src tree into [$DIR/src]"
rsync -av --exclude docker.disk-image-builder  ${DIR}/.. ${DIR}/src

