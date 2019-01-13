## getdata-007 course project: run_analysis
## using UCI dataset on Human Activity Recognition


# if file does not already exist, download file

if (!file.exists("./UCI HAR Dataset")) {
    fileUrl <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
    download.file(fileUrl, destfile = "./data.zip")
    # unzip into working directory
    unzip("./data.zip") # "UCI HAR Dataset" folder into parent dir
    file.remove("./data.zip")
}



## 1. Merge the training and the test sets to create one data set.

# read in training data for x, y, subject
trainx <- read.table("./UCI HAR Dataset/train/X_train.txt",
                    header = FALSE, stringsAsFactors = FALSE)
trainy <- read.table("./UCI HAR Dataset/train/y_train.txt",
                     header = FALSE, stringsAsFactors = FALSE)
trainsubject <- read.table("./UCI HAR Dataset/train/subject_train.txt",
                     header = FALSE, stringsAsFactors = FALSE)

# read in test data for x, y, subject
testx <- read.table("./UCI HAR Dataset/test/X_test.txt",
                    header = FALSE, stringsAsFactors = FALSE)
testy <- read.table("./UCI HAR Dataset/test/y_test.txt",
                    header = FALSE, stringsAsFactors = FALSE)
testsubject <- read.table("./UCI HAR Dataset/test/subject_test.txt",
                          header = FALSE, stringsAsFactors = FALSE)


# bind training data together by col
train <- cbind(trainx, trainy, trainsubject)

# bind test data together by col
test <- cbind(testx, testy, testsubject)

# bind training and test data together by row
df <- rbind(train, test)



## 2. Extract only the measurements on the mean and standard deviation
## for each measurement.

# find columns with colnames containing:
# - 'mean()', denoting mean, or
# - 'std()', denoting standard deviation.
# avoid colnames containing meanFreq(), as instructed by course TA

# variable names are listed in features.txt.
# read them in with sep=" " since format e.g. "1 tBodyAcc-mean()-X"
features <- read.table("./UCI Har Dataset/features.txt",
                       header = FALSE, stringsAsFactors = FALSE,
                       sep = " ")

# each value in features col 2 corresponds to a col name for X data.
xnames <- features[,2]

# grep to get index of the target cols; escape special chars( and )
targetcols <- grep("mean\\(\\)|std\\(\\)", xnames)

# get the mean() and std() columns from dataframe, plus Activity and Subject cols
df_mean_sd <- df[,c(targetcols, 562, 563)]
# the above df has 66 cols + Activity + Subject (will change col order in Step 5)



## 3. Use descriptive activity names to name the activities in the dataset

# read in the activity labels
actlab <- read.table("./UCI HAR Dataset/activity_labels.txt",
                     header = FALSE, stringsAsFactors = FALSE)
# only want the second column containing "WALKING", etc., so that
# actlab[1] gives WALKING, etc. convert to lowercase for readability
actlab <- tolower(actlab[,2])

# replace each activity number, in col 67 of df_mean_sd, with label
for (i in 1:nrow(df_mean_sd)) {
    actnum <- as.numeric(df_mean_sd[i,67])
    df_mean_sd[i,67] <- actlab[actnum]
}



## 4. Appropriately label the data set with descriptive variable names

# to deal with the first 66 cols of x data:
# from the xnames vector we got in Step 2, select mean and sd cols
xnames_mean_sd <- xnames[targetcols] # xnames_mean_sd has 66 cols

# replace the abbreviations in names with fully spelled-out versions
# store each name component in a list to be pasted together later
nameparts <- list(meansd = "",
                  jerk = "",
                  mag = "",
                  bodygrav = "",
                  accgyro = "",
                  axis = "",
                  timefreq = "")

# pre-allocate a vector to hold the pasted-together longname
xlen <- length(xnames_mean_sd)
longname <- rep(NA,xlen)

for (i in 1:xlen) {
    # look at the existing abbreviated name
    shortname <- xnames_mean_sd[i]

    # if string contains mean, it can't contain std
    nameparts$meansd <- ifelse(test = grepl("mean", shortname),
                               yes = "Mean ",
                               no = "Standard Deviation of ")
    # either contains "jerk" or not
    nameparts$jerk <- ifelse(test = grepl("Jerk", shortname),
                               yes = "Jerk ",
                               no = "")
    # either contains "mag" or not
    nameparts$mag <- ifelse(test = grepl("Mag", shortname),
                           yes = "Magnitude ",
                           no = "")
    # either body xor gravity
    nameparts$bodygrav <- ifelse(test = grepl("Body", shortname),
                                 yes = "Body ",
                                 no = "Gravity ")
    # either acceleration xor gyroscope
    nameparts$accgyro <- ifelse(test = grepl("Acc", shortname),
                              yes = "Acceleration ",
                              no = "Gyroscope ")

    # for axis, see if there is X/y/Z at the end
    if (grepl("X$", shortname)) { nameparts$axis <- "along X axis " }
    else if (grepl("Y$", shortname)) { nameparts$axis <- "along Y axis " }
    else if (grepl("Z$", shortname)) { nameparts$axis <- "along Z axis " }

    # either starts with t ie. time, xor starts with f ie. frequency
    nameparts$timefreq <- ifelse(test = grepl("^t", shortname),
                                 yes = "(Time)",
                                 no = "(Frequency)")

    # now paste everything together into row in longname vector
    longname[i] <- paste0(nameparts$meansd,
                          nameparts$jerk,
                          nameparts$mag,
                          nameparts$bodygrav,
                          nameparts$accgyro,
                          nameparts$axis,
                          nameparts$timefreq)
}

# we can now name the first 66 cols according to longname
colnames(df_mean_sd)[1:66] <- longname

# label the 67th and 68th cols "activity" and "subject" respectively
colnames(df_mean_sd)[67] <- "activity"
colnames(df_mean_sd)[68] <- "subject"




## 5. From the data set in step 4, creates a second, independent
# tidy data set with the average of each variable for each
# activity and each subject.

# load required libraries
library(dplyr)
library(reshape2)

# reorder the cols, so it becomes Subject | Activity | Feature1...66
df_mean_sd <- select(df_mean_sd, subject, activity, 1:66)

# convert to narrow form first.
molten <- melt(df_mean_sd, id = c("subject","activity"),
                       measure = 3:68,
                       variable.name = "feature")
# the above looks like: subject | activity | feature | value

# cast back to wide form while computing the mean of value.
castwide <- dcast(molten, subject + activity ~ feature, mean)

# melt it back to narrow, rename last col to show it is mean value
tidy <- melt(castwide, id = c("subject","activity"),
                       measure = 3:68,
                       variable.name = "feature",
                       value.name = "meanvalue")

# using dplyr package, sort rows by Subject then Activity then Feature
tidy <- arrange(tidy, subject, activity, feature)

# as instructed, write to txt with write.table(), row.names = F
write.table(tidy, file = "tidy.txt", row.names = FALSE)
