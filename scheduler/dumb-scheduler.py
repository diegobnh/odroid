#!/usr/bin/env python3
import random
from sklearn.externals import joblib

def main():

    model = joblib.load("DecisionTreeRegressor_model.sav") # Load "model.pkl"

    while True:
        mkpi_str, bmiss_str, ipc_str, big_str, little_str = input().split()
        mkpi = float(mkpi_str)
        bmiss = float(bmiss_str)
        ipc = float(ipc_str)
        hasbig = bool(big_str)
        haslittle = bool(little_str)
        #print(random.random())
        print(model.predict([[mpki, bmiss, ipc, hasbig, haslittle]])[0])

if __name__ == "__main__":
    main()
