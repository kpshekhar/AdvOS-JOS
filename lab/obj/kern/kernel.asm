
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
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
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
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 79 11 f0       	mov    $0xf0117970,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 73 11 f0 	movl   $0xf0117300,(%esp)
f0100063:	e8 2f 3a 00 00       	call   f0103a97 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 92 04 00 00       	call   f01004ff <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 40 3f 10 f0 	movl   $0xf0103f40,(%esp)
f010007c:	e8 b1 2e 00 00       	call   f0102f32 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 bd 12 00 00       	call   f0101343 <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 53 07 00 00       	call   f01007e5 <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 60 79 11 f0 00 	cmpl   $0x0,0xf0117960
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 60 79 11 f0    	mov    %esi,0xf0117960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 5b 3f 10 f0 	movl   $0xf0103f5b,(%esp)
f01000c8:	e8 65 2e 00 00       	call   f0102f32 <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 26 2e 00 00       	call   f0102eff <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 af 4f 10 f0 	movl   $0xf0104faf,(%esp)
f01000e0:	e8 4d 2e 00 00       	call   f0102f32 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 f4 06 00 00       	call   f01007e5 <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 73 3f 10 f0 	movl   $0xf0103f73,(%esp)
f0100112:	e8 1b 2e 00 00       	call   f0102f32 <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 d9 2d 00 00       	call   f0102eff <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 af 4f 10 f0 	movl   $0xf0104faf,(%esp)
f010012d:	e8 00 2e 00 00       	call   f0102f32 <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
f0100138:	66 90                	xchg   %ax,%ax
f010013a:	66 90                	xchg   %ax,%ax
f010013c:	66 90                	xchg   %ax,%ax
f010013e:	66 90                	xchg   %ax,%ax

f0100140 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100148:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100149:	a8 01                	test   $0x1,%al
f010014b:	74 08                	je     f0100155 <serial_proc_data+0x15>
f010014d:	b2 f8                	mov    $0xf8,%dl
f010014f:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100150:	0f b6 c0             	movzbl %al,%eax
f0100153:	eb 05                	jmp    f010015a <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100155:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010015a:	5d                   	pop    %ebp
f010015b:	c3                   	ret    

f010015c <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010015c:	55                   	push   %ebp
f010015d:	89 e5                	mov    %esp,%ebp
f010015f:	53                   	push   %ebx
f0100160:	83 ec 04             	sub    $0x4,%esp
f0100163:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100165:	eb 2a                	jmp    f0100191 <cons_intr+0x35>
		if (c == 0)
f0100167:	85 d2                	test   %edx,%edx
f0100169:	74 26                	je     f0100191 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010016b:	a1 24 75 11 f0       	mov    0xf0117524,%eax
f0100170:	8d 48 01             	lea    0x1(%eax),%ecx
f0100173:	89 0d 24 75 11 f0    	mov    %ecx,0xf0117524
f0100179:	88 90 20 73 11 f0    	mov    %dl,-0xfee8ce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010017f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100185:	75 0a                	jne    f0100191 <cons_intr+0x35>
			cons.wpos = 0;
f0100187:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
f010018e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100191:	ff d3                	call   *%ebx
f0100193:	89 c2                	mov    %eax,%edx
f0100195:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100198:	75 cd                	jne    f0100167 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010019a:	83 c4 04             	add    $0x4,%esp
f010019d:	5b                   	pop    %ebx
f010019e:	5d                   	pop    %ebp
f010019f:	c3                   	ret    

f01001a0 <kbd_proc_data>:
f01001a0:	ba 64 00 00 00       	mov    $0x64,%edx
f01001a5:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001a6:	a8 01                	test   $0x1,%al
f01001a8:	0f 84 ef 00 00 00    	je     f010029d <kbd_proc_data+0xfd>
f01001ae:	b2 60                	mov    $0x60,%dl
f01001b0:	ec                   	in     (%dx),%al
f01001b1:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001b3:	3c e0                	cmp    $0xe0,%al
f01001b5:	75 0d                	jne    f01001c4 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f01001b7:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
		return 0;
f01001be:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001c3:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001c4:	55                   	push   %ebp
f01001c5:	89 e5                	mov    %esp,%ebp
f01001c7:	53                   	push   %ebx
f01001c8:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001cb:	84 c0                	test   %al,%al
f01001cd:	79 37                	jns    f0100206 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001cf:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001d5:	89 cb                	mov    %ecx,%ebx
f01001d7:	83 e3 40             	and    $0x40,%ebx
f01001da:	83 e0 7f             	and    $0x7f,%eax
f01001dd:	85 db                	test   %ebx,%ebx
f01001df:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001e2:	0f b6 d2             	movzbl %dl,%edx
f01001e5:	0f b6 82 e0 40 10 f0 	movzbl -0xfefbf20(%edx),%eax
f01001ec:	83 c8 40             	or     $0x40,%eax
f01001ef:	0f b6 c0             	movzbl %al,%eax
f01001f2:	f7 d0                	not    %eax
f01001f4:	21 c1                	and    %eax,%ecx
f01001f6:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
		return 0;
f01001fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0100201:	e9 9d 00 00 00       	jmp    f01002a3 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100206:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f010020c:	f6 c1 40             	test   $0x40,%cl
f010020f:	74 0e                	je     f010021f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100211:	83 c8 80             	or     $0xffffff80,%eax
f0100214:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100216:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100219:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
	}

	shift |= shiftcode[data];
f010021f:	0f b6 d2             	movzbl %dl,%edx
f0100222:	0f b6 82 e0 40 10 f0 	movzbl -0xfefbf20(%edx),%eax
f0100229:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
	shift ^= togglecode[data];
f010022f:	0f b6 8a e0 3f 10 f0 	movzbl -0xfefc020(%edx),%ecx
f0100236:	31 c8                	xor    %ecx,%eax
f0100238:	a3 00 73 11 f0       	mov    %eax,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f010023d:	89 c1                	mov    %eax,%ecx
f010023f:	83 e1 03             	and    $0x3,%ecx
f0100242:	8b 0c 8d c0 3f 10 f0 	mov    -0xfefc040(,%ecx,4),%ecx
f0100249:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010024d:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100250:	a8 08                	test   $0x8,%al
f0100252:	74 1b                	je     f010026f <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f0100254:	89 da                	mov    %ebx,%edx
f0100256:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100259:	83 f9 19             	cmp    $0x19,%ecx
f010025c:	77 05                	ja     f0100263 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f010025e:	83 eb 20             	sub    $0x20,%ebx
f0100261:	eb 0c                	jmp    f010026f <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f0100263:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100266:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100269:	83 fa 19             	cmp    $0x19,%edx
f010026c:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010026f:	f7 d0                	not    %eax
f0100271:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100273:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100275:	f6 c2 06             	test   $0x6,%dl
f0100278:	75 29                	jne    f01002a3 <kbd_proc_data+0x103>
f010027a:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100280:	75 21                	jne    f01002a3 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f0100282:	c7 04 24 8d 3f 10 f0 	movl   $0xf0103f8d,(%esp)
f0100289:	e8 a4 2c 00 00       	call   f0102f32 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010028e:	ba 92 00 00 00       	mov    $0x92,%edx
f0100293:	b8 03 00 00 00       	mov    $0x3,%eax
f0100298:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100299:	89 d8                	mov    %ebx,%eax
f010029b:	eb 06                	jmp    f01002a3 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010029d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002a2:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002a3:	83 c4 14             	add    $0x14,%esp
f01002a6:	5b                   	pop    %ebx
f01002a7:	5d                   	pop    %ebp
f01002a8:	c3                   	ret    

f01002a9 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002a9:	55                   	push   %ebp
f01002aa:	89 e5                	mov    %esp,%ebp
f01002ac:	57                   	push   %edi
f01002ad:	56                   	push   %esi
f01002ae:	53                   	push   %ebx
f01002af:	83 ec 1c             	sub    $0x1c,%esp
f01002b2:	89 c7                	mov    %eax,%edi
f01002b4:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002b9:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002be:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002c3:	eb 06                	jmp    f01002cb <cons_putc+0x22>
f01002c5:	89 ca                	mov    %ecx,%edx
f01002c7:	ec                   	in     (%dx),%al
f01002c8:	ec                   	in     (%dx),%al
f01002c9:	ec                   	in     (%dx),%al
f01002ca:	ec                   	in     (%dx),%al
f01002cb:	89 f2                	mov    %esi,%edx
f01002cd:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002ce:	a8 20                	test   $0x20,%al
f01002d0:	75 05                	jne    f01002d7 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002d2:	83 eb 01             	sub    $0x1,%ebx
f01002d5:	75 ee                	jne    f01002c5 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01002d7:	89 f8                	mov    %edi,%eax
f01002d9:	0f b6 c0             	movzbl %al,%eax
f01002dc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002df:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002e4:	ee                   	out    %al,(%dx)
f01002e5:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002ea:	be 79 03 00 00       	mov    $0x379,%esi
f01002ef:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002f4:	eb 06                	jmp    f01002fc <cons_putc+0x53>
f01002f6:	89 ca                	mov    %ecx,%edx
f01002f8:	ec                   	in     (%dx),%al
f01002f9:	ec                   	in     (%dx),%al
f01002fa:	ec                   	in     (%dx),%al
f01002fb:	ec                   	in     (%dx),%al
f01002fc:	89 f2                	mov    %esi,%edx
f01002fe:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002ff:	84 c0                	test   %al,%al
f0100301:	78 05                	js     f0100308 <cons_putc+0x5f>
f0100303:	83 eb 01             	sub    $0x1,%ebx
f0100306:	75 ee                	jne    f01002f6 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100308:	ba 78 03 00 00       	mov    $0x378,%edx
f010030d:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100311:	ee                   	out    %al,(%dx)
f0100312:	b2 7a                	mov    $0x7a,%dl
f0100314:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100319:	ee                   	out    %al,(%dx)
f010031a:	b8 08 00 00 00       	mov    $0x8,%eax
f010031f:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100320:	89 fa                	mov    %edi,%edx
f0100322:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100328:	89 f8                	mov    %edi,%eax
f010032a:	80 cc 07             	or     $0x7,%ah
f010032d:	85 d2                	test   %edx,%edx
f010032f:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100332:	89 f8                	mov    %edi,%eax
f0100334:	0f b6 c0             	movzbl %al,%eax
f0100337:	83 f8 09             	cmp    $0x9,%eax
f010033a:	74 76                	je     f01003b2 <cons_putc+0x109>
f010033c:	83 f8 09             	cmp    $0x9,%eax
f010033f:	7f 0a                	jg     f010034b <cons_putc+0xa2>
f0100341:	83 f8 08             	cmp    $0x8,%eax
f0100344:	74 16                	je     f010035c <cons_putc+0xb3>
f0100346:	e9 9b 00 00 00       	jmp    f01003e6 <cons_putc+0x13d>
f010034b:	83 f8 0a             	cmp    $0xa,%eax
f010034e:	66 90                	xchg   %ax,%ax
f0100350:	74 3a                	je     f010038c <cons_putc+0xe3>
f0100352:	83 f8 0d             	cmp    $0xd,%eax
f0100355:	74 3d                	je     f0100394 <cons_putc+0xeb>
f0100357:	e9 8a 00 00 00       	jmp    f01003e6 <cons_putc+0x13d>
	case '\b':
		if (crt_pos > 0) {
f010035c:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f0100363:	66 85 c0             	test   %ax,%ax
f0100366:	0f 84 e5 00 00 00    	je     f0100451 <cons_putc+0x1a8>
			crt_pos--;
f010036c:	83 e8 01             	sub    $0x1,%eax
f010036f:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100375:	0f b7 c0             	movzwl %ax,%eax
f0100378:	66 81 e7 00 ff       	and    $0xff00,%di
f010037d:	83 cf 20             	or     $0x20,%edi
f0100380:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100386:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010038a:	eb 78                	jmp    f0100404 <cons_putc+0x15b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010038c:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f0100393:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100394:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f010039b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003a1:	c1 e8 16             	shr    $0x16,%eax
f01003a4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003a7:	c1 e0 04             	shl    $0x4,%eax
f01003aa:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
f01003b0:	eb 52                	jmp    f0100404 <cons_putc+0x15b>
		break;
	case '\t':
		cons_putc(' ');
f01003b2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b7:	e8 ed fe ff ff       	call   f01002a9 <cons_putc>
		cons_putc(' ');
f01003bc:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c1:	e8 e3 fe ff ff       	call   f01002a9 <cons_putc>
		cons_putc(' ');
f01003c6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003cb:	e8 d9 fe ff ff       	call   f01002a9 <cons_putc>
		cons_putc(' ');
f01003d0:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d5:	e8 cf fe ff ff       	call   f01002a9 <cons_putc>
		cons_putc(' ');
f01003da:	b8 20 00 00 00       	mov    $0x20,%eax
f01003df:	e8 c5 fe ff ff       	call   f01002a9 <cons_putc>
f01003e4:	eb 1e                	jmp    f0100404 <cons_putc+0x15b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003e6:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003ed:	8d 50 01             	lea    0x1(%eax),%edx
f01003f0:	66 89 15 28 75 11 f0 	mov    %dx,0xf0117528
f01003f7:	0f b7 c0             	movzwl %ax,%eax
f01003fa:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100400:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100404:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f010040b:	cf 07 
f010040d:	76 42                	jbe    f0100451 <cons_putc+0x1a8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010040f:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f0100414:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010041b:	00 
f010041c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100422:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100426:	89 04 24             	mov    %eax,(%esp)
f0100429:	e8 b6 36 00 00       	call   f0103ae4 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010042e:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100434:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100439:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010043f:	83 c0 01             	add    $0x1,%eax
f0100442:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100447:	75 f0                	jne    f0100439 <cons_putc+0x190>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100449:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f0100450:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100451:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100457:	b8 0e 00 00 00       	mov    $0xe,%eax
f010045c:	89 ca                	mov    %ecx,%edx
f010045e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010045f:	0f b7 1d 28 75 11 f0 	movzwl 0xf0117528,%ebx
f0100466:	8d 71 01             	lea    0x1(%ecx),%esi
f0100469:	89 d8                	mov    %ebx,%eax
f010046b:	66 c1 e8 08          	shr    $0x8,%ax
f010046f:	89 f2                	mov    %esi,%edx
f0100471:	ee                   	out    %al,(%dx)
f0100472:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100477:	89 ca                	mov    %ecx,%edx
f0100479:	ee                   	out    %al,(%dx)
f010047a:	89 d8                	mov    %ebx,%eax
f010047c:	89 f2                	mov    %esi,%edx
f010047e:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010047f:	83 c4 1c             	add    $0x1c,%esp
f0100482:	5b                   	pop    %ebx
f0100483:	5e                   	pop    %esi
f0100484:	5f                   	pop    %edi
f0100485:	5d                   	pop    %ebp
f0100486:	c3                   	ret    

f0100487 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100487:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
f010048e:	74 11                	je     f01004a1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100490:	55                   	push   %ebp
f0100491:	89 e5                	mov    %esp,%ebp
f0100493:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100496:	b8 40 01 10 f0       	mov    $0xf0100140,%eax
f010049b:	e8 bc fc ff ff       	call   f010015c <cons_intr>
}
f01004a0:	c9                   	leave  
f01004a1:	f3 c3                	repz ret 

f01004a3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004a3:	55                   	push   %ebp
f01004a4:	89 e5                	mov    %esp,%ebp
f01004a6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a9:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f01004ae:	e8 a9 fc ff ff       	call   f010015c <cons_intr>
}
f01004b3:	c9                   	leave  
f01004b4:	c3                   	ret    

f01004b5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004b5:	55                   	push   %ebp
f01004b6:	89 e5                	mov    %esp,%ebp
f01004b8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004bb:	e8 c7 ff ff ff       	call   f0100487 <serial_intr>
	kbd_intr();
f01004c0:	e8 de ff ff ff       	call   f01004a3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004c5:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f01004ca:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01004d0:	74 26                	je     f01004f8 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004d2:	8d 50 01             	lea    0x1(%eax),%edx
f01004d5:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f01004db:	0f b6 88 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004e2:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004e4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004ea:	75 11                	jne    f01004fd <cons_getc+0x48>
			cons.rpos = 0;
f01004ec:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
f01004f3:	00 00 00 
f01004f6:	eb 05                	jmp    f01004fd <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004fd:	c9                   	leave  
f01004fe:	c3                   	ret    

f01004ff <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004ff:	55                   	push   %ebp
f0100500:	89 e5                	mov    %esp,%ebp
f0100502:	57                   	push   %edi
f0100503:	56                   	push   %esi
f0100504:	53                   	push   %ebx
f0100505:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100508:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010050f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100516:	5a a5 
	if (*cp != 0xA55A) {
f0100518:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010051f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100523:	74 11                	je     f0100536 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100525:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
f010052c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010052f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100534:	eb 16                	jmp    f010054c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100536:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010053d:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
f0100544:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100547:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010054c:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100552:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100557:	89 ca                	mov    %ecx,%edx
f0100559:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010055a:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010055d:	89 da                	mov    %ebx,%edx
f010055f:	ec                   	in     (%dx),%al
f0100560:	0f b6 f0             	movzbl %al,%esi
f0100563:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100566:	b8 0f 00 00 00       	mov    $0xf,%eax
f010056b:	89 ca                	mov    %ecx,%edx
f010056d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056e:	89 da                	mov    %ebx,%edx
f0100570:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100571:	89 3d 2c 75 11 f0    	mov    %edi,0xf011752c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100577:	0f b6 d8             	movzbl %al,%ebx
f010057a:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f010057c:	66 89 35 28 75 11 f0 	mov    %si,0xf0117528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100583:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100588:	b8 00 00 00 00       	mov    $0x0,%eax
f010058d:	89 f2                	mov    %esi,%edx
f010058f:	ee                   	out    %al,(%dx)
f0100590:	b2 fb                	mov    $0xfb,%dl
f0100592:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100597:	ee                   	out    %al,(%dx)
f0100598:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010059d:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005a2:	89 da                	mov    %ebx,%edx
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
f01005cd:	88 0d 34 75 11 f0    	mov    %cl,0xf0117534
f01005d3:	89 f2                	mov    %esi,%edx
f01005d5:	ec                   	in     (%dx),%al
f01005d6:	89 da                	mov    %ebx,%edx
f01005d8:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005d9:	84 c9                	test   %cl,%cl
f01005db:	75 0c                	jne    f01005e9 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f01005dd:	c7 04 24 99 3f 10 f0 	movl   $0xf0103f99,(%esp)
f01005e4:	e8 49 29 00 00       	call   f0102f32 <cprintf>
}
f01005e9:	83 c4 1c             	add    $0x1c,%esp
f01005ec:	5b                   	pop    %ebx
f01005ed:	5e                   	pop    %esi
f01005ee:	5f                   	pop    %edi
f01005ef:	5d                   	pop    %ebp
f01005f0:	c3                   	ret    

f01005f1 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005f1:	55                   	push   %ebp
f01005f2:	89 e5                	mov    %esp,%ebp
f01005f4:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005f7:	8b 45 08             	mov    0x8(%ebp),%eax
f01005fa:	e8 aa fc ff ff       	call   f01002a9 <cons_putc>
}
f01005ff:	c9                   	leave  
f0100600:	c3                   	ret    

f0100601 <getchar>:

int
getchar(void)
{
f0100601:	55                   	push   %ebp
f0100602:	89 e5                	mov    %esp,%ebp
f0100604:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100607:	e8 a9 fe ff ff       	call   f01004b5 <cons_getc>
f010060c:	85 c0                	test   %eax,%eax
f010060e:	74 f7                	je     f0100607 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100610:	c9                   	leave  
f0100611:	c3                   	ret    

f0100612 <iscons>:

int
iscons(int fdnum)
{
f0100612:	55                   	push   %ebp
f0100613:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100615:	b8 01 00 00 00       	mov    $0x1,%eax
f010061a:	5d                   	pop    %ebp
f010061b:	c3                   	ret    
f010061c:	66 90                	xchg   %ax,%ax
f010061e:	66 90                	xchg   %ax,%ax

f0100620 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100620:	55                   	push   %ebp
f0100621:	89 e5                	mov    %esp,%ebp
f0100623:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100626:	c7 44 24 08 e0 41 10 	movl   $0xf01041e0,0x8(%esp)
f010062d:	f0 
f010062e:	c7 44 24 04 fe 41 10 	movl   $0xf01041fe,0x4(%esp)
f0100635:	f0 
f0100636:	c7 04 24 03 42 10 f0 	movl   $0xf0104203,(%esp)
f010063d:	e8 f0 28 00 00       	call   f0102f32 <cprintf>
f0100642:	c7 44 24 08 a4 42 10 	movl   $0xf01042a4,0x8(%esp)
f0100649:	f0 
f010064a:	c7 44 24 04 0c 42 10 	movl   $0xf010420c,0x4(%esp)
f0100651:	f0 
f0100652:	c7 04 24 03 42 10 f0 	movl   $0xf0104203,(%esp)
f0100659:	e8 d4 28 00 00       	call   f0102f32 <cprintf>
f010065e:	c7 44 24 08 15 42 10 	movl   $0xf0104215,0x8(%esp)
f0100665:	f0 
f0100666:	c7 44 24 04 32 42 10 	movl   $0xf0104232,0x4(%esp)
f010066d:	f0 
f010066e:	c7 04 24 03 42 10 f0 	movl   $0xf0104203,(%esp)
f0100675:	e8 b8 28 00 00       	call   f0102f32 <cprintf>
	return 0;
}
f010067a:	b8 00 00 00 00       	mov    $0x0,%eax
f010067f:	c9                   	leave  
f0100680:	c3                   	ret    

f0100681 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100681:	55                   	push   %ebp
f0100682:	89 e5                	mov    %esp,%ebp
f0100684:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100687:	c7 04 24 3d 42 10 f0 	movl   $0xf010423d,(%esp)
f010068e:	e8 9f 28 00 00       	call   f0102f32 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100693:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010069a:	00 
f010069b:	c7 04 24 cc 42 10 f0 	movl   $0xf01042cc,(%esp)
f01006a2:	e8 8b 28 00 00       	call   f0102f32 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006a7:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006ae:	00 
f01006af:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006b6:	f0 
f01006b7:	c7 04 24 f4 42 10 f0 	movl   $0xf01042f4,(%esp)
f01006be:	e8 6f 28 00 00       	call   f0102f32 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006c3:	c7 44 24 08 27 3f 10 	movl   $0x103f27,0x8(%esp)
f01006ca:	00 
f01006cb:	c7 44 24 04 27 3f 10 	movl   $0xf0103f27,0x4(%esp)
f01006d2:	f0 
f01006d3:	c7 04 24 18 43 10 f0 	movl   $0xf0104318,(%esp)
f01006da:	e8 53 28 00 00       	call   f0102f32 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006df:	c7 44 24 08 00 73 11 	movl   $0x117300,0x8(%esp)
f01006e6:	00 
f01006e7:	c7 44 24 04 00 73 11 	movl   $0xf0117300,0x4(%esp)
f01006ee:	f0 
f01006ef:	c7 04 24 3c 43 10 f0 	movl   $0xf010433c,(%esp)
f01006f6:	e8 37 28 00 00       	call   f0102f32 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006fb:	c7 44 24 08 70 79 11 	movl   $0x117970,0x8(%esp)
f0100702:	00 
f0100703:	c7 44 24 04 70 79 11 	movl   $0xf0117970,0x4(%esp)
f010070a:	f0 
f010070b:	c7 04 24 60 43 10 f0 	movl   $0xf0104360,(%esp)
f0100712:	e8 1b 28 00 00       	call   f0102f32 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100717:	b8 6f 7d 11 f0       	mov    $0xf0117d6f,%eax
f010071c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100721:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100726:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010072c:	85 c0                	test   %eax,%eax
f010072e:	0f 48 c2             	cmovs  %edx,%eax
f0100731:	c1 f8 0a             	sar    $0xa,%eax
f0100734:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100738:	c7 04 24 84 43 10 f0 	movl   $0xf0104384,(%esp)
f010073f:	e8 ee 27 00 00       	call   f0102f32 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100744:	b8 00 00 00 00       	mov    $0x0,%eax
f0100749:	c9                   	leave  
f010074a:	c3                   	ret    

f010074b <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010074b:	55                   	push   %ebp
f010074c:	89 e5                	mov    %esp,%ebp
f010074e:	57                   	push   %edi
f010074f:	56                   	push   %esi
f0100750:	53                   	push   %ebx
f0100751:	83 ec 6c             	sub    $0x6c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100754:	89 eb                	mov    %ebp,%ebx
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
f0100756:	c7 04 24 56 42 10 f0 	movl   $0xf0104256,(%esp)
f010075d:	e8 d0 27 00 00       	call   f0102f32 <cprintf>
	
	while (ebp){
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
		debuginfo_eip(eip, &sym);
f0100762:	8d 7d d0             	lea    -0x30(%ebp),%edi
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f0100765:	eb 6d                	jmp    f01007d4 <mon_backtrace+0x89>
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
f0100767:	8b 73 04             	mov    0x4(%ebx),%esi
		debuginfo_eip(eip, &sym);
f010076a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010076e:	89 34 24             	mov    %esi,(%esp)
f0100771:	e8 b3 28 00 00       	call   f0103029 <debuginfo_eip>
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n %s:%d: %.*s+%d\n",ebp,eip,
f0100776:	89 f0                	mov    %esi,%eax
f0100778:	2b 45 e0             	sub    -0x20(%ebp),%eax
f010077b:	89 44 24 30          	mov    %eax,0x30(%esp)
f010077f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100782:	89 44 24 2c          	mov    %eax,0x2c(%esp)
f0100786:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100789:	89 44 24 28          	mov    %eax,0x28(%esp)
f010078d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100790:	89 44 24 24          	mov    %eax,0x24(%esp)
f0100794:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100797:	89 44 24 20          	mov    %eax,0x20(%esp)
f010079b:	8b 43 18             	mov    0x18(%ebx),%eax
f010079e:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f01007a2:	8b 43 14             	mov    0x14(%ebx),%eax
f01007a5:	89 44 24 18          	mov    %eax,0x18(%esp)
f01007a9:	8b 43 10             	mov    0x10(%ebx),%eax
f01007ac:	89 44 24 14          	mov    %eax,0x14(%esp)
f01007b0:	8b 43 0c             	mov    0xc(%ebx),%eax
f01007b3:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007b7:	8b 43 08             	mov    0x8(%ebx),%eax
f01007ba:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007be:	89 74 24 08          	mov    %esi,0x8(%esp)
f01007c2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01007c6:	c7 04 24 b0 43 10 f0 	movl   $0xf01043b0,(%esp)
f01007cd:	e8 60 27 00 00       	call   f0102f32 <cprintf>
		*((uint32_t *)ebp + 6), sym.eip_file,
			      sym.eip_line,
			      sym.eip_fn_namelen,
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
f01007d2:	8b 1b                	mov    (%ebx),%ebx
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f01007d4:	85 db                	test   %ebx,%ebx
f01007d6:	75 8f                	jne    f0100767 <mon_backtrace+0x1c>
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
	}
	return 0;
}
f01007d8:	b8 00 00 00 00       	mov    $0x0,%eax
f01007dd:	83 c4 6c             	add    $0x6c,%esp
f01007e0:	5b                   	pop    %ebx
f01007e1:	5e                   	pop    %esi
f01007e2:	5f                   	pop    %edi
f01007e3:	5d                   	pop    %ebp
f01007e4:	c3                   	ret    

f01007e5 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007e5:	55                   	push   %ebp
f01007e6:	89 e5                	mov    %esp,%ebp
f01007e8:	57                   	push   %edi
f01007e9:	56                   	push   %esi
f01007ea:	53                   	push   %ebx
f01007eb:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007ee:	c7 04 24 f4 43 10 f0 	movl   $0xf01043f4,(%esp)
f01007f5:	e8 38 27 00 00       	call   f0102f32 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007fa:	c7 04 24 18 44 10 f0 	movl   $0xf0104418,(%esp)
f0100801:	e8 2c 27 00 00       	call   f0102f32 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100806:	c7 04 24 68 42 10 f0 	movl   $0xf0104268,(%esp)
f010080d:	e8 2e 30 00 00       	call   f0103840 <readline>
f0100812:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100814:	85 c0                	test   %eax,%eax
f0100816:	74 ee                	je     f0100806 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100818:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010081f:	be 00 00 00 00       	mov    $0x0,%esi
f0100824:	eb 0a                	jmp    f0100830 <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100826:	c6 03 00             	movb   $0x0,(%ebx)
f0100829:	89 f7                	mov    %esi,%edi
f010082b:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010082e:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100830:	0f b6 03             	movzbl (%ebx),%eax
f0100833:	84 c0                	test   %al,%al
f0100835:	74 63                	je     f010089a <monitor+0xb5>
f0100837:	0f be c0             	movsbl %al,%eax
f010083a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010083e:	c7 04 24 6c 42 10 f0 	movl   $0xf010426c,(%esp)
f0100845:	e8 10 32 00 00       	call   f0103a5a <strchr>
f010084a:	85 c0                	test   %eax,%eax
f010084c:	75 d8                	jne    f0100826 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f010084e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100851:	74 47                	je     f010089a <monitor+0xb5>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100853:	83 fe 0f             	cmp    $0xf,%esi
f0100856:	75 16                	jne    f010086e <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100858:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f010085f:	00 
f0100860:	c7 04 24 71 42 10 f0 	movl   $0xf0104271,(%esp)
f0100867:	e8 c6 26 00 00       	call   f0102f32 <cprintf>
f010086c:	eb 98                	jmp    f0100806 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f010086e:	8d 7e 01             	lea    0x1(%esi),%edi
f0100871:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100875:	eb 03                	jmp    f010087a <monitor+0x95>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100877:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010087a:	0f b6 03             	movzbl (%ebx),%eax
f010087d:	84 c0                	test   %al,%al
f010087f:	74 ad                	je     f010082e <monitor+0x49>
f0100881:	0f be c0             	movsbl %al,%eax
f0100884:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100888:	c7 04 24 6c 42 10 f0 	movl   $0xf010426c,(%esp)
f010088f:	e8 c6 31 00 00       	call   f0103a5a <strchr>
f0100894:	85 c0                	test   %eax,%eax
f0100896:	74 df                	je     f0100877 <monitor+0x92>
f0100898:	eb 94                	jmp    f010082e <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f010089a:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008a1:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008a2:	85 f6                	test   %esi,%esi
f01008a4:	0f 84 5c ff ff ff    	je     f0100806 <monitor+0x21>
f01008aa:	bb 00 00 00 00       	mov    $0x0,%ebx
f01008af:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008b2:	8b 04 85 40 44 10 f0 	mov    -0xfefbbc0(,%eax,4),%eax
f01008b9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008bd:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008c0:	89 04 24             	mov    %eax,(%esp)
f01008c3:	e8 34 31 00 00       	call   f01039fc <strcmp>
f01008c8:	85 c0                	test   %eax,%eax
f01008ca:	75 24                	jne    f01008f0 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f01008cc:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008cf:	8b 55 08             	mov    0x8(%ebp),%edx
f01008d2:	89 54 24 08          	mov    %edx,0x8(%esp)
f01008d6:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f01008d9:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01008dd:	89 34 24             	mov    %esi,(%esp)
f01008e0:	ff 14 85 48 44 10 f0 	call   *-0xfefbbb8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008e7:	85 c0                	test   %eax,%eax
f01008e9:	78 25                	js     f0100910 <monitor+0x12b>
f01008eb:	e9 16 ff ff ff       	jmp    f0100806 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008f0:	83 c3 01             	add    $0x1,%ebx
f01008f3:	83 fb 03             	cmp    $0x3,%ebx
f01008f6:	75 b7                	jne    f01008af <monitor+0xca>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008f8:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008fb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008ff:	c7 04 24 8e 42 10 f0 	movl   $0xf010428e,(%esp)
f0100906:	e8 27 26 00 00       	call   f0102f32 <cprintf>
f010090b:	e9 f6 fe ff ff       	jmp    f0100806 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100910:	83 c4 5c             	add    $0x5c,%esp
f0100913:	5b                   	pop    %ebx
f0100914:	5e                   	pop    %esi
f0100915:	5f                   	pop    %edi
f0100916:	5d                   	pop    %ebp
f0100917:	c3                   	ret    
f0100918:	66 90                	xchg   %ax,%ax
f010091a:	66 90                	xchg   %ax,%ax
f010091c:	66 90                	xchg   %ax,%ax
f010091e:	66 90                	xchg   %ax,%ax

f0100920 <page2kva>:
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100920:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100926:	c1 f8 03             	sar    $0x3,%eax
f0100929:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010092c:	89 c2                	mov    %eax,%edx
f010092e:	c1 ea 0c             	shr    $0xc,%edx
f0100931:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100937:	72 26                	jb     f010095f <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100939:	55                   	push   %ebp
f010093a:	89 e5                	mov    %esp,%ebp
f010093c:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010093f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100943:	c7 44 24 08 64 44 10 	movl   $0xf0104464,0x8(%esp)
f010094a:	f0 
f010094b:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100952:	00 
f0100953:	c7 04 24 d0 4c 10 f0 	movl   $0xf0104cd0,(%esp)
f010095a:	e8 35 f7 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f010095f:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));
}
f0100964:	c3                   	ret    

f0100965 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100965:	89 d1                	mov    %edx,%ecx
f0100967:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f010096a:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f010096d:	a8 01                	test   $0x1,%al
f010096f:	74 5d                	je     f01009ce <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100971:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100976:	89 c1                	mov    %eax,%ecx
f0100978:	c1 e9 0c             	shr    $0xc,%ecx
f010097b:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0100981:	72 26                	jb     f01009a9 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100983:	55                   	push   %ebp
f0100984:	89 e5                	mov    %esp,%ebp
f0100986:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100989:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010098d:	c7 44 24 08 64 44 10 	movl   $0xf0104464,0x8(%esp)
f0100994:	f0 
f0100995:	c7 44 24 04 36 03 00 	movl   $0x336,0x4(%esp)
f010099c:	00 
f010099d:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01009a4:	e8 eb f6 ff ff       	call   f0100094 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f01009a9:	c1 ea 0c             	shr    $0xc,%edx
f01009ac:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009b2:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01009b9:	89 c2                	mov    %eax,%edx
f01009bb:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009be:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009c3:	85 d2                	test   %edx,%edx
f01009c5:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009ca:	0f 44 c2             	cmove  %edx,%eax
f01009cd:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009ce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009d3:	c3                   	ret    

f01009d4 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01009d4:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f01009db:	75 11                	jne    f01009ee <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE); // Roundup function rounds according to the given functions
f01009dd:	ba 6f 89 11 f0       	mov    $0xf011896f,%edx
f01009e2:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009e8:	89 15 3c 75 11 f0    	mov    %edx,0xf011753c
	}
	
	if (n==0){
f01009ee:	85 c0                	test   %eax,%eax
f01009f0:	75 06                	jne    f01009f8 <boot_alloc+0x24>
	return nextfree;
f01009f2:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01009f7:	c3                   	ret    
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result  = nextfree;
f01009f8:	8b 0d 3c 75 11 f0    	mov    0xf011753c,%ecx
	nextfree += ROUNDUP(n,PGSIZE);
f01009fe:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100a04:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a0a:	01 ca                	add    %ecx,%edx
f0100a0c:	89 15 3c 75 11 f0    	mov    %edx,0xf011753c
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100a12:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0100a18:	77 26                	ja     f0100a40 <boot_alloc+0x6c>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100a1a:	55                   	push   %ebp
f0100a1b:	89 e5                	mov    %esp,%ebp
f0100a1d:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100a20:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100a24:	c7 44 24 08 88 44 10 	movl   $0xf0104488,0x8(%esp)
f0100a2b:	f0 
f0100a2c:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
f0100a33:	00 
f0100a34:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0100a3b:	e8 54 f6 ff ff       	call   f0100094 <_panic>
	// LAB 2: Your code here.
	result  = nextfree;
	nextfree += ROUNDUP(n,PGSIZE);
	
	
	if ((PADDR(nextfree))>npages*PGSIZE){
f0100a40:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0100a45:	c1 e0 0c             	shl    $0xc,%eax
	return (physaddr_t)kva - KERNBASE;
f0100a48:	81 c2 00 00 00 10    	add    $0x10000000,%edx
		return 0;
f0100a4e:	39 c2                	cmp    %eax,%edx
f0100a50:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a55:	0f 46 c1             	cmovbe %ecx,%eax
	}
	return result;
}
f0100a58:	c3                   	ret    

f0100a59 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a59:	55                   	push   %ebp
f0100a5a:	89 e5                	mov    %esp,%ebp
f0100a5c:	57                   	push   %edi
f0100a5d:	56                   	push   %esi
f0100a5e:	53                   	push   %ebx
f0100a5f:	83 ec 4c             	sub    $0x4c,%esp
f0100a62:	89 45 c0             	mov    %eax,-0x40(%ebp)
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a65:	84 c0                	test   %al,%al
f0100a67:	0f 85 1d 03 00 00    	jne    f0100d8a <check_page_free_list+0x331>
f0100a6d:	e9 2a 03 00 00       	jmp    f0100d9c <check_page_free_list+0x343>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100a72:	c7 44 24 08 ac 44 10 	movl   $0xf01044ac,0x8(%esp)
f0100a79:	f0 
f0100a7a:	c7 44 24 04 78 02 00 	movl   $0x278,0x4(%esp)
f0100a81:	00 
f0100a82:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0100a89:	e8 06 f6 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a8e:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100a91:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a94:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a97:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a9a:	89 c2                	mov    %eax,%edx
f0100a9c:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100aa2:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100aa8:	0f 95 c2             	setne  %dl
f0100aab:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100aae:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100ab2:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100ab4:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ab8:	8b 00                	mov    (%eax),%eax
f0100aba:	85 c0                	test   %eax,%eax
f0100abc:	75 dc                	jne    f0100a9a <check_page_free_list+0x41>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100abe:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ac1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100ac7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100aca:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100acd:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100acf:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ad2:	a3 40 75 11 f0       	mov    %eax,0xf0117540
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ad7:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100adc:	8b 1d 40 75 11 f0    	mov    0xf0117540,%ebx
f0100ae2:	eb 63                	jmp    f0100b47 <check_page_free_list+0xee>
f0100ae4:	89 d8                	mov    %ebx,%eax
f0100ae6:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100aec:	c1 f8 03             	sar    $0x3,%eax
f0100aef:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100af2:	89 c2                	mov    %eax,%edx
f0100af4:	c1 ea 16             	shr    $0x16,%edx
f0100af7:	39 f2                	cmp    %esi,%edx
f0100af9:	73 4a                	jae    f0100b45 <check_page_free_list+0xec>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100afb:	89 c2                	mov    %eax,%edx
f0100afd:	c1 ea 0c             	shr    $0xc,%edx
f0100b00:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100b06:	72 20                	jb     f0100b28 <check_page_free_list+0xcf>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b08:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b0c:	c7 44 24 08 64 44 10 	movl   $0xf0104464,0x8(%esp)
f0100b13:	f0 
f0100b14:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100b1b:	00 
f0100b1c:	c7 04 24 d0 4c 10 f0 	movl   $0xf0104cd0,(%esp)
f0100b23:	e8 6c f5 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b28:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b2f:	00 
f0100b30:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b37:	00 
	return (void *)(pa + KERNBASE);
f0100b38:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b3d:	89 04 24             	mov    %eax,(%esp)
f0100b40:	e8 52 2f 00 00       	call   f0103a97 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b45:	8b 1b                	mov    (%ebx),%ebx
f0100b47:	85 db                	test   %ebx,%ebx
f0100b49:	75 99                	jne    f0100ae4 <check_page_free_list+0x8b>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b4b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b50:	e8 7f fe ff ff       	call   f01009d4 <boot_alloc>
f0100b55:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b58:	8b 15 40 75 11 f0    	mov    0xf0117540,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b5e:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
		assert(pp < pages + npages);
f0100b64:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0100b69:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100b6c:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100b6f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b72:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b75:	bf 00 00 00 00       	mov    $0x0,%edi
f0100b7a:	89 5d cc             	mov    %ebx,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b7d:	e9 97 01 00 00       	jmp    f0100d19 <check_page_free_list+0x2c0>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b82:	39 ca                	cmp    %ecx,%edx
f0100b84:	73 24                	jae    f0100baa <check_page_free_list+0x151>
f0100b86:	c7 44 24 0c ea 4c 10 	movl   $0xf0104cea,0xc(%esp)
f0100b8d:	f0 
f0100b8e:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0100b95:	f0 
f0100b96:	c7 44 24 04 92 02 00 	movl   $0x292,0x4(%esp)
f0100b9d:	00 
f0100b9e:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0100ba5:	e8 ea f4 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100baa:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bad:	72 24                	jb     f0100bd3 <check_page_free_list+0x17a>
f0100baf:	c7 44 24 0c 0b 4d 10 	movl   $0xf0104d0b,0xc(%esp)
f0100bb6:	f0 
f0100bb7:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0100bbe:	f0 
f0100bbf:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
f0100bc6:	00 
f0100bc7:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0100bce:	e8 c1 f4 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bd3:	89 d0                	mov    %edx,%eax
f0100bd5:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100bd8:	a8 07                	test   $0x7,%al
f0100bda:	74 24                	je     f0100c00 <check_page_free_list+0x1a7>
f0100bdc:	c7 44 24 0c d0 44 10 	movl   $0xf01044d0,0xc(%esp)
f0100be3:	f0 
f0100be4:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0100beb:	f0 
f0100bec:	c7 44 24 04 94 02 00 	movl   $0x294,0x4(%esp)
f0100bf3:	00 
f0100bf4:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0100bfb:	e8 94 f4 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c00:	c1 f8 03             	sar    $0x3,%eax
f0100c03:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c06:	85 c0                	test   %eax,%eax
f0100c08:	75 24                	jne    f0100c2e <check_page_free_list+0x1d5>
f0100c0a:	c7 44 24 0c 1f 4d 10 	movl   $0xf0104d1f,0xc(%esp)
f0100c11:	f0 
f0100c12:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0100c19:	f0 
f0100c1a:	c7 44 24 04 97 02 00 	movl   $0x297,0x4(%esp)
f0100c21:	00 
f0100c22:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0100c29:	e8 66 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c2e:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c33:	75 24                	jne    f0100c59 <check_page_free_list+0x200>
f0100c35:	c7 44 24 0c 30 4d 10 	movl   $0xf0104d30,0xc(%esp)
f0100c3c:	f0 
f0100c3d:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0100c44:	f0 
f0100c45:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f0100c4c:	00 
f0100c4d:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0100c54:	e8 3b f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c59:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c5e:	75 24                	jne    f0100c84 <check_page_free_list+0x22b>
f0100c60:	c7 44 24 0c 04 45 10 	movl   $0xf0104504,0xc(%esp)
f0100c67:	f0 
f0100c68:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0100c6f:	f0 
f0100c70:	c7 44 24 04 99 02 00 	movl   $0x299,0x4(%esp)
f0100c77:	00 
f0100c78:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0100c7f:	e8 10 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c84:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c89:	75 24                	jne    f0100caf <check_page_free_list+0x256>
f0100c8b:	c7 44 24 0c 49 4d 10 	movl   $0xf0104d49,0xc(%esp)
f0100c92:	f0 
f0100c93:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0100c9a:	f0 
f0100c9b:	c7 44 24 04 9a 02 00 	movl   $0x29a,0x4(%esp)
f0100ca2:	00 
f0100ca3:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0100caa:	e8 e5 f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100caf:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100cb4:	76 58                	jbe    f0100d0e <check_page_free_list+0x2b5>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cb6:	89 c3                	mov    %eax,%ebx
f0100cb8:	c1 eb 0c             	shr    $0xc,%ebx
f0100cbb:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f0100cbe:	77 20                	ja     f0100ce0 <check_page_free_list+0x287>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cc0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100cc4:	c7 44 24 08 64 44 10 	movl   $0xf0104464,0x8(%esp)
f0100ccb:	f0 
f0100ccc:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100cd3:	00 
f0100cd4:	c7 04 24 d0 4c 10 f0 	movl   $0xf0104cd0,(%esp)
f0100cdb:	e8 b4 f3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100ce0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ce5:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100ce8:	76 2a                	jbe    f0100d14 <check_page_free_list+0x2bb>
f0100cea:	c7 44 24 0c 28 45 10 	movl   $0xf0104528,0xc(%esp)
f0100cf1:	f0 
f0100cf2:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0100cf9:	f0 
f0100cfa:	c7 44 24 04 9b 02 00 	movl   $0x29b,0x4(%esp)
f0100d01:	00 
f0100d02:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0100d09:	e8 86 f3 ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d0e:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0100d12:	eb 03                	jmp    f0100d17 <check_page_free_list+0x2be>
		else
			++nfree_extmem;
f0100d14:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d17:	8b 12                	mov    (%edx),%edx
f0100d19:	85 d2                	test   %edx,%edx
f0100d1b:	0f 85 61 fe ff ff    	jne    f0100b82 <check_page_free_list+0x129>
f0100d21:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d24:	85 db                	test   %ebx,%ebx
f0100d26:	7f 24                	jg     f0100d4c <check_page_free_list+0x2f3>
f0100d28:	c7 44 24 0c 63 4d 10 	movl   $0xf0104d63,0xc(%esp)
f0100d2f:	f0 
f0100d30:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0100d37:	f0 
f0100d38:	c7 44 24 04 a3 02 00 	movl   $0x2a3,0x4(%esp)
f0100d3f:	00 
f0100d40:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0100d47:	e8 48 f3 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100d4c:	85 ff                	test   %edi,%edi
f0100d4e:	7f 24                	jg     f0100d74 <check_page_free_list+0x31b>
f0100d50:	c7 44 24 0c 75 4d 10 	movl   $0xf0104d75,0xc(%esp)
f0100d57:	f0 
f0100d58:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0100d5f:	f0 
f0100d60:	c7 44 24 04 a4 02 00 	movl   $0x2a4,0x4(%esp)
f0100d67:	00 
f0100d68:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0100d6f:	e8 20 f3 ff ff       	call   f0100094 <_panic>
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
f0100d74:	0f b6 45 c0          	movzbl -0x40(%ebp),%eax
f0100d78:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d7c:	c7 04 24 70 45 10 f0 	movl   $0xf0104570,(%esp)
f0100d83:	e8 aa 21 00 00       	call   f0102f32 <cprintf>
f0100d88:	eb 29                	jmp    f0100db3 <check_page_free_list+0x35a>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100d8a:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f0100d8f:	85 c0                	test   %eax,%eax
f0100d91:	0f 85 f7 fc ff ff    	jne    f0100a8e <check_page_free_list+0x35>
f0100d97:	e9 d6 fc ff ff       	jmp    f0100a72 <check_page_free_list+0x19>
f0100d9c:	83 3d 40 75 11 f0 00 	cmpl   $0x0,0xf0117540
f0100da3:	0f 84 c9 fc ff ff    	je     f0100a72 <check_page_free_list+0x19>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100da9:	be 00 04 00 00       	mov    $0x400,%esi
f0100dae:	e9 29 fd ff ff       	jmp    f0100adc <check_page_free_list+0x83>
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
}
f0100db3:	83 c4 4c             	add    $0x4c,%esp
f0100db6:	5b                   	pop    %ebx
f0100db7:	5e                   	pop    %esi
f0100db8:	5f                   	pop    %edi
f0100db9:	5d                   	pop    %ebp
f0100dba:	c3                   	ret    

f0100dbb <page_init>:
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100dbb:	b8 01 00 00 00       	mov    $0x1,%eax
f0100dc0:	eb 18                	jmp    f0100dda <page_init+0x1f>
	{
	 pages[i].pp_ref = 1; //Used Pages
f0100dc2:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f0100dc8:	8d 14 c2             	lea    (%edx,%eax,8),%edx
f0100dcb:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
	 pages[i].pp_link = 0; // No links to any pages
f0100dd1:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100dd7:	83 c0 01             	add    $0x1,%eax
f0100dda:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0100de0:	72 e0                	jb     f0100dc2 <page_init+0x7>
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100de2:	55                   	push   %ebp
f0100de3:	89 e5                	mov    %esp,%ebp
f0100de5:	57                   	push   %edi
f0100de6:	56                   	push   %esi
f0100de7:	53                   	push   %ebx
f0100de8:	83 ec 1c             	sub    $0x1c,%esp

	
	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	for (i = 1; i < npages_basemem; i++) {
f0100deb:	8b 35 44 75 11 f0    	mov    0xf0117544,%esi
f0100df1:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100df6:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100dfb:	eb 39                	jmp    f0100e36 <page_init+0x7b>
f0100dfd:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
		pages[i].pp_ref = 0;
f0100e04:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f0100e0a:	66 c7 44 02 04 00 00 	movw   $0x0,0x4(%edx,%eax,1)
		pages[i].pp_link = 0;
f0100e11:	c7 04 da 00 00 00 00 	movl   $0x0,(%edx,%ebx,8)

		if (!page_free_list){		
f0100e18:	85 c9                	test   %ecx,%ecx
f0100e1a:	75 0a                	jne    f0100e26 <page_init+0x6b>
		page_free_list = &pages[i];	// if page_free_list is 0 then point to current page
f0100e1c:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100e22:	89 c1                	mov    %eax,%ecx
f0100e24:	eb 0d                	jmp    f0100e33 <page_init+0x78>
		}
		else{
		pages[i-1].pp_link = &pages[i];
f0100e26:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f0100e2c:	8d 3c 02             	lea    (%edx,%eax,1),%edi
f0100e2f:	89 7c 02 f8          	mov    %edi,-0x8(%edx,%eax,1)

	
	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	for (i = 1; i < npages_basemem; i++) {
f0100e33:	83 c3 01             	add    $0x1,%ebx
f0100e36:	39 f3                	cmp    %esi,%ebx
f0100e38:	72 c3                	jb     f0100dfd <page_init+0x42>
f0100e3a:	89 0d 40 75 11 f0    	mov    %ecx,0xf0117540
		}
		else{
		pages[i-1].pp_link = &pages[i];
		}	//Previous page is linked to this current page
	}
	cprintf("After for loop 1 value of i = %d\n", i);
f0100e40:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100e44:	c7 04 24 98 45 10 f0 	movl   $0xf0104598,(%esp)
f0100e4b:	e8 e2 20 00 00       	call   f0102f32 <cprintf>
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
f0100e50:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0100e55:	8d 44 d8 f8          	lea    -0x8(%eax,%ebx,8),%eax
f0100e59:	a3 38 75 11 f0       	mov    %eax,0xf0117538
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100e5e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e63:	e8 6c fb ff ff       	call   f01009d4 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100e68:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100e6d:	77 20                	ja     f0100e8f <page_init+0xd4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100e6f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e73:	c7 44 24 08 88 44 10 	movl   $0xf0104488,0x8(%esp)
f0100e7a:	f0 
f0100e7b:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
f0100e82:	00 
f0100e83:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0100e8a:	e8 05 f2 ff ff       	call   f0100094 <_panic>
f0100e8f:	05 ff 0f 00 10       	add    $0x10000fff,%eax
f0100e94:	c1 e8 0c             	shr    $0xc,%eax
f0100e97:	8b 1d 38 75 11 f0    	mov    0xf0117538,%ebx
f0100e9d:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100ea4:	eb 2c                	jmp    f0100ed2 <page_init+0x117>
		pages[i].pp_ref = 0;
f0100ea6:	89 d1                	mov    %edx,%ecx
f0100ea8:	03 0d 6c 79 11 f0    	add    0xf011796c,%ecx
f0100eae:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = 0;
f0100eb4:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		track->pp_link = &pages[i];
f0100eba:	89 d1                	mov    %edx,%ecx
f0100ebc:	03 0d 6c 79 11 f0    	add    0xf011796c,%ecx
f0100ec2:	89 0b                	mov    %ecx,(%ebx)
		track = &pages[i];
f0100ec4:	89 d3                	mov    %edx,%ebx
f0100ec6:	03 1d 6c 79 11 f0    	add    0xf011796c,%ebx
	}
	cprintf("After for loop 1 value of i = %d\n", i);
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100ecc:	83 c0 01             	add    $0x1,%eax
f0100ecf:	83 c2 08             	add    $0x8,%edx
f0100ed2:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0100ed8:	72 cc                	jb     f0100ea6 <page_init+0xeb>
f0100eda:	89 1d 38 75 11 f0    	mov    %ebx,0xf0117538
		pages[i].pp_link = 0;
		track->pp_link = &pages[i];
		track = &pages[i];
	}
	
	cprintf("Check first entry of pages &pages[0] = %x\n", &pages[0]);
f0100ee0:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0100ee5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ee9:	c7 04 24 bc 45 10 f0 	movl   $0xf01045bc,(%esp)
f0100ef0:	e8 3d 20 00 00       	call   f0102f32 <cprintf>
	cprintf("&pages[npages-1] = %x\n", &pages[npages-1]);
f0100ef5:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0100efa:	8b 15 64 79 11 f0    	mov    0xf0117964,%edx
f0100f00:	8d 44 d0 f8          	lea    -0x8(%eax,%edx,8),%eax
f0100f04:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f08:	c7 04 24 86 4d 10 f0 	movl   $0xf0104d86,(%esp)
f0100f0f:	e8 1e 20 00 00       	call   f0102f32 <cprintf>
}
f0100f14:	83 c4 1c             	add    $0x1c,%esp
f0100f17:	5b                   	pop    %ebx
f0100f18:	5e                   	pop    %esi
f0100f19:	5f                   	pop    %edi
f0100f1a:	5d                   	pop    %ebp
f0100f1b:	c3                   	ret    

f0100f1c <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100f1c:	55                   	push   %ebp
f0100f1d:	89 e5                	mov    %esp,%ebp
f0100f1f:	53                   	push   %ebx
f0100f20:	83 ec 14             	sub    $0x14,%esp
	// Check if there is a free_page available 
	if (!page_free_list)
f0100f23:	8b 1d 40 75 11 f0    	mov    0xf0117540,%ebx
f0100f29:	85 db                	test   %ebx,%ebx
f0100f2b:	74 75                	je     f0100fa2 <page_alloc+0x86>
	return NULL;
	}
	
	struct PageInfo *allocPage = NULL;   //Create a temporary pointer 
	allocPage = page_free_list;	//Point to the current head of free_page_list
	page_free_list = allocPage ->pp_link; //Move the head to the next avaialble page
f0100f2d:	8b 03                	mov    (%ebx),%eax
f0100f2f:	a3 40 75 11 f0       	mov    %eax,0xf0117540
	allocPage->pp_link = NULL;
f0100f34:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags && ALLOC_ZERO){		//ALLOC_ZERO = 1<<0; which is nothing but  = 1
f0100f3a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100f3e:	74 58                	je     f0100f98 <page_alloc+0x7c>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f40:	89 d8                	mov    %ebx,%eax
f0100f42:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100f48:	c1 f8 03             	sar    $0x3,%eax
f0100f4b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f4e:	89 c2                	mov    %eax,%edx
f0100f50:	c1 ea 0c             	shr    $0xc,%edx
f0100f53:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100f59:	72 20                	jb     f0100f7b <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f5b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f5f:	c7 44 24 08 64 44 10 	movl   $0xf0104464,0x8(%esp)
f0100f66:	f0 
f0100f67:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100f6e:	00 
f0100f6f:	c7 04 24 d0 4c 10 f0 	movl   $0xf0104cd0,(%esp)
f0100f76:	e8 19 f1 ff ff       	call   f0100094 <_panic>
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
f0100f7b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100f82:	00 
f0100f83:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100f8a:	00 
	return (void *)(pa + KERNBASE);
f0100f8b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f90:	89 04 24             	mov    %eax,(%esp)
f0100f93:	e8 ff 2a 00 00       	call   f0103a97 <memset>
	}
	
	allocPage->pp_ref = 0;
f0100f98:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return allocPage;
f0100f9e:	89 d8                	mov    %ebx,%eax
f0100fa0:	eb 05                	jmp    f0100fa7 <page_alloc+0x8b>
page_alloc(int alloc_flags)
{
	// Check if there is a free_page available 
	if (!page_free_list)
	{ 
	return NULL;
f0100fa2:	b8 00 00 00 00       	mov    $0x0,%eax
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
	}
	
	allocPage->pp_ref = 0;
	return allocPage;
}
f0100fa7:	83 c4 14             	add    $0x14,%esp
f0100faa:	5b                   	pop    %ebx
f0100fab:	5d                   	pop    %ebp
f0100fac:	c3                   	ret    

f0100fad <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100fad:	55                   	push   %ebp
f0100fae:	89 e5                	mov    %esp,%ebp
f0100fb0:	83 ec 18             	sub    $0x18,%esp
f0100fb3:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	
	if(pp->pp_ref)
f0100fb6:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100fbb:	74 1c                	je     f0100fd9 <page_free+0x2c>
	{
	panic("Page cannot be returned to free list, as it is still refernced ");
f0100fbd:	c7 44 24 08 e8 45 10 	movl   $0xf01045e8,0x8(%esp)
f0100fc4:	f0 
f0100fc5:	c7 44 24 04 5f 01 00 	movl   $0x15f,0x4(%esp)
f0100fcc:	00 
f0100fcd:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0100fd4:	e8 bb f0 ff ff       	call   f0100094 <_panic>
	return;
	}
	
	// pp->pp_link is not NULL.
	else if(!pp) 
f0100fd9:	85 c0                	test   %eax,%eax
f0100fdb:	75 1c                	jne    f0100ff9 <page_free+0x4c>
	{
	panic("Page cannot be returned to free list as it is Null");
f0100fdd:	c7 44 24 08 28 46 10 	movl   $0xf0104628,0x8(%esp)
f0100fe4:	f0 
f0100fe5:	c7 44 24 04 66 01 00 	movl   $0x166,0x4(%esp)
f0100fec:	00 
f0100fed:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0100ff4:	e8 9b f0 ff ff       	call   f0100094 <_panic>
	return;
	}
	
       else{
	pp->pp_link = page_free_list;
f0100ff9:	8b 15 40 75 11 f0    	mov    0xf0117540,%edx
f0100fff:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0101001:	a3 40 75 11 f0       	mov    %eax,0xf0117540
	}


}
f0101006:	c9                   	leave  
f0101007:	c3                   	ret    

f0101008 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101008:	55                   	push   %ebp
f0101009:	89 e5                	mov    %esp,%ebp
f010100b:	83 ec 18             	sub    $0x18,%esp
f010100e:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0101011:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0101015:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0101018:	66 89 50 04          	mov    %dx,0x4(%eax)
f010101c:	66 85 d2             	test   %dx,%dx
f010101f:	75 08                	jne    f0101029 <page_decref+0x21>
		page_free(pp);
f0101021:	89 04 24             	mov    %eax,(%esp)
f0101024:	e8 84 ff ff ff       	call   f0100fad <page_free>
}
f0101029:	c9                   	leave  
f010102a:	c3                   	ret    

f010102b <pgdir_walk>:
// table and page directory entries.
//

pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f010102b:	55                   	push   %ebp
f010102c:	89 e5                	mov    %esp,%ebp
f010102e:	57                   	push   %edi
f010102f:	56                   	push   %esi
f0101030:	53                   	push   %ebx
f0101031:	83 ec 1c             	sub    $0x1c,%esp
	pte_t *pgTab;  //Page Table index variable

	//To find the index from the pgdir we need to get the MS 10 bits,
	//We get the MS 10bits of the virtual address by using PDX function (found in inc/mmu.h ) 
	//#define PDX(la)		((((uintptr_t) (la)) >> PDXSHIFT) & 0x3FF)
	pgDir = &pgdir[PDX(va)];
f0101034:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101037:	c1 eb 16             	shr    $0x16,%ebx
f010103a:	c1 e3 02             	shl    $0x2,%ebx
f010103d:	03 5d 08             	add    0x8(%ebp),%ebx

	// Check if page is present, PTE_P = 0x1 means page present  
	if (*pgDir & PTE_P)  {
f0101040:	8b 3b                	mov    (%ebx),%edi
f0101042:	f7 c7 01 00 00 00    	test   $0x1,%edi
f0101048:	74 3e                	je     f0101088 <pgdir_walk+0x5d>
		//page table entry to get to the final address translation. Now using the pgDir we can use the 
		//PTE_ADDR(pde) function to get the upper 20 bits, but this function returns a physical address. 
		//Since the kernel requires a virtual address, we can use the function KADDR to get the virtual 
		//address.
		
		pgTab = (pte_t*) KADDR(PTE_ADDR(*pgDir));
f010104a:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101050:	89 f8                	mov    %edi,%eax
f0101052:	c1 e8 0c             	shr    $0xc,%eax
f0101055:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f010105b:	72 20                	jb     f010107d <pgdir_walk+0x52>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010105d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101061:	c7 44 24 08 64 44 10 	movl   $0xf0104464,0x8(%esp)
f0101068:	f0 
f0101069:	c7 44 24 04 a7 01 00 	movl   $0x1a7,0x4(%esp)
f0101070:	00 
f0101071:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101078:	e8 17 f0 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f010107d:	81 ef 00 00 00 10    	sub    $0x10000000,%edi
f0101083:	e9 8f 00 00 00       	jmp    f0101117 <pgdir_walk+0xec>
	//If page is not present 
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
f0101088:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010108c:	0f 84 94 00 00 00    	je     f0101126 <pgdir_walk+0xfb>
f0101092:	c7 04 24 00 10 00 00 	movl   $0x1000,(%esp)
f0101099:	e8 7e fe ff ff       	call   f0100f1c <page_alloc>
f010109e:	89 c6                	mov    %eax,%esi
f01010a0:	85 c0                	test   %eax,%eax
f01010a2:	0f 84 85 00 00 00    	je     f010112d <pgdir_walk+0x102>
			return 0;
		}

		newPage->pp_ref++;  //Increment the ref pointer of the page 
f01010a8:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01010ad:	89 c7                	mov    %eax,%edi
f01010af:	2b 3d 6c 79 11 f0    	sub    0xf011796c,%edi
f01010b5:	c1 ff 03             	sar    $0x3,%edi
f01010b8:	c1 e7 0c             	shl    $0xc,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010bb:	89 f8                	mov    %edi,%eax
f01010bd:	c1 e8 0c             	shr    $0xc,%eax
f01010c0:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f01010c6:	72 20                	jb     f01010e8 <pgdir_walk+0xbd>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010c8:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01010cc:	c7 44 24 08 64 44 10 	movl   $0xf0104464,0x8(%esp)
f01010d3:	f0 
f01010d4:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01010db:	00 
f01010dc:	c7 04 24 d0 4c 10 f0 	movl   $0xf0104cd0,(%esp)
f01010e3:	e8 ac ef ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01010e8:	81 ef 00 00 00 10    	sub    $0x10000000,%edi
		//Now this section creates the bindings and updates all the flags 
		//for relevant use of the page.
		
		//First create a link on the pgTab wrt to the new page
		pgTab = (pte_t*)page2kva(newPage); // this function gets the virtual address of the new page
		memset (pgTab, 0, PGSIZE); //Clear the entire page
f01010ee:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01010f5:	00 
f01010f6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01010fd:	00 
f01010fe:	89 3c 24             	mov    %edi,(%esp)
f0101101:	e8 91 29 00 00       	call   f0103a97 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101106:	2b 35 6c 79 11 f0    	sub    0xf011796c,%esi
f010110c:	c1 fe 03             	sar    $0x3,%esi
f010110f:	c1 e6 0c             	shl    $0xc,%esi

		//Page Table, pgTab contains the virtual address , now we need to set the permission bits.
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
f0101112:	83 ce 07             	or     $0x7,%esi
f0101115:	89 33                	mov    %esi,(%ebx)
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
f0101117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010111a:	c1 e8 0a             	shr    $0xa,%eax
f010111d:	25 fc 0f 00 00       	and    $0xffc,%eax
f0101122:	01 f8                	add    %edi,%eax
f0101124:	eb 0c                	jmp    f0101132 <pgdir_walk+0x107>
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
			return 0;
f0101126:	b8 00 00 00 00       	mov    $0x0,%eax
f010112b:	eb 05                	jmp    f0101132 <pgdir_walk+0x107>
f010112d:	b8 00 00 00 00       	mov    $0x0,%eax
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
}
f0101132:	83 c4 1c             	add    $0x1c,%esp
f0101135:	5b                   	pop    %ebx
f0101136:	5e                   	pop    %esi
f0101137:	5f                   	pop    %edi
f0101138:	5d                   	pop    %ebp
f0101139:	c3                   	ret    

f010113a <boot_map_region>:
//
// Hint: the TA solution uses pgdir_walk

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f010113a:	55                   	push   %ebp
f010113b:	89 e5                	mov    %esp,%ebp
f010113d:	57                   	push   %edi
f010113e:	56                   	push   %esi
f010113f:	53                   	push   %ebx
f0101140:	83 ec 2c             	sub    $0x2c,%esp
f0101143:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f0101146:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
f010114c:	8b 45 08             	mov    0x8(%ebp),%eax
f010114f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	size = ROUNDUP(size, PGSIZE); 
f0101154:	8d b1 ff 0f 00 00    	lea    0xfff(%ecx),%esi
f010115a:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f0101160:	89 d3                	mov    %edx,%ebx
f0101162:	29 d0                	sub    %edx,%eax
f0101164:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		}
		if (*pgTbEnt & PTE_P){
			panic("Page is already mapped");
		}
		
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
f0101167:	8b 45 0c             	mov    0xc(%ebp),%eax
f010116a:	83 c8 01             	or     $0x1,%eax
f010116d:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f0101170:	eb 69                	jmp    f01011db <boot_map_region+0xa1>
		if (!(pgTbEnt = pgdir_walk(pgdir, (const void*)vaBegin, 1))){
f0101172:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101179:	00 
f010117a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010117e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101181:	89 04 24             	mov    %eax,(%esp)
f0101184:	e8 a2 fe ff ff       	call   f010102b <pgdir_walk>
f0101189:	85 c0                	test   %eax,%eax
f010118b:	75 1c                	jne    f01011a9 <boot_map_region+0x6f>
			panic("Cannot find page for the page table entry, from boot_map_region function");
f010118d:	c7 44 24 08 5c 46 10 	movl   $0xf010465c,0x8(%esp)
f0101194:	f0 
f0101195:	c7 44 24 04 dd 01 00 	movl   $0x1dd,0x4(%esp)
f010119c:	00 
f010119d:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01011a4:	e8 eb ee ff ff       	call   f0100094 <_panic>
		}
		if (*pgTbEnt & PTE_P){
f01011a9:	f6 00 01             	testb  $0x1,(%eax)
f01011ac:	74 1c                	je     f01011ca <boot_map_region+0x90>
			panic("Page is already mapped");
f01011ae:	c7 44 24 08 9d 4d 10 	movl   $0xf0104d9d,0x8(%esp)
f01011b5:	f0 
f01011b6:	c7 44 24 04 e0 01 00 	movl   $0x1e0,0x4(%esp)
f01011bd:	00 
f01011be:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01011c5:	e8 ca ee ff ff       	call   f0100094 <_panic>
		}
		
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
f01011ca:	0b 7d dc             	or     -0x24(%ebp),%edi
f01011cd:	89 38                	mov    %edi,(%eax)
		vaBegin += PGSIZE;
f01011cf:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		paBegin += PGSIZE; 
		size -= PGSIZE;
f01011d5:	81 ee 00 10 00 00    	sub    $0x1000,%esi
f01011db:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01011de:	8d 3c 18             	lea    (%eax,%ebx,1),%edi
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f01011e1:	85 f6                	test   %esi,%esi
f01011e3:	75 8d                	jne    f0101172 <boot_map_region+0x38>
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
		vaBegin += PGSIZE;
		paBegin += PGSIZE; 
		size -= PGSIZE;
	} 	
}
f01011e5:	83 c4 2c             	add    $0x2c,%esp
f01011e8:	5b                   	pop    %ebx
f01011e9:	5e                   	pop    %esi
f01011ea:	5f                   	pop    %edi
f01011eb:	5d                   	pop    %ebp
f01011ec:	c3                   	ret    

f01011ed <page_lookup>:
// Hint: the TA solution uses pgdir_walk and pa2page.
//

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01011ed:	55                   	push   %ebp
f01011ee:	89 e5                	mov    %esp,%ebp
f01011f0:	53                   	push   %ebx
f01011f1:	83 ec 14             	sub    $0x14,%esp
f01011f4:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
	pgTbEty = pgdir_walk(pgdir, va, 0);
f01011f7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01011fe:	00 
f01011ff:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101202:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101206:	8b 45 08             	mov    0x8(%ebp),%eax
f0101209:	89 04 24             	mov    %eax,(%esp)
f010120c:	e8 1a fe ff ff       	call   f010102b <pgdir_walk>
f0101211:	89 c2                	mov    %eax,%edx
	if (pgTbEty && (*pgTbEty & PTE_P)) {
f0101213:	85 c0                	test   %eax,%eax
f0101215:	74 1a                	je     f0101231 <page_lookup+0x44>
f0101217:	8b 00                	mov    (%eax),%eax
f0101219:	a8 01                	test   $0x1,%al
f010121b:	74 1b                	je     f0101238 <page_lookup+0x4b>
		ret = pages + (PTE_ADDR(*pgTbEty) >> PTXSHIFT);
f010121d:	c1 e8 0c             	shr    $0xc,%eax
f0101220:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
f0101226:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
		if (pte_store) {
f0101229:	85 db                	test   %ebx,%ebx
f010122b:	74 10                	je     f010123d <page_lookup+0x50>
			*pte_store = pgTbEty;
f010122d:	89 13                	mov    %edx,(%ebx)
f010122f:	eb 0c                	jmp    f010123d <page_lookup+0x50>

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
f0101231:	b8 00 00 00 00       	mov    $0x0,%eax
f0101236:	eb 05                	jmp    f010123d <page_lookup+0x50>
f0101238:	b8 00 00 00 00       	mov    $0x0,%eax
		if (pte_store) {
			*pte_store = pgTbEty;
		}
	}
	return ret;
}
f010123d:	83 c4 14             	add    $0x14,%esp
f0101240:	5b                   	pop    %ebx
f0101241:	5d                   	pop    %ebp
f0101242:	c3                   	ret    

f0101243 <page_remove>:
// 	tlb_invalidate, and page_decref.
//

void
page_remove(pde_t *pgdir, void *va)
{
f0101243:	55                   	push   %ebp
f0101244:	89 e5                	mov    %esp,%ebp
f0101246:	53                   	push   %ebx
f0101247:	83 ec 24             	sub    $0x24,%esp
f010124a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte;
	struct PageInfo *remPage = 0;
	if (!(remPage = page_lookup(pgdir, va, &pte))) {
f010124d:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101250:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101254:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101258:	8b 45 08             	mov    0x8(%ebp),%eax
f010125b:	89 04 24             	mov    %eax,(%esp)
f010125e:	e8 8a ff ff ff       	call   f01011ed <page_lookup>
f0101263:	85 c0                	test   %eax,%eax
f0101265:	74 14                	je     f010127b <page_remove+0x38>
		return;
	}
	page_decref(remPage);
f0101267:	89 04 24             	mov    %eax,(%esp)
f010126a:	e8 99 fd ff ff       	call   f0101008 <page_decref>
	*pte = 0;
f010126f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101272:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101278:	0f 01 3b             	invlpg (%ebx)
	tlb_invalidate(pgdir, va);
}
f010127b:	83 c4 24             	add    $0x24,%esp
f010127e:	5b                   	pop    %ebx
f010127f:	5d                   	pop    %ebp
f0101280:	c3                   	ret    

f0101281 <page_insert>:
// and page2pa.
//

int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101281:	55                   	push   %ebp
f0101282:	89 e5                	mov    %esp,%ebp
f0101284:	57                   	push   %edi
f0101285:	56                   	push   %esi
f0101286:	53                   	push   %ebx
f0101287:	83 ec 1c             	sub    $0x1c,%esp
f010128a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010128d:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
f0101290:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101297:	00 
f0101298:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010129c:	8b 45 08             	mov    0x8(%ebp),%eax
f010129f:	89 04 24             	mov    %eax,(%esp)
f01012a2:	e8 84 fd ff ff       	call   f010102b <pgdir_walk>
f01012a7:	89 c3                	mov    %eax,%ebx
	
	if (!pte){
f01012a9:	85 c0                	test   %eax,%eax
f01012ab:	0f 84 85 00 00 00    	je     f0101336 <page_insert+0xb5>
		return -E_NO_MEM; //Page table could not be allocated	
	}

	if (*pte & PTE_P){    //if page is already present
f01012b1:	8b 00                	mov    (%eax),%eax
f01012b3:	a8 01                	test   $0x1,%al
f01012b5:	74 5b                	je     f0101312 <page_insert+0x91>
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
f01012b7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01012bc:	89 f2                	mov    %esi,%edx
f01012be:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01012c4:	c1 fa 03             	sar    $0x3,%edx
f01012c7:	c1 e2 0c             	shl    $0xc,%edx
f01012ca:	39 d0                	cmp    %edx,%eax
f01012cc:	75 11                	jne    f01012df <page_insert+0x5e>
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
f01012ce:	8b 55 14             	mov    0x14(%ebp),%edx
f01012d1:	83 ca 01             	or     $0x1,%edx
f01012d4:	09 d0                	or     %edx,%eax
f01012d6:	89 03                	mov    %eax,(%ebx)
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
			pp->pp_ref ++;  //incremnt the page reference
		}
		return 0;
f01012d8:	b8 00 00 00 00       	mov    $0x0,%eax
f01012dd:	eb 5c                	jmp    f010133b <page_insert+0xba>
	if (*pte & PTE_P){    //if page is already present
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
		}
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
f01012df:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01012e3:	8b 45 08             	mov    0x8(%ebp),%eax
f01012e6:	89 04 24             	mov    %eax,(%esp)
f01012e9:	e8 55 ff ff ff       	call   f0101243 <page_remove>
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
f01012ee:	8b 55 14             	mov    0x14(%ebp),%edx
f01012f1:	83 ca 01             	or     $0x1,%edx
f01012f4:	89 f0                	mov    %esi,%eax
f01012f6:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01012fc:	c1 f8 03             	sar    $0x3,%eax
f01012ff:	c1 e0 0c             	shl    $0xc,%eax
f0101302:	09 d0                	or     %edx,%eax
f0101304:	89 03                	mov    %eax,(%ebx)
			pp->pp_ref ++;  //incremnt the page reference
f0101306:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
		}
		return 0;
f010130b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101310:	eb 29                	jmp    f010133b <page_insert+0xba>
	}	
	else{   // if page is not present
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
f0101312:	8b 55 14             	mov    0x14(%ebp),%edx
f0101315:	83 ca 01             	or     $0x1,%edx
f0101318:	89 f0                	mov    %esi,%eax
f010131a:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101320:	c1 f8 03             	sar    $0x3,%eax
f0101323:	c1 e0 0c             	shl    $0xc,%eax
f0101326:	09 d0                	or     %edx,%eax
f0101328:	89 03                	mov    %eax,(%ebx)
		pp->pp_ref ++; // increment the page reference count	     
f010132a:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	}
	return 0;
f010132f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101334:	eb 05                	jmp    f010133b <page_insert+0xba>
{
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
	
	if (!pte){
		return -E_NO_MEM; //Page table could not be allocated	
f0101336:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
		pp->pp_ref ++; // increment the page reference count	     
	}
	return 0;

}
f010133b:	83 c4 1c             	add    $0x1c,%esp
f010133e:	5b                   	pop    %ebx
f010133f:	5e                   	pop    %esi
f0101340:	5f                   	pop    %edi
f0101341:	5d                   	pop    %ebp
f0101342:	c3                   	ret    

f0101343 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101343:	55                   	push   %ebp
f0101344:	89 e5                	mov    %esp,%ebp
f0101346:	57                   	push   %edi
f0101347:	56                   	push   %esi
f0101348:	53                   	push   %ebx
f0101349:	83 ec 4c             	sub    $0x4c,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010134c:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f0101353:	e8 6a 1b 00 00       	call   f0102ec2 <mc146818_read>
f0101358:	89 c3                	mov    %eax,%ebx
f010135a:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101361:	e8 5c 1b 00 00       	call   f0102ec2 <mc146818_read>
f0101366:	c1 e0 08             	shl    $0x8,%eax
f0101369:	09 c3                	or     %eax,%ebx
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f010136b:	89 d8                	mov    %ebx,%eax
f010136d:	c1 e0 0a             	shl    $0xa,%eax
f0101370:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101376:	85 c0                	test   %eax,%eax
f0101378:	0f 48 c2             	cmovs  %edx,%eax
f010137b:	c1 f8 0c             	sar    $0xc,%eax
f010137e:	a3 44 75 11 f0       	mov    %eax,0xf0117544
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101383:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010138a:	e8 33 1b 00 00       	call   f0102ec2 <mc146818_read>
f010138f:	89 c3                	mov    %eax,%ebx
f0101391:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101398:	e8 25 1b 00 00       	call   f0102ec2 <mc146818_read>
f010139d:	c1 e0 08             	shl    $0x8,%eax
f01013a0:	09 c3                	or     %eax,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01013a2:	89 d8                	mov    %ebx,%eax
f01013a4:	c1 e0 0a             	shl    $0xa,%eax
f01013a7:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01013ad:	85 c0                	test   %eax,%eax
f01013af:	0f 48 c2             	cmovs  %edx,%eax
f01013b2:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01013b5:	85 c0                	test   %eax,%eax
f01013b7:	74 0e                	je     f01013c7 <mem_init+0x84>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01013b9:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01013bf:	89 15 64 79 11 f0    	mov    %edx,0xf0117964
f01013c5:	eb 0c                	jmp    f01013d3 <mem_init+0x90>
	else
		npages = npages_basemem;
f01013c7:	8b 15 44 75 11 f0    	mov    0xf0117544,%edx
f01013cd:	89 15 64 79 11 f0    	mov    %edx,0xf0117964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f01013d3:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01013d6:	c1 e8 0a             	shr    $0xa,%eax
f01013d9:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f01013dd:	a1 44 75 11 f0       	mov    0xf0117544,%eax
f01013e2:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01013e5:	c1 e8 0a             	shr    $0xa,%eax
f01013e8:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f01013ec:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f01013f1:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01013f4:	c1 e8 0a             	shr    $0xa,%eax
f01013f7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013fb:	c7 04 24 a8 46 10 f0 	movl   $0xf01046a8,(%esp)
f0101402:	e8 2b 1b 00 00       	call   f0102f32 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101407:	b8 00 10 00 00       	mov    $0x1000,%eax
f010140c:	e8 c3 f5 ff ff       	call   f01009d4 <boot_alloc>
f0101411:	a3 68 79 11 f0       	mov    %eax,0xf0117968
	memset(kern_pgdir, 0, PGSIZE);
f0101416:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010141d:	00 
f010141e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101425:	00 
f0101426:	89 04 24             	mov    %eax,(%esp)
f0101429:	e8 69 26 00 00       	call   f0103a97 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010142e:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101433:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101438:	77 20                	ja     f010145a <mem_init+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010143a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010143e:	c7 44 24 08 88 44 10 	movl   $0xf0104488,0x8(%esp)
f0101445:	f0 
f0101446:	c7 44 24 04 95 00 00 	movl   $0x95,0x4(%esp)
f010144d:	00 
f010144e:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101455:	e8 3a ec ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010145a:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101460:	83 ca 05             	or     $0x5,%edx
f0101463:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.

	//This line creates a boot allocation of memory of the size of number of pages
	// mulitplied by size of struct Pageinfo to store metadata of the page. 
	pages = boot_alloc(sizeof(struct PageInfo) * npages);   
f0101469:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f010146e:	c1 e0 03             	shl    $0x3,%eax
f0101471:	e8 5e f5 ff ff       	call   f01009d4 <boot_alloc>
f0101476:	a3 6c 79 11 f0       	mov    %eax,0xf011796c
	memset(pages, 0, sizeof(struct PageInfo) * npages); //Clear the memory 
f010147b:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f0101481:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101488:	89 54 24 08          	mov    %edx,0x8(%esp)
f010148c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101493:	00 
f0101494:	89 04 24             	mov    %eax,(%esp)
f0101497:	e8 fb 25 00 00       	call   f0103a97 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010149c:	e8 1a f9 ff ff       	call   f0100dbb <page_init>

	check_page_free_list(1);
f01014a1:	b8 01 00 00 00       	mov    $0x1,%eax
f01014a6:	e8 ae f5 ff ff       	call   f0100a59 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01014ab:	83 3d 6c 79 11 f0 00 	cmpl   $0x0,0xf011796c
f01014b2:	75 1c                	jne    f01014d0 <mem_init+0x18d>
		panic("'pages' is a null pointer!");
f01014b4:	c7 44 24 08 b4 4d 10 	movl   $0xf0104db4,0x8(%esp)
f01014bb:	f0 
f01014bc:	c7 44 24 04 b6 02 00 	movl   $0x2b6,0x4(%esp)
f01014c3:	00 
f01014c4:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01014cb:	e8 c4 eb ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014d0:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f01014d5:	bb 00 00 00 00       	mov    $0x0,%ebx
f01014da:	eb 05                	jmp    f01014e1 <mem_init+0x19e>
		++nfree;
f01014dc:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014df:	8b 00                	mov    (%eax),%eax
f01014e1:	85 c0                	test   %eax,%eax
f01014e3:	75 f7                	jne    f01014dc <mem_init+0x199>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01014e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014ec:	e8 2b fa ff ff       	call   f0100f1c <page_alloc>
f01014f1:	89 c7                	mov    %eax,%edi
f01014f3:	85 c0                	test   %eax,%eax
f01014f5:	75 24                	jne    f010151b <mem_init+0x1d8>
f01014f7:	c7 44 24 0c cf 4d 10 	movl   $0xf0104dcf,0xc(%esp)
f01014fe:	f0 
f01014ff:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101506:	f0 
f0101507:	c7 44 24 04 be 02 00 	movl   $0x2be,0x4(%esp)
f010150e:	00 
f010150f:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101516:	e8 79 eb ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010151b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101522:	e8 f5 f9 ff ff       	call   f0100f1c <page_alloc>
f0101527:	89 c6                	mov    %eax,%esi
f0101529:	85 c0                	test   %eax,%eax
f010152b:	75 24                	jne    f0101551 <mem_init+0x20e>
f010152d:	c7 44 24 0c e5 4d 10 	movl   $0xf0104de5,0xc(%esp)
f0101534:	f0 
f0101535:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f010153c:	f0 
f010153d:	c7 44 24 04 bf 02 00 	movl   $0x2bf,0x4(%esp)
f0101544:	00 
f0101545:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f010154c:	e8 43 eb ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101551:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101558:	e8 bf f9 ff ff       	call   f0100f1c <page_alloc>
f010155d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101560:	85 c0                	test   %eax,%eax
f0101562:	75 24                	jne    f0101588 <mem_init+0x245>
f0101564:	c7 44 24 0c fb 4d 10 	movl   $0xf0104dfb,0xc(%esp)
f010156b:	f0 
f010156c:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101573:	f0 
f0101574:	c7 44 24 04 c0 02 00 	movl   $0x2c0,0x4(%esp)
f010157b:	00 
f010157c:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101583:	e8 0c eb ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101588:	39 f7                	cmp    %esi,%edi
f010158a:	75 24                	jne    f01015b0 <mem_init+0x26d>
f010158c:	c7 44 24 0c 11 4e 10 	movl   $0xf0104e11,0xc(%esp)
f0101593:	f0 
f0101594:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f010159b:	f0 
f010159c:	c7 44 24 04 c3 02 00 	movl   $0x2c3,0x4(%esp)
f01015a3:	00 
f01015a4:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01015ab:	e8 e4 ea ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015b0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015b3:	39 c6                	cmp    %eax,%esi
f01015b5:	74 04                	je     f01015bb <mem_init+0x278>
f01015b7:	39 c7                	cmp    %eax,%edi
f01015b9:	75 24                	jne    f01015df <mem_init+0x29c>
f01015bb:	c7 44 24 0c e4 46 10 	movl   $0xf01046e4,0xc(%esp)
f01015c2:	f0 
f01015c3:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f01015ca:	f0 
f01015cb:	c7 44 24 04 c4 02 00 	movl   $0x2c4,0x4(%esp)
f01015d2:	00 
f01015d3:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01015da:	e8 b5 ea ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01015df:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f01015e5:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f01015ea:	c1 e0 0c             	shl    $0xc,%eax
f01015ed:	89 f9                	mov    %edi,%ecx
f01015ef:	29 d1                	sub    %edx,%ecx
f01015f1:	c1 f9 03             	sar    $0x3,%ecx
f01015f4:	c1 e1 0c             	shl    $0xc,%ecx
f01015f7:	39 c1                	cmp    %eax,%ecx
f01015f9:	72 24                	jb     f010161f <mem_init+0x2dc>
f01015fb:	c7 44 24 0c 23 4e 10 	movl   $0xf0104e23,0xc(%esp)
f0101602:	f0 
f0101603:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f010160a:	f0 
f010160b:	c7 44 24 04 c5 02 00 	movl   $0x2c5,0x4(%esp)
f0101612:	00 
f0101613:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f010161a:	e8 75 ea ff ff       	call   f0100094 <_panic>
f010161f:	89 f1                	mov    %esi,%ecx
f0101621:	29 d1                	sub    %edx,%ecx
f0101623:	c1 f9 03             	sar    $0x3,%ecx
f0101626:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101629:	39 c8                	cmp    %ecx,%eax
f010162b:	77 24                	ja     f0101651 <mem_init+0x30e>
f010162d:	c7 44 24 0c 40 4e 10 	movl   $0xf0104e40,0xc(%esp)
f0101634:	f0 
f0101635:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f010163c:	f0 
f010163d:	c7 44 24 04 c6 02 00 	movl   $0x2c6,0x4(%esp)
f0101644:	00 
f0101645:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f010164c:	e8 43 ea ff ff       	call   f0100094 <_panic>
f0101651:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101654:	29 d1                	sub    %edx,%ecx
f0101656:	89 ca                	mov    %ecx,%edx
f0101658:	c1 fa 03             	sar    $0x3,%edx
f010165b:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f010165e:	39 d0                	cmp    %edx,%eax
f0101660:	77 24                	ja     f0101686 <mem_init+0x343>
f0101662:	c7 44 24 0c 5d 4e 10 	movl   $0xf0104e5d,0xc(%esp)
f0101669:	f0 
f010166a:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101671:	f0 
f0101672:	c7 44 24 04 c7 02 00 	movl   $0x2c7,0x4(%esp)
f0101679:	00 
f010167a:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101681:	e8 0e ea ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101686:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f010168b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010168e:	c7 05 40 75 11 f0 00 	movl   $0x0,0xf0117540
f0101695:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101698:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010169f:	e8 78 f8 ff ff       	call   f0100f1c <page_alloc>
f01016a4:	85 c0                	test   %eax,%eax
f01016a6:	74 24                	je     f01016cc <mem_init+0x389>
f01016a8:	c7 44 24 0c 7a 4e 10 	movl   $0xf0104e7a,0xc(%esp)
f01016af:	f0 
f01016b0:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f01016b7:	f0 
f01016b8:	c7 44 24 04 ce 02 00 	movl   $0x2ce,0x4(%esp)
f01016bf:	00 
f01016c0:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01016c7:	e8 c8 e9 ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01016cc:	89 3c 24             	mov    %edi,(%esp)
f01016cf:	e8 d9 f8 ff ff       	call   f0100fad <page_free>
	page_free(pp1);
f01016d4:	89 34 24             	mov    %esi,(%esp)
f01016d7:	e8 d1 f8 ff ff       	call   f0100fad <page_free>
	page_free(pp2);
f01016dc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016df:	89 04 24             	mov    %eax,(%esp)
f01016e2:	e8 c6 f8 ff ff       	call   f0100fad <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01016e7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016ee:	e8 29 f8 ff ff       	call   f0100f1c <page_alloc>
f01016f3:	89 c6                	mov    %eax,%esi
f01016f5:	85 c0                	test   %eax,%eax
f01016f7:	75 24                	jne    f010171d <mem_init+0x3da>
f01016f9:	c7 44 24 0c cf 4d 10 	movl   $0xf0104dcf,0xc(%esp)
f0101700:	f0 
f0101701:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101708:	f0 
f0101709:	c7 44 24 04 d5 02 00 	movl   $0x2d5,0x4(%esp)
f0101710:	00 
f0101711:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101718:	e8 77 e9 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010171d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101724:	e8 f3 f7 ff ff       	call   f0100f1c <page_alloc>
f0101729:	89 c7                	mov    %eax,%edi
f010172b:	85 c0                	test   %eax,%eax
f010172d:	75 24                	jne    f0101753 <mem_init+0x410>
f010172f:	c7 44 24 0c e5 4d 10 	movl   $0xf0104de5,0xc(%esp)
f0101736:	f0 
f0101737:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f010173e:	f0 
f010173f:	c7 44 24 04 d6 02 00 	movl   $0x2d6,0x4(%esp)
f0101746:	00 
f0101747:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f010174e:	e8 41 e9 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101753:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010175a:	e8 bd f7 ff ff       	call   f0100f1c <page_alloc>
f010175f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101762:	85 c0                	test   %eax,%eax
f0101764:	75 24                	jne    f010178a <mem_init+0x447>
f0101766:	c7 44 24 0c fb 4d 10 	movl   $0xf0104dfb,0xc(%esp)
f010176d:	f0 
f010176e:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101775:	f0 
f0101776:	c7 44 24 04 d7 02 00 	movl   $0x2d7,0x4(%esp)
f010177d:	00 
f010177e:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101785:	e8 0a e9 ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010178a:	39 fe                	cmp    %edi,%esi
f010178c:	75 24                	jne    f01017b2 <mem_init+0x46f>
f010178e:	c7 44 24 0c 11 4e 10 	movl   $0xf0104e11,0xc(%esp)
f0101795:	f0 
f0101796:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f010179d:	f0 
f010179e:	c7 44 24 04 d9 02 00 	movl   $0x2d9,0x4(%esp)
f01017a5:	00 
f01017a6:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01017ad:	e8 e2 e8 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017b2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017b5:	39 c7                	cmp    %eax,%edi
f01017b7:	74 04                	je     f01017bd <mem_init+0x47a>
f01017b9:	39 c6                	cmp    %eax,%esi
f01017bb:	75 24                	jne    f01017e1 <mem_init+0x49e>
f01017bd:	c7 44 24 0c e4 46 10 	movl   $0xf01046e4,0xc(%esp)
f01017c4:	f0 
f01017c5:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f01017cc:	f0 
f01017cd:	c7 44 24 04 da 02 00 	movl   $0x2da,0x4(%esp)
f01017d4:	00 
f01017d5:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01017dc:	e8 b3 e8 ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f01017e1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017e8:	e8 2f f7 ff ff       	call   f0100f1c <page_alloc>
f01017ed:	85 c0                	test   %eax,%eax
f01017ef:	74 24                	je     f0101815 <mem_init+0x4d2>
f01017f1:	c7 44 24 0c 7a 4e 10 	movl   $0xf0104e7a,0xc(%esp)
f01017f8:	f0 
f01017f9:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101800:	f0 
f0101801:	c7 44 24 04 db 02 00 	movl   $0x2db,0x4(%esp)
f0101808:	00 
f0101809:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101810:	e8 7f e8 ff ff       	call   f0100094 <_panic>
f0101815:	89 f0                	mov    %esi,%eax
f0101817:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f010181d:	c1 f8 03             	sar    $0x3,%eax
f0101820:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101823:	89 c2                	mov    %eax,%edx
f0101825:	c1 ea 0c             	shr    $0xc,%edx
f0101828:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f010182e:	72 20                	jb     f0101850 <mem_init+0x50d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101830:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101834:	c7 44 24 08 64 44 10 	movl   $0xf0104464,0x8(%esp)
f010183b:	f0 
f010183c:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101843:	00 
f0101844:	c7 04 24 d0 4c 10 f0 	movl   $0xf0104cd0,(%esp)
f010184b:	e8 44 e8 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101850:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101857:	00 
f0101858:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f010185f:	00 
	return (void *)(pa + KERNBASE);
f0101860:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101865:	89 04 24             	mov    %eax,(%esp)
f0101868:	e8 2a 22 00 00       	call   f0103a97 <memset>
	page_free(pp0);
f010186d:	89 34 24             	mov    %esi,(%esp)
f0101870:	e8 38 f7 ff ff       	call   f0100fad <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101875:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010187c:	e8 9b f6 ff ff       	call   f0100f1c <page_alloc>
f0101881:	85 c0                	test   %eax,%eax
f0101883:	75 24                	jne    f01018a9 <mem_init+0x566>
f0101885:	c7 44 24 0c 89 4e 10 	movl   $0xf0104e89,0xc(%esp)
f010188c:	f0 
f010188d:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101894:	f0 
f0101895:	c7 44 24 04 e0 02 00 	movl   $0x2e0,0x4(%esp)
f010189c:	00 
f010189d:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01018a4:	e8 eb e7 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f01018a9:	39 c6                	cmp    %eax,%esi
f01018ab:	74 24                	je     f01018d1 <mem_init+0x58e>
f01018ad:	c7 44 24 0c a7 4e 10 	movl   $0xf0104ea7,0xc(%esp)
f01018b4:	f0 
f01018b5:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f01018bc:	f0 
f01018bd:	c7 44 24 04 e1 02 00 	movl   $0x2e1,0x4(%esp)
f01018c4:	00 
f01018c5:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01018cc:	e8 c3 e7 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01018d1:	89 f0                	mov    %esi,%eax
f01018d3:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01018d9:	c1 f8 03             	sar    $0x3,%eax
f01018dc:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01018df:	89 c2                	mov    %eax,%edx
f01018e1:	c1 ea 0c             	shr    $0xc,%edx
f01018e4:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01018ea:	72 20                	jb     f010190c <mem_init+0x5c9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01018ec:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01018f0:	c7 44 24 08 64 44 10 	movl   $0xf0104464,0x8(%esp)
f01018f7:	f0 
f01018f8:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01018ff:	00 
f0101900:	c7 04 24 d0 4c 10 f0 	movl   $0xf0104cd0,(%esp)
f0101907:	e8 88 e7 ff ff       	call   f0100094 <_panic>
f010190c:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101912:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101918:	80 38 00             	cmpb   $0x0,(%eax)
f010191b:	74 24                	je     f0101941 <mem_init+0x5fe>
f010191d:	c7 44 24 0c b7 4e 10 	movl   $0xf0104eb7,0xc(%esp)
f0101924:	f0 
f0101925:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f010192c:	f0 
f010192d:	c7 44 24 04 e4 02 00 	movl   $0x2e4,0x4(%esp)
f0101934:	00 
f0101935:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f010193c:	e8 53 e7 ff ff       	call   f0100094 <_panic>
f0101941:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101944:	39 d0                	cmp    %edx,%eax
f0101946:	75 d0                	jne    f0101918 <mem_init+0x5d5>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101948:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010194b:	a3 40 75 11 f0       	mov    %eax,0xf0117540

	// free the pages we took
	page_free(pp0);
f0101950:	89 34 24             	mov    %esi,(%esp)
f0101953:	e8 55 f6 ff ff       	call   f0100fad <page_free>
	page_free(pp1);
f0101958:	89 3c 24             	mov    %edi,(%esp)
f010195b:	e8 4d f6 ff ff       	call   f0100fad <page_free>
	page_free(pp2);
f0101960:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101963:	89 04 24             	mov    %eax,(%esp)
f0101966:	e8 42 f6 ff ff       	call   f0100fad <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010196b:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f0101970:	eb 05                	jmp    f0101977 <mem_init+0x634>
		--nfree;
f0101972:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101975:	8b 00                	mov    (%eax),%eax
f0101977:	85 c0                	test   %eax,%eax
f0101979:	75 f7                	jne    f0101972 <mem_init+0x62f>
		--nfree;
	assert(nfree == 0);
f010197b:	85 db                	test   %ebx,%ebx
f010197d:	74 24                	je     f01019a3 <mem_init+0x660>
f010197f:	c7 44 24 0c c1 4e 10 	movl   $0xf0104ec1,0xc(%esp)
f0101986:	f0 
f0101987:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f010198e:	f0 
f010198f:	c7 44 24 04 f1 02 00 	movl   $0x2f1,0x4(%esp)
f0101996:	00 
f0101997:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f010199e:	e8 f1 e6 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01019a3:	c7 04 24 04 47 10 f0 	movl   $0xf0104704,(%esp)
f01019aa:	e8 83 15 00 00       	call   f0102f32 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01019af:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019b6:	e8 61 f5 ff ff       	call   f0100f1c <page_alloc>
f01019bb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01019be:	85 c0                	test   %eax,%eax
f01019c0:	75 24                	jne    f01019e6 <mem_init+0x6a3>
f01019c2:	c7 44 24 0c cf 4d 10 	movl   $0xf0104dcf,0xc(%esp)
f01019c9:	f0 
f01019ca:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f01019d1:	f0 
f01019d2:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f01019d9:	00 
f01019da:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01019e1:	e8 ae e6 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01019e6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019ed:	e8 2a f5 ff ff       	call   f0100f1c <page_alloc>
f01019f2:	89 c3                	mov    %eax,%ebx
f01019f4:	85 c0                	test   %eax,%eax
f01019f6:	75 24                	jne    f0101a1c <mem_init+0x6d9>
f01019f8:	c7 44 24 0c e5 4d 10 	movl   $0xf0104de5,0xc(%esp)
f01019ff:	f0 
f0101a00:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101a07:	f0 
f0101a08:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
f0101a0f:	00 
f0101a10:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101a17:	e8 78 e6 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101a1c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a23:	e8 f4 f4 ff ff       	call   f0100f1c <page_alloc>
f0101a28:	89 c6                	mov    %eax,%esi
f0101a2a:	85 c0                	test   %eax,%eax
f0101a2c:	75 24                	jne    f0101a52 <mem_init+0x70f>
f0101a2e:	c7 44 24 0c fb 4d 10 	movl   $0xf0104dfb,0xc(%esp)
f0101a35:	f0 
f0101a36:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101a3d:	f0 
f0101a3e:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0101a45:	00 
f0101a46:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101a4d:	e8 42 e6 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a52:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101a55:	75 24                	jne    f0101a7b <mem_init+0x738>
f0101a57:	c7 44 24 0c 11 4e 10 	movl   $0xf0104e11,0xc(%esp)
f0101a5e:	f0 
f0101a5f:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101a66:	f0 
f0101a67:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f0101a6e:	00 
f0101a6f:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101a76:	e8 19 e6 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a7b:	39 c3                	cmp    %eax,%ebx
f0101a7d:	74 05                	je     f0101a84 <mem_init+0x741>
f0101a7f:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101a82:	75 24                	jne    f0101aa8 <mem_init+0x765>
f0101a84:	c7 44 24 0c e4 46 10 	movl   $0xf01046e4,0xc(%esp)
f0101a8b:	f0 
f0101a8c:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101a93:	f0 
f0101a94:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f0101a9b:	00 
f0101a9c:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101aa3:	e8 ec e5 ff ff       	call   f0100094 <_panic>
	

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101aa8:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f0101aad:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101ab0:	c7 05 40 75 11 f0 00 	movl   $0x0,0xf0117540
f0101ab7:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101aba:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ac1:	e8 56 f4 ff ff       	call   f0100f1c <page_alloc>
f0101ac6:	85 c0                	test   %eax,%eax
f0101ac8:	74 24                	je     f0101aee <mem_init+0x7ab>
f0101aca:	c7 44 24 0c 7a 4e 10 	movl   $0xf0104e7a,0xc(%esp)
f0101ad1:	f0 
f0101ad2:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101ad9:	f0 
f0101ada:	c7 44 24 04 58 03 00 	movl   $0x358,0x4(%esp)
f0101ae1:	00 
f0101ae2:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101ae9:	e8 a6 e5 ff ff       	call   f0100094 <_panic>
	
	
	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101aee:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101af1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101af5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101afc:	00 
f0101afd:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101b02:	89 04 24             	mov    %eax,(%esp)
f0101b05:	e8 e3 f6 ff ff       	call   f01011ed <page_lookup>
f0101b0a:	85 c0                	test   %eax,%eax
f0101b0c:	74 24                	je     f0101b32 <mem_init+0x7ef>
f0101b0e:	c7 44 24 0c 24 47 10 	movl   $0xf0104724,0xc(%esp)
f0101b15:	f0 
f0101b16:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101b1d:	f0 
f0101b1e:	c7 44 24 04 5c 03 00 	movl   $0x35c,0x4(%esp)
f0101b25:	00 
f0101b26:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101b2d:	e8 62 e5 ff ff       	call   f0100094 <_panic>
	
	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101b32:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b39:	00 
f0101b3a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101b41:	00 
f0101b42:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101b46:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101b4b:	89 04 24             	mov    %eax,(%esp)
f0101b4e:	e8 2e f7 ff ff       	call   f0101281 <page_insert>
f0101b53:	85 c0                	test   %eax,%eax
f0101b55:	78 24                	js     f0101b7b <mem_init+0x838>
f0101b57:	c7 44 24 0c 5c 47 10 	movl   $0xf010475c,0xc(%esp)
f0101b5e:	f0 
f0101b5f:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101b66:	f0 
f0101b67:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f0101b6e:	00 
f0101b6f:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101b76:	e8 19 e5 ff ff       	call   f0100094 <_panic>
	
	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101b7b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b7e:	89 04 24             	mov    %eax,(%esp)
f0101b81:	e8 27 f4 ff ff       	call   f0100fad <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101b86:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b8d:	00 
f0101b8e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101b95:	00 
f0101b96:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101b9a:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101b9f:	89 04 24             	mov    %eax,(%esp)
f0101ba2:	e8 da f6 ff ff       	call   f0101281 <page_insert>
f0101ba7:	85 c0                	test   %eax,%eax
f0101ba9:	74 24                	je     f0101bcf <mem_init+0x88c>
f0101bab:	c7 44 24 0c 8c 47 10 	movl   $0xf010478c,0xc(%esp)
f0101bb2:	f0 
f0101bb3:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101bba:	f0 
f0101bbb:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f0101bc2:	00 
f0101bc3:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101bca:	e8 c5 e4 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101bcf:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101bd5:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101bda:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101bdd:	8b 17                	mov    (%edi),%edx
f0101bdf:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101be5:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101be8:	29 c1                	sub    %eax,%ecx
f0101bea:	89 c8                	mov    %ecx,%eax
f0101bec:	c1 f8 03             	sar    $0x3,%eax
f0101bef:	c1 e0 0c             	shl    $0xc,%eax
f0101bf2:	39 c2                	cmp    %eax,%edx
f0101bf4:	74 24                	je     f0101c1a <mem_init+0x8d7>
f0101bf6:	c7 44 24 0c bc 47 10 	movl   $0xf01047bc,0xc(%esp)
f0101bfd:	f0 
f0101bfe:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101c05:	f0 
f0101c06:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f0101c0d:	00 
f0101c0e:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101c15:	e8 7a e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101c1a:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c1f:	89 f8                	mov    %edi,%eax
f0101c21:	e8 3f ed ff ff       	call   f0100965 <check_va2pa>
f0101c26:	89 da                	mov    %ebx,%edx
f0101c28:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101c2b:	c1 fa 03             	sar    $0x3,%edx
f0101c2e:	c1 e2 0c             	shl    $0xc,%edx
f0101c31:	39 d0                	cmp    %edx,%eax
f0101c33:	74 24                	je     f0101c59 <mem_init+0x916>
f0101c35:	c7 44 24 0c e4 47 10 	movl   $0xf01047e4,0xc(%esp)
f0101c3c:	f0 
f0101c3d:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101c44:	f0 
f0101c45:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f0101c4c:	00 
f0101c4d:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101c54:	e8 3b e4 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101c59:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101c5e:	74 24                	je     f0101c84 <mem_init+0x941>
f0101c60:	c7 44 24 0c cc 4e 10 	movl   $0xf0104ecc,0xc(%esp)
f0101c67:	f0 
f0101c68:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101c6f:	f0 
f0101c70:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f0101c77:	00 
f0101c78:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101c7f:	e8 10 e4 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101c84:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c87:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101c8c:	74 24                	je     f0101cb2 <mem_init+0x96f>
f0101c8e:	c7 44 24 0c dd 4e 10 	movl   $0xf0104edd,0xc(%esp)
f0101c95:	f0 
f0101c96:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101c9d:	f0 
f0101c9e:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f0101ca5:	00 
f0101ca6:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101cad:	e8 e2 e3 ff ff       	call   f0100094 <_panic>
	
	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101cb2:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101cb9:	00 
f0101cba:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101cc1:	00 
f0101cc2:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101cc6:	89 3c 24             	mov    %edi,(%esp)
f0101cc9:	e8 b3 f5 ff ff       	call   f0101281 <page_insert>
f0101cce:	85 c0                	test   %eax,%eax
f0101cd0:	74 24                	je     f0101cf6 <mem_init+0x9b3>
f0101cd2:	c7 44 24 0c 14 48 10 	movl   $0xf0104814,0xc(%esp)
f0101cd9:	f0 
f0101cda:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101ce1:	f0 
f0101ce2:	c7 44 24 04 6a 03 00 	movl   $0x36a,0x4(%esp)
f0101ce9:	00 
f0101cea:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101cf1:	e8 9e e3 ff ff       	call   f0100094 <_panic>

	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101cf6:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cfb:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101d00:	e8 60 ec ff ff       	call   f0100965 <check_va2pa>
f0101d05:	89 f2                	mov    %esi,%edx
f0101d07:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101d0d:	c1 fa 03             	sar    $0x3,%edx
f0101d10:	c1 e2 0c             	shl    $0xc,%edx
f0101d13:	39 d0                	cmp    %edx,%eax
f0101d15:	74 24                	je     f0101d3b <mem_init+0x9f8>
f0101d17:	c7 44 24 0c 50 48 10 	movl   $0xf0104850,0xc(%esp)
f0101d1e:	f0 
f0101d1f:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101d26:	f0 
f0101d27:	c7 44 24 04 6c 03 00 	movl   $0x36c,0x4(%esp)
f0101d2e:	00 
f0101d2f:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101d36:	e8 59 e3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101d3b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d40:	74 24                	je     f0101d66 <mem_init+0xa23>
f0101d42:	c7 44 24 0c ee 4e 10 	movl   $0xf0104eee,0xc(%esp)
f0101d49:	f0 
f0101d4a:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101d51:	f0 
f0101d52:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f0101d59:	00 
f0101d5a:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101d61:	e8 2e e3 ff ff       	call   f0100094 <_panic>
	
	// should be no free memory
	assert(!page_alloc(0));
f0101d66:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d6d:	e8 aa f1 ff ff       	call   f0100f1c <page_alloc>
f0101d72:	85 c0                	test   %eax,%eax
f0101d74:	74 24                	je     f0101d9a <mem_init+0xa57>
f0101d76:	c7 44 24 0c 7a 4e 10 	movl   $0xf0104e7a,0xc(%esp)
f0101d7d:	f0 
f0101d7e:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101d85:	f0 
f0101d86:	c7 44 24 04 70 03 00 	movl   $0x370,0x4(%esp)
f0101d8d:	00 
f0101d8e:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101d95:	e8 fa e2 ff ff       	call   f0100094 <_panic>
	
	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d9a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101da1:	00 
f0101da2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101da9:	00 
f0101daa:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101dae:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101db3:	89 04 24             	mov    %eax,(%esp)
f0101db6:	e8 c6 f4 ff ff       	call   f0101281 <page_insert>
f0101dbb:	85 c0                	test   %eax,%eax
f0101dbd:	74 24                	je     f0101de3 <mem_init+0xaa0>
f0101dbf:	c7 44 24 0c 14 48 10 	movl   $0xf0104814,0xc(%esp)
f0101dc6:	f0 
f0101dc7:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101dce:	f0 
f0101dcf:	c7 44 24 04 73 03 00 	movl   $0x373,0x4(%esp)
f0101dd6:	00 
f0101dd7:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101dde:	e8 b1 e2 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101de3:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101de8:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101ded:	e8 73 eb ff ff       	call   f0100965 <check_va2pa>
f0101df2:	89 f2                	mov    %esi,%edx
f0101df4:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101dfa:	c1 fa 03             	sar    $0x3,%edx
f0101dfd:	c1 e2 0c             	shl    $0xc,%edx
f0101e00:	39 d0                	cmp    %edx,%eax
f0101e02:	74 24                	je     f0101e28 <mem_init+0xae5>
f0101e04:	c7 44 24 0c 50 48 10 	movl   $0xf0104850,0xc(%esp)
f0101e0b:	f0 
f0101e0c:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101e13:	f0 
f0101e14:	c7 44 24 04 74 03 00 	movl   $0x374,0x4(%esp)
f0101e1b:	00 
f0101e1c:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101e23:	e8 6c e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101e28:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e2d:	74 24                	je     f0101e53 <mem_init+0xb10>
f0101e2f:	c7 44 24 0c ee 4e 10 	movl   $0xf0104eee,0xc(%esp)
f0101e36:	f0 
f0101e37:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101e3e:	f0 
f0101e3f:	c7 44 24 04 75 03 00 	movl   $0x375,0x4(%esp)
f0101e46:	00 
f0101e47:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101e4e:	e8 41 e2 ff ff       	call   f0100094 <_panic>
	
	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101e53:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101e5a:	e8 bd f0 ff ff       	call   f0100f1c <page_alloc>
f0101e5f:	85 c0                	test   %eax,%eax
f0101e61:	74 24                	je     f0101e87 <mem_init+0xb44>
f0101e63:	c7 44 24 0c 7a 4e 10 	movl   $0xf0104e7a,0xc(%esp)
f0101e6a:	f0 
f0101e6b:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101e72:	f0 
f0101e73:	c7 44 24 04 79 03 00 	movl   $0x379,0x4(%esp)
f0101e7a:	00 
f0101e7b:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101e82:	e8 0d e2 ff ff       	call   f0100094 <_panic>
	
	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101e87:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f0101e8d:	8b 02                	mov    (%edx),%eax
f0101e8f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101e94:	89 c1                	mov    %eax,%ecx
f0101e96:	c1 e9 0c             	shr    $0xc,%ecx
f0101e99:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0101e9f:	72 20                	jb     f0101ec1 <mem_init+0xb7e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ea1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101ea5:	c7 44 24 08 64 44 10 	movl   $0xf0104464,0x8(%esp)
f0101eac:	f0 
f0101ead:	c7 44 24 04 7c 03 00 	movl   $0x37c,0x4(%esp)
f0101eb4:	00 
f0101eb5:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101ebc:	e8 d3 e1 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101ec1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101ec6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101ec9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101ed0:	00 
f0101ed1:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101ed8:	00 
f0101ed9:	89 14 24             	mov    %edx,(%esp)
f0101edc:	e8 4a f1 ff ff       	call   f010102b <pgdir_walk>
f0101ee1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101ee4:	8d 57 04             	lea    0x4(%edi),%edx
f0101ee7:	39 d0                	cmp    %edx,%eax
f0101ee9:	74 24                	je     f0101f0f <mem_init+0xbcc>
f0101eeb:	c7 44 24 0c 80 48 10 	movl   $0xf0104880,0xc(%esp)
f0101ef2:	f0 
f0101ef3:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101efa:	f0 
f0101efb:	c7 44 24 04 7d 03 00 	movl   $0x37d,0x4(%esp)
f0101f02:	00 
f0101f03:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101f0a:	e8 85 e1 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101f0f:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101f16:	00 
f0101f17:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f1e:	00 
f0101f1f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101f23:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101f28:	89 04 24             	mov    %eax,(%esp)
f0101f2b:	e8 51 f3 ff ff       	call   f0101281 <page_insert>
f0101f30:	85 c0                	test   %eax,%eax
f0101f32:	74 24                	je     f0101f58 <mem_init+0xc15>
f0101f34:	c7 44 24 0c c0 48 10 	movl   $0xf01048c0,0xc(%esp)
f0101f3b:	f0 
f0101f3c:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101f43:	f0 
f0101f44:	c7 44 24 04 80 03 00 	movl   $0x380,0x4(%esp)
f0101f4b:	00 
f0101f4c:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101f53:	e8 3c e1 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101f58:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101f5e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f63:	89 f8                	mov    %edi,%eax
f0101f65:	e8 fb e9 ff ff       	call   f0100965 <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101f6a:	89 f2                	mov    %esi,%edx
f0101f6c:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101f72:	c1 fa 03             	sar    $0x3,%edx
f0101f75:	c1 e2 0c             	shl    $0xc,%edx
f0101f78:	39 d0                	cmp    %edx,%eax
f0101f7a:	74 24                	je     f0101fa0 <mem_init+0xc5d>
f0101f7c:	c7 44 24 0c 50 48 10 	movl   $0xf0104850,0xc(%esp)
f0101f83:	f0 
f0101f84:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101f8b:	f0 
f0101f8c:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f0101f93:	00 
f0101f94:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101f9b:	e8 f4 e0 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101fa0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101fa5:	74 24                	je     f0101fcb <mem_init+0xc88>
f0101fa7:	c7 44 24 0c ee 4e 10 	movl   $0xf0104eee,0xc(%esp)
f0101fae:	f0 
f0101faf:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101fb6:	f0 
f0101fb7:	c7 44 24 04 82 03 00 	movl   $0x382,0x4(%esp)
f0101fbe:	00 
f0101fbf:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0101fc6:	e8 c9 e0 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101fcb:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101fd2:	00 
f0101fd3:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101fda:	00 
f0101fdb:	89 3c 24             	mov    %edi,(%esp)
f0101fde:	e8 48 f0 ff ff       	call   f010102b <pgdir_walk>
f0101fe3:	f6 00 04             	testb  $0x4,(%eax)
f0101fe6:	75 24                	jne    f010200c <mem_init+0xcc9>
f0101fe8:	c7 44 24 0c 00 49 10 	movl   $0xf0104900,0xc(%esp)
f0101fef:	f0 
f0101ff0:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0101ff7:	f0 
f0101ff8:	c7 44 24 04 83 03 00 	movl   $0x383,0x4(%esp)
f0101fff:	00 
f0102000:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102007:	e8 88 e0 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f010200c:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102011:	f6 00 04             	testb  $0x4,(%eax)
f0102014:	75 24                	jne    f010203a <mem_init+0xcf7>
f0102016:	c7 44 24 0c ff 4e 10 	movl   $0xf0104eff,0xc(%esp)
f010201d:	f0 
f010201e:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102025:	f0 
f0102026:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f010202d:	00 
f010202e:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102035:	e8 5a e0 ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010203a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102041:	00 
f0102042:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102049:	00 
f010204a:	89 74 24 04          	mov    %esi,0x4(%esp)
f010204e:	89 04 24             	mov    %eax,(%esp)
f0102051:	e8 2b f2 ff ff       	call   f0101281 <page_insert>
f0102056:	85 c0                	test   %eax,%eax
f0102058:	74 24                	je     f010207e <mem_init+0xd3b>
f010205a:	c7 44 24 0c 14 48 10 	movl   $0xf0104814,0xc(%esp)
f0102061:	f0 
f0102062:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102069:	f0 
f010206a:	c7 44 24 04 87 03 00 	movl   $0x387,0x4(%esp)
f0102071:	00 
f0102072:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102079:	e8 16 e0 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f010207e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102085:	00 
f0102086:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010208d:	00 
f010208e:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102093:	89 04 24             	mov    %eax,(%esp)
f0102096:	e8 90 ef ff ff       	call   f010102b <pgdir_walk>
f010209b:	f6 00 02             	testb  $0x2,(%eax)
f010209e:	75 24                	jne    f01020c4 <mem_init+0xd81>
f01020a0:	c7 44 24 0c 34 49 10 	movl   $0xf0104934,0xc(%esp)
f01020a7:	f0 
f01020a8:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f01020af:	f0 
f01020b0:	c7 44 24 04 88 03 00 	movl   $0x388,0x4(%esp)
f01020b7:	00 
f01020b8:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01020bf:	e8 d0 df ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01020c4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01020cb:	00 
f01020cc:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01020d3:	00 
f01020d4:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01020d9:	89 04 24             	mov    %eax,(%esp)
f01020dc:	e8 4a ef ff ff       	call   f010102b <pgdir_walk>
f01020e1:	f6 00 04             	testb  $0x4,(%eax)
f01020e4:	74 24                	je     f010210a <mem_init+0xdc7>
f01020e6:	c7 44 24 0c 68 49 10 	movl   $0xf0104968,0xc(%esp)
f01020ed:	f0 
f01020ee:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f01020f5:	f0 
f01020f6:	c7 44 24 04 89 03 00 	movl   $0x389,0x4(%esp)
f01020fd:	00 
f01020fe:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102105:	e8 8a df ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f010210a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102111:	00 
f0102112:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0102119:	00 
f010211a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010211d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102121:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102126:	89 04 24             	mov    %eax,(%esp)
f0102129:	e8 53 f1 ff ff       	call   f0101281 <page_insert>
f010212e:	85 c0                	test   %eax,%eax
f0102130:	78 24                	js     f0102156 <mem_init+0xe13>
f0102132:	c7 44 24 0c a0 49 10 	movl   $0xf01049a0,0xc(%esp)
f0102139:	f0 
f010213a:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102141:	f0 
f0102142:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f0102149:	00 
f010214a:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102151:	e8 3e df ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102156:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010215d:	00 
f010215e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102165:	00 
f0102166:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010216a:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010216f:	89 04 24             	mov    %eax,(%esp)
f0102172:	e8 0a f1 ff ff       	call   f0101281 <page_insert>
f0102177:	85 c0                	test   %eax,%eax
f0102179:	74 24                	je     f010219f <mem_init+0xe5c>
f010217b:	c7 44 24 0c d8 49 10 	movl   $0xf01049d8,0xc(%esp)
f0102182:	f0 
f0102183:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f010218a:	f0 
f010218b:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f0102192:	00 
f0102193:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f010219a:	e8 f5 de ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010219f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01021a6:	00 
f01021a7:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01021ae:	00 
f01021af:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01021b4:	89 04 24             	mov    %eax,(%esp)
f01021b7:	e8 6f ee ff ff       	call   f010102b <pgdir_walk>
f01021bc:	f6 00 04             	testb  $0x4,(%eax)
f01021bf:	74 24                	je     f01021e5 <mem_init+0xea2>
f01021c1:	c7 44 24 0c 68 49 10 	movl   $0xf0104968,0xc(%esp)
f01021c8:	f0 
f01021c9:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f01021d0:	f0 
f01021d1:	c7 44 24 04 90 03 00 	movl   $0x390,0x4(%esp)
f01021d8:	00 
f01021d9:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01021e0:	e8 af de ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01021e5:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f01021eb:	ba 00 00 00 00       	mov    $0x0,%edx
f01021f0:	89 f8                	mov    %edi,%eax
f01021f2:	e8 6e e7 ff ff       	call   f0100965 <check_va2pa>
f01021f7:	89 c1                	mov    %eax,%ecx
f01021f9:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021fc:	89 d8                	mov    %ebx,%eax
f01021fe:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102204:	c1 f8 03             	sar    $0x3,%eax
f0102207:	c1 e0 0c             	shl    $0xc,%eax
f010220a:	39 c1                	cmp    %eax,%ecx
f010220c:	74 24                	je     f0102232 <mem_init+0xeef>
f010220e:	c7 44 24 0c 14 4a 10 	movl   $0xf0104a14,0xc(%esp)
f0102215:	f0 
f0102216:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f010221d:	f0 
f010221e:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f0102225:	00 
f0102226:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f010222d:	e8 62 de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102232:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102237:	89 f8                	mov    %edi,%eax
f0102239:	e8 27 e7 ff ff       	call   f0100965 <check_va2pa>
f010223e:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0102241:	74 24                	je     f0102267 <mem_init+0xf24>
f0102243:	c7 44 24 0c 40 4a 10 	movl   $0xf0104a40,0xc(%esp)
f010224a:	f0 
f010224b:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102252:	f0 
f0102253:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f010225a:	00 
f010225b:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102262:	e8 2d de ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102267:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f010226c:	74 24                	je     f0102292 <mem_init+0xf4f>
f010226e:	c7 44 24 0c 15 4f 10 	movl   $0xf0104f15,0xc(%esp)
f0102275:	f0 
f0102276:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f010227d:	f0 
f010227e:	c7 44 24 04 96 03 00 	movl   $0x396,0x4(%esp)
f0102285:	00 
f0102286:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f010228d:	e8 02 de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102292:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102297:	74 24                	je     f01022bd <mem_init+0xf7a>
f0102299:	c7 44 24 0c 26 4f 10 	movl   $0xf0104f26,0xc(%esp)
f01022a0:	f0 
f01022a1:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f01022a8:	f0 
f01022a9:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f01022b0:	00 
f01022b1:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01022b8:	e8 d7 dd ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f01022bd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01022c4:	e8 53 ec ff ff       	call   f0100f1c <page_alloc>
f01022c9:	85 c0                	test   %eax,%eax
f01022cb:	74 04                	je     f01022d1 <mem_init+0xf8e>
f01022cd:	39 c6                	cmp    %eax,%esi
f01022cf:	74 24                	je     f01022f5 <mem_init+0xfb2>
f01022d1:	c7 44 24 0c 70 4a 10 	movl   $0xf0104a70,0xc(%esp)
f01022d8:	f0 
f01022d9:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f01022e0:	f0 
f01022e1:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f01022e8:	00 
f01022e9:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01022f0:	e8 9f dd ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f01022f5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01022fc:	00 
f01022fd:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102302:	89 04 24             	mov    %eax,(%esp)
f0102305:	e8 39 ef ff ff       	call   f0101243 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010230a:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0102310:	ba 00 00 00 00       	mov    $0x0,%edx
f0102315:	89 f8                	mov    %edi,%eax
f0102317:	e8 49 e6 ff ff       	call   f0100965 <check_va2pa>
f010231c:	83 f8 ff             	cmp    $0xffffffff,%eax
f010231f:	74 24                	je     f0102345 <mem_init+0x1002>
f0102321:	c7 44 24 0c 94 4a 10 	movl   $0xf0104a94,0xc(%esp)
f0102328:	f0 
f0102329:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102330:	f0 
f0102331:	c7 44 24 04 9e 03 00 	movl   $0x39e,0x4(%esp)
f0102338:	00 
f0102339:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102340:	e8 4f dd ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102345:	ba 00 10 00 00       	mov    $0x1000,%edx
f010234a:	89 f8                	mov    %edi,%eax
f010234c:	e8 14 e6 ff ff       	call   f0100965 <check_va2pa>
f0102351:	89 da                	mov    %ebx,%edx
f0102353:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0102359:	c1 fa 03             	sar    $0x3,%edx
f010235c:	c1 e2 0c             	shl    $0xc,%edx
f010235f:	39 d0                	cmp    %edx,%eax
f0102361:	74 24                	je     f0102387 <mem_init+0x1044>
f0102363:	c7 44 24 0c 40 4a 10 	movl   $0xf0104a40,0xc(%esp)
f010236a:	f0 
f010236b:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102372:	f0 
f0102373:	c7 44 24 04 9f 03 00 	movl   $0x39f,0x4(%esp)
f010237a:	00 
f010237b:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102382:	e8 0d dd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0102387:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010238c:	74 24                	je     f01023b2 <mem_init+0x106f>
f010238e:	c7 44 24 0c cc 4e 10 	movl   $0xf0104ecc,0xc(%esp)
f0102395:	f0 
f0102396:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f010239d:	f0 
f010239e:	c7 44 24 04 a0 03 00 	movl   $0x3a0,0x4(%esp)
f01023a5:	00 
f01023a6:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01023ad:	e8 e2 dc ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01023b2:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01023b7:	74 24                	je     f01023dd <mem_init+0x109a>
f01023b9:	c7 44 24 0c 26 4f 10 	movl   $0xf0104f26,0xc(%esp)
f01023c0:	f0 
f01023c1:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f01023c8:	f0 
f01023c9:	c7 44 24 04 a1 03 00 	movl   $0x3a1,0x4(%esp)
f01023d0:	00 
f01023d1:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01023d8:	e8 b7 dc ff ff       	call   f0100094 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01023dd:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01023e4:	00 
f01023e5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01023ec:	00 
f01023ed:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01023f1:	89 3c 24             	mov    %edi,(%esp)
f01023f4:	e8 88 ee ff ff       	call   f0101281 <page_insert>
f01023f9:	85 c0                	test   %eax,%eax
f01023fb:	74 24                	je     f0102421 <mem_init+0x10de>
f01023fd:	c7 44 24 0c b8 4a 10 	movl   $0xf0104ab8,0xc(%esp)
f0102404:	f0 
f0102405:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f010240c:	f0 
f010240d:	c7 44 24 04 a4 03 00 	movl   $0x3a4,0x4(%esp)
f0102414:	00 
f0102415:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f010241c:	e8 73 dc ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref);
f0102421:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102426:	75 24                	jne    f010244c <mem_init+0x1109>
f0102428:	c7 44 24 0c 37 4f 10 	movl   $0xf0104f37,0xc(%esp)
f010242f:	f0 
f0102430:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102437:	f0 
f0102438:	c7 44 24 04 a5 03 00 	movl   $0x3a5,0x4(%esp)
f010243f:	00 
f0102440:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102447:	e8 48 dc ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_link == NULL);
f010244c:	83 3b 00             	cmpl   $0x0,(%ebx)
f010244f:	74 24                	je     f0102475 <mem_init+0x1132>
f0102451:	c7 44 24 0c 43 4f 10 	movl   $0xf0104f43,0xc(%esp)
f0102458:	f0 
f0102459:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102460:	f0 
f0102461:	c7 44 24 04 a6 03 00 	movl   $0x3a6,0x4(%esp)
f0102468:	00 
f0102469:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102470:	e8 1f dc ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102475:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010247c:	00 
f010247d:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102482:	89 04 24             	mov    %eax,(%esp)
f0102485:	e8 b9 ed ff ff       	call   f0101243 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010248a:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0102490:	ba 00 00 00 00       	mov    $0x0,%edx
f0102495:	89 f8                	mov    %edi,%eax
f0102497:	e8 c9 e4 ff ff       	call   f0100965 <check_va2pa>
f010249c:	83 f8 ff             	cmp    $0xffffffff,%eax
f010249f:	74 24                	je     f01024c5 <mem_init+0x1182>
f01024a1:	c7 44 24 0c 94 4a 10 	movl   $0xf0104a94,0xc(%esp)
f01024a8:	f0 
f01024a9:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f01024b0:	f0 
f01024b1:	c7 44 24 04 aa 03 00 	movl   $0x3aa,0x4(%esp)
f01024b8:	00 
f01024b9:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01024c0:	e8 cf db ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01024c5:	ba 00 10 00 00       	mov    $0x1000,%edx
f01024ca:	89 f8                	mov    %edi,%eax
f01024cc:	e8 94 e4 ff ff       	call   f0100965 <check_va2pa>
f01024d1:	83 f8 ff             	cmp    $0xffffffff,%eax
f01024d4:	74 24                	je     f01024fa <mem_init+0x11b7>
f01024d6:	c7 44 24 0c f0 4a 10 	movl   $0xf0104af0,0xc(%esp)
f01024dd:	f0 
f01024de:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f01024e5:	f0 
f01024e6:	c7 44 24 04 ab 03 00 	movl   $0x3ab,0x4(%esp)
f01024ed:	00 
f01024ee:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01024f5:	e8 9a db ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f01024fa:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01024ff:	74 24                	je     f0102525 <mem_init+0x11e2>
f0102501:	c7 44 24 0c 58 4f 10 	movl   $0xf0104f58,0xc(%esp)
f0102508:	f0 
f0102509:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102510:	f0 
f0102511:	c7 44 24 04 ac 03 00 	movl   $0x3ac,0x4(%esp)
f0102518:	00 
f0102519:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102520:	e8 6f db ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102525:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010252a:	74 24                	je     f0102550 <mem_init+0x120d>
f010252c:	c7 44 24 0c 26 4f 10 	movl   $0xf0104f26,0xc(%esp)
f0102533:	f0 
f0102534:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f010253b:	f0 
f010253c:	c7 44 24 04 ad 03 00 	movl   $0x3ad,0x4(%esp)
f0102543:	00 
f0102544:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f010254b:	e8 44 db ff ff       	call   f0100094 <_panic>
	
	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102550:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102557:	e8 c0 e9 ff ff       	call   f0100f1c <page_alloc>
f010255c:	85 c0                	test   %eax,%eax
f010255e:	74 04                	je     f0102564 <mem_init+0x1221>
f0102560:	39 c3                	cmp    %eax,%ebx
f0102562:	74 24                	je     f0102588 <mem_init+0x1245>
f0102564:	c7 44 24 0c 18 4b 10 	movl   $0xf0104b18,0xc(%esp)
f010256b:	f0 
f010256c:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102573:	f0 
f0102574:	c7 44 24 04 b0 03 00 	movl   $0x3b0,0x4(%esp)
f010257b:	00 
f010257c:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102583:	e8 0c db ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102588:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010258f:	e8 88 e9 ff ff       	call   f0100f1c <page_alloc>
f0102594:	85 c0                	test   %eax,%eax
f0102596:	74 24                	je     f01025bc <mem_init+0x1279>
f0102598:	c7 44 24 0c 7a 4e 10 	movl   $0xf0104e7a,0xc(%esp)
f010259f:	f0 
f01025a0:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f01025a7:	f0 
f01025a8:	c7 44 24 04 b3 03 00 	movl   $0x3b3,0x4(%esp)
f01025af:	00 
f01025b0:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01025b7:	e8 d8 da ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01025bc:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01025c1:	8b 08                	mov    (%eax),%ecx
f01025c3:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01025c9:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01025cc:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01025d2:	c1 fa 03             	sar    $0x3,%edx
f01025d5:	c1 e2 0c             	shl    $0xc,%edx
f01025d8:	39 d1                	cmp    %edx,%ecx
f01025da:	74 24                	je     f0102600 <mem_init+0x12bd>
f01025dc:	c7 44 24 0c bc 47 10 	movl   $0xf01047bc,0xc(%esp)
f01025e3:	f0 
f01025e4:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f01025eb:	f0 
f01025ec:	c7 44 24 04 b6 03 00 	movl   $0x3b6,0x4(%esp)
f01025f3:	00 
f01025f4:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01025fb:	e8 94 da ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102600:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102606:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102609:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010260e:	74 24                	je     f0102634 <mem_init+0x12f1>
f0102610:	c7 44 24 0c dd 4e 10 	movl   $0xf0104edd,0xc(%esp)
f0102617:	f0 
f0102618:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f010261f:	f0 
f0102620:	c7 44 24 04 b8 03 00 	movl   $0x3b8,0x4(%esp)
f0102627:	00 
f0102628:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f010262f:	e8 60 da ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102634:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102637:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010263d:	89 04 24             	mov    %eax,(%esp)
f0102640:	e8 68 e9 ff ff       	call   f0100fad <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102645:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010264c:	00 
f010264d:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f0102654:	00 
f0102655:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010265a:	89 04 24             	mov    %eax,(%esp)
f010265d:	e8 c9 e9 ff ff       	call   f010102b <pgdir_walk>
f0102662:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102665:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102668:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f010266e:	8b 7a 04             	mov    0x4(%edx),%edi
f0102671:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102677:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f010267d:	89 f8                	mov    %edi,%eax
f010267f:	c1 e8 0c             	shr    $0xc,%eax
f0102682:	39 c8                	cmp    %ecx,%eax
f0102684:	72 20                	jb     f01026a6 <mem_init+0x1363>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102686:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010268a:	c7 44 24 08 64 44 10 	movl   $0xf0104464,0x8(%esp)
f0102691:	f0 
f0102692:	c7 44 24 04 bf 03 00 	movl   $0x3bf,0x4(%esp)
f0102699:	00 
f010269a:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01026a1:	e8 ee d9 ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01026a6:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f01026ac:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f01026af:	74 24                	je     f01026d5 <mem_init+0x1392>
f01026b1:	c7 44 24 0c 69 4f 10 	movl   $0xf0104f69,0xc(%esp)
f01026b8:	f0 
f01026b9:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f01026c0:	f0 
f01026c1:	c7 44 24 04 c0 03 00 	movl   $0x3c0,0x4(%esp)
f01026c8:	00 
f01026c9:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01026d0:	e8 bf d9 ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01026d5:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f01026dc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01026df:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01026e5:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01026eb:	c1 f8 03             	sar    $0x3,%eax
f01026ee:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01026f1:	89 c2                	mov    %eax,%edx
f01026f3:	c1 ea 0c             	shr    $0xc,%edx
f01026f6:	39 d1                	cmp    %edx,%ecx
f01026f8:	77 20                	ja     f010271a <mem_init+0x13d7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01026fa:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01026fe:	c7 44 24 08 64 44 10 	movl   $0xf0104464,0x8(%esp)
f0102705:	f0 
f0102706:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010270d:	00 
f010270e:	c7 04 24 d0 4c 10 f0 	movl   $0xf0104cd0,(%esp)
f0102715:	e8 7a d9 ff ff       	call   f0100094 <_panic>
	
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010271a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102721:	00 
f0102722:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102729:	00 
	return (void *)(pa + KERNBASE);
f010272a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010272f:	89 04 24             	mov    %eax,(%esp)
f0102732:	e8 60 13 00 00       	call   f0103a97 <memset>
	page_free(pp0);
f0102737:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010273a:	89 3c 24             	mov    %edi,(%esp)
f010273d:	e8 6b e8 ff ff       	call   f0100fad <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102742:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102749:	00 
f010274a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102751:	00 
f0102752:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102757:	89 04 24             	mov    %eax,(%esp)
f010275a:	e8 cc e8 ff ff       	call   f010102b <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010275f:	89 fa                	mov    %edi,%edx
f0102761:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0102767:	c1 fa 03             	sar    $0x3,%edx
f010276a:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010276d:	89 d0                	mov    %edx,%eax
f010276f:	c1 e8 0c             	shr    $0xc,%eax
f0102772:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0102778:	72 20                	jb     f010279a <mem_init+0x1457>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010277a:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010277e:	c7 44 24 08 64 44 10 	movl   $0xf0104464,0x8(%esp)
f0102785:	f0 
f0102786:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010278d:	00 
f010278e:	c7 04 24 d0 4c 10 f0 	movl   $0xf0104cd0,(%esp)
f0102795:	e8 fa d8 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f010279a:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01027a0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01027a3:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01027a9:	f6 00 01             	testb  $0x1,(%eax)
f01027ac:	74 24                	je     f01027d2 <mem_init+0x148f>
f01027ae:	c7 44 24 0c 81 4f 10 	movl   $0xf0104f81,0xc(%esp)
f01027b5:	f0 
f01027b6:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f01027bd:	f0 
f01027be:	c7 44 24 04 ca 03 00 	movl   $0x3ca,0x4(%esp)
f01027c5:	00 
f01027c6:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01027cd:	e8 c2 d8 ff ff       	call   f0100094 <_panic>
f01027d2:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01027d5:	39 d0                	cmp    %edx,%eax
f01027d7:	75 d0                	jne    f01027a9 <mem_init+0x1466>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01027d9:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01027de:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01027e4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01027e7:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01027ed:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01027f0:	89 0d 40 75 11 f0    	mov    %ecx,0xf0117540

	// free the pages we took
	page_free(pp0);
f01027f6:	89 04 24             	mov    %eax,(%esp)
f01027f9:	e8 af e7 ff ff       	call   f0100fad <page_free>
	page_free(pp1);
f01027fe:	89 1c 24             	mov    %ebx,(%esp)
f0102801:	e8 a7 e7 ff ff       	call   f0100fad <page_free>
	page_free(pp2);
f0102806:	89 34 24             	mov    %esi,(%esp)
f0102809:	e8 9f e7 ff ff       	call   f0100fad <page_free>

	cprintf("check_page() succeeded!\n");
f010280e:	c7 04 24 98 4f 10 f0 	movl   $0xf0104f98,(%esp)
f0102815:	e8 18 07 00 00       	call   f0102f32 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, sizeof(struct PageInfo) * npages,PADDR(pages), PTE_U | PTE_P);
f010281a:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010281f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102824:	77 20                	ja     f0102846 <mem_init+0x1503>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102826:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010282a:	c7 44 24 08 88 44 10 	movl   $0xf0104488,0x8(%esp)
f0102831:	f0 
f0102832:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
f0102839:	00 
f010283a:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102841:	e8 4e d8 ff ff       	call   f0100094 <_panic>
f0102846:	8b 3d 64 79 11 f0    	mov    0xf0117964,%edi
f010284c:	8d 0c fd 00 00 00 00 	lea    0x0(,%edi,8),%ecx
f0102853:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f010285a:	00 
	return (physaddr_t)kva - KERNBASE;
f010285b:	05 00 00 00 10       	add    $0x10000000,%eax
f0102860:	89 04 24             	mov    %eax,(%esp)
f0102863:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102868:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010286d:	e8 c8 e8 ff ff       	call   f010113a <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102872:	bb 00 d0 10 f0       	mov    $0xf010d000,%ebx
f0102877:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f010287d:	77 20                	ja     f010289f <mem_init+0x155c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010287f:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102883:	c7 44 24 08 88 44 10 	movl   $0xf0104488,0x8(%esp)
f010288a:	f0 
f010288b:	c7 44 24 04 c5 00 00 	movl   $0xc5,0x4(%esp)
f0102892:	00 
f0102893:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f010289a:	e8 f5 d7 ff ff       	call   f0100094 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W | PTE_P);
f010289f:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f01028a6:	00 
f01028a7:	c7 04 24 00 d0 10 00 	movl   $0x10d000,(%esp)
f01028ae:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01028b3:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01028b8:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01028bd:	e8 78 e8 ff ff       	call   f010113a <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	size_t size = ROUNDUP(0xFFFFFFFF - KERNBASE + 1, PGSIZE);
	boot_map_region(kern_pgdir, KERNBASE, size, 0, PTE_W | PTE_P);
f01028c2:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f01028c9:	00 
f01028ca:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01028d1:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01028d6:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01028db:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01028e0:	e8 55 e8 ff ff       	call   f010113a <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01028e5:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01028eb:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f01028f0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01028f3:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01028fa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01028ff:	89 45 d0             	mov    %eax,-0x30(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102902:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0102907:	89 45 cc             	mov    %eax,-0x34(%ebp)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010290a:	89 45 c8             	mov    %eax,-0x38(%ebp)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f010290d:	05 00 00 00 10       	add    $0x10000000,%eax
f0102912:	89 45 c4             	mov    %eax,-0x3c(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102915:	be 00 00 00 00       	mov    $0x0,%esi
f010291a:	eb 6d                	jmp    f0102989 <mem_init+0x1646>
f010291c:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102922:	89 f8                	mov    %edi,%eax
f0102924:	e8 3c e0 ff ff       	call   f0100965 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102929:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f0102930:	77 23                	ja     f0102955 <mem_init+0x1612>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102932:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102935:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102939:	c7 44 24 08 88 44 10 	movl   $0xf0104488,0x8(%esp)
f0102940:	f0 
f0102941:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f0102948:	00 
f0102949:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102950:	e8 3f d7 ff ff       	call   f0100094 <_panic>
f0102955:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0102958:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010295b:	39 c2                	cmp    %eax,%edx
f010295d:	74 24                	je     f0102983 <mem_init+0x1640>
f010295f:	c7 44 24 0c 3c 4b 10 	movl   $0xf0104b3c,0xc(%esp)
f0102966:	f0 
f0102967:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f010296e:	f0 
f010296f:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f0102976:	00 
f0102977:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f010297e:	e8 11 d7 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102983:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102989:	39 75 d0             	cmp    %esi,-0x30(%ebp)
f010298c:	77 8e                	ja     f010291c <mem_init+0x15d9>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010298e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102991:	c1 e0 0c             	shl    $0xc,%eax
f0102994:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102997:	be 00 00 00 00       	mov    $0x0,%esi
f010299c:	eb 3b                	jmp    f01029d9 <mem_init+0x1696>
f010299e:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01029a4:	89 f8                	mov    %edi,%eax
f01029a6:	e8 ba df ff ff       	call   f0100965 <check_va2pa>
f01029ab:	39 c6                	cmp    %eax,%esi
f01029ad:	74 24                	je     f01029d3 <mem_init+0x1690>
f01029af:	c7 44 24 0c 70 4b 10 	movl   $0xf0104b70,0xc(%esp)
f01029b6:	f0 
f01029b7:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f01029be:	f0 
f01029bf:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
f01029c6:	00 
f01029c7:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f01029ce:	e8 c1 d6 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01029d3:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01029d9:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01029dc:	72 c0                	jb     f010299e <mem_init+0x165b>
f01029de:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f01029e3:	81 c3 00 80 00 20    	add    $0x20008000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01029e9:	89 f2                	mov    %esi,%edx
f01029eb:	89 f8                	mov    %edi,%eax
f01029ed:	e8 73 df ff ff       	call   f0100965 <check_va2pa>
f01029f2:	8d 14 33             	lea    (%ebx,%esi,1),%edx
f01029f5:	39 d0                	cmp    %edx,%eax
f01029f7:	74 24                	je     f0102a1d <mem_init+0x16da>
f01029f9:	c7 44 24 0c 98 4b 10 	movl   $0xf0104b98,0xc(%esp)
f0102a00:	f0 
f0102a01:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102a08:	f0 
f0102a09:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f0102a10:	00 
f0102a11:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102a18:	e8 77 d6 ff ff       	call   f0100094 <_panic>
f0102a1d:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102a23:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102a29:	75 be                	jne    f01029e9 <mem_init+0x16a6>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102a2b:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102a30:	89 f8                	mov    %edi,%eax
f0102a32:	e8 2e df ff ff       	call   f0100965 <check_va2pa>
f0102a37:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102a3a:	75 0a                	jne    f0102a46 <mem_init+0x1703>
f0102a3c:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a41:	e9 f0 00 00 00       	jmp    f0102b36 <mem_init+0x17f3>
f0102a46:	c7 44 24 0c e0 4b 10 	movl   $0xf0104be0,0xc(%esp)
f0102a4d:	f0 
f0102a4e:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102a55:	f0 
f0102a56:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
f0102a5d:	00 
f0102a5e:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102a65:	e8 2a d6 ff ff       	call   f0100094 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102a6a:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102a6f:	72 3c                	jb     f0102aad <mem_init+0x176a>
f0102a71:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102a76:	76 07                	jbe    f0102a7f <mem_init+0x173c>
f0102a78:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102a7d:	75 2e                	jne    f0102aad <mem_init+0x176a>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102a7f:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0102a83:	0f 85 aa 00 00 00    	jne    f0102b33 <mem_init+0x17f0>
f0102a89:	c7 44 24 0c b1 4f 10 	movl   $0xf0104fb1,0xc(%esp)
f0102a90:	f0 
f0102a91:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102a98:	f0 
f0102a99:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f0102aa0:	00 
f0102aa1:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102aa8:	e8 e7 d5 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102aad:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102ab2:	76 55                	jbe    f0102b09 <mem_init+0x17c6>
				assert(pgdir[i] & PTE_P);
f0102ab4:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0102ab7:	f6 c2 01             	test   $0x1,%dl
f0102aba:	75 24                	jne    f0102ae0 <mem_init+0x179d>
f0102abc:	c7 44 24 0c b1 4f 10 	movl   $0xf0104fb1,0xc(%esp)
f0102ac3:	f0 
f0102ac4:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102acb:	f0 
f0102acc:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f0102ad3:	00 
f0102ad4:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102adb:	e8 b4 d5 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f0102ae0:	f6 c2 02             	test   $0x2,%dl
f0102ae3:	75 4e                	jne    f0102b33 <mem_init+0x17f0>
f0102ae5:	c7 44 24 0c c2 4f 10 	movl   $0xf0104fc2,0xc(%esp)
f0102aec:	f0 
f0102aed:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102af4:	f0 
f0102af5:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f0102afc:	00 
f0102afd:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102b04:	e8 8b d5 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102b09:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102b0d:	74 24                	je     f0102b33 <mem_init+0x17f0>
f0102b0f:	c7 44 24 0c d3 4f 10 	movl   $0xf0104fd3,0xc(%esp)
f0102b16:	f0 
f0102b17:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102b1e:	f0 
f0102b1f:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0102b26:	00 
f0102b27:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102b2e:	e8 61 d5 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102b33:	83 c0 01             	add    $0x1,%eax
f0102b36:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102b3b:	0f 85 29 ff ff ff    	jne    f0102a6a <mem_init+0x1727>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102b41:	c7 04 24 10 4c 10 f0 	movl   $0xf0104c10,(%esp)
f0102b48:	e8 e5 03 00 00       	call   f0102f32 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102b4d:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b52:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b57:	77 20                	ja     f0102b79 <mem_init+0x1836>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b59:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102b5d:	c7 44 24 08 88 44 10 	movl   $0xf0104488,0x8(%esp)
f0102b64:	f0 
f0102b65:	c7 44 24 04 da 00 00 	movl   $0xda,0x4(%esp)
f0102b6c:	00 
f0102b6d:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102b74:	e8 1b d5 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102b79:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102b7e:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102b81:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b86:	e8 ce de ff ff       	call   f0100a59 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102b8b:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102b8e:	83 e0 f3             	and    $0xfffffff3,%eax
f0102b91:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102b96:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102b99:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102ba0:	e8 77 e3 ff ff       	call   f0100f1c <page_alloc>
f0102ba5:	89 c3                	mov    %eax,%ebx
f0102ba7:	85 c0                	test   %eax,%eax
f0102ba9:	75 24                	jne    f0102bcf <mem_init+0x188c>
f0102bab:	c7 44 24 0c cf 4d 10 	movl   $0xf0104dcf,0xc(%esp)
f0102bb2:	f0 
f0102bb3:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102bba:	f0 
f0102bbb:	c7 44 24 04 e5 03 00 	movl   $0x3e5,0x4(%esp)
f0102bc2:	00 
f0102bc3:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102bca:	e8 c5 d4 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102bcf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102bd6:	e8 41 e3 ff ff       	call   f0100f1c <page_alloc>
f0102bdb:	89 c7                	mov    %eax,%edi
f0102bdd:	85 c0                	test   %eax,%eax
f0102bdf:	75 24                	jne    f0102c05 <mem_init+0x18c2>
f0102be1:	c7 44 24 0c e5 4d 10 	movl   $0xf0104de5,0xc(%esp)
f0102be8:	f0 
f0102be9:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102bf0:	f0 
f0102bf1:	c7 44 24 04 e6 03 00 	movl   $0x3e6,0x4(%esp)
f0102bf8:	00 
f0102bf9:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102c00:	e8 8f d4 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102c05:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102c0c:	e8 0b e3 ff ff       	call   f0100f1c <page_alloc>
f0102c11:	89 c6                	mov    %eax,%esi
f0102c13:	85 c0                	test   %eax,%eax
f0102c15:	75 24                	jne    f0102c3b <mem_init+0x18f8>
f0102c17:	c7 44 24 0c fb 4d 10 	movl   $0xf0104dfb,0xc(%esp)
f0102c1e:	f0 
f0102c1f:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102c26:	f0 
f0102c27:	c7 44 24 04 e7 03 00 	movl   $0x3e7,0x4(%esp)
f0102c2e:	00 
f0102c2f:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102c36:	e8 59 d4 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f0102c3b:	89 1c 24             	mov    %ebx,(%esp)
f0102c3e:	e8 6a e3 ff ff       	call   f0100fad <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0102c43:	89 f8                	mov    %edi,%eax
f0102c45:	e8 d6 dc ff ff       	call   f0100920 <page2kva>
f0102c4a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c51:	00 
f0102c52:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102c59:	00 
f0102c5a:	89 04 24             	mov    %eax,(%esp)
f0102c5d:	e8 35 0e 00 00       	call   f0103a97 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0102c62:	89 f0                	mov    %esi,%eax
f0102c64:	e8 b7 dc ff ff       	call   f0100920 <page2kva>
f0102c69:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c70:	00 
f0102c71:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102c78:	00 
f0102c79:	89 04 24             	mov    %eax,(%esp)
f0102c7c:	e8 16 0e 00 00       	call   f0103a97 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102c81:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102c88:	00 
f0102c89:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c90:	00 
f0102c91:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102c95:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102c9a:	89 04 24             	mov    %eax,(%esp)
f0102c9d:	e8 df e5 ff ff       	call   f0101281 <page_insert>
	assert(pp1->pp_ref == 1);
f0102ca2:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102ca7:	74 24                	je     f0102ccd <mem_init+0x198a>
f0102ca9:	c7 44 24 0c cc 4e 10 	movl   $0xf0104ecc,0xc(%esp)
f0102cb0:	f0 
f0102cb1:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102cb8:	f0 
f0102cb9:	c7 44 24 04 ec 03 00 	movl   $0x3ec,0x4(%esp)
f0102cc0:	00 
f0102cc1:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102cc8:	e8 c7 d3 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102ccd:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102cd4:	01 01 01 
f0102cd7:	74 24                	je     f0102cfd <mem_init+0x19ba>
f0102cd9:	c7 44 24 0c 30 4c 10 	movl   $0xf0104c30,0xc(%esp)
f0102ce0:	f0 
f0102ce1:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102ce8:	f0 
f0102ce9:	c7 44 24 04 ed 03 00 	movl   $0x3ed,0x4(%esp)
f0102cf0:	00 
f0102cf1:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102cf8:	e8 97 d3 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102cfd:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102d04:	00 
f0102d05:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102d0c:	00 
f0102d0d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102d11:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102d16:	89 04 24             	mov    %eax,(%esp)
f0102d19:	e8 63 e5 ff ff       	call   f0101281 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102d1e:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102d25:	02 02 02 
f0102d28:	74 24                	je     f0102d4e <mem_init+0x1a0b>
f0102d2a:	c7 44 24 0c 54 4c 10 	movl   $0xf0104c54,0xc(%esp)
f0102d31:	f0 
f0102d32:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102d39:	f0 
f0102d3a:	c7 44 24 04 ef 03 00 	movl   $0x3ef,0x4(%esp)
f0102d41:	00 
f0102d42:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102d49:	e8 46 d3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102d4e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102d53:	74 24                	je     f0102d79 <mem_init+0x1a36>
f0102d55:	c7 44 24 0c ee 4e 10 	movl   $0xf0104eee,0xc(%esp)
f0102d5c:	f0 
f0102d5d:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102d64:	f0 
f0102d65:	c7 44 24 04 f0 03 00 	movl   $0x3f0,0x4(%esp)
f0102d6c:	00 
f0102d6d:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102d74:	e8 1b d3 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102d79:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102d7e:	74 24                	je     f0102da4 <mem_init+0x1a61>
f0102d80:	c7 44 24 0c 58 4f 10 	movl   $0xf0104f58,0xc(%esp)
f0102d87:	f0 
f0102d88:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102d8f:	f0 
f0102d90:	c7 44 24 04 f1 03 00 	movl   $0x3f1,0x4(%esp)
f0102d97:	00 
f0102d98:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102d9f:	e8 f0 d2 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102da4:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102dab:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102dae:	89 f0                	mov    %esi,%eax
f0102db0:	e8 6b db ff ff       	call   f0100920 <page2kva>
f0102db5:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0102dbb:	74 24                	je     f0102de1 <mem_init+0x1a9e>
f0102dbd:	c7 44 24 0c 78 4c 10 	movl   $0xf0104c78,0xc(%esp)
f0102dc4:	f0 
f0102dc5:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102dcc:	f0 
f0102dcd:	c7 44 24 04 f3 03 00 	movl   $0x3f3,0x4(%esp)
f0102dd4:	00 
f0102dd5:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102ddc:	e8 b3 d2 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102de1:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102de8:	00 
f0102de9:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102dee:	89 04 24             	mov    %eax,(%esp)
f0102df1:	e8 4d e4 ff ff       	call   f0101243 <page_remove>
	assert(pp2->pp_ref == 0);
f0102df6:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102dfb:	74 24                	je     f0102e21 <mem_init+0x1ade>
f0102dfd:	c7 44 24 0c 26 4f 10 	movl   $0xf0104f26,0xc(%esp)
f0102e04:	f0 
f0102e05:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102e0c:	f0 
f0102e0d:	c7 44 24 04 f5 03 00 	movl   $0x3f5,0x4(%esp)
f0102e14:	00 
f0102e15:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102e1c:	e8 73 d2 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102e21:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102e26:	8b 08                	mov    (%eax),%ecx
f0102e28:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102e2e:	89 da                	mov    %ebx,%edx
f0102e30:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0102e36:	c1 fa 03             	sar    $0x3,%edx
f0102e39:	c1 e2 0c             	shl    $0xc,%edx
f0102e3c:	39 d1                	cmp    %edx,%ecx
f0102e3e:	74 24                	je     f0102e64 <mem_init+0x1b21>
f0102e40:	c7 44 24 0c bc 47 10 	movl   $0xf01047bc,0xc(%esp)
f0102e47:	f0 
f0102e48:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102e4f:	f0 
f0102e50:	c7 44 24 04 f8 03 00 	movl   $0x3f8,0x4(%esp)
f0102e57:	00 
f0102e58:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102e5f:	e8 30 d2 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102e64:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102e6a:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102e6f:	74 24                	je     f0102e95 <mem_init+0x1b52>
f0102e71:	c7 44 24 0c dd 4e 10 	movl   $0xf0104edd,0xc(%esp)
f0102e78:	f0 
f0102e79:	c7 44 24 08 f6 4c 10 	movl   $0xf0104cf6,0x8(%esp)
f0102e80:	f0 
f0102e81:	c7 44 24 04 fa 03 00 	movl   $0x3fa,0x4(%esp)
f0102e88:	00 
f0102e89:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f0102e90:	e8 ff d1 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102e95:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102e9b:	89 1c 24             	mov    %ebx,(%esp)
f0102e9e:	e8 0a e1 ff ff       	call   f0100fad <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102ea3:	c7 04 24 a4 4c 10 f0 	movl   $0xf0104ca4,(%esp)
f0102eaa:	e8 83 00 00 00       	call   f0102f32 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102eaf:	83 c4 4c             	add    $0x4c,%esp
f0102eb2:	5b                   	pop    %ebx
f0102eb3:	5e                   	pop    %esi
f0102eb4:	5f                   	pop    %edi
f0102eb5:	5d                   	pop    %ebp
f0102eb6:	c3                   	ret    

f0102eb7 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102eb7:	55                   	push   %ebp
f0102eb8:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102eba:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ebd:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102ec0:	5d                   	pop    %ebp
f0102ec1:	c3                   	ret    

f0102ec2 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102ec2:	55                   	push   %ebp
f0102ec3:	89 e5                	mov    %esp,%ebp
f0102ec5:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102ec9:	ba 70 00 00 00       	mov    $0x70,%edx
f0102ece:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102ecf:	b2 71                	mov    $0x71,%dl
f0102ed1:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102ed2:	0f b6 c0             	movzbl %al,%eax
}
f0102ed5:	5d                   	pop    %ebp
f0102ed6:	c3                   	ret    

f0102ed7 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102ed7:	55                   	push   %ebp
f0102ed8:	89 e5                	mov    %esp,%ebp
f0102eda:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102ede:	ba 70 00 00 00       	mov    $0x70,%edx
f0102ee3:	ee                   	out    %al,(%dx)
f0102ee4:	b2 71                	mov    $0x71,%dl
f0102ee6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ee9:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102eea:	5d                   	pop    %ebp
f0102eeb:	c3                   	ret    

f0102eec <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102eec:	55                   	push   %ebp
f0102eed:	89 e5                	mov    %esp,%ebp
f0102eef:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102ef2:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ef5:	89 04 24             	mov    %eax,(%esp)
f0102ef8:	e8 f4 d6 ff ff       	call   f01005f1 <cputchar>
	*cnt++;
}
f0102efd:	c9                   	leave  
f0102efe:	c3                   	ret    

f0102eff <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102eff:	55                   	push   %ebp
f0102f00:	89 e5                	mov    %esp,%ebp
f0102f02:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102f05:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102f0c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f0f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102f13:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f16:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102f1a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102f1d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102f21:	c7 04 24 ec 2e 10 f0 	movl   $0xf0102eec,(%esp)
f0102f28:	e8 b1 04 00 00       	call   f01033de <vprintfmt>
	return cnt;
}
f0102f2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102f30:	c9                   	leave  
f0102f31:	c3                   	ret    

f0102f32 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102f32:	55                   	push   %ebp
f0102f33:	89 e5                	mov    %esp,%ebp
f0102f35:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102f38:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102f3b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102f3f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f42:	89 04 24             	mov    %eax,(%esp)
f0102f45:	e8 b5 ff ff ff       	call   f0102eff <vcprintf>
	va_end(ap);

	return cnt;
}
f0102f4a:	c9                   	leave  
f0102f4b:	c3                   	ret    

f0102f4c <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102f4c:	55                   	push   %ebp
f0102f4d:	89 e5                	mov    %esp,%ebp
f0102f4f:	57                   	push   %edi
f0102f50:	56                   	push   %esi
f0102f51:	53                   	push   %ebx
f0102f52:	83 ec 10             	sub    $0x10,%esp
f0102f55:	89 c6                	mov    %eax,%esi
f0102f57:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102f5a:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102f5d:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102f60:	8b 1a                	mov    (%edx),%ebx
f0102f62:	8b 01                	mov    (%ecx),%eax
f0102f64:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102f67:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0102f6e:	eb 77                	jmp    f0102fe7 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0102f70:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102f73:	01 d8                	add    %ebx,%eax
f0102f75:	b9 02 00 00 00       	mov    $0x2,%ecx
f0102f7a:	99                   	cltd   
f0102f7b:	f7 f9                	idiv   %ecx
f0102f7d:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102f7f:	eb 01                	jmp    f0102f82 <stab_binsearch+0x36>
			m--;
f0102f81:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102f82:	39 d9                	cmp    %ebx,%ecx
f0102f84:	7c 1d                	jl     f0102fa3 <stab_binsearch+0x57>
f0102f86:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102f89:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102f8e:	39 fa                	cmp    %edi,%edx
f0102f90:	75 ef                	jne    f0102f81 <stab_binsearch+0x35>
f0102f92:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102f95:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102f98:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0102f9c:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102f9f:	73 18                	jae    f0102fb9 <stab_binsearch+0x6d>
f0102fa1:	eb 05                	jmp    f0102fa8 <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102fa3:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0102fa6:	eb 3f                	jmp    f0102fe7 <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102fa8:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0102fab:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0102fad:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102fb0:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102fb7:	eb 2e                	jmp    f0102fe7 <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102fb9:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102fbc:	73 15                	jae    f0102fd3 <stab_binsearch+0x87>
			*region_right = m - 1;
f0102fbe:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102fc1:	48                   	dec    %eax
f0102fc2:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102fc5:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102fc8:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102fca:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102fd1:	eb 14                	jmp    f0102fe7 <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102fd3:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102fd6:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0102fd9:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0102fdb:	ff 45 0c             	incl   0xc(%ebp)
f0102fde:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102fe0:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102fe7:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102fea:	7e 84                	jle    f0102f70 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102fec:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102ff0:	75 0d                	jne    f0102fff <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0102ff2:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102ff5:	8b 00                	mov    (%eax),%eax
f0102ff7:	48                   	dec    %eax
f0102ff8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102ffb:	89 07                	mov    %eax,(%edi)
f0102ffd:	eb 22                	jmp    f0103021 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102fff:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103002:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103004:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0103007:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103009:	eb 01                	jmp    f010300c <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010300b:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010300c:	39 c1                	cmp    %eax,%ecx
f010300e:	7d 0c                	jge    f010301c <stab_binsearch+0xd0>
f0103010:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0103013:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0103018:	39 fa                	cmp    %edi,%edx
f010301a:	75 ef                	jne    f010300b <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f010301c:	8b 7d e8             	mov    -0x18(%ebp),%edi
f010301f:	89 07                	mov    %eax,(%edi)
	}
}
f0103021:	83 c4 10             	add    $0x10,%esp
f0103024:	5b                   	pop    %ebx
f0103025:	5e                   	pop    %esi
f0103026:	5f                   	pop    %edi
f0103027:	5d                   	pop    %ebp
f0103028:	c3                   	ret    

f0103029 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103029:	55                   	push   %ebp
f010302a:	89 e5                	mov    %esp,%ebp
f010302c:	57                   	push   %edi
f010302d:	56                   	push   %esi
f010302e:	53                   	push   %ebx
f010302f:	83 ec 3c             	sub    $0x3c,%esp
f0103032:	8b 75 08             	mov    0x8(%ebp),%esi
f0103035:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103038:	c7 03 e1 4f 10 f0    	movl   $0xf0104fe1,(%ebx)
	info->eip_line = 0;
f010303e:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0103045:	c7 43 08 e1 4f 10 f0 	movl   $0xf0104fe1,0x8(%ebx)
	info->eip_fn_namelen = 9;
f010304c:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0103053:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0103056:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010305d:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0103063:	76 12                	jbe    f0103077 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103065:	b8 00 cf 10 f0       	mov    $0xf010cf00,%eax
f010306a:	3d f9 b0 10 f0       	cmp    $0xf010b0f9,%eax
f010306f:	0f 86 cd 01 00 00    	jbe    f0103242 <debuginfo_eip+0x219>
f0103075:	eb 1c                	jmp    f0103093 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0103077:	c7 44 24 08 eb 4f 10 	movl   $0xf0104feb,0x8(%esp)
f010307e:	f0 
f010307f:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0103086:	00 
f0103087:	c7 04 24 f8 4f 10 f0 	movl   $0xf0104ff8,(%esp)
f010308e:	e8 01 d0 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103093:	80 3d ff ce 10 f0 00 	cmpb   $0x0,0xf010ceff
f010309a:	0f 85 a9 01 00 00    	jne    f0103249 <debuginfo_eip+0x220>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01030a0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01030a7:	b8 f8 b0 10 f0       	mov    $0xf010b0f8,%eax
f01030ac:	2d 30 52 10 f0       	sub    $0xf0105230,%eax
f01030b1:	c1 f8 02             	sar    $0x2,%eax
f01030b4:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01030ba:	83 e8 01             	sub    $0x1,%eax
f01030bd:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01030c0:	89 74 24 04          	mov    %esi,0x4(%esp)
f01030c4:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f01030cb:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01030ce:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01030d1:	b8 30 52 10 f0       	mov    $0xf0105230,%eax
f01030d6:	e8 71 fe ff ff       	call   f0102f4c <stab_binsearch>
	if (lfile == 0)
f01030db:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030de:	85 c0                	test   %eax,%eax
f01030e0:	0f 84 6a 01 00 00    	je     f0103250 <debuginfo_eip+0x227>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01030e6:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01030e9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01030ec:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01030ef:	89 74 24 04          	mov    %esi,0x4(%esp)
f01030f3:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f01030fa:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01030fd:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103100:	b8 30 52 10 f0       	mov    $0xf0105230,%eax
f0103105:	e8 42 fe ff ff       	call   f0102f4c <stab_binsearch>

	if (lfun <= rfun) {
f010310a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010310d:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103110:	39 d0                	cmp    %edx,%eax
f0103112:	7f 3d                	jg     f0103151 <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103114:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0103117:	8d b9 30 52 10 f0    	lea    -0xfefadd0(%ecx),%edi
f010311d:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0103120:	8b 89 30 52 10 f0    	mov    -0xfefadd0(%ecx),%ecx
f0103126:	bf 00 cf 10 f0       	mov    $0xf010cf00,%edi
f010312b:	81 ef f9 b0 10 f0    	sub    $0xf010b0f9,%edi
f0103131:	39 f9                	cmp    %edi,%ecx
f0103133:	73 09                	jae    f010313e <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103135:	81 c1 f9 b0 10 f0    	add    $0xf010b0f9,%ecx
f010313b:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f010313e:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0103141:	8b 4f 08             	mov    0x8(%edi),%ecx
f0103144:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0103147:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0103149:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010314c:	89 55 d0             	mov    %edx,-0x30(%ebp)
f010314f:	eb 0f                	jmp    f0103160 <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103151:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0103154:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103157:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010315a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010315d:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103160:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0103167:	00 
f0103168:	8b 43 08             	mov    0x8(%ebx),%eax
f010316b:	89 04 24             	mov    %eax,(%esp)
f010316e:	e8 08 09 00 00       	call   f0103a7b <strfind>
f0103173:	2b 43 08             	sub    0x8(%ebx),%eax
f0103176:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
f0103179:	89 74 24 04          	mov    %esi,0x4(%esp)
f010317d:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0103184:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103187:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010318a:	b8 30 52 10 f0       	mov    $0xf0105230,%eax
f010318f:	e8 b8 fd ff ff       	call   f0102f4c <stab_binsearch>
	if (lline > rline) {
f0103194:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103197:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f010319a:	0f 8f b7 00 00 00    	jg     f0103257 <debuginfo_eip+0x22e>
		return -1; //Did not find the line number in the stab
	}
	info->eip_line = stabs[lline].n_desc; //If found update the info object with the correct line number
f01031a0:	6b c0 0c             	imul   $0xc,%eax,%eax
f01031a3:	0f b7 80 36 52 10 f0 	movzwl -0xfefadca(%eax),%eax
f01031aa:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01031ad:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031b0:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01031b3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01031b6:	6b d0 0c             	imul   $0xc,%eax,%edx
f01031b9:	81 c2 30 52 10 f0    	add    $0xf0105230,%edx
f01031bf:	eb 06                	jmp    f01031c7 <debuginfo_eip+0x19e>
f01031c1:	83 e8 01             	sub    $0x1,%eax
f01031c4:	83 ea 0c             	sub    $0xc,%edx
f01031c7:	89 c6                	mov    %eax,%esi
f01031c9:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f01031cc:	7f 33                	jg     f0103201 <debuginfo_eip+0x1d8>
	       && stabs[lline].n_type != N_SOL
f01031ce:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01031d2:	80 f9 84             	cmp    $0x84,%cl
f01031d5:	74 0b                	je     f01031e2 <debuginfo_eip+0x1b9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01031d7:	80 f9 64             	cmp    $0x64,%cl
f01031da:	75 e5                	jne    f01031c1 <debuginfo_eip+0x198>
f01031dc:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f01031e0:	74 df                	je     f01031c1 <debuginfo_eip+0x198>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01031e2:	6b f6 0c             	imul   $0xc,%esi,%esi
f01031e5:	8b 86 30 52 10 f0    	mov    -0xfefadd0(%esi),%eax
f01031eb:	ba 00 cf 10 f0       	mov    $0xf010cf00,%edx
f01031f0:	81 ea f9 b0 10 f0    	sub    $0xf010b0f9,%edx
f01031f6:	39 d0                	cmp    %edx,%eax
f01031f8:	73 07                	jae    f0103201 <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01031fa:	05 f9 b0 10 f0       	add    $0xf010b0f9,%eax
f01031ff:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103201:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103204:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103207:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010320c:	39 ca                	cmp    %ecx,%edx
f010320e:	7d 53                	jge    f0103263 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
f0103210:	8d 42 01             	lea    0x1(%edx),%eax
f0103213:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103216:	89 c2                	mov    %eax,%edx
f0103218:	6b c0 0c             	imul   $0xc,%eax,%eax
f010321b:	05 30 52 10 f0       	add    $0xf0105230,%eax
f0103220:	89 ce                	mov    %ecx,%esi
f0103222:	eb 04                	jmp    f0103228 <debuginfo_eip+0x1ff>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103224:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103228:	39 d6                	cmp    %edx,%esi
f010322a:	7e 32                	jle    f010325e <debuginfo_eip+0x235>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010322c:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0103230:	83 c2 01             	add    $0x1,%edx
f0103233:	83 c0 0c             	add    $0xc,%eax
f0103236:	80 f9 a0             	cmp    $0xa0,%cl
f0103239:	74 e9                	je     f0103224 <debuginfo_eip+0x1fb>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010323b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103240:	eb 21                	jmp    f0103263 <debuginfo_eip+0x23a>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103242:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103247:	eb 1a                	jmp    f0103263 <debuginfo_eip+0x23a>
f0103249:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010324e:	eb 13                	jmp    f0103263 <debuginfo_eip+0x23a>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103250:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103255:	eb 0c                	jmp    f0103263 <debuginfo_eip+0x23a>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
	if (lline > rline) {
		return -1; //Did not find the line number in the stab
f0103257:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010325c:	eb 05                	jmp    f0103263 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010325e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103263:	83 c4 3c             	add    $0x3c,%esp
f0103266:	5b                   	pop    %ebx
f0103267:	5e                   	pop    %esi
f0103268:	5f                   	pop    %edi
f0103269:	5d                   	pop    %ebp
f010326a:	c3                   	ret    
f010326b:	66 90                	xchg   %ax,%ax
f010326d:	66 90                	xchg   %ax,%ax
f010326f:	90                   	nop

f0103270 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103270:	55                   	push   %ebp
f0103271:	89 e5                	mov    %esp,%ebp
f0103273:	57                   	push   %edi
f0103274:	56                   	push   %esi
f0103275:	53                   	push   %ebx
f0103276:	83 ec 3c             	sub    $0x3c,%esp
f0103279:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010327c:	89 d7                	mov    %edx,%edi
f010327e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103281:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103284:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103287:	89 c3                	mov    %eax,%ebx
f0103289:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010328c:	8b 45 10             	mov    0x10(%ebp),%eax
f010328f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103292:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103297:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010329a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010329d:	39 d9                	cmp    %ebx,%ecx
f010329f:	72 05                	jb     f01032a6 <printnum+0x36>
f01032a1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f01032a4:	77 69                	ja     f010330f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01032a6:	8b 4d 18             	mov    0x18(%ebp),%ecx
f01032a9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01032ad:	83 ee 01             	sub    $0x1,%esi
f01032b0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01032b4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01032b8:	8b 44 24 08          	mov    0x8(%esp),%eax
f01032bc:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01032c0:	89 c3                	mov    %eax,%ebx
f01032c2:	89 d6                	mov    %edx,%esi
f01032c4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01032c7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01032ca:	89 54 24 08          	mov    %edx,0x8(%esp)
f01032ce:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01032d2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032d5:	89 04 24             	mov    %eax,(%esp)
f01032d8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01032db:	89 44 24 04          	mov    %eax,0x4(%esp)
f01032df:	e8 bc 09 00 00       	call   f0103ca0 <__udivdi3>
f01032e4:	89 d9                	mov    %ebx,%ecx
f01032e6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01032ea:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01032ee:	89 04 24             	mov    %eax,(%esp)
f01032f1:	89 54 24 04          	mov    %edx,0x4(%esp)
f01032f5:	89 fa                	mov    %edi,%edx
f01032f7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01032fa:	e8 71 ff ff ff       	call   f0103270 <printnum>
f01032ff:	eb 1b                	jmp    f010331c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103301:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103305:	8b 45 18             	mov    0x18(%ebp),%eax
f0103308:	89 04 24             	mov    %eax,(%esp)
f010330b:	ff d3                	call   *%ebx
f010330d:	eb 03                	jmp    f0103312 <printnum+0xa2>
f010330f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103312:	83 ee 01             	sub    $0x1,%esi
f0103315:	85 f6                	test   %esi,%esi
f0103317:	7f e8                	jg     f0103301 <printnum+0x91>
f0103319:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010331c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103320:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103324:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103327:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010332a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010332e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103332:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103335:	89 04 24             	mov    %eax,(%esp)
f0103338:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010333b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010333f:	e8 8c 0a 00 00       	call   f0103dd0 <__umoddi3>
f0103344:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103348:	0f be 80 06 50 10 f0 	movsbl -0xfefaffa(%eax),%eax
f010334f:	89 04 24             	mov    %eax,(%esp)
f0103352:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103355:	ff d0                	call   *%eax
}
f0103357:	83 c4 3c             	add    $0x3c,%esp
f010335a:	5b                   	pop    %ebx
f010335b:	5e                   	pop    %esi
f010335c:	5f                   	pop    %edi
f010335d:	5d                   	pop    %ebp
f010335e:	c3                   	ret    

f010335f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010335f:	55                   	push   %ebp
f0103360:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103362:	83 fa 01             	cmp    $0x1,%edx
f0103365:	7e 0e                	jle    f0103375 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103367:	8b 10                	mov    (%eax),%edx
f0103369:	8d 4a 08             	lea    0x8(%edx),%ecx
f010336c:	89 08                	mov    %ecx,(%eax)
f010336e:	8b 02                	mov    (%edx),%eax
f0103370:	8b 52 04             	mov    0x4(%edx),%edx
f0103373:	eb 22                	jmp    f0103397 <getuint+0x38>
	else if (lflag)
f0103375:	85 d2                	test   %edx,%edx
f0103377:	74 10                	je     f0103389 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103379:	8b 10                	mov    (%eax),%edx
f010337b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010337e:	89 08                	mov    %ecx,(%eax)
f0103380:	8b 02                	mov    (%edx),%eax
f0103382:	ba 00 00 00 00       	mov    $0x0,%edx
f0103387:	eb 0e                	jmp    f0103397 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103389:	8b 10                	mov    (%eax),%edx
f010338b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010338e:	89 08                	mov    %ecx,(%eax)
f0103390:	8b 02                	mov    (%edx),%eax
f0103392:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103397:	5d                   	pop    %ebp
f0103398:	c3                   	ret    

f0103399 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103399:	55                   	push   %ebp
f010339a:	89 e5                	mov    %esp,%ebp
f010339c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010339f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01033a3:	8b 10                	mov    (%eax),%edx
f01033a5:	3b 50 04             	cmp    0x4(%eax),%edx
f01033a8:	73 0a                	jae    f01033b4 <sprintputch+0x1b>
		*b->buf++ = ch;
f01033aa:	8d 4a 01             	lea    0x1(%edx),%ecx
f01033ad:	89 08                	mov    %ecx,(%eax)
f01033af:	8b 45 08             	mov    0x8(%ebp),%eax
f01033b2:	88 02                	mov    %al,(%edx)
}
f01033b4:	5d                   	pop    %ebp
f01033b5:	c3                   	ret    

f01033b6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01033b6:	55                   	push   %ebp
f01033b7:	89 e5                	mov    %esp,%ebp
f01033b9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01033bc:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01033bf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01033c3:	8b 45 10             	mov    0x10(%ebp),%eax
f01033c6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01033ca:	8b 45 0c             	mov    0xc(%ebp),%eax
f01033cd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01033d1:	8b 45 08             	mov    0x8(%ebp),%eax
f01033d4:	89 04 24             	mov    %eax,(%esp)
f01033d7:	e8 02 00 00 00       	call   f01033de <vprintfmt>
	va_end(ap);
}
f01033dc:	c9                   	leave  
f01033dd:	c3                   	ret    

f01033de <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01033de:	55                   	push   %ebp
f01033df:	89 e5                	mov    %esp,%ebp
f01033e1:	57                   	push   %edi
f01033e2:	56                   	push   %esi
f01033e3:	53                   	push   %ebx
f01033e4:	83 ec 3c             	sub    $0x3c,%esp
f01033e7:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01033ea:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01033ed:	eb 14                	jmp    f0103403 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01033ef:	85 c0                	test   %eax,%eax
f01033f1:	0f 84 b3 03 00 00    	je     f01037aa <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f01033f7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01033fb:	89 04 24             	mov    %eax,(%esp)
f01033fe:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103401:	89 f3                	mov    %esi,%ebx
f0103403:	8d 73 01             	lea    0x1(%ebx),%esi
f0103406:	0f b6 03             	movzbl (%ebx),%eax
f0103409:	83 f8 25             	cmp    $0x25,%eax
f010340c:	75 e1                	jne    f01033ef <vprintfmt+0x11>
f010340e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0103412:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103419:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0103420:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0103427:	ba 00 00 00 00       	mov    $0x0,%edx
f010342c:	eb 1d                	jmp    f010344b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010342e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103430:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0103434:	eb 15                	jmp    f010344b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103436:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103438:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f010343c:	eb 0d                	jmp    f010344b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f010343e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103441:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103444:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010344b:	8d 5e 01             	lea    0x1(%esi),%ebx
f010344e:	0f b6 0e             	movzbl (%esi),%ecx
f0103451:	0f b6 c1             	movzbl %cl,%eax
f0103454:	83 e9 23             	sub    $0x23,%ecx
f0103457:	80 f9 55             	cmp    $0x55,%cl
f010345a:	0f 87 2a 03 00 00    	ja     f010378a <vprintfmt+0x3ac>
f0103460:	0f b6 c9             	movzbl %cl,%ecx
f0103463:	ff 24 8d a0 50 10 f0 	jmp    *-0xfefaf60(,%ecx,4)
f010346a:	89 de                	mov    %ebx,%esi
f010346c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103471:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0103474:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0103478:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f010347b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f010347e:	83 fb 09             	cmp    $0x9,%ebx
f0103481:	77 36                	ja     f01034b9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103483:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103486:	eb e9                	jmp    f0103471 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103488:	8b 45 14             	mov    0x14(%ebp),%eax
f010348b:	8d 48 04             	lea    0x4(%eax),%ecx
f010348e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103491:	8b 00                	mov    (%eax),%eax
f0103493:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103496:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103498:	eb 22                	jmp    f01034bc <vprintfmt+0xde>
f010349a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010349d:	85 c9                	test   %ecx,%ecx
f010349f:	b8 00 00 00 00       	mov    $0x0,%eax
f01034a4:	0f 49 c1             	cmovns %ecx,%eax
f01034a7:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034aa:	89 de                	mov    %ebx,%esi
f01034ac:	eb 9d                	jmp    f010344b <vprintfmt+0x6d>
f01034ae:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01034b0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f01034b7:	eb 92                	jmp    f010344b <vprintfmt+0x6d>
f01034b9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f01034bc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01034c0:	79 89                	jns    f010344b <vprintfmt+0x6d>
f01034c2:	e9 77 ff ff ff       	jmp    f010343e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01034c7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034ca:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01034cc:	e9 7a ff ff ff       	jmp    f010344b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01034d1:	8b 45 14             	mov    0x14(%ebp),%eax
f01034d4:	8d 50 04             	lea    0x4(%eax),%edx
f01034d7:	89 55 14             	mov    %edx,0x14(%ebp)
f01034da:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01034de:	8b 00                	mov    (%eax),%eax
f01034e0:	89 04 24             	mov    %eax,(%esp)
f01034e3:	ff 55 08             	call   *0x8(%ebp)
			break;
f01034e6:	e9 18 ff ff ff       	jmp    f0103403 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01034eb:	8b 45 14             	mov    0x14(%ebp),%eax
f01034ee:	8d 50 04             	lea    0x4(%eax),%edx
f01034f1:	89 55 14             	mov    %edx,0x14(%ebp)
f01034f4:	8b 00                	mov    (%eax),%eax
f01034f6:	99                   	cltd   
f01034f7:	31 d0                	xor    %edx,%eax
f01034f9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01034fb:	83 f8 07             	cmp    $0x7,%eax
f01034fe:	7f 0b                	jg     f010350b <vprintfmt+0x12d>
f0103500:	8b 14 85 00 52 10 f0 	mov    -0xfefae00(,%eax,4),%edx
f0103507:	85 d2                	test   %edx,%edx
f0103509:	75 20                	jne    f010352b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f010350b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010350f:	c7 44 24 08 1e 50 10 	movl   $0xf010501e,0x8(%esp)
f0103516:	f0 
f0103517:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010351b:	8b 45 08             	mov    0x8(%ebp),%eax
f010351e:	89 04 24             	mov    %eax,(%esp)
f0103521:	e8 90 fe ff ff       	call   f01033b6 <printfmt>
f0103526:	e9 d8 fe ff ff       	jmp    f0103403 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f010352b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010352f:	c7 44 24 08 08 4d 10 	movl   $0xf0104d08,0x8(%esp)
f0103536:	f0 
f0103537:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010353b:	8b 45 08             	mov    0x8(%ebp),%eax
f010353e:	89 04 24             	mov    %eax,(%esp)
f0103541:	e8 70 fe ff ff       	call   f01033b6 <printfmt>
f0103546:	e9 b8 fe ff ff       	jmp    f0103403 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010354b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010354e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103551:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103554:	8b 45 14             	mov    0x14(%ebp),%eax
f0103557:	8d 50 04             	lea    0x4(%eax),%edx
f010355a:	89 55 14             	mov    %edx,0x14(%ebp)
f010355d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010355f:	85 f6                	test   %esi,%esi
f0103561:	b8 17 50 10 f0       	mov    $0xf0105017,%eax
f0103566:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0103569:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010356d:	0f 84 97 00 00 00    	je     f010360a <vprintfmt+0x22c>
f0103573:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0103577:	0f 8e 9b 00 00 00    	jle    f0103618 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f010357d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103581:	89 34 24             	mov    %esi,(%esp)
f0103584:	e8 9f 03 00 00       	call   f0103928 <strnlen>
f0103589:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010358c:	29 c2                	sub    %eax,%edx
f010358e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0103591:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0103595:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103598:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010359b:	8b 75 08             	mov    0x8(%ebp),%esi
f010359e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01035a1:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01035a3:	eb 0f                	jmp    f01035b4 <vprintfmt+0x1d6>
					putch(padc, putdat);
f01035a5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01035a9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01035ac:	89 04 24             	mov    %eax,(%esp)
f01035af:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01035b1:	83 eb 01             	sub    $0x1,%ebx
f01035b4:	85 db                	test   %ebx,%ebx
f01035b6:	7f ed                	jg     f01035a5 <vprintfmt+0x1c7>
f01035b8:	8b 75 d8             	mov    -0x28(%ebp),%esi
f01035bb:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01035be:	85 d2                	test   %edx,%edx
f01035c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01035c5:	0f 49 c2             	cmovns %edx,%eax
f01035c8:	29 c2                	sub    %eax,%edx
f01035ca:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01035cd:	89 d7                	mov    %edx,%edi
f01035cf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01035d2:	eb 50                	jmp    f0103624 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01035d4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01035d8:	74 1e                	je     f01035f8 <vprintfmt+0x21a>
f01035da:	0f be d2             	movsbl %dl,%edx
f01035dd:	83 ea 20             	sub    $0x20,%edx
f01035e0:	83 fa 5e             	cmp    $0x5e,%edx
f01035e3:	76 13                	jbe    f01035f8 <vprintfmt+0x21a>
					putch('?', putdat);
f01035e5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01035e8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035ec:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01035f3:	ff 55 08             	call   *0x8(%ebp)
f01035f6:	eb 0d                	jmp    f0103605 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f01035f8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01035fb:	89 54 24 04          	mov    %edx,0x4(%esp)
f01035ff:	89 04 24             	mov    %eax,(%esp)
f0103602:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103605:	83 ef 01             	sub    $0x1,%edi
f0103608:	eb 1a                	jmp    f0103624 <vprintfmt+0x246>
f010360a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010360d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0103610:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103613:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103616:	eb 0c                	jmp    f0103624 <vprintfmt+0x246>
f0103618:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010361b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f010361e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103621:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103624:	83 c6 01             	add    $0x1,%esi
f0103627:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f010362b:	0f be c2             	movsbl %dl,%eax
f010362e:	85 c0                	test   %eax,%eax
f0103630:	74 27                	je     f0103659 <vprintfmt+0x27b>
f0103632:	85 db                	test   %ebx,%ebx
f0103634:	78 9e                	js     f01035d4 <vprintfmt+0x1f6>
f0103636:	83 eb 01             	sub    $0x1,%ebx
f0103639:	79 99                	jns    f01035d4 <vprintfmt+0x1f6>
f010363b:	89 f8                	mov    %edi,%eax
f010363d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103640:	8b 75 08             	mov    0x8(%ebp),%esi
f0103643:	89 c3                	mov    %eax,%ebx
f0103645:	eb 1a                	jmp    f0103661 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103647:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010364b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0103652:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103654:	83 eb 01             	sub    $0x1,%ebx
f0103657:	eb 08                	jmp    f0103661 <vprintfmt+0x283>
f0103659:	89 fb                	mov    %edi,%ebx
f010365b:	8b 75 08             	mov    0x8(%ebp),%esi
f010365e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103661:	85 db                	test   %ebx,%ebx
f0103663:	7f e2                	jg     f0103647 <vprintfmt+0x269>
f0103665:	89 75 08             	mov    %esi,0x8(%ebp)
f0103668:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010366b:	e9 93 fd ff ff       	jmp    f0103403 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103670:	83 fa 01             	cmp    $0x1,%edx
f0103673:	7e 16                	jle    f010368b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0103675:	8b 45 14             	mov    0x14(%ebp),%eax
f0103678:	8d 50 08             	lea    0x8(%eax),%edx
f010367b:	89 55 14             	mov    %edx,0x14(%ebp)
f010367e:	8b 50 04             	mov    0x4(%eax),%edx
f0103681:	8b 00                	mov    (%eax),%eax
f0103683:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103686:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103689:	eb 32                	jmp    f01036bd <vprintfmt+0x2df>
	else if (lflag)
f010368b:	85 d2                	test   %edx,%edx
f010368d:	74 18                	je     f01036a7 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010368f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103692:	8d 50 04             	lea    0x4(%eax),%edx
f0103695:	89 55 14             	mov    %edx,0x14(%ebp)
f0103698:	8b 30                	mov    (%eax),%esi
f010369a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010369d:	89 f0                	mov    %esi,%eax
f010369f:	c1 f8 1f             	sar    $0x1f,%eax
f01036a2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01036a5:	eb 16                	jmp    f01036bd <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f01036a7:	8b 45 14             	mov    0x14(%ebp),%eax
f01036aa:	8d 50 04             	lea    0x4(%eax),%edx
f01036ad:	89 55 14             	mov    %edx,0x14(%ebp)
f01036b0:	8b 30                	mov    (%eax),%esi
f01036b2:	89 75 e0             	mov    %esi,-0x20(%ebp)
f01036b5:	89 f0                	mov    %esi,%eax
f01036b7:	c1 f8 1f             	sar    $0x1f,%eax
f01036ba:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01036bd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01036c0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01036c3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01036c8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01036cc:	0f 89 80 00 00 00    	jns    f0103752 <vprintfmt+0x374>
				putch('-', putdat);
f01036d2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01036d6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01036dd:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01036e0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01036e3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01036e6:	f7 d8                	neg    %eax
f01036e8:	83 d2 00             	adc    $0x0,%edx
f01036eb:	f7 da                	neg    %edx
			}
			base = 10;
f01036ed:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01036f2:	eb 5e                	jmp    f0103752 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01036f4:	8d 45 14             	lea    0x14(%ebp),%eax
f01036f7:	e8 63 fc ff ff       	call   f010335f <getuint>
			base = 10;
f01036fc:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103701:	eb 4f                	jmp    f0103752 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0103703:	8d 45 14             	lea    0x14(%ebp),%eax
f0103706:	e8 54 fc ff ff       	call   f010335f <getuint>
			base = 8;
f010370b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0103710:	eb 40                	jmp    f0103752 <vprintfmt+0x374>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f0103712:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103716:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010371d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103720:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103724:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010372b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010372e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103731:	8d 50 04             	lea    0x4(%eax),%edx
f0103734:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103737:	8b 00                	mov    (%eax),%eax
f0103739:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010373e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103743:	eb 0d                	jmp    f0103752 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103745:	8d 45 14             	lea    0x14(%ebp),%eax
f0103748:	e8 12 fc ff ff       	call   f010335f <getuint>
			base = 16;
f010374d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103752:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0103756:	89 74 24 10          	mov    %esi,0x10(%esp)
f010375a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010375d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103761:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103765:	89 04 24             	mov    %eax,(%esp)
f0103768:	89 54 24 04          	mov    %edx,0x4(%esp)
f010376c:	89 fa                	mov    %edi,%edx
f010376e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103771:	e8 fa fa ff ff       	call   f0103270 <printnum>
			break;
f0103776:	e9 88 fc ff ff       	jmp    f0103403 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010377b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010377f:	89 04 24             	mov    %eax,(%esp)
f0103782:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103785:	e9 79 fc ff ff       	jmp    f0103403 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010378a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010378e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103795:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103798:	89 f3                	mov    %esi,%ebx
f010379a:	eb 03                	jmp    f010379f <vprintfmt+0x3c1>
f010379c:	83 eb 01             	sub    $0x1,%ebx
f010379f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f01037a3:	75 f7                	jne    f010379c <vprintfmt+0x3be>
f01037a5:	e9 59 fc ff ff       	jmp    f0103403 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f01037aa:	83 c4 3c             	add    $0x3c,%esp
f01037ad:	5b                   	pop    %ebx
f01037ae:	5e                   	pop    %esi
f01037af:	5f                   	pop    %edi
f01037b0:	5d                   	pop    %ebp
f01037b1:	c3                   	ret    

f01037b2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01037b2:	55                   	push   %ebp
f01037b3:	89 e5                	mov    %esp,%ebp
f01037b5:	83 ec 28             	sub    $0x28,%esp
f01037b8:	8b 45 08             	mov    0x8(%ebp),%eax
f01037bb:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01037be:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01037c1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01037c5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01037c8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01037cf:	85 c0                	test   %eax,%eax
f01037d1:	74 30                	je     f0103803 <vsnprintf+0x51>
f01037d3:	85 d2                	test   %edx,%edx
f01037d5:	7e 2c                	jle    f0103803 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01037d7:	8b 45 14             	mov    0x14(%ebp),%eax
f01037da:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01037de:	8b 45 10             	mov    0x10(%ebp),%eax
f01037e1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01037e5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01037e8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01037ec:	c7 04 24 99 33 10 f0 	movl   $0xf0103399,(%esp)
f01037f3:	e8 e6 fb ff ff       	call   f01033de <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01037f8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01037fb:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01037fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103801:	eb 05                	jmp    f0103808 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103803:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103808:	c9                   	leave  
f0103809:	c3                   	ret    

f010380a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010380a:	55                   	push   %ebp
f010380b:	89 e5                	mov    %esp,%ebp
f010380d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103810:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103813:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103817:	8b 45 10             	mov    0x10(%ebp),%eax
f010381a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010381e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103821:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103825:	8b 45 08             	mov    0x8(%ebp),%eax
f0103828:	89 04 24             	mov    %eax,(%esp)
f010382b:	e8 82 ff ff ff       	call   f01037b2 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103830:	c9                   	leave  
f0103831:	c3                   	ret    
f0103832:	66 90                	xchg   %ax,%ax
f0103834:	66 90                	xchg   %ax,%ax
f0103836:	66 90                	xchg   %ax,%ax
f0103838:	66 90                	xchg   %ax,%ax
f010383a:	66 90                	xchg   %ax,%ax
f010383c:	66 90                	xchg   %ax,%ax
f010383e:	66 90                	xchg   %ax,%ax

f0103840 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103840:	55                   	push   %ebp
f0103841:	89 e5                	mov    %esp,%ebp
f0103843:	57                   	push   %edi
f0103844:	56                   	push   %esi
f0103845:	53                   	push   %ebx
f0103846:	83 ec 1c             	sub    $0x1c,%esp
f0103849:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010384c:	85 c0                	test   %eax,%eax
f010384e:	74 10                	je     f0103860 <readline+0x20>
		cprintf("%s", prompt);
f0103850:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103854:	c7 04 24 08 4d 10 f0 	movl   $0xf0104d08,(%esp)
f010385b:	e8 d2 f6 ff ff       	call   f0102f32 <cprintf>

	i = 0;
	echoing = iscons(0);
f0103860:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103867:	e8 a6 cd ff ff       	call   f0100612 <iscons>
f010386c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010386e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103873:	e8 89 cd ff ff       	call   f0100601 <getchar>
f0103878:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010387a:	85 c0                	test   %eax,%eax
f010387c:	79 17                	jns    f0103895 <readline+0x55>
			cprintf("read error: %e\n", c);
f010387e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103882:	c7 04 24 20 52 10 f0 	movl   $0xf0105220,(%esp)
f0103889:	e8 a4 f6 ff ff       	call   f0102f32 <cprintf>
			return NULL;
f010388e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103893:	eb 6d                	jmp    f0103902 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103895:	83 f8 7f             	cmp    $0x7f,%eax
f0103898:	74 05                	je     f010389f <readline+0x5f>
f010389a:	83 f8 08             	cmp    $0x8,%eax
f010389d:	75 19                	jne    f01038b8 <readline+0x78>
f010389f:	85 f6                	test   %esi,%esi
f01038a1:	7e 15                	jle    f01038b8 <readline+0x78>
			if (echoing)
f01038a3:	85 ff                	test   %edi,%edi
f01038a5:	74 0c                	je     f01038b3 <readline+0x73>
				cputchar('\b');
f01038a7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01038ae:	e8 3e cd ff ff       	call   f01005f1 <cputchar>
			i--;
f01038b3:	83 ee 01             	sub    $0x1,%esi
f01038b6:	eb bb                	jmp    f0103873 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01038b8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01038be:	7f 1c                	jg     f01038dc <readline+0x9c>
f01038c0:	83 fb 1f             	cmp    $0x1f,%ebx
f01038c3:	7e 17                	jle    f01038dc <readline+0x9c>
			if (echoing)
f01038c5:	85 ff                	test   %edi,%edi
f01038c7:	74 08                	je     f01038d1 <readline+0x91>
				cputchar(c);
f01038c9:	89 1c 24             	mov    %ebx,(%esp)
f01038cc:	e8 20 cd ff ff       	call   f01005f1 <cputchar>
			buf[i++] = c;
f01038d1:	88 9e 60 75 11 f0    	mov    %bl,-0xfee8aa0(%esi)
f01038d7:	8d 76 01             	lea    0x1(%esi),%esi
f01038da:	eb 97                	jmp    f0103873 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01038dc:	83 fb 0d             	cmp    $0xd,%ebx
f01038df:	74 05                	je     f01038e6 <readline+0xa6>
f01038e1:	83 fb 0a             	cmp    $0xa,%ebx
f01038e4:	75 8d                	jne    f0103873 <readline+0x33>
			if (echoing)
f01038e6:	85 ff                	test   %edi,%edi
f01038e8:	74 0c                	je     f01038f6 <readline+0xb6>
				cputchar('\n');
f01038ea:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01038f1:	e8 fb cc ff ff       	call   f01005f1 <cputchar>
			buf[i] = 0;
f01038f6:	c6 86 60 75 11 f0 00 	movb   $0x0,-0xfee8aa0(%esi)
			return buf;
f01038fd:	b8 60 75 11 f0       	mov    $0xf0117560,%eax
		}
	}
}
f0103902:	83 c4 1c             	add    $0x1c,%esp
f0103905:	5b                   	pop    %ebx
f0103906:	5e                   	pop    %esi
f0103907:	5f                   	pop    %edi
f0103908:	5d                   	pop    %ebp
f0103909:	c3                   	ret    
f010390a:	66 90                	xchg   %ax,%ax
f010390c:	66 90                	xchg   %ax,%ax
f010390e:	66 90                	xchg   %ax,%ax

f0103910 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103910:	55                   	push   %ebp
f0103911:	89 e5                	mov    %esp,%ebp
f0103913:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103916:	b8 00 00 00 00       	mov    $0x0,%eax
f010391b:	eb 03                	jmp    f0103920 <strlen+0x10>
		n++;
f010391d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103920:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103924:	75 f7                	jne    f010391d <strlen+0xd>
		n++;
	return n;
}
f0103926:	5d                   	pop    %ebp
f0103927:	c3                   	ret    

f0103928 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103928:	55                   	push   %ebp
f0103929:	89 e5                	mov    %esp,%ebp
f010392b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010392e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103931:	b8 00 00 00 00       	mov    $0x0,%eax
f0103936:	eb 03                	jmp    f010393b <strnlen+0x13>
		n++;
f0103938:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010393b:	39 d0                	cmp    %edx,%eax
f010393d:	74 06                	je     f0103945 <strnlen+0x1d>
f010393f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103943:	75 f3                	jne    f0103938 <strnlen+0x10>
		n++;
	return n;
}
f0103945:	5d                   	pop    %ebp
f0103946:	c3                   	ret    

f0103947 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103947:	55                   	push   %ebp
f0103948:	89 e5                	mov    %esp,%ebp
f010394a:	53                   	push   %ebx
f010394b:	8b 45 08             	mov    0x8(%ebp),%eax
f010394e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103951:	89 c2                	mov    %eax,%edx
f0103953:	83 c2 01             	add    $0x1,%edx
f0103956:	83 c1 01             	add    $0x1,%ecx
f0103959:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010395d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103960:	84 db                	test   %bl,%bl
f0103962:	75 ef                	jne    f0103953 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103964:	5b                   	pop    %ebx
f0103965:	5d                   	pop    %ebp
f0103966:	c3                   	ret    

f0103967 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103967:	55                   	push   %ebp
f0103968:	89 e5                	mov    %esp,%ebp
f010396a:	53                   	push   %ebx
f010396b:	83 ec 08             	sub    $0x8,%esp
f010396e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103971:	89 1c 24             	mov    %ebx,(%esp)
f0103974:	e8 97 ff ff ff       	call   f0103910 <strlen>
	strcpy(dst + len, src);
f0103979:	8b 55 0c             	mov    0xc(%ebp),%edx
f010397c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103980:	01 d8                	add    %ebx,%eax
f0103982:	89 04 24             	mov    %eax,(%esp)
f0103985:	e8 bd ff ff ff       	call   f0103947 <strcpy>
	return dst;
}
f010398a:	89 d8                	mov    %ebx,%eax
f010398c:	83 c4 08             	add    $0x8,%esp
f010398f:	5b                   	pop    %ebx
f0103990:	5d                   	pop    %ebp
f0103991:	c3                   	ret    

f0103992 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103992:	55                   	push   %ebp
f0103993:	89 e5                	mov    %esp,%ebp
f0103995:	56                   	push   %esi
f0103996:	53                   	push   %ebx
f0103997:	8b 75 08             	mov    0x8(%ebp),%esi
f010399a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010399d:	89 f3                	mov    %esi,%ebx
f010399f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01039a2:	89 f2                	mov    %esi,%edx
f01039a4:	eb 0f                	jmp    f01039b5 <strncpy+0x23>
		*dst++ = *src;
f01039a6:	83 c2 01             	add    $0x1,%edx
f01039a9:	0f b6 01             	movzbl (%ecx),%eax
f01039ac:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01039af:	80 39 01             	cmpb   $0x1,(%ecx)
f01039b2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01039b5:	39 da                	cmp    %ebx,%edx
f01039b7:	75 ed                	jne    f01039a6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01039b9:	89 f0                	mov    %esi,%eax
f01039bb:	5b                   	pop    %ebx
f01039bc:	5e                   	pop    %esi
f01039bd:	5d                   	pop    %ebp
f01039be:	c3                   	ret    

f01039bf <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01039bf:	55                   	push   %ebp
f01039c0:	89 e5                	mov    %esp,%ebp
f01039c2:	56                   	push   %esi
f01039c3:	53                   	push   %ebx
f01039c4:	8b 75 08             	mov    0x8(%ebp),%esi
f01039c7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01039ca:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01039cd:	89 f0                	mov    %esi,%eax
f01039cf:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01039d3:	85 c9                	test   %ecx,%ecx
f01039d5:	75 0b                	jne    f01039e2 <strlcpy+0x23>
f01039d7:	eb 1d                	jmp    f01039f6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01039d9:	83 c0 01             	add    $0x1,%eax
f01039dc:	83 c2 01             	add    $0x1,%edx
f01039df:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01039e2:	39 d8                	cmp    %ebx,%eax
f01039e4:	74 0b                	je     f01039f1 <strlcpy+0x32>
f01039e6:	0f b6 0a             	movzbl (%edx),%ecx
f01039e9:	84 c9                	test   %cl,%cl
f01039eb:	75 ec                	jne    f01039d9 <strlcpy+0x1a>
f01039ed:	89 c2                	mov    %eax,%edx
f01039ef:	eb 02                	jmp    f01039f3 <strlcpy+0x34>
f01039f1:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f01039f3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f01039f6:	29 f0                	sub    %esi,%eax
}
f01039f8:	5b                   	pop    %ebx
f01039f9:	5e                   	pop    %esi
f01039fa:	5d                   	pop    %ebp
f01039fb:	c3                   	ret    

f01039fc <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01039fc:	55                   	push   %ebp
f01039fd:	89 e5                	mov    %esp,%ebp
f01039ff:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103a02:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103a05:	eb 06                	jmp    f0103a0d <strcmp+0x11>
		p++, q++;
f0103a07:	83 c1 01             	add    $0x1,%ecx
f0103a0a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103a0d:	0f b6 01             	movzbl (%ecx),%eax
f0103a10:	84 c0                	test   %al,%al
f0103a12:	74 04                	je     f0103a18 <strcmp+0x1c>
f0103a14:	3a 02                	cmp    (%edx),%al
f0103a16:	74 ef                	je     f0103a07 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103a18:	0f b6 c0             	movzbl %al,%eax
f0103a1b:	0f b6 12             	movzbl (%edx),%edx
f0103a1e:	29 d0                	sub    %edx,%eax
}
f0103a20:	5d                   	pop    %ebp
f0103a21:	c3                   	ret    

f0103a22 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103a22:	55                   	push   %ebp
f0103a23:	89 e5                	mov    %esp,%ebp
f0103a25:	53                   	push   %ebx
f0103a26:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a29:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103a2c:	89 c3                	mov    %eax,%ebx
f0103a2e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103a31:	eb 06                	jmp    f0103a39 <strncmp+0x17>
		n--, p++, q++;
f0103a33:	83 c0 01             	add    $0x1,%eax
f0103a36:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103a39:	39 d8                	cmp    %ebx,%eax
f0103a3b:	74 15                	je     f0103a52 <strncmp+0x30>
f0103a3d:	0f b6 08             	movzbl (%eax),%ecx
f0103a40:	84 c9                	test   %cl,%cl
f0103a42:	74 04                	je     f0103a48 <strncmp+0x26>
f0103a44:	3a 0a                	cmp    (%edx),%cl
f0103a46:	74 eb                	je     f0103a33 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103a48:	0f b6 00             	movzbl (%eax),%eax
f0103a4b:	0f b6 12             	movzbl (%edx),%edx
f0103a4e:	29 d0                	sub    %edx,%eax
f0103a50:	eb 05                	jmp    f0103a57 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103a52:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103a57:	5b                   	pop    %ebx
f0103a58:	5d                   	pop    %ebp
f0103a59:	c3                   	ret    

f0103a5a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103a5a:	55                   	push   %ebp
f0103a5b:	89 e5                	mov    %esp,%ebp
f0103a5d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a60:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103a64:	eb 07                	jmp    f0103a6d <strchr+0x13>
		if (*s == c)
f0103a66:	38 ca                	cmp    %cl,%dl
f0103a68:	74 0f                	je     f0103a79 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103a6a:	83 c0 01             	add    $0x1,%eax
f0103a6d:	0f b6 10             	movzbl (%eax),%edx
f0103a70:	84 d2                	test   %dl,%dl
f0103a72:	75 f2                	jne    f0103a66 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103a74:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103a79:	5d                   	pop    %ebp
f0103a7a:	c3                   	ret    

f0103a7b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103a7b:	55                   	push   %ebp
f0103a7c:	89 e5                	mov    %esp,%ebp
f0103a7e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a81:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103a85:	eb 07                	jmp    f0103a8e <strfind+0x13>
		if (*s == c)
f0103a87:	38 ca                	cmp    %cl,%dl
f0103a89:	74 0a                	je     f0103a95 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0103a8b:	83 c0 01             	add    $0x1,%eax
f0103a8e:	0f b6 10             	movzbl (%eax),%edx
f0103a91:	84 d2                	test   %dl,%dl
f0103a93:	75 f2                	jne    f0103a87 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0103a95:	5d                   	pop    %ebp
f0103a96:	c3                   	ret    

f0103a97 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103a97:	55                   	push   %ebp
f0103a98:	89 e5                	mov    %esp,%ebp
f0103a9a:	57                   	push   %edi
f0103a9b:	56                   	push   %esi
f0103a9c:	53                   	push   %ebx
f0103a9d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103aa0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103aa3:	85 c9                	test   %ecx,%ecx
f0103aa5:	74 36                	je     f0103add <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103aa7:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103aad:	75 28                	jne    f0103ad7 <memset+0x40>
f0103aaf:	f6 c1 03             	test   $0x3,%cl
f0103ab2:	75 23                	jne    f0103ad7 <memset+0x40>
		c &= 0xFF;
f0103ab4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103ab8:	89 d3                	mov    %edx,%ebx
f0103aba:	c1 e3 08             	shl    $0x8,%ebx
f0103abd:	89 d6                	mov    %edx,%esi
f0103abf:	c1 e6 18             	shl    $0x18,%esi
f0103ac2:	89 d0                	mov    %edx,%eax
f0103ac4:	c1 e0 10             	shl    $0x10,%eax
f0103ac7:	09 f0                	or     %esi,%eax
f0103ac9:	09 c2                	or     %eax,%edx
f0103acb:	89 d0                	mov    %edx,%eax
f0103acd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0103acf:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0103ad2:	fc                   	cld    
f0103ad3:	f3 ab                	rep stos %eax,%es:(%edi)
f0103ad5:	eb 06                	jmp    f0103add <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103ad7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103ada:	fc                   	cld    
f0103adb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103add:	89 f8                	mov    %edi,%eax
f0103adf:	5b                   	pop    %ebx
f0103ae0:	5e                   	pop    %esi
f0103ae1:	5f                   	pop    %edi
f0103ae2:	5d                   	pop    %ebp
f0103ae3:	c3                   	ret    

f0103ae4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103ae4:	55                   	push   %ebp
f0103ae5:	89 e5                	mov    %esp,%ebp
f0103ae7:	57                   	push   %edi
f0103ae8:	56                   	push   %esi
f0103ae9:	8b 45 08             	mov    0x8(%ebp),%eax
f0103aec:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103aef:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103af2:	39 c6                	cmp    %eax,%esi
f0103af4:	73 35                	jae    f0103b2b <memmove+0x47>
f0103af6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103af9:	39 d0                	cmp    %edx,%eax
f0103afb:	73 2e                	jae    f0103b2b <memmove+0x47>
		s += n;
		d += n;
f0103afd:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0103b00:	89 d6                	mov    %edx,%esi
f0103b02:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103b04:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103b0a:	75 13                	jne    f0103b1f <memmove+0x3b>
f0103b0c:	f6 c1 03             	test   $0x3,%cl
f0103b0f:	75 0e                	jne    f0103b1f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103b11:	83 ef 04             	sub    $0x4,%edi
f0103b14:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103b17:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0103b1a:	fd                   	std    
f0103b1b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103b1d:	eb 09                	jmp    f0103b28 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103b1f:	83 ef 01             	sub    $0x1,%edi
f0103b22:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103b25:	fd                   	std    
f0103b26:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103b28:	fc                   	cld    
f0103b29:	eb 1d                	jmp    f0103b48 <memmove+0x64>
f0103b2b:	89 f2                	mov    %esi,%edx
f0103b2d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103b2f:	f6 c2 03             	test   $0x3,%dl
f0103b32:	75 0f                	jne    f0103b43 <memmove+0x5f>
f0103b34:	f6 c1 03             	test   $0x3,%cl
f0103b37:	75 0a                	jne    f0103b43 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103b39:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0103b3c:	89 c7                	mov    %eax,%edi
f0103b3e:	fc                   	cld    
f0103b3f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103b41:	eb 05                	jmp    f0103b48 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103b43:	89 c7                	mov    %eax,%edi
f0103b45:	fc                   	cld    
f0103b46:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103b48:	5e                   	pop    %esi
f0103b49:	5f                   	pop    %edi
f0103b4a:	5d                   	pop    %ebp
f0103b4b:	c3                   	ret    

f0103b4c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103b4c:	55                   	push   %ebp
f0103b4d:	89 e5                	mov    %esp,%ebp
f0103b4f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103b52:	8b 45 10             	mov    0x10(%ebp),%eax
f0103b55:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103b59:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103b5c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b60:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b63:	89 04 24             	mov    %eax,(%esp)
f0103b66:	e8 79 ff ff ff       	call   f0103ae4 <memmove>
}
f0103b6b:	c9                   	leave  
f0103b6c:	c3                   	ret    

f0103b6d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103b6d:	55                   	push   %ebp
f0103b6e:	89 e5                	mov    %esp,%ebp
f0103b70:	56                   	push   %esi
f0103b71:	53                   	push   %ebx
f0103b72:	8b 55 08             	mov    0x8(%ebp),%edx
f0103b75:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103b78:	89 d6                	mov    %edx,%esi
f0103b7a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103b7d:	eb 1a                	jmp    f0103b99 <memcmp+0x2c>
		if (*s1 != *s2)
f0103b7f:	0f b6 02             	movzbl (%edx),%eax
f0103b82:	0f b6 19             	movzbl (%ecx),%ebx
f0103b85:	38 d8                	cmp    %bl,%al
f0103b87:	74 0a                	je     f0103b93 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103b89:	0f b6 c0             	movzbl %al,%eax
f0103b8c:	0f b6 db             	movzbl %bl,%ebx
f0103b8f:	29 d8                	sub    %ebx,%eax
f0103b91:	eb 0f                	jmp    f0103ba2 <memcmp+0x35>
		s1++, s2++;
f0103b93:	83 c2 01             	add    $0x1,%edx
f0103b96:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103b99:	39 f2                	cmp    %esi,%edx
f0103b9b:	75 e2                	jne    f0103b7f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103b9d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103ba2:	5b                   	pop    %ebx
f0103ba3:	5e                   	pop    %esi
f0103ba4:	5d                   	pop    %ebp
f0103ba5:	c3                   	ret    

f0103ba6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103ba6:	55                   	push   %ebp
f0103ba7:	89 e5                	mov    %esp,%ebp
f0103ba9:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bac:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103baf:	89 c2                	mov    %eax,%edx
f0103bb1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103bb4:	eb 07                	jmp    f0103bbd <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103bb6:	38 08                	cmp    %cl,(%eax)
f0103bb8:	74 07                	je     f0103bc1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103bba:	83 c0 01             	add    $0x1,%eax
f0103bbd:	39 d0                	cmp    %edx,%eax
f0103bbf:	72 f5                	jb     f0103bb6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103bc1:	5d                   	pop    %ebp
f0103bc2:	c3                   	ret    

f0103bc3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103bc3:	55                   	push   %ebp
f0103bc4:	89 e5                	mov    %esp,%ebp
f0103bc6:	57                   	push   %edi
f0103bc7:	56                   	push   %esi
f0103bc8:	53                   	push   %ebx
f0103bc9:	8b 55 08             	mov    0x8(%ebp),%edx
f0103bcc:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103bcf:	eb 03                	jmp    f0103bd4 <strtol+0x11>
		s++;
f0103bd1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103bd4:	0f b6 0a             	movzbl (%edx),%ecx
f0103bd7:	80 f9 09             	cmp    $0x9,%cl
f0103bda:	74 f5                	je     f0103bd1 <strtol+0xe>
f0103bdc:	80 f9 20             	cmp    $0x20,%cl
f0103bdf:	74 f0                	je     f0103bd1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103be1:	80 f9 2b             	cmp    $0x2b,%cl
f0103be4:	75 0a                	jne    f0103bf0 <strtol+0x2d>
		s++;
f0103be6:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103be9:	bf 00 00 00 00       	mov    $0x0,%edi
f0103bee:	eb 11                	jmp    f0103c01 <strtol+0x3e>
f0103bf0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103bf5:	80 f9 2d             	cmp    $0x2d,%cl
f0103bf8:	75 07                	jne    f0103c01 <strtol+0x3e>
		s++, neg = 1;
f0103bfa:	8d 52 01             	lea    0x1(%edx),%edx
f0103bfd:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103c01:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0103c06:	75 15                	jne    f0103c1d <strtol+0x5a>
f0103c08:	80 3a 30             	cmpb   $0x30,(%edx)
f0103c0b:	75 10                	jne    f0103c1d <strtol+0x5a>
f0103c0d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103c11:	75 0a                	jne    f0103c1d <strtol+0x5a>
		s += 2, base = 16;
f0103c13:	83 c2 02             	add    $0x2,%edx
f0103c16:	b8 10 00 00 00       	mov    $0x10,%eax
f0103c1b:	eb 10                	jmp    f0103c2d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f0103c1d:	85 c0                	test   %eax,%eax
f0103c1f:	75 0c                	jne    f0103c2d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103c21:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103c23:	80 3a 30             	cmpb   $0x30,(%edx)
f0103c26:	75 05                	jne    f0103c2d <strtol+0x6a>
		s++, base = 8;
f0103c28:	83 c2 01             	add    $0x1,%edx
f0103c2b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f0103c2d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103c32:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103c35:	0f b6 0a             	movzbl (%edx),%ecx
f0103c38:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0103c3b:	89 f0                	mov    %esi,%eax
f0103c3d:	3c 09                	cmp    $0x9,%al
f0103c3f:	77 08                	ja     f0103c49 <strtol+0x86>
			dig = *s - '0';
f0103c41:	0f be c9             	movsbl %cl,%ecx
f0103c44:	83 e9 30             	sub    $0x30,%ecx
f0103c47:	eb 20                	jmp    f0103c69 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0103c49:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0103c4c:	89 f0                	mov    %esi,%eax
f0103c4e:	3c 19                	cmp    $0x19,%al
f0103c50:	77 08                	ja     f0103c5a <strtol+0x97>
			dig = *s - 'a' + 10;
f0103c52:	0f be c9             	movsbl %cl,%ecx
f0103c55:	83 e9 57             	sub    $0x57,%ecx
f0103c58:	eb 0f                	jmp    f0103c69 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0103c5a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0103c5d:	89 f0                	mov    %esi,%eax
f0103c5f:	3c 19                	cmp    $0x19,%al
f0103c61:	77 16                	ja     f0103c79 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0103c63:	0f be c9             	movsbl %cl,%ecx
f0103c66:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103c69:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0103c6c:	7d 0f                	jge    f0103c7d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f0103c6e:	83 c2 01             	add    $0x1,%edx
f0103c71:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0103c75:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0103c77:	eb bc                	jmp    f0103c35 <strtol+0x72>
f0103c79:	89 d8                	mov    %ebx,%eax
f0103c7b:	eb 02                	jmp    f0103c7f <strtol+0xbc>
f0103c7d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0103c7f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103c83:	74 05                	je     f0103c8a <strtol+0xc7>
		*endptr = (char *) s;
f0103c85:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103c88:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0103c8a:	f7 d8                	neg    %eax
f0103c8c:	85 ff                	test   %edi,%edi
f0103c8e:	0f 44 c3             	cmove  %ebx,%eax
}
f0103c91:	5b                   	pop    %ebx
f0103c92:	5e                   	pop    %esi
f0103c93:	5f                   	pop    %edi
f0103c94:	5d                   	pop    %ebp
f0103c95:	c3                   	ret    
f0103c96:	66 90                	xchg   %ax,%ax
f0103c98:	66 90                	xchg   %ax,%ax
f0103c9a:	66 90                	xchg   %ax,%ax
f0103c9c:	66 90                	xchg   %ax,%ax
f0103c9e:	66 90                	xchg   %ax,%ax

f0103ca0 <__udivdi3>:
f0103ca0:	55                   	push   %ebp
f0103ca1:	57                   	push   %edi
f0103ca2:	56                   	push   %esi
f0103ca3:	83 ec 0c             	sub    $0xc,%esp
f0103ca6:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103caa:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0103cae:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0103cb2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103cb6:	85 c0                	test   %eax,%eax
f0103cb8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103cbc:	89 ea                	mov    %ebp,%edx
f0103cbe:	89 0c 24             	mov    %ecx,(%esp)
f0103cc1:	75 2d                	jne    f0103cf0 <__udivdi3+0x50>
f0103cc3:	39 e9                	cmp    %ebp,%ecx
f0103cc5:	77 61                	ja     f0103d28 <__udivdi3+0x88>
f0103cc7:	85 c9                	test   %ecx,%ecx
f0103cc9:	89 ce                	mov    %ecx,%esi
f0103ccb:	75 0b                	jne    f0103cd8 <__udivdi3+0x38>
f0103ccd:	b8 01 00 00 00       	mov    $0x1,%eax
f0103cd2:	31 d2                	xor    %edx,%edx
f0103cd4:	f7 f1                	div    %ecx
f0103cd6:	89 c6                	mov    %eax,%esi
f0103cd8:	31 d2                	xor    %edx,%edx
f0103cda:	89 e8                	mov    %ebp,%eax
f0103cdc:	f7 f6                	div    %esi
f0103cde:	89 c5                	mov    %eax,%ebp
f0103ce0:	89 f8                	mov    %edi,%eax
f0103ce2:	f7 f6                	div    %esi
f0103ce4:	89 ea                	mov    %ebp,%edx
f0103ce6:	83 c4 0c             	add    $0xc,%esp
f0103ce9:	5e                   	pop    %esi
f0103cea:	5f                   	pop    %edi
f0103ceb:	5d                   	pop    %ebp
f0103cec:	c3                   	ret    
f0103ced:	8d 76 00             	lea    0x0(%esi),%esi
f0103cf0:	39 e8                	cmp    %ebp,%eax
f0103cf2:	77 24                	ja     f0103d18 <__udivdi3+0x78>
f0103cf4:	0f bd e8             	bsr    %eax,%ebp
f0103cf7:	83 f5 1f             	xor    $0x1f,%ebp
f0103cfa:	75 3c                	jne    f0103d38 <__udivdi3+0x98>
f0103cfc:	8b 74 24 04          	mov    0x4(%esp),%esi
f0103d00:	39 34 24             	cmp    %esi,(%esp)
f0103d03:	0f 86 9f 00 00 00    	jbe    f0103da8 <__udivdi3+0x108>
f0103d09:	39 d0                	cmp    %edx,%eax
f0103d0b:	0f 82 97 00 00 00    	jb     f0103da8 <__udivdi3+0x108>
f0103d11:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103d18:	31 d2                	xor    %edx,%edx
f0103d1a:	31 c0                	xor    %eax,%eax
f0103d1c:	83 c4 0c             	add    $0xc,%esp
f0103d1f:	5e                   	pop    %esi
f0103d20:	5f                   	pop    %edi
f0103d21:	5d                   	pop    %ebp
f0103d22:	c3                   	ret    
f0103d23:	90                   	nop
f0103d24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103d28:	89 f8                	mov    %edi,%eax
f0103d2a:	f7 f1                	div    %ecx
f0103d2c:	31 d2                	xor    %edx,%edx
f0103d2e:	83 c4 0c             	add    $0xc,%esp
f0103d31:	5e                   	pop    %esi
f0103d32:	5f                   	pop    %edi
f0103d33:	5d                   	pop    %ebp
f0103d34:	c3                   	ret    
f0103d35:	8d 76 00             	lea    0x0(%esi),%esi
f0103d38:	89 e9                	mov    %ebp,%ecx
f0103d3a:	8b 3c 24             	mov    (%esp),%edi
f0103d3d:	d3 e0                	shl    %cl,%eax
f0103d3f:	89 c6                	mov    %eax,%esi
f0103d41:	b8 20 00 00 00       	mov    $0x20,%eax
f0103d46:	29 e8                	sub    %ebp,%eax
f0103d48:	89 c1                	mov    %eax,%ecx
f0103d4a:	d3 ef                	shr    %cl,%edi
f0103d4c:	89 e9                	mov    %ebp,%ecx
f0103d4e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103d52:	8b 3c 24             	mov    (%esp),%edi
f0103d55:	09 74 24 08          	or     %esi,0x8(%esp)
f0103d59:	89 d6                	mov    %edx,%esi
f0103d5b:	d3 e7                	shl    %cl,%edi
f0103d5d:	89 c1                	mov    %eax,%ecx
f0103d5f:	89 3c 24             	mov    %edi,(%esp)
f0103d62:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103d66:	d3 ee                	shr    %cl,%esi
f0103d68:	89 e9                	mov    %ebp,%ecx
f0103d6a:	d3 e2                	shl    %cl,%edx
f0103d6c:	89 c1                	mov    %eax,%ecx
f0103d6e:	d3 ef                	shr    %cl,%edi
f0103d70:	09 d7                	or     %edx,%edi
f0103d72:	89 f2                	mov    %esi,%edx
f0103d74:	89 f8                	mov    %edi,%eax
f0103d76:	f7 74 24 08          	divl   0x8(%esp)
f0103d7a:	89 d6                	mov    %edx,%esi
f0103d7c:	89 c7                	mov    %eax,%edi
f0103d7e:	f7 24 24             	mull   (%esp)
f0103d81:	39 d6                	cmp    %edx,%esi
f0103d83:	89 14 24             	mov    %edx,(%esp)
f0103d86:	72 30                	jb     f0103db8 <__udivdi3+0x118>
f0103d88:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103d8c:	89 e9                	mov    %ebp,%ecx
f0103d8e:	d3 e2                	shl    %cl,%edx
f0103d90:	39 c2                	cmp    %eax,%edx
f0103d92:	73 05                	jae    f0103d99 <__udivdi3+0xf9>
f0103d94:	3b 34 24             	cmp    (%esp),%esi
f0103d97:	74 1f                	je     f0103db8 <__udivdi3+0x118>
f0103d99:	89 f8                	mov    %edi,%eax
f0103d9b:	31 d2                	xor    %edx,%edx
f0103d9d:	e9 7a ff ff ff       	jmp    f0103d1c <__udivdi3+0x7c>
f0103da2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103da8:	31 d2                	xor    %edx,%edx
f0103daa:	b8 01 00 00 00       	mov    $0x1,%eax
f0103daf:	e9 68 ff ff ff       	jmp    f0103d1c <__udivdi3+0x7c>
f0103db4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103db8:	8d 47 ff             	lea    -0x1(%edi),%eax
f0103dbb:	31 d2                	xor    %edx,%edx
f0103dbd:	83 c4 0c             	add    $0xc,%esp
f0103dc0:	5e                   	pop    %esi
f0103dc1:	5f                   	pop    %edi
f0103dc2:	5d                   	pop    %ebp
f0103dc3:	c3                   	ret    
f0103dc4:	66 90                	xchg   %ax,%ax
f0103dc6:	66 90                	xchg   %ax,%ax
f0103dc8:	66 90                	xchg   %ax,%ax
f0103dca:	66 90                	xchg   %ax,%ax
f0103dcc:	66 90                	xchg   %ax,%ax
f0103dce:	66 90                	xchg   %ax,%ax

f0103dd0 <__umoddi3>:
f0103dd0:	55                   	push   %ebp
f0103dd1:	57                   	push   %edi
f0103dd2:	56                   	push   %esi
f0103dd3:	83 ec 14             	sub    $0x14,%esp
f0103dd6:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103dda:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103dde:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0103de2:	89 c7                	mov    %eax,%edi
f0103de4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103de8:	8b 44 24 30          	mov    0x30(%esp),%eax
f0103dec:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0103df0:	89 34 24             	mov    %esi,(%esp)
f0103df3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103df7:	85 c0                	test   %eax,%eax
f0103df9:	89 c2                	mov    %eax,%edx
f0103dfb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103dff:	75 17                	jne    f0103e18 <__umoddi3+0x48>
f0103e01:	39 fe                	cmp    %edi,%esi
f0103e03:	76 4b                	jbe    f0103e50 <__umoddi3+0x80>
f0103e05:	89 c8                	mov    %ecx,%eax
f0103e07:	89 fa                	mov    %edi,%edx
f0103e09:	f7 f6                	div    %esi
f0103e0b:	89 d0                	mov    %edx,%eax
f0103e0d:	31 d2                	xor    %edx,%edx
f0103e0f:	83 c4 14             	add    $0x14,%esp
f0103e12:	5e                   	pop    %esi
f0103e13:	5f                   	pop    %edi
f0103e14:	5d                   	pop    %ebp
f0103e15:	c3                   	ret    
f0103e16:	66 90                	xchg   %ax,%ax
f0103e18:	39 f8                	cmp    %edi,%eax
f0103e1a:	77 54                	ja     f0103e70 <__umoddi3+0xa0>
f0103e1c:	0f bd e8             	bsr    %eax,%ebp
f0103e1f:	83 f5 1f             	xor    $0x1f,%ebp
f0103e22:	75 5c                	jne    f0103e80 <__umoddi3+0xb0>
f0103e24:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0103e28:	39 3c 24             	cmp    %edi,(%esp)
f0103e2b:	0f 87 e7 00 00 00    	ja     f0103f18 <__umoddi3+0x148>
f0103e31:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103e35:	29 f1                	sub    %esi,%ecx
f0103e37:	19 c7                	sbb    %eax,%edi
f0103e39:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103e3d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103e41:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103e45:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103e49:	83 c4 14             	add    $0x14,%esp
f0103e4c:	5e                   	pop    %esi
f0103e4d:	5f                   	pop    %edi
f0103e4e:	5d                   	pop    %ebp
f0103e4f:	c3                   	ret    
f0103e50:	85 f6                	test   %esi,%esi
f0103e52:	89 f5                	mov    %esi,%ebp
f0103e54:	75 0b                	jne    f0103e61 <__umoddi3+0x91>
f0103e56:	b8 01 00 00 00       	mov    $0x1,%eax
f0103e5b:	31 d2                	xor    %edx,%edx
f0103e5d:	f7 f6                	div    %esi
f0103e5f:	89 c5                	mov    %eax,%ebp
f0103e61:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103e65:	31 d2                	xor    %edx,%edx
f0103e67:	f7 f5                	div    %ebp
f0103e69:	89 c8                	mov    %ecx,%eax
f0103e6b:	f7 f5                	div    %ebp
f0103e6d:	eb 9c                	jmp    f0103e0b <__umoddi3+0x3b>
f0103e6f:	90                   	nop
f0103e70:	89 c8                	mov    %ecx,%eax
f0103e72:	89 fa                	mov    %edi,%edx
f0103e74:	83 c4 14             	add    $0x14,%esp
f0103e77:	5e                   	pop    %esi
f0103e78:	5f                   	pop    %edi
f0103e79:	5d                   	pop    %ebp
f0103e7a:	c3                   	ret    
f0103e7b:	90                   	nop
f0103e7c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103e80:	8b 04 24             	mov    (%esp),%eax
f0103e83:	be 20 00 00 00       	mov    $0x20,%esi
f0103e88:	89 e9                	mov    %ebp,%ecx
f0103e8a:	29 ee                	sub    %ebp,%esi
f0103e8c:	d3 e2                	shl    %cl,%edx
f0103e8e:	89 f1                	mov    %esi,%ecx
f0103e90:	d3 e8                	shr    %cl,%eax
f0103e92:	89 e9                	mov    %ebp,%ecx
f0103e94:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e98:	8b 04 24             	mov    (%esp),%eax
f0103e9b:	09 54 24 04          	or     %edx,0x4(%esp)
f0103e9f:	89 fa                	mov    %edi,%edx
f0103ea1:	d3 e0                	shl    %cl,%eax
f0103ea3:	89 f1                	mov    %esi,%ecx
f0103ea5:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103ea9:	8b 44 24 10          	mov    0x10(%esp),%eax
f0103ead:	d3 ea                	shr    %cl,%edx
f0103eaf:	89 e9                	mov    %ebp,%ecx
f0103eb1:	d3 e7                	shl    %cl,%edi
f0103eb3:	89 f1                	mov    %esi,%ecx
f0103eb5:	d3 e8                	shr    %cl,%eax
f0103eb7:	89 e9                	mov    %ebp,%ecx
f0103eb9:	09 f8                	or     %edi,%eax
f0103ebb:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0103ebf:	f7 74 24 04          	divl   0x4(%esp)
f0103ec3:	d3 e7                	shl    %cl,%edi
f0103ec5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103ec9:	89 d7                	mov    %edx,%edi
f0103ecb:	f7 64 24 08          	mull   0x8(%esp)
f0103ecf:	39 d7                	cmp    %edx,%edi
f0103ed1:	89 c1                	mov    %eax,%ecx
f0103ed3:	89 14 24             	mov    %edx,(%esp)
f0103ed6:	72 2c                	jb     f0103f04 <__umoddi3+0x134>
f0103ed8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0103edc:	72 22                	jb     f0103f00 <__umoddi3+0x130>
f0103ede:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0103ee2:	29 c8                	sub    %ecx,%eax
f0103ee4:	19 d7                	sbb    %edx,%edi
f0103ee6:	89 e9                	mov    %ebp,%ecx
f0103ee8:	89 fa                	mov    %edi,%edx
f0103eea:	d3 e8                	shr    %cl,%eax
f0103eec:	89 f1                	mov    %esi,%ecx
f0103eee:	d3 e2                	shl    %cl,%edx
f0103ef0:	89 e9                	mov    %ebp,%ecx
f0103ef2:	d3 ef                	shr    %cl,%edi
f0103ef4:	09 d0                	or     %edx,%eax
f0103ef6:	89 fa                	mov    %edi,%edx
f0103ef8:	83 c4 14             	add    $0x14,%esp
f0103efb:	5e                   	pop    %esi
f0103efc:	5f                   	pop    %edi
f0103efd:	5d                   	pop    %ebp
f0103efe:	c3                   	ret    
f0103eff:	90                   	nop
f0103f00:	39 d7                	cmp    %edx,%edi
f0103f02:	75 da                	jne    f0103ede <__umoddi3+0x10e>
f0103f04:	8b 14 24             	mov    (%esp),%edx
f0103f07:	89 c1                	mov    %eax,%ecx
f0103f09:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0103f0d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0103f11:	eb cb                	jmp    f0103ede <__umoddi3+0x10e>
f0103f13:	90                   	nop
f0103f14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103f18:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0103f1c:	0f 82 0f ff ff ff    	jb     f0103e31 <__umoddi3+0x61>
f0103f22:	e9 1a ff ff ff       	jmp    f0103e41 <__umoddi3+0x71>
