#!/bin/bash

pip install -r doc_requirements.txt
pip install --no-build-isolation -e .
mkdocs build
