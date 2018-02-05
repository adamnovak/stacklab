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

# The 32 bit syscall convention is:

# 1. Pad the stack out so the arguments will end on a 16 byte boundary.
# 2. Push arguments to the stack, from right to left in the order they are written for the syscall
# 3. Pad the stack by 4 more bytes; See <https://stackoverflow.com/q/21367494>
# 3. Put the syscall number in %eax
# 4. Execute the int $0x80 instruction to do the syscall
# 5. Check the carry flag for an error
# 6. Collect the return value or error code from %eax

# Default file descriptors:
# 0 = standard input
.set STDIN, 0x0
# 1 = standard output
.set STDOUT, 0x1
# 2 = standard error
.set STDERR, 0x2

.section __TEXT,__text
# This is where code goes, but constants can also go in here.

# This puts a string, followed by a terminating null byte
hello_string:
.asciz "Hello World!\n"
grant_string:
.asciz "Access Granted\n"
deny_string:
.asciz "Access Denied\n"
alert_string:
.asciz "ALERT!\n"

# This just does a 4-byte value
correct_pin:
.long 0xDEADBEEF

# Here are some functions that get called
# The function calling convention is different from the syscall calling convention and lives here:
# https://developer.apple.com/library/content/documentation/DeveloperTools/Conceptual/LowLevelABI/130-IA-32_Function_Calling_Conventions/IA32.html
# Arguments are pushed onto the stack so that they end at a 16-byte block boundary.
# The called function returns its return value in %eax

# To call a function:
# 1. Push any of the non-preserved registers you are using (%eax, %ecx, %edx).
# 2. Pad stack so function arguments are 16-byte-aligned.
# 3. Push function arguments, right to left.
# 4. Make the call with a call instruction.
# 5. Use function return value in %eax.
# 6. Clean up the arguments and padding from the stack.
# 7. Restore any non-preserved registers you saved.

# To be a function:
# 1. Save the caller's %ebp, the stack frame pointer ("base pointer"), to the stack.
# 2. Set %ebp to %esp, defining the current function's stack frame.
# 3. Save any other preserved registers (%ebx, %esi, %edi) your function will use.
# 4. Do the work of the function.
#    The arguments passed to the function are addressable as 0x8(%ebp), 0xc(%ebp), 0x10(%ebp) etc. in left to right order.
#    The return address to return to is at 0x4(%ebp).
#    The previous %ebp value is addressable as (%ebp).
# 5. Put your return value in %eax.
# 6. Restore the preserved registers by popping them.
# 7. Restore the previous %ebp value by popping it.
# 8. Return to the caller with a ret instruction.

# String length function: get the length of a null-terminated string.
# int strlen(char* string)
strlen:
    # Establish our stack frame
    pushl %ebp
    movl %esp, %ebp

    # Strategy: start %eax at the string address, advance it until it points to
    # a null byte, and subtract out the original address.
    # We will use %bl, the lowest byte of %ebx, as our single byte comparison scratch.

    # Save the preserved register %ebx that we want to use
    pushl %ebx

    # Load the first argument into %eax
    movl 0x8(%ebp), %eax
Lstrlen_loop: #(This is a local label (prefix L). It is still part of the strlen function.
    # Load the character
    movb (%eax), %bl
    # Test it against 0
    # Only the first argument can be immediate (i.e. a constant)
    cmpb $0, %bl
    # If equal, jump to the local done label
    je Lstrlen_done
    # Otherwise, look at the next character
    addl $1, %eax
    # Loop around
    jmp Lstrlen_loop
Lstrlen_done:
    # We broke out of the loop because we found the null byte.

    # Subtract the address we started at to get the length, in %eax and ready to return.
    subl  0x8(%ebp), %eax

    # Restore preserved registers
    popl %ebx

    # Tear down our stack frame
    popl %ebp
    # Return
    ret

# Print function: print a null-terminated string.
# void print(char* string)
print:
    # Establish our stack frame
    pushl %ebp
    movl %esp, %ebp

    # Strategy: Use the preserved %ebx to hold our string length remaining to write.
    # Use the preserved %esi to hold our next character to write.
    # Use the preserved %edi for scratch.
    # Do write syscalls until all of the string is written.

    # Save the preserved registers that we want to use
    pushl %ebx
    pushl %esi
    pushl %edi

    # Load the string address (first argument)
    movl 0x8(%ebp), %esi

    # Call strlen to get its length
    subl $12, %esp
    pushl %esi
    call strlen
    addl $16, %esp
    # Put the length (from %eax where it was returned) in %ebx
    movl %eax, %ebx

Lprint_loop:
    # See if there are characters left to write
    cmpl $0, %ebx
    # If not, we are done
    je Lprint_done

    # Otherwise, do a write syscall on stdout.
    # int write(int file_descriptor, char* data, int length)
    # Arguments are 12 bytes, so pad to 16
    subl $4, %esp
    # Push the data length
    pushl %ebx
    # Push the data address
    pushl %esi
    # Push the file descriptor to write to.
    pushl $STDOUT
    # Pad the stack by 4 because it's a syscall
    subl $4, %esp
    # Select the write syscall
    movl $SYSCALL_WRITE, %eax 
    # Do the syscall
    int $0x80 
    # If the syscall failed, the "carry" flag is set. So if the carry flag is
    # set, jump to the error handling code.
    jc syscall_failed 
    # Now clean up the stack
    addl $20, %esp

    # The number of bytes written is in %eax. So advance our cursor.
    subl %eax, %ebx
    addl %eax, %esi

    # Write the rest of the string, if any
    jmp Lprint_loop
Lprint_done:
    # Entire string is written. 0 characters left.

    # Restore preserved registers
    popl %edi
    popl %esi
    popl %ebx

    # Tear down our stack frame
    popl %ebp
    # Return
    ret

# Square function: square to the passed argument and return it
# int square(int arg)
square:
    # Establish our stack frame
    pushl %ebp
    movl %esp, %ebp

#*#*#* START LAB CHANGES HERE
    # TODO: Add amazing stack walking code here!
#*#*#* STOP LAB CHANGES HERE

    # Load the argument (first argument)
    movl 0x8(%ebp), %eax
    # Multiply it by itself and leave it in %eax to return
    # Note that mul always multiplies into %eax
    mul %eax

    # Tear down our stack frame
    popl %ebp
    # Return
    ret

# Access validation function
# Check if the correct PIN has been passed and print a message
# void check_access(int provoded_pin, int correct_pin)
check_access:
    # Establish our stack frame
    pushl %ebp
    movl %esp, %ebp

    # Save the preserved registers that we want to use
    pushl %ebx

    # Compute the number of times to say ALERT if the PIN is wrong
    subl $12, %esp
    pushl $3
    call square
    addl $16, %esp

    # Save it in %ebx
    movl %eax, %ebx

    # Load the provided PIN (the first argument)
    movl 0x8(%ebp), %eax
    # Compare against real PIN (the second argument)
    cmp %eax, 0xc(%ebp)
    # If they are the same, report success!
    je Lcheck_access_success

    # Otherwise, the PIN is wrong.

    # Print our failure message
    subl $12, %esp
    pushl $deny_string
    call print
    addl $16, %esp

    # Print alert the right number of times
Lcheck_access_loop:
    # If we ran out of times to do it, stop
    cmp $0, %ebx
    je Lcheck_access_finish

    # Otherwise, print it once
    subl $12, %esp
    pushl $alert_string
    call print
    addl $16, %esp

    # Decrement the count
    subl $1, %ebx

    # And check again
    jmp Lcheck_access_loop

Lcheck_access_success:
    # The PIN was correct. Say so.
    subl $12, %esp
    pushl $grant_string
    call print
    addl $16, %esp

Lcheck_access_finish:
    # Restore preserved registers
    popl %ebx

    # Tear down our stack frame
    popl %ebp
    # Return
    ret

    
# Our label should become a symbol that other files can access
.globl start

# "start" is the default label for the place to start executing code.
start:
    # Get the length of "Hello World" into %eax
    subl $12, %esp
    pushl $hello_string
    call strlen
    addl $16, %esp

    # Print the string
    subl $12, %esp
    pushl $hello_string
    call print
    addl $16, %esp

    # Pretend to read some user data
    movl $0xACCE55ED, entered_pin

    # Uncomment the line below to test and see that the PIN checker really works
    #movl $0xDEADBEEF, entered_pin

    # Check the PIN number and alert the authorities if incorrect
    subl $8, %esp
    # Argument 2: correct PIN
    # We don't use $ because we want the contents of this address; not the address itself
    pushl correct_pin
    # Argument 1: submitted PIN
    pushl entered_pin
    call check_access
    addl $16, %esp

    # Run the exit syscall with argument 0 (for success)
    # Arguments will be 4 bytes, so pad to 16 total
    subl $12, %esp
    # Push the arguments, last arg first
    push $0 
    # Pad the stack by 4 because it's a syscall
    subl $4, %esp 
    # Select the syscall to call
    movl $SYSCALL_EXIT, %eax 
    # Do the syscall
    int $0x80 
    # Clean up the stack (though exit shouldn't return)
    addl $20, %esp 



# This is where we will go if the OS complains about a syscall failing
# Die with the error number as our exit code
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

# User data reading code will set this global to the PIN that has been entered
entered_pin:
.long 0x00000000


# DEBUGGING

# Open up the debugger with: `lldb stacklab`
# View a function's code with e.g. `di -n start` or `di -n strlen`
# Set a breakpoint at an address with e.g. `b 0x1fee`
# When execution is stopped, step to the next instruction with `si`.
# Look at registers with `register read` or e.g. `register read eax`
# Look at memory with `x <address>` e.g. `x 0x12345`. Remember that x86 is little-endian and the stack grows down.
# Flags live in the eflags register, where the carry flag (low bit) indicates a syscall error.


