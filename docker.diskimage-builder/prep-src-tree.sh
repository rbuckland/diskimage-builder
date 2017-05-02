#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo ":: cloning a copy of src tree into [$DIR/src] (Docker needs it as context)"
rsync -av --exclude docker.diskimage-builder  ${DIR}/.. ${DIR}/src

