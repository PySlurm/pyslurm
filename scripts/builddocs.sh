#!/bin/bash

python setup.py clean
pip install -r doc_requirements.txt
scripts/build.sh -j4 -d
mkdocs build
