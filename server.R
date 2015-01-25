# server.R

library(UsingR); data(galton) # parent and child heights
galton.m <- galton * 2.54 # convert inch to cm
fit <- lm(child ~ parent, data=galton.m)
slope <- summary(fit)$coef[2,1]
intercept <- summary(fit)$coef[1,1]
height.multiplier <- 1

shinyServer(function(input, output) {

    output$text1 <- renderText({
        paste0("Given that your ", input$parent,
              " is ", input$height,
              " cm tall and you are ", input$child,
              ":")
    })

    output$text2 <- renderText({

        parent.multiplier <- switch(input$parent,
                                    "mother" = 1.08,
                                    "father" = 1)

        child.divisor <- switch(input$child,
                                "male" = 1,
                                "female" = 1.08)

        result <- round((input$height * parent.multiplier
                         * slope + intercept)/child.divisor,0)

        paste0("Your height is estimated at ",
                result,
                " cm. (Look for the red square below!)")
    })

    output$plot <- renderPlot({

        parent.multiplier <- switch(input$parent,
                                    "mother" = 1.08,
                                    "father" = 1)

        child.divisor <- switch(input$child,
                                "male" = 1,
                                "female" = 1.08)

        result <- round((input$height * parent.multiplier
                         * slope + intercept)/child.divisor,0)

        plot(child~parent, data=galton.m, pch=20,
             main = "How you stack up against people Galton measured in 1885",
             xlim=c(140,210), xlab="parent height (cm)",
             ylim=c(140,210), ylab="child height (cm)")
        abline(fit, lwd=2, col="skyblue")
        points(input$height, result, col="red", pch=15)
        text(input$height, result, paste("You:",result), pos=3, col="red")
    })

})
