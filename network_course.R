#########################################################################
#  title: "Redes Complexas: Análises Básicas"
#author: "Carine Emer"
#date: "11/10/2018"
#output: html_document
#editor_options: 
#chunk_output_type: console
########################################################################

#Curso de Introdução à Teoria de Redes Ecológicas

#Todas as espécies interagem com alguma outra espécie na natureza. Nessa prática os alunos
#coletarão dados sobre interações mutualísticas na natureza (ex. formiga-planta, dispersor
#de semente-planta, polinizador-planta) e/ou utilizarão dados próprios ou da literatura para
#analisar métricas básicas de redes complexas.

#No final do curso o aluno será capaz de:
#1) Desenhar uma rede de interações com diferentes pacotes
#2) Testar se rede é a conectada, modular ou aninhada com uso de modelos nulos
#3) Identificar a centralidade dos nodos
#4) Explorar a estrutura da rede, robustez e seu significado biológico

##########################################################################
#__________________________________________________________________________
#Warning 1: this script works for both binary and weighted networks.

#Warning 2: there is no single magic way to draw all kinds of network.
#There are several network drawing methods implemented in R packages
#and stand-alone software. Study their logic and algorithms,
#see some papers in which they were used, think it through,
#and only then decide which drawing method to use in your study.(M. Mello)

#Warning 3: Null models are an endless discussion in Ecology. The choice of null models
#depends on your question, but is essential to test the significance of the data.
#Chose carefully, based on the biological meanings of the randomization process.

#Warning 4: always check for updates of packages and R versions, specially if you start to have weird errors.

#Have fun!

#########################################################################


# Set the working directory
#setwd("paste your working directory path here")
setwd("~/Documents/Documents - Girassol/Network course/Curso Redes UESC 2018/práticas R/data")
#knitr::opts_knit$set(root.dir = "~/Documents/Documents - Girassol/Network course/Curso Redes UESC 2018/práticas R/data")


# load packages
library(bipartite)
library(vegan)
library(reshape2)
library(igraph)
library(networkD3)
library(reshape2)
#########################################################################


### input data

### you can use the dataset available or your own data. To do so, just replace "the name within brackets" below for your won.

### Binary networks - qualitative data
poll_b<-read.csv("pollination_NewZealand_bin.csv", head=T,row.names=1)
ants_b<-read.csv("ants_Amazon_bin.csv", head=T,row.names=1)
seed_b<-read.csv("seed_dispersal_AtlanticForest_bin.csv", head=T,row.names=1)


###### Weighted networks - quantitative data
poll<-read.csv("pollination_NewZealand.csv", head=T,row.names=1)
ants<-read.csv("ants_Amazon.csv", head=T,row.names=1)
seed<-read.csv("seed_dispersal_AtlanticForest.csv", head=T,row.names=1)

##### check data
poll
dim(poll)
str(poll)


#########################################################################
#Drawing networks
#########################################################################

#### Observe topological differences between binary and weighted networks for the different systems

#### Invaded pollination network from a sub-alpine vegetation, New Zealand (Emer et al. 2016. DOI: 10.1111/ddi.12458)
poll_network<-plotweb(poll,
                      ## set overall parameters 
                      text.rot=c(90), labsize=1,arrow="down.center",
                      y.width.low=0.05,y.width.high=0.05, ybig=1.8, low.y=1.2, high.y=2,
                      high.spacing=.01, low.spacing=0.01,
                      # shorter labels
                      #high.lablength=3, low.lablength=0, 
                      ### check the method if you prefer
                      method="cca", 
                      ### set colors
                      col.low="green", col.high="yellow", col.interaction = "grey80")

#### Network of ant-myrmecophyte interactions from a dam-fragmented island in Balbina, Central Amazon (Emer et al. 2013. DOI: 10.1111/cobi.12045).

# vectors for all colours can be given, to mark certain species or 
# interactions. Colour vectors are recycled if not of appropriate length - BE CAREFULL
# colors are given according to the number of the cells in the matrix/dataframe (rows x cols). It is counted from right-to-left,up-to-down
# for example, lets color the interaction between Cordia nodosa and Azteca sp5 as blue, creating a vector for that. 

# check size of the network by multiplying the n of rows and columns
dim(ants) # 11*15 = 165

#check the position of the interaction of interest, create the vector
my.col<-c(rep("white",33),rep("blue",1),rep("white",131))                          
myrm_network<-plotweb(ants,text.rot=c(90),            labsize=1,y.width.low=0.05,y.width.high=0.05,arrow="down.center",ybig=1.8, low.y=1.2, high.y=2, high.spacing=.01, low.spacing=0.01,method="cca",
                      col.interaction = my.col)


#### Avian seed-dispersal network from Ilha Anchieta, Atlantic Forest (Bello et al. 2017. DOI doi/10.1002/ecy.1818/).
seed_network<-plotweb(seed,text.rot=c(90),labsize=1,y.width.low=0.05,y.width.high=0.05,
                      arrow="down.center",ybig=1.8, low.y=1.2, high.y=2, high.spacing=.01, low.spacing=0.01,
                      method="cca", ### check the method if you prefer
                      col.low="green", col.high="yellow", col.interaction = "grey80")

#export the image
#png('seed_network.png')

#dev.off()
# Tip: There are many other parameters that can be set to customize the drawing.
# Explore them!

### for examples of tri-trophic interactions and how to add abundances in the axis see "script_visual_Gruber_Safariland.R" (https://rdrr.io/cran/bipartite/man/plotweb.html)

#########################################################################
### some more complex but flexible ways of drawing networks
### code needs update to differentiate plants and animals
m<- read.csv("ants_Amazon.csv", head=T)
clos<-read.csv("closeness_ants.csv", head=T)

# transforms the column to a list of character strings
clos$species <- as.character(clos$species) 
# transforms the column to a numeric vector
clos$closeness <- as.character(clos$closeness) 
clos$guild<-as.character(clos$guild) 

## transform to edgelist
m1<-melt(m) 
## select only interactions =1
m2 <- subset(m1, value>0) 

# sets the graph framework
g=graph.data.frame(m2,directed=FALSE) 
#Check the main properties of the igraph object
V(g)
E(g)
# ordering clos so that the order of species list matches the order of species in graph g
clos <- clos[order(match(clos$species, V(g)$name)),] 
clos$closeness <- as.numeric(clos$closeness)

# to a given value of closeness you associate a colour
#color <- colorRampPalette(c('white','blue')) # colour palette
# the colour vector for each species
closeness.col <- heat.colors(25)[as.numeric(cut(-clos$closeness, breaks = 25))] 


## to create a vector for guild
V(g)$guild=as.character(clos$guild)
V(g)$shape=V(g)$guild
V(g)$shape[V(g)$guild=="ant"]="circle"
V(g)$shape[V(g)$guild=="plant"]="square"

plot(g,
     # Set the drawing mode
     # This package contains several drawing methods; try them!
     layout=layout_nicely,
     # Set title
     main='Ant-myrmecophyte network',
     # Set node sizes
     vertex.size=6,
     # Set node attributes
     vertex.shape=V(g)$shape,
     vertex.size = 12,
     vertex.color = closeness.col,
     # Set link colors
     edge.color = "lightblue",
     # Set link curvature from 0 to 1
     edge.curved=0.3,
     # Set nodes labels
     vertex.label.dist=200,
     vertex.label.color='black',
     vertex.label.font=1,
     vertex.label=V(g)$name,
     vertex.label.cex=0.5
)
#export the image
#png('antplant_network.png')

############################## BIPARTITE NETWORKS W/ IGRAPH #########
V(g)$type <- V(g)$name %in% m2[,1]
bipartite.projection(g)
V(g)$x <- V(g)
V(g)$y <- E(g)
col <- c("steelblue", "orange")
shape <- c("circle", "square")

V(g)$shape <- shape[as.numeric(V(g)$type) + 1]
V(g)$color <- col
E(g)$color <- 'gray'
plot(g)


#```{r plot networks network3D}
n3D<-simpleNetwork(m2)
n3D
#saveNetwork(n3D, file = "ants_network3D.html") ### save network as html


#########################################################################
#Network Structure and null models 
#########################################################################


### Observe the differences in some metrics for the analyses of netwoks.
#Run the metrics for other systems, compare the topology among them.
#What does it mean?

#### Explore possibilities of different null models in the different packages, for example:
#??oecosimu
#??vegan::commsim
#??nullmodel

############## Degree distribution ##########################
#??degreedistr ## check the help for some limitations of this method

poll.dd <- degreedistr(poll)
poll.dd
#Dark grey: exp
#Medium grey: power law
#Light grey: truncated power law

############################## CONNECTANCE #####################
obs_c<-networklevel(ants, index="connectance")
# Set Null Model
null_r2d<-oecosimu(ants,networklevel, "r2d", index="connectance",nsim=100)
null_r2d
densityplot(permustats(null_r2d))


############################ NESTEDNESS ########################## 
nested_ants<-networklevel(ants, index = "weighted NODF")
nested_ants

# Set Null Model
obs_nested<-nested_ants
null1<-oecosimu(ants,nestednodf,"quasiswap_count",nsimul = 100, order=FALSE)
null1
densityplot(permustats(null1))

#### Using the classical nullmodels for bipartite
## method 3 = vaznull, explore the other possibilities and discuss when to chose one or another
null <-nullmodel(ants, N=100, method=3) 
null1 <-sapply (X=null, FUN=nested, method="NODF2") 
means_null1 <- apply (X=cbind(null1),MARGIN=2, FUN=mean, na.rm=T)  
sd.means_null1 <- apply(X=cbind(null1), MARGIN=2, FUN=sd, na.rm=T)
z_score<-(obs_nested-means_null1)/sd.means_null1
z_score
p_value<-sum(null1>= obs_nested)/1000 # valor de p
p_value

plot(density(null1), lwd=2, xlim=c(0, 40))
abline(v=obs_nested, col="red", lwd=1)

############################ MODULARITY ########################## 
m_ants<-computeModules(ants)
m_ants
# Check the components of each module
printoutModuleInformation(m_ants)
plotModuleWeb(m_ants)

# Set Null Model
nulls <- nullmodel(ants, N=100, method=1) 
modules.nulls <- sapply(nulls, computeModules)
like.nulls <- sapply(modules.nulls, function(x) x@likelihood)
z <- (m_ants@likelihood - mean(like.nulls))/sd(like.nulls)
p <- 2*pnorm(-abs(z))
plot(density(like.nulls), lwd=2, xlim=c(0, .8))
abline(v=m_ants@likelihood, col="red", lwd=1)

#save.image("pratica_redes.RData")


#########################################################################
#CENTRALITY
#########################################################################

#### identify the degree, closess and betweenness of your species

## To test different indexes, you just have to change the index parameter. Level defines whether the index is calculated for the rows (lower) or columns (higher).

clos_ants<-specieslevel(ants,index = "closeness", level= "higher")

### Explore other indexes by yourself

########## Estimating hubs and connectors according to Olensen et al. 2007, PNAS.
cz <- czvalues(m_ants)
plot(cz[[1]], cz[[2]], pch=16, xlab="c, participation coefficient P", ylab="z, within-module degree", cex=0.8, xlim=c(-1,2.5), las=1, ylim= c(-1.5,4))
abline(v=0.62) # threshold of Olesen et al. 2007
abline(h=2.5)   # dito
text(cz[[1]], cz[[2]], names(cz[[1]]), pos=4, cex=0.7)



#### save the data
#write.csv(clos_ants, "closeness_ants_higher.csv")



### Save your results, so you dont have to run everything again once you want to update your code.

#save.image("pratica_redes.RData")
#dev.off()

#########################################################################
#NETWORK ROBUSTNESS
#########################################################################
#This index is based on:
#Burgos, E., H. Ceva, R.P.J. Perazzo, M. Devoto, D. Medan, M. Zimmermann, and A. Maria Delbue (2007) Why nestedness in mutualistic networks? Journal of Theoretical Biology 249, 307ñ313
#Slope.bipartite È baseado em 
#Memmott, J., Waser, N. M. and Price, M. V. (2004) Tolerance of pollination networks to species extinctions. Proceedings of the Royal Society B 271, 2605ñ2611
## However, there are many implications on using it, mainly because it does consider rewiring. Check the literature for updates.


#Removing species randomly
par(mfrow=c(1,2))
#retirada aleatória
ants.extlower.r <- second.extinct(ants, participant="lower", 
                                  method="random", nrep=100, details=FALSE)
robustness(ants.extlower.r)
#png(filename="dispersao1extlower_random.png", width = 500, height = 500)
slope.bipartite(ants.extlower.r, pch=19, cex=.5)
#dev.off()


#Removing species according to their degree
ants.extlower.d <- second.extinct(ants, participant="lower", method="degree", nrep=100, details=FALSE)
robustness(ants.extlower.d)
#png(filename="dispersao1extlower_degree.png", width = 500, height = 500)
slope.bipartite(ants.extlower.d, pch=19, cex=0.5)
#dev.off()


#########################################################################
#Now you are ready to explore other parameters of the networks and play with your drawings. Networks are a world of possibilities. Be creative and you will succeed!! 
#########################################################################
