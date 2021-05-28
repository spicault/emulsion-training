library(ggplot2)
library(tidyr)
library(dplyr)

###############################################################################
# load data

t <- read.table('outputs/counts.csv', sep=',', header=TRUE)

NBPOP <- max(t$population_id) + 1

t$population_id <- factor(t$population_id, levels=c(paste(0:(NBPOP-1)), "metapop"))


###############################################################################
# Proportion of infected nodes over time

temp <- t%>%
    mutate(is_infected = as.integer(I>0)) %>%
    group_by(step, simu_id) %>%
    summarise(prop_infected = sum(is_infected)/NBPOP)

pdf("prop_infected.pdf", paper="a4r", width=12, height=8)
ggplot(temp, aes(x=step, y=prop_infected)) +
    theme_bw() +
    ylim(0, 1) +
    ggtitle("Proportion of infected herds over time",
            subtitle="Repetitions and average") +
    xlab("Time (days)") +
    ylab("Proportion of infected herds") +
    geom_line(aes(group=simu_id), alpha=0.2, linetype=2) +
    stat_summary(geom="line", fun.y="mean", size=1.5)
dev.off()


###############################################################################
# Proportion of health states over time in metapop

temp <- t%>%
    group_by(step, simu_id) %>%
    summarise(S = sum(S), I = sum(I), R = sum(R))

temp <- temp %>%
    mutate(propS = S / (S + I + R),
           propI = I / (S + I + R),
           propR = R / (S + I + R)
           )

pdf("health_states.pdf", paper="a4r", width=12, height=8)
ggplot(temp, aes(x=step)) +
    theme_bw() +
    ylim(0, 1) +
    geom_line(aes(y=propS, colour="S", group=simu_id), alpha=0.5, linetype=3) +
    geom_line(aes(y=propI, colour="I", group=simu_id), alpha=0.5, linetype=3) +
    geom_line(aes(y=propR, colour="R", group=simu_id), alpha=0.5, linetype=3) +
    stat_summary(aes(y=propS, colour="S"), geom="line", fun.y="mean", size=1.5) +
    stat_summary(aes(y=propI, colour="I"), geom="line", fun.y="mean", size=1.5) +
    stat_summary(aes(y=propR, colour="R"), geom="line", fun.y="mean", size=1.5) +
    scale_colour_manual(values=c("S"="#009051", "I"="#C00040", "R"="#005493")) +
    ggtitle("Evolution of health states over time in the  metapopulation",
            subtitle="Repetitions and average") +
    xlab("Time (days)") +
    ylab("Proportion of health states") +
    guides(colour=guide_legend(title="Health state")) +
    theme(legend.position = "bottom", legend.direction="horizontal")
dev.off()



###############################################################################
# Prevalence over time

pal <- c(rainbow(NBPOP), "black")

pdf("prevalences.pdf", paper="a4r", width=12, height=8)
ggplot(t, aes(x=step, y=I/(S+I+R))) +
    theme_bw() +
    ylim(0, 1) +
    geom_line(aes(group=interaction(simu_id, population_id),
                  colour=population_id), alpha=0.5, linetype=3) +
    stat_summary(aes(group=population_id, colour=population_id),
                 geom="line", fun.y="mean") +
    stat_summary(data=temp, aes(y=propI, colour="metapop"),
                 geom="line", fun.y="mean", size=1.5) +
    scale_colour_manual(values=pal) +
    ggtitle("Prevalence over time", subtitle="Repetitions and average") +
    xlab("Time (days)") +
    ylab("Prevalence") +
    guides(colour=guide_legend(title="Population"))
dev.off()

###############################################################################
# Proportion of age groups over time, in metapop

temp <- t%>%
    group_by(step, simu_id) %>%
    summarise(J = sum(J), A = sum(A))

temp <- temp %>%
    mutate(propJ = J / (J + A),
           propA = A / (J + A)
           )

pdf("age_groups.pdf", paper="a4r", width=12, height=8)
ggplot(temp, aes(x=step)) +
    theme_bw() +
    ylim(0, 1) +
    geom_line(aes(y=propJ, colour="J", group=simu_id), alpha=0.5, linetype=3) +
    geom_line(aes(y=propA, colour="A", group=simu_id), alpha=0.5, linetype=3) +
    stat_summary(aes(y=propJ, colour="J"), geom="line", fun.y="mean") +
    stat_summary(aes(y=propA, colour="A"), geom="line", fun.y="mean") +
    scale_colour_manual(values=c("J"="#FF6500", "A"="#800080")) +
    ggtitle("Proportion of age groups over time in the metapopulation",
            subtitle="Repetitions and average") +
    xlab("Time (days)") +
    ylab("Proportion of age groups") +
    guides(colour=guide_legend(title="Age group"))+
    theme(legend.position = "bottom", legend.direction="horizontal")
dev.off()
