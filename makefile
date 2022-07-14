include settings.mk

################################################################################

filename = lib$(1).so

define compile_bin
gcc $(CFLAGS) -shared -o "$@" $^ $(LIBDIRS:%=-L%) $(LIBS:%=-l%)
endef

define compile_objs
gcc $(CFLAGS) -fPIC -c -o "$@" $< $(IDIRS:%=-I%)
endef

################################################################################

# Set prerrequisites
SRCS_C += $(shell find src/ -iname "*.c")
SRCS_H += $(shell find include/ -iname "*.h")
DEPS = $(foreach SHL,$(SHARED_LIBPATHS),$(SHL:%=%/bin/lib$(notdir $(SHL)).so)) \
	$(foreach STL,$(STATIC_LIBPATHS),$(STL:%=%/bin/lib$(notdir $(STL)).a))

# Set header files' directories to (-I)nclude
IDIRS += $(addsuffix /include,$(SHARED_LIBPATHS) $(STATIC_LIBPATHS) .)

# Set library files' directories to (-L)ook
LIBDIRS = $(addsuffix /bin,$(SHARED_LIBPATHS) $(STATIC_LIBPATHS))

# Set intermediate objects
OBJS = $(patsubst src/%.c,obj/%.o,$(SRCS_C))

# Set binary target
BIN = bin/$(call filename,$(shell cd . && pwd | xargs basename))

.PHONY: all
all: CFLAGS = $(CDEBUG)
all: $(BIN)

.PHONY: release
release: CFLAGS = $(CRELEASE)
release: $(BIN)

.PHONY: clean
clean:
	-rm -rfv obj bin

.PHONY: watch
watch:
	@test $(shell which entr) || entr
	while sleep 0.1; do \
		find src/ include/ | entr -d make all --no-print-directory; \
	done

$(BIN): $(OBJS) | $(dir $(BIN))
	$(call compile_bin)

obj/%.o: src/%.c $(SRCS_H) $(DEPS) | $(dir $(OBJS))
	$(call compile_objs)

.SECONDEXPANSION:
$(DEPS): $$(shell find $$(patsubst %bin/,%src/,$$(dir $$@)) -iname "*.c") \
	$$(shell find $$(patsubst %bin/,%include/,$$(dir $$@)) -iname "*.h")
	make --no-print-directory -C $(patsubst %bin/,%,$(dir $@))

$(sort $(dir $(BIN) $(OBJS))):
	mkdir -pv $@


################################################################################

PATH_TO_LIB=/usr/local/lib
PATH_TO_INCLUDE=/usr/local/include

.PHONY: install
install: release
	sudo cp -uva $(dir $(BIN)). $(PATH_TO_LIB)
	sudo cp -uva include/. $(PATH_TO_INCLUDE)

.PHONY: uninstall
uninstall:
	sudo rm -fv $(patsubst bin/%,$(PATH_TO_LIB)/%,$(BIN))
	sudo rm -fvr $(patsubst include/%,$(PATH_TO_INCLUDE)/%,$(SRCS_H))

