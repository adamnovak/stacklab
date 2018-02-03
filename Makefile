AS:=as
LD:=ld

stacklab: stacklab.o
	# Link the single object file into a binary, using the given entry point.
	# We have to pass -static to prevent dyld from trying to do linking to it that it doesn't need.
	$(LD) stacklab.o -static -o stacklab

stacklab.o: stacklab.s
	# Assemble the source into an object file
	$(AS) -arch i486 stacklab.s -o stacklab.o

clean:
	rm -f stacklab.o stacklab
