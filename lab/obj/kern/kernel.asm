
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
f010004e:	c7 04 24 c0 28 10 f0 	movl   $0xf01028c0,(%esp)
f0100055:	e8 55 18 00 00       	call   f01018af <cprintf>
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
f010008b:	c7 04 24 dc 28 10 f0 	movl   $0xf01028dc,(%esp)
f0100092:	e8 18 18 00 00       	call   f01018af <cprintf>
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
f01000c0:	e8 52 23 00 00       	call   f0102417 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 c5 04 00 00       	call   f010058f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 f7 28 10 f0 	movl   $0xf01028f7,(%esp)
f01000d9:	e8 d1 17 00 00       	call   f01018af <cprintf>
	mem_init();
f01000de:	e8 49 0f 00 00       	call   f010102c <mem_init>

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
f0100107:	c7 04 24 12 29 10 f0 	movl   $0xf0102912,(%esp)
f010010e:	e8 9c 17 00 00       	call   f01018af <cprintf>
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
f010014e:	c7 04 24 24 29 10 f0 	movl   $0xf0102924,(%esp)
f0100155:	e8 55 17 00 00       	call   f01018af <cprintf>
	vcprintf(fmt, ap);
f010015a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010015e:	89 34 24             	mov    %esi,(%esp)
f0100161:	e8 16 17 00 00       	call   f010187c <vcprintf>
	cprintf("\n");
f0100166:	c7 04 24 60 29 10 f0 	movl   $0xf0102960,(%esp)
f010016d:	e8 3d 17 00 00       	call   f01018af <cprintf>
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
f0100198:	c7 04 24 3c 29 10 f0 	movl   $0xf010293c,(%esp)
f010019f:	e8 0b 17 00 00       	call   f01018af <cprintf>
	vcprintf(fmt, ap);
f01001a4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01001a8:	8b 45 10             	mov    0x10(%ebp),%eax
f01001ab:	89 04 24             	mov    %eax,(%esp)
f01001ae:	e8 c9 16 00 00       	call   f010187c <vcprintf>
	cprintf("\n");
f01001b3:	c7 04 24 60 29 10 f0 	movl   $0xf0102960,(%esp)
f01001ba:	e8 f0 16 00 00       	call   f01018af <cprintf>
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
f0100275:	0f b6 82 a0 2a 10 f0 	movzbl -0xfefd560(%edx),%eax
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
f01002b2:	0f b6 82 a0 2a 10 f0 	movzbl -0xfefd560(%edx),%eax
f01002b9:	0b 05 00 53 11 f0    	or     0xf0115300,%eax
	shift ^= togglecode[data];
f01002bf:	0f b6 8a a0 29 10 f0 	movzbl -0xfefd660(%edx),%ecx
f01002c6:	31 c8                	xor    %ecx,%eax
f01002c8:	a3 00 53 11 f0       	mov    %eax,0xf0115300

	c = charcode[shift & (CTL | SHIFT)][data];
f01002cd:	89 c1                	mov    %eax,%ecx
f01002cf:	83 e1 03             	and    $0x3,%ecx
f01002d2:	8b 0c 8d 80 29 10 f0 	mov    -0xfefd680(,%ecx,4),%ecx
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
f0100312:	c7 04 24 56 29 10 f0 	movl   $0xf0102956,(%esp)
f0100319:	e8 91 15 00 00       	call   f01018af <cprintf>
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
f01004b9:	e8 a6 1f 00 00       	call   f0102464 <memmove>
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
f010066d:	c7 04 24 62 29 10 f0 	movl   $0xf0102962,(%esp)
f0100674:	e8 36 12 00 00       	call   f01018af <cprintf>
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
f01006b6:	c7 44 24 08 a0 2b 10 	movl   $0xf0102ba0,0x8(%esp)
f01006bd:	f0 
f01006be:	c7 44 24 04 be 2b 10 	movl   $0xf0102bbe,0x4(%esp)
f01006c5:	f0 
f01006c6:	c7 04 24 c3 2b 10 f0 	movl   $0xf0102bc3,(%esp)
f01006cd:	e8 dd 11 00 00       	call   f01018af <cprintf>
f01006d2:	c7 44 24 08 64 2c 10 	movl   $0xf0102c64,0x8(%esp)
f01006d9:	f0 
f01006da:	c7 44 24 04 cc 2b 10 	movl   $0xf0102bcc,0x4(%esp)
f01006e1:	f0 
f01006e2:	c7 04 24 c3 2b 10 f0 	movl   $0xf0102bc3,(%esp)
f01006e9:	e8 c1 11 00 00       	call   f01018af <cprintf>
f01006ee:	c7 44 24 08 d5 2b 10 	movl   $0xf0102bd5,0x8(%esp)
f01006f5:	f0 
f01006f6:	c7 44 24 04 f2 2b 10 	movl   $0xf0102bf2,0x4(%esp)
f01006fd:	f0 
f01006fe:	c7 04 24 c3 2b 10 f0 	movl   $0xf0102bc3,(%esp)
f0100705:	e8 a5 11 00 00       	call   f01018af <cprintf>
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
f0100717:	c7 04 24 fd 2b 10 f0 	movl   $0xf0102bfd,(%esp)
f010071e:	e8 8c 11 00 00       	call   f01018af <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100723:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010072a:	00 
f010072b:	c7 04 24 8c 2c 10 f0 	movl   $0xf0102c8c,(%esp)
f0100732:	e8 78 11 00 00       	call   f01018af <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100737:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010073e:	00 
f010073f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100746:	f0 
f0100747:	c7 04 24 b4 2c 10 f0 	movl   $0xf0102cb4,(%esp)
f010074e:	e8 5c 11 00 00       	call   f01018af <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100753:	c7 44 24 08 a7 28 10 	movl   $0x1028a7,0x8(%esp)
f010075a:	00 
f010075b:	c7 44 24 04 a7 28 10 	movl   $0xf01028a7,0x4(%esp)
f0100762:	f0 
f0100763:	c7 04 24 d8 2c 10 f0 	movl   $0xf0102cd8,(%esp)
f010076a:	e8 40 11 00 00       	call   f01018af <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010076f:	c7 44 24 08 00 53 11 	movl   $0x115300,0x8(%esp)
f0100776:	00 
f0100777:	c7 44 24 04 00 53 11 	movl   $0xf0115300,0x4(%esp)
f010077e:	f0 
f010077f:	c7 04 24 fc 2c 10 f0 	movl   $0xf0102cfc,(%esp)
f0100786:	e8 24 11 00 00       	call   f01018af <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010078b:	c7 44 24 08 70 59 11 	movl   $0x115970,0x8(%esp)
f0100792:	00 
f0100793:	c7 44 24 04 70 59 11 	movl   $0xf0115970,0x4(%esp)
f010079a:	f0 
f010079b:	c7 04 24 20 2d 10 f0 	movl   $0xf0102d20,(%esp)
f01007a2:	e8 08 11 00 00       	call   f01018af <cprintf>
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
f01007c8:	c7 04 24 44 2d 10 f0 	movl   $0xf0102d44,(%esp)
f01007cf:	e8 db 10 00 00       	call   f01018af <cprintf>
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
f01007e6:	c7 04 24 16 2c 10 f0 	movl   $0xf0102c16,(%esp)
f01007ed:	e8 bd 10 00 00       	call   f01018af <cprintf>
	
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
f0100801:	e8 a0 11 00 00       	call   f01019a6 <debuginfo_eip>
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
f0100856:	c7 04 24 70 2d 10 f0 	movl   $0xf0102d70,(%esp)
f010085d:	e8 4d 10 00 00       	call   f01018af <cprintf>
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
f010087e:	c7 04 24 b4 2d 10 f0 	movl   $0xf0102db4,(%esp)
f0100885:	e8 25 10 00 00       	call   f01018af <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010088a:	c7 04 24 d8 2d 10 f0 	movl   $0xf0102dd8,(%esp)
f0100891:	e8 19 10 00 00       	call   f01018af <cprintf>


	while (1) {
		buf = readline("K> ");
f0100896:	c7 04 24 28 2c 10 f0 	movl   $0xf0102c28,(%esp)
f010089d:	e8 1e 19 00 00       	call   f01021c0 <readline>
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
f01008ce:	c7 04 24 2c 2c 10 f0 	movl   $0xf0102c2c,(%esp)
f01008d5:	e8 00 1b 00 00       	call   f01023da <strchr>
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
f01008f0:	c7 04 24 31 2c 10 f0 	movl   $0xf0102c31,(%esp)
f01008f7:	e8 b3 0f 00 00       	call   f01018af <cprintf>
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
f0100918:	c7 04 24 2c 2c 10 f0 	movl   $0xf0102c2c,(%esp)
f010091f:	e8 b6 1a 00 00       	call   f01023da <strchr>
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
f0100942:	8b 04 85 00 2e 10 f0 	mov    -0xfefd200(,%eax,4),%eax
f0100949:	89 44 24 04          	mov    %eax,0x4(%esp)
f010094d:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100950:	89 04 24             	mov    %eax,(%esp)
f0100953:	e8 24 1a 00 00       	call   f010237c <strcmp>
f0100958:	85 c0                	test   %eax,%eax
f010095a:	75 24                	jne    f0100980 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f010095c:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010095f:	8b 55 08             	mov    0x8(%ebp),%edx
f0100962:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100966:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100969:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010096d:	89 34 24             	mov    %esi,(%esp)
f0100970:	ff 14 85 08 2e 10 f0 	call   *-0xfefd1f8(,%eax,4)


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
f010098f:	c7 04 24 4e 2c 10 f0 	movl   $0xf0102c4e,(%esp)
f0100996:	e8 14 0f 00 00       	call   f01018af <cprintf>
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
f01009d0:	c7 44 24 08 24 2e 10 	movl   $0xf0102e24,0x8(%esp)
f01009d7:	f0 
f01009d8:	c7 44 24 04 ca 02 00 	movl   $0x2ca,0x4(%esp)
f01009df:	00 
f01009e0:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
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
f0100a67:	c7 44 24 08 48 2e 10 	movl   $0xf0102e48,0x8(%esp)
f0100a6e:	f0 
f0100a6f:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
f0100a76:	00 
f0100a77:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
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
f0100ab2:	c7 44 24 08 6c 2e 10 	movl   $0xf0102e6c,0x8(%esp)
f0100ab9:	f0 
f0100aba:	c7 44 24 04 0d 02 00 	movl   $0x20d,0x4(%esp)
f0100ac1:	00 
f0100ac2:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
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
void	tlb_invalidate(pde_t *pgdir, void *va);

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
f0100b4c:	c7 44 24 08 24 2e 10 	movl   $0xf0102e24,0x8(%esp)
f0100b53:	f0 
f0100b54:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100b5b:	00 
f0100b5c:	c7 04 24 ac 30 10 f0 	movl   $0xf01030ac,(%esp)
f0100b63:	e8 b9 f5 ff ff       	call   f0100121 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b68:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b6f:	00 
f0100b70:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b77:	00 
	return (void *)(pa + KERNBASE);
f0100b78:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b7d:	89 04 24             	mov    %eax,(%esp)
f0100b80:	e8 92 18 00 00       	call   f0102417 <memset>
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
f0100bc6:	c7 44 24 0c ba 30 10 	movl   $0xf01030ba,0xc(%esp)
f0100bcd:	f0 
f0100bce:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f0100bd5:	f0 
f0100bd6:	c7 44 24 04 27 02 00 	movl   $0x227,0x4(%esp)
f0100bdd:	00 
f0100bde:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f0100be5:	e8 37 f5 ff ff       	call   f0100121 <_panic>
		assert(pp < pages + npages);
f0100bea:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bed:	72 24                	jb     f0100c13 <check_page_free_list+0x177>
f0100bef:	c7 44 24 0c db 30 10 	movl   $0xf01030db,0xc(%esp)
f0100bf6:	f0 
f0100bf7:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f0100bfe:	f0 
f0100bff:	c7 44 24 04 28 02 00 	movl   $0x228,0x4(%esp)
f0100c06:	00 
f0100c07:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f0100c0e:	e8 0e f5 ff ff       	call   f0100121 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c13:	89 d0                	mov    %edx,%eax
f0100c15:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c18:	a8 07                	test   $0x7,%al
f0100c1a:	74 24                	je     f0100c40 <check_page_free_list+0x1a4>
f0100c1c:	c7 44 24 0c 90 2e 10 	movl   $0xf0102e90,0xc(%esp)
f0100c23:	f0 
f0100c24:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f0100c2b:	f0 
f0100c2c:	c7 44 24 04 29 02 00 	movl   $0x229,0x4(%esp)
f0100c33:	00 
f0100c34:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f0100c3b:	e8 e1 f4 ff ff       	call   f0100121 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

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
f0100c4a:	c7 44 24 0c ef 30 10 	movl   $0xf01030ef,0xc(%esp)
f0100c51:	f0 
f0100c52:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f0100c59:	f0 
f0100c5a:	c7 44 24 04 2c 02 00 	movl   $0x22c,0x4(%esp)
f0100c61:	00 
f0100c62:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f0100c69:	e8 b3 f4 ff ff       	call   f0100121 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c6e:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c73:	75 24                	jne    f0100c99 <check_page_free_list+0x1fd>
f0100c75:	c7 44 24 0c 00 31 10 	movl   $0xf0103100,0xc(%esp)
f0100c7c:	f0 
f0100c7d:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f0100c84:	f0 
f0100c85:	c7 44 24 04 2d 02 00 	movl   $0x22d,0x4(%esp)
f0100c8c:	00 
f0100c8d:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f0100c94:	e8 88 f4 ff ff       	call   f0100121 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c99:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c9e:	75 24                	jne    f0100cc4 <check_page_free_list+0x228>
f0100ca0:	c7 44 24 0c c4 2e 10 	movl   $0xf0102ec4,0xc(%esp)
f0100ca7:	f0 
f0100ca8:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f0100caf:	f0 
f0100cb0:	c7 44 24 04 2e 02 00 	movl   $0x22e,0x4(%esp)
f0100cb7:	00 
f0100cb8:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f0100cbf:	e8 5d f4 ff ff       	call   f0100121 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cc4:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cc9:	75 24                	jne    f0100cef <check_page_free_list+0x253>
f0100ccb:	c7 44 24 0c 19 31 10 	movl   $0xf0103119,0xc(%esp)
f0100cd2:	f0 
f0100cd3:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f0100cda:	f0 
f0100cdb:	c7 44 24 04 2f 02 00 	movl   $0x22f,0x4(%esp)
f0100ce2:	00 
f0100ce3:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
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
f0100d04:	c7 44 24 08 24 2e 10 	movl   $0xf0102e24,0x8(%esp)
f0100d0b:	f0 
f0100d0c:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100d13:	00 
f0100d14:	c7 04 24 ac 30 10 f0 	movl   $0xf01030ac,(%esp)
f0100d1b:	e8 01 f4 ff ff       	call   f0100121 <_panic>
	return (void *)(pa + KERNBASE);
f0100d20:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d25:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100d28:	76 2a                	jbe    f0100d54 <check_page_free_list+0x2b8>
f0100d2a:	c7 44 24 0c e8 2e 10 	movl   $0xf0102ee8,0xc(%esp)
f0100d31:	f0 
f0100d32:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f0100d39:	f0 
f0100d3a:	c7 44 24 04 30 02 00 	movl   $0x230,0x4(%esp)
f0100d41:	00 
f0100d42:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
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
f0100d68:	c7 44 24 0c 33 31 10 	movl   $0xf0103133,0xc(%esp)
f0100d6f:	f0 
f0100d70:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f0100d77:	f0 
f0100d78:	c7 44 24 04 38 02 00 	movl   $0x238,0x4(%esp)
f0100d7f:	00 
f0100d80:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f0100d87:	e8 95 f3 ff ff       	call   f0100121 <_panic>
	assert(nfree_extmem > 0);
f0100d8c:	85 ff                	test   %edi,%edi
f0100d8e:	7f 4d                	jg     f0100ddd <check_page_free_list+0x341>
f0100d90:	c7 44 24 0c 45 31 10 	movl   $0xf0103145,0xc(%esp)
f0100d97:	f0 
f0100d98:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f0100d9f:	f0 
f0100da0:	c7 44 24 04 39 02 00 	movl   $0x239,0x4(%esp)
f0100da7:	00 
f0100da8:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
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
f0100e6e:	c7 04 24 30 2f 10 f0 	movl   $0xf0102f30,(%esp)
f0100e75:	e8 35 0a 00 00       	call   f01018af <cprintf>
	
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
f0100e9d:	c7 44 24 08 48 2e 10 	movl   $0xf0102e48,0x8(%esp)
f0100ea4:	f0 
f0100ea5:	c7 44 24 04 26 01 00 	movl   $0x126,0x4(%esp)
f0100eac:	00 
f0100ead:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
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
f0100f13:	c7 04 24 54 2f 10 f0 	movl   $0xf0102f54,(%esp)
f0100f1a:	e8 90 09 00 00       	call   f01018af <cprintf>
	cprintf("&pages[npages-1] = %x\n", &pages[npages-1]);
f0100f1f:	a1 6c 59 11 f0       	mov    0xf011596c,%eax
f0100f24:	8b 15 64 59 11 f0    	mov    0xf0115964,%edx
f0100f2a:	8d 44 d0 f8          	lea    -0x8(%eax,%edx,8),%eax
f0100f2e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f32:	c7 04 24 56 31 10 f0 	movl   $0xf0103156,(%esp)
f0100f39:	e8 71 09 00 00       	call   f01018af <cprintf>
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
void	tlb_invalidate(pde_t *pgdir, void *va);

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
f0100f83:	c7 44 24 08 24 2e 10 	movl   $0xf0102e24,0x8(%esp)
f0100f8a:	f0 
f0100f8b:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100f92:	00 
f0100f93:	c7 04 24 ac 30 10 f0 	movl   $0xf01030ac,(%esp)
f0100f9a:	e8 82 f1 ff ff       	call   f0100121 <_panic>
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
f0100f9f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100fa6:	00 
f0100fa7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100fae:	00 
	return (void *)(pa + KERNBASE);
f0100faf:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100fb4:	89 04 24             	mov    %eax,(%esp)
f0100fb7:	e8 5b 14 00 00       	call   f0102417 <memset>
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
f0100fe1:	c7 44 24 08 80 2f 10 	movl   $0xf0102f80,0x8(%esp)
f0100fe8:	f0 
f0100fe9:	c7 44 24 04 5e 01 00 	movl   $0x15e,0x4(%esp)
f0100ff0:	00 
f0100ff1:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f0100ff8:	e8 24 f1 ff ff       	call   f0100121 <_panic>
	return;
	}
	
	// pp->pp_link is not NULL.
	else if(!pp) 
f0100ffd:	85 c0                	test   %eax,%eax
f0100fff:	75 1c                	jne    f010101d <page_free+0x4c>
	{
	panic("Page cannot be returned to free list as it is Null");
f0101001:	c7 44 24 08 c0 2f 10 	movl   $0xf0102fc0,0x8(%esp)
f0101008:	f0 
f0101009:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
f0101010:	00 
f0101011:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
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

f010102c <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010102c:	55                   	push   %ebp
f010102d:	89 e5                	mov    %esp,%ebp
f010102f:	57                   	push   %edi
f0101030:	56                   	push   %esi
f0101031:	53                   	push   %ebx
f0101032:	83 ec 2c             	sub    $0x2c,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101035:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f010103c:	e8 fe 07 00 00       	call   f010183f <mc146818_read>
f0101041:	89 c3                	mov    %eax,%ebx
f0101043:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f010104a:	e8 f0 07 00 00       	call   f010183f <mc146818_read>
f010104f:	c1 e0 08             	shl    $0x8,%eax
f0101052:	09 c3                	or     %eax,%ebx
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101054:	89 d8                	mov    %ebx,%eax
f0101056:	c1 e0 0a             	shl    $0xa,%eax
f0101059:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010105f:	85 c0                	test   %eax,%eax
f0101061:	0f 48 c2             	cmovs  %edx,%eax
f0101064:	c1 f8 0c             	sar    $0xc,%eax
f0101067:	a3 44 55 11 f0       	mov    %eax,0xf0115544
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010106c:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101073:	e8 c7 07 00 00       	call   f010183f <mc146818_read>
f0101078:	89 c3                	mov    %eax,%ebx
f010107a:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101081:	e8 b9 07 00 00       	call   f010183f <mc146818_read>
f0101086:	c1 e0 08             	shl    $0x8,%eax
f0101089:	09 c3                	or     %eax,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010108b:	89 d8                	mov    %ebx,%eax
f010108d:	c1 e0 0a             	shl    $0xa,%eax
f0101090:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101096:	85 c0                	test   %eax,%eax
f0101098:	0f 48 c2             	cmovs  %edx,%eax
f010109b:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f010109e:	85 c0                	test   %eax,%eax
f01010a0:	74 0e                	je     f01010b0 <mem_init+0x84>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01010a2:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01010a8:	89 15 64 59 11 f0    	mov    %edx,0xf0115964
f01010ae:	eb 0c                	jmp    f01010bc <mem_init+0x90>
	else
		npages = npages_basemem;
f01010b0:	8b 15 44 55 11 f0    	mov    0xf0115544,%edx
f01010b6:	89 15 64 59 11 f0    	mov    %edx,0xf0115964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f01010bc:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01010bf:	c1 e8 0a             	shr    $0xa,%eax
f01010c2:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f01010c6:	a1 44 55 11 f0       	mov    0xf0115544,%eax
f01010cb:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01010ce:	c1 e8 0a             	shr    $0xa,%eax
f01010d1:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f01010d5:	a1 64 59 11 f0       	mov    0xf0115964,%eax
f01010da:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01010dd:	c1 e8 0a             	shr    $0xa,%eax
f01010e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010e4:	c7 04 24 f4 2f 10 f0 	movl   $0xf0102ff4,(%esp)
f01010eb:	e8 bf 07 00 00       	call   f01018af <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01010f0:	b8 00 10 00 00       	mov    $0x1000,%eax
f01010f5:	e8 1d f9 ff ff       	call   f0100a17 <boot_alloc>
f01010fa:	a3 68 59 11 f0       	mov    %eax,0xf0115968
	memset(kern_pgdir, 0, PGSIZE);
f01010ff:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101106:	00 
f0101107:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010110e:	00 
f010110f:	89 04 24             	mov    %eax,(%esp)
f0101112:	e8 00 13 00 00       	call   f0102417 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101117:	a1 68 59 11 f0       	mov    0xf0115968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010111c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101121:	77 20                	ja     f0101143 <mem_init+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101123:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101127:	c7 44 24 08 48 2e 10 	movl   $0xf0102e48,0x8(%esp)
f010112e:	f0 
f010112f:	c7 44 24 04 95 00 00 	movl   $0x95,0x4(%esp)
f0101136:	00 
f0101137:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f010113e:	e8 de ef ff ff       	call   f0100121 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101143:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101149:	83 ca 05             	or     $0x5,%edx
f010114c:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.

	//This line creates a boot allocation of memory of the size of number of pages
	// mulitplied by size of struct Pageinfo to store metadata of the page. 
	pages = boot_alloc(sizeof(struct PageInfo) * npages);   
f0101152:	a1 64 59 11 f0       	mov    0xf0115964,%eax
f0101157:	c1 e0 03             	shl    $0x3,%eax
f010115a:	e8 b8 f8 ff ff       	call   f0100a17 <boot_alloc>
f010115f:	a3 6c 59 11 f0       	mov    %eax,0xf011596c
	memset(pages, 0, sizeof(struct PageInfo) * npages); //Clear the memory 
f0101164:	8b 3d 64 59 11 f0    	mov    0xf0115964,%edi
f010116a:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f0101171:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101175:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010117c:	00 
f010117d:	89 04 24             	mov    %eax,(%esp)
f0101180:	e8 92 12 00 00       	call   f0102417 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101185:	e8 5b fc ff ff       	call   f0100de5 <page_init>

	check_page_free_list(1);
f010118a:	b8 01 00 00 00       	mov    $0x1,%eax
f010118f:	e8 08 f9 ff ff       	call   f0100a9c <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101194:	83 3d 6c 59 11 f0 00 	cmpl   $0x0,0xf011596c
f010119b:	75 1c                	jne    f01011b9 <mem_init+0x18d>
		panic("'pages' is a null pointer!");
f010119d:	c7 44 24 08 6d 31 10 	movl   $0xf010316d,0x8(%esp)
f01011a4:	f0 
f01011a5:	c7 44 24 04 4a 02 00 	movl   $0x24a,0x4(%esp)
f01011ac:	00 
f01011ad:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f01011b4:	e8 68 ef ff ff       	call   f0100121 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011b9:	a1 40 55 11 f0       	mov    0xf0115540,%eax
f01011be:	bb 00 00 00 00       	mov    $0x0,%ebx
f01011c3:	eb 05                	jmp    f01011ca <mem_init+0x19e>
		++nfree;
f01011c5:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011c8:	8b 00                	mov    (%eax),%eax
f01011ca:	85 c0                	test   %eax,%eax
f01011cc:	75 f7                	jne    f01011c5 <mem_init+0x199>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01011ce:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01011d5:	e8 6c fd ff ff       	call   f0100f46 <page_alloc>
f01011da:	89 c7                	mov    %eax,%edi
f01011dc:	85 c0                	test   %eax,%eax
f01011de:	75 24                	jne    f0101204 <mem_init+0x1d8>
f01011e0:	c7 44 24 0c 88 31 10 	movl   $0xf0103188,0xc(%esp)
f01011e7:	f0 
f01011e8:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f01011ef:	f0 
f01011f0:	c7 44 24 04 52 02 00 	movl   $0x252,0x4(%esp)
f01011f7:	00 
f01011f8:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f01011ff:	e8 1d ef ff ff       	call   f0100121 <_panic>
	assert((pp1 = page_alloc(0)));
f0101204:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010120b:	e8 36 fd ff ff       	call   f0100f46 <page_alloc>
f0101210:	89 c6                	mov    %eax,%esi
f0101212:	85 c0                	test   %eax,%eax
f0101214:	75 24                	jne    f010123a <mem_init+0x20e>
f0101216:	c7 44 24 0c 9e 31 10 	movl   $0xf010319e,0xc(%esp)
f010121d:	f0 
f010121e:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f0101225:	f0 
f0101226:	c7 44 24 04 53 02 00 	movl   $0x253,0x4(%esp)
f010122d:	00 
f010122e:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f0101235:	e8 e7 ee ff ff       	call   f0100121 <_panic>
	assert((pp2 = page_alloc(0)));
f010123a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101241:	e8 00 fd ff ff       	call   f0100f46 <page_alloc>
f0101246:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101249:	85 c0                	test   %eax,%eax
f010124b:	75 24                	jne    f0101271 <mem_init+0x245>
f010124d:	c7 44 24 0c b4 31 10 	movl   $0xf01031b4,0xc(%esp)
f0101254:	f0 
f0101255:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f010125c:	f0 
f010125d:	c7 44 24 04 54 02 00 	movl   $0x254,0x4(%esp)
f0101264:	00 
f0101265:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f010126c:	e8 b0 ee ff ff       	call   f0100121 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101271:	39 f7                	cmp    %esi,%edi
f0101273:	75 24                	jne    f0101299 <mem_init+0x26d>
f0101275:	c7 44 24 0c ca 31 10 	movl   $0xf01031ca,0xc(%esp)
f010127c:	f0 
f010127d:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f0101284:	f0 
f0101285:	c7 44 24 04 57 02 00 	movl   $0x257,0x4(%esp)
f010128c:	00 
f010128d:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f0101294:	e8 88 ee ff ff       	call   f0100121 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101299:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010129c:	39 c6                	cmp    %eax,%esi
f010129e:	74 04                	je     f01012a4 <mem_init+0x278>
f01012a0:	39 c7                	cmp    %eax,%edi
f01012a2:	75 24                	jne    f01012c8 <mem_init+0x29c>
f01012a4:	c7 44 24 0c 30 30 10 	movl   $0xf0103030,0xc(%esp)
f01012ab:	f0 
f01012ac:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f01012b3:	f0 
f01012b4:	c7 44 24 04 58 02 00 	movl   $0x258,0x4(%esp)
f01012bb:	00 
f01012bc:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f01012c3:	e8 59 ee ff ff       	call   f0100121 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012c8:	8b 15 6c 59 11 f0    	mov    0xf011596c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f01012ce:	a1 64 59 11 f0       	mov    0xf0115964,%eax
f01012d3:	c1 e0 0c             	shl    $0xc,%eax
f01012d6:	89 f9                	mov    %edi,%ecx
f01012d8:	29 d1                	sub    %edx,%ecx
f01012da:	c1 f9 03             	sar    $0x3,%ecx
f01012dd:	c1 e1 0c             	shl    $0xc,%ecx
f01012e0:	39 c1                	cmp    %eax,%ecx
f01012e2:	72 24                	jb     f0101308 <mem_init+0x2dc>
f01012e4:	c7 44 24 0c dc 31 10 	movl   $0xf01031dc,0xc(%esp)
f01012eb:	f0 
f01012ec:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f01012f3:	f0 
f01012f4:	c7 44 24 04 59 02 00 	movl   $0x259,0x4(%esp)
f01012fb:	00 
f01012fc:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f0101303:	e8 19 ee ff ff       	call   f0100121 <_panic>
f0101308:	89 f1                	mov    %esi,%ecx
f010130a:	29 d1                	sub    %edx,%ecx
f010130c:	c1 f9 03             	sar    $0x3,%ecx
f010130f:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101312:	39 c8                	cmp    %ecx,%eax
f0101314:	77 24                	ja     f010133a <mem_init+0x30e>
f0101316:	c7 44 24 0c f9 31 10 	movl   $0xf01031f9,0xc(%esp)
f010131d:	f0 
f010131e:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f0101325:	f0 
f0101326:	c7 44 24 04 5a 02 00 	movl   $0x25a,0x4(%esp)
f010132d:	00 
f010132e:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f0101335:	e8 e7 ed ff ff       	call   f0100121 <_panic>
f010133a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010133d:	29 d1                	sub    %edx,%ecx
f010133f:	89 ca                	mov    %ecx,%edx
f0101341:	c1 fa 03             	sar    $0x3,%edx
f0101344:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101347:	39 d0                	cmp    %edx,%eax
f0101349:	77 24                	ja     f010136f <mem_init+0x343>
f010134b:	c7 44 24 0c 16 32 10 	movl   $0xf0103216,0xc(%esp)
f0101352:	f0 
f0101353:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f010135a:	f0 
f010135b:	c7 44 24 04 5b 02 00 	movl   $0x25b,0x4(%esp)
f0101362:	00 
f0101363:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f010136a:	e8 b2 ed ff ff       	call   f0100121 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010136f:	a1 40 55 11 f0       	mov    0xf0115540,%eax
f0101374:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f0101377:	c7 05 40 55 11 f0 00 	movl   $0x0,0xf0115540
f010137e:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101381:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101388:	e8 b9 fb ff ff       	call   f0100f46 <page_alloc>
f010138d:	85 c0                	test   %eax,%eax
f010138f:	74 24                	je     f01013b5 <mem_init+0x389>
f0101391:	c7 44 24 0c 33 32 10 	movl   $0xf0103233,0xc(%esp)
f0101398:	f0 
f0101399:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f01013a0:	f0 
f01013a1:	c7 44 24 04 62 02 00 	movl   $0x262,0x4(%esp)
f01013a8:	00 
f01013a9:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f01013b0:	e8 6c ed ff ff       	call   f0100121 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01013b5:	89 3c 24             	mov    %edi,(%esp)
f01013b8:	e8 14 fc ff ff       	call   f0100fd1 <page_free>
	page_free(pp1);
f01013bd:	89 34 24             	mov    %esi,(%esp)
f01013c0:	e8 0c fc ff ff       	call   f0100fd1 <page_free>
	page_free(pp2);
f01013c5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01013c8:	89 04 24             	mov    %eax,(%esp)
f01013cb:	e8 01 fc ff ff       	call   f0100fd1 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013d0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013d7:	e8 6a fb ff ff       	call   f0100f46 <page_alloc>
f01013dc:	89 c6                	mov    %eax,%esi
f01013de:	85 c0                	test   %eax,%eax
f01013e0:	75 24                	jne    f0101406 <mem_init+0x3da>
f01013e2:	c7 44 24 0c 88 31 10 	movl   $0xf0103188,0xc(%esp)
f01013e9:	f0 
f01013ea:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f01013f1:	f0 
f01013f2:	c7 44 24 04 69 02 00 	movl   $0x269,0x4(%esp)
f01013f9:	00 
f01013fa:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f0101401:	e8 1b ed ff ff       	call   f0100121 <_panic>
	assert((pp1 = page_alloc(0)));
f0101406:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010140d:	e8 34 fb ff ff       	call   f0100f46 <page_alloc>
f0101412:	89 c7                	mov    %eax,%edi
f0101414:	85 c0                	test   %eax,%eax
f0101416:	75 24                	jne    f010143c <mem_init+0x410>
f0101418:	c7 44 24 0c 9e 31 10 	movl   $0xf010319e,0xc(%esp)
f010141f:	f0 
f0101420:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f0101427:	f0 
f0101428:	c7 44 24 04 6a 02 00 	movl   $0x26a,0x4(%esp)
f010142f:	00 
f0101430:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f0101437:	e8 e5 ec ff ff       	call   f0100121 <_panic>
	assert((pp2 = page_alloc(0)));
f010143c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101443:	e8 fe fa ff ff       	call   f0100f46 <page_alloc>
f0101448:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010144b:	85 c0                	test   %eax,%eax
f010144d:	75 24                	jne    f0101473 <mem_init+0x447>
f010144f:	c7 44 24 0c b4 31 10 	movl   $0xf01031b4,0xc(%esp)
f0101456:	f0 
f0101457:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f010145e:	f0 
f010145f:	c7 44 24 04 6b 02 00 	movl   $0x26b,0x4(%esp)
f0101466:	00 
f0101467:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f010146e:	e8 ae ec ff ff       	call   f0100121 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101473:	39 fe                	cmp    %edi,%esi
f0101475:	75 24                	jne    f010149b <mem_init+0x46f>
f0101477:	c7 44 24 0c ca 31 10 	movl   $0xf01031ca,0xc(%esp)
f010147e:	f0 
f010147f:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f0101486:	f0 
f0101487:	c7 44 24 04 6d 02 00 	movl   $0x26d,0x4(%esp)
f010148e:	00 
f010148f:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f0101496:	e8 86 ec ff ff       	call   f0100121 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010149b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010149e:	39 c7                	cmp    %eax,%edi
f01014a0:	74 04                	je     f01014a6 <mem_init+0x47a>
f01014a2:	39 c6                	cmp    %eax,%esi
f01014a4:	75 24                	jne    f01014ca <mem_init+0x49e>
f01014a6:	c7 44 24 0c 30 30 10 	movl   $0xf0103030,0xc(%esp)
f01014ad:	f0 
f01014ae:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f01014b5:	f0 
f01014b6:	c7 44 24 04 6e 02 00 	movl   $0x26e,0x4(%esp)
f01014bd:	00 
f01014be:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f01014c5:	e8 57 ec ff ff       	call   f0100121 <_panic>
	assert(!page_alloc(0));
f01014ca:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014d1:	e8 70 fa ff ff       	call   f0100f46 <page_alloc>
f01014d6:	85 c0                	test   %eax,%eax
f01014d8:	74 24                	je     f01014fe <mem_init+0x4d2>
f01014da:	c7 44 24 0c 33 32 10 	movl   $0xf0103233,0xc(%esp)
f01014e1:	f0 
f01014e2:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f01014e9:	f0 
f01014ea:	c7 44 24 04 6f 02 00 	movl   $0x26f,0x4(%esp)
f01014f1:	00 
f01014f2:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f01014f9:	e8 23 ec ff ff       	call   f0100121 <_panic>
f01014fe:	89 f0                	mov    %esi,%eax
f0101500:	2b 05 6c 59 11 f0    	sub    0xf011596c,%eax
f0101506:	c1 f8 03             	sar    $0x3,%eax
f0101509:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010150c:	89 c2                	mov    %eax,%edx
f010150e:	c1 ea 0c             	shr    $0xc,%edx
f0101511:	3b 15 64 59 11 f0    	cmp    0xf0115964,%edx
f0101517:	72 20                	jb     f0101539 <mem_init+0x50d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101519:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010151d:	c7 44 24 08 24 2e 10 	movl   $0xf0102e24,0x8(%esp)
f0101524:	f0 
f0101525:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010152c:	00 
f010152d:	c7 04 24 ac 30 10 f0 	movl   $0xf01030ac,(%esp)
f0101534:	e8 e8 eb ff ff       	call   f0100121 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101539:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101540:	00 
f0101541:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101548:	00 
	return (void *)(pa + KERNBASE);
f0101549:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010154e:	89 04 24             	mov    %eax,(%esp)
f0101551:	e8 c1 0e 00 00       	call   f0102417 <memset>
	page_free(pp0);
f0101556:	89 34 24             	mov    %esi,(%esp)
f0101559:	e8 73 fa ff ff       	call   f0100fd1 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010155e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101565:	e8 dc f9 ff ff       	call   f0100f46 <page_alloc>
f010156a:	85 c0                	test   %eax,%eax
f010156c:	75 24                	jne    f0101592 <mem_init+0x566>
f010156e:	c7 44 24 0c 42 32 10 	movl   $0xf0103242,0xc(%esp)
f0101575:	f0 
f0101576:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f010157d:	f0 
f010157e:	c7 44 24 04 74 02 00 	movl   $0x274,0x4(%esp)
f0101585:	00 
f0101586:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f010158d:	e8 8f eb ff ff       	call   f0100121 <_panic>
	assert(pp && pp0 == pp);
f0101592:	39 c6                	cmp    %eax,%esi
f0101594:	74 24                	je     f01015ba <mem_init+0x58e>
f0101596:	c7 44 24 0c 60 32 10 	movl   $0xf0103260,0xc(%esp)
f010159d:	f0 
f010159e:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f01015a5:	f0 
f01015a6:	c7 44 24 04 75 02 00 	movl   $0x275,0x4(%esp)
f01015ad:	00 
f01015ae:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f01015b5:	e8 67 eb ff ff       	call   f0100121 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01015ba:	89 f0                	mov    %esi,%eax
f01015bc:	2b 05 6c 59 11 f0    	sub    0xf011596c,%eax
f01015c2:	c1 f8 03             	sar    $0x3,%eax
f01015c5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01015c8:	89 c2                	mov    %eax,%edx
f01015ca:	c1 ea 0c             	shr    $0xc,%edx
f01015cd:	3b 15 64 59 11 f0    	cmp    0xf0115964,%edx
f01015d3:	72 20                	jb     f01015f5 <mem_init+0x5c9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01015d5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01015d9:	c7 44 24 08 24 2e 10 	movl   $0xf0102e24,0x8(%esp)
f01015e0:	f0 
f01015e1:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01015e8:	00 
f01015e9:	c7 04 24 ac 30 10 f0 	movl   $0xf01030ac,(%esp)
f01015f0:	e8 2c eb ff ff       	call   f0100121 <_panic>
f01015f5:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01015fb:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101601:	80 38 00             	cmpb   $0x0,(%eax)
f0101604:	74 24                	je     f010162a <mem_init+0x5fe>
f0101606:	c7 44 24 0c 70 32 10 	movl   $0xf0103270,0xc(%esp)
f010160d:	f0 
f010160e:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f0101615:	f0 
f0101616:	c7 44 24 04 78 02 00 	movl   $0x278,0x4(%esp)
f010161d:	00 
f010161e:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f0101625:	e8 f7 ea ff ff       	call   f0100121 <_panic>
f010162a:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010162d:	39 d0                	cmp    %edx,%eax
f010162f:	75 d0                	jne    f0101601 <mem_init+0x5d5>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101631:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101634:	a3 40 55 11 f0       	mov    %eax,0xf0115540

	// free the pages we took
	page_free(pp0);
f0101639:	89 34 24             	mov    %esi,(%esp)
f010163c:	e8 90 f9 ff ff       	call   f0100fd1 <page_free>
	page_free(pp1);
f0101641:	89 3c 24             	mov    %edi,(%esp)
f0101644:	e8 88 f9 ff ff       	call   f0100fd1 <page_free>
	page_free(pp2);
f0101649:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010164c:	89 04 24             	mov    %eax,(%esp)
f010164f:	e8 7d f9 ff ff       	call   f0100fd1 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101654:	a1 40 55 11 f0       	mov    0xf0115540,%eax
f0101659:	eb 05                	jmp    f0101660 <mem_init+0x634>
		--nfree;
f010165b:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010165e:	8b 00                	mov    (%eax),%eax
f0101660:	85 c0                	test   %eax,%eax
f0101662:	75 f7                	jne    f010165b <mem_init+0x62f>
		--nfree;
	assert(nfree == 0);
f0101664:	85 db                	test   %ebx,%ebx
f0101666:	74 24                	je     f010168c <mem_init+0x660>
f0101668:	c7 44 24 0c 7a 32 10 	movl   $0xf010327a,0xc(%esp)
f010166f:	f0 
f0101670:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f0101677:	f0 
f0101678:	c7 44 24 04 85 02 00 	movl   $0x285,0x4(%esp)
f010167f:	00 
f0101680:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f0101687:	e8 95 ea ff ff       	call   f0100121 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010168c:	c7 04 24 50 30 10 f0 	movl   $0xf0103050,(%esp)
f0101693:	e8 17 02 00 00       	call   f01018af <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101698:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010169f:	e8 a2 f8 ff ff       	call   f0100f46 <page_alloc>
f01016a4:	89 c3                	mov    %eax,%ebx
f01016a6:	85 c0                	test   %eax,%eax
f01016a8:	75 24                	jne    f01016ce <mem_init+0x6a2>
f01016aa:	c7 44 24 0c 88 31 10 	movl   $0xf0103188,0xc(%esp)
f01016b1:	f0 
f01016b2:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f01016b9:	f0 
f01016ba:	c7 44 24 04 de 02 00 	movl   $0x2de,0x4(%esp)
f01016c1:	00 
f01016c2:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f01016c9:	e8 53 ea ff ff       	call   f0100121 <_panic>
	assert((pp1 = page_alloc(0)));
f01016ce:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016d5:	e8 6c f8 ff ff       	call   f0100f46 <page_alloc>
f01016da:	89 c6                	mov    %eax,%esi
f01016dc:	85 c0                	test   %eax,%eax
f01016de:	75 24                	jne    f0101704 <mem_init+0x6d8>
f01016e0:	c7 44 24 0c 9e 31 10 	movl   $0xf010319e,0xc(%esp)
f01016e7:	f0 
f01016e8:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f01016ef:	f0 
f01016f0:	c7 44 24 04 df 02 00 	movl   $0x2df,0x4(%esp)
f01016f7:	00 
f01016f8:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f01016ff:	e8 1d ea ff ff       	call   f0100121 <_panic>
	assert((pp2 = page_alloc(0)));
f0101704:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010170b:	e8 36 f8 ff ff       	call   f0100f46 <page_alloc>
f0101710:	85 c0                	test   %eax,%eax
f0101712:	75 24                	jne    f0101738 <mem_init+0x70c>
f0101714:	c7 44 24 0c b4 31 10 	movl   $0xf01031b4,0xc(%esp)
f010171b:	f0 
f010171c:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f0101723:	f0 
f0101724:	c7 44 24 04 e0 02 00 	movl   $0x2e0,0x4(%esp)
f010172b:	00 
f010172c:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f0101733:	e8 e9 e9 ff ff       	call   f0100121 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101738:	39 f3                	cmp    %esi,%ebx
f010173a:	75 24                	jne    f0101760 <mem_init+0x734>
f010173c:	c7 44 24 0c ca 31 10 	movl   $0xf01031ca,0xc(%esp)
f0101743:	f0 
f0101744:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f010174b:	f0 
f010174c:	c7 44 24 04 e3 02 00 	movl   $0x2e3,0x4(%esp)
f0101753:	00 
f0101754:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f010175b:	e8 c1 e9 ff ff       	call   f0100121 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101760:	39 c6                	cmp    %eax,%esi
f0101762:	74 04                	je     f0101768 <mem_init+0x73c>
f0101764:	39 c3                	cmp    %eax,%ebx
f0101766:	75 24                	jne    f010178c <mem_init+0x760>
f0101768:	c7 44 24 0c 30 30 10 	movl   $0xf0103030,0xc(%esp)
f010176f:	f0 
f0101770:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f0101777:	f0 
f0101778:	c7 44 24 04 e4 02 00 	movl   $0x2e4,0x4(%esp)
f010177f:	00 
f0101780:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f0101787:	e8 95 e9 ff ff       	call   f0100121 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
	page_free_list = 0;
f010178c:	c7 05 40 55 11 f0 00 	movl   $0x0,0xf0115540
f0101793:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101796:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010179d:	e8 a4 f7 ff ff       	call   f0100f46 <page_alloc>
f01017a2:	85 c0                	test   %eax,%eax
f01017a4:	74 24                	je     f01017ca <mem_init+0x79e>
f01017a6:	c7 44 24 0c 33 32 10 	movl   $0xf0103233,0xc(%esp)
f01017ad:	f0 
f01017ae:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f01017b5:	f0 
f01017b6:	c7 44 24 04 eb 02 00 	movl   $0x2eb,0x4(%esp)
f01017bd:	00 
f01017be:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f01017c5:	e8 57 e9 ff ff       	call   f0100121 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01017ca:	c7 44 24 0c 70 30 10 	movl   $0xf0103070,0xc(%esp)
f01017d1:	f0 
f01017d2:	c7 44 24 08 c6 30 10 	movl   $0xf01030c6,0x8(%esp)
f01017d9:	f0 
f01017da:	c7 44 24 04 f1 02 00 	movl   $0x2f1,0x4(%esp)
f01017e1:	00 
f01017e2:	c7 04 24 a0 30 10 f0 	movl   $0xf01030a0,(%esp)
f01017e9:	e8 33 e9 ff ff       	call   f0100121 <_panic>

f01017ee <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f01017ee:	55                   	push   %ebp
f01017ef:	89 e5                	mov    %esp,%ebp
f01017f1:	83 ec 18             	sub    $0x18,%esp
f01017f4:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f01017f7:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f01017fb:	8d 51 ff             	lea    -0x1(%ecx),%edx
f01017fe:	66 89 50 04          	mov    %dx,0x4(%eax)
f0101802:	66 85 d2             	test   %dx,%dx
f0101805:	75 08                	jne    f010180f <page_decref+0x21>
		page_free(pp);
f0101807:	89 04 24             	mov    %eax,(%esp)
f010180a:	e8 c2 f7 ff ff       	call   f0100fd1 <page_free>
}
f010180f:	c9                   	leave  
f0101810:	c3                   	ret    

f0101811 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101811:	55                   	push   %ebp
f0101812:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0101814:	b8 00 00 00 00       	mov    $0x0,%eax
f0101819:	5d                   	pop    %ebp
f010181a:	c3                   	ret    

f010181b <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010181b:	55                   	push   %ebp
f010181c:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f010181e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101823:	5d                   	pop    %ebp
f0101824:	c3                   	ret    

f0101825 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101825:	55                   	push   %ebp
f0101826:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0101828:	b8 00 00 00 00       	mov    $0x0,%eax
f010182d:	5d                   	pop    %ebp
f010182e:	c3                   	ret    

f010182f <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f010182f:	55                   	push   %ebp
f0101830:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0101832:	5d                   	pop    %ebp
f0101833:	c3                   	ret    

f0101834 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101834:	55                   	push   %ebp
f0101835:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101837:	8b 45 0c             	mov    0xc(%ebp),%eax
f010183a:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010183d:	5d                   	pop    %ebp
f010183e:	c3                   	ret    

f010183f <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010183f:	55                   	push   %ebp
f0101840:	89 e5                	mov    %esp,%ebp
f0101842:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0101846:	ba 70 00 00 00       	mov    $0x70,%edx
f010184b:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010184c:	b2 71                	mov    $0x71,%dl
f010184e:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f010184f:	0f b6 c0             	movzbl %al,%eax
}
f0101852:	5d                   	pop    %ebp
f0101853:	c3                   	ret    

f0101854 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0101854:	55                   	push   %ebp
f0101855:	89 e5                	mov    %esp,%ebp
f0101857:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010185b:	ba 70 00 00 00       	mov    $0x70,%edx
f0101860:	ee                   	out    %al,(%dx)
f0101861:	b2 71                	mov    $0x71,%dl
f0101863:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101866:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0101867:	5d                   	pop    %ebp
f0101868:	c3                   	ret    

f0101869 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0101869:	55                   	push   %ebp
f010186a:	89 e5                	mov    %esp,%ebp
f010186c:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010186f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101872:	89 04 24             	mov    %eax,(%esp)
f0101875:	e8 07 ee ff ff       	call   f0100681 <cputchar>
	*cnt++;
}
f010187a:	c9                   	leave  
f010187b:	c3                   	ret    

f010187c <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010187c:	55                   	push   %ebp
f010187d:	89 e5                	mov    %esp,%ebp
f010187f:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0101882:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0101889:	8b 45 0c             	mov    0xc(%ebp),%eax
f010188c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101890:	8b 45 08             	mov    0x8(%ebp),%eax
f0101893:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101897:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010189a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010189e:	c7 04 24 69 18 10 f0 	movl   $0xf0101869,(%esp)
f01018a5:	e8 b4 04 00 00       	call   f0101d5e <vprintfmt>
	return cnt;
}
f01018aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01018ad:	c9                   	leave  
f01018ae:	c3                   	ret    

f01018af <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01018af:	55                   	push   %ebp
f01018b0:	89 e5                	mov    %esp,%ebp
f01018b2:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01018b5:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01018b8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01018bc:	8b 45 08             	mov    0x8(%ebp),%eax
f01018bf:	89 04 24             	mov    %eax,(%esp)
f01018c2:	e8 b5 ff ff ff       	call   f010187c <vcprintf>
	va_end(ap);

	return cnt;
}
f01018c7:	c9                   	leave  
f01018c8:	c3                   	ret    

f01018c9 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01018c9:	55                   	push   %ebp
f01018ca:	89 e5                	mov    %esp,%ebp
f01018cc:	57                   	push   %edi
f01018cd:	56                   	push   %esi
f01018ce:	53                   	push   %ebx
f01018cf:	83 ec 10             	sub    $0x10,%esp
f01018d2:	89 c6                	mov    %eax,%esi
f01018d4:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01018d7:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01018da:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01018dd:	8b 1a                	mov    (%edx),%ebx
f01018df:	8b 01                	mov    (%ecx),%eax
f01018e1:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01018e4:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f01018eb:	eb 77                	jmp    f0101964 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f01018ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01018f0:	01 d8                	add    %ebx,%eax
f01018f2:	b9 02 00 00 00       	mov    $0x2,%ecx
f01018f7:	99                   	cltd   
f01018f8:	f7 f9                	idiv   %ecx
f01018fa:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01018fc:	eb 01                	jmp    f01018ff <stab_binsearch+0x36>
			m--;
f01018fe:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01018ff:	39 d9                	cmp    %ebx,%ecx
f0101901:	7c 1d                	jl     f0101920 <stab_binsearch+0x57>
f0101903:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0101906:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f010190b:	39 fa                	cmp    %edi,%edx
f010190d:	75 ef                	jne    f01018fe <stab_binsearch+0x35>
f010190f:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0101912:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0101915:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0101919:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010191c:	73 18                	jae    f0101936 <stab_binsearch+0x6d>
f010191e:	eb 05                	jmp    f0101925 <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0101920:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0101923:	eb 3f                	jmp    f0101964 <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0101925:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0101928:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f010192a:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010192d:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0101934:	eb 2e                	jmp    f0101964 <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0101936:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0101939:	73 15                	jae    f0101950 <stab_binsearch+0x87>
			*region_right = m - 1;
f010193b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010193e:	48                   	dec    %eax
f010193f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101942:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101945:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0101947:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f010194e:	eb 14                	jmp    f0101964 <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0101950:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101953:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0101956:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0101958:	ff 45 0c             	incl   0xc(%ebp)
f010195b:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010195d:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0101964:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0101967:	7e 84                	jle    f01018ed <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0101969:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f010196d:	75 0d                	jne    f010197c <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f010196f:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101972:	8b 00                	mov    (%eax),%eax
f0101974:	48                   	dec    %eax
f0101975:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101978:	89 07                	mov    %eax,(%edi)
f010197a:	eb 22                	jmp    f010199e <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010197c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010197f:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0101981:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0101984:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101986:	eb 01                	jmp    f0101989 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0101988:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101989:	39 c1                	cmp    %eax,%ecx
f010198b:	7d 0c                	jge    f0101999 <stab_binsearch+0xd0>
f010198d:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0101990:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0101995:	39 fa                	cmp    %edi,%edx
f0101997:	75 ef                	jne    f0101988 <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0101999:	8b 7d e8             	mov    -0x18(%ebp),%edi
f010199c:	89 07                	mov    %eax,(%edi)
	}
}
f010199e:	83 c4 10             	add    $0x10,%esp
f01019a1:	5b                   	pop    %ebx
f01019a2:	5e                   	pop    %esi
f01019a3:	5f                   	pop    %edi
f01019a4:	5d                   	pop    %ebp
f01019a5:	c3                   	ret    

f01019a6 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01019a6:	55                   	push   %ebp
f01019a7:	89 e5                	mov    %esp,%ebp
f01019a9:	57                   	push   %edi
f01019aa:	56                   	push   %esi
f01019ab:	53                   	push   %ebx
f01019ac:	83 ec 3c             	sub    $0x3c,%esp
f01019af:	8b 75 08             	mov    0x8(%ebp),%esi
f01019b2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01019b5:	c7 03 85 32 10 f0    	movl   $0xf0103285,(%ebx)
	info->eip_line = 0;
f01019bb:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01019c2:	c7 43 08 85 32 10 f0 	movl   $0xf0103285,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01019c9:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01019d0:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01019d3:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01019da:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01019e0:	76 12                	jbe    f01019f4 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01019e2:	b8 2c a0 10 f0       	mov    $0xf010a02c,%eax
f01019e7:	3d 0d 83 10 f0       	cmp    $0xf010830d,%eax
f01019ec:	0f 86 cd 01 00 00    	jbe    f0101bbf <debuginfo_eip+0x219>
f01019f2:	eb 1c                	jmp    f0101a10 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01019f4:	c7 44 24 08 8f 32 10 	movl   $0xf010328f,0x8(%esp)
f01019fb:	f0 
f01019fc:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0101a03:	00 
f0101a04:	c7 04 24 9c 32 10 f0 	movl   $0xf010329c,(%esp)
f0101a0b:	e8 11 e7 ff ff       	call   f0100121 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101a10:	80 3d 2b a0 10 f0 00 	cmpb   $0x0,0xf010a02b
f0101a17:	0f 85 a9 01 00 00    	jne    f0101bc6 <debuginfo_eip+0x220>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0101a1d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0101a24:	b8 0c 83 10 f0       	mov    $0xf010830c,%eax
f0101a29:	2d d0 34 10 f0       	sub    $0xf01034d0,%eax
f0101a2e:	c1 f8 02             	sar    $0x2,%eax
f0101a31:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0101a37:	83 e8 01             	sub    $0x1,%eax
f0101a3a:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0101a3d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101a41:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0101a48:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0101a4b:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0101a4e:	b8 d0 34 10 f0       	mov    $0xf01034d0,%eax
f0101a53:	e8 71 fe ff ff       	call   f01018c9 <stab_binsearch>
	if (lfile == 0)
f0101a58:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101a5b:	85 c0                	test   %eax,%eax
f0101a5d:	0f 84 6a 01 00 00    	je     f0101bcd <debuginfo_eip+0x227>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0101a63:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0101a66:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101a69:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0101a6c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101a70:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0101a77:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0101a7a:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0101a7d:	b8 d0 34 10 f0       	mov    $0xf01034d0,%eax
f0101a82:	e8 42 fe ff ff       	call   f01018c9 <stab_binsearch>

	if (lfun <= rfun) {
f0101a87:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101a8a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101a8d:	39 d0                	cmp    %edx,%eax
f0101a8f:	7f 3d                	jg     f0101ace <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0101a91:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0101a94:	8d b9 d0 34 10 f0    	lea    -0xfefcb30(%ecx),%edi
f0101a9a:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0101a9d:	8b 89 d0 34 10 f0    	mov    -0xfefcb30(%ecx),%ecx
f0101aa3:	bf 2c a0 10 f0       	mov    $0xf010a02c,%edi
f0101aa8:	81 ef 0d 83 10 f0    	sub    $0xf010830d,%edi
f0101aae:	39 f9                	cmp    %edi,%ecx
f0101ab0:	73 09                	jae    f0101abb <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0101ab2:	81 c1 0d 83 10 f0    	add    $0xf010830d,%ecx
f0101ab8:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0101abb:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0101abe:	8b 4f 08             	mov    0x8(%edi),%ecx
f0101ac1:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0101ac4:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0101ac6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0101ac9:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101acc:	eb 0f                	jmp    f0101add <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0101ace:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0101ad1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101ad4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0101ad7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101ada:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0101add:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0101ae4:	00 
f0101ae5:	8b 43 08             	mov    0x8(%ebx),%eax
f0101ae8:	89 04 24             	mov    %eax,(%esp)
f0101aeb:	e8 0b 09 00 00       	call   f01023fb <strfind>
f0101af0:	2b 43 08             	sub    0x8(%ebx),%eax
f0101af3:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
f0101af6:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101afa:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0101b01:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0101b04:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0101b07:	b8 d0 34 10 f0       	mov    $0xf01034d0,%eax
f0101b0c:	e8 b8 fd ff ff       	call   f01018c9 <stab_binsearch>
	if (lline > rline) {
f0101b11:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b14:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0101b17:	0f 8f b7 00 00 00    	jg     f0101bd4 <debuginfo_eip+0x22e>
		return -1; //Did not find the line number in the stab
	}
	info->eip_line = stabs[lline].n_desc; //If found update the info object with the correct line number
f0101b1d:	6b c0 0c             	imul   $0xc,%eax,%eax
f0101b20:	0f b7 80 d6 34 10 f0 	movzwl -0xfefcb2a(%eax),%eax
f0101b27:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0101b2a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101b2d:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0101b30:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b33:	6b d0 0c             	imul   $0xc,%eax,%edx
f0101b36:	81 c2 d0 34 10 f0    	add    $0xf01034d0,%edx
f0101b3c:	eb 06                	jmp    f0101b44 <debuginfo_eip+0x19e>
f0101b3e:	83 e8 01             	sub    $0x1,%eax
f0101b41:	83 ea 0c             	sub    $0xc,%edx
f0101b44:	89 c6                	mov    %eax,%esi
f0101b46:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0101b49:	7f 33                	jg     f0101b7e <debuginfo_eip+0x1d8>
	       && stabs[lline].n_type != N_SOL
f0101b4b:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0101b4f:	80 f9 84             	cmp    $0x84,%cl
f0101b52:	74 0b                	je     f0101b5f <debuginfo_eip+0x1b9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0101b54:	80 f9 64             	cmp    $0x64,%cl
f0101b57:	75 e5                	jne    f0101b3e <debuginfo_eip+0x198>
f0101b59:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0101b5d:	74 df                	je     f0101b3e <debuginfo_eip+0x198>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0101b5f:	6b f6 0c             	imul   $0xc,%esi,%esi
f0101b62:	8b 86 d0 34 10 f0    	mov    -0xfefcb30(%esi),%eax
f0101b68:	ba 2c a0 10 f0       	mov    $0xf010a02c,%edx
f0101b6d:	81 ea 0d 83 10 f0    	sub    $0xf010830d,%edx
f0101b73:	39 d0                	cmp    %edx,%eax
f0101b75:	73 07                	jae    f0101b7e <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0101b77:	05 0d 83 10 f0       	add    $0xf010830d,%eax
f0101b7c:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0101b7e:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101b81:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101b84:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0101b89:	39 ca                	cmp    %ecx,%edx
f0101b8b:	7d 53                	jge    f0101be0 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
f0101b8d:	8d 42 01             	lea    0x1(%edx),%eax
f0101b90:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101b93:	89 c2                	mov    %eax,%edx
f0101b95:	6b c0 0c             	imul   $0xc,%eax,%eax
f0101b98:	05 d0 34 10 f0       	add    $0xf01034d0,%eax
f0101b9d:	89 ce                	mov    %ecx,%esi
f0101b9f:	eb 04                	jmp    f0101ba5 <debuginfo_eip+0x1ff>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0101ba1:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0101ba5:	39 d6                	cmp    %edx,%esi
f0101ba7:	7e 32                	jle    f0101bdb <debuginfo_eip+0x235>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0101ba9:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0101bad:	83 c2 01             	add    $0x1,%edx
f0101bb0:	83 c0 0c             	add    $0xc,%eax
f0101bb3:	80 f9 a0             	cmp    $0xa0,%cl
f0101bb6:	74 e9                	je     f0101ba1 <debuginfo_eip+0x1fb>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101bb8:	b8 00 00 00 00       	mov    $0x0,%eax
f0101bbd:	eb 21                	jmp    f0101be0 <debuginfo_eip+0x23a>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0101bbf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101bc4:	eb 1a                	jmp    f0101be0 <debuginfo_eip+0x23a>
f0101bc6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101bcb:	eb 13                	jmp    f0101be0 <debuginfo_eip+0x23a>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0101bcd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101bd2:	eb 0c                	jmp    f0101be0 <debuginfo_eip+0x23a>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
	if (lline > rline) {
		return -1; //Did not find the line number in the stab
f0101bd4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101bd9:	eb 05                	jmp    f0101be0 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101bdb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101be0:	83 c4 3c             	add    $0x3c,%esp
f0101be3:	5b                   	pop    %ebx
f0101be4:	5e                   	pop    %esi
f0101be5:	5f                   	pop    %edi
f0101be6:	5d                   	pop    %ebp
f0101be7:	c3                   	ret    
f0101be8:	66 90                	xchg   %ax,%ax
f0101bea:	66 90                	xchg   %ax,%ax
f0101bec:	66 90                	xchg   %ax,%ax
f0101bee:	66 90                	xchg   %ax,%ax

f0101bf0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0101bf0:	55                   	push   %ebp
f0101bf1:	89 e5                	mov    %esp,%ebp
f0101bf3:	57                   	push   %edi
f0101bf4:	56                   	push   %esi
f0101bf5:	53                   	push   %ebx
f0101bf6:	83 ec 3c             	sub    $0x3c,%esp
f0101bf9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101bfc:	89 d7                	mov    %edx,%edi
f0101bfe:	8b 45 08             	mov    0x8(%ebp),%eax
f0101c01:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101c04:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101c07:	89 c3                	mov    %eax,%ebx
f0101c09:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101c0c:	8b 45 10             	mov    0x10(%ebp),%eax
f0101c0f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0101c12:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101c17:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101c1a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101c1d:	39 d9                	cmp    %ebx,%ecx
f0101c1f:	72 05                	jb     f0101c26 <printnum+0x36>
f0101c21:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0101c24:	77 69                	ja     f0101c8f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0101c26:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0101c29:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101c2d:	83 ee 01             	sub    $0x1,%esi
f0101c30:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0101c34:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101c38:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101c3c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101c40:	89 c3                	mov    %eax,%ebx
f0101c42:	89 d6                	mov    %edx,%esi
f0101c44:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101c47:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101c4a:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101c4e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0101c52:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101c55:	89 04 24             	mov    %eax,(%esp)
f0101c58:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c5b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101c5f:	e8 bc 09 00 00       	call   f0102620 <__udivdi3>
f0101c64:	89 d9                	mov    %ebx,%ecx
f0101c66:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101c6a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0101c6e:	89 04 24             	mov    %eax,(%esp)
f0101c71:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101c75:	89 fa                	mov    %edi,%edx
f0101c77:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101c7a:	e8 71 ff ff ff       	call   f0101bf0 <printnum>
f0101c7f:	eb 1b                	jmp    f0101c9c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0101c81:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101c85:	8b 45 18             	mov    0x18(%ebp),%eax
f0101c88:	89 04 24             	mov    %eax,(%esp)
f0101c8b:	ff d3                	call   *%ebx
f0101c8d:	eb 03                	jmp    f0101c92 <printnum+0xa2>
f0101c8f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0101c92:	83 ee 01             	sub    $0x1,%esi
f0101c95:	85 f6                	test   %esi,%esi
f0101c97:	7f e8                	jg     f0101c81 <printnum+0x91>
f0101c99:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0101c9c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101ca0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101ca4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101ca7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101caa:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101cae:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101cb2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101cb5:	89 04 24             	mov    %eax,(%esp)
f0101cb8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101cbb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101cbf:	e8 8c 0a 00 00       	call   f0102750 <__umoddi3>
f0101cc4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101cc8:	0f be 80 aa 32 10 f0 	movsbl -0xfefcd56(%eax),%eax
f0101ccf:	89 04 24             	mov    %eax,(%esp)
f0101cd2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101cd5:	ff d0                	call   *%eax
}
f0101cd7:	83 c4 3c             	add    $0x3c,%esp
f0101cda:	5b                   	pop    %ebx
f0101cdb:	5e                   	pop    %esi
f0101cdc:	5f                   	pop    %edi
f0101cdd:	5d                   	pop    %ebp
f0101cde:	c3                   	ret    

f0101cdf <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0101cdf:	55                   	push   %ebp
f0101ce0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0101ce2:	83 fa 01             	cmp    $0x1,%edx
f0101ce5:	7e 0e                	jle    f0101cf5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0101ce7:	8b 10                	mov    (%eax),%edx
f0101ce9:	8d 4a 08             	lea    0x8(%edx),%ecx
f0101cec:	89 08                	mov    %ecx,(%eax)
f0101cee:	8b 02                	mov    (%edx),%eax
f0101cf0:	8b 52 04             	mov    0x4(%edx),%edx
f0101cf3:	eb 22                	jmp    f0101d17 <getuint+0x38>
	else if (lflag)
f0101cf5:	85 d2                	test   %edx,%edx
f0101cf7:	74 10                	je     f0101d09 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0101cf9:	8b 10                	mov    (%eax),%edx
f0101cfb:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101cfe:	89 08                	mov    %ecx,(%eax)
f0101d00:	8b 02                	mov    (%edx),%eax
f0101d02:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d07:	eb 0e                	jmp    f0101d17 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0101d09:	8b 10                	mov    (%eax),%edx
f0101d0b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101d0e:	89 08                	mov    %ecx,(%eax)
f0101d10:	8b 02                	mov    (%edx),%eax
f0101d12:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0101d17:	5d                   	pop    %ebp
f0101d18:	c3                   	ret    

f0101d19 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0101d19:	55                   	push   %ebp
f0101d1a:	89 e5                	mov    %esp,%ebp
f0101d1c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0101d1f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0101d23:	8b 10                	mov    (%eax),%edx
f0101d25:	3b 50 04             	cmp    0x4(%eax),%edx
f0101d28:	73 0a                	jae    f0101d34 <sprintputch+0x1b>
		*b->buf++ = ch;
f0101d2a:	8d 4a 01             	lea    0x1(%edx),%ecx
f0101d2d:	89 08                	mov    %ecx,(%eax)
f0101d2f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d32:	88 02                	mov    %al,(%edx)
}
f0101d34:	5d                   	pop    %ebp
f0101d35:	c3                   	ret    

f0101d36 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0101d36:	55                   	push   %ebp
f0101d37:	89 e5                	mov    %esp,%ebp
f0101d39:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0101d3c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0101d3f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101d43:	8b 45 10             	mov    0x10(%ebp),%eax
f0101d46:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101d4a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101d4d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101d51:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d54:	89 04 24             	mov    %eax,(%esp)
f0101d57:	e8 02 00 00 00       	call   f0101d5e <vprintfmt>
	va_end(ap);
}
f0101d5c:	c9                   	leave  
f0101d5d:	c3                   	ret    

f0101d5e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0101d5e:	55                   	push   %ebp
f0101d5f:	89 e5                	mov    %esp,%ebp
f0101d61:	57                   	push   %edi
f0101d62:	56                   	push   %esi
f0101d63:	53                   	push   %ebx
f0101d64:	83 ec 3c             	sub    $0x3c,%esp
f0101d67:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101d6a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0101d6d:	eb 14                	jmp    f0101d83 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0101d6f:	85 c0                	test   %eax,%eax
f0101d71:	0f 84 b3 03 00 00    	je     f010212a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0101d77:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101d7b:	89 04 24             	mov    %eax,(%esp)
f0101d7e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101d81:	89 f3                	mov    %esi,%ebx
f0101d83:	8d 73 01             	lea    0x1(%ebx),%esi
f0101d86:	0f b6 03             	movzbl (%ebx),%eax
f0101d89:	83 f8 25             	cmp    $0x25,%eax
f0101d8c:	75 e1                	jne    f0101d6f <vprintfmt+0x11>
f0101d8e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0101d92:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0101d99:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0101da0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0101da7:	ba 00 00 00 00       	mov    $0x0,%edx
f0101dac:	eb 1d                	jmp    f0101dcb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101dae:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0101db0:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0101db4:	eb 15                	jmp    f0101dcb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101db6:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0101db8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0101dbc:	eb 0d                	jmp    f0101dcb <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0101dbe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101dc1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101dc4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101dcb:	8d 5e 01             	lea    0x1(%esi),%ebx
f0101dce:	0f b6 0e             	movzbl (%esi),%ecx
f0101dd1:	0f b6 c1             	movzbl %cl,%eax
f0101dd4:	83 e9 23             	sub    $0x23,%ecx
f0101dd7:	80 f9 55             	cmp    $0x55,%cl
f0101dda:	0f 87 2a 03 00 00    	ja     f010210a <vprintfmt+0x3ac>
f0101de0:	0f b6 c9             	movzbl %cl,%ecx
f0101de3:	ff 24 8d 40 33 10 f0 	jmp    *-0xfefccc0(,%ecx,4)
f0101dea:	89 de                	mov    %ebx,%esi
f0101dec:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0101df1:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0101df4:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0101df8:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0101dfb:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0101dfe:	83 fb 09             	cmp    $0x9,%ebx
f0101e01:	77 36                	ja     f0101e39 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0101e03:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0101e06:	eb e9                	jmp    f0101df1 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0101e08:	8b 45 14             	mov    0x14(%ebp),%eax
f0101e0b:	8d 48 04             	lea    0x4(%eax),%ecx
f0101e0e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0101e11:	8b 00                	mov    (%eax),%eax
f0101e13:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101e16:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0101e18:	eb 22                	jmp    f0101e3c <vprintfmt+0xde>
f0101e1a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101e1d:	85 c9                	test   %ecx,%ecx
f0101e1f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101e24:	0f 49 c1             	cmovns %ecx,%eax
f0101e27:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101e2a:	89 de                	mov    %ebx,%esi
f0101e2c:	eb 9d                	jmp    f0101dcb <vprintfmt+0x6d>
f0101e2e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0101e30:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0101e37:	eb 92                	jmp    f0101dcb <vprintfmt+0x6d>
f0101e39:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f0101e3c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101e40:	79 89                	jns    f0101dcb <vprintfmt+0x6d>
f0101e42:	e9 77 ff ff ff       	jmp    f0101dbe <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0101e47:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101e4a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0101e4c:	e9 7a ff ff ff       	jmp    f0101dcb <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0101e51:	8b 45 14             	mov    0x14(%ebp),%eax
f0101e54:	8d 50 04             	lea    0x4(%eax),%edx
f0101e57:	89 55 14             	mov    %edx,0x14(%ebp)
f0101e5a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101e5e:	8b 00                	mov    (%eax),%eax
f0101e60:	89 04 24             	mov    %eax,(%esp)
f0101e63:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101e66:	e9 18 ff ff ff       	jmp    f0101d83 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101e6b:	8b 45 14             	mov    0x14(%ebp),%eax
f0101e6e:	8d 50 04             	lea    0x4(%eax),%edx
f0101e71:	89 55 14             	mov    %edx,0x14(%ebp)
f0101e74:	8b 00                	mov    (%eax),%eax
f0101e76:	99                   	cltd   
f0101e77:	31 d0                	xor    %edx,%eax
f0101e79:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101e7b:	83 f8 07             	cmp    $0x7,%eax
f0101e7e:	7f 0b                	jg     f0101e8b <vprintfmt+0x12d>
f0101e80:	8b 14 85 a0 34 10 f0 	mov    -0xfefcb60(,%eax,4),%edx
f0101e87:	85 d2                	test   %edx,%edx
f0101e89:	75 20                	jne    f0101eab <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f0101e8b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101e8f:	c7 44 24 08 c2 32 10 	movl   $0xf01032c2,0x8(%esp)
f0101e96:	f0 
f0101e97:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101e9b:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e9e:	89 04 24             	mov    %eax,(%esp)
f0101ea1:	e8 90 fe ff ff       	call   f0101d36 <printfmt>
f0101ea6:	e9 d8 fe ff ff       	jmp    f0101d83 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0101eab:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101eaf:	c7 44 24 08 d8 30 10 	movl   $0xf01030d8,0x8(%esp)
f0101eb6:	f0 
f0101eb7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101ebb:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ebe:	89 04 24             	mov    %eax,(%esp)
f0101ec1:	e8 70 fe ff ff       	call   f0101d36 <printfmt>
f0101ec6:	e9 b8 fe ff ff       	jmp    f0101d83 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101ecb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101ece:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101ed1:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101ed4:	8b 45 14             	mov    0x14(%ebp),%eax
f0101ed7:	8d 50 04             	lea    0x4(%eax),%edx
f0101eda:	89 55 14             	mov    %edx,0x14(%ebp)
f0101edd:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0101edf:	85 f6                	test   %esi,%esi
f0101ee1:	b8 bb 32 10 f0       	mov    $0xf01032bb,%eax
f0101ee6:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0101ee9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0101eed:	0f 84 97 00 00 00    	je     f0101f8a <vprintfmt+0x22c>
f0101ef3:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0101ef7:	0f 8e 9b 00 00 00    	jle    f0101f98 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101efd:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101f01:	89 34 24             	mov    %esi,(%esp)
f0101f04:	e8 9f 03 00 00       	call   f01022a8 <strnlen>
f0101f09:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101f0c:	29 c2                	sub    %eax,%edx
f0101f0e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0101f11:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0101f15:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101f18:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0101f1b:	8b 75 08             	mov    0x8(%ebp),%esi
f0101f1e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101f21:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101f23:	eb 0f                	jmp    f0101f34 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0101f25:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101f29:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101f2c:	89 04 24             	mov    %eax,(%esp)
f0101f2f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101f31:	83 eb 01             	sub    $0x1,%ebx
f0101f34:	85 db                	test   %ebx,%ebx
f0101f36:	7f ed                	jg     f0101f25 <vprintfmt+0x1c7>
f0101f38:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0101f3b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101f3e:	85 d2                	test   %edx,%edx
f0101f40:	b8 00 00 00 00       	mov    $0x0,%eax
f0101f45:	0f 49 c2             	cmovns %edx,%eax
f0101f48:	29 c2                	sub    %eax,%edx
f0101f4a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0101f4d:	89 d7                	mov    %edx,%edi
f0101f4f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101f52:	eb 50                	jmp    f0101fa4 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101f54:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101f58:	74 1e                	je     f0101f78 <vprintfmt+0x21a>
f0101f5a:	0f be d2             	movsbl %dl,%edx
f0101f5d:	83 ea 20             	sub    $0x20,%edx
f0101f60:	83 fa 5e             	cmp    $0x5e,%edx
f0101f63:	76 13                	jbe    f0101f78 <vprintfmt+0x21a>
					putch('?', putdat);
f0101f65:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101f68:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101f6c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101f73:	ff 55 08             	call   *0x8(%ebp)
f0101f76:	eb 0d                	jmp    f0101f85 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0101f78:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101f7b:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101f7f:	89 04 24             	mov    %eax,(%esp)
f0101f82:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101f85:	83 ef 01             	sub    $0x1,%edi
f0101f88:	eb 1a                	jmp    f0101fa4 <vprintfmt+0x246>
f0101f8a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0101f8d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0101f90:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101f93:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101f96:	eb 0c                	jmp    f0101fa4 <vprintfmt+0x246>
f0101f98:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0101f9b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0101f9e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101fa1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101fa4:	83 c6 01             	add    $0x1,%esi
f0101fa7:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f0101fab:	0f be c2             	movsbl %dl,%eax
f0101fae:	85 c0                	test   %eax,%eax
f0101fb0:	74 27                	je     f0101fd9 <vprintfmt+0x27b>
f0101fb2:	85 db                	test   %ebx,%ebx
f0101fb4:	78 9e                	js     f0101f54 <vprintfmt+0x1f6>
f0101fb6:	83 eb 01             	sub    $0x1,%ebx
f0101fb9:	79 99                	jns    f0101f54 <vprintfmt+0x1f6>
f0101fbb:	89 f8                	mov    %edi,%eax
f0101fbd:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101fc0:	8b 75 08             	mov    0x8(%ebp),%esi
f0101fc3:	89 c3                	mov    %eax,%ebx
f0101fc5:	eb 1a                	jmp    f0101fe1 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101fc7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101fcb:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101fd2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101fd4:	83 eb 01             	sub    $0x1,%ebx
f0101fd7:	eb 08                	jmp    f0101fe1 <vprintfmt+0x283>
f0101fd9:	89 fb                	mov    %edi,%ebx
f0101fdb:	8b 75 08             	mov    0x8(%ebp),%esi
f0101fde:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101fe1:	85 db                	test   %ebx,%ebx
f0101fe3:	7f e2                	jg     f0101fc7 <vprintfmt+0x269>
f0101fe5:	89 75 08             	mov    %esi,0x8(%ebp)
f0101fe8:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0101feb:	e9 93 fd ff ff       	jmp    f0101d83 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101ff0:	83 fa 01             	cmp    $0x1,%edx
f0101ff3:	7e 16                	jle    f010200b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0101ff5:	8b 45 14             	mov    0x14(%ebp),%eax
f0101ff8:	8d 50 08             	lea    0x8(%eax),%edx
f0101ffb:	89 55 14             	mov    %edx,0x14(%ebp)
f0101ffe:	8b 50 04             	mov    0x4(%eax),%edx
f0102001:	8b 00                	mov    (%eax),%eax
f0102003:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102006:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102009:	eb 32                	jmp    f010203d <vprintfmt+0x2df>
	else if (lflag)
f010200b:	85 d2                	test   %edx,%edx
f010200d:	74 18                	je     f0102027 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010200f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102012:	8d 50 04             	lea    0x4(%eax),%edx
f0102015:	89 55 14             	mov    %edx,0x14(%ebp)
f0102018:	8b 30                	mov    (%eax),%esi
f010201a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010201d:	89 f0                	mov    %esi,%eax
f010201f:	c1 f8 1f             	sar    $0x1f,%eax
f0102022:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102025:	eb 16                	jmp    f010203d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0102027:	8b 45 14             	mov    0x14(%ebp),%eax
f010202a:	8d 50 04             	lea    0x4(%eax),%edx
f010202d:	89 55 14             	mov    %edx,0x14(%ebp)
f0102030:	8b 30                	mov    (%eax),%esi
f0102032:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0102035:	89 f0                	mov    %esi,%eax
f0102037:	c1 f8 1f             	sar    $0x1f,%eax
f010203a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010203d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102040:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102043:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102048:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010204c:	0f 89 80 00 00 00    	jns    f01020d2 <vprintfmt+0x374>
				putch('-', putdat);
f0102052:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102056:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010205d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0102060:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102063:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102066:	f7 d8                	neg    %eax
f0102068:	83 d2 00             	adc    $0x0,%edx
f010206b:	f7 da                	neg    %edx
			}
			base = 10;
f010206d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102072:	eb 5e                	jmp    f01020d2 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102074:	8d 45 14             	lea    0x14(%ebp),%eax
f0102077:	e8 63 fc ff ff       	call   f0101cdf <getuint>
			base = 10;
f010207c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102081:	eb 4f                	jmp    f01020d2 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0102083:	8d 45 14             	lea    0x14(%ebp),%eax
f0102086:	e8 54 fc ff ff       	call   f0101cdf <getuint>
			base = 8;
f010208b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0102090:	eb 40                	jmp    f01020d2 <vprintfmt+0x374>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f0102092:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102096:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010209d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01020a0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01020a4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01020ab:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01020ae:	8b 45 14             	mov    0x14(%ebp),%eax
f01020b1:	8d 50 04             	lea    0x4(%eax),%edx
f01020b4:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01020b7:	8b 00                	mov    (%eax),%eax
f01020b9:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01020be:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01020c3:	eb 0d                	jmp    f01020d2 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01020c5:	8d 45 14             	lea    0x14(%ebp),%eax
f01020c8:	e8 12 fc ff ff       	call   f0101cdf <getuint>
			base = 16;
f01020cd:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01020d2:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f01020d6:	89 74 24 10          	mov    %esi,0x10(%esp)
f01020da:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01020dd:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01020e1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01020e5:	89 04 24             	mov    %eax,(%esp)
f01020e8:	89 54 24 04          	mov    %edx,0x4(%esp)
f01020ec:	89 fa                	mov    %edi,%edx
f01020ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01020f1:	e8 fa fa ff ff       	call   f0101bf0 <printnum>
			break;
f01020f6:	e9 88 fc ff ff       	jmp    f0101d83 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01020fb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01020ff:	89 04 24             	mov    %eax,(%esp)
f0102102:	ff 55 08             	call   *0x8(%ebp)
			break;
f0102105:	e9 79 fc ff ff       	jmp    f0101d83 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010210a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010210e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0102115:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102118:	89 f3                	mov    %esi,%ebx
f010211a:	eb 03                	jmp    f010211f <vprintfmt+0x3c1>
f010211c:	83 eb 01             	sub    $0x1,%ebx
f010211f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0102123:	75 f7                	jne    f010211c <vprintfmt+0x3be>
f0102125:	e9 59 fc ff ff       	jmp    f0101d83 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010212a:	83 c4 3c             	add    $0x3c,%esp
f010212d:	5b                   	pop    %ebx
f010212e:	5e                   	pop    %esi
f010212f:	5f                   	pop    %edi
f0102130:	5d                   	pop    %ebp
f0102131:	c3                   	ret    

f0102132 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102132:	55                   	push   %ebp
f0102133:	89 e5                	mov    %esp,%ebp
f0102135:	83 ec 28             	sub    $0x28,%esp
f0102138:	8b 45 08             	mov    0x8(%ebp),%eax
f010213b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010213e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102141:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102145:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102148:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010214f:	85 c0                	test   %eax,%eax
f0102151:	74 30                	je     f0102183 <vsnprintf+0x51>
f0102153:	85 d2                	test   %edx,%edx
f0102155:	7e 2c                	jle    f0102183 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102157:	8b 45 14             	mov    0x14(%ebp),%eax
f010215a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010215e:	8b 45 10             	mov    0x10(%ebp),%eax
f0102161:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102165:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102168:	89 44 24 04          	mov    %eax,0x4(%esp)
f010216c:	c7 04 24 19 1d 10 f0 	movl   $0xf0101d19,(%esp)
f0102173:	e8 e6 fb ff ff       	call   f0101d5e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102178:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010217b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010217e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102181:	eb 05                	jmp    f0102188 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102183:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102188:	c9                   	leave  
f0102189:	c3                   	ret    

f010218a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010218a:	55                   	push   %ebp
f010218b:	89 e5                	mov    %esp,%ebp
f010218d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102190:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102193:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102197:	8b 45 10             	mov    0x10(%ebp),%eax
f010219a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010219e:	8b 45 0c             	mov    0xc(%ebp),%eax
f01021a1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01021a5:	8b 45 08             	mov    0x8(%ebp),%eax
f01021a8:	89 04 24             	mov    %eax,(%esp)
f01021ab:	e8 82 ff ff ff       	call   f0102132 <vsnprintf>
	va_end(ap);

	return rc;
}
f01021b0:	c9                   	leave  
f01021b1:	c3                   	ret    
f01021b2:	66 90                	xchg   %ax,%ax
f01021b4:	66 90                	xchg   %ax,%ax
f01021b6:	66 90                	xchg   %ax,%ax
f01021b8:	66 90                	xchg   %ax,%ax
f01021ba:	66 90                	xchg   %ax,%ax
f01021bc:	66 90                	xchg   %ax,%ax
f01021be:	66 90                	xchg   %ax,%ax

f01021c0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01021c0:	55                   	push   %ebp
f01021c1:	89 e5                	mov    %esp,%ebp
f01021c3:	57                   	push   %edi
f01021c4:	56                   	push   %esi
f01021c5:	53                   	push   %ebx
f01021c6:	83 ec 1c             	sub    $0x1c,%esp
f01021c9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01021cc:	85 c0                	test   %eax,%eax
f01021ce:	74 10                	je     f01021e0 <readline+0x20>
		cprintf("%s", prompt);
f01021d0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01021d4:	c7 04 24 d8 30 10 f0 	movl   $0xf01030d8,(%esp)
f01021db:	e8 cf f6 ff ff       	call   f01018af <cprintf>

	i = 0;
	echoing = iscons(0);
f01021e0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01021e7:	e8 b6 e4 ff ff       	call   f01006a2 <iscons>
f01021ec:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01021ee:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01021f3:	e8 99 e4 ff ff       	call   f0100691 <getchar>
f01021f8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01021fa:	85 c0                	test   %eax,%eax
f01021fc:	79 17                	jns    f0102215 <readline+0x55>
			cprintf("read error: %e\n", c);
f01021fe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102202:	c7 04 24 c0 34 10 f0 	movl   $0xf01034c0,(%esp)
f0102209:	e8 a1 f6 ff ff       	call   f01018af <cprintf>
			return NULL;
f010220e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102213:	eb 6d                	jmp    f0102282 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102215:	83 f8 7f             	cmp    $0x7f,%eax
f0102218:	74 05                	je     f010221f <readline+0x5f>
f010221a:	83 f8 08             	cmp    $0x8,%eax
f010221d:	75 19                	jne    f0102238 <readline+0x78>
f010221f:	85 f6                	test   %esi,%esi
f0102221:	7e 15                	jle    f0102238 <readline+0x78>
			if (echoing)
f0102223:	85 ff                	test   %edi,%edi
f0102225:	74 0c                	je     f0102233 <readline+0x73>
				cputchar('\b');
f0102227:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010222e:	e8 4e e4 ff ff       	call   f0100681 <cputchar>
			i--;
f0102233:	83 ee 01             	sub    $0x1,%esi
f0102236:	eb bb                	jmp    f01021f3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102238:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010223e:	7f 1c                	jg     f010225c <readline+0x9c>
f0102240:	83 fb 1f             	cmp    $0x1f,%ebx
f0102243:	7e 17                	jle    f010225c <readline+0x9c>
			if (echoing)
f0102245:	85 ff                	test   %edi,%edi
f0102247:	74 08                	je     f0102251 <readline+0x91>
				cputchar(c);
f0102249:	89 1c 24             	mov    %ebx,(%esp)
f010224c:	e8 30 e4 ff ff       	call   f0100681 <cputchar>
			buf[i++] = c;
f0102251:	88 9e 60 55 11 f0    	mov    %bl,-0xfeeaaa0(%esi)
f0102257:	8d 76 01             	lea    0x1(%esi),%esi
f010225a:	eb 97                	jmp    f01021f3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010225c:	83 fb 0d             	cmp    $0xd,%ebx
f010225f:	74 05                	je     f0102266 <readline+0xa6>
f0102261:	83 fb 0a             	cmp    $0xa,%ebx
f0102264:	75 8d                	jne    f01021f3 <readline+0x33>
			if (echoing)
f0102266:	85 ff                	test   %edi,%edi
f0102268:	74 0c                	je     f0102276 <readline+0xb6>
				cputchar('\n');
f010226a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0102271:	e8 0b e4 ff ff       	call   f0100681 <cputchar>
			buf[i] = 0;
f0102276:	c6 86 60 55 11 f0 00 	movb   $0x0,-0xfeeaaa0(%esi)
			return buf;
f010227d:	b8 60 55 11 f0       	mov    $0xf0115560,%eax
		}
	}
}
f0102282:	83 c4 1c             	add    $0x1c,%esp
f0102285:	5b                   	pop    %ebx
f0102286:	5e                   	pop    %esi
f0102287:	5f                   	pop    %edi
f0102288:	5d                   	pop    %ebp
f0102289:	c3                   	ret    
f010228a:	66 90                	xchg   %ax,%ax
f010228c:	66 90                	xchg   %ax,%ax
f010228e:	66 90                	xchg   %ax,%ax

f0102290 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0102290:	55                   	push   %ebp
f0102291:	89 e5                	mov    %esp,%ebp
f0102293:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0102296:	b8 00 00 00 00       	mov    $0x0,%eax
f010229b:	eb 03                	jmp    f01022a0 <strlen+0x10>
		n++;
f010229d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01022a0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01022a4:	75 f7                	jne    f010229d <strlen+0xd>
		n++;
	return n;
}
f01022a6:	5d                   	pop    %ebp
f01022a7:	c3                   	ret    

f01022a8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01022a8:	55                   	push   %ebp
f01022a9:	89 e5                	mov    %esp,%ebp
f01022ab:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01022ae:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01022b1:	b8 00 00 00 00       	mov    $0x0,%eax
f01022b6:	eb 03                	jmp    f01022bb <strnlen+0x13>
		n++;
f01022b8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01022bb:	39 d0                	cmp    %edx,%eax
f01022bd:	74 06                	je     f01022c5 <strnlen+0x1d>
f01022bf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01022c3:	75 f3                	jne    f01022b8 <strnlen+0x10>
		n++;
	return n;
}
f01022c5:	5d                   	pop    %ebp
f01022c6:	c3                   	ret    

f01022c7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01022c7:	55                   	push   %ebp
f01022c8:	89 e5                	mov    %esp,%ebp
f01022ca:	53                   	push   %ebx
f01022cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01022ce:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01022d1:	89 c2                	mov    %eax,%edx
f01022d3:	83 c2 01             	add    $0x1,%edx
f01022d6:	83 c1 01             	add    $0x1,%ecx
f01022d9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01022dd:	88 5a ff             	mov    %bl,-0x1(%edx)
f01022e0:	84 db                	test   %bl,%bl
f01022e2:	75 ef                	jne    f01022d3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01022e4:	5b                   	pop    %ebx
f01022e5:	5d                   	pop    %ebp
f01022e6:	c3                   	ret    

f01022e7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01022e7:	55                   	push   %ebp
f01022e8:	89 e5                	mov    %esp,%ebp
f01022ea:	53                   	push   %ebx
f01022eb:	83 ec 08             	sub    $0x8,%esp
f01022ee:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01022f1:	89 1c 24             	mov    %ebx,(%esp)
f01022f4:	e8 97 ff ff ff       	call   f0102290 <strlen>
	strcpy(dst + len, src);
f01022f9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01022fc:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102300:	01 d8                	add    %ebx,%eax
f0102302:	89 04 24             	mov    %eax,(%esp)
f0102305:	e8 bd ff ff ff       	call   f01022c7 <strcpy>
	return dst;
}
f010230a:	89 d8                	mov    %ebx,%eax
f010230c:	83 c4 08             	add    $0x8,%esp
f010230f:	5b                   	pop    %ebx
f0102310:	5d                   	pop    %ebp
f0102311:	c3                   	ret    

f0102312 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0102312:	55                   	push   %ebp
f0102313:	89 e5                	mov    %esp,%ebp
f0102315:	56                   	push   %esi
f0102316:	53                   	push   %ebx
f0102317:	8b 75 08             	mov    0x8(%ebp),%esi
f010231a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010231d:	89 f3                	mov    %esi,%ebx
f010231f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0102322:	89 f2                	mov    %esi,%edx
f0102324:	eb 0f                	jmp    f0102335 <strncpy+0x23>
		*dst++ = *src;
f0102326:	83 c2 01             	add    $0x1,%edx
f0102329:	0f b6 01             	movzbl (%ecx),%eax
f010232c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010232f:	80 39 01             	cmpb   $0x1,(%ecx)
f0102332:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0102335:	39 da                	cmp    %ebx,%edx
f0102337:	75 ed                	jne    f0102326 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0102339:	89 f0                	mov    %esi,%eax
f010233b:	5b                   	pop    %ebx
f010233c:	5e                   	pop    %esi
f010233d:	5d                   	pop    %ebp
f010233e:	c3                   	ret    

f010233f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010233f:	55                   	push   %ebp
f0102340:	89 e5                	mov    %esp,%ebp
f0102342:	56                   	push   %esi
f0102343:	53                   	push   %ebx
f0102344:	8b 75 08             	mov    0x8(%ebp),%esi
f0102347:	8b 55 0c             	mov    0xc(%ebp),%edx
f010234a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010234d:	89 f0                	mov    %esi,%eax
f010234f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0102353:	85 c9                	test   %ecx,%ecx
f0102355:	75 0b                	jne    f0102362 <strlcpy+0x23>
f0102357:	eb 1d                	jmp    f0102376 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0102359:	83 c0 01             	add    $0x1,%eax
f010235c:	83 c2 01             	add    $0x1,%edx
f010235f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0102362:	39 d8                	cmp    %ebx,%eax
f0102364:	74 0b                	je     f0102371 <strlcpy+0x32>
f0102366:	0f b6 0a             	movzbl (%edx),%ecx
f0102369:	84 c9                	test   %cl,%cl
f010236b:	75 ec                	jne    f0102359 <strlcpy+0x1a>
f010236d:	89 c2                	mov    %eax,%edx
f010236f:	eb 02                	jmp    f0102373 <strlcpy+0x34>
f0102371:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0102373:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0102376:	29 f0                	sub    %esi,%eax
}
f0102378:	5b                   	pop    %ebx
f0102379:	5e                   	pop    %esi
f010237a:	5d                   	pop    %ebp
f010237b:	c3                   	ret    

f010237c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010237c:	55                   	push   %ebp
f010237d:	89 e5                	mov    %esp,%ebp
f010237f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102382:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0102385:	eb 06                	jmp    f010238d <strcmp+0x11>
		p++, q++;
f0102387:	83 c1 01             	add    $0x1,%ecx
f010238a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010238d:	0f b6 01             	movzbl (%ecx),%eax
f0102390:	84 c0                	test   %al,%al
f0102392:	74 04                	je     f0102398 <strcmp+0x1c>
f0102394:	3a 02                	cmp    (%edx),%al
f0102396:	74 ef                	je     f0102387 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0102398:	0f b6 c0             	movzbl %al,%eax
f010239b:	0f b6 12             	movzbl (%edx),%edx
f010239e:	29 d0                	sub    %edx,%eax
}
f01023a0:	5d                   	pop    %ebp
f01023a1:	c3                   	ret    

f01023a2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01023a2:	55                   	push   %ebp
f01023a3:	89 e5                	mov    %esp,%ebp
f01023a5:	53                   	push   %ebx
f01023a6:	8b 45 08             	mov    0x8(%ebp),%eax
f01023a9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01023ac:	89 c3                	mov    %eax,%ebx
f01023ae:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01023b1:	eb 06                	jmp    f01023b9 <strncmp+0x17>
		n--, p++, q++;
f01023b3:	83 c0 01             	add    $0x1,%eax
f01023b6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01023b9:	39 d8                	cmp    %ebx,%eax
f01023bb:	74 15                	je     f01023d2 <strncmp+0x30>
f01023bd:	0f b6 08             	movzbl (%eax),%ecx
f01023c0:	84 c9                	test   %cl,%cl
f01023c2:	74 04                	je     f01023c8 <strncmp+0x26>
f01023c4:	3a 0a                	cmp    (%edx),%cl
f01023c6:	74 eb                	je     f01023b3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01023c8:	0f b6 00             	movzbl (%eax),%eax
f01023cb:	0f b6 12             	movzbl (%edx),%edx
f01023ce:	29 d0                	sub    %edx,%eax
f01023d0:	eb 05                	jmp    f01023d7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01023d2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01023d7:	5b                   	pop    %ebx
f01023d8:	5d                   	pop    %ebp
f01023d9:	c3                   	ret    

f01023da <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01023da:	55                   	push   %ebp
f01023db:	89 e5                	mov    %esp,%ebp
f01023dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01023e0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01023e4:	eb 07                	jmp    f01023ed <strchr+0x13>
		if (*s == c)
f01023e6:	38 ca                	cmp    %cl,%dl
f01023e8:	74 0f                	je     f01023f9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01023ea:	83 c0 01             	add    $0x1,%eax
f01023ed:	0f b6 10             	movzbl (%eax),%edx
f01023f0:	84 d2                	test   %dl,%dl
f01023f2:	75 f2                	jne    f01023e6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01023f4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01023f9:	5d                   	pop    %ebp
f01023fa:	c3                   	ret    

f01023fb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01023fb:	55                   	push   %ebp
f01023fc:	89 e5                	mov    %esp,%ebp
f01023fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0102401:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0102405:	eb 07                	jmp    f010240e <strfind+0x13>
		if (*s == c)
f0102407:	38 ca                	cmp    %cl,%dl
f0102409:	74 0a                	je     f0102415 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010240b:	83 c0 01             	add    $0x1,%eax
f010240e:	0f b6 10             	movzbl (%eax),%edx
f0102411:	84 d2                	test   %dl,%dl
f0102413:	75 f2                	jne    f0102407 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0102415:	5d                   	pop    %ebp
f0102416:	c3                   	ret    

f0102417 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0102417:	55                   	push   %ebp
f0102418:	89 e5                	mov    %esp,%ebp
f010241a:	57                   	push   %edi
f010241b:	56                   	push   %esi
f010241c:	53                   	push   %ebx
f010241d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102420:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0102423:	85 c9                	test   %ecx,%ecx
f0102425:	74 36                	je     f010245d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0102427:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010242d:	75 28                	jne    f0102457 <memset+0x40>
f010242f:	f6 c1 03             	test   $0x3,%cl
f0102432:	75 23                	jne    f0102457 <memset+0x40>
		c &= 0xFF;
f0102434:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0102438:	89 d3                	mov    %edx,%ebx
f010243a:	c1 e3 08             	shl    $0x8,%ebx
f010243d:	89 d6                	mov    %edx,%esi
f010243f:	c1 e6 18             	shl    $0x18,%esi
f0102442:	89 d0                	mov    %edx,%eax
f0102444:	c1 e0 10             	shl    $0x10,%eax
f0102447:	09 f0                	or     %esi,%eax
f0102449:	09 c2                	or     %eax,%edx
f010244b:	89 d0                	mov    %edx,%eax
f010244d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010244f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0102452:	fc                   	cld    
f0102453:	f3 ab                	rep stos %eax,%es:(%edi)
f0102455:	eb 06                	jmp    f010245d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0102457:	8b 45 0c             	mov    0xc(%ebp),%eax
f010245a:	fc                   	cld    
f010245b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010245d:	89 f8                	mov    %edi,%eax
f010245f:	5b                   	pop    %ebx
f0102460:	5e                   	pop    %esi
f0102461:	5f                   	pop    %edi
f0102462:	5d                   	pop    %ebp
f0102463:	c3                   	ret    

f0102464 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0102464:	55                   	push   %ebp
f0102465:	89 e5                	mov    %esp,%ebp
f0102467:	57                   	push   %edi
f0102468:	56                   	push   %esi
f0102469:	8b 45 08             	mov    0x8(%ebp),%eax
f010246c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010246f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0102472:	39 c6                	cmp    %eax,%esi
f0102474:	73 35                	jae    f01024ab <memmove+0x47>
f0102476:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0102479:	39 d0                	cmp    %edx,%eax
f010247b:	73 2e                	jae    f01024ab <memmove+0x47>
		s += n;
		d += n;
f010247d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0102480:	89 d6                	mov    %edx,%esi
f0102482:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102484:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010248a:	75 13                	jne    f010249f <memmove+0x3b>
f010248c:	f6 c1 03             	test   $0x3,%cl
f010248f:	75 0e                	jne    f010249f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0102491:	83 ef 04             	sub    $0x4,%edi
f0102494:	8d 72 fc             	lea    -0x4(%edx),%esi
f0102497:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010249a:	fd                   	std    
f010249b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010249d:	eb 09                	jmp    f01024a8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010249f:	83 ef 01             	sub    $0x1,%edi
f01024a2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01024a5:	fd                   	std    
f01024a6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01024a8:	fc                   	cld    
f01024a9:	eb 1d                	jmp    f01024c8 <memmove+0x64>
f01024ab:	89 f2                	mov    %esi,%edx
f01024ad:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01024af:	f6 c2 03             	test   $0x3,%dl
f01024b2:	75 0f                	jne    f01024c3 <memmove+0x5f>
f01024b4:	f6 c1 03             	test   $0x3,%cl
f01024b7:	75 0a                	jne    f01024c3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01024b9:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01024bc:	89 c7                	mov    %eax,%edi
f01024be:	fc                   	cld    
f01024bf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01024c1:	eb 05                	jmp    f01024c8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01024c3:	89 c7                	mov    %eax,%edi
f01024c5:	fc                   	cld    
f01024c6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01024c8:	5e                   	pop    %esi
f01024c9:	5f                   	pop    %edi
f01024ca:	5d                   	pop    %ebp
f01024cb:	c3                   	ret    

f01024cc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01024cc:	55                   	push   %ebp
f01024cd:	89 e5                	mov    %esp,%ebp
f01024cf:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01024d2:	8b 45 10             	mov    0x10(%ebp),%eax
f01024d5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01024d9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01024dc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01024e0:	8b 45 08             	mov    0x8(%ebp),%eax
f01024e3:	89 04 24             	mov    %eax,(%esp)
f01024e6:	e8 79 ff ff ff       	call   f0102464 <memmove>
}
f01024eb:	c9                   	leave  
f01024ec:	c3                   	ret    

f01024ed <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01024ed:	55                   	push   %ebp
f01024ee:	89 e5                	mov    %esp,%ebp
f01024f0:	56                   	push   %esi
f01024f1:	53                   	push   %ebx
f01024f2:	8b 55 08             	mov    0x8(%ebp),%edx
f01024f5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01024f8:	89 d6                	mov    %edx,%esi
f01024fa:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01024fd:	eb 1a                	jmp    f0102519 <memcmp+0x2c>
		if (*s1 != *s2)
f01024ff:	0f b6 02             	movzbl (%edx),%eax
f0102502:	0f b6 19             	movzbl (%ecx),%ebx
f0102505:	38 d8                	cmp    %bl,%al
f0102507:	74 0a                	je     f0102513 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0102509:	0f b6 c0             	movzbl %al,%eax
f010250c:	0f b6 db             	movzbl %bl,%ebx
f010250f:	29 d8                	sub    %ebx,%eax
f0102511:	eb 0f                	jmp    f0102522 <memcmp+0x35>
		s1++, s2++;
f0102513:	83 c2 01             	add    $0x1,%edx
f0102516:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0102519:	39 f2                	cmp    %esi,%edx
f010251b:	75 e2                	jne    f01024ff <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010251d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102522:	5b                   	pop    %ebx
f0102523:	5e                   	pop    %esi
f0102524:	5d                   	pop    %ebp
f0102525:	c3                   	ret    

f0102526 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0102526:	55                   	push   %ebp
f0102527:	89 e5                	mov    %esp,%ebp
f0102529:	8b 45 08             	mov    0x8(%ebp),%eax
f010252c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010252f:	89 c2                	mov    %eax,%edx
f0102531:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0102534:	eb 07                	jmp    f010253d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0102536:	38 08                	cmp    %cl,(%eax)
f0102538:	74 07                	je     f0102541 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010253a:	83 c0 01             	add    $0x1,%eax
f010253d:	39 d0                	cmp    %edx,%eax
f010253f:	72 f5                	jb     f0102536 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0102541:	5d                   	pop    %ebp
f0102542:	c3                   	ret    

f0102543 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0102543:	55                   	push   %ebp
f0102544:	89 e5                	mov    %esp,%ebp
f0102546:	57                   	push   %edi
f0102547:	56                   	push   %esi
f0102548:	53                   	push   %ebx
f0102549:	8b 55 08             	mov    0x8(%ebp),%edx
f010254c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010254f:	eb 03                	jmp    f0102554 <strtol+0x11>
		s++;
f0102551:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0102554:	0f b6 0a             	movzbl (%edx),%ecx
f0102557:	80 f9 09             	cmp    $0x9,%cl
f010255a:	74 f5                	je     f0102551 <strtol+0xe>
f010255c:	80 f9 20             	cmp    $0x20,%cl
f010255f:	74 f0                	je     f0102551 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0102561:	80 f9 2b             	cmp    $0x2b,%cl
f0102564:	75 0a                	jne    f0102570 <strtol+0x2d>
		s++;
f0102566:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0102569:	bf 00 00 00 00       	mov    $0x0,%edi
f010256e:	eb 11                	jmp    f0102581 <strtol+0x3e>
f0102570:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0102575:	80 f9 2d             	cmp    $0x2d,%cl
f0102578:	75 07                	jne    f0102581 <strtol+0x3e>
		s++, neg = 1;
f010257a:	8d 52 01             	lea    0x1(%edx),%edx
f010257d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0102581:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0102586:	75 15                	jne    f010259d <strtol+0x5a>
f0102588:	80 3a 30             	cmpb   $0x30,(%edx)
f010258b:	75 10                	jne    f010259d <strtol+0x5a>
f010258d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0102591:	75 0a                	jne    f010259d <strtol+0x5a>
		s += 2, base = 16;
f0102593:	83 c2 02             	add    $0x2,%edx
f0102596:	b8 10 00 00 00       	mov    $0x10,%eax
f010259b:	eb 10                	jmp    f01025ad <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f010259d:	85 c0                	test   %eax,%eax
f010259f:	75 0c                	jne    f01025ad <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01025a1:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01025a3:	80 3a 30             	cmpb   $0x30,(%edx)
f01025a6:	75 05                	jne    f01025ad <strtol+0x6a>
		s++, base = 8;
f01025a8:	83 c2 01             	add    $0x1,%edx
f01025ab:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f01025ad:	bb 00 00 00 00       	mov    $0x0,%ebx
f01025b2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01025b5:	0f b6 0a             	movzbl (%edx),%ecx
f01025b8:	8d 71 d0             	lea    -0x30(%ecx),%esi
f01025bb:	89 f0                	mov    %esi,%eax
f01025bd:	3c 09                	cmp    $0x9,%al
f01025bf:	77 08                	ja     f01025c9 <strtol+0x86>
			dig = *s - '0';
f01025c1:	0f be c9             	movsbl %cl,%ecx
f01025c4:	83 e9 30             	sub    $0x30,%ecx
f01025c7:	eb 20                	jmp    f01025e9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f01025c9:	8d 71 9f             	lea    -0x61(%ecx),%esi
f01025cc:	89 f0                	mov    %esi,%eax
f01025ce:	3c 19                	cmp    $0x19,%al
f01025d0:	77 08                	ja     f01025da <strtol+0x97>
			dig = *s - 'a' + 10;
f01025d2:	0f be c9             	movsbl %cl,%ecx
f01025d5:	83 e9 57             	sub    $0x57,%ecx
f01025d8:	eb 0f                	jmp    f01025e9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f01025da:	8d 71 bf             	lea    -0x41(%ecx),%esi
f01025dd:	89 f0                	mov    %esi,%eax
f01025df:	3c 19                	cmp    $0x19,%al
f01025e1:	77 16                	ja     f01025f9 <strtol+0xb6>
			dig = *s - 'A' + 10;
f01025e3:	0f be c9             	movsbl %cl,%ecx
f01025e6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01025e9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f01025ec:	7d 0f                	jge    f01025fd <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f01025ee:	83 c2 01             	add    $0x1,%edx
f01025f1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f01025f5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f01025f7:	eb bc                	jmp    f01025b5 <strtol+0x72>
f01025f9:	89 d8                	mov    %ebx,%eax
f01025fb:	eb 02                	jmp    f01025ff <strtol+0xbc>
f01025fd:	89 d8                	mov    %ebx,%eax

	if (endptr)
f01025ff:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0102603:	74 05                	je     f010260a <strtol+0xc7>
		*endptr = (char *) s;
f0102605:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102608:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f010260a:	f7 d8                	neg    %eax
f010260c:	85 ff                	test   %edi,%edi
f010260e:	0f 44 c3             	cmove  %ebx,%eax
}
f0102611:	5b                   	pop    %ebx
f0102612:	5e                   	pop    %esi
f0102613:	5f                   	pop    %edi
f0102614:	5d                   	pop    %ebp
f0102615:	c3                   	ret    
f0102616:	66 90                	xchg   %ax,%ax
f0102618:	66 90                	xchg   %ax,%ax
f010261a:	66 90                	xchg   %ax,%ax
f010261c:	66 90                	xchg   %ax,%ax
f010261e:	66 90                	xchg   %ax,%ax

f0102620 <__udivdi3>:
f0102620:	55                   	push   %ebp
f0102621:	57                   	push   %edi
f0102622:	56                   	push   %esi
f0102623:	83 ec 0c             	sub    $0xc,%esp
f0102626:	8b 44 24 28          	mov    0x28(%esp),%eax
f010262a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010262e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0102632:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0102636:	85 c0                	test   %eax,%eax
f0102638:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010263c:	89 ea                	mov    %ebp,%edx
f010263e:	89 0c 24             	mov    %ecx,(%esp)
f0102641:	75 2d                	jne    f0102670 <__udivdi3+0x50>
f0102643:	39 e9                	cmp    %ebp,%ecx
f0102645:	77 61                	ja     f01026a8 <__udivdi3+0x88>
f0102647:	85 c9                	test   %ecx,%ecx
f0102649:	89 ce                	mov    %ecx,%esi
f010264b:	75 0b                	jne    f0102658 <__udivdi3+0x38>
f010264d:	b8 01 00 00 00       	mov    $0x1,%eax
f0102652:	31 d2                	xor    %edx,%edx
f0102654:	f7 f1                	div    %ecx
f0102656:	89 c6                	mov    %eax,%esi
f0102658:	31 d2                	xor    %edx,%edx
f010265a:	89 e8                	mov    %ebp,%eax
f010265c:	f7 f6                	div    %esi
f010265e:	89 c5                	mov    %eax,%ebp
f0102660:	89 f8                	mov    %edi,%eax
f0102662:	f7 f6                	div    %esi
f0102664:	89 ea                	mov    %ebp,%edx
f0102666:	83 c4 0c             	add    $0xc,%esp
f0102669:	5e                   	pop    %esi
f010266a:	5f                   	pop    %edi
f010266b:	5d                   	pop    %ebp
f010266c:	c3                   	ret    
f010266d:	8d 76 00             	lea    0x0(%esi),%esi
f0102670:	39 e8                	cmp    %ebp,%eax
f0102672:	77 24                	ja     f0102698 <__udivdi3+0x78>
f0102674:	0f bd e8             	bsr    %eax,%ebp
f0102677:	83 f5 1f             	xor    $0x1f,%ebp
f010267a:	75 3c                	jne    f01026b8 <__udivdi3+0x98>
f010267c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0102680:	39 34 24             	cmp    %esi,(%esp)
f0102683:	0f 86 9f 00 00 00    	jbe    f0102728 <__udivdi3+0x108>
f0102689:	39 d0                	cmp    %edx,%eax
f010268b:	0f 82 97 00 00 00    	jb     f0102728 <__udivdi3+0x108>
f0102691:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102698:	31 d2                	xor    %edx,%edx
f010269a:	31 c0                	xor    %eax,%eax
f010269c:	83 c4 0c             	add    $0xc,%esp
f010269f:	5e                   	pop    %esi
f01026a0:	5f                   	pop    %edi
f01026a1:	5d                   	pop    %ebp
f01026a2:	c3                   	ret    
f01026a3:	90                   	nop
f01026a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01026a8:	89 f8                	mov    %edi,%eax
f01026aa:	f7 f1                	div    %ecx
f01026ac:	31 d2                	xor    %edx,%edx
f01026ae:	83 c4 0c             	add    $0xc,%esp
f01026b1:	5e                   	pop    %esi
f01026b2:	5f                   	pop    %edi
f01026b3:	5d                   	pop    %ebp
f01026b4:	c3                   	ret    
f01026b5:	8d 76 00             	lea    0x0(%esi),%esi
f01026b8:	89 e9                	mov    %ebp,%ecx
f01026ba:	8b 3c 24             	mov    (%esp),%edi
f01026bd:	d3 e0                	shl    %cl,%eax
f01026bf:	89 c6                	mov    %eax,%esi
f01026c1:	b8 20 00 00 00       	mov    $0x20,%eax
f01026c6:	29 e8                	sub    %ebp,%eax
f01026c8:	89 c1                	mov    %eax,%ecx
f01026ca:	d3 ef                	shr    %cl,%edi
f01026cc:	89 e9                	mov    %ebp,%ecx
f01026ce:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01026d2:	8b 3c 24             	mov    (%esp),%edi
f01026d5:	09 74 24 08          	or     %esi,0x8(%esp)
f01026d9:	89 d6                	mov    %edx,%esi
f01026db:	d3 e7                	shl    %cl,%edi
f01026dd:	89 c1                	mov    %eax,%ecx
f01026df:	89 3c 24             	mov    %edi,(%esp)
f01026e2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01026e6:	d3 ee                	shr    %cl,%esi
f01026e8:	89 e9                	mov    %ebp,%ecx
f01026ea:	d3 e2                	shl    %cl,%edx
f01026ec:	89 c1                	mov    %eax,%ecx
f01026ee:	d3 ef                	shr    %cl,%edi
f01026f0:	09 d7                	or     %edx,%edi
f01026f2:	89 f2                	mov    %esi,%edx
f01026f4:	89 f8                	mov    %edi,%eax
f01026f6:	f7 74 24 08          	divl   0x8(%esp)
f01026fa:	89 d6                	mov    %edx,%esi
f01026fc:	89 c7                	mov    %eax,%edi
f01026fe:	f7 24 24             	mull   (%esp)
f0102701:	39 d6                	cmp    %edx,%esi
f0102703:	89 14 24             	mov    %edx,(%esp)
f0102706:	72 30                	jb     f0102738 <__udivdi3+0x118>
f0102708:	8b 54 24 04          	mov    0x4(%esp),%edx
f010270c:	89 e9                	mov    %ebp,%ecx
f010270e:	d3 e2                	shl    %cl,%edx
f0102710:	39 c2                	cmp    %eax,%edx
f0102712:	73 05                	jae    f0102719 <__udivdi3+0xf9>
f0102714:	3b 34 24             	cmp    (%esp),%esi
f0102717:	74 1f                	je     f0102738 <__udivdi3+0x118>
f0102719:	89 f8                	mov    %edi,%eax
f010271b:	31 d2                	xor    %edx,%edx
f010271d:	e9 7a ff ff ff       	jmp    f010269c <__udivdi3+0x7c>
f0102722:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102728:	31 d2                	xor    %edx,%edx
f010272a:	b8 01 00 00 00       	mov    $0x1,%eax
f010272f:	e9 68 ff ff ff       	jmp    f010269c <__udivdi3+0x7c>
f0102734:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102738:	8d 47 ff             	lea    -0x1(%edi),%eax
f010273b:	31 d2                	xor    %edx,%edx
f010273d:	83 c4 0c             	add    $0xc,%esp
f0102740:	5e                   	pop    %esi
f0102741:	5f                   	pop    %edi
f0102742:	5d                   	pop    %ebp
f0102743:	c3                   	ret    
f0102744:	66 90                	xchg   %ax,%ax
f0102746:	66 90                	xchg   %ax,%ax
f0102748:	66 90                	xchg   %ax,%ax
f010274a:	66 90                	xchg   %ax,%ax
f010274c:	66 90                	xchg   %ax,%ax
f010274e:	66 90                	xchg   %ax,%ax

f0102750 <__umoddi3>:
f0102750:	55                   	push   %ebp
f0102751:	57                   	push   %edi
f0102752:	56                   	push   %esi
f0102753:	83 ec 14             	sub    $0x14,%esp
f0102756:	8b 44 24 28          	mov    0x28(%esp),%eax
f010275a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010275e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0102762:	89 c7                	mov    %eax,%edi
f0102764:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102768:	8b 44 24 30          	mov    0x30(%esp),%eax
f010276c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0102770:	89 34 24             	mov    %esi,(%esp)
f0102773:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0102777:	85 c0                	test   %eax,%eax
f0102779:	89 c2                	mov    %eax,%edx
f010277b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010277f:	75 17                	jne    f0102798 <__umoddi3+0x48>
f0102781:	39 fe                	cmp    %edi,%esi
f0102783:	76 4b                	jbe    f01027d0 <__umoddi3+0x80>
f0102785:	89 c8                	mov    %ecx,%eax
f0102787:	89 fa                	mov    %edi,%edx
f0102789:	f7 f6                	div    %esi
f010278b:	89 d0                	mov    %edx,%eax
f010278d:	31 d2                	xor    %edx,%edx
f010278f:	83 c4 14             	add    $0x14,%esp
f0102792:	5e                   	pop    %esi
f0102793:	5f                   	pop    %edi
f0102794:	5d                   	pop    %ebp
f0102795:	c3                   	ret    
f0102796:	66 90                	xchg   %ax,%ax
f0102798:	39 f8                	cmp    %edi,%eax
f010279a:	77 54                	ja     f01027f0 <__umoddi3+0xa0>
f010279c:	0f bd e8             	bsr    %eax,%ebp
f010279f:	83 f5 1f             	xor    $0x1f,%ebp
f01027a2:	75 5c                	jne    f0102800 <__umoddi3+0xb0>
f01027a4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f01027a8:	39 3c 24             	cmp    %edi,(%esp)
f01027ab:	0f 87 e7 00 00 00    	ja     f0102898 <__umoddi3+0x148>
f01027b1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01027b5:	29 f1                	sub    %esi,%ecx
f01027b7:	19 c7                	sbb    %eax,%edi
f01027b9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01027bd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01027c1:	8b 44 24 08          	mov    0x8(%esp),%eax
f01027c5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01027c9:	83 c4 14             	add    $0x14,%esp
f01027cc:	5e                   	pop    %esi
f01027cd:	5f                   	pop    %edi
f01027ce:	5d                   	pop    %ebp
f01027cf:	c3                   	ret    
f01027d0:	85 f6                	test   %esi,%esi
f01027d2:	89 f5                	mov    %esi,%ebp
f01027d4:	75 0b                	jne    f01027e1 <__umoddi3+0x91>
f01027d6:	b8 01 00 00 00       	mov    $0x1,%eax
f01027db:	31 d2                	xor    %edx,%edx
f01027dd:	f7 f6                	div    %esi
f01027df:	89 c5                	mov    %eax,%ebp
f01027e1:	8b 44 24 04          	mov    0x4(%esp),%eax
f01027e5:	31 d2                	xor    %edx,%edx
f01027e7:	f7 f5                	div    %ebp
f01027e9:	89 c8                	mov    %ecx,%eax
f01027eb:	f7 f5                	div    %ebp
f01027ed:	eb 9c                	jmp    f010278b <__umoddi3+0x3b>
f01027ef:	90                   	nop
f01027f0:	89 c8                	mov    %ecx,%eax
f01027f2:	89 fa                	mov    %edi,%edx
f01027f4:	83 c4 14             	add    $0x14,%esp
f01027f7:	5e                   	pop    %esi
f01027f8:	5f                   	pop    %edi
f01027f9:	5d                   	pop    %ebp
f01027fa:	c3                   	ret    
f01027fb:	90                   	nop
f01027fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102800:	8b 04 24             	mov    (%esp),%eax
f0102803:	be 20 00 00 00       	mov    $0x20,%esi
f0102808:	89 e9                	mov    %ebp,%ecx
f010280a:	29 ee                	sub    %ebp,%esi
f010280c:	d3 e2                	shl    %cl,%edx
f010280e:	89 f1                	mov    %esi,%ecx
f0102810:	d3 e8                	shr    %cl,%eax
f0102812:	89 e9                	mov    %ebp,%ecx
f0102814:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102818:	8b 04 24             	mov    (%esp),%eax
f010281b:	09 54 24 04          	or     %edx,0x4(%esp)
f010281f:	89 fa                	mov    %edi,%edx
f0102821:	d3 e0                	shl    %cl,%eax
f0102823:	89 f1                	mov    %esi,%ecx
f0102825:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102829:	8b 44 24 10          	mov    0x10(%esp),%eax
f010282d:	d3 ea                	shr    %cl,%edx
f010282f:	89 e9                	mov    %ebp,%ecx
f0102831:	d3 e7                	shl    %cl,%edi
f0102833:	89 f1                	mov    %esi,%ecx
f0102835:	d3 e8                	shr    %cl,%eax
f0102837:	89 e9                	mov    %ebp,%ecx
f0102839:	09 f8                	or     %edi,%eax
f010283b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010283f:	f7 74 24 04          	divl   0x4(%esp)
f0102843:	d3 e7                	shl    %cl,%edi
f0102845:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102849:	89 d7                	mov    %edx,%edi
f010284b:	f7 64 24 08          	mull   0x8(%esp)
f010284f:	39 d7                	cmp    %edx,%edi
f0102851:	89 c1                	mov    %eax,%ecx
f0102853:	89 14 24             	mov    %edx,(%esp)
f0102856:	72 2c                	jb     f0102884 <__umoddi3+0x134>
f0102858:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010285c:	72 22                	jb     f0102880 <__umoddi3+0x130>
f010285e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0102862:	29 c8                	sub    %ecx,%eax
f0102864:	19 d7                	sbb    %edx,%edi
f0102866:	89 e9                	mov    %ebp,%ecx
f0102868:	89 fa                	mov    %edi,%edx
f010286a:	d3 e8                	shr    %cl,%eax
f010286c:	89 f1                	mov    %esi,%ecx
f010286e:	d3 e2                	shl    %cl,%edx
f0102870:	89 e9                	mov    %ebp,%ecx
f0102872:	d3 ef                	shr    %cl,%edi
f0102874:	09 d0                	or     %edx,%eax
f0102876:	89 fa                	mov    %edi,%edx
f0102878:	83 c4 14             	add    $0x14,%esp
f010287b:	5e                   	pop    %esi
f010287c:	5f                   	pop    %edi
f010287d:	5d                   	pop    %ebp
f010287e:	c3                   	ret    
f010287f:	90                   	nop
f0102880:	39 d7                	cmp    %edx,%edi
f0102882:	75 da                	jne    f010285e <__umoddi3+0x10e>
f0102884:	8b 14 24             	mov    (%esp),%edx
f0102887:	89 c1                	mov    %eax,%ecx
f0102889:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f010288d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0102891:	eb cb                	jmp    f010285e <__umoddi3+0x10e>
f0102893:	90                   	nop
f0102894:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102898:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f010289c:	0f 82 0f ff ff ff    	jb     f01027b1 <__umoddi3+0x61>
f01028a2:	e9 1a ff ff ff       	jmp    f01027c1 <__umoddi3+0x71>
