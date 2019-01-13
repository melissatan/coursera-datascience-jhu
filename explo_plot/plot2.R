# Plot 2: linechart of global active power, Thu thru Sat

# using packages: sqldf, dplyr, lubridate

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

# plot global active power over datetime
gap_date_time <- select(dt, Global_active_power, Date, Time)

# lubridate to merge Date and Time into POSIXct object
library(lubridate)
plotdata <- mutate(gap_date_time,
                   lubdate = dmy(Date),
                   lubtime = hms(Time),
                   timestamp = update(lubdate,
                                    hours = hour(lubtime),
                                    minutes = minute(lubtime),
                                    seconds = second(lubtime))
                   )

# save plot to 480px by 480px png

png(file = "plot2.png", # create png in working dir
    width = 480, height = 480, units = "px")

plot(x = plotdata$timestamp, #x axis
     y = plotdata$Global_active_power, #y axis
     type = "l", # line chart
     xlab = "", # no x-label
     ylab = "Global Active Power (kilowatts)"
     )

dev.off() # close png device
