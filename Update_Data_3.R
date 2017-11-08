# Author: Rory Pulvino
# Date:   8/4/2017
# Re:     Testing for criminal history
# Info:   This adds cumulative counting columns for specific crime
# types, adds totaling columns for specific crime types, adds indicator
# columns for each UID for specific crime types, and adds an indicator
# column for if a UID commits a gun offense in the year following an 
# crime.

#################################################################
##             Loading Packages and Data                       ##
#################################################################

# Loading Packages
pkgs <- c('tidyverse', "readxl", "reshape2", 'stringr')
lapply(pkgs, require, character.only = TRUE)

# Setting local path
setwd("R:/Gun Enforcement Unit/Analyses/SNA")

# Loading Data
#df <- read.csv("170424_Suspect_Data2.csv") # Data
df <- read_excel('170830_Suspect_Data4.xlsx') # Data

# Cutting down data
df <- distinct(df, UID, INCIDENT_NUMBER, INCIDENT_CODE, .keep_all = TRUE)
############################################################### 
##                Variable Aggregating                       ##
###############################################################

AggregatedColumns <- function(DF, columnToUse, NewCol1, NewCol2) {
  # Needed library
  library(lazyeval)
  
  # Setting up column names to use
  columnToUse <- deparse(substitute(columnToUse))
  NewCol1 <- deparse(substitute(NewCol1))
  NewCol2 <- deparse(substitute(NewCol2))
  
  #### Creating new columns 
  # Creating the new column (one simple line)
  DF[[NewCol1]] <- as.integer(DF$UID %in% DF$UID[DF[[columnToUse]] == 1])
  
  # Counting up total offenses
  mutate_call = lazyeval::interp(~sum(a), a = as.name(columnToUse))
  DF <- DF %>% group_by_("UID") %>% mutate_(.dots = setNames(list(mutate_call), NewCol2))
  
  DF
}

# Applying function to calculate totals and to show a UID as having committed
# a specified type of crime or having committed a crime in a hotspot
df <- AggregatedColumns(df, aggr_violence_incident, commit_aggr_violence, total_aggr_violence)
df <- AggregatedColumns(df, gun_incident, commit_gun, total_gun)
df <- AggregatedColumns(df, gun_violence_incident, commit_gun_violence, total_gun_violence)
df <- AggregatedColumns(df, property_incident, commit_property, total_property)
df <- AggregatedColumns(df, autoburg_incident, commit_autoburg, total_autoburg)
df <- AggregatedColumns(df, dv_incident, commit_dv, total_dv)
df <- AggregatedColumns(df, violent_incident, commit_violence, total_violence)
df <- AggregatedColumns(df, Alice_Griffith_HS, commit_AG, total_AG)
df <- AggregatedColumns(df, Columbus_Broadway_HS, commit_CBr, total_CBr)
df <- AggregatedColumns(df, Potrero_Hill_HS, commit_PH, total_PH)
df <- AggregatedColumns(df, Central_Bayview_HS, commit_CBay, total_CBay)
df <- AggregatedColumns(df, Holloway_HS, commit_Hol, total_Hol)
df <- AggregatedColumns(df, Tenderloin_HS, commit_TL, total_TL)
df <- AggregatedColumns(df, Mission_24St_HS, commit_M24, total_M24)
df <- AggregatedColumns(df, Mission_16St_HS, commit_M16, total_M16)
df <- AggregatedColumns(df, BlackHole_HS, commit_BH, total_BH)
df <- AggregatedColumns(df, Broad_HS, commit_Br, total_Br)
df <- AggregatedColumns(df, Sunnydale_HS, commit_SD, total_SD)
df <- AggregatedColumns(df, Northern_HS, commit_N, total_N)

# Date columns for most recent crime to easily cut the data
#df$DATE_OF_INCIDENT <- as.Date(df$DATE_OF_INCIDENT, '%Y-%m-%D')

df <- df %>%
  group_by(UID) %>%
  mutate(Most_Recent_Crime_Year = max(lubridate::year(DATE_OF_INCIDENT)))

# Calculating age at time of incident
df$UID_DOB <- gsub('([A-Z]+)_([A-Z]+)_(\\d+)', '\\3', df$UID)

# Setting as a date class and fixing the year to the correct century
df$UID_DOB <- as.Date(df$UID_DOB, format = '%m%d%y')
df$UID_DOB <- as.Date(ifelse(df$UID_DOB > Sys.Date(), format(df$UID_DOB, "19%y-%m-%d"), 
                                 format(df$UID_DOB)))


# Calculating age at the time of each crime
df$age_at_crime <- floor(as.numeric(df$DATE_OF_INCIDENT - df$UID_DOB) / 365.25)

# Totaling up incidents per UID
df <- df %>% group_by(UID) %>% mutate(total_incidents = n())

#################################################################
##             Creating cumulative columns                     ##
#################################################################
# Here the aim is to create summary stats per incident + UID for the 
# UID. For example, for each UID's incident, I want to know how many
# violent incidents the suspect had committed up to that point. Trying to test
# what the connection is between crime types and future gun crime. Will
# also test this for gang affiliation, age, and how recent the previous crime was

# Adding columns of rolling cumulative sums for variables of interest
#df$DATE_OF_INCIDENT <- lubridate::mdy(df$DATE_OF_INCIDENT)    
df <- df %>%
  group_by(UID) %>%
  dplyr::arrange(DATE_OF_INCIDENT) %>%
  mutate(cumulative_property_incidents = cumsum(property_incident),
         cumulative_gun_incidents = cumsum(gun_incident),
         cumulative_gun_v_incidents = cumsum(gun_violence_incident),
         cumulative_violent_incidents = cumsum(violent_incident),
         cumulative_autoburg_incidents = cumsum(autoburg_incident),
         cumulative_dv_incidents = cumsum(dv_incident),
         cumulative_aggr_v_incidents = cumsum(aggr_violence_incident),
         cumulative_incidents = seq(from = 1, to = n()),
         cumulative_TL_inc = cumsum(Tenderloin_HS),
         cumulative_Br_inc = cumsum(Broad_HS),
         cumulative_AG_inc = cumsum(Alice_Griffith_HS),
         cumulative_CBr_inc = cumsum(Columbus_Broadway_HS),
         cumulative_M24_inc = cumsum(Mission_24St_HS),
         cumulative_M16_inc = cumsum(Mission_16St_HS),
         cumulative_N_inc = cumsum(Northern_HS),
         cumulative_SD_inc = cumsum(Sunnydale_HS),
         cumulative_Ho_inc = cumsum(Holloway_HS),
         cumulative_PH_inc = cumsum(Potrero_Hill_HS),
         cumulative_CBa_inc = cumsum(Central_Bayview_HS),
         cumulative_BH_inc = cumsum(BlackHole_HS)
         )

#################################################################
##             Creating predictive dummy columns              ##
#################################################################
# Adding dummy variable for if an individual was a gun suspect in the next year from
# a given incident
# Filtering to the obs I care about
dfadd <- df %>% 
  filter(gun_incident == 1) %>% 
  select(UID, DATE_OF_INCIDENT) %>% 
  rename(gun_inc_date = DATE_OF_INCIDENT)

# Converting to character since in dcast it screws up the dates
dfadd$gun_inc_date <- as.character(dfadd$gun_inc_date)

# Merging data
dfnew <- left_join(df, dfadd, by = 'UID')

# Creating new column used for dcasting
dfnew <- dfnew %>% 
  group_by(UID, DATE_OF_INCIDENT, INCIDENT_NUMBER, INCIDENT_CODE) %>% 
  mutate(gun_date_index = seq(from = 1, to = n()))

dfnew$gun_date_index <- paste0('gun_date_',dfnew$gun_date_index)

#casting the data wide
df1 <- reshape2::dcast(dfnew,
                     ... ~ gun_date_index,
                     value.var = "gun_inc_date",
                     fill = NA)

# CREATE FUNCTION TO DO THE STEPS BELOW FOR gun_date_1 to gun_date_9 columns


# Converting back to date
for (col in colnames(df1)[grep('^gun_date_', colnames(df1))]){
  df1[[col]] <- as.Date(df1[[col]])
}

##### Creating dummy variables #######
## Dummy variable for if a gun incident occurred within a year of a given incident
df1$gun_inc_within_year <- 0 # Initiating column

# Flipping to date if needed
df1$DATE_OF_INCIDENT <- as.Date(df1$DATE_OF_INCIDENT, '%Y-%m-%d')

# This for loop goes over the gun date columns and gives a 1 if a given incident 
# occurred within a year of any of the gun dates (before or after)
for (col in rev(colnames(df1)[grep('^gun_date_', colnames(df1))])){
  df1$gun_inc_within_year <- ifelse((df1[[col]] - df1$DATE_OF_INCIDENT) <= 366,
                                    1, 0)
}

# This gives gun_inc_within_year an NA if the incident is within the last year and 
# there has not been a gun incident, since there is potential that a gun incident will 
# occur.
df1$gun_inc_within_year <- ifelse((df1$DATE_OF_INCIDENT > as.Date('2016-08-30') & df1$gun_inc_within_year == 0), 
                                  NA, df1$gun_inc_within_year)

# This gives gun_inc_within_year a 0 if the incident occurred more than a year ago 
# from the last date in the data (2017-08-30) and no gun incident occurred as it is
# impossible for a gun incident to have occurred by then unless later charges are 
# brought for a past incident, then this will update as data is added.
df1$gun_inc_within_year <- ifelse((df1$DATE_OF_INCIDENT <= as.Date('2016-08-30') & is.na(df1$gun_inc_within_year)), 
                                  0, df1$gun_inc_within_year)


## Dummy variable for if a gun incident occurred within a year AFTER a given incident
df1$gun_inc_next_year <- 0 # Initiating a column

# This for loop goes over the gun date columns and gives a 1 if a given incident 
# occurred less than a year before any of the gun dates
for (col in rev(colnames(df1)[grep('^gun_date_', colnames(df1))])){
  df1$gun_inc_next_year <- ifelse(((df1[[col]] - df1$DATE_OF_INCIDENT) <= 366) & (df1[[col]] > df1$DATE_OF_INCIDENT),
                                    1, df1$gun_inc_next_year)
}

# This gives gun_inc_next_year a 0 if the incident occurred more than a year ago 
# from the last date in the data (2017-04-20) and no gun incident occurred as it is impossible 
# for a gun incident to have occurred by then unless later charges are brought for
# a past incident, then this will update as data is added.
df1$gun_inc_next_year <- ifelse((df1$DATE_OF_INCIDENT <= as.Date('2017-08-30') & is.na(df1$gun_inc_next_year)), 
                                  0, df1$gun_inc_next_year)

# Changing gun_inc_next_year to NA if they were marked as zero and occurred within the
# year from the end of the data (2017-08-30) as it is possible that a gun charge will
# be added in the future
df1$gun_inc_next_year <- ifelse((df1$DATE_OF_INCIDENT > as.Date('2016-08-30') & df1$gun_inc_next_year == 0), 
                                  NA, df1$gun_inc_next_year)

dfcopy <- select(df1, INCIDENT_NUMBER:cumulative_incidents, gun_inc_next_year:gang_charged)

# Saving new dataframe
write.csv(dfcopy, '170830_Suspect_Data5.csv')

########
# Checking out summary stats for  gun offenders
########
dfgun <- filter(df, gun_incident == 1)

dfgun %>%
  filter(!is.na(age_at_crime)) %>%
  ggplot(aes(x = age_at_crime))+
    geom_histogram()
dfgun %>%
  filter(!is.na(age_at_crime) & age_at_crime < 28 & age_at_crime > 2) %>%
  ggplot(aes(x = age_at_crime))+
  geom_histogram()
dfsummary <- dfgun %>%
  ungroup() %>%
  dplyr::summarize(max = max(age_at_crime, na.rm = TRUE), min = min(age_at_crime, na.rm = TRUE), 
            median = median(age_at_crime, na.rm = TRUE), mean = mean(age_at_crime, na.rm = TRUE))
# Based on the distribution, it appears that gun crime starts escalating for those over 12 and
# looks minimal for those over 70

dfsummary <- dfgun %>%
  ungroup() %>%
  filter(!is.na(age_at_crime) & age_at_crime > 12 & age_at_crime < 70) %>%
  summarise(average = mean(age_at_crime), med = median(age_at_crime), stdev = sd(age_at_crime),
            stderror = sd(age_at_crime)/sqrt(n()), N = n())



