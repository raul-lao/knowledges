include ../common.mk
include depends.mk
include loc_config.mk

LD_FLAGS += -L../$(LIB_PATH_NAME) $(addprefix -l, $(DEPEND_PROS))
LD_FLAGS += -Wl,-rpath=$(CURRENT_PATH)/../$(LIB_PATH_NAME)
CFLAGS += -fPIC


all:: check_depends $(BIN) $(SHARE) $(ARCHIVE)


.PHONY: all

$(BIN): $(OBJS)
	$(CC)  -o $@  $(OBJS) $(LD_FLAGS) -lpthread

$(SHARE): $(OBJS)
	gcc -shared -o $@ $(OBJS) -lpthread

$(ARCHIVE): $(OBJS)
	ar -crv $@ $(OBJS)


