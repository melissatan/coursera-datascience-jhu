# Swiftkey capstone milestone report
Melissa Tan  
Sunday, March 22, 2015  



## Executive summary 

This is a milestone report for a data science capstone project that involves next-word prediction. The goal for the overall project is to write an algorithm that uses n-grams (more on that later) to predict the next word that will appear after a given phrase. For example, "_the cat in the_" might be followed by "_hat_". The algorithm will eventually be made into an app. 

In this report, I perform exploratory analysis of 3 texts -- from blogs, news sites, and Twitter -- that were collected from the web. I'll be using these 3 texts later on to build my word prediction algorithm.

In each of the 3 texts, the average sentence length differed. It was shortest for Twitter, due to Twitter's character limit, and longest for blogs.  
Also, there was a huge number of words that appeared only once. The most common words were the usual suspects, such as "and" and "the".

Note: To keep the report brief and concise, I've put my R code in the Appendix, except where it can't be avoided. I've also tried to explain any technical terms used to non-data scientists.

## Download the datasets

The dataset must be downloaded from a [link given in the course website](https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip). Get the file and unzip. 



The unzipped file contains a directory called `final`, then a subdirectory called `en_US`, which contains the texts that I will analyze. 

There are 3 text files.        
* `en_US.blogs.txt` - text from blog posts        
* `en_US.news.txt` - text from news articles posted online        
* `en_US.twitter.txt` - tweets on Twitter        

## Basic summary of the text files

Word and line count for each of the three datasets: 


              Total word count   Total line count   No. of characters in longest line   Average words per line
-----------  -----------------  -----------------  ----------------------------------  -----------------------
blog.stats            37334114             899288                               40833                       42
news.stats            34365936            1010242                               11384                       34
twit.stats            30359852            2360148                                 173                       13

The Twitter one looks off, since we know that tweets have a max length of 140 characters. Looking through the data, I found that the character count is distorted because of special characters. I will remove them later.

## Extract a random subsample of each text

Since the datasets are too large for my laptop RAM, I wrote a function `SampleTxt()` that extracts a random subsample from each of the source texts. The function essentially flips a coin to decide whether to copy a particular line from the source text to the subsample. At the end, I save each subsample in a `.txt` file in my current working directory, so that I don't have to keep re-generating it.



Since there are so many lines, and my laptop RAM is limited, I reckon it's good enough for now to extract about 2% of the lines from the original source text into each randomized subsample. 



File names for the 3 subsamples I made, each containing 2% of lines in original text:       
* `blog.sample.txt`      
* `news.sample.txt`        
* `twit.sample.txt`        

## Basic summary of subsample

Count words and lines in subsamples to see how they compare with the source text. Although the subsamples have markedly fewer words and lines, the average words per line for each text are roughly similar.


                     Sample word count   Sample line count   No. of characters in longest line   Avg words per line
------------------  ------------------  ------------------  ----------------------------------  -------------------
blog.sample.stats               756614               18281                               12403                   41
news.sample.stats               696074               20580                                1806                   34
twit.sample.stats               614887               47791                                 319                   13

The importing process altered the encoding for special characters, and thus the line length for Twitter text has gotten even more distorted. I will remove the offending special characters in the next step.

## Clean up the subsample text



R has a text mining package called `tm`, which can turn the text into a special object in R called a "corpus", for easier analysis and navigation. We do not need to go into details about this right now, but there is more discussion in the Appendix if you are interested.



First, I turn each of the 3 subsamples into a corpus. Next, I will clean up the three corpora (plural of "corpus") using a function I wrote, `CleanCorpus()`, which performs the following steps:

1. Convert text to lowercase

2. Remove URLs by deleting every string of characters that starts with "http". Also remove all strings that are enclosed within `< >` -- these tend to denote special characters such as emojis.

3. Remove all words containing numbers, e.g. "007", "1st", "b2c", "d20", "24/7". Unfortunately, this means that even legit phrases like "19-year-old" will be deleted as well. I haven't found a way around this issue.

4. Convert all smart quotes, e.g. `'`, to straight quotes e.g. `'`. (The difference may not be obvious depending on what font you are viewing this in, but there is a difference.)

5. Handle punctuation: there's a standard `removePunctuation()` function in the `tm` package, which removes everything found in the `[:punct:]` POSIX class, including hyphens and apostrophes. However, I still want to keep some intra-word punctuation marks, e.g. `mother-in-law`, `isn't`. So I wrote my own functions to remove all punctuation except `-`, `'`, and `*`.

6. Keep intra-word hyphens, and remove other hyphens and dashes. e.g. `my mother-in-law visited--i was absolutely -thrilled-!` gets converted to `my mother-in-law visited i was absolutely thrilled!` 

7. Keep intra-word apostrophes, to distinguish between words such as `its` and `it's`. I would like to keep leading apostrophes e.g. `'Twas` too, but sadly I can't do that because I can't figure out to distinguish between those and the start of a sentence. So my code will leave `can't` unchanged, but will turn `'hello world'` into `hello world`, and similarly will turn `'twas` into `twas`. 

8. Intra-word asterisks: These are often used when people are swearing. Keep them for now, but later in the prediction algorithm I'll remove profanity from the output. Remove all other asterisks.

9. Compress extra whitespace

10. Trim leading and trailing whitespace.



## Visualize word frequency



### Frequency counts and histogram

Make a histogram of the word frequency counts. 

![](milestone_files/figure-html/freqhist-1.png) 

Clearly, in all three cases, there are truckloads of words that only appear once. We can count how many of these there are, and display some random examples.


          No. of words that appear only once   Examples of such words in the text 
--------  -----------------------------------  -----------------------------------
blog      18950                                archeon usayn shivers              
news      19218                                coie midori regionalization        
Twitter   19625                                nny clover rih                     

I can remove rarely seen words such as the ones above, so that the frequency histogram looks less skewed. Here's the new, "dense" histograms after removing rare words.

![](milestone_files/figure-html/densehist-1.png) 

The histogram for the dense Twitter TDM looks like that because after removing all the rare words, we were only left with one word: "the". So we have to be careful when removing sparse terms.

### Plans for the eventual app and algorithm

To make the algorithm into an app, I need to reduce the size of the data such that they can be stored easily on a server. I intend to shrink the TDM by replacing all rare words with "UNK", to denote an "unknown" word, which will make the TDM less sparse. I will treat "UNK" as a term to be factored into the prediction, just like all the other words in the corpus. I do not plan to correct for typos, since I assume that they will be removed during the "UNK" replacements.

My plan for the algorithm is to create trigram, bigram and unigram TDMs for each corpus. 

* When presented with a phrase, I will first check the trigram TDM to see what is the most likely word that comes after the final three words in the phrase. 

* If I don't get any probable answer, I'll check the bigram TDM to see the most likely word that follows after the final two words in the phrase. 

* And if that still doesn't give me a likely candidate, I'll just use the unigram TDM to predict the next word based on the most common single word in the corpus.

* The above sequence of steps is commonly referred to as a "back off" procedure.

## End of report (see Appendix for code chunks)

********

## Appendix

After all the cleaning, the sample lines look different. Compare the raw versions and cleaned versions, by printing out a sample line from each corpus before and after. I've arbitrarily chosen the 7th line.


```r
k <- 7  # display 7th line of corpus
inspect(blog.corpus.raw[k])  # before cleaning
```

```
## <<VCorpus (documents: 1, metadata (corpus/indexed): 0/0)>>
## 
## [[1]]
## <<PlainTextDocument (metadata: 7)>>
## Went to Di's big 50 Birthday bash and even the dull weather didn't stop us having a great time....food from her youth, plenty of drink, playing on the Xbox and a tune on the sax what more could a birthday need!.... Oh good chums.... SORTED.
```

```r
inspect(blog.corpus[k])      # after cleaning
```

```
## <<VCorpus (documents: 1, metadata (corpus/indexed): 0/0)>>
## 
## [[1]]
## <<PlainTextDocument (metadata: 7)>>
## went to di's big birthday bash and even the dull weather didn't stop us having a great time food from her youth plenty of drink playing on the xbox and a tune on the sax what more could a birthday need oh good chums sorted
```

```r
inspect(news.corpus.raw[k])  # before cleaning
```

```
## <<VCorpus (documents: 1, metadata (corpus/indexed): 0/0)>>
## 
## [[1]]
## <<PlainTextDocument (metadata: 7)>>
## Jeremy Castro: 6-foot-1, 240 pound defensive end from Murrieta (Vista Murrieta), Calif.. Ranked as the No. 18 defensive end in the country, Castro originally committed to Washington but switched his pledge after his official visit to Oregon in October. Castro plans to take official visits to LSU and Oklahoma but indicated he will not switch his pledge from the Ducks.
```

```r
inspect(news.corpus[k])      # after cleaning
```

```
## <<VCorpus (documents: 1, metadata (corpus/indexed): 0/0)>>
## 
## [[1]]
## <<PlainTextDocument (metadata: 7)>>
## jeremy castro pound defensive end from murrieta vista murrieta calif ranked as the no defensive end in the country castro originally committed to washington but switched his pledge after his official visit to oregon in october castro plans to take official visits to lsu and oklahoma but indicated he will not switch his pledge from the ducks
```

```r
inspect(twit.corpus.raw[k])  # before cleaning
```

```
## <<VCorpus (documents: 1, metadata (corpus/indexed): 0/0)>>
## 
## [[1]]
## <<PlainTextDocument (metadata: 7)>>
## Missing a very important page from my booking notebook...this isnt good.
```

```r
inspect(twit.corpus[k])      # after cleaning
```

```
## <<VCorpus (documents: 1, metadata (corpus/indexed): 0/0)>>
## 
## [[1]]
## <<PlainTextDocument (metadata: 7)>>
## missing a very important page from my booking notebook this isnt good
```

### Navigating a TDM

To find word frequencies, we can use the `tm` package. The very first thing we need to do is turn the corpus into something called a "term-document matrix" (TDM for short). A TDM is basically a matrix that displays the frequency of words found in a collection of documents (source: [Wikipedia](http://en.wikipedia.org/wiki/Document-term_matrix)). The rows correspond to each word, and the columns correspond to each document. (A document-term matrix has it the other way round, and is simply the transpose of the TDM.) 

For our TDM, note that each line in the blog, news, and Twitter subsamples is considered one document by itself. 

When talking about TDMs, there is an important indicator called "sparsity", which essentially gauges how many zeroes there are in the matrix. A sparse matrix is a matrix with a high percentage of zeroes. The subsample TDMs have extremely high sparsity, at nearly 100%.

To illustrate how to navigate a term-document matrix, let's look at an example. Let's search for the word "winter" in the blog subsample text, plus the next 4 words alphabetically. And let's restrict this to the first 10 lines. We see that in the first 10 lines of the blog subsample text, it's all zeroes, meaning that there are no mentions of "winter" at all.


```
## <<TermDocumentMatrix (terms: 6, documents: 10)>>
## Non-/sparse entries: 0/60
## Sparsity           : 100%
## Maximal term length: 13
## Weighting          : term frequency (tf)
## 
##                Docs
## Terms           1 2 3 4 5 6 7 8 9 10
##   winter        0 0 0 0 0 0 0 0 0  0
##   winter's      0 0 0 0 0 0 0 0 0  0
##   wintercoat    0 0 0 0 0 0 0 0 0  0
##   winterkoninck 0 0 0 0 0 0 0 0 0  0
##   winterland    0 0 0 0 0 0 0 0 0  0
##   winters       0 0 0 0 0 0 0 0 0  0
```

For a much more common word, "and", the situation is different. Again, let's look in the blog subsample. The 3rd line of the text (see 3rd column) contains 8 "and"s, the 4th line contains 3 "and"s, and so on.


```
## <<TermDocumentMatrix (terms: 6, documents: 10)>>
## Non-/sparse entries: 6/54
## Sparsity           : 90%
## Maximal term length: 8
## Weighting          : term frequency (tf)
## 
##           Docs
## Terms      1 2 3 4 5 6 7 8 9 10
##   and      0 0 8 3 0 1 2 0 2  9
##   anda     0 0 0 0 0 0 0 0 0  0
##   andd     0 0 0 0 0 0 0 0 0  0
##   ande     0 0 0 0 0 0 0 0 0  0
##   anders   0 0 0 0 0 0 0 0 0  0
##   anderson 0 0 0 0 0 0 0 0 0  0
```

We can see that the word "and" does appear several times within the first 10 lines of the blog subsample text.
### Find the most frequent words

### Frequent words from dense TDM

We can also pluck out the most frequent words from the dense TDM. Below, I show the words that appear at least 1000 times in the blog text.


```r
findFreqTerms(blog.tdm.dense, lowfreq=1000, highfreq=Inf)  # frequent words in blogs
```

```
## [1] "and"  "for"  "that" "the"  "this" "with"
```

```r
findFreqTerms(news.tdm.dense, lowfreq=1000, highfreq=Inf)  # frequent words in news articles
```

```
## [1] "and"  "for"  "said" "that" "the"  "with"
```

```r
findFreqTerms(twit.tdm.dense, lowfreq=1000, highfreq=Inf)  # frequent words in tweets
```

```
## [1] "the"
```

As expected, these are very common words. If we want to, it's possible to remove common words from the corpus. I haven't done that because it may hinder the next-word prediction algorithm.

### Word associations

We can find out which words are associated with which in the original TDM. Example: "snow". (I'm looking in the original TDM because I tried to look for this word in the dense TDM and got 0 results.)


```r
snowwords <- findAssocs(blog.tdm, "snow", 0.2)  # min correlation = 0.2
snowwords
```

```
##             snow
## yaktrax     0.49
## slush       0.45
## securely    0.35
## slope       0.35
## newlyweds   0.30
## reawakening 0.30
## saturates   0.30
## coils       0.28
## fluke       0.28
## grip        0.21
## stimulates  0.21
## tundra      0.21
## downward    0.20
## pleasantly  0.20
```

### Bigrams

We can inspect an arbitrary portion from each of the bigrams we made.


```r
inspect(blog.tdm2[100:110, 1:10])  # blog bigram: rows 100-110, cols 1-10
```

```
## <<TermDocumentMatrix (terms: 11, documents: 10)>>
## Non-/sparse entries: 0/110
## Sparsity           : 100%
## Maximal term length: 11
## Weighting          : term frequency (tf)
## 
##              Docs
## Terms         1 2 3 4 5 6 7 8 9 10
##   a beach     0 0 0 0 0 0 0 0 0  0
##   a beak      0 0 0 0 0 0 0 0 0  0
##   a beamish   0 0 0 0 0 0 0 0 0  0
##   a bear      0 0 0 0 0 0 0 0 0  0
##   a beast     0 0 0 0 0 0 0 0 0  0
##   a beat      0 0 0 0 0 0 0 0 0  0
##   a beating   0 0 0 0 0 0 0 0 0  0
##   a beatle    0 0 0 0 0 0 0 0 0  0
##   a beau      0 0 0 0 0 0 0 0 0  0
##   a beautiful 0 0 0 0 0 0 0 0 0  0
##   a bed       0 0 0 0 0 0 0 0 0  0
```

```r
inspect(news.tdm2[100:110, 1:10])  # news bigram: rows 100-110, cols 1-10
```

```
## <<TermDocumentMatrix (terms: 11, documents: 10)>>
## Non-/sparse entries: 0/110
## Sparsity           : 100%
## Maximal term length: 13
## Weighting          : term frequency (tf)
## 
##                Docs
## Terms           1 2 3 4 5 6 7 8 9 10
##   a basic       0 0 0 0 0 0 0 0 0  0
##   a basket      0 0 0 0 0 0 0 0 0  0
##   a basketball  0 0 0 0 0 0 0 0 0  0
##   a bastion     0 0 0 0 0 0 0 0 0  0
##   a bat         0 0 0 0 0 0 0 0 0  0
##   a bathroom    0 0 0 0 0 0 0 0 0  0
##   a batter      0 0 0 0 0 0 0 0 0  0
##   a battery     0 0 0 0 0 0 0 0 0  0
##   a batting     0 0 0 0 0 0 0 0 0  0
##   a battle      0 0 0 0 0 0 0 0 0  0
##   a battlefield 0 0 0 0 0 0 0 0 0  0
```

```r
inspect(twit.tdm2[100:110, 1:10])  # Twitter bigram: rows 100-110, cols 1-10
```

```
## <<TermDocumentMatrix (terms: 11, documents: 10)>>
## Non-/sparse entries: 0/110
## Sparsity           : 100%
## Maximal term length: 13
## Weighting          : term frequency (tf)
## 
##                Docs
## Terms           1 2 3 4 5 6 7 8 9 10
##   a beat        0 0 0 0 0 0 0 0 0  0
##   a beautifoul  0 0 0 0 0 0 0 0 0  0
##   a beautiful   0 0 0 0 0 0 0 0 0  0
##   a beauty      0 0 0 0 0 0 0 0 0  0
##   a becoming    0 0 0 0 0 0 0 0 0  0
##   a bed         0 0 0 0 0 0 0 0 0  0
##   a bee         0 0 0 0 0 0 0 0 0  0
##   a beep        0 0 0 0 0 0 0 0 0  0
##   a beer        0 0 0 0 0 0 0 0 0  0
##   a beermeister 0 0 0 0 0 0 0 0 0  0
##   a before      0 0 0 0 0 0 0 0 0  0
```

The above extracts of the bigram TDMs seem to look like they come from regular English text, though they do contain some typos. 

### How frequently do phrases appear? 

We can find out how frequently certain phrases appear. Such phrases can be thought of as a collection of N words. These are called n-grams, for a given value of n. Two-word n-grams (e.g. "cat in") are called bigrams, three-word n-grams (e.g. "cat in the") are trigrams, etc. Using the `RWeka` package in R, I write a function `BigramTDM()` that turns a corpus into a bigram TDM.



The TDMs that we created at first are _unigram_ TDMs (e.g. "cat"), so we already have that to work with. Let's also make bigram TDMs for each of the subsamples, from the cleaned corpora. We can extend that to trigrams later.



### Other code chunks used in report:

#### Download zip file

```r
if (!file.exists("../final")) {  # unzip into parent directory
  fileUrl <- "https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip"
  download.file(fileUrl, destfile = "../swiftkey.zip")
  unzip("../swiftkey.zip")
}
```

#### Word and line counts for datasets

```r
orig.wd <- getwd()
setwd("../final/en_US")
numwords <- system("wc -w *.txt", intern=TRUE)  # intern=TRUE to return output  
numlines <- system("wc -l *.txt", intern=TRUE)
longest <- system("wc -L *.txt", intern=TRUE)
setwd(orig.wd)  # return to original working dir, ie. the parent of /final

# number of words for each dataset
blog.numwords <- as.numeric(gsub('[^0-9]', '', numwords[1]))
news.numwords <- as.numeric(gsub('[^0-9]', '', numwords[2]))
twit.numwords <- as.numeric(gsub('[^0-9]', '', numwords[3]))
# number of lines for each dataset
blog.numlines <- as.numeric(gsub('[^0-9]', '', numlines[1]))
news.numlines <- as.numeric(gsub('[^0-9]', '', numlines[2]))
twit.numlines <- as.numeric(gsub('[^0-9]', '', numlines[3]))
# length of longest line for each dataset
blog.longest  <- as.numeric(gsub('[^0-9]', '', longest[1]))
news.longest  <- as.numeric(gsub('[^0-9]', '', longest[2]))
twit.longest  <- as.numeric(gsub('[^0-9]', '', longest[3]))

# create and display summary table
blog.stats <- c(blog.numwords, blog.numlines, blog.longest,
                round(blog.numwords/blog.numlines))
news.stats <- c(news.numwords, news.numlines, news.longest,
                round(news.numwords/news.numlines))
twit.stats <- c(twit.numwords, twit.numlines, twit.longest, 
                round(twit.numwords/twit.numlines))  
data.stats <- data.frame(rbind(blog.stats, news.stats, twit.stats))
names(data.stats) <- c("Total word count", 
                       "Total line count", 
                       "No. of characters in longest line",
                       "Average words per line")
kable(data.stats)  # display the above in table format
```

#### Read in the subsamples into R

```r
blog.mini <- readLines("./blog.sample.txt")  # imports txt as character vector
news.mini <- readLines("./news.sample.txt")
twit.mini <- readLines("./twit.sample.txt")
```

#### Function to extract subsamples from source text

```r
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
      return()  
    }  
    # while not end of file, write out the selected line to file
    if (in.sample[i] == 1) {
      writeLines(currLine, conn.out)
      num.out <- num.out + 1
    }
  }
}
```

#### Extract subsamples from source text

```r
datalist <- c("../final/en_US/en_US.blogs.txt",
              "../final/en_US/en_US.news.txt",
              "../final/en_US/en_US.twitter.txt")
mypercent <- 0.02
myseed <- 60637
if (!file.exists("./blog.sample.txt")) {
  SampleTxt(datalist[1], "blog.sample.txt", myseed, blog.numlines, mypercent, "r")
}
if (!file.exists("./news.sample.txt")) {
  # must use readmode "rb" here, otherwise it breaks on a special char
  SampleTxt(datalist[2], "news.sample.txt", myseed, news.numlines, mypercent, "rb")
}
if (!file.exists("./twit.sample.txt")) {
  SampleTxt(datalist[3], "twit.sample.txt", myseed, twit.numlines, mypercent, "r")
}
```

#### Display word and line summary for subsamples

```r
sample.numwords <- system("wc -w *.sample.txt", intern=TRUE)  
sample.numlines <- system("wc -l *.sample.txt", intern=TRUE)
sample.longest <- system("wc -L *.sample.txt", intern=TRUE)

# number of words for each dataset
blog.sample.numwords <- as.numeric(gsub('[^0-9]', '', sample.numwords[1]))
news.sample.numwords <- as.numeric(gsub('[^0-9]', '', sample.numwords[2]))
twit.sample.numwords <- as.numeric(gsub('[^0-9]', '', sample.numwords[3]))
# number of lines for each dataset
blog.sample.numlines <- as.numeric(gsub('[^0-9]', '', sample.numlines[1]))
news.sample.numlines <- as.numeric(gsub('[^0-9]', '', sample.numlines[2]))
twit.sample.numlines <- as.numeric(gsub('[^0-9]', '', sample.numlines[3]))
# length of longest line for each dataset
blog.sample.longest  <- as.numeric(gsub('[^0-9]', '',  sample.longest[1]))
news.sample.longest  <- as.numeric(gsub('[^0-9]', '',  sample.longest[2]))
twit.sample.longest  <- as.numeric(gsub('[^0-9]', '',  sample.longest[3]))

# create and display summary table
blog.sample.stats <- c(blog.sample.numwords, blog.sample.numlines, blog.sample.longest,
                      round(blog.sample.numwords/blog.sample.numlines))
news.sample.stats <- c(news.sample.numwords, news.sample.numlines, news.sample.longest,
                      round(news.sample.numwords/news.sample.numlines))
twit.sample.stats <- c(twit.sample.numwords, twit.sample.numlines, twit.sample.longest,
                      round(twit.sample.numwords/twit.sample.numlines))  
sample.stats <- data.frame(rbind(blog.sample.stats, 
                                 news.sample.stats, 
                                 twit.sample.stats))
names(sample.stats) <- c("Sample word count", 
                       "Sample line count", 
                       "No. of characters in longest line", 
                       "Avg words per line")
kable(sample.stats)  # display the above in table format
```

#### Turn the subsample text into corpus object

```r
library(tm)
# build a corpus, from a character vector
blog.corpus.raw <- Corpus(VectorSource(blog.mini))
news.corpus.raw <- Corpus(VectorSource(news.mini))
twit.corpus.raw <- Corpus(VectorSource(twit.mini))
```

#### Function to clean corpus, and perform the cleaning

```r
CleanCorpus <- function(my.corpus) {  # input should be a Corpus object
  # 1. convert text to lowercase
  my.corpus <- tm_map(my.corpus, content_transformer(tolower))
  # 2. remove URLs within string and at end of string
  removeURL <- function(x) {
    x <- gsub("http.*?( |$)", "", x)
    gsub("<.+?>"," ",x)
  }
  my.corpus <- tm_map(my.corpus, content_transformer(removeURL))
  # 3. remove any word containing numbers
  myRemoveNumbers <- function(x) {
    gsub("\\S*[0-9]+\\S*", " ", x)
  }
  my.corpus <- tm_map(my.corpus, content_transformer(myRemoveNumbers))
  # 4. convert smart single quotes to straight single quotes
  mySingleQuote <- function(x) {
    gsub("[\x82\x91\x92]", "'", x)  # ANSI version, not Unicode version
  }
  my.corpus <- tm_map(my.corpus, content_transformer(mySingleQuote))
  # 5. custom function to remove most punctuation
  myRemovePunctuation <- function(x) {
    # replace everything that isn't alphanumeric, space, ', -, *
    gsub("[^[:alnum:][:space:]'-*]", " ", x)
  }
  my.corpus <- tm_map(my.corpus, content_transformer(myRemovePunctuation))
  # 6. deal with dashes, apostrophes, asterisks within words
  myDashApos <- function(x) {
    x <- gsub("--+", " ", x)
    gsub("(\\w['-*]\\w)|[[:punct:]]", "\\1", x, perl=TRUE)    
  }
  my.corpus <- tm_map(my.corpus, content_transformer(myDashApos))

  # remove stopwords - optional
  # my.corpus <- tm_map(my.corpus, removeWords, stopwords("english"))
  
  # 7. strip extra whitespace
  my.corpus <- tm_map(my.corpus, content_transformer(stripWhitespace))
  # 8. trim leading and trailing whitespace
  trim <- function(x) {
    gsub("^\\s+|\\s+$", "", x)
  }
  my.corpus <- tm_map(my.corpus, content_transformer(trim))
  return(my.corpus)
}

# Clean corpus
blog.corpus <- CleanCorpus(blog.corpus.raw)  
news.corpus <- CleanCorpus(news.corpus.raw)
twit.corpus <- CleanCorpus(twit.corpus.raw)
```

#### Create term-document matrix (TDM)

```r
blog.tdm <- TermDocumentMatrix(blog.corpus)
news.tdm <- TermDocumentMatrix(news.corpus)
twit.tdm <- TermDocumentMatrix(twit.corpus)
```

#### Look for "winter" in blog TDM

```r
i <- which(dimnames(blog.tdm)$Terms == "winter")
inspect(blog.tdm[i+(0:5), 1:10])
```

#### Look for "and" in blog TDM

```r
i <- which(dimnames(blog.tdm)$Terms == "and")
inspect(blog.tdm[i+(0:5), 1:10])
```

#### Make frequency histogram before removing sparse terms

(Since my TDM is so sparse and large, I got an error when I tried to count words using `rowSums(as.matrix(TDM))`. To get around that, I use the `row_sums()` function from the `slam` package, which can count the row sums for large, sparse arrays.)


```r
library(slam)
blog.freq <- row_sums(blog.tdm, na.rm=TRUE)
news.freq <- row_sums(news.tdm, na.rm=TRUE)
twit.freq <- row_sums(twit.tdm, na.rm=TRUE)
par(mfrow=c(1,3))  # fit graphs into 1 row, 3 cols
hist(blog.freq)
hist(news.freq)
hist(twit.freq)
```

#### Make table of words that appear only once

```r
blog.once <- findFreqTerms(blog.tdm, lowfreq=0, highfreq=1)
news.once <- findFreqTerms(news.tdm, lowfreq=0, highfreq=1)
twit.once <- findFreqTerms(twit.tdm, lowfreq=0, highfreq=1)
# get number of terms that appear at most one time
num.once <- c(length(blog.once), length(news.once), length(twit.once))
# randomly sample 3 of these words from each TDM
set.seed(773)      
ex.once <- c(paste(sample(blog.once, 3), collapse=" "), 
             paste(sample(news.once, 3), collapse=" "),
             paste(sample(twit.once, 3), collapse=" "))
df.once <- data.frame(cbind(num.once, ex.once))
colnames(df.once) <- c("No. of words that appear only once", 
                        "Examples of such words in the text")
rownames(df.once) <- c("blog", "news", "Twitter")
kable(df.once)
```

#### Make frequency histogram after removing sparse terms 

```r
max.empty <- 0.8  # set max empty space (zeroes) at 80% of matrix
blog.tdm.dense <- removeSparseTerms(blog.tdm, max.empty)
news.tdm.dense <- removeSparseTerms(news.tdm, max.empty)
twit.tdm.dense <- removeSparseTerms(twit.tdm, max.empty)
# make new frequency hists
blog.freq.dense <- row_sums(blog.tdm.dense, na.rm=TRUE)
# rowSums(as.matrix(blog.tdm.dense, na.rm=TRUE))
news.freq.dense <- row_sums(news.tdm.dense, na.rm=TRUE)
twit.freq.dense <- row_sums(twit.tdm.dense, na.rm=TRUE)
par(mfrow=c(1,3))  # fit graphs into 1 row, 3 cols
hist(blog.freq.dense)
hist(news.freq.dense)
hist(twit.freq.dense)
```

####  Create tokenizers to make n-gram TDMs

```r
library(RWeka)

# functions to create n-gram Tokenizer to pass on to TDM constructor
BigramTokenizer <- function(x) {
  NGramTokenizer(x, Weka_control(min=2, max=2))
}
TrigramTokenizer <- function(x) {
  NGramTokenizer(x, Weka_control(min=3, max=3))
}

# functions to construct n-gram TDM
BigramTDM <- function(x) { 
  tdm <- TermDocumentMatrix(x, control=list(tokenize=BigramTokenizer))
  return(tdm)
}
TrigramTDM <- function(x) { 
  tdm <- TermDocumentMatrix(x, control=list(tokenize=TrigramTokenizer))
  return(tdm)
}
```

#### Make n-gram

```r
# blog bigram, trigram
blog.tdm2 <- BigramTDM(blog.corpus)
# blog.tdm3 <- TrigramTDM(blog.corpus)

# news bigram, trigram
news.tdm2 <- BigramTDM(news.corpus)
# news.tdm3 <- TrigramTDM(news.corpus)

# twitter bigram, trigram
twit.tdm2 <- BigramTDM(twit.corpus)
# twit.tdm3 <- TrigramTDM(twit.corpus)
```

End of appendix
