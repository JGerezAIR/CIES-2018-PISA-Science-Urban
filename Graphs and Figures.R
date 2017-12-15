# This script prepares each of the figures for CIES 2018 paper: PISA Urban Science (working title)

# Written by Julian Gerez

# Clear workspace

rm(list=ls())

library(ggplot2)

directory <- "G:/Conferences/CIES-2018-PISA-Science-Urban/"

# Percentages

percent <- read.csv(paste0(directory, 'Urban Percentages.csv'))

mean_pct_urban <- mean(percent[["pct_urban"]], na.rm=TRUE)
mean_pct_noturban <- mean(percent[["pct_noturban"]], na.rm=TRUE)

# Performance

performance <- read.csv(paste0(directory, 'Urban Performance.csv'))

