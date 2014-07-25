JULIAHOME = $(JULIA_HOME)/../..
include $(JULIAHOME)/deps/Versions.make
include $(JULIAHOME)/Make.inc

FLAGS = -std=c++11 $(CPPFLAGS) $(CFLAGS) -I$(build_includedir) \
		-I$(JULIAHOME)/src/support \
		-I$(call exec,$(LLVM_CONFIG) --includedir) \
		-I$(JULIAHOME)/deps/llvm-$(LLVM_VER)/tools/clang/lib

JULIA_LDFLAGS = -L$(build_libdir)

CLANG_LIBS = -lclangFrontendTool -lclangBasic -lclangLex -lclangDriver -lclangFrontend -lclangParse \
    -lclangAST -lclangASTMatchers -lclangSema -lclangAnalysis -lclangEdit \
    -lclangRewriteFrontend -lclangRewriteCore -lclangSerialization -lclangStaticAnalyzerCheckers \
    -lclangStaticAnalyzerCore -lclangStaticAnalyzerFrontend -lclangTooling \
    -lclangCodeGen -lclangARCMigrate

LLDB_LIBS = -llldbAPI -llldbBreakpoint -llldbCommands -llldbCore \
    -llldbDataFormatters -llldbExpression -llldbHostCommon  \
    -llldbInitAndLog -llldbInterpreter  \
    -llldbPluginABISysV_x86_64 -llldbPluginDisassemblerLLVM \
    -llldbPluginDynamicLoaderPOSIX -llldbPluginDynamicLoaderStatic -llldbPluginEmulateInstructionARM \
    -llldbPluginEmulateInstructionARM64 -llldbPluginJITLoaderGDB -llldbPluginLanguageRuntimeCPlusPlusItaniumABI \
    -llldbPluginObjectFileELF -llldbPluginObjectFileJIT -llldbPluginObjectContainerBSDArchive \
    -llldbPluginObjectFilePECOFF -llldbPluginOperatingSystemPython \
    -llldbPluginPlatformFreeBSD -llldbPluginPlatformGDBServer -llldbPluginPlatformLinux \
    -llldbPluginPlatformPOSIX -llldbPluginPlatformWindows -llldbPluginPlatformKalimba \
    -llldbPluginProcessElfCore -llldbPluginProcessGDBRemote \
    -llldbPluginSymbolFileDWARF -llldbPluginSymbolFileSymtab -llldbPluginSymbolVendorELF -llldbSymbol -llldbUtility \
    -llldbPluginUnwindAssemblyInstEmulation -llldbPluginUnwindAssemblyx86 -llldbPluginUtility -llldbTarget \
    -lxml2 -lcurses
ifeq ($(OS), Darwin)
LLDB_LIBS += -F/System/Library/Frameworks -F/System/Library/PrivateFrameworks -framework DebugSymbols -llldbHostMacOSX \
    -llldbPluginABIMacOSX_arm -llldbPluginABIMacOSX_arm64 -llldbPluginABIMacOSX_i386 -llldbPluginDynamicLoaderMacOSX \
    -llldbPluginLanguageRuntimeObjCAppleObjCRuntime -llldbPluginDynamicLoaderDarwinKernel -llldbPluginObjectContainerUniversalMachO \
    -llldbPluginProcessDarwin -llldbPluginPlatformMacOSX  -llldbPluginProcessMachCore \
    -llldbPluginSymbolVendorMacOSX -llldbPluginSystemRuntimeMacOSX -llldbPluginObjectFileMachO \
    -framework Security  -lpanel -framework CoreFoundation \
    -framework Foundation -framework Carbon -lobjc -ledit
endif

all: usr/lib/libcxxffi.$(SHLIB_EXT) usr/lib/libcxxffi-debug.$(SHLIB_EXT)

usr/lib:
	@mkdir -p $(CURDIR)/usr/lib/

build:
	@mkdir -p $(CURDIR)/build

build/bootstrap.o: ../src/bootstrap.cpp BuildBootstrap.Makefile | build
	@$(call PRINT_CC, $(CXX) -fno-rtti -fPIC -O0 -g $(FLAGS) -c ../src/bootstrap.cpp -o $@)

ifneq (,$(wildcard $(build_libdir)/libjulia.$(SHLIB_EXT)))
usr/lib/libcxxffi.$(SHLIB_EXT): build/bootstrap.o | usr/lib
	@$(call PRINT_LINK, $(CXX) -shared -fPIC $(JULIA_LDFLAGS) -ljulia $(LDFLAGS) -o $@ $(WHOLE_ARCHIVE) $(CLANG_LIBS) $(LLDB_LIBS) $(NO_WHOLE_ARCHIVE) $< )
else
usr/lib/libcxxffi.$(SHLIB_EXT):
	@echo "Not building release library because corresponding julia RELEASE library does not exist."
	@echo "To build, simply run the build again once the the library has been built."
endif

ifneq (,$(wildcard $(build_libdir)/libjulia-debug.$(SHLIB_EXT)))
usr/lib/libcxxffi-debug.$(SHLIB_EXT): build/bootstrap.o | usr/lib
	@$(call PRINT_LINK, $(CXX) -shared -fPIC $(JULIA_LDFLAGS) -ljulia-debug $(LDFLAGS) -o $@ $(WHOLE_ARCHIVE) $(CLANG_LIBS) $(LLDB_LIBS) $(NO_WHOLE_ARCHIVE) $< )
else
usr/lib/libcxxffi-debug.$(SHLIB_EXT):
	@echo "Not building debug library because corresponding julia DEBUG library does not exist."
	@echo "To build, simply run the build again once the the library has been built."
endif