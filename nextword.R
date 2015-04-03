## Predict next word based on previously computed ngram csvs

## ----------
# This script assumes that I have CSV files containing n-grams for n=1:4.
# The structure of the resulting dataframe should be:
# <freq> <word1> <word2> <word3> <word4> for the 4-gram, and so on.

# The script takes a sentence, matches the last 4/3/2/1 words of the
# sentence to the appropriate ngrams, and predicts the most likely
# next word based on a score derived from word frequencies.
## ----------

## Function that takes a phrase and returns last n words, in a char vec
GetLastWords <- function(x, n) {  # x must be string
  words <- unlist(strsplit(x, " "))  # split up string by space
  len <- length(words)
  if (n > len) {
    n == len
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

## Function that checks the Quadgram
  # initialize score df
  scoredf <- data.frame(nextword=NA,score=0)
  weights <- [1, 5, 10, 20]
  # look in quadgram df
  match.idx <- grep(last3, n4$term)  # gives vector of indices
  if (any(match.idx)) {  # if there are any hits, add to score table
    match.row <- n4[match.idx, ]  # get match subset rows
    match.row <- match.row[order(-count, term), ]  # sort by count
    # for each row, get last word, add to score table
    for (each in match.row) {
      lastword <- gsub(".* ", "", each$term)
      wordscore <- weights[4] * each$count
      scoredf <- rbind(scoredf, c(lastword, wordscore))
    }
    scoredf <-
      last2 <- paste(words[len-1], words[len])
    last1 <- words[len]
  }


