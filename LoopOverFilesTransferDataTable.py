#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Oct 16 12:27:34 2017

@author: Anthony Yorita
"""

#LoopOverFilesTransferDataTable
import os
import docx
import re
import openpyxl
import transferDataTableMultipleFiles
NumberOfRows = 2
# For windows the format will be in - > C:\\Users\\asweigart
# Need to locate the correct directory/file
# os.chdir format for windows is C:\\Users\\... it needs to two backslashes
# wheras mac needs 1 forward slash (/)
#
#os.chdir('/Users/Gesetze/documents/Data_Science_Internship/Files_To_Transfer')
os.chdir('F:\\NIBN_Leads_oRIGINAL') # for windows
#print(os.getcwd())

# for wbLoad, same as the top, make sure the format excel file is already created
# all the variables need to be on row 1

# wbLoad needs a template excel file
# Below for test files
wbLoad = 'C:\\Script\\Ice_Cream\\NLN.xlsx'

#wbLoad = 'F:\\NIBN_Leads\\Lead_TEST_DocumentVersion3.xlsx'
total_files = 0
total_files_errors = 0.0
file_errors_list = []
# change os.listdir depending on where the file is
#for filename in os.listdir('/Users/Gesetze/documents/Data_Science_Internship/Files_To_Transfer'):
for filename in os.listdir('F:\\NIBN_Leads_oRIGINAL'):
#for filename in os.listdir('F:\\NIBN_Leads'):
    if filename.endswith('.docx') and '~' not in filename:

        try: # print(os.path.join(directory, filename))
            # print(filename)

            #workbook to load
            executeFile = transferDataTableMultipleFiles.transferData(filename, NumberOfRows, wbLoad)
            #print(executeFile)
            wbLoad = executeFile[1]
            NumberOfRows = NumberOfRows + int(executeFile[0] - 1)
            print(filename)
        except Exception as e:
            print('There is an error at file :' + filename)
            print(e)
            total_files_errors += 1
            #file_errors_list.append(filename)
            #break
    total_files += 1
print('There were ' + str(total_files_errors) + ' files that had errors')
print('Total completed rate: ' + str((total_files - total_files_errors)/ total_files))
        #break # just one file test
    #continue # *&*&*&* CHANGE THIS IF NEED BE
