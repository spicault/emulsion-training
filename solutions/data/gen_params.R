library(tidyverse)

fmort = Vectorize(function(t, base=0.05, var=0.02, period=100) {
    base + var * cos(t * 2 * pi/period)
})

fK = Vectorize(function(t, start=100, offset=50, width=100) {
    start + offset * t / width
})

morts = data.frame(id=1:4,
                   base=c(0.05, 0.03, 0.05, 0.04),
                   var=c(0.02, 0.02, 0.01, 0.04),
                   period=c(100, 100, 50, 200))
Ks = data.frame(id=1:4,
                start=c(50, 300, 100, 200),
                offset=c(100, -200, 50, -100),
                width=1000)

pops = cbind(data.frame(population_id = 0:15),
             crossing(m=morts$id, carr=Ks$id) %>% arrange(abs(m-carr))) %>%
    inner_join(morts, by=c("m"="id")) %>%
    inner_join(Ks, by=c("carr"="id")) %>%
    crossing(data.frame(step=0:1000)) %>%
    mutate(mortality = fmort(step, base, var, period),
           K = fK(step, start, offset, width)) %>%
    select(population_id, step, K, mortality)

write.table(pops, 'data/herd_params.csv', sep=",", row.names=FALSE, col.names=TRUE, quote=FALSE)
