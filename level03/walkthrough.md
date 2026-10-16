# OverRide (level03)

In this project, we try to **exploit binaries** with the intent of reading the `/home/users/level<n+1>/.pass` file, containing our flag serving as the password for the next level.

# Binary

Binary properties:
- Full path: `/home/users/level03/level03`
- Type: **ELF 32-bit LSB executable** (`file -b ~/level03`)

To analyze its content we generated two files:
- [source.c](./source.c): generated with our [ghidra.sh](../common/ghidra/ghidra.sh), wrapping a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra).
- [source.asm](./source.asm): trimmed after being generated through `objdump -D ~/level03`.

# Security

Let's connect to the server through [ssh](./Ressources/ssh.sh) and inspect the protections in place.

## File Attributes

```sh
$ ls -la ~/level03
-rwsr-s---+ 1 level04 users 7677 Sep 10  2016 /home/users/level03/level03
```

|    Attribute    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|    Suid bit     |    ✅     | Runs with level04's effective uid: opening a shell inherits it.


## Compile-Time

```sh
$ checksec --file ~/level03
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
Partial RELRO   Canary found      NX enabled    No PIE          No RPATH   No RUNPATH   /home/users/level03/level03
```

|   Protection    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|      RELRO      |    ⚠️     | Partial. GOT is still writable but harded to reach.
|  Stack Canary   |    ✅     | Major stack buffer overflows are detected.
|       NX        |    ✅     | Stack/Heap are non-executable. Shellcode injection is not possible.
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

The decompiled binary (cf. [source](source.c)) is not subject to any popular CWE vulnerability. It seems to be a simple reverse-engineering exercise.

Ghidra's output is inconsistent. We relied on the assembly code ([source.asm](./source.asm)) and worked out the rest through experimentation and assumptions. Our version probably drifts from the original, but it is good enough, as we do not intend to manipulate the stack.

The program holds a hashed *(XOR-obfuscated)* password, decoded via an 8-bit key. The key is derived from a *magic number* and the user's input, truncated to 8 bits. If the derived key is not part of a specific whitelist, it is replaced by a pseudo-randomly generated value. Once the password is decoded, a privileged shell is opened.

# Exploit

Through static analysis of the decompiled binary (cf. [source](source.c)) we determined the following:
- How the key is derived: `(322424845 - $user_input) & 0xff` (lowest 8 bits only).
- The key whitelist: `0x1 0x2 0x3 0x4 0x5 0x6 0x7 0x8 0x9 0x10 0x11 0x12 0x13 0x14 0x15`. Any key outside of this range is randomized.
- The XOR-obfuscated password: `0x51 0x7d 0x7c 0x75 0x60 0x73 0x66 0x67 0x7e 0x73 0x66 0x7b 0x7d 0x7c 0x61 0x33`.
- The operation performed on each byte to decipher it: `password_byte ^ key`.

We tried out each key through a dedicated script ([shift_password.sh](./Ressources/data/shift_password.sh)) and found out the matching one was `0x12`.
```sh
#!/bin/sh

password="0x51 0x7d 0x7c 0x75 0x60 0x73 0x66 0x67 0x7e 0x73 0x66 0x7b 0x7d 0x7c 0x61 0x33"
shift_by_list="0x1 0x2 0x3 0x4 0x5 0x6 0x7 0x8 0x9 0x10 0x11 0x12 0x13 0x14 0x15"

for shift in $shift_by_list; do
    printf 'Password shifted by 0x%02x: ' "$shift"
    for byte in $password; do
        printf '%b' "$(printf '\\%03o' "$(( byte ^ shift ))")"
    done
    printf '\n'
done
```

From here we can define the expected user input.
```sh
user_input="$((322424845 - 18))"; # 322424827
(printf '%s\n' "$user_input"; cat -) | ~/level03;
```

And there we are.
