## script to quickly create .RData for the shinyapp

datadir <- "../my_data"

pwd <- getwd()
setwd(datadir)

if (!exists("n5")) {
  n5 <- read.csv("n5.csv", stringsAsFactors=FALSE)
}
if (!exists("n4")) {
  n4 <- read.csv("n4.csv", stringsAsFactors=FALSE)
}
if (!exists("n3")) {
  n3 <- read.csv("n3.csv", stringsAsFactors=FALSE)
}
if (!exists("n2")) {
  n2 <- read.csv("n2.csv", stringsAsFactors=FALSE)
}
if (!exists("profanities")) {
  profanities <- readLines("profanity.txt", encoding="UTF-8")
}

setwd(pwd)
rm(pwd)
rm(datadir)
save.image(file = "../my_app/data/ngrams_and_profanities.RData")
