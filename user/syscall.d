module user.syscall;

import user.nativecall;
import user.util;

import user.console;

// Errors
enum SyscallError : ulong
{
	OK = 0,
	Failcopter
}

// Return structures
struct KeyboardInfo
{
	short* buffer;
	uint bufferLength;

	int* writePointer;
	int* readPointer;
}

// IDs of the system calls
enum SyscallID : ulong
{
	Add = 0,
	RequestConsole,
	Exit
}

// Names of system calls
alias Tuple!
(
	"add",			// add()
	"requestConsole",	// requestConsole()
	"exit"			// exit()
) SyscallNames;


// Return types for each system call
alias Tuple!
(
	long,			// add
	void,			// requestConsole
	void			// exit
) SyscallRetTypes;

// Parameters to system call
struct AddArgs {
	long a, b;
}

struct RequestConsoleArgs {
	ConsoleInfo* cinfo;
}

struct ExitArgs {
	long retVal;
}

// XXX: This template exists because of a bug in the DMDFE; something like Templ!(tuple[idx]) fails for some reason
template SyscallName(uint ID)
{
	const char[] SyscallName = SyscallNames[ID];
}

template ArgsStruct(uint ID)
{
	const char[] ArgsStruct = Capitalize!(SyscallName!(ID)) ~ "Args";
}

template MakeSyscall(uint ID)
{
	const char[] MakeSyscall =
SyscallRetTypes[ID].stringof ~ ` ` ~ SyscallNames[ID] ~ `(Tuple!` ~ typeof(mixin(ArgsStruct!(ID)).tupleof).stringof ~ ` args)
{
	` ~ (is(SyscallRetTypes[ID] == void) ? "ulong ret;" : SyscallRetTypes[ID].stringof ~ ` ret;  `)
	~ ArgsStruct!(ID) ~ ` argStruct;

	foreach(i, arg; args)
		argStruct.tupleof[i] = arg;

	auto err = nativeSyscall(` ~ ID.stringof ~ `, &ret, &argStruct);

	// check err!

	return ret;
}`;
}

mixin(Reduce!(Cat, Map!(MakeSyscall, Range!(SyscallID.max + 1))));
