CXX ?= clang++
CXXFLAGS ?= -std=c++17 -O3 -Wall -Wextra -pthread

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    ARCH_FLAGS ?= -arch arm64 -arch x86_64
else
    ARCH_FLAGS ?=
endif

SRC = main.cpp
HEADERS = LoopingValue.hpp LoopingAST.hpp LoopingCompiler.hpp LoopingPythonBridge.hpp LoopingParser.hpp LoopingInterpreter.hpp LoopingREPL.hpp

TARGET = ../../bin/looping
LOCAL_TARGET = looping

all: $(LOCAL_TARGET) $(TARGET)

$(LOCAL_TARGET): $(SRC) $(HEADERS)
	$(CXX) $(CXXFLAGS) $(ARCH_FLAGS) -I. $(SRC) -o $(LOCAL_TARGET)
	@echo "Built: $(LOCAL_TARGET)"

$(TARGET): $(LOCAL_TARGET)
	@-mkdir -p ../../bin 2>/dev/null && cp $(LOCAL_TARGET) $(TARGET) 2>/dev/null || true
	@echo "Copied to: $(TARGET)"

clean:
	@rm -f $(LOCAL_TARGET)
	@-rm -f $(TARGET) 2>/dev/null || true

.PHONY: all clean
