#!/bin/bash
set -e

#
# Build the docs and push to GitHub Pages 
#

# Build docs for all jobs within build
make BUILDDIR=/root/docs -C /pyslurm/doc/ html

# Only push to GitHub Pages once per build
if [ "$PYTHON" == "2.7" ] && [ "$CYTHON" == "0.26" ] && [ "$SLURM" == "17.02.7"]
then
    git clone https://github.com/pyslurm/pyslurm.github.io.git
    rsync -av --delete --exclude=.git /root/docs/html/ /pyslurm.github.io/
    cd pyslurm.github.io
    git add .
    git -c user.name="Travis" -c user.email="Travis" commit -m 'Updated docs'
    git push -q https://giovtorres:$GITHUB_TOKEN@github.com/pyslurm/pyslurm.github.io &2>/dev/null
fi
