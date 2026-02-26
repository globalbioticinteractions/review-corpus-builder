


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

### Generate a list of dataset references 

To generate a list of dataset references, the following query can be executed:

```
duckdb -csv -c "SELECT DISTINCT(citation), archiveURI, CONCAT('accessed on ', DATE(lastSeenAt), '.') as signature FROM 'interactions.parquet' ORDER BY citation;" | mlr --icsv --otsvlite cat | tr '\t' ' ' 
```

which resulted in the following reference list:

```
AAFC-DAOM DwC-Archive | Darwin Core Archive for Canadian National Mycological Herbarium https://mycoportal.org/portal/content/dwca/AAFC-DAOM_DwC-A.zip accessed on 2026-02-26.
ARIZ DwC-Archive | Darwin Core Archive for University of Arizona, Gilbertson Mycological Herbarium, specimen-based https://mycoportal.org/portal/content/dwca/ARIZ_DwC-A.zip accessed on 2026-02-26.
Abarenkov K, Nilsson RH, Larsson K-H, Taylor AFS, May TW, Frøslev TG, Pawlowska J, Lindahl B, Põldmaa K, Truong C, Vu D, Hosoya T, Niskanen T, Piirmann T, Ivanov F, Zirk A, Peterson M, Cheeke TE, Ishigami Y, Jansson AT, Jeppesen TS, Kristiansson E, Mikryukov V, Miller JT, Oono R, Ossandon FJ, Paupério J, Saar I, Schigel D, Suija A, Tedersoo L, Kõljalg U. 2023. The UNITE database for molecular identification and taxonomic communication of fungi and other eukaryotes: sequences, taxa and classifications reconsidered. Nucleic Acids Research, https://doi.org/10.1093/nar/gkad1039 hash://md5/64b10f445a32904a32c2949594866e1b accessed on 2026-02-26.
BISH DwC-Archive | Darwin Core Archive for Bishop Museum, Herbarium Pacificum https://mycoportal.org/portal/content/dwca/BISH_DwC-A.zip accessed on 2026-02-26.
BPI DwC-Archive | Darwin Core Archive for USDA United States National Fungus Collections https://mycoportal.org/portal/content/dwca/BPI_DwC-A.zip accessed on 2026-02-26.
BRIT DwC-Archive | Darwin Core Archive for Botanical Research Institute of Texas https://mycoportal.org/portal/content/dwca/BRIT_DwC-A.zip accessed on 2026-02-26.
BRU DwC-Archive | Darwin Core Archive for Brown University Herbarium - Fungi https://mycoportal.org/portal/content/dwca/BRU_DwC-A.zip accessed on 2026-02-26.
CHRB DwC-Archive | Darwin Core Archive for Chrysler Herbarium - Mycological Collection https://mycoportal.org/portal/content/dwca/CHRB_DwC-A.zip accessed on 2026-02-26.
CINC DwC-Archive | Darwin Core Archive for University of Cincinnati, Margaret H. Fulford Herbarium - Fungi https://mycoportal.org/portal/content/dwca/CINC_DwC-A.zip accessed on 2026-02-26.
CLEMS DwC-Archive | Darwin Core Archive for Clemson University Herbarium https://mycoportal.org/portal/content/dwca/CLEMS_DwC-A.zip accessed on 2026-02-26.
CSU DwC-Archive | Darwin Core Archive for University of Central Oklahoma Herbarium - Fungi https://mycoportal.org/portal/content/dwca/CSU_DwC-A.zip accessed on 2026-02-26.
CUP DwC-Archive | Darwin Core Archive for Cornell University Plant Pathology Herbarium https://mycoportal.org/portal/content/dwca/CUP_DwC-A.zip accessed on 2026-02-26.
Chaudhary, V. B., Rúa, M. A., Antoninka, A., Bever, J. D., Cannon, J., Craig, A., … Hoeksema, J. D. (2016). MycoDB, a global database of plant response to mycorrhizal fungi. Scientific Data, 3, 160028. doi:10.1038/sdata.2016.28 hash://md5/ce4e1d79bb0d7fb1bc4cd8402f92f8e4 accessed on 2026-02-26.
DBG-DBG DwC-Archive | Darwin Core Archive for Denver Botanic Gardens, Sam Mitchel Herbarium of Fungi https://mycoportal.org/portal/content/dwca/DBG-DBG_DwC-A.zip accessed on 2026-02-26.
DEWV DwC-Archive | Darwin Core Archive for Davis & Elkins College Herbarium - Fungi https://mycoportal.org/portal/content/dwca/DEWV_DwC-A.zip accessed on 2026-02-26.
DUKE DwC-Archive | Darwin Core Archive for Duke University Herbarium Fungal Collection https://mycoportal.org/portal/content/dwca/DUKE_DwC-A.zip accessed on 2026-02-26.
FLAS DwC-Archive | Darwin Core Archive for University of Florida Herbarium - Fungi https://mycoportal.org/portal/content/dwca/FLAS_DwC-A.zip accessed on 2026-02-26.
FLD DwC-Archive | Darwin Core Archive for Fort Lewis College Herbarium https://mycoportal.org/portal/content/dwca/FLD_DwC-A.zip accessed on 2026-02-26.
Falster, Gallagher et al (2021) AusTraits, a curated plant trait database for the Australian flora. Scientific Data 8: 254, https://doi.org/10.1038/s41597-021-01006-6 hash://md5/c4ccba4b446f6054d81cdb8ffd50a094 accessed on 2026-02-26.
Farr, David F.; Rossman, Amy Y.; Castlebury, Lisa A. (2021). United States National Fungus Collections Fungus-Host Dataset. Ag Data Commons. https://doi.org/10.15482/USDA.ADC/1524414. hash://md5/977112d6112bb14f1ad53fc35dbee89b accessed on 2026-02-26.
Flores-Moreno, Habacuc, Treseder, Kathleen, K., , Cornwell, William, K., Maynard, Daniel S., Milo, Amy, M., Abarenkov, Kessy, Afkhami, Michelle, E., Aguilar-Trigueros, Carlos, A., Bates, Scott, Bhatnagar, Jennifer, M., Busby, Posy, E., Christian, Natalie, Crowther, Thomas W., Floudas, Dimitri, Gazis, Romina, Hibbett, David, Kennedy, Peter, F., Lindner, Daniel, L., Nilsson, R. Henrik, Powell, Jeff, Schildhauer, Mark, Schilling, Jonathan, Zanne, Amy, E. 2019. fungaltraits aka funfun: a dynamic functional trait database for the world's fungi. Dataset: https://github.com/traitecoevo/fungaltraits. hash://md5/d110a9340dcec040643282eb28e058c2 accessed on 2026-02-26.
GAM DwC-Archive | Darwin Core Archive for University of Georgia, Julian H. Miller Mycological Herbarium https://mycoportal.org/portal/content/dwca/GAM_DwC-A.zip accessed on 2026-02-26.
Geoffrey Zahn. (2025). gzahn/GlobalAMF_Database: Initial release (Version v1.0) [Computer software]. Zenodo. https://doi.org/10.5281/ZENODO.14812876 hash://md5/b2b03ae44e6840d2ff89352e2f347156 accessed on 2026-02-26.
HCOA DwC-Archive | Darwin Core Archive for College of the Atlantic, Acadia National Park Herbarium https://mycoportal.org/portal/content/dwca/HCOA_DwC-A.zip accessed on 2026-02-26.
ILL DwC-Archive | Darwin Core Archive for University of Illinois Herbarium https://mycoportal.org/portal/content/dwca/ILL_DwC-A.zip accessed on 2026-02-26.
ILLS DwC-Archive | Darwin Core Archive for University of Illinois, Illinois Natural History Survey Fungarium - Fungi https://mycoportal.org/portal/content/dwca/ILLS_DwC-A.zip accessed on 2026-02-26.
ISC DwC-Archive | Darwin Core Archive for Iowa State University, Ada Hayden Herbarium https://mycoportal.org/portal/content/dwca/ISC_DwC-A.zip accessed on 2026-02-26.
International Collection of Microorganisms from Plants (ICMP) hash://md5/504fd2501daae09b0b03362146ce5794 accessed on 2026-02-26.
Iversen CM, McCormack ML, Baer JK, Powell AS, Chen W, Collins C, Fan Y, Fanin N, Freschet GT, Guo D, Hogan JA, Kou L, Laughlin DC, Lavely E, Liese R, Lin D, Meier IC, Montagnoli A, Roumet C, See CR, Soper F, Terzaghi M, Valverde-Barrantes OJ, Wang C, Wright SJ, Wurzburger N, Zadworny M. 2021. Fine-Root Ecology Database (FRED): A Global Collection of Root Trait Data with Coincident Site, Vegetation, Edaphic, and Climatic Data, Version 3. Oak Ridge National Laboratory, TES SFA, U.S. Department of Energy, Oak Ridge, Tennessee, U.S.A. Access on-line at: https://doi.org/10.25581/ornlsfa.014/1459186. hash://md5/d140be6319ddfc37c5e229163f1cfcaa accessed on 2026-02-26.
Kivlin et al. 2025. Microbial Atlas of Predicted Species (MAPS): Arbuscular Mycorrhizal Fungi Records Derived from GenBank. Personal Communication.; Kivlin et al. 2025. Microbial Atlas of Predicted Species (MAPS): Ectomycorrhizal Fungi Records derived from GenBank. Personal Communication. hash://md5/1162b1716c486384eddd59d48ae49658 accessed on 2026-02-26.
LSUM-Fungi DwC-Archive | Darwin Core Archive for Louisiana State University, Bernard Lowy Mycological Herbarium https://mycoportal.org/portal/content/dwca/LSUM-Fungi_DwC-A.zip accessed on 2026-02-26.
Landcare Research (2014-) New Zealand Fungal Herbarium (PDD) specimen data. hash://md5/bba57bcef60681a314a5711762f13fb9 accessed on 2026-02-26.
MICH DwC-Archive | Darwin Core Archive for University of Michigan Herbarium https://mycoportal.org/portal/content/dwca/MICH_DwC-A.zip accessed on 2026-02-26.
MONTU DwC-Archive | Darwin Core Archive for University of Montana Herbarium https://mycoportal.org/portal/content/dwca/MONTU_DwC-A.zip accessed on 2026-02-26.
MSC DwC-Archive | Darwin Core Archive for Michigan State University Herbarium non-lichenized fungi https://mycoportal.org/portal/content/dwca/MSC_DwC-A.zip accessed on 2026-02-26.
MU DwC-Archive | Darwin Core Archive for Miami University, Willard Sherman Turrell Herbarium https://mycoportal.org/portal/content/dwca/MU_DwC-A.zip accessed on 2026-02-26.
NCU-Fungi DwC-Archive | Darwin Core Archive for University of North Carolina at Chapel Hill Herbarium: Fungi https://mycoportal.org/portal/content/dwca/NCU-Fungi_DwC-A.zip accessed on 2026-02-26.
NEB DwC-Archive | Darwin Core Archive for University of Nebraska State Museum, C.E. Bessey Herbarium - Fungi https://mycoportal.org/portal/content/dwca/NEB_DwC-A.zip accessed on 2026-02-26.
OSC DwC-Archive | Darwin Core Archive for Oregon State University Herbarium https://mycoportal.org/portal/content/dwca/OSC_DwC-A.zip accessed on 2026-02-26.
PH DwC-Archive | Darwin Core Archive for Academy of Natural Sciences of Drexel University https://mycoportal.org/portal/content/dwca/PH_DwC-A.zip accessed on 2026-02-26.
Policelli, N., Hoeksema, J.D., Moyano, J., Vilgalys, R., Vivelo, S. and Bhatnagar, J.M. (2023), Global pine tree invasions are linked to invasive root symbionts. New Phytol, 237: 16-21. https://doi.org/10.1111/nph.18527 hash://md5/188bf43c5fc6e2ca54ff437a6b18fe02 accessed on 2026-02-26.
Põlme, S., Abarenkov, K., Henrik Nilsson, R. et al. FungalTraits: a user-friendly traits database of fungi and fungus-like stramenopiles. Fungal Diversity 105, 1–16 (2020). https://doi.org/10.1007/s13225-020-00466-2 hash://md5/165c3c6c75717fb3f1f2635e5c00d7fd accessed on 2026-02-26.
RMS DwC-Archive | Darwin Core Archive for University of Wyoming, Wilhelm G. Solheim Mycological Herbarium https://mycoportal.org/portal/content/dwca/RMS_DwC-A.zip accessed on 2026-02-26.
S. Pehim Limbu, S.L. Stürmer, G. Zahn, C.A. Aguilar-Trigueros, N. Rogers, & V.B. Chaudhary, Climate-linked biogeography of mycorrhizal fungal spore traits, Proc. Natl. Acad. Sci. U.S.A. 122 (29) e2505059122, https://doi.org/10.1073/pnas.2505059122 (2025). hash://md5/16c0e8406681955eb48cc4df5799df99 accessed on 2026-02-26.
SFSU DwC-Archive | Darwin Core Archive for San Francisco State University, Harry D. Thiers Herbarium https://mycoportal.org/portal/content/dwca/SFSU_DwC-A.zip accessed on 2026-02-26.
SYRF DwC-Archive | Darwin Core Archive for State University of New York, SUNY College of Environmental Science and Forestry Herbarium https://mycoportal.org/portal/content/dwca/SYRF_DwC-A.zip accessed on 2026-02-26.
TENN-F DwC-Archive | Darwin Core Archive for University of Tennessee Fungal Herbarium https://mycoportal.org/portal/content/dwca/TENN-F_DwC-A.zip accessed on 2026-02-26.
UC DwC-Archive | Darwin Core Archive for University of California Berkeley, University Herbarium https://mycoportal.org/portal/content/dwca/UC_DwC-A.zip accessed on 2026-02-26.
UCHT-F DwC-Archive | Darwin Core Archive for University of Tennessee, Chattanooga https://mycoportal.org/portal/content/dwca/UCHT-F_DwC-A.zip accessed on 2026-02-26.
UCSC DwC-Archive | Darwin Core Archive for University of California Santa Cruz Fungal Herbarium https://mycoportal.org/portal/content/dwca/UCSC_DwC-A.zip accessed on 2026-02-26.
UNCA-UNCA DwC-Archive | Darwin Core Archive for University of North Carolina Asheville https://mycoportal.org/portal/content/dwca/UNCA-UNCA_DwC-A.zip accessed on 2026-02-26.
USAM DwC-Archive | Darwin Core Archive for University of South Alabama Herbarium https://mycoportal.org/portal/content/dwca/USAM_DwC-A.zip accessed on 2026-02-26.
USCH-Fungi DwC-Archive | Darwin Core Archive for University of South Carolina, A. C. Moore Herbarium Fungal Collection https://mycoportal.org/portal/content/dwca/USCH-Fungi_DwC-A.zip accessed on 2026-02-26.
USF DwC-Archive | Darwin Core Archive for University of South Florida Herbarium - Fungi including lichens https://mycoportal.org/portal/content/dwca/USF_DwC-A.zip accessed on 2026-02-26.
USU-UTC DwC-Archive | Darwin Core Archive for Intermountain Herbarium (fungi, not lichens), Utah State University https://mycoportal.org/portal/content/dwca/USU-UTC_DwC-A.zip accessed on 2026-02-26.
UT-M DwC-Archive | Darwin Core Archive for Natural History Museum of Utah Fungarium https://mycoportal.org/portal/content/dwca/UT-M_DwC-A.zip accessed on 2026-02-26.
VPI DwC-Archive | Darwin Core Archive for Virginia Tech University, Massey Herbarium - Fungi https://mycoportal.org/portal/content/dwca/VPI_DwC-A.zip accessed on 2026-02-26.
VT DwC-Archive | Darwin Core Archive for University of Vermont, Pringle Herbarium, Macrofungi https://mycoportal.org/portal/content/dwca/VT_DwC-A.zip accessed on 2026-02-26.
Větrovský, T., Morais, D., Kohout, P., Lepinay, C., Algora, C., Awokunle Hollá, S., Bahnmann, B.D., Bílohnědá, K., Brabcová, V., D’Alò, F., Human, Z.R., Jomura, M., Kolařík, M., Kvasničková, J., Lladó, S., López-Mondéjar, R., Martinović, T., Mašínová, T., Meszárošová, L., Michalčíková, L., Michalová, T., Mundra, S., Navrátilová, D., Odriozola, I., Piché-Choquette, S., Štursová, M., Švec, K., Tláskal, V., Urbanová, M., Vlk, L., Voříšková, J., Žifčáková, L., Baldrian, P., 2020. GlobalFungi, a global database of fungal occurrences from high-throughput-sequencing metabarcoding studies. Scientific Data 7, 228. https://doi.org/10.1038/s41597-020-0567-7 hash://md5/e75277d6232cb6945dd4364ab821bd88 accessed on 2026-02-26.
WIS DwC-Archive | Darwin Core Archive for Wisconsin State Herbarium, Fungi https://mycoportal.org/portal/content/dwca/WIS_DwC-A.zip accessed on 2026-02-26.
WSP DwC-Archive | Darwin Core Archive for Charles Gardner Shaw Mycological Herbarium, Washington State University https://mycoportal.org/portal/content/dwca/WSP_DwC-A.zip accessed on 2026-02-26.
Öpik, M., Vanatoa, A., Vanatoa, E., Moora, M., Davison, J., Kalwij, J.M., Reier, Ü., Zobel, M. 2010. The online database MaarjAM reveals global and ecosystemic distribution patterns in arbuscular mycorrhizal fungi (Glomeromycota). New Phytologist 188: 223-241. hash://md5/fe1613452656aabf5b2fe52b1a49d6d0 accessed on 2026-02-26. 
```


## References

https://globalbioticinteractions.org/microbenetnet

 
