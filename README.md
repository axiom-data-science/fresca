# FRESCA data management scripts
A collection of related R scripts used for data wrangling as part of the data management effort for the FRESCA program.

R scripts were written in RStudio, version 2024.12.1+563 "Kousa Dogwood" Release (27771613951643d8987af2b2fb0c752081a3a853, 2025-02-02) for Ubuntu Jammy
Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) rstudio/2024.12.1+563 Chrome/126.0.6478.234 Electron/31.7.7 Safari/537.36, Quarto 1.6.43 (/opt/quarto/bin/quarto)

## Scripts
[source]_tf.R reads in the source data file and creates three tables in data_out/:
 - [source]_counts.csv described the number of measurements were taken for each parameter at each station on each date in the source data.
 - [source]_logical.csv indicates with TRUE/FALSE values whether or not any measurements were taken for each parameter at each station on each day in the source data.
 - [source]_stations.csv lists each unique combination of station name, cruise_id, decimal latitude and decimal longitude in the source data.

## Source datasets 
SFER_data.csv - from https://github.com/Ecosystem-Assessment-Lab/SFER/blob/main/DATA/SFER_data.csv
all_ctd.csv - QC'ed USF CTD data files from https://usf.app.box.com/s/dvoi1ve0jn3apbdlad114uhn0pvmjool/folder/263263439573


## To do
 - create tables of data availability by source, to be used by the notebook to link out to sources
 - include more sources
