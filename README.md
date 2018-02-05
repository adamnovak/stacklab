# Stack Lab

This project contains a lab on how the stack works and how to walk it, targeting Mac OS X's 32 bit ABI.

## The Setup

In `stacklab.s` is a well-commented assembly-language program consisting of several functions. The purpose of this program is to validate an entered PIN number. If the PIN entered is correct, the program will print "Access Granted". If the PIN entered is incorrect, the program will print "Access Denied", and a sufficient number of "ALERT!" lines to draw the attention of the authorities.

## The Problem

Your task is to cause the program to report "Access Granted", by changing only this block of code:

```
#*#*#* START LAB CHANGES HERE
    # TODO: Add amazing stack walking code here!
#*#*#* STOP LAB CHANGES HERE
```

## Rubric

 * The solution MUST modify only those lines.
 * The solution MUST cause the compiled program to print "Access Granted" and no "ALERT!" lines.
 * The solution MUST explain how and why it works with comments.
 * The solution SHOULD preserve the functionality of the `square` function.
 * The solution SHOULD allow the correct PIN to continue to work.
 * The solution SHOULD continue to work correctly if the correct PIN is changed.
 * The solution SHOULD continue to work correctly if the entered PIN is changed.
 * The solution SHOULD consist of 5 or fewer assembly language statements.

## Building and Running

To build the program, run `make`. To run the program, execute the resulting `stacklab` binary with `./stacklab`.

## Debugging Tips

 * Open up the debugger with: `lldb stacklab`
 * View a function's code with e.g. `di -n start` or `di -n strlen`
 * Set a breakpoint at an address with e.g. `b 0x1fee`
 * When execution is stopped, step to the next instruction with `si`.
 * Look at registers with `register read` or e.g. `register read eax`
 * Look at memory with `x <address>` e.g. `x 0x12345`. Remember that x86 is little-endian and the stack grows down.
 * Flags live in the eflags register, where the carry flag (low bit) indicates a syscall error.

## Useful References

Some information on how the stack is organized on Mac OS X, and how register preservation works, is available in [Apple's documentation](https://developer.apple.com/library/content/documentation/DeveloperTools/Conceptual/LowLevelABI/130-IA-32_Function_Calling_Conventions/IA32.html#//apple_ref/doc/uid/TP40002492-SW16). Also see the comments documenting the calling convention in the code.

