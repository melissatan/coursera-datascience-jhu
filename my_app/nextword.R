## Predict next word based on previously computed ngram csvs

## ----------
# This script assumes that I have CSV files containing n-grams for n=2:5.
# The structure of the resulting dataframe should be:
# <freq> <word1> <word2> <word3> for the 3-gram, and so on.

# The script takes a sentence, match the last 5/4/3/2 words of the
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
if (!exists("profanities")) {
  profanities <- readLines("profanity.txt", encoding="UTF-8")
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

## Function that returns the last N words of cleaned phrase, in a char vec
GetLastWords <- function(x, n) {
  x <- CleanPhrase(x)
  words <- unlist(strsplit(x, " "))
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

## Functions to check n-gram for x. Returns df with cols: [nextword] [MLE]
Check5Gram <- function(x, n5, getNrows) {
  words <- GetLastWords(x, 4)
  match <- subset(n5, word1 == words[1] & word2 == words[2]
                    & word3 == words[3] & word4 == words[4])
  match <- subset(match, select=c(word5, freq))
  match <- match[order(-match$freq), ]
  sumfreq <- sum(match$freq)
  match$freq <- round(match$freq / sumfreq * 100)
  colnames(match) <- c("nextword","n5.MLE")
  if (nrow(match) < getNrows) {
    getNrows <- nrow(match)
  }
  match[1:getNrows, ]
}
Check4Gram <- function(x, n4, getNrows) {
  words <- GetLastWords(x, 3)
  match <- subset(n4, word1 == words[1] & word2 == words[2]
                    & word3 == words[3])
  match <- subset(match, select=c(word4, freq))
  match <- match[order(-match$freq), ]
  sumfreq <- sum(match$freq)
  match$freq <- round(match$freq / sumfreq * 100)
  colnames(match) <- c("nextword","n4.MLE")
  if (nrow(match) < getNrows) {
    getNrows <- nrow(match)
  }
  match[1:getNrows, ]
}
Check3Gram <- function(x, n3, getNrows) {
  words <- GetLastWords(x, 2)
  match <- subset(n3, word1 == words[1] & word2 == words[2])
  match <- subset(match, select=c(word3, freq))
  match <- match[order(-match$freq), ]
  sumfreq <- sum(match$freq)
  match$freq <- round(match$freq / sumfreq * 100)
  colnames(match) <- c("nextword","n3.MLE")
  if (nrow(match) < getNrows) {
    getNrows <- nrow(match)
  }
  match[1:getNrows, ]
}
Check2Gram <- function(x, n2, getNrows) {  # n4 df should already exist
  words <- GetLastWords(x, 1)
  match <- subset(n2, word1 == words[1])
  match <- subset(match, select=c(word2, freq))
  match <- match[order(-match$freq), ]
  sumfreq <- sum(match$freq)
  match$freq <- round(match$freq / sumfreq * 100)
  colnames(match) <- c("nextword","n2.MLE")
  if (nrow(match) < getNrows) {
    getNrows <- nrow(match)
  }
  match[1:getNrows, ]
}

## Function that computes stupid backoff score
SBScore <- function(alpha=0.4, x5, x4, x3, x2) {
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

## Function that combines the nextword matches into one dataframe
ScoreNgrams <- function(x, nrows=20) {
  # get dfs from parent env
  n5.match <- Check5Gram(x, n5, nrows)
  n4.match <- Check4Gram(x, n4, nrows)
  n3.match <- Check3Gram(x, n3, nrows)
  n2.match <- Check2Gram(x, n2, nrows)
  # merge dfs, by outer join (fills zeroes with NAs)
  merge5n4 <- merge(n5.match, n4.match, by="nextword", all=TRUE)
  merge4n3 <- merge(merge5n4, n3.match, by="nextword", all=TRUE)
  merge3n2 <- merge(merge4n3, n2.match, by="nextword", all=TRUE)
  df <- subset(merge3n2, !is.na(nextword))  # rm any zero-match results
  if (nrow(df) > 0) {
    df <- df[order(-df$n5.MLE, -df$n4.MLE, -df$n3.MLE, -df$n2.MLE), ]
    df[is.na(df)] <- 0  # replace all NAs with 0
    # add in scores
    df$score <- mapply(SBScore, alpha=0.4, df$n5.MLE, df$n4.MLE,
                         df$n3.MLE, df$n2.MLE)
    df <- df[order(-df$score), ]
  }
  return(df)  # dataframe
}

## Implement stupid backoff algo
StupidBackoff <- function(x, alpha=0.4, getNrows=20, showNresults=1,
                          removeProfanity=TRUE) {
  nextword <- ""
  if (x == "") {
    return("the")
  }
  df <- ScoreNgrams(x, getNrows)
  if (nrow(df) == 0) {
    return("and")
  }
  df <- df[df$nextword != "unk", ]  # remove unk
  if (showNresults > nrow(df)) {
    showNresults <- nrow(df)
  }
  if (showNresults == 1) {
    # check if top overall score is shared by multiple candidates
    topwords <- df[df$score == max(df$score), ]$nextword
    # if multiple candidates, randomly select one
    nextword <- sample(topwords, 1)
  } else {
    nextword <- df$nextword[1:showNresults]
  }
  if (removeProfanity) {
    if (nextword %in% profanities) {
      nextword <- "#@?!"
    }
  }
  return(nextword)
}

