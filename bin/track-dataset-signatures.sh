#!/bin/bash
#
# find digital signatures of recent  microbenetnet dataset reviews
#

set -xe

PRESTON_OPTS="--algo md5"

track_datasets() {
  preston track ${PRESTON_OPTS} https://raw.githubusercontent.com/globalbioticinteractions/globalbioticinteractions.github.io/refs/heads/main/_data/microbenetnet.tsv
}

find_dataset_review_records() {
  track_datasets
  preston track ${PRESTON_OPTS} -f <(preston ls ${PRESTON_OPTS} | grep "microbenetnet.tsv" | grep hasVersion | head -1 | preston cat | mlr --tsvlite cut -f review_id | tail -n+2 | grep -v NA | sed 's+^+https://zenodo.org/api/communities/globi-review/records?q=%22urn%3Alsid%3Aglobalbioticinteractions.org%3Adataset%3A+g' | sed 's+$+%22+g')
}

find_dataset_signatures() {
  find_dataset_review_records > /dev/null
  preston head ${PRESTON_OPTS}\
	  | preston cat \
	  | grep hasVersion \
	  | grep "zenodo.org/api" \
	  | preston cat \
	  | jq .hits.hits[].metadata.title \
	  | grep -Eo "hash://md5/[a-f0-9]{32}"
}

find_dataset_signatures
