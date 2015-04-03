## Predict next word based on the computed ngram csvs

## Function that takes a phrase and looks for it in df
FindPhrase <- function(x) {  # x must be string
  words <- unlist(strsplit(x, " "))  # split string by space
  len <- length(words)
  last3 <- paste0(paste(words[len-2], words[len-1], words[len])," ")
  # init score df
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


