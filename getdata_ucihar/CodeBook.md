Codebook
==============

## Input

### Where the data is from:
This project uses a data set collected by the University of California, Irvine (UCI).

It can be downloaded from the UCI website [here](http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones).

The dataset for this course project was provided by the instructor at [https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip]
(https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip)

After unzipping the downloaded file, there will be a directory called `UCI HAR Dataset` in the working directory.

### What the data contains:
The dataset, called "Human Activity Recognitition" (HAR), was collected from the accelerometers inside the 
Samsung Galaxy S smartphone.

The data was built from the recordings of 30 subjects performing 6 activities of daily living, while carrying 
a waist-mounted smartphone with embedded inertial sensors.  
Sensors included an *accelerometer*, measuring acceleration; and a *gyroscope* measuring rotation.

The 6 activities measured were stored in a `activity_labels.txt` file inside the `UCI HAR Dataset` directory.

They are:
1. WALKING
2. WALKING_UPSTAIRS
3. WALKING_DOWNSTAIRS
4. SITTING
5. STANDING
6. LAYING

The dataset contains 70% training data and 30% test data.

### Data dimensions

#### Rows
* The training data has 7,352 observations.
* The test data has 2,947 observations.
* The total dataset has 10,299 observations, from 30 subjects, over 6 activities.

#### Columns
* 1 Subject column 
	* Subjects are labeled 1 to 30
	* Data stored in `train/subject_train.txt` and 'test/subject_test.txt`)
* 1 Activity column 
	* See above section for the 6 activities recorded 
	* Data stored in `activity_labels.txt`) 
* 561 feature measurements, 
	* These are derived from the raw data signals from the accelerometer and gyroscope 
	embedded inside the phone 
	* Data stored in `train/X_train.txt` and `test/X_test.txt`
	* Values are normalized and bounded within [-1,1]

* * *
## Output 

### Description of output (narrow-form tidy dataset)
The tidy dataset produced by the `run_analysis.R` script in this repo is stored 
as a file called `tidy.txt` in the script user's current working directory.

Originally, the data was messy because the columns were actually values (e.g. each item of `features`), not variables.

To tidy it up into narrow form, we convert the Feature variable -- which had been spread out across the column names -- 
into its own column, named "feature".

#### Outcome of transformation applied to raw data
* The subjects were transformed into a unique ID number (1-50)
	- Placed in a column named "subject"
* Each activity was transformed from an activity ID number (1-6) to one of six string values, shown in the section below.
	- Placed in a column named "activity"
* Each measurement feature name was transformed into a string value
	- Placed in a column called "feature"
* The values of each measurement feature were summarized by taking their _mean_, by activity and subject
	- These are numeric values and are in the range [-1, 1]
	- Placed in a column called "meanvalue"

There is one row for every mean value. 

In other words, each row represents an observation of 1 unique subject doing 1 particular activity, recorded in 1 particular measurement feature, and the mean of all the values that were recorded for that combination.

#### How to read dataset
The resulting dataset has 4 columns as follows (column names are in lowercase for consistency):
* subject
	* There are 30 subjects in the study.
	* Each subject is given an ID number, from 1 to 30.
* activity 
	* Each activity is labelled with 1 of 6 activity values:
		1. "walking" - subject is walking 
		2. "walking_upstairs" - subject is walking upstairs
		3. "walking_downstairs" - subject is walking downstairs
		4. "sitting" - subject is sitting
		5. "standing" - subject is standing up
		6. "laying" - subject is lying down
	* Activity values are arranged in alphabetical order in the tidy data set.
* feature
	* Each feature measurement is labelled with a descriptive name.
	* Examples of the descriptive names include:
		* "Mean Body Acceleration along X axis (Time)"
		* "Standard Deviation of Body Acceleration along Z axis (Frequency)"
* meanvalue
	* the average value of each feature, by *subject* and *activity*.
	
### How to read output into R

The script will produce a file called `tidy.txt` in the current working directory. To view its contents:

	address <- "https://s3.amazonaws.com/coursera-uploads/user-a0dfb37c6ee127847e6a3549/972585/asst-3/c57556203d8a11e4a70f8f5a029d0153.txt"
	address <- sub("^https", "http", address)
	data <- read.table(url(address), header = TRUE)
	View(data)

* * *
## Transformation steps (to avoid unnecessary duplication, please see accompanying README for script walkthrough)

1. Merged the training and the test sets to create one data set.  
	* We match the sets of data based on their dimensions, as specified in the __Input__ section above.
	* This was done in accordance with the structure specified by community TA, David Hood in course discussion forum. [See David's diagram here](https://coursera-forum-screenshots.s3.amazonaws.com/ab/a2776024af11e4a69d5576f8bc8459/Slide2.png)

2. Extracted only the measurements on the mean and standard deviation for each measurement.  
	* We did this by searching through each measurement feature name for the strings "mean()" and "sd()".
	* There were some strings containing "meanFreq()", which we avoided as instructed by community TA, Trent Baur, in [this post](https://class.coursera.org/getdata-007/forum/thread?thread_id=71#post-208) in the course discussion forum.
	* After finding the right strings, we extracted their indexes to a list of target columns.
	* We used their indexes to select the correct column numbers from the data set in _Step 1_.
	* We extracted those relevant measurement columns to a new, smaller data set.

3. Used descriptive activity names to name the activities in the data set.  
	* Got the activity names from `activity_labels.txt` in the `UCI HAR Dataset` folder.
	* In `activity_labels.txt`, there were 6 rows, each containing a number (1-6) and a descriptive string value.
	* The activities in the data set were initially represented as numbers (1-6). Therefore, we used the `activity_labels.txt` information to match each number to the appropriate string value.
	* In the smaller data set we obtained in _Step 2_, we replaced each activity number in the activity column with the relevant activity label, which described the activity being recorded.

4. Labeled the data set with descriptive variable names.  
	* For this step, our aim is to rename the as-yet-unnamed measurement feature columns in the smaller data set from _Step 2_.
	* We had gotten a list of target columns in _Step 2_ as well, which we use to select the correct measurement feature names from the list given in `features.txt` inside the `UCI HAR Dataset` folder.
	* After selecting the relevant measurement feature names, we find that those names were abbreviated.
	* Therefore, before we apply those names to the appropriate columns in the smaller data set, we expand each name from its short-form version into a longer, more easily readable long-form version. 
	* We refer to `features_info.txt` in the `UCI HAR Dataset` for information on each measurement feature.
	* After creating the long-form version based on the short-form version, we rename the appropriate columns in the smaller data set we obtained in _Step 2_.

5. Created a second, independent tidy data set with the average of each variable for each activity and each subject.
	* Prior to this step, the dataset was in wide form and had not been summarized yet.
	* It was also not tidy, since there were column names (i.e. the measurement feature names) that were not variables, but in fact values of variables.
	* Therefore, to tidy it up, we convert those column names into values, under a new column called "features" in the tidy dataset.
	* At the same time, we also summarize the data. We note that for 1 unique subject doing 1 particular activity, and for 1 particular measurement feature, there were multiple numeric values recorded.
	* We summarize by computing the _mean_ of those numeric values recorded for each measurement feature, by activity and subject. The mean value is placed into a separate column in the tidy dataset.
	* Finally, we melt the data into narrow form for easier graphical display and write the resulting tidy data set into a file called `tidy.txt` in the current working directory.
	* Please see the above __Output__ section for details on the `tidy.txt` output.

* * *
end CodeBook

