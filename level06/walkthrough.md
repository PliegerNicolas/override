# OverRide (level06)

In this project, we try to **exploit binaries** with the intent of reading the `/home/users/level<n+1>/.pass` file, containing our flag serving as the password for the next level.

# Binary

Binary properties:
- Full path: `/home/users/level06/level06`
- Type: **ELF 32-bit LSB executable** (`file -b ~/level06`)

To analyze its content we generated two files:
- [source.c](./source.c): generated with our [ghidra.sh](../common/ghidra/ghidra.sh), wrapping a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra).
- [source.asm](./source.asm): trimmed after being generated through `objdump -D ~/level06`.

# Security

Let's connect to the server through [ssh](./Ressources/ssh.sh) and inspect the protections in place.

## File Attributes

```sh
$ ls -la ~/level06
-rwsr-s---+ 1 level07 users 7907 Sep 10  2016 /home/users/level06/level06
```

|    Attribute    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|    Suid bit     |    ✅     | Owned by level07, so it runs with level07's effective uid: opening a shell inherits it.


## Compile-Time

```sh
$ checksec --file ~/level06
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
Partial RELRO   Canary found      NX enabled    No PIE          No RPATH   No RUNPATH   /home/users/level06/level06
```

|   Protection    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|      RELRO      |    ⚠️     | Partial. GOT is still writable but harder to reach.
|  Stack Canary   |    ✅     | Major stack buffer overflows are detected.
|       NX        |    ✅     | Stack/Heap are non-executable. Shellcode injection is not possible.
|       PIE       |    ❌     | The code, GOT and PLT sit at fixed addresses.
| RPATH / RUNPATH |    ❌     | No custom library search path to hijack.

## Kernel Run-Time

```sh
$ cat /proc/sys/kernel/randomize_va_space
0
```

|   Protection    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|      ASLR       |    ❌     | Stack and heap addresses are stable across runs.

## Documentation

Reference material for the concepts above:
- Setuid flag (Suid): https://fr.wikipedia.org/wiki/Setuid
- Relocation Read-Only (RELRO): https://ctf101.org/binary-exploitation/relocation-read-only/
- Stack canary: https://ctf101.org/binary-exploitation/stack-canaries/
- No eXecute (NX): https://ctf101.org/binary-exploitation/no-execute/
- Position Independent Code (PIE): https://en.wikipedia.org/wiki/Position-independent_code
- RUNPATH & RPATH: https://en.wikipedia.org/wiki/Rpath
- Address Space Layout Randomization (ASLR): https://ctf101.org/binary-exploitation/address-space-layout-randomization/

# Vulnerability & Analysis

The decompiled binary (cf. [source](source.c)) is not subject to any popular CWE vulnerability. Its main weakness is "Reliance on Security Through Obscurity" ([CWE-656](https://cwe.mitre.org/data/definitions/656.html)) position, ideal for pure reverse-engineering exercises.

The program asks the user for a login and a matching serial number. When provided with a matching pair, we are promoted to a privileged shell.

The serial is generated directly from the login, then compared against the one we supply. Since the program contains the full generation routine, we simply extract that code, use it to compute the expected serial for our login, and hand that value back to the program.

# Exploit

Generate the desired serial number given a login using the following [tool](./Ressources/decoder) and then simply pass it to the program.
```sh
$ make -j -C "./decoder";
# ...

$ login='my_login';
$ serial="$(./decoder "$login")";

$ (printf '%s\n' '$login'; printf '%s\n' '$serial'; cat -) | env -i ~/level06
```

And there we are.
