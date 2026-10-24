/* ************************************************************************* */
/* *                       Decompiled code via GHIDRA                      * */
/* ************************************************************************* */

// /* Function: secret_backdoor. Address: 0010088c */

// void secret_backdoor(void)

// {
//   char local_88 [128];
  
//   fgets(local_88,0x80,*(FILE **)PTR_stdin_00301fb8);
//   system(local_88);
//   return;
// }

// /* Function: handle_msg. Address: 001008c0 */

// void handle_msg(void)

// {
//   undefined1 local_c8 [140];
//   undefined8 local_3c;
//   undefined8 local_34;
//   undefined8 local_2c;
//   undefined8 local_24;
//   undefined8 local_1c;
//   undefined4 local_14;
  
//   local_3c = 0;
//   local_34 = 0;
//   local_2c = 0;
//   local_24 = 0;
//   local_1c = 0;
//   local_14 = 0x8c;
//   set_username(local_c8);
//   set_msg(local_c8);
//   puts(">: Msg sent!");
//   return;
// }

// /* Function: set_msg. Address: 00100932 */

// void set_msg(char *param_1)

// {
//   long lVar1;
//   char *pcVar2;
//   char local_408 [1024];
  
//   pcVar2 = local_408;
//   for (lVar1 = 0x80; lVar1 != 0; lVar1 = lVar1 + -1) {
//     pcVar2[0] = '\0';
//     pcVar2[1] = '\0';
//     pcVar2[2] = '\0';
//     pcVar2[3] = '\0';
//     pcVar2[4] = '\0';
//     pcVar2[5] = '\0';
//     pcVar2[6] = '\0';
//     pcVar2[7] = '\0';
//     pcVar2 = pcVar2 + 8;
//   }
//   puts(">: Msg @Unix-Dude");
//   printf(">>: ");
//   fgets(local_408,0x400,*(FILE **)PTR_stdin_00301fb8);
//   strncpy(param_1,local_408,(long)*(int *)(param_1 + 0xb4));
//   return;
// }

// /* Function: set_username. Address: 001009cd */

// void set_username(long param_1)

// {
//   long lVar1;
//   char *pcVar2;
//   char local_98 [140];
//   int local_c;
  
//   pcVar2 = local_98;
//   for (lVar1 = 0x10; lVar1 != 0; lVar1 = lVar1 + -1) {
//     pcVar2[0] = '\0';
//     pcVar2[1] = '\0';
//     pcVar2[2] = '\0';
//     pcVar2[3] = '\0';
//     pcVar2[4] = '\0';
//     pcVar2[5] = '\0';
//     pcVar2[6] = '\0';
//     pcVar2[7] = '\0';
//     pcVar2 = pcVar2 + 8;
//   }
//   puts(">: Enter your username");
//   printf(">>: ");
//   fgets(local_98,0x80,*(FILE **)PTR_stdin_00301fb8);
//   for (local_c = 0; (local_c < 0x29 && (local_98[local_c] != '\0')); local_c = local_c + 1) {
//     *(char *)(param_1 + 0x8c + (long)local_c) = local_98[local_c];
//   }
//   printf(">: Welcome, %s",param_1 + 0x8c);
//   return;
// }

// /* Function: main. Address: 00100aa8 */

// undefined8 main(void)

// {
//   puts(
//       "--------------------------------------------\n|   ~Welcome to l33t-m$n ~    v1337        |\n--------------------------------------------"
//       );
//   handle_msg();
//   return 0;
// }

/* ************************************************************************* */
/* *                      Manually reconstructed code                      * */
/* ************************************************************************* */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct  s_message { // No padding: 184 is 4-byte aligned.
    char    body[140];
    char    username[40];
    int     len; // No padding: 140+40=180 is 4-byte aligned.
} t_message;

/* Function: secret_backdoor. Address: 0010088c */

// Never called anywhere: our target. Runs system() on attacker input.
void    secret_backdoor(void) {
    char    cmd[128];

    fgets(cmd, sizeof(cmd), stdin);
    system(cmd);
}

/* Function: set_username. Address: 001009cd */

void    set_username(t_message *msg) {
    char    input[128];

    memset(input, 0, sizeof(input));

    puts(">: Enter your username");
    printf(">>: ");

    fgets(input, sizeof(input), stdin);

    // Iteration is off by one due to the usage of `<=` instead of `<`.
    // This causes a 1-byte overflow: from `msg->username` into `msg->len`.
    // `msg->len` is 4-bytes wide but we can only overwrite it's lowest byte, ensuring a maximum value of 255.
    for (int i = 0; i <= sizeof(msg->username) && input[i] != '\0'; i++)
        msg->username[i] = input[i];

    printf(">: Welcome, %s", msg->username);
}

/* Function: set_msg. Address: 00100932 */

void    set_msg(t_message *msg) {
    char    input[1024];

    memset(input, 0, sizeof(input));

    puts(">: Msg @Unix-Dude");
    printf(">>: ");

    fgets(input, sizeof(input), stdin);

    // strncpy is only safe assuming msg->len can be trusted. But this is not the case.
    // It is intended to be of size 140 but can be altered to maximum 255.
    // This allows a 115 byte overflow that would impact handle_msg where t_message msg lives.
    strncpy(msg->body, input, (long)msg->len);
}

/* Function: handle_msg. Address: 001008c0 */

void    handle_msg(void) {
    t_message   msg;

    memset(msg.username, 0, sizeof(msg.username));
    msg.len = sizeof(msg.body);

    set_username(&msg);
    set_msg(&msg);

    puts(">: Msg sent!");
}

/* Function: main. Address: 00100aa8 */

int     main(void) {
    puts("--------------------------------------------\n|   ~Welcome to l33t-m$n ~    v1337        |\n--------------------------------------------");
    handle_msg();
    return 0;
}
