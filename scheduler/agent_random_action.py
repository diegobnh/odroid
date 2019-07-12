#!/usr/bin/env python3
import sys
from random import randint

actions = [3,7,23]

def main():

    while True:
        l_p1,l_p2,l_p3,l_p4,l_p5,b_p1,b_p2,b_p3,b_p4,b_p5,b_p6,b_p7,cpu_migrat,cont_switch,usage_little,usage_big,state,exec_time = input().split()

        print(actions[randint(0, 2)])


if __name__ == "__main__":
    main()

