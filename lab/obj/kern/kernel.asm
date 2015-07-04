
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
f010004e:	c7 04 24 40 19 10 f0 	movl   $0xf0101940,(%esp)
f0100055:	e8 4e 09 00 00       	call   f01009a8 <cprintf>
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
f010008b:	c7 04 24 5c 19 10 f0 	movl   $0xf010195c,(%esp)
f0100092:	e8 11 09 00 00       	call   f01009a8 <cprintf>
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
f01000c0:	e8 e2 13 00 00       	call   f01014a7 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 b5 04 00 00       	call   f010057f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 77 19 10 f0 	movl   $0xf0101977,(%esp)
f01000d9:	e8 ca 08 00 00       	call   f01009a8 <cprintf>

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
f0100102:	c7 04 24 92 19 10 f0 	movl   $0xf0101992,(%esp)
f0100109:	e8 9a 08 00 00       	call   f01009a8 <cprintf>
	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010010e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100115:	e8 13 07 00 00       	call   f010082d <monitor>
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
f0100149:	c7 04 24 a4 19 10 f0 	movl   $0xf01019a4,(%esp)
f0100150:	e8 53 08 00 00       	call   f01009a8 <cprintf>
	vcprintf(fmt, ap);
f0100155:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100159:	89 34 24             	mov    %esi,(%esp)
f010015c:	e8 14 08 00 00       	call   f0100975 <vcprintf>
	cprintf("\n");
f0100161:	c7 04 24 e0 19 10 f0 	movl   $0xf01019e0,(%esp)
f0100168:	e8 3b 08 00 00       	call   f01009a8 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010016d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100174:	e8 b4 06 00 00       	call   f010082d <monitor>
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
f0100193:	c7 04 24 bc 19 10 f0 	movl   $0xf01019bc,(%esp)
f010019a:	e8 09 08 00 00       	call   f01009a8 <cprintf>
	vcprintf(fmt, ap);
f010019f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01001a3:	8b 45 10             	mov    0x10(%ebp),%eax
f01001a6:	89 04 24             	mov    %eax,(%esp)
f01001a9:	e8 c7 07 00 00       	call   f0100975 <vcprintf>
	cprintf("\n");
f01001ae:	c7 04 24 e0 19 10 f0 	movl   $0xf01019e0,(%esp)
f01001b5:	e8 ee 07 00 00       	call   f01009a8 <cprintf>
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
f0100265:	0f b6 82 20 1b 10 f0 	movzbl -0xfefe4e0(%edx),%eax
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
f01002a2:	0f b6 82 20 1b 10 f0 	movzbl -0xfefe4e0(%edx),%eax
f01002a9:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
	shift ^= togglecode[data];
f01002af:	0f b6 8a 20 1a 10 f0 	movzbl -0xfefe5e0(%edx),%ecx
f01002b6:	31 c8                	xor    %ecx,%eax
f01002b8:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f01002bd:	89 c1                	mov    %eax,%ecx
f01002bf:	83 e1 03             	and    $0x3,%ecx
f01002c2:	8b 0c 8d 00 1a 10 f0 	mov    -0xfefe600(,%ecx,4),%ecx
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
f0100302:	c7 04 24 d6 19 10 f0 	movl   $0xf01019d6,(%esp)
f0100309:	e8 9a 06 00 00       	call   f01009a8 <cprintf>
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
f01004a9:	e8 46 10 00 00       	call   f01014f4 <memmove>
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
f010065d:	c7 04 24 e2 19 10 f0 	movl   $0xf01019e2,(%esp)
f0100664:	e8 3f 03 00 00       	call   f01009a8 <cprintf>
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
f01006a6:	c7 44 24 08 20 1c 10 	movl   $0xf0101c20,0x8(%esp)
f01006ad:	f0 
f01006ae:	c7 44 24 04 3e 1c 10 	movl   $0xf0101c3e,0x4(%esp)
f01006b5:	f0 
f01006b6:	c7 04 24 43 1c 10 f0 	movl   $0xf0101c43,(%esp)
f01006bd:	e8 e6 02 00 00       	call   f01009a8 <cprintf>
f01006c2:	c7 44 24 08 e4 1c 10 	movl   $0xf0101ce4,0x8(%esp)
f01006c9:	f0 
f01006ca:	c7 44 24 04 4c 1c 10 	movl   $0xf0101c4c,0x4(%esp)
f01006d1:	f0 
f01006d2:	c7 04 24 43 1c 10 f0 	movl   $0xf0101c43,(%esp)
f01006d9:	e8 ca 02 00 00       	call   f01009a8 <cprintf>
f01006de:	c7 44 24 08 55 1c 10 	movl   $0xf0101c55,0x8(%esp)
f01006e5:	f0 
f01006e6:	c7 44 24 04 72 1c 10 	movl   $0xf0101c72,0x4(%esp)
f01006ed:	f0 
f01006ee:	c7 04 24 43 1c 10 f0 	movl   $0xf0101c43,(%esp)
f01006f5:	e8 ae 02 00 00       	call   f01009a8 <cprintf>
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
f0100707:	c7 04 24 7d 1c 10 f0 	movl   $0xf0101c7d,(%esp)
f010070e:	e8 95 02 00 00       	call   f01009a8 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100713:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010071a:	00 
f010071b:	c7 04 24 0c 1d 10 f0 	movl   $0xf0101d0c,(%esp)
f0100722:	e8 81 02 00 00       	call   f01009a8 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100727:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010072e:	00 
f010072f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100736:	f0 
f0100737:	c7 04 24 34 1d 10 f0 	movl   $0xf0101d34,(%esp)
f010073e:	e8 65 02 00 00       	call   f01009a8 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100743:	c7 44 24 08 37 19 10 	movl   $0x101937,0x8(%esp)
f010074a:	00 
f010074b:	c7 44 24 04 37 19 10 	movl   $0xf0101937,0x4(%esp)
f0100752:	f0 
f0100753:	c7 04 24 58 1d 10 f0 	movl   $0xf0101d58,(%esp)
f010075a:	e8 49 02 00 00       	call   f01009a8 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010075f:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100766:	00 
f0100767:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f010076e:	f0 
f010076f:	c7 04 24 7c 1d 10 f0 	movl   $0xf0101d7c,(%esp)
f0100776:	e8 2d 02 00 00       	call   f01009a8 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010077b:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100782:	00 
f0100783:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f010078a:	f0 
f010078b:	c7 04 24 a0 1d 10 f0 	movl   $0xf0101da0,(%esp)
f0100792:	e8 11 02 00 00       	call   f01009a8 <cprintf>
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
f01007b8:	c7 04 24 c4 1d 10 f0 	movl   $0xf0101dc4,(%esp)
f01007bf:	e8 e4 01 00 00       	call   f01009a8 <cprintf>
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
f01007ce:	53                   	push   %ebx
f01007cf:	83 ec 24             	sub    $0x24,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01007d2:	89 eb                	mov    %ebp,%ebx
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
f01007d4:	c7 04 24 96 1c 10 f0 	movl   $0xf0101c96,(%esp)
f01007db:	e8 c8 01 00 00       	call   f01009a8 <cprintf>
	while (ebp){
f01007e0:	eb 3c                	jmp    f010081e <mon_backtrace+0x53>
	// Your code here.
		uint32_t eip = *((uint32_t*)ebp+1);
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp,eip,
f01007e2:	8b 43 18             	mov    0x18(%ebx),%eax
f01007e5:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f01007e9:	8b 43 14             	mov    0x14(%ebx),%eax
f01007ec:	89 44 24 18          	mov    %eax,0x18(%esp)
f01007f0:	8b 43 10             	mov    0x10(%ebx),%eax
f01007f3:	89 44 24 14          	mov    %eax,0x14(%esp)
f01007f7:	8b 43 0c             	mov    0xc(%ebx),%eax
f01007fa:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007fe:	8b 43 08             	mov    0x8(%ebx),%eax
f0100801:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100805:	8b 43 04             	mov    0x4(%ebx),%eax
f0100808:	89 44 24 08          	mov    %eax,0x8(%esp)
f010080c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100810:	c7 04 24 f0 1d 10 f0 	movl   $0xf0101df0,(%esp)
f0100817:	e8 8c 01 00 00       	call   f01009a8 <cprintf>
		*((uint32_t *)ebp + 2),*((uint32_t *)ebp + 3),*((uint32_t *)ebp + 4),*((uint32_t *)ebp + 5),
		*((uint32_t *)ebp + 6));
	ebp = *(uint32_t*)ebp;
f010081c:	8b 1b                	mov    (%ebx),%ebx
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	while (ebp){
f010081e:	85 db                	test   %ebx,%ebx
f0100820:	75 c0                	jne    f01007e2 <mon_backtrace+0x17>
		*((uint32_t *)ebp + 2),*((uint32_t *)ebp + 3),*((uint32_t *)ebp + 4),*((uint32_t *)ebp + 5),
		*((uint32_t *)ebp + 6));
	ebp = *(uint32_t*)ebp;
	}
	return 0;
}
f0100822:	b8 00 00 00 00       	mov    $0x0,%eax
f0100827:	83 c4 24             	add    $0x24,%esp
f010082a:	5b                   	pop    %ebx
f010082b:	5d                   	pop    %ebp
f010082c:	c3                   	ret    

f010082d <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010082d:	55                   	push   %ebp
f010082e:	89 e5                	mov    %esp,%ebp
f0100830:	57                   	push   %edi
f0100831:	56                   	push   %esi
f0100832:	53                   	push   %ebx
f0100833:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100836:	c7 04 24 24 1e 10 f0 	movl   $0xf0101e24,(%esp)
f010083d:	e8 66 01 00 00       	call   f01009a8 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100842:	c7 04 24 48 1e 10 f0 	movl   $0xf0101e48,(%esp)
f0100849:	e8 5a 01 00 00       	call   f01009a8 <cprintf>


	while (1) {
		buf = readline("K> ");
f010084e:	c7 04 24 a8 1c 10 f0 	movl   $0xf0101ca8,(%esp)
f0100855:	e8 f6 09 00 00       	call   f0101250 <readline>
f010085a:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010085c:	85 c0                	test   %eax,%eax
f010085e:	74 ee                	je     f010084e <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100860:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100867:	be 00 00 00 00       	mov    $0x0,%esi
f010086c:	eb 0a                	jmp    f0100878 <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010086e:	c6 03 00             	movb   $0x0,(%ebx)
f0100871:	89 f7                	mov    %esi,%edi
f0100873:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100876:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100878:	0f b6 03             	movzbl (%ebx),%eax
f010087b:	84 c0                	test   %al,%al
f010087d:	74 65                	je     f01008e4 <monitor+0xb7>
f010087f:	0f be c0             	movsbl %al,%eax
f0100882:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100886:	c7 04 24 ac 1c 10 f0 	movl   $0xf0101cac,(%esp)
f010088d:	e8 d8 0b 00 00       	call   f010146a <strchr>
f0100892:	85 c0                	test   %eax,%eax
f0100894:	75 d8                	jne    f010086e <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100896:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100899:	74 49                	je     f01008e4 <monitor+0xb7>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010089b:	83 fe 0f             	cmp    $0xf,%esi
f010089e:	66 90                	xchg   %ax,%ax
f01008a0:	75 16                	jne    f01008b8 <monitor+0x8b>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008a2:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008a9:	00 
f01008aa:	c7 04 24 b1 1c 10 f0 	movl   $0xf0101cb1,(%esp)
f01008b1:	e8 f2 00 00 00       	call   f01009a8 <cprintf>
f01008b6:	eb 96                	jmp    f010084e <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f01008b8:	8d 7e 01             	lea    0x1(%esi),%edi
f01008bb:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008bf:	eb 03                	jmp    f01008c4 <monitor+0x97>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008c1:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008c4:	0f b6 03             	movzbl (%ebx),%eax
f01008c7:	84 c0                	test   %al,%al
f01008c9:	74 ab                	je     f0100876 <monitor+0x49>
f01008cb:	0f be c0             	movsbl %al,%eax
f01008ce:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008d2:	c7 04 24 ac 1c 10 f0 	movl   $0xf0101cac,(%esp)
f01008d9:	e8 8c 0b 00 00       	call   f010146a <strchr>
f01008de:	85 c0                	test   %eax,%eax
f01008e0:	74 df                	je     f01008c1 <monitor+0x94>
f01008e2:	eb 92                	jmp    f0100876 <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f01008e4:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008eb:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008ec:	85 f6                	test   %esi,%esi
f01008ee:	0f 84 5a ff ff ff    	je     f010084e <monitor+0x21>
f01008f4:	bb 00 00 00 00       	mov    $0x0,%ebx
f01008f9:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008fc:	8b 04 85 80 1e 10 f0 	mov    -0xfefe180(,%eax,4),%eax
f0100903:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100907:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010090a:	89 04 24             	mov    %eax,(%esp)
f010090d:	e8 fa 0a 00 00       	call   f010140c <strcmp>
f0100912:	85 c0                	test   %eax,%eax
f0100914:	75 24                	jne    f010093a <monitor+0x10d>
			return commands[i].func(argc, argv, tf);
f0100916:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100919:	8b 55 08             	mov    0x8(%ebp),%edx
f010091c:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100920:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100923:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100927:	89 34 24             	mov    %esi,(%esp)
f010092a:	ff 14 85 88 1e 10 f0 	call   *-0xfefe178(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100931:	85 c0                	test   %eax,%eax
f0100933:	78 25                	js     f010095a <monitor+0x12d>
f0100935:	e9 14 ff ff ff       	jmp    f010084e <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f010093a:	83 c3 01             	add    $0x1,%ebx
f010093d:	83 fb 03             	cmp    $0x3,%ebx
f0100940:	75 b7                	jne    f01008f9 <monitor+0xcc>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100942:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100945:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100949:	c7 04 24 ce 1c 10 f0 	movl   $0xf0101cce,(%esp)
f0100950:	e8 53 00 00 00       	call   f01009a8 <cprintf>
f0100955:	e9 f4 fe ff ff       	jmp    f010084e <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010095a:	83 c4 5c             	add    $0x5c,%esp
f010095d:	5b                   	pop    %ebx
f010095e:	5e                   	pop    %esi
f010095f:	5f                   	pop    %edi
f0100960:	5d                   	pop    %ebp
f0100961:	c3                   	ret    

f0100962 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100962:	55                   	push   %ebp
f0100963:	89 e5                	mov    %esp,%ebp
f0100965:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100968:	8b 45 08             	mov    0x8(%ebp),%eax
f010096b:	89 04 24             	mov    %eax,(%esp)
f010096e:	e8 fe fc ff ff       	call   f0100671 <cputchar>
	*cnt++;
}
f0100973:	c9                   	leave  
f0100974:	c3                   	ret    

f0100975 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100975:	55                   	push   %ebp
f0100976:	89 e5                	mov    %esp,%ebp
f0100978:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f010097b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100982:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100985:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100989:	8b 45 08             	mov    0x8(%ebp),%eax
f010098c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100990:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100993:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100997:	c7 04 24 62 09 10 f0 	movl   $0xf0100962,(%esp)
f010099e:	e8 4b 04 00 00       	call   f0100dee <vprintfmt>
	return cnt;
}
f01009a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009a6:	c9                   	leave  
f01009a7:	c3                   	ret    

f01009a8 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009a8:	55                   	push   %ebp
f01009a9:	89 e5                	mov    %esp,%ebp
f01009ab:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009ae:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009b1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01009b8:	89 04 24             	mov    %eax,(%esp)
f01009bb:	e8 b5 ff ff ff       	call   f0100975 <vcprintf>
	va_end(ap);

	return cnt;
}
f01009c0:	c9                   	leave  
f01009c1:	c3                   	ret    

f01009c2 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009c2:	55                   	push   %ebp
f01009c3:	89 e5                	mov    %esp,%ebp
f01009c5:	57                   	push   %edi
f01009c6:	56                   	push   %esi
f01009c7:	53                   	push   %ebx
f01009c8:	83 ec 10             	sub    $0x10,%esp
f01009cb:	89 c6                	mov    %eax,%esi
f01009cd:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01009d0:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01009d3:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009d6:	8b 1a                	mov    (%edx),%ebx
f01009d8:	8b 01                	mov    (%ecx),%eax
f01009da:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009dd:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f01009e4:	eb 77                	jmp    f0100a5d <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f01009e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01009e9:	01 d8                	add    %ebx,%eax
f01009eb:	b9 02 00 00 00       	mov    $0x2,%ecx
f01009f0:	99                   	cltd   
f01009f1:	f7 f9                	idiv   %ecx
f01009f3:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009f5:	eb 01                	jmp    f01009f8 <stab_binsearch+0x36>
			m--;
f01009f7:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009f8:	39 d9                	cmp    %ebx,%ecx
f01009fa:	7c 1d                	jl     f0100a19 <stab_binsearch+0x57>
f01009fc:	6b d1 0c             	imul   $0xc,%ecx,%edx
f01009ff:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a04:	39 fa                	cmp    %edi,%edx
f0100a06:	75 ef                	jne    f01009f7 <stab_binsearch+0x35>
f0100a08:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a0b:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a0e:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100a12:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a15:	73 18                	jae    f0100a2f <stab_binsearch+0x6d>
f0100a17:	eb 05                	jmp    f0100a1e <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a19:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100a1c:	eb 3f                	jmp    f0100a5d <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a1e:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a21:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0100a23:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a26:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a2d:	eb 2e                	jmp    f0100a5d <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a2f:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a32:	73 15                	jae    f0100a49 <stab_binsearch+0x87>
			*region_right = m - 1;
f0100a34:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a37:	48                   	dec    %eax
f0100a38:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a3b:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a3e:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a40:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a47:	eb 14                	jmp    f0100a5d <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a49:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a4c:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100a4f:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0100a51:	ff 45 0c             	incl   0xc(%ebp)
f0100a54:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a56:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a5d:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a60:	7e 84                	jle    f01009e6 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a62:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100a66:	75 0d                	jne    f0100a75 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100a68:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a6b:	8b 00                	mov    (%eax),%eax
f0100a6d:	48                   	dec    %eax
f0100a6e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100a71:	89 07                	mov    %eax,(%edi)
f0100a73:	eb 22                	jmp    f0100a97 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a75:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a78:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a7a:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a7d:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a7f:	eb 01                	jmp    f0100a82 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a81:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a82:	39 c1                	cmp    %eax,%ecx
f0100a84:	7d 0c                	jge    f0100a92 <stab_binsearch+0xd0>
f0100a86:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100a89:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a8e:	39 fa                	cmp    %edi,%edx
f0100a90:	75 ef                	jne    f0100a81 <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a92:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100a95:	89 07                	mov    %eax,(%edi)
	}
}
f0100a97:	83 c4 10             	add    $0x10,%esp
f0100a9a:	5b                   	pop    %ebx
f0100a9b:	5e                   	pop    %esi
f0100a9c:	5f                   	pop    %edi
f0100a9d:	5d                   	pop    %ebp
f0100a9e:	c3                   	ret    

f0100a9f <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a9f:	55                   	push   %ebp
f0100aa0:	89 e5                	mov    %esp,%ebp
f0100aa2:	57                   	push   %edi
f0100aa3:	56                   	push   %esi
f0100aa4:	53                   	push   %ebx
f0100aa5:	83 ec 2c             	sub    $0x2c,%esp
f0100aa8:	8b 75 08             	mov    0x8(%ebp),%esi
f0100aab:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100aae:	c7 03 a4 1e 10 f0    	movl   $0xf0101ea4,(%ebx)
	info->eip_line = 0;
f0100ab4:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100abb:	c7 43 08 a4 1e 10 f0 	movl   $0xf0101ea4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100ac2:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100ac9:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100acc:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100ad3:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100ad9:	76 12                	jbe    f0100aed <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100adb:	b8 8f 72 10 f0       	mov    $0xf010728f,%eax
f0100ae0:	3d 9d 59 10 f0       	cmp    $0xf010599d,%eax
f0100ae5:	0f 86 6b 01 00 00    	jbe    f0100c56 <debuginfo_eip+0x1b7>
f0100aeb:	eb 1c                	jmp    f0100b09 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100aed:	c7 44 24 08 ae 1e 10 	movl   $0xf0101eae,0x8(%esp)
f0100af4:	f0 
f0100af5:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100afc:	00 
f0100afd:	c7 04 24 bb 1e 10 f0 	movl   $0xf0101ebb,(%esp)
f0100b04:	e8 13 f6 ff ff       	call   f010011c <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b09:	80 3d 8e 72 10 f0 00 	cmpb   $0x0,0xf010728e
f0100b10:	0f 85 47 01 00 00    	jne    f0100c5d <debuginfo_eip+0x1be>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b16:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b1d:	b8 9c 59 10 f0       	mov    $0xf010599c,%eax
f0100b22:	2d f0 20 10 f0       	sub    $0xf01020f0,%eax
f0100b27:	c1 f8 02             	sar    $0x2,%eax
f0100b2a:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b30:	83 e8 01             	sub    $0x1,%eax
f0100b33:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b36:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b3a:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b41:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b44:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b47:	b8 f0 20 10 f0       	mov    $0xf01020f0,%eax
f0100b4c:	e8 71 fe ff ff       	call   f01009c2 <stab_binsearch>
	if (lfile == 0)
f0100b51:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b54:	85 c0                	test   %eax,%eax
f0100b56:	0f 84 08 01 00 00    	je     f0100c64 <debuginfo_eip+0x1c5>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b5c:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b5f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b62:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b65:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b69:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100b70:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b73:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b76:	b8 f0 20 10 f0       	mov    $0xf01020f0,%eax
f0100b7b:	e8 42 fe ff ff       	call   f01009c2 <stab_binsearch>

	if (lfun <= rfun) {
f0100b80:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100b83:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100b86:	7f 2e                	jg     f0100bb6 <debuginfo_eip+0x117>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b88:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b8b:	8d 90 f0 20 10 f0    	lea    -0xfefdf10(%eax),%edx
f0100b91:	8b 80 f0 20 10 f0    	mov    -0xfefdf10(%eax),%eax
f0100b97:	b9 8f 72 10 f0       	mov    $0xf010728f,%ecx
f0100b9c:	81 e9 9d 59 10 f0    	sub    $0xf010599d,%ecx
f0100ba2:	39 c8                	cmp    %ecx,%eax
f0100ba4:	73 08                	jae    f0100bae <debuginfo_eip+0x10f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100ba6:	05 9d 59 10 f0       	add    $0xf010599d,%eax
f0100bab:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100bae:	8b 42 08             	mov    0x8(%edx),%eax
f0100bb1:	89 43 10             	mov    %eax,0x10(%ebx)
f0100bb4:	eb 06                	jmp    f0100bbc <debuginfo_eip+0x11d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bb6:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100bb9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bbc:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100bc3:	00 
f0100bc4:	8b 43 08             	mov    0x8(%ebx),%eax
f0100bc7:	89 04 24             	mov    %eax,(%esp)
f0100bca:	e8 bc 08 00 00       	call   f010148b <strfind>
f0100bcf:	2b 43 08             	sub    0x8(%ebx),%eax
f0100bd2:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100bd5:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100bd8:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100bdb:	05 f0 20 10 f0       	add    $0xf01020f0,%eax
f0100be0:	eb 06                	jmp    f0100be8 <debuginfo_eip+0x149>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100be2:	83 ef 01             	sub    $0x1,%edi
f0100be5:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100be8:	39 cf                	cmp    %ecx,%edi
f0100bea:	7c 33                	jl     f0100c1f <debuginfo_eip+0x180>
	       && stabs[lline].n_type != N_SOL
f0100bec:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100bf0:	80 fa 84             	cmp    $0x84,%dl
f0100bf3:	74 0b                	je     f0100c00 <debuginfo_eip+0x161>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100bf5:	80 fa 64             	cmp    $0x64,%dl
f0100bf8:	75 e8                	jne    f0100be2 <debuginfo_eip+0x143>
f0100bfa:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100bfe:	74 e2                	je     f0100be2 <debuginfo_eip+0x143>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c00:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100c03:	8b 87 f0 20 10 f0    	mov    -0xfefdf10(%edi),%eax
f0100c09:	ba 8f 72 10 f0       	mov    $0xf010728f,%edx
f0100c0e:	81 ea 9d 59 10 f0    	sub    $0xf010599d,%edx
f0100c14:	39 d0                	cmp    %edx,%eax
f0100c16:	73 07                	jae    f0100c1f <debuginfo_eip+0x180>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c18:	05 9d 59 10 f0       	add    $0xf010599d,%eax
f0100c1d:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c1f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100c22:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c25:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c2a:	39 f1                	cmp    %esi,%ecx
f0100c2c:	7d 42                	jge    f0100c70 <debuginfo_eip+0x1d1>
		for (lline = lfun + 1;
f0100c2e:	8d 51 01             	lea    0x1(%ecx),%edx
f0100c31:	6b c1 0c             	imul   $0xc,%ecx,%eax
f0100c34:	05 f0 20 10 f0       	add    $0xf01020f0,%eax
f0100c39:	eb 07                	jmp    f0100c42 <debuginfo_eip+0x1a3>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c3b:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100c3f:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c42:	39 f2                	cmp    %esi,%edx
f0100c44:	74 25                	je     f0100c6b <debuginfo_eip+0x1cc>
f0100c46:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c49:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100c4d:	74 ec                	je     f0100c3b <debuginfo_eip+0x19c>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c4f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c54:	eb 1a                	jmp    f0100c70 <debuginfo_eip+0x1d1>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c56:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c5b:	eb 13                	jmp    f0100c70 <debuginfo_eip+0x1d1>
f0100c5d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c62:	eb 0c                	jmp    f0100c70 <debuginfo_eip+0x1d1>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100c64:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c69:	eb 05                	jmp    f0100c70 <debuginfo_eip+0x1d1>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c6b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c70:	83 c4 2c             	add    $0x2c,%esp
f0100c73:	5b                   	pop    %ebx
f0100c74:	5e                   	pop    %esi
f0100c75:	5f                   	pop    %edi
f0100c76:	5d                   	pop    %ebp
f0100c77:	c3                   	ret    
f0100c78:	66 90                	xchg   %ax,%ax
f0100c7a:	66 90                	xchg   %ax,%ax
f0100c7c:	66 90                	xchg   %ax,%ax
f0100c7e:	66 90                	xchg   %ax,%ax

f0100c80 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c80:	55                   	push   %ebp
f0100c81:	89 e5                	mov    %esp,%ebp
f0100c83:	57                   	push   %edi
f0100c84:	56                   	push   %esi
f0100c85:	53                   	push   %ebx
f0100c86:	83 ec 3c             	sub    $0x3c,%esp
f0100c89:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100c8c:	89 d7                	mov    %edx,%edi
f0100c8e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c91:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100c94:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c97:	89 c3                	mov    %eax,%ebx
f0100c99:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100c9c:	8b 45 10             	mov    0x10(%ebp),%eax
f0100c9f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100ca2:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100ca7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100caa:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100cad:	39 d9                	cmp    %ebx,%ecx
f0100caf:	72 05                	jb     f0100cb6 <printnum+0x36>
f0100cb1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100cb4:	77 69                	ja     f0100d1f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100cb6:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100cb9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100cbd:	83 ee 01             	sub    $0x1,%esi
f0100cc0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100cc4:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100cc8:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100ccc:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100cd0:	89 c3                	mov    %eax,%ebx
f0100cd2:	89 d6                	mov    %edx,%esi
f0100cd4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100cd7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100cda:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100cde:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100ce2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ce5:	89 04 24             	mov    %eax,(%esp)
f0100ce8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100ceb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100cef:	e8 bc 09 00 00       	call   f01016b0 <__udivdi3>
f0100cf4:	89 d9                	mov    %ebx,%ecx
f0100cf6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100cfa:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100cfe:	89 04 24             	mov    %eax,(%esp)
f0100d01:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100d05:	89 fa                	mov    %edi,%edx
f0100d07:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d0a:	e8 71 ff ff ff       	call   f0100c80 <printnum>
f0100d0f:	eb 1b                	jmp    f0100d2c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d11:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d15:	8b 45 18             	mov    0x18(%ebp),%eax
f0100d18:	89 04 24             	mov    %eax,(%esp)
f0100d1b:	ff d3                	call   *%ebx
f0100d1d:	eb 03                	jmp    f0100d22 <printnum+0xa2>
f0100d1f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d22:	83 ee 01             	sub    $0x1,%esi
f0100d25:	85 f6                	test   %esi,%esi
f0100d27:	7f e8                	jg     f0100d11 <printnum+0x91>
f0100d29:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d2c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d30:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100d34:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100d37:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100d3a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d3e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100d42:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d45:	89 04 24             	mov    %eax,(%esp)
f0100d48:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d4b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d4f:	e8 8c 0a 00 00       	call   f01017e0 <__umoddi3>
f0100d54:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d58:	0f be 80 c9 1e 10 f0 	movsbl -0xfefe137(%eax),%eax
f0100d5f:	89 04 24             	mov    %eax,(%esp)
f0100d62:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d65:	ff d0                	call   *%eax
}
f0100d67:	83 c4 3c             	add    $0x3c,%esp
f0100d6a:	5b                   	pop    %ebx
f0100d6b:	5e                   	pop    %esi
f0100d6c:	5f                   	pop    %edi
f0100d6d:	5d                   	pop    %ebp
f0100d6e:	c3                   	ret    

f0100d6f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d6f:	55                   	push   %ebp
f0100d70:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d72:	83 fa 01             	cmp    $0x1,%edx
f0100d75:	7e 0e                	jle    f0100d85 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100d77:	8b 10                	mov    (%eax),%edx
f0100d79:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100d7c:	89 08                	mov    %ecx,(%eax)
f0100d7e:	8b 02                	mov    (%edx),%eax
f0100d80:	8b 52 04             	mov    0x4(%edx),%edx
f0100d83:	eb 22                	jmp    f0100da7 <getuint+0x38>
	else if (lflag)
f0100d85:	85 d2                	test   %edx,%edx
f0100d87:	74 10                	je     f0100d99 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d89:	8b 10                	mov    (%eax),%edx
f0100d8b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d8e:	89 08                	mov    %ecx,(%eax)
f0100d90:	8b 02                	mov    (%edx),%eax
f0100d92:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d97:	eb 0e                	jmp    f0100da7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d99:	8b 10                	mov    (%eax),%edx
f0100d9b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d9e:	89 08                	mov    %ecx,(%eax)
f0100da0:	8b 02                	mov    (%edx),%eax
f0100da2:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100da7:	5d                   	pop    %ebp
f0100da8:	c3                   	ret    

f0100da9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100da9:	55                   	push   %ebp
f0100daa:	89 e5                	mov    %esp,%ebp
f0100dac:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100daf:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100db3:	8b 10                	mov    (%eax),%edx
f0100db5:	3b 50 04             	cmp    0x4(%eax),%edx
f0100db8:	73 0a                	jae    f0100dc4 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100dba:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100dbd:	89 08                	mov    %ecx,(%eax)
f0100dbf:	8b 45 08             	mov    0x8(%ebp),%eax
f0100dc2:	88 02                	mov    %al,(%edx)
}
f0100dc4:	5d                   	pop    %ebp
f0100dc5:	c3                   	ret    

f0100dc6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100dc6:	55                   	push   %ebp
f0100dc7:	89 e5                	mov    %esp,%ebp
f0100dc9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100dcc:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100dcf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100dd3:	8b 45 10             	mov    0x10(%ebp),%eax
f0100dd6:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100dda:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ddd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100de1:	8b 45 08             	mov    0x8(%ebp),%eax
f0100de4:	89 04 24             	mov    %eax,(%esp)
f0100de7:	e8 02 00 00 00       	call   f0100dee <vprintfmt>
	va_end(ap);
}
f0100dec:	c9                   	leave  
f0100ded:	c3                   	ret    

f0100dee <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100dee:	55                   	push   %ebp
f0100def:	89 e5                	mov    %esp,%ebp
f0100df1:	57                   	push   %edi
f0100df2:	56                   	push   %esi
f0100df3:	53                   	push   %ebx
f0100df4:	83 ec 3c             	sub    $0x3c,%esp
f0100df7:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100dfa:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100dfd:	eb 14                	jmp    f0100e13 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100dff:	85 c0                	test   %eax,%eax
f0100e01:	0f 84 b3 03 00 00    	je     f01011ba <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0100e07:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e0b:	89 04 24             	mov    %eax,(%esp)
f0100e0e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e11:	89 f3                	mov    %esi,%ebx
f0100e13:	8d 73 01             	lea    0x1(%ebx),%esi
f0100e16:	0f b6 03             	movzbl (%ebx),%eax
f0100e19:	83 f8 25             	cmp    $0x25,%eax
f0100e1c:	75 e1                	jne    f0100dff <vprintfmt+0x11>
f0100e1e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100e22:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0100e29:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100e30:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100e37:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e3c:	eb 1d                	jmp    f0100e5b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e3e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100e40:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100e44:	eb 15                	jmp    f0100e5b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e46:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e48:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100e4c:	eb 0d                	jmp    f0100e5b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100e4e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e51:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100e54:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e5b:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100e5e:	0f b6 0e             	movzbl (%esi),%ecx
f0100e61:	0f b6 c1             	movzbl %cl,%eax
f0100e64:	83 e9 23             	sub    $0x23,%ecx
f0100e67:	80 f9 55             	cmp    $0x55,%cl
f0100e6a:	0f 87 2a 03 00 00    	ja     f010119a <vprintfmt+0x3ac>
f0100e70:	0f b6 c9             	movzbl %cl,%ecx
f0100e73:	ff 24 8d 60 1f 10 f0 	jmp    *-0xfefe0a0(,%ecx,4)
f0100e7a:	89 de                	mov    %ebx,%esi
f0100e7c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e81:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100e84:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0100e88:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100e8b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0100e8e:	83 fb 09             	cmp    $0x9,%ebx
f0100e91:	77 36                	ja     f0100ec9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e93:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e96:	eb e9                	jmp    f0100e81 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e98:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e9b:	8d 48 04             	lea    0x4(%eax),%ecx
f0100e9e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100ea1:	8b 00                	mov    (%eax),%eax
f0100ea3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ea6:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100ea8:	eb 22                	jmp    f0100ecc <vprintfmt+0xde>
f0100eaa:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100ead:	85 c9                	test   %ecx,%ecx
f0100eaf:	b8 00 00 00 00       	mov    $0x0,%eax
f0100eb4:	0f 49 c1             	cmovns %ecx,%eax
f0100eb7:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eba:	89 de                	mov    %ebx,%esi
f0100ebc:	eb 9d                	jmp    f0100e5b <vprintfmt+0x6d>
f0100ebe:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100ec0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0100ec7:	eb 92                	jmp    f0100e5b <vprintfmt+0x6d>
f0100ec9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f0100ecc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100ed0:	79 89                	jns    f0100e5b <vprintfmt+0x6d>
f0100ed2:	e9 77 ff ff ff       	jmp    f0100e4e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100ed7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eda:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100edc:	e9 7a ff ff ff       	jmp    f0100e5b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100ee1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ee4:	8d 50 04             	lea    0x4(%eax),%edx
f0100ee7:	89 55 14             	mov    %edx,0x14(%ebp)
f0100eea:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100eee:	8b 00                	mov    (%eax),%eax
f0100ef0:	89 04 24             	mov    %eax,(%esp)
f0100ef3:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100ef6:	e9 18 ff ff ff       	jmp    f0100e13 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100efb:	8b 45 14             	mov    0x14(%ebp),%eax
f0100efe:	8d 50 04             	lea    0x4(%eax),%edx
f0100f01:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f04:	8b 00                	mov    (%eax),%eax
f0100f06:	99                   	cltd   
f0100f07:	31 d0                	xor    %edx,%eax
f0100f09:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f0b:	83 f8 07             	cmp    $0x7,%eax
f0100f0e:	7f 0b                	jg     f0100f1b <vprintfmt+0x12d>
f0100f10:	8b 14 85 c0 20 10 f0 	mov    -0xfefdf40(,%eax,4),%edx
f0100f17:	85 d2                	test   %edx,%edx
f0100f19:	75 20                	jne    f0100f3b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f0100f1b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f1f:	c7 44 24 08 e1 1e 10 	movl   $0xf0101ee1,0x8(%esp)
f0100f26:	f0 
f0100f27:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f2b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f2e:	89 04 24             	mov    %eax,(%esp)
f0100f31:	e8 90 fe ff ff       	call   f0100dc6 <printfmt>
f0100f36:	e9 d8 fe ff ff       	jmp    f0100e13 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0100f3b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100f3f:	c7 44 24 08 ea 1e 10 	movl   $0xf0101eea,0x8(%esp)
f0100f46:	f0 
f0100f47:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f4b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f4e:	89 04 24             	mov    %eax,(%esp)
f0100f51:	e8 70 fe ff ff       	call   f0100dc6 <printfmt>
f0100f56:	e9 b8 fe ff ff       	jmp    f0100e13 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f5b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100f5e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100f61:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f64:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f67:	8d 50 04             	lea    0x4(%eax),%edx
f0100f6a:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f6d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0100f6f:	85 f6                	test   %esi,%esi
f0100f71:	b8 da 1e 10 f0       	mov    $0xf0101eda,%eax
f0100f76:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0100f79:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0100f7d:	0f 84 97 00 00 00    	je     f010101a <vprintfmt+0x22c>
f0100f83:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0100f87:	0f 8e 9b 00 00 00    	jle    f0101028 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f8d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100f91:	89 34 24             	mov    %esi,(%esp)
f0100f94:	e8 9f 03 00 00       	call   f0101338 <strnlen>
f0100f99:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100f9c:	29 c2                	sub    %eax,%edx
f0100f9e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0100fa1:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0100fa5:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100fa8:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0100fab:	8b 75 08             	mov    0x8(%ebp),%esi
f0100fae:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0100fb1:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fb3:	eb 0f                	jmp    f0100fc4 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0100fb5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fb9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100fbc:	89 04 24             	mov    %eax,(%esp)
f0100fbf:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fc1:	83 eb 01             	sub    $0x1,%ebx
f0100fc4:	85 db                	test   %ebx,%ebx
f0100fc6:	7f ed                	jg     f0100fb5 <vprintfmt+0x1c7>
f0100fc8:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0100fcb:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100fce:	85 d2                	test   %edx,%edx
f0100fd0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fd5:	0f 49 c2             	cmovns %edx,%eax
f0100fd8:	29 c2                	sub    %eax,%edx
f0100fda:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0100fdd:	89 d7                	mov    %edx,%edi
f0100fdf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100fe2:	eb 50                	jmp    f0101034 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100fe4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100fe8:	74 1e                	je     f0101008 <vprintfmt+0x21a>
f0100fea:	0f be d2             	movsbl %dl,%edx
f0100fed:	83 ea 20             	sub    $0x20,%edx
f0100ff0:	83 fa 5e             	cmp    $0x5e,%edx
f0100ff3:	76 13                	jbe    f0101008 <vprintfmt+0x21a>
					putch('?', putdat);
f0100ff5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ff8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ffc:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101003:	ff 55 08             	call   *0x8(%ebp)
f0101006:	eb 0d                	jmp    f0101015 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0101008:	8b 55 0c             	mov    0xc(%ebp),%edx
f010100b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010100f:	89 04 24             	mov    %eax,(%esp)
f0101012:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101015:	83 ef 01             	sub    $0x1,%edi
f0101018:	eb 1a                	jmp    f0101034 <vprintfmt+0x246>
f010101a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010101d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0101020:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101023:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101026:	eb 0c                	jmp    f0101034 <vprintfmt+0x246>
f0101028:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010102b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f010102e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101031:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101034:	83 c6 01             	add    $0x1,%esi
f0101037:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f010103b:	0f be c2             	movsbl %dl,%eax
f010103e:	85 c0                	test   %eax,%eax
f0101040:	74 27                	je     f0101069 <vprintfmt+0x27b>
f0101042:	85 db                	test   %ebx,%ebx
f0101044:	78 9e                	js     f0100fe4 <vprintfmt+0x1f6>
f0101046:	83 eb 01             	sub    $0x1,%ebx
f0101049:	79 99                	jns    f0100fe4 <vprintfmt+0x1f6>
f010104b:	89 f8                	mov    %edi,%eax
f010104d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101050:	8b 75 08             	mov    0x8(%ebp),%esi
f0101053:	89 c3                	mov    %eax,%ebx
f0101055:	eb 1a                	jmp    f0101071 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101057:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010105b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101062:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101064:	83 eb 01             	sub    $0x1,%ebx
f0101067:	eb 08                	jmp    f0101071 <vprintfmt+0x283>
f0101069:	89 fb                	mov    %edi,%ebx
f010106b:	8b 75 08             	mov    0x8(%ebp),%esi
f010106e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101071:	85 db                	test   %ebx,%ebx
f0101073:	7f e2                	jg     f0101057 <vprintfmt+0x269>
f0101075:	89 75 08             	mov    %esi,0x8(%ebp)
f0101078:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010107b:	e9 93 fd ff ff       	jmp    f0100e13 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101080:	83 fa 01             	cmp    $0x1,%edx
f0101083:	7e 16                	jle    f010109b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0101085:	8b 45 14             	mov    0x14(%ebp),%eax
f0101088:	8d 50 08             	lea    0x8(%eax),%edx
f010108b:	89 55 14             	mov    %edx,0x14(%ebp)
f010108e:	8b 50 04             	mov    0x4(%eax),%edx
f0101091:	8b 00                	mov    (%eax),%eax
f0101093:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101096:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101099:	eb 32                	jmp    f01010cd <vprintfmt+0x2df>
	else if (lflag)
f010109b:	85 d2                	test   %edx,%edx
f010109d:	74 18                	je     f01010b7 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010109f:	8b 45 14             	mov    0x14(%ebp),%eax
f01010a2:	8d 50 04             	lea    0x4(%eax),%edx
f01010a5:	89 55 14             	mov    %edx,0x14(%ebp)
f01010a8:	8b 30                	mov    (%eax),%esi
f01010aa:	89 75 e0             	mov    %esi,-0x20(%ebp)
f01010ad:	89 f0                	mov    %esi,%eax
f01010af:	c1 f8 1f             	sar    $0x1f,%eax
f01010b2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01010b5:	eb 16                	jmp    f01010cd <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f01010b7:	8b 45 14             	mov    0x14(%ebp),%eax
f01010ba:	8d 50 04             	lea    0x4(%eax),%edx
f01010bd:	89 55 14             	mov    %edx,0x14(%ebp)
f01010c0:	8b 30                	mov    (%eax),%esi
f01010c2:	89 75 e0             	mov    %esi,-0x20(%ebp)
f01010c5:	89 f0                	mov    %esi,%eax
f01010c7:	c1 f8 1f             	sar    $0x1f,%eax
f01010ca:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01010cd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010d0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01010d3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01010d8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01010dc:	0f 89 80 00 00 00    	jns    f0101162 <vprintfmt+0x374>
				putch('-', putdat);
f01010e2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010e6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01010ed:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01010f0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010f3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01010f6:	f7 d8                	neg    %eax
f01010f8:	83 d2 00             	adc    $0x0,%edx
f01010fb:	f7 da                	neg    %edx
			}
			base = 10;
f01010fd:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101102:	eb 5e                	jmp    f0101162 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101104:	8d 45 14             	lea    0x14(%ebp),%eax
f0101107:	e8 63 fc ff ff       	call   f0100d6f <getuint>
			base = 10;
f010110c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101111:	eb 4f                	jmp    f0101162 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0101113:	8d 45 14             	lea    0x14(%ebp),%eax
f0101116:	e8 54 fc ff ff       	call   f0100d6f <getuint>
			base = 8;
f010111b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101120:	eb 40                	jmp    f0101162 <vprintfmt+0x374>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f0101122:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101126:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010112d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101130:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101134:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010113b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010113e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101141:	8d 50 04             	lea    0x4(%eax),%edx
f0101144:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101147:	8b 00                	mov    (%eax),%eax
f0101149:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010114e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101153:	eb 0d                	jmp    f0101162 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101155:	8d 45 14             	lea    0x14(%ebp),%eax
f0101158:	e8 12 fc ff ff       	call   f0100d6f <getuint>
			base = 16;
f010115d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101162:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0101166:	89 74 24 10          	mov    %esi,0x10(%esp)
f010116a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010116d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0101171:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101175:	89 04 24             	mov    %eax,(%esp)
f0101178:	89 54 24 04          	mov    %edx,0x4(%esp)
f010117c:	89 fa                	mov    %edi,%edx
f010117e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101181:	e8 fa fa ff ff       	call   f0100c80 <printnum>
			break;
f0101186:	e9 88 fc ff ff       	jmp    f0100e13 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010118b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010118f:	89 04 24             	mov    %eax,(%esp)
f0101192:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101195:	e9 79 fc ff ff       	jmp    f0100e13 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010119a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010119e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01011a5:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01011a8:	89 f3                	mov    %esi,%ebx
f01011aa:	eb 03                	jmp    f01011af <vprintfmt+0x3c1>
f01011ac:	83 eb 01             	sub    $0x1,%ebx
f01011af:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f01011b3:	75 f7                	jne    f01011ac <vprintfmt+0x3be>
f01011b5:	e9 59 fc ff ff       	jmp    f0100e13 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f01011ba:	83 c4 3c             	add    $0x3c,%esp
f01011bd:	5b                   	pop    %ebx
f01011be:	5e                   	pop    %esi
f01011bf:	5f                   	pop    %edi
f01011c0:	5d                   	pop    %ebp
f01011c1:	c3                   	ret    

f01011c2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01011c2:	55                   	push   %ebp
f01011c3:	89 e5                	mov    %esp,%ebp
f01011c5:	83 ec 28             	sub    $0x28,%esp
f01011c8:	8b 45 08             	mov    0x8(%ebp),%eax
f01011cb:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01011ce:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01011d1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01011d5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01011d8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01011df:	85 c0                	test   %eax,%eax
f01011e1:	74 30                	je     f0101213 <vsnprintf+0x51>
f01011e3:	85 d2                	test   %edx,%edx
f01011e5:	7e 2c                	jle    f0101213 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01011e7:	8b 45 14             	mov    0x14(%ebp),%eax
f01011ea:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011ee:	8b 45 10             	mov    0x10(%ebp),%eax
f01011f1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011f5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01011f8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011fc:	c7 04 24 a9 0d 10 f0 	movl   $0xf0100da9,(%esp)
f0101203:	e8 e6 fb ff ff       	call   f0100dee <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101208:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010120b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010120e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101211:	eb 05                	jmp    f0101218 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101213:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101218:	c9                   	leave  
f0101219:	c3                   	ret    

f010121a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010121a:	55                   	push   %ebp
f010121b:	89 e5                	mov    %esp,%ebp
f010121d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101220:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101223:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101227:	8b 45 10             	mov    0x10(%ebp),%eax
f010122a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010122e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101231:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101235:	8b 45 08             	mov    0x8(%ebp),%eax
f0101238:	89 04 24             	mov    %eax,(%esp)
f010123b:	e8 82 ff ff ff       	call   f01011c2 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101240:	c9                   	leave  
f0101241:	c3                   	ret    
f0101242:	66 90                	xchg   %ax,%ax
f0101244:	66 90                	xchg   %ax,%ax
f0101246:	66 90                	xchg   %ax,%ax
f0101248:	66 90                	xchg   %ax,%ax
f010124a:	66 90                	xchg   %ax,%ax
f010124c:	66 90                	xchg   %ax,%ax
f010124e:	66 90                	xchg   %ax,%ax

f0101250 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101250:	55                   	push   %ebp
f0101251:	89 e5                	mov    %esp,%ebp
f0101253:	57                   	push   %edi
f0101254:	56                   	push   %esi
f0101255:	53                   	push   %ebx
f0101256:	83 ec 1c             	sub    $0x1c,%esp
f0101259:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010125c:	85 c0                	test   %eax,%eax
f010125e:	74 10                	je     f0101270 <readline+0x20>
		cprintf("%s", prompt);
f0101260:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101264:	c7 04 24 ea 1e 10 f0 	movl   $0xf0101eea,(%esp)
f010126b:	e8 38 f7 ff ff       	call   f01009a8 <cprintf>

	i = 0;
	echoing = iscons(0);
f0101270:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101277:	e8 16 f4 ff ff       	call   f0100692 <iscons>
f010127c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010127e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101283:	e8 f9 f3 ff ff       	call   f0100681 <getchar>
f0101288:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010128a:	85 c0                	test   %eax,%eax
f010128c:	79 17                	jns    f01012a5 <readline+0x55>
			cprintf("read error: %e\n", c);
f010128e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101292:	c7 04 24 e0 20 10 f0 	movl   $0xf01020e0,(%esp)
f0101299:	e8 0a f7 ff ff       	call   f01009a8 <cprintf>
			return NULL;
f010129e:	b8 00 00 00 00       	mov    $0x0,%eax
f01012a3:	eb 6d                	jmp    f0101312 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01012a5:	83 f8 7f             	cmp    $0x7f,%eax
f01012a8:	74 05                	je     f01012af <readline+0x5f>
f01012aa:	83 f8 08             	cmp    $0x8,%eax
f01012ad:	75 19                	jne    f01012c8 <readline+0x78>
f01012af:	85 f6                	test   %esi,%esi
f01012b1:	7e 15                	jle    f01012c8 <readline+0x78>
			if (echoing)
f01012b3:	85 ff                	test   %edi,%edi
f01012b5:	74 0c                	je     f01012c3 <readline+0x73>
				cputchar('\b');
f01012b7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01012be:	e8 ae f3 ff ff       	call   f0100671 <cputchar>
			i--;
f01012c3:	83 ee 01             	sub    $0x1,%esi
f01012c6:	eb bb                	jmp    f0101283 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01012c8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01012ce:	7f 1c                	jg     f01012ec <readline+0x9c>
f01012d0:	83 fb 1f             	cmp    $0x1f,%ebx
f01012d3:	7e 17                	jle    f01012ec <readline+0x9c>
			if (echoing)
f01012d5:	85 ff                	test   %edi,%edi
f01012d7:	74 08                	je     f01012e1 <readline+0x91>
				cputchar(c);
f01012d9:	89 1c 24             	mov    %ebx,(%esp)
f01012dc:	e8 90 f3 ff ff       	call   f0100671 <cputchar>
			buf[i++] = c;
f01012e1:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f01012e7:	8d 76 01             	lea    0x1(%esi),%esi
f01012ea:	eb 97                	jmp    f0101283 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01012ec:	83 fb 0d             	cmp    $0xd,%ebx
f01012ef:	74 05                	je     f01012f6 <readline+0xa6>
f01012f1:	83 fb 0a             	cmp    $0xa,%ebx
f01012f4:	75 8d                	jne    f0101283 <readline+0x33>
			if (echoing)
f01012f6:	85 ff                	test   %edi,%edi
f01012f8:	74 0c                	je     f0101306 <readline+0xb6>
				cputchar('\n');
f01012fa:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101301:	e8 6b f3 ff ff       	call   f0100671 <cputchar>
			buf[i] = 0;
f0101306:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010130d:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101312:	83 c4 1c             	add    $0x1c,%esp
f0101315:	5b                   	pop    %ebx
f0101316:	5e                   	pop    %esi
f0101317:	5f                   	pop    %edi
f0101318:	5d                   	pop    %ebp
f0101319:	c3                   	ret    
f010131a:	66 90                	xchg   %ax,%ax
f010131c:	66 90                	xchg   %ax,%ax
f010131e:	66 90                	xchg   %ax,%ax

f0101320 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101320:	55                   	push   %ebp
f0101321:	89 e5                	mov    %esp,%ebp
f0101323:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101326:	b8 00 00 00 00       	mov    $0x0,%eax
f010132b:	eb 03                	jmp    f0101330 <strlen+0x10>
		n++;
f010132d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101330:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101334:	75 f7                	jne    f010132d <strlen+0xd>
		n++;
	return n;
}
f0101336:	5d                   	pop    %ebp
f0101337:	c3                   	ret    

f0101338 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101338:	55                   	push   %ebp
f0101339:	89 e5                	mov    %esp,%ebp
f010133b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010133e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101341:	b8 00 00 00 00       	mov    $0x0,%eax
f0101346:	eb 03                	jmp    f010134b <strnlen+0x13>
		n++;
f0101348:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010134b:	39 d0                	cmp    %edx,%eax
f010134d:	74 06                	je     f0101355 <strnlen+0x1d>
f010134f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101353:	75 f3                	jne    f0101348 <strnlen+0x10>
		n++;
	return n;
}
f0101355:	5d                   	pop    %ebp
f0101356:	c3                   	ret    

f0101357 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101357:	55                   	push   %ebp
f0101358:	89 e5                	mov    %esp,%ebp
f010135a:	53                   	push   %ebx
f010135b:	8b 45 08             	mov    0x8(%ebp),%eax
f010135e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101361:	89 c2                	mov    %eax,%edx
f0101363:	83 c2 01             	add    $0x1,%edx
f0101366:	83 c1 01             	add    $0x1,%ecx
f0101369:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010136d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101370:	84 db                	test   %bl,%bl
f0101372:	75 ef                	jne    f0101363 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101374:	5b                   	pop    %ebx
f0101375:	5d                   	pop    %ebp
f0101376:	c3                   	ret    

f0101377 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101377:	55                   	push   %ebp
f0101378:	89 e5                	mov    %esp,%ebp
f010137a:	53                   	push   %ebx
f010137b:	83 ec 08             	sub    $0x8,%esp
f010137e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101381:	89 1c 24             	mov    %ebx,(%esp)
f0101384:	e8 97 ff ff ff       	call   f0101320 <strlen>
	strcpy(dst + len, src);
f0101389:	8b 55 0c             	mov    0xc(%ebp),%edx
f010138c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101390:	01 d8                	add    %ebx,%eax
f0101392:	89 04 24             	mov    %eax,(%esp)
f0101395:	e8 bd ff ff ff       	call   f0101357 <strcpy>
	return dst;
}
f010139a:	89 d8                	mov    %ebx,%eax
f010139c:	83 c4 08             	add    $0x8,%esp
f010139f:	5b                   	pop    %ebx
f01013a0:	5d                   	pop    %ebp
f01013a1:	c3                   	ret    

f01013a2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01013a2:	55                   	push   %ebp
f01013a3:	89 e5                	mov    %esp,%ebp
f01013a5:	56                   	push   %esi
f01013a6:	53                   	push   %ebx
f01013a7:	8b 75 08             	mov    0x8(%ebp),%esi
f01013aa:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01013ad:	89 f3                	mov    %esi,%ebx
f01013af:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013b2:	89 f2                	mov    %esi,%edx
f01013b4:	eb 0f                	jmp    f01013c5 <strncpy+0x23>
		*dst++ = *src;
f01013b6:	83 c2 01             	add    $0x1,%edx
f01013b9:	0f b6 01             	movzbl (%ecx),%eax
f01013bc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01013bf:	80 39 01             	cmpb   $0x1,(%ecx)
f01013c2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013c5:	39 da                	cmp    %ebx,%edx
f01013c7:	75 ed                	jne    f01013b6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01013c9:	89 f0                	mov    %esi,%eax
f01013cb:	5b                   	pop    %ebx
f01013cc:	5e                   	pop    %esi
f01013cd:	5d                   	pop    %ebp
f01013ce:	c3                   	ret    

f01013cf <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01013cf:	55                   	push   %ebp
f01013d0:	89 e5                	mov    %esp,%ebp
f01013d2:	56                   	push   %esi
f01013d3:	53                   	push   %ebx
f01013d4:	8b 75 08             	mov    0x8(%ebp),%esi
f01013d7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013da:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01013dd:	89 f0                	mov    %esi,%eax
f01013df:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01013e3:	85 c9                	test   %ecx,%ecx
f01013e5:	75 0b                	jne    f01013f2 <strlcpy+0x23>
f01013e7:	eb 1d                	jmp    f0101406 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01013e9:	83 c0 01             	add    $0x1,%eax
f01013ec:	83 c2 01             	add    $0x1,%edx
f01013ef:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01013f2:	39 d8                	cmp    %ebx,%eax
f01013f4:	74 0b                	je     f0101401 <strlcpy+0x32>
f01013f6:	0f b6 0a             	movzbl (%edx),%ecx
f01013f9:	84 c9                	test   %cl,%cl
f01013fb:	75 ec                	jne    f01013e9 <strlcpy+0x1a>
f01013fd:	89 c2                	mov    %eax,%edx
f01013ff:	eb 02                	jmp    f0101403 <strlcpy+0x34>
f0101401:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0101403:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0101406:	29 f0                	sub    %esi,%eax
}
f0101408:	5b                   	pop    %ebx
f0101409:	5e                   	pop    %esi
f010140a:	5d                   	pop    %ebp
f010140b:	c3                   	ret    

f010140c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010140c:	55                   	push   %ebp
f010140d:	89 e5                	mov    %esp,%ebp
f010140f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101412:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101415:	eb 06                	jmp    f010141d <strcmp+0x11>
		p++, q++;
f0101417:	83 c1 01             	add    $0x1,%ecx
f010141a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010141d:	0f b6 01             	movzbl (%ecx),%eax
f0101420:	84 c0                	test   %al,%al
f0101422:	74 04                	je     f0101428 <strcmp+0x1c>
f0101424:	3a 02                	cmp    (%edx),%al
f0101426:	74 ef                	je     f0101417 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101428:	0f b6 c0             	movzbl %al,%eax
f010142b:	0f b6 12             	movzbl (%edx),%edx
f010142e:	29 d0                	sub    %edx,%eax
}
f0101430:	5d                   	pop    %ebp
f0101431:	c3                   	ret    

f0101432 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101432:	55                   	push   %ebp
f0101433:	89 e5                	mov    %esp,%ebp
f0101435:	53                   	push   %ebx
f0101436:	8b 45 08             	mov    0x8(%ebp),%eax
f0101439:	8b 55 0c             	mov    0xc(%ebp),%edx
f010143c:	89 c3                	mov    %eax,%ebx
f010143e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101441:	eb 06                	jmp    f0101449 <strncmp+0x17>
		n--, p++, q++;
f0101443:	83 c0 01             	add    $0x1,%eax
f0101446:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101449:	39 d8                	cmp    %ebx,%eax
f010144b:	74 15                	je     f0101462 <strncmp+0x30>
f010144d:	0f b6 08             	movzbl (%eax),%ecx
f0101450:	84 c9                	test   %cl,%cl
f0101452:	74 04                	je     f0101458 <strncmp+0x26>
f0101454:	3a 0a                	cmp    (%edx),%cl
f0101456:	74 eb                	je     f0101443 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101458:	0f b6 00             	movzbl (%eax),%eax
f010145b:	0f b6 12             	movzbl (%edx),%edx
f010145e:	29 d0                	sub    %edx,%eax
f0101460:	eb 05                	jmp    f0101467 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101462:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101467:	5b                   	pop    %ebx
f0101468:	5d                   	pop    %ebp
f0101469:	c3                   	ret    

f010146a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010146a:	55                   	push   %ebp
f010146b:	89 e5                	mov    %esp,%ebp
f010146d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101470:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101474:	eb 07                	jmp    f010147d <strchr+0x13>
		if (*s == c)
f0101476:	38 ca                	cmp    %cl,%dl
f0101478:	74 0f                	je     f0101489 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010147a:	83 c0 01             	add    $0x1,%eax
f010147d:	0f b6 10             	movzbl (%eax),%edx
f0101480:	84 d2                	test   %dl,%dl
f0101482:	75 f2                	jne    f0101476 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101484:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101489:	5d                   	pop    %ebp
f010148a:	c3                   	ret    

f010148b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010148b:	55                   	push   %ebp
f010148c:	89 e5                	mov    %esp,%ebp
f010148e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101491:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101495:	eb 07                	jmp    f010149e <strfind+0x13>
		if (*s == c)
f0101497:	38 ca                	cmp    %cl,%dl
f0101499:	74 0a                	je     f01014a5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010149b:	83 c0 01             	add    $0x1,%eax
f010149e:	0f b6 10             	movzbl (%eax),%edx
f01014a1:	84 d2                	test   %dl,%dl
f01014a3:	75 f2                	jne    f0101497 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f01014a5:	5d                   	pop    %ebp
f01014a6:	c3                   	ret    

f01014a7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01014a7:	55                   	push   %ebp
f01014a8:	89 e5                	mov    %esp,%ebp
f01014aa:	57                   	push   %edi
f01014ab:	56                   	push   %esi
f01014ac:	53                   	push   %ebx
f01014ad:	8b 7d 08             	mov    0x8(%ebp),%edi
f01014b0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01014b3:	85 c9                	test   %ecx,%ecx
f01014b5:	74 36                	je     f01014ed <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01014b7:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01014bd:	75 28                	jne    f01014e7 <memset+0x40>
f01014bf:	f6 c1 03             	test   $0x3,%cl
f01014c2:	75 23                	jne    f01014e7 <memset+0x40>
		c &= 0xFF;
f01014c4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01014c8:	89 d3                	mov    %edx,%ebx
f01014ca:	c1 e3 08             	shl    $0x8,%ebx
f01014cd:	89 d6                	mov    %edx,%esi
f01014cf:	c1 e6 18             	shl    $0x18,%esi
f01014d2:	89 d0                	mov    %edx,%eax
f01014d4:	c1 e0 10             	shl    $0x10,%eax
f01014d7:	09 f0                	or     %esi,%eax
f01014d9:	09 c2                	or     %eax,%edx
f01014db:	89 d0                	mov    %edx,%eax
f01014dd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01014df:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01014e2:	fc                   	cld    
f01014e3:	f3 ab                	rep stos %eax,%es:(%edi)
f01014e5:	eb 06                	jmp    f01014ed <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01014e7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014ea:	fc                   	cld    
f01014eb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01014ed:	89 f8                	mov    %edi,%eax
f01014ef:	5b                   	pop    %ebx
f01014f0:	5e                   	pop    %esi
f01014f1:	5f                   	pop    %edi
f01014f2:	5d                   	pop    %ebp
f01014f3:	c3                   	ret    

f01014f4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01014f4:	55                   	push   %ebp
f01014f5:	89 e5                	mov    %esp,%ebp
f01014f7:	57                   	push   %edi
f01014f8:	56                   	push   %esi
f01014f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01014fc:	8b 75 0c             	mov    0xc(%ebp),%esi
f01014ff:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101502:	39 c6                	cmp    %eax,%esi
f0101504:	73 35                	jae    f010153b <memmove+0x47>
f0101506:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101509:	39 d0                	cmp    %edx,%eax
f010150b:	73 2e                	jae    f010153b <memmove+0x47>
		s += n;
		d += n;
f010150d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0101510:	89 d6                	mov    %edx,%esi
f0101512:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101514:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010151a:	75 13                	jne    f010152f <memmove+0x3b>
f010151c:	f6 c1 03             	test   $0x3,%cl
f010151f:	75 0e                	jne    f010152f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101521:	83 ef 04             	sub    $0x4,%edi
f0101524:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101527:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010152a:	fd                   	std    
f010152b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010152d:	eb 09                	jmp    f0101538 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010152f:	83 ef 01             	sub    $0x1,%edi
f0101532:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101535:	fd                   	std    
f0101536:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101538:	fc                   	cld    
f0101539:	eb 1d                	jmp    f0101558 <memmove+0x64>
f010153b:	89 f2                	mov    %esi,%edx
f010153d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010153f:	f6 c2 03             	test   $0x3,%dl
f0101542:	75 0f                	jne    f0101553 <memmove+0x5f>
f0101544:	f6 c1 03             	test   $0x3,%cl
f0101547:	75 0a                	jne    f0101553 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101549:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010154c:	89 c7                	mov    %eax,%edi
f010154e:	fc                   	cld    
f010154f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101551:	eb 05                	jmp    f0101558 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101553:	89 c7                	mov    %eax,%edi
f0101555:	fc                   	cld    
f0101556:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101558:	5e                   	pop    %esi
f0101559:	5f                   	pop    %edi
f010155a:	5d                   	pop    %ebp
f010155b:	c3                   	ret    

f010155c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010155c:	55                   	push   %ebp
f010155d:	89 e5                	mov    %esp,%ebp
f010155f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101562:	8b 45 10             	mov    0x10(%ebp),%eax
f0101565:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101569:	8b 45 0c             	mov    0xc(%ebp),%eax
f010156c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101570:	8b 45 08             	mov    0x8(%ebp),%eax
f0101573:	89 04 24             	mov    %eax,(%esp)
f0101576:	e8 79 ff ff ff       	call   f01014f4 <memmove>
}
f010157b:	c9                   	leave  
f010157c:	c3                   	ret    

f010157d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010157d:	55                   	push   %ebp
f010157e:	89 e5                	mov    %esp,%ebp
f0101580:	56                   	push   %esi
f0101581:	53                   	push   %ebx
f0101582:	8b 55 08             	mov    0x8(%ebp),%edx
f0101585:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101588:	89 d6                	mov    %edx,%esi
f010158a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010158d:	eb 1a                	jmp    f01015a9 <memcmp+0x2c>
		if (*s1 != *s2)
f010158f:	0f b6 02             	movzbl (%edx),%eax
f0101592:	0f b6 19             	movzbl (%ecx),%ebx
f0101595:	38 d8                	cmp    %bl,%al
f0101597:	74 0a                	je     f01015a3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101599:	0f b6 c0             	movzbl %al,%eax
f010159c:	0f b6 db             	movzbl %bl,%ebx
f010159f:	29 d8                	sub    %ebx,%eax
f01015a1:	eb 0f                	jmp    f01015b2 <memcmp+0x35>
		s1++, s2++;
f01015a3:	83 c2 01             	add    $0x1,%edx
f01015a6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01015a9:	39 f2                	cmp    %esi,%edx
f01015ab:	75 e2                	jne    f010158f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01015ad:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01015b2:	5b                   	pop    %ebx
f01015b3:	5e                   	pop    %esi
f01015b4:	5d                   	pop    %ebp
f01015b5:	c3                   	ret    

f01015b6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01015b6:	55                   	push   %ebp
f01015b7:	89 e5                	mov    %esp,%ebp
f01015b9:	8b 45 08             	mov    0x8(%ebp),%eax
f01015bc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01015bf:	89 c2                	mov    %eax,%edx
f01015c1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01015c4:	eb 07                	jmp    f01015cd <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01015c6:	38 08                	cmp    %cl,(%eax)
f01015c8:	74 07                	je     f01015d1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01015ca:	83 c0 01             	add    $0x1,%eax
f01015cd:	39 d0                	cmp    %edx,%eax
f01015cf:	72 f5                	jb     f01015c6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01015d1:	5d                   	pop    %ebp
f01015d2:	c3                   	ret    

f01015d3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01015d3:	55                   	push   %ebp
f01015d4:	89 e5                	mov    %esp,%ebp
f01015d6:	57                   	push   %edi
f01015d7:	56                   	push   %esi
f01015d8:	53                   	push   %ebx
f01015d9:	8b 55 08             	mov    0x8(%ebp),%edx
f01015dc:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015df:	eb 03                	jmp    f01015e4 <strtol+0x11>
		s++;
f01015e1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015e4:	0f b6 0a             	movzbl (%edx),%ecx
f01015e7:	80 f9 09             	cmp    $0x9,%cl
f01015ea:	74 f5                	je     f01015e1 <strtol+0xe>
f01015ec:	80 f9 20             	cmp    $0x20,%cl
f01015ef:	74 f0                	je     f01015e1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01015f1:	80 f9 2b             	cmp    $0x2b,%cl
f01015f4:	75 0a                	jne    f0101600 <strtol+0x2d>
		s++;
f01015f6:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01015f9:	bf 00 00 00 00       	mov    $0x0,%edi
f01015fe:	eb 11                	jmp    f0101611 <strtol+0x3e>
f0101600:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101605:	80 f9 2d             	cmp    $0x2d,%cl
f0101608:	75 07                	jne    f0101611 <strtol+0x3e>
		s++, neg = 1;
f010160a:	8d 52 01             	lea    0x1(%edx),%edx
f010160d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101611:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0101616:	75 15                	jne    f010162d <strtol+0x5a>
f0101618:	80 3a 30             	cmpb   $0x30,(%edx)
f010161b:	75 10                	jne    f010162d <strtol+0x5a>
f010161d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101621:	75 0a                	jne    f010162d <strtol+0x5a>
		s += 2, base = 16;
f0101623:	83 c2 02             	add    $0x2,%edx
f0101626:	b8 10 00 00 00       	mov    $0x10,%eax
f010162b:	eb 10                	jmp    f010163d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f010162d:	85 c0                	test   %eax,%eax
f010162f:	75 0c                	jne    f010163d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101631:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101633:	80 3a 30             	cmpb   $0x30,(%edx)
f0101636:	75 05                	jne    f010163d <strtol+0x6a>
		s++, base = 8;
f0101638:	83 c2 01             	add    $0x1,%edx
f010163b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010163d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101642:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101645:	0f b6 0a             	movzbl (%edx),%ecx
f0101648:	8d 71 d0             	lea    -0x30(%ecx),%esi
f010164b:	89 f0                	mov    %esi,%eax
f010164d:	3c 09                	cmp    $0x9,%al
f010164f:	77 08                	ja     f0101659 <strtol+0x86>
			dig = *s - '0';
f0101651:	0f be c9             	movsbl %cl,%ecx
f0101654:	83 e9 30             	sub    $0x30,%ecx
f0101657:	eb 20                	jmp    f0101679 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0101659:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010165c:	89 f0                	mov    %esi,%eax
f010165e:	3c 19                	cmp    $0x19,%al
f0101660:	77 08                	ja     f010166a <strtol+0x97>
			dig = *s - 'a' + 10;
f0101662:	0f be c9             	movsbl %cl,%ecx
f0101665:	83 e9 57             	sub    $0x57,%ecx
f0101668:	eb 0f                	jmp    f0101679 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f010166a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010166d:	89 f0                	mov    %esi,%eax
f010166f:	3c 19                	cmp    $0x19,%al
f0101671:	77 16                	ja     f0101689 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0101673:	0f be c9             	movsbl %cl,%ecx
f0101676:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101679:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f010167c:	7d 0f                	jge    f010168d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f010167e:	83 c2 01             	add    $0x1,%edx
f0101681:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0101685:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0101687:	eb bc                	jmp    f0101645 <strtol+0x72>
f0101689:	89 d8                	mov    %ebx,%eax
f010168b:	eb 02                	jmp    f010168f <strtol+0xbc>
f010168d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f010168f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101693:	74 05                	je     f010169a <strtol+0xc7>
		*endptr = (char *) s;
f0101695:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101698:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f010169a:	f7 d8                	neg    %eax
f010169c:	85 ff                	test   %edi,%edi
f010169e:	0f 44 c3             	cmove  %ebx,%eax
}
f01016a1:	5b                   	pop    %ebx
f01016a2:	5e                   	pop    %esi
f01016a3:	5f                   	pop    %edi
f01016a4:	5d                   	pop    %ebp
f01016a5:	c3                   	ret    
f01016a6:	66 90                	xchg   %ax,%ax
f01016a8:	66 90                	xchg   %ax,%ax
f01016aa:	66 90                	xchg   %ax,%ax
f01016ac:	66 90                	xchg   %ax,%ax
f01016ae:	66 90                	xchg   %ax,%ax

f01016b0 <__udivdi3>:
f01016b0:	55                   	push   %ebp
f01016b1:	57                   	push   %edi
f01016b2:	56                   	push   %esi
f01016b3:	83 ec 0c             	sub    $0xc,%esp
f01016b6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01016ba:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f01016be:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f01016c2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01016c6:	85 c0                	test   %eax,%eax
f01016c8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01016cc:	89 ea                	mov    %ebp,%edx
f01016ce:	89 0c 24             	mov    %ecx,(%esp)
f01016d1:	75 2d                	jne    f0101700 <__udivdi3+0x50>
f01016d3:	39 e9                	cmp    %ebp,%ecx
f01016d5:	77 61                	ja     f0101738 <__udivdi3+0x88>
f01016d7:	85 c9                	test   %ecx,%ecx
f01016d9:	89 ce                	mov    %ecx,%esi
f01016db:	75 0b                	jne    f01016e8 <__udivdi3+0x38>
f01016dd:	b8 01 00 00 00       	mov    $0x1,%eax
f01016e2:	31 d2                	xor    %edx,%edx
f01016e4:	f7 f1                	div    %ecx
f01016e6:	89 c6                	mov    %eax,%esi
f01016e8:	31 d2                	xor    %edx,%edx
f01016ea:	89 e8                	mov    %ebp,%eax
f01016ec:	f7 f6                	div    %esi
f01016ee:	89 c5                	mov    %eax,%ebp
f01016f0:	89 f8                	mov    %edi,%eax
f01016f2:	f7 f6                	div    %esi
f01016f4:	89 ea                	mov    %ebp,%edx
f01016f6:	83 c4 0c             	add    $0xc,%esp
f01016f9:	5e                   	pop    %esi
f01016fa:	5f                   	pop    %edi
f01016fb:	5d                   	pop    %ebp
f01016fc:	c3                   	ret    
f01016fd:	8d 76 00             	lea    0x0(%esi),%esi
f0101700:	39 e8                	cmp    %ebp,%eax
f0101702:	77 24                	ja     f0101728 <__udivdi3+0x78>
f0101704:	0f bd e8             	bsr    %eax,%ebp
f0101707:	83 f5 1f             	xor    $0x1f,%ebp
f010170a:	75 3c                	jne    f0101748 <__udivdi3+0x98>
f010170c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101710:	39 34 24             	cmp    %esi,(%esp)
f0101713:	0f 86 9f 00 00 00    	jbe    f01017b8 <__udivdi3+0x108>
f0101719:	39 d0                	cmp    %edx,%eax
f010171b:	0f 82 97 00 00 00    	jb     f01017b8 <__udivdi3+0x108>
f0101721:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101728:	31 d2                	xor    %edx,%edx
f010172a:	31 c0                	xor    %eax,%eax
f010172c:	83 c4 0c             	add    $0xc,%esp
f010172f:	5e                   	pop    %esi
f0101730:	5f                   	pop    %edi
f0101731:	5d                   	pop    %ebp
f0101732:	c3                   	ret    
f0101733:	90                   	nop
f0101734:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101738:	89 f8                	mov    %edi,%eax
f010173a:	f7 f1                	div    %ecx
f010173c:	31 d2                	xor    %edx,%edx
f010173e:	83 c4 0c             	add    $0xc,%esp
f0101741:	5e                   	pop    %esi
f0101742:	5f                   	pop    %edi
f0101743:	5d                   	pop    %ebp
f0101744:	c3                   	ret    
f0101745:	8d 76 00             	lea    0x0(%esi),%esi
f0101748:	89 e9                	mov    %ebp,%ecx
f010174a:	8b 3c 24             	mov    (%esp),%edi
f010174d:	d3 e0                	shl    %cl,%eax
f010174f:	89 c6                	mov    %eax,%esi
f0101751:	b8 20 00 00 00       	mov    $0x20,%eax
f0101756:	29 e8                	sub    %ebp,%eax
f0101758:	89 c1                	mov    %eax,%ecx
f010175a:	d3 ef                	shr    %cl,%edi
f010175c:	89 e9                	mov    %ebp,%ecx
f010175e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101762:	8b 3c 24             	mov    (%esp),%edi
f0101765:	09 74 24 08          	or     %esi,0x8(%esp)
f0101769:	89 d6                	mov    %edx,%esi
f010176b:	d3 e7                	shl    %cl,%edi
f010176d:	89 c1                	mov    %eax,%ecx
f010176f:	89 3c 24             	mov    %edi,(%esp)
f0101772:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101776:	d3 ee                	shr    %cl,%esi
f0101778:	89 e9                	mov    %ebp,%ecx
f010177a:	d3 e2                	shl    %cl,%edx
f010177c:	89 c1                	mov    %eax,%ecx
f010177e:	d3 ef                	shr    %cl,%edi
f0101780:	09 d7                	or     %edx,%edi
f0101782:	89 f2                	mov    %esi,%edx
f0101784:	89 f8                	mov    %edi,%eax
f0101786:	f7 74 24 08          	divl   0x8(%esp)
f010178a:	89 d6                	mov    %edx,%esi
f010178c:	89 c7                	mov    %eax,%edi
f010178e:	f7 24 24             	mull   (%esp)
f0101791:	39 d6                	cmp    %edx,%esi
f0101793:	89 14 24             	mov    %edx,(%esp)
f0101796:	72 30                	jb     f01017c8 <__udivdi3+0x118>
f0101798:	8b 54 24 04          	mov    0x4(%esp),%edx
f010179c:	89 e9                	mov    %ebp,%ecx
f010179e:	d3 e2                	shl    %cl,%edx
f01017a0:	39 c2                	cmp    %eax,%edx
f01017a2:	73 05                	jae    f01017a9 <__udivdi3+0xf9>
f01017a4:	3b 34 24             	cmp    (%esp),%esi
f01017a7:	74 1f                	je     f01017c8 <__udivdi3+0x118>
f01017a9:	89 f8                	mov    %edi,%eax
f01017ab:	31 d2                	xor    %edx,%edx
f01017ad:	e9 7a ff ff ff       	jmp    f010172c <__udivdi3+0x7c>
f01017b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01017b8:	31 d2                	xor    %edx,%edx
f01017ba:	b8 01 00 00 00       	mov    $0x1,%eax
f01017bf:	e9 68 ff ff ff       	jmp    f010172c <__udivdi3+0x7c>
f01017c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017c8:	8d 47 ff             	lea    -0x1(%edi),%eax
f01017cb:	31 d2                	xor    %edx,%edx
f01017cd:	83 c4 0c             	add    $0xc,%esp
f01017d0:	5e                   	pop    %esi
f01017d1:	5f                   	pop    %edi
f01017d2:	5d                   	pop    %ebp
f01017d3:	c3                   	ret    
f01017d4:	66 90                	xchg   %ax,%ax
f01017d6:	66 90                	xchg   %ax,%ax
f01017d8:	66 90                	xchg   %ax,%ax
f01017da:	66 90                	xchg   %ax,%ax
f01017dc:	66 90                	xchg   %ax,%ax
f01017de:	66 90                	xchg   %ax,%ax

f01017e0 <__umoddi3>:
f01017e0:	55                   	push   %ebp
f01017e1:	57                   	push   %edi
f01017e2:	56                   	push   %esi
f01017e3:	83 ec 14             	sub    $0x14,%esp
f01017e6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01017ea:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01017ee:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f01017f2:	89 c7                	mov    %eax,%edi
f01017f4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01017f8:	8b 44 24 30          	mov    0x30(%esp),%eax
f01017fc:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101800:	89 34 24             	mov    %esi,(%esp)
f0101803:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101807:	85 c0                	test   %eax,%eax
f0101809:	89 c2                	mov    %eax,%edx
f010180b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010180f:	75 17                	jne    f0101828 <__umoddi3+0x48>
f0101811:	39 fe                	cmp    %edi,%esi
f0101813:	76 4b                	jbe    f0101860 <__umoddi3+0x80>
f0101815:	89 c8                	mov    %ecx,%eax
f0101817:	89 fa                	mov    %edi,%edx
f0101819:	f7 f6                	div    %esi
f010181b:	89 d0                	mov    %edx,%eax
f010181d:	31 d2                	xor    %edx,%edx
f010181f:	83 c4 14             	add    $0x14,%esp
f0101822:	5e                   	pop    %esi
f0101823:	5f                   	pop    %edi
f0101824:	5d                   	pop    %ebp
f0101825:	c3                   	ret    
f0101826:	66 90                	xchg   %ax,%ax
f0101828:	39 f8                	cmp    %edi,%eax
f010182a:	77 54                	ja     f0101880 <__umoddi3+0xa0>
f010182c:	0f bd e8             	bsr    %eax,%ebp
f010182f:	83 f5 1f             	xor    $0x1f,%ebp
f0101832:	75 5c                	jne    f0101890 <__umoddi3+0xb0>
f0101834:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101838:	39 3c 24             	cmp    %edi,(%esp)
f010183b:	0f 87 e7 00 00 00    	ja     f0101928 <__umoddi3+0x148>
f0101841:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101845:	29 f1                	sub    %esi,%ecx
f0101847:	19 c7                	sbb    %eax,%edi
f0101849:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010184d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101851:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101855:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101859:	83 c4 14             	add    $0x14,%esp
f010185c:	5e                   	pop    %esi
f010185d:	5f                   	pop    %edi
f010185e:	5d                   	pop    %ebp
f010185f:	c3                   	ret    
f0101860:	85 f6                	test   %esi,%esi
f0101862:	89 f5                	mov    %esi,%ebp
f0101864:	75 0b                	jne    f0101871 <__umoddi3+0x91>
f0101866:	b8 01 00 00 00       	mov    $0x1,%eax
f010186b:	31 d2                	xor    %edx,%edx
f010186d:	f7 f6                	div    %esi
f010186f:	89 c5                	mov    %eax,%ebp
f0101871:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101875:	31 d2                	xor    %edx,%edx
f0101877:	f7 f5                	div    %ebp
f0101879:	89 c8                	mov    %ecx,%eax
f010187b:	f7 f5                	div    %ebp
f010187d:	eb 9c                	jmp    f010181b <__umoddi3+0x3b>
f010187f:	90                   	nop
f0101880:	89 c8                	mov    %ecx,%eax
f0101882:	89 fa                	mov    %edi,%edx
f0101884:	83 c4 14             	add    $0x14,%esp
f0101887:	5e                   	pop    %esi
f0101888:	5f                   	pop    %edi
f0101889:	5d                   	pop    %ebp
f010188a:	c3                   	ret    
f010188b:	90                   	nop
f010188c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101890:	8b 04 24             	mov    (%esp),%eax
f0101893:	be 20 00 00 00       	mov    $0x20,%esi
f0101898:	89 e9                	mov    %ebp,%ecx
f010189a:	29 ee                	sub    %ebp,%esi
f010189c:	d3 e2                	shl    %cl,%edx
f010189e:	89 f1                	mov    %esi,%ecx
f01018a0:	d3 e8                	shr    %cl,%eax
f01018a2:	89 e9                	mov    %ebp,%ecx
f01018a4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01018a8:	8b 04 24             	mov    (%esp),%eax
f01018ab:	09 54 24 04          	or     %edx,0x4(%esp)
f01018af:	89 fa                	mov    %edi,%edx
f01018b1:	d3 e0                	shl    %cl,%eax
f01018b3:	89 f1                	mov    %esi,%ecx
f01018b5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01018b9:	8b 44 24 10          	mov    0x10(%esp),%eax
f01018bd:	d3 ea                	shr    %cl,%edx
f01018bf:	89 e9                	mov    %ebp,%ecx
f01018c1:	d3 e7                	shl    %cl,%edi
f01018c3:	89 f1                	mov    %esi,%ecx
f01018c5:	d3 e8                	shr    %cl,%eax
f01018c7:	89 e9                	mov    %ebp,%ecx
f01018c9:	09 f8                	or     %edi,%eax
f01018cb:	8b 7c 24 10          	mov    0x10(%esp),%edi
f01018cf:	f7 74 24 04          	divl   0x4(%esp)
f01018d3:	d3 e7                	shl    %cl,%edi
f01018d5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01018d9:	89 d7                	mov    %edx,%edi
f01018db:	f7 64 24 08          	mull   0x8(%esp)
f01018df:	39 d7                	cmp    %edx,%edi
f01018e1:	89 c1                	mov    %eax,%ecx
f01018e3:	89 14 24             	mov    %edx,(%esp)
f01018e6:	72 2c                	jb     f0101914 <__umoddi3+0x134>
f01018e8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f01018ec:	72 22                	jb     f0101910 <__umoddi3+0x130>
f01018ee:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01018f2:	29 c8                	sub    %ecx,%eax
f01018f4:	19 d7                	sbb    %edx,%edi
f01018f6:	89 e9                	mov    %ebp,%ecx
f01018f8:	89 fa                	mov    %edi,%edx
f01018fa:	d3 e8                	shr    %cl,%eax
f01018fc:	89 f1                	mov    %esi,%ecx
f01018fe:	d3 e2                	shl    %cl,%edx
f0101900:	89 e9                	mov    %ebp,%ecx
f0101902:	d3 ef                	shr    %cl,%edi
f0101904:	09 d0                	or     %edx,%eax
f0101906:	89 fa                	mov    %edi,%edx
f0101908:	83 c4 14             	add    $0x14,%esp
f010190b:	5e                   	pop    %esi
f010190c:	5f                   	pop    %edi
f010190d:	5d                   	pop    %ebp
f010190e:	c3                   	ret    
f010190f:	90                   	nop
f0101910:	39 d7                	cmp    %edx,%edi
f0101912:	75 da                	jne    f01018ee <__umoddi3+0x10e>
f0101914:	8b 14 24             	mov    (%esp),%edx
f0101917:	89 c1                	mov    %eax,%ecx
f0101919:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f010191d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0101921:	eb cb                	jmp    f01018ee <__umoddi3+0x10e>
f0101923:	90                   	nop
f0101924:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101928:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f010192c:	0f 82 0f ff ff ff    	jb     f0101841 <__umoddi3+0x61>
f0101932:	e9 1a ff ff ff       	jmp    f0101851 <__umoddi3+0x71>
