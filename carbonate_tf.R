install.packages("pacman")
pacman::p_load(readr, tidyr, lubridate, dplyr, stringr, data.table, kutils)

# erddap_data <- read_csv("https://www.ncei.noaa.gov/erddap/tabledap/CRCP_Carbonate_Chemistry_Atlantic.csvp?time%2Clatitude%2Clongitude%2CCTDID%2CRegion%2CYear%2CMission%2CLocation%2CUTCDate%2CUTCTime%2CDate_UTC%2CSample_Depth_m%2CDIC_UMOL_KG%2CTALK_UMOL_KG%2CpH_measured%2CpH_calculated%2CpCO2%2CAragonite_Sat%2CSalinity_Bottle%2CTemperature_C%2CPressure_db%2CSiteID%2CSurvey_design%2CSample_frequency%2Caccession_url&time%3E=2010-03-08T12%3A26%3A00Z&time%3C=2022-12-18T15%3A53%3A00Z&Mission=%22WaltonSmith%22")
data <- read_csv("proj_data/m1/1.1/carbonate/20250513_FK_Carbonate_Chemistry_data.csv")

summary(data)

names(data) <- trimws(names(data))
names(data)
carb_data <- data[data$UTCDate < ymd("2024-04-01"),]
carb_data$DateTimeUTC <- lubridate::parse_date_time(paste(carb_data$UTCDate,
                                                          carb_data$UTCTime), 
                                                orders = c("Ymd HMS", "Ymd HM",
                                                           "Ymd H", "Ymd"))



parameters <- c("DIC_umol_kg","TA_umol_kg","pH_measured","pH_calculated","pCO2_uatm",
                "Aragonite_Sat_W","Salinity_Bottle","Temperature_C","Pressure_db")

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
# keyfield == new_key
# drop unnecessary columns

carb_data <- carb_data %>% select(all_of(c(names(station_table),
                                           "DateTimeUTC", parameters)))

for (i in parameters){
  if (i %in% names(carb_data)) {
    carb_data[[i]] <- as.numeric(carb_data[[i]])
  }
}


summary(carb_data)


slice_sample(carb_data, n = 15)
carb_data$cruise_id <- str_split(carb_data$CTDID , "_", simplify = TRUE)[,1]
carb_data$new_key <- paste(carb_data$cruise_id, carb_data$DateTimeUTC, carb_data$SiteID, sep = "#")

carb_data$cruise_id

h <- carb_data |> 
  mutate(DIC_umol_kg = !is.na(DIC_umol_kg),
         TA_umol_kg = !is.na(TA_umol_kg),
         pH_measured = !is.na(pH_measured),
         pH_calculated = !is.na(pH_calculated),
         pCO2_uatm = !is.na(pCO2_uatm),
         Aragonite_Sat_W = !is.na(Aragonite_Sat_W),
         Salinity_Bottle = !is.na(Salinity_Bottle),
         Temperature_C = !is.na(Temperature_C),
         Pressure_db = !is.na(Pressure_db), .drop = FALSE) |>
  group_by(new_key) |> 
  summarize(event_n = n(),
            DIC_umol_kg = sum(DIC_umol_kg),
            TA_umol_kg = sum(TA_umol_kg),
            pH_measured = sum(pH_measured),
            pH_calculated = sum(pH_calculated),
            pCO2_uatm = sum(pCO2_uatm),
            Aragonite_Sat_W = sum(Aragonite_Sat_W),
            Salinity_Bottle = sum(Salinity_Bottle),
            Temperature_C = sum(Temperature_C),
            Pressure_db = sum(Pressure_db))

h

h$cruise_id <- str_split(h$new_key, "#", simplify = TRUE)[,1]
h$date <- str_split(h$new_key, "#", simplify = TRUE)[,2]
h$station <- str_split(h$new_key, "#", simplify = TRUE)[,3]
typeof(h)

h <- relocate(h, date, cruise_id, station, .after = new_key)

write_csv(h, "data_out/carbonate_daily.csv")

skip_these <- c("new_key", "cruise_id", "station", "event_n", "latitude", "longitude", "date")
other_cols <- setdiff(names(h), skip_these)

j <- h %>% 
  select(-event_n) %>%
  mutate(across(all_of(other_cols), ~ ifelse(.x > 0, TRUE, FALSE)))

write_csv(j, "data_out/carbonate_logical.csv")  

