# makefile for bndr project
# make 		-> make all (all BUT symon)
# make symon 	-> makes ROM*.s with defines for symon and starts symon
# make clean 	-> removes all .bin,.prg
# make rom 	-> makes 32k rom files matching ROM*.s - not c64 prg			-> .bin
# make prog 	-> makes c4 prg bin files not matching ROM but with extension .s 	-> .prg
# make 3rdparty -> makes c4 prg bin files from extensions .vasm 			-> .prg
# make pretty	-> prettifies .s, .vasm and .inc to set rules.
#.DEFAULT_GOAL := help

PRETTIFIER  	= ./prettify.sh
VASM	      	= ~/sources/vasm/vasm6502_oldstyle
VASMOPTS 	= -maxerrors=0 -esc -Fbin -dotdir -ldots -wdc02 -quiet
VASMDEFS	= -Dnolcd
#VASMDEFS	= -Dlcd
SYMON 		= java -jar symon-1.3.2.jar -m bender -cpu 65c02
BIN 		= bin
BINSYMON	= binsymon

all: inc rom srom prog sprog 3rdparty ## build all roms, programs and any 3rdparty programs


release: all millfork

millfork:
	cd millfork && $(MAKE) clean && $(MAKE) -j8 release && echo "Millfork Done"

inc:
	./jmp_table.raku ROM.s

prog: 	  $(addsuffix .prg, $(basename $(wildcard [^R][^O][^M]*.s))) ## builds user programs
sprog: 	  $(addsuffix .sprg, $(basename $(wildcard [^R][^O][^M]*.s))) ## builds user program for symon
rom:      $(addsuffix .bin, $(basename $(wildcard ROM*.s))) ## builds rom images
	@echo "// File created automatically by make" `date` > global.exports
	@grep -E "\w:\w+\sEXP" ROM.bin.lst >> global.exports
	sed -i -e 's/[SAE]:/  @$$/g ; s/E:/=  $$/g ; s/EXP//g' -e'2,$$ s/^/byte /' -e 's/byte osCallArg/word osCallArg/g' global.exports
	@./os_exports.raku

srom:     $(addsuffix .sbin, $(basename $(wildcard ROM*.s))) ## builds rom images for symon
3rdparty: $(addsuffix .prg, $(basename $(wildcard *.vasm))) ## builds user 3rd party programs

%.prg : %.s		## build user programs -> .s to c64 .prg
	$(VASM) $(VASMOPTS) $(VASMDEFS) -cbm-prg -i $< -o $(BIN)/$@ -L $@.lst

%.sprg : %.s		## build user programs SYMON only not c64 .prg-> .s to .sprg
	$(VASM) $(VASMOPTS) $(VASMDEFS) -i $< -o $(BINSYMON)/$@ -L $@.lst

%.bin : %.s		## build roms -> ROM*.s 32k bin
	$(VASM) $(VASMOPTS) $(VASMDEFS) -i $< -o $@ -L $@.lst

%.sbin : %.s		## build rom for symon emulator
	$(VASM) $(VASMOPTS) $(VASMDEFS) -Dsymon -i $< -o $@ -L $@.lst


.PHONY: clean pretty symon gitcommit help millfork  release

symon: srom sprog 	## build roms as .sbin compiled for symon virtual bender target.

symonrun: symon		## run symon vm
	$(SYMON) -r ROM.sbin
clean: 			## remove binaries and compilation detrius
	@echo "Cleaning..."
	@rm -f *.bin *.prg *.sprg *.sbin *.lst $(BIN)/* $(BINSYMON)/*
	@rm global.exports

pretty:   		## prettify all source files
	@echo "Making source files pretty..."
	@$(PRETTIFIER)

gitcommit: clean pretty    ## cleans and prettifys for git commit - runs git awaits message
	@git commit -a

help:  ## display this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
