#Project variables
FILE_NAME = GPS
MODEL_CORE = cortex-m3

# Linker Scripts
LD_SCRIPT = STM32F103C8TX_FLASH.ld

#Directory variables 
APP_DIR = Application
INTERFACE_DIR = Interface
DRIVER_DIR = Drivers
INC_DIR = Inc
SRC_DIR = Src
BUILD_DIR = Build
OBJ_DIR = Obj
START_DIR = Startup

# Toolchain
CC = arm-none-eabi-gcc							#arm gcc compiler
AS = arm-none-eabi-gcc -x assembler				#compiler expecting assembly code
CP = arm-none-eabi-objcopy						#The GNU objcopy utility copies the contents of an object file to another.
SZ = arm-none-eabi-size -d -G					#The GNU size utility lists the section sizes and the total size for each of the binary files objfile on its argument list.
HEX = $(CP) -O ihex
BIN = $(CP) -O binary -S

# Project sources.
C_FILES = $(wildcard $(APP_DIR)/$(SRC_DIR)/*.c) $(wildcard $(DRIVER_DIR)/$(SRC_DIR)/*.c)
ASM_FILES = $(wildcard $(APP_DIR)/$(SRC_DIR)/*.s) $(wildcard $(DRIVER_DIR)/$(SRC_DIR)/*.s)
ASM_FILES += $(wildcard $(START_DIR)/*.s)

# Linker Flags
#-Wl,option - Pass option as an option to the linker. If option contains commas, it is split into multiple options at the commas.
#-Wl,--gc-sections - Removes code that is never exercised
#-Wl,-T - Passes the linker script to the linker
#specs=rdimon.specs - 
LFLAGS = -Wl,--gc-sections -Wl,-T$(LD_SCRIPT) 
#LFLAGS += --specs=rdimon.specs

# Compiler Flags
# GCC
#Wall - This enables all the warnings about constructions that some users consider questionable, and that are easy to avoid, even in conjunction with macros.
#Wextra - This enables some extra warning flags that are not enabled by -Wall.
#std - Sets the language standard.
CFLAGS = -Wall -Wextra -std=c11

#Debug symbols are always enable until I can figure out how to make release vs debug build
#ifdef DEBUG
#g - g, g1, g2,g3 - Produce debugging information in the operating system's native format.  Higher the number the more debug symbols
#O0 - No optimization is performed.
#O1 - This enables most common forms of optimization that requires no size versus speed decisions.
#O2 - This enables additional optimizations, such as instruction scheduling.
#O3 - This enables additional optimizations, such as aggressive function inlining and can therefore increase the speed at the expense of image size.
#Os - This selects optimizations that attempt to minimize the size of the image, even at the expense of speed.
CFLAGS += -g3 -O0
#endif

# ARM
#mthumb - Requests that the compiler targets the T32 instruction set.
#mlittle-endian - Generates code suitable for an Arm processor using little-endian data.
#mfloat-abi=hard - Specifies whether to use hardware instructions or software library functions for floating-point operations, 
#				   and which registers are used to pass floating-point parameters and return values.
#mfpu - Specifies the target FPU architecture, that is the floating-point hardware available on the target.
#mcpu - Enables code generation for a specific Arm processor.  To view a list of all the supported processors, use: -mcpu=list
CFLAGS += -mthumb -mlittle-endian
# CFLAGS += -mfloat-abi=hard -mfpu=fpv4-sp-d16 

# PROJECT
#ffreestanding - This gcc option directs the compiler to limit this program to only those features available in the freestanding environment.
#                In freestanding mode, the only available standard header files are: <float.h>, <iso646.h>, <limits.h>, <stdarg.h>, <stdbool.h>, <stddef.h>, and <stdint.h>
#                Reference: http://cs107e.github.io/guides/gcc/
#                Atleast, that what the internet says.  However, I'm using stdlib.h for malloc and it seems to be working.  Not sure why.
#specs=nosys.specs -
CFLAGS += -mcpu=$(MODEL_CORE) 
CFLAGS += -I$(DRIVER_DIR)/$(INC_DIR)
CFLAGS += -I$(APP_DIR)/$(INC_DIR)
CFLAGS += -ffreestanding
CFLAGS += -specs=nosys.specs

#Make a list of .o files based off source and assembly file names
OBJECTS  = $(addprefix $(BUILD_DIR)\$(OBJ_DIR)\,$(notdir $(C_FILES:.c=.o)))
OBJECTS += $(addprefix $(BUILD_DIR)\$(OBJ_DIR)\,$(notdir $(ASM_FILES:.s=.o)))
#Make a list of .d files based off source and assembly file names
DEPENDS  = $(addprefix $(BUILD_DIR)\$(OBJ_DIR)\,$(notdir $(C_FILES:.c=.d)))
DEPENDS += $(addprefix $(BUILD_DIR)\$(OBJ_DIR)\,$(notdir $(C_FILES:.s=.d)))

vpath %.c $(sort $(dir $(C_FILES)))
vpath %.s $(sort $(dir $(ASM_FILES)))

.PHONY: all
all: $(BUILD_DIR)\$(FILE_NAME).bin

-include $(DEPENDS)

# Compile c
$(BUILD_DIR)\$(OBJ_DIR)\\%.o: %.c Makefile | $(BUILD_DIR) 
	@echo "[CC] $<"
	@$(CC) $(CFLAGS) -c $< -o $@
	
# Compile asm
$(BUILD_DIR)\$(OBJ_DIR)\\%.o: %.s Makefile | $(BUILD_DIR) 
	@echo "[AS] $<"
	@$(AS) $(CFLAGS) -c $< -o $@		
	
# Link
# Build .elf
$(BUILD_DIR)\$(FILE_NAME).elf: $(OBJECTS) Makefile
	@echo "[LD] $@"
	@$(CC) $(CFLAGS) $(LFLAGS) $(OBJECTS) -o $@
	@$(SZ) $@

#Build hex file	
$(BUILD_DIR)\$(FILE_NAME).hex: $(BUILD_DIR)\$(FILE_NAME).elf
	@echo "[HEX] $@"
	@$(HEX) $< $@
	@$(SZ) $@
	
#Build bin
$(BUILD_DIR)\$(FILE_NAME).bin: $(BUILD_DIR)\$(FILE_NAME).elf
	@echo "[BIN] $@"
	@$(BIN) $< $@

intel-hex: $(BUILD_DIR)/$(FILE_NAME).hex
	
# Make directory
$(BUILD_DIR):
	@mkdir $@
	@mkdir $@\$(OBJ_DIR)
	
# Clean
.PHONY: clean
clean:
#/Q removes prompt for file deletion
	@del /Q $(BUILD_DIR)
	@del /Q $(BUILD_DIR)\$(OBJ_DIR)

#Flash
.PHONY: flash
flash: $(BUILD_DIR)\$(FILE_NAME).elf
	openocd -f interface/stlink.cfg -f target/stm32f1x.cfg -c "program $(BUILD_DIR)/$(FILE_NAME).elf verify reset exit"
#copied stm32f1x.cfg and changed 0x1ba01477 to 0x2ba01477 (line 42).  Saved as cs32f1x.cfg 
#	openocd -f interface/stlink.cfg -f target/cs32f1x.cfg -c "program $(BUILD_DIR)/$(FILE_NAME).elf verify reset exit"