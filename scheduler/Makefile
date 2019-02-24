CXXFLAGS += -std=c++14 -O2 -pedantic -Wall -Wextra -Wno-unused-parameter -Wno-unused-variable -Wno-unused-function
INCLUDE += 

SRC_FILES = src/main.cpp src/perf.cpp

all: build

build:
	mkdir -p bin
	$(CXX) $(CXXFLAGS) $(INCLUDE) $(SRC_FILES) -o bin/scheduler-collect -DSCHEDULER_TYPE=0
	$(CXX) $(CXXFLAGS) $(INCLUDE) $(SRC_FILES) -o bin/scheduler-predict -DSCHEDULER_TYPE=1
	$(CXX) $(CXXFLAGS) $(INCLUDE) $(SRC_FILES) -o bin/scheduler-agent -DSCHEDULER_TYPE=2

