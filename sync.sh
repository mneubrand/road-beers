#!/bin/bash
set -e
cd _site
aws s3 sync . s3://road-beers.com --delete --exclude "*.html" --exclude "*.xml" --cache-control="max-age=31536000"
aws s3 sync . s3://road-beers.com --delete --exclude "*" --include "*.html" --include "*.xml" --cache-control="max-age=0, no-cache"
aws cloudfront create-invalidation --distribution-id EH5WFMYUJAR5S --paths "/*"
cd ..
