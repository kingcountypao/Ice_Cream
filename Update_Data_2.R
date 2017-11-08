
#RE:   Removing Homicide Victims from the network
#Date: 8/3/2017
#By:   Rory Pulvino
#Info: This script adds a date of death, death (dummy), and a gang
# columns to the suspect data. 


#################################################################
##             Loading Packages and Data                       ##
#################################################################

# Loading Packages
pkgs <- c('tidyverse', "RecordLinkage", "readxl",
          "stringdist", "reshape2", 'stringr', 'lubridate')
lapply(pkgs, require, character.only = TRUE)

# Setting local path
setwd("R:/R Directory/SFDA_Shiny/sfda_violence_timeline")

# Loading Data
df <- read.csv("10062017_violence_victim_cleaned.csv") # Homicide Data
dfcopy <- df

#################################################################
##             Cleaning up data                                ##
#################################################################
#### Creating dummy variable for homicides ####
# Homicides crimes
df$Crime <- gsub("([0-9]+) - ([A-Z])", '\\2', df$INCIDENT_CODE)
df$Homicide <- ifelse(str_detect(as.character(df$Crime), "^HOMICIDE"), 1, 0)
dfhom <- filter(df, Homicide == 1)

dfhom <- distinct(dfhom, VICTIM_UID, .keep_all = TRUE)

#### Grabbing the full suspect data to add information regarding death and gang affiliation
# Setting local path
setwd("R:/Gun Enforcement Unit/Analyses/SNA")

# Loading Data
dfsuspect <- read.csv("170830_Suspect_Data5.csv") # Suspect data

# Adding column for homicide victims
dfsuspect$dead <- ifelse(dfsuspect$UID %in% dfhom$VICTIM_UID, 1, 0)
dfsuspect$date_of_death <- ifelse(dfsuspect$UID %in% dfhom$VICTIM_UID, 
                                  format(as.Date(dfhom$DATE_OF_INCIDENT, '%m/%d/%Y'), '%Y-%m-%d'), NA)

##### Grabbing gang data
# Setting local path
setwd("R:/R Directory/SFDA_Shiny/sfda_violence_timeline")

# Loading data
dfgang <- read_excel('Gang_charged.xlsx')

# Setting up the UID
dfgang$DOB <- format(as.Date(as.character(dfgang$`Defendant DOB`), '%Y-%m-%d'), '%m%d%y')

dfgang$UID <- gsub('([A-Z]+), ([A-Z]+\\S)', '\\2_\\1', dfgang$`Defendant Name                          `)
dfgang$UID <- gsub('(\\w+).*', '\\1', dfgang$UID)

dfgang$UID <- paste0(dfgang$UID, '_', dfgang$DOB)

# Gang tag
gang_list <- c('800', 'ALE', 'ARMY', 'BIB', 'BNT', 'CDP', 'CHO', 'DBG', 'DBR', 'DVP',
               'DVP', 'EDD', 'HOL', 'HOP', 'JAC', 'KOP', 'MAC', 'NAT', 'NOR', 'OAK',
               'OSC', 'OTHG', 'PAG', 'PAR', 'QST', 'QUE', 'RAN', 'SUN', 'SUR', 'TOW',
               'TP', 'TRE', 'UTH', 'VAL', 'WMO', 'WSI', 'YBG', 'ZOO')

dfgang$gang_charged <- NA
for(x in gang_list){
  dfgang$gang_charged <- ifelse(str_detect(dfgang$`List of Case Crime Involved                       `, x), 
                        x, as.character(dfgang$gang_charged))
}

colnames(dfgang)[24] <- 'name_abbr'
dfgang_only <- distinct(dfgang, UID, gang_charged)

# Adding column for gang prosecutions
dfsuspect$gang_charged <- ifelse(dfsuspect$UID %in% dfgang_only$UID, dfgang_only$gang_charged, NA) 

# Save
setwd("R:/Gun Enforcement Unit/Analyses/SNA")
dfsuspect <- select(dfsuspect, -X)

write.csv(dfsuspect, "170830_Suspect_Data5.csv")

