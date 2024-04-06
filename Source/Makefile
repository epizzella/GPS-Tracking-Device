FILE_NAME = JeepPS

# debug build?
DEBUG = 1
# optimization
OPT = -Og

#Directory variables 
APP_DIR := Application
CORE_DIR := Core
DRIVERS_DIR := Drivers
MODULES_DIR := Modules

BUILD_DIR := Build
OBJ_DIR := obj

DIR_LST =  $(sort $(dir $(wildcard $(APP_DIR)/*/)))
DIR_LST += $(sort $(dir $(wildcard $(CORE_DIR)/*/)))
DIR_LST += $(sort $(dir $(DRIVERS_DIR)/))
DIR_LST += $(sort $(dir $(wildcard $(DRIVERS_DIR)/*/*/)))
DIR_LST += $(sort $(dir $(MODULES_DIR)/))
DIR_LST += $(sort $(dir $(wildcard $(MODULES_DIR)/*/*)))


# Project sources.
C_SOURCES += $(foreach dir, $(DIR_LST), $(wildcard $(dir)*.c))
CXX_SOURCES += $(foreach dir, $(DIR_LST), $(wildcard $(dir)*.cpp))
ASM_SOURCES = $(wildcard *.s)

#######################################
# binaries
#######################################
PREFIX = arm-none-eabi-
# The gcc compiler bin path can be either defined in make command via GCC_PATH variable (> make GCC_PATH=xxx)
# either it can be added to the PATH environment variable.
ifdef GCC_PATH
CC = $(GCC_PATH)/$(PREFIX)g++
AS = $(GCC_PATH)/$(PREFIX)g++ -x assembler-with-cpp
CP = $(GCC_PATH)/$(PREFIX)objcopy
SZ = $(GCC_PATH)/$(PREFIX)size
else
CC = $(PREFIX)g++
AS = $(PREFIX)g++ -x assembler-with-cpp
CP = $(PREFIX)objcopy
SZ = $(PREFIX)size
endif
HEX = $(CP) -O ihex
BIN = $(CP) -O binary -S
 
#######################################
# CXXFLAGS
#######################################
# cpu
CPU = -mcpu=cortex-m3

# mcu
MCU = $(CPU) -mthumb $(FPU) $(FLOAT-ABI)

# macros for gcc
# AS defines
AS_DEFS = 

# C defines
C_DEFS =  \
-DUSE_HAL_DRIVER \
-DSTM32F103xB

# AS includes
AS_INCLUDES = 

# C includes
C_INCLUDES+= $(foreach dir,$(DIR_LST), -I$(dir))

# compile gcc flags
ASFLAGS = $(MCU) $(AS_DEFS) $(AS_INCLUDES) $(OPT) -Wall -fdata-sections -ffunction-sections

CXXFLAGS += $(MCU) $(C_DEFS) $(C_INCLUDES) $(OPT) -Wall -fdata-sections -ffunction-sections -fno-exceptions -std=c++17

ifeq ($(DEBUG), 1)
CXXFLAGS += -g -gdwarf-2
endif

# Generate dependency information
CXXFLAGS += -MMD -MP -MF"$(@:%.o=%.d)"

# link script
LDSCRIPT = STM32F103C8Tx_FLASH.ld

# libraries
LIBS = -lc -lm -lnosys 
LIBDIR = 
LDFLAGS = $(MCU) -specs=nosys.specs -T$(LDSCRIPT) $(LIBDIR) $(LIBS) -Wl,-Map=$(BUILD_DIR)/$(FILE_NAME).map,--cref -Wl,--gc-sections

# list of objects
OBJECTS = $(addprefix $(BUILD_DIR)/$(OBJ_DIR)/,$(notdir $(CXX_SOURCES:.cpp=.o)))
OBJECTS += $(addprefix $(BUILD_DIR)/$(OBJ_DIR)/,$(notdir $(C_SOURCES:.c=.o)))
OBJECTS += $(addprefix $(BUILD_DIR)/$(OBJ_DIR)/,$(notdir $(ASM_SOURCES:.s=.o)))

vpath %.cpp $(sort $(dir $(CXX_SOURCES)))
vpath %.c $(sort $(dir $(C_SOURCES)))
vpath %.s $(sort $(dir $(ASM_SOURCES)))

# default action: build all
.PHONY: all
all: $(BUILD_DIR)/$(FILE_NAME).elf $(BUILD_DIR)/$(FILE_NAME).hex $(BUILD_DIR)/$(FILE_NAME).bin

-include $(wildcard $(BUILD_DIR)/$(OBJ_DIR)/*.d)

$(BUILD_DIR)/$(OBJ_DIR)/%.o: %.cpp Makefile | $(BUILD_DIR)/$(OBJ_DIR)
	@echo $<
	@$(CC) -c $(CXXFLAGS) -Wa,-a,-ad,-alms=$(BUILD_DIR)/$(OBJ_DIR)/$(notdir $(<:.cpp=.lst)) $< -o $@

$(BUILD_DIR)/$(OBJ_DIR)/%.o: %.c Makefile | $(BUILD_DIR)/$(OBJ_DIR)
	@echo $<
	@$(CC) -c $(CXXFLAGS) -Wa,-a,-ad,-alms=$(BUILD_DIR)/$(OBJ_DIR)/$(notdir $(<:.c=.lst)) $< -o $@

$(BUILD_DIR)/$(OBJ_DIR)/%.o: %.s Makefile | $(BUILD_DIR)/$(OBJ_DIR)
	@echo $<
	@$(AS) -c $(CXXFLAGS) $< -o $@

$(BUILD_DIR)/$(FILE_NAME).elf: $(OBJECTS) Makefile
	@$(CC) $(OBJECTS) $(LDFLAGS) -o $@
	$(SZ) $@

#Build hex file
$(BUILD_DIR)/%.hex: $(BUILD_DIR)/%.elf
	@$(HEX) $< $@
	$(SZ) $@

#Build bin
$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf
	@$(BIN) $< $@

.PHONY: hex
hex: $(BUILD_DIR)/$(FILE_NAME).hex

.PHONY: elf
elf: $(BUILD_DIR)/$(FILE_NAME).elf

# Make obj directory dir
$(BUILD_DIR)/$(OBJ_DIR): | $(BUILD_DIR)
	mkdir $(BUILD_DIR)\$(OBJ_DIR)

# Make build directory dir
$(BUILD_DIR):
	mkdir $@

#Show list of folders that are searched for files
.PHONY: dir_list
dir_list: 
	@echo $(DIR_LST)

# Clean
.PHONY: clean
clean:
#/Q removes prompt for file deletion
	@del /Q $(BUILD_DIR)
	@del /Q $(BUILD_DIR)\$(OBJ_DIR)

#Flash
.PHONY: flash
flash: $(BUILD_DIR)/$(FILE_NAME).elf
	openocd -f interface/stlink.cfg -f target/stm32f1x.cfg -c "program $(BUILD_DIR)/$(FILE_NAME).elf verify reset exit"
#copied stm32f1x.cfg and changed 0x1ba01477 to 0x2ba01477 (line 42).  Saved as cs32f1x.cfg 
#	openocd -f interface/stlink.cfg -f target/cs32f1x.cfg -c "program $(BUILD_DIR)/$(FILE_NAME).elf verify reset exit"
