## Capstone project (script to be run from /algo working dir)

## This script sets up all the txt files I need.

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

## Import training sets. Combine into one
if (!file.exists("./comb.train.txt")) {
  blog.train <- readLines("./blog.train.txt")
  news.train <- readLines("./news.train.txt")
  twit.train <- readLines("./twit.train.txt")
  comb.train <- c(blog.train, news.train, twit.train)
  rm(blog.train); rm(news.train); rm(twit.train)
  writeLines(comb.train, "./comb.train.txt")
}

