# PMOS486
a basic operating system bootstrapper for Intel x86 Protected Mode  

A raw 'operating system' bootstraper created before (and updated while) my university cursus (start of 90s). The goal was to understand and implement a switch from Intel i80286 Real Mode (MSDOS environment) to Protected mode (modern OS process isolation), the very first steps of a modern OS boot.

The first version target i80286 (named PRO286), and was able to restore Real Mode when the program terminate (thanks to IMB Bios workaround of the 80286 bug).
PMOIS486 is the evolution targeting  Intel i386 or i486 processors (and the 'clean' return to real mode feature).

PMOS486 move hardware interrupt to remove overlapping interrupt number between cpu and hardware interrupts when running in Protected Mode. The standard position is restored when back to real mode.
It implement a keyboard driver (with a french 'mapping'), a text display 'drivers' (autoscroll of typed chars), a timer interrupt (2char blinking on screen :) )

PMOS486 is fully written in Intel x86 assembler (real and protected mode). It 'was' compilable with masm. 
A version was compatible with tasm (Borland Turbo Assembler).

The source is provided 'as is'. I'm not sure it compile with modern assembler :) (the older you compiler/linker is, luckier you will be ;) )

A binary build is available for testing (downloadable as is, no warranty of any kinds) : https://nicolasclerc.wordpress.com/2008/12/29/historique-%c2%a4-pmos486-%c2%a4-protected-mode-operating-system-486/
