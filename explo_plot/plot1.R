# Plot 1: Global Active Power histogram

# using packages: sqldf, dplyr

# dataset was unzipped outside current working dir
filename <- "../exdata-data-household_power_consumption/household_power_consumption.txt"

# use sqldf to select rows for specific dates
library(sqldf)

# only want dates 2007-02-01 and 2007-02-02
# "Date" col format is e.g. "16/2/2007"
df <- read.csv.sql(filename,
                   header = TRUE,
                   sep = ";",
                   sql = 'select * from file
                          where Date == "1/2/2007"
                          or Date == "2/2/2007"')

# missing values are coded in data as "?"
is.na(df) <- df=="?"

# use dplyr for easier datatable manip
library(dplyr)
dt <- tbl_df(df) #convert df into datatable

# select the Global_active_power column
gap <- select(dt, Global_active_power)

# convert to numeric vector for hist
gap <- gap$Global_active_power

# save plot to 480px by 480px png

png(file = "plot1.png", # create png in working dir
    width = 480, height = 480, units = "px")

hist(gap,
     main = "Global Active Power",
     col = "#FF2800", #ferrari red
     xlab = "Global Active Power (kilowatts)")

dev.off() # close png device
