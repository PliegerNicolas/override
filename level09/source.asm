Disassembly of section .text:

000000000000088c <secret_backdoor>:
 88c:	55                   	push   %rbp
 88d:	48 89 e5             	mov    %rsp,%rbp
 890:	48 83 c4 80          	add    $0xffffffffffffff80,%rsp
 894:	48 8b 05 1d 17 20 00 	mov    0x20171d(%rip),%rax        # 201fb8 <_DYNAMIC+0x198>
 89b:	48 8b 00             	mov    (%rax),%rax
 89e:	48 89 c2             	mov    %rax,%rdx
 8a1:	48 8d 45 80          	lea    -0x80(%rbp),%rax
 8a5:	be 80 00 00 00       	mov    $0x80,%esi
 8aa:	48 89 c7             	mov    %rax,%rdi
 8ad:	e8 be fe ff ff       	callq  770 <fgets@plt>
 8b2:	48 8d 45 80          	lea    -0x80(%rbp),%rax
 8b6:	48 89 c7             	mov    %rax,%rdi
 8b9:	e8 82 fe ff ff       	callq  740 <system@plt>
 8be:	c9                   	leaveq 
 8bf:	c3                   	retq   

00000000000008c0 <handle_msg>:
 8c0:	55                   	push   %rbp
 8c1:	48 89 e5             	mov    %rsp,%rbp
 8c4:	48 81 ec c0 00 00 00 	sub    $0xc0,%rsp
 8cb:	48 8d 85 40 ff ff ff 	lea    -0xc0(%rbp),%rax
 8d2:	48 05 8c 00 00 00    	add    $0x8c,%rax
 8d8:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
 8df:	48 c7 40 08 00 00 00 	movq   $0x0,0x8(%rax)
 8e6:	00 
 8e7:	48 c7 40 10 00 00 00 	movq   $0x0,0x10(%rax)
 8ee:	00 
 8ef:	48 c7 40 18 00 00 00 	movq   $0x0,0x18(%rax)
 8f6:	00 
 8f7:	48 c7 40 20 00 00 00 	movq   $0x0,0x20(%rax)
 8fe:	00 
 8ff:	c7 45 f4 8c 00 00 00 	movl   $0x8c,-0xc(%rbp)
 906:	48 8d 85 40 ff ff ff 	lea    -0xc0(%rbp),%rax
 90d:	48 89 c7             	mov    %rax,%rdi
 910:	e8 b8 00 00 00       	callq  9cd <set_username>
 915:	48 8d 85 40 ff ff ff 	lea    -0xc0(%rbp),%rax
 91c:	48 89 c7             	mov    %rax,%rdi
 91f:	e8 0e 00 00 00       	callq  932 <set_msg>
 924:	48 8d 3d 95 02 00 00 	lea    0x295(%rip),%rdi        # bc0 <_IO_stdin_used+0x8>
 92b:	e8 00 fe ff ff       	callq  730 <puts@plt>
 930:	c9                   	leaveq 
 931:	c3                   	retq   

0000000000000932 <set_msg>:
 932:	55                   	push   %rbp
 933:	48 89 e5             	mov    %rsp,%rbp
 936:	48 81 ec 10 04 00 00 	sub    $0x410,%rsp
 93d:	48 89 bd f8 fb ff ff 	mov    %rdi,-0x408(%rbp)
 944:	48 8d 85 00 fc ff ff 	lea    -0x400(%rbp),%rax
 94b:	48 89 c6             	mov    %rax,%rsi
 94e:	b8 00 00 00 00       	mov    $0x0,%eax
 953:	ba 80 00 00 00       	mov    $0x80,%edx
 958:	48 89 f7             	mov    %rsi,%rdi
 95b:	48 89 d1             	mov    %rdx,%rcx
 95e:	f3 48 ab             	rep stos %rax,%es:(%rdi)
 961:	48 8d 3d 65 02 00 00 	lea    0x265(%rip),%rdi        # bcd <_IO_stdin_used+0x15>
 968:	e8 c3 fd ff ff       	callq  730 <puts@plt>
 96d:	48 8d 05 6b 02 00 00 	lea    0x26b(%rip),%rax        # bdf <_IO_stdin_used+0x27>
 974:	48 89 c7             	mov    %rax,%rdi
 977:	b8 00 00 00 00       	mov    $0x0,%eax
 97c:	e8 cf fd ff ff       	callq  750 <printf@plt>
 981:	48 8b 05 30 16 20 00 	mov    0x201630(%rip),%rax        # 201fb8 <_DYNAMIC+0x198>
 988:	48 8b 00             	mov    (%rax),%rax
 98b:	48 89 c2             	mov    %rax,%rdx
 98e:	48 8d 85 00 fc ff ff 	lea    -0x400(%rbp),%rax
 995:	be 00 04 00 00       	mov    $0x400,%esi
 99a:	48 89 c7             	mov    %rax,%rdi
 99d:	e8 ce fd ff ff       	callq  770 <fgets@plt>
 9a2:	48 8b 85 f8 fb ff ff 	mov    -0x408(%rbp),%rax
 9a9:	8b 80 b4 00 00 00    	mov    0xb4(%rax),%eax
 9af:	48 63 d0             	movslq %eax,%rdx
 9b2:	48 8d 8d 00 fc ff ff 	lea    -0x400(%rbp),%rcx
 9b9:	48 8b 85 f8 fb ff ff 	mov    -0x408(%rbp),%rax
 9c0:	48 89 ce             	mov    %rcx,%rsi
 9c3:	48 89 c7             	mov    %rax,%rdi
 9c6:	e8 55 fd ff ff       	callq  720 <strncpy@plt>
 9cb:	c9                   	leaveq 
 9cc:	c3                   	retq   

00000000000009cd <set_username>:
 9cd:	55                   	push   %rbp
 9ce:	48 89 e5             	mov    %rsp,%rbp
 9d1:	48 81 ec a0 00 00 00 	sub    $0xa0,%rsp
 9d8:	48 89 bd 68 ff ff ff 	mov    %rdi,-0x98(%rbp)
 9df:	48 8d 85 70 ff ff ff 	lea    -0x90(%rbp),%rax
 9e6:	48 89 c6             	mov    %rax,%rsi
 9e9:	b8 00 00 00 00       	mov    $0x0,%eax
 9ee:	ba 10 00 00 00       	mov    $0x10,%edx
 9f3:	48 89 f7             	mov    %rsi,%rdi
 9f6:	48 89 d1             	mov    %rdx,%rcx
 9f9:	f3 48 ab             	rep stos %rax,%es:(%rdi)
 9fc:	48 8d 3d e1 01 00 00 	lea    0x1e1(%rip),%rdi        # be4 <_IO_stdin_used+0x2c>
 a03:	e8 28 fd ff ff       	callq  730 <puts@plt>
 a08:	48 8d 05 d0 01 00 00 	lea    0x1d0(%rip),%rax        # bdf <_IO_stdin_used+0x27>
 a0f:	48 89 c7             	mov    %rax,%rdi
 a12:	b8 00 00 00 00       	mov    $0x0,%eax
 a17:	e8 34 fd ff ff       	callq  750 <printf@plt>
 a1c:	48 8b 05 95 15 20 00 	mov    0x201595(%rip),%rax        # 201fb8 <_DYNAMIC+0x198>
 a23:	48 8b 00             	mov    (%rax),%rax
 a26:	48 89 c2             	mov    %rax,%rdx
 a29:	48 8d 85 70 ff ff ff 	lea    -0x90(%rbp),%rax
 a30:	be 80 00 00 00       	mov    $0x80,%esi
 a35:	48 89 c7             	mov    %rax,%rdi
 a38:	e8 33 fd ff ff       	callq  770 <fgets@plt>
 a3d:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
 a44:	eb 24                	jmp    a6a <set_username+0x9d>
 a46:	8b 45 fc             	mov    -0x4(%rbp),%eax
 a49:	48 98                	cltq   
 a4b:	0f b6 8c 05 70 ff ff 	movzbl -0x90(%rbp,%rax,1),%ecx
 a52:	ff 
 a53:	48 8b 95 68 ff ff ff 	mov    -0x98(%rbp),%rdx
 a5a:	8b 45 fc             	mov    -0x4(%rbp),%eax
 a5d:	48 98                	cltq   
 a5f:	88 8c 02 8c 00 00 00 	mov    %cl,0x8c(%rdx,%rax,1)
 a66:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
 a6a:	83 7d fc 28          	cmpl   $0x28,-0x4(%rbp)
 a6e:	7f 11                	jg     a81 <set_username+0xb4>
 a70:	8b 45 fc             	mov    -0x4(%rbp),%eax
 a73:	48 98                	cltq   
 a75:	0f b6 84 05 70 ff ff 	movzbl -0x90(%rbp,%rax,1),%eax
 a7c:	ff 
 a7d:	84 c0                	test   %al,%al
 a7f:	75 c5                	jne    a46 <set_username+0x79>
 a81:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
 a88:	48 8d 90 8c 00 00 00 	lea    0x8c(%rax),%rdx
 a8f:	48 8d 05 65 01 00 00 	lea    0x165(%rip),%rax        # bfb <_IO_stdin_used+0x43>
 a96:	48 89 d6             	mov    %rdx,%rsi
 a99:	48 89 c7             	mov    %rax,%rdi
 a9c:	b8 00 00 00 00       	mov    $0x0,%eax
 aa1:	e8 aa fc ff ff       	callq  750 <printf@plt>
 aa6:	c9                   	leaveq 
 aa7:	c3                   	retq   

0000000000000aa8 <main>:
 aa8:	55                   	push   %rbp
 aa9:	48 89 e5             	mov    %rsp,%rbp
 aac:	48 8d 3d 5d 01 00 00 	lea    0x15d(%rip),%rdi        # c10 <_IO_stdin_used+0x58>
 ab3:	e8 78 fc ff ff       	callq  730 <puts@plt>
 ab8:	e8 03 fe ff ff       	callq  8c0 <handle_msg>
 abd:	b8 00 00 00 00       	mov    $0x0,%eax
 ac2:	5d                   	pop    %rbp
 ac3:	c3                   	retq   
 ac4:	90                   	nop
 ac5:	90                   	nop
 ac6:	90                   	nop
 ac7:	90                   	nop
 ac8:	90                   	nop
 ac9:	90                   	nop
 aca:	90                   	nop
 acb:	90                   	nop
 acc:	90                   	nop
 acd:	90                   	nop
 ace:	90                   	nop
 acf:	90                   	nop
