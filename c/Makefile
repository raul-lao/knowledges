include arch.mk


ifdef TARGET
	SUBDIRS = $(TARGET)
endif

all:
ifdef SUBDIRS
	@for dir in $(SUBDIRS) ;\
	do\
		if [ -d $$dir ] ;\
		then \
			make -C $$dir ;\
		else \
			echo "$$dir not exist"; \
		fi ;\
	done
endif


clean::
ifdef SUBDIRS
	@for dir in $(SUBDIRS) ;\
	do\
		if [ -d $$dir ] ;\
		then \
			make -C $$dir clean;\
		else \
			echo "$$dir not exist"; \
		fi ;\
	done
endif


.PHONY: all clean
