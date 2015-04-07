## Predict next word based on previously computed ngram csvs

## ----------
# This script assumes that I have CSV files containing n-grams for n=1:4.
# The structure of the resulting dataframe should be:
# <freq> <word1> <word2> <word3> <word4> for the 4-gram, and so on.

# The script takes a sentence, match the last 4/3/2/1 words of the
# sentence to the appropriate ngrams, and predicts the most likely
# next word based on a score derived from word frequencies.
## ----------

## Load in ngrams
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

## Function that cleans a phrase (and removes bracketed parts)
CleanPhrase <- function(x) {
  # convert to lowercase
  x <- tolower(x)
  # remove numbers
  x <- gsub("\\S*[0-9]+\\S*", " ", x)
  # change common hyphenated words to non
  x <- gsub("e-mail","email", x)
  # remove any brackets at the ends
  x <- gsub("^[(]|[)]$", " ", x)
  # remove any bracketed parts in the middle
  x <- gsub("[(].*?[)]", " ", x)
  # remove punctuation, except intra-word apostrophe and dash
  x <- gsub("[^[:alnum:][:space:]'-]", " ", x)
  x <- gsub("(\\w['-]\\w)|[[:punct:]]", "\\1", x)
  # compress and trim whitespace
  x <- gsub("\\s+"," ",x)
  x <- gsub("^\\s+|\\s+$", "", x)
  return(x)
}
# test: should return "i'm two-legged cow pow"
# x <- "(I'm (not a) 5-year-old two-legged -cow-! POW (baa))"
# CleanPhrase(x)

## Function that returns the last N words of cleaned phrase, in a char vec
GetLastWords <- function(x, n) {
  x <- CleanPhrase(x)   # clean x
  words <- unlist(strsplit(x, " "))  # split up string by space
  len <- length(words)
  if (n < 1) {
    stop("GetLastWords() error: number of words  < 0")
  }
  if (n > len) {
    n <- len
  }
  if (n==1) {
    return(words[len])
  } else {
    rv <- words[len]
    for (i in 1:(n-1)) {
      rv <- c(words[len-i], rv)
    }
    rv
  }
}

## Functions to check n-gram for x. Returns df of next word and freq.
# I can't figure out how to combine all these into one -- the difficulty
# lies in filtering the columns because I can't seem to filter by index.
# Each fn returns df with 2 cols: [nextword] [n?freq]
Check5Gram <- function(x, n5, nrows) {
  words <- GetLastWords(x, 4)
  match <- subset(n5, word1 == words[1] & word2 == words[2]
                    & word3 == words[3] & word4 == words[4])
  match <- subset(match, select=c(word5, freq))
  match <- match[order(-match$freq), ]
  sumfreq <- sum(match$freq)
  match$freq <- round(match$freq / sumfreq * 100)
  colnames(match) <- c("nextword","n5.score")
  if (nrow(match) < nrows) {
    nrows <- nrow(match)
  }
  match[1:nrows, ]
}
Check4Gram <- function(x, n4, nrows) {  # n4 df should already exist
  words <- GetLastWords(x, 3)
  match <- subset(n4, word1 == words[1] & word2 == words[2]
                    & word3 == words[3])
  match <- subset(match, select=c(word4, freq))
  match <- match[order(-match$freq), ]
  sumfreq <- sum(match$freq)
  match$freq <- round(match$freq / sumfreq * 100)
  colnames(match) <- c("nextword","n4.score")
  if (nrow(match) < nrows) {
    nrows <- nrow(match)
  }
  match[1:nrows, ]
}
Check3Gram <- function(x, n3, nrows) {  # n4 df should already exist
  words <- GetLastWords(x, 2)
  match <- subset(n3, word1 == words[1] & word2 == words[2])
  match <- subset(match, select=c(word3, freq))
  match <- match[order(-match$freq), ]
  sumfreq <- sum(match$freq)
  match$freq <- round(match$freq / sumfreq * 100)
  colnames(match) <- c("nextword","n3.score")
  if (nrow(match) < nrows) {
    nrows <- nrow(match)
  }
  match[1:nrows, ]
}
Check2Gram <- function(x, n2, nrows) {  # n4 df should already exist
  words <- GetLastWords(x, 1)
  match <- subset(n2, word1 == words[1])
  match <- subset(match, select=c(word2, freq))
  match <- match[order(-match$freq), ]
  sumfreq <- sum(match$freq)
  match$freq <- round(match$freq / sumfreq * 100)
  colnames(match) <- c("nextword","n2.score")
  if (nrow(match) < nrows) {
    nrows <- nrow(match)
  }
  match[1:nrows, ]
}

# test:
# x <- "said the cat in the"
# m5 <- Check5Gram(x, n5, 3)
# m4 <- Check4Gram(x, n4, 3)
# m3 <- Check3Gram(x, n3, 5)
# m2 <- Check2Gram(x, n2, 5)

## Function that combines the nextword match into one dataframe
# nb. function gets n5 ... n2 from parent env
CombineNgrams <- function(x, nrows) {
  # get dfs
  n5.match <- Check5Gram(x, n5, nrows)
  n4.match <- Check4Gram(x, n4, nrows)
  n3.match <- Check3Gram(x, n3, nrows)
  n2.match <- Check2Gram(x, n2, nrows)
  # merge dfs, outer join (fills zeroes with NAs)
  merge4 <- merge(n5.match, n4.match, by="nextword", all=TRUE)
  merge3 <- merge(merge4, n3.match, by="nextword", all=TRUE)
  merge2 <- merge(merge3, n2.match, by="nextword", all=TRUE)
  rv <- subset(merge2, !is.na(nextword))
  rv <- rv[order(-rv$n5.score, -rv$n4.score, -rv$n3.score, -rv$n2.score), ]
  rv[is.na(rv)] <- 0  # replace all NAs with 0
  return(rv)  # dataframe
}
# test:
CombineNgrams("I'll be there for you, I'd live and I would", 5)

SBScore <- function(x5, x4, x3, x2, alpha=0.4) {
  score <- 0
  if (x5 > 0) {
    score <- x5
  } else if (x4 >= 1) {
    score <- x4 * alpha
  } else if (x3 > 0) {
    score <- x3 * alpha * alpha
  } else if (x2 > 0) {
    score <- x2 * alpha * alpha * alpha
  }
  return(round(score,1))
}

## Implement stupid backoff algo
StupidBackoff <- function(x, alpha=0.4, getNrows, showNresults) {
  if (x == "") {
    return("the")
  }
  # alpha = 0.4 by default
  df <- CombineNgrams(x, getNrows)
  df$overall <- mapply(SBScore, df$n5.score, df$n4.score, df$n3.score, df$n2.score, alpha)
  df <- df[order(-df$overall), ]
  if (df$nextword[1] == "unk") {  # deal with unk
    df <- subset(df, df$nextword != "unk")
  }
  if (showNresults > nrow(df)) {
    showNresults <- nrow(df)
  }
  df$nextword[1:showNresults]
}
# test
StupidBackoff("I like to", 0.4, 10, 5)

