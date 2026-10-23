/* ************************************************************************* */
/* *                       Decompiled code via GHIDRA                      * */
/* ************************************************************************* */

// /* Function: log_wrapper. Address: 004008c4 */

// void log_wrapper(FILE *param_1,char *param_2,char *param_3)

// {
//   char cVar1;
//   size_t sVar2;
//   ulong uVar3;
//   ulong uVar4;
//   char *pcVar5;
//   long in_FS_OFFSET;
//   byte bVar6;
//   undefined8 local_120;
//   char local_118 [264];
//   long local_10;
  
//   bVar6 = 0;
//   local_10 = *(long *)(in_FS_OFFSET + 0x28);
//   local_120 = param_1;
//   strcpy(local_118,param_2);
//   uVar3 = 0xffffffffffffffff;
//   pcVar5 = local_118;
//   do {
//     if (uVar3 == 0) break;
//     uVar3 = uVar3 - 1;
//     cVar1 = *pcVar5;
//     pcVar5 = pcVar5 + (ulong)bVar6 * -2 + 1;
//   } while (cVar1 != '\0');
//   uVar4 = 0xffffffffffffffff;
//   pcVar5 = local_118;
//   do {
//     if (uVar4 == 0) break;
//     uVar4 = uVar4 - 1;
//     cVar1 = *pcVar5;
//     pcVar5 = pcVar5 + (ulong)bVar6 * -2 + 1;
//   } while (cVar1 != '\0');
//   snprintf(local_118 + (~uVar4 - 1),0xfe - (~uVar3 - 1),param_3);
//   sVar2 = strcspn(local_118,"\n");
//   local_118[sVar2] = '\0';
//   fprintf(local_120,"LOG: %s\n",local_118);
//   if (local_10 != *(long *)(in_FS_OFFSET + 0x28)) {
//                     /* WARNING: Subroutine does not return */
//     __stack_chk_fail();
//   }
//   return;
// }


// /* Function: main. Address: 004009f0 */

// undefined8 main(int param_1,undefined8 *param_2)

// {
//   char cVar1;
//   int __fd;
//   int iVar2;
//   FILE *pFVar3;
//   FILE *__stream;
//   ulong uVar4;
//   char *pcVar5;
//   long in_FS_OFFSET;
//   byte bVar6;
//   char local_79;
//   char local_78 [8];
//   char local_70 [2];
//   char local_6e;
//   long local_10;
  
//   bVar6 = 0;
//   local_10 = *(long *)(in_FS_OFFSET + 0x28);
//   local_79 = -1;
//   if (param_1 != 2) {
//     printf("Usage: %s filename\n",*param_2);
//   }
//   pFVar3 = fopen("./backups/.log","w");
//   if (pFVar3 == (FILE *)0x0) {
//     printf("ERROR: Failed to open %s\n","./backups/.log");
//                     /* WARNING: Subroutine does not return */
//     exit(1);
//   }
//   log_wrapper(pFVar3,"Starting back up: ",param_2[1]);
//   __stream = fopen((char *)param_2[1],"r");
//   if (__stream == (FILE *)0x0) {
//     printf("ERROR: Failed to open %s\n",param_2[1]);
//                     /* WARNING: Subroutine does not return */
//     exit(1);
//   }
//   local_78[0] = s___backups__00400dab[0];
//   local_78[1] = s___backups__00400dab[1];
//   local_78[2] = s___backups__00400dab[2];
//   local_78[3] = s___backups__00400dab[3];
//   local_78[4] = s___backups__00400dab[4];
//   local_78[5] = s___backups__00400dab[5];
//   local_78[6] = s___backups__00400dab[6];
//   local_78[7] = s___backups__00400dab[7];
//   local_70[0] = s___backups__00400dab[8];
//   local_70[1] = s___backups__00400dab[9];
//   local_6e = s___backups__00400dab[10];
//   uVar4 = 0xffffffffffffffff;
//   pcVar5 = local_78;
//   do {
//     if (uVar4 == 0) break;
//     uVar4 = uVar4 - 1;
//     cVar1 = *pcVar5;
//     pcVar5 = pcVar5 + (ulong)bVar6 * -2 + 1;
//   } while (cVar1 != '\0');
//   strncat(local_78,(char *)param_2[1],99 - (~uVar4 - 1));
//   __fd = open(local_78,0xc1,0x1b0);
//   if (__fd < 0) {
//     printf("ERROR: Failed to open %s%s\n","./backups/",param_2[1]);
//                     /* WARNING: Subroutine does not return */
//     exit(1);
//   }
//   while( true ) {
//     iVar2 = fgetc(__stream);
//     local_79 = (char)iVar2;
//     if (local_79 == -1) break;
//     write(__fd,&local_79,1);
//   }
//   log_wrapper(pFVar3,"Finished back up ",param_2[1]);
//   fclose(__stream);
//   close(__fd);
//   if (local_10 != *(long *)(in_FS_OFFSET + 0x28)) {
//                     /* WARNING: Subroutine does not return */
//     __stack_chk_fail();
//   }
//   return 0;
// }

/* ************************************************************************* */
/* *                      Manually reconstructed code                      * */
/* ************************************************************************* */

#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <stdbool.h>

// Ghidra artefact. Defined just to satisfy vscode.
#define in_FS_OFFSET 0

/* Function: log_wrapper. Address: 004008c4 */

void    log_wrapper(FILE *log_stream, char *prefix, char *fmt) {
    size_t  prefix_len;
    char    line[264];
    long    canary;

    canary = *(long *)(in_FS_OFFSET + 0x28);

    strcpy(line, prefix);

    prefix_len = strlen(line);
    snprintf(line + prefix_len, (sizeof(line) - 10) - prefix_len, fmt);

    line[strcspn(line, "\n")] = '\0';

    fprintf(log_stream, "LOG: %s\n", line);

    if (canary != *(long *)(in_FS_OFFSET + 0x28))
        __stack_chk_fail();
}

/* Function: main. Address: 004009f0 */

int main(int argc, char *argv[]) {
    int             fd;
    int             c;
    FILE            *backup_file;
    FILE            *file_to_backup;
    char            backup_path[100];
    long            canary;

    canary = *(long *)(in_FS_OFFSET + 0x28); // Init canary. This only helps detecting contiguous overflows. We can skip it by direct writes.

    if (argc != 2)
        printf("Usage: %s filename\n",*argv);

    backup_file = fopen("./backups/.log", "w");
    if (backup_file == NULL) {
        printf("ERROR: Failed to open %s\n", "./backups/.log");
        exit(1);
    }

    log_wrapper(backup_file, "Starting back up: ", argv[1]);

    file_to_backup = fopen(argv[1], "r");
    if (file_to_backup == NULL) {
        printf("ERROR: Failed to open %s\n", argv[1]);
        exit(1);
    }

    strcpy(backup_path, "./backups/");
    strncat(backup_path, argv[1], 99 - strlen(backup_path));

    fd = open(backup_path, O_WRONLY | O_CREAT | O_EXCL, 0660);
    if (fd < 0) {
        printf("ERROR: Failed to open %s%s\n", "./backups/", argv[1]);
        exit(1);
    }

    while (true) {
        c = fgetc(file_to_backup);
        if ((char)c == -1)
            break;
        write(fd, &c, 1);
    }

    log_wrapper(backup_file, "Finished back up ", argv[1]);
    fclose(file_to_backup);
    close(fd);

    if (canary != *(long *)(in_FS_OFFSET + 0x28)) // Verify canary
        __stack_chk_fail();

    return 0;
}
