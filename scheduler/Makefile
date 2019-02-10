CXXFLAGS += -std=c++14 -O2 -pedantic -Wall -Wextra -Wno-unused-parameter
INCLUDE += 

SRC_FILES = src/main.cpp src/perf.cpp

all: build

build:
	mkdir -p bin
	$(CXX) $(CXXFLAGS) $(INCLUDE) $(SRC_FILES) -o bin/scheduler

