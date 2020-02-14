#
# Proj: yama
# Auth: matveyt
# Desc: Yet Another GNU Make framework
# Note: None
#


# check Make version
ifneq (3.81,$(firstword $(sort 3.81 $(MAKE_VERSION))))
    $(error GNU Make v3.81+ required)
endif


# prevent multiple inclusion
ifndef yama.IsDug


# global init
.PHONY: all
.DEFAULT_GOAL := all
BUILDROOT ?= $(CURDIR)
SRCROOT ?= $(dir $(firstword $(MAKEFILE_LIST)))
ARFLAGS0 := rv
CPPFLAGS0 :=
CFLAGS0 := -pipe -Wall -Wextra
CXXFLAGS0 := $(CFLAGS0)
LDFLAGS0 :=
ifeq ($(BUILDTYPE),debug)
    CPPFLAGS0 += -DDEBUG -D_DEBUG
    CFLAGS0 += -g
    CXXFLAGS0 += -g
endif
ifeq ($(BUILDTYPE),release)
    CPPFLAGS0 += -DNDEBUG
    CFLAGS0 += -O2
    CXXFLAGS0 += -O2
    LDFLAGS0 += -s
endif
ifeq ($(BUILDTYPE),minsize)
    CPPFLAGS0 += -DNDEBUG
    CFLAGS0 += -Os
    CXXFLAGS0 += -Os
    LDFLAGS0 += -s -fno-ident -Wl,--gc-sections
endif
ARFLAGS := $(ARFLAGS0)
CPPFLAGS := $(CPPFLAGS0)
CFLAGS := $(CFLAGS0)
CXXFLAGS := $(CXXFLAGS0)
LDFLAGS := $(LDFLAGS0)


# Note: both may be true at the same time (e.g. MSYS)
yama.IsWindows := $(if $(COMSPEC)$(ComSpec),1)
yama.IsPOSIX := $(if $(filter /%,$(CURDIR)),1)


# <bool> := $(call yama.pathIsAbs,<path>)
# <newpath> := $(call yama.pathWithSlash,<path>)
# <newpath> := $(call yama.pathOrDot,<path>)
# <newpath> := $(call yama.pathStrip,<path>)
# <newpath> := $(call yama.pathConcat,<path1>,<path2>)
# <newpath> := $(call yama.pathConcatWithSlash,<path1>,<path2>)
# <newpath> := $(call yama.pathConcatOrDot,<path1>,<path2>)
yama.Latin := A a B b C c D d E e F f G g H h I i J j K k L l M m
yama.Latin += N n O o P p Q q R r S s T t U u V v W w X x Y y Z z
ifdef yama.IsWindows
    yama.pathIsAbs = $(if $(filter /% \\% $(if $(yama.IsPOSIX),~%)\
        $(foreach foo$0,$(yama.Latin),$(foo$0):/% $(foo$0):\\%),$1),1)
else
    yama.pathIsAbs = $(if $(filter /% ~%,$1),1)
endif
yama.pathWithSlash = $(if $(filter-out %/,$1),$1/,$1)
yama.pathOrDot = $(or $1,.)
yama.pathStrip = $(patsubst $(CURDIR)/%,%,$(filter-out $(CURDIR),$(abspath $1)))
yama.pathConcat = $(call yama.pathStrip,$(if $(call yama.pathIsAbs,$2),$2,\
    $(call yama.pathWithSlash,$1)$2))
yama.pathConcatWithSlash = $(call yama.pathWithSlash,$(call yama.pathConcat,$1,$2))
yama.pathConcatOrDot = $(call yama.pathOrDot,$(call yama.pathConcat,$1,$2))


# Build/Source/Include etc.
yama.Build0 := $(call yama.pathWithSlash,$(call yama.pathStrip,$(BUILDROOT)))
yama.Source0 := $(call yama.pathWithSlash,$(call yama.pathStrip,$(SRCROOT)))
yama.Include := $(call yama.pathWithSlash,$(call yama.pathStrip,\
    $(dir $(firstword $(MAKEFILE_LIST)))))
yama.Build := $(yama.Build0)
yama.Source := $(yama.Source0)
yama.Level = $(if $(yama.Include.Stack),$(call yama.depth,yama.Include))
yama.A := .a
yama.O := .o
yama.Dll := $(if $(yama.IsWindows),.dll,.so)
yama.Exe := $(if $(yama.IsPOSIX),,.exe)
yama.Sep := $(if $(yama.IsWindows),;,:)
yama.Space := $(yama.Space) #
define yama.NL :=


endef


# $(call yama.push,<vars_list>)
# $(call yama.pop,<vars_list>)
# <val> := $(call yama.top,<var>)
# <val> := $(call yama.bottom,<var>)
# <num> := $(call yama.depth,<var>)
yama.push = $(eval $(foreach foo$0,$1,\
    $(foo$0).Stack := \
        §$(subst $(yama.Space),§,$($(foo$0))) $($(foo$0).Stack)$(yama.NL)\
))
yama.pop = $(eval $(foreach foo$0,$1,\
    $(foo$0) := $(call yama.top,$(foo$0))$(yama.NL)\
    $(foo$0).Stack := \
        $(wordlist 2,$(words $($(foo$0).Stack)),$($(foo$0).Stack))$(yama.NL)\
))
yama.top = $(strip $(subst §,$(yama.Space),$(firstword $($1.Stack))))
yama.bottom = $(strip $(subst §,$(yama.Space),$(lastword $($1.Stack))))
yama.depth = $(words $($1.Stack))


# <new_string> := $(call yama.repeat,<string>,<number>)
yama.repeat.text = $(if $(word $2,$3),,$1$(call yama.repeat.text,$1,$2,$3 w))
yama.repeat = $(if $(filter-out 0,$2),$(call yama.repeat.text,$1,$2))


# <var> = $(call yama.lazyShell,<shell_command>,<var>)
yama.lazyShell = $(eval $2 := $$(shell $1))$($2)


# $(yama.LFSR) -- iv = 0x52525252
# $(yama.random) -- xorshift32, [a, b, c] = [13, 17, 5]
# $(yama.last_random)
yama.LFSR ?= 0 1 0 0 1 0 1 0 0 1 0 0 1 0 1 0 0 1 0 0 1 0 1 0 0 1 0 0 1 0 1 0
yama.last_random = $(subst $(yama.Space),,$(yama.LFSR))
yama.random = $(strip \
    $(eval yama.LFSR := $(wordlist 1,13,$(yama.LFSR)) $(join \
        $(wordlist 14,32,$(yama.LFSR)),$(wordlist 1,19,$(yama.LFSR))))\
    $(eval yama.LFSR := $(join $(yama.LFSR),$(wordlist 18,32,$(yama.LFSR))))\
    $(eval yama.LFSR := $(wordlist 1,5,$(yama.LFSR)) $(join \
        $(wordlist 6,32,$(yama.LFSR)),$(wordlist 1,27,$(yama.LFSR))))\
    $(eval yama.LFSR := $(subst .,0 ,$(subst 1.,1 ,$(subst 11,,$(subst 0,,\
        $(subst $(yama.Space),.,$(yama.LFSR).))))))\
)$(yama.last_random)


# $(call yama.options,<options_list>)
yama.options.text = $(if $(filter 1 on On ON yes Yes YES,$($1)),\
    $($1.on),$($1.off))
yama.options = $(eval $(foreach foo$0,$1,\
        $(call yama.options.text,$(foo$0))$(yama.NL)\
))


# $(call yama.goalExe,<target>,<modules_list>,[binary_name],[build_subdir])
define yama.goalExe.text
    $(eval foo$0 := $(patsubst %,$4%$(yama.O),$2))
    $(if $(subst x$1,,x$3)$(subst x$3,,x$1),\
        .PHONY: $1$(yama.NL)\
        $1: $3$(yama.NL)\
    )
    $3: $(foo$0) $(if $($1.Objects),,;\
        $(CC) $(LDFLAGS) $$^ $(LDLIBS) -o $$@)
    $1.Objects := $($1.Objects) $(foo$0)
endef
yama.goalExe = $(eval \
    $(eval \
        $1 := $(call yama.pathConcat,$(yama.Build),$(or $3,$1)$(yama.Exe))$(yama.NL)\
        foo$0 := $(call yama.pathConcatWithSlash,$(yama.Build),$4)$(yama.NL)\
    )\
    $(call yama.goalExe.text,$1,$2,$($1),$(foo$0))$(yama.NL)\
)


# $(call yama.goalDll,<target>,<modules_list>,[library_name],[build_subdir])
define yama.goalDll.text
    $(eval foo$0 := $(patsubst %,$4%$(yama.O),$2))
    $(if $(subst x$1,,x$3)$(subst x$3,,x$1),\
        .PHONY: $1$(yama.NL)\
        $1: $3$(yama.NL)\
    )
ifdef yama.IsWindows
    $3: $(foo$0) $(if $($1.Objects),,;\
        $(CC) -shared -Wl,--out-implib,$$(@D)/lib$$(@F)$(yama.A)\
            $(LDFLAGS) $$^ $(LDLIBS) -o $$@)
else
    $3: $(foo$0) $(if $($1.Objects),,;\
        $(CC) -shared $(LDFLAGS) $$^ $(LDLIBS) -o $$@)
endif
    $1.Objects := $($1.Objects) $(foo$0)
endef
yama.goalDll = $(eval \
    $(eval \
        $1 := $(call yama.pathConcat,$(yama.Build),$(or $3,$1)$(yama.Dll))$(yama.NL)\
        foo$0 := $(call yama.pathConcatWithSlash,$(yama.Build),$4)$(yama.NL)\
    )\
    $(call yama.goalDll.text,$1,$2,$($1),$(foo$0))$(yama.NL)\
)


# $(call yama.goalLib,<target>,<modules_list>,[library_name],[build_subdir])
define yama.goalLib.text
    $(eval foo$0 := $(patsubst %,$4%$(yama.O),$2))
    $(if $(subst x$1,,x$3)$(subst x$3,,x$1),\
        .PHONY: $1$(yama.NL)\
        $1: $3$(yama.NL)\
    )
    $3: $(foo$0) $(if $($1.Objects),,;\
        $(AR) $(ARFLAGS) $$@ $$?)
    $1.Objects := $($1.Objects) $(foo$0)
endef
yama.goalLib = $(eval \
    $(eval \
        $1 := $(call yama.pathConcat,$(yama.Build),$(or $3,$1)$(yama.A))$(yama.NL)\
        foo$0 := $(call yama.pathConcatWithSlash,$(yama.Build),$4)$(yama.NL)\
    )\
    $(call yama.goalLib.text,$1,$2,$($1),$(foo$0))$(yama.NL)\
)


# $(call yama.rules,[build_directory],[source_directory],[languages_list])
define yama.rules.text
    $(if $1,$1: ;mkdir -p $$@)
    $(foreach foo$0,$3,\
        $(call yama.rules.$(foo$0),$1,$2)$(yama.NL)\
    )
endef
yama.rules = $(eval \
    $(eval \
        foo$0 := $(call yama.pathConcatWithSlash,$(yama.Build),$1)$(yama.NL)\
        bar$0 := $(call yama.pathConcatWithSlash,$(yama.Source),$2)$(yama.NL)\
    )\
    $(call yama.rules.text,$(foo$0),$(bar$0),$(or $3,c))$(yama.NL)\
)
-include $(dir $(lastword $(MAKEFILE_LIST)))rules.yama


# $(call yama.deps,<objects_list>)
UPDBDEPS := updbdeps -z 10m --remove
yama.DEPS := $(yama.Build0).deps
define yama.deps.text
    $(foreach foo$0,$1,\
        $(foo$0): $(foo$0:$(yama.O)=.d)$(yama.NL)\
        $(foo$0:$(yama.O)=.d): ;$(yama.NL)\
    )
    include $(wildcard $(1:$(yama.O)=.d))
endef
define yama.deps.text2.once
    $(dbdeps $(yama.DEPS))
    all: $(yama.DEPS)/data.mdb
    undefine yama.deps.text2.once
endef
define yama.deps.text2
    $(yama.deps.text2.once)
    $(yama.DEPS)/data.mdb:: $1;\
        $(UPDBDEPS) $$(?:$(yama.O)=.d) -d $$(@D)
endef
yama.deps = $(eval \
    $(call $(if $(filter %dbdeps$(yama.Dll),$(.LOADED)),\
        yama.deps.text2,yama.deps.text),$1)$(yama.NL)\
)


# $(call yama.subdirs,<subdirs_list>)
# $(call yama.subdir,<build_subdir>,[source_subdir],[include_file])
define yama.subdir.text
    $(call yama.push,yama.Build yama.Source yama.Include)
    $(eval \
        yama.Build := $(call yama.pathConcatWithSlash,$(yama.Build),$1)$(yama.NL)\
        yama.Source := $(call yama.pathConcatWithSlash,$(yama.Source),$2)$(yama.NL)\
        yama.Include := $(call yama.pathConcatWithSlash,$(yama.Include),$3)$(yama.NL)\
    )
    $(eval include $(filter-out $(MAKEFILE_LIST),$(firstword $(wildcard \
        $(addprefix $(yama.Include),$(or $4,GNUmakefile makefile Makefile *.yama))\
    ))))
    $(call yama.pop,yama.Build yama.Source yama.Include)
endef
yama.subdir = $(strip \
    $(call yama.subdir.text,$1,$(or $2,$1),$(or $(dir $3),$2,$1),$(notdir $3))\
)
yama.subdirs = $(strip $(foreach foo$0,$1,\
    $(eval bar$0 := $(subst $(yama.Sep),$(yama.Space),$(foo$0)))\
    $(call yama.subdir,$(word 1,$(bar$0)),$(word 2,$(bar$0)),$(word 3,$(bar$0)))\
))


# prevent multiple inclusion
yama.IsDug := 1
else
# reset all flags and libs
$(eval $(foreach foo,$(filter-out %MAKEFLAGS MFLAGS .SHELLFLAGS,\
    $(filter %FLAGS %LIBS,$(.VARIABLES))),$(foo) := $($(foo)0)$(yama.NL)))
endif
