CXX ?= clang++
CXXFLAGS ?= -std=c++17 -O3 -Wall -Wextra -pthread

SRC = main.cpp
HEADERS = LoopingValue.hpp LoopingAST.hpp LoopingPythonBridge.hpp LoopingParser.hpp LoopingInterpreter.hpp LoopingREPL.hpp

TARGET = ../../bin/looping
LOCAL_TARGET = looping

all: $(TARGET) $(LOCAL_TARGET)

$(TARGET): $(SRC) $(HEADERS)
	@mkdir -p ../../bin
	$(CXX) $(CXXFLAGS) -I. $(SRC) -o $(TARGET)
	@echo "Built: $(TARGET)"

$(LOCAL_TARGET): $(SRC) $(HEADERS)
	$(CXX) $(CXXFLAGS) -I. $(SRC) -o $(LOCAL_TARGET)
	@echo "Built: $(LOCAL_TARGET)"

clean:
	rm -f $(LOCAL_TARGET) $(TARGET)

.PHONY: all clean
