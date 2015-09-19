
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
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 90 df 17 f0       	mov    $0xf017df90,%eax
f010004b:	2d 65 d0 17 f0       	sub    $0xf017d065,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 65 d0 17 f0 	movl   $0xf017d065,(%esp)
f0100063:	e8 af 48 00 00       	call   f0104917 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 b2 04 00 00       	call   f010051f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 c0 4d 10 f0 	movl   $0xf0104dc0,(%esp)
f010007c:	e8 2b 37 00 00       	call   f01037ac <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 de 12 00 00       	call   f0101364 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100086:	e8 99 30 00 00       	call   f0103124 <env_init>
	trap_init();
f010008b:	90                   	nop
f010008c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100090:	e8 98 37 00 00       	call   f010382d <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100095:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010009c:	00 
f010009d:	c7 04 24 d4 0d 14 f0 	movl   $0xf0140dd4,(%esp)
f01000a4:	e8 4f 32 00 00       	call   f01032f8 <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000a9:	a1 cc d2 17 f0       	mov    0xf017d2cc,%eax
f01000ae:	89 04 24             	mov    %eax,(%esp)
f01000b1:	e8 0e 36 00 00       	call   f01036c4 <env_run>

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
f01000c1:	83 3d 80 df 17 f0 00 	cmpl   $0x0,0xf017df80
f01000c8:	75 3d                	jne    f0100107 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000ca:	89 35 80 df 17 f0    	mov    %esi,0xf017df80

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
f01000e3:	c7 04 24 db 4d 10 f0 	movl   $0xf0104ddb,(%esp)
f01000ea:	e8 bd 36 00 00       	call   f01037ac <cprintf>
	vcprintf(fmt, ap);
f01000ef:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000f3:	89 34 24             	mov    %esi,(%esp)
f01000f6:	e8 7e 36 00 00       	call   f0103779 <vcprintf>
	cprintf("\n");
f01000fb:	c7 04 24 3c 5e 10 f0 	movl   $0xf0105e3c,(%esp)
f0100102:	e8 a5 36 00 00       	call   f01037ac <cprintf>
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
f010012d:	c7 04 24 f3 4d 10 f0 	movl   $0xf0104df3,(%esp)
f0100134:	e8 73 36 00 00       	call   f01037ac <cprintf>
	vcprintf(fmt, ap);
f0100139:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010013d:	8b 45 10             	mov    0x10(%ebp),%eax
f0100140:	89 04 24             	mov    %eax,(%esp)
f0100143:	e8 31 36 00 00       	call   f0103779 <vcprintf>
	cprintf("\n");
f0100148:	c7 04 24 3c 5e 10 f0 	movl   $0xf0105e3c,(%esp)
f010014f:	e8 58 36 00 00       	call   f01037ac <cprintf>
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
f010018b:	a1 a4 d2 17 f0       	mov    0xf017d2a4,%eax
f0100190:	8d 48 01             	lea    0x1(%eax),%ecx
f0100193:	89 0d a4 d2 17 f0    	mov    %ecx,0xf017d2a4
f0100199:	88 90 a0 d0 17 f0    	mov    %dl,-0xfe82f60(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010019f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001a5:	75 0a                	jne    f01001b1 <cons_intr+0x35>
			cons.wpos = 0;
f01001a7:	c7 05 a4 d2 17 f0 00 	movl   $0x0,0xf017d2a4
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
f01001d7:	83 0d 80 d0 17 f0 40 	orl    $0x40,0xf017d080
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
f01001ef:	8b 0d 80 d0 17 f0    	mov    0xf017d080,%ecx
f01001f5:	89 cb                	mov    %ecx,%ebx
f01001f7:	83 e3 40             	and    $0x40,%ebx
f01001fa:	83 e0 7f             	and    $0x7f,%eax
f01001fd:	85 db                	test   %ebx,%ebx
f01001ff:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100202:	0f b6 d2             	movzbl %dl,%edx
f0100205:	0f b6 82 60 4f 10 f0 	movzbl -0xfefb0a0(%edx),%eax
f010020c:	83 c8 40             	or     $0x40,%eax
f010020f:	0f b6 c0             	movzbl %al,%eax
f0100212:	f7 d0                	not    %eax
f0100214:	21 c1                	and    %eax,%ecx
f0100216:	89 0d 80 d0 17 f0    	mov    %ecx,0xf017d080
		return 0;
f010021c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100221:	e9 9d 00 00 00       	jmp    f01002c3 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100226:	8b 0d 80 d0 17 f0    	mov    0xf017d080,%ecx
f010022c:	f6 c1 40             	test   $0x40,%cl
f010022f:	74 0e                	je     f010023f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100231:	83 c8 80             	or     $0xffffff80,%eax
f0100234:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100236:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100239:	89 0d 80 d0 17 f0    	mov    %ecx,0xf017d080
	}

	shift |= shiftcode[data];
f010023f:	0f b6 d2             	movzbl %dl,%edx
f0100242:	0f b6 82 60 4f 10 f0 	movzbl -0xfefb0a0(%edx),%eax
f0100249:	0b 05 80 d0 17 f0    	or     0xf017d080,%eax
	shift ^= togglecode[data];
f010024f:	0f b6 8a 60 4e 10 f0 	movzbl -0xfefb1a0(%edx),%ecx
f0100256:	31 c8                	xor    %ecx,%eax
f0100258:	a3 80 d0 17 f0       	mov    %eax,0xf017d080

	c = charcode[shift & (CTL | SHIFT)][data];
f010025d:	89 c1                	mov    %eax,%ecx
f010025f:	83 e1 03             	and    $0x3,%ecx
f0100262:	8b 0c 8d 40 4e 10 f0 	mov    -0xfefb1c0(,%ecx,4),%ecx
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
f01002a2:	c7 04 24 0d 4e 10 f0 	movl   $0xf0104e0d,(%esp)
f01002a9:	e8 fe 34 00 00       	call   f01037ac <cprintf>
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
f010037c:	0f b7 05 a8 d2 17 f0 	movzwl 0xf017d2a8,%eax
f0100383:	66 85 c0             	test   %ax,%ax
f0100386:	0f 84 e5 00 00 00    	je     f0100471 <cons_putc+0x1a8>
			crt_pos--;
f010038c:	83 e8 01             	sub    $0x1,%eax
f010038f:	66 a3 a8 d2 17 f0    	mov    %ax,0xf017d2a8
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100395:	0f b7 c0             	movzwl %ax,%eax
f0100398:	66 81 e7 00 ff       	and    $0xff00,%di
f010039d:	83 cf 20             	or     $0x20,%edi
f01003a0:	8b 15 ac d2 17 f0    	mov    0xf017d2ac,%edx
f01003a6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003aa:	eb 78                	jmp    f0100424 <cons_putc+0x15b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003ac:	66 83 05 a8 d2 17 f0 	addw   $0x50,0xf017d2a8
f01003b3:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003b4:	0f b7 05 a8 d2 17 f0 	movzwl 0xf017d2a8,%eax
f01003bb:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003c1:	c1 e8 16             	shr    $0x16,%eax
f01003c4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003c7:	c1 e0 04             	shl    $0x4,%eax
f01003ca:	66 a3 a8 d2 17 f0    	mov    %ax,0xf017d2a8
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
f0100406:	0f b7 05 a8 d2 17 f0 	movzwl 0xf017d2a8,%eax
f010040d:	8d 50 01             	lea    0x1(%eax),%edx
f0100410:	66 89 15 a8 d2 17 f0 	mov    %dx,0xf017d2a8
f0100417:	0f b7 c0             	movzwl %ax,%eax
f010041a:	8b 15 ac d2 17 f0    	mov    0xf017d2ac,%edx
f0100420:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100424:	66 81 3d a8 d2 17 f0 	cmpw   $0x7cf,0xf017d2a8
f010042b:	cf 07 
f010042d:	76 42                	jbe    f0100471 <cons_putc+0x1a8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010042f:	a1 ac d2 17 f0       	mov    0xf017d2ac,%eax
f0100434:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010043b:	00 
f010043c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100442:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100446:	89 04 24             	mov    %eax,(%esp)
f0100449:	e8 16 45 00 00       	call   f0104964 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010044e:	8b 15 ac d2 17 f0    	mov    0xf017d2ac,%edx
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
f0100469:	66 83 2d a8 d2 17 f0 	subw   $0x50,0xf017d2a8
f0100470:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100471:	8b 0d b0 d2 17 f0    	mov    0xf017d2b0,%ecx
f0100477:	b8 0e 00 00 00       	mov    $0xe,%eax
f010047c:	89 ca                	mov    %ecx,%edx
f010047e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010047f:	0f b7 1d a8 d2 17 f0 	movzwl 0xf017d2a8,%ebx
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
f01004a7:	80 3d b4 d2 17 f0 00 	cmpb   $0x0,0xf017d2b4
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
f01004e5:	a1 a0 d2 17 f0       	mov    0xf017d2a0,%eax
f01004ea:	3b 05 a4 d2 17 f0    	cmp    0xf017d2a4,%eax
f01004f0:	74 26                	je     f0100518 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004f2:	8d 50 01             	lea    0x1(%eax),%edx
f01004f5:	89 15 a0 d2 17 f0    	mov    %edx,0xf017d2a0
f01004fb:	0f b6 88 a0 d0 17 f0 	movzbl -0xfe82f60(%eax),%ecx
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
f010050c:	c7 05 a0 d2 17 f0 00 	movl   $0x0,0xf017d2a0
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
f0100545:	c7 05 b0 d2 17 f0 b4 	movl   $0x3b4,0xf017d2b0
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
f010055d:	c7 05 b0 d2 17 f0 d4 	movl   $0x3d4,0xf017d2b0
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
f010056c:	8b 0d b0 d2 17 f0    	mov    0xf017d2b0,%ecx
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
f0100591:	89 3d ac d2 17 f0    	mov    %edi,0xf017d2ac

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100597:	0f b6 d8             	movzbl %al,%ebx
f010059a:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f010059c:	66 89 35 a8 d2 17 f0 	mov    %si,0xf017d2a8
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
f01005ed:	88 0d b4 d2 17 f0    	mov    %cl,0xf017d2b4
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
f01005fd:	c7 04 24 19 4e 10 f0 	movl   $0xf0104e19,(%esp)
f0100604:	e8 a3 31 00 00       	call   f01037ac <cprintf>
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
f0100646:	c7 44 24 08 60 50 10 	movl   $0xf0105060,0x8(%esp)
f010064d:	f0 
f010064e:	c7 44 24 04 7e 50 10 	movl   $0xf010507e,0x4(%esp)
f0100655:	f0 
f0100656:	c7 04 24 83 50 10 f0 	movl   $0xf0105083,(%esp)
f010065d:	e8 4a 31 00 00       	call   f01037ac <cprintf>
f0100662:	c7 44 24 08 24 51 10 	movl   $0xf0105124,0x8(%esp)
f0100669:	f0 
f010066a:	c7 44 24 04 8c 50 10 	movl   $0xf010508c,0x4(%esp)
f0100671:	f0 
f0100672:	c7 04 24 83 50 10 f0 	movl   $0xf0105083,(%esp)
f0100679:	e8 2e 31 00 00       	call   f01037ac <cprintf>
f010067e:	c7 44 24 08 95 50 10 	movl   $0xf0105095,0x8(%esp)
f0100685:	f0 
f0100686:	c7 44 24 04 b2 50 10 	movl   $0xf01050b2,0x4(%esp)
f010068d:	f0 
f010068e:	c7 04 24 83 50 10 f0 	movl   $0xf0105083,(%esp)
f0100695:	e8 12 31 00 00       	call   f01037ac <cprintf>
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
f01006a7:	c7 04 24 bd 50 10 f0 	movl   $0xf01050bd,(%esp)
f01006ae:	e8 f9 30 00 00       	call   f01037ac <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006b3:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006ba:	00 
f01006bb:	c7 04 24 4c 51 10 f0 	movl   $0xf010514c,(%esp)
f01006c2:	e8 e5 30 00 00       	call   f01037ac <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006c7:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006ce:	00 
f01006cf:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006d6:	f0 
f01006d7:	c7 04 24 74 51 10 f0 	movl   $0xf0105174,(%esp)
f01006de:	e8 c9 30 00 00       	call   f01037ac <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006e3:	c7 44 24 08 a7 4d 10 	movl   $0x104da7,0x8(%esp)
f01006ea:	00 
f01006eb:	c7 44 24 04 a7 4d 10 	movl   $0xf0104da7,0x4(%esp)
f01006f2:	f0 
f01006f3:	c7 04 24 98 51 10 f0 	movl   $0xf0105198,(%esp)
f01006fa:	e8 ad 30 00 00       	call   f01037ac <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ff:	c7 44 24 08 65 d0 17 	movl   $0x17d065,0x8(%esp)
f0100706:	00 
f0100707:	c7 44 24 04 65 d0 17 	movl   $0xf017d065,0x4(%esp)
f010070e:	f0 
f010070f:	c7 04 24 bc 51 10 f0 	movl   $0xf01051bc,(%esp)
f0100716:	e8 91 30 00 00       	call   f01037ac <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010071b:	c7 44 24 08 90 df 17 	movl   $0x17df90,0x8(%esp)
f0100722:	00 
f0100723:	c7 44 24 04 90 df 17 	movl   $0xf017df90,0x4(%esp)
f010072a:	f0 
f010072b:	c7 04 24 e0 51 10 f0 	movl   $0xf01051e0,(%esp)
f0100732:	e8 75 30 00 00       	call   f01037ac <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100737:	b8 8f e3 17 f0       	mov    $0xf017e38f,%eax
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
f0100758:	c7 04 24 04 52 10 f0 	movl   $0xf0105204,(%esp)
f010075f:	e8 48 30 00 00       	call   f01037ac <cprintf>
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
f0100776:	c7 04 24 d6 50 10 f0 	movl   $0xf01050d6,(%esp)
f010077d:	e8 2a 30 00 00       	call   f01037ac <cprintf>
	
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
f0100791:	e8 07 37 00 00       	call   f0103e9d <debuginfo_eip>
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
f01007e6:	c7 04 24 30 52 10 f0 	movl   $0xf0105230,(%esp)
f01007ed:	e8 ba 2f 00 00       	call   f01037ac <cprintf>
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
f010080e:	c7 04 24 74 52 10 f0 	movl   $0xf0105274,(%esp)
f0100815:	e8 92 2f 00 00       	call   f01037ac <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010081a:	c7 04 24 98 52 10 f0 	movl   $0xf0105298,(%esp)
f0100821:	e8 86 2f 00 00       	call   f01037ac <cprintf>

	if (tf != NULL)
f0100826:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010082a:	74 0b                	je     f0100837 <monitor+0x32>
		print_trapframe(tf);
f010082c:	8b 45 08             	mov    0x8(%ebp),%eax
f010082f:	89 04 24             	mov    %eax,(%esp)
f0100832:	e8 3e 31 00 00       	call   f0103975 <print_trapframe>

	while (1) {
		buf = readline("K> ");
f0100837:	c7 04 24 e8 50 10 f0 	movl   $0xf01050e8,(%esp)
f010083e:	e8 7d 3e 00 00       	call   f01046c0 <readline>
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
f010086f:	c7 04 24 ec 50 10 f0 	movl   $0xf01050ec,(%esp)
f0100876:	e8 5f 40 00 00       	call   f01048da <strchr>
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
f0100891:	c7 04 24 f1 50 10 f0 	movl   $0xf01050f1,(%esp)
f0100898:	e8 0f 2f 00 00       	call   f01037ac <cprintf>
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
f01008b9:	c7 04 24 ec 50 10 f0 	movl   $0xf01050ec,(%esp)
f01008c0:	e8 15 40 00 00       	call   f01048da <strchr>
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
f01008e3:	8b 04 85 c0 52 10 f0 	mov    -0xfefad40(,%eax,4),%eax
f01008ea:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008ee:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008f1:	89 04 24             	mov    %eax,(%esp)
f01008f4:	e8 83 3f 00 00       	call   f010487c <strcmp>
f01008f9:	85 c0                	test   %eax,%eax
f01008fb:	75 24                	jne    f0100921 <monitor+0x11c>
			return commands[i].func(argc, argv, tf);
f01008fd:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100900:	8b 55 08             	mov    0x8(%ebp),%edx
f0100903:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100907:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f010090a:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010090e:	89 34 24             	mov    %esi,(%esp)
f0100911:	ff 14 85 c8 52 10 f0 	call   *-0xfefad38(,%eax,4)
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
f0100930:	c7 04 24 0e 51 10 f0 	movl   $0xf010510e,(%esp)
f0100937:	e8 70 2e 00 00       	call   f01037ac <cprintf>
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
f0100950:	2b 05 8c df 17 f0    	sub    0xf017df8c,%eax
f0100956:	c1 f8 03             	sar    $0x3,%eax
f0100959:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010095c:	89 c2                	mov    %eax,%edx
f010095e:	c1 ea 0c             	shr    $0xc,%edx
f0100961:	3b 15 84 df 17 f0    	cmp    0xf017df84,%edx
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
f0100973:	c7 44 24 08 e4 52 10 	movl   $0xf01052e4,0x8(%esp)
f010097a:	f0 
f010097b:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100982:	00 
f0100983:	c7 04 24 5d 5b 10 f0 	movl   $0xf0105b5d,(%esp)
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
f01009ab:	3b 0d 84 df 17 f0    	cmp    0xf017df84,%ecx
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
f01009bd:	c7 44 24 08 e4 52 10 	movl   $0xf01052e4,0x8(%esp)
f01009c4:	f0 
f01009c5:	c7 44 24 04 7a 03 00 	movl   $0x37a,0x4(%esp)
f01009cc:	00 
f01009cd:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
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
f0100a04:	83 3d bc d2 17 f0 00 	cmpl   $0x0,0xf017d2bc
f0100a0b:	75 11                	jne    f0100a1e <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE); // Roundup function rounds according to the given functions
f0100a0d:	ba 8f ef 17 f0       	mov    $0xf017ef8f,%edx
f0100a12:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a18:	89 15 bc d2 17 f0    	mov    %edx,0xf017d2bc
	}
	
	if (n==0){
f0100a1e:	85 c0                	test   %eax,%eax
f0100a20:	75 06                	jne    f0100a28 <boot_alloc+0x24>
	return nextfree;
f0100a22:	a1 bc d2 17 f0       	mov    0xf017d2bc,%eax
f0100a27:	c3                   	ret    
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result  = nextfree;
f0100a28:	8b 0d bc d2 17 f0    	mov    0xf017d2bc,%ecx
	nextfree += ROUNDUP(n,PGSIZE);
f0100a2e:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100a34:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a3a:	01 ca                	add    %ecx,%edx
f0100a3c:	89 15 bc d2 17 f0    	mov    %edx,0xf017d2bc
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
f0100a54:	c7 44 24 08 08 53 10 	movl   $0xf0105308,0x8(%esp)
f0100a5b:	f0 
f0100a5c:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
f0100a63:	00 
f0100a64:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0100a6b:	e8 46 f6 ff ff       	call   f01000b6 <_panic>
	// LAB 2: Your code here.
	result  = nextfree;
	nextfree += ROUNDUP(n,PGSIZE);
	
	
	if ((PADDR(nextfree))>npages*PGSIZE){
f0100a70:	a1 84 df 17 f0       	mov    0xf017df84,%eax
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
f0100aa2:	c7 44 24 08 2c 53 10 	movl   $0xf010532c,0x8(%esp)
f0100aa9:	f0 
f0100aaa:	c7 44 24 04 b7 02 00 	movl   $0x2b7,0x4(%esp)
f0100ab1:	00 
f0100ab2:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
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
f0100acc:	2b 15 8c df 17 f0    	sub    0xf017df8c,%edx
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
f0100b02:	a3 c0 d2 17 f0       	mov    %eax,0xf017d2c0
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
f0100b0c:	8b 1d c0 d2 17 f0    	mov    0xf017d2c0,%ebx
f0100b12:	eb 63                	jmp    f0100b77 <check_page_free_list+0xee>
f0100b14:	89 d8                	mov    %ebx,%eax
f0100b16:	2b 05 8c df 17 f0    	sub    0xf017df8c,%eax
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
f0100b30:	3b 15 84 df 17 f0    	cmp    0xf017df84,%edx
f0100b36:	72 20                	jb     f0100b58 <check_page_free_list+0xcf>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b38:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b3c:	c7 44 24 08 e4 52 10 	movl   $0xf01052e4,0x8(%esp)
f0100b43:	f0 
f0100b44:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100b4b:	00 
f0100b4c:	c7 04 24 5d 5b 10 f0 	movl   $0xf0105b5d,(%esp)
f0100b53:	e8 5e f5 ff ff       	call   f01000b6 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b58:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b5f:	00 
f0100b60:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b67:	00 
	return (void *)(pa + KERNBASE);
f0100b68:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b6d:	89 04 24             	mov    %eax,(%esp)
f0100b70:	e8 a2 3d 00 00       	call   f0104917 <memset>
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
f0100b88:	8b 15 c0 d2 17 f0    	mov    0xf017d2c0,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b8e:	8b 0d 8c df 17 f0    	mov    0xf017df8c,%ecx
		assert(pp < pages + npages);
f0100b94:	a1 84 df 17 f0       	mov    0xf017df84,%eax
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
f0100bb6:	c7 44 24 0c 77 5b 10 	movl   $0xf0105b77,0xc(%esp)
f0100bbd:	f0 
f0100bbe:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0100bc5:	f0 
f0100bc6:	c7 44 24 04 d1 02 00 	movl   $0x2d1,0x4(%esp)
f0100bcd:	00 
f0100bce:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0100bd5:	e8 dc f4 ff ff       	call   f01000b6 <_panic>
		assert(pp < pages + npages);
f0100bda:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bdd:	72 24                	jb     f0100c03 <check_page_free_list+0x17a>
f0100bdf:	c7 44 24 0c 98 5b 10 	movl   $0xf0105b98,0xc(%esp)
f0100be6:	f0 
f0100be7:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0100bee:	f0 
f0100bef:	c7 44 24 04 d2 02 00 	movl   $0x2d2,0x4(%esp)
f0100bf6:	00 
f0100bf7:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0100bfe:	e8 b3 f4 ff ff       	call   f01000b6 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c03:	89 d0                	mov    %edx,%eax
f0100c05:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c08:	a8 07                	test   $0x7,%al
f0100c0a:	74 24                	je     f0100c30 <check_page_free_list+0x1a7>
f0100c0c:	c7 44 24 0c 50 53 10 	movl   $0xf0105350,0xc(%esp)
f0100c13:	f0 
f0100c14:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0100c1b:	f0 
f0100c1c:	c7 44 24 04 d3 02 00 	movl   $0x2d3,0x4(%esp)
f0100c23:	00 
f0100c24:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
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
f0100c3a:	c7 44 24 0c ac 5b 10 	movl   $0xf0105bac,0xc(%esp)
f0100c41:	f0 
f0100c42:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0100c49:	f0 
f0100c4a:	c7 44 24 04 d6 02 00 	movl   $0x2d6,0x4(%esp)
f0100c51:	00 
f0100c52:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0100c59:	e8 58 f4 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c5e:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c63:	75 24                	jne    f0100c89 <check_page_free_list+0x200>
f0100c65:	c7 44 24 0c bd 5b 10 	movl   $0xf0105bbd,0xc(%esp)
f0100c6c:	f0 
f0100c6d:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0100c74:	f0 
f0100c75:	c7 44 24 04 d7 02 00 	movl   $0x2d7,0x4(%esp)
f0100c7c:	00 
f0100c7d:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0100c84:	e8 2d f4 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c89:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c8e:	75 24                	jne    f0100cb4 <check_page_free_list+0x22b>
f0100c90:	c7 44 24 0c 84 53 10 	movl   $0xf0105384,0xc(%esp)
f0100c97:	f0 
f0100c98:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0100c9f:	f0 
f0100ca0:	c7 44 24 04 d8 02 00 	movl   $0x2d8,0x4(%esp)
f0100ca7:	00 
f0100ca8:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0100caf:	e8 02 f4 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cb4:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cb9:	75 24                	jne    f0100cdf <check_page_free_list+0x256>
f0100cbb:	c7 44 24 0c d6 5b 10 	movl   $0xf0105bd6,0xc(%esp)
f0100cc2:	f0 
f0100cc3:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0100cca:	f0 
f0100ccb:	c7 44 24 04 d9 02 00 	movl   $0x2d9,0x4(%esp)
f0100cd2:	00 
f0100cd3:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
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
f0100cf4:	c7 44 24 08 e4 52 10 	movl   $0xf01052e4,0x8(%esp)
f0100cfb:	f0 
f0100cfc:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100d03:	00 
f0100d04:	c7 04 24 5d 5b 10 f0 	movl   $0xf0105b5d,(%esp)
f0100d0b:	e8 a6 f3 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0100d10:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d15:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100d18:	76 2a                	jbe    f0100d44 <check_page_free_list+0x2bb>
f0100d1a:	c7 44 24 0c a8 53 10 	movl   $0xf01053a8,0xc(%esp)
f0100d21:	f0 
f0100d22:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0100d29:	f0 
f0100d2a:	c7 44 24 04 da 02 00 	movl   $0x2da,0x4(%esp)
f0100d31:	00 
f0100d32:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
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
f0100d58:	c7 44 24 0c f0 5b 10 	movl   $0xf0105bf0,0xc(%esp)
f0100d5f:	f0 
f0100d60:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0100d67:	f0 
f0100d68:	c7 44 24 04 e2 02 00 	movl   $0x2e2,0x4(%esp)
f0100d6f:	00 
f0100d70:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0100d77:	e8 3a f3 ff ff       	call   f01000b6 <_panic>
	assert(nfree_extmem > 0);
f0100d7c:	85 ff                	test   %edi,%edi
f0100d7e:	7f 24                	jg     f0100da4 <check_page_free_list+0x31b>
f0100d80:	c7 44 24 0c 02 5c 10 	movl   $0xf0105c02,0xc(%esp)
f0100d87:	f0 
f0100d88:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0100d8f:	f0 
f0100d90:	c7 44 24 04 e3 02 00 	movl   $0x2e3,0x4(%esp)
f0100d97:	00 
f0100d98:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0100d9f:	e8 12 f3 ff ff       	call   f01000b6 <_panic>
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
f0100da4:	0f b6 45 c0          	movzbl -0x40(%ebp),%eax
f0100da8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dac:	c7 04 24 f0 53 10 f0 	movl   $0xf01053f0,(%esp)
f0100db3:	e8 f4 29 00 00       	call   f01037ac <cprintf>
f0100db8:	eb 29                	jmp    f0100de3 <check_page_free_list+0x35a>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100dba:	a1 c0 d2 17 f0       	mov    0xf017d2c0,%eax
f0100dbf:	85 c0                	test   %eax,%eax
f0100dc1:	0f 85 f7 fc ff ff    	jne    f0100abe <check_page_free_list+0x35>
f0100dc7:	e9 d6 fc ff ff       	jmp    f0100aa2 <check_page_free_list+0x19>
f0100dcc:	83 3d c0 d2 17 f0 00 	cmpl   $0x0,0xf017d2c0
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
f0100df2:	8b 15 8c df 17 f0    	mov    0xf017df8c,%edx
f0100df8:	8d 14 c2             	lea    (%edx,%eax,8),%edx
f0100dfb:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
	 pages[i].pp_link = 0; // No links to any pages
f0100e01:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100e07:	83 c0 01             	add    $0x1,%eax
f0100e0a:	3b 05 84 df 17 f0    	cmp    0xf017df84,%eax
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
f0100e1b:	8b 35 c4 d2 17 f0    	mov    0xf017d2c4,%esi
f0100e21:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100e26:	b8 01 00 00 00       	mov    $0x1,%eax
f0100e2b:	eb 39                	jmp    f0100e66 <page_init+0x7b>
f0100e2d:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100e34:	8b 0d 8c df 17 f0    	mov    0xf017df8c,%ecx
f0100e3a:	66 c7 44 11 04 00 00 	movw   $0x0,0x4(%ecx,%edx,1)
		pages[i].pp_link = 0;
f0100e41:	c7 04 c1 00 00 00 00 	movl   $0x0,(%ecx,%eax,8)

		if (!page_free_list){		
f0100e48:	85 db                	test   %ebx,%ebx
f0100e4a:	75 0a                	jne    f0100e56 <page_init+0x6b>
		page_free_list = &pages[i];	// if page_free_list is 0 then point to current page
f0100e4c:	89 d3                	mov    %edx,%ebx
f0100e4e:	03 1d 8c df 17 f0    	add    0xf017df8c,%ebx
f0100e54:	eb 0d                	jmp    f0100e63 <page_init+0x78>
		}
		else{
		pages[i-1].pp_link = &pages[i];
f0100e56:	8b 0d 8c df 17 f0    	mov    0xf017df8c,%ecx
f0100e5c:	8d 3c 11             	lea    (%ecx,%edx,1),%edi
f0100e5f:	89 7c 11 f8          	mov    %edi,-0x8(%ecx,%edx,1)

	
	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	for (i = 1; i < npages_basemem; i++) {
f0100e63:	83 c0 01             	add    $0x1,%eax
f0100e66:	39 f0                	cmp    %esi,%eax
f0100e68:	72 c3                	jb     f0100e2d <page_init+0x42>
f0100e6a:	89 1d c0 d2 17 f0    	mov    %ebx,0xf017d2c0
		}	//Previous page is linked to this current page
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
f0100e70:	8b 15 8c df 17 f0    	mov    0xf017df8c,%edx
f0100e76:	8d 44 c2 f8          	lea    -0x8(%edx,%eax,8),%eax
f0100e7a:	a3 b8 d2 17 f0       	mov    %eax,0xf017d2b8
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
f0100e94:	c7 44 24 08 08 53 10 	movl   $0xf0105308,0x8(%esp)
f0100e9b:	f0 
f0100e9c:	c7 44 24 04 39 01 00 	movl   $0x139,0x4(%esp)
f0100ea3:	00 
f0100ea4:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0100eab:	e8 06 f2 ff ff       	call   f01000b6 <_panic>
f0100eb0:	05 ff 0f 00 10       	add    $0x10000fff,%eax
f0100eb5:	c1 e8 0c             	shr    $0xc,%eax
f0100eb8:	8b 1d b8 d2 17 f0    	mov    0xf017d2b8,%ebx
f0100ebe:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100ec5:	eb 2c                	jmp    f0100ef3 <page_init+0x108>
		pages[i].pp_ref = 0;
f0100ec7:	89 d1                	mov    %edx,%ecx
f0100ec9:	03 0d 8c df 17 f0    	add    0xf017df8c,%ecx
f0100ecf:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = 0;
f0100ed5:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		track->pp_link = &pages[i];
f0100edb:	89 d1                	mov    %edx,%ecx
f0100edd:	03 0d 8c df 17 f0    	add    0xf017df8c,%ecx
f0100ee3:	89 0b                	mov    %ecx,(%ebx)
		track = &pages[i];
f0100ee5:	89 d3                	mov    %edx,%ebx
f0100ee7:	03 1d 8c df 17 f0    	add    0xf017df8c,%ebx
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100eed:	83 c0 01             	add    $0x1,%eax
f0100ef0:	83 c2 08             	add    $0x8,%edx
f0100ef3:	3b 05 84 df 17 f0    	cmp    0xf017df84,%eax
f0100ef9:	72 cc                	jb     f0100ec7 <page_init+0xdc>
f0100efb:	89 1d b8 d2 17 f0    	mov    %ebx,0xf017d2b8
		pages[i].pp_link = 0;
		track->pp_link = &pages[i];
		track = &pages[i];
	}
	
	cprintf("Check first entry of pages &pages[0] = %x\n", &pages[0]);
f0100f01:	a1 8c df 17 f0       	mov    0xf017df8c,%eax
f0100f06:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f0a:	c7 04 24 18 54 10 f0 	movl   $0xf0105418,(%esp)
f0100f11:	e8 96 28 00 00       	call   f01037ac <cprintf>
	cprintf("&pages[npages-1] = %x\n", &pages[npages-1]);
f0100f16:	a1 8c df 17 f0       	mov    0xf017df8c,%eax
f0100f1b:	8b 15 84 df 17 f0    	mov    0xf017df84,%edx
f0100f21:	8d 44 d0 f8          	lea    -0x8(%eax,%edx,8),%eax
f0100f25:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f29:	c7 04 24 13 5c 10 f0 	movl   $0xf0105c13,(%esp)
f0100f30:	e8 77 28 00 00       	call   f01037ac <cprintf>
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
f0100f44:	8b 1d c0 d2 17 f0    	mov    0xf017d2c0,%ebx
f0100f4a:	85 db                	test   %ebx,%ebx
f0100f4c:	74 75                	je     f0100fc3 <page_alloc+0x86>
	return NULL;
	}
	
	struct PageInfo *allocPage = NULL;   //Create a temporary pointer 
	allocPage = page_free_list;	//Point to the current head of free_page_list
	page_free_list = allocPage ->pp_link; //Move the head to the next avaialble page
f0100f4e:	8b 03                	mov    (%ebx),%eax
f0100f50:	a3 c0 d2 17 f0       	mov    %eax,0xf017d2c0
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
f0100f63:	2b 05 8c df 17 f0    	sub    0xf017df8c,%eax
f0100f69:	c1 f8 03             	sar    $0x3,%eax
f0100f6c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f6f:	89 c2                	mov    %eax,%edx
f0100f71:	c1 ea 0c             	shr    $0xc,%edx
f0100f74:	3b 15 84 df 17 f0    	cmp    0xf017df84,%edx
f0100f7a:	72 20                	jb     f0100f9c <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f7c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f80:	c7 44 24 08 e4 52 10 	movl   $0xf01052e4,0x8(%esp)
f0100f87:	f0 
f0100f88:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100f8f:	00 
f0100f90:	c7 04 24 5d 5b 10 f0 	movl   $0xf0105b5d,(%esp)
f0100f97:	e8 1a f1 ff ff       	call   f01000b6 <_panic>
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
f0100f9c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100fa3:	00 
f0100fa4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100fab:	00 
	return (void *)(pa + KERNBASE);
f0100fac:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100fb1:	89 04 24             	mov    %eax,(%esp)
f0100fb4:	e8 5e 39 00 00       	call   f0104917 <memset>
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
f0100fde:	c7 44 24 08 44 54 10 	movl   $0xf0105444,0x8(%esp)
f0100fe5:	f0 
f0100fe6:	c7 44 24 04 71 01 00 	movl   $0x171,0x4(%esp)
f0100fed:	00 
f0100fee:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0100ff5:	e8 bc f0 ff ff       	call   f01000b6 <_panic>
	return;
	}
	
	// pp->pp_link is not NULL.
	else if(!pp) 
f0100ffa:	85 c0                	test   %eax,%eax
f0100ffc:	75 1c                	jne    f010101a <page_free+0x4c>
	{
	panic("Page cannot be returned to free list as it is Null");
f0100ffe:	c7 44 24 08 84 54 10 	movl   $0xf0105484,0x8(%esp)
f0101005:	f0 
f0101006:	c7 44 24 04 78 01 00 	movl   $0x178,0x4(%esp)
f010100d:	00 
f010100e:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101015:	e8 9c f0 ff ff       	call   f01000b6 <_panic>
	return;
	}
	
       else{
	pp->pp_link = page_free_list;
f010101a:	8b 15 c0 d2 17 f0    	mov    0xf017d2c0,%edx
f0101020:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0101022:	a3 c0 d2 17 f0       	mov    %eax,0xf017d2c0
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
f0101076:	3b 05 84 df 17 f0    	cmp    0xf017df84,%eax
f010107c:	72 20                	jb     f010109e <pgdir_walk+0x52>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010107e:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101082:	c7 44 24 08 e4 52 10 	movl   $0xf01052e4,0x8(%esp)
f0101089:	f0 
f010108a:	c7 44 24 04 b9 01 00 	movl   $0x1b9,0x4(%esp)
f0101091:	00 
f0101092:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
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
f01010d0:	2b 3d 8c df 17 f0    	sub    0xf017df8c,%edi
f01010d6:	c1 ff 03             	sar    $0x3,%edi
f01010d9:	c1 e7 0c             	shl    $0xc,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010dc:	89 f8                	mov    %edi,%eax
f01010de:	c1 e8 0c             	shr    $0xc,%eax
f01010e1:	3b 05 84 df 17 f0    	cmp    0xf017df84,%eax
f01010e7:	72 20                	jb     f0101109 <pgdir_walk+0xbd>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010e9:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01010ed:	c7 44 24 08 e4 52 10 	movl   $0xf01052e4,0x8(%esp)
f01010f4:	f0 
f01010f5:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01010fc:	00 
f01010fd:	c7 04 24 5d 5b 10 f0 	movl   $0xf0105b5d,(%esp)
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
f0101122:	e8 f0 37 00 00       	call   f0104917 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101127:	2b 35 8c df 17 f0    	sub    0xf017df8c,%esi
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
f01011ae:	c7 44 24 08 b8 54 10 	movl   $0xf01054b8,0x8(%esp)
f01011b5:	f0 
f01011b6:	c7 44 24 04 ef 01 00 	movl   $0x1ef,0x4(%esp)
f01011bd:	00 
f01011be:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f01011c5:	e8 ec ee ff ff       	call   f01000b6 <_panic>
		}
		if (*pgTbEnt & PTE_P){
f01011ca:	f6 00 01             	testb  $0x1,(%eax)
f01011cd:	74 1c                	je     f01011eb <boot_map_region+0x90>
			panic("Page is already mapped");
f01011cf:	c7 44 24 08 2a 5c 10 	movl   $0xf0105c2a,0x8(%esp)
f01011d6:	f0 
f01011d7:	c7 44 24 04 f2 01 00 	movl   $0x1f2,0x4(%esp)
f01011de:	00 
f01011df:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
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
f0101241:	8b 0d 8c df 17 f0    	mov    0xf017df8c,%ecx
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
f01012df:	2b 15 8c df 17 f0    	sub    0xf017df8c,%edx
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
f0101317:	2b 05 8c df 17 f0    	sub    0xf017df8c,%eax
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
f010133b:	2b 05 8c df 17 f0    	sub    0xf017df8c,%eax
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
f0101374:	e8 c3 23 00 00       	call   f010373c <mc146818_read>
f0101379:	89 c3                	mov    %eax,%ebx
f010137b:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101382:	e8 b5 23 00 00       	call   f010373c <mc146818_read>
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
f010139f:	a3 c4 d2 17 f0       	mov    %eax,0xf017d2c4
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01013a4:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f01013ab:	e8 8c 23 00 00       	call   f010373c <mc146818_read>
f01013b0:	89 c3                	mov    %eax,%ebx
f01013b2:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01013b9:	e8 7e 23 00 00       	call   f010373c <mc146818_read>
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
f01013e0:	89 15 84 df 17 f0    	mov    %edx,0xf017df84
f01013e6:	eb 0c                	jmp    f01013f4 <mem_init+0x90>
	else
		npages = npages_basemem;
f01013e8:	8b 15 c4 d2 17 f0    	mov    0xf017d2c4,%edx
f01013ee:	89 15 84 df 17 f0    	mov    %edx,0xf017df84

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
f01013fe:	a1 c4 d2 17 f0       	mov    0xf017d2c4,%eax
f0101403:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101406:	c1 e8 0a             	shr    $0xa,%eax
f0101409:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f010140d:	a1 84 df 17 f0       	mov    0xf017df84,%eax
f0101412:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101415:	c1 e8 0a             	shr    $0xa,%eax
f0101418:	89 44 24 04          	mov    %eax,0x4(%esp)
f010141c:	c7 04 24 04 55 10 f0 	movl   $0xf0105504,(%esp)
f0101423:	e8 84 23 00 00       	call   f01037ac <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101428:	b8 00 10 00 00       	mov    $0x1000,%eax
f010142d:	e8 d2 f5 ff ff       	call   f0100a04 <boot_alloc>
f0101432:	a3 88 df 17 f0       	mov    %eax,0xf017df88
	memset(kern_pgdir, 0, PGSIZE);
f0101437:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010143e:	00 
f010143f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101446:	00 
f0101447:	89 04 24             	mov    %eax,(%esp)
f010144a:	e8 c8 34 00 00       	call   f0104917 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010144f:	a1 88 df 17 f0       	mov    0xf017df88,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101454:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101459:	77 20                	ja     f010147b <mem_init+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010145b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010145f:	c7 44 24 08 08 53 10 	movl   $0xf0105308,0x8(%esp)
f0101466:	f0 
f0101467:	c7 44 24 04 96 00 00 	movl   $0x96,0x4(%esp)
f010146e:	00 
f010146f:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
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
f010148a:	a1 84 df 17 f0       	mov    0xf017df84,%eax
f010148f:	c1 e0 03             	shl    $0x3,%eax
f0101492:	e8 6d f5 ff ff       	call   f0100a04 <boot_alloc>
f0101497:	a3 8c df 17 f0       	mov    %eax,0xf017df8c
	memset(pages, 0, sizeof(struct PageInfo) * npages); //Clear the memory 
f010149c:	8b 0d 84 df 17 f0    	mov    0xf017df84,%ecx
f01014a2:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01014a9:	89 54 24 08          	mov    %edx,0x8(%esp)
f01014ad:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01014b4:	00 
f01014b5:	89 04 24             	mov    %eax,(%esp)
f01014b8:	e8 5a 34 00 00       	call   f0104917 <memset>
	// The kernel uses this array to keep track of environment array:
	// 'NENV' is the number of Environments in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = boot_alloc(sizeof(struct Env)*NENV);
f01014bd:	b8 00 80 01 00       	mov    $0x18000,%eax
f01014c2:	e8 3d f5 ff ff       	call   f0100a04 <boot_alloc>
f01014c7:	a3 cc d2 17 f0       	mov    %eax,0xf017d2cc
	memset(envs,0,sizeof(struct Env)*NENV);
f01014cc:	c7 44 24 08 00 80 01 	movl   $0x18000,0x8(%esp)
f01014d3:	00 
f01014d4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01014db:	00 
f01014dc:	89 04 24             	mov    %eax,(%esp)
f01014df:	e8 33 34 00 00       	call   f0104917 <memset>
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
f01014f3:	83 3d 8c df 17 f0 00 	cmpl   $0x0,0xf017df8c
f01014fa:	75 1c                	jne    f0101518 <mem_init+0x1b4>
		panic("'pages' is a null pointer!");
f01014fc:	c7 44 24 08 41 5c 10 	movl   $0xf0105c41,0x8(%esp)
f0101503:	f0 
f0101504:	c7 44 24 04 f5 02 00 	movl   $0x2f5,0x4(%esp)
f010150b:	00 
f010150c:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101513:	e8 9e eb ff ff       	call   f01000b6 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101518:	a1 c0 d2 17 f0       	mov    0xf017d2c0,%eax
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
f010153f:	c7 44 24 0c 5c 5c 10 	movl   $0xf0105c5c,0xc(%esp)
f0101546:	f0 
f0101547:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f010154e:	f0 
f010154f:	c7 44 24 04 fd 02 00 	movl   $0x2fd,0x4(%esp)
f0101556:	00 
f0101557:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f010155e:	e8 53 eb ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101563:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010156a:	e8 ce f9 ff ff       	call   f0100f3d <page_alloc>
f010156f:	89 c6                	mov    %eax,%esi
f0101571:	85 c0                	test   %eax,%eax
f0101573:	75 24                	jne    f0101599 <mem_init+0x235>
f0101575:	c7 44 24 0c 72 5c 10 	movl   $0xf0105c72,0xc(%esp)
f010157c:	f0 
f010157d:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101584:	f0 
f0101585:	c7 44 24 04 fe 02 00 	movl   $0x2fe,0x4(%esp)
f010158c:	00 
f010158d:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101594:	e8 1d eb ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f0101599:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015a0:	e8 98 f9 ff ff       	call   f0100f3d <page_alloc>
f01015a5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015a8:	85 c0                	test   %eax,%eax
f01015aa:	75 24                	jne    f01015d0 <mem_init+0x26c>
f01015ac:	c7 44 24 0c 88 5c 10 	movl   $0xf0105c88,0xc(%esp)
f01015b3:	f0 
f01015b4:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f01015bb:	f0 
f01015bc:	c7 44 24 04 ff 02 00 	movl   $0x2ff,0x4(%esp)
f01015c3:	00 
f01015c4:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f01015cb:	e8 e6 ea ff ff       	call   f01000b6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015d0:	39 f7                	cmp    %esi,%edi
f01015d2:	75 24                	jne    f01015f8 <mem_init+0x294>
f01015d4:	c7 44 24 0c 9e 5c 10 	movl   $0xf0105c9e,0xc(%esp)
f01015db:	f0 
f01015dc:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f01015e3:	f0 
f01015e4:	c7 44 24 04 02 03 00 	movl   $0x302,0x4(%esp)
f01015eb:	00 
f01015ec:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f01015f3:	e8 be ea ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015f8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015fb:	39 c6                	cmp    %eax,%esi
f01015fd:	74 04                	je     f0101603 <mem_init+0x29f>
f01015ff:	39 c7                	cmp    %eax,%edi
f0101601:	75 24                	jne    f0101627 <mem_init+0x2c3>
f0101603:	c7 44 24 0c 40 55 10 	movl   $0xf0105540,0xc(%esp)
f010160a:	f0 
f010160b:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101612:	f0 
f0101613:	c7 44 24 04 03 03 00 	movl   $0x303,0x4(%esp)
f010161a:	00 
f010161b:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101622:	e8 8f ea ff ff       	call   f01000b6 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101627:	8b 15 8c df 17 f0    	mov    0xf017df8c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f010162d:	a1 84 df 17 f0       	mov    0xf017df84,%eax
f0101632:	c1 e0 0c             	shl    $0xc,%eax
f0101635:	89 f9                	mov    %edi,%ecx
f0101637:	29 d1                	sub    %edx,%ecx
f0101639:	c1 f9 03             	sar    $0x3,%ecx
f010163c:	c1 e1 0c             	shl    $0xc,%ecx
f010163f:	39 c1                	cmp    %eax,%ecx
f0101641:	72 24                	jb     f0101667 <mem_init+0x303>
f0101643:	c7 44 24 0c b0 5c 10 	movl   $0xf0105cb0,0xc(%esp)
f010164a:	f0 
f010164b:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101652:	f0 
f0101653:	c7 44 24 04 04 03 00 	movl   $0x304,0x4(%esp)
f010165a:	00 
f010165b:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101662:	e8 4f ea ff ff       	call   f01000b6 <_panic>
f0101667:	89 f1                	mov    %esi,%ecx
f0101669:	29 d1                	sub    %edx,%ecx
f010166b:	c1 f9 03             	sar    $0x3,%ecx
f010166e:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101671:	39 c8                	cmp    %ecx,%eax
f0101673:	77 24                	ja     f0101699 <mem_init+0x335>
f0101675:	c7 44 24 0c cd 5c 10 	movl   $0xf0105ccd,0xc(%esp)
f010167c:	f0 
f010167d:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101684:	f0 
f0101685:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
f010168c:	00 
f010168d:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101694:	e8 1d ea ff ff       	call   f01000b6 <_panic>
f0101699:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010169c:	29 d1                	sub    %edx,%ecx
f010169e:	89 ca                	mov    %ecx,%edx
f01016a0:	c1 fa 03             	sar    $0x3,%edx
f01016a3:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f01016a6:	39 d0                	cmp    %edx,%eax
f01016a8:	77 24                	ja     f01016ce <mem_init+0x36a>
f01016aa:	c7 44 24 0c ea 5c 10 	movl   $0xf0105cea,0xc(%esp)
f01016b1:	f0 
f01016b2:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f01016b9:	f0 
f01016ba:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f01016c1:	00 
f01016c2:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f01016c9:	e8 e8 e9 ff ff       	call   f01000b6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01016ce:	a1 c0 d2 17 f0       	mov    0xf017d2c0,%eax
f01016d3:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01016d6:	c7 05 c0 d2 17 f0 00 	movl   $0x0,0xf017d2c0
f01016dd:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01016e0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016e7:	e8 51 f8 ff ff       	call   f0100f3d <page_alloc>
f01016ec:	85 c0                	test   %eax,%eax
f01016ee:	74 24                	je     f0101714 <mem_init+0x3b0>
f01016f0:	c7 44 24 0c 07 5d 10 	movl   $0xf0105d07,0xc(%esp)
f01016f7:	f0 
f01016f8:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f01016ff:	f0 
f0101700:	c7 44 24 04 0d 03 00 	movl   $0x30d,0x4(%esp)
f0101707:	00 
f0101708:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
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
f0101741:	c7 44 24 0c 5c 5c 10 	movl   $0xf0105c5c,0xc(%esp)
f0101748:	f0 
f0101749:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101750:	f0 
f0101751:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f0101758:	00 
f0101759:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101760:	e8 51 e9 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101765:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010176c:	e8 cc f7 ff ff       	call   f0100f3d <page_alloc>
f0101771:	89 c7                	mov    %eax,%edi
f0101773:	85 c0                	test   %eax,%eax
f0101775:	75 24                	jne    f010179b <mem_init+0x437>
f0101777:	c7 44 24 0c 72 5c 10 	movl   $0xf0105c72,0xc(%esp)
f010177e:	f0 
f010177f:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101786:	f0 
f0101787:	c7 44 24 04 15 03 00 	movl   $0x315,0x4(%esp)
f010178e:	00 
f010178f:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101796:	e8 1b e9 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f010179b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017a2:	e8 96 f7 ff ff       	call   f0100f3d <page_alloc>
f01017a7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01017aa:	85 c0                	test   %eax,%eax
f01017ac:	75 24                	jne    f01017d2 <mem_init+0x46e>
f01017ae:	c7 44 24 0c 88 5c 10 	movl   $0xf0105c88,0xc(%esp)
f01017b5:	f0 
f01017b6:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f01017bd:	f0 
f01017be:	c7 44 24 04 16 03 00 	movl   $0x316,0x4(%esp)
f01017c5:	00 
f01017c6:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f01017cd:	e8 e4 e8 ff ff       	call   f01000b6 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01017d2:	39 fe                	cmp    %edi,%esi
f01017d4:	75 24                	jne    f01017fa <mem_init+0x496>
f01017d6:	c7 44 24 0c 9e 5c 10 	movl   $0xf0105c9e,0xc(%esp)
f01017dd:	f0 
f01017de:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f01017e5:	f0 
f01017e6:	c7 44 24 04 18 03 00 	movl   $0x318,0x4(%esp)
f01017ed:	00 
f01017ee:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f01017f5:	e8 bc e8 ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017fa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017fd:	39 c7                	cmp    %eax,%edi
f01017ff:	74 04                	je     f0101805 <mem_init+0x4a1>
f0101801:	39 c6                	cmp    %eax,%esi
f0101803:	75 24                	jne    f0101829 <mem_init+0x4c5>
f0101805:	c7 44 24 0c 40 55 10 	movl   $0xf0105540,0xc(%esp)
f010180c:	f0 
f010180d:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101814:	f0 
f0101815:	c7 44 24 04 19 03 00 	movl   $0x319,0x4(%esp)
f010181c:	00 
f010181d:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101824:	e8 8d e8 ff ff       	call   f01000b6 <_panic>
	assert(!page_alloc(0));
f0101829:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101830:	e8 08 f7 ff ff       	call   f0100f3d <page_alloc>
f0101835:	85 c0                	test   %eax,%eax
f0101837:	74 24                	je     f010185d <mem_init+0x4f9>
f0101839:	c7 44 24 0c 07 5d 10 	movl   $0xf0105d07,0xc(%esp)
f0101840:	f0 
f0101841:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101848:	f0 
f0101849:	c7 44 24 04 1a 03 00 	movl   $0x31a,0x4(%esp)
f0101850:	00 
f0101851:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101858:	e8 59 e8 ff ff       	call   f01000b6 <_panic>
f010185d:	89 f0                	mov    %esi,%eax
f010185f:	2b 05 8c df 17 f0    	sub    0xf017df8c,%eax
f0101865:	c1 f8 03             	sar    $0x3,%eax
f0101868:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010186b:	89 c2                	mov    %eax,%edx
f010186d:	c1 ea 0c             	shr    $0xc,%edx
f0101870:	3b 15 84 df 17 f0    	cmp    0xf017df84,%edx
f0101876:	72 20                	jb     f0101898 <mem_init+0x534>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101878:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010187c:	c7 44 24 08 e4 52 10 	movl   $0xf01052e4,0x8(%esp)
f0101883:	f0 
f0101884:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010188b:	00 
f010188c:	c7 04 24 5d 5b 10 f0 	movl   $0xf0105b5d,(%esp)
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
f01018b0:	e8 62 30 00 00       	call   f0104917 <memset>
	page_free(pp0);
f01018b5:	89 34 24             	mov    %esi,(%esp)
f01018b8:	e8 11 f7 ff ff       	call   f0100fce <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01018bd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01018c4:	e8 74 f6 ff ff       	call   f0100f3d <page_alloc>
f01018c9:	85 c0                	test   %eax,%eax
f01018cb:	75 24                	jne    f01018f1 <mem_init+0x58d>
f01018cd:	c7 44 24 0c 16 5d 10 	movl   $0xf0105d16,0xc(%esp)
f01018d4:	f0 
f01018d5:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f01018dc:	f0 
f01018dd:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f01018e4:	00 
f01018e5:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f01018ec:	e8 c5 e7 ff ff       	call   f01000b6 <_panic>
	assert(pp && pp0 == pp);
f01018f1:	39 c6                	cmp    %eax,%esi
f01018f3:	74 24                	je     f0101919 <mem_init+0x5b5>
f01018f5:	c7 44 24 0c 34 5d 10 	movl   $0xf0105d34,0xc(%esp)
f01018fc:	f0 
f01018fd:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101904:	f0 
f0101905:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f010190c:	00 
f010190d:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101914:	e8 9d e7 ff ff       	call   f01000b6 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101919:	89 f0                	mov    %esi,%eax
f010191b:	2b 05 8c df 17 f0    	sub    0xf017df8c,%eax
f0101921:	c1 f8 03             	sar    $0x3,%eax
f0101924:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101927:	89 c2                	mov    %eax,%edx
f0101929:	c1 ea 0c             	shr    $0xc,%edx
f010192c:	3b 15 84 df 17 f0    	cmp    0xf017df84,%edx
f0101932:	72 20                	jb     f0101954 <mem_init+0x5f0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101934:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101938:	c7 44 24 08 e4 52 10 	movl   $0xf01052e4,0x8(%esp)
f010193f:	f0 
f0101940:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101947:	00 
f0101948:	c7 04 24 5d 5b 10 f0 	movl   $0xf0105b5d,(%esp)
f010194f:	e8 62 e7 ff ff       	call   f01000b6 <_panic>
f0101954:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010195a:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101960:	80 38 00             	cmpb   $0x0,(%eax)
f0101963:	74 24                	je     f0101989 <mem_init+0x625>
f0101965:	c7 44 24 0c 44 5d 10 	movl   $0xf0105d44,0xc(%esp)
f010196c:	f0 
f010196d:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101974:	f0 
f0101975:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f010197c:	00 
f010197d:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
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
f0101993:	a3 c0 d2 17 f0       	mov    %eax,0xf017d2c0

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
f01019b3:	a1 c0 d2 17 f0       	mov    0xf017d2c0,%eax
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
f01019c7:	c7 44 24 0c 4e 5d 10 	movl   $0xf0105d4e,0xc(%esp)
f01019ce:	f0 
f01019cf:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f01019d6:	f0 
f01019d7:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f01019de:	00 
f01019df:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f01019e6:	e8 cb e6 ff ff       	call   f01000b6 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01019eb:	c7 04 24 60 55 10 f0 	movl   $0xf0105560,(%esp)
f01019f2:	e8 b5 1d 00 00       	call   f01037ac <cprintf>
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
f0101a0a:	c7 44 24 0c 5c 5c 10 	movl   $0xf0105c5c,0xc(%esp)
f0101a11:	f0 
f0101a12:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101a19:	f0 
f0101a1a:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f0101a21:	00 
f0101a22:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101a29:	e8 88 e6 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101a2e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a35:	e8 03 f5 ff ff       	call   f0100f3d <page_alloc>
f0101a3a:	89 c3                	mov    %eax,%ebx
f0101a3c:	85 c0                	test   %eax,%eax
f0101a3e:	75 24                	jne    f0101a64 <mem_init+0x700>
f0101a40:	c7 44 24 0c 72 5c 10 	movl   $0xf0105c72,0xc(%esp)
f0101a47:	f0 
f0101a48:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101a4f:	f0 
f0101a50:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f0101a57:	00 
f0101a58:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101a5f:	e8 52 e6 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f0101a64:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a6b:	e8 cd f4 ff ff       	call   f0100f3d <page_alloc>
f0101a70:	89 c6                	mov    %eax,%esi
f0101a72:	85 c0                	test   %eax,%eax
f0101a74:	75 24                	jne    f0101a9a <mem_init+0x736>
f0101a76:	c7 44 24 0c 88 5c 10 	movl   $0xf0105c88,0xc(%esp)
f0101a7d:	f0 
f0101a7e:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101a85:	f0 
f0101a86:	c7 44 24 04 90 03 00 	movl   $0x390,0x4(%esp)
f0101a8d:	00 
f0101a8e:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101a95:	e8 1c e6 ff ff       	call   f01000b6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a9a:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101a9d:	75 24                	jne    f0101ac3 <mem_init+0x75f>
f0101a9f:	c7 44 24 0c 9e 5c 10 	movl   $0xf0105c9e,0xc(%esp)
f0101aa6:	f0 
f0101aa7:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101aae:	f0 
f0101aaf:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f0101ab6:	00 
f0101ab7:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101abe:	e8 f3 e5 ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101ac3:	39 c3                	cmp    %eax,%ebx
f0101ac5:	74 05                	je     f0101acc <mem_init+0x768>
f0101ac7:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101aca:	75 24                	jne    f0101af0 <mem_init+0x78c>
f0101acc:	c7 44 24 0c 40 55 10 	movl   $0xf0105540,0xc(%esp)
f0101ad3:	f0 
f0101ad4:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101adb:	f0 
f0101adc:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f0101ae3:	00 
f0101ae4:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101aeb:	e8 c6 e5 ff ff       	call   f01000b6 <_panic>
	

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101af0:	a1 c0 d2 17 f0       	mov    0xf017d2c0,%eax
f0101af5:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101af8:	c7 05 c0 d2 17 f0 00 	movl   $0x0,0xf017d2c0
f0101aff:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101b02:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b09:	e8 2f f4 ff ff       	call   f0100f3d <page_alloc>
f0101b0e:	85 c0                	test   %eax,%eax
f0101b10:	74 24                	je     f0101b36 <mem_init+0x7d2>
f0101b12:	c7 44 24 0c 07 5d 10 	movl   $0xf0105d07,0xc(%esp)
f0101b19:	f0 
f0101b1a:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101b21:	f0 
f0101b22:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f0101b29:	00 
f0101b2a:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101b31:	e8 80 e5 ff ff       	call   f01000b6 <_panic>
	
	
	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101b36:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101b39:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101b3d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101b44:	00 
f0101b45:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0101b4a:	89 04 24             	mov    %eax,(%esp)
f0101b4d:	e8 bc f6 ff ff       	call   f010120e <page_lookup>
f0101b52:	85 c0                	test   %eax,%eax
f0101b54:	74 24                	je     f0101b7a <mem_init+0x816>
f0101b56:	c7 44 24 0c 80 55 10 	movl   $0xf0105580,0xc(%esp)
f0101b5d:	f0 
f0101b5e:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101b65:	f0 
f0101b66:	c7 44 24 04 a0 03 00 	movl   $0x3a0,0x4(%esp)
f0101b6d:	00 
f0101b6e:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101b75:	e8 3c e5 ff ff       	call   f01000b6 <_panic>
	
	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101b7a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b81:	00 
f0101b82:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101b89:	00 
f0101b8a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101b8e:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0101b93:	89 04 24             	mov    %eax,(%esp)
f0101b96:	e8 07 f7 ff ff       	call   f01012a2 <page_insert>
f0101b9b:	85 c0                	test   %eax,%eax
f0101b9d:	78 24                	js     f0101bc3 <mem_init+0x85f>
f0101b9f:	c7 44 24 0c b8 55 10 	movl   $0xf01055b8,0xc(%esp)
f0101ba6:	f0 
f0101ba7:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101bae:	f0 
f0101baf:	c7 44 24 04 a3 03 00 	movl   $0x3a3,0x4(%esp)
f0101bb6:	00 
f0101bb7:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
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
f0101be2:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0101be7:	89 04 24             	mov    %eax,(%esp)
f0101bea:	e8 b3 f6 ff ff       	call   f01012a2 <page_insert>
f0101bef:	85 c0                	test   %eax,%eax
f0101bf1:	74 24                	je     f0101c17 <mem_init+0x8b3>
f0101bf3:	c7 44 24 0c e8 55 10 	movl   $0xf01055e8,0xc(%esp)
f0101bfa:	f0 
f0101bfb:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101c02:	f0 
f0101c03:	c7 44 24 04 a7 03 00 	movl   $0x3a7,0x4(%esp)
f0101c0a:	00 
f0101c0b:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101c12:	e8 9f e4 ff ff       	call   f01000b6 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101c17:	8b 3d 88 df 17 f0    	mov    0xf017df88,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101c1d:	a1 8c df 17 f0       	mov    0xf017df8c,%eax
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
f0101c3e:	c7 44 24 0c 18 56 10 	movl   $0xf0105618,0xc(%esp)
f0101c45:	f0 
f0101c46:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101c4d:	f0 
f0101c4e:	c7 44 24 04 a8 03 00 	movl   $0x3a8,0x4(%esp)
f0101c55:	00 
f0101c56:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
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
f0101c7d:	c7 44 24 0c 40 56 10 	movl   $0xf0105640,0xc(%esp)
f0101c84:	f0 
f0101c85:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101c8c:	f0 
f0101c8d:	c7 44 24 04 a9 03 00 	movl   $0x3a9,0x4(%esp)
f0101c94:	00 
f0101c95:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101c9c:	e8 15 e4 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 1);
f0101ca1:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ca6:	74 24                	je     f0101ccc <mem_init+0x968>
f0101ca8:	c7 44 24 0c 59 5d 10 	movl   $0xf0105d59,0xc(%esp)
f0101caf:	f0 
f0101cb0:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101cb7:	f0 
f0101cb8:	c7 44 24 04 aa 03 00 	movl   $0x3aa,0x4(%esp)
f0101cbf:	00 
f0101cc0:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101cc7:	e8 ea e3 ff ff       	call   f01000b6 <_panic>
	assert(pp0->pp_ref == 1);
f0101ccc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ccf:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101cd4:	74 24                	je     f0101cfa <mem_init+0x996>
f0101cd6:	c7 44 24 0c 6a 5d 10 	movl   $0xf0105d6a,0xc(%esp)
f0101cdd:	f0 
f0101cde:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101ce5:	f0 
f0101ce6:	c7 44 24 04 ab 03 00 	movl   $0x3ab,0x4(%esp)
f0101ced:	00 
f0101cee:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
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
f0101d1a:	c7 44 24 0c 70 56 10 	movl   $0xf0105670,0xc(%esp)
f0101d21:	f0 
f0101d22:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101d29:	f0 
f0101d2a:	c7 44 24 04 ae 03 00 	movl   $0x3ae,0x4(%esp)
f0101d31:	00 
f0101d32:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101d39:	e8 78 e3 ff ff       	call   f01000b6 <_panic>

	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d3e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d43:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0101d48:	e8 48 ec ff ff       	call   f0100995 <check_va2pa>
f0101d4d:	89 f2                	mov    %esi,%edx
f0101d4f:	2b 15 8c df 17 f0    	sub    0xf017df8c,%edx
f0101d55:	c1 fa 03             	sar    $0x3,%edx
f0101d58:	c1 e2 0c             	shl    $0xc,%edx
f0101d5b:	39 d0                	cmp    %edx,%eax
f0101d5d:	74 24                	je     f0101d83 <mem_init+0xa1f>
f0101d5f:	c7 44 24 0c ac 56 10 	movl   $0xf01056ac,0xc(%esp)
f0101d66:	f0 
f0101d67:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101d6e:	f0 
f0101d6f:	c7 44 24 04 b0 03 00 	movl   $0x3b0,0x4(%esp)
f0101d76:	00 
f0101d77:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101d7e:	e8 33 e3 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0101d83:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d88:	74 24                	je     f0101dae <mem_init+0xa4a>
f0101d8a:	c7 44 24 0c 7b 5d 10 	movl   $0xf0105d7b,0xc(%esp)
f0101d91:	f0 
f0101d92:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101d99:	f0 
f0101d9a:	c7 44 24 04 b1 03 00 	movl   $0x3b1,0x4(%esp)
f0101da1:	00 
f0101da2:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101da9:	e8 08 e3 ff ff       	call   f01000b6 <_panic>
	
	// should be no free memory
	assert(!page_alloc(0));
f0101dae:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101db5:	e8 83 f1 ff ff       	call   f0100f3d <page_alloc>
f0101dba:	85 c0                	test   %eax,%eax
f0101dbc:	74 24                	je     f0101de2 <mem_init+0xa7e>
f0101dbe:	c7 44 24 0c 07 5d 10 	movl   $0xf0105d07,0xc(%esp)
f0101dc5:	f0 
f0101dc6:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101dcd:	f0 
f0101dce:	c7 44 24 04 b4 03 00 	movl   $0x3b4,0x4(%esp)
f0101dd5:	00 
f0101dd6:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101ddd:	e8 d4 e2 ff ff       	call   f01000b6 <_panic>
	
	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101de2:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101de9:	00 
f0101dea:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101df1:	00 
f0101df2:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101df6:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0101dfb:	89 04 24             	mov    %eax,(%esp)
f0101dfe:	e8 9f f4 ff ff       	call   f01012a2 <page_insert>
f0101e03:	85 c0                	test   %eax,%eax
f0101e05:	74 24                	je     f0101e2b <mem_init+0xac7>
f0101e07:	c7 44 24 0c 70 56 10 	movl   $0xf0105670,0xc(%esp)
f0101e0e:	f0 
f0101e0f:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101e16:	f0 
f0101e17:	c7 44 24 04 b7 03 00 	movl   $0x3b7,0x4(%esp)
f0101e1e:	00 
f0101e1f:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101e26:	e8 8b e2 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e2b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e30:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0101e35:	e8 5b eb ff ff       	call   f0100995 <check_va2pa>
f0101e3a:	89 f2                	mov    %esi,%edx
f0101e3c:	2b 15 8c df 17 f0    	sub    0xf017df8c,%edx
f0101e42:	c1 fa 03             	sar    $0x3,%edx
f0101e45:	c1 e2 0c             	shl    $0xc,%edx
f0101e48:	39 d0                	cmp    %edx,%eax
f0101e4a:	74 24                	je     f0101e70 <mem_init+0xb0c>
f0101e4c:	c7 44 24 0c ac 56 10 	movl   $0xf01056ac,0xc(%esp)
f0101e53:	f0 
f0101e54:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101e5b:	f0 
f0101e5c:	c7 44 24 04 b8 03 00 	movl   $0x3b8,0x4(%esp)
f0101e63:	00 
f0101e64:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101e6b:	e8 46 e2 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0101e70:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e75:	74 24                	je     f0101e9b <mem_init+0xb37>
f0101e77:	c7 44 24 0c 7b 5d 10 	movl   $0xf0105d7b,0xc(%esp)
f0101e7e:	f0 
f0101e7f:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101e86:	f0 
f0101e87:	c7 44 24 04 b9 03 00 	movl   $0x3b9,0x4(%esp)
f0101e8e:	00 
f0101e8f:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101e96:	e8 1b e2 ff ff       	call   f01000b6 <_panic>
	
	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101e9b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ea2:	e8 96 f0 ff ff       	call   f0100f3d <page_alloc>
f0101ea7:	85 c0                	test   %eax,%eax
f0101ea9:	74 24                	je     f0101ecf <mem_init+0xb6b>
f0101eab:	c7 44 24 0c 07 5d 10 	movl   $0xf0105d07,0xc(%esp)
f0101eb2:	f0 
f0101eb3:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101eba:	f0 
f0101ebb:	c7 44 24 04 bd 03 00 	movl   $0x3bd,0x4(%esp)
f0101ec2:	00 
f0101ec3:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101eca:	e8 e7 e1 ff ff       	call   f01000b6 <_panic>
	
	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101ecf:	8b 15 88 df 17 f0    	mov    0xf017df88,%edx
f0101ed5:	8b 02                	mov    (%edx),%eax
f0101ed7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101edc:	89 c1                	mov    %eax,%ecx
f0101ede:	c1 e9 0c             	shr    $0xc,%ecx
f0101ee1:	3b 0d 84 df 17 f0    	cmp    0xf017df84,%ecx
f0101ee7:	72 20                	jb     f0101f09 <mem_init+0xba5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ee9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101eed:	c7 44 24 08 e4 52 10 	movl   $0xf01052e4,0x8(%esp)
f0101ef4:	f0 
f0101ef5:	c7 44 24 04 c0 03 00 	movl   $0x3c0,0x4(%esp)
f0101efc:	00 
f0101efd:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
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
f0101f29:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101f2c:	8d 57 04             	lea    0x4(%edi),%edx
f0101f2f:	39 d0                	cmp    %edx,%eax
f0101f31:	74 24                	je     f0101f57 <mem_init+0xbf3>
f0101f33:	c7 44 24 0c dc 56 10 	movl   $0xf01056dc,0xc(%esp)
f0101f3a:	f0 
f0101f3b:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101f42:	f0 
f0101f43:	c7 44 24 04 c1 03 00 	movl   $0x3c1,0x4(%esp)
f0101f4a:	00 
f0101f4b:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101f52:	e8 5f e1 ff ff       	call   f01000b6 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101f57:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101f5e:	00 
f0101f5f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f66:	00 
f0101f67:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101f6b:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0101f70:	89 04 24             	mov    %eax,(%esp)
f0101f73:	e8 2a f3 ff ff       	call   f01012a2 <page_insert>
f0101f78:	85 c0                	test   %eax,%eax
f0101f7a:	74 24                	je     f0101fa0 <mem_init+0xc3c>
f0101f7c:	c7 44 24 0c 1c 57 10 	movl   $0xf010571c,0xc(%esp)
f0101f83:	f0 
f0101f84:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101f8b:	f0 
f0101f8c:	c7 44 24 04 c4 03 00 	movl   $0x3c4,0x4(%esp)
f0101f93:	00 
f0101f94:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101f9b:	e8 16 e1 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101fa0:	8b 3d 88 df 17 f0    	mov    0xf017df88,%edi
f0101fa6:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fab:	89 f8                	mov    %edi,%eax
f0101fad:	e8 e3 e9 ff ff       	call   f0100995 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101fb2:	89 f2                	mov    %esi,%edx
f0101fb4:	2b 15 8c df 17 f0    	sub    0xf017df8c,%edx
f0101fba:	c1 fa 03             	sar    $0x3,%edx
f0101fbd:	c1 e2 0c             	shl    $0xc,%edx
f0101fc0:	39 d0                	cmp    %edx,%eax
f0101fc2:	74 24                	je     f0101fe8 <mem_init+0xc84>
f0101fc4:	c7 44 24 0c ac 56 10 	movl   $0xf01056ac,0xc(%esp)
f0101fcb:	f0 
f0101fcc:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101fd3:	f0 
f0101fd4:	c7 44 24 04 c5 03 00 	movl   $0x3c5,0x4(%esp)
f0101fdb:	00 
f0101fdc:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0101fe3:	e8 ce e0 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0101fe8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101fed:	74 24                	je     f0102013 <mem_init+0xcaf>
f0101fef:	c7 44 24 0c 7b 5d 10 	movl   $0xf0105d7b,0xc(%esp)
f0101ff6:	f0 
f0101ff7:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0101ffe:	f0 
f0101fff:	c7 44 24 04 c6 03 00 	movl   $0x3c6,0x4(%esp)
f0102006:	00 
f0102007:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
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
f0102030:	c7 44 24 0c 5c 57 10 	movl   $0xf010575c,0xc(%esp)
f0102037:	f0 
f0102038:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f010203f:	f0 
f0102040:	c7 44 24 04 c7 03 00 	movl   $0x3c7,0x4(%esp)
f0102047:	00 
f0102048:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f010204f:	e8 62 e0 ff ff       	call   f01000b6 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102054:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0102059:	f6 00 04             	testb  $0x4,(%eax)
f010205c:	75 24                	jne    f0102082 <mem_init+0xd1e>
f010205e:	c7 44 24 0c 8c 5d 10 	movl   $0xf0105d8c,0xc(%esp)
f0102065:	f0 
f0102066:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f010206d:	f0 
f010206e:	c7 44 24 04 c8 03 00 	movl   $0x3c8,0x4(%esp)
f0102075:	00 
f0102076:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
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
f01020a2:	c7 44 24 0c 70 56 10 	movl   $0xf0105670,0xc(%esp)
f01020a9:	f0 
f01020aa:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f01020b1:	f0 
f01020b2:	c7 44 24 04 cb 03 00 	movl   $0x3cb,0x4(%esp)
f01020b9:	00 
f01020ba:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f01020c1:	e8 f0 df ff ff       	call   f01000b6 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01020c6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01020cd:	00 
f01020ce:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01020d5:	00 
f01020d6:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f01020db:	89 04 24             	mov    %eax,(%esp)
f01020de:	e8 69 ef ff ff       	call   f010104c <pgdir_walk>
f01020e3:	f6 00 02             	testb  $0x2,(%eax)
f01020e6:	75 24                	jne    f010210c <mem_init+0xda8>
f01020e8:	c7 44 24 0c 90 57 10 	movl   $0xf0105790,0xc(%esp)
f01020ef:	f0 
f01020f0:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f01020f7:	f0 
f01020f8:	c7 44 24 04 cc 03 00 	movl   $0x3cc,0x4(%esp)
f01020ff:	00 
f0102100:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102107:	e8 aa df ff ff       	call   f01000b6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010210c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102113:	00 
f0102114:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010211b:	00 
f010211c:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0102121:	89 04 24             	mov    %eax,(%esp)
f0102124:	e8 23 ef ff ff       	call   f010104c <pgdir_walk>
f0102129:	f6 00 04             	testb  $0x4,(%eax)
f010212c:	74 24                	je     f0102152 <mem_init+0xdee>
f010212e:	c7 44 24 0c c4 57 10 	movl   $0xf01057c4,0xc(%esp)
f0102135:	f0 
f0102136:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f010213d:	f0 
f010213e:	c7 44 24 04 cd 03 00 	movl   $0x3cd,0x4(%esp)
f0102145:	00 
f0102146:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f010214d:	e8 64 df ff ff       	call   f01000b6 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102152:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102159:	00 
f010215a:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0102161:	00 
f0102162:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102165:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102169:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f010216e:	89 04 24             	mov    %eax,(%esp)
f0102171:	e8 2c f1 ff ff       	call   f01012a2 <page_insert>
f0102176:	85 c0                	test   %eax,%eax
f0102178:	78 24                	js     f010219e <mem_init+0xe3a>
f010217a:	c7 44 24 0c fc 57 10 	movl   $0xf01057fc,0xc(%esp)
f0102181:	f0 
f0102182:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102189:	f0 
f010218a:	c7 44 24 04 d0 03 00 	movl   $0x3d0,0x4(%esp)
f0102191:	00 
f0102192:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102199:	e8 18 df ff ff       	call   f01000b6 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f010219e:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01021a5:	00 
f01021a6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01021ad:	00 
f01021ae:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01021b2:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f01021b7:	89 04 24             	mov    %eax,(%esp)
f01021ba:	e8 e3 f0 ff ff       	call   f01012a2 <page_insert>
f01021bf:	85 c0                	test   %eax,%eax
f01021c1:	74 24                	je     f01021e7 <mem_init+0xe83>
f01021c3:	c7 44 24 0c 34 58 10 	movl   $0xf0105834,0xc(%esp)
f01021ca:	f0 
f01021cb:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f01021d2:	f0 
f01021d3:	c7 44 24 04 d3 03 00 	movl   $0x3d3,0x4(%esp)
f01021da:	00 
f01021db:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f01021e2:	e8 cf de ff ff       	call   f01000b6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01021e7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01021ee:	00 
f01021ef:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01021f6:	00 
f01021f7:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f01021fc:	89 04 24             	mov    %eax,(%esp)
f01021ff:	e8 48 ee ff ff       	call   f010104c <pgdir_walk>
f0102204:	f6 00 04             	testb  $0x4,(%eax)
f0102207:	74 24                	je     f010222d <mem_init+0xec9>
f0102209:	c7 44 24 0c c4 57 10 	movl   $0xf01057c4,0xc(%esp)
f0102210:	f0 
f0102211:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102218:	f0 
f0102219:	c7 44 24 04 d4 03 00 	movl   $0x3d4,0x4(%esp)
f0102220:	00 
f0102221:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102228:	e8 89 de ff ff       	call   f01000b6 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010222d:	8b 3d 88 df 17 f0    	mov    0xf017df88,%edi
f0102233:	ba 00 00 00 00       	mov    $0x0,%edx
f0102238:	89 f8                	mov    %edi,%eax
f010223a:	e8 56 e7 ff ff       	call   f0100995 <check_va2pa>
f010223f:	89 c1                	mov    %eax,%ecx
f0102241:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102244:	89 d8                	mov    %ebx,%eax
f0102246:	2b 05 8c df 17 f0    	sub    0xf017df8c,%eax
f010224c:	c1 f8 03             	sar    $0x3,%eax
f010224f:	c1 e0 0c             	shl    $0xc,%eax
f0102252:	39 c1                	cmp    %eax,%ecx
f0102254:	74 24                	je     f010227a <mem_init+0xf16>
f0102256:	c7 44 24 0c 70 58 10 	movl   $0xf0105870,0xc(%esp)
f010225d:	f0 
f010225e:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102265:	f0 
f0102266:	c7 44 24 04 d7 03 00 	movl   $0x3d7,0x4(%esp)
f010226d:	00 
f010226e:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102275:	e8 3c de ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010227a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010227f:	89 f8                	mov    %edi,%eax
f0102281:	e8 0f e7 ff ff       	call   f0100995 <check_va2pa>
f0102286:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0102289:	74 24                	je     f01022af <mem_init+0xf4b>
f010228b:	c7 44 24 0c 9c 58 10 	movl   $0xf010589c,0xc(%esp)
f0102292:	f0 
f0102293:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f010229a:	f0 
f010229b:	c7 44 24 04 d8 03 00 	movl   $0x3d8,0x4(%esp)
f01022a2:	00 
f01022a3:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f01022aa:	e8 07 de ff ff       	call   f01000b6 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01022af:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f01022b4:	74 24                	je     f01022da <mem_init+0xf76>
f01022b6:	c7 44 24 0c a2 5d 10 	movl   $0xf0105da2,0xc(%esp)
f01022bd:	f0 
f01022be:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f01022c5:	f0 
f01022c6:	c7 44 24 04 da 03 00 	movl   $0x3da,0x4(%esp)
f01022cd:	00 
f01022ce:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f01022d5:	e8 dc dd ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f01022da:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01022df:	74 24                	je     f0102305 <mem_init+0xfa1>
f01022e1:	c7 44 24 0c b3 5d 10 	movl   $0xf0105db3,0xc(%esp)
f01022e8:	f0 
f01022e9:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f01022f0:	f0 
f01022f1:	c7 44 24 04 db 03 00 	movl   $0x3db,0x4(%esp)
f01022f8:	00 
f01022f9:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102300:	e8 b1 dd ff ff       	call   f01000b6 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102305:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010230c:	e8 2c ec ff ff       	call   f0100f3d <page_alloc>
f0102311:	85 c0                	test   %eax,%eax
f0102313:	74 04                	je     f0102319 <mem_init+0xfb5>
f0102315:	39 c6                	cmp    %eax,%esi
f0102317:	74 24                	je     f010233d <mem_init+0xfd9>
f0102319:	c7 44 24 0c cc 58 10 	movl   $0xf01058cc,0xc(%esp)
f0102320:	f0 
f0102321:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102328:	f0 
f0102329:	c7 44 24 04 de 03 00 	movl   $0x3de,0x4(%esp)
f0102330:	00 
f0102331:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102338:	e8 79 dd ff ff       	call   f01000b6 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010233d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102344:	00 
f0102345:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f010234a:	89 04 24             	mov    %eax,(%esp)
f010234d:	e8 12 ef ff ff       	call   f0101264 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102352:	8b 3d 88 df 17 f0    	mov    0xf017df88,%edi
f0102358:	ba 00 00 00 00       	mov    $0x0,%edx
f010235d:	89 f8                	mov    %edi,%eax
f010235f:	e8 31 e6 ff ff       	call   f0100995 <check_va2pa>
f0102364:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102367:	74 24                	je     f010238d <mem_init+0x1029>
f0102369:	c7 44 24 0c f0 58 10 	movl   $0xf01058f0,0xc(%esp)
f0102370:	f0 
f0102371:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102378:	f0 
f0102379:	c7 44 24 04 e2 03 00 	movl   $0x3e2,0x4(%esp)
f0102380:	00 
f0102381:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102388:	e8 29 dd ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010238d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102392:	89 f8                	mov    %edi,%eax
f0102394:	e8 fc e5 ff ff       	call   f0100995 <check_va2pa>
f0102399:	89 da                	mov    %ebx,%edx
f010239b:	2b 15 8c df 17 f0    	sub    0xf017df8c,%edx
f01023a1:	c1 fa 03             	sar    $0x3,%edx
f01023a4:	c1 e2 0c             	shl    $0xc,%edx
f01023a7:	39 d0                	cmp    %edx,%eax
f01023a9:	74 24                	je     f01023cf <mem_init+0x106b>
f01023ab:	c7 44 24 0c 9c 58 10 	movl   $0xf010589c,0xc(%esp)
f01023b2:	f0 
f01023b3:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f01023ba:	f0 
f01023bb:	c7 44 24 04 e3 03 00 	movl   $0x3e3,0x4(%esp)
f01023c2:	00 
f01023c3:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f01023ca:	e8 e7 dc ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 1);
f01023cf:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01023d4:	74 24                	je     f01023fa <mem_init+0x1096>
f01023d6:	c7 44 24 0c 59 5d 10 	movl   $0xf0105d59,0xc(%esp)
f01023dd:	f0 
f01023de:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f01023e5:	f0 
f01023e6:	c7 44 24 04 e4 03 00 	movl   $0x3e4,0x4(%esp)
f01023ed:	00 
f01023ee:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f01023f5:	e8 bc dc ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f01023fa:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01023ff:	74 24                	je     f0102425 <mem_init+0x10c1>
f0102401:	c7 44 24 0c b3 5d 10 	movl   $0xf0105db3,0xc(%esp)
f0102408:	f0 
f0102409:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102410:	f0 
f0102411:	c7 44 24 04 e5 03 00 	movl   $0x3e5,0x4(%esp)
f0102418:	00 
f0102419:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
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
f0102445:	c7 44 24 0c 14 59 10 	movl   $0xf0105914,0xc(%esp)
f010244c:	f0 
f010244d:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102454:	f0 
f0102455:	c7 44 24 04 e8 03 00 	movl   $0x3e8,0x4(%esp)
f010245c:	00 
f010245d:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102464:	e8 4d dc ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref);
f0102469:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010246e:	75 24                	jne    f0102494 <mem_init+0x1130>
f0102470:	c7 44 24 0c c4 5d 10 	movl   $0xf0105dc4,0xc(%esp)
f0102477:	f0 
f0102478:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f010247f:	f0 
f0102480:	c7 44 24 04 e9 03 00 	movl   $0x3e9,0x4(%esp)
f0102487:	00 
f0102488:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f010248f:	e8 22 dc ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_link == NULL);
f0102494:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102497:	74 24                	je     f01024bd <mem_init+0x1159>
f0102499:	c7 44 24 0c d0 5d 10 	movl   $0xf0105dd0,0xc(%esp)
f01024a0:	f0 
f01024a1:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f01024a8:	f0 
f01024a9:	c7 44 24 04 ea 03 00 	movl   $0x3ea,0x4(%esp)
f01024b0:	00 
f01024b1:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f01024b8:	e8 f9 db ff ff       	call   f01000b6 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01024bd:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01024c4:	00 
f01024c5:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f01024ca:	89 04 24             	mov    %eax,(%esp)
f01024cd:	e8 92 ed ff ff       	call   f0101264 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01024d2:	8b 3d 88 df 17 f0    	mov    0xf017df88,%edi
f01024d8:	ba 00 00 00 00       	mov    $0x0,%edx
f01024dd:	89 f8                	mov    %edi,%eax
f01024df:	e8 b1 e4 ff ff       	call   f0100995 <check_va2pa>
f01024e4:	83 f8 ff             	cmp    $0xffffffff,%eax
f01024e7:	74 24                	je     f010250d <mem_init+0x11a9>
f01024e9:	c7 44 24 0c f0 58 10 	movl   $0xf01058f0,0xc(%esp)
f01024f0:	f0 
f01024f1:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f01024f8:	f0 
f01024f9:	c7 44 24 04 ee 03 00 	movl   $0x3ee,0x4(%esp)
f0102500:	00 
f0102501:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102508:	e8 a9 db ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010250d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102512:	89 f8                	mov    %edi,%eax
f0102514:	e8 7c e4 ff ff       	call   f0100995 <check_va2pa>
f0102519:	83 f8 ff             	cmp    $0xffffffff,%eax
f010251c:	74 24                	je     f0102542 <mem_init+0x11de>
f010251e:	c7 44 24 0c 4c 59 10 	movl   $0xf010594c,0xc(%esp)
f0102525:	f0 
f0102526:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f010252d:	f0 
f010252e:	c7 44 24 04 ef 03 00 	movl   $0x3ef,0x4(%esp)
f0102535:	00 
f0102536:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f010253d:	e8 74 db ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 0);
f0102542:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102547:	74 24                	je     f010256d <mem_init+0x1209>
f0102549:	c7 44 24 0c e5 5d 10 	movl   $0xf0105de5,0xc(%esp)
f0102550:	f0 
f0102551:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102558:	f0 
f0102559:	c7 44 24 04 f0 03 00 	movl   $0x3f0,0x4(%esp)
f0102560:	00 
f0102561:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102568:	e8 49 db ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f010256d:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102572:	74 24                	je     f0102598 <mem_init+0x1234>
f0102574:	c7 44 24 0c b3 5d 10 	movl   $0xf0105db3,0xc(%esp)
f010257b:	f0 
f010257c:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102583:	f0 
f0102584:	c7 44 24 04 f1 03 00 	movl   $0x3f1,0x4(%esp)
f010258b:	00 
f010258c:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102593:	e8 1e db ff ff       	call   f01000b6 <_panic>
	
	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102598:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010259f:	e8 99 e9 ff ff       	call   f0100f3d <page_alloc>
f01025a4:	85 c0                	test   %eax,%eax
f01025a6:	74 04                	je     f01025ac <mem_init+0x1248>
f01025a8:	39 c3                	cmp    %eax,%ebx
f01025aa:	74 24                	je     f01025d0 <mem_init+0x126c>
f01025ac:	c7 44 24 0c 74 59 10 	movl   $0xf0105974,0xc(%esp)
f01025b3:	f0 
f01025b4:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f01025bb:	f0 
f01025bc:	c7 44 24 04 f4 03 00 	movl   $0x3f4,0x4(%esp)
f01025c3:	00 
f01025c4:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f01025cb:	e8 e6 da ff ff       	call   f01000b6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01025d0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01025d7:	e8 61 e9 ff ff       	call   f0100f3d <page_alloc>
f01025dc:	85 c0                	test   %eax,%eax
f01025de:	74 24                	je     f0102604 <mem_init+0x12a0>
f01025e0:	c7 44 24 0c 07 5d 10 	movl   $0xf0105d07,0xc(%esp)
f01025e7:	f0 
f01025e8:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f01025ef:	f0 
f01025f0:	c7 44 24 04 f7 03 00 	movl   $0x3f7,0x4(%esp)
f01025f7:	00 
f01025f8:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f01025ff:	e8 b2 da ff ff       	call   f01000b6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102604:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0102609:	8b 08                	mov    (%eax),%ecx
f010260b:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102611:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102614:	2b 15 8c df 17 f0    	sub    0xf017df8c,%edx
f010261a:	c1 fa 03             	sar    $0x3,%edx
f010261d:	c1 e2 0c             	shl    $0xc,%edx
f0102620:	39 d1                	cmp    %edx,%ecx
f0102622:	74 24                	je     f0102648 <mem_init+0x12e4>
f0102624:	c7 44 24 0c 18 56 10 	movl   $0xf0105618,0xc(%esp)
f010262b:	f0 
f010262c:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102633:	f0 
f0102634:	c7 44 24 04 fa 03 00 	movl   $0x3fa,0x4(%esp)
f010263b:	00 
f010263c:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102643:	e8 6e da ff ff       	call   f01000b6 <_panic>
	kern_pgdir[0] = 0;
f0102648:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f010264e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102651:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102656:	74 24                	je     f010267c <mem_init+0x1318>
f0102658:	c7 44 24 0c 6a 5d 10 	movl   $0xf0105d6a,0xc(%esp)
f010265f:	f0 
f0102660:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102667:	f0 
f0102668:	c7 44 24 04 fc 03 00 	movl   $0x3fc,0x4(%esp)
f010266f:	00 
f0102670:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
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
f010269d:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f01026a2:	89 04 24             	mov    %eax,(%esp)
f01026a5:	e8 a2 e9 ff ff       	call   f010104c <pgdir_walk>
f01026aa:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01026ad:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01026b0:	8b 15 88 df 17 f0    	mov    0xf017df88,%edx
f01026b6:	8b 7a 04             	mov    0x4(%edx),%edi
f01026b9:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01026bf:	8b 0d 84 df 17 f0    	mov    0xf017df84,%ecx
f01026c5:	89 f8                	mov    %edi,%eax
f01026c7:	c1 e8 0c             	shr    $0xc,%eax
f01026ca:	39 c8                	cmp    %ecx,%eax
f01026cc:	72 20                	jb     f01026ee <mem_init+0x138a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01026ce:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01026d2:	c7 44 24 08 e4 52 10 	movl   $0xf01052e4,0x8(%esp)
f01026d9:	f0 
f01026da:	c7 44 24 04 03 04 00 	movl   $0x403,0x4(%esp)
f01026e1:	00 
f01026e2:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f01026e9:	e8 c8 d9 ff ff       	call   f01000b6 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01026ee:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f01026f4:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f01026f7:	74 24                	je     f010271d <mem_init+0x13b9>
f01026f9:	c7 44 24 0c f6 5d 10 	movl   $0xf0105df6,0xc(%esp)
f0102700:	f0 
f0102701:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102708:	f0 
f0102709:	c7 44 24 04 04 04 00 	movl   $0x404,0x4(%esp)
f0102710:	00 
f0102711:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
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
f010272d:	2b 05 8c df 17 f0    	sub    0xf017df8c,%eax
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
f0102746:	c7 44 24 08 e4 52 10 	movl   $0xf01052e4,0x8(%esp)
f010274d:	f0 
f010274e:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102755:	00 
f0102756:	c7 04 24 5d 5b 10 f0 	movl   $0xf0105b5d,(%esp)
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
f010277a:	e8 98 21 00 00       	call   f0104917 <memset>
	page_free(pp0);
f010277f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102782:	89 3c 24             	mov    %edi,(%esp)
f0102785:	e8 44 e8 ff ff       	call   f0100fce <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010278a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102791:	00 
f0102792:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102799:	00 
f010279a:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f010279f:	89 04 24             	mov    %eax,(%esp)
f01027a2:	e8 a5 e8 ff ff       	call   f010104c <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01027a7:	89 fa                	mov    %edi,%edx
f01027a9:	2b 15 8c df 17 f0    	sub    0xf017df8c,%edx
f01027af:	c1 fa 03             	sar    $0x3,%edx
f01027b2:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01027b5:	89 d0                	mov    %edx,%eax
f01027b7:	c1 e8 0c             	shr    $0xc,%eax
f01027ba:	3b 05 84 df 17 f0    	cmp    0xf017df84,%eax
f01027c0:	72 20                	jb     f01027e2 <mem_init+0x147e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01027c2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01027c6:	c7 44 24 08 e4 52 10 	movl   $0xf01052e4,0x8(%esp)
f01027cd:	f0 
f01027ce:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01027d5:	00 
f01027d6:	c7 04 24 5d 5b 10 f0 	movl   $0xf0105b5d,(%esp)
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
f01027f6:	c7 44 24 0c 0e 5e 10 	movl   $0xf0105e0e,0xc(%esp)
f01027fd:	f0 
f01027fe:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102805:	f0 
f0102806:	c7 44 24 04 0e 04 00 	movl   $0x40e,0x4(%esp)
f010280d:	00 
f010280e:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
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
f0102821:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0102826:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010282c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010282f:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102835:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102838:	89 0d c0 d2 17 f0    	mov    %ecx,0xf017d2c0

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
f0102856:	c7 04 24 25 5e 10 f0 	movl   $0xf0105e25,(%esp)
f010285d:	e8 4a 0f 00 00       	call   f01037ac <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, sizeof(struct PageInfo) * npages,PADDR(pages), PTE_U | PTE_P);
f0102862:	a1 8c df 17 f0       	mov    0xf017df8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102867:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010286c:	77 20                	ja     f010288e <mem_init+0x152a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010286e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102872:	c7 44 24 08 08 53 10 	movl   $0xf0105308,0x8(%esp)
f0102879:	f0 
f010287a:	c7 44 24 04 c3 00 00 	movl   $0xc3,0x4(%esp)
f0102881:	00 
f0102882:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102889:	e8 28 d8 ff ff       	call   f01000b6 <_panic>
f010288e:	8b 3d 84 df 17 f0    	mov    0xf017df84,%edi
f0102894:	8d 0c fd 00 00 00 00 	lea    0x0(,%edi,8),%ecx
f010289b:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f01028a2:	00 
	return (physaddr_t)kva - KERNBASE;
f01028a3:	05 00 00 00 10       	add    $0x10000000,%eax
f01028a8:	89 04 24             	mov    %eax,(%esp)
f01028ab:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01028b0:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f01028b5:	e8 a1 e8 ff ff       	call   f010115b <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, sizeof(struct Env) * NENV,PADDR(envs), PTE_U | PTE_P);
f01028ba:	a1 cc d2 17 f0       	mov    0xf017d2cc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028bf:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01028c4:	77 20                	ja     f01028e6 <mem_init+0x1582>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028c6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01028ca:	c7 44 24 08 08 53 10 	movl   $0xf0105308,0x8(%esp)
f01028d1:	f0 
f01028d2:	c7 44 24 04 cb 00 00 	movl   $0xcb,0x4(%esp)
f01028d9:	00 
f01028da:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f01028e1:	e8 d0 d7 ff ff       	call   f01000b6 <_panic>
f01028e6:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f01028ed:	00 
	return (physaddr_t)kva - KERNBASE;
f01028ee:	05 00 00 00 10       	add    $0x10000000,%eax
f01028f3:	89 04 24             	mov    %eax,(%esp)
f01028f6:	b9 00 80 01 00       	mov    $0x18000,%ecx
f01028fb:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102900:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0102905:	e8 51 e8 ff ff       	call   f010115b <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010290a:	bb 00 10 11 f0       	mov    $0xf0111000,%ebx
f010290f:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102915:	77 20                	ja     f0102937 <mem_init+0x15d3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102917:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010291b:	c7 44 24 08 08 53 10 	movl   $0xf0105308,0x8(%esp)
f0102922:	f0 
f0102923:	c7 44 24 04 d7 00 00 	movl   $0xd7,0x4(%esp)
f010292a:	00 
f010292b:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102932:	e8 7f d7 ff ff       	call   f01000b6 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W | PTE_P);
f0102937:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f010293e:	00 
f010293f:	c7 04 24 00 10 11 00 	movl   $0x111000,(%esp)
f0102946:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010294b:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102950:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0102955:	e8 01 e8 ff ff       	call   f010115b <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	size_t size = ROUNDUP(0xFFFFFFFF - KERNBASE + 1, PGSIZE);
	boot_map_region(kern_pgdir, KERNBASE, size, 0, PTE_W | PTE_P);
f010295a:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102961:	00 
f0102962:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102969:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f010296e:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102973:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0102978:	e8 de e7 ff ff       	call   f010115b <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010297d:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0102982:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102985:	a1 84 df 17 f0       	mov    0xf017df84,%eax
f010298a:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010298d:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102994:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102999:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010299c:	8b 3d 8c df 17 f0    	mov    0xf017df8c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01029a2:	89 7d c8             	mov    %edi,-0x38(%ebp)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f01029a5:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01029ab:	89 45 c4             	mov    %eax,-0x3c(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01029ae:	be 00 00 00 00       	mov    $0x0,%esi
f01029b3:	eb 6b                	jmp    f0102a20 <mem_init+0x16bc>
f01029b5:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01029bb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01029be:	e8 d2 df ff ff       	call   f0100995 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01029c3:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f01029ca:	77 20                	ja     f01029ec <mem_init+0x1688>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029cc:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01029d0:	c7 44 24 08 08 53 10 	movl   $0xf0105308,0x8(%esp)
f01029d7:	f0 
f01029d8:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f01029df:	00 
f01029e0:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f01029e7:	e8 ca d6 ff ff       	call   f01000b6 <_panic>
f01029ec:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f01029ef:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01029f2:	39 d0                	cmp    %edx,%eax
f01029f4:	74 24                	je     f0102a1a <mem_init+0x16b6>
f01029f6:	c7 44 24 0c 98 59 10 	movl   $0xf0105998,0xc(%esp)
f01029fd:	f0 
f01029fe:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102a05:	f0 
f0102a06:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f0102a0d:	00 
f0102a0e:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102a15:	e8 9c d6 ff ff       	call   f01000b6 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102a1a:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102a20:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0102a23:	77 90                	ja     f01029b5 <mem_init+0x1651>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102a25:	8b 35 cc d2 17 f0    	mov    0xf017d2cc,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a2b:	89 f7                	mov    %esi,%edi
f0102a2d:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102a32:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a35:	e8 5b df ff ff       	call   f0100995 <check_va2pa>
f0102a3a:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102a40:	77 20                	ja     f0102a62 <mem_init+0x16fe>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a42:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102a46:	c7 44 24 08 08 53 10 	movl   $0xf0105308,0x8(%esp)
f0102a4d:	f0 
f0102a4e:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f0102a55:	00 
f0102a56:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102a5d:	e8 54 d6 ff ff       	call   f01000b6 <_panic>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a62:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f0102a67:	81 c7 00 00 40 21    	add    $0x21400000,%edi
f0102a6d:	8d 14 37             	lea    (%edi,%esi,1),%edx
f0102a70:	39 c2                	cmp    %eax,%edx
f0102a72:	74 24                	je     f0102a98 <mem_init+0x1734>
f0102a74:	c7 44 24 0c cc 59 10 	movl   $0xf01059cc,0xc(%esp)
f0102a7b:	f0 
f0102a7c:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102a83:	f0 
f0102a84:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f0102a8b:	00 
f0102a8c:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102a93:	e8 1e d6 ff ff       	call   f01000b6 <_panic>
f0102a98:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102a9e:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f0102aa4:	0f 85 26 05 00 00    	jne    f0102fd0 <mem_init+0x1c6c>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102aaa:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0102aad:	c1 e7 0c             	shl    $0xc,%edi
f0102ab0:	be 00 00 00 00       	mov    $0x0,%esi
f0102ab5:	eb 3c                	jmp    f0102af3 <mem_init+0x178f>
f0102ab7:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102abd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ac0:	e8 d0 de ff ff       	call   f0100995 <check_va2pa>
f0102ac5:	39 c6                	cmp    %eax,%esi
f0102ac7:	74 24                	je     f0102aed <mem_init+0x1789>
f0102ac9:	c7 44 24 0c 00 5a 10 	movl   $0xf0105a00,0xc(%esp)
f0102ad0:	f0 
f0102ad1:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102ad8:	f0 
f0102ad9:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f0102ae0:	00 
f0102ae1:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102ae8:	e8 c9 d5 ff ff       	call   f01000b6 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102aed:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102af3:	39 fe                	cmp    %edi,%esi
f0102af5:	72 c0                	jb     f0102ab7 <mem_init+0x1753>
f0102af7:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102afc:	81 c3 00 80 00 20    	add    $0x20008000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102b02:	89 f2                	mov    %esi,%edx
f0102b04:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b07:	e8 89 de ff ff       	call   f0100995 <check_va2pa>
f0102b0c:	8d 14 33             	lea    (%ebx,%esi,1),%edx
f0102b0f:	39 d0                	cmp    %edx,%eax
f0102b11:	74 24                	je     f0102b37 <mem_init+0x17d3>
f0102b13:	c7 44 24 0c 28 5a 10 	movl   $0xf0105a28,0xc(%esp)
f0102b1a:	f0 
f0102b1b:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102b22:	f0 
f0102b23:	c7 44 24 04 55 03 00 	movl   $0x355,0x4(%esp)
f0102b2a:	00 
f0102b2b:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102b32:	e8 7f d5 ff ff       	call   f01000b6 <_panic>
f0102b37:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102b3d:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102b43:	75 bd                	jne    f0102b02 <mem_init+0x179e>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102b45:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102b4a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102b4d:	89 f8                	mov    %edi,%eax
f0102b4f:	e8 41 de ff ff       	call   f0100995 <check_va2pa>
f0102b54:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102b57:	75 0c                	jne    f0102b65 <mem_init+0x1801>
f0102b59:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b5e:	89 fa                	mov    %edi,%edx
f0102b60:	e9 f0 00 00 00       	jmp    f0102c55 <mem_init+0x18f1>
f0102b65:	c7 44 24 0c 70 5a 10 	movl   $0xf0105a70,0xc(%esp)
f0102b6c:	f0 
f0102b6d:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102b74:	f0 
f0102b75:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f0102b7c:	00 
f0102b7d:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102b84:	e8 2d d5 ff ff       	call   f01000b6 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102b89:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102b8e:	72 3c                	jb     f0102bcc <mem_init+0x1868>
f0102b90:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102b95:	76 07                	jbe    f0102b9e <mem_init+0x183a>
f0102b97:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102b9c:	75 2e                	jne    f0102bcc <mem_init+0x1868>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f0102b9e:	f6 04 82 01          	testb  $0x1,(%edx,%eax,4)
f0102ba2:	0f 85 aa 00 00 00    	jne    f0102c52 <mem_init+0x18ee>
f0102ba8:	c7 44 24 0c 3e 5e 10 	movl   $0xf0105e3e,0xc(%esp)
f0102baf:	f0 
f0102bb0:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102bb7:	f0 
f0102bb8:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f0102bbf:	00 
f0102bc0:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102bc7:	e8 ea d4 ff ff       	call   f01000b6 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102bcc:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102bd1:	76 55                	jbe    f0102c28 <mem_init+0x18c4>
				assert(pgdir[i] & PTE_P);
f0102bd3:	8b 0c 82             	mov    (%edx,%eax,4),%ecx
f0102bd6:	f6 c1 01             	test   $0x1,%cl
f0102bd9:	75 24                	jne    f0102bff <mem_init+0x189b>
f0102bdb:	c7 44 24 0c 3e 5e 10 	movl   $0xf0105e3e,0xc(%esp)
f0102be2:	f0 
f0102be3:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102bea:	f0 
f0102beb:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f0102bf2:	00 
f0102bf3:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102bfa:	e8 b7 d4 ff ff       	call   f01000b6 <_panic>
				assert(pgdir[i] & PTE_W);
f0102bff:	f6 c1 02             	test   $0x2,%cl
f0102c02:	75 4e                	jne    f0102c52 <mem_init+0x18ee>
f0102c04:	c7 44 24 0c 4f 5e 10 	movl   $0xf0105e4f,0xc(%esp)
f0102c0b:	f0 
f0102c0c:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102c13:	f0 
f0102c14:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f0102c1b:	00 
f0102c1c:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102c23:	e8 8e d4 ff ff       	call   f01000b6 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102c28:	83 3c 82 00          	cmpl   $0x0,(%edx,%eax,4)
f0102c2c:	74 24                	je     f0102c52 <mem_init+0x18ee>
f0102c2e:	c7 44 24 0c 60 5e 10 	movl   $0xf0105e60,0xc(%esp)
f0102c35:	f0 
f0102c36:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102c3d:	f0 
f0102c3e:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f0102c45:	00 
f0102c46:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102c4d:	e8 64 d4 ff ff       	call   f01000b6 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102c52:	83 c0 01             	add    $0x1,%eax
f0102c55:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102c5a:	0f 85 29 ff ff ff    	jne    f0102b89 <mem_init+0x1825>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102c60:	c7 04 24 a0 5a 10 f0 	movl   $0xf0105aa0,(%esp)
f0102c67:	e8 40 0b 00 00       	call   f01037ac <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102c6c:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0102c71:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c76:	77 20                	ja     f0102c98 <mem_init+0x1934>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c78:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c7c:	c7 44 24 08 08 53 10 	movl   $0xf0105308,0x8(%esp)
f0102c83:	f0 
f0102c84:	c7 44 24 04 ec 00 00 	movl   $0xec,0x4(%esp)
f0102c8b:	00 
f0102c8c:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102c93:	e8 1e d4 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102c98:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102c9d:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102ca0:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ca5:	e8 df dd ff ff       	call   f0100a89 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102caa:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102cad:	83 e0 f3             	and    $0xfffffff3,%eax
f0102cb0:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102cb5:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102cb8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102cbf:	e8 79 e2 ff ff       	call   f0100f3d <page_alloc>
f0102cc4:	89 c3                	mov    %eax,%ebx
f0102cc6:	85 c0                	test   %eax,%eax
f0102cc8:	75 24                	jne    f0102cee <mem_init+0x198a>
f0102cca:	c7 44 24 0c 5c 5c 10 	movl   $0xf0105c5c,0xc(%esp)
f0102cd1:	f0 
f0102cd2:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102cd9:	f0 
f0102cda:	c7 44 24 04 29 04 00 	movl   $0x429,0x4(%esp)
f0102ce1:	00 
f0102ce2:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102ce9:	e8 c8 d3 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0102cee:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102cf5:	e8 43 e2 ff ff       	call   f0100f3d <page_alloc>
f0102cfa:	89 c7                	mov    %eax,%edi
f0102cfc:	85 c0                	test   %eax,%eax
f0102cfe:	75 24                	jne    f0102d24 <mem_init+0x19c0>
f0102d00:	c7 44 24 0c 72 5c 10 	movl   $0xf0105c72,0xc(%esp)
f0102d07:	f0 
f0102d08:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102d0f:	f0 
f0102d10:	c7 44 24 04 2a 04 00 	movl   $0x42a,0x4(%esp)
f0102d17:	00 
f0102d18:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102d1f:	e8 92 d3 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f0102d24:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102d2b:	e8 0d e2 ff ff       	call   f0100f3d <page_alloc>
f0102d30:	89 c6                	mov    %eax,%esi
f0102d32:	85 c0                	test   %eax,%eax
f0102d34:	75 24                	jne    f0102d5a <mem_init+0x19f6>
f0102d36:	c7 44 24 0c 88 5c 10 	movl   $0xf0105c88,0xc(%esp)
f0102d3d:	f0 
f0102d3e:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102d45:	f0 
f0102d46:	c7 44 24 04 2b 04 00 	movl   $0x42b,0x4(%esp)
f0102d4d:	00 
f0102d4e:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102d55:	e8 5c d3 ff ff       	call   f01000b6 <_panic>
	page_free(pp0);
f0102d5a:	89 1c 24             	mov    %ebx,(%esp)
f0102d5d:	e8 6c e2 ff ff       	call   f0100fce <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0102d62:	89 f8                	mov    %edi,%eax
f0102d64:	e8 e7 db ff ff       	call   f0100950 <page2kva>
f0102d69:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102d70:	00 
f0102d71:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102d78:	00 
f0102d79:	89 04 24             	mov    %eax,(%esp)
f0102d7c:	e8 96 1b 00 00       	call   f0104917 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0102d81:	89 f0                	mov    %esi,%eax
f0102d83:	e8 c8 db ff ff       	call   f0100950 <page2kva>
f0102d88:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102d8f:	00 
f0102d90:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102d97:	00 
f0102d98:	89 04 24             	mov    %eax,(%esp)
f0102d9b:	e8 77 1b 00 00       	call   f0104917 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102da0:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102da7:	00 
f0102da8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102daf:	00 
f0102db0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102db4:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0102db9:	89 04 24             	mov    %eax,(%esp)
f0102dbc:	e8 e1 e4 ff ff       	call   f01012a2 <page_insert>
	assert(pp1->pp_ref == 1);
f0102dc1:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102dc6:	74 24                	je     f0102dec <mem_init+0x1a88>
f0102dc8:	c7 44 24 0c 59 5d 10 	movl   $0xf0105d59,0xc(%esp)
f0102dcf:	f0 
f0102dd0:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102dd7:	f0 
f0102dd8:	c7 44 24 04 30 04 00 	movl   $0x430,0x4(%esp)
f0102ddf:	00 
f0102de0:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102de7:	e8 ca d2 ff ff       	call   f01000b6 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102dec:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102df3:	01 01 01 
f0102df6:	74 24                	je     f0102e1c <mem_init+0x1ab8>
f0102df8:	c7 44 24 0c c0 5a 10 	movl   $0xf0105ac0,0xc(%esp)
f0102dff:	f0 
f0102e00:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102e07:	f0 
f0102e08:	c7 44 24 04 31 04 00 	movl   $0x431,0x4(%esp)
f0102e0f:	00 
f0102e10:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102e17:	e8 9a d2 ff ff       	call   f01000b6 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102e1c:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102e23:	00 
f0102e24:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102e2b:	00 
f0102e2c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102e30:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0102e35:	89 04 24             	mov    %eax,(%esp)
f0102e38:	e8 65 e4 ff ff       	call   f01012a2 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102e3d:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102e44:	02 02 02 
f0102e47:	74 24                	je     f0102e6d <mem_init+0x1b09>
f0102e49:	c7 44 24 0c e4 5a 10 	movl   $0xf0105ae4,0xc(%esp)
f0102e50:	f0 
f0102e51:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102e58:	f0 
f0102e59:	c7 44 24 04 33 04 00 	movl   $0x433,0x4(%esp)
f0102e60:	00 
f0102e61:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102e68:	e8 49 d2 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0102e6d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102e72:	74 24                	je     f0102e98 <mem_init+0x1b34>
f0102e74:	c7 44 24 0c 7b 5d 10 	movl   $0xf0105d7b,0xc(%esp)
f0102e7b:	f0 
f0102e7c:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102e83:	f0 
f0102e84:	c7 44 24 04 34 04 00 	movl   $0x434,0x4(%esp)
f0102e8b:	00 
f0102e8c:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102e93:	e8 1e d2 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 0);
f0102e98:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102e9d:	74 24                	je     f0102ec3 <mem_init+0x1b5f>
f0102e9f:	c7 44 24 0c e5 5d 10 	movl   $0xf0105de5,0xc(%esp)
f0102ea6:	f0 
f0102ea7:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102eae:	f0 
f0102eaf:	c7 44 24 04 35 04 00 	movl   $0x435,0x4(%esp)
f0102eb6:	00 
f0102eb7:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102ebe:	e8 f3 d1 ff ff       	call   f01000b6 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102ec3:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102eca:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102ecd:	89 f0                	mov    %esi,%eax
f0102ecf:	e8 7c da ff ff       	call   f0100950 <page2kva>
f0102ed4:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0102eda:	74 24                	je     f0102f00 <mem_init+0x1b9c>
f0102edc:	c7 44 24 0c 08 5b 10 	movl   $0xf0105b08,0xc(%esp)
f0102ee3:	f0 
f0102ee4:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102eeb:	f0 
f0102eec:	c7 44 24 04 37 04 00 	movl   $0x437,0x4(%esp)
f0102ef3:	00 
f0102ef4:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102efb:	e8 b6 d1 ff ff       	call   f01000b6 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102f00:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102f07:	00 
f0102f08:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0102f0d:	89 04 24             	mov    %eax,(%esp)
f0102f10:	e8 4f e3 ff ff       	call   f0101264 <page_remove>
	assert(pp2->pp_ref == 0);
f0102f15:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102f1a:	74 24                	je     f0102f40 <mem_init+0x1bdc>
f0102f1c:	c7 44 24 0c b3 5d 10 	movl   $0xf0105db3,0xc(%esp)
f0102f23:	f0 
f0102f24:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102f2b:	f0 
f0102f2c:	c7 44 24 04 39 04 00 	movl   $0x439,0x4(%esp)
f0102f33:	00 
f0102f34:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102f3b:	e8 76 d1 ff ff       	call   f01000b6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102f40:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0102f45:	8b 08                	mov    (%eax),%ecx
f0102f47:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102f4d:	89 da                	mov    %ebx,%edx
f0102f4f:	2b 15 8c df 17 f0    	sub    0xf017df8c,%edx
f0102f55:	c1 fa 03             	sar    $0x3,%edx
f0102f58:	c1 e2 0c             	shl    $0xc,%edx
f0102f5b:	39 d1                	cmp    %edx,%ecx
f0102f5d:	74 24                	je     f0102f83 <mem_init+0x1c1f>
f0102f5f:	c7 44 24 0c 18 56 10 	movl   $0xf0105618,0xc(%esp)
f0102f66:	f0 
f0102f67:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102f6e:	f0 
f0102f6f:	c7 44 24 04 3c 04 00 	movl   $0x43c,0x4(%esp)
f0102f76:	00 
f0102f77:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102f7e:	e8 33 d1 ff ff       	call   f01000b6 <_panic>
	kern_pgdir[0] = 0;
f0102f83:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102f89:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102f8e:	74 24                	je     f0102fb4 <mem_init+0x1c50>
f0102f90:	c7 44 24 0c 6a 5d 10 	movl   $0xf0105d6a,0xc(%esp)
f0102f97:	f0 
f0102f98:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0102f9f:	f0 
f0102fa0:	c7 44 24 04 3e 04 00 	movl   $0x43e,0x4(%esp)
f0102fa7:	00 
f0102fa8:	c7 04 24 6b 5b 10 f0 	movl   $0xf0105b6b,(%esp)
f0102faf:	e8 02 d1 ff ff       	call   f01000b6 <_panic>
	pp0->pp_ref = 0;
f0102fb4:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102fba:	89 1c 24             	mov    %ebx,(%esp)
f0102fbd:	e8 0c e0 ff ff       	call   f0100fce <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102fc2:	c7 04 24 34 5b 10 f0 	movl   $0xf0105b34,(%esp)
f0102fc9:	e8 de 07 00 00       	call   f01037ac <cprintf>
f0102fce:	eb 0f                	jmp    f0102fdf <mem_init+0x1c7b>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102fd0:	89 f2                	mov    %esi,%edx
f0102fd2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102fd5:	e8 bb d9 ff ff       	call   f0100995 <check_va2pa>
f0102fda:	e9 8e fa ff ff       	jmp    f0102a6d <mem_init+0x1709>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102fdf:	83 c4 4c             	add    $0x4c,%esp
f0102fe2:	5b                   	pop    %ebx
f0102fe3:	5e                   	pop    %esi
f0102fe4:	5f                   	pop    %edi
f0102fe5:	5d                   	pop    %ebp
f0102fe6:	c3                   	ret    

f0102fe7 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102fe7:	55                   	push   %ebp
f0102fe8:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102fea:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102fed:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102ff0:	5d                   	pop    %ebp
f0102ff1:	c3                   	ret    

f0102ff2 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102ff2:	55                   	push   %ebp
f0102ff3:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.

	return 0;
}
f0102ff5:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ffa:	5d                   	pop    %ebp
f0102ffb:	c3                   	ret    

f0102ffc <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102ffc:	55                   	push   %ebp
f0102ffd:	89 e5                	mov    %esp,%ebp
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
		cprintf("[%08x] user_mem_check assertion failure for "
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
	}
}
f0102fff:	5d                   	pop    %ebp
f0103000:	c3                   	ret    

f0103001 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0103001:	55                   	push   %ebp
f0103002:	89 e5                	mov    %esp,%ebp
f0103004:	57                   	push   %edi
f0103005:	56                   	push   %esi
f0103006:	53                   	push   %ebx
f0103007:	83 ec 1c             	sub    $0x1c,%esp
f010300a:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
f010300c:	89 d3                	mov    %edx,%ebx
f010300e:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
f0103014:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f010301b:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	
	while (vaBegin<vaEnd){
f0103021:	eb 4d                	jmp    f0103070 <region_alloc+0x6f>
		struct PageInfo *p = page_alloc(0);
f0103023:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010302a:	e8 0e df ff ff       	call   f0100f3d <page_alloc>
		if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
f010302f:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0103036:	00 
f0103037:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010303b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010303f:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103042:	89 04 24             	mov    %eax,(%esp)
f0103045:	e8 58 e2 ff ff       	call   f01012a2 <page_insert>
f010304a:	85 c0                	test   %eax,%eax
f010304c:	74 1c                	je     f010306a <region_alloc+0x69>
			panic("Page table couldn't be allocated!!");
f010304e:	c7 44 24 08 70 5e 10 	movl   $0xf0105e70,0x8(%esp)
f0103055:	f0 
f0103056:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
f010305d:	00 
f010305e:	c7 04 24 12 5f 10 f0 	movl   $0xf0105f12,(%esp)
f0103065:	e8 4c d0 ff ff       	call   f01000b6 <_panic>
		}
		vaBegin += PGSIZE;
f010306a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
	
	while (vaBegin<vaEnd){
f0103070:	39 f3                	cmp    %esi,%ebx
f0103072:	72 af                	jb     f0103023 <region_alloc+0x22>
		if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
			panic("Page table couldn't be allocated!!");
		}
		vaBegin += PGSIZE;
	}
}
f0103074:	83 c4 1c             	add    $0x1c,%esp
f0103077:	5b                   	pop    %ebx
f0103078:	5e                   	pop    %esi
f0103079:	5f                   	pop    %edi
f010307a:	5d                   	pop    %ebp
f010307b:	c3                   	ret    

f010307c <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f010307c:	55                   	push   %ebp
f010307d:	89 e5                	mov    %esp,%ebp
f010307f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103082:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0103085:	85 c0                	test   %eax,%eax
f0103087:	75 11                	jne    f010309a <envid2env+0x1e>
		*env_store = curenv;
f0103089:	a1 c8 d2 17 f0       	mov    0xf017d2c8,%eax
f010308e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103091:	89 01                	mov    %eax,(%ecx)
		return 0;
f0103093:	b8 00 00 00 00       	mov    $0x0,%eax
f0103098:	eb 5e                	jmp    f01030f8 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f010309a:	89 c2                	mov    %eax,%edx
f010309c:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01030a2:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01030a5:	c1 e2 05             	shl    $0x5,%edx
f01030a8:	03 15 cc d2 17 f0    	add    0xf017d2cc,%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f01030ae:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f01030b2:	74 05                	je     f01030b9 <envid2env+0x3d>
f01030b4:	39 42 48             	cmp    %eax,0x48(%edx)
f01030b7:	74 10                	je     f01030c9 <envid2env+0x4d>
		*env_store = 0;
f01030b9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030bc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01030c2:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01030c7:	eb 2f                	jmp    f01030f8 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01030c9:	84 c9                	test   %cl,%cl
f01030cb:	74 21                	je     f01030ee <envid2env+0x72>
f01030cd:	a1 c8 d2 17 f0       	mov    0xf017d2c8,%eax
f01030d2:	39 c2                	cmp    %eax,%edx
f01030d4:	74 18                	je     f01030ee <envid2env+0x72>
f01030d6:	8b 40 48             	mov    0x48(%eax),%eax
f01030d9:	39 42 4c             	cmp    %eax,0x4c(%edx)
f01030dc:	74 10                	je     f01030ee <envid2env+0x72>
		*env_store = 0;
f01030de:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030e1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01030e7:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01030ec:	eb 0a                	jmp    f01030f8 <envid2env+0x7c>
	}

	*env_store = e;
f01030ee:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030f1:	89 10                	mov    %edx,(%eax)
	return 0;
f01030f3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01030f8:	5d                   	pop    %ebp
f01030f9:	c3                   	ret    

f01030fa <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01030fa:	55                   	push   %ebp
f01030fb:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f01030fd:	b8 00 b3 11 f0       	mov    $0xf011b300,%eax
f0103102:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0103105:	b8 23 00 00 00       	mov    $0x23,%eax
f010310a:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f010310c:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f010310e:	b0 10                	mov    $0x10,%al
f0103110:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0103112:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0103114:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f0103116:	ea 1d 31 10 f0 08 00 	ljmp   $0x8,$0xf010311d
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f010311d:	b0 00                	mov    $0x0,%al
f010311f:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0103122:	5d                   	pop    %ebp
f0103123:	c3                   	ret    

f0103124 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0103124:	8b 0d d0 d2 17 f0    	mov    0xf017d2d0,%ecx
f010312a:	a1 cc d2 17 f0       	mov    0xf017d2cc,%eax
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
f010312f:	ba 00 04 00 00       	mov    $0x400,%edx
f0103134:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = NULL;
f010313b:	c7 40 44 00 00 00 00 	movl   $0x0,0x44(%eax)

		if (!env_free_list){		
f0103142:	85 c9                	test   %ecx,%ecx
f0103144:	74 05                	je     f010314b <env_init+0x27>
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
		}
		else{
		envs[i-1].env_link = &envs[i];
f0103146:	89 40 e4             	mov    %eax,-0x1c(%eax)
f0103149:	eb 02                	jmp    f010314d <env_init+0x29>
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
		envs[i].env_link = NULL;

		if (!env_free_list){		
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
f010314b:	89 c1                	mov    %eax,%ecx
f010314d:	83 c0 60             	add    $0x60,%eax
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
f0103150:	83 ea 01             	sub    $0x1,%edx
f0103153:	75 df                	jne    f0103134 <env_init+0x10>
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0103155:	55                   	push   %ebp
f0103156:	89 e5                	mov    %esp,%ebp
f0103158:	89 0d d0 d2 17 f0    	mov    %ecx,0xf017d2d0
		envs[i-1].env_link = &envs[i];
		}	//Previous env is linked to this current env
	}

	// Per-CPU part of the initialization
	env_init_percpu();
f010315e:	e8 97 ff ff ff       	call   f01030fa <env_init_percpu>
}
f0103163:	5d                   	pop    %ebp
f0103164:	c3                   	ret    

f0103165 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0103165:	55                   	push   %ebp
f0103166:	89 e5                	mov    %esp,%ebp
f0103168:	53                   	push   %ebx
f0103169:	83 ec 14             	sub    $0x14,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f010316c:	8b 1d d0 d2 17 f0    	mov    0xf017d2d0,%ebx
f0103172:	85 db                	test   %ebx,%ebx
f0103174:	0f 84 6c 01 00 00    	je     f01032e6 <env_alloc+0x181>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f010317a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0103181:	e8 b7 dd ff ff       	call   f0100f3d <page_alloc>
f0103186:	85 c0                	test   %eax,%eax
f0103188:	0f 84 5f 01 00 00    	je     f01032ed <env_alloc+0x188>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f010318e:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
f0103193:	2b 05 8c df 17 f0    	sub    0xf017df8c,%eax
f0103199:	c1 f8 03             	sar    $0x3,%eax
f010319c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010319f:	89 c2                	mov    %eax,%edx
f01031a1:	c1 ea 0c             	shr    $0xc,%edx
f01031a4:	3b 15 84 df 17 f0    	cmp    0xf017df84,%edx
f01031aa:	72 20                	jb     f01031cc <env_alloc+0x67>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01031ac:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01031b0:	c7 44 24 08 e4 52 10 	movl   $0xf01052e4,0x8(%esp)
f01031b7:	f0 
f01031b8:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01031bf:	00 
f01031c0:	c7 04 24 5d 5b 10 f0 	movl   $0xf0105b5d,(%esp)
f01031c7:	e8 ea ce ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f01031cc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01031d1:	89 43 5c             	mov    %eax,0x5c(%ebx)
	e->env_pgdir = (pde_t*)page2kva(p);
f01031d4:	b8 00 00 00 00       	mov    $0x0,%eax

	for (i = 0; i < NPDENTRIES; ++i) {
		e->env_pgdir[i] = kern_pgdir[i];  //Mapping all 1024 entries of the kernel
f01031d9:	8b 15 88 df 17 f0    	mov    0xf017df88,%edx
f01031df:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f01031e2:	8b 53 5c             	mov    0x5c(%ebx),%edx
f01031e5:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f01031e8:	83 c0 04             	add    $0x4,%eax

	// LAB 3: Your code here.
	p->pp_ref++;
	e->env_pgdir = (pde_t*)page2kva(p);

	for (i = 0; i < NPDENTRIES; ++i) {
f01031eb:	3d 00 10 00 00       	cmp    $0x1000,%eax
f01031f0:	75 e7                	jne    f01031d9 <env_alloc+0x74>
						 //pgdir to the environment pgdir
	}
	
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01031f2:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01031f5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031fa:	77 20                	ja     f010321c <env_alloc+0xb7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031fc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103200:	c7 44 24 08 08 53 10 	movl   $0xf0105308,0x8(%esp)
f0103207:	f0 
f0103208:	c7 44 24 04 cc 00 00 	movl   $0xcc,0x4(%esp)
f010320f:	00 
f0103210:	c7 04 24 12 5f 10 f0 	movl   $0xf0105f12,(%esp)
f0103217:	e8 9a ce ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010321c:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0103222:	83 ca 05             	or     $0x5,%edx
f0103225:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f010322b:	8b 43 48             	mov    0x48(%ebx),%eax
f010322e:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0103233:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0103238:	ba 00 10 00 00       	mov    $0x1000,%edx
f010323d:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0103240:	89 da                	mov    %ebx,%edx
f0103242:	2b 15 cc d2 17 f0    	sub    0xf017d2cc,%edx
f0103248:	c1 fa 05             	sar    $0x5,%edx
f010324b:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0103251:	09 d0                	or     %edx,%eax
f0103253:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0103256:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103259:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f010325c:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0103263:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f010326a:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103271:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0103278:	00 
f0103279:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103280:	00 
f0103281:	89 1c 24             	mov    %ebx,(%esp)
f0103284:	e8 8e 16 00 00       	call   f0104917 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0103289:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f010328f:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103295:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f010329b:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f01032a2:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f01032a8:	8b 43 44             	mov    0x44(%ebx),%eax
f01032ab:	a3 d0 d2 17 f0       	mov    %eax,0xf017d2d0
	*newenv_store = e;
f01032b0:	8b 45 08             	mov    0x8(%ebp),%eax
f01032b3:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01032b5:	8b 53 48             	mov    0x48(%ebx),%edx
f01032b8:	a1 c8 d2 17 f0       	mov    0xf017d2c8,%eax
f01032bd:	85 c0                	test   %eax,%eax
f01032bf:	74 05                	je     f01032c6 <env_alloc+0x161>
f01032c1:	8b 40 48             	mov    0x48(%eax),%eax
f01032c4:	eb 05                	jmp    f01032cb <env_alloc+0x166>
f01032c6:	b8 00 00 00 00       	mov    $0x0,%eax
f01032cb:	89 54 24 08          	mov    %edx,0x8(%esp)
f01032cf:	89 44 24 04          	mov    %eax,0x4(%esp)
f01032d3:	c7 04 24 1d 5f 10 f0 	movl   $0xf0105f1d,(%esp)
f01032da:	e8 cd 04 00 00       	call   f01037ac <cprintf>
	return 0;
f01032df:	b8 00 00 00 00       	mov    $0x0,%eax
f01032e4:	eb 0c                	jmp    f01032f2 <env_alloc+0x18d>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f01032e6:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f01032eb:	eb 05                	jmp    f01032f2 <env_alloc+0x18d>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f01032ed:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f01032f2:	83 c4 14             	add    $0x14,%esp
f01032f5:	5b                   	pop    %ebx
f01032f6:	5d                   	pop    %ebp
f01032f7:	c3                   	ret    

f01032f8 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f01032f8:	55                   	push   %ebp
f01032f9:	89 e5                	mov    %esp,%ebp
f01032fb:	57                   	push   %edi
f01032fc:	56                   	push   %esi
f01032fd:	53                   	push   %ebx
f01032fe:	83 ec 3c             	sub    $0x3c,%esp
f0103301:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	int r;
	struct Env *env =NULL;
f0103304:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	r = env_alloc( &env, 0);
f010330b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103312:	00 
f0103313:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103316:	89 04 24             	mov    %eax,(%esp)
f0103319:	e8 47 fe ff ff       	call   f0103165 <env_alloc>
	if (r){
f010331e:	85 c0                	test   %eax,%eax
f0103320:	74 20                	je     f0103342 <env_create+0x4a>
	panic("env_alloc: %e", r);
f0103322:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103326:	c7 44 24 08 32 5f 10 	movl   $0xf0105f32,0x8(%esp)
f010332d:	f0 
f010332e:	c7 44 24 04 a2 01 00 	movl   $0x1a2,0x4(%esp)
f0103335:	00 
f0103336:	c7 04 24 12 5f 10 f0 	movl   $0xf0105f12,(%esp)
f010333d:	e8 74 cd ff ff       	call   f01000b6 <_panic>
	}
	
	load_icode(env,binary);
f0103342:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103345:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Get the beginning and end of program header table
	//Details of struct proghdr are in /lab/inc/elf.h

	// is this a valid ELF?
	
	if (((struct Elf*)binary)->e_magic != ELF_MAGIC)
f0103348:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f010334e:	74 1c                	je     f010336c <env_create+0x74>
	{
		panic ("Not a valid ELF binary image");
f0103350:	c7 44 24 08 40 5f 10 	movl   $0xf0105f40,0x8(%esp)
f0103357:	f0 
f0103358:	c7 44 24 04 71 01 00 	movl   $0x171,0x4(%esp)
f010335f:	00 
f0103360:	c7 04 24 12 5f 10 f0 	movl   $0xf0105f12,(%esp)
f0103367:	e8 4a cd ff ff       	call   f01000b6 <_panic>
	}

	struct Proghdr *ph =(struct Proghdr *)(binary + ((struct Elf*)binary)->e_phoff); //phoff is the offset
f010336c:	89 fb                	mov    %edi,%ebx
f010336e:	03 5f 1c             	add    0x1c(%edi),%ebx
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
f0103371:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0103375:	c1 e6 05             	shl    $0x5,%esi
f0103378:	01 de                	add    %ebx,%esi
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));
f010337a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010337d:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103380:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103385:	77 20                	ja     f01033a7 <env_create+0xaf>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103387:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010338b:	c7 44 24 08 08 53 10 	movl   $0xf0105308,0x8(%esp)
f0103392:	f0 
f0103393:	c7 44 24 04 78 01 00 	movl   $0x178,0x4(%esp)
f010339a:	00 
f010339b:	c7 04 24 12 5f 10 f0 	movl   $0xf0105f12,(%esp)
f01033a2:	e8 0f cd ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01033a7:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01033ac:	0f 22 d8             	mov    %eax,%cr3
f01033af:	eb 71                	jmp    f0103422 <env_create+0x12a>

	for (;ph<phEnd;++ph){
		if (ph->p_type == ELF_PROG_LOAD){	//Check whether the type is ELF_PROG_LOAD
f01033b1:	83 3b 01             	cmpl   $0x1,(%ebx)
f01033b4:	75 69                	jne    f010341f <env_create+0x127>
		
		if(ph->p_memsz < ph->p_filesz){
f01033b6:	8b 4b 14             	mov    0x14(%ebx),%ecx
f01033b9:	3b 4b 10             	cmp    0x10(%ebx),%ecx
f01033bc:	73 1c                	jae    f01033da <env_create+0xe2>
		panic ("Memory size is smaller than file size!!");
f01033be:	c7 44 24 08 94 5e 10 	movl   $0xf0105e94,0x8(%esp)
f01033c5:	f0 
f01033c6:	c7 44 24 04 7e 01 00 	movl   $0x17e,0x4(%esp)
f01033cd:	00 
f01033ce:	c7 04 24 12 5f 10 f0 	movl   $0xf0105f12,(%esp)
f01033d5:	e8 dc cc ff ff       	call   f01000b6 <_panic>
		}
		region_alloc(e, (void *)ph->p_va, ph->p_memsz);  //Allocate region per segment
f01033da:	8b 53 08             	mov    0x8(%ebx),%edx
f01033dd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01033e0:	e8 1c fc ff ff       	call   f0103001 <region_alloc>
	

		memcpy((void*)ph->p_va, (void*)(binary + ph->p_offset), ph->p_filesz); //Load Binary into memory
f01033e5:	8b 43 10             	mov    0x10(%ebx),%eax
f01033e8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01033ec:	89 f8                	mov    %edi,%eax
f01033ee:	03 43 04             	add    0x4(%ebx),%eax
f01033f1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01033f5:	8b 43 08             	mov    0x8(%ebx),%eax
f01033f8:	89 04 24             	mov    %eax,(%esp)
f01033fb:	e8 cc 15 00 00       	call   f01049cc <memcpy>

		memset((void*)(ph->p_va + ph->p_filesz),0,ph->p_memsz-ph->p_filesz);  //Clear the rest of the memory, i.e the bss segment
f0103400:	8b 43 10             	mov    0x10(%ebx),%eax
f0103403:	8b 53 14             	mov    0x14(%ebx),%edx
f0103406:	29 c2                	sub    %eax,%edx
f0103408:	89 54 24 08          	mov    %edx,0x8(%esp)
f010340c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103413:	00 
f0103414:	03 43 08             	add    0x8(%ebx),%eax
f0103417:	89 04 24             	mov    %eax,(%esp)
f010341a:	e8 f8 14 00 00       	call   f0104917 <memset>
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));

	for (;ph<phEnd;++ph){
f010341f:	83 c3 20             	add    $0x20,%ebx
f0103422:	39 de                	cmp    %ebx,%esi
f0103424:	77 8b                	ja     f01033b1 <env_create+0xb9>
		}
		else{
			continue;
		}
	}
	lcr3(PADDR(kern_pgdir));   //Switch back to Kernel page directory
f0103426:	a1 88 df 17 f0       	mov    0xf017df88,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010342b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103430:	77 20                	ja     f0103452 <env_create+0x15a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103432:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103436:	c7 44 24 08 08 53 10 	movl   $0xf0105308,0x8(%esp)
f010343d:	f0 
f010343e:	c7 44 24 04 8b 01 00 	movl   $0x18b,0x4(%esp)
f0103445:	00 
f0103446:	c7 04 24 12 5f 10 f0 	movl   $0xf0105f12,(%esp)
f010344d:	e8 64 cc ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103452:	05 00 00 00 10       	add    $0x10000000,%eax
f0103457:	0f 22 d8             	mov    %eax,%cr3
	
	e->env_tf.tf_eip = ((struct Elf*)binary)->e_entry;   //Define the entry point of the env from the ELF binary entry point
f010345a:	8b 47 18             	mov    0x18(%edi),%eax
f010345d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103460:	89 47 30             	mov    %eax,0x30(%edi)

	region_alloc(e,(void *)USTACKTOP - PGSIZE, PGSIZE);
f0103463:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103468:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f010346d:	89 f8                	mov    %edi,%eax
f010346f:	e8 8d fb ff ff       	call   f0103001 <region_alloc>
	if (r){
	panic("env_alloc: %e", r);
	}
	
	load_icode(env,binary);
	env->env_type = type;
f0103474:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103477:	8b 55 0c             	mov    0xc(%ebp),%edx
f010347a:	89 50 50             	mov    %edx,0x50(%eax)
}
f010347d:	83 c4 3c             	add    $0x3c,%esp
f0103480:	5b                   	pop    %ebx
f0103481:	5e                   	pop    %esi
f0103482:	5f                   	pop    %edi
f0103483:	5d                   	pop    %ebp
f0103484:	c3                   	ret    

f0103485 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103485:	55                   	push   %ebp
f0103486:	89 e5                	mov    %esp,%ebp
f0103488:	57                   	push   %edi
f0103489:	56                   	push   %esi
f010348a:	53                   	push   %ebx
f010348b:	83 ec 2c             	sub    $0x2c,%esp
f010348e:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103491:	a1 c8 d2 17 f0       	mov    0xf017d2c8,%eax
f0103496:	39 c7                	cmp    %eax,%edi
f0103498:	75 37                	jne    f01034d1 <env_free+0x4c>
		lcr3(PADDR(kern_pgdir));
f010349a:	8b 15 88 df 17 f0    	mov    0xf017df88,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01034a0:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01034a6:	77 20                	ja     f01034c8 <env_free+0x43>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034a8:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01034ac:	c7 44 24 08 08 53 10 	movl   $0xf0105308,0x8(%esp)
f01034b3:	f0 
f01034b4:	c7 44 24 04 b8 01 00 	movl   $0x1b8,0x4(%esp)
f01034bb:	00 
f01034bc:	c7 04 24 12 5f 10 f0 	movl   $0xf0105f12,(%esp)
f01034c3:	e8 ee cb ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01034c8:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f01034ce:	0f 22 da             	mov    %edx,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01034d1:	8b 57 48             	mov    0x48(%edi),%edx
f01034d4:	85 c0                	test   %eax,%eax
f01034d6:	74 05                	je     f01034dd <env_free+0x58>
f01034d8:	8b 40 48             	mov    0x48(%eax),%eax
f01034db:	eb 05                	jmp    f01034e2 <env_free+0x5d>
f01034dd:	b8 00 00 00 00       	mov    $0x0,%eax
f01034e2:	89 54 24 08          	mov    %edx,0x8(%esp)
f01034e6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034ea:	c7 04 24 5d 5f 10 f0 	movl   $0xf0105f5d,(%esp)
f01034f1:	e8 b6 02 00 00       	call   f01037ac <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01034f6:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01034fd:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103500:	89 c8                	mov    %ecx,%eax
f0103502:	c1 e0 02             	shl    $0x2,%eax
f0103505:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103508:	8b 47 5c             	mov    0x5c(%edi),%eax
f010350b:	8b 34 88             	mov    (%eax,%ecx,4),%esi
f010350e:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103514:	0f 84 b7 00 00 00    	je     f01035d1 <env_free+0x14c>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f010351a:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103520:	89 f0                	mov    %esi,%eax
f0103522:	c1 e8 0c             	shr    $0xc,%eax
f0103525:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103528:	3b 05 84 df 17 f0    	cmp    0xf017df84,%eax
f010352e:	72 20                	jb     f0103550 <env_free+0xcb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103530:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103534:	c7 44 24 08 e4 52 10 	movl   $0xf01052e4,0x8(%esp)
f010353b:	f0 
f010353c:	c7 44 24 04 c7 01 00 	movl   $0x1c7,0x4(%esp)
f0103543:	00 
f0103544:	c7 04 24 12 5f 10 f0 	movl   $0xf0105f12,(%esp)
f010354b:	e8 66 cb ff ff       	call   f01000b6 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103550:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103553:	c1 e0 16             	shl    $0x16,%eax
f0103556:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103559:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f010355e:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103565:	01 
f0103566:	74 17                	je     f010357f <env_free+0xfa>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103568:	89 d8                	mov    %ebx,%eax
f010356a:	c1 e0 0c             	shl    $0xc,%eax
f010356d:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103570:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103574:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103577:	89 04 24             	mov    %eax,(%esp)
f010357a:	e8 e5 dc ff ff       	call   f0101264 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010357f:	83 c3 01             	add    $0x1,%ebx
f0103582:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103588:	75 d4                	jne    f010355e <env_free+0xd9>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f010358a:	8b 47 5c             	mov    0x5c(%edi),%eax
f010358d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103590:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103597:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010359a:	3b 05 84 df 17 f0    	cmp    0xf017df84,%eax
f01035a0:	72 1c                	jb     f01035be <env_free+0x139>
		panic("pa2page called with invalid pa");
f01035a2:	c7 44 24 08 bc 5e 10 	movl   $0xf0105ebc,0x8(%esp)
f01035a9:	f0 
f01035aa:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f01035b1:	00 
f01035b2:	c7 04 24 5d 5b 10 f0 	movl   $0xf0105b5d,(%esp)
f01035b9:	e8 f8 ca ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f01035be:	a1 8c df 17 f0       	mov    0xf017df8c,%eax
f01035c3:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01035c6:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		page_decref(pa2page(pa));
f01035c9:	89 04 24             	mov    %eax,(%esp)
f01035cc:	e8 58 da ff ff       	call   f0101029 <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01035d1:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f01035d5:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f01035dc:	0f 85 1b ff ff ff    	jne    f01034fd <env_free+0x78>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f01035e2:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01035e5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01035ea:	77 20                	ja     f010360c <env_free+0x187>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01035ec:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01035f0:	c7 44 24 08 08 53 10 	movl   $0xf0105308,0x8(%esp)
f01035f7:	f0 
f01035f8:	c7 44 24 04 d5 01 00 	movl   $0x1d5,0x4(%esp)
f01035ff:	00 
f0103600:	c7 04 24 12 5f 10 f0 	movl   $0xf0105f12,(%esp)
f0103607:	e8 aa ca ff ff       	call   f01000b6 <_panic>
	e->env_pgdir = 0;
f010360c:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103613:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103618:	c1 e8 0c             	shr    $0xc,%eax
f010361b:	3b 05 84 df 17 f0    	cmp    0xf017df84,%eax
f0103621:	72 1c                	jb     f010363f <env_free+0x1ba>
		panic("pa2page called with invalid pa");
f0103623:	c7 44 24 08 bc 5e 10 	movl   $0xf0105ebc,0x8(%esp)
f010362a:	f0 
f010362b:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0103632:	00 
f0103633:	c7 04 24 5d 5b 10 f0 	movl   $0xf0105b5d,(%esp)
f010363a:	e8 77 ca ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f010363f:	8b 15 8c df 17 f0    	mov    0xf017df8c,%edx
f0103645:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	page_decref(pa2page(pa));
f0103648:	89 04 24             	mov    %eax,(%esp)
f010364b:	e8 d9 d9 ff ff       	call   f0101029 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103650:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103657:	a1 d0 d2 17 f0       	mov    0xf017d2d0,%eax
f010365c:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f010365f:	89 3d d0 d2 17 f0    	mov    %edi,0xf017d2d0
}
f0103665:	83 c4 2c             	add    $0x2c,%esp
f0103668:	5b                   	pop    %ebx
f0103669:	5e                   	pop    %esi
f010366a:	5f                   	pop    %edi
f010366b:	5d                   	pop    %ebp
f010366c:	c3                   	ret    

f010366d <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f010366d:	55                   	push   %ebp
f010366e:	89 e5                	mov    %esp,%ebp
f0103670:	83 ec 18             	sub    $0x18,%esp
	env_free(e);
f0103673:	8b 45 08             	mov    0x8(%ebp),%eax
f0103676:	89 04 24             	mov    %eax,(%esp)
f0103679:	e8 07 fe ff ff       	call   f0103485 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f010367e:	c7 04 24 dc 5e 10 f0 	movl   $0xf0105edc,(%esp)
f0103685:	e8 22 01 00 00       	call   f01037ac <cprintf>
	while (1)
		monitor(NULL);
f010368a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103691:	e8 6f d1 ff ff       	call   f0100805 <monitor>
f0103696:	eb f2                	jmp    f010368a <env_destroy+0x1d>

f0103698 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103698:	55                   	push   %ebp
f0103699:	89 e5                	mov    %esp,%ebp
f010369b:	83 ec 18             	sub    $0x18,%esp
	__asm __volatile("movl %0,%%esp\n"
f010369e:	8b 65 08             	mov    0x8(%ebp),%esp
f01036a1:	61                   	popa   
f01036a2:	07                   	pop    %es
f01036a3:	1f                   	pop    %ds
f01036a4:	83 c4 08             	add    $0x8,%esp
f01036a7:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f01036a8:	c7 44 24 08 73 5f 10 	movl   $0xf0105f73,0x8(%esp)
f01036af:	f0 
f01036b0:	c7 44 24 04 fd 01 00 	movl   $0x1fd,0x4(%esp)
f01036b7:	00 
f01036b8:	c7 04 24 12 5f 10 f0 	movl   $0xf0105f12,(%esp)
f01036bf:	e8 f2 c9 ff ff       	call   f01000b6 <_panic>

f01036c4 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f01036c4:	55                   	push   %ebp
f01036c5:	89 e5                	mov    %esp,%ebp
f01036c7:	83 ec 18             	sub    $0x18,%esp
f01036ca:	8b 45 08             	mov    0x8(%ebp),%eax

	// LAB 3: Your code here.

	//check if this is the first call to env_run
	if (curenv == NULL){
	curenv = e;
f01036cd:	83 3d c8 d2 17 f0 00 	cmpl   $0x0,0xf017d2c8
f01036d4:	89 c2                	mov    %eax,%edx
f01036d6:	0f 45 15 c8 d2 17 f0 	cmovne 0xf017d2c8,%edx
f01036dd:	89 15 c8 d2 17 f0    	mov    %edx,0xf017d2c8
	}
	
	//If curenv state is running mode , set it to runnable 
	if (curenv->env_status == ENV_RUNNING){
f01036e3:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f01036e7:	75 07                	jne    f01036f0 <env_run+0x2c>
	 curenv->env_status = ENV_RUNNABLE;
f01036e9:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
	}
	curenv = e;	//Set the current environment to the new env
f01036f0:	a3 c8 d2 17 f0       	mov    %eax,0xf017d2c8
	curenv->env_status = ENV_RUNNING; //Set it to running state
f01036f5:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	++curenv->env_runs;	// Increment the env_runs counter
f01036fc:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(e->env_pgdir));	//Use lcr3 to switch to the env directory
f0103700:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103703:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103709:	77 20                	ja     f010372b <env_run+0x67>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010370b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010370f:	c7 44 24 08 08 53 10 	movl   $0xf0105308,0x8(%esp)
f0103716:	f0 
f0103717:	c7 44 24 04 28 02 00 	movl   $0x228,0x4(%esp)
f010371e:	00 
f010371f:	c7 04 24 12 5f 10 f0 	movl   $0xf0105f12,(%esp)
f0103726:	e8 8b c9 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010372b:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0103731:	0f 22 da             	mov    %edx,%cr3

	env_pop_tf(&e->env_tf);
f0103734:	89 04 24             	mov    %eax,(%esp)
f0103737:	e8 5c ff ff ff       	call   f0103698 <env_pop_tf>

f010373c <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010373c:	55                   	push   %ebp
f010373d:	89 e5                	mov    %esp,%ebp
f010373f:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103743:	ba 70 00 00 00       	mov    $0x70,%edx
f0103748:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103749:	b2 71                	mov    $0x71,%dl
f010374b:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f010374c:	0f b6 c0             	movzbl %al,%eax
}
f010374f:	5d                   	pop    %ebp
f0103750:	c3                   	ret    

f0103751 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103751:	55                   	push   %ebp
f0103752:	89 e5                	mov    %esp,%ebp
f0103754:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103758:	ba 70 00 00 00       	mov    $0x70,%edx
f010375d:	ee                   	out    %al,(%dx)
f010375e:	b2 71                	mov    $0x71,%dl
f0103760:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103763:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103764:	5d                   	pop    %ebp
f0103765:	c3                   	ret    

f0103766 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103766:	55                   	push   %ebp
f0103767:	89 e5                	mov    %esp,%ebp
f0103769:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010376c:	8b 45 08             	mov    0x8(%ebp),%eax
f010376f:	89 04 24             	mov    %eax,(%esp)
f0103772:	e8 9a ce ff ff       	call   f0100611 <cputchar>
	*cnt++;
}
f0103777:	c9                   	leave  
f0103778:	c3                   	ret    

f0103779 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103779:	55                   	push   %ebp
f010377a:	89 e5                	mov    %esp,%ebp
f010377c:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f010377f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103786:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103789:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010378d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103790:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103794:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103797:	89 44 24 04          	mov    %eax,0x4(%esp)
f010379b:	c7 04 24 66 37 10 f0 	movl   $0xf0103766,(%esp)
f01037a2:	e8 b7 0a 00 00       	call   f010425e <vprintfmt>
	return cnt;
}
f01037a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01037aa:	c9                   	leave  
f01037ab:	c3                   	ret    

f01037ac <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01037ac:	55                   	push   %ebp
f01037ad:	89 e5                	mov    %esp,%ebp
f01037af:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01037b2:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01037b5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01037b9:	8b 45 08             	mov    0x8(%ebp),%eax
f01037bc:	89 04 24             	mov    %eax,(%esp)
f01037bf:	e8 b5 ff ff ff       	call   f0103779 <vcprintf>
	va_end(ap);

	return cnt;
}
f01037c4:	c9                   	leave  
f01037c5:	c3                   	ret    
f01037c6:	66 90                	xchg   %ax,%ax
f01037c8:	66 90                	xchg   %ax,%ax
f01037ca:	66 90                	xchg   %ax,%ax
f01037cc:	66 90                	xchg   %ax,%ax
f01037ce:	66 90                	xchg   %ax,%ax

f01037d0 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01037d0:	55                   	push   %ebp
f01037d1:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f01037d3:	c7 05 04 db 17 f0 00 	movl   $0xf0000000,0xf017db04
f01037da:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f01037dd:	66 c7 05 08 db 17 f0 	movw   $0x10,0xf017db08
f01037e4:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f01037e6:	66 c7 05 48 b3 11 f0 	movw   $0x67,0xf011b348
f01037ed:	67 00 
f01037ef:	b8 00 db 17 f0       	mov    $0xf017db00,%eax
f01037f4:	66 a3 4a b3 11 f0    	mov    %ax,0xf011b34a
f01037fa:	89 c2                	mov    %eax,%edx
f01037fc:	c1 ea 10             	shr    $0x10,%edx
f01037ff:	88 15 4c b3 11 f0    	mov    %dl,0xf011b34c
f0103805:	c6 05 4e b3 11 f0 40 	movb   $0x40,0xf011b34e
f010380c:	c1 e8 18             	shr    $0x18,%eax
f010380f:	a2 4f b3 11 f0       	mov    %al,0xf011b34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103814:	c6 05 4d b3 11 f0 89 	movb   $0x89,0xf011b34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f010381b:	b8 28 00 00 00       	mov    $0x28,%eax
f0103820:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0103823:	b8 50 b3 11 f0       	mov    $0xf011b350,%eax
f0103828:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f010382b:	5d                   	pop    %ebp
f010382c:	c3                   	ret    

f010382d <trap_init>:
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i; 
	for (i=0; i<= T_SIMDERR;i++){
f010382d:	b8 00 00 00 00       	mov    $0x0,%eax
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
f0103832:	8b 14 85 56 b3 11 f0 	mov    -0xfee4caa(,%eax,4),%edx
f0103839:	66 89 14 c5 e0 d2 17 	mov    %dx,-0xfe82d20(,%eax,8)
f0103840:	f0 
f0103841:	66 c7 04 c5 e2 d2 17 	movw   $0x8,-0xfe82d1e(,%eax,8)
f0103848:	f0 08 00 
f010384b:	c6 04 c5 e4 d2 17 f0 	movb   $0x0,-0xfe82d1c(,%eax,8)
f0103852:	00 
f0103853:	c6 04 c5 e5 d2 17 f0 	movb   $0x8e,-0xfe82d1b(,%eax,8)
f010385a:	8e 
f010385b:	c1 ea 10             	shr    $0x10,%edx
f010385e:	66 89 14 c5 e6 d2 17 	mov    %dx,-0xfe82d1a(,%eax,8)
f0103865:	f0 
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i; 
	for (i=0; i<= T_SIMDERR;i++){
f0103866:	83 c0 01             	add    $0x1,%eax
f0103869:	83 f8 14             	cmp    $0x14,%eax
f010386c:	75 c4                	jne    f0103832 <trap_init+0x5>
}


void
trap_init(void)
{
f010386e:	55                   	push   %ebp
f010386f:	89 e5                	mov    %esp,%ebp
	for (i=0; i<= T_SIMDERR;i++){
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
	}

	//Interrupt 3 is a soft interrupt generated by user, hence the dpl of the gate will be checked with 3
  	SETGATE(idt[3],0,GD_KT,int_vector_table[3],3);
f0103871:	a1 62 b3 11 f0       	mov    0xf011b362,%eax
f0103876:	66 a3 f8 d2 17 f0    	mov    %ax,0xf017d2f8
f010387c:	66 c7 05 fa d2 17 f0 	movw   $0x8,0xf017d2fa
f0103883:	08 00 
f0103885:	c6 05 fc d2 17 f0 00 	movb   $0x0,0xf017d2fc
f010388c:	c6 05 fd d2 17 f0 ee 	movb   $0xee,0xf017d2fd
f0103893:	c1 e8 10             	shr    $0x10,%eax
f0103896:	66 a3 fe d2 17 f0    	mov    %ax,0xf017d2fe

	//similarly system call is setup by the user and hence the gate should be checked with 3 
	SETGATE(idt[T_SYSCALL],0,GD_KT,int_vector_table[T_SYSCALL],3);// T_SYSCALL = 3
f010389c:	a1 16 b4 11 f0       	mov    0xf011b416,%eax
f01038a1:	66 a3 60 d4 17 f0    	mov    %ax,0xf017d460
f01038a7:	66 c7 05 62 d4 17 f0 	movw   $0x8,0xf017d462
f01038ae:	08 00 
f01038b0:	c6 05 64 d4 17 f0 00 	movb   $0x0,0xf017d464
f01038b7:	c6 05 65 d4 17 f0 ee 	movb   $0xee,0xf017d465
f01038be:	c1 e8 10             	shr    $0x10,%eax
f01038c1:	66 a3 66 d4 17 f0    	mov    %ax,0xf017d466

	// Per-CPU setup 
	trap_init_percpu();
f01038c7:	e8 04 ff ff ff       	call   f01037d0 <trap_init_percpu>
}
f01038cc:	5d                   	pop    %ebp
f01038cd:	c3                   	ret    

f01038ce <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01038ce:	55                   	push   %ebp
f01038cf:	89 e5                	mov    %esp,%ebp
f01038d1:	53                   	push   %ebx
f01038d2:	83 ec 14             	sub    $0x14,%esp
f01038d5:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01038d8:	8b 03                	mov    (%ebx),%eax
f01038da:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038de:	c7 04 24 7f 5f 10 f0 	movl   $0xf0105f7f,(%esp)
f01038e5:	e8 c2 fe ff ff       	call   f01037ac <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01038ea:	8b 43 04             	mov    0x4(%ebx),%eax
f01038ed:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038f1:	c7 04 24 8e 5f 10 f0 	movl   $0xf0105f8e,(%esp)
f01038f8:	e8 af fe ff ff       	call   f01037ac <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01038fd:	8b 43 08             	mov    0x8(%ebx),%eax
f0103900:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103904:	c7 04 24 9d 5f 10 f0 	movl   $0xf0105f9d,(%esp)
f010390b:	e8 9c fe ff ff       	call   f01037ac <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103910:	8b 43 0c             	mov    0xc(%ebx),%eax
f0103913:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103917:	c7 04 24 ac 5f 10 f0 	movl   $0xf0105fac,(%esp)
f010391e:	e8 89 fe ff ff       	call   f01037ac <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103923:	8b 43 10             	mov    0x10(%ebx),%eax
f0103926:	89 44 24 04          	mov    %eax,0x4(%esp)
f010392a:	c7 04 24 bb 5f 10 f0 	movl   $0xf0105fbb,(%esp)
f0103931:	e8 76 fe ff ff       	call   f01037ac <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103936:	8b 43 14             	mov    0x14(%ebx),%eax
f0103939:	89 44 24 04          	mov    %eax,0x4(%esp)
f010393d:	c7 04 24 ca 5f 10 f0 	movl   $0xf0105fca,(%esp)
f0103944:	e8 63 fe ff ff       	call   f01037ac <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103949:	8b 43 18             	mov    0x18(%ebx),%eax
f010394c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103950:	c7 04 24 d9 5f 10 f0 	movl   $0xf0105fd9,(%esp)
f0103957:	e8 50 fe ff ff       	call   f01037ac <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f010395c:	8b 43 1c             	mov    0x1c(%ebx),%eax
f010395f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103963:	c7 04 24 e8 5f 10 f0 	movl   $0xf0105fe8,(%esp)
f010396a:	e8 3d fe ff ff       	call   f01037ac <cprintf>
}
f010396f:	83 c4 14             	add    $0x14,%esp
f0103972:	5b                   	pop    %ebx
f0103973:	5d                   	pop    %ebp
f0103974:	c3                   	ret    

f0103975 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103975:	55                   	push   %ebp
f0103976:	89 e5                	mov    %esp,%ebp
f0103978:	56                   	push   %esi
f0103979:	53                   	push   %ebx
f010397a:	83 ec 10             	sub    $0x10,%esp
f010397d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103980:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103984:	c7 04 24 1e 61 10 f0 	movl   $0xf010611e,(%esp)
f010398b:	e8 1c fe ff ff       	call   f01037ac <cprintf>
	print_regs(&tf->tf_regs);
f0103990:	89 1c 24             	mov    %ebx,(%esp)
f0103993:	e8 36 ff ff ff       	call   f01038ce <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103998:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f010399c:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039a0:	c7 04 24 39 60 10 f0 	movl   $0xf0106039,(%esp)
f01039a7:	e8 00 fe ff ff       	call   f01037ac <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f01039ac:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f01039b0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039b4:	c7 04 24 4c 60 10 f0 	movl   $0xf010604c,(%esp)
f01039bb:	e8 ec fd ff ff       	call   f01037ac <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01039c0:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f01039c3:	83 f8 13             	cmp    $0x13,%eax
f01039c6:	77 09                	ja     f01039d1 <print_trapframe+0x5c>
		return excnames[trapno];
f01039c8:	8b 14 85 20 63 10 f0 	mov    -0xfef9ce0(,%eax,4),%edx
f01039cf:	eb 10                	jmp    f01039e1 <print_trapframe+0x6c>
	if (trapno == T_SYSCALL)
		return "System call";
f01039d1:	83 f8 30             	cmp    $0x30,%eax
f01039d4:	ba f7 5f 10 f0       	mov    $0xf0105ff7,%edx
f01039d9:	b9 03 60 10 f0       	mov    $0xf0106003,%ecx
f01039de:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01039e1:	89 54 24 08          	mov    %edx,0x8(%esp)
f01039e5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039e9:	c7 04 24 5f 60 10 f0 	movl   $0xf010605f,(%esp)
f01039f0:	e8 b7 fd ff ff       	call   f01037ac <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01039f5:	3b 1d e0 da 17 f0    	cmp    0xf017dae0,%ebx
f01039fb:	75 19                	jne    f0103a16 <print_trapframe+0xa1>
f01039fd:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103a01:	75 13                	jne    f0103a16 <print_trapframe+0xa1>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103a03:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103a06:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a0a:	c7 04 24 71 60 10 f0 	movl   $0xf0106071,(%esp)
f0103a11:	e8 96 fd ff ff       	call   f01037ac <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f0103a16:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103a19:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a1d:	c7 04 24 80 60 10 f0 	movl   $0xf0106080,(%esp)
f0103a24:	e8 83 fd ff ff       	call   f01037ac <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103a29:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103a2d:	75 51                	jne    f0103a80 <print_trapframe+0x10b>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103a2f:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103a32:	89 c2                	mov    %eax,%edx
f0103a34:	83 e2 01             	and    $0x1,%edx
f0103a37:	ba 12 60 10 f0       	mov    $0xf0106012,%edx
f0103a3c:	b9 1d 60 10 f0       	mov    $0xf010601d,%ecx
f0103a41:	0f 45 ca             	cmovne %edx,%ecx
f0103a44:	89 c2                	mov    %eax,%edx
f0103a46:	83 e2 02             	and    $0x2,%edx
f0103a49:	ba 29 60 10 f0       	mov    $0xf0106029,%edx
f0103a4e:	be 2f 60 10 f0       	mov    $0xf010602f,%esi
f0103a53:	0f 44 d6             	cmove  %esi,%edx
f0103a56:	83 e0 04             	and    $0x4,%eax
f0103a59:	b8 34 60 10 f0       	mov    $0xf0106034,%eax
f0103a5e:	be 49 61 10 f0       	mov    $0xf0106149,%esi
f0103a63:	0f 44 c6             	cmove  %esi,%eax
f0103a66:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103a6a:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103a6e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a72:	c7 04 24 8e 60 10 f0 	movl   $0xf010608e,(%esp)
f0103a79:	e8 2e fd ff ff       	call   f01037ac <cprintf>
f0103a7e:	eb 0c                	jmp    f0103a8c <print_trapframe+0x117>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103a80:	c7 04 24 3c 5e 10 f0 	movl   $0xf0105e3c,(%esp)
f0103a87:	e8 20 fd ff ff       	call   f01037ac <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103a8c:	8b 43 30             	mov    0x30(%ebx),%eax
f0103a8f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a93:	c7 04 24 9d 60 10 f0 	movl   $0xf010609d,(%esp)
f0103a9a:	e8 0d fd ff ff       	call   f01037ac <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103a9f:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103aa3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103aa7:	c7 04 24 ac 60 10 f0 	movl   $0xf01060ac,(%esp)
f0103aae:	e8 f9 fc ff ff       	call   f01037ac <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103ab3:	8b 43 38             	mov    0x38(%ebx),%eax
f0103ab6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103aba:	c7 04 24 bf 60 10 f0 	movl   $0xf01060bf,(%esp)
f0103ac1:	e8 e6 fc ff ff       	call   f01037ac <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103ac6:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103aca:	74 27                	je     f0103af3 <print_trapframe+0x17e>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103acc:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103acf:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ad3:	c7 04 24 ce 60 10 f0 	movl   $0xf01060ce,(%esp)
f0103ada:	e8 cd fc ff ff       	call   f01037ac <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103adf:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103ae3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ae7:	c7 04 24 dd 60 10 f0 	movl   $0xf01060dd,(%esp)
f0103aee:	e8 b9 fc ff ff       	call   f01037ac <cprintf>
	}
}
f0103af3:	83 c4 10             	add    $0x10,%esp
f0103af6:	5b                   	pop    %ebx
f0103af7:	5e                   	pop    %esi
f0103af8:	5d                   	pop    %ebp
f0103af9:	c3                   	ret    

f0103afa <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103afa:	55                   	push   %ebp
f0103afb:	89 e5                	mov    %esp,%ebp
f0103afd:	53                   	push   %ebx
f0103afe:	83 ec 14             	sub    $0x14,%esp
f0103b01:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103b04:	0f 20 d0             	mov    %cr2,%eax
	// LAB 3: Your code here.


	//If the processor is already in kernel mode when the interrupt or exception occurs 
	//(the low 2 bits of the CS register are already zero), Hence we have to check the CS register to make sure its in kernel mode
	if ((tf->tf_cs & 0x11) == 0){
f0103b07:	f6 43 34 11          	testb  $0x11,0x34(%ebx)
f0103b0b:	75 20                	jne    f0103b2d <page_fault_handler+0x33>
		panic("Fault occured in kernel space on %08x \n",fault_va);
f0103b0d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103b11:	c7 44 24 08 94 62 10 	movl   $0xf0106294,0x8(%esp)
f0103b18:	f0 
f0103b19:	c7 44 24 04 e9 00 00 	movl   $0xe9,0x4(%esp)
f0103b20:	00 
f0103b21:	c7 04 24 f0 60 10 f0 	movl   $0xf01060f0,(%esp)
f0103b28:	e8 89 c5 ff ff       	call   f01000b6 <_panic>

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103b2d:	8b 53 30             	mov    0x30(%ebx),%edx
f0103b30:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103b34:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103b38:	a1 c8 d2 17 f0       	mov    0xf017d2c8,%eax
f0103b3d:	8b 40 48             	mov    0x48(%eax),%eax
f0103b40:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b44:	c7 04 24 bc 62 10 f0 	movl   $0xf01062bc,(%esp)
f0103b4b:	e8 5c fc ff ff       	call   f01037ac <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103b50:	89 1c 24             	mov    %ebx,(%esp)
f0103b53:	e8 1d fe ff ff       	call   f0103975 <print_trapframe>
	env_destroy(curenv);
f0103b58:	a1 c8 d2 17 f0       	mov    0xf017d2c8,%eax
f0103b5d:	89 04 24             	mov    %eax,(%esp)
f0103b60:	e8 08 fb ff ff       	call   f010366d <env_destroy>
}
f0103b65:	83 c4 14             	add    $0x14,%esp
f0103b68:	5b                   	pop    %ebx
f0103b69:	5d                   	pop    %ebp
f0103b6a:	c3                   	ret    

f0103b6b <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103b6b:	55                   	push   %ebp
f0103b6c:	89 e5                	mov    %esp,%ebp
f0103b6e:	57                   	push   %edi
f0103b6f:	56                   	push   %esi
f0103b70:	83 ec 10             	sub    $0x10,%esp
f0103b73:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103b76:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103b77:	9c                   	pushf  
f0103b78:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103b79:	f6 c4 02             	test   $0x2,%ah
f0103b7c:	74 24                	je     f0103ba2 <trap+0x37>
f0103b7e:	c7 44 24 0c fc 60 10 	movl   $0xf01060fc,0xc(%esp)
f0103b85:	f0 
f0103b86:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0103b8d:	f0 
f0103b8e:	c7 44 24 04 bc 00 00 	movl   $0xbc,0x4(%esp)
f0103b95:	00 
f0103b96:	c7 04 24 f0 60 10 f0 	movl   $0xf01060f0,(%esp)
f0103b9d:	e8 14 c5 ff ff       	call   f01000b6 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103ba2:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103ba6:	c7 04 24 15 61 10 f0 	movl   $0xf0106115,(%esp)
f0103bad:	e8 fa fb ff ff       	call   f01037ac <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103bb2:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103bb6:	83 e0 03             	and    $0x3,%eax
f0103bb9:	66 83 f8 03          	cmp    $0x3,%ax
f0103bbd:	75 3c                	jne    f0103bfb <trap+0x90>
		// Trapped from user mode.
		assert(curenv);
f0103bbf:	a1 c8 d2 17 f0       	mov    0xf017d2c8,%eax
f0103bc4:	85 c0                	test   %eax,%eax
f0103bc6:	75 24                	jne    f0103bec <trap+0x81>
f0103bc8:	c7 44 24 0c 30 61 10 	movl   $0xf0106130,0xc(%esp)
f0103bcf:	f0 
f0103bd0:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0103bd7:	f0 
f0103bd8:	c7 44 24 04 c2 00 00 	movl   $0xc2,0x4(%esp)
f0103bdf:	00 
f0103be0:	c7 04 24 f0 60 10 f0 	movl   $0xf01060f0,(%esp)
f0103be7:	e8 ca c4 ff ff       	call   f01000b6 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103bec:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103bf1:	89 c7                	mov    %eax,%edi
f0103bf3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103bf5:	8b 35 c8 d2 17 f0    	mov    0xf017d2c8,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103bfb:	89 35 e0 da 17 f0    	mov    %esi,0xf017dae0
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	//call trap_handler function for page_fault
	if(tf->tf_trapno == T_PGFLT){
f0103c01:	8b 46 28             	mov    0x28(%esi),%eax
f0103c04:	83 f8 0e             	cmp    $0xe,%eax
f0103c07:	75 0a                	jne    f0103c13 <trap+0xa8>
		page_fault_handler(tf);
f0103c09:	89 34 24             	mov    %esi,(%esp)
f0103c0c:	e8 e9 fe ff ff       	call   f0103afa <page_fault_handler>
f0103c11:	eb 12                	jmp    f0103c25 <trap+0xba>
	}
	
	else if(tf->tf_trapno == T_BRKPT){
f0103c13:	83 f8 03             	cmp    $0x3,%eax
f0103c16:	75 0d                	jne    f0103c25 <trap+0xba>
		monitor(tf);
f0103c18:	89 34 24             	mov    %esi,(%esp)
f0103c1b:	90                   	nop
f0103c1c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103c20:	e8 e0 cb ff ff       	call   f0100805 <monitor>
	}

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103c25:	89 34 24             	mov    %esi,(%esp)
f0103c28:	e8 48 fd ff ff       	call   f0103975 <print_trapframe>
	if (tf->tf_cs == GD_KT){
f0103c2d:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103c32:	75 1c                	jne    f0103c50 <trap+0xe5>
		panic("unhandled trap in kernel");
f0103c34:	c7 44 24 08 37 61 10 	movl   $0xf0106137,0x8(%esp)
f0103c3b:	f0 
f0103c3c:	c7 44 24 04 aa 00 00 	movl   $0xaa,0x4(%esp)
f0103c43:	00 
f0103c44:	c7 04 24 f0 60 10 f0 	movl   $0xf01060f0,(%esp)
f0103c4b:	e8 66 c4 ff ff       	call   f01000b6 <_panic>
	}
	else {
		env_destroy(curenv);
f0103c50:	a1 c8 d2 17 f0       	mov    0xf017d2c8,%eax
f0103c55:	89 04 24             	mov    %eax,(%esp)
f0103c58:	e8 10 fa ff ff       	call   f010366d <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103c5d:	a1 c8 d2 17 f0       	mov    0xf017d2c8,%eax
f0103c62:	85 c0                	test   %eax,%eax
f0103c64:	74 06                	je     f0103c6c <trap+0x101>
f0103c66:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103c6a:	74 24                	je     f0103c90 <trap+0x125>
f0103c6c:	c7 44 24 0c e0 62 10 	movl   $0xf01062e0,0xc(%esp)
f0103c73:	f0 
f0103c74:	c7 44 24 08 83 5b 10 	movl   $0xf0105b83,0x8(%esp)
f0103c7b:	f0 
f0103c7c:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
f0103c83:	00 
f0103c84:	c7 04 24 f0 60 10 f0 	movl   $0xf01060f0,(%esp)
f0103c8b:	e8 26 c4 ff ff       	call   f01000b6 <_panic>
	env_run(curenv);
f0103c90:	89 04 24             	mov    %eax,(%esp)
f0103c93:	e8 2c fa ff ff       	call   f01036c4 <env_run>

f0103c98 <handler_0>:
#define T_DEFAULT   500		// catchall
*/

//TRAPHANDLER_NOEC for traps without error code
// From 0-7 no error code requred
	TRAPHANDLER_NOEC(handler_0, 0)   #Divide error
f0103c98:	6a 00                	push   $0x0
f0103c9a:	6a 00                	push   $0x0
f0103c9c:	e9 ba 00 00 00       	jmp    f0103d5b <_alltraps>
f0103ca1:	90                   	nop

f0103ca2 <handler_1>:
	TRAPHANDLER_NOEC(handler_1, 1)   #Debug exceptions 
f0103ca2:	6a 00                	push   $0x0
f0103ca4:	6a 01                	push   $0x1
f0103ca6:	e9 b0 00 00 00       	jmp    f0103d5b <_alltraps>
f0103cab:	90                   	nop

f0103cac <handler_2>:
 	TRAPHANDLER_NOEC(handler_2, 2)   //NMI Interrupt
f0103cac:	6a 00                	push   $0x0
f0103cae:	6a 02                	push   $0x2
f0103cb0:	e9 a6 00 00 00       	jmp    f0103d5b <_alltraps>
f0103cb5:	90                   	nop

f0103cb6 <handler_3>:
	TRAPHANDLER_NOEC(handler_3, 3)   //Breakpoint
f0103cb6:	6a 00                	push   $0x0
f0103cb8:	6a 03                	push   $0x3
f0103cba:	e9 9c 00 00 00       	jmp    f0103d5b <_alltraps>
f0103cbf:	90                   	nop

f0103cc0 <handler_4>:
	TRAPHANDLER_NOEC(handler_4, 4)   //Overflow
f0103cc0:	6a 00                	push   $0x0
f0103cc2:	6a 04                	push   $0x4
f0103cc4:	e9 92 00 00 00       	jmp    f0103d5b <_alltraps>
f0103cc9:	90                   	nop

f0103cca <handler_5>:
	TRAPHANDLER_NOEC(handler_5, 5)   //Bounds check 
f0103cca:	6a 00                	push   $0x0
f0103ccc:	6a 05                	push   $0x5
f0103cce:	e9 88 00 00 00       	jmp    f0103d5b <_alltraps>
f0103cd3:	90                   	nop

f0103cd4 <handler_6>:
	TRAPHANDLER_NOEC(handler_6, 6)   //Invalid opcode
f0103cd4:	6a 00                	push   $0x0
f0103cd6:	6a 06                	push   $0x6
f0103cd8:	e9 7e 00 00 00       	jmp    f0103d5b <_alltraps>
f0103cdd:	90                   	nop

f0103cde <handler_7>:
	TRAPHANDLER_NOEC(handler_7, 7)   //Coprocessor not available
f0103cde:	6a 00                	push   $0x0
f0103ce0:	6a 07                	push   $0x7
f0103ce2:	e9 74 00 00 00       	jmp    f0103d5b <_alltraps>
f0103ce7:	90                   	nop

f0103ce8 <handler_8>:
	
	TRAPHANDLER(handler_8, 8)   // double fault
f0103ce8:	6a 08                	push   $0x8
f0103cea:	e9 6c 00 00 00       	jmp    f0103d5b <_alltraps>
f0103cef:	90                   	nop

f0103cf0 <handler_9>:
	
	TRAPHANDLER_NOEC(handler_9, 9)   //Coprocessor Segment Overrun
f0103cf0:	6a 00                	push   $0x0
f0103cf2:	6a 09                	push   $0x9
f0103cf4:	e9 62 00 00 00       	jmp    f0103d5b <_alltraps>
f0103cf9:	90                   	nop

f0103cfa <handler_10>:

	TRAPHANDLER(handler_10, 10)   // invalid task switch segment
f0103cfa:	6a 0a                	push   $0xa
f0103cfc:	e9 5a 00 00 00       	jmp    f0103d5b <_alltraps>
f0103d01:	90                   	nop

f0103d02 <handler_11>:
	TRAPHANDLER(handler_11, 11)   // segment not present
f0103d02:	6a 0b                	push   $0xb
f0103d04:	e9 52 00 00 00       	jmp    f0103d5b <_alltraps>
f0103d09:	90                   	nop

f0103d0a <handler_12>:
	TRAPHANDLER(handler_12, 12)   // stack exception
f0103d0a:	6a 0c                	push   $0xc
f0103d0c:	e9 4a 00 00 00       	jmp    f0103d5b <_alltraps>
f0103d11:	90                   	nop

f0103d12 <handler_13>:
	TRAPHANDLER(handler_13, 13)   // general protection fault
f0103d12:	6a 0d                	push   $0xd
f0103d14:	e9 42 00 00 00       	jmp    f0103d5b <_alltraps>
f0103d19:	90                   	nop

f0103d1a <handler_14>:
	TRAPHANDLER(handler_14, 14)   // page fault
f0103d1a:	6a 0e                	push   $0xe
f0103d1c:	e9 3a 00 00 00       	jmp    f0103d5b <_alltraps>
f0103d21:	90                   	nop

f0103d22 <handler_15>:

	TRAPHANDLER_NOEC(handler_15, 15)   // Reserved
f0103d22:	6a 00                	push   $0x0
f0103d24:	6a 0f                	push   $0xf
f0103d26:	e9 30 00 00 00       	jmp    f0103d5b <_alltraps>
f0103d2b:	90                   	nop

f0103d2c <handler_16>:

	TRAPHANDLER_NOEC(handler_16, 16)   // floating point error
f0103d2c:	6a 00                	push   $0x0
f0103d2e:	6a 10                	push   $0x10
f0103d30:	e9 26 00 00 00       	jmp    f0103d5b <_alltraps>
f0103d35:	90                   	nop

f0103d36 <handler_17>:

	TRAPHANDLER(handler_17, 17)   // aligment check
f0103d36:	6a 11                	push   $0x11
f0103d38:	e9 1e 00 00 00       	jmp    f0103d5b <_alltraps>
f0103d3d:	90                   	nop

f0103d3e <handler_18>:

	TRAPHANDLER_NOEC(handler_18, 18)   // machine check
f0103d3e:	6a 00                	push   $0x0
f0103d40:	6a 12                	push   $0x12
f0103d42:	e9 14 00 00 00       	jmp    f0103d5b <_alltraps>
f0103d47:	90                   	nop

f0103d48 <handler_19>:
	TRAPHANDLER_NOEC(handler_19, 19)   // SIMD floating point error
f0103d48:	6a 00                	push   $0x0
f0103d4a:	6a 13                	push   $0x13
f0103d4c:	e9 0a 00 00 00       	jmp    f0103d5b <_alltraps>
f0103d51:	90                   	nop

f0103d52 <handler_48>:

	TRAPHANDLER_NOEC(handler_48, 48)   // floating point error
f0103d52:	6a 00                	push   $0x0
f0103d54:	6a 30                	push   $0x30
f0103d56:	e9 00 00 00 00       	jmp    f0103d5b <_alltraps>

f0103d5b <_alltraps>:
 */

.globl _alltraps
_alltraps:
	#Remaining Trap frame
	push %ds
f0103d5b:	1e                   	push   %ds
	push %es
f0103d5c:	06                   	push   %es
	pushal
f0103d5d:	60                   	pusha  

	xor %ax, %ax 
f0103d5e:	66 31 c0             	xor    %ax,%ax
	movw $GD_KD, %ax
f0103d61:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f0103d65:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f0103d67:	8e c0                	mov    %eax,%es

	#call TRap 
	push %esp
f0103d69:	54                   	push   %esp
	call trap
f0103d6a:	e8 fc fd ff ff       	call   f0103b6b <trap>

	#restore operation
	addl $0x04, %esp
f0103d6f:	83 c4 04             	add    $0x4,%esp
	popal
f0103d72:	61                   	popa   
	pop %es
f0103d73:	07                   	pop    %es
	pop %ds
f0103d74:	1f                   	pop    %ds

	addl $0x08, %esp
f0103d75:	83 c4 08             	add    $0x8,%esp
	iret
f0103d78:	cf                   	iret   

f0103d79 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0103d79:	55                   	push   %ebp
f0103d7a:	89 e5                	mov    %esp,%ebp
f0103d7c:	83 ec 18             	sub    $0x18,%esp
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	panic("syscall not implemented");
f0103d7f:	c7 44 24 08 70 63 10 	movl   $0xf0106370,0x8(%esp)
f0103d86:	f0 
f0103d87:	c7 44 24 04 49 00 00 	movl   $0x49,0x4(%esp)
f0103d8e:	00 
f0103d8f:	c7 04 24 88 63 10 f0 	movl   $0xf0106388,(%esp)
f0103d96:	e8 1b c3 ff ff       	call   f01000b6 <_panic>

f0103d9b <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103d9b:	55                   	push   %ebp
f0103d9c:	89 e5                	mov    %esp,%ebp
f0103d9e:	57                   	push   %edi
f0103d9f:	56                   	push   %esi
f0103da0:	53                   	push   %ebx
f0103da1:	83 ec 14             	sub    $0x14,%esp
f0103da4:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103da7:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103daa:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103dad:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103db0:	8b 1a                	mov    (%edx),%ebx
f0103db2:	8b 01                	mov    (%ecx),%eax
f0103db4:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103db7:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0103dbe:	e9 88 00 00 00       	jmp    f0103e4b <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0103dc3:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103dc6:	01 d8                	add    %ebx,%eax
f0103dc8:	89 c7                	mov    %eax,%edi
f0103dca:	c1 ef 1f             	shr    $0x1f,%edi
f0103dcd:	01 c7                	add    %eax,%edi
f0103dcf:	d1 ff                	sar    %edi
f0103dd1:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0103dd4:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103dd7:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103dda:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103ddc:	eb 03                	jmp    f0103de1 <stab_binsearch+0x46>
			m--;
f0103dde:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103de1:	39 c3                	cmp    %eax,%ebx
f0103de3:	7f 1f                	jg     f0103e04 <stab_binsearch+0x69>
f0103de5:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103de9:	83 ea 0c             	sub    $0xc,%edx
f0103dec:	39 f1                	cmp    %esi,%ecx
f0103dee:	75 ee                	jne    f0103dde <stab_binsearch+0x43>
f0103df0:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103df3:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103df6:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103df9:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103dfd:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103e00:	76 18                	jbe    f0103e1a <stab_binsearch+0x7f>
f0103e02:	eb 05                	jmp    f0103e09 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103e04:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0103e07:	eb 42                	jmp    f0103e4b <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0103e09:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103e0c:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0103e0e:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103e11:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103e18:	eb 31                	jmp    f0103e4b <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103e1a:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103e1d:	73 17                	jae    f0103e36 <stab_binsearch+0x9b>
			*region_right = m - 1;
f0103e1f:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103e22:	83 e8 01             	sub    $0x1,%eax
f0103e25:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103e28:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103e2b:	89 07                	mov    %eax,(%edi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103e2d:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103e34:	eb 15                	jmp    f0103e4b <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103e36:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103e39:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0103e3c:	89 1f                	mov    %ebx,(%edi)
			l = m;
			addr++;
f0103e3e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103e42:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103e44:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103e4b:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0103e4e:	0f 8e 6f ff ff ff    	jle    f0103dc3 <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103e54:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103e58:	75 0f                	jne    f0103e69 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0103e5a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103e5d:	8b 00                	mov    (%eax),%eax
f0103e5f:	83 e8 01             	sub    $0x1,%eax
f0103e62:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103e65:	89 07                	mov    %eax,(%edi)
f0103e67:	eb 2c                	jmp    f0103e95 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103e69:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103e6c:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103e6e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103e71:	8b 0f                	mov    (%edi),%ecx
f0103e73:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103e76:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0103e79:	8d 14 97             	lea    (%edi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103e7c:	eb 03                	jmp    f0103e81 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103e7e:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103e81:	39 c8                	cmp    %ecx,%eax
f0103e83:	7e 0b                	jle    f0103e90 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0103e85:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0103e89:	83 ea 0c             	sub    $0xc,%edx
f0103e8c:	39 f3                	cmp    %esi,%ebx
f0103e8e:	75 ee                	jne    f0103e7e <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103e90:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103e93:	89 07                	mov    %eax,(%edi)
	}
}
f0103e95:	83 c4 14             	add    $0x14,%esp
f0103e98:	5b                   	pop    %ebx
f0103e99:	5e                   	pop    %esi
f0103e9a:	5f                   	pop    %edi
f0103e9b:	5d                   	pop    %ebp
f0103e9c:	c3                   	ret    

f0103e9d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103e9d:	55                   	push   %ebp
f0103e9e:	89 e5                	mov    %esp,%ebp
f0103ea0:	57                   	push   %edi
f0103ea1:	56                   	push   %esi
f0103ea2:	53                   	push   %ebx
f0103ea3:	83 ec 4c             	sub    $0x4c,%esp
f0103ea6:	8b 75 08             	mov    0x8(%ebp),%esi
f0103ea9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103eac:	c7 03 97 63 10 f0    	movl   $0xf0106397,(%ebx)
	info->eip_line = 0;
f0103eb2:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0103eb9:	c7 43 08 97 63 10 f0 	movl   $0xf0106397,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0103ec0:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0103ec7:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0103eca:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103ed1:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0103ed7:	77 21                	ja     f0103efa <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0103ed9:	a1 00 00 20 00       	mov    0x200000,%eax
f0103ede:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		stab_end = usd->stab_end;
f0103ee1:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f0103ee6:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f0103eec:	89 7d c0             	mov    %edi,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f0103eef:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f0103ef5:	89 7d bc             	mov    %edi,-0x44(%ebp)
f0103ef8:	eb 1a                	jmp    f0103f14 <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103efa:	c7 45 bc e1 0b 11 f0 	movl   $0xf0110be1,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103f01:	c7 45 c0 9d e1 10 f0 	movl   $0xf010e19d,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103f08:	b8 9c e1 10 f0       	mov    $0xf010e19c,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103f0d:	c7 45 c4 d0 65 10 f0 	movl   $0xf01065d0,-0x3c(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103f14:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0103f17:	39 7d c0             	cmp    %edi,-0x40(%ebp)
f0103f1a:	0f 83 9d 01 00 00    	jae    f01040bd <debuginfo_eip+0x220>
f0103f20:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f0103f24:	0f 85 9a 01 00 00    	jne    f01040c4 <debuginfo_eip+0x227>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103f2a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103f31:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0103f34:	29 f8                	sub    %edi,%eax
f0103f36:	c1 f8 02             	sar    $0x2,%eax
f0103f39:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103f3f:	83 e8 01             	sub    $0x1,%eax
f0103f42:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103f45:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103f49:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0103f50:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103f53:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103f56:	89 f8                	mov    %edi,%eax
f0103f58:	e8 3e fe ff ff       	call   f0103d9b <stab_binsearch>
	if (lfile == 0)
f0103f5d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103f60:	85 c0                	test   %eax,%eax
f0103f62:	0f 84 63 01 00 00    	je     f01040cb <debuginfo_eip+0x22e>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103f68:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103f6b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103f6e:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103f71:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103f75:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0103f7c:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103f7f:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103f82:	89 f8                	mov    %edi,%eax
f0103f84:	e8 12 fe ff ff       	call   f0103d9b <stab_binsearch>

	if (lfun <= rfun) {
f0103f89:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103f8c:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0103f8f:	39 c8                	cmp    %ecx,%eax
f0103f91:	7f 32                	jg     f0103fc5 <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103f93:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103f96:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0103f99:	8d 3c 97             	lea    (%edi,%edx,4),%edi
f0103f9c:	8b 17                	mov    (%edi),%edx
f0103f9e:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0103fa1:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0103fa4:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0103fa7:	39 55 b8             	cmp    %edx,-0x48(%ebp)
f0103faa:	73 09                	jae    f0103fb5 <debuginfo_eip+0x118>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103fac:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0103faf:	03 55 c0             	add    -0x40(%ebp),%edx
f0103fb2:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103fb5:	8b 57 08             	mov    0x8(%edi),%edx
f0103fb8:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0103fbb:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0103fbd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103fc0:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0103fc3:	eb 0f                	jmp    f0103fd4 <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103fc5:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0103fc8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103fcb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103fce:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103fd1:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103fd4:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0103fdb:	00 
f0103fdc:	8b 43 08             	mov    0x8(%ebx),%eax
f0103fdf:	89 04 24             	mov    %eax,(%esp)
f0103fe2:	e8 14 09 00 00       	call   f01048fb <strfind>
f0103fe7:	2b 43 08             	sub    0x8(%ebx),%eax
f0103fea:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
f0103fed:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103ff1:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0103ff8:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103ffb:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103ffe:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0104001:	89 f8                	mov    %edi,%eax
f0104003:	e8 93 fd ff ff       	call   f0103d9b <stab_binsearch>
	if (lline > rline) {
f0104008:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010400b:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f010400e:	0f 8f be 00 00 00    	jg     f01040d2 <debuginfo_eip+0x235>
		return -1; //Did not find the line number in the stab
	}
	info->eip_line = stabs[lline].n_desc; //If found update the info object with the correct line number
f0104014:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104017:	0f b7 44 87 06       	movzwl 0x6(%edi,%eax,4),%eax
f010401c:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010401f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104022:	89 c6                	mov    %eax,%esi
f0104024:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104027:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010402a:	8d 14 97             	lea    (%edi,%edx,4),%edx
f010402d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104030:	eb 06                	jmp    f0104038 <debuginfo_eip+0x19b>
f0104032:	83 e8 01             	sub    $0x1,%eax
f0104035:	83 ea 0c             	sub    $0xc,%edx
f0104038:	89 c7                	mov    %eax,%edi
f010403a:	39 c6                	cmp    %eax,%esi
f010403c:	7f 3c                	jg     f010407a <debuginfo_eip+0x1dd>
	       && stabs[lline].n_type != N_SOL
f010403e:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104042:	80 f9 84             	cmp    $0x84,%cl
f0104045:	75 08                	jne    f010404f <debuginfo_eip+0x1b2>
f0104047:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010404a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010404d:	eb 11                	jmp    f0104060 <debuginfo_eip+0x1c3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010404f:	80 f9 64             	cmp    $0x64,%cl
f0104052:	75 de                	jne    f0104032 <debuginfo_eip+0x195>
f0104054:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0104058:	74 d8                	je     f0104032 <debuginfo_eip+0x195>
f010405a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010405d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104060:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0104063:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0104066:	8b 04 86             	mov    (%esi,%eax,4),%eax
f0104069:	8b 55 bc             	mov    -0x44(%ebp),%edx
f010406c:	2b 55 c0             	sub    -0x40(%ebp),%edx
f010406f:	39 d0                	cmp    %edx,%eax
f0104071:	73 0a                	jae    f010407d <debuginfo_eip+0x1e0>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104073:	03 45 c0             	add    -0x40(%ebp),%eax
f0104076:	89 03                	mov    %eax,(%ebx)
f0104078:	eb 03                	jmp    f010407d <debuginfo_eip+0x1e0>
f010407a:	8b 5d 0c             	mov    0xc(%ebp),%ebx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010407d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104080:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104083:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104088:	39 f2                	cmp    %esi,%edx
f010408a:	7d 52                	jge    f01040de <debuginfo_eip+0x241>
		for (lline = lfun + 1;
f010408c:	83 c2 01             	add    $0x1,%edx
f010408f:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104092:	89 d0                	mov    %edx,%eax
f0104094:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104097:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010409a:	8d 14 97             	lea    (%edi,%edx,4),%edx
f010409d:	eb 04                	jmp    f01040a3 <debuginfo_eip+0x206>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010409f:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01040a3:	39 c6                	cmp    %eax,%esi
f01040a5:	7e 32                	jle    f01040d9 <debuginfo_eip+0x23c>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01040a7:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01040ab:	83 c0 01             	add    $0x1,%eax
f01040ae:	83 c2 0c             	add    $0xc,%edx
f01040b1:	80 f9 a0             	cmp    $0xa0,%cl
f01040b4:	74 e9                	je     f010409f <debuginfo_eip+0x202>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01040b6:	b8 00 00 00 00       	mov    $0x0,%eax
f01040bb:	eb 21                	jmp    f01040de <debuginfo_eip+0x241>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01040bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01040c2:	eb 1a                	jmp    f01040de <debuginfo_eip+0x241>
f01040c4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01040c9:	eb 13                	jmp    f01040de <debuginfo_eip+0x241>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01040cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01040d0:	eb 0c                	jmp    f01040de <debuginfo_eip+0x241>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
	if (lline > rline) {
		return -1; //Did not find the line number in the stab
f01040d2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01040d7:	eb 05                	jmp    f01040de <debuginfo_eip+0x241>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01040d9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01040de:	83 c4 4c             	add    $0x4c,%esp
f01040e1:	5b                   	pop    %ebx
f01040e2:	5e                   	pop    %esi
f01040e3:	5f                   	pop    %edi
f01040e4:	5d                   	pop    %ebp
f01040e5:	c3                   	ret    
f01040e6:	66 90                	xchg   %ax,%ax
f01040e8:	66 90                	xchg   %ax,%ax
f01040ea:	66 90                	xchg   %ax,%ax
f01040ec:	66 90                	xchg   %ax,%ax
f01040ee:	66 90                	xchg   %ax,%ax

f01040f0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01040f0:	55                   	push   %ebp
f01040f1:	89 e5                	mov    %esp,%ebp
f01040f3:	57                   	push   %edi
f01040f4:	56                   	push   %esi
f01040f5:	53                   	push   %ebx
f01040f6:	83 ec 3c             	sub    $0x3c,%esp
f01040f9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01040fc:	89 d7                	mov    %edx,%edi
f01040fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0104101:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104104:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104107:	89 c3                	mov    %eax,%ebx
f0104109:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010410c:	8b 45 10             	mov    0x10(%ebp),%eax
f010410f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104112:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104117:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010411a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010411d:	39 d9                	cmp    %ebx,%ecx
f010411f:	72 05                	jb     f0104126 <printnum+0x36>
f0104121:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0104124:	77 69                	ja     f010418f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104126:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0104129:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010412d:	83 ee 01             	sub    $0x1,%esi
f0104130:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0104134:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104138:	8b 44 24 08          	mov    0x8(%esp),%eax
f010413c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0104140:	89 c3                	mov    %eax,%ebx
f0104142:	89 d6                	mov    %edx,%esi
f0104144:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104147:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010414a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010414e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0104152:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104155:	89 04 24             	mov    %eax,(%esp)
f0104158:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010415b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010415f:	e8 bc 09 00 00       	call   f0104b20 <__udivdi3>
f0104164:	89 d9                	mov    %ebx,%ecx
f0104166:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010416a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010416e:	89 04 24             	mov    %eax,(%esp)
f0104171:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104175:	89 fa                	mov    %edi,%edx
f0104177:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010417a:	e8 71 ff ff ff       	call   f01040f0 <printnum>
f010417f:	eb 1b                	jmp    f010419c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104181:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104185:	8b 45 18             	mov    0x18(%ebp),%eax
f0104188:	89 04 24             	mov    %eax,(%esp)
f010418b:	ff d3                	call   *%ebx
f010418d:	eb 03                	jmp    f0104192 <printnum+0xa2>
f010418f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104192:	83 ee 01             	sub    $0x1,%esi
f0104195:	85 f6                	test   %esi,%esi
f0104197:	7f e8                	jg     f0104181 <printnum+0x91>
f0104199:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010419c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01041a0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01041a4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01041a7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01041aa:	89 44 24 08          	mov    %eax,0x8(%esp)
f01041ae:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01041b2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01041b5:	89 04 24             	mov    %eax,(%esp)
f01041b8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01041bb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01041bf:	e8 8c 0a 00 00       	call   f0104c50 <__umoddi3>
f01041c4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01041c8:	0f be 80 a1 63 10 f0 	movsbl -0xfef9c5f(%eax),%eax
f01041cf:	89 04 24             	mov    %eax,(%esp)
f01041d2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01041d5:	ff d0                	call   *%eax
}
f01041d7:	83 c4 3c             	add    $0x3c,%esp
f01041da:	5b                   	pop    %ebx
f01041db:	5e                   	pop    %esi
f01041dc:	5f                   	pop    %edi
f01041dd:	5d                   	pop    %ebp
f01041de:	c3                   	ret    

f01041df <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01041df:	55                   	push   %ebp
f01041e0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01041e2:	83 fa 01             	cmp    $0x1,%edx
f01041e5:	7e 0e                	jle    f01041f5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01041e7:	8b 10                	mov    (%eax),%edx
f01041e9:	8d 4a 08             	lea    0x8(%edx),%ecx
f01041ec:	89 08                	mov    %ecx,(%eax)
f01041ee:	8b 02                	mov    (%edx),%eax
f01041f0:	8b 52 04             	mov    0x4(%edx),%edx
f01041f3:	eb 22                	jmp    f0104217 <getuint+0x38>
	else if (lflag)
f01041f5:	85 d2                	test   %edx,%edx
f01041f7:	74 10                	je     f0104209 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01041f9:	8b 10                	mov    (%eax),%edx
f01041fb:	8d 4a 04             	lea    0x4(%edx),%ecx
f01041fe:	89 08                	mov    %ecx,(%eax)
f0104200:	8b 02                	mov    (%edx),%eax
f0104202:	ba 00 00 00 00       	mov    $0x0,%edx
f0104207:	eb 0e                	jmp    f0104217 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104209:	8b 10                	mov    (%eax),%edx
f010420b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010420e:	89 08                	mov    %ecx,(%eax)
f0104210:	8b 02                	mov    (%edx),%eax
f0104212:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104217:	5d                   	pop    %ebp
f0104218:	c3                   	ret    

f0104219 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104219:	55                   	push   %ebp
f010421a:	89 e5                	mov    %esp,%ebp
f010421c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010421f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104223:	8b 10                	mov    (%eax),%edx
f0104225:	3b 50 04             	cmp    0x4(%eax),%edx
f0104228:	73 0a                	jae    f0104234 <sprintputch+0x1b>
		*b->buf++ = ch;
f010422a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010422d:	89 08                	mov    %ecx,(%eax)
f010422f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104232:	88 02                	mov    %al,(%edx)
}
f0104234:	5d                   	pop    %ebp
f0104235:	c3                   	ret    

f0104236 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104236:	55                   	push   %ebp
f0104237:	89 e5                	mov    %esp,%ebp
f0104239:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f010423c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010423f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104243:	8b 45 10             	mov    0x10(%ebp),%eax
f0104246:	89 44 24 08          	mov    %eax,0x8(%esp)
f010424a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010424d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104251:	8b 45 08             	mov    0x8(%ebp),%eax
f0104254:	89 04 24             	mov    %eax,(%esp)
f0104257:	e8 02 00 00 00       	call   f010425e <vprintfmt>
	va_end(ap);
}
f010425c:	c9                   	leave  
f010425d:	c3                   	ret    

f010425e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010425e:	55                   	push   %ebp
f010425f:	89 e5                	mov    %esp,%ebp
f0104261:	57                   	push   %edi
f0104262:	56                   	push   %esi
f0104263:	53                   	push   %ebx
f0104264:	83 ec 3c             	sub    $0x3c,%esp
f0104267:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010426a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010426d:	eb 14                	jmp    f0104283 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010426f:	85 c0                	test   %eax,%eax
f0104271:	0f 84 b3 03 00 00    	je     f010462a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0104277:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010427b:	89 04 24             	mov    %eax,(%esp)
f010427e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104281:	89 f3                	mov    %esi,%ebx
f0104283:	8d 73 01             	lea    0x1(%ebx),%esi
f0104286:	0f b6 03             	movzbl (%ebx),%eax
f0104289:	83 f8 25             	cmp    $0x25,%eax
f010428c:	75 e1                	jne    f010426f <vprintfmt+0x11>
f010428e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0104292:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0104299:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f01042a0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f01042a7:	ba 00 00 00 00       	mov    $0x0,%edx
f01042ac:	eb 1d                	jmp    f01042cb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01042ae:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f01042b0:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f01042b4:	eb 15                	jmp    f01042cb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01042b6:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01042b8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f01042bc:	eb 0d                	jmp    f01042cb <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01042be:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01042c1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01042c4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01042cb:	8d 5e 01             	lea    0x1(%esi),%ebx
f01042ce:	0f b6 0e             	movzbl (%esi),%ecx
f01042d1:	0f b6 c1             	movzbl %cl,%eax
f01042d4:	83 e9 23             	sub    $0x23,%ecx
f01042d7:	80 f9 55             	cmp    $0x55,%cl
f01042da:	0f 87 2a 03 00 00    	ja     f010460a <vprintfmt+0x3ac>
f01042e0:	0f b6 c9             	movzbl %cl,%ecx
f01042e3:	ff 24 8d 40 64 10 f0 	jmp    *-0xfef9bc0(,%ecx,4)
f01042ea:	89 de                	mov    %ebx,%esi
f01042ec:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01042f1:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f01042f4:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f01042f8:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f01042fb:	8d 58 d0             	lea    -0x30(%eax),%ebx
f01042fe:	83 fb 09             	cmp    $0x9,%ebx
f0104301:	77 36                	ja     f0104339 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104303:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104306:	eb e9                	jmp    f01042f1 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104308:	8b 45 14             	mov    0x14(%ebp),%eax
f010430b:	8d 48 04             	lea    0x4(%eax),%ecx
f010430e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104311:	8b 00                	mov    (%eax),%eax
f0104313:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104316:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104318:	eb 22                	jmp    f010433c <vprintfmt+0xde>
f010431a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010431d:	85 c9                	test   %ecx,%ecx
f010431f:	b8 00 00 00 00       	mov    $0x0,%eax
f0104324:	0f 49 c1             	cmovns %ecx,%eax
f0104327:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010432a:	89 de                	mov    %ebx,%esi
f010432c:	eb 9d                	jmp    f01042cb <vprintfmt+0x6d>
f010432e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104330:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0104337:	eb 92                	jmp    f01042cb <vprintfmt+0x6d>
f0104339:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f010433c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104340:	79 89                	jns    f01042cb <vprintfmt+0x6d>
f0104342:	e9 77 ff ff ff       	jmp    f01042be <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104347:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010434a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010434c:	e9 7a ff ff ff       	jmp    f01042cb <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104351:	8b 45 14             	mov    0x14(%ebp),%eax
f0104354:	8d 50 04             	lea    0x4(%eax),%edx
f0104357:	89 55 14             	mov    %edx,0x14(%ebp)
f010435a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010435e:	8b 00                	mov    (%eax),%eax
f0104360:	89 04 24             	mov    %eax,(%esp)
f0104363:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104366:	e9 18 ff ff ff       	jmp    f0104283 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010436b:	8b 45 14             	mov    0x14(%ebp),%eax
f010436e:	8d 50 04             	lea    0x4(%eax),%edx
f0104371:	89 55 14             	mov    %edx,0x14(%ebp)
f0104374:	8b 00                	mov    (%eax),%eax
f0104376:	99                   	cltd   
f0104377:	31 d0                	xor    %edx,%eax
f0104379:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010437b:	83 f8 07             	cmp    $0x7,%eax
f010437e:	7f 0b                	jg     f010438b <vprintfmt+0x12d>
f0104380:	8b 14 85 a0 65 10 f0 	mov    -0xfef9a60(,%eax,4),%edx
f0104387:	85 d2                	test   %edx,%edx
f0104389:	75 20                	jne    f01043ab <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f010438b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010438f:	c7 44 24 08 b9 63 10 	movl   $0xf01063b9,0x8(%esp)
f0104396:	f0 
f0104397:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010439b:	8b 45 08             	mov    0x8(%ebp),%eax
f010439e:	89 04 24             	mov    %eax,(%esp)
f01043a1:	e8 90 fe ff ff       	call   f0104236 <printfmt>
f01043a6:	e9 d8 fe ff ff       	jmp    f0104283 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f01043ab:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01043af:	c7 44 24 08 95 5b 10 	movl   $0xf0105b95,0x8(%esp)
f01043b6:	f0 
f01043b7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01043bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01043be:	89 04 24             	mov    %eax,(%esp)
f01043c1:	e8 70 fe ff ff       	call   f0104236 <printfmt>
f01043c6:	e9 b8 fe ff ff       	jmp    f0104283 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01043cb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01043ce:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01043d1:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01043d4:	8b 45 14             	mov    0x14(%ebp),%eax
f01043d7:	8d 50 04             	lea    0x4(%eax),%edx
f01043da:	89 55 14             	mov    %edx,0x14(%ebp)
f01043dd:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f01043df:	85 f6                	test   %esi,%esi
f01043e1:	b8 b2 63 10 f0       	mov    $0xf01063b2,%eax
f01043e6:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f01043e9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f01043ed:	0f 84 97 00 00 00    	je     f010448a <vprintfmt+0x22c>
f01043f3:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01043f7:	0f 8e 9b 00 00 00    	jle    f0104498 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f01043fd:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104401:	89 34 24             	mov    %esi,(%esp)
f0104404:	e8 9f 03 00 00       	call   f01047a8 <strnlen>
f0104409:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010440c:	29 c2                	sub    %eax,%edx
f010440e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0104411:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0104415:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0104418:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010441b:	8b 75 08             	mov    0x8(%ebp),%esi
f010441e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0104421:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104423:	eb 0f                	jmp    f0104434 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0104425:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104429:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010442c:	89 04 24             	mov    %eax,(%esp)
f010442f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104431:	83 eb 01             	sub    $0x1,%ebx
f0104434:	85 db                	test   %ebx,%ebx
f0104436:	7f ed                	jg     f0104425 <vprintfmt+0x1c7>
f0104438:	8b 75 d8             	mov    -0x28(%ebp),%esi
f010443b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010443e:	85 d2                	test   %edx,%edx
f0104440:	b8 00 00 00 00       	mov    $0x0,%eax
f0104445:	0f 49 c2             	cmovns %edx,%eax
f0104448:	29 c2                	sub    %eax,%edx
f010444a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010444d:	89 d7                	mov    %edx,%edi
f010444f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104452:	eb 50                	jmp    f01044a4 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104454:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104458:	74 1e                	je     f0104478 <vprintfmt+0x21a>
f010445a:	0f be d2             	movsbl %dl,%edx
f010445d:	83 ea 20             	sub    $0x20,%edx
f0104460:	83 fa 5e             	cmp    $0x5e,%edx
f0104463:	76 13                	jbe    f0104478 <vprintfmt+0x21a>
					putch('?', putdat);
f0104465:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104468:	89 44 24 04          	mov    %eax,0x4(%esp)
f010446c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0104473:	ff 55 08             	call   *0x8(%ebp)
f0104476:	eb 0d                	jmp    f0104485 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0104478:	8b 55 0c             	mov    0xc(%ebp),%edx
f010447b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010447f:	89 04 24             	mov    %eax,(%esp)
f0104482:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104485:	83 ef 01             	sub    $0x1,%edi
f0104488:	eb 1a                	jmp    f01044a4 <vprintfmt+0x246>
f010448a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010448d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0104490:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0104493:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104496:	eb 0c                	jmp    f01044a4 <vprintfmt+0x246>
f0104498:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010449b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f010449e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01044a1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01044a4:	83 c6 01             	add    $0x1,%esi
f01044a7:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f01044ab:	0f be c2             	movsbl %dl,%eax
f01044ae:	85 c0                	test   %eax,%eax
f01044b0:	74 27                	je     f01044d9 <vprintfmt+0x27b>
f01044b2:	85 db                	test   %ebx,%ebx
f01044b4:	78 9e                	js     f0104454 <vprintfmt+0x1f6>
f01044b6:	83 eb 01             	sub    $0x1,%ebx
f01044b9:	79 99                	jns    f0104454 <vprintfmt+0x1f6>
f01044bb:	89 f8                	mov    %edi,%eax
f01044bd:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01044c0:	8b 75 08             	mov    0x8(%ebp),%esi
f01044c3:	89 c3                	mov    %eax,%ebx
f01044c5:	eb 1a                	jmp    f01044e1 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01044c7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01044cb:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01044d2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01044d4:	83 eb 01             	sub    $0x1,%ebx
f01044d7:	eb 08                	jmp    f01044e1 <vprintfmt+0x283>
f01044d9:	89 fb                	mov    %edi,%ebx
f01044db:	8b 75 08             	mov    0x8(%ebp),%esi
f01044de:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01044e1:	85 db                	test   %ebx,%ebx
f01044e3:	7f e2                	jg     f01044c7 <vprintfmt+0x269>
f01044e5:	89 75 08             	mov    %esi,0x8(%ebp)
f01044e8:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01044eb:	e9 93 fd ff ff       	jmp    f0104283 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01044f0:	83 fa 01             	cmp    $0x1,%edx
f01044f3:	7e 16                	jle    f010450b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f01044f5:	8b 45 14             	mov    0x14(%ebp),%eax
f01044f8:	8d 50 08             	lea    0x8(%eax),%edx
f01044fb:	89 55 14             	mov    %edx,0x14(%ebp)
f01044fe:	8b 50 04             	mov    0x4(%eax),%edx
f0104501:	8b 00                	mov    (%eax),%eax
f0104503:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104506:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104509:	eb 32                	jmp    f010453d <vprintfmt+0x2df>
	else if (lflag)
f010450b:	85 d2                	test   %edx,%edx
f010450d:	74 18                	je     f0104527 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010450f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104512:	8d 50 04             	lea    0x4(%eax),%edx
f0104515:	89 55 14             	mov    %edx,0x14(%ebp)
f0104518:	8b 30                	mov    (%eax),%esi
f010451a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010451d:	89 f0                	mov    %esi,%eax
f010451f:	c1 f8 1f             	sar    $0x1f,%eax
f0104522:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104525:	eb 16                	jmp    f010453d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0104527:	8b 45 14             	mov    0x14(%ebp),%eax
f010452a:	8d 50 04             	lea    0x4(%eax),%edx
f010452d:	89 55 14             	mov    %edx,0x14(%ebp)
f0104530:	8b 30                	mov    (%eax),%esi
f0104532:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0104535:	89 f0                	mov    %esi,%eax
f0104537:	c1 f8 1f             	sar    $0x1f,%eax
f010453a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010453d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104540:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0104543:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104548:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010454c:	0f 89 80 00 00 00    	jns    f01045d2 <vprintfmt+0x374>
				putch('-', putdat);
f0104552:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104556:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010455d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0104560:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104563:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104566:	f7 d8                	neg    %eax
f0104568:	83 d2 00             	adc    $0x0,%edx
f010456b:	f7 da                	neg    %edx
			}
			base = 10;
f010456d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0104572:	eb 5e                	jmp    f01045d2 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104574:	8d 45 14             	lea    0x14(%ebp),%eax
f0104577:	e8 63 fc ff ff       	call   f01041df <getuint>
			base = 10;
f010457c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0104581:	eb 4f                	jmp    f01045d2 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0104583:	8d 45 14             	lea    0x14(%ebp),%eax
f0104586:	e8 54 fc ff ff       	call   f01041df <getuint>
			base = 8;
f010458b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0104590:	eb 40                	jmp    f01045d2 <vprintfmt+0x374>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f0104592:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104596:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010459d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01045a0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01045a4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01045ab:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01045ae:	8b 45 14             	mov    0x14(%ebp),%eax
f01045b1:	8d 50 04             	lea    0x4(%eax),%edx
f01045b4:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01045b7:	8b 00                	mov    (%eax),%eax
f01045b9:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01045be:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01045c3:	eb 0d                	jmp    f01045d2 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01045c5:	8d 45 14             	lea    0x14(%ebp),%eax
f01045c8:	e8 12 fc ff ff       	call   f01041df <getuint>
			base = 16;
f01045cd:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01045d2:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f01045d6:	89 74 24 10          	mov    %esi,0x10(%esp)
f01045da:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01045dd:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01045e1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01045e5:	89 04 24             	mov    %eax,(%esp)
f01045e8:	89 54 24 04          	mov    %edx,0x4(%esp)
f01045ec:	89 fa                	mov    %edi,%edx
f01045ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01045f1:	e8 fa fa ff ff       	call   f01040f0 <printnum>
			break;
f01045f6:	e9 88 fc ff ff       	jmp    f0104283 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01045fb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01045ff:	89 04 24             	mov    %eax,(%esp)
f0104602:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104605:	e9 79 fc ff ff       	jmp    f0104283 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010460a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010460e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0104615:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104618:	89 f3                	mov    %esi,%ebx
f010461a:	eb 03                	jmp    f010461f <vprintfmt+0x3c1>
f010461c:	83 eb 01             	sub    $0x1,%ebx
f010461f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0104623:	75 f7                	jne    f010461c <vprintfmt+0x3be>
f0104625:	e9 59 fc ff ff       	jmp    f0104283 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010462a:	83 c4 3c             	add    $0x3c,%esp
f010462d:	5b                   	pop    %ebx
f010462e:	5e                   	pop    %esi
f010462f:	5f                   	pop    %edi
f0104630:	5d                   	pop    %ebp
f0104631:	c3                   	ret    

f0104632 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104632:	55                   	push   %ebp
f0104633:	89 e5                	mov    %esp,%ebp
f0104635:	83 ec 28             	sub    $0x28,%esp
f0104638:	8b 45 08             	mov    0x8(%ebp),%eax
f010463b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010463e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104641:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104645:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104648:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010464f:	85 c0                	test   %eax,%eax
f0104651:	74 30                	je     f0104683 <vsnprintf+0x51>
f0104653:	85 d2                	test   %edx,%edx
f0104655:	7e 2c                	jle    f0104683 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104657:	8b 45 14             	mov    0x14(%ebp),%eax
f010465a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010465e:	8b 45 10             	mov    0x10(%ebp),%eax
f0104661:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104665:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104668:	89 44 24 04          	mov    %eax,0x4(%esp)
f010466c:	c7 04 24 19 42 10 f0 	movl   $0xf0104219,(%esp)
f0104673:	e8 e6 fb ff ff       	call   f010425e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104678:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010467b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010467e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104681:	eb 05                	jmp    f0104688 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104683:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104688:	c9                   	leave  
f0104689:	c3                   	ret    

f010468a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010468a:	55                   	push   %ebp
f010468b:	89 e5                	mov    %esp,%ebp
f010468d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104690:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104693:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104697:	8b 45 10             	mov    0x10(%ebp),%eax
f010469a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010469e:	8b 45 0c             	mov    0xc(%ebp),%eax
f01046a1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01046a5:	8b 45 08             	mov    0x8(%ebp),%eax
f01046a8:	89 04 24             	mov    %eax,(%esp)
f01046ab:	e8 82 ff ff ff       	call   f0104632 <vsnprintf>
	va_end(ap);

	return rc;
}
f01046b0:	c9                   	leave  
f01046b1:	c3                   	ret    
f01046b2:	66 90                	xchg   %ax,%ax
f01046b4:	66 90                	xchg   %ax,%ax
f01046b6:	66 90                	xchg   %ax,%ax
f01046b8:	66 90                	xchg   %ax,%ax
f01046ba:	66 90                	xchg   %ax,%ax
f01046bc:	66 90                	xchg   %ax,%ax
f01046be:	66 90                	xchg   %ax,%ax

f01046c0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01046c0:	55                   	push   %ebp
f01046c1:	89 e5                	mov    %esp,%ebp
f01046c3:	57                   	push   %edi
f01046c4:	56                   	push   %esi
f01046c5:	53                   	push   %ebx
f01046c6:	83 ec 1c             	sub    $0x1c,%esp
f01046c9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01046cc:	85 c0                	test   %eax,%eax
f01046ce:	74 10                	je     f01046e0 <readline+0x20>
		cprintf("%s", prompt);
f01046d0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01046d4:	c7 04 24 95 5b 10 f0 	movl   $0xf0105b95,(%esp)
f01046db:	e8 cc f0 ff ff       	call   f01037ac <cprintf>

	i = 0;
	echoing = iscons(0);
f01046e0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01046e7:	e8 46 bf ff ff       	call   f0100632 <iscons>
f01046ec:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01046ee:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01046f3:	e8 29 bf ff ff       	call   f0100621 <getchar>
f01046f8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01046fa:	85 c0                	test   %eax,%eax
f01046fc:	79 17                	jns    f0104715 <readline+0x55>
			cprintf("read error: %e\n", c);
f01046fe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104702:	c7 04 24 c0 65 10 f0 	movl   $0xf01065c0,(%esp)
f0104709:	e8 9e f0 ff ff       	call   f01037ac <cprintf>
			return NULL;
f010470e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104713:	eb 6d                	jmp    f0104782 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104715:	83 f8 7f             	cmp    $0x7f,%eax
f0104718:	74 05                	je     f010471f <readline+0x5f>
f010471a:	83 f8 08             	cmp    $0x8,%eax
f010471d:	75 19                	jne    f0104738 <readline+0x78>
f010471f:	85 f6                	test   %esi,%esi
f0104721:	7e 15                	jle    f0104738 <readline+0x78>
			if (echoing)
f0104723:	85 ff                	test   %edi,%edi
f0104725:	74 0c                	je     f0104733 <readline+0x73>
				cputchar('\b');
f0104727:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010472e:	e8 de be ff ff       	call   f0100611 <cputchar>
			i--;
f0104733:	83 ee 01             	sub    $0x1,%esi
f0104736:	eb bb                	jmp    f01046f3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104738:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010473e:	7f 1c                	jg     f010475c <readline+0x9c>
f0104740:	83 fb 1f             	cmp    $0x1f,%ebx
f0104743:	7e 17                	jle    f010475c <readline+0x9c>
			if (echoing)
f0104745:	85 ff                	test   %edi,%edi
f0104747:	74 08                	je     f0104751 <readline+0x91>
				cputchar(c);
f0104749:	89 1c 24             	mov    %ebx,(%esp)
f010474c:	e8 c0 be ff ff       	call   f0100611 <cputchar>
			buf[i++] = c;
f0104751:	88 9e 80 db 17 f0    	mov    %bl,-0xfe82480(%esi)
f0104757:	8d 76 01             	lea    0x1(%esi),%esi
f010475a:	eb 97                	jmp    f01046f3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010475c:	83 fb 0d             	cmp    $0xd,%ebx
f010475f:	74 05                	je     f0104766 <readline+0xa6>
f0104761:	83 fb 0a             	cmp    $0xa,%ebx
f0104764:	75 8d                	jne    f01046f3 <readline+0x33>
			if (echoing)
f0104766:	85 ff                	test   %edi,%edi
f0104768:	74 0c                	je     f0104776 <readline+0xb6>
				cputchar('\n');
f010476a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0104771:	e8 9b be ff ff       	call   f0100611 <cputchar>
			buf[i] = 0;
f0104776:	c6 86 80 db 17 f0 00 	movb   $0x0,-0xfe82480(%esi)
			return buf;
f010477d:	b8 80 db 17 f0       	mov    $0xf017db80,%eax
		}
	}
}
f0104782:	83 c4 1c             	add    $0x1c,%esp
f0104785:	5b                   	pop    %ebx
f0104786:	5e                   	pop    %esi
f0104787:	5f                   	pop    %edi
f0104788:	5d                   	pop    %ebp
f0104789:	c3                   	ret    
f010478a:	66 90                	xchg   %ax,%ax
f010478c:	66 90                	xchg   %ax,%ax
f010478e:	66 90                	xchg   %ax,%ax

f0104790 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104790:	55                   	push   %ebp
f0104791:	89 e5                	mov    %esp,%ebp
f0104793:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104796:	b8 00 00 00 00       	mov    $0x0,%eax
f010479b:	eb 03                	jmp    f01047a0 <strlen+0x10>
		n++;
f010479d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01047a0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01047a4:	75 f7                	jne    f010479d <strlen+0xd>
		n++;
	return n;
}
f01047a6:	5d                   	pop    %ebp
f01047a7:	c3                   	ret    

f01047a8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01047a8:	55                   	push   %ebp
f01047a9:	89 e5                	mov    %esp,%ebp
f01047ab:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01047ae:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01047b1:	b8 00 00 00 00       	mov    $0x0,%eax
f01047b6:	eb 03                	jmp    f01047bb <strnlen+0x13>
		n++;
f01047b8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01047bb:	39 d0                	cmp    %edx,%eax
f01047bd:	74 06                	je     f01047c5 <strnlen+0x1d>
f01047bf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01047c3:	75 f3                	jne    f01047b8 <strnlen+0x10>
		n++;
	return n;
}
f01047c5:	5d                   	pop    %ebp
f01047c6:	c3                   	ret    

f01047c7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01047c7:	55                   	push   %ebp
f01047c8:	89 e5                	mov    %esp,%ebp
f01047ca:	53                   	push   %ebx
f01047cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01047ce:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01047d1:	89 c2                	mov    %eax,%edx
f01047d3:	83 c2 01             	add    $0x1,%edx
f01047d6:	83 c1 01             	add    $0x1,%ecx
f01047d9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01047dd:	88 5a ff             	mov    %bl,-0x1(%edx)
f01047e0:	84 db                	test   %bl,%bl
f01047e2:	75 ef                	jne    f01047d3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01047e4:	5b                   	pop    %ebx
f01047e5:	5d                   	pop    %ebp
f01047e6:	c3                   	ret    

f01047e7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01047e7:	55                   	push   %ebp
f01047e8:	89 e5                	mov    %esp,%ebp
f01047ea:	53                   	push   %ebx
f01047eb:	83 ec 08             	sub    $0x8,%esp
f01047ee:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01047f1:	89 1c 24             	mov    %ebx,(%esp)
f01047f4:	e8 97 ff ff ff       	call   f0104790 <strlen>
	strcpy(dst + len, src);
f01047f9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01047fc:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104800:	01 d8                	add    %ebx,%eax
f0104802:	89 04 24             	mov    %eax,(%esp)
f0104805:	e8 bd ff ff ff       	call   f01047c7 <strcpy>
	return dst;
}
f010480a:	89 d8                	mov    %ebx,%eax
f010480c:	83 c4 08             	add    $0x8,%esp
f010480f:	5b                   	pop    %ebx
f0104810:	5d                   	pop    %ebp
f0104811:	c3                   	ret    

f0104812 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104812:	55                   	push   %ebp
f0104813:	89 e5                	mov    %esp,%ebp
f0104815:	56                   	push   %esi
f0104816:	53                   	push   %ebx
f0104817:	8b 75 08             	mov    0x8(%ebp),%esi
f010481a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010481d:	89 f3                	mov    %esi,%ebx
f010481f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104822:	89 f2                	mov    %esi,%edx
f0104824:	eb 0f                	jmp    f0104835 <strncpy+0x23>
		*dst++ = *src;
f0104826:	83 c2 01             	add    $0x1,%edx
f0104829:	0f b6 01             	movzbl (%ecx),%eax
f010482c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010482f:	80 39 01             	cmpb   $0x1,(%ecx)
f0104832:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104835:	39 da                	cmp    %ebx,%edx
f0104837:	75 ed                	jne    f0104826 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104839:	89 f0                	mov    %esi,%eax
f010483b:	5b                   	pop    %ebx
f010483c:	5e                   	pop    %esi
f010483d:	5d                   	pop    %ebp
f010483e:	c3                   	ret    

f010483f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010483f:	55                   	push   %ebp
f0104840:	89 e5                	mov    %esp,%ebp
f0104842:	56                   	push   %esi
f0104843:	53                   	push   %ebx
f0104844:	8b 75 08             	mov    0x8(%ebp),%esi
f0104847:	8b 55 0c             	mov    0xc(%ebp),%edx
f010484a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010484d:	89 f0                	mov    %esi,%eax
f010484f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104853:	85 c9                	test   %ecx,%ecx
f0104855:	75 0b                	jne    f0104862 <strlcpy+0x23>
f0104857:	eb 1d                	jmp    f0104876 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104859:	83 c0 01             	add    $0x1,%eax
f010485c:	83 c2 01             	add    $0x1,%edx
f010485f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104862:	39 d8                	cmp    %ebx,%eax
f0104864:	74 0b                	je     f0104871 <strlcpy+0x32>
f0104866:	0f b6 0a             	movzbl (%edx),%ecx
f0104869:	84 c9                	test   %cl,%cl
f010486b:	75 ec                	jne    f0104859 <strlcpy+0x1a>
f010486d:	89 c2                	mov    %eax,%edx
f010486f:	eb 02                	jmp    f0104873 <strlcpy+0x34>
f0104871:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0104873:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0104876:	29 f0                	sub    %esi,%eax
}
f0104878:	5b                   	pop    %ebx
f0104879:	5e                   	pop    %esi
f010487a:	5d                   	pop    %ebp
f010487b:	c3                   	ret    

f010487c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010487c:	55                   	push   %ebp
f010487d:	89 e5                	mov    %esp,%ebp
f010487f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104882:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104885:	eb 06                	jmp    f010488d <strcmp+0x11>
		p++, q++;
f0104887:	83 c1 01             	add    $0x1,%ecx
f010488a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010488d:	0f b6 01             	movzbl (%ecx),%eax
f0104890:	84 c0                	test   %al,%al
f0104892:	74 04                	je     f0104898 <strcmp+0x1c>
f0104894:	3a 02                	cmp    (%edx),%al
f0104896:	74 ef                	je     f0104887 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104898:	0f b6 c0             	movzbl %al,%eax
f010489b:	0f b6 12             	movzbl (%edx),%edx
f010489e:	29 d0                	sub    %edx,%eax
}
f01048a0:	5d                   	pop    %ebp
f01048a1:	c3                   	ret    

f01048a2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01048a2:	55                   	push   %ebp
f01048a3:	89 e5                	mov    %esp,%ebp
f01048a5:	53                   	push   %ebx
f01048a6:	8b 45 08             	mov    0x8(%ebp),%eax
f01048a9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01048ac:	89 c3                	mov    %eax,%ebx
f01048ae:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01048b1:	eb 06                	jmp    f01048b9 <strncmp+0x17>
		n--, p++, q++;
f01048b3:	83 c0 01             	add    $0x1,%eax
f01048b6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01048b9:	39 d8                	cmp    %ebx,%eax
f01048bb:	74 15                	je     f01048d2 <strncmp+0x30>
f01048bd:	0f b6 08             	movzbl (%eax),%ecx
f01048c0:	84 c9                	test   %cl,%cl
f01048c2:	74 04                	je     f01048c8 <strncmp+0x26>
f01048c4:	3a 0a                	cmp    (%edx),%cl
f01048c6:	74 eb                	je     f01048b3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01048c8:	0f b6 00             	movzbl (%eax),%eax
f01048cb:	0f b6 12             	movzbl (%edx),%edx
f01048ce:	29 d0                	sub    %edx,%eax
f01048d0:	eb 05                	jmp    f01048d7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01048d2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01048d7:	5b                   	pop    %ebx
f01048d8:	5d                   	pop    %ebp
f01048d9:	c3                   	ret    

f01048da <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01048da:	55                   	push   %ebp
f01048db:	89 e5                	mov    %esp,%ebp
f01048dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01048e0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01048e4:	eb 07                	jmp    f01048ed <strchr+0x13>
		if (*s == c)
f01048e6:	38 ca                	cmp    %cl,%dl
f01048e8:	74 0f                	je     f01048f9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01048ea:	83 c0 01             	add    $0x1,%eax
f01048ed:	0f b6 10             	movzbl (%eax),%edx
f01048f0:	84 d2                	test   %dl,%dl
f01048f2:	75 f2                	jne    f01048e6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01048f4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01048f9:	5d                   	pop    %ebp
f01048fa:	c3                   	ret    

f01048fb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01048fb:	55                   	push   %ebp
f01048fc:	89 e5                	mov    %esp,%ebp
f01048fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0104901:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104905:	eb 07                	jmp    f010490e <strfind+0x13>
		if (*s == c)
f0104907:	38 ca                	cmp    %cl,%dl
f0104909:	74 0a                	je     f0104915 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010490b:	83 c0 01             	add    $0x1,%eax
f010490e:	0f b6 10             	movzbl (%eax),%edx
f0104911:	84 d2                	test   %dl,%dl
f0104913:	75 f2                	jne    f0104907 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0104915:	5d                   	pop    %ebp
f0104916:	c3                   	ret    

f0104917 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104917:	55                   	push   %ebp
f0104918:	89 e5                	mov    %esp,%ebp
f010491a:	57                   	push   %edi
f010491b:	56                   	push   %esi
f010491c:	53                   	push   %ebx
f010491d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104920:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104923:	85 c9                	test   %ecx,%ecx
f0104925:	74 36                	je     f010495d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104927:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010492d:	75 28                	jne    f0104957 <memset+0x40>
f010492f:	f6 c1 03             	test   $0x3,%cl
f0104932:	75 23                	jne    f0104957 <memset+0x40>
		c &= 0xFF;
f0104934:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104938:	89 d3                	mov    %edx,%ebx
f010493a:	c1 e3 08             	shl    $0x8,%ebx
f010493d:	89 d6                	mov    %edx,%esi
f010493f:	c1 e6 18             	shl    $0x18,%esi
f0104942:	89 d0                	mov    %edx,%eax
f0104944:	c1 e0 10             	shl    $0x10,%eax
f0104947:	09 f0                	or     %esi,%eax
f0104949:	09 c2                	or     %eax,%edx
f010494b:	89 d0                	mov    %edx,%eax
f010494d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010494f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0104952:	fc                   	cld    
f0104953:	f3 ab                	rep stos %eax,%es:(%edi)
f0104955:	eb 06                	jmp    f010495d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104957:	8b 45 0c             	mov    0xc(%ebp),%eax
f010495a:	fc                   	cld    
f010495b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010495d:	89 f8                	mov    %edi,%eax
f010495f:	5b                   	pop    %ebx
f0104960:	5e                   	pop    %esi
f0104961:	5f                   	pop    %edi
f0104962:	5d                   	pop    %ebp
f0104963:	c3                   	ret    

f0104964 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104964:	55                   	push   %ebp
f0104965:	89 e5                	mov    %esp,%ebp
f0104967:	57                   	push   %edi
f0104968:	56                   	push   %esi
f0104969:	8b 45 08             	mov    0x8(%ebp),%eax
f010496c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010496f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104972:	39 c6                	cmp    %eax,%esi
f0104974:	73 35                	jae    f01049ab <memmove+0x47>
f0104976:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104979:	39 d0                	cmp    %edx,%eax
f010497b:	73 2e                	jae    f01049ab <memmove+0x47>
		s += n;
		d += n;
f010497d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0104980:	89 d6                	mov    %edx,%esi
f0104982:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104984:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010498a:	75 13                	jne    f010499f <memmove+0x3b>
f010498c:	f6 c1 03             	test   $0x3,%cl
f010498f:	75 0e                	jne    f010499f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104991:	83 ef 04             	sub    $0x4,%edi
f0104994:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104997:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010499a:	fd                   	std    
f010499b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010499d:	eb 09                	jmp    f01049a8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010499f:	83 ef 01             	sub    $0x1,%edi
f01049a2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01049a5:	fd                   	std    
f01049a6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01049a8:	fc                   	cld    
f01049a9:	eb 1d                	jmp    f01049c8 <memmove+0x64>
f01049ab:	89 f2                	mov    %esi,%edx
f01049ad:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01049af:	f6 c2 03             	test   $0x3,%dl
f01049b2:	75 0f                	jne    f01049c3 <memmove+0x5f>
f01049b4:	f6 c1 03             	test   $0x3,%cl
f01049b7:	75 0a                	jne    f01049c3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01049b9:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01049bc:	89 c7                	mov    %eax,%edi
f01049be:	fc                   	cld    
f01049bf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01049c1:	eb 05                	jmp    f01049c8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01049c3:	89 c7                	mov    %eax,%edi
f01049c5:	fc                   	cld    
f01049c6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01049c8:	5e                   	pop    %esi
f01049c9:	5f                   	pop    %edi
f01049ca:	5d                   	pop    %ebp
f01049cb:	c3                   	ret    

f01049cc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01049cc:	55                   	push   %ebp
f01049cd:	89 e5                	mov    %esp,%ebp
f01049cf:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01049d2:	8b 45 10             	mov    0x10(%ebp),%eax
f01049d5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01049d9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01049dc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01049e0:	8b 45 08             	mov    0x8(%ebp),%eax
f01049e3:	89 04 24             	mov    %eax,(%esp)
f01049e6:	e8 79 ff ff ff       	call   f0104964 <memmove>
}
f01049eb:	c9                   	leave  
f01049ec:	c3                   	ret    

f01049ed <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01049ed:	55                   	push   %ebp
f01049ee:	89 e5                	mov    %esp,%ebp
f01049f0:	56                   	push   %esi
f01049f1:	53                   	push   %ebx
f01049f2:	8b 55 08             	mov    0x8(%ebp),%edx
f01049f5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01049f8:	89 d6                	mov    %edx,%esi
f01049fa:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01049fd:	eb 1a                	jmp    f0104a19 <memcmp+0x2c>
		if (*s1 != *s2)
f01049ff:	0f b6 02             	movzbl (%edx),%eax
f0104a02:	0f b6 19             	movzbl (%ecx),%ebx
f0104a05:	38 d8                	cmp    %bl,%al
f0104a07:	74 0a                	je     f0104a13 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104a09:	0f b6 c0             	movzbl %al,%eax
f0104a0c:	0f b6 db             	movzbl %bl,%ebx
f0104a0f:	29 d8                	sub    %ebx,%eax
f0104a11:	eb 0f                	jmp    f0104a22 <memcmp+0x35>
		s1++, s2++;
f0104a13:	83 c2 01             	add    $0x1,%edx
f0104a16:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104a19:	39 f2                	cmp    %esi,%edx
f0104a1b:	75 e2                	jne    f01049ff <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104a1d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104a22:	5b                   	pop    %ebx
f0104a23:	5e                   	pop    %esi
f0104a24:	5d                   	pop    %ebp
f0104a25:	c3                   	ret    

f0104a26 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104a26:	55                   	push   %ebp
f0104a27:	89 e5                	mov    %esp,%ebp
f0104a29:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a2c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0104a2f:	89 c2                	mov    %eax,%edx
f0104a31:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104a34:	eb 07                	jmp    f0104a3d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104a36:	38 08                	cmp    %cl,(%eax)
f0104a38:	74 07                	je     f0104a41 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104a3a:	83 c0 01             	add    $0x1,%eax
f0104a3d:	39 d0                	cmp    %edx,%eax
f0104a3f:	72 f5                	jb     f0104a36 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104a41:	5d                   	pop    %ebp
f0104a42:	c3                   	ret    

f0104a43 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104a43:	55                   	push   %ebp
f0104a44:	89 e5                	mov    %esp,%ebp
f0104a46:	57                   	push   %edi
f0104a47:	56                   	push   %esi
f0104a48:	53                   	push   %ebx
f0104a49:	8b 55 08             	mov    0x8(%ebp),%edx
f0104a4c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104a4f:	eb 03                	jmp    f0104a54 <strtol+0x11>
		s++;
f0104a51:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104a54:	0f b6 0a             	movzbl (%edx),%ecx
f0104a57:	80 f9 09             	cmp    $0x9,%cl
f0104a5a:	74 f5                	je     f0104a51 <strtol+0xe>
f0104a5c:	80 f9 20             	cmp    $0x20,%cl
f0104a5f:	74 f0                	je     f0104a51 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104a61:	80 f9 2b             	cmp    $0x2b,%cl
f0104a64:	75 0a                	jne    f0104a70 <strtol+0x2d>
		s++;
f0104a66:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104a69:	bf 00 00 00 00       	mov    $0x0,%edi
f0104a6e:	eb 11                	jmp    f0104a81 <strtol+0x3e>
f0104a70:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104a75:	80 f9 2d             	cmp    $0x2d,%cl
f0104a78:	75 07                	jne    f0104a81 <strtol+0x3e>
		s++, neg = 1;
f0104a7a:	8d 52 01             	lea    0x1(%edx),%edx
f0104a7d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104a81:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0104a86:	75 15                	jne    f0104a9d <strtol+0x5a>
f0104a88:	80 3a 30             	cmpb   $0x30,(%edx)
f0104a8b:	75 10                	jne    f0104a9d <strtol+0x5a>
f0104a8d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0104a91:	75 0a                	jne    f0104a9d <strtol+0x5a>
		s += 2, base = 16;
f0104a93:	83 c2 02             	add    $0x2,%edx
f0104a96:	b8 10 00 00 00       	mov    $0x10,%eax
f0104a9b:	eb 10                	jmp    f0104aad <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f0104a9d:	85 c0                	test   %eax,%eax
f0104a9f:	75 0c                	jne    f0104aad <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104aa1:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104aa3:	80 3a 30             	cmpb   $0x30,(%edx)
f0104aa6:	75 05                	jne    f0104aad <strtol+0x6a>
		s++, base = 8;
f0104aa8:	83 c2 01             	add    $0x1,%edx
f0104aab:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f0104aad:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104ab2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104ab5:	0f b6 0a             	movzbl (%edx),%ecx
f0104ab8:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0104abb:	89 f0                	mov    %esi,%eax
f0104abd:	3c 09                	cmp    $0x9,%al
f0104abf:	77 08                	ja     f0104ac9 <strtol+0x86>
			dig = *s - '0';
f0104ac1:	0f be c9             	movsbl %cl,%ecx
f0104ac4:	83 e9 30             	sub    $0x30,%ecx
f0104ac7:	eb 20                	jmp    f0104ae9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0104ac9:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0104acc:	89 f0                	mov    %esi,%eax
f0104ace:	3c 19                	cmp    $0x19,%al
f0104ad0:	77 08                	ja     f0104ada <strtol+0x97>
			dig = *s - 'a' + 10;
f0104ad2:	0f be c9             	movsbl %cl,%ecx
f0104ad5:	83 e9 57             	sub    $0x57,%ecx
f0104ad8:	eb 0f                	jmp    f0104ae9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0104ada:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0104add:	89 f0                	mov    %esi,%eax
f0104adf:	3c 19                	cmp    $0x19,%al
f0104ae1:	77 16                	ja     f0104af9 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0104ae3:	0f be c9             	movsbl %cl,%ecx
f0104ae6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0104ae9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0104aec:	7d 0f                	jge    f0104afd <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f0104aee:	83 c2 01             	add    $0x1,%edx
f0104af1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0104af5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0104af7:	eb bc                	jmp    f0104ab5 <strtol+0x72>
f0104af9:	89 d8                	mov    %ebx,%eax
f0104afb:	eb 02                	jmp    f0104aff <strtol+0xbc>
f0104afd:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0104aff:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104b03:	74 05                	je     f0104b0a <strtol+0xc7>
		*endptr = (char *) s;
f0104b05:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104b08:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0104b0a:	f7 d8                	neg    %eax
f0104b0c:	85 ff                	test   %edi,%edi
f0104b0e:	0f 44 c3             	cmove  %ebx,%eax
}
f0104b11:	5b                   	pop    %ebx
f0104b12:	5e                   	pop    %esi
f0104b13:	5f                   	pop    %edi
f0104b14:	5d                   	pop    %ebp
f0104b15:	c3                   	ret    
f0104b16:	66 90                	xchg   %ax,%ax
f0104b18:	66 90                	xchg   %ax,%ax
f0104b1a:	66 90                	xchg   %ax,%ax
f0104b1c:	66 90                	xchg   %ax,%ax
f0104b1e:	66 90                	xchg   %ax,%ax

f0104b20 <__udivdi3>:
f0104b20:	55                   	push   %ebp
f0104b21:	57                   	push   %edi
f0104b22:	56                   	push   %esi
f0104b23:	83 ec 0c             	sub    $0xc,%esp
f0104b26:	8b 44 24 28          	mov    0x28(%esp),%eax
f0104b2a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0104b2e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0104b32:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0104b36:	85 c0                	test   %eax,%eax
f0104b38:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104b3c:	89 ea                	mov    %ebp,%edx
f0104b3e:	89 0c 24             	mov    %ecx,(%esp)
f0104b41:	75 2d                	jne    f0104b70 <__udivdi3+0x50>
f0104b43:	39 e9                	cmp    %ebp,%ecx
f0104b45:	77 61                	ja     f0104ba8 <__udivdi3+0x88>
f0104b47:	85 c9                	test   %ecx,%ecx
f0104b49:	89 ce                	mov    %ecx,%esi
f0104b4b:	75 0b                	jne    f0104b58 <__udivdi3+0x38>
f0104b4d:	b8 01 00 00 00       	mov    $0x1,%eax
f0104b52:	31 d2                	xor    %edx,%edx
f0104b54:	f7 f1                	div    %ecx
f0104b56:	89 c6                	mov    %eax,%esi
f0104b58:	31 d2                	xor    %edx,%edx
f0104b5a:	89 e8                	mov    %ebp,%eax
f0104b5c:	f7 f6                	div    %esi
f0104b5e:	89 c5                	mov    %eax,%ebp
f0104b60:	89 f8                	mov    %edi,%eax
f0104b62:	f7 f6                	div    %esi
f0104b64:	89 ea                	mov    %ebp,%edx
f0104b66:	83 c4 0c             	add    $0xc,%esp
f0104b69:	5e                   	pop    %esi
f0104b6a:	5f                   	pop    %edi
f0104b6b:	5d                   	pop    %ebp
f0104b6c:	c3                   	ret    
f0104b6d:	8d 76 00             	lea    0x0(%esi),%esi
f0104b70:	39 e8                	cmp    %ebp,%eax
f0104b72:	77 24                	ja     f0104b98 <__udivdi3+0x78>
f0104b74:	0f bd e8             	bsr    %eax,%ebp
f0104b77:	83 f5 1f             	xor    $0x1f,%ebp
f0104b7a:	75 3c                	jne    f0104bb8 <__udivdi3+0x98>
f0104b7c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0104b80:	39 34 24             	cmp    %esi,(%esp)
f0104b83:	0f 86 9f 00 00 00    	jbe    f0104c28 <__udivdi3+0x108>
f0104b89:	39 d0                	cmp    %edx,%eax
f0104b8b:	0f 82 97 00 00 00    	jb     f0104c28 <__udivdi3+0x108>
f0104b91:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104b98:	31 d2                	xor    %edx,%edx
f0104b9a:	31 c0                	xor    %eax,%eax
f0104b9c:	83 c4 0c             	add    $0xc,%esp
f0104b9f:	5e                   	pop    %esi
f0104ba0:	5f                   	pop    %edi
f0104ba1:	5d                   	pop    %ebp
f0104ba2:	c3                   	ret    
f0104ba3:	90                   	nop
f0104ba4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104ba8:	89 f8                	mov    %edi,%eax
f0104baa:	f7 f1                	div    %ecx
f0104bac:	31 d2                	xor    %edx,%edx
f0104bae:	83 c4 0c             	add    $0xc,%esp
f0104bb1:	5e                   	pop    %esi
f0104bb2:	5f                   	pop    %edi
f0104bb3:	5d                   	pop    %ebp
f0104bb4:	c3                   	ret    
f0104bb5:	8d 76 00             	lea    0x0(%esi),%esi
f0104bb8:	89 e9                	mov    %ebp,%ecx
f0104bba:	8b 3c 24             	mov    (%esp),%edi
f0104bbd:	d3 e0                	shl    %cl,%eax
f0104bbf:	89 c6                	mov    %eax,%esi
f0104bc1:	b8 20 00 00 00       	mov    $0x20,%eax
f0104bc6:	29 e8                	sub    %ebp,%eax
f0104bc8:	89 c1                	mov    %eax,%ecx
f0104bca:	d3 ef                	shr    %cl,%edi
f0104bcc:	89 e9                	mov    %ebp,%ecx
f0104bce:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0104bd2:	8b 3c 24             	mov    (%esp),%edi
f0104bd5:	09 74 24 08          	or     %esi,0x8(%esp)
f0104bd9:	89 d6                	mov    %edx,%esi
f0104bdb:	d3 e7                	shl    %cl,%edi
f0104bdd:	89 c1                	mov    %eax,%ecx
f0104bdf:	89 3c 24             	mov    %edi,(%esp)
f0104be2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0104be6:	d3 ee                	shr    %cl,%esi
f0104be8:	89 e9                	mov    %ebp,%ecx
f0104bea:	d3 e2                	shl    %cl,%edx
f0104bec:	89 c1                	mov    %eax,%ecx
f0104bee:	d3 ef                	shr    %cl,%edi
f0104bf0:	09 d7                	or     %edx,%edi
f0104bf2:	89 f2                	mov    %esi,%edx
f0104bf4:	89 f8                	mov    %edi,%eax
f0104bf6:	f7 74 24 08          	divl   0x8(%esp)
f0104bfa:	89 d6                	mov    %edx,%esi
f0104bfc:	89 c7                	mov    %eax,%edi
f0104bfe:	f7 24 24             	mull   (%esp)
f0104c01:	39 d6                	cmp    %edx,%esi
f0104c03:	89 14 24             	mov    %edx,(%esp)
f0104c06:	72 30                	jb     f0104c38 <__udivdi3+0x118>
f0104c08:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104c0c:	89 e9                	mov    %ebp,%ecx
f0104c0e:	d3 e2                	shl    %cl,%edx
f0104c10:	39 c2                	cmp    %eax,%edx
f0104c12:	73 05                	jae    f0104c19 <__udivdi3+0xf9>
f0104c14:	3b 34 24             	cmp    (%esp),%esi
f0104c17:	74 1f                	je     f0104c38 <__udivdi3+0x118>
f0104c19:	89 f8                	mov    %edi,%eax
f0104c1b:	31 d2                	xor    %edx,%edx
f0104c1d:	e9 7a ff ff ff       	jmp    f0104b9c <__udivdi3+0x7c>
f0104c22:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104c28:	31 d2                	xor    %edx,%edx
f0104c2a:	b8 01 00 00 00       	mov    $0x1,%eax
f0104c2f:	e9 68 ff ff ff       	jmp    f0104b9c <__udivdi3+0x7c>
f0104c34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104c38:	8d 47 ff             	lea    -0x1(%edi),%eax
f0104c3b:	31 d2                	xor    %edx,%edx
f0104c3d:	83 c4 0c             	add    $0xc,%esp
f0104c40:	5e                   	pop    %esi
f0104c41:	5f                   	pop    %edi
f0104c42:	5d                   	pop    %ebp
f0104c43:	c3                   	ret    
f0104c44:	66 90                	xchg   %ax,%ax
f0104c46:	66 90                	xchg   %ax,%ax
f0104c48:	66 90                	xchg   %ax,%ax
f0104c4a:	66 90                	xchg   %ax,%ax
f0104c4c:	66 90                	xchg   %ax,%ax
f0104c4e:	66 90                	xchg   %ax,%ax

f0104c50 <__umoddi3>:
f0104c50:	55                   	push   %ebp
f0104c51:	57                   	push   %edi
f0104c52:	56                   	push   %esi
f0104c53:	83 ec 14             	sub    $0x14,%esp
f0104c56:	8b 44 24 28          	mov    0x28(%esp),%eax
f0104c5a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0104c5e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0104c62:	89 c7                	mov    %eax,%edi
f0104c64:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104c68:	8b 44 24 30          	mov    0x30(%esp),%eax
f0104c6c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0104c70:	89 34 24             	mov    %esi,(%esp)
f0104c73:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104c77:	85 c0                	test   %eax,%eax
f0104c79:	89 c2                	mov    %eax,%edx
f0104c7b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104c7f:	75 17                	jne    f0104c98 <__umoddi3+0x48>
f0104c81:	39 fe                	cmp    %edi,%esi
f0104c83:	76 4b                	jbe    f0104cd0 <__umoddi3+0x80>
f0104c85:	89 c8                	mov    %ecx,%eax
f0104c87:	89 fa                	mov    %edi,%edx
f0104c89:	f7 f6                	div    %esi
f0104c8b:	89 d0                	mov    %edx,%eax
f0104c8d:	31 d2                	xor    %edx,%edx
f0104c8f:	83 c4 14             	add    $0x14,%esp
f0104c92:	5e                   	pop    %esi
f0104c93:	5f                   	pop    %edi
f0104c94:	5d                   	pop    %ebp
f0104c95:	c3                   	ret    
f0104c96:	66 90                	xchg   %ax,%ax
f0104c98:	39 f8                	cmp    %edi,%eax
f0104c9a:	77 54                	ja     f0104cf0 <__umoddi3+0xa0>
f0104c9c:	0f bd e8             	bsr    %eax,%ebp
f0104c9f:	83 f5 1f             	xor    $0x1f,%ebp
f0104ca2:	75 5c                	jne    f0104d00 <__umoddi3+0xb0>
f0104ca4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0104ca8:	39 3c 24             	cmp    %edi,(%esp)
f0104cab:	0f 87 e7 00 00 00    	ja     f0104d98 <__umoddi3+0x148>
f0104cb1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0104cb5:	29 f1                	sub    %esi,%ecx
f0104cb7:	19 c7                	sbb    %eax,%edi
f0104cb9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104cbd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104cc1:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104cc5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0104cc9:	83 c4 14             	add    $0x14,%esp
f0104ccc:	5e                   	pop    %esi
f0104ccd:	5f                   	pop    %edi
f0104cce:	5d                   	pop    %ebp
f0104ccf:	c3                   	ret    
f0104cd0:	85 f6                	test   %esi,%esi
f0104cd2:	89 f5                	mov    %esi,%ebp
f0104cd4:	75 0b                	jne    f0104ce1 <__umoddi3+0x91>
f0104cd6:	b8 01 00 00 00       	mov    $0x1,%eax
f0104cdb:	31 d2                	xor    %edx,%edx
f0104cdd:	f7 f6                	div    %esi
f0104cdf:	89 c5                	mov    %eax,%ebp
f0104ce1:	8b 44 24 04          	mov    0x4(%esp),%eax
f0104ce5:	31 d2                	xor    %edx,%edx
f0104ce7:	f7 f5                	div    %ebp
f0104ce9:	89 c8                	mov    %ecx,%eax
f0104ceb:	f7 f5                	div    %ebp
f0104ced:	eb 9c                	jmp    f0104c8b <__umoddi3+0x3b>
f0104cef:	90                   	nop
f0104cf0:	89 c8                	mov    %ecx,%eax
f0104cf2:	89 fa                	mov    %edi,%edx
f0104cf4:	83 c4 14             	add    $0x14,%esp
f0104cf7:	5e                   	pop    %esi
f0104cf8:	5f                   	pop    %edi
f0104cf9:	5d                   	pop    %ebp
f0104cfa:	c3                   	ret    
f0104cfb:	90                   	nop
f0104cfc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104d00:	8b 04 24             	mov    (%esp),%eax
f0104d03:	be 20 00 00 00       	mov    $0x20,%esi
f0104d08:	89 e9                	mov    %ebp,%ecx
f0104d0a:	29 ee                	sub    %ebp,%esi
f0104d0c:	d3 e2                	shl    %cl,%edx
f0104d0e:	89 f1                	mov    %esi,%ecx
f0104d10:	d3 e8                	shr    %cl,%eax
f0104d12:	89 e9                	mov    %ebp,%ecx
f0104d14:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104d18:	8b 04 24             	mov    (%esp),%eax
f0104d1b:	09 54 24 04          	or     %edx,0x4(%esp)
f0104d1f:	89 fa                	mov    %edi,%edx
f0104d21:	d3 e0                	shl    %cl,%eax
f0104d23:	89 f1                	mov    %esi,%ecx
f0104d25:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104d29:	8b 44 24 10          	mov    0x10(%esp),%eax
f0104d2d:	d3 ea                	shr    %cl,%edx
f0104d2f:	89 e9                	mov    %ebp,%ecx
f0104d31:	d3 e7                	shl    %cl,%edi
f0104d33:	89 f1                	mov    %esi,%ecx
f0104d35:	d3 e8                	shr    %cl,%eax
f0104d37:	89 e9                	mov    %ebp,%ecx
f0104d39:	09 f8                	or     %edi,%eax
f0104d3b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0104d3f:	f7 74 24 04          	divl   0x4(%esp)
f0104d43:	d3 e7                	shl    %cl,%edi
f0104d45:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104d49:	89 d7                	mov    %edx,%edi
f0104d4b:	f7 64 24 08          	mull   0x8(%esp)
f0104d4f:	39 d7                	cmp    %edx,%edi
f0104d51:	89 c1                	mov    %eax,%ecx
f0104d53:	89 14 24             	mov    %edx,(%esp)
f0104d56:	72 2c                	jb     f0104d84 <__umoddi3+0x134>
f0104d58:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0104d5c:	72 22                	jb     f0104d80 <__umoddi3+0x130>
f0104d5e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0104d62:	29 c8                	sub    %ecx,%eax
f0104d64:	19 d7                	sbb    %edx,%edi
f0104d66:	89 e9                	mov    %ebp,%ecx
f0104d68:	89 fa                	mov    %edi,%edx
f0104d6a:	d3 e8                	shr    %cl,%eax
f0104d6c:	89 f1                	mov    %esi,%ecx
f0104d6e:	d3 e2                	shl    %cl,%edx
f0104d70:	89 e9                	mov    %ebp,%ecx
f0104d72:	d3 ef                	shr    %cl,%edi
f0104d74:	09 d0                	or     %edx,%eax
f0104d76:	89 fa                	mov    %edi,%edx
f0104d78:	83 c4 14             	add    $0x14,%esp
f0104d7b:	5e                   	pop    %esi
f0104d7c:	5f                   	pop    %edi
f0104d7d:	5d                   	pop    %ebp
f0104d7e:	c3                   	ret    
f0104d7f:	90                   	nop
f0104d80:	39 d7                	cmp    %edx,%edi
f0104d82:	75 da                	jne    f0104d5e <__umoddi3+0x10e>
f0104d84:	8b 14 24             	mov    (%esp),%edx
f0104d87:	89 c1                	mov    %eax,%ecx
f0104d89:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0104d8d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0104d91:	eb cb                	jmp    f0104d5e <__umoddi3+0x10e>
f0104d93:	90                   	nop
f0104d94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104d98:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0104d9c:	0f 82 0f ff ff ff    	jb     f0104cb1 <__umoddi3+0x61>
f0104da2:	e9 1a ff ff ff       	jmp    f0104cc1 <__umoddi3+0x71>
