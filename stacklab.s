# This is an assembly language file targeting Mac OS X
# We are targiting 32 bit mode (movl-like instructions and %eax-like registers) because the book uses it.
# 64-bit mode is what everyone uses now (movq-like instructions and %rax-like registers)

# The assembler will do some useful work for you, like letting you define named constants ("symbols").
# Symbols and labels are one and the same; a label creates a symbol holding its address.

# Here we will define some symbols for useful syscalls. You can pass one of
# these to the operating system with the syscall instruction and get it to do
# useful things for you.

# exit(int exit_code)
.set SYSCALL_EXIT, 0x2000001
# write()
.set SYSCALL_WRITE, 0x2000004

# The 32 bit syscall convention (from https://filippo.io/making-system-calls-from-assembly-in-mac-os-x/) is:

# 1. Push arguments to the stack, from right to left in the order they are written for the syscall
# 2. Pad the stack out to the next 16 byte boundary
# 3. Put the syscall number in %eax
# 4. Execute the int $0x80 instruction to do the syscall



# Our code ends up being put at the end of the 0x1000 segment after some garbage, and before some non-code linking data at 0x2000
# Then the unixthread segment from the binary starts execution at the address the code loaded at

.section __TEXT,__text
# This is where code goes, but constants can also go in here.
# It ends up at virtual address 0x1000

# Our label should become a symbol that other files can access
.globl start

# "start" is the default label for the place to start executing code.
start:
    # call exit(10)
    pushl $10 # Push the arguments, last arg first
    subl $4, %esp # That took 4 bytes, so pad out to 16 total
    movl $SYSCALL_EXIT, %eax # Select the syscall to call
    int $0x80 # Do the syscall



