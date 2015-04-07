## Capstone project

## This script follows unk.R, which counts unigram and then cleans corpus.

if (!file.exists("./train.unk.txt")) {
  stop("error: please make sure dir has train.unk.txt")
}

# convert text (char vec) to corpus
library(tm)
if (!exists("train.unk")) {
  train.unk <- readLines("train.unk.txt")
}
corpus.unk <- Corpus(VectorSource(train.unk))
rm(train.unk)

library(RWeka)
delim <- ' \r\n\t.,;:"()?!'
library(slam)
library(stringr)

# make bigram csv
if (!file.exists("./n2.csv")) {
  print("did not find n2, making now")
  BigramTokenizer <- function(x) {
    NGramTokenizer(x, Weka_control(min=2, max=2, delimiters=delim))
  }
  BigramTDM <- function(x) {
    tdm <- TermDocumentMatrix(x, control=list(tokenize=BigramTokenizer))
    return(tdm)
  }
  comb.tdm2 <- BigramTDM(corpus.unk)
  rm(BigramTokenizer); rm(BigramTDM)
  n2 <- data.frame(row_sums(comb.tdm2))
  rm(comb.tdm2)
  n2$term <- rownames(n2)
  rownames(n2) <- NULL
  words <- str_split_fixed(n2$term, " ", 2)  # split col2 by space into 2
  n2 <- cbind(n2[ ,1], words)
  rm(words)
  colnames(n2) <- c("freq", "word1", "word2")
  write.csv(n2, "n2.csv", row.names=FALSE)
  rm(n2)  # re-import later
  print("wrote n2 csv")
}

# make trigram csv
if (!file.exists("./n3.csv")) {
  print("did not find n3, making now")
  TrigramTokenizer <- function(x) {
    NGramTokenizer(x, Weka_control(min=3, max=3, delimiters=delim))
  }
#   TrigramTokenizer <- ngram_tokenizer(3)
  TrigramTDM <- function(x) {
    tdm <- TermDocumentMatrix(x, control=list(tokenize=TrigramTokenizer))
    return(tdm)
  }
  comb.tdm3 <- TrigramTDM(corpus.unk)
  rm(TrigramTokenizer); rm(TrigramTDM)
  n3 <- data.frame(row_sums(comb.tdm3))
  rm(comb.tdm3)
  n3$term <- rownames(n3)
  rownames(n3) <- NULL
  colnames(n3) <- c("freq","term")
  n3 <- subset(n3, n3$freq > 1)
  words <- str_split_fixed(n3$term, " ", 3)  # split col2 by space into 3
  n3 <- cbind(n3$freq, words)
  rm(words)
  colnames(n3) <- c("freq", "word1", "word2", "word3")
  write.csv(n3, "n3.csv", row.names=FALSE)
  rm(n3)  # re-import later
  print("wrote n3 csv")
}

# make quadgram csv
if (!file.exists("./n4.csv")) {
  print("did not find n4, making now")
  QuadgramTokenizer <- function(x) {
    NGramTokenizer(x, Weka_control(min=4, max=4, delimiters=delim))
  }
  QuadgramTDM <- function(x) {
    tdm <- TermDocumentMatrix(x, control=list(tokenize=QuadgramTokenizer))
    return(tdm)
  }
  comb.tdm4 <- QuadgramTDM(corpus.unk)
  rm(QuadgramTokenizer); rm(QuadgramTDM)
  n4 <- data.frame(row_sums(comb.tdm4))
  rm(comb.tdm4)
  n4$term <- rownames(n4)
  rownames(n4) <- NULL
  colnames(n4) <- c("freq", "term")
  n4 <- subset(n4, n4$freq > 1)  # remove singles
  words <- str_split_fixed(n4$term, " ", 4)  # split col2 by space into 4
  n4 <- cbind(n4$freq, words)
  rm(words)
  colnames(n4) <- c("freq", "word1", "word2", "word3", "word4")
  write.csv(n4, "n4.csv", row.names=FALSE)
  rm(n4)  # re-import later
  print("wrote n4 csv")
}

# make Quintgram csv
if (!file.exists("./n5.csv")) {
  print("did not find n5, making now")
  QuintgramTokenizer <- function(x) {
    NGramTokenizer(x, Weka_control(min=5, max=5, delimiters=delim))
  }
  QuintgramTDM <- function(x) {
    tdm <- TermDocumentMatrix(x, control=list(tokenize=QuintgramTokenizer))
    return(tdm)
  }
  comb.tdm5 <- QuintgramTDM(corpus.unk)
  rm(QuintgramTokenizer); rm(QuintgramTDM)
  n5 <- data.frame(row_sums(comb.tdm5))
  rm(comb.tdm5)
  n5$term <- rownames(n5)
  rownames(n5) <- NULL
  colnames(n5) <- c("freq", "term")
  n5k <- subset(n5, n5$freq > 1)
  words <- str_split_fixed(n5k$term, " ", 5)
  n5k <- cbind(n5k$freq, words)
  rm(words)
  colnames(n5k) <- c("freq", "word1", "word2", "word3", "word4", "word5")
  write.csv(n5k, "n5.csv", row.names=FALSE)
  rm(n5k)  # re-import later
  print("wrote n5 csv")
}

print("finished making all CSVs")

## Clean ngrams further?



