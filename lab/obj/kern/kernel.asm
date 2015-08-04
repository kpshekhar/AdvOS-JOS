
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
f0100015:	b8 00 60 11 00       	mov    $0x116000,%eax
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
f0100034:	bc 00 60 11 f0       	mov    $0xf0116000,%esp

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
f010004e:	c7 04 24 c0 3f 10 f0 	movl   $0xf0103fc0,(%esp)
f0100055:	e8 68 2f 00 00       	call   f0102fc2 <cprintf>
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
f010008b:	c7 04 24 dc 3f 10 f0 	movl   $0xf0103fdc,(%esp)
f0100092:	e8 2b 2f 00 00       	call   f0102fc2 <cprintf>
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
f01000a3:	b8 70 89 11 f0       	mov    $0xf0118970,%eax
f01000a8:	2d 00 83 11 f0       	sub    $0xf0118300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 83 11 f0 	movl   $0xf0118300,(%esp)
f01000c0:	e8 62 3a 00 00       	call   f0103b27 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 c5 04 00 00       	call   f010058f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 f7 3f 10 f0 	movl   $0xf0103ff7,(%esp)
f01000d9:	e8 e4 2e 00 00       	call   f0102fc2 <cprintf>
	mem_init();
f01000de:	e8 f0 12 00 00       	call   f01013d3 <mem_init>

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
f0100107:	c7 04 24 12 40 10 f0 	movl   $0xf0104012,(%esp)
f010010e:	e8 af 2e 00 00       	call   f0102fc2 <cprintf>
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
f010012c:	83 3d 60 89 11 f0 00 	cmpl   $0x0,0xf0118960
f0100133:	75 3d                	jne    f0100172 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f0100135:	89 35 60 89 11 f0    	mov    %esi,0xf0118960

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
f010014e:	c7 04 24 24 40 10 f0 	movl   $0xf0104024,(%esp)
f0100155:	e8 68 2e 00 00       	call   f0102fc2 <cprintf>
	vcprintf(fmt, ap);
f010015a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010015e:	89 34 24             	mov    %esi,(%esp)
f0100161:	e8 29 2e 00 00       	call   f0102f8f <vcprintf>
	cprintf("\n");
f0100166:	c7 04 24 6f 50 10 f0 	movl   $0xf010506f,(%esp)
f010016d:	e8 50 2e 00 00       	call   f0102fc2 <cprintf>
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
f0100198:	c7 04 24 3c 40 10 f0 	movl   $0xf010403c,(%esp)
f010019f:	e8 1e 2e 00 00       	call   f0102fc2 <cprintf>
	vcprintf(fmt, ap);
f01001a4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01001a8:	8b 45 10             	mov    0x10(%ebp),%eax
f01001ab:	89 04 24             	mov    %eax,(%esp)
f01001ae:	e8 dc 2d 00 00       	call   f0102f8f <vcprintf>
	cprintf("\n");
f01001b3:	c7 04 24 6f 50 10 f0 	movl   $0xf010506f,(%esp)
f01001ba:	e8 03 2e 00 00       	call   f0102fc2 <cprintf>
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
f01001fb:	a1 24 85 11 f0       	mov    0xf0118524,%eax
f0100200:	8d 48 01             	lea    0x1(%eax),%ecx
f0100203:	89 0d 24 85 11 f0    	mov    %ecx,0xf0118524
f0100209:	88 90 20 83 11 f0    	mov    %dl,-0xfee7ce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010020f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100215:	75 0a                	jne    f0100221 <cons_intr+0x35>
			cons.wpos = 0;
f0100217:	c7 05 24 85 11 f0 00 	movl   $0x0,0xf0118524
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
f0100247:	83 0d 00 83 11 f0 40 	orl    $0x40,0xf0118300
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
f010025f:	8b 0d 00 83 11 f0    	mov    0xf0118300,%ecx
f0100265:	89 cb                	mov    %ecx,%ebx
f0100267:	83 e3 40             	and    $0x40,%ebx
f010026a:	83 e0 7f             	and    $0x7f,%eax
f010026d:	85 db                	test   %ebx,%ebx
f010026f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100272:	0f b6 d2             	movzbl %dl,%edx
f0100275:	0f b6 82 a0 41 10 f0 	movzbl -0xfefbe60(%edx),%eax
f010027c:	83 c8 40             	or     $0x40,%eax
f010027f:	0f b6 c0             	movzbl %al,%eax
f0100282:	f7 d0                	not    %eax
f0100284:	21 c1                	and    %eax,%ecx
f0100286:	89 0d 00 83 11 f0    	mov    %ecx,0xf0118300
		return 0;
f010028c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100291:	e9 9d 00 00 00       	jmp    f0100333 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100296:	8b 0d 00 83 11 f0    	mov    0xf0118300,%ecx
f010029c:	f6 c1 40             	test   $0x40,%cl
f010029f:	74 0e                	je     f01002af <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01002a1:	83 c8 80             	or     $0xffffff80,%eax
f01002a4:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01002a6:	83 e1 bf             	and    $0xffffffbf,%ecx
f01002a9:	89 0d 00 83 11 f0    	mov    %ecx,0xf0118300
	}

	shift |= shiftcode[data];
f01002af:	0f b6 d2             	movzbl %dl,%edx
f01002b2:	0f b6 82 a0 41 10 f0 	movzbl -0xfefbe60(%edx),%eax
f01002b9:	0b 05 00 83 11 f0    	or     0xf0118300,%eax
	shift ^= togglecode[data];
f01002bf:	0f b6 8a a0 40 10 f0 	movzbl -0xfefbf60(%edx),%ecx
f01002c6:	31 c8                	xor    %ecx,%eax
f01002c8:	a3 00 83 11 f0       	mov    %eax,0xf0118300

	c = charcode[shift & (CTL | SHIFT)][data];
f01002cd:	89 c1                	mov    %eax,%ecx
f01002cf:	83 e1 03             	and    $0x3,%ecx
f01002d2:	8b 0c 8d 80 40 10 f0 	mov    -0xfefbf80(,%ecx,4),%ecx
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
f0100312:	c7 04 24 56 40 10 f0 	movl   $0xf0104056,(%esp)
f0100319:	e8 a4 2c 00 00       	call   f0102fc2 <cprintf>
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
f01003ec:	0f b7 05 28 85 11 f0 	movzwl 0xf0118528,%eax
f01003f3:	66 85 c0             	test   %ax,%ax
f01003f6:	0f 84 e5 00 00 00    	je     f01004e1 <cons_putc+0x1a8>
			crt_pos--;
f01003fc:	83 e8 01             	sub    $0x1,%eax
f01003ff:	66 a3 28 85 11 f0    	mov    %ax,0xf0118528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100405:	0f b7 c0             	movzwl %ax,%eax
f0100408:	66 81 e7 00 ff       	and    $0xff00,%di
f010040d:	83 cf 20             	or     $0x20,%edi
f0100410:	8b 15 2c 85 11 f0    	mov    0xf011852c,%edx
f0100416:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010041a:	eb 78                	jmp    f0100494 <cons_putc+0x15b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010041c:	66 83 05 28 85 11 f0 	addw   $0x50,0xf0118528
f0100423:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100424:	0f b7 05 28 85 11 f0 	movzwl 0xf0118528,%eax
f010042b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100431:	c1 e8 16             	shr    $0x16,%eax
f0100434:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100437:	c1 e0 04             	shl    $0x4,%eax
f010043a:	66 a3 28 85 11 f0    	mov    %ax,0xf0118528
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
f0100476:	0f b7 05 28 85 11 f0 	movzwl 0xf0118528,%eax
f010047d:	8d 50 01             	lea    0x1(%eax),%edx
f0100480:	66 89 15 28 85 11 f0 	mov    %dx,0xf0118528
f0100487:	0f b7 c0             	movzwl %ax,%eax
f010048a:	8b 15 2c 85 11 f0    	mov    0xf011852c,%edx
f0100490:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100494:	66 81 3d 28 85 11 f0 	cmpw   $0x7cf,0xf0118528
f010049b:	cf 07 
f010049d:	76 42                	jbe    f01004e1 <cons_putc+0x1a8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010049f:	a1 2c 85 11 f0       	mov    0xf011852c,%eax
f01004a4:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f01004ab:	00 
f01004ac:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004b2:	89 54 24 04          	mov    %edx,0x4(%esp)
f01004b6:	89 04 24             	mov    %eax,(%esp)
f01004b9:	e8 b6 36 00 00       	call   f0103b74 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01004be:	8b 15 2c 85 11 f0    	mov    0xf011852c,%edx
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
f01004d9:	66 83 2d 28 85 11 f0 	subw   $0x50,0xf0118528
f01004e0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004e1:	8b 0d 30 85 11 f0    	mov    0xf0118530,%ecx
f01004e7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004ec:	89 ca                	mov    %ecx,%edx
f01004ee:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004ef:	0f b7 1d 28 85 11 f0 	movzwl 0xf0118528,%ebx
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
f0100517:	80 3d 34 85 11 f0 00 	cmpb   $0x0,0xf0118534
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
f0100555:	a1 20 85 11 f0       	mov    0xf0118520,%eax
f010055a:	3b 05 24 85 11 f0    	cmp    0xf0118524,%eax
f0100560:	74 26                	je     f0100588 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100562:	8d 50 01             	lea    0x1(%eax),%edx
f0100565:	89 15 20 85 11 f0    	mov    %edx,0xf0118520
f010056b:	0f b6 88 20 83 11 f0 	movzbl -0xfee7ce0(%eax),%ecx
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
f010057c:	c7 05 20 85 11 f0 00 	movl   $0x0,0xf0118520
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
f01005b5:	c7 05 30 85 11 f0 b4 	movl   $0x3b4,0xf0118530
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
f01005cd:	c7 05 30 85 11 f0 d4 	movl   $0x3d4,0xf0118530
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
f01005dc:	8b 0d 30 85 11 f0    	mov    0xf0118530,%ecx
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
f0100601:	89 3d 2c 85 11 f0    	mov    %edi,0xf011852c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100607:	0f b6 d8             	movzbl %al,%ebx
f010060a:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f010060c:	66 89 35 28 85 11 f0 	mov    %si,0xf0118528
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
f010065d:	88 0d 34 85 11 f0    	mov    %cl,0xf0118534
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
f010066d:	c7 04 24 62 40 10 f0 	movl   $0xf0104062,(%esp)
f0100674:	e8 49 29 00 00       	call   f0102fc2 <cprintf>
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
f01006b6:	c7 44 24 08 a0 42 10 	movl   $0xf01042a0,0x8(%esp)
f01006bd:	f0 
f01006be:	c7 44 24 04 be 42 10 	movl   $0xf01042be,0x4(%esp)
f01006c5:	f0 
f01006c6:	c7 04 24 c3 42 10 f0 	movl   $0xf01042c3,(%esp)
f01006cd:	e8 f0 28 00 00       	call   f0102fc2 <cprintf>
f01006d2:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f01006d9:	f0 
f01006da:	c7 44 24 04 cc 42 10 	movl   $0xf01042cc,0x4(%esp)
f01006e1:	f0 
f01006e2:	c7 04 24 c3 42 10 f0 	movl   $0xf01042c3,(%esp)
f01006e9:	e8 d4 28 00 00       	call   f0102fc2 <cprintf>
f01006ee:	c7 44 24 08 d5 42 10 	movl   $0xf01042d5,0x8(%esp)
f01006f5:	f0 
f01006f6:	c7 44 24 04 f2 42 10 	movl   $0xf01042f2,0x4(%esp)
f01006fd:	f0 
f01006fe:	c7 04 24 c3 42 10 f0 	movl   $0xf01042c3,(%esp)
f0100705:	e8 b8 28 00 00       	call   f0102fc2 <cprintf>
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
f0100717:	c7 04 24 fd 42 10 f0 	movl   $0xf01042fd,(%esp)
f010071e:	e8 9f 28 00 00       	call   f0102fc2 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100723:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010072a:	00 
f010072b:	c7 04 24 8c 43 10 f0 	movl   $0xf010438c,(%esp)
f0100732:	e8 8b 28 00 00       	call   f0102fc2 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100737:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010073e:	00 
f010073f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100746:	f0 
f0100747:	c7 04 24 b4 43 10 f0 	movl   $0xf01043b4,(%esp)
f010074e:	e8 6f 28 00 00       	call   f0102fc2 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100753:	c7 44 24 08 b7 3f 10 	movl   $0x103fb7,0x8(%esp)
f010075a:	00 
f010075b:	c7 44 24 04 b7 3f 10 	movl   $0xf0103fb7,0x4(%esp)
f0100762:	f0 
f0100763:	c7 04 24 d8 43 10 f0 	movl   $0xf01043d8,(%esp)
f010076a:	e8 53 28 00 00       	call   f0102fc2 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010076f:	c7 44 24 08 00 83 11 	movl   $0x118300,0x8(%esp)
f0100776:	00 
f0100777:	c7 44 24 04 00 83 11 	movl   $0xf0118300,0x4(%esp)
f010077e:	f0 
f010077f:	c7 04 24 fc 43 10 f0 	movl   $0xf01043fc,(%esp)
f0100786:	e8 37 28 00 00       	call   f0102fc2 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010078b:	c7 44 24 08 70 89 11 	movl   $0x118970,0x8(%esp)
f0100792:	00 
f0100793:	c7 44 24 04 70 89 11 	movl   $0xf0118970,0x4(%esp)
f010079a:	f0 
f010079b:	c7 04 24 20 44 10 f0 	movl   $0xf0104420,(%esp)
f01007a2:	e8 1b 28 00 00       	call   f0102fc2 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01007a7:	b8 6f 8d 11 f0       	mov    $0xf0118d6f,%eax
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
f01007c8:	c7 04 24 44 44 10 f0 	movl   $0xf0104444,(%esp)
f01007cf:	e8 ee 27 00 00       	call   f0102fc2 <cprintf>
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
f01007e6:	c7 04 24 16 43 10 f0 	movl   $0xf0104316,(%esp)
f01007ed:	e8 d0 27 00 00       	call   f0102fc2 <cprintf>
	
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
f0100801:	e8 b3 28 00 00       	call   f01030b9 <debuginfo_eip>
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
f0100856:	c7 04 24 70 44 10 f0 	movl   $0xf0104470,(%esp)
f010085d:	e8 60 27 00 00       	call   f0102fc2 <cprintf>
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
f010087e:	c7 04 24 b4 44 10 f0 	movl   $0xf01044b4,(%esp)
f0100885:	e8 38 27 00 00       	call   f0102fc2 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010088a:	c7 04 24 d8 44 10 f0 	movl   $0xf01044d8,(%esp)
f0100891:	e8 2c 27 00 00       	call   f0102fc2 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100896:	c7 04 24 28 43 10 f0 	movl   $0xf0104328,(%esp)
f010089d:	e8 2e 30 00 00       	call   f01038d0 <readline>
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
f01008ce:	c7 04 24 2c 43 10 f0 	movl   $0xf010432c,(%esp)
f01008d5:	e8 10 32 00 00       	call   f0103aea <strchr>
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
f01008f0:	c7 04 24 31 43 10 f0 	movl   $0xf0104331,(%esp)
f01008f7:	e8 c6 26 00 00       	call   f0102fc2 <cprintf>
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
f0100918:	c7 04 24 2c 43 10 f0 	movl   $0xf010432c,(%esp)
f010091f:	e8 c6 31 00 00       	call   f0103aea <strchr>
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
f0100942:	8b 04 85 00 45 10 f0 	mov    -0xfefbb00(,%eax,4),%eax
f0100949:	89 44 24 04          	mov    %eax,0x4(%esp)
f010094d:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100950:	89 04 24             	mov    %eax,(%esp)
f0100953:	e8 34 31 00 00       	call   f0103a8c <strcmp>
f0100958:	85 c0                	test   %eax,%eax
f010095a:	75 24                	jne    f0100980 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f010095c:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010095f:	8b 55 08             	mov    0x8(%ebp),%edx
f0100962:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100966:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100969:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010096d:	89 34 24             	mov    %esi,(%esp)
f0100970:	ff 14 85 08 45 10 f0 	call   *-0xfefbaf8(,%eax,4)


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
f010098f:	c7 04 24 4e 43 10 f0 	movl   $0xf010434e,(%esp)
f0100996:	e8 27 26 00 00       	call   f0102fc2 <cprintf>
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
f01009a8:	66 90                	xchg   %ax,%ax
f01009aa:	66 90                	xchg   %ax,%ax
f01009ac:	66 90                	xchg   %ax,%ax
f01009ae:	66 90                	xchg   %ax,%ax

f01009b0 <page2kva>:

//page2pa returns the relevant physical address of the page
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01009b0:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f01009b6:	c1 f8 03             	sar    $0x3,%eax
f01009b9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009bc:	89 c2                	mov    %eax,%edx
f01009be:	c1 ea 0c             	shr    $0xc,%edx
f01009c1:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f01009c7:	72 26                	jb     f01009ef <page2kva+0x3f>
}

//This function returns the virtual address of the page.
static inline void*
page2kva(struct PageInfo *pp)
{
f01009c9:	55                   	push   %ebp
f01009ca:	89 e5                	mov    %esp,%ebp
f01009cc:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009cf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009d3:	c7 44 24 08 24 45 10 	movl   $0xf0104524,0x8(%esp)
f01009da:	f0 
f01009db:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01009e2:	00 
f01009e3:	c7 04 24 90 4d 10 f0 	movl   $0xf0104d90,(%esp)
f01009ea:	e8 32 f7 ff ff       	call   f0100121 <_panic>
	return (void *)(pa + KERNBASE);
f01009ef:	2d 00 00 00 10       	sub    $0x10000000,%eax
//This function returns the virtual address of the page.
static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));
}
f01009f4:	c3                   	ret    

f01009f5 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f01009f5:	89 d1                	mov    %edx,%ecx
f01009f7:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f01009fa:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f01009fd:	a8 01                	test   $0x1,%al
f01009ff:	74 5d                	je     f0100a5e <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a01:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a06:	89 c1                	mov    %eax,%ecx
f0100a08:	c1 e9 0c             	shr    $0xc,%ecx
f0100a0b:	3b 0d 64 89 11 f0    	cmp    0xf0118964,%ecx
f0100a11:	72 26                	jb     f0100a39 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a13:	55                   	push   %ebp
f0100a14:	89 e5                	mov    %esp,%ebp
f0100a16:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a19:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a1d:	c7 44 24 08 24 45 10 	movl   $0xf0104524,0x8(%esp)
f0100a24:	f0 
f0100a25:	c7 44 24 04 36 03 00 	movl   $0x336,0x4(%esp)
f0100a2c:	00 
f0100a2d:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0100a34:	e8 e8 f6 ff ff       	call   f0100121 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100a39:	c1 ea 0c             	shr    $0xc,%edx
f0100a3c:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a42:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a49:	89 c2                	mov    %eax,%edx
f0100a4b:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a4e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a53:	85 d2                	test   %edx,%edx
f0100a55:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a5a:	0f 44 c2             	cmove  %edx,%eax
f0100a5d:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100a5e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100a63:	c3                   	ret    

f0100a64 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100a64:	83 3d 3c 85 11 f0 00 	cmpl   $0x0,0xf011853c
f0100a6b:	75 11                	jne    f0100a7e <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE); // Roundup function rounds according to the given functions
f0100a6d:	ba 6f 99 11 f0       	mov    $0xf011996f,%edx
f0100a72:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a78:	89 15 3c 85 11 f0    	mov    %edx,0xf011853c
	}
	
	if (n==0){
f0100a7e:	85 c0                	test   %eax,%eax
f0100a80:	75 06                	jne    f0100a88 <boot_alloc+0x24>
	return nextfree;
f0100a82:	a1 3c 85 11 f0       	mov    0xf011853c,%eax
f0100a87:	c3                   	ret    
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result  = nextfree;
f0100a88:	8b 0d 3c 85 11 f0    	mov    0xf011853c,%ecx
	nextfree += ROUNDUP(n,PGSIZE);
f0100a8e:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100a94:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a9a:	01 ca                	add    %ecx,%edx
f0100a9c:	89 15 3c 85 11 f0    	mov    %edx,0xf011853c
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100aa2:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0100aa8:	77 26                	ja     f0100ad0 <boot_alloc+0x6c>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100aaa:	55                   	push   %ebp
f0100aab:	89 e5                	mov    %esp,%ebp
f0100aad:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100ab0:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100ab4:	c7 44 24 08 48 45 10 	movl   $0xf0104548,0x8(%esp)
f0100abb:	f0 
f0100abc:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
f0100ac3:	00 
f0100ac4:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0100acb:	e8 51 f6 ff ff       	call   f0100121 <_panic>
	// LAB 2: Your code here.
	result  = nextfree;
	nextfree += ROUNDUP(n,PGSIZE);
	
	
	if ((PADDR(nextfree))>npages*PGSIZE){
f0100ad0:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f0100ad5:	c1 e0 0c             	shl    $0xc,%eax
	return (physaddr_t)kva - KERNBASE;
f0100ad8:	81 c2 00 00 00 10    	add    $0x10000000,%edx
		return 0;
f0100ade:	39 c2                	cmp    %eax,%edx
f0100ae0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ae5:	0f 46 c1             	cmovbe %ecx,%eax
	}
	return result;
}
f0100ae8:	c3                   	ret    

f0100ae9 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100ae9:	55                   	push   %ebp
f0100aea:	89 e5                	mov    %esp,%ebp
f0100aec:	57                   	push   %edi
f0100aed:	56                   	push   %esi
f0100aee:	53                   	push   %ebx
f0100aef:	83 ec 4c             	sub    $0x4c,%esp
f0100af2:	89 45 c0             	mov    %eax,-0x40(%ebp)
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100af5:	84 c0                	test   %al,%al
f0100af7:	0f 85 1d 03 00 00    	jne    f0100e1a <check_page_free_list+0x331>
f0100afd:	e9 2a 03 00 00       	jmp    f0100e2c <check_page_free_list+0x343>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100b02:	c7 44 24 08 6c 45 10 	movl   $0xf010456c,0x8(%esp)
f0100b09:	f0 
f0100b0a:	c7 44 24 04 78 02 00 	movl   $0x278,0x4(%esp)
f0100b11:	00 
f0100b12:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0100b19:	e8 03 f6 ff ff       	call   f0100121 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100b1e:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100b21:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100b24:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b27:	89 55 e4             	mov    %edx,-0x1c(%ebp)

//page2pa returns the relevant physical address of the page
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b2a:	89 c2                	mov    %eax,%edx
f0100b2c:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100b32:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100b38:	0f 95 c2             	setne  %dl
f0100b3b:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100b3e:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100b42:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100b44:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b48:	8b 00                	mov    (%eax),%eax
f0100b4a:	85 c0                	test   %eax,%eax
f0100b4c:	75 dc                	jne    f0100b2a <check_page_free_list+0x41>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100b4e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b51:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100b57:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b5a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100b5d:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100b5f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100b62:	a3 40 85 11 f0       	mov    %eax,0xf0118540
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b67:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b6c:	8b 1d 40 85 11 f0    	mov    0xf0118540,%ebx
f0100b72:	eb 63                	jmp    f0100bd7 <check_page_free_list+0xee>
f0100b74:	89 d8                	mov    %ebx,%eax
f0100b76:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0100b7c:	c1 f8 03             	sar    $0x3,%eax
f0100b7f:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b82:	89 c2                	mov    %eax,%edx
f0100b84:	c1 ea 16             	shr    $0x16,%edx
f0100b87:	39 f2                	cmp    %esi,%edx
f0100b89:	73 4a                	jae    f0100bd5 <check_page_free_list+0xec>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b8b:	89 c2                	mov    %eax,%edx
f0100b8d:	c1 ea 0c             	shr    $0xc,%edx
f0100b90:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0100b96:	72 20                	jb     f0100bb8 <check_page_free_list+0xcf>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b98:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b9c:	c7 44 24 08 24 45 10 	movl   $0xf0104524,0x8(%esp)
f0100ba3:	f0 
f0100ba4:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100bab:	00 
f0100bac:	c7 04 24 90 4d 10 f0 	movl   $0xf0104d90,(%esp)
f0100bb3:	e8 69 f5 ff ff       	call   f0100121 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100bb8:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100bbf:	00 
f0100bc0:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100bc7:	00 
	return (void *)(pa + KERNBASE);
f0100bc8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bcd:	89 04 24             	mov    %eax,(%esp)
f0100bd0:	e8 52 2f 00 00       	call   f0103b27 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bd5:	8b 1b                	mov    (%ebx),%ebx
f0100bd7:	85 db                	test   %ebx,%ebx
f0100bd9:	75 99                	jne    f0100b74 <check_page_free_list+0x8b>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100bdb:	b8 00 00 00 00       	mov    $0x0,%eax
f0100be0:	e8 7f fe ff ff       	call   f0100a64 <boot_alloc>
f0100be5:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100be8:	8b 15 40 85 11 f0    	mov    0xf0118540,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bee:	8b 0d 6c 89 11 f0    	mov    0xf011896c,%ecx
		assert(pp < pages + npages);
f0100bf4:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f0100bf9:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100bfc:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100bff:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c02:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c05:	bf 00 00 00 00       	mov    $0x0,%edi
f0100c0a:	89 5d cc             	mov    %ebx,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c0d:	e9 97 01 00 00       	jmp    f0100da9 <check_page_free_list+0x2c0>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c12:	39 ca                	cmp    %ecx,%edx
f0100c14:	73 24                	jae    f0100c3a <check_page_free_list+0x151>
f0100c16:	c7 44 24 0c aa 4d 10 	movl   $0xf0104daa,0xc(%esp)
f0100c1d:	f0 
f0100c1e:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0100c25:	f0 
f0100c26:	c7 44 24 04 92 02 00 	movl   $0x292,0x4(%esp)
f0100c2d:	00 
f0100c2e:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0100c35:	e8 e7 f4 ff ff       	call   f0100121 <_panic>
		assert(pp < pages + npages);
f0100c3a:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c3d:	72 24                	jb     f0100c63 <check_page_free_list+0x17a>
f0100c3f:	c7 44 24 0c cb 4d 10 	movl   $0xf0104dcb,0xc(%esp)
f0100c46:	f0 
f0100c47:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0100c4e:	f0 
f0100c4f:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
f0100c56:	00 
f0100c57:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0100c5e:	e8 be f4 ff ff       	call   f0100121 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c63:	89 d0                	mov    %edx,%eax
f0100c65:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c68:	a8 07                	test   $0x7,%al
f0100c6a:	74 24                	je     f0100c90 <check_page_free_list+0x1a7>
f0100c6c:	c7 44 24 0c 90 45 10 	movl   $0xf0104590,0xc(%esp)
f0100c73:	f0 
f0100c74:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0100c7b:	f0 
f0100c7c:	c7 44 24 04 94 02 00 	movl   $0x294,0x4(%esp)
f0100c83:	00 
f0100c84:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0100c8b:	e8 91 f4 ff ff       	call   f0100121 <_panic>

//page2pa returns the relevant physical address of the page
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c90:	c1 f8 03             	sar    $0x3,%eax
f0100c93:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c96:	85 c0                	test   %eax,%eax
f0100c98:	75 24                	jne    f0100cbe <check_page_free_list+0x1d5>
f0100c9a:	c7 44 24 0c df 4d 10 	movl   $0xf0104ddf,0xc(%esp)
f0100ca1:	f0 
f0100ca2:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0100ca9:	f0 
f0100caa:	c7 44 24 04 97 02 00 	movl   $0x297,0x4(%esp)
f0100cb1:	00 
f0100cb2:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0100cb9:	e8 63 f4 ff ff       	call   f0100121 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100cbe:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100cc3:	75 24                	jne    f0100ce9 <check_page_free_list+0x200>
f0100cc5:	c7 44 24 0c f0 4d 10 	movl   $0xf0104df0,0xc(%esp)
f0100ccc:	f0 
f0100ccd:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0100cd4:	f0 
f0100cd5:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f0100cdc:	00 
f0100cdd:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0100ce4:	e8 38 f4 ff ff       	call   f0100121 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100ce9:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100cee:	75 24                	jne    f0100d14 <check_page_free_list+0x22b>
f0100cf0:	c7 44 24 0c c4 45 10 	movl   $0xf01045c4,0xc(%esp)
f0100cf7:	f0 
f0100cf8:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0100cff:	f0 
f0100d00:	c7 44 24 04 99 02 00 	movl   $0x299,0x4(%esp)
f0100d07:	00 
f0100d08:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0100d0f:	e8 0d f4 ff ff       	call   f0100121 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d14:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100d19:	75 24                	jne    f0100d3f <check_page_free_list+0x256>
f0100d1b:	c7 44 24 0c 09 4e 10 	movl   $0xf0104e09,0xc(%esp)
f0100d22:	f0 
f0100d23:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0100d2a:	f0 
f0100d2b:	c7 44 24 04 9a 02 00 	movl   $0x29a,0x4(%esp)
f0100d32:	00 
f0100d33:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0100d3a:	e8 e2 f3 ff ff       	call   f0100121 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d3f:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d44:	76 58                	jbe    f0100d9e <check_page_free_list+0x2b5>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d46:	89 c3                	mov    %eax,%ebx
f0100d48:	c1 eb 0c             	shr    $0xc,%ebx
f0100d4b:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f0100d4e:	77 20                	ja     f0100d70 <check_page_free_list+0x287>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d50:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d54:	c7 44 24 08 24 45 10 	movl   $0xf0104524,0x8(%esp)
f0100d5b:	f0 
f0100d5c:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100d63:	00 
f0100d64:	c7 04 24 90 4d 10 f0 	movl   $0xf0104d90,(%esp)
f0100d6b:	e8 b1 f3 ff ff       	call   f0100121 <_panic>
	return (void *)(pa + KERNBASE);
f0100d70:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d75:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100d78:	76 2a                	jbe    f0100da4 <check_page_free_list+0x2bb>
f0100d7a:	c7 44 24 0c e8 45 10 	movl   $0xf01045e8,0xc(%esp)
f0100d81:	f0 
f0100d82:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0100d89:	f0 
f0100d8a:	c7 44 24 04 9b 02 00 	movl   $0x29b,0x4(%esp)
f0100d91:	00 
f0100d92:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0100d99:	e8 83 f3 ff ff       	call   f0100121 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d9e:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0100da2:	eb 03                	jmp    f0100da7 <check_page_free_list+0x2be>
		else
			++nfree_extmem;
f0100da4:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100da7:	8b 12                	mov    (%edx),%edx
f0100da9:	85 d2                	test   %edx,%edx
f0100dab:	0f 85 61 fe ff ff    	jne    f0100c12 <check_page_free_list+0x129>
f0100db1:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100db4:	85 db                	test   %ebx,%ebx
f0100db6:	7f 24                	jg     f0100ddc <check_page_free_list+0x2f3>
f0100db8:	c7 44 24 0c 23 4e 10 	movl   $0xf0104e23,0xc(%esp)
f0100dbf:	f0 
f0100dc0:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0100dc7:	f0 
f0100dc8:	c7 44 24 04 a3 02 00 	movl   $0x2a3,0x4(%esp)
f0100dcf:	00 
f0100dd0:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0100dd7:	e8 45 f3 ff ff       	call   f0100121 <_panic>
	assert(nfree_extmem > 0);
f0100ddc:	85 ff                	test   %edi,%edi
f0100dde:	7f 24                	jg     f0100e04 <check_page_free_list+0x31b>
f0100de0:	c7 44 24 0c 35 4e 10 	movl   $0xf0104e35,0xc(%esp)
f0100de7:	f0 
f0100de8:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0100def:	f0 
f0100df0:	c7 44 24 04 a4 02 00 	movl   $0x2a4,0x4(%esp)
f0100df7:	00 
f0100df8:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0100dff:	e8 1d f3 ff ff       	call   f0100121 <_panic>
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
f0100e04:	0f b6 45 c0          	movzbl -0x40(%ebp),%eax
f0100e08:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e0c:	c7 04 24 30 46 10 f0 	movl   $0xf0104630,(%esp)
f0100e13:	e8 aa 21 00 00       	call   f0102fc2 <cprintf>
f0100e18:	eb 29                	jmp    f0100e43 <check_page_free_list+0x35a>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100e1a:	a1 40 85 11 f0       	mov    0xf0118540,%eax
f0100e1f:	85 c0                	test   %eax,%eax
f0100e21:	0f 85 f7 fc ff ff    	jne    f0100b1e <check_page_free_list+0x35>
f0100e27:	e9 d6 fc ff ff       	jmp    f0100b02 <check_page_free_list+0x19>
f0100e2c:	83 3d 40 85 11 f0 00 	cmpl   $0x0,0xf0118540
f0100e33:	0f 84 c9 fc ff ff    	je     f0100b02 <check_page_free_list+0x19>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e39:	be 00 04 00 00       	mov    $0x400,%esi
f0100e3e:	e9 29 fd ff ff       	jmp    f0100b6c <check_page_free_list+0x83>
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
}
f0100e43:	83 c4 4c             	add    $0x4c,%esp
f0100e46:	5b                   	pop    %ebx
f0100e47:	5e                   	pop    %esi
f0100e48:	5f                   	pop    %edi
f0100e49:	5d                   	pop    %ebp
f0100e4a:	c3                   	ret    

f0100e4b <page_init>:
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100e4b:	b8 01 00 00 00       	mov    $0x1,%eax
f0100e50:	eb 18                	jmp    f0100e6a <page_init+0x1f>
	{
	 pages[i].pp_ref = 1; //Used Pages
f0100e52:	8b 15 6c 89 11 f0    	mov    0xf011896c,%edx
f0100e58:	8d 14 c2             	lea    (%edx,%eax,8),%edx
f0100e5b:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
	 pages[i].pp_link = 0; // No links to any pages
f0100e61:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100e67:	83 c0 01             	add    $0x1,%eax
f0100e6a:	3b 05 64 89 11 f0    	cmp    0xf0118964,%eax
f0100e70:	72 e0                	jb     f0100e52 <page_init+0x7>
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100e72:	55                   	push   %ebp
f0100e73:	89 e5                	mov    %esp,%ebp
f0100e75:	57                   	push   %edi
f0100e76:	56                   	push   %esi
f0100e77:	53                   	push   %ebx
f0100e78:	83 ec 1c             	sub    $0x1c,%esp

	
	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	for (i = 1; i < npages_basemem; i++) {
f0100e7b:	8b 35 44 85 11 f0    	mov    0xf0118544,%esi
f0100e81:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e86:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100e8b:	eb 39                	jmp    f0100ec6 <page_init+0x7b>
f0100e8d:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
		pages[i].pp_ref = 0;
f0100e94:	8b 15 6c 89 11 f0    	mov    0xf011896c,%edx
f0100e9a:	66 c7 44 02 04 00 00 	movw   $0x0,0x4(%edx,%eax,1)
		pages[i].pp_link = 0;
f0100ea1:	c7 04 da 00 00 00 00 	movl   $0x0,(%edx,%ebx,8)

		if (!page_free_list){		
f0100ea8:	85 c9                	test   %ecx,%ecx
f0100eaa:	75 0a                	jne    f0100eb6 <page_init+0x6b>
		page_free_list = &pages[i];	// if page_free_list is 0 then point to current page
f0100eac:	03 05 6c 89 11 f0    	add    0xf011896c,%eax
f0100eb2:	89 c1                	mov    %eax,%ecx
f0100eb4:	eb 0d                	jmp    f0100ec3 <page_init+0x78>
		}
		else{
		pages[i-1].pp_link = &pages[i];
f0100eb6:	8b 15 6c 89 11 f0    	mov    0xf011896c,%edx
f0100ebc:	8d 3c 02             	lea    (%edx,%eax,1),%edi
f0100ebf:	89 7c 02 f8          	mov    %edi,-0x8(%edx,%eax,1)

	
	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	for (i = 1; i < npages_basemem; i++) {
f0100ec3:	83 c3 01             	add    $0x1,%ebx
f0100ec6:	39 f3                	cmp    %esi,%ebx
f0100ec8:	72 c3                	jb     f0100e8d <page_init+0x42>
f0100eca:	89 0d 40 85 11 f0    	mov    %ecx,0xf0118540
		}
		else{
		pages[i-1].pp_link = &pages[i];
		}	//Previous page is linked to this current page
	}
	cprintf("After for loop 1 value of i = %d\n", i);
f0100ed0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ed4:	c7 04 24 58 46 10 f0 	movl   $0xf0104658,(%esp)
f0100edb:	e8 e2 20 00 00       	call   f0102fc2 <cprintf>
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
f0100ee0:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f0100ee5:	8d 44 d8 f8          	lea    -0x8(%eax,%ebx,8),%eax
f0100ee9:	a3 38 85 11 f0       	mov    %eax,0xf0118538
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100eee:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ef3:	e8 6c fb ff ff       	call   f0100a64 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100ef8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100efd:	77 20                	ja     f0100f1f <page_init+0xd4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100eff:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f03:	c7 44 24 08 48 45 10 	movl   $0xf0104548,0x8(%esp)
f0100f0a:	f0 
f0100f0b:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
f0100f12:	00 
f0100f13:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0100f1a:	e8 02 f2 ff ff       	call   f0100121 <_panic>
f0100f1f:	05 ff 0f 00 10       	add    $0x10000fff,%eax
f0100f24:	c1 e8 0c             	shr    $0xc,%eax
f0100f27:	8b 1d 38 85 11 f0    	mov    0xf0118538,%ebx
f0100f2d:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100f34:	eb 2c                	jmp    f0100f62 <page_init+0x117>
		pages[i].pp_ref = 0;
f0100f36:	89 d1                	mov    %edx,%ecx
f0100f38:	03 0d 6c 89 11 f0    	add    0xf011896c,%ecx
f0100f3e:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = 0;
f0100f44:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		track->pp_link = &pages[i];
f0100f4a:	89 d1                	mov    %edx,%ecx
f0100f4c:	03 0d 6c 89 11 f0    	add    0xf011896c,%ecx
f0100f52:	89 0b                	mov    %ecx,(%ebx)
		track = &pages[i];
f0100f54:	89 d3                	mov    %edx,%ebx
f0100f56:	03 1d 6c 89 11 f0    	add    0xf011896c,%ebx
	}
	cprintf("After for loop 1 value of i = %d\n", i);
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100f5c:	83 c0 01             	add    $0x1,%eax
f0100f5f:	83 c2 08             	add    $0x8,%edx
f0100f62:	3b 05 64 89 11 f0    	cmp    0xf0118964,%eax
f0100f68:	72 cc                	jb     f0100f36 <page_init+0xeb>
f0100f6a:	89 1d 38 85 11 f0    	mov    %ebx,0xf0118538
		pages[i].pp_link = 0;
		track->pp_link = &pages[i];
		track = &pages[i];
	}
	
	cprintf("Check first entry of pages &pages[0] = %x\n", &pages[0]);
f0100f70:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f0100f75:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f79:	c7 04 24 7c 46 10 f0 	movl   $0xf010467c,(%esp)
f0100f80:	e8 3d 20 00 00       	call   f0102fc2 <cprintf>
	cprintf("&pages[npages-1] = %x\n", &pages[npages-1]);
f0100f85:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f0100f8a:	8b 15 64 89 11 f0    	mov    0xf0118964,%edx
f0100f90:	8d 44 d0 f8          	lea    -0x8(%eax,%edx,8),%eax
f0100f94:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f98:	c7 04 24 46 4e 10 f0 	movl   $0xf0104e46,(%esp)
f0100f9f:	e8 1e 20 00 00       	call   f0102fc2 <cprintf>
}
f0100fa4:	83 c4 1c             	add    $0x1c,%esp
f0100fa7:	5b                   	pop    %ebx
f0100fa8:	5e                   	pop    %esi
f0100fa9:	5f                   	pop    %edi
f0100faa:	5d                   	pop    %ebp
f0100fab:	c3                   	ret    

f0100fac <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100fac:	55                   	push   %ebp
f0100fad:	89 e5                	mov    %esp,%ebp
f0100faf:	53                   	push   %ebx
f0100fb0:	83 ec 14             	sub    $0x14,%esp
	// Check if there is a free_page available 
	if (!page_free_list)
f0100fb3:	8b 1d 40 85 11 f0    	mov    0xf0118540,%ebx
f0100fb9:	85 db                	test   %ebx,%ebx
f0100fbb:	74 75                	je     f0101032 <page_alloc+0x86>
	return NULL;
	}
	
	struct PageInfo *allocPage = NULL;   //Create a temporary pointer 
	allocPage = page_free_list;	//Point to the current head of free_page_list
	page_free_list = allocPage ->pp_link; //Move the head to the next avaialble page
f0100fbd:	8b 03                	mov    (%ebx),%eax
f0100fbf:	a3 40 85 11 f0       	mov    %eax,0xf0118540
	allocPage->pp_link = NULL;
f0100fc4:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags && ALLOC_ZERO){		//ALLOC_ZERO = 1<<0; which is nothing but  = 1
f0100fca:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100fce:	74 58                	je     f0101028 <page_alloc+0x7c>

//page2pa returns the relevant physical address of the page
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fd0:	89 d8                	mov    %ebx,%eax
f0100fd2:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0100fd8:	c1 f8 03             	sar    $0x3,%eax
f0100fdb:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fde:	89 c2                	mov    %eax,%edx
f0100fe0:	c1 ea 0c             	shr    $0xc,%edx
f0100fe3:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0100fe9:	72 20                	jb     f010100b <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100feb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fef:	c7 44 24 08 24 45 10 	movl   $0xf0104524,0x8(%esp)
f0100ff6:	f0 
f0100ff7:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100ffe:	00 
f0100fff:	c7 04 24 90 4d 10 f0 	movl   $0xf0104d90,(%esp)
f0101006:	e8 16 f1 ff ff       	call   f0100121 <_panic>
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
f010100b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101012:	00 
f0101013:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010101a:	00 
	return (void *)(pa + KERNBASE);
f010101b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101020:	89 04 24             	mov    %eax,(%esp)
f0101023:	e8 ff 2a 00 00       	call   f0103b27 <memset>
	}
	
	allocPage->pp_ref = 0;
f0101028:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return allocPage;
f010102e:	89 d8                	mov    %ebx,%eax
f0101030:	eb 05                	jmp    f0101037 <page_alloc+0x8b>
page_alloc(int alloc_flags)
{
	// Check if there is a free_page available 
	if (!page_free_list)
	{ 
	return NULL;
f0101032:	b8 00 00 00 00       	mov    $0x0,%eax
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
	}
	
	allocPage->pp_ref = 0;
	return allocPage;
}
f0101037:	83 c4 14             	add    $0x14,%esp
f010103a:	5b                   	pop    %ebx
f010103b:	5d                   	pop    %ebp
f010103c:	c3                   	ret    

f010103d <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f010103d:	55                   	push   %ebp
f010103e:	89 e5                	mov    %esp,%ebp
f0101040:	83 ec 18             	sub    $0x18,%esp
f0101043:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	
	if(pp->pp_ref)
f0101046:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010104b:	74 1c                	je     f0101069 <page_free+0x2c>
	{
	panic("Page cannot be returned to free list, as it is still refernced ");
f010104d:	c7 44 24 08 a8 46 10 	movl   $0xf01046a8,0x8(%esp)
f0101054:	f0 
f0101055:	c7 44 24 04 5f 01 00 	movl   $0x15f,0x4(%esp)
f010105c:	00 
f010105d:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101064:	e8 b8 f0 ff ff       	call   f0100121 <_panic>
	return;
	}
	
	// pp->pp_link is not NULL.
	else if(!pp) 
f0101069:	85 c0                	test   %eax,%eax
f010106b:	75 1c                	jne    f0101089 <page_free+0x4c>
	{
	panic("Page cannot be returned to free list as it is Null");
f010106d:	c7 44 24 08 e8 46 10 	movl   $0xf01046e8,0x8(%esp)
f0101074:	f0 
f0101075:	c7 44 24 04 66 01 00 	movl   $0x166,0x4(%esp)
f010107c:	00 
f010107d:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101084:	e8 98 f0 ff ff       	call   f0100121 <_panic>
	return;
	}
	
       else{
	pp->pp_link = page_free_list;
f0101089:	8b 15 40 85 11 f0    	mov    0xf0118540,%edx
f010108f:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0101091:	a3 40 85 11 f0       	mov    %eax,0xf0118540
	}


}
f0101096:	c9                   	leave  
f0101097:	c3                   	ret    

f0101098 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101098:	55                   	push   %ebp
f0101099:	89 e5                	mov    %esp,%ebp
f010109b:	83 ec 18             	sub    $0x18,%esp
f010109e:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f01010a1:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f01010a5:	8d 51 ff             	lea    -0x1(%ecx),%edx
f01010a8:	66 89 50 04          	mov    %dx,0x4(%eax)
f01010ac:	66 85 d2             	test   %dx,%dx
f01010af:	75 08                	jne    f01010b9 <page_decref+0x21>
		page_free(pp);
f01010b1:	89 04 24             	mov    %eax,(%esp)
f01010b4:	e8 84 ff ff ff       	call   f010103d <page_free>
}
f01010b9:	c9                   	leave  
f01010ba:	c3                   	ret    

f01010bb <pgdir_walk>:
// table and page directory entries.
//

pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01010bb:	55                   	push   %ebp
f01010bc:	89 e5                	mov    %esp,%ebp
f01010be:	57                   	push   %edi
f01010bf:	56                   	push   %esi
f01010c0:	53                   	push   %ebx
f01010c1:	83 ec 1c             	sub    $0x1c,%esp
	pte_t *pgTab;  //Page Table index variable

	//To find the index from the pgdir we need to get the MS 10 bits,
	//We get the MS 10bits of the virtual address by using PDX function (found in inc/mmu.h ) 
	//#define PDX(la)		((((uintptr_t) (la)) >> PDXSHIFT) & 0x3FF)
	pgDir = &pgdir[PDX(va)];
f01010c4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01010c7:	c1 eb 16             	shr    $0x16,%ebx
f01010ca:	c1 e3 02             	shl    $0x2,%ebx
f01010cd:	03 5d 08             	add    0x8(%ebp),%ebx

	// Check if page is present, PTE_P = 0x1 means page present  
	if (*pgDir & PTE_P)  {
f01010d0:	8b 3b                	mov    (%ebx),%edi
f01010d2:	f7 c7 01 00 00 00    	test   $0x1,%edi
f01010d8:	74 3e                	je     f0101118 <pgdir_walk+0x5d>
		//page table entry to get to the final address translation. Now using the pgDir we can use the 
		//PTE_ADDR(pde) function to get the upper 20 bits, but this function returns a physical address. 
		//Since the kernel requires a virtual address, we can use the function KADDR to get the virtual 
		//address.
		
		pgTab = (pte_t*) KADDR(PTE_ADDR(*pgDir));
f01010da:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010e0:	89 f8                	mov    %edi,%eax
f01010e2:	c1 e8 0c             	shr    $0xc,%eax
f01010e5:	3b 05 64 89 11 f0    	cmp    0xf0118964,%eax
f01010eb:	72 20                	jb     f010110d <pgdir_walk+0x52>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010ed:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01010f1:	c7 44 24 08 24 45 10 	movl   $0xf0104524,0x8(%esp)
f01010f8:	f0 
f01010f9:	c7 44 24 04 a7 01 00 	movl   $0x1a7,0x4(%esp)
f0101100:	00 
f0101101:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101108:	e8 14 f0 ff ff       	call   f0100121 <_panic>
	return (void *)(pa + KERNBASE);
f010110d:	81 ef 00 00 00 10    	sub    $0x10000000,%edi
f0101113:	e9 8f 00 00 00       	jmp    f01011a7 <pgdir_walk+0xec>
	//If page is not present 
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
f0101118:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010111c:	0f 84 94 00 00 00    	je     f01011b6 <pgdir_walk+0xfb>
f0101122:	c7 04 24 00 10 00 00 	movl   $0x1000,(%esp)
f0101129:	e8 7e fe ff ff       	call   f0100fac <page_alloc>
f010112e:	89 c6                	mov    %eax,%esi
f0101130:	85 c0                	test   %eax,%eax
f0101132:	0f 84 85 00 00 00    	je     f01011bd <pgdir_walk+0x102>
			return 0;
		}

		newPage->pp_ref++;  //Increment the ref pointer of the page 
f0101138:	66 83 40 04 01       	addw   $0x1,0x4(%eax)

//page2pa returns the relevant physical address of the page
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010113d:	89 c7                	mov    %eax,%edi
f010113f:	2b 3d 6c 89 11 f0    	sub    0xf011896c,%edi
f0101145:	c1 ff 03             	sar    $0x3,%edi
f0101148:	c1 e7 0c             	shl    $0xc,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010114b:	89 f8                	mov    %edi,%eax
f010114d:	c1 e8 0c             	shr    $0xc,%eax
f0101150:	3b 05 64 89 11 f0    	cmp    0xf0118964,%eax
f0101156:	72 20                	jb     f0101178 <pgdir_walk+0xbd>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101158:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010115c:	c7 44 24 08 24 45 10 	movl   $0xf0104524,0x8(%esp)
f0101163:	f0 
f0101164:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010116b:	00 
f010116c:	c7 04 24 90 4d 10 f0 	movl   $0xf0104d90,(%esp)
f0101173:	e8 a9 ef ff ff       	call   f0100121 <_panic>
	return (void *)(pa + KERNBASE);
f0101178:	81 ef 00 00 00 10    	sub    $0x10000000,%edi
		//Now this section creates the bindings and updates all the flags 
		//for relevant use of the page.
		
		//First create a link on the pgTab wrt to the new page
		pgTab = (pte_t*)page2kva(newPage); // this function gets the virtual address of the new page
		memset (pgTab, 0, PGSIZE); //Clear the entire page
f010117e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101185:	00 
f0101186:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010118d:	00 
f010118e:	89 3c 24             	mov    %edi,(%esp)
f0101191:	e8 91 29 00 00       	call   f0103b27 <memset>

//page2pa returns the relevant physical address of the page
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101196:	2b 35 6c 89 11 f0    	sub    0xf011896c,%esi
f010119c:	c1 fe 03             	sar    $0x3,%esi
f010119f:	c1 e6 0c             	shl    $0xc,%esi

		//Page Table, pgTab contains the virtual address , now we need to set the permission bits.
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
f01011a2:	83 ce 07             	or     $0x7,%esi
f01011a5:	89 33                	mov    %esi,(%ebx)
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
f01011a7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011aa:	c1 e8 0a             	shr    $0xa,%eax
f01011ad:	25 fc 0f 00 00       	and    $0xffc,%eax
f01011b2:	01 f8                	add    %edi,%eax
f01011b4:	eb 0c                	jmp    f01011c2 <pgdir_walk+0x107>
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
			return 0;
f01011b6:	b8 00 00 00 00       	mov    $0x0,%eax
f01011bb:	eb 05                	jmp    f01011c2 <pgdir_walk+0x107>
f01011bd:	b8 00 00 00 00       	mov    $0x0,%eax
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
}
f01011c2:	83 c4 1c             	add    $0x1c,%esp
f01011c5:	5b                   	pop    %ebx
f01011c6:	5e                   	pop    %esi
f01011c7:	5f                   	pop    %edi
f01011c8:	5d                   	pop    %ebp
f01011c9:	c3                   	ret    

f01011ca <boot_map_region>:
//
// Hint: the TA solution uses pgdir_walk

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01011ca:	55                   	push   %ebp
f01011cb:	89 e5                	mov    %esp,%ebp
f01011cd:	57                   	push   %edi
f01011ce:	56                   	push   %esi
f01011cf:	53                   	push   %ebx
f01011d0:	83 ec 2c             	sub    $0x2c,%esp
f01011d3:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f01011d6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
f01011dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01011df:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	size = ROUNDUP(size, PGSIZE); 
f01011e4:	8d b1 ff 0f 00 00    	lea    0xfff(%ecx),%esi
f01011ea:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f01011f0:	89 d3                	mov    %edx,%ebx
f01011f2:	29 d0                	sub    %edx,%eax
f01011f4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		}
		if (*pgTbEnt & PTE_P){
			panic("Page is already mapped");
		}
		
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
f01011f7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011fa:	83 c8 01             	or     $0x1,%eax
f01011fd:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f0101200:	eb 69                	jmp    f010126b <boot_map_region+0xa1>
		if (!(pgTbEnt = pgdir_walk(pgdir, (const void*)vaBegin, 1))){
f0101202:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101209:	00 
f010120a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010120e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101211:	89 04 24             	mov    %eax,(%esp)
f0101214:	e8 a2 fe ff ff       	call   f01010bb <pgdir_walk>
f0101219:	85 c0                	test   %eax,%eax
f010121b:	75 1c                	jne    f0101239 <boot_map_region+0x6f>
			panic("Cannot find page for the page table entry, from boot_map_region function");
f010121d:	c7 44 24 08 1c 47 10 	movl   $0xf010471c,0x8(%esp)
f0101224:	f0 
f0101225:	c7 44 24 04 dd 01 00 	movl   $0x1dd,0x4(%esp)
f010122c:	00 
f010122d:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101234:	e8 e8 ee ff ff       	call   f0100121 <_panic>
		}
		if (*pgTbEnt & PTE_P){
f0101239:	f6 00 01             	testb  $0x1,(%eax)
f010123c:	74 1c                	je     f010125a <boot_map_region+0x90>
			panic("Page is already mapped");
f010123e:	c7 44 24 08 5d 4e 10 	movl   $0xf0104e5d,0x8(%esp)
f0101245:	f0 
f0101246:	c7 44 24 04 e0 01 00 	movl   $0x1e0,0x4(%esp)
f010124d:	00 
f010124e:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101255:	e8 c7 ee ff ff       	call   f0100121 <_panic>
		}
		
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
f010125a:	0b 7d dc             	or     -0x24(%ebp),%edi
f010125d:	89 38                	mov    %edi,(%eax)
		vaBegin += PGSIZE;
f010125f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		paBegin += PGSIZE; 
		size -= PGSIZE;
f0101265:	81 ee 00 10 00 00    	sub    $0x1000,%esi
f010126b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010126e:	8d 3c 18             	lea    (%eax,%ebx,1),%edi
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f0101271:	85 f6                	test   %esi,%esi
f0101273:	75 8d                	jne    f0101202 <boot_map_region+0x38>
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
		vaBegin += PGSIZE;
		paBegin += PGSIZE; 
		size -= PGSIZE;
	} 	
}
f0101275:	83 c4 2c             	add    $0x2c,%esp
f0101278:	5b                   	pop    %ebx
f0101279:	5e                   	pop    %esi
f010127a:	5f                   	pop    %edi
f010127b:	5d                   	pop    %ebp
f010127c:	c3                   	ret    

f010127d <page_lookup>:
// Hint: the TA solution uses pgdir_walk and pa2page.
//

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f010127d:	55                   	push   %ebp
f010127e:	89 e5                	mov    %esp,%ebp
f0101280:	53                   	push   %ebx
f0101281:	83 ec 14             	sub    $0x14,%esp
f0101284:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
	pgTbEty = pgdir_walk(pgdir, va, 0);
f0101287:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010128e:	00 
f010128f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101292:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101296:	8b 45 08             	mov    0x8(%ebp),%eax
f0101299:	89 04 24             	mov    %eax,(%esp)
f010129c:	e8 1a fe ff ff       	call   f01010bb <pgdir_walk>
f01012a1:	89 c2                	mov    %eax,%edx
	if (pgTbEty && (*pgTbEty & PTE_P)) {
f01012a3:	85 c0                	test   %eax,%eax
f01012a5:	74 1a                	je     f01012c1 <page_lookup+0x44>
f01012a7:	8b 00                	mov    (%eax),%eax
f01012a9:	a8 01                	test   $0x1,%al
f01012ab:	74 1b                	je     f01012c8 <page_lookup+0x4b>
		ret = pages + (PTE_ADDR(*pgTbEty) >> PTXSHIFT);
f01012ad:	c1 e8 0c             	shr    $0xc,%eax
f01012b0:	8b 0d 6c 89 11 f0    	mov    0xf011896c,%ecx
f01012b6:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
		if (pte_store) {
f01012b9:	85 db                	test   %ebx,%ebx
f01012bb:	74 10                	je     f01012cd <page_lookup+0x50>
			*pte_store = pgTbEty;
f01012bd:	89 13                	mov    %edx,(%ebx)
f01012bf:	eb 0c                	jmp    f01012cd <page_lookup+0x50>

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
f01012c1:	b8 00 00 00 00       	mov    $0x0,%eax
f01012c6:	eb 05                	jmp    f01012cd <page_lookup+0x50>
f01012c8:	b8 00 00 00 00       	mov    $0x0,%eax
		if (pte_store) {
			*pte_store = pgTbEty;
		}
	}
	return ret;
}
f01012cd:	83 c4 14             	add    $0x14,%esp
f01012d0:	5b                   	pop    %ebx
f01012d1:	5d                   	pop    %ebp
f01012d2:	c3                   	ret    

f01012d3 <page_remove>:
// 	tlb_invalidate, and page_decref.
//

void
page_remove(pde_t *pgdir, void *va)
{
f01012d3:	55                   	push   %ebp
f01012d4:	89 e5                	mov    %esp,%ebp
f01012d6:	53                   	push   %ebx
f01012d7:	83 ec 24             	sub    $0x24,%esp
f01012da:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte;
	struct PageInfo *remPage = 0;
	if (!(remPage = page_lookup(pgdir, va, &pte))) {
f01012dd:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01012e0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012e4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012e8:	8b 45 08             	mov    0x8(%ebp),%eax
f01012eb:	89 04 24             	mov    %eax,(%esp)
f01012ee:	e8 8a ff ff ff       	call   f010127d <page_lookup>
f01012f3:	85 c0                	test   %eax,%eax
f01012f5:	74 14                	je     f010130b <page_remove+0x38>
		return;
	}
	page_decref(remPage);
f01012f7:	89 04 24             	mov    %eax,(%esp)
f01012fa:	e8 99 fd ff ff       	call   f0101098 <page_decref>
	*pte = 0;
f01012ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101302:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101308:	0f 01 3b             	invlpg (%ebx)
	tlb_invalidate(pgdir, va);
}
f010130b:	83 c4 24             	add    $0x24,%esp
f010130e:	5b                   	pop    %ebx
f010130f:	5d                   	pop    %ebp
f0101310:	c3                   	ret    

f0101311 <page_insert>:
// and page2pa.
//

int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101311:	55                   	push   %ebp
f0101312:	89 e5                	mov    %esp,%ebp
f0101314:	57                   	push   %edi
f0101315:	56                   	push   %esi
f0101316:	53                   	push   %ebx
f0101317:	83 ec 1c             	sub    $0x1c,%esp
f010131a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010131d:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
f0101320:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101327:	00 
f0101328:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010132c:	8b 45 08             	mov    0x8(%ebp),%eax
f010132f:	89 04 24             	mov    %eax,(%esp)
f0101332:	e8 84 fd ff ff       	call   f01010bb <pgdir_walk>
f0101337:	89 c3                	mov    %eax,%ebx
	
	if (!pte){
f0101339:	85 c0                	test   %eax,%eax
f010133b:	0f 84 85 00 00 00    	je     f01013c6 <page_insert+0xb5>
		return -E_NO_MEM; //Page table could not be allocated	
	}

	if (*pte & PTE_P){    //if page is already present
f0101341:	8b 00                	mov    (%eax),%eax
f0101343:	a8 01                	test   $0x1,%al
f0101345:	74 5b                	je     f01013a2 <page_insert+0x91>
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
f0101347:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010134c:	89 f2                	mov    %esi,%edx
f010134e:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0101354:	c1 fa 03             	sar    $0x3,%edx
f0101357:	c1 e2 0c             	shl    $0xc,%edx
f010135a:	39 d0                	cmp    %edx,%eax
f010135c:	75 11                	jne    f010136f <page_insert+0x5e>
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
f010135e:	8b 55 14             	mov    0x14(%ebp),%edx
f0101361:	83 ca 01             	or     $0x1,%edx
f0101364:	09 d0                	or     %edx,%eax
f0101366:	89 03                	mov    %eax,(%ebx)
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
			pp->pp_ref ++;  //incremnt the page reference
		}
		return 0;
f0101368:	b8 00 00 00 00       	mov    $0x0,%eax
f010136d:	eb 5c                	jmp    f01013cb <page_insert+0xba>
	if (*pte & PTE_P){    //if page is already present
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
		}
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
f010136f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101373:	8b 45 08             	mov    0x8(%ebp),%eax
f0101376:	89 04 24             	mov    %eax,(%esp)
f0101379:	e8 55 ff ff ff       	call   f01012d3 <page_remove>
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
f010137e:	8b 55 14             	mov    0x14(%ebp),%edx
f0101381:	83 ca 01             	or     $0x1,%edx
f0101384:	89 f0                	mov    %esi,%eax
f0101386:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f010138c:	c1 f8 03             	sar    $0x3,%eax
f010138f:	c1 e0 0c             	shl    $0xc,%eax
f0101392:	09 d0                	or     %edx,%eax
f0101394:	89 03                	mov    %eax,(%ebx)
			pp->pp_ref ++;  //incremnt the page reference
f0101396:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
		}
		return 0;
f010139b:	b8 00 00 00 00       	mov    $0x0,%eax
f01013a0:	eb 29                	jmp    f01013cb <page_insert+0xba>
	}	
	else{   // if page is not present
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
f01013a2:	8b 55 14             	mov    0x14(%ebp),%edx
f01013a5:	83 ca 01             	or     $0x1,%edx
f01013a8:	89 f0                	mov    %esi,%eax
f01013aa:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f01013b0:	c1 f8 03             	sar    $0x3,%eax
f01013b3:	c1 e0 0c             	shl    $0xc,%eax
f01013b6:	09 d0                	or     %edx,%eax
f01013b8:	89 03                	mov    %eax,(%ebx)
		pp->pp_ref ++; // increment the page reference count	     
f01013ba:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	}
	return 0;
f01013bf:	b8 00 00 00 00       	mov    $0x0,%eax
f01013c4:	eb 05                	jmp    f01013cb <page_insert+0xba>
{
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
	
	if (!pte){
		return -E_NO_MEM; //Page table could not be allocated	
f01013c6:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
		pp->pp_ref ++; // increment the page reference count	     
	}
	return 0;

}
f01013cb:	83 c4 1c             	add    $0x1c,%esp
f01013ce:	5b                   	pop    %ebx
f01013cf:	5e                   	pop    %esi
f01013d0:	5f                   	pop    %edi
f01013d1:	5d                   	pop    %ebp
f01013d2:	c3                   	ret    

f01013d3 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01013d3:	55                   	push   %ebp
f01013d4:	89 e5                	mov    %esp,%ebp
f01013d6:	57                   	push   %edi
f01013d7:	56                   	push   %esi
f01013d8:	53                   	push   %ebx
f01013d9:	83 ec 4c             	sub    $0x4c,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01013dc:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f01013e3:	e8 6a 1b 00 00       	call   f0102f52 <mc146818_read>
f01013e8:	89 c3                	mov    %eax,%ebx
f01013ea:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f01013f1:	e8 5c 1b 00 00       	call   f0102f52 <mc146818_read>
f01013f6:	c1 e0 08             	shl    $0x8,%eax
f01013f9:	09 c3                	or     %eax,%ebx
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01013fb:	89 d8                	mov    %ebx,%eax
f01013fd:	c1 e0 0a             	shl    $0xa,%eax
f0101400:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101406:	85 c0                	test   %eax,%eax
f0101408:	0f 48 c2             	cmovs  %edx,%eax
f010140b:	c1 f8 0c             	sar    $0xc,%eax
f010140e:	a3 44 85 11 f0       	mov    %eax,0xf0118544
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101413:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010141a:	e8 33 1b 00 00       	call   f0102f52 <mc146818_read>
f010141f:	89 c3                	mov    %eax,%ebx
f0101421:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101428:	e8 25 1b 00 00       	call   f0102f52 <mc146818_read>
f010142d:	c1 e0 08             	shl    $0x8,%eax
f0101430:	09 c3                	or     %eax,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101432:	89 d8                	mov    %ebx,%eax
f0101434:	c1 e0 0a             	shl    $0xa,%eax
f0101437:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010143d:	85 c0                	test   %eax,%eax
f010143f:	0f 48 c2             	cmovs  %edx,%eax
f0101442:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101445:	85 c0                	test   %eax,%eax
f0101447:	74 0e                	je     f0101457 <mem_init+0x84>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101449:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f010144f:	89 15 64 89 11 f0    	mov    %edx,0xf0118964
f0101455:	eb 0c                	jmp    f0101463 <mem_init+0x90>
	else
		npages = npages_basemem;
f0101457:	8b 15 44 85 11 f0    	mov    0xf0118544,%edx
f010145d:	89 15 64 89 11 f0    	mov    %edx,0xf0118964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0101463:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101466:	c1 e8 0a             	shr    $0xa,%eax
f0101469:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f010146d:	a1 44 85 11 f0       	mov    0xf0118544,%eax
f0101472:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101475:	c1 e8 0a             	shr    $0xa,%eax
f0101478:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f010147c:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f0101481:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101484:	c1 e8 0a             	shr    $0xa,%eax
f0101487:	89 44 24 04          	mov    %eax,0x4(%esp)
f010148b:	c7 04 24 68 47 10 f0 	movl   $0xf0104768,(%esp)
f0101492:	e8 2b 1b 00 00       	call   f0102fc2 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101497:	b8 00 10 00 00       	mov    $0x1000,%eax
f010149c:	e8 c3 f5 ff ff       	call   f0100a64 <boot_alloc>
f01014a1:	a3 68 89 11 f0       	mov    %eax,0xf0118968
	memset(kern_pgdir, 0, PGSIZE);
f01014a6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01014ad:	00 
f01014ae:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01014b5:	00 
f01014b6:	89 04 24             	mov    %eax,(%esp)
f01014b9:	e8 69 26 00 00       	call   f0103b27 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01014be:	a1 68 89 11 f0       	mov    0xf0118968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01014c3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01014c8:	77 20                	ja     f01014ea <mem_init+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01014ca:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01014ce:	c7 44 24 08 48 45 10 	movl   $0xf0104548,0x8(%esp)
f01014d5:	f0 
f01014d6:	c7 44 24 04 95 00 00 	movl   $0x95,0x4(%esp)
f01014dd:	00 
f01014de:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f01014e5:	e8 37 ec ff ff       	call   f0100121 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01014ea:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01014f0:	83 ca 05             	or     $0x5,%edx
f01014f3:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.

	//This line creates a boot allocation of memory of the size of number of pages
	// mulitplied by size of struct Pageinfo to store metadata of the page. 
	pages = boot_alloc(sizeof(struct PageInfo) * npages);   
f01014f9:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f01014fe:	c1 e0 03             	shl    $0x3,%eax
f0101501:	e8 5e f5 ff ff       	call   f0100a64 <boot_alloc>
f0101506:	a3 6c 89 11 f0       	mov    %eax,0xf011896c
	memset(pages, 0, sizeof(struct PageInfo) * npages); //Clear the memory 
f010150b:	8b 0d 64 89 11 f0    	mov    0xf0118964,%ecx
f0101511:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101518:	89 54 24 08          	mov    %edx,0x8(%esp)
f010151c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101523:	00 
f0101524:	89 04 24             	mov    %eax,(%esp)
f0101527:	e8 fb 25 00 00       	call   f0103b27 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010152c:	e8 1a f9 ff ff       	call   f0100e4b <page_init>

	check_page_free_list(1);
f0101531:	b8 01 00 00 00       	mov    $0x1,%eax
f0101536:	e8 ae f5 ff ff       	call   f0100ae9 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010153b:	83 3d 6c 89 11 f0 00 	cmpl   $0x0,0xf011896c
f0101542:	75 1c                	jne    f0101560 <mem_init+0x18d>
		panic("'pages' is a null pointer!");
f0101544:	c7 44 24 08 74 4e 10 	movl   $0xf0104e74,0x8(%esp)
f010154b:	f0 
f010154c:	c7 44 24 04 b6 02 00 	movl   $0x2b6,0x4(%esp)
f0101553:	00 
f0101554:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f010155b:	e8 c1 eb ff ff       	call   f0100121 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101560:	a1 40 85 11 f0       	mov    0xf0118540,%eax
f0101565:	bb 00 00 00 00       	mov    $0x0,%ebx
f010156a:	eb 05                	jmp    f0101571 <mem_init+0x19e>
		++nfree;
f010156c:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010156f:	8b 00                	mov    (%eax),%eax
f0101571:	85 c0                	test   %eax,%eax
f0101573:	75 f7                	jne    f010156c <mem_init+0x199>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101575:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010157c:	e8 2b fa ff ff       	call   f0100fac <page_alloc>
f0101581:	89 c7                	mov    %eax,%edi
f0101583:	85 c0                	test   %eax,%eax
f0101585:	75 24                	jne    f01015ab <mem_init+0x1d8>
f0101587:	c7 44 24 0c 8f 4e 10 	movl   $0xf0104e8f,0xc(%esp)
f010158e:	f0 
f010158f:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101596:	f0 
f0101597:	c7 44 24 04 be 02 00 	movl   $0x2be,0x4(%esp)
f010159e:	00 
f010159f:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f01015a6:	e8 76 eb ff ff       	call   f0100121 <_panic>
	assert((pp1 = page_alloc(0)));
f01015ab:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015b2:	e8 f5 f9 ff ff       	call   f0100fac <page_alloc>
f01015b7:	89 c6                	mov    %eax,%esi
f01015b9:	85 c0                	test   %eax,%eax
f01015bb:	75 24                	jne    f01015e1 <mem_init+0x20e>
f01015bd:	c7 44 24 0c a5 4e 10 	movl   $0xf0104ea5,0xc(%esp)
f01015c4:	f0 
f01015c5:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f01015cc:	f0 
f01015cd:	c7 44 24 04 bf 02 00 	movl   $0x2bf,0x4(%esp)
f01015d4:	00 
f01015d5:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f01015dc:	e8 40 eb ff ff       	call   f0100121 <_panic>
	assert((pp2 = page_alloc(0)));
f01015e1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015e8:	e8 bf f9 ff ff       	call   f0100fac <page_alloc>
f01015ed:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015f0:	85 c0                	test   %eax,%eax
f01015f2:	75 24                	jne    f0101618 <mem_init+0x245>
f01015f4:	c7 44 24 0c bb 4e 10 	movl   $0xf0104ebb,0xc(%esp)
f01015fb:	f0 
f01015fc:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101603:	f0 
f0101604:	c7 44 24 04 c0 02 00 	movl   $0x2c0,0x4(%esp)
f010160b:	00 
f010160c:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101613:	e8 09 eb ff ff       	call   f0100121 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101618:	39 f7                	cmp    %esi,%edi
f010161a:	75 24                	jne    f0101640 <mem_init+0x26d>
f010161c:	c7 44 24 0c d1 4e 10 	movl   $0xf0104ed1,0xc(%esp)
f0101623:	f0 
f0101624:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f010162b:	f0 
f010162c:	c7 44 24 04 c3 02 00 	movl   $0x2c3,0x4(%esp)
f0101633:	00 
f0101634:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f010163b:	e8 e1 ea ff ff       	call   f0100121 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101640:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101643:	39 c6                	cmp    %eax,%esi
f0101645:	74 04                	je     f010164b <mem_init+0x278>
f0101647:	39 c7                	cmp    %eax,%edi
f0101649:	75 24                	jne    f010166f <mem_init+0x29c>
f010164b:	c7 44 24 0c a4 47 10 	movl   $0xf01047a4,0xc(%esp)
f0101652:	f0 
f0101653:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f010165a:	f0 
f010165b:	c7 44 24 04 c4 02 00 	movl   $0x2c4,0x4(%esp)
f0101662:	00 
f0101663:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f010166a:	e8 b2 ea ff ff       	call   f0100121 <_panic>

//page2pa returns the relevant physical address of the page
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010166f:	8b 15 6c 89 11 f0    	mov    0xf011896c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101675:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f010167a:	c1 e0 0c             	shl    $0xc,%eax
f010167d:	89 f9                	mov    %edi,%ecx
f010167f:	29 d1                	sub    %edx,%ecx
f0101681:	c1 f9 03             	sar    $0x3,%ecx
f0101684:	c1 e1 0c             	shl    $0xc,%ecx
f0101687:	39 c1                	cmp    %eax,%ecx
f0101689:	72 24                	jb     f01016af <mem_init+0x2dc>
f010168b:	c7 44 24 0c e3 4e 10 	movl   $0xf0104ee3,0xc(%esp)
f0101692:	f0 
f0101693:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f010169a:	f0 
f010169b:	c7 44 24 04 c5 02 00 	movl   $0x2c5,0x4(%esp)
f01016a2:	00 
f01016a3:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f01016aa:	e8 72 ea ff ff       	call   f0100121 <_panic>
f01016af:	89 f1                	mov    %esi,%ecx
f01016b1:	29 d1                	sub    %edx,%ecx
f01016b3:	c1 f9 03             	sar    $0x3,%ecx
f01016b6:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f01016b9:	39 c8                	cmp    %ecx,%eax
f01016bb:	77 24                	ja     f01016e1 <mem_init+0x30e>
f01016bd:	c7 44 24 0c 00 4f 10 	movl   $0xf0104f00,0xc(%esp)
f01016c4:	f0 
f01016c5:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f01016cc:	f0 
f01016cd:	c7 44 24 04 c6 02 00 	movl   $0x2c6,0x4(%esp)
f01016d4:	00 
f01016d5:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f01016dc:	e8 40 ea ff ff       	call   f0100121 <_panic>
f01016e1:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01016e4:	29 d1                	sub    %edx,%ecx
f01016e6:	89 ca                	mov    %ecx,%edx
f01016e8:	c1 fa 03             	sar    $0x3,%edx
f01016eb:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f01016ee:	39 d0                	cmp    %edx,%eax
f01016f0:	77 24                	ja     f0101716 <mem_init+0x343>
f01016f2:	c7 44 24 0c 1d 4f 10 	movl   $0xf0104f1d,0xc(%esp)
f01016f9:	f0 
f01016fa:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101701:	f0 
f0101702:	c7 44 24 04 c7 02 00 	movl   $0x2c7,0x4(%esp)
f0101709:	00 
f010170a:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101711:	e8 0b ea ff ff       	call   f0100121 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101716:	a1 40 85 11 f0       	mov    0xf0118540,%eax
f010171b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010171e:	c7 05 40 85 11 f0 00 	movl   $0x0,0xf0118540
f0101725:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101728:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010172f:	e8 78 f8 ff ff       	call   f0100fac <page_alloc>
f0101734:	85 c0                	test   %eax,%eax
f0101736:	74 24                	je     f010175c <mem_init+0x389>
f0101738:	c7 44 24 0c 3a 4f 10 	movl   $0xf0104f3a,0xc(%esp)
f010173f:	f0 
f0101740:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101747:	f0 
f0101748:	c7 44 24 04 ce 02 00 	movl   $0x2ce,0x4(%esp)
f010174f:	00 
f0101750:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101757:	e8 c5 e9 ff ff       	call   f0100121 <_panic>

	// free and re-allocate?
	page_free(pp0);
f010175c:	89 3c 24             	mov    %edi,(%esp)
f010175f:	e8 d9 f8 ff ff       	call   f010103d <page_free>
	page_free(pp1);
f0101764:	89 34 24             	mov    %esi,(%esp)
f0101767:	e8 d1 f8 ff ff       	call   f010103d <page_free>
	page_free(pp2);
f010176c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010176f:	89 04 24             	mov    %eax,(%esp)
f0101772:	e8 c6 f8 ff ff       	call   f010103d <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101777:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010177e:	e8 29 f8 ff ff       	call   f0100fac <page_alloc>
f0101783:	89 c6                	mov    %eax,%esi
f0101785:	85 c0                	test   %eax,%eax
f0101787:	75 24                	jne    f01017ad <mem_init+0x3da>
f0101789:	c7 44 24 0c 8f 4e 10 	movl   $0xf0104e8f,0xc(%esp)
f0101790:	f0 
f0101791:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101798:	f0 
f0101799:	c7 44 24 04 d5 02 00 	movl   $0x2d5,0x4(%esp)
f01017a0:	00 
f01017a1:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f01017a8:	e8 74 e9 ff ff       	call   f0100121 <_panic>
	assert((pp1 = page_alloc(0)));
f01017ad:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017b4:	e8 f3 f7 ff ff       	call   f0100fac <page_alloc>
f01017b9:	89 c7                	mov    %eax,%edi
f01017bb:	85 c0                	test   %eax,%eax
f01017bd:	75 24                	jne    f01017e3 <mem_init+0x410>
f01017bf:	c7 44 24 0c a5 4e 10 	movl   $0xf0104ea5,0xc(%esp)
f01017c6:	f0 
f01017c7:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f01017ce:	f0 
f01017cf:	c7 44 24 04 d6 02 00 	movl   $0x2d6,0x4(%esp)
f01017d6:	00 
f01017d7:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f01017de:	e8 3e e9 ff ff       	call   f0100121 <_panic>
	assert((pp2 = page_alloc(0)));
f01017e3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017ea:	e8 bd f7 ff ff       	call   f0100fac <page_alloc>
f01017ef:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01017f2:	85 c0                	test   %eax,%eax
f01017f4:	75 24                	jne    f010181a <mem_init+0x447>
f01017f6:	c7 44 24 0c bb 4e 10 	movl   $0xf0104ebb,0xc(%esp)
f01017fd:	f0 
f01017fe:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101805:	f0 
f0101806:	c7 44 24 04 d7 02 00 	movl   $0x2d7,0x4(%esp)
f010180d:	00 
f010180e:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101815:	e8 07 e9 ff ff       	call   f0100121 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010181a:	39 fe                	cmp    %edi,%esi
f010181c:	75 24                	jne    f0101842 <mem_init+0x46f>
f010181e:	c7 44 24 0c d1 4e 10 	movl   $0xf0104ed1,0xc(%esp)
f0101825:	f0 
f0101826:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f010182d:	f0 
f010182e:	c7 44 24 04 d9 02 00 	movl   $0x2d9,0x4(%esp)
f0101835:	00 
f0101836:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f010183d:	e8 df e8 ff ff       	call   f0100121 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101842:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101845:	39 c7                	cmp    %eax,%edi
f0101847:	74 04                	je     f010184d <mem_init+0x47a>
f0101849:	39 c6                	cmp    %eax,%esi
f010184b:	75 24                	jne    f0101871 <mem_init+0x49e>
f010184d:	c7 44 24 0c a4 47 10 	movl   $0xf01047a4,0xc(%esp)
f0101854:	f0 
f0101855:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f010185c:	f0 
f010185d:	c7 44 24 04 da 02 00 	movl   $0x2da,0x4(%esp)
f0101864:	00 
f0101865:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f010186c:	e8 b0 e8 ff ff       	call   f0100121 <_panic>
	assert(!page_alloc(0));
f0101871:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101878:	e8 2f f7 ff ff       	call   f0100fac <page_alloc>
f010187d:	85 c0                	test   %eax,%eax
f010187f:	74 24                	je     f01018a5 <mem_init+0x4d2>
f0101881:	c7 44 24 0c 3a 4f 10 	movl   $0xf0104f3a,0xc(%esp)
f0101888:	f0 
f0101889:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101890:	f0 
f0101891:	c7 44 24 04 db 02 00 	movl   $0x2db,0x4(%esp)
f0101898:	00 
f0101899:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f01018a0:	e8 7c e8 ff ff       	call   f0100121 <_panic>
f01018a5:	89 f0                	mov    %esi,%eax
f01018a7:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f01018ad:	c1 f8 03             	sar    $0x3,%eax
f01018b0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01018b3:	89 c2                	mov    %eax,%edx
f01018b5:	c1 ea 0c             	shr    $0xc,%edx
f01018b8:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f01018be:	72 20                	jb     f01018e0 <mem_init+0x50d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01018c0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01018c4:	c7 44 24 08 24 45 10 	movl   $0xf0104524,0x8(%esp)
f01018cb:	f0 
f01018cc:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01018d3:	00 
f01018d4:	c7 04 24 90 4d 10 f0 	movl   $0xf0104d90,(%esp)
f01018db:	e8 41 e8 ff ff       	call   f0100121 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01018e0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01018e7:	00 
f01018e8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01018ef:	00 
	return (void *)(pa + KERNBASE);
f01018f0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01018f5:	89 04 24             	mov    %eax,(%esp)
f01018f8:	e8 2a 22 00 00       	call   f0103b27 <memset>
	page_free(pp0);
f01018fd:	89 34 24             	mov    %esi,(%esp)
f0101900:	e8 38 f7 ff ff       	call   f010103d <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101905:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010190c:	e8 9b f6 ff ff       	call   f0100fac <page_alloc>
f0101911:	85 c0                	test   %eax,%eax
f0101913:	75 24                	jne    f0101939 <mem_init+0x566>
f0101915:	c7 44 24 0c 49 4f 10 	movl   $0xf0104f49,0xc(%esp)
f010191c:	f0 
f010191d:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101924:	f0 
f0101925:	c7 44 24 04 e0 02 00 	movl   $0x2e0,0x4(%esp)
f010192c:	00 
f010192d:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101934:	e8 e8 e7 ff ff       	call   f0100121 <_panic>
	assert(pp && pp0 == pp);
f0101939:	39 c6                	cmp    %eax,%esi
f010193b:	74 24                	je     f0101961 <mem_init+0x58e>
f010193d:	c7 44 24 0c 67 4f 10 	movl   $0xf0104f67,0xc(%esp)
f0101944:	f0 
f0101945:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f010194c:	f0 
f010194d:	c7 44 24 04 e1 02 00 	movl   $0x2e1,0x4(%esp)
f0101954:	00 
f0101955:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f010195c:	e8 c0 e7 ff ff       	call   f0100121 <_panic>

//page2pa returns the relevant physical address of the page
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101961:	89 f0                	mov    %esi,%eax
f0101963:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0101969:	c1 f8 03             	sar    $0x3,%eax
f010196c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010196f:	89 c2                	mov    %eax,%edx
f0101971:	c1 ea 0c             	shr    $0xc,%edx
f0101974:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f010197a:	72 20                	jb     f010199c <mem_init+0x5c9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010197c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101980:	c7 44 24 08 24 45 10 	movl   $0xf0104524,0x8(%esp)
f0101987:	f0 
f0101988:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010198f:	00 
f0101990:	c7 04 24 90 4d 10 f0 	movl   $0xf0104d90,(%esp)
f0101997:	e8 85 e7 ff ff       	call   f0100121 <_panic>
f010199c:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01019a2:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01019a8:	80 38 00             	cmpb   $0x0,(%eax)
f01019ab:	74 24                	je     f01019d1 <mem_init+0x5fe>
f01019ad:	c7 44 24 0c 77 4f 10 	movl   $0xf0104f77,0xc(%esp)
f01019b4:	f0 
f01019b5:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f01019bc:	f0 
f01019bd:	c7 44 24 04 e4 02 00 	movl   $0x2e4,0x4(%esp)
f01019c4:	00 
f01019c5:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f01019cc:	e8 50 e7 ff ff       	call   f0100121 <_panic>
f01019d1:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01019d4:	39 d0                	cmp    %edx,%eax
f01019d6:	75 d0                	jne    f01019a8 <mem_init+0x5d5>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01019d8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01019db:	a3 40 85 11 f0       	mov    %eax,0xf0118540

	// free the pages we took
	page_free(pp0);
f01019e0:	89 34 24             	mov    %esi,(%esp)
f01019e3:	e8 55 f6 ff ff       	call   f010103d <page_free>
	page_free(pp1);
f01019e8:	89 3c 24             	mov    %edi,(%esp)
f01019eb:	e8 4d f6 ff ff       	call   f010103d <page_free>
	page_free(pp2);
f01019f0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019f3:	89 04 24             	mov    %eax,(%esp)
f01019f6:	e8 42 f6 ff ff       	call   f010103d <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01019fb:	a1 40 85 11 f0       	mov    0xf0118540,%eax
f0101a00:	eb 05                	jmp    f0101a07 <mem_init+0x634>
		--nfree;
f0101a02:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101a05:	8b 00                	mov    (%eax),%eax
f0101a07:	85 c0                	test   %eax,%eax
f0101a09:	75 f7                	jne    f0101a02 <mem_init+0x62f>
		--nfree;
	assert(nfree == 0);
f0101a0b:	85 db                	test   %ebx,%ebx
f0101a0d:	74 24                	je     f0101a33 <mem_init+0x660>
f0101a0f:	c7 44 24 0c 81 4f 10 	movl   $0xf0104f81,0xc(%esp)
f0101a16:	f0 
f0101a17:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101a1e:	f0 
f0101a1f:	c7 44 24 04 f1 02 00 	movl   $0x2f1,0x4(%esp)
f0101a26:	00 
f0101a27:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101a2e:	e8 ee e6 ff ff       	call   f0100121 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101a33:	c7 04 24 c4 47 10 f0 	movl   $0xf01047c4,(%esp)
f0101a3a:	e8 83 15 00 00       	call   f0102fc2 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101a3f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a46:	e8 61 f5 ff ff       	call   f0100fac <page_alloc>
f0101a4b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101a4e:	85 c0                	test   %eax,%eax
f0101a50:	75 24                	jne    f0101a76 <mem_init+0x6a3>
f0101a52:	c7 44 24 0c 8f 4e 10 	movl   $0xf0104e8f,0xc(%esp)
f0101a59:	f0 
f0101a5a:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101a61:	f0 
f0101a62:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f0101a69:	00 
f0101a6a:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101a71:	e8 ab e6 ff ff       	call   f0100121 <_panic>
	assert((pp1 = page_alloc(0)));
f0101a76:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a7d:	e8 2a f5 ff ff       	call   f0100fac <page_alloc>
f0101a82:	89 c3                	mov    %eax,%ebx
f0101a84:	85 c0                	test   %eax,%eax
f0101a86:	75 24                	jne    f0101aac <mem_init+0x6d9>
f0101a88:	c7 44 24 0c a5 4e 10 	movl   $0xf0104ea5,0xc(%esp)
f0101a8f:	f0 
f0101a90:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101a97:	f0 
f0101a98:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
f0101a9f:	00 
f0101aa0:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101aa7:	e8 75 e6 ff ff       	call   f0100121 <_panic>
	assert((pp2 = page_alloc(0)));
f0101aac:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ab3:	e8 f4 f4 ff ff       	call   f0100fac <page_alloc>
f0101ab8:	89 c6                	mov    %eax,%esi
f0101aba:	85 c0                	test   %eax,%eax
f0101abc:	75 24                	jne    f0101ae2 <mem_init+0x70f>
f0101abe:	c7 44 24 0c bb 4e 10 	movl   $0xf0104ebb,0xc(%esp)
f0101ac5:	f0 
f0101ac6:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101acd:	f0 
f0101ace:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0101ad5:	00 
f0101ad6:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101add:	e8 3f e6 ff ff       	call   f0100121 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101ae2:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101ae5:	75 24                	jne    f0101b0b <mem_init+0x738>
f0101ae7:	c7 44 24 0c d1 4e 10 	movl   $0xf0104ed1,0xc(%esp)
f0101aee:	f0 
f0101aef:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101af6:	f0 
f0101af7:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f0101afe:	00 
f0101aff:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101b06:	e8 16 e6 ff ff       	call   f0100121 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101b0b:	39 c3                	cmp    %eax,%ebx
f0101b0d:	74 05                	je     f0101b14 <mem_init+0x741>
f0101b0f:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101b12:	75 24                	jne    f0101b38 <mem_init+0x765>
f0101b14:	c7 44 24 0c a4 47 10 	movl   $0xf01047a4,0xc(%esp)
f0101b1b:	f0 
f0101b1c:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101b23:	f0 
f0101b24:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f0101b2b:	00 
f0101b2c:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101b33:	e8 e9 e5 ff ff       	call   f0100121 <_panic>
	

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101b38:	a1 40 85 11 f0       	mov    0xf0118540,%eax
f0101b3d:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101b40:	c7 05 40 85 11 f0 00 	movl   $0x0,0xf0118540
f0101b47:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101b4a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b51:	e8 56 f4 ff ff       	call   f0100fac <page_alloc>
f0101b56:	85 c0                	test   %eax,%eax
f0101b58:	74 24                	je     f0101b7e <mem_init+0x7ab>
f0101b5a:	c7 44 24 0c 3a 4f 10 	movl   $0xf0104f3a,0xc(%esp)
f0101b61:	f0 
f0101b62:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101b69:	f0 
f0101b6a:	c7 44 24 04 58 03 00 	movl   $0x358,0x4(%esp)
f0101b71:	00 
f0101b72:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101b79:	e8 a3 e5 ff ff       	call   f0100121 <_panic>
	
	
	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101b7e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101b81:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101b85:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101b8c:	00 
f0101b8d:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101b92:	89 04 24             	mov    %eax,(%esp)
f0101b95:	e8 e3 f6 ff ff       	call   f010127d <page_lookup>
f0101b9a:	85 c0                	test   %eax,%eax
f0101b9c:	74 24                	je     f0101bc2 <mem_init+0x7ef>
f0101b9e:	c7 44 24 0c e4 47 10 	movl   $0xf01047e4,0xc(%esp)
f0101ba5:	f0 
f0101ba6:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101bad:	f0 
f0101bae:	c7 44 24 04 5c 03 00 	movl   $0x35c,0x4(%esp)
f0101bb5:	00 
f0101bb6:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101bbd:	e8 5f e5 ff ff       	call   f0100121 <_panic>
	
	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101bc2:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101bc9:	00 
f0101bca:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101bd1:	00 
f0101bd2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101bd6:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101bdb:	89 04 24             	mov    %eax,(%esp)
f0101bde:	e8 2e f7 ff ff       	call   f0101311 <page_insert>
f0101be3:	85 c0                	test   %eax,%eax
f0101be5:	78 24                	js     f0101c0b <mem_init+0x838>
f0101be7:	c7 44 24 0c 1c 48 10 	movl   $0xf010481c,0xc(%esp)
f0101bee:	f0 
f0101bef:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101bf6:	f0 
f0101bf7:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f0101bfe:	00 
f0101bff:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101c06:	e8 16 e5 ff ff       	call   f0100121 <_panic>
	
	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101c0b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c0e:	89 04 24             	mov    %eax,(%esp)
f0101c11:	e8 27 f4 ff ff       	call   f010103d <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101c16:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c1d:	00 
f0101c1e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101c25:	00 
f0101c26:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101c2a:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101c2f:	89 04 24             	mov    %eax,(%esp)
f0101c32:	e8 da f6 ff ff       	call   f0101311 <page_insert>
f0101c37:	85 c0                	test   %eax,%eax
f0101c39:	74 24                	je     f0101c5f <mem_init+0x88c>
f0101c3b:	c7 44 24 0c 4c 48 10 	movl   $0xf010484c,0xc(%esp)
f0101c42:	f0 
f0101c43:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101c4a:	f0 
f0101c4b:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f0101c52:	00 
f0101c53:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101c5a:	e8 c2 e4 ff ff       	call   f0100121 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101c5f:	8b 3d 68 89 11 f0    	mov    0xf0118968,%edi

//page2pa returns the relevant physical address of the page
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101c65:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f0101c6a:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c6d:	8b 17                	mov    (%edi),%edx
f0101c6f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101c75:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101c78:	29 c1                	sub    %eax,%ecx
f0101c7a:	89 c8                	mov    %ecx,%eax
f0101c7c:	c1 f8 03             	sar    $0x3,%eax
f0101c7f:	c1 e0 0c             	shl    $0xc,%eax
f0101c82:	39 c2                	cmp    %eax,%edx
f0101c84:	74 24                	je     f0101caa <mem_init+0x8d7>
f0101c86:	c7 44 24 0c 7c 48 10 	movl   $0xf010487c,0xc(%esp)
f0101c8d:	f0 
f0101c8e:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101c95:	f0 
f0101c96:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f0101c9d:	00 
f0101c9e:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101ca5:	e8 77 e4 ff ff       	call   f0100121 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101caa:	ba 00 00 00 00       	mov    $0x0,%edx
f0101caf:	89 f8                	mov    %edi,%eax
f0101cb1:	e8 3f ed ff ff       	call   f01009f5 <check_va2pa>
f0101cb6:	89 da                	mov    %ebx,%edx
f0101cb8:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101cbb:	c1 fa 03             	sar    $0x3,%edx
f0101cbe:	c1 e2 0c             	shl    $0xc,%edx
f0101cc1:	39 d0                	cmp    %edx,%eax
f0101cc3:	74 24                	je     f0101ce9 <mem_init+0x916>
f0101cc5:	c7 44 24 0c a4 48 10 	movl   $0xf01048a4,0xc(%esp)
f0101ccc:	f0 
f0101ccd:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101cd4:	f0 
f0101cd5:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f0101cdc:	00 
f0101cdd:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101ce4:	e8 38 e4 ff ff       	call   f0100121 <_panic>
	assert(pp1->pp_ref == 1);
f0101ce9:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101cee:	74 24                	je     f0101d14 <mem_init+0x941>
f0101cf0:	c7 44 24 0c 8c 4f 10 	movl   $0xf0104f8c,0xc(%esp)
f0101cf7:	f0 
f0101cf8:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101cff:	f0 
f0101d00:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f0101d07:	00 
f0101d08:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101d0f:	e8 0d e4 ff ff       	call   f0100121 <_panic>
	assert(pp0->pp_ref == 1);
f0101d14:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d17:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101d1c:	74 24                	je     f0101d42 <mem_init+0x96f>
f0101d1e:	c7 44 24 0c 9d 4f 10 	movl   $0xf0104f9d,0xc(%esp)
f0101d25:	f0 
f0101d26:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101d2d:	f0 
f0101d2e:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f0101d35:	00 
f0101d36:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101d3d:	e8 df e3 ff ff       	call   f0100121 <_panic>
	
	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d42:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101d49:	00 
f0101d4a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101d51:	00 
f0101d52:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101d56:	89 3c 24             	mov    %edi,(%esp)
f0101d59:	e8 b3 f5 ff ff       	call   f0101311 <page_insert>
f0101d5e:	85 c0                	test   %eax,%eax
f0101d60:	74 24                	je     f0101d86 <mem_init+0x9b3>
f0101d62:	c7 44 24 0c d4 48 10 	movl   $0xf01048d4,0xc(%esp)
f0101d69:	f0 
f0101d6a:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101d71:	f0 
f0101d72:	c7 44 24 04 6a 03 00 	movl   $0x36a,0x4(%esp)
f0101d79:	00 
f0101d7a:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101d81:	e8 9b e3 ff ff       	call   f0100121 <_panic>

	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d86:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d8b:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101d90:	e8 60 ec ff ff       	call   f01009f5 <check_va2pa>
f0101d95:	89 f2                	mov    %esi,%edx
f0101d97:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0101d9d:	c1 fa 03             	sar    $0x3,%edx
f0101da0:	c1 e2 0c             	shl    $0xc,%edx
f0101da3:	39 d0                	cmp    %edx,%eax
f0101da5:	74 24                	je     f0101dcb <mem_init+0x9f8>
f0101da7:	c7 44 24 0c 10 49 10 	movl   $0xf0104910,0xc(%esp)
f0101dae:	f0 
f0101daf:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101db6:	f0 
f0101db7:	c7 44 24 04 6c 03 00 	movl   $0x36c,0x4(%esp)
f0101dbe:	00 
f0101dbf:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101dc6:	e8 56 e3 ff ff       	call   f0100121 <_panic>
	assert(pp2->pp_ref == 1);
f0101dcb:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101dd0:	74 24                	je     f0101df6 <mem_init+0xa23>
f0101dd2:	c7 44 24 0c ae 4f 10 	movl   $0xf0104fae,0xc(%esp)
f0101dd9:	f0 
f0101dda:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101de1:	f0 
f0101de2:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f0101de9:	00 
f0101dea:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101df1:	e8 2b e3 ff ff       	call   f0100121 <_panic>
	
	// should be no free memory
	assert(!page_alloc(0));
f0101df6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101dfd:	e8 aa f1 ff ff       	call   f0100fac <page_alloc>
f0101e02:	85 c0                	test   %eax,%eax
f0101e04:	74 24                	je     f0101e2a <mem_init+0xa57>
f0101e06:	c7 44 24 0c 3a 4f 10 	movl   $0xf0104f3a,0xc(%esp)
f0101e0d:	f0 
f0101e0e:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101e15:	f0 
f0101e16:	c7 44 24 04 70 03 00 	movl   $0x370,0x4(%esp)
f0101e1d:	00 
f0101e1e:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101e25:	e8 f7 e2 ff ff       	call   f0100121 <_panic>
	
	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e2a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e31:	00 
f0101e32:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e39:	00 
f0101e3a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101e3e:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101e43:	89 04 24             	mov    %eax,(%esp)
f0101e46:	e8 c6 f4 ff ff       	call   f0101311 <page_insert>
f0101e4b:	85 c0                	test   %eax,%eax
f0101e4d:	74 24                	je     f0101e73 <mem_init+0xaa0>
f0101e4f:	c7 44 24 0c d4 48 10 	movl   $0xf01048d4,0xc(%esp)
f0101e56:	f0 
f0101e57:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101e5e:	f0 
f0101e5f:	c7 44 24 04 73 03 00 	movl   $0x373,0x4(%esp)
f0101e66:	00 
f0101e67:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101e6e:	e8 ae e2 ff ff       	call   f0100121 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e73:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e78:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101e7d:	e8 73 eb ff ff       	call   f01009f5 <check_va2pa>
f0101e82:	89 f2                	mov    %esi,%edx
f0101e84:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0101e8a:	c1 fa 03             	sar    $0x3,%edx
f0101e8d:	c1 e2 0c             	shl    $0xc,%edx
f0101e90:	39 d0                	cmp    %edx,%eax
f0101e92:	74 24                	je     f0101eb8 <mem_init+0xae5>
f0101e94:	c7 44 24 0c 10 49 10 	movl   $0xf0104910,0xc(%esp)
f0101e9b:	f0 
f0101e9c:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101ea3:	f0 
f0101ea4:	c7 44 24 04 74 03 00 	movl   $0x374,0x4(%esp)
f0101eab:	00 
f0101eac:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101eb3:	e8 69 e2 ff ff       	call   f0100121 <_panic>
	assert(pp2->pp_ref == 1);
f0101eb8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ebd:	74 24                	je     f0101ee3 <mem_init+0xb10>
f0101ebf:	c7 44 24 0c ae 4f 10 	movl   $0xf0104fae,0xc(%esp)
f0101ec6:	f0 
f0101ec7:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101ece:	f0 
f0101ecf:	c7 44 24 04 75 03 00 	movl   $0x375,0x4(%esp)
f0101ed6:	00 
f0101ed7:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101ede:	e8 3e e2 ff ff       	call   f0100121 <_panic>
	
	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101ee3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101eea:	e8 bd f0 ff ff       	call   f0100fac <page_alloc>
f0101eef:	85 c0                	test   %eax,%eax
f0101ef1:	74 24                	je     f0101f17 <mem_init+0xb44>
f0101ef3:	c7 44 24 0c 3a 4f 10 	movl   $0xf0104f3a,0xc(%esp)
f0101efa:	f0 
f0101efb:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101f02:	f0 
f0101f03:	c7 44 24 04 79 03 00 	movl   $0x379,0x4(%esp)
f0101f0a:	00 
f0101f0b:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101f12:	e8 0a e2 ff ff       	call   f0100121 <_panic>
	
	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101f17:	8b 15 68 89 11 f0    	mov    0xf0118968,%edx
f0101f1d:	8b 02                	mov    (%edx),%eax
f0101f1f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f24:	89 c1                	mov    %eax,%ecx
f0101f26:	c1 e9 0c             	shr    $0xc,%ecx
f0101f29:	3b 0d 64 89 11 f0    	cmp    0xf0118964,%ecx
f0101f2f:	72 20                	jb     f0101f51 <mem_init+0xb7e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f31:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101f35:	c7 44 24 08 24 45 10 	movl   $0xf0104524,0x8(%esp)
f0101f3c:	f0 
f0101f3d:	c7 44 24 04 7c 03 00 	movl   $0x37c,0x4(%esp)
f0101f44:	00 
f0101f45:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101f4c:	e8 d0 e1 ff ff       	call   f0100121 <_panic>
	return (void *)(pa + KERNBASE);
f0101f51:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101f56:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101f59:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f60:	00 
f0101f61:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f68:	00 
f0101f69:	89 14 24             	mov    %edx,(%esp)
f0101f6c:	e8 4a f1 ff ff       	call   f01010bb <pgdir_walk>
f0101f71:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101f74:	8d 57 04             	lea    0x4(%edi),%edx
f0101f77:	39 d0                	cmp    %edx,%eax
f0101f79:	74 24                	je     f0101f9f <mem_init+0xbcc>
f0101f7b:	c7 44 24 0c 40 49 10 	movl   $0xf0104940,0xc(%esp)
f0101f82:	f0 
f0101f83:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101f8a:	f0 
f0101f8b:	c7 44 24 04 7d 03 00 	movl   $0x37d,0x4(%esp)
f0101f92:	00 
f0101f93:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101f9a:	e8 82 e1 ff ff       	call   f0100121 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101f9f:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101fa6:	00 
f0101fa7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101fae:	00 
f0101faf:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101fb3:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101fb8:	89 04 24             	mov    %eax,(%esp)
f0101fbb:	e8 51 f3 ff ff       	call   f0101311 <page_insert>
f0101fc0:	85 c0                	test   %eax,%eax
f0101fc2:	74 24                	je     f0101fe8 <mem_init+0xc15>
f0101fc4:	c7 44 24 0c 80 49 10 	movl   $0xf0104980,0xc(%esp)
f0101fcb:	f0 
f0101fcc:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0101fd3:	f0 
f0101fd4:	c7 44 24 04 80 03 00 	movl   $0x380,0x4(%esp)
f0101fdb:	00 
f0101fdc:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0101fe3:	e8 39 e1 ff ff       	call   f0100121 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101fe8:	8b 3d 68 89 11 f0    	mov    0xf0118968,%edi
f0101fee:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ff3:	89 f8                	mov    %edi,%eax
f0101ff5:	e8 fb e9 ff ff       	call   f01009f5 <check_va2pa>

//page2pa returns the relevant physical address of the page
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101ffa:	89 f2                	mov    %esi,%edx
f0101ffc:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0102002:	c1 fa 03             	sar    $0x3,%edx
f0102005:	c1 e2 0c             	shl    $0xc,%edx
f0102008:	39 d0                	cmp    %edx,%eax
f010200a:	74 24                	je     f0102030 <mem_init+0xc5d>
f010200c:	c7 44 24 0c 10 49 10 	movl   $0xf0104910,0xc(%esp)
f0102013:	f0 
f0102014:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f010201b:	f0 
f010201c:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f0102023:	00 
f0102024:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f010202b:	e8 f1 e0 ff ff       	call   f0100121 <_panic>
	assert(pp2->pp_ref == 1);
f0102030:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102035:	74 24                	je     f010205b <mem_init+0xc88>
f0102037:	c7 44 24 0c ae 4f 10 	movl   $0xf0104fae,0xc(%esp)
f010203e:	f0 
f010203f:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102046:	f0 
f0102047:	c7 44 24 04 82 03 00 	movl   $0x382,0x4(%esp)
f010204e:	00 
f010204f:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102056:	e8 c6 e0 ff ff       	call   f0100121 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f010205b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102062:	00 
f0102063:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010206a:	00 
f010206b:	89 3c 24             	mov    %edi,(%esp)
f010206e:	e8 48 f0 ff ff       	call   f01010bb <pgdir_walk>
f0102073:	f6 00 04             	testb  $0x4,(%eax)
f0102076:	75 24                	jne    f010209c <mem_init+0xcc9>
f0102078:	c7 44 24 0c c0 49 10 	movl   $0xf01049c0,0xc(%esp)
f010207f:	f0 
f0102080:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102087:	f0 
f0102088:	c7 44 24 04 83 03 00 	movl   $0x383,0x4(%esp)
f010208f:	00 
f0102090:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102097:	e8 85 e0 ff ff       	call   f0100121 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f010209c:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01020a1:	f6 00 04             	testb  $0x4,(%eax)
f01020a4:	75 24                	jne    f01020ca <mem_init+0xcf7>
f01020a6:	c7 44 24 0c bf 4f 10 	movl   $0xf0104fbf,0xc(%esp)
f01020ad:	f0 
f01020ae:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f01020b5:	f0 
f01020b6:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f01020bd:	00 
f01020be:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f01020c5:	e8 57 e0 ff ff       	call   f0100121 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01020ca:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01020d1:	00 
f01020d2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01020d9:	00 
f01020da:	89 74 24 04          	mov    %esi,0x4(%esp)
f01020de:	89 04 24             	mov    %eax,(%esp)
f01020e1:	e8 2b f2 ff ff       	call   f0101311 <page_insert>
f01020e6:	85 c0                	test   %eax,%eax
f01020e8:	74 24                	je     f010210e <mem_init+0xd3b>
f01020ea:	c7 44 24 0c d4 48 10 	movl   $0xf01048d4,0xc(%esp)
f01020f1:	f0 
f01020f2:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f01020f9:	f0 
f01020fa:	c7 44 24 04 87 03 00 	movl   $0x387,0x4(%esp)
f0102101:	00 
f0102102:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102109:	e8 13 e0 ff ff       	call   f0100121 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f010210e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102115:	00 
f0102116:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010211d:	00 
f010211e:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102123:	89 04 24             	mov    %eax,(%esp)
f0102126:	e8 90 ef ff ff       	call   f01010bb <pgdir_walk>
f010212b:	f6 00 02             	testb  $0x2,(%eax)
f010212e:	75 24                	jne    f0102154 <mem_init+0xd81>
f0102130:	c7 44 24 0c f4 49 10 	movl   $0xf01049f4,0xc(%esp)
f0102137:	f0 
f0102138:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f010213f:	f0 
f0102140:	c7 44 24 04 88 03 00 	movl   $0x388,0x4(%esp)
f0102147:	00 
f0102148:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f010214f:	e8 cd df ff ff       	call   f0100121 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102154:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010215b:	00 
f010215c:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102163:	00 
f0102164:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102169:	89 04 24             	mov    %eax,(%esp)
f010216c:	e8 4a ef ff ff       	call   f01010bb <pgdir_walk>
f0102171:	f6 00 04             	testb  $0x4,(%eax)
f0102174:	74 24                	je     f010219a <mem_init+0xdc7>
f0102176:	c7 44 24 0c 28 4a 10 	movl   $0xf0104a28,0xc(%esp)
f010217d:	f0 
f010217e:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102185:	f0 
f0102186:	c7 44 24 04 89 03 00 	movl   $0x389,0x4(%esp)
f010218d:	00 
f010218e:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102195:	e8 87 df ff ff       	call   f0100121 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f010219a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01021a1:	00 
f01021a2:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f01021a9:	00 
f01021aa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021ad:	89 44 24 04          	mov    %eax,0x4(%esp)
f01021b1:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01021b6:	89 04 24             	mov    %eax,(%esp)
f01021b9:	e8 53 f1 ff ff       	call   f0101311 <page_insert>
f01021be:	85 c0                	test   %eax,%eax
f01021c0:	78 24                	js     f01021e6 <mem_init+0xe13>
f01021c2:	c7 44 24 0c 60 4a 10 	movl   $0xf0104a60,0xc(%esp)
f01021c9:	f0 
f01021ca:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f01021d1:	f0 
f01021d2:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f01021d9:	00 
f01021da:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f01021e1:	e8 3b df ff ff       	call   f0100121 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01021e6:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01021ed:	00 
f01021ee:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01021f5:	00 
f01021f6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01021fa:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01021ff:	89 04 24             	mov    %eax,(%esp)
f0102202:	e8 0a f1 ff ff       	call   f0101311 <page_insert>
f0102207:	85 c0                	test   %eax,%eax
f0102209:	74 24                	je     f010222f <mem_init+0xe5c>
f010220b:	c7 44 24 0c 98 4a 10 	movl   $0xf0104a98,0xc(%esp)
f0102212:	f0 
f0102213:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f010221a:	f0 
f010221b:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f0102222:	00 
f0102223:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f010222a:	e8 f2 de ff ff       	call   f0100121 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010222f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102236:	00 
f0102237:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010223e:	00 
f010223f:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102244:	89 04 24             	mov    %eax,(%esp)
f0102247:	e8 6f ee ff ff       	call   f01010bb <pgdir_walk>
f010224c:	f6 00 04             	testb  $0x4,(%eax)
f010224f:	74 24                	je     f0102275 <mem_init+0xea2>
f0102251:	c7 44 24 0c 28 4a 10 	movl   $0xf0104a28,0xc(%esp)
f0102258:	f0 
f0102259:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102260:	f0 
f0102261:	c7 44 24 04 90 03 00 	movl   $0x390,0x4(%esp)
f0102268:	00 
f0102269:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102270:	e8 ac de ff ff       	call   f0100121 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102275:	8b 3d 68 89 11 f0    	mov    0xf0118968,%edi
f010227b:	ba 00 00 00 00       	mov    $0x0,%edx
f0102280:	89 f8                	mov    %edi,%eax
f0102282:	e8 6e e7 ff ff       	call   f01009f5 <check_va2pa>
f0102287:	89 c1                	mov    %eax,%ecx
f0102289:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010228c:	89 d8                	mov    %ebx,%eax
f010228e:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0102294:	c1 f8 03             	sar    $0x3,%eax
f0102297:	c1 e0 0c             	shl    $0xc,%eax
f010229a:	39 c1                	cmp    %eax,%ecx
f010229c:	74 24                	je     f01022c2 <mem_init+0xeef>
f010229e:	c7 44 24 0c d4 4a 10 	movl   $0xf0104ad4,0xc(%esp)
f01022a5:	f0 
f01022a6:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f01022ad:	f0 
f01022ae:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f01022b5:	00 
f01022b6:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f01022bd:	e8 5f de ff ff       	call   f0100121 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01022c2:	ba 00 10 00 00       	mov    $0x1000,%edx
f01022c7:	89 f8                	mov    %edi,%eax
f01022c9:	e8 27 e7 ff ff       	call   f01009f5 <check_va2pa>
f01022ce:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f01022d1:	74 24                	je     f01022f7 <mem_init+0xf24>
f01022d3:	c7 44 24 0c 00 4b 10 	movl   $0xf0104b00,0xc(%esp)
f01022da:	f0 
f01022db:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f01022e2:	f0 
f01022e3:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f01022ea:	00 
f01022eb:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f01022f2:	e8 2a de ff ff       	call   f0100121 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01022f7:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f01022fc:	74 24                	je     f0102322 <mem_init+0xf4f>
f01022fe:	c7 44 24 0c d5 4f 10 	movl   $0xf0104fd5,0xc(%esp)
f0102305:	f0 
f0102306:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f010230d:	f0 
f010230e:	c7 44 24 04 96 03 00 	movl   $0x396,0x4(%esp)
f0102315:	00 
f0102316:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f010231d:	e8 ff dd ff ff       	call   f0100121 <_panic>
	assert(pp2->pp_ref == 0);
f0102322:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102327:	74 24                	je     f010234d <mem_init+0xf7a>
f0102329:	c7 44 24 0c e6 4f 10 	movl   $0xf0104fe6,0xc(%esp)
f0102330:	f0 
f0102331:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102338:	f0 
f0102339:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f0102340:	00 
f0102341:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102348:	e8 d4 dd ff ff       	call   f0100121 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f010234d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102354:	e8 53 ec ff ff       	call   f0100fac <page_alloc>
f0102359:	85 c0                	test   %eax,%eax
f010235b:	74 04                	je     f0102361 <mem_init+0xf8e>
f010235d:	39 c6                	cmp    %eax,%esi
f010235f:	74 24                	je     f0102385 <mem_init+0xfb2>
f0102361:	c7 44 24 0c 30 4b 10 	movl   $0xf0104b30,0xc(%esp)
f0102368:	f0 
f0102369:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102370:	f0 
f0102371:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f0102378:	00 
f0102379:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102380:	e8 9c dd ff ff       	call   f0100121 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102385:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010238c:	00 
f010238d:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102392:	89 04 24             	mov    %eax,(%esp)
f0102395:	e8 39 ef ff ff       	call   f01012d3 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010239a:	8b 3d 68 89 11 f0    	mov    0xf0118968,%edi
f01023a0:	ba 00 00 00 00       	mov    $0x0,%edx
f01023a5:	89 f8                	mov    %edi,%eax
f01023a7:	e8 49 e6 ff ff       	call   f01009f5 <check_va2pa>
f01023ac:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023af:	74 24                	je     f01023d5 <mem_init+0x1002>
f01023b1:	c7 44 24 0c 54 4b 10 	movl   $0xf0104b54,0xc(%esp)
f01023b8:	f0 
f01023b9:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f01023c0:	f0 
f01023c1:	c7 44 24 04 9e 03 00 	movl   $0x39e,0x4(%esp)
f01023c8:	00 
f01023c9:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f01023d0:	e8 4c dd ff ff       	call   f0100121 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01023d5:	ba 00 10 00 00       	mov    $0x1000,%edx
f01023da:	89 f8                	mov    %edi,%eax
f01023dc:	e8 14 e6 ff ff       	call   f01009f5 <check_va2pa>
f01023e1:	89 da                	mov    %ebx,%edx
f01023e3:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f01023e9:	c1 fa 03             	sar    $0x3,%edx
f01023ec:	c1 e2 0c             	shl    $0xc,%edx
f01023ef:	39 d0                	cmp    %edx,%eax
f01023f1:	74 24                	je     f0102417 <mem_init+0x1044>
f01023f3:	c7 44 24 0c 00 4b 10 	movl   $0xf0104b00,0xc(%esp)
f01023fa:	f0 
f01023fb:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102402:	f0 
f0102403:	c7 44 24 04 9f 03 00 	movl   $0x39f,0x4(%esp)
f010240a:	00 
f010240b:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102412:	e8 0a dd ff ff       	call   f0100121 <_panic>
	assert(pp1->pp_ref == 1);
f0102417:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010241c:	74 24                	je     f0102442 <mem_init+0x106f>
f010241e:	c7 44 24 0c 8c 4f 10 	movl   $0xf0104f8c,0xc(%esp)
f0102425:	f0 
f0102426:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f010242d:	f0 
f010242e:	c7 44 24 04 a0 03 00 	movl   $0x3a0,0x4(%esp)
f0102435:	00 
f0102436:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f010243d:	e8 df dc ff ff       	call   f0100121 <_panic>
	assert(pp2->pp_ref == 0);
f0102442:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102447:	74 24                	je     f010246d <mem_init+0x109a>
f0102449:	c7 44 24 0c e6 4f 10 	movl   $0xf0104fe6,0xc(%esp)
f0102450:	f0 
f0102451:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102458:	f0 
f0102459:	c7 44 24 04 a1 03 00 	movl   $0x3a1,0x4(%esp)
f0102460:	00 
f0102461:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102468:	e8 b4 dc ff ff       	call   f0100121 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f010246d:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0102474:	00 
f0102475:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010247c:	00 
f010247d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102481:	89 3c 24             	mov    %edi,(%esp)
f0102484:	e8 88 ee ff ff       	call   f0101311 <page_insert>
f0102489:	85 c0                	test   %eax,%eax
f010248b:	74 24                	je     f01024b1 <mem_init+0x10de>
f010248d:	c7 44 24 0c 78 4b 10 	movl   $0xf0104b78,0xc(%esp)
f0102494:	f0 
f0102495:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f010249c:	f0 
f010249d:	c7 44 24 04 a4 03 00 	movl   $0x3a4,0x4(%esp)
f01024a4:	00 
f01024a5:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f01024ac:	e8 70 dc ff ff       	call   f0100121 <_panic>
	assert(pp1->pp_ref);
f01024b1:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01024b6:	75 24                	jne    f01024dc <mem_init+0x1109>
f01024b8:	c7 44 24 0c f7 4f 10 	movl   $0xf0104ff7,0xc(%esp)
f01024bf:	f0 
f01024c0:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f01024c7:	f0 
f01024c8:	c7 44 24 04 a5 03 00 	movl   $0x3a5,0x4(%esp)
f01024cf:	00 
f01024d0:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f01024d7:	e8 45 dc ff ff       	call   f0100121 <_panic>
	assert(pp1->pp_link == NULL);
f01024dc:	83 3b 00             	cmpl   $0x0,(%ebx)
f01024df:	74 24                	je     f0102505 <mem_init+0x1132>
f01024e1:	c7 44 24 0c 03 50 10 	movl   $0xf0105003,0xc(%esp)
f01024e8:	f0 
f01024e9:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f01024f0:	f0 
f01024f1:	c7 44 24 04 a6 03 00 	movl   $0x3a6,0x4(%esp)
f01024f8:	00 
f01024f9:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102500:	e8 1c dc ff ff       	call   f0100121 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102505:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010250c:	00 
f010250d:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102512:	89 04 24             	mov    %eax,(%esp)
f0102515:	e8 b9 ed ff ff       	call   f01012d3 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010251a:	8b 3d 68 89 11 f0    	mov    0xf0118968,%edi
f0102520:	ba 00 00 00 00       	mov    $0x0,%edx
f0102525:	89 f8                	mov    %edi,%eax
f0102527:	e8 c9 e4 ff ff       	call   f01009f5 <check_va2pa>
f010252c:	83 f8 ff             	cmp    $0xffffffff,%eax
f010252f:	74 24                	je     f0102555 <mem_init+0x1182>
f0102531:	c7 44 24 0c 54 4b 10 	movl   $0xf0104b54,0xc(%esp)
f0102538:	f0 
f0102539:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102540:	f0 
f0102541:	c7 44 24 04 aa 03 00 	movl   $0x3aa,0x4(%esp)
f0102548:	00 
f0102549:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102550:	e8 cc db ff ff       	call   f0100121 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102555:	ba 00 10 00 00       	mov    $0x1000,%edx
f010255a:	89 f8                	mov    %edi,%eax
f010255c:	e8 94 e4 ff ff       	call   f01009f5 <check_va2pa>
f0102561:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102564:	74 24                	je     f010258a <mem_init+0x11b7>
f0102566:	c7 44 24 0c b0 4b 10 	movl   $0xf0104bb0,0xc(%esp)
f010256d:	f0 
f010256e:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102575:	f0 
f0102576:	c7 44 24 04 ab 03 00 	movl   $0x3ab,0x4(%esp)
f010257d:	00 
f010257e:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102585:	e8 97 db ff ff       	call   f0100121 <_panic>
	assert(pp1->pp_ref == 0);
f010258a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010258f:	74 24                	je     f01025b5 <mem_init+0x11e2>
f0102591:	c7 44 24 0c 18 50 10 	movl   $0xf0105018,0xc(%esp)
f0102598:	f0 
f0102599:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f01025a0:	f0 
f01025a1:	c7 44 24 04 ac 03 00 	movl   $0x3ac,0x4(%esp)
f01025a8:	00 
f01025a9:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f01025b0:	e8 6c db ff ff       	call   f0100121 <_panic>
	assert(pp2->pp_ref == 0);
f01025b5:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01025ba:	74 24                	je     f01025e0 <mem_init+0x120d>
f01025bc:	c7 44 24 0c e6 4f 10 	movl   $0xf0104fe6,0xc(%esp)
f01025c3:	f0 
f01025c4:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f01025cb:	f0 
f01025cc:	c7 44 24 04 ad 03 00 	movl   $0x3ad,0x4(%esp)
f01025d3:	00 
f01025d4:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f01025db:	e8 41 db ff ff       	call   f0100121 <_panic>
	
	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01025e0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01025e7:	e8 c0 e9 ff ff       	call   f0100fac <page_alloc>
f01025ec:	85 c0                	test   %eax,%eax
f01025ee:	74 04                	je     f01025f4 <mem_init+0x1221>
f01025f0:	39 c3                	cmp    %eax,%ebx
f01025f2:	74 24                	je     f0102618 <mem_init+0x1245>
f01025f4:	c7 44 24 0c d8 4b 10 	movl   $0xf0104bd8,0xc(%esp)
f01025fb:	f0 
f01025fc:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102603:	f0 
f0102604:	c7 44 24 04 b0 03 00 	movl   $0x3b0,0x4(%esp)
f010260b:	00 
f010260c:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102613:	e8 09 db ff ff       	call   f0100121 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102618:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010261f:	e8 88 e9 ff ff       	call   f0100fac <page_alloc>
f0102624:	85 c0                	test   %eax,%eax
f0102626:	74 24                	je     f010264c <mem_init+0x1279>
f0102628:	c7 44 24 0c 3a 4f 10 	movl   $0xf0104f3a,0xc(%esp)
f010262f:	f0 
f0102630:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102637:	f0 
f0102638:	c7 44 24 04 b3 03 00 	movl   $0x3b3,0x4(%esp)
f010263f:	00 
f0102640:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102647:	e8 d5 da ff ff       	call   f0100121 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010264c:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102651:	8b 08                	mov    (%eax),%ecx
f0102653:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102659:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010265c:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0102662:	c1 fa 03             	sar    $0x3,%edx
f0102665:	c1 e2 0c             	shl    $0xc,%edx
f0102668:	39 d1                	cmp    %edx,%ecx
f010266a:	74 24                	je     f0102690 <mem_init+0x12bd>
f010266c:	c7 44 24 0c 7c 48 10 	movl   $0xf010487c,0xc(%esp)
f0102673:	f0 
f0102674:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f010267b:	f0 
f010267c:	c7 44 24 04 b6 03 00 	movl   $0x3b6,0x4(%esp)
f0102683:	00 
f0102684:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f010268b:	e8 91 da ff ff       	call   f0100121 <_panic>
	kern_pgdir[0] = 0;
f0102690:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102696:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102699:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010269e:	74 24                	je     f01026c4 <mem_init+0x12f1>
f01026a0:	c7 44 24 0c 9d 4f 10 	movl   $0xf0104f9d,0xc(%esp)
f01026a7:	f0 
f01026a8:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f01026af:	f0 
f01026b0:	c7 44 24 04 b8 03 00 	movl   $0x3b8,0x4(%esp)
f01026b7:	00 
f01026b8:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f01026bf:	e8 5d da ff ff       	call   f0100121 <_panic>
	pp0->pp_ref = 0;
f01026c4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01026c7:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01026cd:	89 04 24             	mov    %eax,(%esp)
f01026d0:	e8 68 e9 ff ff       	call   f010103d <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01026d5:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01026dc:	00 
f01026dd:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f01026e4:	00 
f01026e5:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01026ea:	89 04 24             	mov    %eax,(%esp)
f01026ed:	e8 c9 e9 ff ff       	call   f01010bb <pgdir_walk>
f01026f2:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01026f5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01026f8:	8b 15 68 89 11 f0    	mov    0xf0118968,%edx
f01026fe:	8b 7a 04             	mov    0x4(%edx),%edi
f0102701:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102707:	8b 0d 64 89 11 f0    	mov    0xf0118964,%ecx
f010270d:	89 f8                	mov    %edi,%eax
f010270f:	c1 e8 0c             	shr    $0xc,%eax
f0102712:	39 c8                	cmp    %ecx,%eax
f0102714:	72 20                	jb     f0102736 <mem_init+0x1363>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102716:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010271a:	c7 44 24 08 24 45 10 	movl   $0xf0104524,0x8(%esp)
f0102721:	f0 
f0102722:	c7 44 24 04 bf 03 00 	movl   $0x3bf,0x4(%esp)
f0102729:	00 
f010272a:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102731:	e8 eb d9 ff ff       	call   f0100121 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102736:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f010273c:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f010273f:	74 24                	je     f0102765 <mem_init+0x1392>
f0102741:	c7 44 24 0c 29 50 10 	movl   $0xf0105029,0xc(%esp)
f0102748:	f0 
f0102749:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102750:	f0 
f0102751:	c7 44 24 04 c0 03 00 	movl   $0x3c0,0x4(%esp)
f0102758:	00 
f0102759:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102760:	e8 bc d9 ff ff       	call   f0100121 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102765:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f010276c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010276f:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

//page2pa returns the relevant physical address of the page
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102775:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f010277b:	c1 f8 03             	sar    $0x3,%eax
f010277e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102781:	89 c2                	mov    %eax,%edx
f0102783:	c1 ea 0c             	shr    $0xc,%edx
f0102786:	39 d1                	cmp    %edx,%ecx
f0102788:	77 20                	ja     f01027aa <mem_init+0x13d7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010278a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010278e:	c7 44 24 08 24 45 10 	movl   $0xf0104524,0x8(%esp)
f0102795:	f0 
f0102796:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010279d:	00 
f010279e:	c7 04 24 90 4d 10 f0 	movl   $0xf0104d90,(%esp)
f01027a5:	e8 77 d9 ff ff       	call   f0100121 <_panic>
	
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01027aa:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01027b1:	00 
f01027b2:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f01027b9:	00 
	return (void *)(pa + KERNBASE);
f01027ba:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01027bf:	89 04 24             	mov    %eax,(%esp)
f01027c2:	e8 60 13 00 00       	call   f0103b27 <memset>
	page_free(pp0);
f01027c7:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01027ca:	89 3c 24             	mov    %edi,(%esp)
f01027cd:	e8 6b e8 ff ff       	call   f010103d <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01027d2:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01027d9:	00 
f01027da:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01027e1:	00 
f01027e2:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01027e7:	89 04 24             	mov    %eax,(%esp)
f01027ea:	e8 cc e8 ff ff       	call   f01010bb <pgdir_walk>

//page2pa returns the relevant physical address of the page
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01027ef:	89 fa                	mov    %edi,%edx
f01027f1:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f01027f7:	c1 fa 03             	sar    $0x3,%edx
f01027fa:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01027fd:	89 d0                	mov    %edx,%eax
f01027ff:	c1 e8 0c             	shr    $0xc,%eax
f0102802:	3b 05 64 89 11 f0    	cmp    0xf0118964,%eax
f0102808:	72 20                	jb     f010282a <mem_init+0x1457>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010280a:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010280e:	c7 44 24 08 24 45 10 	movl   $0xf0104524,0x8(%esp)
f0102815:	f0 
f0102816:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010281d:	00 
f010281e:	c7 04 24 90 4d 10 f0 	movl   $0xf0104d90,(%esp)
f0102825:	e8 f7 d8 ff ff       	call   f0100121 <_panic>
	return (void *)(pa + KERNBASE);
f010282a:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102830:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102833:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102839:	f6 00 01             	testb  $0x1,(%eax)
f010283c:	74 24                	je     f0102862 <mem_init+0x148f>
f010283e:	c7 44 24 0c 41 50 10 	movl   $0xf0105041,0xc(%esp)
f0102845:	f0 
f0102846:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f010284d:	f0 
f010284e:	c7 44 24 04 ca 03 00 	movl   $0x3ca,0x4(%esp)
f0102855:	00 
f0102856:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f010285d:	e8 bf d8 ff ff       	call   f0100121 <_panic>
f0102862:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102865:	39 d0                	cmp    %edx,%eax
f0102867:	75 d0                	jne    f0102839 <mem_init+0x1466>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102869:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f010286e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102874:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102877:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010287d:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102880:	89 0d 40 85 11 f0    	mov    %ecx,0xf0118540

	// free the pages we took
	page_free(pp0);
f0102886:	89 04 24             	mov    %eax,(%esp)
f0102889:	e8 af e7 ff ff       	call   f010103d <page_free>
	page_free(pp1);
f010288e:	89 1c 24             	mov    %ebx,(%esp)
f0102891:	e8 a7 e7 ff ff       	call   f010103d <page_free>
	page_free(pp2);
f0102896:	89 34 24             	mov    %esi,(%esp)
f0102899:	e8 9f e7 ff ff       	call   f010103d <page_free>

	cprintf("check_page() succeeded!\n");
f010289e:	c7 04 24 58 50 10 f0 	movl   $0xf0105058,(%esp)
f01028a5:	e8 18 07 00 00       	call   f0102fc2 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, sizeof(struct PageInfo) * npages,PADDR(pages), PTE_U | PTE_P);
f01028aa:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028af:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01028b4:	77 20                	ja     f01028d6 <mem_init+0x1503>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028b6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01028ba:	c7 44 24 08 48 45 10 	movl   $0xf0104548,0x8(%esp)
f01028c1:	f0 
f01028c2:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
f01028c9:	00 
f01028ca:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f01028d1:	e8 4b d8 ff ff       	call   f0100121 <_panic>
f01028d6:	8b 3d 64 89 11 f0    	mov    0xf0118964,%edi
f01028dc:	8d 0c fd 00 00 00 00 	lea    0x0(,%edi,8),%ecx
f01028e3:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f01028ea:	00 
	return (physaddr_t)kva - KERNBASE;
f01028eb:	05 00 00 00 10       	add    $0x10000000,%eax
f01028f0:	89 04 24             	mov    %eax,(%esp)
f01028f3:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01028f8:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01028fd:	e8 c8 e8 ff ff       	call   f01011ca <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102902:	bb 00 e0 10 f0       	mov    $0xf010e000,%ebx
f0102907:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f010290d:	77 20                	ja     f010292f <mem_init+0x155c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010290f:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102913:	c7 44 24 08 48 45 10 	movl   $0xf0104548,0x8(%esp)
f010291a:	f0 
f010291b:	c7 44 24 04 c5 00 00 	movl   $0xc5,0x4(%esp)
f0102922:	00 
f0102923:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f010292a:	e8 f2 d7 ff ff       	call   f0100121 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W | PTE_P);
f010292f:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102936:	00 
f0102937:	c7 04 24 00 e0 10 00 	movl   $0x10e000,(%esp)
f010293e:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102943:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102948:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f010294d:	e8 78 e8 ff ff       	call   f01011ca <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	size_t size = ROUNDUP(0xFFFFFFFF - KERNBASE + 1, PGSIZE);
	boot_map_region(kern_pgdir, KERNBASE, size, 0, PTE_W | PTE_P);
f0102952:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102959:	00 
f010295a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102961:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102966:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010296b:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102970:	e8 55 e8 ff ff       	call   f01011ca <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102975:	8b 3d 68 89 11 f0    	mov    0xf0118968,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010297b:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f0102980:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102983:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010298a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010298f:	89 45 d0             	mov    %eax,-0x30(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102992:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f0102997:	89 45 cc             	mov    %eax,-0x34(%ebp)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010299a:	89 45 c8             	mov    %eax,-0x38(%ebp)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f010299d:	05 00 00 00 10       	add    $0x10000000,%eax
f01029a2:	89 45 c4             	mov    %eax,-0x3c(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01029a5:	be 00 00 00 00       	mov    $0x0,%esi
f01029aa:	eb 6d                	jmp    f0102a19 <mem_init+0x1646>
f01029ac:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01029b2:	89 f8                	mov    %edi,%eax
f01029b4:	e8 3c e0 ff ff       	call   f01009f5 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01029b9:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f01029c0:	77 23                	ja     f01029e5 <mem_init+0x1612>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029c2:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01029c5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01029c9:	c7 44 24 08 48 45 10 	movl   $0xf0104548,0x8(%esp)
f01029d0:	f0 
f01029d1:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f01029d8:	00 
f01029d9:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f01029e0:	e8 3c d7 ff ff       	call   f0100121 <_panic>
f01029e5:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f01029e8:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01029eb:	39 c2                	cmp    %eax,%edx
f01029ed:	74 24                	je     f0102a13 <mem_init+0x1640>
f01029ef:	c7 44 24 0c fc 4b 10 	movl   $0xf0104bfc,0xc(%esp)
f01029f6:	f0 
f01029f7:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f01029fe:	f0 
f01029ff:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f0102a06:	00 
f0102a07:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102a0e:	e8 0e d7 ff ff       	call   f0100121 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102a13:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102a19:	39 75 d0             	cmp    %esi,-0x30(%ebp)
f0102a1c:	77 8e                	ja     f01029ac <mem_init+0x15d9>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a1e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a21:	c1 e0 0c             	shl    $0xc,%eax
f0102a24:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102a27:	be 00 00 00 00       	mov    $0x0,%esi
f0102a2c:	eb 3b                	jmp    f0102a69 <mem_init+0x1696>
f0102a2e:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102a34:	89 f8                	mov    %edi,%eax
f0102a36:	e8 ba df ff ff       	call   f01009f5 <check_va2pa>
f0102a3b:	39 c6                	cmp    %eax,%esi
f0102a3d:	74 24                	je     f0102a63 <mem_init+0x1690>
f0102a3f:	c7 44 24 0c 30 4c 10 	movl   $0xf0104c30,0xc(%esp)
f0102a46:	f0 
f0102a47:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102a4e:	f0 
f0102a4f:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
f0102a56:	00 
f0102a57:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102a5e:	e8 be d6 ff ff       	call   f0100121 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a63:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102a69:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0102a6c:	72 c0                	jb     f0102a2e <mem_init+0x165b>
f0102a6e:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102a73:	81 c3 00 80 00 20    	add    $0x20008000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102a79:	89 f2                	mov    %esi,%edx
f0102a7b:	89 f8                	mov    %edi,%eax
f0102a7d:	e8 73 df ff ff       	call   f01009f5 <check_va2pa>
f0102a82:	8d 14 33             	lea    (%ebx,%esi,1),%edx
f0102a85:	39 d0                	cmp    %edx,%eax
f0102a87:	74 24                	je     f0102aad <mem_init+0x16da>
f0102a89:	c7 44 24 0c 58 4c 10 	movl   $0xf0104c58,0xc(%esp)
f0102a90:	f0 
f0102a91:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102a98:	f0 
f0102a99:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f0102aa0:	00 
f0102aa1:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102aa8:	e8 74 d6 ff ff       	call   f0100121 <_panic>
f0102aad:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102ab3:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102ab9:	75 be                	jne    f0102a79 <mem_init+0x16a6>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102abb:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102ac0:	89 f8                	mov    %edi,%eax
f0102ac2:	e8 2e df ff ff       	call   f01009f5 <check_va2pa>
f0102ac7:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102aca:	75 0a                	jne    f0102ad6 <mem_init+0x1703>
f0102acc:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ad1:	e9 f0 00 00 00       	jmp    f0102bc6 <mem_init+0x17f3>
f0102ad6:	c7 44 24 0c a0 4c 10 	movl   $0xf0104ca0,0xc(%esp)
f0102add:	f0 
f0102ade:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102ae5:	f0 
f0102ae6:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
f0102aed:	00 
f0102aee:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102af5:	e8 27 d6 ff ff       	call   f0100121 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102afa:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102aff:	72 3c                	jb     f0102b3d <mem_init+0x176a>
f0102b01:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102b06:	76 07                	jbe    f0102b0f <mem_init+0x173c>
f0102b08:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102b0d:	75 2e                	jne    f0102b3d <mem_init+0x176a>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102b0f:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0102b13:	0f 85 aa 00 00 00    	jne    f0102bc3 <mem_init+0x17f0>
f0102b19:	c7 44 24 0c 71 50 10 	movl   $0xf0105071,0xc(%esp)
f0102b20:	f0 
f0102b21:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102b28:	f0 
f0102b29:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f0102b30:	00 
f0102b31:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102b38:	e8 e4 d5 ff ff       	call   f0100121 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102b3d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102b42:	76 55                	jbe    f0102b99 <mem_init+0x17c6>
				assert(pgdir[i] & PTE_P);
f0102b44:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0102b47:	f6 c2 01             	test   $0x1,%dl
f0102b4a:	75 24                	jne    f0102b70 <mem_init+0x179d>
f0102b4c:	c7 44 24 0c 71 50 10 	movl   $0xf0105071,0xc(%esp)
f0102b53:	f0 
f0102b54:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102b5b:	f0 
f0102b5c:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f0102b63:	00 
f0102b64:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102b6b:	e8 b1 d5 ff ff       	call   f0100121 <_panic>
				assert(pgdir[i] & PTE_W);
f0102b70:	f6 c2 02             	test   $0x2,%dl
f0102b73:	75 4e                	jne    f0102bc3 <mem_init+0x17f0>
f0102b75:	c7 44 24 0c 82 50 10 	movl   $0xf0105082,0xc(%esp)
f0102b7c:	f0 
f0102b7d:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102b84:	f0 
f0102b85:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f0102b8c:	00 
f0102b8d:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102b94:	e8 88 d5 ff ff       	call   f0100121 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102b99:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102b9d:	74 24                	je     f0102bc3 <mem_init+0x17f0>
f0102b9f:	c7 44 24 0c 93 50 10 	movl   $0xf0105093,0xc(%esp)
f0102ba6:	f0 
f0102ba7:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102bae:	f0 
f0102baf:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0102bb6:	00 
f0102bb7:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102bbe:	e8 5e d5 ff ff       	call   f0100121 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102bc3:	83 c0 01             	add    $0x1,%eax
f0102bc6:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102bcb:	0f 85 29 ff ff ff    	jne    f0102afa <mem_init+0x1727>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102bd1:	c7 04 24 d0 4c 10 f0 	movl   $0xf0104cd0,(%esp)
f0102bd8:	e8 e5 03 00 00       	call   f0102fc2 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102bdd:	a1 68 89 11 f0       	mov    0xf0118968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102be2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102be7:	77 20                	ja     f0102c09 <mem_init+0x1836>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102be9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102bed:	c7 44 24 08 48 45 10 	movl   $0xf0104548,0x8(%esp)
f0102bf4:	f0 
f0102bf5:	c7 44 24 04 da 00 00 	movl   $0xda,0x4(%esp)
f0102bfc:	00 
f0102bfd:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102c04:	e8 18 d5 ff ff       	call   f0100121 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102c09:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102c0e:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102c11:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c16:	e8 ce de ff ff       	call   f0100ae9 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102c1b:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102c1e:	83 e0 f3             	and    $0xfffffff3,%eax
f0102c21:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102c26:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102c29:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102c30:	e8 77 e3 ff ff       	call   f0100fac <page_alloc>
f0102c35:	89 c3                	mov    %eax,%ebx
f0102c37:	85 c0                	test   %eax,%eax
f0102c39:	75 24                	jne    f0102c5f <mem_init+0x188c>
f0102c3b:	c7 44 24 0c 8f 4e 10 	movl   $0xf0104e8f,0xc(%esp)
f0102c42:	f0 
f0102c43:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102c4a:	f0 
f0102c4b:	c7 44 24 04 e5 03 00 	movl   $0x3e5,0x4(%esp)
f0102c52:	00 
f0102c53:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102c5a:	e8 c2 d4 ff ff       	call   f0100121 <_panic>
	assert((pp1 = page_alloc(0)));
f0102c5f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102c66:	e8 41 e3 ff ff       	call   f0100fac <page_alloc>
f0102c6b:	89 c7                	mov    %eax,%edi
f0102c6d:	85 c0                	test   %eax,%eax
f0102c6f:	75 24                	jne    f0102c95 <mem_init+0x18c2>
f0102c71:	c7 44 24 0c a5 4e 10 	movl   $0xf0104ea5,0xc(%esp)
f0102c78:	f0 
f0102c79:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102c80:	f0 
f0102c81:	c7 44 24 04 e6 03 00 	movl   $0x3e6,0x4(%esp)
f0102c88:	00 
f0102c89:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102c90:	e8 8c d4 ff ff       	call   f0100121 <_panic>
	assert((pp2 = page_alloc(0)));
f0102c95:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102c9c:	e8 0b e3 ff ff       	call   f0100fac <page_alloc>
f0102ca1:	89 c6                	mov    %eax,%esi
f0102ca3:	85 c0                	test   %eax,%eax
f0102ca5:	75 24                	jne    f0102ccb <mem_init+0x18f8>
f0102ca7:	c7 44 24 0c bb 4e 10 	movl   $0xf0104ebb,0xc(%esp)
f0102cae:	f0 
f0102caf:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102cb6:	f0 
f0102cb7:	c7 44 24 04 e7 03 00 	movl   $0x3e7,0x4(%esp)
f0102cbe:	00 
f0102cbf:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102cc6:	e8 56 d4 ff ff       	call   f0100121 <_panic>
	page_free(pp0);
f0102ccb:	89 1c 24             	mov    %ebx,(%esp)
f0102cce:	e8 6a e3 ff ff       	call   f010103d <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0102cd3:	89 f8                	mov    %edi,%eax
f0102cd5:	e8 d6 dc ff ff       	call   f01009b0 <page2kva>
f0102cda:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102ce1:	00 
f0102ce2:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102ce9:	00 
f0102cea:	89 04 24             	mov    %eax,(%esp)
f0102ced:	e8 35 0e 00 00       	call   f0103b27 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0102cf2:	89 f0                	mov    %esi,%eax
f0102cf4:	e8 b7 dc ff ff       	call   f01009b0 <page2kva>
f0102cf9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102d00:	00 
f0102d01:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102d08:	00 
f0102d09:	89 04 24             	mov    %eax,(%esp)
f0102d0c:	e8 16 0e 00 00       	call   f0103b27 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102d11:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102d18:	00 
f0102d19:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102d20:	00 
f0102d21:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102d25:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102d2a:	89 04 24             	mov    %eax,(%esp)
f0102d2d:	e8 df e5 ff ff       	call   f0101311 <page_insert>
	assert(pp1->pp_ref == 1);
f0102d32:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102d37:	74 24                	je     f0102d5d <mem_init+0x198a>
f0102d39:	c7 44 24 0c 8c 4f 10 	movl   $0xf0104f8c,0xc(%esp)
f0102d40:	f0 
f0102d41:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102d48:	f0 
f0102d49:	c7 44 24 04 ec 03 00 	movl   $0x3ec,0x4(%esp)
f0102d50:	00 
f0102d51:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102d58:	e8 c4 d3 ff ff       	call   f0100121 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102d5d:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102d64:	01 01 01 
f0102d67:	74 24                	je     f0102d8d <mem_init+0x19ba>
f0102d69:	c7 44 24 0c f0 4c 10 	movl   $0xf0104cf0,0xc(%esp)
f0102d70:	f0 
f0102d71:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102d78:	f0 
f0102d79:	c7 44 24 04 ed 03 00 	movl   $0x3ed,0x4(%esp)
f0102d80:	00 
f0102d81:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102d88:	e8 94 d3 ff ff       	call   f0100121 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102d8d:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102d94:	00 
f0102d95:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102d9c:	00 
f0102d9d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102da1:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102da6:	89 04 24             	mov    %eax,(%esp)
f0102da9:	e8 63 e5 ff ff       	call   f0101311 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102dae:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102db5:	02 02 02 
f0102db8:	74 24                	je     f0102dde <mem_init+0x1a0b>
f0102dba:	c7 44 24 0c 14 4d 10 	movl   $0xf0104d14,0xc(%esp)
f0102dc1:	f0 
f0102dc2:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102dc9:	f0 
f0102dca:	c7 44 24 04 ef 03 00 	movl   $0x3ef,0x4(%esp)
f0102dd1:	00 
f0102dd2:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102dd9:	e8 43 d3 ff ff       	call   f0100121 <_panic>
	assert(pp2->pp_ref == 1);
f0102dde:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102de3:	74 24                	je     f0102e09 <mem_init+0x1a36>
f0102de5:	c7 44 24 0c ae 4f 10 	movl   $0xf0104fae,0xc(%esp)
f0102dec:	f0 
f0102ded:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102df4:	f0 
f0102df5:	c7 44 24 04 f0 03 00 	movl   $0x3f0,0x4(%esp)
f0102dfc:	00 
f0102dfd:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102e04:	e8 18 d3 ff ff       	call   f0100121 <_panic>
	assert(pp1->pp_ref == 0);
f0102e09:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102e0e:	74 24                	je     f0102e34 <mem_init+0x1a61>
f0102e10:	c7 44 24 0c 18 50 10 	movl   $0xf0105018,0xc(%esp)
f0102e17:	f0 
f0102e18:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102e1f:	f0 
f0102e20:	c7 44 24 04 f1 03 00 	movl   $0x3f1,0x4(%esp)
f0102e27:	00 
f0102e28:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102e2f:	e8 ed d2 ff ff       	call   f0100121 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102e34:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102e3b:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102e3e:	89 f0                	mov    %esi,%eax
f0102e40:	e8 6b db ff ff       	call   f01009b0 <page2kva>
f0102e45:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0102e4b:	74 24                	je     f0102e71 <mem_init+0x1a9e>
f0102e4d:	c7 44 24 0c 38 4d 10 	movl   $0xf0104d38,0xc(%esp)
f0102e54:	f0 
f0102e55:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102e5c:	f0 
f0102e5d:	c7 44 24 04 f3 03 00 	movl   $0x3f3,0x4(%esp)
f0102e64:	00 
f0102e65:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102e6c:	e8 b0 d2 ff ff       	call   f0100121 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102e71:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102e78:	00 
f0102e79:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102e7e:	89 04 24             	mov    %eax,(%esp)
f0102e81:	e8 4d e4 ff ff       	call   f01012d3 <page_remove>
	assert(pp2->pp_ref == 0);
f0102e86:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102e8b:	74 24                	je     f0102eb1 <mem_init+0x1ade>
f0102e8d:	c7 44 24 0c e6 4f 10 	movl   $0xf0104fe6,0xc(%esp)
f0102e94:	f0 
f0102e95:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102e9c:	f0 
f0102e9d:	c7 44 24 04 f5 03 00 	movl   $0x3f5,0x4(%esp)
f0102ea4:	00 
f0102ea5:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102eac:	e8 70 d2 ff ff       	call   f0100121 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102eb1:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102eb6:	8b 08                	mov    (%eax),%ecx
f0102eb8:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx

//page2pa returns the relevant physical address of the page
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102ebe:	89 da                	mov    %ebx,%edx
f0102ec0:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0102ec6:	c1 fa 03             	sar    $0x3,%edx
f0102ec9:	c1 e2 0c             	shl    $0xc,%edx
f0102ecc:	39 d1                	cmp    %edx,%ecx
f0102ece:	74 24                	je     f0102ef4 <mem_init+0x1b21>
f0102ed0:	c7 44 24 0c 7c 48 10 	movl   $0xf010487c,0xc(%esp)
f0102ed7:	f0 
f0102ed8:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102edf:	f0 
f0102ee0:	c7 44 24 04 f8 03 00 	movl   $0x3f8,0x4(%esp)
f0102ee7:	00 
f0102ee8:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102eef:	e8 2d d2 ff ff       	call   f0100121 <_panic>
	kern_pgdir[0] = 0;
f0102ef4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102efa:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102eff:	74 24                	je     f0102f25 <mem_init+0x1b52>
f0102f01:	c7 44 24 0c 9d 4f 10 	movl   $0xf0104f9d,0xc(%esp)
f0102f08:	f0 
f0102f09:	c7 44 24 08 b6 4d 10 	movl   $0xf0104db6,0x8(%esp)
f0102f10:	f0 
f0102f11:	c7 44 24 04 fa 03 00 	movl   $0x3fa,0x4(%esp)
f0102f18:	00 
f0102f19:	c7 04 24 9e 4d 10 f0 	movl   $0xf0104d9e,(%esp)
f0102f20:	e8 fc d1 ff ff       	call   f0100121 <_panic>
	pp0->pp_ref = 0;
f0102f25:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102f2b:	89 1c 24             	mov    %ebx,(%esp)
f0102f2e:	e8 0a e1 ff ff       	call   f010103d <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102f33:	c7 04 24 64 4d 10 f0 	movl   $0xf0104d64,(%esp)
f0102f3a:	e8 83 00 00 00       	call   f0102fc2 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102f3f:	83 c4 4c             	add    $0x4c,%esp
f0102f42:	5b                   	pop    %ebx
f0102f43:	5e                   	pop    %esi
f0102f44:	5f                   	pop    %edi
f0102f45:	5d                   	pop    %ebp
f0102f46:	c3                   	ret    

f0102f47 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102f47:	55                   	push   %ebp
f0102f48:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102f4a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f4d:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102f50:	5d                   	pop    %ebp
f0102f51:	c3                   	ret    

f0102f52 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102f52:	55                   	push   %ebp
f0102f53:	89 e5                	mov    %esp,%ebp
f0102f55:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102f59:	ba 70 00 00 00       	mov    $0x70,%edx
f0102f5e:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102f5f:	b2 71                	mov    $0x71,%dl
f0102f61:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102f62:	0f b6 c0             	movzbl %al,%eax
}
f0102f65:	5d                   	pop    %ebp
f0102f66:	c3                   	ret    

f0102f67 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102f67:	55                   	push   %ebp
f0102f68:	89 e5                	mov    %esp,%ebp
f0102f6a:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102f6e:	ba 70 00 00 00       	mov    $0x70,%edx
f0102f73:	ee                   	out    %al,(%dx)
f0102f74:	b2 71                	mov    $0x71,%dl
f0102f76:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f79:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102f7a:	5d                   	pop    %ebp
f0102f7b:	c3                   	ret    

f0102f7c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102f7c:	55                   	push   %ebp
f0102f7d:	89 e5                	mov    %esp,%ebp
f0102f7f:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102f82:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f85:	89 04 24             	mov    %eax,(%esp)
f0102f88:	e8 f4 d6 ff ff       	call   f0100681 <cputchar>
	*cnt++;
}
f0102f8d:	c9                   	leave  
f0102f8e:	c3                   	ret    

f0102f8f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102f8f:	55                   	push   %ebp
f0102f90:	89 e5                	mov    %esp,%ebp
f0102f92:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102f95:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102f9c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f9f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102fa3:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fa6:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102faa:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102fad:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102fb1:	c7 04 24 7c 2f 10 f0 	movl   $0xf0102f7c,(%esp)
f0102fb8:	e8 b1 04 00 00       	call   f010346e <vprintfmt>
	return cnt;
}
f0102fbd:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102fc0:	c9                   	leave  
f0102fc1:	c3                   	ret    

f0102fc2 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102fc2:	55                   	push   %ebp
f0102fc3:	89 e5                	mov    %esp,%ebp
f0102fc5:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102fc8:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102fcb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102fcf:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fd2:	89 04 24             	mov    %eax,(%esp)
f0102fd5:	e8 b5 ff ff ff       	call   f0102f8f <vcprintf>
	va_end(ap);

	return cnt;
}
f0102fda:	c9                   	leave  
f0102fdb:	c3                   	ret    

f0102fdc <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102fdc:	55                   	push   %ebp
f0102fdd:	89 e5                	mov    %esp,%ebp
f0102fdf:	57                   	push   %edi
f0102fe0:	56                   	push   %esi
f0102fe1:	53                   	push   %ebx
f0102fe2:	83 ec 10             	sub    $0x10,%esp
f0102fe5:	89 c6                	mov    %eax,%esi
f0102fe7:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102fea:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102fed:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102ff0:	8b 1a                	mov    (%edx),%ebx
f0102ff2:	8b 01                	mov    (%ecx),%eax
f0102ff4:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102ff7:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0102ffe:	eb 77                	jmp    f0103077 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0103000:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103003:	01 d8                	add    %ebx,%eax
f0103005:	b9 02 00 00 00       	mov    $0x2,%ecx
f010300a:	99                   	cltd   
f010300b:	f7 f9                	idiv   %ecx
f010300d:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010300f:	eb 01                	jmp    f0103012 <stab_binsearch+0x36>
			m--;
f0103011:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103012:	39 d9                	cmp    %ebx,%ecx
f0103014:	7c 1d                	jl     f0103033 <stab_binsearch+0x57>
f0103016:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0103019:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f010301e:	39 fa                	cmp    %edi,%edx
f0103020:	75 ef                	jne    f0103011 <stab_binsearch+0x35>
f0103022:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103025:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0103028:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f010302c:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010302f:	73 18                	jae    f0103049 <stab_binsearch+0x6d>
f0103031:	eb 05                	jmp    f0103038 <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103033:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0103036:	eb 3f                	jmp    f0103077 <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0103038:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f010303b:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f010303d:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103040:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0103047:	eb 2e                	jmp    f0103077 <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103049:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010304c:	73 15                	jae    f0103063 <stab_binsearch+0x87>
			*region_right = m - 1;
f010304e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103051:	48                   	dec    %eax
f0103052:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103055:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103058:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010305a:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0103061:	eb 14                	jmp    f0103077 <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103063:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103066:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0103069:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f010306b:	ff 45 0c             	incl   0xc(%ebp)
f010306e:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103070:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103077:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010307a:	7e 84                	jle    f0103000 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010307c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0103080:	75 0d                	jne    f010308f <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0103082:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103085:	8b 00                	mov    (%eax),%eax
f0103087:	48                   	dec    %eax
f0103088:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010308b:	89 07                	mov    %eax,(%edi)
f010308d:	eb 22                	jmp    f01030b1 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010308f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103092:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103094:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0103097:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103099:	eb 01                	jmp    f010309c <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010309b:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010309c:	39 c1                	cmp    %eax,%ecx
f010309e:	7d 0c                	jge    f01030ac <stab_binsearch+0xd0>
f01030a0:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f01030a3:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f01030a8:	39 fa                	cmp    %edi,%edx
f01030aa:	75 ef                	jne    f010309b <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f01030ac:	8b 7d e8             	mov    -0x18(%ebp),%edi
f01030af:	89 07                	mov    %eax,(%edi)
	}
}
f01030b1:	83 c4 10             	add    $0x10,%esp
f01030b4:	5b                   	pop    %ebx
f01030b5:	5e                   	pop    %esi
f01030b6:	5f                   	pop    %edi
f01030b7:	5d                   	pop    %ebp
f01030b8:	c3                   	ret    

f01030b9 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01030b9:	55                   	push   %ebp
f01030ba:	89 e5                	mov    %esp,%ebp
f01030bc:	57                   	push   %edi
f01030bd:	56                   	push   %esi
f01030be:	53                   	push   %ebx
f01030bf:	83 ec 3c             	sub    $0x3c,%esp
f01030c2:	8b 75 08             	mov    0x8(%ebp),%esi
f01030c5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01030c8:	c7 03 a1 50 10 f0    	movl   $0xf01050a1,(%ebx)
	info->eip_line = 0;
f01030ce:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01030d5:	c7 43 08 a1 50 10 f0 	movl   $0xf01050a1,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01030dc:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01030e3:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01030e6:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01030ed:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01030f3:	76 12                	jbe    f0103107 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01030f5:	b8 79 d0 10 f0       	mov    $0xf010d079,%eax
f01030fa:	3d 49 b2 10 f0       	cmp    $0xf010b249,%eax
f01030ff:	0f 86 cd 01 00 00    	jbe    f01032d2 <debuginfo_eip+0x219>
f0103105:	eb 1c                	jmp    f0103123 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0103107:	c7 44 24 08 ab 50 10 	movl   $0xf01050ab,0x8(%esp)
f010310e:	f0 
f010310f:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0103116:	00 
f0103117:	c7 04 24 b8 50 10 f0 	movl   $0xf01050b8,(%esp)
f010311e:	e8 fe cf ff ff       	call   f0100121 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103123:	80 3d 78 d0 10 f0 00 	cmpb   $0x0,0xf010d078
f010312a:	0f 85 a9 01 00 00    	jne    f01032d9 <debuginfo_eip+0x220>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103130:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103137:	b8 48 b2 10 f0       	mov    $0xf010b248,%eax
f010313c:	2d f0 52 10 f0       	sub    $0xf01052f0,%eax
f0103141:	c1 f8 02             	sar    $0x2,%eax
f0103144:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010314a:	83 e8 01             	sub    $0x1,%eax
f010314d:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103150:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103154:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f010315b:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f010315e:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103161:	b8 f0 52 10 f0       	mov    $0xf01052f0,%eax
f0103166:	e8 71 fe ff ff       	call   f0102fdc <stab_binsearch>
	if (lfile == 0)
f010316b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010316e:	85 c0                	test   %eax,%eax
f0103170:	0f 84 6a 01 00 00    	je     f01032e0 <debuginfo_eip+0x227>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103176:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103179:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010317c:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010317f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103183:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f010318a:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010318d:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103190:	b8 f0 52 10 f0       	mov    $0xf01052f0,%eax
f0103195:	e8 42 fe ff ff       	call   f0102fdc <stab_binsearch>

	if (lfun <= rfun) {
f010319a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010319d:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01031a0:	39 d0                	cmp    %edx,%eax
f01031a2:	7f 3d                	jg     f01031e1 <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01031a4:	6b c8 0c             	imul   $0xc,%eax,%ecx
f01031a7:	8d b9 f0 52 10 f0    	lea    -0xfefad10(%ecx),%edi
f01031ad:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f01031b0:	8b 89 f0 52 10 f0    	mov    -0xfefad10(%ecx),%ecx
f01031b6:	bf 79 d0 10 f0       	mov    $0xf010d079,%edi
f01031bb:	81 ef 49 b2 10 f0    	sub    $0xf010b249,%edi
f01031c1:	39 f9                	cmp    %edi,%ecx
f01031c3:	73 09                	jae    f01031ce <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01031c5:	81 c1 49 b2 10 f0    	add    $0xf010b249,%ecx
f01031cb:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01031ce:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01031d1:	8b 4f 08             	mov    0x8(%edi),%ecx
f01031d4:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01031d7:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01031d9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01031dc:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01031df:	eb 0f                	jmp    f01031f0 <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01031e1:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01031e4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031e7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01031ea:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01031ed:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01031f0:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f01031f7:	00 
f01031f8:	8b 43 08             	mov    0x8(%ebx),%eax
f01031fb:	89 04 24             	mov    %eax,(%esp)
f01031fe:	e8 08 09 00 00       	call   f0103b0b <strfind>
f0103203:	2b 43 08             	sub    0x8(%ebx),%eax
f0103206:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
f0103209:	89 74 24 04          	mov    %esi,0x4(%esp)
f010320d:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0103214:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103217:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010321a:	b8 f0 52 10 f0       	mov    $0xf01052f0,%eax
f010321f:	e8 b8 fd ff ff       	call   f0102fdc <stab_binsearch>
	if (lline > rline) {
f0103224:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103227:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f010322a:	0f 8f b7 00 00 00    	jg     f01032e7 <debuginfo_eip+0x22e>
		return -1; //Did not find the line number in the stab
	}
	info->eip_line = stabs[lline].n_desc; //If found update the info object with the correct line number
f0103230:	6b c0 0c             	imul   $0xc,%eax,%eax
f0103233:	0f b7 80 f6 52 10 f0 	movzwl -0xfefad0a(%eax),%eax
f010323a:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010323d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103240:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0103243:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103246:	6b d0 0c             	imul   $0xc,%eax,%edx
f0103249:	81 c2 f0 52 10 f0    	add    $0xf01052f0,%edx
f010324f:	eb 06                	jmp    f0103257 <debuginfo_eip+0x19e>
f0103251:	83 e8 01             	sub    $0x1,%eax
f0103254:	83 ea 0c             	sub    $0xc,%edx
f0103257:	89 c6                	mov    %eax,%esi
f0103259:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f010325c:	7f 33                	jg     f0103291 <debuginfo_eip+0x1d8>
	       && stabs[lline].n_type != N_SOL
f010325e:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103262:	80 f9 84             	cmp    $0x84,%cl
f0103265:	74 0b                	je     f0103272 <debuginfo_eip+0x1b9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103267:	80 f9 64             	cmp    $0x64,%cl
f010326a:	75 e5                	jne    f0103251 <debuginfo_eip+0x198>
f010326c:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103270:	74 df                	je     f0103251 <debuginfo_eip+0x198>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103272:	6b f6 0c             	imul   $0xc,%esi,%esi
f0103275:	8b 86 f0 52 10 f0    	mov    -0xfefad10(%esi),%eax
f010327b:	ba 79 d0 10 f0       	mov    $0xf010d079,%edx
f0103280:	81 ea 49 b2 10 f0    	sub    $0xf010b249,%edx
f0103286:	39 d0                	cmp    %edx,%eax
f0103288:	73 07                	jae    f0103291 <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010328a:	05 49 b2 10 f0       	add    $0xf010b249,%eax
f010328f:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103291:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103294:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103297:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010329c:	39 ca                	cmp    %ecx,%edx
f010329e:	7d 53                	jge    f01032f3 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
f01032a0:	8d 42 01             	lea    0x1(%edx),%eax
f01032a3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01032a6:	89 c2                	mov    %eax,%edx
f01032a8:	6b c0 0c             	imul   $0xc,%eax,%eax
f01032ab:	05 f0 52 10 f0       	add    $0xf01052f0,%eax
f01032b0:	89 ce                	mov    %ecx,%esi
f01032b2:	eb 04                	jmp    f01032b8 <debuginfo_eip+0x1ff>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01032b4:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01032b8:	39 d6                	cmp    %edx,%esi
f01032ba:	7e 32                	jle    f01032ee <debuginfo_eip+0x235>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01032bc:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f01032c0:	83 c2 01             	add    $0x1,%edx
f01032c3:	83 c0 0c             	add    $0xc,%eax
f01032c6:	80 f9 a0             	cmp    $0xa0,%cl
f01032c9:	74 e9                	je     f01032b4 <debuginfo_eip+0x1fb>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01032cb:	b8 00 00 00 00       	mov    $0x0,%eax
f01032d0:	eb 21                	jmp    f01032f3 <debuginfo_eip+0x23a>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01032d2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01032d7:	eb 1a                	jmp    f01032f3 <debuginfo_eip+0x23a>
f01032d9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01032de:	eb 13                	jmp    f01032f3 <debuginfo_eip+0x23a>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01032e0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01032e5:	eb 0c                	jmp    f01032f3 <debuginfo_eip+0x23a>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
	if (lline > rline) {
		return -1; //Did not find the line number in the stab
f01032e7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01032ec:	eb 05                	jmp    f01032f3 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01032ee:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01032f3:	83 c4 3c             	add    $0x3c,%esp
f01032f6:	5b                   	pop    %ebx
f01032f7:	5e                   	pop    %esi
f01032f8:	5f                   	pop    %edi
f01032f9:	5d                   	pop    %ebp
f01032fa:	c3                   	ret    
f01032fb:	66 90                	xchg   %ax,%ax
f01032fd:	66 90                	xchg   %ax,%ax
f01032ff:	90                   	nop

f0103300 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103300:	55                   	push   %ebp
f0103301:	89 e5                	mov    %esp,%ebp
f0103303:	57                   	push   %edi
f0103304:	56                   	push   %esi
f0103305:	53                   	push   %ebx
f0103306:	83 ec 3c             	sub    $0x3c,%esp
f0103309:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010330c:	89 d7                	mov    %edx,%edi
f010330e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103311:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103314:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103317:	89 c3                	mov    %eax,%ebx
f0103319:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010331c:	8b 45 10             	mov    0x10(%ebp),%eax
f010331f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103322:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103327:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010332a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010332d:	39 d9                	cmp    %ebx,%ecx
f010332f:	72 05                	jb     f0103336 <printnum+0x36>
f0103331:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0103334:	77 69                	ja     f010339f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103336:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0103339:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010333d:	83 ee 01             	sub    $0x1,%esi
f0103340:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103344:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103348:	8b 44 24 08          	mov    0x8(%esp),%eax
f010334c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103350:	89 c3                	mov    %eax,%ebx
f0103352:	89 d6                	mov    %edx,%esi
f0103354:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103357:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010335a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010335e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103362:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103365:	89 04 24             	mov    %eax,(%esp)
f0103368:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010336b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010336f:	e8 bc 09 00 00       	call   f0103d30 <__udivdi3>
f0103374:	89 d9                	mov    %ebx,%ecx
f0103376:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010337a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010337e:	89 04 24             	mov    %eax,(%esp)
f0103381:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103385:	89 fa                	mov    %edi,%edx
f0103387:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010338a:	e8 71 ff ff ff       	call   f0103300 <printnum>
f010338f:	eb 1b                	jmp    f01033ac <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103391:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103395:	8b 45 18             	mov    0x18(%ebp),%eax
f0103398:	89 04 24             	mov    %eax,(%esp)
f010339b:	ff d3                	call   *%ebx
f010339d:	eb 03                	jmp    f01033a2 <printnum+0xa2>
f010339f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01033a2:	83 ee 01             	sub    $0x1,%esi
f01033a5:	85 f6                	test   %esi,%esi
f01033a7:	7f e8                	jg     f0103391 <printnum+0x91>
f01033a9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01033ac:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01033b0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01033b4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01033b7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01033ba:	89 44 24 08          	mov    %eax,0x8(%esp)
f01033be:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01033c2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01033c5:	89 04 24             	mov    %eax,(%esp)
f01033c8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01033cb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01033cf:	e8 8c 0a 00 00       	call   f0103e60 <__umoddi3>
f01033d4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01033d8:	0f be 80 c6 50 10 f0 	movsbl -0xfefaf3a(%eax),%eax
f01033df:	89 04 24             	mov    %eax,(%esp)
f01033e2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01033e5:	ff d0                	call   *%eax
}
f01033e7:	83 c4 3c             	add    $0x3c,%esp
f01033ea:	5b                   	pop    %ebx
f01033eb:	5e                   	pop    %esi
f01033ec:	5f                   	pop    %edi
f01033ed:	5d                   	pop    %ebp
f01033ee:	c3                   	ret    

f01033ef <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01033ef:	55                   	push   %ebp
f01033f0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01033f2:	83 fa 01             	cmp    $0x1,%edx
f01033f5:	7e 0e                	jle    f0103405 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01033f7:	8b 10                	mov    (%eax),%edx
f01033f9:	8d 4a 08             	lea    0x8(%edx),%ecx
f01033fc:	89 08                	mov    %ecx,(%eax)
f01033fe:	8b 02                	mov    (%edx),%eax
f0103400:	8b 52 04             	mov    0x4(%edx),%edx
f0103403:	eb 22                	jmp    f0103427 <getuint+0x38>
	else if (lflag)
f0103405:	85 d2                	test   %edx,%edx
f0103407:	74 10                	je     f0103419 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103409:	8b 10                	mov    (%eax),%edx
f010340b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010340e:	89 08                	mov    %ecx,(%eax)
f0103410:	8b 02                	mov    (%edx),%eax
f0103412:	ba 00 00 00 00       	mov    $0x0,%edx
f0103417:	eb 0e                	jmp    f0103427 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103419:	8b 10                	mov    (%eax),%edx
f010341b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010341e:	89 08                	mov    %ecx,(%eax)
f0103420:	8b 02                	mov    (%edx),%eax
f0103422:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103427:	5d                   	pop    %ebp
f0103428:	c3                   	ret    

f0103429 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103429:	55                   	push   %ebp
f010342a:	89 e5                	mov    %esp,%ebp
f010342c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010342f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103433:	8b 10                	mov    (%eax),%edx
f0103435:	3b 50 04             	cmp    0x4(%eax),%edx
f0103438:	73 0a                	jae    f0103444 <sprintputch+0x1b>
		*b->buf++ = ch;
f010343a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010343d:	89 08                	mov    %ecx,(%eax)
f010343f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103442:	88 02                	mov    %al,(%edx)
}
f0103444:	5d                   	pop    %ebp
f0103445:	c3                   	ret    

f0103446 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103446:	55                   	push   %ebp
f0103447:	89 e5                	mov    %esp,%ebp
f0103449:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f010344c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010344f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103453:	8b 45 10             	mov    0x10(%ebp),%eax
f0103456:	89 44 24 08          	mov    %eax,0x8(%esp)
f010345a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010345d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103461:	8b 45 08             	mov    0x8(%ebp),%eax
f0103464:	89 04 24             	mov    %eax,(%esp)
f0103467:	e8 02 00 00 00       	call   f010346e <vprintfmt>
	va_end(ap);
}
f010346c:	c9                   	leave  
f010346d:	c3                   	ret    

f010346e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010346e:	55                   	push   %ebp
f010346f:	89 e5                	mov    %esp,%ebp
f0103471:	57                   	push   %edi
f0103472:	56                   	push   %esi
f0103473:	53                   	push   %ebx
f0103474:	83 ec 3c             	sub    $0x3c,%esp
f0103477:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010347a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010347d:	eb 14                	jmp    f0103493 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010347f:	85 c0                	test   %eax,%eax
f0103481:	0f 84 b3 03 00 00    	je     f010383a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0103487:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010348b:	89 04 24             	mov    %eax,(%esp)
f010348e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103491:	89 f3                	mov    %esi,%ebx
f0103493:	8d 73 01             	lea    0x1(%ebx),%esi
f0103496:	0f b6 03             	movzbl (%ebx),%eax
f0103499:	83 f8 25             	cmp    $0x25,%eax
f010349c:	75 e1                	jne    f010347f <vprintfmt+0x11>
f010349e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f01034a2:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01034a9:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f01034b0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f01034b7:	ba 00 00 00 00       	mov    $0x0,%edx
f01034bc:	eb 1d                	jmp    f01034db <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034be:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f01034c0:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f01034c4:	eb 15                	jmp    f01034db <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034c6:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01034c8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f01034cc:	eb 0d                	jmp    f01034db <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01034ce:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01034d1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01034d4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034db:	8d 5e 01             	lea    0x1(%esi),%ebx
f01034de:	0f b6 0e             	movzbl (%esi),%ecx
f01034e1:	0f b6 c1             	movzbl %cl,%eax
f01034e4:	83 e9 23             	sub    $0x23,%ecx
f01034e7:	80 f9 55             	cmp    $0x55,%cl
f01034ea:	0f 87 2a 03 00 00    	ja     f010381a <vprintfmt+0x3ac>
f01034f0:	0f b6 c9             	movzbl %cl,%ecx
f01034f3:	ff 24 8d 60 51 10 f0 	jmp    *-0xfefaea0(,%ecx,4)
f01034fa:	89 de                	mov    %ebx,%esi
f01034fc:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103501:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0103504:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0103508:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f010350b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f010350e:	83 fb 09             	cmp    $0x9,%ebx
f0103511:	77 36                	ja     f0103549 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103513:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103516:	eb e9                	jmp    f0103501 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103518:	8b 45 14             	mov    0x14(%ebp),%eax
f010351b:	8d 48 04             	lea    0x4(%eax),%ecx
f010351e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103521:	8b 00                	mov    (%eax),%eax
f0103523:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103526:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103528:	eb 22                	jmp    f010354c <vprintfmt+0xde>
f010352a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010352d:	85 c9                	test   %ecx,%ecx
f010352f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103534:	0f 49 c1             	cmovns %ecx,%eax
f0103537:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010353a:	89 de                	mov    %ebx,%esi
f010353c:	eb 9d                	jmp    f01034db <vprintfmt+0x6d>
f010353e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103540:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0103547:	eb 92                	jmp    f01034db <vprintfmt+0x6d>
f0103549:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f010354c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103550:	79 89                	jns    f01034db <vprintfmt+0x6d>
f0103552:	e9 77 ff ff ff       	jmp    f01034ce <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103557:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010355a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010355c:	e9 7a ff ff ff       	jmp    f01034db <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103561:	8b 45 14             	mov    0x14(%ebp),%eax
f0103564:	8d 50 04             	lea    0x4(%eax),%edx
f0103567:	89 55 14             	mov    %edx,0x14(%ebp)
f010356a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010356e:	8b 00                	mov    (%eax),%eax
f0103570:	89 04 24             	mov    %eax,(%esp)
f0103573:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103576:	e9 18 ff ff ff       	jmp    f0103493 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010357b:	8b 45 14             	mov    0x14(%ebp),%eax
f010357e:	8d 50 04             	lea    0x4(%eax),%edx
f0103581:	89 55 14             	mov    %edx,0x14(%ebp)
f0103584:	8b 00                	mov    (%eax),%eax
f0103586:	99                   	cltd   
f0103587:	31 d0                	xor    %edx,%eax
f0103589:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010358b:	83 f8 07             	cmp    $0x7,%eax
f010358e:	7f 0b                	jg     f010359b <vprintfmt+0x12d>
f0103590:	8b 14 85 c0 52 10 f0 	mov    -0xfefad40(,%eax,4),%edx
f0103597:	85 d2                	test   %edx,%edx
f0103599:	75 20                	jne    f01035bb <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f010359b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010359f:	c7 44 24 08 de 50 10 	movl   $0xf01050de,0x8(%esp)
f01035a6:	f0 
f01035a7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01035ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01035ae:	89 04 24             	mov    %eax,(%esp)
f01035b1:	e8 90 fe ff ff       	call   f0103446 <printfmt>
f01035b6:	e9 d8 fe ff ff       	jmp    f0103493 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f01035bb:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01035bf:	c7 44 24 08 c8 4d 10 	movl   $0xf0104dc8,0x8(%esp)
f01035c6:	f0 
f01035c7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01035cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01035ce:	89 04 24             	mov    %eax,(%esp)
f01035d1:	e8 70 fe ff ff       	call   f0103446 <printfmt>
f01035d6:	e9 b8 fe ff ff       	jmp    f0103493 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01035db:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01035de:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01035e1:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01035e4:	8b 45 14             	mov    0x14(%ebp),%eax
f01035e7:	8d 50 04             	lea    0x4(%eax),%edx
f01035ea:	89 55 14             	mov    %edx,0x14(%ebp)
f01035ed:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f01035ef:	85 f6                	test   %esi,%esi
f01035f1:	b8 d7 50 10 f0       	mov    $0xf01050d7,%eax
f01035f6:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f01035f9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f01035fd:	0f 84 97 00 00 00    	je     f010369a <vprintfmt+0x22c>
f0103603:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0103607:	0f 8e 9b 00 00 00    	jle    f01036a8 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f010360d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103611:	89 34 24             	mov    %esi,(%esp)
f0103614:	e8 9f 03 00 00       	call   f01039b8 <strnlen>
f0103619:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010361c:	29 c2                	sub    %eax,%edx
f010361e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0103621:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0103625:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103628:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010362b:	8b 75 08             	mov    0x8(%ebp),%esi
f010362e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103631:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103633:	eb 0f                	jmp    f0103644 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0103635:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103639:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010363c:	89 04 24             	mov    %eax,(%esp)
f010363f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103641:	83 eb 01             	sub    $0x1,%ebx
f0103644:	85 db                	test   %ebx,%ebx
f0103646:	7f ed                	jg     f0103635 <vprintfmt+0x1c7>
f0103648:	8b 75 d8             	mov    -0x28(%ebp),%esi
f010364b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010364e:	85 d2                	test   %edx,%edx
f0103650:	b8 00 00 00 00       	mov    $0x0,%eax
f0103655:	0f 49 c2             	cmovns %edx,%eax
f0103658:	29 c2                	sub    %eax,%edx
f010365a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010365d:	89 d7                	mov    %edx,%edi
f010365f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103662:	eb 50                	jmp    f01036b4 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103664:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103668:	74 1e                	je     f0103688 <vprintfmt+0x21a>
f010366a:	0f be d2             	movsbl %dl,%edx
f010366d:	83 ea 20             	sub    $0x20,%edx
f0103670:	83 fa 5e             	cmp    $0x5e,%edx
f0103673:	76 13                	jbe    f0103688 <vprintfmt+0x21a>
					putch('?', putdat);
f0103675:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103678:	89 44 24 04          	mov    %eax,0x4(%esp)
f010367c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0103683:	ff 55 08             	call   *0x8(%ebp)
f0103686:	eb 0d                	jmp    f0103695 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0103688:	8b 55 0c             	mov    0xc(%ebp),%edx
f010368b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010368f:	89 04 24             	mov    %eax,(%esp)
f0103692:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103695:	83 ef 01             	sub    $0x1,%edi
f0103698:	eb 1a                	jmp    f01036b4 <vprintfmt+0x246>
f010369a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010369d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01036a0:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01036a3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01036a6:	eb 0c                	jmp    f01036b4 <vprintfmt+0x246>
f01036a8:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01036ab:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01036ae:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01036b1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01036b4:	83 c6 01             	add    $0x1,%esi
f01036b7:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f01036bb:	0f be c2             	movsbl %dl,%eax
f01036be:	85 c0                	test   %eax,%eax
f01036c0:	74 27                	je     f01036e9 <vprintfmt+0x27b>
f01036c2:	85 db                	test   %ebx,%ebx
f01036c4:	78 9e                	js     f0103664 <vprintfmt+0x1f6>
f01036c6:	83 eb 01             	sub    $0x1,%ebx
f01036c9:	79 99                	jns    f0103664 <vprintfmt+0x1f6>
f01036cb:	89 f8                	mov    %edi,%eax
f01036cd:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01036d0:	8b 75 08             	mov    0x8(%ebp),%esi
f01036d3:	89 c3                	mov    %eax,%ebx
f01036d5:	eb 1a                	jmp    f01036f1 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01036d7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01036db:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01036e2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01036e4:	83 eb 01             	sub    $0x1,%ebx
f01036e7:	eb 08                	jmp    f01036f1 <vprintfmt+0x283>
f01036e9:	89 fb                	mov    %edi,%ebx
f01036eb:	8b 75 08             	mov    0x8(%ebp),%esi
f01036ee:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01036f1:	85 db                	test   %ebx,%ebx
f01036f3:	7f e2                	jg     f01036d7 <vprintfmt+0x269>
f01036f5:	89 75 08             	mov    %esi,0x8(%ebp)
f01036f8:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01036fb:	e9 93 fd ff ff       	jmp    f0103493 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103700:	83 fa 01             	cmp    $0x1,%edx
f0103703:	7e 16                	jle    f010371b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0103705:	8b 45 14             	mov    0x14(%ebp),%eax
f0103708:	8d 50 08             	lea    0x8(%eax),%edx
f010370b:	89 55 14             	mov    %edx,0x14(%ebp)
f010370e:	8b 50 04             	mov    0x4(%eax),%edx
f0103711:	8b 00                	mov    (%eax),%eax
f0103713:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103716:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103719:	eb 32                	jmp    f010374d <vprintfmt+0x2df>
	else if (lflag)
f010371b:	85 d2                	test   %edx,%edx
f010371d:	74 18                	je     f0103737 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010371f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103722:	8d 50 04             	lea    0x4(%eax),%edx
f0103725:	89 55 14             	mov    %edx,0x14(%ebp)
f0103728:	8b 30                	mov    (%eax),%esi
f010372a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010372d:	89 f0                	mov    %esi,%eax
f010372f:	c1 f8 1f             	sar    $0x1f,%eax
f0103732:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103735:	eb 16                	jmp    f010374d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0103737:	8b 45 14             	mov    0x14(%ebp),%eax
f010373a:	8d 50 04             	lea    0x4(%eax),%edx
f010373d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103740:	8b 30                	mov    (%eax),%esi
f0103742:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0103745:	89 f0                	mov    %esi,%eax
f0103747:	c1 f8 1f             	sar    $0x1f,%eax
f010374a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010374d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103750:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103753:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103758:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010375c:	0f 89 80 00 00 00    	jns    f01037e2 <vprintfmt+0x374>
				putch('-', putdat);
f0103762:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103766:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010376d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0103770:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103773:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103776:	f7 d8                	neg    %eax
f0103778:	83 d2 00             	adc    $0x0,%edx
f010377b:	f7 da                	neg    %edx
			}
			base = 10;
f010377d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103782:	eb 5e                	jmp    f01037e2 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103784:	8d 45 14             	lea    0x14(%ebp),%eax
f0103787:	e8 63 fc ff ff       	call   f01033ef <getuint>
			base = 10;
f010378c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103791:	eb 4f                	jmp    f01037e2 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0103793:	8d 45 14             	lea    0x14(%ebp),%eax
f0103796:	e8 54 fc ff ff       	call   f01033ef <getuint>
			base = 8;
f010379b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01037a0:	eb 40                	jmp    f01037e2 <vprintfmt+0x374>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f01037a2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01037a6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01037ad:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01037b0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01037b4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01037bb:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01037be:	8b 45 14             	mov    0x14(%ebp),%eax
f01037c1:	8d 50 04             	lea    0x4(%eax),%edx
f01037c4:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01037c7:	8b 00                	mov    (%eax),%eax
f01037c9:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01037ce:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01037d3:	eb 0d                	jmp    f01037e2 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01037d5:	8d 45 14             	lea    0x14(%ebp),%eax
f01037d8:	e8 12 fc ff ff       	call   f01033ef <getuint>
			base = 16;
f01037dd:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01037e2:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f01037e6:	89 74 24 10          	mov    %esi,0x10(%esp)
f01037ea:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01037ed:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01037f1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01037f5:	89 04 24             	mov    %eax,(%esp)
f01037f8:	89 54 24 04          	mov    %edx,0x4(%esp)
f01037fc:	89 fa                	mov    %edi,%edx
f01037fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0103801:	e8 fa fa ff ff       	call   f0103300 <printnum>
			break;
f0103806:	e9 88 fc ff ff       	jmp    f0103493 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010380b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010380f:	89 04 24             	mov    %eax,(%esp)
f0103812:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103815:	e9 79 fc ff ff       	jmp    f0103493 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010381a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010381e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103825:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103828:	89 f3                	mov    %esi,%ebx
f010382a:	eb 03                	jmp    f010382f <vprintfmt+0x3c1>
f010382c:	83 eb 01             	sub    $0x1,%ebx
f010382f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0103833:	75 f7                	jne    f010382c <vprintfmt+0x3be>
f0103835:	e9 59 fc ff ff       	jmp    f0103493 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010383a:	83 c4 3c             	add    $0x3c,%esp
f010383d:	5b                   	pop    %ebx
f010383e:	5e                   	pop    %esi
f010383f:	5f                   	pop    %edi
f0103840:	5d                   	pop    %ebp
f0103841:	c3                   	ret    

f0103842 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103842:	55                   	push   %ebp
f0103843:	89 e5                	mov    %esp,%ebp
f0103845:	83 ec 28             	sub    $0x28,%esp
f0103848:	8b 45 08             	mov    0x8(%ebp),%eax
f010384b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010384e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103851:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103855:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103858:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010385f:	85 c0                	test   %eax,%eax
f0103861:	74 30                	je     f0103893 <vsnprintf+0x51>
f0103863:	85 d2                	test   %edx,%edx
f0103865:	7e 2c                	jle    f0103893 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103867:	8b 45 14             	mov    0x14(%ebp),%eax
f010386a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010386e:	8b 45 10             	mov    0x10(%ebp),%eax
f0103871:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103875:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103878:	89 44 24 04          	mov    %eax,0x4(%esp)
f010387c:	c7 04 24 29 34 10 f0 	movl   $0xf0103429,(%esp)
f0103883:	e8 e6 fb ff ff       	call   f010346e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103888:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010388b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010388e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103891:	eb 05                	jmp    f0103898 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103893:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103898:	c9                   	leave  
f0103899:	c3                   	ret    

f010389a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010389a:	55                   	push   %ebp
f010389b:	89 e5                	mov    %esp,%ebp
f010389d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01038a0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01038a3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01038a7:	8b 45 10             	mov    0x10(%ebp),%eax
f01038aa:	89 44 24 08          	mov    %eax,0x8(%esp)
f01038ae:	8b 45 0c             	mov    0xc(%ebp),%eax
f01038b1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01038b8:	89 04 24             	mov    %eax,(%esp)
f01038bb:	e8 82 ff ff ff       	call   f0103842 <vsnprintf>
	va_end(ap);

	return rc;
}
f01038c0:	c9                   	leave  
f01038c1:	c3                   	ret    
f01038c2:	66 90                	xchg   %ax,%ax
f01038c4:	66 90                	xchg   %ax,%ax
f01038c6:	66 90                	xchg   %ax,%ax
f01038c8:	66 90                	xchg   %ax,%ax
f01038ca:	66 90                	xchg   %ax,%ax
f01038cc:	66 90                	xchg   %ax,%ax
f01038ce:	66 90                	xchg   %ax,%ax

f01038d0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01038d0:	55                   	push   %ebp
f01038d1:	89 e5                	mov    %esp,%ebp
f01038d3:	57                   	push   %edi
f01038d4:	56                   	push   %esi
f01038d5:	53                   	push   %ebx
f01038d6:	83 ec 1c             	sub    $0x1c,%esp
f01038d9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01038dc:	85 c0                	test   %eax,%eax
f01038de:	74 10                	je     f01038f0 <readline+0x20>
		cprintf("%s", prompt);
f01038e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038e4:	c7 04 24 c8 4d 10 f0 	movl   $0xf0104dc8,(%esp)
f01038eb:	e8 d2 f6 ff ff       	call   f0102fc2 <cprintf>

	i = 0;
	echoing = iscons(0);
f01038f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01038f7:	e8 a6 cd ff ff       	call   f01006a2 <iscons>
f01038fc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01038fe:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103903:	e8 89 cd ff ff       	call   f0100691 <getchar>
f0103908:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010390a:	85 c0                	test   %eax,%eax
f010390c:	79 17                	jns    f0103925 <readline+0x55>
			cprintf("read error: %e\n", c);
f010390e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103912:	c7 04 24 e0 52 10 f0 	movl   $0xf01052e0,(%esp)
f0103919:	e8 a4 f6 ff ff       	call   f0102fc2 <cprintf>
			return NULL;
f010391e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103923:	eb 6d                	jmp    f0103992 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103925:	83 f8 7f             	cmp    $0x7f,%eax
f0103928:	74 05                	je     f010392f <readline+0x5f>
f010392a:	83 f8 08             	cmp    $0x8,%eax
f010392d:	75 19                	jne    f0103948 <readline+0x78>
f010392f:	85 f6                	test   %esi,%esi
f0103931:	7e 15                	jle    f0103948 <readline+0x78>
			if (echoing)
f0103933:	85 ff                	test   %edi,%edi
f0103935:	74 0c                	je     f0103943 <readline+0x73>
				cputchar('\b');
f0103937:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010393e:	e8 3e cd ff ff       	call   f0100681 <cputchar>
			i--;
f0103943:	83 ee 01             	sub    $0x1,%esi
f0103946:	eb bb                	jmp    f0103903 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103948:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010394e:	7f 1c                	jg     f010396c <readline+0x9c>
f0103950:	83 fb 1f             	cmp    $0x1f,%ebx
f0103953:	7e 17                	jle    f010396c <readline+0x9c>
			if (echoing)
f0103955:	85 ff                	test   %edi,%edi
f0103957:	74 08                	je     f0103961 <readline+0x91>
				cputchar(c);
f0103959:	89 1c 24             	mov    %ebx,(%esp)
f010395c:	e8 20 cd ff ff       	call   f0100681 <cputchar>
			buf[i++] = c;
f0103961:	88 9e 60 85 11 f0    	mov    %bl,-0xfee7aa0(%esi)
f0103967:	8d 76 01             	lea    0x1(%esi),%esi
f010396a:	eb 97                	jmp    f0103903 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010396c:	83 fb 0d             	cmp    $0xd,%ebx
f010396f:	74 05                	je     f0103976 <readline+0xa6>
f0103971:	83 fb 0a             	cmp    $0xa,%ebx
f0103974:	75 8d                	jne    f0103903 <readline+0x33>
			if (echoing)
f0103976:	85 ff                	test   %edi,%edi
f0103978:	74 0c                	je     f0103986 <readline+0xb6>
				cputchar('\n');
f010397a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103981:	e8 fb cc ff ff       	call   f0100681 <cputchar>
			buf[i] = 0;
f0103986:	c6 86 60 85 11 f0 00 	movb   $0x0,-0xfee7aa0(%esi)
			return buf;
f010398d:	b8 60 85 11 f0       	mov    $0xf0118560,%eax
		}
	}
}
f0103992:	83 c4 1c             	add    $0x1c,%esp
f0103995:	5b                   	pop    %ebx
f0103996:	5e                   	pop    %esi
f0103997:	5f                   	pop    %edi
f0103998:	5d                   	pop    %ebp
f0103999:	c3                   	ret    
f010399a:	66 90                	xchg   %ax,%ax
f010399c:	66 90                	xchg   %ax,%ax
f010399e:	66 90                	xchg   %ax,%ax

f01039a0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01039a0:	55                   	push   %ebp
f01039a1:	89 e5                	mov    %esp,%ebp
f01039a3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01039a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01039ab:	eb 03                	jmp    f01039b0 <strlen+0x10>
		n++;
f01039ad:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01039b0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01039b4:	75 f7                	jne    f01039ad <strlen+0xd>
		n++;
	return n;
}
f01039b6:	5d                   	pop    %ebp
f01039b7:	c3                   	ret    

f01039b8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01039b8:	55                   	push   %ebp
f01039b9:	89 e5                	mov    %esp,%ebp
f01039bb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01039be:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01039c1:	b8 00 00 00 00       	mov    $0x0,%eax
f01039c6:	eb 03                	jmp    f01039cb <strnlen+0x13>
		n++;
f01039c8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01039cb:	39 d0                	cmp    %edx,%eax
f01039cd:	74 06                	je     f01039d5 <strnlen+0x1d>
f01039cf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01039d3:	75 f3                	jne    f01039c8 <strnlen+0x10>
		n++;
	return n;
}
f01039d5:	5d                   	pop    %ebp
f01039d6:	c3                   	ret    

f01039d7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01039d7:	55                   	push   %ebp
f01039d8:	89 e5                	mov    %esp,%ebp
f01039da:	53                   	push   %ebx
f01039db:	8b 45 08             	mov    0x8(%ebp),%eax
f01039de:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01039e1:	89 c2                	mov    %eax,%edx
f01039e3:	83 c2 01             	add    $0x1,%edx
f01039e6:	83 c1 01             	add    $0x1,%ecx
f01039e9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01039ed:	88 5a ff             	mov    %bl,-0x1(%edx)
f01039f0:	84 db                	test   %bl,%bl
f01039f2:	75 ef                	jne    f01039e3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01039f4:	5b                   	pop    %ebx
f01039f5:	5d                   	pop    %ebp
f01039f6:	c3                   	ret    

f01039f7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01039f7:	55                   	push   %ebp
f01039f8:	89 e5                	mov    %esp,%ebp
f01039fa:	53                   	push   %ebx
f01039fb:	83 ec 08             	sub    $0x8,%esp
f01039fe:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103a01:	89 1c 24             	mov    %ebx,(%esp)
f0103a04:	e8 97 ff ff ff       	call   f01039a0 <strlen>
	strcpy(dst + len, src);
f0103a09:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103a0c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103a10:	01 d8                	add    %ebx,%eax
f0103a12:	89 04 24             	mov    %eax,(%esp)
f0103a15:	e8 bd ff ff ff       	call   f01039d7 <strcpy>
	return dst;
}
f0103a1a:	89 d8                	mov    %ebx,%eax
f0103a1c:	83 c4 08             	add    $0x8,%esp
f0103a1f:	5b                   	pop    %ebx
f0103a20:	5d                   	pop    %ebp
f0103a21:	c3                   	ret    

f0103a22 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103a22:	55                   	push   %ebp
f0103a23:	89 e5                	mov    %esp,%ebp
f0103a25:	56                   	push   %esi
f0103a26:	53                   	push   %ebx
f0103a27:	8b 75 08             	mov    0x8(%ebp),%esi
f0103a2a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103a2d:	89 f3                	mov    %esi,%ebx
f0103a2f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103a32:	89 f2                	mov    %esi,%edx
f0103a34:	eb 0f                	jmp    f0103a45 <strncpy+0x23>
		*dst++ = *src;
f0103a36:	83 c2 01             	add    $0x1,%edx
f0103a39:	0f b6 01             	movzbl (%ecx),%eax
f0103a3c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103a3f:	80 39 01             	cmpb   $0x1,(%ecx)
f0103a42:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103a45:	39 da                	cmp    %ebx,%edx
f0103a47:	75 ed                	jne    f0103a36 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103a49:	89 f0                	mov    %esi,%eax
f0103a4b:	5b                   	pop    %ebx
f0103a4c:	5e                   	pop    %esi
f0103a4d:	5d                   	pop    %ebp
f0103a4e:	c3                   	ret    

f0103a4f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103a4f:	55                   	push   %ebp
f0103a50:	89 e5                	mov    %esp,%ebp
f0103a52:	56                   	push   %esi
f0103a53:	53                   	push   %ebx
f0103a54:	8b 75 08             	mov    0x8(%ebp),%esi
f0103a57:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103a5a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103a5d:	89 f0                	mov    %esi,%eax
f0103a5f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103a63:	85 c9                	test   %ecx,%ecx
f0103a65:	75 0b                	jne    f0103a72 <strlcpy+0x23>
f0103a67:	eb 1d                	jmp    f0103a86 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103a69:	83 c0 01             	add    $0x1,%eax
f0103a6c:	83 c2 01             	add    $0x1,%edx
f0103a6f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103a72:	39 d8                	cmp    %ebx,%eax
f0103a74:	74 0b                	je     f0103a81 <strlcpy+0x32>
f0103a76:	0f b6 0a             	movzbl (%edx),%ecx
f0103a79:	84 c9                	test   %cl,%cl
f0103a7b:	75 ec                	jne    f0103a69 <strlcpy+0x1a>
f0103a7d:	89 c2                	mov    %eax,%edx
f0103a7f:	eb 02                	jmp    f0103a83 <strlcpy+0x34>
f0103a81:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0103a83:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0103a86:	29 f0                	sub    %esi,%eax
}
f0103a88:	5b                   	pop    %ebx
f0103a89:	5e                   	pop    %esi
f0103a8a:	5d                   	pop    %ebp
f0103a8b:	c3                   	ret    

f0103a8c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103a8c:	55                   	push   %ebp
f0103a8d:	89 e5                	mov    %esp,%ebp
f0103a8f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103a92:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103a95:	eb 06                	jmp    f0103a9d <strcmp+0x11>
		p++, q++;
f0103a97:	83 c1 01             	add    $0x1,%ecx
f0103a9a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103a9d:	0f b6 01             	movzbl (%ecx),%eax
f0103aa0:	84 c0                	test   %al,%al
f0103aa2:	74 04                	je     f0103aa8 <strcmp+0x1c>
f0103aa4:	3a 02                	cmp    (%edx),%al
f0103aa6:	74 ef                	je     f0103a97 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103aa8:	0f b6 c0             	movzbl %al,%eax
f0103aab:	0f b6 12             	movzbl (%edx),%edx
f0103aae:	29 d0                	sub    %edx,%eax
}
f0103ab0:	5d                   	pop    %ebp
f0103ab1:	c3                   	ret    

f0103ab2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103ab2:	55                   	push   %ebp
f0103ab3:	89 e5                	mov    %esp,%ebp
f0103ab5:	53                   	push   %ebx
f0103ab6:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ab9:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103abc:	89 c3                	mov    %eax,%ebx
f0103abe:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103ac1:	eb 06                	jmp    f0103ac9 <strncmp+0x17>
		n--, p++, q++;
f0103ac3:	83 c0 01             	add    $0x1,%eax
f0103ac6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103ac9:	39 d8                	cmp    %ebx,%eax
f0103acb:	74 15                	je     f0103ae2 <strncmp+0x30>
f0103acd:	0f b6 08             	movzbl (%eax),%ecx
f0103ad0:	84 c9                	test   %cl,%cl
f0103ad2:	74 04                	je     f0103ad8 <strncmp+0x26>
f0103ad4:	3a 0a                	cmp    (%edx),%cl
f0103ad6:	74 eb                	je     f0103ac3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103ad8:	0f b6 00             	movzbl (%eax),%eax
f0103adb:	0f b6 12             	movzbl (%edx),%edx
f0103ade:	29 d0                	sub    %edx,%eax
f0103ae0:	eb 05                	jmp    f0103ae7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103ae2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103ae7:	5b                   	pop    %ebx
f0103ae8:	5d                   	pop    %ebp
f0103ae9:	c3                   	ret    

f0103aea <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103aea:	55                   	push   %ebp
f0103aeb:	89 e5                	mov    %esp,%ebp
f0103aed:	8b 45 08             	mov    0x8(%ebp),%eax
f0103af0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103af4:	eb 07                	jmp    f0103afd <strchr+0x13>
		if (*s == c)
f0103af6:	38 ca                	cmp    %cl,%dl
f0103af8:	74 0f                	je     f0103b09 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103afa:	83 c0 01             	add    $0x1,%eax
f0103afd:	0f b6 10             	movzbl (%eax),%edx
f0103b00:	84 d2                	test   %dl,%dl
f0103b02:	75 f2                	jne    f0103af6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103b04:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103b09:	5d                   	pop    %ebp
f0103b0a:	c3                   	ret    

f0103b0b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103b0b:	55                   	push   %ebp
f0103b0c:	89 e5                	mov    %esp,%ebp
f0103b0e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b11:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103b15:	eb 07                	jmp    f0103b1e <strfind+0x13>
		if (*s == c)
f0103b17:	38 ca                	cmp    %cl,%dl
f0103b19:	74 0a                	je     f0103b25 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0103b1b:	83 c0 01             	add    $0x1,%eax
f0103b1e:	0f b6 10             	movzbl (%eax),%edx
f0103b21:	84 d2                	test   %dl,%dl
f0103b23:	75 f2                	jne    f0103b17 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0103b25:	5d                   	pop    %ebp
f0103b26:	c3                   	ret    

f0103b27 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103b27:	55                   	push   %ebp
f0103b28:	89 e5                	mov    %esp,%ebp
f0103b2a:	57                   	push   %edi
f0103b2b:	56                   	push   %esi
f0103b2c:	53                   	push   %ebx
f0103b2d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103b30:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103b33:	85 c9                	test   %ecx,%ecx
f0103b35:	74 36                	je     f0103b6d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103b37:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103b3d:	75 28                	jne    f0103b67 <memset+0x40>
f0103b3f:	f6 c1 03             	test   $0x3,%cl
f0103b42:	75 23                	jne    f0103b67 <memset+0x40>
		c &= 0xFF;
f0103b44:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103b48:	89 d3                	mov    %edx,%ebx
f0103b4a:	c1 e3 08             	shl    $0x8,%ebx
f0103b4d:	89 d6                	mov    %edx,%esi
f0103b4f:	c1 e6 18             	shl    $0x18,%esi
f0103b52:	89 d0                	mov    %edx,%eax
f0103b54:	c1 e0 10             	shl    $0x10,%eax
f0103b57:	09 f0                	or     %esi,%eax
f0103b59:	09 c2                	or     %eax,%edx
f0103b5b:	89 d0                	mov    %edx,%eax
f0103b5d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0103b5f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0103b62:	fc                   	cld    
f0103b63:	f3 ab                	rep stos %eax,%es:(%edi)
f0103b65:	eb 06                	jmp    f0103b6d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103b67:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103b6a:	fc                   	cld    
f0103b6b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103b6d:	89 f8                	mov    %edi,%eax
f0103b6f:	5b                   	pop    %ebx
f0103b70:	5e                   	pop    %esi
f0103b71:	5f                   	pop    %edi
f0103b72:	5d                   	pop    %ebp
f0103b73:	c3                   	ret    

f0103b74 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103b74:	55                   	push   %ebp
f0103b75:	89 e5                	mov    %esp,%ebp
f0103b77:	57                   	push   %edi
f0103b78:	56                   	push   %esi
f0103b79:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b7c:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103b7f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103b82:	39 c6                	cmp    %eax,%esi
f0103b84:	73 35                	jae    f0103bbb <memmove+0x47>
f0103b86:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103b89:	39 d0                	cmp    %edx,%eax
f0103b8b:	73 2e                	jae    f0103bbb <memmove+0x47>
		s += n;
		d += n;
f0103b8d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0103b90:	89 d6                	mov    %edx,%esi
f0103b92:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103b94:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103b9a:	75 13                	jne    f0103baf <memmove+0x3b>
f0103b9c:	f6 c1 03             	test   $0x3,%cl
f0103b9f:	75 0e                	jne    f0103baf <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103ba1:	83 ef 04             	sub    $0x4,%edi
f0103ba4:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103ba7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0103baa:	fd                   	std    
f0103bab:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103bad:	eb 09                	jmp    f0103bb8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103baf:	83 ef 01             	sub    $0x1,%edi
f0103bb2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103bb5:	fd                   	std    
f0103bb6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103bb8:	fc                   	cld    
f0103bb9:	eb 1d                	jmp    f0103bd8 <memmove+0x64>
f0103bbb:	89 f2                	mov    %esi,%edx
f0103bbd:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103bbf:	f6 c2 03             	test   $0x3,%dl
f0103bc2:	75 0f                	jne    f0103bd3 <memmove+0x5f>
f0103bc4:	f6 c1 03             	test   $0x3,%cl
f0103bc7:	75 0a                	jne    f0103bd3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103bc9:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0103bcc:	89 c7                	mov    %eax,%edi
f0103bce:	fc                   	cld    
f0103bcf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103bd1:	eb 05                	jmp    f0103bd8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103bd3:	89 c7                	mov    %eax,%edi
f0103bd5:	fc                   	cld    
f0103bd6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103bd8:	5e                   	pop    %esi
f0103bd9:	5f                   	pop    %edi
f0103bda:	5d                   	pop    %ebp
f0103bdb:	c3                   	ret    

f0103bdc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103bdc:	55                   	push   %ebp
f0103bdd:	89 e5                	mov    %esp,%ebp
f0103bdf:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103be2:	8b 45 10             	mov    0x10(%ebp),%eax
f0103be5:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103be9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103bec:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bf0:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bf3:	89 04 24             	mov    %eax,(%esp)
f0103bf6:	e8 79 ff ff ff       	call   f0103b74 <memmove>
}
f0103bfb:	c9                   	leave  
f0103bfc:	c3                   	ret    

f0103bfd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103bfd:	55                   	push   %ebp
f0103bfe:	89 e5                	mov    %esp,%ebp
f0103c00:	56                   	push   %esi
f0103c01:	53                   	push   %ebx
f0103c02:	8b 55 08             	mov    0x8(%ebp),%edx
f0103c05:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103c08:	89 d6                	mov    %edx,%esi
f0103c0a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103c0d:	eb 1a                	jmp    f0103c29 <memcmp+0x2c>
		if (*s1 != *s2)
f0103c0f:	0f b6 02             	movzbl (%edx),%eax
f0103c12:	0f b6 19             	movzbl (%ecx),%ebx
f0103c15:	38 d8                	cmp    %bl,%al
f0103c17:	74 0a                	je     f0103c23 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103c19:	0f b6 c0             	movzbl %al,%eax
f0103c1c:	0f b6 db             	movzbl %bl,%ebx
f0103c1f:	29 d8                	sub    %ebx,%eax
f0103c21:	eb 0f                	jmp    f0103c32 <memcmp+0x35>
		s1++, s2++;
f0103c23:	83 c2 01             	add    $0x1,%edx
f0103c26:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103c29:	39 f2                	cmp    %esi,%edx
f0103c2b:	75 e2                	jne    f0103c0f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103c2d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103c32:	5b                   	pop    %ebx
f0103c33:	5e                   	pop    %esi
f0103c34:	5d                   	pop    %ebp
f0103c35:	c3                   	ret    

f0103c36 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103c36:	55                   	push   %ebp
f0103c37:	89 e5                	mov    %esp,%ebp
f0103c39:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c3c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103c3f:	89 c2                	mov    %eax,%edx
f0103c41:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103c44:	eb 07                	jmp    f0103c4d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103c46:	38 08                	cmp    %cl,(%eax)
f0103c48:	74 07                	je     f0103c51 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103c4a:	83 c0 01             	add    $0x1,%eax
f0103c4d:	39 d0                	cmp    %edx,%eax
f0103c4f:	72 f5                	jb     f0103c46 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103c51:	5d                   	pop    %ebp
f0103c52:	c3                   	ret    

f0103c53 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103c53:	55                   	push   %ebp
f0103c54:	89 e5                	mov    %esp,%ebp
f0103c56:	57                   	push   %edi
f0103c57:	56                   	push   %esi
f0103c58:	53                   	push   %ebx
f0103c59:	8b 55 08             	mov    0x8(%ebp),%edx
f0103c5c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103c5f:	eb 03                	jmp    f0103c64 <strtol+0x11>
		s++;
f0103c61:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103c64:	0f b6 0a             	movzbl (%edx),%ecx
f0103c67:	80 f9 09             	cmp    $0x9,%cl
f0103c6a:	74 f5                	je     f0103c61 <strtol+0xe>
f0103c6c:	80 f9 20             	cmp    $0x20,%cl
f0103c6f:	74 f0                	je     f0103c61 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103c71:	80 f9 2b             	cmp    $0x2b,%cl
f0103c74:	75 0a                	jne    f0103c80 <strtol+0x2d>
		s++;
f0103c76:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103c79:	bf 00 00 00 00       	mov    $0x0,%edi
f0103c7e:	eb 11                	jmp    f0103c91 <strtol+0x3e>
f0103c80:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103c85:	80 f9 2d             	cmp    $0x2d,%cl
f0103c88:	75 07                	jne    f0103c91 <strtol+0x3e>
		s++, neg = 1;
f0103c8a:	8d 52 01             	lea    0x1(%edx),%edx
f0103c8d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103c91:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0103c96:	75 15                	jne    f0103cad <strtol+0x5a>
f0103c98:	80 3a 30             	cmpb   $0x30,(%edx)
f0103c9b:	75 10                	jne    f0103cad <strtol+0x5a>
f0103c9d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103ca1:	75 0a                	jne    f0103cad <strtol+0x5a>
		s += 2, base = 16;
f0103ca3:	83 c2 02             	add    $0x2,%edx
f0103ca6:	b8 10 00 00 00       	mov    $0x10,%eax
f0103cab:	eb 10                	jmp    f0103cbd <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f0103cad:	85 c0                	test   %eax,%eax
f0103caf:	75 0c                	jne    f0103cbd <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103cb1:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103cb3:	80 3a 30             	cmpb   $0x30,(%edx)
f0103cb6:	75 05                	jne    f0103cbd <strtol+0x6a>
		s++, base = 8;
f0103cb8:	83 c2 01             	add    $0x1,%edx
f0103cbb:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f0103cbd:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103cc2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103cc5:	0f b6 0a             	movzbl (%edx),%ecx
f0103cc8:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0103ccb:	89 f0                	mov    %esi,%eax
f0103ccd:	3c 09                	cmp    $0x9,%al
f0103ccf:	77 08                	ja     f0103cd9 <strtol+0x86>
			dig = *s - '0';
f0103cd1:	0f be c9             	movsbl %cl,%ecx
f0103cd4:	83 e9 30             	sub    $0x30,%ecx
f0103cd7:	eb 20                	jmp    f0103cf9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0103cd9:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0103cdc:	89 f0                	mov    %esi,%eax
f0103cde:	3c 19                	cmp    $0x19,%al
f0103ce0:	77 08                	ja     f0103cea <strtol+0x97>
			dig = *s - 'a' + 10;
f0103ce2:	0f be c9             	movsbl %cl,%ecx
f0103ce5:	83 e9 57             	sub    $0x57,%ecx
f0103ce8:	eb 0f                	jmp    f0103cf9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0103cea:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0103ced:	89 f0                	mov    %esi,%eax
f0103cef:	3c 19                	cmp    $0x19,%al
f0103cf1:	77 16                	ja     f0103d09 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0103cf3:	0f be c9             	movsbl %cl,%ecx
f0103cf6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103cf9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0103cfc:	7d 0f                	jge    f0103d0d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f0103cfe:	83 c2 01             	add    $0x1,%edx
f0103d01:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0103d05:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0103d07:	eb bc                	jmp    f0103cc5 <strtol+0x72>
f0103d09:	89 d8                	mov    %ebx,%eax
f0103d0b:	eb 02                	jmp    f0103d0f <strtol+0xbc>
f0103d0d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0103d0f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103d13:	74 05                	je     f0103d1a <strtol+0xc7>
		*endptr = (char *) s;
f0103d15:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103d18:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0103d1a:	f7 d8                	neg    %eax
f0103d1c:	85 ff                	test   %edi,%edi
f0103d1e:	0f 44 c3             	cmove  %ebx,%eax
}
f0103d21:	5b                   	pop    %ebx
f0103d22:	5e                   	pop    %esi
f0103d23:	5f                   	pop    %edi
f0103d24:	5d                   	pop    %ebp
f0103d25:	c3                   	ret    
f0103d26:	66 90                	xchg   %ax,%ax
f0103d28:	66 90                	xchg   %ax,%ax
f0103d2a:	66 90                	xchg   %ax,%ax
f0103d2c:	66 90                	xchg   %ax,%ax
f0103d2e:	66 90                	xchg   %ax,%ax

f0103d30 <__udivdi3>:
f0103d30:	55                   	push   %ebp
f0103d31:	57                   	push   %edi
f0103d32:	56                   	push   %esi
f0103d33:	83 ec 0c             	sub    $0xc,%esp
f0103d36:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103d3a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0103d3e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0103d42:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103d46:	85 c0                	test   %eax,%eax
f0103d48:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103d4c:	89 ea                	mov    %ebp,%edx
f0103d4e:	89 0c 24             	mov    %ecx,(%esp)
f0103d51:	75 2d                	jne    f0103d80 <__udivdi3+0x50>
f0103d53:	39 e9                	cmp    %ebp,%ecx
f0103d55:	77 61                	ja     f0103db8 <__udivdi3+0x88>
f0103d57:	85 c9                	test   %ecx,%ecx
f0103d59:	89 ce                	mov    %ecx,%esi
f0103d5b:	75 0b                	jne    f0103d68 <__udivdi3+0x38>
f0103d5d:	b8 01 00 00 00       	mov    $0x1,%eax
f0103d62:	31 d2                	xor    %edx,%edx
f0103d64:	f7 f1                	div    %ecx
f0103d66:	89 c6                	mov    %eax,%esi
f0103d68:	31 d2                	xor    %edx,%edx
f0103d6a:	89 e8                	mov    %ebp,%eax
f0103d6c:	f7 f6                	div    %esi
f0103d6e:	89 c5                	mov    %eax,%ebp
f0103d70:	89 f8                	mov    %edi,%eax
f0103d72:	f7 f6                	div    %esi
f0103d74:	89 ea                	mov    %ebp,%edx
f0103d76:	83 c4 0c             	add    $0xc,%esp
f0103d79:	5e                   	pop    %esi
f0103d7a:	5f                   	pop    %edi
f0103d7b:	5d                   	pop    %ebp
f0103d7c:	c3                   	ret    
f0103d7d:	8d 76 00             	lea    0x0(%esi),%esi
f0103d80:	39 e8                	cmp    %ebp,%eax
f0103d82:	77 24                	ja     f0103da8 <__udivdi3+0x78>
f0103d84:	0f bd e8             	bsr    %eax,%ebp
f0103d87:	83 f5 1f             	xor    $0x1f,%ebp
f0103d8a:	75 3c                	jne    f0103dc8 <__udivdi3+0x98>
f0103d8c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0103d90:	39 34 24             	cmp    %esi,(%esp)
f0103d93:	0f 86 9f 00 00 00    	jbe    f0103e38 <__udivdi3+0x108>
f0103d99:	39 d0                	cmp    %edx,%eax
f0103d9b:	0f 82 97 00 00 00    	jb     f0103e38 <__udivdi3+0x108>
f0103da1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103da8:	31 d2                	xor    %edx,%edx
f0103daa:	31 c0                	xor    %eax,%eax
f0103dac:	83 c4 0c             	add    $0xc,%esp
f0103daf:	5e                   	pop    %esi
f0103db0:	5f                   	pop    %edi
f0103db1:	5d                   	pop    %ebp
f0103db2:	c3                   	ret    
f0103db3:	90                   	nop
f0103db4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103db8:	89 f8                	mov    %edi,%eax
f0103dba:	f7 f1                	div    %ecx
f0103dbc:	31 d2                	xor    %edx,%edx
f0103dbe:	83 c4 0c             	add    $0xc,%esp
f0103dc1:	5e                   	pop    %esi
f0103dc2:	5f                   	pop    %edi
f0103dc3:	5d                   	pop    %ebp
f0103dc4:	c3                   	ret    
f0103dc5:	8d 76 00             	lea    0x0(%esi),%esi
f0103dc8:	89 e9                	mov    %ebp,%ecx
f0103dca:	8b 3c 24             	mov    (%esp),%edi
f0103dcd:	d3 e0                	shl    %cl,%eax
f0103dcf:	89 c6                	mov    %eax,%esi
f0103dd1:	b8 20 00 00 00       	mov    $0x20,%eax
f0103dd6:	29 e8                	sub    %ebp,%eax
f0103dd8:	89 c1                	mov    %eax,%ecx
f0103dda:	d3 ef                	shr    %cl,%edi
f0103ddc:	89 e9                	mov    %ebp,%ecx
f0103dde:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103de2:	8b 3c 24             	mov    (%esp),%edi
f0103de5:	09 74 24 08          	or     %esi,0x8(%esp)
f0103de9:	89 d6                	mov    %edx,%esi
f0103deb:	d3 e7                	shl    %cl,%edi
f0103ded:	89 c1                	mov    %eax,%ecx
f0103def:	89 3c 24             	mov    %edi,(%esp)
f0103df2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103df6:	d3 ee                	shr    %cl,%esi
f0103df8:	89 e9                	mov    %ebp,%ecx
f0103dfa:	d3 e2                	shl    %cl,%edx
f0103dfc:	89 c1                	mov    %eax,%ecx
f0103dfe:	d3 ef                	shr    %cl,%edi
f0103e00:	09 d7                	or     %edx,%edi
f0103e02:	89 f2                	mov    %esi,%edx
f0103e04:	89 f8                	mov    %edi,%eax
f0103e06:	f7 74 24 08          	divl   0x8(%esp)
f0103e0a:	89 d6                	mov    %edx,%esi
f0103e0c:	89 c7                	mov    %eax,%edi
f0103e0e:	f7 24 24             	mull   (%esp)
f0103e11:	39 d6                	cmp    %edx,%esi
f0103e13:	89 14 24             	mov    %edx,(%esp)
f0103e16:	72 30                	jb     f0103e48 <__udivdi3+0x118>
f0103e18:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103e1c:	89 e9                	mov    %ebp,%ecx
f0103e1e:	d3 e2                	shl    %cl,%edx
f0103e20:	39 c2                	cmp    %eax,%edx
f0103e22:	73 05                	jae    f0103e29 <__udivdi3+0xf9>
f0103e24:	3b 34 24             	cmp    (%esp),%esi
f0103e27:	74 1f                	je     f0103e48 <__udivdi3+0x118>
f0103e29:	89 f8                	mov    %edi,%eax
f0103e2b:	31 d2                	xor    %edx,%edx
f0103e2d:	e9 7a ff ff ff       	jmp    f0103dac <__udivdi3+0x7c>
f0103e32:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103e38:	31 d2                	xor    %edx,%edx
f0103e3a:	b8 01 00 00 00       	mov    $0x1,%eax
f0103e3f:	e9 68 ff ff ff       	jmp    f0103dac <__udivdi3+0x7c>
f0103e44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103e48:	8d 47 ff             	lea    -0x1(%edi),%eax
f0103e4b:	31 d2                	xor    %edx,%edx
f0103e4d:	83 c4 0c             	add    $0xc,%esp
f0103e50:	5e                   	pop    %esi
f0103e51:	5f                   	pop    %edi
f0103e52:	5d                   	pop    %ebp
f0103e53:	c3                   	ret    
f0103e54:	66 90                	xchg   %ax,%ax
f0103e56:	66 90                	xchg   %ax,%ax
f0103e58:	66 90                	xchg   %ax,%ax
f0103e5a:	66 90                	xchg   %ax,%ax
f0103e5c:	66 90                	xchg   %ax,%ax
f0103e5e:	66 90                	xchg   %ax,%ax

f0103e60 <__umoddi3>:
f0103e60:	55                   	push   %ebp
f0103e61:	57                   	push   %edi
f0103e62:	56                   	push   %esi
f0103e63:	83 ec 14             	sub    $0x14,%esp
f0103e66:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103e6a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103e6e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0103e72:	89 c7                	mov    %eax,%edi
f0103e74:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e78:	8b 44 24 30          	mov    0x30(%esp),%eax
f0103e7c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0103e80:	89 34 24             	mov    %esi,(%esp)
f0103e83:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103e87:	85 c0                	test   %eax,%eax
f0103e89:	89 c2                	mov    %eax,%edx
f0103e8b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103e8f:	75 17                	jne    f0103ea8 <__umoddi3+0x48>
f0103e91:	39 fe                	cmp    %edi,%esi
f0103e93:	76 4b                	jbe    f0103ee0 <__umoddi3+0x80>
f0103e95:	89 c8                	mov    %ecx,%eax
f0103e97:	89 fa                	mov    %edi,%edx
f0103e99:	f7 f6                	div    %esi
f0103e9b:	89 d0                	mov    %edx,%eax
f0103e9d:	31 d2                	xor    %edx,%edx
f0103e9f:	83 c4 14             	add    $0x14,%esp
f0103ea2:	5e                   	pop    %esi
f0103ea3:	5f                   	pop    %edi
f0103ea4:	5d                   	pop    %ebp
f0103ea5:	c3                   	ret    
f0103ea6:	66 90                	xchg   %ax,%ax
f0103ea8:	39 f8                	cmp    %edi,%eax
f0103eaa:	77 54                	ja     f0103f00 <__umoddi3+0xa0>
f0103eac:	0f bd e8             	bsr    %eax,%ebp
f0103eaf:	83 f5 1f             	xor    $0x1f,%ebp
f0103eb2:	75 5c                	jne    f0103f10 <__umoddi3+0xb0>
f0103eb4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0103eb8:	39 3c 24             	cmp    %edi,(%esp)
f0103ebb:	0f 87 e7 00 00 00    	ja     f0103fa8 <__umoddi3+0x148>
f0103ec1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103ec5:	29 f1                	sub    %esi,%ecx
f0103ec7:	19 c7                	sbb    %eax,%edi
f0103ec9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103ecd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103ed1:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103ed5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103ed9:	83 c4 14             	add    $0x14,%esp
f0103edc:	5e                   	pop    %esi
f0103edd:	5f                   	pop    %edi
f0103ede:	5d                   	pop    %ebp
f0103edf:	c3                   	ret    
f0103ee0:	85 f6                	test   %esi,%esi
f0103ee2:	89 f5                	mov    %esi,%ebp
f0103ee4:	75 0b                	jne    f0103ef1 <__umoddi3+0x91>
f0103ee6:	b8 01 00 00 00       	mov    $0x1,%eax
f0103eeb:	31 d2                	xor    %edx,%edx
f0103eed:	f7 f6                	div    %esi
f0103eef:	89 c5                	mov    %eax,%ebp
f0103ef1:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103ef5:	31 d2                	xor    %edx,%edx
f0103ef7:	f7 f5                	div    %ebp
f0103ef9:	89 c8                	mov    %ecx,%eax
f0103efb:	f7 f5                	div    %ebp
f0103efd:	eb 9c                	jmp    f0103e9b <__umoddi3+0x3b>
f0103eff:	90                   	nop
f0103f00:	89 c8                	mov    %ecx,%eax
f0103f02:	89 fa                	mov    %edi,%edx
f0103f04:	83 c4 14             	add    $0x14,%esp
f0103f07:	5e                   	pop    %esi
f0103f08:	5f                   	pop    %edi
f0103f09:	5d                   	pop    %ebp
f0103f0a:	c3                   	ret    
f0103f0b:	90                   	nop
f0103f0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103f10:	8b 04 24             	mov    (%esp),%eax
f0103f13:	be 20 00 00 00       	mov    $0x20,%esi
f0103f18:	89 e9                	mov    %ebp,%ecx
f0103f1a:	29 ee                	sub    %ebp,%esi
f0103f1c:	d3 e2                	shl    %cl,%edx
f0103f1e:	89 f1                	mov    %esi,%ecx
f0103f20:	d3 e8                	shr    %cl,%eax
f0103f22:	89 e9                	mov    %ebp,%ecx
f0103f24:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f28:	8b 04 24             	mov    (%esp),%eax
f0103f2b:	09 54 24 04          	or     %edx,0x4(%esp)
f0103f2f:	89 fa                	mov    %edi,%edx
f0103f31:	d3 e0                	shl    %cl,%eax
f0103f33:	89 f1                	mov    %esi,%ecx
f0103f35:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103f39:	8b 44 24 10          	mov    0x10(%esp),%eax
f0103f3d:	d3 ea                	shr    %cl,%edx
f0103f3f:	89 e9                	mov    %ebp,%ecx
f0103f41:	d3 e7                	shl    %cl,%edi
f0103f43:	89 f1                	mov    %esi,%ecx
f0103f45:	d3 e8                	shr    %cl,%eax
f0103f47:	89 e9                	mov    %ebp,%ecx
f0103f49:	09 f8                	or     %edi,%eax
f0103f4b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0103f4f:	f7 74 24 04          	divl   0x4(%esp)
f0103f53:	d3 e7                	shl    %cl,%edi
f0103f55:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103f59:	89 d7                	mov    %edx,%edi
f0103f5b:	f7 64 24 08          	mull   0x8(%esp)
f0103f5f:	39 d7                	cmp    %edx,%edi
f0103f61:	89 c1                	mov    %eax,%ecx
f0103f63:	89 14 24             	mov    %edx,(%esp)
f0103f66:	72 2c                	jb     f0103f94 <__umoddi3+0x134>
f0103f68:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0103f6c:	72 22                	jb     f0103f90 <__umoddi3+0x130>
f0103f6e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0103f72:	29 c8                	sub    %ecx,%eax
f0103f74:	19 d7                	sbb    %edx,%edi
f0103f76:	89 e9                	mov    %ebp,%ecx
f0103f78:	89 fa                	mov    %edi,%edx
f0103f7a:	d3 e8                	shr    %cl,%eax
f0103f7c:	89 f1                	mov    %esi,%ecx
f0103f7e:	d3 e2                	shl    %cl,%edx
f0103f80:	89 e9                	mov    %ebp,%ecx
f0103f82:	d3 ef                	shr    %cl,%edi
f0103f84:	09 d0                	or     %edx,%eax
f0103f86:	89 fa                	mov    %edi,%edx
f0103f88:	83 c4 14             	add    $0x14,%esp
f0103f8b:	5e                   	pop    %esi
f0103f8c:	5f                   	pop    %edi
f0103f8d:	5d                   	pop    %ebp
f0103f8e:	c3                   	ret    
f0103f8f:	90                   	nop
f0103f90:	39 d7                	cmp    %edx,%edi
f0103f92:	75 da                	jne    f0103f6e <__umoddi3+0x10e>
f0103f94:	8b 14 24             	mov    (%esp),%edx
f0103f97:	89 c1                	mov    %eax,%ecx
f0103f99:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0103f9d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0103fa1:	eb cb                	jmp    f0103f6e <__umoddi3+0x10e>
f0103fa3:	90                   	nop
f0103fa4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103fa8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0103fac:	0f 82 0f ff ff ff    	jb     f0103ec1 <__umoddi3+0x61>
f0103fb2:	e9 1a ff ff ff       	jmp    f0103ed1 <__umoddi3+0x71>
