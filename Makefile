.DEFAULT_GOAL := hex
NOTHING:=
SPACE:=$(NOTHING) $(NOTHING)

FLAGS := 
#-std=c99

a: 

sudo.bat: a
	echo -e 'set root=tmp' > sudo.bat
	echo -e 'mkdir %root%\nset tmp1=%root%sudo.tmp.vbs\nset tmp2=%root%asadmin.bat\necho %tmp1% %tmp2%\ndel %tmp1%\ndel %tmp2%\necho Set UAC = CreateObject^("Shell.Application"^) > %tmp1%\necho Running in CD=%cd%\necho UAC.ShellExecute "%tmp2%", "", "", "runas", 1 >> %tmp1%\necho cd %cd% > %tmp2%\nrem http://www.robvanderwoude.com/ntcall.php\necho %* >> %tmp2%\n%tmp1%\n' >> sudo.bat

checkDirs: 
	ls .FlyportLibs
	ls .TCPIPStack
	ls .Microchip
	ls .picincludes
	which pic30-gcc #check whether there is compiler in PATH variable

.TCPIPStack:
	# cmd "//c" 'mkdir tmp' || echo 'tmp exists'
	echo 'sudo mklink /D $@ "c:\Program Files\FlyPort IDE\Microchip\TCPIP Stack"' > create.bat
	cmd "//c" 'create.bat' && ls $@
.picincludes:
	echo 'sudo mklink /D $@ "c:\Program Files\Microchip\MPLAB C30\include"' > create.bat
	cmd "//c" 'create.bat' && ls $@
.Microchip:
	echo 'sudo mklink /D $@ "c:\Program Files\FlyPort IDE\Microchip"' > create.bat
	cmd "//c" 'create.bat' && ls $@
.FlyportLibs:
	echo 'sudo mklink /D $@ "Libs\\Flyport libs"' > create.bat
	cmd "//c" 'create.bat' && ls $@

links: sudo.bat .TCPIPStack .FlyportLibs .Microchip .picincludes checkDirs

# DIRS := $(shell find . -type d)
ROOT_DIRECTORY := .
DIRS := ${sort ${dir ${wildcard ${ROOT_DIRECTORY}/*/${ROOT_DIRECTORY}/*/*/}}}
DIRS := . ./.FlyportLibs ./.FlyportLibs/Include ./.Microchip ./.Microchip/%temp% ./.Microchip/Include ./.Microchip/Include/TCPIP Stack ./.Microchip/TCPIP Stack ./.Microchip/TCPIP Stack/WiFi ./.picincludes ./.TCPIPStack ./.TCPIPStack/WiFi ./Libs ./Libs/ExternalLib ./Libs/ExternalLib/Include ./Libs/Flyport libs ./Libs/Flyport libs/Include ./Libs/FreeRTOS ./Libs/FreeRTOS/include 

INCS := $(addprefix -I,$(DIRS)) 
# http://gcc.gnu.org/onlinedocs/gcc-3.4.2/gnat_ugn_unw/Automatically-Creating-a-List-of-Directories.html
# DIRSWITHSEMICOLONS:=$(subst $(SPACE),:,$(DIRS))

clean: 
	rm -f .TCPIPStack
	rm -f .FlyportLibs
	rm -f .Microchip
	rm -f .picincludes
	rm -f tmpasadmin.bat
	rm -f tmpsudo.tmp.bat
	rm -f create.bat
	rm -f sudo.bat
	rm -f Obj/*

# Obj/%.o: .TCPIPStack/%.c
# 	echo building $@, first dep @<

fles := $(wildcard .Microchip/*.c) $(wildcard .FlyportLibs/*.c) $(wildcard .TCPIPStack/*.c) $(wildcard .TCPIPStack/WiFi/*.c) $(wildcard *.c) $(wildcard Libs/FreeRTOS/*.c)
sources := $(notdir $(fles))
objs := $(sources:.c=.o)
vpath % .Microchip:.FlyportLibs:.TCPIPStack:.TCPIPStack/WiFi:Libs/FreeRTOS

# MPFSImg2.s

Obj/portasm_PIC24.o: Libs\FreeRTOS\portasm_PIC24.S
# Obj/%.o: $(filter %.S, $(sources))
	@echo "building $@, dependency: $<"
	pic30-gcc -mcpu=24FJ256GA106 -x assembler -c $< -o $@ -Wa -g

#This is file with webpages
Obj/MPFSImg2.o: MPFSImg2.s
# Obj/%.o: $(filter %.S, $(sources))
	@echo "building $@, dependency: $<"
	pic30-gcc -mcpu=24FJ256GA106 -x assembler -c $< -o $@ -Wa -g

# Obj/%.o: $(filter %.c, $(sources))
Obj/%.o: %.c WF_Config.h
# @echo "$(INCS)"
	@echo "building $@, dependency: $<"
	pic30-gcc -mcpu=24FJ256GA106 -x c -c $< -o $@ -Wall -mlarge-code -mlarge-data $(INCS) $(FLAGS)


printfiles: 
#	@echo -e "All files: $(subst $(SPACE),\n,$(fles))"

c: printfiles $(addprefix Obj/,$(objs))
	@echo "$(sources)"

asm: Obj/portasm_PIC24.o

# vpath %.a .TCPIPStack
# .LIBPATTERNS := '%.a'

LIBS := "-L.TCPIPStack\BigInt_helper_elf.a" "-L.TCPIPStack\BigInt_helper_coff.a" "-LC:\Program Files\FlyPort IDE\c30\support\gld" "-LC:\Program Files\FlyPort IDE\c30\lib" "-LC:\Program Files\FlyPort IDE\c30\lib\pic24f"

Obj/a.cof: c asm
	pic30-gcc -mcpu=24FJ256GA106 Obj/*.o -o $@ $(LIBS) -Wall -mlarge-code -mlarge-data -Wl,-Tp24FJ256GA106.gld,--defsym=__MPLAB_BUILD=1,-Map=Flyport.map,--report-mem --start-group -lpic30 -lc -lm --end-group
	# echo "Initial size [B]: $(ls -l $@ | awk '{print $5};' )"
	sh -c "ls -l $@ | awk '{print $5};'"
	pic30-strip $@ 
	# echo "reduced size to $(ls -l $@ | awk '{print $5};' )"
	sh -c "ls -l $@ | awk '{print $5};'"

projName := $(wildcard *.conf)
projName := $(projName:.conf=.hex)

hex: links Obj/a.cof
	pic30-bin2hex Obj/a.cof && mv Obj/a.hex Obj/$(projName)

all: 
	@echo "$(DIRS)"
	make hex -j 4 | tee -a logbuilds.txt

upload: 
	 ds30LoaderConsole.exe "-f=Obj\test.hex" -d=PIC24FJ256GA106 "-k=COM10" -r=115200 --writef --ht=10000 --polltime=500 --timeout=3000

# %: 
# 	echo "There is .c file $@ which should not be here."
# 	exit 1