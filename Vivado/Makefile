include config.mk

# ============================================================
# Tools
# ============================================================

VIVADO          := ./.Docker/vivado-docker
OPENFPGALOADER  ?= openFPGALoader
VIVADO_WIN      ?= C:/Xilinx/2026.1/Vivado/bin/vivado.bat

PROGRAM_TCL     := scripts/program.tcl
FLOW_TCL        := scripts/flow.tcl
BITSTREAM       := $(BUILD_DIR)/$(PROJECT).bit


# ============================================================
# Arguments used by every flow stage
# ============================================================

FLOW_ARGS = \
	PROJECT="$(PROJECT)" \
	TOP="$(TOP)" \
	SIM_TOP="$(SIM_TOP)" \
	PART="$(PART)" \
	PROJECT_DIR="$(PROJECT_DIR)" \
	BUILD_DIR="$(BUILD_DIR)" \
	RTL_DIR="$(RTL_DIR)" \
	TB_DIR="$(TB_DIR)" \
	XDC_DIR="$(XDC_DIR)" \
	HDL="$(HDL)" \
	VHDL_STD="$(VHDL_STD)" \
	JOBS="$(JOBS)" \
	PHYS_OPT="$(PHYS_OPT)" \
	FAIL_TIMING="$(FAIL_TIMING)" \
	SIM_TIME="$(SIM_TIME)"

# $(call RUN_VIVADO,project build)
define RUN_VIVADO
	$(VIVADO) \
		-mode batch \
		-nolog \
		-nojournal \
		-source $(FLOW_TCL) \
		-tclargs \
			FLOW="$(1)" \
			$(FLOW_ARGS)
endef

# Run a flow that starts from a freshly generated Vivado project.
define RUN_FRESH_FLOW
	rm -rf $(PROJECT_DIR)
	rm -rf *.jou
	rm -rf *.log
	mkdir -p $(BUILD_DIR)
	$(call RUN_VIVADO,$(1))
endef


.PHONY: all project pins build sim full reports flash flash-mac flash-windows clean

all: build


# ============================================================
# Vivado flows
#
# Each target below uses ONE Vivado process. For example, `make full`
# performs project -> pins -> build -> sim without closing the project
# between stages.
# ============================================================

project:
	$(call RUN_FRESH_FLOW,project)

pins:
	$(call RUN_FRESH_FLOW,project pins)

build:
	$(call RUN_FRESH_FLOW,project build)

sim:
	$(call RUN_FRESH_FLOW,project sim)

full:
	$(call RUN_FRESH_FLOW,project pins build sim)


# ============================================================
# Reports
# ============================================================

reports:
	@echo "Vivado reports:"
	@find $(BUILD_DIR)/reports -type f 2>/dev/null || true



# ============================================================
# Flash Device
# ============================================================


ifeq ($(OS),Windows_NT)
flash: build flash-windows 
else 
flash: build flash-mac 
endif


flash-mac: 
	$(OPENFPGALOADER) \
		-b $(BOARD) \
		$(BITSTREAM)


flash-windows: 
	$(VIVADO_WIN) \
		-mode batch \
		-nolog \
		-nojournal \
		-source $(PROGRAM_TCL) \
		-tclargs \
			BITSTREAM="$(BITSTREAM)" \
			HW_SERVER="$(HW_SERVER)" \
			HW_DEVICE="$(HW_DEVICE)"


tcl: project
	./.Docker/vivado-docker -mode tcl

gui: project
	./.Docker/vivado-docker -mode gui

# ============================================================
# Cleanup
# ============================================================

clean:
	rm -rf $(BUILD_DIR)
	rm -rf .Xil
