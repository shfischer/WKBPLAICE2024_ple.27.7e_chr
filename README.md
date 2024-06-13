2024_ple.27.7e_assessment
================

## Plaice (*Pleuronectes platessa*) in Division 7.e (western English Channel) - WGCSE 2024

This repository recreates the stock assessment for plaice (*Pleuronectes
platessa*) in Division 7.e (western English Channel) in `R` from WGCSE
2024.

The advice for this plaice stock is biennial and was last given one year
ago at WGCSE 2022. This repository (2024) is a new assessment.

## R packages

The following R packages are needed:

``` r
icesTAF
icesAdvice
dplyr
tidyr
ggplot2
cat3advice
```

They can be installed with:

``` r
### install/update packages
install.packages(c("icesTAF", "icesAdvice", "dplyr", "tidyr", "ggplot2"))
### install cat3advice from ICES r-universe
install.packages("cat3advice", repos = c("https://ices-tools-prod.r-universe.dev", "https://cloud.r-project.org"))
```

For exact reproducibility, it is recommended to use exactly the same
package version as used in the assessment. These package are
automatically installed into a local library when running the TAF
assessment (see below) or by calling

``` r
library(icesTAF)
taf.boot()
```

## Running the assessment

The easiest way to run the assessment is to clone or download this
repository, navigate into the repository with R and run:

``` r
### load the icesTAF package
library(icesTAF)
### load data
taf.boot(software = FALSE)
### install R package from SOFTWARE.bib - only if needed
if (FALSE) taf.boot(software = TRUE, data = FALSE, clean = FALSE)
### run all scripts
source.all()
```

This code snippet runs the data compilation and assessment and creates
the tables and figures presented in the WG report.
