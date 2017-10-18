#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Oct 16 10:03:55 2017

@author: Anthony Yorita
"""
import docx
import re
import openpyxl
# 2nd Script Gather All Data by Table
#***def transferDataTable(filename, NumberOfRows, wbLoad):
    #****document = docx.Document(filename)
#document = docx.Document('/Users/Gesetze/Documents/Data_Science_Internship/Files_To_Transfer/17-077.docx')

def transferData(filename, NumberOfRows, wbLoad):
    document = docx.Document(filename)

        # Uncomment (remove # in front of line) below if you desire to know the
        # number of tables in the word file
        # print(len(document.tables))


        # Data will be a list of rows represented as dictionaries or tuples
        # containing each row's data.
    data = []
    table_list = []
    allText = ''
    for table in document.tables: #document.tables are the tables objects
        allText = ''
        keys = None
        for i, row in enumerate(table.rows):
            text = (cell.text for cell in row.cells)
            for cell in row.cells:
                allText = allText + cell.text
           # allText = allText + str(text)
            # Establish the mapping based on the first row
            # headers; these will become the keys of our dictionary
            if i == 0:
                keys = tuple(text)
                continue

            # Construct a dictionary(or append a tuple) for this row, mapping
            # keys to values for this row

            row_data = tuple(text)
            #allText = allText + str(row_data)
            data.append(row_data)
        table_list.append(allText)
    #print(allText)
    #print(table_list[0]) # prints only the first table

    # all Regexes
    # ^ and $ aren't working because it means whatever the string starts with
    # not whether there is a ^WSP in the STRING!!!'

    # not from table
    #dateRegex = re.compile(r'\d\d-\d\d-\d\d|\d-\d-\d\d|\d\d-\d-\d\d|\d-\d\d-\d\d')
    dateRegex = re.compile(r'\d\d(-|/)?\d\d(-|/)?\d\d|\d(-|/)?\d(-|/)?\d\d|\d\d(-|/)?\d(-|/)?\d\d|\d(-|/)?\d\d(-|/)?\d\d')
    nibinRegex = re.compile(r'\d\d-\d\d\d')


    WSP_case_number_Regex = re.compile(r'(WSP case number)(.*)(Case Number)')
    Case_Number_regex = re.compile(r'(Case Number)(.*)(Exhibit Number)')
    Exhibit_regex = re.compile(r'(Exhibit Number)(.*)(Offense)')
    Offense_regex = re.compile(r'(Offense)(.*)(Evidence)')
    Evidence_regex = re.compile(r'(Evidence)(.*)(Date)')
    Date_regex = re.compile(r'(Date)(.*)(Location)')
    Location_regex = re.compile(r'(Location)(.*)(Agency)')
    Agency_regex = re.compile(r'(Agency)(.*)(Assigned Detective)')
    AD_regex = re.compile(r'(Assigned Detective)(.*)(Contact info)')
    Contact_regex = re.compile(r'(Contact info)(.*)')
    """
    mo_WSP = WSP_case_number_Regex.search(table_list[0])
    mo_Case = Case_Number_regex.search(table_list[0])
    mo_Exhibit = Exhibit_regex.search(table_list[0])
    mo_Offense = Offense_regex.search(table_list[0])
    mo_Date = Date_regex.search(table_list[0])
    mo_Location = Location_regex.search(table_list[0])
    mo_Agency = Agency_regex.search(table_list[0])
    mo_AD = AD_regex.search(table_list[0])
    mo_Contact = Contact_regex.search(table_list[0])
    """

    #mo.group(0) prints all group. Starts at group(1), group(2)...
    #print(mo_Case.group(2))
    """
    print(mo_WSP.group(2))
    print(mo_Case.group(2))
    print(mo_Exhibit.group(2))
    print(mo_Offense.group(2))
    print(mo_Date.group(2))
    print(mo_Location.group(2))
    print(mo_Agency.group(2))
    print(mo_AD.group(2))
    print(mo_Contact.group(2))
    """

    stringWord = ''

    #takes all paragraphs and put them into one string for data and NIBIN
    for line in document.paragraphs:
        if '_sre.SRE_Match' not in line.text:
            stringWord = stringWord + line.text
    mo = dateRegex.search(stringWord)
    moNibin = nibinRegex.search(stringWord)
    #print(mo.group())
    #print(moNibin.group())

    #  NumberOfRows = 2 #***** TAKE THIS OUT FOR FUNCTION!!!
    #leftSide = 'C' + str(NumberOfRows)
    #rightSide = 'L' + str(NumberOfRows + len(document.tables))
    #leftSideRegex = 'A' + str(NumberOfRows)
    #rightSideRegex = 'B' + str((NumberOfRows) + len(document.tables) - 2)

    #print(leftSideRegex)
    #print(rightSideRegex)

    # Adding table values to excel sheet
    # value is just for the column[x], it just goes to next
    # value in the sorted_data

    # WRITING TO EXCEL PORTION
    # Column A in excel will be date of investigation, B will be the NIBIN,
    # C will be WSP case number,... and so on until L being Contact INfo
    # wbLoad is the excel workbook being loaded
    # sheet is the only sheet in the workbook, can specify more
    wb = openpyxl.load_workbook(wbLoad)
    sheet = wb.get_sheet_by_name('Sheet1')

    """
    for i in range(len(document.tables) - 1):#range(2):
        mo_WSP = WSP_case_number_Regex.search(table_list[i])
        mo_Case = Case_Number_regex.search(table_list[i])
        mo_Exhibit = Exhibit_regex.search(table_list[i])
        mo_Offense = Offense_regex.search(table_list[i])
        mo_Date = Date_regex.search(table_list[i])
        mo_Location = Location_regex.search(table_list[i])
        mo_Agency = Agency_regex.search(table_list[i])
        mo_AD = AD_regex.search(table_list[i])
        mo_Contact = Contact_regex.search(table_list[i])
        print(mo_Case.group(2))
    """
    #print(sheet.cell(row = 1, column = 2))
    # to get cell do sheet.cell(row = x, column = y)
    # to get cell value do sheet.cell(row = x, column = y).value
    """
    value = 0
    for rowOfCellObjects in sheet[leftSide : rightSide]:
        for cellObj in rowOfCellObjects:
            #print(cellObj)
            #if value > len(sorted_data) - 1:
            #    break
            #else:
            #cellObj.value = sorted_data[value]
            value += 1
    """
    for i in range(len(document.tables) - 1):
        # those two don't work because they are not in the table,
        # other code for mo and moNibin is above
       # mo = dateRegex.search(table_list[i])
        #moNibin = nibinRegex.search(table_list[i])
        mo_WSP = WSP_case_number_Regex.search(table_list[i])
        mo_Case = Case_Number_regex.search(table_list[i])
        mo_Exhibit = Exhibit_regex.search(table_list[i])
        mo_Offense = Offense_regex.search(table_list[i])
        mo_Evidence = Evidence_regex.search(table_list[i])
        mo_Date = Date_regex.search(table_list[i])
        mo_Location = Location_regex.search(table_list[i])
        mo_Agency = Agency_regex.search(table_list[i])
        mo_AD = AD_regex.search(table_list[i])
        mo_Contact = Contact_regex.search(table_list[i])
        # then input in
        regex_list = [mo, moNibin, mo_WSP, mo_Case, mo_Exhibit, mo_Offense,
                      mo_Evidence, mo_Date, mo_Location, mo_Agency, mo_AD,
                      mo_Contact]
        # Have to enter these manually since they are different than the rest
        # they don't have multiple groups in regex

        if (mo != None):
            sheet.cell(row= NumberOfRows + i, column= 1, value=mo.group())
        else :
            sheet.cell(row = NumberOfRows + i, column = 1, value = '')
        if (moNibin != None):
            sheet.cell(row= NumberOfRows + i, column=2, value=moNibin.group())
        else:
            sheet.cell(row = NumberOfRows + i, column = 2, value = '')

        columnNumber = 3
        for regex in range(2, len(regex_list)):
            if regex_list[regex] != None and regex_list[regex]!= mo and regex_list[regex] != moNibin:
                sheet.cell(row = NumberOfRows + i, column = columnNumber, value = regex_list[regex].group(2))
            else:
                sheet.cell(row = NumberOfRows + i, column = columnNumber, value = '')

            columnNumber = columnNumber + 1
        sheet.cell(row= NumberOfRows + i, column= 13, value=filename)
        """
        sheet.cell(row= NumberOfRows + i, column=1, value=mo.group())
        sheet.cell(row= NumberOfRows + i, column=2, value=moNibin.group())
        sheet.cell(row= NumberOfRows + i, column=3, value=mo_WSP.group(2))
        sheet.cell(row= NumberOfRows + i, column=4, value=mo_Case.group(2))
        sheet.cell(row= NumberOfRows + i, column=5, value=mo_Exhibit.group(2))
        sheet.cell(row= NumberOfRows + i, column=6, value=mo_Offense.group(2))
        sheet.cell(row= NumberOfRows + i, column=7, value=mo_Evidence.group(2))
        sheet.cell(row= NumberOfRows + i, column=8, value=mo_Date.group(2))
        sheet.cell(row= NumberOfRows + i, column=9, value=mo_Location.group(2))
        sheet.cell(row= NumberOfRows + i, column=10, value=mo_Agency.group(2))
        sheet.cell(row= NumberOfRows + i, column=11, value=mo_AD.group(2))
        sheet.cell(row= NumberOfRows + i, column=12, value=mo_Contact.group(2))
        print(sheet.cell(row= 2, column = 1).value)
        """
            #print(sheet.cell(row = 2, column = 1).value)



    wb.save('C:\\Script\\Ice_Cream\\KCNIBNRealTest.xlsx')
    tupe1 = (len(document.tables), 'C:\\Script\\Ice_Cream\\KCNIBNRealTest.xlsx')
    return tupe1
