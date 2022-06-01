library(shinydashboard)

ui <- dashboardPage(
  dashboardHeader(title = "FCRE Data Dashboard"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Meteorology", tabName = "meteorology", icon = icon("cloud-sun-rain")),
      menuItem("Water Quality", tabName = "waterqual", icon = icon("tint")),
      menuItem("Forecasts", tabName = "forecasts", icon = icon("chart-line")),
      menuItem("About", tabName = "about", icon = icon("info-circle"))
    )
  ),
  dashboardBody(
    tabItems(
      # First tab content
      tabItem(tabName = "dashboard",
              fluidRow(
                column(
                  h1("Welcome to the Falling Creek Reservoir Data Dashboard!"),
                  p("Explore our high frequency sensor data and our forecasts.")
                )
              )
      ),
      # Meteorology ----
      tabItem(tabName = "meteorology",
              fluidRow(
                h2("Meteorology tab content"),
                selectInput("met_var", "Select variable", choices = met_vars$variable),
                plotlyOutput("met_plot")
              )
      ),
      
      # insitu ----
      tabItem(tabName = "waterqual",
              fluidRow(
                h2("WQ tab content"),
                column(3,
                       checkboxGroupInput("wtemp_depth", "Select depth", choices = wtemp_depths)
                       ),
                column(9,
                       h3("Water temperature"),
                       plotlyOutput("wtemp_line_plot"),
                       h3("Thermocline depth"),
                       plotlyOutput("thermo_plot")
                       )
                )
      ),
      
      
      # Forecasts ----
      tabItem(tabName = "forecasts",
              h2("Forecasts tab content"),
              column(3,
                     checkboxGroupInput("fc_depths", "Select depth", choices = unique(curr_tibble$depth))
              ),
              column(9,
                     plotlyOutput("fc_wtemp_line_plot"),
                     checkboxInput("add_uc", "Add uncertainty")
              )
      ),
      # About ----
      tabItem(tabName = "about",
              h2("About tab content")
      )
    )
  )
)

# end
