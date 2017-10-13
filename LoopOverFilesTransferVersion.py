#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Oct 12 19:10:13 2017

@author: Gesetze
"""
import os
import docx
import re
import openpyxl
import transferDataFinalCleanVersion # this also returns the number of tables in file
# need to know tables to know how far to go down

#print(os.getcwd())
NumberOfRows = 2
# For windows the format will be in - > C:\\Users\\asweigart
# Need to locate the correct directory/file 
# os.chdir format for windows is C:\\Users\\... it needs to two backslashes
# wheras mac needs 1 forward slash (/)
# 
#os.chdir('/Users/Gesetze/documents/Data_Science_Internship/Files_To_Transfer')
os.chdir('F:\\NIBN_Leads') # for windows
#print(os.getcwd())

# for wbLoad, same as the top, make sure the format excel file is already created
# all the variables need to be on row 1

# wbLoad needs a template excel file 
# Below for test files
#wbLoad = '/Users/Gesetze/documents/Data_Science_Internship/NLN.xlsx'

wbLoad = 'F:\\NIBN_Leads\\Lead_TEST_DocumentVersion3.xlsx'

# change os.listdir depending on where the file is 
#for filename in os.listdir('/Users/Gesetze/documents/Data_Science_Internship/Files_To_Transfer'):
    
for filename in os.listdir('F:\\NIBN_Leads'):
    if filename.endswith('.docx') and '~' not in filename:
        # print(os.path.join(directory, filename))
        # print(filename)
        
        #workbook to load
        executeFile = transferDataFinalCleanVersion.transferData(filename, NumberOfRows, wbLoad)
        # print(executeFile)
        wbLoad = executeFile[1]
        NumberOfRows = NumberOfRows + int(executeFile[0] - 1)
    #continue
    