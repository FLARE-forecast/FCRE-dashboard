server <- function(input, output) {

  output$met_plot <- renderPlotly({
    idx <- which(names(met) == met_vars$var[met_vars$variable == input$met_var])
    p <- ggplot(met) +
      geom_point(aes_string("time", names(met)[idx]))
    ggplotly(p, dynamicTicks = TRUE)
  })
  
  output$wtemp_line_plot <- renderPlotly({
    
    validate(
      need(length(input$wtemp_depth) > 0, "Please select a depth.")
    )
    p <- ggplot(wtemp_long[wtemp_long$depth %in% as.numeric(input$wtemp_depth), ]) +
      geom_point(aes(date, value, color = fdepth))
    ggplotly(p, dynamicTicks = TRUE)
  })
  
  output$thermo_plot <- renderPlotly({
    p <- ggplot(thermocline) +
      geom_line(aes(date, thermo.depth)) +
      scale_y_continuous(c(0, 9), trans = "reverse", name = "Depth (m)")
    ggplotly(p, dynamicTicks = TRUE)
  })
  
  output$fc_wtemp_line_plot <- renderPlotly({
    
    print(input$fc_depths)
    validate(
      need(length(input$fc_depths) > 0, "Please select a depth.")
    )
    
    idx <- which(curr_tibble$depth %in% as.numeric(input$fc_depths))

    p <- ggplot(curr_tibble[idx, ], aes(x = date)) +
      {if(input$add_uc) geom_line(aes(y = forecast_lower_95, color = fdepth), size = 0.5, linetype = "dashed")} +
      {if(input$add_uc) geom_line(aes(y = forecast_upper_95, color = fdepth), size = 0.5, linetype = "dashed")} +
      geom_line(aes(y = forecast_mean, color = fdepth), size = 0.5) +
      theme_light() +
      labs(x = "Date", y = "temp", title = "temp") +
      theme(axis.text.x = element_text(angle = 90, size = 10))
    ggplotly(p, dynamicTicks = TRUE)
  })
}

# end
