# MicrobeNetNet Review Corpus Builder

This repository provides workflow for building a integrated corpus of MicrobeNetNet associated datasets reviewed by Global Biotic Interactions. 

## Requirements

Elton, Preston

## Steps

1. discover and track signatures of dataset with reviews on Zenodo. See related script [track-dataset-signatures.sh](bin/track-dataset-signatures.sh).

```bash
./bin/track-dataset-signatures.sh \
 | tee dataset-signatures.txt \
 | preston track --algo md5 
```

2. stage datasets associated with discovered signatures. See related script [stage-datasets.sh](bin/stage-dataset.sh).

```bash
cat dataset-signatures.txt \
 | ./bin/stage-datasets.sh \
 | tee dataset-staged.nq
```

or equivalently

```bash
preston head --algo md5 \
  | preston cat \
  | grep hasVersion \
  | preston cat \
  | ./bin/stage-datasets.sh \
  | tee dataset-staged.nq
```

3. generate a tab-separated values file with a table of interactions extracted from staged datasets using [Elton](https://globalbioticinteractions.org/elton).
 
```bash
cat dataset-staged.nq \
  | elton stream --algo md5 --data-dir data --prov-dir data \
  | tee interactions.tsv
```

4. convert the table to generate a file in parquet format to facilitate analysis using tools like [https://duckdb.org](https://duckdb.org) .

```bash
duckdb -c "COPY ( SELECT * FROM 'interactions.tsv' ) TO 'interactions.parquet';
```

## Capacity Queries


### Number of Indexed Interaction Records 

```bash
duckdb -c "SELECT COUNT(*) FROM 'interactions.parquet';"
```

### Most Frequently Occurring Source Taxon Name

```bash
duckdb -c "SELECT DISTINCT(sourceTaxonName), COUNT(*) as freq FROM 'interactions.parquet' GROUP BY sourceTaxonName ORDER BY freq DESC;"
```



## References

https://globalbioticinteractions.org/microbenetnet
 
