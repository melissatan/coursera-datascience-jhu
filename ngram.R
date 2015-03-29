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

## Import training set


## Combine into one and clean
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

## From clean corpus, make 1-gram TDM and then dataframe.
comb.tdm1 <- TermDocumentMatrix(comb.corpus)
n1 <- data.frame(dimnames(comb.tdm1)$Terms, row_sums(comb.tdm1))
colnames(n1) <- c("term", "count")
rownames(n1) <- NULL
rm(comb.tdm1)
write.csv(n1, "n1.csv")

## Remove sparse terms -- doesn't really work because we end up with stopwords
# max.empty <- 0.99  # set max empty space (zeroes)
# comb.tdm1.dense <- removeSparseTerms(comb.tdm1, max.empty)
# comb.tdm1.dense

# For testing and debugging - inspect n-gram TDMs:
#i <- which(dimnames(blog.tdm1.dense)$Terms == "beer")
#inspect(blog.tdm1.dense[i+(0:10), 1:20])

## Make n-gram TDMs and turn into dataframe
comb.tdm2 <- BigramTDM(comb.corpus)
n2 <- data.frame(dimnames(comb.tdm2)$Terms, row_sums(comb.tdm2))
colnames(n2) <- c("term", "count")
rownames(n2) <- NULL
rm(comb.tdm2)
write.csv(n2, "n2.csv"); rm(n2)

comb.tdm3 <- TrigramTDM(comb.corpus)
n3 <- data.frame(dimnames(comb.tdm3)$Terms, row_sums(comb.tdm3))
colnames(n3) <- c("term", "count")
rownames(n3) <- NULL
rm(comb.tdm3)
write.csv(n3, "n3.csv"); rm(n3)

comb.tdm4 <- QuadgramTDM(comb.corpus)
n4 <- data.frame(dimnames(comb.tdm4)$Terms, row_sums(comb.tdm4))
colnames(n4) <- c("term", "count")
rownames(n4) <- NULL
rm(comb.tdm4)
write.csv(n3, "n3.csv"); rm(n3)

## Function that counts all terms that occur only once
CountUnk <- function(df) {
  return(sum(df$count == 1))
}

## Filter df to get only the terms that appear more than once.
n1 <- subset(n1, count > 1)
n1 <- rbind(n1, c("UNK",CountUnk(n1)))

n2 <- subset(n2, count > 1)
n2 <- rbind(n2, c("UNK",CountUnk(n2)))

n3 <- subset(n3, count > 1)
n3 <- rbind(n3, c("UNK",CountUnk(n3)))

n4 <- subset(n4, count > 1)
n4 <- rbind(n4, c("UNK",CountUnk(n4)))

## Function that takes a phrase and looks for it in df
FindPhrase <- function(x) {  # x must be string
  words <- strsplit(x, " ")  # split string by space
  len <- length(words)
  last3 <- paste(words[len-2], words[len-1], words[len])
  last2 <- paste(words[len-1], words[len])
  last1 <- words[len]

}



