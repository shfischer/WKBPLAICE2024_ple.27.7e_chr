2024_ple.27.7e_assessment
================

## Plaice (*Pleuronectes platessa*) in Division 7.e (western English Channel) - WGCSE 2024 - ***work in progress***

This repository recreates the stock assessment for plaice (*Pleuronectes
platessa*) in Division 7.e (western English Channel) in `R` from WGCSE
2023.

The advice for this plaice stock is biennial and was last given one year
ago at WGCSE 2022. This repository (2024) is a new assessment.

## R packages

The following R packages from CRAN are required to run the assessment:

``` r
TAF
```

They can be installed with:

``` r
### list with required packages
req_pkgs <- c("icesTAF")
### install/update packages
install.packages(req_pkgs)
```

Furthermore, the following packages from GitHub are required:

``` r
cat3advice
```

For exact reproducibility, it is recommended to use exactly the same
package version as used in the assessment. These package are
automatically installed into a local library when running the TAF
assessment (see below) or by calling

``` r
taf.boot()
```

Alternatively, they can be manually installed from GitHub with

``` r
icesTAF::taf.libPaths() # install packages into local TAF library
remotes::install_github("shfischer/cat3advice")
```

## Running the assessment

The easiest way to run the assessment is to clone or download this
repository, navigate into the repository with R and run:

``` r
### load the icesTAF package
library(icesTAF)
### load data and install R packages
taf.boot()
### run all scripts
sourceAll()
```

This code snippet runs the data compilation and assessment and creates
the tables and figures presented in the WG report.
