
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
f0100015:	b8 00 30 11 00       	mov    $0x113000,%eax
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
f0100034:	bc 00 30 11 f0       	mov    $0xf0113000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/kclock.h>

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
f010004e:	c7 04 24 a0 2a 10 f0 	movl   $0xf0102aa0,(%esp)
f0100055:	e8 4d 1a 00 00       	call   f0101aa7 <cprintf>
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
f0100082:	e8 54 07 00 00       	call   f01007db <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 bc 2a 10 f0 	movl   $0xf0102abc,(%esp)
f0100092:	e8 10 1a 00 00       	call   f0101aa7 <cprintf>
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
f01000a3:	b8 70 59 11 f0       	mov    $0xf0115970,%eax
f01000a8:	2d 00 53 11 f0       	sub    $0xf0115300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 53 11 f0 	movl   $0xf0115300,(%esp)
f01000c0:	e8 42 25 00 00       	call   f0102607 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 c5 04 00 00       	call   f010058f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 d7 2a 10 f0 	movl   $0xf0102ad7,(%esp)
f01000d9:	e8 c9 19 00 00       	call   f0101aa7 <cprintf>
	mem_init();
f01000de:	e8 43 11 00 00       	call   f0101226 <mem_init>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000e3:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000ea:	e8 51 ff ff ff       	call   f0100040 <test_backtrace>
	int x = 1, y = 3, z = 4;
	cprintf("x %d, y %x, z %d\n", x, y, z);
f01000ef:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f01000f6:	00 
f01000f7:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
f01000fe:	00 
f01000ff:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0100106:	00 
f0100107:	c7 04 24 f2 2a 10 f0 	movl   $0xf0102af2,(%esp)
f010010e:	e8 94 19 00 00       	call   f0101aa7 <cprintf>
	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100113:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010011a:	e8 56 07 00 00       	call   f0100875 <monitor>
f010011f:	eb f2                	jmp    f0100113 <i386_init+0x76>

f0100121 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100121:	55                   	push   %ebp
f0100122:	89 e5                	mov    %esp,%ebp
f0100124:	56                   	push   %esi
f0100125:	53                   	push   %ebx
f0100126:	83 ec 10             	sub    $0x10,%esp
f0100129:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010012c:	83 3d 60 59 11 f0 00 	cmpl   $0x0,0xf0115960
f0100133:	75 3d                	jne    f0100172 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f0100135:	89 35 60 59 11 f0    	mov    %esi,0xf0115960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f010013b:	fa                   	cli    
f010013c:	fc                   	cld    

	va_start(ap, fmt);
f010013d:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100140:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100143:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100147:	8b 45 08             	mov    0x8(%ebp),%eax
f010014a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010014e:	c7 04 24 04 2b 10 f0 	movl   $0xf0102b04,(%esp)
f0100155:	e8 4d 19 00 00       	call   f0101aa7 <cprintf>
	vcprintf(fmt, ap);
f010015a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010015e:	89 34 24             	mov    %esi,(%esp)
f0100161:	e8 0e 19 00 00       	call   f0101a74 <vcprintf>
	cprintf("\n");
f0100166:	c7 04 24 40 2b 10 f0 	movl   $0xf0102b40,(%esp)
f010016d:	e8 35 19 00 00       	call   f0101aa7 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100172:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100179:	e8 f7 06 00 00       	call   f0100875 <monitor>
f010017e:	eb f2                	jmp    f0100172 <_panic+0x51>

f0100180 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100180:	55                   	push   %ebp
f0100181:	89 e5                	mov    %esp,%ebp
f0100183:	53                   	push   %ebx
f0100184:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f0100187:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f010018a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010018d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100191:	8b 45 08             	mov    0x8(%ebp),%eax
f0100194:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100198:	c7 04 24 1c 2b 10 f0 	movl   $0xf0102b1c,(%esp)
f010019f:	e8 03 19 00 00       	call   f0101aa7 <cprintf>
	vcprintf(fmt, ap);
f01001a4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01001a8:	8b 45 10             	mov    0x10(%ebp),%eax
f01001ab:	89 04 24             	mov    %eax,(%esp)
f01001ae:	e8 c1 18 00 00       	call   f0101a74 <vcprintf>
	cprintf("\n");
f01001b3:	c7 04 24 40 2b 10 f0 	movl   $0xf0102b40,(%esp)
f01001ba:	e8 e8 18 00 00       	call   f0101aa7 <cprintf>
	va_end(ap);
}
f01001bf:	83 c4 14             	add    $0x14,%esp
f01001c2:	5b                   	pop    %ebx
f01001c3:	5d                   	pop    %ebp
f01001c4:	c3                   	ret    
f01001c5:	66 90                	xchg   %ax,%ax
f01001c7:	66 90                	xchg   %ax,%ax
f01001c9:	66 90                	xchg   %ax,%ax
f01001cb:	66 90                	xchg   %ax,%ax
f01001cd:	66 90                	xchg   %ax,%ax
f01001cf:	90                   	nop

f01001d0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001d0:	55                   	push   %ebp
f01001d1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001d3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001d8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001d9:	a8 01                	test   $0x1,%al
f01001db:	74 08                	je     f01001e5 <serial_proc_data+0x15>
f01001dd:	b2 f8                	mov    $0xf8,%dl
f01001df:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001e0:	0f b6 c0             	movzbl %al,%eax
f01001e3:	eb 05                	jmp    f01001ea <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001ea:	5d                   	pop    %ebp
f01001eb:	c3                   	ret    

f01001ec <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001ec:	55                   	push   %ebp
f01001ed:	89 e5                	mov    %esp,%ebp
f01001ef:	53                   	push   %ebx
f01001f0:	83 ec 04             	sub    $0x4,%esp
f01001f3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001f5:	eb 2a                	jmp    f0100221 <cons_intr+0x35>
		if (c == 0)
f01001f7:	85 d2                	test   %edx,%edx
f01001f9:	74 26                	je     f0100221 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001fb:	a1 24 55 11 f0       	mov    0xf0115524,%eax
f0100200:	8d 48 01             	lea    0x1(%eax),%ecx
f0100203:	89 0d 24 55 11 f0    	mov    %ecx,0xf0115524
f0100209:	88 90 20 53 11 f0    	mov    %dl,-0xfeeace0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010020f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100215:	75 0a                	jne    f0100221 <cons_intr+0x35>
			cons.wpos = 0;
f0100217:	c7 05 24 55 11 f0 00 	movl   $0x0,0xf0115524
f010021e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100221:	ff d3                	call   *%ebx
f0100223:	89 c2                	mov    %eax,%edx
f0100225:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100228:	75 cd                	jne    f01001f7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010022a:	83 c4 04             	add    $0x4,%esp
f010022d:	5b                   	pop    %ebx
f010022e:	5d                   	pop    %ebp
f010022f:	c3                   	ret    

f0100230 <kbd_proc_data>:
f0100230:	ba 64 00 00 00       	mov    $0x64,%edx
f0100235:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100236:	a8 01                	test   $0x1,%al
f0100238:	0f 84 ef 00 00 00    	je     f010032d <kbd_proc_data+0xfd>
f010023e:	b2 60                	mov    $0x60,%dl
f0100240:	ec                   	in     (%dx),%al
f0100241:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100243:	3c e0                	cmp    $0xe0,%al
f0100245:	75 0d                	jne    f0100254 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100247:	83 0d 00 53 11 f0 40 	orl    $0x40,0xf0115300
		return 0;
f010024e:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100253:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100254:	55                   	push   %ebp
f0100255:	89 e5                	mov    %esp,%ebp
f0100257:	53                   	push   %ebx
f0100258:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010025b:	84 c0                	test   %al,%al
f010025d:	79 37                	jns    f0100296 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010025f:	8b 0d 00 53 11 f0    	mov    0xf0115300,%ecx
f0100265:	89 cb                	mov    %ecx,%ebx
f0100267:	83 e3 40             	and    $0x40,%ebx
f010026a:	83 e0 7f             	and    $0x7f,%eax
f010026d:	85 db                	test   %ebx,%ebx
f010026f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100272:	0f b6 d2             	movzbl %dl,%edx
f0100275:	0f b6 82 80 2c 10 f0 	movzbl -0xfefd380(%edx),%eax
f010027c:	83 c8 40             	or     $0x40,%eax
f010027f:	0f b6 c0             	movzbl %al,%eax
f0100282:	f7 d0                	not    %eax
f0100284:	21 c1                	and    %eax,%ecx
f0100286:	89 0d 00 53 11 f0    	mov    %ecx,0xf0115300
		return 0;
f010028c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100291:	e9 9d 00 00 00       	jmp    f0100333 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100296:	8b 0d 00 53 11 f0    	mov    0xf0115300,%ecx
f010029c:	f6 c1 40             	test   $0x40,%cl
f010029f:	74 0e                	je     f01002af <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01002a1:	83 c8 80             	or     $0xffffff80,%eax
f01002a4:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01002a6:	83 e1 bf             	and    $0xffffffbf,%ecx
f01002a9:	89 0d 00 53 11 f0    	mov    %ecx,0xf0115300
	}

	shift |= shiftcode[data];
f01002af:	0f b6 d2             	movzbl %dl,%edx
f01002b2:	0f b6 82 80 2c 10 f0 	movzbl -0xfefd380(%edx),%eax
f01002b9:	0b 05 00 53 11 f0    	or     0xf0115300,%eax
	shift ^= togglecode[data];
f01002bf:	0f b6 8a 80 2b 10 f0 	movzbl -0xfefd480(%edx),%ecx
f01002c6:	31 c8                	xor    %ecx,%eax
f01002c8:	a3 00 53 11 f0       	mov    %eax,0xf0115300

	c = charcode[shift & (CTL | SHIFT)][data];
f01002cd:	89 c1                	mov    %eax,%ecx
f01002cf:	83 e1 03             	and    $0x3,%ecx
f01002d2:	8b 0c 8d 60 2b 10 f0 	mov    -0xfefd4a0(,%ecx,4),%ecx
f01002d9:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002dd:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002e0:	a8 08                	test   $0x8,%al
f01002e2:	74 1b                	je     f01002ff <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01002e4:	89 da                	mov    %ebx,%edx
f01002e6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002e9:	83 f9 19             	cmp    $0x19,%ecx
f01002ec:	77 05                	ja     f01002f3 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f01002ee:	83 eb 20             	sub    $0x20,%ebx
f01002f1:	eb 0c                	jmp    f01002ff <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f01002f3:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002f6:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002f9:	83 fa 19             	cmp    $0x19,%edx
f01002fc:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002ff:	f7 d0                	not    %eax
f0100301:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100303:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100305:	f6 c2 06             	test   $0x6,%dl
f0100308:	75 29                	jne    f0100333 <kbd_proc_data+0x103>
f010030a:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100310:	75 21                	jne    f0100333 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f0100312:	c7 04 24 36 2b 10 f0 	movl   $0xf0102b36,(%esp)
f0100319:	e8 89 17 00 00       	call   f0101aa7 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010031e:	ba 92 00 00 00       	mov    $0x92,%edx
f0100323:	b8 03 00 00 00       	mov    $0x3,%eax
f0100328:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100329:	89 d8                	mov    %ebx,%eax
f010032b:	eb 06                	jmp    f0100333 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010032d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100332:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100333:	83 c4 14             	add    $0x14,%esp
f0100336:	5b                   	pop    %ebx
f0100337:	5d                   	pop    %ebp
f0100338:	c3                   	ret    

f0100339 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100339:	55                   	push   %ebp
f010033a:	89 e5                	mov    %esp,%ebp
f010033c:	57                   	push   %edi
f010033d:	56                   	push   %esi
f010033e:	53                   	push   %ebx
f010033f:	83 ec 1c             	sub    $0x1c,%esp
f0100342:	89 c7                	mov    %eax,%edi
f0100344:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100349:	be fd 03 00 00       	mov    $0x3fd,%esi
f010034e:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100353:	eb 06                	jmp    f010035b <cons_putc+0x22>
f0100355:	89 ca                	mov    %ecx,%edx
f0100357:	ec                   	in     (%dx),%al
f0100358:	ec                   	in     (%dx),%al
f0100359:	ec                   	in     (%dx),%al
f010035a:	ec                   	in     (%dx),%al
f010035b:	89 f2                	mov    %esi,%edx
f010035d:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010035e:	a8 20                	test   $0x20,%al
f0100360:	75 05                	jne    f0100367 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100362:	83 eb 01             	sub    $0x1,%ebx
f0100365:	75 ee                	jne    f0100355 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100367:	89 f8                	mov    %edi,%eax
f0100369:	0f b6 c0             	movzbl %al,%eax
f010036c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010036f:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100374:	ee                   	out    %al,(%dx)
f0100375:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010037a:	be 79 03 00 00       	mov    $0x379,%esi
f010037f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100384:	eb 06                	jmp    f010038c <cons_putc+0x53>
f0100386:	89 ca                	mov    %ecx,%edx
f0100388:	ec                   	in     (%dx),%al
f0100389:	ec                   	in     (%dx),%al
f010038a:	ec                   	in     (%dx),%al
f010038b:	ec                   	in     (%dx),%al
f010038c:	89 f2                	mov    %esi,%edx
f010038e:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010038f:	84 c0                	test   %al,%al
f0100391:	78 05                	js     f0100398 <cons_putc+0x5f>
f0100393:	83 eb 01             	sub    $0x1,%ebx
f0100396:	75 ee                	jne    f0100386 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100398:	ba 78 03 00 00       	mov    $0x378,%edx
f010039d:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f01003a1:	ee                   	out    %al,(%dx)
f01003a2:	b2 7a                	mov    $0x7a,%dl
f01003a4:	b8 0d 00 00 00       	mov    $0xd,%eax
f01003a9:	ee                   	out    %al,(%dx)
f01003aa:	b8 08 00 00 00       	mov    $0x8,%eax
f01003af:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f01003b0:	89 fa                	mov    %edi,%edx
f01003b2:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f01003b8:	89 f8                	mov    %edi,%eax
f01003ba:	80 cc 07             	or     $0x7,%ah
f01003bd:	85 d2                	test   %edx,%edx
f01003bf:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f01003c2:	89 f8                	mov    %edi,%eax
f01003c4:	0f b6 c0             	movzbl %al,%eax
f01003c7:	83 f8 09             	cmp    $0x9,%eax
f01003ca:	74 76                	je     f0100442 <cons_putc+0x109>
f01003cc:	83 f8 09             	cmp    $0x9,%eax
f01003cf:	7f 0a                	jg     f01003db <cons_putc+0xa2>
f01003d1:	83 f8 08             	cmp    $0x8,%eax
f01003d4:	74 16                	je     f01003ec <cons_putc+0xb3>
f01003d6:	e9 9b 00 00 00       	jmp    f0100476 <cons_putc+0x13d>
f01003db:	83 f8 0a             	cmp    $0xa,%eax
f01003de:	66 90                	xchg   %ax,%ax
f01003e0:	74 3a                	je     f010041c <cons_putc+0xe3>
f01003e2:	83 f8 0d             	cmp    $0xd,%eax
f01003e5:	74 3d                	je     f0100424 <cons_putc+0xeb>
f01003e7:	e9 8a 00 00 00       	jmp    f0100476 <cons_putc+0x13d>
	case '\b':
		if (crt_pos > 0) {
f01003ec:	0f b7 05 28 55 11 f0 	movzwl 0xf0115528,%eax
f01003f3:	66 85 c0             	test   %ax,%ax
f01003f6:	0f 84 e5 00 00 00    	je     f01004e1 <cons_putc+0x1a8>
			crt_pos--;
f01003fc:	83 e8 01             	sub    $0x1,%eax
f01003ff:	66 a3 28 55 11 f0    	mov    %ax,0xf0115528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100405:	0f b7 c0             	movzwl %ax,%eax
f0100408:	66 81 e7 00 ff       	and    $0xff00,%di
f010040d:	83 cf 20             	or     $0x20,%edi
f0100410:	8b 15 2c 55 11 f0    	mov    0xf011552c,%edx
f0100416:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010041a:	eb 78                	jmp    f0100494 <cons_putc+0x15b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010041c:	66 83 05 28 55 11 f0 	addw   $0x50,0xf0115528
f0100423:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100424:	0f b7 05 28 55 11 f0 	movzwl 0xf0115528,%eax
f010042b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100431:	c1 e8 16             	shr    $0x16,%eax
f0100434:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100437:	c1 e0 04             	shl    $0x4,%eax
f010043a:	66 a3 28 55 11 f0    	mov    %ax,0xf0115528
f0100440:	eb 52                	jmp    f0100494 <cons_putc+0x15b>
		break;
	case '\t':
		cons_putc(' ');
f0100442:	b8 20 00 00 00       	mov    $0x20,%eax
f0100447:	e8 ed fe ff ff       	call   f0100339 <cons_putc>
		cons_putc(' ');
f010044c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100451:	e8 e3 fe ff ff       	call   f0100339 <cons_putc>
		cons_putc(' ');
f0100456:	b8 20 00 00 00       	mov    $0x20,%eax
f010045b:	e8 d9 fe ff ff       	call   f0100339 <cons_putc>
		cons_putc(' ');
f0100460:	b8 20 00 00 00       	mov    $0x20,%eax
f0100465:	e8 cf fe ff ff       	call   f0100339 <cons_putc>
		cons_putc(' ');
f010046a:	b8 20 00 00 00       	mov    $0x20,%eax
f010046f:	e8 c5 fe ff ff       	call   f0100339 <cons_putc>
f0100474:	eb 1e                	jmp    f0100494 <cons_putc+0x15b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100476:	0f b7 05 28 55 11 f0 	movzwl 0xf0115528,%eax
f010047d:	8d 50 01             	lea    0x1(%eax),%edx
f0100480:	66 89 15 28 55 11 f0 	mov    %dx,0xf0115528
f0100487:	0f b7 c0             	movzwl %ax,%eax
f010048a:	8b 15 2c 55 11 f0    	mov    0xf011552c,%edx
f0100490:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100494:	66 81 3d 28 55 11 f0 	cmpw   $0x7cf,0xf0115528
f010049b:	cf 07 
f010049d:	76 42                	jbe    f01004e1 <cons_putc+0x1a8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010049f:	a1 2c 55 11 f0       	mov    0xf011552c,%eax
f01004a4:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f01004ab:	00 
f01004ac:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004b2:	89 54 24 04          	mov    %edx,0x4(%esp)
f01004b6:	89 04 24             	mov    %eax,(%esp)
f01004b9:	e8 96 21 00 00       	call   f0102654 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01004be:	8b 15 2c 55 11 f0    	mov    0xf011552c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004c4:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01004c9:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004cf:	83 c0 01             	add    $0x1,%eax
f01004d2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01004d7:	75 f0                	jne    f01004c9 <cons_putc+0x190>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004d9:	66 83 2d 28 55 11 f0 	subw   $0x50,0xf0115528
f01004e0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004e1:	8b 0d 30 55 11 f0    	mov    0xf0115530,%ecx
f01004e7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004ec:	89 ca                	mov    %ecx,%edx
f01004ee:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004ef:	0f b7 1d 28 55 11 f0 	movzwl 0xf0115528,%ebx
f01004f6:	8d 71 01             	lea    0x1(%ecx),%esi
f01004f9:	89 d8                	mov    %ebx,%eax
f01004fb:	66 c1 e8 08          	shr    $0x8,%ax
f01004ff:	89 f2                	mov    %esi,%edx
f0100501:	ee                   	out    %al,(%dx)
f0100502:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100507:	89 ca                	mov    %ecx,%edx
f0100509:	ee                   	out    %al,(%dx)
f010050a:	89 d8                	mov    %ebx,%eax
f010050c:	89 f2                	mov    %esi,%edx
f010050e:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010050f:	83 c4 1c             	add    $0x1c,%esp
f0100512:	5b                   	pop    %ebx
f0100513:	5e                   	pop    %esi
f0100514:	5f                   	pop    %edi
f0100515:	5d                   	pop    %ebp
f0100516:	c3                   	ret    

f0100517 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100517:	80 3d 34 55 11 f0 00 	cmpb   $0x0,0xf0115534
f010051e:	74 11                	je     f0100531 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100520:	55                   	push   %ebp
f0100521:	89 e5                	mov    %esp,%ebp
f0100523:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100526:	b8 d0 01 10 f0       	mov    $0xf01001d0,%eax
f010052b:	e8 bc fc ff ff       	call   f01001ec <cons_intr>
}
f0100530:	c9                   	leave  
f0100531:	f3 c3                	repz ret 

f0100533 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100533:	55                   	push   %ebp
f0100534:	89 e5                	mov    %esp,%ebp
f0100536:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100539:	b8 30 02 10 f0       	mov    $0xf0100230,%eax
f010053e:	e8 a9 fc ff ff       	call   f01001ec <cons_intr>
}
f0100543:	c9                   	leave  
f0100544:	c3                   	ret    

f0100545 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100545:	55                   	push   %ebp
f0100546:	89 e5                	mov    %esp,%ebp
f0100548:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010054b:	e8 c7 ff ff ff       	call   f0100517 <serial_intr>
	kbd_intr();
f0100550:	e8 de ff ff ff       	call   f0100533 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100555:	a1 20 55 11 f0       	mov    0xf0115520,%eax
f010055a:	3b 05 24 55 11 f0    	cmp    0xf0115524,%eax
f0100560:	74 26                	je     f0100588 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100562:	8d 50 01             	lea    0x1(%eax),%edx
f0100565:	89 15 20 55 11 f0    	mov    %edx,0xf0115520
f010056b:	0f b6 88 20 53 11 f0 	movzbl -0xfeeace0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100572:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100574:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010057a:	75 11                	jne    f010058d <cons_getc+0x48>
			cons.rpos = 0;
f010057c:	c7 05 20 55 11 f0 00 	movl   $0x0,0xf0115520
f0100583:	00 00 00 
f0100586:	eb 05                	jmp    f010058d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100588:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010058d:	c9                   	leave  
f010058e:	c3                   	ret    

f010058f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010058f:	55                   	push   %ebp
f0100590:	89 e5                	mov    %esp,%ebp
f0100592:	57                   	push   %edi
f0100593:	56                   	push   %esi
f0100594:	53                   	push   %ebx
f0100595:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100598:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010059f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01005a6:	5a a5 
	if (*cp != 0xA55A) {
f01005a8:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01005af:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005b3:	74 11                	je     f01005c6 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01005b5:	c7 05 30 55 11 f0 b4 	movl   $0x3b4,0xf0115530
f01005bc:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005bf:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01005c4:	eb 16                	jmp    f01005dc <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005c6:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005cd:	c7 05 30 55 11 f0 d4 	movl   $0x3d4,0xf0115530
f01005d4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005d7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005dc:	8b 0d 30 55 11 f0    	mov    0xf0115530,%ecx
f01005e2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005e7:	89 ca                	mov    %ecx,%edx
f01005e9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ea:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005ed:	89 da                	mov    %ebx,%edx
f01005ef:	ec                   	in     (%dx),%al
f01005f0:	0f b6 f0             	movzbl %al,%esi
f01005f3:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005f6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005fb:	89 ca                	mov    %ecx,%edx
f01005fd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005fe:	89 da                	mov    %ebx,%edx
f0100600:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100601:	89 3d 2c 55 11 f0    	mov    %edi,0xf011552c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100607:	0f b6 d8             	movzbl %al,%ebx
f010060a:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f010060c:	66 89 35 28 55 11 f0 	mov    %si,0xf0115528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100613:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100618:	b8 00 00 00 00       	mov    $0x0,%eax
f010061d:	89 f2                	mov    %esi,%edx
f010061f:	ee                   	out    %al,(%dx)
f0100620:	b2 fb                	mov    $0xfb,%dl
f0100622:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100627:	ee                   	out    %al,(%dx)
f0100628:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010062d:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100632:	89 da                	mov    %ebx,%edx
f0100634:	ee                   	out    %al,(%dx)
f0100635:	b2 f9                	mov    $0xf9,%dl
f0100637:	b8 00 00 00 00       	mov    $0x0,%eax
f010063c:	ee                   	out    %al,(%dx)
f010063d:	b2 fb                	mov    $0xfb,%dl
f010063f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100644:	ee                   	out    %al,(%dx)
f0100645:	b2 fc                	mov    $0xfc,%dl
f0100647:	b8 00 00 00 00       	mov    $0x0,%eax
f010064c:	ee                   	out    %al,(%dx)
f010064d:	b2 f9                	mov    $0xf9,%dl
f010064f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100654:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100655:	b2 fd                	mov    $0xfd,%dl
f0100657:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100658:	3c ff                	cmp    $0xff,%al
f010065a:	0f 95 c1             	setne  %cl
f010065d:	88 0d 34 55 11 f0    	mov    %cl,0xf0115534
f0100663:	89 f2                	mov    %esi,%edx
f0100665:	ec                   	in     (%dx),%al
f0100666:	89 da                	mov    %ebx,%edx
f0100668:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100669:	84 c9                	test   %cl,%cl
f010066b:	75 0c                	jne    f0100679 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f010066d:	c7 04 24 42 2b 10 f0 	movl   $0xf0102b42,(%esp)
f0100674:	e8 2e 14 00 00       	call   f0101aa7 <cprintf>
}
f0100679:	83 c4 1c             	add    $0x1c,%esp
f010067c:	5b                   	pop    %ebx
f010067d:	5e                   	pop    %esi
f010067e:	5f                   	pop    %edi
f010067f:	5d                   	pop    %ebp
f0100680:	c3                   	ret    

f0100681 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100681:	55                   	push   %ebp
f0100682:	89 e5                	mov    %esp,%ebp
f0100684:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100687:	8b 45 08             	mov    0x8(%ebp),%eax
f010068a:	e8 aa fc ff ff       	call   f0100339 <cons_putc>
}
f010068f:	c9                   	leave  
f0100690:	c3                   	ret    

f0100691 <getchar>:

int
getchar(void)
{
f0100691:	55                   	push   %ebp
f0100692:	89 e5                	mov    %esp,%ebp
f0100694:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100697:	e8 a9 fe ff ff       	call   f0100545 <cons_getc>
f010069c:	85 c0                	test   %eax,%eax
f010069e:	74 f7                	je     f0100697 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01006a0:	c9                   	leave  
f01006a1:	c3                   	ret    

f01006a2 <iscons>:

int
iscons(int fdnum)
{
f01006a2:	55                   	push   %ebp
f01006a3:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01006a5:	b8 01 00 00 00       	mov    $0x1,%eax
f01006aa:	5d                   	pop    %ebp
f01006ab:	c3                   	ret    
f01006ac:	66 90                	xchg   %ax,%ax
f01006ae:	66 90                	xchg   %ax,%ax

f01006b0 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006b0:	55                   	push   %ebp
f01006b1:	89 e5                	mov    %esp,%ebp
f01006b3:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006b6:	c7 44 24 08 80 2d 10 	movl   $0xf0102d80,0x8(%esp)
f01006bd:	f0 
f01006be:	c7 44 24 04 9e 2d 10 	movl   $0xf0102d9e,0x4(%esp)
f01006c5:	f0 
f01006c6:	c7 04 24 a3 2d 10 f0 	movl   $0xf0102da3,(%esp)
f01006cd:	e8 d5 13 00 00       	call   f0101aa7 <cprintf>
f01006d2:	c7 44 24 08 44 2e 10 	movl   $0xf0102e44,0x8(%esp)
f01006d9:	f0 
f01006da:	c7 44 24 04 ac 2d 10 	movl   $0xf0102dac,0x4(%esp)
f01006e1:	f0 
f01006e2:	c7 04 24 a3 2d 10 f0 	movl   $0xf0102da3,(%esp)
f01006e9:	e8 b9 13 00 00       	call   f0101aa7 <cprintf>
f01006ee:	c7 44 24 08 b5 2d 10 	movl   $0xf0102db5,0x8(%esp)
f01006f5:	f0 
f01006f6:	c7 44 24 04 d2 2d 10 	movl   $0xf0102dd2,0x4(%esp)
f01006fd:	f0 
f01006fe:	c7 04 24 a3 2d 10 f0 	movl   $0xf0102da3,(%esp)
f0100705:	e8 9d 13 00 00       	call   f0101aa7 <cprintf>
	return 0;
}
f010070a:	b8 00 00 00 00       	mov    $0x0,%eax
f010070f:	c9                   	leave  
f0100710:	c3                   	ret    

f0100711 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100711:	55                   	push   %ebp
f0100712:	89 e5                	mov    %esp,%ebp
f0100714:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100717:	c7 04 24 dd 2d 10 f0 	movl   $0xf0102ddd,(%esp)
f010071e:	e8 84 13 00 00       	call   f0101aa7 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100723:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010072a:	00 
f010072b:	c7 04 24 6c 2e 10 f0 	movl   $0xf0102e6c,(%esp)
f0100732:	e8 70 13 00 00       	call   f0101aa7 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100737:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010073e:	00 
f010073f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100746:	f0 
f0100747:	c7 04 24 94 2e 10 f0 	movl   $0xf0102e94,(%esp)
f010074e:	e8 54 13 00 00       	call   f0101aa7 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100753:	c7 44 24 08 97 2a 10 	movl   $0x102a97,0x8(%esp)
f010075a:	00 
f010075b:	c7 44 24 04 97 2a 10 	movl   $0xf0102a97,0x4(%esp)
f0100762:	f0 
f0100763:	c7 04 24 b8 2e 10 f0 	movl   $0xf0102eb8,(%esp)
f010076a:	e8 38 13 00 00       	call   f0101aa7 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010076f:	c7 44 24 08 00 53 11 	movl   $0x115300,0x8(%esp)
f0100776:	00 
f0100777:	c7 44 24 04 00 53 11 	movl   $0xf0115300,0x4(%esp)
f010077e:	f0 
f010077f:	c7 04 24 dc 2e 10 f0 	movl   $0xf0102edc,(%esp)
f0100786:	e8 1c 13 00 00       	call   f0101aa7 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010078b:	c7 44 24 08 70 59 11 	movl   $0x115970,0x8(%esp)
f0100792:	00 
f0100793:	c7 44 24 04 70 59 11 	movl   $0xf0115970,0x4(%esp)
f010079a:	f0 
f010079b:	c7 04 24 00 2f 10 f0 	movl   $0xf0102f00,(%esp)
f01007a2:	e8 00 13 00 00       	call   f0101aa7 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01007a7:	b8 6f 5d 11 f0       	mov    $0xf0115d6f,%eax
f01007ac:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01007b1:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007b6:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01007bc:	85 c0                	test   %eax,%eax
f01007be:	0f 48 c2             	cmovs  %edx,%eax
f01007c1:	c1 f8 0a             	sar    $0xa,%eax
f01007c4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007c8:	c7 04 24 24 2f 10 f0 	movl   $0xf0102f24,(%esp)
f01007cf:	e8 d3 12 00 00       	call   f0101aa7 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01007d4:	b8 00 00 00 00       	mov    $0x0,%eax
f01007d9:	c9                   	leave  
f01007da:	c3                   	ret    

f01007db <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007db:	55                   	push   %ebp
f01007dc:	89 e5                	mov    %esp,%ebp
f01007de:	57                   	push   %edi
f01007df:	56                   	push   %esi
f01007e0:	53                   	push   %ebx
f01007e1:	83 ec 6c             	sub    $0x6c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01007e4:	89 eb                	mov    %ebp,%ebx
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
f01007e6:	c7 04 24 f6 2d 10 f0 	movl   $0xf0102df6,(%esp)
f01007ed:	e8 b5 12 00 00       	call   f0101aa7 <cprintf>
	
	while (ebp){
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
		debuginfo_eip(eip, &sym);
f01007f2:	8d 7d d0             	lea    -0x30(%ebp),%edi
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f01007f5:	eb 6d                	jmp    f0100864 <mon_backtrace+0x89>
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
f01007f7:	8b 73 04             	mov    0x4(%ebx),%esi
		debuginfo_eip(eip, &sym);
f01007fa:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01007fe:	89 34 24             	mov    %esi,(%esp)
f0100801:	e8 98 13 00 00       	call   f0101b9e <debuginfo_eip>
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n %s:%d: %.*s+%d\n",ebp,eip,
f0100806:	89 f0                	mov    %esi,%eax
f0100808:	2b 45 e0             	sub    -0x20(%ebp),%eax
f010080b:	89 44 24 30          	mov    %eax,0x30(%esp)
f010080f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100812:	89 44 24 2c          	mov    %eax,0x2c(%esp)
f0100816:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100819:	89 44 24 28          	mov    %eax,0x28(%esp)
f010081d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100820:	89 44 24 24          	mov    %eax,0x24(%esp)
f0100824:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100827:	89 44 24 20          	mov    %eax,0x20(%esp)
f010082b:	8b 43 18             	mov    0x18(%ebx),%eax
f010082e:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f0100832:	8b 43 14             	mov    0x14(%ebx),%eax
f0100835:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100839:	8b 43 10             	mov    0x10(%ebx),%eax
f010083c:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100840:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100843:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100847:	8b 43 08             	mov    0x8(%ebx),%eax
f010084a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010084e:	89 74 24 08          	mov    %esi,0x8(%esp)
f0100852:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100856:	c7 04 24 50 2f 10 f0 	movl   $0xf0102f50,(%esp)
f010085d:	e8 45 12 00 00       	call   f0101aa7 <cprintf>
		*((uint32_t *)ebp + 6), sym.eip_file,
			      sym.eip_line,
			      sym.eip_fn_namelen,
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
f0100862:	8b 1b                	mov    (%ebx),%ebx
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f0100864:	85 db                	test   %ebx,%ebx
f0100866:	75 8f                	jne    f01007f7 <mon_backtrace+0x1c>
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
	}
	return 0;
}
f0100868:	b8 00 00 00 00       	mov    $0x0,%eax
f010086d:	83 c4 6c             	add    $0x6c,%esp
f0100870:	5b                   	pop    %ebx
f0100871:	5e                   	pop    %esi
f0100872:	5f                   	pop    %edi
f0100873:	5d                   	pop    %ebp
f0100874:	c3                   	ret    

f0100875 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100875:	55                   	push   %ebp
f0100876:	89 e5                	mov    %esp,%ebp
f0100878:	57                   	push   %edi
f0100879:	56                   	push   %esi
f010087a:	53                   	push   %ebx
f010087b:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010087e:	c7 04 24 94 2f 10 f0 	movl   $0xf0102f94,(%esp)
f0100885:	e8 1d 12 00 00       	call   f0101aa7 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010088a:	c7 04 24 b8 2f 10 f0 	movl   $0xf0102fb8,(%esp)
f0100891:	e8 11 12 00 00       	call   f0101aa7 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100896:	c7 04 24 08 2e 10 f0 	movl   $0xf0102e08,(%esp)
f010089d:	e8 0e 1b 00 00       	call   f01023b0 <readline>
f01008a2:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01008a4:	85 c0                	test   %eax,%eax
f01008a6:	74 ee                	je     f0100896 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008a8:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008af:	be 00 00 00 00       	mov    $0x0,%esi
f01008b4:	eb 0a                	jmp    f01008c0 <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008b6:	c6 03 00             	movb   $0x0,(%ebx)
f01008b9:	89 f7                	mov    %esi,%edi
f01008bb:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01008be:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008c0:	0f b6 03             	movzbl (%ebx),%eax
f01008c3:	84 c0                	test   %al,%al
f01008c5:	74 63                	je     f010092a <monitor+0xb5>
f01008c7:	0f be c0             	movsbl %al,%eax
f01008ca:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008ce:	c7 04 24 0c 2e 10 f0 	movl   $0xf0102e0c,(%esp)
f01008d5:	e8 f0 1c 00 00       	call   f01025ca <strchr>
f01008da:	85 c0                	test   %eax,%eax
f01008dc:	75 d8                	jne    f01008b6 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f01008de:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008e1:	74 47                	je     f010092a <monitor+0xb5>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008e3:	83 fe 0f             	cmp    $0xf,%esi
f01008e6:	75 16                	jne    f01008fe <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008e8:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008ef:	00 
f01008f0:	c7 04 24 11 2e 10 f0 	movl   $0xf0102e11,(%esp)
f01008f7:	e8 ab 11 00 00       	call   f0101aa7 <cprintf>
f01008fc:	eb 98                	jmp    f0100896 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f01008fe:	8d 7e 01             	lea    0x1(%esi),%edi
f0100901:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100905:	eb 03                	jmp    f010090a <monitor+0x95>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100907:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010090a:	0f b6 03             	movzbl (%ebx),%eax
f010090d:	84 c0                	test   %al,%al
f010090f:	74 ad                	je     f01008be <monitor+0x49>
f0100911:	0f be c0             	movsbl %al,%eax
f0100914:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100918:	c7 04 24 0c 2e 10 f0 	movl   $0xf0102e0c,(%esp)
f010091f:	e8 a6 1c 00 00       	call   f01025ca <strchr>
f0100924:	85 c0                	test   %eax,%eax
f0100926:	74 df                	je     f0100907 <monitor+0x92>
f0100928:	eb 94                	jmp    f01008be <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f010092a:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100931:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100932:	85 f6                	test   %esi,%esi
f0100934:	0f 84 5c ff ff ff    	je     f0100896 <monitor+0x21>
f010093a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010093f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100942:	8b 04 85 e0 2f 10 f0 	mov    -0xfefd020(,%eax,4),%eax
f0100949:	89 44 24 04          	mov    %eax,0x4(%esp)
f010094d:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100950:	89 04 24             	mov    %eax,(%esp)
f0100953:	e8 14 1c 00 00       	call   f010256c <strcmp>
f0100958:	85 c0                	test   %eax,%eax
f010095a:	75 24                	jne    f0100980 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f010095c:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010095f:	8b 55 08             	mov    0x8(%ebp),%edx
f0100962:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100966:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100969:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010096d:	89 34 24             	mov    %esi,(%esp)
f0100970:	ff 14 85 e8 2f 10 f0 	call   *-0xfefd018(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100977:	85 c0                	test   %eax,%eax
f0100979:	78 25                	js     f01009a0 <monitor+0x12b>
f010097b:	e9 16 ff ff ff       	jmp    f0100896 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100980:	83 c3 01             	add    $0x1,%ebx
f0100983:	83 fb 03             	cmp    $0x3,%ebx
f0100986:	75 b7                	jne    f010093f <monitor+0xca>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100988:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010098b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010098f:	c7 04 24 2e 2e 10 f0 	movl   $0xf0102e2e,(%esp)
f0100996:	e8 0c 11 00 00       	call   f0101aa7 <cprintf>
f010099b:	e9 f6 fe ff ff       	jmp    f0100896 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01009a0:	83 c4 5c             	add    $0x5c,%esp
f01009a3:	5b                   	pop    %ebx
f01009a4:	5e                   	pop    %esi
f01009a5:	5f                   	pop    %edi
f01009a6:	5d                   	pop    %ebp
f01009a7:	c3                   	ret    

f01009a8 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f01009a8:	89 d1                	mov    %edx,%ecx
f01009aa:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f01009ad:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f01009b0:	a8 01                	test   $0x1,%al
f01009b2:	74 5d                	je     f0100a11 <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f01009b4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009b9:	89 c1                	mov    %eax,%ecx
f01009bb:	c1 e9 0c             	shr    $0xc,%ecx
f01009be:	3b 0d 64 59 11 f0    	cmp    0xf0115964,%ecx
f01009c4:	72 26                	jb     f01009ec <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01009c6:	55                   	push   %ebp
f01009c7:	89 e5                	mov    %esp,%ebp
f01009c9:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009cc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009d0:	c7 44 24 08 04 30 10 	movl   $0xf0103004,0x8(%esp)
f01009d7:	f0 
f01009d8:	c7 44 24 04 18 03 00 	movl   $0x318,0x4(%esp)
f01009df:	00 
f01009e0:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f01009e7:	e8 35 f7 ff ff       	call   f0100121 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f01009ec:	c1 ea 0c             	shr    $0xc,%edx
f01009ef:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009f5:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01009fc:	89 c2                	mov    %eax,%edx
f01009fe:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a01:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a06:	85 d2                	test   %edx,%edx
f0100a08:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a0d:	0f 44 c2             	cmove  %edx,%eax
f0100a10:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100a11:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100a16:	c3                   	ret    

f0100a17 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100a17:	83 3d 3c 55 11 f0 00 	cmpl   $0x0,0xf011553c
f0100a1e:	75 11                	jne    f0100a31 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE); // Roundup function rounds according to the given functions
f0100a20:	ba 6f 69 11 f0       	mov    $0xf011696f,%edx
f0100a25:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a2b:	89 15 3c 55 11 f0    	mov    %edx,0xf011553c
	}
	
	if (n==0){
f0100a31:	85 c0                	test   %eax,%eax
f0100a33:	75 06                	jne    f0100a3b <boot_alloc+0x24>
	return nextfree;
f0100a35:	a1 3c 55 11 f0       	mov    0xf011553c,%eax
f0100a3a:	c3                   	ret    
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result  = nextfree;
f0100a3b:	8b 0d 3c 55 11 f0    	mov    0xf011553c,%ecx
	nextfree += ROUNDUP(n,PGSIZE);
f0100a41:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100a47:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a4d:	01 ca                	add    %ecx,%edx
f0100a4f:	89 15 3c 55 11 f0    	mov    %edx,0xf011553c
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100a55:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0100a5b:	77 26                	ja     f0100a83 <boot_alloc+0x6c>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100a5d:	55                   	push   %ebp
f0100a5e:	89 e5                	mov    %esp,%ebp
f0100a60:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100a63:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100a67:	c7 44 24 08 28 30 10 	movl   $0xf0103028,0x8(%esp)
f0100a6e:	f0 
f0100a6f:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
f0100a76:	00 
f0100a77:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0100a7e:	e8 9e f6 ff ff       	call   f0100121 <_panic>
	// LAB 2: Your code here.
	result  = nextfree;
	nextfree += ROUNDUP(n,PGSIZE);
	
	
	if ((PADDR(nextfree))>npages*PGSIZE){
f0100a83:	a1 64 59 11 f0       	mov    0xf0115964,%eax
f0100a88:	c1 e0 0c             	shl    $0xc,%eax
	return (physaddr_t)kva - KERNBASE;
f0100a8b:	81 c2 00 00 00 10    	add    $0x10000000,%edx
		return 0;
f0100a91:	39 c2                	cmp    %eax,%edx
f0100a93:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a98:	0f 46 c1             	cmovbe %ecx,%eax
	}
	return result;
}
f0100a9b:	c3                   	ret    

f0100a9c <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a9c:	55                   	push   %ebp
f0100a9d:	89 e5                	mov    %esp,%ebp
f0100a9f:	57                   	push   %edi
f0100aa0:	56                   	push   %esi
f0100aa1:	53                   	push   %ebx
f0100aa2:	83 ec 4c             	sub    $0x4c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100aa5:	84 c0                	test   %al,%al
f0100aa7:	0f 85 07 03 00 00    	jne    f0100db4 <check_page_free_list+0x318>
f0100aad:	e9 14 03 00 00       	jmp    f0100dc6 <check_page_free_list+0x32a>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100ab2:	c7 44 24 08 4c 30 10 	movl   $0xf010304c,0x8(%esp)
f0100ab9:	f0 
f0100aba:	c7 44 24 04 5b 02 00 	movl   $0x25b,0x4(%esp)
f0100ac1:	00 
f0100ac2:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0100ac9:	e8 53 f6 ff ff       	call   f0100121 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100ace:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100ad1:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100ad4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ad7:	89 55 e4             	mov    %edx,-0x1c(%ebp)

//page2pa returns the relevant physical address of the page
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ada:	89 c2                	mov    %eax,%edx
f0100adc:	2b 15 6c 59 11 f0    	sub    0xf011596c,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ae2:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100ae8:	0f 95 c2             	setne  %dl
f0100aeb:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100aee:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100af2:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100af4:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100af8:	8b 00                	mov    (%eax),%eax
f0100afa:	85 c0                	test   %eax,%eax
f0100afc:	75 dc                	jne    f0100ada <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100afe:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b01:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100b07:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b0a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100b0d:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100b0f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100b12:	a3 40 55 11 f0       	mov    %eax,0xf0115540
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b17:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b1c:	8b 1d 40 55 11 f0    	mov    0xf0115540,%ebx
f0100b22:	eb 63                	jmp    f0100b87 <check_page_free_list+0xeb>
f0100b24:	89 d8                	mov    %ebx,%eax
f0100b26:	2b 05 6c 59 11 f0    	sub    0xf011596c,%eax
f0100b2c:	c1 f8 03             	sar    $0x3,%eax
f0100b2f:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b32:	89 c2                	mov    %eax,%edx
f0100b34:	c1 ea 16             	shr    $0x16,%edx
f0100b37:	39 f2                	cmp    %esi,%edx
f0100b39:	73 4a                	jae    f0100b85 <check_page_free_list+0xe9>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b3b:	89 c2                	mov    %eax,%edx
f0100b3d:	c1 ea 0c             	shr    $0xc,%edx
f0100b40:	3b 15 64 59 11 f0    	cmp    0xf0115964,%edx
f0100b46:	72 20                	jb     f0100b68 <check_page_free_list+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b48:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b4c:	c7 44 24 08 04 30 10 	movl   $0xf0103004,0x8(%esp)
f0100b53:	f0 
f0100b54:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100b5b:	00 
f0100b5c:	c7 04 24 08 33 10 f0 	movl   $0xf0103308,(%esp)
f0100b63:	e8 b9 f5 ff ff       	call   f0100121 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b68:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b6f:	00 
f0100b70:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b77:	00 
	return (void *)(pa + KERNBASE);
f0100b78:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b7d:	89 04 24             	mov    %eax,(%esp)
f0100b80:	e8 82 1a 00 00       	call   f0102607 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b85:	8b 1b                	mov    (%ebx),%ebx
f0100b87:	85 db                	test   %ebx,%ebx
f0100b89:	75 99                	jne    f0100b24 <check_page_free_list+0x88>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b8b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b90:	e8 82 fe ff ff       	call   f0100a17 <boot_alloc>
f0100b95:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b98:	8b 15 40 55 11 f0    	mov    0xf0115540,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b9e:	8b 0d 6c 59 11 f0    	mov    0xf011596c,%ecx
		assert(pp < pages + npages);
f0100ba4:	a1 64 59 11 f0       	mov    0xf0115964,%eax
f0100ba9:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100bac:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100baf:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bb2:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100bb5:	bf 00 00 00 00       	mov    $0x0,%edi
f0100bba:	89 5d cc             	mov    %ebx,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bbd:	e9 97 01 00 00       	jmp    f0100d59 <check_page_free_list+0x2bd>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bc2:	39 ca                	cmp    %ecx,%edx
f0100bc4:	73 24                	jae    f0100bea <check_page_free_list+0x14e>
f0100bc6:	c7 44 24 0c 16 33 10 	movl   $0xf0103316,0xc(%esp)
f0100bcd:	f0 
f0100bce:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f0100bd5:	f0 
f0100bd6:	c7 44 24 04 75 02 00 	movl   $0x275,0x4(%esp)
f0100bdd:	00 
f0100bde:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0100be5:	e8 37 f5 ff ff       	call   f0100121 <_panic>
		assert(pp < pages + npages);
f0100bea:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bed:	72 24                	jb     f0100c13 <check_page_free_list+0x177>
f0100bef:	c7 44 24 0c 37 33 10 	movl   $0xf0103337,0xc(%esp)
f0100bf6:	f0 
f0100bf7:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f0100bfe:	f0 
f0100bff:	c7 44 24 04 76 02 00 	movl   $0x276,0x4(%esp)
f0100c06:	00 
f0100c07:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0100c0e:	e8 0e f5 ff ff       	call   f0100121 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c13:	89 d0                	mov    %edx,%eax
f0100c15:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c18:	a8 07                	test   $0x7,%al
f0100c1a:	74 24                	je     f0100c40 <check_page_free_list+0x1a4>
f0100c1c:	c7 44 24 0c 70 30 10 	movl   $0xf0103070,0xc(%esp)
f0100c23:	f0 
f0100c24:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f0100c2b:	f0 
f0100c2c:	c7 44 24 04 77 02 00 	movl   $0x277,0x4(%esp)
f0100c33:	00 
f0100c34:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0100c3b:	e8 e1 f4 ff ff       	call   f0100121 <_panic>

//page2pa returns the relevant physical address of the page
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c40:	c1 f8 03             	sar    $0x3,%eax
f0100c43:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c46:	85 c0                	test   %eax,%eax
f0100c48:	75 24                	jne    f0100c6e <check_page_free_list+0x1d2>
f0100c4a:	c7 44 24 0c 4b 33 10 	movl   $0xf010334b,0xc(%esp)
f0100c51:	f0 
f0100c52:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f0100c59:	f0 
f0100c5a:	c7 44 24 04 7a 02 00 	movl   $0x27a,0x4(%esp)
f0100c61:	00 
f0100c62:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0100c69:	e8 b3 f4 ff ff       	call   f0100121 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c6e:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c73:	75 24                	jne    f0100c99 <check_page_free_list+0x1fd>
f0100c75:	c7 44 24 0c 5c 33 10 	movl   $0xf010335c,0xc(%esp)
f0100c7c:	f0 
f0100c7d:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f0100c84:	f0 
f0100c85:	c7 44 24 04 7b 02 00 	movl   $0x27b,0x4(%esp)
f0100c8c:	00 
f0100c8d:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0100c94:	e8 88 f4 ff ff       	call   f0100121 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c99:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c9e:	75 24                	jne    f0100cc4 <check_page_free_list+0x228>
f0100ca0:	c7 44 24 0c a4 30 10 	movl   $0xf01030a4,0xc(%esp)
f0100ca7:	f0 
f0100ca8:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f0100caf:	f0 
f0100cb0:	c7 44 24 04 7c 02 00 	movl   $0x27c,0x4(%esp)
f0100cb7:	00 
f0100cb8:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0100cbf:	e8 5d f4 ff ff       	call   f0100121 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cc4:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cc9:	75 24                	jne    f0100cef <check_page_free_list+0x253>
f0100ccb:	c7 44 24 0c 75 33 10 	movl   $0xf0103375,0xc(%esp)
f0100cd2:	f0 
f0100cd3:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f0100cda:	f0 
f0100cdb:	c7 44 24 04 7d 02 00 	movl   $0x27d,0x4(%esp)
f0100ce2:	00 
f0100ce3:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0100cea:	e8 32 f4 ff ff       	call   f0100121 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cef:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100cf4:	76 58                	jbe    f0100d4e <check_page_free_list+0x2b2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cf6:	89 c3                	mov    %eax,%ebx
f0100cf8:	c1 eb 0c             	shr    $0xc,%ebx
f0100cfb:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f0100cfe:	77 20                	ja     f0100d20 <check_page_free_list+0x284>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d00:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d04:	c7 44 24 08 04 30 10 	movl   $0xf0103004,0x8(%esp)
f0100d0b:	f0 
f0100d0c:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100d13:	00 
f0100d14:	c7 04 24 08 33 10 f0 	movl   $0xf0103308,(%esp)
f0100d1b:	e8 01 f4 ff ff       	call   f0100121 <_panic>
	return (void *)(pa + KERNBASE);
f0100d20:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d25:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100d28:	76 2a                	jbe    f0100d54 <check_page_free_list+0x2b8>
f0100d2a:	c7 44 24 0c c8 30 10 	movl   $0xf01030c8,0xc(%esp)
f0100d31:	f0 
f0100d32:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f0100d39:	f0 
f0100d3a:	c7 44 24 04 7e 02 00 	movl   $0x27e,0x4(%esp)
f0100d41:	00 
f0100d42:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0100d49:	e8 d3 f3 ff ff       	call   f0100121 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d4e:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0100d52:	eb 03                	jmp    f0100d57 <check_page_free_list+0x2bb>
		else
			++nfree_extmem;
f0100d54:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d57:	8b 12                	mov    (%edx),%edx
f0100d59:	85 d2                	test   %edx,%edx
f0100d5b:	0f 85 61 fe ff ff    	jne    f0100bc2 <check_page_free_list+0x126>
f0100d61:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d64:	85 db                	test   %ebx,%ebx
f0100d66:	7f 24                	jg     f0100d8c <check_page_free_list+0x2f0>
f0100d68:	c7 44 24 0c 8f 33 10 	movl   $0xf010338f,0xc(%esp)
f0100d6f:	f0 
f0100d70:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f0100d77:	f0 
f0100d78:	c7 44 24 04 86 02 00 	movl   $0x286,0x4(%esp)
f0100d7f:	00 
f0100d80:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0100d87:	e8 95 f3 ff ff       	call   f0100121 <_panic>
	assert(nfree_extmem > 0);
f0100d8c:	85 ff                	test   %edi,%edi
f0100d8e:	7f 4d                	jg     f0100ddd <check_page_free_list+0x341>
f0100d90:	c7 44 24 0c a1 33 10 	movl   $0xf01033a1,0xc(%esp)
f0100d97:	f0 
f0100d98:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f0100d9f:	f0 
f0100da0:	c7 44 24 04 87 02 00 	movl   $0x287,0x4(%esp)
f0100da7:	00 
f0100da8:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0100daf:	e8 6d f3 ff ff       	call   f0100121 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100db4:	a1 40 55 11 f0       	mov    0xf0115540,%eax
f0100db9:	85 c0                	test   %eax,%eax
f0100dbb:	0f 85 0d fd ff ff    	jne    f0100ace <check_page_free_list+0x32>
f0100dc1:	e9 ec fc ff ff       	jmp    f0100ab2 <check_page_free_list+0x16>
f0100dc6:	83 3d 40 55 11 f0 00 	cmpl   $0x0,0xf0115540
f0100dcd:	0f 84 df fc ff ff    	je     f0100ab2 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100dd3:	be 00 04 00 00       	mov    $0x400,%esi
f0100dd8:	e9 3f fd ff ff       	jmp    f0100b1c <check_page_free_list+0x80>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100ddd:	83 c4 4c             	add    $0x4c,%esp
f0100de0:	5b                   	pop    %ebx
f0100de1:	5e                   	pop    %esi
f0100de2:	5f                   	pop    %edi
f0100de3:	5d                   	pop    %ebp
f0100de4:	c3                   	ret    

f0100de5 <page_init>:
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100de5:	b8 01 00 00 00       	mov    $0x1,%eax
f0100dea:	eb 18                	jmp    f0100e04 <page_init+0x1f>
	{
	 pages[i].pp_ref = 1; //Used Pages
f0100dec:	8b 15 6c 59 11 f0    	mov    0xf011596c,%edx
f0100df2:	8d 14 c2             	lea    (%edx,%eax,8),%edx
f0100df5:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
	 pages[i].pp_link = 0; // No links to any pages
f0100dfb:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100e01:	83 c0 01             	add    $0x1,%eax
f0100e04:	3b 05 64 59 11 f0    	cmp    0xf0115964,%eax
f0100e0a:	72 e0                	jb     f0100dec <page_init+0x7>
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100e0c:	55                   	push   %ebp
f0100e0d:	89 e5                	mov    %esp,%ebp
f0100e0f:	57                   	push   %edi
f0100e10:	56                   	push   %esi
f0100e11:	53                   	push   %ebx
f0100e12:	83 ec 1c             	sub    $0x1c,%esp

	
	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	for (i = 1; i < npages_basemem; i++) {
f0100e15:	8b 35 44 55 11 f0    	mov    0xf0115544,%esi
f0100e1b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e20:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100e25:	eb 39                	jmp    f0100e60 <page_init+0x7b>
f0100e27:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
		pages[i].pp_ref = 0;
f0100e2e:	8b 15 6c 59 11 f0    	mov    0xf011596c,%edx
f0100e34:	66 c7 44 02 04 00 00 	movw   $0x0,0x4(%edx,%eax,1)
		pages[i].pp_link = 0;
f0100e3b:	c7 04 da 00 00 00 00 	movl   $0x0,(%edx,%ebx,8)

		if (!page_free_list){		
f0100e42:	85 c9                	test   %ecx,%ecx
f0100e44:	75 0a                	jne    f0100e50 <page_init+0x6b>
		page_free_list = &pages[i];	// if page_free_list is 0 then point to current page
f0100e46:	03 05 6c 59 11 f0    	add    0xf011596c,%eax
f0100e4c:	89 c1                	mov    %eax,%ecx
f0100e4e:	eb 0d                	jmp    f0100e5d <page_init+0x78>
		}
		else{
		pages[i-1].pp_link = &pages[i];
f0100e50:	8b 15 6c 59 11 f0    	mov    0xf011596c,%edx
f0100e56:	8d 3c 02             	lea    (%edx,%eax,1),%edi
f0100e59:	89 7c 02 f8          	mov    %edi,-0x8(%edx,%eax,1)

	
	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	for (i = 1; i < npages_basemem; i++) {
f0100e5d:	83 c3 01             	add    $0x1,%ebx
f0100e60:	39 f3                	cmp    %esi,%ebx
f0100e62:	72 c3                	jb     f0100e27 <page_init+0x42>
f0100e64:	89 0d 40 55 11 f0    	mov    %ecx,0xf0115540
		}
		else{
		pages[i-1].pp_link = &pages[i];
		}	//Previous page is linked to this current page
	}
	cprintf("After for loop 1 value of i = %d\n", i);
f0100e6a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100e6e:	c7 04 24 10 31 10 f0 	movl   $0xf0103110,(%esp)
f0100e75:	e8 2d 0c 00 00       	call   f0101aa7 <cprintf>
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
f0100e7a:	a1 6c 59 11 f0       	mov    0xf011596c,%eax
f0100e7f:	8d 44 d8 f8          	lea    -0x8(%eax,%ebx,8),%eax
f0100e83:	a3 38 55 11 f0       	mov    %eax,0xf0115538
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100e88:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e8d:	e8 85 fb ff ff       	call   f0100a17 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100e92:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100e97:	77 20                	ja     f0100eb9 <page_init+0xd4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100e99:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e9d:	c7 44 24 08 28 30 10 	movl   $0xf0103028,0x8(%esp)
f0100ea4:	f0 
f0100ea5:	c7 44 24 04 26 01 00 	movl   $0x126,0x4(%esp)
f0100eac:	00 
f0100ead:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0100eb4:	e8 68 f2 ff ff       	call   f0100121 <_panic>
f0100eb9:	05 ff 0f 00 10       	add    $0x10000fff,%eax
f0100ebe:	c1 e8 0c             	shr    $0xc,%eax
f0100ec1:	8b 1d 38 55 11 f0    	mov    0xf0115538,%ebx
f0100ec7:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100ece:	eb 2c                	jmp    f0100efc <page_init+0x117>
		pages[i].pp_ref = 0;
f0100ed0:	89 d1                	mov    %edx,%ecx
f0100ed2:	03 0d 6c 59 11 f0    	add    0xf011596c,%ecx
f0100ed8:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = 0;
f0100ede:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		track->pp_link = &pages[i];
f0100ee4:	89 d1                	mov    %edx,%ecx
f0100ee6:	03 0d 6c 59 11 f0    	add    0xf011596c,%ecx
f0100eec:	89 0b                	mov    %ecx,(%ebx)
		track = &pages[i];
f0100eee:	89 d3                	mov    %edx,%ebx
f0100ef0:	03 1d 6c 59 11 f0    	add    0xf011596c,%ebx
	}
	cprintf("After for loop 1 value of i = %d\n", i);
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100ef6:	83 c0 01             	add    $0x1,%eax
f0100ef9:	83 c2 08             	add    $0x8,%edx
f0100efc:	3b 05 64 59 11 f0    	cmp    0xf0115964,%eax
f0100f02:	72 cc                	jb     f0100ed0 <page_init+0xeb>
f0100f04:	89 1d 38 55 11 f0    	mov    %ebx,0xf0115538
		pages[i].pp_link = 0;
		track->pp_link = &pages[i];
		track = &pages[i];
	}
	
	cprintf("Check first entry of pages &pages[0] = %x\n", &pages[0]);
f0100f0a:	a1 6c 59 11 f0       	mov    0xf011596c,%eax
f0100f0f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f13:	c7 04 24 34 31 10 f0 	movl   $0xf0103134,(%esp)
f0100f1a:	e8 88 0b 00 00       	call   f0101aa7 <cprintf>
	cprintf("&pages[npages-1] = %x\n", &pages[npages-1]);
f0100f1f:	a1 6c 59 11 f0       	mov    0xf011596c,%eax
f0100f24:	8b 15 64 59 11 f0    	mov    0xf0115964,%edx
f0100f2a:	8d 44 d0 f8          	lea    -0x8(%eax,%edx,8),%eax
f0100f2e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f32:	c7 04 24 b2 33 10 f0 	movl   $0xf01033b2,(%esp)
f0100f39:	e8 69 0b 00 00       	call   f0101aa7 <cprintf>
}
f0100f3e:	83 c4 1c             	add    $0x1c,%esp
f0100f41:	5b                   	pop    %ebx
f0100f42:	5e                   	pop    %esi
f0100f43:	5f                   	pop    %edi
f0100f44:	5d                   	pop    %ebp
f0100f45:	c3                   	ret    

f0100f46 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100f46:	55                   	push   %ebp
f0100f47:	89 e5                	mov    %esp,%ebp
f0100f49:	53                   	push   %ebx
f0100f4a:	83 ec 14             	sub    $0x14,%esp
	// Check if there is a free_page available 
	if (!page_free_list)
f0100f4d:	8b 1d 40 55 11 f0    	mov    0xf0115540,%ebx
f0100f53:	85 db                	test   %ebx,%ebx
f0100f55:	74 6f                	je     f0100fc6 <page_alloc+0x80>
	return NULL;
	}
	
	struct PageInfo *allocPage = NULL;   //Create a temporary pointer 
	allocPage = page_free_list;	//Point to the current head of free_page_list
	page_free_list = allocPage ->pp_link; //Move the head to the next avaialble page
f0100f57:	8b 03                	mov    (%ebx),%eax
f0100f59:	a3 40 55 11 f0       	mov    %eax,0xf0115540

	if (alloc_flags && ALLOC_ZERO){		//ALLOC_ZERO = 1<<0; which is nothing but  = 1
f0100f5e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100f62:	74 58                	je     f0100fbc <page_alloc+0x76>

//page2pa returns the relevant physical address of the page
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f64:	89 d8                	mov    %ebx,%eax
f0100f66:	2b 05 6c 59 11 f0    	sub    0xf011596c,%eax
f0100f6c:	c1 f8 03             	sar    $0x3,%eax
f0100f6f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f72:	89 c2                	mov    %eax,%edx
f0100f74:	c1 ea 0c             	shr    $0xc,%edx
f0100f77:	3b 15 64 59 11 f0    	cmp    0xf0115964,%edx
f0100f7d:	72 20                	jb     f0100f9f <page_alloc+0x59>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f7f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f83:	c7 44 24 08 04 30 10 	movl   $0xf0103004,0x8(%esp)
f0100f8a:	f0 
f0100f8b:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100f92:	00 
f0100f93:	c7 04 24 08 33 10 f0 	movl   $0xf0103308,(%esp)
f0100f9a:	e8 82 f1 ff ff       	call   f0100121 <_panic>
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
f0100f9f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100fa6:	00 
f0100fa7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100fae:	00 
	return (void *)(pa + KERNBASE);
f0100faf:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100fb4:	89 04 24             	mov    %eax,(%esp)
f0100fb7:	e8 4b 16 00 00       	call   f0102607 <memset>
	}
	
	allocPage->pp_ref = 0;
f0100fbc:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return allocPage;
f0100fc2:	89 d8                	mov    %ebx,%eax
f0100fc4:	eb 05                	jmp    f0100fcb <page_alloc+0x85>
page_alloc(int alloc_flags)
{
	// Check if there is a free_page available 
	if (!page_free_list)
	{ 
	return NULL;
f0100fc6:	b8 00 00 00 00       	mov    $0x0,%eax
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
	}
	
	allocPage->pp_ref = 0;
	return allocPage;
}
f0100fcb:	83 c4 14             	add    $0x14,%esp
f0100fce:	5b                   	pop    %ebx
f0100fcf:	5d                   	pop    %ebp
f0100fd0:	c3                   	ret    

f0100fd1 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100fd1:	55                   	push   %ebp
f0100fd2:	89 e5                	mov    %esp,%ebp
f0100fd4:	83 ec 18             	sub    $0x18,%esp
f0100fd7:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	
	if(pp->pp_ref)
f0100fda:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100fdf:	74 1c                	je     f0100ffd <page_free+0x2c>
	{
	panic("Page cannot be returned to free list, as it is still refernced ");
f0100fe1:	c7 44 24 08 60 31 10 	movl   $0xf0103160,0x8(%esp)
f0100fe8:	f0 
f0100fe9:	c7 44 24 04 5e 01 00 	movl   $0x15e,0x4(%esp)
f0100ff0:	00 
f0100ff1:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0100ff8:	e8 24 f1 ff ff       	call   f0100121 <_panic>
	return;
	}
	
	// pp->pp_link is not NULL.
	else if(!pp) 
f0100ffd:	85 c0                	test   %eax,%eax
f0100fff:	75 1c                	jne    f010101d <page_free+0x4c>
	{
	panic("Page cannot be returned to free list as it is Null");
f0101001:	c7 44 24 08 a0 31 10 	movl   $0xf01031a0,0x8(%esp)
f0101008:	f0 
f0101009:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
f0101010:	00 
f0101011:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0101018:	e8 04 f1 ff ff       	call   f0100121 <_panic>
	return;
	}
	
       else{
	pp->pp_link = page_free_list;
f010101d:	8b 15 40 55 11 f0    	mov    0xf0115540,%edx
f0101023:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0101025:	a3 40 55 11 f0       	mov    %eax,0xf0115540
	}

}
f010102a:	c9                   	leave  
f010102b:	c3                   	ret    

f010102c <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f010102c:	55                   	push   %ebp
f010102d:	89 e5                	mov    %esp,%ebp
f010102f:	83 ec 18             	sub    $0x18,%esp
f0101032:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0101035:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0101039:	8d 51 ff             	lea    -0x1(%ecx),%edx
f010103c:	66 89 50 04          	mov    %dx,0x4(%eax)
f0101040:	66 85 d2             	test   %dx,%dx
f0101043:	75 08                	jne    f010104d <page_decref+0x21>
		page_free(pp);
f0101045:	89 04 24             	mov    %eax,(%esp)
f0101048:	e8 84 ff ff ff       	call   f0100fd1 <page_free>
}
f010104d:	c9                   	leave  
f010104e:	c3                   	ret    

f010104f <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f010104f:	55                   	push   %ebp
f0101050:	89 e5                	mov    %esp,%ebp
f0101052:	57                   	push   %edi
f0101053:	56                   	push   %esi
f0101054:	53                   	push   %ebx
f0101055:	83 ec 1c             	sub    $0x1c,%esp
	pte_t *pgTab;  //Page Table index variable

	//To find the index from the pgdir we need to get the MS 10 bits,
	//We get the MS 10bits of the virtual address by using PDX function (found in inc/mmu.h ) 
	//#define PDX(la)		((((uintptr_t) (la)) >> PDXSHIFT) & 0x3FF)
	pgDir = &pgdir[PDX(va)];
f0101058:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010105b:	c1 eb 16             	shr    $0x16,%ebx
f010105e:	c1 e3 02             	shl    $0x2,%ebx
f0101061:	03 5d 08             	add    0x8(%ebp),%ebx

	// Check if page is present, PTE_P = 0x1 means page present  
	if (*pgDir & PTE_P)  {
f0101064:	f6 03 01             	testb  $0x1,(%ebx)
f0101067:	74 3e                	je     f01010a7 <pgdir_walk+0x58>
		page table entry to get to the final address translation. Now using the pgDir we can use the 
		PTE_ADDR(pde) function to get the upper 20 bits, but this function returns a physical address. 
		Since the kernel requires a virtual address, we can use the function KADDR to get the virtual 
		address.
		*/
		pgTab = (pte_t*) KADDR(PTE_ADDR(pgDir));
f0101069:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010106f:	89 d8                	mov    %ebx,%eax
f0101071:	c1 e8 0c             	shr    $0xc,%eax
f0101074:	3b 05 64 59 11 f0    	cmp    0xf0115964,%eax
f010107a:	72 20                	jb     f010109c <pgdir_walk+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010107c:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0101080:	c7 44 24 08 04 30 10 	movl   $0xf0103004,0x8(%esp)
f0101087:	f0 
f0101088:	c7 44 24 04 a4 01 00 	movl   $0x1a4,0x4(%esp)
f010108f:	00 
f0101090:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0101097:	e8 85 f0 ff ff       	call   f0100121 <_panic>
	return (void *)(pa + KERNBASE);
f010109c:	8d bb 00 00 00 f0    	lea    -0x10000000(%ebx),%edi
f01010a2:	e9 8f 00 00 00       	jmp    f0101136 <pgdir_walk+0xe7>
	//If page is not present 
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
f01010a7:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01010ab:	0f 84 94 00 00 00    	je     f0101145 <pgdir_walk+0xf6>
f01010b1:	c7 04 24 00 10 00 00 	movl   $0x1000,(%esp)
f01010b8:	e8 89 fe ff ff       	call   f0100f46 <page_alloc>
f01010bd:	89 c6                	mov    %eax,%esi
f01010bf:	85 c0                	test   %eax,%eax
f01010c1:	0f 84 85 00 00 00    	je     f010114c <pgdir_walk+0xfd>
			return 0;
		}

		newPage->pp_ref++;  //Increment the ref pointer of the page 
f01010c7:	66 83 40 04 01       	addw   $0x1,0x4(%eax)

//page2pa returns the relevant physical address of the page
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01010cc:	89 c7                	mov    %eax,%edi
f01010ce:	2b 3d 6c 59 11 f0    	sub    0xf011596c,%edi
f01010d4:	c1 ff 03             	sar    $0x3,%edi
f01010d7:	c1 e7 0c             	shl    $0xc,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010da:	89 f8                	mov    %edi,%eax
f01010dc:	c1 e8 0c             	shr    $0xc,%eax
f01010df:	3b 05 64 59 11 f0    	cmp    0xf0115964,%eax
f01010e5:	72 20                	jb     f0101107 <pgdir_walk+0xb8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010e7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01010eb:	c7 44 24 08 04 30 10 	movl   $0xf0103004,0x8(%esp)
f01010f2:	f0 
f01010f3:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01010fa:	00 
f01010fb:	c7 04 24 08 33 10 f0 	movl   $0xf0103308,(%esp)
f0101102:	e8 1a f0 ff ff       	call   f0100121 <_panic>
	return (void *)(pa + KERNBASE);
f0101107:	81 ef 00 00 00 10    	sub    $0x10000000,%edi
		//Now this section creates the bindings and updates all the flags 
		//for relevant use of the page.
		
		//First create a link on the pgTab wrt to the new page
		pgTab = (pte_t *)page2kva(newPage); // this function gets the virtual address of the new page
		memset (pgTab, 0, PGSIZE); //Clear the entire page
f010110d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101114:	00 
f0101115:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010111c:	00 
f010111d:	89 3c 24             	mov    %edi,(%esp)
f0101120:	e8 e2 14 00 00       	call   f0102607 <memset>

//page2pa returns the relevant physical address of the page
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101125:	2b 35 6c 59 11 f0    	sub    0xf011596c,%esi
f010112b:	c1 fe 03             	sar    $0x3,%esi
f010112e:	c1 e6 0c             	shl    $0xc,%esi

		/*Page Table, pgTab contains the virtual address , now we need to set the permission bits.
		The page directory entry contains the 20 bit physical address and also the permission bits,
		We can set better permissive bits here.*/
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
f0101131:	83 ce 07             	or     $0x7,%esi
f0101134:	89 33                	mov    %esi,(%ebx)
	}
	return &pgTab[PTX(va)];	//Return the final address of the page table entry.
f0101136:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101139:	c1 e8 0a             	shr    $0xa,%eax
f010113c:	25 fc 0f 00 00       	and    $0xffc,%eax
f0101141:	01 f8                	add    %edi,%eax
f0101143:	eb 0c                	jmp    f0101151 <pgdir_walk+0x102>
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
			return 0;
f0101145:	b8 00 00 00 00       	mov    $0x0,%eax
f010114a:	eb 05                	jmp    f0101151 <pgdir_walk+0x102>
f010114c:	b8 00 00 00 00       	mov    $0x0,%eax
		The page directory entry contains the 20 bit physical address and also the permission bits,
		We can set better permissive bits here.*/
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
	}
	return &pgTab[PTX(va)];	//Return the final address of the page table entry.
}
f0101151:	83 c4 1c             	add    $0x1c,%esp
f0101154:	5b                   	pop    %ebx
f0101155:	5e                   	pop    %esi
f0101156:	5f                   	pop    %edi
f0101157:	5d                   	pop    %ebp
f0101158:	c3                   	ret    

f0101159 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101159:	55                   	push   %ebp
f010115a:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f010115c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101161:	5d                   	pop    %ebp
f0101162:	c3                   	ret    

f0101163 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101163:	55                   	push   %ebp
f0101164:	89 e5                	mov    %esp,%ebp
f0101166:	53                   	push   %ebx
f0101167:	83 ec 14             	sub    $0x14,%esp
f010116a:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pTe; 
	
	pTe = pgdir_walk(pgdir, va , 0);
f010116d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101174:	00 
f0101175:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101178:	89 44 24 04          	mov    %eax,0x4(%esp)
f010117c:	8b 45 08             	mov    0x8(%ebp),%eax
f010117f:	89 04 24             	mov    %eax,(%esp)
f0101182:	e8 c8 fe ff ff       	call   f010104f <pgdir_walk>

	//Now check if the page table entry is valid and is present
	if (!(pTe && (*pTe & PTE_P))){ 
f0101187:	85 c0                	test   %eax,%eax
f0101189:	74 05                	je     f0101190 <page_lookup+0x2d>
f010118b:	f6 00 01             	testb  $0x1,(%eax)
f010118e:	75 1c                	jne    f01011ac <page_lookup+0x49>
		panic ("The page looked up is not present\n");
f0101190:	c7 44 24 08 d4 31 10 	movl   $0xf01031d4,0x8(%esp)
f0101197:	f0 
f0101198:	c7 44 24 04 18 02 00 	movl   $0x218,0x4(%esp)
f010119f:	00 
f01011a0:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f01011a7:	e8 75 ef ff ff       	call   f0100121 <_panic>
        return NULL; 
	}

	if (pte_store){
f01011ac:	85 db                	test   %ebx,%ebx
f01011ae:	74 02                	je     f01011b2 <page_lookup+0x4f>
		*pte_store = pTe;
f01011b0:	89 03                	mov    %eax,(%ebx)

//this function returns address of the page from the physical address
static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01011b2:	c1 e8 0c             	shr    $0xc,%eax
f01011b5:	3b 05 64 59 11 f0    	cmp    0xf0115964,%eax
f01011bb:	72 1c                	jb     f01011d9 <page_lookup+0x76>
		panic("pa2page called with invalid pa");
f01011bd:	c7 44 24 08 f8 31 10 	movl   $0xf01031f8,0x8(%esp)
f01011c4:	f0 
f01011c5:	c7 44 24 04 4e 00 00 	movl   $0x4e,0x4(%esp)
f01011cc:	00 
f01011cd:	c7 04 24 08 33 10 f0 	movl   $0xf0103308,(%esp)
f01011d4:	e8 48 ef ff ff       	call   f0100121 <_panic>
	return &pages[PGNUM(pa)];
f01011d9:	8b 15 6c 59 11 f0    	mov    0xf011596c,%edx
f01011df:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	}
	return pa2page (PTE_ADDR (pTe));
}
f01011e2:	83 c4 14             	add    $0x14,%esp
f01011e5:	5b                   	pop    %ebx
f01011e6:	5d                   	pop    %ebp
f01011e7:	c3                   	ret    

f01011e8 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01011e8:	55                   	push   %ebp
f01011e9:	89 e5                	mov    %esp,%ebp
f01011eb:	53                   	push   %ebx
f01011ec:	83 ec 24             	sub    $0x24,%esp
f01011ef:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte;
	struct PageInfo *remPage = 0;
	if (!(remPage = page_lookup(pgdir, va, &pte))) {
f01011f2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01011f5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011f9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011fd:	8b 45 08             	mov    0x8(%ebp),%eax
f0101200:	89 04 24             	mov    %eax,(%esp)
f0101203:	e8 5b ff ff ff       	call   f0101163 <page_lookup>
f0101208:	85 c0                	test   %eax,%eax
f010120a:	74 14                	je     f0101220 <page_remove+0x38>
		return;
	}
	page_decref(remPage);
f010120c:	89 04 24             	mov    %eax,(%esp)
f010120f:	e8 18 fe ff ff       	call   f010102c <page_decref>
	*pte = 0;
f0101214:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101217:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010121d:	0f 01 3b             	invlpg (%ebx)
	tlb_invalidate(pgdir, va);
}
f0101220:	83 c4 24             	add    $0x24,%esp
f0101223:	5b                   	pop    %ebx
f0101224:	5d                   	pop    %ebp
f0101225:	c3                   	ret    

f0101226 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101226:	55                   	push   %ebp
f0101227:	89 e5                	mov    %esp,%ebp
f0101229:	57                   	push   %edi
f010122a:	56                   	push   %esi
f010122b:	53                   	push   %ebx
f010122c:	83 ec 3c             	sub    $0x3c,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010122f:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f0101236:	e8 fc 07 00 00       	call   f0101a37 <mc146818_read>
f010123b:	89 c3                	mov    %eax,%ebx
f010123d:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101244:	e8 ee 07 00 00       	call   f0101a37 <mc146818_read>
f0101249:	c1 e0 08             	shl    $0x8,%eax
f010124c:	09 c3                	or     %eax,%ebx
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f010124e:	89 d8                	mov    %ebx,%eax
f0101250:	c1 e0 0a             	shl    $0xa,%eax
f0101253:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101259:	85 c0                	test   %eax,%eax
f010125b:	0f 48 c2             	cmovs  %edx,%eax
f010125e:	c1 f8 0c             	sar    $0xc,%eax
f0101261:	a3 44 55 11 f0       	mov    %eax,0xf0115544
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101266:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010126d:	e8 c5 07 00 00       	call   f0101a37 <mc146818_read>
f0101272:	89 c3                	mov    %eax,%ebx
f0101274:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f010127b:	e8 b7 07 00 00       	call   f0101a37 <mc146818_read>
f0101280:	c1 e0 08             	shl    $0x8,%eax
f0101283:	09 c3                	or     %eax,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101285:	89 d8                	mov    %ebx,%eax
f0101287:	c1 e0 0a             	shl    $0xa,%eax
f010128a:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101290:	85 c0                	test   %eax,%eax
f0101292:	0f 48 c2             	cmovs  %edx,%eax
f0101295:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101298:	85 c0                	test   %eax,%eax
f010129a:	74 0e                	je     f01012aa <mem_init+0x84>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010129c:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01012a2:	89 15 64 59 11 f0    	mov    %edx,0xf0115964
f01012a8:	eb 0c                	jmp    f01012b6 <mem_init+0x90>
	else
		npages = npages_basemem;
f01012aa:	8b 15 44 55 11 f0    	mov    0xf0115544,%edx
f01012b0:	89 15 64 59 11 f0    	mov    %edx,0xf0115964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f01012b6:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012b9:	c1 e8 0a             	shr    $0xa,%eax
f01012bc:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f01012c0:	a1 44 55 11 f0       	mov    0xf0115544,%eax
f01012c5:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012c8:	c1 e8 0a             	shr    $0xa,%eax
f01012cb:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f01012cf:	a1 64 59 11 f0       	mov    0xf0115964,%eax
f01012d4:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012d7:	c1 e8 0a             	shr    $0xa,%eax
f01012da:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012de:	c7 04 24 18 32 10 f0 	movl   $0xf0103218,(%esp)
f01012e5:	e8 bd 07 00 00       	call   f0101aa7 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01012ea:	b8 00 10 00 00       	mov    $0x1000,%eax
f01012ef:	e8 23 f7 ff ff       	call   f0100a17 <boot_alloc>
f01012f4:	a3 68 59 11 f0       	mov    %eax,0xf0115968
	memset(kern_pgdir, 0, PGSIZE);
f01012f9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101300:	00 
f0101301:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101308:	00 
f0101309:	89 04 24             	mov    %eax,(%esp)
f010130c:	e8 f6 12 00 00       	call   f0102607 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101311:	a1 68 59 11 f0       	mov    0xf0115968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101316:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010131b:	77 20                	ja     f010133d <mem_init+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010131d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101321:	c7 44 24 08 28 30 10 	movl   $0xf0103028,0x8(%esp)
f0101328:	f0 
f0101329:	c7 44 24 04 95 00 00 	movl   $0x95,0x4(%esp)
f0101330:	00 
f0101331:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0101338:	e8 e4 ed ff ff       	call   f0100121 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010133d:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101343:	83 ca 05             	or     $0x5,%edx
f0101346:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.

	//This line creates a boot allocation of memory of the size of number of pages
	// mulitplied by size of struct Pageinfo to store metadata of the page. 
	pages = boot_alloc(sizeof(struct PageInfo) * npages);   
f010134c:	a1 64 59 11 f0       	mov    0xf0115964,%eax
f0101351:	c1 e0 03             	shl    $0x3,%eax
f0101354:	e8 be f6 ff ff       	call   f0100a17 <boot_alloc>
f0101359:	a3 6c 59 11 f0       	mov    %eax,0xf011596c
	memset(pages, 0, sizeof(struct PageInfo) * npages); //Clear the memory 
f010135e:	8b 3d 64 59 11 f0    	mov    0xf0115964,%edi
f0101364:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f010136b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010136f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101376:	00 
f0101377:	89 04 24             	mov    %eax,(%esp)
f010137a:	e8 88 12 00 00       	call   f0102607 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010137f:	e8 61 fa ff ff       	call   f0100de5 <page_init>

	check_page_free_list(1);
f0101384:	b8 01 00 00 00       	mov    $0x1,%eax
f0101389:	e8 0e f7 ff ff       	call   f0100a9c <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010138e:	83 3d 6c 59 11 f0 00 	cmpl   $0x0,0xf011596c
f0101395:	75 1c                	jne    f01013b3 <mem_init+0x18d>
		panic("'pages' is a null pointer!");
f0101397:	c7 44 24 08 c9 33 10 	movl   $0xf01033c9,0x8(%esp)
f010139e:	f0 
f010139f:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f01013a6:	00 
f01013a7:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f01013ae:	e8 6e ed ff ff       	call   f0100121 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013b3:	a1 40 55 11 f0       	mov    0xf0115540,%eax
f01013b8:	bb 00 00 00 00       	mov    $0x0,%ebx
f01013bd:	eb 05                	jmp    f01013c4 <mem_init+0x19e>
		++nfree;
f01013bf:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013c2:	8b 00                	mov    (%eax),%eax
f01013c4:	85 c0                	test   %eax,%eax
f01013c6:	75 f7                	jne    f01013bf <mem_init+0x199>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013c8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013cf:	e8 72 fb ff ff       	call   f0100f46 <page_alloc>
f01013d4:	89 c7                	mov    %eax,%edi
f01013d6:	85 c0                	test   %eax,%eax
f01013d8:	75 24                	jne    f01013fe <mem_init+0x1d8>
f01013da:	c7 44 24 0c e4 33 10 	movl   $0xf01033e4,0xc(%esp)
f01013e1:	f0 
f01013e2:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f01013e9:	f0 
f01013ea:	c7 44 24 04 a0 02 00 	movl   $0x2a0,0x4(%esp)
f01013f1:	00 
f01013f2:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f01013f9:	e8 23 ed ff ff       	call   f0100121 <_panic>
	assert((pp1 = page_alloc(0)));
f01013fe:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101405:	e8 3c fb ff ff       	call   f0100f46 <page_alloc>
f010140a:	89 c6                	mov    %eax,%esi
f010140c:	85 c0                	test   %eax,%eax
f010140e:	75 24                	jne    f0101434 <mem_init+0x20e>
f0101410:	c7 44 24 0c fa 33 10 	movl   $0xf01033fa,0xc(%esp)
f0101417:	f0 
f0101418:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f010141f:	f0 
f0101420:	c7 44 24 04 a1 02 00 	movl   $0x2a1,0x4(%esp)
f0101427:	00 
f0101428:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f010142f:	e8 ed ec ff ff       	call   f0100121 <_panic>
	assert((pp2 = page_alloc(0)));
f0101434:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010143b:	e8 06 fb ff ff       	call   f0100f46 <page_alloc>
f0101440:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101443:	85 c0                	test   %eax,%eax
f0101445:	75 24                	jne    f010146b <mem_init+0x245>
f0101447:	c7 44 24 0c 10 34 10 	movl   $0xf0103410,0xc(%esp)
f010144e:	f0 
f010144f:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f0101456:	f0 
f0101457:	c7 44 24 04 a2 02 00 	movl   $0x2a2,0x4(%esp)
f010145e:	00 
f010145f:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0101466:	e8 b6 ec ff ff       	call   f0100121 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010146b:	39 f7                	cmp    %esi,%edi
f010146d:	75 24                	jne    f0101493 <mem_init+0x26d>
f010146f:	c7 44 24 0c 26 34 10 	movl   $0xf0103426,0xc(%esp)
f0101476:	f0 
f0101477:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f010147e:	f0 
f010147f:	c7 44 24 04 a5 02 00 	movl   $0x2a5,0x4(%esp)
f0101486:	00 
f0101487:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f010148e:	e8 8e ec ff ff       	call   f0100121 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101493:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101496:	39 c6                	cmp    %eax,%esi
f0101498:	74 04                	je     f010149e <mem_init+0x278>
f010149a:	39 c7                	cmp    %eax,%edi
f010149c:	75 24                	jne    f01014c2 <mem_init+0x29c>
f010149e:	c7 44 24 0c 54 32 10 	movl   $0xf0103254,0xc(%esp)
f01014a5:	f0 
f01014a6:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f01014ad:	f0 
f01014ae:	c7 44 24 04 a6 02 00 	movl   $0x2a6,0x4(%esp)
f01014b5:	00 
f01014b6:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f01014bd:	e8 5f ec ff ff       	call   f0100121 <_panic>

//page2pa returns the relevant physical address of the page
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014c2:	8b 15 6c 59 11 f0    	mov    0xf011596c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f01014c8:	a1 64 59 11 f0       	mov    0xf0115964,%eax
f01014cd:	c1 e0 0c             	shl    $0xc,%eax
f01014d0:	89 f9                	mov    %edi,%ecx
f01014d2:	29 d1                	sub    %edx,%ecx
f01014d4:	c1 f9 03             	sar    $0x3,%ecx
f01014d7:	c1 e1 0c             	shl    $0xc,%ecx
f01014da:	39 c1                	cmp    %eax,%ecx
f01014dc:	72 24                	jb     f0101502 <mem_init+0x2dc>
f01014de:	c7 44 24 0c 38 34 10 	movl   $0xf0103438,0xc(%esp)
f01014e5:	f0 
f01014e6:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f01014ed:	f0 
f01014ee:	c7 44 24 04 a7 02 00 	movl   $0x2a7,0x4(%esp)
f01014f5:	00 
f01014f6:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f01014fd:	e8 1f ec ff ff       	call   f0100121 <_panic>
f0101502:	89 f1                	mov    %esi,%ecx
f0101504:	29 d1                	sub    %edx,%ecx
f0101506:	c1 f9 03             	sar    $0x3,%ecx
f0101509:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f010150c:	39 c8                	cmp    %ecx,%eax
f010150e:	77 24                	ja     f0101534 <mem_init+0x30e>
f0101510:	c7 44 24 0c 55 34 10 	movl   $0xf0103455,0xc(%esp)
f0101517:	f0 
f0101518:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f010151f:	f0 
f0101520:	c7 44 24 04 a8 02 00 	movl   $0x2a8,0x4(%esp)
f0101527:	00 
f0101528:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f010152f:	e8 ed eb ff ff       	call   f0100121 <_panic>
f0101534:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101537:	29 d1                	sub    %edx,%ecx
f0101539:	89 ca                	mov    %ecx,%edx
f010153b:	c1 fa 03             	sar    $0x3,%edx
f010153e:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101541:	39 d0                	cmp    %edx,%eax
f0101543:	77 24                	ja     f0101569 <mem_init+0x343>
f0101545:	c7 44 24 0c 72 34 10 	movl   $0xf0103472,0xc(%esp)
f010154c:	f0 
f010154d:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f0101554:	f0 
f0101555:	c7 44 24 04 a9 02 00 	movl   $0x2a9,0x4(%esp)
f010155c:	00 
f010155d:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0101564:	e8 b8 eb ff ff       	call   f0100121 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101569:	a1 40 55 11 f0       	mov    0xf0115540,%eax
f010156e:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101571:	c7 05 40 55 11 f0 00 	movl   $0x0,0xf0115540
f0101578:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010157b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101582:	e8 bf f9 ff ff       	call   f0100f46 <page_alloc>
f0101587:	85 c0                	test   %eax,%eax
f0101589:	74 24                	je     f01015af <mem_init+0x389>
f010158b:	c7 44 24 0c 8f 34 10 	movl   $0xf010348f,0xc(%esp)
f0101592:	f0 
f0101593:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f010159a:	f0 
f010159b:	c7 44 24 04 b0 02 00 	movl   $0x2b0,0x4(%esp)
f01015a2:	00 
f01015a3:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f01015aa:	e8 72 eb ff ff       	call   f0100121 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01015af:	89 3c 24             	mov    %edi,(%esp)
f01015b2:	e8 1a fa ff ff       	call   f0100fd1 <page_free>
	page_free(pp1);
f01015b7:	89 34 24             	mov    %esi,(%esp)
f01015ba:	e8 12 fa ff ff       	call   f0100fd1 <page_free>
	page_free(pp2);
f01015bf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015c2:	89 04 24             	mov    %eax,(%esp)
f01015c5:	e8 07 fa ff ff       	call   f0100fd1 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015ca:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015d1:	e8 70 f9 ff ff       	call   f0100f46 <page_alloc>
f01015d6:	89 c6                	mov    %eax,%esi
f01015d8:	85 c0                	test   %eax,%eax
f01015da:	75 24                	jne    f0101600 <mem_init+0x3da>
f01015dc:	c7 44 24 0c e4 33 10 	movl   $0xf01033e4,0xc(%esp)
f01015e3:	f0 
f01015e4:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f01015eb:	f0 
f01015ec:	c7 44 24 04 b7 02 00 	movl   $0x2b7,0x4(%esp)
f01015f3:	00 
f01015f4:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f01015fb:	e8 21 eb ff ff       	call   f0100121 <_panic>
	assert((pp1 = page_alloc(0)));
f0101600:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101607:	e8 3a f9 ff ff       	call   f0100f46 <page_alloc>
f010160c:	89 c7                	mov    %eax,%edi
f010160e:	85 c0                	test   %eax,%eax
f0101610:	75 24                	jne    f0101636 <mem_init+0x410>
f0101612:	c7 44 24 0c fa 33 10 	movl   $0xf01033fa,0xc(%esp)
f0101619:	f0 
f010161a:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f0101621:	f0 
f0101622:	c7 44 24 04 b8 02 00 	movl   $0x2b8,0x4(%esp)
f0101629:	00 
f010162a:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0101631:	e8 eb ea ff ff       	call   f0100121 <_panic>
	assert((pp2 = page_alloc(0)));
f0101636:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010163d:	e8 04 f9 ff ff       	call   f0100f46 <page_alloc>
f0101642:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101645:	85 c0                	test   %eax,%eax
f0101647:	75 24                	jne    f010166d <mem_init+0x447>
f0101649:	c7 44 24 0c 10 34 10 	movl   $0xf0103410,0xc(%esp)
f0101650:	f0 
f0101651:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f0101658:	f0 
f0101659:	c7 44 24 04 b9 02 00 	movl   $0x2b9,0x4(%esp)
f0101660:	00 
f0101661:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0101668:	e8 b4 ea ff ff       	call   f0100121 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010166d:	39 fe                	cmp    %edi,%esi
f010166f:	75 24                	jne    f0101695 <mem_init+0x46f>
f0101671:	c7 44 24 0c 26 34 10 	movl   $0xf0103426,0xc(%esp)
f0101678:	f0 
f0101679:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f0101680:	f0 
f0101681:	c7 44 24 04 bb 02 00 	movl   $0x2bb,0x4(%esp)
f0101688:	00 
f0101689:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0101690:	e8 8c ea ff ff       	call   f0100121 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101695:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101698:	39 c7                	cmp    %eax,%edi
f010169a:	74 04                	je     f01016a0 <mem_init+0x47a>
f010169c:	39 c6                	cmp    %eax,%esi
f010169e:	75 24                	jne    f01016c4 <mem_init+0x49e>
f01016a0:	c7 44 24 0c 54 32 10 	movl   $0xf0103254,0xc(%esp)
f01016a7:	f0 
f01016a8:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f01016af:	f0 
f01016b0:	c7 44 24 04 bc 02 00 	movl   $0x2bc,0x4(%esp)
f01016b7:	00 
f01016b8:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f01016bf:	e8 5d ea ff ff       	call   f0100121 <_panic>
	assert(!page_alloc(0));
f01016c4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016cb:	e8 76 f8 ff ff       	call   f0100f46 <page_alloc>
f01016d0:	85 c0                	test   %eax,%eax
f01016d2:	74 24                	je     f01016f8 <mem_init+0x4d2>
f01016d4:	c7 44 24 0c 8f 34 10 	movl   $0xf010348f,0xc(%esp)
f01016db:	f0 
f01016dc:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f01016e3:	f0 
f01016e4:	c7 44 24 04 bd 02 00 	movl   $0x2bd,0x4(%esp)
f01016eb:	00 
f01016ec:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f01016f3:	e8 29 ea ff ff       	call   f0100121 <_panic>
f01016f8:	89 f0                	mov    %esi,%eax
f01016fa:	2b 05 6c 59 11 f0    	sub    0xf011596c,%eax
f0101700:	c1 f8 03             	sar    $0x3,%eax
f0101703:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101706:	89 c2                	mov    %eax,%edx
f0101708:	c1 ea 0c             	shr    $0xc,%edx
f010170b:	3b 15 64 59 11 f0    	cmp    0xf0115964,%edx
f0101711:	72 20                	jb     f0101733 <mem_init+0x50d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101713:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101717:	c7 44 24 08 04 30 10 	movl   $0xf0103004,0x8(%esp)
f010171e:	f0 
f010171f:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101726:	00 
f0101727:	c7 04 24 08 33 10 f0 	movl   $0xf0103308,(%esp)
f010172e:	e8 ee e9 ff ff       	call   f0100121 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101733:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010173a:	00 
f010173b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101742:	00 
	return (void *)(pa + KERNBASE);
f0101743:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101748:	89 04 24             	mov    %eax,(%esp)
f010174b:	e8 b7 0e 00 00       	call   f0102607 <memset>
	page_free(pp0);
f0101750:	89 34 24             	mov    %esi,(%esp)
f0101753:	e8 79 f8 ff ff       	call   f0100fd1 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101758:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010175f:	e8 e2 f7 ff ff       	call   f0100f46 <page_alloc>
f0101764:	85 c0                	test   %eax,%eax
f0101766:	75 24                	jne    f010178c <mem_init+0x566>
f0101768:	c7 44 24 0c 9e 34 10 	movl   $0xf010349e,0xc(%esp)
f010176f:	f0 
f0101770:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f0101777:	f0 
f0101778:	c7 44 24 04 c2 02 00 	movl   $0x2c2,0x4(%esp)
f010177f:	00 
f0101780:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0101787:	e8 95 e9 ff ff       	call   f0100121 <_panic>
	assert(pp && pp0 == pp);
f010178c:	39 c6                	cmp    %eax,%esi
f010178e:	74 24                	je     f01017b4 <mem_init+0x58e>
f0101790:	c7 44 24 0c bc 34 10 	movl   $0xf01034bc,0xc(%esp)
f0101797:	f0 
f0101798:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f010179f:	f0 
f01017a0:	c7 44 24 04 c3 02 00 	movl   $0x2c3,0x4(%esp)
f01017a7:	00 
f01017a8:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f01017af:	e8 6d e9 ff ff       	call   f0100121 <_panic>

//page2pa returns the relevant physical address of the page
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01017b4:	89 f0                	mov    %esi,%eax
f01017b6:	2b 05 6c 59 11 f0    	sub    0xf011596c,%eax
f01017bc:	c1 f8 03             	sar    $0x3,%eax
f01017bf:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01017c2:	89 c2                	mov    %eax,%edx
f01017c4:	c1 ea 0c             	shr    $0xc,%edx
f01017c7:	3b 15 64 59 11 f0    	cmp    0xf0115964,%edx
f01017cd:	72 20                	jb     f01017ef <mem_init+0x5c9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01017cf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01017d3:	c7 44 24 08 04 30 10 	movl   $0xf0103004,0x8(%esp)
f01017da:	f0 
f01017db:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01017e2:	00 
f01017e3:	c7 04 24 08 33 10 f0 	movl   $0xf0103308,(%esp)
f01017ea:	e8 32 e9 ff ff       	call   f0100121 <_panic>
f01017ef:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01017f5:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01017fb:	80 38 00             	cmpb   $0x0,(%eax)
f01017fe:	74 24                	je     f0101824 <mem_init+0x5fe>
f0101800:	c7 44 24 0c cc 34 10 	movl   $0xf01034cc,0xc(%esp)
f0101807:	f0 
f0101808:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f010180f:	f0 
f0101810:	c7 44 24 04 c6 02 00 	movl   $0x2c6,0x4(%esp)
f0101817:	00 
f0101818:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f010181f:	e8 fd e8 ff ff       	call   f0100121 <_panic>
f0101824:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101827:	39 d0                	cmp    %edx,%eax
f0101829:	75 d0                	jne    f01017fb <mem_init+0x5d5>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010182b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010182e:	a3 40 55 11 f0       	mov    %eax,0xf0115540

	// free the pages we took
	page_free(pp0);
f0101833:	89 34 24             	mov    %esi,(%esp)
f0101836:	e8 96 f7 ff ff       	call   f0100fd1 <page_free>
	page_free(pp1);
f010183b:	89 3c 24             	mov    %edi,(%esp)
f010183e:	e8 8e f7 ff ff       	call   f0100fd1 <page_free>
	page_free(pp2);
f0101843:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101846:	89 04 24             	mov    %eax,(%esp)
f0101849:	e8 83 f7 ff ff       	call   f0100fd1 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010184e:	a1 40 55 11 f0       	mov    0xf0115540,%eax
f0101853:	eb 05                	jmp    f010185a <mem_init+0x634>
		--nfree;
f0101855:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101858:	8b 00                	mov    (%eax),%eax
f010185a:	85 c0                	test   %eax,%eax
f010185c:	75 f7                	jne    f0101855 <mem_init+0x62f>
		--nfree;
	assert(nfree == 0);
f010185e:	85 db                	test   %ebx,%ebx
f0101860:	74 24                	je     f0101886 <mem_init+0x660>
f0101862:	c7 44 24 0c d6 34 10 	movl   $0xf01034d6,0xc(%esp)
f0101869:	f0 
f010186a:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f0101871:	f0 
f0101872:	c7 44 24 04 d3 02 00 	movl   $0x2d3,0x4(%esp)
f0101879:	00 
f010187a:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0101881:	e8 9b e8 ff ff       	call   f0100121 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101886:	c7 04 24 74 32 10 f0 	movl   $0xf0103274,(%esp)
f010188d:	e8 15 02 00 00       	call   f0101aa7 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101892:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101899:	e8 a8 f6 ff ff       	call   f0100f46 <page_alloc>
f010189e:	89 c3                	mov    %eax,%ebx
f01018a0:	85 c0                	test   %eax,%eax
f01018a2:	75 24                	jne    f01018c8 <mem_init+0x6a2>
f01018a4:	c7 44 24 0c e4 33 10 	movl   $0xf01033e4,0xc(%esp)
f01018ab:	f0 
f01018ac:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f01018b3:	f0 
f01018b4:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
f01018bb:	00 
f01018bc:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f01018c3:	e8 59 e8 ff ff       	call   f0100121 <_panic>
	assert((pp1 = page_alloc(0)));
f01018c8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018cf:	e8 72 f6 ff ff       	call   f0100f46 <page_alloc>
f01018d4:	89 c6                	mov    %eax,%esi
f01018d6:	85 c0                	test   %eax,%eax
f01018d8:	75 24                	jne    f01018fe <mem_init+0x6d8>
f01018da:	c7 44 24 0c fa 33 10 	movl   $0xf01033fa,0xc(%esp)
f01018e1:	f0 
f01018e2:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f01018e9:	f0 
f01018ea:	c7 44 24 04 2d 03 00 	movl   $0x32d,0x4(%esp)
f01018f1:	00 
f01018f2:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f01018f9:	e8 23 e8 ff ff       	call   f0100121 <_panic>
	assert((pp2 = page_alloc(0)));
f01018fe:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101905:	e8 3c f6 ff ff       	call   f0100f46 <page_alloc>
f010190a:	85 c0                	test   %eax,%eax
f010190c:	75 24                	jne    f0101932 <mem_init+0x70c>
f010190e:	c7 44 24 0c 10 34 10 	movl   $0xf0103410,0xc(%esp)
f0101915:	f0 
f0101916:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f010191d:	f0 
f010191e:	c7 44 24 04 2e 03 00 	movl   $0x32e,0x4(%esp)
f0101925:	00 
f0101926:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f010192d:	e8 ef e7 ff ff       	call   f0100121 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101932:	39 f3                	cmp    %esi,%ebx
f0101934:	75 24                	jne    f010195a <mem_init+0x734>
f0101936:	c7 44 24 0c 26 34 10 	movl   $0xf0103426,0xc(%esp)
f010193d:	f0 
f010193e:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f0101945:	f0 
f0101946:	c7 44 24 04 31 03 00 	movl   $0x331,0x4(%esp)
f010194d:	00 
f010194e:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0101955:	e8 c7 e7 ff ff       	call   f0100121 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010195a:	39 c6                	cmp    %eax,%esi
f010195c:	74 04                	je     f0101962 <mem_init+0x73c>
f010195e:	39 c3                	cmp    %eax,%ebx
f0101960:	75 24                	jne    f0101986 <mem_init+0x760>
f0101962:	c7 44 24 0c 54 32 10 	movl   $0xf0103254,0xc(%esp)
f0101969:	f0 
f010196a:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f0101971:	f0 
f0101972:	c7 44 24 04 32 03 00 	movl   $0x332,0x4(%esp)
f0101979:	00 
f010197a:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0101981:	e8 9b e7 ff ff       	call   f0100121 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
	page_free_list = 0;
f0101986:	c7 05 40 55 11 f0 00 	movl   $0x0,0xf0115540
f010198d:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101990:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101997:	e8 aa f5 ff ff       	call   f0100f46 <page_alloc>
f010199c:	85 c0                	test   %eax,%eax
f010199e:	74 24                	je     f01019c4 <mem_init+0x79e>
f01019a0:	c7 44 24 0c 8f 34 10 	movl   $0xf010348f,0xc(%esp)
f01019a7:	f0 
f01019a8:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f01019af:	f0 
f01019b0:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f01019b7:	00 
f01019b8:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f01019bf:	e8 5d e7 ff ff       	call   f0100121 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01019c4:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01019c7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01019cb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01019d2:	00 
f01019d3:	a1 68 59 11 f0       	mov    0xf0115968,%eax
f01019d8:	89 04 24             	mov    %eax,(%esp)
f01019db:	e8 83 f7 ff ff       	call   f0101163 <page_lookup>
f01019e0:	85 c0                	test   %eax,%eax
f01019e2:	74 24                	je     f0101a08 <mem_init+0x7e2>
f01019e4:	c7 44 24 0c 94 32 10 	movl   $0xf0103294,0xc(%esp)
f01019eb:	f0 
f01019ec:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f01019f3:	f0 
f01019f4:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f01019fb:	00 
f01019fc:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0101a03:	e8 19 e7 ff ff       	call   f0100121 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a08:	c7 44 24 0c cc 32 10 	movl   $0xf01032cc,0xc(%esp)
f0101a0f:	f0 
f0101a10:	c7 44 24 08 22 33 10 	movl   $0xf0103322,0x8(%esp)
f0101a17:	f0 
f0101a18:	c7 44 24 04 3f 03 00 	movl   $0x33f,0x4(%esp)
f0101a1f:	00 
f0101a20:	c7 04 24 fc 32 10 f0 	movl   $0xf01032fc,(%esp)
f0101a27:	e8 f5 e6 ff ff       	call   f0100121 <_panic>

f0101a2c <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101a2c:	55                   	push   %ebp
f0101a2d:	89 e5                	mov    %esp,%ebp
f0101a2f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101a32:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0101a35:	5d                   	pop    %ebp
f0101a36:	c3                   	ret    

f0101a37 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0101a37:	55                   	push   %ebp
f0101a38:	89 e5                	mov    %esp,%ebp
f0101a3a:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0101a3e:	ba 70 00 00 00       	mov    $0x70,%edx
f0101a43:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0101a44:	b2 71                	mov    $0x71,%dl
f0101a46:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0101a47:	0f b6 c0             	movzbl %al,%eax
}
f0101a4a:	5d                   	pop    %ebp
f0101a4b:	c3                   	ret    

f0101a4c <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0101a4c:	55                   	push   %ebp
f0101a4d:	89 e5                	mov    %esp,%ebp
f0101a4f:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0101a53:	ba 70 00 00 00       	mov    $0x70,%edx
f0101a58:	ee                   	out    %al,(%dx)
f0101a59:	b2 71                	mov    $0x71,%dl
f0101a5b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101a5e:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0101a5f:	5d                   	pop    %ebp
f0101a60:	c3                   	ret    

f0101a61 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0101a61:	55                   	push   %ebp
f0101a62:	89 e5                	mov    %esp,%ebp
f0101a64:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0101a67:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a6a:	89 04 24             	mov    %eax,(%esp)
f0101a6d:	e8 0f ec ff ff       	call   f0100681 <cputchar>
	*cnt++;
}
f0101a72:	c9                   	leave  
f0101a73:	c3                   	ret    

f0101a74 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0101a74:	55                   	push   %ebp
f0101a75:	89 e5                	mov    %esp,%ebp
f0101a77:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0101a7a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0101a81:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101a84:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101a88:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a8b:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101a8f:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101a92:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a96:	c7 04 24 61 1a 10 f0 	movl   $0xf0101a61,(%esp)
f0101a9d:	e8 ac 04 00 00       	call   f0101f4e <vprintfmt>
	return cnt;
}
f0101aa2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101aa5:	c9                   	leave  
f0101aa6:	c3                   	ret    

f0101aa7 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0101aa7:	55                   	push   %ebp
f0101aa8:	89 e5                	mov    %esp,%ebp
f0101aaa:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0101aad:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0101ab0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101ab4:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ab7:	89 04 24             	mov    %eax,(%esp)
f0101aba:	e8 b5 ff ff ff       	call   f0101a74 <vcprintf>
	va_end(ap);

	return cnt;
}
f0101abf:	c9                   	leave  
f0101ac0:	c3                   	ret    

f0101ac1 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0101ac1:	55                   	push   %ebp
f0101ac2:	89 e5                	mov    %esp,%ebp
f0101ac4:	57                   	push   %edi
f0101ac5:	56                   	push   %esi
f0101ac6:	53                   	push   %ebx
f0101ac7:	83 ec 10             	sub    $0x10,%esp
f0101aca:	89 c6                	mov    %eax,%esi
f0101acc:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0101acf:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0101ad2:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0101ad5:	8b 1a                	mov    (%edx),%ebx
f0101ad7:	8b 01                	mov    (%ecx),%eax
f0101ad9:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101adc:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0101ae3:	eb 77                	jmp    f0101b5c <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0101ae5:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101ae8:	01 d8                	add    %ebx,%eax
f0101aea:	b9 02 00 00 00       	mov    $0x2,%ecx
f0101aef:	99                   	cltd   
f0101af0:	f7 f9                	idiv   %ecx
f0101af2:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0101af4:	eb 01                	jmp    f0101af7 <stab_binsearch+0x36>
			m--;
f0101af6:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0101af7:	39 d9                	cmp    %ebx,%ecx
f0101af9:	7c 1d                	jl     f0101b18 <stab_binsearch+0x57>
f0101afb:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0101afe:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0101b03:	39 fa                	cmp    %edi,%edx
f0101b05:	75 ef                	jne    f0101af6 <stab_binsearch+0x35>
f0101b07:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0101b0a:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0101b0d:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0101b11:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0101b14:	73 18                	jae    f0101b2e <stab_binsearch+0x6d>
f0101b16:	eb 05                	jmp    f0101b1d <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0101b18:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0101b1b:	eb 3f                	jmp    f0101b5c <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0101b1d:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0101b20:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0101b22:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0101b25:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0101b2c:	eb 2e                	jmp    f0101b5c <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0101b2e:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0101b31:	73 15                	jae    f0101b48 <stab_binsearch+0x87>
			*region_right = m - 1;
f0101b33:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101b36:	48                   	dec    %eax
f0101b37:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101b3a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101b3d:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0101b3f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0101b46:	eb 14                	jmp    f0101b5c <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0101b48:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101b4b:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0101b4e:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0101b50:	ff 45 0c             	incl   0xc(%ebp)
f0101b53:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0101b55:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0101b5c:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0101b5f:	7e 84                	jle    f0101ae5 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0101b61:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0101b65:	75 0d                	jne    f0101b74 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0101b67:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101b6a:	8b 00                	mov    (%eax),%eax
f0101b6c:	48                   	dec    %eax
f0101b6d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101b70:	89 07                	mov    %eax,(%edi)
f0101b72:	eb 22                	jmp    f0101b96 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101b74:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101b77:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0101b79:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0101b7c:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101b7e:	eb 01                	jmp    f0101b81 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0101b80:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101b81:	39 c1                	cmp    %eax,%ecx
f0101b83:	7d 0c                	jge    f0101b91 <stab_binsearch+0xd0>
f0101b85:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0101b88:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0101b8d:	39 fa                	cmp    %edi,%edx
f0101b8f:	75 ef                	jne    f0101b80 <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0101b91:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0101b94:	89 07                	mov    %eax,(%edi)
	}
}
f0101b96:	83 c4 10             	add    $0x10,%esp
f0101b99:	5b                   	pop    %ebx
f0101b9a:	5e                   	pop    %esi
f0101b9b:	5f                   	pop    %edi
f0101b9c:	5d                   	pop    %ebp
f0101b9d:	c3                   	ret    

f0101b9e <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0101b9e:	55                   	push   %ebp
f0101b9f:	89 e5                	mov    %esp,%ebp
f0101ba1:	57                   	push   %edi
f0101ba2:	56                   	push   %esi
f0101ba3:	53                   	push   %ebx
f0101ba4:	83 ec 3c             	sub    $0x3c,%esp
f0101ba7:	8b 75 08             	mov    0x8(%ebp),%esi
f0101baa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0101bad:	c7 03 e1 34 10 f0    	movl   $0xf01034e1,(%ebx)
	info->eip_line = 0;
f0101bb3:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0101bba:	c7 43 08 e1 34 10 f0 	movl   $0xf01034e1,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0101bc1:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0101bc8:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0101bcb:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0101bd2:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0101bd8:	76 12                	jbe    f0101bec <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101bda:	b8 15 a6 10 f0       	mov    $0xf010a615,%eax
f0101bdf:	3d 79 88 10 f0       	cmp    $0xf0108879,%eax
f0101be4:	0f 86 cd 01 00 00    	jbe    f0101db7 <debuginfo_eip+0x219>
f0101bea:	eb 1c                	jmp    f0101c08 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0101bec:	c7 44 24 08 eb 34 10 	movl   $0xf01034eb,0x8(%esp)
f0101bf3:	f0 
f0101bf4:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0101bfb:	00 
f0101bfc:	c7 04 24 f8 34 10 f0 	movl   $0xf01034f8,(%esp)
f0101c03:	e8 19 e5 ff ff       	call   f0100121 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101c08:	80 3d 14 a6 10 f0 00 	cmpb   $0x0,0xf010a614
f0101c0f:	0f 85 a9 01 00 00    	jne    f0101dbe <debuginfo_eip+0x220>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0101c15:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0101c1c:	b8 78 88 10 f0       	mov    $0xf0108878,%eax
f0101c21:	2d 30 37 10 f0       	sub    $0xf0103730,%eax
f0101c26:	c1 f8 02             	sar    $0x2,%eax
f0101c29:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0101c2f:	83 e8 01             	sub    $0x1,%eax
f0101c32:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0101c35:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101c39:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0101c40:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0101c43:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0101c46:	b8 30 37 10 f0       	mov    $0xf0103730,%eax
f0101c4b:	e8 71 fe ff ff       	call   f0101ac1 <stab_binsearch>
	if (lfile == 0)
f0101c50:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101c53:	85 c0                	test   %eax,%eax
f0101c55:	0f 84 6a 01 00 00    	je     f0101dc5 <debuginfo_eip+0x227>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0101c5b:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0101c5e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101c61:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0101c64:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101c68:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0101c6f:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0101c72:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0101c75:	b8 30 37 10 f0       	mov    $0xf0103730,%eax
f0101c7a:	e8 42 fe ff ff       	call   f0101ac1 <stab_binsearch>

	if (lfun <= rfun) {
f0101c7f:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101c82:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101c85:	39 d0                	cmp    %edx,%eax
f0101c87:	7f 3d                	jg     f0101cc6 <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0101c89:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0101c8c:	8d b9 30 37 10 f0    	lea    -0xfefc8d0(%ecx),%edi
f0101c92:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0101c95:	8b 89 30 37 10 f0    	mov    -0xfefc8d0(%ecx),%ecx
f0101c9b:	bf 15 a6 10 f0       	mov    $0xf010a615,%edi
f0101ca0:	81 ef 79 88 10 f0    	sub    $0xf0108879,%edi
f0101ca6:	39 f9                	cmp    %edi,%ecx
f0101ca8:	73 09                	jae    f0101cb3 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0101caa:	81 c1 79 88 10 f0    	add    $0xf0108879,%ecx
f0101cb0:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0101cb3:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0101cb6:	8b 4f 08             	mov    0x8(%edi),%ecx
f0101cb9:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0101cbc:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0101cbe:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0101cc1:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101cc4:	eb 0f                	jmp    f0101cd5 <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0101cc6:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0101cc9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101ccc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0101ccf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101cd2:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0101cd5:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0101cdc:	00 
f0101cdd:	8b 43 08             	mov    0x8(%ebx),%eax
f0101ce0:	89 04 24             	mov    %eax,(%esp)
f0101ce3:	e8 03 09 00 00       	call   f01025eb <strfind>
f0101ce8:	2b 43 08             	sub    0x8(%ebx),%eax
f0101ceb:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
f0101cee:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101cf2:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0101cf9:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0101cfc:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0101cff:	b8 30 37 10 f0       	mov    $0xf0103730,%eax
f0101d04:	e8 b8 fd ff ff       	call   f0101ac1 <stab_binsearch>
	if (lline > rline) {
f0101d09:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d0c:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0101d0f:	0f 8f b7 00 00 00    	jg     f0101dcc <debuginfo_eip+0x22e>
		return -1; //Did not find the line number in the stab
	}
	info->eip_line = stabs[lline].n_desc; //If found update the info object with the correct line number
f0101d15:	6b c0 0c             	imul   $0xc,%eax,%eax
f0101d18:	0f b7 80 36 37 10 f0 	movzwl -0xfefc8ca(%eax),%eax
f0101d1f:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0101d22:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101d25:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0101d28:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d2b:	6b d0 0c             	imul   $0xc,%eax,%edx
f0101d2e:	81 c2 30 37 10 f0    	add    $0xf0103730,%edx
f0101d34:	eb 06                	jmp    f0101d3c <debuginfo_eip+0x19e>
f0101d36:	83 e8 01             	sub    $0x1,%eax
f0101d39:	83 ea 0c             	sub    $0xc,%edx
f0101d3c:	89 c6                	mov    %eax,%esi
f0101d3e:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0101d41:	7f 33                	jg     f0101d76 <debuginfo_eip+0x1d8>
	       && stabs[lline].n_type != N_SOL
f0101d43:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0101d47:	80 f9 84             	cmp    $0x84,%cl
f0101d4a:	74 0b                	je     f0101d57 <debuginfo_eip+0x1b9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0101d4c:	80 f9 64             	cmp    $0x64,%cl
f0101d4f:	75 e5                	jne    f0101d36 <debuginfo_eip+0x198>
f0101d51:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0101d55:	74 df                	je     f0101d36 <debuginfo_eip+0x198>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0101d57:	6b f6 0c             	imul   $0xc,%esi,%esi
f0101d5a:	8b 86 30 37 10 f0    	mov    -0xfefc8d0(%esi),%eax
f0101d60:	ba 15 a6 10 f0       	mov    $0xf010a615,%edx
f0101d65:	81 ea 79 88 10 f0    	sub    $0xf0108879,%edx
f0101d6b:	39 d0                	cmp    %edx,%eax
f0101d6d:	73 07                	jae    f0101d76 <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0101d6f:	05 79 88 10 f0       	add    $0xf0108879,%eax
f0101d74:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0101d76:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101d79:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101d7c:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0101d81:	39 ca                	cmp    %ecx,%edx
f0101d83:	7d 53                	jge    f0101dd8 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
f0101d85:	8d 42 01             	lea    0x1(%edx),%eax
f0101d88:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101d8b:	89 c2                	mov    %eax,%edx
f0101d8d:	6b c0 0c             	imul   $0xc,%eax,%eax
f0101d90:	05 30 37 10 f0       	add    $0xf0103730,%eax
f0101d95:	89 ce                	mov    %ecx,%esi
f0101d97:	eb 04                	jmp    f0101d9d <debuginfo_eip+0x1ff>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0101d99:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0101d9d:	39 d6                	cmp    %edx,%esi
f0101d9f:	7e 32                	jle    f0101dd3 <debuginfo_eip+0x235>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0101da1:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0101da5:	83 c2 01             	add    $0x1,%edx
f0101da8:	83 c0 0c             	add    $0xc,%eax
f0101dab:	80 f9 a0             	cmp    $0xa0,%cl
f0101dae:	74 e9                	je     f0101d99 <debuginfo_eip+0x1fb>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101db0:	b8 00 00 00 00       	mov    $0x0,%eax
f0101db5:	eb 21                	jmp    f0101dd8 <debuginfo_eip+0x23a>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0101db7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101dbc:	eb 1a                	jmp    f0101dd8 <debuginfo_eip+0x23a>
f0101dbe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101dc3:	eb 13                	jmp    f0101dd8 <debuginfo_eip+0x23a>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0101dc5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101dca:	eb 0c                	jmp    f0101dd8 <debuginfo_eip+0x23a>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
	if (lline > rline) {
		return -1; //Did not find the line number in the stab
f0101dcc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101dd1:	eb 05                	jmp    f0101dd8 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101dd3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101dd8:	83 c4 3c             	add    $0x3c,%esp
f0101ddb:	5b                   	pop    %ebx
f0101ddc:	5e                   	pop    %esi
f0101ddd:	5f                   	pop    %edi
f0101dde:	5d                   	pop    %ebp
f0101ddf:	c3                   	ret    

f0101de0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0101de0:	55                   	push   %ebp
f0101de1:	89 e5                	mov    %esp,%ebp
f0101de3:	57                   	push   %edi
f0101de4:	56                   	push   %esi
f0101de5:	53                   	push   %ebx
f0101de6:	83 ec 3c             	sub    $0x3c,%esp
f0101de9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101dec:	89 d7                	mov    %edx,%edi
f0101dee:	8b 45 08             	mov    0x8(%ebp),%eax
f0101df1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101df4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101df7:	89 c3                	mov    %eax,%ebx
f0101df9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101dfc:	8b 45 10             	mov    0x10(%ebp),%eax
f0101dff:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0101e02:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101e07:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101e0a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101e0d:	39 d9                	cmp    %ebx,%ecx
f0101e0f:	72 05                	jb     f0101e16 <printnum+0x36>
f0101e11:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0101e14:	77 69                	ja     f0101e7f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0101e16:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0101e19:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101e1d:	83 ee 01             	sub    $0x1,%esi
f0101e20:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0101e24:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101e28:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101e2c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101e30:	89 c3                	mov    %eax,%ebx
f0101e32:	89 d6                	mov    %edx,%esi
f0101e34:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101e37:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101e3a:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101e3e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0101e42:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101e45:	89 04 24             	mov    %eax,(%esp)
f0101e48:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e4b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101e4f:	e8 bc 09 00 00       	call   f0102810 <__udivdi3>
f0101e54:	89 d9                	mov    %ebx,%ecx
f0101e56:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101e5a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0101e5e:	89 04 24             	mov    %eax,(%esp)
f0101e61:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101e65:	89 fa                	mov    %edi,%edx
f0101e67:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101e6a:	e8 71 ff ff ff       	call   f0101de0 <printnum>
f0101e6f:	eb 1b                	jmp    f0101e8c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0101e71:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101e75:	8b 45 18             	mov    0x18(%ebp),%eax
f0101e78:	89 04 24             	mov    %eax,(%esp)
f0101e7b:	ff d3                	call   *%ebx
f0101e7d:	eb 03                	jmp    f0101e82 <printnum+0xa2>
f0101e7f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0101e82:	83 ee 01             	sub    $0x1,%esi
f0101e85:	85 f6                	test   %esi,%esi
f0101e87:	7f e8                	jg     f0101e71 <printnum+0x91>
f0101e89:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0101e8c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101e90:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101e94:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101e97:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101e9a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101e9e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101ea2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101ea5:	89 04 24             	mov    %eax,(%esp)
f0101ea8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101eab:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101eaf:	e8 8c 0a 00 00       	call   f0102940 <__umoddi3>
f0101eb4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101eb8:	0f be 80 06 35 10 f0 	movsbl -0xfefcafa(%eax),%eax
f0101ebf:	89 04 24             	mov    %eax,(%esp)
f0101ec2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101ec5:	ff d0                	call   *%eax
}
f0101ec7:	83 c4 3c             	add    $0x3c,%esp
f0101eca:	5b                   	pop    %ebx
f0101ecb:	5e                   	pop    %esi
f0101ecc:	5f                   	pop    %edi
f0101ecd:	5d                   	pop    %ebp
f0101ece:	c3                   	ret    

f0101ecf <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0101ecf:	55                   	push   %ebp
f0101ed0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0101ed2:	83 fa 01             	cmp    $0x1,%edx
f0101ed5:	7e 0e                	jle    f0101ee5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0101ed7:	8b 10                	mov    (%eax),%edx
f0101ed9:	8d 4a 08             	lea    0x8(%edx),%ecx
f0101edc:	89 08                	mov    %ecx,(%eax)
f0101ede:	8b 02                	mov    (%edx),%eax
f0101ee0:	8b 52 04             	mov    0x4(%edx),%edx
f0101ee3:	eb 22                	jmp    f0101f07 <getuint+0x38>
	else if (lflag)
f0101ee5:	85 d2                	test   %edx,%edx
f0101ee7:	74 10                	je     f0101ef9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0101ee9:	8b 10                	mov    (%eax),%edx
f0101eeb:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101eee:	89 08                	mov    %ecx,(%eax)
f0101ef0:	8b 02                	mov    (%edx),%eax
f0101ef2:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ef7:	eb 0e                	jmp    f0101f07 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0101ef9:	8b 10                	mov    (%eax),%edx
f0101efb:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101efe:	89 08                	mov    %ecx,(%eax)
f0101f00:	8b 02                	mov    (%edx),%eax
f0101f02:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0101f07:	5d                   	pop    %ebp
f0101f08:	c3                   	ret    

f0101f09 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0101f09:	55                   	push   %ebp
f0101f0a:	89 e5                	mov    %esp,%ebp
f0101f0c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0101f0f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0101f13:	8b 10                	mov    (%eax),%edx
f0101f15:	3b 50 04             	cmp    0x4(%eax),%edx
f0101f18:	73 0a                	jae    f0101f24 <sprintputch+0x1b>
		*b->buf++ = ch;
f0101f1a:	8d 4a 01             	lea    0x1(%edx),%ecx
f0101f1d:	89 08                	mov    %ecx,(%eax)
f0101f1f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f22:	88 02                	mov    %al,(%edx)
}
f0101f24:	5d                   	pop    %ebp
f0101f25:	c3                   	ret    

f0101f26 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0101f26:	55                   	push   %ebp
f0101f27:	89 e5                	mov    %esp,%ebp
f0101f29:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0101f2c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0101f2f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101f33:	8b 45 10             	mov    0x10(%ebp),%eax
f0101f36:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101f3a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101f3d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101f41:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f44:	89 04 24             	mov    %eax,(%esp)
f0101f47:	e8 02 00 00 00       	call   f0101f4e <vprintfmt>
	va_end(ap);
}
f0101f4c:	c9                   	leave  
f0101f4d:	c3                   	ret    

f0101f4e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0101f4e:	55                   	push   %ebp
f0101f4f:	89 e5                	mov    %esp,%ebp
f0101f51:	57                   	push   %edi
f0101f52:	56                   	push   %esi
f0101f53:	53                   	push   %ebx
f0101f54:	83 ec 3c             	sub    $0x3c,%esp
f0101f57:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101f5a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0101f5d:	eb 14                	jmp    f0101f73 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0101f5f:	85 c0                	test   %eax,%eax
f0101f61:	0f 84 b3 03 00 00    	je     f010231a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0101f67:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101f6b:	89 04 24             	mov    %eax,(%esp)
f0101f6e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101f71:	89 f3                	mov    %esi,%ebx
f0101f73:	8d 73 01             	lea    0x1(%ebx),%esi
f0101f76:	0f b6 03             	movzbl (%ebx),%eax
f0101f79:	83 f8 25             	cmp    $0x25,%eax
f0101f7c:	75 e1                	jne    f0101f5f <vprintfmt+0x11>
f0101f7e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0101f82:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0101f89:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0101f90:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0101f97:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f9c:	eb 1d                	jmp    f0101fbb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101f9e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0101fa0:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0101fa4:	eb 15                	jmp    f0101fbb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101fa6:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0101fa8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0101fac:	eb 0d                	jmp    f0101fbb <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0101fae:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fb1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101fb4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101fbb:	8d 5e 01             	lea    0x1(%esi),%ebx
f0101fbe:	0f b6 0e             	movzbl (%esi),%ecx
f0101fc1:	0f b6 c1             	movzbl %cl,%eax
f0101fc4:	83 e9 23             	sub    $0x23,%ecx
f0101fc7:	80 f9 55             	cmp    $0x55,%cl
f0101fca:	0f 87 2a 03 00 00    	ja     f01022fa <vprintfmt+0x3ac>
f0101fd0:	0f b6 c9             	movzbl %cl,%ecx
f0101fd3:	ff 24 8d a0 35 10 f0 	jmp    *-0xfefca60(,%ecx,4)
f0101fda:	89 de                	mov    %ebx,%esi
f0101fdc:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0101fe1:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0101fe4:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0101fe8:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0101feb:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0101fee:	83 fb 09             	cmp    $0x9,%ebx
f0101ff1:	77 36                	ja     f0102029 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0101ff3:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0101ff6:	eb e9                	jmp    f0101fe1 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0101ff8:	8b 45 14             	mov    0x14(%ebp),%eax
f0101ffb:	8d 48 04             	lea    0x4(%eax),%ecx
f0101ffe:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102001:	8b 00                	mov    (%eax),%eax
f0102003:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102006:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102008:	eb 22                	jmp    f010202c <vprintfmt+0xde>
f010200a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010200d:	85 c9                	test   %ecx,%ecx
f010200f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102014:	0f 49 c1             	cmovns %ecx,%eax
f0102017:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010201a:	89 de                	mov    %ebx,%esi
f010201c:	eb 9d                	jmp    f0101fbb <vprintfmt+0x6d>
f010201e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102020:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0102027:	eb 92                	jmp    f0101fbb <vprintfmt+0x6d>
f0102029:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f010202c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102030:	79 89                	jns    f0101fbb <vprintfmt+0x6d>
f0102032:	e9 77 ff ff ff       	jmp    f0101fae <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102037:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010203a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010203c:	e9 7a ff ff ff       	jmp    f0101fbb <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102041:	8b 45 14             	mov    0x14(%ebp),%eax
f0102044:	8d 50 04             	lea    0x4(%eax),%edx
f0102047:	89 55 14             	mov    %edx,0x14(%ebp)
f010204a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010204e:	8b 00                	mov    (%eax),%eax
f0102050:	89 04 24             	mov    %eax,(%esp)
f0102053:	ff 55 08             	call   *0x8(%ebp)
			break;
f0102056:	e9 18 ff ff ff       	jmp    f0101f73 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010205b:	8b 45 14             	mov    0x14(%ebp),%eax
f010205e:	8d 50 04             	lea    0x4(%eax),%edx
f0102061:	89 55 14             	mov    %edx,0x14(%ebp)
f0102064:	8b 00                	mov    (%eax),%eax
f0102066:	99                   	cltd   
f0102067:	31 d0                	xor    %edx,%eax
f0102069:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010206b:	83 f8 07             	cmp    $0x7,%eax
f010206e:	7f 0b                	jg     f010207b <vprintfmt+0x12d>
f0102070:	8b 14 85 00 37 10 f0 	mov    -0xfefc900(,%eax,4),%edx
f0102077:	85 d2                	test   %edx,%edx
f0102079:	75 20                	jne    f010209b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f010207b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010207f:	c7 44 24 08 1e 35 10 	movl   $0xf010351e,0x8(%esp)
f0102086:	f0 
f0102087:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010208b:	8b 45 08             	mov    0x8(%ebp),%eax
f010208e:	89 04 24             	mov    %eax,(%esp)
f0102091:	e8 90 fe ff ff       	call   f0101f26 <printfmt>
f0102096:	e9 d8 fe ff ff       	jmp    f0101f73 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f010209b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010209f:	c7 44 24 08 34 33 10 	movl   $0xf0103334,0x8(%esp)
f01020a6:	f0 
f01020a7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01020ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01020ae:	89 04 24             	mov    %eax,(%esp)
f01020b1:	e8 70 fe ff ff       	call   f0101f26 <printfmt>
f01020b6:	e9 b8 fe ff ff       	jmp    f0101f73 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01020bb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01020be:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01020c1:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01020c4:	8b 45 14             	mov    0x14(%ebp),%eax
f01020c7:	8d 50 04             	lea    0x4(%eax),%edx
f01020ca:	89 55 14             	mov    %edx,0x14(%ebp)
f01020cd:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f01020cf:	85 f6                	test   %esi,%esi
f01020d1:	b8 17 35 10 f0       	mov    $0xf0103517,%eax
f01020d6:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f01020d9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f01020dd:	0f 84 97 00 00 00    	je     f010217a <vprintfmt+0x22c>
f01020e3:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01020e7:	0f 8e 9b 00 00 00    	jle    f0102188 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f01020ed:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01020f1:	89 34 24             	mov    %esi,(%esp)
f01020f4:	e8 9f 03 00 00       	call   f0102498 <strnlen>
f01020f9:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01020fc:	29 c2                	sub    %eax,%edx
f01020fe:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0102101:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0102105:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0102108:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010210b:	8b 75 08             	mov    0x8(%ebp),%esi
f010210e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0102111:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102113:	eb 0f                	jmp    f0102124 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0102115:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102119:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010211c:	89 04 24             	mov    %eax,(%esp)
f010211f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102121:	83 eb 01             	sub    $0x1,%ebx
f0102124:	85 db                	test   %ebx,%ebx
f0102126:	7f ed                	jg     f0102115 <vprintfmt+0x1c7>
f0102128:	8b 75 d8             	mov    -0x28(%ebp),%esi
f010212b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010212e:	85 d2                	test   %edx,%edx
f0102130:	b8 00 00 00 00       	mov    $0x0,%eax
f0102135:	0f 49 c2             	cmovns %edx,%eax
f0102138:	29 c2                	sub    %eax,%edx
f010213a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010213d:	89 d7                	mov    %edx,%edi
f010213f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102142:	eb 50                	jmp    f0102194 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102144:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102148:	74 1e                	je     f0102168 <vprintfmt+0x21a>
f010214a:	0f be d2             	movsbl %dl,%edx
f010214d:	83 ea 20             	sub    $0x20,%edx
f0102150:	83 fa 5e             	cmp    $0x5e,%edx
f0102153:	76 13                	jbe    f0102168 <vprintfmt+0x21a>
					putch('?', putdat);
f0102155:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102158:	89 44 24 04          	mov    %eax,0x4(%esp)
f010215c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0102163:	ff 55 08             	call   *0x8(%ebp)
f0102166:	eb 0d                	jmp    f0102175 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0102168:	8b 55 0c             	mov    0xc(%ebp),%edx
f010216b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010216f:	89 04 24             	mov    %eax,(%esp)
f0102172:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102175:	83 ef 01             	sub    $0x1,%edi
f0102178:	eb 1a                	jmp    f0102194 <vprintfmt+0x246>
f010217a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010217d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0102180:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0102183:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102186:	eb 0c                	jmp    f0102194 <vprintfmt+0x246>
f0102188:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010218b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f010218e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0102191:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102194:	83 c6 01             	add    $0x1,%esi
f0102197:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f010219b:	0f be c2             	movsbl %dl,%eax
f010219e:	85 c0                	test   %eax,%eax
f01021a0:	74 27                	je     f01021c9 <vprintfmt+0x27b>
f01021a2:	85 db                	test   %ebx,%ebx
f01021a4:	78 9e                	js     f0102144 <vprintfmt+0x1f6>
f01021a6:	83 eb 01             	sub    $0x1,%ebx
f01021a9:	79 99                	jns    f0102144 <vprintfmt+0x1f6>
f01021ab:	89 f8                	mov    %edi,%eax
f01021ad:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01021b0:	8b 75 08             	mov    0x8(%ebp),%esi
f01021b3:	89 c3                	mov    %eax,%ebx
f01021b5:	eb 1a                	jmp    f01021d1 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01021b7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01021bb:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01021c2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01021c4:	83 eb 01             	sub    $0x1,%ebx
f01021c7:	eb 08                	jmp    f01021d1 <vprintfmt+0x283>
f01021c9:	89 fb                	mov    %edi,%ebx
f01021cb:	8b 75 08             	mov    0x8(%ebp),%esi
f01021ce:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01021d1:	85 db                	test   %ebx,%ebx
f01021d3:	7f e2                	jg     f01021b7 <vprintfmt+0x269>
f01021d5:	89 75 08             	mov    %esi,0x8(%ebp)
f01021d8:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01021db:	e9 93 fd ff ff       	jmp    f0101f73 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01021e0:	83 fa 01             	cmp    $0x1,%edx
f01021e3:	7e 16                	jle    f01021fb <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f01021e5:	8b 45 14             	mov    0x14(%ebp),%eax
f01021e8:	8d 50 08             	lea    0x8(%eax),%edx
f01021eb:	89 55 14             	mov    %edx,0x14(%ebp)
f01021ee:	8b 50 04             	mov    0x4(%eax),%edx
f01021f1:	8b 00                	mov    (%eax),%eax
f01021f3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01021f6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01021f9:	eb 32                	jmp    f010222d <vprintfmt+0x2df>
	else if (lflag)
f01021fb:	85 d2                	test   %edx,%edx
f01021fd:	74 18                	je     f0102217 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f01021ff:	8b 45 14             	mov    0x14(%ebp),%eax
f0102202:	8d 50 04             	lea    0x4(%eax),%edx
f0102205:	89 55 14             	mov    %edx,0x14(%ebp)
f0102208:	8b 30                	mov    (%eax),%esi
f010220a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010220d:	89 f0                	mov    %esi,%eax
f010220f:	c1 f8 1f             	sar    $0x1f,%eax
f0102212:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102215:	eb 16                	jmp    f010222d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0102217:	8b 45 14             	mov    0x14(%ebp),%eax
f010221a:	8d 50 04             	lea    0x4(%eax),%edx
f010221d:	89 55 14             	mov    %edx,0x14(%ebp)
f0102220:	8b 30                	mov    (%eax),%esi
f0102222:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0102225:	89 f0                	mov    %esi,%eax
f0102227:	c1 f8 1f             	sar    $0x1f,%eax
f010222a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010222d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102230:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102233:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102238:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010223c:	0f 89 80 00 00 00    	jns    f01022c2 <vprintfmt+0x374>
				putch('-', putdat);
f0102242:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102246:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010224d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0102250:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102253:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102256:	f7 d8                	neg    %eax
f0102258:	83 d2 00             	adc    $0x0,%edx
f010225b:	f7 da                	neg    %edx
			}
			base = 10;
f010225d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102262:	eb 5e                	jmp    f01022c2 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102264:	8d 45 14             	lea    0x14(%ebp),%eax
f0102267:	e8 63 fc ff ff       	call   f0101ecf <getuint>
			base = 10;
f010226c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102271:	eb 4f                	jmp    f01022c2 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0102273:	8d 45 14             	lea    0x14(%ebp),%eax
f0102276:	e8 54 fc ff ff       	call   f0101ecf <getuint>
			base = 8;
f010227b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0102280:	eb 40                	jmp    f01022c2 <vprintfmt+0x374>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f0102282:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102286:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010228d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0102290:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102294:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010229b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010229e:	8b 45 14             	mov    0x14(%ebp),%eax
f01022a1:	8d 50 04             	lea    0x4(%eax),%edx
f01022a4:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01022a7:	8b 00                	mov    (%eax),%eax
f01022a9:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01022ae:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01022b3:	eb 0d                	jmp    f01022c2 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01022b5:	8d 45 14             	lea    0x14(%ebp),%eax
f01022b8:	e8 12 fc ff ff       	call   f0101ecf <getuint>
			base = 16;
f01022bd:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01022c2:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f01022c6:	89 74 24 10          	mov    %esi,0x10(%esp)
f01022ca:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01022cd:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01022d1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01022d5:	89 04 24             	mov    %eax,(%esp)
f01022d8:	89 54 24 04          	mov    %edx,0x4(%esp)
f01022dc:	89 fa                	mov    %edi,%edx
f01022de:	8b 45 08             	mov    0x8(%ebp),%eax
f01022e1:	e8 fa fa ff ff       	call   f0101de0 <printnum>
			break;
f01022e6:	e9 88 fc ff ff       	jmp    f0101f73 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01022eb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01022ef:	89 04 24             	mov    %eax,(%esp)
f01022f2:	ff 55 08             	call   *0x8(%ebp)
			break;
f01022f5:	e9 79 fc ff ff       	jmp    f0101f73 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01022fa:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01022fe:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0102305:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102308:	89 f3                	mov    %esi,%ebx
f010230a:	eb 03                	jmp    f010230f <vprintfmt+0x3c1>
f010230c:	83 eb 01             	sub    $0x1,%ebx
f010230f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0102313:	75 f7                	jne    f010230c <vprintfmt+0x3be>
f0102315:	e9 59 fc ff ff       	jmp    f0101f73 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010231a:	83 c4 3c             	add    $0x3c,%esp
f010231d:	5b                   	pop    %ebx
f010231e:	5e                   	pop    %esi
f010231f:	5f                   	pop    %edi
f0102320:	5d                   	pop    %ebp
f0102321:	c3                   	ret    

f0102322 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102322:	55                   	push   %ebp
f0102323:	89 e5                	mov    %esp,%ebp
f0102325:	83 ec 28             	sub    $0x28,%esp
f0102328:	8b 45 08             	mov    0x8(%ebp),%eax
f010232b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010232e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102331:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102335:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102338:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010233f:	85 c0                	test   %eax,%eax
f0102341:	74 30                	je     f0102373 <vsnprintf+0x51>
f0102343:	85 d2                	test   %edx,%edx
f0102345:	7e 2c                	jle    f0102373 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102347:	8b 45 14             	mov    0x14(%ebp),%eax
f010234a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010234e:	8b 45 10             	mov    0x10(%ebp),%eax
f0102351:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102355:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102358:	89 44 24 04          	mov    %eax,0x4(%esp)
f010235c:	c7 04 24 09 1f 10 f0 	movl   $0xf0101f09,(%esp)
f0102363:	e8 e6 fb ff ff       	call   f0101f4e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102368:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010236b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010236e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102371:	eb 05                	jmp    f0102378 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102373:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102378:	c9                   	leave  
f0102379:	c3                   	ret    

f010237a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010237a:	55                   	push   %ebp
f010237b:	89 e5                	mov    %esp,%ebp
f010237d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102380:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102383:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102387:	8b 45 10             	mov    0x10(%ebp),%eax
f010238a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010238e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102391:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102395:	8b 45 08             	mov    0x8(%ebp),%eax
f0102398:	89 04 24             	mov    %eax,(%esp)
f010239b:	e8 82 ff ff ff       	call   f0102322 <vsnprintf>
	va_end(ap);

	return rc;
}
f01023a0:	c9                   	leave  
f01023a1:	c3                   	ret    
f01023a2:	66 90                	xchg   %ax,%ax
f01023a4:	66 90                	xchg   %ax,%ax
f01023a6:	66 90                	xchg   %ax,%ax
f01023a8:	66 90                	xchg   %ax,%ax
f01023aa:	66 90                	xchg   %ax,%ax
f01023ac:	66 90                	xchg   %ax,%ax
f01023ae:	66 90                	xchg   %ax,%ax

f01023b0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01023b0:	55                   	push   %ebp
f01023b1:	89 e5                	mov    %esp,%ebp
f01023b3:	57                   	push   %edi
f01023b4:	56                   	push   %esi
f01023b5:	53                   	push   %ebx
f01023b6:	83 ec 1c             	sub    $0x1c,%esp
f01023b9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01023bc:	85 c0                	test   %eax,%eax
f01023be:	74 10                	je     f01023d0 <readline+0x20>
		cprintf("%s", prompt);
f01023c0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01023c4:	c7 04 24 34 33 10 f0 	movl   $0xf0103334,(%esp)
f01023cb:	e8 d7 f6 ff ff       	call   f0101aa7 <cprintf>

	i = 0;
	echoing = iscons(0);
f01023d0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01023d7:	e8 c6 e2 ff ff       	call   f01006a2 <iscons>
f01023dc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01023de:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01023e3:	e8 a9 e2 ff ff       	call   f0100691 <getchar>
f01023e8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01023ea:	85 c0                	test   %eax,%eax
f01023ec:	79 17                	jns    f0102405 <readline+0x55>
			cprintf("read error: %e\n", c);
f01023ee:	89 44 24 04          	mov    %eax,0x4(%esp)
f01023f2:	c7 04 24 20 37 10 f0 	movl   $0xf0103720,(%esp)
f01023f9:	e8 a9 f6 ff ff       	call   f0101aa7 <cprintf>
			return NULL;
f01023fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0102403:	eb 6d                	jmp    f0102472 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102405:	83 f8 7f             	cmp    $0x7f,%eax
f0102408:	74 05                	je     f010240f <readline+0x5f>
f010240a:	83 f8 08             	cmp    $0x8,%eax
f010240d:	75 19                	jne    f0102428 <readline+0x78>
f010240f:	85 f6                	test   %esi,%esi
f0102411:	7e 15                	jle    f0102428 <readline+0x78>
			if (echoing)
f0102413:	85 ff                	test   %edi,%edi
f0102415:	74 0c                	je     f0102423 <readline+0x73>
				cputchar('\b');
f0102417:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010241e:	e8 5e e2 ff ff       	call   f0100681 <cputchar>
			i--;
f0102423:	83 ee 01             	sub    $0x1,%esi
f0102426:	eb bb                	jmp    f01023e3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102428:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010242e:	7f 1c                	jg     f010244c <readline+0x9c>
f0102430:	83 fb 1f             	cmp    $0x1f,%ebx
f0102433:	7e 17                	jle    f010244c <readline+0x9c>
			if (echoing)
f0102435:	85 ff                	test   %edi,%edi
f0102437:	74 08                	je     f0102441 <readline+0x91>
				cputchar(c);
f0102439:	89 1c 24             	mov    %ebx,(%esp)
f010243c:	e8 40 e2 ff ff       	call   f0100681 <cputchar>
			buf[i++] = c;
f0102441:	88 9e 60 55 11 f0    	mov    %bl,-0xfeeaaa0(%esi)
f0102447:	8d 76 01             	lea    0x1(%esi),%esi
f010244a:	eb 97                	jmp    f01023e3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010244c:	83 fb 0d             	cmp    $0xd,%ebx
f010244f:	74 05                	je     f0102456 <readline+0xa6>
f0102451:	83 fb 0a             	cmp    $0xa,%ebx
f0102454:	75 8d                	jne    f01023e3 <readline+0x33>
			if (echoing)
f0102456:	85 ff                	test   %edi,%edi
f0102458:	74 0c                	je     f0102466 <readline+0xb6>
				cputchar('\n');
f010245a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0102461:	e8 1b e2 ff ff       	call   f0100681 <cputchar>
			buf[i] = 0;
f0102466:	c6 86 60 55 11 f0 00 	movb   $0x0,-0xfeeaaa0(%esi)
			return buf;
f010246d:	b8 60 55 11 f0       	mov    $0xf0115560,%eax
		}
	}
}
f0102472:	83 c4 1c             	add    $0x1c,%esp
f0102475:	5b                   	pop    %ebx
f0102476:	5e                   	pop    %esi
f0102477:	5f                   	pop    %edi
f0102478:	5d                   	pop    %ebp
f0102479:	c3                   	ret    
f010247a:	66 90                	xchg   %ax,%ax
f010247c:	66 90                	xchg   %ax,%ax
f010247e:	66 90                	xchg   %ax,%ax

f0102480 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0102480:	55                   	push   %ebp
f0102481:	89 e5                	mov    %esp,%ebp
f0102483:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0102486:	b8 00 00 00 00       	mov    $0x0,%eax
f010248b:	eb 03                	jmp    f0102490 <strlen+0x10>
		n++;
f010248d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0102490:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0102494:	75 f7                	jne    f010248d <strlen+0xd>
		n++;
	return n;
}
f0102496:	5d                   	pop    %ebp
f0102497:	c3                   	ret    

f0102498 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0102498:	55                   	push   %ebp
f0102499:	89 e5                	mov    %esp,%ebp
f010249b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010249e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01024a1:	b8 00 00 00 00       	mov    $0x0,%eax
f01024a6:	eb 03                	jmp    f01024ab <strnlen+0x13>
		n++;
f01024a8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01024ab:	39 d0                	cmp    %edx,%eax
f01024ad:	74 06                	je     f01024b5 <strnlen+0x1d>
f01024af:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01024b3:	75 f3                	jne    f01024a8 <strnlen+0x10>
		n++;
	return n;
}
f01024b5:	5d                   	pop    %ebp
f01024b6:	c3                   	ret    

f01024b7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01024b7:	55                   	push   %ebp
f01024b8:	89 e5                	mov    %esp,%ebp
f01024ba:	53                   	push   %ebx
f01024bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01024be:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01024c1:	89 c2                	mov    %eax,%edx
f01024c3:	83 c2 01             	add    $0x1,%edx
f01024c6:	83 c1 01             	add    $0x1,%ecx
f01024c9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01024cd:	88 5a ff             	mov    %bl,-0x1(%edx)
f01024d0:	84 db                	test   %bl,%bl
f01024d2:	75 ef                	jne    f01024c3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01024d4:	5b                   	pop    %ebx
f01024d5:	5d                   	pop    %ebp
f01024d6:	c3                   	ret    

f01024d7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01024d7:	55                   	push   %ebp
f01024d8:	89 e5                	mov    %esp,%ebp
f01024da:	53                   	push   %ebx
f01024db:	83 ec 08             	sub    $0x8,%esp
f01024de:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01024e1:	89 1c 24             	mov    %ebx,(%esp)
f01024e4:	e8 97 ff ff ff       	call   f0102480 <strlen>
	strcpy(dst + len, src);
f01024e9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01024ec:	89 54 24 04          	mov    %edx,0x4(%esp)
f01024f0:	01 d8                	add    %ebx,%eax
f01024f2:	89 04 24             	mov    %eax,(%esp)
f01024f5:	e8 bd ff ff ff       	call   f01024b7 <strcpy>
	return dst;
}
f01024fa:	89 d8                	mov    %ebx,%eax
f01024fc:	83 c4 08             	add    $0x8,%esp
f01024ff:	5b                   	pop    %ebx
f0102500:	5d                   	pop    %ebp
f0102501:	c3                   	ret    

f0102502 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0102502:	55                   	push   %ebp
f0102503:	89 e5                	mov    %esp,%ebp
f0102505:	56                   	push   %esi
f0102506:	53                   	push   %ebx
f0102507:	8b 75 08             	mov    0x8(%ebp),%esi
f010250a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010250d:	89 f3                	mov    %esi,%ebx
f010250f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0102512:	89 f2                	mov    %esi,%edx
f0102514:	eb 0f                	jmp    f0102525 <strncpy+0x23>
		*dst++ = *src;
f0102516:	83 c2 01             	add    $0x1,%edx
f0102519:	0f b6 01             	movzbl (%ecx),%eax
f010251c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010251f:	80 39 01             	cmpb   $0x1,(%ecx)
f0102522:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0102525:	39 da                	cmp    %ebx,%edx
f0102527:	75 ed                	jne    f0102516 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0102529:	89 f0                	mov    %esi,%eax
f010252b:	5b                   	pop    %ebx
f010252c:	5e                   	pop    %esi
f010252d:	5d                   	pop    %ebp
f010252e:	c3                   	ret    

f010252f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010252f:	55                   	push   %ebp
f0102530:	89 e5                	mov    %esp,%ebp
f0102532:	56                   	push   %esi
f0102533:	53                   	push   %ebx
f0102534:	8b 75 08             	mov    0x8(%ebp),%esi
f0102537:	8b 55 0c             	mov    0xc(%ebp),%edx
f010253a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010253d:	89 f0                	mov    %esi,%eax
f010253f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0102543:	85 c9                	test   %ecx,%ecx
f0102545:	75 0b                	jne    f0102552 <strlcpy+0x23>
f0102547:	eb 1d                	jmp    f0102566 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0102549:	83 c0 01             	add    $0x1,%eax
f010254c:	83 c2 01             	add    $0x1,%edx
f010254f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0102552:	39 d8                	cmp    %ebx,%eax
f0102554:	74 0b                	je     f0102561 <strlcpy+0x32>
f0102556:	0f b6 0a             	movzbl (%edx),%ecx
f0102559:	84 c9                	test   %cl,%cl
f010255b:	75 ec                	jne    f0102549 <strlcpy+0x1a>
f010255d:	89 c2                	mov    %eax,%edx
f010255f:	eb 02                	jmp    f0102563 <strlcpy+0x34>
f0102561:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0102563:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0102566:	29 f0                	sub    %esi,%eax
}
f0102568:	5b                   	pop    %ebx
f0102569:	5e                   	pop    %esi
f010256a:	5d                   	pop    %ebp
f010256b:	c3                   	ret    

f010256c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010256c:	55                   	push   %ebp
f010256d:	89 e5                	mov    %esp,%ebp
f010256f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102572:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0102575:	eb 06                	jmp    f010257d <strcmp+0x11>
		p++, q++;
f0102577:	83 c1 01             	add    $0x1,%ecx
f010257a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010257d:	0f b6 01             	movzbl (%ecx),%eax
f0102580:	84 c0                	test   %al,%al
f0102582:	74 04                	je     f0102588 <strcmp+0x1c>
f0102584:	3a 02                	cmp    (%edx),%al
f0102586:	74 ef                	je     f0102577 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0102588:	0f b6 c0             	movzbl %al,%eax
f010258b:	0f b6 12             	movzbl (%edx),%edx
f010258e:	29 d0                	sub    %edx,%eax
}
f0102590:	5d                   	pop    %ebp
f0102591:	c3                   	ret    

f0102592 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0102592:	55                   	push   %ebp
f0102593:	89 e5                	mov    %esp,%ebp
f0102595:	53                   	push   %ebx
f0102596:	8b 45 08             	mov    0x8(%ebp),%eax
f0102599:	8b 55 0c             	mov    0xc(%ebp),%edx
f010259c:	89 c3                	mov    %eax,%ebx
f010259e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01025a1:	eb 06                	jmp    f01025a9 <strncmp+0x17>
		n--, p++, q++;
f01025a3:	83 c0 01             	add    $0x1,%eax
f01025a6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01025a9:	39 d8                	cmp    %ebx,%eax
f01025ab:	74 15                	je     f01025c2 <strncmp+0x30>
f01025ad:	0f b6 08             	movzbl (%eax),%ecx
f01025b0:	84 c9                	test   %cl,%cl
f01025b2:	74 04                	je     f01025b8 <strncmp+0x26>
f01025b4:	3a 0a                	cmp    (%edx),%cl
f01025b6:	74 eb                	je     f01025a3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01025b8:	0f b6 00             	movzbl (%eax),%eax
f01025bb:	0f b6 12             	movzbl (%edx),%edx
f01025be:	29 d0                	sub    %edx,%eax
f01025c0:	eb 05                	jmp    f01025c7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01025c2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01025c7:	5b                   	pop    %ebx
f01025c8:	5d                   	pop    %ebp
f01025c9:	c3                   	ret    

f01025ca <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01025ca:	55                   	push   %ebp
f01025cb:	89 e5                	mov    %esp,%ebp
f01025cd:	8b 45 08             	mov    0x8(%ebp),%eax
f01025d0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01025d4:	eb 07                	jmp    f01025dd <strchr+0x13>
		if (*s == c)
f01025d6:	38 ca                	cmp    %cl,%dl
f01025d8:	74 0f                	je     f01025e9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01025da:	83 c0 01             	add    $0x1,%eax
f01025dd:	0f b6 10             	movzbl (%eax),%edx
f01025e0:	84 d2                	test   %dl,%dl
f01025e2:	75 f2                	jne    f01025d6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01025e4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01025e9:	5d                   	pop    %ebp
f01025ea:	c3                   	ret    

f01025eb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01025eb:	55                   	push   %ebp
f01025ec:	89 e5                	mov    %esp,%ebp
f01025ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01025f1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01025f5:	eb 07                	jmp    f01025fe <strfind+0x13>
		if (*s == c)
f01025f7:	38 ca                	cmp    %cl,%dl
f01025f9:	74 0a                	je     f0102605 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01025fb:	83 c0 01             	add    $0x1,%eax
f01025fe:	0f b6 10             	movzbl (%eax),%edx
f0102601:	84 d2                	test   %dl,%dl
f0102603:	75 f2                	jne    f01025f7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0102605:	5d                   	pop    %ebp
f0102606:	c3                   	ret    

f0102607 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0102607:	55                   	push   %ebp
f0102608:	89 e5                	mov    %esp,%ebp
f010260a:	57                   	push   %edi
f010260b:	56                   	push   %esi
f010260c:	53                   	push   %ebx
f010260d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102610:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0102613:	85 c9                	test   %ecx,%ecx
f0102615:	74 36                	je     f010264d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0102617:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010261d:	75 28                	jne    f0102647 <memset+0x40>
f010261f:	f6 c1 03             	test   $0x3,%cl
f0102622:	75 23                	jne    f0102647 <memset+0x40>
		c &= 0xFF;
f0102624:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0102628:	89 d3                	mov    %edx,%ebx
f010262a:	c1 e3 08             	shl    $0x8,%ebx
f010262d:	89 d6                	mov    %edx,%esi
f010262f:	c1 e6 18             	shl    $0x18,%esi
f0102632:	89 d0                	mov    %edx,%eax
f0102634:	c1 e0 10             	shl    $0x10,%eax
f0102637:	09 f0                	or     %esi,%eax
f0102639:	09 c2                	or     %eax,%edx
f010263b:	89 d0                	mov    %edx,%eax
f010263d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010263f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0102642:	fc                   	cld    
f0102643:	f3 ab                	rep stos %eax,%es:(%edi)
f0102645:	eb 06                	jmp    f010264d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0102647:	8b 45 0c             	mov    0xc(%ebp),%eax
f010264a:	fc                   	cld    
f010264b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010264d:	89 f8                	mov    %edi,%eax
f010264f:	5b                   	pop    %ebx
f0102650:	5e                   	pop    %esi
f0102651:	5f                   	pop    %edi
f0102652:	5d                   	pop    %ebp
f0102653:	c3                   	ret    

f0102654 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0102654:	55                   	push   %ebp
f0102655:	89 e5                	mov    %esp,%ebp
f0102657:	57                   	push   %edi
f0102658:	56                   	push   %esi
f0102659:	8b 45 08             	mov    0x8(%ebp),%eax
f010265c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010265f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0102662:	39 c6                	cmp    %eax,%esi
f0102664:	73 35                	jae    f010269b <memmove+0x47>
f0102666:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0102669:	39 d0                	cmp    %edx,%eax
f010266b:	73 2e                	jae    f010269b <memmove+0x47>
		s += n;
		d += n;
f010266d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0102670:	89 d6                	mov    %edx,%esi
f0102672:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102674:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010267a:	75 13                	jne    f010268f <memmove+0x3b>
f010267c:	f6 c1 03             	test   $0x3,%cl
f010267f:	75 0e                	jne    f010268f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0102681:	83 ef 04             	sub    $0x4,%edi
f0102684:	8d 72 fc             	lea    -0x4(%edx),%esi
f0102687:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010268a:	fd                   	std    
f010268b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010268d:	eb 09                	jmp    f0102698 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010268f:	83 ef 01             	sub    $0x1,%edi
f0102692:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0102695:	fd                   	std    
f0102696:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0102698:	fc                   	cld    
f0102699:	eb 1d                	jmp    f01026b8 <memmove+0x64>
f010269b:	89 f2                	mov    %esi,%edx
f010269d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010269f:	f6 c2 03             	test   $0x3,%dl
f01026a2:	75 0f                	jne    f01026b3 <memmove+0x5f>
f01026a4:	f6 c1 03             	test   $0x3,%cl
f01026a7:	75 0a                	jne    f01026b3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01026a9:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01026ac:	89 c7                	mov    %eax,%edi
f01026ae:	fc                   	cld    
f01026af:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01026b1:	eb 05                	jmp    f01026b8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01026b3:	89 c7                	mov    %eax,%edi
f01026b5:	fc                   	cld    
f01026b6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01026b8:	5e                   	pop    %esi
f01026b9:	5f                   	pop    %edi
f01026ba:	5d                   	pop    %ebp
f01026bb:	c3                   	ret    

f01026bc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01026bc:	55                   	push   %ebp
f01026bd:	89 e5                	mov    %esp,%ebp
f01026bf:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01026c2:	8b 45 10             	mov    0x10(%ebp),%eax
f01026c5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01026c9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01026cc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01026d0:	8b 45 08             	mov    0x8(%ebp),%eax
f01026d3:	89 04 24             	mov    %eax,(%esp)
f01026d6:	e8 79 ff ff ff       	call   f0102654 <memmove>
}
f01026db:	c9                   	leave  
f01026dc:	c3                   	ret    

f01026dd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01026dd:	55                   	push   %ebp
f01026de:	89 e5                	mov    %esp,%ebp
f01026e0:	56                   	push   %esi
f01026e1:	53                   	push   %ebx
f01026e2:	8b 55 08             	mov    0x8(%ebp),%edx
f01026e5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01026e8:	89 d6                	mov    %edx,%esi
f01026ea:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01026ed:	eb 1a                	jmp    f0102709 <memcmp+0x2c>
		if (*s1 != *s2)
f01026ef:	0f b6 02             	movzbl (%edx),%eax
f01026f2:	0f b6 19             	movzbl (%ecx),%ebx
f01026f5:	38 d8                	cmp    %bl,%al
f01026f7:	74 0a                	je     f0102703 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01026f9:	0f b6 c0             	movzbl %al,%eax
f01026fc:	0f b6 db             	movzbl %bl,%ebx
f01026ff:	29 d8                	sub    %ebx,%eax
f0102701:	eb 0f                	jmp    f0102712 <memcmp+0x35>
		s1++, s2++;
f0102703:	83 c2 01             	add    $0x1,%edx
f0102706:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0102709:	39 f2                	cmp    %esi,%edx
f010270b:	75 e2                	jne    f01026ef <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010270d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102712:	5b                   	pop    %ebx
f0102713:	5e                   	pop    %esi
f0102714:	5d                   	pop    %ebp
f0102715:	c3                   	ret    

f0102716 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0102716:	55                   	push   %ebp
f0102717:	89 e5                	mov    %esp,%ebp
f0102719:	8b 45 08             	mov    0x8(%ebp),%eax
f010271c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010271f:	89 c2                	mov    %eax,%edx
f0102721:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0102724:	eb 07                	jmp    f010272d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0102726:	38 08                	cmp    %cl,(%eax)
f0102728:	74 07                	je     f0102731 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010272a:	83 c0 01             	add    $0x1,%eax
f010272d:	39 d0                	cmp    %edx,%eax
f010272f:	72 f5                	jb     f0102726 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0102731:	5d                   	pop    %ebp
f0102732:	c3                   	ret    

f0102733 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0102733:	55                   	push   %ebp
f0102734:	89 e5                	mov    %esp,%ebp
f0102736:	57                   	push   %edi
f0102737:	56                   	push   %esi
f0102738:	53                   	push   %ebx
f0102739:	8b 55 08             	mov    0x8(%ebp),%edx
f010273c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010273f:	eb 03                	jmp    f0102744 <strtol+0x11>
		s++;
f0102741:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0102744:	0f b6 0a             	movzbl (%edx),%ecx
f0102747:	80 f9 09             	cmp    $0x9,%cl
f010274a:	74 f5                	je     f0102741 <strtol+0xe>
f010274c:	80 f9 20             	cmp    $0x20,%cl
f010274f:	74 f0                	je     f0102741 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0102751:	80 f9 2b             	cmp    $0x2b,%cl
f0102754:	75 0a                	jne    f0102760 <strtol+0x2d>
		s++;
f0102756:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0102759:	bf 00 00 00 00       	mov    $0x0,%edi
f010275e:	eb 11                	jmp    f0102771 <strtol+0x3e>
f0102760:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0102765:	80 f9 2d             	cmp    $0x2d,%cl
f0102768:	75 07                	jne    f0102771 <strtol+0x3e>
		s++, neg = 1;
f010276a:	8d 52 01             	lea    0x1(%edx),%edx
f010276d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0102771:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0102776:	75 15                	jne    f010278d <strtol+0x5a>
f0102778:	80 3a 30             	cmpb   $0x30,(%edx)
f010277b:	75 10                	jne    f010278d <strtol+0x5a>
f010277d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0102781:	75 0a                	jne    f010278d <strtol+0x5a>
		s += 2, base = 16;
f0102783:	83 c2 02             	add    $0x2,%edx
f0102786:	b8 10 00 00 00       	mov    $0x10,%eax
f010278b:	eb 10                	jmp    f010279d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f010278d:	85 c0                	test   %eax,%eax
f010278f:	75 0c                	jne    f010279d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0102791:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0102793:	80 3a 30             	cmpb   $0x30,(%edx)
f0102796:	75 05                	jne    f010279d <strtol+0x6a>
		s++, base = 8;
f0102798:	83 c2 01             	add    $0x1,%edx
f010279b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010279d:	bb 00 00 00 00       	mov    $0x0,%ebx
f01027a2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01027a5:	0f b6 0a             	movzbl (%edx),%ecx
f01027a8:	8d 71 d0             	lea    -0x30(%ecx),%esi
f01027ab:	89 f0                	mov    %esi,%eax
f01027ad:	3c 09                	cmp    $0x9,%al
f01027af:	77 08                	ja     f01027b9 <strtol+0x86>
			dig = *s - '0';
f01027b1:	0f be c9             	movsbl %cl,%ecx
f01027b4:	83 e9 30             	sub    $0x30,%ecx
f01027b7:	eb 20                	jmp    f01027d9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f01027b9:	8d 71 9f             	lea    -0x61(%ecx),%esi
f01027bc:	89 f0                	mov    %esi,%eax
f01027be:	3c 19                	cmp    $0x19,%al
f01027c0:	77 08                	ja     f01027ca <strtol+0x97>
			dig = *s - 'a' + 10;
f01027c2:	0f be c9             	movsbl %cl,%ecx
f01027c5:	83 e9 57             	sub    $0x57,%ecx
f01027c8:	eb 0f                	jmp    f01027d9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f01027ca:	8d 71 bf             	lea    -0x41(%ecx),%esi
f01027cd:	89 f0                	mov    %esi,%eax
f01027cf:	3c 19                	cmp    $0x19,%al
f01027d1:	77 16                	ja     f01027e9 <strtol+0xb6>
			dig = *s - 'A' + 10;
f01027d3:	0f be c9             	movsbl %cl,%ecx
f01027d6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01027d9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f01027dc:	7d 0f                	jge    f01027ed <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f01027de:	83 c2 01             	add    $0x1,%edx
f01027e1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f01027e5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f01027e7:	eb bc                	jmp    f01027a5 <strtol+0x72>
f01027e9:	89 d8                	mov    %ebx,%eax
f01027eb:	eb 02                	jmp    f01027ef <strtol+0xbc>
f01027ed:	89 d8                	mov    %ebx,%eax

	if (endptr)
f01027ef:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01027f3:	74 05                	je     f01027fa <strtol+0xc7>
		*endptr = (char *) s;
f01027f5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01027f8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f01027fa:	f7 d8                	neg    %eax
f01027fc:	85 ff                	test   %edi,%edi
f01027fe:	0f 44 c3             	cmove  %ebx,%eax
}
f0102801:	5b                   	pop    %ebx
f0102802:	5e                   	pop    %esi
f0102803:	5f                   	pop    %edi
f0102804:	5d                   	pop    %ebp
f0102805:	c3                   	ret    
f0102806:	66 90                	xchg   %ax,%ax
f0102808:	66 90                	xchg   %ax,%ax
f010280a:	66 90                	xchg   %ax,%ax
f010280c:	66 90                	xchg   %ax,%ax
f010280e:	66 90                	xchg   %ax,%ax

f0102810 <__udivdi3>:
f0102810:	55                   	push   %ebp
f0102811:	57                   	push   %edi
f0102812:	56                   	push   %esi
f0102813:	83 ec 0c             	sub    $0xc,%esp
f0102816:	8b 44 24 28          	mov    0x28(%esp),%eax
f010281a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010281e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0102822:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0102826:	85 c0                	test   %eax,%eax
f0102828:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010282c:	89 ea                	mov    %ebp,%edx
f010282e:	89 0c 24             	mov    %ecx,(%esp)
f0102831:	75 2d                	jne    f0102860 <__udivdi3+0x50>
f0102833:	39 e9                	cmp    %ebp,%ecx
f0102835:	77 61                	ja     f0102898 <__udivdi3+0x88>
f0102837:	85 c9                	test   %ecx,%ecx
f0102839:	89 ce                	mov    %ecx,%esi
f010283b:	75 0b                	jne    f0102848 <__udivdi3+0x38>
f010283d:	b8 01 00 00 00       	mov    $0x1,%eax
f0102842:	31 d2                	xor    %edx,%edx
f0102844:	f7 f1                	div    %ecx
f0102846:	89 c6                	mov    %eax,%esi
f0102848:	31 d2                	xor    %edx,%edx
f010284a:	89 e8                	mov    %ebp,%eax
f010284c:	f7 f6                	div    %esi
f010284e:	89 c5                	mov    %eax,%ebp
f0102850:	89 f8                	mov    %edi,%eax
f0102852:	f7 f6                	div    %esi
f0102854:	89 ea                	mov    %ebp,%edx
f0102856:	83 c4 0c             	add    $0xc,%esp
f0102859:	5e                   	pop    %esi
f010285a:	5f                   	pop    %edi
f010285b:	5d                   	pop    %ebp
f010285c:	c3                   	ret    
f010285d:	8d 76 00             	lea    0x0(%esi),%esi
f0102860:	39 e8                	cmp    %ebp,%eax
f0102862:	77 24                	ja     f0102888 <__udivdi3+0x78>
f0102864:	0f bd e8             	bsr    %eax,%ebp
f0102867:	83 f5 1f             	xor    $0x1f,%ebp
f010286a:	75 3c                	jne    f01028a8 <__udivdi3+0x98>
f010286c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0102870:	39 34 24             	cmp    %esi,(%esp)
f0102873:	0f 86 9f 00 00 00    	jbe    f0102918 <__udivdi3+0x108>
f0102879:	39 d0                	cmp    %edx,%eax
f010287b:	0f 82 97 00 00 00    	jb     f0102918 <__udivdi3+0x108>
f0102881:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102888:	31 d2                	xor    %edx,%edx
f010288a:	31 c0                	xor    %eax,%eax
f010288c:	83 c4 0c             	add    $0xc,%esp
f010288f:	5e                   	pop    %esi
f0102890:	5f                   	pop    %edi
f0102891:	5d                   	pop    %ebp
f0102892:	c3                   	ret    
f0102893:	90                   	nop
f0102894:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102898:	89 f8                	mov    %edi,%eax
f010289a:	f7 f1                	div    %ecx
f010289c:	31 d2                	xor    %edx,%edx
f010289e:	83 c4 0c             	add    $0xc,%esp
f01028a1:	5e                   	pop    %esi
f01028a2:	5f                   	pop    %edi
f01028a3:	5d                   	pop    %ebp
f01028a4:	c3                   	ret    
f01028a5:	8d 76 00             	lea    0x0(%esi),%esi
f01028a8:	89 e9                	mov    %ebp,%ecx
f01028aa:	8b 3c 24             	mov    (%esp),%edi
f01028ad:	d3 e0                	shl    %cl,%eax
f01028af:	89 c6                	mov    %eax,%esi
f01028b1:	b8 20 00 00 00       	mov    $0x20,%eax
f01028b6:	29 e8                	sub    %ebp,%eax
f01028b8:	89 c1                	mov    %eax,%ecx
f01028ba:	d3 ef                	shr    %cl,%edi
f01028bc:	89 e9                	mov    %ebp,%ecx
f01028be:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01028c2:	8b 3c 24             	mov    (%esp),%edi
f01028c5:	09 74 24 08          	or     %esi,0x8(%esp)
f01028c9:	89 d6                	mov    %edx,%esi
f01028cb:	d3 e7                	shl    %cl,%edi
f01028cd:	89 c1                	mov    %eax,%ecx
f01028cf:	89 3c 24             	mov    %edi,(%esp)
f01028d2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01028d6:	d3 ee                	shr    %cl,%esi
f01028d8:	89 e9                	mov    %ebp,%ecx
f01028da:	d3 e2                	shl    %cl,%edx
f01028dc:	89 c1                	mov    %eax,%ecx
f01028de:	d3 ef                	shr    %cl,%edi
f01028e0:	09 d7                	or     %edx,%edi
f01028e2:	89 f2                	mov    %esi,%edx
f01028e4:	89 f8                	mov    %edi,%eax
f01028e6:	f7 74 24 08          	divl   0x8(%esp)
f01028ea:	89 d6                	mov    %edx,%esi
f01028ec:	89 c7                	mov    %eax,%edi
f01028ee:	f7 24 24             	mull   (%esp)
f01028f1:	39 d6                	cmp    %edx,%esi
f01028f3:	89 14 24             	mov    %edx,(%esp)
f01028f6:	72 30                	jb     f0102928 <__udivdi3+0x118>
f01028f8:	8b 54 24 04          	mov    0x4(%esp),%edx
f01028fc:	89 e9                	mov    %ebp,%ecx
f01028fe:	d3 e2                	shl    %cl,%edx
f0102900:	39 c2                	cmp    %eax,%edx
f0102902:	73 05                	jae    f0102909 <__udivdi3+0xf9>
f0102904:	3b 34 24             	cmp    (%esp),%esi
f0102907:	74 1f                	je     f0102928 <__udivdi3+0x118>
f0102909:	89 f8                	mov    %edi,%eax
f010290b:	31 d2                	xor    %edx,%edx
f010290d:	e9 7a ff ff ff       	jmp    f010288c <__udivdi3+0x7c>
f0102912:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102918:	31 d2                	xor    %edx,%edx
f010291a:	b8 01 00 00 00       	mov    $0x1,%eax
f010291f:	e9 68 ff ff ff       	jmp    f010288c <__udivdi3+0x7c>
f0102924:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102928:	8d 47 ff             	lea    -0x1(%edi),%eax
f010292b:	31 d2                	xor    %edx,%edx
f010292d:	83 c4 0c             	add    $0xc,%esp
f0102930:	5e                   	pop    %esi
f0102931:	5f                   	pop    %edi
f0102932:	5d                   	pop    %ebp
f0102933:	c3                   	ret    
f0102934:	66 90                	xchg   %ax,%ax
f0102936:	66 90                	xchg   %ax,%ax
f0102938:	66 90                	xchg   %ax,%ax
f010293a:	66 90                	xchg   %ax,%ax
f010293c:	66 90                	xchg   %ax,%ax
f010293e:	66 90                	xchg   %ax,%ax

f0102940 <__umoddi3>:
f0102940:	55                   	push   %ebp
f0102941:	57                   	push   %edi
f0102942:	56                   	push   %esi
f0102943:	83 ec 14             	sub    $0x14,%esp
f0102946:	8b 44 24 28          	mov    0x28(%esp),%eax
f010294a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010294e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0102952:	89 c7                	mov    %eax,%edi
f0102954:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102958:	8b 44 24 30          	mov    0x30(%esp),%eax
f010295c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0102960:	89 34 24             	mov    %esi,(%esp)
f0102963:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0102967:	85 c0                	test   %eax,%eax
f0102969:	89 c2                	mov    %eax,%edx
f010296b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010296f:	75 17                	jne    f0102988 <__umoddi3+0x48>
f0102971:	39 fe                	cmp    %edi,%esi
f0102973:	76 4b                	jbe    f01029c0 <__umoddi3+0x80>
f0102975:	89 c8                	mov    %ecx,%eax
f0102977:	89 fa                	mov    %edi,%edx
f0102979:	f7 f6                	div    %esi
f010297b:	89 d0                	mov    %edx,%eax
f010297d:	31 d2                	xor    %edx,%edx
f010297f:	83 c4 14             	add    $0x14,%esp
f0102982:	5e                   	pop    %esi
f0102983:	5f                   	pop    %edi
f0102984:	5d                   	pop    %ebp
f0102985:	c3                   	ret    
f0102986:	66 90                	xchg   %ax,%ax
f0102988:	39 f8                	cmp    %edi,%eax
f010298a:	77 54                	ja     f01029e0 <__umoddi3+0xa0>
f010298c:	0f bd e8             	bsr    %eax,%ebp
f010298f:	83 f5 1f             	xor    $0x1f,%ebp
f0102992:	75 5c                	jne    f01029f0 <__umoddi3+0xb0>
f0102994:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0102998:	39 3c 24             	cmp    %edi,(%esp)
f010299b:	0f 87 e7 00 00 00    	ja     f0102a88 <__umoddi3+0x148>
f01029a1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01029a5:	29 f1                	sub    %esi,%ecx
f01029a7:	19 c7                	sbb    %eax,%edi
f01029a9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01029ad:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01029b1:	8b 44 24 08          	mov    0x8(%esp),%eax
f01029b5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01029b9:	83 c4 14             	add    $0x14,%esp
f01029bc:	5e                   	pop    %esi
f01029bd:	5f                   	pop    %edi
f01029be:	5d                   	pop    %ebp
f01029bf:	c3                   	ret    
f01029c0:	85 f6                	test   %esi,%esi
f01029c2:	89 f5                	mov    %esi,%ebp
f01029c4:	75 0b                	jne    f01029d1 <__umoddi3+0x91>
f01029c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01029cb:	31 d2                	xor    %edx,%edx
f01029cd:	f7 f6                	div    %esi
f01029cf:	89 c5                	mov    %eax,%ebp
f01029d1:	8b 44 24 04          	mov    0x4(%esp),%eax
f01029d5:	31 d2                	xor    %edx,%edx
f01029d7:	f7 f5                	div    %ebp
f01029d9:	89 c8                	mov    %ecx,%eax
f01029db:	f7 f5                	div    %ebp
f01029dd:	eb 9c                	jmp    f010297b <__umoddi3+0x3b>
f01029df:	90                   	nop
f01029e0:	89 c8                	mov    %ecx,%eax
f01029e2:	89 fa                	mov    %edi,%edx
f01029e4:	83 c4 14             	add    $0x14,%esp
f01029e7:	5e                   	pop    %esi
f01029e8:	5f                   	pop    %edi
f01029e9:	5d                   	pop    %ebp
f01029ea:	c3                   	ret    
f01029eb:	90                   	nop
f01029ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01029f0:	8b 04 24             	mov    (%esp),%eax
f01029f3:	be 20 00 00 00       	mov    $0x20,%esi
f01029f8:	89 e9                	mov    %ebp,%ecx
f01029fa:	29 ee                	sub    %ebp,%esi
f01029fc:	d3 e2                	shl    %cl,%edx
f01029fe:	89 f1                	mov    %esi,%ecx
f0102a00:	d3 e8                	shr    %cl,%eax
f0102a02:	89 e9                	mov    %ebp,%ecx
f0102a04:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102a08:	8b 04 24             	mov    (%esp),%eax
f0102a0b:	09 54 24 04          	or     %edx,0x4(%esp)
f0102a0f:	89 fa                	mov    %edi,%edx
f0102a11:	d3 e0                	shl    %cl,%eax
f0102a13:	89 f1                	mov    %esi,%ecx
f0102a15:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102a19:	8b 44 24 10          	mov    0x10(%esp),%eax
f0102a1d:	d3 ea                	shr    %cl,%edx
f0102a1f:	89 e9                	mov    %ebp,%ecx
f0102a21:	d3 e7                	shl    %cl,%edi
f0102a23:	89 f1                	mov    %esi,%ecx
f0102a25:	d3 e8                	shr    %cl,%eax
f0102a27:	89 e9                	mov    %ebp,%ecx
f0102a29:	09 f8                	or     %edi,%eax
f0102a2b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0102a2f:	f7 74 24 04          	divl   0x4(%esp)
f0102a33:	d3 e7                	shl    %cl,%edi
f0102a35:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102a39:	89 d7                	mov    %edx,%edi
f0102a3b:	f7 64 24 08          	mull   0x8(%esp)
f0102a3f:	39 d7                	cmp    %edx,%edi
f0102a41:	89 c1                	mov    %eax,%ecx
f0102a43:	89 14 24             	mov    %edx,(%esp)
f0102a46:	72 2c                	jb     f0102a74 <__umoddi3+0x134>
f0102a48:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0102a4c:	72 22                	jb     f0102a70 <__umoddi3+0x130>
f0102a4e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0102a52:	29 c8                	sub    %ecx,%eax
f0102a54:	19 d7                	sbb    %edx,%edi
f0102a56:	89 e9                	mov    %ebp,%ecx
f0102a58:	89 fa                	mov    %edi,%edx
f0102a5a:	d3 e8                	shr    %cl,%eax
f0102a5c:	89 f1                	mov    %esi,%ecx
f0102a5e:	d3 e2                	shl    %cl,%edx
f0102a60:	89 e9                	mov    %ebp,%ecx
f0102a62:	d3 ef                	shr    %cl,%edi
f0102a64:	09 d0                	or     %edx,%eax
f0102a66:	89 fa                	mov    %edi,%edx
f0102a68:	83 c4 14             	add    $0x14,%esp
f0102a6b:	5e                   	pop    %esi
f0102a6c:	5f                   	pop    %edi
f0102a6d:	5d                   	pop    %ebp
f0102a6e:	c3                   	ret    
f0102a6f:	90                   	nop
f0102a70:	39 d7                	cmp    %edx,%edi
f0102a72:	75 da                	jne    f0102a4e <__umoddi3+0x10e>
f0102a74:	8b 14 24             	mov    (%esp),%edx
f0102a77:	89 c1                	mov    %eax,%ecx
f0102a79:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0102a7d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0102a81:	eb cb                	jmp    f0102a4e <__umoddi3+0x10e>
f0102a83:	90                   	nop
f0102a84:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102a88:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0102a8c:	0f 82 0f ff ff ff    	jb     f01029a1 <__umoddi3+0x61>
f0102a92:	e9 1a ff ff ff       	jmp    f01029b1 <__umoddi3+0x71>
