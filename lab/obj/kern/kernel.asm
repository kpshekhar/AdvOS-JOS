
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 90 11 00       	mov    $0x119000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 90 11 f0       	mov    $0xf0119000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 10 df 17 f0       	mov    $0xf017df10,%eax
f010004b:	2d ae cf 17 f0       	sub    $0xf017cfae,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 ae cf 17 f0       	push   $0xf017cfae
f0100058:	e8 8b 42 00 00       	call   f01042e8 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 9a 04 00 00       	call   f01004fc <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 c0 47 10 f0       	push   $0xf01047c0
f010006f:	e8 ac 30 00 00       	call   f0103120 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 05 11 00 00       	call   f010117e <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 d5 2a 00 00       	call   f0102b53 <env_init>
	trap_init();
f010007e:	e8 0e 31 00 00       	call   f0103191 <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 fa 1c 13 f0       	push   $0xf0131cfa
f010008d:	e8 75 2c 00 00       	call   f0102d07 <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 30 d2 17 f0    	pushl  0xf017d230
f010009b:	e8 bd 2f 00 00       	call   f010305d <env_run>

f01000a0 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000a0:	55                   	push   %ebp
f01000a1:	89 e5                	mov    %esp,%ebp
f01000a3:	56                   	push   %esi
f01000a4:	53                   	push   %ebx
f01000a5:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000a8:	83 3d 00 df 17 f0 00 	cmpl   $0x0,0xf017df00
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 00 df 17 f0    	mov    %esi,0xf017df00

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000b7:	fa                   	cli    
f01000b8:	fc                   	cld    

	va_start(ap, fmt);
f01000b9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000bc:	83 ec 04             	sub    $0x4,%esp
f01000bf:	ff 75 0c             	pushl  0xc(%ebp)
f01000c2:	ff 75 08             	pushl  0x8(%ebp)
f01000c5:	68 db 47 10 f0       	push   $0xf01047db
f01000ca:	e8 51 30 00 00       	call   f0103120 <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 21 30 00 00       	call   f01030fa <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 5c 5e 10 f0 	movl   $0xf0105e5c,(%esp)
f01000e0:	e8 3b 30 00 00       	call   f0103120 <cprintf>
	va_end(ap);
f01000e5:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e8:	83 ec 0c             	sub    $0xc,%esp
f01000eb:	6a 00                	push   $0x0
f01000ed:	e8 9c 06 00 00       	call   f010078e <monitor>
f01000f2:	83 c4 10             	add    $0x10,%esp
f01000f5:	eb f1                	jmp    f01000e8 <_panic+0x48>

f01000f7 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f7:	55                   	push   %ebp
f01000f8:	89 e5                	mov    %esp,%ebp
f01000fa:	53                   	push   %ebx
f01000fb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fe:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100101:	ff 75 0c             	pushl  0xc(%ebp)
f0100104:	ff 75 08             	pushl  0x8(%ebp)
f0100107:	68 f3 47 10 f0       	push   $0xf01047f3
f010010c:	e8 0f 30 00 00       	call   f0103120 <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 dd 2f 00 00       	call   f01030fa <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 5c 5e 10 f0 	movl   $0xf0105e5c,(%esp)
f0100124:	e8 f7 2f 00 00       	call   f0103120 <cprintf>
	va_end(ap);
f0100129:	83 c4 10             	add    $0x10,%esp
}
f010012c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010012f:	c9                   	leave  
f0100130:	c3                   	ret    

f0100131 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100131:	55                   	push   %ebp
f0100132:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100134:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100139:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010013a:	a8 01                	test   $0x1,%al
f010013c:	74 08                	je     f0100146 <serial_proc_data+0x15>
f010013e:	b2 f8                	mov    $0xf8,%dl
f0100140:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100141:	0f b6 c0             	movzbl %al,%eax
f0100144:	eb 05                	jmp    f010014b <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100146:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010014b:	5d                   	pop    %ebp
f010014c:	c3                   	ret    

f010014d <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010014d:	55                   	push   %ebp
f010014e:	89 e5                	mov    %esp,%ebp
f0100150:	53                   	push   %ebx
f0100151:	83 ec 04             	sub    $0x4,%esp
f0100154:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100156:	eb 2a                	jmp    f0100182 <cons_intr+0x35>
		if (c == 0)
f0100158:	85 d2                	test   %edx,%edx
f010015a:	74 26                	je     f0100182 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010015c:	a1 04 d2 17 f0       	mov    0xf017d204,%eax
f0100161:	8d 48 01             	lea    0x1(%eax),%ecx
f0100164:	89 0d 04 d2 17 f0    	mov    %ecx,0xf017d204
f010016a:	88 90 00 d0 17 f0    	mov    %dl,-0xfe83000(%eax)
		if (cons.wpos == CONSBUFSIZE)
f0100170:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100176:	75 0a                	jne    f0100182 <cons_intr+0x35>
			cons.wpos = 0;
f0100178:	c7 05 04 d2 17 f0 00 	movl   $0x0,0xf017d204
f010017f:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100182:	ff d3                	call   *%ebx
f0100184:	89 c2                	mov    %eax,%edx
f0100186:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100189:	75 cd                	jne    f0100158 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010018b:	83 c4 04             	add    $0x4,%esp
f010018e:	5b                   	pop    %ebx
f010018f:	5d                   	pop    %ebp
f0100190:	c3                   	ret    

f0100191 <kbd_proc_data>:
f0100191:	ba 64 00 00 00       	mov    $0x64,%edx
f0100196:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100197:	a8 01                	test   $0x1,%al
f0100199:	0f 84 f0 00 00 00    	je     f010028f <kbd_proc_data+0xfe>
f010019f:	b2 60                	mov    $0x60,%dl
f01001a1:	ec                   	in     (%dx),%al
f01001a2:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001a4:	3c e0                	cmp    $0xe0,%al
f01001a6:	75 0d                	jne    f01001b5 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f01001a8:	83 0d c0 cf 17 f0 40 	orl    $0x40,0xf017cfc0
		return 0;
f01001af:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001b4:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001b5:	55                   	push   %ebp
f01001b6:	89 e5                	mov    %esp,%ebp
f01001b8:	53                   	push   %ebx
f01001b9:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001bc:	84 c0                	test   %al,%al
f01001be:	79 36                	jns    f01001f6 <kbd_proc_data+0x65>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001c0:	8b 0d c0 cf 17 f0    	mov    0xf017cfc0,%ecx
f01001c6:	89 cb                	mov    %ecx,%ebx
f01001c8:	83 e3 40             	and    $0x40,%ebx
f01001cb:	83 e0 7f             	and    $0x7f,%eax
f01001ce:	85 db                	test   %ebx,%ebx
f01001d0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001d3:	0f b6 d2             	movzbl %dl,%edx
f01001d6:	0f b6 82 80 49 10 f0 	movzbl -0xfefb680(%edx),%eax
f01001dd:	83 c8 40             	or     $0x40,%eax
f01001e0:	0f b6 c0             	movzbl %al,%eax
f01001e3:	f7 d0                	not    %eax
f01001e5:	21 c8                	and    %ecx,%eax
f01001e7:	a3 c0 cf 17 f0       	mov    %eax,0xf017cfc0
		return 0;
f01001ec:	b8 00 00 00 00       	mov    $0x0,%eax
f01001f1:	e9 a1 00 00 00       	jmp    f0100297 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001f6:	8b 0d c0 cf 17 f0    	mov    0xf017cfc0,%ecx
f01001fc:	f6 c1 40             	test   $0x40,%cl
f01001ff:	74 0e                	je     f010020f <kbd_proc_data+0x7e>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100201:	83 c8 80             	or     $0xffffff80,%eax
f0100204:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100206:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100209:	89 0d c0 cf 17 f0    	mov    %ecx,0xf017cfc0
	}

	shift |= shiftcode[data];
f010020f:	0f b6 c2             	movzbl %dl,%eax
f0100212:	0f b6 90 80 49 10 f0 	movzbl -0xfefb680(%eax),%edx
f0100219:	0b 15 c0 cf 17 f0    	or     0xf017cfc0,%edx
	shift ^= togglecode[data];
f010021f:	0f b6 88 80 48 10 f0 	movzbl -0xfefb780(%eax),%ecx
f0100226:	31 ca                	xor    %ecx,%edx
f0100228:	89 15 c0 cf 17 f0    	mov    %edx,0xf017cfc0

	c = charcode[shift & (CTL | SHIFT)][data];
f010022e:	89 d1                	mov    %edx,%ecx
f0100230:	83 e1 03             	and    $0x3,%ecx
f0100233:	8b 0c 8d 40 48 10 f0 	mov    -0xfefb7c0(,%ecx,4),%ecx
f010023a:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f010023e:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f0100241:	f6 c2 08             	test   $0x8,%dl
f0100244:	74 1b                	je     f0100261 <kbd_proc_data+0xd0>
		if ('a' <= c && c <= 'z')
f0100246:	89 d8                	mov    %ebx,%eax
f0100248:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010024b:	83 f9 19             	cmp    $0x19,%ecx
f010024e:	77 05                	ja     f0100255 <kbd_proc_data+0xc4>
			c += 'A' - 'a';
f0100250:	83 eb 20             	sub    $0x20,%ebx
f0100253:	eb 0c                	jmp    f0100261 <kbd_proc_data+0xd0>
		else if ('A' <= c && c <= 'Z')
f0100255:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f0100258:	8d 4b 20             	lea    0x20(%ebx),%ecx
f010025b:	83 f8 19             	cmp    $0x19,%eax
f010025e:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100261:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100267:	75 2c                	jne    f0100295 <kbd_proc_data+0x104>
f0100269:	f7 d2                	not    %edx
f010026b:	f6 c2 06             	test   $0x6,%dl
f010026e:	75 25                	jne    f0100295 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f0100270:	83 ec 0c             	sub    $0xc,%esp
f0100273:	68 0d 48 10 f0       	push   $0xf010480d
f0100278:	e8 a3 2e 00 00       	call   f0103120 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010027d:	ba 92 00 00 00       	mov    $0x92,%edx
f0100282:	b8 03 00 00 00       	mov    $0x3,%eax
f0100287:	ee                   	out    %al,(%dx)
f0100288:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f010028b:	89 d8                	mov    %ebx,%eax
f010028d:	eb 08                	jmp    f0100297 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010028f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100294:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100295:	89 d8                	mov    %ebx,%eax
}
f0100297:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010029a:	c9                   	leave  
f010029b:	c3                   	ret    

f010029c <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010029c:	55                   	push   %ebp
f010029d:	89 e5                	mov    %esp,%ebp
f010029f:	57                   	push   %edi
f01002a0:	56                   	push   %esi
f01002a1:	53                   	push   %ebx
f01002a2:	83 ec 1c             	sub    $0x1c,%esp
f01002a5:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a7:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002ac:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002b1:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b6:	eb 09                	jmp    f01002c1 <cons_putc+0x25>
f01002b8:	89 ca                	mov    %ecx,%edx
f01002ba:	ec                   	in     (%dx),%al
f01002bb:	ec                   	in     (%dx),%al
f01002bc:	ec                   	in     (%dx),%al
f01002bd:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002be:	83 c3 01             	add    $0x1,%ebx
f01002c1:	89 f2                	mov    %esi,%edx
f01002c3:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002c4:	a8 20                	test   $0x20,%al
f01002c6:	75 08                	jne    f01002d0 <cons_putc+0x34>
f01002c8:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002ce:	7e e8                	jle    f01002b8 <cons_putc+0x1c>
f01002d0:	89 f8                	mov    %edi,%eax
f01002d2:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d5:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002da:	89 f8                	mov    %edi,%eax
f01002dc:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002dd:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002e2:	be 79 03 00 00       	mov    $0x379,%esi
f01002e7:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002ec:	eb 09                	jmp    f01002f7 <cons_putc+0x5b>
f01002ee:	89 ca                	mov    %ecx,%edx
f01002f0:	ec                   	in     (%dx),%al
f01002f1:	ec                   	in     (%dx),%al
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	ec                   	in     (%dx),%al
f01002f4:	83 c3 01             	add    $0x1,%ebx
f01002f7:	89 f2                	mov    %esi,%edx
f01002f9:	ec                   	in     (%dx),%al
f01002fa:	84 c0                	test   %al,%al
f01002fc:	78 08                	js     f0100306 <cons_putc+0x6a>
f01002fe:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100304:	7e e8                	jle    f01002ee <cons_putc+0x52>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100306:	ba 78 03 00 00       	mov    $0x378,%edx
f010030b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010030f:	ee                   	out    %al,(%dx)
f0100310:	b2 7a                	mov    $0x7a,%dl
f0100312:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100317:	ee                   	out    %al,(%dx)
f0100318:	b8 08 00 00 00       	mov    $0x8,%eax
f010031d:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010031e:	89 fa                	mov    %edi,%edx
f0100320:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100326:	89 f8                	mov    %edi,%eax
f0100328:	80 cc 07             	or     $0x7,%ah
f010032b:	85 d2                	test   %edx,%edx
f010032d:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100330:	89 f8                	mov    %edi,%eax
f0100332:	0f b6 c0             	movzbl %al,%eax
f0100335:	83 f8 09             	cmp    $0x9,%eax
f0100338:	74 74                	je     f01003ae <cons_putc+0x112>
f010033a:	83 f8 09             	cmp    $0x9,%eax
f010033d:	7f 0a                	jg     f0100349 <cons_putc+0xad>
f010033f:	83 f8 08             	cmp    $0x8,%eax
f0100342:	74 14                	je     f0100358 <cons_putc+0xbc>
f0100344:	e9 99 00 00 00       	jmp    f01003e2 <cons_putc+0x146>
f0100349:	83 f8 0a             	cmp    $0xa,%eax
f010034c:	74 3a                	je     f0100388 <cons_putc+0xec>
f010034e:	83 f8 0d             	cmp    $0xd,%eax
f0100351:	74 3d                	je     f0100390 <cons_putc+0xf4>
f0100353:	e9 8a 00 00 00       	jmp    f01003e2 <cons_putc+0x146>
	case '\b':
		if (crt_pos > 0) {
f0100358:	0f b7 05 08 d2 17 f0 	movzwl 0xf017d208,%eax
f010035f:	66 85 c0             	test   %ax,%ax
f0100362:	0f 84 e6 00 00 00    	je     f010044e <cons_putc+0x1b2>
			crt_pos--;
f0100368:	83 e8 01             	sub    $0x1,%eax
f010036b:	66 a3 08 d2 17 f0    	mov    %ax,0xf017d208
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100371:	0f b7 c0             	movzwl %ax,%eax
f0100374:	66 81 e7 00 ff       	and    $0xff00,%di
f0100379:	83 cf 20             	or     $0x20,%edi
f010037c:	8b 15 0c d2 17 f0    	mov    0xf017d20c,%edx
f0100382:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100386:	eb 78                	jmp    f0100400 <cons_putc+0x164>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100388:	66 83 05 08 d2 17 f0 	addw   $0x50,0xf017d208
f010038f:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100390:	0f b7 05 08 d2 17 f0 	movzwl 0xf017d208,%eax
f0100397:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010039d:	c1 e8 16             	shr    $0x16,%eax
f01003a0:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003a3:	c1 e0 04             	shl    $0x4,%eax
f01003a6:	66 a3 08 d2 17 f0    	mov    %ax,0xf017d208
f01003ac:	eb 52                	jmp    f0100400 <cons_putc+0x164>
		break;
	case '\t':
		cons_putc(' ');
f01003ae:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b3:	e8 e4 fe ff ff       	call   f010029c <cons_putc>
		cons_putc(' ');
f01003b8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003bd:	e8 da fe ff ff       	call   f010029c <cons_putc>
		cons_putc(' ');
f01003c2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c7:	e8 d0 fe ff ff       	call   f010029c <cons_putc>
		cons_putc(' ');
f01003cc:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d1:	e8 c6 fe ff ff       	call   f010029c <cons_putc>
		cons_putc(' ');
f01003d6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003db:	e8 bc fe ff ff       	call   f010029c <cons_putc>
f01003e0:	eb 1e                	jmp    f0100400 <cons_putc+0x164>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003e2:	0f b7 05 08 d2 17 f0 	movzwl 0xf017d208,%eax
f01003e9:	8d 50 01             	lea    0x1(%eax),%edx
f01003ec:	66 89 15 08 d2 17 f0 	mov    %dx,0xf017d208
f01003f3:	0f b7 c0             	movzwl %ax,%eax
f01003f6:	8b 15 0c d2 17 f0    	mov    0xf017d20c,%edx
f01003fc:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100400:	66 81 3d 08 d2 17 f0 	cmpw   $0x7cf,0xf017d208
f0100407:	cf 07 
f0100409:	76 43                	jbe    f010044e <cons_putc+0x1b2>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010040b:	a1 0c d2 17 f0       	mov    0xf017d20c,%eax
f0100410:	83 ec 04             	sub    $0x4,%esp
f0100413:	68 00 0f 00 00       	push   $0xf00
f0100418:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041e:	52                   	push   %edx
f010041f:	50                   	push   %eax
f0100420:	e8 10 3f 00 00       	call   f0104335 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100425:	8b 15 0c d2 17 f0    	mov    0xf017d20c,%edx
f010042b:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100431:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100437:	83 c4 10             	add    $0x10,%esp
f010043a:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010043f:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100442:	39 d0                	cmp    %edx,%eax
f0100444:	75 f4                	jne    f010043a <cons_putc+0x19e>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100446:	66 83 2d 08 d2 17 f0 	subw   $0x50,0xf017d208
f010044d:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044e:	8b 0d 10 d2 17 f0    	mov    0xf017d210,%ecx
f0100454:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100459:	89 ca                	mov    %ecx,%edx
f010045b:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010045c:	0f b7 1d 08 d2 17 f0 	movzwl 0xf017d208,%ebx
f0100463:	8d 71 01             	lea    0x1(%ecx),%esi
f0100466:	89 d8                	mov    %ebx,%eax
f0100468:	66 c1 e8 08          	shr    $0x8,%ax
f010046c:	89 f2                	mov    %esi,%edx
f010046e:	ee                   	out    %al,(%dx)
f010046f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100474:	89 ca                	mov    %ecx,%edx
f0100476:	ee                   	out    %al,(%dx)
f0100477:	89 d8                	mov    %ebx,%eax
f0100479:	89 f2                	mov    %esi,%edx
f010047b:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010047c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010047f:	5b                   	pop    %ebx
f0100480:	5e                   	pop    %esi
f0100481:	5f                   	pop    %edi
f0100482:	5d                   	pop    %ebp
f0100483:	c3                   	ret    

f0100484 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100484:	80 3d 14 d2 17 f0 00 	cmpb   $0x0,0xf017d214
f010048b:	74 11                	je     f010049e <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010048d:	55                   	push   %ebp
f010048e:	89 e5                	mov    %esp,%ebp
f0100490:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100493:	b8 31 01 10 f0       	mov    $0xf0100131,%eax
f0100498:	e8 b0 fc ff ff       	call   f010014d <cons_intr>
}
f010049d:	c9                   	leave  
f010049e:	f3 c3                	repz ret 

f01004a0 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004a0:	55                   	push   %ebp
f01004a1:	89 e5                	mov    %esp,%ebp
f01004a3:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a6:	b8 91 01 10 f0       	mov    $0xf0100191,%eax
f01004ab:	e8 9d fc ff ff       	call   f010014d <cons_intr>
}
f01004b0:	c9                   	leave  
f01004b1:	c3                   	ret    

f01004b2 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004b2:	55                   	push   %ebp
f01004b3:	89 e5                	mov    %esp,%ebp
f01004b5:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004b8:	e8 c7 ff ff ff       	call   f0100484 <serial_intr>
	kbd_intr();
f01004bd:	e8 de ff ff ff       	call   f01004a0 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004c2:	a1 00 d2 17 f0       	mov    0xf017d200,%eax
f01004c7:	3b 05 04 d2 17 f0    	cmp    0xf017d204,%eax
f01004cd:	74 26                	je     f01004f5 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004cf:	8d 50 01             	lea    0x1(%eax),%edx
f01004d2:	89 15 00 d2 17 f0    	mov    %edx,0xf017d200
f01004d8:	0f b6 88 00 d0 17 f0 	movzbl -0xfe83000(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004df:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004e1:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004e7:	75 11                	jne    f01004fa <cons_getc+0x48>
			cons.rpos = 0;
f01004e9:	c7 05 00 d2 17 f0 00 	movl   $0x0,0xf017d200
f01004f0:	00 00 00 
f01004f3:	eb 05                	jmp    f01004fa <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004fa:	c9                   	leave  
f01004fb:	c3                   	ret    

f01004fc <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004fc:	55                   	push   %ebp
f01004fd:	89 e5                	mov    %esp,%ebp
f01004ff:	57                   	push   %edi
f0100500:	56                   	push   %esi
f0100501:	53                   	push   %ebx
f0100502:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100505:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010050c:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100513:	5a a5 
	if (*cp != 0xA55A) {
f0100515:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010051c:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100520:	74 11                	je     f0100533 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100522:	c7 05 10 d2 17 f0 b4 	movl   $0x3b4,0xf017d210
f0100529:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010052c:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100531:	eb 16                	jmp    f0100549 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100533:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010053a:	c7 05 10 d2 17 f0 d4 	movl   $0x3d4,0xf017d210
f0100541:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100544:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100549:	8b 3d 10 d2 17 f0    	mov    0xf017d210,%edi
f010054f:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100554:	89 fa                	mov    %edi,%edx
f0100556:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100557:	8d 4f 01             	lea    0x1(%edi),%ecx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010055a:	89 ca                	mov    %ecx,%edx
f010055c:	ec                   	in     (%dx),%al
f010055d:	0f b6 c0             	movzbl %al,%eax
f0100560:	c1 e0 08             	shl    $0x8,%eax
f0100563:	89 c3                	mov    %eax,%ebx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100565:	b8 0f 00 00 00       	mov    $0xf,%eax
f010056a:	89 fa                	mov    %edi,%edx
f010056c:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056d:	89 ca                	mov    %ecx,%edx
f010056f:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100570:	89 35 0c d2 17 f0    	mov    %esi,0xf017d20c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100576:	0f b6 c8             	movzbl %al,%ecx
f0100579:	89 d8                	mov    %ebx,%eax
f010057b:	09 c8                	or     %ecx,%eax

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f010057d:	66 a3 08 d2 17 f0    	mov    %ax,0xf017d208
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100583:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f0100588:	b8 00 00 00 00       	mov    $0x0,%eax
f010058d:	89 da                	mov    %ebx,%edx
f010058f:	ee                   	out    %al,(%dx)
f0100590:	b2 fb                	mov    $0xfb,%dl
f0100592:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100597:	ee                   	out    %al,(%dx)
f0100598:	be f8 03 00 00       	mov    $0x3f8,%esi
f010059d:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005a2:	89 f2                	mov    %esi,%edx
f01005a4:	ee                   	out    %al,(%dx)
f01005a5:	b2 f9                	mov    $0xf9,%dl
f01005a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ac:	ee                   	out    %al,(%dx)
f01005ad:	b2 fb                	mov    $0xfb,%dl
f01005af:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b4:	ee                   	out    %al,(%dx)
f01005b5:	b2 fc                	mov    $0xfc,%dl
f01005b7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005bc:	ee                   	out    %al,(%dx)
f01005bd:	b2 f9                	mov    $0xf9,%dl
f01005bf:	b8 01 00 00 00       	mov    $0x1,%eax
f01005c4:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c5:	b2 fd                	mov    $0xfd,%dl
f01005c7:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005c8:	3c ff                	cmp    $0xff,%al
f01005ca:	0f 95 c1             	setne  %cl
f01005cd:	88 0d 14 d2 17 f0    	mov    %cl,0xf017d214
f01005d3:	89 da                	mov    %ebx,%edx
f01005d5:	ec                   	in     (%dx),%al
f01005d6:	89 f2                	mov    %esi,%edx
f01005d8:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005d9:	84 c9                	test   %cl,%cl
f01005db:	75 10                	jne    f01005ed <cons_init+0xf1>
		cprintf("Serial port does not exist!\n");
f01005dd:	83 ec 0c             	sub    $0xc,%esp
f01005e0:	68 19 48 10 f0       	push   $0xf0104819
f01005e5:	e8 36 2b 00 00       	call   f0103120 <cprintf>
f01005ea:	83 c4 10             	add    $0x10,%esp
}
f01005ed:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005f0:	5b                   	pop    %ebx
f01005f1:	5e                   	pop    %esi
f01005f2:	5f                   	pop    %edi
f01005f3:	5d                   	pop    %ebp
f01005f4:	c3                   	ret    

f01005f5 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005f5:	55                   	push   %ebp
f01005f6:	89 e5                	mov    %esp,%ebp
f01005f8:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01005fe:	e8 99 fc ff ff       	call   f010029c <cons_putc>
}
f0100603:	c9                   	leave  
f0100604:	c3                   	ret    

f0100605 <getchar>:

int
getchar(void)
{
f0100605:	55                   	push   %ebp
f0100606:	89 e5                	mov    %esp,%ebp
f0100608:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010060b:	e8 a2 fe ff ff       	call   f01004b2 <cons_getc>
f0100610:	85 c0                	test   %eax,%eax
f0100612:	74 f7                	je     f010060b <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100614:	c9                   	leave  
f0100615:	c3                   	ret    

f0100616 <iscons>:

int
iscons(int fdnum)
{
f0100616:	55                   	push   %ebp
f0100617:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100619:	b8 01 00 00 00       	mov    $0x1,%eax
f010061e:	5d                   	pop    %ebp
f010061f:	c3                   	ret    

f0100620 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100620:	55                   	push   %ebp
f0100621:	89 e5                	mov    %esp,%ebp
f0100623:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100626:	68 80 4a 10 f0       	push   $0xf0104a80
f010062b:	68 9e 4a 10 f0       	push   $0xf0104a9e
f0100630:	68 a3 4a 10 f0       	push   $0xf0104aa3
f0100635:	e8 e6 2a 00 00       	call   f0103120 <cprintf>
f010063a:	83 c4 0c             	add    $0xc,%esp
f010063d:	68 44 4b 10 f0       	push   $0xf0104b44
f0100642:	68 ac 4a 10 f0       	push   $0xf0104aac
f0100647:	68 a3 4a 10 f0       	push   $0xf0104aa3
f010064c:	e8 cf 2a 00 00       	call   f0103120 <cprintf>
f0100651:	83 c4 0c             	add    $0xc,%esp
f0100654:	68 b5 4a 10 f0       	push   $0xf0104ab5
f0100659:	68 d2 4a 10 f0       	push   $0xf0104ad2
f010065e:	68 a3 4a 10 f0       	push   $0xf0104aa3
f0100663:	e8 b8 2a 00 00       	call   f0103120 <cprintf>
	return 0;
}
f0100668:	b8 00 00 00 00       	mov    $0x0,%eax
f010066d:	c9                   	leave  
f010066e:	c3                   	ret    

f010066f <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010066f:	55                   	push   %ebp
f0100670:	89 e5                	mov    %esp,%ebp
f0100672:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100675:	68 dd 4a 10 f0       	push   $0xf0104add
f010067a:	e8 a1 2a 00 00       	call   f0103120 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010067f:	83 c4 08             	add    $0x8,%esp
f0100682:	68 0c 00 10 00       	push   $0x10000c
f0100687:	68 6c 4b 10 f0       	push   $0xf0104b6c
f010068c:	e8 8f 2a 00 00       	call   f0103120 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100691:	83 c4 0c             	add    $0xc,%esp
f0100694:	68 0c 00 10 00       	push   $0x10000c
f0100699:	68 0c 00 10 f0       	push   $0xf010000c
f010069e:	68 94 4b 10 f0       	push   $0xf0104b94
f01006a3:	e8 78 2a 00 00       	call   f0103120 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006a8:	83 c4 0c             	add    $0xc,%esp
f01006ab:	68 95 47 10 00       	push   $0x104795
f01006b0:	68 95 47 10 f0       	push   $0xf0104795
f01006b5:	68 b8 4b 10 f0       	push   $0xf0104bb8
f01006ba:	e8 61 2a 00 00       	call   f0103120 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006bf:	83 c4 0c             	add    $0xc,%esp
f01006c2:	68 ae cf 17 00       	push   $0x17cfae
f01006c7:	68 ae cf 17 f0       	push   $0xf017cfae
f01006cc:	68 dc 4b 10 f0       	push   $0xf0104bdc
f01006d1:	e8 4a 2a 00 00       	call   f0103120 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006d6:	83 c4 0c             	add    $0xc,%esp
f01006d9:	68 10 df 17 00       	push   $0x17df10
f01006de:	68 10 df 17 f0       	push   $0xf017df10
f01006e3:	68 00 4c 10 f0       	push   $0xf0104c00
f01006e8:	e8 33 2a 00 00       	call   f0103120 <cprintf>
f01006ed:	b8 0f e3 17 f0       	mov    $0xf017e30f,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006f2:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006f7:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01006fa:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006ff:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100705:	85 c0                	test   %eax,%eax
f0100707:	0f 48 c2             	cmovs  %edx,%eax
f010070a:	c1 f8 0a             	sar    $0xa,%eax
f010070d:	50                   	push   %eax
f010070e:	68 24 4c 10 f0       	push   $0xf0104c24
f0100713:	e8 08 2a 00 00       	call   f0103120 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100718:	b8 00 00 00 00       	mov    $0x0,%eax
f010071d:	c9                   	leave  
f010071e:	c3                   	ret    

f010071f <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010071f:	55                   	push   %ebp
f0100720:	89 e5                	mov    %esp,%ebp
f0100722:	57                   	push   %edi
f0100723:	56                   	push   %esi
f0100724:	53                   	push   %ebx
f0100725:	83 ec 38             	sub    $0x38,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100728:	89 eb                	mov    %ebp,%ebx
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
f010072a:	68 f6 4a 10 f0       	push   $0xf0104af6
f010072f:	e8 ec 29 00 00       	call   f0103120 <cprintf>
	
	
	while (ebp){
f0100734:	83 c4 10             	add    $0x10,%esp
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
		debuginfo_eip(eip, &sym);
f0100737:	8d 7d d0             	lea    -0x30(%ebp),%edi
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f010073a:	eb 41                	jmp    f010077d <mon_backtrace+0x5e>
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
f010073c:	8b 73 04             	mov    0x4(%ebx),%esi
		debuginfo_eip(eip, &sym);
f010073f:	83 ec 08             	sub    $0x8,%esp
f0100742:	57                   	push   %edi
f0100743:	56                   	push   %esi
f0100744:	e8 45 31 00 00       	call   f010388e <debuginfo_eip>
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n %s:%d: %.*s+%d\n",ebp,eip,
f0100749:	89 f0                	mov    %esi,%eax
f010074b:	2b 45 e0             	sub    -0x20(%ebp),%eax
f010074e:	89 04 24             	mov    %eax,(%esp)
f0100751:	ff 75 d8             	pushl  -0x28(%ebp)
f0100754:	ff 75 dc             	pushl  -0x24(%ebp)
f0100757:	ff 75 d4             	pushl  -0x2c(%ebp)
f010075a:	ff 75 d0             	pushl  -0x30(%ebp)
f010075d:	ff 73 18             	pushl  0x18(%ebx)
f0100760:	ff 73 14             	pushl  0x14(%ebx)
f0100763:	ff 73 10             	pushl  0x10(%ebx)
f0100766:	ff 73 0c             	pushl  0xc(%ebx)
f0100769:	ff 73 08             	pushl  0x8(%ebx)
f010076c:	56                   	push   %esi
f010076d:	53                   	push   %ebx
f010076e:	68 50 4c 10 f0       	push   $0xf0104c50
f0100773:	e8 a8 29 00 00       	call   f0103120 <cprintf>
		*((uint32_t *)ebp + 6), sym.eip_file,
			      sym.eip_line,
			      sym.eip_fn_namelen,
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
f0100778:	8b 1b                	mov    (%ebx),%ebx
f010077a:	83 c4 40             	add    $0x40,%esp
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f010077d:	85 db                	test   %ebx,%ebx
f010077f:	75 bb                	jne    f010073c <mon_backtrace+0x1d>
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
	}
	return 0;
}
f0100781:	b8 00 00 00 00       	mov    $0x0,%eax
f0100786:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100789:	5b                   	pop    %ebx
f010078a:	5e                   	pop    %esi
f010078b:	5f                   	pop    %edi
f010078c:	5d                   	pop    %ebp
f010078d:	c3                   	ret    

f010078e <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010078e:	55                   	push   %ebp
f010078f:	89 e5                	mov    %esp,%ebp
f0100791:	57                   	push   %edi
f0100792:	56                   	push   %esi
f0100793:	53                   	push   %ebx
f0100794:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100797:	68 94 4c 10 f0       	push   $0xf0104c94
f010079c:	e8 7f 29 00 00       	call   f0103120 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007a1:	c7 04 24 b8 4c 10 f0 	movl   $0xf0104cb8,(%esp)
f01007a8:	e8 73 29 00 00       	call   f0103120 <cprintf>

	if (tf != NULL)
f01007ad:	83 c4 10             	add    $0x10,%esp
f01007b0:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01007b4:	74 0e                	je     f01007c4 <monitor+0x36>
		print_trapframe(tf);
f01007b6:	83 ec 0c             	sub    $0xc,%esp
f01007b9:	ff 75 08             	pushl  0x8(%ebp)
f01007bc:	e8 ff 2a 00 00       	call   f01032c0 <print_trapframe>
f01007c1:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01007c4:	83 ec 0c             	sub    $0xc,%esp
f01007c7:	68 08 4b 10 f0       	push   $0xf0104b08
f01007cc:	e8 c0 38 00 00       	call   f0104091 <readline>
f01007d1:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007d3:	83 c4 10             	add    $0x10,%esp
f01007d6:	85 c0                	test   %eax,%eax
f01007d8:	74 ea                	je     f01007c4 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007da:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007e1:	be 00 00 00 00       	mov    $0x0,%esi
f01007e6:	eb 0a                	jmp    f01007f2 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007e8:	c6 03 00             	movb   $0x0,(%ebx)
f01007eb:	89 f7                	mov    %esi,%edi
f01007ed:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007f0:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007f2:	0f b6 03             	movzbl (%ebx),%eax
f01007f5:	84 c0                	test   %al,%al
f01007f7:	74 63                	je     f010085c <monitor+0xce>
f01007f9:	83 ec 08             	sub    $0x8,%esp
f01007fc:	0f be c0             	movsbl %al,%eax
f01007ff:	50                   	push   %eax
f0100800:	68 0c 4b 10 f0       	push   $0xf0104b0c
f0100805:	e8 a1 3a 00 00       	call   f01042ab <strchr>
f010080a:	83 c4 10             	add    $0x10,%esp
f010080d:	85 c0                	test   %eax,%eax
f010080f:	75 d7                	jne    f01007e8 <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f0100811:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100814:	74 46                	je     f010085c <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100816:	83 fe 0f             	cmp    $0xf,%esi
f0100819:	75 14                	jne    f010082f <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010081b:	83 ec 08             	sub    $0x8,%esp
f010081e:	6a 10                	push   $0x10
f0100820:	68 11 4b 10 f0       	push   $0xf0104b11
f0100825:	e8 f6 28 00 00       	call   f0103120 <cprintf>
f010082a:	83 c4 10             	add    $0x10,%esp
f010082d:	eb 95                	jmp    f01007c4 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f010082f:	8d 7e 01             	lea    0x1(%esi),%edi
f0100832:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100836:	eb 03                	jmp    f010083b <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100838:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010083b:	0f b6 03             	movzbl (%ebx),%eax
f010083e:	84 c0                	test   %al,%al
f0100840:	74 ae                	je     f01007f0 <monitor+0x62>
f0100842:	83 ec 08             	sub    $0x8,%esp
f0100845:	0f be c0             	movsbl %al,%eax
f0100848:	50                   	push   %eax
f0100849:	68 0c 4b 10 f0       	push   $0xf0104b0c
f010084e:	e8 58 3a 00 00       	call   f01042ab <strchr>
f0100853:	83 c4 10             	add    $0x10,%esp
f0100856:	85 c0                	test   %eax,%eax
f0100858:	74 de                	je     f0100838 <monitor+0xaa>
f010085a:	eb 94                	jmp    f01007f0 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f010085c:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100863:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100864:	85 f6                	test   %esi,%esi
f0100866:	0f 84 58 ff ff ff    	je     f01007c4 <monitor+0x36>
f010086c:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100871:	83 ec 08             	sub    $0x8,%esp
f0100874:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100877:	ff 34 85 e0 4c 10 f0 	pushl  -0xfefb320(,%eax,4)
f010087e:	ff 75 a8             	pushl  -0x58(%ebp)
f0100881:	e8 c7 39 00 00       	call   f010424d <strcmp>
f0100886:	83 c4 10             	add    $0x10,%esp
f0100889:	85 c0                	test   %eax,%eax
f010088b:	75 22                	jne    f01008af <monitor+0x121>
			return commands[i].func(argc, argv, tf);
f010088d:	83 ec 04             	sub    $0x4,%esp
f0100890:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100893:	ff 75 08             	pushl  0x8(%ebp)
f0100896:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100899:	52                   	push   %edx
f010089a:	56                   	push   %esi
f010089b:	ff 14 85 e8 4c 10 f0 	call   *-0xfefb318(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008a2:	83 c4 10             	add    $0x10,%esp
f01008a5:	85 c0                	test   %eax,%eax
f01008a7:	0f 89 17 ff ff ff    	jns    f01007c4 <monitor+0x36>
f01008ad:	eb 20                	jmp    f01008cf <monitor+0x141>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008af:	83 c3 01             	add    $0x1,%ebx
f01008b2:	83 fb 03             	cmp    $0x3,%ebx
f01008b5:	75 ba                	jne    f0100871 <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008b7:	83 ec 08             	sub    $0x8,%esp
f01008ba:	ff 75 a8             	pushl  -0x58(%ebp)
f01008bd:	68 2e 4b 10 f0       	push   $0xf0104b2e
f01008c2:	e8 59 28 00 00       	call   f0103120 <cprintf>
f01008c7:	83 c4 10             	add    $0x10,%esp
f01008ca:	e9 f5 fe ff ff       	jmp    f01007c4 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008cf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008d2:	5b                   	pop    %ebx
f01008d3:	5e                   	pop    %esi
f01008d4:	5f                   	pop    %edi
f01008d5:	5d                   	pop    %ebp
f01008d6:	c3                   	ret    

f01008d7 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f01008d7:	89 d1                	mov    %edx,%ecx
f01008d9:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f01008dc:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f01008df:	a8 01                	test   $0x1,%al
f01008e1:	74 52                	je     f0100935 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f01008e3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01008e8:	89 c1                	mov    %eax,%ecx
f01008ea:	c1 e9 0c             	shr    $0xc,%ecx
f01008ed:	3b 0d 04 df 17 f0    	cmp    0xf017df04,%ecx
f01008f3:	72 1b                	jb     f0100910 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01008f5:	55                   	push   %ebp
f01008f6:	89 e5                	mov    %esp,%ebp
f01008f8:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01008fb:	50                   	push   %eax
f01008fc:	68 04 4d 10 f0       	push   $0xf0104d04
f0100901:	68 99 03 00 00       	push   $0x399
f0100906:	68 b5 55 10 f0       	push   $0xf01055b5
f010090b:	e8 90 f7 ff ff       	call   f01000a0 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100910:	c1 ea 0c             	shr    $0xc,%edx
f0100913:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100919:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100920:	89 c2                	mov    %eax,%edx
f0100922:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100925:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010092a:	85 d2                	test   %edx,%edx
f010092c:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100931:	0f 44 c2             	cmove  %edx,%eax
f0100934:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100935:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f010093a:	c3                   	ret    

f010093b <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f010093b:	83 3d 1c d2 17 f0 00 	cmpl   $0x0,0xf017d21c
f0100942:	75 11                	jne    f0100955 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE); // Roundup function rounds according to the given functions
f0100944:	ba 0f ef 17 f0       	mov    $0xf017ef0f,%edx
f0100949:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010094f:	89 15 1c d2 17 f0    	mov    %edx,0xf017d21c
	}
	
	if (n==0){
f0100955:	85 c0                	test   %eax,%eax
f0100957:	75 06                	jne    f010095f <boot_alloc+0x24>
	return nextfree;
f0100959:	a1 1c d2 17 f0       	mov    0xf017d21c,%eax
f010095e:	c3                   	ret    
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result  = nextfree;
f010095f:	8b 0d 1c d2 17 f0    	mov    0xf017d21c,%ecx
	nextfree += ROUNDUP(n,PGSIZE);
f0100965:	05 ff 0f 00 00       	add    $0xfff,%eax
f010096a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010096f:	8d 14 01             	lea    (%ecx,%eax,1),%edx
f0100972:	89 15 1c d2 17 f0    	mov    %edx,0xf017d21c
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100978:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f010097e:	77 18                	ja     f0100998 <boot_alloc+0x5d>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100980:	55                   	push   %ebp
f0100981:	89 e5                	mov    %esp,%ebp
f0100983:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100986:	52                   	push   %edx
f0100987:	68 28 4d 10 f0       	push   $0xf0104d28
f010098c:	6a 6f                	push   $0x6f
f010098e:	68 b5 55 10 f0       	push   $0xf01055b5
f0100993:	e8 08 f7 ff ff       	call   f01000a0 <_panic>
	// LAB 2: Your code here.
	result  = nextfree;
	nextfree += ROUNDUP(n,PGSIZE);
	
	
	if ((PADDR(nextfree))>npages*PGSIZE){
f0100998:	a1 04 df 17 f0       	mov    0xf017df04,%eax
f010099d:	c1 e0 0c             	shl    $0xc,%eax
	return (physaddr_t)kva - KERNBASE;
f01009a0:	81 c2 00 00 00 10    	add    $0x10000000,%edx
		return 0;
	}
	return result;
f01009a6:	39 c2                	cmp    %eax,%edx
f01009a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01009ad:	0f 46 c1             	cmovbe %ecx,%eax
}
f01009b0:	c3                   	ret    

f01009b1 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009b1:	55                   	push   %ebp
f01009b2:	89 e5                	mov    %esp,%ebp
f01009b4:	57                   	push   %edi
f01009b5:	56                   	push   %esi
f01009b6:	53                   	push   %ebx
f01009b7:	83 ec 3c             	sub    $0x3c,%esp
f01009ba:	89 45 c0             	mov    %eax,-0x40(%ebp)
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009bd:	84 c0                	test   %al,%al
f01009bf:	0f 85 87 02 00 00    	jne    f0100c4c <check_page_free_list+0x29b>
f01009c5:	e9 94 02 00 00       	jmp    f0100c5e <check_page_free_list+0x2ad>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009ca:	83 ec 04             	sub    $0x4,%esp
f01009cd:	68 4c 4d 10 f0       	push   $0xf0104d4c
f01009d2:	68 d6 02 00 00       	push   $0x2d6
f01009d7:	68 b5 55 10 f0       	push   $0xf01055b5
f01009dc:	e8 bf f6 ff ff       	call   f01000a0 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f01009e1:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01009e4:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01009e7:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01009ea:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01009ed:	89 c2                	mov    %eax,%edx
f01009ef:	2b 15 0c df 17 f0    	sub    0xf017df0c,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f01009f5:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f01009fb:	0f 95 c2             	setne  %dl
f01009fe:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a01:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a05:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a07:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a0b:	8b 00                	mov    (%eax),%eax
f0100a0d:	85 c0                	test   %eax,%eax
f0100a0f:	75 dc                	jne    f01009ed <check_page_free_list+0x3c>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a11:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a14:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a1a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a1d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a20:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a22:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a25:	a3 24 d2 17 f0       	mov    %eax,0xf017d224
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a2a:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a2f:	8b 1d 24 d2 17 f0    	mov    0xf017d224,%ebx
f0100a35:	eb 53                	jmp    f0100a8a <check_page_free_list+0xd9>
f0100a37:	89 d8                	mov    %ebx,%eax
f0100a39:	2b 05 0c df 17 f0    	sub    0xf017df0c,%eax
f0100a3f:	c1 f8 03             	sar    $0x3,%eax
f0100a42:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a45:	89 c2                	mov    %eax,%edx
f0100a47:	c1 ea 16             	shr    $0x16,%edx
f0100a4a:	39 f2                	cmp    %esi,%edx
f0100a4c:	73 3a                	jae    f0100a88 <check_page_free_list+0xd7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a4e:	89 c2                	mov    %eax,%edx
f0100a50:	c1 ea 0c             	shr    $0xc,%edx
f0100a53:	3b 15 04 df 17 f0    	cmp    0xf017df04,%edx
f0100a59:	72 12                	jb     f0100a6d <check_page_free_list+0xbc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a5b:	50                   	push   %eax
f0100a5c:	68 04 4d 10 f0       	push   $0xf0104d04
f0100a61:	6a 56                	push   $0x56
f0100a63:	68 c1 55 10 f0       	push   $0xf01055c1
f0100a68:	e8 33 f6 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a6d:	83 ec 04             	sub    $0x4,%esp
f0100a70:	68 80 00 00 00       	push   $0x80
f0100a75:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100a7a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a7f:	50                   	push   %eax
f0100a80:	e8 63 38 00 00       	call   f01042e8 <memset>
f0100a85:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a88:	8b 1b                	mov    (%ebx),%ebx
f0100a8a:	85 db                	test   %ebx,%ebx
f0100a8c:	75 a9                	jne    f0100a37 <check_page_free_list+0x86>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100a8e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a93:	e8 a3 fe ff ff       	call   f010093b <boot_alloc>
f0100a98:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a9b:	8b 15 24 d2 17 f0    	mov    0xf017d224,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100aa1:	8b 0d 0c df 17 f0    	mov    0xf017df0c,%ecx
		assert(pp < pages + npages);
f0100aa7:	a1 04 df 17 f0       	mov    0xf017df04,%eax
f0100aac:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100aaf:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ab2:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100ab5:	be 00 00 00 00       	mov    $0x0,%esi
f0100aba:	89 5d cc             	mov    %ebx,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100abd:	e9 33 01 00 00       	jmp    f0100bf5 <check_page_free_list+0x244>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ac2:	39 ca                	cmp    %ecx,%edx
f0100ac4:	73 19                	jae    f0100adf <check_page_free_list+0x12e>
f0100ac6:	68 cf 55 10 f0       	push   $0xf01055cf
f0100acb:	68 db 55 10 f0       	push   $0xf01055db
f0100ad0:	68 f0 02 00 00       	push   $0x2f0
f0100ad5:	68 b5 55 10 f0       	push   $0xf01055b5
f0100ada:	e8 c1 f5 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100adf:	39 fa                	cmp    %edi,%edx
f0100ae1:	72 19                	jb     f0100afc <check_page_free_list+0x14b>
f0100ae3:	68 f0 55 10 f0       	push   $0xf01055f0
f0100ae8:	68 db 55 10 f0       	push   $0xf01055db
f0100aed:	68 f1 02 00 00       	push   $0x2f1
f0100af2:	68 b5 55 10 f0       	push   $0xf01055b5
f0100af7:	e8 a4 f5 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100afc:	89 d0                	mov    %edx,%eax
f0100afe:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b01:	a8 07                	test   $0x7,%al
f0100b03:	74 19                	je     f0100b1e <check_page_free_list+0x16d>
f0100b05:	68 70 4d 10 f0       	push   $0xf0104d70
f0100b0a:	68 db 55 10 f0       	push   $0xf01055db
f0100b0f:	68 f2 02 00 00       	push   $0x2f2
f0100b14:	68 b5 55 10 f0       	push   $0xf01055b5
f0100b19:	e8 82 f5 ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b1e:	c1 f8 03             	sar    $0x3,%eax
f0100b21:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b24:	85 c0                	test   %eax,%eax
f0100b26:	75 19                	jne    f0100b41 <check_page_free_list+0x190>
f0100b28:	68 04 56 10 f0       	push   $0xf0105604
f0100b2d:	68 db 55 10 f0       	push   $0xf01055db
f0100b32:	68 f5 02 00 00       	push   $0x2f5
f0100b37:	68 b5 55 10 f0       	push   $0xf01055b5
f0100b3c:	e8 5f f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b41:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b46:	75 19                	jne    f0100b61 <check_page_free_list+0x1b0>
f0100b48:	68 15 56 10 f0       	push   $0xf0105615
f0100b4d:	68 db 55 10 f0       	push   $0xf01055db
f0100b52:	68 f6 02 00 00       	push   $0x2f6
f0100b57:	68 b5 55 10 f0       	push   $0xf01055b5
f0100b5c:	e8 3f f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b61:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b66:	75 19                	jne    f0100b81 <check_page_free_list+0x1d0>
f0100b68:	68 a4 4d 10 f0       	push   $0xf0104da4
f0100b6d:	68 db 55 10 f0       	push   $0xf01055db
f0100b72:	68 f7 02 00 00       	push   $0x2f7
f0100b77:	68 b5 55 10 f0       	push   $0xf01055b5
f0100b7c:	e8 1f f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b81:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b86:	75 19                	jne    f0100ba1 <check_page_free_list+0x1f0>
f0100b88:	68 2e 56 10 f0       	push   $0xf010562e
f0100b8d:	68 db 55 10 f0       	push   $0xf01055db
f0100b92:	68 f8 02 00 00       	push   $0x2f8
f0100b97:	68 b5 55 10 f0       	push   $0xf01055b5
f0100b9c:	e8 ff f4 ff ff       	call   f01000a0 <_panic>
f0100ba1:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100ba4:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100ba9:	76 3f                	jbe    f0100bea <check_page_free_list+0x239>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bab:	89 c3                	mov    %eax,%ebx
f0100bad:	c1 eb 0c             	shr    $0xc,%ebx
f0100bb0:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f0100bb3:	77 12                	ja     f0100bc7 <check_page_free_list+0x216>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bb5:	50                   	push   %eax
f0100bb6:	68 04 4d 10 f0       	push   $0xf0104d04
f0100bbb:	6a 56                	push   $0x56
f0100bbd:	68 c1 55 10 f0       	push   $0xf01055c1
f0100bc2:	e8 d9 f4 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0100bc7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bcc:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100bcf:	76 1f                	jbe    f0100bf0 <check_page_free_list+0x23f>
f0100bd1:	68 c8 4d 10 f0       	push   $0xf0104dc8
f0100bd6:	68 db 55 10 f0       	push   $0xf01055db
f0100bdb:	68 f9 02 00 00       	push   $0x2f9
f0100be0:	68 b5 55 10 f0       	push   $0xf01055b5
f0100be5:	e8 b6 f4 ff ff       	call   f01000a0 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100bea:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0100bee:	eb 03                	jmp    f0100bf3 <check_page_free_list+0x242>
		else
			++nfree_extmem;
f0100bf0:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bf3:	8b 12                	mov    (%edx),%edx
f0100bf5:	85 d2                	test   %edx,%edx
f0100bf7:	0f 85 c5 fe ff ff    	jne    f0100ac2 <check_page_free_list+0x111>
f0100bfd:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c00:	85 db                	test   %ebx,%ebx
f0100c02:	7f 19                	jg     f0100c1d <check_page_free_list+0x26c>
f0100c04:	68 48 56 10 f0       	push   $0xf0105648
f0100c09:	68 db 55 10 f0       	push   $0xf01055db
f0100c0e:	68 01 03 00 00       	push   $0x301
f0100c13:	68 b5 55 10 f0       	push   $0xf01055b5
f0100c18:	e8 83 f4 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100c1d:	85 f6                	test   %esi,%esi
f0100c1f:	7f 19                	jg     f0100c3a <check_page_free_list+0x289>
f0100c21:	68 5a 56 10 f0       	push   $0xf010565a
f0100c26:	68 db 55 10 f0       	push   $0xf01055db
f0100c2b:	68 02 03 00 00       	push   $0x302
f0100c30:	68 b5 55 10 f0       	push   $0xf01055b5
f0100c35:	e8 66 f4 ff ff       	call   f01000a0 <_panic>
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
f0100c3a:	83 ec 08             	sub    $0x8,%esp
f0100c3d:	ff 75 c0             	pushl  -0x40(%ebp)
f0100c40:	68 10 4e 10 f0       	push   $0xf0104e10
f0100c45:	e8 d6 24 00 00       	call   f0103120 <cprintf>
f0100c4a:	eb 29                	jmp    f0100c75 <check_page_free_list+0x2c4>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c4c:	a1 24 d2 17 f0       	mov    0xf017d224,%eax
f0100c51:	85 c0                	test   %eax,%eax
f0100c53:	0f 85 88 fd ff ff    	jne    f01009e1 <check_page_free_list+0x30>
f0100c59:	e9 6c fd ff ff       	jmp    f01009ca <check_page_free_list+0x19>
f0100c5e:	83 3d 24 d2 17 f0 00 	cmpl   $0x0,0xf017d224
f0100c65:	0f 84 5f fd ff ff    	je     f01009ca <check_page_free_list+0x19>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c6b:	be 00 04 00 00       	mov    $0x400,%esi
f0100c70:	e9 ba fd ff ff       	jmp    f0100a2f <check_page_free_list+0x7e>
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
}
f0100c75:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c78:	5b                   	pop    %ebx
f0100c79:	5e                   	pop    %esi
f0100c7a:	5f                   	pop    %edi
f0100c7b:	5d                   	pop    %ebp
f0100c7c:	c3                   	ret    

f0100c7d <page_init>:
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100c7d:	b8 01 00 00 00       	mov    $0x1,%eax
f0100c82:	eb 18                	jmp    f0100c9c <page_init+0x1f>
	{
	 pages[i].pp_ref = 1; //Used Pages
f0100c84:	8b 15 0c df 17 f0    	mov    0xf017df0c,%edx
f0100c8a:	8d 14 c2             	lea    (%edx,%eax,8),%edx
f0100c8d:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
	 pages[i].pp_link = 0; // No links to any pages
f0100c93:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100c99:	83 c0 01             	add    $0x1,%eax
f0100c9c:	3b 05 04 df 17 f0    	cmp    0xf017df04,%eax
f0100ca2:	72 e0                	jb     f0100c84 <page_init+0x7>
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100ca4:	55                   	push   %ebp
f0100ca5:	89 e5                	mov    %esp,%ebp
f0100ca7:	57                   	push   %edi
f0100ca8:	56                   	push   %esi
f0100ca9:	53                   	push   %ebx
f0100caa:	83 ec 0c             	sub    $0xc,%esp

	
	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	for (i = 1; i < npages_basemem; i++) {
f0100cad:	8b 35 28 d2 17 f0    	mov    0xf017d228,%esi
f0100cb3:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100cb8:	b8 01 00 00 00       	mov    $0x1,%eax
f0100cbd:	eb 39                	jmp    f0100cf8 <page_init+0x7b>
f0100cbf:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100cc6:	8b 0d 0c df 17 f0    	mov    0xf017df0c,%ecx
f0100ccc:	66 c7 44 11 04 00 00 	movw   $0x0,0x4(%ecx,%edx,1)
		pages[i].pp_link = 0;
f0100cd3:	c7 04 c1 00 00 00 00 	movl   $0x0,(%ecx,%eax,8)

		if (!page_free_list){		
f0100cda:	85 db                	test   %ebx,%ebx
f0100cdc:	75 0a                	jne    f0100ce8 <page_init+0x6b>
		page_free_list = &pages[i];	// if page_free_list is 0 then point to current page
f0100cde:	89 d3                	mov    %edx,%ebx
f0100ce0:	03 1d 0c df 17 f0    	add    0xf017df0c,%ebx
f0100ce6:	eb 0d                	jmp    f0100cf5 <page_init+0x78>
		}
		else{
		pages[i-1].pp_link = &pages[i];
f0100ce8:	8b 0d 0c df 17 f0    	mov    0xf017df0c,%ecx
f0100cee:	8d 3c 11             	lea    (%ecx,%edx,1),%edi
f0100cf1:	89 7c 11 f8          	mov    %edi,-0x8(%ecx,%edx,1)

	
	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	for (i = 1; i < npages_basemem; i++) {
f0100cf5:	83 c0 01             	add    $0x1,%eax
f0100cf8:	39 f0                	cmp    %esi,%eax
f0100cfa:	72 c3                	jb     f0100cbf <page_init+0x42>
f0100cfc:	89 1d 24 d2 17 f0    	mov    %ebx,0xf017d224
		}	//Previous page is linked to this current page
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
f0100d02:	8b 15 0c df 17 f0    	mov    0xf017df0c,%edx
f0100d08:	8d 44 c2 f8          	lea    -0x8(%edx,%eax,8),%eax
f0100d0c:	a3 18 d2 17 f0       	mov    %eax,0xf017d218
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100d11:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d16:	e8 20 fc ff ff       	call   f010093b <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100d1b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100d20:	77 15                	ja     f0100d37 <page_init+0xba>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100d22:	50                   	push   %eax
f0100d23:	68 28 4d 10 f0       	push   $0xf0104d28
f0100d28:	68 39 01 00 00       	push   $0x139
f0100d2d:	68 b5 55 10 f0       	push   $0xf01055b5
f0100d32:	e8 69 f3 ff ff       	call   f01000a0 <_panic>
f0100d37:	05 ff 0f 00 10       	add    $0x10000fff,%eax
f0100d3c:	c1 e8 0c             	shr    $0xc,%eax
f0100d3f:	8b 1d 18 d2 17 f0    	mov    0xf017d218,%ebx
f0100d45:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100d4c:	eb 2c                	jmp    f0100d7a <page_init+0xfd>
		pages[i].pp_ref = 0;
f0100d4e:	89 d1                	mov    %edx,%ecx
f0100d50:	03 0d 0c df 17 f0    	add    0xf017df0c,%ecx
f0100d56:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = 0;
f0100d5c:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		track->pp_link = &pages[i];
f0100d62:	89 d1                	mov    %edx,%ecx
f0100d64:	03 0d 0c df 17 f0    	add    0xf017df0c,%ecx
f0100d6a:	89 0b                	mov    %ecx,(%ebx)
		track = &pages[i];
f0100d6c:	89 d3                	mov    %edx,%ebx
f0100d6e:	03 1d 0c df 17 f0    	add    0xf017df0c,%ebx
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100d74:	83 c0 01             	add    $0x1,%eax
f0100d77:	83 c2 08             	add    $0x8,%edx
f0100d7a:	3b 05 04 df 17 f0    	cmp    0xf017df04,%eax
f0100d80:	72 cc                	jb     f0100d4e <page_init+0xd1>
f0100d82:	89 1d 18 d2 17 f0    	mov    %ebx,0xf017d218
		pages[i].pp_link = 0;
		track->pp_link = &pages[i];
		track = &pages[i];
	}
	
	cprintf("Check first entry of pages &pages[0] = %x\n", &pages[0]);
f0100d88:	83 ec 08             	sub    $0x8,%esp
f0100d8b:	ff 35 0c df 17 f0    	pushl  0xf017df0c
f0100d91:	68 38 4e 10 f0       	push   $0xf0104e38
f0100d96:	e8 85 23 00 00       	call   f0103120 <cprintf>
	cprintf("&pages[npages-1] = %x\n", &pages[npages-1]);
f0100d9b:	83 c4 08             	add    $0x8,%esp
f0100d9e:	a1 0c df 17 f0       	mov    0xf017df0c,%eax
f0100da3:	8b 15 04 df 17 f0    	mov    0xf017df04,%edx
f0100da9:	8d 44 d0 f8          	lea    -0x8(%eax,%edx,8),%eax
f0100dad:	50                   	push   %eax
f0100dae:	68 6b 56 10 f0       	push   $0xf010566b
f0100db3:	e8 68 23 00 00       	call   f0103120 <cprintf>
f0100db8:	83 c4 10             	add    $0x10,%esp
}
f0100dbb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100dbe:	5b                   	pop    %ebx
f0100dbf:	5e                   	pop    %esi
f0100dc0:	5f                   	pop    %edi
f0100dc1:	5d                   	pop    %ebp
f0100dc2:	c3                   	ret    

f0100dc3 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100dc3:	55                   	push   %ebp
f0100dc4:	89 e5                	mov    %esp,%ebp
f0100dc6:	53                   	push   %ebx
f0100dc7:	83 ec 04             	sub    $0x4,%esp
	// Check if there is a free_page available 
	if (!page_free_list)
f0100dca:	8b 1d 24 d2 17 f0    	mov    0xf017d224,%ebx
f0100dd0:	85 db                	test   %ebx,%ebx
f0100dd2:	74 5e                	je     f0100e32 <page_alloc+0x6f>
	return NULL;
	}
	
	struct PageInfo *allocPage = NULL;   //Create a temporary pointer 
	allocPage = page_free_list;	//Point to the current head of free_page_list
	page_free_list = allocPage ->pp_link; //Move the head to the next avaialble page
f0100dd4:	8b 03                	mov    (%ebx),%eax
f0100dd6:	a3 24 d2 17 f0       	mov    %eax,0xf017d224
	allocPage->pp_link = NULL;	//Break the link 
f0100ddb:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags && ALLOC_ZERO){		//ALLOC_ZERO = 1<<0; which is nothing but  = 1
f0100de1:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100de5:	74 45                	je     f0100e2c <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100de7:	89 d8                	mov    %ebx,%eax
f0100de9:	2b 05 0c df 17 f0    	sub    0xf017df0c,%eax
f0100def:	c1 f8 03             	sar    $0x3,%eax
f0100df2:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100df5:	89 c2                	mov    %eax,%edx
f0100df7:	c1 ea 0c             	shr    $0xc,%edx
f0100dfa:	3b 15 04 df 17 f0    	cmp    0xf017df04,%edx
f0100e00:	72 12                	jb     f0100e14 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e02:	50                   	push   %eax
f0100e03:	68 04 4d 10 f0       	push   $0xf0104d04
f0100e08:	6a 56                	push   $0x56
f0100e0a:	68 c1 55 10 f0       	push   $0xf01055c1
f0100e0f:	e8 8c f2 ff ff       	call   f01000a0 <_panic>
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
f0100e14:	83 ec 04             	sub    $0x4,%esp
f0100e17:	68 00 10 00 00       	push   $0x1000
f0100e1c:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0100e1e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e23:	50                   	push   %eax
f0100e24:	e8 bf 34 00 00       	call   f01042e8 <memset>
f0100e29:	83 c4 10             	add    $0x10,%esp
	}
	
	allocPage->pp_ref = 0;
f0100e2c:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return allocPage;
}
f0100e32:	89 d8                	mov    %ebx,%eax
f0100e34:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100e37:	c9                   	leave  
f0100e38:	c3                   	ret    

f0100e39 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100e39:	55                   	push   %ebp
f0100e3a:	89 e5                	mov    %esp,%ebp
f0100e3c:	83 ec 08             	sub    $0x8,%esp
f0100e3f:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	
	if(pp->pp_ref)
f0100e42:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100e47:	74 17                	je     f0100e60 <page_free+0x27>
	{
	panic("Page cannot be returned to free list, as it is still refernced ");
f0100e49:	83 ec 04             	sub    $0x4,%esp
f0100e4c:	68 64 4e 10 f0       	push   $0xf0104e64
f0100e51:	68 71 01 00 00       	push   $0x171
f0100e56:	68 b5 55 10 f0       	push   $0xf01055b5
f0100e5b:	e8 40 f2 ff ff       	call   f01000a0 <_panic>
	return;
	}
	
	// pp->pp_link is not NULL.
	else if(!pp) 
f0100e60:	85 c0                	test   %eax,%eax
f0100e62:	75 17                	jne    f0100e7b <page_free+0x42>
	{
	panic("Page cannot be returned to free list as it is Null");
f0100e64:	83 ec 04             	sub    $0x4,%esp
f0100e67:	68 a4 4e 10 f0       	push   $0xf0104ea4
f0100e6c:	68 78 01 00 00       	push   $0x178
f0100e71:	68 b5 55 10 f0       	push   $0xf01055b5
f0100e76:	e8 25 f2 ff ff       	call   f01000a0 <_panic>
	return;
	}
	
       else{
	pp->pp_link = page_free_list;
f0100e7b:	8b 15 24 d2 17 f0    	mov    0xf017d224,%edx
f0100e81:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100e83:	a3 24 d2 17 f0       	mov    %eax,0xf017d224
	}


}
f0100e88:	c9                   	leave  
f0100e89:	c3                   	ret    

f0100e8a <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e8a:	55                   	push   %ebp
f0100e8b:	89 e5                	mov    %esp,%ebp
f0100e8d:	83 ec 08             	sub    $0x8,%esp
f0100e90:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e93:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e97:	83 e8 01             	sub    $0x1,%eax
f0100e9a:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e9e:	66 85 c0             	test   %ax,%ax
f0100ea1:	75 0c                	jne    f0100eaf <page_decref+0x25>
		page_free(pp);
f0100ea3:	83 ec 0c             	sub    $0xc,%esp
f0100ea6:	52                   	push   %edx
f0100ea7:	e8 8d ff ff ff       	call   f0100e39 <page_free>
f0100eac:	83 c4 10             	add    $0x10,%esp
}
f0100eaf:	c9                   	leave  
f0100eb0:	c3                   	ret    

f0100eb1 <pgdir_walk>:
// table and page directory entries.
//

pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100eb1:	55                   	push   %ebp
f0100eb2:	89 e5                	mov    %esp,%ebp
f0100eb4:	57                   	push   %edi
f0100eb5:	56                   	push   %esi
f0100eb6:	53                   	push   %ebx
f0100eb7:	83 ec 0c             	sub    $0xc,%esp
	pte_t *pgTab;  //Page Table index variable

	//To find the index from the pgdir we need to get the MS 10 bits,
	//We get the MS 10bits of the virtual address by using PDX function (found in inc/mmu.h ) 
	//#define PDX(la)		((((uintptr_t) (la)) >> PDXSHIFT) & 0x3FF)
	pgDir = &pgdir[PDX(va)];
f0100eba:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100ebd:	c1 ee 16             	shr    $0x16,%esi
f0100ec0:	c1 e6 02             	shl    $0x2,%esi
f0100ec3:	03 75 08             	add    0x8(%ebp),%esi

	// Check if page is present, PTE_P = 0x1 means page present  
	if (*pgDir & PTE_P)  {
f0100ec6:	8b 1e                	mov    (%esi),%ebx
f0100ec8:	f6 c3 01             	test   $0x1,%bl
f0100ecb:	74 30                	je     f0100efd <pgdir_walk+0x4c>
		//page table entry to get to the final address translation. Now using the pgDir we can use the 
		//PTE_ADDR(pde) function to get the upper 20 bits, but this function returns a physical address. 
		//Since the kernel requires a virtual address, we can use the function KADDR to get the virtual 
		//address.
		
		pgTab = (pte_t*) KADDR(PTE_ADDR(*pgDir));
f0100ecd:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ed3:	89 d8                	mov    %ebx,%eax
f0100ed5:	c1 e8 0c             	shr    $0xc,%eax
f0100ed8:	3b 05 04 df 17 f0    	cmp    0xf017df04,%eax
f0100ede:	72 15                	jb     f0100ef5 <pgdir_walk+0x44>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ee0:	53                   	push   %ebx
f0100ee1:	68 04 4d 10 f0       	push   $0xf0104d04
f0100ee6:	68 b9 01 00 00       	push   $0x1b9
f0100eeb:	68 b5 55 10 f0       	push   $0xf01055b5
f0100ef0:	e8 ab f1 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0100ef5:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
f0100efb:	eb 7c                	jmp    f0100f79 <pgdir_walk+0xc8>
	//If page is not present 
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
f0100efd:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100f01:	0f 84 81 00 00 00    	je     f0100f88 <pgdir_walk+0xd7>
f0100f07:	83 ec 0c             	sub    $0xc,%esp
f0100f0a:	68 00 10 00 00       	push   $0x1000
f0100f0f:	e8 af fe ff ff       	call   f0100dc3 <page_alloc>
f0100f14:	89 c7                	mov    %eax,%edi
f0100f16:	83 c4 10             	add    $0x10,%esp
f0100f19:	85 c0                	test   %eax,%eax
f0100f1b:	74 72                	je     f0100f8f <pgdir_walk+0xde>
			return 0;
		}

		newPage->pp_ref++;  //Increment the ref pointer of the page 
f0100f1d:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f22:	89 c3                	mov    %eax,%ebx
f0100f24:	2b 1d 0c df 17 f0    	sub    0xf017df0c,%ebx
f0100f2a:	c1 fb 03             	sar    $0x3,%ebx
f0100f2d:	c1 e3 0c             	shl    $0xc,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f30:	89 d8                	mov    %ebx,%eax
f0100f32:	c1 e8 0c             	shr    $0xc,%eax
f0100f35:	3b 05 04 df 17 f0    	cmp    0xf017df04,%eax
f0100f3b:	72 12                	jb     f0100f4f <pgdir_walk+0x9e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f3d:	53                   	push   %ebx
f0100f3e:	68 04 4d 10 f0       	push   $0xf0104d04
f0100f43:	6a 56                	push   $0x56
f0100f45:	68 c1 55 10 f0       	push   $0xf01055c1
f0100f4a:	e8 51 f1 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0100f4f:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
		//Now this section creates the bindings and updates all the flags 
		//for relevant use of the page.
		
		//First create a link on the pgTab wrt to the new page
		pgTab = (pte_t*)page2kva(newPage); // this function gets the virtual address of the new page
		memset (pgTab, 0, PGSIZE); //Clear the entire page
f0100f55:	83 ec 04             	sub    $0x4,%esp
f0100f58:	68 00 10 00 00       	push   $0x1000
f0100f5d:	6a 00                	push   $0x0
f0100f5f:	53                   	push   %ebx
f0100f60:	e8 83 33 00 00       	call   f01042e8 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f65:	2b 3d 0c df 17 f0    	sub    0xf017df0c,%edi
f0100f6b:	c1 ff 03             	sar    $0x3,%edi
f0100f6e:	c1 e7 0c             	shl    $0xc,%edi

		//Page Table, pgTab contains the virtual address , now we need to set the permission bits.
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
f0100f71:	83 cf 07             	or     $0x7,%edi
f0100f74:	89 3e                	mov    %edi,(%esi)
f0100f76:	83 c4 10             	add    $0x10,%esp
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
f0100f79:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f7c:	c1 e8 0a             	shr    $0xa,%eax
f0100f7f:	25 fc 0f 00 00       	and    $0xffc,%eax
f0100f84:	01 d8                	add    %ebx,%eax
f0100f86:	eb 0c                	jmp    f0100f94 <pgdir_walk+0xe3>
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
			return 0;
f0100f88:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f8d:	eb 05                	jmp    f0100f94 <pgdir_walk+0xe3>
f0100f8f:	b8 00 00 00 00       	mov    $0x0,%eax
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
}
f0100f94:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f97:	5b                   	pop    %ebx
f0100f98:	5e                   	pop    %esi
f0100f99:	5f                   	pop    %edi
f0100f9a:	5d                   	pop    %ebp
f0100f9b:	c3                   	ret    

f0100f9c <boot_map_region>:
//
// Hint: the TA solution uses pgdir_walk

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100f9c:	55                   	push   %ebp
f0100f9d:	89 e5                	mov    %esp,%ebp
f0100f9f:	57                   	push   %edi
f0100fa0:	56                   	push   %esi
f0100fa1:	53                   	push   %ebx
f0100fa2:	83 ec 1c             	sub    $0x1c,%esp
f0100fa5:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f0100fa8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
f0100fae:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fb1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	size = ROUNDUP(size, PGSIZE); 
f0100fb6:	8d b9 ff 0f 00 00    	lea    0xfff(%ecx),%edi
f0100fbc:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f0100fc2:	89 d3                	mov    %edx,%ebx
f0100fc4:	29 d0                	sub    %edx,%eax
f0100fc6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100fc9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100fcc:	83 c8 01             	or     $0x1,%eax
f0100fcf:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f0100fd2:	eb 59                	jmp    f010102d <boot_map_region+0x91>
		if (!(pgTbEnt = pgdir_walk(pgdir, (const void*)vaBegin, 1))){
f0100fd4:	83 ec 04             	sub    $0x4,%esp
f0100fd7:	6a 01                	push   $0x1
f0100fd9:	53                   	push   %ebx
f0100fda:	ff 75 e0             	pushl  -0x20(%ebp)
f0100fdd:	e8 cf fe ff ff       	call   f0100eb1 <pgdir_walk>
f0100fe2:	83 c4 10             	add    $0x10,%esp
f0100fe5:	85 c0                	test   %eax,%eax
f0100fe7:	75 17                	jne    f0101000 <boot_map_region+0x64>
			panic("Cannot find page for the page table entry, from boot_map_region function");
f0100fe9:	83 ec 04             	sub    $0x4,%esp
f0100fec:	68 d8 4e 10 f0       	push   $0xf0104ed8
f0100ff1:	68 ef 01 00 00       	push   $0x1ef
f0100ff6:	68 b5 55 10 f0       	push   $0xf01055b5
f0100ffb:	e8 a0 f0 ff ff       	call   f01000a0 <_panic>
		}
		if (*pgTbEnt & PTE_P){
f0101000:	f6 00 01             	testb  $0x1,(%eax)
f0101003:	74 17                	je     f010101c <boot_map_region+0x80>
			panic("Page is already mapped");
f0101005:	83 ec 04             	sub    $0x4,%esp
f0101008:	68 82 56 10 f0       	push   $0xf0105682
f010100d:	68 f2 01 00 00       	push   $0x1f2
f0101012:	68 b5 55 10 f0       	push   $0xf01055b5
f0101017:	e8 84 f0 ff ff       	call   f01000a0 <_panic>
		}
		
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
f010101c:	0b 75 dc             	or     -0x24(%ebp),%esi
f010101f:	89 30                	mov    %esi,(%eax)
		vaBegin += PGSIZE;
f0101021:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		paBegin += PGSIZE; 
		size -= PGSIZE;
f0101027:	81 ef 00 10 00 00    	sub    $0x1000,%edi
f010102d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101030:	8d 34 18             	lea    (%eax,%ebx,1),%esi
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f0101033:	85 ff                	test   %edi,%edi
f0101035:	75 9d                	jne    f0100fd4 <boot_map_region+0x38>
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
		vaBegin += PGSIZE;
		paBegin += PGSIZE; 
		size -= PGSIZE;
	} 	
}
f0101037:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010103a:	5b                   	pop    %ebx
f010103b:	5e                   	pop    %esi
f010103c:	5f                   	pop    %edi
f010103d:	5d                   	pop    %ebp
f010103e:	c3                   	ret    

f010103f <page_lookup>:
// Hint: the TA solution uses pgdir_walk and pa2page.
//

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f010103f:	55                   	push   %ebp
f0101040:	89 e5                	mov    %esp,%ebp
f0101042:	53                   	push   %ebx
f0101043:	83 ec 08             	sub    $0x8,%esp
f0101046:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
	pgTbEty = pgdir_walk(pgdir, va, 0);
f0101049:	6a 00                	push   $0x0
f010104b:	ff 75 0c             	pushl  0xc(%ebp)
f010104e:	ff 75 08             	pushl  0x8(%ebp)
f0101051:	e8 5b fe ff ff       	call   f0100eb1 <pgdir_walk>
f0101056:	89 c1                	mov    %eax,%ecx
	if (pgTbEty && (*pgTbEty & PTE_P)) {
f0101058:	83 c4 10             	add    $0x10,%esp
f010105b:	85 c0                	test   %eax,%eax
f010105d:	74 1a                	je     f0101079 <page_lookup+0x3a>
f010105f:	8b 10                	mov    (%eax),%edx
f0101061:	f6 c2 01             	test   $0x1,%dl
f0101064:	74 1a                	je     f0101080 <page_lookup+0x41>
		ret = pages + (PTE_ADDR(*pgTbEty) >> PTXSHIFT);
f0101066:	c1 ea 0c             	shr    $0xc,%edx
f0101069:	a1 0c df 17 f0       	mov    0xf017df0c,%eax
f010106e:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		if (pte_store) {
f0101071:	85 db                	test   %ebx,%ebx
f0101073:	74 10                	je     f0101085 <page_lookup+0x46>
			*pte_store = pgTbEty;
f0101075:	89 0b                	mov    %ecx,(%ebx)
f0101077:	eb 0c                	jmp    f0101085 <page_lookup+0x46>

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
f0101079:	b8 00 00 00 00       	mov    $0x0,%eax
f010107e:	eb 05                	jmp    f0101085 <page_lookup+0x46>
f0101080:	b8 00 00 00 00       	mov    $0x0,%eax
		if (pte_store) {
			*pte_store = pgTbEty;
		}
	}
	return ret;
}
f0101085:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101088:	c9                   	leave  
f0101089:	c3                   	ret    

f010108a <page_remove>:
// 	tlb_invalidate, and page_decref.
//

void
page_remove(pde_t *pgdir, void *va)
{
f010108a:	55                   	push   %ebp
f010108b:	89 e5                	mov    %esp,%ebp
f010108d:	53                   	push   %ebx
f010108e:	83 ec 18             	sub    $0x18,%esp
f0101091:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte;
	struct PageInfo *remPage = 0;
	if (!(remPage = page_lookup(pgdir, va, &pte))) {
f0101094:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101097:	50                   	push   %eax
f0101098:	53                   	push   %ebx
f0101099:	ff 75 08             	pushl  0x8(%ebp)
f010109c:	e8 9e ff ff ff       	call   f010103f <page_lookup>
f01010a1:	83 c4 10             	add    $0x10,%esp
f01010a4:	85 c0                	test   %eax,%eax
f01010a6:	74 18                	je     f01010c0 <page_remove+0x36>
		return;
	}
	page_decref(remPage);
f01010a8:	83 ec 0c             	sub    $0xc,%esp
f01010ab:	50                   	push   %eax
f01010ac:	e8 d9 fd ff ff       	call   f0100e8a <page_decref>
	*pte = 0;
f01010b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01010b4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01010ba:	0f 01 3b             	invlpg (%ebx)
f01010bd:	83 c4 10             	add    $0x10,%esp
	tlb_invalidate(pgdir, va);
}
f01010c0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01010c3:	c9                   	leave  
f01010c4:	c3                   	ret    

f01010c5 <page_insert>:
// and page2pa.
//

int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01010c5:	55                   	push   %ebp
f01010c6:	89 e5                	mov    %esp,%ebp
f01010c8:	57                   	push   %edi
f01010c9:	56                   	push   %esi
f01010ca:	53                   	push   %ebx
f01010cb:	83 ec 10             	sub    $0x10,%esp
f01010ce:	8b 75 0c             	mov    0xc(%ebp),%esi
f01010d1:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
f01010d4:	6a 01                	push   $0x1
f01010d6:	57                   	push   %edi
f01010d7:	ff 75 08             	pushl  0x8(%ebp)
f01010da:	e8 d2 fd ff ff       	call   f0100eb1 <pgdir_walk>
f01010df:	89 c3                	mov    %eax,%ebx
	
	if (!pte){
f01010e1:	83 c4 10             	add    $0x10,%esp
f01010e4:	85 c0                	test   %eax,%eax
f01010e6:	0f 84 85 00 00 00    	je     f0101171 <page_insert+0xac>
		return -E_NO_MEM; //Page table could not be allocated	
	}

	if (*pte & PTE_P){    //if page is already present
f01010ec:	8b 00                	mov    (%eax),%eax
f01010ee:	a8 01                	test   $0x1,%al
f01010f0:	74 5b                	je     f010114d <page_insert+0x88>
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
f01010f2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01010f7:	89 f2                	mov    %esi,%edx
f01010f9:	2b 15 0c df 17 f0    	sub    0xf017df0c,%edx
f01010ff:	c1 fa 03             	sar    $0x3,%edx
f0101102:	c1 e2 0c             	shl    $0xc,%edx
f0101105:	39 d0                	cmp    %edx,%eax
f0101107:	75 11                	jne    f010111a <page_insert+0x55>
f0101109:	8b 55 14             	mov    0x14(%ebp),%edx
f010110c:	83 ca 01             	or     $0x1,%edx
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
f010110f:	09 d0                	or     %edx,%eax
f0101111:	89 03                	mov    %eax,(%ebx)
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
			pp->pp_ref ++;  //incremnt the page reference
		}
		return 0;
f0101113:	b8 00 00 00 00       	mov    $0x0,%eax
f0101118:	eb 5c                	jmp    f0101176 <page_insert+0xb1>
	if (*pte & PTE_P){    //if page is already present
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
		}
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
f010111a:	83 ec 08             	sub    $0x8,%esp
f010111d:	57                   	push   %edi
f010111e:	ff 75 08             	pushl  0x8(%ebp)
f0101121:	e8 64 ff ff ff       	call   f010108a <page_remove>
f0101126:	8b 55 14             	mov    0x14(%ebp),%edx
f0101129:	83 ca 01             	or     $0x1,%edx
f010112c:	89 f0                	mov    %esi,%eax
f010112e:	2b 05 0c df 17 f0    	sub    0xf017df0c,%eax
f0101134:	c1 f8 03             	sar    $0x3,%eax
f0101137:	c1 e0 0c             	shl    $0xc,%eax
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
f010113a:	09 d0                	or     %edx,%eax
f010113c:	89 03                	mov    %eax,(%ebx)
			pp->pp_ref ++;  //incremnt the page reference
f010113e:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
f0101143:	83 c4 10             	add    $0x10,%esp
		}
		return 0;
f0101146:	b8 00 00 00 00       	mov    $0x0,%eax
f010114b:	eb 29                	jmp    f0101176 <page_insert+0xb1>
f010114d:	8b 55 14             	mov    0x14(%ebp),%edx
f0101150:	83 ca 01             	or     $0x1,%edx
f0101153:	89 f0                	mov    %esi,%eax
f0101155:	2b 05 0c df 17 f0    	sub    0xf017df0c,%eax
f010115b:	c1 f8 03             	sar    $0x3,%eax
f010115e:	c1 e0 0c             	shl    $0xc,%eax
	}	
	else{   // if page is not present
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
f0101161:	09 d0                	or     %edx,%eax
f0101163:	89 03                	mov    %eax,(%ebx)
		pp->pp_ref ++; // increment the page reference count	     
f0101165:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	}
	return 0;
f010116a:	b8 00 00 00 00       	mov    $0x0,%eax
f010116f:	eb 05                	jmp    f0101176 <page_insert+0xb1>
{
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
	
	if (!pte){
		return -E_NO_MEM; //Page table could not be allocated	
f0101171:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
		pp->pp_ref ++; // increment the page reference count	     
	}
	return 0;

}
f0101176:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101179:	5b                   	pop    %ebx
f010117a:	5e                   	pop    %esi
f010117b:	5f                   	pop    %edi
f010117c:	5d                   	pop    %ebp
f010117d:	c3                   	ret    

f010117e <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010117e:	55                   	push   %ebp
f010117f:	89 e5                	mov    %esp,%ebp
f0101181:	57                   	push   %edi
f0101182:	56                   	push   %esi
f0101183:	53                   	push   %ebx
f0101184:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101187:	6a 15                	push   $0x15
f0101189:	e8 31 1f 00 00       	call   f01030bf <mc146818_read>
f010118e:	89 c3                	mov    %eax,%ebx
f0101190:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101197:	e8 23 1f 00 00       	call   f01030bf <mc146818_read>
f010119c:	c1 e0 08             	shl    $0x8,%eax
f010119f:	09 d8                	or     %ebx,%eax
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01011a1:	c1 e0 0a             	shl    $0xa,%eax
f01011a4:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01011aa:	85 c0                	test   %eax,%eax
f01011ac:	0f 48 c2             	cmovs  %edx,%eax
f01011af:	c1 f8 0c             	sar    $0xc,%eax
f01011b2:	a3 28 d2 17 f0       	mov    %eax,0xf017d228
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01011b7:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f01011be:	e8 fc 1e 00 00       	call   f01030bf <mc146818_read>
f01011c3:	89 c3                	mov    %eax,%ebx
f01011c5:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01011cc:	e8 ee 1e 00 00       	call   f01030bf <mc146818_read>
f01011d1:	c1 e0 08             	shl    $0x8,%eax
f01011d4:	09 d8                	or     %ebx,%eax
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01011d6:	c1 e0 0a             	shl    $0xa,%eax
f01011d9:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01011df:	83 c4 10             	add    $0x10,%esp
f01011e2:	85 c0                	test   %eax,%eax
f01011e4:	0f 48 c2             	cmovs  %edx,%eax
f01011e7:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01011ea:	85 c0                	test   %eax,%eax
f01011ec:	74 0e                	je     f01011fc <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01011ee:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01011f4:	89 15 04 df 17 f0    	mov    %edx,0xf017df04
f01011fa:	eb 0c                	jmp    f0101208 <mem_init+0x8a>
	else
		npages = npages_basemem;
f01011fc:	8b 15 28 d2 17 f0    	mov    0xf017d228,%edx
f0101202:	89 15 04 df 17 f0    	mov    %edx,0xf017df04

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0101208:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010120b:	c1 e8 0a             	shr    $0xa,%eax
f010120e:	50                   	push   %eax
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f010120f:	a1 28 d2 17 f0       	mov    0xf017d228,%eax
f0101214:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101217:	c1 e8 0a             	shr    $0xa,%eax
f010121a:	50                   	push   %eax
		npages * PGSIZE / 1024,
f010121b:	a1 04 df 17 f0       	mov    0xf017df04,%eax
f0101220:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101223:	c1 e8 0a             	shr    $0xa,%eax
f0101226:	50                   	push   %eax
f0101227:	68 24 4f 10 f0       	push   $0xf0104f24
f010122c:	e8 ef 1e 00 00       	call   f0103120 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101231:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101236:	e8 00 f7 ff ff       	call   f010093b <boot_alloc>
f010123b:	a3 08 df 17 f0       	mov    %eax,0xf017df08
	memset(kern_pgdir, 0, PGSIZE);
f0101240:	83 c4 0c             	add    $0xc,%esp
f0101243:	68 00 10 00 00       	push   $0x1000
f0101248:	6a 00                	push   $0x0
f010124a:	50                   	push   %eax
f010124b:	e8 98 30 00 00       	call   f01042e8 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101250:	a1 08 df 17 f0       	mov    0xf017df08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101255:	83 c4 10             	add    $0x10,%esp
f0101258:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010125d:	77 15                	ja     f0101274 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010125f:	50                   	push   %eax
f0101260:	68 28 4d 10 f0       	push   $0xf0104d28
f0101265:	68 96 00 00 00       	push   $0x96
f010126a:	68 b5 55 10 f0       	push   $0xf01055b5
f010126f:	e8 2c ee ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101274:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010127a:	83 ca 05             	or     $0x5,%edx
f010127d:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.

	//This line creates a boot allocation of memory of the size of number of pages
	// mulitplied by size of struct Pageinfo to store metadata of the page. 
	pages = boot_alloc(sizeof(struct PageInfo) * npages);   
f0101283:	a1 04 df 17 f0       	mov    0xf017df04,%eax
f0101288:	c1 e0 03             	shl    $0x3,%eax
f010128b:	e8 ab f6 ff ff       	call   f010093b <boot_alloc>
f0101290:	a3 0c df 17 f0       	mov    %eax,0xf017df0c
	memset(pages, 0, sizeof(struct PageInfo) * npages); //Clear the memory 
f0101295:	83 ec 04             	sub    $0x4,%esp
f0101298:	8b 3d 04 df 17 f0    	mov    0xf017df04,%edi
f010129e:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f01012a5:	52                   	push   %edx
f01012a6:	6a 00                	push   $0x0
f01012a8:	50                   	push   %eax
f01012a9:	e8 3a 30 00 00       	call   f01042e8 <memset>
	// The kernel uses this array to keep track of environment array:
	// 'NENV' is the number of Environments in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = boot_alloc(sizeof(struct Env)*NENV);
f01012ae:	b8 00 80 01 00       	mov    $0x18000,%eax
f01012b3:	e8 83 f6 ff ff       	call   f010093b <boot_alloc>
f01012b8:	a3 30 d2 17 f0       	mov    %eax,0xf017d230
	memset(envs,0,sizeof(struct Env)*NENV);
f01012bd:	83 c4 0c             	add    $0xc,%esp
f01012c0:	68 00 80 01 00       	push   $0x18000
f01012c5:	6a 00                	push   $0x0
f01012c7:	50                   	push   %eax
f01012c8:	e8 1b 30 00 00       	call   f01042e8 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01012cd:	e8 ab f9 ff ff       	call   f0100c7d <page_init>

	check_page_free_list(1);
f01012d2:	b8 01 00 00 00       	mov    $0x1,%eax
f01012d7:	e8 d5 f6 ff ff       	call   f01009b1 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01012dc:	83 c4 10             	add    $0x10,%esp
f01012df:	83 3d 0c df 17 f0 00 	cmpl   $0x0,0xf017df0c
f01012e6:	75 17                	jne    f01012ff <mem_init+0x181>
		panic("'pages' is a null pointer!");
f01012e8:	83 ec 04             	sub    $0x4,%esp
f01012eb:	68 99 56 10 f0       	push   $0xf0105699
f01012f0:	68 14 03 00 00       	push   $0x314
f01012f5:	68 b5 55 10 f0       	push   $0xf01055b5
f01012fa:	e8 a1 ed ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01012ff:	a1 24 d2 17 f0       	mov    0xf017d224,%eax
f0101304:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101309:	eb 05                	jmp    f0101310 <mem_init+0x192>
		++nfree;
f010130b:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010130e:	8b 00                	mov    (%eax),%eax
f0101310:	85 c0                	test   %eax,%eax
f0101312:	75 f7                	jne    f010130b <mem_init+0x18d>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101314:	83 ec 0c             	sub    $0xc,%esp
f0101317:	6a 00                	push   $0x0
f0101319:	e8 a5 fa ff ff       	call   f0100dc3 <page_alloc>
f010131e:	89 c7                	mov    %eax,%edi
f0101320:	83 c4 10             	add    $0x10,%esp
f0101323:	85 c0                	test   %eax,%eax
f0101325:	75 19                	jne    f0101340 <mem_init+0x1c2>
f0101327:	68 b4 56 10 f0       	push   $0xf01056b4
f010132c:	68 db 55 10 f0       	push   $0xf01055db
f0101331:	68 1c 03 00 00       	push   $0x31c
f0101336:	68 b5 55 10 f0       	push   $0xf01055b5
f010133b:	e8 60 ed ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101340:	83 ec 0c             	sub    $0xc,%esp
f0101343:	6a 00                	push   $0x0
f0101345:	e8 79 fa ff ff       	call   f0100dc3 <page_alloc>
f010134a:	89 c6                	mov    %eax,%esi
f010134c:	83 c4 10             	add    $0x10,%esp
f010134f:	85 c0                	test   %eax,%eax
f0101351:	75 19                	jne    f010136c <mem_init+0x1ee>
f0101353:	68 ca 56 10 f0       	push   $0xf01056ca
f0101358:	68 db 55 10 f0       	push   $0xf01055db
f010135d:	68 1d 03 00 00       	push   $0x31d
f0101362:	68 b5 55 10 f0       	push   $0xf01055b5
f0101367:	e8 34 ed ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010136c:	83 ec 0c             	sub    $0xc,%esp
f010136f:	6a 00                	push   $0x0
f0101371:	e8 4d fa ff ff       	call   f0100dc3 <page_alloc>
f0101376:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101379:	83 c4 10             	add    $0x10,%esp
f010137c:	85 c0                	test   %eax,%eax
f010137e:	75 19                	jne    f0101399 <mem_init+0x21b>
f0101380:	68 e0 56 10 f0       	push   $0xf01056e0
f0101385:	68 db 55 10 f0       	push   $0xf01055db
f010138a:	68 1e 03 00 00       	push   $0x31e
f010138f:	68 b5 55 10 f0       	push   $0xf01055b5
f0101394:	e8 07 ed ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101399:	39 f7                	cmp    %esi,%edi
f010139b:	75 19                	jne    f01013b6 <mem_init+0x238>
f010139d:	68 f6 56 10 f0       	push   $0xf01056f6
f01013a2:	68 db 55 10 f0       	push   $0xf01055db
f01013a7:	68 21 03 00 00       	push   $0x321
f01013ac:	68 b5 55 10 f0       	push   $0xf01055b5
f01013b1:	e8 ea ec ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013b6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013b9:	39 c7                	cmp    %eax,%edi
f01013bb:	74 04                	je     f01013c1 <mem_init+0x243>
f01013bd:	39 c6                	cmp    %eax,%esi
f01013bf:	75 19                	jne    f01013da <mem_init+0x25c>
f01013c1:	68 60 4f 10 f0       	push   $0xf0104f60
f01013c6:	68 db 55 10 f0       	push   $0xf01055db
f01013cb:	68 22 03 00 00       	push   $0x322
f01013d0:	68 b5 55 10 f0       	push   $0xf01055b5
f01013d5:	e8 c6 ec ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01013da:	8b 0d 0c df 17 f0    	mov    0xf017df0c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01013e0:	8b 15 04 df 17 f0    	mov    0xf017df04,%edx
f01013e6:	c1 e2 0c             	shl    $0xc,%edx
f01013e9:	89 f8                	mov    %edi,%eax
f01013eb:	29 c8                	sub    %ecx,%eax
f01013ed:	c1 f8 03             	sar    $0x3,%eax
f01013f0:	c1 e0 0c             	shl    $0xc,%eax
f01013f3:	39 d0                	cmp    %edx,%eax
f01013f5:	72 19                	jb     f0101410 <mem_init+0x292>
f01013f7:	68 08 57 10 f0       	push   $0xf0105708
f01013fc:	68 db 55 10 f0       	push   $0xf01055db
f0101401:	68 23 03 00 00       	push   $0x323
f0101406:	68 b5 55 10 f0       	push   $0xf01055b5
f010140b:	e8 90 ec ff ff       	call   f01000a0 <_panic>
f0101410:	89 f0                	mov    %esi,%eax
f0101412:	29 c8                	sub    %ecx,%eax
f0101414:	c1 f8 03             	sar    $0x3,%eax
f0101417:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f010141a:	39 c2                	cmp    %eax,%edx
f010141c:	77 19                	ja     f0101437 <mem_init+0x2b9>
f010141e:	68 25 57 10 f0       	push   $0xf0105725
f0101423:	68 db 55 10 f0       	push   $0xf01055db
f0101428:	68 24 03 00 00       	push   $0x324
f010142d:	68 b5 55 10 f0       	push   $0xf01055b5
f0101432:	e8 69 ec ff ff       	call   f01000a0 <_panic>
f0101437:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010143a:	29 c8                	sub    %ecx,%eax
f010143c:	c1 f8 03             	sar    $0x3,%eax
f010143f:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f0101442:	39 c2                	cmp    %eax,%edx
f0101444:	77 19                	ja     f010145f <mem_init+0x2e1>
f0101446:	68 42 57 10 f0       	push   $0xf0105742
f010144b:	68 db 55 10 f0       	push   $0xf01055db
f0101450:	68 25 03 00 00       	push   $0x325
f0101455:	68 b5 55 10 f0       	push   $0xf01055b5
f010145a:	e8 41 ec ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010145f:	a1 24 d2 17 f0       	mov    0xf017d224,%eax
f0101464:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101467:	c7 05 24 d2 17 f0 00 	movl   $0x0,0xf017d224
f010146e:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101471:	83 ec 0c             	sub    $0xc,%esp
f0101474:	6a 00                	push   $0x0
f0101476:	e8 48 f9 ff ff       	call   f0100dc3 <page_alloc>
f010147b:	83 c4 10             	add    $0x10,%esp
f010147e:	85 c0                	test   %eax,%eax
f0101480:	74 19                	je     f010149b <mem_init+0x31d>
f0101482:	68 5f 57 10 f0       	push   $0xf010575f
f0101487:	68 db 55 10 f0       	push   $0xf01055db
f010148c:	68 2c 03 00 00       	push   $0x32c
f0101491:	68 b5 55 10 f0       	push   $0xf01055b5
f0101496:	e8 05 ec ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f010149b:	83 ec 0c             	sub    $0xc,%esp
f010149e:	57                   	push   %edi
f010149f:	e8 95 f9 ff ff       	call   f0100e39 <page_free>
	page_free(pp1);
f01014a4:	89 34 24             	mov    %esi,(%esp)
f01014a7:	e8 8d f9 ff ff       	call   f0100e39 <page_free>
	page_free(pp2);
f01014ac:	83 c4 04             	add    $0x4,%esp
f01014af:	ff 75 d4             	pushl  -0x2c(%ebp)
f01014b2:	e8 82 f9 ff ff       	call   f0100e39 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01014b7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014be:	e8 00 f9 ff ff       	call   f0100dc3 <page_alloc>
f01014c3:	89 c6                	mov    %eax,%esi
f01014c5:	83 c4 10             	add    $0x10,%esp
f01014c8:	85 c0                	test   %eax,%eax
f01014ca:	75 19                	jne    f01014e5 <mem_init+0x367>
f01014cc:	68 b4 56 10 f0       	push   $0xf01056b4
f01014d1:	68 db 55 10 f0       	push   $0xf01055db
f01014d6:	68 33 03 00 00       	push   $0x333
f01014db:	68 b5 55 10 f0       	push   $0xf01055b5
f01014e0:	e8 bb eb ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01014e5:	83 ec 0c             	sub    $0xc,%esp
f01014e8:	6a 00                	push   $0x0
f01014ea:	e8 d4 f8 ff ff       	call   f0100dc3 <page_alloc>
f01014ef:	89 c7                	mov    %eax,%edi
f01014f1:	83 c4 10             	add    $0x10,%esp
f01014f4:	85 c0                	test   %eax,%eax
f01014f6:	75 19                	jne    f0101511 <mem_init+0x393>
f01014f8:	68 ca 56 10 f0       	push   $0xf01056ca
f01014fd:	68 db 55 10 f0       	push   $0xf01055db
f0101502:	68 34 03 00 00       	push   $0x334
f0101507:	68 b5 55 10 f0       	push   $0xf01055b5
f010150c:	e8 8f eb ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101511:	83 ec 0c             	sub    $0xc,%esp
f0101514:	6a 00                	push   $0x0
f0101516:	e8 a8 f8 ff ff       	call   f0100dc3 <page_alloc>
f010151b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010151e:	83 c4 10             	add    $0x10,%esp
f0101521:	85 c0                	test   %eax,%eax
f0101523:	75 19                	jne    f010153e <mem_init+0x3c0>
f0101525:	68 e0 56 10 f0       	push   $0xf01056e0
f010152a:	68 db 55 10 f0       	push   $0xf01055db
f010152f:	68 35 03 00 00       	push   $0x335
f0101534:	68 b5 55 10 f0       	push   $0xf01055b5
f0101539:	e8 62 eb ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010153e:	39 fe                	cmp    %edi,%esi
f0101540:	75 19                	jne    f010155b <mem_init+0x3dd>
f0101542:	68 f6 56 10 f0       	push   $0xf01056f6
f0101547:	68 db 55 10 f0       	push   $0xf01055db
f010154c:	68 37 03 00 00       	push   $0x337
f0101551:	68 b5 55 10 f0       	push   $0xf01055b5
f0101556:	e8 45 eb ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010155b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010155e:	39 c6                	cmp    %eax,%esi
f0101560:	74 04                	je     f0101566 <mem_init+0x3e8>
f0101562:	39 c7                	cmp    %eax,%edi
f0101564:	75 19                	jne    f010157f <mem_init+0x401>
f0101566:	68 60 4f 10 f0       	push   $0xf0104f60
f010156b:	68 db 55 10 f0       	push   $0xf01055db
f0101570:	68 38 03 00 00       	push   $0x338
f0101575:	68 b5 55 10 f0       	push   $0xf01055b5
f010157a:	e8 21 eb ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f010157f:	83 ec 0c             	sub    $0xc,%esp
f0101582:	6a 00                	push   $0x0
f0101584:	e8 3a f8 ff ff       	call   f0100dc3 <page_alloc>
f0101589:	83 c4 10             	add    $0x10,%esp
f010158c:	85 c0                	test   %eax,%eax
f010158e:	74 19                	je     f01015a9 <mem_init+0x42b>
f0101590:	68 5f 57 10 f0       	push   $0xf010575f
f0101595:	68 db 55 10 f0       	push   $0xf01055db
f010159a:	68 39 03 00 00       	push   $0x339
f010159f:	68 b5 55 10 f0       	push   $0xf01055b5
f01015a4:	e8 f7 ea ff ff       	call   f01000a0 <_panic>
f01015a9:	89 f0                	mov    %esi,%eax
f01015ab:	2b 05 0c df 17 f0    	sub    0xf017df0c,%eax
f01015b1:	c1 f8 03             	sar    $0x3,%eax
f01015b4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01015b7:	89 c2                	mov    %eax,%edx
f01015b9:	c1 ea 0c             	shr    $0xc,%edx
f01015bc:	3b 15 04 df 17 f0    	cmp    0xf017df04,%edx
f01015c2:	72 12                	jb     f01015d6 <mem_init+0x458>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01015c4:	50                   	push   %eax
f01015c5:	68 04 4d 10 f0       	push   $0xf0104d04
f01015ca:	6a 56                	push   $0x56
f01015cc:	68 c1 55 10 f0       	push   $0xf01055c1
f01015d1:	e8 ca ea ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01015d6:	83 ec 04             	sub    $0x4,%esp
f01015d9:	68 00 10 00 00       	push   $0x1000
f01015de:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f01015e0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01015e5:	50                   	push   %eax
f01015e6:	e8 fd 2c 00 00       	call   f01042e8 <memset>
	page_free(pp0);
f01015eb:	89 34 24             	mov    %esi,(%esp)
f01015ee:	e8 46 f8 ff ff       	call   f0100e39 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01015f3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01015fa:	e8 c4 f7 ff ff       	call   f0100dc3 <page_alloc>
f01015ff:	83 c4 10             	add    $0x10,%esp
f0101602:	85 c0                	test   %eax,%eax
f0101604:	75 19                	jne    f010161f <mem_init+0x4a1>
f0101606:	68 6e 57 10 f0       	push   $0xf010576e
f010160b:	68 db 55 10 f0       	push   $0xf01055db
f0101610:	68 3e 03 00 00       	push   $0x33e
f0101615:	68 b5 55 10 f0       	push   $0xf01055b5
f010161a:	e8 81 ea ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f010161f:	39 c6                	cmp    %eax,%esi
f0101621:	74 19                	je     f010163c <mem_init+0x4be>
f0101623:	68 8c 57 10 f0       	push   $0xf010578c
f0101628:	68 db 55 10 f0       	push   $0xf01055db
f010162d:	68 3f 03 00 00       	push   $0x33f
f0101632:	68 b5 55 10 f0       	push   $0xf01055b5
f0101637:	e8 64 ea ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010163c:	89 f0                	mov    %esi,%eax
f010163e:	2b 05 0c df 17 f0    	sub    0xf017df0c,%eax
f0101644:	c1 f8 03             	sar    $0x3,%eax
f0101647:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010164a:	89 c2                	mov    %eax,%edx
f010164c:	c1 ea 0c             	shr    $0xc,%edx
f010164f:	3b 15 04 df 17 f0    	cmp    0xf017df04,%edx
f0101655:	72 12                	jb     f0101669 <mem_init+0x4eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101657:	50                   	push   %eax
f0101658:	68 04 4d 10 f0       	push   $0xf0104d04
f010165d:	6a 56                	push   $0x56
f010165f:	68 c1 55 10 f0       	push   $0xf01055c1
f0101664:	e8 37 ea ff ff       	call   f01000a0 <_panic>
f0101669:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010166f:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101675:	80 38 00             	cmpb   $0x0,(%eax)
f0101678:	74 19                	je     f0101693 <mem_init+0x515>
f010167a:	68 9c 57 10 f0       	push   $0xf010579c
f010167f:	68 db 55 10 f0       	push   $0xf01055db
f0101684:	68 42 03 00 00       	push   $0x342
f0101689:	68 b5 55 10 f0       	push   $0xf01055b5
f010168e:	e8 0d ea ff ff       	call   f01000a0 <_panic>
f0101693:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101696:	39 d0                	cmp    %edx,%eax
f0101698:	75 db                	jne    f0101675 <mem_init+0x4f7>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010169a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010169d:	a3 24 d2 17 f0       	mov    %eax,0xf017d224

	// free the pages we took
	page_free(pp0);
f01016a2:	83 ec 0c             	sub    $0xc,%esp
f01016a5:	56                   	push   %esi
f01016a6:	e8 8e f7 ff ff       	call   f0100e39 <page_free>
	page_free(pp1);
f01016ab:	89 3c 24             	mov    %edi,(%esp)
f01016ae:	e8 86 f7 ff ff       	call   f0100e39 <page_free>
	page_free(pp2);
f01016b3:	83 c4 04             	add    $0x4,%esp
f01016b6:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016b9:	e8 7b f7 ff ff       	call   f0100e39 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01016be:	a1 24 d2 17 f0       	mov    0xf017d224,%eax
f01016c3:	83 c4 10             	add    $0x10,%esp
f01016c6:	eb 05                	jmp    f01016cd <mem_init+0x54f>
		--nfree;
f01016c8:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01016cb:	8b 00                	mov    (%eax),%eax
f01016cd:	85 c0                	test   %eax,%eax
f01016cf:	75 f7                	jne    f01016c8 <mem_init+0x54a>
		--nfree;
	assert(nfree == 0);
f01016d1:	85 db                	test   %ebx,%ebx
f01016d3:	74 19                	je     f01016ee <mem_init+0x570>
f01016d5:	68 a6 57 10 f0       	push   $0xf01057a6
f01016da:	68 db 55 10 f0       	push   $0xf01055db
f01016df:	68 4f 03 00 00       	push   $0x34f
f01016e4:	68 b5 55 10 f0       	push   $0xf01055b5
f01016e9:	e8 b2 e9 ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01016ee:	83 ec 0c             	sub    $0xc,%esp
f01016f1:	68 80 4f 10 f0       	push   $0xf0104f80
f01016f6:	e8 25 1a 00 00       	call   f0103120 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01016fb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101702:	e8 bc f6 ff ff       	call   f0100dc3 <page_alloc>
f0101707:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010170a:	83 c4 10             	add    $0x10,%esp
f010170d:	85 c0                	test   %eax,%eax
f010170f:	75 19                	jne    f010172a <mem_init+0x5ac>
f0101711:	68 b4 56 10 f0       	push   $0xf01056b4
f0101716:	68 db 55 10 f0       	push   $0xf01055db
f010171b:	68 ad 03 00 00       	push   $0x3ad
f0101720:	68 b5 55 10 f0       	push   $0xf01055b5
f0101725:	e8 76 e9 ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010172a:	83 ec 0c             	sub    $0xc,%esp
f010172d:	6a 00                	push   $0x0
f010172f:	e8 8f f6 ff ff       	call   f0100dc3 <page_alloc>
f0101734:	89 c3                	mov    %eax,%ebx
f0101736:	83 c4 10             	add    $0x10,%esp
f0101739:	85 c0                	test   %eax,%eax
f010173b:	75 19                	jne    f0101756 <mem_init+0x5d8>
f010173d:	68 ca 56 10 f0       	push   $0xf01056ca
f0101742:	68 db 55 10 f0       	push   $0xf01055db
f0101747:	68 ae 03 00 00       	push   $0x3ae
f010174c:	68 b5 55 10 f0       	push   $0xf01055b5
f0101751:	e8 4a e9 ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101756:	83 ec 0c             	sub    $0xc,%esp
f0101759:	6a 00                	push   $0x0
f010175b:	e8 63 f6 ff ff       	call   f0100dc3 <page_alloc>
f0101760:	89 c6                	mov    %eax,%esi
f0101762:	83 c4 10             	add    $0x10,%esp
f0101765:	85 c0                	test   %eax,%eax
f0101767:	75 19                	jne    f0101782 <mem_init+0x604>
f0101769:	68 e0 56 10 f0       	push   $0xf01056e0
f010176e:	68 db 55 10 f0       	push   $0xf01055db
f0101773:	68 af 03 00 00       	push   $0x3af
f0101778:	68 b5 55 10 f0       	push   $0xf01055b5
f010177d:	e8 1e e9 ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101782:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101785:	75 19                	jne    f01017a0 <mem_init+0x622>
f0101787:	68 f6 56 10 f0       	push   $0xf01056f6
f010178c:	68 db 55 10 f0       	push   $0xf01055db
f0101791:	68 b2 03 00 00       	push   $0x3b2
f0101796:	68 b5 55 10 f0       	push   $0xf01055b5
f010179b:	e8 00 e9 ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017a0:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01017a3:	74 04                	je     f01017a9 <mem_init+0x62b>
f01017a5:	39 c3                	cmp    %eax,%ebx
f01017a7:	75 19                	jne    f01017c2 <mem_init+0x644>
f01017a9:	68 60 4f 10 f0       	push   $0xf0104f60
f01017ae:	68 db 55 10 f0       	push   $0xf01055db
f01017b3:	68 b3 03 00 00       	push   $0x3b3
f01017b8:	68 b5 55 10 f0       	push   $0xf01055b5
f01017bd:	e8 de e8 ff ff       	call   f01000a0 <_panic>
	

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01017c2:	a1 24 d2 17 f0       	mov    0xf017d224,%eax
f01017c7:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01017ca:	c7 05 24 d2 17 f0 00 	movl   $0x0,0xf017d224
f01017d1:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01017d4:	83 ec 0c             	sub    $0xc,%esp
f01017d7:	6a 00                	push   $0x0
f01017d9:	e8 e5 f5 ff ff       	call   f0100dc3 <page_alloc>
f01017de:	83 c4 10             	add    $0x10,%esp
f01017e1:	85 c0                	test   %eax,%eax
f01017e3:	74 19                	je     f01017fe <mem_init+0x680>
f01017e5:	68 5f 57 10 f0       	push   $0xf010575f
f01017ea:	68 db 55 10 f0       	push   $0xf01055db
f01017ef:	68 bb 03 00 00       	push   $0x3bb
f01017f4:	68 b5 55 10 f0       	push   $0xf01055b5
f01017f9:	e8 a2 e8 ff ff       	call   f01000a0 <_panic>
	
	
	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01017fe:	83 ec 04             	sub    $0x4,%esp
f0101801:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101804:	50                   	push   %eax
f0101805:	6a 00                	push   $0x0
f0101807:	ff 35 08 df 17 f0    	pushl  0xf017df08
f010180d:	e8 2d f8 ff ff       	call   f010103f <page_lookup>
f0101812:	83 c4 10             	add    $0x10,%esp
f0101815:	85 c0                	test   %eax,%eax
f0101817:	74 19                	je     f0101832 <mem_init+0x6b4>
f0101819:	68 a0 4f 10 f0       	push   $0xf0104fa0
f010181e:	68 db 55 10 f0       	push   $0xf01055db
f0101823:	68 bf 03 00 00       	push   $0x3bf
f0101828:	68 b5 55 10 f0       	push   $0xf01055b5
f010182d:	e8 6e e8 ff ff       	call   f01000a0 <_panic>
	
	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101832:	6a 02                	push   $0x2
f0101834:	6a 00                	push   $0x0
f0101836:	53                   	push   %ebx
f0101837:	ff 35 08 df 17 f0    	pushl  0xf017df08
f010183d:	e8 83 f8 ff ff       	call   f01010c5 <page_insert>
f0101842:	83 c4 10             	add    $0x10,%esp
f0101845:	85 c0                	test   %eax,%eax
f0101847:	78 19                	js     f0101862 <mem_init+0x6e4>
f0101849:	68 d8 4f 10 f0       	push   $0xf0104fd8
f010184e:	68 db 55 10 f0       	push   $0xf01055db
f0101853:	68 c2 03 00 00       	push   $0x3c2
f0101858:	68 b5 55 10 f0       	push   $0xf01055b5
f010185d:	e8 3e e8 ff ff       	call   f01000a0 <_panic>
	
	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101862:	83 ec 0c             	sub    $0xc,%esp
f0101865:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101868:	e8 cc f5 ff ff       	call   f0100e39 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010186d:	6a 02                	push   $0x2
f010186f:	6a 00                	push   $0x0
f0101871:	53                   	push   %ebx
f0101872:	ff 35 08 df 17 f0    	pushl  0xf017df08
f0101878:	e8 48 f8 ff ff       	call   f01010c5 <page_insert>
f010187d:	83 c4 20             	add    $0x20,%esp
f0101880:	85 c0                	test   %eax,%eax
f0101882:	74 19                	je     f010189d <mem_init+0x71f>
f0101884:	68 08 50 10 f0       	push   $0xf0105008
f0101889:	68 db 55 10 f0       	push   $0xf01055db
f010188e:	68 c6 03 00 00       	push   $0x3c6
f0101893:	68 b5 55 10 f0       	push   $0xf01055b5
f0101898:	e8 03 e8 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010189d:	8b 3d 08 df 17 f0    	mov    0xf017df08,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01018a3:	a1 0c df 17 f0       	mov    0xf017df0c,%eax
f01018a8:	89 c1                	mov    %eax,%ecx
f01018aa:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01018ad:	8b 17                	mov    (%edi),%edx
f01018af:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01018b5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01018b8:	29 c8                	sub    %ecx,%eax
f01018ba:	c1 f8 03             	sar    $0x3,%eax
f01018bd:	c1 e0 0c             	shl    $0xc,%eax
f01018c0:	39 c2                	cmp    %eax,%edx
f01018c2:	74 19                	je     f01018dd <mem_init+0x75f>
f01018c4:	68 38 50 10 f0       	push   $0xf0105038
f01018c9:	68 db 55 10 f0       	push   $0xf01055db
f01018ce:	68 c7 03 00 00       	push   $0x3c7
f01018d3:	68 b5 55 10 f0       	push   $0xf01055b5
f01018d8:	e8 c3 e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01018dd:	ba 00 00 00 00       	mov    $0x0,%edx
f01018e2:	89 f8                	mov    %edi,%eax
f01018e4:	e8 ee ef ff ff       	call   f01008d7 <check_va2pa>
f01018e9:	89 da                	mov    %ebx,%edx
f01018eb:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01018ee:	c1 fa 03             	sar    $0x3,%edx
f01018f1:	c1 e2 0c             	shl    $0xc,%edx
f01018f4:	39 d0                	cmp    %edx,%eax
f01018f6:	74 19                	je     f0101911 <mem_init+0x793>
f01018f8:	68 60 50 10 f0       	push   $0xf0105060
f01018fd:	68 db 55 10 f0       	push   $0xf01055db
f0101902:	68 c8 03 00 00       	push   $0x3c8
f0101907:	68 b5 55 10 f0       	push   $0xf01055b5
f010190c:	e8 8f e7 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101911:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101916:	74 19                	je     f0101931 <mem_init+0x7b3>
f0101918:	68 b1 57 10 f0       	push   $0xf01057b1
f010191d:	68 db 55 10 f0       	push   $0xf01055db
f0101922:	68 c9 03 00 00       	push   $0x3c9
f0101927:	68 b5 55 10 f0       	push   $0xf01055b5
f010192c:	e8 6f e7 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f0101931:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101934:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101939:	74 19                	je     f0101954 <mem_init+0x7d6>
f010193b:	68 c2 57 10 f0       	push   $0xf01057c2
f0101940:	68 db 55 10 f0       	push   $0xf01055db
f0101945:	68 ca 03 00 00       	push   $0x3ca
f010194a:	68 b5 55 10 f0       	push   $0xf01055b5
f010194f:	e8 4c e7 ff ff       	call   f01000a0 <_panic>
	
	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101954:	6a 02                	push   $0x2
f0101956:	68 00 10 00 00       	push   $0x1000
f010195b:	56                   	push   %esi
f010195c:	57                   	push   %edi
f010195d:	e8 63 f7 ff ff       	call   f01010c5 <page_insert>
f0101962:	83 c4 10             	add    $0x10,%esp
f0101965:	85 c0                	test   %eax,%eax
f0101967:	74 19                	je     f0101982 <mem_init+0x804>
f0101969:	68 90 50 10 f0       	push   $0xf0105090
f010196e:	68 db 55 10 f0       	push   $0xf01055db
f0101973:	68 cd 03 00 00       	push   $0x3cd
f0101978:	68 b5 55 10 f0       	push   $0xf01055b5
f010197d:	e8 1e e7 ff ff       	call   f01000a0 <_panic>

	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101982:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101987:	a1 08 df 17 f0       	mov    0xf017df08,%eax
f010198c:	e8 46 ef ff ff       	call   f01008d7 <check_va2pa>
f0101991:	89 f2                	mov    %esi,%edx
f0101993:	2b 15 0c df 17 f0    	sub    0xf017df0c,%edx
f0101999:	c1 fa 03             	sar    $0x3,%edx
f010199c:	c1 e2 0c             	shl    $0xc,%edx
f010199f:	39 d0                	cmp    %edx,%eax
f01019a1:	74 19                	je     f01019bc <mem_init+0x83e>
f01019a3:	68 cc 50 10 f0       	push   $0xf01050cc
f01019a8:	68 db 55 10 f0       	push   $0xf01055db
f01019ad:	68 cf 03 00 00       	push   $0x3cf
f01019b2:	68 b5 55 10 f0       	push   $0xf01055b5
f01019b7:	e8 e4 e6 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01019bc:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019c1:	74 19                	je     f01019dc <mem_init+0x85e>
f01019c3:	68 d3 57 10 f0       	push   $0xf01057d3
f01019c8:	68 db 55 10 f0       	push   $0xf01055db
f01019cd:	68 d0 03 00 00       	push   $0x3d0
f01019d2:	68 b5 55 10 f0       	push   $0xf01055b5
f01019d7:	e8 c4 e6 ff ff       	call   f01000a0 <_panic>
	
	// should be no free memory
	assert(!page_alloc(0));
f01019dc:	83 ec 0c             	sub    $0xc,%esp
f01019df:	6a 00                	push   $0x0
f01019e1:	e8 dd f3 ff ff       	call   f0100dc3 <page_alloc>
f01019e6:	83 c4 10             	add    $0x10,%esp
f01019e9:	85 c0                	test   %eax,%eax
f01019eb:	74 19                	je     f0101a06 <mem_init+0x888>
f01019ed:	68 5f 57 10 f0       	push   $0xf010575f
f01019f2:	68 db 55 10 f0       	push   $0xf01055db
f01019f7:	68 d3 03 00 00       	push   $0x3d3
f01019fc:	68 b5 55 10 f0       	push   $0xf01055b5
f0101a01:	e8 9a e6 ff ff       	call   f01000a0 <_panic>
	
	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a06:	6a 02                	push   $0x2
f0101a08:	68 00 10 00 00       	push   $0x1000
f0101a0d:	56                   	push   %esi
f0101a0e:	ff 35 08 df 17 f0    	pushl  0xf017df08
f0101a14:	e8 ac f6 ff ff       	call   f01010c5 <page_insert>
f0101a19:	83 c4 10             	add    $0x10,%esp
f0101a1c:	85 c0                	test   %eax,%eax
f0101a1e:	74 19                	je     f0101a39 <mem_init+0x8bb>
f0101a20:	68 90 50 10 f0       	push   $0xf0105090
f0101a25:	68 db 55 10 f0       	push   $0xf01055db
f0101a2a:	68 d6 03 00 00       	push   $0x3d6
f0101a2f:	68 b5 55 10 f0       	push   $0xf01055b5
f0101a34:	e8 67 e6 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a39:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a3e:	a1 08 df 17 f0       	mov    0xf017df08,%eax
f0101a43:	e8 8f ee ff ff       	call   f01008d7 <check_va2pa>
f0101a48:	89 f2                	mov    %esi,%edx
f0101a4a:	2b 15 0c df 17 f0    	sub    0xf017df0c,%edx
f0101a50:	c1 fa 03             	sar    $0x3,%edx
f0101a53:	c1 e2 0c             	shl    $0xc,%edx
f0101a56:	39 d0                	cmp    %edx,%eax
f0101a58:	74 19                	je     f0101a73 <mem_init+0x8f5>
f0101a5a:	68 cc 50 10 f0       	push   $0xf01050cc
f0101a5f:	68 db 55 10 f0       	push   $0xf01055db
f0101a64:	68 d7 03 00 00       	push   $0x3d7
f0101a69:	68 b5 55 10 f0       	push   $0xf01055b5
f0101a6e:	e8 2d e6 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101a73:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a78:	74 19                	je     f0101a93 <mem_init+0x915>
f0101a7a:	68 d3 57 10 f0       	push   $0xf01057d3
f0101a7f:	68 db 55 10 f0       	push   $0xf01055db
f0101a84:	68 d8 03 00 00       	push   $0x3d8
f0101a89:	68 b5 55 10 f0       	push   $0xf01055b5
f0101a8e:	e8 0d e6 ff ff       	call   f01000a0 <_panic>
	
	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101a93:	83 ec 0c             	sub    $0xc,%esp
f0101a96:	6a 00                	push   $0x0
f0101a98:	e8 26 f3 ff ff       	call   f0100dc3 <page_alloc>
f0101a9d:	83 c4 10             	add    $0x10,%esp
f0101aa0:	85 c0                	test   %eax,%eax
f0101aa2:	74 19                	je     f0101abd <mem_init+0x93f>
f0101aa4:	68 5f 57 10 f0       	push   $0xf010575f
f0101aa9:	68 db 55 10 f0       	push   $0xf01055db
f0101aae:	68 dc 03 00 00       	push   $0x3dc
f0101ab3:	68 b5 55 10 f0       	push   $0xf01055b5
f0101ab8:	e8 e3 e5 ff ff       	call   f01000a0 <_panic>
	
	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101abd:	8b 15 08 df 17 f0    	mov    0xf017df08,%edx
f0101ac3:	8b 02                	mov    (%edx),%eax
f0101ac5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101aca:	89 c1                	mov    %eax,%ecx
f0101acc:	c1 e9 0c             	shr    $0xc,%ecx
f0101acf:	3b 0d 04 df 17 f0    	cmp    0xf017df04,%ecx
f0101ad5:	72 15                	jb     f0101aec <mem_init+0x96e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ad7:	50                   	push   %eax
f0101ad8:	68 04 4d 10 f0       	push   $0xf0104d04
f0101add:	68 df 03 00 00       	push   $0x3df
f0101ae2:	68 b5 55 10 f0       	push   $0xf01055b5
f0101ae7:	e8 b4 e5 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0101aec:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101af1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101af4:	83 ec 04             	sub    $0x4,%esp
f0101af7:	6a 00                	push   $0x0
f0101af9:	68 00 10 00 00       	push   $0x1000
f0101afe:	52                   	push   %edx
f0101aff:	e8 ad f3 ff ff       	call   f0100eb1 <pgdir_walk>
f0101b04:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101b07:	8d 57 04             	lea    0x4(%edi),%edx
f0101b0a:	83 c4 10             	add    $0x10,%esp
f0101b0d:	39 d0                	cmp    %edx,%eax
f0101b0f:	74 19                	je     f0101b2a <mem_init+0x9ac>
f0101b11:	68 fc 50 10 f0       	push   $0xf01050fc
f0101b16:	68 db 55 10 f0       	push   $0xf01055db
f0101b1b:	68 e0 03 00 00       	push   $0x3e0
f0101b20:	68 b5 55 10 f0       	push   $0xf01055b5
f0101b25:	e8 76 e5 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101b2a:	6a 06                	push   $0x6
f0101b2c:	68 00 10 00 00       	push   $0x1000
f0101b31:	56                   	push   %esi
f0101b32:	ff 35 08 df 17 f0    	pushl  0xf017df08
f0101b38:	e8 88 f5 ff ff       	call   f01010c5 <page_insert>
f0101b3d:	83 c4 10             	add    $0x10,%esp
f0101b40:	85 c0                	test   %eax,%eax
f0101b42:	74 19                	je     f0101b5d <mem_init+0x9df>
f0101b44:	68 3c 51 10 f0       	push   $0xf010513c
f0101b49:	68 db 55 10 f0       	push   $0xf01055db
f0101b4e:	68 e3 03 00 00       	push   $0x3e3
f0101b53:	68 b5 55 10 f0       	push   $0xf01055b5
f0101b58:	e8 43 e5 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b5d:	8b 3d 08 df 17 f0    	mov    0xf017df08,%edi
f0101b63:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b68:	89 f8                	mov    %edi,%eax
f0101b6a:	e8 68 ed ff ff       	call   f01008d7 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101b6f:	89 f2                	mov    %esi,%edx
f0101b71:	2b 15 0c df 17 f0    	sub    0xf017df0c,%edx
f0101b77:	c1 fa 03             	sar    $0x3,%edx
f0101b7a:	c1 e2 0c             	shl    $0xc,%edx
f0101b7d:	39 d0                	cmp    %edx,%eax
f0101b7f:	74 19                	je     f0101b9a <mem_init+0xa1c>
f0101b81:	68 cc 50 10 f0       	push   $0xf01050cc
f0101b86:	68 db 55 10 f0       	push   $0xf01055db
f0101b8b:	68 e4 03 00 00       	push   $0x3e4
f0101b90:	68 b5 55 10 f0       	push   $0xf01055b5
f0101b95:	e8 06 e5 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101b9a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b9f:	74 19                	je     f0101bba <mem_init+0xa3c>
f0101ba1:	68 d3 57 10 f0       	push   $0xf01057d3
f0101ba6:	68 db 55 10 f0       	push   $0xf01055db
f0101bab:	68 e5 03 00 00       	push   $0x3e5
f0101bb0:	68 b5 55 10 f0       	push   $0xf01055b5
f0101bb5:	e8 e6 e4 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101bba:	83 ec 04             	sub    $0x4,%esp
f0101bbd:	6a 00                	push   $0x0
f0101bbf:	68 00 10 00 00       	push   $0x1000
f0101bc4:	57                   	push   %edi
f0101bc5:	e8 e7 f2 ff ff       	call   f0100eb1 <pgdir_walk>
f0101bca:	83 c4 10             	add    $0x10,%esp
f0101bcd:	f6 00 04             	testb  $0x4,(%eax)
f0101bd0:	75 19                	jne    f0101beb <mem_init+0xa6d>
f0101bd2:	68 7c 51 10 f0       	push   $0xf010517c
f0101bd7:	68 db 55 10 f0       	push   $0xf01055db
f0101bdc:	68 e6 03 00 00       	push   $0x3e6
f0101be1:	68 b5 55 10 f0       	push   $0xf01055b5
f0101be6:	e8 b5 e4 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101beb:	a1 08 df 17 f0       	mov    0xf017df08,%eax
f0101bf0:	f6 00 04             	testb  $0x4,(%eax)
f0101bf3:	75 19                	jne    f0101c0e <mem_init+0xa90>
f0101bf5:	68 e4 57 10 f0       	push   $0xf01057e4
f0101bfa:	68 db 55 10 f0       	push   $0xf01055db
f0101bff:	68 e7 03 00 00       	push   $0x3e7
f0101c04:	68 b5 55 10 f0       	push   $0xf01055b5
f0101c09:	e8 92 e4 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c0e:	6a 02                	push   $0x2
f0101c10:	68 00 10 00 00       	push   $0x1000
f0101c15:	56                   	push   %esi
f0101c16:	50                   	push   %eax
f0101c17:	e8 a9 f4 ff ff       	call   f01010c5 <page_insert>
f0101c1c:	83 c4 10             	add    $0x10,%esp
f0101c1f:	85 c0                	test   %eax,%eax
f0101c21:	74 19                	je     f0101c3c <mem_init+0xabe>
f0101c23:	68 90 50 10 f0       	push   $0xf0105090
f0101c28:	68 db 55 10 f0       	push   $0xf01055db
f0101c2d:	68 ea 03 00 00       	push   $0x3ea
f0101c32:	68 b5 55 10 f0       	push   $0xf01055b5
f0101c37:	e8 64 e4 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101c3c:	83 ec 04             	sub    $0x4,%esp
f0101c3f:	6a 00                	push   $0x0
f0101c41:	68 00 10 00 00       	push   $0x1000
f0101c46:	ff 35 08 df 17 f0    	pushl  0xf017df08
f0101c4c:	e8 60 f2 ff ff       	call   f0100eb1 <pgdir_walk>
f0101c51:	83 c4 10             	add    $0x10,%esp
f0101c54:	f6 00 02             	testb  $0x2,(%eax)
f0101c57:	75 19                	jne    f0101c72 <mem_init+0xaf4>
f0101c59:	68 b0 51 10 f0       	push   $0xf01051b0
f0101c5e:	68 db 55 10 f0       	push   $0xf01055db
f0101c63:	68 eb 03 00 00       	push   $0x3eb
f0101c68:	68 b5 55 10 f0       	push   $0xf01055b5
f0101c6d:	e8 2e e4 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c72:	83 ec 04             	sub    $0x4,%esp
f0101c75:	6a 00                	push   $0x0
f0101c77:	68 00 10 00 00       	push   $0x1000
f0101c7c:	ff 35 08 df 17 f0    	pushl  0xf017df08
f0101c82:	e8 2a f2 ff ff       	call   f0100eb1 <pgdir_walk>
f0101c87:	83 c4 10             	add    $0x10,%esp
f0101c8a:	f6 00 04             	testb  $0x4,(%eax)
f0101c8d:	74 19                	je     f0101ca8 <mem_init+0xb2a>
f0101c8f:	68 e4 51 10 f0       	push   $0xf01051e4
f0101c94:	68 db 55 10 f0       	push   $0xf01055db
f0101c99:	68 ec 03 00 00       	push   $0x3ec
f0101c9e:	68 b5 55 10 f0       	push   $0xf01055b5
f0101ca3:	e8 f8 e3 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101ca8:	6a 02                	push   $0x2
f0101caa:	68 00 00 40 00       	push   $0x400000
f0101caf:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101cb2:	ff 35 08 df 17 f0    	pushl  0xf017df08
f0101cb8:	e8 08 f4 ff ff       	call   f01010c5 <page_insert>
f0101cbd:	83 c4 10             	add    $0x10,%esp
f0101cc0:	85 c0                	test   %eax,%eax
f0101cc2:	78 19                	js     f0101cdd <mem_init+0xb5f>
f0101cc4:	68 1c 52 10 f0       	push   $0xf010521c
f0101cc9:	68 db 55 10 f0       	push   $0xf01055db
f0101cce:	68 ef 03 00 00       	push   $0x3ef
f0101cd3:	68 b5 55 10 f0       	push   $0xf01055b5
f0101cd8:	e8 c3 e3 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101cdd:	6a 02                	push   $0x2
f0101cdf:	68 00 10 00 00       	push   $0x1000
f0101ce4:	53                   	push   %ebx
f0101ce5:	ff 35 08 df 17 f0    	pushl  0xf017df08
f0101ceb:	e8 d5 f3 ff ff       	call   f01010c5 <page_insert>
f0101cf0:	83 c4 10             	add    $0x10,%esp
f0101cf3:	85 c0                	test   %eax,%eax
f0101cf5:	74 19                	je     f0101d10 <mem_init+0xb92>
f0101cf7:	68 54 52 10 f0       	push   $0xf0105254
f0101cfc:	68 db 55 10 f0       	push   $0xf01055db
f0101d01:	68 f2 03 00 00       	push   $0x3f2
f0101d06:	68 b5 55 10 f0       	push   $0xf01055b5
f0101d0b:	e8 90 e3 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d10:	83 ec 04             	sub    $0x4,%esp
f0101d13:	6a 00                	push   $0x0
f0101d15:	68 00 10 00 00       	push   $0x1000
f0101d1a:	ff 35 08 df 17 f0    	pushl  0xf017df08
f0101d20:	e8 8c f1 ff ff       	call   f0100eb1 <pgdir_walk>
f0101d25:	83 c4 10             	add    $0x10,%esp
f0101d28:	f6 00 04             	testb  $0x4,(%eax)
f0101d2b:	74 19                	je     f0101d46 <mem_init+0xbc8>
f0101d2d:	68 e4 51 10 f0       	push   $0xf01051e4
f0101d32:	68 db 55 10 f0       	push   $0xf01055db
f0101d37:	68 f3 03 00 00       	push   $0x3f3
f0101d3c:	68 b5 55 10 f0       	push   $0xf01055b5
f0101d41:	e8 5a e3 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101d46:	8b 3d 08 df 17 f0    	mov    0xf017df08,%edi
f0101d4c:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d51:	89 f8                	mov    %edi,%eax
f0101d53:	e8 7f eb ff ff       	call   f01008d7 <check_va2pa>
f0101d58:	89 c1                	mov    %eax,%ecx
f0101d5a:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101d5d:	89 d8                	mov    %ebx,%eax
f0101d5f:	2b 05 0c df 17 f0    	sub    0xf017df0c,%eax
f0101d65:	c1 f8 03             	sar    $0x3,%eax
f0101d68:	c1 e0 0c             	shl    $0xc,%eax
f0101d6b:	39 c1                	cmp    %eax,%ecx
f0101d6d:	74 19                	je     f0101d88 <mem_init+0xc0a>
f0101d6f:	68 90 52 10 f0       	push   $0xf0105290
f0101d74:	68 db 55 10 f0       	push   $0xf01055db
f0101d79:	68 f6 03 00 00       	push   $0x3f6
f0101d7e:	68 b5 55 10 f0       	push   $0xf01055b5
f0101d83:	e8 18 e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d88:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d8d:	89 f8                	mov    %edi,%eax
f0101d8f:	e8 43 eb ff ff       	call   f01008d7 <check_va2pa>
f0101d94:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101d97:	74 19                	je     f0101db2 <mem_init+0xc34>
f0101d99:	68 bc 52 10 f0       	push   $0xf01052bc
f0101d9e:	68 db 55 10 f0       	push   $0xf01055db
f0101da3:	68 f7 03 00 00       	push   $0x3f7
f0101da8:	68 b5 55 10 f0       	push   $0xf01055b5
f0101dad:	e8 ee e2 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101db2:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101db7:	74 19                	je     f0101dd2 <mem_init+0xc54>
f0101db9:	68 fa 57 10 f0       	push   $0xf01057fa
f0101dbe:	68 db 55 10 f0       	push   $0xf01055db
f0101dc3:	68 f9 03 00 00       	push   $0x3f9
f0101dc8:	68 b5 55 10 f0       	push   $0xf01055b5
f0101dcd:	e8 ce e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101dd2:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101dd7:	74 19                	je     f0101df2 <mem_init+0xc74>
f0101dd9:	68 0b 58 10 f0       	push   $0xf010580b
f0101dde:	68 db 55 10 f0       	push   $0xf01055db
f0101de3:	68 fa 03 00 00       	push   $0x3fa
f0101de8:	68 b5 55 10 f0       	push   $0xf01055b5
f0101ded:	e8 ae e2 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101df2:	83 ec 0c             	sub    $0xc,%esp
f0101df5:	6a 00                	push   $0x0
f0101df7:	e8 c7 ef ff ff       	call   f0100dc3 <page_alloc>
f0101dfc:	83 c4 10             	add    $0x10,%esp
f0101dff:	85 c0                	test   %eax,%eax
f0101e01:	74 04                	je     f0101e07 <mem_init+0xc89>
f0101e03:	39 c6                	cmp    %eax,%esi
f0101e05:	74 19                	je     f0101e20 <mem_init+0xca2>
f0101e07:	68 ec 52 10 f0       	push   $0xf01052ec
f0101e0c:	68 db 55 10 f0       	push   $0xf01055db
f0101e11:	68 fd 03 00 00       	push   $0x3fd
f0101e16:	68 b5 55 10 f0       	push   $0xf01055b5
f0101e1b:	e8 80 e2 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101e20:	83 ec 08             	sub    $0x8,%esp
f0101e23:	6a 00                	push   $0x0
f0101e25:	ff 35 08 df 17 f0    	pushl  0xf017df08
f0101e2b:	e8 5a f2 ff ff       	call   f010108a <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e30:	8b 3d 08 df 17 f0    	mov    0xf017df08,%edi
f0101e36:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e3b:	89 f8                	mov    %edi,%eax
f0101e3d:	e8 95 ea ff ff       	call   f01008d7 <check_va2pa>
f0101e42:	83 c4 10             	add    $0x10,%esp
f0101e45:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e48:	74 19                	je     f0101e63 <mem_init+0xce5>
f0101e4a:	68 10 53 10 f0       	push   $0xf0105310
f0101e4f:	68 db 55 10 f0       	push   $0xf01055db
f0101e54:	68 01 04 00 00       	push   $0x401
f0101e59:	68 b5 55 10 f0       	push   $0xf01055b5
f0101e5e:	e8 3d e2 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e63:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e68:	89 f8                	mov    %edi,%eax
f0101e6a:	e8 68 ea ff ff       	call   f01008d7 <check_va2pa>
f0101e6f:	89 da                	mov    %ebx,%edx
f0101e71:	2b 15 0c df 17 f0    	sub    0xf017df0c,%edx
f0101e77:	c1 fa 03             	sar    $0x3,%edx
f0101e7a:	c1 e2 0c             	shl    $0xc,%edx
f0101e7d:	39 d0                	cmp    %edx,%eax
f0101e7f:	74 19                	je     f0101e9a <mem_init+0xd1c>
f0101e81:	68 bc 52 10 f0       	push   $0xf01052bc
f0101e86:	68 db 55 10 f0       	push   $0xf01055db
f0101e8b:	68 02 04 00 00       	push   $0x402
f0101e90:	68 b5 55 10 f0       	push   $0xf01055b5
f0101e95:	e8 06 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101e9a:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101e9f:	74 19                	je     f0101eba <mem_init+0xd3c>
f0101ea1:	68 b1 57 10 f0       	push   $0xf01057b1
f0101ea6:	68 db 55 10 f0       	push   $0xf01055db
f0101eab:	68 03 04 00 00       	push   $0x403
f0101eb0:	68 b5 55 10 f0       	push   $0xf01055b5
f0101eb5:	e8 e6 e1 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101eba:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ebf:	74 19                	je     f0101eda <mem_init+0xd5c>
f0101ec1:	68 0b 58 10 f0       	push   $0xf010580b
f0101ec6:	68 db 55 10 f0       	push   $0xf01055db
f0101ecb:	68 04 04 00 00       	push   $0x404
f0101ed0:	68 b5 55 10 f0       	push   $0xf01055b5
f0101ed5:	e8 c6 e1 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101eda:	6a 00                	push   $0x0
f0101edc:	68 00 10 00 00       	push   $0x1000
f0101ee1:	53                   	push   %ebx
f0101ee2:	57                   	push   %edi
f0101ee3:	e8 dd f1 ff ff       	call   f01010c5 <page_insert>
f0101ee8:	83 c4 10             	add    $0x10,%esp
f0101eeb:	85 c0                	test   %eax,%eax
f0101eed:	74 19                	je     f0101f08 <mem_init+0xd8a>
f0101eef:	68 34 53 10 f0       	push   $0xf0105334
f0101ef4:	68 db 55 10 f0       	push   $0xf01055db
f0101ef9:	68 07 04 00 00       	push   $0x407
f0101efe:	68 b5 55 10 f0       	push   $0xf01055b5
f0101f03:	e8 98 e1 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101f08:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101f0d:	75 19                	jne    f0101f28 <mem_init+0xdaa>
f0101f0f:	68 1c 58 10 f0       	push   $0xf010581c
f0101f14:	68 db 55 10 f0       	push   $0xf01055db
f0101f19:	68 08 04 00 00       	push   $0x408
f0101f1e:	68 b5 55 10 f0       	push   $0xf01055b5
f0101f23:	e8 78 e1 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101f28:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101f2b:	74 19                	je     f0101f46 <mem_init+0xdc8>
f0101f2d:	68 28 58 10 f0       	push   $0xf0105828
f0101f32:	68 db 55 10 f0       	push   $0xf01055db
f0101f37:	68 09 04 00 00       	push   $0x409
f0101f3c:	68 b5 55 10 f0       	push   $0xf01055b5
f0101f41:	e8 5a e1 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101f46:	83 ec 08             	sub    $0x8,%esp
f0101f49:	68 00 10 00 00       	push   $0x1000
f0101f4e:	ff 35 08 df 17 f0    	pushl  0xf017df08
f0101f54:	e8 31 f1 ff ff       	call   f010108a <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f59:	8b 3d 08 df 17 f0    	mov    0xf017df08,%edi
f0101f5f:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f64:	89 f8                	mov    %edi,%eax
f0101f66:	e8 6c e9 ff ff       	call   f01008d7 <check_va2pa>
f0101f6b:	83 c4 10             	add    $0x10,%esp
f0101f6e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f71:	74 19                	je     f0101f8c <mem_init+0xe0e>
f0101f73:	68 10 53 10 f0       	push   $0xf0105310
f0101f78:	68 db 55 10 f0       	push   $0xf01055db
f0101f7d:	68 0d 04 00 00       	push   $0x40d
f0101f82:	68 b5 55 10 f0       	push   $0xf01055b5
f0101f87:	e8 14 e1 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101f8c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f91:	89 f8                	mov    %edi,%eax
f0101f93:	e8 3f e9 ff ff       	call   f01008d7 <check_va2pa>
f0101f98:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f9b:	74 19                	je     f0101fb6 <mem_init+0xe38>
f0101f9d:	68 6c 53 10 f0       	push   $0xf010536c
f0101fa2:	68 db 55 10 f0       	push   $0xf01055db
f0101fa7:	68 0e 04 00 00       	push   $0x40e
f0101fac:	68 b5 55 10 f0       	push   $0xf01055b5
f0101fb1:	e8 ea e0 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101fb6:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101fbb:	74 19                	je     f0101fd6 <mem_init+0xe58>
f0101fbd:	68 3d 58 10 f0       	push   $0xf010583d
f0101fc2:	68 db 55 10 f0       	push   $0xf01055db
f0101fc7:	68 0f 04 00 00       	push   $0x40f
f0101fcc:	68 b5 55 10 f0       	push   $0xf01055b5
f0101fd1:	e8 ca e0 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101fd6:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101fdb:	74 19                	je     f0101ff6 <mem_init+0xe78>
f0101fdd:	68 0b 58 10 f0       	push   $0xf010580b
f0101fe2:	68 db 55 10 f0       	push   $0xf01055db
f0101fe7:	68 10 04 00 00       	push   $0x410
f0101fec:	68 b5 55 10 f0       	push   $0xf01055b5
f0101ff1:	e8 aa e0 ff ff       	call   f01000a0 <_panic>
	
	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101ff6:	83 ec 0c             	sub    $0xc,%esp
f0101ff9:	6a 00                	push   $0x0
f0101ffb:	e8 c3 ed ff ff       	call   f0100dc3 <page_alloc>
f0102000:	83 c4 10             	add    $0x10,%esp
f0102003:	85 c0                	test   %eax,%eax
f0102005:	74 04                	je     f010200b <mem_init+0xe8d>
f0102007:	39 c3                	cmp    %eax,%ebx
f0102009:	74 19                	je     f0102024 <mem_init+0xea6>
f010200b:	68 94 53 10 f0       	push   $0xf0105394
f0102010:	68 db 55 10 f0       	push   $0xf01055db
f0102015:	68 13 04 00 00       	push   $0x413
f010201a:	68 b5 55 10 f0       	push   $0xf01055b5
f010201f:	e8 7c e0 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102024:	83 ec 0c             	sub    $0xc,%esp
f0102027:	6a 00                	push   $0x0
f0102029:	e8 95 ed ff ff       	call   f0100dc3 <page_alloc>
f010202e:	83 c4 10             	add    $0x10,%esp
f0102031:	85 c0                	test   %eax,%eax
f0102033:	74 19                	je     f010204e <mem_init+0xed0>
f0102035:	68 5f 57 10 f0       	push   $0xf010575f
f010203a:	68 db 55 10 f0       	push   $0xf01055db
f010203f:	68 16 04 00 00       	push   $0x416
f0102044:	68 b5 55 10 f0       	push   $0xf01055b5
f0102049:	e8 52 e0 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010204e:	8b 0d 08 df 17 f0    	mov    0xf017df08,%ecx
f0102054:	8b 11                	mov    (%ecx),%edx
f0102056:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010205c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010205f:	2b 05 0c df 17 f0    	sub    0xf017df0c,%eax
f0102065:	c1 f8 03             	sar    $0x3,%eax
f0102068:	c1 e0 0c             	shl    $0xc,%eax
f010206b:	39 c2                	cmp    %eax,%edx
f010206d:	74 19                	je     f0102088 <mem_init+0xf0a>
f010206f:	68 38 50 10 f0       	push   $0xf0105038
f0102074:	68 db 55 10 f0       	push   $0xf01055db
f0102079:	68 19 04 00 00       	push   $0x419
f010207e:	68 b5 55 10 f0       	push   $0xf01055b5
f0102083:	e8 18 e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0102088:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010208e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102091:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102096:	74 19                	je     f01020b1 <mem_init+0xf33>
f0102098:	68 c2 57 10 f0       	push   $0xf01057c2
f010209d:	68 db 55 10 f0       	push   $0xf01055db
f01020a2:	68 1b 04 00 00       	push   $0x41b
f01020a7:	68 b5 55 10 f0       	push   $0xf01055b5
f01020ac:	e8 ef df ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f01020b1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020b4:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01020ba:	83 ec 0c             	sub    $0xc,%esp
f01020bd:	50                   	push   %eax
f01020be:	e8 76 ed ff ff       	call   f0100e39 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01020c3:	83 c4 0c             	add    $0xc,%esp
f01020c6:	6a 01                	push   $0x1
f01020c8:	68 00 10 40 00       	push   $0x401000
f01020cd:	ff 35 08 df 17 f0    	pushl  0xf017df08
f01020d3:	e8 d9 ed ff ff       	call   f0100eb1 <pgdir_walk>
f01020d8:	89 c7                	mov    %eax,%edi
f01020da:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01020dd:	a1 08 df 17 f0       	mov    0xf017df08,%eax
f01020e2:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01020e5:	8b 40 04             	mov    0x4(%eax),%eax
f01020e8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01020ed:	8b 0d 04 df 17 f0    	mov    0xf017df04,%ecx
f01020f3:	89 c2                	mov    %eax,%edx
f01020f5:	c1 ea 0c             	shr    $0xc,%edx
f01020f8:	83 c4 10             	add    $0x10,%esp
f01020fb:	39 ca                	cmp    %ecx,%edx
f01020fd:	72 15                	jb     f0102114 <mem_init+0xf96>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01020ff:	50                   	push   %eax
f0102100:	68 04 4d 10 f0       	push   $0xf0104d04
f0102105:	68 22 04 00 00       	push   $0x422
f010210a:	68 b5 55 10 f0       	push   $0xf01055b5
f010210f:	e8 8c df ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102114:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0102119:	39 c7                	cmp    %eax,%edi
f010211b:	74 19                	je     f0102136 <mem_init+0xfb8>
f010211d:	68 4e 58 10 f0       	push   $0xf010584e
f0102122:	68 db 55 10 f0       	push   $0xf01055db
f0102127:	68 23 04 00 00       	push   $0x423
f010212c:	68 b5 55 10 f0       	push   $0xf01055b5
f0102131:	e8 6a df ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102136:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102139:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102140:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102143:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102149:	2b 05 0c df 17 f0    	sub    0xf017df0c,%eax
f010214f:	c1 f8 03             	sar    $0x3,%eax
f0102152:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102155:	89 c2                	mov    %eax,%edx
f0102157:	c1 ea 0c             	shr    $0xc,%edx
f010215a:	39 d1                	cmp    %edx,%ecx
f010215c:	77 12                	ja     f0102170 <mem_init+0xff2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010215e:	50                   	push   %eax
f010215f:	68 04 4d 10 f0       	push   $0xf0104d04
f0102164:	6a 56                	push   $0x56
f0102166:	68 c1 55 10 f0       	push   $0xf01055c1
f010216b:	e8 30 df ff ff       	call   f01000a0 <_panic>
	
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102170:	83 ec 04             	sub    $0x4,%esp
f0102173:	68 00 10 00 00       	push   $0x1000
f0102178:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f010217d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102182:	50                   	push   %eax
f0102183:	e8 60 21 00 00       	call   f01042e8 <memset>
	page_free(pp0);
f0102188:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010218b:	89 3c 24             	mov    %edi,(%esp)
f010218e:	e8 a6 ec ff ff       	call   f0100e39 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102193:	83 c4 0c             	add    $0xc,%esp
f0102196:	6a 01                	push   $0x1
f0102198:	6a 00                	push   $0x0
f010219a:	ff 35 08 df 17 f0    	pushl  0xf017df08
f01021a0:	e8 0c ed ff ff       	call   f0100eb1 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01021a5:	89 fa                	mov    %edi,%edx
f01021a7:	2b 15 0c df 17 f0    	sub    0xf017df0c,%edx
f01021ad:	c1 fa 03             	sar    $0x3,%edx
f01021b0:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01021b3:	89 d0                	mov    %edx,%eax
f01021b5:	c1 e8 0c             	shr    $0xc,%eax
f01021b8:	83 c4 10             	add    $0x10,%esp
f01021bb:	3b 05 04 df 17 f0    	cmp    0xf017df04,%eax
f01021c1:	72 12                	jb     f01021d5 <mem_init+0x1057>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01021c3:	52                   	push   %edx
f01021c4:	68 04 4d 10 f0       	push   $0xf0104d04
f01021c9:	6a 56                	push   $0x56
f01021cb:	68 c1 55 10 f0       	push   $0xf01055c1
f01021d0:	e8 cb de ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f01021d5:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01021db:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01021de:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01021e4:	f6 00 01             	testb  $0x1,(%eax)
f01021e7:	74 19                	je     f0102202 <mem_init+0x1084>
f01021e9:	68 66 58 10 f0       	push   $0xf0105866
f01021ee:	68 db 55 10 f0       	push   $0xf01055db
f01021f3:	68 2d 04 00 00       	push   $0x42d
f01021f8:	68 b5 55 10 f0       	push   $0xf01055b5
f01021fd:	e8 9e de ff ff       	call   f01000a0 <_panic>
f0102202:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102205:	39 d0                	cmp    %edx,%eax
f0102207:	75 db                	jne    f01021e4 <mem_init+0x1066>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102209:	a1 08 df 17 f0       	mov    0xf017df08,%eax
f010220e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102214:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102217:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010221d:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0102220:	89 3d 24 d2 17 f0    	mov    %edi,0xf017d224

	// free the pages we took
	page_free(pp0);
f0102226:	83 ec 0c             	sub    $0xc,%esp
f0102229:	50                   	push   %eax
f010222a:	e8 0a ec ff ff       	call   f0100e39 <page_free>
	page_free(pp1);
f010222f:	89 1c 24             	mov    %ebx,(%esp)
f0102232:	e8 02 ec ff ff       	call   f0100e39 <page_free>
	page_free(pp2);
f0102237:	89 34 24             	mov    %esi,(%esp)
f010223a:	e8 fa eb ff ff       	call   f0100e39 <page_free>

	cprintf("check_page() succeeded!\n");
f010223f:	c7 04 24 7d 58 10 f0 	movl   $0xf010587d,(%esp)
f0102246:	e8 d5 0e 00 00       	call   f0103120 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, ROUNDUP( (sizeof(struct PageInfo)*npages),PGSIZE), PADDR(pages), PTE_U | PTE_P);
f010224b:	a1 0c df 17 f0       	mov    0xf017df0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102250:	83 c4 10             	add    $0x10,%esp
f0102253:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102258:	77 15                	ja     f010226f <mem_init+0x10f1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010225a:	50                   	push   %eax
f010225b:	68 28 4d 10 f0       	push   $0xf0104d28
f0102260:	68 c3 00 00 00       	push   $0xc3
f0102265:	68 b5 55 10 f0       	push   $0xf01055b5
f010226a:	e8 31 de ff ff       	call   f01000a0 <_panic>
f010226f:	8b 15 04 df 17 f0    	mov    0xf017df04,%edx
f0102275:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f010227c:	83 ec 08             	sub    $0x8,%esp
f010227f:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102285:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f0102287:	05 00 00 00 10       	add    $0x10000000,%eax
f010228c:	50                   	push   %eax
f010228d:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102292:	a1 08 df 17 f0       	mov    0xf017df08,%eax
f0102297:	e8 00 ed ff ff       	call   f0100f9c <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, sizeof(struct Env) * NENV,PADDR(envs), PTE_U);
f010229c:	a1 30 d2 17 f0       	mov    0xf017d230,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01022a1:	83 c4 10             	add    $0x10,%esp
f01022a4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01022a9:	77 15                	ja     f01022c0 <mem_init+0x1142>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01022ab:	50                   	push   %eax
f01022ac:	68 28 4d 10 f0       	push   $0xf0104d28
f01022b1:	68 cb 00 00 00       	push   $0xcb
f01022b6:	68 b5 55 10 f0       	push   $0xf01055b5
f01022bb:	e8 e0 dd ff ff       	call   f01000a0 <_panic>
f01022c0:	83 ec 08             	sub    $0x8,%esp
f01022c3:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f01022c5:	05 00 00 00 10       	add    $0x10000000,%eax
f01022ca:	50                   	push   %eax
f01022cb:	b9 00 80 01 00       	mov    $0x18000,%ecx
f01022d0:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01022d5:	a1 08 df 17 f0       	mov    0xf017df08,%eax
f01022da:	e8 bd ec ff ff       	call   f0100f9c <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01022df:	83 c4 10             	add    $0x10,%esp
f01022e2:	b8 00 10 11 f0       	mov    $0xf0111000,%eax
f01022e7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01022ec:	77 15                	ja     f0102303 <mem_init+0x1185>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01022ee:	50                   	push   %eax
f01022ef:	68 28 4d 10 f0       	push   $0xf0104d28
f01022f4:	68 d7 00 00 00       	push   $0xd7
f01022f9:	68 b5 55 10 f0       	push   $0xf01055b5
f01022fe:	e8 9d dd ff ff       	call   f01000a0 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W | PTE_P);
f0102303:	83 ec 08             	sub    $0x8,%esp
f0102306:	6a 03                	push   $0x3
f0102308:	68 00 10 11 00       	push   $0x111000
f010230d:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102312:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102317:	a1 08 df 17 f0       	mov    0xf017df08,%eax
f010231c:	e8 7b ec ff ff       	call   f0100f9c <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	size_t size = ROUNDUP(0xFFFFFFFF - KERNBASE + 1, PGSIZE);
	boot_map_region(kern_pgdir, KERNBASE, size, 0, PTE_W | PTE_P);
f0102321:	83 c4 08             	add    $0x8,%esp
f0102324:	6a 03                	push   $0x3
f0102326:	6a 00                	push   $0x0
f0102328:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f010232d:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102332:	a1 08 df 17 f0       	mov    0xf017df08,%eax
f0102337:	e8 60 ec ff ff       	call   f0100f9c <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010233c:	8b 1d 08 df 17 f0    	mov    0xf017df08,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102342:	a1 04 df 17 f0       	mov    0xf017df04,%eax
f0102347:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010234a:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102351:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102356:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102359:	8b 3d 0c df 17 f0    	mov    0xf017df0c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010235f:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102362:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102365:	be 00 00 00 00       	mov    $0x0,%esi
f010236a:	eb 55                	jmp    f01023c1 <mem_init+0x1243>
f010236c:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102372:	89 d8                	mov    %ebx,%eax
f0102374:	e8 5e e5 ff ff       	call   f01008d7 <check_va2pa>
f0102379:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102380:	77 15                	ja     f0102397 <mem_init+0x1219>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102382:	57                   	push   %edi
f0102383:	68 28 4d 10 f0       	push   $0xf0104d28
f0102388:	68 67 03 00 00       	push   $0x367
f010238d:	68 b5 55 10 f0       	push   $0xf01055b5
f0102392:	e8 09 dd ff ff       	call   f01000a0 <_panic>
f0102397:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f010239e:	39 c2                	cmp    %eax,%edx
f01023a0:	74 19                	je     f01023bb <mem_init+0x123d>
f01023a2:	68 b8 53 10 f0       	push   $0xf01053b8
f01023a7:	68 db 55 10 f0       	push   $0xf01055db
f01023ac:	68 67 03 00 00       	push   $0x367
f01023b1:	68 b5 55 10 f0       	push   $0xf01055b5
f01023b6:	e8 e5 dc ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01023bb:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01023c1:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f01023c4:	77 a6                	ja     f010236c <mem_init+0x11ee>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01023c6:	8b 3d 30 d2 17 f0    	mov    0xf017d230,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01023cc:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01023cf:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f01023d4:	89 f2                	mov    %esi,%edx
f01023d6:	89 d8                	mov    %ebx,%eax
f01023d8:	e8 fa e4 ff ff       	call   f01008d7 <check_va2pa>
f01023dd:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f01023e4:	77 15                	ja     f01023fb <mem_init+0x127d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01023e6:	57                   	push   %edi
f01023e7:	68 28 4d 10 f0       	push   $0xf0104d28
f01023ec:	68 6c 03 00 00       	push   $0x36c
f01023f1:	68 b5 55 10 f0       	push   $0xf01055b5
f01023f6:	e8 a5 dc ff ff       	call   f01000a0 <_panic>
f01023fb:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f0102402:	39 c2                	cmp    %eax,%edx
f0102404:	74 19                	je     f010241f <mem_init+0x12a1>
f0102406:	68 ec 53 10 f0       	push   $0xf01053ec
f010240b:	68 db 55 10 f0       	push   $0xf01055db
f0102410:	68 6c 03 00 00       	push   $0x36c
f0102415:	68 b5 55 10 f0       	push   $0xf01055b5
f010241a:	e8 81 dc ff ff       	call   f01000a0 <_panic>
f010241f:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102425:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f010242b:	75 a7                	jne    f01023d4 <mem_init+0x1256>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010242d:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102430:	c1 e7 0c             	shl    $0xc,%edi
f0102433:	be 00 00 00 00       	mov    $0x0,%esi
f0102438:	eb 30                	jmp    f010246a <mem_init+0x12ec>
f010243a:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102440:	89 d8                	mov    %ebx,%eax
f0102442:	e8 90 e4 ff ff       	call   f01008d7 <check_va2pa>
f0102447:	39 c6                	cmp    %eax,%esi
f0102449:	74 19                	je     f0102464 <mem_init+0x12e6>
f010244b:	68 20 54 10 f0       	push   $0xf0105420
f0102450:	68 db 55 10 f0       	push   $0xf01055db
f0102455:	68 70 03 00 00       	push   $0x370
f010245a:	68 b5 55 10 f0       	push   $0xf01055b5
f010245f:	e8 3c dc ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102464:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010246a:	39 fe                	cmp    %edi,%esi
f010246c:	72 cc                	jb     f010243a <mem_init+0x12bc>
f010246e:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102473:	89 f2                	mov    %esi,%edx
f0102475:	89 d8                	mov    %ebx,%eax
f0102477:	e8 5b e4 ff ff       	call   f01008d7 <check_va2pa>
f010247c:	8d 96 00 90 11 10    	lea    0x10119000(%esi),%edx
f0102482:	39 c2                	cmp    %eax,%edx
f0102484:	74 19                	je     f010249f <mem_init+0x1321>
f0102486:	68 48 54 10 f0       	push   $0xf0105448
f010248b:	68 db 55 10 f0       	push   $0xf01055db
f0102490:	68 74 03 00 00       	push   $0x374
f0102495:	68 b5 55 10 f0       	push   $0xf01055b5
f010249a:	e8 01 dc ff ff       	call   f01000a0 <_panic>
f010249f:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01024a5:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f01024ab:	75 c6                	jne    f0102473 <mem_init+0x12f5>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01024ad:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01024b2:	89 d8                	mov    %ebx,%eax
f01024b4:	e8 1e e4 ff ff       	call   f01008d7 <check_va2pa>
f01024b9:	83 f8 ff             	cmp    $0xffffffff,%eax
f01024bc:	74 51                	je     f010250f <mem_init+0x1391>
f01024be:	68 90 54 10 f0       	push   $0xf0105490
f01024c3:	68 db 55 10 f0       	push   $0xf01055db
f01024c8:	68 75 03 00 00       	push   $0x375
f01024cd:	68 b5 55 10 f0       	push   $0xf01055b5
f01024d2:	e8 c9 db ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01024d7:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01024dc:	72 36                	jb     f0102514 <mem_init+0x1396>
f01024de:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01024e3:	76 07                	jbe    f01024ec <mem_init+0x136e>
f01024e5:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01024ea:	75 28                	jne    f0102514 <mem_init+0x1396>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f01024ec:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f01024f0:	0f 85 83 00 00 00    	jne    f0102579 <mem_init+0x13fb>
f01024f6:	68 96 58 10 f0       	push   $0xf0105896
f01024fb:	68 db 55 10 f0       	push   $0xf01055db
f0102500:	68 7e 03 00 00       	push   $0x37e
f0102505:	68 b5 55 10 f0       	push   $0xf01055b5
f010250a:	e8 91 db ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010250f:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102514:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102519:	76 3f                	jbe    f010255a <mem_init+0x13dc>
				assert(pgdir[i] & PTE_P);
f010251b:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f010251e:	f6 c2 01             	test   $0x1,%dl
f0102521:	75 19                	jne    f010253c <mem_init+0x13be>
f0102523:	68 96 58 10 f0       	push   $0xf0105896
f0102528:	68 db 55 10 f0       	push   $0xf01055db
f010252d:	68 82 03 00 00       	push   $0x382
f0102532:	68 b5 55 10 f0       	push   $0xf01055b5
f0102537:	e8 64 db ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f010253c:	f6 c2 02             	test   $0x2,%dl
f010253f:	75 38                	jne    f0102579 <mem_init+0x13fb>
f0102541:	68 a7 58 10 f0       	push   $0xf01058a7
f0102546:	68 db 55 10 f0       	push   $0xf01055db
f010254b:	68 83 03 00 00       	push   $0x383
f0102550:	68 b5 55 10 f0       	push   $0xf01055b5
f0102555:	e8 46 db ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f010255a:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f010255e:	74 19                	je     f0102579 <mem_init+0x13fb>
f0102560:	68 b8 58 10 f0       	push   $0xf01058b8
f0102565:	68 db 55 10 f0       	push   $0xf01055db
f010256a:	68 85 03 00 00       	push   $0x385
f010256f:	68 b5 55 10 f0       	push   $0xf01055b5
f0102574:	e8 27 db ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102579:	83 c0 01             	add    $0x1,%eax
f010257c:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102581:	0f 86 50 ff ff ff    	jbe    f01024d7 <mem_init+0x1359>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102587:	83 ec 0c             	sub    $0xc,%esp
f010258a:	68 c0 54 10 f0       	push   $0xf01054c0
f010258f:	e8 8c 0b 00 00       	call   f0103120 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102594:	a1 08 df 17 f0       	mov    0xf017df08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102599:	83 c4 10             	add    $0x10,%esp
f010259c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01025a1:	77 15                	ja     f01025b8 <mem_init+0x143a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025a3:	50                   	push   %eax
f01025a4:	68 28 4d 10 f0       	push   $0xf0104d28
f01025a9:	68 ec 00 00 00       	push   $0xec
f01025ae:	68 b5 55 10 f0       	push   $0xf01055b5
f01025b3:	e8 e8 da ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01025b8:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01025bd:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01025c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01025c5:	e8 e7 e3 ff ff       	call   f01009b1 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01025ca:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f01025cd:	83 e0 f3             	and    $0xfffffff3,%eax
f01025d0:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01025d5:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01025d8:	83 ec 0c             	sub    $0xc,%esp
f01025db:	6a 00                	push   $0x0
f01025dd:	e8 e1 e7 ff ff       	call   f0100dc3 <page_alloc>
f01025e2:	89 c3                	mov    %eax,%ebx
f01025e4:	83 c4 10             	add    $0x10,%esp
f01025e7:	85 c0                	test   %eax,%eax
f01025e9:	75 19                	jne    f0102604 <mem_init+0x1486>
f01025eb:	68 b4 56 10 f0       	push   $0xf01056b4
f01025f0:	68 db 55 10 f0       	push   $0xf01055db
f01025f5:	68 48 04 00 00       	push   $0x448
f01025fa:	68 b5 55 10 f0       	push   $0xf01055b5
f01025ff:	e8 9c da ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0102604:	83 ec 0c             	sub    $0xc,%esp
f0102607:	6a 00                	push   $0x0
f0102609:	e8 b5 e7 ff ff       	call   f0100dc3 <page_alloc>
f010260e:	89 c7                	mov    %eax,%edi
f0102610:	83 c4 10             	add    $0x10,%esp
f0102613:	85 c0                	test   %eax,%eax
f0102615:	75 19                	jne    f0102630 <mem_init+0x14b2>
f0102617:	68 ca 56 10 f0       	push   $0xf01056ca
f010261c:	68 db 55 10 f0       	push   $0xf01055db
f0102621:	68 49 04 00 00       	push   $0x449
f0102626:	68 b5 55 10 f0       	push   $0xf01055b5
f010262b:	e8 70 da ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0102630:	83 ec 0c             	sub    $0xc,%esp
f0102633:	6a 00                	push   $0x0
f0102635:	e8 89 e7 ff ff       	call   f0100dc3 <page_alloc>
f010263a:	89 c6                	mov    %eax,%esi
f010263c:	83 c4 10             	add    $0x10,%esp
f010263f:	85 c0                	test   %eax,%eax
f0102641:	75 19                	jne    f010265c <mem_init+0x14de>
f0102643:	68 e0 56 10 f0       	push   $0xf01056e0
f0102648:	68 db 55 10 f0       	push   $0xf01055db
f010264d:	68 4a 04 00 00       	push   $0x44a
f0102652:	68 b5 55 10 f0       	push   $0xf01055b5
f0102657:	e8 44 da ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f010265c:	83 ec 0c             	sub    $0xc,%esp
f010265f:	53                   	push   %ebx
f0102660:	e8 d4 e7 ff ff       	call   f0100e39 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102665:	89 f8                	mov    %edi,%eax
f0102667:	2b 05 0c df 17 f0    	sub    0xf017df0c,%eax
f010266d:	c1 f8 03             	sar    $0x3,%eax
f0102670:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102673:	89 c2                	mov    %eax,%edx
f0102675:	c1 ea 0c             	shr    $0xc,%edx
f0102678:	83 c4 10             	add    $0x10,%esp
f010267b:	3b 15 04 df 17 f0    	cmp    0xf017df04,%edx
f0102681:	72 12                	jb     f0102695 <mem_init+0x1517>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102683:	50                   	push   %eax
f0102684:	68 04 4d 10 f0       	push   $0xf0104d04
f0102689:	6a 56                	push   $0x56
f010268b:	68 c1 55 10 f0       	push   $0xf01055c1
f0102690:	e8 0b da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102695:	83 ec 04             	sub    $0x4,%esp
f0102698:	68 00 10 00 00       	push   $0x1000
f010269d:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f010269f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01026a4:	50                   	push   %eax
f01026a5:	e8 3e 1c 00 00       	call   f01042e8 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01026aa:	89 f0                	mov    %esi,%eax
f01026ac:	2b 05 0c df 17 f0    	sub    0xf017df0c,%eax
f01026b2:	c1 f8 03             	sar    $0x3,%eax
f01026b5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01026b8:	89 c2                	mov    %eax,%edx
f01026ba:	c1 ea 0c             	shr    $0xc,%edx
f01026bd:	83 c4 10             	add    $0x10,%esp
f01026c0:	3b 15 04 df 17 f0    	cmp    0xf017df04,%edx
f01026c6:	72 12                	jb     f01026da <mem_init+0x155c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01026c8:	50                   	push   %eax
f01026c9:	68 04 4d 10 f0       	push   $0xf0104d04
f01026ce:	6a 56                	push   $0x56
f01026d0:	68 c1 55 10 f0       	push   $0xf01055c1
f01026d5:	e8 c6 d9 ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01026da:	83 ec 04             	sub    $0x4,%esp
f01026dd:	68 00 10 00 00       	push   $0x1000
f01026e2:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f01026e4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01026e9:	50                   	push   %eax
f01026ea:	e8 f9 1b 00 00       	call   f01042e8 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01026ef:	6a 02                	push   $0x2
f01026f1:	68 00 10 00 00       	push   $0x1000
f01026f6:	57                   	push   %edi
f01026f7:	ff 35 08 df 17 f0    	pushl  0xf017df08
f01026fd:	e8 c3 e9 ff ff       	call   f01010c5 <page_insert>
	assert(pp1->pp_ref == 1);
f0102702:	83 c4 20             	add    $0x20,%esp
f0102705:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f010270a:	74 19                	je     f0102725 <mem_init+0x15a7>
f010270c:	68 b1 57 10 f0       	push   $0xf01057b1
f0102711:	68 db 55 10 f0       	push   $0xf01055db
f0102716:	68 4f 04 00 00       	push   $0x44f
f010271b:	68 b5 55 10 f0       	push   $0xf01055b5
f0102720:	e8 7b d9 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102725:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f010272c:	01 01 01 
f010272f:	74 19                	je     f010274a <mem_init+0x15cc>
f0102731:	68 e0 54 10 f0       	push   $0xf01054e0
f0102736:	68 db 55 10 f0       	push   $0xf01055db
f010273b:	68 50 04 00 00       	push   $0x450
f0102740:	68 b5 55 10 f0       	push   $0xf01055b5
f0102745:	e8 56 d9 ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f010274a:	6a 02                	push   $0x2
f010274c:	68 00 10 00 00       	push   $0x1000
f0102751:	56                   	push   %esi
f0102752:	ff 35 08 df 17 f0    	pushl  0xf017df08
f0102758:	e8 68 e9 ff ff       	call   f01010c5 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010275d:	83 c4 10             	add    $0x10,%esp
f0102760:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102767:	02 02 02 
f010276a:	74 19                	je     f0102785 <mem_init+0x1607>
f010276c:	68 04 55 10 f0       	push   $0xf0105504
f0102771:	68 db 55 10 f0       	push   $0xf01055db
f0102776:	68 52 04 00 00       	push   $0x452
f010277b:	68 b5 55 10 f0       	push   $0xf01055b5
f0102780:	e8 1b d9 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0102785:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010278a:	74 19                	je     f01027a5 <mem_init+0x1627>
f010278c:	68 d3 57 10 f0       	push   $0xf01057d3
f0102791:	68 db 55 10 f0       	push   $0xf01055db
f0102796:	68 53 04 00 00       	push   $0x453
f010279b:	68 b5 55 10 f0       	push   $0xf01055b5
f01027a0:	e8 fb d8 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f01027a5:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01027aa:	74 19                	je     f01027c5 <mem_init+0x1647>
f01027ac:	68 3d 58 10 f0       	push   $0xf010583d
f01027b1:	68 db 55 10 f0       	push   $0xf01055db
f01027b6:	68 54 04 00 00       	push   $0x454
f01027bb:	68 b5 55 10 f0       	push   $0xf01055b5
f01027c0:	e8 db d8 ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01027c5:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01027cc:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01027cf:	89 f0                	mov    %esi,%eax
f01027d1:	2b 05 0c df 17 f0    	sub    0xf017df0c,%eax
f01027d7:	c1 f8 03             	sar    $0x3,%eax
f01027da:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01027dd:	89 c2                	mov    %eax,%edx
f01027df:	c1 ea 0c             	shr    $0xc,%edx
f01027e2:	3b 15 04 df 17 f0    	cmp    0xf017df04,%edx
f01027e8:	72 12                	jb     f01027fc <mem_init+0x167e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01027ea:	50                   	push   %eax
f01027eb:	68 04 4d 10 f0       	push   $0xf0104d04
f01027f0:	6a 56                	push   $0x56
f01027f2:	68 c1 55 10 f0       	push   $0xf01055c1
f01027f7:	e8 a4 d8 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01027fc:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102803:	03 03 03 
f0102806:	74 19                	je     f0102821 <mem_init+0x16a3>
f0102808:	68 28 55 10 f0       	push   $0xf0105528
f010280d:	68 db 55 10 f0       	push   $0xf01055db
f0102812:	68 56 04 00 00       	push   $0x456
f0102817:	68 b5 55 10 f0       	push   $0xf01055b5
f010281c:	e8 7f d8 ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102821:	83 ec 08             	sub    $0x8,%esp
f0102824:	68 00 10 00 00       	push   $0x1000
f0102829:	ff 35 08 df 17 f0    	pushl  0xf017df08
f010282f:	e8 56 e8 ff ff       	call   f010108a <page_remove>
	assert(pp2->pp_ref == 0);
f0102834:	83 c4 10             	add    $0x10,%esp
f0102837:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010283c:	74 19                	je     f0102857 <mem_init+0x16d9>
f010283e:	68 0b 58 10 f0       	push   $0xf010580b
f0102843:	68 db 55 10 f0       	push   $0xf01055db
f0102848:	68 58 04 00 00       	push   $0x458
f010284d:	68 b5 55 10 f0       	push   $0xf01055b5
f0102852:	e8 49 d8 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102857:	8b 0d 08 df 17 f0    	mov    0xf017df08,%ecx
f010285d:	8b 11                	mov    (%ecx),%edx
f010285f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102865:	89 d8                	mov    %ebx,%eax
f0102867:	2b 05 0c df 17 f0    	sub    0xf017df0c,%eax
f010286d:	c1 f8 03             	sar    $0x3,%eax
f0102870:	c1 e0 0c             	shl    $0xc,%eax
f0102873:	39 c2                	cmp    %eax,%edx
f0102875:	74 19                	je     f0102890 <mem_init+0x1712>
f0102877:	68 38 50 10 f0       	push   $0xf0105038
f010287c:	68 db 55 10 f0       	push   $0xf01055db
f0102881:	68 5b 04 00 00       	push   $0x45b
f0102886:	68 b5 55 10 f0       	push   $0xf01055b5
f010288b:	e8 10 d8 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0102890:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102896:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010289b:	74 19                	je     f01028b6 <mem_init+0x1738>
f010289d:	68 c2 57 10 f0       	push   $0xf01057c2
f01028a2:	68 db 55 10 f0       	push   $0xf01055db
f01028a7:	68 5d 04 00 00       	push   $0x45d
f01028ac:	68 b5 55 10 f0       	push   $0xf01055b5
f01028b1:	e8 ea d7 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f01028b6:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01028bc:	83 ec 0c             	sub    $0xc,%esp
f01028bf:	53                   	push   %ebx
f01028c0:	e8 74 e5 ff ff       	call   f0100e39 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01028c5:	c7 04 24 54 55 10 f0 	movl   $0xf0105554,(%esp)
f01028cc:	e8 4f 08 00 00       	call   f0103120 <cprintf>
f01028d1:	83 c4 10             	add    $0x10,%esp
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01028d4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01028d7:	5b                   	pop    %ebx
f01028d8:	5e                   	pop    %esi
f01028d9:	5f                   	pop    %edi
f01028da:	5d                   	pop    %ebp
f01028db:	c3                   	ret    

f01028dc <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01028dc:	55                   	push   %ebp
f01028dd:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01028df:	8b 45 0c             	mov    0xc(%ebp),%eax
f01028e2:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01028e5:	5d                   	pop    %ebp
f01028e6:	c3                   	ret    

f01028e7 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f01028e7:	55                   	push   %ebp
f01028e8:	89 e5                	mov    %esp,%ebp
f01028ea:	57                   	push   %edi
f01028eb:	56                   	push   %esi
f01028ec:	53                   	push   %ebx
f01028ed:	83 ec 1c             	sub    $0x1c,%esp
f01028f0:	8b 7d 08             	mov    0x8(%ebp),%edi
f01028f3:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// LAB 3: Your code here.

	// step 1 : check below ULIM
  uintptr_t va_beg = (uintptr_t)va;
  uintptr_t va_end = va_beg + len;
f01028f6:	8b 75 0c             	mov    0xc(%ebp),%esi
f01028f9:	03 75 10             	add    0x10(%ebp),%esi
  if (va_beg >= ULIM || va_end >= ULIM) {
f01028fc:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102902:	77 09                	ja     f010290d <user_mem_check+0x26>
f0102904:	81 7d 0c ff ff 7f ef 	cmpl   $0xef7fffff,0xc(%ebp)
f010290b:	76 1f                	jbe    f010292c <user_mem_check+0x45>
    user_mem_check_addr = (va_beg >= ULIM) ? va_beg : ULIM;
f010290d:	81 7d 0c 00 00 80 ef 	cmpl   $0xef800000,0xc(%ebp)
f0102914:	b8 00 00 80 ef       	mov    $0xef800000,%eax
f0102919:	0f 43 45 0c          	cmovae 0xc(%ebp),%eax
f010291d:	a3 20 d2 17 f0       	mov    %eax,0xf017d220
    return -E_FAULT;
f0102922:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102927:	e9 a7 00 00 00       	jmp    f01029d3 <user_mem_check+0xec>
  }

  // step 2 : check present & permission
  uintptr_t va_beg2 = ROUNDDOWN(va_beg, PGSIZE);
f010292c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010292f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  uintptr_t va_end2 = ROUNDUP(va_end, PGSIZE);
f0102935:	81 c6 ff 0f 00 00    	add    $0xfff,%esi
f010293b:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102941:	a1 04 df 17 f0       	mov    0xf017df04,%eax
f0102946:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102949:	89 7d 08             	mov    %edi,0x8(%ebp)
  while (va_beg2 < va_end2) {
f010294c:	eb 7c                	jmp    f01029ca <user_mem_check+0xe3>

    // check page table is present ?
    if (!(env->env_pgdir[PDX(va_beg2)] & PTE_P)) {
f010294e:	89 d1                	mov    %edx,%ecx
f0102950:	c1 e9 16             	shr    $0x16,%ecx
f0102953:	8b 45 08             	mov    0x8(%ebp),%eax
f0102956:	8b 40 5c             	mov    0x5c(%eax),%eax
f0102959:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f010295c:	a8 01                	test   $0x1,%al
f010295e:	75 14                	jne    f0102974 <user_mem_check+0x8d>
      user_mem_check_addr = (va_beg2 > va_beg) ? va_beg2 : va_beg;
f0102960:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102963:	0f 42 55 0c          	cmovb  0xc(%ebp),%edx
f0102967:	89 15 20 d2 17 f0    	mov    %edx,0xf017d220
      return -E_FAULT;
f010296d:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102972:	eb 5f                	jmp    f01029d3 <user_mem_check+0xec>
    }

    // get current page table kernel va
    uint32_t* pt_kva = KADDR(PTE_ADDR(env->env_pgdir[PDX(va_beg2)]));
f0102974:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102979:	89 c1                	mov    %eax,%ecx
f010297b:	c1 e9 0c             	shr    $0xc,%ecx
f010297e:	3b 4d e4             	cmp    -0x1c(%ebp),%ecx
f0102981:	72 15                	jb     f0102998 <user_mem_check+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102983:	50                   	push   %eax
f0102984:	68 04 4d 10 f0       	push   $0xf0104d04
f0102989:	68 a6 02 00 00       	push   $0x2a6
f010298e:	68 b5 55 10 f0       	push   $0xf01055b5
f0102993:	e8 08 d7 ff ff       	call   f01000a0 <_panic>

    // check page is present & permissions
    if (!((pt_kva[PTX(va_beg2)] & perm) == perm)) {
f0102998:	89 d1                	mov    %edx,%ecx
f010299a:	c1 e9 0c             	shr    $0xc,%ecx
f010299d:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
f01029a3:	89 df                	mov    %ebx,%edi
f01029a5:	23 bc 88 00 00 00 f0 	and    -0x10000000(%eax,%ecx,4),%edi
f01029ac:	39 fb                	cmp    %edi,%ebx
f01029ae:	74 14                	je     f01029c4 <user_mem_check+0xdd>
      user_mem_check_addr = (va_beg2 > va_beg) ? va_beg2 : va_beg;
f01029b0:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01029b3:	0f 42 55 0c          	cmovb  0xc(%ebp),%edx
f01029b7:	89 15 20 d2 17 f0    	mov    %edx,0xf017d220
      return -E_FAULT;
f01029bd:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01029c2:	eb 0f                	jmp    f01029d3 <user_mem_check+0xec>
    }

    va_beg2 += PGSIZE;
f01029c4:	81 c2 00 10 00 00    	add    $0x1000,%edx
  }

  // step 2 : check present & permission
  uintptr_t va_beg2 = ROUNDDOWN(va_beg, PGSIZE);
  uintptr_t va_end2 = ROUNDUP(va_end, PGSIZE);
  while (va_beg2 < va_end2) {
f01029ca:	39 f2                	cmp    %esi,%edx
f01029cc:	72 80                	jb     f010294e <user_mem_check+0x67>
      return -E_FAULT;
    }

    va_beg2 += PGSIZE;
  }
  return 0;
f01029ce:	b8 00 00 00 00       	mov    $0x0,%eax

}
f01029d3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01029d6:	5b                   	pop    %ebx
f01029d7:	5e                   	pop    %esi
f01029d8:	5f                   	pop    %edi
f01029d9:	5d                   	pop    %ebp
f01029da:	c3                   	ret    

f01029db <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f01029db:	55                   	push   %ebp
f01029dc:	89 e5                	mov    %esp,%ebp
f01029de:	53                   	push   %ebx
f01029df:	83 ec 04             	sub    $0x4,%esp
f01029e2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f01029e5:	8b 45 14             	mov    0x14(%ebp),%eax
f01029e8:	83 c8 04             	or     $0x4,%eax
f01029eb:	50                   	push   %eax
f01029ec:	ff 75 10             	pushl  0x10(%ebp)
f01029ef:	ff 75 0c             	pushl  0xc(%ebp)
f01029f2:	53                   	push   %ebx
f01029f3:	e8 ef fe ff ff       	call   f01028e7 <user_mem_check>
f01029f8:	83 c4 10             	add    $0x10,%esp
f01029fb:	85 c0                	test   %eax,%eax
f01029fd:	79 21                	jns    f0102a20 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f01029ff:	83 ec 04             	sub    $0x4,%esp
f0102a02:	ff 35 20 d2 17 f0    	pushl  0xf017d220
f0102a08:	ff 73 48             	pushl  0x48(%ebx)
f0102a0b:	68 80 55 10 f0       	push   $0xf0105580
f0102a10:	e8 0b 07 00 00       	call   f0103120 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102a15:	89 1c 24             	mov    %ebx,(%esp)
f0102a18:	e8 f0 05 00 00       	call   f010300d <env_destroy>
f0102a1d:	83 c4 10             	add    $0x10,%esp
	}
}
f0102a20:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102a23:	c9                   	leave  
f0102a24:	c3                   	ret    

f0102a25 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102a25:	55                   	push   %ebp
f0102a26:	89 e5                	mov    %esp,%ebp
f0102a28:	57                   	push   %edi
f0102a29:	56                   	push   %esi
f0102a2a:	53                   	push   %ebx
f0102a2b:	83 ec 0c             	sub    $0xc,%esp
f0102a2e:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
f0102a30:	89 d3                	mov    %edx,%ebx
f0102a32:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
f0102a38:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102a3f:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	
	while (vaBegin<vaEnd){
f0102a45:	eb 58                	jmp    f0102a9f <region_alloc+0x7a>
		struct PageInfo *p = page_alloc(0);
f0102a47:	83 ec 0c             	sub    $0xc,%esp
f0102a4a:	6a 00                	push   $0x0
f0102a4c:	e8 72 e3 ff ff       	call   f0100dc3 <page_alloc>
		if (p == NULL)
f0102a51:	83 c4 10             	add    $0x10,%esp
f0102a54:	85 c0                	test   %eax,%eax
f0102a56:	75 17                	jne    f0102a6f <region_alloc+0x4a>
			panic("Page alloc failed!");
f0102a58:	83 ec 04             	sub    $0x4,%esp
f0102a5b:	68 c6 58 10 f0       	push   $0xf01058c6
f0102a60:	68 28 01 00 00       	push   $0x128
f0102a65:	68 d9 58 10 f0       	push   $0xf01058d9
f0102a6a:	e8 31 d6 ff ff       	call   f01000a0 <_panic>
		else if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
f0102a6f:	6a 06                	push   $0x6
f0102a71:	53                   	push   %ebx
f0102a72:	50                   	push   %eax
f0102a73:	ff 77 5c             	pushl  0x5c(%edi)
f0102a76:	e8 4a e6 ff ff       	call   f01010c5 <page_insert>
f0102a7b:	83 c4 10             	add    $0x10,%esp
f0102a7e:	85 c0                	test   %eax,%eax
f0102a80:	74 17                	je     f0102a99 <region_alloc+0x74>
			panic("Page table couldn't be allocated!!");
f0102a82:	83 ec 04             	sub    $0x4,%esp
f0102a85:	68 48 59 10 f0       	push   $0xf0105948
f0102a8a:	68 2a 01 00 00       	push   $0x12a
f0102a8f:	68 d9 58 10 f0       	push   $0xf01058d9
f0102a94:	e8 07 d6 ff ff       	call   f01000a0 <_panic>
		}
		vaBegin += PGSIZE;
f0102a99:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
	
	while (vaBegin<vaEnd){
f0102a9f:	39 f3                	cmp    %esi,%ebx
f0102aa1:	72 a4                	jb     f0102a47 <region_alloc+0x22>
		else if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
			panic("Page table couldn't be allocated!!");
		}
		vaBegin += PGSIZE;
	}
}
f0102aa3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102aa6:	5b                   	pop    %ebx
f0102aa7:	5e                   	pop    %esi
f0102aa8:	5f                   	pop    %edi
f0102aa9:	5d                   	pop    %ebp
f0102aaa:	c3                   	ret    

f0102aab <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102aab:	55                   	push   %ebp
f0102aac:	89 e5                	mov    %esp,%ebp
f0102aae:	8b 55 08             	mov    0x8(%ebp),%edx
f0102ab1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102ab4:	85 d2                	test   %edx,%edx
f0102ab6:	75 11                	jne    f0102ac9 <envid2env+0x1e>
		*env_store = curenv;
f0102ab8:	a1 2c d2 17 f0       	mov    0xf017d22c,%eax
f0102abd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102ac0:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102ac2:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ac7:	eb 5e                	jmp    f0102b27 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102ac9:	89 d0                	mov    %edx,%eax
f0102acb:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102ad0:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102ad3:	c1 e0 05             	shl    $0x5,%eax
f0102ad6:	03 05 30 d2 17 f0    	add    0xf017d230,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102adc:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0102ae0:	74 05                	je     f0102ae7 <envid2env+0x3c>
f0102ae2:	39 50 48             	cmp    %edx,0x48(%eax)
f0102ae5:	74 10                	je     f0102af7 <envid2env+0x4c>
		*env_store = 0;
f0102ae7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102aea:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102af0:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102af5:	eb 30                	jmp    f0102b27 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102af7:	84 c9                	test   %cl,%cl
f0102af9:	74 22                	je     f0102b1d <envid2env+0x72>
f0102afb:	8b 15 2c d2 17 f0    	mov    0xf017d22c,%edx
f0102b01:	39 d0                	cmp    %edx,%eax
f0102b03:	74 18                	je     f0102b1d <envid2env+0x72>
f0102b05:	8b 4a 48             	mov    0x48(%edx),%ecx
f0102b08:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f0102b0b:	74 10                	je     f0102b1d <envid2env+0x72>
		*env_store = 0;
f0102b0d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102b10:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102b16:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102b1b:	eb 0a                	jmp    f0102b27 <envid2env+0x7c>
	}

	*env_store = e;
f0102b1d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102b20:	89 01                	mov    %eax,(%ecx)
	return 0;
f0102b22:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102b27:	5d                   	pop    %ebp
f0102b28:	c3                   	ret    

f0102b29 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102b29:	55                   	push   %ebp
f0102b2a:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0102b2c:	b8 00 b3 11 f0       	mov    $0xf011b300,%eax
f0102b31:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0102b34:	b8 23 00 00 00       	mov    $0x23,%eax
f0102b39:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0102b3b:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0102b3d:	b0 10                	mov    $0x10,%al
f0102b3f:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0102b41:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0102b43:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f0102b45:	ea 4c 2b 10 f0 08 00 	ljmp   $0x8,$0xf0102b4c
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0102b4c:	b0 00                	mov    $0x0,%al
f0102b4e:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102b51:	5d                   	pop    %ebp
f0102b52:	c3                   	ret    

f0102b53 <env_init>:
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
f0102b53:	8b 0d 30 d2 17 f0    	mov    0xf017d230,%ecx
f0102b59:	8b 15 34 d2 17 f0    	mov    0xf017d234,%edx
f0102b5f:	89 c8                	mov    %ecx,%eax
f0102b61:	81 c1 00 80 01 00    	add    $0x18000,%ecx
f0102b67:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = NULL;
f0102b6e:	c7 40 44 00 00 00 00 	movl   $0x0,0x44(%eax)

		if (!env_free_list){		
f0102b75:	85 d2                	test   %edx,%edx
f0102b77:	74 05                	je     f0102b7e <env_init+0x2b>
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
		}
		else{
		envs[i-1].env_link = &envs[i];
f0102b79:	89 40 e4             	mov    %eax,-0x1c(%eax)
f0102b7c:	eb 02                	jmp    f0102b80 <env_init+0x2d>
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
		envs[i].env_link = NULL;

		if (!env_free_list){		
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
f0102b7e:	89 c2                	mov    %eax,%edx
f0102b80:	83 c0 60             	add    $0x60,%eax
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
f0102b83:	39 c8                	cmp    %ecx,%eax
f0102b85:	75 e0                	jne    f0102b67 <env_init+0x14>
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102b87:	55                   	push   %ebp
f0102b88:	89 e5                	mov    %esp,%ebp
f0102b8a:	89 15 34 d2 17 f0    	mov    %edx,0xf017d234
		}	//Previous env is linked to this current env
	}
	

	// Per-CPU part of the initialization
	env_init_percpu();
f0102b90:	e8 94 ff ff ff       	call   f0102b29 <env_init_percpu>
}
f0102b95:	5d                   	pop    %ebp
f0102b96:	c3                   	ret    

f0102b97 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102b97:	55                   	push   %ebp
f0102b98:	89 e5                	mov    %esp,%ebp
f0102b9a:	53                   	push   %ebx
f0102b9b:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102b9e:	8b 1d 34 d2 17 f0    	mov    0xf017d234,%ebx
f0102ba4:	85 db                	test   %ebx,%ebx
f0102ba6:	0f 84 4a 01 00 00    	je     f0102cf6 <env_alloc+0x15f>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102bac:	83 ec 0c             	sub    $0xc,%esp
f0102baf:	6a 01                	push   $0x1
f0102bb1:	e8 0d e2 ff ff       	call   f0100dc3 <page_alloc>
f0102bb6:	83 c4 10             	add    $0x10,%esp
f0102bb9:	85 c0                	test   %eax,%eax
f0102bbb:	0f 84 3c 01 00 00    	je     f0102cfd <env_alloc+0x166>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f0102bc1:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102bc6:	2b 05 0c df 17 f0    	sub    0xf017df0c,%eax
f0102bcc:	c1 f8 03             	sar    $0x3,%eax
f0102bcf:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bd2:	89 c2                	mov    %eax,%edx
f0102bd4:	c1 ea 0c             	shr    $0xc,%edx
f0102bd7:	3b 15 04 df 17 f0    	cmp    0xf017df04,%edx
f0102bdd:	72 12                	jb     f0102bf1 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bdf:	50                   	push   %eax
f0102be0:	68 04 4d 10 f0       	push   $0xf0104d04
f0102be5:	6a 56                	push   $0x56
f0102be7:	68 c1 55 10 f0       	push   $0xf01055c1
f0102bec:	e8 af d4 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0102bf1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102bf6:	89 43 5c             	mov    %eax,0x5c(%ebx)
	e->env_pgdir = (pde_t*)page2kva(p);
f0102bf9:	b8 00 00 00 00       	mov    $0x0,%eax

	for (i = 0; i < NPDENTRIES; ++i) {
		e->env_pgdir[i] = kern_pgdir[i];  //Mapping all 1024 entries of the kernel
f0102bfe:	8b 15 08 df 17 f0    	mov    0xf017df08,%edx
f0102c04:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f0102c07:	8b 53 5c             	mov    0x5c(%ebx),%edx
f0102c0a:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f0102c0d:	83 c0 04             	add    $0x4,%eax

	// LAB 3: Your code here.
	p->pp_ref++;
	e->env_pgdir = (pde_t*)page2kva(p);

	for (i = 0; i < NPDENTRIES; ++i) {
f0102c10:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102c15:	75 e7                	jne    f0102bfe <env_alloc+0x67>
						 //pgdir to the environment pgdir
	}
	
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102c17:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c1a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c1f:	77 15                	ja     f0102c36 <env_alloc+0x9f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c21:	50                   	push   %eax
f0102c22:	68 28 4d 10 f0       	push   $0xf0104d28
f0102c27:	68 cd 00 00 00       	push   $0xcd
f0102c2c:	68 d9 58 10 f0       	push   $0xf01058d9
f0102c31:	e8 6a d4 ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102c36:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102c3c:	83 ca 05             	or     $0x5,%edx
f0102c3f:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102c45:	8b 43 48             	mov    0x48(%ebx),%eax
f0102c48:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102c4d:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102c52:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102c57:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102c5a:	89 da                	mov    %ebx,%edx
f0102c5c:	2b 15 30 d2 17 f0    	sub    0xf017d230,%edx
f0102c62:	c1 fa 05             	sar    $0x5,%edx
f0102c65:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102c6b:	09 d0                	or     %edx,%eax
f0102c6d:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102c70:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102c73:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102c76:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102c7d:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102c84:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102c8b:	83 ec 04             	sub    $0x4,%esp
f0102c8e:	6a 44                	push   $0x44
f0102c90:	6a 00                	push   $0x0
f0102c92:	53                   	push   %ebx
f0102c93:	e8 50 16 00 00       	call   f01042e8 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102c98:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102c9e:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102ca4:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102caa:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102cb1:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102cb7:	8b 43 44             	mov    0x44(%ebx),%eax
f0102cba:	a3 34 d2 17 f0       	mov    %eax,0xf017d234
	*newenv_store = e;
f0102cbf:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cc2:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102cc4:	8b 53 48             	mov    0x48(%ebx),%edx
f0102cc7:	a1 2c d2 17 f0       	mov    0xf017d22c,%eax
f0102ccc:	83 c4 10             	add    $0x10,%esp
f0102ccf:	85 c0                	test   %eax,%eax
f0102cd1:	74 05                	je     f0102cd8 <env_alloc+0x141>
f0102cd3:	8b 40 48             	mov    0x48(%eax),%eax
f0102cd6:	eb 05                	jmp    f0102cdd <env_alloc+0x146>
f0102cd8:	b8 00 00 00 00       	mov    $0x0,%eax
f0102cdd:	83 ec 04             	sub    $0x4,%esp
f0102ce0:	52                   	push   %edx
f0102ce1:	50                   	push   %eax
f0102ce2:	68 e4 58 10 f0       	push   $0xf01058e4
f0102ce7:	e8 34 04 00 00       	call   f0103120 <cprintf>
	return 0;
f0102cec:	83 c4 10             	add    $0x10,%esp
f0102cef:	b8 00 00 00 00       	mov    $0x0,%eax
f0102cf4:	eb 0c                	jmp    f0102d02 <env_alloc+0x16b>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102cf6:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102cfb:	eb 05                	jmp    f0102d02 <env_alloc+0x16b>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102cfd:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102d02:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102d05:	c9                   	leave  
f0102d06:	c3                   	ret    

f0102d07 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102d07:	55                   	push   %ebp
f0102d08:	89 e5                	mov    %esp,%ebp
f0102d0a:	57                   	push   %edi
f0102d0b:	56                   	push   %esi
f0102d0c:	53                   	push   %ebx
f0102d0d:	83 ec 34             	sub    $0x34,%esp
f0102d10:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	int r;
	struct Env *env;
	r = env_alloc( &env, 0);
f0102d13:	6a 00                	push   $0x0
f0102d15:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102d18:	50                   	push   %eax
f0102d19:	e8 79 fe ff ff       	call   f0102b97 <env_alloc>
	if (r){
f0102d1e:	83 c4 10             	add    $0x10,%esp
f0102d21:	85 c0                	test   %eax,%eax
f0102d23:	74 15                	je     f0102d3a <env_create+0x33>
	panic("env_alloc: %e", r);
f0102d25:	50                   	push   %eax
f0102d26:	68 f9 58 10 f0       	push   $0xf01058f9
f0102d2b:	68 a5 01 00 00       	push   $0x1a5
f0102d30:	68 d9 58 10 f0       	push   $0xf01058d9
f0102d35:	e8 66 d3 ff ff       	call   f01000a0 <_panic>
	}
	
	load_icode(env,binary);
f0102d3a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102d3d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Get the beginning and end of program header table
	//Details of struct proghdr are in /lab/inc/elf.h

	// is this a valid ELF?
	
	if (((struct Elf*)binary)->e_magic != ELF_MAGIC)
f0102d40:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102d46:	74 17                	je     f0102d5f <env_create+0x58>
	{
		panic ("Not a valid ELF binary image");
f0102d48:	83 ec 04             	sub    $0x4,%esp
f0102d4b:	68 07 59 10 f0       	push   $0xf0105907
f0102d50:	68 74 01 00 00       	push   $0x174
f0102d55:	68 d9 58 10 f0       	push   $0xf01058d9
f0102d5a:	e8 41 d3 ff ff       	call   f01000a0 <_panic>
	}

	struct Proghdr *ph =(struct Proghdr *)(binary + ((struct Elf*)binary)->e_phoff); //phoff is the offset
f0102d5f:	89 fb                	mov    %edi,%ebx
f0102d61:	03 5f 1c             	add    0x1c(%edi),%ebx
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
f0102d64:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0102d68:	c1 e6 05             	shl    $0x5,%esi
f0102d6b:	01 de                	add    %ebx,%esi
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));
f0102d6d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d70:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d73:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d78:	77 15                	ja     f0102d8f <env_create+0x88>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d7a:	50                   	push   %eax
f0102d7b:	68 28 4d 10 f0       	push   $0xf0104d28
f0102d80:	68 7b 01 00 00       	push   $0x17b
f0102d85:	68 d9 58 10 f0       	push   $0xf01058d9
f0102d8a:	e8 11 d3 ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102d8f:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102d94:	0f 22 d8             	mov    %eax,%cr3
f0102d97:	eb 60                	jmp    f0102df9 <env_create+0xf2>

	for (;ph<phEnd;++ph){
		if (ph->p_type == ELF_PROG_LOAD){	//Check whether the type is ELF_PROG_LOAD
f0102d99:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102d9c:	75 58                	jne    f0102df6 <env_create+0xef>
		
		if(ph->p_memsz < ph->p_filesz){
f0102d9e:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102da1:	3b 4b 10             	cmp    0x10(%ebx),%ecx
f0102da4:	73 17                	jae    f0102dbd <env_create+0xb6>
		panic ("Memory size is smaller than file size!!");
f0102da6:	83 ec 04             	sub    $0x4,%esp
f0102da9:	68 6c 59 10 f0       	push   $0xf010596c
f0102dae:	68 81 01 00 00       	push   $0x181
f0102db3:	68 d9 58 10 f0       	push   $0xf01058d9
f0102db8:	e8 e3 d2 ff ff       	call   f01000a0 <_panic>
		}
		region_alloc(e, (void *)ph->p_va, ph->p_memsz);  //Allocate region per segment
f0102dbd:	8b 53 08             	mov    0x8(%ebx),%edx
f0102dc0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102dc3:	e8 5d fc ff ff       	call   f0102a25 <region_alloc>
	

		memcpy((void*)ph->p_va, (void*)(binary + ph->p_offset), ph->p_filesz); //Load Binary into memory
f0102dc8:	83 ec 04             	sub    $0x4,%esp
f0102dcb:	ff 73 10             	pushl  0x10(%ebx)
f0102dce:	89 f8                	mov    %edi,%eax
f0102dd0:	03 43 04             	add    0x4(%ebx),%eax
f0102dd3:	50                   	push   %eax
f0102dd4:	ff 73 08             	pushl  0x8(%ebx)
f0102dd7:	e8 c1 15 00 00       	call   f010439d <memcpy>

		memset((void*)(ph->p_va + ph->p_filesz),0,ph->p_memsz-ph->p_filesz);  //Clear the rest of the memory, i.e the bss segment
f0102ddc:	8b 43 10             	mov    0x10(%ebx),%eax
f0102ddf:	83 c4 0c             	add    $0xc,%esp
f0102de2:	8b 53 14             	mov    0x14(%ebx),%edx
f0102de5:	29 c2                	sub    %eax,%edx
f0102de7:	52                   	push   %edx
f0102de8:	6a 00                	push   $0x0
f0102dea:	03 43 08             	add    0x8(%ebx),%eax
f0102ded:	50                   	push   %eax
f0102dee:	e8 f5 14 00 00       	call   f01042e8 <memset>
f0102df3:	83 c4 10             	add    $0x10,%esp
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));

	for (;ph<phEnd;++ph){
f0102df6:	83 c3 20             	add    $0x20,%ebx
f0102df9:	39 de                	cmp    %ebx,%esi
f0102dfb:	77 9c                	ja     f0102d99 <env_create+0x92>
		}
		else{
			continue;
		}
	}
	lcr3(PADDR(kern_pgdir));   //Switch back to Kernel page directory
f0102dfd:	a1 08 df 17 f0       	mov    0xf017df08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e02:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102e07:	77 15                	ja     f0102e1e <env_create+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e09:	50                   	push   %eax
f0102e0a:	68 28 4d 10 f0       	push   $0xf0104d28
f0102e0f:	68 8e 01 00 00       	push   $0x18e
f0102e14:	68 d9 58 10 f0       	push   $0xf01058d9
f0102e19:	e8 82 d2 ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102e1e:	05 00 00 00 10       	add    $0x10000000,%eax
f0102e23:	0f 22 d8             	mov    %eax,%cr3
	
	e->env_tf.tf_eip = ((struct Elf*)binary)->e_entry;   //Define the entry point of the env from the ELF binary entry point
f0102e26:	8b 47 18             	mov    0x18(%edi),%eax
f0102e29:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102e2c:	89 47 30             	mov    %eax,0x30(%edi)

	region_alloc(e,(void *)USTACKTOP - PGSIZE, PGSIZE);
f0102e2f:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102e34:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102e39:	89 f8                	mov    %edi,%eax
f0102e3b:	e8 e5 fb ff ff       	call   f0102a25 <region_alloc>
	if (r){
	panic("env_alloc: %e", r);
	}
	
	load_icode(env,binary);
	env->env_type = type;
f0102e40:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102e43:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102e46:	89 50 50             	mov    %edx,0x50(%eax)
}
f0102e49:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e4c:	5b                   	pop    %ebx
f0102e4d:	5e                   	pop    %esi
f0102e4e:	5f                   	pop    %edi
f0102e4f:	5d                   	pop    %ebp
f0102e50:	c3                   	ret    

f0102e51 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102e51:	55                   	push   %ebp
f0102e52:	89 e5                	mov    %esp,%ebp
f0102e54:	57                   	push   %edi
f0102e55:	56                   	push   %esi
f0102e56:	53                   	push   %ebx
f0102e57:	83 ec 1c             	sub    $0x1c,%esp
f0102e5a:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102e5d:	8b 15 2c d2 17 f0    	mov    0xf017d22c,%edx
f0102e63:	39 d7                	cmp    %edx,%edi
f0102e65:	75 29                	jne    f0102e90 <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102e67:	a1 08 df 17 f0       	mov    0xf017df08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e6c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102e71:	77 15                	ja     f0102e88 <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e73:	50                   	push   %eax
f0102e74:	68 28 4d 10 f0       	push   $0xf0104d28
f0102e79:	68 bb 01 00 00       	push   $0x1bb
f0102e7e:	68 d9 58 10 f0       	push   $0xf01058d9
f0102e83:	e8 18 d2 ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102e88:	05 00 00 00 10       	add    $0x10000000,%eax
f0102e8d:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102e90:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102e93:	85 d2                	test   %edx,%edx
f0102e95:	74 05                	je     f0102e9c <env_free+0x4b>
f0102e97:	8b 42 48             	mov    0x48(%edx),%eax
f0102e9a:	eb 05                	jmp    f0102ea1 <env_free+0x50>
f0102e9c:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ea1:	83 ec 04             	sub    $0x4,%esp
f0102ea4:	51                   	push   %ecx
f0102ea5:	50                   	push   %eax
f0102ea6:	68 24 59 10 f0       	push   $0xf0105924
f0102eab:	e8 70 02 00 00       	call   f0103120 <cprintf>
f0102eb0:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102eb3:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102eba:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102ebd:	89 d0                	mov    %edx,%eax
f0102ebf:	c1 e0 02             	shl    $0x2,%eax
f0102ec2:	89 45 d8             	mov    %eax,-0x28(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102ec5:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102ec8:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102ecb:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102ed1:	0f 84 a8 00 00 00    	je     f0102f7f <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102ed7:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102edd:	89 f0                	mov    %esi,%eax
f0102edf:	c1 e8 0c             	shr    $0xc,%eax
f0102ee2:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0102ee5:	3b 05 04 df 17 f0    	cmp    0xf017df04,%eax
f0102eeb:	72 15                	jb     f0102f02 <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102eed:	56                   	push   %esi
f0102eee:	68 04 4d 10 f0       	push   $0xf0104d04
f0102ef3:	68 ca 01 00 00       	push   $0x1ca
f0102ef8:	68 d9 58 10 f0       	push   $0xf01058d9
f0102efd:	e8 9e d1 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102f02:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102f05:	c1 e0 16             	shl    $0x16,%eax
f0102f08:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102f0b:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102f10:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102f17:	01 
f0102f18:	74 17                	je     f0102f31 <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102f1a:	83 ec 08             	sub    $0x8,%esp
f0102f1d:	89 d8                	mov    %ebx,%eax
f0102f1f:	c1 e0 0c             	shl    $0xc,%eax
f0102f22:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102f25:	50                   	push   %eax
f0102f26:	ff 77 5c             	pushl  0x5c(%edi)
f0102f29:	e8 5c e1 ff ff       	call   f010108a <page_remove>
f0102f2e:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102f31:	83 c3 01             	add    $0x1,%ebx
f0102f34:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102f3a:	75 d4                	jne    f0102f10 <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102f3c:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102f3f:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102f42:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102f49:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102f4c:	3b 05 04 df 17 f0    	cmp    0xf017df04,%eax
f0102f52:	72 14                	jb     f0102f68 <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102f54:	83 ec 04             	sub    $0x4,%esp
f0102f57:	68 94 59 10 f0       	push   $0xf0105994
f0102f5c:	6a 4f                	push   $0x4f
f0102f5e:	68 c1 55 10 f0       	push   $0xf01055c1
f0102f63:	e8 38 d1 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102f68:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0102f6b:	a1 0c df 17 f0       	mov    0xf017df0c,%eax
f0102f70:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102f73:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102f76:	50                   	push   %eax
f0102f77:	e8 0e df ff ff       	call   f0100e8a <page_decref>
f0102f7c:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102f7f:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102f83:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102f86:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102f8b:	0f 85 29 ff ff ff    	jne    f0102eba <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102f91:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f94:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102f99:	77 15                	ja     f0102fb0 <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f9b:	50                   	push   %eax
f0102f9c:	68 28 4d 10 f0       	push   $0xf0104d28
f0102fa1:	68 d8 01 00 00       	push   $0x1d8
f0102fa6:	68 d9 58 10 f0       	push   $0xf01058d9
f0102fab:	e8 f0 d0 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102fb0:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	return (physaddr_t)kva - KERNBASE;
f0102fb7:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102fbc:	c1 e8 0c             	shr    $0xc,%eax
f0102fbf:	3b 05 04 df 17 f0    	cmp    0xf017df04,%eax
f0102fc5:	72 14                	jb     f0102fdb <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102fc7:	83 ec 04             	sub    $0x4,%esp
f0102fca:	68 94 59 10 f0       	push   $0xf0105994
f0102fcf:	6a 4f                	push   $0x4f
f0102fd1:	68 c1 55 10 f0       	push   $0xf01055c1
f0102fd6:	e8 c5 d0 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102fdb:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0102fde:	8b 15 0c df 17 f0    	mov    0xf017df0c,%edx
f0102fe4:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102fe7:	50                   	push   %eax
f0102fe8:	e8 9d de ff ff       	call   f0100e8a <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102fed:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102ff4:	a1 34 d2 17 f0       	mov    0xf017d234,%eax
f0102ff9:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102ffc:	89 3d 34 d2 17 f0    	mov    %edi,0xf017d234
f0103002:	83 c4 10             	add    $0x10,%esp
}
f0103005:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103008:	5b                   	pop    %ebx
f0103009:	5e                   	pop    %esi
f010300a:	5f                   	pop    %edi
f010300b:	5d                   	pop    %ebp
f010300c:	c3                   	ret    

f010300d <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f010300d:	55                   	push   %ebp
f010300e:	89 e5                	mov    %esp,%ebp
f0103010:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0103013:	ff 75 08             	pushl  0x8(%ebp)
f0103016:	e8 36 fe ff ff       	call   f0102e51 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f010301b:	c7 04 24 b4 59 10 f0 	movl   $0xf01059b4,(%esp)
f0103022:	e8 f9 00 00 00       	call   f0103120 <cprintf>
f0103027:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f010302a:	83 ec 0c             	sub    $0xc,%esp
f010302d:	6a 00                	push   $0x0
f010302f:	e8 5a d7 ff ff       	call   f010078e <monitor>
f0103034:	83 c4 10             	add    $0x10,%esp
f0103037:	eb f1                	jmp    f010302a <env_destroy+0x1d>

f0103039 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103039:	55                   	push   %ebp
f010303a:	89 e5                	mov    %esp,%ebp
f010303c:	83 ec 0c             	sub    $0xc,%esp
	__asm __volatile("movl %0,%%esp\n"
f010303f:	8b 65 08             	mov    0x8(%ebp),%esp
f0103042:	61                   	popa   
f0103043:	07                   	pop    %es
f0103044:	1f                   	pop    %ds
f0103045:	83 c4 08             	add    $0x8,%esp
f0103048:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103049:	68 3a 59 10 f0       	push   $0xf010593a
f010304e:	68 00 02 00 00       	push   $0x200
f0103053:	68 d9 58 10 f0       	push   $0xf01058d9
f0103058:	e8 43 d0 ff ff       	call   f01000a0 <_panic>

f010305d <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f010305d:	55                   	push   %ebp
f010305e:	89 e5                	mov    %esp,%ebp
f0103060:	83 ec 08             	sub    $0x8,%esp
f0103063:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	//check if this is the first call to env_run
	if (curenv == NULL){
f0103066:	8b 15 2c d2 17 f0    	mov    0xf017d22c,%edx
f010306c:	85 d2                	test   %edx,%edx
f010306e:	74 0d                	je     f010307d <env_run+0x20>
	curenv = e;
	}
	
	//If curenv state is running mode , set it to runnable 
	else if (curenv->env_status == ENV_RUNNING){
f0103070:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0103074:	75 07                	jne    f010307d <env_run+0x20>
	 curenv->env_status = ENV_RUNNABLE;
f0103076:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
	}
	curenv = e;	//Set the current environment to the new env
f010307d:	a3 2c d2 17 f0       	mov    %eax,0xf017d22c
	curenv->env_status = ENV_RUNNING; //Set it to running state
f0103082:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;	// Increment the env_runs counter
f0103089:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(e->env_pgdir));	//Use lcr3 to switch to the env directory
f010308d:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103090:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103096:	77 15                	ja     f01030ad <env_run+0x50>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103098:	52                   	push   %edx
f0103099:	68 28 4d 10 f0       	push   $0xf0104d28
f010309e:	68 2b 02 00 00       	push   $0x22b
f01030a3:	68 d9 58 10 f0       	push   $0xf01058d9
f01030a8:	e8 f3 cf ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01030ad:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f01030b3:	0f 22 da             	mov    %edx,%cr3

	env_pop_tf(&e->env_tf);
f01030b6:	83 ec 0c             	sub    $0xc,%esp
f01030b9:	50                   	push   %eax
f01030ba:	e8 7a ff ff ff       	call   f0103039 <env_pop_tf>

f01030bf <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01030bf:	55                   	push   %ebp
f01030c0:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01030c2:	ba 70 00 00 00       	mov    $0x70,%edx
f01030c7:	8b 45 08             	mov    0x8(%ebp),%eax
f01030ca:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01030cb:	b2 71                	mov    $0x71,%dl
f01030cd:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01030ce:	0f b6 c0             	movzbl %al,%eax
}
f01030d1:	5d                   	pop    %ebp
f01030d2:	c3                   	ret    

f01030d3 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01030d3:	55                   	push   %ebp
f01030d4:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01030d6:	ba 70 00 00 00       	mov    $0x70,%edx
f01030db:	8b 45 08             	mov    0x8(%ebp),%eax
f01030de:	ee                   	out    %al,(%dx)
f01030df:	b2 71                	mov    $0x71,%dl
f01030e1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030e4:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01030e5:	5d                   	pop    %ebp
f01030e6:	c3                   	ret    

f01030e7 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01030e7:	55                   	push   %ebp
f01030e8:	89 e5                	mov    %esp,%ebp
f01030ea:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01030ed:	ff 75 08             	pushl  0x8(%ebp)
f01030f0:	e8 00 d5 ff ff       	call   f01005f5 <cputchar>
f01030f5:	83 c4 10             	add    $0x10,%esp
	*cnt++;
}
f01030f8:	c9                   	leave  
f01030f9:	c3                   	ret    

f01030fa <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01030fa:	55                   	push   %ebp
f01030fb:	89 e5                	mov    %esp,%ebp
f01030fd:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0103100:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103107:	ff 75 0c             	pushl  0xc(%ebp)
f010310a:	ff 75 08             	pushl  0x8(%ebp)
f010310d:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103110:	50                   	push   %eax
f0103111:	68 e7 30 10 f0       	push   $0xf01030e7
f0103116:	e8 5a 0b 00 00       	call   f0103c75 <vprintfmt>
	return cnt;
}
f010311b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010311e:	c9                   	leave  
f010311f:	c3                   	ret    

f0103120 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103120:	55                   	push   %ebp
f0103121:	89 e5                	mov    %esp,%ebp
f0103123:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103126:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103129:	50                   	push   %eax
f010312a:	ff 75 08             	pushl  0x8(%ebp)
f010312d:	e8 c8 ff ff ff       	call   f01030fa <vcprintf>
	va_end(ap);

	return cnt;
}
f0103132:	c9                   	leave  
f0103133:	c3                   	ret    

f0103134 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103134:	55                   	push   %ebp
f0103135:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103137:	b8 80 da 17 f0       	mov    $0xf017da80,%eax
f010313c:	c7 05 84 da 17 f0 00 	movl   $0xf0000000,0xf017da84
f0103143:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0103146:	66 c7 05 88 da 17 f0 	movw   $0x10,0xf017da88
f010314d:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f010314f:	66 c7 05 48 b3 11 f0 	movw   $0x67,0xf011b348
f0103156:	67 00 
f0103158:	66 a3 4a b3 11 f0    	mov    %ax,0xf011b34a
f010315e:	89 c2                	mov    %eax,%edx
f0103160:	c1 ea 10             	shr    $0x10,%edx
f0103163:	88 15 4c b3 11 f0    	mov    %dl,0xf011b34c
f0103169:	c6 05 4e b3 11 f0 40 	movb   $0x40,0xf011b34e
f0103170:	c1 e8 18             	shr    $0x18,%eax
f0103173:	a2 4f b3 11 f0       	mov    %al,0xf011b34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103178:	c6 05 4d b3 11 f0 89 	movb   $0x89,0xf011b34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f010317f:	b8 28 00 00 00       	mov    $0x28,%eax
f0103184:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0103187:	b8 50 b3 11 f0       	mov    $0xf011b350,%eax
f010318c:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f010318f:	5d                   	pop    %ebp
f0103190:	c3                   	ret    

f0103191 <trap_init>:
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i; 
	for (i=0; i<= T_SIMDERR;i++){
f0103191:	b8 00 00 00 00       	mov    $0x0,%eax
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
f0103196:	8b 14 85 56 b3 11 f0 	mov    -0xfee4caa(,%eax,4),%edx
f010319d:	66 89 14 c5 40 d2 17 	mov    %dx,-0xfe82dc0(,%eax,8)
f01031a4:	f0 
f01031a5:	66 c7 04 c5 42 d2 17 	movw   $0x8,-0xfe82dbe(,%eax,8)
f01031ac:	f0 08 00 
f01031af:	c6 04 c5 44 d2 17 f0 	movb   $0x0,-0xfe82dbc(,%eax,8)
f01031b6:	00 
f01031b7:	c6 04 c5 45 d2 17 f0 	movb   $0x8e,-0xfe82dbb(,%eax,8)
f01031be:	8e 
f01031bf:	c1 ea 10             	shr    $0x10,%edx
f01031c2:	66 89 14 c5 46 d2 17 	mov    %dx,-0xfe82dba(,%eax,8)
f01031c9:	f0 
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i; 
	for (i=0; i<= T_SIMDERR;i++){
f01031ca:	83 c0 01             	add    $0x1,%eax
f01031cd:	83 f8 14             	cmp    $0x14,%eax
f01031d0:	75 c4                	jne    f0103196 <trap_init+0x5>
}


void
trap_init(void)
{
f01031d2:	55                   	push   %ebp
f01031d3:	89 e5                	mov    %esp,%ebp
	for (i=0; i<= T_SIMDERR;i++){
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
	}

	//Interrupt 3 is a soft interrupt generated by user, hence the dpl of the gate will be checked with 3
  	SETGATE(idt[3],0,GD_KT,int_vector_table[3],3);
f01031d5:	a1 62 b3 11 f0       	mov    0xf011b362,%eax
f01031da:	66 a3 58 d2 17 f0    	mov    %ax,0xf017d258
f01031e0:	66 c7 05 5a d2 17 f0 	movw   $0x8,0xf017d25a
f01031e7:	08 00 
f01031e9:	c6 05 5c d2 17 f0 00 	movb   $0x0,0xf017d25c
f01031f0:	c6 05 5d d2 17 f0 ee 	movb   $0xee,0xf017d25d
f01031f7:	c1 e8 10             	shr    $0x10,%eax
f01031fa:	66 a3 5e d2 17 f0    	mov    %ax,0xf017d25e

	//similarly system call is setup by the user and hence the gate should be checked with 3 
	SETGATE(idt[T_SYSCALL], 0, GD_KT, int_vector_table[T_SYSCALL], 3);// T_SYSCALL = 3
f0103200:	a1 16 b4 11 f0       	mov    0xf011b416,%eax
f0103205:	66 a3 c0 d3 17 f0    	mov    %ax,0xf017d3c0
f010320b:	66 c7 05 c2 d3 17 f0 	movw   $0x8,0xf017d3c2
f0103212:	08 00 
f0103214:	c6 05 c4 d3 17 f0 00 	movb   $0x0,0xf017d3c4
f010321b:	c6 05 c5 d3 17 f0 ee 	movb   $0xee,0xf017d3c5
f0103222:	c1 e8 10             	shr    $0x10,%eax
f0103225:	66 a3 c6 d3 17 f0    	mov    %ax,0xf017d3c6

	// Per-CPU setup 
	trap_init_percpu();
f010322b:	e8 04 ff ff ff       	call   f0103134 <trap_init_percpu>
}
f0103230:	5d                   	pop    %ebp
f0103231:	c3                   	ret    

f0103232 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103232:	55                   	push   %ebp
f0103233:	89 e5                	mov    %esp,%ebp
f0103235:	53                   	push   %ebx
f0103236:	83 ec 0c             	sub    $0xc,%esp
f0103239:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f010323c:	ff 33                	pushl  (%ebx)
f010323e:	68 ea 59 10 f0       	push   $0xf01059ea
f0103243:	e8 d8 fe ff ff       	call   f0103120 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103248:	83 c4 08             	add    $0x8,%esp
f010324b:	ff 73 04             	pushl  0x4(%ebx)
f010324e:	68 f9 59 10 f0       	push   $0xf01059f9
f0103253:	e8 c8 fe ff ff       	call   f0103120 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103258:	83 c4 08             	add    $0x8,%esp
f010325b:	ff 73 08             	pushl  0x8(%ebx)
f010325e:	68 08 5a 10 f0       	push   $0xf0105a08
f0103263:	e8 b8 fe ff ff       	call   f0103120 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103268:	83 c4 08             	add    $0x8,%esp
f010326b:	ff 73 0c             	pushl  0xc(%ebx)
f010326e:	68 17 5a 10 f0       	push   $0xf0105a17
f0103273:	e8 a8 fe ff ff       	call   f0103120 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103278:	83 c4 08             	add    $0x8,%esp
f010327b:	ff 73 10             	pushl  0x10(%ebx)
f010327e:	68 26 5a 10 f0       	push   $0xf0105a26
f0103283:	e8 98 fe ff ff       	call   f0103120 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103288:	83 c4 08             	add    $0x8,%esp
f010328b:	ff 73 14             	pushl  0x14(%ebx)
f010328e:	68 35 5a 10 f0       	push   $0xf0105a35
f0103293:	e8 88 fe ff ff       	call   f0103120 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103298:	83 c4 08             	add    $0x8,%esp
f010329b:	ff 73 18             	pushl  0x18(%ebx)
f010329e:	68 44 5a 10 f0       	push   $0xf0105a44
f01032a3:	e8 78 fe ff ff       	call   f0103120 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f01032a8:	83 c4 08             	add    $0x8,%esp
f01032ab:	ff 73 1c             	pushl  0x1c(%ebx)
f01032ae:	68 53 5a 10 f0       	push   $0xf0105a53
f01032b3:	e8 68 fe ff ff       	call   f0103120 <cprintf>
f01032b8:	83 c4 10             	add    $0x10,%esp
}
f01032bb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01032be:	c9                   	leave  
f01032bf:	c3                   	ret    

f01032c0 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f01032c0:	55                   	push   %ebp
f01032c1:	89 e5                	mov    %esp,%ebp
f01032c3:	56                   	push   %esi
f01032c4:	53                   	push   %ebx
f01032c5:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f01032c8:	83 ec 08             	sub    $0x8,%esp
f01032cb:	53                   	push   %ebx
f01032cc:	68 89 5b 10 f0       	push   $0xf0105b89
f01032d1:	e8 4a fe ff ff       	call   f0103120 <cprintf>
	print_regs(&tf->tf_regs);
f01032d6:	89 1c 24             	mov    %ebx,(%esp)
f01032d9:	e8 54 ff ff ff       	call   f0103232 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f01032de:	83 c4 08             	add    $0x8,%esp
f01032e1:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f01032e5:	50                   	push   %eax
f01032e6:	68 a4 5a 10 f0       	push   $0xf0105aa4
f01032eb:	e8 30 fe ff ff       	call   f0103120 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f01032f0:	83 c4 08             	add    $0x8,%esp
f01032f3:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f01032f7:	50                   	push   %eax
f01032f8:	68 b7 5a 10 f0       	push   $0xf0105ab7
f01032fd:	e8 1e fe ff ff       	call   f0103120 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103302:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103305:	83 c4 10             	add    $0x10,%esp
f0103308:	83 f8 13             	cmp    $0x13,%eax
f010330b:	77 09                	ja     f0103316 <print_trapframe+0x56>
		return excnames[trapno];
f010330d:	8b 14 85 c0 5d 10 f0 	mov    -0xfefa240(,%eax,4),%edx
f0103314:	eb 10                	jmp    f0103326 <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f0103316:	83 f8 30             	cmp    $0x30,%eax
f0103319:	b9 6e 5a 10 f0       	mov    $0xf0105a6e,%ecx
f010331e:	ba 62 5a 10 f0       	mov    $0xf0105a62,%edx
f0103323:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103326:	83 ec 04             	sub    $0x4,%esp
f0103329:	52                   	push   %edx
f010332a:	50                   	push   %eax
f010332b:	68 ca 5a 10 f0       	push   $0xf0105aca
f0103330:	e8 eb fd ff ff       	call   f0103120 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103335:	83 c4 10             	add    $0x10,%esp
f0103338:	3b 1d 40 da 17 f0    	cmp    0xf017da40,%ebx
f010333e:	75 1a                	jne    f010335a <print_trapframe+0x9a>
f0103340:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103344:	75 14                	jne    f010335a <print_trapframe+0x9a>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103346:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103349:	83 ec 08             	sub    $0x8,%esp
f010334c:	50                   	push   %eax
f010334d:	68 dc 5a 10 f0       	push   $0xf0105adc
f0103352:	e8 c9 fd ff ff       	call   f0103120 <cprintf>
f0103357:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f010335a:	83 ec 08             	sub    $0x8,%esp
f010335d:	ff 73 2c             	pushl  0x2c(%ebx)
f0103360:	68 eb 5a 10 f0       	push   $0xf0105aeb
f0103365:	e8 b6 fd ff ff       	call   f0103120 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f010336a:	83 c4 10             	add    $0x10,%esp
f010336d:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103371:	75 49                	jne    f01033bc <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103373:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103376:	89 c2                	mov    %eax,%edx
f0103378:	83 e2 01             	and    $0x1,%edx
f010337b:	ba 88 5a 10 f0       	mov    $0xf0105a88,%edx
f0103380:	b9 7d 5a 10 f0       	mov    $0xf0105a7d,%ecx
f0103385:	0f 44 ca             	cmove  %edx,%ecx
f0103388:	89 c2                	mov    %eax,%edx
f010338a:	83 e2 02             	and    $0x2,%edx
f010338d:	ba 9a 5a 10 f0       	mov    $0xf0105a9a,%edx
f0103392:	be 94 5a 10 f0       	mov    $0xf0105a94,%esi
f0103397:	0f 45 d6             	cmovne %esi,%edx
f010339a:	83 e0 04             	and    $0x4,%eax
f010339d:	be d0 5b 10 f0       	mov    $0xf0105bd0,%esi
f01033a2:	b8 9f 5a 10 f0       	mov    $0xf0105a9f,%eax
f01033a7:	0f 44 c6             	cmove  %esi,%eax
f01033aa:	51                   	push   %ecx
f01033ab:	52                   	push   %edx
f01033ac:	50                   	push   %eax
f01033ad:	68 f9 5a 10 f0       	push   $0xf0105af9
f01033b2:	e8 69 fd ff ff       	call   f0103120 <cprintf>
f01033b7:	83 c4 10             	add    $0x10,%esp
f01033ba:	eb 10                	jmp    f01033cc <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f01033bc:	83 ec 0c             	sub    $0xc,%esp
f01033bf:	68 5c 5e 10 f0       	push   $0xf0105e5c
f01033c4:	e8 57 fd ff ff       	call   f0103120 <cprintf>
f01033c9:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f01033cc:	83 ec 08             	sub    $0x8,%esp
f01033cf:	ff 73 30             	pushl  0x30(%ebx)
f01033d2:	68 08 5b 10 f0       	push   $0xf0105b08
f01033d7:	e8 44 fd ff ff       	call   f0103120 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f01033dc:	83 c4 08             	add    $0x8,%esp
f01033df:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f01033e3:	50                   	push   %eax
f01033e4:	68 17 5b 10 f0       	push   $0xf0105b17
f01033e9:	e8 32 fd ff ff       	call   f0103120 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f01033ee:	83 c4 08             	add    $0x8,%esp
f01033f1:	ff 73 38             	pushl  0x38(%ebx)
f01033f4:	68 2a 5b 10 f0       	push   $0xf0105b2a
f01033f9:	e8 22 fd ff ff       	call   f0103120 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f01033fe:	83 c4 10             	add    $0x10,%esp
f0103401:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103405:	74 25                	je     f010342c <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103407:	83 ec 08             	sub    $0x8,%esp
f010340a:	ff 73 3c             	pushl  0x3c(%ebx)
f010340d:	68 39 5b 10 f0       	push   $0xf0105b39
f0103412:	e8 09 fd ff ff       	call   f0103120 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103417:	83 c4 08             	add    $0x8,%esp
f010341a:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f010341e:	50                   	push   %eax
f010341f:	68 48 5b 10 f0       	push   $0xf0105b48
f0103424:	e8 f7 fc ff ff       	call   f0103120 <cprintf>
f0103429:	83 c4 10             	add    $0x10,%esp
	}
}
f010342c:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010342f:	5b                   	pop    %ebx
f0103430:	5e                   	pop    %esi
f0103431:	5d                   	pop    %ebp
f0103432:	c3                   	ret    

f0103433 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103433:	55                   	push   %ebp
f0103434:	89 e5                	mov    %esp,%ebp
f0103436:	53                   	push   %ebx
f0103437:	83 ec 04             	sub    $0x4,%esp
f010343a:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010343d:	0f 20 d0             	mov    %cr2,%eax
	// LAB 3: Your code here.


	//If the processor is already in kernel mode when the interrupt or exception occurs 
	//(the low 2 bits of the CS register are already zero), Hence we have to check the CS register to make sure its in kernel mode
	if ((tf->tf_cs & 0x11) == 0){
f0103440:	f6 43 34 11          	testb  $0x11,0x34(%ebx)
f0103444:	75 15                	jne    f010345b <page_fault_handler+0x28>
		panic("Fault occured in kernel space on %08x \n",fault_va);
f0103446:	50                   	push   %eax
f0103447:	68 1c 5d 10 f0       	push   $0xf0105d1c
f010344c:	68 f6 00 00 00       	push   $0xf6
f0103451:	68 5b 5b 10 f0       	push   $0xf0105b5b
f0103456:	e8 45 cc ff ff       	call   f01000a0 <_panic>

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f010345b:	ff 73 30             	pushl  0x30(%ebx)
f010345e:	50                   	push   %eax
f010345f:	a1 2c d2 17 f0       	mov    0xf017d22c,%eax
f0103464:	ff 70 48             	pushl  0x48(%eax)
f0103467:	68 44 5d 10 f0       	push   $0xf0105d44
f010346c:	e8 af fc ff ff       	call   f0103120 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103471:	89 1c 24             	mov    %ebx,(%esp)
f0103474:	e8 47 fe ff ff       	call   f01032c0 <print_trapframe>
	env_destroy(curenv);
f0103479:	83 c4 04             	add    $0x4,%esp
f010347c:	ff 35 2c d2 17 f0    	pushl  0xf017d22c
f0103482:	e8 86 fb ff ff       	call   f010300d <env_destroy>
f0103487:	83 c4 10             	add    $0x10,%esp
}
f010348a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010348d:	c9                   	leave  
f010348e:	c3                   	ret    

f010348f <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f010348f:	55                   	push   %ebp
f0103490:	89 e5                	mov    %esp,%ebp
f0103492:	57                   	push   %edi
f0103493:	56                   	push   %esi
f0103494:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103497:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103498:	9c                   	pushf  
f0103499:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f010349a:	f6 c4 02             	test   $0x2,%ah
f010349d:	74 19                	je     f01034b8 <trap+0x29>
f010349f:	68 67 5b 10 f0       	push   $0xf0105b67
f01034a4:	68 db 55 10 f0       	push   $0xf01055db
f01034a9:	68 c9 00 00 00       	push   $0xc9
f01034ae:	68 5b 5b 10 f0       	push   $0xf0105b5b
f01034b3:	e8 e8 cb ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f01034b8:	83 ec 08             	sub    $0x8,%esp
f01034bb:	56                   	push   %esi
f01034bc:	68 80 5b 10 f0       	push   $0xf0105b80
f01034c1:	e8 5a fc ff ff       	call   f0103120 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f01034c6:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f01034ca:	83 e0 03             	and    $0x3,%eax
f01034cd:	83 c4 10             	add    $0x10,%esp
f01034d0:	66 83 f8 03          	cmp    $0x3,%ax
f01034d4:	75 31                	jne    f0103507 <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f01034d6:	a1 2c d2 17 f0       	mov    0xf017d22c,%eax
f01034db:	85 c0                	test   %eax,%eax
f01034dd:	75 19                	jne    f01034f8 <trap+0x69>
f01034df:	68 9b 5b 10 f0       	push   $0xf0105b9b
f01034e4:	68 db 55 10 f0       	push   $0xf01055db
f01034e9:	68 cf 00 00 00       	push   $0xcf
f01034ee:	68 5b 5b 10 f0       	push   $0xf0105b5b
f01034f3:	e8 a8 cb ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f01034f8:	b9 11 00 00 00       	mov    $0x11,%ecx
f01034fd:	89 c7                	mov    %eax,%edi
f01034ff:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103501:	8b 35 2c d2 17 f0    	mov    0xf017d22c,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103507:	89 35 40 da 17 f0    	mov    %esi,0xf017da40
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	//call trap_handler function for page_fault
	switch (tf->tf_trapno) {
f010350d:	8b 46 28             	mov    0x28(%esi),%eax
f0103510:	83 f8 0e             	cmp    $0xe,%eax
f0103513:	74 24                	je     f0103539 <trap+0xaa>
f0103515:	83 f8 30             	cmp    $0x30,%eax
f0103518:	74 2d                	je     f0103547 <trap+0xb8>
f010351a:	83 f8 03             	cmp    $0x3,%eax
f010351d:	75 49                	jne    f0103568 <trap+0xd9>
		case T_BRKPT:
			monitor(tf);
f010351f:	83 ec 0c             	sub    $0xc,%esp
f0103522:	56                   	push   %esi
f0103523:	e8 66 d2 ff ff       	call   f010078e <monitor>
			cprintf("return from breakpoint....\n");
f0103528:	c7 04 24 a2 5b 10 f0 	movl   $0xf0105ba2,(%esp)
f010352f:	e8 ec fb ff ff       	call   f0103120 <cprintf>
f0103534:	83 c4 10             	add    $0x10,%esp
f0103537:	eb 2f                	jmp    f0103568 <trap+0xd9>
			break;

		case T_PGFLT:
			page_fault_handler(tf);
f0103539:	83 ec 0c             	sub    $0xc,%esp
f010353c:	56                   	push   %esi
f010353d:	e8 f1 fe ff ff       	call   f0103433 <page_fault_handler>
f0103542:	83 c4 10             	add    $0x10,%esp
f0103545:	eb 21                	jmp    f0103568 <trap+0xd9>
			break;

		case T_SYSCALL:
			tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax,
f0103547:	83 ec 08             	sub    $0x8,%esp
f010354a:	ff 76 04             	pushl  0x4(%esi)
f010354d:	ff 36                	pushl  (%esi)
f010354f:	ff 76 10             	pushl  0x10(%esi)
f0103552:	ff 76 18             	pushl  0x18(%esi)
f0103555:	ff 76 14             	pushl  0x14(%esi)
f0103558:	ff 76 1c             	pushl  0x1c(%esi)
f010355b:	e8 48 01 00 00       	call   f01036a8 <syscall>
f0103560:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103563:	83 c4 20             	add    $0x20,%esp
f0103566:	eb 3b                	jmp    f01035a3 <trap+0x114>
			//asm volatile("movl %%eax, %0\n" : "=m"(tf->tf_regs.reg_eax) ::);
			return;
	}

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103568:	83 ec 0c             	sub    $0xc,%esp
f010356b:	56                   	push   %esi
f010356c:	e8 4f fd ff ff       	call   f01032c0 <print_trapframe>
	if (tf->tf_cs == GD_KT){
f0103571:	83 c4 10             	add    $0x10,%esp
f0103574:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103579:	75 17                	jne    f0103592 <trap+0x103>
		panic("unhandled trap in kernel");
f010357b:	83 ec 04             	sub    $0x4,%esp
f010357e:	68 be 5b 10 f0       	push   $0xf0105bbe
f0103583:	68 b7 00 00 00       	push   $0xb7
f0103588:	68 5b 5b 10 f0       	push   $0xf0105b5b
f010358d:	e8 0e cb ff ff       	call   f01000a0 <_panic>
	}
	else {
		env_destroy(curenv);
f0103592:	83 ec 0c             	sub    $0xc,%esp
f0103595:	ff 35 2c d2 17 f0    	pushl  0xf017d22c
f010359b:	e8 6d fa ff ff       	call   f010300d <env_destroy>
f01035a0:	83 c4 10             	add    $0x10,%esp

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f01035a3:	a1 2c d2 17 f0       	mov    0xf017d22c,%eax
f01035a8:	85 c0                	test   %eax,%eax
f01035aa:	74 06                	je     f01035b2 <trap+0x123>
f01035ac:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01035b0:	74 19                	je     f01035cb <trap+0x13c>
f01035b2:	68 68 5d 10 f0       	push   $0xf0105d68
f01035b7:	68 db 55 10 f0       	push   $0xf01055db
f01035bc:	68 e1 00 00 00       	push   $0xe1
f01035c1:	68 5b 5b 10 f0       	push   $0xf0105b5b
f01035c6:	e8 d5 ca ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f01035cb:	83 ec 0c             	sub    $0xc,%esp
f01035ce:	50                   	push   %eax
f01035cf:	e8 89 fa ff ff       	call   f010305d <env_run>

f01035d4 <handler_0>:
#define T_DEFAULT   500		// catchall
*/

//TRAPHANDLER_NOEC for traps without error code
// From 0-7 no error code requred
	TRAPHANDLER_NOEC(handler_0, 0)   #Divide error
f01035d4:	6a 00                	push   $0x0
f01035d6:	6a 00                	push   $0x0
f01035d8:	e9 ba 00 00 00       	jmp    f0103697 <_alltraps>
f01035dd:	90                   	nop

f01035de <handler_1>:
	TRAPHANDLER_NOEC(handler_1, 1)   #Debug exceptions 
f01035de:	6a 00                	push   $0x0
f01035e0:	6a 01                	push   $0x1
f01035e2:	e9 b0 00 00 00       	jmp    f0103697 <_alltraps>
f01035e7:	90                   	nop

f01035e8 <handler_2>:
 	TRAPHANDLER_NOEC(handler_2, 2)   //NMI Interrupt
f01035e8:	6a 00                	push   $0x0
f01035ea:	6a 02                	push   $0x2
f01035ec:	e9 a6 00 00 00       	jmp    f0103697 <_alltraps>
f01035f1:	90                   	nop

f01035f2 <handler_3>:
	TRAPHANDLER_NOEC(handler_3, 3)   //Breakpoint
f01035f2:	6a 00                	push   $0x0
f01035f4:	6a 03                	push   $0x3
f01035f6:	e9 9c 00 00 00       	jmp    f0103697 <_alltraps>
f01035fb:	90                   	nop

f01035fc <handler_4>:
	TRAPHANDLER_NOEC(handler_4, 4)   //Overflow
f01035fc:	6a 00                	push   $0x0
f01035fe:	6a 04                	push   $0x4
f0103600:	e9 92 00 00 00       	jmp    f0103697 <_alltraps>
f0103605:	90                   	nop

f0103606 <handler_5>:
	TRAPHANDLER_NOEC(handler_5, 5)   //Bounds check 
f0103606:	6a 00                	push   $0x0
f0103608:	6a 05                	push   $0x5
f010360a:	e9 88 00 00 00       	jmp    f0103697 <_alltraps>
f010360f:	90                   	nop

f0103610 <handler_6>:
	TRAPHANDLER_NOEC(handler_6, 6)   //Invalid opcode
f0103610:	6a 00                	push   $0x0
f0103612:	6a 06                	push   $0x6
f0103614:	e9 7e 00 00 00       	jmp    f0103697 <_alltraps>
f0103619:	90                   	nop

f010361a <handler_7>:
	TRAPHANDLER_NOEC(handler_7, 7)   //Coprocessor not available
f010361a:	6a 00                	push   $0x0
f010361c:	6a 07                	push   $0x7
f010361e:	e9 74 00 00 00       	jmp    f0103697 <_alltraps>
f0103623:	90                   	nop

f0103624 <handler_8>:
	
	TRAPHANDLER(handler_8, 8)   // double fault
f0103624:	6a 08                	push   $0x8
f0103626:	e9 6c 00 00 00       	jmp    f0103697 <_alltraps>
f010362b:	90                   	nop

f010362c <handler_9>:
	
	TRAPHANDLER_NOEC(handler_9, 9)   //Coprocessor Segment Overrun
f010362c:	6a 00                	push   $0x0
f010362e:	6a 09                	push   $0x9
f0103630:	e9 62 00 00 00       	jmp    f0103697 <_alltraps>
f0103635:	90                   	nop

f0103636 <handler_10>:

	TRAPHANDLER(handler_10, 10)   // invalid task switch segment
f0103636:	6a 0a                	push   $0xa
f0103638:	e9 5a 00 00 00       	jmp    f0103697 <_alltraps>
f010363d:	90                   	nop

f010363e <handler_11>:
	TRAPHANDLER(handler_11, 11)   // segment not present
f010363e:	6a 0b                	push   $0xb
f0103640:	e9 52 00 00 00       	jmp    f0103697 <_alltraps>
f0103645:	90                   	nop

f0103646 <handler_12>:
	TRAPHANDLER(handler_12, 12)   // stack exception
f0103646:	6a 0c                	push   $0xc
f0103648:	e9 4a 00 00 00       	jmp    f0103697 <_alltraps>
f010364d:	90                   	nop

f010364e <handler_13>:
	TRAPHANDLER(handler_13, 13)   // general protection fault
f010364e:	6a 0d                	push   $0xd
f0103650:	e9 42 00 00 00       	jmp    f0103697 <_alltraps>
f0103655:	90                   	nop

f0103656 <handler_14>:
	TRAPHANDLER(handler_14, 14)   // page fault
f0103656:	6a 0e                	push   $0xe
f0103658:	e9 3a 00 00 00       	jmp    f0103697 <_alltraps>
f010365d:	90                   	nop

f010365e <handler_15>:

	TRAPHANDLER_NOEC(handler_15, 15)   // Reserved
f010365e:	6a 00                	push   $0x0
f0103660:	6a 0f                	push   $0xf
f0103662:	e9 30 00 00 00       	jmp    f0103697 <_alltraps>
f0103667:	90                   	nop

f0103668 <handler_16>:

	TRAPHANDLER_NOEC(handler_16, 16)   // floating point error
f0103668:	6a 00                	push   $0x0
f010366a:	6a 10                	push   $0x10
f010366c:	e9 26 00 00 00       	jmp    f0103697 <_alltraps>
f0103671:	90                   	nop

f0103672 <handler_17>:

	TRAPHANDLER(handler_17, 17)   // aligment check
f0103672:	6a 11                	push   $0x11
f0103674:	e9 1e 00 00 00       	jmp    f0103697 <_alltraps>
f0103679:	90                   	nop

f010367a <handler_18>:

	TRAPHANDLER_NOEC(handler_18, 18)   // machine check
f010367a:	6a 00                	push   $0x0
f010367c:	6a 12                	push   $0x12
f010367e:	e9 14 00 00 00       	jmp    f0103697 <_alltraps>
f0103683:	90                   	nop

f0103684 <handler_19>:
	TRAPHANDLER_NOEC(handler_19, 19)   // SIMD floating point error
f0103684:	6a 00                	push   $0x0
f0103686:	6a 13                	push   $0x13
f0103688:	e9 0a 00 00 00       	jmp    f0103697 <_alltraps>
f010368d:	90                   	nop

f010368e <handler_48>:

	TRAPHANDLER_NOEC(handler_48, 48)   // system call
f010368e:	6a 00                	push   $0x0
f0103690:	6a 30                	push   $0x30
f0103692:	e9 00 00 00 00       	jmp    f0103697 <_alltraps>

f0103697 <_alltraps>:
 */

.globl _alltraps
_alltraps:
	#Remaining Trap frame
	push %ds
f0103697:	1e                   	push   %ds
	push %es
f0103698:	06                   	push   %es
	pushal
f0103699:	60                   	pusha  

	
	movw $GD_KD, %ax
f010369a:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f010369e:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f01036a0:	8e c0                	mov    %eax,%es

	#call Trap 
	pushl %esp
f01036a2:	54                   	push   %esp
	call trap
f01036a3:	e8 e7 fd ff ff       	call   f010348f <trap>

f01036a8 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01036a8:	55                   	push   %ebp
f01036a9:	89 e5                	mov    %esp,%ebp
f01036ab:	83 ec 18             	sub    $0x18,%esp
f01036ae:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	

	switch (syscallno) {
f01036b1:	83 f8 01             	cmp    $0x1,%eax
f01036b4:	74 47                	je     f01036fd <syscall+0x55>
f01036b6:	83 f8 01             	cmp    $0x1,%eax
f01036b9:	72 0f                	jb     f01036ca <syscall+0x22>
f01036bb:	83 f8 02             	cmp    $0x2,%eax
f01036be:	74 47                	je     f0103707 <syscall+0x5f>
f01036c0:	83 f8 03             	cmp    $0x3,%eax
f01036c3:	74 4c                	je     f0103711 <syscall+0x69>
f01036c5:	e9 ac 00 00 00       	jmp    f0103776 <syscall+0xce>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_P | PTE_U);
f01036ca:	6a 05                	push   $0x5
f01036cc:	ff 75 10             	pushl  0x10(%ebp)
f01036cf:	ff 75 0c             	pushl  0xc(%ebp)
f01036d2:	ff 35 2c d2 17 f0    	pushl  0xf017d22c
f01036d8:	e8 fe f2 ff ff       	call   f01029db <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01036dd:	83 c4 0c             	add    $0xc,%esp
f01036e0:	ff 75 0c             	pushl  0xc(%ebp)
f01036e3:	ff 75 10             	pushl  0x10(%ebp)
f01036e6:	68 10 5e 10 f0       	push   $0xf0105e10
f01036eb:	e8 30 fa ff ff       	call   f0103120 <cprintf>
f01036f0:	83 c4 10             	add    $0x10,%esp

	switch (syscallno) {

	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;
f01036f3:	b8 00 00 00 00       	mov    $0x0,%eax
f01036f8:	e9 8d 00 00 00       	jmp    f010378a <syscall+0xe2>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f01036fd:	e8 b0 cd ff ff       	call   f01004b2 <cons_getc>
	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;

	case SYS_cgetc:
		return sys_cgetc();
f0103702:	e9 83 00 00 00       	jmp    f010378a <syscall+0xe2>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0103707:	a1 2c d2 17 f0       	mov    0xf017d22c,%eax
f010370c:	8b 40 48             	mov    0x48(%eax),%eax

	case SYS_cgetc:
		return sys_cgetc();
		
	case SYS_getenvid:
		return sys_getenvid();
f010370f:	eb 79                	jmp    f010378a <syscall+0xe2>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0103711:	83 ec 04             	sub    $0x4,%esp
f0103714:	6a 01                	push   $0x1
f0103716:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103719:	50                   	push   %eax
f010371a:	ff 75 0c             	pushl  0xc(%ebp)
f010371d:	e8 89 f3 ff ff       	call   f0102aab <envid2env>
f0103722:	83 c4 10             	add    $0x10,%esp
f0103725:	85 c0                	test   %eax,%eax
f0103727:	78 61                	js     f010378a <syscall+0xe2>
		return r;
	if (e == curenv)
f0103729:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010372c:	8b 15 2c d2 17 f0    	mov    0xf017d22c,%edx
f0103732:	39 d0                	cmp    %edx,%eax
f0103734:	75 15                	jne    f010374b <syscall+0xa3>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0103736:	83 ec 08             	sub    $0x8,%esp
f0103739:	ff 70 48             	pushl  0x48(%eax)
f010373c:	68 15 5e 10 f0       	push   $0xf0105e15
f0103741:	e8 da f9 ff ff       	call   f0103120 <cprintf>
f0103746:	83 c4 10             	add    $0x10,%esp
f0103749:	eb 16                	jmp    f0103761 <syscall+0xb9>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f010374b:	83 ec 04             	sub    $0x4,%esp
f010374e:	ff 70 48             	pushl  0x48(%eax)
f0103751:	ff 72 48             	pushl  0x48(%edx)
f0103754:	68 30 5e 10 f0       	push   $0xf0105e30
f0103759:	e8 c2 f9 ff ff       	call   f0103120 <cprintf>
f010375e:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0103761:	83 ec 0c             	sub    $0xc,%esp
f0103764:	ff 75 f4             	pushl  -0xc(%ebp)
f0103767:	e8 a1 f8 ff ff       	call   f010300d <env_destroy>
f010376c:	83 c4 10             	add    $0x10,%esp
	return 0;
f010376f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103774:	eb 14                	jmp    f010378a <syscall+0xe2>
		
	case SYS_env_destroy:
		return sys_env_destroy(a1);
		
	default:
		panic("Invalid System Call \n");
f0103776:	83 ec 04             	sub    $0x4,%esp
f0103779:	68 48 5e 10 f0       	push   $0xf0105e48
f010377e:	6a 5b                	push   $0x5b
f0103780:	68 5e 5e 10 f0       	push   $0xf0105e5e
f0103785:	e8 16 c9 ff ff       	call   f01000a0 <_panic>
		return -E_INVAL;
	}
}
f010378a:	c9                   	leave  
f010378b:	c3                   	ret    

f010378c <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010378c:	55                   	push   %ebp
f010378d:	89 e5                	mov    %esp,%ebp
f010378f:	57                   	push   %edi
f0103790:	56                   	push   %esi
f0103791:	53                   	push   %ebx
f0103792:	83 ec 14             	sub    $0x14,%esp
f0103795:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103798:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010379b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010379e:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01037a1:	8b 1a                	mov    (%edx),%ebx
f01037a3:	8b 01                	mov    (%ecx),%eax
f01037a5:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01037a8:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01037af:	e9 88 00 00 00       	jmp    f010383c <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f01037b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01037b7:	01 d8                	add    %ebx,%eax
f01037b9:	89 c6                	mov    %eax,%esi
f01037bb:	c1 ee 1f             	shr    $0x1f,%esi
f01037be:	01 c6                	add    %eax,%esi
f01037c0:	d1 fe                	sar    %esi
f01037c2:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01037c5:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01037c8:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01037cb:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01037cd:	eb 03                	jmp    f01037d2 <stab_binsearch+0x46>
			m--;
f01037cf:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01037d2:	39 c3                	cmp    %eax,%ebx
f01037d4:	7f 1f                	jg     f01037f5 <stab_binsearch+0x69>
f01037d6:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01037da:	83 ea 0c             	sub    $0xc,%edx
f01037dd:	39 f9                	cmp    %edi,%ecx
f01037df:	75 ee                	jne    f01037cf <stab_binsearch+0x43>
f01037e1:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01037e4:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01037e7:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01037ea:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01037ee:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01037f1:	76 18                	jbe    f010380b <stab_binsearch+0x7f>
f01037f3:	eb 05                	jmp    f01037fa <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01037f5:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01037f8:	eb 42                	jmp    f010383c <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01037fa:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01037fd:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01037ff:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103802:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103809:	eb 31                	jmp    f010383c <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010380b:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010380e:	73 17                	jae    f0103827 <stab_binsearch+0x9b>
			*region_right = m - 1;
f0103810:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103813:	83 e8 01             	sub    $0x1,%eax
f0103816:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103819:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010381c:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010381e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103825:	eb 15                	jmp    f010383c <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103827:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010382a:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f010382d:	89 1e                	mov    %ebx,(%esi)
			l = m;
			addr++;
f010382f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103833:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103835:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010383c:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010383f:	0f 8e 6f ff ff ff    	jle    f01037b4 <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103845:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103849:	75 0f                	jne    f010385a <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f010384b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010384e:	8b 00                	mov    (%eax),%eax
f0103850:	83 e8 01             	sub    $0x1,%eax
f0103853:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103856:	89 06                	mov    %eax,(%esi)
f0103858:	eb 2c                	jmp    f0103886 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010385a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010385d:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010385f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103862:	8b 0e                	mov    (%esi),%ecx
f0103864:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103867:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010386a:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010386d:	eb 03                	jmp    f0103872 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010386f:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103872:	39 c8                	cmp    %ecx,%eax
f0103874:	7e 0b                	jle    f0103881 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0103876:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010387a:	83 ea 0c             	sub    $0xc,%edx
f010387d:	39 fb                	cmp    %edi,%ebx
f010387f:	75 ee                	jne    f010386f <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103881:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103884:	89 06                	mov    %eax,(%esi)
	}
}
f0103886:	83 c4 14             	add    $0x14,%esp
f0103889:	5b                   	pop    %ebx
f010388a:	5e                   	pop    %esi
f010388b:	5f                   	pop    %edi
f010388c:	5d                   	pop    %ebp
f010388d:	c3                   	ret    

f010388e <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010388e:	55                   	push   %ebp
f010388f:	89 e5                	mov    %esp,%ebp
f0103891:	57                   	push   %edi
f0103892:	56                   	push   %esi
f0103893:	53                   	push   %ebx
f0103894:	83 ec 3c             	sub    $0x3c,%esp
f0103897:	8b 7d 08             	mov    0x8(%ebp),%edi
f010389a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010389d:	c7 03 6d 5e 10 f0    	movl   $0xf0105e6d,(%ebx)
	info->eip_line = 0;
f01038a3:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01038aa:	c7 43 08 6d 5e 10 f0 	movl   $0xf0105e6d,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01038b1:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01038b8:	89 7b 10             	mov    %edi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01038bb:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01038c2:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01038c8:	0f 87 81 00 00 00    	ja     f010394f <debuginfo_eip+0xc1>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
f01038ce:	6a 05                	push   $0x5
f01038d0:	6a 10                	push   $0x10
f01038d2:	68 00 00 20 00       	push   $0x200000
f01038d7:	ff 35 2c d2 17 f0    	pushl  0xf017d22c
f01038dd:	e8 05 f0 ff ff       	call   f01028e7 <user_mem_check>
f01038e2:	83 c4 10             	add    $0x10,%esp
f01038e5:	85 c0                	test   %eax,%eax
f01038e7:	0f 88 08 02 00 00    	js     f0103af5 <debuginfo_eip+0x267>
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
		}
		stabs = usd->stabs;
f01038ed:	a1 00 00 20 00       	mov    0x200000,%eax
f01038f2:	89 c1                	mov    %eax,%ecx
f01038f4:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		stab_end = usd->stab_end;
f01038f7:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f01038fd:	a1 08 00 20 00       	mov    0x200008,%eax
f0103902:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f0103905:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f010390b:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
f010390e:	6a 05                	push   $0x5
f0103910:	89 f0                	mov    %esi,%eax
f0103912:	29 c8                	sub    %ecx,%eax
f0103914:	50                   	push   %eax
f0103915:	51                   	push   %ecx
f0103916:	ff 35 2c d2 17 f0    	pushl  0xf017d22c
f010391c:	e8 c6 ef ff ff       	call   f01028e7 <user_mem_check>
f0103921:	83 c4 10             	add    $0x10,%esp
f0103924:	85 c0                	test   %eax,%eax
f0103926:	0f 88 d0 01 00 00    	js     f0103afc <debuginfo_eip+0x26e>
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
		}

		if (user_mem_check(curenv, (const void *)stabstr,
f010392c:	6a 05                	push   $0x5
f010392e:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0103931:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f0103934:	29 ca                	sub    %ecx,%edx
f0103936:	52                   	push   %edx
f0103937:	51                   	push   %ecx
f0103938:	ff 35 2c d2 17 f0    	pushl  0xf017d22c
f010393e:	e8 a4 ef ff ff       	call   f01028e7 <user_mem_check>
f0103943:	83 c4 10             	add    $0x10,%esp
f0103946:	85 c0                	test   %eax,%eax
f0103948:	79 1f                	jns    f0103969 <debuginfo_eip+0xdb>
f010394a:	e9 b4 01 00 00       	jmp    f0103b03 <debuginfo_eip+0x275>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f010394f:	c7 45 bc a2 0a 11 f0 	movl   $0xf0110aa2,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103956:	c7 45 c0 31 e0 10 f0 	movl   $0xf010e031,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f010395d:	be 30 e0 10 f0       	mov    $0xf010e030,%esi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103962:	c7 45 c4 b0 60 10 f0 	movl   $0xf01060b0,-0x3c(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103969:	8b 45 bc             	mov    -0x44(%ebp),%eax
f010396c:	39 45 c0             	cmp    %eax,-0x40(%ebp)
f010396f:	0f 83 95 01 00 00    	jae    f0103b0a <debuginfo_eip+0x27c>
f0103975:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0103979:	0f 85 92 01 00 00    	jne    f0103b11 <debuginfo_eip+0x283>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010397f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103986:	2b 75 c4             	sub    -0x3c(%ebp),%esi
f0103989:	c1 fe 02             	sar    $0x2,%esi
f010398c:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f0103992:	83 e8 01             	sub    $0x1,%eax
f0103995:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103998:	83 ec 08             	sub    $0x8,%esp
f010399b:	57                   	push   %edi
f010399c:	6a 64                	push   $0x64
f010399e:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01039a1:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01039a4:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01039a7:	89 f0                	mov    %esi,%eax
f01039a9:	e8 de fd ff ff       	call   f010378c <stab_binsearch>
	if (lfile == 0)
f01039ae:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01039b1:	83 c4 10             	add    $0x10,%esp
f01039b4:	85 c0                	test   %eax,%eax
f01039b6:	0f 84 5c 01 00 00    	je     f0103b18 <debuginfo_eip+0x28a>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01039bc:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01039bf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01039c2:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01039c5:	83 ec 08             	sub    $0x8,%esp
f01039c8:	57                   	push   %edi
f01039c9:	6a 24                	push   $0x24
f01039cb:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01039ce:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01039d1:	89 f0                	mov    %esi,%eax
f01039d3:	e8 b4 fd ff ff       	call   f010378c <stab_binsearch>

	if (lfun <= rfun) {
f01039d8:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01039db:	8b 75 d8             	mov    -0x28(%ebp),%esi
f01039de:	83 c4 10             	add    $0x10,%esp
f01039e1:	39 f0                	cmp    %esi,%eax
f01039e3:	7f 32                	jg     f0103a17 <debuginfo_eip+0x189>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01039e5:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01039e8:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f01039eb:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f01039ee:	8b 11                	mov    (%ecx),%edx
f01039f0:	89 55 b8             	mov    %edx,-0x48(%ebp)
f01039f3:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01039f6:	2b 55 c0             	sub    -0x40(%ebp),%edx
f01039f9:	39 55 b8             	cmp    %edx,-0x48(%ebp)
f01039fc:	73 09                	jae    f0103a07 <debuginfo_eip+0x179>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01039fe:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0103a01:	03 55 c0             	add    -0x40(%ebp),%edx
f0103a04:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103a07:	8b 51 08             	mov    0x8(%ecx),%edx
f0103a0a:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0103a0d:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0103a0f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103a12:	89 75 d0             	mov    %esi,-0x30(%ebp)
f0103a15:	eb 0f                	jmp    f0103a26 <debuginfo_eip+0x198>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103a17:	89 7b 10             	mov    %edi,0x10(%ebx)
		lline = lfile;
f0103a1a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103a1d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103a20:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103a23:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103a26:	83 ec 08             	sub    $0x8,%esp
f0103a29:	6a 3a                	push   $0x3a
f0103a2b:	ff 73 08             	pushl  0x8(%ebx)
f0103a2e:	e8 99 08 00 00       	call   f01042cc <strfind>
f0103a33:	2b 43 08             	sub    0x8(%ebx),%eax
f0103a36:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
f0103a39:	83 c4 08             	add    $0x8,%esp
f0103a3c:	57                   	push   %edi
f0103a3d:	6a 44                	push   $0x44
f0103a3f:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103a42:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103a45:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0103a48:	89 f0                	mov    %esi,%eax
f0103a4a:	e8 3d fd ff ff       	call   f010378c <stab_binsearch>
	if (lline > rline) {
f0103a4f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103a52:	83 c4 10             	add    $0x10,%esp
f0103a55:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103a58:	0f 8f c1 00 00 00    	jg     f0103b1f <debuginfo_eip+0x291>
		return -1; //Did not find the line number in the stab
	}
	info->eip_line = stabs[lline].n_desc; //If found update the info object with the correct line number
f0103a5e:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103a61:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0103a66:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103a69:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103a6c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103a6f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103a72:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0103a75:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103a78:	eb 06                	jmp    f0103a80 <debuginfo_eip+0x1f2>
f0103a7a:	83 e8 01             	sub    $0x1,%eax
f0103a7d:	83 ea 0c             	sub    $0xc,%edx
f0103a80:	39 c7                	cmp    %eax,%edi
f0103a82:	7f 2a                	jg     f0103aae <debuginfo_eip+0x220>
	       && stabs[lline].n_type != N_SOL
f0103a84:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103a88:	80 f9 84             	cmp    $0x84,%cl
f0103a8b:	0f 84 9c 00 00 00    	je     f0103b2d <debuginfo_eip+0x29f>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103a91:	80 f9 64             	cmp    $0x64,%cl
f0103a94:	75 e4                	jne    f0103a7a <debuginfo_eip+0x1ec>
f0103a96:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103a9a:	74 de                	je     f0103a7a <debuginfo_eip+0x1ec>
f0103a9c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103a9f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103aa2:	e9 8c 00 00 00       	jmp    f0103b33 <debuginfo_eip+0x2a5>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103aa7:	03 55 c0             	add    -0x40(%ebp),%edx
f0103aaa:	89 13                	mov    %edx,(%ebx)
f0103aac:	eb 03                	jmp    f0103ab1 <debuginfo_eip+0x223>
f0103aae:	8b 5d 0c             	mov    0xc(%ebp),%ebx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103ab1:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103ab4:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103ab7:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103abc:	39 f2                	cmp    %esi,%edx
f0103abe:	0f 8d 8b 00 00 00    	jge    f0103b4f <debuginfo_eip+0x2c1>
		for (lline = lfun + 1;
f0103ac4:	83 c2 01             	add    $0x1,%edx
f0103ac7:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103aca:	89 d0                	mov    %edx,%eax
f0103acc:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103acf:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0103ad2:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0103ad5:	eb 04                	jmp    f0103adb <debuginfo_eip+0x24d>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103ad7:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103adb:	39 c6                	cmp    %eax,%esi
f0103add:	7e 47                	jle    f0103b26 <debuginfo_eip+0x298>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103adf:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103ae3:	83 c0 01             	add    $0x1,%eax
f0103ae6:	83 c2 0c             	add    $0xc,%edx
f0103ae9:	80 f9 a0             	cmp    $0xa0,%cl
f0103aec:	74 e9                	je     f0103ad7 <debuginfo_eip+0x249>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103aee:	b8 00 00 00 00       	mov    $0x0,%eax
f0103af3:	eb 5a                	jmp    f0103b4f <debuginfo_eip+0x2c1>
		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
f0103af5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103afa:	eb 53                	jmp    f0103b4f <debuginfo_eip+0x2c1>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
f0103afc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b01:	eb 4c                	jmp    f0103b4f <debuginfo_eip+0x2c1>
		}

		if (user_mem_check(curenv, (const void *)stabstr,
				(uintptr_t)stabstr_end - (uintptr_t)stabstr, PTE_U | PTE_P) < 0) {
			return -1;
f0103b03:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b08:	eb 45                	jmp    f0103b4f <debuginfo_eip+0x2c1>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103b0a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b0f:	eb 3e                	jmp    f0103b4f <debuginfo_eip+0x2c1>
f0103b11:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b16:	eb 37                	jmp    f0103b4f <debuginfo_eip+0x2c1>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103b18:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b1d:	eb 30                	jmp    f0103b4f <debuginfo_eip+0x2c1>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
	if (lline > rline) {
		return -1; //Did not find the line number in the stab
f0103b1f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b24:	eb 29                	jmp    f0103b4f <debuginfo_eip+0x2c1>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103b26:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b2b:	eb 22                	jmp    f0103b4f <debuginfo_eip+0x2c1>
f0103b2d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103b30:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103b33:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103b36:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0103b39:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103b3c:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103b3f:	2b 45 c0             	sub    -0x40(%ebp),%eax
f0103b42:	39 c2                	cmp    %eax,%edx
f0103b44:	0f 82 5d ff ff ff    	jb     f0103aa7 <debuginfo_eip+0x219>
f0103b4a:	e9 62 ff ff ff       	jmp    f0103ab1 <debuginfo_eip+0x223>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
}
f0103b4f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103b52:	5b                   	pop    %ebx
f0103b53:	5e                   	pop    %esi
f0103b54:	5f                   	pop    %edi
f0103b55:	5d                   	pop    %ebp
f0103b56:	c3                   	ret    

f0103b57 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103b57:	55                   	push   %ebp
f0103b58:	89 e5                	mov    %esp,%ebp
f0103b5a:	57                   	push   %edi
f0103b5b:	56                   	push   %esi
f0103b5c:	53                   	push   %ebx
f0103b5d:	83 ec 1c             	sub    $0x1c,%esp
f0103b60:	89 c7                	mov    %eax,%edi
f0103b62:	89 d6                	mov    %edx,%esi
f0103b64:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b67:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103b6a:	89 d1                	mov    %edx,%ecx
f0103b6c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103b6f:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103b72:	8b 45 10             	mov    0x10(%ebp),%eax
f0103b75:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103b78:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103b7b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0103b82:	39 4d e4             	cmp    %ecx,-0x1c(%ebp)
f0103b85:	72 05                	jb     f0103b8c <printnum+0x35>
f0103b87:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0103b8a:	77 3e                	ja     f0103bca <printnum+0x73>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103b8c:	83 ec 0c             	sub    $0xc,%esp
f0103b8f:	ff 75 18             	pushl  0x18(%ebp)
f0103b92:	83 eb 01             	sub    $0x1,%ebx
f0103b95:	53                   	push   %ebx
f0103b96:	50                   	push   %eax
f0103b97:	83 ec 08             	sub    $0x8,%esp
f0103b9a:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103b9d:	ff 75 e0             	pushl  -0x20(%ebp)
f0103ba0:	ff 75 dc             	pushl  -0x24(%ebp)
f0103ba3:	ff 75 d8             	pushl  -0x28(%ebp)
f0103ba6:	e8 45 09 00 00       	call   f01044f0 <__udivdi3>
f0103bab:	83 c4 18             	add    $0x18,%esp
f0103bae:	52                   	push   %edx
f0103baf:	50                   	push   %eax
f0103bb0:	89 f2                	mov    %esi,%edx
f0103bb2:	89 f8                	mov    %edi,%eax
f0103bb4:	e8 9e ff ff ff       	call   f0103b57 <printnum>
f0103bb9:	83 c4 20             	add    $0x20,%esp
f0103bbc:	eb 13                	jmp    f0103bd1 <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103bbe:	83 ec 08             	sub    $0x8,%esp
f0103bc1:	56                   	push   %esi
f0103bc2:	ff 75 18             	pushl  0x18(%ebp)
f0103bc5:	ff d7                	call   *%edi
f0103bc7:	83 c4 10             	add    $0x10,%esp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103bca:	83 eb 01             	sub    $0x1,%ebx
f0103bcd:	85 db                	test   %ebx,%ebx
f0103bcf:	7f ed                	jg     f0103bbe <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103bd1:	83 ec 08             	sub    $0x8,%esp
f0103bd4:	56                   	push   %esi
f0103bd5:	83 ec 04             	sub    $0x4,%esp
f0103bd8:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103bdb:	ff 75 e0             	pushl  -0x20(%ebp)
f0103bde:	ff 75 dc             	pushl  -0x24(%ebp)
f0103be1:	ff 75 d8             	pushl  -0x28(%ebp)
f0103be4:	e8 37 0a 00 00       	call   f0104620 <__umoddi3>
f0103be9:	83 c4 14             	add    $0x14,%esp
f0103bec:	0f be 80 77 5e 10 f0 	movsbl -0xfefa189(%eax),%eax
f0103bf3:	50                   	push   %eax
f0103bf4:	ff d7                	call   *%edi
f0103bf6:	83 c4 10             	add    $0x10,%esp
}
f0103bf9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103bfc:	5b                   	pop    %ebx
f0103bfd:	5e                   	pop    %esi
f0103bfe:	5f                   	pop    %edi
f0103bff:	5d                   	pop    %ebp
f0103c00:	c3                   	ret    

f0103c01 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103c01:	55                   	push   %ebp
f0103c02:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103c04:	83 fa 01             	cmp    $0x1,%edx
f0103c07:	7e 0e                	jle    f0103c17 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103c09:	8b 10                	mov    (%eax),%edx
f0103c0b:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103c0e:	89 08                	mov    %ecx,(%eax)
f0103c10:	8b 02                	mov    (%edx),%eax
f0103c12:	8b 52 04             	mov    0x4(%edx),%edx
f0103c15:	eb 22                	jmp    f0103c39 <getuint+0x38>
	else if (lflag)
f0103c17:	85 d2                	test   %edx,%edx
f0103c19:	74 10                	je     f0103c2b <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103c1b:	8b 10                	mov    (%eax),%edx
f0103c1d:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103c20:	89 08                	mov    %ecx,(%eax)
f0103c22:	8b 02                	mov    (%edx),%eax
f0103c24:	ba 00 00 00 00       	mov    $0x0,%edx
f0103c29:	eb 0e                	jmp    f0103c39 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103c2b:	8b 10                	mov    (%eax),%edx
f0103c2d:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103c30:	89 08                	mov    %ecx,(%eax)
f0103c32:	8b 02                	mov    (%edx),%eax
f0103c34:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103c39:	5d                   	pop    %ebp
f0103c3a:	c3                   	ret    

f0103c3b <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103c3b:	55                   	push   %ebp
f0103c3c:	89 e5                	mov    %esp,%ebp
f0103c3e:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103c41:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103c45:	8b 10                	mov    (%eax),%edx
f0103c47:	3b 50 04             	cmp    0x4(%eax),%edx
f0103c4a:	73 0a                	jae    f0103c56 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103c4c:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103c4f:	89 08                	mov    %ecx,(%eax)
f0103c51:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c54:	88 02                	mov    %al,(%edx)
}
f0103c56:	5d                   	pop    %ebp
f0103c57:	c3                   	ret    

f0103c58 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103c58:	55                   	push   %ebp
f0103c59:	89 e5                	mov    %esp,%ebp
f0103c5b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103c5e:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103c61:	50                   	push   %eax
f0103c62:	ff 75 10             	pushl  0x10(%ebp)
f0103c65:	ff 75 0c             	pushl  0xc(%ebp)
f0103c68:	ff 75 08             	pushl  0x8(%ebp)
f0103c6b:	e8 05 00 00 00       	call   f0103c75 <vprintfmt>
	va_end(ap);
f0103c70:	83 c4 10             	add    $0x10,%esp
}
f0103c73:	c9                   	leave  
f0103c74:	c3                   	ret    

f0103c75 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103c75:	55                   	push   %ebp
f0103c76:	89 e5                	mov    %esp,%ebp
f0103c78:	57                   	push   %edi
f0103c79:	56                   	push   %esi
f0103c7a:	53                   	push   %ebx
f0103c7b:	83 ec 2c             	sub    $0x2c,%esp
f0103c7e:	8b 75 08             	mov    0x8(%ebp),%esi
f0103c81:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103c84:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103c87:	eb 12                	jmp    f0103c9b <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103c89:	85 c0                	test   %eax,%eax
f0103c8b:	0f 84 90 03 00 00    	je     f0104021 <vprintfmt+0x3ac>
				return;
			putch(ch, putdat);
f0103c91:	83 ec 08             	sub    $0x8,%esp
f0103c94:	53                   	push   %ebx
f0103c95:	50                   	push   %eax
f0103c96:	ff d6                	call   *%esi
f0103c98:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103c9b:	83 c7 01             	add    $0x1,%edi
f0103c9e:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103ca2:	83 f8 25             	cmp    $0x25,%eax
f0103ca5:	75 e2                	jne    f0103c89 <vprintfmt+0x14>
f0103ca7:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103cab:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103cb2:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103cb9:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103cc0:	ba 00 00 00 00       	mov    $0x0,%edx
f0103cc5:	eb 07                	jmp    f0103cce <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103cc7:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103cca:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103cce:	8d 47 01             	lea    0x1(%edi),%eax
f0103cd1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103cd4:	0f b6 07             	movzbl (%edi),%eax
f0103cd7:	0f b6 c8             	movzbl %al,%ecx
f0103cda:	83 e8 23             	sub    $0x23,%eax
f0103cdd:	3c 55                	cmp    $0x55,%al
f0103cdf:	0f 87 21 03 00 00    	ja     f0104006 <vprintfmt+0x391>
f0103ce5:	0f b6 c0             	movzbl %al,%eax
f0103ce8:	ff 24 85 20 5f 10 f0 	jmp    *-0xfefa0e0(,%eax,4)
f0103cef:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103cf2:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103cf6:	eb d6                	jmp    f0103cce <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103cf8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103cfb:	b8 00 00 00 00       	mov    $0x0,%eax
f0103d00:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103d03:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103d06:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0103d0a:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0103d0d:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0103d10:	83 fa 09             	cmp    $0x9,%edx
f0103d13:	77 39                	ja     f0103d4e <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103d15:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103d18:	eb e9                	jmp    f0103d03 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103d1a:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d1d:	8d 48 04             	lea    0x4(%eax),%ecx
f0103d20:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103d23:	8b 00                	mov    (%eax),%eax
f0103d25:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d28:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103d2b:	eb 27                	jmp    f0103d54 <vprintfmt+0xdf>
f0103d2d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103d30:	85 c0                	test   %eax,%eax
f0103d32:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103d37:	0f 49 c8             	cmovns %eax,%ecx
f0103d3a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d3d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103d40:	eb 8c                	jmp    f0103cce <vprintfmt+0x59>
f0103d42:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103d45:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103d4c:	eb 80                	jmp    f0103cce <vprintfmt+0x59>
f0103d4e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103d51:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103d54:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103d58:	0f 89 70 ff ff ff    	jns    f0103cce <vprintfmt+0x59>
				width = precision, precision = -1;
f0103d5e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103d61:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103d64:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103d6b:	e9 5e ff ff ff       	jmp    f0103cce <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103d70:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d73:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103d76:	e9 53 ff ff ff       	jmp    f0103cce <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103d7b:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d7e:	8d 50 04             	lea    0x4(%eax),%edx
f0103d81:	89 55 14             	mov    %edx,0x14(%ebp)
f0103d84:	83 ec 08             	sub    $0x8,%esp
f0103d87:	53                   	push   %ebx
f0103d88:	ff 30                	pushl  (%eax)
f0103d8a:	ff d6                	call   *%esi
			break;
f0103d8c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d8f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103d92:	e9 04 ff ff ff       	jmp    f0103c9b <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103d97:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d9a:	8d 50 04             	lea    0x4(%eax),%edx
f0103d9d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103da0:	8b 00                	mov    (%eax),%eax
f0103da2:	99                   	cltd   
f0103da3:	31 d0                	xor    %edx,%eax
f0103da5:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103da7:	83 f8 07             	cmp    $0x7,%eax
f0103daa:	7f 0b                	jg     f0103db7 <vprintfmt+0x142>
f0103dac:	8b 14 85 80 60 10 f0 	mov    -0xfef9f80(,%eax,4),%edx
f0103db3:	85 d2                	test   %edx,%edx
f0103db5:	75 18                	jne    f0103dcf <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0103db7:	50                   	push   %eax
f0103db8:	68 8f 5e 10 f0       	push   $0xf0105e8f
f0103dbd:	53                   	push   %ebx
f0103dbe:	56                   	push   %esi
f0103dbf:	e8 94 fe ff ff       	call   f0103c58 <printfmt>
f0103dc4:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103dc7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103dca:	e9 cc fe ff ff       	jmp    f0103c9b <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103dcf:	52                   	push   %edx
f0103dd0:	68 ed 55 10 f0       	push   $0xf01055ed
f0103dd5:	53                   	push   %ebx
f0103dd6:	56                   	push   %esi
f0103dd7:	e8 7c fe ff ff       	call   f0103c58 <printfmt>
f0103ddc:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ddf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103de2:	e9 b4 fe ff ff       	jmp    f0103c9b <vprintfmt+0x26>
f0103de7:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103dea:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103ded:	89 45 cc             	mov    %eax,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103df0:	8b 45 14             	mov    0x14(%ebp),%eax
f0103df3:	8d 50 04             	lea    0x4(%eax),%edx
f0103df6:	89 55 14             	mov    %edx,0x14(%ebp)
f0103df9:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103dfb:	85 ff                	test   %edi,%edi
f0103dfd:	ba 88 5e 10 f0       	mov    $0xf0105e88,%edx
f0103e02:	0f 44 fa             	cmove  %edx,%edi
			if (width > 0 && padc != '-')
f0103e05:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103e09:	0f 84 92 00 00 00    	je     f0103ea1 <vprintfmt+0x22c>
f0103e0f:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0103e13:	0f 8e 96 00 00 00    	jle    f0103eaf <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103e19:	83 ec 08             	sub    $0x8,%esp
f0103e1c:	51                   	push   %ecx
f0103e1d:	57                   	push   %edi
f0103e1e:	e8 5f 03 00 00       	call   f0104182 <strnlen>
f0103e23:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0103e26:	29 c1                	sub    %eax,%ecx
f0103e28:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0103e2b:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103e2e:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103e32:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103e35:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103e38:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103e3a:	eb 0f                	jmp    f0103e4b <vprintfmt+0x1d6>
					putch(padc, putdat);
f0103e3c:	83 ec 08             	sub    $0x8,%esp
f0103e3f:	53                   	push   %ebx
f0103e40:	ff 75 e0             	pushl  -0x20(%ebp)
f0103e43:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103e45:	83 ef 01             	sub    $0x1,%edi
f0103e48:	83 c4 10             	add    $0x10,%esp
f0103e4b:	85 ff                	test   %edi,%edi
f0103e4d:	7f ed                	jg     f0103e3c <vprintfmt+0x1c7>
f0103e4f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103e52:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0103e55:	85 c9                	test   %ecx,%ecx
f0103e57:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e5c:	0f 49 c1             	cmovns %ecx,%eax
f0103e5f:	29 c1                	sub    %eax,%ecx
f0103e61:	89 75 08             	mov    %esi,0x8(%ebp)
f0103e64:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103e67:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103e6a:	89 cb                	mov    %ecx,%ebx
f0103e6c:	eb 4d                	jmp    f0103ebb <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103e6e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103e72:	74 1b                	je     f0103e8f <vprintfmt+0x21a>
f0103e74:	0f be c0             	movsbl %al,%eax
f0103e77:	83 e8 20             	sub    $0x20,%eax
f0103e7a:	83 f8 5e             	cmp    $0x5e,%eax
f0103e7d:	76 10                	jbe    f0103e8f <vprintfmt+0x21a>
					putch('?', putdat);
f0103e7f:	83 ec 08             	sub    $0x8,%esp
f0103e82:	ff 75 0c             	pushl  0xc(%ebp)
f0103e85:	6a 3f                	push   $0x3f
f0103e87:	ff 55 08             	call   *0x8(%ebp)
f0103e8a:	83 c4 10             	add    $0x10,%esp
f0103e8d:	eb 0d                	jmp    f0103e9c <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0103e8f:	83 ec 08             	sub    $0x8,%esp
f0103e92:	ff 75 0c             	pushl  0xc(%ebp)
f0103e95:	52                   	push   %edx
f0103e96:	ff 55 08             	call   *0x8(%ebp)
f0103e99:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103e9c:	83 eb 01             	sub    $0x1,%ebx
f0103e9f:	eb 1a                	jmp    f0103ebb <vprintfmt+0x246>
f0103ea1:	89 75 08             	mov    %esi,0x8(%ebp)
f0103ea4:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103ea7:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103eaa:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103ead:	eb 0c                	jmp    f0103ebb <vprintfmt+0x246>
f0103eaf:	89 75 08             	mov    %esi,0x8(%ebp)
f0103eb2:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103eb5:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103eb8:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103ebb:	83 c7 01             	add    $0x1,%edi
f0103ebe:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103ec2:	0f be d0             	movsbl %al,%edx
f0103ec5:	85 d2                	test   %edx,%edx
f0103ec7:	74 23                	je     f0103eec <vprintfmt+0x277>
f0103ec9:	85 f6                	test   %esi,%esi
f0103ecb:	78 a1                	js     f0103e6e <vprintfmt+0x1f9>
f0103ecd:	83 ee 01             	sub    $0x1,%esi
f0103ed0:	79 9c                	jns    f0103e6e <vprintfmt+0x1f9>
f0103ed2:	89 df                	mov    %ebx,%edi
f0103ed4:	8b 75 08             	mov    0x8(%ebp),%esi
f0103ed7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103eda:	eb 18                	jmp    f0103ef4 <vprintfmt+0x27f>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103edc:	83 ec 08             	sub    $0x8,%esp
f0103edf:	53                   	push   %ebx
f0103ee0:	6a 20                	push   $0x20
f0103ee2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103ee4:	83 ef 01             	sub    $0x1,%edi
f0103ee7:	83 c4 10             	add    $0x10,%esp
f0103eea:	eb 08                	jmp    f0103ef4 <vprintfmt+0x27f>
f0103eec:	89 df                	mov    %ebx,%edi
f0103eee:	8b 75 08             	mov    0x8(%ebp),%esi
f0103ef1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103ef4:	85 ff                	test   %edi,%edi
f0103ef6:	7f e4                	jg     f0103edc <vprintfmt+0x267>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ef8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103efb:	e9 9b fd ff ff       	jmp    f0103c9b <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103f00:	83 fa 01             	cmp    $0x1,%edx
f0103f03:	7e 16                	jle    f0103f1b <vprintfmt+0x2a6>
		return va_arg(*ap, long long);
f0103f05:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f08:	8d 50 08             	lea    0x8(%eax),%edx
f0103f0b:	89 55 14             	mov    %edx,0x14(%ebp)
f0103f0e:	8b 50 04             	mov    0x4(%eax),%edx
f0103f11:	8b 00                	mov    (%eax),%eax
f0103f13:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103f16:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103f19:	eb 32                	jmp    f0103f4d <vprintfmt+0x2d8>
	else if (lflag)
f0103f1b:	85 d2                	test   %edx,%edx
f0103f1d:	74 18                	je     f0103f37 <vprintfmt+0x2c2>
		return va_arg(*ap, long);
f0103f1f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f22:	8d 50 04             	lea    0x4(%eax),%edx
f0103f25:	89 55 14             	mov    %edx,0x14(%ebp)
f0103f28:	8b 00                	mov    (%eax),%eax
f0103f2a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103f2d:	89 c1                	mov    %eax,%ecx
f0103f2f:	c1 f9 1f             	sar    $0x1f,%ecx
f0103f32:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103f35:	eb 16                	jmp    f0103f4d <vprintfmt+0x2d8>
	else
		return va_arg(*ap, int);
f0103f37:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f3a:	8d 50 04             	lea    0x4(%eax),%edx
f0103f3d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103f40:	8b 00                	mov    (%eax),%eax
f0103f42:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103f45:	89 c1                	mov    %eax,%ecx
f0103f47:	c1 f9 1f             	sar    $0x1f,%ecx
f0103f4a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103f4d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103f50:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103f53:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103f58:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103f5c:	79 74                	jns    f0103fd2 <vprintfmt+0x35d>
				putch('-', putdat);
f0103f5e:	83 ec 08             	sub    $0x8,%esp
f0103f61:	53                   	push   %ebx
f0103f62:	6a 2d                	push   $0x2d
f0103f64:	ff d6                	call   *%esi
				num = -(long long) num;
f0103f66:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103f69:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103f6c:	f7 d8                	neg    %eax
f0103f6e:	83 d2 00             	adc    $0x0,%edx
f0103f71:	f7 da                	neg    %edx
f0103f73:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103f76:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103f7b:	eb 55                	jmp    f0103fd2 <vprintfmt+0x35d>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103f7d:	8d 45 14             	lea    0x14(%ebp),%eax
f0103f80:	e8 7c fc ff ff       	call   f0103c01 <getuint>
			base = 10;
f0103f85:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103f8a:	eb 46                	jmp    f0103fd2 <vprintfmt+0x35d>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0103f8c:	8d 45 14             	lea    0x14(%ebp),%eax
f0103f8f:	e8 6d fc ff ff       	call   f0103c01 <getuint>
			base = 8;
f0103f94:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0103f99:	eb 37                	jmp    f0103fd2 <vprintfmt+0x35d>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f0103f9b:	83 ec 08             	sub    $0x8,%esp
f0103f9e:	53                   	push   %ebx
f0103f9f:	6a 30                	push   $0x30
f0103fa1:	ff d6                	call   *%esi
			putch('x', putdat);
f0103fa3:	83 c4 08             	add    $0x8,%esp
f0103fa6:	53                   	push   %ebx
f0103fa7:	6a 78                	push   $0x78
f0103fa9:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103fab:	8b 45 14             	mov    0x14(%ebp),%eax
f0103fae:	8d 50 04             	lea    0x4(%eax),%edx
f0103fb1:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103fb4:	8b 00                	mov    (%eax),%eax
f0103fb6:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0103fbb:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103fbe:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103fc3:	eb 0d                	jmp    f0103fd2 <vprintfmt+0x35d>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103fc5:	8d 45 14             	lea    0x14(%ebp),%eax
f0103fc8:	e8 34 fc ff ff       	call   f0103c01 <getuint>
			base = 16;
f0103fcd:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103fd2:	83 ec 0c             	sub    $0xc,%esp
f0103fd5:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103fd9:	57                   	push   %edi
f0103fda:	ff 75 e0             	pushl  -0x20(%ebp)
f0103fdd:	51                   	push   %ecx
f0103fde:	52                   	push   %edx
f0103fdf:	50                   	push   %eax
f0103fe0:	89 da                	mov    %ebx,%edx
f0103fe2:	89 f0                	mov    %esi,%eax
f0103fe4:	e8 6e fb ff ff       	call   f0103b57 <printnum>
			break;
f0103fe9:	83 c4 20             	add    $0x20,%esp
f0103fec:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103fef:	e9 a7 fc ff ff       	jmp    f0103c9b <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103ff4:	83 ec 08             	sub    $0x8,%esp
f0103ff7:	53                   	push   %ebx
f0103ff8:	51                   	push   %ecx
f0103ff9:	ff d6                	call   *%esi
			break;
f0103ffb:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ffe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0104001:	e9 95 fc ff ff       	jmp    f0103c9b <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104006:	83 ec 08             	sub    $0x8,%esp
f0104009:	53                   	push   %ebx
f010400a:	6a 25                	push   $0x25
f010400c:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010400e:	83 c4 10             	add    $0x10,%esp
f0104011:	eb 03                	jmp    f0104016 <vprintfmt+0x3a1>
f0104013:	83 ef 01             	sub    $0x1,%edi
f0104016:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f010401a:	75 f7                	jne    f0104013 <vprintfmt+0x39e>
f010401c:	e9 7a fc ff ff       	jmp    f0103c9b <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0104021:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104024:	5b                   	pop    %ebx
f0104025:	5e                   	pop    %esi
f0104026:	5f                   	pop    %edi
f0104027:	5d                   	pop    %ebp
f0104028:	c3                   	ret    

f0104029 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104029:	55                   	push   %ebp
f010402a:	89 e5                	mov    %esp,%ebp
f010402c:	83 ec 18             	sub    $0x18,%esp
f010402f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104032:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104035:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104038:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010403c:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010403f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104046:	85 c0                	test   %eax,%eax
f0104048:	74 26                	je     f0104070 <vsnprintf+0x47>
f010404a:	85 d2                	test   %edx,%edx
f010404c:	7e 22                	jle    f0104070 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010404e:	ff 75 14             	pushl  0x14(%ebp)
f0104051:	ff 75 10             	pushl  0x10(%ebp)
f0104054:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104057:	50                   	push   %eax
f0104058:	68 3b 3c 10 f0       	push   $0xf0103c3b
f010405d:	e8 13 fc ff ff       	call   f0103c75 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104062:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104065:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104068:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010406b:	83 c4 10             	add    $0x10,%esp
f010406e:	eb 05                	jmp    f0104075 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104070:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104075:	c9                   	leave  
f0104076:	c3                   	ret    

f0104077 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104077:	55                   	push   %ebp
f0104078:	89 e5                	mov    %esp,%ebp
f010407a:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010407d:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104080:	50                   	push   %eax
f0104081:	ff 75 10             	pushl  0x10(%ebp)
f0104084:	ff 75 0c             	pushl  0xc(%ebp)
f0104087:	ff 75 08             	pushl  0x8(%ebp)
f010408a:	e8 9a ff ff ff       	call   f0104029 <vsnprintf>
	va_end(ap);

	return rc;
}
f010408f:	c9                   	leave  
f0104090:	c3                   	ret    

f0104091 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104091:	55                   	push   %ebp
f0104092:	89 e5                	mov    %esp,%ebp
f0104094:	57                   	push   %edi
f0104095:	56                   	push   %esi
f0104096:	53                   	push   %ebx
f0104097:	83 ec 0c             	sub    $0xc,%esp
f010409a:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010409d:	85 c0                	test   %eax,%eax
f010409f:	74 11                	je     f01040b2 <readline+0x21>
		cprintf("%s", prompt);
f01040a1:	83 ec 08             	sub    $0x8,%esp
f01040a4:	50                   	push   %eax
f01040a5:	68 ed 55 10 f0       	push   $0xf01055ed
f01040aa:	e8 71 f0 ff ff       	call   f0103120 <cprintf>
f01040af:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01040b2:	83 ec 0c             	sub    $0xc,%esp
f01040b5:	6a 00                	push   $0x0
f01040b7:	e8 5a c5 ff ff       	call   f0100616 <iscons>
f01040bc:	89 c7                	mov    %eax,%edi
f01040be:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01040c1:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01040c6:	e8 3a c5 ff ff       	call   f0100605 <getchar>
f01040cb:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01040cd:	85 c0                	test   %eax,%eax
f01040cf:	79 18                	jns    f01040e9 <readline+0x58>
			cprintf("read error: %e\n", c);
f01040d1:	83 ec 08             	sub    $0x8,%esp
f01040d4:	50                   	push   %eax
f01040d5:	68 a0 60 10 f0       	push   $0xf01060a0
f01040da:	e8 41 f0 ff ff       	call   f0103120 <cprintf>
			return NULL;
f01040df:	83 c4 10             	add    $0x10,%esp
f01040e2:	b8 00 00 00 00       	mov    $0x0,%eax
f01040e7:	eb 79                	jmp    f0104162 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01040e9:	83 f8 7f             	cmp    $0x7f,%eax
f01040ec:	0f 94 c2             	sete   %dl
f01040ef:	83 f8 08             	cmp    $0x8,%eax
f01040f2:	0f 94 c0             	sete   %al
f01040f5:	08 c2                	or     %al,%dl
f01040f7:	74 1a                	je     f0104113 <readline+0x82>
f01040f9:	85 f6                	test   %esi,%esi
f01040fb:	7e 16                	jle    f0104113 <readline+0x82>
			if (echoing)
f01040fd:	85 ff                	test   %edi,%edi
f01040ff:	74 0d                	je     f010410e <readline+0x7d>
				cputchar('\b');
f0104101:	83 ec 0c             	sub    $0xc,%esp
f0104104:	6a 08                	push   $0x8
f0104106:	e8 ea c4 ff ff       	call   f01005f5 <cputchar>
f010410b:	83 c4 10             	add    $0x10,%esp
			i--;
f010410e:	83 ee 01             	sub    $0x1,%esi
f0104111:	eb b3                	jmp    f01040c6 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104113:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104119:	7f 20                	jg     f010413b <readline+0xaa>
f010411b:	83 fb 1f             	cmp    $0x1f,%ebx
f010411e:	7e 1b                	jle    f010413b <readline+0xaa>
			if (echoing)
f0104120:	85 ff                	test   %edi,%edi
f0104122:	74 0c                	je     f0104130 <readline+0x9f>
				cputchar(c);
f0104124:	83 ec 0c             	sub    $0xc,%esp
f0104127:	53                   	push   %ebx
f0104128:	e8 c8 c4 ff ff       	call   f01005f5 <cputchar>
f010412d:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104130:	88 9e 00 db 17 f0    	mov    %bl,-0xfe82500(%esi)
f0104136:	8d 76 01             	lea    0x1(%esi),%esi
f0104139:	eb 8b                	jmp    f01040c6 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f010413b:	83 fb 0d             	cmp    $0xd,%ebx
f010413e:	74 05                	je     f0104145 <readline+0xb4>
f0104140:	83 fb 0a             	cmp    $0xa,%ebx
f0104143:	75 81                	jne    f01040c6 <readline+0x35>
			if (echoing)
f0104145:	85 ff                	test   %edi,%edi
f0104147:	74 0d                	je     f0104156 <readline+0xc5>
				cputchar('\n');
f0104149:	83 ec 0c             	sub    $0xc,%esp
f010414c:	6a 0a                	push   $0xa
f010414e:	e8 a2 c4 ff ff       	call   f01005f5 <cputchar>
f0104153:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0104156:	c6 86 00 db 17 f0 00 	movb   $0x0,-0xfe82500(%esi)
			return buf;
f010415d:	b8 00 db 17 f0       	mov    $0xf017db00,%eax
		}
	}
}
f0104162:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104165:	5b                   	pop    %ebx
f0104166:	5e                   	pop    %esi
f0104167:	5f                   	pop    %edi
f0104168:	5d                   	pop    %ebp
f0104169:	c3                   	ret    

f010416a <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010416a:	55                   	push   %ebp
f010416b:	89 e5                	mov    %esp,%ebp
f010416d:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104170:	b8 00 00 00 00       	mov    $0x0,%eax
f0104175:	eb 03                	jmp    f010417a <strlen+0x10>
		n++;
f0104177:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010417a:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010417e:	75 f7                	jne    f0104177 <strlen+0xd>
		n++;
	return n;
}
f0104180:	5d                   	pop    %ebp
f0104181:	c3                   	ret    

f0104182 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104182:	55                   	push   %ebp
f0104183:	89 e5                	mov    %esp,%ebp
f0104185:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104188:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010418b:	ba 00 00 00 00       	mov    $0x0,%edx
f0104190:	eb 03                	jmp    f0104195 <strnlen+0x13>
		n++;
f0104192:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104195:	39 c2                	cmp    %eax,%edx
f0104197:	74 08                	je     f01041a1 <strnlen+0x1f>
f0104199:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010419d:	75 f3                	jne    f0104192 <strnlen+0x10>
f010419f:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01041a1:	5d                   	pop    %ebp
f01041a2:	c3                   	ret    

f01041a3 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01041a3:	55                   	push   %ebp
f01041a4:	89 e5                	mov    %esp,%ebp
f01041a6:	53                   	push   %ebx
f01041a7:	8b 45 08             	mov    0x8(%ebp),%eax
f01041aa:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01041ad:	89 c2                	mov    %eax,%edx
f01041af:	83 c2 01             	add    $0x1,%edx
f01041b2:	83 c1 01             	add    $0x1,%ecx
f01041b5:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01041b9:	88 5a ff             	mov    %bl,-0x1(%edx)
f01041bc:	84 db                	test   %bl,%bl
f01041be:	75 ef                	jne    f01041af <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01041c0:	5b                   	pop    %ebx
f01041c1:	5d                   	pop    %ebp
f01041c2:	c3                   	ret    

f01041c3 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01041c3:	55                   	push   %ebp
f01041c4:	89 e5                	mov    %esp,%ebp
f01041c6:	53                   	push   %ebx
f01041c7:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01041ca:	53                   	push   %ebx
f01041cb:	e8 9a ff ff ff       	call   f010416a <strlen>
f01041d0:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01041d3:	ff 75 0c             	pushl  0xc(%ebp)
f01041d6:	01 d8                	add    %ebx,%eax
f01041d8:	50                   	push   %eax
f01041d9:	e8 c5 ff ff ff       	call   f01041a3 <strcpy>
	return dst;
}
f01041de:	89 d8                	mov    %ebx,%eax
f01041e0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01041e3:	c9                   	leave  
f01041e4:	c3                   	ret    

f01041e5 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01041e5:	55                   	push   %ebp
f01041e6:	89 e5                	mov    %esp,%ebp
f01041e8:	56                   	push   %esi
f01041e9:	53                   	push   %ebx
f01041ea:	8b 75 08             	mov    0x8(%ebp),%esi
f01041ed:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01041f0:	89 f3                	mov    %esi,%ebx
f01041f2:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01041f5:	89 f2                	mov    %esi,%edx
f01041f7:	eb 0f                	jmp    f0104208 <strncpy+0x23>
		*dst++ = *src;
f01041f9:	83 c2 01             	add    $0x1,%edx
f01041fc:	0f b6 01             	movzbl (%ecx),%eax
f01041ff:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104202:	80 39 01             	cmpb   $0x1,(%ecx)
f0104205:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104208:	39 da                	cmp    %ebx,%edx
f010420a:	75 ed                	jne    f01041f9 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010420c:	89 f0                	mov    %esi,%eax
f010420e:	5b                   	pop    %ebx
f010420f:	5e                   	pop    %esi
f0104210:	5d                   	pop    %ebp
f0104211:	c3                   	ret    

f0104212 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104212:	55                   	push   %ebp
f0104213:	89 e5                	mov    %esp,%ebp
f0104215:	56                   	push   %esi
f0104216:	53                   	push   %ebx
f0104217:	8b 75 08             	mov    0x8(%ebp),%esi
f010421a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010421d:	8b 55 10             	mov    0x10(%ebp),%edx
f0104220:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104222:	85 d2                	test   %edx,%edx
f0104224:	74 21                	je     f0104247 <strlcpy+0x35>
f0104226:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010422a:	89 f2                	mov    %esi,%edx
f010422c:	eb 09                	jmp    f0104237 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010422e:	83 c2 01             	add    $0x1,%edx
f0104231:	83 c1 01             	add    $0x1,%ecx
f0104234:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104237:	39 c2                	cmp    %eax,%edx
f0104239:	74 09                	je     f0104244 <strlcpy+0x32>
f010423b:	0f b6 19             	movzbl (%ecx),%ebx
f010423e:	84 db                	test   %bl,%bl
f0104240:	75 ec                	jne    f010422e <strlcpy+0x1c>
f0104242:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104244:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104247:	29 f0                	sub    %esi,%eax
}
f0104249:	5b                   	pop    %ebx
f010424a:	5e                   	pop    %esi
f010424b:	5d                   	pop    %ebp
f010424c:	c3                   	ret    

f010424d <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010424d:	55                   	push   %ebp
f010424e:	89 e5                	mov    %esp,%ebp
f0104250:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104253:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104256:	eb 06                	jmp    f010425e <strcmp+0x11>
		p++, q++;
f0104258:	83 c1 01             	add    $0x1,%ecx
f010425b:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010425e:	0f b6 01             	movzbl (%ecx),%eax
f0104261:	84 c0                	test   %al,%al
f0104263:	74 04                	je     f0104269 <strcmp+0x1c>
f0104265:	3a 02                	cmp    (%edx),%al
f0104267:	74 ef                	je     f0104258 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104269:	0f b6 c0             	movzbl %al,%eax
f010426c:	0f b6 12             	movzbl (%edx),%edx
f010426f:	29 d0                	sub    %edx,%eax
}
f0104271:	5d                   	pop    %ebp
f0104272:	c3                   	ret    

f0104273 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104273:	55                   	push   %ebp
f0104274:	89 e5                	mov    %esp,%ebp
f0104276:	53                   	push   %ebx
f0104277:	8b 45 08             	mov    0x8(%ebp),%eax
f010427a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010427d:	89 c3                	mov    %eax,%ebx
f010427f:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104282:	eb 06                	jmp    f010428a <strncmp+0x17>
		n--, p++, q++;
f0104284:	83 c0 01             	add    $0x1,%eax
f0104287:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010428a:	39 d8                	cmp    %ebx,%eax
f010428c:	74 15                	je     f01042a3 <strncmp+0x30>
f010428e:	0f b6 08             	movzbl (%eax),%ecx
f0104291:	84 c9                	test   %cl,%cl
f0104293:	74 04                	je     f0104299 <strncmp+0x26>
f0104295:	3a 0a                	cmp    (%edx),%cl
f0104297:	74 eb                	je     f0104284 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104299:	0f b6 00             	movzbl (%eax),%eax
f010429c:	0f b6 12             	movzbl (%edx),%edx
f010429f:	29 d0                	sub    %edx,%eax
f01042a1:	eb 05                	jmp    f01042a8 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01042a3:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01042a8:	5b                   	pop    %ebx
f01042a9:	5d                   	pop    %ebp
f01042aa:	c3                   	ret    

f01042ab <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01042ab:	55                   	push   %ebp
f01042ac:	89 e5                	mov    %esp,%ebp
f01042ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01042b1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01042b5:	eb 07                	jmp    f01042be <strchr+0x13>
		if (*s == c)
f01042b7:	38 ca                	cmp    %cl,%dl
f01042b9:	74 0f                	je     f01042ca <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01042bb:	83 c0 01             	add    $0x1,%eax
f01042be:	0f b6 10             	movzbl (%eax),%edx
f01042c1:	84 d2                	test   %dl,%dl
f01042c3:	75 f2                	jne    f01042b7 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01042c5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01042ca:	5d                   	pop    %ebp
f01042cb:	c3                   	ret    

f01042cc <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01042cc:	55                   	push   %ebp
f01042cd:	89 e5                	mov    %esp,%ebp
f01042cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01042d2:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01042d6:	eb 03                	jmp    f01042db <strfind+0xf>
f01042d8:	83 c0 01             	add    $0x1,%eax
f01042db:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01042de:	84 d2                	test   %dl,%dl
f01042e0:	74 04                	je     f01042e6 <strfind+0x1a>
f01042e2:	38 ca                	cmp    %cl,%dl
f01042e4:	75 f2                	jne    f01042d8 <strfind+0xc>
			break;
	return (char *) s;
}
f01042e6:	5d                   	pop    %ebp
f01042e7:	c3                   	ret    

f01042e8 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01042e8:	55                   	push   %ebp
f01042e9:	89 e5                	mov    %esp,%ebp
f01042eb:	57                   	push   %edi
f01042ec:	56                   	push   %esi
f01042ed:	53                   	push   %ebx
f01042ee:	8b 7d 08             	mov    0x8(%ebp),%edi
f01042f1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01042f4:	85 c9                	test   %ecx,%ecx
f01042f6:	74 36                	je     f010432e <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01042f8:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01042fe:	75 28                	jne    f0104328 <memset+0x40>
f0104300:	f6 c1 03             	test   $0x3,%cl
f0104303:	75 23                	jne    f0104328 <memset+0x40>
		c &= 0xFF;
f0104305:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104309:	89 d3                	mov    %edx,%ebx
f010430b:	c1 e3 08             	shl    $0x8,%ebx
f010430e:	89 d6                	mov    %edx,%esi
f0104310:	c1 e6 18             	shl    $0x18,%esi
f0104313:	89 d0                	mov    %edx,%eax
f0104315:	c1 e0 10             	shl    $0x10,%eax
f0104318:	09 f0                	or     %esi,%eax
f010431a:	09 c2                	or     %eax,%edx
f010431c:	89 d0                	mov    %edx,%eax
f010431e:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0104320:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0104323:	fc                   	cld    
f0104324:	f3 ab                	rep stos %eax,%es:(%edi)
f0104326:	eb 06                	jmp    f010432e <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104328:	8b 45 0c             	mov    0xc(%ebp),%eax
f010432b:	fc                   	cld    
f010432c:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010432e:	89 f8                	mov    %edi,%eax
f0104330:	5b                   	pop    %ebx
f0104331:	5e                   	pop    %esi
f0104332:	5f                   	pop    %edi
f0104333:	5d                   	pop    %ebp
f0104334:	c3                   	ret    

f0104335 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104335:	55                   	push   %ebp
f0104336:	89 e5                	mov    %esp,%ebp
f0104338:	57                   	push   %edi
f0104339:	56                   	push   %esi
f010433a:	8b 45 08             	mov    0x8(%ebp),%eax
f010433d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104340:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104343:	39 c6                	cmp    %eax,%esi
f0104345:	73 35                	jae    f010437c <memmove+0x47>
f0104347:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010434a:	39 d0                	cmp    %edx,%eax
f010434c:	73 2e                	jae    f010437c <memmove+0x47>
		s += n;
		d += n;
f010434e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0104351:	89 d6                	mov    %edx,%esi
f0104353:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104355:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010435b:	75 13                	jne    f0104370 <memmove+0x3b>
f010435d:	f6 c1 03             	test   $0x3,%cl
f0104360:	75 0e                	jne    f0104370 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104362:	83 ef 04             	sub    $0x4,%edi
f0104365:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104368:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010436b:	fd                   	std    
f010436c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010436e:	eb 09                	jmp    f0104379 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0104370:	83 ef 01             	sub    $0x1,%edi
f0104373:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104376:	fd                   	std    
f0104377:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104379:	fc                   	cld    
f010437a:	eb 1d                	jmp    f0104399 <memmove+0x64>
f010437c:	89 f2                	mov    %esi,%edx
f010437e:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104380:	f6 c2 03             	test   $0x3,%dl
f0104383:	75 0f                	jne    f0104394 <memmove+0x5f>
f0104385:	f6 c1 03             	test   $0x3,%cl
f0104388:	75 0a                	jne    f0104394 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010438a:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010438d:	89 c7                	mov    %eax,%edi
f010438f:	fc                   	cld    
f0104390:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104392:	eb 05                	jmp    f0104399 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104394:	89 c7                	mov    %eax,%edi
f0104396:	fc                   	cld    
f0104397:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104399:	5e                   	pop    %esi
f010439a:	5f                   	pop    %edi
f010439b:	5d                   	pop    %ebp
f010439c:	c3                   	ret    

f010439d <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010439d:	55                   	push   %ebp
f010439e:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01043a0:	ff 75 10             	pushl  0x10(%ebp)
f01043a3:	ff 75 0c             	pushl  0xc(%ebp)
f01043a6:	ff 75 08             	pushl  0x8(%ebp)
f01043a9:	e8 87 ff ff ff       	call   f0104335 <memmove>
}
f01043ae:	c9                   	leave  
f01043af:	c3                   	ret    

f01043b0 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01043b0:	55                   	push   %ebp
f01043b1:	89 e5                	mov    %esp,%ebp
f01043b3:	56                   	push   %esi
f01043b4:	53                   	push   %ebx
f01043b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01043b8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01043bb:	89 c6                	mov    %eax,%esi
f01043bd:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01043c0:	eb 1a                	jmp    f01043dc <memcmp+0x2c>
		if (*s1 != *s2)
f01043c2:	0f b6 08             	movzbl (%eax),%ecx
f01043c5:	0f b6 1a             	movzbl (%edx),%ebx
f01043c8:	38 d9                	cmp    %bl,%cl
f01043ca:	74 0a                	je     f01043d6 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01043cc:	0f b6 c1             	movzbl %cl,%eax
f01043cf:	0f b6 db             	movzbl %bl,%ebx
f01043d2:	29 d8                	sub    %ebx,%eax
f01043d4:	eb 0f                	jmp    f01043e5 <memcmp+0x35>
		s1++, s2++;
f01043d6:	83 c0 01             	add    $0x1,%eax
f01043d9:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01043dc:	39 f0                	cmp    %esi,%eax
f01043de:	75 e2                	jne    f01043c2 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01043e0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01043e5:	5b                   	pop    %ebx
f01043e6:	5e                   	pop    %esi
f01043e7:	5d                   	pop    %ebp
f01043e8:	c3                   	ret    

f01043e9 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01043e9:	55                   	push   %ebp
f01043ea:	89 e5                	mov    %esp,%ebp
f01043ec:	8b 45 08             	mov    0x8(%ebp),%eax
f01043ef:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01043f2:	89 c2                	mov    %eax,%edx
f01043f4:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01043f7:	eb 07                	jmp    f0104400 <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01043f9:	38 08                	cmp    %cl,(%eax)
f01043fb:	74 07                	je     f0104404 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01043fd:	83 c0 01             	add    $0x1,%eax
f0104400:	39 d0                	cmp    %edx,%eax
f0104402:	72 f5                	jb     f01043f9 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104404:	5d                   	pop    %ebp
f0104405:	c3                   	ret    

f0104406 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104406:	55                   	push   %ebp
f0104407:	89 e5                	mov    %esp,%ebp
f0104409:	57                   	push   %edi
f010440a:	56                   	push   %esi
f010440b:	53                   	push   %ebx
f010440c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010440f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104412:	eb 03                	jmp    f0104417 <strtol+0x11>
		s++;
f0104414:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104417:	0f b6 01             	movzbl (%ecx),%eax
f010441a:	3c 09                	cmp    $0x9,%al
f010441c:	74 f6                	je     f0104414 <strtol+0xe>
f010441e:	3c 20                	cmp    $0x20,%al
f0104420:	74 f2                	je     f0104414 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104422:	3c 2b                	cmp    $0x2b,%al
f0104424:	75 0a                	jne    f0104430 <strtol+0x2a>
		s++;
f0104426:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104429:	bf 00 00 00 00       	mov    $0x0,%edi
f010442e:	eb 10                	jmp    f0104440 <strtol+0x3a>
f0104430:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104435:	3c 2d                	cmp    $0x2d,%al
f0104437:	75 07                	jne    f0104440 <strtol+0x3a>
		s++, neg = 1;
f0104439:	8d 49 01             	lea    0x1(%ecx),%ecx
f010443c:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104440:	85 db                	test   %ebx,%ebx
f0104442:	0f 94 c0             	sete   %al
f0104445:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010444b:	75 19                	jne    f0104466 <strtol+0x60>
f010444d:	80 39 30             	cmpb   $0x30,(%ecx)
f0104450:	75 14                	jne    f0104466 <strtol+0x60>
f0104452:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0104456:	0f 85 82 00 00 00    	jne    f01044de <strtol+0xd8>
		s += 2, base = 16;
f010445c:	83 c1 02             	add    $0x2,%ecx
f010445f:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104464:	eb 16                	jmp    f010447c <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0104466:	84 c0                	test   %al,%al
f0104468:	74 12                	je     f010447c <strtol+0x76>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010446a:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010446f:	80 39 30             	cmpb   $0x30,(%ecx)
f0104472:	75 08                	jne    f010447c <strtol+0x76>
		s++, base = 8;
f0104474:	83 c1 01             	add    $0x1,%ecx
f0104477:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f010447c:	b8 00 00 00 00       	mov    $0x0,%eax
f0104481:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104484:	0f b6 11             	movzbl (%ecx),%edx
f0104487:	8d 72 d0             	lea    -0x30(%edx),%esi
f010448a:	89 f3                	mov    %esi,%ebx
f010448c:	80 fb 09             	cmp    $0x9,%bl
f010448f:	77 08                	ja     f0104499 <strtol+0x93>
			dig = *s - '0';
f0104491:	0f be d2             	movsbl %dl,%edx
f0104494:	83 ea 30             	sub    $0x30,%edx
f0104497:	eb 22                	jmp    f01044bb <strtol+0xb5>
		else if (*s >= 'a' && *s <= 'z')
f0104499:	8d 72 9f             	lea    -0x61(%edx),%esi
f010449c:	89 f3                	mov    %esi,%ebx
f010449e:	80 fb 19             	cmp    $0x19,%bl
f01044a1:	77 08                	ja     f01044ab <strtol+0xa5>
			dig = *s - 'a' + 10;
f01044a3:	0f be d2             	movsbl %dl,%edx
f01044a6:	83 ea 57             	sub    $0x57,%edx
f01044a9:	eb 10                	jmp    f01044bb <strtol+0xb5>
		else if (*s >= 'A' && *s <= 'Z')
f01044ab:	8d 72 bf             	lea    -0x41(%edx),%esi
f01044ae:	89 f3                	mov    %esi,%ebx
f01044b0:	80 fb 19             	cmp    $0x19,%bl
f01044b3:	77 16                	ja     f01044cb <strtol+0xc5>
			dig = *s - 'A' + 10;
f01044b5:	0f be d2             	movsbl %dl,%edx
f01044b8:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01044bb:	3b 55 10             	cmp    0x10(%ebp),%edx
f01044be:	7d 0f                	jge    f01044cf <strtol+0xc9>
			break;
		s++, val = (val * base) + dig;
f01044c0:	83 c1 01             	add    $0x1,%ecx
f01044c3:	0f af 45 10          	imul   0x10(%ebp),%eax
f01044c7:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01044c9:	eb b9                	jmp    f0104484 <strtol+0x7e>
f01044cb:	89 c2                	mov    %eax,%edx
f01044cd:	eb 02                	jmp    f01044d1 <strtol+0xcb>
f01044cf:	89 c2                	mov    %eax,%edx

	if (endptr)
f01044d1:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01044d5:	74 0d                	je     f01044e4 <strtol+0xde>
		*endptr = (char *) s;
f01044d7:	8b 75 0c             	mov    0xc(%ebp),%esi
f01044da:	89 0e                	mov    %ecx,(%esi)
f01044dc:	eb 06                	jmp    f01044e4 <strtol+0xde>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01044de:	84 c0                	test   %al,%al
f01044e0:	75 92                	jne    f0104474 <strtol+0x6e>
f01044e2:	eb 98                	jmp    f010447c <strtol+0x76>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01044e4:	f7 da                	neg    %edx
f01044e6:	85 ff                	test   %edi,%edi
f01044e8:	0f 45 c2             	cmovne %edx,%eax
}
f01044eb:	5b                   	pop    %ebx
f01044ec:	5e                   	pop    %esi
f01044ed:	5f                   	pop    %edi
f01044ee:	5d                   	pop    %ebp
f01044ef:	c3                   	ret    

f01044f0 <__udivdi3>:
f01044f0:	55                   	push   %ebp
f01044f1:	57                   	push   %edi
f01044f2:	56                   	push   %esi
f01044f3:	83 ec 10             	sub    $0x10,%esp
f01044f6:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f01044fa:	8b 7c 24 20          	mov    0x20(%esp),%edi
f01044fe:	8b 74 24 24          	mov    0x24(%esp),%esi
f0104502:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0104506:	85 d2                	test   %edx,%edx
f0104508:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010450c:	89 34 24             	mov    %esi,(%esp)
f010450f:	89 c8                	mov    %ecx,%eax
f0104511:	75 35                	jne    f0104548 <__udivdi3+0x58>
f0104513:	39 f1                	cmp    %esi,%ecx
f0104515:	0f 87 bd 00 00 00    	ja     f01045d8 <__udivdi3+0xe8>
f010451b:	85 c9                	test   %ecx,%ecx
f010451d:	89 cd                	mov    %ecx,%ebp
f010451f:	75 0b                	jne    f010452c <__udivdi3+0x3c>
f0104521:	b8 01 00 00 00       	mov    $0x1,%eax
f0104526:	31 d2                	xor    %edx,%edx
f0104528:	f7 f1                	div    %ecx
f010452a:	89 c5                	mov    %eax,%ebp
f010452c:	89 f0                	mov    %esi,%eax
f010452e:	31 d2                	xor    %edx,%edx
f0104530:	f7 f5                	div    %ebp
f0104532:	89 c6                	mov    %eax,%esi
f0104534:	89 f8                	mov    %edi,%eax
f0104536:	f7 f5                	div    %ebp
f0104538:	89 f2                	mov    %esi,%edx
f010453a:	83 c4 10             	add    $0x10,%esp
f010453d:	5e                   	pop    %esi
f010453e:	5f                   	pop    %edi
f010453f:	5d                   	pop    %ebp
f0104540:	c3                   	ret    
f0104541:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104548:	3b 14 24             	cmp    (%esp),%edx
f010454b:	77 7b                	ja     f01045c8 <__udivdi3+0xd8>
f010454d:	0f bd f2             	bsr    %edx,%esi
f0104550:	83 f6 1f             	xor    $0x1f,%esi
f0104553:	0f 84 97 00 00 00    	je     f01045f0 <__udivdi3+0x100>
f0104559:	bd 20 00 00 00       	mov    $0x20,%ebp
f010455e:	89 d7                	mov    %edx,%edi
f0104560:	89 f1                	mov    %esi,%ecx
f0104562:	29 f5                	sub    %esi,%ebp
f0104564:	d3 e7                	shl    %cl,%edi
f0104566:	89 c2                	mov    %eax,%edx
f0104568:	89 e9                	mov    %ebp,%ecx
f010456a:	d3 ea                	shr    %cl,%edx
f010456c:	89 f1                	mov    %esi,%ecx
f010456e:	09 fa                	or     %edi,%edx
f0104570:	8b 3c 24             	mov    (%esp),%edi
f0104573:	d3 e0                	shl    %cl,%eax
f0104575:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104579:	89 e9                	mov    %ebp,%ecx
f010457b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010457f:	8b 44 24 04          	mov    0x4(%esp),%eax
f0104583:	89 fa                	mov    %edi,%edx
f0104585:	d3 ea                	shr    %cl,%edx
f0104587:	89 f1                	mov    %esi,%ecx
f0104589:	d3 e7                	shl    %cl,%edi
f010458b:	89 e9                	mov    %ebp,%ecx
f010458d:	d3 e8                	shr    %cl,%eax
f010458f:	09 c7                	or     %eax,%edi
f0104591:	89 f8                	mov    %edi,%eax
f0104593:	f7 74 24 08          	divl   0x8(%esp)
f0104597:	89 d5                	mov    %edx,%ebp
f0104599:	89 c7                	mov    %eax,%edi
f010459b:	f7 64 24 0c          	mull   0xc(%esp)
f010459f:	39 d5                	cmp    %edx,%ebp
f01045a1:	89 14 24             	mov    %edx,(%esp)
f01045a4:	72 11                	jb     f01045b7 <__udivdi3+0xc7>
f01045a6:	8b 54 24 04          	mov    0x4(%esp),%edx
f01045aa:	89 f1                	mov    %esi,%ecx
f01045ac:	d3 e2                	shl    %cl,%edx
f01045ae:	39 c2                	cmp    %eax,%edx
f01045b0:	73 5e                	jae    f0104610 <__udivdi3+0x120>
f01045b2:	3b 2c 24             	cmp    (%esp),%ebp
f01045b5:	75 59                	jne    f0104610 <__udivdi3+0x120>
f01045b7:	8d 47 ff             	lea    -0x1(%edi),%eax
f01045ba:	31 f6                	xor    %esi,%esi
f01045bc:	89 f2                	mov    %esi,%edx
f01045be:	83 c4 10             	add    $0x10,%esp
f01045c1:	5e                   	pop    %esi
f01045c2:	5f                   	pop    %edi
f01045c3:	5d                   	pop    %ebp
f01045c4:	c3                   	ret    
f01045c5:	8d 76 00             	lea    0x0(%esi),%esi
f01045c8:	31 f6                	xor    %esi,%esi
f01045ca:	31 c0                	xor    %eax,%eax
f01045cc:	89 f2                	mov    %esi,%edx
f01045ce:	83 c4 10             	add    $0x10,%esp
f01045d1:	5e                   	pop    %esi
f01045d2:	5f                   	pop    %edi
f01045d3:	5d                   	pop    %ebp
f01045d4:	c3                   	ret    
f01045d5:	8d 76 00             	lea    0x0(%esi),%esi
f01045d8:	89 f2                	mov    %esi,%edx
f01045da:	31 f6                	xor    %esi,%esi
f01045dc:	89 f8                	mov    %edi,%eax
f01045de:	f7 f1                	div    %ecx
f01045e0:	89 f2                	mov    %esi,%edx
f01045e2:	83 c4 10             	add    $0x10,%esp
f01045e5:	5e                   	pop    %esi
f01045e6:	5f                   	pop    %edi
f01045e7:	5d                   	pop    %ebp
f01045e8:	c3                   	ret    
f01045e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01045f0:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f01045f4:	76 0b                	jbe    f0104601 <__udivdi3+0x111>
f01045f6:	31 c0                	xor    %eax,%eax
f01045f8:	3b 14 24             	cmp    (%esp),%edx
f01045fb:	0f 83 37 ff ff ff    	jae    f0104538 <__udivdi3+0x48>
f0104601:	b8 01 00 00 00       	mov    $0x1,%eax
f0104606:	e9 2d ff ff ff       	jmp    f0104538 <__udivdi3+0x48>
f010460b:	90                   	nop
f010460c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104610:	89 f8                	mov    %edi,%eax
f0104612:	31 f6                	xor    %esi,%esi
f0104614:	e9 1f ff ff ff       	jmp    f0104538 <__udivdi3+0x48>
f0104619:	66 90                	xchg   %ax,%ax
f010461b:	66 90                	xchg   %ax,%ax
f010461d:	66 90                	xchg   %ax,%ax
f010461f:	90                   	nop

f0104620 <__umoddi3>:
f0104620:	55                   	push   %ebp
f0104621:	57                   	push   %edi
f0104622:	56                   	push   %esi
f0104623:	83 ec 20             	sub    $0x20,%esp
f0104626:	8b 44 24 34          	mov    0x34(%esp),%eax
f010462a:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010462e:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104632:	89 c6                	mov    %eax,%esi
f0104634:	89 44 24 10          	mov    %eax,0x10(%esp)
f0104638:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f010463c:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0104640:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104644:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0104648:	89 74 24 18          	mov    %esi,0x18(%esp)
f010464c:	85 c0                	test   %eax,%eax
f010464e:	89 c2                	mov    %eax,%edx
f0104650:	75 1e                	jne    f0104670 <__umoddi3+0x50>
f0104652:	39 f7                	cmp    %esi,%edi
f0104654:	76 52                	jbe    f01046a8 <__umoddi3+0x88>
f0104656:	89 c8                	mov    %ecx,%eax
f0104658:	89 f2                	mov    %esi,%edx
f010465a:	f7 f7                	div    %edi
f010465c:	89 d0                	mov    %edx,%eax
f010465e:	31 d2                	xor    %edx,%edx
f0104660:	83 c4 20             	add    $0x20,%esp
f0104663:	5e                   	pop    %esi
f0104664:	5f                   	pop    %edi
f0104665:	5d                   	pop    %ebp
f0104666:	c3                   	ret    
f0104667:	89 f6                	mov    %esi,%esi
f0104669:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0104670:	39 f0                	cmp    %esi,%eax
f0104672:	77 5c                	ja     f01046d0 <__umoddi3+0xb0>
f0104674:	0f bd e8             	bsr    %eax,%ebp
f0104677:	83 f5 1f             	xor    $0x1f,%ebp
f010467a:	75 64                	jne    f01046e0 <__umoddi3+0xc0>
f010467c:	8b 6c 24 14          	mov    0x14(%esp),%ebp
f0104680:	39 6c 24 0c          	cmp    %ebp,0xc(%esp)
f0104684:	0f 86 f6 00 00 00    	jbe    f0104780 <__umoddi3+0x160>
f010468a:	3b 44 24 18          	cmp    0x18(%esp),%eax
f010468e:	0f 82 ec 00 00 00    	jb     f0104780 <__umoddi3+0x160>
f0104694:	8b 44 24 14          	mov    0x14(%esp),%eax
f0104698:	8b 54 24 18          	mov    0x18(%esp),%edx
f010469c:	83 c4 20             	add    $0x20,%esp
f010469f:	5e                   	pop    %esi
f01046a0:	5f                   	pop    %edi
f01046a1:	5d                   	pop    %ebp
f01046a2:	c3                   	ret    
f01046a3:	90                   	nop
f01046a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01046a8:	85 ff                	test   %edi,%edi
f01046aa:	89 fd                	mov    %edi,%ebp
f01046ac:	75 0b                	jne    f01046b9 <__umoddi3+0x99>
f01046ae:	b8 01 00 00 00       	mov    $0x1,%eax
f01046b3:	31 d2                	xor    %edx,%edx
f01046b5:	f7 f7                	div    %edi
f01046b7:	89 c5                	mov    %eax,%ebp
f01046b9:	8b 44 24 10          	mov    0x10(%esp),%eax
f01046bd:	31 d2                	xor    %edx,%edx
f01046bf:	f7 f5                	div    %ebp
f01046c1:	89 c8                	mov    %ecx,%eax
f01046c3:	f7 f5                	div    %ebp
f01046c5:	eb 95                	jmp    f010465c <__umoddi3+0x3c>
f01046c7:	89 f6                	mov    %esi,%esi
f01046c9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f01046d0:	89 c8                	mov    %ecx,%eax
f01046d2:	89 f2                	mov    %esi,%edx
f01046d4:	83 c4 20             	add    $0x20,%esp
f01046d7:	5e                   	pop    %esi
f01046d8:	5f                   	pop    %edi
f01046d9:	5d                   	pop    %ebp
f01046da:	c3                   	ret    
f01046db:	90                   	nop
f01046dc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01046e0:	b8 20 00 00 00       	mov    $0x20,%eax
f01046e5:	89 e9                	mov    %ebp,%ecx
f01046e7:	29 e8                	sub    %ebp,%eax
f01046e9:	d3 e2                	shl    %cl,%edx
f01046eb:	89 c7                	mov    %eax,%edi
f01046ed:	89 44 24 18          	mov    %eax,0x18(%esp)
f01046f1:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01046f5:	89 f9                	mov    %edi,%ecx
f01046f7:	d3 e8                	shr    %cl,%eax
f01046f9:	89 c1                	mov    %eax,%ecx
f01046fb:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01046ff:	09 d1                	or     %edx,%ecx
f0104701:	89 fa                	mov    %edi,%edx
f0104703:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0104707:	89 e9                	mov    %ebp,%ecx
f0104709:	d3 e0                	shl    %cl,%eax
f010470b:	89 f9                	mov    %edi,%ecx
f010470d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104711:	89 f0                	mov    %esi,%eax
f0104713:	d3 e8                	shr    %cl,%eax
f0104715:	89 e9                	mov    %ebp,%ecx
f0104717:	89 c7                	mov    %eax,%edi
f0104719:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f010471d:	d3 e6                	shl    %cl,%esi
f010471f:	89 d1                	mov    %edx,%ecx
f0104721:	89 fa                	mov    %edi,%edx
f0104723:	d3 e8                	shr    %cl,%eax
f0104725:	89 e9                	mov    %ebp,%ecx
f0104727:	09 f0                	or     %esi,%eax
f0104729:	8b 74 24 1c          	mov    0x1c(%esp),%esi
f010472d:	f7 74 24 10          	divl   0x10(%esp)
f0104731:	d3 e6                	shl    %cl,%esi
f0104733:	89 d1                	mov    %edx,%ecx
f0104735:	f7 64 24 0c          	mull   0xc(%esp)
f0104739:	39 d1                	cmp    %edx,%ecx
f010473b:	89 74 24 14          	mov    %esi,0x14(%esp)
f010473f:	89 d7                	mov    %edx,%edi
f0104741:	89 c6                	mov    %eax,%esi
f0104743:	72 0a                	jb     f010474f <__umoddi3+0x12f>
f0104745:	39 44 24 14          	cmp    %eax,0x14(%esp)
f0104749:	73 10                	jae    f010475b <__umoddi3+0x13b>
f010474b:	39 d1                	cmp    %edx,%ecx
f010474d:	75 0c                	jne    f010475b <__umoddi3+0x13b>
f010474f:	89 d7                	mov    %edx,%edi
f0104751:	89 c6                	mov    %eax,%esi
f0104753:	2b 74 24 0c          	sub    0xc(%esp),%esi
f0104757:	1b 7c 24 10          	sbb    0x10(%esp),%edi
f010475b:	89 ca                	mov    %ecx,%edx
f010475d:	89 e9                	mov    %ebp,%ecx
f010475f:	8b 44 24 14          	mov    0x14(%esp),%eax
f0104763:	29 f0                	sub    %esi,%eax
f0104765:	19 fa                	sbb    %edi,%edx
f0104767:	d3 e8                	shr    %cl,%eax
f0104769:	0f b6 4c 24 18       	movzbl 0x18(%esp),%ecx
f010476e:	89 d7                	mov    %edx,%edi
f0104770:	d3 e7                	shl    %cl,%edi
f0104772:	89 e9                	mov    %ebp,%ecx
f0104774:	09 f8                	or     %edi,%eax
f0104776:	d3 ea                	shr    %cl,%edx
f0104778:	83 c4 20             	add    $0x20,%esp
f010477b:	5e                   	pop    %esi
f010477c:	5f                   	pop    %edi
f010477d:	5d                   	pop    %ebp
f010477e:	c3                   	ret    
f010477f:	90                   	nop
f0104780:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104784:	29 f9                	sub    %edi,%ecx
f0104786:	19 c6                	sbb    %eax,%esi
f0104788:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f010478c:	89 74 24 18          	mov    %esi,0x18(%esp)
f0104790:	e9 ff fe ff ff       	jmp    f0104694 <__umoddi3+0x74>
