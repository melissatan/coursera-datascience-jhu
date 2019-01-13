# Plot 4: 2x2 with plot1, Voltage, plot3, Global reactive power

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

plotdata <- select(dt,
                   Global_active_power,
                   Global_reactive_power,
                   Voltage,
                   Sub_metering_1,
                   Sub_metering_2,
                   Sub_metering_3,
                   Date, Time)


# lubridate to merge Date and Time to POSIXct object, timestamp
library(lubridate)
plotdata <- mutate(plotdata,
                   lubdate = dmy(Date),
                   lubtime = hms(Time),
                   timestamp = update(lubdate,
                                      hours = hour(lubtime),
                                      minutes = minute(lubtime),
                                      seconds = second(lubtime))
)

png(file = "plot4.png", # create png in working dir
    width = 480, height = 480, units = "px")

# want 2 cols and 2 rows. fill by row
par(mfrow=c(2,2))

# topleft: global active power (plot1)
plot(x = plotdata$timestamp,
     y = plotdata$Global_active_power,
     type = "l", # line chart
     xlab = "", # no x-label
     ylab = "Global Active Power"
)

# topright: voltage
plot(x = plotdata$timestamp,
     y = plotdata$Voltage,
     type = "l", # line chart
     xlab = "datetime",
     ylab = "Voltage"
)

# bottomleft: energy submetering (plot3)
max_y <- 38
# initial plot of submeter 1, black
plot(x = plotdata$timestamp, #x axis
     y = plotdata$Sub_metering_1, #y axis
     type = "l", # line chart
     xlab = "", # no x-label
     ylab = "Energy sub metering",
     ylim=c(0,max_y),
     col = "black"
)
# overlay new plots - submeter 2, red
par(new=T) # tells R not to erase the older plot
plot(x = plotdata$timestamp, #x axis
     y = plotdata$Sub_metering_2, #y axis
     type = "l", # line chart
     xlab = "", # no x-label
     ylab = "",
     ylim=c(0,max_y),
     col = "red"
)
legend(x = "topright",
       legend = c("Sub_metering_1",
                  "Sub_metering_2",
                  "Sub_metering_3"),
       pch = NA, lty = 1 ,
       col = c("black", "red", "blue"),
       bty = "n" # to remove border
       )
# overlay submeter 3, blue
par(new=T)
plot(x = plotdata$timestamp, #x axis
     y = plotdata$Sub_metering_3, #y axis
     type = "l", # line chart
     xlab = "", # no x-label
     ylab = "",
     ylim=c(0,max_y),
     col = "blue"
)
par(new=F)

# bottomright: global reactive power
plot(x = plotdata$timestamp,
     y = plotdata$Global_reactive_power,
     type = "l", # line chart
     xlab = "datetime",
     ylab = "Global_reactive_power"
)

dev.off() # close png device

