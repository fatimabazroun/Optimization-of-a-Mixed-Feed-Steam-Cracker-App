#!/bin/bash
# Packages lambda_function.py + reportlab into a ZIP ready to upload to AWS Lambda.
# Run from this directory: bash package.sh

set -e

echo ">>> Installing reportlab (Linux x86_64 wheels for Lambda)"
pip3 install reportlab \
  --platform manylinux2014_x86_64 \
  --implementation cp \
  --python-version 3.11 \
  --only-binary=:all: \
  -t package/ --quiet

echo ">>> Copying Lambda handler"
cp lambda_function.py package/

echo ">>> Zipping"
cd package
zip -r ../deployment.zip . -q
cd ..

echo ">>> Done — upload deployment.zip to your Lambda function"
echo "    Lambda console → Code → Upload from → .zip file"
