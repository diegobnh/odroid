#!/usr/bin/env python3
import sys
import random
from sklearn.externals import joblib


THRESHOLD = 120

def main():

    initial_state = -1;
    flag = 1;
 
    while True:
        pmu1_str, pmu2_str, pmu3_str, cpu_usage_str, state_str = input().split()

        pmu1 = float.fromhex(pmu1_str)
        pmu2 = float.fromhex(pmu2_str)
        pmu3 = float.fromhex(pmu3_str)
        cpu_usage  = float.fromhex(cpu_usage_str)
        current_state = int(state_str)

                        
        if (cpu_usage < THRESHOLD and flag == 1): #Probability in sequencial phase                                               
            initial_state = current_state
            flag = 0
            print(5) #means 2big in enum State 
        elif (cpu_usage > THRESHOLD and flag == 0):  #Probability there is more than one thread working   
            current_state = initial_state
            print(current_state)
            flag = 1
        
        #print(random.randint(0, 23))#range to State enum

if __name__ == "__main__":
    main()
