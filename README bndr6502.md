### bndr6502

Coding conventions

**Lables**
_name...                    local and private - do not call
os[LibraryName]_[Routine]   os library - for calling
k[LibraryName]_[Routine]    kernal - for calling (Interrupt, Main's etc)

**Includes:**
Kernal ZP allocations
BNDR6502 memory map

How to do headers for calling?



### Memory Map
$FE00           IOspace 8 devices 32 bits spacing $00 $20 $40 etc
$fe00   ACIA
$fe20   VIA 0
$8000-$EFFF     General start of ROM
$1000-$7FFF     User program space
$0400-$047F     onewire space
$0300-$03FF      kernal output buffer
$0200-$02FF     kernal input buffer
$0100-$01FF     System stack
$f9             Warm or Cold start (1 warm start set to 0 for cold // enything else)
$fa             shadow irq vector
$fc             shadow nmi vector
$fe             shadow reset (warm)

### Hardware
VIA 1 port B (and 3 bits of A) 2x20 line display
VIA 2 port A pin 1 - onewire interface


### Serial software
alias bender='cd /home/kevin/Nextcloud/development/breadboard/code'
alias bndr6502='screen  /dev/ttyUSB0 19200'

Uses screen and need lrzsz or some such package (apt-get install screen lrzsz)

minicom

**Screen commands (first line bndr6502)**
screen [device] [baud]
ctrl-a :
exec !! sx [file]

ctl-a \ to quit

**This can also work**
sx boot.bin | socat FILE:/dev/ttyUSB0,b115200,raw -

### Process to compile and burn Rom image
See code/arduino serial from linux cli.md for serial control of adriuno burner

alias vasm='~/sources/vasm/vasm6502_oldstyle -Fbin -dotdir -ldots -wdc02'

enter bndr6502 to enter screenhd

screen does not do flow control!!!
try

minicom -D /dev/ttyUSB0 -8 -b 19200 -c on

ctrl-a then s for downloads
space selects file and return should be on okay and accepts it. Cached if you try again

### symon emulator
added a custom machine to emulate bender

java -jar symon-1.3.2.jar -m bender -cpu 65c02 -r ROM.bin


### Process to compile and load RAM image

add -esc to use escape codes

alias vasmbin='~/sources/vasm/vasm6502_oldstyle -Fbin -dotdir -ldots -wdc02 -cbm-prg'
alias vasmbootbin='~/sources/vasm/vasm6502_oldstyle -Fbin -dotdir -ldots -wdc02 -cbm-prg -o boot.bin'

### hexdump command

hexdump  -e '":" 8/1  "%02x " "\n"'
hexdump  -e '":" 8/1  "%02x " "\n"' | xclip
:a9 01 85 80 4c 00 80
