


# Review Corpus Builder

This repository provides workflow for building an integrated review corpus of datasets reviewed by Global Biotic Interactions. 

The examples below are applied to the collection of datasets mentioned in various meetings facilitated by [MicrobeNetNet](https://globalbioticinteractions.org/microbenetnet) and these results are documented in an accompanying data paper.   

## Requirements

[Elton](https://globalbioticinteractions.org/elton), [Preston](https://globalbioticinteractions.org/preston), [duckdb](https://duckdb.org), and a commandline running [bash](https://en.wikipedia.org/wiki/Bash_(Unix_shell)).

## Steps

1. discover and track signatures of dataset with reviews on Zenodo. See related script [track-dataset-signatures.sh](bin/track-dataset-signatures.sh).

```bash
./bin/track-dataset-signatures.sh \
 | tee dataset-signatures.txt \
 | preston track --algo md5 
```

2. stage datasets associated with discovered review signatures. See related script [stage-datasets.sh](bin/stage-dataset.sh). For MicrobeNetNet on 2026-02-26, this results in about 4.2 GiB of content in the ```data/``` folder.

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

3. generate a tab-separated values file with a table of interactions extracted from staged datasets using [Elton](https://globalbioticinteractions.org/elton). For MicrobeNetNet on 2026-02-26, this step took a little over an hour on commodity hardware and resulted in a file ```interactions.tsv``` with size ~6.8 GiB containing over 7M lines. 
 
```bash
cat dataset-staged.nq \
  | elton stream --algo md5 --data-dir data --prov-dir data \
  | tee interactions.tsv
```

4. convert the table to generate a file in parquet format to facilitate analysis using tools like [https://duckdb.org](https://duckdb.org) . For MicrobeNetNet on 2026-02-26, this steps some less than a minute and resulted in a file ```interactions.parquet``` with size less than 300 MiB. 

```bash
duckdb -c "COPY ( SELECT * FROM 'interactions.tsv' ) TO 'interactions.parquet';"
```


## Capacity Queries


### Number of Indexed Interaction Records 

```bash
duckdb -c "SELECT COUNT(*) FROM 'interactions.parquet';"
```

produced 

```
┌────────────────┐
│  count_star()  │
│     int64      │
├────────────────┤
│    7161029     │
│ (7.16 million) │
└────────────────┘
```


### Top 10 Most Frequently Occurring Source Taxon Name

```bash
duckdb -c "SELECT DISTINCT(sourceTaxonName), COUNT(*) as freq FROM 'interactions.parquet' GROUP BY sourceTaxonName ORDER BY freq DESC LIMIT 10;"
```

producing

```
┌──────────────────────────┬────────┐
│     sourceTaxonName      │  freq  │
│         varchar          │ int64  │
├──────────────────────────┼────────┤
│ Funneliformis mosseae    │ 498158 │
│ Entrophospora lamellosa  │ 269038 │
│ Rhizophagus irregularis  │ 238999 │
│ Rhizophagus intraradices │ 185635 │
│ Diversispora aurantia    │ 171170 │
│ Funneliformis caledonius │ 141749 │
│ Racocetra castanea       │ 110574 │
│ Fagus sylvatica          │ 108747 │
│ Acaulospora koskei       │  87100 │
│ Gigaspora decipiens      │  85638 │
├──────────────────────────┴────────┤
│ 10 rows                 2 columns │
└───────────────────────────────────┘
```

which suggests that _Funneliformis mosseae_, a fungus, is the most frequently reported name in indexed species interaction claims in the dataset corpus under review.




## References

https://globalbioticinteractions.org/microbenetnet
 
