#!/usr/bin/env python3
import sys
import random

def main():
    while True:
        mkpi_str, bmiss_str, ipc_str = input().split()
        mkpi = float.fromhex(mkpi_str)
        bmiss = float.fromhex(bmiss_str)
        ipc = float.fromhex(ipc_str)
        print(random.choice(["4L", "4B", "4B4L"]))

if __name__ == "__main__":
    main()
