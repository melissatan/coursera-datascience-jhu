# ui.R
library(shiny)

shinyUI(fluidPage(
  theme = "bootstrap.css",

  titlePanel(h1("Word Psychic", align="center"),
             windowTitle = "word psychic - a coursera capstone project"),
  h4("(about as accurate as a human one.)", align="center"),

  hr(),

  fluidRow(

    column(6, offset=3,

        tabsetPanel(type = "tabs",
          tabPanel("Classic",
            "This text box wants to be your friend! Go on, write something:",
            textInput("phrase", label = "", value = ""),
            tags$head(tags$style(type="text/css", "#phrase {width: 600px;}")),

            fluidRow(
              column(6,
                     actionButton("goButton", "Guess the next word!"),
                     br(), br(),
                     p("Our tea leaves think the next word is...")
              ),
              column(6,
                     p(textOutput("stats")),
                     h2(textOutput("nextword"))
              )
            )

          ),
          tabPanel("Instant",
            "This text box wants to be your friend! Go on, write something:",
            textInput("phrase2", label = "", value = ""),
            tags$head(tags$style(type="text/css", "#phrase2 {width: 600px;}")),

            fluidRow(
              column(6,
                    br(),br(),br(),
                    "Our crystal ball says the next word is..."
                    ),
              column(6,
                    p(textOutput("stats2")),
                    h2(textOutput("nextword2"))
                    )
            )
          )
        )
    )
  ),

  hr(),

  fluidRow(
    column(5, offset=1,

           wellPanel(
             h4("How to use this?"),

             p("To get started, fill in the text box."),
             p("If you're in 'Classic' mode, click the button.
                For 'Instant' mode, a word should appear by itself."),

             helpText("Select language ",em("English (US)"), ",
                  if you are one of my
                  brilliant and totally-not-susceptible-to-flattery
                  peer graders from Coursera.
                  ")
           )

    ),
    column(5,
           selectInput("lang",
                       label = "Which language should we use?",
                       choices = list("English (US)" = "en_us",
                                      "Valley Girl (Calif.)" = "valley",
                                      "Librarian (Discworld)" = "ook",
                                      "Hodor (Westeros)" = "hodor"),
                       selected = "en_us"),
           checkboxInput("safemode",
                         label = "Safe mode on (remove swear words, etc.)",
                         value = TRUE),
           br(),
           p("Source code on ",
             a("Github", href="https://github.com/melissatan/dscapstone"),
             align="right")
    )
  )
))
