
#RE:   CABLE Name Cleaning and Adding to Older Data
#Date: 7/11/2017
#By:   Rory Pulvino
#Info: This is the first script for adding new suspect data.
# It is used to clean up names coming from CABLE data that
# will be used in SNA and is added to the previous database.
#      


#################################################################
##             Loading Packages and Data                       ##
#################################################################

# Loading Packages
pkgs <- c('tidyverse', "RecordLinkage", "readxl",
          "stringdist", "reshape2", 'crimeVarCreation')
lapply(pkgs, require, character.only = TRUE)

# Setting local path
setwd("R:/Gun Enforcement Unit/Analyses/SNA")

# Loading Data
dfData <- read.csv("171101_Suspect_Data2.csv") # New Data
dfOldData <- read.csv("170830_Suspect_Data5.csv") # Old Data
dfOldData <- rename(dfOldData, INCIDENT_NUMBER.1 = INCIDENT_NUMBER_1)

df <- anti_join(dfData, dfOldData, by = c("NAME", "INCIDENT_NUMBER.1")) # Only the new entries
df$New <- 1

############################################################### 
##                Cleaning Names                             ##
###############################################################

# Duplicating NAME column to alter
df$NAMECleaned <- df$NAME

# Getting rid of Jr., Sr., and III in names
df$NAMECleaned <- gsub("/JR/", "/", df$NAMECleaned) # Replaces JR, SR, and III with no space
df$NAMECleaned <- gsub("/SR/", "/", df$NAMECleaned)
df$NAMECleaned <- gsub("/III/", "/", df$NAMECleaned)
df$NAMECleaned <- gsub("/IV/", "/", df$NAMECleaned)
df$NAMECleaned <- gsub("JR/", "/", df$NAMECleaned) # Takes care of JR, SR, and III that are attached at the end of a name
df$NAMECleaned <- gsub("SR/", "/", df$NAMECleaned)
df$NAMECleaned <- gsub("III/", "/", df$NAMECleaned)
df$NAMECleaned <- gsub("IV/", "/", df$NAMECleaned)

# Breaking apart name column and creating a first and last name column
df$First_Name <- as.character(lapply(strsplit(as.character(df$NAMECleaned), "/"), "[", 2)) # This splits the NAME column and then takes the second item split off as the first name
df$Last_Name <- as.character(lapply(strsplit(as.character(df$NAMECleaned), "/"), "[", 1)) # This splits the NAME column and then takes the first item split off as the last name

# Adjusting DOB column to M-D-Y format
df$DATE_OF_BIRTH <- sprintf("%06d", df$DATE_OF_BIRTH) # Adding a leading zero to birthdays where leading zero was dropped when coming into R
df$DOB <- format(as.Date(df$DATE_OF_BIRTH, format="%m%d%y"),"%Y-%m-%d")
df$DOB <- as.Date(ifelse(df$DOB > Sys.Date(), 
                         format(as.Date(df$DATE_OF_BIRTH, format="%m%d%y"),"19%y-%m-%d"), 
                         format(df$DOB)))

dfOldData$DATE_OF_BIRTH <- sprintf("%06d", dfOldData$DATE_OF_BIRTH) # Adding a leading zero to birthdays where leading zero was dropped when coming into R
dfOldData$DOB <- format(as.Date(dfOldData$DATE_OF_BIRTH, format="%m%d%y"),"%Y-%m-%d")
dfOldData$DOB <- as.Date(ifelse(dfOldData$DOB > Sys.Date(), 
                         format(as.Date(dfOldData$DATE_OF_BIRTH, format="%m%d%y"),"19%y-%m-%d"), 
                         format(dfOldData$DOB)))

# Creating a column withe full name and DOB to use for UID and matching
df <- unite_(df, "UID", c("First_Name", "Last_Name", "DATE_OF_BIRTH"), sep = '_', remove = FALSE)


#################################################################
##              Cutting down variables                         ##
#################################################################
# Getting rid of ending letter in incident number
df$INCIDENT_NUMBER <- gsub("([0-9]+)[A-Z]", '\\1', df$INCIDENT_NUMBER)

df <- select(df, INCIDENT_NUMBER, INCIDENT_NUMBER.1, INCIDENT_CODE, 
                UID, New, NAME, First_Name, Last_Name, DOB,
                DATE_OF_BIRTH, DATE_OF_INCIDENT,
                TIME_OCCURRED_FROM, DISTRICT, AddressNoXSpace, RACE,
                SEX)

dfOldData <- select(dfOldData, INCIDENT_NUMBER, INCIDENT_NUMBER.1, INCIDENT_CODE, 
             UID, NAME, First_Name, Last_Name, DOB,
             DATE_OF_BIRTH, DATE_OF_INCIDENT,
             TIME_OCCURRED_FROM, DISTRICT, AddressNoXSpace, RACE,
             SEX)
#################################################################
##              Adding variables                               ##
#################################################################
# Need to test modified function to make sure string detect part
# works. If the new function doesn't work with the string detect, 
# then can get rid of the number at the start of the Incident Code
# with the below code and then alter the list auto burg and res burgs.
# df$Crime_Type <- gsub("[0-9]+ - (.*)", '\\1', dfnew$Crime_Type) # Taking away inc code number
#
#

# Creating column to manipulate
df$INCIDENT_CODE <- as.character(df$INCIDENT_CODE)
df$Crime_Type <- as.character(df$INCIDENT_CODE)

dfOldData$INCIDENT_CODE <- as.character(dfOldData$INCIDENT_CODE)
dfOldData$Crime_Type <- as.character(dfOldData$INCIDENT_CODE)

# Changing to auto burglary
AutoBurg_codes <- c('06240 - ATTEMPTED THEFT FROM LOCKED VEHICLE', '06220 - ATTEMPTED THEFT FROM UNLOCKED VEHICLE',
                    '05014 - BURGLARY, VEHICLE (ARREST MADE)', '05015 - BURGLARY, VEHICLE, ATT. (ARREST MADE)',
                    '06244 - GRAND THEFT FROM LOCKED AUTO', '06224 - GRAND THEFT FROM UNLOCKED AUTO',
                    '06241 - PETTY THEFT FROM LOCKED AUTO', '06221 - PETTY THEFT FROM UNLOCKED AUTO')

df <- gen_crime_type(AutoBurg_codes, df, INCIDENT_CODE, Crime_Type, 'AUTO BURGLARY')
dfOldData <- gen_crime_type(AutoBurg_codes, dfOldData, INCIDENT_CODE, Crime_Type, 'AUTO BURGLARY')

# Changing to residential burglary
ResBurg_codes <- c('05012 - BURGLARY OF APARTMENT HOUSE, ATT FORCIBLE ENTRY', '05011 - BURGLARY OF APARTMENT HOUSE, FORCIBLE ENTRY',
                   '05013 - BURGLARY OF APARTMENT HOUSE, UNLAWFUL ENTRY', '05022 - BURGLARY OF FLAT, ATTEMPTED FORCIBLE ENTRY',
                   '05021 - BURGLARY OF FLAT, FORCIBLE ENTRY', '05023 - BURGLARY OF FLAT, UNLAWFUL ENTRY',
                   '05031 - BURGLARY OF HOTEL ROOM, FORCIBLE ENTRY', '05033 - BURGLARY OF HOTEL ROOM, UNLAWFUL ENTRY',
                   '05042 - BURGLARY OF RESIDENCE, ATTEMPTED FORCIBLE ENTRY', '05041 - BURGLARY OF RESIDENCE, FORCIBLE ENTRY',
                   '05043 - BURGLARY OF RESIDENCE, UNLAWFUL ENTRY', '05082 - BURGLARY, HOT PROWL, ATTEMPTED FORCIBLE ENTRY',
                   '05081 - BURGLARY, HOT PROWL, FORCIBLE ENTRY', '05083 - BURGLARY, HOT PROWL, UNLAWFUL ENTRY')

df <- gen_crime_type(ResBurg_codes, df, INCIDENT_CODE, Crime_Type, 'RESIDENTIAL BURGLARY')
dfOldData <- gen_crime_type(ResBurg_codes, dfOldData, INCIDENT_CODE, Crime_Type, 'RESIDENTIAL BURGLARY')

# Changing to burglary other
BurgOther_codes <- c('BURGLARY,BLDG. UNDER CONSTRUCTION, FORCIBLE ENTRY', 'BURGLARY,STORE UNDER CONSTRUCTION, UNLAWFUL ENTRY',
                     'BURGLARY OF STORE, FORCIBLE ENTRY', 'BURGLARY,STORE UNDER CONSTRUCTION, FORCIBLE ENTRY',
                     'BURGLARY,RESIDENCE UNDER CONSTRT, UNLAWFUL ENTRY', 'BURGLARY, UNLAWFUL ENTRY',
                     'BURGLARY, FORCIBLE ENTRY', 'BURGLARY OF WAREHOUSE, FORCIBLE ENTRY',
                     'BURGLARY OF STORE, ATTEMPTED FORCIBLE ENTRY', 'BURGLARY,APT UNDER CONSTRUCTION, FORCIBLE ENTRY',
                     'BURGLARY OF STORE, UNLAWFUL ENTRY', 'BURGLARY,APT UNDER CONSTRUCTION, ATT. FORCIBLE',
                     'SAFE BURGLARY OF A STORE', 'SAFE BURGLARY', 'BURGLARY OF HOTEL ROOM, UNLAWFUL ENTRY',
                     'BURGLARY,BLDG. UNDER CONSTRUCTION, UNLAWFUL ENTRY', 'BURGLARY,FLAT UNDER CONSTRUCTION, UNLAWFUL ENTRY',
                     'BURGLARY,RESIDENCE UNDER CONSTRT, ATT. FORCIBLE', 'BURGLARY,FLAT UNDER CONSTRUCTION, FORCIBLE ENTRY',
                     'BURGLARY OF WAREHOUSE, UNLAWFUL ENTRY', 'BURGLARY OF WAREHOUSE, ATTEMPTED FORCIBLE ENTRY',
                     'BURGLARY,APT UNDER CONSTRUCTION, UNLAWFUL ENTRY', 'BURGLARY,WAREHOUSE UNDER CONSTRT, FORCIBLE ENTRY',
                     'SAFE BURGLARY OF AN APARTMENT', 'BURGLARY,HOTEL UNDER CONSTRUCTION, FORCIBLE ENTRY',
                     'SAFE BURGLARY OF A FLAT', 'BURGLARY,WAREHOUSE UNDER CONSTRT, ATT. FORCIBLE',
                     'BURGLARY OF HOTEL ROOM, ATTEMPTED FORCIBLE ENTRY', 'SAFE BURGLARY OF A WAREHOUSE',
                     'BURGLARY,FLAT UNDER CONSTRUCTION, ATT. FORCIBLE', 'BURGLARY OF HOTEL ROOM, FORCIBLE ENTRY',
                     'BURGLARY,WAREHOUSE UNDER CONSTRT, UNLAWFUL ENTRY', 'BURGLARY,BLDG. UNDER CONSTRUCTION, ATT. FORCIBLE',
                     'BURGLARY,HOTEL UNDER CONSTRUCTION, UNLAWFUL ENTRY', 'SAFE BURGLARY OF A HOTEL')

df <- gen_crime_type(BurgOther_codes, df, INCIDENT_CODE, Crime_Type, 'BURGLARY OTHER')
dfOldData <- gen_crime_type(BurgOther_codes, dfOldData, INCIDENT_CODE, Crime_Type, 'BURGLARY OTHER')

# Changing to ARSON
Arson_codes <- c('FIRE, UNLAWFULLY CAUSING', 'ARSON OF A VEHICLE',
                 'ARSON OF AN INHABITED DWELLING', 'ARSON',
                 'ATTEMPTED ARSON', 'ARSON OF A VACANT BUILDING',
                 'ARSON WITH GREAT BODILY INJURY', 'ARSON OF A COMMERCIAL BUILDING',
                 'ARSON OF A POLICE BUILDING', 'ARSON OF A POLICE VEHICLE')

df <- gen_crime_type(Arson_codes, df, INCIDENT_CODE, Crime_Type, 'ARSON')
dfOldData <- gen_crime_type(Arson_codes, dfOldData, INCIDENT_CODE, Crime_Type, 'ARSON')

# Changing to Assault
Assault_codes <- c('AGGRAVATED ASSAULT WITH BODILY FORCE', 'BATTERY', 'ASSAULT',
                   'AGGRAVATED ASSAULT WITH A DEADLY WEAPON', 'BATTERY WITH SERIOUS INJURIES',
                   'ASSAULT WITH CAUSTIC CHEMICALS', 'ATTEMPTED SIMPLE ASSAULT',
                   'ASSAULT BY POISONING', 'ASSAULT ON A POLICE OFFICER WITH A DEADLY WEAPON',
                   'MAYHEM WITH A DEADLY WEAPON', 'MAYHEM WITH BODILY FORCE',
                   'ATTEMPTED HOMICIDE WITH A DANGEROUS WEAPON', 'MAYHEM WITH A KNIFE',
                   'AGGRAVATED ASSAULT ON POLICE OFFICER WITH A KNIFE', 'ATTEMPTED MAYHEM WITH A DEADLY WEAPON',
                   'AGGRAVATED ASSAULT WITH A KNIFE', 'ATTEMPTED HOMICIDE WITH BODILY FORCE', 
                   'ATTEMPTED MAYHEM WITH A KNIFE', "ASSAULT OR ATTEMPTED MURDER UPON GOV'T OFFICERS",
                   'ATTEMPTED MAYHEM WITH BODILY FORCE', 'BATTERY OF A POLICE OFFICER',
                   'ATTEMPTED HOMICIDE WITH A KNIFE', 'AGGRAVATED ASSAULT OF POLICE OFFICER,BODILY FORCE',
                   
                   'SHOOTING INTO INHABITED DWELLING OR OCCUPIED VEHICLE', 'ASSAULT, AGGRAVATED, W/ SEMI AUTO',
                   'ASSAULT, AGGRAVATED, W/ MACHINE GUN', 'MAYHEM WITH A GUN',
                   'ATTEMPTED HOMICIDE WITH A GUN', 'FIREARM, DISCHARGING AT OCCUPIED BLDG, VEHICLE, OR AIRCRAFT',
                   'AGGRAVATED ASSAULT WITH A GUN', 'ASSAULT, AGGRAVATED, W/ GUN', 
                   'ASSAULT, AGGRAVATED, ON POLICE OFFICER, W/ GUN', 'ASSAULT, AGGRAVATED, ON POLICE OFFICER, W/ SEMI AUTO',
                   'FIREARM,Â DISCHARGING IN GROSSLY NEGLIGENT MANNER', 'DISCHARGING IN GROSSLY NEGLIGENT MANNER',
                   
                   'INFLICT INJURY ON COHABITEE', 'BATTERY, FORMER SPOUSE OR DATING RELATIONSHIP',
                   'CHILD ABUSE (PHYSICAL)', 'CHILD, INFLICTING INJURY RESULTING IN TRAUMATIC CONDITION',
                   'WILLFUL CRUELTY TO CHILD',
                   
                   'THREATS AGAINST LIFE', 'THREATENING PHONE CALL(S)',
                   'THREAT OR FORCE TO RESIST EXECUTIVE OFFICER', 'THREATENING SCHOOL OR PUBLIC EMPLOYEE',
                   'THREATS TO SCHOOL TEACHERS', 'THREAT TO STATE OFFICIAL OR JUDGE',
                   'UNLAWFUL DISSUADING/THREATENING OF A WITNESS', 'TERRORIZING BY MARKING PRIVATE PROPERTY',
                   'CIVIL RIGHTS, INCL. INJURY, THREAT, OR DAMAGE (HATE CRIMES)', 'TRESPASS WITHIN 30 DAYS OF CREDIBLE THREAT',
                   'ELDER ADULT OR DEPENDENT ABUSE (NOT EMBEZZLEMENT OR THEFT)', 'TERRORIZING BY ARSON OR EXPLOSIVE DEVICE',
                   'FALSE IMPRISONMENT', 'STALKING', 'ASSAULT BY POLICE OFFICER',
                   'RESISTING PEACE OFFICER, CAUSING THEIR SERIOUS INJURY OR DEATH', 'BATTERY DURING LABOR DISPUTE',
                   'LASERS, DISCHARGING OR LIGHTS AT AIRCRAFT')

df <- gen_crime_type(Assault_codes, df, INCIDENT_CODE, Crime_Type, 'ASSAULT')
dfOldData <- gen_crime_type(Assault_codes, dfOldData, INCIDENT_CODE, Crime_Type, 'ASSAULT')

# Changing to ROBBERY
Robbery_codes <- c('ROBBERY, BODILY FORCE', 'ROBBERY, ARMED WITH A KNIFE', 'ROBBERY ON THE STREET WITH A DANGEROUS WEAPON',
                   'ROBBERY OF A CHAIN STORE WITH BODILY FORCE', 'ROBBERY OF A CHAIN STORE WITH A KNIFE',
                   'ATTEMPTED ROBBERY ON THE STREET W/DEADLY WEAPON', 'ROBBERY ON THE STREET, STRONGARM',
                   'CARJACKING WITH A KNIFE', 'ROBBERY, ARMED WITH A DANGEROUS WEAPON',
                   'ATTEMPTED ROBBERY ON THE STREET WITH BODILY FORCE', 'ROBBERY OF A CHAIN STORE WITH A DANGEROUS WEAPON',
                   'ROBBERY ON THE STREET WITH A KNIFE', 'ROBBERY,  ATM, FORCE, ATT.',
                   'CARJACKING WITH A DANGEROUS WEAPON', 'SHOPLIFTING, FORCE AGAINST AGENT',
                   'ROBBERY OF A RESIDENCE WITH BODILY FORCE', 'ATTEMPTED ROBBERY WITH A KNIFE',
                   'ROBBERY OF A SERVICE STATION WITH A KNIFE', 'ATTEMPTED ROBBERY SERVICE STATION W/BODILY FORCE',
                   'CARJACKING WITH BODILY FORCE', 'ATTEMPTED ROBBERY WITH BODILY FORCE',
                   'ROBBERY, VEHICLE FOR HIRE, ATT., W/ FORCE', 'ATTEMPTED ROBBERY RESIDENCE WITH A KNIFE',
                   'ATTEMPTED ROBBERY SERVICE STATION W/DEADLY WEAPON', 'ATTEMPTED ROBBERY CHAIN STORE WITH A KNIFE',
                   'ROBBERY, VEHICLE FOR HIRE, ATT., W/ OTHER WEAPON', 'ATTEMPTED ROBBERY OF A BANK WITH BODILY FORCE',
                   'ROBBERY OF A BANK WITH A DANGEROUS WEAPON', 'ATTEMPTED ROBBERY OF A BANK WITH A KNIFE',
                   'ATTEMPTED ROBBERY CHAIN STORE WITH DEADLY WEAPON', 'ATTEMPTED ROBBERY RESIDENCE WITH A DEADLY WEAPON',
                   'ATTEMPTED ROBBERY COMM. ESTAB. WITH DEADLY WEAPON', 'ATTEMPTED ROBBERY COMM. ESTABLISHMENT W/KNIFE',
                   'ROBBERY,  ATM, KNIFE, ATT.',"ROBBERY OF A BANK WITH BODILY FORCE", 'ROBBERY OF A BANK WITH A KNIFE',
                   'ATTEMPTED ROBBERY COMM. ESTAB. WITH BODILY FORCE', 'ROBBERY OF A COMMERCIAL ESTABLISHMENT W/ A KNIFE',
                   'ROBBERY OF A SERVICE STATION WITH BODILY FORCE', 'ATTEMPTED ROBBERY OF A BANK WITH A DEADLY WEAPON',
                   'ROBBERY OF A SERVICE STATION W/DANGEROUS WEAPON', 'ATTEMPTED ROBBERY SERVICE STATION WITH A KNIFE',
                   'ROBBERY,  ATM, KNIFE', 'ATTEMPTED ROBBERY RESIDENCE WITH BODILY FORCE',
                   'ATTEMPTED ROBBERY ON THE STREET WITH A KNIFE', 'ROBBERY,  ATM, OTHER WEAPON',
                   'ROBBERY OF A RESIDENCE WITH A DANGEROUS WEAPON', 'ROBBERY OF A RESIDENCE WITH A KNIFE',
                   'ATTEMPTED ROBBERY WITH A DEADLY WEAPON', 'ROBBERY OF A COMMERCIAL ESTABLISHMENT W/ WEAPON',
                   'ROBBERY OF A COMMERCIAL ESTABLISHMENT, STRONGARM', 'ATTEMPTED ROBBERY CHAIN STORE WITH BODILY FORCE',
                   
                   'ATTEMPTED ROBBERY SERVICE STATION WITH A GUN', 'ATTEMPTED ROBBERY OF A BANK WITH A GUN',
                   'ROBBERY,  ATM, GUN, ATT.', 'ROBBERY OF A BANK WITH A GUN', 'ROBBERY,  ATM, GUN',
                   'ROBBERY, VEHICLE FOR HIRE, ATT., W/ GUN', 'ROBBERY OF A SERVICE STATION WITH A GUN',
                   'ATTEMPTED ROBBERY RESIDENCE WITH A GUN', 'ATTEMPTED ROBBERY CHAIN STORE WITH A GUN',
                   'ROBBERY OF A CHAIN STORE WITH A GUN', 'ATTEMPTED ROBBERY ON THE STREET WITH A GUN',
                   'ROBBERY ON THE STREET WITH A GUN', 'ROBBERY OF A RESIDENCE WITH A GUN',
                   'CARJACKING WITH A GUN', 'ROBBERY, ARMED WITH A GUN', 'ATTEMPTED ROBBERY WITH A GUN',
                   'ATTEMPTED ROBBERY COMM. ESTABLISHMENT WITH A GUN', 'ROBBERY OF A COMMERCIAL ESTABLISHMENT WITH A GUN')

df <- gen_crime_type(Robbery_codes, df, INCIDENT_CODE, Crime_Type, 'ROBBERY')
dfOldData <- gen_crime_type(Robbery_codes, dfOldData, INCIDENT_CODE, Crime_Type, 'ROBBERY')

# Changing to SEX OFFENSES, FORCIBLE
SexAssault_codes <- c('ATTEMPTED RAPE, ARMED WITH A DANGEROUS WEAPON', 'ASSAULT TO RAPE WITH A DANGEROUS WEAPON',
                      'ATTEMPTED RAPE WITH A GUN', 'FORCIBLE RAPE, ARMED WITH A DANGEROUS WEAPON',
                      'ASSAULT TO RAPE WITH A GUN', 'SODOMY', 'ENGAGING IN LEWD ACT',
                      'ATTEMPTED RAPE, ARMED WITH A SHARP INSTRUMENT', 'ASSAULT TO RAPE WITH A SHARP INSTRUMENT',
                      'RAPE, SPOUSAL', 'SEXUAL ASSAULT, ADMINISTERING DRUG TO COMMIT', 'CHILD ABUSE, EXPLOITATION',
                      'FORCIBLE RAPE, ARMED WITH A SHARP INSTRUMENT', 'FORCIBLE RAPE, ARMED WITH A GUN',
                      'ORAL COPULATION, UNLAWFUL (ADULT VICTIM)', 'PENETRATION, FORCED, WITH OBJECT',
                      'ORAL COPULATION', 'CHILD ABUSE, PORNOGRAPHY', 'ANNOY OR MOLEST CHILDREN',
                      'CHILD ABUSE SEXUAL', 'ASSAULT TO RAPE WITH BODILY FORCE',
                      'ATTEMPTED RAPE, BODILY FORCE', 'FORCIBLE RAPE, BODILY FORCE',
                      'SODOMY (ADULT VICTIM)', 'SEXUAL ASSAULT, AGGRAVATED, OF CHILD',
                      'ASSAULT TO COMMIT MAYHEM OR SPECIFIC SEX OFFENSES', 'SEXUAL BATTERY')

df <- gen_crime_type(SexAssault_codes, df, INCIDENT_CODE, Crime_Type, 'SEX OFFENSES, FORCIBLE')
dfOldData <- gen_crime_type(SexAssault_codes, dfOldData, INCIDENT_CODE, Crime_Type, 'SEX OFFENSES, FORCIBLE')

# Changing to LARCENY/THEFT
Larceny_codes <- c('GRAND THEFT FROM A BUILDING', 'ATTEMPTED THEFT COIN OPERATED MACHINE',
                   'PETTY THEFT SHOPLIFTING', 'PETTY THEFT FROM A BUILDING',
                   'PETTY THEFT OF PROPERTY', 'GRAND THEFT FROM PERSON', 'GRAND THEFT OF PROPERTY',
                   'LICENSE PLATE OR TAB, THEFT OF', 'LOST PROPERTY, GRAND THEFT',
                   'THEFT OF UTILITY SERVICES', 'GRAND THEFT BICYCLE',
                   'THEFT OF COMPUTERS OR CELL PHONES', 'THEFT OF CHECKS OR CREDIT CARDS',
                   'LOST PROPERTY, PETTY THEFT', 'THEFT, GRAND, OF FIREARM',
                   'GRAND THEFT PURSESNATCH', 'THEFT, BICYCLE, <$50, NO SERIAL NUMBER',
                   'PETTY THEFT COIN OPERATED MACHINE',  'GRAND THEFT PICKPOCKET', 'PETTY THEFT AUTO STRIP',
                   'EMBEZZLEMENT FROM DEPENDENT OR ELDER ADULT BY CARETAKER', 'GRAND THEFT AUTO STRIP',
                   'THEFT OF ANIMALS (GENERAL)', 'THEFT FROM MERCHANT OR LIBRARY',
                   'THEFT, GRAND, AGRICULTURAL', 'LOOTING DURING STATE OF EMERGENCY',
                   'ATTEMPTED MOTORCYCLE STRIP', "TRADE SECRETS, THEFT OR UNAUTHORIZED COPYING",
                   'THEFT, ANIMAL, ATT.', 'PETTY THEFT PHONE BOOTH', 'THEFT, BOAT',
                   'GRAND THEFT PHONE BOOTH', 'THEFT, DRUNK ROLL, ATT.', 'THEFT, DRUNK ROLL, <$50',
                   'ATTEMPTED GRAND THEFT PURSESNATCH', 'GRAND THEFT MOTORCYCLE STRIP', 
                   'THEFT, DRUNK ROLL, $50-$200', 'GRAND THEFT COIN OPERATED MACHINE',
                   'PETTY THEFT MOTORCYCLE STRIP', 'THEFT, BICYCLE, <$50, SERIAL NUMBER KNOWN',
                   'ATTEMPTED THEFT OF A BICYCLE', 'GRAND THEFT BY PROSTITUTE',
                   'THEFT OF TELECOMMUNICATION SERVICES, INCL. CLONE PHONE', 'ATTEMPTED SHOPLIFTING',
                   'PETTY THEFT WITH PRIOR', 'THEFT OF WRITTEN INSTRUMENT',
                   'GRAND THEFT SHOPLIFTING', 'THEFT, GRAND, BY FIDUCIARY, >$400 IN 12 MONTHS',
                   'ATTEMPTED THEFT FROM A BUILDING', 'THEFT, DRUNK ROLL, >$400',
                   'ATTEMPTED GRAND THEFT PICKPOCKET', 'THEFT, DRUNK ROLL, $200-$400',
                   'ATTEMPTED GRAND THEFT FROM PERSON', 'ATTEMPTED PETTY THEFT OF PROPERTY',
                   'ATTEMPTED AUTO STRIP', 'PETTY THEFT BICYCLE')

df <- gen_crime_type(Larceny_codes, df, INCIDENT_CODE, Crime_Type, 'LARCENY/THEFT')
dfOldData <- gen_crime_type(Larceny_codes, dfOldData, INCIDENT_CODE, Crime_Type, 'LARCENY/THEFT')

# Changing to VEHICLE THEFT
VehicleTheft_codes <- c('STOLEN TRAILER', 'STOLEN BUS', 'STOLEN MISCELLANEOUS VEHICLE',
                        'VEHICLE, RENTAL, FAILURE TO RETURN', 'ATTEMPTED STOLEN VEHICLE',
                        'AUTO, GRAND THEFT OF', 'STOLEN AND RECOVERED VEHICLE',
                        'STOLEN MOTORCYCLE', 'STOLEN TRUCK', 'STOLEN AUTOMOBILE')

df <- gen_crime_type(VehicleTheft_codes, df, INCIDENT_CODE, Crime_Type, 'VEHICLE THEFT')
dfOldData <- gen_crime_type(VehicleTheft_codes, dfOldData, INCIDENT_CODE, Crime_Type, 'VEHICLE THEFT')

####### Creating dummies for violent crimes, property crimes, auto burglaries, 
####### gun violence, and gun crimes
# Dummy for gun incident
gun_codes <- c('04011 - AGGRAVATED ASSAULT WITH A GUN', '02101 - ASSAULT TO RAPE WITH A GUN',
               '04093 - ASSAULT, AGGRAVATED, ON POLICE OFFICER, W/ GUN',
               '04083 - FIREARM,Â DISCHARGING IN GROSSLY NEGLIGENT MANNER',
               '04092 - ASSAULT, AGGRAVATED, W/ GUN',
               '04090 - ASSAULT, AGGRAVATED, W/ MACHINE GUN',
               '04091 - ASSAULT, AGGRAVATED, W/ SEMI AUTO',
               '04021 - ATTEMPTED HOMICIDE WITH A GUN',
               '02201 - ATTEMPTED RAPE WITH A GUN',
               '03441 - ATTEMPTED ROBBERY CHAIN STORE WITH A GUN',
               '03421 - ATTEMPTED ROBBERY COMM. ESTABLISHMENT WITH A GUN',
               '03461 - ATTEMPTED ROBBERY OF A BANK WITH A GUN',
               '03411 - ATTEMPTED ROBBERY ON THE STREET WITH A GUN',
               '03451 - ATTEMPTED ROBBERY RESIDENCE WITH A GUN',
               '03431 - ATTEMPTED ROBBERY SERVICE STATION WITH A GUN',
               '03471 - ATTEMPTED ROBBERY WITH A GUN',
               '60050 - ATTEMPTED SUICIDE BY FIREARMS',
               '03081 - CARJACKING WITH A GUN',
               '12026 - DISCHARGE FIREARM AT AN INHABITED DWELLING',
               '12027 - DISCHARGE FIREARM WITHIN CITY LIMITS',
               '19083 - FIREARM POSSESSION IN SCHOOL ZONE',
               '27122 - FIREARM WITH ALTERED IDENTIFICATION',
               '16780 - FIREARM, ARMED WHILE POSSESSING CONTROLLED SUBSTANCE',
               '12166 - FIREARM, CARRYING LOADED WITH INTENT TO COMMIT FELONY',
               '04084 - FIREARM, DISCHARGING AT OCCUPIED BLDG, VEHICLE, OR AIRCRAFT',
               '12168 - FIREARM, LOADED, IN VEHICLE, POSSESSION OR USE',
               '04080 - FIREARM, NEGLIGENT DISCHARGE',
               '12169 - FIREARM, POSSESSION OF WHILE WEARING MASK',
               '15154 - FIREARMS, SEIZING AT SCENE OF DV',
               '02001 - FORCIBLE RAPE, ARMED WITH A GUN',
               '28110 - MALICIOUS MISCHIEF, BREAKING WINDOWS WITH BB GUN',
               'MAYHEM WITH A GUN',
               '12080 - POSS OF FIREARM BY CONVICTED FELON/ADDICT/ALIEN',
               '12100 - POSS OF LOADED FIREARM',
               '30140 - POSSESSION OF AIR GUN',
               '12110 - POSSESSION OF MACHINE GUN',
               '03061 - ROBBERY OF A BANK WITH A GUN',
               '03041 - ROBBERY OF A CHAIN STORE WITH A GUN',
               '03021 - ROBBERY OF A COMMERCIAL ESTABLISHMENT WITH A GUN',
               '03051 - ROBBERY OF A RESIDENCE WITH A GUN',
               '03031 - ROBBERY OF A SERVICE STATION WITH A GUN',
               '03011 - ROBBERY ON THE STREET WITH A GUN',
               '03091 - ROBBERY,  ATM, GUN',
               '03491 - ROBBERY,  ATM, GUN, ATT.',
               '03071 - ROBBERY, ARMED WITH A GUN',
               '04081 - SHOOTING INTO INHABITED DWELLING OR OCCUPIED VEHICLE',
               'SUICIDE BY FIREARMS',
               '64072 - SUSPICIOUS OCCURRENCE, POSSIBLE SHOTS FIRED',
               '12140 - TAMPERING WITH MARKS ON FIREARM',
               '06386 - THEFT, GRAND, OF FIREARM',
               '12040 - VIOLATION OF RESTRICTIONS ON A FIREARM TRANSFER',
               '01001 - HOMICIDE WITH A GUN')

df <- Crime_type_dummies(gun_codes, df, INCIDENT_CODE, gun_incident)
dfOldData <- Crime_type_dummies(gun_codes, dfOldData, INCIDENT_CODE, gun_incident)

# Dummy for violent gun incident
gun_violence_codes <- c('01001 - HOMICIDE WITH A GUN', 
                        '04011 - AGGRAVATED ASSAULT WITH A GUN',
                        '04021 - ATTEMPTED HOMICIDE WITH A GUN', 
                        '04081 - SHOOTING INTO INHABITED DWELLING OR OCCUPIED VEHICLE',
                        '04090 - ASSAULT, AGGRAVATED, W/ MACHINE GUN',
                        '04092 - ASSAULT, AGGRAVATED, W/ GUN',
                        '04093 - ASSAULT, AGGRAVATED, ON POLICE OFFICER, W/ GUN',
                        '12026 - DISCHARGE FIREARM AT AN INHABITED DWELLING',
                        '12027 - DISCHARGE FIREARM WITHIN CITY LIMITS',
                        '04091 - ASSAULT, AGGRAVATED, W/ SEMI AUTO',
                        '64072 - SUSPICIOUS OCCURRENCE, POSSIBLE SHOTS FIRED')

df <- Crime_type_dummies(gun_violence_codes, df, INCIDENT_CODE, gun_violence_incident)
dfOldData <- Crime_type_dummies(gun_violence_codes, dfOldData, INCIDENT_CODE, gun_violence_incident)

# Dummy for property crime
property_codes <- c('RESIDENTIAL BURGLARY', 'AUTO BURGLARY', 'BURGLARY OTHER',
                    'LARCENY/THEFT', 'VEHICLE THEFT', 'ARSON')

df <- Crime_type_dummies(property_codes, df, Crime_Type, property_incident)
dfOldData <- Crime_type_dummies(property_codes, dfOldData, Crime_Type, property_incident)

# Dummy for violent incident
violence_codes <- c('ASSAULT', 'ROBBERY', 'SEX OFFENSES, FORCIBLE')

df <- Crime_type_dummies(violence_codes, df, Crime_Type, violent_incident)
dfOldData <- Crime_type_dummies(violence_codes, dfOldData, Crime_Type, violent_incident)

# Dummy for auto burglary
df <- Crime_type_dummies(AutoBurg_codes, df, INCIDENT_CODE, autoburg_incident)
dfOldData <- Crime_type_dummies(AutoBurg_codes, dfOldData, INCIDENT_CODE, autoburg_incident)

# Dummy for domestic violence 
DV_codes <- c('INFLICT INJURY ON COHABITEE', 'BATTERY, FORMER SPOUSE OR DATING RELATIONSHIP',
              'CHILD ABUSE (PHYSICAL)', 'CHILD, INFLICTING INJURY RESULTING IN TRAUMATIC CONDITION',
              'WILLFUL CRUELTY TO CHILD')

df <- Crime_type_dummies(DV_codes, df, INCIDENT_CODE, dv_incident)
dfOldData <- Crime_type_dummies(DV_codes, dfOldData, INCIDENT_CODE, dv_incident)

# Dummy for aggravated violence
AggViolence_codes <- c('ROBBERY, BODILY FORCE', 'ROBBERY, ARMED WITH A KNIFE', 'ROBBERY ON THE STREET WITH A DANGEROUS WEAPON',
                       'ROBBERY OF A CHAIN STORE WITH BODILY FORCE', 'ROBBERY OF A CHAIN STORE WITH A KNIFE',
                       'ATTEMPTED ROBBERY ON THE STREET W/DEADLY WEAPON', 'ROBBERY ON THE STREET, STRONGARM',
                       'CARJACKING WITH A KNIFE', 'ROBBERY, ARMED WITH A DANGEROUS WEAPON',
                       'ATTEMPTED ROBBERY ON THE STREET WITH BODILY FORCE', 'ROBBERY OF A CHAIN STORE WITH A DANGEROUS WEAPON',
                       'ROBBERY ON THE STREET WITH A KNIFE', 'ROBBERY,  ATM, FORCE, ATT.',
                       'CARJACKING WITH A DANGEROUS WEAPON', 'SHOPLIFTING, FORCE AGAINST AGENT',
                       'ROBBERY OF A RESIDENCE WITH BODILY FORCE', 'ATTEMPTED ROBBERY WITH A KNIFE',
                       'ROBBERY OF A SERVICE STATION WITH A KNIFE', 'ATTEMPTED ROBBERY SERVICE STATION W/BODILY FORCE',
                       'CARJACKING WITH BODILY FORCE', 'ATTEMPTED ROBBERY WITH BODILY FORCE',
                       'ROBBERY, VEHICLE FOR HIRE, ATT., W/ FORCE', 'ATTEMPTED ROBBERY RESIDENCE WITH A KNIFE',
                       'ATTEMPTED ROBBERY SERVICE STATION W/DEADLY WEAPON', 'ATTEMPTED ROBBERY CHAIN STORE WITH A KNIFE',
                       'ROBBERY, VEHICLE FOR HIRE, ATT., W/ OTHER WEAPON', 'ATTEMPTED ROBBERY OF A BANK WITH BODILY FORCE',
                       'ROBBERY OF A BANK WITH A DANGEROUS WEAPON', 'ATTEMPTED ROBBERY OF A BANK WITH A KNIFE',
                       'ATTEMPTED ROBBERY CHAIN STORE WITH DEADLY WEAPON', 'ATTEMPTED ROBBERY RESIDENCE WITH A DEADLY WEAPON',
                       'ATTEMPTED ROBBERY COMM. ESTAB. WITH DEADLY WEAPON', 'ATTEMPTED ROBBERY COMM. ESTABLISHMENT W/KNIFE',
                       'ROBBERY,  ATM, KNIFE, ATT.',"ROBBERY OF A BANK WITH BODILY FORCE", 'ROBBERY OF A BANK WITH A KNIFE',
                       'ATTEMPTED ROBBERY COMM. ESTAB. WITH BODILY FORCE', 'ROBBERY OF A COMMERCIAL ESTABLISHMENT W/ A KNIFE',
                       'ROBBERY OF A SERVICE STATION WITH BODILY FORCE', 'ATTEMPTED ROBBERY OF A BANK WITH A DEADLY WEAPON',
                       'ROBBERY OF A SERVICE STATION W/DANGEROUS WEAPON', 'ATTEMPTED ROBBERY SERVICE STATION WITH A KNIFE',
                       'ROBBERY,  ATM, KNIFE', 'ATTEMPTED ROBBERY RESIDENCE WITH BODILY FORCE',
                       'ATTEMPTED ROBBERY ON THE STREET WITH A KNIFE', 'ROBBERY,  ATM, OTHER WEAPON',
                       'ROBBERY OF A RESIDENCE WITH A DANGEROUS WEAPON', 'ROBBERY OF A RESIDENCE WITH A KNIFE',
                       'ATTEMPTED ROBBERY WITH A DEADLY WEAPON', 'ROBBERY OF A COMMERCIAL ESTABLISHMENT W/ WEAPON',
                       'ROBBERY OF A COMMERCIAL ESTABLISHMENT, STRONGARM', 'ATTEMPTED ROBBERY CHAIN STORE WITH BODILY FORCE',
                       
                       'AGGRAVATED ASSAULT WITH BODILY FORCE', 'BATTERY', 'ASSAULT',
                       'AGGRAVATED ASSAULT WITH A DEADLY WEAPON', 'BATTERY WITH SERIOUS INJURIES',
                       'ASSAULT WITH CAUSTIC CHEMICALS', 'ATTEMPTED SIMPLE ASSAULT',
                       'ASSAULT BY POISONING', 'ASSAULT ON A POLICE OFFICER WITH A DEADLY WEAPON',
                       'MAYHEM WITH A DEADLY WEAPON', 'MAYHEM WITH BODILY FORCE',
                       'ATTEMPTED HOMICIDE WITH A DANGEROUS WEAPON', 'MAYHEM WITH A KNIFE',
                       'AGGRAVATED ASSAULT ON POLICE OFFICER WITH A KNIFE', 'ATTEMPTED MAYHEM WITH A DEADLY WEAPON',
                       'AGGRAVATED ASSAULT WITH A KNIFE', 'ATTEMPTED HOMICIDE WITH BODILY FORCE', 
                       'ATTEMPTED MAYHEM WITH A KNIFE', "ASSAULT OR ATTEMPTED MURDER UPON GOV'T OFFICERS",
                       'ATTEMPTED MAYHEM WITH BODILY FORCE', 'BATTERY OF A POLICE OFFICER',
                       'ATTEMPTED HOMICIDE WITH A KNIFE', 'AGGRAVATED ASSAULT OF POLICE OFFICER,BODILY FORCE')

df <- Crime_type_dummies(AggViolence_codes, df, INCIDENT_CODE, aggr_violence_incident)
dfOldData <- Crime_type_dummies(AggViolence_codes, dfOldData, INCIDENT_CODE, aggr_violence_incident)

############################################################### 
##                Binding rows                             ##
###############################################################
df$INCIDENT_NUMBER <- as.numeric(df$INCIDENT_NUMBER)
df$DATE_OF_BIRTH <- as.character(df$DATE_OF_BIRTH)
df$TIME_OCCURRED_FROM <- as.numeric(df$TIME_OCCURRED_FROM)

dfSave <- bind_rows(df, dfOldData)

dfSave <- distinct(dfSave, UID, INCIDENT_CODE, INCIDENT_NUMBER, .keep_all = TRUE)

########################################
# Race and Sex columns
########################################
# Filling in missing data for a given UID
dfSave$RACE <- as.character(dfSave$RACE)
dfSave$RACE <- ifelse(dfSave$RACE == 'NULL', NA, dfSave$RACE)
dfSave <- dfSave %>% group_by(UID) %>% fill(RACE) %>% fill(RACE, .direction = 'up')

deconflictRows <- function(DF, columnToUse, NewCol1, x) {
  # Needed library
  library(lazyeval)
  
  # Setting up column names to use
  columnToUse <- deparse(substitute(columnToUse))
  NewCol1 <- deparse(substitute(NewCol1))
  
  # Creating new columns 
  DF[[NewCol1]] <- ifelse(DF[[columnToUse]] == x, 1, NA)
  DF <- DF %>% group_by_("UID") %>% fill_(NewCol1) %>% fill_(NewCol1, .direction = 'up')
  DF[[NewCol1]] <- ifelse(is.na(DF[[NewCol1]]), 0, DF[[NewCol1]])
  
  DF
}

# Male column
dfSave$SEX <- as.numeric(as.character(dfSave$SEX))
dfSave <- deconflictRows(dfSave, SEX, Male, 1)

# Race columns
dfSave <- deconflictRows(dfSave, RACE, Black, "B")
dfSave <- deconflictRows(dfSave, RACE, Hispanic, "H")
dfSave <- deconflictRows(dfSave, RACE, Asian, "A")
dfSave <- deconflictRows(dfSave, RACE, White, "W")

#
#
#
#
#
#
#
#
############################################################### 
##   Saving and reloading Data                               ##
###############################################################
# Saving the compiled data here to then go and hand clean the names as needed.
# Also add in GIS info of hot spot indicators.
# This part sucks.

write.csv(dfSave, '171101_Suspect_Data3.csv')

