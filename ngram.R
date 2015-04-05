## Capstone project

## This script follows unk.R, which counts unigram and then cleans corpus.

if (!file.exists("./train.unk.txt")) {
  stop("error: please make sure dir has train.unk.txt")
}

# convert text (char vec) to corpus
library(tm)
train.unk <- readLines("train.unk.txt")
corpus.unk <- Corpus(VectorSource(train.unk))

## Functions to create n-gram Tokenizer to pass on to TDM constructor
library(RWeka)
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

library(stringr)
library(slam)

# make bigram csv
comb.tdm2 <- BigramTDM(corpus.unk)
n2 <- data.frame(row_sums(comb.tdm2))
n2$term <- rownames(n2)
words <- str_split_fixed(n2$term, " ", 2)  # split col2 by space into 2
n2 <- cbind(n2[ ,1], words)
rm(words)
colnames(n2) <- c("freq", "word1", "word2")
rownames(n2) <- NULL
rm(comb.tdm2)
write.csv(n2, "n2.csv", row.names=FALSE)
rm(n2)  # re-import later

# make trigram csv
comb.tdm3 <- TrigramTDM(corpus.unk)
n3 <- data.frame(row_sums(comb.tdm3))
n3$term <- rownames(n3)
words <- str_split_fixed(n3$term, " ", 3)  # split col2 by space into 3
n3 <- cbind(n3[ ,1], words)
rm(words)
colnames(n3) <- c("freq", "word1", "word2", "word3")
rownames(n3) <- NULL
rm(comb.tdm3)
write.csv(n3, "n3.csv", row.names=FALSE)
rm(n3)  # re-import later

# make quadgram csv
comb.tdm4 <- QuadgramTDM(corpus.unk)
n4 <- data.frame(row_sums(comb.tdm4))
n4$term <- rownames(n4)
words <- str_split_fixed(n4$term, " ", 4)  # split col2 by space into 4
n4 <- cbind(n4[ ,1], words)
rm(words)
colnames(n4) <- c("freq", "word1", "word2", "word3", "word4")
rownames(n4) <- NULL
rm(comb.tdm4)
write.csv(n4, "n4.csv", row.names=FALSE)
rm(n4)  # re-import later
