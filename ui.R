# ui.R

shinyUI(fluidPage(
    titlePanel(h1("How tall were you meant to be?")),

    sidebarLayout(
        sidebarPanel(
            h3("Your parent's height"),

            helpText("To get started, just fill in the
                    requested details below. The app will
                    automatically update the results."),

            sliderInput("height",
                        label = "Your parent's height (cm):",
                        min = 150, max = 200, value = 170),

            radioButtons("parent",
                         label = "Which parent is that?",
                         choices = list("Mother" = "mother",
                                        "Father" = "father"),
                         selected = "mother"),

            selectInput("child",
                        label ="Your birth gender:",
                        choices = list("Male" = "male",
                                       "Female" = "female"),
                        selected = "male"),

            helpText("With apologies to folks in the US who
                     don't use the metric system."),

            helpText("To see the source code, visit the ",
                    a("github repo",
                    href="https://github.com/melissatan/ddp-shiny"))

        ),

        mainPanel(
            h3("About this app"),
            p("This app uses the Galton height dataset,
              from R's UsingR library, converted to metric.
            I've fit the data to a linear model, with
            parent height as predictor and child height as
            outcome.
            Galton's data points are shown as
            black dots; the regression line is blue."),
            p("Caveat: Galton collected this data around 1885,
            so extrapolating it to modern-day people is just
            for fun. And, as you can see below, his dataset's height
            range is limited.
            (His multiplier number, to convert female heights to
            male heights, was 1.08. This figure is debatable, but
            for convenience I've also used that multiplier
            for my prediction).
            Results are best taken with a pinch of salt!"),
            h3("Results"),
            p(textOutput("text1")),
            (textOutput("text2")),
            plotOutput("plot")
        )
    )
))
