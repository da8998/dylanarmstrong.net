#!/bin/bash

echo "Coping website files to S3..."
aws s3 sync src/ s3://dylanarmstrong-net-website-content/
echo "Done."
echo "Zipping and uploading contact lambda to S3..."
zip -r lambda.zip lambda/contact.js
aws s3 cp lambda.zip s3://dylanarmstrong-net-website-content/
rm -rf lambda.zip
echo "Done."

