
obj/boot/boot.out:     file format elf32-i386


Disassembly of section .text:

00007c00 <start>:
.set CR0_PE_ON,      0x1         # protected mode enable flag

.globl start
start:
  .code16                     # Assemble for 16-bit mode
  cli                         # Disable interrupts
    7c00:	fa                   	cli    
  cld                         # String operations increment
    7c01:	fc                   	cld    

  # Set up the important data segment registers (DS, ES, SS).
  xorw    %ax,%ax             # Segment number zero
    7c02:	31 c0                	xor    %eax,%eax
  movw    %ax,%ds             # -> Data Segment
    7c04:	8e d8                	mov    %eax,%ds
  movw    %ax,%es             # -> Extra Segment
    7c06:	8e c0                	mov    %eax,%es
  movw    %ax,%ss             # -> Stack Segment
    7c08:	8e d0                	mov    %eax,%ss

00007c0a <seta20.1>:
  # Enable A20:
  #   For backwards compatibility with the earliest PCs, physical
  #   address line 20 is tied low, so that addresses higher than
  #   1MB wrap around to zero by default.  This code undoes this.
seta20.1:
  inb     $0x64,%al               # Wait for not busy
    7c0a:	e4 64                	in     $0x64,%al
  testb   $0x2,%al
    7c0c:	a8 02                	test   $0x2,%al
  jnz     seta20.1
    7c0e:	75 fa                	jne    7c0a <seta20.1>

  movb    $0xd1,%al               # 0xd1 -> port 0x64
    7c10:	b0 d1                	mov    $0xd1,%al
  outb    %al,$0x64
    7c12:	e6 64                	out    %al,$0x64

00007c14 <seta20.2>:

seta20.2:
  inb     $0x64,%al               # Wait for not busy
    7c14:	e4 64                	in     $0x64,%al
  testb   $0x2,%al
    7c16:	a8 02                	test   $0x2,%al
  jnz     seta20.2
    7c18:	75 fa                	jne    7c14 <seta20.2>

  movb    $0xdf,%al               # 0xdf -> port 0x60
    7c1a:	b0 df                	mov    $0xdf,%al
  outb    %al,$0x60
    7c1c:	e6 60                	out    %al,$0x60

  # Switch from real to protected mode, using a bootstrap GDT
  # and segment translation that makes virtual addresses 
  # identical to their physical addresses, so that the 
  # effective memory map does not change during the switch.
  lgdt    gdtdesc
    7c1e:	0f 01 16             	lgdtl  (%esi)
    7c21:	64 7c 0f             	fs jl  7c33 <protcseg+0x1>
  movl    %cr0, %eax
    7c24:	20 c0                	and    %al,%al
  orl     $CR0_PE_ON, %eax
    7c26:	66 83 c8 01          	or     $0x1,%ax
  movl    %eax, %cr0
    7c2a:	0f 22 c0             	mov    %eax,%cr0
  
  # Jump to next instruction, but in 32-bit code segment.
  # Switches processor into 32-bit mode.
  ljmp    $PROT_MODE_CSEG, $protcseg
    7c2d:	ea 32 7c 08 00 66 b8 	ljmp   $0xb866,$0x87c32

00007c32 <protcseg>:

  .code32                     # Assemble for 32-bit mode
protcseg:
  # Set up the protected-mode data segment registers
  movw    $PROT_MODE_DSEG, %ax    # Our data segment selector
    7c32:	66 b8 10 00          	mov    $0x10,%ax
  movw    %ax, %ds                # -> DS: Data Segment
    7c36:	8e d8                	mov    %eax,%ds
  movw    %ax, %es                # -> ES: Extra Segment
    7c38:	8e c0                	mov    %eax,%es
  movw    %ax, %fs                # -> FS
    7c3a:	8e e0                	mov    %eax,%fs
  movw    %ax, %gs                # -> GS
    7c3c:	8e e8                	mov    %eax,%gs
  movw    %ax, %ss                # -> SS: Stack Segment
    7c3e:	8e d0                	mov    %eax,%ss
  
  # Set up the stack pointer and call into C.
  movl    $start, %esp
    7c40:	bc 00 7c 00 00       	mov    $0x7c00,%esp
  call bootmain
    7c45:	e8 be 00 00 00       	call   7d08 <bootmain>

00007c4a <spin>:

  # If bootmain returns (it shouldn't), loop.
spin:
  jmp spin
    7c4a:	eb fe                	jmp    7c4a <spin>

00007c4c <gdt>:
	...
    7c54:	ff                   	(bad)  
    7c55:	ff 00                	incl   (%eax)
    7c57:	00 00                	add    %al,(%eax)
    7c59:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
    7c60:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

00007c64 <gdtdesc>:
    7c64:	17                   	pop    %ss
    7c65:	00 4c 7c 00          	add    %cl,0x0(%esp,%edi,2)
	...

00007c6a <waitdisk>:
	}
}

void
waitdisk(void)
{
    7c6a:	55                   	push   %ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
    7c6b:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7c70:	89 e5                	mov    %esp,%ebp
    7c72:	ec                   	in     (%dx),%al
	// wait for disk reaady
	while ((inb(0x1F7) & 0xC0) != 0x40)
    7c73:	83 e0 c0             	and    $0xffffffc0,%eax
    7c76:	3c 40                	cmp    $0x40,%al
    7c78:	75 f8                	jne    7c72 <waitdisk+0x8>
		/* do nothing */;
}
    7c7a:	5d                   	pop    %ebp
    7c7b:	c3                   	ret    

00007c7c <readsect>:

void
readsect(void *dst, uint32_t offset)
{
    7c7c:	55                   	push   %ebp
    7c7d:	89 e5                	mov    %esp,%ebp
    7c7f:	57                   	push   %edi
    7c80:	53                   	push   %ebx
    7c81:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// wait for disk to be ready
	waitdisk();
    7c84:	e8 e1 ff ff ff       	call   7c6a <waitdisk>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
    7c89:	ba f2 01 00 00       	mov    $0x1f2,%edx
    7c8e:	b0 01                	mov    $0x1,%al
    7c90:	ee                   	out    %al,(%dx)
    7c91:	b2 f3                	mov    $0xf3,%dl
    7c93:	88 d8                	mov    %bl,%al
    7c95:	ee                   	out    %al,(%dx)

	outb(0x1F2, 1);		// count = 1
	outb(0x1F3, offset);
	outb(0x1F4, offset >> 8);
    7c96:	89 d8                	mov    %ebx,%eax
    7c98:	b2 f4                	mov    $0xf4,%dl
    7c9a:	c1 e8 08             	shr    $0x8,%eax
    7c9d:	ee                   	out    %al,(%dx)
	outb(0x1F5, offset >> 16);
    7c9e:	89 d8                	mov    %ebx,%eax
    7ca0:	b2 f5                	mov    $0xf5,%dl
    7ca2:	c1 e8 10             	shr    $0x10,%eax
    7ca5:	ee                   	out    %al,(%dx)
	outb(0x1F6, (offset >> 24) | 0xE0);
    7ca6:	89 d8                	mov    %ebx,%eax
    7ca8:	b2 f6                	mov    $0xf6,%dl
    7caa:	c1 e8 18             	shr    $0x18,%eax
    7cad:	83 c8 e0             	or     $0xffffffe0,%eax
    7cb0:	ee                   	out    %al,(%dx)
    7cb1:	b0 20                	mov    $0x20,%al
    7cb3:	b2 f7                	mov    $0xf7,%dl
    7cb5:	ee                   	out    %al,(%dx)
	outb(0x1F7, 0x20);	// cmd 0x20 - read sectors

	// wait for disk to be ready
	waitdisk();
    7cb6:	e8 af ff ff ff       	call   7c6a <waitdisk>
}

static __inline void
insl(int port, void *addr, int cnt)
{
	__asm __volatile("cld\n\trepne\n\tinsl"			:
    7cbb:	8b 7d 08             	mov    0x8(%ebp),%edi
    7cbe:	b9 80 00 00 00       	mov    $0x80,%ecx
    7cc3:	ba f0 01 00 00       	mov    $0x1f0,%edx
    7cc8:	fc                   	cld    
    7cc9:	f2 6d                	repnz insl (%dx),%es:(%edi)

	// read a sector
	insl(0x1F0, dst, SECTSIZE/4);
}
    7ccb:	5b                   	pop    %ebx
    7ccc:	5f                   	pop    %edi
    7ccd:	5d                   	pop    %ebp
    7cce:	c3                   	ret    

00007ccf <readseg>:

// Read 'count' bytes at 'offset' from kernel into physical address 'pa'.
// Might copy more than asked
void
readseg(uint32_t pa, uint32_t count, uint32_t offset)
{
    7ccf:	55                   	push   %ebp
    7cd0:	89 e5                	mov    %esp,%ebp
    7cd2:	57                   	push   %edi
    7cd3:	56                   	push   %esi

	// round down to sector boundary
	pa &= ~(SECTSIZE - 1);

	// translate from bytes to sectors, and kernel starts at sector 1
	offset = (offset / SECTSIZE) + 1;
    7cd4:	8b 7d 10             	mov    0x10(%ebp),%edi

// Read 'count' bytes at 'offset' from kernel into physical address 'pa'.
// Might copy more than asked
void
readseg(uint32_t pa, uint32_t count, uint32_t offset)
{
    7cd7:	53                   	push   %ebx
	uint32_t end_pa;

	end_pa = pa + count;
    7cd8:	8b 75 0c             	mov    0xc(%ebp),%esi

// Read 'count' bytes at 'offset' from kernel into physical address 'pa'.
// Might copy more than asked
void
readseg(uint32_t pa, uint32_t count, uint32_t offset)
{
    7cdb:	8b 5d 08             	mov    0x8(%ebp),%ebx

	// round down to sector boundary
	pa &= ~(SECTSIZE - 1);

	// translate from bytes to sectors, and kernel starts at sector 1
	offset = (offset / SECTSIZE) + 1;
    7cde:	c1 ef 09             	shr    $0x9,%edi
void
readseg(uint32_t pa, uint32_t count, uint32_t offset)
{
	uint32_t end_pa;

	end_pa = pa + count;
    7ce1:	01 de                	add    %ebx,%esi

	// round down to sector boundary
	pa &= ~(SECTSIZE - 1);

	// translate from bytes to sectors, and kernel starts at sector 1
	offset = (offset / SECTSIZE) + 1;
    7ce3:	47                   	inc    %edi
	uint32_t end_pa;

	end_pa = pa + count;

	// round down to sector boundary
	pa &= ~(SECTSIZE - 1);
    7ce4:	81 e3 00 fe ff ff    	and    $0xfffffe00,%ebx
	offset = (offset / SECTSIZE) + 1;

	// If this is too slow, we could read lots of sectors at a time.
	// We'd write more to memory than asked, but it doesn't matter --
	// we load in increasing order.
	while (pa < end_pa) {
    7cea:	39 f3                	cmp    %esi,%ebx
    7cec:	73 12                	jae    7d00 <readseg+0x31>
		// Since we haven't enabled paging yet and we're using
		// an identity segment mapping (see boot.S), we can
		// use physical addresses directly.  This won't be the
		// case once JOS enables the MMU.
		readsect((uint8_t*) pa, offset);
    7cee:	57                   	push   %edi
    7cef:	53                   	push   %ebx
		pa += SECTSIZE;
		offset++;
    7cf0:	47                   	inc    %edi
		// Since we haven't enabled paging yet and we're using
		// an identity segment mapping (see boot.S), we can
		// use physical addresses directly.  This won't be the
		// case once JOS enables the MMU.
		readsect((uint8_t*) pa, offset);
		pa += SECTSIZE;
    7cf1:	81 c3 00 02 00 00    	add    $0x200,%ebx
	while (pa < end_pa) {
		// Since we haven't enabled paging yet and we're using
		// an identity segment mapping (see boot.S), we can
		// use physical addresses directly.  This won't be the
		// case once JOS enables the MMU.
		readsect((uint8_t*) pa, offset);
    7cf7:	e8 80 ff ff ff       	call   7c7c <readsect>
		pa += SECTSIZE;
		offset++;
    7cfc:	58                   	pop    %eax
    7cfd:	5a                   	pop    %edx
    7cfe:	eb ea                	jmp    7cea <readseg+0x1b>
	}
}
    7d00:	8d 65 f4             	lea    -0xc(%ebp),%esp
    7d03:	5b                   	pop    %ebx
    7d04:	5e                   	pop    %esi
    7d05:	5f                   	pop    %edi
    7d06:	5d                   	pop    %ebp
    7d07:	c3                   	ret    

00007d08 <bootmain>:
void readsect(void*, uint32_t);
void readseg(uint32_t, uint32_t, uint32_t);

void
bootmain(void)
{
    7d08:	55                   	push   %ebp
    7d09:	89 e5                	mov    %esp,%ebp
    7d0b:	56                   	push   %esi
    7d0c:	53                   	push   %ebx
	struct Proghdr *ph, *eph;

	// read 1st page off disk
	readseg((uint32_t) ELFHDR, SECTSIZE*8, 0);
    7d0d:	6a 00                	push   $0x0
    7d0f:	68 00 10 00 00       	push   $0x1000
    7d14:	68 00 00 01 00       	push   $0x10000
    7d19:	e8 b1 ff ff ff       	call   7ccf <readseg>

	// is this a valid ELF?
	if (ELFHDR->e_magic != ELF_MAGIC)
    7d1e:	83 c4 0c             	add    $0xc,%esp
    7d21:	81 3d 00 00 01 00 7f 	cmpl   $0x464c457f,0x10000
    7d28:	45 4c 46 
    7d2b:	75 37                	jne    7d64 <bootmain+0x5c>
		goto bad;

	// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
    7d2d:	a1 1c 00 01 00       	mov    0x1001c,%eax
	eph = ph + ELFHDR->e_phnum;
    7d32:	0f b7 35 2c 00 01 00 	movzwl 0x1002c,%esi
	// is this a valid ELF?
	if (ELFHDR->e_magic != ELF_MAGIC)
		goto bad;

	// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
    7d39:	8d 98 00 00 01 00    	lea    0x10000(%eax),%ebx
	eph = ph + ELFHDR->e_phnum;
    7d3f:	c1 e6 05             	shl    $0x5,%esi
    7d42:	01 de                	add    %ebx,%esi
	for (; ph < eph; ph++)
    7d44:	39 f3                	cmp    %esi,%ebx
    7d46:	73 16                	jae    7d5e <bootmain+0x56>
		// p_pa is the load address of this segment (as well
		// as the physical address)
		readseg(ph->p_pa, ph->p_memsz, ph->p_offset);
    7d48:	ff 73 04             	pushl  0x4(%ebx)
    7d4b:	ff 73 14             	pushl  0x14(%ebx)
		goto bad;

	// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
	eph = ph + ELFHDR->e_phnum;
	for (; ph < eph; ph++)
    7d4e:	83 c3 20             	add    $0x20,%ebx
		// p_pa is the load address of this segment (as well
		// as the physical address)
		readseg(ph->p_pa, ph->p_memsz, ph->p_offset);
    7d51:	ff 73 ec             	pushl  -0x14(%ebx)
    7d54:	e8 76 ff ff ff       	call   7ccf <readseg>
		goto bad;

	// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
	eph = ph + ELFHDR->e_phnum;
	for (; ph < eph; ph++)
    7d59:	83 c4 0c             	add    $0xc,%esp
    7d5c:	eb e6                	jmp    7d44 <bootmain+0x3c>
		// as the physical address)
		readseg(ph->p_pa, ph->p_memsz, ph->p_offset);

	// call the entry point from the ELF header
	// note: does not return!
	((void (*)(void)) (ELFHDR->e_entry))();
    7d5e:	ff 15 18 00 01 00    	call   *0x10018
}

static __inline void
outw(int port, uint16_t data)
{
	__asm __volatile("outw %0,%w1" : : "a" (data), "d" (port));
    7d64:	ba 00 8a 00 00       	mov    $0x8a00,%edx
    7d69:	b8 00 8a ff ff       	mov    $0xffff8a00,%eax
    7d6e:	66 ef                	out    %ax,(%dx)
    7d70:	b8 00 8e ff ff       	mov    $0xffff8e00,%eax
    7d75:	66 ef                	out    %ax,(%dx)

bad:
	outw(0x8A00, 0x8A00);
	outw(0x8A00, 0x8E00);
	while (1)
		/* do nothing */;
    7d77:	eb fe                	jmp    7d77 <bootmain+0x6f>
