### ------------------------------------------------------------------------ ###
### Apply rfb rule ####
### ------------------------------------------------------------------------ ###

## Before: data/idx.csv
##         data/advice_history.csv
##         data/length_data.rds
## After:  model/advice.rds

library(icesTAF)
taf.libPaths()
library(cat3advice)
library(dplyr)

mkdir("model")

### ------------------------------------------------------------------------ ###
### load data ####
### ------------------------------------------------------------------------ ###

### history of catch and advice
catch <- read.taf("data/advice_history.csv")
catch <- catch %>%
  select(year, advice = advice_catch_stock, discards = ICES_discards_stock,
         landings = ICES_landings_stock , catch = ICES_catch_stock)

### biomass index
idxB <- read.taf("data/idx.csv")

### catch length data
lngth <- read.taf("data/length_data.csv")

### ------------------------------------------------------------------------ ###
### reference catch ####
### ------------------------------------------------------------------------ ###
### use catch advice value for 2022 (no update)
A <- A(catch[catch$year <= 2022, ], units = "tonnes", 
       basis = "advice", advice_metric = "catch")

### ------------------------------------------------------------------------ ###
### r - biomass index trend/ratio ####
### ------------------------------------------------------------------------ ###
### 2 over 3 ratio
### add 1-year lag with n0=1 to keep last year's index ratio
r <- rfb_r(idxB, units = "kg/hr", n0 = 1)

### ------------------------------------------------------------------------ ###
### b - biomass safeguard ####
### ------------------------------------------------------------------------ ###
### keep reference year for Itrigger from last year
### add 1-year lag with n0=1 to keep last year's index ratio
b <- rfb_b(idxB, units = "kg/hr", yr_ref = 2007, n0 = 1)

### ------------------------------------------------------------------------ ###
### f - length-based indicator/fishing pressure proxy ####
### ------------------------------------------------------------------------ ###

### calculate annual length at first capture - for information only
lc_annual <- Lc(lngth, units = "mm")
### keep Lc calculation from last year 
### (pool 2017-2021 data, exclude new 2022 data)
lc <- Lc(lngth, pool = 2017:2021, units = "mm")

### mean annual catch length above Lc
lmean <- Lmean(lngth, Lc = lc, units = "mm")

### reference length LF=M - keep value calculated last year
### Linf calculated by fitting von Bertalanffy model to age-length data
lref <- Lref(basis = "LF=M", Lc = lc, Linf = 585, units = "mm")

### length indicator
### add 1-year lag with n0=1 to keep last year's index ratio
f <- rfb_f(Lmean = lmean, Lref = lref, units = "mm", n0 = 1)

### ------------------------------------------------------------------------ ###
### multiplier ####
### ------------------------------------------------------------------------ ###
### generic multiplier based on life history (von Bertalanffy k)
### k value from fitting von Bertalanffy model to age-length data

m <- rfb_m(k = 0.11)

### ------------------------------------------------------------------------ ###
### apply rfb rule - combine elements ####
### ------------------------------------------------------------------------ ###
### includes consideration of stability clause

advice <- rfb(A = A, r = r, f = f, b = b, m = m,
              cap = "conditional", cap_upper = 20, cap_lower = -30,
              frequency = "biennial", 
              discard_rate = 26.71693)

### ------------------------------------------------------------------------ ###
### save output ####
### ------------------------------------------------------------------------ ###
saveRDS(advice, file = "model/advice.rds")
saveRDS(lc_annual, file = "model/lc_annual.rds")


