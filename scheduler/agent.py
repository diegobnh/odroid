#!/usr/bin/env python3
import sys
from random import randint

THRESHOLD = 150

def main():

    initial_state = -1;
    flag = 1;
 
    while True:
        pmu1_str, pmu2_str, pmu3_str, cpu_usage_little_str, cpu_usage_big_str, state_str, exec_time_str = input().split()

        pmu1 = float.fromhex(pmu1_str)
        pmu2 = float.fromhex(pmu2_str)
        pmu3 = float.fromhex(pmu3_str)
        cpu_usage_little  = float.fromhex(cpu_usage_little_str)
        cpu_usage_big  = float.fromhex(cpu_usage_big_str)
        current_state = int(state_str)
        exec_time_str = float(exec_time_str)

        if current_state == -1:
            assert pmu1 == 0.0
            assert pmu2 == 0.0
            assert pmu3 == 0.0
            assert cpu_usage_little == 0.0
            assert cpu_usage_bit == 0.0
            # This is the end of a episode
            print(current_state) # the result does not matter, but it is necessary
            continue

        if ((cpu_usage_little + cpu_usage_big) < THRESHOLD and flag == 1): #Probability in sequencial phase
            initial_state = current_state
            flag = 0
            print(3) #means 2big in enum State 
        elif ((cpu_usage_little + cpu_usage_big) > THRESHOLD and flag == 0):  #Probability there is more than one thread working   
            current_state = initial_state
            print(current_state)
            flag = 1
        else:
            print(current_state)


        #print(randint(0, 23))#range to State enum


if __name__ == "__main__":
    main()

