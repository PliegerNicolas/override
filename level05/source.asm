Disassembly of section .plt:

08048370 <exit@plt>:
 8048370:	ff 25 e0 97 04 08    	jmp    *0x80497e0
 8048376:	68 18 00 00 00       	push   $0x18
 804837b:	e9 b0 ff ff ff       	jmp    8048330 <_init+0x38>

Disassembly of section .text:

08048444 <main>:
 8048444:	55                   	push   %ebp
 8048445:	89 e5                	mov    %esp,%ebp
 8048447:	57                   	push   %edi
 8048448:	53                   	push   %ebx
 8048449:	83 e4 f0             	and    $0xfffffff0,%esp
 804844c:	81 ec 90 00 00 00    	sub    $0x90,%esp
 8048452:	c7 84 24 8c 00 00 00 	movl   $0x0,0x8c(%esp)
 8048459:	00 00 00 00 
 804845d:	a1 f0 97 04 08       	mov    0x80497f0,%eax
 8048462:	89 44 24 08          	mov    %eax,0x8(%esp)
 8048466:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
 804846d:	00 
 804846e:	8d 44 24 28          	lea    0x28(%esp),%eax
 8048472:	89 04 24             	mov    %eax,(%esp)
 8048475:	e8 d6 fe ff ff       	call   8048350 <fgets@plt>
 804847a:	c7 84 24 8c 00 00 00 	movl   $0x0,0x8c(%esp)
 8048481:	00 00 00 00 
 8048485:	eb 4c                	jmp    80484d3 <main+0x8f>
 8048487:	8d 44 24 28          	lea    0x28(%esp),%eax
 804848b:	03 84 24 8c 00 00 00 	add    0x8c(%esp),%eax
 8048492:	0f b6 00             	movzbl (%eax),%eax
 8048495:	3c 40                	cmp    $0x40,%al
 8048497:	7e 32                	jle    80484cb <main+0x87>
 8048499:	8d 44 24 28          	lea    0x28(%esp),%eax
 804849d:	03 84 24 8c 00 00 00 	add    0x8c(%esp),%eax
 80484a4:	0f b6 00             	movzbl (%eax),%eax
 80484a7:	3c 5a                	cmp    $0x5a,%al
 80484a9:	7f 20                	jg     80484cb <main+0x87>
 80484ab:	8d 44 24 28          	lea    0x28(%esp),%eax
 80484af:	03 84 24 8c 00 00 00 	add    0x8c(%esp),%eax
 80484b6:	0f b6 00             	movzbl (%eax),%eax
 80484b9:	89 c2                	mov    %eax,%edx
 80484bb:	83 f2 20             	xor    $0x20,%edx
 80484be:	8d 44 24 28          	lea    0x28(%esp),%eax
 80484c2:	03 84 24 8c 00 00 00 	add    0x8c(%esp),%eax
 80484c9:	88 10                	mov    %dl,(%eax)
 80484cb:	83 84 24 8c 00 00 00 	addl   $0x1,0x8c(%esp)
 80484d2:	01 
 80484d3:	8b 9c 24 8c 00 00 00 	mov    0x8c(%esp),%ebx
 80484da:	8d 44 24 28          	lea    0x28(%esp),%eax
 80484de:	c7 44 24 1c ff ff ff 	movl   $0xffffffff,0x1c(%esp)
 80484e5:	ff 
 80484e6:	89 c2                	mov    %eax,%edx
 80484e8:	b8 00 00 00 00       	mov    $0x0,%eax
 80484ed:	8b 4c 24 1c          	mov    0x1c(%esp),%ecx
 80484f1:	89 d7                	mov    %edx,%edi
 80484f3:	f2 ae                	repnz scas %es:(%edi),%al
 80484f5:	89 c8                	mov    %ecx,%eax
 80484f7:	f7 d0                	not    %eax
 80484f9:	83 e8 01             	sub    $0x1,%eax
 80484fc:	39 c3                	cmp    %eax,%ebx
 80484fe:	72 87                	jb     8048487 <main+0x43>
 8048500:	8d 44 24 28          	lea    0x28(%esp),%eax
 8048504:	89 04 24             	mov    %eax,(%esp)
 8048507:	e8 34 fe ff ff       	call   8048340 <printf@plt>
 804850c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
 8048513:	e8 58 fe ff ff       	call   8048370 <exit@plt>
 8048518:	90                   	nop
 8048519:	90                   	nop
 804851a:	90                   	nop
 804851b:	90                   	nop
 804851c:	90                   	nop
 804851d:	90                   	nop
 804851e:	90                   	nop
 804851f:	90                   	nop
