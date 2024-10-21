### ------------------------------------------------------------------------ ###
### Apply chr rule ####
### ------------------------------------------------------------------------ ###

## Before: data/idx.csv
##         data/advice_history.csv
##         data/length_data.rds
## After:  model/advice.rds

library(icesTAF)
taf.libPaths()
library(cat3advice)
# devtools::load_all("../../../data-limited/cat3advice/")
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

### combine catch and index
catch_idx <- full_join(catch_A, idxB) %>%
  select(year, index, catch, landings, discards)

### ------------------------------------------------------------------------ ###
### chr rule control parameters ####
### ------------------------------------------------------------------------ ###
chr_pars <- list(n1 = 2, v = 2, w = 3.7, x = 0.66)


### ------------------------------------------------------------------------ ###
### reference catch ####
### ------------------------------------------------------------------------ ###
### use last catch advice (advice given in 2022 for 2023 and 2024)
A <- A(catch_A, units = "tonnes", 
       basis = "advice", advice_metric = "catch")

### ------------------------------------------------------------------------ ###
### I - biomass index ####
### ------------------------------------------------------------------------ ###
### average of last two values
I <- chr_I(idxB, n_yrs = chr_pars$n1, units = "kg/(hr m beam)")


### ------------------------------------------------------------------------ ###
### HR - harvest rate target ####
### ------------------------------------------------------------------------ ###

### 1st: calculate harvest rate over time
hr <- HR(catch_idx, units_catch = "tonnes", units_index = "kg/(hr m beam)")

### 2nd: calculate harvest rate target
### include multiplier into target harvest rate (from MSE)
### -> do not include later for chr component m (set m=1)
HR <- F(hr, yr_ref = 2003:2023, MSE = TRUE, multiplier = chr_pars$x)


### ------------------------------------------------------------------------ ###
### b - biomass safeguard ####
### ------------------------------------------------------------------------ ###
### first application of chr rule
### use definition of Itrigger from WKBPLAICE 2024:
### - based on Iloss*w in 2007
b <- chr_b(I, idxB, units = "kg/(hr m beam)", yr_ref = 2007, w = chr_pars$w)

### ------------------------------------------------------------------------ ###
### multiplier ####
### ------------------------------------------------------------------------ ###
### set to 1 because multiplier already included in target harvest rate above

m <- chr_m(1, MSE = TRUE)

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
### discard survival ####
### ------------------------------------------------------------------------ ###
### set to 50% by WKBPLAICE 2024
discard_survival <- 0.5

### ------------------------------------------------------------------------ ###
### apply chr rule - combine elements ####
### ------------------------------------------------------------------------ ###
### includes consideration of stability clause

advice <- chr(A = A, I = I, F = HR, b = b, m = m,
              cap = "conditional", cap_upper = 20, cap_lower = -30,
              frequency = "biennial", 
              discard_rate = discard_rate * 100,
              discard_survival = discard_survival * 100)

### ------------------------------------------------------------------------ ###
### save output ####
### ------------------------------------------------------------------------ ###
saveRDS(advice, file = "model/advice.rds")


