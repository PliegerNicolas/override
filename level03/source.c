/* ************************************************************************* */
/* *                       Decompiled code via GHIDRA                      * */
/* ************************************************************************* */

// /* Function: clear_stdin. Address: 080485f4 */

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


// /* Function: get_unum. Address: 08048617 */

// undefined4 get_unum(void)

// {
//   undefined4 local_10 [3];
  
//   local_10[0] = 0;
//   fflush(stdout);
//   __isoc99_scanf(&DAT_080489c0,local_10);
//   clear_stdin();
//   return local_10[0];
// }


// /* Function: prog_timeout. Address: 0804864f */

// void prog_timeout(void)

// {
//   code *pcVar1;
  
//   pcVar1 = (code *)swi(0x80);
//   (*pcVar1)();
//   return;
// }


// /* Function: decrypt. Address: 08048660 */

// /* WARNING: Removing unreachable block (ram,0x08048698) */

// int decrypt(EVP_PKEY_CTX *ctx,uchar *out,size_t *outlen,uchar *in,size_t inlen)

// {
//   byte bVar1;
//   uint uVar2;
//   int iVar3;
//   byte *pbVar4;
//   byte *pbVar5;
//   int in_GS_OFFSET;
//   bool bVar6;
//   bool bVar7;
//   uint local_2c;
//   byte local_21 [17];
//   int local_10;
  
//   local_10 = *(int *)(in_GS_OFFSET + 0x14);
//   local_21[0] = 0x51;
//   local_21[1] = 0x7d;
//   local_21[2] = 0x7c;
//   local_21[3] = 0x75;
//   local_21[4] = 0x60;
//   local_21[5] = 0x73;
//   local_21[6] = 0x66;
//   local_21[7] = 0x67;
//   local_21[8] = 0x7e;
//   local_21[9] = 0x73;
//   local_21[10] = 0x66;
//   local_21[0xb] = 0x7b;
//   local_21[0xc] = 0x7d;
//   local_21[0xd] = 0x7c;
//   local_21[0xe] = 0x61;
//   local_21[0xf] = 0x33;
//   local_21[0x10] = 0;
//   uVar2 = 0xffffffff;
//   pbVar4 = local_21;
//   do {
//     if (uVar2 == 0) break;
//     uVar2 = uVar2 - 1;
//     bVar1 = *pbVar4;
//     pbVar4 = pbVar4 + 1;
//   } while (bVar1 != 0);
//   local_2c = 0;
//   while( true ) {
//     bVar6 = local_2c < ~uVar2 - 1;
//     bVar7 = local_2c == ~uVar2 - 1;
//     if (!bVar6) break;
//     local_21[local_2c] = (byte)ctx ^ local_21[local_2c];
//     local_2c = local_2c + 1;
//   }
//   iVar3 = 0x11;
//   pbVar4 = local_21;
//   pbVar5 = (byte *)"Congratulations!";
//   do {
//     if (iVar3 == 0) break;
//     iVar3 = iVar3 + -1;
//     bVar6 = *pbVar4 < *pbVar5;
//     bVar7 = *pbVar4 == *pbVar5;
//     pbVar4 = pbVar4 + 1;
//     pbVar5 = pbVar5 + 1;
//   } while (bVar7);
//   if ((!bVar6 && !bVar7) == bVar6) {
//     iVar3 = system("/bin/sh");
//   }
//   else {
//     iVar3 = puts("\nInvalid Password");
//   }
//   if (local_10 == *(int *)(in_GS_OFFSET + 0x14)) {
//     return iVar3;
//   }
//                     /* WARNING: Subroutine does not return */
//   __stack_chk_fail();
// }


// /* Function: test. Address: 08048747 */

// void test(int param_1,int param_2)

// {
//   EVP_PKEY_CTX *pEVar1;
//   uchar *in_stack_ffffffd8;
//   size_t *in_stack_ffffffdc;
//   uchar *in_stack_ffffffe0;
//   size_t in_stack_ffffffe4;
  
//   pEVar1 = (EVP_PKEY_CTX *)(param_2 - param_1);
//   switch(pEVar1) {
//   default:
//     pEVar1 = (EVP_PKEY_CTX *)rand();
//     decrypt(pEVar1,in_stack_ffffffd8,in_stack_ffffffdc,in_stack_ffffffe0,in_stack_ffffffe4);
//     break;
//   case (EVP_PKEY_CTX *)0x1:
//     decrypt(pEVar1,in_stack_ffffffd8,in_stack_ffffffdc,in_stack_ffffffe0,in_stack_ffffffe4);
//     break;
//   case (EVP_PKEY_CTX *)0x2:
//     decrypt(pEVar1,in_stack_ffffffd8,in_stack_ffffffdc,in_stack_ffffffe0,in_stack_ffffffe4);
//     break;
//   case (EVP_PKEY_CTX *)0x3:
//     decrypt(pEVar1,in_stack_ffffffd8,in_stack_ffffffdc,in_stack_ffffffe0,in_stack_ffffffe4);
//     break;
//   case (EVP_PKEY_CTX *)0x4:
//     decrypt(pEVar1,in_stack_ffffffd8,in_stack_ffffffdc,in_stack_ffffffe0,in_stack_ffffffe4);
//     break;
//   case (EVP_PKEY_CTX *)0x5:
//     decrypt(pEVar1,in_stack_ffffffd8,in_stack_ffffffdc,in_stack_ffffffe0,in_stack_ffffffe4);
//     break;
//   case (EVP_PKEY_CTX *)0x6:
//     decrypt(pEVar1,in_stack_ffffffd8,in_stack_ffffffdc,in_stack_ffffffe0,in_stack_ffffffe4);
//     break;
//   case (EVP_PKEY_CTX *)0x7:
//     decrypt(pEVar1,in_stack_ffffffd8,in_stack_ffffffdc,in_stack_ffffffe0,in_stack_ffffffe4);
//     break;
//   case (EVP_PKEY_CTX *)0x8:
//     decrypt(pEVar1,in_stack_ffffffd8,in_stack_ffffffdc,in_stack_ffffffe0,in_stack_ffffffe4);
//     break;
//   case (EVP_PKEY_CTX *)0x9:
//     decrypt(pEVar1,in_stack_ffffffd8,in_stack_ffffffdc,in_stack_ffffffe0,in_stack_ffffffe4);
//     break;
//   case (EVP_PKEY_CTX *)0x10:
//     decrypt(pEVar1,in_stack_ffffffd8,in_stack_ffffffdc,in_stack_ffffffe0,in_stack_ffffffe4);
//     break;
//   case (EVP_PKEY_CTX *)0x11:
//     decrypt(pEVar1,in_stack_ffffffd8,in_stack_ffffffdc,in_stack_ffffffe0,in_stack_ffffffe4);
//     break;
//   case (EVP_PKEY_CTX *)0x12:
//     decrypt(pEVar1,in_stack_ffffffd8,in_stack_ffffffdc,in_stack_ffffffe0,in_stack_ffffffe4);
//     break;
//   case (EVP_PKEY_CTX *)0x13:
//     decrypt(pEVar1,in_stack_ffffffd8,in_stack_ffffffdc,in_stack_ffffffe0,in_stack_ffffffe4);
//     break;
//   case (EVP_PKEY_CTX *)0x14:
//     decrypt(pEVar1,in_stack_ffffffd8,in_stack_ffffffdc,in_stack_ffffffe0,in_stack_ffffffe4);
//     break;
//   case (EVP_PKEY_CTX *)0x15:
//     decrypt(pEVar1,in_stack_ffffffd8,in_stack_ffffffdc,in_stack_ffffffe0,in_stack_ffffffe4);
//   }
//   return;
// }


// /* Function: main. Address: 0804885a */

// /* WARNING: Removing unreachable block (ram,0x08048868) */

// undefined4 main(void)

// {
//   uint __seed;
  
//   __seed = time((time_t *)0x0);
//   srand(__seed);
//   puts("***********************************");
//   puts("*\t\tlevel03\t\t**");
//   puts("***********************************");
//   printf("Password:");
//   __isoc99_scanf();
//   test();
//   return 0;
// }

/* ************************************************************************* */
/* *                      Manually reconstructed code                      * */
/* ************************************************************************* */

// The source code was hard to restitue.
// Ghidra assumed the <openssl/evp.h> library was used for whatever reason.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <stdint.h>

/* Function: clear_stdin. Address: 080485f4 */

void    clear_stdin(void) {
    int c;

    do {
        c = getchar();
    } while (c != '\n' && c != EOF);
}

/* Function: get_unum. Address: 08048617 */

unsigned int    get_unum(void) {
    unsigned int  unum;

    unum = 0;
    fflush(stdout);
    scanf("%u", &unum); // objdump -s -j .rodata ~/level03
    clear_stdin();
    return unum;
}

/* Function: prog_timeout. Address: 0804864f */

void    prog_timeout(void) {
    exit(1);
}

/* Function: decrypt. Address: 08048660 */

/* WARNING: Removing unreachable block (ram,0x08048698) */

int decrypt(uint8_t hashing_key) {
    uint8_t password[17] = { 0x51, 0x7d, 0x7c, 0x75, 0x60, 0x73, 0x66, 0x67, 0x7e, 0x73, 0x66, 0x7b, 0x7d, 0x7c, 0x61, 0x33, 0x00 };

    for (size_t i = 0; i < sizeof(password) - 1; i++)
        password[i] ^= hashing_key;

    if (memcmp(password, "Congratulations!", 17) == 0)
        return system("/bin/sh");
    return puts("\nInvalid Password");
}

/* Function: test. Address: 08048747 */

void    test(int input_code, int magic_number) {
    uint8_t hashing_key = (uint8_t)(magic_number - input_code);

    switch(hashing_key) {
        case 0x1:
        case 0x2:
        case 0x3:
        case 0x4:
        case 0x5:
        case 0x6:
        case 0x7:
        case 0x8:
        case 0x9:
        case 0x10:
        case 0x11:
        case 0x12:
        case 0x13:
        case 0x14:
        case 0x15:
            decrypt(hashing_key);
            break;
        default:
            hashing_key = (uint8_t)rand();
            decrypt(hashing_key);
            break;
    }
}

/* Function: main. Address: 0804885a */

int main(void) {
    time_t  seed;
    int     input;

    seed = time(NULL);
    srand(seed);

    puts("***********************************");
    puts("*\t\tlevel03\t\t**");
    puts("***********************************");

    printf("Password:");
    scanf("%d", &input);
    test(input, 0x1337d00d);

    return 0;
}