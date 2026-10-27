08048634 <clear_stdin>:
 8048634:	55                   	push   %ebp
 8048635:	89 e5                	mov    %esp,%ebp
 8048637:	83 ec 18             	sub    $0x18,%esp
 804863a:	c6 45 f7 00          	movb   $0x0,-0x9(%ebp)
 804863e:	eb 01                	jmp    8048641 <clear_stdin+0xd>
 8048640:	90                   	nop
 8048641:	e8 7a fe ff ff       	call   80484c0 <getchar@plt>
 8048646:	88 45 f7             	mov    %al,-0x9(%ebp)
 8048649:	80 7d f7 0a          	cmpb   $0xa,-0x9(%ebp)
 804864d:	74 06                	je     8048655 <clear_stdin+0x21>
 804864f:	80 7d f7 ff          	cmpb   $0xff,-0x9(%ebp)
 8048653:	75 eb                	jne    8048640 <clear_stdin+0xc>
 8048655:	c9                   	leave  
 8048656:	c3                   	ret    

08048657 <get_unum>:
 8048657:	55                   	push   %ebp
 8048658:	89 e5                	mov    %esp,%ebp
 804865a:	83 ec 28             	sub    $0x28,%esp
 804865d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
 8048664:	a1 40 a0 04 08       	mov    0x804a040,%eax
 8048669:	89 04 24             	mov    %eax,(%esp)
 804866c:	e8 2f fe ff ff       	call   80484a0 <fflush@plt>
 8048671:	b8 00 89 04 08       	mov    $0x8048900,%eax
 8048676:	8d 55 f4             	lea    -0xc(%ebp),%edx
 8048679:	89 54 24 04          	mov    %edx,0x4(%esp)
 804867d:	89 04 24             	mov    %eax,(%esp)
 8048680:	e8 db fe ff ff       	call   8048560 <__isoc99_scanf@plt>
 8048685:	e8 aa ff ff ff       	call   8048634 <clear_stdin>
 804868a:	8b 45 f4             	mov    -0xc(%ebp),%eax
 804868d:	c9                   	leave  
 804868e:	c3                   	ret    

0804868f <prog_timeout>:
 804868f:	55                   	push   %ebp
 8048690:	89 e5                	mov    %esp,%ebp
 8048692:	b8 01 00 00 00       	mov    $0x1,%eax
 8048697:	bb 01 00 00 00       	mov    $0x1,%ebx
 804869c:	cd 80                	int    $0x80
 804869e:	5d                   	pop    %ebp
 804869f:	c3                   	ret    

080486a0 <enable_timeout_cons>:
 80486a0:	55                   	push   %ebp
 80486a1:	89 e5                	mov    %esp,%ebp
 80486a3:	83 ec 18             	sub    $0x18,%esp
 80486a6:	c7 44 24 04 8f 86 04 	movl   $0x804868f,0x4(%esp)
 80486ad:	08 
 80486ae:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
 80486b5:	e8 16 fe ff ff       	call   80484d0 <signal@plt>
 80486ba:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
 80486c1:	e8 1a fe ff ff       	call   80484e0 <alarm@plt>
 80486c6:	c9                   	leave  
 80486c7:	c3                   	ret    

080486c8 <main>:
 80486c8:	55                   	push   %ebp
 80486c9:	89 e5                	mov    %esp,%ebp
 80486cb:	57                   	push   %edi
 80486cc:	53                   	push   %ebx
 80486cd:	83 e4 f0             	and    $0xfffffff0,%esp
 80486d0:	81 ec b0 00 00 00    	sub    $0xb0,%esp
 80486d6:	e8 75 fe ff ff       	call   8048550 <fork@plt>
 80486db:	89 84 24 ac 00 00 00 	mov    %eax,0xac(%esp)
 80486e2:	8d 5c 24 20          	lea    0x20(%esp),%ebx
 80486e6:	b8 00 00 00 00       	mov    $0x0,%eax
 80486eb:	ba 20 00 00 00       	mov    $0x20,%edx
 80486f0:	89 df                	mov    %ebx,%edi
 80486f2:	89 d1                	mov    %edx,%ecx
 80486f4:	f3 ab                	rep stos %eax,%es:(%edi)
 80486f6:	c7 84 24 a8 00 00 00 	movl   $0x0,0xa8(%esp)
 80486fd:	00 00 00 00 
 8048701:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
 8048708:	00 
 8048709:	83 bc 24 ac 00 00 00 	cmpl   $0x0,0xac(%esp)
 8048710:	00 
 8048711:	75 56                	jne    8048769 <main+0xa1>
 8048713:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
 804871a:	00 
 804871b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
 8048722:	e8 19 fe ff ff       	call   8048540 <prctl@plt>
 8048727:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
 804872e:	00 
 804872f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
 8048736:	00 
 8048737:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
 804873e:	00 
 804873f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
 8048746:	e8 25 fe ff ff       	call   8048570 <ptrace@plt>
 804874b:	c7 04 24 03 89 04 08 	movl   $0x8048903,(%esp)
 8048752:	e8 a9 fd ff ff       	call   8048500 <puts@plt>
 8048757:	8d 44 24 20          	lea    0x20(%esp),%eax
 804875b:	89 04 24             	mov    %eax,(%esp)
 804875e:	e8 4d fd ff ff       	call   80484b0 <gets@plt>
 8048763:	e9 b2 00 00 00       	jmp    804881a <main+0x152>
 8048768:	90                   	nop
 8048769:	8d 44 24 1c          	lea    0x1c(%esp),%eax
 804876d:	89 04 24             	mov    %eax,(%esp)
 8048770:	e8 7b fd ff ff       	call   80484f0 <wait@plt>
 8048775:	8b 44 24 1c          	mov    0x1c(%esp),%eax
 8048779:	89 84 24 a0 00 00 00 	mov    %eax,0xa0(%esp)
 8048780:	8b 84 24 a0 00 00 00 	mov    0xa0(%esp),%eax
 8048787:	83 e0 7f             	and    $0x7f,%eax
 804878a:	85 c0                	test   %eax,%eax
 804878c:	74 1e                	je     80487ac <main+0xe4>
 804878e:	8b 44 24 1c          	mov    0x1c(%esp),%eax
 8048792:	89 84 24 a4 00 00 00 	mov    %eax,0xa4(%esp)
 8048799:	8b 84 24 a4 00 00 00 	mov    0xa4(%esp),%eax
 80487a0:	83 e0 7f             	and    $0x7f,%eax
 80487a3:	83 c0 01             	add    $0x1,%eax
 80487a6:	d0 f8                	sar    %al
 80487a8:	84 c0                	test   %al,%al
 80487aa:	7e 0e                	jle    80487ba <main+0xf2>
 80487ac:	c7 04 24 1d 89 04 08 	movl   $0x804891d,(%esp)
 80487b3:	e8 48 fd ff ff       	call   8048500 <puts@plt>
 80487b8:	eb 60                	jmp    804881a <main+0x152>
 80487ba:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
 80487c1:	00 
 80487c2:	c7 44 24 08 2c 00 00 	movl   $0x2c,0x8(%esp)
 80487c9:	00 
 80487ca:	8b 84 24 ac 00 00 00 	mov    0xac(%esp),%eax
 80487d1:	89 44 24 04          	mov    %eax,0x4(%esp)
 80487d5:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
 80487dc:	e8 8f fd ff ff       	call   8048570 <ptrace@plt>
 80487e1:	89 84 24 a8 00 00 00 	mov    %eax,0xa8(%esp)
 80487e8:	83 bc 24 a8 00 00 00 	cmpl   $0xb,0xa8(%esp)
 80487ef:	0b 
 80487f0:	0f 85 72 ff ff ff    	jne    8048768 <main+0xa0>
 80487f6:	c7 04 24 31 89 04 08 	movl   $0x8048931,(%esp)
 80487fd:	e8 fe fc ff ff       	call   8048500 <puts@plt>
 8048802:	c7 44 24 04 09 00 00 	movl   $0x9,0x4(%esp)
 8048809:	00 
 804880a:	8b 84 24 ac 00 00 00 	mov    0xac(%esp),%eax
 8048811:	89 04 24             	mov    %eax,(%esp)
 8048814:	e8 07 fd ff ff       	call   8048520 <kill@plt>
 8048819:	90                   	nop
 804881a:	b8 00 00 00 00       	mov    $0x0,%eax
 804881f:	8d 65 f8             	lea    -0x8(%ebp),%esp
 8048822:	5b                   	pop    %ebx
 8048823:	5f                   	pop    %edi
 8048824:	5d                   	pop    %ebp
 8048825:	c3                   	ret    
 8048826:	90                   	nop
 8048827:	90                   	nop
 8048828:	90                   	nop
 8048829:	90                   	nop
 804882a:	90                   	nop
 804882b:	90                   	nop
 804882c:	90                   	nop
 804882d:	90                   	nop
 804882e:	90                   	nop
 804882f:	90                   	nop
