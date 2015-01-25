# ui.R

shinyUI(fluidPage(
    titlePanel(h1("How tall were you meant to be?")),

    sidebarLayout(
        sidebarPanel(
            h3("Your parent's height"),

            sliderInput("height",
                        label = "Parent's height (cm):",
                        min = 150, max = 200, value = 170),

            radioButtons("parent",
                         label = "Which parent?",
                         choices = list("Mother" = "mother",
                                        "Father" = "father"),
                         selected = "mother"),

            selectInput("child",
                        label ="Your gender:",
                        choices = list("Male" = "male",
                                       "Female" = "female"),
                        selected = "male"),

            helpText("With apologies to folks in the US who
                     don't use the metric system.")
        ),

        mainPanel(
            h3("Results"),
            h4(textOutput("text1")),
            h4(textOutput("text2")),
            plotOutput("plot"),
            h3("About the app"),
            p("This Shiny app relies on the Galton height dataset,
              which can be found in R's UsingR library.
            Caveat: Galton collected this data around 1885,
              so it may or may not apply to modern-day people.
              Results are best taken with pinch of salt.")
        )
    )
))
