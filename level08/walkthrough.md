# OverRide (level08)

In this project, we try to **exploit binaries** with the intent of reading the `/home/users/level<n+1>/.pass` file, containing our flag serving as the password for the next level.

# Binary

Binary properties:
- Full path: `/home/users/level08/level08`
- Type: **ELF 64-bit LSB executable** (`file -b ~/level08`)

To analyze its content we generated two files:
- [source.c](./source.c): generated with our [ghidra.sh](../common/ghidra/ghidra.sh), wrapping a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra).
- [source.asm](./source.asm): trimmed after being generated through `objdump -D ~/level08`.

# Security

Let's connect to the server through [ssh](./Ressources/ssh.sh) and inspect the protections in place.

## File Attributes

```sh
$ ls -la ~/level08
-rwsr-s---+ 1 level09 users 12975 Oct 19  2016 /home/users/level08/level08
```

|    Attribute    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|    Suid bit     |    ✅     | Owned by level09, so it runs with level09's effective uid: opening a shell inherits it.


## Compile-Time

```sh
$ checksec --file ~/level08
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
Full RELRO      Canary found      NX disabled   No PIE          No RPATH   No RUNPATH   /home/users/level08/level08
```

|   Protection    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|      RELRO      |    ✅     | Full. The whole GOT is resolved at startup then mapped read-only. GOT-overwrite attacks are out.
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

The decompiled binary (cf. [source](source.c)) is subhect to two CWE vulnerabilities:
- "Use of Externally-Controlled Format String" ([CWE-134](https://cwe.mitre.org/data/definitions/134.html))
- "Improper Link Resolution Before File Access ('Link Following')" ([CWE-59](https://cwe.mitre.org/data/definitions/59.html))

## General behaviour

The program takes a filepath *(`argv[1]`)* and attempts to copy its content to an equivalently named file in the relative `./backups/` folder. It also generates a `.log` file in the same folder, where it records the runs.

## Permissions

The program runs with **effective UID `level09`** and **effective GID `users`**, through its **SUID** and **SGID** flags *(`-rwsr-s---`)*. The files it creates are masked by **level08**'s umask *(SUID doesn't change that)*: `0002`.

To generate the `./backups/.log` file, it uses [`fopen()`](https://man7.org/linux/man-pages/man3/fopen.3.html):
- With mode `"w"` *(equivalent to `O_WRONLY | O_CREAT | O_TRUNC` flags)*: the file is created when missing, and truncated to empty otherwise. It also fails if an intermediary folder is missing *(no parent directory is created)*.
- It inherits user **level09**: the newly created file is owned by the process's **effective UID**, which the **SUID** flag set.
- It inherits group **users**: the newly created file is owned by the process's **effective GID**, which the **SGID** flag set.
- Its mode is set to `0664` *(`0666 & ~umask`)*. In other words, members of the **users** group, such as **level08**, can read **and** write it.

To generate the `./backups/${argv[1]}` file, it uses [`open()`](https://man7.org/linux/man-pages/man2/open.2.html):
- With `O_WRONLY | O_CREAT | O_EXCL` flags: the file is created when missing, but fails if it already exists. It also fails if an intermediary folder is missing *(no parent directory is created)*.
- It inherits user **level09**: the newly created file is owned by the process's **effective UID**, which the **SUID** flag set.
- It inherits group **users**: the newly created file is owned by the process's **effective GID**, which the **SGID** flag set.
- Its mode is set to `0660` *(`0660 & ~umask`)*. In other words, members of the **users** group, such as **level08**, can read **and** write it.

## Caveats

The program is inherently insecure as it takes few precautions around user and group management while having the SETUID/SETGID flags set.

The backup path is built by concatenation: `./backups/` + `argv[1]`. Neither `fopen()` nor `open()` creates intermediate directories, so the whole chain of folders in the resulting path must already exist, or the call fails. This restricts us to bare filenames: passing something like `subdir/file` would target `./backups/subdir/file`, which doesn't exist and cannot be created in `~/backups/`.

Luckily, the program refers to its directory through relative pathing *(`./backups/`)*. This means we can create our own `backups/` directory and broaden its permissions. That way, we can create all the necessary folders to satisfy the conditions to copy the `/home/users/level09/.pass` file.

# Exploit

```sh
mkdir -p "$(dirname '/tmp/backups/home/users/level09/.pass')";
(cd /tmp && /home/users/level08/level08 '/home/users/level09/.pass');
cat /tmp/backups/home/users/level09/.pass;
(cd /tmp && rm -r ./backups);
```

And there we are.
