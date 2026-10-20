/* ************************************************************************* */
/* *                       Decompiled code via GHIDRA                      * */
/* ************************************************************************* */

// /* Function: clear_stdin. Address: 080486b4 */

// void clear_stdin(void)

// {
//   int iVar1;
  
//   do {
//     iVar1 = getchar();
//     if ((char)iVar1 == '\n') {
//       return;
//     }
//   } while ((char)iVar1 != -1);
//   return;
// }


// /* Function: get_unum. Address: 080486d7 */

// undefined4 get_unum(void)

// {
//   undefined4 local_10 [3];
  
//   local_10[0] = 0;
//   fflush(stdout);
//   __isoc99_scanf(&DAT_08048a60,local_10);
//   clear_stdin();
//   return local_10[0];
// }


// /* Function: prog_timeout. Address: 0804870f */

// void prog_timeout(void)

// {
//   code *pcVar1;
  
//   pcVar1 = (code *)swi(0x80);
//   (*pcVar1)();
//   return;
// }


// /* Function: enable_timeout_cons. Address: 08048720 */

// void enable_timeout_cons(void)

// {
//   signal(0xe,prog_timeout);
//   alarm(0x3c);
//   return;
// }


// /* Function: auth. Address: 08048748 */

// /* WARNING: Removing unreachable block (ram,0x08048782) */
// /* WARNING: Restarted to delay deadcode elimination for space: stack */

// undefined4 auth(char *param_1,uint param_2)

// {
//   size_t sVar1;
//   undefined4 uVar2;
//   long lVar3;
//   int local_18;
//   uint local_14;
  
//   sVar1 = strcspn(param_1,"\n");
//   param_1[sVar1] = '\0';
//   sVar1 = strnlen(param_1,0x20);
//   if ((int)sVar1 < 6) {
//     uVar2 = 1;
//   }
//   else {
//     lVar3 = ptrace(PTRACE_TRACEME);
//     if (lVar3 == -1) {
//       puts("\x1b[32m.---------------------------.");
//       puts("\x1b[31m| !! TAMPERING DETECTED !!  |");
//       puts("\x1b[32m\'---------------------------\'");
//       uVar2 = 1;
//     }
//     else {
//       local_14 = ((int)param_1[3] ^ 0x1337U) + 0x5eeded;
//       for (local_18 = 0; local_18 < (int)sVar1; local_18 = local_18 + 1) {
//         if (param_1[local_18] < ' ') {
//           return 1;
//         }
//         local_14 = local_14 + ((int)param_1[local_18] ^ local_14) % 0x539;
//       }
//       if (param_2 == local_14) {
//         uVar2 = 0;
//       }
//       else {
//         uVar2 = 1;
//       }
//     }
//   }
//   return uVar2;
// }


// /* Function: main. Address: 08048879 */

// /* WARNING: Removing unreachable block (ram,0x0804889a) */
// /* WARNING: Restarted to delay deadcode elimination for space: stack */

// bool main(void)

// {
//   int iVar1;
//   int in_GS_OFFSET;
//   char local_34 [32];
//   int local_14;
  
//   local_14 = *(int *)(in_GS_OFFSET + 0x14);
//   puts("***********************************");
//   puts("*\t\tlevel06\t\t  *");
//   puts("***********************************");
//   printf("-> Enter Login: ");
//   fgets(local_34,0x20,stdin);
//   puts("***********************************");
//   puts("***** NEW ACCOUNT DETECTED ********");
//   puts("***********************************");
//   printf("-> Enter Serial: ");
//   __isoc99_scanf();
//   iVar1 = auth();
//   if (iVar1 == 0) {
//     puts("Authenticated!");
//     system("/bin/sh");
//   }
//   if (local_14 != *(int *)(in_GS_OFFSET + 0x14)) {
//                     /* WARNING: Subroutine does not return */
//     __stack_chk_fail();
//   }
//   return iVar1 != 0;
// }

/* ************************************************************************* */
/* *                      Manually reconstructed code                      * */
/* ************************************************************************* */


#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>
#include <sys/ptrace.h>

// Ghidra artefact. Defined just to satisfy vscode.
# define in_GS_OFFSET 0

/* Function: clear_stdin. Address: 080486b4 */

void    clear_stdin(void) {
    char    c;

    do {
        c = getchar();
    } while (c != '\n' && c != EOF);
}

/* Function: get_unum. Address: 080486d7 */

unsigned int    get_unum(void) {
    unsigned int  unum;

    unum = 0;
    fflush(stdout);
    scanf("%u", &unum);
    clear_stdin();
    return unum;
}

/* Function: prog_timeout. Address: 0804870f */

void    prog_timeout(void) {
    exit(1);
}

/* Function: enable_timeout_cons. Address: 08048720 */

void    enable_timeout_cons(void) {
    signal(SIGALRM, prog_timeout);
    alarm(60);
}


/* Function: auth. Address: 08048748 */

int auth(char *login, unsigned int reference_serial) {
    size_t          login_length;
    unsigned int    generated_serial;
    
    login[strcspn(login, "\n")] = '\0';
    login_length = strnlen(login, 32 /* sizeof(login) */);

    if (login_length < 6)
        return 1;

    // The kernel only allows one tracer per process. This blocks away gdb. D:
    if (ptrace(PTRACE_TRACEME) == -1) {
        puts("\x1b[32m.---------------------------.");
        puts("\x1b[31m| !! TAMPERING DETECTED !!  |");
        puts("\x1b[32m\'---------------------------\'");
        return 1;
    } 

    generated_serial = ((int)login[3] ^ 0x1337U) + 0x5eeded;
    for (int i = 0; i < (int)login_length; i += 1) {
        if (login[i] < ' ') // ASCII char >= 32 enforced.
            return 1;
        generated_serial += ((int)login[i] ^ generated_serial) % 0x539;
    }

    return reference_serial != generated_serial;
}


/* Function: main. Address: 08048879 */

int main(void) {
    int             authenticated;
    char            login[32];
    unsigned int    serial;
    int             canary;

    canary = *(int *)(in_GS_OFFSET + 0x14);

    puts("***********************************");
    puts("*\t\tlevel06\t\t  *");
    puts("***********************************");
    printf("-> Enter Login: ");
    fgets(login, sizeof(login), stdin);

    puts("***********************************");
    puts("***** NEW ACCOUNT DETECTED ********");
    puts("***********************************");
    printf("-> Enter Serial: ");
    scanf("%u", &serial);

    authenticated = auth(login, serial);

    if (authenticated == 0) {
        puts("Authenticated!");
        system("/bin/sh");
    }

    if (canary != *(int *)(in_GS_OFFSET + 0x14))
        __stack_chk_fail();

    return authenticated != 0;
}
