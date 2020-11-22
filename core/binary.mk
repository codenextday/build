###########################################################
## Standard rules for building binary object files from
## asm/c/cpp/yacc/lex/etc source files.
##
## The list of object files is exported in $(all_objects).
###########################################################

#######################################
include $(BUILD_SYSTEM)/base_rules.mk
#######################################

##################################################
# Compute the dependency of the shared libraries
##################################################
# On the target, we compile with -nostdlib, so we must add in the
# default system shared libraries, unless they have requested not
# to by supplying a LOCAL_SYSTEM_SHARED_LIBRARIES value.  One would
# supply that, for example, when building libc itself.
ifdef LOCAL_IS_HOST_MODULE
  ifeq ($(LOCAL_SYSTEM_SHARED_LIBRARIES),none)
      my_system_shared_libraries :=
  else
      my_system_shared_libraries := $(LOCAL_SYSTEM_SHARED_LIBRARIES)
  endif
else
  ifeq ($(LOCAL_SYSTEM_SHARED_LIBRARIES),none)
      my_system_shared_libraries := 
  else
      my_system_shared_libraries := $(LOCAL_SYSTEM_SHARED_LIBRARIES)
  endif
endif


# The following LOCAL_ variables will be modified in this file.
# Because the same LOCAL_ variables may be used to define modules for both 1st arch and 2nd arch,
# we can't modify them in place.
my_src_files := $(LOCAL_SRC_FILES)
my_src_files_exclude := $(LOCAL_SRC_FILES_EXCLUDE)
my_static_libraries := $(LOCAL_STATIC_LIBRARIES)
my_whole_static_libraries := $(LOCAL_WHOLE_STATIC_LIBRARIES)
my_shared_libraries := $(LOCAL_SHARED_LIBRARIES)
my_cflags := $(LOCAL_CFLAGS)
my_conlyflags := $(LOCAL_CONLYFLAGS)
my_cppflags := $(LOCAL_CPPFLAGS)
my_cflags_no_override := $(GLOBAL_CFLAGS_NO_OVERRIDE)
my_cppflags_no_override := $(GLOBAL_CPPFLAGS_NO_OVERRIDE)
my_ldflags := $(LOCAL_LDFLAGS)
my_ldlibs := $(LOCAL_LDLIBS)
my_asflags := $(LOCAL_ASFLAGS)
my_cc := $(LOCAL_CC)
my_cc_wrapper := $(CC_WRAPPER)
my_cxx := $(LOCAL_CXX)
my_cxx_wrapper := $(CXX_WRAPPER)
my_c_includes := $(LOCAL_C_INCLUDES)
my_generated_sources := $(LOCAL_GENERATED_SOURCES)
my_native_coverage := $(LOCAL_NATIVE_COVERAGE)
my_additional_dependencies := $(LOCAL_MODULE_MAKEFILE_DEP) $(LOCAL_ADDITIONAL_DEPENDENCIES)
my_export_c_include_dirs := $(LOCAL_EXPORT_C_INCLUDE_DIRS)

ifdef LOCAL_IS_HOST_MODULE
my_allow_undefined_symbols := true
else
my_allow_undefined_symbols := $(strip $(LOCAL_ALLOW_UNDEFINED_SYMBOLS))
endif

# MinGW spits out warnings about -fPIC even for -fpie?!) being ignored because
# all code is position independent, and then those warnings get promoted to
# errors.
ifeq ($(LOCAL_MODULE_CLASS),EXECUTABLES)
my_cflags += -fpie
else
my_cflags += -fPIC
endif

ifdef LOCAL_IS_HOST_MODULE
my_src_files += $(LOCAL_SRC_FILES_$($(my_prefix)OS)) $(LOCAL_SRC_FILES_$($(my_prefix)OS)_$($(my_prefix)ARCH))
my_static_libraries += $(LOCAL_STATIC_LIBRARIES_$($(my_prefix)OS))
my_shared_libraries += $(LOCAL_SHARED_LIBRARIES_$($(my_prefix)OS))
my_cflags += $(LOCAL_CFLAGS_$($(my_prefix)OS))
my_cppflags += $(LOCAL_CPPFLAGS_$($(my_prefix)OS))
my_ldflags += $(LOCAL_LDFLAGS_$($(my_prefix)OS))
my_ldlibs += $(LOCAL_LDLIBS_$($(my_prefix)OS))
my_asflags += $(LOCAL_ASFLAGS_$($(my_prefix)OS))
my_c_includes += $(LOCAL_C_INCLUDES_$($(my_prefix)OS))
my_generated_sources += $(LOCAL_GENERATED_SOURCES_$($(my_prefix)OS))
endif

my_src_files += $(LOCAL_SRC_FILES_$($(my_prefix)ARCH)) $(LOCAL_SRC_FILES_$(my_32_64_bit_suffix))
my_src_files_exclude += $(LOCAL_SRC_FILES_EXCLUDE_$($(my_prefix)ARCH)) $(LOCAL_SRC_FILES_EXCLUDE_$(my_32_64_bit_suffix))
my_shared_libraries += $(LOCAL_SHARED_LIBRARIES_$($(my_prefix)ARCH)) $(LOCAL_SHARED_LIBRARIES_$(my_32_64_bit_suffix))
my_cflags += $(LOCAL_CFLAGS_$($(my_prefix)ARCH)) $(LOCAL_CFLAGS_$(my_32_64_bit_suffix))
my_cppflags += $(LOCAL_CPPFLAGS_$($(my_prefix)ARCH)) $(LOCAL_CPPFLAGS_$(my_32_64_bit_suffix))
my_ldflags += $(LOCAL_LDFLAGS_$($(my_prefix)ARCH)) $(LOCAL_LDFLAGS_$(my_32_64_bit_suffix))
my_asflags += $(LOCAL_ASFLAGS_$($(my_prefix)ARCH)) $(LOCAL_ASFLAGS_$(my_32_64_bit_suffix))
my_c_includes += $(LOCAL_C_INCLUDES_$($(my_prefix)ARCH)) $(LOCAL_C_INCLUDES_$(my_32_64_bit_suffix))
my_generated_sources += $(LOCAL_GENERATED_SOURCES_$($(my_prefix)ARCH)) $(LOCAL_GENERATED_SOURCES_$(my_32_64_bit_suffix))

my_src_files := $(filter-out $(my_src_files_exclude),$(my_src_files))

my_cpp_std_version := -std=gnu++11


my_cppflags := $(my_cpp_std_version) $(my_cppflags)



# arch-specific static libraries go first so that generic ones can depend on them
my_static_libraries := $(LOCAL_STATIC_LIBRARIES_$($(my_prefix)ARCH)) $(LOCAL_STATIC_LIBRARIES_$(my_32_64_bit_suffix)) $(my_static_libraries)
my_whole_static_libraries := $(LOCAL_WHOLE_STATIC_LIBRARIES_$($(my_prefix)ARCH)) $(LOCAL_WHOLE_STATIC_LIBRARIES_$(my_32_64_bit_suffix)) $(my_whole_static_libraries)

#include $(BUILD_SYSTEM)/cxx_stl_setup.mk


my_linker := $(TARGET_LINKER)


###########################################################
## Explicitly declare assembly-only __ASSEMBLY__ macro for
## assembly source
###########################################################
my_asflags += -D__ASSEMBLY__


###########################################################
## Define PRIVATE_ variables from global vars
###########################################################
ifndef LOCAL_IS_HOST_MODULE

my_target_project_includes := $(TARGET_PROJECT_INCLUDES)
my_target_c_includes := $(TARGET_C_INCLUDES)
my_target_global_cppflags :=

my_target_global_cflags := $(TARGET_GLOBAL_CFLAGS)
my_target_global_conlyflags := $(TARGET_GLOBAL_CONLYFLAGS)
my_target_global_cppflags += $(TARGET_GLOBAL_CPPFLAGS)
my_target_global_ldflags := $(TARGET_GLOBAL_LDFLAGS)

$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_TARGET_PROJECT_INCLUDES := $(my_target_project_includes)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_TARGET_C_INCLUDES := $(my_target_c_includes)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_TARGET_GLOBAL_CFLAGS := $(my_target_global_cflags)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_TARGET_GLOBAL_CONLYFLAGS := $(my_target_global_conlyflags)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_TARGET_GLOBAL_CPPFLAGS := $(my_target_global_cppflags)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_TARGET_GLOBAL_LDFLAGS := $(my_target_global_ldflags)

else # LOCAL_IS_HOST_MODULE

my_host_global_cflags := $($(my_prefix)GLOBAL_CFLAGS)
my_host_global_conlyflags := $($(my_prefix)GLOBAL_CONLYFLAGS)
my_host_global_cppflags := $($(my_prefix)GLOBAL_CPPFLAGS)
my_host_global_ldflags := $($(my_prefix)GLOBAL_LDFLAGS)
my_host_c_includes := $($(my_prefix)C_INCLUDES)

$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_HOST_C_INCLUDES := $(my_host_c_includes)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_HOST_GLOBAL_CFLAGS := $(my_host_global_cflags)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_HOST_GLOBAL_CONLYFLAGS := $(my_host_global_conlyflags)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_HOST_GLOBAL_CPPFLAGS := $(my_host_global_cppflags)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_HOST_GLOBAL_LDFLAGS := $(my_host_global_ldflags)
endif # LOCAL_IS_HOST_MODULE


###########################################################
## Define PRIVATE_ variables used by multiple module types
###########################################################
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_NO_DEFAULT_COMPILER_FLAGS := \
    $(strip $(LOCAL_NO_DEFAULT_COMPILER_FLAGS))


ifneq ($(strip $(LOCAL_IS_HOST_MODULE)),)
  my_syntax_arch := host
else
  my_syntax_arch := $(TARGET_ARCH)
endif

ifeq ($(strip $(my_cc)),)
  my_cc := $($(my_prefix)CC)
  my_cc := $(my_cc_wrapper) $(my_cc)
endif


$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_CC := $(my_cc)

ifeq ($(strip $(my_cxx)),)
  my_cxx := $($(my_prefix)CXX)
  my_cxx := $(my_cxx_wrapper) $(my_cxx)
endif


$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_LINKER := $(my_linker)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_CXX := $(my_cxx)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_CLANG := $(my_clang)

# TODO: support a mix of standard extensions so that this isn't necessary
LOCAL_CPP_EXTENSION := $(strip $(LOCAL_CPP_EXTENSION))
ifeq ($(LOCAL_CPP_EXTENSION),)
  LOCAL_CPP_EXTENSION := .cpp
endif

# Certain modules like libdl have to have symbols resolved at runtime and blow
# up if --no-undefined is passed to the linker.
ifeq ($(strip $(LOCAL_NO_DEFAULT_COMPILER_FLAGS)),)
ifeq ($(my_allow_undefined_symbols),)
  my_ldflags +=  $($(my_prefix)NO_UNDEFINED_LDFLAGS)
endif
endif

ifeq (true,$(LOCAL_GROUP_STATIC_LIBRARIES))
$(LOCAL_BUILT_MODULE): PRIVATE_GROUP_STATIC_LIBRARIES := true
else
$(LOCAL_BUILT_MODULE): PRIVATE_GROUP_STATIC_LIBRARIES :=
endif

###########################################################
## Define arm-vs-thumb-mode flags.
###########################################################
LOCAL_ARM_MODE := $(strip $(LOCAL_ARM_MODE))
ifeq ($($(my_prefix)ARCH),arm)
arm_objects_mode := $(if $(LOCAL_ARM_MODE),$(LOCAL_ARM_MODE),arm)
normal_objects_mode := $(if $(LOCAL_ARM_MODE),$(LOCAL_ARM_MODE),thumb)

# Read the values from something like TARGET_arm_CFLAGS or
# TARGET_thumb_CFLAGS.  HOST_(arm|thumb)_CFLAGS values aren't
# actually used (although they are usually empty).
arm_objects_cflags := $($(my_prefix)$(arm_objects_mode)_CFLAGS)
normal_objects_cflags := $($(my_prefix)$(normal_objects_mode)_CFLAGS)
ifeq ($(my_clang),true)
arm_objects_cflags := $(call convert-to-$(my_host)clang-flags,$(arm_objects_cflags))
normal_objects_cflags := $(call convert-to-$(my_host)clang-flags,$(normal_objects_cflags))
endif

else
arm_objects_mode :=
normal_objects_mode :=
arm_objects_cflags :=
normal_objects_cflags :=
endif

###########################################################
## Define per-module debugging flags.  Users can turn on
## debugging for a particular module by setting DEBUG_MODULE_ModuleName
## to a non-empty value in their environment or buildspec.mk,
## and setting HOST_/TARGET_CUSTOM_DEBUG_CFLAGS to the
## debug flags that they want to use.
###########################################################
ifdef DEBUG_MODULE_$(strip $(LOCAL_MODULE))
  debug_cflags := $($(my_prefix)CUSTOM_DEBUG_CFLAGS)
else
  debug_cflags :=
endif

####################################################
## Keep track of src -> obj mapping
####################################################

my_tracked_gen_files :=
my_tracked_src_files :=


####################################################
## Compile RenderScript with reflected C++
####################################################

renderscript_sources := $(filter %.rs %.fs,$(my_src_files))

ifneq (,$(renderscript_sources))

renderscript_sources_fullpath := $(addprefix $(LOCAL_PATH)/, $(renderscript_sources))
RenderScript_file_stamp := $(intermediates)/RenderScriptCPP.stamp
renderscript_intermediate := $(intermediates)/renderscript

renderscript_target_api :=

ifneq (,$(LOCAL_RENDERSCRIPT_TARGET_API))
renderscript_target_api := $(LOCAL_RENDERSCRIPT_TARGET_API)
else
ifneq (,$(LOCAL_SDK_VERSION))
# Set target-api for LOCAL_SDK_VERSIONs other than current.
ifneq (,$(filter-out current system_current test_current, $(LOCAL_SDK_VERSION)))
renderscript_target_api := $(LOCAL_SDK_VERSION)
endif
endif  # LOCAL_SDK_VERSION is set
endif  # LOCAL_RENDERSCRIPT_TARGET_API is set


ifeq ($(LOCAL_RENDERSCRIPT_CC),)
LOCAL_RENDERSCRIPT_CC := $(LLVM_RS_CC)
endif

# Turn on all warnings and warnings as errors for RS compiles.
# This can be disabled with LOCAL_RENDERSCRIPT_FLAGS := -Wno-error
renderscript_flags := -Wall -Werror
renderscript_flags += $(LOCAL_RENDERSCRIPT_FLAGS)
# -m32 or -m64
renderscript_flags += -m$(my_32_64_bit_suffix)

renderscript_includes := \
    $(TOPDIR)external/clang/lib/Headers \
    $(TOPDIR)frameworks/rs/scriptc \
    $(LOCAL_RENDERSCRIPT_INCLUDES)

ifneq ($(LOCAL_RENDERSCRIPT_INCLUDES_OVERRIDE),)
renderscript_includes := $(LOCAL_RENDERSCRIPT_INCLUDES_OVERRIDE)
endif

bc_dep_files := $(addprefix $(renderscript_intermediate)/, \
    $(patsubst %.fs,%.d, $(patsubst %.rs,%.d, $(notdir $(renderscript_sources)))))

$(RenderScript_file_stamp): PRIVATE_RS_INCLUDES := $(renderscript_includes)
$(RenderScript_file_stamp): PRIVATE_RS_CC := $(LOCAL_RENDERSCRIPT_CC)
$(RenderScript_file_stamp): PRIVATE_RS_FLAGS := $(renderscript_flags)
$(RenderScript_file_stamp): PRIVATE_RS_SOURCE_FILES := $(renderscript_sources_fullpath)
$(RenderScript_file_stamp): PRIVATE_RS_OUTPUT_DIR := $(renderscript_intermediate)
$(RenderScript_file_stamp): PRIVATE_RS_TARGET_API := $(renderscript_target_api)
$(RenderScript_file_stamp): PRIVATE_DEP_FILES := $(bc_dep_files)
$(RenderScript_file_stamp): $(renderscript_sources_fullpath) $(LOCAL_RENDERSCRIPT_CC)
	$(transform-renderscripts-to-cpp-and-bc)

# include the dependency files (.d/.P) generated by llvm-rs-cc.
$(call include-depfile,$(RenderScript_file_stamp).P,$(RenderScript_file_stamp))

LOCAL_INTERMEDIATE_TARGETS += $(RenderScript_file_stamp)

rs_generated_cpps := $(addprefix \
    $(renderscript_intermediate)/ScriptC_,$(patsubst %.fs,%.cpp, $(patsubst %.rs,%.cpp, \
    $(notdir $(renderscript_sources)))))

$(call track-src-file-gen,$(renderscript_sources),$(rs_generated_cpps))

# This is just a dummy rule to make sure gmake doesn't skip updating the dependents.
$(rs_generated_cpps) : $(RenderScript_file_stamp)
	@echo "Updated RS generated cpp file $@."
	$(hide) touch $@

my_c_includes += $(renderscript_intermediate)
my_generated_sources += $(rs_generated_cpps)

endif


###########################################################
## Compile the .proto files to .cc (or .c) and then to .o
###########################################################
proto_sources := $(filter %.proto,$(my_src_files))
ifneq ($(proto_sources),)
proto_gen_dir := $(generated_sources_dir)/proto

my_rename_cpp_ext :=
ifneq (,$(filter nanopb-c nanopb-c-enable_malloc, $(LOCAL_PROTOC_OPTIMIZE_TYPE)))
my_proto_source_suffix := .c
my_proto_c_includes := external/nanopb-c
my_protoc_flags := --nanopb_out=$(proto_gen_dir) \
    --plugin=external/nanopb-c/generator/protoc-gen-nanopb
else
my_proto_source_suffix := $(LOCAL_CPP_EXTENSION)
ifneq ($(my_proto_source_suffix),.cc)
# aprotoc is hardcoded to write out only .cc file.
# We need to rename the extension to $(LOCAL_CPP_EXTENSION) if it's not .cc.
my_rename_cpp_ext := true
endif
my_proto_c_includes := external/protobuf/src
my_cflags += -DGOOGLE_PROTOBUF_NO_RTTI
my_protoc_flags := --cpp_out=$(proto_gen_dir)
endif
my_proto_c_includes += $(proto_gen_dir)

proto_sources_fullpath := $(addprefix $(LOCAL_PATH)/, $(proto_sources))
proto_generated_cpps := $(addprefix $(proto_gen_dir)/, \
    $(patsubst %.proto,%.pb$(my_proto_source_suffix),$(proto_sources_fullpath)))

define copy-proto-files
$(if $(PRIVATE_PROTOC_OUTPUT), \
   $(if $(call streq,$(PRIVATE_PROTOC_INPUT),$(PRIVATE_PROTOC_OUTPUT)),, \
   $(eval proto_generated_path := $(dir $(subst $(PRIVATE_PROTOC_INPUT),$(PRIVATE_PROTOC_OUTPUT),$@)))
   @mkdir -p $(dir $(proto_generated_path))
   @echo "Protobuf relocation: $(basename $@).h => $(proto_generated_path)"
   @cp -f $(basename $@).h $(proto_generated_path) ),)
endef

# Ensure the transform-proto-to-cc rule is only defined once in multilib build.
ifndef $(my_host)$(LOCAL_MODULE_CLASS)_$(LOCAL_MODULE)_proto_defined
$(proto_generated_cpps): PRIVATE_PROTO_INCLUDES := $(TOP)
$(proto_generated_cpps): PRIVATE_PROTOC_FLAGS := $(LOCAL_PROTOC_FLAGS) $(my_protoc_flags)
$(proto_generated_cpps): PRIVATE_PROTOC_OUTPUT := $(LOCAL_PROTOC_OUTPUT)
$(proto_generated_cpps): PRIVATE_PROTOC_INPUT := $(LOCAL_PATH)
$(proto_generated_cpps): PRIVATE_RENAME_CPP_EXT := $(my_rename_cpp_ext)
$(proto_generated_cpps): $(proto_gen_dir)/%.pb$(my_proto_source_suffix): %.proto $(my_protoc_deps) $(PROTOC)
	$(transform-proto-to-cc)
	$(copy-proto-files)

$(my_host)$(LOCAL_MODULE_CLASS)_$(LOCAL_MODULE)_proto_defined := true
endif
# Ideally we can generate the source directly into $(intermediates).
# But many Android.mks assume the .pb.hs are in $(generated_sources_dir).
# As a workaround, we make a copy in the $(intermediates).
proto_intermediate_dir := $(intermediates)/proto
proto_intermediate_cpps := $(patsubst $(proto_gen_dir)/%,$(proto_intermediate_dir)/%,\
    $(proto_generated_cpps))
$(proto_intermediate_cpps) : $(proto_intermediate_dir)/% : $(proto_gen_dir)/% | $(ACP)
	@echo "Copy: $@"
	$(copy-file-to-target)
	$(hide) cp $(basename $<).h $(basename $@).h
$(call track-src-file-gen,$(proto_sources),$(proto_intermediate_cpps))

my_generated_sources += $(proto_intermediate_cpps)

my_c_includes += $(my_proto_c_includes)
# Auto-export the generated proto source dir.
my_export_c_include_dirs += $(my_proto_c_includes)

ifeq ($(LOCAL_PROTOC_OPTIMIZE_TYPE),nanopb-c-enable_malloc)
    my_static_libraries += libprotobuf-c-nano-enable_malloc
else ifeq ($(LOCAL_PROTOC_OPTIMIZE_TYPE),nanopb-c)
    my_static_libraries += libprotobuf-c-nano
else ifeq ($(LOCAL_PROTOC_OPTIMIZE_TYPE),full)
    ifdef LOCAL_SDK_VERSION
        my_static_libraries += libprotobuf-cpp-full-ndk
    else
        my_shared_libraries += libprotobuf-cpp-full
    endif
else
    ifdef LOCAL_SDK_VERSION
        my_static_libraries += libprotobuf-cpp-lite-ndk
    else
        my_shared_libraries += libprotobuf-cpp-lite
    endif
endif
endif  # $(proto_sources) non-empty

###########################################################
## Compile the .dbus-xml files to c++ headers
###########################################################
dbus_definitions := $(filter %.dbus-xml,$(my_src_files))
dbus_generated_headers :=
ifneq ($(dbus_definitions),)

dbus_definition_paths := $(addprefix $(LOCAL_PATH)/,$(dbus_definitions))
dbus_service_config := $(filter %dbus-service-config.json,$(my_src_files))
dbus_service_config_path := $(addprefix $(LOCAL_PATH)/,$(dbus_service_config))

# Mark these source files as not producing objects
$(call track-src-file-obj,$(dbus_definitions) $(dbus_service_config),)

dbus_gen_dir := $(generated_sources_dir)/dbus_bindings

ifdef LOCAL_DBUS_PROXY_PREFIX
dbus_header_dir := $(dbus_gen_dir)/include/$(LOCAL_DBUS_PROXY_PREFIX)
dbus_headers := dbus-proxies.h
else
dbus_header_dir := $(dbus_gen_dir)
dbus_headers := $(patsubst %.dbus-xml,%.h,$(dbus_definitions))
endif
dbus_generated_headers := $(addprefix $(dbus_header_dir)/,$(dbus_headers))

# Ensure that we only define build rules once in multilib builds.
ifndef $(my_prefix)_$(LOCAL_MODULE_CLASS)_$(LOCAL_MODULE)_dbus_bindings_defined
$(my_prefix)_$(LOCAL_MODULE_CLASS)_$(LOCAL_MODULE)_dbus_bindings_defined := true

$(dbus_generated_headers): PRIVATE_MODULE := $(LOCAL_MODULE)
$(dbus_generated_headers): PRIVATE_DBUS_SERVICE_CONFIG := $(dbus_service_config_path)
$(dbus_generated_headers) : $(dbus_service_config_path) $(DBUS_GENERATOR)
ifdef LOCAL_DBUS_PROXY_PREFIX
$(dbus_generated_headers) : $(dbus_definition_paths)
	$(generate-dbus-proxies)
else
$(dbus_generated_headers) : $(dbus_header_dir)/%.h : $(LOCAL_PATH)/%.dbus-xml
	$(generate-dbus-adaptors)
endif  # $(LOCAL_DBUS_PROXY_PREFIX)
endif  # $(my_prefix)_$(LOCAL_MODULE_CLASS)_$(LOCAL_MODULE)_dbus_bindings_defined

ifdef LOCAL_DBUS_PROXY_PREFIX
# Auto-export the generated dbus proxy directory.
my_export_c_include_dirs += $(dbus_gen_dir)/include
my_c_includes += $(dbus_gen_dir)/include
else
my_export_c_include_dirs += $(dbus_header_dir)
my_c_includes += $(dbus_header_dir)
endif  # $(LOCAL_DBUS_PROXY_PREFIX)

my_generated_sources += $(dbus_generated_headers)

endif  # $(dbus_definitions) non-empty


###########################################################
## AIDL: Compile .aidl files to .cpp and .h files
###########################################################
aidl_src := $(strip $(filter %.aidl,$(my_src_files)))
aidl_gen_cpp :=
ifneq ($(aidl_src),)

# Use the intermediates directory to avoid writing our own .cpp -> .o rules.
aidl_gen_cpp_root := $(intermediates)/aidl-generated/src
aidl_gen_include_root := $(intermediates)/aidl-generated/include

# Multi-architecture builds have distinct intermediates directories.
# Thus we'll actually generate source for each architecture.
$(foreach s,$(aidl_src),\
    $(eval $(call define-aidl-cpp-rule,$(s),$(aidl_gen_cpp_root),aidl_gen_cpp)))
$(foreach cpp,$(aidl_gen_cpp), \
    $(call include-depfile,$(addsuffix .aidl.P,$(basename $(cpp))),$(cpp)))
$(call track-src-file-gen,$(aidl_src),$(aidl_gen_cpp))

$(aidl_gen_cpp) : PRIVATE_MODULE := $(LOCAL_MODULE)
$(aidl_gen_cpp) : PRIVATE_HEADER_OUTPUT_DIR := $(aidl_gen_include_root)
$(aidl_gen_cpp) : PRIVATE_AIDL_FLAGS := $(addprefix -I,$(LOCAL_AIDL_INCLUDES))

# Add generated headers to include paths.
my_c_includes += $(aidl_gen_include_root)
my_export_c_include_dirs += $(aidl_gen_include_root)
# Pick up the generated C++ files later for transformation to .o files.
my_generated_sources += $(aidl_gen_cpp)

endif  # $(aidl_src) non-empty

###########################################################
## Compile the .vts files to .cc (or .c) and then to .o
###########################################################

vts_src := $(strip $(filter %.vts,$(my_src_files)))
vts_gen_cpp :=
ifneq ($(vts_src),)

# Use the intermediates directory to avoid writing our own .cpp -> .o rules.
vts_gen_cpp_root := $(intermediates)/vts-generated/src
vts_gen_include_root := $(intermediates)/vts-generated/include

# Multi-architecture builds have distinct intermediates directories.
# Thus we'll actually generate source for each architecture.
$(foreach s,$(vts_src),\
    $(eval $(call define-vts-cpp-rule,$(s),$(vts_gen_cpp_root),vts_gen_cpp)))
$(foreach cpp,$(vts_gen_cpp), \
    $(call include-depfile,$(addsuffix .vts.P,$(basename $(cpp))),$(cpp)))
$(call track-src-file-gen,$(vts_src),$(vts_gen_cpp))

$(vts_gen_cpp) : PRIVATE_MODULE := $(LOCAL_MODULE)
$(vts_gen_cpp) : PRIVATE_HEADER_OUTPUT_DIR := $(vts_gen_include_root)
$(vts_gen_cpp) : PRIVATE_VTS_FLAGS := $(addprefix -I,$(LOCAL_VTS_INCLUDES))

# Add generated headers to include paths.
my_c_includes += $(vts_gen_include_root)
my_export_c_include_dirs += $(vts_gen_include_root)
# Pick up the generated C++ files later for transformation to .o files.
my_generated_sources += $(vts_gen_cpp)

endif  # $(vts_src) non-empty

###########################################################
## YACC: Compile .y/.yy files to .c/.cpp and then to .o.
###########################################################

y_yacc_sources := $(filter %.y,$(my_src_files))
y_yacc_cs := $(addprefix \
    $(intermediates)/,$(y_yacc_sources:.y=.c))
ifneq ($(y_yacc_cs),)
$(y_yacc_cs): $(intermediates)/%.c: \
    $(TOPDIR)$(LOCAL_PATH)/%.y \
    $(my_additional_dependencies)
	$(call transform-y-to-c-or-cpp)
$(call track-src-file-gen,$(y_yacc_sources),$(y_yacc_cs))

my_generated_sources += $(y_yacc_cs)
endif

yy_yacc_sources := $(filter %.yy,$(my_src_files))
yy_yacc_cpps := $(addprefix \
    $(intermediates)/,$(yy_yacc_sources:.yy=$(LOCAL_CPP_EXTENSION)))
ifneq ($(yy_yacc_cpps),)
$(yy_yacc_cpps): $(intermediates)/%$(LOCAL_CPP_EXTENSION): \
    $(TOPDIR)$(LOCAL_PATH)/%.yy \
    $(my_additional_dependencies)
	$(call transform-y-to-c-or-cpp)
$(call track-src-file-gen,$(yy_yacc_sources),$(yy_yacc_cpps))

my_generated_sources += $(yy_yacc_cpps)
endif

###########################################################
## LEX: Compile .l/.ll files to .c/.cpp and then to .o.
###########################################################

l_lex_sources := $(filter %.l,$(my_src_files))
l_lex_cs := $(addprefix \
    $(intermediates)/,$(l_lex_sources:.l=.c))
ifneq ($(l_lex_cs),)
$(l_lex_cs): $(intermediates)/%.c: \
    $(TOPDIR)$(LOCAL_PATH)/%.l
	$(transform-l-to-c-or-cpp)
$(call track-src-file-gen,$(l_lex_sources),$(l_lex_cs))

my_generated_sources += $(l_lex_cs)
endif

ll_lex_sources := $(filter %.ll,$(my_src_files))
ll_lex_cpps := $(addprefix \
    $(intermediates)/,$(ll_lex_sources:.ll=$(LOCAL_CPP_EXTENSION)))
ifneq ($(ll_lex_cpps),)
$(ll_lex_cpps): $(intermediates)/%$(LOCAL_CPP_EXTENSION): \
    $(TOPDIR)$(LOCAL_PATH)/%.ll
	$(transform-l-to-c-or-cpp)
$(call track-src-file-gen,$(ll_lex_sources),$(ll_lex_cpps))

my_generated_sources += $(ll_lex_cpps)
endif

###########################################################
## C++: Compile .cpp files to .o.
###########################################################

# we also do this on host modules, even though
# it's not really arm, because there are files that are shared.
cpp_arm_sources := $(patsubst %$(LOCAL_CPP_EXTENSION).arm,%$(LOCAL_CPP_EXTENSION),$(filter %$(LOCAL_CPP_EXTENSION).arm,$(my_src_files)))
dotdot_arm_sources := $(filter ../%,$(cpp_arm_sources))
cpp_arm_sources := $(filter-out ../%,$(cpp_arm_sources))
cpp_arm_objects := $(addprefix $(intermediates)/,$(cpp_arm_sources:$(LOCAL_CPP_EXTENSION)=.o))
$(call track-src-file-obj,$(patsubst %,%.arm,$(cpp_arm_sources)),$(cpp_arm_objects))

# For source files starting with ../, we remove all the ../ in the object file path,
# to avoid object file escaping the intermediate directory.
dotdot_arm_objects :=
$(foreach s,$(dotdot_arm_sources),\
  $(eval $(call compile-dotdot-cpp-file,$(s),\
  $(my_additional_dependencies),\
  dotdot_arm_objects)))
$(call track-src-file-obj,$(patsubst %,%.arm,$(dotdot_arm_sources)),$(dotdot_arm_objects))

dotdot_sources := $(filter ../%$(LOCAL_CPP_EXTENSION),$(my_src_files))
dotdot_objects :=
$(foreach s,$(dotdot_sources),\
  $(eval $(call compile-dotdot-cpp-file,$(s),\
    $(my_additional_dependencies),\
    dotdot_objects)))
$(call track-src-file-obj,$(dotdot_sources),$(dotdot_objects))

cpp_normal_sources := $(filter-out ../%,$(filter %$(LOCAL_CPP_EXTENSION),$(my_src_files)))
cpp_normal_objects := $(addprefix $(intermediates)/,$(cpp_normal_sources:$(LOCAL_CPP_EXTENSION)=.o))
$(call track-src-file-obj,$(cpp_normal_sources),$(cpp_normal_objects))

$(dotdot_arm_objects) $(cpp_arm_objects): PRIVATE_ARM_MODE := $(arm_objects_mode)
$(dotdot_arm_objects) $(cpp_arm_objects): PRIVATE_ARM_CFLAGS := $(arm_objects_cflags)
$(dotdot_objects) $(cpp_normal_objects): PRIVATE_ARM_MODE := $(normal_objects_mode)
$(dotdot_objects) $(cpp_normal_objects): PRIVATE_ARM_CFLAGS := $(normal_objects_cflags)

cpp_objects        := $(cpp_arm_objects) $(cpp_normal_objects)

ifneq ($(strip $(cpp_objects)),)
$(cpp_objects): $(intermediates)/%.o: \
    $(TOPDIR)$(LOCAL_PATH)/%$(LOCAL_CPP_EXTENSION) \
    $(my_additional_dependencies)
	$(transform-$(PRIVATE_HOST)cpp-to-o)
$(call include-depfiles-for-objs, $(cpp_objects))
endif

cpp_objects += $(dotdot_arm_objects) $(dotdot_objects)

###########################################################
## C++: Compile generated .cpp files to .o.
###########################################################

gen_cpp_sources := $(filter %$(LOCAL_CPP_EXTENSION),$(my_generated_sources))
gen_cpp_objects := $(gen_cpp_sources:%$(LOCAL_CPP_EXTENSION)=%.o)
$(call track-gen-file-obj,$(gen_cpp_sources),$(gen_cpp_objects))

ifneq ($(strip $(gen_cpp_objects)),)
# Compile all generated files as thumb.
# TODO: support compiling certain generated files as arm.
$(gen_cpp_objects): PRIVATE_ARM_MODE := $(normal_objects_mode)
$(gen_cpp_objects): PRIVATE_ARM_CFLAGS := $(normal_objects_cflags)
$(gen_cpp_objects): $(intermediates)/%.o: \
    $(intermediates)/%$(LOCAL_CPP_EXTENSION) \
    $(my_additional_dependencies)
	$(transform-$(PRIVATE_HOST)cpp-to-o)
$(call include-depfiles-for-objs, $(gen_cpp_objects))
endif

###########################################################
## S: Compile generated .S and .s files to .o.
###########################################################

gen_S_sources := $(filter %.S,$(my_generated_sources))
gen_S_objects := $(gen_S_sources:%.S=%.o)
$(call track-gen-file-obj,$(gen_S_sources),$(gen_S_objects))

ifneq ($(strip $(gen_S_sources)),)
$(gen_S_objects): $(intermediates)/%.o: $(intermediates)/%.S \
    $(my_additional_dependencies)
	$(transform-$(PRIVATE_HOST)s-to-o)
$(call include-depfiles-for-objs, $(gen_S_objects))
endif

gen_s_sources := $(filter %.s,$(my_generated_sources))
gen_s_objects := $(gen_s_sources:%.s=%.o)
$(call track-gen-file-obj,$(gen_s_sources),$(gen_s_objects))

ifneq ($(strip $(gen_s_objects)),)
$(gen_s_objects): $(intermediates)/%.o: $(intermediates)/%.s \
    $(my_additional_dependencies)
	$(transform-$(PRIVATE_HOST)s-to-o-no-deps)
endif

gen_asm_objects := $(gen_S_objects) $(gen_s_objects)
$(gen_asm_objects): PRIVATE_ARM_CFLAGS := $(normal_objects_cflags)

###########################################################
## o: Include generated .o files in output.
###########################################################

gen_o_objects := $(filter %.o,$(my_generated_sources))

###########################################################
## C: Compile .c files to .o.
###########################################################

c_arm_sources := $(patsubst %.c.arm,%.c,$(filter %.c.arm,$(my_src_files)))
dotdot_arm_sources := $(filter ../%,$(c_arm_sources))
c_arm_sources := $(filter-out ../%,$(c_arm_sources))
c_arm_objects := $(addprefix $(intermediates)/,$(c_arm_sources:.c=.o))
$(call track-src-file-obj,$(patsubst %,%.arm,$(c_arm_sources)),$(c_arm_objects))

# For source files starting with ../, we remove all the ../ in the object file path,
# to avoid object file escaping the intermediate directory.
dotdot_arm_objects :=
$(foreach s,$(dotdot_arm_sources),\
  $(eval $(call compile-dotdot-c-file,$(s),\
    $(my_additional_dependencies),\
    dotdot_arm_objects)))
$(call track-src-file-obj,$(patsubst %,%.arm,$(dotdot_arm_sources)),$(dotdot_arm_objects))

dotdot_sources := $(filter ../%.c, $(my_src_files))
dotdot_objects :=
$(foreach s, $(dotdot_sources),\
  $(eval $(call compile-dotdot-c-file,$(s),\
    $(my_additional_dependencies),\
    dotdot_objects)))
$(call track-src-file-obj,$(dotdot_sources),$(dotdot_objects))

c_normal_sources := $(filter-out ../%,$(filter %.c,$(my_src_files)))
c_normal_objects := $(addprefix $(intermediates)/,$(c_normal_sources:.c=.o))
$(call track-src-file-obj,$(c_normal_sources),$(c_normal_objects))

$(dotdot_arm_objects) $(c_arm_objects): PRIVATE_ARM_MODE := $(arm_objects_mode)
$(dotdot_arm_objects) $(c_arm_objects): PRIVATE_ARM_CFLAGS := $(arm_objects_cflags)
$(dotdot_objects) $(c_normal_objects): PRIVATE_ARM_MODE := $(normal_objects_mode)
$(dotdot_objects) $(c_normal_objects): PRIVATE_ARM_CFLAGS := $(normal_objects_cflags)

c_objects        := $(c_arm_objects) $(c_normal_objects)

ifneq ($(strip $(c_objects)),)
$(c_objects): $(intermediates)/%.o: $(TOPDIR)$(LOCAL_PATH)/%.c \
    $(my_additional_dependencies)
	$(transform-$(PRIVATE_HOST)c-to-o)
$(call include-depfiles-for-objs, $(c_objects))
endif

#c_objects += $(dotdot_arm_objects) $(dotdot_objects)

###########################################################
## C: Compile generated .c files to .o.
###########################################################

gen_c_sources := $(filter %.c,$(my_generated_sources))
gen_c_objects := $(gen_c_sources:%.c=%.o)
$(call track-gen-file-obj,$(gen_c_sources),$(gen_c_objects))

ifneq ($(strip $(gen_c_objects)),)
# Compile all generated files as thumb.
# TODO: support compiling certain generated files as arm.
$(gen_c_objects): PRIVATE_ARM_MODE := $(normal_objects_mode)
$(gen_c_objects): PRIVATE_ARM_CFLAGS := $(normal_objects_cflags)
$(gen_c_objects): $(intermediates)/%.o: $(intermediates)/%.c \
    $(my_additional_dependencies)
	$(transform-$(PRIVATE_HOST)c-to-o)
$(call include-depfiles-for-objs, $(gen_c_objects))
endif

###########################################################
## ObjC: Compile .m files to .o
###########################################################

objc_sources := $(filter %.m,$(my_src_files))
objc_objects := $(addprefix $(intermediates)/,$(objc_sources:.m=.o))
$(call track-src-file-obj,$(objc_sources),$(objc_objects))

ifneq ($(strip $(objc_objects)),)
$(objc_objects): $(intermediates)/%.o: $(TOPDIR)$(LOCAL_PATH)/%.m \
    $(my_additional_dependencies)
	$(transform-$(PRIVATE_HOST)m-to-o)
$(call include-depfiles-for-objs, $(objc_objects))
endif

###########################################################
## ObjC++: Compile .mm files to .o
###########################################################

objcpp_sources := $(filter %.mm,$(my_src_files))
objcpp_objects := $(addprefix $(intermediates)/,$(objcpp_sources:.mm=.o))
$(call track-src-file-obj,$(objcpp_sources),$(objcpp_objects))

ifneq ($(strip $(objcpp_objects)),)
$(objcpp_objects): $(intermediates)/%.o: $(TOPDIR)$(LOCAL_PATH)/%.mm \
    $(my_additional_dependencies)
	$(transform-$(PRIVATE_HOST)mm-to-o)
$(call include-depfiles-for-objs, $(objcpp_objects))
endif

###########################################################
## AS: Compile .S files to .o.
###########################################################

asm_sources_S := $(filter %.S,$(my_src_files))
dotdot_sources := $(filter ../%,$(asm_sources_S))
asm_sources_S := $(filter-out ../%,$(asm_sources_S))
asm_objects_S := $(addprefix $(intermediates)/,$(asm_sources_S:.S=.o))
$(call track-src-file-obj,$(asm_sources_S),$(asm_objects_S))

dotdot_objects_S :=
$(foreach s,$(dotdot_sources),\
  $(eval $(call compile-dotdot-s-file,$(s),\
    $(my_additional_dependencies),\
    dotdot_objects_S)))
$(call track-src-file-obj,$(dotdot_sources),$(dotdot_objects_S))

ifneq ($(strip $(asm_objects_S)),)
$(asm_objects_S): $(intermediates)/%.o: $(TOPDIR)$(LOCAL_PATH)/%.S \
    $(my_additional_dependencies)
	$(transform-$(PRIVATE_HOST)s-to-o)
$(call include-depfiles-for-objs, $(asm_objects_S))
endif

asm_sources_s := $(filter %.s,$(my_src_files))
dotdot_sources := $(filter ../%,$(asm_sources_s))
asm_sources_s := $(filter-out ../%,$(asm_sources_s))
asm_objects_s := $(addprefix $(intermediates)/,$(asm_sources_s:.s=.o))
$(call track-src-file-obj,$(asm_sources_s),$(asm_objects_s))

dotdot_objects_s :=
$(foreach s,$(dotdot_sources),\
  $(eval $(call compile-dotdot-s-file-no-deps,$(s),\
    $(my_additional_dependencies),\
    dotdot_objects_s)))
$(call track-src-file-obj,$(dotdot_sources),$(dotdot_objects_s))

ifneq ($(strip $(asm_objects_s)),)
$(asm_objects_s): $(intermediates)/%.o: $(TOPDIR)$(LOCAL_PATH)/%.s \
    $(my_additional_dependencies)
	$(transform-$(PRIVATE_HOST)s-to-o-no-deps)
endif

asm_objects := $(dotdot_objects_S) $(dotdot_objects_s) $(asm_objects_S) $(asm_objects_s)
$(asm_objects): PRIVATE_ARM_CFLAGS := $(normal_objects_cflags)


# .asm for x86/x86_64 needs to be compiled with yasm.
asm_sources_asm := $(filter %.asm,$(my_src_files))
ifneq ($(strip $(asm_sources_asm)),)
asm_objects_asm := $(addprefix $(intermediates)/,$(asm_sources_asm:.asm=.o))
$(asm_objects_asm): $(intermediates)/%.o: $(TOPDIR)$(LOCAL_PATH)/%.asm \
    $(my_additional_dependencies)
	$(transform-asm-to-o)
$(call track-src-file-obj,$(asm_sources_asm),$(asm_objects_asm))

asm_objects += $(asm_objects_asm)
endif


##########################################################
## Set up installed module dependency
## We cannot compute the full path of the LOCAL_SHARED_LIBRARIES for
## they may cusomize their install path with LOCAL_MODULE_PATH
##########################################################
# Get the list of INSTALLED libraries as module names.
ifdef LOCAL_SDK_VERSION
  installed_shared_library_module_names := \
      $(my_shared_libraries)
else
  installed_shared_library_module_names := \
      $(my_shared_libraries) $(my_system_shared_libraries)
endif

# The real dependency will be added after all Android.mks are loaded and the install paths
# of the shared libraries are determined.
ifdef LOCAL_INSTALLED_MODULE
ifdef installed_shared_library_module_names
$(my_prefix)DEPENDENCIES_ON_SHARED_LIBRARIES += \
    $(my_register_name):$(LOCAL_INSTALLED_MODULE):$(subst $(space),$(comma),$(sort $(installed_shared_library_module_names)))
endif
endif


####################################################
## Import includes
####################################################
import_includes := $(intermediates)/import_includes
import_includes_deps := $(strip \
    $(foreach l, $(installed_shared_library_module_names), \
      $(call intermediates-dir-for,SHARED_LIBRARIES,$(l),$(LOCAL_IS_HOST_MODULE),,,$(my_host_cross))/export_includes) \
    $(foreach l, $(my_static_libraries) $(my_whole_static_libraries), \
      $(call intermediates-dir-for,STATIC_LIBRARIES,$(l),$(LOCAL_IS_HOST_MODULE),,,$(my_host_cross))/export_includes))
$(import_includes): PRIVATE_IMPORT_EXPORT_INCLUDES := $(import_includes_deps)
$(import_includes) : $(LOCAL_MODULE_MAKEFILE_DEP) $(import_includes_deps)
	@echo Import includes file: $@
	$(hide) mkdir -p $(dir $@) && rm -f $@
ifdef import_includes_deps
	$(hide) for f in $(PRIVATE_IMPORT_EXPORT_INCLUDES); do \
	  cat $$f >> $@; \
	done
else
	$(hide) touch $@
endif

###########################################################
## Common object handling.
###########################################################


# some rules depend on asm_objects being first.  If your code depends on
# being first, it's reasonable to require it to be assembly
normal_objects := \
    $(asm_objects) \
    $(cpp_objects) \
    $(gen_cpp_objects) \
    $(gen_asm_objects) \
    $(c_objects) \
    $(gen_c_objects) \
    $(objc_objects) \
    $(objcpp_objects)


normal_objects += $(addprefix $(TOPDIR)$(LOCAL_PATH)/,$(LOCAL_PREBUILT_OBJ_FILES))

all_objects := $(normal_objects) $(gen_o_objects)


## Allow a device's own headers to take precedence over global ones
ifneq ($(TARGET_SPECIFIC_HEADER_PATH),)
my_c_includes := $(TOPDIR)$(TARGET_SPECIFIC_HEADER_PATH) $(my_c_includes)
endif

my_c_includes += $(TOPDIR)$(LOCAL_PATH) $(intermediates) $(generated_sources_dir)

ifndef LOCAL_SDK_VERSION
  my_c_includes += $(JNI_H_INCLUDE)
endif

# all_objects includes gen_o_objects which were part of LOCAL_GENERATED_SOURCES;
# use normal_objects here to avoid creating circular dependencies. This assumes
# that custom build rules which generate .o files don't consume other generated
# sources as input (or if they do they take care of that dependency themselves).
$(normal_objects) : | $(my_generated_sources)
#ifeq ($(BUILDING_WITH_NINJA),true)
#$(all_objects) : $(import_includes)
#else
$(all_objects) :
#| $(import_includes)
#endif
ALL_C_CPP_ETC_OBJECTS += $(all_objects)


###########################################################
# Standard library handling.
###########################################################

###########################################################
# The list of libraries that this module will link against are in
# these variables.  Each is a list of bare module names like "libc libm".
#
# LOCAL_SHARED_LIBRARIES
# LOCAL_STATIC_LIBRARIES
# LOCAL_WHOLE_STATIC_LIBRARIES
#
# We need to convert the bare names into the dependencies that
# we'll use for LOCAL_BUILT_MODULE and LOCAL_INSTALLED_MODULE.
# LOCAL_BUILT_MODULE should depend on the BUILT versions of the
# libraries, so that simply building this module doesn't force
# an install of a library.  Similarly, LOCAL_INSTALLED_MODULE
# should depend on the INSTALLED versions of the libraries so
# that they get installed when this module does.
###########################################################
# NOTE:
# WHOLE_STATIC_LIBRARIES are libraries that are pulled into the
# module without leaving anything out, which is useful for turning
# a collection of .a files into a .so file.  Linking against a
# normal STATIC_LIBRARY will only pull in code/symbols that are
# referenced by the module. (see gcc/ld's --whole-archive option)
###########################################################

# Get the list of BUILT libraries, which are under
# various intermediates directories.
so_suffix := $($(my_prefix)SHLIB_SUFFIX)
a_suffix := $($(my_prefix)STATIC_LIB_SUFFIX)

ifdef LOCAL_SDK_VERSION
built_shared_libraries := \
    $(addprefix $($(my_prefix)OUT_INTERMEDIATE_LIBRARIES)/, \
      $(addsuffix $(so_suffix), \
        $(my_shared_libraries)))
built_shared_library_deps := $(addsuffix .toc, $(built_shared_libraries))

# Add the NDK libraries to the built module dependency
my_system_shared_libraries_fullpath := \
    $(my_ndk_stl_shared_lib_fullpath) \
    $(addprefix $(my_ndk_sysroot_lib)/, \
        $(addsuffix $(so_suffix), $(my_system_shared_libraries)))

built_shared_libraries += $(my_system_shared_libraries_fullpath)
else
built_shared_libraries := \
    $(addprefix $($(my_prefix)OUT_INTERMEDIATE_LIBRARIES)/, \
      $(addsuffix $(so_suffix), \
        $(installed_shared_library_module_names)))
ifdef LOCAL_IS_HOST_MODULE
# Disable .toc optimization for host modules: we may run the host binaries during the build process
# and the libraries' implementation matters.
built_shared_library_deps := $(built_shared_libraries)
else
built_shared_library_deps := $(addsuffix .toc, $(built_shared_libraries))
endif
my_system_shared_libraries_fullpath :=
endif

built_static_libraries := \
    $(foreach lib,$(my_static_libraries), \
      $(call intermediates-dir-for, \
        STATIC_LIBRARIES,$(lib),$(LOCAL_IS_HOST_MODULE),,,$(my_host_cross))/$(lib)$(a_suffix))

ifdef LOCAL_SDK_VERSION
built_static_libraries += $(my_ndk_stl_static_lib)
endif

built_whole_libraries := \
    $(foreach lib,$(my_whole_static_libraries), \
      $(call intermediates-dir-for, \
        STATIC_LIBRARIES,$(lib),$(LOCAL_IS_HOST_MODULE),,,$(my_host_cross))/$(lib)$(a_suffix))

# We don't care about installed static libraries, since the
# libraries have already been linked into the module at that point.
# We do, however, care about the NOTICE files for any static
# libraries that we use. (see notice_files.mk)

installed_static_library_notice_file_targets := \
    $(foreach lib,$(my_static_libraries) $(my_whole_static_libraries), \
      NOTICE-$(if $(LOCAL_IS_HOST_MODULE),HOST,TARGET)-STATIC_LIBRARIES-$(lib))

# Default is -fno-rtti.
ifeq ($(strip $(LOCAL_RTTI_FLAG)),)
LOCAL_RTTI_FLAG := -fno-rtti
endif

###########################################################
# Rule-specific variable definitions
###########################################################

ifeq ($(my_clang),true)
my_cflags += $(LOCAL_CLANG_CFLAGS)
my_conlyflags += $(LOCAL_CLANG_CONLYFLAGS)
my_cppflags += $(LOCAL_CLANG_CPPFLAGS)
my_cflags_no_override += $(GLOBAL_CLANG_CFLAGS_NO_OVERRIDE)
my_cppflags_no_override += $(GLOBAL_CLANG_CPPFLAGS_NO_OVERRIDE)
my_asflags += $(LOCAL_CLANG_ASFLAGS)
my_ldflags += $(LOCAL_CLANG_LDFLAGS)
my_cflags += $(LOCAL_CLANG_CFLAGS_$($(my_prefix)ARCH)) $(LOCAL_CLANG_CFLAGS_$(my_32_64_bit_suffix))
my_conlyflags += $(LOCAL_CLANG_CONLYFLAGS_$($(my_prefix)ARCH)) $(LOCAL_CLANG_CONLYFLAGS_$(my_32_64_bit_suffix))
my_cppflags += $(LOCAL_CLANG_CPPFLAGS_$($(my_prefix)ARCH)) $(LOCAL_CLANG_CPPFLAGS_$(my_32_64_bit_suffix))
my_ldflags += $(LOCAL_CLANG_LDFLAGS_$($(my_prefix)ARCH)) $(LOCAL_CLANG_LDFLAGS_$(my_32_64_bit_suffix))
my_asflags += $(LOCAL_CLANG_ASFLAGS_$($(my_prefix)ARCH)) $(LOCAL_CLANG_ASFLAGS_$(my_32_64_bit_suffix))
my_cflags := $(call convert-to-$(my_host)clang-flags,$(my_cflags))
my_cppflags := $(call convert-to-$(my_host)clang-flags,$(my_cppflags))
my_asflags := $(call convert-to-$(my_host)clang-flags,$(my_asflags))
my_ldflags := $(call convert-to-$(my_host)clang-flags,$(my_ldflags))
endif

ifeq ($(my_fdo_build), true)
  my_cflags := $(patsubst -Os,-O2,$(my_cflags))
  fdo_incompatible_flags := -fno-early-inlining -finline-limit=%
  my_cflags := $(filter-out $(fdo_incompatible_flags),$(my_cflags))
endif

# No one should ever use this flag. On GCC it's mere presence will disable all
# warnings, even those that are specified after it (contrary to typical warning
# flag behavior). This circumvents CFLAGS_NO_OVERRIDE from forcibly enabling the
# warnings that are *always* bugs.
my_illegal_flags := -w
my_cflags := $(filter-out $(my_illegal_flags),$(my_cflags))
my_cppflags := $(filter-out $(my_illegal_flags),$(my_cppflags))
my_conlyflags := $(filter-out $(my_illegal_flags),$(my_conlyflags))

$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_YACCFLAGS := $(LOCAL_YACCFLAGS)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_ASFLAGS := $(my_asflags)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_CONLYFLAGS := $(my_conlyflags)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_CFLAGS := $(my_cflags)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_CPPFLAGS := $(my_cppflags)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_CFLAGS_NO_OVERRIDE := $(my_cflags_no_override)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_CPPFLAGS_NO_OVERRIDE := $(my_cppflags_no_override)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_RTTI_FLAG := $(LOCAL_RTTI_FLAG)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_DEBUG_CFLAGS := $(debug_cflags)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_C_INCLUDES := $(my_c_includes)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_IMPORT_INCLUDES := $(import_includes)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_LDFLAGS := $(my_ldflags)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_LDLIBS := $(my_ldlibs)

# this is really the way to get the files onto the command line instead
# of using $^, because then LOCAL_ADDITIONAL_DEPENDENCIES doesn't work
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_ALL_SHARED_LIBRARIES := $(built_shared_libraries)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_ALL_STATIC_LIBRARIES := $(built_static_libraries)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_ALL_WHOLE_STATIC_LIBRARIES := $(built_whole_libraries)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_ALL_OBJECTS := $(all_objects)

###########################################################
# Define library dependencies.
###########################################################
# all_libraries is used for the dependencies on LOCAL_BUILT_MODULE.
all_libraries := \
    $(built_shared_library_deps) \
    $(my_system_shared_libraries_fullpath) \
    $(built_static_libraries) \
    $(built_whole_libraries)

# Also depend on the notice files for any static libraries that
# are linked into this module.  This will force them to be installed
# when this module is.
$(LOCAL_INSTALLED_MODULE): | $(installed_static_library_notice_file_targets)

###########################################################
# Export includes
###########################################################
export_includes := $(intermediates)/export_includes
$(export_includes): PRIVATE_EXPORT_C_INCLUDE_DIRS := $(my_export_c_include_dirs)
# By adding $(my_generated_sources) it makes sure the headers get generated
# before any dependent source files get compiled.
$(export_includes) : $(my_generated_sources) $(export_include_deps)
	@echo Export includes file: $< -- $@
	$(hide) mkdir -p $(dir $@) && rm -f $@.tmp
ifdef my_export_c_include_dirs
	$(hide) for d in $(PRIVATE_EXPORT_C_INCLUDE_DIRS); do \
	        echo "-I $$d" >> $@.tmp; \
	        done
else
	$(hide) touch $@.tmp
endif
ifeq ($(BUILDING_WITH_NINJA),true)
	$(hide) if cmp -s $@.tmp $@ ; then \
	  rm $@.tmp ; \
	else \
	  mv $@.tmp $@ ; \
	fi
else
	mv $@.tmp $@ ;
endif

# Kati adds restat=1 to ninja. GNU make does nothing for this.
.KATI_RESTAT: $(export_includes)

# Make sure export_includes gets generated when you are running mm/mmm
$(LOCAL_BUILT_MODULE) : | $(export_includes)
