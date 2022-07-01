#!/usr/bin/env Rscript

library(ggplot2)
library(tidyverse)
library(reshape2)
library(hrbrthemes)
library(RColorBrewer)
library(plyr)
library(zoo)
library(viridis)
library(ggnewscale)
library(ggforce)
library(cowplot)


args <- commandArgs(trailingOnly=TRUE)

table_path <- args[1]
normdata_path <- args[2]

zscore <- function(x, na.rm = FALSE) (x - mean(x, na.rm = na.rm)) / sd(x, na.rm)

data <- read.table(table_path, sep='\t', header=T)

rdata <- data %>% mutate(Frontal = ctx.rh.caudalmiddlefrontal +
                ctx.rh.lateralorbitofrontal +
                ctx.rh.medialorbitofrontal +
                ctx.rh.parsopercularis +
                ctx.rh.parsorbitalis +
                ctx.rh.parstriangularis +
                ctx.rh.precentral +
                ctx.rh.rostralmiddlefrontal +
                ctx.rh.superiorfrontal,
               Temporal = ctx.rh.entorhinal +
                 ctx.rh.fusiform +
                 ctx.rh.inferiortemporal +
                 ctx.rh.middletemporal +
                 ctx.rh.parahippocampal +
                 ctx.rh.superiortemporal +
                 ctx.rh.transversetemporal +
                 Right.Amygdala,
               Hippocampus = Right.Hippocampus,
               Frontal_Parietal = ctx.rh.paracentral,
               Parietal = ctx.rh.inferiorparietal +
                          ctx.rh.postcentral +
                          ctx.rh.precuneus +
                          ctx.rh.superiorparietal +
                          ctx.rh.supramarginal,
               Insula = ctx.rh.insula,
               Cingulate = ctx.rh.caudalanteriorcingulate +
                           ctx.rh.isthmuscingulate +
                           ctx.rh.posteriorcingulate +
                           ctx.rh.rostralanteriorcingulate,
               Occipital = ctx.rh.cuneus +
                           ctx.rh.lateraloccipital +
                           ctx.rh.lingual +
                           ctx.rh.pericalcarine,
               BasalGanglia = Right.Caudate + Right.Putamen +
                              Right.Pallidum + Right.Accumbens.area,
               Thalamus = Right.Thalamus.Proper,
               Cerebellum = Right.Cerebellum.White.Matter +
                            Right.Cerebellum.Cortex,
               CorpusCallosum = CC_Posterior + CC_Mid_Posterior + CC_Central + CC_Mid_Anterior + CC_Anterior,
               Ventricles = Right.Lateral.Ventricle +
                            Right.Inf.Lat.Vent +
                            Right.choroid.plexus +
                            X3rd.Ventricle + X4th.Ventricle + CSF,
                VentralDC = Left.VentralDC + Right.VentralDC,
                WM = Right.Cerebral.White.Matter,
                Brainstem = Brain.Stem) %>%
    select(ids, age, Frontal, Temporal, Hippocampus, Frontal_Parietal, Parietal, Insula, Cingulate, Occipital,, BasalGanglia,
           Thalamus, Cerebellum, CorpusCallosum, Ventricles, VentralDC, WM, Brainstem, eTIV)

ldata <- data %>% mutate(Frontal = ctx.lh.caudalmiddlefrontal +
                ctx.lh.lateralorbitofrontal +
                ctx.lh.medialorbitofrontal +
                ctx.lh.parsopercularis +
                ctx.lh.parsorbitalis +
                ctx.lh.parstriangularis +
                ctx.lh.precentral +
                ctx.lh.rostralmiddlefrontal +
                ctx.lh.superiorfrontal,
               Temporal = ctx.lh.entorhinal +
                 ctx.lh.fusiform +
                 ctx.lh.inferiortemporal +
                 ctx.lh.middletemporal +
                 ctx.lh.parahippocampal +
                 ctx.lh.superiortemporal +
                 ctx.lh.transversetemporal +
                 Left.Amygdala,
               Hippocampus = Left.Hippocampus,
               Frontal_Parietal = ctx.lh.paracentral,
               Parietal = ctx.lh.inferiorparietal +
                          ctx.lh.postcentral +
                          ctx.lh.precuneus +
                          ctx.lh.superiorparietal +
                          ctx.lh.supramarginal,
               Insula = ctx.lh.insula,
               Cingulate = ctx.lh.caudalanteriorcingulate +
                           ctx.lh.isthmuscingulate +
                           ctx.lh.posteriorcingulate +
                           ctx.lh.rostralanteriorcingulate,
               Occipital = ctx.lh.cuneus +
                           ctx.lh.lateraloccipital +
                           ctx.lh.lingual +
                           ctx.lh.pericalcarine,
               BasalGanglia = Left.Caudate + Left.Putamen +
                              Left.Pallidum + Left.Accumbens.area,
               Thalamus = Left.Thalamus.Proper,
               Cerebellum = Left.Cerebellum.White.Matter +
                            Left.Cerebellum.Cortex,
               CorpusCallosum = CC_Posterior + CC_Mid_Posterior + CC_Central + CC_Mid_Anterior + CC_Anterior,
               Ventricles = Left.Lateral.Ventricle +
                            Left.Inf.Lat.Vent +
                            Left.choroid.plexus +
                            X3rd.Ventricle + X4th.Ventricle + CSF,
                VentralDC = Left.VentralDC + Left.VentralDC,
                WM = Left.Cerebral.White.Matter,
                Brainstem = Brain.Stem) %>%
    select(ids, age, Frontal, Temporal, Hippocampus, Frontal_Parietal, Parietal, Insula, Cingulate, Occipital,, BasalGanglia,
           Thalamus, Cerebellum, CorpusCallosum, Ventricles, VentralDC, WM, Brainstem, eTIV)

rdata['LR']='R'
ldata['LR']='L'

data_s <- rbind(rdata, ldata)

data_norm_s <- data_s %>% mutate_at(vars(Frontal:Brainstem), ~./as.double(eTIV))

normdata <- read.table(normdata_path, sep=',', header=T) #%>% select(-c(X))


w=20

data_s_tmp <- data_norm_s %>%
    gather(key='ROI',value='Volume', 'Frontal':'Brainstem')
normdata_tmp <- normdata %>%
    gather(key='ROI',value='Volume', 'Frontal':'Brainstem')

data_norm_p95 <- normdata %>% arrange(age) %>% mutate_at(vars(Frontal:Brainstem), rollapply, width=w, quantile, probs=0.95, fill=NA) %>% select(-c(ids)) %>%
    gather(key='ROI',value='Volume', 'Frontal':'Brainstem')

data_norm_p75 <- normdata %>% arrange(age) %>% mutate_at(vars(Frontal:Brainstem), rollapply, width=w, quantile, probs=0.75, fill=NA) %>% select(-c(ids)) %>%
    gather(key='ROI',value='Volume', 'Frontal':'Brainstem')

data_norm_p25 <- normdata %>% arrange(age) %>% mutate_at(vars(Frontal:Brainstem), rollapply, width=w, quantile, probs=0.25, fill=NA) %>% select(-c(ids)) %>%
    gather(key='ROI',value='Volume', 'Frontal':'Brainstem')

data_norm_p50 <- normdata %>% arrange(age) %>% mutate_at(vars(Frontal:Brainstem), rollapply, width=w, quantile, probs=0.50, fill=NA) %>% select(-c(ids)) %>%
    gather(key='ROI',value='Volume', 'Frontal':'Brainstem')

data_norm_p05 <- normdata %>% arrange(age) %>% mutate_at(vars(Frontal:Brainstem), rollapply, width=w, quantile, probs=0.05, fill=NA) %>% select(-c(ids)) %>%
    gather(key='ROI',value='Volume', 'Frontal':'Brainstem')

data_norm_perc <- rbind(data_norm_p95 %>% mutate(percentile=0.95),
                        data_norm_p50 %>% mutate(percentile=0.50))
data_norm_perc <- rbind(data_norm_perc,
                         data_norm_p05 %>% mutate(percentile=0.05))
data_norm_perc <- data_norm_perc %>% mutate(percentile=factor(percentile))

scatterplot <- ggplot(normdata_tmp, aes(x=age, y=Volume, group=ROI, shape=LR)) +
    geom_point(alpha=0.2) +
#    geom_smooth(data=data_norm_p50, aes(x=age, y=Volume), se=F) +
#    geom_smooth(data=data_norm_p95, aes(x=age, y=Volume), se=F) +
#    geom_smooth(data=data_norm_p05, aes(x=age, y=Volume), se=F) +
geom_smooth(data=data_norm_perc, aes(x=age, y=Volume, group=percentile), color='black', se=F) +
scale_color_viridis_d(begin=0.4, end=0.8)+
new_scale_color()  +

geom_point(data=data_s_tmp, aes(x=age, y=Volume, shape=LR, color=ids), size=5) +
scale_color_viridis_d(option='plasma', begin=0.4, end=0.8)+

    facet_wrap(vars(ROI), scales = "free") +
    theme_bw() +
    labs(x='Age', y='Volume') +
    theme(text = element_text(size=20))
    #theme(legend.position = 'none')

print('save scatterplot')
ggsave(paste(dirname(table_path), 'scatterplot.png', sep='/'), plot=scatterplot, width=600, height=300, units='mm')

lnormdata <- normdata %>% filter(LR=='L')
rnormdata <- normdata %>% filter(LR=='R')

age_min <- min(data_norm_s$age) -1
age_max <- max(data_norm_s$age) +1


znormdata <- rbind(lnormdata %>% filter(age > age_min & age <= age_max) %>%
dplyr::mutate(across(Frontal:Brainstem, zscore)),
                rnormdata %>% filter(age > age_min & age <= age_max) %>%
dplyr::mutate(across(Frontal:Brainstem, zscore)))

lnormmeans <- lnormdata %>% dplyr::summarize(across(Frontal:Brainstem, mean))
lnormsd <- lnormdata %>% dplyr::summarize(across(Frontal:Brainstem, sd))

rnormmeans <- rnormdata %>% dplyr::summarize(across(Frontal:Brainstem, mean))
rnormsd <- rnormdata %>% dplyr::summarize(across(Frontal:Brainstem, sd))

zscore2 <- function(x, normmean, normsd, na.rm = FALSE) (x - normmean) / normsd

ldata_s <- data_norm_s %>% filter(LR=='L')
rdata_s <- data_norm_s %>% filter(LR=='R')

for (i in colnames(lnormsd)) {
    ldata_s[i] <- zscore2(ldata_s[i], unlist(lnormmeans[i]), unlist(lnormsd[i]))
    rdata_s[i] <- zscore2(rdata_s[i], unlist(rnormmeans[i]), unlist(rnormsd[i]))
    }

zdata_s <- rbind(ldata_s, rdata_s)

tmp_normz <- znormdata %>%
gather(key='rois',value='z_score', 'Frontal':'Brainstem')

tmp_zdata_s <- zdata_s %>%
gather(key='rois',value='z_score', 'Frontal':'Brainstem')

ids= unique(tmp_zdata_s$ids)

pl <- ggplot(tmp_normz, aes(x=rois, y=z_score), alpha=0.4, width = 0.25) +
    geom_link(aes(x = rois, xend=rois, y = -3, yend=3, colour = stat(index)), lineend = "round", size = 10, show.legend = F)+
    geom_jitter(data=tmp_normz%>% filter(LR=='L'), aes(x=rois, y=z_score), alpha=0.4, width = 0.25)+
    new_scale_color() +
    ylim(-3,+3)

n = 0.0
 for (i in ids) {
     pl <- pl + geom_boxplot(data=tmp_zdata_s %>% filter(LR=='L', ids==i), aes(x=rois, y=z_score, fill=ids, color=ids), size=1)
     }

     pl <- pl+
scale_fill_viridis_d('IDs',option='plasma', begin=0.4)+
scale_color_viridis_d('IDs', option='plasma', begin=0.4)+
    coord_flip() +
    theme_bw() +
    labs(title='Sub-R001', x='ROI', y='Z_score') +
    theme(legend.position="bottom",
         axis.text.x = element_text(size=16),
         axis.text.y = element_text(size=16),
         text = element_text(size=16))

pr <- ggplot(tmp_normz, aes(x=rois, y=z_score), alpha=0.4, width = 0.25) +
    geom_link(aes(x = rois, xend=rois, y = -3, yend=+3, colour = stat(index)), lineend = "round", size = 10, show.legend=F)+
    geom_jitter(data=tmp_normz%>% filter(LR=='R'), aes(x=rois, y=z_score), alpha=0.4, width = 0.25)+
    new_scale_color() +
    ylim(-3,+3)

for (i in ids) {
    pr <- pr + geom_boxplot(data=tmp_zdata_s %>% filter(LR=='R', ids==i), aes(x=rois, y=z_score, fill=ids, color=ids), size=1)
    }
    pr <- pr+
scale_fill_viridis_d('IDs', option='plasma', begin=0.4)+
scale_color_viridis_d('IDs', option='plasma', begin=0.4)+
    coord_flip() +
    theme_bw() +
    labs(title='Sub-R001', x='ROI', y='Z_score') +
    theme(legend.position="bottom",
         axis.text.x = element_text(size=16),
         axis.text.y = element_text(size=16),
         text = element_text(size=16))

sliding_plot <- plot_grid(pr, pl, labels = c('R', 'L'), label_size = 20)
print('saving_sliding_plot')

ggsave(paste(dirname(table_path), 'scatterplot.png', sep='/'), plot=sliding_plot, width=600, height=300, units='mm')


