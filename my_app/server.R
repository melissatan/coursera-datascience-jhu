# server.R

load("data/start.RData", envir=.GlobalEnv)
source("nextword.R")

nextw <- function(phrase, lang, safemode) {
  if (lang == "en_us") {
    return(StupidBackoff(phrase, removeProfanity=safemode))
  } else if (lang == "valley") {
    return("like")
  } else if (lang == "ook") {
    return("ook")
  } else if (lang == "hodor") {
    return("HODOR")
  }
}

shinyServer(function(input, output) {

    phraseGo <- eventReactive(input$goButton, {
      input$phrase
    })
    output$stats <- renderText({
      numword <- length(strsplit(input$phrase," ")[[1]])
      numchar <- nchar(input$phrase)
      paste("You've written ", numword, " words and ", numchar, "characters")
    })
    output$nextword <- renderText({
      result <- nextw(phraseGo(), input$lang, input$safemode)
      # result <- nextw(input$phrase, input$lang)
      paste0(result)
    })
    output$stats2 <- renderText({
      numword <- length(strsplit(input$phrase2," ")[[1]])
      numchar <- nchar(input$phrase2)
      paste("You've written ", numword, " words and ", numchar, "characters")
    })
    output$nextword2 <- renderText({
      result <- nextw(input$phrase2, input$lang, input$safemode)
      paste0(result)
    })

})
