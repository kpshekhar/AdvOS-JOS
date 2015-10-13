
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
f0100015:	b8 00 a0 11 00       	mov    $0x11a000,%eax
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
f0100034:	bc 00 a0 11 f0       	mov    $0xf011a000,%esp

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
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 90 ef 17 f0       	mov    $0xf017ef90,%eax
f010004b:	2d 69 e0 17 f0       	sub    $0xf017e069,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 69 e0 17 f0 	movl   $0xf017e069,(%esp)
f0100063:	e8 cf 4b 00 00       	call   f0104c37 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 b2 04 00 00       	call   f010051f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 e0 50 10 f0 	movl   $0xf01050e0,(%esp)
f010007c:	e8 8c 38 00 00       	call   f010390d <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 de 12 00 00       	call   f0101364 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100086:	e8 0d 32 00 00       	call   f0103298 <env_init>
	trap_init();
f010008b:	90                   	nop
f010008c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100090:	e8 f8 38 00 00       	call   f010398d <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100095:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010009c:	00 
f010009d:	c7 04 24 25 2d 13 f0 	movl   $0xf0132d25,(%esp)
f01000a4:	e8 c3 33 00 00       	call   f010346c <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000a9:	a1 d0 e2 17 f0       	mov    0xf017e2d0,%eax
f01000ae:	89 04 24             	mov    %eax,(%esp)
f01000b1:	e8 7b 37 00 00       	call   f0103831 <env_run>

f01000b6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000b6:	55                   	push   %ebp
f01000b7:	89 e5                	mov    %esp,%ebp
f01000b9:	56                   	push   %esi
f01000ba:	53                   	push   %ebx
f01000bb:	83 ec 10             	sub    $0x10,%esp
f01000be:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000c1:	83 3d 80 ef 17 f0 00 	cmpl   $0x0,0xf017ef80
f01000c8:	75 3d                	jne    f0100107 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000ca:	89 35 80 ef 17 f0    	mov    %esi,0xf017ef80

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000d0:	fa                   	cli    
f01000d1:	fc                   	cld    

	va_start(ap, fmt);
f01000d2:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000d5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000d8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01000df:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000e3:	c7 04 24 fb 50 10 f0 	movl   $0xf01050fb,(%esp)
f01000ea:	e8 1e 38 00 00       	call   f010390d <cprintf>
	vcprintf(fmt, ap);
f01000ef:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000f3:	89 34 24             	mov    %esi,(%esp)
f01000f6:	e8 df 37 00 00       	call   f01038da <vcprintf>
	cprintf("\n");
f01000fb:	c7 04 24 3c 67 10 f0 	movl   $0xf010673c,(%esp)
f0100102:	e8 06 38 00 00       	call   f010390d <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100107:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010010e:	e8 f2 06 00 00       	call   f0100805 <monitor>
f0100113:	eb f2                	jmp    f0100107 <_panic+0x51>

f0100115 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100115:	55                   	push   %ebp
f0100116:	89 e5                	mov    %esp,%ebp
f0100118:	53                   	push   %ebx
f0100119:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010011c:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f010011f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100122:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100126:	8b 45 08             	mov    0x8(%ebp),%eax
f0100129:	89 44 24 04          	mov    %eax,0x4(%esp)
f010012d:	c7 04 24 13 51 10 f0 	movl   $0xf0105113,(%esp)
f0100134:	e8 d4 37 00 00       	call   f010390d <cprintf>
	vcprintf(fmt, ap);
f0100139:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010013d:	8b 45 10             	mov    0x10(%ebp),%eax
f0100140:	89 04 24             	mov    %eax,(%esp)
f0100143:	e8 92 37 00 00       	call   f01038da <vcprintf>
	cprintf("\n");
f0100148:	c7 04 24 3c 67 10 f0 	movl   $0xf010673c,(%esp)
f010014f:	e8 b9 37 00 00       	call   f010390d <cprintf>
	va_end(ap);
}
f0100154:	83 c4 14             	add    $0x14,%esp
f0100157:	5b                   	pop    %ebx
f0100158:	5d                   	pop    %ebp
f0100159:	c3                   	ret    
f010015a:	66 90                	xchg   %ax,%ax
f010015c:	66 90                	xchg   %ax,%ax
f010015e:	66 90                	xchg   %ax,%ax

f0100160 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100160:	55                   	push   %ebp
f0100161:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100163:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100168:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100169:	a8 01                	test   $0x1,%al
f010016b:	74 08                	je     f0100175 <serial_proc_data+0x15>
f010016d:	b2 f8                	mov    $0xf8,%dl
f010016f:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100170:	0f b6 c0             	movzbl %al,%eax
f0100173:	eb 05                	jmp    f010017a <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100175:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010017a:	5d                   	pop    %ebp
f010017b:	c3                   	ret    

f010017c <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010017c:	55                   	push   %ebp
f010017d:	89 e5                	mov    %esp,%ebp
f010017f:	53                   	push   %ebx
f0100180:	83 ec 04             	sub    $0x4,%esp
f0100183:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100185:	eb 2a                	jmp    f01001b1 <cons_intr+0x35>
		if (c == 0)
f0100187:	85 d2                	test   %edx,%edx
f0100189:	74 26                	je     f01001b1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010018b:	a1 a4 e2 17 f0       	mov    0xf017e2a4,%eax
f0100190:	8d 48 01             	lea    0x1(%eax),%ecx
f0100193:	89 0d a4 e2 17 f0    	mov    %ecx,0xf017e2a4
f0100199:	88 90 a0 e0 17 f0    	mov    %dl,-0xfe81f60(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010019f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001a5:	75 0a                	jne    f01001b1 <cons_intr+0x35>
			cons.wpos = 0;
f01001a7:	c7 05 a4 e2 17 f0 00 	movl   $0x0,0xf017e2a4
f01001ae:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001b1:	ff d3                	call   *%ebx
f01001b3:	89 c2                	mov    %eax,%edx
f01001b5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001b8:	75 cd                	jne    f0100187 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001ba:	83 c4 04             	add    $0x4,%esp
f01001bd:	5b                   	pop    %ebx
f01001be:	5d                   	pop    %ebp
f01001bf:	c3                   	ret    

f01001c0 <kbd_proc_data>:
f01001c0:	ba 64 00 00 00       	mov    $0x64,%edx
f01001c5:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001c6:	a8 01                	test   $0x1,%al
f01001c8:	0f 84 ef 00 00 00    	je     f01002bd <kbd_proc_data+0xfd>
f01001ce:	b2 60                	mov    $0x60,%dl
f01001d0:	ec                   	in     (%dx),%al
f01001d1:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001d3:	3c e0                	cmp    $0xe0,%al
f01001d5:	75 0d                	jne    f01001e4 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f01001d7:	83 0d 80 e0 17 f0 40 	orl    $0x40,0xf017e080
		return 0;
f01001de:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001e3:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001e4:	55                   	push   %ebp
f01001e5:	89 e5                	mov    %esp,%ebp
f01001e7:	53                   	push   %ebx
f01001e8:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001eb:	84 c0                	test   %al,%al
f01001ed:	79 37                	jns    f0100226 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001ef:	8b 0d 80 e0 17 f0    	mov    0xf017e080,%ecx
f01001f5:	89 cb                	mov    %ecx,%ebx
f01001f7:	83 e3 40             	and    $0x40,%ebx
f01001fa:	83 e0 7f             	and    $0x7f,%eax
f01001fd:	85 db                	test   %ebx,%ebx
f01001ff:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100202:	0f b6 d2             	movzbl %dl,%edx
f0100205:	0f b6 82 80 52 10 f0 	movzbl -0xfefad80(%edx),%eax
f010020c:	83 c8 40             	or     $0x40,%eax
f010020f:	0f b6 c0             	movzbl %al,%eax
f0100212:	f7 d0                	not    %eax
f0100214:	21 c1                	and    %eax,%ecx
f0100216:	89 0d 80 e0 17 f0    	mov    %ecx,0xf017e080
		return 0;
f010021c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100221:	e9 9d 00 00 00       	jmp    f01002c3 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100226:	8b 0d 80 e0 17 f0    	mov    0xf017e080,%ecx
f010022c:	f6 c1 40             	test   $0x40,%cl
f010022f:	74 0e                	je     f010023f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100231:	83 c8 80             	or     $0xffffff80,%eax
f0100234:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100236:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100239:	89 0d 80 e0 17 f0    	mov    %ecx,0xf017e080
	}

	shift |= shiftcode[data];
f010023f:	0f b6 d2             	movzbl %dl,%edx
f0100242:	0f b6 82 80 52 10 f0 	movzbl -0xfefad80(%edx),%eax
f0100249:	0b 05 80 e0 17 f0    	or     0xf017e080,%eax
	shift ^= togglecode[data];
f010024f:	0f b6 8a 80 51 10 f0 	movzbl -0xfefae80(%edx),%ecx
f0100256:	31 c8                	xor    %ecx,%eax
f0100258:	a3 80 e0 17 f0       	mov    %eax,0xf017e080

	c = charcode[shift & (CTL | SHIFT)][data];
f010025d:	89 c1                	mov    %eax,%ecx
f010025f:	83 e1 03             	and    $0x3,%ecx
f0100262:	8b 0c 8d 60 51 10 f0 	mov    -0xfefaea0(,%ecx,4),%ecx
f0100269:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010026d:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100270:	a8 08                	test   $0x8,%al
f0100272:	74 1b                	je     f010028f <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f0100274:	89 da                	mov    %ebx,%edx
f0100276:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100279:	83 f9 19             	cmp    $0x19,%ecx
f010027c:	77 05                	ja     f0100283 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f010027e:	83 eb 20             	sub    $0x20,%ebx
f0100281:	eb 0c                	jmp    f010028f <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f0100283:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100286:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100289:	83 fa 19             	cmp    $0x19,%edx
f010028c:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010028f:	f7 d0                	not    %eax
f0100291:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100293:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100295:	f6 c2 06             	test   $0x6,%dl
f0100298:	75 29                	jne    f01002c3 <kbd_proc_data+0x103>
f010029a:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002a0:	75 21                	jne    f01002c3 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f01002a2:	c7 04 24 2d 51 10 f0 	movl   $0xf010512d,(%esp)
f01002a9:	e8 5f 36 00 00       	call   f010390d <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ae:	ba 92 00 00 00       	mov    $0x92,%edx
f01002b3:	b8 03 00 00 00       	mov    $0x3,%eax
f01002b8:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002b9:	89 d8                	mov    %ebx,%eax
f01002bb:	eb 06                	jmp    f01002c3 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002c2:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002c3:	83 c4 14             	add    $0x14,%esp
f01002c6:	5b                   	pop    %ebx
f01002c7:	5d                   	pop    %ebp
f01002c8:	c3                   	ret    

f01002c9 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002c9:	55                   	push   %ebp
f01002ca:	89 e5                	mov    %esp,%ebp
f01002cc:	57                   	push   %edi
f01002cd:	56                   	push   %esi
f01002ce:	53                   	push   %ebx
f01002cf:	83 ec 1c             	sub    $0x1c,%esp
f01002d2:	89 c7                	mov    %eax,%edi
f01002d4:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002d9:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002de:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002e3:	eb 06                	jmp    f01002eb <cons_putc+0x22>
f01002e5:	89 ca                	mov    %ecx,%edx
f01002e7:	ec                   	in     (%dx),%al
f01002e8:	ec                   	in     (%dx),%al
f01002e9:	ec                   	in     (%dx),%al
f01002ea:	ec                   	in     (%dx),%al
f01002eb:	89 f2                	mov    %esi,%edx
f01002ed:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002ee:	a8 20                	test   $0x20,%al
f01002f0:	75 05                	jne    f01002f7 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002f2:	83 eb 01             	sub    $0x1,%ebx
f01002f5:	75 ee                	jne    f01002e5 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01002f7:	89 f8                	mov    %edi,%eax
f01002f9:	0f b6 c0             	movzbl %al,%eax
f01002fc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ff:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100304:	ee                   	out    %al,(%dx)
f0100305:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010030a:	be 79 03 00 00       	mov    $0x379,%esi
f010030f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100314:	eb 06                	jmp    f010031c <cons_putc+0x53>
f0100316:	89 ca                	mov    %ecx,%edx
f0100318:	ec                   	in     (%dx),%al
f0100319:	ec                   	in     (%dx),%al
f010031a:	ec                   	in     (%dx),%al
f010031b:	ec                   	in     (%dx),%al
f010031c:	89 f2                	mov    %esi,%edx
f010031e:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010031f:	84 c0                	test   %al,%al
f0100321:	78 05                	js     f0100328 <cons_putc+0x5f>
f0100323:	83 eb 01             	sub    $0x1,%ebx
f0100326:	75 ee                	jne    f0100316 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100328:	ba 78 03 00 00       	mov    $0x378,%edx
f010032d:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100331:	ee                   	out    %al,(%dx)
f0100332:	b2 7a                	mov    $0x7a,%dl
f0100334:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100339:	ee                   	out    %al,(%dx)
f010033a:	b8 08 00 00 00       	mov    $0x8,%eax
f010033f:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100340:	89 fa                	mov    %edi,%edx
f0100342:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100348:	89 f8                	mov    %edi,%eax
f010034a:	80 cc 07             	or     $0x7,%ah
f010034d:	85 d2                	test   %edx,%edx
f010034f:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100352:	89 f8                	mov    %edi,%eax
f0100354:	0f b6 c0             	movzbl %al,%eax
f0100357:	83 f8 09             	cmp    $0x9,%eax
f010035a:	74 76                	je     f01003d2 <cons_putc+0x109>
f010035c:	83 f8 09             	cmp    $0x9,%eax
f010035f:	7f 0a                	jg     f010036b <cons_putc+0xa2>
f0100361:	83 f8 08             	cmp    $0x8,%eax
f0100364:	74 16                	je     f010037c <cons_putc+0xb3>
f0100366:	e9 9b 00 00 00       	jmp    f0100406 <cons_putc+0x13d>
f010036b:	83 f8 0a             	cmp    $0xa,%eax
f010036e:	66 90                	xchg   %ax,%ax
f0100370:	74 3a                	je     f01003ac <cons_putc+0xe3>
f0100372:	83 f8 0d             	cmp    $0xd,%eax
f0100375:	74 3d                	je     f01003b4 <cons_putc+0xeb>
f0100377:	e9 8a 00 00 00       	jmp    f0100406 <cons_putc+0x13d>
	case '\b':
		if (crt_pos > 0) {
f010037c:	0f b7 05 a8 e2 17 f0 	movzwl 0xf017e2a8,%eax
f0100383:	66 85 c0             	test   %ax,%ax
f0100386:	0f 84 e5 00 00 00    	je     f0100471 <cons_putc+0x1a8>
			crt_pos--;
f010038c:	83 e8 01             	sub    $0x1,%eax
f010038f:	66 a3 a8 e2 17 f0    	mov    %ax,0xf017e2a8
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100395:	0f b7 c0             	movzwl %ax,%eax
f0100398:	66 81 e7 00 ff       	and    $0xff00,%di
f010039d:	83 cf 20             	or     $0x20,%edi
f01003a0:	8b 15 ac e2 17 f0    	mov    0xf017e2ac,%edx
f01003a6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003aa:	eb 78                	jmp    f0100424 <cons_putc+0x15b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003ac:	66 83 05 a8 e2 17 f0 	addw   $0x50,0xf017e2a8
f01003b3:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003b4:	0f b7 05 a8 e2 17 f0 	movzwl 0xf017e2a8,%eax
f01003bb:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003c1:	c1 e8 16             	shr    $0x16,%eax
f01003c4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003c7:	c1 e0 04             	shl    $0x4,%eax
f01003ca:	66 a3 a8 e2 17 f0    	mov    %ax,0xf017e2a8
f01003d0:	eb 52                	jmp    f0100424 <cons_putc+0x15b>
		break;
	case '\t':
		cons_putc(' ');
f01003d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d7:	e8 ed fe ff ff       	call   f01002c9 <cons_putc>
		cons_putc(' ');
f01003dc:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e1:	e8 e3 fe ff ff       	call   f01002c9 <cons_putc>
		cons_putc(' ');
f01003e6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003eb:	e8 d9 fe ff ff       	call   f01002c9 <cons_putc>
		cons_putc(' ');
f01003f0:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f5:	e8 cf fe ff ff       	call   f01002c9 <cons_putc>
		cons_putc(' ');
f01003fa:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ff:	e8 c5 fe ff ff       	call   f01002c9 <cons_putc>
f0100404:	eb 1e                	jmp    f0100424 <cons_putc+0x15b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100406:	0f b7 05 a8 e2 17 f0 	movzwl 0xf017e2a8,%eax
f010040d:	8d 50 01             	lea    0x1(%eax),%edx
f0100410:	66 89 15 a8 e2 17 f0 	mov    %dx,0xf017e2a8
f0100417:	0f b7 c0             	movzwl %ax,%eax
f010041a:	8b 15 ac e2 17 f0    	mov    0xf017e2ac,%edx
f0100420:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100424:	66 81 3d a8 e2 17 f0 	cmpw   $0x7cf,0xf017e2a8
f010042b:	cf 07 
f010042d:	76 42                	jbe    f0100471 <cons_putc+0x1a8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010042f:	a1 ac e2 17 f0       	mov    0xf017e2ac,%eax
f0100434:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010043b:	00 
f010043c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100442:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100446:	89 04 24             	mov    %eax,(%esp)
f0100449:	e8 36 48 00 00       	call   f0104c84 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010044e:	8b 15 ac e2 17 f0    	mov    0xf017e2ac,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100454:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100459:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010045f:	83 c0 01             	add    $0x1,%eax
f0100462:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100467:	75 f0                	jne    f0100459 <cons_putc+0x190>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100469:	66 83 2d a8 e2 17 f0 	subw   $0x50,0xf017e2a8
f0100470:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100471:	8b 0d b0 e2 17 f0    	mov    0xf017e2b0,%ecx
f0100477:	b8 0e 00 00 00       	mov    $0xe,%eax
f010047c:	89 ca                	mov    %ecx,%edx
f010047e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010047f:	0f b7 1d a8 e2 17 f0 	movzwl 0xf017e2a8,%ebx
f0100486:	8d 71 01             	lea    0x1(%ecx),%esi
f0100489:	89 d8                	mov    %ebx,%eax
f010048b:	66 c1 e8 08          	shr    $0x8,%ax
f010048f:	89 f2                	mov    %esi,%edx
f0100491:	ee                   	out    %al,(%dx)
f0100492:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100497:	89 ca                	mov    %ecx,%edx
f0100499:	ee                   	out    %al,(%dx)
f010049a:	89 d8                	mov    %ebx,%eax
f010049c:	89 f2                	mov    %esi,%edx
f010049e:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010049f:	83 c4 1c             	add    $0x1c,%esp
f01004a2:	5b                   	pop    %ebx
f01004a3:	5e                   	pop    %esi
f01004a4:	5f                   	pop    %edi
f01004a5:	5d                   	pop    %ebp
f01004a6:	c3                   	ret    

f01004a7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004a7:	80 3d b4 e2 17 f0 00 	cmpb   $0x0,0xf017e2b4
f01004ae:	74 11                	je     f01004c1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004b0:	55                   	push   %ebp
f01004b1:	89 e5                	mov    %esp,%ebp
f01004b3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004b6:	b8 60 01 10 f0       	mov    $0xf0100160,%eax
f01004bb:	e8 bc fc ff ff       	call   f010017c <cons_intr>
}
f01004c0:	c9                   	leave  
f01004c1:	f3 c3                	repz ret 

f01004c3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004c3:	55                   	push   %ebp
f01004c4:	89 e5                	mov    %esp,%ebp
f01004c6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004c9:	b8 c0 01 10 f0       	mov    $0xf01001c0,%eax
f01004ce:	e8 a9 fc ff ff       	call   f010017c <cons_intr>
}
f01004d3:	c9                   	leave  
f01004d4:	c3                   	ret    

f01004d5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004d5:	55                   	push   %ebp
f01004d6:	89 e5                	mov    %esp,%ebp
f01004d8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004db:	e8 c7 ff ff ff       	call   f01004a7 <serial_intr>
	kbd_intr();
f01004e0:	e8 de ff ff ff       	call   f01004c3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004e5:	a1 a0 e2 17 f0       	mov    0xf017e2a0,%eax
f01004ea:	3b 05 a4 e2 17 f0    	cmp    0xf017e2a4,%eax
f01004f0:	74 26                	je     f0100518 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004f2:	8d 50 01             	lea    0x1(%eax),%edx
f01004f5:	89 15 a0 e2 17 f0    	mov    %edx,0xf017e2a0
f01004fb:	0f b6 88 a0 e0 17 f0 	movzbl -0xfe81f60(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100502:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100504:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010050a:	75 11                	jne    f010051d <cons_getc+0x48>
			cons.rpos = 0;
f010050c:	c7 05 a0 e2 17 f0 00 	movl   $0x0,0xf017e2a0
f0100513:	00 00 00 
f0100516:	eb 05                	jmp    f010051d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100518:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010051d:	c9                   	leave  
f010051e:	c3                   	ret    

f010051f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010051f:	55                   	push   %ebp
f0100520:	89 e5                	mov    %esp,%ebp
f0100522:	57                   	push   %edi
f0100523:	56                   	push   %esi
f0100524:	53                   	push   %ebx
f0100525:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100528:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010052f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100536:	5a a5 
	if (*cp != 0xA55A) {
f0100538:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010053f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100543:	74 11                	je     f0100556 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100545:	c7 05 b0 e2 17 f0 b4 	movl   $0x3b4,0xf017e2b0
f010054c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010054f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100554:	eb 16                	jmp    f010056c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100556:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010055d:	c7 05 b0 e2 17 f0 d4 	movl   $0x3d4,0xf017e2b0
f0100564:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100567:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010056c:	8b 0d b0 e2 17 f0    	mov    0xf017e2b0,%ecx
f0100572:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100577:	89 ca                	mov    %ecx,%edx
f0100579:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010057a:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010057d:	89 da                	mov    %ebx,%edx
f010057f:	ec                   	in     (%dx),%al
f0100580:	0f b6 f0             	movzbl %al,%esi
f0100583:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100586:	b8 0f 00 00 00       	mov    $0xf,%eax
f010058b:	89 ca                	mov    %ecx,%edx
f010058d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010058e:	89 da                	mov    %ebx,%edx
f0100590:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100591:	89 3d ac e2 17 f0    	mov    %edi,0xf017e2ac

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100597:	0f b6 d8             	movzbl %al,%ebx
f010059a:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f010059c:	66 89 35 a8 e2 17 f0 	mov    %si,0xf017e2a8
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005a3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ad:	89 f2                	mov    %esi,%edx
f01005af:	ee                   	out    %al,(%dx)
f01005b0:	b2 fb                	mov    $0xfb,%dl
f01005b2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005b7:	ee                   	out    %al,(%dx)
f01005b8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005bd:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005c2:	89 da                	mov    %ebx,%edx
f01005c4:	ee                   	out    %al,(%dx)
f01005c5:	b2 f9                	mov    $0xf9,%dl
f01005c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005cc:	ee                   	out    %al,(%dx)
f01005cd:	b2 fb                	mov    $0xfb,%dl
f01005cf:	b8 03 00 00 00       	mov    $0x3,%eax
f01005d4:	ee                   	out    %al,(%dx)
f01005d5:	b2 fc                	mov    $0xfc,%dl
f01005d7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005dc:	ee                   	out    %al,(%dx)
f01005dd:	b2 f9                	mov    $0xf9,%dl
f01005df:	b8 01 00 00 00       	mov    $0x1,%eax
f01005e4:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005e5:	b2 fd                	mov    $0xfd,%dl
f01005e7:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005e8:	3c ff                	cmp    $0xff,%al
f01005ea:	0f 95 c1             	setne  %cl
f01005ed:	88 0d b4 e2 17 f0    	mov    %cl,0xf017e2b4
f01005f3:	89 f2                	mov    %esi,%edx
f01005f5:	ec                   	in     (%dx),%al
f01005f6:	89 da                	mov    %ebx,%edx
f01005f8:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005f9:	84 c9                	test   %cl,%cl
f01005fb:	75 0c                	jne    f0100609 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f01005fd:	c7 04 24 39 51 10 f0 	movl   $0xf0105139,(%esp)
f0100604:	e8 04 33 00 00       	call   f010390d <cprintf>
}
f0100609:	83 c4 1c             	add    $0x1c,%esp
f010060c:	5b                   	pop    %ebx
f010060d:	5e                   	pop    %esi
f010060e:	5f                   	pop    %edi
f010060f:	5d                   	pop    %ebp
f0100610:	c3                   	ret    

f0100611 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100611:	55                   	push   %ebp
f0100612:	89 e5                	mov    %esp,%ebp
f0100614:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100617:	8b 45 08             	mov    0x8(%ebp),%eax
f010061a:	e8 aa fc ff ff       	call   f01002c9 <cons_putc>
}
f010061f:	c9                   	leave  
f0100620:	c3                   	ret    

f0100621 <getchar>:

int
getchar(void)
{
f0100621:	55                   	push   %ebp
f0100622:	89 e5                	mov    %esp,%ebp
f0100624:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100627:	e8 a9 fe ff ff       	call   f01004d5 <cons_getc>
f010062c:	85 c0                	test   %eax,%eax
f010062e:	74 f7                	je     f0100627 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100630:	c9                   	leave  
f0100631:	c3                   	ret    

f0100632 <iscons>:

int
iscons(int fdnum)
{
f0100632:	55                   	push   %ebp
f0100633:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100635:	b8 01 00 00 00       	mov    $0x1,%eax
f010063a:	5d                   	pop    %ebp
f010063b:	c3                   	ret    
f010063c:	66 90                	xchg   %ax,%ax
f010063e:	66 90                	xchg   %ax,%ax

f0100640 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100640:	55                   	push   %ebp
f0100641:	89 e5                	mov    %esp,%ebp
f0100643:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100646:	c7 44 24 08 80 53 10 	movl   $0xf0105380,0x8(%esp)
f010064d:	f0 
f010064e:	c7 44 24 04 9e 53 10 	movl   $0xf010539e,0x4(%esp)
f0100655:	f0 
f0100656:	c7 04 24 a3 53 10 f0 	movl   $0xf01053a3,(%esp)
f010065d:	e8 ab 32 00 00       	call   f010390d <cprintf>
f0100662:	c7 44 24 08 44 54 10 	movl   $0xf0105444,0x8(%esp)
f0100669:	f0 
f010066a:	c7 44 24 04 ac 53 10 	movl   $0xf01053ac,0x4(%esp)
f0100671:	f0 
f0100672:	c7 04 24 a3 53 10 f0 	movl   $0xf01053a3,(%esp)
f0100679:	e8 8f 32 00 00       	call   f010390d <cprintf>
f010067e:	c7 44 24 08 b5 53 10 	movl   $0xf01053b5,0x8(%esp)
f0100685:	f0 
f0100686:	c7 44 24 04 d2 53 10 	movl   $0xf01053d2,0x4(%esp)
f010068d:	f0 
f010068e:	c7 04 24 a3 53 10 f0 	movl   $0xf01053a3,(%esp)
f0100695:	e8 73 32 00 00       	call   f010390d <cprintf>
	return 0;
}
f010069a:	b8 00 00 00 00       	mov    $0x0,%eax
f010069f:	c9                   	leave  
f01006a0:	c3                   	ret    

f01006a1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006a1:	55                   	push   %ebp
f01006a2:	89 e5                	mov    %esp,%ebp
f01006a4:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006a7:	c7 04 24 dd 53 10 f0 	movl   $0xf01053dd,(%esp)
f01006ae:	e8 5a 32 00 00       	call   f010390d <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006b3:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006ba:	00 
f01006bb:	c7 04 24 6c 54 10 f0 	movl   $0xf010546c,(%esp)
f01006c2:	e8 46 32 00 00       	call   f010390d <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006c7:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006ce:	00 
f01006cf:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006d6:	f0 
f01006d7:	c7 04 24 94 54 10 f0 	movl   $0xf0105494,(%esp)
f01006de:	e8 2a 32 00 00       	call   f010390d <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006e3:	c7 44 24 08 c7 50 10 	movl   $0x1050c7,0x8(%esp)
f01006ea:	00 
f01006eb:	c7 44 24 04 c7 50 10 	movl   $0xf01050c7,0x4(%esp)
f01006f2:	f0 
f01006f3:	c7 04 24 b8 54 10 f0 	movl   $0xf01054b8,(%esp)
f01006fa:	e8 0e 32 00 00       	call   f010390d <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ff:	c7 44 24 08 69 e0 17 	movl   $0x17e069,0x8(%esp)
f0100706:	00 
f0100707:	c7 44 24 04 69 e0 17 	movl   $0xf017e069,0x4(%esp)
f010070e:	f0 
f010070f:	c7 04 24 dc 54 10 f0 	movl   $0xf01054dc,(%esp)
f0100716:	e8 f2 31 00 00       	call   f010390d <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010071b:	c7 44 24 08 90 ef 17 	movl   $0x17ef90,0x8(%esp)
f0100722:	00 
f0100723:	c7 44 24 04 90 ef 17 	movl   $0xf017ef90,0x4(%esp)
f010072a:	f0 
f010072b:	c7 04 24 00 55 10 f0 	movl   $0xf0105500,(%esp)
f0100732:	e8 d6 31 00 00       	call   f010390d <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100737:	b8 8f f3 17 f0       	mov    $0xf017f38f,%eax
f010073c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100741:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100746:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010074c:	85 c0                	test   %eax,%eax
f010074e:	0f 48 c2             	cmovs  %edx,%eax
f0100751:	c1 f8 0a             	sar    $0xa,%eax
f0100754:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100758:	c7 04 24 24 55 10 f0 	movl   $0xf0105524,(%esp)
f010075f:	e8 a9 31 00 00       	call   f010390d <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100764:	b8 00 00 00 00       	mov    $0x0,%eax
f0100769:	c9                   	leave  
f010076a:	c3                   	ret    

f010076b <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010076b:	55                   	push   %ebp
f010076c:	89 e5                	mov    %esp,%ebp
f010076e:	57                   	push   %edi
f010076f:	56                   	push   %esi
f0100770:	53                   	push   %ebx
f0100771:	83 ec 6c             	sub    $0x6c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100774:	89 eb                	mov    %ebp,%ebx
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
f0100776:	c7 04 24 f6 53 10 f0 	movl   $0xf01053f6,(%esp)
f010077d:	e8 8b 31 00 00       	call   f010390d <cprintf>
	
	while (ebp){
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
		debuginfo_eip(eip, &sym);
f0100782:	8d 7d d0             	lea    -0x30(%ebp),%edi
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f0100785:	eb 6d                	jmp    f01007f4 <mon_backtrace+0x89>
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
f0100787:	8b 73 04             	mov    0x4(%ebx),%esi
		debuginfo_eip(eip, &sym);
f010078a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010078e:	89 34 24             	mov    %esi,(%esp)
f0100791:	e8 89 39 00 00       	call   f010411f <debuginfo_eip>
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n %s:%d: %.*s+%d\n",ebp,eip,
f0100796:	89 f0                	mov    %esi,%eax
f0100798:	2b 45 e0             	sub    -0x20(%ebp),%eax
f010079b:	89 44 24 30          	mov    %eax,0x30(%esp)
f010079f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01007a2:	89 44 24 2c          	mov    %eax,0x2c(%esp)
f01007a6:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01007a9:	89 44 24 28          	mov    %eax,0x28(%esp)
f01007ad:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007b0:	89 44 24 24          	mov    %eax,0x24(%esp)
f01007b4:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01007b7:	89 44 24 20          	mov    %eax,0x20(%esp)
f01007bb:	8b 43 18             	mov    0x18(%ebx),%eax
f01007be:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f01007c2:	8b 43 14             	mov    0x14(%ebx),%eax
f01007c5:	89 44 24 18          	mov    %eax,0x18(%esp)
f01007c9:	8b 43 10             	mov    0x10(%ebx),%eax
f01007cc:	89 44 24 14          	mov    %eax,0x14(%esp)
f01007d0:	8b 43 0c             	mov    0xc(%ebx),%eax
f01007d3:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007d7:	8b 43 08             	mov    0x8(%ebx),%eax
f01007da:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007de:	89 74 24 08          	mov    %esi,0x8(%esp)
f01007e2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01007e6:	c7 04 24 50 55 10 f0 	movl   $0xf0105550,(%esp)
f01007ed:	e8 1b 31 00 00       	call   f010390d <cprintf>
		*((uint32_t *)ebp + 6), sym.eip_file,
			      sym.eip_line,
			      sym.eip_fn_namelen,
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
f01007f2:	8b 1b                	mov    (%ebx),%ebx
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f01007f4:	85 db                	test   %ebx,%ebx
f01007f6:	75 8f                	jne    f0100787 <mon_backtrace+0x1c>
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
	}
	return 0;
}
f01007f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01007fd:	83 c4 6c             	add    $0x6c,%esp
f0100800:	5b                   	pop    %ebx
f0100801:	5e                   	pop    %esi
f0100802:	5f                   	pop    %edi
f0100803:	5d                   	pop    %ebp
f0100804:	c3                   	ret    

f0100805 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100805:	55                   	push   %ebp
f0100806:	89 e5                	mov    %esp,%ebp
f0100808:	57                   	push   %edi
f0100809:	56                   	push   %esi
f010080a:	53                   	push   %ebx
f010080b:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010080e:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0100815:	e8 f3 30 00 00       	call   f010390d <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010081a:	c7 04 24 b8 55 10 f0 	movl   $0xf01055b8,(%esp)
f0100821:	e8 e7 30 00 00       	call   f010390d <cprintf>

	if (tf != NULL)
f0100826:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010082a:	74 0b                	je     f0100837 <monitor+0x32>
		print_trapframe(tf);
f010082c:	8b 45 08             	mov    0x8(%ebp),%eax
f010082f:	89 04 24             	mov    %eax,(%esp)
f0100832:	e8 9e 32 00 00       	call   f0103ad5 <print_trapframe>

	while (1) {
		buf = readline("K> ");
f0100837:	c7 04 24 08 54 10 f0 	movl   $0xf0105408,(%esp)
f010083e:	e8 9d 41 00 00       	call   f01049e0 <readline>
f0100843:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100845:	85 c0                	test   %eax,%eax
f0100847:	74 ee                	je     f0100837 <monitor+0x32>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100849:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100850:	be 00 00 00 00       	mov    $0x0,%esi
f0100855:	eb 0a                	jmp    f0100861 <monitor+0x5c>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100857:	c6 03 00             	movb   $0x0,(%ebx)
f010085a:	89 f7                	mov    %esi,%edi
f010085c:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010085f:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100861:	0f b6 03             	movzbl (%ebx),%eax
f0100864:	84 c0                	test   %al,%al
f0100866:	74 63                	je     f01008cb <monitor+0xc6>
f0100868:	0f be c0             	movsbl %al,%eax
f010086b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010086f:	c7 04 24 0c 54 10 f0 	movl   $0xf010540c,(%esp)
f0100876:	e8 7f 43 00 00       	call   f0104bfa <strchr>
f010087b:	85 c0                	test   %eax,%eax
f010087d:	75 d8                	jne    f0100857 <monitor+0x52>
			*buf++ = 0;
		if (*buf == 0)
f010087f:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100882:	74 47                	je     f01008cb <monitor+0xc6>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100884:	83 fe 0f             	cmp    $0xf,%esi
f0100887:	75 16                	jne    f010089f <monitor+0x9a>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100889:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100890:	00 
f0100891:	c7 04 24 11 54 10 f0 	movl   $0xf0105411,(%esp)
f0100898:	e8 70 30 00 00       	call   f010390d <cprintf>
f010089d:	eb 98                	jmp    f0100837 <monitor+0x32>
			return 0;
		}
		argv[argc++] = buf;
f010089f:	8d 7e 01             	lea    0x1(%esi),%edi
f01008a2:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008a6:	eb 03                	jmp    f01008ab <monitor+0xa6>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008a8:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008ab:	0f b6 03             	movzbl (%ebx),%eax
f01008ae:	84 c0                	test   %al,%al
f01008b0:	74 ad                	je     f010085f <monitor+0x5a>
f01008b2:	0f be c0             	movsbl %al,%eax
f01008b5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008b9:	c7 04 24 0c 54 10 f0 	movl   $0xf010540c,(%esp)
f01008c0:	e8 35 43 00 00       	call   f0104bfa <strchr>
f01008c5:	85 c0                	test   %eax,%eax
f01008c7:	74 df                	je     f01008a8 <monitor+0xa3>
f01008c9:	eb 94                	jmp    f010085f <monitor+0x5a>
			buf++;
	}
	argv[argc] = 0;
f01008cb:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008d2:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008d3:	85 f6                	test   %esi,%esi
f01008d5:	0f 84 5c ff ff ff    	je     f0100837 <monitor+0x32>
f01008db:	bb 00 00 00 00       	mov    $0x0,%ebx
f01008e0:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008e3:	8b 04 85 e0 55 10 f0 	mov    -0xfefaa20(,%eax,4),%eax
f01008ea:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008ee:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008f1:	89 04 24             	mov    %eax,(%esp)
f01008f4:	e8 a3 42 00 00       	call   f0104b9c <strcmp>
f01008f9:	85 c0                	test   %eax,%eax
f01008fb:	75 24                	jne    f0100921 <monitor+0x11c>
			return commands[i].func(argc, argv, tf);
f01008fd:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100900:	8b 55 08             	mov    0x8(%ebp),%edx
f0100903:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100907:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f010090a:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010090e:	89 34 24             	mov    %esi,(%esp)
f0100911:	ff 14 85 e8 55 10 f0 	call   *-0xfefaa18(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100918:	85 c0                	test   %eax,%eax
f010091a:	78 25                	js     f0100941 <monitor+0x13c>
f010091c:	e9 16 ff ff ff       	jmp    f0100837 <monitor+0x32>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100921:	83 c3 01             	add    $0x1,%ebx
f0100924:	83 fb 03             	cmp    $0x3,%ebx
f0100927:	75 b7                	jne    f01008e0 <monitor+0xdb>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100929:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010092c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100930:	c7 04 24 2e 54 10 f0 	movl   $0xf010542e,(%esp)
f0100937:	e8 d1 2f 00 00       	call   f010390d <cprintf>
f010093c:	e9 f6 fe ff ff       	jmp    f0100837 <monitor+0x32>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100941:	83 c4 5c             	add    $0x5c,%esp
f0100944:	5b                   	pop    %ebx
f0100945:	5e                   	pop    %esi
f0100946:	5f                   	pop    %edi
f0100947:	5d                   	pop    %ebp
f0100948:	c3                   	ret    
f0100949:	66 90                	xchg   %ax,%ax
f010094b:	66 90                	xchg   %ax,%ax
f010094d:	66 90                	xchg   %ax,%ax
f010094f:	90                   	nop

f0100950 <page2kva>:
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100950:	2b 05 8c ef 17 f0    	sub    0xf017ef8c,%eax
f0100956:	c1 f8 03             	sar    $0x3,%eax
f0100959:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010095c:	89 c2                	mov    %eax,%edx
f010095e:	c1 ea 0c             	shr    $0xc,%edx
f0100961:	3b 15 84 ef 17 f0    	cmp    0xf017ef84,%edx
f0100967:	72 26                	jb     f010098f <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100969:	55                   	push   %ebp
f010096a:	89 e5                	mov    %esp,%ebp
f010096c:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010096f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100973:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f010097a:	f0 
f010097b:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100982:	00 
f0100983:	c7 04 24 b5 5e 10 f0 	movl   $0xf0105eb5,(%esp)
f010098a:	e8 27 f7 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f010098f:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));  //page2kva returns virtual address of the 
}
f0100994:	c3                   	ret    

f0100995 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100995:	89 d1                	mov    %edx,%ecx
f0100997:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f010099a:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f010099d:	a8 01                	test   $0x1,%al
f010099f:	74 5d                	je     f01009fe <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f01009a1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009a6:	89 c1                	mov    %eax,%ecx
f01009a8:	c1 e9 0c             	shr    $0xc,%ecx
f01009ab:	3b 0d 84 ef 17 f0    	cmp    0xf017ef84,%ecx
f01009b1:	72 26                	jb     f01009d9 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01009b3:	55                   	push   %ebp
f01009b4:	89 e5                	mov    %esp,%ebp
f01009b6:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009bd:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f01009c4:	f0 
f01009c5:	c7 44 24 04 99 03 00 	movl   $0x399,0x4(%esp)
f01009cc:	00 
f01009cd:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f01009d4:	e8 dd f6 ff ff       	call   f01000b6 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f01009d9:	c1 ea 0c             	shr    $0xc,%edx
f01009dc:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009e2:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01009e9:	89 c2                	mov    %eax,%edx
f01009eb:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009ee:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009f3:	85 d2                	test   %edx,%edx
f01009f5:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009fa:	0f 44 c2             	cmove  %edx,%eax
f01009fd:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100a03:	c3                   	ret    

f0100a04 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100a04:	83 3d bc e2 17 f0 00 	cmpl   $0x0,0xf017e2bc
f0100a0b:	75 11                	jne    f0100a1e <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE); // Roundup function rounds according to the given functions
f0100a0d:	ba 8f ff 17 f0       	mov    $0xf017ff8f,%edx
f0100a12:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a18:	89 15 bc e2 17 f0    	mov    %edx,0xf017e2bc
	}
	
	if (n==0){
f0100a1e:	85 c0                	test   %eax,%eax
f0100a20:	75 06                	jne    f0100a28 <boot_alloc+0x24>
	return nextfree;
f0100a22:	a1 bc e2 17 f0       	mov    0xf017e2bc,%eax
f0100a27:	c3                   	ret    
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result  = nextfree;
f0100a28:	8b 0d bc e2 17 f0    	mov    0xf017e2bc,%ecx
	nextfree += ROUNDUP(n,PGSIZE);
f0100a2e:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100a34:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a3a:	01 ca                	add    %ecx,%edx
f0100a3c:	89 15 bc e2 17 f0    	mov    %edx,0xf017e2bc
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100a42:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0100a48:	77 26                	ja     f0100a70 <boot_alloc+0x6c>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100a4a:	55                   	push   %ebp
f0100a4b:	89 e5                	mov    %esp,%ebp
f0100a4d:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100a50:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100a54:	c7 44 24 08 28 56 10 	movl   $0xf0105628,0x8(%esp)
f0100a5b:	f0 
f0100a5c:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
f0100a63:	00 
f0100a64:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0100a6b:	e8 46 f6 ff ff       	call   f01000b6 <_panic>
	// LAB 2: Your code here.
	result  = nextfree;
	nextfree += ROUNDUP(n,PGSIZE);
	
	
	if ((PADDR(nextfree))>npages*PGSIZE){
f0100a70:	a1 84 ef 17 f0       	mov    0xf017ef84,%eax
f0100a75:	c1 e0 0c             	shl    $0xc,%eax
	return (physaddr_t)kva - KERNBASE;
f0100a78:	81 c2 00 00 00 10    	add    $0x10000000,%edx
		return 0;
f0100a7e:	39 c2                	cmp    %eax,%edx
f0100a80:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a85:	0f 46 c1             	cmovbe %ecx,%eax
	}
	return result;
}
f0100a88:	c3                   	ret    

f0100a89 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a89:	55                   	push   %ebp
f0100a8a:	89 e5                	mov    %esp,%ebp
f0100a8c:	57                   	push   %edi
f0100a8d:	56                   	push   %esi
f0100a8e:	53                   	push   %ebx
f0100a8f:	83 ec 4c             	sub    $0x4c,%esp
f0100a92:	89 45 c0             	mov    %eax,-0x40(%ebp)
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a95:	84 c0                	test   %al,%al
f0100a97:	0f 85 1d 03 00 00    	jne    f0100dba <check_page_free_list+0x331>
f0100a9d:	e9 2a 03 00 00       	jmp    f0100dcc <check_page_free_list+0x343>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100aa2:	c7 44 24 08 4c 56 10 	movl   $0xf010564c,0x8(%esp)
f0100aa9:	f0 
f0100aaa:	c7 44 24 04 d6 02 00 	movl   $0x2d6,0x4(%esp)
f0100ab1:	00 
f0100ab2:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0100ab9:	e8 f8 f5 ff ff       	call   f01000b6 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100abe:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100ac1:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100ac4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ac7:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100aca:	89 c2                	mov    %eax,%edx
f0100acc:	2b 15 8c ef 17 f0    	sub    0xf017ef8c,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ad2:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100ad8:	0f 95 c2             	setne  %dl
f0100adb:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100ade:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100ae2:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100ae4:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ae8:	8b 00                	mov    (%eax),%eax
f0100aea:	85 c0                	test   %eax,%eax
f0100aec:	75 dc                	jne    f0100aca <check_page_free_list+0x41>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100aee:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100af1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100af7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100afa:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100afd:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100aff:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100b02:	a3 c4 e2 17 f0       	mov    %eax,0xf017e2c4
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b07:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b0c:	8b 1d c4 e2 17 f0    	mov    0xf017e2c4,%ebx
f0100b12:	eb 63                	jmp    f0100b77 <check_page_free_list+0xee>
f0100b14:	89 d8                	mov    %ebx,%eax
f0100b16:	2b 05 8c ef 17 f0    	sub    0xf017ef8c,%eax
f0100b1c:	c1 f8 03             	sar    $0x3,%eax
f0100b1f:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b22:	89 c2                	mov    %eax,%edx
f0100b24:	c1 ea 16             	shr    $0x16,%edx
f0100b27:	39 f2                	cmp    %esi,%edx
f0100b29:	73 4a                	jae    f0100b75 <check_page_free_list+0xec>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b2b:	89 c2                	mov    %eax,%edx
f0100b2d:	c1 ea 0c             	shr    $0xc,%edx
f0100b30:	3b 15 84 ef 17 f0    	cmp    0xf017ef84,%edx
f0100b36:	72 20                	jb     f0100b58 <check_page_free_list+0xcf>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b38:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b3c:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f0100b43:	f0 
f0100b44:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100b4b:	00 
f0100b4c:	c7 04 24 b5 5e 10 f0 	movl   $0xf0105eb5,(%esp)
f0100b53:	e8 5e f5 ff ff       	call   f01000b6 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b58:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b5f:	00 
f0100b60:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b67:	00 
	return (void *)(pa + KERNBASE);
f0100b68:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b6d:	89 04 24             	mov    %eax,(%esp)
f0100b70:	e8 c2 40 00 00       	call   f0104c37 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b75:	8b 1b                	mov    (%ebx),%ebx
f0100b77:	85 db                	test   %ebx,%ebx
f0100b79:	75 99                	jne    f0100b14 <check_page_free_list+0x8b>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b7b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b80:	e8 7f fe ff ff       	call   f0100a04 <boot_alloc>
f0100b85:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b88:	8b 15 c4 e2 17 f0    	mov    0xf017e2c4,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b8e:	8b 0d 8c ef 17 f0    	mov    0xf017ef8c,%ecx
		assert(pp < pages + npages);
f0100b94:	a1 84 ef 17 f0       	mov    0xf017ef84,%eax
f0100b99:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100b9c:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100b9f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ba2:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100ba5:	bf 00 00 00 00       	mov    $0x0,%edi
f0100baa:	89 5d cc             	mov    %ebx,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bad:	e9 97 01 00 00       	jmp    f0100d49 <check_page_free_list+0x2c0>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bb2:	39 ca                	cmp    %ecx,%edx
f0100bb4:	73 24                	jae    f0100bda <check_page_free_list+0x151>
f0100bb6:	c7 44 24 0c cf 5e 10 	movl   $0xf0105ecf,0xc(%esp)
f0100bbd:	f0 
f0100bbe:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0100bc5:	f0 
f0100bc6:	c7 44 24 04 f0 02 00 	movl   $0x2f0,0x4(%esp)
f0100bcd:	00 
f0100bce:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0100bd5:	e8 dc f4 ff ff       	call   f01000b6 <_panic>
		assert(pp < pages + npages);
f0100bda:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bdd:	72 24                	jb     f0100c03 <check_page_free_list+0x17a>
f0100bdf:	c7 44 24 0c f0 5e 10 	movl   $0xf0105ef0,0xc(%esp)
f0100be6:	f0 
f0100be7:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0100bee:	f0 
f0100bef:	c7 44 24 04 f1 02 00 	movl   $0x2f1,0x4(%esp)
f0100bf6:	00 
f0100bf7:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0100bfe:	e8 b3 f4 ff ff       	call   f01000b6 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c03:	89 d0                	mov    %edx,%eax
f0100c05:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c08:	a8 07                	test   $0x7,%al
f0100c0a:	74 24                	je     f0100c30 <check_page_free_list+0x1a7>
f0100c0c:	c7 44 24 0c 70 56 10 	movl   $0xf0105670,0xc(%esp)
f0100c13:	f0 
f0100c14:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0100c1b:	f0 
f0100c1c:	c7 44 24 04 f2 02 00 	movl   $0x2f2,0x4(%esp)
f0100c23:	00 
f0100c24:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0100c2b:	e8 86 f4 ff ff       	call   f01000b6 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c30:	c1 f8 03             	sar    $0x3,%eax
f0100c33:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c36:	85 c0                	test   %eax,%eax
f0100c38:	75 24                	jne    f0100c5e <check_page_free_list+0x1d5>
f0100c3a:	c7 44 24 0c 04 5f 10 	movl   $0xf0105f04,0xc(%esp)
f0100c41:	f0 
f0100c42:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0100c49:	f0 
f0100c4a:	c7 44 24 04 f5 02 00 	movl   $0x2f5,0x4(%esp)
f0100c51:	00 
f0100c52:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0100c59:	e8 58 f4 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c5e:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c63:	75 24                	jne    f0100c89 <check_page_free_list+0x200>
f0100c65:	c7 44 24 0c 15 5f 10 	movl   $0xf0105f15,0xc(%esp)
f0100c6c:	f0 
f0100c6d:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0100c74:	f0 
f0100c75:	c7 44 24 04 f6 02 00 	movl   $0x2f6,0x4(%esp)
f0100c7c:	00 
f0100c7d:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0100c84:	e8 2d f4 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c89:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c8e:	75 24                	jne    f0100cb4 <check_page_free_list+0x22b>
f0100c90:	c7 44 24 0c a4 56 10 	movl   $0xf01056a4,0xc(%esp)
f0100c97:	f0 
f0100c98:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0100c9f:	f0 
f0100ca0:	c7 44 24 04 f7 02 00 	movl   $0x2f7,0x4(%esp)
f0100ca7:	00 
f0100ca8:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0100caf:	e8 02 f4 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cb4:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cb9:	75 24                	jne    f0100cdf <check_page_free_list+0x256>
f0100cbb:	c7 44 24 0c 2e 5f 10 	movl   $0xf0105f2e,0xc(%esp)
f0100cc2:	f0 
f0100cc3:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0100cca:	f0 
f0100ccb:	c7 44 24 04 f8 02 00 	movl   $0x2f8,0x4(%esp)
f0100cd2:	00 
f0100cd3:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0100cda:	e8 d7 f3 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cdf:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100ce4:	76 58                	jbe    f0100d3e <check_page_free_list+0x2b5>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ce6:	89 c3                	mov    %eax,%ebx
f0100ce8:	c1 eb 0c             	shr    $0xc,%ebx
f0100ceb:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f0100cee:	77 20                	ja     f0100d10 <check_page_free_list+0x287>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cf0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100cf4:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f0100cfb:	f0 
f0100cfc:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100d03:	00 
f0100d04:	c7 04 24 b5 5e 10 f0 	movl   $0xf0105eb5,(%esp)
f0100d0b:	e8 a6 f3 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0100d10:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d15:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100d18:	76 2a                	jbe    f0100d44 <check_page_free_list+0x2bb>
f0100d1a:	c7 44 24 0c c8 56 10 	movl   $0xf01056c8,0xc(%esp)
f0100d21:	f0 
f0100d22:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0100d29:	f0 
f0100d2a:	c7 44 24 04 f9 02 00 	movl   $0x2f9,0x4(%esp)
f0100d31:	00 
f0100d32:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0100d39:	e8 78 f3 ff ff       	call   f01000b6 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d3e:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0100d42:	eb 03                	jmp    f0100d47 <check_page_free_list+0x2be>
		else
			++nfree_extmem;
f0100d44:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d47:	8b 12                	mov    (%edx),%edx
f0100d49:	85 d2                	test   %edx,%edx
f0100d4b:	0f 85 61 fe ff ff    	jne    f0100bb2 <check_page_free_list+0x129>
f0100d51:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d54:	85 db                	test   %ebx,%ebx
f0100d56:	7f 24                	jg     f0100d7c <check_page_free_list+0x2f3>
f0100d58:	c7 44 24 0c 48 5f 10 	movl   $0xf0105f48,0xc(%esp)
f0100d5f:	f0 
f0100d60:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0100d67:	f0 
f0100d68:	c7 44 24 04 01 03 00 	movl   $0x301,0x4(%esp)
f0100d6f:	00 
f0100d70:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0100d77:	e8 3a f3 ff ff       	call   f01000b6 <_panic>
	assert(nfree_extmem > 0);
f0100d7c:	85 ff                	test   %edi,%edi
f0100d7e:	7f 24                	jg     f0100da4 <check_page_free_list+0x31b>
f0100d80:	c7 44 24 0c 5a 5f 10 	movl   $0xf0105f5a,0xc(%esp)
f0100d87:	f0 
f0100d88:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0100d8f:	f0 
f0100d90:	c7 44 24 04 02 03 00 	movl   $0x302,0x4(%esp)
f0100d97:	00 
f0100d98:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0100d9f:	e8 12 f3 ff ff       	call   f01000b6 <_panic>
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
f0100da4:	0f b6 45 c0          	movzbl -0x40(%ebp),%eax
f0100da8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dac:	c7 04 24 10 57 10 f0 	movl   $0xf0105710,(%esp)
f0100db3:	e8 55 2b 00 00       	call   f010390d <cprintf>
f0100db8:	eb 29                	jmp    f0100de3 <check_page_free_list+0x35a>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100dba:	a1 c4 e2 17 f0       	mov    0xf017e2c4,%eax
f0100dbf:	85 c0                	test   %eax,%eax
f0100dc1:	0f 85 f7 fc ff ff    	jne    f0100abe <check_page_free_list+0x35>
f0100dc7:	e9 d6 fc ff ff       	jmp    f0100aa2 <check_page_free_list+0x19>
f0100dcc:	83 3d c4 e2 17 f0 00 	cmpl   $0x0,0xf017e2c4
f0100dd3:	0f 84 c9 fc ff ff    	je     f0100aa2 <check_page_free_list+0x19>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100dd9:	be 00 04 00 00       	mov    $0x400,%esi
f0100dde:	e9 29 fd ff ff       	jmp    f0100b0c <check_page_free_list+0x83>
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
}
f0100de3:	83 c4 4c             	add    $0x4c,%esp
f0100de6:	5b                   	pop    %ebx
f0100de7:	5e                   	pop    %esi
f0100de8:	5f                   	pop    %edi
f0100de9:	5d                   	pop    %ebp
f0100dea:	c3                   	ret    

f0100deb <page_init>:
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100deb:	b8 01 00 00 00       	mov    $0x1,%eax
f0100df0:	eb 18                	jmp    f0100e0a <page_init+0x1f>
	{
	 pages[i].pp_ref = 1; //Used Pages
f0100df2:	8b 15 8c ef 17 f0    	mov    0xf017ef8c,%edx
f0100df8:	8d 14 c2             	lea    (%edx,%eax,8),%edx
f0100dfb:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
	 pages[i].pp_link = 0; // No links to any pages
f0100e01:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100e07:	83 c0 01             	add    $0x1,%eax
f0100e0a:	3b 05 84 ef 17 f0    	cmp    0xf017ef84,%eax
f0100e10:	72 e0                	jb     f0100df2 <page_init+0x7>
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100e12:	55                   	push   %ebp
f0100e13:	89 e5                	mov    %esp,%ebp
f0100e15:	57                   	push   %edi
f0100e16:	56                   	push   %esi
f0100e17:	53                   	push   %ebx
f0100e18:	83 ec 1c             	sub    $0x1c,%esp

	
	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	for (i = 1; i < npages_basemem; i++) {
f0100e1b:	8b 35 c8 e2 17 f0    	mov    0xf017e2c8,%esi
f0100e21:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100e26:	b8 01 00 00 00       	mov    $0x1,%eax
f0100e2b:	eb 39                	jmp    f0100e66 <page_init+0x7b>
f0100e2d:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100e34:	8b 0d 8c ef 17 f0    	mov    0xf017ef8c,%ecx
f0100e3a:	66 c7 44 11 04 00 00 	movw   $0x0,0x4(%ecx,%edx,1)
		pages[i].pp_link = 0;
f0100e41:	c7 04 c1 00 00 00 00 	movl   $0x0,(%ecx,%eax,8)

		if (!page_free_list){		
f0100e48:	85 db                	test   %ebx,%ebx
f0100e4a:	75 0a                	jne    f0100e56 <page_init+0x6b>
		page_free_list = &pages[i];	// if page_free_list is 0 then point to current page
f0100e4c:	89 d3                	mov    %edx,%ebx
f0100e4e:	03 1d 8c ef 17 f0    	add    0xf017ef8c,%ebx
f0100e54:	eb 0d                	jmp    f0100e63 <page_init+0x78>
		}
		else{
		pages[i-1].pp_link = &pages[i];
f0100e56:	8b 0d 8c ef 17 f0    	mov    0xf017ef8c,%ecx
f0100e5c:	8d 3c 11             	lea    (%ecx,%edx,1),%edi
f0100e5f:	89 7c 11 f8          	mov    %edi,-0x8(%ecx,%edx,1)

	
	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	for (i = 1; i < npages_basemem; i++) {
f0100e63:	83 c0 01             	add    $0x1,%eax
f0100e66:	39 f0                	cmp    %esi,%eax
f0100e68:	72 c3                	jb     f0100e2d <page_init+0x42>
f0100e6a:	89 1d c4 e2 17 f0    	mov    %ebx,0xf017e2c4
		}	//Previous page is linked to this current page
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
f0100e70:	8b 15 8c ef 17 f0    	mov    0xf017ef8c,%edx
f0100e76:	8d 44 c2 f8          	lea    -0x8(%edx,%eax,8),%eax
f0100e7a:	a3 b8 e2 17 f0       	mov    %eax,0xf017e2b8
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100e7f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e84:	e8 7b fb ff ff       	call   f0100a04 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100e89:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100e8e:	77 20                	ja     f0100eb0 <page_init+0xc5>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100e90:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e94:	c7 44 24 08 28 56 10 	movl   $0xf0105628,0x8(%esp)
f0100e9b:	f0 
f0100e9c:	c7 44 24 04 39 01 00 	movl   $0x139,0x4(%esp)
f0100ea3:	00 
f0100ea4:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0100eab:	e8 06 f2 ff ff       	call   f01000b6 <_panic>
f0100eb0:	05 ff 0f 00 10       	add    $0x10000fff,%eax
f0100eb5:	c1 e8 0c             	shr    $0xc,%eax
f0100eb8:	8b 1d b8 e2 17 f0    	mov    0xf017e2b8,%ebx
f0100ebe:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100ec5:	eb 2c                	jmp    f0100ef3 <page_init+0x108>
		pages[i].pp_ref = 0;
f0100ec7:	89 d1                	mov    %edx,%ecx
f0100ec9:	03 0d 8c ef 17 f0    	add    0xf017ef8c,%ecx
f0100ecf:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = 0;
f0100ed5:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		track->pp_link = &pages[i];
f0100edb:	89 d1                	mov    %edx,%ecx
f0100edd:	03 0d 8c ef 17 f0    	add    0xf017ef8c,%ecx
f0100ee3:	89 0b                	mov    %ecx,(%ebx)
		track = &pages[i];
f0100ee5:	89 d3                	mov    %edx,%ebx
f0100ee7:	03 1d 8c ef 17 f0    	add    0xf017ef8c,%ebx
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100eed:	83 c0 01             	add    $0x1,%eax
f0100ef0:	83 c2 08             	add    $0x8,%edx
f0100ef3:	3b 05 84 ef 17 f0    	cmp    0xf017ef84,%eax
f0100ef9:	72 cc                	jb     f0100ec7 <page_init+0xdc>
f0100efb:	89 1d b8 e2 17 f0    	mov    %ebx,0xf017e2b8
		pages[i].pp_link = 0;
		track->pp_link = &pages[i];
		track = &pages[i];
	}
	
	cprintf("Check first entry of pages &pages[0] = %x\n", &pages[0]);
f0100f01:	a1 8c ef 17 f0       	mov    0xf017ef8c,%eax
f0100f06:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f0a:	c7 04 24 38 57 10 f0 	movl   $0xf0105738,(%esp)
f0100f11:	e8 f7 29 00 00       	call   f010390d <cprintf>
	cprintf("&pages[npages-1] = %x\n", &pages[npages-1]);
f0100f16:	a1 8c ef 17 f0       	mov    0xf017ef8c,%eax
f0100f1b:	8b 15 84 ef 17 f0    	mov    0xf017ef84,%edx
f0100f21:	8d 44 d0 f8          	lea    -0x8(%eax,%edx,8),%eax
f0100f25:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f29:	c7 04 24 6b 5f 10 f0 	movl   $0xf0105f6b,(%esp)
f0100f30:	e8 d8 29 00 00       	call   f010390d <cprintf>
}
f0100f35:	83 c4 1c             	add    $0x1c,%esp
f0100f38:	5b                   	pop    %ebx
f0100f39:	5e                   	pop    %esi
f0100f3a:	5f                   	pop    %edi
f0100f3b:	5d                   	pop    %ebp
f0100f3c:	c3                   	ret    

f0100f3d <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100f3d:	55                   	push   %ebp
f0100f3e:	89 e5                	mov    %esp,%ebp
f0100f40:	53                   	push   %ebx
f0100f41:	83 ec 14             	sub    $0x14,%esp
	// Check if there is a free_page available 
	if (!page_free_list)
f0100f44:	8b 1d c4 e2 17 f0    	mov    0xf017e2c4,%ebx
f0100f4a:	85 db                	test   %ebx,%ebx
f0100f4c:	74 75                	je     f0100fc3 <page_alloc+0x86>
	return NULL;
	}
	
	struct PageInfo *allocPage = NULL;   //Create a temporary pointer 
	allocPage = page_free_list;	//Point to the current head of free_page_list
	page_free_list = allocPage ->pp_link; //Move the head to the next avaialble page
f0100f4e:	8b 03                	mov    (%ebx),%eax
f0100f50:	a3 c4 e2 17 f0       	mov    %eax,0xf017e2c4
	allocPage->pp_link = NULL;	//Break the link 
f0100f55:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags && ALLOC_ZERO){		//ALLOC_ZERO = 1<<0; which is nothing but  = 1
f0100f5b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100f5f:	74 58                	je     f0100fb9 <page_alloc+0x7c>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f61:	89 d8                	mov    %ebx,%eax
f0100f63:	2b 05 8c ef 17 f0    	sub    0xf017ef8c,%eax
f0100f69:	c1 f8 03             	sar    $0x3,%eax
f0100f6c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f6f:	89 c2                	mov    %eax,%edx
f0100f71:	c1 ea 0c             	shr    $0xc,%edx
f0100f74:	3b 15 84 ef 17 f0    	cmp    0xf017ef84,%edx
f0100f7a:	72 20                	jb     f0100f9c <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f7c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f80:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f0100f87:	f0 
f0100f88:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100f8f:	00 
f0100f90:	c7 04 24 b5 5e 10 f0 	movl   $0xf0105eb5,(%esp)
f0100f97:	e8 1a f1 ff ff       	call   f01000b6 <_panic>
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
f0100f9c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100fa3:	00 
f0100fa4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100fab:	00 
	return (void *)(pa + KERNBASE);
f0100fac:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100fb1:	89 04 24             	mov    %eax,(%esp)
f0100fb4:	e8 7e 3c 00 00       	call   f0104c37 <memset>
	}
	
	allocPage->pp_ref = 0;
f0100fb9:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return allocPage;
f0100fbf:	89 d8                	mov    %ebx,%eax
f0100fc1:	eb 05                	jmp    f0100fc8 <page_alloc+0x8b>
page_alloc(int alloc_flags)
{
	// Check if there is a free_page available 
	if (!page_free_list)
	{ 
	return NULL;
f0100fc3:	b8 00 00 00 00       	mov    $0x0,%eax
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
	}
	
	allocPage->pp_ref = 0;
	return allocPage;
}
f0100fc8:	83 c4 14             	add    $0x14,%esp
f0100fcb:	5b                   	pop    %ebx
f0100fcc:	5d                   	pop    %ebp
f0100fcd:	c3                   	ret    

f0100fce <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100fce:	55                   	push   %ebp
f0100fcf:	89 e5                	mov    %esp,%ebp
f0100fd1:	83 ec 18             	sub    $0x18,%esp
f0100fd4:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	
	if(pp->pp_ref)
f0100fd7:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100fdc:	74 1c                	je     f0100ffa <page_free+0x2c>
	{
	panic("Page cannot be returned to free list, as it is still refernced ");
f0100fde:	c7 44 24 08 64 57 10 	movl   $0xf0105764,0x8(%esp)
f0100fe5:	f0 
f0100fe6:	c7 44 24 04 71 01 00 	movl   $0x171,0x4(%esp)
f0100fed:	00 
f0100fee:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0100ff5:	e8 bc f0 ff ff       	call   f01000b6 <_panic>
	return;
	}
	
	// pp->pp_link is not NULL.
	else if(!pp) 
f0100ffa:	85 c0                	test   %eax,%eax
f0100ffc:	75 1c                	jne    f010101a <page_free+0x4c>
	{
	panic("Page cannot be returned to free list as it is Null");
f0100ffe:	c7 44 24 08 a4 57 10 	movl   $0xf01057a4,0x8(%esp)
f0101005:	f0 
f0101006:	c7 44 24 04 78 01 00 	movl   $0x178,0x4(%esp)
f010100d:	00 
f010100e:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101015:	e8 9c f0 ff ff       	call   f01000b6 <_panic>
	return;
	}
	
       else{
	pp->pp_link = page_free_list;
f010101a:	8b 15 c4 e2 17 f0    	mov    0xf017e2c4,%edx
f0101020:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0101022:	a3 c4 e2 17 f0       	mov    %eax,0xf017e2c4
	}


}
f0101027:	c9                   	leave  
f0101028:	c3                   	ret    

f0101029 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101029:	55                   	push   %ebp
f010102a:	89 e5                	mov    %esp,%ebp
f010102c:	83 ec 18             	sub    $0x18,%esp
f010102f:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0101032:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0101036:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0101039:	66 89 50 04          	mov    %dx,0x4(%eax)
f010103d:	66 85 d2             	test   %dx,%dx
f0101040:	75 08                	jne    f010104a <page_decref+0x21>
		page_free(pp);
f0101042:	89 04 24             	mov    %eax,(%esp)
f0101045:	e8 84 ff ff ff       	call   f0100fce <page_free>
}
f010104a:	c9                   	leave  
f010104b:	c3                   	ret    

f010104c <pgdir_walk>:
// table and page directory entries.
//

pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f010104c:	55                   	push   %ebp
f010104d:	89 e5                	mov    %esp,%ebp
f010104f:	57                   	push   %edi
f0101050:	56                   	push   %esi
f0101051:	53                   	push   %ebx
f0101052:	83 ec 1c             	sub    $0x1c,%esp
	pte_t *pgTab;  //Page Table index variable

	//To find the index from the pgdir we need to get the MS 10 bits,
	//We get the MS 10bits of the virtual address by using PDX function (found in inc/mmu.h ) 
	//#define PDX(la)		((((uintptr_t) (la)) >> PDXSHIFT) & 0x3FF)
	pgDir = &pgdir[PDX(va)];
f0101055:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101058:	c1 eb 16             	shr    $0x16,%ebx
f010105b:	c1 e3 02             	shl    $0x2,%ebx
f010105e:	03 5d 08             	add    0x8(%ebp),%ebx

	// Check if page is present, PTE_P = 0x1 means page present  
	if (*pgDir & PTE_P)  {
f0101061:	8b 3b                	mov    (%ebx),%edi
f0101063:	f7 c7 01 00 00 00    	test   $0x1,%edi
f0101069:	74 3e                	je     f01010a9 <pgdir_walk+0x5d>
		//page table entry to get to the final address translation. Now using the pgDir we can use the 
		//PTE_ADDR(pde) function to get the upper 20 bits, but this function returns a physical address. 
		//Since the kernel requires a virtual address, we can use the function KADDR to get the virtual 
		//address.
		
		pgTab = (pte_t*) KADDR(PTE_ADDR(*pgDir));
f010106b:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101071:	89 f8                	mov    %edi,%eax
f0101073:	c1 e8 0c             	shr    $0xc,%eax
f0101076:	3b 05 84 ef 17 f0    	cmp    0xf017ef84,%eax
f010107c:	72 20                	jb     f010109e <pgdir_walk+0x52>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010107e:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101082:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f0101089:	f0 
f010108a:	c7 44 24 04 b9 01 00 	movl   $0x1b9,0x4(%esp)
f0101091:	00 
f0101092:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101099:	e8 18 f0 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f010109e:	81 ef 00 00 00 10    	sub    $0x10000000,%edi
f01010a4:	e9 8f 00 00 00       	jmp    f0101138 <pgdir_walk+0xec>
	//If page is not present 
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
f01010a9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01010ad:	0f 84 94 00 00 00    	je     f0101147 <pgdir_walk+0xfb>
f01010b3:	c7 04 24 00 10 00 00 	movl   $0x1000,(%esp)
f01010ba:	e8 7e fe ff ff       	call   f0100f3d <page_alloc>
f01010bf:	89 c6                	mov    %eax,%esi
f01010c1:	85 c0                	test   %eax,%eax
f01010c3:	0f 84 85 00 00 00    	je     f010114e <pgdir_walk+0x102>
			return 0;
		}

		newPage->pp_ref++;  //Increment the ref pointer of the page 
f01010c9:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01010ce:	89 c7                	mov    %eax,%edi
f01010d0:	2b 3d 8c ef 17 f0    	sub    0xf017ef8c,%edi
f01010d6:	c1 ff 03             	sar    $0x3,%edi
f01010d9:	c1 e7 0c             	shl    $0xc,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010dc:	89 f8                	mov    %edi,%eax
f01010de:	c1 e8 0c             	shr    $0xc,%eax
f01010e1:	3b 05 84 ef 17 f0    	cmp    0xf017ef84,%eax
f01010e7:	72 20                	jb     f0101109 <pgdir_walk+0xbd>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010e9:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01010ed:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f01010f4:	f0 
f01010f5:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01010fc:	00 
f01010fd:	c7 04 24 b5 5e 10 f0 	movl   $0xf0105eb5,(%esp)
f0101104:	e8 ad ef ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0101109:	81 ef 00 00 00 10    	sub    $0x10000000,%edi
		//Now this section creates the bindings and updates all the flags 
		//for relevant use of the page.
		
		//First create a link on the pgTab wrt to the new page
		pgTab = (pte_t*)page2kva(newPage); // this function gets the virtual address of the new page
		memset (pgTab, 0, PGSIZE); //Clear the entire page
f010110f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101116:	00 
f0101117:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010111e:	00 
f010111f:	89 3c 24             	mov    %edi,(%esp)
f0101122:	e8 10 3b 00 00       	call   f0104c37 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101127:	2b 35 8c ef 17 f0    	sub    0xf017ef8c,%esi
f010112d:	c1 fe 03             	sar    $0x3,%esi
f0101130:	c1 e6 0c             	shl    $0xc,%esi

		//Page Table, pgTab contains the virtual address , now we need to set the permission bits.
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
f0101133:	83 ce 07             	or     $0x7,%esi
f0101136:	89 33                	mov    %esi,(%ebx)
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
f0101138:	8b 45 0c             	mov    0xc(%ebp),%eax
f010113b:	c1 e8 0a             	shr    $0xa,%eax
f010113e:	25 fc 0f 00 00       	and    $0xffc,%eax
f0101143:	01 f8                	add    %edi,%eax
f0101145:	eb 0c                	jmp    f0101153 <pgdir_walk+0x107>
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
			return 0;
f0101147:	b8 00 00 00 00       	mov    $0x0,%eax
f010114c:	eb 05                	jmp    f0101153 <pgdir_walk+0x107>
f010114e:	b8 00 00 00 00       	mov    $0x0,%eax
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
}
f0101153:	83 c4 1c             	add    $0x1c,%esp
f0101156:	5b                   	pop    %ebx
f0101157:	5e                   	pop    %esi
f0101158:	5f                   	pop    %edi
f0101159:	5d                   	pop    %ebp
f010115a:	c3                   	ret    

f010115b <boot_map_region>:
//
// Hint: the TA solution uses pgdir_walk

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f010115b:	55                   	push   %ebp
f010115c:	89 e5                	mov    %esp,%ebp
f010115e:	57                   	push   %edi
f010115f:	56                   	push   %esi
f0101160:	53                   	push   %ebx
f0101161:	83 ec 2c             	sub    $0x2c,%esp
f0101164:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f0101167:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
f010116d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101170:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	size = ROUNDUP(size, PGSIZE); 
f0101175:	8d b1 ff 0f 00 00    	lea    0xfff(%ecx),%esi
f010117b:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f0101181:	89 d3                	mov    %edx,%ebx
f0101183:	29 d0                	sub    %edx,%eax
f0101185:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		}
		if (*pgTbEnt & PTE_P){
			panic("Page is already mapped");
		}
		
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
f0101188:	8b 45 0c             	mov    0xc(%ebp),%eax
f010118b:	83 c8 01             	or     $0x1,%eax
f010118e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f0101191:	eb 69                	jmp    f01011fc <boot_map_region+0xa1>
		if (!(pgTbEnt = pgdir_walk(pgdir, (const void*)vaBegin, 1))){
f0101193:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010119a:	00 
f010119b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010119f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01011a2:	89 04 24             	mov    %eax,(%esp)
f01011a5:	e8 a2 fe ff ff       	call   f010104c <pgdir_walk>
f01011aa:	85 c0                	test   %eax,%eax
f01011ac:	75 1c                	jne    f01011ca <boot_map_region+0x6f>
			panic("Cannot find page for the page table entry, from boot_map_region function");
f01011ae:	c7 44 24 08 d8 57 10 	movl   $0xf01057d8,0x8(%esp)
f01011b5:	f0 
f01011b6:	c7 44 24 04 ef 01 00 	movl   $0x1ef,0x4(%esp)
f01011bd:	00 
f01011be:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f01011c5:	e8 ec ee ff ff       	call   f01000b6 <_panic>
		}
		if (*pgTbEnt & PTE_P){
f01011ca:	f6 00 01             	testb  $0x1,(%eax)
f01011cd:	74 1c                	je     f01011eb <boot_map_region+0x90>
			panic("Page is already mapped");
f01011cf:	c7 44 24 08 82 5f 10 	movl   $0xf0105f82,0x8(%esp)
f01011d6:	f0 
f01011d7:	c7 44 24 04 f2 01 00 	movl   $0x1f2,0x4(%esp)
f01011de:	00 
f01011df:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f01011e6:	e8 cb ee ff ff       	call   f01000b6 <_panic>
		}
		
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
f01011eb:	0b 7d dc             	or     -0x24(%ebp),%edi
f01011ee:	89 38                	mov    %edi,(%eax)
		vaBegin += PGSIZE;
f01011f0:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		paBegin += PGSIZE; 
		size -= PGSIZE;
f01011f6:	81 ee 00 10 00 00    	sub    $0x1000,%esi
f01011fc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01011ff:	8d 3c 18             	lea    (%eax,%ebx,1),%edi
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f0101202:	85 f6                	test   %esi,%esi
f0101204:	75 8d                	jne    f0101193 <boot_map_region+0x38>
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
		vaBegin += PGSIZE;
		paBegin += PGSIZE; 
		size -= PGSIZE;
	} 	
}
f0101206:	83 c4 2c             	add    $0x2c,%esp
f0101209:	5b                   	pop    %ebx
f010120a:	5e                   	pop    %esi
f010120b:	5f                   	pop    %edi
f010120c:	5d                   	pop    %ebp
f010120d:	c3                   	ret    

f010120e <page_lookup>:
// Hint: the TA solution uses pgdir_walk and pa2page.
//

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f010120e:	55                   	push   %ebp
f010120f:	89 e5                	mov    %esp,%ebp
f0101211:	53                   	push   %ebx
f0101212:	83 ec 14             	sub    $0x14,%esp
f0101215:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
	pgTbEty = pgdir_walk(pgdir, va, 0);
f0101218:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010121f:	00 
f0101220:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101223:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101227:	8b 45 08             	mov    0x8(%ebp),%eax
f010122a:	89 04 24             	mov    %eax,(%esp)
f010122d:	e8 1a fe ff ff       	call   f010104c <pgdir_walk>
f0101232:	89 c2                	mov    %eax,%edx
	if (pgTbEty && (*pgTbEty & PTE_P)) {
f0101234:	85 c0                	test   %eax,%eax
f0101236:	74 1a                	je     f0101252 <page_lookup+0x44>
f0101238:	8b 00                	mov    (%eax),%eax
f010123a:	a8 01                	test   $0x1,%al
f010123c:	74 1b                	je     f0101259 <page_lookup+0x4b>
		ret = pages + (PTE_ADDR(*pgTbEty) >> PTXSHIFT);
f010123e:	c1 e8 0c             	shr    $0xc,%eax
f0101241:	8b 0d 8c ef 17 f0    	mov    0xf017ef8c,%ecx
f0101247:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
		if (pte_store) {
f010124a:	85 db                	test   %ebx,%ebx
f010124c:	74 10                	je     f010125e <page_lookup+0x50>
			*pte_store = pgTbEty;
f010124e:	89 13                	mov    %edx,(%ebx)
f0101250:	eb 0c                	jmp    f010125e <page_lookup+0x50>

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
f0101252:	b8 00 00 00 00       	mov    $0x0,%eax
f0101257:	eb 05                	jmp    f010125e <page_lookup+0x50>
f0101259:	b8 00 00 00 00       	mov    $0x0,%eax
		if (pte_store) {
			*pte_store = pgTbEty;
		}
	}
	return ret;
}
f010125e:	83 c4 14             	add    $0x14,%esp
f0101261:	5b                   	pop    %ebx
f0101262:	5d                   	pop    %ebp
f0101263:	c3                   	ret    

f0101264 <page_remove>:
// 	tlb_invalidate, and page_decref.
//

void
page_remove(pde_t *pgdir, void *va)
{
f0101264:	55                   	push   %ebp
f0101265:	89 e5                	mov    %esp,%ebp
f0101267:	53                   	push   %ebx
f0101268:	83 ec 24             	sub    $0x24,%esp
f010126b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte;
	struct PageInfo *remPage = 0;
	if (!(remPage = page_lookup(pgdir, va, &pte))) {
f010126e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101271:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101275:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101279:	8b 45 08             	mov    0x8(%ebp),%eax
f010127c:	89 04 24             	mov    %eax,(%esp)
f010127f:	e8 8a ff ff ff       	call   f010120e <page_lookup>
f0101284:	85 c0                	test   %eax,%eax
f0101286:	74 14                	je     f010129c <page_remove+0x38>
		return;
	}
	page_decref(remPage);
f0101288:	89 04 24             	mov    %eax,(%esp)
f010128b:	e8 99 fd ff ff       	call   f0101029 <page_decref>
	*pte = 0;
f0101290:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101293:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101299:	0f 01 3b             	invlpg (%ebx)
	tlb_invalidate(pgdir, va);
}
f010129c:	83 c4 24             	add    $0x24,%esp
f010129f:	5b                   	pop    %ebx
f01012a0:	5d                   	pop    %ebp
f01012a1:	c3                   	ret    

f01012a2 <page_insert>:
// and page2pa.
//

int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01012a2:	55                   	push   %ebp
f01012a3:	89 e5                	mov    %esp,%ebp
f01012a5:	57                   	push   %edi
f01012a6:	56                   	push   %esi
f01012a7:	53                   	push   %ebx
f01012a8:	83 ec 1c             	sub    $0x1c,%esp
f01012ab:	8b 75 0c             	mov    0xc(%ebp),%esi
f01012ae:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
f01012b1:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01012b8:	00 
f01012b9:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01012bd:	8b 45 08             	mov    0x8(%ebp),%eax
f01012c0:	89 04 24             	mov    %eax,(%esp)
f01012c3:	e8 84 fd ff ff       	call   f010104c <pgdir_walk>
f01012c8:	89 c3                	mov    %eax,%ebx
	
	if (!pte){
f01012ca:	85 c0                	test   %eax,%eax
f01012cc:	0f 84 85 00 00 00    	je     f0101357 <page_insert+0xb5>
		return -E_NO_MEM; //Page table could not be allocated	
	}

	if (*pte & PTE_P){    //if page is already present
f01012d2:	8b 00                	mov    (%eax),%eax
f01012d4:	a8 01                	test   $0x1,%al
f01012d6:	74 5b                	je     f0101333 <page_insert+0x91>
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
f01012d8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01012dd:	89 f2                	mov    %esi,%edx
f01012df:	2b 15 8c ef 17 f0    	sub    0xf017ef8c,%edx
f01012e5:	c1 fa 03             	sar    $0x3,%edx
f01012e8:	c1 e2 0c             	shl    $0xc,%edx
f01012eb:	39 d0                	cmp    %edx,%eax
f01012ed:	75 11                	jne    f0101300 <page_insert+0x5e>
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
f01012ef:	8b 55 14             	mov    0x14(%ebp),%edx
f01012f2:	83 ca 01             	or     $0x1,%edx
f01012f5:	09 d0                	or     %edx,%eax
f01012f7:	89 03                	mov    %eax,(%ebx)
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
			pp->pp_ref ++;  //incremnt the page reference
		}
		return 0;
f01012f9:	b8 00 00 00 00       	mov    $0x0,%eax
f01012fe:	eb 5c                	jmp    f010135c <page_insert+0xba>
	if (*pte & PTE_P){    //if page is already present
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
		}
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
f0101300:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101304:	8b 45 08             	mov    0x8(%ebp),%eax
f0101307:	89 04 24             	mov    %eax,(%esp)
f010130a:	e8 55 ff ff ff       	call   f0101264 <page_remove>
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
f010130f:	8b 55 14             	mov    0x14(%ebp),%edx
f0101312:	83 ca 01             	or     $0x1,%edx
f0101315:	89 f0                	mov    %esi,%eax
f0101317:	2b 05 8c ef 17 f0    	sub    0xf017ef8c,%eax
f010131d:	c1 f8 03             	sar    $0x3,%eax
f0101320:	c1 e0 0c             	shl    $0xc,%eax
f0101323:	09 d0                	or     %edx,%eax
f0101325:	89 03                	mov    %eax,(%ebx)
			pp->pp_ref ++;  //incremnt the page reference
f0101327:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
		}
		return 0;
f010132c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101331:	eb 29                	jmp    f010135c <page_insert+0xba>
	}	
	else{   // if page is not present
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
f0101333:	8b 55 14             	mov    0x14(%ebp),%edx
f0101336:	83 ca 01             	or     $0x1,%edx
f0101339:	89 f0                	mov    %esi,%eax
f010133b:	2b 05 8c ef 17 f0    	sub    0xf017ef8c,%eax
f0101341:	c1 f8 03             	sar    $0x3,%eax
f0101344:	c1 e0 0c             	shl    $0xc,%eax
f0101347:	09 d0                	or     %edx,%eax
f0101349:	89 03                	mov    %eax,(%ebx)
		pp->pp_ref ++; // increment the page reference count	     
f010134b:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	}
	return 0;
f0101350:	b8 00 00 00 00       	mov    $0x0,%eax
f0101355:	eb 05                	jmp    f010135c <page_insert+0xba>
{
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
	
	if (!pte){
		return -E_NO_MEM; //Page table could not be allocated	
f0101357:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
		pp->pp_ref ++; // increment the page reference count	     
	}
	return 0;

}
f010135c:	83 c4 1c             	add    $0x1c,%esp
f010135f:	5b                   	pop    %ebx
f0101360:	5e                   	pop    %esi
f0101361:	5f                   	pop    %edi
f0101362:	5d                   	pop    %ebp
f0101363:	c3                   	ret    

f0101364 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101364:	55                   	push   %ebp
f0101365:	89 e5                	mov    %esp,%ebp
f0101367:	57                   	push   %edi
f0101368:	56                   	push   %esi
f0101369:	53                   	push   %ebx
f010136a:	83 ec 4c             	sub    $0x4c,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010136d:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f0101374:	e8 24 25 00 00       	call   f010389d <mc146818_read>
f0101379:	89 c3                	mov    %eax,%ebx
f010137b:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101382:	e8 16 25 00 00       	call   f010389d <mc146818_read>
f0101387:	c1 e0 08             	shl    $0x8,%eax
f010138a:	09 c3                	or     %eax,%ebx
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f010138c:	89 d8                	mov    %ebx,%eax
f010138e:	c1 e0 0a             	shl    $0xa,%eax
f0101391:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101397:	85 c0                	test   %eax,%eax
f0101399:	0f 48 c2             	cmovs  %edx,%eax
f010139c:	c1 f8 0c             	sar    $0xc,%eax
f010139f:	a3 c8 e2 17 f0       	mov    %eax,0xf017e2c8
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01013a4:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f01013ab:	e8 ed 24 00 00       	call   f010389d <mc146818_read>
f01013b0:	89 c3                	mov    %eax,%ebx
f01013b2:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01013b9:	e8 df 24 00 00       	call   f010389d <mc146818_read>
f01013be:	c1 e0 08             	shl    $0x8,%eax
f01013c1:	09 c3                	or     %eax,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01013c3:	89 d8                	mov    %ebx,%eax
f01013c5:	c1 e0 0a             	shl    $0xa,%eax
f01013c8:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01013ce:	85 c0                	test   %eax,%eax
f01013d0:	0f 48 c2             	cmovs  %edx,%eax
f01013d3:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01013d6:	85 c0                	test   %eax,%eax
f01013d8:	74 0e                	je     f01013e8 <mem_init+0x84>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01013da:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01013e0:	89 15 84 ef 17 f0    	mov    %edx,0xf017ef84
f01013e6:	eb 0c                	jmp    f01013f4 <mem_init+0x90>
	else
		npages = npages_basemem;
f01013e8:	8b 15 c8 e2 17 f0    	mov    0xf017e2c8,%edx
f01013ee:	89 15 84 ef 17 f0    	mov    %edx,0xf017ef84

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f01013f4:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01013f7:	c1 e8 0a             	shr    $0xa,%eax
f01013fa:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f01013fe:	a1 c8 e2 17 f0       	mov    0xf017e2c8,%eax
f0101403:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101406:	c1 e8 0a             	shr    $0xa,%eax
f0101409:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f010140d:	a1 84 ef 17 f0       	mov    0xf017ef84,%eax
f0101412:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101415:	c1 e8 0a             	shr    $0xa,%eax
f0101418:	89 44 24 04          	mov    %eax,0x4(%esp)
f010141c:	c7 04 24 24 58 10 f0 	movl   $0xf0105824,(%esp)
f0101423:	e8 e5 24 00 00       	call   f010390d <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101428:	b8 00 10 00 00       	mov    $0x1000,%eax
f010142d:	e8 d2 f5 ff ff       	call   f0100a04 <boot_alloc>
f0101432:	a3 88 ef 17 f0       	mov    %eax,0xf017ef88
	memset(kern_pgdir, 0, PGSIZE);
f0101437:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010143e:	00 
f010143f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101446:	00 
f0101447:	89 04 24             	mov    %eax,(%esp)
f010144a:	e8 e8 37 00 00       	call   f0104c37 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010144f:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101454:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101459:	77 20                	ja     f010147b <mem_init+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010145b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010145f:	c7 44 24 08 28 56 10 	movl   $0xf0105628,0x8(%esp)
f0101466:	f0 
f0101467:	c7 44 24 04 96 00 00 	movl   $0x96,0x4(%esp)
f010146e:	00 
f010146f:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101476:	e8 3b ec ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010147b:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101481:	83 ca 05             	or     $0x5,%edx
f0101484:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.

	//This line creates a boot allocation of memory of the size of number of pages
	// mulitplied by size of struct Pageinfo to store metadata of the page. 
	pages = boot_alloc(sizeof(struct PageInfo) * npages);   
f010148a:	a1 84 ef 17 f0       	mov    0xf017ef84,%eax
f010148f:	c1 e0 03             	shl    $0x3,%eax
f0101492:	e8 6d f5 ff ff       	call   f0100a04 <boot_alloc>
f0101497:	a3 8c ef 17 f0       	mov    %eax,0xf017ef8c
	memset(pages, 0, sizeof(struct PageInfo) * npages); //Clear the memory 
f010149c:	8b 3d 84 ef 17 f0    	mov    0xf017ef84,%edi
f01014a2:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f01014a9:	89 54 24 08          	mov    %edx,0x8(%esp)
f01014ad:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01014b4:	00 
f01014b5:	89 04 24             	mov    %eax,(%esp)
f01014b8:	e8 7a 37 00 00       	call   f0104c37 <memset>
	// The kernel uses this array to keep track of environment array:
	// 'NENV' is the number of Environments in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = boot_alloc(sizeof(struct Env)*NENV);
f01014bd:	b8 00 80 01 00       	mov    $0x18000,%eax
f01014c2:	e8 3d f5 ff ff       	call   f0100a04 <boot_alloc>
f01014c7:	a3 d0 e2 17 f0       	mov    %eax,0xf017e2d0
	memset(envs,0,sizeof(struct Env)*NENV);
f01014cc:	c7 44 24 08 00 80 01 	movl   $0x18000,0x8(%esp)
f01014d3:	00 
f01014d4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01014db:	00 
f01014dc:	89 04 24             	mov    %eax,(%esp)
f01014df:	e8 53 37 00 00       	call   f0104c37 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01014e4:	e8 02 f9 ff ff       	call   f0100deb <page_init>

	check_page_free_list(1);
f01014e9:	b8 01 00 00 00       	mov    $0x1,%eax
f01014ee:	e8 96 f5 ff ff       	call   f0100a89 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01014f3:	83 3d 8c ef 17 f0 00 	cmpl   $0x0,0xf017ef8c
f01014fa:	75 1c                	jne    f0101518 <mem_init+0x1b4>
		panic("'pages' is a null pointer!");
f01014fc:	c7 44 24 08 99 5f 10 	movl   $0xf0105f99,0x8(%esp)
f0101503:	f0 
f0101504:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f010150b:	00 
f010150c:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101513:	e8 9e eb ff ff       	call   f01000b6 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101518:	a1 c4 e2 17 f0       	mov    0xf017e2c4,%eax
f010151d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101522:	eb 05                	jmp    f0101529 <mem_init+0x1c5>
		++nfree;
f0101524:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101527:	8b 00                	mov    (%eax),%eax
f0101529:	85 c0                	test   %eax,%eax
f010152b:	75 f7                	jne    f0101524 <mem_init+0x1c0>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010152d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101534:	e8 04 fa ff ff       	call   f0100f3d <page_alloc>
f0101539:	89 c7                	mov    %eax,%edi
f010153b:	85 c0                	test   %eax,%eax
f010153d:	75 24                	jne    f0101563 <mem_init+0x1ff>
f010153f:	c7 44 24 0c b4 5f 10 	movl   $0xf0105fb4,0xc(%esp)
f0101546:	f0 
f0101547:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f010154e:	f0 
f010154f:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f0101556:	00 
f0101557:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f010155e:	e8 53 eb ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101563:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010156a:	e8 ce f9 ff ff       	call   f0100f3d <page_alloc>
f010156f:	89 c6                	mov    %eax,%esi
f0101571:	85 c0                	test   %eax,%eax
f0101573:	75 24                	jne    f0101599 <mem_init+0x235>
f0101575:	c7 44 24 0c ca 5f 10 	movl   $0xf0105fca,0xc(%esp)
f010157c:	f0 
f010157d:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101584:	f0 
f0101585:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
f010158c:	00 
f010158d:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101594:	e8 1d eb ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f0101599:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015a0:	e8 98 f9 ff ff       	call   f0100f3d <page_alloc>
f01015a5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015a8:	85 c0                	test   %eax,%eax
f01015aa:	75 24                	jne    f01015d0 <mem_init+0x26c>
f01015ac:	c7 44 24 0c e0 5f 10 	movl   $0xf0105fe0,0xc(%esp)
f01015b3:	f0 
f01015b4:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f01015bb:	f0 
f01015bc:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f01015c3:	00 
f01015c4:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f01015cb:	e8 e6 ea ff ff       	call   f01000b6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015d0:	39 f7                	cmp    %esi,%edi
f01015d2:	75 24                	jne    f01015f8 <mem_init+0x294>
f01015d4:	c7 44 24 0c f6 5f 10 	movl   $0xf0105ff6,0xc(%esp)
f01015db:	f0 
f01015dc:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f01015e3:	f0 
f01015e4:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f01015eb:	00 
f01015ec:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f01015f3:	e8 be ea ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015f8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015fb:	39 c6                	cmp    %eax,%esi
f01015fd:	74 04                	je     f0101603 <mem_init+0x29f>
f01015ff:	39 c7                	cmp    %eax,%edi
f0101601:	75 24                	jne    f0101627 <mem_init+0x2c3>
f0101603:	c7 44 24 0c 60 58 10 	movl   $0xf0105860,0xc(%esp)
f010160a:	f0 
f010160b:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101612:	f0 
f0101613:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f010161a:	00 
f010161b:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101622:	e8 8f ea ff ff       	call   f01000b6 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101627:	8b 15 8c ef 17 f0    	mov    0xf017ef8c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f010162d:	a1 84 ef 17 f0       	mov    0xf017ef84,%eax
f0101632:	c1 e0 0c             	shl    $0xc,%eax
f0101635:	89 f9                	mov    %edi,%ecx
f0101637:	29 d1                	sub    %edx,%ecx
f0101639:	c1 f9 03             	sar    $0x3,%ecx
f010163c:	c1 e1 0c             	shl    $0xc,%ecx
f010163f:	39 c1                	cmp    %eax,%ecx
f0101641:	72 24                	jb     f0101667 <mem_init+0x303>
f0101643:	c7 44 24 0c 08 60 10 	movl   $0xf0106008,0xc(%esp)
f010164a:	f0 
f010164b:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101652:	f0 
f0101653:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f010165a:	00 
f010165b:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101662:	e8 4f ea ff ff       	call   f01000b6 <_panic>
f0101667:	89 f1                	mov    %esi,%ecx
f0101669:	29 d1                	sub    %edx,%ecx
f010166b:	c1 f9 03             	sar    $0x3,%ecx
f010166e:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101671:	39 c8                	cmp    %ecx,%eax
f0101673:	77 24                	ja     f0101699 <mem_init+0x335>
f0101675:	c7 44 24 0c 25 60 10 	movl   $0xf0106025,0xc(%esp)
f010167c:	f0 
f010167d:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101684:	f0 
f0101685:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f010168c:	00 
f010168d:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101694:	e8 1d ea ff ff       	call   f01000b6 <_panic>
f0101699:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010169c:	29 d1                	sub    %edx,%ecx
f010169e:	89 ca                	mov    %ecx,%edx
f01016a0:	c1 fa 03             	sar    $0x3,%edx
f01016a3:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f01016a6:	39 d0                	cmp    %edx,%eax
f01016a8:	77 24                	ja     f01016ce <mem_init+0x36a>
f01016aa:	c7 44 24 0c 42 60 10 	movl   $0xf0106042,0xc(%esp)
f01016b1:	f0 
f01016b2:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f01016b9:	f0 
f01016ba:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f01016c1:	00 
f01016c2:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f01016c9:	e8 e8 e9 ff ff       	call   f01000b6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01016ce:	a1 c4 e2 17 f0       	mov    0xf017e2c4,%eax
f01016d3:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01016d6:	c7 05 c4 e2 17 f0 00 	movl   $0x0,0xf017e2c4
f01016dd:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01016e0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016e7:	e8 51 f8 ff ff       	call   f0100f3d <page_alloc>
f01016ec:	85 c0                	test   %eax,%eax
f01016ee:	74 24                	je     f0101714 <mem_init+0x3b0>
f01016f0:	c7 44 24 0c 5f 60 10 	movl   $0xf010605f,0xc(%esp)
f01016f7:	f0 
f01016f8:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f01016ff:	f0 
f0101700:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
f0101707:	00 
f0101708:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f010170f:	e8 a2 e9 ff ff       	call   f01000b6 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101714:	89 3c 24             	mov    %edi,(%esp)
f0101717:	e8 b2 f8 ff ff       	call   f0100fce <page_free>
	page_free(pp1);
f010171c:	89 34 24             	mov    %esi,(%esp)
f010171f:	e8 aa f8 ff ff       	call   f0100fce <page_free>
	page_free(pp2);
f0101724:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101727:	89 04 24             	mov    %eax,(%esp)
f010172a:	e8 9f f8 ff ff       	call   f0100fce <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010172f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101736:	e8 02 f8 ff ff       	call   f0100f3d <page_alloc>
f010173b:	89 c6                	mov    %eax,%esi
f010173d:	85 c0                	test   %eax,%eax
f010173f:	75 24                	jne    f0101765 <mem_init+0x401>
f0101741:	c7 44 24 0c b4 5f 10 	movl   $0xf0105fb4,0xc(%esp)
f0101748:	f0 
f0101749:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101750:	f0 
f0101751:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f0101758:	00 
f0101759:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101760:	e8 51 e9 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101765:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010176c:	e8 cc f7 ff ff       	call   f0100f3d <page_alloc>
f0101771:	89 c7                	mov    %eax,%edi
f0101773:	85 c0                	test   %eax,%eax
f0101775:	75 24                	jne    f010179b <mem_init+0x437>
f0101777:	c7 44 24 0c ca 5f 10 	movl   $0xf0105fca,0xc(%esp)
f010177e:	f0 
f010177f:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101786:	f0 
f0101787:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f010178e:	00 
f010178f:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101796:	e8 1b e9 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f010179b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017a2:	e8 96 f7 ff ff       	call   f0100f3d <page_alloc>
f01017a7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01017aa:	85 c0                	test   %eax,%eax
f01017ac:	75 24                	jne    f01017d2 <mem_init+0x46e>
f01017ae:	c7 44 24 0c e0 5f 10 	movl   $0xf0105fe0,0xc(%esp)
f01017b5:	f0 
f01017b6:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f01017bd:	f0 
f01017be:	c7 44 24 04 35 03 00 	movl   $0x335,0x4(%esp)
f01017c5:	00 
f01017c6:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f01017cd:	e8 e4 e8 ff ff       	call   f01000b6 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01017d2:	39 fe                	cmp    %edi,%esi
f01017d4:	75 24                	jne    f01017fa <mem_init+0x496>
f01017d6:	c7 44 24 0c f6 5f 10 	movl   $0xf0105ff6,0xc(%esp)
f01017dd:	f0 
f01017de:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f01017e5:	f0 
f01017e6:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f01017ed:	00 
f01017ee:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f01017f5:	e8 bc e8 ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017fa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017fd:	39 c7                	cmp    %eax,%edi
f01017ff:	74 04                	je     f0101805 <mem_init+0x4a1>
f0101801:	39 c6                	cmp    %eax,%esi
f0101803:	75 24                	jne    f0101829 <mem_init+0x4c5>
f0101805:	c7 44 24 0c 60 58 10 	movl   $0xf0105860,0xc(%esp)
f010180c:	f0 
f010180d:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101814:	f0 
f0101815:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f010181c:	00 
f010181d:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101824:	e8 8d e8 ff ff       	call   f01000b6 <_panic>
	assert(!page_alloc(0));
f0101829:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101830:	e8 08 f7 ff ff       	call   f0100f3d <page_alloc>
f0101835:	85 c0                	test   %eax,%eax
f0101837:	74 24                	je     f010185d <mem_init+0x4f9>
f0101839:	c7 44 24 0c 5f 60 10 	movl   $0xf010605f,0xc(%esp)
f0101840:	f0 
f0101841:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101848:	f0 
f0101849:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f0101850:	00 
f0101851:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101858:	e8 59 e8 ff ff       	call   f01000b6 <_panic>
f010185d:	89 f0                	mov    %esi,%eax
f010185f:	2b 05 8c ef 17 f0    	sub    0xf017ef8c,%eax
f0101865:	c1 f8 03             	sar    $0x3,%eax
f0101868:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010186b:	89 c2                	mov    %eax,%edx
f010186d:	c1 ea 0c             	shr    $0xc,%edx
f0101870:	3b 15 84 ef 17 f0    	cmp    0xf017ef84,%edx
f0101876:	72 20                	jb     f0101898 <mem_init+0x534>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101878:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010187c:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f0101883:	f0 
f0101884:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010188b:	00 
f010188c:	c7 04 24 b5 5e 10 f0 	movl   $0xf0105eb5,(%esp)
f0101893:	e8 1e e8 ff ff       	call   f01000b6 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101898:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010189f:	00 
f01018a0:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01018a7:	00 
	return (void *)(pa + KERNBASE);
f01018a8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01018ad:	89 04 24             	mov    %eax,(%esp)
f01018b0:	e8 82 33 00 00       	call   f0104c37 <memset>
	page_free(pp0);
f01018b5:	89 34 24             	mov    %esi,(%esp)
f01018b8:	e8 11 f7 ff ff       	call   f0100fce <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01018bd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01018c4:	e8 74 f6 ff ff       	call   f0100f3d <page_alloc>
f01018c9:	85 c0                	test   %eax,%eax
f01018cb:	75 24                	jne    f01018f1 <mem_init+0x58d>
f01018cd:	c7 44 24 0c 6e 60 10 	movl   $0xf010606e,0xc(%esp)
f01018d4:	f0 
f01018d5:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f01018dc:	f0 
f01018dd:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f01018e4:	00 
f01018e5:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f01018ec:	e8 c5 e7 ff ff       	call   f01000b6 <_panic>
	assert(pp && pp0 == pp);
f01018f1:	39 c6                	cmp    %eax,%esi
f01018f3:	74 24                	je     f0101919 <mem_init+0x5b5>
f01018f5:	c7 44 24 0c 8c 60 10 	movl   $0xf010608c,0xc(%esp)
f01018fc:	f0 
f01018fd:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101904:	f0 
f0101905:	c7 44 24 04 3f 03 00 	movl   $0x33f,0x4(%esp)
f010190c:	00 
f010190d:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101914:	e8 9d e7 ff ff       	call   f01000b6 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101919:	89 f0                	mov    %esi,%eax
f010191b:	2b 05 8c ef 17 f0    	sub    0xf017ef8c,%eax
f0101921:	c1 f8 03             	sar    $0x3,%eax
f0101924:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101927:	89 c2                	mov    %eax,%edx
f0101929:	c1 ea 0c             	shr    $0xc,%edx
f010192c:	3b 15 84 ef 17 f0    	cmp    0xf017ef84,%edx
f0101932:	72 20                	jb     f0101954 <mem_init+0x5f0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101934:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101938:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f010193f:	f0 
f0101940:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101947:	00 
f0101948:	c7 04 24 b5 5e 10 f0 	movl   $0xf0105eb5,(%esp)
f010194f:	e8 62 e7 ff ff       	call   f01000b6 <_panic>
f0101954:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010195a:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101960:	80 38 00             	cmpb   $0x0,(%eax)
f0101963:	74 24                	je     f0101989 <mem_init+0x625>
f0101965:	c7 44 24 0c 9c 60 10 	movl   $0xf010609c,0xc(%esp)
f010196c:	f0 
f010196d:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101974:	f0 
f0101975:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f010197c:	00 
f010197d:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101984:	e8 2d e7 ff ff       	call   f01000b6 <_panic>
f0101989:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010198c:	39 d0                	cmp    %edx,%eax
f010198e:	75 d0                	jne    f0101960 <mem_init+0x5fc>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101990:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101993:	a3 c4 e2 17 f0       	mov    %eax,0xf017e2c4

	// free the pages we took
	page_free(pp0);
f0101998:	89 34 24             	mov    %esi,(%esp)
f010199b:	e8 2e f6 ff ff       	call   f0100fce <page_free>
	page_free(pp1);
f01019a0:	89 3c 24             	mov    %edi,(%esp)
f01019a3:	e8 26 f6 ff ff       	call   f0100fce <page_free>
	page_free(pp2);
f01019a8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019ab:	89 04 24             	mov    %eax,(%esp)
f01019ae:	e8 1b f6 ff ff       	call   f0100fce <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01019b3:	a1 c4 e2 17 f0       	mov    0xf017e2c4,%eax
f01019b8:	eb 05                	jmp    f01019bf <mem_init+0x65b>
		--nfree;
f01019ba:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01019bd:	8b 00                	mov    (%eax),%eax
f01019bf:	85 c0                	test   %eax,%eax
f01019c1:	75 f7                	jne    f01019ba <mem_init+0x656>
		--nfree;
	assert(nfree == 0);
f01019c3:	85 db                	test   %ebx,%ebx
f01019c5:	74 24                	je     f01019eb <mem_init+0x687>
f01019c7:	c7 44 24 0c a6 60 10 	movl   $0xf01060a6,0xc(%esp)
f01019ce:	f0 
f01019cf:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f01019d6:	f0 
f01019d7:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f01019de:	00 
f01019df:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f01019e6:	e8 cb e6 ff ff       	call   f01000b6 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01019eb:	c7 04 24 80 58 10 f0 	movl   $0xf0105880,(%esp)
f01019f2:	e8 16 1f 00 00       	call   f010390d <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01019f7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019fe:	e8 3a f5 ff ff       	call   f0100f3d <page_alloc>
f0101a03:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101a06:	85 c0                	test   %eax,%eax
f0101a08:	75 24                	jne    f0101a2e <mem_init+0x6ca>
f0101a0a:	c7 44 24 0c b4 5f 10 	movl   $0xf0105fb4,0xc(%esp)
f0101a11:	f0 
f0101a12:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101a19:	f0 
f0101a1a:	c7 44 24 04 ad 03 00 	movl   $0x3ad,0x4(%esp)
f0101a21:	00 
f0101a22:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101a29:	e8 88 e6 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101a2e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a35:	e8 03 f5 ff ff       	call   f0100f3d <page_alloc>
f0101a3a:	89 c3                	mov    %eax,%ebx
f0101a3c:	85 c0                	test   %eax,%eax
f0101a3e:	75 24                	jne    f0101a64 <mem_init+0x700>
f0101a40:	c7 44 24 0c ca 5f 10 	movl   $0xf0105fca,0xc(%esp)
f0101a47:	f0 
f0101a48:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101a4f:	f0 
f0101a50:	c7 44 24 04 ae 03 00 	movl   $0x3ae,0x4(%esp)
f0101a57:	00 
f0101a58:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101a5f:	e8 52 e6 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f0101a64:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a6b:	e8 cd f4 ff ff       	call   f0100f3d <page_alloc>
f0101a70:	89 c6                	mov    %eax,%esi
f0101a72:	85 c0                	test   %eax,%eax
f0101a74:	75 24                	jne    f0101a9a <mem_init+0x736>
f0101a76:	c7 44 24 0c e0 5f 10 	movl   $0xf0105fe0,0xc(%esp)
f0101a7d:	f0 
f0101a7e:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101a85:	f0 
f0101a86:	c7 44 24 04 af 03 00 	movl   $0x3af,0x4(%esp)
f0101a8d:	00 
f0101a8e:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101a95:	e8 1c e6 ff ff       	call   f01000b6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a9a:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101a9d:	75 24                	jne    f0101ac3 <mem_init+0x75f>
f0101a9f:	c7 44 24 0c f6 5f 10 	movl   $0xf0105ff6,0xc(%esp)
f0101aa6:	f0 
f0101aa7:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101aae:	f0 
f0101aaf:	c7 44 24 04 b2 03 00 	movl   $0x3b2,0x4(%esp)
f0101ab6:	00 
f0101ab7:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101abe:	e8 f3 e5 ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101ac3:	39 c3                	cmp    %eax,%ebx
f0101ac5:	74 05                	je     f0101acc <mem_init+0x768>
f0101ac7:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101aca:	75 24                	jne    f0101af0 <mem_init+0x78c>
f0101acc:	c7 44 24 0c 60 58 10 	movl   $0xf0105860,0xc(%esp)
f0101ad3:	f0 
f0101ad4:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101adb:	f0 
f0101adc:	c7 44 24 04 b3 03 00 	movl   $0x3b3,0x4(%esp)
f0101ae3:	00 
f0101ae4:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101aeb:	e8 c6 e5 ff ff       	call   f01000b6 <_panic>
	

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101af0:	a1 c4 e2 17 f0       	mov    0xf017e2c4,%eax
f0101af5:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101af8:	c7 05 c4 e2 17 f0 00 	movl   $0x0,0xf017e2c4
f0101aff:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101b02:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b09:	e8 2f f4 ff ff       	call   f0100f3d <page_alloc>
f0101b0e:	85 c0                	test   %eax,%eax
f0101b10:	74 24                	je     f0101b36 <mem_init+0x7d2>
f0101b12:	c7 44 24 0c 5f 60 10 	movl   $0xf010605f,0xc(%esp)
f0101b19:	f0 
f0101b1a:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101b21:	f0 
f0101b22:	c7 44 24 04 bb 03 00 	movl   $0x3bb,0x4(%esp)
f0101b29:	00 
f0101b2a:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101b31:	e8 80 e5 ff ff       	call   f01000b6 <_panic>
	
	
	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101b36:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101b39:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101b3d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101b44:	00 
f0101b45:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f0101b4a:	89 04 24             	mov    %eax,(%esp)
f0101b4d:	e8 bc f6 ff ff       	call   f010120e <page_lookup>
f0101b52:	85 c0                	test   %eax,%eax
f0101b54:	74 24                	je     f0101b7a <mem_init+0x816>
f0101b56:	c7 44 24 0c a0 58 10 	movl   $0xf01058a0,0xc(%esp)
f0101b5d:	f0 
f0101b5e:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101b65:	f0 
f0101b66:	c7 44 24 04 bf 03 00 	movl   $0x3bf,0x4(%esp)
f0101b6d:	00 
f0101b6e:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101b75:	e8 3c e5 ff ff       	call   f01000b6 <_panic>
	
	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101b7a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b81:	00 
f0101b82:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101b89:	00 
f0101b8a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101b8e:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f0101b93:	89 04 24             	mov    %eax,(%esp)
f0101b96:	e8 07 f7 ff ff       	call   f01012a2 <page_insert>
f0101b9b:	85 c0                	test   %eax,%eax
f0101b9d:	78 24                	js     f0101bc3 <mem_init+0x85f>
f0101b9f:	c7 44 24 0c d8 58 10 	movl   $0xf01058d8,0xc(%esp)
f0101ba6:	f0 
f0101ba7:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101bae:	f0 
f0101baf:	c7 44 24 04 c2 03 00 	movl   $0x3c2,0x4(%esp)
f0101bb6:	00 
f0101bb7:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101bbe:	e8 f3 e4 ff ff       	call   f01000b6 <_panic>
	
	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101bc3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101bc6:	89 04 24             	mov    %eax,(%esp)
f0101bc9:	e8 00 f4 ff ff       	call   f0100fce <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101bce:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101bd5:	00 
f0101bd6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101bdd:	00 
f0101bde:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101be2:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f0101be7:	89 04 24             	mov    %eax,(%esp)
f0101bea:	e8 b3 f6 ff ff       	call   f01012a2 <page_insert>
f0101bef:	85 c0                	test   %eax,%eax
f0101bf1:	74 24                	je     f0101c17 <mem_init+0x8b3>
f0101bf3:	c7 44 24 0c 08 59 10 	movl   $0xf0105908,0xc(%esp)
f0101bfa:	f0 
f0101bfb:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101c02:	f0 
f0101c03:	c7 44 24 04 c6 03 00 	movl   $0x3c6,0x4(%esp)
f0101c0a:	00 
f0101c0b:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101c12:	e8 9f e4 ff ff       	call   f01000b6 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101c17:	8b 3d 88 ef 17 f0    	mov    0xf017ef88,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101c1d:	a1 8c ef 17 f0       	mov    0xf017ef8c,%eax
f0101c22:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c25:	8b 17                	mov    (%edi),%edx
f0101c27:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101c2d:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101c30:	29 c1                	sub    %eax,%ecx
f0101c32:	89 c8                	mov    %ecx,%eax
f0101c34:	c1 f8 03             	sar    $0x3,%eax
f0101c37:	c1 e0 0c             	shl    $0xc,%eax
f0101c3a:	39 c2                	cmp    %eax,%edx
f0101c3c:	74 24                	je     f0101c62 <mem_init+0x8fe>
f0101c3e:	c7 44 24 0c 38 59 10 	movl   $0xf0105938,0xc(%esp)
f0101c45:	f0 
f0101c46:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101c4d:	f0 
f0101c4e:	c7 44 24 04 c7 03 00 	movl   $0x3c7,0x4(%esp)
f0101c55:	00 
f0101c56:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101c5d:	e8 54 e4 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101c62:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c67:	89 f8                	mov    %edi,%eax
f0101c69:	e8 27 ed ff ff       	call   f0100995 <check_va2pa>
f0101c6e:	89 da                	mov    %ebx,%edx
f0101c70:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101c73:	c1 fa 03             	sar    $0x3,%edx
f0101c76:	c1 e2 0c             	shl    $0xc,%edx
f0101c79:	39 d0                	cmp    %edx,%eax
f0101c7b:	74 24                	je     f0101ca1 <mem_init+0x93d>
f0101c7d:	c7 44 24 0c 60 59 10 	movl   $0xf0105960,0xc(%esp)
f0101c84:	f0 
f0101c85:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101c8c:	f0 
f0101c8d:	c7 44 24 04 c8 03 00 	movl   $0x3c8,0x4(%esp)
f0101c94:	00 
f0101c95:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101c9c:	e8 15 e4 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 1);
f0101ca1:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ca6:	74 24                	je     f0101ccc <mem_init+0x968>
f0101ca8:	c7 44 24 0c b1 60 10 	movl   $0xf01060b1,0xc(%esp)
f0101caf:	f0 
f0101cb0:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101cb7:	f0 
f0101cb8:	c7 44 24 04 c9 03 00 	movl   $0x3c9,0x4(%esp)
f0101cbf:	00 
f0101cc0:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101cc7:	e8 ea e3 ff ff       	call   f01000b6 <_panic>
	assert(pp0->pp_ref == 1);
f0101ccc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ccf:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101cd4:	74 24                	je     f0101cfa <mem_init+0x996>
f0101cd6:	c7 44 24 0c c2 60 10 	movl   $0xf01060c2,0xc(%esp)
f0101cdd:	f0 
f0101cde:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101ce5:	f0 
f0101ce6:	c7 44 24 04 ca 03 00 	movl   $0x3ca,0x4(%esp)
f0101ced:	00 
f0101cee:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101cf5:	e8 bc e3 ff ff       	call   f01000b6 <_panic>
	
	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101cfa:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101d01:	00 
f0101d02:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101d09:	00 
f0101d0a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101d0e:	89 3c 24             	mov    %edi,(%esp)
f0101d11:	e8 8c f5 ff ff       	call   f01012a2 <page_insert>
f0101d16:	85 c0                	test   %eax,%eax
f0101d18:	74 24                	je     f0101d3e <mem_init+0x9da>
f0101d1a:	c7 44 24 0c 90 59 10 	movl   $0xf0105990,0xc(%esp)
f0101d21:	f0 
f0101d22:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101d29:	f0 
f0101d2a:	c7 44 24 04 cd 03 00 	movl   $0x3cd,0x4(%esp)
f0101d31:	00 
f0101d32:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101d39:	e8 78 e3 ff ff       	call   f01000b6 <_panic>

	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d3e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d43:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f0101d48:	e8 48 ec ff ff       	call   f0100995 <check_va2pa>
f0101d4d:	89 f2                	mov    %esi,%edx
f0101d4f:	2b 15 8c ef 17 f0    	sub    0xf017ef8c,%edx
f0101d55:	c1 fa 03             	sar    $0x3,%edx
f0101d58:	c1 e2 0c             	shl    $0xc,%edx
f0101d5b:	39 d0                	cmp    %edx,%eax
f0101d5d:	74 24                	je     f0101d83 <mem_init+0xa1f>
f0101d5f:	c7 44 24 0c cc 59 10 	movl   $0xf01059cc,0xc(%esp)
f0101d66:	f0 
f0101d67:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101d6e:	f0 
f0101d6f:	c7 44 24 04 cf 03 00 	movl   $0x3cf,0x4(%esp)
f0101d76:	00 
f0101d77:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101d7e:	e8 33 e3 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0101d83:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d88:	74 24                	je     f0101dae <mem_init+0xa4a>
f0101d8a:	c7 44 24 0c d3 60 10 	movl   $0xf01060d3,0xc(%esp)
f0101d91:	f0 
f0101d92:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101d99:	f0 
f0101d9a:	c7 44 24 04 d0 03 00 	movl   $0x3d0,0x4(%esp)
f0101da1:	00 
f0101da2:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101da9:	e8 08 e3 ff ff       	call   f01000b6 <_panic>
	
	// should be no free memory
	assert(!page_alloc(0));
f0101dae:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101db5:	e8 83 f1 ff ff       	call   f0100f3d <page_alloc>
f0101dba:	85 c0                	test   %eax,%eax
f0101dbc:	74 24                	je     f0101de2 <mem_init+0xa7e>
f0101dbe:	c7 44 24 0c 5f 60 10 	movl   $0xf010605f,0xc(%esp)
f0101dc5:	f0 
f0101dc6:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101dcd:	f0 
f0101dce:	c7 44 24 04 d3 03 00 	movl   $0x3d3,0x4(%esp)
f0101dd5:	00 
f0101dd6:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101ddd:	e8 d4 e2 ff ff       	call   f01000b6 <_panic>
	
	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101de2:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101de9:	00 
f0101dea:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101df1:	00 
f0101df2:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101df6:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f0101dfb:	89 04 24             	mov    %eax,(%esp)
f0101dfe:	e8 9f f4 ff ff       	call   f01012a2 <page_insert>
f0101e03:	85 c0                	test   %eax,%eax
f0101e05:	74 24                	je     f0101e2b <mem_init+0xac7>
f0101e07:	c7 44 24 0c 90 59 10 	movl   $0xf0105990,0xc(%esp)
f0101e0e:	f0 
f0101e0f:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101e16:	f0 
f0101e17:	c7 44 24 04 d6 03 00 	movl   $0x3d6,0x4(%esp)
f0101e1e:	00 
f0101e1f:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101e26:	e8 8b e2 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e2b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e30:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f0101e35:	e8 5b eb ff ff       	call   f0100995 <check_va2pa>
f0101e3a:	89 f2                	mov    %esi,%edx
f0101e3c:	2b 15 8c ef 17 f0    	sub    0xf017ef8c,%edx
f0101e42:	c1 fa 03             	sar    $0x3,%edx
f0101e45:	c1 e2 0c             	shl    $0xc,%edx
f0101e48:	39 d0                	cmp    %edx,%eax
f0101e4a:	74 24                	je     f0101e70 <mem_init+0xb0c>
f0101e4c:	c7 44 24 0c cc 59 10 	movl   $0xf01059cc,0xc(%esp)
f0101e53:	f0 
f0101e54:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101e5b:	f0 
f0101e5c:	c7 44 24 04 d7 03 00 	movl   $0x3d7,0x4(%esp)
f0101e63:	00 
f0101e64:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101e6b:	e8 46 e2 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0101e70:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e75:	74 24                	je     f0101e9b <mem_init+0xb37>
f0101e77:	c7 44 24 0c d3 60 10 	movl   $0xf01060d3,0xc(%esp)
f0101e7e:	f0 
f0101e7f:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101e86:	f0 
f0101e87:	c7 44 24 04 d8 03 00 	movl   $0x3d8,0x4(%esp)
f0101e8e:	00 
f0101e8f:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101e96:	e8 1b e2 ff ff       	call   f01000b6 <_panic>
	
	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101e9b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ea2:	e8 96 f0 ff ff       	call   f0100f3d <page_alloc>
f0101ea7:	85 c0                	test   %eax,%eax
f0101ea9:	74 24                	je     f0101ecf <mem_init+0xb6b>
f0101eab:	c7 44 24 0c 5f 60 10 	movl   $0xf010605f,0xc(%esp)
f0101eb2:	f0 
f0101eb3:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101eba:	f0 
f0101ebb:	c7 44 24 04 dc 03 00 	movl   $0x3dc,0x4(%esp)
f0101ec2:	00 
f0101ec3:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101eca:	e8 e7 e1 ff ff       	call   f01000b6 <_panic>
	
	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101ecf:	8b 15 88 ef 17 f0    	mov    0xf017ef88,%edx
f0101ed5:	8b 02                	mov    (%edx),%eax
f0101ed7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101edc:	89 c1                	mov    %eax,%ecx
f0101ede:	c1 e9 0c             	shr    $0xc,%ecx
f0101ee1:	3b 0d 84 ef 17 f0    	cmp    0xf017ef84,%ecx
f0101ee7:	72 20                	jb     f0101f09 <mem_init+0xba5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ee9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101eed:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f0101ef4:	f0 
f0101ef5:	c7 44 24 04 df 03 00 	movl   $0x3df,0x4(%esp)
f0101efc:	00 
f0101efd:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101f04:	e8 ad e1 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0101f09:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101f0e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101f11:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f18:	00 
f0101f19:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f20:	00 
f0101f21:	89 14 24             	mov    %edx,(%esp)
f0101f24:	e8 23 f1 ff ff       	call   f010104c <pgdir_walk>
f0101f29:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101f2c:	8d 51 04             	lea    0x4(%ecx),%edx
f0101f2f:	39 d0                	cmp    %edx,%eax
f0101f31:	74 24                	je     f0101f57 <mem_init+0xbf3>
f0101f33:	c7 44 24 0c fc 59 10 	movl   $0xf01059fc,0xc(%esp)
f0101f3a:	f0 
f0101f3b:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101f42:	f0 
f0101f43:	c7 44 24 04 e0 03 00 	movl   $0x3e0,0x4(%esp)
f0101f4a:	00 
f0101f4b:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101f52:	e8 5f e1 ff ff       	call   f01000b6 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101f57:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101f5e:	00 
f0101f5f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f66:	00 
f0101f67:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101f6b:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f0101f70:	89 04 24             	mov    %eax,(%esp)
f0101f73:	e8 2a f3 ff ff       	call   f01012a2 <page_insert>
f0101f78:	85 c0                	test   %eax,%eax
f0101f7a:	74 24                	je     f0101fa0 <mem_init+0xc3c>
f0101f7c:	c7 44 24 0c 3c 5a 10 	movl   $0xf0105a3c,0xc(%esp)
f0101f83:	f0 
f0101f84:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101f8b:	f0 
f0101f8c:	c7 44 24 04 e3 03 00 	movl   $0x3e3,0x4(%esp)
f0101f93:	00 
f0101f94:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101f9b:	e8 16 e1 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101fa0:	8b 3d 88 ef 17 f0    	mov    0xf017ef88,%edi
f0101fa6:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fab:	89 f8                	mov    %edi,%eax
f0101fad:	e8 e3 e9 ff ff       	call   f0100995 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101fb2:	89 f2                	mov    %esi,%edx
f0101fb4:	2b 15 8c ef 17 f0    	sub    0xf017ef8c,%edx
f0101fba:	c1 fa 03             	sar    $0x3,%edx
f0101fbd:	c1 e2 0c             	shl    $0xc,%edx
f0101fc0:	39 d0                	cmp    %edx,%eax
f0101fc2:	74 24                	je     f0101fe8 <mem_init+0xc84>
f0101fc4:	c7 44 24 0c cc 59 10 	movl   $0xf01059cc,0xc(%esp)
f0101fcb:	f0 
f0101fcc:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101fd3:	f0 
f0101fd4:	c7 44 24 04 e4 03 00 	movl   $0x3e4,0x4(%esp)
f0101fdb:	00 
f0101fdc:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0101fe3:	e8 ce e0 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0101fe8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101fed:	74 24                	je     f0102013 <mem_init+0xcaf>
f0101fef:	c7 44 24 0c d3 60 10 	movl   $0xf01060d3,0xc(%esp)
f0101ff6:	f0 
f0101ff7:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0101ffe:	f0 
f0101fff:	c7 44 24 04 e5 03 00 	movl   $0x3e5,0x4(%esp)
f0102006:	00 
f0102007:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f010200e:	e8 a3 e0 ff ff       	call   f01000b6 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102013:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010201a:	00 
f010201b:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102022:	00 
f0102023:	89 3c 24             	mov    %edi,(%esp)
f0102026:	e8 21 f0 ff ff       	call   f010104c <pgdir_walk>
f010202b:	f6 00 04             	testb  $0x4,(%eax)
f010202e:	75 24                	jne    f0102054 <mem_init+0xcf0>
f0102030:	c7 44 24 0c 7c 5a 10 	movl   $0xf0105a7c,0xc(%esp)
f0102037:	f0 
f0102038:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f010203f:	f0 
f0102040:	c7 44 24 04 e6 03 00 	movl   $0x3e6,0x4(%esp)
f0102047:	00 
f0102048:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f010204f:	e8 62 e0 ff ff       	call   f01000b6 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102054:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f0102059:	f6 00 04             	testb  $0x4,(%eax)
f010205c:	75 24                	jne    f0102082 <mem_init+0xd1e>
f010205e:	c7 44 24 0c e4 60 10 	movl   $0xf01060e4,0xc(%esp)
f0102065:	f0 
f0102066:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f010206d:	f0 
f010206e:	c7 44 24 04 e7 03 00 	movl   $0x3e7,0x4(%esp)
f0102075:	00 
f0102076:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f010207d:	e8 34 e0 ff ff       	call   f01000b6 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102082:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102089:	00 
f010208a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102091:	00 
f0102092:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102096:	89 04 24             	mov    %eax,(%esp)
f0102099:	e8 04 f2 ff ff       	call   f01012a2 <page_insert>
f010209e:	85 c0                	test   %eax,%eax
f01020a0:	74 24                	je     f01020c6 <mem_init+0xd62>
f01020a2:	c7 44 24 0c 90 59 10 	movl   $0xf0105990,0xc(%esp)
f01020a9:	f0 
f01020aa:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f01020b1:	f0 
f01020b2:	c7 44 24 04 ea 03 00 	movl   $0x3ea,0x4(%esp)
f01020b9:	00 
f01020ba:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f01020c1:	e8 f0 df ff ff       	call   f01000b6 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01020c6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01020cd:	00 
f01020ce:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01020d5:	00 
f01020d6:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f01020db:	89 04 24             	mov    %eax,(%esp)
f01020de:	e8 69 ef ff ff       	call   f010104c <pgdir_walk>
f01020e3:	f6 00 02             	testb  $0x2,(%eax)
f01020e6:	75 24                	jne    f010210c <mem_init+0xda8>
f01020e8:	c7 44 24 0c b0 5a 10 	movl   $0xf0105ab0,0xc(%esp)
f01020ef:	f0 
f01020f0:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f01020f7:	f0 
f01020f8:	c7 44 24 04 eb 03 00 	movl   $0x3eb,0x4(%esp)
f01020ff:	00 
f0102100:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102107:	e8 aa df ff ff       	call   f01000b6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010210c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102113:	00 
f0102114:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010211b:	00 
f010211c:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f0102121:	89 04 24             	mov    %eax,(%esp)
f0102124:	e8 23 ef ff ff       	call   f010104c <pgdir_walk>
f0102129:	f6 00 04             	testb  $0x4,(%eax)
f010212c:	74 24                	je     f0102152 <mem_init+0xdee>
f010212e:	c7 44 24 0c e4 5a 10 	movl   $0xf0105ae4,0xc(%esp)
f0102135:	f0 
f0102136:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f010213d:	f0 
f010213e:	c7 44 24 04 ec 03 00 	movl   $0x3ec,0x4(%esp)
f0102145:	00 
f0102146:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f010214d:	e8 64 df ff ff       	call   f01000b6 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102152:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102159:	00 
f010215a:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0102161:	00 
f0102162:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102165:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102169:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f010216e:	89 04 24             	mov    %eax,(%esp)
f0102171:	e8 2c f1 ff ff       	call   f01012a2 <page_insert>
f0102176:	85 c0                	test   %eax,%eax
f0102178:	78 24                	js     f010219e <mem_init+0xe3a>
f010217a:	c7 44 24 0c 1c 5b 10 	movl   $0xf0105b1c,0xc(%esp)
f0102181:	f0 
f0102182:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102189:	f0 
f010218a:	c7 44 24 04 ef 03 00 	movl   $0x3ef,0x4(%esp)
f0102191:	00 
f0102192:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102199:	e8 18 df ff ff       	call   f01000b6 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f010219e:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01021a5:	00 
f01021a6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01021ad:	00 
f01021ae:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01021b2:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f01021b7:	89 04 24             	mov    %eax,(%esp)
f01021ba:	e8 e3 f0 ff ff       	call   f01012a2 <page_insert>
f01021bf:	85 c0                	test   %eax,%eax
f01021c1:	74 24                	je     f01021e7 <mem_init+0xe83>
f01021c3:	c7 44 24 0c 54 5b 10 	movl   $0xf0105b54,0xc(%esp)
f01021ca:	f0 
f01021cb:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f01021d2:	f0 
f01021d3:	c7 44 24 04 f2 03 00 	movl   $0x3f2,0x4(%esp)
f01021da:	00 
f01021db:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f01021e2:	e8 cf de ff ff       	call   f01000b6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01021e7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01021ee:	00 
f01021ef:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01021f6:	00 
f01021f7:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f01021fc:	89 04 24             	mov    %eax,(%esp)
f01021ff:	e8 48 ee ff ff       	call   f010104c <pgdir_walk>
f0102204:	f6 00 04             	testb  $0x4,(%eax)
f0102207:	74 24                	je     f010222d <mem_init+0xec9>
f0102209:	c7 44 24 0c e4 5a 10 	movl   $0xf0105ae4,0xc(%esp)
f0102210:	f0 
f0102211:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102218:	f0 
f0102219:	c7 44 24 04 f3 03 00 	movl   $0x3f3,0x4(%esp)
f0102220:	00 
f0102221:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102228:	e8 89 de ff ff       	call   f01000b6 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010222d:	8b 3d 88 ef 17 f0    	mov    0xf017ef88,%edi
f0102233:	ba 00 00 00 00       	mov    $0x0,%edx
f0102238:	89 f8                	mov    %edi,%eax
f010223a:	e8 56 e7 ff ff       	call   f0100995 <check_va2pa>
f010223f:	89 c1                	mov    %eax,%ecx
f0102241:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102244:	89 d8                	mov    %ebx,%eax
f0102246:	2b 05 8c ef 17 f0    	sub    0xf017ef8c,%eax
f010224c:	c1 f8 03             	sar    $0x3,%eax
f010224f:	c1 e0 0c             	shl    $0xc,%eax
f0102252:	39 c1                	cmp    %eax,%ecx
f0102254:	74 24                	je     f010227a <mem_init+0xf16>
f0102256:	c7 44 24 0c 90 5b 10 	movl   $0xf0105b90,0xc(%esp)
f010225d:	f0 
f010225e:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102265:	f0 
f0102266:	c7 44 24 04 f6 03 00 	movl   $0x3f6,0x4(%esp)
f010226d:	00 
f010226e:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102275:	e8 3c de ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010227a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010227f:	89 f8                	mov    %edi,%eax
f0102281:	e8 0f e7 ff ff       	call   f0100995 <check_va2pa>
f0102286:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0102289:	74 24                	je     f01022af <mem_init+0xf4b>
f010228b:	c7 44 24 0c bc 5b 10 	movl   $0xf0105bbc,0xc(%esp)
f0102292:	f0 
f0102293:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f010229a:	f0 
f010229b:	c7 44 24 04 f7 03 00 	movl   $0x3f7,0x4(%esp)
f01022a2:	00 
f01022a3:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f01022aa:	e8 07 de ff ff       	call   f01000b6 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01022af:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f01022b4:	74 24                	je     f01022da <mem_init+0xf76>
f01022b6:	c7 44 24 0c fa 60 10 	movl   $0xf01060fa,0xc(%esp)
f01022bd:	f0 
f01022be:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f01022c5:	f0 
f01022c6:	c7 44 24 04 f9 03 00 	movl   $0x3f9,0x4(%esp)
f01022cd:	00 
f01022ce:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f01022d5:	e8 dc dd ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f01022da:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01022df:	74 24                	je     f0102305 <mem_init+0xfa1>
f01022e1:	c7 44 24 0c 0b 61 10 	movl   $0xf010610b,0xc(%esp)
f01022e8:	f0 
f01022e9:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f01022f0:	f0 
f01022f1:	c7 44 24 04 fa 03 00 	movl   $0x3fa,0x4(%esp)
f01022f8:	00 
f01022f9:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102300:	e8 b1 dd ff ff       	call   f01000b6 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102305:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010230c:	e8 2c ec ff ff       	call   f0100f3d <page_alloc>
f0102311:	85 c0                	test   %eax,%eax
f0102313:	74 04                	je     f0102319 <mem_init+0xfb5>
f0102315:	39 c6                	cmp    %eax,%esi
f0102317:	74 24                	je     f010233d <mem_init+0xfd9>
f0102319:	c7 44 24 0c ec 5b 10 	movl   $0xf0105bec,0xc(%esp)
f0102320:	f0 
f0102321:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102328:	f0 
f0102329:	c7 44 24 04 fd 03 00 	movl   $0x3fd,0x4(%esp)
f0102330:	00 
f0102331:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102338:	e8 79 dd ff ff       	call   f01000b6 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010233d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102344:	00 
f0102345:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f010234a:	89 04 24             	mov    %eax,(%esp)
f010234d:	e8 12 ef ff ff       	call   f0101264 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102352:	8b 3d 88 ef 17 f0    	mov    0xf017ef88,%edi
f0102358:	ba 00 00 00 00       	mov    $0x0,%edx
f010235d:	89 f8                	mov    %edi,%eax
f010235f:	e8 31 e6 ff ff       	call   f0100995 <check_va2pa>
f0102364:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102367:	74 24                	je     f010238d <mem_init+0x1029>
f0102369:	c7 44 24 0c 10 5c 10 	movl   $0xf0105c10,0xc(%esp)
f0102370:	f0 
f0102371:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102378:	f0 
f0102379:	c7 44 24 04 01 04 00 	movl   $0x401,0x4(%esp)
f0102380:	00 
f0102381:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102388:	e8 29 dd ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010238d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102392:	89 f8                	mov    %edi,%eax
f0102394:	e8 fc e5 ff ff       	call   f0100995 <check_va2pa>
f0102399:	89 da                	mov    %ebx,%edx
f010239b:	2b 15 8c ef 17 f0    	sub    0xf017ef8c,%edx
f01023a1:	c1 fa 03             	sar    $0x3,%edx
f01023a4:	c1 e2 0c             	shl    $0xc,%edx
f01023a7:	39 d0                	cmp    %edx,%eax
f01023a9:	74 24                	je     f01023cf <mem_init+0x106b>
f01023ab:	c7 44 24 0c bc 5b 10 	movl   $0xf0105bbc,0xc(%esp)
f01023b2:	f0 
f01023b3:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f01023ba:	f0 
f01023bb:	c7 44 24 04 02 04 00 	movl   $0x402,0x4(%esp)
f01023c2:	00 
f01023c3:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f01023ca:	e8 e7 dc ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 1);
f01023cf:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01023d4:	74 24                	je     f01023fa <mem_init+0x1096>
f01023d6:	c7 44 24 0c b1 60 10 	movl   $0xf01060b1,0xc(%esp)
f01023dd:	f0 
f01023de:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f01023e5:	f0 
f01023e6:	c7 44 24 04 03 04 00 	movl   $0x403,0x4(%esp)
f01023ed:	00 
f01023ee:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f01023f5:	e8 bc dc ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f01023fa:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01023ff:	74 24                	je     f0102425 <mem_init+0x10c1>
f0102401:	c7 44 24 0c 0b 61 10 	movl   $0xf010610b,0xc(%esp)
f0102408:	f0 
f0102409:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102410:	f0 
f0102411:	c7 44 24 04 04 04 00 	movl   $0x404,0x4(%esp)
f0102418:	00 
f0102419:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102420:	e8 91 dc ff ff       	call   f01000b6 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102425:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010242c:	00 
f010242d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102434:	00 
f0102435:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102439:	89 3c 24             	mov    %edi,(%esp)
f010243c:	e8 61 ee ff ff       	call   f01012a2 <page_insert>
f0102441:	85 c0                	test   %eax,%eax
f0102443:	74 24                	je     f0102469 <mem_init+0x1105>
f0102445:	c7 44 24 0c 34 5c 10 	movl   $0xf0105c34,0xc(%esp)
f010244c:	f0 
f010244d:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102454:	f0 
f0102455:	c7 44 24 04 07 04 00 	movl   $0x407,0x4(%esp)
f010245c:	00 
f010245d:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102464:	e8 4d dc ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref);
f0102469:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010246e:	75 24                	jne    f0102494 <mem_init+0x1130>
f0102470:	c7 44 24 0c 1c 61 10 	movl   $0xf010611c,0xc(%esp)
f0102477:	f0 
f0102478:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f010247f:	f0 
f0102480:	c7 44 24 04 08 04 00 	movl   $0x408,0x4(%esp)
f0102487:	00 
f0102488:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f010248f:	e8 22 dc ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_link == NULL);
f0102494:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102497:	74 24                	je     f01024bd <mem_init+0x1159>
f0102499:	c7 44 24 0c 28 61 10 	movl   $0xf0106128,0xc(%esp)
f01024a0:	f0 
f01024a1:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f01024a8:	f0 
f01024a9:	c7 44 24 04 09 04 00 	movl   $0x409,0x4(%esp)
f01024b0:	00 
f01024b1:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f01024b8:	e8 f9 db ff ff       	call   f01000b6 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01024bd:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01024c4:	00 
f01024c5:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f01024ca:	89 04 24             	mov    %eax,(%esp)
f01024cd:	e8 92 ed ff ff       	call   f0101264 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01024d2:	8b 3d 88 ef 17 f0    	mov    0xf017ef88,%edi
f01024d8:	ba 00 00 00 00       	mov    $0x0,%edx
f01024dd:	89 f8                	mov    %edi,%eax
f01024df:	e8 b1 e4 ff ff       	call   f0100995 <check_va2pa>
f01024e4:	83 f8 ff             	cmp    $0xffffffff,%eax
f01024e7:	74 24                	je     f010250d <mem_init+0x11a9>
f01024e9:	c7 44 24 0c 10 5c 10 	movl   $0xf0105c10,0xc(%esp)
f01024f0:	f0 
f01024f1:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f01024f8:	f0 
f01024f9:	c7 44 24 04 0d 04 00 	movl   $0x40d,0x4(%esp)
f0102500:	00 
f0102501:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102508:	e8 a9 db ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010250d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102512:	89 f8                	mov    %edi,%eax
f0102514:	e8 7c e4 ff ff       	call   f0100995 <check_va2pa>
f0102519:	83 f8 ff             	cmp    $0xffffffff,%eax
f010251c:	74 24                	je     f0102542 <mem_init+0x11de>
f010251e:	c7 44 24 0c 6c 5c 10 	movl   $0xf0105c6c,0xc(%esp)
f0102525:	f0 
f0102526:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f010252d:	f0 
f010252e:	c7 44 24 04 0e 04 00 	movl   $0x40e,0x4(%esp)
f0102535:	00 
f0102536:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f010253d:	e8 74 db ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 0);
f0102542:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102547:	74 24                	je     f010256d <mem_init+0x1209>
f0102549:	c7 44 24 0c 3d 61 10 	movl   $0xf010613d,0xc(%esp)
f0102550:	f0 
f0102551:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102558:	f0 
f0102559:	c7 44 24 04 0f 04 00 	movl   $0x40f,0x4(%esp)
f0102560:	00 
f0102561:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102568:	e8 49 db ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f010256d:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102572:	74 24                	je     f0102598 <mem_init+0x1234>
f0102574:	c7 44 24 0c 0b 61 10 	movl   $0xf010610b,0xc(%esp)
f010257b:	f0 
f010257c:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102583:	f0 
f0102584:	c7 44 24 04 10 04 00 	movl   $0x410,0x4(%esp)
f010258b:	00 
f010258c:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102593:	e8 1e db ff ff       	call   f01000b6 <_panic>
	
	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102598:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010259f:	e8 99 e9 ff ff       	call   f0100f3d <page_alloc>
f01025a4:	85 c0                	test   %eax,%eax
f01025a6:	74 04                	je     f01025ac <mem_init+0x1248>
f01025a8:	39 c3                	cmp    %eax,%ebx
f01025aa:	74 24                	je     f01025d0 <mem_init+0x126c>
f01025ac:	c7 44 24 0c 94 5c 10 	movl   $0xf0105c94,0xc(%esp)
f01025b3:	f0 
f01025b4:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f01025bb:	f0 
f01025bc:	c7 44 24 04 13 04 00 	movl   $0x413,0x4(%esp)
f01025c3:	00 
f01025c4:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f01025cb:	e8 e6 da ff ff       	call   f01000b6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01025d0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01025d7:	e8 61 e9 ff ff       	call   f0100f3d <page_alloc>
f01025dc:	85 c0                	test   %eax,%eax
f01025de:	74 24                	je     f0102604 <mem_init+0x12a0>
f01025e0:	c7 44 24 0c 5f 60 10 	movl   $0xf010605f,0xc(%esp)
f01025e7:	f0 
f01025e8:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f01025ef:	f0 
f01025f0:	c7 44 24 04 16 04 00 	movl   $0x416,0x4(%esp)
f01025f7:	00 
f01025f8:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f01025ff:	e8 b2 da ff ff       	call   f01000b6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102604:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f0102609:	8b 08                	mov    (%eax),%ecx
f010260b:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102611:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102614:	2b 15 8c ef 17 f0    	sub    0xf017ef8c,%edx
f010261a:	c1 fa 03             	sar    $0x3,%edx
f010261d:	c1 e2 0c             	shl    $0xc,%edx
f0102620:	39 d1                	cmp    %edx,%ecx
f0102622:	74 24                	je     f0102648 <mem_init+0x12e4>
f0102624:	c7 44 24 0c 38 59 10 	movl   $0xf0105938,0xc(%esp)
f010262b:	f0 
f010262c:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102633:	f0 
f0102634:	c7 44 24 04 19 04 00 	movl   $0x419,0x4(%esp)
f010263b:	00 
f010263c:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102643:	e8 6e da ff ff       	call   f01000b6 <_panic>
	kern_pgdir[0] = 0;
f0102648:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f010264e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102651:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102656:	74 24                	je     f010267c <mem_init+0x1318>
f0102658:	c7 44 24 0c c2 60 10 	movl   $0xf01060c2,0xc(%esp)
f010265f:	f0 
f0102660:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102667:	f0 
f0102668:	c7 44 24 04 1b 04 00 	movl   $0x41b,0x4(%esp)
f010266f:	00 
f0102670:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102677:	e8 3a da ff ff       	call   f01000b6 <_panic>
	pp0->pp_ref = 0;
f010267c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010267f:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102685:	89 04 24             	mov    %eax,(%esp)
f0102688:	e8 41 e9 ff ff       	call   f0100fce <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f010268d:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102694:	00 
f0102695:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f010269c:	00 
f010269d:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f01026a2:	89 04 24             	mov    %eax,(%esp)
f01026a5:	e8 a2 e9 ff ff       	call   f010104c <pgdir_walk>
f01026aa:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01026ad:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01026b0:	8b 15 88 ef 17 f0    	mov    0xf017ef88,%edx
f01026b6:	8b 7a 04             	mov    0x4(%edx),%edi
f01026b9:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01026bf:	8b 0d 84 ef 17 f0    	mov    0xf017ef84,%ecx
f01026c5:	89 f8                	mov    %edi,%eax
f01026c7:	c1 e8 0c             	shr    $0xc,%eax
f01026ca:	39 c8                	cmp    %ecx,%eax
f01026cc:	72 20                	jb     f01026ee <mem_init+0x138a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01026ce:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01026d2:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f01026d9:	f0 
f01026da:	c7 44 24 04 22 04 00 	movl   $0x422,0x4(%esp)
f01026e1:	00 
f01026e2:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f01026e9:	e8 c8 d9 ff ff       	call   f01000b6 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01026ee:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f01026f4:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f01026f7:	74 24                	je     f010271d <mem_init+0x13b9>
f01026f9:	c7 44 24 0c 4e 61 10 	movl   $0xf010614e,0xc(%esp)
f0102700:	f0 
f0102701:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102708:	f0 
f0102709:	c7 44 24 04 23 04 00 	movl   $0x423,0x4(%esp)
f0102710:	00 
f0102711:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102718:	e8 99 d9 ff ff       	call   f01000b6 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010271d:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f0102724:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102727:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010272d:	2b 05 8c ef 17 f0    	sub    0xf017ef8c,%eax
f0102733:	c1 f8 03             	sar    $0x3,%eax
f0102736:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102739:	89 c2                	mov    %eax,%edx
f010273b:	c1 ea 0c             	shr    $0xc,%edx
f010273e:	39 d1                	cmp    %edx,%ecx
f0102740:	77 20                	ja     f0102762 <mem_init+0x13fe>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102742:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102746:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f010274d:	f0 
f010274e:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102755:	00 
f0102756:	c7 04 24 b5 5e 10 f0 	movl   $0xf0105eb5,(%esp)
f010275d:	e8 54 d9 ff ff       	call   f01000b6 <_panic>
	
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102762:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102769:	00 
f010276a:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102771:	00 
	return (void *)(pa + KERNBASE);
f0102772:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102777:	89 04 24             	mov    %eax,(%esp)
f010277a:	e8 b8 24 00 00       	call   f0104c37 <memset>
	page_free(pp0);
f010277f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102782:	89 3c 24             	mov    %edi,(%esp)
f0102785:	e8 44 e8 ff ff       	call   f0100fce <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010278a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102791:	00 
f0102792:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102799:	00 
f010279a:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f010279f:	89 04 24             	mov    %eax,(%esp)
f01027a2:	e8 a5 e8 ff ff       	call   f010104c <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01027a7:	89 fa                	mov    %edi,%edx
f01027a9:	2b 15 8c ef 17 f0    	sub    0xf017ef8c,%edx
f01027af:	c1 fa 03             	sar    $0x3,%edx
f01027b2:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01027b5:	89 d0                	mov    %edx,%eax
f01027b7:	c1 e8 0c             	shr    $0xc,%eax
f01027ba:	3b 05 84 ef 17 f0    	cmp    0xf017ef84,%eax
f01027c0:	72 20                	jb     f01027e2 <mem_init+0x147e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01027c2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01027c6:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f01027cd:	f0 
f01027ce:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01027d5:	00 
f01027d6:	c7 04 24 b5 5e 10 f0 	movl   $0xf0105eb5,(%esp)
f01027dd:	e8 d4 d8 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f01027e2:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01027e8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01027eb:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01027f1:	f6 00 01             	testb  $0x1,(%eax)
f01027f4:	74 24                	je     f010281a <mem_init+0x14b6>
f01027f6:	c7 44 24 0c 66 61 10 	movl   $0xf0106166,0xc(%esp)
f01027fd:	f0 
f01027fe:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102805:	f0 
f0102806:	c7 44 24 04 2d 04 00 	movl   $0x42d,0x4(%esp)
f010280d:	00 
f010280e:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102815:	e8 9c d8 ff ff       	call   f01000b6 <_panic>
f010281a:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010281d:	39 d0                	cmp    %edx,%eax
f010281f:	75 d0                	jne    f01027f1 <mem_init+0x148d>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102821:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f0102826:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010282c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010282f:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102835:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0102838:	89 3d c4 e2 17 f0    	mov    %edi,0xf017e2c4

	// free the pages we took
	page_free(pp0);
f010283e:	89 04 24             	mov    %eax,(%esp)
f0102841:	e8 88 e7 ff ff       	call   f0100fce <page_free>
	page_free(pp1);
f0102846:	89 1c 24             	mov    %ebx,(%esp)
f0102849:	e8 80 e7 ff ff       	call   f0100fce <page_free>
	page_free(pp2);
f010284e:	89 34 24             	mov    %esi,(%esp)
f0102851:	e8 78 e7 ff ff       	call   f0100fce <page_free>

	cprintf("check_page() succeeded!\n");
f0102856:	c7 04 24 7d 61 10 f0 	movl   $0xf010617d,(%esp)
f010285d:	e8 ab 10 00 00       	call   f010390d <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, ROUNDUP( (sizeof(struct PageInfo)*npages),PGSIZE), PADDR(pages), PTE_U | PTE_P);
f0102862:	a1 8c ef 17 f0       	mov    0xf017ef8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102867:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010286c:	77 20                	ja     f010288e <mem_init+0x152a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010286e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102872:	c7 44 24 08 28 56 10 	movl   $0xf0105628,0x8(%esp)
f0102879:	f0 
f010287a:	c7 44 24 04 c3 00 00 	movl   $0xc3,0x4(%esp)
f0102881:	00 
f0102882:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102889:	e8 28 d8 ff ff       	call   f01000b6 <_panic>
f010288e:	8b 15 84 ef 17 f0    	mov    0xf017ef84,%edx
f0102894:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f010289b:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01028a1:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f01028a8:	00 
	return (physaddr_t)kva - KERNBASE;
f01028a9:	05 00 00 00 10       	add    $0x10000000,%eax
f01028ae:	89 04 24             	mov    %eax,(%esp)
f01028b1:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01028b6:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f01028bb:	e8 9b e8 ff ff       	call   f010115b <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, sizeof(struct Env) * NENV,PADDR(envs), PTE_U);
f01028c0:	a1 d0 e2 17 f0       	mov    0xf017e2d0,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028c5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01028ca:	77 20                	ja     f01028ec <mem_init+0x1588>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028cc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01028d0:	c7 44 24 08 28 56 10 	movl   $0xf0105628,0x8(%esp)
f01028d7:	f0 
f01028d8:	c7 44 24 04 cb 00 00 	movl   $0xcb,0x4(%esp)
f01028df:	00 
f01028e0:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f01028e7:	e8 ca d7 ff ff       	call   f01000b6 <_panic>
f01028ec:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f01028f3:	00 
	return (physaddr_t)kva - KERNBASE;
f01028f4:	05 00 00 00 10       	add    $0x10000000,%eax
f01028f9:	89 04 24             	mov    %eax,(%esp)
f01028fc:	b9 00 80 01 00       	mov    $0x18000,%ecx
f0102901:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102906:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f010290b:	e8 4b e8 ff ff       	call   f010115b <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102910:	bb 00 20 11 f0       	mov    $0xf0112000,%ebx
f0102915:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f010291b:	77 20                	ja     f010293d <mem_init+0x15d9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010291d:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102921:	c7 44 24 08 28 56 10 	movl   $0xf0105628,0x8(%esp)
f0102928:	f0 
f0102929:	c7 44 24 04 d7 00 00 	movl   $0xd7,0x4(%esp)
f0102930:	00 
f0102931:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102938:	e8 79 d7 ff ff       	call   f01000b6 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W | PTE_P);
f010293d:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102944:	00 
f0102945:	c7 04 24 00 20 11 00 	movl   $0x112000,(%esp)
f010294c:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102951:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102956:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f010295b:	e8 fb e7 ff ff       	call   f010115b <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	size_t size = ROUNDUP(0xFFFFFFFF - KERNBASE + 1, PGSIZE);
	boot_map_region(kern_pgdir, KERNBASE, size, 0, PTE_W | PTE_P);
f0102960:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102967:	00 
f0102968:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010296f:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102974:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102979:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f010297e:	e8 d8 e7 ff ff       	call   f010115b <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102983:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f0102988:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010298b:	a1 84 ef 17 f0       	mov    0xf017ef84,%eax
f0102990:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102993:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010299a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010299f:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01029a2:	8b 3d 8c ef 17 f0    	mov    0xf017ef8c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01029a8:	89 7d c8             	mov    %edi,-0x38(%ebp)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f01029ab:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01029b1:	89 45 c4             	mov    %eax,-0x3c(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01029b4:	be 00 00 00 00       	mov    $0x0,%esi
f01029b9:	eb 6b                	jmp    f0102a26 <mem_init+0x16c2>
f01029bb:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01029c1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01029c4:	e8 cc df ff ff       	call   f0100995 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01029c9:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f01029d0:	77 20                	ja     f01029f2 <mem_init+0x168e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029d2:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01029d6:	c7 44 24 08 28 56 10 	movl   $0xf0105628,0x8(%esp)
f01029dd:	f0 
f01029de:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f01029e5:	00 
f01029e6:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f01029ed:	e8 c4 d6 ff ff       	call   f01000b6 <_panic>
f01029f2:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f01029f5:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01029f8:	39 d0                	cmp    %edx,%eax
f01029fa:	74 24                	je     f0102a20 <mem_init+0x16bc>
f01029fc:	c7 44 24 0c b8 5c 10 	movl   $0xf0105cb8,0xc(%esp)
f0102a03:	f0 
f0102a04:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102a0b:	f0 
f0102a0c:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f0102a13:	00 
f0102a14:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102a1b:	e8 96 d6 ff ff       	call   f01000b6 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102a20:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102a26:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0102a29:	77 90                	ja     f01029bb <mem_init+0x1657>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102a2b:	8b 35 d0 e2 17 f0    	mov    0xf017e2d0,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a31:	89 f7                	mov    %esi,%edi
f0102a33:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102a38:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a3b:	e8 55 df ff ff       	call   f0100995 <check_va2pa>
f0102a40:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102a46:	77 20                	ja     f0102a68 <mem_init+0x1704>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a48:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102a4c:	c7 44 24 08 28 56 10 	movl   $0xf0105628,0x8(%esp)
f0102a53:	f0 
f0102a54:	c7 44 24 04 6c 03 00 	movl   $0x36c,0x4(%esp)
f0102a5b:	00 
f0102a5c:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102a63:	e8 4e d6 ff ff       	call   f01000b6 <_panic>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a68:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f0102a6d:	81 c7 00 00 40 21    	add    $0x21400000,%edi
f0102a73:	8d 14 37             	lea    (%edi,%esi,1),%edx
f0102a76:	39 c2                	cmp    %eax,%edx
f0102a78:	74 24                	je     f0102a9e <mem_init+0x173a>
f0102a7a:	c7 44 24 0c ec 5c 10 	movl   $0xf0105cec,0xc(%esp)
f0102a81:	f0 
f0102a82:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102a89:	f0 
f0102a8a:	c7 44 24 04 6c 03 00 	movl   $0x36c,0x4(%esp)
f0102a91:	00 
f0102a92:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102a99:	e8 18 d6 ff ff       	call   f01000b6 <_panic>
f0102a9e:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102aa4:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f0102aaa:	0f 85 26 05 00 00    	jne    f0102fd6 <mem_init+0x1c72>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102ab0:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0102ab3:	c1 e7 0c             	shl    $0xc,%edi
f0102ab6:	be 00 00 00 00       	mov    $0x0,%esi
f0102abb:	eb 3c                	jmp    f0102af9 <mem_init+0x1795>
f0102abd:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102ac3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ac6:	e8 ca de ff ff       	call   f0100995 <check_va2pa>
f0102acb:	39 c6                	cmp    %eax,%esi
f0102acd:	74 24                	je     f0102af3 <mem_init+0x178f>
f0102acf:	c7 44 24 0c 20 5d 10 	movl   $0xf0105d20,0xc(%esp)
f0102ad6:	f0 
f0102ad7:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102ade:	f0 
f0102adf:	c7 44 24 04 70 03 00 	movl   $0x370,0x4(%esp)
f0102ae6:	00 
f0102ae7:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102aee:	e8 c3 d5 ff ff       	call   f01000b6 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102af3:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102af9:	39 fe                	cmp    %edi,%esi
f0102afb:	72 c0                	jb     f0102abd <mem_init+0x1759>
f0102afd:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102b02:	81 c3 00 80 00 20    	add    $0x20008000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102b08:	89 f2                	mov    %esi,%edx
f0102b0a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b0d:	e8 83 de ff ff       	call   f0100995 <check_va2pa>
f0102b12:	8d 14 33             	lea    (%ebx,%esi,1),%edx
f0102b15:	39 d0                	cmp    %edx,%eax
f0102b17:	74 24                	je     f0102b3d <mem_init+0x17d9>
f0102b19:	c7 44 24 0c 48 5d 10 	movl   $0xf0105d48,0xc(%esp)
f0102b20:	f0 
f0102b21:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102b28:	f0 
f0102b29:	c7 44 24 04 74 03 00 	movl   $0x374,0x4(%esp)
f0102b30:	00 
f0102b31:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102b38:	e8 79 d5 ff ff       	call   f01000b6 <_panic>
f0102b3d:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102b43:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102b49:	75 bd                	jne    f0102b08 <mem_init+0x17a4>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102b4b:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102b50:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102b53:	89 f8                	mov    %edi,%eax
f0102b55:	e8 3b de ff ff       	call   f0100995 <check_va2pa>
f0102b5a:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102b5d:	75 0c                	jne    f0102b6b <mem_init+0x1807>
f0102b5f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b64:	89 fa                	mov    %edi,%edx
f0102b66:	e9 f0 00 00 00       	jmp    f0102c5b <mem_init+0x18f7>
f0102b6b:	c7 44 24 0c 90 5d 10 	movl   $0xf0105d90,0xc(%esp)
f0102b72:	f0 
f0102b73:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102b7a:	f0 
f0102b7b:	c7 44 24 04 75 03 00 	movl   $0x375,0x4(%esp)
f0102b82:	00 
f0102b83:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102b8a:	e8 27 d5 ff ff       	call   f01000b6 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102b8f:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102b94:	72 3c                	jb     f0102bd2 <mem_init+0x186e>
f0102b96:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102b9b:	76 07                	jbe    f0102ba4 <mem_init+0x1840>
f0102b9d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102ba2:	75 2e                	jne    f0102bd2 <mem_init+0x186e>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f0102ba4:	f6 04 82 01          	testb  $0x1,(%edx,%eax,4)
f0102ba8:	0f 85 aa 00 00 00    	jne    f0102c58 <mem_init+0x18f4>
f0102bae:	c7 44 24 0c 96 61 10 	movl   $0xf0106196,0xc(%esp)
f0102bb5:	f0 
f0102bb6:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102bbd:	f0 
f0102bbe:	c7 44 24 04 7e 03 00 	movl   $0x37e,0x4(%esp)
f0102bc5:	00 
f0102bc6:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102bcd:	e8 e4 d4 ff ff       	call   f01000b6 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102bd2:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102bd7:	76 55                	jbe    f0102c2e <mem_init+0x18ca>
				assert(pgdir[i] & PTE_P);
f0102bd9:	8b 0c 82             	mov    (%edx,%eax,4),%ecx
f0102bdc:	f6 c1 01             	test   $0x1,%cl
f0102bdf:	75 24                	jne    f0102c05 <mem_init+0x18a1>
f0102be1:	c7 44 24 0c 96 61 10 	movl   $0xf0106196,0xc(%esp)
f0102be8:	f0 
f0102be9:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102bf0:	f0 
f0102bf1:	c7 44 24 04 82 03 00 	movl   $0x382,0x4(%esp)
f0102bf8:	00 
f0102bf9:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102c00:	e8 b1 d4 ff ff       	call   f01000b6 <_panic>
				assert(pgdir[i] & PTE_W);
f0102c05:	f6 c1 02             	test   $0x2,%cl
f0102c08:	75 4e                	jne    f0102c58 <mem_init+0x18f4>
f0102c0a:	c7 44 24 0c a7 61 10 	movl   $0xf01061a7,0xc(%esp)
f0102c11:	f0 
f0102c12:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102c19:	f0 
f0102c1a:	c7 44 24 04 83 03 00 	movl   $0x383,0x4(%esp)
f0102c21:	00 
f0102c22:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102c29:	e8 88 d4 ff ff       	call   f01000b6 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102c2e:	83 3c 82 00          	cmpl   $0x0,(%edx,%eax,4)
f0102c32:	74 24                	je     f0102c58 <mem_init+0x18f4>
f0102c34:	c7 44 24 0c b8 61 10 	movl   $0xf01061b8,0xc(%esp)
f0102c3b:	f0 
f0102c3c:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102c43:	f0 
f0102c44:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f0102c4b:	00 
f0102c4c:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102c53:	e8 5e d4 ff ff       	call   f01000b6 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102c58:	83 c0 01             	add    $0x1,%eax
f0102c5b:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102c60:	0f 85 29 ff ff ff    	jne    f0102b8f <mem_init+0x182b>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102c66:	c7 04 24 c0 5d 10 f0 	movl   $0xf0105dc0,(%esp)
f0102c6d:	e8 9b 0c 00 00       	call   f010390d <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102c72:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f0102c77:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c7c:	77 20                	ja     f0102c9e <mem_init+0x193a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c7e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c82:	c7 44 24 08 28 56 10 	movl   $0xf0105628,0x8(%esp)
f0102c89:	f0 
f0102c8a:	c7 44 24 04 ec 00 00 	movl   $0xec,0x4(%esp)
f0102c91:	00 
f0102c92:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102c99:	e8 18 d4 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102c9e:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102ca3:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102ca6:	b8 00 00 00 00       	mov    $0x0,%eax
f0102cab:	e8 d9 dd ff ff       	call   f0100a89 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102cb0:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102cb3:	83 e0 f3             	and    $0xfffffff3,%eax
f0102cb6:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102cbb:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102cbe:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102cc5:	e8 73 e2 ff ff       	call   f0100f3d <page_alloc>
f0102cca:	89 c3                	mov    %eax,%ebx
f0102ccc:	85 c0                	test   %eax,%eax
f0102cce:	75 24                	jne    f0102cf4 <mem_init+0x1990>
f0102cd0:	c7 44 24 0c b4 5f 10 	movl   $0xf0105fb4,0xc(%esp)
f0102cd7:	f0 
f0102cd8:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102cdf:	f0 
f0102ce0:	c7 44 24 04 48 04 00 	movl   $0x448,0x4(%esp)
f0102ce7:	00 
f0102ce8:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102cef:	e8 c2 d3 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0102cf4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102cfb:	e8 3d e2 ff ff       	call   f0100f3d <page_alloc>
f0102d00:	89 c7                	mov    %eax,%edi
f0102d02:	85 c0                	test   %eax,%eax
f0102d04:	75 24                	jne    f0102d2a <mem_init+0x19c6>
f0102d06:	c7 44 24 0c ca 5f 10 	movl   $0xf0105fca,0xc(%esp)
f0102d0d:	f0 
f0102d0e:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102d15:	f0 
f0102d16:	c7 44 24 04 49 04 00 	movl   $0x449,0x4(%esp)
f0102d1d:	00 
f0102d1e:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102d25:	e8 8c d3 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f0102d2a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102d31:	e8 07 e2 ff ff       	call   f0100f3d <page_alloc>
f0102d36:	89 c6                	mov    %eax,%esi
f0102d38:	85 c0                	test   %eax,%eax
f0102d3a:	75 24                	jne    f0102d60 <mem_init+0x19fc>
f0102d3c:	c7 44 24 0c e0 5f 10 	movl   $0xf0105fe0,0xc(%esp)
f0102d43:	f0 
f0102d44:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102d4b:	f0 
f0102d4c:	c7 44 24 04 4a 04 00 	movl   $0x44a,0x4(%esp)
f0102d53:	00 
f0102d54:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102d5b:	e8 56 d3 ff ff       	call   f01000b6 <_panic>
	page_free(pp0);
f0102d60:	89 1c 24             	mov    %ebx,(%esp)
f0102d63:	e8 66 e2 ff ff       	call   f0100fce <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0102d68:	89 f8                	mov    %edi,%eax
f0102d6a:	e8 e1 db ff ff       	call   f0100950 <page2kva>
f0102d6f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102d76:	00 
f0102d77:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102d7e:	00 
f0102d7f:	89 04 24             	mov    %eax,(%esp)
f0102d82:	e8 b0 1e 00 00       	call   f0104c37 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0102d87:	89 f0                	mov    %esi,%eax
f0102d89:	e8 c2 db ff ff       	call   f0100950 <page2kva>
f0102d8e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102d95:	00 
f0102d96:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102d9d:	00 
f0102d9e:	89 04 24             	mov    %eax,(%esp)
f0102da1:	e8 91 1e 00 00       	call   f0104c37 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102da6:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102dad:	00 
f0102dae:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102db5:	00 
f0102db6:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102dba:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f0102dbf:	89 04 24             	mov    %eax,(%esp)
f0102dc2:	e8 db e4 ff ff       	call   f01012a2 <page_insert>
	assert(pp1->pp_ref == 1);
f0102dc7:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102dcc:	74 24                	je     f0102df2 <mem_init+0x1a8e>
f0102dce:	c7 44 24 0c b1 60 10 	movl   $0xf01060b1,0xc(%esp)
f0102dd5:	f0 
f0102dd6:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102ddd:	f0 
f0102dde:	c7 44 24 04 4f 04 00 	movl   $0x44f,0x4(%esp)
f0102de5:	00 
f0102de6:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102ded:	e8 c4 d2 ff ff       	call   f01000b6 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102df2:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102df9:	01 01 01 
f0102dfc:	74 24                	je     f0102e22 <mem_init+0x1abe>
f0102dfe:	c7 44 24 0c e0 5d 10 	movl   $0xf0105de0,0xc(%esp)
f0102e05:	f0 
f0102e06:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102e0d:	f0 
f0102e0e:	c7 44 24 04 50 04 00 	movl   $0x450,0x4(%esp)
f0102e15:	00 
f0102e16:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102e1d:	e8 94 d2 ff ff       	call   f01000b6 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102e22:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102e29:	00 
f0102e2a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102e31:	00 
f0102e32:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102e36:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f0102e3b:	89 04 24             	mov    %eax,(%esp)
f0102e3e:	e8 5f e4 ff ff       	call   f01012a2 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102e43:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102e4a:	02 02 02 
f0102e4d:	74 24                	je     f0102e73 <mem_init+0x1b0f>
f0102e4f:	c7 44 24 0c 04 5e 10 	movl   $0xf0105e04,0xc(%esp)
f0102e56:	f0 
f0102e57:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102e5e:	f0 
f0102e5f:	c7 44 24 04 52 04 00 	movl   $0x452,0x4(%esp)
f0102e66:	00 
f0102e67:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102e6e:	e8 43 d2 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0102e73:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102e78:	74 24                	je     f0102e9e <mem_init+0x1b3a>
f0102e7a:	c7 44 24 0c d3 60 10 	movl   $0xf01060d3,0xc(%esp)
f0102e81:	f0 
f0102e82:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102e89:	f0 
f0102e8a:	c7 44 24 04 53 04 00 	movl   $0x453,0x4(%esp)
f0102e91:	00 
f0102e92:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102e99:	e8 18 d2 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 0);
f0102e9e:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102ea3:	74 24                	je     f0102ec9 <mem_init+0x1b65>
f0102ea5:	c7 44 24 0c 3d 61 10 	movl   $0xf010613d,0xc(%esp)
f0102eac:	f0 
f0102ead:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102eb4:	f0 
f0102eb5:	c7 44 24 04 54 04 00 	movl   $0x454,0x4(%esp)
f0102ebc:	00 
f0102ebd:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102ec4:	e8 ed d1 ff ff       	call   f01000b6 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102ec9:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102ed0:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102ed3:	89 f0                	mov    %esi,%eax
f0102ed5:	e8 76 da ff ff       	call   f0100950 <page2kva>
f0102eda:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0102ee0:	74 24                	je     f0102f06 <mem_init+0x1ba2>
f0102ee2:	c7 44 24 0c 28 5e 10 	movl   $0xf0105e28,0xc(%esp)
f0102ee9:	f0 
f0102eea:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102ef1:	f0 
f0102ef2:	c7 44 24 04 56 04 00 	movl   $0x456,0x4(%esp)
f0102ef9:	00 
f0102efa:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102f01:	e8 b0 d1 ff ff       	call   f01000b6 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102f06:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102f0d:	00 
f0102f0e:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f0102f13:	89 04 24             	mov    %eax,(%esp)
f0102f16:	e8 49 e3 ff ff       	call   f0101264 <page_remove>
	assert(pp2->pp_ref == 0);
f0102f1b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102f20:	74 24                	je     f0102f46 <mem_init+0x1be2>
f0102f22:	c7 44 24 0c 0b 61 10 	movl   $0xf010610b,0xc(%esp)
f0102f29:	f0 
f0102f2a:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102f31:	f0 
f0102f32:	c7 44 24 04 58 04 00 	movl   $0x458,0x4(%esp)
f0102f39:	00 
f0102f3a:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102f41:	e8 70 d1 ff ff       	call   f01000b6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102f46:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
f0102f4b:	8b 08                	mov    (%eax),%ecx
f0102f4d:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102f53:	89 da                	mov    %ebx,%edx
f0102f55:	2b 15 8c ef 17 f0    	sub    0xf017ef8c,%edx
f0102f5b:	c1 fa 03             	sar    $0x3,%edx
f0102f5e:	c1 e2 0c             	shl    $0xc,%edx
f0102f61:	39 d1                	cmp    %edx,%ecx
f0102f63:	74 24                	je     f0102f89 <mem_init+0x1c25>
f0102f65:	c7 44 24 0c 38 59 10 	movl   $0xf0105938,0xc(%esp)
f0102f6c:	f0 
f0102f6d:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102f74:	f0 
f0102f75:	c7 44 24 04 5b 04 00 	movl   $0x45b,0x4(%esp)
f0102f7c:	00 
f0102f7d:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102f84:	e8 2d d1 ff ff       	call   f01000b6 <_panic>
	kern_pgdir[0] = 0;
f0102f89:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102f8f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102f94:	74 24                	je     f0102fba <mem_init+0x1c56>
f0102f96:	c7 44 24 0c c2 60 10 	movl   $0xf01060c2,0xc(%esp)
f0102f9d:	f0 
f0102f9e:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0102fa5:	f0 
f0102fa6:	c7 44 24 04 5d 04 00 	movl   $0x45d,0x4(%esp)
f0102fad:	00 
f0102fae:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f0102fb5:	e8 fc d0 ff ff       	call   f01000b6 <_panic>
	pp0->pp_ref = 0;
f0102fba:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102fc0:	89 1c 24             	mov    %ebx,(%esp)
f0102fc3:	e8 06 e0 ff ff       	call   f0100fce <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102fc8:	c7 04 24 54 5e 10 f0 	movl   $0xf0105e54,(%esp)
f0102fcf:	e8 39 09 00 00       	call   f010390d <cprintf>
f0102fd4:	eb 0f                	jmp    f0102fe5 <mem_init+0x1c81>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102fd6:	89 f2                	mov    %esi,%edx
f0102fd8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102fdb:	e8 b5 d9 ff ff       	call   f0100995 <check_va2pa>
f0102fe0:	e9 8e fa ff ff       	jmp    f0102a73 <mem_init+0x170f>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102fe5:	83 c4 4c             	add    $0x4c,%esp
f0102fe8:	5b                   	pop    %ebx
f0102fe9:	5e                   	pop    %esi
f0102fea:	5f                   	pop    %edi
f0102feb:	5d                   	pop    %ebp
f0102fec:	c3                   	ret    

f0102fed <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102fed:	55                   	push   %ebp
f0102fee:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102ff0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ff3:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102ff6:	5d                   	pop    %ebp
f0102ff7:	c3                   	ret    

f0102ff8 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102ff8:	55                   	push   %ebp
f0102ff9:	89 e5                	mov    %esp,%ebp
f0102ffb:	57                   	push   %edi
f0102ffc:	56                   	push   %esi
f0102ffd:	53                   	push   %ebx
f0102ffe:	83 ec 2c             	sub    $0x2c,%esp
f0103001:	8b 75 08             	mov    0x8(%ebp),%esi
f0103004:	8b 4d 14             	mov    0x14(%ebp),%ecx
	// LAB 3: Your code here.

	// step 1 : check below ULIM
  uintptr_t va_beg = (uintptr_t)va;
  uintptr_t va_end = va_beg + len;
f0103007:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010300a:	03 5d 10             	add    0x10(%ebp),%ebx
  if (va_beg >= ULIM || va_end >= ULIM) {
f010300d:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0103013:	77 09                	ja     f010301e <user_mem_check+0x26>
f0103015:	81 7d 0c ff ff 7f ef 	cmpl   $0xef7fffff,0xc(%ebp)
f010301c:	76 1f                	jbe    f010303d <user_mem_check+0x45>
    user_mem_check_addr = (va_beg >= ULIM) ? va_beg : ULIM;
f010301e:	81 7d 0c 00 00 80 ef 	cmpl   $0xef800000,0xc(%ebp)
f0103025:	b8 00 00 80 ef       	mov    $0xef800000,%eax
f010302a:	0f 43 45 0c          	cmovae 0xc(%ebp),%eax
f010302e:	a3 c0 e2 17 f0       	mov    %eax,0xf017e2c0
    return -E_FAULT;
f0103033:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0103038:	e9 b8 00 00 00       	jmp    f01030f5 <user_mem_check+0xfd>
  }

  // step 2 : check present & permission
  uintptr_t va_beg2 = ROUNDDOWN(va_beg, PGSIZE);
f010303d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103040:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  uintptr_t va_end2 = ROUNDUP(va_end, PGSIZE);
f0103045:	81 c3 ff 0f 00 00    	add    $0xfff,%ebx
f010304b:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103051:	8b 15 84 ef 17 f0    	mov    0xf017ef84,%edx
f0103057:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010305a:	89 75 08             	mov    %esi,0x8(%ebp)
  while (va_beg2 < va_end2) {
f010305d:	e9 86 00 00 00       	jmp    f01030e8 <user_mem_check+0xf0>

    // check page table is present ?
    if (!(env->env_pgdir[PDX(va_beg2)] & PTE_P)) {
f0103062:	89 c7                	mov    %eax,%edi
f0103064:	c1 ef 16             	shr    $0x16,%edi
f0103067:	8b 75 08             	mov    0x8(%ebp),%esi
f010306a:	8b 56 5c             	mov    0x5c(%esi),%edx
f010306d:	8b 14 ba             	mov    (%edx,%edi,4),%edx
f0103070:	f6 c2 01             	test   $0x1,%dl
f0103073:	75 13                	jne    f0103088 <user_mem_check+0x90>
      user_mem_check_addr = (va_beg2 > va_beg) ? va_beg2 : va_beg;
f0103075:	3b 45 0c             	cmp    0xc(%ebp),%eax
f0103078:	0f 42 45 0c          	cmovb  0xc(%ebp),%eax
f010307c:	a3 c0 e2 17 f0       	mov    %eax,0xf017e2c0
      return -E_FAULT;
f0103081:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0103086:	eb 6d                	jmp    f01030f5 <user_mem_check+0xfd>
    }

    // get current page table kernel va
    uint32_t* pt_kva = KADDR(PTE_ADDR(env->env_pgdir[PDX(va_beg2)]));
f0103088:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010308e:	89 d7                	mov    %edx,%edi
f0103090:	c1 ef 0c             	shr    $0xc,%edi
f0103093:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f0103096:	72 20                	jb     f01030b8 <user_mem_check+0xc0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103098:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010309c:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f01030a3:	f0 
f01030a4:	c7 44 24 04 a6 02 00 	movl   $0x2a6,0x4(%esp)
f01030ab:	00 
f01030ac:	c7 04 24 c3 5e 10 f0 	movl   $0xf0105ec3,(%esp)
f01030b3:	e8 fe cf ff ff       	call   f01000b6 <_panic>

    // check page is present & permissions
    if (!((pt_kva[PTX(va_beg2)] & perm) == perm)) {
f01030b8:	89 c7                	mov    %eax,%edi
f01030ba:	c1 ef 0c             	shr    $0xc,%edi
f01030bd:	81 e7 ff 03 00 00    	and    $0x3ff,%edi
f01030c3:	89 ce                	mov    %ecx,%esi
f01030c5:	23 b4 ba 00 00 00 f0 	and    -0x10000000(%edx,%edi,4),%esi
f01030cc:	39 f1                	cmp    %esi,%ecx
f01030ce:	74 13                	je     f01030e3 <user_mem_check+0xeb>
      user_mem_check_addr = (va_beg2 > va_beg) ? va_beg2 : va_beg;
f01030d0:	3b 45 0c             	cmp    0xc(%ebp),%eax
f01030d3:	0f 42 45 0c          	cmovb  0xc(%ebp),%eax
f01030d7:	a3 c0 e2 17 f0       	mov    %eax,0xf017e2c0
      return -E_FAULT;
f01030dc:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01030e1:	eb 12                	jmp    f01030f5 <user_mem_check+0xfd>
    }

    va_beg2 += PGSIZE;
f01030e3:	05 00 10 00 00       	add    $0x1000,%eax
  }

  // step 2 : check present & permission
  uintptr_t va_beg2 = ROUNDDOWN(va_beg, PGSIZE);
  uintptr_t va_end2 = ROUNDUP(va_end, PGSIZE);
  while (va_beg2 < va_end2) {
f01030e8:	39 d8                	cmp    %ebx,%eax
f01030ea:	0f 82 72 ff ff ff    	jb     f0103062 <user_mem_check+0x6a>
      return -E_FAULT;
    }

    va_beg2 += PGSIZE;
  }
  return 0;
f01030f0:	b8 00 00 00 00       	mov    $0x0,%eax

}
f01030f5:	83 c4 2c             	add    $0x2c,%esp
f01030f8:	5b                   	pop    %ebx
f01030f9:	5e                   	pop    %esi
f01030fa:	5f                   	pop    %edi
f01030fb:	5d                   	pop    %ebp
f01030fc:	c3                   	ret    

f01030fd <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f01030fd:	55                   	push   %ebp
f01030fe:	89 e5                	mov    %esp,%ebp
f0103100:	53                   	push   %ebx
f0103101:	83 ec 14             	sub    $0x14,%esp
f0103104:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0103107:	8b 45 14             	mov    0x14(%ebp),%eax
f010310a:	83 c8 04             	or     $0x4,%eax
f010310d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103111:	8b 45 10             	mov    0x10(%ebp),%eax
f0103114:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103118:	8b 45 0c             	mov    0xc(%ebp),%eax
f010311b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010311f:	89 1c 24             	mov    %ebx,(%esp)
f0103122:	e8 d1 fe ff ff       	call   f0102ff8 <user_mem_check>
f0103127:	85 c0                	test   %eax,%eax
f0103129:	79 24                	jns    f010314f <user_mem_assert+0x52>
		cprintf("[%08x] user_mem_check assertion failure for "
f010312b:	a1 c0 e2 17 f0       	mov    0xf017e2c0,%eax
f0103130:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103134:	8b 43 48             	mov    0x48(%ebx),%eax
f0103137:	89 44 24 04          	mov    %eax,0x4(%esp)
f010313b:	c7 04 24 80 5e 10 f0 	movl   $0xf0105e80,(%esp)
f0103142:	e8 c6 07 00 00       	call   f010390d <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0103147:	89 1c 24             	mov    %ebx,(%esp)
f010314a:	e8 8b 06 00 00       	call   f01037da <env_destroy>
	}
}
f010314f:	83 c4 14             	add    $0x14,%esp
f0103152:	5b                   	pop    %ebx
f0103153:	5d                   	pop    %ebp
f0103154:	c3                   	ret    

f0103155 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0103155:	55                   	push   %ebp
f0103156:	89 e5                	mov    %esp,%ebp
f0103158:	57                   	push   %edi
f0103159:	56                   	push   %esi
f010315a:	53                   	push   %ebx
f010315b:	83 ec 1c             	sub    $0x1c,%esp
f010315e:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
f0103160:	89 d3                	mov    %edx,%ebx
f0103162:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
f0103168:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f010316f:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	
	while (vaBegin<vaEnd){
f0103175:	eb 6d                	jmp    f01031e4 <region_alloc+0x8f>
		struct PageInfo *p = page_alloc(0);
f0103177:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010317e:	e8 ba dd ff ff       	call   f0100f3d <page_alloc>
		if (p == NULL)
f0103183:	85 c0                	test   %eax,%eax
f0103185:	75 1c                	jne    f01031a3 <region_alloc+0x4e>
			panic("Page alloc failed!");
f0103187:	c7 44 24 08 c6 61 10 	movl   $0xf01061c6,0x8(%esp)
f010318e:	f0 
f010318f:	c7 44 24 04 28 01 00 	movl   $0x128,0x4(%esp)
f0103196:	00 
f0103197:	c7 04 24 d9 61 10 f0 	movl   $0xf01061d9,(%esp)
f010319e:	e8 13 cf ff ff       	call   f01000b6 <_panic>
		else if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
f01031a3:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f01031aa:	00 
f01031ab:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01031af:	89 44 24 04          	mov    %eax,0x4(%esp)
f01031b3:	8b 47 5c             	mov    0x5c(%edi),%eax
f01031b6:	89 04 24             	mov    %eax,(%esp)
f01031b9:	e8 e4 e0 ff ff       	call   f01012a2 <page_insert>
f01031be:	85 c0                	test   %eax,%eax
f01031c0:	74 1c                	je     f01031de <region_alloc+0x89>
			panic("Page table couldn't be allocated!!");
f01031c2:	c7 44 24 08 48 62 10 	movl   $0xf0106248,0x8(%esp)
f01031c9:	f0 
f01031ca:	c7 44 24 04 2a 01 00 	movl   $0x12a,0x4(%esp)
f01031d1:	00 
f01031d2:	c7 04 24 d9 61 10 f0 	movl   $0xf01061d9,(%esp)
f01031d9:	e8 d8 ce ff ff       	call   f01000b6 <_panic>
		}
		vaBegin += PGSIZE;
f01031de:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
	
	while (vaBegin<vaEnd){
f01031e4:	39 f3                	cmp    %esi,%ebx
f01031e6:	72 8f                	jb     f0103177 <region_alloc+0x22>
		else if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
			panic("Page table couldn't be allocated!!");
		}
		vaBegin += PGSIZE;
	}
}
f01031e8:	83 c4 1c             	add    $0x1c,%esp
f01031eb:	5b                   	pop    %ebx
f01031ec:	5e                   	pop    %esi
f01031ed:	5f                   	pop    %edi
f01031ee:	5d                   	pop    %ebp
f01031ef:	c3                   	ret    

f01031f0 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f01031f0:	55                   	push   %ebp
f01031f1:	89 e5                	mov    %esp,%ebp
f01031f3:	8b 45 08             	mov    0x8(%ebp),%eax
f01031f6:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f01031f9:	85 c0                	test   %eax,%eax
f01031fb:	75 11                	jne    f010320e <envid2env+0x1e>
		*env_store = curenv;
f01031fd:	a1 cc e2 17 f0       	mov    0xf017e2cc,%eax
f0103202:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103205:	89 01                	mov    %eax,(%ecx)
		return 0;
f0103207:	b8 00 00 00 00       	mov    $0x0,%eax
f010320c:	eb 5e                	jmp    f010326c <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f010320e:	89 c2                	mov    %eax,%edx
f0103210:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0103216:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103219:	c1 e2 05             	shl    $0x5,%edx
f010321c:	03 15 d0 e2 17 f0    	add    0xf017e2d0,%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103222:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f0103226:	74 05                	je     f010322d <envid2env+0x3d>
f0103228:	39 42 48             	cmp    %eax,0x48(%edx)
f010322b:	74 10                	je     f010323d <envid2env+0x4d>
		*env_store = 0;
f010322d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103230:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103236:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010323b:	eb 2f                	jmp    f010326c <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f010323d:	84 c9                	test   %cl,%cl
f010323f:	74 21                	je     f0103262 <envid2env+0x72>
f0103241:	a1 cc e2 17 f0       	mov    0xf017e2cc,%eax
f0103246:	39 c2                	cmp    %eax,%edx
f0103248:	74 18                	je     f0103262 <envid2env+0x72>
f010324a:	8b 40 48             	mov    0x48(%eax),%eax
f010324d:	39 42 4c             	cmp    %eax,0x4c(%edx)
f0103250:	74 10                	je     f0103262 <envid2env+0x72>
		*env_store = 0;
f0103252:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103255:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010325b:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103260:	eb 0a                	jmp    f010326c <envid2env+0x7c>
	}

	*env_store = e;
f0103262:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103265:	89 10                	mov    %edx,(%eax)
	return 0;
f0103267:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010326c:	5d                   	pop    %ebp
f010326d:	c3                   	ret    

f010326e <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f010326e:	55                   	push   %ebp
f010326f:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0103271:	b8 00 c3 11 f0       	mov    $0xf011c300,%eax
f0103276:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0103279:	b8 23 00 00 00       	mov    $0x23,%eax
f010327e:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0103280:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0103282:	b0 10                	mov    $0x10,%al
f0103284:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0103286:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0103288:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f010328a:	ea 91 32 10 f0 08 00 	ljmp   $0x8,$0xf0103291
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0103291:	b0 00                	mov    $0x0,%al
f0103293:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0103296:	5d                   	pop    %ebp
f0103297:	c3                   	ret    

f0103298 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0103298:	8b 0d d4 e2 17 f0    	mov    0xf017e2d4,%ecx
f010329e:	a1 d0 e2 17 f0       	mov    0xf017e2d0,%eax
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
f01032a3:	ba 00 04 00 00       	mov    $0x400,%edx
f01032a8:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = NULL;
f01032af:	c7 40 44 00 00 00 00 	movl   $0x0,0x44(%eax)

		if (!env_free_list){		
f01032b6:	85 c9                	test   %ecx,%ecx
f01032b8:	74 05                	je     f01032bf <env_init+0x27>
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
		}
		else{
		envs[i-1].env_link = &envs[i];
f01032ba:	89 40 e4             	mov    %eax,-0x1c(%eax)
f01032bd:	eb 02                	jmp    f01032c1 <env_init+0x29>
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
		envs[i].env_link = NULL;

		if (!env_free_list){		
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
f01032bf:	89 c1                	mov    %eax,%ecx
f01032c1:	83 c0 60             	add    $0x60,%eax
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
f01032c4:	83 ea 01             	sub    $0x1,%edx
f01032c7:	75 df                	jne    f01032a8 <env_init+0x10>
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01032c9:	55                   	push   %ebp
f01032ca:	89 e5                	mov    %esp,%ebp
f01032cc:	89 0d d4 e2 17 f0    	mov    %ecx,0xf017e2d4
		}	//Previous env is linked to this current env
	}
	

	// Per-CPU part of the initialization
	env_init_percpu();
f01032d2:	e8 97 ff ff ff       	call   f010326e <env_init_percpu>
}
f01032d7:	5d                   	pop    %ebp
f01032d8:	c3                   	ret    

f01032d9 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01032d9:	55                   	push   %ebp
f01032da:	89 e5                	mov    %esp,%ebp
f01032dc:	53                   	push   %ebx
f01032dd:	83 ec 14             	sub    $0x14,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f01032e0:	8b 1d d4 e2 17 f0    	mov    0xf017e2d4,%ebx
f01032e6:	85 db                	test   %ebx,%ebx
f01032e8:	0f 84 6c 01 00 00    	je     f010345a <env_alloc+0x181>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f01032ee:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01032f5:	e8 43 dc ff ff       	call   f0100f3d <page_alloc>
f01032fa:	85 c0                	test   %eax,%eax
f01032fc:	0f 84 5f 01 00 00    	je     f0103461 <env_alloc+0x188>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f0103302:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0103307:	2b 05 8c ef 17 f0    	sub    0xf017ef8c,%eax
f010330d:	c1 f8 03             	sar    $0x3,%eax
f0103310:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103313:	89 c2                	mov    %eax,%edx
f0103315:	c1 ea 0c             	shr    $0xc,%edx
f0103318:	3b 15 84 ef 17 f0    	cmp    0xf017ef84,%edx
f010331e:	72 20                	jb     f0103340 <env_alloc+0x67>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103320:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103324:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f010332b:	f0 
f010332c:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0103333:	00 
f0103334:	c7 04 24 b5 5e 10 f0 	movl   $0xf0105eb5,(%esp)
f010333b:	e8 76 cd ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0103340:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103345:	89 43 5c             	mov    %eax,0x5c(%ebx)
	e->env_pgdir = (pde_t*)page2kva(p);
f0103348:	b8 00 00 00 00       	mov    $0x0,%eax

	for (i = 0; i < NPDENTRIES; ++i) {
		e->env_pgdir[i] = kern_pgdir[i];  //Mapping all 1024 entries of the kernel
f010334d:	8b 15 88 ef 17 f0    	mov    0xf017ef88,%edx
f0103353:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f0103356:	8b 53 5c             	mov    0x5c(%ebx),%edx
f0103359:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f010335c:	83 c0 04             	add    $0x4,%eax

	// LAB 3: Your code here.
	p->pp_ref++;
	e->env_pgdir = (pde_t*)page2kva(p);

	for (i = 0; i < NPDENTRIES; ++i) {
f010335f:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0103364:	75 e7                	jne    f010334d <env_alloc+0x74>
						 //pgdir to the environment pgdir
	}
	
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0103366:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103369:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010336e:	77 20                	ja     f0103390 <env_alloc+0xb7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103370:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103374:	c7 44 24 08 28 56 10 	movl   $0xf0105628,0x8(%esp)
f010337b:	f0 
f010337c:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
f0103383:	00 
f0103384:	c7 04 24 d9 61 10 f0 	movl   $0xf01061d9,(%esp)
f010338b:	e8 26 cd ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103390:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0103396:	83 ca 05             	or     $0x5,%edx
f0103399:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f010339f:	8b 43 48             	mov    0x48(%ebx),%eax
f01033a2:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01033a7:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01033ac:	ba 00 10 00 00       	mov    $0x1000,%edx
f01033b1:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01033b4:	89 da                	mov    %ebx,%edx
f01033b6:	2b 15 d0 e2 17 f0    	sub    0xf017e2d0,%edx
f01033bc:	c1 fa 05             	sar    $0x5,%edx
f01033bf:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01033c5:	09 d0                	or     %edx,%eax
f01033c7:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f01033ca:	8b 45 0c             	mov    0xc(%ebp),%eax
f01033cd:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f01033d0:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01033d7:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f01033de:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01033e5:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f01033ec:	00 
f01033ed:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01033f4:	00 
f01033f5:	89 1c 24             	mov    %ebx,(%esp)
f01033f8:	e8 3a 18 00 00       	call   f0104c37 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f01033fd:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103403:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103409:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f010340f:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0103416:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f010341c:	8b 43 44             	mov    0x44(%ebx),%eax
f010341f:	a3 d4 e2 17 f0       	mov    %eax,0xf017e2d4
	*newenv_store = e;
f0103424:	8b 45 08             	mov    0x8(%ebp),%eax
f0103427:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103429:	8b 53 48             	mov    0x48(%ebx),%edx
f010342c:	a1 cc e2 17 f0       	mov    0xf017e2cc,%eax
f0103431:	85 c0                	test   %eax,%eax
f0103433:	74 05                	je     f010343a <env_alloc+0x161>
f0103435:	8b 40 48             	mov    0x48(%eax),%eax
f0103438:	eb 05                	jmp    f010343f <env_alloc+0x166>
f010343a:	b8 00 00 00 00       	mov    $0x0,%eax
f010343f:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103443:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103447:	c7 04 24 e4 61 10 f0 	movl   $0xf01061e4,(%esp)
f010344e:	e8 ba 04 00 00       	call   f010390d <cprintf>
	return 0;
f0103453:	b8 00 00 00 00       	mov    $0x0,%eax
f0103458:	eb 0c                	jmp    f0103466 <env_alloc+0x18d>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f010345a:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f010345f:	eb 05                	jmp    f0103466 <env_alloc+0x18d>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0103461:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0103466:	83 c4 14             	add    $0x14,%esp
f0103469:	5b                   	pop    %ebx
f010346a:	5d                   	pop    %ebp
f010346b:	c3                   	ret    

f010346c <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f010346c:	55                   	push   %ebp
f010346d:	89 e5                	mov    %esp,%ebp
f010346f:	57                   	push   %edi
f0103470:	56                   	push   %esi
f0103471:	53                   	push   %ebx
f0103472:	83 ec 3c             	sub    $0x3c,%esp
f0103475:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	int r;
	struct Env *env;
	r = env_alloc( &env, 0);
f0103478:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010347f:	00 
f0103480:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103483:	89 04 24             	mov    %eax,(%esp)
f0103486:	e8 4e fe ff ff       	call   f01032d9 <env_alloc>
	if (r){
f010348b:	85 c0                	test   %eax,%eax
f010348d:	74 20                	je     f01034af <env_create+0x43>
	panic("env_alloc: %e", r);
f010348f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103493:	c7 44 24 08 f9 61 10 	movl   $0xf01061f9,0x8(%esp)
f010349a:	f0 
f010349b:	c7 44 24 04 a5 01 00 	movl   $0x1a5,0x4(%esp)
f01034a2:	00 
f01034a3:	c7 04 24 d9 61 10 f0 	movl   $0xf01061d9,(%esp)
f01034aa:	e8 07 cc ff ff       	call   f01000b6 <_panic>
	}
	
	load_icode(env,binary);
f01034af:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01034b2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Get the beginning and end of program header table
	//Details of struct proghdr are in /lab/inc/elf.h

	// is this a valid ELF?
	
	if (((struct Elf*)binary)->e_magic != ELF_MAGIC)
f01034b5:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f01034bb:	74 1c                	je     f01034d9 <env_create+0x6d>
	{
		panic ("Not a valid ELF binary image");
f01034bd:	c7 44 24 08 07 62 10 	movl   $0xf0106207,0x8(%esp)
f01034c4:	f0 
f01034c5:	c7 44 24 04 74 01 00 	movl   $0x174,0x4(%esp)
f01034cc:	00 
f01034cd:	c7 04 24 d9 61 10 f0 	movl   $0xf01061d9,(%esp)
f01034d4:	e8 dd cb ff ff       	call   f01000b6 <_panic>
	}

	struct Proghdr *ph =(struct Proghdr *)(binary + ((struct Elf*)binary)->e_phoff); //phoff is the offset
f01034d9:	89 fb                	mov    %edi,%ebx
f01034db:	03 5f 1c             	add    0x1c(%edi),%ebx
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
f01034de:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f01034e2:	c1 e6 05             	shl    $0x5,%esi
f01034e5:	01 de                	add    %ebx,%esi
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));
f01034e7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01034ea:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01034ed:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01034f2:	77 20                	ja     f0103514 <env_create+0xa8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034f4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01034f8:	c7 44 24 08 28 56 10 	movl   $0xf0105628,0x8(%esp)
f01034ff:	f0 
f0103500:	c7 44 24 04 7b 01 00 	movl   $0x17b,0x4(%esp)
f0103507:	00 
f0103508:	c7 04 24 d9 61 10 f0 	movl   $0xf01061d9,(%esp)
f010350f:	e8 a2 cb ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103514:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0103519:	0f 22 d8             	mov    %eax,%cr3
f010351c:	eb 71                	jmp    f010358f <env_create+0x123>

	for (;ph<phEnd;++ph){
		if (ph->p_type == ELF_PROG_LOAD){	//Check whether the type is ELF_PROG_LOAD
f010351e:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103521:	75 69                	jne    f010358c <env_create+0x120>
		
		if(ph->p_memsz < ph->p_filesz){
f0103523:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103526:	3b 4b 10             	cmp    0x10(%ebx),%ecx
f0103529:	73 1c                	jae    f0103547 <env_create+0xdb>
		panic ("Memory size is smaller than file size!!");
f010352b:	c7 44 24 08 6c 62 10 	movl   $0xf010626c,0x8(%esp)
f0103532:	f0 
f0103533:	c7 44 24 04 81 01 00 	movl   $0x181,0x4(%esp)
f010353a:	00 
f010353b:	c7 04 24 d9 61 10 f0 	movl   $0xf01061d9,(%esp)
f0103542:	e8 6f cb ff ff       	call   f01000b6 <_panic>
		}
		region_alloc(e, (void *)ph->p_va, ph->p_memsz);  //Allocate region per segment
f0103547:	8b 53 08             	mov    0x8(%ebx),%edx
f010354a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010354d:	e8 03 fc ff ff       	call   f0103155 <region_alloc>
	

		memcpy((void*)ph->p_va, (void*)(binary + ph->p_offset), ph->p_filesz); //Load Binary into memory
f0103552:	8b 43 10             	mov    0x10(%ebx),%eax
f0103555:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103559:	89 f8                	mov    %edi,%eax
f010355b:	03 43 04             	add    0x4(%ebx),%eax
f010355e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103562:	8b 43 08             	mov    0x8(%ebx),%eax
f0103565:	89 04 24             	mov    %eax,(%esp)
f0103568:	e8 7f 17 00 00       	call   f0104cec <memcpy>

		memset((void*)(ph->p_va + ph->p_filesz),0,ph->p_memsz-ph->p_filesz);  //Clear the rest of the memory, i.e the bss segment
f010356d:	8b 43 10             	mov    0x10(%ebx),%eax
f0103570:	8b 53 14             	mov    0x14(%ebx),%edx
f0103573:	29 c2                	sub    %eax,%edx
f0103575:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103579:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103580:	00 
f0103581:	03 43 08             	add    0x8(%ebx),%eax
f0103584:	89 04 24             	mov    %eax,(%esp)
f0103587:	e8 ab 16 00 00       	call   f0104c37 <memset>
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));

	for (;ph<phEnd;++ph){
f010358c:	83 c3 20             	add    $0x20,%ebx
f010358f:	39 de                	cmp    %ebx,%esi
f0103591:	77 8b                	ja     f010351e <env_create+0xb2>
		}
		else{
			continue;
		}
	}
	lcr3(PADDR(kern_pgdir));   //Switch back to Kernel page directory
f0103593:	a1 88 ef 17 f0       	mov    0xf017ef88,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103598:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010359d:	77 20                	ja     f01035bf <env_create+0x153>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010359f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01035a3:	c7 44 24 08 28 56 10 	movl   $0xf0105628,0x8(%esp)
f01035aa:	f0 
f01035ab:	c7 44 24 04 8e 01 00 	movl   $0x18e,0x4(%esp)
f01035b2:	00 
f01035b3:	c7 04 24 d9 61 10 f0 	movl   $0xf01061d9,(%esp)
f01035ba:	e8 f7 ca ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01035bf:	05 00 00 00 10       	add    $0x10000000,%eax
f01035c4:	0f 22 d8             	mov    %eax,%cr3
	
	e->env_tf.tf_eip = ((struct Elf*)binary)->e_entry;   //Define the entry point of the env from the ELF binary entry point
f01035c7:	8b 47 18             	mov    0x18(%edi),%eax
f01035ca:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01035cd:	89 47 30             	mov    %eax,0x30(%edi)

	region_alloc(e,(void *)USTACKTOP - PGSIZE, PGSIZE);
f01035d0:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01035d5:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01035da:	89 f8                	mov    %edi,%eax
f01035dc:	e8 74 fb ff ff       	call   f0103155 <region_alloc>
	if (r){
	panic("env_alloc: %e", r);
	}
	
	load_icode(env,binary);
	env->env_type = type;
f01035e1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01035e4:	8b 55 0c             	mov    0xc(%ebp),%edx
f01035e7:	89 50 50             	mov    %edx,0x50(%eax)
}
f01035ea:	83 c4 3c             	add    $0x3c,%esp
f01035ed:	5b                   	pop    %ebx
f01035ee:	5e                   	pop    %esi
f01035ef:	5f                   	pop    %edi
f01035f0:	5d                   	pop    %ebp
f01035f1:	c3                   	ret    

f01035f2 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01035f2:	55                   	push   %ebp
f01035f3:	89 e5                	mov    %esp,%ebp
f01035f5:	57                   	push   %edi
f01035f6:	56                   	push   %esi
f01035f7:	53                   	push   %ebx
f01035f8:	83 ec 2c             	sub    $0x2c,%esp
f01035fb:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01035fe:	a1 cc e2 17 f0       	mov    0xf017e2cc,%eax
f0103603:	39 c7                	cmp    %eax,%edi
f0103605:	75 37                	jne    f010363e <env_free+0x4c>
		lcr3(PADDR(kern_pgdir));
f0103607:	8b 15 88 ef 17 f0    	mov    0xf017ef88,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010360d:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103613:	77 20                	ja     f0103635 <env_free+0x43>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103615:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103619:	c7 44 24 08 28 56 10 	movl   $0xf0105628,0x8(%esp)
f0103620:	f0 
f0103621:	c7 44 24 04 bb 01 00 	movl   $0x1bb,0x4(%esp)
f0103628:	00 
f0103629:	c7 04 24 d9 61 10 f0 	movl   $0xf01061d9,(%esp)
f0103630:	e8 81 ca ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103635:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f010363b:	0f 22 da             	mov    %edx,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f010363e:	8b 57 48             	mov    0x48(%edi),%edx
f0103641:	85 c0                	test   %eax,%eax
f0103643:	74 05                	je     f010364a <env_free+0x58>
f0103645:	8b 40 48             	mov    0x48(%eax),%eax
f0103648:	eb 05                	jmp    f010364f <env_free+0x5d>
f010364a:	b8 00 00 00 00       	mov    $0x0,%eax
f010364f:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103653:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103657:	c7 04 24 24 62 10 f0 	movl   $0xf0106224,(%esp)
f010365e:	e8 aa 02 00 00       	call   f010390d <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103663:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f010366a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010366d:	89 c8                	mov    %ecx,%eax
f010366f:	c1 e0 02             	shl    $0x2,%eax
f0103672:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103675:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103678:	8b 34 88             	mov    (%eax,%ecx,4),%esi
f010367b:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103681:	0f 84 b7 00 00 00    	je     f010373e <env_free+0x14c>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103687:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010368d:	89 f0                	mov    %esi,%eax
f010368f:	c1 e8 0c             	shr    $0xc,%eax
f0103692:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103695:	3b 05 84 ef 17 f0    	cmp    0xf017ef84,%eax
f010369b:	72 20                	jb     f01036bd <env_free+0xcb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010369d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01036a1:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f01036a8:	f0 
f01036a9:	c7 44 24 04 ca 01 00 	movl   $0x1ca,0x4(%esp)
f01036b0:	00 
f01036b1:	c7 04 24 d9 61 10 f0 	movl   $0xf01061d9,(%esp)
f01036b8:	e8 f9 c9 ff ff       	call   f01000b6 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01036bd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01036c0:	c1 e0 16             	shl    $0x16,%eax
f01036c3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01036c6:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f01036cb:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f01036d2:	01 
f01036d3:	74 17                	je     f01036ec <env_free+0xfa>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01036d5:	89 d8                	mov    %ebx,%eax
f01036d7:	c1 e0 0c             	shl    $0xc,%eax
f01036da:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01036dd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036e1:	8b 47 5c             	mov    0x5c(%edi),%eax
f01036e4:	89 04 24             	mov    %eax,(%esp)
f01036e7:	e8 78 db ff ff       	call   f0101264 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01036ec:	83 c3 01             	add    $0x1,%ebx
f01036ef:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01036f5:	75 d4                	jne    f01036cb <env_free+0xd9>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01036f7:	8b 47 5c             	mov    0x5c(%edi),%eax
f01036fa:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01036fd:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103704:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103707:	3b 05 84 ef 17 f0    	cmp    0xf017ef84,%eax
f010370d:	72 1c                	jb     f010372b <env_free+0x139>
		panic("pa2page called with invalid pa");
f010370f:	c7 44 24 08 94 62 10 	movl   $0xf0106294,0x8(%esp)
f0103716:	f0 
f0103717:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f010371e:	00 
f010371f:	c7 04 24 b5 5e 10 f0 	movl   $0xf0105eb5,(%esp)
f0103726:	e8 8b c9 ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f010372b:	a1 8c ef 17 f0       	mov    0xf017ef8c,%eax
f0103730:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103733:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		page_decref(pa2page(pa));
f0103736:	89 04 24             	mov    %eax,(%esp)
f0103739:	e8 eb d8 ff ff       	call   f0101029 <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f010373e:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103742:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f0103749:	0f 85 1b ff ff ff    	jne    f010366a <env_free+0x78>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f010374f:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103752:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103757:	77 20                	ja     f0103779 <env_free+0x187>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103759:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010375d:	c7 44 24 08 28 56 10 	movl   $0xf0105628,0x8(%esp)
f0103764:	f0 
f0103765:	c7 44 24 04 d8 01 00 	movl   $0x1d8,0x4(%esp)
f010376c:	00 
f010376d:	c7 04 24 d9 61 10 f0 	movl   $0xf01061d9,(%esp)
f0103774:	e8 3d c9 ff ff       	call   f01000b6 <_panic>
	e->env_pgdir = 0;
f0103779:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103780:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103785:	c1 e8 0c             	shr    $0xc,%eax
f0103788:	3b 05 84 ef 17 f0    	cmp    0xf017ef84,%eax
f010378e:	72 1c                	jb     f01037ac <env_free+0x1ba>
		panic("pa2page called with invalid pa");
f0103790:	c7 44 24 08 94 62 10 	movl   $0xf0106294,0x8(%esp)
f0103797:	f0 
f0103798:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f010379f:	00 
f01037a0:	c7 04 24 b5 5e 10 f0 	movl   $0xf0105eb5,(%esp)
f01037a7:	e8 0a c9 ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f01037ac:	8b 15 8c ef 17 f0    	mov    0xf017ef8c,%edx
f01037b2:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	page_decref(pa2page(pa));
f01037b5:	89 04 24             	mov    %eax,(%esp)
f01037b8:	e8 6c d8 ff ff       	call   f0101029 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f01037bd:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f01037c4:	a1 d4 e2 17 f0       	mov    0xf017e2d4,%eax
f01037c9:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f01037cc:	89 3d d4 e2 17 f0    	mov    %edi,0xf017e2d4
}
f01037d2:	83 c4 2c             	add    $0x2c,%esp
f01037d5:	5b                   	pop    %ebx
f01037d6:	5e                   	pop    %esi
f01037d7:	5f                   	pop    %edi
f01037d8:	5d                   	pop    %ebp
f01037d9:	c3                   	ret    

f01037da <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f01037da:	55                   	push   %ebp
f01037db:	89 e5                	mov    %esp,%ebp
f01037dd:	83 ec 18             	sub    $0x18,%esp
	env_free(e);
f01037e0:	8b 45 08             	mov    0x8(%ebp),%eax
f01037e3:	89 04 24             	mov    %eax,(%esp)
f01037e6:	e8 07 fe ff ff       	call   f01035f2 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f01037eb:	c7 04 24 b4 62 10 f0 	movl   $0xf01062b4,(%esp)
f01037f2:	e8 16 01 00 00       	call   f010390d <cprintf>
	while (1)
		monitor(NULL);
f01037f7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01037fe:	e8 02 d0 ff ff       	call   f0100805 <monitor>
f0103803:	eb f2                	jmp    f01037f7 <env_destroy+0x1d>

f0103805 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103805:	55                   	push   %ebp
f0103806:	89 e5                	mov    %esp,%ebp
f0103808:	83 ec 18             	sub    $0x18,%esp
	__asm __volatile("movl %0,%%esp\n"
f010380b:	8b 65 08             	mov    0x8(%ebp),%esp
f010380e:	61                   	popa   
f010380f:	07                   	pop    %es
f0103810:	1f                   	pop    %ds
f0103811:	83 c4 08             	add    $0x8,%esp
f0103814:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103815:	c7 44 24 08 3a 62 10 	movl   $0xf010623a,0x8(%esp)
f010381c:	f0 
f010381d:	c7 44 24 04 00 02 00 	movl   $0x200,0x4(%esp)
f0103824:	00 
f0103825:	c7 04 24 d9 61 10 f0 	movl   $0xf01061d9,(%esp)
f010382c:	e8 85 c8 ff ff       	call   f01000b6 <_panic>

f0103831 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103831:	55                   	push   %ebp
f0103832:	89 e5                	mov    %esp,%ebp
f0103834:	83 ec 18             	sub    $0x18,%esp
f0103837:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	//check if this is the first call to env_run
	if (curenv == NULL){
f010383a:	8b 15 cc e2 17 f0    	mov    0xf017e2cc,%edx
f0103840:	85 d2                	test   %edx,%edx
f0103842:	74 0d                	je     f0103851 <env_run+0x20>
	curenv = e;
	}
	
	//If curenv state is running mode , set it to runnable 
	else if (curenv->env_status == ENV_RUNNING){
f0103844:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0103848:	75 07                	jne    f0103851 <env_run+0x20>
	 curenv->env_status = ENV_RUNNABLE;
f010384a:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
	}
	curenv = e;	//Set the current environment to the new env
f0103851:	a3 cc e2 17 f0       	mov    %eax,0xf017e2cc
	curenv->env_status = ENV_RUNNING; //Set it to running state
f0103856:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;	// Increment the env_runs counter
f010385d:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(e->env_pgdir));	//Use lcr3 to switch to the env directory
f0103861:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103864:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f010386a:	77 20                	ja     f010388c <env_run+0x5b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010386c:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103870:	c7 44 24 08 28 56 10 	movl   $0xf0105628,0x8(%esp)
f0103877:	f0 
f0103878:	c7 44 24 04 2b 02 00 	movl   $0x22b,0x4(%esp)
f010387f:	00 
f0103880:	c7 04 24 d9 61 10 f0 	movl   $0xf01061d9,(%esp)
f0103887:	e8 2a c8 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010388c:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0103892:	0f 22 da             	mov    %edx,%cr3

	env_pop_tf(&e->env_tf);
f0103895:	89 04 24             	mov    %eax,(%esp)
f0103898:	e8 68 ff ff ff       	call   f0103805 <env_pop_tf>

f010389d <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010389d:	55                   	push   %ebp
f010389e:	89 e5                	mov    %esp,%ebp
f01038a0:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01038a4:	ba 70 00 00 00       	mov    $0x70,%edx
f01038a9:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01038aa:	b2 71                	mov    $0x71,%dl
f01038ac:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01038ad:	0f b6 c0             	movzbl %al,%eax
}
f01038b0:	5d                   	pop    %ebp
f01038b1:	c3                   	ret    

f01038b2 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01038b2:	55                   	push   %ebp
f01038b3:	89 e5                	mov    %esp,%ebp
f01038b5:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01038b9:	ba 70 00 00 00       	mov    $0x70,%edx
f01038be:	ee                   	out    %al,(%dx)
f01038bf:	b2 71                	mov    $0x71,%dl
f01038c1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01038c4:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01038c5:	5d                   	pop    %ebp
f01038c6:	c3                   	ret    

f01038c7 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01038c7:	55                   	push   %ebp
f01038c8:	89 e5                	mov    %esp,%ebp
f01038ca:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01038cd:	8b 45 08             	mov    0x8(%ebp),%eax
f01038d0:	89 04 24             	mov    %eax,(%esp)
f01038d3:	e8 39 cd ff ff       	call   f0100611 <cputchar>
	*cnt++;
}
f01038d8:	c9                   	leave  
f01038d9:	c3                   	ret    

f01038da <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01038da:	55                   	push   %ebp
f01038db:	89 e5                	mov    %esp,%ebp
f01038dd:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01038e0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01038e7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01038ea:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01038ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01038f1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01038f5:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01038f8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038fc:	c7 04 24 c7 38 10 f0 	movl   $0xf01038c7,(%esp)
f0103903:	e8 76 0c 00 00       	call   f010457e <vprintfmt>
	return cnt;
}
f0103908:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010390b:	c9                   	leave  
f010390c:	c3                   	ret    

f010390d <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010390d:	55                   	push   %ebp
f010390e:	89 e5                	mov    %esp,%ebp
f0103910:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103913:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103916:	89 44 24 04          	mov    %eax,0x4(%esp)
f010391a:	8b 45 08             	mov    0x8(%ebp),%eax
f010391d:	89 04 24             	mov    %eax,(%esp)
f0103920:	e8 b5 ff ff ff       	call   f01038da <vcprintf>
	va_end(ap);

	return cnt;
}
f0103925:	c9                   	leave  
f0103926:	c3                   	ret    
f0103927:	66 90                	xchg   %ax,%ax
f0103929:	66 90                	xchg   %ax,%ax
f010392b:	66 90                	xchg   %ax,%ax
f010392d:	66 90                	xchg   %ax,%ax
f010392f:	90                   	nop

f0103930 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103930:	55                   	push   %ebp
f0103931:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103933:	c7 05 04 eb 17 f0 00 	movl   $0xf0000000,0xf017eb04
f010393a:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f010393d:	66 c7 05 08 eb 17 f0 	movw   $0x10,0xf017eb08
f0103944:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0103946:	66 c7 05 48 c3 11 f0 	movw   $0x67,0xf011c348
f010394d:	67 00 
f010394f:	b8 00 eb 17 f0       	mov    $0xf017eb00,%eax
f0103954:	66 a3 4a c3 11 f0    	mov    %ax,0xf011c34a
f010395a:	89 c2                	mov    %eax,%edx
f010395c:	c1 ea 10             	shr    $0x10,%edx
f010395f:	88 15 4c c3 11 f0    	mov    %dl,0xf011c34c
f0103965:	c6 05 4e c3 11 f0 40 	movb   $0x40,0xf011c34e
f010396c:	c1 e8 18             	shr    $0x18,%eax
f010396f:	a2 4f c3 11 f0       	mov    %al,0xf011c34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103974:	c6 05 4d c3 11 f0 89 	movb   $0x89,0xf011c34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f010397b:	b8 28 00 00 00       	mov    $0x28,%eax
f0103980:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0103983:	b8 50 c3 11 f0       	mov    $0xf011c350,%eax
f0103988:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f010398b:	5d                   	pop    %ebp
f010398c:	c3                   	ret    

f010398d <trap_init>:
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i; 
	for (i=0; i<= T_SIMDERR;i++){
f010398d:	b8 00 00 00 00       	mov    $0x0,%eax
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
f0103992:	8b 14 85 56 c3 11 f0 	mov    -0xfee3caa(,%eax,4),%edx
f0103999:	66 89 14 c5 e0 e2 17 	mov    %dx,-0xfe81d20(,%eax,8)
f01039a0:	f0 
f01039a1:	66 c7 04 c5 e2 e2 17 	movw   $0x8,-0xfe81d1e(,%eax,8)
f01039a8:	f0 08 00 
f01039ab:	c6 04 c5 e4 e2 17 f0 	movb   $0x0,-0xfe81d1c(,%eax,8)
f01039b2:	00 
f01039b3:	c6 04 c5 e5 e2 17 f0 	movb   $0x8e,-0xfe81d1b(,%eax,8)
f01039ba:	8e 
f01039bb:	c1 ea 10             	shr    $0x10,%edx
f01039be:	66 89 14 c5 e6 e2 17 	mov    %dx,-0xfe81d1a(,%eax,8)
f01039c5:	f0 
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i; 
	for (i=0; i<= T_SIMDERR;i++){
f01039c6:	83 c0 01             	add    $0x1,%eax
f01039c9:	83 f8 14             	cmp    $0x14,%eax
f01039cc:	75 c4                	jne    f0103992 <trap_init+0x5>
}


void
trap_init(void)
{
f01039ce:	55                   	push   %ebp
f01039cf:	89 e5                	mov    %esp,%ebp
	for (i=0; i<= T_SIMDERR;i++){
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
	}

	//Interrupt 3 is a soft interrupt generated by user, hence the dpl of the gate will be checked with 3
  	SETGATE(idt[3],0,GD_KT,int_vector_table[3],3);
f01039d1:	a1 62 c3 11 f0       	mov    0xf011c362,%eax
f01039d6:	66 a3 f8 e2 17 f0    	mov    %ax,0xf017e2f8
f01039dc:	66 c7 05 fa e2 17 f0 	movw   $0x8,0xf017e2fa
f01039e3:	08 00 
f01039e5:	c6 05 fc e2 17 f0 00 	movb   $0x0,0xf017e2fc
f01039ec:	c6 05 fd e2 17 f0 ee 	movb   $0xee,0xf017e2fd
f01039f3:	c1 e8 10             	shr    $0x10,%eax
f01039f6:	66 a3 fe e2 17 f0    	mov    %ax,0xf017e2fe

	//similarly system call is setup by the user and hence the gate should be checked with 3 
	SETGATE(idt[T_SYSCALL], 0, GD_KT, int_vector_table[T_SYSCALL], 3);// T_SYSCALL = 3
f01039fc:	a1 16 c4 11 f0       	mov    0xf011c416,%eax
f0103a01:	66 a3 60 e4 17 f0    	mov    %ax,0xf017e460
f0103a07:	66 c7 05 62 e4 17 f0 	movw   $0x8,0xf017e462
f0103a0e:	08 00 
f0103a10:	c6 05 64 e4 17 f0 00 	movb   $0x0,0xf017e464
f0103a17:	c6 05 65 e4 17 f0 ee 	movb   $0xee,0xf017e465
f0103a1e:	c1 e8 10             	shr    $0x10,%eax
f0103a21:	66 a3 66 e4 17 f0    	mov    %ax,0xf017e466

	// Per-CPU setup 
	trap_init_percpu();
f0103a27:	e8 04 ff ff ff       	call   f0103930 <trap_init_percpu>
}
f0103a2c:	5d                   	pop    %ebp
f0103a2d:	c3                   	ret    

f0103a2e <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103a2e:	55                   	push   %ebp
f0103a2f:	89 e5                	mov    %esp,%ebp
f0103a31:	53                   	push   %ebx
f0103a32:	83 ec 14             	sub    $0x14,%esp
f0103a35:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103a38:	8b 03                	mov    (%ebx),%eax
f0103a3a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a3e:	c7 04 24 ea 62 10 f0 	movl   $0xf01062ea,(%esp)
f0103a45:	e8 c3 fe ff ff       	call   f010390d <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103a4a:	8b 43 04             	mov    0x4(%ebx),%eax
f0103a4d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a51:	c7 04 24 f9 62 10 f0 	movl   $0xf01062f9,(%esp)
f0103a58:	e8 b0 fe ff ff       	call   f010390d <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103a5d:	8b 43 08             	mov    0x8(%ebx),%eax
f0103a60:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a64:	c7 04 24 08 63 10 f0 	movl   $0xf0106308,(%esp)
f0103a6b:	e8 9d fe ff ff       	call   f010390d <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103a70:	8b 43 0c             	mov    0xc(%ebx),%eax
f0103a73:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a77:	c7 04 24 17 63 10 f0 	movl   $0xf0106317,(%esp)
f0103a7e:	e8 8a fe ff ff       	call   f010390d <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103a83:	8b 43 10             	mov    0x10(%ebx),%eax
f0103a86:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a8a:	c7 04 24 26 63 10 f0 	movl   $0xf0106326,(%esp)
f0103a91:	e8 77 fe ff ff       	call   f010390d <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103a96:	8b 43 14             	mov    0x14(%ebx),%eax
f0103a99:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a9d:	c7 04 24 35 63 10 f0 	movl   $0xf0106335,(%esp)
f0103aa4:	e8 64 fe ff ff       	call   f010390d <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103aa9:	8b 43 18             	mov    0x18(%ebx),%eax
f0103aac:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ab0:	c7 04 24 44 63 10 f0 	movl   $0xf0106344,(%esp)
f0103ab7:	e8 51 fe ff ff       	call   f010390d <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103abc:	8b 43 1c             	mov    0x1c(%ebx),%eax
f0103abf:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ac3:	c7 04 24 53 63 10 f0 	movl   $0xf0106353,(%esp)
f0103aca:	e8 3e fe ff ff       	call   f010390d <cprintf>
}
f0103acf:	83 c4 14             	add    $0x14,%esp
f0103ad2:	5b                   	pop    %ebx
f0103ad3:	5d                   	pop    %ebp
f0103ad4:	c3                   	ret    

f0103ad5 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103ad5:	55                   	push   %ebp
f0103ad6:	89 e5                	mov    %esp,%ebp
f0103ad8:	56                   	push   %esi
f0103ad9:	53                   	push   %ebx
f0103ada:	83 ec 10             	sub    $0x10,%esp
f0103add:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103ae0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103ae4:	c7 04 24 89 64 10 f0 	movl   $0xf0106489,(%esp)
f0103aeb:	e8 1d fe ff ff       	call   f010390d <cprintf>
	print_regs(&tf->tf_regs);
f0103af0:	89 1c 24             	mov    %ebx,(%esp)
f0103af3:	e8 36 ff ff ff       	call   f0103a2e <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103af8:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103afc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b00:	c7 04 24 a4 63 10 f0 	movl   $0xf01063a4,(%esp)
f0103b07:	e8 01 fe ff ff       	call   f010390d <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103b0c:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103b10:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b14:	c7 04 24 b7 63 10 f0 	movl   $0xf01063b7,(%esp)
f0103b1b:	e8 ed fd ff ff       	call   f010390d <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103b20:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103b23:	83 f8 13             	cmp    $0x13,%eax
f0103b26:	77 09                	ja     f0103b31 <print_trapframe+0x5c>
		return excnames[trapno];
f0103b28:	8b 14 85 a0 66 10 f0 	mov    -0xfef9960(,%eax,4),%edx
f0103b2f:	eb 10                	jmp    f0103b41 <print_trapframe+0x6c>
	if (trapno == T_SYSCALL)
		return "System call";
f0103b31:	83 f8 30             	cmp    $0x30,%eax
f0103b34:	ba 62 63 10 f0       	mov    $0xf0106362,%edx
f0103b39:	b9 6e 63 10 f0       	mov    $0xf010636e,%ecx
f0103b3e:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103b41:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103b45:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b49:	c7 04 24 ca 63 10 f0 	movl   $0xf01063ca,(%esp)
f0103b50:	e8 b8 fd ff ff       	call   f010390d <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103b55:	3b 1d e0 ea 17 f0    	cmp    0xf017eae0,%ebx
f0103b5b:	75 19                	jne    f0103b76 <print_trapframe+0xa1>
f0103b5d:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103b61:	75 13                	jne    f0103b76 <print_trapframe+0xa1>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103b63:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103b66:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b6a:	c7 04 24 dc 63 10 f0 	movl   $0xf01063dc,(%esp)
f0103b71:	e8 97 fd ff ff       	call   f010390d <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f0103b76:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103b79:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b7d:	c7 04 24 eb 63 10 f0 	movl   $0xf01063eb,(%esp)
f0103b84:	e8 84 fd ff ff       	call   f010390d <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103b89:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103b8d:	75 51                	jne    f0103be0 <print_trapframe+0x10b>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103b8f:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103b92:	89 c2                	mov    %eax,%edx
f0103b94:	83 e2 01             	and    $0x1,%edx
f0103b97:	ba 7d 63 10 f0       	mov    $0xf010637d,%edx
f0103b9c:	b9 88 63 10 f0       	mov    $0xf0106388,%ecx
f0103ba1:	0f 45 ca             	cmovne %edx,%ecx
f0103ba4:	89 c2                	mov    %eax,%edx
f0103ba6:	83 e2 02             	and    $0x2,%edx
f0103ba9:	ba 94 63 10 f0       	mov    $0xf0106394,%edx
f0103bae:	be 9a 63 10 f0       	mov    $0xf010639a,%esi
f0103bb3:	0f 44 d6             	cmove  %esi,%edx
f0103bb6:	83 e0 04             	and    $0x4,%eax
f0103bb9:	b8 9f 63 10 f0       	mov    $0xf010639f,%eax
f0103bbe:	be d0 64 10 f0       	mov    $0xf01064d0,%esi
f0103bc3:	0f 44 c6             	cmove  %esi,%eax
f0103bc6:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103bca:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103bce:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bd2:	c7 04 24 f9 63 10 f0 	movl   $0xf01063f9,(%esp)
f0103bd9:	e8 2f fd ff ff       	call   f010390d <cprintf>
f0103bde:	eb 0c                	jmp    f0103bec <print_trapframe+0x117>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103be0:	c7 04 24 3c 67 10 f0 	movl   $0xf010673c,(%esp)
f0103be7:	e8 21 fd ff ff       	call   f010390d <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103bec:	8b 43 30             	mov    0x30(%ebx),%eax
f0103bef:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bf3:	c7 04 24 08 64 10 f0 	movl   $0xf0106408,(%esp)
f0103bfa:	e8 0e fd ff ff       	call   f010390d <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103bff:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103c03:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c07:	c7 04 24 17 64 10 f0 	movl   $0xf0106417,(%esp)
f0103c0e:	e8 fa fc ff ff       	call   f010390d <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103c13:	8b 43 38             	mov    0x38(%ebx),%eax
f0103c16:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c1a:	c7 04 24 2a 64 10 f0 	movl   $0xf010642a,(%esp)
f0103c21:	e8 e7 fc ff ff       	call   f010390d <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103c26:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103c2a:	74 27                	je     f0103c53 <print_trapframe+0x17e>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103c2c:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103c2f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c33:	c7 04 24 39 64 10 f0 	movl   $0xf0106439,(%esp)
f0103c3a:	e8 ce fc ff ff       	call   f010390d <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103c3f:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103c43:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c47:	c7 04 24 48 64 10 f0 	movl   $0xf0106448,(%esp)
f0103c4e:	e8 ba fc ff ff       	call   f010390d <cprintf>
	}
}
f0103c53:	83 c4 10             	add    $0x10,%esp
f0103c56:	5b                   	pop    %ebx
f0103c57:	5e                   	pop    %esi
f0103c58:	5d                   	pop    %ebp
f0103c59:	c3                   	ret    

f0103c5a <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103c5a:	55                   	push   %ebp
f0103c5b:	89 e5                	mov    %esp,%ebp
f0103c5d:	53                   	push   %ebx
f0103c5e:	83 ec 14             	sub    $0x14,%esp
f0103c61:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103c64:	0f 20 d0             	mov    %cr2,%eax
	// LAB 3: Your code here.


	//If the processor is already in kernel mode when the interrupt or exception occurs 
	//(the low 2 bits of the CS register are already zero), Hence we have to check the CS register to make sure its in kernel mode
	if ((tf->tf_cs & 0x11) == 0){
f0103c67:	f6 43 34 11          	testb  $0x11,0x34(%ebx)
f0103c6b:	75 20                	jne    f0103c8d <page_fault_handler+0x33>
		panic("Fault occured in kernel space on %08x \n",fault_va);
f0103c6d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103c71:	c7 44 24 08 1c 66 10 	movl   $0xf010661c,0x8(%esp)
f0103c78:	f0 
f0103c79:	c7 44 24 04 f6 00 00 	movl   $0xf6,0x4(%esp)
f0103c80:	00 
f0103c81:	c7 04 24 5b 64 10 f0 	movl   $0xf010645b,(%esp)
f0103c88:	e8 29 c4 ff ff       	call   f01000b6 <_panic>

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c8d:	8b 53 30             	mov    0x30(%ebx),%edx
f0103c90:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103c94:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103c98:	a1 cc e2 17 f0       	mov    0xf017e2cc,%eax
f0103c9d:	8b 40 48             	mov    0x48(%eax),%eax
f0103ca0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ca4:	c7 04 24 44 66 10 f0 	movl   $0xf0106644,(%esp)
f0103cab:	e8 5d fc ff ff       	call   f010390d <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103cb0:	89 1c 24             	mov    %ebx,(%esp)
f0103cb3:	e8 1d fe ff ff       	call   f0103ad5 <print_trapframe>
	env_destroy(curenv);
f0103cb8:	a1 cc e2 17 f0       	mov    0xf017e2cc,%eax
f0103cbd:	89 04 24             	mov    %eax,(%esp)
f0103cc0:	e8 15 fb ff ff       	call   f01037da <env_destroy>
}
f0103cc5:	83 c4 14             	add    $0x14,%esp
f0103cc8:	5b                   	pop    %ebx
f0103cc9:	5d                   	pop    %ebp
f0103cca:	c3                   	ret    

f0103ccb <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103ccb:	55                   	push   %ebp
f0103ccc:	89 e5                	mov    %esp,%ebp
f0103cce:	57                   	push   %edi
f0103ccf:	56                   	push   %esi
f0103cd0:	83 ec 20             	sub    $0x20,%esp
f0103cd3:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103cd6:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103cd7:	9c                   	pushf  
f0103cd8:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103cd9:	f6 c4 02             	test   $0x2,%ah
f0103cdc:	74 24                	je     f0103d02 <trap+0x37>
f0103cde:	c7 44 24 0c 67 64 10 	movl   $0xf0106467,0xc(%esp)
f0103ce5:	f0 
f0103ce6:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0103ced:	f0 
f0103cee:	c7 44 24 04 c9 00 00 	movl   $0xc9,0x4(%esp)
f0103cf5:	00 
f0103cf6:	c7 04 24 5b 64 10 f0 	movl   $0xf010645b,(%esp)
f0103cfd:	e8 b4 c3 ff ff       	call   f01000b6 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103d02:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103d06:	c7 04 24 80 64 10 f0 	movl   $0xf0106480,(%esp)
f0103d0d:	e8 fb fb ff ff       	call   f010390d <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103d12:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103d16:	83 e0 03             	and    $0x3,%eax
f0103d19:	66 83 f8 03          	cmp    $0x3,%ax
f0103d1d:	75 3c                	jne    f0103d5b <trap+0x90>
		// Trapped from user mode.
		assert(curenv);
f0103d1f:	a1 cc e2 17 f0       	mov    0xf017e2cc,%eax
f0103d24:	85 c0                	test   %eax,%eax
f0103d26:	75 24                	jne    f0103d4c <trap+0x81>
f0103d28:	c7 44 24 0c 9b 64 10 	movl   $0xf010649b,0xc(%esp)
f0103d2f:	f0 
f0103d30:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0103d37:	f0 
f0103d38:	c7 44 24 04 cf 00 00 	movl   $0xcf,0x4(%esp)
f0103d3f:	00 
f0103d40:	c7 04 24 5b 64 10 f0 	movl   $0xf010645b,(%esp)
f0103d47:	e8 6a c3 ff ff       	call   f01000b6 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103d4c:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103d51:	89 c7                	mov    %eax,%edi
f0103d53:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103d55:	8b 35 cc e2 17 f0    	mov    0xf017e2cc,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103d5b:	89 35 e0 ea 17 f0    	mov    %esi,0xf017eae0
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	//call trap_handler function for page_fault
	switch (tf->tf_trapno) {
f0103d61:	8b 46 28             	mov    0x28(%esi),%eax
f0103d64:	83 f8 0e             	cmp    $0xe,%eax
f0103d67:	74 20                	je     f0103d89 <trap+0xbe>
f0103d69:	83 f8 30             	cmp    $0x30,%eax
f0103d6c:	74 25                	je     f0103d93 <trap+0xc8>
f0103d6e:	83 f8 03             	cmp    $0x3,%eax
f0103d71:	75 52                	jne    f0103dc5 <trap+0xfa>
		case T_BRKPT:
			monitor(tf);
f0103d73:	89 34 24             	mov    %esi,(%esp)
f0103d76:	e8 8a ca ff ff       	call   f0100805 <monitor>
			cprintf("return from breakpoint....\n");
f0103d7b:	c7 04 24 a2 64 10 f0 	movl   $0xf01064a2,(%esp)
f0103d82:	e8 86 fb ff ff       	call   f010390d <cprintf>
f0103d87:	eb 3c                	jmp    f0103dc5 <trap+0xfa>
			break;

		case T_PGFLT:
			page_fault_handler(tf);
f0103d89:	89 34 24             	mov    %esi,(%esp)
f0103d8c:	e8 c9 fe ff ff       	call   f0103c5a <page_fault_handler>
f0103d91:	eb 32                	jmp    f0103dc5 <trap+0xfa>
			break;

		case T_SYSCALL:
			tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax,
f0103d93:	8b 46 04             	mov    0x4(%esi),%eax
f0103d96:	89 44 24 14          	mov    %eax,0x14(%esp)
f0103d9a:	8b 06                	mov    (%esi),%eax
f0103d9c:	89 44 24 10          	mov    %eax,0x10(%esp)
f0103da0:	8b 46 10             	mov    0x10(%esi),%eax
f0103da3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103da7:	8b 46 18             	mov    0x18(%esi),%eax
f0103daa:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103dae:	8b 46 14             	mov    0x14(%esi),%eax
f0103db1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103db5:	8b 46 1c             	mov    0x1c(%esi),%eax
f0103db8:	89 04 24             	mov    %eax,(%esp)
f0103dbb:	e8 50 01 00 00       	call   f0103f10 <syscall>
f0103dc0:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103dc3:	eb 38                	jmp    f0103dfd <trap+0x132>
			//asm volatile("movl %%eax, %0\n" : "=m"(tf->tf_regs.reg_eax) ::);
			return;
	}

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103dc5:	89 34 24             	mov    %esi,(%esp)
f0103dc8:	e8 08 fd ff ff       	call   f0103ad5 <print_trapframe>
	if (tf->tf_cs == GD_KT){
f0103dcd:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103dd2:	75 1c                	jne    f0103df0 <trap+0x125>
		panic("unhandled trap in kernel");
f0103dd4:	c7 44 24 08 be 64 10 	movl   $0xf01064be,0x8(%esp)
f0103ddb:	f0 
f0103ddc:	c7 44 24 04 b7 00 00 	movl   $0xb7,0x4(%esp)
f0103de3:	00 
f0103de4:	c7 04 24 5b 64 10 f0 	movl   $0xf010645b,(%esp)
f0103deb:	e8 c6 c2 ff ff       	call   f01000b6 <_panic>
	}
	else {
		env_destroy(curenv);
f0103df0:	a1 cc e2 17 f0       	mov    0xf017e2cc,%eax
f0103df5:	89 04 24             	mov    %eax,(%esp)
f0103df8:	e8 dd f9 ff ff       	call   f01037da <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103dfd:	a1 cc e2 17 f0       	mov    0xf017e2cc,%eax
f0103e02:	85 c0                	test   %eax,%eax
f0103e04:	74 06                	je     f0103e0c <trap+0x141>
f0103e06:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103e0a:	74 24                	je     f0103e30 <trap+0x165>
f0103e0c:	c7 44 24 0c 68 66 10 	movl   $0xf0106668,0xc(%esp)
f0103e13:	f0 
f0103e14:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f0103e1b:	f0 
f0103e1c:	c7 44 24 04 e1 00 00 	movl   $0xe1,0x4(%esp)
f0103e23:	00 
f0103e24:	c7 04 24 5b 64 10 f0 	movl   $0xf010645b,(%esp)
f0103e2b:	e8 86 c2 ff ff       	call   f01000b6 <_panic>
	env_run(curenv);
f0103e30:	89 04 24             	mov    %eax,(%esp)
f0103e33:	e8 f9 f9 ff ff       	call   f0103831 <env_run>

f0103e38 <handler_0>:
#define T_DEFAULT   500		// catchall
*/

//TRAPHANDLER_NOEC for traps without error code
// From 0-7 no error code requred
	TRAPHANDLER_NOEC(handler_0, 0)   #Divide error
f0103e38:	6a 00                	push   $0x0
f0103e3a:	6a 00                	push   $0x0
f0103e3c:	e9 ba 00 00 00       	jmp    f0103efb <_alltraps>
f0103e41:	90                   	nop

f0103e42 <handler_1>:
	TRAPHANDLER_NOEC(handler_1, 1)   #Debug exceptions 
f0103e42:	6a 00                	push   $0x0
f0103e44:	6a 01                	push   $0x1
f0103e46:	e9 b0 00 00 00       	jmp    f0103efb <_alltraps>
f0103e4b:	90                   	nop

f0103e4c <handler_2>:
 	TRAPHANDLER_NOEC(handler_2, 2)   //NMI Interrupt
f0103e4c:	6a 00                	push   $0x0
f0103e4e:	6a 02                	push   $0x2
f0103e50:	e9 a6 00 00 00       	jmp    f0103efb <_alltraps>
f0103e55:	90                   	nop

f0103e56 <handler_3>:
	TRAPHANDLER_NOEC(handler_3, 3)   //Breakpoint
f0103e56:	6a 00                	push   $0x0
f0103e58:	6a 03                	push   $0x3
f0103e5a:	e9 9c 00 00 00       	jmp    f0103efb <_alltraps>
f0103e5f:	90                   	nop

f0103e60 <handler_4>:
	TRAPHANDLER_NOEC(handler_4, 4)   //Overflow
f0103e60:	6a 00                	push   $0x0
f0103e62:	6a 04                	push   $0x4
f0103e64:	e9 92 00 00 00       	jmp    f0103efb <_alltraps>
f0103e69:	90                   	nop

f0103e6a <handler_5>:
	TRAPHANDLER_NOEC(handler_5, 5)   //Bounds check 
f0103e6a:	6a 00                	push   $0x0
f0103e6c:	6a 05                	push   $0x5
f0103e6e:	e9 88 00 00 00       	jmp    f0103efb <_alltraps>
f0103e73:	90                   	nop

f0103e74 <handler_6>:
	TRAPHANDLER_NOEC(handler_6, 6)   //Invalid opcode
f0103e74:	6a 00                	push   $0x0
f0103e76:	6a 06                	push   $0x6
f0103e78:	e9 7e 00 00 00       	jmp    f0103efb <_alltraps>
f0103e7d:	90                   	nop

f0103e7e <handler_7>:
	TRAPHANDLER_NOEC(handler_7, 7)   //Coprocessor not available
f0103e7e:	6a 00                	push   $0x0
f0103e80:	6a 07                	push   $0x7
f0103e82:	e9 74 00 00 00       	jmp    f0103efb <_alltraps>
f0103e87:	90                   	nop

f0103e88 <handler_8>:
	
	TRAPHANDLER(handler_8, 8)   // double fault
f0103e88:	6a 08                	push   $0x8
f0103e8a:	e9 6c 00 00 00       	jmp    f0103efb <_alltraps>
f0103e8f:	90                   	nop

f0103e90 <handler_9>:
	
	TRAPHANDLER_NOEC(handler_9, 9)   //Coprocessor Segment Overrun
f0103e90:	6a 00                	push   $0x0
f0103e92:	6a 09                	push   $0x9
f0103e94:	e9 62 00 00 00       	jmp    f0103efb <_alltraps>
f0103e99:	90                   	nop

f0103e9a <handler_10>:

	TRAPHANDLER(handler_10, 10)   // invalid task switch segment
f0103e9a:	6a 0a                	push   $0xa
f0103e9c:	e9 5a 00 00 00       	jmp    f0103efb <_alltraps>
f0103ea1:	90                   	nop

f0103ea2 <handler_11>:
	TRAPHANDLER(handler_11, 11)   // segment not present
f0103ea2:	6a 0b                	push   $0xb
f0103ea4:	e9 52 00 00 00       	jmp    f0103efb <_alltraps>
f0103ea9:	90                   	nop

f0103eaa <handler_12>:
	TRAPHANDLER(handler_12, 12)   // stack exception
f0103eaa:	6a 0c                	push   $0xc
f0103eac:	e9 4a 00 00 00       	jmp    f0103efb <_alltraps>
f0103eb1:	90                   	nop

f0103eb2 <handler_13>:
	TRAPHANDLER(handler_13, 13)   // general protection fault
f0103eb2:	6a 0d                	push   $0xd
f0103eb4:	e9 42 00 00 00       	jmp    f0103efb <_alltraps>
f0103eb9:	90                   	nop

f0103eba <handler_14>:
	TRAPHANDLER(handler_14, 14)   // page fault
f0103eba:	6a 0e                	push   $0xe
f0103ebc:	e9 3a 00 00 00       	jmp    f0103efb <_alltraps>
f0103ec1:	90                   	nop

f0103ec2 <handler_15>:

	TRAPHANDLER_NOEC(handler_15, 15)   // Reserved
f0103ec2:	6a 00                	push   $0x0
f0103ec4:	6a 0f                	push   $0xf
f0103ec6:	e9 30 00 00 00       	jmp    f0103efb <_alltraps>
f0103ecb:	90                   	nop

f0103ecc <handler_16>:

	TRAPHANDLER_NOEC(handler_16, 16)   // floating point error
f0103ecc:	6a 00                	push   $0x0
f0103ece:	6a 10                	push   $0x10
f0103ed0:	e9 26 00 00 00       	jmp    f0103efb <_alltraps>
f0103ed5:	90                   	nop

f0103ed6 <handler_17>:

	TRAPHANDLER(handler_17, 17)   // aligment check
f0103ed6:	6a 11                	push   $0x11
f0103ed8:	e9 1e 00 00 00       	jmp    f0103efb <_alltraps>
f0103edd:	90                   	nop

f0103ede <handler_18>:

	TRAPHANDLER_NOEC(handler_18, 18)   // machine check
f0103ede:	6a 00                	push   $0x0
f0103ee0:	6a 12                	push   $0x12
f0103ee2:	e9 14 00 00 00       	jmp    f0103efb <_alltraps>
f0103ee7:	90                   	nop

f0103ee8 <handler_19>:
	TRAPHANDLER_NOEC(handler_19, 19)   // SIMD floating point error
f0103ee8:	6a 00                	push   $0x0
f0103eea:	6a 13                	push   $0x13
f0103eec:	e9 0a 00 00 00       	jmp    f0103efb <_alltraps>
f0103ef1:	90                   	nop

f0103ef2 <handler_48>:

	TRAPHANDLER_NOEC(handler_48, 48)   // system call
f0103ef2:	6a 00                	push   $0x0
f0103ef4:	6a 30                	push   $0x30
f0103ef6:	e9 00 00 00 00       	jmp    f0103efb <_alltraps>

f0103efb <_alltraps>:
 */

.globl _alltraps
_alltraps:
	#Remaining Trap frame
	push %ds
f0103efb:	1e                   	push   %ds
	push %es
f0103efc:	06                   	push   %es
	pushal
f0103efd:	60                   	pusha  

	
	movw $GD_KD, %ax
f0103efe:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f0103f02:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f0103f04:	8e c0                	mov    %eax,%es

	#call Trap 
	pushl %esp
f0103f06:	54                   	push   %esp
	call trap
f0103f07:	e8 bf fd ff ff       	call   f0103ccb <trap>
f0103f0c:	66 90                	xchg   %ax,%ax
f0103f0e:	66 90                	xchg   %ax,%ax

f0103f10 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0103f10:	55                   	push   %ebp
f0103f11:	89 e5                	mov    %esp,%ebp
f0103f13:	83 ec 28             	sub    $0x28,%esp
f0103f16:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	

	switch (syscallno) {
f0103f19:	83 f8 01             	cmp    $0x1,%eax
f0103f1c:	74 5e                	je     f0103f7c <syscall+0x6c>
f0103f1e:	83 f8 01             	cmp    $0x1,%eax
f0103f21:	72 12                	jb     f0103f35 <syscall+0x25>
f0103f23:	83 f8 02             	cmp    $0x2,%eax
f0103f26:	74 5e                	je     f0103f86 <syscall+0x76>
f0103f28:	83 f8 03             	cmp    $0x3,%eax
f0103f2b:	74 66                	je     f0103f93 <syscall+0x83>
f0103f2d:	8d 76 00             	lea    0x0(%esi),%esi
f0103f30:	e9 ca 00 00 00       	jmp    f0103fff <syscall+0xef>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_P | PTE_U);
f0103f35:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f0103f3c:	00 
f0103f3d:	8b 45 10             	mov    0x10(%ebp),%eax
f0103f40:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103f44:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103f47:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f4b:	a1 cc e2 17 f0       	mov    0xf017e2cc,%eax
f0103f50:	89 04 24             	mov    %eax,(%esp)
f0103f53:	e8 a5 f1 ff ff       	call   f01030fd <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0103f58:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103f5b:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103f5f:	8b 45 10             	mov    0x10(%ebp),%eax
f0103f62:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f66:	c7 04 24 f0 66 10 f0 	movl   $0xf01066f0,(%esp)
f0103f6d:	e8 9b f9 ff ff       	call   f010390d <cprintf>

	switch (syscallno) {

	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;
f0103f72:	b8 00 00 00 00       	mov    $0x0,%eax
f0103f77:	e9 9f 00 00 00       	jmp    f010401b <syscall+0x10b>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0103f7c:	e8 54 c5 ff ff       	call   f01004d5 <cons_getc>
	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;

	case SYS_cgetc:
		return sys_cgetc();
f0103f81:	e9 95 00 00 00       	jmp    f010401b <syscall+0x10b>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0103f86:	a1 cc e2 17 f0       	mov    0xf017e2cc,%eax
f0103f8b:	8b 40 48             	mov    0x48(%eax),%eax

	case SYS_cgetc:
		return sys_cgetc();
		
	case SYS_getenvid:
		return sys_getenvid();
f0103f8e:	e9 88 00 00 00       	jmp    f010401b <syscall+0x10b>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0103f93:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0103f9a:	00 
f0103f9b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103f9e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103fa2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103fa5:	89 04 24             	mov    %eax,(%esp)
f0103fa8:	e8 43 f2 ff ff       	call   f01031f0 <envid2env>
f0103fad:	85 c0                	test   %eax,%eax
f0103faf:	78 6a                	js     f010401b <syscall+0x10b>
		return r;
	if (e == curenv)
f0103fb1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103fb4:	8b 15 cc e2 17 f0    	mov    0xf017e2cc,%edx
f0103fba:	39 d0                	cmp    %edx,%eax
f0103fbc:	75 15                	jne    f0103fd3 <syscall+0xc3>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0103fbe:	8b 40 48             	mov    0x48(%eax),%eax
f0103fc1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103fc5:	c7 04 24 f5 66 10 f0 	movl   $0xf01066f5,(%esp)
f0103fcc:	e8 3c f9 ff ff       	call   f010390d <cprintf>
f0103fd1:	eb 1a                	jmp    f0103fed <syscall+0xdd>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0103fd3:	8b 40 48             	mov    0x48(%eax),%eax
f0103fd6:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103fda:	8b 42 48             	mov    0x48(%edx),%eax
f0103fdd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103fe1:	c7 04 24 10 67 10 f0 	movl   $0xf0106710,(%esp)
f0103fe8:	e8 20 f9 ff ff       	call   f010390d <cprintf>
	env_destroy(e);
f0103fed:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103ff0:	89 04 24             	mov    %eax,(%esp)
f0103ff3:	e8 e2 f7 ff ff       	call   f01037da <env_destroy>
	return 0;
f0103ff8:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ffd:	eb 1c                	jmp    f010401b <syscall+0x10b>
		
	case SYS_env_destroy:
		return sys_env_destroy(a1);
		
	default:
		panic("Invalid System Call \n");
f0103fff:	c7 44 24 08 28 67 10 	movl   $0xf0106728,0x8(%esp)
f0104006:	f0 
f0104007:	c7 44 24 04 5b 00 00 	movl   $0x5b,0x4(%esp)
f010400e:	00 
f010400f:	c7 04 24 3e 67 10 f0 	movl   $0xf010673e,(%esp)
f0104016:	e8 9b c0 ff ff       	call   f01000b6 <_panic>
		return -E_INVAL;
	}
}
f010401b:	c9                   	leave  
f010401c:	c3                   	ret    

f010401d <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010401d:	55                   	push   %ebp
f010401e:	89 e5                	mov    %esp,%ebp
f0104020:	57                   	push   %edi
f0104021:	56                   	push   %esi
f0104022:	53                   	push   %ebx
f0104023:	83 ec 14             	sub    $0x14,%esp
f0104026:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104029:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010402c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010402f:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104032:	8b 1a                	mov    (%edx),%ebx
f0104034:	8b 01                	mov    (%ecx),%eax
f0104036:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104039:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104040:	e9 88 00 00 00       	jmp    f01040cd <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0104045:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104048:	01 d8                	add    %ebx,%eax
f010404a:	89 c7                	mov    %eax,%edi
f010404c:	c1 ef 1f             	shr    $0x1f,%edi
f010404f:	01 c7                	add    %eax,%edi
f0104051:	d1 ff                	sar    %edi
f0104053:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0104056:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104059:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010405c:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010405e:	eb 03                	jmp    f0104063 <stab_binsearch+0x46>
			m--;
f0104060:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104063:	39 c3                	cmp    %eax,%ebx
f0104065:	7f 1f                	jg     f0104086 <stab_binsearch+0x69>
f0104067:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010406b:	83 ea 0c             	sub    $0xc,%edx
f010406e:	39 f1                	cmp    %esi,%ecx
f0104070:	75 ee                	jne    f0104060 <stab_binsearch+0x43>
f0104072:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104075:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104078:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010407b:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010407f:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104082:	76 18                	jbe    f010409c <stab_binsearch+0x7f>
f0104084:	eb 05                	jmp    f010408b <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104086:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0104089:	eb 42                	jmp    f01040cd <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f010408b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010408e:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0104090:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104093:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010409a:	eb 31                	jmp    f01040cd <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010409c:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010409f:	73 17                	jae    f01040b8 <stab_binsearch+0x9b>
			*region_right = m - 1;
f01040a1:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01040a4:	83 e8 01             	sub    $0x1,%eax
f01040a7:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01040aa:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01040ad:	89 07                	mov    %eax,(%edi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01040af:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01040b6:	eb 15                	jmp    f01040cd <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01040b8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01040bb:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f01040be:	89 1f                	mov    %ebx,(%edi)
			l = m;
			addr++;
f01040c0:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01040c4:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01040c6:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01040cd:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01040d0:	0f 8e 6f ff ff ff    	jle    f0104045 <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01040d6:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01040da:	75 0f                	jne    f01040eb <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f01040dc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01040df:	8b 00                	mov    (%eax),%eax
f01040e1:	83 e8 01             	sub    $0x1,%eax
f01040e4:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01040e7:	89 07                	mov    %eax,(%edi)
f01040e9:	eb 2c                	jmp    f0104117 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01040eb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01040ee:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01040f0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01040f3:	8b 0f                	mov    (%edi),%ecx
f01040f5:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01040f8:	8b 7d ec             	mov    -0x14(%ebp),%edi
f01040fb:	8d 14 97             	lea    (%edi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01040fe:	eb 03                	jmp    f0104103 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104100:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104103:	39 c8                	cmp    %ecx,%eax
f0104105:	7e 0b                	jle    f0104112 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0104107:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010410b:	83 ea 0c             	sub    $0xc,%edx
f010410e:	39 f3                	cmp    %esi,%ebx
f0104110:	75 ee                	jne    f0104100 <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104112:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104115:	89 07                	mov    %eax,(%edi)
	}
}
f0104117:	83 c4 14             	add    $0x14,%esp
f010411a:	5b                   	pop    %ebx
f010411b:	5e                   	pop    %esi
f010411c:	5f                   	pop    %edi
f010411d:	5d                   	pop    %ebp
f010411e:	c3                   	ret    

f010411f <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010411f:	55                   	push   %ebp
f0104120:	89 e5                	mov    %esp,%ebp
f0104122:	57                   	push   %edi
f0104123:	56                   	push   %esi
f0104124:	53                   	push   %ebx
f0104125:	83 ec 4c             	sub    $0x4c,%esp
f0104128:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010412b:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010412e:	c7 07 4d 67 10 f0    	movl   $0xf010674d,(%edi)
	info->eip_line = 0;
f0104134:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f010413b:	c7 47 08 4d 67 10 f0 	movl   $0xf010674d,0x8(%edi)
	info->eip_fn_namelen = 9;
f0104142:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0104149:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f010414c:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104153:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0104159:	0f 87 a5 00 00 00    	ja     f0104204 <debuginfo_eip+0xe5>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
f010415f:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f0104166:	00 
f0104167:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f010416e:	00 
f010416f:	c7 44 24 04 00 00 20 	movl   $0x200000,0x4(%esp)
f0104176:	00 
f0104177:	a1 cc e2 17 f0       	mov    0xf017e2cc,%eax
f010417c:	89 04 24             	mov    %eax,(%esp)
f010417f:	e8 74 ee ff ff       	call   f0102ff8 <user_mem_check>
f0104184:	85 c0                	test   %eax,%eax
f0104186:	0f 88 3e 02 00 00    	js     f01043ca <debuginfo_eip+0x2ab>
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
		}
		stabs = usd->stabs;
f010418c:	a1 00 00 20 00       	mov    0x200000,%eax
f0104191:	89 c1                	mov    %eax,%ecx
f0104193:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		stab_end = usd->stab_end;
f0104196:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f010419c:	a1 08 00 20 00       	mov    0x200008,%eax
f01041a1:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f01041a4:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f01041aa:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
f01041ad:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f01041b4:	00 
f01041b5:	89 f0                	mov    %esi,%eax
f01041b7:	29 c8                	sub    %ecx,%eax
f01041b9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01041bd:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01041c1:	a1 cc e2 17 f0       	mov    0xf017e2cc,%eax
f01041c6:	89 04 24             	mov    %eax,(%esp)
f01041c9:	e8 2a ee ff ff       	call   f0102ff8 <user_mem_check>
f01041ce:	85 c0                	test   %eax,%eax
f01041d0:	0f 88 fb 01 00 00    	js     f01043d1 <debuginfo_eip+0x2b2>
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
		}

		if (user_mem_check(curenv, (const void *)stabstr,
f01041d6:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f01041dd:	00 
f01041de:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01041e1:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f01041e4:	29 ca                	sub    %ecx,%edx
f01041e6:	89 54 24 08          	mov    %edx,0x8(%esp)
f01041ea:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01041ee:	a1 cc e2 17 f0       	mov    0xf017e2cc,%eax
f01041f3:	89 04 24             	mov    %eax,(%esp)
f01041f6:	e8 fd ed ff ff       	call   f0102ff8 <user_mem_check>
f01041fb:	85 c0                	test   %eax,%eax
f01041fd:	79 1f                	jns    f010421e <debuginfo_eip+0xff>
f01041ff:	e9 d4 01 00 00       	jmp    f01043d8 <debuginfo_eip+0x2b9>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104204:	c7 45 bc 24 13 11 f0 	movl   $0xf0111324,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f010420b:	c7 45 c0 5d e8 10 f0 	movl   $0xf010e85d,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104212:	be 5c e8 10 f0       	mov    $0xf010e85c,%esi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104217:	c7 45 c4 90 69 10 f0 	movl   $0xf0106990,-0x3c(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010421e:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104221:	39 45 c0             	cmp    %eax,-0x40(%ebp)
f0104224:	0f 83 b5 01 00 00    	jae    f01043df <debuginfo_eip+0x2c0>
f010422a:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f010422e:	0f 85 b2 01 00 00    	jne    f01043e6 <debuginfo_eip+0x2c7>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104234:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010423b:	2b 75 c4             	sub    -0x3c(%ebp),%esi
f010423e:	c1 fe 02             	sar    $0x2,%esi
f0104241:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f0104247:	83 e8 01             	sub    $0x1,%eax
f010424a:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010424d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104251:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0104258:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f010425b:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010425e:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0104261:	89 f0                	mov    %esi,%eax
f0104263:	e8 b5 fd ff ff       	call   f010401d <stab_binsearch>
	if (lfile == 0)
f0104268:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010426b:	85 c0                	test   %eax,%eax
f010426d:	0f 84 7a 01 00 00    	je     f01043ed <debuginfo_eip+0x2ce>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104273:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104276:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104279:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010427c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104280:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0104287:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010428a:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010428d:	89 f0                	mov    %esi,%eax
f010428f:	e8 89 fd ff ff       	call   f010401d <stab_binsearch>

	if (lfun <= rfun) {
f0104294:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104297:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f010429a:	39 c8                	cmp    %ecx,%eax
f010429c:	7f 32                	jg     f01042d0 <debuginfo_eip+0x1b1>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010429e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01042a1:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01042a4:	8d 34 96             	lea    (%esi,%edx,4),%esi
f01042a7:	8b 16                	mov    (%esi),%edx
f01042a9:	89 55 b8             	mov    %edx,-0x48(%ebp)
f01042ac:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01042af:	2b 55 c0             	sub    -0x40(%ebp),%edx
f01042b2:	39 55 b8             	cmp    %edx,-0x48(%ebp)
f01042b5:	73 09                	jae    f01042c0 <debuginfo_eip+0x1a1>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01042b7:	8b 55 b8             	mov    -0x48(%ebp),%edx
f01042ba:	03 55 c0             	add    -0x40(%ebp),%edx
f01042bd:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f01042c0:	8b 56 08             	mov    0x8(%esi),%edx
f01042c3:	89 57 10             	mov    %edx,0x10(%edi)
		addr -= info->eip_fn_addr;
f01042c6:	29 d3                	sub    %edx,%ebx
		// Search within the function definition for the line number.
		lline = lfun;
f01042c8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01042cb:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f01042ce:	eb 0f                	jmp    f01042df <debuginfo_eip+0x1c0>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01042d0:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f01042d3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01042d6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01042d9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01042dc:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01042df:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f01042e6:	00 
f01042e7:	8b 47 08             	mov    0x8(%edi),%eax
f01042ea:	89 04 24             	mov    %eax,(%esp)
f01042ed:	e8 29 09 00 00       	call   f0104c1b <strfind>
f01042f2:	2b 47 08             	sub    0x8(%edi),%eax
f01042f5:	89 47 0c             	mov    %eax,0xc(%edi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
f01042f8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01042fc:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0104303:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104306:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0104309:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f010430c:	89 f0                	mov    %esi,%eax
f010430e:	e8 0a fd ff ff       	call   f010401d <stab_binsearch>
	if (lline > rline) {
f0104313:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104316:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0104319:	0f 8f d5 00 00 00    	jg     f01043f4 <debuginfo_eip+0x2d5>
		return -1; //Did not find the line number in the stab
	}
	info->eip_line = stabs[lline].n_desc; //If found update the info object with the correct line number
f010431f:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104322:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0104327:	89 47 04             	mov    %eax,0x4(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010432a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010432d:	89 c3                	mov    %eax,%ebx
f010432f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104332:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104335:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0104338:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010433b:	89 df                	mov    %ebx,%edi
f010433d:	eb 06                	jmp    f0104345 <debuginfo_eip+0x226>
f010433f:	83 e8 01             	sub    $0x1,%eax
f0104342:	83 ea 0c             	sub    $0xc,%edx
f0104345:	89 c6                	mov    %eax,%esi
f0104347:	39 c7                	cmp    %eax,%edi
f0104349:	7f 3c                	jg     f0104387 <debuginfo_eip+0x268>
	       && stabs[lline].n_type != N_SOL
f010434b:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010434f:	80 f9 84             	cmp    $0x84,%cl
f0104352:	75 08                	jne    f010435c <debuginfo_eip+0x23d>
f0104354:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104357:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010435a:	eb 11                	jmp    f010436d <debuginfo_eip+0x24e>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010435c:	80 f9 64             	cmp    $0x64,%cl
f010435f:	75 de                	jne    f010433f <debuginfo_eip+0x220>
f0104361:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0104365:	74 d8                	je     f010433f <debuginfo_eip+0x220>
f0104367:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010436a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010436d:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0104370:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0104373:	8b 04 83             	mov    (%ebx,%eax,4),%eax
f0104376:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104379:	2b 55 c0             	sub    -0x40(%ebp),%edx
f010437c:	39 d0                	cmp    %edx,%eax
f010437e:	73 0a                	jae    f010438a <debuginfo_eip+0x26b>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104380:	03 45 c0             	add    -0x40(%ebp),%eax
f0104383:	89 07                	mov    %eax,(%edi)
f0104385:	eb 03                	jmp    f010438a <debuginfo_eip+0x26b>
f0104387:	8b 7d 0c             	mov    0xc(%ebp),%edi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010438a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010438d:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104390:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104395:	39 da                	cmp    %ebx,%edx
f0104397:	7d 67                	jge    f0104400 <debuginfo_eip+0x2e1>
		for (lline = lfun + 1;
f0104399:	83 c2 01             	add    $0x1,%edx
f010439c:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010439f:	89 d0                	mov    %edx,%eax
f01043a1:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01043a4:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01043a7:	8d 14 96             	lea    (%esi,%edx,4),%edx
f01043aa:	eb 04                	jmp    f01043b0 <debuginfo_eip+0x291>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01043ac:	83 47 14 01          	addl   $0x1,0x14(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01043b0:	39 c3                	cmp    %eax,%ebx
f01043b2:	7e 47                	jle    f01043fb <debuginfo_eip+0x2dc>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01043b4:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01043b8:	83 c0 01             	add    $0x1,%eax
f01043bb:	83 c2 0c             	add    $0xc,%edx
f01043be:	80 f9 a0             	cmp    $0xa0,%cl
f01043c1:	74 e9                	je     f01043ac <debuginfo_eip+0x28d>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01043c3:	b8 00 00 00 00       	mov    $0x0,%eax
f01043c8:	eb 36                	jmp    f0104400 <debuginfo_eip+0x2e1>
		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
f01043ca:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01043cf:	eb 2f                	jmp    f0104400 <debuginfo_eip+0x2e1>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
f01043d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01043d6:	eb 28                	jmp    f0104400 <debuginfo_eip+0x2e1>
		}

		if (user_mem_check(curenv, (const void *)stabstr,
				(uintptr_t)stabstr_end - (uintptr_t)stabstr, PTE_U | PTE_P) < 0) {
			return -1;
f01043d8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01043dd:	eb 21                	jmp    f0104400 <debuginfo_eip+0x2e1>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01043df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01043e4:	eb 1a                	jmp    f0104400 <debuginfo_eip+0x2e1>
f01043e6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01043eb:	eb 13                	jmp    f0104400 <debuginfo_eip+0x2e1>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01043ed:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01043f2:	eb 0c                	jmp    f0104400 <debuginfo_eip+0x2e1>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
	if (lline > rline) {
		return -1; //Did not find the line number in the stab
f01043f4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01043f9:	eb 05                	jmp    f0104400 <debuginfo_eip+0x2e1>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01043fb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104400:	83 c4 4c             	add    $0x4c,%esp
f0104403:	5b                   	pop    %ebx
f0104404:	5e                   	pop    %esi
f0104405:	5f                   	pop    %edi
f0104406:	5d                   	pop    %ebp
f0104407:	c3                   	ret    
f0104408:	66 90                	xchg   %ax,%ax
f010440a:	66 90                	xchg   %ax,%ax
f010440c:	66 90                	xchg   %ax,%ax
f010440e:	66 90                	xchg   %ax,%ax

f0104410 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104410:	55                   	push   %ebp
f0104411:	89 e5                	mov    %esp,%ebp
f0104413:	57                   	push   %edi
f0104414:	56                   	push   %esi
f0104415:	53                   	push   %ebx
f0104416:	83 ec 3c             	sub    $0x3c,%esp
f0104419:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010441c:	89 d7                	mov    %edx,%edi
f010441e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104421:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104424:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104427:	89 c3                	mov    %eax,%ebx
f0104429:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010442c:	8b 45 10             	mov    0x10(%ebp),%eax
f010442f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104432:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104437:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010443a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010443d:	39 d9                	cmp    %ebx,%ecx
f010443f:	72 05                	jb     f0104446 <printnum+0x36>
f0104441:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0104444:	77 69                	ja     f01044af <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104446:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0104449:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010444d:	83 ee 01             	sub    $0x1,%esi
f0104450:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0104454:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104458:	8b 44 24 08          	mov    0x8(%esp),%eax
f010445c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0104460:	89 c3                	mov    %eax,%ebx
f0104462:	89 d6                	mov    %edx,%esi
f0104464:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104467:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010446a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010446e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0104472:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104475:	89 04 24             	mov    %eax,(%esp)
f0104478:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010447b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010447f:	e8 bc 09 00 00       	call   f0104e40 <__udivdi3>
f0104484:	89 d9                	mov    %ebx,%ecx
f0104486:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010448a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010448e:	89 04 24             	mov    %eax,(%esp)
f0104491:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104495:	89 fa                	mov    %edi,%edx
f0104497:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010449a:	e8 71 ff ff ff       	call   f0104410 <printnum>
f010449f:	eb 1b                	jmp    f01044bc <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01044a1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01044a5:	8b 45 18             	mov    0x18(%ebp),%eax
f01044a8:	89 04 24             	mov    %eax,(%esp)
f01044ab:	ff d3                	call   *%ebx
f01044ad:	eb 03                	jmp    f01044b2 <printnum+0xa2>
f01044af:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01044b2:	83 ee 01             	sub    $0x1,%esi
f01044b5:	85 f6                	test   %esi,%esi
f01044b7:	7f e8                	jg     f01044a1 <printnum+0x91>
f01044b9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01044bc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01044c0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01044c4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01044c7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01044ca:	89 44 24 08          	mov    %eax,0x8(%esp)
f01044ce:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01044d2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01044d5:	89 04 24             	mov    %eax,(%esp)
f01044d8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01044db:	89 44 24 04          	mov    %eax,0x4(%esp)
f01044df:	e8 8c 0a 00 00       	call   f0104f70 <__umoddi3>
f01044e4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01044e8:	0f be 80 57 67 10 f0 	movsbl -0xfef98a9(%eax),%eax
f01044ef:	89 04 24             	mov    %eax,(%esp)
f01044f2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01044f5:	ff d0                	call   *%eax
}
f01044f7:	83 c4 3c             	add    $0x3c,%esp
f01044fa:	5b                   	pop    %ebx
f01044fb:	5e                   	pop    %esi
f01044fc:	5f                   	pop    %edi
f01044fd:	5d                   	pop    %ebp
f01044fe:	c3                   	ret    

f01044ff <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01044ff:	55                   	push   %ebp
f0104500:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104502:	83 fa 01             	cmp    $0x1,%edx
f0104505:	7e 0e                	jle    f0104515 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0104507:	8b 10                	mov    (%eax),%edx
f0104509:	8d 4a 08             	lea    0x8(%edx),%ecx
f010450c:	89 08                	mov    %ecx,(%eax)
f010450e:	8b 02                	mov    (%edx),%eax
f0104510:	8b 52 04             	mov    0x4(%edx),%edx
f0104513:	eb 22                	jmp    f0104537 <getuint+0x38>
	else if (lflag)
f0104515:	85 d2                	test   %edx,%edx
f0104517:	74 10                	je     f0104529 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104519:	8b 10                	mov    (%eax),%edx
f010451b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010451e:	89 08                	mov    %ecx,(%eax)
f0104520:	8b 02                	mov    (%edx),%eax
f0104522:	ba 00 00 00 00       	mov    $0x0,%edx
f0104527:	eb 0e                	jmp    f0104537 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104529:	8b 10                	mov    (%eax),%edx
f010452b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010452e:	89 08                	mov    %ecx,(%eax)
f0104530:	8b 02                	mov    (%edx),%eax
f0104532:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104537:	5d                   	pop    %ebp
f0104538:	c3                   	ret    

f0104539 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104539:	55                   	push   %ebp
f010453a:	89 e5                	mov    %esp,%ebp
f010453c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010453f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104543:	8b 10                	mov    (%eax),%edx
f0104545:	3b 50 04             	cmp    0x4(%eax),%edx
f0104548:	73 0a                	jae    f0104554 <sprintputch+0x1b>
		*b->buf++ = ch;
f010454a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010454d:	89 08                	mov    %ecx,(%eax)
f010454f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104552:	88 02                	mov    %al,(%edx)
}
f0104554:	5d                   	pop    %ebp
f0104555:	c3                   	ret    

f0104556 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104556:	55                   	push   %ebp
f0104557:	89 e5                	mov    %esp,%ebp
f0104559:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f010455c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010455f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104563:	8b 45 10             	mov    0x10(%ebp),%eax
f0104566:	89 44 24 08          	mov    %eax,0x8(%esp)
f010456a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010456d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104571:	8b 45 08             	mov    0x8(%ebp),%eax
f0104574:	89 04 24             	mov    %eax,(%esp)
f0104577:	e8 02 00 00 00       	call   f010457e <vprintfmt>
	va_end(ap);
}
f010457c:	c9                   	leave  
f010457d:	c3                   	ret    

f010457e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010457e:	55                   	push   %ebp
f010457f:	89 e5                	mov    %esp,%ebp
f0104581:	57                   	push   %edi
f0104582:	56                   	push   %esi
f0104583:	53                   	push   %ebx
f0104584:	83 ec 3c             	sub    $0x3c,%esp
f0104587:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010458a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010458d:	eb 14                	jmp    f01045a3 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010458f:	85 c0                	test   %eax,%eax
f0104591:	0f 84 b3 03 00 00    	je     f010494a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0104597:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010459b:	89 04 24             	mov    %eax,(%esp)
f010459e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01045a1:	89 f3                	mov    %esi,%ebx
f01045a3:	8d 73 01             	lea    0x1(%ebx),%esi
f01045a6:	0f b6 03             	movzbl (%ebx),%eax
f01045a9:	83 f8 25             	cmp    $0x25,%eax
f01045ac:	75 e1                	jne    f010458f <vprintfmt+0x11>
f01045ae:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f01045b2:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01045b9:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f01045c0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f01045c7:	ba 00 00 00 00       	mov    $0x0,%edx
f01045cc:	eb 1d                	jmp    f01045eb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01045ce:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f01045d0:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f01045d4:	eb 15                	jmp    f01045eb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01045d6:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01045d8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f01045dc:	eb 0d                	jmp    f01045eb <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01045de:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01045e1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01045e4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01045eb:	8d 5e 01             	lea    0x1(%esi),%ebx
f01045ee:	0f b6 0e             	movzbl (%esi),%ecx
f01045f1:	0f b6 c1             	movzbl %cl,%eax
f01045f4:	83 e9 23             	sub    $0x23,%ecx
f01045f7:	80 f9 55             	cmp    $0x55,%cl
f01045fa:	0f 87 2a 03 00 00    	ja     f010492a <vprintfmt+0x3ac>
f0104600:	0f b6 c9             	movzbl %cl,%ecx
f0104603:	ff 24 8d 00 68 10 f0 	jmp    *-0xfef9800(,%ecx,4)
f010460a:	89 de                	mov    %ebx,%esi
f010460c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104611:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0104614:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0104618:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f010461b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f010461e:	83 fb 09             	cmp    $0x9,%ebx
f0104621:	77 36                	ja     f0104659 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104623:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104626:	eb e9                	jmp    f0104611 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104628:	8b 45 14             	mov    0x14(%ebp),%eax
f010462b:	8d 48 04             	lea    0x4(%eax),%ecx
f010462e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104631:	8b 00                	mov    (%eax),%eax
f0104633:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104636:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104638:	eb 22                	jmp    f010465c <vprintfmt+0xde>
f010463a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010463d:	85 c9                	test   %ecx,%ecx
f010463f:	b8 00 00 00 00       	mov    $0x0,%eax
f0104644:	0f 49 c1             	cmovns %ecx,%eax
f0104647:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010464a:	89 de                	mov    %ebx,%esi
f010464c:	eb 9d                	jmp    f01045eb <vprintfmt+0x6d>
f010464e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104650:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0104657:	eb 92                	jmp    f01045eb <vprintfmt+0x6d>
f0104659:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f010465c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104660:	79 89                	jns    f01045eb <vprintfmt+0x6d>
f0104662:	e9 77 ff ff ff       	jmp    f01045de <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104667:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010466a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010466c:	e9 7a ff ff ff       	jmp    f01045eb <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104671:	8b 45 14             	mov    0x14(%ebp),%eax
f0104674:	8d 50 04             	lea    0x4(%eax),%edx
f0104677:	89 55 14             	mov    %edx,0x14(%ebp)
f010467a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010467e:	8b 00                	mov    (%eax),%eax
f0104680:	89 04 24             	mov    %eax,(%esp)
f0104683:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104686:	e9 18 ff ff ff       	jmp    f01045a3 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010468b:	8b 45 14             	mov    0x14(%ebp),%eax
f010468e:	8d 50 04             	lea    0x4(%eax),%edx
f0104691:	89 55 14             	mov    %edx,0x14(%ebp)
f0104694:	8b 00                	mov    (%eax),%eax
f0104696:	99                   	cltd   
f0104697:	31 d0                	xor    %edx,%eax
f0104699:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010469b:	83 f8 07             	cmp    $0x7,%eax
f010469e:	7f 0b                	jg     f01046ab <vprintfmt+0x12d>
f01046a0:	8b 14 85 60 69 10 f0 	mov    -0xfef96a0(,%eax,4),%edx
f01046a7:	85 d2                	test   %edx,%edx
f01046a9:	75 20                	jne    f01046cb <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f01046ab:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01046af:	c7 44 24 08 6f 67 10 	movl   $0xf010676f,0x8(%esp)
f01046b6:	f0 
f01046b7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01046bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01046be:	89 04 24             	mov    %eax,(%esp)
f01046c1:	e8 90 fe ff ff       	call   f0104556 <printfmt>
f01046c6:	e9 d8 fe ff ff       	jmp    f01045a3 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f01046cb:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01046cf:	c7 44 24 08 ed 5e 10 	movl   $0xf0105eed,0x8(%esp)
f01046d6:	f0 
f01046d7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01046db:	8b 45 08             	mov    0x8(%ebp),%eax
f01046de:	89 04 24             	mov    %eax,(%esp)
f01046e1:	e8 70 fe ff ff       	call   f0104556 <printfmt>
f01046e6:	e9 b8 fe ff ff       	jmp    f01045a3 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01046eb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01046ee:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01046f1:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01046f4:	8b 45 14             	mov    0x14(%ebp),%eax
f01046f7:	8d 50 04             	lea    0x4(%eax),%edx
f01046fa:	89 55 14             	mov    %edx,0x14(%ebp)
f01046fd:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f01046ff:	85 f6                	test   %esi,%esi
f0104701:	b8 68 67 10 f0       	mov    $0xf0106768,%eax
f0104706:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0104709:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010470d:	0f 84 97 00 00 00    	je     f01047aa <vprintfmt+0x22c>
f0104713:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0104717:	0f 8e 9b 00 00 00    	jle    f01047b8 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f010471d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104721:	89 34 24             	mov    %esi,(%esp)
f0104724:	e8 9f 03 00 00       	call   f0104ac8 <strnlen>
f0104729:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010472c:	29 c2                	sub    %eax,%edx
f010472e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0104731:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0104735:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0104738:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010473b:	8b 75 08             	mov    0x8(%ebp),%esi
f010473e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0104741:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104743:	eb 0f                	jmp    f0104754 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0104745:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104749:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010474c:	89 04 24             	mov    %eax,(%esp)
f010474f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104751:	83 eb 01             	sub    $0x1,%ebx
f0104754:	85 db                	test   %ebx,%ebx
f0104756:	7f ed                	jg     f0104745 <vprintfmt+0x1c7>
f0104758:	8b 75 d8             	mov    -0x28(%ebp),%esi
f010475b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010475e:	85 d2                	test   %edx,%edx
f0104760:	b8 00 00 00 00       	mov    $0x0,%eax
f0104765:	0f 49 c2             	cmovns %edx,%eax
f0104768:	29 c2                	sub    %eax,%edx
f010476a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010476d:	89 d7                	mov    %edx,%edi
f010476f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104772:	eb 50                	jmp    f01047c4 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104774:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104778:	74 1e                	je     f0104798 <vprintfmt+0x21a>
f010477a:	0f be d2             	movsbl %dl,%edx
f010477d:	83 ea 20             	sub    $0x20,%edx
f0104780:	83 fa 5e             	cmp    $0x5e,%edx
f0104783:	76 13                	jbe    f0104798 <vprintfmt+0x21a>
					putch('?', putdat);
f0104785:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104788:	89 44 24 04          	mov    %eax,0x4(%esp)
f010478c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0104793:	ff 55 08             	call   *0x8(%ebp)
f0104796:	eb 0d                	jmp    f01047a5 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0104798:	8b 55 0c             	mov    0xc(%ebp),%edx
f010479b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010479f:	89 04 24             	mov    %eax,(%esp)
f01047a2:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01047a5:	83 ef 01             	sub    $0x1,%edi
f01047a8:	eb 1a                	jmp    f01047c4 <vprintfmt+0x246>
f01047aa:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01047ad:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01047b0:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01047b3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01047b6:	eb 0c                	jmp    f01047c4 <vprintfmt+0x246>
f01047b8:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01047bb:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01047be:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01047c1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01047c4:	83 c6 01             	add    $0x1,%esi
f01047c7:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f01047cb:	0f be c2             	movsbl %dl,%eax
f01047ce:	85 c0                	test   %eax,%eax
f01047d0:	74 27                	je     f01047f9 <vprintfmt+0x27b>
f01047d2:	85 db                	test   %ebx,%ebx
f01047d4:	78 9e                	js     f0104774 <vprintfmt+0x1f6>
f01047d6:	83 eb 01             	sub    $0x1,%ebx
f01047d9:	79 99                	jns    f0104774 <vprintfmt+0x1f6>
f01047db:	89 f8                	mov    %edi,%eax
f01047dd:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01047e0:	8b 75 08             	mov    0x8(%ebp),%esi
f01047e3:	89 c3                	mov    %eax,%ebx
f01047e5:	eb 1a                	jmp    f0104801 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01047e7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01047eb:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01047f2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01047f4:	83 eb 01             	sub    $0x1,%ebx
f01047f7:	eb 08                	jmp    f0104801 <vprintfmt+0x283>
f01047f9:	89 fb                	mov    %edi,%ebx
f01047fb:	8b 75 08             	mov    0x8(%ebp),%esi
f01047fe:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104801:	85 db                	test   %ebx,%ebx
f0104803:	7f e2                	jg     f01047e7 <vprintfmt+0x269>
f0104805:	89 75 08             	mov    %esi,0x8(%ebp)
f0104808:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010480b:	e9 93 fd ff ff       	jmp    f01045a3 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104810:	83 fa 01             	cmp    $0x1,%edx
f0104813:	7e 16                	jle    f010482b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0104815:	8b 45 14             	mov    0x14(%ebp),%eax
f0104818:	8d 50 08             	lea    0x8(%eax),%edx
f010481b:	89 55 14             	mov    %edx,0x14(%ebp)
f010481e:	8b 50 04             	mov    0x4(%eax),%edx
f0104821:	8b 00                	mov    (%eax),%eax
f0104823:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104826:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104829:	eb 32                	jmp    f010485d <vprintfmt+0x2df>
	else if (lflag)
f010482b:	85 d2                	test   %edx,%edx
f010482d:	74 18                	je     f0104847 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010482f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104832:	8d 50 04             	lea    0x4(%eax),%edx
f0104835:	89 55 14             	mov    %edx,0x14(%ebp)
f0104838:	8b 30                	mov    (%eax),%esi
f010483a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010483d:	89 f0                	mov    %esi,%eax
f010483f:	c1 f8 1f             	sar    $0x1f,%eax
f0104842:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104845:	eb 16                	jmp    f010485d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0104847:	8b 45 14             	mov    0x14(%ebp),%eax
f010484a:	8d 50 04             	lea    0x4(%eax),%edx
f010484d:	89 55 14             	mov    %edx,0x14(%ebp)
f0104850:	8b 30                	mov    (%eax),%esi
f0104852:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0104855:	89 f0                	mov    %esi,%eax
f0104857:	c1 f8 1f             	sar    $0x1f,%eax
f010485a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010485d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104860:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0104863:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104868:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010486c:	0f 89 80 00 00 00    	jns    f01048f2 <vprintfmt+0x374>
				putch('-', putdat);
f0104872:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104876:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010487d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0104880:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104883:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104886:	f7 d8                	neg    %eax
f0104888:	83 d2 00             	adc    $0x0,%edx
f010488b:	f7 da                	neg    %edx
			}
			base = 10;
f010488d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0104892:	eb 5e                	jmp    f01048f2 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104894:	8d 45 14             	lea    0x14(%ebp),%eax
f0104897:	e8 63 fc ff ff       	call   f01044ff <getuint>
			base = 10;
f010489c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01048a1:	eb 4f                	jmp    f01048f2 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01048a3:	8d 45 14             	lea    0x14(%ebp),%eax
f01048a6:	e8 54 fc ff ff       	call   f01044ff <getuint>
			base = 8;
f01048ab:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01048b0:	eb 40                	jmp    f01048f2 <vprintfmt+0x374>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f01048b2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01048b6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01048bd:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01048c0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01048c4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01048cb:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01048ce:	8b 45 14             	mov    0x14(%ebp),%eax
f01048d1:	8d 50 04             	lea    0x4(%eax),%edx
f01048d4:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01048d7:	8b 00                	mov    (%eax),%eax
f01048d9:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01048de:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01048e3:	eb 0d                	jmp    f01048f2 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01048e5:	8d 45 14             	lea    0x14(%ebp),%eax
f01048e8:	e8 12 fc ff ff       	call   f01044ff <getuint>
			base = 16;
f01048ed:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01048f2:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f01048f6:	89 74 24 10          	mov    %esi,0x10(%esp)
f01048fa:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01048fd:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0104901:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104905:	89 04 24             	mov    %eax,(%esp)
f0104908:	89 54 24 04          	mov    %edx,0x4(%esp)
f010490c:	89 fa                	mov    %edi,%edx
f010490e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104911:	e8 fa fa ff ff       	call   f0104410 <printnum>
			break;
f0104916:	e9 88 fc ff ff       	jmp    f01045a3 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010491b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010491f:	89 04 24             	mov    %eax,(%esp)
f0104922:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104925:	e9 79 fc ff ff       	jmp    f01045a3 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010492a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010492e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0104935:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104938:	89 f3                	mov    %esi,%ebx
f010493a:	eb 03                	jmp    f010493f <vprintfmt+0x3c1>
f010493c:	83 eb 01             	sub    $0x1,%ebx
f010493f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0104943:	75 f7                	jne    f010493c <vprintfmt+0x3be>
f0104945:	e9 59 fc ff ff       	jmp    f01045a3 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010494a:	83 c4 3c             	add    $0x3c,%esp
f010494d:	5b                   	pop    %ebx
f010494e:	5e                   	pop    %esi
f010494f:	5f                   	pop    %edi
f0104950:	5d                   	pop    %ebp
f0104951:	c3                   	ret    

f0104952 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104952:	55                   	push   %ebp
f0104953:	89 e5                	mov    %esp,%ebp
f0104955:	83 ec 28             	sub    $0x28,%esp
f0104958:	8b 45 08             	mov    0x8(%ebp),%eax
f010495b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010495e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104961:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104965:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104968:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010496f:	85 c0                	test   %eax,%eax
f0104971:	74 30                	je     f01049a3 <vsnprintf+0x51>
f0104973:	85 d2                	test   %edx,%edx
f0104975:	7e 2c                	jle    f01049a3 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104977:	8b 45 14             	mov    0x14(%ebp),%eax
f010497a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010497e:	8b 45 10             	mov    0x10(%ebp),%eax
f0104981:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104985:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104988:	89 44 24 04          	mov    %eax,0x4(%esp)
f010498c:	c7 04 24 39 45 10 f0 	movl   $0xf0104539,(%esp)
f0104993:	e8 e6 fb ff ff       	call   f010457e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104998:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010499b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010499e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01049a1:	eb 05                	jmp    f01049a8 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01049a3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01049a8:	c9                   	leave  
f01049a9:	c3                   	ret    

f01049aa <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01049aa:	55                   	push   %ebp
f01049ab:	89 e5                	mov    %esp,%ebp
f01049ad:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01049b0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01049b3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01049b7:	8b 45 10             	mov    0x10(%ebp),%eax
f01049ba:	89 44 24 08          	mov    %eax,0x8(%esp)
f01049be:	8b 45 0c             	mov    0xc(%ebp),%eax
f01049c1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01049c5:	8b 45 08             	mov    0x8(%ebp),%eax
f01049c8:	89 04 24             	mov    %eax,(%esp)
f01049cb:	e8 82 ff ff ff       	call   f0104952 <vsnprintf>
	va_end(ap);

	return rc;
}
f01049d0:	c9                   	leave  
f01049d1:	c3                   	ret    
f01049d2:	66 90                	xchg   %ax,%ax
f01049d4:	66 90                	xchg   %ax,%ax
f01049d6:	66 90                	xchg   %ax,%ax
f01049d8:	66 90                	xchg   %ax,%ax
f01049da:	66 90                	xchg   %ax,%ax
f01049dc:	66 90                	xchg   %ax,%ax
f01049de:	66 90                	xchg   %ax,%ax

f01049e0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01049e0:	55                   	push   %ebp
f01049e1:	89 e5                	mov    %esp,%ebp
f01049e3:	57                   	push   %edi
f01049e4:	56                   	push   %esi
f01049e5:	53                   	push   %ebx
f01049e6:	83 ec 1c             	sub    $0x1c,%esp
f01049e9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01049ec:	85 c0                	test   %eax,%eax
f01049ee:	74 10                	je     f0104a00 <readline+0x20>
		cprintf("%s", prompt);
f01049f0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01049f4:	c7 04 24 ed 5e 10 f0 	movl   $0xf0105eed,(%esp)
f01049fb:	e8 0d ef ff ff       	call   f010390d <cprintf>

	i = 0;
	echoing = iscons(0);
f0104a00:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0104a07:	e8 26 bc ff ff       	call   f0100632 <iscons>
f0104a0c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104a0e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104a13:	e8 09 bc ff ff       	call   f0100621 <getchar>
f0104a18:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104a1a:	85 c0                	test   %eax,%eax
f0104a1c:	79 17                	jns    f0104a35 <readline+0x55>
			cprintf("read error: %e\n", c);
f0104a1e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104a22:	c7 04 24 80 69 10 f0 	movl   $0xf0106980,(%esp)
f0104a29:	e8 df ee ff ff       	call   f010390d <cprintf>
			return NULL;
f0104a2e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a33:	eb 6d                	jmp    f0104aa2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104a35:	83 f8 7f             	cmp    $0x7f,%eax
f0104a38:	74 05                	je     f0104a3f <readline+0x5f>
f0104a3a:	83 f8 08             	cmp    $0x8,%eax
f0104a3d:	75 19                	jne    f0104a58 <readline+0x78>
f0104a3f:	85 f6                	test   %esi,%esi
f0104a41:	7e 15                	jle    f0104a58 <readline+0x78>
			if (echoing)
f0104a43:	85 ff                	test   %edi,%edi
f0104a45:	74 0c                	je     f0104a53 <readline+0x73>
				cputchar('\b');
f0104a47:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0104a4e:	e8 be bb ff ff       	call   f0100611 <cputchar>
			i--;
f0104a53:	83 ee 01             	sub    $0x1,%esi
f0104a56:	eb bb                	jmp    f0104a13 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104a58:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104a5e:	7f 1c                	jg     f0104a7c <readline+0x9c>
f0104a60:	83 fb 1f             	cmp    $0x1f,%ebx
f0104a63:	7e 17                	jle    f0104a7c <readline+0x9c>
			if (echoing)
f0104a65:	85 ff                	test   %edi,%edi
f0104a67:	74 08                	je     f0104a71 <readline+0x91>
				cputchar(c);
f0104a69:	89 1c 24             	mov    %ebx,(%esp)
f0104a6c:	e8 a0 bb ff ff       	call   f0100611 <cputchar>
			buf[i++] = c;
f0104a71:	88 9e 80 eb 17 f0    	mov    %bl,-0xfe81480(%esi)
f0104a77:	8d 76 01             	lea    0x1(%esi),%esi
f0104a7a:	eb 97                	jmp    f0104a13 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0104a7c:	83 fb 0d             	cmp    $0xd,%ebx
f0104a7f:	74 05                	je     f0104a86 <readline+0xa6>
f0104a81:	83 fb 0a             	cmp    $0xa,%ebx
f0104a84:	75 8d                	jne    f0104a13 <readline+0x33>
			if (echoing)
f0104a86:	85 ff                	test   %edi,%edi
f0104a88:	74 0c                	je     f0104a96 <readline+0xb6>
				cputchar('\n');
f0104a8a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0104a91:	e8 7b bb ff ff       	call   f0100611 <cputchar>
			buf[i] = 0;
f0104a96:	c6 86 80 eb 17 f0 00 	movb   $0x0,-0xfe81480(%esi)
			return buf;
f0104a9d:	b8 80 eb 17 f0       	mov    $0xf017eb80,%eax
		}
	}
}
f0104aa2:	83 c4 1c             	add    $0x1c,%esp
f0104aa5:	5b                   	pop    %ebx
f0104aa6:	5e                   	pop    %esi
f0104aa7:	5f                   	pop    %edi
f0104aa8:	5d                   	pop    %ebp
f0104aa9:	c3                   	ret    
f0104aaa:	66 90                	xchg   %ax,%ax
f0104aac:	66 90                	xchg   %ax,%ax
f0104aae:	66 90                	xchg   %ax,%ax

f0104ab0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104ab0:	55                   	push   %ebp
f0104ab1:	89 e5                	mov    %esp,%ebp
f0104ab3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104ab6:	b8 00 00 00 00       	mov    $0x0,%eax
f0104abb:	eb 03                	jmp    f0104ac0 <strlen+0x10>
		n++;
f0104abd:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104ac0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104ac4:	75 f7                	jne    f0104abd <strlen+0xd>
		n++;
	return n;
}
f0104ac6:	5d                   	pop    %ebp
f0104ac7:	c3                   	ret    

f0104ac8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104ac8:	55                   	push   %ebp
f0104ac9:	89 e5                	mov    %esp,%ebp
f0104acb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104ace:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104ad1:	b8 00 00 00 00       	mov    $0x0,%eax
f0104ad6:	eb 03                	jmp    f0104adb <strnlen+0x13>
		n++;
f0104ad8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104adb:	39 d0                	cmp    %edx,%eax
f0104add:	74 06                	je     f0104ae5 <strnlen+0x1d>
f0104adf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0104ae3:	75 f3                	jne    f0104ad8 <strnlen+0x10>
		n++;
	return n;
}
f0104ae5:	5d                   	pop    %ebp
f0104ae6:	c3                   	ret    

f0104ae7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104ae7:	55                   	push   %ebp
f0104ae8:	89 e5                	mov    %esp,%ebp
f0104aea:	53                   	push   %ebx
f0104aeb:	8b 45 08             	mov    0x8(%ebp),%eax
f0104aee:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104af1:	89 c2                	mov    %eax,%edx
f0104af3:	83 c2 01             	add    $0x1,%edx
f0104af6:	83 c1 01             	add    $0x1,%ecx
f0104af9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104afd:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104b00:	84 db                	test   %bl,%bl
f0104b02:	75 ef                	jne    f0104af3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104b04:	5b                   	pop    %ebx
f0104b05:	5d                   	pop    %ebp
f0104b06:	c3                   	ret    

f0104b07 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104b07:	55                   	push   %ebp
f0104b08:	89 e5                	mov    %esp,%ebp
f0104b0a:	53                   	push   %ebx
f0104b0b:	83 ec 08             	sub    $0x8,%esp
f0104b0e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104b11:	89 1c 24             	mov    %ebx,(%esp)
f0104b14:	e8 97 ff ff ff       	call   f0104ab0 <strlen>
	strcpy(dst + len, src);
f0104b19:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104b1c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104b20:	01 d8                	add    %ebx,%eax
f0104b22:	89 04 24             	mov    %eax,(%esp)
f0104b25:	e8 bd ff ff ff       	call   f0104ae7 <strcpy>
	return dst;
}
f0104b2a:	89 d8                	mov    %ebx,%eax
f0104b2c:	83 c4 08             	add    $0x8,%esp
f0104b2f:	5b                   	pop    %ebx
f0104b30:	5d                   	pop    %ebp
f0104b31:	c3                   	ret    

f0104b32 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104b32:	55                   	push   %ebp
f0104b33:	89 e5                	mov    %esp,%ebp
f0104b35:	56                   	push   %esi
f0104b36:	53                   	push   %ebx
f0104b37:	8b 75 08             	mov    0x8(%ebp),%esi
f0104b3a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104b3d:	89 f3                	mov    %esi,%ebx
f0104b3f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104b42:	89 f2                	mov    %esi,%edx
f0104b44:	eb 0f                	jmp    f0104b55 <strncpy+0x23>
		*dst++ = *src;
f0104b46:	83 c2 01             	add    $0x1,%edx
f0104b49:	0f b6 01             	movzbl (%ecx),%eax
f0104b4c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104b4f:	80 39 01             	cmpb   $0x1,(%ecx)
f0104b52:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104b55:	39 da                	cmp    %ebx,%edx
f0104b57:	75 ed                	jne    f0104b46 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104b59:	89 f0                	mov    %esi,%eax
f0104b5b:	5b                   	pop    %ebx
f0104b5c:	5e                   	pop    %esi
f0104b5d:	5d                   	pop    %ebp
f0104b5e:	c3                   	ret    

f0104b5f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104b5f:	55                   	push   %ebp
f0104b60:	89 e5                	mov    %esp,%ebp
f0104b62:	56                   	push   %esi
f0104b63:	53                   	push   %ebx
f0104b64:	8b 75 08             	mov    0x8(%ebp),%esi
f0104b67:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104b6a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104b6d:	89 f0                	mov    %esi,%eax
f0104b6f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104b73:	85 c9                	test   %ecx,%ecx
f0104b75:	75 0b                	jne    f0104b82 <strlcpy+0x23>
f0104b77:	eb 1d                	jmp    f0104b96 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104b79:	83 c0 01             	add    $0x1,%eax
f0104b7c:	83 c2 01             	add    $0x1,%edx
f0104b7f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104b82:	39 d8                	cmp    %ebx,%eax
f0104b84:	74 0b                	je     f0104b91 <strlcpy+0x32>
f0104b86:	0f b6 0a             	movzbl (%edx),%ecx
f0104b89:	84 c9                	test   %cl,%cl
f0104b8b:	75 ec                	jne    f0104b79 <strlcpy+0x1a>
f0104b8d:	89 c2                	mov    %eax,%edx
f0104b8f:	eb 02                	jmp    f0104b93 <strlcpy+0x34>
f0104b91:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0104b93:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0104b96:	29 f0                	sub    %esi,%eax
}
f0104b98:	5b                   	pop    %ebx
f0104b99:	5e                   	pop    %esi
f0104b9a:	5d                   	pop    %ebp
f0104b9b:	c3                   	ret    

f0104b9c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104b9c:	55                   	push   %ebp
f0104b9d:	89 e5                	mov    %esp,%ebp
f0104b9f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104ba2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104ba5:	eb 06                	jmp    f0104bad <strcmp+0x11>
		p++, q++;
f0104ba7:	83 c1 01             	add    $0x1,%ecx
f0104baa:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104bad:	0f b6 01             	movzbl (%ecx),%eax
f0104bb0:	84 c0                	test   %al,%al
f0104bb2:	74 04                	je     f0104bb8 <strcmp+0x1c>
f0104bb4:	3a 02                	cmp    (%edx),%al
f0104bb6:	74 ef                	je     f0104ba7 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104bb8:	0f b6 c0             	movzbl %al,%eax
f0104bbb:	0f b6 12             	movzbl (%edx),%edx
f0104bbe:	29 d0                	sub    %edx,%eax
}
f0104bc0:	5d                   	pop    %ebp
f0104bc1:	c3                   	ret    

f0104bc2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104bc2:	55                   	push   %ebp
f0104bc3:	89 e5                	mov    %esp,%ebp
f0104bc5:	53                   	push   %ebx
f0104bc6:	8b 45 08             	mov    0x8(%ebp),%eax
f0104bc9:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104bcc:	89 c3                	mov    %eax,%ebx
f0104bce:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104bd1:	eb 06                	jmp    f0104bd9 <strncmp+0x17>
		n--, p++, q++;
f0104bd3:	83 c0 01             	add    $0x1,%eax
f0104bd6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104bd9:	39 d8                	cmp    %ebx,%eax
f0104bdb:	74 15                	je     f0104bf2 <strncmp+0x30>
f0104bdd:	0f b6 08             	movzbl (%eax),%ecx
f0104be0:	84 c9                	test   %cl,%cl
f0104be2:	74 04                	je     f0104be8 <strncmp+0x26>
f0104be4:	3a 0a                	cmp    (%edx),%cl
f0104be6:	74 eb                	je     f0104bd3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104be8:	0f b6 00             	movzbl (%eax),%eax
f0104beb:	0f b6 12             	movzbl (%edx),%edx
f0104bee:	29 d0                	sub    %edx,%eax
f0104bf0:	eb 05                	jmp    f0104bf7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104bf2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104bf7:	5b                   	pop    %ebx
f0104bf8:	5d                   	pop    %ebp
f0104bf9:	c3                   	ret    

f0104bfa <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104bfa:	55                   	push   %ebp
f0104bfb:	89 e5                	mov    %esp,%ebp
f0104bfd:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c00:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104c04:	eb 07                	jmp    f0104c0d <strchr+0x13>
		if (*s == c)
f0104c06:	38 ca                	cmp    %cl,%dl
f0104c08:	74 0f                	je     f0104c19 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104c0a:	83 c0 01             	add    $0x1,%eax
f0104c0d:	0f b6 10             	movzbl (%eax),%edx
f0104c10:	84 d2                	test   %dl,%dl
f0104c12:	75 f2                	jne    f0104c06 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104c14:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104c19:	5d                   	pop    %ebp
f0104c1a:	c3                   	ret    

f0104c1b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104c1b:	55                   	push   %ebp
f0104c1c:	89 e5                	mov    %esp,%ebp
f0104c1e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c21:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104c25:	eb 07                	jmp    f0104c2e <strfind+0x13>
		if (*s == c)
f0104c27:	38 ca                	cmp    %cl,%dl
f0104c29:	74 0a                	je     f0104c35 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0104c2b:	83 c0 01             	add    $0x1,%eax
f0104c2e:	0f b6 10             	movzbl (%eax),%edx
f0104c31:	84 d2                	test   %dl,%dl
f0104c33:	75 f2                	jne    f0104c27 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0104c35:	5d                   	pop    %ebp
f0104c36:	c3                   	ret    

f0104c37 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104c37:	55                   	push   %ebp
f0104c38:	89 e5                	mov    %esp,%ebp
f0104c3a:	57                   	push   %edi
f0104c3b:	56                   	push   %esi
f0104c3c:	53                   	push   %ebx
f0104c3d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104c40:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104c43:	85 c9                	test   %ecx,%ecx
f0104c45:	74 36                	je     f0104c7d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104c47:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104c4d:	75 28                	jne    f0104c77 <memset+0x40>
f0104c4f:	f6 c1 03             	test   $0x3,%cl
f0104c52:	75 23                	jne    f0104c77 <memset+0x40>
		c &= 0xFF;
f0104c54:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104c58:	89 d3                	mov    %edx,%ebx
f0104c5a:	c1 e3 08             	shl    $0x8,%ebx
f0104c5d:	89 d6                	mov    %edx,%esi
f0104c5f:	c1 e6 18             	shl    $0x18,%esi
f0104c62:	89 d0                	mov    %edx,%eax
f0104c64:	c1 e0 10             	shl    $0x10,%eax
f0104c67:	09 f0                	or     %esi,%eax
f0104c69:	09 c2                	or     %eax,%edx
f0104c6b:	89 d0                	mov    %edx,%eax
f0104c6d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0104c6f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0104c72:	fc                   	cld    
f0104c73:	f3 ab                	rep stos %eax,%es:(%edi)
f0104c75:	eb 06                	jmp    f0104c7d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104c77:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104c7a:	fc                   	cld    
f0104c7b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104c7d:	89 f8                	mov    %edi,%eax
f0104c7f:	5b                   	pop    %ebx
f0104c80:	5e                   	pop    %esi
f0104c81:	5f                   	pop    %edi
f0104c82:	5d                   	pop    %ebp
f0104c83:	c3                   	ret    

f0104c84 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104c84:	55                   	push   %ebp
f0104c85:	89 e5                	mov    %esp,%ebp
f0104c87:	57                   	push   %edi
f0104c88:	56                   	push   %esi
f0104c89:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c8c:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104c8f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104c92:	39 c6                	cmp    %eax,%esi
f0104c94:	73 35                	jae    f0104ccb <memmove+0x47>
f0104c96:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104c99:	39 d0                	cmp    %edx,%eax
f0104c9b:	73 2e                	jae    f0104ccb <memmove+0x47>
		s += n;
		d += n;
f0104c9d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0104ca0:	89 d6                	mov    %edx,%esi
f0104ca2:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104ca4:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104caa:	75 13                	jne    f0104cbf <memmove+0x3b>
f0104cac:	f6 c1 03             	test   $0x3,%cl
f0104caf:	75 0e                	jne    f0104cbf <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104cb1:	83 ef 04             	sub    $0x4,%edi
f0104cb4:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104cb7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0104cba:	fd                   	std    
f0104cbb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104cbd:	eb 09                	jmp    f0104cc8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0104cbf:	83 ef 01             	sub    $0x1,%edi
f0104cc2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104cc5:	fd                   	std    
f0104cc6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104cc8:	fc                   	cld    
f0104cc9:	eb 1d                	jmp    f0104ce8 <memmove+0x64>
f0104ccb:	89 f2                	mov    %esi,%edx
f0104ccd:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104ccf:	f6 c2 03             	test   $0x3,%dl
f0104cd2:	75 0f                	jne    f0104ce3 <memmove+0x5f>
f0104cd4:	f6 c1 03             	test   $0x3,%cl
f0104cd7:	75 0a                	jne    f0104ce3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0104cd9:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0104cdc:	89 c7                	mov    %eax,%edi
f0104cde:	fc                   	cld    
f0104cdf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104ce1:	eb 05                	jmp    f0104ce8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104ce3:	89 c7                	mov    %eax,%edi
f0104ce5:	fc                   	cld    
f0104ce6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104ce8:	5e                   	pop    %esi
f0104ce9:	5f                   	pop    %edi
f0104cea:	5d                   	pop    %ebp
f0104ceb:	c3                   	ret    

f0104cec <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104cec:	55                   	push   %ebp
f0104ced:	89 e5                	mov    %esp,%ebp
f0104cef:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0104cf2:	8b 45 10             	mov    0x10(%ebp),%eax
f0104cf5:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104cf9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104cfc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104d00:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d03:	89 04 24             	mov    %eax,(%esp)
f0104d06:	e8 79 ff ff ff       	call   f0104c84 <memmove>
}
f0104d0b:	c9                   	leave  
f0104d0c:	c3                   	ret    

f0104d0d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104d0d:	55                   	push   %ebp
f0104d0e:	89 e5                	mov    %esp,%ebp
f0104d10:	56                   	push   %esi
f0104d11:	53                   	push   %ebx
f0104d12:	8b 55 08             	mov    0x8(%ebp),%edx
f0104d15:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104d18:	89 d6                	mov    %edx,%esi
f0104d1a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104d1d:	eb 1a                	jmp    f0104d39 <memcmp+0x2c>
		if (*s1 != *s2)
f0104d1f:	0f b6 02             	movzbl (%edx),%eax
f0104d22:	0f b6 19             	movzbl (%ecx),%ebx
f0104d25:	38 d8                	cmp    %bl,%al
f0104d27:	74 0a                	je     f0104d33 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104d29:	0f b6 c0             	movzbl %al,%eax
f0104d2c:	0f b6 db             	movzbl %bl,%ebx
f0104d2f:	29 d8                	sub    %ebx,%eax
f0104d31:	eb 0f                	jmp    f0104d42 <memcmp+0x35>
		s1++, s2++;
f0104d33:	83 c2 01             	add    $0x1,%edx
f0104d36:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104d39:	39 f2                	cmp    %esi,%edx
f0104d3b:	75 e2                	jne    f0104d1f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104d3d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104d42:	5b                   	pop    %ebx
f0104d43:	5e                   	pop    %esi
f0104d44:	5d                   	pop    %ebp
f0104d45:	c3                   	ret    

f0104d46 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104d46:	55                   	push   %ebp
f0104d47:	89 e5                	mov    %esp,%ebp
f0104d49:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d4c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0104d4f:	89 c2                	mov    %eax,%edx
f0104d51:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104d54:	eb 07                	jmp    f0104d5d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104d56:	38 08                	cmp    %cl,(%eax)
f0104d58:	74 07                	je     f0104d61 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104d5a:	83 c0 01             	add    $0x1,%eax
f0104d5d:	39 d0                	cmp    %edx,%eax
f0104d5f:	72 f5                	jb     f0104d56 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104d61:	5d                   	pop    %ebp
f0104d62:	c3                   	ret    

f0104d63 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104d63:	55                   	push   %ebp
f0104d64:	89 e5                	mov    %esp,%ebp
f0104d66:	57                   	push   %edi
f0104d67:	56                   	push   %esi
f0104d68:	53                   	push   %ebx
f0104d69:	8b 55 08             	mov    0x8(%ebp),%edx
f0104d6c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104d6f:	eb 03                	jmp    f0104d74 <strtol+0x11>
		s++;
f0104d71:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104d74:	0f b6 0a             	movzbl (%edx),%ecx
f0104d77:	80 f9 09             	cmp    $0x9,%cl
f0104d7a:	74 f5                	je     f0104d71 <strtol+0xe>
f0104d7c:	80 f9 20             	cmp    $0x20,%cl
f0104d7f:	74 f0                	je     f0104d71 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104d81:	80 f9 2b             	cmp    $0x2b,%cl
f0104d84:	75 0a                	jne    f0104d90 <strtol+0x2d>
		s++;
f0104d86:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104d89:	bf 00 00 00 00       	mov    $0x0,%edi
f0104d8e:	eb 11                	jmp    f0104da1 <strtol+0x3e>
f0104d90:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104d95:	80 f9 2d             	cmp    $0x2d,%cl
f0104d98:	75 07                	jne    f0104da1 <strtol+0x3e>
		s++, neg = 1;
f0104d9a:	8d 52 01             	lea    0x1(%edx),%edx
f0104d9d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104da1:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0104da6:	75 15                	jne    f0104dbd <strtol+0x5a>
f0104da8:	80 3a 30             	cmpb   $0x30,(%edx)
f0104dab:	75 10                	jne    f0104dbd <strtol+0x5a>
f0104dad:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0104db1:	75 0a                	jne    f0104dbd <strtol+0x5a>
		s += 2, base = 16;
f0104db3:	83 c2 02             	add    $0x2,%edx
f0104db6:	b8 10 00 00 00       	mov    $0x10,%eax
f0104dbb:	eb 10                	jmp    f0104dcd <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f0104dbd:	85 c0                	test   %eax,%eax
f0104dbf:	75 0c                	jne    f0104dcd <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104dc1:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104dc3:	80 3a 30             	cmpb   $0x30,(%edx)
f0104dc6:	75 05                	jne    f0104dcd <strtol+0x6a>
		s++, base = 8;
f0104dc8:	83 c2 01             	add    $0x1,%edx
f0104dcb:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f0104dcd:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104dd2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104dd5:	0f b6 0a             	movzbl (%edx),%ecx
f0104dd8:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0104ddb:	89 f0                	mov    %esi,%eax
f0104ddd:	3c 09                	cmp    $0x9,%al
f0104ddf:	77 08                	ja     f0104de9 <strtol+0x86>
			dig = *s - '0';
f0104de1:	0f be c9             	movsbl %cl,%ecx
f0104de4:	83 e9 30             	sub    $0x30,%ecx
f0104de7:	eb 20                	jmp    f0104e09 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0104de9:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0104dec:	89 f0                	mov    %esi,%eax
f0104dee:	3c 19                	cmp    $0x19,%al
f0104df0:	77 08                	ja     f0104dfa <strtol+0x97>
			dig = *s - 'a' + 10;
f0104df2:	0f be c9             	movsbl %cl,%ecx
f0104df5:	83 e9 57             	sub    $0x57,%ecx
f0104df8:	eb 0f                	jmp    f0104e09 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0104dfa:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0104dfd:	89 f0                	mov    %esi,%eax
f0104dff:	3c 19                	cmp    $0x19,%al
f0104e01:	77 16                	ja     f0104e19 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0104e03:	0f be c9             	movsbl %cl,%ecx
f0104e06:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0104e09:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0104e0c:	7d 0f                	jge    f0104e1d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f0104e0e:	83 c2 01             	add    $0x1,%edx
f0104e11:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0104e15:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0104e17:	eb bc                	jmp    f0104dd5 <strtol+0x72>
f0104e19:	89 d8                	mov    %ebx,%eax
f0104e1b:	eb 02                	jmp    f0104e1f <strtol+0xbc>
f0104e1d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0104e1f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104e23:	74 05                	je     f0104e2a <strtol+0xc7>
		*endptr = (char *) s;
f0104e25:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104e28:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0104e2a:	f7 d8                	neg    %eax
f0104e2c:	85 ff                	test   %edi,%edi
f0104e2e:	0f 44 c3             	cmove  %ebx,%eax
}
f0104e31:	5b                   	pop    %ebx
f0104e32:	5e                   	pop    %esi
f0104e33:	5f                   	pop    %edi
f0104e34:	5d                   	pop    %ebp
f0104e35:	c3                   	ret    
f0104e36:	66 90                	xchg   %ax,%ax
f0104e38:	66 90                	xchg   %ax,%ax
f0104e3a:	66 90                	xchg   %ax,%ax
f0104e3c:	66 90                	xchg   %ax,%ax
f0104e3e:	66 90                	xchg   %ax,%ax

f0104e40 <__udivdi3>:
f0104e40:	55                   	push   %ebp
f0104e41:	57                   	push   %edi
f0104e42:	56                   	push   %esi
f0104e43:	83 ec 0c             	sub    $0xc,%esp
f0104e46:	8b 44 24 28          	mov    0x28(%esp),%eax
f0104e4a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0104e4e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0104e52:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0104e56:	85 c0                	test   %eax,%eax
f0104e58:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104e5c:	89 ea                	mov    %ebp,%edx
f0104e5e:	89 0c 24             	mov    %ecx,(%esp)
f0104e61:	75 2d                	jne    f0104e90 <__udivdi3+0x50>
f0104e63:	39 e9                	cmp    %ebp,%ecx
f0104e65:	77 61                	ja     f0104ec8 <__udivdi3+0x88>
f0104e67:	85 c9                	test   %ecx,%ecx
f0104e69:	89 ce                	mov    %ecx,%esi
f0104e6b:	75 0b                	jne    f0104e78 <__udivdi3+0x38>
f0104e6d:	b8 01 00 00 00       	mov    $0x1,%eax
f0104e72:	31 d2                	xor    %edx,%edx
f0104e74:	f7 f1                	div    %ecx
f0104e76:	89 c6                	mov    %eax,%esi
f0104e78:	31 d2                	xor    %edx,%edx
f0104e7a:	89 e8                	mov    %ebp,%eax
f0104e7c:	f7 f6                	div    %esi
f0104e7e:	89 c5                	mov    %eax,%ebp
f0104e80:	89 f8                	mov    %edi,%eax
f0104e82:	f7 f6                	div    %esi
f0104e84:	89 ea                	mov    %ebp,%edx
f0104e86:	83 c4 0c             	add    $0xc,%esp
f0104e89:	5e                   	pop    %esi
f0104e8a:	5f                   	pop    %edi
f0104e8b:	5d                   	pop    %ebp
f0104e8c:	c3                   	ret    
f0104e8d:	8d 76 00             	lea    0x0(%esi),%esi
f0104e90:	39 e8                	cmp    %ebp,%eax
f0104e92:	77 24                	ja     f0104eb8 <__udivdi3+0x78>
f0104e94:	0f bd e8             	bsr    %eax,%ebp
f0104e97:	83 f5 1f             	xor    $0x1f,%ebp
f0104e9a:	75 3c                	jne    f0104ed8 <__udivdi3+0x98>
f0104e9c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0104ea0:	39 34 24             	cmp    %esi,(%esp)
f0104ea3:	0f 86 9f 00 00 00    	jbe    f0104f48 <__udivdi3+0x108>
f0104ea9:	39 d0                	cmp    %edx,%eax
f0104eab:	0f 82 97 00 00 00    	jb     f0104f48 <__udivdi3+0x108>
f0104eb1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104eb8:	31 d2                	xor    %edx,%edx
f0104eba:	31 c0                	xor    %eax,%eax
f0104ebc:	83 c4 0c             	add    $0xc,%esp
f0104ebf:	5e                   	pop    %esi
f0104ec0:	5f                   	pop    %edi
f0104ec1:	5d                   	pop    %ebp
f0104ec2:	c3                   	ret    
f0104ec3:	90                   	nop
f0104ec4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104ec8:	89 f8                	mov    %edi,%eax
f0104eca:	f7 f1                	div    %ecx
f0104ecc:	31 d2                	xor    %edx,%edx
f0104ece:	83 c4 0c             	add    $0xc,%esp
f0104ed1:	5e                   	pop    %esi
f0104ed2:	5f                   	pop    %edi
f0104ed3:	5d                   	pop    %ebp
f0104ed4:	c3                   	ret    
f0104ed5:	8d 76 00             	lea    0x0(%esi),%esi
f0104ed8:	89 e9                	mov    %ebp,%ecx
f0104eda:	8b 3c 24             	mov    (%esp),%edi
f0104edd:	d3 e0                	shl    %cl,%eax
f0104edf:	89 c6                	mov    %eax,%esi
f0104ee1:	b8 20 00 00 00       	mov    $0x20,%eax
f0104ee6:	29 e8                	sub    %ebp,%eax
f0104ee8:	89 c1                	mov    %eax,%ecx
f0104eea:	d3 ef                	shr    %cl,%edi
f0104eec:	89 e9                	mov    %ebp,%ecx
f0104eee:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0104ef2:	8b 3c 24             	mov    (%esp),%edi
f0104ef5:	09 74 24 08          	or     %esi,0x8(%esp)
f0104ef9:	89 d6                	mov    %edx,%esi
f0104efb:	d3 e7                	shl    %cl,%edi
f0104efd:	89 c1                	mov    %eax,%ecx
f0104eff:	89 3c 24             	mov    %edi,(%esp)
f0104f02:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0104f06:	d3 ee                	shr    %cl,%esi
f0104f08:	89 e9                	mov    %ebp,%ecx
f0104f0a:	d3 e2                	shl    %cl,%edx
f0104f0c:	89 c1                	mov    %eax,%ecx
f0104f0e:	d3 ef                	shr    %cl,%edi
f0104f10:	09 d7                	or     %edx,%edi
f0104f12:	89 f2                	mov    %esi,%edx
f0104f14:	89 f8                	mov    %edi,%eax
f0104f16:	f7 74 24 08          	divl   0x8(%esp)
f0104f1a:	89 d6                	mov    %edx,%esi
f0104f1c:	89 c7                	mov    %eax,%edi
f0104f1e:	f7 24 24             	mull   (%esp)
f0104f21:	39 d6                	cmp    %edx,%esi
f0104f23:	89 14 24             	mov    %edx,(%esp)
f0104f26:	72 30                	jb     f0104f58 <__udivdi3+0x118>
f0104f28:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104f2c:	89 e9                	mov    %ebp,%ecx
f0104f2e:	d3 e2                	shl    %cl,%edx
f0104f30:	39 c2                	cmp    %eax,%edx
f0104f32:	73 05                	jae    f0104f39 <__udivdi3+0xf9>
f0104f34:	3b 34 24             	cmp    (%esp),%esi
f0104f37:	74 1f                	je     f0104f58 <__udivdi3+0x118>
f0104f39:	89 f8                	mov    %edi,%eax
f0104f3b:	31 d2                	xor    %edx,%edx
f0104f3d:	e9 7a ff ff ff       	jmp    f0104ebc <__udivdi3+0x7c>
f0104f42:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104f48:	31 d2                	xor    %edx,%edx
f0104f4a:	b8 01 00 00 00       	mov    $0x1,%eax
f0104f4f:	e9 68 ff ff ff       	jmp    f0104ebc <__udivdi3+0x7c>
f0104f54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104f58:	8d 47 ff             	lea    -0x1(%edi),%eax
f0104f5b:	31 d2                	xor    %edx,%edx
f0104f5d:	83 c4 0c             	add    $0xc,%esp
f0104f60:	5e                   	pop    %esi
f0104f61:	5f                   	pop    %edi
f0104f62:	5d                   	pop    %ebp
f0104f63:	c3                   	ret    
f0104f64:	66 90                	xchg   %ax,%ax
f0104f66:	66 90                	xchg   %ax,%ax
f0104f68:	66 90                	xchg   %ax,%ax
f0104f6a:	66 90                	xchg   %ax,%ax
f0104f6c:	66 90                	xchg   %ax,%ax
f0104f6e:	66 90                	xchg   %ax,%ax

f0104f70 <__umoddi3>:
f0104f70:	55                   	push   %ebp
f0104f71:	57                   	push   %edi
f0104f72:	56                   	push   %esi
f0104f73:	83 ec 14             	sub    $0x14,%esp
f0104f76:	8b 44 24 28          	mov    0x28(%esp),%eax
f0104f7a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0104f7e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0104f82:	89 c7                	mov    %eax,%edi
f0104f84:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104f88:	8b 44 24 30          	mov    0x30(%esp),%eax
f0104f8c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0104f90:	89 34 24             	mov    %esi,(%esp)
f0104f93:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104f97:	85 c0                	test   %eax,%eax
f0104f99:	89 c2                	mov    %eax,%edx
f0104f9b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104f9f:	75 17                	jne    f0104fb8 <__umoddi3+0x48>
f0104fa1:	39 fe                	cmp    %edi,%esi
f0104fa3:	76 4b                	jbe    f0104ff0 <__umoddi3+0x80>
f0104fa5:	89 c8                	mov    %ecx,%eax
f0104fa7:	89 fa                	mov    %edi,%edx
f0104fa9:	f7 f6                	div    %esi
f0104fab:	89 d0                	mov    %edx,%eax
f0104fad:	31 d2                	xor    %edx,%edx
f0104faf:	83 c4 14             	add    $0x14,%esp
f0104fb2:	5e                   	pop    %esi
f0104fb3:	5f                   	pop    %edi
f0104fb4:	5d                   	pop    %ebp
f0104fb5:	c3                   	ret    
f0104fb6:	66 90                	xchg   %ax,%ax
f0104fb8:	39 f8                	cmp    %edi,%eax
f0104fba:	77 54                	ja     f0105010 <__umoddi3+0xa0>
f0104fbc:	0f bd e8             	bsr    %eax,%ebp
f0104fbf:	83 f5 1f             	xor    $0x1f,%ebp
f0104fc2:	75 5c                	jne    f0105020 <__umoddi3+0xb0>
f0104fc4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0104fc8:	39 3c 24             	cmp    %edi,(%esp)
f0104fcb:	0f 87 e7 00 00 00    	ja     f01050b8 <__umoddi3+0x148>
f0104fd1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0104fd5:	29 f1                	sub    %esi,%ecx
f0104fd7:	19 c7                	sbb    %eax,%edi
f0104fd9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104fdd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104fe1:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104fe5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0104fe9:	83 c4 14             	add    $0x14,%esp
f0104fec:	5e                   	pop    %esi
f0104fed:	5f                   	pop    %edi
f0104fee:	5d                   	pop    %ebp
f0104fef:	c3                   	ret    
f0104ff0:	85 f6                	test   %esi,%esi
f0104ff2:	89 f5                	mov    %esi,%ebp
f0104ff4:	75 0b                	jne    f0105001 <__umoddi3+0x91>
f0104ff6:	b8 01 00 00 00       	mov    $0x1,%eax
f0104ffb:	31 d2                	xor    %edx,%edx
f0104ffd:	f7 f6                	div    %esi
f0104fff:	89 c5                	mov    %eax,%ebp
f0105001:	8b 44 24 04          	mov    0x4(%esp),%eax
f0105005:	31 d2                	xor    %edx,%edx
f0105007:	f7 f5                	div    %ebp
f0105009:	89 c8                	mov    %ecx,%eax
f010500b:	f7 f5                	div    %ebp
f010500d:	eb 9c                	jmp    f0104fab <__umoddi3+0x3b>
f010500f:	90                   	nop
f0105010:	89 c8                	mov    %ecx,%eax
f0105012:	89 fa                	mov    %edi,%edx
f0105014:	83 c4 14             	add    $0x14,%esp
f0105017:	5e                   	pop    %esi
f0105018:	5f                   	pop    %edi
f0105019:	5d                   	pop    %ebp
f010501a:	c3                   	ret    
f010501b:	90                   	nop
f010501c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105020:	8b 04 24             	mov    (%esp),%eax
f0105023:	be 20 00 00 00       	mov    $0x20,%esi
f0105028:	89 e9                	mov    %ebp,%ecx
f010502a:	29 ee                	sub    %ebp,%esi
f010502c:	d3 e2                	shl    %cl,%edx
f010502e:	89 f1                	mov    %esi,%ecx
f0105030:	d3 e8                	shr    %cl,%eax
f0105032:	89 e9                	mov    %ebp,%ecx
f0105034:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105038:	8b 04 24             	mov    (%esp),%eax
f010503b:	09 54 24 04          	or     %edx,0x4(%esp)
f010503f:	89 fa                	mov    %edi,%edx
f0105041:	d3 e0                	shl    %cl,%eax
f0105043:	89 f1                	mov    %esi,%ecx
f0105045:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105049:	8b 44 24 10          	mov    0x10(%esp),%eax
f010504d:	d3 ea                	shr    %cl,%edx
f010504f:	89 e9                	mov    %ebp,%ecx
f0105051:	d3 e7                	shl    %cl,%edi
f0105053:	89 f1                	mov    %esi,%ecx
f0105055:	d3 e8                	shr    %cl,%eax
f0105057:	89 e9                	mov    %ebp,%ecx
f0105059:	09 f8                	or     %edi,%eax
f010505b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010505f:	f7 74 24 04          	divl   0x4(%esp)
f0105063:	d3 e7                	shl    %cl,%edi
f0105065:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0105069:	89 d7                	mov    %edx,%edi
f010506b:	f7 64 24 08          	mull   0x8(%esp)
f010506f:	39 d7                	cmp    %edx,%edi
f0105071:	89 c1                	mov    %eax,%ecx
f0105073:	89 14 24             	mov    %edx,(%esp)
f0105076:	72 2c                	jb     f01050a4 <__umoddi3+0x134>
f0105078:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010507c:	72 22                	jb     f01050a0 <__umoddi3+0x130>
f010507e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0105082:	29 c8                	sub    %ecx,%eax
f0105084:	19 d7                	sbb    %edx,%edi
f0105086:	89 e9                	mov    %ebp,%ecx
f0105088:	89 fa                	mov    %edi,%edx
f010508a:	d3 e8                	shr    %cl,%eax
f010508c:	89 f1                	mov    %esi,%ecx
f010508e:	d3 e2                	shl    %cl,%edx
f0105090:	89 e9                	mov    %ebp,%ecx
f0105092:	d3 ef                	shr    %cl,%edi
f0105094:	09 d0                	or     %edx,%eax
f0105096:	89 fa                	mov    %edi,%edx
f0105098:	83 c4 14             	add    $0x14,%esp
f010509b:	5e                   	pop    %esi
f010509c:	5f                   	pop    %edi
f010509d:	5d                   	pop    %ebp
f010509e:	c3                   	ret    
f010509f:	90                   	nop
f01050a0:	39 d7                	cmp    %edx,%edi
f01050a2:	75 da                	jne    f010507e <__umoddi3+0x10e>
f01050a4:	8b 14 24             	mov    (%esp),%edx
f01050a7:	89 c1                	mov    %eax,%ecx
f01050a9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f01050ad:	1b 54 24 04          	sbb    0x4(%esp),%edx
f01050b1:	eb cb                	jmp    f010507e <__umoddi3+0x10e>
f01050b3:	90                   	nop
f01050b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01050b8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f01050bc:	0f 82 0f ff ff ff    	jb     f0104fd1 <__umoddi3+0x61>
f01050c2:	e9 1a ff ff ff       	jmp    f0104fe1 <__umoddi3+0x71>
