/* ************************************************************************* */
/* *                       Decompiled code via GHIDRA                      * */
/* ************************************************************************* */

// /* Function: clear_stdin. Address: 08048634 */

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


// /* Function: get_unum. Address: 08048657 */

// undefined4 get_unum(void)

// {
//   undefined4 local_10 [3];
  
//   local_10[0] = 0;
//   fflush(stdout);
//   __isoc99_scanf(&DAT_08048900,local_10);
//   clear_stdin();
//   return local_10[0];
// }


// /* Function: prog_timeout. Address: 0804868f */

// void prog_timeout(void)

// {
//   code *pcVar1;
  
//   pcVar1 = (code *)swi(0x80);
//   (*pcVar1)();
//   return;
// }


// /* Function: enable_timeout_cons. Address: 080486a0 */

// void enable_timeout_cons(void)

// {
//   signal(0xe,prog_timeout);
//   alarm(0x3c);
//   return;
// }


// /* Function: main. Address: 080486c8 */

// undefined4 main(void)

// {
//   int iVar1;
//   char *pcVar2;
//   byte bVar3;
//   uint local_a4;
//   char local_a0 [128];
//   uint local_20;
//   uint local_1c;
//   long local_18;
//   int local_14;
  
//   bVar3 = 0;
//   local_14 = fork();
//   pcVar2 = local_a0;
//   for (iVar1 = 0x20; iVar1 != 0; iVar1 = iVar1 + -1) {
//     pcVar2[0] = '\0';
//     pcVar2[1] = '\0';
//     pcVar2[2] = '\0';
//     pcVar2[3] = '\0';
//     pcVar2 = pcVar2 + ((uint)bVar3 * -2 + 1) * 4;
//   }
//   local_18 = 0;
//   local_a4 = 0;
//   if (local_14 == 0) {
//     prctl(1,1);
//     ptrace(PTRACE_TRACEME,0,0,0);
//     puts("Give me some shellcode, k");
//     gets(local_a0);
//   }
//   else {
//     do {
//       wait(&local_a4);
//       local_20 = local_a4;
//       if (((local_a4 & 0x7f) == 0) ||
//          (local_1c = local_a4, '\0' < (char)(((byte)local_a4 & 0x7f) + 1) >> 1)) {
//         puts("child is exiting...");
//         return 0;
//       }
//       local_18 = ptrace(PTRACE_PEEKUSER,local_14,0x2c,0);
//     } while (local_18 != 0xb);
//     puts("no exec() for you");
//     kill(local_14,9);
//   }
//   return 0;
// }

/* ************************************************************************* */
/* *                      Manually reconstructed code                      * */
/* ************************************************************************* */

#include <stdio.h>

/* Function: clear_stdin. Address: 08048634 */

void    clear_stdin(void) {
    int c;

    do {
        c = getchar();
    } while (c != '\n' && c != EOF);
}

/* Function: get_unum. Address: 08048657 */

unsigned int    get_unum(void) {
    unsigned int  unum;

    unum = 0;
    fflush(stdout);
    scanf("%u", &unum);
    clear_stdin();
    return unum;
}


/* Function: prog_timeout. Address: 0804868f */

void prog_timeout(void) {
    code *pcVar1;

    pcVar1 = (code *)swi(0x80);
    (*pcVar1)();
    return;
}


/* Function: enable_timeout_cons. Address: 080486a0 */

void enable_timeout_cons(void) {
    signal(0xe,prog_timeout);
    alarm(0x3c);
    return;
}


/* Function: main. Address: 080486c8 */

int main(void) {
    int iVar1;
    char *pcVar2;
    byte bVar3;
    uint local_a4;
    char local_a0 [128];
    uint local_20;
    uint local_1c;
    long local_18;
    int local_14;
    
    bVar3 = 0;
    local_14 = fork();
    pcVar2 = local_a0;
    for (iVar1 = 0x20; iVar1 != 0; iVar1 = iVar1 + -1) {
        pcVar2[0] = '\0';
        pcVar2[1] = '\0';
        pcVar2[2] = '\0';
        pcVar2[3] = '\0';
        pcVar2 = pcVar2 + ((uint)bVar3 * -2 + 1) * 4;
    }
    local_18 = 0;
    local_a4 = 0;
    if (local_14 == 0) {
        prctl(1,1);
        ptrace(PTRACE_TRACEME,0,0,0);
        puts("Give me some shellcode, k");
        gets(local_a0);
    }
    else {
        do {
        wait(&local_a4);
        local_20 = local_a4;
        if (((local_a4 & 0x7f) == 0) ||
            (local_1c = local_a4, '\0' < (char)(((byte)local_a4 & 0x7f) + 1) >> 1)) {
            puts("child is exiting...");
            return 0;
        }
        local_18 = ptrace(PTRACE_PEEKUSER,local_14,0x2c,0);
        } while (local_18 != 0xb);
        puts("no exec() for you");
        kill(local_14,9);
    }
    return 0;
}
