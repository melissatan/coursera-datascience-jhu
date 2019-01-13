Course project for Coursera module "Getting and Cleaning Data"
==============
#### About the data used:
This project uses a data set collected by the University of California, Irvine (UCI).  
The dataset, called "Human Activity Recognitition" (HAR), was collected from the accelerometers inside the Samsung Galaxy S smartphone.  
The dataset was built from the recordings of 30 subjects performing 6 activities of daily living, while carrying a waist-mounted smartphone with embedded inertial sensors.

#### Project instructions:
The purpose of this project is to demonstrate ability to collect, work with, and clean a data set. 
The goal is to prepare tidy data that can be used for later analysis.

This will be done by an R script, run_analysis.R, that does the following:  
1. Merges the training and the test sets to create one data set.  
2. Extracts only the measurements on the mean and standard deviation for each measurement.  
3. Uses descriptive activity names to name the activities in the data set.  
4. Appropriately labels the data set with descriptive variable names.  
5. Creates a second, independent tidy data set with the average of each variable for each activity and each subject.
***
#### This README will explain what I wrote in run_analysis.R for each of the five steps.
***
### Preparation part 1: Download the data required
The dataset for the course project was provided at [https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip]
(https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip) by the instructor.

First, check to see if the data is already in the working directory. If it isn't, the script will download it.
 
Downloads the zip to the current working directory and unzip.  
We know that the unzipped folder is automatically named `UCI HAR Dataset`.

	if (!file.exists("./UCI HAR Dataset")) {
		fileUrl <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
		download.file(fileUrl, destfile = "./data.zip")
		unzip("./data.zip")
		file.remove("./data.zip")
	}

Remove the zip after we're done unzipping, to save space in memory. 

***
### Preparation part 2: Read in the data
There are two sub-directories inside the `UCI HAR Dataset` directory: `train` and `test`.

Inside them are .txt files with data on the:
* `subject`, numbered 1 to 30,
* `y` which is the activity e.g. "laying", "sitting" (activity labels are stored in `activity_labels.txt`)
* `X` which contains the feature measurements (feature measurement names are stored in `features.txt`)

The `features.txt` file will be used in *Step 2* and `activity_labels.txt` will be used in *Step 3*.

Since these are all .txt files, we read them in using `read.table()`.

Read in training data for `X`, `y`, `subject`:

	trainx <- read.table("./UCI HAR Dataset/train/X_train.txt", header = FALSE, stringsAsFactors = FALSE)
	trainy <- read.table("./UCI HAR Dataset/train/y_train.txt", header = FALSE, stringsAsFactors = FALSE)
	trainsubject <- read.table("./UCI HAR Dataset/train/subject_train.txt", header = FALSE, stringsAsFactors = FALSE)
					
Read in test data for `X`, `y`, `subject`:

	testx <- read.table("./UCI HAR Dataset/test/X_test.txt", header = FALSE, stringsAsFactors = FALSE)
	testy <- read.table("./UCI HAR Dataset/test/y_test.txt", header = FALSE, stringsAsFactors = FALSE)
	testsubject <- read.table("./UCI HAR Dataset/test/subject_test.txt", header = FALSE, stringsAsFactors = FALSE)					 

			   

***
### Step 1. Merge training and test sets to create one data set

We know that the data can be merged together according to this structure kindly provided in the course discussion forum 
by Mr. David Hood, a community TA in the course. 
[See David's diagram here](https://coursera-forum-screenshots.s3.amazonaws.com/ab/a2776024af11e4a69d5576f8bc8459/Slide2.png)

Accordingly, we merge together the training data and the test data column-wise.  
The `y` and `subject` data are at the right-hand side of the dataframe right now, 
but we will rearrange the columns later at the end.

	train <- cbind(trainx, trainy, trainsubject)
	test <- cbind(testx, testy, testsubject)

Then we combine the `train` and `test` data by rows into one large dataframe.

	df <- rbind(train, test)

***
### Step 2. Extract only the measurements on the mean and standard deviation for each measurement

The names of all the feature measurements can be found in `features.txt`. 
We use `grep` on the contents of `features.txt` to find the indexes of those names containing:  
* "mean()", denoting mean, OR
* "std()", denoting standard deviation.

We don't want colnames containing "meanFreq()", as [instructed by course TA, Trent Baur]
(https://class.coursera.org/getdata-007/forum/thread?thread_id=71#post-208) in the forum.

Read in the measurement features data from `features.txt`

	features <- read.table('./UCI Har Dataset/features.txt', header = FALSE, stringsAsFactors = FALSE,
							sep = " ")

The colname strings for the `X` data will be in the 2nd column of `features`, so we extract it to `xnames` vector

	# each value in features col 2 corresponds to a col name for X data.
	xnames <- features[,2]
	
Grep to find the index of the target cols; NB. have to escape special chars "(" and ")"

	targetcols <- grep("mean\\(\\)|std\\(\\)", xnames)

Now that we have the correct indexes, extract the relevant mean() and std() columns from dataframe.  
Also get the Activity column (col 562) and the Subject column (col 563).

	df_mean_sd <- df[,c(targetcols, 562, 563)]
	
***
### Step 3. Use descriptive activity names to name the activities in the data set

Read in the activity labels data from `activity_labels.txt`.  
(N.B. read.table() applied to this will give two columns. The 1st column is a number (1-6).  
The 2nd column is the activity label string corresponding to that number.

	actlab <- read.table('./UCI HAR Dataset/activity_labels.txt', header = FALSE, stringsAsFactors = FALSE)

We extract the 2nd column to `actlab` vector, converted to lowercase for readability.

	actlab <- tolower(actlab[,2])
	
Replace each activity number (`actnum`) in column 67 of `df_mean_sd` with the right string label from `actlab`, 
so that each activity will be represented in the dataframe with a descriptive string rather than a number.
	
	for (i in 1:nrow(df_mean_sd)) {
		actnum <- as.numeric(df_mean_sd[i,67])
		df_mean_sd[i,67] <- actlab[actnum]
	}
	

***
### Step 4. Appropriately label data set with descriptive variable names. 
(This part is slightly longer, so please bear with me!)

I interpreted this step as requiring us to label the unnamed `X` data columns with their appropriate `feature` names.

To start off doing that, we deal with the `X` data in the first 66 cols of `df_mean_sd`.

Recall that the `xnames` vector from *Step 2* contains all the column names for the `X` data. 

Extract the relevant colnames with "mean" and "sd" from `xnames`, using the `targetcols` indexes that we `grep`ped earlier.

	xnames_mean_sd <- xnames[targetcols] # xnames_mean_sd has 66 cols

The column names stored in `xnames_mean_sd` are all Feature names in a certain format, such as "tBodyAcc-mean()-X" and "tGravityAcc-std()-Z".

Now, we loop through all of the Feature names, replacing the abbreviations in each with their fully spelled-out versions 
so that it is easier for the viewer to know what each Feature name is. 

For example, the short-form "tBodyAcc-mean()-X" will be turned into long-form "Mean Body Acceleration along X axis (time)".

NB. This step assumes that the viewer has some domain knowledge of what those words mean -- it 
would likely be far more cumbersome if we have to translate the short-form name to, for instance, 
"The average acceleration recorded that was due to the body moving along the X axis of the smartphone, in time domain", 
though that certainly could be done.

We will construct the long-form name using a list of 7 name components that we will paste together later. 
A simple substitution using `gsub()` will not work, since we want to alter the word arrangements slightly, 
e.g. moving "mean" from the back to place it at the front of the new name.

	nameparts <- list(meansd = "", jerk = "", mag = "", bodygrav = "", accgyro = "", axis = "", timefreq = "")

Pre-allocate a vector, `longname`, to hold the loop's result: a pasted-together long-form Feature name

	xlen <- length(xnames_mean_sd)
	longname <- rep(NA,xlen)

The column names that we are going to alter are stored inside `xnames_mean_sd`.

Begin the loop, which walks from the first to last element of `xnames_mean_sd`.

For each Feature name stored in `xnames_mean_sd`, we look at the existing short-form name string and 
modify the corresponding item in `nameparts` accordingly, to match. There are 7 elements inside `nameparts` to be filled in.

	for (i in 1:xlen) {
		shortname <- xnames_mean_sd[i]

1. If short-form name string contains "mean", we know that it does not contain "std".  
Here we use the ternary, `ifelse`, for convenience.

		nameparts$meansd <- ifelse(test = grepl("mean", shortname),
                               yes = "Mean ",
                               no = "Standard Deviation of ")
							   
2. Short-form name either contains "jerk" or does not.

		nameparts$jerk <- ifelse(test = grepl("Jerk", shortname),
                               yes = "Jerk ",
                               no = "")

3. Either contains "Mag" or not.

		nameparts$mag <- ifelse(test = grepl("Mag", shortname),
                           yes = "Magnitude ",
                           no = "")
						   
4. Either contains "Body" XOR (XOR denotes "exclusive or") "Gravity".

		nameparts$bodygrav <- ifelse(test = grepl("Body", shortname),
                                 yes = "Body ",
                                 no = "Gravity ")

5. Either contains "Acc" for acceleration XOR "Gyro" for gyroscope

		nameparts$accgyro <- ifelse(test = grepl("Acc", shortname),
                              yes = "Acceleration ",
                              no = "Gyroscope ")

6. For the X/Y/Z axis component, we check if there is X, Y or Z at the end of string

		if (grepl("X$", shortname)) { nameparts$axis <- "along X axis " }
		else if (grepl("Y$", shortname)) { nameparts$axis <- "along Y axis " }
		else if (grepl("Z$", shortname)) { nameparts$axis <- "along Z axis " }

7. Lastly, we check whether name starts with "t" ie. time domain XOR starts with "f" ie. frequency domain.

		nameparts$timefreq <- ifelse(test = grepl("^t", shortname),
                                 yes = "(Time)",
                                 no = "(Frequency)")

Now that we've got every component, paste all parts together into the corresponding row in `longname` vector, and close the loop.

		longname[i] <- paste0(nameparts$meansd,
                          nameparts$jerk,
                          nameparts$mag,
                          nameparts$bodygrav,
                          nameparts$accgyro,
                          nameparts$axis,
                          nameparts$timefreq)
	}
		
The `longname` vector now contains all the fully spelled-out Feature names. We use it to rename the dataframe columns.

All column names in my script are in lowercase, for consistency and to make it easier for the user.

The first 66 cols of Feature data are renamed according to `longname` values:

	colnames(df_mean_sd)[1:66] <- longname

We label the 67th and 68th cols "activity" and "subject" respectively:

	colnames(df_mean_sd)[67] <- "activity"
	colnames(df_mean_sd)[68] <- "subject"

The dataframe `df_mean_sd` now has more descriptive column labels and more descriptive activity values. 
In the next and final step, we rearrange the columns and tidy up the data.

***
### Step 5. Create a second, independent tidy data set with the average of each variable for each activity and each subject.

According to the TA David's [project FAQ in the forum](https://class.coursera.org/getdata-007/forum/thread?thread_id=49), 
either the wide or narrow form is acceptable. 

Here, I've chosen to do the narrow representation. Libraries I use are `dplyr` and `reshape2`.

	library(dplyr); library(reshape2)
	
Originally, the data was messy because the columns were actually values (e.g. each item of `features`), not variables.

To tidy it up into narrow form, we convert the Feature variable into its own column, using the `reshape2` package's `melt()` function.

First, we reorder the cols for neatness using `dplyr`, so that the dataframe columns read: "Subject | Activity | Feature1...66"

	df_mean_sd <- select(df_mean_sd, subject, activity, 1:66)

Now we melt the dataframe into narrow form using `reshape2` package. Columns will read: "subject | activity | feature | value"

	molten <- melt(df_mean_sd, id = c("subject","activity"),
							   measure = 3:68,
							   variable.name = "feature")

We need to get the *average of each variable for each activity and each subject*, as instructed.  
So we temporarily cast to wide form, because this function conveniently lets us compute the mean values for each Feature.

	castwide <- dcast(molten, subject + activity ~ feature, mean)

Now that the mean values that we wanted have been computed, we can put the data back into narrow form to get our *tidy* result.

	tidy <- melt(castwide, id = c("subject","activity"),
						   measure = 3:68,
						   variable.name = "feature",
						   value.name = "meanvalue")

For neatness, we sort each row by the Subject in ascending order, 
followed by Activity in ascending order and then by Feature in ascending order.

	tidy <- arrange(tidy, subject, activity, feature)
	
We're done tidying up the data! 

Write it to `tidy.txt` as instructed, using `write.table()` with `row,names = FALSE`.

	write.table(tidy, file = "tidy.txt", row.names = FALSE)

The `tidy.txt` file is now in the current working directory.

***
### How to read the tidy result in R

The script will produce a file called `tidy.txt` in the current working directory. To view its contents:

	address <- "https://s3.amazonaws.com/coursera-uploads/user-a0dfb37c6ee127847e6a3549/972585/asst-3/c57556203d8a11e4a70f8f5a029d0153.txt"
	address <- sub("^https", "http", address)
	data <- read.table(url(address), header = TRUE)
	View(data)

Thank you very much for reading this till the end!

#### END README