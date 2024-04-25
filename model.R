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
catch_A <- catch %>%
  select(year, advice = advice_catch_stock, discards = ICES_discards_stock,
         landings = ICES_landings_stock , catch = ICES_catch_stock)

### biomass index
idxB <- read.taf("data/idx.csv")

### catch length data
lngth <- read.taf("data/length_data.csv")

### ------------------------------------------------------------------------ ###
### reference catch ####
### ------------------------------------------------------------------------ ###
### use last catch advice (advice given in 2022 for 2023 and 2024)
A <- A(catch_A[catch_A$year <= 2024, ], units = "tonnes", 
       basis = "advice", advice_metric = "catch")

### ------------------------------------------------------------------------ ###
### r - biomass index trend/ratio ####
### ------------------------------------------------------------------------ ###
### 2 over 3 ratio
r <- rfb_r(idxB, units = "kg/hr")

### ------------------------------------------------------------------------ ###
### b - biomass safeguard ####
### ------------------------------------------------------------------------ ###
### do not redefine biomass trigger Itrigger and keep value defined in 2022
### Itrigger based on Iloss (2007)
b <- rfb_b(idxB, units = "kg/hr", yr_ref = 2007)

### ------------------------------------------------------------------------ ###
### f - length-based indicator/fishing pressure proxy ####
### ------------------------------------------------------------------------ ###

### calculate annual length at first capture - for information only
lc_annual <- Lc(lngth, units = "mm")

### Lc was defined at WGCSE 2022 by using data from 2017:2021
### keep this definition (do not update Lc)
#lc <- Lc(lngth, pool = 2017:2021, units = "mm")
lc <- Lc(264, units = "mm")

### mean annual catch length above Lc
lmean <- Lmean(lngth, Lc = lc, units = "mm")

### reference length LF=M - keep value calculated at WGCSE 2022
### Linf calculated by fitting von Bertalanffy model to age-length data
#lref <- Lref(basis = "LF=M", Lc = lc, Linf = 585, units = "mm")
lref <- Lref(value = 344.2867278973251, basis = "LF=M", units = "mm")

### length indicator
f <- rfb_f(Lmean = lmean, Lref = lref, units = "mm")

### ------------------------------------------------------------------------ ###
### multiplier ####
### ------------------------------------------------------------------------ ###
### generic multiplier based on life history (von Bertalanffy k)
### k value from fitting von Bertalanffy model to age-length data

m <- rfb_m(k = 0.11)

### ------------------------------------------------------------------------ ###
### discard rate ####
### ------------------------------------------------------------------------ ###
discard_rate <- catch %>%
  select(year, discards = ICES_discards_stock, landings = ICES_landings_stock,
         catch = ICES_catch_stock) %>%
  mutate(discard_rate = discards/catch) %>%
  filter(year >= 2012) %>%
  summarise(discard_rate = mean(discard_rate, na.rm = TRUE)) %>% 
  as.numeric()


### ------------------------------------------------------------------------ ###
### apply rfb rule - combine elements ####
### ------------------------------------------------------------------------ ###
### includes consideration of stability clause

advice <- rfb(A = A, r = r, f = f, b = b, m = m,
              cap = "conditional", cap_upper = 20, cap_lower = -30,
              frequency = "biennial", 
              discard_rate = discard_rate * 100)

### ------------------------------------------------------------------------ ###
### save output ####
### ------------------------------------------------------------------------ ###
saveRDS(advice, file = "model/advice.rds")
saveRDS(lc_annual, file = "model/lc_annual.rds")


