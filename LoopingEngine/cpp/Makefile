ifeq ($(OS),Windows_NT)
    CXX ?= g++
    EXE_EXT = .exe
    ARCH_FLAGS ?=
else
    CXX ?= clang++
    EXE_EXT =
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Darwin)
        ARCH_FLAGS ?= -arch arm64 -arch x86_64
        MAC_SRCS = LoopingMacWindow.mm LoopingAsmCore.S
        MAC_OBJS = LoopingMacWindow.o LoopingAsmCore.o
        MAC_LDFLAGS = -framework Cocoa -framework CoreGraphics -framework Foundation
    else
        ARCH_FLAGS ?=
        MAC_SRCS =
        MAC_OBJS =
        MAC_LDFLAGS =
    endif
endif

CXXFLAGS ?= -std=c++17 -O3 -Wall -Wextra -pthread

SRC = main.cpp
HEADERS = LoopingValue.hpp Looping3D.hpp LoopingAST.hpp LoopingDirectXWindow.hpp LoopingMacWindow.hpp LoopingStage.hpp LoopingCompiler.hpp LoopingPythonBridge.hpp LoopingCSharpBridge.hpp LoopizeCore.hpp LoopingParser.hpp LoopingInterpreter.hpp LoopingREPL.hpp

ifneq ($(wildcard ../Makefile),)
    TARGET = ../bin/looping$(EXE_EXT)
else
    TARGET = ../../bin/looping$(EXE_EXT)
endif
LOCAL_TARGET = looping$(EXE_EXT)

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

all: $(LOCAL_TARGET) $(TARGET)

LoopingMacWindow.o: LoopingMacWindow.mm LoopingMacWindow.hpp LoopingDirectXWindow.hpp
	$(CXX) $(CXXFLAGS) -fobjc-arc $(ARCH_FLAGS) -I. -c LoopingMacWindow.mm -o LoopingMacWindow.o

LoopingAsmCore.o: LoopingAsmCore.S
	$(CXX) $(ARCH_FLAGS) -c LoopingAsmCore.S -o LoopingAsmCore.o

$(LOCAL_TARGET): $(SRC) $(HEADERS) $(MAC_OBJS)
	@rm -f $(LOCAL_TARGET)
	$(CXX) $(CXXFLAGS) $(ARCH_FLAGS) -I. $(SRC) $(MAC_OBJS) $(MAC_LDFLAGS) -o $(LOCAL_TARGET)
	@if command -v codesign >/dev/null 2>&1; then codesign -s - --force $(LOCAL_TARGET) >/dev/null 2>&1 || true; fi
	@echo "Built: $(LOCAL_TARGET)"

$(TARGET): $(LOCAL_TARGET)
	@-mkdir -p $(dir $(TARGET)) 2>/dev/null && rm -f $(TARGET) && cp $(LOCAL_TARGET) $(TARGET) 2>/dev/null || true
	@if command -v codesign >/dev/null 2>&1; then codesign -s - --force $(TARGET) >/dev/null 2>&1 || true; fi
	@echo "Copied to: $(TARGET)"

install: $(LOCAL_TARGET)
	@mkdir -p $(DESTDIR)$(BINDIR)
	install -m 755 $(LOCAL_TARGET) $(DESTDIR)$(BINDIR)/looping
	@echo "Installed looping to $(DESTDIR)$(BINDIR)/looping"

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/looping
	@echo "Uninstalled looping from $(DESTDIR)$(BINDIR)/looping"

clean:
	@rm -f $(LOCAL_TARGET) LoopingMacWindow.o LoopingAsmCore.o
	@-rm -f $(TARGET) 2>/dev/null || true

.PHONY: all clean install uninstall
