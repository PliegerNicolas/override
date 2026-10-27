/* ************************************************************************* */
/* *                       Decompiled code via GHIDRA                      * */
/* ************************************************************************* */

// /* Function: main. Address: 08048494 */

// bool main(void)

// {
//   int local_14 [4];
  
//   puts("***********************************");
//   puts("* \t     -Level00 -\t\t  *");
//   puts("***********************************");
//   printf("Password:");
//   __isoc99_scanf(&DAT_08048636,local_14);
//   if (local_14[0] != 0x149c) {
//     puts("\nInvalid Password!");
//   }
//   else {
//     puts("\nAuthenticated!");
//     system("/bin/sh");
//   }
//   return local_14[0] != 0x149c;
// }

/* ************************************************************************* */
/* *                      Manually reconstructed code                      * */
/* ************************************************************************* */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Function: main. Address: 08048494 */

int main(void) {
    int password[4];

    puts("***********************************");
    puts("* \t     -Level00 -\t\t  *");
    puts("***********************************");

    printf("Password:");
    scanf("%d", &password[0] /* <=> password */);

    if (password[0] == 5276) {
        puts("\nAuthenticated!");
        system("/bin/sh");
    } else {
        puts("\nInvalid Password!");
    }

    return password[0] != 5276;
}