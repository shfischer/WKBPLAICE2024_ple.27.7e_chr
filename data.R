### ------------------------------------------------------------------------ ###
### Preprocess data, write TAF data tables ####
### ------------------------------------------------------------------------ ###

## Before: boot/data/FSP7e.csv
##         boot/data/advice/advice_history.csv
##         boot/data/InterCatch_length.csv
## After:  data/idx.csv
##         data/advice_history.csv
##         data/length_data.rds

library(icesTAF)
taf.libPaths()
library(tidyr)
library(dplyr)

### create folder to store data
mkdir("data")

### ------------------------------------------------------------------------ ###
### Biomass index data ####
### ------------------------------------------------------------------------ ###
### 1 biomass index: FSP7e
### - biomass at age (standardised)

### load data from csv
idxB <- read.csv("boot/data/FSP_biomass.csv")

### only ages 2-8 are used -> sum up biomass
idxB <- cbind(idxB["year"], 
              index = apply(idxB[, paste0("WAAge", 2:8)], 1, sum))

### save in data directory
write.taf(idxB, file = "data/idx.csv")
saveRDS(idxB, file = "data/idx.rds")


### ------------------------------------------------------------------------ ###
### catch and advice data ####
### ------------------------------------------------------------------------ ###

catch <- read.csv("boot/data/advice_history.csv")
names(catch)[1] <- "year"
write.taf(catch, file = "data/advice_history.csv")
saveRDS(catch, file = "data/advice_history.rds")

catch_7d <- read.csv("boot/data/ple7d_STF_removals_from_7e_2024.csv")
write.taf(catch_7d, file = "data/catch_7d.csv")

