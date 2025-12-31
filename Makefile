# CC       = arm-none-eabi-gcc
# OBJCOPY  = arm-none-eabi-objcopy

# TARGET   = main
# ELF      = $(TARGET).elf
# HEX      = $(TARGET).hex

# SRC_DIR      = Src
# INC_DIR      = Inc
# FREERTOS_DIR = FreeRTOS-Kernel

# SRCS = \
# $(wildcard $(SRC_DIR)/*.c) \
# $(FREERTOS_DIR)/croutine.c \
# $(FREERTOS_DIR)/event_groups.c \
# $(FREERTOS_DIR)/list.c \
# $(FREERTOS_DIR)/queue.c \
# $(FREERTOS_DIR)/stream_buffer.c \
# $(FREERTOS_DIR)/tasks.c \
# $(FREERTOS_DIR)/timers.c \
# $(FREERTOS_DIR)/portable/GCC/ARM_CM4F/port.c \
# $(FREERTOS_DIR)/portable/MemMang/heap_4.c

# STARTUP = startup_stm32f446.s

# INCLUDES = \
# -I$(INC_DIR) \
# -I$(FREERTOS_DIR)/include \
# -I$(FREERTOS_DIR)/portable/GCC/ARM_CM4F

# CFLAGS = \
# -mcpu=cortex-m4 \
# -mfpu=fpv4-sp-d16 \
# -mfloat-abi=hard \
# -mthumb \
# -O0 \
# -g \
# -Wall \
# -ffreestanding

# LDFLAGS = \
# -T linker.ld \
# -nostdlib

# all: $(ELF) $(HEX)

# $(ELF):
# 	$(CC) $(CFLAGS) $(SRCS) $(STARTUP) $(INCLUDES) $(LDFLAGS) -o $(ELF)

# $(HEX): $(ELF)
# 	$(OBJCOPY) -O ihex $(ELF) $(HEX)

# clean:
# 	rm -f $(ELF) $(HEX)

# Toolchain Setup
CC       = arm-none-eabi-gcc
OBJCOPY  = arm-none-eabi-objcopy
OBJDUMP  = arm-none-eabi-objdump
SIZE     = arm-none-eabi-size
GDB      = arm-none-eabi-gdb
RM       = rm -rf

# MCU Configuration
MCU       = cortex-m4
FPU       = fpv4-sp-d16
FLOAT-ABI = hard

# Project Structure
SRC_DIR      = Src
INC_DIR      = Inc
FREERTOS_DIR = FreeRTOS-Kernel
STARTUP      = startup_stm32f446.s
LINKER       = linker.ld

# Build Versioning
VERSION     = MY_RELEASE_1.0.0
BUILD_DATE := $(shell date +"%Y-%m-%d")
BUILD_TIME := $(shell date +"%H:%M:%S")

CFLAGS += -DBUILD_DATE=\"$(BUILD_DATE)\"
CFLAGS += -DBUILD_TIME=\"$(BUILD_TIME)\"
CFLAGS += -DBUILD_VERSION=\"$(VERSION)\"

# Build Configuration
ifeq ($(DEBUG),1)
CFLAGS_OPT = -O0 -g
BUILD_TYPE = Debug
else ifeq ($(RELEASE),1)
CFLAGS_OPT = -O2
BUILD_TYPE = Release
else
CFLAGS_OPT = -O0 -g
BUILD_TYPE = Default(Debug)
endif

# Target
TARGET = main
BUILD_DIR = Build

# Source Files
SRCS = \
$(wildcard $(SRC_DIR)/*.c) \
$(FREERTOS_DIR)/croutine.c \
$(FREERTOS_DIR)/event_groups.c \
$(FREERTOS_DIR)/list.c \
$(FREERTOS_DIR)/queue.c \
$(FREERTOS_DIR)/stream_buffer.c \
$(FREERTOS_DIR)/tasks.c \
$(FREERTOS_DIR)/timers.c \
$(FREERTOS_DIR)/portable/GCC/ARM_CM4F/port.c \
$(FREERTOS_DIR)/portable/MemMang/heap_4.c

ASMS = $(STARTUP)

# Objects
OBJS = $(patsubst %.c,$(BUILD_DIR)/%.o,$(SRCS)) \
       $(patsubst %.s,$(BUILD_DIR)/%.o,$(ASMS))

# Include Directories
INCLUDES = -I$(INC_DIR) -I$(FREERTOS_DIR)/include -I$(FREERTOS_DIR)/portable/GCC/ARM_CM4F

# Compiler Flags
CFLAGS  += -Wall $(CFLAGS_OPT) -std=gnu11
CFLAGS  += -mcpu=$(MCU) -mthumb -mfpu=$(FPU) -mfloat-abi=$(FLOAT-ABI)
CFLAGS  += $(INCLUDES)

# Linker Flags
LDFLAGS = -T $(LINKER) -nostdlib -mcpu=$(MCU) -mthumb -mfpu=$(FPU) -mfloat-abi=$(FLOAT-ABI)

# Primary Targets
.PHONY: all clean flash debug kill_openocd info

all: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).bin $(BUILD_DIR)/$(TARGET).hex
	@echo "---------------------------------------------------------"
	@echo "Build complete - Target: $(TARGET) | Mode: $(BUILD_TYPE)"
	@echo "Build Version: $(VERSION)"
	@echo "Build Date: $(BUILD_DATE)  Time: $(BUILD_TIME)"
	@echo "---------------------------------------------------------"

# Compile C sources
$(BUILD_DIR)/%.o: %.c | $(BUILD_DIR)
	@echo "Compiling $<"
	@mkdir -p $(dir $@)
	@$(CC) $(CFLAGS) -c $< -o $@

# Assemble startup
$(BUILD_DIR)/%.o: %.s | $(BUILD_DIR)
	@echo "Assembling $<"
	@mkdir -p $(dir $@)
	@$(CC) -c $< -o $@

# Create Build folder
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# Linking
$(BUILD_DIR)/$(TARGET).elf: $(OBJS)
	@echo "Linking..."
	@$(CC) $(OBJS) $(LDFLAGS) -o $@
	@echo "Created ELF: $@"
	@$(SIZE) --format=berkeley $@
	@$(OBJDUMP) -h -S $@ > $(BUILD_DIR)/$(TARGET)_sections.txt
	@echo "Section details : $(BUILD_DIR)/$(TARGET)_sections.txt"

# Generate BIN / HEX
$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf
	@$(OBJCOPY) -O binary $< $@
	@echo "Created binary  : $@"

$(BUILD_DIR)/%.hex: $(BUILD_DIR)/%.elf
	@$(OBJCOPY) -O ihex $< $@
	@echo "Created hex     : $@"

# Flashing
flash: all
	openocd -f interface/stlink.cfg -f target/stm32f4x.cfg \
	-c "program $(BUILD_DIR)/$(TARGET).elf verify reset exit"

# Debugging with GDB + OpenOCD
debug: all
	@echo "Starting OpenOCD..."
	@nohup openocd -f interface/stlink.cfg \
	               -c "transport select swd" \
	               -f target/stm32f4x.cfg \
	               > $(BUILD_DIR)/openocd.log 2>&1 &
	@sleep 5   # increase wait time to ensure OpenOCD starts
	@echo "Launching GDB..."
	$(GDB) $(BUILD_DIR)/$(TARGET).elf \
		-ex "target extended-remote localhost:3333" \
		-ex "monitor reset halt" \
		-ex "load" \
		-ex "monitor reset halt" \
		-ex "set pagination off"

kill_openocd:
	@pkill -f openocd

# Clean build folder
clean:
	@echo "Cleaning build files..."
	@$(RM) $(BUILD_DIR)
	@echo "Clean done."

# Build info
info:
	@echo "Target       : $(TARGET)"
	@echo "Source files : $(SRCS)"
	@echo "Object files : $(OBJS)"
	@echo "Include path : $(INCLUDES)"
	@echo "Build Mode   : $(BUILD_TYPE)"
	@echo "Build Date   : $(BUILD_DATE) $(BUILD_TIME)"
	@echo "Version Tag  : $(VERSION)"
