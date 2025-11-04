#!/bin/bash

dockerfile=$(find . -maxdepth 1 -name "Dockerfile.*" -type f -printf "%f\n" | sort -r | fzf --height 40% --layout reverse)
chrome_version=${dockerfile##*_}
image_name="gitsang/chrome:${chrome_version}"

docker build -f "${dockerfile}" -t "${image_name}" .
docker push "${image_name}"
