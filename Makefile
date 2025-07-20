# FreeRTOS Hello World Makefile

# Project name
PROJECT = freertos_hello

# FreeRTOS source directory (adjust path as needed)
FREERTOS_DIR = FreeRTOS-Kernel

# Tools
CC = arm-none-eabi-gcc
OBJCOPY = arm-none-eabi-objcopy
SIZE = arm-none-eabi-size
GDB = arm-none-eabi-gdb

# MCU settings
MCU = -mcpu=cortex-m3 -mthumb -mfloat-abi=soft

# Directories
BUILD_DIR = build
INC_DIR = .
FREERTOS_INC = $(FREERTOS_DIR)/include
FREERTOS_PORT_INC = $(FREERTOS_DIR)/portable/GCC/ARM_CM3

# Source files
C_SRCS = main.c
ASM_SRCS = startup.s

# FreeRTOS source files
FREERTOS_SRCS = $(FREERTOS_DIR)/tasks.c
FREERTOS_SRCS += $(FREERTOS_DIR)/queue.c
FREERTOS_SRCS += $(FREERTOS_DIR)/list.c
FREERTOS_SRCS += $(FREERTOS_DIR)/timers.c
FREERTOS_SRCS += $(FREERTOS_DIR)/event_groups.c
FREERTOS_SRCS += $(FREERTOS_DIR)/stream_buffer.c
FREERTOS_SRCS += $(FREERTOS_DIR)/portable/GCC/ARM_CM3/port.c
FREERTOS_SRCS += $(FREERTOS_DIR)/portable/MemMang/heap_4.c

# Include paths
INCLUDES = -I$(INC_DIR)
INCLUDES += -I$(FREERTOS_INC)
INCLUDES += -I$(FREERTOS_PORT_INC)

# Compiler flags
CFLAGS = $(MCU)
CFLAGS += -Wall -Wextra -Wno-unused-parameter
CFLAGS += -fdata-sections -ffunction-sections
CFLAGS += -g -O2
CFLAGS += $(INCLUDES)
CFLAGS += -DSTM32 -DUSE_STDPERIPH_DRIVER

# Linker flags
LDFLAGS = $(MCU)
LDFLAGS += -specs=nano.specs
LDFLAGS += -T linker.ld
LDFLAGS += -Wl,--gc-sections
LDFLAGS += -Wl,--print-memory-usage

# Object files
C_OBJS = $(C_SRCS:.c=.o)
ASM_OBJS = $(ASM_SRCS:.s=.o)
FREERTOS_OBJS = $(notdir $(FREERTOS_SRCS:.c=.o))

OBJS = $(addprefix $(BUILD_DIR)/, $(C_OBJS) $(ASM_OBJS) $(FREERTOS_OBJS))

# Default target
all: $(BUILD_DIR)/$(PROJECT).elf $(BUILD_DIR)/$(PROJECT).bin

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Compile C files
$(BUILD_DIR)/%.o: %.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Compile FreeRTOS source files with full paths
$(BUILD_DIR)/tasks.o: $(FREERTOS_DIR)/tasks.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/queue.o: $(FREERTOS_DIR)/queue.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/list.o: $(FREERTOS_DIR)/list.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/timers.o: $(FREERTOS_DIR)/timers.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/event_groups.o: $(FREERTOS_DIR)/event_groups.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/stream_buffer.o: $(FREERTOS_DIR)/stream_buffer.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/port.o: $(FREERTOS_DIR)/portable/GCC/ARM_CM3/port.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/heap_4.o: $(FREERTOS_DIR)/portable/MemMang/heap_4.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Compile assembly files
$(BUILD_DIR)/%.o: %.s | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Link
$(BUILD_DIR)/$(PROJECT).elf: $(OBJS)
	$(CC) $(LDFLAGS) $^ -o $@
	$(SIZE) $@

# Create binary
$(BUILD_DIR)/$(PROJECT).bin: $(BUILD_DIR)/$(PROJECT).elf
	$(OBJCOPY) -O binary $< $@

# QEMU run target
qemu: $(BUILD_DIR)/$(PROJECT).bin
# 	qemu-system-arm -M lm3s6965evb -cpu cortex-m3 -nographic -semihosting-config enable=on,target=native -kernel $(BUILD_DIR)/$(PROJECT).elf
	xterm -e "qemu-system-arm -M lm3s6965evb -cpu cortex-m3 -nographic -semihosting-config enable=on,target=native -kernel $(BUILD_DIR)/$(PROJECT).elf"


# QEMU with GDB support
qemu-gdb: $(BUILD_DIR)/$(PROJECT).bin
	qemu-system-arm -M lm3s6965evb -cpu cortex-m3 -nographic -semihosting-config enable=on,target=native -kernel $(BUILD_DIR)/$(PROJECT).elf -s -S

# GDB debug session
debug: $(BUILD_DIR)/$(PROJECT).elf
	$(GDB) -ex "target remote localhost:1234" -ex "load" $<

# Clean
clean:
	rm -rf $(BUILD_DIR)

# Download FreeRTOS (run this first)
freertos:
	@if [ ! -d "$(FREERTOS_DIR)" ]; then \
		echo "Downloading FreeRTOS kernel..."; \
		wget -O FreeRTOS-Kernel.zip https://github.com/FreeRTOS/FreeRTOS-Kernel/archive/refs/heads/main.zip; \
		unzip FreeRTOS-Kernel.zip; \
		mv FreeRTOS-Kernel-main FreeRTOS-Kernel; \
		rm FreeRTOS-Kernel.zip; \
		echo "FreeRTOS kernel downloaded successfully!"; \
	else \
		echo "FreeRTOS kernel already exists."; \
	fi

# Setup target - downloads FreeRTOS and builds
setup: freertos all

.PHONY: all clean qemu qemu-gdb debug freertos setup
