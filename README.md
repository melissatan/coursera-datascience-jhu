# dscapstone

# coursera data science specialization capstone project

The project is to create a Shiny app that predicts the next word based on a user-input phrase.

## Documentation:

### Rstudio Presenter slide deck

Files found in `my_deck` directory. 

### Shiny app

The Shiny app files (`ui.R`, `server.R`, and `nextword.R` which contains the algo) are in the `my_app` folder in the repo. 

The `nextword.R` script depends on the work done by scripts found in the `helper-scripts` directory.

### Helper scripts

The helper scripts should be run in this order:

1. `setup.R` - Downloads the corpora dataset and randomly samples a subset, to produce training dataset

2. `unk.R` - Cleans up the training dataset e.g. converting to lowercase, removing punctuations except apostrophes, standardizing words such as "e-mail" to "email", etc. Replaces singleton words with placeholder `unk`, and spits out the cleaned training dataset.

3. `ngram.R` - From the cleaned dataset, produces n-grams for n=2, 3, 4, 5. For 3-grams and above, I had to remove all n-grams with frequency == 1, due to memory limitations on my machine. 

4. `mkrdata.R` - Makes the ngram CSV and profanity txt file into a .Rdata object, `ngrams_and_profanities.Rdata`, which will be loaded by the Shiny app.

### Data 

Data is in `my_data` folder. 

This contains the n-gram CSVs produced, together with a profanities list ([source](https://gist.github.com/jamiew/1112488)). 

