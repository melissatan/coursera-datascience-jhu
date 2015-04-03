## Capstone project (script to be run from /algo working dir)

## This script follows after setup.R which creates the training data.
## It assumes that comb.train.txt already exists.

## Load libraries
library(tm)
library(RWeka)
library(slam)

if (!file.exists("./comb.train.txt")) {
  print("error: please make sure dir has comb.train.txt")
}
## Functions to clean up corpus
removeURL <- function(x) {
  gsub("http.*?( |$)", "", x)
}
convertSpecial <- function(x) {
  # replace any <U+0092> with single straight quote, remove all other <>
  x <- gsub("<U.0092>","'",x)  # actually unnecessary, but just in case
  x <- gsub("'","'",x)
  gsub("<.+?>"," ",x)
}
myRemoveNumbers <- function(x) {
  # remove any word containing numbers
  gsub("\\S*[0-9]+\\S*", " ", x)
}
# removeProfanity <- function(x) {
#   # remove any string that contains *
#   gsub("\\S*[*]+\\S*", " ", x)
# }
myRemovePunct <- function(x) {
  # custom function to remove most punctuation
  # replace everything that isn't alphanumeric, space, ', -, *
  gsub("[^[:alnum:][:space:]'*-]", " ", x)
}
myDashApos <- function(x) {
  # deal with dashes, apostrophes within words.
  # preserve intra-word apostrophes, remove all else
  x <- gsub("--+", " ", x)
  gsub("(\\w['-]\\w)|[[:punct:]]", "\\1", x)
  x <- gsub("-", "", x)
}
trim <- function(x) {
  # trim leading and trailing whitespace
  gsub("^\\s+|\\s+$", "", x)
}
CleanCorpus <- function(x) {  # input should be a Corpus object
  x <- tm_map(x, content_transformer(tolower))
  x <- tm_map(x, content_transformer(removeURL))
  x <- tm_map(x, content_transformer(convertSpecial))
  x <- tm_map(x, content_transformer(myRemoveNumbers))
  # x <- tm_map(x, content_transformer(removeProfanity))
  x <- tm_map(x, content_transformer(myRemovePunct))
  x <- tm_map(x, content_transformer(myDashApos))
  # x <- tm_map(x, removeWords, stopwords("english"))
  x <- tm_map(x, content_transformer(stripWhitespace))
  x <- tm_map(x, content_transformer(trim))
  return(x)
}

## Clean combined training set
comb.train <- readLines("./comb.train.txt")
comb.corpus.raw <- Corpus(VectorSource(comb.train))
comb.corpus <- CleanCorpus(comb.corpus.raw)
rm(comb.train)
rm(comb.corpus.raw)

## From clean corpus, make 1-gram TDM and then dataframe.
comb.tdm1 <- TermDocumentMatrix(comb.corpus)
n1 <- data.frame(row_sums(comb.tdm1))
rm(comb.tdm1)
n1$word1 <- rownames(n1)
rownames(n1) <- NULL
colnames(n1) <- c("freq", "word1")
write.csv(n1, "n1.csv")
# rm(n1)  # re-import later

## Replace all words that occur only once in corpus with UNK
singles <- subset(n1, freq==1)
singles <- singles$word1  # char vec
# using tm_map is extremely slow, so I convert corpus to df
corpusdf <- data.frame(text=unlist(sapply(comb.corpus,
                      `[`, "content")), stringsAsFactors=F)
textvec <- corpusdf$text  # char vec
for (s in singles) {
  textvec <- gsub(paste0(" ",s," "), " UNK ", textvec)
  textvec <- gsub(paste0("^",s," "), "UNK ", textvec)
  textvec <- gsub(paste0(" ",s,"$"), " UNK", textvec)
}
# convert text (char vec) back to corpus
rm(comb.corpus)
comb.corpus.UNK <- Corpus(VectorSource(textvec))

## Functions to create n-gram Tokenizer to pass on to TDM constructor
delim <- ' \r\n\t.,;:"()?!'
BigramTokenizer <- function(x) {
  NGramTokenizer(x, Weka_control(min=2, max=2, delimiters=delim))
}
TrigramTokenizer <- function(x) {
  NGramTokenizer(x, Weka_control(min=3, max=3, delimiters=delim))
}
QuadgramTokenizer <- function(x) {
  NGramTokenizer(x, Weka_control(min=4, max=4, delimiters=delim))
}
## Functions to construct n-gram TDM
BigramTDM <- function(x) {
  tdm <- TermDocumentMatrix(x, control=list(tokenize=BigramTokenizer))
  return(tdm)
}
TrigramTDM <- function(x) {
  tdm <- TermDocumentMatrix(x, control=list(tokenize=TrigramTokenizer))
  return(tdm)
}
QuadgramTDM <- function(x) {
  tdm <- TermDocumentMatrix(x, control=list(tokenize=QuadgramTokenizer))
  return(tdm)
}



comb.tdm2 <- BigramTDM(comb.corpus)
n2 <- data.frame(dimnames(comb.tdm2)$Terms, row_sums(comb.tdm2))
colnames(n2) <- c("term", "count")
rownames(n2) <- NULL
rm(comb.tdm2)
write.csv(n2, "n2.csv"); rm(n2)  # re-import later

comb.tdm3 <- TrigramTDM(comb.corpus)
n3 <- data.frame(dimnames(comb.tdm3)$Terms, row_sums(comb.tdm3))
colnames(n3) <- c("term", "count")
rownames(n3) <- NULL
rm(comb.tdm3)
write.csv(n3, "n3.csv"); rm(n3)  # re-import later

comb.tdm4 <- QuadgramTDM(comb.corpus)
n4 <- data.frame(dimnames(comb.tdm4)$Terms, row_sums(comb.tdm4))
colnames(n4) <- c("term", "count")
rownames(n4) <- NULL
rm(comb.tdm4)
write.csv(n4, "n4.csv"); rm(n4)  # re-import later

## Function that counts all terms that occur only once
CountUnk <- function(df) {
  return(sum(df$count == 1))
}

## Filter df to get only the terms that appear more than once.
n1 <- read.csv("n1.csv", stringsAsFactors=F)
unknowns1 <- CountUnk(n1)
n1 <- subset(n1[2:3], count > 1)
n1 <- rbind(n1, c("UNK", unknowns1))
write.csv(n1, "n1.dense.csv")

n2 <- read.csv("n2.csv", stringsAsFactors=F)
unknowns2 <- CountUnk(n2)
n2 <- subset(n2[2:3], count > 1)
n2 <- rbind(n2, c("UNK", unknowns2))
write.csv(n2, "n2.dense.csv")

n3 <- read.csv("n3.csv", stringsAsFactors=F)
unknowns3 <- CountUnk(n3)
n3 <- subset(n3[2:3], count > 1)
n3 <- rbind(n3, c("UNK", unknowns3))
write.csv(n3, "n3.dense.csv")

n4 <- read.csv("n4.csv", stringsAsFactors=F)
unknowns4 <- CountUnk(n4)
n4 <- subset(n4[2:3], count > 1)
n4 <- rbind(n4, c("UNK", unknowns4))
write.csv(n4, "n4.dense.csv")

