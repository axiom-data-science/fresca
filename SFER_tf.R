install.packages("pacman")
pacman::p_load(readr, tidyr, lubridate, dplyr, stringr)

sfer_full <- read_csv("proj_data/m1/1.1/SFER_data.csv")


#create station table, write out to csv
station_table <- sfer_full %>%
  select("cruise_id", "station", "lat_dec", "lon_dec", "station_type") %>% 
  unique() %>%
  arrange(station)
write_csv(station_table, "sfer_station.csv")

# drop columns that are all NA
sfer <- Filter(function(x)!all(is.na(x)), sfer_full)
names(sfer)


#### create daily T/F subset for all_ctd data frame
# create date column
# create new keyfield
# drop unnecessary columns
sfer$date <- str_split(sfer$datetime, " ", simplify = TRUE)[,1]
sfer$new_key <- paste(sfer$date, sfer$cruise_id, sfer$station, sep = "_")

to_drop <- c("keyfield", "year", "month", "day", "time", "lat_deg", "lat_min",
             "lon_deg", "lon_min", "station_type", "depth", "depth_class",
             "depth_order", "cast", "datetime")
sfer <- sfer %>% select(-all_of(to_drop))

names(sfer)

# create counts table
h <- sfer %>% 
  mutate(temp = !is.na(temp),
         sal = !is.na(sal),
         o2_ctd = !is.na(o2_ctd),
         nh4 = !is.na(nh4),
         no2 = !is.na(no2),
         no3 = !is.na(no3),
         no3_no2 = !is.na(no3_no2),
         po4 = !is.na(po4),
         si = !is.na(si),
         avg_chl_a = !is.na(avg_chl_a),
         avg_phaeo = !is.na(avg_phaeo), .drop = FALSE) %>% 
  group_by(new_key) %>%
  summarize(event_n = n(),
            temp = sum(temp),
            sal = sum(sal),
            o2_ctd = sum(o2_ctd),
            nh4 = sum(nh4),
            no2 = sum(no2),
            no3 = sum(no3),
            no3_no2 = sum(no3_no2),
            po4 = sum(po4),
            si = sum(si),
            avg_chl_a = sum(avg_chl_a),
            avg_phaeo = sum(avg_phaeo))

h$date <- str_split(h$new_key, "_", simplify = TRUE)[,1]
h$cruise_id <- str_split(h$new_key, "_", simplify = TRUE)[,2]
h$station <- str_split(h$new_key, "_", simplify = TRUE)[,3]
h <- relocate(h, date, cruise_id, station, .after = new_key)
names(h)

h %>% filter(event_n > 1)

write_csv(h, "sfer_counts.csv")

names(h)
skip_these <- c("new_key", "cruise_id", "station", "event_n", "latitude", "longitude", "date")
other_cols <- setdiff(names(h), skip_these)

j <- h %>% 
  select(-event_n) %>%
  mutate(across(all_of(other_cols), ~ ifelse(.x > 0, TRUE, FALSE)))

sample_n(j, 20)

write_csv(j, "sfer_logical.csv")  
