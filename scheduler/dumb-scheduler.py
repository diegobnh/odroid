#!/usr/bin/env python3
import sys
import random
from sklearn.externals import joblib

def main():

    model = joblib.load("DecisionTreeRegressor_model.sav") # Load "model.pkl"

    while True:
        mkpi_str, bmiss_str, ipc_str, big_str, little_str = input().split()
        mkpi = float.fromhex(mkpi_str)
        bmiss = float.fromhex(bmiss_str)
        ipc = float.fromhex(ipc_str)
        hasbig = bool(int(big_str))
        haslittle = bool(int(little_str))
        #print(random.random())
        print(model.predict([[mkpi, bmiss, ipc, hasbig, haslittle]])[0])

if __name__ == "__main__":
    main()
