#/bin/bash
# stage datasets 
#
# usage:
#   cat signatures.txt | ./stage-datasets.sh
#   
#   where signatures.txt contains hash uris like:
#   hash://md5/17cb1afe09fab2499edfc1636640c7c6
#
#   as they appear in data reviews like:
#
#   Elton, Nomer, & Preston. (2026). Versioned Archive and Review of Biotic Interactions and Taxon Names Found within globalbioticinteractions/maarjam hash://md5/17cb1afe09fab2499edfc1636640c7c6. Zenodo. https://doi.org/10.5281/zenodo.18792289
#

set -xe

xargs -I{} preston ls --anchor {} --remote https://zenodo.org --algo md5
