## Capstone project (script to be run from /algo working dir)

## Load libraries
library(tm)
library(RWeka)
library(slam)

## Download the datasets, unzip into parent directory
if (!file.exists("../final")) {
  fileUrl <- "https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip"
  download.file(fileUrl, destfile = "../swiftkey.zip")
  unzip("../swiftkey.zip")
}

## Function to create subsample of txt file
SampleTxt <- function(infile, outfile, seed, inlines, percent, readmode) {
  conn.in <- file(infile, readmode)  # readmode = "r" or "rb"
  conn.out <- file(outfile,"w")
  # for each line, flip a coin to decide whether to put it in sample
  set.seed(seed)
  in.sample <- rbinom(n=inlines, size=1, prob=percent)
  i <- 0  # have to use for-loop, not while-loop, bec of in.sample array
  num.out <- 0
  for (i in 1:(inlines+1)) {
    # read in one line at a time
    currLine <- readLines(conn.in, n=1, encoding="UTF-8", skipNul=TRUE)
    # if reached end of file, close all conns
    if (length(currLine) == 0) {
      close(conn.out)
      close(conn.in)
      return(num.out)
    }
    # while not end of file, write out the selected line to file
    if (in.sample[i] == 1) {
      writeLines(currLine, conn.out)
      num.out <- num.out + 1
    }
  }
}

## Make subsample
datalist <- c("../final/en_US/en_US.blogs.txt",
              "../final/en_US/en_US.news.txt",
              "../final/en_US/en_US.twitter.txt")
mypercent <- 0.1
myseed <- 60637
pwd <- getwd()
setwd("../final/en_US")
blog.numlines <- as.numeric(gsub('[^0-9]', '', system("wc -l en_US.blogs.txt", intern=TRUE)))
news.numlines <- as.numeric(gsub('[^0-9]', '', system("wc -l en_US.news.txt", intern=TRUE)))
twit.numlines <- as.numeric(gsub('[^0-9]', '', system("wc -l en_US.twitter.txt", intern=TRUE)))
setwd(pwd)
# files should already exist in dir. if they don't, make them
if (!file.exists("./blog.sample.txt")) {
  blog.sample.numlines <- SampleTxt(datalist[1], "blog.sample.txt",
                                    myseed, blog.numlines, mypercent, "r")
}
if (!file.exists("./news.sample10.txt")) {
  # must use readmode "rb" here, otherwise it breaks on a special char
  news.sample.numlines <- SampleTxt(datalist[2], "news.sample.txt",
                                    myseed, news.numlines, mypercent, "rb")
}
if (!file.exists("./twit.sample.txt")) {
  twit.sample.numlines <- SampleTxt(datalist[3], "twit.sample.txt",
                                    myseed, twit.numlines, mypercent, "r")
}

# get the number of lines in sample, using wc -l
blog.sample.numlines <- as.numeric(gsub('[^0-9]', '',
                          system("wc -l blog.sample.txt", intern=TRUE)))
news.sample.numlines <- as.numeric(gsub('[^0-9]', '',
                          system("wc -l news.sample.txt", intern=TRUE)))
twit.sample.numlines <- as.numeric(gsub('[^0-9]', '',
                          system("wc -l twit.sample.txt", intern=TRUE)))

## Function to partition subsample txt file
PartitionTxt <- function(infile, outfiles, seed, inlines, trainpct, readmode) {
  conn.in <- file(infile, readmode)  # readmode = "r" or "rb"
  conn.out.train <- file(outfiles[1],"w")
  conn.out.valid <- file(outfiles[2],"w")
  conn.out.test  <- file(outfiles[3],"w")
  # hardcode in the threshold percentages because lazy
  thresh.train <- trainpct
  thresh.test  <- 100
  thresh.valid <- thresh.train + ((thresh.test - thresh.train) / 2)
  # random partition with runif
  set.seed(seed)
  i <- 0
  num.processed <- 0
  for (i in 1:(inlines+1)) {
    # read in one line at a time
    currLine <- readLines(conn.in, n=1, encoding="UTF-8", skipNul=TRUE)
    # print(currLine)
    # if reached end of file, close all conns
    if (length(currLine) == 0) {
      close(conn.out.train)
      close(conn.out.valid)
      close(conn.out.test)
      close(conn.in)
      return(num.processed)
    }
    # while not end of file, randomly decide where to write line
    rand <- runif(1) * 100
    # replace smartquote with singlequote in line:
      # currLine <- gsub(".u0092","'", currLine) doesnt work
      # currLine <- gsub("<U.0092>","'", currLine) doesn't work
    currLine <- iconv(currLine, from="", to="UTF-8")
    # print(currLine)
    # write to one of the three output files
    if (rand <= thresh.train) {
      writeLines(currLine, conn.out.train)
    } else if (rand <= thresh.valid) {
      writeLines(currLine, conn.out.valid)
    } else if (rand <= thresh.test) {
      writeLines(currLine, conn.out.test)
    }
    num.processed <- num.processed + 1
  }
}

# Split subsamples into training (60%), validation (20%) and test (20%)

# for debugging purposes:
# PartitionTxt("./bmini.txt",
#               c("test1.txt","test2.txt","test3.txt"),
#               773, blog.sample.numlines, 60, "r")
myseed <- 773; mytrain <- 60
# Create train, valid, test sets, in UTF-8 encoding
if (!file.exists("./blog.train.txt")) {
  PartitionTxt("./blog.sample.txt",
                 c("blog.train.txt","blog.valid.txt","blog.test.txt"),
                 myseed, blog.sample.numlines, mytrain, "r")
}
if (!file.exists("./news.train.txt")) {
  # must use readmode "rb" here, otherwise it breaks on a special char
  PartitionTxt("news.sample.txt",
              c("news.train.txt","news.valid.txt","news.test.txt"),
              myseed, news.sample.numlines, mytrain, "rb")
}
if (!file.exists("./twit.train.txt")) {
  PartitionTxt("twit.sample.txt",
              c("twit.train.txt","twit.valid.txt","twit.test.txt"),
              myseed, twit.sample.numlines, mytrain, "r")
}

## Functions to clean up corpus
removeURL <- function(x) {
  gsub("http.*?( |$)", "", x)
}
convertSpecial <- function(x) {
  # replace any <U+0092> with single straight quote, remove all other <>
  x <- gsub("<U.0092>","'",x)  # actually unnecessary, but just in case
  gsub("<.+?>"," ",x)
}
myRemoveNumbers <- function(x) {
  # remove any word containing numbers
  gsub("\\S*[0-9]+\\S*", " ", x)
}
removeProfanity <- function(x) {
  # remove any string that contains *
  gsub("\\S*[*]+\\S*", " ", x)
}
myRemovePunct <- function(x) {
  # custom function to remove most punctuation
  # replace everything that isn't alphanumeric, space, ', -, *
  gsub("[^[:alnum:][:space:]'*-]", " ", x)
}
myDashApos <- function(x) {
  # deal with dashes, apostrophes, asterisks within words
  x <- gsub("--+", " ", x)
  # preserve intra-word dashes, apostrophes, remove all else
  gsub("(\\w['*-]\\w)|[[:punct:]]", "\\1", x)
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
  x <- tm_map(x, content_transformer(removeProfanity))
  x <- tm_map(x, content_transformer(myRemovePunct))
  x <- tm_map(x, content_transformer(myDashApos))
  # x <- tm_map(x, removeWords, stopwords("english"))
  x <- tm_map(x, content_transformer(stripWhitespace))
  x <- tm_map(x, content_transformer(trim))
  return(x)
}

## Import training sets. Combine into one, and clean
if (!file.exists("./comb.train.txt")) {
  blog.train <- readLines("./blog.train.txt")
  news.train <- readLines("./news.train.txt")
  twit.train <- readLines("./twit.train.txt")
  comb.train <- c(blog.train, news.train, twit.train)
  rm(blog.train); rm(news.train); rm(twit.train)
  writeLines(comb.train, "./comb.train.txt")
}
comb.train <- readLines("./comb.train.txt")
comb.corpus.raw <- Corpus(VectorSource(comb.train))
comb.corpus <- CleanCorpus(comb.corpus.raw)
rm(comb.train); rm(comb.corpus.raw)

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

## From clean corpus, make 1-gram TDM and then dataframe.
comb.tdm1 <- TermDocumentMatrix(comb.corpus)
n1 <- data.frame(dimnames(comb.tdm1)$Terms, row_sums(comb.tdm1))
rm(comb.tdm1)
colnames(n1) <- c("term", "count")
rownames(n1) <- NULL
write.csv(n1, "n1.csv"); rm(n1)  # re-import later

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

## Function that takes a phrase and looks for it in df
FindPhrase <- function(x) {  # x must be string
  words <- strsplit(x, " ")  # split string by space
  len <- length(words)
  last3 <- paste(words[len-2], words[len-1], words[len])
  last2 <- paste(words[len-1], words[len])
  last1 <- words[len]
}



