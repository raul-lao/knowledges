CURRENT_PATH := $(shell pwd)
LIB_PATH_NAME = libs
BUILD_DIR_NAME = build
CFLAGS = -g -Wall -Werror
LD_FLAGS =
INCLUDE_PATH = -I ../

SRC := $(wildcard ./*.c)
OBJS := $(SRC:./%.c=./$(BUILD_DIR_NAME)/%.o)
DEPS := $(SRC:./%.c=./$(BUILD_DIR_NAME)/%.d)


all::

mk_build_dir:
	@mkdir -p $(BUILD_DIR_NAME)

check_depends:

.PHONY: mk_build_dir check_depends


${BUILD_DIR_NAME}/%.d: %.c
	@mkdir -p ${BUILD_DIR_NAME}
	$(CC) $(CFLAGS) $(INCLUDE_PATH) -MM -MT "$(BUILD_DIR_NAME)/$(subst .c,.o,${notdir $<}) $(BUILD_DIR_NAME)/$(subst .c,.d,${notdir $<})" -MF "$(subst .c,.d,${BUILD_DIR_NAME}/${notdir $<})" $<


ifneq ($(MAKECMDGOALS),clean)
-include $(DEPS)
endif

$(BUILD_DIR_NAME)/%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDE_PATH) -c $< -o $@

clean::
	rm -rf $(BUILD_DIR_NAME) $(BIN) $(SHARE) $(ARCHIVE)

.PHONY: clean