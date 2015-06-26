
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
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 c0 18 10 f0 	movl   $0xf01018c0,(%esp)
f0100055:	e8 c7 08 00 00       	call   f0100921 <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 08 07 00 00       	call   f010078f <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 dc 18 10 f0 	movl   $0xf01018dc,(%esp)
f0100092:	e8 8a 08 00 00       	call   f0100921 <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 62 13 00 00       	call   f0101427 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 95 04 00 00       	call   f010055f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 f7 18 10 f0 	movl   $0xf01018f7,(%esp)
f01000d9:	e8 43 08 00 00       	call   f0100921 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 a3 06 00 00       	call   f0100799 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 12 19 10 f0 	movl   $0xf0101912,(%esp)
f010012c:	e8 f0 07 00 00       	call   f0100921 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 b1 07 00 00       	call   f01008ee <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 4e 19 10 f0 	movl   $0xf010194e,(%esp)
f0100144:	e8 d8 07 00 00       	call   f0100921 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 44 06 00 00       	call   f0100799 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 2a 19 10 f0 	movl   $0xf010192a,(%esp)
f0100176:	e8 a6 07 00 00       	call   f0100921 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 64 07 00 00       	call   f01008ee <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 4e 19 10 f0 	movl   $0xf010194e,(%esp)
f0100191:	e8 8b 07 00 00       	call   f0100921 <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a9:	a8 01                	test   $0x1,%al
f01001ab:	74 08                	je     f01001b5 <serial_proc_data+0x15>
f01001ad:	b2 f8                	mov    $0xf8,%dl
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
f01001b3:	eb 05                	jmp    f01001ba <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	53                   	push   %ebx
f01001c0:	83 ec 04             	sub    $0x4,%esp
f01001c3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001c5:	eb 2a                	jmp    f01001f1 <cons_intr+0x35>
		if (c == 0)
f01001c7:	85 d2                	test   %edx,%edx
f01001c9:	74 26                	je     f01001f1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001cb:	a1 24 25 11 f0       	mov    0xf0112524,%eax
f01001d0:	8d 48 01             	lea    0x1(%eax),%ecx
f01001d3:	89 0d 24 25 11 f0    	mov    %ecx,0xf0112524
f01001d9:	88 90 20 23 11 f0    	mov    %dl,-0xfeedce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001df:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001e5:	75 0a                	jne    f01001f1 <cons_intr+0x35>
			cons.wpos = 0;
f01001e7:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001ee:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001f1:	ff d3                	call   *%ebx
f01001f3:	89 c2                	mov    %eax,%edx
f01001f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f8:	75 cd                	jne    f01001c7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001fa:	83 c4 04             	add    $0x4,%esp
f01001fd:	5b                   	pop    %ebx
f01001fe:	5d                   	pop    %ebp
f01001ff:	c3                   	ret    

f0100200 <kbd_proc_data>:
f0100200:	ba 64 00 00 00       	mov    $0x64,%edx
f0100205:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100206:	a8 01                	test   $0x1,%al
f0100208:	0f 84 ef 00 00 00    	je     f01002fd <kbd_proc_data+0xfd>
f010020e:	b2 60                	mov    $0x60,%dl
f0100210:	ec                   	in     (%dx),%al
f0100211:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100213:	3c e0                	cmp    $0xe0,%al
f0100215:	75 0d                	jne    f0100224 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100217:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f010021e:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100223:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100224:	55                   	push   %ebp
f0100225:	89 e5                	mov    %esp,%ebp
f0100227:	53                   	push   %ebx
f0100228:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010022b:	84 c0                	test   %al,%al
f010022d:	79 37                	jns    f0100266 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010022f:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100235:	89 cb                	mov    %ecx,%ebx
f0100237:	83 e3 40             	and    $0x40,%ebx
f010023a:	83 e0 7f             	and    $0x7f,%eax
f010023d:	85 db                	test   %ebx,%ebx
f010023f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100242:	0f b6 d2             	movzbl %dl,%edx
f0100245:	0f b6 82 a0 1a 10 f0 	movzbl -0xfefe560(%edx),%eax
f010024c:	83 c8 40             	or     $0x40,%eax
f010024f:	0f b6 c0             	movzbl %al,%eax
f0100252:	f7 d0                	not    %eax
f0100254:	21 c1                	and    %eax,%ecx
f0100256:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
		return 0;
f010025c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100261:	e9 9d 00 00 00       	jmp    f0100303 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100266:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010026c:	f6 c1 40             	test   $0x40,%cl
f010026f:	74 0e                	je     f010027f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100271:	83 c8 80             	or     $0xffffff80,%eax
f0100274:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100276:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100279:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f010027f:	0f b6 d2             	movzbl %dl,%edx
f0100282:	0f b6 82 a0 1a 10 f0 	movzbl -0xfefe560(%edx),%eax
f0100289:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
	shift ^= togglecode[data];
f010028f:	0f b6 8a a0 19 10 f0 	movzbl -0xfefe660(%edx),%ecx
f0100296:	31 c8                	xor    %ecx,%eax
f0100298:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f010029d:	89 c1                	mov    %eax,%ecx
f010029f:	83 e1 03             	and    $0x3,%ecx
f01002a2:	8b 0c 8d 80 19 10 f0 	mov    -0xfefe680(,%ecx,4),%ecx
f01002a9:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002ad:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002b0:	a8 08                	test   $0x8,%al
f01002b2:	74 1b                	je     f01002cf <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01002b4:	89 da                	mov    %ebx,%edx
f01002b6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002b9:	83 f9 19             	cmp    $0x19,%ecx
f01002bc:	77 05                	ja     f01002c3 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f01002be:	83 eb 20             	sub    $0x20,%ebx
f01002c1:	eb 0c                	jmp    f01002cf <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f01002c3:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002c6:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002c9:	83 fa 19             	cmp    $0x19,%edx
f01002cc:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002cf:	f7 d0                	not    %eax
f01002d1:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002d5:	f6 c2 06             	test   $0x6,%dl
f01002d8:	75 29                	jne    f0100303 <kbd_proc_data+0x103>
f01002da:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002e0:	75 21                	jne    f0100303 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f01002e2:	c7 04 24 44 19 10 f0 	movl   $0xf0101944,(%esp)
f01002e9:	e8 33 06 00 00       	call   f0100921 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ee:	ba 92 00 00 00       	mov    $0x92,%edx
f01002f3:	b8 03 00 00 00       	mov    $0x3,%eax
f01002f8:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002f9:	89 d8                	mov    %ebx,%eax
f01002fb:	eb 06                	jmp    f0100303 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100302:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100303:	83 c4 14             	add    $0x14,%esp
f0100306:	5b                   	pop    %ebx
f0100307:	5d                   	pop    %ebp
f0100308:	c3                   	ret    

f0100309 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100309:	55                   	push   %ebp
f010030a:	89 e5                	mov    %esp,%ebp
f010030c:	57                   	push   %edi
f010030d:	56                   	push   %esi
f010030e:	53                   	push   %ebx
f010030f:	83 ec 1c             	sub    $0x1c,%esp
f0100312:	89 c7                	mov    %eax,%edi
f0100314:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100319:	be fd 03 00 00       	mov    $0x3fd,%esi
f010031e:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100323:	eb 06                	jmp    f010032b <cons_putc+0x22>
f0100325:	89 ca                	mov    %ecx,%edx
f0100327:	ec                   	in     (%dx),%al
f0100328:	ec                   	in     (%dx),%al
f0100329:	ec                   	in     (%dx),%al
f010032a:	ec                   	in     (%dx),%al
f010032b:	89 f2                	mov    %esi,%edx
f010032d:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010032e:	a8 20                	test   $0x20,%al
f0100330:	75 05                	jne    f0100337 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100332:	83 eb 01             	sub    $0x1,%ebx
f0100335:	75 ee                	jne    f0100325 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100337:	89 f8                	mov    %edi,%eax
f0100339:	0f b6 c0             	movzbl %al,%eax
f010033c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010033f:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100344:	ee                   	out    %al,(%dx)
f0100345:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010034a:	be 79 03 00 00       	mov    $0x379,%esi
f010034f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100354:	eb 06                	jmp    f010035c <cons_putc+0x53>
f0100356:	89 ca                	mov    %ecx,%edx
f0100358:	ec                   	in     (%dx),%al
f0100359:	ec                   	in     (%dx),%al
f010035a:	ec                   	in     (%dx),%al
f010035b:	ec                   	in     (%dx),%al
f010035c:	89 f2                	mov    %esi,%edx
f010035e:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010035f:	84 c0                	test   %al,%al
f0100361:	78 05                	js     f0100368 <cons_putc+0x5f>
f0100363:	83 eb 01             	sub    $0x1,%ebx
f0100366:	75 ee                	jne    f0100356 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100368:	ba 78 03 00 00       	mov    $0x378,%edx
f010036d:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100371:	ee                   	out    %al,(%dx)
f0100372:	b2 7a                	mov    $0x7a,%dl
f0100374:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100379:	ee                   	out    %al,(%dx)
f010037a:	b8 08 00 00 00       	mov    $0x8,%eax
f010037f:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100380:	89 fa                	mov    %edi,%edx
f0100382:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100388:	89 f8                	mov    %edi,%eax
f010038a:	80 cc 07             	or     $0x7,%ah
f010038d:	85 d2                	test   %edx,%edx
f010038f:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100392:	89 f8                	mov    %edi,%eax
f0100394:	0f b6 c0             	movzbl %al,%eax
f0100397:	83 f8 09             	cmp    $0x9,%eax
f010039a:	74 76                	je     f0100412 <cons_putc+0x109>
f010039c:	83 f8 09             	cmp    $0x9,%eax
f010039f:	7f 0a                	jg     f01003ab <cons_putc+0xa2>
f01003a1:	83 f8 08             	cmp    $0x8,%eax
f01003a4:	74 16                	je     f01003bc <cons_putc+0xb3>
f01003a6:	e9 9b 00 00 00       	jmp    f0100446 <cons_putc+0x13d>
f01003ab:	83 f8 0a             	cmp    $0xa,%eax
f01003ae:	66 90                	xchg   %ax,%ax
f01003b0:	74 3a                	je     f01003ec <cons_putc+0xe3>
f01003b2:	83 f8 0d             	cmp    $0xd,%eax
f01003b5:	74 3d                	je     f01003f4 <cons_putc+0xeb>
f01003b7:	e9 8a 00 00 00       	jmp    f0100446 <cons_putc+0x13d>
	case '\b':
		if (crt_pos > 0) {
f01003bc:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003c3:	66 85 c0             	test   %ax,%ax
f01003c6:	0f 84 e5 00 00 00    	je     f01004b1 <cons_putc+0x1a8>
			crt_pos--;
f01003cc:	83 e8 01             	sub    $0x1,%eax
f01003cf:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003d5:	0f b7 c0             	movzwl %ax,%eax
f01003d8:	66 81 e7 00 ff       	and    $0xff00,%di
f01003dd:	83 cf 20             	or     $0x20,%edi
f01003e0:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003e6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003ea:	eb 78                	jmp    f0100464 <cons_putc+0x15b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003ec:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003f3:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003f4:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003fb:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100401:	c1 e8 16             	shr    $0x16,%eax
f0100404:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100407:	c1 e0 04             	shl    $0x4,%eax
f010040a:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f0100410:	eb 52                	jmp    f0100464 <cons_putc+0x15b>
		break;
	case '\t':
		cons_putc(' ');
f0100412:	b8 20 00 00 00       	mov    $0x20,%eax
f0100417:	e8 ed fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010041c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100421:	e8 e3 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100426:	b8 20 00 00 00       	mov    $0x20,%eax
f010042b:	e8 d9 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100430:	b8 20 00 00 00       	mov    $0x20,%eax
f0100435:	e8 cf fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010043a:	b8 20 00 00 00       	mov    $0x20,%eax
f010043f:	e8 c5 fe ff ff       	call   f0100309 <cons_putc>
f0100444:	eb 1e                	jmp    f0100464 <cons_putc+0x15b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100446:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010044d:	8d 50 01             	lea    0x1(%eax),%edx
f0100450:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f0100457:	0f b7 c0             	movzwl %ax,%eax
f010045a:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100460:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100464:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f010046b:	cf 07 
f010046d:	76 42                	jbe    f01004b1 <cons_putc+0x1a8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010046f:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100474:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010047b:	00 
f010047c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100482:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100486:	89 04 24             	mov    %eax,(%esp)
f0100489:	e8 e6 0f 00 00       	call   f0101474 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010048e:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100494:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100499:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010049f:	83 c0 01             	add    $0x1,%eax
f01004a2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01004a7:	75 f0                	jne    f0100499 <cons_putc+0x190>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004a9:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004b0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004b1:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004b7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004bc:	89 ca                	mov    %ecx,%edx
f01004be:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004bf:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004c6:	8d 71 01             	lea    0x1(%ecx),%esi
f01004c9:	89 d8                	mov    %ebx,%eax
f01004cb:	66 c1 e8 08          	shr    $0x8,%ax
f01004cf:	89 f2                	mov    %esi,%edx
f01004d1:	ee                   	out    %al,(%dx)
f01004d2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004d7:	89 ca                	mov    %ecx,%edx
f01004d9:	ee                   	out    %al,(%dx)
f01004da:	89 d8                	mov    %ebx,%eax
f01004dc:	89 f2                	mov    %esi,%edx
f01004de:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004df:	83 c4 1c             	add    $0x1c,%esp
f01004e2:	5b                   	pop    %ebx
f01004e3:	5e                   	pop    %esi
f01004e4:	5f                   	pop    %edi
f01004e5:	5d                   	pop    %ebp
f01004e6:	c3                   	ret    

f01004e7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004e7:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004ee:	74 11                	je     f0100501 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004f0:	55                   	push   %ebp
f01004f1:	89 e5                	mov    %esp,%ebp
f01004f3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004f6:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f01004fb:	e8 bc fc ff ff       	call   f01001bc <cons_intr>
}
f0100500:	c9                   	leave  
f0100501:	f3 c3                	repz ret 

f0100503 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100503:	55                   	push   %ebp
f0100504:	89 e5                	mov    %esp,%ebp
f0100506:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100509:	b8 00 02 10 f0       	mov    $0xf0100200,%eax
f010050e:	e8 a9 fc ff ff       	call   f01001bc <cons_intr>
}
f0100513:	c9                   	leave  
f0100514:	c3                   	ret    

f0100515 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100515:	55                   	push   %ebp
f0100516:	89 e5                	mov    %esp,%ebp
f0100518:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010051b:	e8 c7 ff ff ff       	call   f01004e7 <serial_intr>
	kbd_intr();
f0100520:	e8 de ff ff ff       	call   f0100503 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100525:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f010052a:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100530:	74 26                	je     f0100558 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100532:	8d 50 01             	lea    0x1(%eax),%edx
f0100535:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010053b:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100542:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100544:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010054a:	75 11                	jne    f010055d <cons_getc+0x48>
			cons.rpos = 0;
f010054c:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100553:	00 00 00 
f0100556:	eb 05                	jmp    f010055d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100558:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010055d:	c9                   	leave  
f010055e:	c3                   	ret    

f010055f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010055f:	55                   	push   %ebp
f0100560:	89 e5                	mov    %esp,%ebp
f0100562:	57                   	push   %edi
f0100563:	56                   	push   %esi
f0100564:	53                   	push   %ebx
f0100565:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100568:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010056f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100576:	5a a5 
	if (*cp != 0xA55A) {
f0100578:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010057f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100583:	74 11                	je     f0100596 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100585:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f010058c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010058f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100594:	eb 16                	jmp    f01005ac <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100596:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010059d:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f01005a4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005a7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005ac:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01005b2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005b7:	89 ca                	mov    %ecx,%edx
f01005b9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ba:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005bd:	89 da                	mov    %ebx,%edx
f01005bf:	ec                   	in     (%dx),%al
f01005c0:	0f b6 f0             	movzbl %al,%esi
f01005c3:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005cb:	89 ca                	mov    %ecx,%edx
f01005cd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005ce:	89 da                	mov    %ebx,%edx
f01005d0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005d1:	89 3d 2c 25 11 f0    	mov    %edi,0xf011252c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005d7:	0f b6 d8             	movzbl %al,%ebx
f01005da:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005dc:	66 89 35 28 25 11 f0 	mov    %si,0xf0112528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005e3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005e8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ed:	89 f2                	mov    %esi,%edx
f01005ef:	ee                   	out    %al,(%dx)
f01005f0:	b2 fb                	mov    $0xfb,%dl
f01005f2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005f7:	ee                   	out    %al,(%dx)
f01005f8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005fd:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100602:	89 da                	mov    %ebx,%edx
f0100604:	ee                   	out    %al,(%dx)
f0100605:	b2 f9                	mov    $0xf9,%dl
f0100607:	b8 00 00 00 00       	mov    $0x0,%eax
f010060c:	ee                   	out    %al,(%dx)
f010060d:	b2 fb                	mov    $0xfb,%dl
f010060f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100614:	ee                   	out    %al,(%dx)
f0100615:	b2 fc                	mov    $0xfc,%dl
f0100617:	b8 00 00 00 00       	mov    $0x0,%eax
f010061c:	ee                   	out    %al,(%dx)
f010061d:	b2 f9                	mov    $0xf9,%dl
f010061f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100624:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100625:	b2 fd                	mov    $0xfd,%dl
f0100627:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100628:	3c ff                	cmp    $0xff,%al
f010062a:	0f 95 c1             	setne  %cl
f010062d:	88 0d 34 25 11 f0    	mov    %cl,0xf0112534
f0100633:	89 f2                	mov    %esi,%edx
f0100635:	ec                   	in     (%dx),%al
f0100636:	89 da                	mov    %ebx,%edx
f0100638:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100639:	84 c9                	test   %cl,%cl
f010063b:	75 0c                	jne    f0100649 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f010063d:	c7 04 24 50 19 10 f0 	movl   $0xf0101950,(%esp)
f0100644:	e8 d8 02 00 00       	call   f0100921 <cprintf>
}
f0100649:	83 c4 1c             	add    $0x1c,%esp
f010064c:	5b                   	pop    %ebx
f010064d:	5e                   	pop    %esi
f010064e:	5f                   	pop    %edi
f010064f:	5d                   	pop    %ebp
f0100650:	c3                   	ret    

f0100651 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100651:	55                   	push   %ebp
f0100652:	89 e5                	mov    %esp,%ebp
f0100654:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100657:	8b 45 08             	mov    0x8(%ebp),%eax
f010065a:	e8 aa fc ff ff       	call   f0100309 <cons_putc>
}
f010065f:	c9                   	leave  
f0100660:	c3                   	ret    

f0100661 <getchar>:

int
getchar(void)
{
f0100661:	55                   	push   %ebp
f0100662:	89 e5                	mov    %esp,%ebp
f0100664:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100667:	e8 a9 fe ff ff       	call   f0100515 <cons_getc>
f010066c:	85 c0                	test   %eax,%eax
f010066e:	74 f7                	je     f0100667 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100670:	c9                   	leave  
f0100671:	c3                   	ret    

f0100672 <iscons>:

int
iscons(int fdnum)
{
f0100672:	55                   	push   %ebp
f0100673:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100675:	b8 01 00 00 00       	mov    $0x1,%eax
f010067a:	5d                   	pop    %ebp
f010067b:	c3                   	ret    
f010067c:	66 90                	xchg   %ax,%ax
f010067e:	66 90                	xchg   %ax,%ax

f0100680 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100680:	55                   	push   %ebp
f0100681:	89 e5                	mov    %esp,%ebp
f0100683:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100686:	c7 44 24 08 a0 1b 10 	movl   $0xf0101ba0,0x8(%esp)
f010068d:	f0 
f010068e:	c7 44 24 04 be 1b 10 	movl   $0xf0101bbe,0x4(%esp)
f0100695:	f0 
f0100696:	c7 04 24 c3 1b 10 f0 	movl   $0xf0101bc3,(%esp)
f010069d:	e8 7f 02 00 00       	call   f0100921 <cprintf>
f01006a2:	c7 44 24 08 2c 1c 10 	movl   $0xf0101c2c,0x8(%esp)
f01006a9:	f0 
f01006aa:	c7 44 24 04 cc 1b 10 	movl   $0xf0101bcc,0x4(%esp)
f01006b1:	f0 
f01006b2:	c7 04 24 c3 1b 10 f0 	movl   $0xf0101bc3,(%esp)
f01006b9:	e8 63 02 00 00       	call   f0100921 <cprintf>
	return 0;
}
f01006be:	b8 00 00 00 00       	mov    $0x0,%eax
f01006c3:	c9                   	leave  
f01006c4:	c3                   	ret    

f01006c5 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006c5:	55                   	push   %ebp
f01006c6:	89 e5                	mov    %esp,%ebp
f01006c8:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006cb:	c7 04 24 d5 1b 10 f0 	movl   $0xf0101bd5,(%esp)
f01006d2:	e8 4a 02 00 00       	call   f0100921 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006d7:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006de:	00 
f01006df:	c7 04 24 54 1c 10 f0 	movl   $0xf0101c54,(%esp)
f01006e6:	e8 36 02 00 00       	call   f0100921 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006eb:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006f2:	00 
f01006f3:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006fa:	f0 
f01006fb:	c7 04 24 7c 1c 10 f0 	movl   $0xf0101c7c,(%esp)
f0100702:	e8 1a 02 00 00       	call   f0100921 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100707:	c7 44 24 08 b7 18 10 	movl   $0x1018b7,0x8(%esp)
f010070e:	00 
f010070f:	c7 44 24 04 b7 18 10 	movl   $0xf01018b7,0x4(%esp)
f0100716:	f0 
f0100717:	c7 04 24 a0 1c 10 f0 	movl   $0xf0101ca0,(%esp)
f010071e:	e8 fe 01 00 00       	call   f0100921 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100723:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f010072a:	00 
f010072b:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f0100732:	f0 
f0100733:	c7 04 24 c4 1c 10 f0 	movl   $0xf0101cc4,(%esp)
f010073a:	e8 e2 01 00 00       	call   f0100921 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010073f:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100746:	00 
f0100747:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f010074e:	f0 
f010074f:	c7 04 24 e8 1c 10 f0 	movl   $0xf0101ce8,(%esp)
f0100756:	e8 c6 01 00 00       	call   f0100921 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010075b:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f0100760:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100765:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010076a:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100770:	85 c0                	test   %eax,%eax
f0100772:	0f 48 c2             	cmovs  %edx,%eax
f0100775:	c1 f8 0a             	sar    $0xa,%eax
f0100778:	89 44 24 04          	mov    %eax,0x4(%esp)
f010077c:	c7 04 24 0c 1d 10 f0 	movl   $0xf0101d0c,(%esp)
f0100783:	e8 99 01 00 00       	call   f0100921 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100788:	b8 00 00 00 00       	mov    $0x0,%eax
f010078d:	c9                   	leave  
f010078e:	c3                   	ret    

f010078f <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010078f:	55                   	push   %ebp
f0100790:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100792:	b8 00 00 00 00       	mov    $0x0,%eax
f0100797:	5d                   	pop    %ebp
f0100798:	c3                   	ret    

f0100799 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100799:	55                   	push   %ebp
f010079a:	89 e5                	mov    %esp,%ebp
f010079c:	57                   	push   %edi
f010079d:	56                   	push   %esi
f010079e:	53                   	push   %ebx
f010079f:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007a2:	c7 04 24 38 1d 10 f0 	movl   $0xf0101d38,(%esp)
f01007a9:	e8 73 01 00 00       	call   f0100921 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007ae:	c7 04 24 5c 1d 10 f0 	movl   $0xf0101d5c,(%esp)
f01007b5:	e8 67 01 00 00       	call   f0100921 <cprintf>


	while (1) {
		buf = readline("K> ");
f01007ba:	c7 04 24 ee 1b 10 f0 	movl   $0xf0101bee,(%esp)
f01007c1:	e8 0a 0a 00 00       	call   f01011d0 <readline>
f01007c6:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007c8:	85 c0                	test   %eax,%eax
f01007ca:	74 ee                	je     f01007ba <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007cc:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007d3:	be 00 00 00 00       	mov    $0x0,%esi
f01007d8:	eb 0a                	jmp    f01007e4 <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007da:	c6 03 00             	movb   $0x0,(%ebx)
f01007dd:	89 f7                	mov    %esi,%edi
f01007df:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007e2:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007e4:	0f b6 03             	movzbl (%ebx),%eax
f01007e7:	84 c0                	test   %al,%al
f01007e9:	74 63                	je     f010084e <monitor+0xb5>
f01007eb:	0f be c0             	movsbl %al,%eax
f01007ee:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007f2:	c7 04 24 f2 1b 10 f0 	movl   $0xf0101bf2,(%esp)
f01007f9:	e8 ec 0b 00 00       	call   f01013ea <strchr>
f01007fe:	85 c0                	test   %eax,%eax
f0100800:	75 d8                	jne    f01007da <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100802:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100805:	74 47                	je     f010084e <monitor+0xb5>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100807:	83 fe 0f             	cmp    $0xf,%esi
f010080a:	75 16                	jne    f0100822 <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010080c:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100813:	00 
f0100814:	c7 04 24 f7 1b 10 f0 	movl   $0xf0101bf7,(%esp)
f010081b:	e8 01 01 00 00       	call   f0100921 <cprintf>
f0100820:	eb 98                	jmp    f01007ba <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100822:	8d 7e 01             	lea    0x1(%esi),%edi
f0100825:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100829:	eb 03                	jmp    f010082e <monitor+0x95>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010082b:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010082e:	0f b6 03             	movzbl (%ebx),%eax
f0100831:	84 c0                	test   %al,%al
f0100833:	74 ad                	je     f01007e2 <monitor+0x49>
f0100835:	0f be c0             	movsbl %al,%eax
f0100838:	89 44 24 04          	mov    %eax,0x4(%esp)
f010083c:	c7 04 24 f2 1b 10 f0 	movl   $0xf0101bf2,(%esp)
f0100843:	e8 a2 0b 00 00       	call   f01013ea <strchr>
f0100848:	85 c0                	test   %eax,%eax
f010084a:	74 df                	je     f010082b <monitor+0x92>
f010084c:	eb 94                	jmp    f01007e2 <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f010084e:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100855:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100856:	85 f6                	test   %esi,%esi
f0100858:	0f 84 5c ff ff ff    	je     f01007ba <monitor+0x21>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010085e:	c7 44 24 04 be 1b 10 	movl   $0xf0101bbe,0x4(%esp)
f0100865:	f0 
f0100866:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100869:	89 04 24             	mov    %eax,(%esp)
f010086c:	e8 1b 0b 00 00       	call   f010138c <strcmp>
f0100871:	85 c0                	test   %eax,%eax
f0100873:	74 1b                	je     f0100890 <monitor+0xf7>
f0100875:	c7 44 24 04 cc 1b 10 	movl   $0xf0101bcc,0x4(%esp)
f010087c:	f0 
f010087d:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100880:	89 04 24             	mov    %eax,(%esp)
f0100883:	e8 04 0b 00 00       	call   f010138c <strcmp>
f0100888:	85 c0                	test   %eax,%eax
f010088a:	75 2f                	jne    f01008bb <monitor+0x122>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f010088c:	b0 01                	mov    $0x1,%al
f010088e:	eb 05                	jmp    f0100895 <monitor+0xfc>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100890:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100895:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100898:	01 d0                	add    %edx,%eax
f010089a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010089d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01008a1:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008a4:	89 54 24 04          	mov    %edx,0x4(%esp)
f01008a8:	89 34 24             	mov    %esi,(%esp)
f01008ab:	ff 14 85 8c 1d 10 f0 	call   *-0xfefe274(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008b2:	85 c0                	test   %eax,%eax
f01008b4:	78 1d                	js     f01008d3 <monitor+0x13a>
f01008b6:	e9 ff fe ff ff       	jmp    f01007ba <monitor+0x21>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008bb:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008be:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008c2:	c7 04 24 14 1c 10 f0 	movl   $0xf0101c14,(%esp)
f01008c9:	e8 53 00 00 00       	call   f0100921 <cprintf>
f01008ce:	e9 e7 fe ff ff       	jmp    f01007ba <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008d3:	83 c4 5c             	add    $0x5c,%esp
f01008d6:	5b                   	pop    %ebx
f01008d7:	5e                   	pop    %esi
f01008d8:	5f                   	pop    %edi
f01008d9:	5d                   	pop    %ebp
f01008da:	c3                   	ret    

f01008db <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01008db:	55                   	push   %ebp
f01008dc:	89 e5                	mov    %esp,%ebp
f01008de:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01008e1:	8b 45 08             	mov    0x8(%ebp),%eax
f01008e4:	89 04 24             	mov    %eax,(%esp)
f01008e7:	e8 65 fd ff ff       	call   f0100651 <cputchar>
	*cnt++;
}
f01008ec:	c9                   	leave  
f01008ed:	c3                   	ret    

f01008ee <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01008ee:	55                   	push   %ebp
f01008ef:	89 e5                	mov    %esp,%ebp
f01008f1:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01008f4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01008fb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01008fe:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100902:	8b 45 08             	mov    0x8(%ebp),%eax
f0100905:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100909:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010090c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100910:	c7 04 24 db 08 10 f0 	movl   $0xf01008db,(%esp)
f0100917:	e8 52 04 00 00       	call   f0100d6e <vprintfmt>
	return cnt;
}
f010091c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010091f:	c9                   	leave  
f0100920:	c3                   	ret    

f0100921 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100921:	55                   	push   %ebp
f0100922:	89 e5                	mov    %esp,%ebp
f0100924:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100927:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010092a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010092e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100931:	89 04 24             	mov    %eax,(%esp)
f0100934:	e8 b5 ff ff ff       	call   f01008ee <vcprintf>
	va_end(ap);

	return cnt;
}
f0100939:	c9                   	leave  
f010093a:	c3                   	ret    

f010093b <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010093b:	55                   	push   %ebp
f010093c:	89 e5                	mov    %esp,%ebp
f010093e:	57                   	push   %edi
f010093f:	56                   	push   %esi
f0100940:	53                   	push   %ebx
f0100941:	83 ec 10             	sub    $0x10,%esp
f0100944:	89 c6                	mov    %eax,%esi
f0100946:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100949:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f010094c:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010094f:	8b 1a                	mov    (%edx),%ebx
f0100951:	8b 01                	mov    (%ecx),%eax
f0100953:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100956:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f010095d:	eb 77                	jmp    f01009d6 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f010095f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100962:	01 d8                	add    %ebx,%eax
f0100964:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100969:	99                   	cltd   
f010096a:	f7 f9                	idiv   %ecx
f010096c:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010096e:	eb 01                	jmp    f0100971 <stab_binsearch+0x36>
			m--;
f0100970:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100971:	39 d9                	cmp    %ebx,%ecx
f0100973:	7c 1d                	jl     f0100992 <stab_binsearch+0x57>
f0100975:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100978:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f010097d:	39 fa                	cmp    %edi,%edx
f010097f:	75 ef                	jne    f0100970 <stab_binsearch+0x35>
f0100981:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100984:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100987:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f010098b:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010098e:	73 18                	jae    f01009a8 <stab_binsearch+0x6d>
f0100990:	eb 05                	jmp    f0100997 <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100992:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100995:	eb 3f                	jmp    f01009d6 <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100997:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f010099a:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f010099c:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010099f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01009a6:	eb 2e                	jmp    f01009d6 <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01009a8:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009ab:	73 15                	jae    f01009c2 <stab_binsearch+0x87>
			*region_right = m - 1;
f01009ad:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01009b0:	48                   	dec    %eax
f01009b1:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009b4:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01009b7:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009b9:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01009c0:	eb 14                	jmp    f01009d6 <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01009c2:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01009c5:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f01009c8:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f01009ca:	ff 45 0c             	incl   0xc(%ebp)
f01009cd:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009cf:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01009d6:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01009d9:	7e 84                	jle    f010095f <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01009db:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f01009df:	75 0d                	jne    f01009ee <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f01009e1:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01009e4:	8b 00                	mov    (%eax),%eax
f01009e6:	48                   	dec    %eax
f01009e7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01009ea:	89 07                	mov    %eax,(%edi)
f01009ec:	eb 22                	jmp    f0100a10 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009ee:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009f1:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01009f3:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f01009f6:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009f8:	eb 01                	jmp    f01009fb <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01009fa:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009fb:	39 c1                	cmp    %eax,%ecx
f01009fd:	7d 0c                	jge    f0100a0b <stab_binsearch+0xd0>
f01009ff:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100a02:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a07:	39 fa                	cmp    %edi,%edx
f0100a09:	75 ef                	jne    f01009fa <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a0b:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100a0e:	89 07                	mov    %eax,(%edi)
	}
}
f0100a10:	83 c4 10             	add    $0x10,%esp
f0100a13:	5b                   	pop    %ebx
f0100a14:	5e                   	pop    %esi
f0100a15:	5f                   	pop    %edi
f0100a16:	5d                   	pop    %ebp
f0100a17:	c3                   	ret    

f0100a18 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a18:	55                   	push   %ebp
f0100a19:	89 e5                	mov    %esp,%ebp
f0100a1b:	57                   	push   %edi
f0100a1c:	56                   	push   %esi
f0100a1d:	53                   	push   %ebx
f0100a1e:	83 ec 2c             	sub    $0x2c,%esp
f0100a21:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a24:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a27:	c7 03 9c 1d 10 f0    	movl   $0xf0101d9c,(%ebx)
	info->eip_line = 0;
f0100a2d:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100a34:	c7 43 08 9c 1d 10 f0 	movl   $0xf0101d9c,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100a3b:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100a42:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100a45:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a4c:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100a52:	76 12                	jbe    f0100a66 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a54:	b8 00 71 10 f0       	mov    $0xf0107100,%eax
f0100a59:	3d 19 58 10 f0       	cmp    $0xf0105819,%eax
f0100a5e:	0f 86 6b 01 00 00    	jbe    f0100bcf <debuginfo_eip+0x1b7>
f0100a64:	eb 1c                	jmp    f0100a82 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100a66:	c7 44 24 08 a6 1d 10 	movl   $0xf0101da6,0x8(%esp)
f0100a6d:	f0 
f0100a6e:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100a75:	00 
f0100a76:	c7 04 24 b3 1d 10 f0 	movl   $0xf0101db3,(%esp)
f0100a7d:	e8 76 f6 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a82:	80 3d ff 70 10 f0 00 	cmpb   $0x0,0xf01070ff
f0100a89:	0f 85 47 01 00 00    	jne    f0100bd6 <debuginfo_eip+0x1be>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100a8f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100a96:	b8 18 58 10 f0       	mov    $0xf0105818,%eax
f0100a9b:	2d f0 1f 10 f0       	sub    $0xf0101ff0,%eax
f0100aa0:	c1 f8 02             	sar    $0x2,%eax
f0100aa3:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100aa9:	83 e8 01             	sub    $0x1,%eax
f0100aac:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100aaf:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ab3:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100aba:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100abd:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100ac0:	b8 f0 1f 10 f0       	mov    $0xf0101ff0,%eax
f0100ac5:	e8 71 fe ff ff       	call   f010093b <stab_binsearch>
	if (lfile == 0)
f0100aca:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100acd:	85 c0                	test   %eax,%eax
f0100acf:	0f 84 08 01 00 00    	je     f0100bdd <debuginfo_eip+0x1c5>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100ad5:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100ad8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100adb:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100ade:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ae2:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100ae9:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100aec:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100aef:	b8 f0 1f 10 f0       	mov    $0xf0101ff0,%eax
f0100af4:	e8 42 fe ff ff       	call   f010093b <stab_binsearch>

	if (lfun <= rfun) {
f0100af9:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100afc:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100aff:	7f 2e                	jg     f0100b2f <debuginfo_eip+0x117>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b01:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b04:	8d 90 f0 1f 10 f0    	lea    -0xfefe010(%eax),%edx
f0100b0a:	8b 80 f0 1f 10 f0    	mov    -0xfefe010(%eax),%eax
f0100b10:	b9 00 71 10 f0       	mov    $0xf0107100,%ecx
f0100b15:	81 e9 19 58 10 f0    	sub    $0xf0105819,%ecx
f0100b1b:	39 c8                	cmp    %ecx,%eax
f0100b1d:	73 08                	jae    f0100b27 <debuginfo_eip+0x10f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b1f:	05 19 58 10 f0       	add    $0xf0105819,%eax
f0100b24:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b27:	8b 42 08             	mov    0x8(%edx),%eax
f0100b2a:	89 43 10             	mov    %eax,0x10(%ebx)
f0100b2d:	eb 06                	jmp    f0100b35 <debuginfo_eip+0x11d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b2f:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100b32:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100b35:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100b3c:	00 
f0100b3d:	8b 43 08             	mov    0x8(%ebx),%eax
f0100b40:	89 04 24             	mov    %eax,(%esp)
f0100b43:	e8 c3 08 00 00       	call   f010140b <strfind>
f0100b48:	2b 43 08             	sub    0x8(%ebx),%eax
f0100b4b:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b4e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100b51:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b54:	05 f0 1f 10 f0       	add    $0xf0101ff0,%eax
f0100b59:	eb 06                	jmp    f0100b61 <debuginfo_eip+0x149>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100b5b:	83 ef 01             	sub    $0x1,%edi
f0100b5e:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b61:	39 cf                	cmp    %ecx,%edi
f0100b63:	7c 33                	jl     f0100b98 <debuginfo_eip+0x180>
	       && stabs[lline].n_type != N_SOL
f0100b65:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100b69:	80 fa 84             	cmp    $0x84,%dl
f0100b6c:	74 0b                	je     f0100b79 <debuginfo_eip+0x161>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100b6e:	80 fa 64             	cmp    $0x64,%dl
f0100b71:	75 e8                	jne    f0100b5b <debuginfo_eip+0x143>
f0100b73:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100b77:	74 e2                	je     f0100b5b <debuginfo_eip+0x143>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100b79:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100b7c:	8b 87 f0 1f 10 f0    	mov    -0xfefe010(%edi),%eax
f0100b82:	ba 00 71 10 f0       	mov    $0xf0107100,%edx
f0100b87:	81 ea 19 58 10 f0    	sub    $0xf0105819,%edx
f0100b8d:	39 d0                	cmp    %edx,%eax
f0100b8f:	73 07                	jae    f0100b98 <debuginfo_eip+0x180>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100b91:	05 19 58 10 f0       	add    $0xf0105819,%eax
f0100b96:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100b98:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100b9b:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100b9e:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100ba3:	39 f1                	cmp    %esi,%ecx
f0100ba5:	7d 42                	jge    f0100be9 <debuginfo_eip+0x1d1>
		for (lline = lfun + 1;
f0100ba7:	8d 51 01             	lea    0x1(%ecx),%edx
f0100baa:	6b c1 0c             	imul   $0xc,%ecx,%eax
f0100bad:	05 f0 1f 10 f0       	add    $0xf0101ff0,%eax
f0100bb2:	eb 07                	jmp    f0100bbb <debuginfo_eip+0x1a3>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100bb4:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100bb8:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100bbb:	39 f2                	cmp    %esi,%edx
f0100bbd:	74 25                	je     f0100be4 <debuginfo_eip+0x1cc>
f0100bbf:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100bc2:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100bc6:	74 ec                	je     f0100bb4 <debuginfo_eip+0x19c>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100bc8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bcd:	eb 1a                	jmp    f0100be9 <debuginfo_eip+0x1d1>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100bcf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bd4:	eb 13                	jmp    f0100be9 <debuginfo_eip+0x1d1>
f0100bd6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bdb:	eb 0c                	jmp    f0100be9 <debuginfo_eip+0x1d1>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100bdd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100be2:	eb 05                	jmp    f0100be9 <debuginfo_eip+0x1d1>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100be4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100be9:	83 c4 2c             	add    $0x2c,%esp
f0100bec:	5b                   	pop    %ebx
f0100bed:	5e                   	pop    %esi
f0100bee:	5f                   	pop    %edi
f0100bef:	5d                   	pop    %ebp
f0100bf0:	c3                   	ret    
f0100bf1:	66 90                	xchg   %ax,%ax
f0100bf3:	66 90                	xchg   %ax,%ax
f0100bf5:	66 90                	xchg   %ax,%ax
f0100bf7:	66 90                	xchg   %ax,%ax
f0100bf9:	66 90                	xchg   %ax,%ax
f0100bfb:	66 90                	xchg   %ax,%ax
f0100bfd:	66 90                	xchg   %ax,%ax
f0100bff:	90                   	nop

f0100c00 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c00:	55                   	push   %ebp
f0100c01:	89 e5                	mov    %esp,%ebp
f0100c03:	57                   	push   %edi
f0100c04:	56                   	push   %esi
f0100c05:	53                   	push   %ebx
f0100c06:	83 ec 3c             	sub    $0x3c,%esp
f0100c09:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100c0c:	89 d7                	mov    %edx,%edi
f0100c0e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c11:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100c14:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c17:	89 c3                	mov    %eax,%ebx
f0100c19:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100c1c:	8b 45 10             	mov    0x10(%ebp),%eax
f0100c1f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c22:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100c27:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100c2a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100c2d:	39 d9                	cmp    %ebx,%ecx
f0100c2f:	72 05                	jb     f0100c36 <printnum+0x36>
f0100c31:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100c34:	77 69                	ja     f0100c9f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100c36:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100c39:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100c3d:	83 ee 01             	sub    $0x1,%esi
f0100c40:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100c44:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100c48:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100c4c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100c50:	89 c3                	mov    %eax,%ebx
f0100c52:	89 d6                	mov    %edx,%esi
f0100c54:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100c57:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100c5a:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100c5e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100c62:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c65:	89 04 24             	mov    %eax,(%esp)
f0100c68:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c6b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c6f:	e8 bc 09 00 00       	call   f0101630 <__udivdi3>
f0100c74:	89 d9                	mov    %ebx,%ecx
f0100c76:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100c7a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100c7e:	89 04 24             	mov    %eax,(%esp)
f0100c81:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100c85:	89 fa                	mov    %edi,%edx
f0100c87:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c8a:	e8 71 ff ff ff       	call   f0100c00 <printnum>
f0100c8f:	eb 1b                	jmp    f0100cac <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100c91:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100c95:	8b 45 18             	mov    0x18(%ebp),%eax
f0100c98:	89 04 24             	mov    %eax,(%esp)
f0100c9b:	ff d3                	call   *%ebx
f0100c9d:	eb 03                	jmp    f0100ca2 <printnum+0xa2>
f0100c9f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100ca2:	83 ee 01             	sub    $0x1,%esi
f0100ca5:	85 f6                	test   %esi,%esi
f0100ca7:	7f e8                	jg     f0100c91 <printnum+0x91>
f0100ca9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100cac:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100cb0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100cb4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100cb7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100cba:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100cbe:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100cc2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100cc5:	89 04 24             	mov    %eax,(%esp)
f0100cc8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100ccb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ccf:	e8 8c 0a 00 00       	call   f0101760 <__umoddi3>
f0100cd4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100cd8:	0f be 80 c1 1d 10 f0 	movsbl -0xfefe23f(%eax),%eax
f0100cdf:	89 04 24             	mov    %eax,(%esp)
f0100ce2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ce5:	ff d0                	call   *%eax
}
f0100ce7:	83 c4 3c             	add    $0x3c,%esp
f0100cea:	5b                   	pop    %ebx
f0100ceb:	5e                   	pop    %esi
f0100cec:	5f                   	pop    %edi
f0100ced:	5d                   	pop    %ebp
f0100cee:	c3                   	ret    

f0100cef <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100cef:	55                   	push   %ebp
f0100cf0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100cf2:	83 fa 01             	cmp    $0x1,%edx
f0100cf5:	7e 0e                	jle    f0100d05 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100cf7:	8b 10                	mov    (%eax),%edx
f0100cf9:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100cfc:	89 08                	mov    %ecx,(%eax)
f0100cfe:	8b 02                	mov    (%edx),%eax
f0100d00:	8b 52 04             	mov    0x4(%edx),%edx
f0100d03:	eb 22                	jmp    f0100d27 <getuint+0x38>
	else if (lflag)
f0100d05:	85 d2                	test   %edx,%edx
f0100d07:	74 10                	je     f0100d19 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d09:	8b 10                	mov    (%eax),%edx
f0100d0b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d0e:	89 08                	mov    %ecx,(%eax)
f0100d10:	8b 02                	mov    (%edx),%eax
f0100d12:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d17:	eb 0e                	jmp    f0100d27 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d19:	8b 10                	mov    (%eax),%edx
f0100d1b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d1e:	89 08                	mov    %ecx,(%eax)
f0100d20:	8b 02                	mov    (%edx),%eax
f0100d22:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100d27:	5d                   	pop    %ebp
f0100d28:	c3                   	ret    

f0100d29 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d29:	55                   	push   %ebp
f0100d2a:	89 e5                	mov    %esp,%ebp
f0100d2c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100d2f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100d33:	8b 10                	mov    (%eax),%edx
f0100d35:	3b 50 04             	cmp    0x4(%eax),%edx
f0100d38:	73 0a                	jae    f0100d44 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100d3a:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100d3d:	89 08                	mov    %ecx,(%eax)
f0100d3f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d42:	88 02                	mov    %al,(%edx)
}
f0100d44:	5d                   	pop    %ebp
f0100d45:	c3                   	ret    

f0100d46 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100d46:	55                   	push   %ebp
f0100d47:	89 e5                	mov    %esp,%ebp
f0100d49:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100d4c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100d4f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d53:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d56:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d5a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d5d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d61:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d64:	89 04 24             	mov    %eax,(%esp)
f0100d67:	e8 02 00 00 00       	call   f0100d6e <vprintfmt>
	va_end(ap);
}
f0100d6c:	c9                   	leave  
f0100d6d:	c3                   	ret    

f0100d6e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100d6e:	55                   	push   %ebp
f0100d6f:	89 e5                	mov    %esp,%ebp
f0100d71:	57                   	push   %edi
f0100d72:	56                   	push   %esi
f0100d73:	53                   	push   %ebx
f0100d74:	83 ec 3c             	sub    $0x3c,%esp
f0100d77:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100d7a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100d7d:	eb 14                	jmp    f0100d93 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100d7f:	85 c0                	test   %eax,%eax
f0100d81:	0f 84 b3 03 00 00    	je     f010113a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0100d87:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d8b:	89 04 24             	mov    %eax,(%esp)
f0100d8e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100d91:	89 f3                	mov    %esi,%ebx
f0100d93:	8d 73 01             	lea    0x1(%ebx),%esi
f0100d96:	0f b6 03             	movzbl (%ebx),%eax
f0100d99:	83 f8 25             	cmp    $0x25,%eax
f0100d9c:	75 e1                	jne    f0100d7f <vprintfmt+0x11>
f0100d9e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100da2:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0100da9:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100db0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100db7:	ba 00 00 00 00       	mov    $0x0,%edx
f0100dbc:	eb 1d                	jmp    f0100ddb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dbe:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100dc0:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100dc4:	eb 15                	jmp    f0100ddb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dc6:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100dc8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100dcc:	eb 0d                	jmp    f0100ddb <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100dce:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100dd1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100dd4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ddb:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100dde:	0f b6 0e             	movzbl (%esi),%ecx
f0100de1:	0f b6 c1             	movzbl %cl,%eax
f0100de4:	83 e9 23             	sub    $0x23,%ecx
f0100de7:	80 f9 55             	cmp    $0x55,%cl
f0100dea:	0f 87 2a 03 00 00    	ja     f010111a <vprintfmt+0x3ac>
f0100df0:	0f b6 c9             	movzbl %cl,%ecx
f0100df3:	ff 24 8d 60 1e 10 f0 	jmp    *-0xfefe1a0(,%ecx,4)
f0100dfa:	89 de                	mov    %ebx,%esi
f0100dfc:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e01:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100e04:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0100e08:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100e0b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0100e0e:	83 fb 09             	cmp    $0x9,%ebx
f0100e11:	77 36                	ja     f0100e49 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e13:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e16:	eb e9                	jmp    f0100e01 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e18:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e1b:	8d 48 04             	lea    0x4(%eax),%ecx
f0100e1e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100e21:	8b 00                	mov    (%eax),%eax
f0100e23:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e26:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e28:	eb 22                	jmp    f0100e4c <vprintfmt+0xde>
f0100e2a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100e2d:	85 c9                	test   %ecx,%ecx
f0100e2f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e34:	0f 49 c1             	cmovns %ecx,%eax
f0100e37:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e3a:	89 de                	mov    %ebx,%esi
f0100e3c:	eb 9d                	jmp    f0100ddb <vprintfmt+0x6d>
f0100e3e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100e40:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0100e47:	eb 92                	jmp    f0100ddb <vprintfmt+0x6d>
f0100e49:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f0100e4c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100e50:	79 89                	jns    f0100ddb <vprintfmt+0x6d>
f0100e52:	e9 77 ff ff ff       	jmp    f0100dce <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100e57:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e5a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100e5c:	e9 7a ff ff ff       	jmp    f0100ddb <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100e61:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e64:	8d 50 04             	lea    0x4(%eax),%edx
f0100e67:	89 55 14             	mov    %edx,0x14(%ebp)
f0100e6a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e6e:	8b 00                	mov    (%eax),%eax
f0100e70:	89 04 24             	mov    %eax,(%esp)
f0100e73:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100e76:	e9 18 ff ff ff       	jmp    f0100d93 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100e7b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e7e:	8d 50 04             	lea    0x4(%eax),%edx
f0100e81:	89 55 14             	mov    %edx,0x14(%ebp)
f0100e84:	8b 00                	mov    (%eax),%eax
f0100e86:	99                   	cltd   
f0100e87:	31 d0                	xor    %edx,%eax
f0100e89:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100e8b:	83 f8 07             	cmp    $0x7,%eax
f0100e8e:	7f 0b                	jg     f0100e9b <vprintfmt+0x12d>
f0100e90:	8b 14 85 c0 1f 10 f0 	mov    -0xfefe040(,%eax,4),%edx
f0100e97:	85 d2                	test   %edx,%edx
f0100e99:	75 20                	jne    f0100ebb <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f0100e9b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e9f:	c7 44 24 08 d9 1d 10 	movl   $0xf0101dd9,0x8(%esp)
f0100ea6:	f0 
f0100ea7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100eab:	8b 45 08             	mov    0x8(%ebp),%eax
f0100eae:	89 04 24             	mov    %eax,(%esp)
f0100eb1:	e8 90 fe ff ff       	call   f0100d46 <printfmt>
f0100eb6:	e9 d8 fe ff ff       	jmp    f0100d93 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0100ebb:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100ebf:	c7 44 24 08 e2 1d 10 	movl   $0xf0101de2,0x8(%esp)
f0100ec6:	f0 
f0100ec7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ecb:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ece:	89 04 24             	mov    %eax,(%esp)
f0100ed1:	e8 70 fe ff ff       	call   f0100d46 <printfmt>
f0100ed6:	e9 b8 fe ff ff       	jmp    f0100d93 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100edb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100ede:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ee1:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100ee4:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ee7:	8d 50 04             	lea    0x4(%eax),%edx
f0100eea:	89 55 14             	mov    %edx,0x14(%ebp)
f0100eed:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0100eef:	85 f6                	test   %esi,%esi
f0100ef1:	b8 d2 1d 10 f0       	mov    $0xf0101dd2,%eax
f0100ef6:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0100ef9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0100efd:	0f 84 97 00 00 00    	je     f0100f9a <vprintfmt+0x22c>
f0100f03:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0100f07:	0f 8e 9b 00 00 00    	jle    f0100fa8 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f0d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100f11:	89 34 24             	mov    %esi,(%esp)
f0100f14:	e8 9f 03 00 00       	call   f01012b8 <strnlen>
f0100f19:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100f1c:	29 c2                	sub    %eax,%edx
f0100f1e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0100f21:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0100f25:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100f28:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0100f2b:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f2e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0100f31:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f33:	eb 0f                	jmp    f0100f44 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0100f35:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f39:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100f3c:	89 04 24             	mov    %eax,(%esp)
f0100f3f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f41:	83 eb 01             	sub    $0x1,%ebx
f0100f44:	85 db                	test   %ebx,%ebx
f0100f46:	7f ed                	jg     f0100f35 <vprintfmt+0x1c7>
f0100f48:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0100f4b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100f4e:	85 d2                	test   %edx,%edx
f0100f50:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f55:	0f 49 c2             	cmovns %edx,%eax
f0100f58:	29 c2                	sub    %eax,%edx
f0100f5a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0100f5d:	89 d7                	mov    %edx,%edi
f0100f5f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100f62:	eb 50                	jmp    f0100fb4 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100f64:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f68:	74 1e                	je     f0100f88 <vprintfmt+0x21a>
f0100f6a:	0f be d2             	movsbl %dl,%edx
f0100f6d:	83 ea 20             	sub    $0x20,%edx
f0100f70:	83 fa 5e             	cmp    $0x5e,%edx
f0100f73:	76 13                	jbe    f0100f88 <vprintfmt+0x21a>
					putch('?', putdat);
f0100f75:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f78:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f7c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0100f83:	ff 55 08             	call   *0x8(%ebp)
f0100f86:	eb 0d                	jmp    f0100f95 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0100f88:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100f8b:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100f8f:	89 04 24             	mov    %eax,(%esp)
f0100f92:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100f95:	83 ef 01             	sub    $0x1,%edi
f0100f98:	eb 1a                	jmp    f0100fb4 <vprintfmt+0x246>
f0100f9a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0100f9d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100fa0:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0100fa3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100fa6:	eb 0c                	jmp    f0100fb4 <vprintfmt+0x246>
f0100fa8:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0100fab:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100fae:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0100fb1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100fb4:	83 c6 01             	add    $0x1,%esi
f0100fb7:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f0100fbb:	0f be c2             	movsbl %dl,%eax
f0100fbe:	85 c0                	test   %eax,%eax
f0100fc0:	74 27                	je     f0100fe9 <vprintfmt+0x27b>
f0100fc2:	85 db                	test   %ebx,%ebx
f0100fc4:	78 9e                	js     f0100f64 <vprintfmt+0x1f6>
f0100fc6:	83 eb 01             	sub    $0x1,%ebx
f0100fc9:	79 99                	jns    f0100f64 <vprintfmt+0x1f6>
f0100fcb:	89 f8                	mov    %edi,%eax
f0100fcd:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100fd0:	8b 75 08             	mov    0x8(%ebp),%esi
f0100fd3:	89 c3                	mov    %eax,%ebx
f0100fd5:	eb 1a                	jmp    f0100ff1 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0100fd7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fdb:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100fe2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100fe4:	83 eb 01             	sub    $0x1,%ebx
f0100fe7:	eb 08                	jmp    f0100ff1 <vprintfmt+0x283>
f0100fe9:	89 fb                	mov    %edi,%ebx
f0100feb:	8b 75 08             	mov    0x8(%ebp),%esi
f0100fee:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100ff1:	85 db                	test   %ebx,%ebx
f0100ff3:	7f e2                	jg     f0100fd7 <vprintfmt+0x269>
f0100ff5:	89 75 08             	mov    %esi,0x8(%ebp)
f0100ff8:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100ffb:	e9 93 fd ff ff       	jmp    f0100d93 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101000:	83 fa 01             	cmp    $0x1,%edx
f0101003:	7e 16                	jle    f010101b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0101005:	8b 45 14             	mov    0x14(%ebp),%eax
f0101008:	8d 50 08             	lea    0x8(%eax),%edx
f010100b:	89 55 14             	mov    %edx,0x14(%ebp)
f010100e:	8b 50 04             	mov    0x4(%eax),%edx
f0101011:	8b 00                	mov    (%eax),%eax
f0101013:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101016:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101019:	eb 32                	jmp    f010104d <vprintfmt+0x2df>
	else if (lflag)
f010101b:	85 d2                	test   %edx,%edx
f010101d:	74 18                	je     f0101037 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010101f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101022:	8d 50 04             	lea    0x4(%eax),%edx
f0101025:	89 55 14             	mov    %edx,0x14(%ebp)
f0101028:	8b 30                	mov    (%eax),%esi
f010102a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010102d:	89 f0                	mov    %esi,%eax
f010102f:	c1 f8 1f             	sar    $0x1f,%eax
f0101032:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101035:	eb 16                	jmp    f010104d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0101037:	8b 45 14             	mov    0x14(%ebp),%eax
f010103a:	8d 50 04             	lea    0x4(%eax),%edx
f010103d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101040:	8b 30                	mov    (%eax),%esi
f0101042:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0101045:	89 f0                	mov    %esi,%eax
f0101047:	c1 f8 1f             	sar    $0x1f,%eax
f010104a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010104d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101050:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101053:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101058:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010105c:	0f 89 80 00 00 00    	jns    f01010e2 <vprintfmt+0x374>
				putch('-', putdat);
f0101062:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101066:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010106d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101070:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101073:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101076:	f7 d8                	neg    %eax
f0101078:	83 d2 00             	adc    $0x0,%edx
f010107b:	f7 da                	neg    %edx
			}
			base = 10;
f010107d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101082:	eb 5e                	jmp    f01010e2 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101084:	8d 45 14             	lea    0x14(%ebp),%eax
f0101087:	e8 63 fc ff ff       	call   f0100cef <getuint>
			base = 10;
f010108c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101091:	eb 4f                	jmp    f01010e2 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0101093:	8d 45 14             	lea    0x14(%ebp),%eax
f0101096:	e8 54 fc ff ff       	call   f0100cef <getuint>
			base = 8;
f010109b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01010a0:	eb 40                	jmp    f01010e2 <vprintfmt+0x374>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f01010a2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010a6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01010ad:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01010b0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010b4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01010bb:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01010be:	8b 45 14             	mov    0x14(%ebp),%eax
f01010c1:	8d 50 04             	lea    0x4(%eax),%edx
f01010c4:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01010c7:	8b 00                	mov    (%eax),%eax
f01010c9:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01010ce:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01010d3:	eb 0d                	jmp    f01010e2 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01010d5:	8d 45 14             	lea    0x14(%ebp),%eax
f01010d8:	e8 12 fc ff ff       	call   f0100cef <getuint>
			base = 16;
f01010dd:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01010e2:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f01010e6:	89 74 24 10          	mov    %esi,0x10(%esp)
f01010ea:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01010ed:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01010f1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01010f5:	89 04 24             	mov    %eax,(%esp)
f01010f8:	89 54 24 04          	mov    %edx,0x4(%esp)
f01010fc:	89 fa                	mov    %edi,%edx
f01010fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0101101:	e8 fa fa ff ff       	call   f0100c00 <printnum>
			break;
f0101106:	e9 88 fc ff ff       	jmp    f0100d93 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010110b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010110f:	89 04 24             	mov    %eax,(%esp)
f0101112:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101115:	e9 79 fc ff ff       	jmp    f0100d93 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010111a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010111e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101125:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101128:	89 f3                	mov    %esi,%ebx
f010112a:	eb 03                	jmp    f010112f <vprintfmt+0x3c1>
f010112c:	83 eb 01             	sub    $0x1,%ebx
f010112f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0101133:	75 f7                	jne    f010112c <vprintfmt+0x3be>
f0101135:	e9 59 fc ff ff       	jmp    f0100d93 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010113a:	83 c4 3c             	add    $0x3c,%esp
f010113d:	5b                   	pop    %ebx
f010113e:	5e                   	pop    %esi
f010113f:	5f                   	pop    %edi
f0101140:	5d                   	pop    %ebp
f0101141:	c3                   	ret    

f0101142 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101142:	55                   	push   %ebp
f0101143:	89 e5                	mov    %esp,%ebp
f0101145:	83 ec 28             	sub    $0x28,%esp
f0101148:	8b 45 08             	mov    0x8(%ebp),%eax
f010114b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010114e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101151:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101155:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101158:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010115f:	85 c0                	test   %eax,%eax
f0101161:	74 30                	je     f0101193 <vsnprintf+0x51>
f0101163:	85 d2                	test   %edx,%edx
f0101165:	7e 2c                	jle    f0101193 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101167:	8b 45 14             	mov    0x14(%ebp),%eax
f010116a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010116e:	8b 45 10             	mov    0x10(%ebp),%eax
f0101171:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101175:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101178:	89 44 24 04          	mov    %eax,0x4(%esp)
f010117c:	c7 04 24 29 0d 10 f0 	movl   $0xf0100d29,(%esp)
f0101183:	e8 e6 fb ff ff       	call   f0100d6e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101188:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010118b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010118e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101191:	eb 05                	jmp    f0101198 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101193:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101198:	c9                   	leave  
f0101199:	c3                   	ret    

f010119a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010119a:	55                   	push   %ebp
f010119b:	89 e5                	mov    %esp,%ebp
f010119d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01011a0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01011a3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011a7:	8b 45 10             	mov    0x10(%ebp),%eax
f01011aa:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011ae:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011b1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01011b8:	89 04 24             	mov    %eax,(%esp)
f01011bb:	e8 82 ff ff ff       	call   f0101142 <vsnprintf>
	va_end(ap);

	return rc;
}
f01011c0:	c9                   	leave  
f01011c1:	c3                   	ret    
f01011c2:	66 90                	xchg   %ax,%ax
f01011c4:	66 90                	xchg   %ax,%ax
f01011c6:	66 90                	xchg   %ax,%ax
f01011c8:	66 90                	xchg   %ax,%ax
f01011ca:	66 90                	xchg   %ax,%ax
f01011cc:	66 90                	xchg   %ax,%ax
f01011ce:	66 90                	xchg   %ax,%ax

f01011d0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01011d0:	55                   	push   %ebp
f01011d1:	89 e5                	mov    %esp,%ebp
f01011d3:	57                   	push   %edi
f01011d4:	56                   	push   %esi
f01011d5:	53                   	push   %ebx
f01011d6:	83 ec 1c             	sub    $0x1c,%esp
f01011d9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01011dc:	85 c0                	test   %eax,%eax
f01011de:	74 10                	je     f01011f0 <readline+0x20>
		cprintf("%s", prompt);
f01011e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011e4:	c7 04 24 e2 1d 10 f0 	movl   $0xf0101de2,(%esp)
f01011eb:	e8 31 f7 ff ff       	call   f0100921 <cprintf>

	i = 0;
	echoing = iscons(0);
f01011f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01011f7:	e8 76 f4 ff ff       	call   f0100672 <iscons>
f01011fc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01011fe:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101203:	e8 59 f4 ff ff       	call   f0100661 <getchar>
f0101208:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010120a:	85 c0                	test   %eax,%eax
f010120c:	79 17                	jns    f0101225 <readline+0x55>
			cprintf("read error: %e\n", c);
f010120e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101212:	c7 04 24 e0 1f 10 f0 	movl   $0xf0101fe0,(%esp)
f0101219:	e8 03 f7 ff ff       	call   f0100921 <cprintf>
			return NULL;
f010121e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101223:	eb 6d                	jmp    f0101292 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101225:	83 f8 7f             	cmp    $0x7f,%eax
f0101228:	74 05                	je     f010122f <readline+0x5f>
f010122a:	83 f8 08             	cmp    $0x8,%eax
f010122d:	75 19                	jne    f0101248 <readline+0x78>
f010122f:	85 f6                	test   %esi,%esi
f0101231:	7e 15                	jle    f0101248 <readline+0x78>
			if (echoing)
f0101233:	85 ff                	test   %edi,%edi
f0101235:	74 0c                	je     f0101243 <readline+0x73>
				cputchar('\b');
f0101237:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010123e:	e8 0e f4 ff ff       	call   f0100651 <cputchar>
			i--;
f0101243:	83 ee 01             	sub    $0x1,%esi
f0101246:	eb bb                	jmp    f0101203 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101248:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010124e:	7f 1c                	jg     f010126c <readline+0x9c>
f0101250:	83 fb 1f             	cmp    $0x1f,%ebx
f0101253:	7e 17                	jle    f010126c <readline+0x9c>
			if (echoing)
f0101255:	85 ff                	test   %edi,%edi
f0101257:	74 08                	je     f0101261 <readline+0x91>
				cputchar(c);
f0101259:	89 1c 24             	mov    %ebx,(%esp)
f010125c:	e8 f0 f3 ff ff       	call   f0100651 <cputchar>
			buf[i++] = c;
f0101261:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101267:	8d 76 01             	lea    0x1(%esi),%esi
f010126a:	eb 97                	jmp    f0101203 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010126c:	83 fb 0d             	cmp    $0xd,%ebx
f010126f:	74 05                	je     f0101276 <readline+0xa6>
f0101271:	83 fb 0a             	cmp    $0xa,%ebx
f0101274:	75 8d                	jne    f0101203 <readline+0x33>
			if (echoing)
f0101276:	85 ff                	test   %edi,%edi
f0101278:	74 0c                	je     f0101286 <readline+0xb6>
				cputchar('\n');
f010127a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101281:	e8 cb f3 ff ff       	call   f0100651 <cputchar>
			buf[i] = 0;
f0101286:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010128d:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101292:	83 c4 1c             	add    $0x1c,%esp
f0101295:	5b                   	pop    %ebx
f0101296:	5e                   	pop    %esi
f0101297:	5f                   	pop    %edi
f0101298:	5d                   	pop    %ebp
f0101299:	c3                   	ret    
f010129a:	66 90                	xchg   %ax,%ax
f010129c:	66 90                	xchg   %ax,%ax
f010129e:	66 90                	xchg   %ax,%ax

f01012a0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01012a0:	55                   	push   %ebp
f01012a1:	89 e5                	mov    %esp,%ebp
f01012a3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01012a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01012ab:	eb 03                	jmp    f01012b0 <strlen+0x10>
		n++;
f01012ad:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01012b0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01012b4:	75 f7                	jne    f01012ad <strlen+0xd>
		n++;
	return n;
}
f01012b6:	5d                   	pop    %ebp
f01012b7:	c3                   	ret    

f01012b8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01012b8:	55                   	push   %ebp
f01012b9:	89 e5                	mov    %esp,%ebp
f01012bb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01012be:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012c1:	b8 00 00 00 00       	mov    $0x0,%eax
f01012c6:	eb 03                	jmp    f01012cb <strnlen+0x13>
		n++;
f01012c8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012cb:	39 d0                	cmp    %edx,%eax
f01012cd:	74 06                	je     f01012d5 <strnlen+0x1d>
f01012cf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01012d3:	75 f3                	jne    f01012c8 <strnlen+0x10>
		n++;
	return n;
}
f01012d5:	5d                   	pop    %ebp
f01012d6:	c3                   	ret    

f01012d7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01012d7:	55                   	push   %ebp
f01012d8:	89 e5                	mov    %esp,%ebp
f01012da:	53                   	push   %ebx
f01012db:	8b 45 08             	mov    0x8(%ebp),%eax
f01012de:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01012e1:	89 c2                	mov    %eax,%edx
f01012e3:	83 c2 01             	add    $0x1,%edx
f01012e6:	83 c1 01             	add    $0x1,%ecx
f01012e9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01012ed:	88 5a ff             	mov    %bl,-0x1(%edx)
f01012f0:	84 db                	test   %bl,%bl
f01012f2:	75 ef                	jne    f01012e3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01012f4:	5b                   	pop    %ebx
f01012f5:	5d                   	pop    %ebp
f01012f6:	c3                   	ret    

f01012f7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01012f7:	55                   	push   %ebp
f01012f8:	89 e5                	mov    %esp,%ebp
f01012fa:	53                   	push   %ebx
f01012fb:	83 ec 08             	sub    $0x8,%esp
f01012fe:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101301:	89 1c 24             	mov    %ebx,(%esp)
f0101304:	e8 97 ff ff ff       	call   f01012a0 <strlen>
	strcpy(dst + len, src);
f0101309:	8b 55 0c             	mov    0xc(%ebp),%edx
f010130c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101310:	01 d8                	add    %ebx,%eax
f0101312:	89 04 24             	mov    %eax,(%esp)
f0101315:	e8 bd ff ff ff       	call   f01012d7 <strcpy>
	return dst;
}
f010131a:	89 d8                	mov    %ebx,%eax
f010131c:	83 c4 08             	add    $0x8,%esp
f010131f:	5b                   	pop    %ebx
f0101320:	5d                   	pop    %ebp
f0101321:	c3                   	ret    

f0101322 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101322:	55                   	push   %ebp
f0101323:	89 e5                	mov    %esp,%ebp
f0101325:	56                   	push   %esi
f0101326:	53                   	push   %ebx
f0101327:	8b 75 08             	mov    0x8(%ebp),%esi
f010132a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010132d:	89 f3                	mov    %esi,%ebx
f010132f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101332:	89 f2                	mov    %esi,%edx
f0101334:	eb 0f                	jmp    f0101345 <strncpy+0x23>
		*dst++ = *src;
f0101336:	83 c2 01             	add    $0x1,%edx
f0101339:	0f b6 01             	movzbl (%ecx),%eax
f010133c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010133f:	80 39 01             	cmpb   $0x1,(%ecx)
f0101342:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101345:	39 da                	cmp    %ebx,%edx
f0101347:	75 ed                	jne    f0101336 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101349:	89 f0                	mov    %esi,%eax
f010134b:	5b                   	pop    %ebx
f010134c:	5e                   	pop    %esi
f010134d:	5d                   	pop    %ebp
f010134e:	c3                   	ret    

f010134f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010134f:	55                   	push   %ebp
f0101350:	89 e5                	mov    %esp,%ebp
f0101352:	56                   	push   %esi
f0101353:	53                   	push   %ebx
f0101354:	8b 75 08             	mov    0x8(%ebp),%esi
f0101357:	8b 55 0c             	mov    0xc(%ebp),%edx
f010135a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010135d:	89 f0                	mov    %esi,%eax
f010135f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101363:	85 c9                	test   %ecx,%ecx
f0101365:	75 0b                	jne    f0101372 <strlcpy+0x23>
f0101367:	eb 1d                	jmp    f0101386 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101369:	83 c0 01             	add    $0x1,%eax
f010136c:	83 c2 01             	add    $0x1,%edx
f010136f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101372:	39 d8                	cmp    %ebx,%eax
f0101374:	74 0b                	je     f0101381 <strlcpy+0x32>
f0101376:	0f b6 0a             	movzbl (%edx),%ecx
f0101379:	84 c9                	test   %cl,%cl
f010137b:	75 ec                	jne    f0101369 <strlcpy+0x1a>
f010137d:	89 c2                	mov    %eax,%edx
f010137f:	eb 02                	jmp    f0101383 <strlcpy+0x34>
f0101381:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0101383:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0101386:	29 f0                	sub    %esi,%eax
}
f0101388:	5b                   	pop    %ebx
f0101389:	5e                   	pop    %esi
f010138a:	5d                   	pop    %ebp
f010138b:	c3                   	ret    

f010138c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010138c:	55                   	push   %ebp
f010138d:	89 e5                	mov    %esp,%ebp
f010138f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101392:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101395:	eb 06                	jmp    f010139d <strcmp+0x11>
		p++, q++;
f0101397:	83 c1 01             	add    $0x1,%ecx
f010139a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010139d:	0f b6 01             	movzbl (%ecx),%eax
f01013a0:	84 c0                	test   %al,%al
f01013a2:	74 04                	je     f01013a8 <strcmp+0x1c>
f01013a4:	3a 02                	cmp    (%edx),%al
f01013a6:	74 ef                	je     f0101397 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01013a8:	0f b6 c0             	movzbl %al,%eax
f01013ab:	0f b6 12             	movzbl (%edx),%edx
f01013ae:	29 d0                	sub    %edx,%eax
}
f01013b0:	5d                   	pop    %ebp
f01013b1:	c3                   	ret    

f01013b2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01013b2:	55                   	push   %ebp
f01013b3:	89 e5                	mov    %esp,%ebp
f01013b5:	53                   	push   %ebx
f01013b6:	8b 45 08             	mov    0x8(%ebp),%eax
f01013b9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013bc:	89 c3                	mov    %eax,%ebx
f01013be:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01013c1:	eb 06                	jmp    f01013c9 <strncmp+0x17>
		n--, p++, q++;
f01013c3:	83 c0 01             	add    $0x1,%eax
f01013c6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01013c9:	39 d8                	cmp    %ebx,%eax
f01013cb:	74 15                	je     f01013e2 <strncmp+0x30>
f01013cd:	0f b6 08             	movzbl (%eax),%ecx
f01013d0:	84 c9                	test   %cl,%cl
f01013d2:	74 04                	je     f01013d8 <strncmp+0x26>
f01013d4:	3a 0a                	cmp    (%edx),%cl
f01013d6:	74 eb                	je     f01013c3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01013d8:	0f b6 00             	movzbl (%eax),%eax
f01013db:	0f b6 12             	movzbl (%edx),%edx
f01013de:	29 d0                	sub    %edx,%eax
f01013e0:	eb 05                	jmp    f01013e7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01013e2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01013e7:	5b                   	pop    %ebx
f01013e8:	5d                   	pop    %ebp
f01013e9:	c3                   	ret    

f01013ea <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01013ea:	55                   	push   %ebp
f01013eb:	89 e5                	mov    %esp,%ebp
f01013ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01013f0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01013f4:	eb 07                	jmp    f01013fd <strchr+0x13>
		if (*s == c)
f01013f6:	38 ca                	cmp    %cl,%dl
f01013f8:	74 0f                	je     f0101409 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01013fa:	83 c0 01             	add    $0x1,%eax
f01013fd:	0f b6 10             	movzbl (%eax),%edx
f0101400:	84 d2                	test   %dl,%dl
f0101402:	75 f2                	jne    f01013f6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101404:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101409:	5d                   	pop    %ebp
f010140a:	c3                   	ret    

f010140b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010140b:	55                   	push   %ebp
f010140c:	89 e5                	mov    %esp,%ebp
f010140e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101411:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101415:	eb 07                	jmp    f010141e <strfind+0x13>
		if (*s == c)
f0101417:	38 ca                	cmp    %cl,%dl
f0101419:	74 0a                	je     f0101425 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010141b:	83 c0 01             	add    $0x1,%eax
f010141e:	0f b6 10             	movzbl (%eax),%edx
f0101421:	84 d2                	test   %dl,%dl
f0101423:	75 f2                	jne    f0101417 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0101425:	5d                   	pop    %ebp
f0101426:	c3                   	ret    

f0101427 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101427:	55                   	push   %ebp
f0101428:	89 e5                	mov    %esp,%ebp
f010142a:	57                   	push   %edi
f010142b:	56                   	push   %esi
f010142c:	53                   	push   %ebx
f010142d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101430:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101433:	85 c9                	test   %ecx,%ecx
f0101435:	74 36                	je     f010146d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101437:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010143d:	75 28                	jne    f0101467 <memset+0x40>
f010143f:	f6 c1 03             	test   $0x3,%cl
f0101442:	75 23                	jne    f0101467 <memset+0x40>
		c &= 0xFF;
f0101444:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101448:	89 d3                	mov    %edx,%ebx
f010144a:	c1 e3 08             	shl    $0x8,%ebx
f010144d:	89 d6                	mov    %edx,%esi
f010144f:	c1 e6 18             	shl    $0x18,%esi
f0101452:	89 d0                	mov    %edx,%eax
f0101454:	c1 e0 10             	shl    $0x10,%eax
f0101457:	09 f0                	or     %esi,%eax
f0101459:	09 c2                	or     %eax,%edx
f010145b:	89 d0                	mov    %edx,%eax
f010145d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010145f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101462:	fc                   	cld    
f0101463:	f3 ab                	rep stos %eax,%es:(%edi)
f0101465:	eb 06                	jmp    f010146d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101467:	8b 45 0c             	mov    0xc(%ebp),%eax
f010146a:	fc                   	cld    
f010146b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010146d:	89 f8                	mov    %edi,%eax
f010146f:	5b                   	pop    %ebx
f0101470:	5e                   	pop    %esi
f0101471:	5f                   	pop    %edi
f0101472:	5d                   	pop    %ebp
f0101473:	c3                   	ret    

f0101474 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101474:	55                   	push   %ebp
f0101475:	89 e5                	mov    %esp,%ebp
f0101477:	57                   	push   %edi
f0101478:	56                   	push   %esi
f0101479:	8b 45 08             	mov    0x8(%ebp),%eax
f010147c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010147f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101482:	39 c6                	cmp    %eax,%esi
f0101484:	73 35                	jae    f01014bb <memmove+0x47>
f0101486:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101489:	39 d0                	cmp    %edx,%eax
f010148b:	73 2e                	jae    f01014bb <memmove+0x47>
		s += n;
		d += n;
f010148d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0101490:	89 d6                	mov    %edx,%esi
f0101492:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101494:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010149a:	75 13                	jne    f01014af <memmove+0x3b>
f010149c:	f6 c1 03             	test   $0x3,%cl
f010149f:	75 0e                	jne    f01014af <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01014a1:	83 ef 04             	sub    $0x4,%edi
f01014a4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01014a7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01014aa:	fd                   	std    
f01014ab:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014ad:	eb 09                	jmp    f01014b8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01014af:	83 ef 01             	sub    $0x1,%edi
f01014b2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01014b5:	fd                   	std    
f01014b6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01014b8:	fc                   	cld    
f01014b9:	eb 1d                	jmp    f01014d8 <memmove+0x64>
f01014bb:	89 f2                	mov    %esi,%edx
f01014bd:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014bf:	f6 c2 03             	test   $0x3,%dl
f01014c2:	75 0f                	jne    f01014d3 <memmove+0x5f>
f01014c4:	f6 c1 03             	test   $0x3,%cl
f01014c7:	75 0a                	jne    f01014d3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01014c9:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01014cc:	89 c7                	mov    %eax,%edi
f01014ce:	fc                   	cld    
f01014cf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014d1:	eb 05                	jmp    f01014d8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01014d3:	89 c7                	mov    %eax,%edi
f01014d5:	fc                   	cld    
f01014d6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01014d8:	5e                   	pop    %esi
f01014d9:	5f                   	pop    %edi
f01014da:	5d                   	pop    %ebp
f01014db:	c3                   	ret    

f01014dc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01014dc:	55                   	push   %ebp
f01014dd:	89 e5                	mov    %esp,%ebp
f01014df:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01014e2:	8b 45 10             	mov    0x10(%ebp),%eax
f01014e5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01014e9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014ec:	89 44 24 04          	mov    %eax,0x4(%esp)
f01014f0:	8b 45 08             	mov    0x8(%ebp),%eax
f01014f3:	89 04 24             	mov    %eax,(%esp)
f01014f6:	e8 79 ff ff ff       	call   f0101474 <memmove>
}
f01014fb:	c9                   	leave  
f01014fc:	c3                   	ret    

f01014fd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01014fd:	55                   	push   %ebp
f01014fe:	89 e5                	mov    %esp,%ebp
f0101500:	56                   	push   %esi
f0101501:	53                   	push   %ebx
f0101502:	8b 55 08             	mov    0x8(%ebp),%edx
f0101505:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101508:	89 d6                	mov    %edx,%esi
f010150a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010150d:	eb 1a                	jmp    f0101529 <memcmp+0x2c>
		if (*s1 != *s2)
f010150f:	0f b6 02             	movzbl (%edx),%eax
f0101512:	0f b6 19             	movzbl (%ecx),%ebx
f0101515:	38 d8                	cmp    %bl,%al
f0101517:	74 0a                	je     f0101523 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101519:	0f b6 c0             	movzbl %al,%eax
f010151c:	0f b6 db             	movzbl %bl,%ebx
f010151f:	29 d8                	sub    %ebx,%eax
f0101521:	eb 0f                	jmp    f0101532 <memcmp+0x35>
		s1++, s2++;
f0101523:	83 c2 01             	add    $0x1,%edx
f0101526:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101529:	39 f2                	cmp    %esi,%edx
f010152b:	75 e2                	jne    f010150f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010152d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101532:	5b                   	pop    %ebx
f0101533:	5e                   	pop    %esi
f0101534:	5d                   	pop    %ebp
f0101535:	c3                   	ret    

f0101536 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101536:	55                   	push   %ebp
f0101537:	89 e5                	mov    %esp,%ebp
f0101539:	8b 45 08             	mov    0x8(%ebp),%eax
f010153c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010153f:	89 c2                	mov    %eax,%edx
f0101541:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101544:	eb 07                	jmp    f010154d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101546:	38 08                	cmp    %cl,(%eax)
f0101548:	74 07                	je     f0101551 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010154a:	83 c0 01             	add    $0x1,%eax
f010154d:	39 d0                	cmp    %edx,%eax
f010154f:	72 f5                	jb     f0101546 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101551:	5d                   	pop    %ebp
f0101552:	c3                   	ret    

f0101553 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101553:	55                   	push   %ebp
f0101554:	89 e5                	mov    %esp,%ebp
f0101556:	57                   	push   %edi
f0101557:	56                   	push   %esi
f0101558:	53                   	push   %ebx
f0101559:	8b 55 08             	mov    0x8(%ebp),%edx
f010155c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010155f:	eb 03                	jmp    f0101564 <strtol+0x11>
		s++;
f0101561:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101564:	0f b6 0a             	movzbl (%edx),%ecx
f0101567:	80 f9 09             	cmp    $0x9,%cl
f010156a:	74 f5                	je     f0101561 <strtol+0xe>
f010156c:	80 f9 20             	cmp    $0x20,%cl
f010156f:	74 f0                	je     f0101561 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101571:	80 f9 2b             	cmp    $0x2b,%cl
f0101574:	75 0a                	jne    f0101580 <strtol+0x2d>
		s++;
f0101576:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101579:	bf 00 00 00 00       	mov    $0x0,%edi
f010157e:	eb 11                	jmp    f0101591 <strtol+0x3e>
f0101580:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101585:	80 f9 2d             	cmp    $0x2d,%cl
f0101588:	75 07                	jne    f0101591 <strtol+0x3e>
		s++, neg = 1;
f010158a:	8d 52 01             	lea    0x1(%edx),%edx
f010158d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101591:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0101596:	75 15                	jne    f01015ad <strtol+0x5a>
f0101598:	80 3a 30             	cmpb   $0x30,(%edx)
f010159b:	75 10                	jne    f01015ad <strtol+0x5a>
f010159d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01015a1:	75 0a                	jne    f01015ad <strtol+0x5a>
		s += 2, base = 16;
f01015a3:	83 c2 02             	add    $0x2,%edx
f01015a6:	b8 10 00 00 00       	mov    $0x10,%eax
f01015ab:	eb 10                	jmp    f01015bd <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f01015ad:	85 c0                	test   %eax,%eax
f01015af:	75 0c                	jne    f01015bd <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01015b1:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01015b3:	80 3a 30             	cmpb   $0x30,(%edx)
f01015b6:	75 05                	jne    f01015bd <strtol+0x6a>
		s++, base = 8;
f01015b8:	83 c2 01             	add    $0x1,%edx
f01015bb:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f01015bd:	bb 00 00 00 00       	mov    $0x0,%ebx
f01015c2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01015c5:	0f b6 0a             	movzbl (%edx),%ecx
f01015c8:	8d 71 d0             	lea    -0x30(%ecx),%esi
f01015cb:	89 f0                	mov    %esi,%eax
f01015cd:	3c 09                	cmp    $0x9,%al
f01015cf:	77 08                	ja     f01015d9 <strtol+0x86>
			dig = *s - '0';
f01015d1:	0f be c9             	movsbl %cl,%ecx
f01015d4:	83 e9 30             	sub    $0x30,%ecx
f01015d7:	eb 20                	jmp    f01015f9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f01015d9:	8d 71 9f             	lea    -0x61(%ecx),%esi
f01015dc:	89 f0                	mov    %esi,%eax
f01015de:	3c 19                	cmp    $0x19,%al
f01015e0:	77 08                	ja     f01015ea <strtol+0x97>
			dig = *s - 'a' + 10;
f01015e2:	0f be c9             	movsbl %cl,%ecx
f01015e5:	83 e9 57             	sub    $0x57,%ecx
f01015e8:	eb 0f                	jmp    f01015f9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f01015ea:	8d 71 bf             	lea    -0x41(%ecx),%esi
f01015ed:	89 f0                	mov    %esi,%eax
f01015ef:	3c 19                	cmp    $0x19,%al
f01015f1:	77 16                	ja     f0101609 <strtol+0xb6>
			dig = *s - 'A' + 10;
f01015f3:	0f be c9             	movsbl %cl,%ecx
f01015f6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01015f9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f01015fc:	7d 0f                	jge    f010160d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f01015fe:	83 c2 01             	add    $0x1,%edx
f0101601:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0101605:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0101607:	eb bc                	jmp    f01015c5 <strtol+0x72>
f0101609:	89 d8                	mov    %ebx,%eax
f010160b:	eb 02                	jmp    f010160f <strtol+0xbc>
f010160d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f010160f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101613:	74 05                	je     f010161a <strtol+0xc7>
		*endptr = (char *) s;
f0101615:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101618:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f010161a:	f7 d8                	neg    %eax
f010161c:	85 ff                	test   %edi,%edi
f010161e:	0f 44 c3             	cmove  %ebx,%eax
}
f0101621:	5b                   	pop    %ebx
f0101622:	5e                   	pop    %esi
f0101623:	5f                   	pop    %edi
f0101624:	5d                   	pop    %ebp
f0101625:	c3                   	ret    
f0101626:	66 90                	xchg   %ax,%ax
f0101628:	66 90                	xchg   %ax,%ax
f010162a:	66 90                	xchg   %ax,%ax
f010162c:	66 90                	xchg   %ax,%ax
f010162e:	66 90                	xchg   %ax,%ax

f0101630 <__udivdi3>:
f0101630:	55                   	push   %ebp
f0101631:	57                   	push   %edi
f0101632:	56                   	push   %esi
f0101633:	83 ec 0c             	sub    $0xc,%esp
f0101636:	8b 44 24 28          	mov    0x28(%esp),%eax
f010163a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010163e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0101642:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101646:	85 c0                	test   %eax,%eax
f0101648:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010164c:	89 ea                	mov    %ebp,%edx
f010164e:	89 0c 24             	mov    %ecx,(%esp)
f0101651:	75 2d                	jne    f0101680 <__udivdi3+0x50>
f0101653:	39 e9                	cmp    %ebp,%ecx
f0101655:	77 61                	ja     f01016b8 <__udivdi3+0x88>
f0101657:	85 c9                	test   %ecx,%ecx
f0101659:	89 ce                	mov    %ecx,%esi
f010165b:	75 0b                	jne    f0101668 <__udivdi3+0x38>
f010165d:	b8 01 00 00 00       	mov    $0x1,%eax
f0101662:	31 d2                	xor    %edx,%edx
f0101664:	f7 f1                	div    %ecx
f0101666:	89 c6                	mov    %eax,%esi
f0101668:	31 d2                	xor    %edx,%edx
f010166a:	89 e8                	mov    %ebp,%eax
f010166c:	f7 f6                	div    %esi
f010166e:	89 c5                	mov    %eax,%ebp
f0101670:	89 f8                	mov    %edi,%eax
f0101672:	f7 f6                	div    %esi
f0101674:	89 ea                	mov    %ebp,%edx
f0101676:	83 c4 0c             	add    $0xc,%esp
f0101679:	5e                   	pop    %esi
f010167a:	5f                   	pop    %edi
f010167b:	5d                   	pop    %ebp
f010167c:	c3                   	ret    
f010167d:	8d 76 00             	lea    0x0(%esi),%esi
f0101680:	39 e8                	cmp    %ebp,%eax
f0101682:	77 24                	ja     f01016a8 <__udivdi3+0x78>
f0101684:	0f bd e8             	bsr    %eax,%ebp
f0101687:	83 f5 1f             	xor    $0x1f,%ebp
f010168a:	75 3c                	jne    f01016c8 <__udivdi3+0x98>
f010168c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101690:	39 34 24             	cmp    %esi,(%esp)
f0101693:	0f 86 9f 00 00 00    	jbe    f0101738 <__udivdi3+0x108>
f0101699:	39 d0                	cmp    %edx,%eax
f010169b:	0f 82 97 00 00 00    	jb     f0101738 <__udivdi3+0x108>
f01016a1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01016a8:	31 d2                	xor    %edx,%edx
f01016aa:	31 c0                	xor    %eax,%eax
f01016ac:	83 c4 0c             	add    $0xc,%esp
f01016af:	5e                   	pop    %esi
f01016b0:	5f                   	pop    %edi
f01016b1:	5d                   	pop    %ebp
f01016b2:	c3                   	ret    
f01016b3:	90                   	nop
f01016b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01016b8:	89 f8                	mov    %edi,%eax
f01016ba:	f7 f1                	div    %ecx
f01016bc:	31 d2                	xor    %edx,%edx
f01016be:	83 c4 0c             	add    $0xc,%esp
f01016c1:	5e                   	pop    %esi
f01016c2:	5f                   	pop    %edi
f01016c3:	5d                   	pop    %ebp
f01016c4:	c3                   	ret    
f01016c5:	8d 76 00             	lea    0x0(%esi),%esi
f01016c8:	89 e9                	mov    %ebp,%ecx
f01016ca:	8b 3c 24             	mov    (%esp),%edi
f01016cd:	d3 e0                	shl    %cl,%eax
f01016cf:	89 c6                	mov    %eax,%esi
f01016d1:	b8 20 00 00 00       	mov    $0x20,%eax
f01016d6:	29 e8                	sub    %ebp,%eax
f01016d8:	89 c1                	mov    %eax,%ecx
f01016da:	d3 ef                	shr    %cl,%edi
f01016dc:	89 e9                	mov    %ebp,%ecx
f01016de:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01016e2:	8b 3c 24             	mov    (%esp),%edi
f01016e5:	09 74 24 08          	or     %esi,0x8(%esp)
f01016e9:	89 d6                	mov    %edx,%esi
f01016eb:	d3 e7                	shl    %cl,%edi
f01016ed:	89 c1                	mov    %eax,%ecx
f01016ef:	89 3c 24             	mov    %edi,(%esp)
f01016f2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01016f6:	d3 ee                	shr    %cl,%esi
f01016f8:	89 e9                	mov    %ebp,%ecx
f01016fa:	d3 e2                	shl    %cl,%edx
f01016fc:	89 c1                	mov    %eax,%ecx
f01016fe:	d3 ef                	shr    %cl,%edi
f0101700:	09 d7                	or     %edx,%edi
f0101702:	89 f2                	mov    %esi,%edx
f0101704:	89 f8                	mov    %edi,%eax
f0101706:	f7 74 24 08          	divl   0x8(%esp)
f010170a:	89 d6                	mov    %edx,%esi
f010170c:	89 c7                	mov    %eax,%edi
f010170e:	f7 24 24             	mull   (%esp)
f0101711:	39 d6                	cmp    %edx,%esi
f0101713:	89 14 24             	mov    %edx,(%esp)
f0101716:	72 30                	jb     f0101748 <__udivdi3+0x118>
f0101718:	8b 54 24 04          	mov    0x4(%esp),%edx
f010171c:	89 e9                	mov    %ebp,%ecx
f010171e:	d3 e2                	shl    %cl,%edx
f0101720:	39 c2                	cmp    %eax,%edx
f0101722:	73 05                	jae    f0101729 <__udivdi3+0xf9>
f0101724:	3b 34 24             	cmp    (%esp),%esi
f0101727:	74 1f                	je     f0101748 <__udivdi3+0x118>
f0101729:	89 f8                	mov    %edi,%eax
f010172b:	31 d2                	xor    %edx,%edx
f010172d:	e9 7a ff ff ff       	jmp    f01016ac <__udivdi3+0x7c>
f0101732:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101738:	31 d2                	xor    %edx,%edx
f010173a:	b8 01 00 00 00       	mov    $0x1,%eax
f010173f:	e9 68 ff ff ff       	jmp    f01016ac <__udivdi3+0x7c>
f0101744:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101748:	8d 47 ff             	lea    -0x1(%edi),%eax
f010174b:	31 d2                	xor    %edx,%edx
f010174d:	83 c4 0c             	add    $0xc,%esp
f0101750:	5e                   	pop    %esi
f0101751:	5f                   	pop    %edi
f0101752:	5d                   	pop    %ebp
f0101753:	c3                   	ret    
f0101754:	66 90                	xchg   %ax,%ax
f0101756:	66 90                	xchg   %ax,%ax
f0101758:	66 90                	xchg   %ax,%ax
f010175a:	66 90                	xchg   %ax,%ax
f010175c:	66 90                	xchg   %ax,%ax
f010175e:	66 90                	xchg   %ax,%ax

f0101760 <__umoddi3>:
f0101760:	55                   	push   %ebp
f0101761:	57                   	push   %edi
f0101762:	56                   	push   %esi
f0101763:	83 ec 14             	sub    $0x14,%esp
f0101766:	8b 44 24 28          	mov    0x28(%esp),%eax
f010176a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010176e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0101772:	89 c7                	mov    %eax,%edi
f0101774:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101778:	8b 44 24 30          	mov    0x30(%esp),%eax
f010177c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101780:	89 34 24             	mov    %esi,(%esp)
f0101783:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101787:	85 c0                	test   %eax,%eax
f0101789:	89 c2                	mov    %eax,%edx
f010178b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010178f:	75 17                	jne    f01017a8 <__umoddi3+0x48>
f0101791:	39 fe                	cmp    %edi,%esi
f0101793:	76 4b                	jbe    f01017e0 <__umoddi3+0x80>
f0101795:	89 c8                	mov    %ecx,%eax
f0101797:	89 fa                	mov    %edi,%edx
f0101799:	f7 f6                	div    %esi
f010179b:	89 d0                	mov    %edx,%eax
f010179d:	31 d2                	xor    %edx,%edx
f010179f:	83 c4 14             	add    $0x14,%esp
f01017a2:	5e                   	pop    %esi
f01017a3:	5f                   	pop    %edi
f01017a4:	5d                   	pop    %ebp
f01017a5:	c3                   	ret    
f01017a6:	66 90                	xchg   %ax,%ax
f01017a8:	39 f8                	cmp    %edi,%eax
f01017aa:	77 54                	ja     f0101800 <__umoddi3+0xa0>
f01017ac:	0f bd e8             	bsr    %eax,%ebp
f01017af:	83 f5 1f             	xor    $0x1f,%ebp
f01017b2:	75 5c                	jne    f0101810 <__umoddi3+0xb0>
f01017b4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f01017b8:	39 3c 24             	cmp    %edi,(%esp)
f01017bb:	0f 87 e7 00 00 00    	ja     f01018a8 <__umoddi3+0x148>
f01017c1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01017c5:	29 f1                	sub    %esi,%ecx
f01017c7:	19 c7                	sbb    %eax,%edi
f01017c9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01017cd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01017d1:	8b 44 24 08          	mov    0x8(%esp),%eax
f01017d5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01017d9:	83 c4 14             	add    $0x14,%esp
f01017dc:	5e                   	pop    %esi
f01017dd:	5f                   	pop    %edi
f01017de:	5d                   	pop    %ebp
f01017df:	c3                   	ret    
f01017e0:	85 f6                	test   %esi,%esi
f01017e2:	89 f5                	mov    %esi,%ebp
f01017e4:	75 0b                	jne    f01017f1 <__umoddi3+0x91>
f01017e6:	b8 01 00 00 00       	mov    $0x1,%eax
f01017eb:	31 d2                	xor    %edx,%edx
f01017ed:	f7 f6                	div    %esi
f01017ef:	89 c5                	mov    %eax,%ebp
f01017f1:	8b 44 24 04          	mov    0x4(%esp),%eax
f01017f5:	31 d2                	xor    %edx,%edx
f01017f7:	f7 f5                	div    %ebp
f01017f9:	89 c8                	mov    %ecx,%eax
f01017fb:	f7 f5                	div    %ebp
f01017fd:	eb 9c                	jmp    f010179b <__umoddi3+0x3b>
f01017ff:	90                   	nop
f0101800:	89 c8                	mov    %ecx,%eax
f0101802:	89 fa                	mov    %edi,%edx
f0101804:	83 c4 14             	add    $0x14,%esp
f0101807:	5e                   	pop    %esi
f0101808:	5f                   	pop    %edi
f0101809:	5d                   	pop    %ebp
f010180a:	c3                   	ret    
f010180b:	90                   	nop
f010180c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101810:	8b 04 24             	mov    (%esp),%eax
f0101813:	be 20 00 00 00       	mov    $0x20,%esi
f0101818:	89 e9                	mov    %ebp,%ecx
f010181a:	29 ee                	sub    %ebp,%esi
f010181c:	d3 e2                	shl    %cl,%edx
f010181e:	89 f1                	mov    %esi,%ecx
f0101820:	d3 e8                	shr    %cl,%eax
f0101822:	89 e9                	mov    %ebp,%ecx
f0101824:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101828:	8b 04 24             	mov    (%esp),%eax
f010182b:	09 54 24 04          	or     %edx,0x4(%esp)
f010182f:	89 fa                	mov    %edi,%edx
f0101831:	d3 e0                	shl    %cl,%eax
f0101833:	89 f1                	mov    %esi,%ecx
f0101835:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101839:	8b 44 24 10          	mov    0x10(%esp),%eax
f010183d:	d3 ea                	shr    %cl,%edx
f010183f:	89 e9                	mov    %ebp,%ecx
f0101841:	d3 e7                	shl    %cl,%edi
f0101843:	89 f1                	mov    %esi,%ecx
f0101845:	d3 e8                	shr    %cl,%eax
f0101847:	89 e9                	mov    %ebp,%ecx
f0101849:	09 f8                	or     %edi,%eax
f010184b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010184f:	f7 74 24 04          	divl   0x4(%esp)
f0101853:	d3 e7                	shl    %cl,%edi
f0101855:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101859:	89 d7                	mov    %edx,%edi
f010185b:	f7 64 24 08          	mull   0x8(%esp)
f010185f:	39 d7                	cmp    %edx,%edi
f0101861:	89 c1                	mov    %eax,%ecx
f0101863:	89 14 24             	mov    %edx,(%esp)
f0101866:	72 2c                	jb     f0101894 <__umoddi3+0x134>
f0101868:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010186c:	72 22                	jb     f0101890 <__umoddi3+0x130>
f010186e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101872:	29 c8                	sub    %ecx,%eax
f0101874:	19 d7                	sbb    %edx,%edi
f0101876:	89 e9                	mov    %ebp,%ecx
f0101878:	89 fa                	mov    %edi,%edx
f010187a:	d3 e8                	shr    %cl,%eax
f010187c:	89 f1                	mov    %esi,%ecx
f010187e:	d3 e2                	shl    %cl,%edx
f0101880:	89 e9                	mov    %ebp,%ecx
f0101882:	d3 ef                	shr    %cl,%edi
f0101884:	09 d0                	or     %edx,%eax
f0101886:	89 fa                	mov    %edi,%edx
f0101888:	83 c4 14             	add    $0x14,%esp
f010188b:	5e                   	pop    %esi
f010188c:	5f                   	pop    %edi
f010188d:	5d                   	pop    %ebp
f010188e:	c3                   	ret    
f010188f:	90                   	nop
f0101890:	39 d7                	cmp    %edx,%edi
f0101892:	75 da                	jne    f010186e <__umoddi3+0x10e>
f0101894:	8b 14 24             	mov    (%esp),%edx
f0101897:	89 c1                	mov    %eax,%ecx
f0101899:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f010189d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f01018a1:	eb cb                	jmp    f010186e <__umoddi3+0x10e>
f01018a3:	90                   	nop
f01018a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018a8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f01018ac:	0f 82 0f ff ff ff    	jb     f01017c1 <__umoddi3+0x61>
f01018b2:	e9 1a ff ff ff       	jmp    f01017d1 <__umoddi3+0x71>
