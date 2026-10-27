#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

bool has_invalid_length(const size_t len) {
    if (len < 6) {
        fprintf(stderr, "Provided login must be at least 6 characters long.\n");
        return 1;
    }
    return 0;
}

bool has_invalid_chars(const char *login, const size_t len) {
    for (size_t i = 0; i < len; i++)
        if (login[i] < ' ') {
            fprintf(stderr, "Invalid char detected (%c).\n", login[i]);
            return 1;
        }
    return 0;
}

int main(int argc, char **argv) {
    unsigned int    serial;

    if (argc < 2) {
        fprintf(stderr, "At least one argument is expected\n");
        return 1;
    }

    char    *login = argv[1];
    size_t  len = strnlen(login, 31); // main()'s fgets(login, 32) reads at most 31 chars.

    if (has_invalid_length(len))
        return 1;
    if (has_invalid_chars(login, len))
        return 1;

    serial = ((int)login[3] ^ 0x1337U) + 0x5eeded;
    for (size_t i = 0; i < len; i++)
        serial += ((int)login[i] ^ serial) % 0x539;

    //printf("login: %s, serial: %u\n", login, serial);
    printf("%u\n", serial);

    return 0;
}
