## Usage:
##   Rscript gather_outputs.R PLAN_NAME
## where PLAN_NAME.csv is the experiment plan

## Produce outputs/PLAN_NAME/results.csv
## AUTHOR: Sébastien Picault


library(dplyr)
library(tidyr)

args = commandArgs(trailingOnly=TRUE)
scen.path = args[1]

plan.name = paste(scen.path, 'csv', sep='.')

scen.prefix = paste('outputs', scen.path, sep='/')
ref.prefix = paste('outputs',  'reference', sep='/')

plan <- read.table(plan.name, header=TRUE, sep='\t', dec='.')

scenarios <- plan$scenario_id
plan <- plan %>% select(-scenario_id)

all.results <- data.frame()

total <- dim(plan[1])[1]
pb <- txtProgressBar(min=1, max=total, style=3)
for (expe in 1:total) {
    if (expe == 0) { path <- ref.prefix } else { path <- paste(scen.prefix, scenarios[expe], sep='/') }

    counts <- read.table(paste(path, 'counts.csv', sep='/'), header=TRUE, sep=',')

    all.results <- rbind(all.results, cbind(plan[expe,], counts))

    setTxtProgressBar(pb, expe)
} ## end for
close(pb)

write.table(all.results, paste('outputs', scen.path, 'results.csv', sep='/'),
            row.names=FALSE, sep=',', quote=FALSE)
