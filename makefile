# Be silent per default, but 'make V=1' will show all compiler calls.
ifneq ($(V),1)
Q := @
# Do not print "Entering directory ...".
MAKEFLAGS += --no-print-directory
endif

OPENCM3_DIR := inc/libopencm3
FREERTOS_DIR := inc/FreeRTOS

OBJ_DIR = obj
BIN_DIR = bin
SRC_DIR = src

# all the files will be generated with this name (main.elf, main.bin, main.hex, etc)
PROJECT_NAME=main

SRC_FILES := $(wildcard $(SRC_DIR)/*.c)

SRC_FILES += $(FREERTOS_DIR)/tasks.c
SRC_FILES += $(FREERTOS_DIR)/list.c
SRC_FILES += $(FREERTOS_DIR)/queue.c
SRC_FILES += $(FREERTOS_DIR)/timers.c
SRC_FILES += $(FREERTOS_DIR)/portable/GCC/ARM_CM4F/port.c
SRC_FILES += $(FREERTOS_DIR)/portable/MemMang/heap_4.c

INCLUDES  = -I$(realpath config)
INCLUDES += -I$(realpath src)
INCLUDES += -I$(OPENCM3_DIR)/include
INCLUDES += -I$(FREERTOS_DIR)/include
INCLUDES += -I$(FREERTOS_DIR)/portable/GCC/ARM_CM4F

OBJECTS = $(addprefix $(OBJ_DIR)/, $(SRC_FILES:.c=.o))

# Linker script for our MCU
LDSCRIPT = stm32f4-discovery.ld

# Using the stm32f4 series chip
TARGETS		:= stm32/f4
LIBNAME		= opencm3_stm32f4
DEFS		+= -DSTM32F4

# Target-specific flags
FP_FLAGS	?= -mfloat-abi=hard -mfpu=fpv4-sp-d16
ARCH_FLAGS	= -mthumb -mcpu=cortex-m4 $(FP_FLAGS)

# Compiler configuration
PREFIX		?= arm-none-eabi

CC		:= $(PREFIX)-gcc
CXX		:= $(PREFIX)-g++
LD		:= $(PREFIX)-gcc
AR		:= $(PREFIX)-ar
AS		:= $(PREFIX)-as
SIZE	:= $(PREFIX)-size
OBJCOPY	:= $(PREFIX)-objcopy
OBJDUMP	:= $(PREFIX)-objdump
GDB		:= $(PREFIX)-gdb
STFLASH	 = $(shell which st-flash)
OPT		:= -Os
DEBUG	:= -ggdb3
CSTD	?= -std=c99

# C flags
TGT_CFLAGS	+= $(OPT) $(CSTD) $(DEBUG)
TGT_CFLAGS	+= $(ARCH_FLAGS)
TGT_CFLAGS	+= -Wextra -Wshadow -Wimplicit-function-declaration
TGT_CFLAGS	+= -Wredundant-decls -Wmissing-prototypes -Wstrict-prototypes
TGT_CFLAGS	+= -fno-common -ffunction-sections -fdata-sections

# C & C++ preprocessor common flags
TGT_CPPFLAGS	+= -MD
TGT_CPPFLAGS	+= -Wall -Wundef
TGT_CPPFLAGS	+= $(DEFS)

# Linker flags
TGT_LDFLAGS		+= --static -nostartfiles
TGT_LDFLAGS		+= -T$(LDSCRIPT)
TGT_LDFLAGS		+= $(ARCH_FLAGS) $(DEBUG)
TGT_LDFLAGS		+= -Wl,-Map=$(BIN_DIR)/$(*).map -Wl,--cref
TGT_LDFLAGS		+= -Wl,--gc-sections
ifeq ($(V),1)
TGT_LDFLAGS		+= -Wl,--print-gc-sections
endif

# Used libraries
DEFS		+= $(INCLUDES)
LDFLAGS		+= -L$(OPENCM3_DIR)/lib
LDLIBS		+= -l$(LIBNAME)
LDLIBS		+= -Wl,--start-group -lc -lgcc -lnosys -Wl,--end-group

all: libopencm3 freertos $(BIN_DIR)/$(PROJECT_NAME).bin

libopencm3:
	$(Q)if [ ! "`ls -A $(OPENCM3_DIR)`" ] ; then \
		printf "#===========# ERROR #===========#\n"; \
		printf "  libopencm3 is not initialized\n"; \
		printf "  Please run:\n"; \
		printf "    $$ git submodule init\n"; \
		printf "    $$ git submodule update\n"; \
		printf "  before running make.\n"; \
		printf "#===========# ERROR #===========#\n"; \
		exit 1; \
		fi
	$(Q)$(MAKE) -C $(OPENCM3_DIR) TARGETS=$(TARGETS)

freertos:
	$(Q)if [ ! "`ls -A $(FREERTOS_DIR)`" ] ; then \
		printf "#===========# ERROR #===========#\n"; \
		printf "  FreeRTOS is not initialized\n"; \
		printf "  Please run:\n"; \
		printf "    $$ git submodule init\n"; \
		printf "    $$ git submodule update\n"; \
		printf "  before running make.\n"; \
		printf "#===========# ERROR #===========#\n"; \
		exit 1; \
		fi

$(BIN_DIR)/%.bin: $(BIN_DIR)/%.elf
	@printf "  OBJCOPY\t$@\n"
	$(Q)$(OBJCOPY) -Obinary $< $@

$(BIN_DIR)/%.elf: $(OBJECTS) $(LDSCRIPT)
	@printf "  LD\t$@\n"
	@mkdir -p $(dir $@)
	$(Q)$(LD) $(TGT_LDFLAGS) $(LDFLAGS) $(OBJECTS) $(LDLIBS) -o $@

$(OBJ_DIR)/%.o: %.c
	@printf "  CC\t$<\n"
	@mkdir -p $(dir $@)
	$(Q)$(CC) $(TGT_CFLAGS) $(CFLAGS) $(TGT_CPPFLAGS) $(CPPFLAGS) -c $< -o $@

clean:
	@printf "  CLEAN\tbin\n"
	$(Q)rm -Rf bin/*
	@printf "  CLEAN\tobj\n"
	$(Q)rm -Rf obj/*

flash: $(BIN_DIR)/$(PROJECT_NAME).bin
	@printf "  FLASH\t$<\n"
	$(Q)$(STFLASH) --reset write $(BIN_DIR)/$(PROJECT_NAME).bin 0x08000000

.PHONY: all libopencm3 freertos clean flash
.SECONDARY: $(OBJECTS) $(BIN_DIR)/$(PROJECT_NAME).elf
