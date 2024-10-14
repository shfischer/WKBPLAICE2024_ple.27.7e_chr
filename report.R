### ------------------------------------------------------------------------ ###
### Prepare plots and tables for report ####
### ------------------------------------------------------------------------ ###


## Before: model/advice.rds
## After:  figures in report/figures/
##         tables in report/tables

library(icesTAF)
taf.libPaths()
library(icesAdvice)
library(cat3advice)
# devtools::load_all("../../../data-limited/cat3advice/")
library(ggplot2)
library(tidyr)
library(dplyr)

mkdir("report")
mkdir("report/figures")
mkdir("report/tables")

### ------------------------------------------------------------------------ ###
### load advice and catch ####
### ------------------------------------------------------------------------ ###
advice <- readRDS("model/advice.rds")
catch <- read.taf("data/advice_history.csv")
catch_7d <- read.csv("data/catch_7d.csv")


### ------------------------------------------------------------------------ ###
### harvest rates - total, dead, landings ####
### ------------------------------------------------------------------------ ###
df_catch <- catch %>%
  select(year, discards = ICES_discards_stock,
         landings = ICES_landings_stock) %>%
  pivot_longer(cols = -year) %>%
  filter(!is.na(value))
  
c_max <- df_catch %>%
  dplyr::group_by(year) %>%
  dplyr::summarise(catch = sum(value)) %>%
  dplyr::select(catch) %>%
  max(na.rm = TRUE)
yr_min_c <- min(df_catch$year)
yr_max_c <- max(df_catch$year)
cols_c_colours <- c(landings = "#002b5f", discards = "#28b3e8")
p_catch <- ggplot() +
  geom_col(data = df_catch,
                    aes(x = year, y = value/1000, fill = name),
                    na.rm = TRUE) +
  scale_fill_manual("",
                             values = cols_c_colours) + 
  coord_cartesian(ylim = c(0, c_max/1000 * 1.1), 
                           xlim = c(yr_min_c - 1, yr_max_c + 1), 
                           expand = FALSE) +
  labs(x = "", y = "Catches in 1000 tonnes", 
                title = "Catches") +
  theme_bw(base_size = 8) +
  theme(axis.title.y = element_text(face = "bold"),
                 axis.title.x = element_blank(),
                 legend.position = "bottom",
                 legend.key.size = unit(0.5, "lines"),
                 plot.title = element_text(face = "bold", 
                                                    colour = "#002b5f"))
#p_catch

idx_max <- max(advice@I@idx$index, na.rm = TRUE)
p_idx <- ggplot() +
  geom_line(data = advice@I@idx,
                     aes(x = year, y = index),
                     color = "#077c6c",
                     na.rm = TRUE) +
  coord_cartesian(ylim = c(0, idx_max * 1.1), 
                           xlim = c(yr_min_c - 1, yr_max_c + 1), 
                           expand = FALSE) +
  labs(x = "", y = "Biomass index in kg/(hr m beam)", 
                title = "Biomass Index") +
  theme_bw(base_size = 8) +
  theme(axis.title.y = element_text(face = "bold"),
                 axis.title.x = element_blank(),
                 legend.position = "bottom",
                 legend.key.height = unit(0.5, "lines"),
                 plot.title = element_text(face = "bold", 
                                                    colour = "#097e6e"))
#p_idx

### calculate harvest rates
df_hr <- full_join(catch %>%
                     select(year, discards = ICES_discards_stock,
                            landings = ICES_landings_stock),
                   advice@I@idx) %>%
  mutate(hr_total = (landings + discards)/index,
         hr_dead = (landings + discards * 0.5)/index,
         hr_landings = (landings)/index) %>%
  select(year, hr_total, hr_dead, hr_landings) %>%
  pivot_longer(-1) %>%
  filter(!is.na(value)) %>%
  mutate(name = factor(name,
                       levels = c("hr_total", "hr_dead", "hr_landings"),
                       labels = c("HR[total]", "HR[dead]", "HR[landings]")))
hr_max <- max(df_hr$value, na.rm = TRUE)

p_hr <- ggplot() +
  geom_line(data = df_hr,
            aes(x = year, y = value, linetype = name),
            color = "#ed6028", 
            na.rm = TRUE) +
  scale_x_continuous(breaks = scales::pretty_breaks()) +
  coord_cartesian(ylim = c(0, hr_max * 1.1),
                  xlim = c(2003 - 1, 2023 + 1),
                  expand = FALSE) +
  scale_linetype("", 
                 labels = c(expression(HR[total]), expression(HR[dead]),
                            expression(HR[landings]))) + 
  labs(x = "", y = "Harvest rate", 
       title = "Relative harvest rate (catch / biomass index)") +
  theme_bw(base_size = 8) +
  theme(axis.title.y = element_text(face = "bold"),
        axis.title.x = element_blank(),
        legend.position = "bottom",
        legend.key.height = unit(0.5, "lines"),
        plot.title = element_text(face = "bold", 
                                  colour = "#ed6028"))
#p_hr
(p_catch + p_idx)/p_hr
ggsave("report/figures/hr_versions.png", width = 16, height = 12, units = "cm",
       dpi = 300, type = "cairo")

### ------------------------------------------------------------------------ ###
### chr rule - figures ####
### ------------------------------------------------------------------------ ###

### A - reference catch
### compare realised catch to advice
# catch %>%
#   select(year, catch = ICES_catch_stock, advice = advice_catch_stock) %>%
#   pivot_longer(-year) %>%
#   filter(year >= 2016) %>%
#   ggplot(aes(x = year, y = value, fill = name)) +
#   geom_col(position = "dodge") +
#   scale_fill_discrete("") + 
#   scale_x_continuous(breaks = scales::pretty_breaks()) + 
#   labs(y = "Catch (tonnes)", x = "Year") +
#   theme_bw(base_size = 8)
# ggsave("report/figures/catch_advice.png", width = 10, height = 6, units = "cm",
#        dpi = 300, type = "cairo")

### biomass index - I and b ####
plot(advice@b)
ggsave("report/figures/chr_b.png", width = 10, height = 6, units = "cm",
       dpi = 300, type = "cairo")

### harvest rate
plot(advice@F, show.data = FALSE)
ggsave("report/figures/chr_HR.png", width = 10, height = 6, units = "cm",
       dpi = 300, type = "cairo")

### ------------------------------------------------------------------------ ###
### chr rule - advice table ####
### ------------------------------------------------------------------------ ###
### create ICES advice style table
### numbers are rounded following ICES rounding rules


### print to screen
advice(advice)
### save in file
capture.output(advice(advice), file = "report/tables/advice_table.txt")

### ------------------------------------------------------------------------ ###
### advice for 7e area ####
### ------------------------------------------------------------------------ ###

### 7e area discard rate
discard_rate_7e <- catch %>%
  select(year, discards = ICES_discards_7e, landings = ICES_landings_7e,
         catch = ICES_catch_7e) %>%
  mutate(discard_rate = discards/catch) %>%
  filter(year >= 2012) %>%
  summarise(discard_rate = mean(discard_rate, na.rm = TRUE)) %>% 
  as.numeric()

### catch in 7d forecast for 7e stock
catch_7d <- catch_7d %>%
  mutate(catch = landings + discards)

### advice in 7e
advice_catch_7e <- value(advice) - catch_7d$catch
advice_landings_7e <- advice_catch_7e * (1 - discard_rate_7e)
advice_discards_7e <- advice_catch_7e * discard_rate_7e
advice_discards_dead_7e <- advice_discards_7e * (1 - discard_survival)
advice_discards_surviving_7e <- advice_discards_7e * (discard_survival)

advice_7e <- paste0(
  paste(rep("-", 80), collapse = ""), "\n",
  "Plaice in Division 7.e", "\n",
  paste(rep("-", 80), collapse = ""), "\n",
  
  paste0(format("Catches of Division 7.e stock caught in", width = 48), 
         " | ", "\n",
         format("  Division 7.d", width = 48), " | ",
         format(paste0(round(catch_7d$catch), " tonnes"), width = 29, 
                justify = "right"),
         "\n"),
  paste0(format("Catch of plaice in Division 7.e corresponding", width = 48), 
         " | ", "\n",
         format("  to the advice for the stock", width = 48), " | ",
         format(paste0(round(advice_catch_7e), " tonnes"), width = 29, 
                justify = "right"),
         "\n"),
  paste0(format("Area based discard rate", width = 48), " | ", 
         format(paste0(icesAdvice::icesRound(discard_rate_7e * 100), "%"), 
                width = 29, justify = "right")),
         "\n",
  paste0(format("Projected landings of plaice in Division 7.e", width = 48), 
         " | ", "\n",
         format("  corresponding to the advice for the stock", width = 48), 
         " | ",
         format(paste0(round(advice_landings_7e), " tonnes"), width = 29, 
                justify = "right"),
         "\n"),
  paste0(format("Projected total discards of plaice in Division", width = 48), 
         " | ", "\n",
         format("  7.e corresponding to the advice for the stock", width = 48), 
         " | ",
         format(paste0(round(advice_discards_7e), " tonnes"), width = 29, 
                justify = "right"),
         "\n"),
  paste0(format("Discard survival", width = 48), " | ", 
         format(paste0(icesAdvice::icesRound(discard_survival * 100), "%"), 
                width = 29, justify = "right")),
          "\n",
  paste0(format("Projected dead discards of plaice in Division", width = 48), 
         " | ", "\n",
         format("  7.e corresponding to the advice for the stock", width = 48), 
         " | ",
         format(paste0(round(advice_discards_dead_7e), " tonnes"), width = 29, 
                justify = "right"),
         "\n"),
  paste0(format("Projected surviving discards of plaice in", 
                width = 48),
         " | ", "\n",
         format("  Division 7.e corresponding to the advice for", width = 48), 
         " | ", "\n",
         format("  the stock", width = 48), 
         " | ",
         format(paste0(round(advice_discards_surviving_7e), " tonnes"), 
                width = 29, 
                justify = "right"),
         "\n"),
  
  
  paste(rep("-", 80), collapse = ""), "\n"
)
cat(advice_7e)
writeLines(advice_7e, "report/tables/advice_table_7e.txt")
