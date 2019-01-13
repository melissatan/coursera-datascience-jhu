## Capstone project (script to be run from /algo working dir)

## This script follows after setup.R which creates the training data.
## It assumes that comb.train.txt already exists.

if (!file.exists("./comb.train.txt")) {
  stop("error: please make sure dir has comb.train.txt")
}

if (!file.exists("./train.clean.txt")) {

  library(tm)

  ## Functions to clean up corpus
  removeURL <- function(x) {
    gsub("http.*?( |$)", "", x)
  }
  convertSpecial <- function(x) {
    # replace any <U+0092> with single straight quote, remove all other <>
    x <- gsub("<U.0092>","'",x)  # actually unnecessary, but just in case
    x <- gsub("’","'",x)
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
    x <- gsub("(\\w['-]\\w)|[[:punct:]]", "\\1", x)
    gsub("-", " ", x)
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

  ## Clean combined training set and save to disk
  comb.train <- readLines("./comb.train.txt")
  corpus.raw <- Corpus(VectorSource(comb.train))
  corpus.clean <- CleanCorpus(corpus.raw)
  rm(comb.train)
  rm(corpus.raw)

  # using tm_map is extremely slow, so I convert corpus to df
  cleandf <- data.frame(text=unlist(sapply(corpus.clean,
                            `[`, "content")), stringsAsFactors=F)
  clean.text <- cleandf$text
  writeLines(clean.text, "train.clean.txt")
  rm(corpus.clean)
  rm(clean.text)
  print("made clean train data")
}

train.clean <- readLines("./train.clean.txt")

if (!file.exists("./n1.csv")) {

  library(slam)

  corpus.clean <- Corpus(VectorSource(train.clean))
  ## From clean corpus, make 1-gram TDM and then dataframe.
  comb.tdm1 <- TermDocumentMatrix(corpus.clean)
  n1 <- data.frame(row_sums(comb.tdm1))
  rm(comb.tdm1)
  n1$word1 <- rownames(n1)
  rownames(n1) <- NULL
  colnames(n1) <- c("freq", "word1")
  write.csv(n1, "n1.csv", row.names=FALSE)
  rm(corpus.clean)
  print("wrote n1 csv")
}
# rm(n1)  # re-import later

## Replace all rare words in corpus with UNK
if (!exists("n1")) {
  n1 <- read.csv("n1.csv", stringsAsFactors=FALSE)
}

rare <- subset(n1, freq < 3)
rm(n1)
rare <- rare$word1  # char vec

if (!exists("train.clean")) {
  train.clean <- readLines("./train.clean.txt")
}

## For each line in train.clean, check if word belongs to rare set
library(parallel)

processInput <- function(x, rare) {
  words <- unlist(strsplit(x, " "))
  funk <- function(x, matches) {
    if (x %in% matches) {
      x <- "UNK"
    } else {
      x
    }
  }
  rv <- lapply(words, funk, matches=rare)
  paste(unlist(rv), collapse=" ")
}

numCores <- detectCores()

cl <- makeCluster(numCores)
results = parLapply(cl, train.clean, processInput, rare=rare)
stopCluster(cl)

results <- unlist(results)
writeLines(results, "train.unk.txt")
print("wrote unk-ed text to disk")

