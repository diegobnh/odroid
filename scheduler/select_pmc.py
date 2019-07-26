import numpy as np 
import pandas as pd
from sklearn import model_selection
from sklearn.linear_model import ElasticNet      
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.neighbors import KNeighborsRegressor
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import GridSearchCV
from sklearn.externals import joblib
from numpy.random import seed
from sklearn.metrics import r2_score
import sys

g_Tunning="False"


headers_big = ['ins_exec_soft','l1_inst_cache_refill','l1_inst_cache_tlb_refill','l1_d_cache_refill','l1_d_cache_access','l1_data_tlb_refill','ins_exec','excep_taken','ins_exec_except','ins_exec_context','mispred_branch','pred_branch','data_mem_access','l1_inst_cache_access','l1_d_cache_write','l2_d_cache_access','l2_d_cache_refill','l2_d_cache_write','bus_access','local_mem_error','inst_espec_exec','inst_exec','bus_cycle','l1_d_cache_access_read','l1_d_cache_access_write','l1_d_cache_refill_read','l1_d_cache_refill_write','l1_d_cache_writeback_victim','l1_d_cache_writeback_clean','l1_d_cache_inv','l1_d_tlb_refill_read','l1_d_tlb_refill_write','l2_d_cache_access_read','l2_d_cache_access_write','l2_d_cache_refill_read','l2_d_cache_refill_write','l2_d_cache_writeback_victim','l2_d_cache_writeback_clean','l2_d_cache_inv','bus_access_read','bus_access_write','bus_access_norm1','bus_access_not_norm','bus_access_norm2','bus_access_perip','data_mem_access_read','data_mem_access_write','un_access_read','un_access_write','un_access','ldrex','strex_pass','strex_fail','load','store','load_or_store','integer_proc','simd','vfp','change_pc','branch_esp_imm','branch_esp_proc','branch_esp_ind','barrier_isb','barrier_dsb','barrier_dmb']

headers_little = ['inst_fetch_refill','inst_fetch_tlb_refill','data_read_write_refill','data_read_write_refill','data_read_write_tlb_refill','data_read_exec','data_write_exec','ins_exec','excep_taken','excep_exec','context_retir','change_pc','imed_branch_exec','proc_return','un_load_store','branch_predic','branch','data_mem_access','inst_cache_access','data_cache_evic','l2_data_cache_access','l2_data_cache_refill','l2_data_cache_write','bus_access','bus_cycle','bus_access_read','bus_access_write','irq_excep','fiq_excep','ext_mem_req','no_cache_ext_mem_req','linefill','prefetch','enter_read_alloc_mode','read_alloc_mode','reserved','etm_0','etm_1','data_write_stalls','data_snooped']



fileName = sys.argv[1]

dataframe = pd.read_csv(fileName, header=None)# Estou pegando apenas os valores.       (..,names=headers_big) 
array = dataframe.values

#parte1 = array[:,[0,3]] #ipc or cyclos
#parte2 = array[:,[5]] #ipc or cyclos
#parte1 = np.concatenate((parte1, parte2), axis=1) 
#print(parte1)
best_score=-1
best_index = 1
select_pmus = array[:,[6]] #ipc para big 
#select_pmus = array[:,7] #ipc para little 

index_pmus_select = []
index_pmus_select.append(6)

for pmus_select in range(6):#6 pmc for big
     
     for i in range (1, len(headers_big)-1):
 
         models = [("Linear_Regression", LinearRegression())]
         
         
         if i not in index_pmus_select:
            
            column = array[:,[i]] #seleciona a coluna a ser testada            
            X = np.concatenate((select_pmus, column), axis=1) #concatena com os atuais pmus
            Y = array[:, (len(headers_big) - 1)]                               
            
            for name, model in models:
                model = model
                model.fit(X, Y)

            current_score = model.score(X,Y)              
         
            if current_score > best_score:
               best_score = current_score
               best_index = i
               print("Fase:",pmus_select, " Index:",best_index," Score:",best_score)
               #input("Pressione <enter> para continuar")
            
     #Após testar todos os restantes pmus, adiciona na lista o pmus que melhor contribuiu para o aprendizado    
     
     index_pmus_select.append(best_index)
     column = array[:,[best_index]] 
     select_pmus = np.concatenate((select_pmus, column), axis=1) 

print(index_pmus_select)

