## Capstone project (script to be run from /algo working dir)

## Load libraries
library(tm)
library(RWeka)

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
  i <- 0
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
mypercent <- 0.05
myseed <- 60637
# got the below using wc -l, hardcoded bec lazy
blog.sample.numlines <- 45506
news.sample.numlines <- 51087
twit.sample.numlines <- 119260

# files should already exist in dir. if they don't, make them
if (!file.exists("./blog.sample5.txt")) {
  blog.sample.numlines <- SampleTxt(datalist[1], "blog.sample5.txt", myseed, blog.numlines, mypercent, "r")
}
if (!file.exists("./news.sample5.txt")) {
  # must use readmode "rb" here, otherwise it breaks on a special char
  news.sample.numlines <- SampleTxt(datalist[2], "news.sample5.txt", myseed, news.numlines, mypercent, "rb")
}
if (!file.exists("./twit.sample5.txt")) {
  twit.sample.numlines <- SampleTxt(datalist[3], "twit.sample5.txt", myseed, twit.numlines, mypercent, "r")
}

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
  PartitionTxt("./blog.sample5.txt",
                 c("blog.train.txt","blog.valid.txt","blog.test.txt"),
                 myseed, blog.sample.numlines, mytrain, "r")
}
if (!file.exists("./news.train.txt")) {
  # must use readmode "rb" here, otherwise it breaks on a special char
  PartitionTxt("news.sample5.txt",
              c("news.train.txt","news.valid.txt","news.test.txt"),
              myseed, news.sample.numlines, mytrain, "rb")
}
if (!file.exists("./twit.train.txt")) {
  PartitionTxt("twit.sample5.txt",
              c("twit.train.txt","twit.valid.txt","twit.test.txt"),
              myseed, twit.sample.numlines, mytrain, "r")
}

## Functions to clean up corpus
removeURL <- function(x) {
  gsub("http.*?( |$)", "", x)
}
removeSpecial <- function(x) {
  # replace any <U+0092> with single straight quote, remove all other <>
  x <- gsub("<U.0092>","'",x)  # actually unnecessary, but just in case
  gsub("<.+?>"," ",x)
}
myRemoveNumbers <- function(x) {
  # remove any word containing numbers
  gsub("\\S*[0-9]+\\S*", " ", x)
}
mySingleQuote <- function(x) {
  # convert smart single quotes to straight single quotes
  gsub("[\x82\x91\x92]", "'", x)  # ANSI version, not Unicode version
}
myRemovePunctuation <- function(x) {
  # custom function to remove most punctuation
  # replace everything that isn't alphanumeric, space, ', -, *
  gsub("[^[:alnum:][:space:]'-*]", " ", x)
}
myDashApos <- function(x) {
  # deal with dashes, apostrophes, asterisks within words
  x <- gsub("--+", " ", x)
  gsub("(\\w['-*]\\w)|[[:punct:]]", "\\1", x, perl=TRUE)
}
trim <- function(x) {
  # trim leading and trailing whitespace
  gsub("^\\s+|\\s+$", "", x)
}
CleanCorpus <- function(my.corpus) {  # input should be a Corpus object
  my.corpus <- tm_map(my.corpus, content_transformer(tolower))
  my.corpus <- tm_map(my.corpus, content_transformer(removeURL))
  my.corpus <- tm_map(my.corpus, content_transformer(removeSpecial))
  my.corpus <- tm_map(my.corpus, content_transformer(myRemoveNumbers))
  my.corpus <- tm_map(my.corpus, content_transformer(mySingleQuote))
  my.corpus <- tm_map(my.corpus, content_transformer(myRemovePunctuation))
  my.corpus <- tm_map(my.corpus, content_transformer(myDashApos))
  # my.corpus <- tm_map(my.corpus, removeWords, stopwords("english"))
  my.corpus <- tm_map(my.corpus, content_transformer(stripWhitespace))
  my.corpus <- tm_map(my.corpus, content_transformer(trim))
  return(my.corpus)
}

# Clean up the train corpus
blog.train <- readLines("./blog.train.txt")
blog.corpus.raw <- Corpus(VectorSource(blog.train))
blog.corpus <- CleanCorpus(blog.corpus.raw)
# NB. can't use tm::writeCorpus() because that generates individual documents
# writeLines(as.character(blog.corpus), con="blog.corpus.txt")
rm(blog.corpus.raw)

news.train <- readLines("./news.train.txt")
news.corpus.raw <- Corpus(VectorSource(news.train))
news.corpus <- CleanCorpus(news.corpus.raw)
# writeLines(as.character(news.corpus), con="news.corpus.txt")
rm(news.corpus.raw)

twit.train <- readLines("./twit.train.txt")
twit.corpus.raw <- Corpus(VectorSource(twit.train))
twit.corpus <- CleanCorpus(twit.corpus.raw)
# writeLines(as.character(twit.corpus), con="twit.corpus.txt")
rm(twit.corpus.raw)

## From clean corpus, make TDM
blog.tdm1 <- TermDocumentMatrix(blog.corpus)
news.tdm1 <- TermDocumentMatrix(news.corpus)
twit.tdm1 <- TermDocumentMatrix(twit.corpus)

## Remove sparse terms
max.empty <- 0.8  # set max empty space (zeroes)
blog.tdm1.dense <- removeSparseTerms(blog.tdm, max.empty)
news.tdm1.dense <- removeSparseTerms(news.tdm, max.empty)
twit.tdm1.dense <- removeSparseTerms(twit.tdm, max.empty+0.1)

## Functions to create n-gram Tokenizer to pass on to TDM constructor
BigramTokenizer <- function(x) {
  NGramTokenizer(x, Weka_control(min=2, max=2))
}
TrigramTokenizer <- function(x) {
  NGramTokenizer(x, Weka_control(min=3, max=3))
}
QuadgramTokenizer <- function(x) {
  NGramTokenizer(x, Weka_control(min=4, max=4))
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
# Make n-gram TDMs

# Bigrams
blog.tdm2 <- BigramTDM(blog.corpus)
news.tdm2 <- BigramTDM(news.corpus)
twit.tdm2 <- BigramTDM(twit.corpus)

# Trigrams
#blog.tdm3 <- TrigramTDM(blog.corpus)
#news.tdm3 <- TrigramTDM(news.corpus)
#twit.tdm3 <- TrigramTDM(twit.corpus)

# Quadgrams

# For testing and debugging - inspect n-gram TDMs:
# i <- which(dimnames(blog.tdm)$Terms == "a a")
# inspect(blog.tdm[i+(0:10), 1:20])
