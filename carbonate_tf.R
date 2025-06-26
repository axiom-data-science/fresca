install.packages("pacman")
pacman::p_load(readr, tidyr, lubridate, dplyr, stringr, data.table, kutils)

# erddap_data <- read_csv("https://www.ncei.noaa.gov/erddap/tabledap/CRCP_Carbonate_Chemistry_Atlantic.csvp?time%2Clatitude%2Clongitude%2CCTDID%2CRegion%2CYear%2CMission%2CLocation%2CUTCDate%2CUTCTime%2CDate_UTC%2CSample_Depth_m%2CDIC_UMOL_KG%2CTALK_UMOL_KG%2CpH_measured%2CpH_calculated%2CpCO2%2CAragonite_Sat%2CSalinity_Bottle%2CTemperature_C%2CPressure_db%2CSiteID%2CSurvey_design%2CSample_frequency%2Caccession_url&time%3E=2010-03-08T12%3A26%3A00Z&time%3C=2022-12-18T15%3A53%3A00Z&Mission=%22WaltonSmith%22")
carb_data <- read_csv("proj_data/m1/1.1/carbonate/20250513_FK_Carbonate_Chemistry_data.csv")

summary(carb_data)

zapspace(names(carb_data))


names(carb_data) <- trimws(names(carb_data))
names(carb_data)
carb_data <- carb_data[carb_data$UTCDate < ymd("2024-04-01"),]
carb_data$DateTimeUTC <- lubridate::parse_date_time(paste(carb_data$UTCDate,
                                                          carb_data$UTCTime), 
                                                orders = c("Ymd HMS", "Ymd HM",
                                                           "Ymd H", "Ymd"))

carb_data <- data.frame(carb_data)

parameters <- c("DIC_umol_kg","TA_umol_kg","pH_measured","pH_calculated","pCO2_uatm",
                "Aragonite_Sat_W","Salinity_Bottle","Temperature_C","Pressure_db")
length(parameters)
# create table of stations for carbonate data
station_table <- carb_data %>%
  select("CTDID", "SiteID", "Latitude", "Longitude") %>% 
  unique() %>%
  arrange(SiteID)
write_csv(station_table, "data_out/carb_stations.csv")

# names(carb_data)
# typeof(carb_data)
# summary(carb_data)

# drop columns that are all NA, if any
carb_data <- Filter(function(x)!all(is.na(x)), carb_data)
# names(carb_data)

#### create daily T/F subset for all_ctd data frame
# date column == DateTimeUTC
# keyfield == CTDID
# drop unnecessary columns

to_drop <- c("keyfield", "year", "month", "day", "time", "lat_deg", "lat_min",
             "lon_deg", "lon_min", "station_type", "depth", "depth_class",
             "depth_order", "cast", "datetime")
carb_data <- carb_data %>% select(all_of(c(parameters, names(station_table), "DateTimeUTC")))

