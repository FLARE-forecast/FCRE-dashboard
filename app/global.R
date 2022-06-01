library(tidyverse)
library(lubridate)
library(plotly)
library(ncdf4)

config_set_name <- "default"
message("Beginning generate targets")
message(config_set_name)

#' Set the lake directory to the repository directory

lake_directory <- getwd()


#' Source the R files in the repository

files.sources <- list.files(file.path(lake_directory, "R"), full.names = TRUE)
sapply(files.sources, source)

#' Generate the `config_obs` object and create directories if necessary

# Download Data from GitHub ----
config_obs <- FLAREr::initialize_obs_processing(lake_directory,
                                                observation_yml = "observation_processing.yml",
                                                config_set_name)
# config <- FLAREr::set_configuration(configure_run_file = "configure_run.yml",
#                                     lake_directory,
#                                     config_set_name = config_set_name)


#' Clone or pull from data repositories

FLAREr::get_git_repo(lake_directory,
                     directory = config_obs$realtime_insitu_location,
                     git_repo = "https://github.com/FLARE-forecast/FCRE-data.git")

FLAREr::get_git_repo(lake_directory,
                     directory = config_obs$realtime_met_station_location,
                     git_repo = "https://github.com/FLARE-forecast/FCRE-data.git")
FLAREr::get_git_repo(lake_directory,
                     directory = config_obs$realtime_inflow_data_location,
                     git_repo = "https://github.com/FLARE-forecast/FCRE-data.git")

#get_git_repo(lake_directory,
#             directory = config_obs$manual_data_location,
#             git_repo = "https://github.com/FLARE-forecast/FCRE-data.git")

#' Download files from EDI

FLAREr::get_edi_file(edi_https = "https://pasta.lternet.edu/package/data/eml/edi/389/5/3d1866fecfb8e17dc902c76436239431",
                     file = config_obs$met_raw_obs_fname[2],
                     lake_directory)

FLAREr::get_edi_file(edi_https = "https://pasta.lternet.edu/package/data/eml/edi/271/5/c1b1f16b8e3edbbff15444824b65fe8f",
                     file = config_obs$insitu_obs_fname[2],
                     lake_directory)

FLAREr::get_edi_file(edi_https = "https://pasta.lternet.edu/package/data/eml/edi/198/8/336d0a27c4ae396a75f4c07c01652985",
                     file = config_obs$secchi_fname,
                     lake_directory)

FLAREr::get_edi_file(edi_https = "https://pasta.lternet.edu/package/data/eml/edi/200/11/d771f5e9956304424c3bc0a39298a5ce",
                     file = config_obs$ctd_fname,
                     lake_directory)

FLAREr::get_edi_file(edi_https = "https://pasta.lternet.edu/package/data/eml/edi/199/8/da174082a3d924e989d3151924f9ef98",
                     file = config_obs$nutrients_fname,
                     lake_directory)


FLAREr::get_edi_file(edi_https = "https://pasta.lternet.edu/package/data/eml/edi/202/7/f5fa5de4b49bae8373f6e7c1773b026e",
                     file = config_obs$inflow_raw_file1[2],
                     lake_directory)

FLAREr::get_edi_file(edi_https = "https://pasta.lternet.edu/package/data/eml/edi/542/1/791ec9ca0f1cb9361fa6a03fae8dfc95",
                     file = "silica_master_df.csv",
                     lake_directory)

FLAREr::get_edi_file(edi_https = "https://pasta.lternet.edu/package/data/eml/edi/551/5/38d72673295864956cccd6bbba99a1a3",
                     file = "Dissolved_CO2_CH4_Virginia_Reservoirs.csv",
                     lake_directory)

#' Clean up observed meterology
library(magrittr)
library(dplyr)
cleaned_met_file <- met_qaqc(realtime_file = file.path(config_obs$file_path$data_directory, config_obs$met_raw_obs_fname[1]),
                             qaqc_file = file.path(config_obs$file_path$data_directory, config_obs$met_raw_obs_fname[2]),
                             cleaned_met_file = file.path(config_obs$file_path$targets_directory, config_obs$site_id,paste0("observed-met_",config_obs$site_id,".nc")),
                             input_file_tz = "EST",
                             nldas = NULL)

#' Clean up observed inflow
library(tidyverse)
cleaned_inflow_file <- inflow_qaqc(realtime_file = file.path(config_obs$file_path$data_directory, config_obs$inflow_raw_file1[1]),
                                   qaqc_file = file.path(config_obs$file_path$data_directory, config_obs$inflow_raw_file1[2]),
                                   nutrients_file = file.path(config_obs$file_path$data_directory, config_obs$nutrients_fname),
                                   silica_file = file.path(config_obs$file_path$data_directory,  config_obs$silica_fname),
                                   co2_ch4 = file.path(config_obs$file_path$data_directory, config_obs$ch4_fname),
                                   cleaned_inflow_file = file.path(config_obs$file_path$targets_directory, config_obs$site_id, paste0(config_obs$site_id,"-targets-inflow.csv")),
                                   input_file_tz = 'EST')

#' Clean up observed insitu measurements

cleaned_insitu_file <- in_situ_qaqc(insitu_obs_fname = file.path(config_obs$file_path$data_directory,config_obs$insitu_obs_fname),
                                    data_location = config_obs$file_path$data_directory,
                                    maintenance_file = file.path(config_obs$file_path$data_directory,config_obs$maintenance_file),
                                    ctd_fname = file.path(config_obs$file_path$data_directory, config_obs$ctd_fname),
                                    nutrients_fname =  file.path(config_obs$file_path$data_directory, config_obs$nutrients_fname),
                                    secchi_fname = file.path(config_obs$file_path$data_directory, config_obs$secchi_fname),
                                    ch4_fname = file.path(config_obs$file_path$data_directory, config_obs$ch4_fname),
                                    cleaned_insitu_file = file.path(config_obs$file_path$targets_directory, config_obs$site_id, paste0(config_obs$site_id,"-targets-insitu.csv")),
                                    lake_name_code = config_obs$site_id,
                                    config = config_obs)

#' Move targets to s3 bucket

message("Successfully generated targets")

# FLAREr::put_targets(site_id = config_obs$site_id,
#                     cleaned_insitu_file,
#                     cleaned_met_file,
#                     cleaned_inflow_file,
#                     use_s3 = config$run_config$use_s3)
#
# if(config$run_config$use_s3){
#   message("Successfully moved targets to s3 bucket")
# }

# Generate GLM met files
cf_met_vars <- c("air_temperature",
                 "surface_downwelling_shortwave_flux_in_air",
                 "surface_downwelling_longwave_flux_in_air",
                 "relative_humidity",
                 "wind_speed",
                 "precipitation_flux")
glm_met_vars <- c("AirTemp",
                  "ShortWave",
                  "LongWave",
                  "RelHum",
                  "WindSpeed",
                  "Rain")
obs_met_nc <- ncdf4::nc_open(cleaned_met_file) # obs_met_file
obs_met_time <- ncdf4::ncvar_get(obs_met_nc, "time")
origin <- stringr::str_sub(ncdf4::ncatt_get(obs_met_nc, "time")$units, 13, 28)
origin <- lubridate::ymd_hm(origin)
obs_met_time <- origin + lubridate::hours(obs_met_time)
met <- tibble::tibble(time = obs_met_time)
for(i in 1:length(cf_met_vars)) {
  met <- cbind(met, ncdf4::ncvar_get(obs_met_nc, cf_met_vars[i]))
}
ncdf4::nc_close(obs_met_nc)

names(met) <- c("time", glm_met_vars)
met$AirTemp <- met$AirTemp - 273.15
met$RelHum <- met$RelHum * 100
met <- met[met$time > "2022-01-01", ]

met_vars <- data.frame(var = names(met)[-1], variable = c("Air temperature", "Shortwave radiation", "Longwave radiation", "Relative humidity", "Wind speed", "Rain"))

# inflow
inflow <- readr::read_csv(cleaned_inflow_file)
inflow <- inflow[inflow$time >= "2022-01-01", ]
inflow_vars <- data.frame(var = names(inflow)[2:3], variable = c("Flow", "Water temperature"))

#insitu data
insitu <- readr::read_csv(cleaned_insitu_file)
insitu <- insitu[insitu$date >= "2022-01-01", ]

wtemp <- pivot_wider(insitu[insitu$variable == "temperature", ], values_from = value, names_prefix = "wtr_", names_from = depth, id_cols = date)
wtemp_long <- insitu[insitu$variable == "temperature", ]
wtemp_long$fdepth <- factor(wtemp_long$depth)
wtemp_depths <- unique(wtemp_long$depth)

thermocline <- rLakeAnalyzer::ts.thermo.depth(wtemp)

# # Download FLARE forecast ----
# Sys.setenv('AWS_DEFAULT_REGION' = 's3',
#            'AWS_S3_ENDPOINT' = 'flare-forecast.org',
#            'USE_HTTPS' = TRUE)
# 
today_date <- Sys.Date()
# 
filename <- normalizePath(file.path("data", "forecasts", "fcre", "realtime", paste0("fcre-", today_date, ".nc")))
# 
# 
# tryCatch({ #because we know there are 4 days missing so this will bonk 4 times
#   object = paste0("fcre/fcre-", today_date, "-marylofton.nc")
#   #retrieve object from bucket and write to file locally
#   aws.s3::save_object(
#     object = object,
#     bucket = "forecasts",
#     file = file.path(filename))
# }, error = function(e) {
#   cat("ERROR :",conditionMessage(e), "\n")
#   }
# )
# 
# df <- aws.s3::get_bucket_df(bucket = "forecasts", prefix = "fcre_js2", max = Inf)
# head(df)
# tail(df)


# Read FLARE forecasts ----
today_date <- "2021-06-06"
filename <- normalizePath(file.path("forecasts", "fcre", "realtime", paste0("fcre-", today_date, ".nc")))

fc_temp <- read_flare_temp(file = filename)

fc_temp[[1]]$temp

mean_var <- array(NA, dim = c(length(fc_temp[[1]]$depths), length(fc_temp[[1]]$dates)))
upper_var <- array(NA, dim = c(length(fc_temp[[1]]$depths), length(fc_temp[[1]]$dates)))
lower_var <- array(NA,dim = c(length(fc_temp[[1]]$depths), length(fc_temp[[1]]$dates)))
sd_var <- array(NA,dim = c(length(fc_temp[[1]]$depths), length(fc_temp[[1]]$dates)))
for(j in 1:length(fc_temp[[1]]$dates)){
  for(ii in 1:length(fc_temp[[1]]$depths)){
    mean_var[ii, j] <- mean(fc_temp[[1]]$temp[j,ii , ], na.rm = TRUE)
    sd_var[ii, j] <- sd(fc_temp[[1]]$temp[j,ii , ], na.rm = TRUE)
    upper_var[ii, j] <- quantile(fc_temp[[1]]$temp[j,ii , ], 0.1, na.rm = TRUE)
    lower_var[ii, j] <- quantile(fc_temp[[1]]$temp[j,ii , ], 0.9, na.rm = TRUE)
  }
}

curr_tibble <- tibble::tibble(date = rep(lubridate::as_datetime(fc_temp[[1]]$dates), each = length(fc_temp[[1]]$depths)),
                              forecast_mean = round(c(mean_var),4),
                              forecast_sd = round(c(sd_var),4),
                              forecast_upper_95 = round(c(upper_var),4),
                              forecast_lower_95 = round(c(lower_var),4),
                              # observed = round(obs_curr,4),
                              depth = rep(fc_temp[[1]]$depths, length(fc_temp[[1]]$dates)),
                              state = "temp",
                              forecast_start_day = fc_temp[[1]]$dates[1])
curr_tibble$fdepth <- factor(curr_tibble$depth)

# if(file.exists(filename)) {
#   
# }
