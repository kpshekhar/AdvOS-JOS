
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
f010004e:	c7 04 24 e0 19 10 f0 	movl   $0xf01019e0,(%esp)
f0100055:	e8 84 09 00 00       	call   f01009de <cprintf>
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
f0100082:	e8 44 07 00 00       	call   f01007cb <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 fc 19 10 f0 	movl   $0xf01019fc,(%esp)
f0100092:	e8 47 09 00 00       	call   f01009de <cprintf>
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
f01000c0:	e8 82 14 00 00       	call   f0101547 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 b5 04 00 00       	call   f010057f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 17 1a 10 f0 	movl   $0xf0101a17,(%esp)
f01000d9:	e8 00 09 00 00       	call   f01009de <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>
	int x = 1, y = 3, z = 4;
	cprintf("x %d, y %x, z %d\n", x, y, z);
f01000ea:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f01000f1:	00 
f01000f2:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
f01000f9:	00 
f01000fa:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0100101:	00 
f0100102:	c7 04 24 32 1a 10 f0 	movl   $0xf0101a32,(%esp)
f0100109:	e8 d0 08 00 00       	call   f01009de <cprintf>
	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010010e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100115:	e8 4b 07 00 00       	call   f0100865 <monitor>
f010011a:	eb f2                	jmp    f010010e <i386_init+0x71>

f010011c <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp
f010011f:	56                   	push   %esi
f0100120:	53                   	push   %ebx
f0100121:	83 ec 10             	sub    $0x10,%esp
f0100124:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100127:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f010012e:	75 3d                	jne    f010016d <_panic+0x51>
		goto dead;
	panicstr = fmt;
f0100130:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100136:	fa                   	cli    
f0100137:	fc                   	cld    

	va_start(ap, fmt);
f0100138:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f010013b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010013e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100142:	8b 45 08             	mov    0x8(%ebp),%eax
f0100145:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100149:	c7 04 24 44 1a 10 f0 	movl   $0xf0101a44,(%esp)
f0100150:	e8 89 08 00 00       	call   f01009de <cprintf>
	vcprintf(fmt, ap);
f0100155:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100159:	89 34 24             	mov    %esi,(%esp)
f010015c:	e8 4a 08 00 00       	call   f01009ab <vcprintf>
	cprintf("\n");
f0100161:	c7 04 24 80 1a 10 f0 	movl   $0xf0101a80,(%esp)
f0100168:	e8 71 08 00 00       	call   f01009de <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010016d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100174:	e8 ec 06 00 00       	call   f0100865 <monitor>
f0100179:	eb f2                	jmp    f010016d <_panic+0x51>

f010017b <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010017b:	55                   	push   %ebp
f010017c:	89 e5                	mov    %esp,%ebp
f010017e:	53                   	push   %ebx
f010017f:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f0100182:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100185:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100188:	89 44 24 08          	mov    %eax,0x8(%esp)
f010018c:	8b 45 08             	mov    0x8(%ebp),%eax
f010018f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100193:	c7 04 24 5c 1a 10 f0 	movl   $0xf0101a5c,(%esp)
f010019a:	e8 3f 08 00 00       	call   f01009de <cprintf>
	vcprintf(fmt, ap);
f010019f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01001a3:	8b 45 10             	mov    0x10(%ebp),%eax
f01001a6:	89 04 24             	mov    %eax,(%esp)
f01001a9:	e8 fd 07 00 00       	call   f01009ab <vcprintf>
	cprintf("\n");
f01001ae:	c7 04 24 80 1a 10 f0 	movl   $0xf0101a80,(%esp)
f01001b5:	e8 24 08 00 00       	call   f01009de <cprintf>
	va_end(ap);
}
f01001ba:	83 c4 14             	add    $0x14,%esp
f01001bd:	5b                   	pop    %ebx
f01001be:	5d                   	pop    %ebp
f01001bf:	c3                   	ret    

f01001c0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001c0:	55                   	push   %ebp
f01001c1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001c3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001c8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001c9:	a8 01                	test   $0x1,%al
f01001cb:	74 08                	je     f01001d5 <serial_proc_data+0x15>
f01001cd:	b2 f8                	mov    $0xf8,%dl
f01001cf:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001d0:	0f b6 c0             	movzbl %al,%eax
f01001d3:	eb 05                	jmp    f01001da <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001da:	5d                   	pop    %ebp
f01001db:	c3                   	ret    

f01001dc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001dc:	55                   	push   %ebp
f01001dd:	89 e5                	mov    %esp,%ebp
f01001df:	53                   	push   %ebx
f01001e0:	83 ec 04             	sub    $0x4,%esp
f01001e3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001e5:	eb 2a                	jmp    f0100211 <cons_intr+0x35>
		if (c == 0)
f01001e7:	85 d2                	test   %edx,%edx
f01001e9:	74 26                	je     f0100211 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001eb:	a1 24 25 11 f0       	mov    0xf0112524,%eax
f01001f0:	8d 48 01             	lea    0x1(%eax),%ecx
f01001f3:	89 0d 24 25 11 f0    	mov    %ecx,0xf0112524
f01001f9:	88 90 20 23 11 f0    	mov    %dl,-0xfeedce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001ff:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100205:	75 0a                	jne    f0100211 <cons_intr+0x35>
			cons.wpos = 0;
f0100207:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f010020e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100211:	ff d3                	call   *%ebx
f0100213:	89 c2                	mov    %eax,%edx
f0100215:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100218:	75 cd                	jne    f01001e7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010021a:	83 c4 04             	add    $0x4,%esp
f010021d:	5b                   	pop    %ebx
f010021e:	5d                   	pop    %ebp
f010021f:	c3                   	ret    

f0100220 <kbd_proc_data>:
f0100220:	ba 64 00 00 00       	mov    $0x64,%edx
f0100225:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100226:	a8 01                	test   $0x1,%al
f0100228:	0f 84 ef 00 00 00    	je     f010031d <kbd_proc_data+0xfd>
f010022e:	b2 60                	mov    $0x60,%dl
f0100230:	ec                   	in     (%dx),%al
f0100231:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100233:	3c e0                	cmp    $0xe0,%al
f0100235:	75 0d                	jne    f0100244 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100237:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f010023e:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100243:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100244:	55                   	push   %ebp
f0100245:	89 e5                	mov    %esp,%ebp
f0100247:	53                   	push   %ebx
f0100248:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010024b:	84 c0                	test   %al,%al
f010024d:	79 37                	jns    f0100286 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010024f:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100255:	89 cb                	mov    %ecx,%ebx
f0100257:	83 e3 40             	and    $0x40,%ebx
f010025a:	83 e0 7f             	and    $0x7f,%eax
f010025d:	85 db                	test   %ebx,%ebx
f010025f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100262:	0f b6 d2             	movzbl %dl,%edx
f0100265:	0f b6 82 c0 1b 10 f0 	movzbl -0xfefe440(%edx),%eax
f010026c:	83 c8 40             	or     $0x40,%eax
f010026f:	0f b6 c0             	movzbl %al,%eax
f0100272:	f7 d0                	not    %eax
f0100274:	21 c1                	and    %eax,%ecx
f0100276:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
		return 0;
f010027c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100281:	e9 9d 00 00 00       	jmp    f0100323 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100286:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010028c:	f6 c1 40             	test   $0x40,%cl
f010028f:	74 0e                	je     f010029f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100291:	83 c8 80             	or     $0xffffff80,%eax
f0100294:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100296:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100299:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f010029f:	0f b6 d2             	movzbl %dl,%edx
f01002a2:	0f b6 82 c0 1b 10 f0 	movzbl -0xfefe440(%edx),%eax
f01002a9:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
	shift ^= togglecode[data];
f01002af:	0f b6 8a c0 1a 10 f0 	movzbl -0xfefe540(%edx),%ecx
f01002b6:	31 c8                	xor    %ecx,%eax
f01002b8:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f01002bd:	89 c1                	mov    %eax,%ecx
f01002bf:	83 e1 03             	and    $0x3,%ecx
f01002c2:	8b 0c 8d a0 1a 10 f0 	mov    -0xfefe560(,%ecx,4),%ecx
f01002c9:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002cd:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002d0:	a8 08                	test   $0x8,%al
f01002d2:	74 1b                	je     f01002ef <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01002d4:	89 da                	mov    %ebx,%edx
f01002d6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002d9:	83 f9 19             	cmp    $0x19,%ecx
f01002dc:	77 05                	ja     f01002e3 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f01002de:	83 eb 20             	sub    $0x20,%ebx
f01002e1:	eb 0c                	jmp    f01002ef <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f01002e3:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002e6:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002e9:	83 fa 19             	cmp    $0x19,%edx
f01002ec:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002ef:	f7 d0                	not    %eax
f01002f1:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002f3:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002f5:	f6 c2 06             	test   $0x6,%dl
f01002f8:	75 29                	jne    f0100323 <kbd_proc_data+0x103>
f01002fa:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100300:	75 21                	jne    f0100323 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f0100302:	c7 04 24 76 1a 10 f0 	movl   $0xf0101a76,(%esp)
f0100309:	e8 d0 06 00 00       	call   f01009de <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010030e:	ba 92 00 00 00       	mov    $0x92,%edx
f0100313:	b8 03 00 00 00       	mov    $0x3,%eax
f0100318:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100319:	89 d8                	mov    %ebx,%eax
f010031b:	eb 06                	jmp    f0100323 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010031d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100322:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100323:	83 c4 14             	add    $0x14,%esp
f0100326:	5b                   	pop    %ebx
f0100327:	5d                   	pop    %ebp
f0100328:	c3                   	ret    

f0100329 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100329:	55                   	push   %ebp
f010032a:	89 e5                	mov    %esp,%ebp
f010032c:	57                   	push   %edi
f010032d:	56                   	push   %esi
f010032e:	53                   	push   %ebx
f010032f:	83 ec 1c             	sub    $0x1c,%esp
f0100332:	89 c7                	mov    %eax,%edi
f0100334:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100339:	be fd 03 00 00       	mov    $0x3fd,%esi
f010033e:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100343:	eb 06                	jmp    f010034b <cons_putc+0x22>
f0100345:	89 ca                	mov    %ecx,%edx
f0100347:	ec                   	in     (%dx),%al
f0100348:	ec                   	in     (%dx),%al
f0100349:	ec                   	in     (%dx),%al
f010034a:	ec                   	in     (%dx),%al
f010034b:	89 f2                	mov    %esi,%edx
f010034d:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010034e:	a8 20                	test   $0x20,%al
f0100350:	75 05                	jne    f0100357 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100352:	83 eb 01             	sub    $0x1,%ebx
f0100355:	75 ee                	jne    f0100345 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100357:	89 f8                	mov    %edi,%eax
f0100359:	0f b6 c0             	movzbl %al,%eax
f010035c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010035f:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100364:	ee                   	out    %al,(%dx)
f0100365:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010036a:	be 79 03 00 00       	mov    $0x379,%esi
f010036f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100374:	eb 06                	jmp    f010037c <cons_putc+0x53>
f0100376:	89 ca                	mov    %ecx,%edx
f0100378:	ec                   	in     (%dx),%al
f0100379:	ec                   	in     (%dx),%al
f010037a:	ec                   	in     (%dx),%al
f010037b:	ec                   	in     (%dx),%al
f010037c:	89 f2                	mov    %esi,%edx
f010037e:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010037f:	84 c0                	test   %al,%al
f0100381:	78 05                	js     f0100388 <cons_putc+0x5f>
f0100383:	83 eb 01             	sub    $0x1,%ebx
f0100386:	75 ee                	jne    f0100376 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100388:	ba 78 03 00 00       	mov    $0x378,%edx
f010038d:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100391:	ee                   	out    %al,(%dx)
f0100392:	b2 7a                	mov    $0x7a,%dl
f0100394:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100399:	ee                   	out    %al,(%dx)
f010039a:	b8 08 00 00 00       	mov    $0x8,%eax
f010039f:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f01003a0:	89 fa                	mov    %edi,%edx
f01003a2:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f01003a8:	89 f8                	mov    %edi,%eax
f01003aa:	80 cc 07             	or     $0x7,%ah
f01003ad:	85 d2                	test   %edx,%edx
f01003af:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f01003b2:	89 f8                	mov    %edi,%eax
f01003b4:	0f b6 c0             	movzbl %al,%eax
f01003b7:	83 f8 09             	cmp    $0x9,%eax
f01003ba:	74 76                	je     f0100432 <cons_putc+0x109>
f01003bc:	83 f8 09             	cmp    $0x9,%eax
f01003bf:	7f 0a                	jg     f01003cb <cons_putc+0xa2>
f01003c1:	83 f8 08             	cmp    $0x8,%eax
f01003c4:	74 16                	je     f01003dc <cons_putc+0xb3>
f01003c6:	e9 9b 00 00 00       	jmp    f0100466 <cons_putc+0x13d>
f01003cb:	83 f8 0a             	cmp    $0xa,%eax
f01003ce:	66 90                	xchg   %ax,%ax
f01003d0:	74 3a                	je     f010040c <cons_putc+0xe3>
f01003d2:	83 f8 0d             	cmp    $0xd,%eax
f01003d5:	74 3d                	je     f0100414 <cons_putc+0xeb>
f01003d7:	e9 8a 00 00 00       	jmp    f0100466 <cons_putc+0x13d>
	case '\b':
		if (crt_pos > 0) {
f01003dc:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003e3:	66 85 c0             	test   %ax,%ax
f01003e6:	0f 84 e5 00 00 00    	je     f01004d1 <cons_putc+0x1a8>
			crt_pos--;
f01003ec:	83 e8 01             	sub    $0x1,%eax
f01003ef:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003f5:	0f b7 c0             	movzwl %ax,%eax
f01003f8:	66 81 e7 00 ff       	and    $0xff00,%di
f01003fd:	83 cf 20             	or     $0x20,%edi
f0100400:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100406:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010040a:	eb 78                	jmp    f0100484 <cons_putc+0x15b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010040c:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f0100413:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100414:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010041b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100421:	c1 e8 16             	shr    $0x16,%eax
f0100424:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100427:	c1 e0 04             	shl    $0x4,%eax
f010042a:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f0100430:	eb 52                	jmp    f0100484 <cons_putc+0x15b>
		break;
	case '\t':
		cons_putc(' ');
f0100432:	b8 20 00 00 00       	mov    $0x20,%eax
f0100437:	e8 ed fe ff ff       	call   f0100329 <cons_putc>
		cons_putc(' ');
f010043c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100441:	e8 e3 fe ff ff       	call   f0100329 <cons_putc>
		cons_putc(' ');
f0100446:	b8 20 00 00 00       	mov    $0x20,%eax
f010044b:	e8 d9 fe ff ff       	call   f0100329 <cons_putc>
		cons_putc(' ');
f0100450:	b8 20 00 00 00       	mov    $0x20,%eax
f0100455:	e8 cf fe ff ff       	call   f0100329 <cons_putc>
		cons_putc(' ');
f010045a:	b8 20 00 00 00       	mov    $0x20,%eax
f010045f:	e8 c5 fe ff ff       	call   f0100329 <cons_putc>
f0100464:	eb 1e                	jmp    f0100484 <cons_putc+0x15b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100466:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010046d:	8d 50 01             	lea    0x1(%eax),%edx
f0100470:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f0100477:	0f b7 c0             	movzwl %ax,%eax
f010047a:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100480:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100484:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f010048b:	cf 07 
f010048d:	76 42                	jbe    f01004d1 <cons_putc+0x1a8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010048f:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100494:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010049b:	00 
f010049c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004a2:	89 54 24 04          	mov    %edx,0x4(%esp)
f01004a6:	89 04 24             	mov    %eax,(%esp)
f01004a9:	e8 e6 10 00 00       	call   f0101594 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01004ae:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004b4:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01004b9:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004bf:	83 c0 01             	add    $0x1,%eax
f01004c2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01004c7:	75 f0                	jne    f01004b9 <cons_putc+0x190>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004c9:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004d0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004d1:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004d7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004dc:	89 ca                	mov    %ecx,%edx
f01004de:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004df:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004e6:	8d 71 01             	lea    0x1(%ecx),%esi
f01004e9:	89 d8                	mov    %ebx,%eax
f01004eb:	66 c1 e8 08          	shr    $0x8,%ax
f01004ef:	89 f2                	mov    %esi,%edx
f01004f1:	ee                   	out    %al,(%dx)
f01004f2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004f7:	89 ca                	mov    %ecx,%edx
f01004f9:	ee                   	out    %al,(%dx)
f01004fa:	89 d8                	mov    %ebx,%eax
f01004fc:	89 f2                	mov    %esi,%edx
f01004fe:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004ff:	83 c4 1c             	add    $0x1c,%esp
f0100502:	5b                   	pop    %ebx
f0100503:	5e                   	pop    %esi
f0100504:	5f                   	pop    %edi
f0100505:	5d                   	pop    %ebp
f0100506:	c3                   	ret    

f0100507 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100507:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f010050e:	74 11                	je     f0100521 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100510:	55                   	push   %ebp
f0100511:	89 e5                	mov    %esp,%ebp
f0100513:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100516:	b8 c0 01 10 f0       	mov    $0xf01001c0,%eax
f010051b:	e8 bc fc ff ff       	call   f01001dc <cons_intr>
}
f0100520:	c9                   	leave  
f0100521:	f3 c3                	repz ret 

f0100523 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100523:	55                   	push   %ebp
f0100524:	89 e5                	mov    %esp,%ebp
f0100526:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100529:	b8 20 02 10 f0       	mov    $0xf0100220,%eax
f010052e:	e8 a9 fc ff ff       	call   f01001dc <cons_intr>
}
f0100533:	c9                   	leave  
f0100534:	c3                   	ret    

f0100535 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100535:	55                   	push   %ebp
f0100536:	89 e5                	mov    %esp,%ebp
f0100538:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010053b:	e8 c7 ff ff ff       	call   f0100507 <serial_intr>
	kbd_intr();
f0100540:	e8 de ff ff ff       	call   f0100523 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100545:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f010054a:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100550:	74 26                	je     f0100578 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100552:	8d 50 01             	lea    0x1(%eax),%edx
f0100555:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010055b:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100562:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100564:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010056a:	75 11                	jne    f010057d <cons_getc+0x48>
			cons.rpos = 0;
f010056c:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100573:	00 00 00 
f0100576:	eb 05                	jmp    f010057d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100578:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010057d:	c9                   	leave  
f010057e:	c3                   	ret    

f010057f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010057f:	55                   	push   %ebp
f0100580:	89 e5                	mov    %esp,%ebp
f0100582:	57                   	push   %edi
f0100583:	56                   	push   %esi
f0100584:	53                   	push   %ebx
f0100585:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100588:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010058f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100596:	5a a5 
	if (*cp != 0xA55A) {
f0100598:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010059f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005a3:	74 11                	je     f01005b6 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01005a5:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f01005ac:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005af:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01005b4:	eb 16                	jmp    f01005cc <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005b6:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005bd:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f01005c4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005c7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005cc:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01005d2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005d7:	89 ca                	mov    %ecx,%edx
f01005d9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005da:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005dd:	89 da                	mov    %ebx,%edx
f01005df:	ec                   	in     (%dx),%al
f01005e0:	0f b6 f0             	movzbl %al,%esi
f01005e3:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005e6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005eb:	89 ca                	mov    %ecx,%edx
f01005ed:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005ee:	89 da                	mov    %ebx,%edx
f01005f0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005f1:	89 3d 2c 25 11 f0    	mov    %edi,0xf011252c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005f7:	0f b6 d8             	movzbl %al,%ebx
f01005fa:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005fc:	66 89 35 28 25 11 f0 	mov    %si,0xf0112528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100603:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100608:	b8 00 00 00 00       	mov    $0x0,%eax
f010060d:	89 f2                	mov    %esi,%edx
f010060f:	ee                   	out    %al,(%dx)
f0100610:	b2 fb                	mov    $0xfb,%dl
f0100612:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100617:	ee                   	out    %al,(%dx)
f0100618:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010061d:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100622:	89 da                	mov    %ebx,%edx
f0100624:	ee                   	out    %al,(%dx)
f0100625:	b2 f9                	mov    $0xf9,%dl
f0100627:	b8 00 00 00 00       	mov    $0x0,%eax
f010062c:	ee                   	out    %al,(%dx)
f010062d:	b2 fb                	mov    $0xfb,%dl
f010062f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100634:	ee                   	out    %al,(%dx)
f0100635:	b2 fc                	mov    $0xfc,%dl
f0100637:	b8 00 00 00 00       	mov    $0x0,%eax
f010063c:	ee                   	out    %al,(%dx)
f010063d:	b2 f9                	mov    $0xf9,%dl
f010063f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100644:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100645:	b2 fd                	mov    $0xfd,%dl
f0100647:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100648:	3c ff                	cmp    $0xff,%al
f010064a:	0f 95 c1             	setne  %cl
f010064d:	88 0d 34 25 11 f0    	mov    %cl,0xf0112534
f0100653:	89 f2                	mov    %esi,%edx
f0100655:	ec                   	in     (%dx),%al
f0100656:	89 da                	mov    %ebx,%edx
f0100658:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100659:	84 c9                	test   %cl,%cl
f010065b:	75 0c                	jne    f0100669 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f010065d:	c7 04 24 82 1a 10 f0 	movl   $0xf0101a82,(%esp)
f0100664:	e8 75 03 00 00       	call   f01009de <cprintf>
}
f0100669:	83 c4 1c             	add    $0x1c,%esp
f010066c:	5b                   	pop    %ebx
f010066d:	5e                   	pop    %esi
f010066e:	5f                   	pop    %edi
f010066f:	5d                   	pop    %ebp
f0100670:	c3                   	ret    

f0100671 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100671:	55                   	push   %ebp
f0100672:	89 e5                	mov    %esp,%ebp
f0100674:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100677:	8b 45 08             	mov    0x8(%ebp),%eax
f010067a:	e8 aa fc ff ff       	call   f0100329 <cons_putc>
}
f010067f:	c9                   	leave  
f0100680:	c3                   	ret    

f0100681 <getchar>:

int
getchar(void)
{
f0100681:	55                   	push   %ebp
f0100682:	89 e5                	mov    %esp,%ebp
f0100684:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100687:	e8 a9 fe ff ff       	call   f0100535 <cons_getc>
f010068c:	85 c0                	test   %eax,%eax
f010068e:	74 f7                	je     f0100687 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100690:	c9                   	leave  
f0100691:	c3                   	ret    

f0100692 <iscons>:

int
iscons(int fdnum)
{
f0100692:	55                   	push   %ebp
f0100693:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100695:	b8 01 00 00 00       	mov    $0x1,%eax
f010069a:	5d                   	pop    %ebp
f010069b:	c3                   	ret    
f010069c:	66 90                	xchg   %ax,%ax
f010069e:	66 90                	xchg   %ax,%ax

f01006a0 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006a0:	55                   	push   %ebp
f01006a1:	89 e5                	mov    %esp,%ebp
f01006a3:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006a6:	c7 44 24 08 c0 1c 10 	movl   $0xf0101cc0,0x8(%esp)
f01006ad:	f0 
f01006ae:	c7 44 24 04 de 1c 10 	movl   $0xf0101cde,0x4(%esp)
f01006b5:	f0 
f01006b6:	c7 04 24 e3 1c 10 f0 	movl   $0xf0101ce3,(%esp)
f01006bd:	e8 1c 03 00 00       	call   f01009de <cprintf>
f01006c2:	c7 44 24 08 84 1d 10 	movl   $0xf0101d84,0x8(%esp)
f01006c9:	f0 
f01006ca:	c7 44 24 04 ec 1c 10 	movl   $0xf0101cec,0x4(%esp)
f01006d1:	f0 
f01006d2:	c7 04 24 e3 1c 10 f0 	movl   $0xf0101ce3,(%esp)
f01006d9:	e8 00 03 00 00       	call   f01009de <cprintf>
f01006de:	c7 44 24 08 f5 1c 10 	movl   $0xf0101cf5,0x8(%esp)
f01006e5:	f0 
f01006e6:	c7 44 24 04 12 1d 10 	movl   $0xf0101d12,0x4(%esp)
f01006ed:	f0 
f01006ee:	c7 04 24 e3 1c 10 f0 	movl   $0xf0101ce3,(%esp)
f01006f5:	e8 e4 02 00 00       	call   f01009de <cprintf>
	return 0;
}
f01006fa:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ff:	c9                   	leave  
f0100700:	c3                   	ret    

f0100701 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100701:	55                   	push   %ebp
f0100702:	89 e5                	mov    %esp,%ebp
f0100704:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100707:	c7 04 24 1d 1d 10 f0 	movl   $0xf0101d1d,(%esp)
f010070e:	e8 cb 02 00 00       	call   f01009de <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100713:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010071a:	00 
f010071b:	c7 04 24 ac 1d 10 f0 	movl   $0xf0101dac,(%esp)
f0100722:	e8 b7 02 00 00       	call   f01009de <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100727:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010072e:	00 
f010072f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100736:	f0 
f0100737:	c7 04 24 d4 1d 10 f0 	movl   $0xf0101dd4,(%esp)
f010073e:	e8 9b 02 00 00       	call   f01009de <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100743:	c7 44 24 08 d7 19 10 	movl   $0x1019d7,0x8(%esp)
f010074a:	00 
f010074b:	c7 44 24 04 d7 19 10 	movl   $0xf01019d7,0x4(%esp)
f0100752:	f0 
f0100753:	c7 04 24 f8 1d 10 f0 	movl   $0xf0101df8,(%esp)
f010075a:	e8 7f 02 00 00       	call   f01009de <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010075f:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100766:	00 
f0100767:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f010076e:	f0 
f010076f:	c7 04 24 1c 1e 10 f0 	movl   $0xf0101e1c,(%esp)
f0100776:	e8 63 02 00 00       	call   f01009de <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010077b:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100782:	00 
f0100783:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f010078a:	f0 
f010078b:	c7 04 24 40 1e 10 f0 	movl   $0xf0101e40,(%esp)
f0100792:	e8 47 02 00 00       	call   f01009de <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100797:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f010079c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01007a1:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007a6:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01007ac:	85 c0                	test   %eax,%eax
f01007ae:	0f 48 c2             	cmovs  %edx,%eax
f01007b1:	c1 f8 0a             	sar    $0xa,%eax
f01007b4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007b8:	c7 04 24 64 1e 10 f0 	movl   $0xf0101e64,(%esp)
f01007bf:	e8 1a 02 00 00       	call   f01009de <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01007c4:	b8 00 00 00 00       	mov    $0x0,%eax
f01007c9:	c9                   	leave  
f01007ca:	c3                   	ret    

f01007cb <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007cb:	55                   	push   %ebp
f01007cc:	89 e5                	mov    %esp,%ebp
f01007ce:	57                   	push   %edi
f01007cf:	56                   	push   %esi
f01007d0:	53                   	push   %ebx
f01007d1:	83 ec 6c             	sub    $0x6c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01007d4:	89 eb                	mov    %ebp,%ebx
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
f01007d6:	c7 04 24 36 1d 10 f0 	movl   $0xf0101d36,(%esp)
f01007dd:	e8 fc 01 00 00       	call   f01009de <cprintf>
	
	while (ebp){
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
		debuginfo_eip(eip, &sym);
f01007e2:	8d 7d d0             	lea    -0x30(%ebp),%edi
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f01007e5:	eb 6d                	jmp    f0100854 <mon_backtrace+0x89>
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
f01007e7:	8b 73 04             	mov    0x4(%ebx),%esi
		debuginfo_eip(eip, &sym);
f01007ea:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01007ee:	89 34 24             	mov    %esi,(%esp)
f01007f1:	e8 df 02 00 00       	call   f0100ad5 <debuginfo_eip>
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n %s:%d: %.*s+%d\n",ebp,eip,
f01007f6:	89 f0                	mov    %esi,%eax
f01007f8:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01007fb:	89 44 24 30          	mov    %eax,0x30(%esp)
f01007ff:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100802:	89 44 24 2c          	mov    %eax,0x2c(%esp)
f0100806:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100809:	89 44 24 28          	mov    %eax,0x28(%esp)
f010080d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100810:	89 44 24 24          	mov    %eax,0x24(%esp)
f0100814:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100817:	89 44 24 20          	mov    %eax,0x20(%esp)
f010081b:	8b 43 18             	mov    0x18(%ebx),%eax
f010081e:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f0100822:	8b 43 14             	mov    0x14(%ebx),%eax
f0100825:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100829:	8b 43 10             	mov    0x10(%ebx),%eax
f010082c:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100830:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100833:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100837:	8b 43 08             	mov    0x8(%ebx),%eax
f010083a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010083e:	89 74 24 08          	mov    %esi,0x8(%esp)
f0100842:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100846:	c7 04 24 90 1e 10 f0 	movl   $0xf0101e90,(%esp)
f010084d:	e8 8c 01 00 00       	call   f01009de <cprintf>
		*((uint32_t *)ebp + 6), sym.eip_file,
			      sym.eip_line,
			      sym.eip_fn_namelen,
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
f0100852:	8b 1b                	mov    (%ebx),%ebx
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f0100854:	85 db                	test   %ebx,%ebx
f0100856:	75 8f                	jne    f01007e7 <mon_backtrace+0x1c>
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
	}
	return 0;
}
f0100858:	b8 00 00 00 00       	mov    $0x0,%eax
f010085d:	83 c4 6c             	add    $0x6c,%esp
f0100860:	5b                   	pop    %ebx
f0100861:	5e                   	pop    %esi
f0100862:	5f                   	pop    %edi
f0100863:	5d                   	pop    %ebp
f0100864:	c3                   	ret    

f0100865 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100865:	55                   	push   %ebp
f0100866:	89 e5                	mov    %esp,%ebp
f0100868:	57                   	push   %edi
f0100869:	56                   	push   %esi
f010086a:	53                   	push   %ebx
f010086b:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010086e:	c7 04 24 d4 1e 10 f0 	movl   $0xf0101ed4,(%esp)
f0100875:	e8 64 01 00 00       	call   f01009de <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010087a:	c7 04 24 f8 1e 10 f0 	movl   $0xf0101ef8,(%esp)
f0100881:	e8 58 01 00 00       	call   f01009de <cprintf>


	while (1) {
		buf = readline("K> ");
f0100886:	c7 04 24 48 1d 10 f0 	movl   $0xf0101d48,(%esp)
f010088d:	e8 5e 0a 00 00       	call   f01012f0 <readline>
f0100892:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100894:	85 c0                	test   %eax,%eax
f0100896:	74 ee                	je     f0100886 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100898:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010089f:	be 00 00 00 00       	mov    $0x0,%esi
f01008a4:	eb 0a                	jmp    f01008b0 <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008a6:	c6 03 00             	movb   $0x0,(%ebx)
f01008a9:	89 f7                	mov    %esi,%edi
f01008ab:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01008ae:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008b0:	0f b6 03             	movzbl (%ebx),%eax
f01008b3:	84 c0                	test   %al,%al
f01008b5:	74 63                	je     f010091a <monitor+0xb5>
f01008b7:	0f be c0             	movsbl %al,%eax
f01008ba:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008be:	c7 04 24 4c 1d 10 f0 	movl   $0xf0101d4c,(%esp)
f01008c5:	e8 40 0c 00 00       	call   f010150a <strchr>
f01008ca:	85 c0                	test   %eax,%eax
f01008cc:	75 d8                	jne    f01008a6 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f01008ce:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008d1:	74 47                	je     f010091a <monitor+0xb5>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008d3:	83 fe 0f             	cmp    $0xf,%esi
f01008d6:	75 16                	jne    f01008ee <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008d8:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008df:	00 
f01008e0:	c7 04 24 51 1d 10 f0 	movl   $0xf0101d51,(%esp)
f01008e7:	e8 f2 00 00 00       	call   f01009de <cprintf>
f01008ec:	eb 98                	jmp    f0100886 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f01008ee:	8d 7e 01             	lea    0x1(%esi),%edi
f01008f1:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008f5:	eb 03                	jmp    f01008fa <monitor+0x95>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008f7:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008fa:	0f b6 03             	movzbl (%ebx),%eax
f01008fd:	84 c0                	test   %al,%al
f01008ff:	74 ad                	je     f01008ae <monitor+0x49>
f0100901:	0f be c0             	movsbl %al,%eax
f0100904:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100908:	c7 04 24 4c 1d 10 f0 	movl   $0xf0101d4c,(%esp)
f010090f:	e8 f6 0b 00 00       	call   f010150a <strchr>
f0100914:	85 c0                	test   %eax,%eax
f0100916:	74 df                	je     f01008f7 <monitor+0x92>
f0100918:	eb 94                	jmp    f01008ae <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f010091a:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100921:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100922:	85 f6                	test   %esi,%esi
f0100924:	0f 84 5c ff ff ff    	je     f0100886 <monitor+0x21>
f010092a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010092f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100932:	8b 04 85 20 1f 10 f0 	mov    -0xfefe0e0(,%eax,4),%eax
f0100939:	89 44 24 04          	mov    %eax,0x4(%esp)
f010093d:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100940:	89 04 24             	mov    %eax,(%esp)
f0100943:	e8 64 0b 00 00       	call   f01014ac <strcmp>
f0100948:	85 c0                	test   %eax,%eax
f010094a:	75 24                	jne    f0100970 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f010094c:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010094f:	8b 55 08             	mov    0x8(%ebp),%edx
f0100952:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100956:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100959:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010095d:	89 34 24             	mov    %esi,(%esp)
f0100960:	ff 14 85 28 1f 10 f0 	call   *-0xfefe0d8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100967:	85 c0                	test   %eax,%eax
f0100969:	78 25                	js     f0100990 <monitor+0x12b>
f010096b:	e9 16 ff ff ff       	jmp    f0100886 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100970:	83 c3 01             	add    $0x1,%ebx
f0100973:	83 fb 03             	cmp    $0x3,%ebx
f0100976:	75 b7                	jne    f010092f <monitor+0xca>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100978:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010097b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010097f:	c7 04 24 6e 1d 10 f0 	movl   $0xf0101d6e,(%esp)
f0100986:	e8 53 00 00 00       	call   f01009de <cprintf>
f010098b:	e9 f6 fe ff ff       	jmp    f0100886 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100990:	83 c4 5c             	add    $0x5c,%esp
f0100993:	5b                   	pop    %ebx
f0100994:	5e                   	pop    %esi
f0100995:	5f                   	pop    %edi
f0100996:	5d                   	pop    %ebp
f0100997:	c3                   	ret    

f0100998 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100998:	55                   	push   %ebp
f0100999:	89 e5                	mov    %esp,%ebp
f010099b:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010099e:	8b 45 08             	mov    0x8(%ebp),%eax
f01009a1:	89 04 24             	mov    %eax,(%esp)
f01009a4:	e8 c8 fc ff ff       	call   f0100671 <cputchar>
	*cnt++;
}
f01009a9:	c9                   	leave  
f01009aa:	c3                   	ret    

f01009ab <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01009ab:	55                   	push   %ebp
f01009ac:	89 e5                	mov    %esp,%ebp
f01009ae:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01009b1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009b8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009bb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01009c2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009c6:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009c9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009cd:	c7 04 24 98 09 10 f0 	movl   $0xf0100998,(%esp)
f01009d4:	e8 b5 04 00 00       	call   f0100e8e <vprintfmt>
	return cnt;
}
f01009d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009dc:	c9                   	leave  
f01009dd:	c3                   	ret    

f01009de <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009de:	55                   	push   %ebp
f01009df:	89 e5                	mov    %esp,%ebp
f01009e1:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009e4:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009eb:	8b 45 08             	mov    0x8(%ebp),%eax
f01009ee:	89 04 24             	mov    %eax,(%esp)
f01009f1:	e8 b5 ff ff ff       	call   f01009ab <vcprintf>
	va_end(ap);

	return cnt;
}
f01009f6:	c9                   	leave  
f01009f7:	c3                   	ret    

f01009f8 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009f8:	55                   	push   %ebp
f01009f9:	89 e5                	mov    %esp,%ebp
f01009fb:	57                   	push   %edi
f01009fc:	56                   	push   %esi
f01009fd:	53                   	push   %ebx
f01009fe:	83 ec 10             	sub    $0x10,%esp
f0100a01:	89 c6                	mov    %eax,%esi
f0100a03:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a06:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100a09:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a0c:	8b 1a                	mov    (%edx),%ebx
f0100a0e:	8b 01                	mov    (%ecx),%eax
f0100a10:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a13:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100a1a:	eb 77                	jmp    f0100a93 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100a1c:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a1f:	01 d8                	add    %ebx,%eax
f0100a21:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100a26:	99                   	cltd   
f0100a27:	f7 f9                	idiv   %ecx
f0100a29:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a2b:	eb 01                	jmp    f0100a2e <stab_binsearch+0x36>
			m--;
f0100a2d:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a2e:	39 d9                	cmp    %ebx,%ecx
f0100a30:	7c 1d                	jl     f0100a4f <stab_binsearch+0x57>
f0100a32:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a35:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a3a:	39 fa                	cmp    %edi,%edx
f0100a3c:	75 ef                	jne    f0100a2d <stab_binsearch+0x35>
f0100a3e:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a41:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a44:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100a48:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a4b:	73 18                	jae    f0100a65 <stab_binsearch+0x6d>
f0100a4d:	eb 05                	jmp    f0100a54 <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a4f:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100a52:	eb 3f                	jmp    f0100a93 <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a54:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a57:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0100a59:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a5c:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a63:	eb 2e                	jmp    f0100a93 <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a65:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a68:	73 15                	jae    f0100a7f <stab_binsearch+0x87>
			*region_right = m - 1;
f0100a6a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a6d:	48                   	dec    %eax
f0100a6e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a71:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a74:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a76:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a7d:	eb 14                	jmp    f0100a93 <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a7f:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a82:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100a85:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0100a87:	ff 45 0c             	incl   0xc(%ebp)
f0100a8a:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a8c:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a93:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a96:	7e 84                	jle    f0100a1c <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a98:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100a9c:	75 0d                	jne    f0100aab <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100a9e:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100aa1:	8b 00                	mov    (%eax),%eax
f0100aa3:	48                   	dec    %eax
f0100aa4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100aa7:	89 07                	mov    %eax,(%edi)
f0100aa9:	eb 22                	jmp    f0100acd <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100aab:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100aae:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100ab0:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100ab3:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ab5:	eb 01                	jmp    f0100ab8 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100ab7:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ab8:	39 c1                	cmp    %eax,%ecx
f0100aba:	7d 0c                	jge    f0100ac8 <stab_binsearch+0xd0>
f0100abc:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100abf:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100ac4:	39 fa                	cmp    %edi,%edx
f0100ac6:	75 ef                	jne    f0100ab7 <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100ac8:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100acb:	89 07                	mov    %eax,(%edi)
	}
}
f0100acd:	83 c4 10             	add    $0x10,%esp
f0100ad0:	5b                   	pop    %ebx
f0100ad1:	5e                   	pop    %esi
f0100ad2:	5f                   	pop    %edi
f0100ad3:	5d                   	pop    %ebp
f0100ad4:	c3                   	ret    

f0100ad5 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100ad5:	55                   	push   %ebp
f0100ad6:	89 e5                	mov    %esp,%ebp
f0100ad8:	57                   	push   %edi
f0100ad9:	56                   	push   %esi
f0100ada:	53                   	push   %ebx
f0100adb:	83 ec 3c             	sub    $0x3c,%esp
f0100ade:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ae1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100ae4:	c7 03 44 1f 10 f0    	movl   $0xf0101f44,(%ebx)
	info->eip_line = 0;
f0100aea:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100af1:	c7 43 08 44 1f 10 f0 	movl   $0xf0101f44,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100af8:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100aff:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b02:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b09:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b0f:	76 12                	jbe    f0100b23 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b11:	b8 40 74 10 f0       	mov    $0xf0107440,%eax
f0100b16:	3d 21 5b 10 f0       	cmp    $0xf0105b21,%eax
f0100b1b:	0f 86 cd 01 00 00    	jbe    f0100cee <debuginfo_eip+0x219>
f0100b21:	eb 1c                	jmp    f0100b3f <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b23:	c7 44 24 08 4e 1f 10 	movl   $0xf0101f4e,0x8(%esp)
f0100b2a:	f0 
f0100b2b:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b32:	00 
f0100b33:	c7 04 24 5b 1f 10 f0 	movl   $0xf0101f5b,(%esp)
f0100b3a:	e8 dd f5 ff ff       	call   f010011c <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b3f:	80 3d 3f 74 10 f0 00 	cmpb   $0x0,0xf010743f
f0100b46:	0f 85 a9 01 00 00    	jne    f0100cf5 <debuginfo_eip+0x220>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b4c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b53:	b8 20 5b 10 f0       	mov    $0xf0105b20,%eax
f0100b58:	2d 90 21 10 f0       	sub    $0xf0102190,%eax
f0100b5d:	c1 f8 02             	sar    $0x2,%eax
f0100b60:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b66:	83 e8 01             	sub    $0x1,%eax
f0100b69:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b6c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b70:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b77:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b7a:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b7d:	b8 90 21 10 f0       	mov    $0xf0102190,%eax
f0100b82:	e8 71 fe ff ff       	call   f01009f8 <stab_binsearch>
	if (lfile == 0)
f0100b87:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b8a:	85 c0                	test   %eax,%eax
f0100b8c:	0f 84 6a 01 00 00    	je     f0100cfc <debuginfo_eip+0x227>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b92:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b95:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b98:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b9b:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b9f:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100ba6:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100ba9:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100bac:	b8 90 21 10 f0       	mov    $0xf0102190,%eax
f0100bb1:	e8 42 fe ff ff       	call   f01009f8 <stab_binsearch>

	if (lfun <= rfun) {
f0100bb6:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100bb9:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100bbc:	39 d0                	cmp    %edx,%eax
f0100bbe:	7f 3d                	jg     f0100bfd <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100bc0:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100bc3:	8d b9 90 21 10 f0    	lea    -0xfefde70(%ecx),%edi
f0100bc9:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100bcc:	8b 89 90 21 10 f0    	mov    -0xfefde70(%ecx),%ecx
f0100bd2:	bf 40 74 10 f0       	mov    $0xf0107440,%edi
f0100bd7:	81 ef 21 5b 10 f0    	sub    $0xf0105b21,%edi
f0100bdd:	39 f9                	cmp    %edi,%ecx
f0100bdf:	73 09                	jae    f0100bea <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100be1:	81 c1 21 5b 10 f0    	add    $0xf0105b21,%ecx
f0100be7:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100bea:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100bed:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100bf0:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100bf3:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100bf5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100bf8:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100bfb:	eb 0f                	jmp    f0100c0c <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bfd:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c00:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c03:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100c06:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c09:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c0c:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100c13:	00 
f0100c14:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c17:	89 04 24             	mov    %eax,(%esp)
f0100c1a:	e8 0c 09 00 00       	call   f010152b <strfind>
f0100c1f:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c22:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
f0100c25:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c29:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100c30:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100c33:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100c36:	b8 90 21 10 f0       	mov    $0xf0102190,%eax
f0100c3b:	e8 b8 fd ff ff       	call   f01009f8 <stab_binsearch>
	if (lline > rline) {
f0100c40:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c43:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100c46:	0f 8f b7 00 00 00    	jg     f0100d03 <debuginfo_eip+0x22e>
		return -1; //Did not find the line number in the stab
	}
	info->eip_line = stabs[lline].n_desc; //If found update the info object with the correct line number
f0100c4c:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100c4f:	0f b7 80 96 21 10 f0 	movzwl -0xfefde6a(%eax),%eax
f0100c56:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c59:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c5c:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100c5f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c62:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100c65:	81 c2 90 21 10 f0    	add    $0xf0102190,%edx
f0100c6b:	eb 06                	jmp    f0100c73 <debuginfo_eip+0x19e>
f0100c6d:	83 e8 01             	sub    $0x1,%eax
f0100c70:	83 ea 0c             	sub    $0xc,%edx
f0100c73:	89 c6                	mov    %eax,%esi
f0100c75:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0100c78:	7f 33                	jg     f0100cad <debuginfo_eip+0x1d8>
	       && stabs[lline].n_type != N_SOL
f0100c7a:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100c7e:	80 f9 84             	cmp    $0x84,%cl
f0100c81:	74 0b                	je     f0100c8e <debuginfo_eip+0x1b9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c83:	80 f9 64             	cmp    $0x64,%cl
f0100c86:	75 e5                	jne    f0100c6d <debuginfo_eip+0x198>
f0100c88:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0100c8c:	74 df                	je     f0100c6d <debuginfo_eip+0x198>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c8e:	6b f6 0c             	imul   $0xc,%esi,%esi
f0100c91:	8b 86 90 21 10 f0    	mov    -0xfefde70(%esi),%eax
f0100c97:	ba 40 74 10 f0       	mov    $0xf0107440,%edx
f0100c9c:	81 ea 21 5b 10 f0    	sub    $0xf0105b21,%edx
f0100ca2:	39 d0                	cmp    %edx,%eax
f0100ca4:	73 07                	jae    f0100cad <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100ca6:	05 21 5b 10 f0       	add    $0xf0105b21,%eax
f0100cab:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cad:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100cb0:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cb3:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cb8:	39 ca                	cmp    %ecx,%edx
f0100cba:	7d 53                	jge    f0100d0f <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
f0100cbc:	8d 42 01             	lea    0x1(%edx),%eax
f0100cbf:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100cc2:	89 c2                	mov    %eax,%edx
f0100cc4:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100cc7:	05 90 21 10 f0       	add    $0xf0102190,%eax
f0100ccc:	89 ce                	mov    %ecx,%esi
f0100cce:	eb 04                	jmp    f0100cd4 <debuginfo_eip+0x1ff>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100cd0:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100cd4:	39 d6                	cmp    %edx,%esi
f0100cd6:	7e 32                	jle    f0100d0a <debuginfo_eip+0x235>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100cd8:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100cdc:	83 c2 01             	add    $0x1,%edx
f0100cdf:	83 c0 0c             	add    $0xc,%eax
f0100ce2:	80 f9 a0             	cmp    $0xa0,%cl
f0100ce5:	74 e9                	je     f0100cd0 <debuginfo_eip+0x1fb>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100ce7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cec:	eb 21                	jmp    f0100d0f <debuginfo_eip+0x23a>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100cee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cf3:	eb 1a                	jmp    f0100d0f <debuginfo_eip+0x23a>
f0100cf5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cfa:	eb 13                	jmp    f0100d0f <debuginfo_eip+0x23a>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100cfc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d01:	eb 0c                	jmp    f0100d0f <debuginfo_eip+0x23a>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
	if (lline > rline) {
		return -1; //Did not find the line number in the stab
f0100d03:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d08:	eb 05                	jmp    f0100d0f <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d0a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d0f:	83 c4 3c             	add    $0x3c,%esp
f0100d12:	5b                   	pop    %ebx
f0100d13:	5e                   	pop    %esi
f0100d14:	5f                   	pop    %edi
f0100d15:	5d                   	pop    %ebp
f0100d16:	c3                   	ret    
f0100d17:	66 90                	xchg   %ax,%ax
f0100d19:	66 90                	xchg   %ax,%ax
f0100d1b:	66 90                	xchg   %ax,%ax
f0100d1d:	66 90                	xchg   %ax,%ax
f0100d1f:	90                   	nop

f0100d20 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d20:	55                   	push   %ebp
f0100d21:	89 e5                	mov    %esp,%ebp
f0100d23:	57                   	push   %edi
f0100d24:	56                   	push   %esi
f0100d25:	53                   	push   %ebx
f0100d26:	83 ec 3c             	sub    $0x3c,%esp
f0100d29:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d2c:	89 d7                	mov    %edx,%edi
f0100d2e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d31:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d34:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d37:	89 c3                	mov    %eax,%ebx
f0100d39:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100d3c:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d3f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d42:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d47:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d4a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100d4d:	39 d9                	cmp    %ebx,%ecx
f0100d4f:	72 05                	jb     f0100d56 <printnum+0x36>
f0100d51:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100d54:	77 69                	ja     f0100dbf <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d56:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100d59:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100d5d:	83 ee 01             	sub    $0x1,%esi
f0100d60:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100d64:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d68:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100d6c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100d70:	89 c3                	mov    %eax,%ebx
f0100d72:	89 d6                	mov    %edx,%esi
f0100d74:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100d77:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100d7a:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100d7e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100d82:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d85:	89 04 24             	mov    %eax,(%esp)
f0100d88:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d8b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d8f:	e8 bc 09 00 00       	call   f0101750 <__udivdi3>
f0100d94:	89 d9                	mov    %ebx,%ecx
f0100d96:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100d9a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100d9e:	89 04 24             	mov    %eax,(%esp)
f0100da1:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100da5:	89 fa                	mov    %edi,%edx
f0100da7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100daa:	e8 71 ff ff ff       	call   f0100d20 <printnum>
f0100daf:	eb 1b                	jmp    f0100dcc <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100db1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100db5:	8b 45 18             	mov    0x18(%ebp),%eax
f0100db8:	89 04 24             	mov    %eax,(%esp)
f0100dbb:	ff d3                	call   *%ebx
f0100dbd:	eb 03                	jmp    f0100dc2 <printnum+0xa2>
f0100dbf:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100dc2:	83 ee 01             	sub    $0x1,%esi
f0100dc5:	85 f6                	test   %esi,%esi
f0100dc7:	7f e8                	jg     f0100db1 <printnum+0x91>
f0100dc9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100dcc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100dd0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100dd4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100dd7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100dda:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100dde:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100de2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100de5:	89 04 24             	mov    %eax,(%esp)
f0100de8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100deb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100def:	e8 8c 0a 00 00       	call   f0101880 <__umoddi3>
f0100df4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100df8:	0f be 80 69 1f 10 f0 	movsbl -0xfefe097(%eax),%eax
f0100dff:	89 04 24             	mov    %eax,(%esp)
f0100e02:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e05:	ff d0                	call   *%eax
}
f0100e07:	83 c4 3c             	add    $0x3c,%esp
f0100e0a:	5b                   	pop    %ebx
f0100e0b:	5e                   	pop    %esi
f0100e0c:	5f                   	pop    %edi
f0100e0d:	5d                   	pop    %ebp
f0100e0e:	c3                   	ret    

f0100e0f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100e0f:	55                   	push   %ebp
f0100e10:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e12:	83 fa 01             	cmp    $0x1,%edx
f0100e15:	7e 0e                	jle    f0100e25 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100e17:	8b 10                	mov    (%eax),%edx
f0100e19:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100e1c:	89 08                	mov    %ecx,(%eax)
f0100e1e:	8b 02                	mov    (%edx),%eax
f0100e20:	8b 52 04             	mov    0x4(%edx),%edx
f0100e23:	eb 22                	jmp    f0100e47 <getuint+0x38>
	else if (lflag)
f0100e25:	85 d2                	test   %edx,%edx
f0100e27:	74 10                	je     f0100e39 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100e29:	8b 10                	mov    (%eax),%edx
f0100e2b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e2e:	89 08                	mov    %ecx,(%eax)
f0100e30:	8b 02                	mov    (%edx),%eax
f0100e32:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e37:	eb 0e                	jmp    f0100e47 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100e39:	8b 10                	mov    (%eax),%edx
f0100e3b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e3e:	89 08                	mov    %ecx,(%eax)
f0100e40:	8b 02                	mov    (%edx),%eax
f0100e42:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100e47:	5d                   	pop    %ebp
f0100e48:	c3                   	ret    

f0100e49 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e49:	55                   	push   %ebp
f0100e4a:	89 e5                	mov    %esp,%ebp
f0100e4c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e4f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e53:	8b 10                	mov    (%eax),%edx
f0100e55:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e58:	73 0a                	jae    f0100e64 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e5a:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e5d:	89 08                	mov    %ecx,(%eax)
f0100e5f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e62:	88 02                	mov    %al,(%edx)
}
f0100e64:	5d                   	pop    %ebp
f0100e65:	c3                   	ret    

f0100e66 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100e66:	55                   	push   %ebp
f0100e67:	89 e5                	mov    %esp,%ebp
f0100e69:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100e6c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e6f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e73:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e76:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e7a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e7d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e81:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e84:	89 04 24             	mov    %eax,(%esp)
f0100e87:	e8 02 00 00 00       	call   f0100e8e <vprintfmt>
	va_end(ap);
}
f0100e8c:	c9                   	leave  
f0100e8d:	c3                   	ret    

f0100e8e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100e8e:	55                   	push   %ebp
f0100e8f:	89 e5                	mov    %esp,%ebp
f0100e91:	57                   	push   %edi
f0100e92:	56                   	push   %esi
f0100e93:	53                   	push   %ebx
f0100e94:	83 ec 3c             	sub    $0x3c,%esp
f0100e97:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100e9a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100e9d:	eb 14                	jmp    f0100eb3 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100e9f:	85 c0                	test   %eax,%eax
f0100ea1:	0f 84 b3 03 00 00    	je     f010125a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0100ea7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100eab:	89 04 24             	mov    %eax,(%esp)
f0100eae:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100eb1:	89 f3                	mov    %esi,%ebx
f0100eb3:	8d 73 01             	lea    0x1(%ebx),%esi
f0100eb6:	0f b6 03             	movzbl (%ebx),%eax
f0100eb9:	83 f8 25             	cmp    $0x25,%eax
f0100ebc:	75 e1                	jne    f0100e9f <vprintfmt+0x11>
f0100ebe:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100ec2:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0100ec9:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100ed0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100ed7:	ba 00 00 00 00       	mov    $0x0,%edx
f0100edc:	eb 1d                	jmp    f0100efb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ede:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100ee0:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100ee4:	eb 15                	jmp    f0100efb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ee6:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100ee8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100eec:	eb 0d                	jmp    f0100efb <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100eee:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100ef1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100ef4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100efb:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100efe:	0f b6 0e             	movzbl (%esi),%ecx
f0100f01:	0f b6 c1             	movzbl %cl,%eax
f0100f04:	83 e9 23             	sub    $0x23,%ecx
f0100f07:	80 f9 55             	cmp    $0x55,%cl
f0100f0a:	0f 87 2a 03 00 00    	ja     f010123a <vprintfmt+0x3ac>
f0100f10:	0f b6 c9             	movzbl %cl,%ecx
f0100f13:	ff 24 8d 00 20 10 f0 	jmp    *-0xfefe000(,%ecx,4)
f0100f1a:	89 de                	mov    %ebx,%esi
f0100f1c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f21:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100f24:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0100f28:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100f2b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0100f2e:	83 fb 09             	cmp    $0x9,%ebx
f0100f31:	77 36                	ja     f0100f69 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f33:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100f36:	eb e9                	jmp    f0100f21 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f38:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f3b:	8d 48 04             	lea    0x4(%eax),%ecx
f0100f3e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100f41:	8b 00                	mov    (%eax),%eax
f0100f43:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f46:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100f48:	eb 22                	jmp    f0100f6c <vprintfmt+0xde>
f0100f4a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100f4d:	85 c9                	test   %ecx,%ecx
f0100f4f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f54:	0f 49 c1             	cmovns %ecx,%eax
f0100f57:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f5a:	89 de                	mov    %ebx,%esi
f0100f5c:	eb 9d                	jmp    f0100efb <vprintfmt+0x6d>
f0100f5e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100f60:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0100f67:	eb 92                	jmp    f0100efb <vprintfmt+0x6d>
f0100f69:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f0100f6c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100f70:	79 89                	jns    f0100efb <vprintfmt+0x6d>
f0100f72:	e9 77 ff ff ff       	jmp    f0100eee <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100f77:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f7a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100f7c:	e9 7a ff ff ff       	jmp    f0100efb <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100f81:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f84:	8d 50 04             	lea    0x4(%eax),%edx
f0100f87:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f8a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f8e:	8b 00                	mov    (%eax),%eax
f0100f90:	89 04 24             	mov    %eax,(%esp)
f0100f93:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100f96:	e9 18 ff ff ff       	jmp    f0100eb3 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f9b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f9e:	8d 50 04             	lea    0x4(%eax),%edx
f0100fa1:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fa4:	8b 00                	mov    (%eax),%eax
f0100fa6:	99                   	cltd   
f0100fa7:	31 d0                	xor    %edx,%eax
f0100fa9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100fab:	83 f8 07             	cmp    $0x7,%eax
f0100fae:	7f 0b                	jg     f0100fbb <vprintfmt+0x12d>
f0100fb0:	8b 14 85 60 21 10 f0 	mov    -0xfefdea0(,%eax,4),%edx
f0100fb7:	85 d2                	test   %edx,%edx
f0100fb9:	75 20                	jne    f0100fdb <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f0100fbb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fbf:	c7 44 24 08 81 1f 10 	movl   $0xf0101f81,0x8(%esp)
f0100fc6:	f0 
f0100fc7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fcb:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fce:	89 04 24             	mov    %eax,(%esp)
f0100fd1:	e8 90 fe ff ff       	call   f0100e66 <printfmt>
f0100fd6:	e9 d8 fe ff ff       	jmp    f0100eb3 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0100fdb:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100fdf:	c7 44 24 08 8a 1f 10 	movl   $0xf0101f8a,0x8(%esp)
f0100fe6:	f0 
f0100fe7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100feb:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fee:	89 04 24             	mov    %eax,(%esp)
f0100ff1:	e8 70 fe ff ff       	call   f0100e66 <printfmt>
f0100ff6:	e9 b8 fe ff ff       	jmp    f0100eb3 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ffb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100ffe:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101001:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101004:	8b 45 14             	mov    0x14(%ebp),%eax
f0101007:	8d 50 04             	lea    0x4(%eax),%edx
f010100a:	89 55 14             	mov    %edx,0x14(%ebp)
f010100d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010100f:	85 f6                	test   %esi,%esi
f0101011:	b8 7a 1f 10 f0       	mov    $0xf0101f7a,%eax
f0101016:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0101019:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010101d:	0f 84 97 00 00 00    	je     f01010ba <vprintfmt+0x22c>
f0101023:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0101027:	0f 8e 9b 00 00 00    	jle    f01010c8 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f010102d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101031:	89 34 24             	mov    %esi,(%esp)
f0101034:	e8 9f 03 00 00       	call   f01013d8 <strnlen>
f0101039:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010103c:	29 c2                	sub    %eax,%edx
f010103e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0101041:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0101045:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101048:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010104b:	8b 75 08             	mov    0x8(%ebp),%esi
f010104e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101051:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101053:	eb 0f                	jmp    f0101064 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0101055:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101059:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010105c:	89 04 24             	mov    %eax,(%esp)
f010105f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101061:	83 eb 01             	sub    $0x1,%ebx
f0101064:	85 db                	test   %ebx,%ebx
f0101066:	7f ed                	jg     f0101055 <vprintfmt+0x1c7>
f0101068:	8b 75 d8             	mov    -0x28(%ebp),%esi
f010106b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010106e:	85 d2                	test   %edx,%edx
f0101070:	b8 00 00 00 00       	mov    $0x0,%eax
f0101075:	0f 49 c2             	cmovns %edx,%eax
f0101078:	29 c2                	sub    %eax,%edx
f010107a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010107d:	89 d7                	mov    %edx,%edi
f010107f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101082:	eb 50                	jmp    f01010d4 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101084:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101088:	74 1e                	je     f01010a8 <vprintfmt+0x21a>
f010108a:	0f be d2             	movsbl %dl,%edx
f010108d:	83 ea 20             	sub    $0x20,%edx
f0101090:	83 fa 5e             	cmp    $0x5e,%edx
f0101093:	76 13                	jbe    f01010a8 <vprintfmt+0x21a>
					putch('?', putdat);
f0101095:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101098:	89 44 24 04          	mov    %eax,0x4(%esp)
f010109c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01010a3:	ff 55 08             	call   *0x8(%ebp)
f01010a6:	eb 0d                	jmp    f01010b5 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f01010a8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01010ab:	89 54 24 04          	mov    %edx,0x4(%esp)
f01010af:	89 04 24             	mov    %eax,(%esp)
f01010b2:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010b5:	83 ef 01             	sub    $0x1,%edi
f01010b8:	eb 1a                	jmp    f01010d4 <vprintfmt+0x246>
f01010ba:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01010bd:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01010c0:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01010c3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01010c6:	eb 0c                	jmp    f01010d4 <vprintfmt+0x246>
f01010c8:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01010cb:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01010ce:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01010d1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01010d4:	83 c6 01             	add    $0x1,%esi
f01010d7:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f01010db:	0f be c2             	movsbl %dl,%eax
f01010de:	85 c0                	test   %eax,%eax
f01010e0:	74 27                	je     f0101109 <vprintfmt+0x27b>
f01010e2:	85 db                	test   %ebx,%ebx
f01010e4:	78 9e                	js     f0101084 <vprintfmt+0x1f6>
f01010e6:	83 eb 01             	sub    $0x1,%ebx
f01010e9:	79 99                	jns    f0101084 <vprintfmt+0x1f6>
f01010eb:	89 f8                	mov    %edi,%eax
f01010ed:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01010f0:	8b 75 08             	mov    0x8(%ebp),%esi
f01010f3:	89 c3                	mov    %eax,%ebx
f01010f5:	eb 1a                	jmp    f0101111 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01010f7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010fb:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101102:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101104:	83 eb 01             	sub    $0x1,%ebx
f0101107:	eb 08                	jmp    f0101111 <vprintfmt+0x283>
f0101109:	89 fb                	mov    %edi,%ebx
f010110b:	8b 75 08             	mov    0x8(%ebp),%esi
f010110e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101111:	85 db                	test   %ebx,%ebx
f0101113:	7f e2                	jg     f01010f7 <vprintfmt+0x269>
f0101115:	89 75 08             	mov    %esi,0x8(%ebp)
f0101118:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010111b:	e9 93 fd ff ff       	jmp    f0100eb3 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101120:	83 fa 01             	cmp    $0x1,%edx
f0101123:	7e 16                	jle    f010113b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0101125:	8b 45 14             	mov    0x14(%ebp),%eax
f0101128:	8d 50 08             	lea    0x8(%eax),%edx
f010112b:	89 55 14             	mov    %edx,0x14(%ebp)
f010112e:	8b 50 04             	mov    0x4(%eax),%edx
f0101131:	8b 00                	mov    (%eax),%eax
f0101133:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101136:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101139:	eb 32                	jmp    f010116d <vprintfmt+0x2df>
	else if (lflag)
f010113b:	85 d2                	test   %edx,%edx
f010113d:	74 18                	je     f0101157 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010113f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101142:	8d 50 04             	lea    0x4(%eax),%edx
f0101145:	89 55 14             	mov    %edx,0x14(%ebp)
f0101148:	8b 30                	mov    (%eax),%esi
f010114a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010114d:	89 f0                	mov    %esi,%eax
f010114f:	c1 f8 1f             	sar    $0x1f,%eax
f0101152:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101155:	eb 16                	jmp    f010116d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0101157:	8b 45 14             	mov    0x14(%ebp),%eax
f010115a:	8d 50 04             	lea    0x4(%eax),%edx
f010115d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101160:	8b 30                	mov    (%eax),%esi
f0101162:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0101165:	89 f0                	mov    %esi,%eax
f0101167:	c1 f8 1f             	sar    $0x1f,%eax
f010116a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010116d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101170:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101173:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101178:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010117c:	0f 89 80 00 00 00    	jns    f0101202 <vprintfmt+0x374>
				putch('-', putdat);
f0101182:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101186:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010118d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101190:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101193:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101196:	f7 d8                	neg    %eax
f0101198:	83 d2 00             	adc    $0x0,%edx
f010119b:	f7 da                	neg    %edx
			}
			base = 10;
f010119d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01011a2:	eb 5e                	jmp    f0101202 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01011a4:	8d 45 14             	lea    0x14(%ebp),%eax
f01011a7:	e8 63 fc ff ff       	call   f0100e0f <getuint>
			base = 10;
f01011ac:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01011b1:	eb 4f                	jmp    f0101202 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01011b3:	8d 45 14             	lea    0x14(%ebp),%eax
f01011b6:	e8 54 fc ff ff       	call   f0100e0f <getuint>
			base = 8;
f01011bb:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01011c0:	eb 40                	jmp    f0101202 <vprintfmt+0x374>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f01011c2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011c6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01011cd:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01011d0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011d4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01011db:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01011de:	8b 45 14             	mov    0x14(%ebp),%eax
f01011e1:	8d 50 04             	lea    0x4(%eax),%edx
f01011e4:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01011e7:	8b 00                	mov    (%eax),%eax
f01011e9:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01011ee:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01011f3:	eb 0d                	jmp    f0101202 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01011f5:	8d 45 14             	lea    0x14(%ebp),%eax
f01011f8:	e8 12 fc ff ff       	call   f0100e0f <getuint>
			base = 16;
f01011fd:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101202:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0101206:	89 74 24 10          	mov    %esi,0x10(%esp)
f010120a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010120d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0101211:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101215:	89 04 24             	mov    %eax,(%esp)
f0101218:	89 54 24 04          	mov    %edx,0x4(%esp)
f010121c:	89 fa                	mov    %edi,%edx
f010121e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101221:	e8 fa fa ff ff       	call   f0100d20 <printnum>
			break;
f0101226:	e9 88 fc ff ff       	jmp    f0100eb3 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010122b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010122f:	89 04 24             	mov    %eax,(%esp)
f0101232:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101235:	e9 79 fc ff ff       	jmp    f0100eb3 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010123a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010123e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101245:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101248:	89 f3                	mov    %esi,%ebx
f010124a:	eb 03                	jmp    f010124f <vprintfmt+0x3c1>
f010124c:	83 eb 01             	sub    $0x1,%ebx
f010124f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0101253:	75 f7                	jne    f010124c <vprintfmt+0x3be>
f0101255:	e9 59 fc ff ff       	jmp    f0100eb3 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010125a:	83 c4 3c             	add    $0x3c,%esp
f010125d:	5b                   	pop    %ebx
f010125e:	5e                   	pop    %esi
f010125f:	5f                   	pop    %edi
f0101260:	5d                   	pop    %ebp
f0101261:	c3                   	ret    

f0101262 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101262:	55                   	push   %ebp
f0101263:	89 e5                	mov    %esp,%ebp
f0101265:	83 ec 28             	sub    $0x28,%esp
f0101268:	8b 45 08             	mov    0x8(%ebp),%eax
f010126b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010126e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101271:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101275:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101278:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010127f:	85 c0                	test   %eax,%eax
f0101281:	74 30                	je     f01012b3 <vsnprintf+0x51>
f0101283:	85 d2                	test   %edx,%edx
f0101285:	7e 2c                	jle    f01012b3 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101287:	8b 45 14             	mov    0x14(%ebp),%eax
f010128a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010128e:	8b 45 10             	mov    0x10(%ebp),%eax
f0101291:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101295:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101298:	89 44 24 04          	mov    %eax,0x4(%esp)
f010129c:	c7 04 24 49 0e 10 f0 	movl   $0xf0100e49,(%esp)
f01012a3:	e8 e6 fb ff ff       	call   f0100e8e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01012a8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01012ab:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01012ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012b1:	eb 05                	jmp    f01012b8 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01012b3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01012b8:	c9                   	leave  
f01012b9:	c3                   	ret    

f01012ba <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01012ba:	55                   	push   %ebp
f01012bb:	89 e5                	mov    %esp,%ebp
f01012bd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01012c0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01012c3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012c7:	8b 45 10             	mov    0x10(%ebp),%eax
f01012ca:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012ce:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012d1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012d5:	8b 45 08             	mov    0x8(%ebp),%eax
f01012d8:	89 04 24             	mov    %eax,(%esp)
f01012db:	e8 82 ff ff ff       	call   f0101262 <vsnprintf>
	va_end(ap);

	return rc;
}
f01012e0:	c9                   	leave  
f01012e1:	c3                   	ret    
f01012e2:	66 90                	xchg   %ax,%ax
f01012e4:	66 90                	xchg   %ax,%ax
f01012e6:	66 90                	xchg   %ax,%ax
f01012e8:	66 90                	xchg   %ax,%ax
f01012ea:	66 90                	xchg   %ax,%ax
f01012ec:	66 90                	xchg   %ax,%ax
f01012ee:	66 90                	xchg   %ax,%ax

f01012f0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01012f0:	55                   	push   %ebp
f01012f1:	89 e5                	mov    %esp,%ebp
f01012f3:	57                   	push   %edi
f01012f4:	56                   	push   %esi
f01012f5:	53                   	push   %ebx
f01012f6:	83 ec 1c             	sub    $0x1c,%esp
f01012f9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01012fc:	85 c0                	test   %eax,%eax
f01012fe:	74 10                	je     f0101310 <readline+0x20>
		cprintf("%s", prompt);
f0101300:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101304:	c7 04 24 8a 1f 10 f0 	movl   $0xf0101f8a,(%esp)
f010130b:	e8 ce f6 ff ff       	call   f01009de <cprintf>

	i = 0;
	echoing = iscons(0);
f0101310:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101317:	e8 76 f3 ff ff       	call   f0100692 <iscons>
f010131c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010131e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101323:	e8 59 f3 ff ff       	call   f0100681 <getchar>
f0101328:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010132a:	85 c0                	test   %eax,%eax
f010132c:	79 17                	jns    f0101345 <readline+0x55>
			cprintf("read error: %e\n", c);
f010132e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101332:	c7 04 24 80 21 10 f0 	movl   $0xf0102180,(%esp)
f0101339:	e8 a0 f6 ff ff       	call   f01009de <cprintf>
			return NULL;
f010133e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101343:	eb 6d                	jmp    f01013b2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101345:	83 f8 7f             	cmp    $0x7f,%eax
f0101348:	74 05                	je     f010134f <readline+0x5f>
f010134a:	83 f8 08             	cmp    $0x8,%eax
f010134d:	75 19                	jne    f0101368 <readline+0x78>
f010134f:	85 f6                	test   %esi,%esi
f0101351:	7e 15                	jle    f0101368 <readline+0x78>
			if (echoing)
f0101353:	85 ff                	test   %edi,%edi
f0101355:	74 0c                	je     f0101363 <readline+0x73>
				cputchar('\b');
f0101357:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010135e:	e8 0e f3 ff ff       	call   f0100671 <cputchar>
			i--;
f0101363:	83 ee 01             	sub    $0x1,%esi
f0101366:	eb bb                	jmp    f0101323 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101368:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010136e:	7f 1c                	jg     f010138c <readline+0x9c>
f0101370:	83 fb 1f             	cmp    $0x1f,%ebx
f0101373:	7e 17                	jle    f010138c <readline+0x9c>
			if (echoing)
f0101375:	85 ff                	test   %edi,%edi
f0101377:	74 08                	je     f0101381 <readline+0x91>
				cputchar(c);
f0101379:	89 1c 24             	mov    %ebx,(%esp)
f010137c:	e8 f0 f2 ff ff       	call   f0100671 <cputchar>
			buf[i++] = c;
f0101381:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101387:	8d 76 01             	lea    0x1(%esi),%esi
f010138a:	eb 97                	jmp    f0101323 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010138c:	83 fb 0d             	cmp    $0xd,%ebx
f010138f:	74 05                	je     f0101396 <readline+0xa6>
f0101391:	83 fb 0a             	cmp    $0xa,%ebx
f0101394:	75 8d                	jne    f0101323 <readline+0x33>
			if (echoing)
f0101396:	85 ff                	test   %edi,%edi
f0101398:	74 0c                	je     f01013a6 <readline+0xb6>
				cputchar('\n');
f010139a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01013a1:	e8 cb f2 ff ff       	call   f0100671 <cputchar>
			buf[i] = 0;
f01013a6:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f01013ad:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f01013b2:	83 c4 1c             	add    $0x1c,%esp
f01013b5:	5b                   	pop    %ebx
f01013b6:	5e                   	pop    %esi
f01013b7:	5f                   	pop    %edi
f01013b8:	5d                   	pop    %ebp
f01013b9:	c3                   	ret    
f01013ba:	66 90                	xchg   %ax,%ax
f01013bc:	66 90                	xchg   %ax,%ax
f01013be:	66 90                	xchg   %ax,%ax

f01013c0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01013c0:	55                   	push   %ebp
f01013c1:	89 e5                	mov    %esp,%ebp
f01013c3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01013c6:	b8 00 00 00 00       	mov    $0x0,%eax
f01013cb:	eb 03                	jmp    f01013d0 <strlen+0x10>
		n++;
f01013cd:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01013d0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01013d4:	75 f7                	jne    f01013cd <strlen+0xd>
		n++;
	return n;
}
f01013d6:	5d                   	pop    %ebp
f01013d7:	c3                   	ret    

f01013d8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01013d8:	55                   	push   %ebp
f01013d9:	89 e5                	mov    %esp,%ebp
f01013db:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013de:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01013e6:	eb 03                	jmp    f01013eb <strnlen+0x13>
		n++;
f01013e8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013eb:	39 d0                	cmp    %edx,%eax
f01013ed:	74 06                	je     f01013f5 <strnlen+0x1d>
f01013ef:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01013f3:	75 f3                	jne    f01013e8 <strnlen+0x10>
		n++;
	return n;
}
f01013f5:	5d                   	pop    %ebp
f01013f6:	c3                   	ret    

f01013f7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01013f7:	55                   	push   %ebp
f01013f8:	89 e5                	mov    %esp,%ebp
f01013fa:	53                   	push   %ebx
f01013fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01013fe:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101401:	89 c2                	mov    %eax,%edx
f0101403:	83 c2 01             	add    $0x1,%edx
f0101406:	83 c1 01             	add    $0x1,%ecx
f0101409:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010140d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101410:	84 db                	test   %bl,%bl
f0101412:	75 ef                	jne    f0101403 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101414:	5b                   	pop    %ebx
f0101415:	5d                   	pop    %ebp
f0101416:	c3                   	ret    

f0101417 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101417:	55                   	push   %ebp
f0101418:	89 e5                	mov    %esp,%ebp
f010141a:	53                   	push   %ebx
f010141b:	83 ec 08             	sub    $0x8,%esp
f010141e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101421:	89 1c 24             	mov    %ebx,(%esp)
f0101424:	e8 97 ff ff ff       	call   f01013c0 <strlen>
	strcpy(dst + len, src);
f0101429:	8b 55 0c             	mov    0xc(%ebp),%edx
f010142c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101430:	01 d8                	add    %ebx,%eax
f0101432:	89 04 24             	mov    %eax,(%esp)
f0101435:	e8 bd ff ff ff       	call   f01013f7 <strcpy>
	return dst;
}
f010143a:	89 d8                	mov    %ebx,%eax
f010143c:	83 c4 08             	add    $0x8,%esp
f010143f:	5b                   	pop    %ebx
f0101440:	5d                   	pop    %ebp
f0101441:	c3                   	ret    

f0101442 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101442:	55                   	push   %ebp
f0101443:	89 e5                	mov    %esp,%ebp
f0101445:	56                   	push   %esi
f0101446:	53                   	push   %ebx
f0101447:	8b 75 08             	mov    0x8(%ebp),%esi
f010144a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010144d:	89 f3                	mov    %esi,%ebx
f010144f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101452:	89 f2                	mov    %esi,%edx
f0101454:	eb 0f                	jmp    f0101465 <strncpy+0x23>
		*dst++ = *src;
f0101456:	83 c2 01             	add    $0x1,%edx
f0101459:	0f b6 01             	movzbl (%ecx),%eax
f010145c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010145f:	80 39 01             	cmpb   $0x1,(%ecx)
f0101462:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101465:	39 da                	cmp    %ebx,%edx
f0101467:	75 ed                	jne    f0101456 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101469:	89 f0                	mov    %esi,%eax
f010146b:	5b                   	pop    %ebx
f010146c:	5e                   	pop    %esi
f010146d:	5d                   	pop    %ebp
f010146e:	c3                   	ret    

f010146f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010146f:	55                   	push   %ebp
f0101470:	89 e5                	mov    %esp,%ebp
f0101472:	56                   	push   %esi
f0101473:	53                   	push   %ebx
f0101474:	8b 75 08             	mov    0x8(%ebp),%esi
f0101477:	8b 55 0c             	mov    0xc(%ebp),%edx
f010147a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010147d:	89 f0                	mov    %esi,%eax
f010147f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101483:	85 c9                	test   %ecx,%ecx
f0101485:	75 0b                	jne    f0101492 <strlcpy+0x23>
f0101487:	eb 1d                	jmp    f01014a6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101489:	83 c0 01             	add    $0x1,%eax
f010148c:	83 c2 01             	add    $0x1,%edx
f010148f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101492:	39 d8                	cmp    %ebx,%eax
f0101494:	74 0b                	je     f01014a1 <strlcpy+0x32>
f0101496:	0f b6 0a             	movzbl (%edx),%ecx
f0101499:	84 c9                	test   %cl,%cl
f010149b:	75 ec                	jne    f0101489 <strlcpy+0x1a>
f010149d:	89 c2                	mov    %eax,%edx
f010149f:	eb 02                	jmp    f01014a3 <strlcpy+0x34>
f01014a1:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f01014a3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f01014a6:	29 f0                	sub    %esi,%eax
}
f01014a8:	5b                   	pop    %ebx
f01014a9:	5e                   	pop    %esi
f01014aa:	5d                   	pop    %ebp
f01014ab:	c3                   	ret    

f01014ac <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01014ac:	55                   	push   %ebp
f01014ad:	89 e5                	mov    %esp,%ebp
f01014af:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014b2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01014b5:	eb 06                	jmp    f01014bd <strcmp+0x11>
		p++, q++;
f01014b7:	83 c1 01             	add    $0x1,%ecx
f01014ba:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01014bd:	0f b6 01             	movzbl (%ecx),%eax
f01014c0:	84 c0                	test   %al,%al
f01014c2:	74 04                	je     f01014c8 <strcmp+0x1c>
f01014c4:	3a 02                	cmp    (%edx),%al
f01014c6:	74 ef                	je     f01014b7 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01014c8:	0f b6 c0             	movzbl %al,%eax
f01014cb:	0f b6 12             	movzbl (%edx),%edx
f01014ce:	29 d0                	sub    %edx,%eax
}
f01014d0:	5d                   	pop    %ebp
f01014d1:	c3                   	ret    

f01014d2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01014d2:	55                   	push   %ebp
f01014d3:	89 e5                	mov    %esp,%ebp
f01014d5:	53                   	push   %ebx
f01014d6:	8b 45 08             	mov    0x8(%ebp),%eax
f01014d9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014dc:	89 c3                	mov    %eax,%ebx
f01014de:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01014e1:	eb 06                	jmp    f01014e9 <strncmp+0x17>
		n--, p++, q++;
f01014e3:	83 c0 01             	add    $0x1,%eax
f01014e6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01014e9:	39 d8                	cmp    %ebx,%eax
f01014eb:	74 15                	je     f0101502 <strncmp+0x30>
f01014ed:	0f b6 08             	movzbl (%eax),%ecx
f01014f0:	84 c9                	test   %cl,%cl
f01014f2:	74 04                	je     f01014f8 <strncmp+0x26>
f01014f4:	3a 0a                	cmp    (%edx),%cl
f01014f6:	74 eb                	je     f01014e3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01014f8:	0f b6 00             	movzbl (%eax),%eax
f01014fb:	0f b6 12             	movzbl (%edx),%edx
f01014fe:	29 d0                	sub    %edx,%eax
f0101500:	eb 05                	jmp    f0101507 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101502:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101507:	5b                   	pop    %ebx
f0101508:	5d                   	pop    %ebp
f0101509:	c3                   	ret    

f010150a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010150a:	55                   	push   %ebp
f010150b:	89 e5                	mov    %esp,%ebp
f010150d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101510:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101514:	eb 07                	jmp    f010151d <strchr+0x13>
		if (*s == c)
f0101516:	38 ca                	cmp    %cl,%dl
f0101518:	74 0f                	je     f0101529 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010151a:	83 c0 01             	add    $0x1,%eax
f010151d:	0f b6 10             	movzbl (%eax),%edx
f0101520:	84 d2                	test   %dl,%dl
f0101522:	75 f2                	jne    f0101516 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101524:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101529:	5d                   	pop    %ebp
f010152a:	c3                   	ret    

f010152b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010152b:	55                   	push   %ebp
f010152c:	89 e5                	mov    %esp,%ebp
f010152e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101531:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101535:	eb 07                	jmp    f010153e <strfind+0x13>
		if (*s == c)
f0101537:	38 ca                	cmp    %cl,%dl
f0101539:	74 0a                	je     f0101545 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010153b:	83 c0 01             	add    $0x1,%eax
f010153e:	0f b6 10             	movzbl (%eax),%edx
f0101541:	84 d2                	test   %dl,%dl
f0101543:	75 f2                	jne    f0101537 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0101545:	5d                   	pop    %ebp
f0101546:	c3                   	ret    

f0101547 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101547:	55                   	push   %ebp
f0101548:	89 e5                	mov    %esp,%ebp
f010154a:	57                   	push   %edi
f010154b:	56                   	push   %esi
f010154c:	53                   	push   %ebx
f010154d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101550:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101553:	85 c9                	test   %ecx,%ecx
f0101555:	74 36                	je     f010158d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101557:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010155d:	75 28                	jne    f0101587 <memset+0x40>
f010155f:	f6 c1 03             	test   $0x3,%cl
f0101562:	75 23                	jne    f0101587 <memset+0x40>
		c &= 0xFF;
f0101564:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101568:	89 d3                	mov    %edx,%ebx
f010156a:	c1 e3 08             	shl    $0x8,%ebx
f010156d:	89 d6                	mov    %edx,%esi
f010156f:	c1 e6 18             	shl    $0x18,%esi
f0101572:	89 d0                	mov    %edx,%eax
f0101574:	c1 e0 10             	shl    $0x10,%eax
f0101577:	09 f0                	or     %esi,%eax
f0101579:	09 c2                	or     %eax,%edx
f010157b:	89 d0                	mov    %edx,%eax
f010157d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010157f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101582:	fc                   	cld    
f0101583:	f3 ab                	rep stos %eax,%es:(%edi)
f0101585:	eb 06                	jmp    f010158d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101587:	8b 45 0c             	mov    0xc(%ebp),%eax
f010158a:	fc                   	cld    
f010158b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010158d:	89 f8                	mov    %edi,%eax
f010158f:	5b                   	pop    %ebx
f0101590:	5e                   	pop    %esi
f0101591:	5f                   	pop    %edi
f0101592:	5d                   	pop    %ebp
f0101593:	c3                   	ret    

f0101594 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101594:	55                   	push   %ebp
f0101595:	89 e5                	mov    %esp,%ebp
f0101597:	57                   	push   %edi
f0101598:	56                   	push   %esi
f0101599:	8b 45 08             	mov    0x8(%ebp),%eax
f010159c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010159f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01015a2:	39 c6                	cmp    %eax,%esi
f01015a4:	73 35                	jae    f01015db <memmove+0x47>
f01015a6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01015a9:	39 d0                	cmp    %edx,%eax
f01015ab:	73 2e                	jae    f01015db <memmove+0x47>
		s += n;
		d += n;
f01015ad:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01015b0:	89 d6                	mov    %edx,%esi
f01015b2:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015b4:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01015ba:	75 13                	jne    f01015cf <memmove+0x3b>
f01015bc:	f6 c1 03             	test   $0x3,%cl
f01015bf:	75 0e                	jne    f01015cf <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01015c1:	83 ef 04             	sub    $0x4,%edi
f01015c4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01015c7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01015ca:	fd                   	std    
f01015cb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015cd:	eb 09                	jmp    f01015d8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01015cf:	83 ef 01             	sub    $0x1,%edi
f01015d2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01015d5:	fd                   	std    
f01015d6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01015d8:	fc                   	cld    
f01015d9:	eb 1d                	jmp    f01015f8 <memmove+0x64>
f01015db:	89 f2                	mov    %esi,%edx
f01015dd:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015df:	f6 c2 03             	test   $0x3,%dl
f01015e2:	75 0f                	jne    f01015f3 <memmove+0x5f>
f01015e4:	f6 c1 03             	test   $0x3,%cl
f01015e7:	75 0a                	jne    f01015f3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01015e9:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01015ec:	89 c7                	mov    %eax,%edi
f01015ee:	fc                   	cld    
f01015ef:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015f1:	eb 05                	jmp    f01015f8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01015f3:	89 c7                	mov    %eax,%edi
f01015f5:	fc                   	cld    
f01015f6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01015f8:	5e                   	pop    %esi
f01015f9:	5f                   	pop    %edi
f01015fa:	5d                   	pop    %ebp
f01015fb:	c3                   	ret    

f01015fc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01015fc:	55                   	push   %ebp
f01015fd:	89 e5                	mov    %esp,%ebp
f01015ff:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101602:	8b 45 10             	mov    0x10(%ebp),%eax
f0101605:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101609:	8b 45 0c             	mov    0xc(%ebp),%eax
f010160c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101610:	8b 45 08             	mov    0x8(%ebp),%eax
f0101613:	89 04 24             	mov    %eax,(%esp)
f0101616:	e8 79 ff ff ff       	call   f0101594 <memmove>
}
f010161b:	c9                   	leave  
f010161c:	c3                   	ret    

f010161d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010161d:	55                   	push   %ebp
f010161e:	89 e5                	mov    %esp,%ebp
f0101620:	56                   	push   %esi
f0101621:	53                   	push   %ebx
f0101622:	8b 55 08             	mov    0x8(%ebp),%edx
f0101625:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101628:	89 d6                	mov    %edx,%esi
f010162a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010162d:	eb 1a                	jmp    f0101649 <memcmp+0x2c>
		if (*s1 != *s2)
f010162f:	0f b6 02             	movzbl (%edx),%eax
f0101632:	0f b6 19             	movzbl (%ecx),%ebx
f0101635:	38 d8                	cmp    %bl,%al
f0101637:	74 0a                	je     f0101643 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101639:	0f b6 c0             	movzbl %al,%eax
f010163c:	0f b6 db             	movzbl %bl,%ebx
f010163f:	29 d8                	sub    %ebx,%eax
f0101641:	eb 0f                	jmp    f0101652 <memcmp+0x35>
		s1++, s2++;
f0101643:	83 c2 01             	add    $0x1,%edx
f0101646:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101649:	39 f2                	cmp    %esi,%edx
f010164b:	75 e2                	jne    f010162f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010164d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101652:	5b                   	pop    %ebx
f0101653:	5e                   	pop    %esi
f0101654:	5d                   	pop    %ebp
f0101655:	c3                   	ret    

f0101656 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101656:	55                   	push   %ebp
f0101657:	89 e5                	mov    %esp,%ebp
f0101659:	8b 45 08             	mov    0x8(%ebp),%eax
f010165c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010165f:	89 c2                	mov    %eax,%edx
f0101661:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101664:	eb 07                	jmp    f010166d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101666:	38 08                	cmp    %cl,(%eax)
f0101668:	74 07                	je     f0101671 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010166a:	83 c0 01             	add    $0x1,%eax
f010166d:	39 d0                	cmp    %edx,%eax
f010166f:	72 f5                	jb     f0101666 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101671:	5d                   	pop    %ebp
f0101672:	c3                   	ret    

f0101673 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101673:	55                   	push   %ebp
f0101674:	89 e5                	mov    %esp,%ebp
f0101676:	57                   	push   %edi
f0101677:	56                   	push   %esi
f0101678:	53                   	push   %ebx
f0101679:	8b 55 08             	mov    0x8(%ebp),%edx
f010167c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010167f:	eb 03                	jmp    f0101684 <strtol+0x11>
		s++;
f0101681:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101684:	0f b6 0a             	movzbl (%edx),%ecx
f0101687:	80 f9 09             	cmp    $0x9,%cl
f010168a:	74 f5                	je     f0101681 <strtol+0xe>
f010168c:	80 f9 20             	cmp    $0x20,%cl
f010168f:	74 f0                	je     f0101681 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101691:	80 f9 2b             	cmp    $0x2b,%cl
f0101694:	75 0a                	jne    f01016a0 <strtol+0x2d>
		s++;
f0101696:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101699:	bf 00 00 00 00       	mov    $0x0,%edi
f010169e:	eb 11                	jmp    f01016b1 <strtol+0x3e>
f01016a0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01016a5:	80 f9 2d             	cmp    $0x2d,%cl
f01016a8:	75 07                	jne    f01016b1 <strtol+0x3e>
		s++, neg = 1;
f01016aa:	8d 52 01             	lea    0x1(%edx),%edx
f01016ad:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01016b1:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f01016b6:	75 15                	jne    f01016cd <strtol+0x5a>
f01016b8:	80 3a 30             	cmpb   $0x30,(%edx)
f01016bb:	75 10                	jne    f01016cd <strtol+0x5a>
f01016bd:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01016c1:	75 0a                	jne    f01016cd <strtol+0x5a>
		s += 2, base = 16;
f01016c3:	83 c2 02             	add    $0x2,%edx
f01016c6:	b8 10 00 00 00       	mov    $0x10,%eax
f01016cb:	eb 10                	jmp    f01016dd <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f01016cd:	85 c0                	test   %eax,%eax
f01016cf:	75 0c                	jne    f01016dd <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01016d1:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01016d3:	80 3a 30             	cmpb   $0x30,(%edx)
f01016d6:	75 05                	jne    f01016dd <strtol+0x6a>
		s++, base = 8;
f01016d8:	83 c2 01             	add    $0x1,%edx
f01016db:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f01016dd:	bb 00 00 00 00       	mov    $0x0,%ebx
f01016e2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01016e5:	0f b6 0a             	movzbl (%edx),%ecx
f01016e8:	8d 71 d0             	lea    -0x30(%ecx),%esi
f01016eb:	89 f0                	mov    %esi,%eax
f01016ed:	3c 09                	cmp    $0x9,%al
f01016ef:	77 08                	ja     f01016f9 <strtol+0x86>
			dig = *s - '0';
f01016f1:	0f be c9             	movsbl %cl,%ecx
f01016f4:	83 e9 30             	sub    $0x30,%ecx
f01016f7:	eb 20                	jmp    f0101719 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f01016f9:	8d 71 9f             	lea    -0x61(%ecx),%esi
f01016fc:	89 f0                	mov    %esi,%eax
f01016fe:	3c 19                	cmp    $0x19,%al
f0101700:	77 08                	ja     f010170a <strtol+0x97>
			dig = *s - 'a' + 10;
f0101702:	0f be c9             	movsbl %cl,%ecx
f0101705:	83 e9 57             	sub    $0x57,%ecx
f0101708:	eb 0f                	jmp    f0101719 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f010170a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010170d:	89 f0                	mov    %esi,%eax
f010170f:	3c 19                	cmp    $0x19,%al
f0101711:	77 16                	ja     f0101729 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0101713:	0f be c9             	movsbl %cl,%ecx
f0101716:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101719:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f010171c:	7d 0f                	jge    f010172d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f010171e:	83 c2 01             	add    $0x1,%edx
f0101721:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0101725:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0101727:	eb bc                	jmp    f01016e5 <strtol+0x72>
f0101729:	89 d8                	mov    %ebx,%eax
f010172b:	eb 02                	jmp    f010172f <strtol+0xbc>
f010172d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f010172f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101733:	74 05                	je     f010173a <strtol+0xc7>
		*endptr = (char *) s;
f0101735:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101738:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f010173a:	f7 d8                	neg    %eax
f010173c:	85 ff                	test   %edi,%edi
f010173e:	0f 44 c3             	cmove  %ebx,%eax
}
f0101741:	5b                   	pop    %ebx
f0101742:	5e                   	pop    %esi
f0101743:	5f                   	pop    %edi
f0101744:	5d                   	pop    %ebp
f0101745:	c3                   	ret    
f0101746:	66 90                	xchg   %ax,%ax
f0101748:	66 90                	xchg   %ax,%ax
f010174a:	66 90                	xchg   %ax,%ax
f010174c:	66 90                	xchg   %ax,%ax
f010174e:	66 90                	xchg   %ax,%ax

f0101750 <__udivdi3>:
f0101750:	55                   	push   %ebp
f0101751:	57                   	push   %edi
f0101752:	56                   	push   %esi
f0101753:	83 ec 0c             	sub    $0xc,%esp
f0101756:	8b 44 24 28          	mov    0x28(%esp),%eax
f010175a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010175e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0101762:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101766:	85 c0                	test   %eax,%eax
f0101768:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010176c:	89 ea                	mov    %ebp,%edx
f010176e:	89 0c 24             	mov    %ecx,(%esp)
f0101771:	75 2d                	jne    f01017a0 <__udivdi3+0x50>
f0101773:	39 e9                	cmp    %ebp,%ecx
f0101775:	77 61                	ja     f01017d8 <__udivdi3+0x88>
f0101777:	85 c9                	test   %ecx,%ecx
f0101779:	89 ce                	mov    %ecx,%esi
f010177b:	75 0b                	jne    f0101788 <__udivdi3+0x38>
f010177d:	b8 01 00 00 00       	mov    $0x1,%eax
f0101782:	31 d2                	xor    %edx,%edx
f0101784:	f7 f1                	div    %ecx
f0101786:	89 c6                	mov    %eax,%esi
f0101788:	31 d2                	xor    %edx,%edx
f010178a:	89 e8                	mov    %ebp,%eax
f010178c:	f7 f6                	div    %esi
f010178e:	89 c5                	mov    %eax,%ebp
f0101790:	89 f8                	mov    %edi,%eax
f0101792:	f7 f6                	div    %esi
f0101794:	89 ea                	mov    %ebp,%edx
f0101796:	83 c4 0c             	add    $0xc,%esp
f0101799:	5e                   	pop    %esi
f010179a:	5f                   	pop    %edi
f010179b:	5d                   	pop    %ebp
f010179c:	c3                   	ret    
f010179d:	8d 76 00             	lea    0x0(%esi),%esi
f01017a0:	39 e8                	cmp    %ebp,%eax
f01017a2:	77 24                	ja     f01017c8 <__udivdi3+0x78>
f01017a4:	0f bd e8             	bsr    %eax,%ebp
f01017a7:	83 f5 1f             	xor    $0x1f,%ebp
f01017aa:	75 3c                	jne    f01017e8 <__udivdi3+0x98>
f01017ac:	8b 74 24 04          	mov    0x4(%esp),%esi
f01017b0:	39 34 24             	cmp    %esi,(%esp)
f01017b3:	0f 86 9f 00 00 00    	jbe    f0101858 <__udivdi3+0x108>
f01017b9:	39 d0                	cmp    %edx,%eax
f01017bb:	0f 82 97 00 00 00    	jb     f0101858 <__udivdi3+0x108>
f01017c1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01017c8:	31 d2                	xor    %edx,%edx
f01017ca:	31 c0                	xor    %eax,%eax
f01017cc:	83 c4 0c             	add    $0xc,%esp
f01017cf:	5e                   	pop    %esi
f01017d0:	5f                   	pop    %edi
f01017d1:	5d                   	pop    %ebp
f01017d2:	c3                   	ret    
f01017d3:	90                   	nop
f01017d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017d8:	89 f8                	mov    %edi,%eax
f01017da:	f7 f1                	div    %ecx
f01017dc:	31 d2                	xor    %edx,%edx
f01017de:	83 c4 0c             	add    $0xc,%esp
f01017e1:	5e                   	pop    %esi
f01017e2:	5f                   	pop    %edi
f01017e3:	5d                   	pop    %ebp
f01017e4:	c3                   	ret    
f01017e5:	8d 76 00             	lea    0x0(%esi),%esi
f01017e8:	89 e9                	mov    %ebp,%ecx
f01017ea:	8b 3c 24             	mov    (%esp),%edi
f01017ed:	d3 e0                	shl    %cl,%eax
f01017ef:	89 c6                	mov    %eax,%esi
f01017f1:	b8 20 00 00 00       	mov    $0x20,%eax
f01017f6:	29 e8                	sub    %ebp,%eax
f01017f8:	89 c1                	mov    %eax,%ecx
f01017fa:	d3 ef                	shr    %cl,%edi
f01017fc:	89 e9                	mov    %ebp,%ecx
f01017fe:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101802:	8b 3c 24             	mov    (%esp),%edi
f0101805:	09 74 24 08          	or     %esi,0x8(%esp)
f0101809:	89 d6                	mov    %edx,%esi
f010180b:	d3 e7                	shl    %cl,%edi
f010180d:	89 c1                	mov    %eax,%ecx
f010180f:	89 3c 24             	mov    %edi,(%esp)
f0101812:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101816:	d3 ee                	shr    %cl,%esi
f0101818:	89 e9                	mov    %ebp,%ecx
f010181a:	d3 e2                	shl    %cl,%edx
f010181c:	89 c1                	mov    %eax,%ecx
f010181e:	d3 ef                	shr    %cl,%edi
f0101820:	09 d7                	or     %edx,%edi
f0101822:	89 f2                	mov    %esi,%edx
f0101824:	89 f8                	mov    %edi,%eax
f0101826:	f7 74 24 08          	divl   0x8(%esp)
f010182a:	89 d6                	mov    %edx,%esi
f010182c:	89 c7                	mov    %eax,%edi
f010182e:	f7 24 24             	mull   (%esp)
f0101831:	39 d6                	cmp    %edx,%esi
f0101833:	89 14 24             	mov    %edx,(%esp)
f0101836:	72 30                	jb     f0101868 <__udivdi3+0x118>
f0101838:	8b 54 24 04          	mov    0x4(%esp),%edx
f010183c:	89 e9                	mov    %ebp,%ecx
f010183e:	d3 e2                	shl    %cl,%edx
f0101840:	39 c2                	cmp    %eax,%edx
f0101842:	73 05                	jae    f0101849 <__udivdi3+0xf9>
f0101844:	3b 34 24             	cmp    (%esp),%esi
f0101847:	74 1f                	je     f0101868 <__udivdi3+0x118>
f0101849:	89 f8                	mov    %edi,%eax
f010184b:	31 d2                	xor    %edx,%edx
f010184d:	e9 7a ff ff ff       	jmp    f01017cc <__udivdi3+0x7c>
f0101852:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101858:	31 d2                	xor    %edx,%edx
f010185a:	b8 01 00 00 00       	mov    $0x1,%eax
f010185f:	e9 68 ff ff ff       	jmp    f01017cc <__udivdi3+0x7c>
f0101864:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101868:	8d 47 ff             	lea    -0x1(%edi),%eax
f010186b:	31 d2                	xor    %edx,%edx
f010186d:	83 c4 0c             	add    $0xc,%esp
f0101870:	5e                   	pop    %esi
f0101871:	5f                   	pop    %edi
f0101872:	5d                   	pop    %ebp
f0101873:	c3                   	ret    
f0101874:	66 90                	xchg   %ax,%ax
f0101876:	66 90                	xchg   %ax,%ax
f0101878:	66 90                	xchg   %ax,%ax
f010187a:	66 90                	xchg   %ax,%ax
f010187c:	66 90                	xchg   %ax,%ax
f010187e:	66 90                	xchg   %ax,%ax

f0101880 <__umoddi3>:
f0101880:	55                   	push   %ebp
f0101881:	57                   	push   %edi
f0101882:	56                   	push   %esi
f0101883:	83 ec 14             	sub    $0x14,%esp
f0101886:	8b 44 24 28          	mov    0x28(%esp),%eax
f010188a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010188e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0101892:	89 c7                	mov    %eax,%edi
f0101894:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101898:	8b 44 24 30          	mov    0x30(%esp),%eax
f010189c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01018a0:	89 34 24             	mov    %esi,(%esp)
f01018a3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018a7:	85 c0                	test   %eax,%eax
f01018a9:	89 c2                	mov    %eax,%edx
f01018ab:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01018af:	75 17                	jne    f01018c8 <__umoddi3+0x48>
f01018b1:	39 fe                	cmp    %edi,%esi
f01018b3:	76 4b                	jbe    f0101900 <__umoddi3+0x80>
f01018b5:	89 c8                	mov    %ecx,%eax
f01018b7:	89 fa                	mov    %edi,%edx
f01018b9:	f7 f6                	div    %esi
f01018bb:	89 d0                	mov    %edx,%eax
f01018bd:	31 d2                	xor    %edx,%edx
f01018bf:	83 c4 14             	add    $0x14,%esp
f01018c2:	5e                   	pop    %esi
f01018c3:	5f                   	pop    %edi
f01018c4:	5d                   	pop    %ebp
f01018c5:	c3                   	ret    
f01018c6:	66 90                	xchg   %ax,%ax
f01018c8:	39 f8                	cmp    %edi,%eax
f01018ca:	77 54                	ja     f0101920 <__umoddi3+0xa0>
f01018cc:	0f bd e8             	bsr    %eax,%ebp
f01018cf:	83 f5 1f             	xor    $0x1f,%ebp
f01018d2:	75 5c                	jne    f0101930 <__umoddi3+0xb0>
f01018d4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f01018d8:	39 3c 24             	cmp    %edi,(%esp)
f01018db:	0f 87 e7 00 00 00    	ja     f01019c8 <__umoddi3+0x148>
f01018e1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01018e5:	29 f1                	sub    %esi,%ecx
f01018e7:	19 c7                	sbb    %eax,%edi
f01018e9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018ed:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01018f1:	8b 44 24 08          	mov    0x8(%esp),%eax
f01018f5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01018f9:	83 c4 14             	add    $0x14,%esp
f01018fc:	5e                   	pop    %esi
f01018fd:	5f                   	pop    %edi
f01018fe:	5d                   	pop    %ebp
f01018ff:	c3                   	ret    
f0101900:	85 f6                	test   %esi,%esi
f0101902:	89 f5                	mov    %esi,%ebp
f0101904:	75 0b                	jne    f0101911 <__umoddi3+0x91>
f0101906:	b8 01 00 00 00       	mov    $0x1,%eax
f010190b:	31 d2                	xor    %edx,%edx
f010190d:	f7 f6                	div    %esi
f010190f:	89 c5                	mov    %eax,%ebp
f0101911:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101915:	31 d2                	xor    %edx,%edx
f0101917:	f7 f5                	div    %ebp
f0101919:	89 c8                	mov    %ecx,%eax
f010191b:	f7 f5                	div    %ebp
f010191d:	eb 9c                	jmp    f01018bb <__umoddi3+0x3b>
f010191f:	90                   	nop
f0101920:	89 c8                	mov    %ecx,%eax
f0101922:	89 fa                	mov    %edi,%edx
f0101924:	83 c4 14             	add    $0x14,%esp
f0101927:	5e                   	pop    %esi
f0101928:	5f                   	pop    %edi
f0101929:	5d                   	pop    %ebp
f010192a:	c3                   	ret    
f010192b:	90                   	nop
f010192c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101930:	8b 04 24             	mov    (%esp),%eax
f0101933:	be 20 00 00 00       	mov    $0x20,%esi
f0101938:	89 e9                	mov    %ebp,%ecx
f010193a:	29 ee                	sub    %ebp,%esi
f010193c:	d3 e2                	shl    %cl,%edx
f010193e:	89 f1                	mov    %esi,%ecx
f0101940:	d3 e8                	shr    %cl,%eax
f0101942:	89 e9                	mov    %ebp,%ecx
f0101944:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101948:	8b 04 24             	mov    (%esp),%eax
f010194b:	09 54 24 04          	or     %edx,0x4(%esp)
f010194f:	89 fa                	mov    %edi,%edx
f0101951:	d3 e0                	shl    %cl,%eax
f0101953:	89 f1                	mov    %esi,%ecx
f0101955:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101959:	8b 44 24 10          	mov    0x10(%esp),%eax
f010195d:	d3 ea                	shr    %cl,%edx
f010195f:	89 e9                	mov    %ebp,%ecx
f0101961:	d3 e7                	shl    %cl,%edi
f0101963:	89 f1                	mov    %esi,%ecx
f0101965:	d3 e8                	shr    %cl,%eax
f0101967:	89 e9                	mov    %ebp,%ecx
f0101969:	09 f8                	or     %edi,%eax
f010196b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010196f:	f7 74 24 04          	divl   0x4(%esp)
f0101973:	d3 e7                	shl    %cl,%edi
f0101975:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101979:	89 d7                	mov    %edx,%edi
f010197b:	f7 64 24 08          	mull   0x8(%esp)
f010197f:	39 d7                	cmp    %edx,%edi
f0101981:	89 c1                	mov    %eax,%ecx
f0101983:	89 14 24             	mov    %edx,(%esp)
f0101986:	72 2c                	jb     f01019b4 <__umoddi3+0x134>
f0101988:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010198c:	72 22                	jb     f01019b0 <__umoddi3+0x130>
f010198e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101992:	29 c8                	sub    %ecx,%eax
f0101994:	19 d7                	sbb    %edx,%edi
f0101996:	89 e9                	mov    %ebp,%ecx
f0101998:	89 fa                	mov    %edi,%edx
f010199a:	d3 e8                	shr    %cl,%eax
f010199c:	89 f1                	mov    %esi,%ecx
f010199e:	d3 e2                	shl    %cl,%edx
f01019a0:	89 e9                	mov    %ebp,%ecx
f01019a2:	d3 ef                	shr    %cl,%edi
f01019a4:	09 d0                	or     %edx,%eax
f01019a6:	89 fa                	mov    %edi,%edx
f01019a8:	83 c4 14             	add    $0x14,%esp
f01019ab:	5e                   	pop    %esi
f01019ac:	5f                   	pop    %edi
f01019ad:	5d                   	pop    %ebp
f01019ae:	c3                   	ret    
f01019af:	90                   	nop
f01019b0:	39 d7                	cmp    %edx,%edi
f01019b2:	75 da                	jne    f010198e <__umoddi3+0x10e>
f01019b4:	8b 14 24             	mov    (%esp),%edx
f01019b7:	89 c1                	mov    %eax,%ecx
f01019b9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f01019bd:	1b 54 24 04          	sbb    0x4(%esp),%edx
f01019c1:	eb cb                	jmp    f010198e <__umoddi3+0x10e>
f01019c3:	90                   	nop
f01019c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019c8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f01019cc:	0f 82 0f ff ff ff    	jb     f01018e1 <__umoddi3+0x61>
f01019d2:	e9 1a ff ff ff       	jmp    f01018f1 <__umoddi3+0x71>
