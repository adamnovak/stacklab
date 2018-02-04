# This is an assembly language file targeting Mac OS X
# We are targiting 32 bit mode (movl-like instructions and %eax-like registers) because the book uses it.
# 64-bit mode is what everyone uses now (movq-like instructions and %rax-like registers)

# The assembler will do some useful work for you, like letting you define named constants ("symbols").
# Symbols and labels are one and the same; a label creates a symbol holding its address.

# Here we will define some symbols for useful syscalls. You can pass one of
# these to the operating system with the syscall instruction and get it to do
# useful things for you.

# int exit(int exit_code): exits the program with the given return code.
.set SYSCALL_EXIT, 0x2000001
# int read(int file_descriptor, char* data, int length): Read from a file descriptor. Return bytes read, 0 for EOF.
# On error, return error code and set carry flag.
.set SYSCALL_READ, 0x2000003
# int write(int file_descriptor, char* data, int length): Write to a file descriptor. Returns bytes written.
# On error, return error code and set carry flag.
.set SYSCALL_WRITE, 0x2000004
# More syscalls are dfined here:
# https://opensource.apple.com/source/xnu/xnu-1504.3.12/bsd/kern/syscalls.master
# Make sure to add 0x2000000 to them to mark them as "Unix" class syscalls.

# Default file descriptors:
# 0 = standard input
.set STDIN, 0x0
# 1 = standard output
.set STDOUT, 0x1
# 2 = standard error
.set STDERR, 0x2

# The 32 bit syscall convention is:

# 1. Pad the stack out so the arguments will end on a 16 byte boundary.
# 2. Push arguments to the stack, from right to left in the order they are written for the syscall
# 3. Pad the stack by 4 more bytes; See <https://stackoverflow.com/q/21367494>
# 3. Put the syscall number in %eax
# 4. Execute the int $0x80 instruction to do the syscall
# 5. Check the carry flag for an error
# 6. Collect the return value or error code from %eax

.section __TEXT,__text
# This is where code goes, but constants can also go in here.

# This puts a string, followed by a terminating null byte
hello_string:
.asciz "Hello World\n"

# Our label should become a symbol that other files can access
.globl start

# "start" is the default label for the place to start executing code.
start:
    # Print "Hello World"
    subl $4, %esp # Arguments are 12 bytes, so pad to 16
    pushl $12 # Push the data length
    pushl $hello_string # Push the data address
    pushl $STDOUT # Push the file descriptor to write to.
    subl $4, %esp # Pad the stack by 4
    movl $SYSCALL_WRITE, %eax # Select the write syscall
    int $0x80 # Do the syscall
    # If the syscall failed, the "carry" flag is set. So if the carry flag is
    # set, jump to the error handling code.
    jc syscall_failed 
    # Now clean up the stack
    addl $20, %esp

    # Run exit(10)
    subl $12, %esp # Arguments will be 4 bytes, so pad to 16 total
    push $0 # Push the arguments, last arg first
    subl $4, %esp # Pad the stack by 4
    movl $SYSCALL_EXIT, %eax # Select the syscall to call
    int $0x80 # Do the syscall
    addl $20, %esp # Clean up the stack (though exit shouldn't return)

# This is where we will go if the OS complains about a syscall failing
syscall_failed:
    # Run exit(%eax), since error number is in eax
    # We never cleaned the 4-byte padding from the last syscall
    subl $8, %esp
    pushl %eax
    subl $4, %esp
    movl $SYSCALL_EXIT, %eax
    int $0x80

.section __DATA,__data
# This is where global mutable data lives.


# DEBUGGING

# Open up the debugger with: `lldb stacklab`
# View a function's code with e.g. `di -n start`
# Set a breakpoint at an address with e.g. `b 0x1fee`
# When execution is stopped, step to the next instruction with `si`.
# Look at registers with `register read` or e.g. `register read eax`
# Flags live in the eflags register, where the carry flag (low bit) indicates a syscall error.


