install.packages("pacman")
pacman::p_load(readr, tidyr, lubridate, dplyr, stringr)

data_dir <- "proj_data/m1/1.1/cleaned_ctd_data/"

cruises <- str_remove(list.files(data_dir), ".csv")
ctd_data <- list()
for (i in cruises){
  ctd_data[[i]] <- read_csv(paste0(data_dir, i, ".csv"), col_types = cols(.default = "c"))
}
names(ctd_data) <- cruises

find_widest <- function(list_of_dfs){
  h <- 0
  widest <- ""
  for (i in 1:length(list_of_dfs)){
    j <- ncol(list_of_dfs[[i]])
    if (j > h){
      h <- j
      widest <- names(list_of_dfs[i])
    }
  }
  remove(list = c("j", "h"))
  return(widest)
}

add_cols_and_concat <- function(template_table, list_of_tables){
  for (i in 1:length(list_of_tables)){
    test_table <- list_of_tables[[i]]
    this_cruise <- names(list_of_tables[i])
    
    if (this_cruise %in% unique(template_table$cruise_id)){
      next
    } else {
      for (i in names(template_table)){
        if (!(i %in% names(test_table))){
          test_table[i] <- NA
        }
      }
    
      reorder_index <- match(names(template_table), names(test_table))
      template_table <- rbind(template_table, test_table[reorder_index])
    }
  }
  remove(list = c("test_table", "reorder_index", "this_cruise"))
  return(template_table)
}

template <- find_widest(ctd_data)
all_ctd <- read_csv(paste0(data_dir, template, ".csv"), col_types = cols(.default = "c"))
remove(template)

all_ctd <- add_cols_and_concat(all_ctd, ctd_data)

## the code above successfully concatenates all of the tables together. 
# Just to check my work I tried to do the same thing on the command line:
# $ touch ../all_ctd.csv
# $ for i in *.csv;do csvcut -c "scan,salinity,temperature,pressure,cruise_id,
#   station,time,latitude,longitude,sea_water_electrical_conductivity,
#   dissolved_oxygen,oxygen_saturation,depth,sea_water_sigma_t,descent_rate,
#   sound_velocity" $i >> ../all_ctd.csv; done
#
# That only has the subset of columns that are present in every file. 
# Now I'll read that into R and make sure I get the same thing

all_subset <- read_csv("proj_data/m1/1.1/all_ctd.csv", col_types = cols(.default = "c"))

# I need to remove the duplicate rows from csvstack adding the header
# row from each csv as a row in the table

dupes <- all_subset[duplicated(all_subset), ]
no_dupes <- setdiff(all_subset, dupes)

# Now I'll remove from all_ctd, the data frame made in R of all the 
# concatenated tables, the columns that aren't present in every file.
# And then finally check to make sure the two data frames are the same by
# checking that the setdiff between the two data frames is empty

all_ctd_subset <- all_ctd[,names(all_subset)]
setdiff(all_ctd_subset, no_dupes)
# the difference is a with zero rews - all good!

remove(list = c("all_subset", "dupes", "no_dupes", "all_ctd_subset",
            "ctd_data"))

#### create daily T/F subset for all_ctd data frame
names(all_ctd)
all_ctd$date <- str_split(all_ctd$time, " ", simplify = TRUE)[,1]
all_ctd$key <- paste(all_ctd$date, all_ctd$cruise_id, all_ctd$station, sep = "_")

h <- all_ctd %>% 
  mutate(scan = !is.na(scan),
         salinity = !is.na(salinity),
         temperature = !is.na(temperature),
         pressure = !is.na(pressure),
         sea_water_electrical_conductivity = !is.na(sea_water_electrical_conductivity),
         CDOM = !is.na(CDOM),
         dissolved_oxygen = !is.na(dissolved_oxygen),
         oxygen_saturation = !is.na(oxygen_saturation),
         chlorophyll_concentration = !is.na(chlorophyll_concentration),
         chlorophyll_fluorescence = !is.na(chlorophyll_fluorescence),
         photosynthetically_available_radiation = !is.na(photosynthetically_available_radiation),
         beam_attenuation = !is.na(beam_attenuation),
         beam_transmission = !is.na(beam_transmission),
         depth = !is.na(depth),
         sea_water_sigma_t = !is.na(sea_water_sigma_t),
         sound_velocity = !is.na(sound_velocity),
         altimeter = !is.na(altimeter), .drop = FALSE) %>% 
  group_by(key) %>%
  summarize(event_n = n(),
            scan = sum(scan),
            salinity = sum(salinity),
            temperature = sum(temperature),
            pressure = sum(pressure),
            sea_water_electrical_conductivity = sum(sea_water_electrical_conductivity),
            CDOM = sum(CDOM),
            dissolved_oxygen = sum(dissolved_oxygen),
            oxygen_saturation = sum(oxygen_saturation),
            chlorophyll_concentration = sum(chlorophyll_concentration),
            chlorophyll_fluorescence = sum(chlorophyll_fluorescence),
            photosynthetically_available_radiation = sum(photosynthetically_available_radiation),
            beam_attenuation = sum(beam_attenuation),
            beam_transmission = sum(beam_transmission),
            depth = sum(depth),
            sea_water_sigma_t = sum(sea_water_sigma_t),
            sound_velocity = sum(sound_velocity),
            altimeter = sum(altimeter))

names(h)
h$date <- str_split(h$key, "_", simplify = TRUE)[,1]
h$cruise_id <- str_split(h$key, "_", simplify = TRUE)[,2]
h$station <- str_split(h$key, "_", simplify = TRUE)[,3]
h <- relocate(h, date, cruise_id, station, .after = key)

write_csv(h, "all_ctd_counts.csv")
names(h)
skip_these <- c("key", "cruise_id", "station", "event_n", "latitude", "longitude", "date")
other_cols <- setdiff(names(h), skip_these)

j <- h %>% 
  select(-event_n) %>%
  mutate(across(all_of(other_cols), ~ ifelse(.x > 0, TRUE, FALSE)))

write_csv(j, "all_ctd_logical.csv")  


# create a list of all stations and accompanying lat/lon values
stations <- all_ctd %>% 
  select(cruise_id, station, latitude, longitude) %>%
  distinct() %>%
  arrange(station)
write_csv(stations, "all_ctd_stations.csv")



# create a table linking cruise_id to download location.
# this is tricky because box is a bit like the RW and uses hash-like file names
          
