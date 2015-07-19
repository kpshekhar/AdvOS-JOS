
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
f0100015:	b8 00 10 11 00       	mov    $0x111000,%eax
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
f0100034:	bc 00 10 11 f0       	mov    $0xf0111000,%esp

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
f010004e:	c7 04 24 80 1b 10 f0 	movl   $0xf0101b80,(%esp)
f0100055:	e8 2a 0b 00 00       	call   f0100b84 <cprintf>
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
f010008b:	c7 04 24 9c 1b 10 f0 	movl   $0xf0101b9c,(%esp)
f0100092:	e8 ed 0a 00 00       	call   f0100b84 <cprintf>
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
f01000a3:	b8 50 39 11 f0       	mov    $0xf0113950,%eax
f01000a8:	2d 00 33 11 f0       	sub    $0xf0113300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 33 11 f0 	movl   $0xf0113300,(%esp)
f01000c0:	e8 22 16 00 00       	call   f01016e7 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 c5 04 00 00       	call   f010058f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 b7 1b 10 f0 	movl   $0xf0101bb7,(%esp)
f01000d9:	e8 a6 0a 00 00       	call   f0100b84 <cprintf>
	mem_init();
f01000de:	e8 c5 08 00 00       	call   f01009a8 <mem_init>

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
f0100107:	c7 04 24 d2 1b 10 f0 	movl   $0xf0101bd2,(%esp)
f010010e:	e8 71 0a 00 00       	call   f0100b84 <cprintf>
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
f010012c:	83 3d 40 39 11 f0 00 	cmpl   $0x0,0xf0113940
f0100133:	75 3d                	jne    f0100172 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f0100135:	89 35 40 39 11 f0    	mov    %esi,0xf0113940

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
f010014e:	c7 04 24 e4 1b 10 f0 	movl   $0xf0101be4,(%esp)
f0100155:	e8 2a 0a 00 00       	call   f0100b84 <cprintf>
	vcprintf(fmt, ap);
f010015a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010015e:	89 34 24             	mov    %esi,(%esp)
f0100161:	e8 eb 09 00 00       	call   f0100b51 <vcprintf>
	cprintf("\n");
f0100166:	c7 04 24 20 1c 10 f0 	movl   $0xf0101c20,(%esp)
f010016d:	e8 12 0a 00 00       	call   f0100b84 <cprintf>
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
f0100198:	c7 04 24 fc 1b 10 f0 	movl   $0xf0101bfc,(%esp)
f010019f:	e8 e0 09 00 00       	call   f0100b84 <cprintf>
	vcprintf(fmt, ap);
f01001a4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01001a8:	8b 45 10             	mov    0x10(%ebp),%eax
f01001ab:	89 04 24             	mov    %eax,(%esp)
f01001ae:	e8 9e 09 00 00       	call   f0100b51 <vcprintf>
	cprintf("\n");
f01001b3:	c7 04 24 20 1c 10 f0 	movl   $0xf0101c20,(%esp)
f01001ba:	e8 c5 09 00 00       	call   f0100b84 <cprintf>
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
f01001fb:	a1 24 35 11 f0       	mov    0xf0113524,%eax
f0100200:	8d 48 01             	lea    0x1(%eax),%ecx
f0100203:	89 0d 24 35 11 f0    	mov    %ecx,0xf0113524
f0100209:	88 90 20 33 11 f0    	mov    %dl,-0xfeecce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010020f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100215:	75 0a                	jne    f0100221 <cons_intr+0x35>
			cons.wpos = 0;
f0100217:	c7 05 24 35 11 f0 00 	movl   $0x0,0xf0113524
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
f0100247:	83 0d 00 33 11 f0 40 	orl    $0x40,0xf0113300
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
f010025f:	8b 0d 00 33 11 f0    	mov    0xf0113300,%ecx
f0100265:	89 cb                	mov    %ecx,%ebx
f0100267:	83 e3 40             	and    $0x40,%ebx
f010026a:	83 e0 7f             	and    $0x7f,%eax
f010026d:	85 db                	test   %ebx,%ebx
f010026f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100272:	0f b6 d2             	movzbl %dl,%edx
f0100275:	0f b6 82 60 1d 10 f0 	movzbl -0xfefe2a0(%edx),%eax
f010027c:	83 c8 40             	or     $0x40,%eax
f010027f:	0f b6 c0             	movzbl %al,%eax
f0100282:	f7 d0                	not    %eax
f0100284:	21 c1                	and    %eax,%ecx
f0100286:	89 0d 00 33 11 f0    	mov    %ecx,0xf0113300
		return 0;
f010028c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100291:	e9 9d 00 00 00       	jmp    f0100333 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100296:	8b 0d 00 33 11 f0    	mov    0xf0113300,%ecx
f010029c:	f6 c1 40             	test   $0x40,%cl
f010029f:	74 0e                	je     f01002af <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01002a1:	83 c8 80             	or     $0xffffff80,%eax
f01002a4:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01002a6:	83 e1 bf             	and    $0xffffffbf,%ecx
f01002a9:	89 0d 00 33 11 f0    	mov    %ecx,0xf0113300
	}

	shift |= shiftcode[data];
f01002af:	0f b6 d2             	movzbl %dl,%edx
f01002b2:	0f b6 82 60 1d 10 f0 	movzbl -0xfefe2a0(%edx),%eax
f01002b9:	0b 05 00 33 11 f0    	or     0xf0113300,%eax
	shift ^= togglecode[data];
f01002bf:	0f b6 8a 60 1c 10 f0 	movzbl -0xfefe3a0(%edx),%ecx
f01002c6:	31 c8                	xor    %ecx,%eax
f01002c8:	a3 00 33 11 f0       	mov    %eax,0xf0113300

	c = charcode[shift & (CTL | SHIFT)][data];
f01002cd:	89 c1                	mov    %eax,%ecx
f01002cf:	83 e1 03             	and    $0x3,%ecx
f01002d2:	8b 0c 8d 40 1c 10 f0 	mov    -0xfefe3c0(,%ecx,4),%ecx
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
f0100312:	c7 04 24 16 1c 10 f0 	movl   $0xf0101c16,(%esp)
f0100319:	e8 66 08 00 00       	call   f0100b84 <cprintf>
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
f01003ec:	0f b7 05 28 35 11 f0 	movzwl 0xf0113528,%eax
f01003f3:	66 85 c0             	test   %ax,%ax
f01003f6:	0f 84 e5 00 00 00    	je     f01004e1 <cons_putc+0x1a8>
			crt_pos--;
f01003fc:	83 e8 01             	sub    $0x1,%eax
f01003ff:	66 a3 28 35 11 f0    	mov    %ax,0xf0113528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100405:	0f b7 c0             	movzwl %ax,%eax
f0100408:	66 81 e7 00 ff       	and    $0xff00,%di
f010040d:	83 cf 20             	or     $0x20,%edi
f0100410:	8b 15 2c 35 11 f0    	mov    0xf011352c,%edx
f0100416:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010041a:	eb 78                	jmp    f0100494 <cons_putc+0x15b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010041c:	66 83 05 28 35 11 f0 	addw   $0x50,0xf0113528
f0100423:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100424:	0f b7 05 28 35 11 f0 	movzwl 0xf0113528,%eax
f010042b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100431:	c1 e8 16             	shr    $0x16,%eax
f0100434:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100437:	c1 e0 04             	shl    $0x4,%eax
f010043a:	66 a3 28 35 11 f0    	mov    %ax,0xf0113528
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
f0100476:	0f b7 05 28 35 11 f0 	movzwl 0xf0113528,%eax
f010047d:	8d 50 01             	lea    0x1(%eax),%edx
f0100480:	66 89 15 28 35 11 f0 	mov    %dx,0xf0113528
f0100487:	0f b7 c0             	movzwl %ax,%eax
f010048a:	8b 15 2c 35 11 f0    	mov    0xf011352c,%edx
f0100490:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100494:	66 81 3d 28 35 11 f0 	cmpw   $0x7cf,0xf0113528
f010049b:	cf 07 
f010049d:	76 42                	jbe    f01004e1 <cons_putc+0x1a8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010049f:	a1 2c 35 11 f0       	mov    0xf011352c,%eax
f01004a4:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f01004ab:	00 
f01004ac:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004b2:	89 54 24 04          	mov    %edx,0x4(%esp)
f01004b6:	89 04 24             	mov    %eax,(%esp)
f01004b9:	e8 76 12 00 00       	call   f0101734 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01004be:	8b 15 2c 35 11 f0    	mov    0xf011352c,%edx
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
f01004d9:	66 83 2d 28 35 11 f0 	subw   $0x50,0xf0113528
f01004e0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004e1:	8b 0d 30 35 11 f0    	mov    0xf0113530,%ecx
f01004e7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004ec:	89 ca                	mov    %ecx,%edx
f01004ee:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004ef:	0f b7 1d 28 35 11 f0 	movzwl 0xf0113528,%ebx
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
f0100517:	80 3d 34 35 11 f0 00 	cmpb   $0x0,0xf0113534
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
f0100555:	a1 20 35 11 f0       	mov    0xf0113520,%eax
f010055a:	3b 05 24 35 11 f0    	cmp    0xf0113524,%eax
f0100560:	74 26                	je     f0100588 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100562:	8d 50 01             	lea    0x1(%eax),%edx
f0100565:	89 15 20 35 11 f0    	mov    %edx,0xf0113520
f010056b:	0f b6 88 20 33 11 f0 	movzbl -0xfeecce0(%eax),%ecx
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
f010057c:	c7 05 20 35 11 f0 00 	movl   $0x0,0xf0113520
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
f01005b5:	c7 05 30 35 11 f0 b4 	movl   $0x3b4,0xf0113530
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
f01005cd:	c7 05 30 35 11 f0 d4 	movl   $0x3d4,0xf0113530
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
f01005dc:	8b 0d 30 35 11 f0    	mov    0xf0113530,%ecx
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
f0100601:	89 3d 2c 35 11 f0    	mov    %edi,0xf011352c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100607:	0f b6 d8             	movzbl %al,%ebx
f010060a:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f010060c:	66 89 35 28 35 11 f0 	mov    %si,0xf0113528
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
f010065d:	88 0d 34 35 11 f0    	mov    %cl,0xf0113534
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
f010066d:	c7 04 24 22 1c 10 f0 	movl   $0xf0101c22,(%esp)
f0100674:	e8 0b 05 00 00       	call   f0100b84 <cprintf>
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
f01006b6:	c7 44 24 08 60 1e 10 	movl   $0xf0101e60,0x8(%esp)
f01006bd:	f0 
f01006be:	c7 44 24 04 7e 1e 10 	movl   $0xf0101e7e,0x4(%esp)
f01006c5:	f0 
f01006c6:	c7 04 24 83 1e 10 f0 	movl   $0xf0101e83,(%esp)
f01006cd:	e8 b2 04 00 00       	call   f0100b84 <cprintf>
f01006d2:	c7 44 24 08 24 1f 10 	movl   $0xf0101f24,0x8(%esp)
f01006d9:	f0 
f01006da:	c7 44 24 04 8c 1e 10 	movl   $0xf0101e8c,0x4(%esp)
f01006e1:	f0 
f01006e2:	c7 04 24 83 1e 10 f0 	movl   $0xf0101e83,(%esp)
f01006e9:	e8 96 04 00 00       	call   f0100b84 <cprintf>
f01006ee:	c7 44 24 08 95 1e 10 	movl   $0xf0101e95,0x8(%esp)
f01006f5:	f0 
f01006f6:	c7 44 24 04 b2 1e 10 	movl   $0xf0101eb2,0x4(%esp)
f01006fd:	f0 
f01006fe:	c7 04 24 83 1e 10 f0 	movl   $0xf0101e83,(%esp)
f0100705:	e8 7a 04 00 00       	call   f0100b84 <cprintf>
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
f0100717:	c7 04 24 bd 1e 10 f0 	movl   $0xf0101ebd,(%esp)
f010071e:	e8 61 04 00 00       	call   f0100b84 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100723:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010072a:	00 
f010072b:	c7 04 24 4c 1f 10 f0 	movl   $0xf0101f4c,(%esp)
f0100732:	e8 4d 04 00 00       	call   f0100b84 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100737:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010073e:	00 
f010073f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100746:	f0 
f0100747:	c7 04 24 74 1f 10 f0 	movl   $0xf0101f74,(%esp)
f010074e:	e8 31 04 00 00       	call   f0100b84 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100753:	c7 44 24 08 77 1b 10 	movl   $0x101b77,0x8(%esp)
f010075a:	00 
f010075b:	c7 44 24 04 77 1b 10 	movl   $0xf0101b77,0x4(%esp)
f0100762:	f0 
f0100763:	c7 04 24 98 1f 10 f0 	movl   $0xf0101f98,(%esp)
f010076a:	e8 15 04 00 00       	call   f0100b84 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010076f:	c7 44 24 08 00 33 11 	movl   $0x113300,0x8(%esp)
f0100776:	00 
f0100777:	c7 44 24 04 00 33 11 	movl   $0xf0113300,0x4(%esp)
f010077e:	f0 
f010077f:	c7 04 24 bc 1f 10 f0 	movl   $0xf0101fbc,(%esp)
f0100786:	e8 f9 03 00 00       	call   f0100b84 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010078b:	c7 44 24 08 50 39 11 	movl   $0x113950,0x8(%esp)
f0100792:	00 
f0100793:	c7 44 24 04 50 39 11 	movl   $0xf0113950,0x4(%esp)
f010079a:	f0 
f010079b:	c7 04 24 e0 1f 10 f0 	movl   $0xf0101fe0,(%esp)
f01007a2:	e8 dd 03 00 00       	call   f0100b84 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01007a7:	b8 4f 3d 11 f0       	mov    $0xf0113d4f,%eax
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
f01007c8:	c7 04 24 04 20 10 f0 	movl   $0xf0102004,(%esp)
f01007cf:	e8 b0 03 00 00       	call   f0100b84 <cprintf>
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
f01007e6:	c7 04 24 d6 1e 10 f0 	movl   $0xf0101ed6,(%esp)
f01007ed:	e8 92 03 00 00       	call   f0100b84 <cprintf>
	
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
f0100801:	e8 75 04 00 00       	call   f0100c7b <debuginfo_eip>
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
f0100856:	c7 04 24 30 20 10 f0 	movl   $0xf0102030,(%esp)
f010085d:	e8 22 03 00 00       	call   f0100b84 <cprintf>
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
f010087e:	c7 04 24 74 20 10 f0 	movl   $0xf0102074,(%esp)
f0100885:	e8 fa 02 00 00       	call   f0100b84 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010088a:	c7 04 24 98 20 10 f0 	movl   $0xf0102098,(%esp)
f0100891:	e8 ee 02 00 00       	call   f0100b84 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100896:	c7 04 24 e8 1e 10 f0 	movl   $0xf0101ee8,(%esp)
f010089d:	e8 ee 0b 00 00       	call   f0101490 <readline>
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
f01008ce:	c7 04 24 ec 1e 10 f0 	movl   $0xf0101eec,(%esp)
f01008d5:	e8 d0 0d 00 00       	call   f01016aa <strchr>
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
f01008f0:	c7 04 24 f1 1e 10 f0 	movl   $0xf0101ef1,(%esp)
f01008f7:	e8 88 02 00 00       	call   f0100b84 <cprintf>
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
f0100918:	c7 04 24 ec 1e 10 f0 	movl   $0xf0101eec,(%esp)
f010091f:	e8 86 0d 00 00       	call   f01016aa <strchr>
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
f0100942:	8b 04 85 c0 20 10 f0 	mov    -0xfefdf40(,%eax,4),%eax
f0100949:	89 44 24 04          	mov    %eax,0x4(%esp)
f010094d:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100950:	89 04 24             	mov    %eax,(%esp)
f0100953:	e8 f4 0c 00 00       	call   f010164c <strcmp>
f0100958:	85 c0                	test   %eax,%eax
f010095a:	75 24                	jne    f0100980 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f010095c:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010095f:	8b 55 08             	mov    0x8(%ebp),%edx
f0100962:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100966:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100969:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010096d:	89 34 24             	mov    %esi,(%esp)
f0100970:	ff 14 85 c8 20 10 f0 	call   *-0xfefdf38(,%eax,4)


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
f010098f:	c7 04 24 0e 1f 10 f0 	movl   $0xf0101f0e,(%esp)
f0100996:	e8 e9 01 00 00       	call   f0100b84 <cprintf>
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

f01009a8 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01009a8:	55                   	push   %ebp
f01009a9:	89 e5                	mov    %esp,%ebp
f01009ab:	53                   	push   %ebx
f01009ac:	83 ec 14             	sub    $0x14,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01009af:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f01009b6:	e8 59 01 00 00       	call   f0100b14 <mc146818_read>
f01009bb:	89 c3                	mov    %eax,%ebx
f01009bd:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f01009c4:	e8 4b 01 00 00       	call   f0100b14 <mc146818_read>
f01009c9:	c1 e0 08             	shl    $0x8,%eax
f01009cc:	09 c3                	or     %eax,%ebx
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01009ce:	89 d8                	mov    %ebx,%eax
f01009d0:	c1 e0 0a             	shl    $0xa,%eax
f01009d3:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01009d9:	85 c0                	test   %eax,%eax
f01009db:	0f 48 c2             	cmovs  %edx,%eax
f01009de:	c1 f8 0c             	sar    $0xc,%eax
f01009e1:	a3 3c 35 11 f0       	mov    %eax,0xf011353c
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01009e6:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f01009ed:	e8 22 01 00 00       	call   f0100b14 <mc146818_read>
f01009f2:	89 c3                	mov    %eax,%ebx
f01009f4:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01009fb:	e8 14 01 00 00       	call   f0100b14 <mc146818_read>
f0100a00:	c1 e0 08             	shl    $0x8,%eax
f0100a03:	09 c3                	or     %eax,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0100a05:	89 d8                	mov    %ebx,%eax
f0100a07:	c1 e0 0a             	shl    $0xa,%eax
f0100a0a:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100a10:	85 c0                	test   %eax,%eax
f0100a12:	0f 48 c2             	cmovs  %edx,%eax
f0100a15:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0100a18:	85 c0                	test   %eax,%eax
f0100a1a:	74 0e                	je     f0100a2a <mem_init+0x82>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0100a1c:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0100a22:	89 15 44 39 11 f0    	mov    %edx,0xf0113944
f0100a28:	eb 0c                	jmp    f0100a36 <mem_init+0x8e>
	else
		npages = npages_basemem;
f0100a2a:	8b 15 3c 35 11 f0    	mov    0xf011353c,%edx
f0100a30:	89 15 44 39 11 f0    	mov    %edx,0xf0113944

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0100a36:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100a39:	c1 e8 0a             	shr    $0xa,%eax
f0100a3c:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0100a40:	a1 3c 35 11 f0       	mov    0xf011353c,%eax
f0100a45:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100a48:	c1 e8 0a             	shr    $0xa,%eax
f0100a4b:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f0100a4f:	a1 44 39 11 f0       	mov    0xf0113944,%eax
f0100a54:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100a57:	c1 e8 0a             	shr    $0xa,%eax
f0100a5a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a5e:	c7 04 24 e4 20 10 f0 	movl   $0xf01020e4,(%esp)
f0100a65:	e8 1a 01 00 00       	call   f0100b84 <cprintf>

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();

	// Remove this line when you're ready to test this function.
	panic("mem_init: This function is not finished\n");
f0100a6a:	c7 44 24 08 20 21 10 	movl   $0xf0102120,0x8(%esp)
f0100a71:	f0 
f0100a72:	c7 44 24 04 81 00 00 	movl   $0x81,0x4(%esp)
f0100a79:	00 
f0100a7a:	c7 04 24 4c 21 10 f0 	movl   $0xf010214c,(%esp)
f0100a81:	e8 9b f6 ff ff       	call   f0100121 <_panic>

f0100a86 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100a86:	55                   	push   %ebp
f0100a87:	89 e5                	mov    %esp,%ebp
f0100a89:	53                   	push   %ebx
f0100a8a:	8b 1d 38 35 11 f0    	mov    0xf0113538,%ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100a90:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a95:	eb 22                	jmp    f0100ab9 <page_init+0x33>
f0100a97:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100a9e:	89 d1                	mov    %edx,%ecx
f0100aa0:	03 0d 4c 39 11 f0    	add    0xf011394c,%ecx
f0100aa6:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100aac:	89 19                	mov    %ebx,(%ecx)
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100aae:	83 c0 01             	add    $0x1,%eax
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100ab1:	89 d3                	mov    %edx,%ebx
f0100ab3:	03 1d 4c 39 11 f0    	add    0xf011394c,%ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100ab9:	3b 05 44 39 11 f0    	cmp    0xf0113944,%eax
f0100abf:	72 d6                	jb     f0100a97 <page_init+0x11>
f0100ac1:	89 1d 38 35 11 f0    	mov    %ebx,0xf0113538
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0100ac7:	5b                   	pop    %ebx
f0100ac8:	5d                   	pop    %ebp
f0100ac9:	c3                   	ret    

f0100aca <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100aca:	55                   	push   %ebp
f0100acb:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100acd:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ad2:	5d                   	pop    %ebp
f0100ad3:	c3                   	ret    

f0100ad4 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100ad4:	55                   	push   %ebp
f0100ad5:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
}
f0100ad7:	5d                   	pop    %ebp
f0100ad8:	c3                   	ret    

f0100ad9 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100ad9:	55                   	push   %ebp
f0100ada:	89 e5                	mov    %esp,%ebp
f0100adc:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100adf:	66 83 68 04 01       	subw   $0x1,0x4(%eax)
		page_free(pp);
}
f0100ae4:	5d                   	pop    %ebp
f0100ae5:	c3                   	ret    

f0100ae6 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100ae6:	55                   	push   %ebp
f0100ae7:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100ae9:	b8 00 00 00 00       	mov    $0x0,%eax
f0100aee:	5d                   	pop    %ebp
f0100aef:	c3                   	ret    

f0100af0 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100af0:	55                   	push   %ebp
f0100af1:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100af3:	b8 00 00 00 00       	mov    $0x0,%eax
f0100af8:	5d                   	pop    %ebp
f0100af9:	c3                   	ret    

f0100afa <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100afa:	55                   	push   %ebp
f0100afb:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100afd:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b02:	5d                   	pop    %ebp
f0100b03:	c3                   	ret    

f0100b04 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100b04:	55                   	push   %ebp
f0100b05:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0100b07:	5d                   	pop    %ebp
f0100b08:	c3                   	ret    

f0100b09 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0100b09:	55                   	push   %ebp
f0100b0a:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100b0c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100b0f:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0100b12:	5d                   	pop    %ebp
f0100b13:	c3                   	ret    

f0100b14 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0100b14:	55                   	push   %ebp
f0100b15:	89 e5                	mov    %esp,%ebp
f0100b17:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100b1b:	ba 70 00 00 00       	mov    $0x70,%edx
f0100b20:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100b21:	b2 71                	mov    $0x71,%dl
f0100b23:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0100b24:	0f b6 c0             	movzbl %al,%eax
}
f0100b27:	5d                   	pop    %ebp
f0100b28:	c3                   	ret    

f0100b29 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0100b29:	55                   	push   %ebp
f0100b2a:	89 e5                	mov    %esp,%ebp
f0100b2c:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100b30:	ba 70 00 00 00       	mov    $0x70,%edx
f0100b35:	ee                   	out    %al,(%dx)
f0100b36:	b2 71                	mov    $0x71,%dl
f0100b38:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100b3b:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0100b3c:	5d                   	pop    %ebp
f0100b3d:	c3                   	ret    

f0100b3e <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100b3e:	55                   	push   %ebp
f0100b3f:	89 e5                	mov    %esp,%ebp
f0100b41:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100b44:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b47:	89 04 24             	mov    %eax,(%esp)
f0100b4a:	e8 32 fb ff ff       	call   f0100681 <cputchar>
	*cnt++;
}
f0100b4f:	c9                   	leave  
f0100b50:	c3                   	ret    

f0100b51 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100b51:	55                   	push   %ebp
f0100b52:	89 e5                	mov    %esp,%ebp
f0100b54:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100b57:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100b5e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100b61:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b65:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b68:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100b6c:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100b6f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b73:	c7 04 24 3e 0b 10 f0 	movl   $0xf0100b3e,(%esp)
f0100b7a:	e8 af 04 00 00       	call   f010102e <vprintfmt>
	return cnt;
}
f0100b7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100b82:	c9                   	leave  
f0100b83:	c3                   	ret    

f0100b84 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100b84:	55                   	push   %ebp
f0100b85:	89 e5                	mov    %esp,%ebp
f0100b87:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100b8a:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100b8d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b91:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b94:	89 04 24             	mov    %eax,(%esp)
f0100b97:	e8 b5 ff ff ff       	call   f0100b51 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100b9c:	c9                   	leave  
f0100b9d:	c3                   	ret    

f0100b9e <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100b9e:	55                   	push   %ebp
f0100b9f:	89 e5                	mov    %esp,%ebp
f0100ba1:	57                   	push   %edi
f0100ba2:	56                   	push   %esi
f0100ba3:	53                   	push   %ebx
f0100ba4:	83 ec 10             	sub    $0x10,%esp
f0100ba7:	89 c6                	mov    %eax,%esi
f0100ba9:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100bac:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100baf:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100bb2:	8b 1a                	mov    (%edx),%ebx
f0100bb4:	8b 01                	mov    (%ecx),%eax
f0100bb6:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100bb9:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100bc0:	eb 77                	jmp    f0100c39 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100bc2:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100bc5:	01 d8                	add    %ebx,%eax
f0100bc7:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100bcc:	99                   	cltd   
f0100bcd:	f7 f9                	idiv   %ecx
f0100bcf:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100bd1:	eb 01                	jmp    f0100bd4 <stab_binsearch+0x36>
			m--;
f0100bd3:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100bd4:	39 d9                	cmp    %ebx,%ecx
f0100bd6:	7c 1d                	jl     f0100bf5 <stab_binsearch+0x57>
f0100bd8:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100bdb:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100be0:	39 fa                	cmp    %edi,%edx
f0100be2:	75 ef                	jne    f0100bd3 <stab_binsearch+0x35>
f0100be4:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100be7:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100bea:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100bee:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100bf1:	73 18                	jae    f0100c0b <stab_binsearch+0x6d>
f0100bf3:	eb 05                	jmp    f0100bfa <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100bf5:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100bf8:	eb 3f                	jmp    f0100c39 <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100bfa:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100bfd:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0100bff:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100c02:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100c09:	eb 2e                	jmp    f0100c39 <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100c0b:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100c0e:	73 15                	jae    f0100c25 <stab_binsearch+0x87>
			*region_right = m - 1;
f0100c10:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100c13:	48                   	dec    %eax
f0100c14:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100c17:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100c1a:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100c1c:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100c23:	eb 14                	jmp    f0100c39 <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100c25:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100c28:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100c2b:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0100c2d:	ff 45 0c             	incl   0xc(%ebp)
f0100c30:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100c32:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100c39:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100c3c:	7e 84                	jle    f0100bc2 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100c3e:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100c42:	75 0d                	jne    f0100c51 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100c44:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100c47:	8b 00                	mov    (%eax),%eax
f0100c49:	48                   	dec    %eax
f0100c4a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c4d:	89 07                	mov    %eax,(%edi)
f0100c4f:	eb 22                	jmp    f0100c73 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100c51:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c54:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100c56:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100c59:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100c5b:	eb 01                	jmp    f0100c5e <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100c5d:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100c5e:	39 c1                	cmp    %eax,%ecx
f0100c60:	7d 0c                	jge    f0100c6e <stab_binsearch+0xd0>
f0100c62:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100c65:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100c6a:	39 fa                	cmp    %edi,%edx
f0100c6c:	75 ef                	jne    f0100c5d <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100c6e:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100c71:	89 07                	mov    %eax,(%edi)
	}
}
f0100c73:	83 c4 10             	add    $0x10,%esp
f0100c76:	5b                   	pop    %ebx
f0100c77:	5e                   	pop    %esi
f0100c78:	5f                   	pop    %edi
f0100c79:	5d                   	pop    %ebp
f0100c7a:	c3                   	ret    

f0100c7b <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100c7b:	55                   	push   %ebp
f0100c7c:	89 e5                	mov    %esp,%ebp
f0100c7e:	57                   	push   %edi
f0100c7f:	56                   	push   %esi
f0100c80:	53                   	push   %ebx
f0100c81:	83 ec 3c             	sub    $0x3c,%esp
f0100c84:	8b 75 08             	mov    0x8(%ebp),%esi
f0100c87:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100c8a:	c7 03 58 21 10 f0    	movl   $0xf0102158,(%ebx)
	info->eip_line = 0;
f0100c90:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100c97:	c7 43 08 58 21 10 f0 	movl   $0xf0102158,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100c9e:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100ca5:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100ca8:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100caf:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100cb5:	76 12                	jbe    f0100cc9 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100cb7:	b8 81 80 10 f0       	mov    $0xf0108081,%eax
f0100cbc:	3d a9 64 10 f0       	cmp    $0xf01064a9,%eax
f0100cc1:	0f 86 cd 01 00 00    	jbe    f0100e94 <debuginfo_eip+0x219>
f0100cc7:	eb 1c                	jmp    f0100ce5 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100cc9:	c7 44 24 08 62 21 10 	movl   $0xf0102162,0x8(%esp)
f0100cd0:	f0 
f0100cd1:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100cd8:	00 
f0100cd9:	c7 04 24 6f 21 10 f0 	movl   $0xf010216f,(%esp)
f0100ce0:	e8 3c f4 ff ff       	call   f0100121 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ce5:	80 3d 80 80 10 f0 00 	cmpb   $0x0,0xf0108080
f0100cec:	0f 85 a9 01 00 00    	jne    f0100e9b <debuginfo_eip+0x220>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100cf2:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100cf9:	b8 a8 64 10 f0       	mov    $0xf01064a8,%eax
f0100cfe:	2d b0 23 10 f0       	sub    $0xf01023b0,%eax
f0100d03:	c1 f8 02             	sar    $0x2,%eax
f0100d06:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100d0c:	83 e8 01             	sub    $0x1,%eax
f0100d0f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100d12:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100d16:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100d1d:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100d20:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100d23:	b8 b0 23 10 f0       	mov    $0xf01023b0,%eax
f0100d28:	e8 71 fe ff ff       	call   f0100b9e <stab_binsearch>
	if (lfile == 0)
f0100d2d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d30:	85 c0                	test   %eax,%eax
f0100d32:	0f 84 6a 01 00 00    	je     f0100ea2 <debuginfo_eip+0x227>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100d38:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100d3b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d3e:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100d41:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100d45:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100d4c:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100d4f:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100d52:	b8 b0 23 10 f0       	mov    $0xf01023b0,%eax
f0100d57:	e8 42 fe ff ff       	call   f0100b9e <stab_binsearch>

	if (lfun <= rfun) {
f0100d5c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100d5f:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100d62:	39 d0                	cmp    %edx,%eax
f0100d64:	7f 3d                	jg     f0100da3 <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100d66:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100d69:	8d b9 b0 23 10 f0    	lea    -0xfefdc50(%ecx),%edi
f0100d6f:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100d72:	8b 89 b0 23 10 f0    	mov    -0xfefdc50(%ecx),%ecx
f0100d78:	bf 81 80 10 f0       	mov    $0xf0108081,%edi
f0100d7d:	81 ef a9 64 10 f0    	sub    $0xf01064a9,%edi
f0100d83:	39 f9                	cmp    %edi,%ecx
f0100d85:	73 09                	jae    f0100d90 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100d87:	81 c1 a9 64 10 f0    	add    $0xf01064a9,%ecx
f0100d8d:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100d90:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100d93:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100d96:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100d99:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100d9b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100d9e:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100da1:	eb 0f                	jmp    f0100db2 <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100da3:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100da6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100da9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100dac:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100daf:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100db2:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100db9:	00 
f0100dba:	8b 43 08             	mov    0x8(%ebx),%eax
f0100dbd:	89 04 24             	mov    %eax,(%esp)
f0100dc0:	e8 06 09 00 00       	call   f01016cb <strfind>
f0100dc5:	2b 43 08             	sub    0x8(%ebx),%eax
f0100dc8:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
f0100dcb:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100dcf:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100dd6:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100dd9:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100ddc:	b8 b0 23 10 f0       	mov    $0xf01023b0,%eax
f0100de1:	e8 b8 fd ff ff       	call   f0100b9e <stab_binsearch>
	if (lline > rline) {
f0100de6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100de9:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100dec:	0f 8f b7 00 00 00    	jg     f0100ea9 <debuginfo_eip+0x22e>
		return -1; //Did not find the line number in the stab
	}
	info->eip_line = stabs[lline].n_desc; //If found update the info object with the correct line number
f0100df2:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100df5:	0f b7 80 b6 23 10 f0 	movzwl -0xfefdc4a(%eax),%eax
f0100dfc:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100dff:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e02:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100e05:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e08:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100e0b:	81 c2 b0 23 10 f0    	add    $0xf01023b0,%edx
f0100e11:	eb 06                	jmp    f0100e19 <debuginfo_eip+0x19e>
f0100e13:	83 e8 01             	sub    $0x1,%eax
f0100e16:	83 ea 0c             	sub    $0xc,%edx
f0100e19:	89 c6                	mov    %eax,%esi
f0100e1b:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0100e1e:	7f 33                	jg     f0100e53 <debuginfo_eip+0x1d8>
	       && stabs[lline].n_type != N_SOL
f0100e20:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100e24:	80 f9 84             	cmp    $0x84,%cl
f0100e27:	74 0b                	je     f0100e34 <debuginfo_eip+0x1b9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100e29:	80 f9 64             	cmp    $0x64,%cl
f0100e2c:	75 e5                	jne    f0100e13 <debuginfo_eip+0x198>
f0100e2e:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0100e32:	74 df                	je     f0100e13 <debuginfo_eip+0x198>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100e34:	6b f6 0c             	imul   $0xc,%esi,%esi
f0100e37:	8b 86 b0 23 10 f0    	mov    -0xfefdc50(%esi),%eax
f0100e3d:	ba 81 80 10 f0       	mov    $0xf0108081,%edx
f0100e42:	81 ea a9 64 10 f0    	sub    $0xf01064a9,%edx
f0100e48:	39 d0                	cmp    %edx,%eax
f0100e4a:	73 07                	jae    f0100e53 <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100e4c:	05 a9 64 10 f0       	add    $0xf01064a9,%eax
f0100e51:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100e53:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100e56:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100e59:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100e5e:	39 ca                	cmp    %ecx,%edx
f0100e60:	7d 53                	jge    f0100eb5 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
f0100e62:	8d 42 01             	lea    0x1(%edx),%eax
f0100e65:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100e68:	89 c2                	mov    %eax,%edx
f0100e6a:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100e6d:	05 b0 23 10 f0       	add    $0xf01023b0,%eax
f0100e72:	89 ce                	mov    %ecx,%esi
f0100e74:	eb 04                	jmp    f0100e7a <debuginfo_eip+0x1ff>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100e76:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100e7a:	39 d6                	cmp    %edx,%esi
f0100e7c:	7e 32                	jle    f0100eb0 <debuginfo_eip+0x235>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100e7e:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100e82:	83 c2 01             	add    $0x1,%edx
f0100e85:	83 c0 0c             	add    $0xc,%eax
f0100e88:	80 f9 a0             	cmp    $0xa0,%cl
f0100e8b:	74 e9                	je     f0100e76 <debuginfo_eip+0x1fb>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100e8d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e92:	eb 21                	jmp    f0100eb5 <debuginfo_eip+0x23a>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100e94:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e99:	eb 1a                	jmp    f0100eb5 <debuginfo_eip+0x23a>
f0100e9b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ea0:	eb 13                	jmp    f0100eb5 <debuginfo_eip+0x23a>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100ea2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ea7:	eb 0c                	jmp    f0100eb5 <debuginfo_eip+0x23a>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
	if (lline > rline) {
		return -1; //Did not find the line number in the stab
f0100ea9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100eae:	eb 05                	jmp    f0100eb5 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100eb0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100eb5:	83 c4 3c             	add    $0x3c,%esp
f0100eb8:	5b                   	pop    %ebx
f0100eb9:	5e                   	pop    %esi
f0100eba:	5f                   	pop    %edi
f0100ebb:	5d                   	pop    %ebp
f0100ebc:	c3                   	ret    
f0100ebd:	66 90                	xchg   %ax,%ax
f0100ebf:	90                   	nop

f0100ec0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100ec0:	55                   	push   %ebp
f0100ec1:	89 e5                	mov    %esp,%ebp
f0100ec3:	57                   	push   %edi
f0100ec4:	56                   	push   %esi
f0100ec5:	53                   	push   %ebx
f0100ec6:	83 ec 3c             	sub    $0x3c,%esp
f0100ec9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100ecc:	89 d7                	mov    %edx,%edi
f0100ece:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ed1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100ed4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ed7:	89 c3                	mov    %eax,%ebx
f0100ed9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100edc:	8b 45 10             	mov    0x10(%ebp),%eax
f0100edf:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100ee2:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100ee7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100eea:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100eed:	39 d9                	cmp    %ebx,%ecx
f0100eef:	72 05                	jb     f0100ef6 <printnum+0x36>
f0100ef1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100ef4:	77 69                	ja     f0100f5f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100ef6:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100ef9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100efd:	83 ee 01             	sub    $0x1,%esi
f0100f00:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100f04:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100f08:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100f0c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100f10:	89 c3                	mov    %eax,%ebx
f0100f12:	89 d6                	mov    %edx,%esi
f0100f14:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100f17:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100f1a:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100f1e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100f22:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f25:	89 04 24             	mov    %eax,(%esp)
f0100f28:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f2b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f2f:	e8 bc 09 00 00       	call   f01018f0 <__udivdi3>
f0100f34:	89 d9                	mov    %ebx,%ecx
f0100f36:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100f3a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100f3e:	89 04 24             	mov    %eax,(%esp)
f0100f41:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100f45:	89 fa                	mov    %edi,%edx
f0100f47:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f4a:	e8 71 ff ff ff       	call   f0100ec0 <printnum>
f0100f4f:	eb 1b                	jmp    f0100f6c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100f51:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f55:	8b 45 18             	mov    0x18(%ebp),%eax
f0100f58:	89 04 24             	mov    %eax,(%esp)
f0100f5b:	ff d3                	call   *%ebx
f0100f5d:	eb 03                	jmp    f0100f62 <printnum+0xa2>
f0100f5f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100f62:	83 ee 01             	sub    $0x1,%esi
f0100f65:	85 f6                	test   %esi,%esi
f0100f67:	7f e8                	jg     f0100f51 <printnum+0x91>
f0100f69:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100f6c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f70:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100f74:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100f77:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100f7a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100f7e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100f82:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f85:	89 04 24             	mov    %eax,(%esp)
f0100f88:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f8b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f8f:	e8 8c 0a 00 00       	call   f0101a20 <__umoddi3>
f0100f94:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f98:	0f be 80 7d 21 10 f0 	movsbl -0xfefde83(%eax),%eax
f0100f9f:	89 04 24             	mov    %eax,(%esp)
f0100fa2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100fa5:	ff d0                	call   *%eax
}
f0100fa7:	83 c4 3c             	add    $0x3c,%esp
f0100faa:	5b                   	pop    %ebx
f0100fab:	5e                   	pop    %esi
f0100fac:	5f                   	pop    %edi
f0100fad:	5d                   	pop    %ebp
f0100fae:	c3                   	ret    

f0100faf <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100faf:	55                   	push   %ebp
f0100fb0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100fb2:	83 fa 01             	cmp    $0x1,%edx
f0100fb5:	7e 0e                	jle    f0100fc5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100fb7:	8b 10                	mov    (%eax),%edx
f0100fb9:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100fbc:	89 08                	mov    %ecx,(%eax)
f0100fbe:	8b 02                	mov    (%edx),%eax
f0100fc0:	8b 52 04             	mov    0x4(%edx),%edx
f0100fc3:	eb 22                	jmp    f0100fe7 <getuint+0x38>
	else if (lflag)
f0100fc5:	85 d2                	test   %edx,%edx
f0100fc7:	74 10                	je     f0100fd9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100fc9:	8b 10                	mov    (%eax),%edx
f0100fcb:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100fce:	89 08                	mov    %ecx,(%eax)
f0100fd0:	8b 02                	mov    (%edx),%eax
f0100fd2:	ba 00 00 00 00       	mov    $0x0,%edx
f0100fd7:	eb 0e                	jmp    f0100fe7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100fd9:	8b 10                	mov    (%eax),%edx
f0100fdb:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100fde:	89 08                	mov    %ecx,(%eax)
f0100fe0:	8b 02                	mov    (%edx),%eax
f0100fe2:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100fe7:	5d                   	pop    %ebp
f0100fe8:	c3                   	ret    

f0100fe9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100fe9:	55                   	push   %ebp
f0100fea:	89 e5                	mov    %esp,%ebp
f0100fec:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100fef:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100ff3:	8b 10                	mov    (%eax),%edx
f0100ff5:	3b 50 04             	cmp    0x4(%eax),%edx
f0100ff8:	73 0a                	jae    f0101004 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100ffa:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100ffd:	89 08                	mov    %ecx,(%eax)
f0100fff:	8b 45 08             	mov    0x8(%ebp),%eax
f0101002:	88 02                	mov    %al,(%edx)
}
f0101004:	5d                   	pop    %ebp
f0101005:	c3                   	ret    

f0101006 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0101006:	55                   	push   %ebp
f0101007:	89 e5                	mov    %esp,%ebp
f0101009:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f010100c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010100f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101013:	8b 45 10             	mov    0x10(%ebp),%eax
f0101016:	89 44 24 08          	mov    %eax,0x8(%esp)
f010101a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010101d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101021:	8b 45 08             	mov    0x8(%ebp),%eax
f0101024:	89 04 24             	mov    %eax,(%esp)
f0101027:	e8 02 00 00 00       	call   f010102e <vprintfmt>
	va_end(ap);
}
f010102c:	c9                   	leave  
f010102d:	c3                   	ret    

f010102e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010102e:	55                   	push   %ebp
f010102f:	89 e5                	mov    %esp,%ebp
f0101031:	57                   	push   %edi
f0101032:	56                   	push   %esi
f0101033:	53                   	push   %ebx
f0101034:	83 ec 3c             	sub    $0x3c,%esp
f0101037:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010103a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010103d:	eb 14                	jmp    f0101053 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010103f:	85 c0                	test   %eax,%eax
f0101041:	0f 84 b3 03 00 00    	je     f01013fa <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0101047:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010104b:	89 04 24             	mov    %eax,(%esp)
f010104e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101051:	89 f3                	mov    %esi,%ebx
f0101053:	8d 73 01             	lea    0x1(%ebx),%esi
f0101056:	0f b6 03             	movzbl (%ebx),%eax
f0101059:	83 f8 25             	cmp    $0x25,%eax
f010105c:	75 e1                	jne    f010103f <vprintfmt+0x11>
f010105e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0101062:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0101069:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0101070:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0101077:	ba 00 00 00 00       	mov    $0x0,%edx
f010107c:	eb 1d                	jmp    f010109b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010107e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0101080:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0101084:	eb 15                	jmp    f010109b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101086:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0101088:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f010108c:	eb 0d                	jmp    f010109b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f010108e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101091:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101094:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010109b:	8d 5e 01             	lea    0x1(%esi),%ebx
f010109e:	0f b6 0e             	movzbl (%esi),%ecx
f01010a1:	0f b6 c1             	movzbl %cl,%eax
f01010a4:	83 e9 23             	sub    $0x23,%ecx
f01010a7:	80 f9 55             	cmp    $0x55,%cl
f01010aa:	0f 87 2a 03 00 00    	ja     f01013da <vprintfmt+0x3ac>
f01010b0:	0f b6 c9             	movzbl %cl,%ecx
f01010b3:	ff 24 8d 20 22 10 f0 	jmp    *-0xfefdde0(,%ecx,4)
f01010ba:	89 de                	mov    %ebx,%esi
f01010bc:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01010c1:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f01010c4:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f01010c8:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f01010cb:	8d 58 d0             	lea    -0x30(%eax),%ebx
f01010ce:	83 fb 09             	cmp    $0x9,%ebx
f01010d1:	77 36                	ja     f0101109 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01010d3:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01010d6:	eb e9                	jmp    f01010c1 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01010d8:	8b 45 14             	mov    0x14(%ebp),%eax
f01010db:	8d 48 04             	lea    0x4(%eax),%ecx
f01010de:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01010e1:	8b 00                	mov    (%eax),%eax
f01010e3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010e6:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01010e8:	eb 22                	jmp    f010110c <vprintfmt+0xde>
f01010ea:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01010ed:	85 c9                	test   %ecx,%ecx
f01010ef:	b8 00 00 00 00       	mov    $0x0,%eax
f01010f4:	0f 49 c1             	cmovns %ecx,%eax
f01010f7:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010fa:	89 de                	mov    %ebx,%esi
f01010fc:	eb 9d                	jmp    f010109b <vprintfmt+0x6d>
f01010fe:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0101100:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0101107:	eb 92                	jmp    f010109b <vprintfmt+0x6d>
f0101109:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f010110c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101110:	79 89                	jns    f010109b <vprintfmt+0x6d>
f0101112:	e9 77 ff ff ff       	jmp    f010108e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0101117:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010111a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010111c:	e9 7a ff ff ff       	jmp    f010109b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0101121:	8b 45 14             	mov    0x14(%ebp),%eax
f0101124:	8d 50 04             	lea    0x4(%eax),%edx
f0101127:	89 55 14             	mov    %edx,0x14(%ebp)
f010112a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010112e:	8b 00                	mov    (%eax),%eax
f0101130:	89 04 24             	mov    %eax,(%esp)
f0101133:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101136:	e9 18 ff ff ff       	jmp    f0101053 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010113b:	8b 45 14             	mov    0x14(%ebp),%eax
f010113e:	8d 50 04             	lea    0x4(%eax),%edx
f0101141:	89 55 14             	mov    %edx,0x14(%ebp)
f0101144:	8b 00                	mov    (%eax),%eax
f0101146:	99                   	cltd   
f0101147:	31 d0                	xor    %edx,%eax
f0101149:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010114b:	83 f8 07             	cmp    $0x7,%eax
f010114e:	7f 0b                	jg     f010115b <vprintfmt+0x12d>
f0101150:	8b 14 85 80 23 10 f0 	mov    -0xfefdc80(,%eax,4),%edx
f0101157:	85 d2                	test   %edx,%edx
f0101159:	75 20                	jne    f010117b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f010115b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010115f:	c7 44 24 08 95 21 10 	movl   $0xf0102195,0x8(%esp)
f0101166:	f0 
f0101167:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010116b:	8b 45 08             	mov    0x8(%ebp),%eax
f010116e:	89 04 24             	mov    %eax,(%esp)
f0101171:	e8 90 fe ff ff       	call   f0101006 <printfmt>
f0101176:	e9 d8 fe ff ff       	jmp    f0101053 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f010117b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010117f:	c7 44 24 08 9e 21 10 	movl   $0xf010219e,0x8(%esp)
f0101186:	f0 
f0101187:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010118b:	8b 45 08             	mov    0x8(%ebp),%eax
f010118e:	89 04 24             	mov    %eax,(%esp)
f0101191:	e8 70 fe ff ff       	call   f0101006 <printfmt>
f0101196:	e9 b8 fe ff ff       	jmp    f0101053 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010119b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010119e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01011a1:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01011a4:	8b 45 14             	mov    0x14(%ebp),%eax
f01011a7:	8d 50 04             	lea    0x4(%eax),%edx
f01011aa:	89 55 14             	mov    %edx,0x14(%ebp)
f01011ad:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f01011af:	85 f6                	test   %esi,%esi
f01011b1:	b8 8e 21 10 f0       	mov    $0xf010218e,%eax
f01011b6:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f01011b9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f01011bd:	0f 84 97 00 00 00    	je     f010125a <vprintfmt+0x22c>
f01011c3:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01011c7:	0f 8e 9b 00 00 00    	jle    f0101268 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f01011cd:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01011d1:	89 34 24             	mov    %esi,(%esp)
f01011d4:	e8 9f 03 00 00       	call   f0101578 <strnlen>
f01011d9:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01011dc:	29 c2                	sub    %eax,%edx
f01011de:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f01011e1:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f01011e5:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01011e8:	89 75 d8             	mov    %esi,-0x28(%ebp)
f01011eb:	8b 75 08             	mov    0x8(%ebp),%esi
f01011ee:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01011f1:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01011f3:	eb 0f                	jmp    f0101204 <vprintfmt+0x1d6>
					putch(padc, putdat);
f01011f5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011f9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01011fc:	89 04 24             	mov    %eax,(%esp)
f01011ff:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101201:	83 eb 01             	sub    $0x1,%ebx
f0101204:	85 db                	test   %ebx,%ebx
f0101206:	7f ed                	jg     f01011f5 <vprintfmt+0x1c7>
f0101208:	8b 75 d8             	mov    -0x28(%ebp),%esi
f010120b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010120e:	85 d2                	test   %edx,%edx
f0101210:	b8 00 00 00 00       	mov    $0x0,%eax
f0101215:	0f 49 c2             	cmovns %edx,%eax
f0101218:	29 c2                	sub    %eax,%edx
f010121a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010121d:	89 d7                	mov    %edx,%edi
f010121f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101222:	eb 50                	jmp    f0101274 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101224:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101228:	74 1e                	je     f0101248 <vprintfmt+0x21a>
f010122a:	0f be d2             	movsbl %dl,%edx
f010122d:	83 ea 20             	sub    $0x20,%edx
f0101230:	83 fa 5e             	cmp    $0x5e,%edx
f0101233:	76 13                	jbe    f0101248 <vprintfmt+0x21a>
					putch('?', putdat);
f0101235:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101238:	89 44 24 04          	mov    %eax,0x4(%esp)
f010123c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101243:	ff 55 08             	call   *0x8(%ebp)
f0101246:	eb 0d                	jmp    f0101255 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0101248:	8b 55 0c             	mov    0xc(%ebp),%edx
f010124b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010124f:	89 04 24             	mov    %eax,(%esp)
f0101252:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101255:	83 ef 01             	sub    $0x1,%edi
f0101258:	eb 1a                	jmp    f0101274 <vprintfmt+0x246>
f010125a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010125d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0101260:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101263:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101266:	eb 0c                	jmp    f0101274 <vprintfmt+0x246>
f0101268:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010126b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f010126e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101271:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101274:	83 c6 01             	add    $0x1,%esi
f0101277:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f010127b:	0f be c2             	movsbl %dl,%eax
f010127e:	85 c0                	test   %eax,%eax
f0101280:	74 27                	je     f01012a9 <vprintfmt+0x27b>
f0101282:	85 db                	test   %ebx,%ebx
f0101284:	78 9e                	js     f0101224 <vprintfmt+0x1f6>
f0101286:	83 eb 01             	sub    $0x1,%ebx
f0101289:	79 99                	jns    f0101224 <vprintfmt+0x1f6>
f010128b:	89 f8                	mov    %edi,%eax
f010128d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101290:	8b 75 08             	mov    0x8(%ebp),%esi
f0101293:	89 c3                	mov    %eax,%ebx
f0101295:	eb 1a                	jmp    f01012b1 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101297:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010129b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01012a2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01012a4:	83 eb 01             	sub    $0x1,%ebx
f01012a7:	eb 08                	jmp    f01012b1 <vprintfmt+0x283>
f01012a9:	89 fb                	mov    %edi,%ebx
f01012ab:	8b 75 08             	mov    0x8(%ebp),%esi
f01012ae:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01012b1:	85 db                	test   %ebx,%ebx
f01012b3:	7f e2                	jg     f0101297 <vprintfmt+0x269>
f01012b5:	89 75 08             	mov    %esi,0x8(%ebp)
f01012b8:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01012bb:	e9 93 fd ff ff       	jmp    f0101053 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01012c0:	83 fa 01             	cmp    $0x1,%edx
f01012c3:	7e 16                	jle    f01012db <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f01012c5:	8b 45 14             	mov    0x14(%ebp),%eax
f01012c8:	8d 50 08             	lea    0x8(%eax),%edx
f01012cb:	89 55 14             	mov    %edx,0x14(%ebp)
f01012ce:	8b 50 04             	mov    0x4(%eax),%edx
f01012d1:	8b 00                	mov    (%eax),%eax
f01012d3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01012d6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01012d9:	eb 32                	jmp    f010130d <vprintfmt+0x2df>
	else if (lflag)
f01012db:	85 d2                	test   %edx,%edx
f01012dd:	74 18                	je     f01012f7 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f01012df:	8b 45 14             	mov    0x14(%ebp),%eax
f01012e2:	8d 50 04             	lea    0x4(%eax),%edx
f01012e5:	89 55 14             	mov    %edx,0x14(%ebp)
f01012e8:	8b 30                	mov    (%eax),%esi
f01012ea:	89 75 e0             	mov    %esi,-0x20(%ebp)
f01012ed:	89 f0                	mov    %esi,%eax
f01012ef:	c1 f8 1f             	sar    $0x1f,%eax
f01012f2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01012f5:	eb 16                	jmp    f010130d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f01012f7:	8b 45 14             	mov    0x14(%ebp),%eax
f01012fa:	8d 50 04             	lea    0x4(%eax),%edx
f01012fd:	89 55 14             	mov    %edx,0x14(%ebp)
f0101300:	8b 30                	mov    (%eax),%esi
f0101302:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0101305:	89 f0                	mov    %esi,%eax
f0101307:	c1 f8 1f             	sar    $0x1f,%eax
f010130a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010130d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101310:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101313:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101318:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010131c:	0f 89 80 00 00 00    	jns    f01013a2 <vprintfmt+0x374>
				putch('-', putdat);
f0101322:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101326:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010132d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101330:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101333:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101336:	f7 d8                	neg    %eax
f0101338:	83 d2 00             	adc    $0x0,%edx
f010133b:	f7 da                	neg    %edx
			}
			base = 10;
f010133d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101342:	eb 5e                	jmp    f01013a2 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101344:	8d 45 14             	lea    0x14(%ebp),%eax
f0101347:	e8 63 fc ff ff       	call   f0100faf <getuint>
			base = 10;
f010134c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101351:	eb 4f                	jmp    f01013a2 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0101353:	8d 45 14             	lea    0x14(%ebp),%eax
f0101356:	e8 54 fc ff ff       	call   f0100faf <getuint>
			base = 8;
f010135b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101360:	eb 40                	jmp    f01013a2 <vprintfmt+0x374>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f0101362:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101366:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010136d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101370:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101374:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010137b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010137e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101381:	8d 50 04             	lea    0x4(%eax),%edx
f0101384:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101387:	8b 00                	mov    (%eax),%eax
f0101389:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010138e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101393:	eb 0d                	jmp    f01013a2 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101395:	8d 45 14             	lea    0x14(%ebp),%eax
f0101398:	e8 12 fc ff ff       	call   f0100faf <getuint>
			base = 16;
f010139d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01013a2:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f01013a6:	89 74 24 10          	mov    %esi,0x10(%esp)
f01013aa:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01013ad:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01013b1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01013b5:	89 04 24             	mov    %eax,(%esp)
f01013b8:	89 54 24 04          	mov    %edx,0x4(%esp)
f01013bc:	89 fa                	mov    %edi,%edx
f01013be:	8b 45 08             	mov    0x8(%ebp),%eax
f01013c1:	e8 fa fa ff ff       	call   f0100ec0 <printnum>
			break;
f01013c6:	e9 88 fc ff ff       	jmp    f0101053 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01013cb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01013cf:	89 04 24             	mov    %eax,(%esp)
f01013d2:	ff 55 08             	call   *0x8(%ebp)
			break;
f01013d5:	e9 79 fc ff ff       	jmp    f0101053 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01013da:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01013de:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01013e5:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01013e8:	89 f3                	mov    %esi,%ebx
f01013ea:	eb 03                	jmp    f01013ef <vprintfmt+0x3c1>
f01013ec:	83 eb 01             	sub    $0x1,%ebx
f01013ef:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f01013f3:	75 f7                	jne    f01013ec <vprintfmt+0x3be>
f01013f5:	e9 59 fc ff ff       	jmp    f0101053 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f01013fa:	83 c4 3c             	add    $0x3c,%esp
f01013fd:	5b                   	pop    %ebx
f01013fe:	5e                   	pop    %esi
f01013ff:	5f                   	pop    %edi
f0101400:	5d                   	pop    %ebp
f0101401:	c3                   	ret    

f0101402 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101402:	55                   	push   %ebp
f0101403:	89 e5                	mov    %esp,%ebp
f0101405:	83 ec 28             	sub    $0x28,%esp
f0101408:	8b 45 08             	mov    0x8(%ebp),%eax
f010140b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010140e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101411:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101415:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101418:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010141f:	85 c0                	test   %eax,%eax
f0101421:	74 30                	je     f0101453 <vsnprintf+0x51>
f0101423:	85 d2                	test   %edx,%edx
f0101425:	7e 2c                	jle    f0101453 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101427:	8b 45 14             	mov    0x14(%ebp),%eax
f010142a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010142e:	8b 45 10             	mov    0x10(%ebp),%eax
f0101431:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101435:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101438:	89 44 24 04          	mov    %eax,0x4(%esp)
f010143c:	c7 04 24 e9 0f 10 f0 	movl   $0xf0100fe9,(%esp)
f0101443:	e8 e6 fb ff ff       	call   f010102e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101448:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010144b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010144e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101451:	eb 05                	jmp    f0101458 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101453:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101458:	c9                   	leave  
f0101459:	c3                   	ret    

f010145a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010145a:	55                   	push   %ebp
f010145b:	89 e5                	mov    %esp,%ebp
f010145d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101460:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101463:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101467:	8b 45 10             	mov    0x10(%ebp),%eax
f010146a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010146e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101471:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101475:	8b 45 08             	mov    0x8(%ebp),%eax
f0101478:	89 04 24             	mov    %eax,(%esp)
f010147b:	e8 82 ff ff ff       	call   f0101402 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101480:	c9                   	leave  
f0101481:	c3                   	ret    
f0101482:	66 90                	xchg   %ax,%ax
f0101484:	66 90                	xchg   %ax,%ax
f0101486:	66 90                	xchg   %ax,%ax
f0101488:	66 90                	xchg   %ax,%ax
f010148a:	66 90                	xchg   %ax,%ax
f010148c:	66 90                	xchg   %ax,%ax
f010148e:	66 90                	xchg   %ax,%ax

f0101490 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101490:	55                   	push   %ebp
f0101491:	89 e5                	mov    %esp,%ebp
f0101493:	57                   	push   %edi
f0101494:	56                   	push   %esi
f0101495:	53                   	push   %ebx
f0101496:	83 ec 1c             	sub    $0x1c,%esp
f0101499:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010149c:	85 c0                	test   %eax,%eax
f010149e:	74 10                	je     f01014b0 <readline+0x20>
		cprintf("%s", prompt);
f01014a0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01014a4:	c7 04 24 9e 21 10 f0 	movl   $0xf010219e,(%esp)
f01014ab:	e8 d4 f6 ff ff       	call   f0100b84 <cprintf>

	i = 0;
	echoing = iscons(0);
f01014b0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014b7:	e8 e6 f1 ff ff       	call   f01006a2 <iscons>
f01014bc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01014be:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01014c3:	e8 c9 f1 ff ff       	call   f0100691 <getchar>
f01014c8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01014ca:	85 c0                	test   %eax,%eax
f01014cc:	79 17                	jns    f01014e5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01014ce:	89 44 24 04          	mov    %eax,0x4(%esp)
f01014d2:	c7 04 24 a0 23 10 f0 	movl   $0xf01023a0,(%esp)
f01014d9:	e8 a6 f6 ff ff       	call   f0100b84 <cprintf>
			return NULL;
f01014de:	b8 00 00 00 00       	mov    $0x0,%eax
f01014e3:	eb 6d                	jmp    f0101552 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01014e5:	83 f8 7f             	cmp    $0x7f,%eax
f01014e8:	74 05                	je     f01014ef <readline+0x5f>
f01014ea:	83 f8 08             	cmp    $0x8,%eax
f01014ed:	75 19                	jne    f0101508 <readline+0x78>
f01014ef:	85 f6                	test   %esi,%esi
f01014f1:	7e 15                	jle    f0101508 <readline+0x78>
			if (echoing)
f01014f3:	85 ff                	test   %edi,%edi
f01014f5:	74 0c                	je     f0101503 <readline+0x73>
				cputchar('\b');
f01014f7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01014fe:	e8 7e f1 ff ff       	call   f0100681 <cputchar>
			i--;
f0101503:	83 ee 01             	sub    $0x1,%esi
f0101506:	eb bb                	jmp    f01014c3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101508:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010150e:	7f 1c                	jg     f010152c <readline+0x9c>
f0101510:	83 fb 1f             	cmp    $0x1f,%ebx
f0101513:	7e 17                	jle    f010152c <readline+0x9c>
			if (echoing)
f0101515:	85 ff                	test   %edi,%edi
f0101517:	74 08                	je     f0101521 <readline+0x91>
				cputchar(c);
f0101519:	89 1c 24             	mov    %ebx,(%esp)
f010151c:	e8 60 f1 ff ff       	call   f0100681 <cputchar>
			buf[i++] = c;
f0101521:	88 9e 40 35 11 f0    	mov    %bl,-0xfeecac0(%esi)
f0101527:	8d 76 01             	lea    0x1(%esi),%esi
f010152a:	eb 97                	jmp    f01014c3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010152c:	83 fb 0d             	cmp    $0xd,%ebx
f010152f:	74 05                	je     f0101536 <readline+0xa6>
f0101531:	83 fb 0a             	cmp    $0xa,%ebx
f0101534:	75 8d                	jne    f01014c3 <readline+0x33>
			if (echoing)
f0101536:	85 ff                	test   %edi,%edi
f0101538:	74 0c                	je     f0101546 <readline+0xb6>
				cputchar('\n');
f010153a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101541:	e8 3b f1 ff ff       	call   f0100681 <cputchar>
			buf[i] = 0;
f0101546:	c6 86 40 35 11 f0 00 	movb   $0x0,-0xfeecac0(%esi)
			return buf;
f010154d:	b8 40 35 11 f0       	mov    $0xf0113540,%eax
		}
	}
}
f0101552:	83 c4 1c             	add    $0x1c,%esp
f0101555:	5b                   	pop    %ebx
f0101556:	5e                   	pop    %esi
f0101557:	5f                   	pop    %edi
f0101558:	5d                   	pop    %ebp
f0101559:	c3                   	ret    
f010155a:	66 90                	xchg   %ax,%ax
f010155c:	66 90                	xchg   %ax,%ax
f010155e:	66 90                	xchg   %ax,%ax

f0101560 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101560:	55                   	push   %ebp
f0101561:	89 e5                	mov    %esp,%ebp
f0101563:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101566:	b8 00 00 00 00       	mov    $0x0,%eax
f010156b:	eb 03                	jmp    f0101570 <strlen+0x10>
		n++;
f010156d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101570:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101574:	75 f7                	jne    f010156d <strlen+0xd>
		n++;
	return n;
}
f0101576:	5d                   	pop    %ebp
f0101577:	c3                   	ret    

f0101578 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101578:	55                   	push   %ebp
f0101579:	89 e5                	mov    %esp,%ebp
f010157b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010157e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101581:	b8 00 00 00 00       	mov    $0x0,%eax
f0101586:	eb 03                	jmp    f010158b <strnlen+0x13>
		n++;
f0101588:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010158b:	39 d0                	cmp    %edx,%eax
f010158d:	74 06                	je     f0101595 <strnlen+0x1d>
f010158f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101593:	75 f3                	jne    f0101588 <strnlen+0x10>
		n++;
	return n;
}
f0101595:	5d                   	pop    %ebp
f0101596:	c3                   	ret    

f0101597 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101597:	55                   	push   %ebp
f0101598:	89 e5                	mov    %esp,%ebp
f010159a:	53                   	push   %ebx
f010159b:	8b 45 08             	mov    0x8(%ebp),%eax
f010159e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01015a1:	89 c2                	mov    %eax,%edx
f01015a3:	83 c2 01             	add    $0x1,%edx
f01015a6:	83 c1 01             	add    $0x1,%ecx
f01015a9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01015ad:	88 5a ff             	mov    %bl,-0x1(%edx)
f01015b0:	84 db                	test   %bl,%bl
f01015b2:	75 ef                	jne    f01015a3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01015b4:	5b                   	pop    %ebx
f01015b5:	5d                   	pop    %ebp
f01015b6:	c3                   	ret    

f01015b7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01015b7:	55                   	push   %ebp
f01015b8:	89 e5                	mov    %esp,%ebp
f01015ba:	53                   	push   %ebx
f01015bb:	83 ec 08             	sub    $0x8,%esp
f01015be:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01015c1:	89 1c 24             	mov    %ebx,(%esp)
f01015c4:	e8 97 ff ff ff       	call   f0101560 <strlen>
	strcpy(dst + len, src);
f01015c9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01015cc:	89 54 24 04          	mov    %edx,0x4(%esp)
f01015d0:	01 d8                	add    %ebx,%eax
f01015d2:	89 04 24             	mov    %eax,(%esp)
f01015d5:	e8 bd ff ff ff       	call   f0101597 <strcpy>
	return dst;
}
f01015da:	89 d8                	mov    %ebx,%eax
f01015dc:	83 c4 08             	add    $0x8,%esp
f01015df:	5b                   	pop    %ebx
f01015e0:	5d                   	pop    %ebp
f01015e1:	c3                   	ret    

f01015e2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01015e2:	55                   	push   %ebp
f01015e3:	89 e5                	mov    %esp,%ebp
f01015e5:	56                   	push   %esi
f01015e6:	53                   	push   %ebx
f01015e7:	8b 75 08             	mov    0x8(%ebp),%esi
f01015ea:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01015ed:	89 f3                	mov    %esi,%ebx
f01015ef:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01015f2:	89 f2                	mov    %esi,%edx
f01015f4:	eb 0f                	jmp    f0101605 <strncpy+0x23>
		*dst++ = *src;
f01015f6:	83 c2 01             	add    $0x1,%edx
f01015f9:	0f b6 01             	movzbl (%ecx),%eax
f01015fc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01015ff:	80 39 01             	cmpb   $0x1,(%ecx)
f0101602:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101605:	39 da                	cmp    %ebx,%edx
f0101607:	75 ed                	jne    f01015f6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101609:	89 f0                	mov    %esi,%eax
f010160b:	5b                   	pop    %ebx
f010160c:	5e                   	pop    %esi
f010160d:	5d                   	pop    %ebp
f010160e:	c3                   	ret    

f010160f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010160f:	55                   	push   %ebp
f0101610:	89 e5                	mov    %esp,%ebp
f0101612:	56                   	push   %esi
f0101613:	53                   	push   %ebx
f0101614:	8b 75 08             	mov    0x8(%ebp),%esi
f0101617:	8b 55 0c             	mov    0xc(%ebp),%edx
f010161a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010161d:	89 f0                	mov    %esi,%eax
f010161f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101623:	85 c9                	test   %ecx,%ecx
f0101625:	75 0b                	jne    f0101632 <strlcpy+0x23>
f0101627:	eb 1d                	jmp    f0101646 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101629:	83 c0 01             	add    $0x1,%eax
f010162c:	83 c2 01             	add    $0x1,%edx
f010162f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101632:	39 d8                	cmp    %ebx,%eax
f0101634:	74 0b                	je     f0101641 <strlcpy+0x32>
f0101636:	0f b6 0a             	movzbl (%edx),%ecx
f0101639:	84 c9                	test   %cl,%cl
f010163b:	75 ec                	jne    f0101629 <strlcpy+0x1a>
f010163d:	89 c2                	mov    %eax,%edx
f010163f:	eb 02                	jmp    f0101643 <strlcpy+0x34>
f0101641:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0101643:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0101646:	29 f0                	sub    %esi,%eax
}
f0101648:	5b                   	pop    %ebx
f0101649:	5e                   	pop    %esi
f010164a:	5d                   	pop    %ebp
f010164b:	c3                   	ret    

f010164c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010164c:	55                   	push   %ebp
f010164d:	89 e5                	mov    %esp,%ebp
f010164f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101652:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101655:	eb 06                	jmp    f010165d <strcmp+0x11>
		p++, q++;
f0101657:	83 c1 01             	add    $0x1,%ecx
f010165a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010165d:	0f b6 01             	movzbl (%ecx),%eax
f0101660:	84 c0                	test   %al,%al
f0101662:	74 04                	je     f0101668 <strcmp+0x1c>
f0101664:	3a 02                	cmp    (%edx),%al
f0101666:	74 ef                	je     f0101657 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101668:	0f b6 c0             	movzbl %al,%eax
f010166b:	0f b6 12             	movzbl (%edx),%edx
f010166e:	29 d0                	sub    %edx,%eax
}
f0101670:	5d                   	pop    %ebp
f0101671:	c3                   	ret    

f0101672 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101672:	55                   	push   %ebp
f0101673:	89 e5                	mov    %esp,%ebp
f0101675:	53                   	push   %ebx
f0101676:	8b 45 08             	mov    0x8(%ebp),%eax
f0101679:	8b 55 0c             	mov    0xc(%ebp),%edx
f010167c:	89 c3                	mov    %eax,%ebx
f010167e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101681:	eb 06                	jmp    f0101689 <strncmp+0x17>
		n--, p++, q++;
f0101683:	83 c0 01             	add    $0x1,%eax
f0101686:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101689:	39 d8                	cmp    %ebx,%eax
f010168b:	74 15                	je     f01016a2 <strncmp+0x30>
f010168d:	0f b6 08             	movzbl (%eax),%ecx
f0101690:	84 c9                	test   %cl,%cl
f0101692:	74 04                	je     f0101698 <strncmp+0x26>
f0101694:	3a 0a                	cmp    (%edx),%cl
f0101696:	74 eb                	je     f0101683 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101698:	0f b6 00             	movzbl (%eax),%eax
f010169b:	0f b6 12             	movzbl (%edx),%edx
f010169e:	29 d0                	sub    %edx,%eax
f01016a0:	eb 05                	jmp    f01016a7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01016a2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01016a7:	5b                   	pop    %ebx
f01016a8:	5d                   	pop    %ebp
f01016a9:	c3                   	ret    

f01016aa <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01016aa:	55                   	push   %ebp
f01016ab:	89 e5                	mov    %esp,%ebp
f01016ad:	8b 45 08             	mov    0x8(%ebp),%eax
f01016b0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01016b4:	eb 07                	jmp    f01016bd <strchr+0x13>
		if (*s == c)
f01016b6:	38 ca                	cmp    %cl,%dl
f01016b8:	74 0f                	je     f01016c9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01016ba:	83 c0 01             	add    $0x1,%eax
f01016bd:	0f b6 10             	movzbl (%eax),%edx
f01016c0:	84 d2                	test   %dl,%dl
f01016c2:	75 f2                	jne    f01016b6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01016c4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01016c9:	5d                   	pop    %ebp
f01016ca:	c3                   	ret    

f01016cb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01016cb:	55                   	push   %ebp
f01016cc:	89 e5                	mov    %esp,%ebp
f01016ce:	8b 45 08             	mov    0x8(%ebp),%eax
f01016d1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01016d5:	eb 07                	jmp    f01016de <strfind+0x13>
		if (*s == c)
f01016d7:	38 ca                	cmp    %cl,%dl
f01016d9:	74 0a                	je     f01016e5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01016db:	83 c0 01             	add    $0x1,%eax
f01016de:	0f b6 10             	movzbl (%eax),%edx
f01016e1:	84 d2                	test   %dl,%dl
f01016e3:	75 f2                	jne    f01016d7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f01016e5:	5d                   	pop    %ebp
f01016e6:	c3                   	ret    

f01016e7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01016e7:	55                   	push   %ebp
f01016e8:	89 e5                	mov    %esp,%ebp
f01016ea:	57                   	push   %edi
f01016eb:	56                   	push   %esi
f01016ec:	53                   	push   %ebx
f01016ed:	8b 7d 08             	mov    0x8(%ebp),%edi
f01016f0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01016f3:	85 c9                	test   %ecx,%ecx
f01016f5:	74 36                	je     f010172d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01016f7:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01016fd:	75 28                	jne    f0101727 <memset+0x40>
f01016ff:	f6 c1 03             	test   $0x3,%cl
f0101702:	75 23                	jne    f0101727 <memset+0x40>
		c &= 0xFF;
f0101704:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101708:	89 d3                	mov    %edx,%ebx
f010170a:	c1 e3 08             	shl    $0x8,%ebx
f010170d:	89 d6                	mov    %edx,%esi
f010170f:	c1 e6 18             	shl    $0x18,%esi
f0101712:	89 d0                	mov    %edx,%eax
f0101714:	c1 e0 10             	shl    $0x10,%eax
f0101717:	09 f0                	or     %esi,%eax
f0101719:	09 c2                	or     %eax,%edx
f010171b:	89 d0                	mov    %edx,%eax
f010171d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010171f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101722:	fc                   	cld    
f0101723:	f3 ab                	rep stos %eax,%es:(%edi)
f0101725:	eb 06                	jmp    f010172d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101727:	8b 45 0c             	mov    0xc(%ebp),%eax
f010172a:	fc                   	cld    
f010172b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010172d:	89 f8                	mov    %edi,%eax
f010172f:	5b                   	pop    %ebx
f0101730:	5e                   	pop    %esi
f0101731:	5f                   	pop    %edi
f0101732:	5d                   	pop    %ebp
f0101733:	c3                   	ret    

f0101734 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101734:	55                   	push   %ebp
f0101735:	89 e5                	mov    %esp,%ebp
f0101737:	57                   	push   %edi
f0101738:	56                   	push   %esi
f0101739:	8b 45 08             	mov    0x8(%ebp),%eax
f010173c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010173f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101742:	39 c6                	cmp    %eax,%esi
f0101744:	73 35                	jae    f010177b <memmove+0x47>
f0101746:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101749:	39 d0                	cmp    %edx,%eax
f010174b:	73 2e                	jae    f010177b <memmove+0x47>
		s += n;
		d += n;
f010174d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0101750:	89 d6                	mov    %edx,%esi
f0101752:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101754:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010175a:	75 13                	jne    f010176f <memmove+0x3b>
f010175c:	f6 c1 03             	test   $0x3,%cl
f010175f:	75 0e                	jne    f010176f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101761:	83 ef 04             	sub    $0x4,%edi
f0101764:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101767:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010176a:	fd                   	std    
f010176b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010176d:	eb 09                	jmp    f0101778 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010176f:	83 ef 01             	sub    $0x1,%edi
f0101772:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101775:	fd                   	std    
f0101776:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101778:	fc                   	cld    
f0101779:	eb 1d                	jmp    f0101798 <memmove+0x64>
f010177b:	89 f2                	mov    %esi,%edx
f010177d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010177f:	f6 c2 03             	test   $0x3,%dl
f0101782:	75 0f                	jne    f0101793 <memmove+0x5f>
f0101784:	f6 c1 03             	test   $0x3,%cl
f0101787:	75 0a                	jne    f0101793 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101789:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010178c:	89 c7                	mov    %eax,%edi
f010178e:	fc                   	cld    
f010178f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101791:	eb 05                	jmp    f0101798 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101793:	89 c7                	mov    %eax,%edi
f0101795:	fc                   	cld    
f0101796:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101798:	5e                   	pop    %esi
f0101799:	5f                   	pop    %edi
f010179a:	5d                   	pop    %ebp
f010179b:	c3                   	ret    

f010179c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010179c:	55                   	push   %ebp
f010179d:	89 e5                	mov    %esp,%ebp
f010179f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01017a2:	8b 45 10             	mov    0x10(%ebp),%eax
f01017a5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01017a9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01017ac:	89 44 24 04          	mov    %eax,0x4(%esp)
f01017b0:	8b 45 08             	mov    0x8(%ebp),%eax
f01017b3:	89 04 24             	mov    %eax,(%esp)
f01017b6:	e8 79 ff ff ff       	call   f0101734 <memmove>
}
f01017bb:	c9                   	leave  
f01017bc:	c3                   	ret    

f01017bd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01017bd:	55                   	push   %ebp
f01017be:	89 e5                	mov    %esp,%ebp
f01017c0:	56                   	push   %esi
f01017c1:	53                   	push   %ebx
f01017c2:	8b 55 08             	mov    0x8(%ebp),%edx
f01017c5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01017c8:	89 d6                	mov    %edx,%esi
f01017ca:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01017cd:	eb 1a                	jmp    f01017e9 <memcmp+0x2c>
		if (*s1 != *s2)
f01017cf:	0f b6 02             	movzbl (%edx),%eax
f01017d2:	0f b6 19             	movzbl (%ecx),%ebx
f01017d5:	38 d8                	cmp    %bl,%al
f01017d7:	74 0a                	je     f01017e3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01017d9:	0f b6 c0             	movzbl %al,%eax
f01017dc:	0f b6 db             	movzbl %bl,%ebx
f01017df:	29 d8                	sub    %ebx,%eax
f01017e1:	eb 0f                	jmp    f01017f2 <memcmp+0x35>
		s1++, s2++;
f01017e3:	83 c2 01             	add    $0x1,%edx
f01017e6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01017e9:	39 f2                	cmp    %esi,%edx
f01017eb:	75 e2                	jne    f01017cf <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01017ed:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01017f2:	5b                   	pop    %ebx
f01017f3:	5e                   	pop    %esi
f01017f4:	5d                   	pop    %ebp
f01017f5:	c3                   	ret    

f01017f6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01017f6:	55                   	push   %ebp
f01017f7:	89 e5                	mov    %esp,%ebp
f01017f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01017fc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01017ff:	89 c2                	mov    %eax,%edx
f0101801:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101804:	eb 07                	jmp    f010180d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101806:	38 08                	cmp    %cl,(%eax)
f0101808:	74 07                	je     f0101811 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010180a:	83 c0 01             	add    $0x1,%eax
f010180d:	39 d0                	cmp    %edx,%eax
f010180f:	72 f5                	jb     f0101806 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101811:	5d                   	pop    %ebp
f0101812:	c3                   	ret    

f0101813 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101813:	55                   	push   %ebp
f0101814:	89 e5                	mov    %esp,%ebp
f0101816:	57                   	push   %edi
f0101817:	56                   	push   %esi
f0101818:	53                   	push   %ebx
f0101819:	8b 55 08             	mov    0x8(%ebp),%edx
f010181c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010181f:	eb 03                	jmp    f0101824 <strtol+0x11>
		s++;
f0101821:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101824:	0f b6 0a             	movzbl (%edx),%ecx
f0101827:	80 f9 09             	cmp    $0x9,%cl
f010182a:	74 f5                	je     f0101821 <strtol+0xe>
f010182c:	80 f9 20             	cmp    $0x20,%cl
f010182f:	74 f0                	je     f0101821 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101831:	80 f9 2b             	cmp    $0x2b,%cl
f0101834:	75 0a                	jne    f0101840 <strtol+0x2d>
		s++;
f0101836:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101839:	bf 00 00 00 00       	mov    $0x0,%edi
f010183e:	eb 11                	jmp    f0101851 <strtol+0x3e>
f0101840:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101845:	80 f9 2d             	cmp    $0x2d,%cl
f0101848:	75 07                	jne    f0101851 <strtol+0x3e>
		s++, neg = 1;
f010184a:	8d 52 01             	lea    0x1(%edx),%edx
f010184d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101851:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0101856:	75 15                	jne    f010186d <strtol+0x5a>
f0101858:	80 3a 30             	cmpb   $0x30,(%edx)
f010185b:	75 10                	jne    f010186d <strtol+0x5a>
f010185d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101861:	75 0a                	jne    f010186d <strtol+0x5a>
		s += 2, base = 16;
f0101863:	83 c2 02             	add    $0x2,%edx
f0101866:	b8 10 00 00 00       	mov    $0x10,%eax
f010186b:	eb 10                	jmp    f010187d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f010186d:	85 c0                	test   %eax,%eax
f010186f:	75 0c                	jne    f010187d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101871:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101873:	80 3a 30             	cmpb   $0x30,(%edx)
f0101876:	75 05                	jne    f010187d <strtol+0x6a>
		s++, base = 8;
f0101878:	83 c2 01             	add    $0x1,%edx
f010187b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010187d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101882:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101885:	0f b6 0a             	movzbl (%edx),%ecx
f0101888:	8d 71 d0             	lea    -0x30(%ecx),%esi
f010188b:	89 f0                	mov    %esi,%eax
f010188d:	3c 09                	cmp    $0x9,%al
f010188f:	77 08                	ja     f0101899 <strtol+0x86>
			dig = *s - '0';
f0101891:	0f be c9             	movsbl %cl,%ecx
f0101894:	83 e9 30             	sub    $0x30,%ecx
f0101897:	eb 20                	jmp    f01018b9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0101899:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010189c:	89 f0                	mov    %esi,%eax
f010189e:	3c 19                	cmp    $0x19,%al
f01018a0:	77 08                	ja     f01018aa <strtol+0x97>
			dig = *s - 'a' + 10;
f01018a2:	0f be c9             	movsbl %cl,%ecx
f01018a5:	83 e9 57             	sub    $0x57,%ecx
f01018a8:	eb 0f                	jmp    f01018b9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f01018aa:	8d 71 bf             	lea    -0x41(%ecx),%esi
f01018ad:	89 f0                	mov    %esi,%eax
f01018af:	3c 19                	cmp    $0x19,%al
f01018b1:	77 16                	ja     f01018c9 <strtol+0xb6>
			dig = *s - 'A' + 10;
f01018b3:	0f be c9             	movsbl %cl,%ecx
f01018b6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01018b9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f01018bc:	7d 0f                	jge    f01018cd <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f01018be:	83 c2 01             	add    $0x1,%edx
f01018c1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f01018c5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f01018c7:	eb bc                	jmp    f0101885 <strtol+0x72>
f01018c9:	89 d8                	mov    %ebx,%eax
f01018cb:	eb 02                	jmp    f01018cf <strtol+0xbc>
f01018cd:	89 d8                	mov    %ebx,%eax

	if (endptr)
f01018cf:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01018d3:	74 05                	je     f01018da <strtol+0xc7>
		*endptr = (char *) s;
f01018d5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01018d8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f01018da:	f7 d8                	neg    %eax
f01018dc:	85 ff                	test   %edi,%edi
f01018de:	0f 44 c3             	cmove  %ebx,%eax
}
f01018e1:	5b                   	pop    %ebx
f01018e2:	5e                   	pop    %esi
f01018e3:	5f                   	pop    %edi
f01018e4:	5d                   	pop    %ebp
f01018e5:	c3                   	ret    
f01018e6:	66 90                	xchg   %ax,%ax
f01018e8:	66 90                	xchg   %ax,%ax
f01018ea:	66 90                	xchg   %ax,%ax
f01018ec:	66 90                	xchg   %ax,%ax
f01018ee:	66 90                	xchg   %ax,%ax

f01018f0 <__udivdi3>:
f01018f0:	55                   	push   %ebp
f01018f1:	57                   	push   %edi
f01018f2:	56                   	push   %esi
f01018f3:	83 ec 0c             	sub    $0xc,%esp
f01018f6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01018fa:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f01018fe:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0101902:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101906:	85 c0                	test   %eax,%eax
f0101908:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010190c:	89 ea                	mov    %ebp,%edx
f010190e:	89 0c 24             	mov    %ecx,(%esp)
f0101911:	75 2d                	jne    f0101940 <__udivdi3+0x50>
f0101913:	39 e9                	cmp    %ebp,%ecx
f0101915:	77 61                	ja     f0101978 <__udivdi3+0x88>
f0101917:	85 c9                	test   %ecx,%ecx
f0101919:	89 ce                	mov    %ecx,%esi
f010191b:	75 0b                	jne    f0101928 <__udivdi3+0x38>
f010191d:	b8 01 00 00 00       	mov    $0x1,%eax
f0101922:	31 d2                	xor    %edx,%edx
f0101924:	f7 f1                	div    %ecx
f0101926:	89 c6                	mov    %eax,%esi
f0101928:	31 d2                	xor    %edx,%edx
f010192a:	89 e8                	mov    %ebp,%eax
f010192c:	f7 f6                	div    %esi
f010192e:	89 c5                	mov    %eax,%ebp
f0101930:	89 f8                	mov    %edi,%eax
f0101932:	f7 f6                	div    %esi
f0101934:	89 ea                	mov    %ebp,%edx
f0101936:	83 c4 0c             	add    $0xc,%esp
f0101939:	5e                   	pop    %esi
f010193a:	5f                   	pop    %edi
f010193b:	5d                   	pop    %ebp
f010193c:	c3                   	ret    
f010193d:	8d 76 00             	lea    0x0(%esi),%esi
f0101940:	39 e8                	cmp    %ebp,%eax
f0101942:	77 24                	ja     f0101968 <__udivdi3+0x78>
f0101944:	0f bd e8             	bsr    %eax,%ebp
f0101947:	83 f5 1f             	xor    $0x1f,%ebp
f010194a:	75 3c                	jne    f0101988 <__udivdi3+0x98>
f010194c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101950:	39 34 24             	cmp    %esi,(%esp)
f0101953:	0f 86 9f 00 00 00    	jbe    f01019f8 <__udivdi3+0x108>
f0101959:	39 d0                	cmp    %edx,%eax
f010195b:	0f 82 97 00 00 00    	jb     f01019f8 <__udivdi3+0x108>
f0101961:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101968:	31 d2                	xor    %edx,%edx
f010196a:	31 c0                	xor    %eax,%eax
f010196c:	83 c4 0c             	add    $0xc,%esp
f010196f:	5e                   	pop    %esi
f0101970:	5f                   	pop    %edi
f0101971:	5d                   	pop    %ebp
f0101972:	c3                   	ret    
f0101973:	90                   	nop
f0101974:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101978:	89 f8                	mov    %edi,%eax
f010197a:	f7 f1                	div    %ecx
f010197c:	31 d2                	xor    %edx,%edx
f010197e:	83 c4 0c             	add    $0xc,%esp
f0101981:	5e                   	pop    %esi
f0101982:	5f                   	pop    %edi
f0101983:	5d                   	pop    %ebp
f0101984:	c3                   	ret    
f0101985:	8d 76 00             	lea    0x0(%esi),%esi
f0101988:	89 e9                	mov    %ebp,%ecx
f010198a:	8b 3c 24             	mov    (%esp),%edi
f010198d:	d3 e0                	shl    %cl,%eax
f010198f:	89 c6                	mov    %eax,%esi
f0101991:	b8 20 00 00 00       	mov    $0x20,%eax
f0101996:	29 e8                	sub    %ebp,%eax
f0101998:	89 c1                	mov    %eax,%ecx
f010199a:	d3 ef                	shr    %cl,%edi
f010199c:	89 e9                	mov    %ebp,%ecx
f010199e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01019a2:	8b 3c 24             	mov    (%esp),%edi
f01019a5:	09 74 24 08          	or     %esi,0x8(%esp)
f01019a9:	89 d6                	mov    %edx,%esi
f01019ab:	d3 e7                	shl    %cl,%edi
f01019ad:	89 c1                	mov    %eax,%ecx
f01019af:	89 3c 24             	mov    %edi,(%esp)
f01019b2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01019b6:	d3 ee                	shr    %cl,%esi
f01019b8:	89 e9                	mov    %ebp,%ecx
f01019ba:	d3 e2                	shl    %cl,%edx
f01019bc:	89 c1                	mov    %eax,%ecx
f01019be:	d3 ef                	shr    %cl,%edi
f01019c0:	09 d7                	or     %edx,%edi
f01019c2:	89 f2                	mov    %esi,%edx
f01019c4:	89 f8                	mov    %edi,%eax
f01019c6:	f7 74 24 08          	divl   0x8(%esp)
f01019ca:	89 d6                	mov    %edx,%esi
f01019cc:	89 c7                	mov    %eax,%edi
f01019ce:	f7 24 24             	mull   (%esp)
f01019d1:	39 d6                	cmp    %edx,%esi
f01019d3:	89 14 24             	mov    %edx,(%esp)
f01019d6:	72 30                	jb     f0101a08 <__udivdi3+0x118>
f01019d8:	8b 54 24 04          	mov    0x4(%esp),%edx
f01019dc:	89 e9                	mov    %ebp,%ecx
f01019de:	d3 e2                	shl    %cl,%edx
f01019e0:	39 c2                	cmp    %eax,%edx
f01019e2:	73 05                	jae    f01019e9 <__udivdi3+0xf9>
f01019e4:	3b 34 24             	cmp    (%esp),%esi
f01019e7:	74 1f                	je     f0101a08 <__udivdi3+0x118>
f01019e9:	89 f8                	mov    %edi,%eax
f01019eb:	31 d2                	xor    %edx,%edx
f01019ed:	e9 7a ff ff ff       	jmp    f010196c <__udivdi3+0x7c>
f01019f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01019f8:	31 d2                	xor    %edx,%edx
f01019fa:	b8 01 00 00 00       	mov    $0x1,%eax
f01019ff:	e9 68 ff ff ff       	jmp    f010196c <__udivdi3+0x7c>
f0101a04:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a08:	8d 47 ff             	lea    -0x1(%edi),%eax
f0101a0b:	31 d2                	xor    %edx,%edx
f0101a0d:	83 c4 0c             	add    $0xc,%esp
f0101a10:	5e                   	pop    %esi
f0101a11:	5f                   	pop    %edi
f0101a12:	5d                   	pop    %ebp
f0101a13:	c3                   	ret    
f0101a14:	66 90                	xchg   %ax,%ax
f0101a16:	66 90                	xchg   %ax,%ax
f0101a18:	66 90                	xchg   %ax,%ax
f0101a1a:	66 90                	xchg   %ax,%ax
f0101a1c:	66 90                	xchg   %ax,%ax
f0101a1e:	66 90                	xchg   %ax,%ax

f0101a20 <__umoddi3>:
f0101a20:	55                   	push   %ebp
f0101a21:	57                   	push   %edi
f0101a22:	56                   	push   %esi
f0101a23:	83 ec 14             	sub    $0x14,%esp
f0101a26:	8b 44 24 28          	mov    0x28(%esp),%eax
f0101a2a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101a2e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0101a32:	89 c7                	mov    %eax,%edi
f0101a34:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a38:	8b 44 24 30          	mov    0x30(%esp),%eax
f0101a3c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101a40:	89 34 24             	mov    %esi,(%esp)
f0101a43:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101a47:	85 c0                	test   %eax,%eax
f0101a49:	89 c2                	mov    %eax,%edx
f0101a4b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101a4f:	75 17                	jne    f0101a68 <__umoddi3+0x48>
f0101a51:	39 fe                	cmp    %edi,%esi
f0101a53:	76 4b                	jbe    f0101aa0 <__umoddi3+0x80>
f0101a55:	89 c8                	mov    %ecx,%eax
f0101a57:	89 fa                	mov    %edi,%edx
f0101a59:	f7 f6                	div    %esi
f0101a5b:	89 d0                	mov    %edx,%eax
f0101a5d:	31 d2                	xor    %edx,%edx
f0101a5f:	83 c4 14             	add    $0x14,%esp
f0101a62:	5e                   	pop    %esi
f0101a63:	5f                   	pop    %edi
f0101a64:	5d                   	pop    %ebp
f0101a65:	c3                   	ret    
f0101a66:	66 90                	xchg   %ax,%ax
f0101a68:	39 f8                	cmp    %edi,%eax
f0101a6a:	77 54                	ja     f0101ac0 <__umoddi3+0xa0>
f0101a6c:	0f bd e8             	bsr    %eax,%ebp
f0101a6f:	83 f5 1f             	xor    $0x1f,%ebp
f0101a72:	75 5c                	jne    f0101ad0 <__umoddi3+0xb0>
f0101a74:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101a78:	39 3c 24             	cmp    %edi,(%esp)
f0101a7b:	0f 87 e7 00 00 00    	ja     f0101b68 <__umoddi3+0x148>
f0101a81:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101a85:	29 f1                	sub    %esi,%ecx
f0101a87:	19 c7                	sbb    %eax,%edi
f0101a89:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101a8d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101a91:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101a95:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101a99:	83 c4 14             	add    $0x14,%esp
f0101a9c:	5e                   	pop    %esi
f0101a9d:	5f                   	pop    %edi
f0101a9e:	5d                   	pop    %ebp
f0101a9f:	c3                   	ret    
f0101aa0:	85 f6                	test   %esi,%esi
f0101aa2:	89 f5                	mov    %esi,%ebp
f0101aa4:	75 0b                	jne    f0101ab1 <__umoddi3+0x91>
f0101aa6:	b8 01 00 00 00       	mov    $0x1,%eax
f0101aab:	31 d2                	xor    %edx,%edx
f0101aad:	f7 f6                	div    %esi
f0101aaf:	89 c5                	mov    %eax,%ebp
f0101ab1:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101ab5:	31 d2                	xor    %edx,%edx
f0101ab7:	f7 f5                	div    %ebp
f0101ab9:	89 c8                	mov    %ecx,%eax
f0101abb:	f7 f5                	div    %ebp
f0101abd:	eb 9c                	jmp    f0101a5b <__umoddi3+0x3b>
f0101abf:	90                   	nop
f0101ac0:	89 c8                	mov    %ecx,%eax
f0101ac2:	89 fa                	mov    %edi,%edx
f0101ac4:	83 c4 14             	add    $0x14,%esp
f0101ac7:	5e                   	pop    %esi
f0101ac8:	5f                   	pop    %edi
f0101ac9:	5d                   	pop    %ebp
f0101aca:	c3                   	ret    
f0101acb:	90                   	nop
f0101acc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101ad0:	8b 04 24             	mov    (%esp),%eax
f0101ad3:	be 20 00 00 00       	mov    $0x20,%esi
f0101ad8:	89 e9                	mov    %ebp,%ecx
f0101ada:	29 ee                	sub    %ebp,%esi
f0101adc:	d3 e2                	shl    %cl,%edx
f0101ade:	89 f1                	mov    %esi,%ecx
f0101ae0:	d3 e8                	shr    %cl,%eax
f0101ae2:	89 e9                	mov    %ebp,%ecx
f0101ae4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101ae8:	8b 04 24             	mov    (%esp),%eax
f0101aeb:	09 54 24 04          	or     %edx,0x4(%esp)
f0101aef:	89 fa                	mov    %edi,%edx
f0101af1:	d3 e0                	shl    %cl,%eax
f0101af3:	89 f1                	mov    %esi,%ecx
f0101af5:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101af9:	8b 44 24 10          	mov    0x10(%esp),%eax
f0101afd:	d3 ea                	shr    %cl,%edx
f0101aff:	89 e9                	mov    %ebp,%ecx
f0101b01:	d3 e7                	shl    %cl,%edi
f0101b03:	89 f1                	mov    %esi,%ecx
f0101b05:	d3 e8                	shr    %cl,%eax
f0101b07:	89 e9                	mov    %ebp,%ecx
f0101b09:	09 f8                	or     %edi,%eax
f0101b0b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0101b0f:	f7 74 24 04          	divl   0x4(%esp)
f0101b13:	d3 e7                	shl    %cl,%edi
f0101b15:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101b19:	89 d7                	mov    %edx,%edi
f0101b1b:	f7 64 24 08          	mull   0x8(%esp)
f0101b1f:	39 d7                	cmp    %edx,%edi
f0101b21:	89 c1                	mov    %eax,%ecx
f0101b23:	89 14 24             	mov    %edx,(%esp)
f0101b26:	72 2c                	jb     f0101b54 <__umoddi3+0x134>
f0101b28:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0101b2c:	72 22                	jb     f0101b50 <__umoddi3+0x130>
f0101b2e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101b32:	29 c8                	sub    %ecx,%eax
f0101b34:	19 d7                	sbb    %edx,%edi
f0101b36:	89 e9                	mov    %ebp,%ecx
f0101b38:	89 fa                	mov    %edi,%edx
f0101b3a:	d3 e8                	shr    %cl,%eax
f0101b3c:	89 f1                	mov    %esi,%ecx
f0101b3e:	d3 e2                	shl    %cl,%edx
f0101b40:	89 e9                	mov    %ebp,%ecx
f0101b42:	d3 ef                	shr    %cl,%edi
f0101b44:	09 d0                	or     %edx,%eax
f0101b46:	89 fa                	mov    %edi,%edx
f0101b48:	83 c4 14             	add    $0x14,%esp
f0101b4b:	5e                   	pop    %esi
f0101b4c:	5f                   	pop    %edi
f0101b4d:	5d                   	pop    %ebp
f0101b4e:	c3                   	ret    
f0101b4f:	90                   	nop
f0101b50:	39 d7                	cmp    %edx,%edi
f0101b52:	75 da                	jne    f0101b2e <__umoddi3+0x10e>
f0101b54:	8b 14 24             	mov    (%esp),%edx
f0101b57:	89 c1                	mov    %eax,%ecx
f0101b59:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0101b5d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0101b61:	eb cb                	jmp    f0101b2e <__umoddi3+0x10e>
f0101b63:	90                   	nop
f0101b64:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101b68:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0101b6c:	0f 82 0f ff ff ff    	jb     f0101a81 <__umoddi3+0x61>
f0101b72:	e9 1a ff ff ff       	jmp    f0101a91 <__umoddi3+0x71>
