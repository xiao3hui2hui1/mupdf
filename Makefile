# GNU Makefile

build ?= debug

OUT := build/$(build)
GEN := generated

# --- Variables, Commands, etc... ---

default: all

# Do not specify CFLAGS or LIBS on the make invocation line - specify
# XCFLAGS or XLIBS instead. Make ignores any lines in the makefile that
# set a variable that was set on the command line.
CFLAGS += $(XCFLAGS) -Iinclude -Iscripts -I$(GEN) -Iucdn
LIBS += $(XLIBS) -lm

include Makerules
include Makethird

THIRD_LIBS += $(FREETYPE_LIB)
THIRD_LIBS += $(JBIG2DEC_LIB)
THIRD_LIBS += $(JPEG_LIB)
THIRD_LIBS += $(OPENJPEG_LIB)
THIRD_LIBS += $(OPENSSL_LIB)
THIRD_LIBS += $(ZLIB_LIB)

LIBS += $(FREETYPE_LIBS)
LIBS += $(JBIG2DEC_LIBS)
LIBS += $(JPEG_LIBS)
LIBS += $(OPENJPEG_LIBS)
LIBS += $(OPENSSL_LIBS)
LIBS += $(ZLIB_LIBS)

CFLAGS += $(FREETYPE_CFLAGS)
CFLAGS += $(JBIG2DEC_CFLAGS)
CFLAGS += $(JPEG_CFLAGS)
CFLAGS += $(OPENJPEG_CFLAGS)
CFLAGS += $(OPENSSL_CFLAGS)
CFLAGS += $(ZLIB_CFLAGS)

ifeq "$(verbose)" ""
QUIET_AR = @ echo ' ' ' ' AR $@ ;
QUIET_CC = @ echo ' ' ' ' CC $@ ;
QUIET_CXX = @ echo ' ' ' ' CXX $@ ;
QUIET_GEN = @ echo ' ' ' ' GEN $@ ;
QUIET_LINK = @ echo ' ' ' ' LINK $@ ;
QUIET_MKDIR = @ echo ' ' ' ' MKDIR $@ ;
QUIET_RM = @ echo ' ' ' ' RM $@ ;
endif

CC_CMD = $(QUIET_CC) $(CC) $(CFLAGS) -o $@ -c $<
CXX_CMD = $(QUIET_CXX) $(CXX) $(CFLAGS) -o $@ -c $<
AR_CMD = $(QUIET_AR) $(AR) cr $@ $^
LINK_CMD = $(QUIET_LINK) $(CC) $(LDFLAGS) -o $@ $^ $(LIBS)
MKDIR_CMD = $(QUIET_MKDIR) mkdir -p $@
RM_CMD = $(QUIET_RM) rm -f $@

# --- Rules ---

FITZ_HDR := include/mupdf/fitz.h
MUPDF_HDR := $(FITZ_HDR) include/mupdf/pdf.h
MUXPS_HDR := $(FITZ_HDR) include/mupdf/xps.h
MUCBZ_HDR := $(FITZ_HDR) include/mupdf/cbz.h
MUIMAGE_HDR := $(FITZ_HDR) include/mupdf/image.h

$(OUT) $(GEN) :
	$(MKDIR_CMD)

$(OUT)/%.a :
	$(RM_CMD)
	$(AR_CMD)
	$(RANLIB_CMD)

$(OUT)/% : $(OUT)/%.o
	$(LINK_CMD)

$(OUT)/%.o : fitz/%.c $(FITZ_HDR) | $(OUT)
	$(CC_CMD)
$(OUT)/%.o : draw/%.c $(FITZ_HDR) | $(OUT)
	$(CC_CMD)
$(OUT)/%.o : pdf/%.c $(MUPDF_HDR) | $(OUT)
	$(CC_CMD)
$(OUT)/%.o : pdf/%.cpp $(MUPDF_HDR) | $(OUT)
	$(CXX_CMD)
$(OUT)/%.o : xps/%.c $(MUXPS_HDR) | $(OUT)
	$(CC_CMD)
$(OUT)/%.o : cbz/%.c $(MUCBZ_HDR) | $(OUT)
	$(CC_CMD)
$(OUT)/%.o : image/%.c $(MUIMAGE_HDR) | $(OUT)
	$(CC_CMD)
$(OUT)/%.o : ucdn/%.c | $(OUT)
	$(CC_CMD)
$(OUT)/%.o : scripts/%.c | $(OUT)
	$(CC_CMD)

$(OUT)/x11_%.o : apps/x11_%.c $(FITZ_HDR) | $(OUT)
	$(CC_CMD) $(X11_CFLAGS)

$(OUT)/%.o : apps/%.c $(FITZ_HDR) $(MUPDF_HDR) | $(OUT)
	$(CC_CMD)


.PRECIOUS : $(OUT)/%.o # Keep intermediates from chained rules

# --- Fitz, MuPDF, MuXPS and MuCBZ library ---

MUPDF_LIB := $(OUT)/libmupdf.a
MUPDF_V8_LIB := $(OUT)/libmupdf-v8.a

FITZ_SRC := $(notdir $(wildcard fitz/*.c draw/*.c ucdn/*.c))
FITZ_SRC := $(filter-out draw_simple_scale.c, $(FITZ_SRC))
MUPDF_ALL_SRC := $(notdir $(wildcard pdf/*.c))
MUPDF_SRC := $(filter-out pdf_js.c pdf_jsimp_cpp.c, $(MUPDF_ALL_SRC))
MUPDF_V8_SRC := $(filter-out pdf_js_none.c, $(MUPDF_ALL_SRC))
MUPDF_V8_CPP_SRC := $(notdir $(wildcard pdf/*.cpp))
MUXPS_SRC := $(notdir $(wildcard xps/*.c))
MUCBZ_SRC := $(notdir $(wildcard cbz/*.c))
MUIMAGE_SRC := $(notdir $(wildcard image/*.c))

$(MUPDF_LIB) : $(addprefix $(OUT)/, $(FITZ_SRC:%.c=%.o))
$(MUPDF_LIB) : $(addprefix $(OUT)/, $(MUPDF_SRC:%.c=%.o))
$(MUPDF_LIB) : $(addprefix $(OUT)/, $(MUXPS_SRC:%.c=%.o))
$(MUPDF_LIB) : $(addprefix $(OUT)/, $(MUCBZ_SRC:%.c=%.o))
$(MUPDF_LIB) : $(addprefix $(OUT)/, $(MUIMAGE_SRC:%.c=%.o))

$(MUPDF_V8_LIB) : $(addprefix $(OUT)/, $(FITZ_SRC:%.c=%.o))
$(MUPDF_V8_LIB) : $(addprefix $(OUT)/, $(MUPDF_V8_SRC:%.c=%.o))
$(MUPDF_V8_LIB) : $(addprefix $(OUT)/, $(MUPDF_V8_CPP_SRC:%.cpp=%.o))
$(MUPDF_V8_LIB) : $(addprefix $(OUT)/, $(MUXPS_SRC:%.c=%.o))
$(MUPDF_V8_LIB) : $(addprefix $(OUT)/, $(MUCBZ_SRC:%.c=%.o))
$(MUPDF_V8_LIB) : $(addprefix $(OUT)/, $(MUIMAGE_SRC:%.c=%.o))

libs: $(MUPDF_LIB) $(THIRD_LIBS)
libs_v8: libs $(MUPDF_V8_LIB)

# --- Generated CMAP, FONT and JAVASCRIPT files ---

CMAPDUMP := $(OUT)/cmapdump
FONTDUMP := $(OUT)/fontdump
CQUOTE := $(OUT)/cquote
BIN2HEX := $(OUT)/bin2hex

CMAP_CNS_SRC := $(wildcard cmaps/cns/*)
CMAP_GB_SRC := $(wildcard cmaps/gb/*)
CMAP_JAPAN_SRC := $(wildcard cmaps/japan/*)
CMAP_KOREA_SRC := $(wildcard cmaps/korea/*)
FONT_BASE14_SRC := $(wildcard fonts/*.cff)
FONT_DROID_SRC := fonts/droid/DroidSans.ttf fonts/droid/DroidSansMono.ttf
FONT_CJK_SRC := fonts/droid/DroidSansFallback.ttf
FONT_CJK_FULL_SRC := fonts/droid/DroidSansFallbackFull.ttf

$(GEN)/cmap_cns.h : $(CMAP_CNS_SRC)
	$(QUIET_GEN) $(CMAPDUMP) $@ $(CMAP_CNS_SRC)
$(GEN)/cmap_gb.h : $(CMAP_GB_SRC)
	$(QUIET_GEN) $(CMAPDUMP) $@ $(CMAP_GB_SRC)
$(GEN)/cmap_japan.h : $(CMAP_JAPAN_SRC)
	$(QUIET_GEN) $(CMAPDUMP) $@ $(CMAP_JAPAN_SRC)
$(GEN)/cmap_korea.h : $(CMAP_KOREA_SRC)
	$(QUIET_GEN) $(CMAPDUMP) $@ $(CMAP_KOREA_SRC)

CMAP_GEN := $(addprefix $(GEN)/, cmap_cns.h cmap_gb.h cmap_japan.h cmap_korea.h)

$(GEN)/font_base14.h : $(FONT_BASE14_SRC)
	$(QUIET_GEN) $(FONTDUMP) $@ $(FONT_BASE14_SRC)
$(GEN)/font_droid.h : $(FONT_DROID_SRC)
	$(QUIET_GEN) $(FONTDUMP) $@ $(FONT_DROID_SRC)
$(GEN)/font_cjk.h : $(FONT_CJK_SRC)
	$(QUIET_GEN) $(FONTDUMP) $@ $(FONT_CJK_SRC)
$(GEN)/font_cjk_full.h : $(FONT_CJK_FULL_SRC)
	$(QUIET_GEN) $(FONTDUMP) $@ $(FONT_CJK_FULL_SRC)

FONT_GEN := $(GEN)/font_base14.h $(GEN)/font_droid.h $(GEN)/font_cjk.h $(GEN)/font_cjk_full.h

JAVASCRIPT_SRC := pdf/pdf_util.js
JAVASCRIPT_GEN := $(GEN)/js_util.h
$(JAVASCRIPT_GEN) : $(JAVASCRIPT_SRC)
	$(QUIET_GEN) $(CQUOTE) $@ $(JAVASCRIPT_SRC)

ADOBECA_SRC := certs/AdobeCA.p7c
ADOBECA_GEN := $(GEN)/adobe_ca.h
$(ADOBECA_GEN) : $(ADOBECA_SRC)
	$(QUIET_GEN) $(BIN2HEX) $@ $(ADOBECA_SRC)

ifeq "$(CROSSCOMPILE)" ""
$(CMAP_GEN) : $(CMAPDUMP) | $(GEN)
$(FONT_GEN) : $(FONTDUMP) | $(GEN)
$(JAVASCRIPT_GEN) : $(CQUOTE) | $(GEN)
$(ADOBECA_GEN) : $(BIN2HEX) | $(GEN)
endif

generate: $(CMAP_GEN) $(FONT_GEN) $(JAVASCRIPT_GEN) $(ADOBECA_GEN)

$(OUT)/pdf_cmap_table.o : $(CMAP_GEN)
$(OUT)/pdf_fontfile.o : $(FONT_GEN)
$(OUT)/pdf_js.o : $(JAVASCRIPT_GEN)
$(OUT)/crypt_pkcs7.o : $(ADOBECA_GEN)
$(OUT)/cmapdump.o : pdf/pdf_cmap.c pdf/pdf_cmap_parse.c

# --- Tools and Apps ---

MUDRAW := $(addprefix $(OUT)/, mudraw)
$(MUDRAW) : $(MUPDF_LIB) $(THIRD_LIBS)

MUTOOL := $(addprefix $(OUT)/, mutool)
$(MUTOOL) : $(addprefix $(OUT)/, pdfclean.o pdfextract.o pdfinfo.o pdfposter.o pdfshow.o) $(MUPDF_LIB) $(THIRD_LIBS)

ifeq "$(NOX11)" ""

MUVIEW := $(OUT)/mupdf
$(MUVIEW) : $(MUPDF_LIB) $(THIRD_LIBS)
$(MUVIEW) : $(addprefix $(OUT)/, x11_main.o x11_image.o pdfapp.o)
	$(LINK_CMD) $(X11_LIBS)

MUVIEW_V8 := $(OUT)/mupdf-v8
$(MUVIEW_V8) : $(MUPDF_V8_LIB) $(THIRD_LIBS)
$(MUVIEW_V8) : $(addprefix $(OUT)/, x11_main.o x11_image.o pdfapp.o)
	$(LINK_CMD) $(X11_LIBS) $(V8_LIBS)
endif

MUJSTEST_V8 := $(OUT)/mujstest-v8
$(MUJSTEST_V8) : $(MUPDF_V8_LIB) $(THIRD_LIBS)
$(MUJSTEST_V8) : $(addprefix $(OUT)/, jstest_main.o pdfapp.o)
	$(LINK_CMD) $(V8_LIBS)

ifeq "$(V8_PRESENT)" "1"
JSTARGETS := $(MUJSTEST_V8) $(MUPDF_V8_LIB) $(MUVIEW_V8)
else
JSTARGETS :=
endif

# --- Format man pages ---

%.txt: %.1
	nroff -man $< | col -b | expand > $@

MAN_FILES := $(wildcard apps/man/*.1)
TXT_FILES := $(MAN_FILES:%.1=%.txt)

catman: $(TXT_FILES)

# --- Install ---

prefix ?= /usr/local
bindir ?= $(prefix)/bin
libdir ?= $(prefix)/lib
incdir ?= $(prefix)/include
mandir ?= $(prefix)/share/man

install: $(MUPDF_LIB) $(MUVIEW) $(MUDRAW) $(MUTOOL)
	install -d $(DESTDIR)$(bindir) $(DESTDIR)$(libdir) $(DESTDIR)$(incdir) $(DESTDIR)$(mandir)/man1
	install $(MUPDF_LIB) $(DESTDIR)$(libdir)
	install fitz/memento.h fitz/fitz.h pdf/mupdf.h xps/muxps.h cbz/mucbz.h image/muimage.h $(DESTDIR)$(incdir)
	install $(MUVIEW) $(MUDRAW) $(MUTOOL) $(DESTDIR)$(bindir)
	install $(wildcard apps/man/*.1) $(DESTDIR)$(mandir)/man1

# --- Clean and Default ---

tags: $(wildcard */*.h */*.c)
	ctags $^

all: all-nojs $(JSTARGETS)

all-nojs: $(THIRD_LIBS) $(MUPDF_LIB) $(MUVIEW) $(MUDRAW) $(MUTOOL)

third: $(THIRD_LIBS)

clean:
	rm -rf $(OUT)
nuke:
	rm -rf build/* $(GEN)

.PHONY: all clean nuke install
