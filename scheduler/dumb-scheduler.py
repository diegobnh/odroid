#!/usr/bin/env python3
import random

def main():
    while True:
        mkpi_str, bmiss_str, ipc_str, big_str, little_str = input().split()
        mkpi = float(mkpi_str)
        bmiss = float(bmiss_str)
        hasbig = bool(big_str)
        haslittle = bool(little_str)
        print(random.random())

if __name__ == "__main__":
    main()
