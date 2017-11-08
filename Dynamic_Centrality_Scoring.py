# Python version 2.7.13
# Title:  Arrest Network Analysis
# Author: Rory Pulvino
# Date:   August 4, 2017
# Info:   Analysis for the gang unit and FD. For the gang unit,
#         giving them the network of gun violence suspects, including a 
#         separate network with dead suspects removed. For FD, focusing 
#         on the network in Potrero Hill.

import sys as sys
import numpy as np
import pandas as pd
import networkx as nx
import matplotlib.pyplot as plt
import community
#import igraph as ig
import os

os.chdir('R:\\Gun Enforcement Unit\\Analyses\\SNA')
#os.chdir('E:\\SNA')
import SNA_Analysis as sna

#######################################################
###     Loading data                                ###
#######################################################\

dframe = pd.read_csv('170830_Suspect_Data5.csv')

#######################################################
###     Creating new function                       ###
#######################################################
### Chunking the data by date
## Starting with the first 2 years of data to establish baseline of network
dframe['DATE_OF_INCIDENT'].dtype
dframe['Incident_Date'] = pd.to_datetime(dframe['DATE_OF_INCIDENT']) # setting date column to date type
#dframe['date_of_death'] = pd.to_datetime(dframe['date_of_death']) # setting date column to date type
dframe['dob'] = pd.to_datetime(dframe['UID_DOB']) # Setting DOB column to date type

base_date = pd.to_datetime('2015-01-01')
base_data = dframe[(dframe['Incident_Date'] < base_date)] # first two years of data

# Setting the base graph
G_base = nx.Graph()

G_base.add_nodes_from(base_data['UID'], bipartite = 'suspects')
G_base.add_nodes_from(base_data['INCIDENT_NUMBER'], bipartite = 'incident')

G_base.add_edges_from(zip(base_data['UID'], base_data['INCIDENT_NUMBER']))

# Adding attributes to large graph that will allow for isolating nodes
suspect_attr_columns = ['UID_DOB', 'date_of_death', 'Male', 'Black', 'Hispanic', 'Asian', 
'dob', 'gang_charged', 'gang', 'cumulative_incidents', 'cumulative_gun_incidents', 
'cumulative_gun_v_incidents', 'cumulative_property_incidents', 'cumulative_gun_incidents', 
'cumulative_gun_v_incidents', 'cumulative_violent_incidents', 'cumulative_autoburg_incidents',
'cumulative_dv_incidents', 'cumulative_aggr_v_incidents', 'cumulative_TL_inc', 'cumulative_Br_inc',
'cumulative_AG_inc', 'cumulative_CBr_inc', 'cumulative_M24_inc', 'cumulative_M16_inc',
'cumulative_N_inc', 'cumulative_SD_inc', 'cumulative_Ho_inc', 'cumulative_PH_inc', 
'cumulative_CBa_inc', 'cumulative_BH_inc', 'gun_inc_within_year', 'gun_inc_next_year'] 

# Need to test this attribute addition to see if it add the most recent entry for
# the cumulative stats to then properly slice the data
sna.add_node_attribute(suspect_attr_columns, data = base_data, graph = G_base, data_index='UID')

# Creating unipartite base graph of suspects
suspect_list = [n for n, d in G_base.nodes(data = True) if d['bipartite'] == 'suspects']
G_base_suspect = nx.bipartite.projected_graph(G_base, nodes = suspect_list)

# Testing out addition of attributes
#df_test = pd.DataFrame(sna.move_graph_to_list(G_base_suspect)) 
#df_test_gun = df_test[(df_test['cumulative_gun_incidents'] > 0)]
#df_compare = base_data.drop_duplicates(subset = 'UID', keep = 'last')
#df_compare_gun = df_compare[(df_compare['cumulative_gun_incidents'] > 0)]
# According to this test, when attributes are added to the graph and if there are
# duplicate rows adding to the same node, but with different column values, the last
# column value is added. This fits for the purpose here.

## Setting lists of nodes of interest based on if an individual 
## had committed a gun or gun violence incident and those directly 
## connected to them
nodes_gun_suspects = [n for n, d in G_base_suspect.nodes(data = True) if d['cumulative_gun_incidents'] > 0]
nodes_gun_2nd = sna.get_nodes_and_nbrs(G_base_suspect, nodes_gun_suspects)
nodes_gun_3rd = sna.get_nodes_and_nbrs(G_base_suspect, nodes_gun_2nd)

nodes_gun_violence_suspects = [n for n, d in G_base_suspect.nodes(data = True) if d['cumulative_gun_v_incidents'] > 0]
nodes_gun_violence_2nd = sna.get_nodes_and_nbrs(G_base_suspect, nodes_gun_violence_suspects)
nodes_gun_violence_3rd = sna.get_nodes_and_nbrs(G_base_suspect, nodes_gun_violence_2nd)

# Going through the list of node lists of interest to
# pull out the largest component subgraph from each node list
G_1 = sna.get_largest_component_subgraph(G_base_suspect, nodes_gun_suspects)
G_2 = sna.get_largest_component_subgraph(G_base_suspect, nodes_gun_2nd)
G_3 = sna.get_largest_component_subgraph(G_base_suspect, nodes_gun_3rd)

G_4 = sna.get_largest_component_subgraph(G_base_suspect, nodes_gun_violence_suspects)
G_5 = sna.get_largest_component_subgraph(G_base_suspect, nodes_gun_violence_2nd)
G_6 = sna.get_largest_component_subgraph(G_base_suspect, nodes_gun_violence_3rd)

list_of_graphs = [G_1, G_2, G_3, G_4, G_5, G_6]

# Adding centrality measures to each of the graphs and subgraphs of interest 
#sna.add_centrality_measures_to_nodes(G_3, graph_type = 'component')
    
# Putting graphs into dataframe format
#df_test = pd.DataFrame(sna.move_graph_to_list(G_1))

#start = 0
# Renaming columns
#df_test.rename(columns = {'component_Betweenness_centrality' : 'G_base_' + str(start) + '_B_centrality',
#'component_Degree_centrality' : 'G_base_' + str(start) + '_D_centrality',
#'component_Eigen_centrality' : 'G_base_' + str(start) + '_E_centrality',
#'component_Closeness_centrality' : 'G_base_' + str(start) + '_C_centrality',
#'component_Katz_centrality' : 'G_base_' + str(start) + '_K_centrality'
#}, inplace = True)
    
# Renaming dataframe
#dfname = 'df_base_' +str(start)
#df_dict[dfname] = df_test

start = 0
df_dict = {}

for graph in list_of_graphs:
    # adding centrality measures to nodes from list of grpahs
    sna.add_centrality_measures_to_nodes(graph, graph_type = 'component')
    
    # Putting graphs into dataframe format
    df = pd.DataFrame(sna.move_graph_to_list(graph))
    
    # Renaming columns
    start = start + 1
    df.rename(columns = {'component_Betweenness_centrality' : 'Network_' + str(start) + '_B_centrality',
        'component_Degree_centrality' : 'Network_' + str(start) + '_D_centrality',
        'component_Eigen_centrality' : 'Network_' + str(start) + '_E_centrality',
        'component_Closeness_centrality' : 'Network_' + str(start) + '_C_centrality',
        'component_Katz_centrality' : 'Network_' + str(start) + '_K_centrality'
    }, inplace = True)
    
    # Renaming dataframe
    df_name = 'df_base_' + str(start)
    df_dict[df_name] = df


# Merging the dataframes back together based on UID
# Each UID should have a single row
base_df = df_dict['df_base_1']
df_dict.pop('df_base_1', None)
df_final = base_df

for key, value in df_dict.iteritems():
    df_final = pd.merge(df_final, value, on = ['Name', 'date_of_death', 'dob', 'UID_DOB',
    'gang_charged', 'gang', 'Male', 'Black', 'Hispanic', 'Asian', 'cumulative_TL_inc', 
    'cumulative_Br_inc', 'cumulative_AG_inc', 'cumulative_CBr_inc', 'cumulative_M24_inc', 
    'cumulative_M16_inc', 'cumulative_N_inc', 'cumulative_SD_inc', 'cumulative_Ho_inc', 
    'cumulative_PH_inc', 'cumulative_CBa_inc', 'cumulative_BH_inc', 'cumulative_incidents',
    'cumulative_property_incidents', 'cumulative_gun_incidents', 'cumulative_gun_v_incidents',
    'cumulative_violent_incidents', 'cumulative_autoburg_incidents', 'cumulative_dv_incidents',
    'cumulative_aggr_v_incidents','cumulative_gun_incidents', 'cumulative_gun_v_incidents',
    'gun_inc_within_year', 'gun_inc_next_year', 'bipartite'], how = 'outer')

# Adding a month indicator column
date_col = 'base'
df_final['Month'] = str(date_col)

# Adding an age column
df_final['Age'] = (base_date - df_final['dob']).astype('<m8[Y]')

#################################################
# WHAT I'M REALLY UNSURE OF...

## Chunking the network by month after the initial baseline to track
## dynamic centrality scores
def dynamic_centrality_scoring(data, start_date, end_date):
    '''Function that chunks a dataframe by month between the start and end dates. 
    Each chunk is transformed into various networkx graphs and centrality scores calculated.
    The graphs for each chunk are then returned as dataframes, merged, and added to a dictionary.'''
    
    # Setting up the time period to range over
    from datetime import datetime
    start = datetime.strptime(start_date, '%Y-%m-%d')
    stop = datetime.strptime(end_date, '%Y-%m-%d')
    
    # Month counter
    month_number = 0
    
    # Looping through the data to create graphs; calculate and add centrality scores;
    # pull graph out into a data frame; add data frame to a dictionary
    from dateutil.relativedelta import relativedelta
    while start <= stop:
        start = start + relativedelta(months = +1) # increase the date by a month
        # Need to start a month before you want data for since this iterator jumps forward one month
        
        # This takes the incidents that are less than a given date and who has not died
        #month_data = data[(data['DATE_OF_INCIDENT'] < start) & ((data['date_of_death'] > start) | (data['date_of_death'].isnull()))] # subsetting data
        # The date_of_death column is off it seems because of the way that the data is entered in CABLE. As
        # of now the police enter all victims in a homicide incident as homicide victims so this shows some
        # people as dead that are not dead.
        month_data = data[(data['Incident_Date'] < start)] # subsetting data
        
        # Setting the base graph
        G_month = nx.Graph()
        
        G_month.add_nodes_from(month_data['UID'], bipartite = 'suspects')
        G_month.add_nodes_from(month_data['INCIDENT_NUMBER'], bipartite = 'incident')
        
        G_month.add_edges_from(zip(month_data['UID'], month_data['INCIDENT_NUMBER']))
        
        # Adding attributes to large graph that will allow for isolating nodes
        suspect_attr_columns = ['UID_DOB', 'date_of_death', 'Male', 'Black', 'Hispanic', 'Asian', 
        'dob', 'gang_charged', 'gang', 'cumulative_incidents', 'cumulative_gun_incidents', 
        'cumulative_gun_v_incidents', 'cumulative_property_incidents', 'cumulative_gun_incidents', 
        'cumulative_gun_v_incidents', 'cumulative_violent_incidents', 'cumulative_autoburg_incidents',
        'cumulative_dv_incidents', 'cumulative_aggr_v_incidents', 'cumulative_TL_inc', 'cumulative_Br_inc',
        'cumulative_AG_inc', 'cumulative_CBr_inc', 'cumulative_M24_inc', 'cumulative_M16_inc',
        'cumulative_N_inc', 'cumulative_SD_inc', 'cumulative_Ho_inc', 'cumulative_PH_inc', 
        'cumulative_CBa_inc', 'cumulative_BH_inc', 'gun_inc_within_year', 'gun_inc_next_year'] 
        
        sna.add_node_attribute(suspect_attr_columns, data = month_data, graph = G_month, data_index='UID')
        
        # Creating unipartite base graph of suspects
        suspect_list = [n for n, d in G_month.nodes(data = True) if d['bipartite'] == 'suspects']
        G_month_suspect = nx.bipartite.projected_graph(G_month, nodes = suspect_list)
        
        ## Setting lists of nodes of interest based on if an individual 
        ## had committed a gun or gun violence incident and those directly 
        ## connected to them
        nodes_gun_suspects = [n for n, d in G_month_suspect.nodes(data = True) if d['cumulative_gun_incidents'] > 0]
        nodes_gun_2nd = sna.get_nodes_and_nbrs(G_month_suspect, nodes_gun_suspects)
        nodes_gun_3rd = sna.get_nodes_and_nbrs(G_month_suspect, nodes_gun_2nd)
        
        nodes_gun_violence_suspects = [n for n, d in G_month_suspect.nodes(data = True) if d['cumulative_gun_v_incidents'] > 0]
        nodes_gun_violence_2nd = sna.get_nodes_and_nbrs(G_month_suspect, nodes_gun_violence_suspects)
        nodes_gun_violence_3rd = sna.get_nodes_and_nbrs(G_month_suspect, nodes_gun_violence_2nd)
        
        # Going through the list of node lists of interest to
        # pull out the largest component subgraph from each node list
        G_1 = sna.get_largest_component_subgraph(G_month_suspect, nodes_gun_suspects)
        G_2 = sna.get_largest_component_subgraph(G_month_suspect, nodes_gun_2nd)
        G_3 = sna.get_largest_component_subgraph(G_month_suspect, nodes_gun_3rd)
        
        G_4 = sna.get_largest_component_subgraph(G_month_suspect, nodes_gun_violence_suspects)
        G_5 = sna.get_largest_component_subgraph(G_month_suspect, nodes_gun_violence_2nd)
        G_6 = sna.get_largest_component_subgraph(G_month_suspect, nodes_gun_violence_3rd)
        
        ####################
        # Need to figure out how to add these graphs to the list and then add
        # loop over them. Possible to maybe do a for loop earlier in the function
        # to do the looping? But need the while loop as a timing mechanism
        list_of_graphs = []
        list_of_graphs = [G_1, G_2, G_3, G_4, G_5, G_6]
        
        month_number = month_number + 1
        graph_number = 0
        dict_new = {}
        # Adding centrality measures to each of the graphs and subgraphs of interest
        for graph in list_of_graphs:
            #print str(len(graph)) + ' nodes of graph'
            
            # adding centrality measures to nodes from list of grpahs
            sna.add_centrality_measures_to_nodes(graph, graph_type = 'component')
            
            # Putting graphs into dataframe format
            df_new = pd.DataFrame(sna.move_graph_to_list(graph))
            
            #print str(start.year)
            # Renaming columns
            graph_number = graph_number + 1
            #print str(graph_number)
            
            df_new.rename(columns = {'component_Betweenness_centrality' :  'Network_' + str(graph_number) + '_B_centrality',
            'component_Degree_centrality' : 'Network_' + str(graph_number) + '_D_centrality',
            'component_Eigen_centrality' : 'Network_' + str(graph_number) + '_E_centrality',
            'component_Closeness_centrality' : 'Network_' + str(graph_number) + '_C_centrality',
            'component_Katz_centrality' : 'Network_' + str(graph_number) + '_K_centrality'
            }, inplace = True)
            
            
            # Dropping unneeded columns
            #df_new = df_new.drop(['date_of_death', 'cumulative_gun_incidents', 'cumulative_gun_v_incidents'], 
            #axis = 1)
            # Using these columns now to create a time series dataframe that has each suspect
            # by month, the suspects' cumulative incidents per month, and the suspects' 
            # centrality measures 
            
            # Need to figure out how to get the five dataframes from each month chunk
            # merged so that my dictionary is of dataframes that represent monthly slices
            # of centrality scores. Then I can merge those slices back with the full data based 
            # on date.
            
            # Renaming dataframe and adding to dictionary
            #df_name = 'df_' str(start.year) + str(start.month) + '_G_' + str(graph_number)
            #df_dict_month[df_name] = df_new
            df_name = 'df_' + str(graph_number)
            dict_new[df_name] = df_new
        
        # Merging the dataframes back together based on UID
        # Each UID should have a single row
        print dict_new.keys()
        
        df_month = dict_new.pop('df_3', None)
        
        print 'Done with creating dataframes for ' + str(start.year) + '-' + str(start.month)
        
        for key, value in dict_new.iteritems():
            print str(len(value))
            
            df_month = pd.merge(df_month, value, on = ['Name', 'date_of_death', 'dob', 'UID_DOB',
            'gang_charged', 'gang', 'Male', 'Black', 'Hispanic', 'Asian', 'cumulative_TL_inc', 
            'cumulative_Br_inc', 'cumulative_AG_inc', 'cumulative_CBr_inc', 'cumulative_M24_inc', 
            'cumulative_M16_inc', 'cumulative_N_inc', 'cumulative_SD_inc', 'cumulative_Ho_inc', 
            'cumulative_PH_inc', 'cumulative_CBa_inc', 'cumulative_BH_inc', 'cumulative_incidents',
            'cumulative_property_incidents', 'cumulative_gun_incidents', 'cumulative_gun_v_incidents',
            'cumulative_violent_incidents', 'cumulative_autoburg_incidents', 'cumulative_dv_incidents',
            'cumulative_aggr_v_incidents','cumulative_gun_incidents', 'cumulative_gun_v_incidents',
            'gun_inc_within_year', 'gun_inc_next_year', 'bipartite'], how = 'outer')
        
        print 'number of persons in the dataframe ' + str(len(df_month))
        
        # Adding Month indicator 
        date_col = str(start.year) + '-' + str(start.month)
        df_month['Month'] = str(date_col)
        
        # Adding an age column based on the month
        df_month['Age'] = (start - df_month['dob']).astype('<m8[Y]')
        
        # Adding df_month to dictionary of dataframes
        df_month_scores = 'df_' + str(start.year) + '-' + str(start.month)
        df_dict_month[df_month_scores] = df_month
        
        print 'Added ' + str(start.year) + '-' + str(start.month) + ' dataframe to dictionary'
    
    return df_dict_month
    
# Creating an empty dictionary
df_dict_month = {}

# running function
dynamic_centrality_scoring(dframe, '2014-12-31', '2017-08-28')

# Merging dataframes from dictionary to create final dataframe
df_final2 = df_final

for key, value in df_dict_month.iteritems():
    print 'Binding ' + str(key) + ' to the data frame'
    
    df_final2 = df_final2.append(value, ignore_index = True)
    
### Saving final dataframe

df_final2.to_csv('df_network_170830.csv', sep = ',')