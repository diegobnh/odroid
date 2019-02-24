#!/usr/bin/env python3
import sys
import random
from sklearn.externals import joblib

def main():

    #model = joblib.load("Linear_Regression.pkl")
    model = joblib.load("Decision_Tree_Regressor.pkl")
    #model = joblib.load("Gradiente_Boosting_Regressor.pkl")
    print(model.predict([[0.000011,0.085019,0.498491,1,0]])[0])
'''
    while True:
        mpki_str, bmiss_str, ipc_str, big_str, little_str = input().split()
        mpki = float.fromhex(mpki_str)
        bmiss = float.fromhex(bmiss_str)
        ipc = float.fromhex(ipc_str)
        hasbig = bool(int(big_str))
        haslittle = bool(int(little_str))
        #print(random.random())
        print(model.predict([[mpki, bmiss, ipc, hasbig, haslittle]])[0])
'''
if __name__ == "__main__":
    main()
