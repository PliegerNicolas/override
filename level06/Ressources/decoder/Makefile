#* *************************************************************************** *#
#* *                                    ID                                   * *#
#* *************************************************************************** *#

NAME				:=	decoder

# Compilation flags and utils.
CC					:=	gcc
CFLAGS				:=	-Wall -Wextra -Werror -O1

# Linkage
LD_FLAGS			:=

# Artefact
ARTEFACT_NAME		:=	$(NAME)

#* *************************************************************************** *#
#* *                                  FILES                                  * *#
#* *************************************************************************** *#

#* Config *#

# Directories
SOURCES_DIR_PATH	:=	sources
HEADERS_DIR_PATHS	:=	includes
OBJECTS_DIR_PATH	:=	objects

# File extensions
SOURCES_FILE_EXTENSION			:=	.c
HEADERS_FILE_EXTENSION			:=	.h

# Files
SOURCES_FILE_NAMES	:=	decoder


SOURCES_FILE_NAMES_WITH_EXT := $(foreach file, $(SOURCES_FILE_NAMES), $(basename $(file))$(SOURCES_FILE_EXTENSION))
DIRECTORIES := $(sort $(dir $(SOURCES_FILE_NAMES_WITH_EXT)))
SORTED_COMPLETE_SOURCES_FILE_NAMES := $(foreach directory, $(DIRECTORIES), \
    	$(sort $(foreach file, $(SOURCES_FILE_NAMES_WITH_EXT), \
        	$(if $(filter $(directory), $(dir $(file))), $(file), ))))

#* Data *#

SOURCES			:= $(addprefix $(SOURCES_DIR_PATH)/, $(SORTED_COMPLETE_SOURCES_FILE_NAMES))
OBJECTS			:= $(addprefix $(OBJECTS_DIR_PATH)/, $(SORTED_COMPLETE_SOURCES_FILE_NAMES:%$(SOURCES_FILE_EXTENSION)=%.o))
DEPENDENCIES	:= $(OBJECTS:%.o=%.d)
HEADERS			:= $(addprefix -I , $(HEADERS_DIR_PATHS))

#* *************************************************************************** *#
#* *                              CONSTANTS                                  * *#
#* *************************************************************************** *#

# Text formatting
BOLD			:=		\033[1m
ITALIC			:=		\033[3m
UNDERLINE		:=		\033[4m
STRIKETHROUGH	:=		\033[9m

# Color codes
RED			:=		\033[0;31m
GREEN		:=		\033[0;32m
YELLOW		:=		\033[0;33m
BLUE		:=		\033[0;34m
PURPLE		:=		\033[0;35m
CYAN		:=		\033[0;36m
ORANGE		:=		\033[0;38;5;209m
GRAY		:=		\033[0;37m
RESET		:=		\033[0m

#* *************************************************************************** *#
#* *                               MESSAGES                                  * *#
#* *************************************************************************** *#

define make_successful
	echo "🌟 $(GREEN)$(BOLD)Make successful$(RESET) 🌟"
endef

define linkage_message
	echo "🔗 $(YELLOW)Linking $(BOLD)$(CYAN)$@$(RESET)$(YELLOW)...$(RESET)"
endef

define clean_message
		echo "🗑️🧹 $(ORANGE)Cleaning up object files...$(RESET)"
endef

define fclean_message
		echo "🗑️🧹 $(ORANGE)Cleaning up artefacts...$(RESET)"
endef

define build_object_message
	echo "Creating $(nodir $<)"
endef

define build_object_message
		echo "    $(YELLOW)•$(RESET) $(CYAN)$(notdir $<)$(RESET)"
endef

LAST_DIR	:=
define build_object_dir_and_message
	if [ "$(dir $@)" != "$(LAST_DIR)" ]; then \
		mkdir -p $(dir $@); \
		echo "$(CYAN)Building object files in directory $(BOLD)./$(patsubst %/,%,$(dir $@))$(RESET)"; \
	fi
	$(eval LAST_DIR := $(dir $@))
endef

#* *************************************************************************** *#
#* *                                  RULES                                  * *#
#* *************************************************************************** *#

all: $(ARTEFACT_NAME)

# Rule to build the final executable/shared object/...
$(ARTEFACT_NAME): $(OBJECTS)
	@$(call linkage_message)
	@$(CC) $(CFLAGS) $(HEADERS) -o $@ $(OBJECTS) $(LD_FLAGS) $(LIBFT_MINI_LD_FLAGS)
	@$(call set_ping_executable_privileges,$(ARTEFACT_NAME))
	@$(call make_successful)

# Rule to build object and dependency files (.o & .d) from source files (.c)
-include $(DEPENDENCIES) # Include the header files if they exist, to take them into account. Fail silently if needed.
$(OBJECTS_DIR_PATH)/%.o: $(SOURCES_DIR_PATH)/%$(SOURCES_FILE_EXTENSION)
	@$(call build_object_dir_and_message)
	@$(call build_object_message)
	@$(CC) $(CFLAGS) -MMD -MP -MF $(@:%.o=%.d) $(HEADERS) -c $< -o $@

# Rule to delete all objects (.o) and dependencies (.d).
clean:
	@$(call clean_message)
	@rm -rf $(OBJECTS_DIR_PATH)

# Rule to delete all objects (.o), dependencies (.d) and artifact (.a, .so, .dll, ...).
fclean:
	@$(call fclean_message)
	@rm -rf $(OBJECTS_DIR_PATH)
	@rm -f $(ARTEFACT_NAME)

# Rule to clean all and build it everything from scratch again.
re: fclean
	@$(MAKE) all

.PHONY: clean fclean re
