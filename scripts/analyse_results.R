## Usage:
##   Rscript analyse_results.R PLAN_NAME
## where PLAN_NAME.csv is the experiment plan

## Reads outputs/PLAN_NAME/results.csv
## AUTHOR: Sébastien Picault
## analyse results for rabies control simulations

library(tidyr)
library(dplyr)
library(ggplot2)

args = commandArgs(trailingOnly=TRUE)
scen.path = args[1]

results <- read.table(paste('outputs', scen.path, 'results.csv', sep='/'),
                      header=TRUE, sep=',')
MAX.STEP = max(results$step)
NB.SIMU = max(results$simu_id) + 1

results <- results  %>%
    mutate(persists = as.integer(Y + H > 0) / NB.SIMU)

## names(results)
##  [1] "cattle_vaccination_rate"   "bat_additional_mortality"
##  [3] "simu_id"                   "Bat"
##  [5] "Cattle"                    "D"
##  [7] "Dead"                      "H"
##  [9] "X"                         "Y"
## [11] "Z"                         "agent_id"
## [13] "bat_latent_prevalence"     "bat_rabid_prevalence"
## [15] "cattle_rabid_prevalence"   "cattle_vaccination_rate.1"
## [17] "disease_impact"            "do_vaccination"
## [19] "level"                     "prop_vaccinated"
## [21] "step"

ggplot(results, aes(x=step)) +
    facet_grid(cattle_vaccination_rate ~ bat_additional_mortality, labeller="label_both") +
    geom_line(aes(y=bat_rabid_prevalence, group=simu_id, color="Bats", linetype="Stochastic repetition"), alpha=0.4) +
    geom_line(aes(y=cattle_rabid_prevalence, group=simu_id, color="Cattle", linetype="Stochastic repetition"), alpha=0.4) +
    stat_summary(aes(y=bat_rabid_prevalence, color="Bats", linetype="Average"), geom="line", fun.y="mean") +
    stat_summary(aes(y=cattle_rabid_prevalence, color="Cattle", linetype="Average"), geom="line", fun.y="mean") +
    guides(colour=guide_legend(title="Species", override.aes=list(alpha=1)),
           linetype = guide_legend(title=NULL)) +
    ggtitle('Evolution of prevalence function of control measures') +
    xlab("Time (days)") + ylab("Prevalence") +
    ylim(0, 0.1) +
    theme_bw() +
    theme(legend.position="bottom", legend.direction="horizontal")

ggplot(results, aes(x=step)) +
    facet_grid(cattle_vaccination_rate ~ bat_additional_mortality, labeller="label_both") +
    stat_summary(aes(y=persists), geom="line", fun.y="sum") +
    ggtitle('Evolution of persistence function of control measures') +
    xlab("Time (days)") + ylab("Persistence") +
    theme_bw()

ggplot(results, aes(x=step)) +
    facet_grid(cattle_vaccination_rate ~ bat_additional_mortality, labeller="label_both") +
    stat_summary(aes(y=disease_impact), geom="line", fun.y="sum") +
    ggtitle('Evolution of persistence function of control measures') +
    xlab("Time (days)") + ylab("Persistence") +
    theme_bw()

ggplot(results %>% filter(step == MAX.STEP),
       aes(x=interaction(cattle_vaccination_rate, bat_additional_mortality, sep=" / "),
           y=disease_impact)) +
    geom_boxplot() +
    stat_summary(aes(colour="Average"), geom="point", size=3) +
    xlab("cattle_vaccination_rate / bat_additional_mortality") +
    ggtitle("Disease impact function of control measures") +
    guides(colour=guide_legend(title=NULL)) +
    theme_bw() +
    theme(legend.position="bottom", legend.direction="horizontal")

durations <- results %>%
    filter(persists > 0) %>%
    group_by(cattle_vaccination_rate, bat_additional_mortality, simu_id) %>%
    summarise(duration = n())

ggplot(durations, aes(x=interaction(cattle_vaccination_rate, bat_additional_mortality, sep=" / "),
                      y=duration)) +
    geom_boxplot() +
    stat_summary(aes(colour="Average"), geom="point", size=3) +
    xlab("cattle_vaccination_rate / bat_additional_mortality") +
    ggtitle("Duration of disease persistence function of control measures") +
    guides(colour=guide_legend(title=NULL)) +
    theme_bw() +
    theme(legend.position="bottom", legend.direction="horizontal")
