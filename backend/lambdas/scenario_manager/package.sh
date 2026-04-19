#!/bin/bash
set -e

rm -rf package deployment.zip
mkdir package

# boto3 is provided by the Lambda runtime — no extra deps needed
cp lambda_function.py package/

cd package
zip -r ../deployment.zip . -q
cd ..

echo "deployment.zip ready"
