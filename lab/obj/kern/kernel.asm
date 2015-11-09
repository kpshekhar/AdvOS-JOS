
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
f0100015:	b8 00 e0 11 00       	mov    $0x11e000,%eax
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
f0100034:	bc 00 e0 11 f0       	mov    $0xf011e000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5c 00 00 00       	call   f010009a <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100048:	83 3d c0 0e 23 f0 00 	cmpl   $0x0,0xf0230ec0
f010004f:	75 3a                	jne    f010008b <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f0100051:	89 35 c0 0e 23 f0    	mov    %esi,0xf0230ec0

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100057:	fa                   	cli    
f0100058:	fc                   	cld    

	va_start(ap, fmt);
f0100059:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005c:	e8 6a 59 00 00       	call   f01059cb <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 80 60 10 f0       	push   $0xf0106080
f010006d:	e8 df 37 00 00       	call   f0103851 <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 af 37 00 00       	call   f010382b <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 12 79 10 f0 	movl   $0xf0107912,(%esp)
f0100083:	e8 c9 37 00 00       	call   f0103851 <cprintf>
	va_end(ap);
f0100088:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010008b:	83 ec 0c             	sub    $0xc,%esp
f010008e:	6a 00                	push   $0x0
f0100090:	e8 49 08 00 00       	call   f01008de <monitor>
f0100095:	83 c4 10             	add    $0x10,%esp
f0100098:	eb f1                	jmp    f010008b <_panic+0x4b>

f010009a <i386_init>:
static void boot_aps(void);


void
i386_init(void)
{
f010009a:	55                   	push   %ebp
f010009b:	89 e5                	mov    %esp,%ebp
f010009d:	53                   	push   %ebx
f010009e:	83 ec 08             	sub    $0x8,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a1:	b8 08 20 27 f0       	mov    $0xf0272008,%eax
f01000a6:	2d 28 f0 22 f0       	sub    $0xf022f028,%eax
f01000ab:	50                   	push   %eax
f01000ac:	6a 00                	push   $0x0
f01000ae:	68 28 f0 22 f0       	push   $0xf022f028
f01000b3:	e8 f0 52 00 00       	call   f01053a8 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 72 05 00 00       	call   f010062f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 ec 60 10 f0       	push   $0xf01060ec
f01000ca:	e8 82 37 00 00       	call   f0103851 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 e3 12 00 00       	call   f01013b7 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 b2 2f 00 00       	call   f010308b <env_init>
	trap_init();
f01000d9:	e8 1c 38 00 00       	call   f01038fa <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 e1 55 00 00       	call   f01056c4 <mp_init>
	lapic_init();
f01000e3:	e8 fe 58 00 00       	call   f01059e6 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 a0 36 00 00       	call   f010378d <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000ed:	c7 04 24 c0 04 12 f0 	movl   $0xf01204c0,(%esp)
f01000f4:	e8 3d 5b 00 00       	call   f0105c36 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000f9:	83 c4 10             	add    $0x10,%esp
f01000fc:	83 3d c8 0e 23 f0 07 	cmpl   $0x7,0xf0230ec8
f0100103:	77 16                	ja     f010011b <i386_init+0x81>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100105:	68 00 70 00 00       	push   $0x7000
f010010a:	68 a4 60 10 f0       	push   $0xf01060a4
f010010f:	6a 59                	push   $0x59
f0100111:	68 07 61 10 f0       	push   $0xf0106107
f0100116:	e8 25 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010011b:	83 ec 04             	sub    $0x4,%esp
f010011e:	b8 2a 56 10 f0       	mov    $0xf010562a,%eax
f0100123:	2d b0 55 10 f0       	sub    $0xf01055b0,%eax
f0100128:	50                   	push   %eax
f0100129:	68 b0 55 10 f0       	push   $0xf01055b0
f010012e:	68 00 70 00 f0       	push   $0xf0007000
f0100133:	e8 bd 52 00 00       	call   f01053f5 <memmove>
f0100138:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010013b:	bb 40 10 23 f0       	mov    $0xf0231040,%ebx
f0100140:	eb 4e                	jmp    f0100190 <i386_init+0xf6>
		if (c == cpus + cpunum())  // We've started already.
f0100142:	e8 84 58 00 00       	call   f01059cb <cpunum>
f0100147:	6b c0 74             	imul   $0x74,%eax,%eax
f010014a:	05 40 10 23 f0       	add    $0xf0231040,%eax
f010014f:	39 c3                	cmp    %eax,%ebx
f0100151:	74 3a                	je     f010018d <i386_init+0xf3>
f0100153:	89 d8                	mov    %ebx,%eax
f0100155:	2d 40 10 23 f0       	sub    $0xf0231040,%eax
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f010015a:	c1 f8 02             	sar    $0x2,%eax
f010015d:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100163:	c1 e0 0f             	shl    $0xf,%eax
f0100166:	8d 80 00 a0 23 f0    	lea    -0xfdc6000(%eax),%eax
f010016c:	a3 c4 0e 23 f0       	mov    %eax,0xf0230ec4
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100171:	83 ec 08             	sub    $0x8,%esp
f0100174:	68 00 70 00 00       	push   $0x7000
f0100179:	0f b6 03             	movzbl (%ebx),%eax
f010017c:	50                   	push   %eax
f010017d:	e8 b2 59 00 00       	call   f0105b34 <lapic_startap>
f0100182:	83 c4 10             	add    $0x10,%esp
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f0100185:	8b 43 04             	mov    0x4(%ebx),%eax
f0100188:	83 f8 01             	cmp    $0x1,%eax
f010018b:	75 f8                	jne    f0100185 <i386_init+0xeb>
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010018d:	83 c3 74             	add    $0x74,%ebx
f0100190:	6b 05 e4 13 23 f0 74 	imul   $0x74,0xf02313e4,%eax
f0100197:	05 40 10 23 f0       	add    $0xf0231040,%eax
f010019c:	39 c3                	cmp    %eax,%ebx
f010019e:	72 a2                	jb     f0100142 <i386_init+0xa8>
	// Starting non-boot CPUs
	boot_aps();

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f01001a0:	83 ec 08             	sub    $0x8,%esp
f01001a3:	6a 00                	push   $0x0
f01001a5:	68 94 55 22 f0       	push   $0xf0225594
f01001aa:	e8 b6 30 00 00       	call   f0103265 <env_create>

	//ENV_CREATE(user_yield, ENV_TYPE_USER);
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001af:	e8 2e 40 00 00       	call   f01041e2 <sched_yield>

f01001b4 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001b4:	55                   	push   %ebp
f01001b5:	89 e5                	mov    %esp,%ebp
f01001b7:	83 ec 08             	sub    $0x8,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001ba:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001bf:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001c4:	77 12                	ja     f01001d8 <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001c6:	50                   	push   %eax
f01001c7:	68 c8 60 10 f0       	push   $0xf01060c8
f01001cc:	6a 70                	push   $0x70
f01001ce:	68 07 61 10 f0       	push   $0xf0106107
f01001d3:	e8 68 fe ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01001d8:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01001dd:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001e0:	e8 e6 57 00 00       	call   f01059cb <cpunum>
f01001e5:	83 ec 08             	sub    $0x8,%esp
f01001e8:	50                   	push   %eax
f01001e9:	68 13 61 10 f0       	push   $0xf0106113
f01001ee:	e8 5e 36 00 00       	call   f0103851 <cprintf>

	lapic_init();
f01001f3:	e8 ee 57 00 00       	call   f01059e6 <lapic_init>
	env_init_percpu();
f01001f8:	e8 64 2e 00 00       	call   f0103061 <env_init_percpu>
	trap_init_percpu();
f01001fd:	e8 63 36 00 00       	call   f0103865 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100202:	e8 c4 57 00 00       	call   f01059cb <cpunum>
f0100207:	6b d0 74             	imul   $0x74,%eax,%edx
f010020a:	81 c2 40 10 23 f0    	add    $0xf0231040,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0100210:	b8 01 00 00 00       	mov    $0x1,%eax
f0100215:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0100219:	c7 04 24 c0 04 12 f0 	movl   $0xf01204c0,(%esp)
f0100220:	e8 11 5a 00 00       	call   f0105c36 <spin_lock>
	// to start running processes on this CPU.  But make sure that
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	lock_kernel();  //Acquire the lock
	sched_yield(); //Call the sched_yield() function to schedule and run different environments, Exercise 6
f0100225:	e8 b8 3f 00 00       	call   f01041e2 <sched_yield>

f010022a <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010022a:	55                   	push   %ebp
f010022b:	89 e5                	mov    %esp,%ebp
f010022d:	53                   	push   %ebx
f010022e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100231:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100234:	ff 75 0c             	pushl  0xc(%ebp)
f0100237:	ff 75 08             	pushl  0x8(%ebp)
f010023a:	68 29 61 10 f0       	push   $0xf0106129
f010023f:	e8 0d 36 00 00       	call   f0103851 <cprintf>
	vcprintf(fmt, ap);
f0100244:	83 c4 08             	add    $0x8,%esp
f0100247:	53                   	push   %ebx
f0100248:	ff 75 10             	pushl  0x10(%ebp)
f010024b:	e8 db 35 00 00       	call   f010382b <vcprintf>
	cprintf("\n");
f0100250:	c7 04 24 12 79 10 f0 	movl   $0xf0107912,(%esp)
f0100257:	e8 f5 35 00 00       	call   f0103851 <cprintf>
	va_end(ap);
f010025c:	83 c4 10             	add    $0x10,%esp
}
f010025f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100262:	c9                   	leave  
f0100263:	c3                   	ret    

f0100264 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100264:	55                   	push   %ebp
f0100265:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100267:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010026c:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010026d:	a8 01                	test   $0x1,%al
f010026f:	74 08                	je     f0100279 <serial_proc_data+0x15>
f0100271:	b2 f8                	mov    $0xf8,%dl
f0100273:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100274:	0f b6 c0             	movzbl %al,%eax
f0100277:	eb 05                	jmp    f010027e <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100279:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010027e:	5d                   	pop    %ebp
f010027f:	c3                   	ret    

f0100280 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100280:	55                   	push   %ebp
f0100281:	89 e5                	mov    %esp,%ebp
f0100283:	53                   	push   %ebx
f0100284:	83 ec 04             	sub    $0x4,%esp
f0100287:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100289:	eb 2a                	jmp    f01002b5 <cons_intr+0x35>
		if (c == 0)
f010028b:	85 d2                	test   %edx,%edx
f010028d:	74 26                	je     f01002b5 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010028f:	a1 44 02 23 f0       	mov    0xf0230244,%eax
f0100294:	8d 48 01             	lea    0x1(%eax),%ecx
f0100297:	89 0d 44 02 23 f0    	mov    %ecx,0xf0230244
f010029d:	88 90 40 00 23 f0    	mov    %dl,-0xfdcffc0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01002a3:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01002a9:	75 0a                	jne    f01002b5 <cons_intr+0x35>
			cons.wpos = 0;
f01002ab:	c7 05 44 02 23 f0 00 	movl   $0x0,0xf0230244
f01002b2:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002b5:	ff d3                	call   *%ebx
f01002b7:	89 c2                	mov    %eax,%edx
f01002b9:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002bc:	75 cd                	jne    f010028b <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01002be:	83 c4 04             	add    $0x4,%esp
f01002c1:	5b                   	pop    %ebx
f01002c2:	5d                   	pop    %ebp
f01002c3:	c3                   	ret    

f01002c4 <kbd_proc_data>:
f01002c4:	ba 64 00 00 00       	mov    $0x64,%edx
f01002c9:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01002ca:	a8 01                	test   $0x1,%al
f01002cc:	0f 84 f0 00 00 00    	je     f01003c2 <kbd_proc_data+0xfe>
f01002d2:	b2 60                	mov    $0x60,%dl
f01002d4:	ec                   	in     (%dx),%al
f01002d5:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01002d7:	3c e0                	cmp    $0xe0,%al
f01002d9:	75 0d                	jne    f01002e8 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f01002db:	83 0d 00 00 23 f0 40 	orl    $0x40,0xf0230000
		return 0;
f01002e2:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002e7:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01002e8:	55                   	push   %ebp
f01002e9:	89 e5                	mov    %esp,%ebp
f01002eb:	53                   	push   %ebx
f01002ec:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01002ef:	84 c0                	test   %al,%al
f01002f1:	79 36                	jns    f0100329 <kbd_proc_data+0x65>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01002f3:	8b 0d 00 00 23 f0    	mov    0xf0230000,%ecx
f01002f9:	89 cb                	mov    %ecx,%ebx
f01002fb:	83 e3 40             	and    $0x40,%ebx
f01002fe:	83 e0 7f             	and    $0x7f,%eax
f0100301:	85 db                	test   %ebx,%ebx
f0100303:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100306:	0f b6 d2             	movzbl %dl,%edx
f0100309:	0f b6 82 c0 62 10 f0 	movzbl -0xfef9d40(%edx),%eax
f0100310:	83 c8 40             	or     $0x40,%eax
f0100313:	0f b6 c0             	movzbl %al,%eax
f0100316:	f7 d0                	not    %eax
f0100318:	21 c8                	and    %ecx,%eax
f010031a:	a3 00 00 23 f0       	mov    %eax,0xf0230000
		return 0;
f010031f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100324:	e9 a1 00 00 00       	jmp    f01003ca <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f0100329:	8b 0d 00 00 23 f0    	mov    0xf0230000,%ecx
f010032f:	f6 c1 40             	test   $0x40,%cl
f0100332:	74 0e                	je     f0100342 <kbd_proc_data+0x7e>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100334:	83 c8 80             	or     $0xffffff80,%eax
f0100337:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100339:	83 e1 bf             	and    $0xffffffbf,%ecx
f010033c:	89 0d 00 00 23 f0    	mov    %ecx,0xf0230000
	}

	shift |= shiftcode[data];
f0100342:	0f b6 c2             	movzbl %dl,%eax
f0100345:	0f b6 90 c0 62 10 f0 	movzbl -0xfef9d40(%eax),%edx
f010034c:	0b 15 00 00 23 f0    	or     0xf0230000,%edx
	shift ^= togglecode[data];
f0100352:	0f b6 88 c0 61 10 f0 	movzbl -0xfef9e40(%eax),%ecx
f0100359:	31 ca                	xor    %ecx,%edx
f010035b:	89 15 00 00 23 f0    	mov    %edx,0xf0230000

	c = charcode[shift & (CTL | SHIFT)][data];
f0100361:	89 d1                	mov    %edx,%ecx
f0100363:	83 e1 03             	and    $0x3,%ecx
f0100366:	8b 0c 8d 80 61 10 f0 	mov    -0xfef9e80(,%ecx,4),%ecx
f010036d:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f0100371:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f0100374:	f6 c2 08             	test   $0x8,%dl
f0100377:	74 1b                	je     f0100394 <kbd_proc_data+0xd0>
		if ('a' <= c && c <= 'z')
f0100379:	89 d8                	mov    %ebx,%eax
f010037b:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010037e:	83 f9 19             	cmp    $0x19,%ecx
f0100381:	77 05                	ja     f0100388 <kbd_proc_data+0xc4>
			c += 'A' - 'a';
f0100383:	83 eb 20             	sub    $0x20,%ebx
f0100386:	eb 0c                	jmp    f0100394 <kbd_proc_data+0xd0>
		else if ('A' <= c && c <= 'Z')
f0100388:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f010038b:	8d 4b 20             	lea    0x20(%ebx),%ecx
f010038e:	83 f8 19             	cmp    $0x19,%eax
f0100391:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100394:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010039a:	75 2c                	jne    f01003c8 <kbd_proc_data+0x104>
f010039c:	f7 d2                	not    %edx
f010039e:	f6 c2 06             	test   $0x6,%dl
f01003a1:	75 25                	jne    f01003c8 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01003a3:	83 ec 0c             	sub    $0xc,%esp
f01003a6:	68 43 61 10 f0       	push   $0xf0106143
f01003ab:	e8 a1 34 00 00       	call   f0103851 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003b0:	ba 92 00 00 00       	mov    $0x92,%edx
f01003b5:	b8 03 00 00 00       	mov    $0x3,%eax
f01003ba:	ee                   	out    %al,(%dx)
f01003bb:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003be:	89 d8                	mov    %ebx,%eax
f01003c0:	eb 08                	jmp    f01003ca <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01003c2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01003c7:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003c8:	89 d8                	mov    %ebx,%eax
}
f01003ca:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01003cd:	c9                   	leave  
f01003ce:	c3                   	ret    

f01003cf <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003cf:	55                   	push   %ebp
f01003d0:	89 e5                	mov    %esp,%ebp
f01003d2:	57                   	push   %edi
f01003d3:	56                   	push   %esi
f01003d4:	53                   	push   %ebx
f01003d5:	83 ec 1c             	sub    $0x1c,%esp
f01003d8:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01003da:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003df:	be fd 03 00 00       	mov    $0x3fd,%esi
f01003e4:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003e9:	eb 09                	jmp    f01003f4 <cons_putc+0x25>
f01003eb:	89 ca                	mov    %ecx,%edx
f01003ed:	ec                   	in     (%dx),%al
f01003ee:	ec                   	in     (%dx),%al
f01003ef:	ec                   	in     (%dx),%al
f01003f0:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01003f1:	83 c3 01             	add    $0x1,%ebx
f01003f4:	89 f2                	mov    %esi,%edx
f01003f6:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01003f7:	a8 20                	test   $0x20,%al
f01003f9:	75 08                	jne    f0100403 <cons_putc+0x34>
f01003fb:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100401:	7e e8                	jle    f01003eb <cons_putc+0x1c>
f0100403:	89 f8                	mov    %edi,%eax
f0100405:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100408:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010040d:	89 f8                	mov    %edi,%eax
f010040f:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100410:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100415:	be 79 03 00 00       	mov    $0x379,%esi
f010041a:	b9 84 00 00 00       	mov    $0x84,%ecx
f010041f:	eb 09                	jmp    f010042a <cons_putc+0x5b>
f0100421:	89 ca                	mov    %ecx,%edx
f0100423:	ec                   	in     (%dx),%al
f0100424:	ec                   	in     (%dx),%al
f0100425:	ec                   	in     (%dx),%al
f0100426:	ec                   	in     (%dx),%al
f0100427:	83 c3 01             	add    $0x1,%ebx
f010042a:	89 f2                	mov    %esi,%edx
f010042c:	ec                   	in     (%dx),%al
f010042d:	84 c0                	test   %al,%al
f010042f:	78 08                	js     f0100439 <cons_putc+0x6a>
f0100431:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100437:	7e e8                	jle    f0100421 <cons_putc+0x52>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100439:	ba 78 03 00 00       	mov    $0x378,%edx
f010043e:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100442:	ee                   	out    %al,(%dx)
f0100443:	b2 7a                	mov    $0x7a,%dl
f0100445:	b8 0d 00 00 00       	mov    $0xd,%eax
f010044a:	ee                   	out    %al,(%dx)
f010044b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100450:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100451:	89 fa                	mov    %edi,%edx
f0100453:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100459:	89 f8                	mov    %edi,%eax
f010045b:	80 cc 07             	or     $0x7,%ah
f010045e:	85 d2                	test   %edx,%edx
f0100460:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100463:	89 f8                	mov    %edi,%eax
f0100465:	0f b6 c0             	movzbl %al,%eax
f0100468:	83 f8 09             	cmp    $0x9,%eax
f010046b:	74 74                	je     f01004e1 <cons_putc+0x112>
f010046d:	83 f8 09             	cmp    $0x9,%eax
f0100470:	7f 0a                	jg     f010047c <cons_putc+0xad>
f0100472:	83 f8 08             	cmp    $0x8,%eax
f0100475:	74 14                	je     f010048b <cons_putc+0xbc>
f0100477:	e9 99 00 00 00       	jmp    f0100515 <cons_putc+0x146>
f010047c:	83 f8 0a             	cmp    $0xa,%eax
f010047f:	74 3a                	je     f01004bb <cons_putc+0xec>
f0100481:	83 f8 0d             	cmp    $0xd,%eax
f0100484:	74 3d                	je     f01004c3 <cons_putc+0xf4>
f0100486:	e9 8a 00 00 00       	jmp    f0100515 <cons_putc+0x146>
	case '\b':
		if (crt_pos > 0) {
f010048b:	0f b7 05 48 02 23 f0 	movzwl 0xf0230248,%eax
f0100492:	66 85 c0             	test   %ax,%ax
f0100495:	0f 84 e6 00 00 00    	je     f0100581 <cons_putc+0x1b2>
			crt_pos--;
f010049b:	83 e8 01             	sub    $0x1,%eax
f010049e:	66 a3 48 02 23 f0    	mov    %ax,0xf0230248
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004a4:	0f b7 c0             	movzwl %ax,%eax
f01004a7:	66 81 e7 00 ff       	and    $0xff00,%di
f01004ac:	83 cf 20             	or     $0x20,%edi
f01004af:	8b 15 4c 02 23 f0    	mov    0xf023024c,%edx
f01004b5:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004b9:	eb 78                	jmp    f0100533 <cons_putc+0x164>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004bb:	66 83 05 48 02 23 f0 	addw   $0x50,0xf0230248
f01004c2:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004c3:	0f b7 05 48 02 23 f0 	movzwl 0xf0230248,%eax
f01004ca:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004d0:	c1 e8 16             	shr    $0x16,%eax
f01004d3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004d6:	c1 e0 04             	shl    $0x4,%eax
f01004d9:	66 a3 48 02 23 f0    	mov    %ax,0xf0230248
f01004df:	eb 52                	jmp    f0100533 <cons_putc+0x164>
		break;
	case '\t':
		cons_putc(' ');
f01004e1:	b8 20 00 00 00       	mov    $0x20,%eax
f01004e6:	e8 e4 fe ff ff       	call   f01003cf <cons_putc>
		cons_putc(' ');
f01004eb:	b8 20 00 00 00       	mov    $0x20,%eax
f01004f0:	e8 da fe ff ff       	call   f01003cf <cons_putc>
		cons_putc(' ');
f01004f5:	b8 20 00 00 00       	mov    $0x20,%eax
f01004fa:	e8 d0 fe ff ff       	call   f01003cf <cons_putc>
		cons_putc(' ');
f01004ff:	b8 20 00 00 00       	mov    $0x20,%eax
f0100504:	e8 c6 fe ff ff       	call   f01003cf <cons_putc>
		cons_putc(' ');
f0100509:	b8 20 00 00 00       	mov    $0x20,%eax
f010050e:	e8 bc fe ff ff       	call   f01003cf <cons_putc>
f0100513:	eb 1e                	jmp    f0100533 <cons_putc+0x164>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100515:	0f b7 05 48 02 23 f0 	movzwl 0xf0230248,%eax
f010051c:	8d 50 01             	lea    0x1(%eax),%edx
f010051f:	66 89 15 48 02 23 f0 	mov    %dx,0xf0230248
f0100526:	0f b7 c0             	movzwl %ax,%eax
f0100529:	8b 15 4c 02 23 f0    	mov    0xf023024c,%edx
f010052f:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100533:	66 81 3d 48 02 23 f0 	cmpw   $0x7cf,0xf0230248
f010053a:	cf 07 
f010053c:	76 43                	jbe    f0100581 <cons_putc+0x1b2>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010053e:	a1 4c 02 23 f0       	mov    0xf023024c,%eax
f0100543:	83 ec 04             	sub    $0x4,%esp
f0100546:	68 00 0f 00 00       	push   $0xf00
f010054b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100551:	52                   	push   %edx
f0100552:	50                   	push   %eax
f0100553:	e8 9d 4e 00 00       	call   f01053f5 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100558:	8b 15 4c 02 23 f0    	mov    0xf023024c,%edx
f010055e:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100564:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010056a:	83 c4 10             	add    $0x10,%esp
f010056d:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100572:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100575:	39 d0                	cmp    %edx,%eax
f0100577:	75 f4                	jne    f010056d <cons_putc+0x19e>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100579:	66 83 2d 48 02 23 f0 	subw   $0x50,0xf0230248
f0100580:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100581:	8b 0d 50 02 23 f0    	mov    0xf0230250,%ecx
f0100587:	b8 0e 00 00 00       	mov    $0xe,%eax
f010058c:	89 ca                	mov    %ecx,%edx
f010058e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010058f:	0f b7 1d 48 02 23 f0 	movzwl 0xf0230248,%ebx
f0100596:	8d 71 01             	lea    0x1(%ecx),%esi
f0100599:	89 d8                	mov    %ebx,%eax
f010059b:	66 c1 e8 08          	shr    $0x8,%ax
f010059f:	89 f2                	mov    %esi,%edx
f01005a1:	ee                   	out    %al,(%dx)
f01005a2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005a7:	89 ca                	mov    %ecx,%edx
f01005a9:	ee                   	out    %al,(%dx)
f01005aa:	89 d8                	mov    %ebx,%eax
f01005ac:	89 f2                	mov    %esi,%edx
f01005ae:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005af:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005b2:	5b                   	pop    %ebx
f01005b3:	5e                   	pop    %esi
f01005b4:	5f                   	pop    %edi
f01005b5:	5d                   	pop    %ebp
f01005b6:	c3                   	ret    

f01005b7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01005b7:	80 3d 54 02 23 f0 00 	cmpb   $0x0,0xf0230254
f01005be:	74 11                	je     f01005d1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01005c0:	55                   	push   %ebp
f01005c1:	89 e5                	mov    %esp,%ebp
f01005c3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01005c6:	b8 64 02 10 f0       	mov    $0xf0100264,%eax
f01005cb:	e8 b0 fc ff ff       	call   f0100280 <cons_intr>
}
f01005d0:	c9                   	leave  
f01005d1:	f3 c3                	repz ret 

f01005d3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01005d3:	55                   	push   %ebp
f01005d4:	89 e5                	mov    %esp,%ebp
f01005d6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01005d9:	b8 c4 02 10 f0       	mov    $0xf01002c4,%eax
f01005de:	e8 9d fc ff ff       	call   f0100280 <cons_intr>
}
f01005e3:	c9                   	leave  
f01005e4:	c3                   	ret    

f01005e5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01005e5:	55                   	push   %ebp
f01005e6:	89 e5                	mov    %esp,%ebp
f01005e8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01005eb:	e8 c7 ff ff ff       	call   f01005b7 <serial_intr>
	kbd_intr();
f01005f0:	e8 de ff ff ff       	call   f01005d3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01005f5:	a1 40 02 23 f0       	mov    0xf0230240,%eax
f01005fa:	3b 05 44 02 23 f0    	cmp    0xf0230244,%eax
f0100600:	74 26                	je     f0100628 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100602:	8d 50 01             	lea    0x1(%eax),%edx
f0100605:	89 15 40 02 23 f0    	mov    %edx,0xf0230240
f010060b:	0f b6 88 40 00 23 f0 	movzbl -0xfdcffc0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100612:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100614:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010061a:	75 11                	jne    f010062d <cons_getc+0x48>
			cons.rpos = 0;
f010061c:	c7 05 40 02 23 f0 00 	movl   $0x0,0xf0230240
f0100623:	00 00 00 
f0100626:	eb 05                	jmp    f010062d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100628:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010062d:	c9                   	leave  
f010062e:	c3                   	ret    

f010062f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010062f:	55                   	push   %ebp
f0100630:	89 e5                	mov    %esp,%ebp
f0100632:	57                   	push   %edi
f0100633:	56                   	push   %esi
f0100634:	53                   	push   %ebx
f0100635:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100638:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010063f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100646:	5a a5 
	if (*cp != 0xA55A) {
f0100648:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010064f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100653:	74 11                	je     f0100666 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100655:	c7 05 50 02 23 f0 b4 	movl   $0x3b4,0xf0230250
f010065c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010065f:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100664:	eb 16                	jmp    f010067c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100666:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010066d:	c7 05 50 02 23 f0 d4 	movl   $0x3d4,0xf0230250
f0100674:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100677:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010067c:	8b 3d 50 02 23 f0    	mov    0xf0230250,%edi
f0100682:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100687:	89 fa                	mov    %edi,%edx
f0100689:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010068a:	8d 4f 01             	lea    0x1(%edi),%ecx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010068d:	89 ca                	mov    %ecx,%edx
f010068f:	ec                   	in     (%dx),%al
f0100690:	0f b6 c0             	movzbl %al,%eax
f0100693:	c1 e0 08             	shl    $0x8,%eax
f0100696:	89 c3                	mov    %eax,%ebx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100698:	b8 0f 00 00 00       	mov    $0xf,%eax
f010069d:	89 fa                	mov    %edi,%edx
f010069f:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006a0:	89 ca                	mov    %ecx,%edx
f01006a2:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006a3:	89 35 4c 02 23 f0    	mov    %esi,0xf023024c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01006a9:	0f b6 c8             	movzbl %al,%ecx
f01006ac:	89 d8                	mov    %ebx,%eax
f01006ae:	09 c8                	or     %ecx,%eax

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01006b0:	66 a3 48 02 23 f0    	mov    %ax,0xf0230248

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006b6:	e8 18 ff ff ff       	call   f01005d3 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<1));
f01006bb:	83 ec 0c             	sub    $0xc,%esp
f01006be:	0f b7 05 e8 03 12 f0 	movzwl 0xf01203e8,%eax
f01006c5:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006ca:	50                   	push   %eax
f01006cb:	e8 48 30 00 00       	call   f0103718 <irq_setmask_8259A>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006d0:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01006d5:	b8 00 00 00 00       	mov    $0x0,%eax
f01006da:	89 da                	mov    %ebx,%edx
f01006dc:	ee                   	out    %al,(%dx)
f01006dd:	b2 fb                	mov    $0xfb,%dl
f01006df:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006e4:	ee                   	out    %al,(%dx)
f01006e5:	be f8 03 00 00       	mov    $0x3f8,%esi
f01006ea:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006ef:	89 f2                	mov    %esi,%edx
f01006f1:	ee                   	out    %al,(%dx)
f01006f2:	b2 f9                	mov    $0xf9,%dl
f01006f4:	b8 00 00 00 00       	mov    $0x0,%eax
f01006f9:	ee                   	out    %al,(%dx)
f01006fa:	b2 fb                	mov    $0xfb,%dl
f01006fc:	b8 03 00 00 00       	mov    $0x3,%eax
f0100701:	ee                   	out    %al,(%dx)
f0100702:	b2 fc                	mov    $0xfc,%dl
f0100704:	b8 00 00 00 00       	mov    $0x0,%eax
f0100709:	ee                   	out    %al,(%dx)
f010070a:	b2 f9                	mov    $0xf9,%dl
f010070c:	b8 01 00 00 00       	mov    $0x1,%eax
f0100711:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100712:	b2 fd                	mov    $0xfd,%dl
f0100714:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100715:	83 c4 10             	add    $0x10,%esp
f0100718:	3c ff                	cmp    $0xff,%al
f010071a:	0f 95 c1             	setne  %cl
f010071d:	88 0d 54 02 23 f0    	mov    %cl,0xf0230254
f0100723:	89 da                	mov    %ebx,%edx
f0100725:	ec                   	in     (%dx),%al
f0100726:	89 f2                	mov    %esi,%edx
f0100728:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100729:	84 c9                	test   %cl,%cl
f010072b:	75 10                	jne    f010073d <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
f010072d:	83 ec 0c             	sub    $0xc,%esp
f0100730:	68 4f 61 10 f0       	push   $0xf010614f
f0100735:	e8 17 31 00 00       	call   f0103851 <cprintf>
f010073a:	83 c4 10             	add    $0x10,%esp
}
f010073d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100740:	5b                   	pop    %ebx
f0100741:	5e                   	pop    %esi
f0100742:	5f                   	pop    %edi
f0100743:	5d                   	pop    %ebp
f0100744:	c3                   	ret    

f0100745 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100745:	55                   	push   %ebp
f0100746:	89 e5                	mov    %esp,%ebp
f0100748:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010074b:	8b 45 08             	mov    0x8(%ebp),%eax
f010074e:	e8 7c fc ff ff       	call   f01003cf <cons_putc>
}
f0100753:	c9                   	leave  
f0100754:	c3                   	ret    

f0100755 <getchar>:

int
getchar(void)
{
f0100755:	55                   	push   %ebp
f0100756:	89 e5                	mov    %esp,%ebp
f0100758:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010075b:	e8 85 fe ff ff       	call   f01005e5 <cons_getc>
f0100760:	85 c0                	test   %eax,%eax
f0100762:	74 f7                	je     f010075b <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100764:	c9                   	leave  
f0100765:	c3                   	ret    

f0100766 <iscons>:

int
iscons(int fdnum)
{
f0100766:	55                   	push   %ebp
f0100767:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100769:	b8 01 00 00 00       	mov    $0x1,%eax
f010076e:	5d                   	pop    %ebp
f010076f:	c3                   	ret    

f0100770 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100770:	55                   	push   %ebp
f0100771:	89 e5                	mov    %esp,%ebp
f0100773:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100776:	68 c0 63 10 f0       	push   $0xf01063c0
f010077b:	68 de 63 10 f0       	push   $0xf01063de
f0100780:	68 e3 63 10 f0       	push   $0xf01063e3
f0100785:	e8 c7 30 00 00       	call   f0103851 <cprintf>
f010078a:	83 c4 0c             	add    $0xc,%esp
f010078d:	68 84 64 10 f0       	push   $0xf0106484
f0100792:	68 ec 63 10 f0       	push   $0xf01063ec
f0100797:	68 e3 63 10 f0       	push   $0xf01063e3
f010079c:	e8 b0 30 00 00       	call   f0103851 <cprintf>
f01007a1:	83 c4 0c             	add    $0xc,%esp
f01007a4:	68 f5 63 10 f0       	push   $0xf01063f5
f01007a9:	68 12 64 10 f0       	push   $0xf0106412
f01007ae:	68 e3 63 10 f0       	push   $0xf01063e3
f01007b3:	e8 99 30 00 00       	call   f0103851 <cprintf>
	return 0;
}
f01007b8:	b8 00 00 00 00       	mov    $0x0,%eax
f01007bd:	c9                   	leave  
f01007be:	c3                   	ret    

f01007bf <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007bf:	55                   	push   %ebp
f01007c0:	89 e5                	mov    %esp,%ebp
f01007c2:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007c5:	68 1d 64 10 f0       	push   $0xf010641d
f01007ca:	e8 82 30 00 00       	call   f0103851 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007cf:	83 c4 08             	add    $0x8,%esp
f01007d2:	68 0c 00 10 00       	push   $0x10000c
f01007d7:	68 ac 64 10 f0       	push   $0xf01064ac
f01007dc:	e8 70 30 00 00       	call   f0103851 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007e1:	83 c4 0c             	add    $0xc,%esp
f01007e4:	68 0c 00 10 00       	push   $0x10000c
f01007e9:	68 0c 00 10 f0       	push   $0xf010000c
f01007ee:	68 d4 64 10 f0       	push   $0xf01064d4
f01007f3:	e8 59 30 00 00       	call   f0103851 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007f8:	83 c4 0c             	add    $0xc,%esp
f01007fb:	68 65 60 10 00       	push   $0x106065
f0100800:	68 65 60 10 f0       	push   $0xf0106065
f0100805:	68 f8 64 10 f0       	push   $0xf01064f8
f010080a:	e8 42 30 00 00       	call   f0103851 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010080f:	83 c4 0c             	add    $0xc,%esp
f0100812:	68 28 f0 22 00       	push   $0x22f028
f0100817:	68 28 f0 22 f0       	push   $0xf022f028
f010081c:	68 1c 65 10 f0       	push   $0xf010651c
f0100821:	e8 2b 30 00 00       	call   f0103851 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100826:	83 c4 0c             	add    $0xc,%esp
f0100829:	68 08 20 27 00       	push   $0x272008
f010082e:	68 08 20 27 f0       	push   $0xf0272008
f0100833:	68 40 65 10 f0       	push   $0xf0106540
f0100838:	e8 14 30 00 00       	call   f0103851 <cprintf>
f010083d:	b8 07 24 27 f0       	mov    $0xf0272407,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100842:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100847:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f010084a:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010084f:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100855:	85 c0                	test   %eax,%eax
f0100857:	0f 48 c2             	cmovs  %edx,%eax
f010085a:	c1 f8 0a             	sar    $0xa,%eax
f010085d:	50                   	push   %eax
f010085e:	68 64 65 10 f0       	push   $0xf0106564
f0100863:	e8 e9 2f 00 00       	call   f0103851 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100868:	b8 00 00 00 00       	mov    $0x0,%eax
f010086d:	c9                   	leave  
f010086e:	c3                   	ret    

f010086f <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010086f:	55                   	push   %ebp
f0100870:	89 e5                	mov    %esp,%ebp
f0100872:	57                   	push   %edi
f0100873:	56                   	push   %esi
f0100874:	53                   	push   %ebx
f0100875:	83 ec 38             	sub    $0x38,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100878:	89 eb                	mov    %ebp,%ebx
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
f010087a:	68 36 64 10 f0       	push   $0xf0106436
f010087f:	e8 cd 2f 00 00       	call   f0103851 <cprintf>
	
	
	while (ebp){
f0100884:	83 c4 10             	add    $0x10,%esp
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
		debuginfo_eip(eip, &sym);
f0100887:	8d 7d d0             	lea    -0x30(%ebp),%edi
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f010088a:	eb 41                	jmp    f01008cd <mon_backtrace+0x5e>
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
f010088c:	8b 73 04             	mov    0x4(%ebx),%esi
		debuginfo_eip(eip, &sym);
f010088f:	83 ec 08             	sub    $0x8,%esp
f0100892:	57                   	push   %edi
f0100893:	56                   	push   %esi
f0100894:	e8 91 40 00 00       	call   f010492a <debuginfo_eip>
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n %s:%d: %.*s+%d\n",ebp,eip,
f0100899:	89 f0                	mov    %esi,%eax
f010089b:	2b 45 e0             	sub    -0x20(%ebp),%eax
f010089e:	89 04 24             	mov    %eax,(%esp)
f01008a1:	ff 75 d8             	pushl  -0x28(%ebp)
f01008a4:	ff 75 dc             	pushl  -0x24(%ebp)
f01008a7:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008aa:	ff 75 d0             	pushl  -0x30(%ebp)
f01008ad:	ff 73 18             	pushl  0x18(%ebx)
f01008b0:	ff 73 14             	pushl  0x14(%ebx)
f01008b3:	ff 73 10             	pushl  0x10(%ebx)
f01008b6:	ff 73 0c             	pushl  0xc(%ebx)
f01008b9:	ff 73 08             	pushl  0x8(%ebx)
f01008bc:	56                   	push   %esi
f01008bd:	53                   	push   %ebx
f01008be:	68 90 65 10 f0       	push   $0xf0106590
f01008c3:	e8 89 2f 00 00       	call   f0103851 <cprintf>
		*((uint32_t *)ebp + 6), sym.eip_file,
			      sym.eip_line,
			      sym.eip_fn_namelen,
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
f01008c8:	8b 1b                	mov    (%ebx),%ebx
f01008ca:	83 c4 40             	add    $0x40,%esp
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f01008cd:	85 db                	test   %ebx,%ebx
f01008cf:	75 bb                	jne    f010088c <mon_backtrace+0x1d>
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
	}
	return 0;
}
f01008d1:	b8 00 00 00 00       	mov    $0x0,%eax
f01008d6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008d9:	5b                   	pop    %ebx
f01008da:	5e                   	pop    %esi
f01008db:	5f                   	pop    %edi
f01008dc:	5d                   	pop    %ebp
f01008dd:	c3                   	ret    

f01008de <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01008de:	55                   	push   %ebp
f01008df:	89 e5                	mov    %esp,%ebp
f01008e1:	57                   	push   %edi
f01008e2:	56                   	push   %esi
f01008e3:	53                   	push   %ebx
f01008e4:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01008e7:	68 d4 65 10 f0       	push   $0xf01065d4
f01008ec:	e8 60 2f 00 00       	call   f0103851 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008f1:	c7 04 24 f8 65 10 f0 	movl   $0xf01065f8,(%esp)
f01008f8:	e8 54 2f 00 00       	call   f0103851 <cprintf>

	if (tf != NULL)
f01008fd:	83 c4 10             	add    $0x10,%esp
f0100900:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100904:	74 0e                	je     f0100914 <monitor+0x36>
		print_trapframe(tf);
f0100906:	83 ec 0c             	sub    $0xc,%esp
f0100909:	ff 75 08             	pushl  0x8(%ebp)
f010090c:	e8 5c 31 00 00       	call   f0103a6d <print_trapframe>
f0100911:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100914:	83 ec 0c             	sub    $0xc,%esp
f0100917:	68 48 64 10 f0       	push   $0xf0106448
f010091c:	e8 30 48 00 00       	call   f0105151 <readline>
f0100921:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100923:	83 c4 10             	add    $0x10,%esp
f0100926:	85 c0                	test   %eax,%eax
f0100928:	74 ea                	je     f0100914 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010092a:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100931:	be 00 00 00 00       	mov    $0x0,%esi
f0100936:	eb 0a                	jmp    f0100942 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100938:	c6 03 00             	movb   $0x0,(%ebx)
f010093b:	89 f7                	mov    %esi,%edi
f010093d:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100940:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100942:	0f b6 03             	movzbl (%ebx),%eax
f0100945:	84 c0                	test   %al,%al
f0100947:	74 63                	je     f01009ac <monitor+0xce>
f0100949:	83 ec 08             	sub    $0x8,%esp
f010094c:	0f be c0             	movsbl %al,%eax
f010094f:	50                   	push   %eax
f0100950:	68 4c 64 10 f0       	push   $0xf010644c
f0100955:	e8 11 4a 00 00       	call   f010536b <strchr>
f010095a:	83 c4 10             	add    $0x10,%esp
f010095d:	85 c0                	test   %eax,%eax
f010095f:	75 d7                	jne    f0100938 <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f0100961:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100964:	74 46                	je     f01009ac <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100966:	83 fe 0f             	cmp    $0xf,%esi
f0100969:	75 14                	jne    f010097f <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010096b:	83 ec 08             	sub    $0x8,%esp
f010096e:	6a 10                	push   $0x10
f0100970:	68 51 64 10 f0       	push   $0xf0106451
f0100975:	e8 d7 2e 00 00       	call   f0103851 <cprintf>
f010097a:	83 c4 10             	add    $0x10,%esp
f010097d:	eb 95                	jmp    f0100914 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f010097f:	8d 7e 01             	lea    0x1(%esi),%edi
f0100982:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100986:	eb 03                	jmp    f010098b <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100988:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010098b:	0f b6 03             	movzbl (%ebx),%eax
f010098e:	84 c0                	test   %al,%al
f0100990:	74 ae                	je     f0100940 <monitor+0x62>
f0100992:	83 ec 08             	sub    $0x8,%esp
f0100995:	0f be c0             	movsbl %al,%eax
f0100998:	50                   	push   %eax
f0100999:	68 4c 64 10 f0       	push   $0xf010644c
f010099e:	e8 c8 49 00 00       	call   f010536b <strchr>
f01009a3:	83 c4 10             	add    $0x10,%esp
f01009a6:	85 c0                	test   %eax,%eax
f01009a8:	74 de                	je     f0100988 <monitor+0xaa>
f01009aa:	eb 94                	jmp    f0100940 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f01009ac:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01009b3:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01009b4:	85 f6                	test   %esi,%esi
f01009b6:	0f 84 58 ff ff ff    	je     f0100914 <monitor+0x36>
f01009bc:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01009c1:	83 ec 08             	sub    $0x8,%esp
f01009c4:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009c7:	ff 34 85 20 66 10 f0 	pushl  -0xfef99e0(,%eax,4)
f01009ce:	ff 75 a8             	pushl  -0x58(%ebp)
f01009d1:	e8 37 49 00 00       	call   f010530d <strcmp>
f01009d6:	83 c4 10             	add    $0x10,%esp
f01009d9:	85 c0                	test   %eax,%eax
f01009db:	75 22                	jne    f01009ff <monitor+0x121>
			return commands[i].func(argc, argv, tf);
f01009dd:	83 ec 04             	sub    $0x4,%esp
f01009e0:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009e3:	ff 75 08             	pushl  0x8(%ebp)
f01009e6:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01009e9:	52                   	push   %edx
f01009ea:	56                   	push   %esi
f01009eb:	ff 14 85 28 66 10 f0 	call   *-0xfef99d8(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01009f2:	83 c4 10             	add    $0x10,%esp
f01009f5:	85 c0                	test   %eax,%eax
f01009f7:	0f 89 17 ff ff ff    	jns    f0100914 <monitor+0x36>
f01009fd:	eb 20                	jmp    f0100a1f <monitor+0x141>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01009ff:	83 c3 01             	add    $0x1,%ebx
f0100a02:	83 fb 03             	cmp    $0x3,%ebx
f0100a05:	75 ba                	jne    f01009c1 <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a07:	83 ec 08             	sub    $0x8,%esp
f0100a0a:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a0d:	68 6e 64 10 f0       	push   $0xf010646e
f0100a12:	e8 3a 2e 00 00       	call   f0103851 <cprintf>
f0100a17:	83 c4 10             	add    $0x10,%esp
f0100a1a:	e9 f5 fe ff ff       	jmp    f0100914 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a1f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a22:	5b                   	pop    %ebx
f0100a23:	5e                   	pop    %esi
f0100a24:	5f                   	pop    %edi
f0100a25:	5d                   	pop    %ebp
f0100a26:	c3                   	ret    

f0100a27 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100a27:	89 d1                	mov    %edx,%ecx
f0100a29:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100a2c:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100a2f:	a8 01                	test   $0x1,%al
f0100a31:	74 52                	je     f0100a85 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a33:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a38:	89 c1                	mov    %eax,%ecx
f0100a3a:	c1 e9 0c             	shr    $0xc,%ecx
f0100a3d:	3b 0d c8 0e 23 f0    	cmp    0xf0230ec8,%ecx
f0100a43:	72 1b                	jb     f0100a60 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a45:	55                   	push   %ebp
f0100a46:	89 e5                	mov    %esp,%ebp
f0100a48:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a4b:	50                   	push   %eax
f0100a4c:	68 a4 60 10 f0       	push   $0xf01060a4
f0100a51:	68 10 04 00 00       	push   $0x410
f0100a56:	68 35 70 10 f0       	push   $0xf0107035
f0100a5b:	e8 e0 f5 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100a60:	c1 ea 0c             	shr    $0xc,%edx
f0100a63:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a69:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a70:	89 c2                	mov    %eax,%edx
f0100a72:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a75:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a7a:	85 d2                	test   %edx,%edx
f0100a7c:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a81:	0f 44 c2             	cmove  %edx,%eax
f0100a84:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100a85:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100a8a:	c3                   	ret    

f0100a8b <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100a8b:	83 3d 5c 02 23 f0 00 	cmpl   $0x0,0xf023025c
f0100a92:	75 11                	jne    f0100aa5 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE); // Roundup function rounds according to the given functions
f0100a94:	ba 07 30 27 f0       	mov    $0xf0273007,%edx
f0100a99:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a9f:	89 15 5c 02 23 f0    	mov    %edx,0xf023025c
	}
	
	if (n==0){
f0100aa5:	85 c0                	test   %eax,%eax
f0100aa7:	75 06                	jne    f0100aaf <boot_alloc+0x24>
	return nextfree;
f0100aa9:	a1 5c 02 23 f0       	mov    0xf023025c,%eax
f0100aae:	c3                   	ret    
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result  = nextfree;
f0100aaf:	8b 0d 5c 02 23 f0    	mov    0xf023025c,%ecx
	nextfree += ROUNDUP(n,PGSIZE);
f0100ab5:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100aba:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100abf:	8d 14 01             	lea    (%ecx,%eax,1),%edx
f0100ac2:	89 15 5c 02 23 f0    	mov    %edx,0xf023025c
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100ac8:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0100ace:	77 18                	ja     f0100ae8 <boot_alloc+0x5d>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100ad0:	55                   	push   %ebp
f0100ad1:	89 e5                	mov    %esp,%ebp
f0100ad3:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100ad6:	52                   	push   %edx
f0100ad7:	68 c8 60 10 f0       	push   $0xf01060c8
f0100adc:	6a 71                	push   $0x71
f0100ade:	68 35 70 10 f0       	push   $0xf0107035
f0100ae3:	e8 58 f5 ff ff       	call   f0100040 <_panic>
	// LAB 2: Your code here.
	result  = nextfree;
	nextfree += ROUNDUP(n,PGSIZE);
	
	
	if ((PADDR(nextfree))>npages*PGSIZE){
f0100ae8:	a1 c8 0e 23 f0       	mov    0xf0230ec8,%eax
f0100aed:	c1 e0 0c             	shl    $0xc,%eax
	return (physaddr_t)kva - KERNBASE;
f0100af0:	81 c2 00 00 00 10    	add    $0x10000000,%edx
		return 0;
	}
	return result;
f0100af6:	39 c2                	cmp    %eax,%edx
f0100af8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100afd:	0f 46 c1             	cmovbe %ecx,%eax
}
f0100b00:	c3                   	ret    

f0100b01 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100b01:	55                   	push   %ebp
f0100b02:	89 e5                	mov    %esp,%ebp
f0100b04:	57                   	push   %edi
f0100b05:	56                   	push   %esi
f0100b06:	53                   	push   %ebx
f0100b07:	83 ec 3c             	sub    $0x3c,%esp
f0100b0a:	89 45 c0             	mov    %eax,-0x40(%ebp)
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b0d:	84 c0                	test   %al,%al
f0100b0f:	0f 85 af 02 00 00    	jne    f0100dc4 <check_page_free_list+0x2c3>
f0100b15:	e9 bc 02 00 00       	jmp    f0100dd6 <check_page_free_list+0x2d5>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100b1a:	83 ec 04             	sub    $0x4,%esp
f0100b1d:	68 44 66 10 f0       	push   $0xf0106644
f0100b22:	68 44 03 00 00       	push   $0x344
f0100b27:	68 35 70 10 f0       	push   $0xf0107035
f0100b2c:	e8 0f f5 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100b31:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100b34:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100b37:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b3a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b3d:	89 c2                	mov    %eax,%edx
f0100b3f:	2b 15 d0 0e 23 f0    	sub    0xf0230ed0,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100b45:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100b4b:	0f 95 c2             	setne  %dl
f0100b4e:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100b51:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100b55:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100b57:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b5b:	8b 00                	mov    (%eax),%eax
f0100b5d:	85 c0                	test   %eax,%eax
f0100b5f:	75 dc                	jne    f0100b3d <check_page_free_list+0x3c>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100b61:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b64:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100b6a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b6d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100b70:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100b72:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100b75:	a3 64 02 23 f0       	mov    %eax,0xf0230264
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b7a:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b7f:	8b 1d 64 02 23 f0    	mov    0xf0230264,%ebx
f0100b85:	eb 53                	jmp    f0100bda <check_page_free_list+0xd9>
f0100b87:	89 d8                	mov    %ebx,%eax
f0100b89:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f0100b8f:	c1 f8 03             	sar    $0x3,%eax
f0100b92:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b95:	89 c2                	mov    %eax,%edx
f0100b97:	c1 ea 16             	shr    $0x16,%edx
f0100b9a:	39 f2                	cmp    %esi,%edx
f0100b9c:	73 3a                	jae    f0100bd8 <check_page_free_list+0xd7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b9e:	89 c2                	mov    %eax,%edx
f0100ba0:	c1 ea 0c             	shr    $0xc,%edx
f0100ba3:	3b 15 c8 0e 23 f0    	cmp    0xf0230ec8,%edx
f0100ba9:	72 12                	jb     f0100bbd <check_page_free_list+0xbc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bab:	50                   	push   %eax
f0100bac:	68 a4 60 10 f0       	push   $0xf01060a4
f0100bb1:	6a 58                	push   $0x58
f0100bb3:	68 41 70 10 f0       	push   $0xf0107041
f0100bb8:	e8 83 f4 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100bbd:	83 ec 04             	sub    $0x4,%esp
f0100bc0:	68 80 00 00 00       	push   $0x80
f0100bc5:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100bca:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bcf:	50                   	push   %eax
f0100bd0:	e8 d3 47 00 00       	call   f01053a8 <memset>
f0100bd5:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bd8:	8b 1b                	mov    (%ebx),%ebx
f0100bda:	85 db                	test   %ebx,%ebx
f0100bdc:	75 a9                	jne    f0100b87 <check_page_free_list+0x86>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100bde:	b8 00 00 00 00       	mov    $0x0,%eax
f0100be3:	e8 a3 fe ff ff       	call   f0100a8b <boot_alloc>
f0100be8:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100beb:	8b 15 64 02 23 f0    	mov    0xf0230264,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bf1:	8b 0d d0 0e 23 f0    	mov    0xf0230ed0,%ecx
		assert(pp < pages + npages);
f0100bf7:	a1 c8 0e 23 f0       	mov    0xf0230ec8,%eax
f0100bfc:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100bff:	8d 34 c1             	lea    (%ecx,%eax,8),%esi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c02:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c05:	bf 00 00 00 00       	mov    $0x0,%edi
f0100c0a:	89 5d cc             	mov    %ebx,-0x34(%ebp)
f0100c0d:	89 f0                	mov    %esi,%eax
f0100c0f:	89 ce                	mov    %ecx,%esi
f0100c11:	89 c1                	mov    %eax,%ecx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c13:	e9 55 01 00 00       	jmp    f0100d6d <check_page_free_list+0x26c>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c18:	39 f2                	cmp    %esi,%edx
f0100c1a:	73 19                	jae    f0100c35 <check_page_free_list+0x134>
f0100c1c:	68 4f 70 10 f0       	push   $0xf010704f
f0100c21:	68 5b 70 10 f0       	push   $0xf010705b
f0100c26:	68 5e 03 00 00       	push   $0x35e
f0100c2b:	68 35 70 10 f0       	push   $0xf0107035
f0100c30:	e8 0b f4 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100c35:	39 ca                	cmp    %ecx,%edx
f0100c37:	72 19                	jb     f0100c52 <check_page_free_list+0x151>
f0100c39:	68 70 70 10 f0       	push   $0xf0107070
f0100c3e:	68 5b 70 10 f0       	push   $0xf010705b
f0100c43:	68 5f 03 00 00       	push   $0x35f
f0100c48:	68 35 70 10 f0       	push   $0xf0107035
f0100c4d:	e8 ee f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c52:	89 d0                	mov    %edx,%eax
f0100c54:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100c57:	a8 07                	test   $0x7,%al
f0100c59:	74 19                	je     f0100c74 <check_page_free_list+0x173>
f0100c5b:	68 68 66 10 f0       	push   $0xf0106668
f0100c60:	68 5b 70 10 f0       	push   $0xf010705b
f0100c65:	68 60 03 00 00       	push   $0x360
f0100c6a:	68 35 70 10 f0       	push   $0xf0107035
f0100c6f:	e8 cc f3 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c74:	c1 f8 03             	sar    $0x3,%eax
f0100c77:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c7a:	85 c0                	test   %eax,%eax
f0100c7c:	75 19                	jne    f0100c97 <check_page_free_list+0x196>
f0100c7e:	68 84 70 10 f0       	push   $0xf0107084
f0100c83:	68 5b 70 10 f0       	push   $0xf010705b
f0100c88:	68 63 03 00 00       	push   $0x363
f0100c8d:	68 35 70 10 f0       	push   $0xf0107035
f0100c92:	e8 a9 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c97:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c9c:	75 19                	jne    f0100cb7 <check_page_free_list+0x1b6>
f0100c9e:	68 95 70 10 f0       	push   $0xf0107095
f0100ca3:	68 5b 70 10 f0       	push   $0xf010705b
f0100ca8:	68 64 03 00 00       	push   $0x364
f0100cad:	68 35 70 10 f0       	push   $0xf0107035
f0100cb2:	e8 89 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cb7:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100cbc:	75 19                	jne    f0100cd7 <check_page_free_list+0x1d6>
f0100cbe:	68 9c 66 10 f0       	push   $0xf010669c
f0100cc3:	68 5b 70 10 f0       	push   $0xf010705b
f0100cc8:	68 65 03 00 00       	push   $0x365
f0100ccd:	68 35 70 10 f0       	push   $0xf0107035
f0100cd2:	e8 69 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cd7:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cdc:	75 19                	jne    f0100cf7 <check_page_free_list+0x1f6>
f0100cde:	68 ae 70 10 f0       	push   $0xf01070ae
f0100ce3:	68 5b 70 10 f0       	push   $0xf010705b
f0100ce8:	68 66 03 00 00       	push   $0x366
f0100ced:	68 35 70 10 f0       	push   $0xf0107035
f0100cf2:	e8 49 f3 ff ff       	call   f0100040 <_panic>
f0100cf7:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cfa:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100cff:	0f 86 e8 00 00 00    	jbe    f0100ded <check_page_free_list+0x2ec>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d05:	89 c3                	mov    %eax,%ebx
f0100d07:	c1 eb 0c             	shr    $0xc,%ebx
f0100d0a:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f0100d0d:	77 12                	ja     f0100d21 <check_page_free_list+0x220>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d0f:	50                   	push   %eax
f0100d10:	68 a4 60 10 f0       	push   $0xf01060a4
f0100d15:	6a 58                	push   $0x58
f0100d17:	68 41 70 10 f0       	push   $0xf0107041
f0100d1c:	e8 1f f3 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100d21:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
f0100d27:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100d2a:	0f 86 cd 00 00 00    	jbe    f0100dfd <check_page_free_list+0x2fc>
f0100d30:	68 c0 66 10 f0       	push   $0xf01066c0
f0100d35:	68 5b 70 10 f0       	push   $0xf010705b
f0100d3a:	68 67 03 00 00       	push   $0x367
f0100d3f:	68 35 70 10 f0       	push   $0xf0107035
f0100d44:	e8 f7 f2 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100d49:	68 c8 70 10 f0       	push   $0xf01070c8
f0100d4e:	68 5b 70 10 f0       	push   $0xf010705b
f0100d53:	68 69 03 00 00       	push   $0x369
f0100d58:	68 35 70 10 f0       	push   $0xf0107035
f0100d5d:	e8 de f2 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d62:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0100d66:	eb 03                	jmp    f0100d6b <check_page_free_list+0x26a>
		else
			++nfree_extmem;
f0100d68:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d6b:	8b 12                	mov    (%edx),%edx
f0100d6d:	85 d2                	test   %edx,%edx
f0100d6f:	0f 85 a3 fe ff ff    	jne    f0100c18 <check_page_free_list+0x117>
f0100d75:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d78:	85 db                	test   %ebx,%ebx
f0100d7a:	7f 19                	jg     f0100d95 <check_page_free_list+0x294>
f0100d7c:	68 e5 70 10 f0       	push   $0xf01070e5
f0100d81:	68 5b 70 10 f0       	push   $0xf010705b
f0100d86:	68 71 03 00 00       	push   $0x371
f0100d8b:	68 35 70 10 f0       	push   $0xf0107035
f0100d90:	e8 ab f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100d95:	85 ff                	test   %edi,%edi
f0100d97:	7f 19                	jg     f0100db2 <check_page_free_list+0x2b1>
f0100d99:	68 f7 70 10 f0       	push   $0xf01070f7
f0100d9e:	68 5b 70 10 f0       	push   $0xf010705b
f0100da3:	68 72 03 00 00       	push   $0x372
f0100da8:	68 35 70 10 f0       	push   $0xf0107035
f0100dad:	e8 8e f2 ff ff       	call   f0100040 <_panic>
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
f0100db2:	83 ec 08             	sub    $0x8,%esp
f0100db5:	ff 75 c0             	pushl  -0x40(%ebp)
f0100db8:	68 08 67 10 f0       	push   $0xf0106708
f0100dbd:	e8 8f 2a 00 00       	call   f0103851 <cprintf>
f0100dc2:	eb 49                	jmp    f0100e0d <check_page_free_list+0x30c>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100dc4:	a1 64 02 23 f0       	mov    0xf0230264,%eax
f0100dc9:	85 c0                	test   %eax,%eax
f0100dcb:	0f 85 60 fd ff ff    	jne    f0100b31 <check_page_free_list+0x30>
f0100dd1:	e9 44 fd ff ff       	jmp    f0100b1a <check_page_free_list+0x19>
f0100dd6:	83 3d 64 02 23 f0 00 	cmpl   $0x0,0xf0230264
f0100ddd:	0f 84 37 fd ff ff    	je     f0100b1a <check_page_free_list+0x19>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100de3:	be 00 04 00 00       	mov    $0x400,%esi
f0100de8:	e9 92 fd ff ff       	jmp    f0100b7f <check_page_free_list+0x7e>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100ded:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100df2:	0f 85 6a ff ff ff    	jne    f0100d62 <check_page_free_list+0x261>
f0100df8:	e9 4c ff ff ff       	jmp    f0100d49 <check_page_free_list+0x248>
f0100dfd:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e02:	0f 85 60 ff ff ff    	jne    f0100d68 <check_page_free_list+0x267>
f0100e08:	e9 3c ff ff ff       	jmp    f0100d49 <check_page_free_list+0x248>
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
}
f0100e0d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e10:	5b                   	pop    %ebx
f0100e11:	5e                   	pop    %esi
f0100e12:	5f                   	pop    %edi
f0100e13:	5d                   	pop    %ebp
f0100e14:	c3                   	ret    

f0100e15 <page_init>:
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100e15:	b8 01 00 00 00       	mov    $0x1,%eax
f0100e1a:	eb 18                	jmp    f0100e34 <page_init+0x1f>
	{
	 pages[i].pp_ref = 1; //Used Pages
f0100e1c:	8b 15 d0 0e 23 f0    	mov    0xf0230ed0,%edx
f0100e22:	8d 14 c2             	lea    (%edx,%eax,8),%edx
f0100e25:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
	 pages[i].pp_link = 0; // No links to any pages
f0100e2b:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100e31:	83 c0 01             	add    $0x1,%eax
f0100e34:	3b 05 c8 0e 23 f0    	cmp    0xf0230ec8,%eax
f0100e3a:	72 e0                	jb     f0100e1c <page_init+0x7>
//


void
page_init(void)
{
f0100e3c:	55                   	push   %ebp
f0100e3d:	89 e5                	mov    %esp,%ebp
f0100e3f:	57                   	push   %edi
f0100e40:	56                   	push   %esi
f0100e41:	53                   	push   %ebx
f0100e42:	83 ec 0c             	sub    $0xc,%esp
	//Modification for Lab 4, We have to skip the Page that MPENTRY_PADDR is at from the page_free_list
	//Hence we can divide it with PGSIZE and whatever is the value, just skip that page. 
	size_t mpentyPg = MPENTRY_PADDR/PGSIZE;

	// 2. The rest of base memory 
	page_free_list = 0 ;
f0100e45:	c7 05 64 02 23 f0 00 	movl   $0x0,0xf0230264
f0100e4c:	00 00 00 
	
	struct PageInfo *prev = 0;
	for (i = 1; i < npages_basemem; ++i) {
f0100e4f:	be 00 00 00 00       	mov    $0x0,%esi
	size_t mpentyPg = MPENTRY_PADDR/PGSIZE;

	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	struct PageInfo *prev = 0;
f0100e54:	bf 00 00 00 00       	mov    $0x0,%edi
	for (i = 1; i < npages_basemem; ++i) {
f0100e59:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100e5e:	eb 71                	jmp    f0100ed1 <page_init+0xbc>
		if (i == mpentyPg) {
f0100e60:	83 fb 07             	cmp    $0x7,%ebx
f0100e63:	75 14                	jne    f0100e79 <page_init+0x64>
			cprintf("Skipped this page %d\n", i);
f0100e65:	83 ec 08             	sub    $0x8,%esp
f0100e68:	6a 07                	push   $0x7
f0100e6a:	68 08 71 10 f0       	push   $0xf0107108
f0100e6f:	e8 dd 29 00 00       	call   f0103851 <cprintf>
			continue;	
f0100e74:	83 c4 10             	add    $0x10,%esp
f0100e77:	eb 52                	jmp    f0100ecb <page_init+0xb6>
f0100e79:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
		}

		pages[i].pp_ref = 0;
f0100e80:	8b 15 d0 0e 23 f0    	mov    0xf0230ed0,%edx
f0100e86:	66 c7 44 02 04 00 00 	movw   $0x0,0x4(%edx,%eax,1)
		pages[i].pp_link = 0;
f0100e8d:	c7 04 da 00 00 00 00 	movl   $0x0,(%edx,%ebx,8)
		if (!page_free_list) {
f0100e94:	83 3d 64 02 23 f0 00 	cmpl   $0x0,0xf0230264
f0100e9b:	75 10                	jne    f0100ead <page_init+0x98>
			page_free_list = &pages[i];
f0100e9d:	89 c2                	mov    %eax,%edx
f0100e9f:	03 15 d0 0e 23 f0    	add    0xf0230ed0,%edx
f0100ea5:	89 15 64 02 23 f0    	mov    %edx,0xf0230264
f0100eab:	eb 16                	jmp    f0100ec3 <page_init+0xae>
		} else {
			prev->pp_link = &pages[i];
f0100ead:	89 c2                	mov    %eax,%edx
f0100eaf:	03 15 d0 0e 23 f0    	add    0xf0230ed0,%edx
f0100eb5:	89 17                	mov    %edx,(%edi)
			pages[i-1].pp_link = &pages[i];
f0100eb7:	8b 15 d0 0e 23 f0    	mov    0xf0230ed0,%edx
f0100ebd:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
f0100ec0:	89 0c 32             	mov    %ecx,(%edx,%esi,1)
		}
		prev = &pages[i];
f0100ec3:	03 05 d0 0e 23 f0    	add    0xf0230ed0,%eax
f0100ec9:	89 c7                	mov    %eax,%edi

	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	struct PageInfo *prev = 0;
	for (i = 1; i < npages_basemem; ++i) {
f0100ecb:	83 c3 01             	add    $0x1,%ebx
f0100ece:	83 c6 08             	add    $0x8,%esi
f0100ed1:	3b 1d 68 02 23 f0    	cmp    0xf0230268,%ebx
f0100ed7:	72 87                	jb     f0100e60 <page_init+0x4b>
		prev = &pages[i];
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
f0100ed9:	a1 d0 0e 23 f0       	mov    0xf0230ed0,%eax
f0100ede:	8d 44 d8 f8          	lea    -0x8(%eax,%ebx,8),%eax
f0100ee2:	a3 58 02 23 f0       	mov    %eax,0xf0230258
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100ee7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100eec:	e8 9a fb ff ff       	call   f0100a8b <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100ef1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100ef6:	77 15                	ja     f0100f0d <page_init+0xf8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100ef8:	50                   	push   %eax
f0100ef9:	68 c8 60 10 f0       	push   $0xf01060c8
f0100efe:	68 75 01 00 00       	push   $0x175
f0100f03:	68 35 70 10 f0       	push   $0xf0107035
f0100f08:	e8 33 f1 ff ff       	call   f0100040 <_panic>
f0100f0d:	05 ff 0f 00 10       	add    $0x10000fff,%eax
f0100f12:	c1 e8 0c             	shr    $0xc,%eax
f0100f15:	8b 1d 58 02 23 f0    	mov    0xf0230258,%ebx
f0100f1b:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100f22:	eb 2c                	jmp    f0100f50 <page_init+0x13b>
		pages[i].pp_ref = 0;
f0100f24:	89 d1                	mov    %edx,%ecx
f0100f26:	03 0d d0 0e 23 f0    	add    0xf0230ed0,%ecx
f0100f2c:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = 0;
f0100f32:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		track->pp_link = &pages[i];
f0100f38:	89 d1                	mov    %edx,%ecx
f0100f3a:	03 0d d0 0e 23 f0    	add    0xf0230ed0,%ecx
f0100f40:	89 0b                	mov    %ecx,(%ebx)
		track = &pages[i];
f0100f42:	89 d3                	mov    %edx,%ebx
f0100f44:	03 1d d0 0e 23 f0    	add    0xf0230ed0,%ebx
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100f4a:	83 c0 01             	add    $0x1,%eax
f0100f4d:	83 c2 08             	add    $0x8,%edx
f0100f50:	3b 05 c8 0e 23 f0    	cmp    0xf0230ec8,%eax
f0100f56:	72 cc                	jb     f0100f24 <page_init+0x10f>
f0100f58:	89 1d 58 02 23 f0    	mov    %ebx,0xf0230258
		pages[i].pp_link = 0;
		track->pp_link = &pages[i];
		track = &pages[i];
	}
	
	cprintf("Check first entry of pages &pages[0] = %x\n", &pages[0]);
f0100f5e:	83 ec 08             	sub    $0x8,%esp
f0100f61:	ff 35 d0 0e 23 f0    	pushl  0xf0230ed0
f0100f67:	68 30 67 10 f0       	push   $0xf0106730
f0100f6c:	e8 e0 28 00 00       	call   f0103851 <cprintf>
	cprintf("&pages[npages-1] = %x\n", &pages[npages-1]);
f0100f71:	83 c4 08             	add    $0x8,%esp
f0100f74:	a1 d0 0e 23 f0       	mov    0xf0230ed0,%eax
f0100f79:	8b 15 c8 0e 23 f0    	mov    0xf0230ec8,%edx
f0100f7f:	8d 44 d0 f8          	lea    -0x8(%eax,%edx,8),%eax
f0100f83:	50                   	push   %eax
f0100f84:	68 1e 71 10 f0       	push   $0xf010711e
f0100f89:	e8 c3 28 00 00       	call   f0103851 <cprintf>
f0100f8e:	83 c4 10             	add    $0x10,%esp
}
f0100f91:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f94:	5b                   	pop    %ebx
f0100f95:	5e                   	pop    %esi
f0100f96:	5f                   	pop    %edi
f0100f97:	5d                   	pop    %ebp
f0100f98:	c3                   	ret    

f0100f99 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100f99:	55                   	push   %ebp
f0100f9a:	89 e5                	mov    %esp,%ebp
f0100f9c:	53                   	push   %ebx
f0100f9d:	83 ec 04             	sub    $0x4,%esp
	// Check if there is a free_page available 
	if (!page_free_list)
f0100fa0:	8b 1d 64 02 23 f0    	mov    0xf0230264,%ebx
f0100fa6:	85 db                	test   %ebx,%ebx
f0100fa8:	74 5e                	je     f0101008 <page_alloc+0x6f>
	return NULL;
	}
	
	struct PageInfo *allocPage = NULL;   //Create a temporary pointer 
	allocPage = page_free_list;	//Point to the current head of free_page_list
	page_free_list = allocPage ->pp_link; //Move the head to the next avaialble page
f0100faa:	8b 03                	mov    (%ebx),%eax
f0100fac:	a3 64 02 23 f0       	mov    %eax,0xf0230264
	allocPage->pp_link = NULL;	//Break the link 
f0100fb1:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags && ALLOC_ZERO){		//ALLOC_ZERO = 1<<0; which is nothing but  = 1
f0100fb7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100fbb:	74 45                	je     f0101002 <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fbd:	89 d8                	mov    %ebx,%eax
f0100fbf:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f0100fc5:	c1 f8 03             	sar    $0x3,%eax
f0100fc8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fcb:	89 c2                	mov    %eax,%edx
f0100fcd:	c1 ea 0c             	shr    $0xc,%edx
f0100fd0:	3b 15 c8 0e 23 f0    	cmp    0xf0230ec8,%edx
f0100fd6:	72 12                	jb     f0100fea <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fd8:	50                   	push   %eax
f0100fd9:	68 a4 60 10 f0       	push   $0xf01060a4
f0100fde:	6a 58                	push   $0x58
f0100fe0:	68 41 70 10 f0       	push   $0xf0107041
f0100fe5:	e8 56 f0 ff ff       	call   f0100040 <_panic>
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
f0100fea:	83 ec 04             	sub    $0x4,%esp
f0100fed:	68 00 10 00 00       	push   $0x1000
f0100ff2:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0100ff4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ff9:	50                   	push   %eax
f0100ffa:	e8 a9 43 00 00       	call   f01053a8 <memset>
f0100fff:	83 c4 10             	add    $0x10,%esp
	}
	
	allocPage->pp_ref = 0;
f0101002:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return allocPage;
}
f0101008:	89 d8                	mov    %ebx,%eax
f010100a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010100d:	c9                   	leave  
f010100e:	c3                   	ret    

f010100f <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f010100f:	55                   	push   %ebp
f0101010:	89 e5                	mov    %esp,%ebp
f0101012:	83 ec 08             	sub    $0x8,%esp
f0101015:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	
	if(pp->pp_ref)
f0101018:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010101d:	74 17                	je     f0101036 <page_free+0x27>
	{
	panic("Page cannot be returned to free list, as it is still refernced ");
f010101f:	83 ec 04             	sub    $0x4,%esp
f0101022:	68 5c 67 10 f0       	push   $0xf010675c
f0101027:	68 ad 01 00 00       	push   $0x1ad
f010102c:	68 35 70 10 f0       	push   $0xf0107035
f0101031:	e8 0a f0 ff ff       	call   f0100040 <_panic>
	return;
	}
	
	// pp->pp_link is not NULL.
	else if(!pp) 
f0101036:	85 c0                	test   %eax,%eax
f0101038:	75 17                	jne    f0101051 <page_free+0x42>
	{
	panic("Page cannot be returned to free list as it is Null");
f010103a:	83 ec 04             	sub    $0x4,%esp
f010103d:	68 9c 67 10 f0       	push   $0xf010679c
f0101042:	68 b4 01 00 00       	push   $0x1b4
f0101047:	68 35 70 10 f0       	push   $0xf0107035
f010104c:	e8 ef ef ff ff       	call   f0100040 <_panic>
	return;
	}
	
       else{
	pp->pp_link = page_free_list;
f0101051:	8b 15 64 02 23 f0    	mov    0xf0230264,%edx
f0101057:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0101059:	a3 64 02 23 f0       	mov    %eax,0xf0230264
	}


}
f010105e:	c9                   	leave  
f010105f:	c3                   	ret    

f0101060 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101060:	55                   	push   %ebp
f0101061:	89 e5                	mov    %esp,%ebp
f0101063:	83 ec 08             	sub    $0x8,%esp
f0101066:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101069:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f010106d:	83 e8 01             	sub    $0x1,%eax
f0101070:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101074:	66 85 c0             	test   %ax,%ax
f0101077:	75 0c                	jne    f0101085 <page_decref+0x25>
		page_free(pp);
f0101079:	83 ec 0c             	sub    $0xc,%esp
f010107c:	52                   	push   %edx
f010107d:	e8 8d ff ff ff       	call   f010100f <page_free>
f0101082:	83 c4 10             	add    $0x10,%esp
}
f0101085:	c9                   	leave  
f0101086:	c3                   	ret    

f0101087 <pgdir_walk>:
// table and page directory entries.
//

pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101087:	55                   	push   %ebp
f0101088:	89 e5                	mov    %esp,%ebp
f010108a:	57                   	push   %edi
f010108b:	56                   	push   %esi
f010108c:	53                   	push   %ebx
f010108d:	83 ec 0c             	sub    $0xc,%esp
	pte_t *pgTab;  //Page Table index variable

	//To find the index from the pgdir we need to get the MS 10 bits,
	//We get the MS 10bits of the virtual address by using PDX function (found in inc/mmu.h ) 
	//#define PDX(la)		((((uintptr_t) (la)) >> PDXSHIFT) & 0x3FF)
	pgDir = &pgdir[PDX(va)];
f0101090:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101093:	c1 ee 16             	shr    $0x16,%esi
f0101096:	c1 e6 02             	shl    $0x2,%esi
f0101099:	03 75 08             	add    0x8(%ebp),%esi

	// Check if page is present, PTE_P = 0x1 means page present  
	if (*pgDir & PTE_P)  {
f010109c:	8b 1e                	mov    (%esi),%ebx
f010109e:	f6 c3 01             	test   $0x1,%bl
f01010a1:	74 30                	je     f01010d3 <pgdir_walk+0x4c>
		//page table entry to get to the final address translation. Now using the pgDir we can use the 
		//PTE_ADDR(pde) function to get the upper 20 bits, but this function returns a physical address. 
		//Since the kernel requires a virtual address, we can use the function KADDR to get the virtual 
		//address.
		
		pgTab = (pte_t*) KADDR(PTE_ADDR(*pgDir));
f01010a3:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010a9:	89 d8                	mov    %ebx,%eax
f01010ab:	c1 e8 0c             	shr    $0xc,%eax
f01010ae:	3b 05 c8 0e 23 f0    	cmp    0xf0230ec8,%eax
f01010b4:	72 15                	jb     f01010cb <pgdir_walk+0x44>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010b6:	53                   	push   %ebx
f01010b7:	68 a4 60 10 f0       	push   $0xf01060a4
f01010bc:	68 f5 01 00 00       	push   $0x1f5
f01010c1:	68 35 70 10 f0       	push   $0xf0107035
f01010c6:	e8 75 ef ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01010cb:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
f01010d1:	eb 7c                	jmp    f010114f <pgdir_walk+0xc8>
	//If page is not present 
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
f01010d3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01010d7:	0f 84 81 00 00 00    	je     f010115e <pgdir_walk+0xd7>
f01010dd:	83 ec 0c             	sub    $0xc,%esp
f01010e0:	68 00 10 00 00       	push   $0x1000
f01010e5:	e8 af fe ff ff       	call   f0100f99 <page_alloc>
f01010ea:	89 c7                	mov    %eax,%edi
f01010ec:	83 c4 10             	add    $0x10,%esp
f01010ef:	85 c0                	test   %eax,%eax
f01010f1:	74 72                	je     f0101165 <pgdir_walk+0xde>
			return 0;
		}

		newPage->pp_ref++;  //Increment the ref pointer of the page 
f01010f3:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01010f8:	89 c3                	mov    %eax,%ebx
f01010fa:	2b 1d d0 0e 23 f0    	sub    0xf0230ed0,%ebx
f0101100:	c1 fb 03             	sar    $0x3,%ebx
f0101103:	c1 e3 0c             	shl    $0xc,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101106:	89 d8                	mov    %ebx,%eax
f0101108:	c1 e8 0c             	shr    $0xc,%eax
f010110b:	3b 05 c8 0e 23 f0    	cmp    0xf0230ec8,%eax
f0101111:	72 12                	jb     f0101125 <pgdir_walk+0x9e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101113:	53                   	push   %ebx
f0101114:	68 a4 60 10 f0       	push   $0xf01060a4
f0101119:	6a 58                	push   $0x58
f010111b:	68 41 70 10 f0       	push   $0xf0107041
f0101120:	e8 1b ef ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101125:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
		//Now this section creates the bindings and updates all the flags 
		//for relevant use of the page.
		
		//First create a link on the pgTab wrt to the new page
		pgTab = (pte_t*)page2kva(newPage); // this function gets the virtual address of the new page
		memset (pgTab, 0, PGSIZE); //Clear the entire page
f010112b:	83 ec 04             	sub    $0x4,%esp
f010112e:	68 00 10 00 00       	push   $0x1000
f0101133:	6a 00                	push   $0x0
f0101135:	53                   	push   %ebx
f0101136:	e8 6d 42 00 00       	call   f01053a8 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010113b:	2b 3d d0 0e 23 f0    	sub    0xf0230ed0,%edi
f0101141:	c1 ff 03             	sar    $0x3,%edi
f0101144:	c1 e7 0c             	shl    $0xc,%edi

		//Page Table, pgTab contains the virtual address , now we need to set the permission bits.
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
f0101147:	83 cf 07             	or     $0x7,%edi
f010114a:	89 3e                	mov    %edi,(%esi)
f010114c:	83 c4 10             	add    $0x10,%esp
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
f010114f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101152:	c1 e8 0a             	shr    $0xa,%eax
f0101155:	25 fc 0f 00 00       	and    $0xffc,%eax
f010115a:	01 d8                	add    %ebx,%eax
f010115c:	eb 0c                	jmp    f010116a <pgdir_walk+0xe3>
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
			return 0;
f010115e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101163:	eb 05                	jmp    f010116a <pgdir_walk+0xe3>
f0101165:	b8 00 00 00 00       	mov    $0x0,%eax
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
}
f010116a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010116d:	5b                   	pop    %ebx
f010116e:	5e                   	pop    %esi
f010116f:	5f                   	pop    %edi
f0101170:	5d                   	pop    %ebp
f0101171:	c3                   	ret    

f0101172 <boot_map_region>:
//
// Hint: the TA solution uses pgdir_walk

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101172:	55                   	push   %ebp
f0101173:	89 e5                	mov    %esp,%ebp
f0101175:	57                   	push   %edi
f0101176:	56                   	push   %esi
f0101177:	53                   	push   %ebx
f0101178:	83 ec 1c             	sub    $0x1c,%esp
f010117b:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f010117e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
f0101184:	8b 45 08             	mov    0x8(%ebp),%eax
f0101187:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	size = ROUNDUP(size, PGSIZE); 
f010118c:	8d b9 ff 0f 00 00    	lea    0xfff(%ecx),%edi
f0101192:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f0101198:	89 d3                	mov    %edx,%ebx
f010119a:	29 d0                	sub    %edx,%eax
f010119c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010119f:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011a2:	83 c8 01             	or     $0x1,%eax
f01011a5:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f01011a8:	eb 3d                	jmp    f01011e7 <boot_map_region+0x75>
		if (!(pgTbEnt = pgdir_walk(pgdir, (const void*)vaBegin, 1))){
f01011aa:	83 ec 04             	sub    $0x4,%esp
f01011ad:	6a 01                	push   $0x1
f01011af:	53                   	push   %ebx
f01011b0:	ff 75 e0             	pushl  -0x20(%ebp)
f01011b3:	e8 cf fe ff ff       	call   f0101087 <pgdir_walk>
f01011b8:	83 c4 10             	add    $0x10,%esp
f01011bb:	85 c0                	test   %eax,%eax
f01011bd:	75 17                	jne    f01011d6 <boot_map_region+0x64>
			panic("Cannot find page for the page table entry, from boot_map_region function");
f01011bf:	83 ec 04             	sub    $0x4,%esp
f01011c2:	68 d0 67 10 f0       	push   $0xf01067d0
f01011c7:	68 2b 02 00 00       	push   $0x22b
f01011cc:	68 35 70 10 f0       	push   $0xf0107035
f01011d1:	e8 6a ee ff ff       	call   f0100040 <_panic>
		}
		//if (*pgTbEnt & PTE_P)
		//	panic("Page is already mapped");
		
		
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
f01011d6:	0b 75 dc             	or     -0x24(%ebp),%esi
f01011d9:	89 30                	mov    %esi,(%eax)
		vaBegin += PGSIZE;
f01011db:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		paBegin += PGSIZE; 
		size -= PGSIZE;
f01011e1:	81 ef 00 10 00 00    	sub    $0x1000,%edi
f01011e7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01011ea:	8d 34 18             	lea    (%eax,%ebx,1),%esi
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f01011ed:	85 ff                	test   %edi,%edi
f01011ef:	75 b9                	jne    f01011aa <boot_map_region+0x38>
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
		vaBegin += PGSIZE;
		paBegin += PGSIZE; 
		size -= PGSIZE;
	} 	
}
f01011f1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011f4:	5b                   	pop    %ebx
f01011f5:	5e                   	pop    %esi
f01011f6:	5f                   	pop    %edi
f01011f7:	5d                   	pop    %ebp
f01011f8:	c3                   	ret    

f01011f9 <page_lookup>:
// Hint: the TA solution uses pgdir_walk and pa2page.
//

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01011f9:	55                   	push   %ebp
f01011fa:	89 e5                	mov    %esp,%ebp
f01011fc:	53                   	push   %ebx
f01011fd:	83 ec 08             	sub    $0x8,%esp
f0101200:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
	pgTbEty = pgdir_walk(pgdir, va, 0);
f0101203:	6a 00                	push   $0x0
f0101205:	ff 75 0c             	pushl  0xc(%ebp)
f0101208:	ff 75 08             	pushl  0x8(%ebp)
f010120b:	e8 77 fe ff ff       	call   f0101087 <pgdir_walk>
f0101210:	89 c1                	mov    %eax,%ecx
	if (pgTbEty && (*pgTbEty & PTE_P)) {
f0101212:	83 c4 10             	add    $0x10,%esp
f0101215:	85 c0                	test   %eax,%eax
f0101217:	74 1a                	je     f0101233 <page_lookup+0x3a>
f0101219:	8b 10                	mov    (%eax),%edx
f010121b:	f6 c2 01             	test   $0x1,%dl
f010121e:	74 1a                	je     f010123a <page_lookup+0x41>
		ret = pages + (PTE_ADDR(*pgTbEty) >> PTXSHIFT);
f0101220:	c1 ea 0c             	shr    $0xc,%edx
f0101223:	a1 d0 0e 23 f0       	mov    0xf0230ed0,%eax
f0101228:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		if (pte_store) {
f010122b:	85 db                	test   %ebx,%ebx
f010122d:	74 10                	je     f010123f <page_lookup+0x46>
			*pte_store = pgTbEty;
f010122f:	89 0b                	mov    %ecx,(%ebx)
f0101231:	eb 0c                	jmp    f010123f <page_lookup+0x46>

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
f0101233:	b8 00 00 00 00       	mov    $0x0,%eax
f0101238:	eb 05                	jmp    f010123f <page_lookup+0x46>
f010123a:	b8 00 00 00 00       	mov    $0x0,%eax
		if (pte_store) {
			*pte_store = pgTbEty;
		}
	}
	return ret;
}
f010123f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101242:	c9                   	leave  
f0101243:	c3                   	ret    

f0101244 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101244:	55                   	push   %ebp
f0101245:	89 e5                	mov    %esp,%ebp
f0101247:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f010124a:	e8 7c 47 00 00       	call   f01059cb <cpunum>
f010124f:	6b c0 74             	imul   $0x74,%eax,%eax
f0101252:	83 b8 48 10 23 f0 00 	cmpl   $0x0,-0xfdcefb8(%eax)
f0101259:	74 16                	je     f0101271 <tlb_invalidate+0x2d>
f010125b:	e8 6b 47 00 00       	call   f01059cb <cpunum>
f0101260:	6b c0 74             	imul   $0x74,%eax,%eax
f0101263:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0101269:	8b 55 08             	mov    0x8(%ebp),%edx
f010126c:	39 50 60             	cmp    %edx,0x60(%eax)
f010126f:	75 06                	jne    f0101277 <tlb_invalidate+0x33>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101271:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101274:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f0101277:	c9                   	leave  
f0101278:	c3                   	ret    

f0101279 <page_remove>:
// 	tlb_invalidate, and page_decref.
//

void
page_remove(pde_t *pgdir, void *va)
{
f0101279:	55                   	push   %ebp
f010127a:	89 e5                	mov    %esp,%ebp
f010127c:	56                   	push   %esi
f010127d:	53                   	push   %ebx
f010127e:	83 ec 14             	sub    $0x14,%esp
f0101281:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101284:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t *pte;
	struct PageInfo *remPage = 0;
	if (!(remPage = page_lookup(pgdir, va, &pte))) {
f0101287:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010128a:	50                   	push   %eax
f010128b:	56                   	push   %esi
f010128c:	53                   	push   %ebx
f010128d:	e8 67 ff ff ff       	call   f01011f9 <page_lookup>
f0101292:	83 c4 10             	add    $0x10,%esp
f0101295:	85 c0                	test   %eax,%eax
f0101297:	74 1f                	je     f01012b8 <page_remove+0x3f>
		return;
	}
	page_decref(remPage);
f0101299:	83 ec 0c             	sub    $0xc,%esp
f010129c:	50                   	push   %eax
f010129d:	e8 be fd ff ff       	call   f0101060 <page_decref>
	*pte = 0;
f01012a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012a5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir, va);
f01012ab:	83 c4 08             	add    $0x8,%esp
f01012ae:	56                   	push   %esi
f01012af:	53                   	push   %ebx
f01012b0:	e8 8f ff ff ff       	call   f0101244 <tlb_invalidate>
f01012b5:	83 c4 10             	add    $0x10,%esp
}
f01012b8:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01012bb:	5b                   	pop    %ebx
f01012bc:	5e                   	pop    %esi
f01012bd:	5d                   	pop    %ebp
f01012be:	c3                   	ret    

f01012bf <page_insert>:
// and page2pa.
//

int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01012bf:	55                   	push   %ebp
f01012c0:	89 e5                	mov    %esp,%ebp
f01012c2:	57                   	push   %edi
f01012c3:	56                   	push   %esi
f01012c4:	53                   	push   %ebx
f01012c5:	83 ec 10             	sub    $0x10,%esp
f01012c8:	8b 75 0c             	mov    0xc(%ebp),%esi
f01012cb:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
f01012ce:	6a 01                	push   $0x1
f01012d0:	57                   	push   %edi
f01012d1:	ff 75 08             	pushl  0x8(%ebp)
f01012d4:	e8 ae fd ff ff       	call   f0101087 <pgdir_walk>
f01012d9:	89 c3                	mov    %eax,%ebx
	
	if (!pte){
f01012db:	83 c4 10             	add    $0x10,%esp
f01012de:	85 c0                	test   %eax,%eax
f01012e0:	0f 84 85 00 00 00    	je     f010136b <page_insert+0xac>
		return -E_NO_MEM; //Page table could not be allocated	
	}

	if (*pte & PTE_P){    //if page is already present
f01012e6:	8b 00                	mov    (%eax),%eax
f01012e8:	a8 01                	test   $0x1,%al
f01012ea:	74 5b                	je     f0101347 <page_insert+0x88>
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
f01012ec:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01012f1:	89 f2                	mov    %esi,%edx
f01012f3:	2b 15 d0 0e 23 f0    	sub    0xf0230ed0,%edx
f01012f9:	c1 fa 03             	sar    $0x3,%edx
f01012fc:	c1 e2 0c             	shl    $0xc,%edx
f01012ff:	39 d0                	cmp    %edx,%eax
f0101301:	75 11                	jne    f0101314 <page_insert+0x55>
f0101303:	8b 55 14             	mov    0x14(%ebp),%edx
f0101306:	83 ca 01             	or     $0x1,%edx
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
f0101309:	09 d0                	or     %edx,%eax
f010130b:	89 03                	mov    %eax,(%ebx)
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
			pp->pp_ref ++;  //incremnt the page reference
		}
		return 0;
f010130d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101312:	eb 5c                	jmp    f0101370 <page_insert+0xb1>
	if (*pte & PTE_P){    //if page is already present
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
		}
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
f0101314:	83 ec 08             	sub    $0x8,%esp
f0101317:	57                   	push   %edi
f0101318:	ff 75 08             	pushl  0x8(%ebp)
f010131b:	e8 59 ff ff ff       	call   f0101279 <page_remove>
f0101320:	8b 55 14             	mov    0x14(%ebp),%edx
f0101323:	83 ca 01             	or     $0x1,%edx
f0101326:	89 f0                	mov    %esi,%eax
f0101328:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f010132e:	c1 f8 03             	sar    $0x3,%eax
f0101331:	c1 e0 0c             	shl    $0xc,%eax
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
f0101334:	09 d0                	or     %edx,%eax
f0101336:	89 03                	mov    %eax,(%ebx)
			pp->pp_ref ++;  //incremnt the page reference
f0101338:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
f010133d:	83 c4 10             	add    $0x10,%esp
		}
		return 0;
f0101340:	b8 00 00 00 00       	mov    $0x0,%eax
f0101345:	eb 29                	jmp    f0101370 <page_insert+0xb1>
f0101347:	8b 55 14             	mov    0x14(%ebp),%edx
f010134a:	83 ca 01             	or     $0x1,%edx
f010134d:	89 f0                	mov    %esi,%eax
f010134f:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f0101355:	c1 f8 03             	sar    $0x3,%eax
f0101358:	c1 e0 0c             	shl    $0xc,%eax
	}	
	else{   // if page is not present
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
f010135b:	09 d0                	or     %edx,%eax
f010135d:	89 03                	mov    %eax,(%ebx)
		pp->pp_ref ++; // increment the page reference count	     
f010135f:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	}
	return 0;
f0101364:	b8 00 00 00 00       	mov    $0x0,%eax
f0101369:	eb 05                	jmp    f0101370 <page_insert+0xb1>
{
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
	
	if (!pte){
		return -E_NO_MEM; //Page table could not be allocated	
f010136b:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
		pp->pp_ref ++; // increment the page reference count	     
	}
	return 0;

}
f0101370:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101373:	5b                   	pop    %ebx
f0101374:	5e                   	pop    %esi
f0101375:	5f                   	pop    %edi
f0101376:	5d                   	pop    %ebp
f0101377:	c3                   	ret    

f0101378 <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f0101378:	55                   	push   %ebp
f0101379:	89 e5                	mov    %esp,%ebp
f010137b:	56                   	push   %esi
f010137c:	53                   	push   %ebx
	//
	// Your code here:
	//panic("mmio_map_region not implemented");
	
	//Since we modify the value of the pointer, copy the value of the pointer into some variable
	void* save = (void*) base;  // USe a pointer to void, just to store the first address
f010137d:	8b 35 00 03 12 f0    	mov    0xf0120300,%esi
	
	//Roundup size to pgsize
	size = ROUNDUP(size,PGSIZE);
f0101383:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101386:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f010138c:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	
	//Use bootmap region to map the given region
	boot_map_region(kern_pgdir, base, size, pa, PTE_W | PTE_P |PTE_PCD|PTE_PWT);
f0101392:	83 ec 08             	sub    $0x8,%esp
f0101395:	6a 1b                	push   $0x1b
f0101397:	ff 75 08             	pushl  0x8(%ebp)
f010139a:	89 d9                	mov    %ebx,%ecx
f010139c:	89 f2                	mov    %esi,%edx
f010139e:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
f01013a3:	e8 ca fd ff ff       	call   f0101172 <boot_map_region>
	
	//reserving size bytes of memory
	base += size;
f01013a8:	01 1d 00 03 12 f0    	add    %ebx,0xf0120300
	
	return save; 
	
}
f01013ae:	89 f0                	mov    %esi,%eax
f01013b0:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01013b3:	5b                   	pop    %ebx
f01013b4:	5e                   	pop    %esi
f01013b5:	5d                   	pop    %ebp
f01013b6:	c3                   	ret    

f01013b7 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01013b7:	55                   	push   %ebp
f01013b8:	89 e5                	mov    %esp,%ebp
f01013ba:	57                   	push   %edi
f01013bb:	56                   	push   %esi
f01013bc:	53                   	push   %ebx
f01013bd:	83 ec 48             	sub    $0x48,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01013c0:	6a 15                	push   $0x15
f01013c2:	e8 29 23 00 00       	call   f01036f0 <mc146818_read>
f01013c7:	89 c3                	mov    %eax,%ebx
f01013c9:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f01013d0:	e8 1b 23 00 00       	call   f01036f0 <mc146818_read>
f01013d5:	c1 e0 08             	shl    $0x8,%eax
f01013d8:	09 d8                	or     %ebx,%eax
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01013da:	c1 e0 0a             	shl    $0xa,%eax
f01013dd:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01013e3:	85 c0                	test   %eax,%eax
f01013e5:	0f 48 c2             	cmovs  %edx,%eax
f01013e8:	c1 f8 0c             	sar    $0xc,%eax
f01013eb:	a3 68 02 23 f0       	mov    %eax,0xf0230268
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01013f0:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f01013f7:	e8 f4 22 00 00       	call   f01036f0 <mc146818_read>
f01013fc:	89 c3                	mov    %eax,%ebx
f01013fe:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101405:	e8 e6 22 00 00       	call   f01036f0 <mc146818_read>
f010140a:	c1 e0 08             	shl    $0x8,%eax
f010140d:	09 d8                	or     %ebx,%eax
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010140f:	c1 e0 0a             	shl    $0xa,%eax
f0101412:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101418:	83 c4 10             	add    $0x10,%esp
f010141b:	85 c0                	test   %eax,%eax
f010141d:	0f 48 c2             	cmovs  %edx,%eax
f0101420:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101423:	85 c0                	test   %eax,%eax
f0101425:	74 0e                	je     f0101435 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101427:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f010142d:	89 15 c8 0e 23 f0    	mov    %edx,0xf0230ec8
f0101433:	eb 0c                	jmp    f0101441 <mem_init+0x8a>
	else
		npages = npages_basemem;
f0101435:	8b 15 68 02 23 f0    	mov    0xf0230268,%edx
f010143b:	89 15 c8 0e 23 f0    	mov    %edx,0xf0230ec8

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0101441:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101444:	c1 e8 0a             	shr    $0xa,%eax
f0101447:	50                   	push   %eax
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0101448:	a1 68 02 23 f0       	mov    0xf0230268,%eax
f010144d:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101450:	c1 e8 0a             	shr    $0xa,%eax
f0101453:	50                   	push   %eax
		npages * PGSIZE / 1024,
f0101454:	a1 c8 0e 23 f0       	mov    0xf0230ec8,%eax
f0101459:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010145c:	c1 e8 0a             	shr    $0xa,%eax
f010145f:	50                   	push   %eax
f0101460:	68 1c 68 10 f0       	push   $0xf010681c
f0101465:	e8 e7 23 00 00       	call   f0103851 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010146a:	b8 00 10 00 00       	mov    $0x1000,%eax
f010146f:	e8 17 f6 ff ff       	call   f0100a8b <boot_alloc>
f0101474:	a3 cc 0e 23 f0       	mov    %eax,0xf0230ecc
	memset(kern_pgdir, 0, PGSIZE);
f0101479:	83 c4 0c             	add    $0xc,%esp
f010147c:	68 00 10 00 00       	push   $0x1000
f0101481:	6a 00                	push   $0x0
f0101483:	50                   	push   %eax
f0101484:	e8 1f 3f 00 00       	call   f01053a8 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101489:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010148e:	83 c4 10             	add    $0x10,%esp
f0101491:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101496:	77 15                	ja     f01014ad <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101498:	50                   	push   %eax
f0101499:	68 c8 60 10 f0       	push   $0xf01060c8
f010149e:	68 98 00 00 00       	push   $0x98
f01014a3:	68 35 70 10 f0       	push   $0xf0107035
f01014a8:	e8 93 eb ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01014ad:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01014b3:	83 ca 05             	or     $0x5,%edx
f01014b6:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.

	//This line creates a boot allocation of memory of the size of number of pages
	// mulitplied by size of struct Pageinfo to store metadata of the page. 
	pages = boot_alloc(sizeof(struct PageInfo) * npages);   
f01014bc:	a1 c8 0e 23 f0       	mov    0xf0230ec8,%eax
f01014c1:	c1 e0 03             	shl    $0x3,%eax
f01014c4:	e8 c2 f5 ff ff       	call   f0100a8b <boot_alloc>
f01014c9:	a3 d0 0e 23 f0       	mov    %eax,0xf0230ed0
	memset(pages, 0, sizeof(struct PageInfo) * npages); //Clear the memory 
f01014ce:	83 ec 04             	sub    $0x4,%esp
f01014d1:	8b 0d c8 0e 23 f0    	mov    0xf0230ec8,%ecx
f01014d7:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01014de:	52                   	push   %edx
f01014df:	6a 00                	push   $0x0
f01014e1:	50                   	push   %eax
f01014e2:	e8 c1 3e 00 00       	call   f01053a8 <memset>
	// The kernel uses this array to keep track of environment array:
	// 'NENV' is the number of Environments in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = boot_alloc(sizeof(struct Env)*NENV);
f01014e7:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f01014ec:	e8 9a f5 ff ff       	call   f0100a8b <boot_alloc>
f01014f1:	a3 6c 02 23 f0       	mov    %eax,0xf023026c
	memset(envs,0,sizeof(struct Env)*NENV);
f01014f6:	83 c4 0c             	add    $0xc,%esp
f01014f9:	68 00 f0 01 00       	push   $0x1f000
f01014fe:	6a 00                	push   $0x0
f0101500:	50                   	push   %eax
f0101501:	e8 a2 3e 00 00       	call   f01053a8 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101506:	e8 0a f9 ff ff       	call   f0100e15 <page_init>

	check_page_free_list(1);
f010150b:	b8 01 00 00 00       	mov    $0x1,%eax
f0101510:	e8 ec f5 ff ff       	call   f0100b01 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101515:	83 c4 10             	add    $0x10,%esp
f0101518:	83 3d d0 0e 23 f0 00 	cmpl   $0x0,0xf0230ed0
f010151f:	75 17                	jne    f0101538 <mem_init+0x181>
		panic("'pages' is a null pointer!");
f0101521:	83 ec 04             	sub    $0x4,%esp
f0101524:	68 35 71 10 f0       	push   $0xf0107135
f0101529:	68 84 03 00 00       	push   $0x384
f010152e:	68 35 70 10 f0       	push   $0xf0107035
f0101533:	e8 08 eb ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101538:	a1 64 02 23 f0       	mov    0xf0230264,%eax
f010153d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101542:	eb 05                	jmp    f0101549 <mem_init+0x192>
		++nfree;
f0101544:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101547:	8b 00                	mov    (%eax),%eax
f0101549:	85 c0                	test   %eax,%eax
f010154b:	75 f7                	jne    f0101544 <mem_init+0x18d>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010154d:	83 ec 0c             	sub    $0xc,%esp
f0101550:	6a 00                	push   $0x0
f0101552:	e8 42 fa ff ff       	call   f0100f99 <page_alloc>
f0101557:	89 c7                	mov    %eax,%edi
f0101559:	83 c4 10             	add    $0x10,%esp
f010155c:	85 c0                	test   %eax,%eax
f010155e:	75 19                	jne    f0101579 <mem_init+0x1c2>
f0101560:	68 50 71 10 f0       	push   $0xf0107150
f0101565:	68 5b 70 10 f0       	push   $0xf010705b
f010156a:	68 8c 03 00 00       	push   $0x38c
f010156f:	68 35 70 10 f0       	push   $0xf0107035
f0101574:	e8 c7 ea ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101579:	83 ec 0c             	sub    $0xc,%esp
f010157c:	6a 00                	push   $0x0
f010157e:	e8 16 fa ff ff       	call   f0100f99 <page_alloc>
f0101583:	89 c6                	mov    %eax,%esi
f0101585:	83 c4 10             	add    $0x10,%esp
f0101588:	85 c0                	test   %eax,%eax
f010158a:	75 19                	jne    f01015a5 <mem_init+0x1ee>
f010158c:	68 66 71 10 f0       	push   $0xf0107166
f0101591:	68 5b 70 10 f0       	push   $0xf010705b
f0101596:	68 8d 03 00 00       	push   $0x38d
f010159b:	68 35 70 10 f0       	push   $0xf0107035
f01015a0:	e8 9b ea ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01015a5:	83 ec 0c             	sub    $0xc,%esp
f01015a8:	6a 00                	push   $0x0
f01015aa:	e8 ea f9 ff ff       	call   f0100f99 <page_alloc>
f01015af:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015b2:	83 c4 10             	add    $0x10,%esp
f01015b5:	85 c0                	test   %eax,%eax
f01015b7:	75 19                	jne    f01015d2 <mem_init+0x21b>
f01015b9:	68 7c 71 10 f0       	push   $0xf010717c
f01015be:	68 5b 70 10 f0       	push   $0xf010705b
f01015c3:	68 8e 03 00 00       	push   $0x38e
f01015c8:	68 35 70 10 f0       	push   $0xf0107035
f01015cd:	e8 6e ea ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015d2:	39 f7                	cmp    %esi,%edi
f01015d4:	75 19                	jne    f01015ef <mem_init+0x238>
f01015d6:	68 92 71 10 f0       	push   $0xf0107192
f01015db:	68 5b 70 10 f0       	push   $0xf010705b
f01015e0:	68 91 03 00 00       	push   $0x391
f01015e5:	68 35 70 10 f0       	push   $0xf0107035
f01015ea:	e8 51 ea ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015ef:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015f2:	39 c7                	cmp    %eax,%edi
f01015f4:	74 04                	je     f01015fa <mem_init+0x243>
f01015f6:	39 c6                	cmp    %eax,%esi
f01015f8:	75 19                	jne    f0101613 <mem_init+0x25c>
f01015fa:	68 58 68 10 f0       	push   $0xf0106858
f01015ff:	68 5b 70 10 f0       	push   $0xf010705b
f0101604:	68 92 03 00 00       	push   $0x392
f0101609:	68 35 70 10 f0       	push   $0xf0107035
f010160e:	e8 2d ea ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101613:	8b 0d d0 0e 23 f0    	mov    0xf0230ed0,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101619:	8b 15 c8 0e 23 f0    	mov    0xf0230ec8,%edx
f010161f:	c1 e2 0c             	shl    $0xc,%edx
f0101622:	89 f8                	mov    %edi,%eax
f0101624:	29 c8                	sub    %ecx,%eax
f0101626:	c1 f8 03             	sar    $0x3,%eax
f0101629:	c1 e0 0c             	shl    $0xc,%eax
f010162c:	39 d0                	cmp    %edx,%eax
f010162e:	72 19                	jb     f0101649 <mem_init+0x292>
f0101630:	68 a4 71 10 f0       	push   $0xf01071a4
f0101635:	68 5b 70 10 f0       	push   $0xf010705b
f010163a:	68 93 03 00 00       	push   $0x393
f010163f:	68 35 70 10 f0       	push   $0xf0107035
f0101644:	e8 f7 e9 ff ff       	call   f0100040 <_panic>
f0101649:	89 f0                	mov    %esi,%eax
f010164b:	29 c8                	sub    %ecx,%eax
f010164d:	c1 f8 03             	sar    $0x3,%eax
f0101650:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f0101653:	39 c2                	cmp    %eax,%edx
f0101655:	77 19                	ja     f0101670 <mem_init+0x2b9>
f0101657:	68 c1 71 10 f0       	push   $0xf01071c1
f010165c:	68 5b 70 10 f0       	push   $0xf010705b
f0101661:	68 94 03 00 00       	push   $0x394
f0101666:	68 35 70 10 f0       	push   $0xf0107035
f010166b:	e8 d0 e9 ff ff       	call   f0100040 <_panic>
f0101670:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101673:	29 c8                	sub    %ecx,%eax
f0101675:	c1 f8 03             	sar    $0x3,%eax
f0101678:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f010167b:	39 c2                	cmp    %eax,%edx
f010167d:	77 19                	ja     f0101698 <mem_init+0x2e1>
f010167f:	68 de 71 10 f0       	push   $0xf01071de
f0101684:	68 5b 70 10 f0       	push   $0xf010705b
f0101689:	68 95 03 00 00       	push   $0x395
f010168e:	68 35 70 10 f0       	push   $0xf0107035
f0101693:	e8 a8 e9 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101698:	a1 64 02 23 f0       	mov    0xf0230264,%eax
f010169d:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01016a0:	c7 05 64 02 23 f0 00 	movl   $0x0,0xf0230264
f01016a7:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01016aa:	83 ec 0c             	sub    $0xc,%esp
f01016ad:	6a 00                	push   $0x0
f01016af:	e8 e5 f8 ff ff       	call   f0100f99 <page_alloc>
f01016b4:	83 c4 10             	add    $0x10,%esp
f01016b7:	85 c0                	test   %eax,%eax
f01016b9:	74 19                	je     f01016d4 <mem_init+0x31d>
f01016bb:	68 fb 71 10 f0       	push   $0xf01071fb
f01016c0:	68 5b 70 10 f0       	push   $0xf010705b
f01016c5:	68 9c 03 00 00       	push   $0x39c
f01016ca:	68 35 70 10 f0       	push   $0xf0107035
f01016cf:	e8 6c e9 ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01016d4:	83 ec 0c             	sub    $0xc,%esp
f01016d7:	57                   	push   %edi
f01016d8:	e8 32 f9 ff ff       	call   f010100f <page_free>
	page_free(pp1);
f01016dd:	89 34 24             	mov    %esi,(%esp)
f01016e0:	e8 2a f9 ff ff       	call   f010100f <page_free>
	page_free(pp2);
f01016e5:	83 c4 04             	add    $0x4,%esp
f01016e8:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016eb:	e8 1f f9 ff ff       	call   f010100f <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01016f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016f7:	e8 9d f8 ff ff       	call   f0100f99 <page_alloc>
f01016fc:	89 c6                	mov    %eax,%esi
f01016fe:	83 c4 10             	add    $0x10,%esp
f0101701:	85 c0                	test   %eax,%eax
f0101703:	75 19                	jne    f010171e <mem_init+0x367>
f0101705:	68 50 71 10 f0       	push   $0xf0107150
f010170a:	68 5b 70 10 f0       	push   $0xf010705b
f010170f:	68 a3 03 00 00       	push   $0x3a3
f0101714:	68 35 70 10 f0       	push   $0xf0107035
f0101719:	e8 22 e9 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010171e:	83 ec 0c             	sub    $0xc,%esp
f0101721:	6a 00                	push   $0x0
f0101723:	e8 71 f8 ff ff       	call   f0100f99 <page_alloc>
f0101728:	89 c7                	mov    %eax,%edi
f010172a:	83 c4 10             	add    $0x10,%esp
f010172d:	85 c0                	test   %eax,%eax
f010172f:	75 19                	jne    f010174a <mem_init+0x393>
f0101731:	68 66 71 10 f0       	push   $0xf0107166
f0101736:	68 5b 70 10 f0       	push   $0xf010705b
f010173b:	68 a4 03 00 00       	push   $0x3a4
f0101740:	68 35 70 10 f0       	push   $0xf0107035
f0101745:	e8 f6 e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010174a:	83 ec 0c             	sub    $0xc,%esp
f010174d:	6a 00                	push   $0x0
f010174f:	e8 45 f8 ff ff       	call   f0100f99 <page_alloc>
f0101754:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101757:	83 c4 10             	add    $0x10,%esp
f010175a:	85 c0                	test   %eax,%eax
f010175c:	75 19                	jne    f0101777 <mem_init+0x3c0>
f010175e:	68 7c 71 10 f0       	push   $0xf010717c
f0101763:	68 5b 70 10 f0       	push   $0xf010705b
f0101768:	68 a5 03 00 00       	push   $0x3a5
f010176d:	68 35 70 10 f0       	push   $0xf0107035
f0101772:	e8 c9 e8 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101777:	39 fe                	cmp    %edi,%esi
f0101779:	75 19                	jne    f0101794 <mem_init+0x3dd>
f010177b:	68 92 71 10 f0       	push   $0xf0107192
f0101780:	68 5b 70 10 f0       	push   $0xf010705b
f0101785:	68 a7 03 00 00       	push   $0x3a7
f010178a:	68 35 70 10 f0       	push   $0xf0107035
f010178f:	e8 ac e8 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101794:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101797:	39 c6                	cmp    %eax,%esi
f0101799:	74 04                	je     f010179f <mem_init+0x3e8>
f010179b:	39 c7                	cmp    %eax,%edi
f010179d:	75 19                	jne    f01017b8 <mem_init+0x401>
f010179f:	68 58 68 10 f0       	push   $0xf0106858
f01017a4:	68 5b 70 10 f0       	push   $0xf010705b
f01017a9:	68 a8 03 00 00       	push   $0x3a8
f01017ae:	68 35 70 10 f0       	push   $0xf0107035
f01017b3:	e8 88 e8 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01017b8:	83 ec 0c             	sub    $0xc,%esp
f01017bb:	6a 00                	push   $0x0
f01017bd:	e8 d7 f7 ff ff       	call   f0100f99 <page_alloc>
f01017c2:	83 c4 10             	add    $0x10,%esp
f01017c5:	85 c0                	test   %eax,%eax
f01017c7:	74 19                	je     f01017e2 <mem_init+0x42b>
f01017c9:	68 fb 71 10 f0       	push   $0xf01071fb
f01017ce:	68 5b 70 10 f0       	push   $0xf010705b
f01017d3:	68 a9 03 00 00       	push   $0x3a9
f01017d8:	68 35 70 10 f0       	push   $0xf0107035
f01017dd:	e8 5e e8 ff ff       	call   f0100040 <_panic>
f01017e2:	89 f0                	mov    %esi,%eax
f01017e4:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f01017ea:	c1 f8 03             	sar    $0x3,%eax
f01017ed:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01017f0:	89 c2                	mov    %eax,%edx
f01017f2:	c1 ea 0c             	shr    $0xc,%edx
f01017f5:	3b 15 c8 0e 23 f0    	cmp    0xf0230ec8,%edx
f01017fb:	72 12                	jb     f010180f <mem_init+0x458>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01017fd:	50                   	push   %eax
f01017fe:	68 a4 60 10 f0       	push   $0xf01060a4
f0101803:	6a 58                	push   $0x58
f0101805:	68 41 70 10 f0       	push   $0xf0107041
f010180a:	e8 31 e8 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010180f:	83 ec 04             	sub    $0x4,%esp
f0101812:	68 00 10 00 00       	push   $0x1000
f0101817:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0101819:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010181e:	50                   	push   %eax
f010181f:	e8 84 3b 00 00       	call   f01053a8 <memset>
	page_free(pp0);
f0101824:	89 34 24             	mov    %esi,(%esp)
f0101827:	e8 e3 f7 ff ff       	call   f010100f <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010182c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101833:	e8 61 f7 ff ff       	call   f0100f99 <page_alloc>
f0101838:	83 c4 10             	add    $0x10,%esp
f010183b:	85 c0                	test   %eax,%eax
f010183d:	75 19                	jne    f0101858 <mem_init+0x4a1>
f010183f:	68 0a 72 10 f0       	push   $0xf010720a
f0101844:	68 5b 70 10 f0       	push   $0xf010705b
f0101849:	68 ae 03 00 00       	push   $0x3ae
f010184e:	68 35 70 10 f0       	push   $0xf0107035
f0101853:	e8 e8 e7 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101858:	39 c6                	cmp    %eax,%esi
f010185a:	74 19                	je     f0101875 <mem_init+0x4be>
f010185c:	68 28 72 10 f0       	push   $0xf0107228
f0101861:	68 5b 70 10 f0       	push   $0xf010705b
f0101866:	68 af 03 00 00       	push   $0x3af
f010186b:	68 35 70 10 f0       	push   $0xf0107035
f0101870:	e8 cb e7 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101875:	89 f0                	mov    %esi,%eax
f0101877:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f010187d:	c1 f8 03             	sar    $0x3,%eax
f0101880:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101883:	89 c2                	mov    %eax,%edx
f0101885:	c1 ea 0c             	shr    $0xc,%edx
f0101888:	3b 15 c8 0e 23 f0    	cmp    0xf0230ec8,%edx
f010188e:	72 12                	jb     f01018a2 <mem_init+0x4eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101890:	50                   	push   %eax
f0101891:	68 a4 60 10 f0       	push   $0xf01060a4
f0101896:	6a 58                	push   $0x58
f0101898:	68 41 70 10 f0       	push   $0xf0107041
f010189d:	e8 9e e7 ff ff       	call   f0100040 <_panic>
f01018a2:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01018a8:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01018ae:	80 38 00             	cmpb   $0x0,(%eax)
f01018b1:	74 19                	je     f01018cc <mem_init+0x515>
f01018b3:	68 38 72 10 f0       	push   $0xf0107238
f01018b8:	68 5b 70 10 f0       	push   $0xf010705b
f01018bd:	68 b2 03 00 00       	push   $0x3b2
f01018c2:	68 35 70 10 f0       	push   $0xf0107035
f01018c7:	e8 74 e7 ff ff       	call   f0100040 <_panic>
f01018cc:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01018cf:	39 d0                	cmp    %edx,%eax
f01018d1:	75 db                	jne    f01018ae <mem_init+0x4f7>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01018d3:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01018d6:	a3 64 02 23 f0       	mov    %eax,0xf0230264

	// free the pages we took
	page_free(pp0);
f01018db:	83 ec 0c             	sub    $0xc,%esp
f01018de:	56                   	push   %esi
f01018df:	e8 2b f7 ff ff       	call   f010100f <page_free>
	page_free(pp1);
f01018e4:	89 3c 24             	mov    %edi,(%esp)
f01018e7:	e8 23 f7 ff ff       	call   f010100f <page_free>
	page_free(pp2);
f01018ec:	83 c4 04             	add    $0x4,%esp
f01018ef:	ff 75 d4             	pushl  -0x2c(%ebp)
f01018f2:	e8 18 f7 ff ff       	call   f010100f <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01018f7:	a1 64 02 23 f0       	mov    0xf0230264,%eax
f01018fc:	83 c4 10             	add    $0x10,%esp
f01018ff:	eb 05                	jmp    f0101906 <mem_init+0x54f>
		--nfree;
f0101901:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101904:	8b 00                	mov    (%eax),%eax
f0101906:	85 c0                	test   %eax,%eax
f0101908:	75 f7                	jne    f0101901 <mem_init+0x54a>
		--nfree;
	assert(nfree == 0);
f010190a:	85 db                	test   %ebx,%ebx
f010190c:	74 19                	je     f0101927 <mem_init+0x570>
f010190e:	68 42 72 10 f0       	push   $0xf0107242
f0101913:	68 5b 70 10 f0       	push   $0xf010705b
f0101918:	68 bf 03 00 00       	push   $0x3bf
f010191d:	68 35 70 10 f0       	push   $0xf0107035
f0101922:	e8 19 e7 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101927:	83 ec 0c             	sub    $0xc,%esp
f010192a:	68 78 68 10 f0       	push   $0xf0106878
f010192f:	e8 1d 1f 00 00       	call   f0103851 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101934:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010193b:	e8 59 f6 ff ff       	call   f0100f99 <page_alloc>
f0101940:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101943:	83 c4 10             	add    $0x10,%esp
f0101946:	85 c0                	test   %eax,%eax
f0101948:	75 19                	jne    f0101963 <mem_init+0x5ac>
f010194a:	68 50 71 10 f0       	push   $0xf0107150
f010194f:	68 5b 70 10 f0       	push   $0xf010705b
f0101954:	68 25 04 00 00       	push   $0x425
f0101959:	68 35 70 10 f0       	push   $0xf0107035
f010195e:	e8 dd e6 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101963:	83 ec 0c             	sub    $0xc,%esp
f0101966:	6a 00                	push   $0x0
f0101968:	e8 2c f6 ff ff       	call   f0100f99 <page_alloc>
f010196d:	89 c3                	mov    %eax,%ebx
f010196f:	83 c4 10             	add    $0x10,%esp
f0101972:	85 c0                	test   %eax,%eax
f0101974:	75 19                	jne    f010198f <mem_init+0x5d8>
f0101976:	68 66 71 10 f0       	push   $0xf0107166
f010197b:	68 5b 70 10 f0       	push   $0xf010705b
f0101980:	68 26 04 00 00       	push   $0x426
f0101985:	68 35 70 10 f0       	push   $0xf0107035
f010198a:	e8 b1 e6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010198f:	83 ec 0c             	sub    $0xc,%esp
f0101992:	6a 00                	push   $0x0
f0101994:	e8 00 f6 ff ff       	call   f0100f99 <page_alloc>
f0101999:	89 c6                	mov    %eax,%esi
f010199b:	83 c4 10             	add    $0x10,%esp
f010199e:	85 c0                	test   %eax,%eax
f01019a0:	75 19                	jne    f01019bb <mem_init+0x604>
f01019a2:	68 7c 71 10 f0       	push   $0xf010717c
f01019a7:	68 5b 70 10 f0       	push   $0xf010705b
f01019ac:	68 27 04 00 00       	push   $0x427
f01019b1:	68 35 70 10 f0       	push   $0xf0107035
f01019b6:	e8 85 e6 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01019bb:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01019be:	75 19                	jne    f01019d9 <mem_init+0x622>
f01019c0:	68 92 71 10 f0       	push   $0xf0107192
f01019c5:	68 5b 70 10 f0       	push   $0xf010705b
f01019ca:	68 2a 04 00 00       	push   $0x42a
f01019cf:	68 35 70 10 f0       	push   $0xf0107035
f01019d4:	e8 67 e6 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01019d9:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01019dc:	74 04                	je     f01019e2 <mem_init+0x62b>
f01019de:	39 c3                	cmp    %eax,%ebx
f01019e0:	75 19                	jne    f01019fb <mem_init+0x644>
f01019e2:	68 58 68 10 f0       	push   $0xf0106858
f01019e7:	68 5b 70 10 f0       	push   $0xf010705b
f01019ec:	68 2b 04 00 00       	push   $0x42b
f01019f1:	68 35 70 10 f0       	push   $0xf0107035
f01019f6:	e8 45 e6 ff ff       	call   f0100040 <_panic>
	

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01019fb:	a1 64 02 23 f0       	mov    0xf0230264,%eax
f0101a00:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101a03:	c7 05 64 02 23 f0 00 	movl   $0x0,0xf0230264
f0101a0a:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101a0d:	83 ec 0c             	sub    $0xc,%esp
f0101a10:	6a 00                	push   $0x0
f0101a12:	e8 82 f5 ff ff       	call   f0100f99 <page_alloc>
f0101a17:	83 c4 10             	add    $0x10,%esp
f0101a1a:	85 c0                	test   %eax,%eax
f0101a1c:	74 19                	je     f0101a37 <mem_init+0x680>
f0101a1e:	68 fb 71 10 f0       	push   $0xf01071fb
f0101a23:	68 5b 70 10 f0       	push   $0xf010705b
f0101a28:	68 33 04 00 00       	push   $0x433
f0101a2d:	68 35 70 10 f0       	push   $0xf0107035
f0101a32:	e8 09 e6 ff ff       	call   f0100040 <_panic>
	
	
	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101a37:	83 ec 04             	sub    $0x4,%esp
f0101a3a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101a3d:	50                   	push   %eax
f0101a3e:	6a 00                	push   $0x0
f0101a40:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0101a46:	e8 ae f7 ff ff       	call   f01011f9 <page_lookup>
f0101a4b:	83 c4 10             	add    $0x10,%esp
f0101a4e:	85 c0                	test   %eax,%eax
f0101a50:	74 19                	je     f0101a6b <mem_init+0x6b4>
f0101a52:	68 98 68 10 f0       	push   $0xf0106898
f0101a57:	68 5b 70 10 f0       	push   $0xf010705b
f0101a5c:	68 37 04 00 00       	push   $0x437
f0101a61:	68 35 70 10 f0       	push   $0xf0107035
f0101a66:	e8 d5 e5 ff ff       	call   f0100040 <_panic>
	
	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a6b:	6a 02                	push   $0x2
f0101a6d:	6a 00                	push   $0x0
f0101a6f:	53                   	push   %ebx
f0101a70:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0101a76:	e8 44 f8 ff ff       	call   f01012bf <page_insert>
f0101a7b:	83 c4 10             	add    $0x10,%esp
f0101a7e:	85 c0                	test   %eax,%eax
f0101a80:	78 19                	js     f0101a9b <mem_init+0x6e4>
f0101a82:	68 d0 68 10 f0       	push   $0xf01068d0
f0101a87:	68 5b 70 10 f0       	push   $0xf010705b
f0101a8c:	68 3a 04 00 00       	push   $0x43a
f0101a91:	68 35 70 10 f0       	push   $0xf0107035
f0101a96:	e8 a5 e5 ff ff       	call   f0100040 <_panic>
	
	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a9b:	83 ec 0c             	sub    $0xc,%esp
f0101a9e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101aa1:	e8 69 f5 ff ff       	call   f010100f <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101aa6:	6a 02                	push   $0x2
f0101aa8:	6a 00                	push   $0x0
f0101aaa:	53                   	push   %ebx
f0101aab:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0101ab1:	e8 09 f8 ff ff       	call   f01012bf <page_insert>
f0101ab6:	83 c4 20             	add    $0x20,%esp
f0101ab9:	85 c0                	test   %eax,%eax
f0101abb:	74 19                	je     f0101ad6 <mem_init+0x71f>
f0101abd:	68 00 69 10 f0       	push   $0xf0106900
f0101ac2:	68 5b 70 10 f0       	push   $0xf010705b
f0101ac7:	68 3e 04 00 00       	push   $0x43e
f0101acc:	68 35 70 10 f0       	push   $0xf0107035
f0101ad1:	e8 6a e5 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ad6:	8b 3d cc 0e 23 f0    	mov    0xf0230ecc,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101adc:	a1 d0 0e 23 f0       	mov    0xf0230ed0,%eax
f0101ae1:	89 c1                	mov    %eax,%ecx
f0101ae3:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101ae6:	8b 17                	mov    (%edi),%edx
f0101ae8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101aee:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101af1:	29 c8                	sub    %ecx,%eax
f0101af3:	c1 f8 03             	sar    $0x3,%eax
f0101af6:	c1 e0 0c             	shl    $0xc,%eax
f0101af9:	39 c2                	cmp    %eax,%edx
f0101afb:	74 19                	je     f0101b16 <mem_init+0x75f>
f0101afd:	68 30 69 10 f0       	push   $0xf0106930
f0101b02:	68 5b 70 10 f0       	push   $0xf010705b
f0101b07:	68 3f 04 00 00       	push   $0x43f
f0101b0c:	68 35 70 10 f0       	push   $0xf0107035
f0101b11:	e8 2a e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b16:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b1b:	89 f8                	mov    %edi,%eax
f0101b1d:	e8 05 ef ff ff       	call   f0100a27 <check_va2pa>
f0101b22:	89 da                	mov    %ebx,%edx
f0101b24:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101b27:	c1 fa 03             	sar    $0x3,%edx
f0101b2a:	c1 e2 0c             	shl    $0xc,%edx
f0101b2d:	39 d0                	cmp    %edx,%eax
f0101b2f:	74 19                	je     f0101b4a <mem_init+0x793>
f0101b31:	68 58 69 10 f0       	push   $0xf0106958
f0101b36:	68 5b 70 10 f0       	push   $0xf010705b
f0101b3b:	68 40 04 00 00       	push   $0x440
f0101b40:	68 35 70 10 f0       	push   $0xf0107035
f0101b45:	e8 f6 e4 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101b4a:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b4f:	74 19                	je     f0101b6a <mem_init+0x7b3>
f0101b51:	68 4d 72 10 f0       	push   $0xf010724d
f0101b56:	68 5b 70 10 f0       	push   $0xf010705b
f0101b5b:	68 41 04 00 00       	push   $0x441
f0101b60:	68 35 70 10 f0       	push   $0xf0107035
f0101b65:	e8 d6 e4 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101b6a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b6d:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b72:	74 19                	je     f0101b8d <mem_init+0x7d6>
f0101b74:	68 5e 72 10 f0       	push   $0xf010725e
f0101b79:	68 5b 70 10 f0       	push   $0xf010705b
f0101b7e:	68 42 04 00 00       	push   $0x442
f0101b83:	68 35 70 10 f0       	push   $0xf0107035
f0101b88:	e8 b3 e4 ff ff       	call   f0100040 <_panic>
	
	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b8d:	6a 02                	push   $0x2
f0101b8f:	68 00 10 00 00       	push   $0x1000
f0101b94:	56                   	push   %esi
f0101b95:	57                   	push   %edi
f0101b96:	e8 24 f7 ff ff       	call   f01012bf <page_insert>
f0101b9b:	83 c4 10             	add    $0x10,%esp
f0101b9e:	85 c0                	test   %eax,%eax
f0101ba0:	74 19                	je     f0101bbb <mem_init+0x804>
f0101ba2:	68 88 69 10 f0       	push   $0xf0106988
f0101ba7:	68 5b 70 10 f0       	push   $0xf010705b
f0101bac:	68 45 04 00 00       	push   $0x445
f0101bb1:	68 35 70 10 f0       	push   $0xf0107035
f0101bb6:	e8 85 e4 ff ff       	call   f0100040 <_panic>

	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bbb:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bc0:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
f0101bc5:	e8 5d ee ff ff       	call   f0100a27 <check_va2pa>
f0101bca:	89 f2                	mov    %esi,%edx
f0101bcc:	2b 15 d0 0e 23 f0    	sub    0xf0230ed0,%edx
f0101bd2:	c1 fa 03             	sar    $0x3,%edx
f0101bd5:	c1 e2 0c             	shl    $0xc,%edx
f0101bd8:	39 d0                	cmp    %edx,%eax
f0101bda:	74 19                	je     f0101bf5 <mem_init+0x83e>
f0101bdc:	68 c4 69 10 f0       	push   $0xf01069c4
f0101be1:	68 5b 70 10 f0       	push   $0xf010705b
f0101be6:	68 47 04 00 00       	push   $0x447
f0101beb:	68 35 70 10 f0       	push   $0xf0107035
f0101bf0:	e8 4b e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101bf5:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101bfa:	74 19                	je     f0101c15 <mem_init+0x85e>
f0101bfc:	68 6f 72 10 f0       	push   $0xf010726f
f0101c01:	68 5b 70 10 f0       	push   $0xf010705b
f0101c06:	68 48 04 00 00       	push   $0x448
f0101c0b:	68 35 70 10 f0       	push   $0xf0107035
f0101c10:	e8 2b e4 ff ff       	call   f0100040 <_panic>
	
	// should be no free memory
	assert(!page_alloc(0));
f0101c15:	83 ec 0c             	sub    $0xc,%esp
f0101c18:	6a 00                	push   $0x0
f0101c1a:	e8 7a f3 ff ff       	call   f0100f99 <page_alloc>
f0101c1f:	83 c4 10             	add    $0x10,%esp
f0101c22:	85 c0                	test   %eax,%eax
f0101c24:	74 19                	je     f0101c3f <mem_init+0x888>
f0101c26:	68 fb 71 10 f0       	push   $0xf01071fb
f0101c2b:	68 5b 70 10 f0       	push   $0xf010705b
f0101c30:	68 4b 04 00 00       	push   $0x44b
f0101c35:	68 35 70 10 f0       	push   $0xf0107035
f0101c3a:	e8 01 e4 ff ff       	call   f0100040 <_panic>
	
	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c3f:	6a 02                	push   $0x2
f0101c41:	68 00 10 00 00       	push   $0x1000
f0101c46:	56                   	push   %esi
f0101c47:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0101c4d:	e8 6d f6 ff ff       	call   f01012bf <page_insert>
f0101c52:	83 c4 10             	add    $0x10,%esp
f0101c55:	85 c0                	test   %eax,%eax
f0101c57:	74 19                	je     f0101c72 <mem_init+0x8bb>
f0101c59:	68 88 69 10 f0       	push   $0xf0106988
f0101c5e:	68 5b 70 10 f0       	push   $0xf010705b
f0101c63:	68 4e 04 00 00       	push   $0x44e
f0101c68:	68 35 70 10 f0       	push   $0xf0107035
f0101c6d:	e8 ce e3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c72:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c77:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
f0101c7c:	e8 a6 ed ff ff       	call   f0100a27 <check_va2pa>
f0101c81:	89 f2                	mov    %esi,%edx
f0101c83:	2b 15 d0 0e 23 f0    	sub    0xf0230ed0,%edx
f0101c89:	c1 fa 03             	sar    $0x3,%edx
f0101c8c:	c1 e2 0c             	shl    $0xc,%edx
f0101c8f:	39 d0                	cmp    %edx,%eax
f0101c91:	74 19                	je     f0101cac <mem_init+0x8f5>
f0101c93:	68 c4 69 10 f0       	push   $0xf01069c4
f0101c98:	68 5b 70 10 f0       	push   $0xf010705b
f0101c9d:	68 4f 04 00 00       	push   $0x44f
f0101ca2:	68 35 70 10 f0       	push   $0xf0107035
f0101ca7:	e8 94 e3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101cac:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101cb1:	74 19                	je     f0101ccc <mem_init+0x915>
f0101cb3:	68 6f 72 10 f0       	push   $0xf010726f
f0101cb8:	68 5b 70 10 f0       	push   $0xf010705b
f0101cbd:	68 50 04 00 00       	push   $0x450
f0101cc2:	68 35 70 10 f0       	push   $0xf0107035
f0101cc7:	e8 74 e3 ff ff       	call   f0100040 <_panic>
	
	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101ccc:	83 ec 0c             	sub    $0xc,%esp
f0101ccf:	6a 00                	push   $0x0
f0101cd1:	e8 c3 f2 ff ff       	call   f0100f99 <page_alloc>
f0101cd6:	83 c4 10             	add    $0x10,%esp
f0101cd9:	85 c0                	test   %eax,%eax
f0101cdb:	74 19                	je     f0101cf6 <mem_init+0x93f>
f0101cdd:	68 fb 71 10 f0       	push   $0xf01071fb
f0101ce2:	68 5b 70 10 f0       	push   $0xf010705b
f0101ce7:	68 54 04 00 00       	push   $0x454
f0101cec:	68 35 70 10 f0       	push   $0xf0107035
f0101cf1:	e8 4a e3 ff ff       	call   f0100040 <_panic>
	
	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101cf6:	8b 15 cc 0e 23 f0    	mov    0xf0230ecc,%edx
f0101cfc:	8b 02                	mov    (%edx),%eax
f0101cfe:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101d03:	89 c1                	mov    %eax,%ecx
f0101d05:	c1 e9 0c             	shr    $0xc,%ecx
f0101d08:	3b 0d c8 0e 23 f0    	cmp    0xf0230ec8,%ecx
f0101d0e:	72 15                	jb     f0101d25 <mem_init+0x96e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d10:	50                   	push   %eax
f0101d11:	68 a4 60 10 f0       	push   $0xf01060a4
f0101d16:	68 57 04 00 00       	push   $0x457
f0101d1b:	68 35 70 10 f0       	push   $0xf0107035
f0101d20:	e8 1b e3 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101d25:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d2a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d2d:	83 ec 04             	sub    $0x4,%esp
f0101d30:	6a 00                	push   $0x0
f0101d32:	68 00 10 00 00       	push   $0x1000
f0101d37:	52                   	push   %edx
f0101d38:	e8 4a f3 ff ff       	call   f0101087 <pgdir_walk>
f0101d3d:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101d40:	8d 51 04             	lea    0x4(%ecx),%edx
f0101d43:	83 c4 10             	add    $0x10,%esp
f0101d46:	39 d0                	cmp    %edx,%eax
f0101d48:	74 19                	je     f0101d63 <mem_init+0x9ac>
f0101d4a:	68 f4 69 10 f0       	push   $0xf01069f4
f0101d4f:	68 5b 70 10 f0       	push   $0xf010705b
f0101d54:	68 58 04 00 00       	push   $0x458
f0101d59:	68 35 70 10 f0       	push   $0xf0107035
f0101d5e:	e8 dd e2 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101d63:	6a 06                	push   $0x6
f0101d65:	68 00 10 00 00       	push   $0x1000
f0101d6a:	56                   	push   %esi
f0101d6b:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0101d71:	e8 49 f5 ff ff       	call   f01012bf <page_insert>
f0101d76:	83 c4 10             	add    $0x10,%esp
f0101d79:	85 c0                	test   %eax,%eax
f0101d7b:	74 19                	je     f0101d96 <mem_init+0x9df>
f0101d7d:	68 34 6a 10 f0       	push   $0xf0106a34
f0101d82:	68 5b 70 10 f0       	push   $0xf010705b
f0101d87:	68 5b 04 00 00       	push   $0x45b
f0101d8c:	68 35 70 10 f0       	push   $0xf0107035
f0101d91:	e8 aa e2 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d96:	8b 3d cc 0e 23 f0    	mov    0xf0230ecc,%edi
f0101d9c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101da1:	89 f8                	mov    %edi,%eax
f0101da3:	e8 7f ec ff ff       	call   f0100a27 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101da8:	89 f2                	mov    %esi,%edx
f0101daa:	2b 15 d0 0e 23 f0    	sub    0xf0230ed0,%edx
f0101db0:	c1 fa 03             	sar    $0x3,%edx
f0101db3:	c1 e2 0c             	shl    $0xc,%edx
f0101db6:	39 d0                	cmp    %edx,%eax
f0101db8:	74 19                	je     f0101dd3 <mem_init+0xa1c>
f0101dba:	68 c4 69 10 f0       	push   $0xf01069c4
f0101dbf:	68 5b 70 10 f0       	push   $0xf010705b
f0101dc4:	68 5c 04 00 00       	push   $0x45c
f0101dc9:	68 35 70 10 f0       	push   $0xf0107035
f0101dce:	e8 6d e2 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101dd3:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101dd8:	74 19                	je     f0101df3 <mem_init+0xa3c>
f0101dda:	68 6f 72 10 f0       	push   $0xf010726f
f0101ddf:	68 5b 70 10 f0       	push   $0xf010705b
f0101de4:	68 5d 04 00 00       	push   $0x45d
f0101de9:	68 35 70 10 f0       	push   $0xf0107035
f0101dee:	e8 4d e2 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101df3:	83 ec 04             	sub    $0x4,%esp
f0101df6:	6a 00                	push   $0x0
f0101df8:	68 00 10 00 00       	push   $0x1000
f0101dfd:	57                   	push   %edi
f0101dfe:	e8 84 f2 ff ff       	call   f0101087 <pgdir_walk>
f0101e03:	83 c4 10             	add    $0x10,%esp
f0101e06:	f6 00 04             	testb  $0x4,(%eax)
f0101e09:	75 19                	jne    f0101e24 <mem_init+0xa6d>
f0101e0b:	68 74 6a 10 f0       	push   $0xf0106a74
f0101e10:	68 5b 70 10 f0       	push   $0xf010705b
f0101e15:	68 5e 04 00 00       	push   $0x45e
f0101e1a:	68 35 70 10 f0       	push   $0xf0107035
f0101e1f:	e8 1c e2 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101e24:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
f0101e29:	f6 00 04             	testb  $0x4,(%eax)
f0101e2c:	75 19                	jne    f0101e47 <mem_init+0xa90>
f0101e2e:	68 80 72 10 f0       	push   $0xf0107280
f0101e33:	68 5b 70 10 f0       	push   $0xf010705b
f0101e38:	68 5f 04 00 00       	push   $0x45f
f0101e3d:	68 35 70 10 f0       	push   $0xf0107035
f0101e42:	e8 f9 e1 ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e47:	6a 02                	push   $0x2
f0101e49:	68 00 10 00 00       	push   $0x1000
f0101e4e:	56                   	push   %esi
f0101e4f:	50                   	push   %eax
f0101e50:	e8 6a f4 ff ff       	call   f01012bf <page_insert>
f0101e55:	83 c4 10             	add    $0x10,%esp
f0101e58:	85 c0                	test   %eax,%eax
f0101e5a:	74 19                	je     f0101e75 <mem_init+0xabe>
f0101e5c:	68 88 69 10 f0       	push   $0xf0106988
f0101e61:	68 5b 70 10 f0       	push   $0xf010705b
f0101e66:	68 62 04 00 00       	push   $0x462
f0101e6b:	68 35 70 10 f0       	push   $0xf0107035
f0101e70:	e8 cb e1 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101e75:	83 ec 04             	sub    $0x4,%esp
f0101e78:	6a 00                	push   $0x0
f0101e7a:	68 00 10 00 00       	push   $0x1000
f0101e7f:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0101e85:	e8 fd f1 ff ff       	call   f0101087 <pgdir_walk>
f0101e8a:	83 c4 10             	add    $0x10,%esp
f0101e8d:	f6 00 02             	testb  $0x2,(%eax)
f0101e90:	75 19                	jne    f0101eab <mem_init+0xaf4>
f0101e92:	68 a8 6a 10 f0       	push   $0xf0106aa8
f0101e97:	68 5b 70 10 f0       	push   $0xf010705b
f0101e9c:	68 63 04 00 00       	push   $0x463
f0101ea1:	68 35 70 10 f0       	push   $0xf0107035
f0101ea6:	e8 95 e1 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101eab:	83 ec 04             	sub    $0x4,%esp
f0101eae:	6a 00                	push   $0x0
f0101eb0:	68 00 10 00 00       	push   $0x1000
f0101eb5:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0101ebb:	e8 c7 f1 ff ff       	call   f0101087 <pgdir_walk>
f0101ec0:	83 c4 10             	add    $0x10,%esp
f0101ec3:	f6 00 04             	testb  $0x4,(%eax)
f0101ec6:	74 19                	je     f0101ee1 <mem_init+0xb2a>
f0101ec8:	68 dc 6a 10 f0       	push   $0xf0106adc
f0101ecd:	68 5b 70 10 f0       	push   $0xf010705b
f0101ed2:	68 64 04 00 00       	push   $0x464
f0101ed7:	68 35 70 10 f0       	push   $0xf0107035
f0101edc:	e8 5f e1 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101ee1:	6a 02                	push   $0x2
f0101ee3:	68 00 00 40 00       	push   $0x400000
f0101ee8:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101eeb:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0101ef1:	e8 c9 f3 ff ff       	call   f01012bf <page_insert>
f0101ef6:	83 c4 10             	add    $0x10,%esp
f0101ef9:	85 c0                	test   %eax,%eax
f0101efb:	78 19                	js     f0101f16 <mem_init+0xb5f>
f0101efd:	68 14 6b 10 f0       	push   $0xf0106b14
f0101f02:	68 5b 70 10 f0       	push   $0xf010705b
f0101f07:	68 67 04 00 00       	push   $0x467
f0101f0c:	68 35 70 10 f0       	push   $0xf0107035
f0101f11:	e8 2a e1 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101f16:	6a 02                	push   $0x2
f0101f18:	68 00 10 00 00       	push   $0x1000
f0101f1d:	53                   	push   %ebx
f0101f1e:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0101f24:	e8 96 f3 ff ff       	call   f01012bf <page_insert>
f0101f29:	83 c4 10             	add    $0x10,%esp
f0101f2c:	85 c0                	test   %eax,%eax
f0101f2e:	74 19                	je     f0101f49 <mem_init+0xb92>
f0101f30:	68 4c 6b 10 f0       	push   $0xf0106b4c
f0101f35:	68 5b 70 10 f0       	push   $0xf010705b
f0101f3a:	68 6a 04 00 00       	push   $0x46a
f0101f3f:	68 35 70 10 f0       	push   $0xf0107035
f0101f44:	e8 f7 e0 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f49:	83 ec 04             	sub    $0x4,%esp
f0101f4c:	6a 00                	push   $0x0
f0101f4e:	68 00 10 00 00       	push   $0x1000
f0101f53:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0101f59:	e8 29 f1 ff ff       	call   f0101087 <pgdir_walk>
f0101f5e:	83 c4 10             	add    $0x10,%esp
f0101f61:	f6 00 04             	testb  $0x4,(%eax)
f0101f64:	74 19                	je     f0101f7f <mem_init+0xbc8>
f0101f66:	68 dc 6a 10 f0       	push   $0xf0106adc
f0101f6b:	68 5b 70 10 f0       	push   $0xf010705b
f0101f70:	68 6b 04 00 00       	push   $0x46b
f0101f75:	68 35 70 10 f0       	push   $0xf0107035
f0101f7a:	e8 c1 e0 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101f7f:	8b 3d cc 0e 23 f0    	mov    0xf0230ecc,%edi
f0101f85:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f8a:	89 f8                	mov    %edi,%eax
f0101f8c:	e8 96 ea ff ff       	call   f0100a27 <check_va2pa>
f0101f91:	89 c1                	mov    %eax,%ecx
f0101f93:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f96:	89 d8                	mov    %ebx,%eax
f0101f98:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f0101f9e:	c1 f8 03             	sar    $0x3,%eax
f0101fa1:	c1 e0 0c             	shl    $0xc,%eax
f0101fa4:	39 c1                	cmp    %eax,%ecx
f0101fa6:	74 19                	je     f0101fc1 <mem_init+0xc0a>
f0101fa8:	68 88 6b 10 f0       	push   $0xf0106b88
f0101fad:	68 5b 70 10 f0       	push   $0xf010705b
f0101fb2:	68 6e 04 00 00       	push   $0x46e
f0101fb7:	68 35 70 10 f0       	push   $0xf0107035
f0101fbc:	e8 7f e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101fc1:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fc6:	89 f8                	mov    %edi,%eax
f0101fc8:	e8 5a ea ff ff       	call   f0100a27 <check_va2pa>
f0101fcd:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101fd0:	74 19                	je     f0101feb <mem_init+0xc34>
f0101fd2:	68 b4 6b 10 f0       	push   $0xf0106bb4
f0101fd7:	68 5b 70 10 f0       	push   $0xf010705b
f0101fdc:	68 6f 04 00 00       	push   $0x46f
f0101fe1:	68 35 70 10 f0       	push   $0xf0107035
f0101fe6:	e8 55 e0 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101feb:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101ff0:	74 19                	je     f010200b <mem_init+0xc54>
f0101ff2:	68 96 72 10 f0       	push   $0xf0107296
f0101ff7:	68 5b 70 10 f0       	push   $0xf010705b
f0101ffc:	68 71 04 00 00       	push   $0x471
f0102001:	68 35 70 10 f0       	push   $0xf0107035
f0102006:	e8 35 e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010200b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102010:	74 19                	je     f010202b <mem_init+0xc74>
f0102012:	68 a7 72 10 f0       	push   $0xf01072a7
f0102017:	68 5b 70 10 f0       	push   $0xf010705b
f010201c:	68 72 04 00 00       	push   $0x472
f0102021:	68 35 70 10 f0       	push   $0xf0107035
f0102026:	e8 15 e0 ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f010202b:	83 ec 0c             	sub    $0xc,%esp
f010202e:	6a 00                	push   $0x0
f0102030:	e8 64 ef ff ff       	call   f0100f99 <page_alloc>
f0102035:	83 c4 10             	add    $0x10,%esp
f0102038:	85 c0                	test   %eax,%eax
f010203a:	74 04                	je     f0102040 <mem_init+0xc89>
f010203c:	39 c6                	cmp    %eax,%esi
f010203e:	74 19                	je     f0102059 <mem_init+0xca2>
f0102040:	68 e4 6b 10 f0       	push   $0xf0106be4
f0102045:	68 5b 70 10 f0       	push   $0xf010705b
f010204a:	68 75 04 00 00       	push   $0x475
f010204f:	68 35 70 10 f0       	push   $0xf0107035
f0102054:	e8 e7 df ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102059:	83 ec 08             	sub    $0x8,%esp
f010205c:	6a 00                	push   $0x0
f010205e:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0102064:	e8 10 f2 ff ff       	call   f0101279 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102069:	8b 3d cc 0e 23 f0    	mov    0xf0230ecc,%edi
f010206f:	ba 00 00 00 00       	mov    $0x0,%edx
f0102074:	89 f8                	mov    %edi,%eax
f0102076:	e8 ac e9 ff ff       	call   f0100a27 <check_va2pa>
f010207b:	83 c4 10             	add    $0x10,%esp
f010207e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102081:	74 19                	je     f010209c <mem_init+0xce5>
f0102083:	68 08 6c 10 f0       	push   $0xf0106c08
f0102088:	68 5b 70 10 f0       	push   $0xf010705b
f010208d:	68 79 04 00 00       	push   $0x479
f0102092:	68 35 70 10 f0       	push   $0xf0107035
f0102097:	e8 a4 df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010209c:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020a1:	89 f8                	mov    %edi,%eax
f01020a3:	e8 7f e9 ff ff       	call   f0100a27 <check_va2pa>
f01020a8:	89 da                	mov    %ebx,%edx
f01020aa:	2b 15 d0 0e 23 f0    	sub    0xf0230ed0,%edx
f01020b0:	c1 fa 03             	sar    $0x3,%edx
f01020b3:	c1 e2 0c             	shl    $0xc,%edx
f01020b6:	39 d0                	cmp    %edx,%eax
f01020b8:	74 19                	je     f01020d3 <mem_init+0xd1c>
f01020ba:	68 b4 6b 10 f0       	push   $0xf0106bb4
f01020bf:	68 5b 70 10 f0       	push   $0xf010705b
f01020c4:	68 7a 04 00 00       	push   $0x47a
f01020c9:	68 35 70 10 f0       	push   $0xf0107035
f01020ce:	e8 6d df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f01020d3:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01020d8:	74 19                	je     f01020f3 <mem_init+0xd3c>
f01020da:	68 4d 72 10 f0       	push   $0xf010724d
f01020df:	68 5b 70 10 f0       	push   $0xf010705b
f01020e4:	68 7b 04 00 00       	push   $0x47b
f01020e9:	68 35 70 10 f0       	push   $0xf0107035
f01020ee:	e8 4d df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01020f3:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01020f8:	74 19                	je     f0102113 <mem_init+0xd5c>
f01020fa:	68 a7 72 10 f0       	push   $0xf01072a7
f01020ff:	68 5b 70 10 f0       	push   $0xf010705b
f0102104:	68 7c 04 00 00       	push   $0x47c
f0102109:	68 35 70 10 f0       	push   $0xf0107035
f010210e:	e8 2d df ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102113:	6a 00                	push   $0x0
f0102115:	68 00 10 00 00       	push   $0x1000
f010211a:	53                   	push   %ebx
f010211b:	57                   	push   %edi
f010211c:	e8 9e f1 ff ff       	call   f01012bf <page_insert>
f0102121:	83 c4 10             	add    $0x10,%esp
f0102124:	85 c0                	test   %eax,%eax
f0102126:	74 19                	je     f0102141 <mem_init+0xd8a>
f0102128:	68 2c 6c 10 f0       	push   $0xf0106c2c
f010212d:	68 5b 70 10 f0       	push   $0xf010705b
f0102132:	68 7f 04 00 00       	push   $0x47f
f0102137:	68 35 70 10 f0       	push   $0xf0107035
f010213c:	e8 ff de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f0102141:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102146:	75 19                	jne    f0102161 <mem_init+0xdaa>
f0102148:	68 b8 72 10 f0       	push   $0xf01072b8
f010214d:	68 5b 70 10 f0       	push   $0xf010705b
f0102152:	68 80 04 00 00       	push   $0x480
f0102157:	68 35 70 10 f0       	push   $0xf0107035
f010215c:	e8 df de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0102161:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102164:	74 19                	je     f010217f <mem_init+0xdc8>
f0102166:	68 c4 72 10 f0       	push   $0xf01072c4
f010216b:	68 5b 70 10 f0       	push   $0xf010705b
f0102170:	68 81 04 00 00       	push   $0x481
f0102175:	68 35 70 10 f0       	push   $0xf0107035
f010217a:	e8 c1 de ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f010217f:	83 ec 08             	sub    $0x8,%esp
f0102182:	68 00 10 00 00       	push   $0x1000
f0102187:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f010218d:	e8 e7 f0 ff ff       	call   f0101279 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102192:	8b 3d cc 0e 23 f0    	mov    0xf0230ecc,%edi
f0102198:	ba 00 00 00 00       	mov    $0x0,%edx
f010219d:	89 f8                	mov    %edi,%eax
f010219f:	e8 83 e8 ff ff       	call   f0100a27 <check_va2pa>
f01021a4:	83 c4 10             	add    $0x10,%esp
f01021a7:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021aa:	74 19                	je     f01021c5 <mem_init+0xe0e>
f01021ac:	68 08 6c 10 f0       	push   $0xf0106c08
f01021b1:	68 5b 70 10 f0       	push   $0xf010705b
f01021b6:	68 85 04 00 00       	push   $0x485
f01021bb:	68 35 70 10 f0       	push   $0xf0107035
f01021c0:	e8 7b de ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01021c5:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021ca:	89 f8                	mov    %edi,%eax
f01021cc:	e8 56 e8 ff ff       	call   f0100a27 <check_va2pa>
f01021d1:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021d4:	74 19                	je     f01021ef <mem_init+0xe38>
f01021d6:	68 64 6c 10 f0       	push   $0xf0106c64
f01021db:	68 5b 70 10 f0       	push   $0xf010705b
f01021e0:	68 86 04 00 00       	push   $0x486
f01021e5:	68 35 70 10 f0       	push   $0xf0107035
f01021ea:	e8 51 de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f01021ef:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01021f4:	74 19                	je     f010220f <mem_init+0xe58>
f01021f6:	68 d9 72 10 f0       	push   $0xf01072d9
f01021fb:	68 5b 70 10 f0       	push   $0xf010705b
f0102200:	68 87 04 00 00       	push   $0x487
f0102205:	68 35 70 10 f0       	push   $0xf0107035
f010220a:	e8 31 de ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010220f:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102214:	74 19                	je     f010222f <mem_init+0xe78>
f0102216:	68 a7 72 10 f0       	push   $0xf01072a7
f010221b:	68 5b 70 10 f0       	push   $0xf010705b
f0102220:	68 88 04 00 00       	push   $0x488
f0102225:	68 35 70 10 f0       	push   $0xf0107035
f010222a:	e8 11 de ff ff       	call   f0100040 <_panic>
	
	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010222f:	83 ec 0c             	sub    $0xc,%esp
f0102232:	6a 00                	push   $0x0
f0102234:	e8 60 ed ff ff       	call   f0100f99 <page_alloc>
f0102239:	83 c4 10             	add    $0x10,%esp
f010223c:	85 c0                	test   %eax,%eax
f010223e:	74 04                	je     f0102244 <mem_init+0xe8d>
f0102240:	39 c3                	cmp    %eax,%ebx
f0102242:	74 19                	je     f010225d <mem_init+0xea6>
f0102244:	68 8c 6c 10 f0       	push   $0xf0106c8c
f0102249:	68 5b 70 10 f0       	push   $0xf010705b
f010224e:	68 8b 04 00 00       	push   $0x48b
f0102253:	68 35 70 10 f0       	push   $0xf0107035
f0102258:	e8 e3 dd ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010225d:	83 ec 0c             	sub    $0xc,%esp
f0102260:	6a 00                	push   $0x0
f0102262:	e8 32 ed ff ff       	call   f0100f99 <page_alloc>
f0102267:	83 c4 10             	add    $0x10,%esp
f010226a:	85 c0                	test   %eax,%eax
f010226c:	74 19                	je     f0102287 <mem_init+0xed0>
f010226e:	68 fb 71 10 f0       	push   $0xf01071fb
f0102273:	68 5b 70 10 f0       	push   $0xf010705b
f0102278:	68 8e 04 00 00       	push   $0x48e
f010227d:	68 35 70 10 f0       	push   $0xf0107035
f0102282:	e8 b9 dd ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102287:	8b 0d cc 0e 23 f0    	mov    0xf0230ecc,%ecx
f010228d:	8b 11                	mov    (%ecx),%edx
f010228f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102295:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102298:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f010229e:	c1 f8 03             	sar    $0x3,%eax
f01022a1:	c1 e0 0c             	shl    $0xc,%eax
f01022a4:	39 c2                	cmp    %eax,%edx
f01022a6:	74 19                	je     f01022c1 <mem_init+0xf0a>
f01022a8:	68 30 69 10 f0       	push   $0xf0106930
f01022ad:	68 5b 70 10 f0       	push   $0xf010705b
f01022b2:	68 91 04 00 00       	push   $0x491
f01022b7:	68 35 70 10 f0       	push   $0xf0107035
f01022bc:	e8 7f dd ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f01022c1:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01022c7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022ca:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01022cf:	74 19                	je     f01022ea <mem_init+0xf33>
f01022d1:	68 5e 72 10 f0       	push   $0xf010725e
f01022d6:	68 5b 70 10 f0       	push   $0xf010705b
f01022db:	68 93 04 00 00       	push   $0x493
f01022e0:	68 35 70 10 f0       	push   $0xf0107035
f01022e5:	e8 56 dd ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f01022ea:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022ed:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01022f3:	83 ec 0c             	sub    $0xc,%esp
f01022f6:	50                   	push   %eax
f01022f7:	e8 13 ed ff ff       	call   f010100f <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01022fc:	83 c4 0c             	add    $0xc,%esp
f01022ff:	6a 01                	push   $0x1
f0102301:	68 00 10 40 00       	push   $0x401000
f0102306:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f010230c:	e8 76 ed ff ff       	call   f0101087 <pgdir_walk>
f0102311:	89 c7                	mov    %eax,%edi
f0102313:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102316:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
f010231b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010231e:	8b 40 04             	mov    0x4(%eax),%eax
f0102321:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102326:	8b 0d c8 0e 23 f0    	mov    0xf0230ec8,%ecx
f010232c:	89 c2                	mov    %eax,%edx
f010232e:	c1 ea 0c             	shr    $0xc,%edx
f0102331:	83 c4 10             	add    $0x10,%esp
f0102334:	39 ca                	cmp    %ecx,%edx
f0102336:	72 15                	jb     f010234d <mem_init+0xf96>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102338:	50                   	push   %eax
f0102339:	68 a4 60 10 f0       	push   $0xf01060a4
f010233e:	68 9a 04 00 00       	push   $0x49a
f0102343:	68 35 70 10 f0       	push   $0xf0107035
f0102348:	e8 f3 dc ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010234d:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0102352:	39 c7                	cmp    %eax,%edi
f0102354:	74 19                	je     f010236f <mem_init+0xfb8>
f0102356:	68 ea 72 10 f0       	push   $0xf01072ea
f010235b:	68 5b 70 10 f0       	push   $0xf010705b
f0102360:	68 9b 04 00 00       	push   $0x49b
f0102365:	68 35 70 10 f0       	push   $0xf0107035
f010236a:	e8 d1 dc ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010236f:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102372:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102379:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010237c:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102382:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f0102388:	c1 f8 03             	sar    $0x3,%eax
f010238b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010238e:	89 c2                	mov    %eax,%edx
f0102390:	c1 ea 0c             	shr    $0xc,%edx
f0102393:	39 d1                	cmp    %edx,%ecx
f0102395:	77 12                	ja     f01023a9 <mem_init+0xff2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102397:	50                   	push   %eax
f0102398:	68 a4 60 10 f0       	push   $0xf01060a4
f010239d:	6a 58                	push   $0x58
f010239f:	68 41 70 10 f0       	push   $0xf0107041
f01023a4:	e8 97 dc ff ff       	call   f0100040 <_panic>
	
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01023a9:	83 ec 04             	sub    $0x4,%esp
f01023ac:	68 00 10 00 00       	push   $0x1000
f01023b1:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f01023b6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01023bb:	50                   	push   %eax
f01023bc:	e8 e7 2f 00 00       	call   f01053a8 <memset>
	page_free(pp0);
f01023c1:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01023c4:	89 3c 24             	mov    %edi,(%esp)
f01023c7:	e8 43 ec ff ff       	call   f010100f <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01023cc:	83 c4 0c             	add    $0xc,%esp
f01023cf:	6a 01                	push   $0x1
f01023d1:	6a 00                	push   $0x0
f01023d3:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f01023d9:	e8 a9 ec ff ff       	call   f0101087 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01023de:	89 fa                	mov    %edi,%edx
f01023e0:	2b 15 d0 0e 23 f0    	sub    0xf0230ed0,%edx
f01023e6:	c1 fa 03             	sar    $0x3,%edx
f01023e9:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01023ec:	89 d0                	mov    %edx,%eax
f01023ee:	c1 e8 0c             	shr    $0xc,%eax
f01023f1:	83 c4 10             	add    $0x10,%esp
f01023f4:	3b 05 c8 0e 23 f0    	cmp    0xf0230ec8,%eax
f01023fa:	72 12                	jb     f010240e <mem_init+0x1057>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01023fc:	52                   	push   %edx
f01023fd:	68 a4 60 10 f0       	push   $0xf01060a4
f0102402:	6a 58                	push   $0x58
f0102404:	68 41 70 10 f0       	push   $0xf0107041
f0102409:	e8 32 dc ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010240e:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102414:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102417:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010241d:	f6 00 01             	testb  $0x1,(%eax)
f0102420:	74 19                	je     f010243b <mem_init+0x1084>
f0102422:	68 02 73 10 f0       	push   $0xf0107302
f0102427:	68 5b 70 10 f0       	push   $0xf010705b
f010242c:	68 a5 04 00 00       	push   $0x4a5
f0102431:	68 35 70 10 f0       	push   $0xf0107035
f0102436:	e8 05 dc ff ff       	call   f0100040 <_panic>
f010243b:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010243e:	39 d0                	cmp    %edx,%eax
f0102440:	75 db                	jne    f010241d <mem_init+0x1066>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102442:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
f0102447:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010244d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102450:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102456:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102459:	89 0d 64 02 23 f0    	mov    %ecx,0xf0230264

	// free the pages we took
	page_free(pp0);
f010245f:	83 ec 0c             	sub    $0xc,%esp
f0102462:	50                   	push   %eax
f0102463:	e8 a7 eb ff ff       	call   f010100f <page_free>
	page_free(pp1);
f0102468:	89 1c 24             	mov    %ebx,(%esp)
f010246b:	e8 9f eb ff ff       	call   f010100f <page_free>
	page_free(pp2);
f0102470:	89 34 24             	mov    %esi,(%esp)
f0102473:	e8 97 eb ff ff       	call   f010100f <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f0102478:	83 c4 08             	add    $0x8,%esp
f010247b:	68 01 10 00 00       	push   $0x1001
f0102480:	6a 00                	push   $0x0
f0102482:	e8 f1 ee ff ff       	call   f0101378 <mmio_map_region>
f0102487:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f0102489:	83 c4 08             	add    $0x8,%esp
f010248c:	68 00 10 00 00       	push   $0x1000
f0102491:	6a 00                	push   $0x0
f0102493:	e8 e0 ee ff ff       	call   f0101378 <mmio_map_region>
f0102498:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f010249a:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f01024a0:	83 c4 10             	add    $0x10,%esp
f01024a3:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f01024a8:	77 08                	ja     f01024b2 <mem_init+0x10fb>
f01024aa:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f01024b0:	77 19                	ja     f01024cb <mem_init+0x1114>
f01024b2:	68 b0 6c 10 f0       	push   $0xf0106cb0
f01024b7:	68 5b 70 10 f0       	push   $0xf010705b
f01024bc:	68 b5 04 00 00       	push   $0x4b5
f01024c1:	68 35 70 10 f0       	push   $0xf0107035
f01024c6:	e8 75 db ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f01024cb:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f01024d1:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f01024d7:	77 08                	ja     f01024e1 <mem_init+0x112a>
f01024d9:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01024df:	77 19                	ja     f01024fa <mem_init+0x1143>
f01024e1:	68 d8 6c 10 f0       	push   $0xf0106cd8
f01024e6:	68 5b 70 10 f0       	push   $0xf010705b
f01024eb:	68 b6 04 00 00       	push   $0x4b6
f01024f0:	68 35 70 10 f0       	push   $0xf0107035
f01024f5:	e8 46 db ff ff       	call   f0100040 <_panic>
f01024fa:	89 da                	mov    %ebx,%edx
f01024fc:	09 f2                	or     %esi,%edx
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f01024fe:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0102504:	74 19                	je     f010251f <mem_init+0x1168>
f0102506:	68 00 6d 10 f0       	push   $0xf0106d00
f010250b:	68 5b 70 10 f0       	push   $0xf010705b
f0102510:	68 b8 04 00 00       	push   $0x4b8
f0102515:	68 35 70 10 f0       	push   $0xf0107035
f010251a:	e8 21 db ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f010251f:	39 c6                	cmp    %eax,%esi
f0102521:	73 19                	jae    f010253c <mem_init+0x1185>
f0102523:	68 19 73 10 f0       	push   $0xf0107319
f0102528:	68 5b 70 10 f0       	push   $0xf010705b
f010252d:	68 ba 04 00 00       	push   $0x4ba
f0102532:	68 35 70 10 f0       	push   $0xf0107035
f0102537:	e8 04 db ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f010253c:	8b 3d cc 0e 23 f0    	mov    0xf0230ecc,%edi
f0102542:	89 da                	mov    %ebx,%edx
f0102544:	89 f8                	mov    %edi,%eax
f0102546:	e8 dc e4 ff ff       	call   f0100a27 <check_va2pa>
f010254b:	85 c0                	test   %eax,%eax
f010254d:	74 19                	je     f0102568 <mem_init+0x11b1>
f010254f:	68 28 6d 10 f0       	push   $0xf0106d28
f0102554:	68 5b 70 10 f0       	push   $0xf010705b
f0102559:	68 bc 04 00 00       	push   $0x4bc
f010255e:	68 35 70 10 f0       	push   $0xf0107035
f0102563:	e8 d8 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102568:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f010256e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102571:	89 c2                	mov    %eax,%edx
f0102573:	89 f8                	mov    %edi,%eax
f0102575:	e8 ad e4 ff ff       	call   f0100a27 <check_va2pa>
f010257a:	3d 00 10 00 00       	cmp    $0x1000,%eax
f010257f:	74 19                	je     f010259a <mem_init+0x11e3>
f0102581:	68 4c 6d 10 f0       	push   $0xf0106d4c
f0102586:	68 5b 70 10 f0       	push   $0xf010705b
f010258b:	68 bd 04 00 00       	push   $0x4bd
f0102590:	68 35 70 10 f0       	push   $0xf0107035
f0102595:	e8 a6 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f010259a:	89 f2                	mov    %esi,%edx
f010259c:	89 f8                	mov    %edi,%eax
f010259e:	e8 84 e4 ff ff       	call   f0100a27 <check_va2pa>
f01025a3:	85 c0                	test   %eax,%eax
f01025a5:	74 19                	je     f01025c0 <mem_init+0x1209>
f01025a7:	68 7c 6d 10 f0       	push   $0xf0106d7c
f01025ac:	68 5b 70 10 f0       	push   $0xf010705b
f01025b1:	68 be 04 00 00       	push   $0x4be
f01025b6:	68 35 70 10 f0       	push   $0xf0107035
f01025bb:	e8 80 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f01025c0:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f01025c6:	89 f8                	mov    %edi,%eax
f01025c8:	e8 5a e4 ff ff       	call   f0100a27 <check_va2pa>
f01025cd:	83 f8 ff             	cmp    $0xffffffff,%eax
f01025d0:	74 19                	je     f01025eb <mem_init+0x1234>
f01025d2:	68 a0 6d 10 f0       	push   $0xf0106da0
f01025d7:	68 5b 70 10 f0       	push   $0xf010705b
f01025dc:	68 bf 04 00 00       	push   $0x4bf
f01025e1:	68 35 70 10 f0       	push   $0xf0107035
f01025e6:	e8 55 da ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f01025eb:	83 ec 04             	sub    $0x4,%esp
f01025ee:	6a 00                	push   $0x0
f01025f0:	53                   	push   %ebx
f01025f1:	57                   	push   %edi
f01025f2:	e8 90 ea ff ff       	call   f0101087 <pgdir_walk>
f01025f7:	83 c4 10             	add    $0x10,%esp
f01025fa:	f6 00 1a             	testb  $0x1a,(%eax)
f01025fd:	75 19                	jne    f0102618 <mem_init+0x1261>
f01025ff:	68 cc 6d 10 f0       	push   $0xf0106dcc
f0102604:	68 5b 70 10 f0       	push   $0xf010705b
f0102609:	68 c1 04 00 00       	push   $0x4c1
f010260e:	68 35 70 10 f0       	push   $0xf0107035
f0102613:	e8 28 da ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102618:	83 ec 04             	sub    $0x4,%esp
f010261b:	6a 00                	push   $0x0
f010261d:	53                   	push   %ebx
f010261e:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0102624:	e8 5e ea ff ff       	call   f0101087 <pgdir_walk>
f0102629:	83 c4 10             	add    $0x10,%esp
f010262c:	f6 00 04             	testb  $0x4,(%eax)
f010262f:	74 19                	je     f010264a <mem_init+0x1293>
f0102631:	68 10 6e 10 f0       	push   $0xf0106e10
f0102636:	68 5b 70 10 f0       	push   $0xf010705b
f010263b:	68 c2 04 00 00       	push   $0x4c2
f0102640:	68 35 70 10 f0       	push   $0xf0107035
f0102645:	e8 f6 d9 ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f010264a:	83 ec 04             	sub    $0x4,%esp
f010264d:	6a 00                	push   $0x0
f010264f:	53                   	push   %ebx
f0102650:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0102656:	e8 2c ea ff ff       	call   f0101087 <pgdir_walk>
f010265b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f0102661:	83 c4 0c             	add    $0xc,%esp
f0102664:	6a 00                	push   $0x0
f0102666:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102669:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f010266f:	e8 13 ea ff ff       	call   f0101087 <pgdir_walk>
f0102674:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f010267a:	83 c4 0c             	add    $0xc,%esp
f010267d:	6a 00                	push   $0x0
f010267f:	56                   	push   %esi
f0102680:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0102686:	e8 fc e9 ff ff       	call   f0101087 <pgdir_walk>
f010268b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f0102691:	c7 04 24 2b 73 10 f0 	movl   $0xf010732b,(%esp)
f0102698:	e8 b4 11 00 00       	call   f0103851 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, ROUNDUP( (sizeof(struct PageInfo)*npages),PGSIZE), PADDR(pages), PTE_U | PTE_P);
f010269d:	a1 d0 0e 23 f0       	mov    0xf0230ed0,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026a2:	83 c4 10             	add    $0x10,%esp
f01026a5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01026aa:	77 15                	ja     f01026c1 <mem_init+0x130a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026ac:	50                   	push   %eax
f01026ad:	68 c8 60 10 f0       	push   $0xf01060c8
f01026b2:	68 c5 00 00 00       	push   $0xc5
f01026b7:	68 35 70 10 f0       	push   $0xf0107035
f01026bc:	e8 7f d9 ff ff       	call   f0100040 <_panic>
f01026c1:	8b 15 c8 0e 23 f0    	mov    0xf0230ec8,%edx
f01026c7:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f01026ce:	83 ec 08             	sub    $0x8,%esp
f01026d1:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01026d7:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f01026d9:	05 00 00 00 10       	add    $0x10000000,%eax
f01026de:	50                   	push   %eax
f01026df:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01026e4:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
f01026e9:	e8 84 ea ff ff       	call   f0101172 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, sizeof(struct Env) * NENV,PADDR(envs), PTE_U);
f01026ee:	a1 6c 02 23 f0       	mov    0xf023026c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026f3:	83 c4 10             	add    $0x10,%esp
f01026f6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01026fb:	77 15                	ja     f0102712 <mem_init+0x135b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026fd:	50                   	push   %eax
f01026fe:	68 c8 60 10 f0       	push   $0xf01060c8
f0102703:	68 cd 00 00 00       	push   $0xcd
f0102708:	68 35 70 10 f0       	push   $0xf0107035
f010270d:	e8 2e d9 ff ff       	call   f0100040 <_panic>
f0102712:	83 ec 08             	sub    $0x8,%esp
f0102715:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f0102717:	05 00 00 00 10       	add    $0x10000000,%eax
f010271c:	50                   	push   %eax
f010271d:	b9 00 f0 01 00       	mov    $0x1f000,%ecx
f0102722:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102727:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
f010272c:	e8 41 ea ff ff       	call   f0101172 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102731:	83 c4 10             	add    $0x10,%esp
f0102734:	b8 00 60 11 f0       	mov    $0xf0116000,%eax
f0102739:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010273e:	77 15                	ja     f0102755 <mem_init+0x139e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102740:	50                   	push   %eax
f0102741:	68 c8 60 10 f0       	push   $0xf01060c8
f0102746:	68 d9 00 00 00       	push   $0xd9
f010274b:	68 35 70 10 f0       	push   $0xf0107035
f0102750:	e8 eb d8 ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W | PTE_P);
f0102755:	83 ec 08             	sub    $0x8,%esp
f0102758:	6a 03                	push   $0x3
f010275a:	68 00 60 11 00       	push   $0x116000
f010275f:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102764:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102769:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
f010276e:	e8 ff e9 ff ff       	call   f0101172 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	size_t size = ROUNDUP(0xFFFFFFFF - KERNBASE + 1, PGSIZE);
	boot_map_region(kern_pgdir, KERNBASE, size, 0, PTE_W | PTE_P);
f0102773:	83 c4 08             	add    $0x8,%esp
f0102776:	6a 03                	push   $0x3
f0102778:	6a 00                	push   $0x0
f010277a:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f010277f:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102784:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
f0102789:	e8 e4 e9 ff ff       	call   f0101172 <boot_map_region>
f010278e:	c7 45 c4 00 20 23 f0 	movl   $0xf0232000,-0x3c(%ebp)
f0102795:	83 c4 10             	add    $0x10,%esp
f0102798:	bb 00 20 23 f0       	mov    $0xf0232000,%ebx
f010279d:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027a2:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f01027a8:	77 15                	ja     f01027bf <mem_init+0x1408>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027aa:	53                   	push   %ebx
f01027ab:	68 c8 60 10 f0       	push   $0xf01060c8
f01027b0:	68 20 01 00 00       	push   $0x120
f01027b5:	68 35 70 10 f0       	push   $0xf0107035
f01027ba:	e8 81 d8 ff ff       	call   f0100040 <_panic>
	uint32_t percpu_stacktop = KSTACKTOP;
	//uint32_t percpu_stackbtm;
	
	for (i=0;i<NCPU;i++)
	{	
		boot_map_region(kern_pgdir, percpu_stacktop - KSTKSIZE, KSTKSIZE,PADDR((void*)percpu_kstacks[i]), PTE_W | PTE_P);
f01027bf:	83 ec 08             	sub    $0x8,%esp
f01027c2:	6a 03                	push   $0x3
f01027c4:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f01027ca:	50                   	push   %eax
f01027cb:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01027d0:	89 f2                	mov    %esi,%edx
f01027d2:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
f01027d7:	e8 96 e9 ff ff       	call   f0101172 <boot_map_region>
f01027dc:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f01027e2:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	
	int i=0;
	uint32_t percpu_stacktop = KSTACKTOP;
	//uint32_t percpu_stackbtm;
	
	for (i=0;i<NCPU;i++)
f01027e8:	83 c4 10             	add    $0x10,%esp
f01027eb:	81 fb 00 20 27 f0    	cmp    $0xf0272000,%ebx
f01027f1:	75 af                	jne    f01027a2 <mem_init+0x13eb>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01027f3:	8b 3d cc 0e 23 f0    	mov    0xf0230ecc,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01027f9:	a1 c8 0e 23 f0       	mov    0xf0230ec8,%eax
f01027fe:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102801:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102808:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010280d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102810:	8b 35 d0 0e 23 f0    	mov    0xf0230ed0,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102816:	89 75 d0             	mov    %esi,-0x30(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102819:	bb 00 00 00 00       	mov    $0x0,%ebx
f010281e:	eb 55                	jmp    f0102875 <mem_init+0x14be>
f0102820:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102826:	89 f8                	mov    %edi,%eax
f0102828:	e8 fa e1 ff ff       	call   f0100a27 <check_va2pa>
f010282d:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102834:	77 15                	ja     f010284b <mem_init+0x1494>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102836:	56                   	push   %esi
f0102837:	68 c8 60 10 f0       	push   $0xf01060c8
f010283c:	68 d7 03 00 00       	push   $0x3d7
f0102841:	68 35 70 10 f0       	push   $0xf0107035
f0102846:	e8 f5 d7 ff ff       	call   f0100040 <_panic>
f010284b:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f0102852:	39 d0                	cmp    %edx,%eax
f0102854:	74 19                	je     f010286f <mem_init+0x14b8>
f0102856:	68 44 6e 10 f0       	push   $0xf0106e44
f010285b:	68 5b 70 10 f0       	push   $0xf010705b
f0102860:	68 d7 03 00 00       	push   $0x3d7
f0102865:	68 35 70 10 f0       	push   $0xf0107035
f010286a:	e8 d1 d7 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010286f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102875:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102878:	77 a6                	ja     f0102820 <mem_init+0x1469>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f010287a:	8b 35 6c 02 23 f0    	mov    0xf023026c,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102880:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0102883:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f0102888:	89 da                	mov    %ebx,%edx
f010288a:	89 f8                	mov    %edi,%eax
f010288c:	e8 96 e1 ff ff       	call   f0100a27 <check_va2pa>
f0102891:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f0102898:	77 15                	ja     f01028af <mem_init+0x14f8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010289a:	56                   	push   %esi
f010289b:	68 c8 60 10 f0       	push   $0xf01060c8
f01028a0:	68 dc 03 00 00       	push   $0x3dc
f01028a5:	68 35 70 10 f0       	push   $0xf0107035
f01028aa:	e8 91 d7 ff ff       	call   f0100040 <_panic>
f01028af:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f01028b6:	39 d0                	cmp    %edx,%eax
f01028b8:	74 19                	je     f01028d3 <mem_init+0x151c>
f01028ba:	68 78 6e 10 f0       	push   $0xf0106e78
f01028bf:	68 5b 70 10 f0       	push   $0xf010705b
f01028c4:	68 dc 03 00 00       	push   $0x3dc
f01028c9:	68 35 70 10 f0       	push   $0xf0107035
f01028ce:	e8 6d d7 ff ff       	call   f0100040 <_panic>
f01028d3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01028d9:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f01028df:	75 a7                	jne    f0102888 <mem_init+0x14d1>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01028e1:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01028e4:	c1 e6 0c             	shl    $0xc,%esi
f01028e7:	bb 00 00 00 00       	mov    $0x0,%ebx
f01028ec:	eb 30                	jmp    f010291e <mem_init+0x1567>
f01028ee:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01028f4:	89 f8                	mov    %edi,%eax
f01028f6:	e8 2c e1 ff ff       	call   f0100a27 <check_va2pa>
f01028fb:	39 c3                	cmp    %eax,%ebx
f01028fd:	74 19                	je     f0102918 <mem_init+0x1561>
f01028ff:	68 ac 6e 10 f0       	push   $0xf0106eac
f0102904:	68 5b 70 10 f0       	push   $0xf010705b
f0102909:	68 e0 03 00 00       	push   $0x3e0
f010290e:	68 35 70 10 f0       	push   $0xf0107035
f0102913:	e8 28 d7 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102918:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010291e:	39 f3                	cmp    %esi,%ebx
f0102920:	72 cc                	jb     f01028ee <mem_init+0x1537>
f0102922:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
f0102929:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f010292e:	89 75 cc             	mov    %esi,-0x34(%ebp)
f0102931:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0102934:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102937:	8d 88 00 80 00 00    	lea    0x8000(%eax),%ecx
f010293d:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0102940:	89 c3                	mov    %eax,%ebx
f0102942:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102945:	05 00 80 00 20       	add    $0x20008000,%eax
f010294a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f010294d:	89 da                	mov    %ebx,%edx
f010294f:	89 f8                	mov    %edi,%eax
f0102951:	e8 d1 e0 ff ff       	call   f0100a27 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102956:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f010295c:	77 15                	ja     f0102973 <mem_init+0x15bc>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010295e:	56                   	push   %esi
f010295f:	68 c8 60 10 f0       	push   $0xf01060c8
f0102964:	68 e8 03 00 00       	push   $0x3e8
f0102969:	68 35 70 10 f0       	push   $0xf0107035
f010296e:	e8 cd d6 ff ff       	call   f0100040 <_panic>
f0102973:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102976:	8d 94 0b 00 20 23 f0 	lea    -0xfdce000(%ebx,%ecx,1),%edx
f010297d:	39 d0                	cmp    %edx,%eax
f010297f:	74 19                	je     f010299a <mem_init+0x15e3>
f0102981:	68 d4 6e 10 f0       	push   $0xf0106ed4
f0102986:	68 5b 70 10 f0       	push   $0xf010705b
f010298b:	68 e8 03 00 00       	push   $0x3e8
f0102990:	68 35 70 10 f0       	push   $0xf0107035
f0102995:	e8 a6 d6 ff ff       	call   f0100040 <_panic>
f010299a:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01029a0:	3b 5d d0             	cmp    -0x30(%ebp),%ebx
f01029a3:	75 a8                	jne    f010294d <mem_init+0x1596>
f01029a5:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01029a8:	8d 98 00 80 ff ff    	lea    -0x8000(%eax),%ebx
f01029ae:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01029b1:	89 c6                	mov    %eax,%esi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f01029b3:	89 da                	mov    %ebx,%edx
f01029b5:	89 f8                	mov    %edi,%eax
f01029b7:	e8 6b e0 ff ff       	call   f0100a27 <check_va2pa>
f01029bc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01029bf:	74 19                	je     f01029da <mem_init+0x1623>
f01029c1:	68 1c 6f 10 f0       	push   $0xf0106f1c
f01029c6:	68 5b 70 10 f0       	push   $0xf010705b
f01029cb:	68 ea 03 00 00       	push   $0x3ea
f01029d0:	68 35 70 10 f0       	push   $0xf0107035
f01029d5:	e8 66 d6 ff ff       	call   f0100040 <_panic>
f01029da:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f01029e0:	39 de                	cmp    %ebx,%esi
f01029e2:	75 cf                	jne    f01029b3 <mem_init+0x15fc>
f01029e4:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f01029e7:	81 6d cc 00 00 01 00 	subl   $0x10000,-0x34(%ebp)
f01029ee:	81 45 c8 00 80 01 00 	addl   $0x18000,-0x38(%ebp)
f01029f5:	81 c6 00 80 00 00    	add    $0x8000,%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f01029fb:	81 fe 00 20 27 f0    	cmp    $0xf0272000,%esi
f0102a01:	0f 85 2d ff ff ff    	jne    f0102934 <mem_init+0x157d>
f0102a07:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a0c:	eb 2a                	jmp    f0102a38 <mem_init+0x1681>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102a0e:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0102a14:	83 fa 04             	cmp    $0x4,%edx
f0102a17:	77 1f                	ja     f0102a38 <mem_init+0x1681>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f0102a19:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0102a1d:	75 7e                	jne    f0102a9d <mem_init+0x16e6>
f0102a1f:	68 44 73 10 f0       	push   $0xf0107344
f0102a24:	68 5b 70 10 f0       	push   $0xf010705b
f0102a29:	68 f5 03 00 00       	push   $0x3f5
f0102a2e:	68 35 70 10 f0       	push   $0xf0107035
f0102a33:	e8 08 d6 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102a38:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102a3d:	76 3f                	jbe    f0102a7e <mem_init+0x16c7>
				assert(pgdir[i] & PTE_P);
f0102a3f:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0102a42:	f6 c2 01             	test   $0x1,%dl
f0102a45:	75 19                	jne    f0102a60 <mem_init+0x16a9>
f0102a47:	68 44 73 10 f0       	push   $0xf0107344
f0102a4c:	68 5b 70 10 f0       	push   $0xf010705b
f0102a51:	68 f9 03 00 00       	push   $0x3f9
f0102a56:	68 35 70 10 f0       	push   $0xf0107035
f0102a5b:	e8 e0 d5 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f0102a60:	f6 c2 02             	test   $0x2,%dl
f0102a63:	75 38                	jne    f0102a9d <mem_init+0x16e6>
f0102a65:	68 55 73 10 f0       	push   $0xf0107355
f0102a6a:	68 5b 70 10 f0       	push   $0xf010705b
f0102a6f:	68 fa 03 00 00       	push   $0x3fa
f0102a74:	68 35 70 10 f0       	push   $0xf0107035
f0102a79:	e8 c2 d5 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102a7e:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102a82:	74 19                	je     f0102a9d <mem_init+0x16e6>
f0102a84:	68 66 73 10 f0       	push   $0xf0107366
f0102a89:	68 5b 70 10 f0       	push   $0xf010705b
f0102a8e:	68 fc 03 00 00       	push   $0x3fc
f0102a93:	68 35 70 10 f0       	push   $0xf0107035
f0102a98:	e8 a3 d5 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102a9d:	83 c0 01             	add    $0x1,%eax
f0102aa0:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102aa5:	0f 86 63 ff ff ff    	jbe    f0102a0e <mem_init+0x1657>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102aab:	83 ec 0c             	sub    $0xc,%esp
f0102aae:	68 40 6f 10 f0       	push   $0xf0106f40
f0102ab3:	e8 99 0d 00 00       	call   f0103851 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102ab8:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102abd:	83 c4 10             	add    $0x10,%esp
f0102ac0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102ac5:	77 15                	ja     f0102adc <mem_init+0x1725>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ac7:	50                   	push   %eax
f0102ac8:	68 c8 60 10 f0       	push   $0xf01060c8
f0102acd:	68 f2 00 00 00       	push   $0xf2
f0102ad2:	68 35 70 10 f0       	push   $0xf0107035
f0102ad7:	e8 64 d5 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102adc:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102ae1:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102ae4:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ae9:	e8 13 e0 ff ff       	call   f0100b01 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102aee:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102af1:	83 e0 f3             	and    $0xfffffff3,%eax
f0102af4:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102af9:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102afc:	83 ec 0c             	sub    $0xc,%esp
f0102aff:	6a 00                	push   $0x0
f0102b01:	e8 93 e4 ff ff       	call   f0100f99 <page_alloc>
f0102b06:	89 c3                	mov    %eax,%ebx
f0102b08:	83 c4 10             	add    $0x10,%esp
f0102b0b:	85 c0                	test   %eax,%eax
f0102b0d:	75 19                	jne    f0102b28 <mem_init+0x1771>
f0102b0f:	68 50 71 10 f0       	push   $0xf0107150
f0102b14:	68 5b 70 10 f0       	push   $0xf010705b
f0102b19:	68 d7 04 00 00       	push   $0x4d7
f0102b1e:	68 35 70 10 f0       	push   $0xf0107035
f0102b23:	e8 18 d5 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102b28:	83 ec 0c             	sub    $0xc,%esp
f0102b2b:	6a 00                	push   $0x0
f0102b2d:	e8 67 e4 ff ff       	call   f0100f99 <page_alloc>
f0102b32:	89 c7                	mov    %eax,%edi
f0102b34:	83 c4 10             	add    $0x10,%esp
f0102b37:	85 c0                	test   %eax,%eax
f0102b39:	75 19                	jne    f0102b54 <mem_init+0x179d>
f0102b3b:	68 66 71 10 f0       	push   $0xf0107166
f0102b40:	68 5b 70 10 f0       	push   $0xf010705b
f0102b45:	68 d8 04 00 00       	push   $0x4d8
f0102b4a:	68 35 70 10 f0       	push   $0xf0107035
f0102b4f:	e8 ec d4 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102b54:	83 ec 0c             	sub    $0xc,%esp
f0102b57:	6a 00                	push   $0x0
f0102b59:	e8 3b e4 ff ff       	call   f0100f99 <page_alloc>
f0102b5e:	89 c6                	mov    %eax,%esi
f0102b60:	83 c4 10             	add    $0x10,%esp
f0102b63:	85 c0                	test   %eax,%eax
f0102b65:	75 19                	jne    f0102b80 <mem_init+0x17c9>
f0102b67:	68 7c 71 10 f0       	push   $0xf010717c
f0102b6c:	68 5b 70 10 f0       	push   $0xf010705b
f0102b71:	68 d9 04 00 00       	push   $0x4d9
f0102b76:	68 35 70 10 f0       	push   $0xf0107035
f0102b7b:	e8 c0 d4 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f0102b80:	83 ec 0c             	sub    $0xc,%esp
f0102b83:	53                   	push   %ebx
f0102b84:	e8 86 e4 ff ff       	call   f010100f <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b89:	89 f8                	mov    %edi,%eax
f0102b8b:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f0102b91:	c1 f8 03             	sar    $0x3,%eax
f0102b94:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b97:	89 c2                	mov    %eax,%edx
f0102b99:	c1 ea 0c             	shr    $0xc,%edx
f0102b9c:	83 c4 10             	add    $0x10,%esp
f0102b9f:	3b 15 c8 0e 23 f0    	cmp    0xf0230ec8,%edx
f0102ba5:	72 12                	jb     f0102bb9 <mem_init+0x1802>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ba7:	50                   	push   %eax
f0102ba8:	68 a4 60 10 f0       	push   $0xf01060a4
f0102bad:	6a 58                	push   $0x58
f0102baf:	68 41 70 10 f0       	push   $0xf0107041
f0102bb4:	e8 87 d4 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102bb9:	83 ec 04             	sub    $0x4,%esp
f0102bbc:	68 00 10 00 00       	push   $0x1000
f0102bc1:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102bc3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102bc8:	50                   	push   %eax
f0102bc9:	e8 da 27 00 00       	call   f01053a8 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102bce:	89 f0                	mov    %esi,%eax
f0102bd0:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f0102bd6:	c1 f8 03             	sar    $0x3,%eax
f0102bd9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bdc:	89 c2                	mov    %eax,%edx
f0102bde:	c1 ea 0c             	shr    $0xc,%edx
f0102be1:	83 c4 10             	add    $0x10,%esp
f0102be4:	3b 15 c8 0e 23 f0    	cmp    0xf0230ec8,%edx
f0102bea:	72 12                	jb     f0102bfe <mem_init+0x1847>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bec:	50                   	push   %eax
f0102bed:	68 a4 60 10 f0       	push   $0xf01060a4
f0102bf2:	6a 58                	push   $0x58
f0102bf4:	68 41 70 10 f0       	push   $0xf0107041
f0102bf9:	e8 42 d4 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102bfe:	83 ec 04             	sub    $0x4,%esp
f0102c01:	68 00 10 00 00       	push   $0x1000
f0102c06:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102c08:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102c0d:	50                   	push   %eax
f0102c0e:	e8 95 27 00 00       	call   f01053a8 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102c13:	6a 02                	push   $0x2
f0102c15:	68 00 10 00 00       	push   $0x1000
f0102c1a:	57                   	push   %edi
f0102c1b:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0102c21:	e8 99 e6 ff ff       	call   f01012bf <page_insert>
	assert(pp1->pp_ref == 1);
f0102c26:	83 c4 20             	add    $0x20,%esp
f0102c29:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102c2e:	74 19                	je     f0102c49 <mem_init+0x1892>
f0102c30:	68 4d 72 10 f0       	push   $0xf010724d
f0102c35:	68 5b 70 10 f0       	push   $0xf010705b
f0102c3a:	68 de 04 00 00       	push   $0x4de
f0102c3f:	68 35 70 10 f0       	push   $0xf0107035
f0102c44:	e8 f7 d3 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102c49:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102c50:	01 01 01 
f0102c53:	74 19                	je     f0102c6e <mem_init+0x18b7>
f0102c55:	68 60 6f 10 f0       	push   $0xf0106f60
f0102c5a:	68 5b 70 10 f0       	push   $0xf010705b
f0102c5f:	68 df 04 00 00       	push   $0x4df
f0102c64:	68 35 70 10 f0       	push   $0xf0107035
f0102c69:	e8 d2 d3 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102c6e:	6a 02                	push   $0x2
f0102c70:	68 00 10 00 00       	push   $0x1000
f0102c75:	56                   	push   %esi
f0102c76:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0102c7c:	e8 3e e6 ff ff       	call   f01012bf <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102c81:	83 c4 10             	add    $0x10,%esp
f0102c84:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102c8b:	02 02 02 
f0102c8e:	74 19                	je     f0102ca9 <mem_init+0x18f2>
f0102c90:	68 84 6f 10 f0       	push   $0xf0106f84
f0102c95:	68 5b 70 10 f0       	push   $0xf010705b
f0102c9a:	68 e1 04 00 00       	push   $0x4e1
f0102c9f:	68 35 70 10 f0       	push   $0xf0107035
f0102ca4:	e8 97 d3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102ca9:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102cae:	74 19                	je     f0102cc9 <mem_init+0x1912>
f0102cb0:	68 6f 72 10 f0       	push   $0xf010726f
f0102cb5:	68 5b 70 10 f0       	push   $0xf010705b
f0102cba:	68 e2 04 00 00       	push   $0x4e2
f0102cbf:	68 35 70 10 f0       	push   $0xf0107035
f0102cc4:	e8 77 d3 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102cc9:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102cce:	74 19                	je     f0102ce9 <mem_init+0x1932>
f0102cd0:	68 d9 72 10 f0       	push   $0xf01072d9
f0102cd5:	68 5b 70 10 f0       	push   $0xf010705b
f0102cda:	68 e3 04 00 00       	push   $0x4e3
f0102cdf:	68 35 70 10 f0       	push   $0xf0107035
f0102ce4:	e8 57 d3 ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102ce9:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102cf0:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102cf3:	89 f0                	mov    %esi,%eax
f0102cf5:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f0102cfb:	c1 f8 03             	sar    $0x3,%eax
f0102cfe:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d01:	89 c2                	mov    %eax,%edx
f0102d03:	c1 ea 0c             	shr    $0xc,%edx
f0102d06:	3b 15 c8 0e 23 f0    	cmp    0xf0230ec8,%edx
f0102d0c:	72 12                	jb     f0102d20 <mem_init+0x1969>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102d0e:	50                   	push   %eax
f0102d0f:	68 a4 60 10 f0       	push   $0xf01060a4
f0102d14:	6a 58                	push   $0x58
f0102d16:	68 41 70 10 f0       	push   $0xf0107041
f0102d1b:	e8 20 d3 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102d20:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102d27:	03 03 03 
f0102d2a:	74 19                	je     f0102d45 <mem_init+0x198e>
f0102d2c:	68 a8 6f 10 f0       	push   $0xf0106fa8
f0102d31:	68 5b 70 10 f0       	push   $0xf010705b
f0102d36:	68 e5 04 00 00       	push   $0x4e5
f0102d3b:	68 35 70 10 f0       	push   $0xf0107035
f0102d40:	e8 fb d2 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102d45:	83 ec 08             	sub    $0x8,%esp
f0102d48:	68 00 10 00 00       	push   $0x1000
f0102d4d:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0102d53:	e8 21 e5 ff ff       	call   f0101279 <page_remove>
	assert(pp2->pp_ref == 0);
f0102d58:	83 c4 10             	add    $0x10,%esp
f0102d5b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102d60:	74 19                	je     f0102d7b <mem_init+0x19c4>
f0102d62:	68 a7 72 10 f0       	push   $0xf01072a7
f0102d67:	68 5b 70 10 f0       	push   $0xf010705b
f0102d6c:	68 e7 04 00 00       	push   $0x4e7
f0102d71:	68 35 70 10 f0       	push   $0xf0107035
f0102d76:	e8 c5 d2 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102d7b:	8b 0d cc 0e 23 f0    	mov    0xf0230ecc,%ecx
f0102d81:	8b 11                	mov    (%ecx),%edx
f0102d83:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102d89:	89 d8                	mov    %ebx,%eax
f0102d8b:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f0102d91:	c1 f8 03             	sar    $0x3,%eax
f0102d94:	c1 e0 0c             	shl    $0xc,%eax
f0102d97:	39 c2                	cmp    %eax,%edx
f0102d99:	74 19                	je     f0102db4 <mem_init+0x19fd>
f0102d9b:	68 30 69 10 f0       	push   $0xf0106930
f0102da0:	68 5b 70 10 f0       	push   $0xf010705b
f0102da5:	68 ea 04 00 00       	push   $0x4ea
f0102daa:	68 35 70 10 f0       	push   $0xf0107035
f0102daf:	e8 8c d2 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102db4:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102dba:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102dbf:	74 19                	je     f0102dda <mem_init+0x1a23>
f0102dc1:	68 5e 72 10 f0       	push   $0xf010725e
f0102dc6:	68 5b 70 10 f0       	push   $0xf010705b
f0102dcb:	68 ec 04 00 00       	push   $0x4ec
f0102dd0:	68 35 70 10 f0       	push   $0xf0107035
f0102dd5:	e8 66 d2 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102dda:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102de0:	83 ec 0c             	sub    $0xc,%esp
f0102de3:	53                   	push   %ebx
f0102de4:	e8 26 e2 ff ff       	call   f010100f <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102de9:	c7 04 24 d4 6f 10 f0 	movl   $0xf0106fd4,(%esp)
f0102df0:	e8 5c 0a 00 00       	call   f0103851 <cprintf>
f0102df5:	83 c4 10             	add    $0x10,%esp
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102df8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102dfb:	5b                   	pop    %ebx
f0102dfc:	5e                   	pop    %esi
f0102dfd:	5f                   	pop    %edi
f0102dfe:	5d                   	pop    %ebp
f0102dff:	c3                   	ret    

f0102e00 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102e00:	55                   	push   %ebp
f0102e01:	89 e5                	mov    %esp,%ebp
f0102e03:	57                   	push   %edi
f0102e04:	56                   	push   %esi
f0102e05:	53                   	push   %ebx
f0102e06:	83 ec 1c             	sub    $0x1c,%esp
f0102e09:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102e0c:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// LAB 3: Your code here.

	// step 1 : check below ULIM
  uintptr_t va_beg = (uintptr_t)va;
  uintptr_t va_end = va_beg + len;
f0102e0f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102e12:	03 75 10             	add    0x10(%ebp),%esi
  if (va_beg >= ULIM || va_end >= ULIM) {
f0102e15:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102e1b:	77 09                	ja     f0102e26 <user_mem_check+0x26>
f0102e1d:	81 7d 0c ff ff 7f ef 	cmpl   $0xef7fffff,0xc(%ebp)
f0102e24:	76 1f                	jbe    f0102e45 <user_mem_check+0x45>
    user_mem_check_addr = (va_beg >= ULIM) ? va_beg : ULIM;
f0102e26:	81 7d 0c 00 00 80 ef 	cmpl   $0xef800000,0xc(%ebp)
f0102e2d:	b8 00 00 80 ef       	mov    $0xef800000,%eax
f0102e32:	0f 43 45 0c          	cmovae 0xc(%ebp),%eax
f0102e36:	a3 60 02 23 f0       	mov    %eax,0xf0230260
    return -E_FAULT;
f0102e3b:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102e40:	e9 a7 00 00 00       	jmp    f0102eec <user_mem_check+0xec>
  }

  // step 2 : check present & permission
  uintptr_t va_beg2 = ROUNDDOWN(va_beg, PGSIZE);
f0102e45:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102e48:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  uintptr_t va_end2 = ROUNDUP(va_end, PGSIZE);
f0102e4e:	81 c6 ff 0f 00 00    	add    $0xfff,%esi
f0102e54:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102e5a:	a1 c8 0e 23 f0       	mov    0xf0230ec8,%eax
f0102e5f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102e62:	89 7d 08             	mov    %edi,0x8(%ebp)
  while (va_beg2 < va_end2) {
f0102e65:	eb 7c                	jmp    f0102ee3 <user_mem_check+0xe3>

    // check page table is present ?
    if (!(env->env_pgdir[PDX(va_beg2)] & PTE_P)) {
f0102e67:	89 d1                	mov    %edx,%ecx
f0102e69:	c1 e9 16             	shr    $0x16,%ecx
f0102e6c:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e6f:	8b 40 60             	mov    0x60(%eax),%eax
f0102e72:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0102e75:	a8 01                	test   $0x1,%al
f0102e77:	75 14                	jne    f0102e8d <user_mem_check+0x8d>
      user_mem_check_addr = (va_beg2 > va_beg) ? va_beg2 : va_beg;
f0102e79:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102e7c:	0f 42 55 0c          	cmovb  0xc(%ebp),%edx
f0102e80:	89 15 60 02 23 f0    	mov    %edx,0xf0230260
      return -E_FAULT;
f0102e86:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102e8b:	eb 5f                	jmp    f0102eec <user_mem_check+0xec>
    }

    // get current page table kernel va
    uint32_t* pt_kva = KADDR(PTE_ADDR(env->env_pgdir[PDX(va_beg2)]));
f0102e8d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102e92:	89 c1                	mov    %eax,%ecx
f0102e94:	c1 e9 0c             	shr    $0xc,%ecx
f0102e97:	3b 4d e4             	cmp    -0x1c(%ebp),%ecx
f0102e9a:	72 15                	jb     f0102eb1 <user_mem_check+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102e9c:	50                   	push   %eax
f0102e9d:	68 a4 60 10 f0       	push   $0xf01060a4
f0102ea2:	68 14 03 00 00       	push   $0x314
f0102ea7:	68 35 70 10 f0       	push   $0xf0107035
f0102eac:	e8 8f d1 ff ff       	call   f0100040 <_panic>

    // check page is present & permissions
    if (!((pt_kva[PTX(va_beg2)] & perm) == perm)) {
f0102eb1:	89 d1                	mov    %edx,%ecx
f0102eb3:	c1 e9 0c             	shr    $0xc,%ecx
f0102eb6:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
f0102ebc:	89 df                	mov    %ebx,%edi
f0102ebe:	23 bc 88 00 00 00 f0 	and    -0x10000000(%eax,%ecx,4),%edi
f0102ec5:	39 fb                	cmp    %edi,%ebx
f0102ec7:	74 14                	je     f0102edd <user_mem_check+0xdd>
      user_mem_check_addr = (va_beg2 > va_beg) ? va_beg2 : va_beg;
f0102ec9:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102ecc:	0f 42 55 0c          	cmovb  0xc(%ebp),%edx
f0102ed0:	89 15 60 02 23 f0    	mov    %edx,0xf0230260
      return -E_FAULT;
f0102ed6:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102edb:	eb 0f                	jmp    f0102eec <user_mem_check+0xec>
    }

    va_beg2 += PGSIZE;
f0102edd:	81 c2 00 10 00 00    	add    $0x1000,%edx
  }

  // step 2 : check present & permission
  uintptr_t va_beg2 = ROUNDDOWN(va_beg, PGSIZE);
  uintptr_t va_end2 = ROUNDUP(va_end, PGSIZE);
  while (va_beg2 < va_end2) {
f0102ee3:	39 f2                	cmp    %esi,%edx
f0102ee5:	72 80                	jb     f0102e67 <user_mem_check+0x67>
      return -E_FAULT;
    }

    va_beg2 += PGSIZE;
  }
  return 0;
f0102ee7:	b8 00 00 00 00       	mov    $0x0,%eax

}
f0102eec:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102eef:	5b                   	pop    %ebx
f0102ef0:	5e                   	pop    %esi
f0102ef1:	5f                   	pop    %edi
f0102ef2:	5d                   	pop    %ebp
f0102ef3:	c3                   	ret    

f0102ef4 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102ef4:	55                   	push   %ebp
f0102ef5:	89 e5                	mov    %esp,%ebp
f0102ef7:	53                   	push   %ebx
f0102ef8:	83 ec 04             	sub    $0x4,%esp
f0102efb:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102efe:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f01:	83 c8 04             	or     $0x4,%eax
f0102f04:	50                   	push   %eax
f0102f05:	ff 75 10             	pushl  0x10(%ebp)
f0102f08:	ff 75 0c             	pushl  0xc(%ebp)
f0102f0b:	53                   	push   %ebx
f0102f0c:	e8 ef fe ff ff       	call   f0102e00 <user_mem_check>
f0102f11:	83 c4 10             	add    $0x10,%esp
f0102f14:	85 c0                	test   %eax,%eax
f0102f16:	79 21                	jns    f0102f39 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102f18:	83 ec 04             	sub    $0x4,%esp
f0102f1b:	ff 35 60 02 23 f0    	pushl  0xf0230260
f0102f21:	ff 73 48             	pushl  0x48(%ebx)
f0102f24:	68 00 70 10 f0       	push   $0xf0107000
f0102f29:	e8 23 09 00 00       	call   f0103851 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102f2e:	89 1c 24             	mov    %ebx,(%esp)
f0102f31:	e8 54 06 00 00       	call   f010358a <env_destroy>
f0102f36:	83 c4 10             	add    $0x10,%esp
	}
}
f0102f39:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102f3c:	c9                   	leave  
f0102f3d:	c3                   	ret    

f0102f3e <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102f3e:	55                   	push   %ebp
f0102f3f:	89 e5                	mov    %esp,%ebp
f0102f41:	57                   	push   %edi
f0102f42:	56                   	push   %esi
f0102f43:	53                   	push   %ebx
f0102f44:	83 ec 0c             	sub    $0xc,%esp
f0102f47:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
f0102f49:	89 d3                	mov    %edx,%ebx
f0102f4b:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
f0102f51:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102f58:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	
	while (vaBegin<vaEnd){
f0102f5e:	eb 58                	jmp    f0102fb8 <region_alloc+0x7a>
		struct PageInfo *p = page_alloc(0);
f0102f60:	83 ec 0c             	sub    $0xc,%esp
f0102f63:	6a 00                	push   $0x0
f0102f65:	e8 2f e0 ff ff       	call   f0100f99 <page_alloc>
		if (p == NULL)
f0102f6a:	83 c4 10             	add    $0x10,%esp
f0102f6d:	85 c0                	test   %eax,%eax
f0102f6f:	75 17                	jne    f0102f88 <region_alloc+0x4a>
			panic("Page alloc failed!");
f0102f71:	83 ec 04             	sub    $0x4,%esp
f0102f74:	68 74 73 10 f0       	push   $0xf0107374
f0102f79:	68 35 01 00 00       	push   $0x135
f0102f7e:	68 87 73 10 f0       	push   $0xf0107387
f0102f83:	e8 b8 d0 ff ff       	call   f0100040 <_panic>
		else if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
f0102f88:	6a 06                	push   $0x6
f0102f8a:	53                   	push   %ebx
f0102f8b:	50                   	push   %eax
f0102f8c:	ff 77 60             	pushl  0x60(%edi)
f0102f8f:	e8 2b e3 ff ff       	call   f01012bf <page_insert>
f0102f94:	83 c4 10             	add    $0x10,%esp
f0102f97:	85 c0                	test   %eax,%eax
f0102f99:	74 17                	je     f0102fb2 <region_alloc+0x74>
			panic("Page table couldn't be allocated!!");
f0102f9b:	83 ec 04             	sub    $0x4,%esp
f0102f9e:	68 f4 73 10 f0       	push   $0xf01073f4
f0102fa3:	68 37 01 00 00       	push   $0x137
f0102fa8:	68 87 73 10 f0       	push   $0xf0107387
f0102fad:	e8 8e d0 ff ff       	call   f0100040 <_panic>
		}
		vaBegin += PGSIZE;
f0102fb2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
	
	while (vaBegin<vaEnd){
f0102fb8:	39 f3                	cmp    %esi,%ebx
f0102fba:	72 a4                	jb     f0102f60 <region_alloc+0x22>
		else if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
			panic("Page table couldn't be allocated!!");
		}
		vaBegin += PGSIZE;
	}
}
f0102fbc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102fbf:	5b                   	pop    %ebx
f0102fc0:	5e                   	pop    %esi
f0102fc1:	5f                   	pop    %edi
f0102fc2:	5d                   	pop    %ebp
f0102fc3:	c3                   	ret    

f0102fc4 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102fc4:	55                   	push   %ebp
f0102fc5:	89 e5                	mov    %esp,%ebp
f0102fc7:	56                   	push   %esi
f0102fc8:	53                   	push   %ebx
f0102fc9:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fcc:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102fcf:	85 c0                	test   %eax,%eax
f0102fd1:	75 1a                	jne    f0102fed <envid2env+0x29>
		*env_store = curenv;
f0102fd3:	e8 f3 29 00 00       	call   f01059cb <cpunum>
f0102fd8:	6b c0 74             	imul   $0x74,%eax,%eax
f0102fdb:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0102fe1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102fe4:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102fe6:	b8 00 00 00 00       	mov    $0x0,%eax
f0102feb:	eb 70                	jmp    f010305d <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102fed:	89 c3                	mov    %eax,%ebx
f0102fef:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0102ff5:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0102ff8:	03 1d 6c 02 23 f0    	add    0xf023026c,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102ffe:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0103002:	74 05                	je     f0103009 <envid2env+0x45>
f0103004:	39 43 48             	cmp    %eax,0x48(%ebx)
f0103007:	74 10                	je     f0103019 <envid2env+0x55>
		*env_store = 0;
f0103009:	8b 45 0c             	mov    0xc(%ebp),%eax
f010300c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103012:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103017:	eb 44                	jmp    f010305d <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103019:	84 d2                	test   %dl,%dl
f010301b:	74 36                	je     f0103053 <envid2env+0x8f>
f010301d:	e8 a9 29 00 00       	call   f01059cb <cpunum>
f0103022:	6b c0 74             	imul   $0x74,%eax,%eax
f0103025:	39 98 48 10 23 f0    	cmp    %ebx,-0xfdcefb8(%eax)
f010302b:	74 26                	je     f0103053 <envid2env+0x8f>
f010302d:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0103030:	e8 96 29 00 00       	call   f01059cb <cpunum>
f0103035:	6b c0 74             	imul   $0x74,%eax,%eax
f0103038:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f010303e:	3b 70 48             	cmp    0x48(%eax),%esi
f0103041:	74 10                	je     f0103053 <envid2env+0x8f>
		*env_store = 0;
f0103043:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103046:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010304c:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103051:	eb 0a                	jmp    f010305d <envid2env+0x99>
	}

	*env_store = e;
f0103053:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103056:	89 18                	mov    %ebx,(%eax)
	return 0;
f0103058:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010305d:	5b                   	pop    %ebx
f010305e:	5e                   	pop    %esi
f010305f:	5d                   	pop    %ebp
f0103060:	c3                   	ret    

f0103061 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0103061:	55                   	push   %ebp
f0103062:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0103064:	b8 40 03 12 f0       	mov    $0xf0120340,%eax
f0103069:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f010306c:	b8 23 00 00 00       	mov    $0x23,%eax
f0103071:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0103073:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0103075:	b0 10                	mov    $0x10,%al
f0103077:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0103079:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f010307b:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f010307d:	ea 84 30 10 f0 08 00 	ljmp   $0x8,$0xf0103084
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0103084:	b0 00                	mov    $0x0,%al
f0103086:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0103089:	5d                   	pop    %ebp
f010308a:	c3                   	ret    

f010308b <env_init>:
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
f010308b:	8b 0d 6c 02 23 f0    	mov    0xf023026c,%ecx
f0103091:	8b 15 70 02 23 f0    	mov    0xf0230270,%edx
f0103097:	89 c8                	mov    %ecx,%eax
f0103099:	81 c1 00 f0 01 00    	add    $0x1f000,%ecx
f010309f:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = NULL;
f01030a6:	c7 40 44 00 00 00 00 	movl   $0x0,0x44(%eax)

		if (!env_free_list){		
f01030ad:	85 d2                	test   %edx,%edx
f01030af:	74 05                	je     f01030b6 <env_init+0x2b>
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
		}
		else{
		envs[i-1].env_link = &envs[i];
f01030b1:	89 40 c8             	mov    %eax,-0x38(%eax)
f01030b4:	eb 02                	jmp    f01030b8 <env_init+0x2d>
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
		envs[i].env_link = NULL;

		if (!env_free_list){		
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
f01030b6:	89 c2                	mov    %eax,%edx
f01030b8:	83 c0 7c             	add    $0x7c,%eax
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
f01030bb:	39 c8                	cmp    %ecx,%eax
f01030bd:	75 e0                	jne    f010309f <env_init+0x14>
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01030bf:	55                   	push   %ebp
f01030c0:	89 e5                	mov    %esp,%ebp
f01030c2:	89 15 70 02 23 f0    	mov    %edx,0xf0230270
		}	//Previous env is linked to this current env
	}
	

	// Per-CPU part of the initialization
	env_init_percpu();
f01030c8:	e8 94 ff ff ff       	call   f0103061 <env_init_percpu>
}
f01030cd:	5d                   	pop    %ebp
f01030ce:	c3                   	ret    

f01030cf <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01030cf:	55                   	push   %ebp
f01030d0:	89 e5                	mov    %esp,%ebp
f01030d2:	53                   	push   %ebx
f01030d3:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f01030d6:	8b 1d 70 02 23 f0    	mov    0xf0230270,%ebx
f01030dc:	85 db                	test   %ebx,%ebx
f01030de:	0f 84 70 01 00 00    	je     f0103254 <env_alloc+0x185>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f01030e4:	83 ec 0c             	sub    $0xc,%esp
f01030e7:	6a 01                	push   $0x1
f01030e9:	e8 ab de ff ff       	call   f0100f99 <page_alloc>
f01030ee:	83 c4 10             	add    $0x10,%esp
f01030f1:	85 c0                	test   %eax,%eax
f01030f3:	0f 84 62 01 00 00    	je     f010325b <env_alloc+0x18c>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f01030f9:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01030fe:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f0103104:	c1 f8 03             	sar    $0x3,%eax
f0103107:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010310a:	89 c2                	mov    %eax,%edx
f010310c:	c1 ea 0c             	shr    $0xc,%edx
f010310f:	3b 15 c8 0e 23 f0    	cmp    0xf0230ec8,%edx
f0103115:	72 12                	jb     f0103129 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103117:	50                   	push   %eax
f0103118:	68 a4 60 10 f0       	push   $0xf01060a4
f010311d:	6a 58                	push   $0x58
f010311f:	68 41 70 10 f0       	push   $0xf0107041
f0103124:	e8 17 cf ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0103129:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010312e:	89 43 60             	mov    %eax,0x60(%ebx)
	e->env_pgdir = (pde_t*)page2kva(p);
f0103131:	b8 00 00 00 00       	mov    $0x0,%eax

	for (i = 0; i < NPDENTRIES; ++i) {
		e->env_pgdir[i] = kern_pgdir[i];  //Mapping all 1024 entries of the kernel
f0103136:	8b 15 cc 0e 23 f0    	mov    0xf0230ecc,%edx
f010313c:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f010313f:	8b 53 60             	mov    0x60(%ebx),%edx
f0103142:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f0103145:	83 c0 04             	add    $0x4,%eax

	// LAB 3: Your code here.
	p->pp_ref++;
	e->env_pgdir = (pde_t*)page2kva(p);

	for (i = 0; i < NPDENTRIES; ++i) {
f0103148:	3d 00 10 00 00       	cmp    $0x1000,%eax
f010314d:	75 e7                	jne    f0103136 <env_alloc+0x67>
						 //pgdir to the environment pgdir
	}
	
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f010314f:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103152:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103157:	77 15                	ja     f010316e <env_alloc+0x9f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103159:	50                   	push   %eax
f010315a:	68 c8 60 10 f0       	push   $0xf01060c8
f010315f:	68 d0 00 00 00       	push   $0xd0
f0103164:	68 87 73 10 f0       	push   $0xf0107387
f0103169:	e8 d2 ce ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010316e:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0103174:	83 ca 05             	or     $0x5,%edx
f0103177:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f010317d:	8b 43 48             	mov    0x48(%ebx),%eax
f0103180:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0103185:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f010318a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010318f:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0103192:	89 da                	mov    %ebx,%edx
f0103194:	2b 15 6c 02 23 f0    	sub    0xf023026c,%edx
f010319a:	c1 fa 02             	sar    $0x2,%edx
f010319d:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f01031a3:	09 d0                	or     %edx,%eax
f01031a5:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f01031a8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031ab:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f01031ae:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01031b5:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f01031bc:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01031c3:	83 ec 04             	sub    $0x4,%esp
f01031c6:	6a 44                	push   $0x44
f01031c8:	6a 00                	push   $0x0
f01031ca:	53                   	push   %ebx
f01031cb:	e8 d8 21 00 00       	call   f01053a8 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f01031d0:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f01031d6:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f01031dc:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f01031e2:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f01031e9:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.
	e->env_tf.tf_eflags |= FL_IF;  //Modification for exercise 13
f01031ef:	81 4b 38 00 02 00 00 	orl    $0x200,0x38(%ebx)

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f01031f6:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f01031fd:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0103201:	8b 43 44             	mov    0x44(%ebx),%eax
f0103204:	a3 70 02 23 f0       	mov    %eax,0xf0230270
	*newenv_store = e;
f0103209:	8b 45 08             	mov    0x8(%ebp),%eax
f010320c:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f010320e:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0103211:	e8 b5 27 00 00       	call   f01059cb <cpunum>
f0103216:	6b c0 74             	imul   $0x74,%eax,%eax
f0103219:	83 c4 10             	add    $0x10,%esp
f010321c:	ba 00 00 00 00       	mov    $0x0,%edx
f0103221:	83 b8 48 10 23 f0 00 	cmpl   $0x0,-0xfdcefb8(%eax)
f0103228:	74 11                	je     f010323b <env_alloc+0x16c>
f010322a:	e8 9c 27 00 00       	call   f01059cb <cpunum>
f010322f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103232:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0103238:	8b 50 48             	mov    0x48(%eax),%edx
f010323b:	83 ec 04             	sub    $0x4,%esp
f010323e:	53                   	push   %ebx
f010323f:	52                   	push   %edx
f0103240:	68 92 73 10 f0       	push   $0xf0107392
f0103245:	e8 07 06 00 00       	call   f0103851 <cprintf>
	return 0;
f010324a:	83 c4 10             	add    $0x10,%esp
f010324d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103252:	eb 0c                	jmp    f0103260 <env_alloc+0x191>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103254:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103259:	eb 05                	jmp    f0103260 <env_alloc+0x191>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f010325b:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0103260:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103263:	c9                   	leave  
f0103264:	c3                   	ret    

f0103265 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103265:	55                   	push   %ebp
f0103266:	89 e5                	mov    %esp,%ebp
f0103268:	57                   	push   %edi
f0103269:	56                   	push   %esi
f010326a:	53                   	push   %ebx
f010326b:	83 ec 34             	sub    $0x34,%esp
f010326e:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	int r;
	struct Env *env;
	r = env_alloc( &env, 0);
f0103271:	6a 00                	push   $0x0
f0103273:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103276:	50                   	push   %eax
f0103277:	e8 53 fe ff ff       	call   f01030cf <env_alloc>
	if (r){
f010327c:	83 c4 10             	add    $0x10,%esp
f010327f:	85 c0                	test   %eax,%eax
f0103281:	74 15                	je     f0103298 <env_create+0x33>
	panic("env_alloc: %e", r);
f0103283:	50                   	push   %eax
f0103284:	68 a7 73 10 f0       	push   $0xf01073a7
f0103289:	68 b2 01 00 00       	push   $0x1b2
f010328e:	68 87 73 10 f0       	push   $0xf0107387
f0103293:	e8 a8 cd ff ff       	call   f0100040 <_panic>
	}
	
	load_icode(env,binary);
f0103298:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010329b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Get the beginning and end of program header table
	//Details of struct proghdr are in /lab/inc/elf.h

	// is this a valid ELF?
	
	if (((struct Elf*)binary)->e_magic != ELF_MAGIC)
f010329e:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f01032a4:	74 17                	je     f01032bd <env_create+0x58>
	{
		panic ("Not a valid ELF binary image");
f01032a6:	83 ec 04             	sub    $0x4,%esp
f01032a9:	68 b5 73 10 f0       	push   $0xf01073b5
f01032ae:	68 81 01 00 00       	push   $0x181
f01032b3:	68 87 73 10 f0       	push   $0xf0107387
f01032b8:	e8 83 cd ff ff       	call   f0100040 <_panic>
	}

	struct Proghdr *ph =(struct Proghdr *)(binary + ((struct Elf*)binary)->e_phoff); //phoff is the offset
f01032bd:	89 fb                	mov    %edi,%ebx
f01032bf:	03 5f 1c             	add    0x1c(%edi),%ebx
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
f01032c2:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f01032c6:	c1 e6 05             	shl    $0x5,%esi
f01032c9:	01 de                	add    %ebx,%esi
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));
f01032cb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01032ce:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01032d1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01032d6:	77 15                	ja     f01032ed <env_create+0x88>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01032d8:	50                   	push   %eax
f01032d9:	68 c8 60 10 f0       	push   $0xf01060c8
f01032de:	68 88 01 00 00       	push   $0x188
f01032e3:	68 87 73 10 f0       	push   $0xf0107387
f01032e8:	e8 53 cd ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01032ed:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01032f2:	0f 22 d8             	mov    %eax,%cr3
f01032f5:	eb 60                	jmp    f0103357 <env_create+0xf2>

	for (;ph<phEnd;++ph){
		if (ph->p_type == ELF_PROG_LOAD){	//Check whether the type is ELF_PROG_LOAD
f01032f7:	83 3b 01             	cmpl   $0x1,(%ebx)
f01032fa:	75 58                	jne    f0103354 <env_create+0xef>
		
		if(ph->p_memsz < ph->p_filesz){
f01032fc:	8b 4b 14             	mov    0x14(%ebx),%ecx
f01032ff:	3b 4b 10             	cmp    0x10(%ebx),%ecx
f0103302:	73 17                	jae    f010331b <env_create+0xb6>
		panic ("Memory size is smaller than file size!!");
f0103304:	83 ec 04             	sub    $0x4,%esp
f0103307:	68 18 74 10 f0       	push   $0xf0107418
f010330c:	68 8e 01 00 00       	push   $0x18e
f0103311:	68 87 73 10 f0       	push   $0xf0107387
f0103316:	e8 25 cd ff ff       	call   f0100040 <_panic>
		}
		region_alloc(e, (void *)ph->p_va, ph->p_memsz);  //Allocate region per segment
f010331b:	8b 53 08             	mov    0x8(%ebx),%edx
f010331e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103321:	e8 18 fc ff ff       	call   f0102f3e <region_alloc>
	

		memcpy((void*)ph->p_va, (void*)(binary + ph->p_offset), ph->p_filesz); //Load Binary into memory
f0103326:	83 ec 04             	sub    $0x4,%esp
f0103329:	ff 73 10             	pushl  0x10(%ebx)
f010332c:	89 f8                	mov    %edi,%eax
f010332e:	03 43 04             	add    0x4(%ebx),%eax
f0103331:	50                   	push   %eax
f0103332:	ff 73 08             	pushl  0x8(%ebx)
f0103335:	e8 23 21 00 00       	call   f010545d <memcpy>

		memset((void*)(ph->p_va + ph->p_filesz),0,ph->p_memsz-ph->p_filesz);  //Clear the rest of the memory, i.e the bss segment
f010333a:	8b 43 10             	mov    0x10(%ebx),%eax
f010333d:	83 c4 0c             	add    $0xc,%esp
f0103340:	8b 53 14             	mov    0x14(%ebx),%edx
f0103343:	29 c2                	sub    %eax,%edx
f0103345:	52                   	push   %edx
f0103346:	6a 00                	push   $0x0
f0103348:	03 43 08             	add    0x8(%ebx),%eax
f010334b:	50                   	push   %eax
f010334c:	e8 57 20 00 00       	call   f01053a8 <memset>
f0103351:	83 c4 10             	add    $0x10,%esp
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));

	for (;ph<phEnd;++ph){
f0103354:	83 c3 20             	add    $0x20,%ebx
f0103357:	39 de                	cmp    %ebx,%esi
f0103359:	77 9c                	ja     f01032f7 <env_create+0x92>
		}
		else{
			continue;
		}
	}
	lcr3(PADDR(kern_pgdir));   //Switch back to Kernel page directory
f010335b:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103360:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103365:	77 15                	ja     f010337c <env_create+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103367:	50                   	push   %eax
f0103368:	68 c8 60 10 f0       	push   $0xf01060c8
f010336d:	68 9b 01 00 00       	push   $0x19b
f0103372:	68 87 73 10 f0       	push   $0xf0107387
f0103377:	e8 c4 cc ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010337c:	05 00 00 00 10       	add    $0x10000000,%eax
f0103381:	0f 22 d8             	mov    %eax,%cr3
	
	e->env_tf.tf_eip = ((struct Elf*)binary)->e_entry;   //Define the entry point of the env from the ELF binary entry point
f0103384:	8b 47 18             	mov    0x18(%edi),%eax
f0103387:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010338a:	89 47 30             	mov    %eax,0x30(%edi)

	region_alloc(e,(void *)USTACKTOP - PGSIZE, PGSIZE);
f010338d:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103392:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103397:	89 f8                	mov    %edi,%eax
f0103399:	e8 a0 fb ff ff       	call   f0102f3e <region_alloc>
	if (r){
	panic("env_alloc: %e", r);
	}
	
	load_icode(env,binary);
	env->env_type = type;
f010339e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01033a1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01033a4:	89 50 50             	mov    %edx,0x50(%eax)
}
f01033a7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01033aa:	5b                   	pop    %ebx
f01033ab:	5e                   	pop    %esi
f01033ac:	5f                   	pop    %edi
f01033ad:	5d                   	pop    %ebp
f01033ae:	c3                   	ret    

f01033af <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01033af:	55                   	push   %ebp
f01033b0:	89 e5                	mov    %esp,%ebp
f01033b2:	57                   	push   %edi
f01033b3:	56                   	push   %esi
f01033b4:	53                   	push   %ebx
f01033b5:	83 ec 1c             	sub    $0x1c,%esp
f01033b8:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01033bb:	e8 0b 26 00 00       	call   f01059cb <cpunum>
f01033c0:	6b c0 74             	imul   $0x74,%eax,%eax
f01033c3:	39 b8 48 10 23 f0    	cmp    %edi,-0xfdcefb8(%eax)
f01033c9:	75 29                	jne    f01033f4 <env_free+0x45>
		lcr3(PADDR(kern_pgdir));
f01033cb:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01033d0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01033d5:	77 15                	ja     f01033ec <env_free+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033d7:	50                   	push   %eax
f01033d8:	68 c8 60 10 f0       	push   $0xf01060c8
f01033dd:	68 c8 01 00 00       	push   $0x1c8
f01033e2:	68 87 73 10 f0       	push   $0xf0107387
f01033e7:	e8 54 cc ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01033ec:	05 00 00 00 10       	add    $0x10000000,%eax
f01033f1:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01033f4:	8b 5f 48             	mov    0x48(%edi),%ebx
f01033f7:	e8 cf 25 00 00       	call   f01059cb <cpunum>
f01033fc:	6b c0 74             	imul   $0x74,%eax,%eax
f01033ff:	ba 00 00 00 00       	mov    $0x0,%edx
f0103404:	83 b8 48 10 23 f0 00 	cmpl   $0x0,-0xfdcefb8(%eax)
f010340b:	74 11                	je     f010341e <env_free+0x6f>
f010340d:	e8 b9 25 00 00       	call   f01059cb <cpunum>
f0103412:	6b c0 74             	imul   $0x74,%eax,%eax
f0103415:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f010341b:	8b 50 48             	mov    0x48(%eax),%edx
f010341e:	83 ec 04             	sub    $0x4,%esp
f0103421:	53                   	push   %ebx
f0103422:	52                   	push   %edx
f0103423:	68 d2 73 10 f0       	push   $0xf01073d2
f0103428:	e8 24 04 00 00       	call   f0103851 <cprintf>
f010342d:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103430:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103437:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010343a:	89 d0                	mov    %edx,%eax
f010343c:	c1 e0 02             	shl    $0x2,%eax
f010343f:	89 45 d8             	mov    %eax,-0x28(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103442:	8b 47 60             	mov    0x60(%edi),%eax
f0103445:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0103448:	f7 c6 01 00 00 00    	test   $0x1,%esi
f010344e:	0f 84 a8 00 00 00    	je     f01034fc <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103454:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010345a:	89 f0                	mov    %esi,%eax
f010345c:	c1 e8 0c             	shr    $0xc,%eax
f010345f:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103462:	3b 05 c8 0e 23 f0    	cmp    0xf0230ec8,%eax
f0103468:	72 15                	jb     f010347f <env_free+0xd0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010346a:	56                   	push   %esi
f010346b:	68 a4 60 10 f0       	push   $0xf01060a4
f0103470:	68 d7 01 00 00       	push   $0x1d7
f0103475:	68 87 73 10 f0       	push   $0xf0107387
f010347a:	e8 c1 cb ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010347f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103482:	c1 e0 16             	shl    $0x16,%eax
f0103485:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103488:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f010348d:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103494:	01 
f0103495:	74 17                	je     f01034ae <env_free+0xff>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103497:	83 ec 08             	sub    $0x8,%esp
f010349a:	89 d8                	mov    %ebx,%eax
f010349c:	c1 e0 0c             	shl    $0xc,%eax
f010349f:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01034a2:	50                   	push   %eax
f01034a3:	ff 77 60             	pushl  0x60(%edi)
f01034a6:	e8 ce dd ff ff       	call   f0101279 <page_remove>
f01034ab:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01034ae:	83 c3 01             	add    $0x1,%ebx
f01034b1:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01034b7:	75 d4                	jne    f010348d <env_free+0xde>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01034b9:	8b 47 60             	mov    0x60(%edi),%eax
f01034bc:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01034bf:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01034c6:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01034c9:	3b 05 c8 0e 23 f0    	cmp    0xf0230ec8,%eax
f01034cf:	72 14                	jb     f01034e5 <env_free+0x136>
		panic("pa2page called with invalid pa");
f01034d1:	83 ec 04             	sub    $0x4,%esp
f01034d4:	68 40 74 10 f0       	push   $0xf0107440
f01034d9:	6a 51                	push   $0x51
f01034db:	68 41 70 10 f0       	push   $0xf0107041
f01034e0:	e8 5b cb ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f01034e5:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f01034e8:	a1 d0 0e 23 f0       	mov    0xf0230ed0,%eax
f01034ed:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01034f0:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01034f3:	50                   	push   %eax
f01034f4:	e8 67 db ff ff       	call   f0101060 <page_decref>
f01034f9:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01034fc:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103500:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103503:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0103508:	0f 85 29 ff ff ff    	jne    f0103437 <env_free+0x88>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f010350e:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103511:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103516:	77 15                	ja     f010352d <env_free+0x17e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103518:	50                   	push   %eax
f0103519:	68 c8 60 10 f0       	push   $0xf01060c8
f010351e:	68 e5 01 00 00       	push   $0x1e5
f0103523:	68 87 73 10 f0       	push   $0xf0107387
f0103528:	e8 13 cb ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f010352d:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103534:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103539:	c1 e8 0c             	shr    $0xc,%eax
f010353c:	3b 05 c8 0e 23 f0    	cmp    0xf0230ec8,%eax
f0103542:	72 14                	jb     f0103558 <env_free+0x1a9>
		panic("pa2page called with invalid pa");
f0103544:	83 ec 04             	sub    $0x4,%esp
f0103547:	68 40 74 10 f0       	push   $0xf0107440
f010354c:	6a 51                	push   $0x51
f010354e:	68 41 70 10 f0       	push   $0xf0107041
f0103553:	e8 e8 ca ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f0103558:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f010355b:	8b 15 d0 0e 23 f0    	mov    0xf0230ed0,%edx
f0103561:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0103564:	50                   	push   %eax
f0103565:	e8 f6 da ff ff       	call   f0101060 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f010356a:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103571:	a1 70 02 23 f0       	mov    0xf0230270,%eax
f0103576:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103579:	89 3d 70 02 23 f0    	mov    %edi,0xf0230270
f010357f:	83 c4 10             	add    $0x10,%esp
}
f0103582:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103585:	5b                   	pop    %ebx
f0103586:	5e                   	pop    %esi
f0103587:	5f                   	pop    %edi
f0103588:	5d                   	pop    %ebp
f0103589:	c3                   	ret    

f010358a <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f010358a:	55                   	push   %ebp
f010358b:	89 e5                	mov    %esp,%ebp
f010358d:	53                   	push   %ebx
f010358e:	83 ec 04             	sub    $0x4,%esp
f0103591:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f0103594:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f0103598:	75 19                	jne    f01035b3 <env_destroy+0x29>
f010359a:	e8 2c 24 00 00       	call   f01059cb <cpunum>
f010359f:	6b c0 74             	imul   $0x74,%eax,%eax
f01035a2:	39 98 48 10 23 f0    	cmp    %ebx,-0xfdcefb8(%eax)
f01035a8:	74 09                	je     f01035b3 <env_destroy+0x29>
		e->env_status = ENV_DYING;
f01035aa:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f01035b1:	eb 33                	jmp    f01035e6 <env_destroy+0x5c>
	}

	env_free(e);
f01035b3:	83 ec 0c             	sub    $0xc,%esp
f01035b6:	53                   	push   %ebx
f01035b7:	e8 f3 fd ff ff       	call   f01033af <env_free>

	if (curenv == e) {
f01035bc:	e8 0a 24 00 00       	call   f01059cb <cpunum>
f01035c1:	6b c0 74             	imul   $0x74,%eax,%eax
f01035c4:	83 c4 10             	add    $0x10,%esp
f01035c7:	39 98 48 10 23 f0    	cmp    %ebx,-0xfdcefb8(%eax)
f01035cd:	75 17                	jne    f01035e6 <env_destroy+0x5c>
		curenv = NULL;
f01035cf:	e8 f7 23 00 00       	call   f01059cb <cpunum>
f01035d4:	6b c0 74             	imul   $0x74,%eax,%eax
f01035d7:	c7 80 48 10 23 f0 00 	movl   $0x0,-0xfdcefb8(%eax)
f01035de:	00 00 00 
		sched_yield();
f01035e1:	e8 fc 0b 00 00       	call   f01041e2 <sched_yield>
	}
}
f01035e6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01035e9:	c9                   	leave  
f01035ea:	c3                   	ret    

f01035eb <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01035eb:	55                   	push   %ebp
f01035ec:	89 e5                	mov    %esp,%ebp
f01035ee:	53                   	push   %ebx
f01035ef:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f01035f2:	e8 d4 23 00 00       	call   f01059cb <cpunum>
f01035f7:	6b c0 74             	imul   $0x74,%eax,%eax
f01035fa:	8b 98 48 10 23 f0    	mov    -0xfdcefb8(%eax),%ebx
f0103600:	e8 c6 23 00 00       	call   f01059cb <cpunum>
f0103605:	89 43 5c             	mov    %eax,0x5c(%ebx)

	__asm __volatile("movl %0,%%esp\n"
f0103608:	8b 65 08             	mov    0x8(%ebp),%esp
f010360b:	61                   	popa   
f010360c:	07                   	pop    %es
f010360d:	1f                   	pop    %ds
f010360e:	83 c4 08             	add    $0x8,%esp
f0103611:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103612:	83 ec 04             	sub    $0x4,%esp
f0103615:	68 e8 73 10 f0       	push   $0xf01073e8
f010361a:	68 1b 02 00 00       	push   $0x21b
f010361f:	68 87 73 10 f0       	push   $0xf0107387
f0103624:	e8 17 ca ff ff       	call   f0100040 <_panic>

f0103629 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103629:	55                   	push   %ebp
f010362a:	89 e5                	mov    %esp,%ebp
f010362c:	53                   	push   %ebx
f010362d:	83 ec 04             	sub    $0x4,%esp
f0103630:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	//check if this is the first call to env_run
	if (curenv == NULL){
f0103633:	e8 93 23 00 00       	call   f01059cb <cpunum>
f0103638:	6b c0 74             	imul   $0x74,%eax,%eax
f010363b:	83 b8 48 10 23 f0 00 	cmpl   $0x0,-0xfdcefb8(%eax)
f0103642:	75 10                	jne    f0103654 <env_run+0x2b>
	curenv = e;
f0103644:	e8 82 23 00 00       	call   f01059cb <cpunum>
f0103649:	6b c0 74             	imul   $0x74,%eax,%eax
f010364c:	89 98 48 10 23 f0    	mov    %ebx,-0xfdcefb8(%eax)
f0103652:	eb 29                	jmp    f010367d <env_run+0x54>
	}
	
	//If curenv state is running mode , set it to runnable 
	else if (curenv->env_status == ENV_RUNNING){
f0103654:	e8 72 23 00 00       	call   f01059cb <cpunum>
f0103659:	6b c0 74             	imul   $0x74,%eax,%eax
f010365c:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0103662:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103666:	75 15                	jne    f010367d <env_run+0x54>
	 curenv->env_status = ENV_RUNNABLE;
f0103668:	e8 5e 23 00 00       	call   f01059cb <cpunum>
f010366d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103670:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0103676:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	curenv = e;	//Set the current environment to the new env
f010367d:	e8 49 23 00 00       	call   f01059cb <cpunum>
f0103682:	6b c0 74             	imul   $0x74,%eax,%eax
f0103685:	89 98 48 10 23 f0    	mov    %ebx,-0xfdcefb8(%eax)
	curenv->env_status = ENV_RUNNING; //Set it to running state
f010368b:	e8 3b 23 00 00       	call   f01059cb <cpunum>
f0103690:	6b c0 74             	imul   $0x74,%eax,%eax
f0103693:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0103699:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;	// Increment the env_runs counter
f01036a0:	e8 26 23 00 00       	call   f01059cb <cpunum>
f01036a5:	6b c0 74             	imul   $0x74,%eax,%eax
f01036a8:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f01036ae:	83 40 58 01          	addl   $0x1,0x58(%eax)
	
	lcr3(PADDR(e->env_pgdir));	//Use lcr3 to switch to the env directory
f01036b2:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01036b5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01036ba:	77 15                	ja     f01036d1 <env_run+0xa8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01036bc:	50                   	push   %eax
f01036bd:	68 c8 60 10 f0       	push   $0xf01060c8
f01036c2:	68 47 02 00 00       	push   $0x247
f01036c7:	68 87 73 10 f0       	push   $0xf0107387
f01036cc:	e8 6f c9 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01036d1:	05 00 00 00 10       	add    $0x10000000,%eax
f01036d6:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01036d9:	83 ec 0c             	sub    $0xc,%esp
f01036dc:	68 c0 04 12 f0       	push   $0xf01204c0
f01036e1:	e8 ed 25 00 00       	call   f0105cd3 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01036e6:	f3 90                	pause  
	unlock_kernel();
	env_pop_tf(&e->env_tf);
f01036e8:	89 1c 24             	mov    %ebx,(%esp)
f01036eb:	e8 fb fe ff ff       	call   f01035eb <env_pop_tf>

f01036f0 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01036f0:	55                   	push   %ebp
f01036f1:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01036f3:	ba 70 00 00 00       	mov    $0x70,%edx
f01036f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01036fb:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01036fc:	b2 71                	mov    $0x71,%dl
f01036fe:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01036ff:	0f b6 c0             	movzbl %al,%eax
}
f0103702:	5d                   	pop    %ebp
f0103703:	c3                   	ret    

f0103704 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103704:	55                   	push   %ebp
f0103705:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103707:	ba 70 00 00 00       	mov    $0x70,%edx
f010370c:	8b 45 08             	mov    0x8(%ebp),%eax
f010370f:	ee                   	out    %al,(%dx)
f0103710:	b2 71                	mov    $0x71,%dl
f0103712:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103715:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103716:	5d                   	pop    %ebp
f0103717:	c3                   	ret    

f0103718 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103718:	55                   	push   %ebp
f0103719:	89 e5                	mov    %esp,%ebp
f010371b:	56                   	push   %esi
f010371c:	53                   	push   %ebx
f010371d:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103720:	66 a3 e8 03 12 f0    	mov    %ax,0xf01203e8
	if (!didinit)
f0103726:	80 3d 74 02 23 f0 00 	cmpb   $0x0,0xf0230274
f010372d:	74 57                	je     f0103786 <irq_setmask_8259A+0x6e>
f010372f:	89 c6                	mov    %eax,%esi
f0103731:	ba 21 00 00 00       	mov    $0x21,%edx
f0103736:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
f0103737:	66 c1 e8 08          	shr    $0x8,%ax
f010373b:	b2 a1                	mov    $0xa1,%dl
f010373d:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f010373e:	83 ec 0c             	sub    $0xc,%esp
f0103741:	68 5f 74 10 f0       	push   $0xf010745f
f0103746:	e8 06 01 00 00       	call   f0103851 <cprintf>
f010374b:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f010374e:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103753:	0f b7 f6             	movzwl %si,%esi
f0103756:	f7 d6                	not    %esi
f0103758:	0f a3 de             	bt     %ebx,%esi
f010375b:	73 11                	jae    f010376e <irq_setmask_8259A+0x56>
			cprintf(" %d", i);
f010375d:	83 ec 08             	sub    $0x8,%esp
f0103760:	53                   	push   %ebx
f0103761:	68 7f 79 10 f0       	push   $0xf010797f
f0103766:	e8 e6 00 00 00       	call   f0103851 <cprintf>
f010376b:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f010376e:	83 c3 01             	add    $0x1,%ebx
f0103771:	83 fb 10             	cmp    $0x10,%ebx
f0103774:	75 e2                	jne    f0103758 <irq_setmask_8259A+0x40>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f0103776:	83 ec 0c             	sub    $0xc,%esp
f0103779:	68 12 79 10 f0       	push   $0xf0107912
f010377e:	e8 ce 00 00 00       	call   f0103851 <cprintf>
f0103783:	83 c4 10             	add    $0x10,%esp
}
f0103786:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103789:	5b                   	pop    %ebx
f010378a:	5e                   	pop    %esi
f010378b:	5d                   	pop    %ebp
f010378c:	c3                   	ret    

f010378d <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f010378d:	c6 05 74 02 23 f0 01 	movb   $0x1,0xf0230274
f0103794:	ba 21 00 00 00       	mov    $0x21,%edx
f0103799:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010379e:	ee                   	out    %al,(%dx)
f010379f:	b2 a1                	mov    $0xa1,%dl
f01037a1:	ee                   	out    %al,(%dx)
f01037a2:	b2 20                	mov    $0x20,%dl
f01037a4:	b8 11 00 00 00       	mov    $0x11,%eax
f01037a9:	ee                   	out    %al,(%dx)
f01037aa:	b2 21                	mov    $0x21,%dl
f01037ac:	b8 20 00 00 00       	mov    $0x20,%eax
f01037b1:	ee                   	out    %al,(%dx)
f01037b2:	b8 04 00 00 00       	mov    $0x4,%eax
f01037b7:	ee                   	out    %al,(%dx)
f01037b8:	b8 03 00 00 00       	mov    $0x3,%eax
f01037bd:	ee                   	out    %al,(%dx)
f01037be:	b2 a0                	mov    $0xa0,%dl
f01037c0:	b8 11 00 00 00       	mov    $0x11,%eax
f01037c5:	ee                   	out    %al,(%dx)
f01037c6:	b2 a1                	mov    $0xa1,%dl
f01037c8:	b8 28 00 00 00       	mov    $0x28,%eax
f01037cd:	ee                   	out    %al,(%dx)
f01037ce:	b8 02 00 00 00       	mov    $0x2,%eax
f01037d3:	ee                   	out    %al,(%dx)
f01037d4:	b8 01 00 00 00       	mov    $0x1,%eax
f01037d9:	ee                   	out    %al,(%dx)
f01037da:	b2 20                	mov    $0x20,%dl
f01037dc:	b8 68 00 00 00       	mov    $0x68,%eax
f01037e1:	ee                   	out    %al,(%dx)
f01037e2:	b8 0a 00 00 00       	mov    $0xa,%eax
f01037e7:	ee                   	out    %al,(%dx)
f01037e8:	b2 a0                	mov    $0xa0,%dl
f01037ea:	b8 68 00 00 00       	mov    $0x68,%eax
f01037ef:	ee                   	out    %al,(%dx)
f01037f0:	b8 0a 00 00 00       	mov    $0xa,%eax
f01037f5:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f01037f6:	0f b7 05 e8 03 12 f0 	movzwl 0xf01203e8,%eax
f01037fd:	66 83 f8 ff          	cmp    $0xffff,%ax
f0103801:	74 13                	je     f0103816 <pic_init+0x89>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f0103803:	55                   	push   %ebp
f0103804:	89 e5                	mov    %esp,%ebp
f0103806:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f0103809:	0f b7 c0             	movzwl %ax,%eax
f010380c:	50                   	push   %eax
f010380d:	e8 06 ff ff ff       	call   f0103718 <irq_setmask_8259A>
f0103812:	83 c4 10             	add    $0x10,%esp
}
f0103815:	c9                   	leave  
f0103816:	f3 c3                	repz ret 

f0103818 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103818:	55                   	push   %ebp
f0103819:	89 e5                	mov    %esp,%ebp
f010381b:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010381e:	ff 75 08             	pushl  0x8(%ebp)
f0103821:	e8 1f cf ff ff       	call   f0100745 <cputchar>
f0103826:	83 c4 10             	add    $0x10,%esp
	*cnt++;
}
f0103829:	c9                   	leave  
f010382a:	c3                   	ret    

f010382b <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010382b:	55                   	push   %ebp
f010382c:	89 e5                	mov    %esp,%ebp
f010382e:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0103831:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103838:	ff 75 0c             	pushl  0xc(%ebp)
f010383b:	ff 75 08             	pushl  0x8(%ebp)
f010383e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103841:	50                   	push   %eax
f0103842:	68 18 38 10 f0       	push   $0xf0103818
f0103847:	e8 e9 14 00 00       	call   f0104d35 <vprintfmt>
	return cnt;
}
f010384c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010384f:	c9                   	leave  
f0103850:	c3                   	ret    

f0103851 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103851:	55                   	push   %ebp
f0103852:	89 e5                	mov    %esp,%ebp
f0103854:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103857:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010385a:	50                   	push   %eax
f010385b:	ff 75 08             	pushl  0x8(%ebp)
f010385e:	e8 c8 ff ff ff       	call   f010382b <vcprintf>
	va_end(ap);

	return cnt;
}
f0103863:	c9                   	leave  
f0103864:	c3                   	ret    

f0103865 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103865:	55                   	push   %ebp
f0103866:	89 e5                	mov    %esp,%ebp
f0103868:	56                   	push   %esi
f0103869:	53                   	push   %ebx
	// user space on that CPU.
	//
	// LAB 4: Your code here:

	
	int i = cpunum();
f010386a:	e8 5c 21 00 00       	call   f01059cb <cpunum>
f010386f:	89 c3                	mov    %eax,%ebx
	

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	thiscpu->cpu_ts.ts_esp0 = (uintptr_t)(percpu_kstacks[cpunum()] + KSTKSIZE);
f0103871:	e8 55 21 00 00       	call   f01059cb <cpunum>
f0103876:	89 c6                	mov    %eax,%esi
f0103878:	e8 4e 21 00 00       	call   f01059cb <cpunum>
f010387d:	6b f6 74             	imul   $0x74,%esi,%esi
f0103880:	c1 e0 0f             	shl    $0xf,%eax
f0103883:	8d 80 00 a0 23 f0    	lea    -0xfdc6000(%eax),%eax
f0103889:	89 86 50 10 23 f0    	mov    %eax,-0xfdcefb0(%esi)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f010388f:	e8 37 21 00 00       	call   f01059cb <cpunum>
f0103894:	6b c0 74             	imul   $0x74,%eax,%eax
f0103897:	66 c7 80 54 10 23 f0 	movw   $0x10,-0xfdcefac(%eax)
f010389e:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3)+i] = SEG16(STS_T32A, (uint32_t) (&cpus[i].cpu_ts),  //It was (&ts) instead of &cpus[i].cpu_ts
f01038a0:	8d 43 05             	lea    0x5(%ebx),%eax
f01038a3:	6b d3 74             	imul   $0x74,%ebx,%edx
f01038a6:	81 c2 4c 10 23 f0    	add    $0xf023104c,%edx
f01038ac:	66 c7 04 c5 80 03 12 	movw   $0x67,-0xfedfc80(,%eax,8)
f01038b3:	f0 67 00 
f01038b6:	66 89 14 c5 82 03 12 	mov    %dx,-0xfedfc7e(,%eax,8)
f01038bd:	f0 
f01038be:	89 d1                	mov    %edx,%ecx
f01038c0:	c1 e9 10             	shr    $0x10,%ecx
f01038c3:	88 0c c5 84 03 12 f0 	mov    %cl,-0xfedfc7c(,%eax,8)
f01038ca:	c6 04 c5 86 03 12 f0 	movb   $0x40,-0xfedfc7a(,%eax,8)
f01038d1:	40 
f01038d2:	c1 ea 18             	shr    $0x18,%edx
f01038d5:	88 14 c5 87 03 12 f0 	mov    %dl,-0xfedfc79(,%eax,8)
					sizeof(struct Taskstate)-1, 0);
	gdt[(GD_TSS0 >> 3)+i].sd_s = 0;
f01038dc:	c6 04 c5 85 03 12 f0 	movb   $0x89,-0xfedfc7b(,%eax,8)
f01038e3:	89 

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(((GD_TSS0>>3) + i) << 3);	
f01038e4:	8d 1c dd 28 00 00 00 	lea    0x28(,%ebx,8),%ebx
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f01038eb:	0f 00 db             	ltr    %bx
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f01038ee:	b8 ea 03 12 f0       	mov    $0xf01203ea,%eax
f01038f3:	0f 01 18             	lidtl  (%eax)
	lidt(&idt_pd); 
	
	


}
f01038f6:	5b                   	pop    %ebx
f01038f7:	5e                   	pop    %esi
f01038f8:	5d                   	pop    %ebp
f01038f9:	c3                   	ret    

f01038fa <trap_init>:
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i,j; 
	for (i=0; i<= T_SIMDERR;i++){
f01038fa:	b8 00 00 00 00       	mov    $0x0,%eax
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
f01038ff:	8b 14 85 f0 03 12 f0 	mov    -0xfedfc10(,%eax,4),%edx
f0103906:	66 89 14 c5 80 02 23 	mov    %dx,-0xfdcfd80(,%eax,8)
f010390d:	f0 
f010390e:	66 c7 04 c5 82 02 23 	movw   $0x8,-0xfdcfd7e(,%eax,8)
f0103915:	f0 08 00 
f0103918:	c6 04 c5 84 02 23 f0 	movb   $0x0,-0xfdcfd7c(,%eax,8)
f010391f:	00 
f0103920:	c6 04 c5 85 02 23 f0 	movb   $0x8e,-0xfdcfd7b(,%eax,8)
f0103927:	8e 
f0103928:	c1 ea 10             	shr    $0x10,%edx
f010392b:	66 89 14 c5 86 02 23 	mov    %dx,-0xfdcfd7a(,%eax,8)
f0103932:	f0 
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i,j; 
	for (i=0; i<= T_SIMDERR;i++){
f0103933:	83 c0 01             	add    $0x1,%eax
f0103936:	83 f8 14             	cmp    $0x14,%eax
f0103939:	75 c4                	jne    f01038ff <trap_init+0x5>
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
	}

	//Interrupt 3 is a soft interrupt generated by user, hence the dpl of the gate will be checked with 3
  	SETGATE(idt[3],0,GD_KT,int_vector_table[3],3);
f010393b:	a1 fc 03 12 f0       	mov    0xf01203fc,%eax
f0103940:	66 a3 98 02 23 f0    	mov    %ax,0xf0230298
f0103946:	66 c7 05 9a 02 23 f0 	movw   $0x8,0xf023029a
f010394d:	08 00 
f010394f:	c6 05 9c 02 23 f0 00 	movb   $0x0,0xf023029c
f0103956:	c6 05 9d 02 23 f0 ee 	movb   $0xee,0xf023029d
f010395d:	c1 e8 10             	shr    $0x10,%eax
f0103960:	66 a3 9e 02 23 f0    	mov    %ax,0xf023029e

	//similarly system call is setup by the user and hence the gate should be checked with 3 
	SETGATE(idt[T_SYSCALL], 0, GD_KT, int_vector_table[T_SYSCALL], 3);// T_SYSCALL = 3
f0103966:	a1 b0 04 12 f0       	mov    0xf01204b0,%eax
f010396b:	66 a3 00 04 23 f0    	mov    %ax,0xf0230400
f0103971:	66 c7 05 02 04 23 f0 	movw   $0x8,0xf0230402
f0103978:	08 00 
f010397a:	c6 05 04 04 23 f0 00 	movb   $0x0,0xf0230404
f0103981:	c6 05 05 04 23 f0 ee 	movb   $0xee,0xf0230405
f0103988:	c1 e8 10             	shr    $0x10,%eax
f010398b:	66 a3 06 04 23 f0    	mov    %ax,0xf0230406
f0103991:	b8 20 00 00 00       	mov    $0x20,%eax

	//For IRQ interrupts
	for(j=0;j<16;j++)
	    SETGATE(idt[IRQ_OFFSET + j], 0, GD_KT, int_vector_table[IRQ_OFFSET + j], 3);
f0103996:	8b 14 85 f0 03 12 f0 	mov    -0xfedfc10(,%eax,4),%edx
f010399d:	66 89 14 c5 80 02 23 	mov    %dx,-0xfdcfd80(,%eax,8)
f01039a4:	f0 
f01039a5:	66 c7 04 c5 82 02 23 	movw   $0x8,-0xfdcfd7e(,%eax,8)
f01039ac:	f0 08 00 
f01039af:	c6 04 c5 84 02 23 f0 	movb   $0x0,-0xfdcfd7c(,%eax,8)
f01039b6:	00 
f01039b7:	c6 04 c5 85 02 23 f0 	movb   $0xee,-0xfdcfd7b(,%eax,8)
f01039be:	ee 
f01039bf:	c1 ea 10             	shr    $0x10,%edx
f01039c2:	66 89 14 c5 86 02 23 	mov    %dx,-0xfdcfd7a(,%eax,8)
f01039c9:	f0 
f01039ca:	83 c0 01             	add    $0x1,%eax

	//similarly system call is setup by the user and hence the gate should be checked with 3 
	SETGATE(idt[T_SYSCALL], 0, GD_KT, int_vector_table[T_SYSCALL], 3);// T_SYSCALL = 3

	//For IRQ interrupts
	for(j=0;j<16;j++)
f01039cd:	83 f8 30             	cmp    $0x30,%eax
f01039d0:	75 c4                	jne    f0103996 <trap_init+0x9c>
}


void
trap_init(void)
{
f01039d2:	55                   	push   %ebp
f01039d3:	89 e5                	mov    %esp,%ebp
f01039d5:	83 ec 08             	sub    $0x8,%esp
	//For IRQ interrupts
	for(j=0;j<16;j++)
	    SETGATE(idt[IRQ_OFFSET + j], 0, GD_KT, int_vector_table[IRQ_OFFSET + j], 3);

	// Per-CPU setup 
	trap_init_percpu();
f01039d8:	e8 88 fe ff ff       	call   f0103865 <trap_init_percpu>
}
f01039dd:	c9                   	leave  
f01039de:	c3                   	ret    

f01039df <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01039df:	55                   	push   %ebp
f01039e0:	89 e5                	mov    %esp,%ebp
f01039e2:	53                   	push   %ebx
f01039e3:	83 ec 0c             	sub    $0xc,%esp
f01039e6:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01039e9:	ff 33                	pushl  (%ebx)
f01039eb:	68 73 74 10 f0       	push   $0xf0107473
f01039f0:	e8 5c fe ff ff       	call   f0103851 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01039f5:	83 c4 08             	add    $0x8,%esp
f01039f8:	ff 73 04             	pushl  0x4(%ebx)
f01039fb:	68 82 74 10 f0       	push   $0xf0107482
f0103a00:	e8 4c fe ff ff       	call   f0103851 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103a05:	83 c4 08             	add    $0x8,%esp
f0103a08:	ff 73 08             	pushl  0x8(%ebx)
f0103a0b:	68 91 74 10 f0       	push   $0xf0107491
f0103a10:	e8 3c fe ff ff       	call   f0103851 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103a15:	83 c4 08             	add    $0x8,%esp
f0103a18:	ff 73 0c             	pushl  0xc(%ebx)
f0103a1b:	68 a0 74 10 f0       	push   $0xf01074a0
f0103a20:	e8 2c fe ff ff       	call   f0103851 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103a25:	83 c4 08             	add    $0x8,%esp
f0103a28:	ff 73 10             	pushl  0x10(%ebx)
f0103a2b:	68 af 74 10 f0       	push   $0xf01074af
f0103a30:	e8 1c fe ff ff       	call   f0103851 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103a35:	83 c4 08             	add    $0x8,%esp
f0103a38:	ff 73 14             	pushl  0x14(%ebx)
f0103a3b:	68 be 74 10 f0       	push   $0xf01074be
f0103a40:	e8 0c fe ff ff       	call   f0103851 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103a45:	83 c4 08             	add    $0x8,%esp
f0103a48:	ff 73 18             	pushl  0x18(%ebx)
f0103a4b:	68 cd 74 10 f0       	push   $0xf01074cd
f0103a50:	e8 fc fd ff ff       	call   f0103851 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103a55:	83 c4 08             	add    $0x8,%esp
f0103a58:	ff 73 1c             	pushl  0x1c(%ebx)
f0103a5b:	68 dc 74 10 f0       	push   $0xf01074dc
f0103a60:	e8 ec fd ff ff       	call   f0103851 <cprintf>
f0103a65:	83 c4 10             	add    $0x10,%esp
}
f0103a68:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103a6b:	c9                   	leave  
f0103a6c:	c3                   	ret    

f0103a6d <print_trapframe>:

}

void
print_trapframe(struct Trapframe *tf)
{
f0103a6d:	55                   	push   %ebp
f0103a6e:	89 e5                	mov    %esp,%ebp
f0103a70:	56                   	push   %esi
f0103a71:	53                   	push   %ebx
f0103a72:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103a75:	e8 51 1f 00 00       	call   f01059cb <cpunum>
f0103a7a:	83 ec 04             	sub    $0x4,%esp
f0103a7d:	50                   	push   %eax
f0103a7e:	53                   	push   %ebx
f0103a7f:	68 40 75 10 f0       	push   $0xf0107540
f0103a84:	e8 c8 fd ff ff       	call   f0103851 <cprintf>
	print_regs(&tf->tf_regs);
f0103a89:	89 1c 24             	mov    %ebx,(%esp)
f0103a8c:	e8 4e ff ff ff       	call   f01039df <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103a91:	83 c4 08             	add    $0x8,%esp
f0103a94:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103a98:	50                   	push   %eax
f0103a99:	68 5e 75 10 f0       	push   $0xf010755e
f0103a9e:	e8 ae fd ff ff       	call   f0103851 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103aa3:	83 c4 08             	add    $0x8,%esp
f0103aa6:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103aaa:	50                   	push   %eax
f0103aab:	68 71 75 10 f0       	push   $0xf0107571
f0103ab0:	e8 9c fd ff ff       	call   f0103851 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103ab5:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103ab8:	83 c4 10             	add    $0x10,%esp
f0103abb:	83 f8 13             	cmp    $0x13,%eax
f0103abe:	77 09                	ja     f0103ac9 <print_trapframe+0x5c>
		return excnames[trapno];
f0103ac0:	8b 14 85 40 78 10 f0 	mov    -0xfef87c0(,%eax,4),%edx
f0103ac7:	eb 1f                	jmp    f0103ae8 <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103ac9:	83 f8 30             	cmp    $0x30,%eax
f0103acc:	74 15                	je     f0103ae3 <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103ace:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103ad1:	83 fa 10             	cmp    $0x10,%edx
f0103ad4:	b9 0a 75 10 f0       	mov    $0xf010750a,%ecx
f0103ad9:	ba f7 74 10 f0       	mov    $0xf01074f7,%edx
f0103ade:	0f 43 d1             	cmovae %ecx,%edx
f0103ae1:	eb 05                	jmp    f0103ae8 <print_trapframe+0x7b>
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103ae3:	ba eb 74 10 f0       	mov    $0xf01074eb,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103ae8:	83 ec 04             	sub    $0x4,%esp
f0103aeb:	52                   	push   %edx
f0103aec:	50                   	push   %eax
f0103aed:	68 84 75 10 f0       	push   $0xf0107584
f0103af2:	e8 5a fd ff ff       	call   f0103851 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103af7:	83 c4 10             	add    $0x10,%esp
f0103afa:	3b 1d 80 0a 23 f0    	cmp    0xf0230a80,%ebx
f0103b00:	75 1a                	jne    f0103b1c <print_trapframe+0xaf>
f0103b02:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103b06:	75 14                	jne    f0103b1c <print_trapframe+0xaf>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103b08:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103b0b:	83 ec 08             	sub    $0x8,%esp
f0103b0e:	50                   	push   %eax
f0103b0f:	68 96 75 10 f0       	push   $0xf0107596
f0103b14:	e8 38 fd ff ff       	call   f0103851 <cprintf>
f0103b19:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103b1c:	83 ec 08             	sub    $0x8,%esp
f0103b1f:	ff 73 2c             	pushl  0x2c(%ebx)
f0103b22:	68 a5 75 10 f0       	push   $0xf01075a5
f0103b27:	e8 25 fd ff ff       	call   f0103851 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103b2c:	83 c4 10             	add    $0x10,%esp
f0103b2f:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103b33:	75 49                	jne    f0103b7e <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103b35:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103b38:	89 c2                	mov    %eax,%edx
f0103b3a:	83 e2 01             	and    $0x1,%edx
f0103b3d:	ba 24 75 10 f0       	mov    $0xf0107524,%edx
f0103b42:	b9 19 75 10 f0       	mov    $0xf0107519,%ecx
f0103b47:	0f 44 ca             	cmove  %edx,%ecx
f0103b4a:	89 c2                	mov    %eax,%edx
f0103b4c:	83 e2 02             	and    $0x2,%edx
f0103b4f:	ba 36 75 10 f0       	mov    $0xf0107536,%edx
f0103b54:	be 30 75 10 f0       	mov    $0xf0107530,%esi
f0103b59:	0f 45 d6             	cmovne %esi,%edx
f0103b5c:	83 e0 04             	and    $0x4,%eax
f0103b5f:	be 8c 76 10 f0       	mov    $0xf010768c,%esi
f0103b64:	b8 3b 75 10 f0       	mov    $0xf010753b,%eax
f0103b69:	0f 44 c6             	cmove  %esi,%eax
f0103b6c:	51                   	push   %ecx
f0103b6d:	52                   	push   %edx
f0103b6e:	50                   	push   %eax
f0103b6f:	68 b3 75 10 f0       	push   $0xf01075b3
f0103b74:	e8 d8 fc ff ff       	call   f0103851 <cprintf>
f0103b79:	83 c4 10             	add    $0x10,%esp
f0103b7c:	eb 10                	jmp    f0103b8e <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103b7e:	83 ec 0c             	sub    $0xc,%esp
f0103b81:	68 12 79 10 f0       	push   $0xf0107912
f0103b86:	e8 c6 fc ff ff       	call   f0103851 <cprintf>
f0103b8b:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103b8e:	83 ec 08             	sub    $0x8,%esp
f0103b91:	ff 73 30             	pushl  0x30(%ebx)
f0103b94:	68 c2 75 10 f0       	push   $0xf01075c2
f0103b99:	e8 b3 fc ff ff       	call   f0103851 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103b9e:	83 c4 08             	add    $0x8,%esp
f0103ba1:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103ba5:	50                   	push   %eax
f0103ba6:	68 d1 75 10 f0       	push   $0xf01075d1
f0103bab:	e8 a1 fc ff ff       	call   f0103851 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103bb0:	83 c4 08             	add    $0x8,%esp
f0103bb3:	ff 73 38             	pushl  0x38(%ebx)
f0103bb6:	68 e4 75 10 f0       	push   $0xf01075e4
f0103bbb:	e8 91 fc ff ff       	call   f0103851 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103bc0:	83 c4 10             	add    $0x10,%esp
f0103bc3:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103bc7:	74 25                	je     f0103bee <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103bc9:	83 ec 08             	sub    $0x8,%esp
f0103bcc:	ff 73 3c             	pushl  0x3c(%ebx)
f0103bcf:	68 f3 75 10 f0       	push   $0xf01075f3
f0103bd4:	e8 78 fc ff ff       	call   f0103851 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103bd9:	83 c4 08             	add    $0x8,%esp
f0103bdc:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103be0:	50                   	push   %eax
f0103be1:	68 02 76 10 f0       	push   $0xf0107602
f0103be6:	e8 66 fc ff ff       	call   f0103851 <cprintf>
f0103beb:	83 c4 10             	add    $0x10,%esp
	}
}
f0103bee:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103bf1:	5b                   	pop    %ebx
f0103bf2:	5e                   	pop    %esi
f0103bf3:	5d                   	pop    %ebp
f0103bf4:	c3                   	ret    

f0103bf5 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103bf5:	55                   	push   %ebp
f0103bf6:	89 e5                	mov    %esp,%ebp
f0103bf8:	57                   	push   %edi
f0103bf9:	56                   	push   %esi
f0103bfa:	53                   	push   %ebx
f0103bfb:	83 ec 1c             	sub    $0x1c,%esp
f0103bfe:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103c01:	0f 20 d6             	mov    %cr2,%esi
	// LAB 3: Your code here.


	//If the processor is already in kernel mode when the interrupt or exception occurs 
	//(the low 2 bits of the CS register are already zero), Hence we have to check the CS register to make sure its in kernel mode
	if ((tf->tf_cs & 0x11) == 0){
f0103c04:	f6 43 34 11          	testb  $0x11,0x34(%ebx)
f0103c08:	75 15                	jne    f0103c1f <page_fault_handler+0x2a>
		panic("Fault occured in kernel space on %08x \n",fault_va);
f0103c0a:	56                   	push   %esi
f0103c0b:	68 d8 77 10 f0       	push   $0xf01077d8
f0103c10:	68 47 01 00 00       	push   $0x147
f0103c15:	68 15 76 10 f0       	push   $0xf0107615
f0103c1a:	e8 21 c4 ff ff       	call   f0100040 <_panic>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	//Store the current env's stack tf_esp for use, if the call occurs inside UXtrapframe  
	const uint32_t cur_tf_esp_addr = (uint32_t)(tf->tf_esp); 	// trap-time esp
f0103c1f:	8b 7b 3c             	mov    0x3c(%ebx),%edi

	

	// If there is no env_pgfault_upcall or no page fault handler for the curenv follow the original procedure
	if (!curenv->env_pgfault_upcall)
f0103c22:	e8 a4 1d 00 00       	call   f01059cb <cpunum>
f0103c27:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c2a:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0103c30:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f0103c34:	75 46                	jne    f0103c7c <page_fault_handler+0x87>
	{
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c36:	8b 43 30             	mov    0x30(%ebx),%eax
f0103c39:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			curenv->env_id, fault_va, tf->tf_eip);
f0103c3c:	e8 8a 1d 00 00       	call   f01059cb <cpunum>
	

	// If there is no env_pgfault_upcall or no page fault handler for the curenv follow the original procedure
	if (!curenv->env_pgfault_upcall)
	{
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c41:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103c44:	56                   	push   %esi
			curenv->env_id, fault_va, tf->tf_eip);
f0103c45:	6b c0 74             	imul   $0x74,%eax,%eax
	

	// If there is no env_pgfault_upcall or no page fault handler for the curenv follow the original procedure
	if (!curenv->env_pgfault_upcall)
	{
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c48:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0103c4e:	ff 70 48             	pushl  0x48(%eax)
f0103c51:	68 00 78 10 f0       	push   $0xf0107800
f0103c56:	e8 f6 fb ff ff       	call   f0103851 <cprintf>
			curenv->env_id, fault_va, tf->tf_eip);
		print_trapframe(tf);
f0103c5b:	89 1c 24             	mov    %ebx,(%esp)
f0103c5e:	e8 0a fe ff ff       	call   f0103a6d <print_trapframe>
		env_destroy(curenv);	// Destroy the environment that caused the fault.
f0103c63:	e8 63 1d 00 00       	call   f01059cb <cpunum>
f0103c68:	83 c4 04             	add    $0x4,%esp
f0103c6b:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c6e:	ff b0 48 10 23 f0    	pushl  -0xfdcefb8(%eax)
f0103c74:	e8 11 f9 ff ff       	call   f010358a <env_destroy>
f0103c79:	83 c4 10             	add    $0x10,%esp
	}
	
	//Check if the	
	struct UTrapframe* usertf = NULL; //As defined in inc/trap.h
	
	if((cur_tf_esp_addr < UXSTACKTOP) && (cur_tf_esp_addr >=(UXSTACKTOP - PGSIZE)))
f0103c7c:	8d 97 00 10 40 11    	lea    0x11401000(%edi),%edx
	{
		//If its already inside the exception stack
		//Allocate the address by leaving space for 32-bit word
		usertf = (struct UTrapframe*)(cur_tf_esp_addr - 4 - sizeof(struct UTrapframe));
f0103c82:	8d 47 c8             	lea    -0x38(%edi),%eax
f0103c85:	81 fa ff 0f 00 00    	cmp    $0xfff,%edx
f0103c8b:	ba cc ff bf ee       	mov    $0xeebfffcc,%edx
f0103c90:	0f 46 d0             	cmovbe %eax,%edx
f0103c93:	89 d7                	mov    %edx,%edi
		usertf = (struct UTrapframe*)(UXSTACKTOP - sizeof(struct UTrapframe));
	}
	
	//Check whether the usertf memory is valid
	//This function will not return if there is a fault and it will also destroy the environment
	user_mem_assert(curenv, (void*)usertf, sizeof(struct UTrapframe), PTE_U | PTE_P | PTE_W);
f0103c95:	e8 31 1d 00 00       	call   f01059cb <cpunum>
f0103c9a:	6a 07                	push   $0x7
f0103c9c:	6a 34                	push   $0x34
f0103c9e:	57                   	push   %edi
f0103c9f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ca2:	ff b0 48 10 23 f0    	pushl  -0xfdcefb8(%eax)
f0103ca8:	e8 47 f2 ff ff       	call   f0102ef4 <user_mem_assert>
	
	
	// User exeception trapframe
	usertf->utf_fault_va = fault_va;
f0103cad:	89 fa                	mov    %edi,%edx
f0103caf:	89 37                	mov    %esi,(%edi)
	usertf->utf_err = tf->tf_err;
f0103cb1:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103cb4:	89 47 04             	mov    %eax,0x4(%edi)
	usertf->utf_regs = tf->tf_regs;
f0103cb7:	8d 7f 08             	lea    0x8(%edi),%edi
f0103cba:	b9 08 00 00 00       	mov    $0x8,%ecx
f0103cbf:	89 de                	mov    %ebx,%esi
f0103cc1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	usertf->utf_eip = tf->tf_eip;
f0103cc3:	8b 43 30             	mov    0x30(%ebx),%eax
f0103cc6:	89 42 28             	mov    %eax,0x28(%edx)
	usertf->utf_esp = tf->tf_esp;
f0103cc9:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103ccc:	89 42 30             	mov    %eax,0x30(%edx)
	usertf->utf_eflags = tf->tf_eflags;
f0103ccf:	8b 43 38             	mov    0x38(%ebx),%eax
f0103cd2:	89 42 2c             	mov    %eax,0x2c(%edx)
	
	//Setup the tf with Exception stack frame
	
	tf->tf_esp= (uintptr_t)usertf;
f0103cd5:	89 53 3c             	mov    %edx,0x3c(%ebx)
	tf->tf_eip = (uintptr_t)curenv->env_pgfault_upcall; 
f0103cd8:	e8 ee 1c 00 00       	call   f01059cb <cpunum>
f0103cdd:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ce0:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0103ce6:	8b 40 64             	mov    0x64(%eax),%eax
f0103ce9:	89 43 30             	mov    %eax,0x30(%ebx)

	env_run(curenv);
f0103cec:	e8 da 1c 00 00       	call   f01059cb <cpunum>
f0103cf1:	83 c4 04             	add    $0x4,%esp
f0103cf4:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cf7:	ff b0 48 10 23 f0    	pushl  -0xfdcefb8(%eax)
f0103cfd:	e8 27 f9 ff ff       	call   f0103629 <env_run>

f0103d02 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103d02:	55                   	push   %ebp
f0103d03:	89 e5                	mov    %esp,%ebp
f0103d05:	57                   	push   %edi
f0103d06:	56                   	push   %esi
f0103d07:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103d0a:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103d0b:	83 3d c0 0e 23 f0 00 	cmpl   $0x0,0xf0230ec0
f0103d12:	74 01                	je     f0103d15 <trap+0x13>
		asm volatile("hlt");
f0103d14:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103d15:	e8 b1 1c 00 00       	call   f01059cb <cpunum>
f0103d1a:	6b d0 74             	imul   $0x74,%eax,%edx
f0103d1d:	81 c2 40 10 23 f0    	add    $0xf0231040,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0103d23:	b8 01 00 00 00       	mov    $0x1,%eax
f0103d28:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103d2c:	83 f8 02             	cmp    $0x2,%eax
f0103d2f:	75 10                	jne    f0103d41 <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103d31:	83 ec 0c             	sub    $0xc,%esp
f0103d34:	68 c0 04 12 f0       	push   $0xf01204c0
f0103d39:	e8 f8 1e 00 00       	call   f0105c36 <spin_lock>
f0103d3e:	83 c4 10             	add    $0x10,%esp

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103d41:	9c                   	pushf  
f0103d42:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103d43:	f6 c4 02             	test   $0x2,%ah
f0103d46:	74 19                	je     f0103d61 <trap+0x5f>
f0103d48:	68 21 76 10 f0       	push   $0xf0107621
f0103d4d:	68 5b 70 10 f0       	push   $0xf010705b
f0103d52:	68 0d 01 00 00       	push   $0x10d
f0103d57:	68 15 76 10 f0       	push   $0xf0107615
f0103d5c:	e8 df c2 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103d61:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103d65:	83 e0 03             	and    $0x3,%eax
f0103d68:	66 83 f8 03          	cmp    $0x3,%ax
f0103d6c:	0f 85 a0 00 00 00    	jne    f0103e12 <trap+0x110>
f0103d72:	83 ec 0c             	sub    $0xc,%esp
f0103d75:	68 c0 04 12 f0       	push   $0xf01204c0
f0103d7a:	e8 b7 1e 00 00       	call   f0105c36 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel(); //Lock Kernel
		assert(curenv);
f0103d7f:	e8 47 1c 00 00       	call   f01059cb <cpunum>
f0103d84:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d87:	83 c4 10             	add    $0x10,%esp
f0103d8a:	83 b8 48 10 23 f0 00 	cmpl   $0x0,-0xfdcefb8(%eax)
f0103d91:	75 19                	jne    f0103dac <trap+0xaa>
f0103d93:	68 3a 76 10 f0       	push   $0xf010763a
f0103d98:	68 5b 70 10 f0       	push   $0xf010705b
f0103d9d:	68 15 01 00 00       	push   $0x115
f0103da2:	68 15 76 10 f0       	push   $0xf0107615
f0103da7:	e8 94 c2 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103dac:	e8 1a 1c 00 00       	call   f01059cb <cpunum>
f0103db1:	6b c0 74             	imul   $0x74,%eax,%eax
f0103db4:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0103dba:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103dbe:	75 2d                	jne    f0103ded <trap+0xeb>
			env_free(curenv);
f0103dc0:	e8 06 1c 00 00       	call   f01059cb <cpunum>
f0103dc5:	83 ec 0c             	sub    $0xc,%esp
f0103dc8:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dcb:	ff b0 48 10 23 f0    	pushl  -0xfdcefb8(%eax)
f0103dd1:	e8 d9 f5 ff ff       	call   f01033af <env_free>
			curenv = NULL;
f0103dd6:	e8 f0 1b 00 00       	call   f01059cb <cpunum>
f0103ddb:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dde:	c7 80 48 10 23 f0 00 	movl   $0x0,-0xfdcefb8(%eax)
f0103de5:	00 00 00 
			sched_yield();
f0103de8:	e8 f5 03 00 00       	call   f01041e2 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103ded:	e8 d9 1b 00 00       	call   f01059cb <cpunum>
f0103df2:	6b c0 74             	imul   $0x74,%eax,%eax
f0103df5:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0103dfb:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103e00:	89 c7                	mov    %eax,%edi
f0103e02:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103e04:	e8 c2 1b 00 00       	call   f01059cb <cpunum>
f0103e09:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e0c:	8b b0 48 10 23 f0    	mov    -0xfdcefb8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103e12:	89 35 80 0a 23 f0    	mov    %esi,0xf0230a80
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	//call trap_handler function for page_fault
	switch (tf->tf_trapno) {
f0103e18:	8b 46 28             	mov    0x28(%esi),%eax
f0103e1b:	83 f8 0e             	cmp    $0xe,%eax
f0103e1e:	74 24                	je     f0103e44 <trap+0x142>
f0103e20:	83 f8 30             	cmp    $0x30,%eax
f0103e23:	74 28                	je     f0103e4d <trap+0x14b>
f0103e25:	83 f8 03             	cmp    $0x3,%eax
f0103e28:	75 44                	jne    f0103e6e <trap+0x16c>
		case T_BRKPT:
			monitor(tf);
f0103e2a:	83 ec 0c             	sub    $0xc,%esp
f0103e2d:	56                   	push   %esi
f0103e2e:	e8 ab ca ff ff       	call   f01008de <monitor>
			cprintf("return from breakpoint....\n");
f0103e33:	c7 04 24 41 76 10 f0 	movl   $0xf0107641,(%esp)
f0103e3a:	e8 12 fa ff ff       	call   f0103851 <cprintf>
f0103e3f:	83 c4 10             	add    $0x10,%esp
f0103e42:	eb 2a                	jmp    f0103e6e <trap+0x16c>
			break;

		case T_PGFLT:
			page_fault_handler(tf);
f0103e44:	83 ec 0c             	sub    $0xc,%esp
f0103e47:	56                   	push   %esi
f0103e48:	e8 a8 fd ff ff       	call   f0103bf5 <page_fault_handler>
			break;

		case T_SYSCALL:
			tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax,
f0103e4d:	83 ec 08             	sub    $0x8,%esp
f0103e50:	ff 76 04             	pushl  0x4(%esi)
f0103e53:	ff 36                	pushl  (%esi)
f0103e55:	ff 76 10             	pushl  0x10(%esi)
f0103e58:	ff 76 18             	pushl  0x18(%esi)
f0103e5b:	ff 76 14             	pushl  0x14(%esi)
f0103e5e:	ff 76 1c             	pushl  0x1c(%esi)
f0103e61:	e8 5c 04 00 00       	call   f01042c2 <syscall>
f0103e66:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103e69:	83 c4 20             	add    $0x20,%esp
f0103e6c:	eb 74                	jmp    f0103ee2 <trap+0x1e0>
	}

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0103e6e:	8b 46 28             	mov    0x28(%esi),%eax
f0103e71:	83 f8 27             	cmp    $0x27,%eax
f0103e74:	75 1a                	jne    f0103e90 <trap+0x18e>
		cprintf("Spurious interrupt on irq 7\n");
f0103e76:	83 ec 0c             	sub    $0xc,%esp
f0103e79:	68 5d 76 10 f0       	push   $0xf010765d
f0103e7e:	e8 ce f9 ff ff       	call   f0103851 <cprintf>
		print_trapframe(tf);
f0103e83:	89 34 24             	mov    %esi,(%esp)
f0103e86:	e8 e2 fb ff ff       	call   f0103a6d <print_trapframe>
f0103e8b:	83 c4 10             	add    $0x10,%esp
f0103e8e:	eb 52                	jmp    f0103ee2 <trap+0x1e0>
	}

	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_TIMER) {
f0103e90:	83 f8 20             	cmp    $0x20,%eax
f0103e93:	75 0a                	jne    f0103e9f <trap+0x19d>
		lapic_eoi();
f0103e95:	e8 7c 1c 00 00       	call   f0105b16 <lapic_eoi>
		sched_yield();
f0103e9a:	e8 43 03 00 00       	call   f01041e2 <sched_yield>
	}
	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103e9f:	83 ec 0c             	sub    $0xc,%esp
f0103ea2:	56                   	push   %esi
f0103ea3:	e8 c5 fb ff ff       	call   f0103a6d <print_trapframe>
	if (tf->tf_cs == GD_KT){
f0103ea8:	83 c4 10             	add    $0x10,%esp
f0103eab:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103eb0:	75 17                	jne    f0103ec9 <trap+0x1c7>
		panic("unhandled trap in kernel");
f0103eb2:	83 ec 04             	sub    $0x4,%esp
f0103eb5:	68 7a 76 10 f0       	push   $0xf010767a
f0103eba:	68 f2 00 00 00       	push   $0xf2
f0103ebf:	68 15 76 10 f0       	push   $0xf0107615
f0103ec4:	e8 77 c1 ff ff       	call   f0100040 <_panic>
	}
	else {
		env_destroy(curenv);
f0103ec9:	e8 fd 1a 00 00       	call   f01059cb <cpunum>
f0103ece:	83 ec 0c             	sub    $0xc,%esp
f0103ed1:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ed4:	ff b0 48 10 23 f0    	pushl  -0xfdcefb8(%eax)
f0103eda:	e8 ab f6 ff ff       	call   f010358a <env_destroy>
f0103edf:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103ee2:	e8 e4 1a 00 00       	call   f01059cb <cpunum>
f0103ee7:	6b c0 74             	imul   $0x74,%eax,%eax
f0103eea:	83 b8 48 10 23 f0 00 	cmpl   $0x0,-0xfdcefb8(%eax)
f0103ef1:	74 2a                	je     f0103f1d <trap+0x21b>
f0103ef3:	e8 d3 1a 00 00       	call   f01059cb <cpunum>
f0103ef8:	6b c0 74             	imul   $0x74,%eax,%eax
f0103efb:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0103f01:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103f05:	75 16                	jne    f0103f1d <trap+0x21b>
		env_run(curenv);
f0103f07:	e8 bf 1a 00 00       	call   f01059cb <cpunum>
f0103f0c:	83 ec 0c             	sub    $0xc,%esp
f0103f0f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f12:	ff b0 48 10 23 f0    	pushl  -0xfdcefb8(%eax)
f0103f18:	e8 0c f7 ff ff       	call   f0103629 <env_run>
	else
		sched_yield();
f0103f1d:	e8 c0 02 00 00       	call   f01041e2 <sched_yield>

f0103f22 <handler_0>:
#define T_DEFAULT   500		// catchall
*/

//TRAPHANDLER_NOEC for traps without error code
// From 0-7 no error code requred
	TRAPHANDLER_NOEC(handler_0, 0)   #Divide error
f0103f22:	6a 00                	push   $0x0
f0103f24:	6a 00                	push   $0x0
f0103f26:	e9 d2 01 00 00       	jmp    f01040fd <_alltraps>
f0103f2b:	90                   	nop

f0103f2c <handler_1>:
	TRAPHANDLER_NOEC(handler_1, 1)   #Debug exceptions 
f0103f2c:	6a 00                	push   $0x0
f0103f2e:	6a 01                	push   $0x1
f0103f30:	e9 c8 01 00 00       	jmp    f01040fd <_alltraps>
f0103f35:	90                   	nop

f0103f36 <handler_2>:
 	TRAPHANDLER_NOEC(handler_2, 2)   //NMI Interrupt
f0103f36:	6a 00                	push   $0x0
f0103f38:	6a 02                	push   $0x2
f0103f3a:	e9 be 01 00 00       	jmp    f01040fd <_alltraps>
f0103f3f:	90                   	nop

f0103f40 <handler_3>:
	TRAPHANDLER_NOEC(handler_3, 3)   //Breakpoint
f0103f40:	6a 00                	push   $0x0
f0103f42:	6a 03                	push   $0x3
f0103f44:	e9 b4 01 00 00       	jmp    f01040fd <_alltraps>
f0103f49:	90                   	nop

f0103f4a <handler_4>:
	TRAPHANDLER_NOEC(handler_4, 4)   //Overflow
f0103f4a:	6a 00                	push   $0x0
f0103f4c:	6a 04                	push   $0x4
f0103f4e:	e9 aa 01 00 00       	jmp    f01040fd <_alltraps>
f0103f53:	90                   	nop

f0103f54 <handler_5>:
	TRAPHANDLER_NOEC(handler_5, 5)   //Bounds check 
f0103f54:	6a 00                	push   $0x0
f0103f56:	6a 05                	push   $0x5
f0103f58:	e9 a0 01 00 00       	jmp    f01040fd <_alltraps>
f0103f5d:	90                   	nop

f0103f5e <handler_6>:
	TRAPHANDLER_NOEC(handler_6, 6)   //Invalid opcode
f0103f5e:	6a 00                	push   $0x0
f0103f60:	6a 06                	push   $0x6
f0103f62:	e9 96 01 00 00       	jmp    f01040fd <_alltraps>
f0103f67:	90                   	nop

f0103f68 <handler_7>:
	TRAPHANDLER_NOEC(handler_7, 7)   //Coprocessor not available
f0103f68:	6a 00                	push   $0x0
f0103f6a:	6a 07                	push   $0x7
f0103f6c:	e9 8c 01 00 00       	jmp    f01040fd <_alltraps>
f0103f71:	90                   	nop

f0103f72 <handler_8>:
	
	TRAPHANDLER(handler_8, 8)   // double fault
f0103f72:	6a 08                	push   $0x8
f0103f74:	e9 84 01 00 00       	jmp    f01040fd <_alltraps>
f0103f79:	90                   	nop

f0103f7a <handler_9>:
	
	TRAPHANDLER_NOEC(handler_9, 9)   //Coprocessor Segment Overrun
f0103f7a:	6a 00                	push   $0x0
f0103f7c:	6a 09                	push   $0x9
f0103f7e:	e9 7a 01 00 00       	jmp    f01040fd <_alltraps>
f0103f83:	90                   	nop

f0103f84 <handler_10>:

	TRAPHANDLER(handler_10, 10)   // invalid task switch segment
f0103f84:	6a 0a                	push   $0xa
f0103f86:	e9 72 01 00 00       	jmp    f01040fd <_alltraps>
f0103f8b:	90                   	nop

f0103f8c <handler_11>:
	TRAPHANDLER(handler_11, 11)   // segment not present
f0103f8c:	6a 0b                	push   $0xb
f0103f8e:	e9 6a 01 00 00       	jmp    f01040fd <_alltraps>
f0103f93:	90                   	nop

f0103f94 <handler_12>:
	TRAPHANDLER(handler_12, 12)   // stack exception
f0103f94:	6a 0c                	push   $0xc
f0103f96:	e9 62 01 00 00       	jmp    f01040fd <_alltraps>
f0103f9b:	90                   	nop

f0103f9c <handler_13>:
	TRAPHANDLER(handler_13, 13)   // general protection fault
f0103f9c:	6a 0d                	push   $0xd
f0103f9e:	e9 5a 01 00 00       	jmp    f01040fd <_alltraps>
f0103fa3:	90                   	nop

f0103fa4 <handler_14>:
	TRAPHANDLER(handler_14, 14)   // page fault
f0103fa4:	6a 0e                	push   $0xe
f0103fa6:	e9 52 01 00 00       	jmp    f01040fd <_alltraps>
f0103fab:	90                   	nop

f0103fac <handler_15>:

	TRAPHANDLER_NOEC(handler_15, 15)   // Reserved
f0103fac:	6a 00                	push   $0x0
f0103fae:	6a 0f                	push   $0xf
f0103fb0:	e9 48 01 00 00       	jmp    f01040fd <_alltraps>
f0103fb5:	90                   	nop

f0103fb6 <handler_16>:

	TRAPHANDLER_NOEC(handler_16, 16)   // floating point error
f0103fb6:	6a 00                	push   $0x0
f0103fb8:	6a 10                	push   $0x10
f0103fba:	e9 3e 01 00 00       	jmp    f01040fd <_alltraps>
f0103fbf:	90                   	nop

f0103fc0 <handler_17>:

	TRAPHANDLER(handler_17, 17)   // aligment check
f0103fc0:	6a 11                	push   $0x11
f0103fc2:	e9 36 01 00 00       	jmp    f01040fd <_alltraps>
f0103fc7:	90                   	nop

f0103fc8 <handler_18>:

	TRAPHANDLER_NOEC(handler_18, 18)   // machine check
f0103fc8:	6a 00                	push   $0x0
f0103fca:	6a 12                	push   $0x12
f0103fcc:	e9 2c 01 00 00       	jmp    f01040fd <_alltraps>
f0103fd1:	90                   	nop

f0103fd2 <handler_19>:
	TRAPHANDLER_NOEC(handler_19, 19)   // SIMD floating point error
f0103fd2:	6a 00                	push   $0x0
f0103fd4:	6a 13                	push   $0x13
f0103fd6:	e9 22 01 00 00       	jmp    f01040fd <_alltraps>
f0103fdb:	90                   	nop

f0103fdc <handler_20>:

	TRAPHANDLER_NOEC(handler_20, 20)
f0103fdc:	6a 00                	push   $0x0
f0103fde:	6a 14                	push   $0x14
f0103fe0:	e9 18 01 00 00       	jmp    f01040fd <_alltraps>
f0103fe5:	90                   	nop

f0103fe6 <handler_21>:
	TRAPHANDLER_NOEC(handler_21, 21)
f0103fe6:	6a 00                	push   $0x0
f0103fe8:	6a 15                	push   $0x15
f0103fea:	e9 0e 01 00 00       	jmp    f01040fd <_alltraps>
f0103fef:	90                   	nop

f0103ff0 <handler_22>:
	TRAPHANDLER_NOEC(handler_22, 22)
f0103ff0:	6a 00                	push   $0x0
f0103ff2:	6a 16                	push   $0x16
f0103ff4:	e9 04 01 00 00       	jmp    f01040fd <_alltraps>
f0103ff9:	90                   	nop

f0103ffa <handler_23>:
	TRAPHANDLER_NOEC(handler_23, 23)
f0103ffa:	6a 00                	push   $0x0
f0103ffc:	6a 17                	push   $0x17
f0103ffe:	e9 fa 00 00 00       	jmp    f01040fd <_alltraps>
f0104003:	90                   	nop

f0104004 <handler_24>:
	TRAPHANDLER_NOEC(handler_24, 24)
f0104004:	6a 00                	push   $0x0
f0104006:	6a 18                	push   $0x18
f0104008:	e9 f0 00 00 00       	jmp    f01040fd <_alltraps>
f010400d:	90                   	nop

f010400e <handler_25>:
	TRAPHANDLER_NOEC(handler_25, 25)
f010400e:	6a 00                	push   $0x0
f0104010:	6a 19                	push   $0x19
f0104012:	e9 e6 00 00 00       	jmp    f01040fd <_alltraps>
f0104017:	90                   	nop

f0104018 <handler_26>:
	TRAPHANDLER_NOEC(handler_26, 26)
f0104018:	6a 00                	push   $0x0
f010401a:	6a 1a                	push   $0x1a
f010401c:	e9 dc 00 00 00       	jmp    f01040fd <_alltraps>
f0104021:	90                   	nop

f0104022 <handler_27>:
	TRAPHANDLER_NOEC(handler_27, 27)
f0104022:	6a 00                	push   $0x0
f0104024:	6a 1b                	push   $0x1b
f0104026:	e9 d2 00 00 00       	jmp    f01040fd <_alltraps>
f010402b:	90                   	nop

f010402c <handler_28>:
	TRAPHANDLER_NOEC(handler_28, 28)
f010402c:	6a 00                	push   $0x0
f010402e:	6a 1c                	push   $0x1c
f0104030:	e9 c8 00 00 00       	jmp    f01040fd <_alltraps>
f0104035:	90                   	nop

f0104036 <handler_29>:
	TRAPHANDLER_NOEC(handler_29, 29)
f0104036:	6a 00                	push   $0x0
f0104038:	6a 1d                	push   $0x1d
f010403a:	e9 be 00 00 00       	jmp    f01040fd <_alltraps>
f010403f:	90                   	nop

f0104040 <handler_30>:
	TRAPHANDLER_NOEC(handler_30, 30)
f0104040:	6a 00                	push   $0x0
f0104042:	6a 1e                	push   $0x1e
f0104044:	e9 b4 00 00 00       	jmp    f01040fd <_alltraps>
f0104049:	90                   	nop

f010404a <handler_31>:
	TRAPHANDLER_NOEC(handler_31, 31)
f010404a:	6a 00                	push   $0x0
f010404c:	6a 1f                	push   $0x1f
f010404e:	e9 aa 00 00 00       	jmp    f01040fd <_alltraps>
f0104053:	90                   	nop

f0104054 <handler_32>:
	TRAPHANDLER_NOEC(handler_32, 32)
f0104054:	6a 00                	push   $0x0
f0104056:	6a 20                	push   $0x20
f0104058:	e9 a0 00 00 00       	jmp    f01040fd <_alltraps>
f010405d:	90                   	nop

f010405e <handler_33>:
	TRAPHANDLER_NOEC(handler_33, 33)
f010405e:	6a 00                	push   $0x0
f0104060:	6a 21                	push   $0x21
f0104062:	e9 96 00 00 00       	jmp    f01040fd <_alltraps>
f0104067:	90                   	nop

f0104068 <handler_34>:
	TRAPHANDLER_NOEC(handler_34, 34)
f0104068:	6a 00                	push   $0x0
f010406a:	6a 22                	push   $0x22
f010406c:	e9 8c 00 00 00       	jmp    f01040fd <_alltraps>
f0104071:	90                   	nop

f0104072 <handler_35>:
	TRAPHANDLER_NOEC(handler_35, 35)
f0104072:	6a 00                	push   $0x0
f0104074:	6a 23                	push   $0x23
f0104076:	e9 82 00 00 00       	jmp    f01040fd <_alltraps>
f010407b:	90                   	nop

f010407c <handler_36>:
	TRAPHANDLER_NOEC(handler_36, 36)
f010407c:	6a 00                	push   $0x0
f010407e:	6a 24                	push   $0x24
f0104080:	e9 78 00 00 00       	jmp    f01040fd <_alltraps>
f0104085:	90                   	nop

f0104086 <handler_37>:
	TRAPHANDLER_NOEC(handler_37, 37)
f0104086:	6a 00                	push   $0x0
f0104088:	6a 25                	push   $0x25
f010408a:	e9 6e 00 00 00       	jmp    f01040fd <_alltraps>
f010408f:	90                   	nop

f0104090 <handler_38>:
	TRAPHANDLER_NOEC(handler_38, 38)
f0104090:	6a 00                	push   $0x0
f0104092:	6a 26                	push   $0x26
f0104094:	e9 64 00 00 00       	jmp    f01040fd <_alltraps>
f0104099:	90                   	nop

f010409a <handler_39>:
	TRAPHANDLER_NOEC(handler_39, 39)
f010409a:	6a 00                	push   $0x0
f010409c:	6a 27                	push   $0x27
f010409e:	e9 5a 00 00 00       	jmp    f01040fd <_alltraps>
f01040a3:	90                   	nop

f01040a4 <handler_40>:
	TRAPHANDLER_NOEC(handler_40, 40)
f01040a4:	6a 00                	push   $0x0
f01040a6:	6a 28                	push   $0x28
f01040a8:	e9 50 00 00 00       	jmp    f01040fd <_alltraps>
f01040ad:	90                   	nop

f01040ae <handler_41>:
	TRAPHANDLER_NOEC(handler_41, 41)
f01040ae:	6a 00                	push   $0x0
f01040b0:	6a 29                	push   $0x29
f01040b2:	e9 46 00 00 00       	jmp    f01040fd <_alltraps>
f01040b7:	90                   	nop

f01040b8 <handler_42>:
	TRAPHANDLER_NOEC(handler_42, 42)
f01040b8:	6a 00                	push   $0x0
f01040ba:	6a 2a                	push   $0x2a
f01040bc:	e9 3c 00 00 00       	jmp    f01040fd <_alltraps>
f01040c1:	90                   	nop

f01040c2 <handler_43>:
	TRAPHANDLER_NOEC(handler_43, 43)
f01040c2:	6a 00                	push   $0x0
f01040c4:	6a 2b                	push   $0x2b
f01040c6:	e9 32 00 00 00       	jmp    f01040fd <_alltraps>
f01040cb:	90                   	nop

f01040cc <handler_44>:
	TRAPHANDLER_NOEC(handler_44, 44)
f01040cc:	6a 00                	push   $0x0
f01040ce:	6a 2c                	push   $0x2c
f01040d0:	e9 28 00 00 00       	jmp    f01040fd <_alltraps>
f01040d5:	90                   	nop

f01040d6 <handler_45>:
	TRAPHANDLER_NOEC(handler_45, 45)
f01040d6:	6a 00                	push   $0x0
f01040d8:	6a 2d                	push   $0x2d
f01040da:	e9 1e 00 00 00       	jmp    f01040fd <_alltraps>
f01040df:	90                   	nop

f01040e0 <handler_46>:
	TRAPHANDLER_NOEC(handler_46, 46)
f01040e0:	6a 00                	push   $0x0
f01040e2:	6a 2e                	push   $0x2e
f01040e4:	e9 14 00 00 00       	jmp    f01040fd <_alltraps>
f01040e9:	90                   	nop

f01040ea <handler_47>:
	TRAPHANDLER_NOEC(handler_47, 47)
f01040ea:	6a 00                	push   $0x0
f01040ec:	6a 2f                	push   $0x2f
f01040ee:	e9 0a 00 00 00       	jmp    f01040fd <_alltraps>
f01040f3:	90                   	nop

f01040f4 <handler_48>:

	TRAPHANDLER_NOEC(handler_48, 48)   // system call
f01040f4:	6a 00                	push   $0x0
f01040f6:	6a 30                	push   $0x30
f01040f8:	e9 00 00 00 00       	jmp    f01040fd <_alltraps>

f01040fd <_alltraps>:
 */

.globl _alltraps
_alltraps:
	#Remaining Trap frame
	push %ds
f01040fd:	1e                   	push   %ds
	push %es
f01040fe:	06                   	push   %es
	pushal
f01040ff:	60                   	pusha  

	
	movw $GD_KD, %ax
f0104100:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f0104104:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f0104106:	8e c0                	mov    %eax,%es

	#call Trap 
	pushl %esp
f0104108:	54                   	push   %esp
	call trap
f0104109:	e8 f4 fb ff ff       	call   f0103d02 <trap>

f010410e <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f010410e:	55                   	push   %ebp
f010410f:	89 e5                	mov    %esp,%ebp
f0104111:	83 ec 08             	sub    $0x8,%esp
f0104114:	a1 6c 02 23 f0       	mov    0xf023026c,%eax
f0104119:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f010411c:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
f0104121:	8b 02                	mov    (%edx),%eax
f0104123:	83 e8 01             	sub    $0x1,%eax
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0104126:	83 f8 02             	cmp    $0x2,%eax
f0104129:	76 10                	jbe    f010413b <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f010412b:	83 c1 01             	add    $0x1,%ecx
f010412e:	83 c2 7c             	add    $0x7c,%edx
f0104131:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0104137:	75 e8                	jne    f0104121 <sched_halt+0x13>
f0104139:	eb 08                	jmp    f0104143 <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f010413b:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0104141:	75 1f                	jne    f0104162 <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f0104143:	83 ec 0c             	sub    $0xc,%esp
f0104146:	68 90 78 10 f0       	push   $0xf0107890
f010414b:	e8 01 f7 ff ff       	call   f0103851 <cprintf>
f0104150:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f0104153:	83 ec 0c             	sub    $0xc,%esp
f0104156:	6a 00                	push   $0x0
f0104158:	e8 81 c7 ff ff       	call   f01008de <monitor>
f010415d:	83 c4 10             	add    $0x10,%esp
f0104160:	eb f1                	jmp    f0104153 <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0104162:	e8 64 18 00 00       	call   f01059cb <cpunum>
f0104167:	6b c0 74             	imul   $0x74,%eax,%eax
f010416a:	c7 80 48 10 23 f0 00 	movl   $0x0,-0xfdcefb8(%eax)
f0104171:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0104174:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0104179:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010417e:	77 12                	ja     f0104192 <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0104180:	50                   	push   %eax
f0104181:	68 c8 60 10 f0       	push   $0xf01060c8
f0104186:	6a 54                	push   $0x54
f0104188:	68 b9 78 10 f0       	push   $0xf01078b9
f010418d:	e8 ae be ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0104192:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0104197:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f010419a:	e8 2c 18 00 00       	call   f01059cb <cpunum>
f010419f:	6b d0 74             	imul   $0x74,%eax,%edx
f01041a2:	81 c2 40 10 23 f0    	add    $0xf0231040,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f01041a8:	b8 02 00 00 00       	mov    $0x2,%eax
f01041ad:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01041b1:	83 ec 0c             	sub    $0xc,%esp
f01041b4:	68 c0 04 12 f0       	push   $0xf01204c0
f01041b9:	e8 15 1b 00 00       	call   f0105cd3 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01041be:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f01041c0:	e8 06 18 00 00       	call   f01059cb <cpunum>
f01041c5:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f01041c8:	8b 80 50 10 23 f0    	mov    -0xfdcefb0(%eax),%eax
f01041ce:	bd 00 00 00 00       	mov    $0x0,%ebp
f01041d3:	89 c4                	mov    %eax,%esp
f01041d5:	6a 00                	push   $0x0
f01041d7:	6a 00                	push   $0x0
f01041d9:	fb                   	sti    
f01041da:	f4                   	hlt    
f01041db:	eb fd                	jmp    f01041da <sched_halt+0xcc>
f01041dd:	83 c4 10             	add    $0x10,%esp
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f01041e0:	c9                   	leave  
f01041e1:	c3                   	ret    

f01041e2 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f01041e2:	55                   	push   %ebp
f01041e3:	89 e5                	mov    %esp,%ebp
f01041e5:	53                   	push   %ebx
f01041e6:	83 ec 04             	sub    $0x4,%esp
	// below to halt the cpu.

	// LAB 4: Your code here.
	int envVal, j = 0 ;
	 
	if (curenv)
f01041e9:	e8 dd 17 00 00       	call   f01059cb <cpunum>
f01041ee:	6b c0 74             	imul   $0x74,%eax,%eax
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
						     // we can use the value 'curenv- envs' to get the current env and +1 to get the next env
	else 
		envVal = 0; 
f01041f1:	ba 00 00 00 00       	mov    $0x0,%edx
	// below to halt the cpu.

	// LAB 4: Your code here.
	int envVal, j = 0 ;
	 
	if (curenv)
f01041f6:	83 b8 48 10 23 f0 00 	cmpl   $0x0,-0xfdcefb8(%eax)
f01041fd:	74 33                	je     f0104232 <sched_yield+0x50>
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
f01041ff:	e8 c7 17 00 00       	call   f01059cb <cpunum>
f0104204:	6b c0 74             	imul   $0x74,%eax,%eax
f0104207:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f010420d:	2b 05 6c 02 23 f0    	sub    0xf023026c,%eax
f0104213:	c1 f8 02             	sar    $0x2,%eax
f0104216:	69 c0 df 7b ef bd    	imul   $0xbdef7bdf,%eax,%eax
f010421c:	83 c0 01             	add    $0x1,%eax
f010421f:	89 c1                	mov    %eax,%ecx
f0104221:	c1 f9 1f             	sar    $0x1f,%ecx
f0104224:	c1 e9 16             	shr    $0x16,%ecx
f0104227:	8d 14 08             	lea    (%eax,%ecx,1),%edx
f010422a:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0104230:	29 ca                	sub    %ecx,%edx
	else 
		envVal = 0; 
	
	for (j = 0; j< NENV; j++)
	{
		if (envs[envVal].env_status == ENV_RUNNABLE)
f0104232:	a1 6c 02 23 f0       	mov    0xf023026c,%eax
f0104237:	b9 00 04 00 00       	mov    $0x400,%ecx
f010423c:	6b da 7c             	imul   $0x7c,%edx,%ebx
f010423f:	83 7c 18 54 02       	cmpl   $0x2,0x54(%eax,%ebx,1)
f0104244:	74 70                	je     f01042b6 <sched_yield+0xd4>
		    break;
		else
		    envVal=(envVal+1)%NENV;
f0104246:	83 c2 01             	add    $0x1,%edx
f0104249:	89 d3                	mov    %edx,%ebx
f010424b:	c1 fb 1f             	sar    $0x1f,%ebx
f010424e:	c1 eb 16             	shr    $0x16,%ebx
f0104251:	01 da                	add    %ebx,%edx
f0104253:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0104259:	29 da                	sub    %ebx,%edx
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
						     // we can use the value 'curenv- envs' to get the current env and +1 to get the next env
	else 
		envVal = 0; 
	
	for (j = 0; j< NENV; j++)
f010425b:	83 e9 01             	sub    $0x1,%ecx
f010425e:	75 dc                	jne    f010423c <sched_yield+0x5a>
		    break;
		else
		    envVal=(envVal+1)%NENV;
	}
	
	if (envs[envVal].env_status == ENV_RUNNABLE)
f0104260:	6b d2 7c             	imul   $0x7c,%edx,%edx
f0104263:	01 c2                	add    %eax,%edx
f0104265:	83 7a 54 02          	cmpl   $0x2,0x54(%edx)
f0104269:	75 09                	jne    f0104274 <sched_yield+0x92>
	{
	    idle = envs + envVal ;
	    env_run(idle);
f010426b:	83 ec 0c             	sub    $0xc,%esp
f010426e:	52                   	push   %edx
f010426f:	e8 b5 f3 ff ff       	call   f0103629 <env_run>
	} 
	else if (!idle && (curenv) && (curenv->env_status == ENV_RUNNING) ){
f0104274:	e8 52 17 00 00       	call   f01059cb <cpunum>
f0104279:	6b c0 74             	imul   $0x74,%eax,%eax
f010427c:	83 b8 48 10 23 f0 00 	cmpl   $0x0,-0xfdcefb8(%eax)
f0104283:	74 2a                	je     f01042af <sched_yield+0xcd>
f0104285:	e8 41 17 00 00       	call   f01059cb <cpunum>
f010428a:	6b c0 74             	imul   $0x74,%eax,%eax
f010428d:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0104293:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0104297:	75 16                	jne    f01042af <sched_yield+0xcd>
	    env_run(curenv) ;
f0104299:	e8 2d 17 00 00       	call   f01059cb <cpunum>
f010429e:	83 ec 0c             	sub    $0xc,%esp
f01042a1:	6b c0 74             	imul   $0x74,%eax,%eax
f01042a4:	ff b0 48 10 23 f0    	pushl  -0xfdcefb8(%eax)
f01042aa:	e8 7a f3 ff ff       	call   f0103629 <env_run>
	}
	// sched_halt never returns
	sched_halt();
f01042af:	e8 5a fe ff ff       	call   f010410e <sched_halt>
f01042b4:	eb 07                	jmp    f01042bd <sched_yield+0xdb>
		    break;
		else
		    envVal=(envVal+1)%NENV;
	}
	
	if (envs[envVal].env_status == ENV_RUNNABLE)
f01042b6:	6b d2 7c             	imul   $0x7c,%edx,%edx
f01042b9:	01 c2                	add    %eax,%edx
f01042bb:	eb ae                	jmp    f010426b <sched_yield+0x89>
	else if (!idle && (curenv) && (curenv->env_status == ENV_RUNNING) ){
	    env_run(curenv) ;
	}
	// sched_halt never returns
	sched_halt();
}
f01042bd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01042c0:	c9                   	leave  
f01042c1:	c3                   	ret    

f01042c2 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01042c2:	55                   	push   %ebp
f01042c3:	89 e5                	mov    %esp,%ebp
f01042c5:	57                   	push   %edi
f01042c6:	56                   	push   %esi
f01042c7:	53                   	push   %ebx
f01042c8:	83 ec 1c             	sub    $0x1c,%esp
f01042cb:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	

	switch (syscallno) {
f01042ce:	83 f8 0c             	cmp    $0xc,%eax
f01042d1:	0f 87 2d 05 00 00    	ja     f0104804 <syscall+0x542>
f01042d7:	ff 24 85 24 79 10 f0 	jmp    *-0xfef86dc(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_P | PTE_U);
f01042de:	e8 e8 16 00 00       	call   f01059cb <cpunum>
f01042e3:	6a 05                	push   $0x5
f01042e5:	ff 75 10             	pushl  0x10(%ebp)
f01042e8:	ff 75 0c             	pushl  0xc(%ebp)
f01042eb:	6b c0 74             	imul   $0x74,%eax,%eax
f01042ee:	ff b0 48 10 23 f0    	pushl  -0xfdcefb8(%eax)
f01042f4:	e8 fb eb ff ff       	call   f0102ef4 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01042f9:	83 c4 0c             	add    $0xc,%esp
f01042fc:	ff 75 0c             	pushl  0xc(%ebp)
f01042ff:	ff 75 10             	pushl  0x10(%ebp)
f0104302:	68 c6 78 10 f0       	push   $0xf01078c6
f0104307:	e8 45 f5 ff ff       	call   f0103851 <cprintf>
f010430c:	83 c4 10             	add    $0x10,%esp

	switch (syscallno) {

	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;
f010430f:	b8 00 00 00 00       	mov    $0x0,%eax
f0104314:	e9 07 05 00 00       	jmp    f0104820 <syscall+0x55e>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0104319:	e8 c7 c2 ff ff       	call   f01005e5 <cons_getc>
	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;

	case SYS_cgetc:
		return sys_cgetc();
f010431e:	e9 fd 04 00 00       	jmp    f0104820 <syscall+0x55e>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0104323:	e8 a3 16 00 00       	call   f01059cb <cpunum>
f0104328:	6b c0 74             	imul   $0x74,%eax,%eax
f010432b:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0104331:	8b 40 48             	mov    0x48(%eax),%eax

	case SYS_cgetc:
		return sys_cgetc();
		
	case SYS_getenvid:
		return sys_getenvid();
f0104334:	e9 e7 04 00 00       	jmp    f0104820 <syscall+0x55e>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0104339:	83 ec 04             	sub    $0x4,%esp
f010433c:	6a 01                	push   $0x1
f010433e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104341:	50                   	push   %eax
f0104342:	ff 75 0c             	pushl  0xc(%ebp)
f0104345:	e8 7a ec ff ff       	call   f0102fc4 <envid2env>
f010434a:	89 c2                	mov    %eax,%edx
f010434c:	83 c4 10             	add    $0x10,%esp
f010434f:	85 d2                	test   %edx,%edx
f0104351:	0f 88 c9 04 00 00    	js     f0104820 <syscall+0x55e>
		return r;
	if (e == curenv)
f0104357:	e8 6f 16 00 00       	call   f01059cb <cpunum>
f010435c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010435f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104362:	39 90 48 10 23 f0    	cmp    %edx,-0xfdcefb8(%eax)
f0104368:	75 23                	jne    f010438d <syscall+0xcb>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f010436a:	e8 5c 16 00 00       	call   f01059cb <cpunum>
f010436f:	83 ec 08             	sub    $0x8,%esp
f0104372:	6b c0 74             	imul   $0x74,%eax,%eax
f0104375:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f010437b:	ff 70 48             	pushl  0x48(%eax)
f010437e:	68 cb 78 10 f0       	push   $0xf01078cb
f0104383:	e8 c9 f4 ff ff       	call   f0103851 <cprintf>
f0104388:	83 c4 10             	add    $0x10,%esp
f010438b:	eb 25                	jmp    f01043b2 <syscall+0xf0>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f010438d:	8b 5a 48             	mov    0x48(%edx),%ebx
f0104390:	e8 36 16 00 00       	call   f01059cb <cpunum>
f0104395:	83 ec 04             	sub    $0x4,%esp
f0104398:	53                   	push   %ebx
f0104399:	6b c0 74             	imul   $0x74,%eax,%eax
f010439c:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f01043a2:	ff 70 48             	pushl  0x48(%eax)
f01043a5:	68 e6 78 10 f0       	push   $0xf01078e6
f01043aa:	e8 a2 f4 ff ff       	call   f0103851 <cprintf>
f01043af:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f01043b2:	83 ec 0c             	sub    $0xc,%esp
f01043b5:	ff 75 e4             	pushl  -0x1c(%ebp)
f01043b8:	e8 cd f1 ff ff       	call   f010358a <env_destroy>
f01043bd:	83 c4 10             	add    $0x10,%esp
	return 0;
f01043c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01043c5:	e9 56 04 00 00       	jmp    f0104820 <syscall+0x55e>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f01043ca:	e8 13 fe ff ff       	call   f01041e2 <sched_yield>
	// from the current environment -- but tweaked so sys_exofork
	// will appear to return 0.

	// LAB 4: Your code here.
	struct Env* childenv;
	int errcode = env_alloc(&childenv, curenv->env_id);
f01043cf:	e8 f7 15 00 00       	call   f01059cb <cpunum>
f01043d4:	83 ec 08             	sub    $0x8,%esp
f01043d7:	6b c0 74             	imul   $0x74,%eax,%eax
f01043da:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f01043e0:	ff 70 48             	pushl  0x48(%eax)
f01043e3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01043e6:	50                   	push   %eax
f01043e7:	e8 e3 ec ff ff       	call   f01030cf <env_alloc>
f01043ec:	89 c2                	mov    %eax,%edx
	
	//If the error code is less than 0, that means there has been an error while creating an env	
	if (errcode < 0) {
f01043ee:	83 c4 10             	add    $0x10,%esp
f01043f1:	85 d2                	test   %edx,%edx
f01043f3:	0f 88 27 04 00 00    	js     f0104820 <syscall+0x55e>
		return errcode; //Return the environment
	}
	
	//Set the child environment as not runnable	
	childenv->env_status = ENV_NOT_RUNNABLE;
f01043f9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01043fc:	c7 43 54 04 00 00 00 	movl   $0x4,0x54(%ebx)

	//Copy the current environemnt register data into the child
	childenv->env_tf = curenv->env_tf;
f0104403:	e8 c3 15 00 00       	call   f01059cb <cpunum>
f0104408:	6b c0 74             	imul   $0x74,%eax,%eax
f010440b:	8b b0 48 10 23 f0    	mov    -0xfdcefb8(%eax),%esi
f0104411:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104416:	89 df                	mov    %ebx,%edi
f0104418:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

	// when the child is scheduled to run, it has to restart the trapframe. 
	//Hence we modify the register eax to be 0. 

	childenv->env_tf.tf_regs.reg_eax = 0; 
f010441a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010441d:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

	return childenv->env_id;
f0104424:	8b 40 48             	mov    0x48(%eax),%eax
f0104427:	e9 f4 03 00 00       	jmp    f0104820 <syscall+0x55e>

	// LAB 4: Your code here.
	
	struct Env *env_store;
	int errcode; 
	errcode = envid2env(envid, &env_store,1);
f010442c:	83 ec 04             	sub    $0x4,%esp
f010442f:	6a 01                	push   $0x1
f0104431:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104434:	50                   	push   %eax
f0104435:	ff 75 0c             	pushl  0xc(%ebp)
f0104438:	e8 87 eb ff ff       	call   f0102fc4 <envid2env>
	if (errcode < 0)
f010443d:	83 c4 10             	add    $0x10,%esp
f0104440:	85 c0                	test   %eax,%eax
f0104442:	0f 88 d8 03 00 00    	js     f0104820 <syscall+0x55e>
		return errcode;
	
	//Check if status is runnable or not runnable
	if (status == ENV_RUNNABLE || status == ENV_NOT_RUNNABLE)
f0104448:	8b 45 10             	mov    0x10(%ebp),%eax
f010444b:	8d 50 fe             	lea    -0x2(%eax),%edx
		env_store->env_status = status;

	else
		return E_INVAL;
f010444e:	b8 03 00 00 00       	mov    $0x3,%eax
	errcode = envid2env(envid, &env_store,1);
	if (errcode < 0)
		return errcode;
	
	//Check if status is runnable or not runnable
	if (status == ENV_RUNNABLE || status == ENV_NOT_RUNNABLE)
f0104453:	f7 c2 fd ff ff ff    	test   $0xfffffffd,%edx
f0104459:	0f 85 c1 03 00 00    	jne    f0104820 <syscall+0x55e>
		env_store->env_status = status;
f010445f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104462:	8b 75 10             	mov    0x10(%ebp),%esi
f0104465:	89 70 54             	mov    %esi,0x54(%eax)

	else
		return E_INVAL;

	return 0;
f0104468:	b8 00 00 00 00       	mov    $0x0,%eax
f010446d:	e9 ae 03 00 00       	jmp    f0104820 <syscall+0x55e>
	struct Env *en; 
	int code;
	
	//Check for valid address and page alignment
	if((((uint32_t)va) >= UTOP) || (((uint32_t)va) % PGSIZE) !=0)
		return  E_INVAL;
f0104472:	b8 03 00 00 00       	mov    $0x3,%eax
	
	struct Env *en; 
	int code;
	
	//Check for valid address and page alignment
	if((((uint32_t)va) >= UTOP) || (((uint32_t)va) % PGSIZE) !=0)
f0104477:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f010447e:	0f 87 9c 03 00 00    	ja     f0104820 <syscall+0x55e>
f0104484:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f010448b:	0f 85 8f 03 00 00    	jne    f0104820 <syscall+0x55e>
		return  E_INVAL;

	//Check for permissions
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
f0104491:	f7 45 14 fd f1 ff ff 	testl  $0xfffff1fd,0x14(%ebp)
f0104498:	0f 84 82 03 00 00    	je     f0104820 <syscall+0x55e>
		return E_INVAL;

	//Page allocation check
	struct PageInfo *newpage = page_alloc(ALLOC_ZERO); 
f010449e:	83 ec 0c             	sub    $0xc,%esp
f01044a1:	6a 01                	push   $0x1
f01044a3:	e8 f1 ca ff ff       	call   f0100f99 <page_alloc>
f01044a8:	89 c3                	mov    %eax,%ebx
	if (!newpage)
f01044aa:	83 c4 10             	add    $0x10,%esp
		return E_NO_MEM; 
f01044ad:	b8 04 00 00 00       	mov    $0x4,%eax
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
		return E_INVAL;

	//Page allocation check
	struct PageInfo *newpage = page_alloc(ALLOC_ZERO); 
	if (!newpage)
f01044b2:	85 db                	test   %ebx,%ebx
f01044b4:	0f 84 66 03 00 00    	je     f0104820 <syscall+0x55e>
		return E_NO_MEM; 

	//Use environid to get the environment 
	if ((code = envid2env(envid, &en,1))<0)
f01044ba:	83 ec 04             	sub    $0x4,%esp
f01044bd:	6a 01                	push   $0x1
f01044bf:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01044c2:	50                   	push   %eax
f01044c3:	ff 75 0c             	pushl  0xc(%ebp)
f01044c6:	e8 f9 ea ff ff       	call   f0102fc4 <envid2env>
f01044cb:	83 c4 10             	add    $0x10,%esp
f01044ce:	85 c0                	test   %eax,%eax
f01044d0:	0f 88 4a 03 00 00    	js     f0104820 <syscall+0x55e>
		return code;

	//Check if the page mapping is correct otherwise free the page
	code=page_insert(en->env_pgdir,newpage,(void *)va,perm);
f01044d6:	ff 75 14             	pushl  0x14(%ebp)
f01044d9:	ff 75 10             	pushl  0x10(%ebp)
f01044dc:	53                   	push   %ebx
f01044dd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01044e0:	ff 70 60             	pushl  0x60(%eax)
f01044e3:	e8 d7 cd ff ff       	call   f01012bf <page_insert>
f01044e8:	89 c6                	mov    %eax,%esi
	if (code < 0)
f01044ea:	83 c4 10             	add    $0x10,%esp
	{
		page_free(newpage);
		return code;
	}
	
	return 0;
f01044ed:	b8 00 00 00 00       	mov    $0x0,%eax
	if ((code = envid2env(envid, &en,1))<0)
		return code;

	//Check if the page mapping is correct otherwise free the page
	code=page_insert(en->env_pgdir,newpage,(void *)va,perm);
	if (code < 0)
f01044f2:	85 f6                	test   %esi,%esi
f01044f4:	0f 89 26 03 00 00    	jns    f0104820 <syscall+0x55e>
	{
		page_free(newpage);
f01044fa:	83 ec 0c             	sub    $0xc,%esp
f01044fd:	53                   	push   %ebx
f01044fe:	e8 0c cb ff ff       	call   f010100f <page_free>
f0104503:	83 c4 10             	add    $0x10,%esp
		return code;
f0104506:	89 f0                	mov    %esi,%eax
f0104508:	e9 13 03 00 00       	jmp    f0104820 <syscall+0x55e>
	struct Env* src_env;
	struct Env* dst_env;
	int errcode;
	
	//Check for valid src env id
	errcode = envid2env(srcenvid, &src_env, 1);
f010450d:	83 ec 04             	sub    $0x4,%esp
f0104510:	6a 01                	push   $0x1
f0104512:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0104515:	50                   	push   %eax
f0104516:	ff 75 0c             	pushl  0xc(%ebp)
f0104519:	e8 a6 ea ff ff       	call   f0102fc4 <envid2env>
f010451e:	89 c2                	mov    %eax,%edx
	if (errcode < 0) 
f0104520:	83 c4 10             	add    $0x10,%esp
f0104523:	85 d2                	test   %edx,%edx
f0104525:	0f 88 f5 02 00 00    	js     f0104820 <syscall+0x55e>
		return errcode;
	
	//Check for valid des env id
	errcode = envid2env(dstenvid, &dst_env, 1);
f010452b:	83 ec 04             	sub    $0x4,%esp
f010452e:	6a 01                	push   $0x1
f0104530:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104533:	50                   	push   %eax
f0104534:	ff 75 14             	pushl  0x14(%ebp)
f0104537:	e8 88 ea ff ff       	call   f0102fc4 <envid2env>
	if (errcode < 0) 
f010453c:	83 c4 10             	add    $0x10,%esp
f010453f:	85 c0                	test   %eax,%eax
f0104541:	0f 88 d9 02 00 00    	js     f0104820 <syscall+0x55e>
		return errcode;
	
	//Check if the address is below UTOP
	if (((uint32_t)srcva) >= UTOP || ((uint32_t)dstva) >= UTOP) 
f0104547:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f010454e:	77 6d                	ja     f01045bd <syscall+0x2fb>
f0104550:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f0104557:	77 64                	ja     f01045bd <syscall+0x2fb>
f0104559:	8b 45 10             	mov    0x10(%ebp),%eax
f010455c:	0b 45 18             	or     0x18(%ebp),%eax
		return -E_INVAL;
	
	//Checking if the address is page aligned
	if ((((uint32_t)srcva)%PGSIZE != 0) || (((uint32_t)dstva)%PGSIZE != 0)) 
f010455f:	a9 ff 0f 00 00       	test   $0xfff,%eax
f0104564:	75 61                	jne    f01045c7 <syscall+0x305>
		return -E_INVAL;

	// find the page corresponding to srcva in src_e
	pte_t* pte_src;

	struct PageInfo* srcPage = page_lookup(src_env->env_pgdir, srcva, &pte_src);
f0104566:	83 ec 04             	sub    $0x4,%esp
f0104569:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010456c:	50                   	push   %eax
f010456d:	ff 75 10             	pushl  0x10(%ebp)
f0104570:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104573:	ff 70 60             	pushl  0x60(%eax)
f0104576:	e8 7e cc ff ff       	call   f01011f9 <page_lookup>
	if (!srcPage) 
f010457b:	83 c4 10             	add    $0x10,%esp
f010457e:	85 c0                	test   %eax,%eax
f0104580:	74 4f                	je     f01045d1 <syscall+0x30f>
		return -E_INVAL;
	

	//Check for permissions
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
f0104582:	f7 45 1c fd f1 ff ff 	testl  $0xfffff1fd,0x1c(%ebp)
f0104589:	74 50                	je     f01045db <syscall+0x319>
		return -E_INVAL; 	
	

	// the page is not writable but write permission is set	
	if (!(*pte_src & PTE_W) && (perm & PTE_W)) {
f010458b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010458e:	f6 02 02             	testb  $0x2,(%edx)
f0104591:	75 06                	jne    f0104599 <syscall+0x2d7>
f0104593:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f0104597:	75 4c                	jne    f01045e5 <syscall+0x323>
		return -E_INVAL;
	}

	// mapping
	errcode = page_insert(dst_env->env_pgdir, srcPage, dstva, perm);
f0104599:	ff 75 1c             	pushl  0x1c(%ebp)
f010459c:	ff 75 18             	pushl  0x18(%ebp)
f010459f:	50                   	push   %eax
f01045a0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01045a3:	ff 70 60             	pushl  0x60(%eax)
f01045a6:	e8 14 cd ff ff       	call   f01012bf <page_insert>
f01045ab:	83 c4 10             	add    $0x10,%esp
f01045ae:	85 c0                	test   %eax,%eax
f01045b0:	ba 00 00 00 00       	mov    $0x0,%edx
f01045b5:	0f 4f c2             	cmovg  %edx,%eax
f01045b8:	e9 63 02 00 00       	jmp    f0104820 <syscall+0x55e>
	if (errcode < 0) 
		return errcode;
	
	//Check if the address is below UTOP
	if (((uint32_t)srcva) >= UTOP || ((uint32_t)dstva) >= UTOP) 
		return -E_INVAL;
f01045bd:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01045c2:	e9 59 02 00 00       	jmp    f0104820 <syscall+0x55e>
	
	//Checking if the address is page aligned
	if ((((uint32_t)srcva)%PGSIZE != 0) || (((uint32_t)dstva)%PGSIZE != 0)) 
		return -E_INVAL;
f01045c7:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01045cc:	e9 4f 02 00 00       	jmp    f0104820 <syscall+0x55e>
	// find the page corresponding to srcva in src_e
	pte_t* pte_src;

	struct PageInfo* srcPage = page_lookup(src_env->env_pgdir, srcva, &pte_src);
	if (!srcPage) 
		return -E_INVAL;
f01045d1:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01045d6:	e9 45 02 00 00       	jmp    f0104820 <syscall+0x55e>
	

	//Check for permissions
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
		return -E_INVAL; 	
f01045db:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01045e0:	e9 3b 02 00 00       	jmp    f0104820 <syscall+0x55e>
	

	// the page is not writable but write permission is set	
	if (!(*pte_src & PTE_W) && (perm & PTE_W)) {
		return -E_INVAL;
f01045e5:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	case SYS_page_alloc:
		return sys_page_alloc( (envid_t)a1, (void *)a2, (int)a3);
	
	case SYS_page_map:
		return sys_page_map( (envid_t)a1, (void *)a2,
f01045ea:	e9 31 02 00 00       	jmp    f0104820 <syscall+0x55e>
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	struct Env* en;
	//Check for valid envid
	int errcode = envid2env(envid, &en, 1);
f01045ef:	83 ec 04             	sub    $0x4,%esp
f01045f2:	6a 01                	push   $0x1
f01045f4:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01045f7:	50                   	push   %eax
f01045f8:	ff 75 0c             	pushl  0xc(%ebp)
f01045fb:	e8 c4 e9 ff ff       	call   f0102fc4 <envid2env>
	if (errcode < 0){ 
f0104600:	83 c4 10             	add    $0x10,%esp
f0104603:	85 c0                	test   %eax,%eax
f0104605:	0f 88 15 02 00 00    	js     f0104820 <syscall+0x55e>
		return errcode;
	}
	
	//Checkfor valid address and page alignment
	if ((((uint32_t)va) >= UTOP) ||(((uint32_t)va)%PGSIZE != 0 ) ) {
f010460b:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104612:	77 27                	ja     f010463b <syscall+0x379>
f0104614:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f010461b:	75 28                	jne    f0104645 <syscall+0x383>
		return -E_INVAL;
	}

	page_remove(en->env_pgdir, va);
f010461d:	83 ec 08             	sub    $0x8,%esp
f0104620:	ff 75 10             	pushl  0x10(%ebp)
f0104623:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104626:	ff 70 60             	pushl  0x60(%eax)
f0104629:	e8 4b cc ff ff       	call   f0101279 <page_remove>
f010462e:	83 c4 10             	add    $0x10,%esp

	return 0;
f0104631:	b8 00 00 00 00       	mov    $0x0,%eax
f0104636:	e9 e5 01 00 00       	jmp    f0104820 <syscall+0x55e>
		return errcode;
	}
	
	//Checkfor valid address and page alignment
	if ((((uint32_t)va) >= UTOP) ||(((uint32_t)va)%PGSIZE != 0 ) ) {
		return -E_INVAL;
f010463b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104640:	e9 db 01 00 00       	jmp    f0104820 <syscall+0x55e>
f0104645:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	case SYS_page_map:
		return sys_page_map( (envid_t)a1, (void *)a2,
	     (envid_t) a3, (void *)a4, (int )a5);

	case SYS_page_unmap:
		return sys_page_unmap((envid_t)a1, (void *)a2);	
f010464a:	e9 d1 01 00 00       	jmp    f0104820 <syscall+0x55e>
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here. //Exercise 8 code
	struct Env* en;
	int errcode = envid2env(envid, &en, 1);
f010464f:	83 ec 04             	sub    $0x4,%esp
f0104652:	6a 01                	push   $0x1
f0104654:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104657:	50                   	push   %eax
f0104658:	ff 75 0c             	pushl  0xc(%ebp)
f010465b:	e8 64 e9 ff ff       	call   f0102fc4 <envid2env>
	if (errcode < 0) {
f0104660:	83 c4 10             	add    $0x10,%esp
f0104663:	85 c0                	test   %eax,%eax
f0104665:	0f 88 b5 01 00 00    	js     f0104820 <syscall+0x55e>
		return errcode;
	}

	//Set the pgfault_upcall to func
	en->env_pgfault_upcall = func;
f010466b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010466e:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104671:	89 78 64             	mov    %edi,0x64(%eax)
	return 0;
f0104674:	b8 00 00 00 00       	mov    $0x0,%eax
f0104679:	e9 a2 01 00 00       	jmp    f0104820 <syscall+0x55e>
	// LAB 4: Your code here.
	int r; 
	struct Env* target_env; 
	
	//Bad Environment
	if ((r = envid2env(envid, &target_env, 0)) < 0)
f010467e:	83 ec 04             	sub    $0x4,%esp
f0104681:	6a 00                	push   $0x0
f0104683:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104686:	50                   	push   %eax
f0104687:	ff 75 0c             	pushl  0xc(%ebp)
f010468a:	e8 35 e9 ff ff       	call   f0102fc4 <envid2env>
f010468f:	83 c4 10             	add    $0x10,%esp
f0104692:	85 c0                	test   %eax,%eax
f0104694:	0f 88 0a 01 00 00    	js     f01047a4 <syscall+0x4e2>
		return -E_BAD_ENV; 
	
	//If target is not receiving
	if(!target_env->env_ipc_recving)
f010469a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010469d:	80 78 68 00          	cmpb   $0x0,0x68(%eax)
f01046a1:	0f 84 04 01 00 00    	je     f01047ab <syscall+0x4e9>
		return -E_IPC_NOT_RECV;
	
	//If src and dst addesses are below UTOP
	if (((uint32_t)srcva) < UTOP && (uint32_t)target_env->env_ipc_dstva < UTOP)
f01046a7:	81 7d 14 ff ff bf ee 	cmpl   $0xeebfffff,0x14(%ebp)
f01046ae:	0f 87 b0 00 00 00    	ja     f0104764 <syscall+0x4a2>
f01046b4:	81 78 6c ff ff bf ee 	cmpl   $0xeebfffff,0x6c(%eax)
f01046bb:	0f 87 a3 00 00 00    	ja     f0104764 <syscall+0x4a2>
	{
		
		//Check if srcva is page aligned
		if ((uint32_t)srcva % PGSIZE !=0)
			return -E_INVAL;
f01046c1:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	//If src and dst addesses are below UTOP
	if (((uint32_t)srcva) < UTOP && (uint32_t)target_env->env_ipc_dstva < UTOP)
	{
		
		//Check if srcva is page aligned
		if ((uint32_t)srcva % PGSIZE !=0)
f01046c6:	f7 45 14 ff 0f 00 00 	testl  $0xfff,0x14(%ebp)
f01046cd:	0f 85 4d 01 00 00    	jne    f0104820 <syscall+0x55e>
			return -E_INVAL;
	
		//Check for permissions
		if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
f01046d3:	f7 45 18 fd f1 ff ff 	testl  $0xfffff1fd,0x18(%ebp)
f01046da:	0f 84 40 01 00 00    	je     f0104820 <syscall+0x55e>
			return -E_INVAL;

		struct PageInfo* srcpage = NULL;

		pte_t* pte = NULL;
f01046e0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		//Lookup the page and get a pte
		if (!(srcpage = page_lookup(curenv->env_pgdir, srcva,&pte)))
f01046e7:	e8 df 12 00 00       	call   f01059cb <cpunum>
f01046ec:	83 ec 04             	sub    $0x4,%esp
f01046ef:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01046f2:	52                   	push   %edx
f01046f3:	ff 75 14             	pushl  0x14(%ebp)
f01046f6:	6b c0 74             	imul   $0x74,%eax,%eax
f01046f9:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f01046ff:	ff 70 60             	pushl  0x60(%eax)
f0104702:	e8 f2 ca ff ff       	call   f01011f9 <page_lookup>
f0104707:	89 c2                	mov    %eax,%edx
f0104709:	83 c4 10             	add    $0x10,%esp
f010470c:	85 c0                	test   %eax,%eax
f010470e:	74 40                	je     f0104750 <syscall+0x48e>
			return -E_INVAL;
		
		//if (perm & PTE_W), but srcva is read-only in the
		//current environment's address space.
		if ((perm & PTE_W) && !(*pte & PTE_W))
f0104710:	f6 45 18 02          	testb  $0x2,0x18(%ebp)
f0104714:	74 11                	je     f0104727 <syscall+0x465>
			return -E_INVAL; 
f0104716:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		if (!(srcpage = page_lookup(curenv->env_pgdir, srcva,&pte)))
			return -E_INVAL;
		
		//if (perm & PTE_W), but srcva is read-only in the
		//current environment's address space.
		if ((perm & PTE_W) && !(*pte & PTE_W))
f010471b:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010471e:	f6 01 02             	testb  $0x2,(%ecx)
f0104721:	0f 84 f9 00 00 00    	je     f0104820 <syscall+0x55e>
			return -E_INVAL; 
		
		//Page mappingto destination
		if (target_env->env_ipc_dstva)
f0104727:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010472a:	8b 48 6c             	mov    0x6c(%eax),%ecx
f010472d:	85 c9                	test   %ecx,%ecx
f010472f:	74 14                	je     f0104745 <syscall+0x483>
		{
			//map the page
			if ((r = page_insert(target_env->env_pgdir, srcpage, (void *)target_env->env_ipc_dstva,perm) )< 0)
f0104731:	ff 75 18             	pushl  0x18(%ebp)
f0104734:	51                   	push   %ecx
f0104735:	52                   	push   %edx
f0104736:	ff 70 60             	pushl  0x60(%eax)
f0104739:	e8 81 cb ff ff       	call   f01012bf <page_insert>
f010473e:	83 c4 10             	add    $0x10,%esp
f0104741:	85 c0                	test   %eax,%eax
f0104743:	78 15                	js     f010475a <syscall+0x498>
				return -E_NO_MEM;
			
		}
		
		target_env->env_ipc_perm = perm; // is set to 'perm' if a page was transferred, 0 otherwise. 
f0104745:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104748:	8b 75 18             	mov    0x18(%ebp),%esi
f010474b:	89 70 78             	mov    %esi,0x78(%eax)
f010474e:	eb 1b                	jmp    f010476b <syscall+0x4a9>
		struct PageInfo* srcpage = NULL;

		pte_t* pte = NULL;
		//Lookup the page and get a pte
		if (!(srcpage = page_lookup(curenv->env_pgdir, srcva,&pte)))
			return -E_INVAL;
f0104750:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104755:	e9 c6 00 00 00       	jmp    f0104820 <syscall+0x55e>
		//Page mappingto destination
		if (target_env->env_ipc_dstva)
		{
			//map the page
			if ((r = page_insert(target_env->env_pgdir, srcpage, (void *)target_env->env_ipc_dstva,perm) )< 0)
				return -E_NO_MEM;
f010475a:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f010475f:	e9 bc 00 00 00       	jmp    f0104820 <syscall+0x55e>
		}
		
		target_env->env_ipc_perm = perm; // is set to 'perm' if a page was transferred, 0 otherwise. 
	}
	else{
		target_env->env_ipc_perm = 0; //  0 otherwise. 
f0104764:	c7 40 78 00 00 00 00 	movl   $0x0,0x78(%eax)
	}
	
	target_env->env_ipc_recving  = 0; //is set to 0 to block future sends
f010476b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010476e:	c6 43 68 00          	movb   $0x0,0x68(%ebx)
	target_env->env_ipc_from = curenv->env_id; // is set to the sending envid;
f0104772:	e8 54 12 00 00       	call   f01059cb <cpunum>
f0104777:	6b c0 74             	imul   $0x74,%eax,%eax
f010477a:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0104780:	8b 40 48             	mov    0x48(%eax),%eax
f0104783:	89 43 74             	mov    %eax,0x74(%ebx)
	target_env->env_tf.tf_regs.reg_eax = 0;
f0104786:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104789:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	target_env->env_ipc_value = value; // is set to the 'value' parameter;
f0104790:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104793:	89 48 70             	mov    %ecx,0x70(%eax)
	target_env->env_status = ENV_RUNNABLE; 
f0104796:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	
	return 0;
f010479d:	b8 00 00 00 00       	mov    $0x0,%eax
f01047a2:	eb 7c                	jmp    f0104820 <syscall+0x55e>
	int r; 
	struct Env* target_env; 
	
	//Bad Environment
	if ((r = envid2env(envid, &target_env, 0)) < 0)
		return -E_BAD_ENV; 
f01047a4:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01047a9:	eb 75                	jmp    f0104820 <syscall+0x55e>
	
	//If target is not receiving
	if(!target_env->env_ipc_recving)
		return -E_IPC_NOT_RECV;
f01047ab:	b8 f8 ff ff ff       	mov    $0xfffffff8,%eax

	case SYS_env_set_pgfault_upcall:
		return sys_env_set_pgfault_upcall((envid_t) a1, (void *)a2);

	case SYS_ipc_try_send:
		return sys_ipc_try_send(a1,a2,(void*)a3, a4);
f01047b0:	eb 6e                	jmp    f0104820 <syscall+0x55e>
	//panic("sys_ipc_recv not implemented");

	//check if dstva is below UTOP
	
	
	if ((uint32_t)dstva < UTOP)
f01047b2:	81 7d 0c ff ff bf ee 	cmpl   $0xeebfffff,0xc(%ebp)
f01047b9:	77 1d                	ja     f01047d8 <syscall+0x516>
	{
		if ((uint32_t)dstva % PGSIZE !=0)
f01047bb:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
f01047c2:	75 57                	jne    f010481b <syscall+0x559>
			return -E_INVAL;
		curenv->env_ipc_dstva = dstva;
f01047c4:	e8 02 12 00 00       	call   f01059cb <cpunum>
f01047c9:	6b c0 74             	imul   $0x74,%eax,%eax
f01047cc:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f01047d2:	8b 75 0c             	mov    0xc(%ebp),%esi
f01047d5:	89 70 6c             	mov    %esi,0x6c(%eax)
	}
	
	//Enable receiving
	curenv->env_ipc_recving = 1;
f01047d8:	e8 ee 11 00 00       	call   f01059cb <cpunum>
f01047dd:	6b c0 74             	imul   $0x74,%eax,%eax
f01047e0:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f01047e6:	c6 40 68 01          	movb   $0x1,0x68(%eax)
	curenv->env_status = ENV_NOT_RUNNABLE;
f01047ea:	e8 dc 11 00 00       	call   f01059cb <cpunum>
f01047ef:	6b c0 74             	imul   $0x74,%eax,%eax
f01047f2:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f01047f8:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	sched_yield();
f01047ff:	e8 de f9 ff ff       	call   f01041e2 <sched_yield>

	case SYS_ipc_recv:
		return sys_ipc_recv((void*)a1);
		
	default:
		panic("Invalid System Call \n");
f0104804:	83 ec 04             	sub    $0x4,%esp
f0104807:	68 fe 78 10 f0       	push   $0xf01078fe
f010480c:	68 15 02 00 00       	push   $0x215
f0104811:	68 14 79 10 f0       	push   $0xf0107914
f0104816:	e8 25 b8 ff ff       	call   f0100040 <_panic>

	case SYS_ipc_try_send:
		return sys_ipc_try_send(a1,a2,(void*)a3, a4);

	case SYS_ipc_recv:
		return sys_ipc_recv((void*)a1);
f010481b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		
	default:
		panic("Invalid System Call \n");
		return -E_INVAL;
	}
}
f0104820:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104823:	5b                   	pop    %ebx
f0104824:	5e                   	pop    %esi
f0104825:	5f                   	pop    %edi
f0104826:	5d                   	pop    %ebp
f0104827:	c3                   	ret    

f0104828 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104828:	55                   	push   %ebp
f0104829:	89 e5                	mov    %esp,%ebp
f010482b:	57                   	push   %edi
f010482c:	56                   	push   %esi
f010482d:	53                   	push   %ebx
f010482e:	83 ec 14             	sub    $0x14,%esp
f0104831:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104834:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104837:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010483a:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010483d:	8b 1a                	mov    (%edx),%ebx
f010483f:	8b 01                	mov    (%ecx),%eax
f0104841:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104844:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010484b:	e9 88 00 00 00       	jmp    f01048d8 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0104850:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104853:	01 d8                	add    %ebx,%eax
f0104855:	89 c6                	mov    %eax,%esi
f0104857:	c1 ee 1f             	shr    $0x1f,%esi
f010485a:	01 c6                	add    %eax,%esi
f010485c:	d1 fe                	sar    %esi
f010485e:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0104861:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104864:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0104867:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104869:	eb 03                	jmp    f010486e <stab_binsearch+0x46>
			m--;
f010486b:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010486e:	39 c3                	cmp    %eax,%ebx
f0104870:	7f 1f                	jg     f0104891 <stab_binsearch+0x69>
f0104872:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104876:	83 ea 0c             	sub    $0xc,%edx
f0104879:	39 f9                	cmp    %edi,%ecx
f010487b:	75 ee                	jne    f010486b <stab_binsearch+0x43>
f010487d:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104880:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104883:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104886:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010488a:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010488d:	76 18                	jbe    f01048a7 <stab_binsearch+0x7f>
f010488f:	eb 05                	jmp    f0104896 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104891:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0104894:	eb 42                	jmp    f01048d8 <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0104896:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104899:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010489b:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010489e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01048a5:	eb 31                	jmp    f01048d8 <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01048a7:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01048aa:	73 17                	jae    f01048c3 <stab_binsearch+0x9b>
			*region_right = m - 1;
f01048ac:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01048af:	83 e8 01             	sub    $0x1,%eax
f01048b2:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01048b5:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01048b8:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01048ba:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01048c1:	eb 15                	jmp    f01048d8 <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01048c3:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01048c6:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f01048c9:	89 1e                	mov    %ebx,(%esi)
			l = m;
			addr++;
f01048cb:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01048cf:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01048d1:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01048d8:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01048db:	0f 8e 6f ff ff ff    	jle    f0104850 <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01048e1:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01048e5:	75 0f                	jne    f01048f6 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f01048e7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01048ea:	8b 00                	mov    (%eax),%eax
f01048ec:	83 e8 01             	sub    $0x1,%eax
f01048ef:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01048f2:	89 06                	mov    %eax,(%esi)
f01048f4:	eb 2c                	jmp    f0104922 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01048f6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01048f9:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01048fb:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01048fe:	8b 0e                	mov    (%esi),%ecx
f0104900:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104903:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0104906:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104909:	eb 03                	jmp    f010490e <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010490b:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010490e:	39 c8                	cmp    %ecx,%eax
f0104910:	7e 0b                	jle    f010491d <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0104912:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104916:	83 ea 0c             	sub    $0xc,%edx
f0104919:	39 fb                	cmp    %edi,%ebx
f010491b:	75 ee                	jne    f010490b <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f010491d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104920:	89 06                	mov    %eax,(%esi)
	}
}
f0104922:	83 c4 14             	add    $0x14,%esp
f0104925:	5b                   	pop    %ebx
f0104926:	5e                   	pop    %esi
f0104927:	5f                   	pop    %edi
f0104928:	5d                   	pop    %ebp
f0104929:	c3                   	ret    

f010492a <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010492a:	55                   	push   %ebp
f010492b:	89 e5                	mov    %esp,%ebp
f010492d:	57                   	push   %edi
f010492e:	56                   	push   %esi
f010492f:	53                   	push   %ebx
f0104930:	83 ec 3c             	sub    $0x3c,%esp
f0104933:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104936:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104939:	c7 06 58 79 10 f0    	movl   $0xf0107958,(%esi)
	info->eip_line = 0;
f010493f:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0104946:	c7 46 08 58 79 10 f0 	movl   $0xf0107958,0x8(%esi)
	info->eip_fn_namelen = 9;
f010494d:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0104954:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0104957:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010495e:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0104964:	0f 87 a4 00 00 00    	ja     f0104a0e <debuginfo_eip+0xe4>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
f010496a:	e8 5c 10 00 00       	call   f01059cb <cpunum>
f010496f:	6a 05                	push   $0x5
f0104971:	6a 10                	push   $0x10
f0104973:	68 00 00 20 00       	push   $0x200000
f0104978:	6b c0 74             	imul   $0x74,%eax,%eax
f010497b:	ff b0 48 10 23 f0    	pushl  -0xfdcefb8(%eax)
f0104981:	e8 7a e4 ff ff       	call   f0102e00 <user_mem_check>
f0104986:	83 c4 10             	add    $0x10,%esp
f0104989:	85 c0                	test   %eax,%eax
f010498b:	0f 88 24 02 00 00    	js     f0104bb5 <debuginfo_eip+0x28b>
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
		}
		stabs = usd->stabs;
f0104991:	a1 00 00 20 00       	mov    0x200000,%eax
		stab_end = usd->stab_end;
f0104996:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f010499c:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f01049a2:	89 4d c0             	mov    %ecx,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f01049a5:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f01049ab:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
f01049ae:	89 d9                	mov    %ebx,%ecx
f01049b0:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01049b3:	29 c1                	sub    %eax,%ecx
f01049b5:	89 4d b8             	mov    %ecx,-0x48(%ebp)
f01049b8:	e8 0e 10 00 00       	call   f01059cb <cpunum>
f01049bd:	6a 05                	push   $0x5
f01049bf:	ff 75 b8             	pushl  -0x48(%ebp)
f01049c2:	ff 75 c4             	pushl  -0x3c(%ebp)
f01049c5:	6b c0 74             	imul   $0x74,%eax,%eax
f01049c8:	ff b0 48 10 23 f0    	pushl  -0xfdcefb8(%eax)
f01049ce:	e8 2d e4 ff ff       	call   f0102e00 <user_mem_check>
f01049d3:	83 c4 10             	add    $0x10,%esp
f01049d6:	85 c0                	test   %eax,%eax
f01049d8:	0f 88 de 01 00 00    	js     f0104bbc <debuginfo_eip+0x292>
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
		}

		if (user_mem_check(curenv, (const void *)stabstr,
f01049de:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01049e1:	2b 55 c0             	sub    -0x40(%ebp),%edx
f01049e4:	89 55 b8             	mov    %edx,-0x48(%ebp)
f01049e7:	e8 df 0f 00 00       	call   f01059cb <cpunum>
f01049ec:	6a 05                	push   $0x5
f01049ee:	ff 75 b8             	pushl  -0x48(%ebp)
f01049f1:	ff 75 c0             	pushl  -0x40(%ebp)
f01049f4:	6b c0 74             	imul   $0x74,%eax,%eax
f01049f7:	ff b0 48 10 23 f0    	pushl  -0xfdcefb8(%eax)
f01049fd:	e8 fe e3 ff ff       	call   f0102e00 <user_mem_check>
f0104a02:	83 c4 10             	add    $0x10,%esp
f0104a05:	85 c0                	test   %eax,%eax
f0104a07:	79 1f                	jns    f0104a28 <debuginfo_eip+0xfe>
f0104a09:	e9 b5 01 00 00       	jmp    f0104bc3 <debuginfo_eip+0x299>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104a0e:	c7 45 bc 63 5d 11 f0 	movl   $0xf0115d63,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104a15:	c7 45 c0 69 26 11 f0 	movl   $0xf0112669,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104a1c:	bb 68 26 11 f0       	mov    $0xf0112668,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104a21:	c7 45 c4 38 7e 10 f0 	movl   $0xf0107e38,-0x3c(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104a28:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104a2b:	39 45 c0             	cmp    %eax,-0x40(%ebp)
f0104a2e:	0f 83 96 01 00 00    	jae    f0104bca <debuginfo_eip+0x2a0>
f0104a34:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0104a38:	0f 85 93 01 00 00    	jne    f0104bd1 <debuginfo_eip+0x2a7>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104a3e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104a45:	89 d8                	mov    %ebx,%eax
f0104a47:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0104a4a:	29 d8                	sub    %ebx,%eax
f0104a4c:	c1 f8 02             	sar    $0x2,%eax
f0104a4f:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0104a55:	83 e8 01             	sub    $0x1,%eax
f0104a58:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104a5b:	83 ec 08             	sub    $0x8,%esp
f0104a5e:	57                   	push   %edi
f0104a5f:	6a 64                	push   $0x64
f0104a61:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0104a64:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104a67:	89 d8                	mov    %ebx,%eax
f0104a69:	e8 ba fd ff ff       	call   f0104828 <stab_binsearch>
	if (lfile == 0)
f0104a6e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104a71:	83 c4 10             	add    $0x10,%esp
f0104a74:	85 c0                	test   %eax,%eax
f0104a76:	0f 84 5c 01 00 00    	je     f0104bd8 <debuginfo_eip+0x2ae>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104a7c:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104a7f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104a82:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104a85:	83 ec 08             	sub    $0x8,%esp
f0104a88:	57                   	push   %edi
f0104a89:	6a 24                	push   $0x24
f0104a8b:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0104a8e:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104a91:	89 d8                	mov    %ebx,%eax
f0104a93:	e8 90 fd ff ff       	call   f0104828 <stab_binsearch>

	if (lfun <= rfun) {
f0104a98:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104a9b:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0104a9e:	83 c4 10             	add    $0x10,%esp
f0104aa1:	39 d8                	cmp    %ebx,%eax
f0104aa3:	7f 32                	jg     f0104ad7 <debuginfo_eip+0x1ad>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104aa5:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104aa8:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0104aab:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f0104aae:	8b 11                	mov    (%ecx),%edx
f0104ab0:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0104ab3:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104ab6:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0104ab9:	39 55 b8             	cmp    %edx,-0x48(%ebp)
f0104abc:	73 09                	jae    f0104ac7 <debuginfo_eip+0x19d>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104abe:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0104ac1:	03 55 c0             	add    -0x40(%ebp),%edx
f0104ac4:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104ac7:	8b 51 08             	mov    0x8(%ecx),%edx
f0104aca:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0104acd:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0104acf:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104ad2:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0104ad5:	eb 0f                	jmp    f0104ae6 <debuginfo_eip+0x1bc>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104ad7:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0104ada:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104add:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104ae0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104ae3:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104ae6:	83 ec 08             	sub    $0x8,%esp
f0104ae9:	6a 3a                	push   $0x3a
f0104aeb:	ff 76 08             	pushl  0x8(%esi)
f0104aee:	e8 99 08 00 00       	call   f010538c <strfind>
f0104af3:	2b 46 08             	sub    0x8(%esi),%eax
f0104af6:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
f0104af9:	83 c4 08             	add    $0x8,%esp
f0104afc:	57                   	push   %edi
f0104afd:	6a 44                	push   $0x44
f0104aff:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104b02:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0104b05:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0104b08:	89 d8                	mov    %ebx,%eax
f0104b0a:	e8 19 fd ff ff       	call   f0104828 <stab_binsearch>
	if (lline > rline) {
f0104b0f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104b12:	83 c4 10             	add    $0x10,%esp
f0104b15:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0104b18:	0f 8f c1 00 00 00    	jg     f0104bdf <debuginfo_eip+0x2b5>
		return -1; //Did not find the line number in the stab
	}
	info->eip_line = stabs[lline].n_desc; //If found update the info object with the correct line number
f0104b1e:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104b21:	0f b7 44 83 06       	movzwl 0x6(%ebx,%eax,4),%eax
f0104b26:	89 46 04             	mov    %eax,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104b29:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104b2c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104b2f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104b32:	8d 14 93             	lea    (%ebx,%edx,4),%edx
f0104b35:	89 75 0c             	mov    %esi,0xc(%ebp)
f0104b38:	eb 06                	jmp    f0104b40 <debuginfo_eip+0x216>
f0104b3a:	83 e8 01             	sub    $0x1,%eax
f0104b3d:	83 ea 0c             	sub    $0xc,%edx
f0104b40:	39 c7                	cmp    %eax,%edi
f0104b42:	7f 2a                	jg     f0104b6e <debuginfo_eip+0x244>
	       && stabs[lline].n_type != N_SOL
f0104b44:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104b48:	80 f9 84             	cmp    $0x84,%cl
f0104b4b:	0f 84 9c 00 00 00    	je     f0104bed <debuginfo_eip+0x2c3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104b51:	80 f9 64             	cmp    $0x64,%cl
f0104b54:	75 e4                	jne    f0104b3a <debuginfo_eip+0x210>
f0104b56:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0104b5a:	74 de                	je     f0104b3a <debuginfo_eip+0x210>
f0104b5c:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104b5f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104b62:	e9 8c 00 00 00       	jmp    f0104bf3 <debuginfo_eip+0x2c9>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104b67:	03 55 c0             	add    -0x40(%ebp),%edx
f0104b6a:	89 16                	mov    %edx,(%esi)
f0104b6c:	eb 03                	jmp    f0104b71 <debuginfo_eip+0x247>
f0104b6e:	8b 75 0c             	mov    0xc(%ebp),%esi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104b71:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104b74:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104b77:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104b7c:	39 da                	cmp    %ebx,%edx
f0104b7e:	0f 8d 8b 00 00 00    	jge    f0104c0f <debuginfo_eip+0x2e5>
		for (lline = lfun + 1;
f0104b84:	83 c2 01             	add    $0x1,%edx
f0104b87:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104b8a:	89 d0                	mov    %edx,%eax
f0104b8c:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104b8f:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0104b92:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0104b95:	eb 04                	jmp    f0104b9b <debuginfo_eip+0x271>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104b97:	83 46 14 01          	addl   $0x1,0x14(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104b9b:	39 c3                	cmp    %eax,%ebx
f0104b9d:	7e 47                	jle    f0104be6 <debuginfo_eip+0x2bc>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104b9f:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104ba3:	83 c0 01             	add    $0x1,%eax
f0104ba6:	83 c2 0c             	add    $0xc,%edx
f0104ba9:	80 f9 a0             	cmp    $0xa0,%cl
f0104bac:	74 e9                	je     f0104b97 <debuginfo_eip+0x26d>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104bae:	b8 00 00 00 00       	mov    $0x0,%eax
f0104bb3:	eb 5a                	jmp    f0104c0f <debuginfo_eip+0x2e5>
		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
f0104bb5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104bba:	eb 53                	jmp    f0104c0f <debuginfo_eip+0x2e5>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
f0104bbc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104bc1:	eb 4c                	jmp    f0104c0f <debuginfo_eip+0x2e5>
		}

		if (user_mem_check(curenv, (const void *)stabstr,
				(uintptr_t)stabstr_end - (uintptr_t)stabstr, PTE_U | PTE_P) < 0) {
			return -1;
f0104bc3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104bc8:	eb 45                	jmp    f0104c0f <debuginfo_eip+0x2e5>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104bca:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104bcf:	eb 3e                	jmp    f0104c0f <debuginfo_eip+0x2e5>
f0104bd1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104bd6:	eb 37                	jmp    f0104c0f <debuginfo_eip+0x2e5>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104bd8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104bdd:	eb 30                	jmp    f0104c0f <debuginfo_eip+0x2e5>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
	if (lline > rline) {
		return -1; //Did not find the line number in the stab
f0104bdf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104be4:	eb 29                	jmp    f0104c0f <debuginfo_eip+0x2e5>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104be6:	b8 00 00 00 00       	mov    $0x0,%eax
f0104beb:	eb 22                	jmp    f0104c0f <debuginfo_eip+0x2e5>
f0104bed:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104bf0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104bf3:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104bf6:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0104bf9:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0104bfc:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104bff:	2b 45 c0             	sub    -0x40(%ebp),%eax
f0104c02:	39 c2                	cmp    %eax,%edx
f0104c04:	0f 82 5d ff ff ff    	jb     f0104b67 <debuginfo_eip+0x23d>
f0104c0a:	e9 62 ff ff ff       	jmp    f0104b71 <debuginfo_eip+0x247>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
}
f0104c0f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104c12:	5b                   	pop    %ebx
f0104c13:	5e                   	pop    %esi
f0104c14:	5f                   	pop    %edi
f0104c15:	5d                   	pop    %ebp
f0104c16:	c3                   	ret    

f0104c17 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104c17:	55                   	push   %ebp
f0104c18:	89 e5                	mov    %esp,%ebp
f0104c1a:	57                   	push   %edi
f0104c1b:	56                   	push   %esi
f0104c1c:	53                   	push   %ebx
f0104c1d:	83 ec 1c             	sub    $0x1c,%esp
f0104c20:	89 c7                	mov    %eax,%edi
f0104c22:	89 d6                	mov    %edx,%esi
f0104c24:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c27:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104c2a:	89 d1                	mov    %edx,%ecx
f0104c2c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104c2f:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104c32:	8b 45 10             	mov    0x10(%ebp),%eax
f0104c35:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104c38:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104c3b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0104c42:	39 4d e4             	cmp    %ecx,-0x1c(%ebp)
f0104c45:	72 05                	jb     f0104c4c <printnum+0x35>
f0104c47:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0104c4a:	77 3e                	ja     f0104c8a <printnum+0x73>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104c4c:	83 ec 0c             	sub    $0xc,%esp
f0104c4f:	ff 75 18             	pushl  0x18(%ebp)
f0104c52:	83 eb 01             	sub    $0x1,%ebx
f0104c55:	53                   	push   %ebx
f0104c56:	50                   	push   %eax
f0104c57:	83 ec 08             	sub    $0x8,%esp
f0104c5a:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104c5d:	ff 75 e0             	pushl  -0x20(%ebp)
f0104c60:	ff 75 dc             	pushl  -0x24(%ebp)
f0104c63:	ff 75 d8             	pushl  -0x28(%ebp)
f0104c66:	e8 55 11 00 00       	call   f0105dc0 <__udivdi3>
f0104c6b:	83 c4 18             	add    $0x18,%esp
f0104c6e:	52                   	push   %edx
f0104c6f:	50                   	push   %eax
f0104c70:	89 f2                	mov    %esi,%edx
f0104c72:	89 f8                	mov    %edi,%eax
f0104c74:	e8 9e ff ff ff       	call   f0104c17 <printnum>
f0104c79:	83 c4 20             	add    $0x20,%esp
f0104c7c:	eb 13                	jmp    f0104c91 <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104c7e:	83 ec 08             	sub    $0x8,%esp
f0104c81:	56                   	push   %esi
f0104c82:	ff 75 18             	pushl  0x18(%ebp)
f0104c85:	ff d7                	call   *%edi
f0104c87:	83 c4 10             	add    $0x10,%esp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104c8a:	83 eb 01             	sub    $0x1,%ebx
f0104c8d:	85 db                	test   %ebx,%ebx
f0104c8f:	7f ed                	jg     f0104c7e <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104c91:	83 ec 08             	sub    $0x8,%esp
f0104c94:	56                   	push   %esi
f0104c95:	83 ec 04             	sub    $0x4,%esp
f0104c98:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104c9b:	ff 75 e0             	pushl  -0x20(%ebp)
f0104c9e:	ff 75 dc             	pushl  -0x24(%ebp)
f0104ca1:	ff 75 d8             	pushl  -0x28(%ebp)
f0104ca4:	e8 47 12 00 00       	call   f0105ef0 <__umoddi3>
f0104ca9:	83 c4 14             	add    $0x14,%esp
f0104cac:	0f be 80 62 79 10 f0 	movsbl -0xfef869e(%eax),%eax
f0104cb3:	50                   	push   %eax
f0104cb4:	ff d7                	call   *%edi
f0104cb6:	83 c4 10             	add    $0x10,%esp
}
f0104cb9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104cbc:	5b                   	pop    %ebx
f0104cbd:	5e                   	pop    %esi
f0104cbe:	5f                   	pop    %edi
f0104cbf:	5d                   	pop    %ebp
f0104cc0:	c3                   	ret    

f0104cc1 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0104cc1:	55                   	push   %ebp
f0104cc2:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104cc4:	83 fa 01             	cmp    $0x1,%edx
f0104cc7:	7e 0e                	jle    f0104cd7 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0104cc9:	8b 10                	mov    (%eax),%edx
f0104ccb:	8d 4a 08             	lea    0x8(%edx),%ecx
f0104cce:	89 08                	mov    %ecx,(%eax)
f0104cd0:	8b 02                	mov    (%edx),%eax
f0104cd2:	8b 52 04             	mov    0x4(%edx),%edx
f0104cd5:	eb 22                	jmp    f0104cf9 <getuint+0x38>
	else if (lflag)
f0104cd7:	85 d2                	test   %edx,%edx
f0104cd9:	74 10                	je     f0104ceb <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104cdb:	8b 10                	mov    (%eax),%edx
f0104cdd:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104ce0:	89 08                	mov    %ecx,(%eax)
f0104ce2:	8b 02                	mov    (%edx),%eax
f0104ce4:	ba 00 00 00 00       	mov    $0x0,%edx
f0104ce9:	eb 0e                	jmp    f0104cf9 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104ceb:	8b 10                	mov    (%eax),%edx
f0104ced:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104cf0:	89 08                	mov    %ecx,(%eax)
f0104cf2:	8b 02                	mov    (%edx),%eax
f0104cf4:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104cf9:	5d                   	pop    %ebp
f0104cfa:	c3                   	ret    

f0104cfb <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104cfb:	55                   	push   %ebp
f0104cfc:	89 e5                	mov    %esp,%ebp
f0104cfe:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104d01:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104d05:	8b 10                	mov    (%eax),%edx
f0104d07:	3b 50 04             	cmp    0x4(%eax),%edx
f0104d0a:	73 0a                	jae    f0104d16 <sprintputch+0x1b>
		*b->buf++ = ch;
f0104d0c:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104d0f:	89 08                	mov    %ecx,(%eax)
f0104d11:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d14:	88 02                	mov    %al,(%edx)
}
f0104d16:	5d                   	pop    %ebp
f0104d17:	c3                   	ret    

f0104d18 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104d18:	55                   	push   %ebp
f0104d19:	89 e5                	mov    %esp,%ebp
f0104d1b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0104d1e:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104d21:	50                   	push   %eax
f0104d22:	ff 75 10             	pushl  0x10(%ebp)
f0104d25:	ff 75 0c             	pushl  0xc(%ebp)
f0104d28:	ff 75 08             	pushl  0x8(%ebp)
f0104d2b:	e8 05 00 00 00       	call   f0104d35 <vprintfmt>
	va_end(ap);
f0104d30:	83 c4 10             	add    $0x10,%esp
}
f0104d33:	c9                   	leave  
f0104d34:	c3                   	ret    

f0104d35 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104d35:	55                   	push   %ebp
f0104d36:	89 e5                	mov    %esp,%ebp
f0104d38:	57                   	push   %edi
f0104d39:	56                   	push   %esi
f0104d3a:	53                   	push   %ebx
f0104d3b:	83 ec 2c             	sub    $0x2c,%esp
f0104d3e:	8b 75 08             	mov    0x8(%ebp),%esi
f0104d41:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104d44:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104d47:	eb 12                	jmp    f0104d5b <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104d49:	85 c0                	test   %eax,%eax
f0104d4b:	0f 84 90 03 00 00    	je     f01050e1 <vprintfmt+0x3ac>
				return;
			putch(ch, putdat);
f0104d51:	83 ec 08             	sub    $0x8,%esp
f0104d54:	53                   	push   %ebx
f0104d55:	50                   	push   %eax
f0104d56:	ff d6                	call   *%esi
f0104d58:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104d5b:	83 c7 01             	add    $0x1,%edi
f0104d5e:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104d62:	83 f8 25             	cmp    $0x25,%eax
f0104d65:	75 e2                	jne    f0104d49 <vprintfmt+0x14>
f0104d67:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0104d6b:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0104d72:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104d79:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0104d80:	ba 00 00 00 00       	mov    $0x0,%edx
f0104d85:	eb 07                	jmp    f0104d8e <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104d87:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104d8a:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104d8e:	8d 47 01             	lea    0x1(%edi),%eax
f0104d91:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104d94:	0f b6 07             	movzbl (%edi),%eax
f0104d97:	0f b6 c8             	movzbl %al,%ecx
f0104d9a:	83 e8 23             	sub    $0x23,%eax
f0104d9d:	3c 55                	cmp    $0x55,%al
f0104d9f:	0f 87 21 03 00 00    	ja     f01050c6 <vprintfmt+0x391>
f0104da5:	0f b6 c0             	movzbl %al,%eax
f0104da8:	ff 24 85 20 7a 10 f0 	jmp    *-0xfef85e0(,%eax,4)
f0104daf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104db2:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0104db6:	eb d6                	jmp    f0104d8e <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104db8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104dbb:	b8 00 00 00 00       	mov    $0x0,%eax
f0104dc0:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104dc3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104dc6:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0104dca:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0104dcd:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0104dd0:	83 fa 09             	cmp    $0x9,%edx
f0104dd3:	77 39                	ja     f0104e0e <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104dd5:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104dd8:	eb e9                	jmp    f0104dc3 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104dda:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ddd:	8d 48 04             	lea    0x4(%eax),%ecx
f0104de0:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104de3:	8b 00                	mov    (%eax),%eax
f0104de5:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104de8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104deb:	eb 27                	jmp    f0104e14 <vprintfmt+0xdf>
f0104ded:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104df0:	85 c0                	test   %eax,%eax
f0104df2:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104df7:	0f 49 c8             	cmovns %eax,%ecx
f0104dfa:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104dfd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104e00:	eb 8c                	jmp    f0104d8e <vprintfmt+0x59>
f0104e02:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104e05:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0104e0c:	eb 80                	jmp    f0104d8e <vprintfmt+0x59>
f0104e0e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104e11:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0104e14:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104e18:	0f 89 70 ff ff ff    	jns    f0104d8e <vprintfmt+0x59>
				width = precision, precision = -1;
f0104e1e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104e21:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104e24:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104e2b:	e9 5e ff ff ff       	jmp    f0104d8e <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104e30:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e33:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0104e36:	e9 53 ff ff ff       	jmp    f0104d8e <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104e3b:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e3e:	8d 50 04             	lea    0x4(%eax),%edx
f0104e41:	89 55 14             	mov    %edx,0x14(%ebp)
f0104e44:	83 ec 08             	sub    $0x8,%esp
f0104e47:	53                   	push   %ebx
f0104e48:	ff 30                	pushl  (%eax)
f0104e4a:	ff d6                	call   *%esi
			break;
f0104e4c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e4f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0104e52:	e9 04 ff ff ff       	jmp    f0104d5b <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104e57:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e5a:	8d 50 04             	lea    0x4(%eax),%edx
f0104e5d:	89 55 14             	mov    %edx,0x14(%ebp)
f0104e60:	8b 00                	mov    (%eax),%eax
f0104e62:	99                   	cltd   
f0104e63:	31 d0                	xor    %edx,%eax
f0104e65:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104e67:	83 f8 09             	cmp    $0x9,%eax
f0104e6a:	7f 0b                	jg     f0104e77 <vprintfmt+0x142>
f0104e6c:	8b 14 85 80 7b 10 f0 	mov    -0xfef8480(,%eax,4),%edx
f0104e73:	85 d2                	test   %edx,%edx
f0104e75:	75 18                	jne    f0104e8f <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0104e77:	50                   	push   %eax
f0104e78:	68 7a 79 10 f0       	push   $0xf010797a
f0104e7d:	53                   	push   %ebx
f0104e7e:	56                   	push   %esi
f0104e7f:	e8 94 fe ff ff       	call   f0104d18 <printfmt>
f0104e84:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e87:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0104e8a:	e9 cc fe ff ff       	jmp    f0104d5b <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0104e8f:	52                   	push   %edx
f0104e90:	68 6d 70 10 f0       	push   $0xf010706d
f0104e95:	53                   	push   %ebx
f0104e96:	56                   	push   %esi
f0104e97:	e8 7c fe ff ff       	call   f0104d18 <printfmt>
f0104e9c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e9f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104ea2:	e9 b4 fe ff ff       	jmp    f0104d5b <vprintfmt+0x26>
f0104ea7:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0104eaa:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104ead:	89 45 cc             	mov    %eax,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104eb0:	8b 45 14             	mov    0x14(%ebp),%eax
f0104eb3:	8d 50 04             	lea    0x4(%eax),%edx
f0104eb6:	89 55 14             	mov    %edx,0x14(%ebp)
f0104eb9:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104ebb:	85 ff                	test   %edi,%edi
f0104ebd:	ba 73 79 10 f0       	mov    $0xf0107973,%edx
f0104ec2:	0f 44 fa             	cmove  %edx,%edi
			if (width > 0 && padc != '-')
f0104ec5:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0104ec9:	0f 84 92 00 00 00    	je     f0104f61 <vprintfmt+0x22c>
f0104ecf:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0104ed3:	0f 8e 96 00 00 00    	jle    f0104f6f <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104ed9:	83 ec 08             	sub    $0x8,%esp
f0104edc:	51                   	push   %ecx
f0104edd:	57                   	push   %edi
f0104ede:	e8 5f 03 00 00       	call   f0105242 <strnlen>
f0104ee3:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104ee6:	29 c1                	sub    %eax,%ecx
f0104ee8:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0104eeb:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104eee:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104ef2:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104ef5:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104ef8:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104efa:	eb 0f                	jmp    f0104f0b <vprintfmt+0x1d6>
					putch(padc, putdat);
f0104efc:	83 ec 08             	sub    $0x8,%esp
f0104eff:	53                   	push   %ebx
f0104f00:	ff 75 e0             	pushl  -0x20(%ebp)
f0104f03:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104f05:	83 ef 01             	sub    $0x1,%edi
f0104f08:	83 c4 10             	add    $0x10,%esp
f0104f0b:	85 ff                	test   %edi,%edi
f0104f0d:	7f ed                	jg     f0104efc <vprintfmt+0x1c7>
f0104f0f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104f12:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104f15:	85 c9                	test   %ecx,%ecx
f0104f17:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f1c:	0f 49 c1             	cmovns %ecx,%eax
f0104f1f:	29 c1                	sub    %eax,%ecx
f0104f21:	89 75 08             	mov    %esi,0x8(%ebp)
f0104f24:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104f27:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104f2a:	89 cb                	mov    %ecx,%ebx
f0104f2c:	eb 4d                	jmp    f0104f7b <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104f2e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104f32:	74 1b                	je     f0104f4f <vprintfmt+0x21a>
f0104f34:	0f be c0             	movsbl %al,%eax
f0104f37:	83 e8 20             	sub    $0x20,%eax
f0104f3a:	83 f8 5e             	cmp    $0x5e,%eax
f0104f3d:	76 10                	jbe    f0104f4f <vprintfmt+0x21a>
					putch('?', putdat);
f0104f3f:	83 ec 08             	sub    $0x8,%esp
f0104f42:	ff 75 0c             	pushl  0xc(%ebp)
f0104f45:	6a 3f                	push   $0x3f
f0104f47:	ff 55 08             	call   *0x8(%ebp)
f0104f4a:	83 c4 10             	add    $0x10,%esp
f0104f4d:	eb 0d                	jmp    f0104f5c <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0104f4f:	83 ec 08             	sub    $0x8,%esp
f0104f52:	ff 75 0c             	pushl  0xc(%ebp)
f0104f55:	52                   	push   %edx
f0104f56:	ff 55 08             	call   *0x8(%ebp)
f0104f59:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104f5c:	83 eb 01             	sub    $0x1,%ebx
f0104f5f:	eb 1a                	jmp    f0104f7b <vprintfmt+0x246>
f0104f61:	89 75 08             	mov    %esi,0x8(%ebp)
f0104f64:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104f67:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104f6a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104f6d:	eb 0c                	jmp    f0104f7b <vprintfmt+0x246>
f0104f6f:	89 75 08             	mov    %esi,0x8(%ebp)
f0104f72:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104f75:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104f78:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104f7b:	83 c7 01             	add    $0x1,%edi
f0104f7e:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104f82:	0f be d0             	movsbl %al,%edx
f0104f85:	85 d2                	test   %edx,%edx
f0104f87:	74 23                	je     f0104fac <vprintfmt+0x277>
f0104f89:	85 f6                	test   %esi,%esi
f0104f8b:	78 a1                	js     f0104f2e <vprintfmt+0x1f9>
f0104f8d:	83 ee 01             	sub    $0x1,%esi
f0104f90:	79 9c                	jns    f0104f2e <vprintfmt+0x1f9>
f0104f92:	89 df                	mov    %ebx,%edi
f0104f94:	8b 75 08             	mov    0x8(%ebp),%esi
f0104f97:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104f9a:	eb 18                	jmp    f0104fb4 <vprintfmt+0x27f>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104f9c:	83 ec 08             	sub    $0x8,%esp
f0104f9f:	53                   	push   %ebx
f0104fa0:	6a 20                	push   $0x20
f0104fa2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104fa4:	83 ef 01             	sub    $0x1,%edi
f0104fa7:	83 c4 10             	add    $0x10,%esp
f0104faa:	eb 08                	jmp    f0104fb4 <vprintfmt+0x27f>
f0104fac:	89 df                	mov    %ebx,%edi
f0104fae:	8b 75 08             	mov    0x8(%ebp),%esi
f0104fb1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104fb4:	85 ff                	test   %edi,%edi
f0104fb6:	7f e4                	jg     f0104f9c <vprintfmt+0x267>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104fb8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104fbb:	e9 9b fd ff ff       	jmp    f0104d5b <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104fc0:	83 fa 01             	cmp    $0x1,%edx
f0104fc3:	7e 16                	jle    f0104fdb <vprintfmt+0x2a6>
		return va_arg(*ap, long long);
f0104fc5:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fc8:	8d 50 08             	lea    0x8(%eax),%edx
f0104fcb:	89 55 14             	mov    %edx,0x14(%ebp)
f0104fce:	8b 50 04             	mov    0x4(%eax),%edx
f0104fd1:	8b 00                	mov    (%eax),%eax
f0104fd3:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104fd6:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104fd9:	eb 32                	jmp    f010500d <vprintfmt+0x2d8>
	else if (lflag)
f0104fdb:	85 d2                	test   %edx,%edx
f0104fdd:	74 18                	je     f0104ff7 <vprintfmt+0x2c2>
		return va_arg(*ap, long);
f0104fdf:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fe2:	8d 50 04             	lea    0x4(%eax),%edx
f0104fe5:	89 55 14             	mov    %edx,0x14(%ebp)
f0104fe8:	8b 00                	mov    (%eax),%eax
f0104fea:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104fed:	89 c1                	mov    %eax,%ecx
f0104fef:	c1 f9 1f             	sar    $0x1f,%ecx
f0104ff2:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104ff5:	eb 16                	jmp    f010500d <vprintfmt+0x2d8>
	else
		return va_arg(*ap, int);
f0104ff7:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ffa:	8d 50 04             	lea    0x4(%eax),%edx
f0104ffd:	89 55 14             	mov    %edx,0x14(%ebp)
f0105000:	8b 00                	mov    (%eax),%eax
f0105002:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105005:	89 c1                	mov    %eax,%ecx
f0105007:	c1 f9 1f             	sar    $0x1f,%ecx
f010500a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010500d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0105010:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0105013:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0105018:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010501c:	79 74                	jns    f0105092 <vprintfmt+0x35d>
				putch('-', putdat);
f010501e:	83 ec 08             	sub    $0x8,%esp
f0105021:	53                   	push   %ebx
f0105022:	6a 2d                	push   $0x2d
f0105024:	ff d6                	call   *%esi
				num = -(long long) num;
f0105026:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0105029:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010502c:	f7 d8                	neg    %eax
f010502e:	83 d2 00             	adc    $0x0,%edx
f0105031:	f7 da                	neg    %edx
f0105033:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0105036:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010503b:	eb 55                	jmp    f0105092 <vprintfmt+0x35d>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010503d:	8d 45 14             	lea    0x14(%ebp),%eax
f0105040:	e8 7c fc ff ff       	call   f0104cc1 <getuint>
			base = 10;
f0105045:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f010504a:	eb 46                	jmp    f0105092 <vprintfmt+0x35d>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f010504c:	8d 45 14             	lea    0x14(%ebp),%eax
f010504f:	e8 6d fc ff ff       	call   f0104cc1 <getuint>
			base = 8;
f0105054:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0105059:	eb 37                	jmp    f0105092 <vprintfmt+0x35d>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f010505b:	83 ec 08             	sub    $0x8,%esp
f010505e:	53                   	push   %ebx
f010505f:	6a 30                	push   $0x30
f0105061:	ff d6                	call   *%esi
			putch('x', putdat);
f0105063:	83 c4 08             	add    $0x8,%esp
f0105066:	53                   	push   %ebx
f0105067:	6a 78                	push   $0x78
f0105069:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010506b:	8b 45 14             	mov    0x14(%ebp),%eax
f010506e:	8d 50 04             	lea    0x4(%eax),%edx
f0105071:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0105074:	8b 00                	mov    (%eax),%eax
f0105076:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010507b:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010507e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0105083:	eb 0d                	jmp    f0105092 <vprintfmt+0x35d>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0105085:	8d 45 14             	lea    0x14(%ebp),%eax
f0105088:	e8 34 fc ff ff       	call   f0104cc1 <getuint>
			base = 16;
f010508d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0105092:	83 ec 0c             	sub    $0xc,%esp
f0105095:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0105099:	57                   	push   %edi
f010509a:	ff 75 e0             	pushl  -0x20(%ebp)
f010509d:	51                   	push   %ecx
f010509e:	52                   	push   %edx
f010509f:	50                   	push   %eax
f01050a0:	89 da                	mov    %ebx,%edx
f01050a2:	89 f0                	mov    %esi,%eax
f01050a4:	e8 6e fb ff ff       	call   f0104c17 <printnum>
			break;
f01050a9:	83 c4 20             	add    $0x20,%esp
f01050ac:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01050af:	e9 a7 fc ff ff       	jmp    f0104d5b <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01050b4:	83 ec 08             	sub    $0x8,%esp
f01050b7:	53                   	push   %ebx
f01050b8:	51                   	push   %ecx
f01050b9:	ff d6                	call   *%esi
			break;
f01050bb:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01050be:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01050c1:	e9 95 fc ff ff       	jmp    f0104d5b <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01050c6:	83 ec 08             	sub    $0x8,%esp
f01050c9:	53                   	push   %ebx
f01050ca:	6a 25                	push   $0x25
f01050cc:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01050ce:	83 c4 10             	add    $0x10,%esp
f01050d1:	eb 03                	jmp    f01050d6 <vprintfmt+0x3a1>
f01050d3:	83 ef 01             	sub    $0x1,%edi
f01050d6:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01050da:	75 f7                	jne    f01050d3 <vprintfmt+0x39e>
f01050dc:	e9 7a fc ff ff       	jmp    f0104d5b <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01050e1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01050e4:	5b                   	pop    %ebx
f01050e5:	5e                   	pop    %esi
f01050e6:	5f                   	pop    %edi
f01050e7:	5d                   	pop    %ebp
f01050e8:	c3                   	ret    

f01050e9 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01050e9:	55                   	push   %ebp
f01050ea:	89 e5                	mov    %esp,%ebp
f01050ec:	83 ec 18             	sub    $0x18,%esp
f01050ef:	8b 45 08             	mov    0x8(%ebp),%eax
f01050f2:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01050f5:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01050f8:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01050fc:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01050ff:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0105106:	85 c0                	test   %eax,%eax
f0105108:	74 26                	je     f0105130 <vsnprintf+0x47>
f010510a:	85 d2                	test   %edx,%edx
f010510c:	7e 22                	jle    f0105130 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010510e:	ff 75 14             	pushl  0x14(%ebp)
f0105111:	ff 75 10             	pushl  0x10(%ebp)
f0105114:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0105117:	50                   	push   %eax
f0105118:	68 fb 4c 10 f0       	push   $0xf0104cfb
f010511d:	e8 13 fc ff ff       	call   f0104d35 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0105122:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105125:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0105128:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010512b:	83 c4 10             	add    $0x10,%esp
f010512e:	eb 05                	jmp    f0105135 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0105130:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0105135:	c9                   	leave  
f0105136:	c3                   	ret    

f0105137 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0105137:	55                   	push   %ebp
f0105138:	89 e5                	mov    %esp,%ebp
f010513a:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010513d:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0105140:	50                   	push   %eax
f0105141:	ff 75 10             	pushl  0x10(%ebp)
f0105144:	ff 75 0c             	pushl  0xc(%ebp)
f0105147:	ff 75 08             	pushl  0x8(%ebp)
f010514a:	e8 9a ff ff ff       	call   f01050e9 <vsnprintf>
	va_end(ap);

	return rc;
}
f010514f:	c9                   	leave  
f0105150:	c3                   	ret    

f0105151 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0105151:	55                   	push   %ebp
f0105152:	89 e5                	mov    %esp,%ebp
f0105154:	57                   	push   %edi
f0105155:	56                   	push   %esi
f0105156:	53                   	push   %ebx
f0105157:	83 ec 0c             	sub    $0xc,%esp
f010515a:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010515d:	85 c0                	test   %eax,%eax
f010515f:	74 11                	je     f0105172 <readline+0x21>
		cprintf("%s", prompt);
f0105161:	83 ec 08             	sub    $0x8,%esp
f0105164:	50                   	push   %eax
f0105165:	68 6d 70 10 f0       	push   $0xf010706d
f010516a:	e8 e2 e6 ff ff       	call   f0103851 <cprintf>
f010516f:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0105172:	83 ec 0c             	sub    $0xc,%esp
f0105175:	6a 00                	push   $0x0
f0105177:	e8 ea b5 ff ff       	call   f0100766 <iscons>
f010517c:	89 c7                	mov    %eax,%edi
f010517e:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0105181:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0105186:	e8 ca b5 ff ff       	call   f0100755 <getchar>
f010518b:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010518d:	85 c0                	test   %eax,%eax
f010518f:	79 18                	jns    f01051a9 <readline+0x58>
			cprintf("read error: %e\n", c);
f0105191:	83 ec 08             	sub    $0x8,%esp
f0105194:	50                   	push   %eax
f0105195:	68 a8 7b 10 f0       	push   $0xf0107ba8
f010519a:	e8 b2 e6 ff ff       	call   f0103851 <cprintf>
			return NULL;
f010519f:	83 c4 10             	add    $0x10,%esp
f01051a2:	b8 00 00 00 00       	mov    $0x0,%eax
f01051a7:	eb 79                	jmp    f0105222 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01051a9:	83 f8 7f             	cmp    $0x7f,%eax
f01051ac:	0f 94 c2             	sete   %dl
f01051af:	83 f8 08             	cmp    $0x8,%eax
f01051b2:	0f 94 c0             	sete   %al
f01051b5:	08 c2                	or     %al,%dl
f01051b7:	74 1a                	je     f01051d3 <readline+0x82>
f01051b9:	85 f6                	test   %esi,%esi
f01051bb:	7e 16                	jle    f01051d3 <readline+0x82>
			if (echoing)
f01051bd:	85 ff                	test   %edi,%edi
f01051bf:	74 0d                	je     f01051ce <readline+0x7d>
				cputchar('\b');
f01051c1:	83 ec 0c             	sub    $0xc,%esp
f01051c4:	6a 08                	push   $0x8
f01051c6:	e8 7a b5 ff ff       	call   f0100745 <cputchar>
f01051cb:	83 c4 10             	add    $0x10,%esp
			i--;
f01051ce:	83 ee 01             	sub    $0x1,%esi
f01051d1:	eb b3                	jmp    f0105186 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01051d3:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01051d9:	7f 20                	jg     f01051fb <readline+0xaa>
f01051db:	83 fb 1f             	cmp    $0x1f,%ebx
f01051de:	7e 1b                	jle    f01051fb <readline+0xaa>
			if (echoing)
f01051e0:	85 ff                	test   %edi,%edi
f01051e2:	74 0c                	je     f01051f0 <readline+0x9f>
				cputchar(c);
f01051e4:	83 ec 0c             	sub    $0xc,%esp
f01051e7:	53                   	push   %ebx
f01051e8:	e8 58 b5 ff ff       	call   f0100745 <cputchar>
f01051ed:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01051f0:	88 9e c0 0a 23 f0    	mov    %bl,-0xfdcf540(%esi)
f01051f6:	8d 76 01             	lea    0x1(%esi),%esi
f01051f9:	eb 8b                	jmp    f0105186 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01051fb:	83 fb 0d             	cmp    $0xd,%ebx
f01051fe:	74 05                	je     f0105205 <readline+0xb4>
f0105200:	83 fb 0a             	cmp    $0xa,%ebx
f0105203:	75 81                	jne    f0105186 <readline+0x35>
			if (echoing)
f0105205:	85 ff                	test   %edi,%edi
f0105207:	74 0d                	je     f0105216 <readline+0xc5>
				cputchar('\n');
f0105209:	83 ec 0c             	sub    $0xc,%esp
f010520c:	6a 0a                	push   $0xa
f010520e:	e8 32 b5 ff ff       	call   f0100745 <cputchar>
f0105213:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0105216:	c6 86 c0 0a 23 f0 00 	movb   $0x0,-0xfdcf540(%esi)
			return buf;
f010521d:	b8 c0 0a 23 f0       	mov    $0xf0230ac0,%eax
		}
	}
}
f0105222:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105225:	5b                   	pop    %ebx
f0105226:	5e                   	pop    %esi
f0105227:	5f                   	pop    %edi
f0105228:	5d                   	pop    %ebp
f0105229:	c3                   	ret    

f010522a <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010522a:	55                   	push   %ebp
f010522b:	89 e5                	mov    %esp,%ebp
f010522d:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0105230:	b8 00 00 00 00       	mov    $0x0,%eax
f0105235:	eb 03                	jmp    f010523a <strlen+0x10>
		n++;
f0105237:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010523a:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010523e:	75 f7                	jne    f0105237 <strlen+0xd>
		n++;
	return n;
}
f0105240:	5d                   	pop    %ebp
f0105241:	c3                   	ret    

f0105242 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0105242:	55                   	push   %ebp
f0105243:	89 e5                	mov    %esp,%ebp
f0105245:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105248:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010524b:	ba 00 00 00 00       	mov    $0x0,%edx
f0105250:	eb 03                	jmp    f0105255 <strnlen+0x13>
		n++;
f0105252:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105255:	39 c2                	cmp    %eax,%edx
f0105257:	74 08                	je     f0105261 <strnlen+0x1f>
f0105259:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010525d:	75 f3                	jne    f0105252 <strnlen+0x10>
f010525f:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0105261:	5d                   	pop    %ebp
f0105262:	c3                   	ret    

f0105263 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0105263:	55                   	push   %ebp
f0105264:	89 e5                	mov    %esp,%ebp
f0105266:	53                   	push   %ebx
f0105267:	8b 45 08             	mov    0x8(%ebp),%eax
f010526a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010526d:	89 c2                	mov    %eax,%edx
f010526f:	83 c2 01             	add    $0x1,%edx
f0105272:	83 c1 01             	add    $0x1,%ecx
f0105275:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0105279:	88 5a ff             	mov    %bl,-0x1(%edx)
f010527c:	84 db                	test   %bl,%bl
f010527e:	75 ef                	jne    f010526f <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0105280:	5b                   	pop    %ebx
f0105281:	5d                   	pop    %ebp
f0105282:	c3                   	ret    

f0105283 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0105283:	55                   	push   %ebp
f0105284:	89 e5                	mov    %esp,%ebp
f0105286:	53                   	push   %ebx
f0105287:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010528a:	53                   	push   %ebx
f010528b:	e8 9a ff ff ff       	call   f010522a <strlen>
f0105290:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0105293:	ff 75 0c             	pushl  0xc(%ebp)
f0105296:	01 d8                	add    %ebx,%eax
f0105298:	50                   	push   %eax
f0105299:	e8 c5 ff ff ff       	call   f0105263 <strcpy>
	return dst;
}
f010529e:	89 d8                	mov    %ebx,%eax
f01052a0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01052a3:	c9                   	leave  
f01052a4:	c3                   	ret    

f01052a5 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01052a5:	55                   	push   %ebp
f01052a6:	89 e5                	mov    %esp,%ebp
f01052a8:	56                   	push   %esi
f01052a9:	53                   	push   %ebx
f01052aa:	8b 75 08             	mov    0x8(%ebp),%esi
f01052ad:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01052b0:	89 f3                	mov    %esi,%ebx
f01052b2:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01052b5:	89 f2                	mov    %esi,%edx
f01052b7:	eb 0f                	jmp    f01052c8 <strncpy+0x23>
		*dst++ = *src;
f01052b9:	83 c2 01             	add    $0x1,%edx
f01052bc:	0f b6 01             	movzbl (%ecx),%eax
f01052bf:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01052c2:	80 39 01             	cmpb   $0x1,(%ecx)
f01052c5:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01052c8:	39 da                	cmp    %ebx,%edx
f01052ca:	75 ed                	jne    f01052b9 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01052cc:	89 f0                	mov    %esi,%eax
f01052ce:	5b                   	pop    %ebx
f01052cf:	5e                   	pop    %esi
f01052d0:	5d                   	pop    %ebp
f01052d1:	c3                   	ret    

f01052d2 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01052d2:	55                   	push   %ebp
f01052d3:	89 e5                	mov    %esp,%ebp
f01052d5:	56                   	push   %esi
f01052d6:	53                   	push   %ebx
f01052d7:	8b 75 08             	mov    0x8(%ebp),%esi
f01052da:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01052dd:	8b 55 10             	mov    0x10(%ebp),%edx
f01052e0:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01052e2:	85 d2                	test   %edx,%edx
f01052e4:	74 21                	je     f0105307 <strlcpy+0x35>
f01052e6:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01052ea:	89 f2                	mov    %esi,%edx
f01052ec:	eb 09                	jmp    f01052f7 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01052ee:	83 c2 01             	add    $0x1,%edx
f01052f1:	83 c1 01             	add    $0x1,%ecx
f01052f4:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01052f7:	39 c2                	cmp    %eax,%edx
f01052f9:	74 09                	je     f0105304 <strlcpy+0x32>
f01052fb:	0f b6 19             	movzbl (%ecx),%ebx
f01052fe:	84 db                	test   %bl,%bl
f0105300:	75 ec                	jne    f01052ee <strlcpy+0x1c>
f0105302:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0105304:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105307:	29 f0                	sub    %esi,%eax
}
f0105309:	5b                   	pop    %ebx
f010530a:	5e                   	pop    %esi
f010530b:	5d                   	pop    %ebp
f010530c:	c3                   	ret    

f010530d <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010530d:	55                   	push   %ebp
f010530e:	89 e5                	mov    %esp,%ebp
f0105310:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105313:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105316:	eb 06                	jmp    f010531e <strcmp+0x11>
		p++, q++;
f0105318:	83 c1 01             	add    $0x1,%ecx
f010531b:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010531e:	0f b6 01             	movzbl (%ecx),%eax
f0105321:	84 c0                	test   %al,%al
f0105323:	74 04                	je     f0105329 <strcmp+0x1c>
f0105325:	3a 02                	cmp    (%edx),%al
f0105327:	74 ef                	je     f0105318 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105329:	0f b6 c0             	movzbl %al,%eax
f010532c:	0f b6 12             	movzbl (%edx),%edx
f010532f:	29 d0                	sub    %edx,%eax
}
f0105331:	5d                   	pop    %ebp
f0105332:	c3                   	ret    

f0105333 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0105333:	55                   	push   %ebp
f0105334:	89 e5                	mov    %esp,%ebp
f0105336:	53                   	push   %ebx
f0105337:	8b 45 08             	mov    0x8(%ebp),%eax
f010533a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010533d:	89 c3                	mov    %eax,%ebx
f010533f:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0105342:	eb 06                	jmp    f010534a <strncmp+0x17>
		n--, p++, q++;
f0105344:	83 c0 01             	add    $0x1,%eax
f0105347:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010534a:	39 d8                	cmp    %ebx,%eax
f010534c:	74 15                	je     f0105363 <strncmp+0x30>
f010534e:	0f b6 08             	movzbl (%eax),%ecx
f0105351:	84 c9                	test   %cl,%cl
f0105353:	74 04                	je     f0105359 <strncmp+0x26>
f0105355:	3a 0a                	cmp    (%edx),%cl
f0105357:	74 eb                	je     f0105344 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105359:	0f b6 00             	movzbl (%eax),%eax
f010535c:	0f b6 12             	movzbl (%edx),%edx
f010535f:	29 d0                	sub    %edx,%eax
f0105361:	eb 05                	jmp    f0105368 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0105363:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0105368:	5b                   	pop    %ebx
f0105369:	5d                   	pop    %ebp
f010536a:	c3                   	ret    

f010536b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010536b:	55                   	push   %ebp
f010536c:	89 e5                	mov    %esp,%ebp
f010536e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105371:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105375:	eb 07                	jmp    f010537e <strchr+0x13>
		if (*s == c)
f0105377:	38 ca                	cmp    %cl,%dl
f0105379:	74 0f                	je     f010538a <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010537b:	83 c0 01             	add    $0x1,%eax
f010537e:	0f b6 10             	movzbl (%eax),%edx
f0105381:	84 d2                	test   %dl,%dl
f0105383:	75 f2                	jne    f0105377 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0105385:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010538a:	5d                   	pop    %ebp
f010538b:	c3                   	ret    

f010538c <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010538c:	55                   	push   %ebp
f010538d:	89 e5                	mov    %esp,%ebp
f010538f:	8b 45 08             	mov    0x8(%ebp),%eax
f0105392:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105396:	eb 03                	jmp    f010539b <strfind+0xf>
f0105398:	83 c0 01             	add    $0x1,%eax
f010539b:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010539e:	84 d2                	test   %dl,%dl
f01053a0:	74 04                	je     f01053a6 <strfind+0x1a>
f01053a2:	38 ca                	cmp    %cl,%dl
f01053a4:	75 f2                	jne    f0105398 <strfind+0xc>
			break;
	return (char *) s;
}
f01053a6:	5d                   	pop    %ebp
f01053a7:	c3                   	ret    

f01053a8 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01053a8:	55                   	push   %ebp
f01053a9:	89 e5                	mov    %esp,%ebp
f01053ab:	57                   	push   %edi
f01053ac:	56                   	push   %esi
f01053ad:	53                   	push   %ebx
f01053ae:	8b 7d 08             	mov    0x8(%ebp),%edi
f01053b1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01053b4:	85 c9                	test   %ecx,%ecx
f01053b6:	74 36                	je     f01053ee <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01053b8:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01053be:	75 28                	jne    f01053e8 <memset+0x40>
f01053c0:	f6 c1 03             	test   $0x3,%cl
f01053c3:	75 23                	jne    f01053e8 <memset+0x40>
		c &= 0xFF;
f01053c5:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01053c9:	89 d3                	mov    %edx,%ebx
f01053cb:	c1 e3 08             	shl    $0x8,%ebx
f01053ce:	89 d6                	mov    %edx,%esi
f01053d0:	c1 e6 18             	shl    $0x18,%esi
f01053d3:	89 d0                	mov    %edx,%eax
f01053d5:	c1 e0 10             	shl    $0x10,%eax
f01053d8:	09 f0                	or     %esi,%eax
f01053da:	09 c2                	or     %eax,%edx
f01053dc:	89 d0                	mov    %edx,%eax
f01053de:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01053e0:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01053e3:	fc                   	cld    
f01053e4:	f3 ab                	rep stos %eax,%es:(%edi)
f01053e6:	eb 06                	jmp    f01053ee <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01053e8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01053eb:	fc                   	cld    
f01053ec:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01053ee:	89 f8                	mov    %edi,%eax
f01053f0:	5b                   	pop    %ebx
f01053f1:	5e                   	pop    %esi
f01053f2:	5f                   	pop    %edi
f01053f3:	5d                   	pop    %ebp
f01053f4:	c3                   	ret    

f01053f5 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01053f5:	55                   	push   %ebp
f01053f6:	89 e5                	mov    %esp,%ebp
f01053f8:	57                   	push   %edi
f01053f9:	56                   	push   %esi
f01053fa:	8b 45 08             	mov    0x8(%ebp),%eax
f01053fd:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105400:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0105403:	39 c6                	cmp    %eax,%esi
f0105405:	73 35                	jae    f010543c <memmove+0x47>
f0105407:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010540a:	39 d0                	cmp    %edx,%eax
f010540c:	73 2e                	jae    f010543c <memmove+0x47>
		s += n;
		d += n;
f010540e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0105411:	89 d6                	mov    %edx,%esi
f0105413:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105415:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010541b:	75 13                	jne    f0105430 <memmove+0x3b>
f010541d:	f6 c1 03             	test   $0x3,%cl
f0105420:	75 0e                	jne    f0105430 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0105422:	83 ef 04             	sub    $0x4,%edi
f0105425:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105428:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010542b:	fd                   	std    
f010542c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010542e:	eb 09                	jmp    f0105439 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0105430:	83 ef 01             	sub    $0x1,%edi
f0105433:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0105436:	fd                   	std    
f0105437:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105439:	fc                   	cld    
f010543a:	eb 1d                	jmp    f0105459 <memmove+0x64>
f010543c:	89 f2                	mov    %esi,%edx
f010543e:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105440:	f6 c2 03             	test   $0x3,%dl
f0105443:	75 0f                	jne    f0105454 <memmove+0x5f>
f0105445:	f6 c1 03             	test   $0x3,%cl
f0105448:	75 0a                	jne    f0105454 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010544a:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010544d:	89 c7                	mov    %eax,%edi
f010544f:	fc                   	cld    
f0105450:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105452:	eb 05                	jmp    f0105459 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0105454:	89 c7                	mov    %eax,%edi
f0105456:	fc                   	cld    
f0105457:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105459:	5e                   	pop    %esi
f010545a:	5f                   	pop    %edi
f010545b:	5d                   	pop    %ebp
f010545c:	c3                   	ret    

f010545d <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010545d:	55                   	push   %ebp
f010545e:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0105460:	ff 75 10             	pushl  0x10(%ebp)
f0105463:	ff 75 0c             	pushl  0xc(%ebp)
f0105466:	ff 75 08             	pushl  0x8(%ebp)
f0105469:	e8 87 ff ff ff       	call   f01053f5 <memmove>
}
f010546e:	c9                   	leave  
f010546f:	c3                   	ret    

f0105470 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0105470:	55                   	push   %ebp
f0105471:	89 e5                	mov    %esp,%ebp
f0105473:	56                   	push   %esi
f0105474:	53                   	push   %ebx
f0105475:	8b 45 08             	mov    0x8(%ebp),%eax
f0105478:	8b 55 0c             	mov    0xc(%ebp),%edx
f010547b:	89 c6                	mov    %eax,%esi
f010547d:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105480:	eb 1a                	jmp    f010549c <memcmp+0x2c>
		if (*s1 != *s2)
f0105482:	0f b6 08             	movzbl (%eax),%ecx
f0105485:	0f b6 1a             	movzbl (%edx),%ebx
f0105488:	38 d9                	cmp    %bl,%cl
f010548a:	74 0a                	je     f0105496 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010548c:	0f b6 c1             	movzbl %cl,%eax
f010548f:	0f b6 db             	movzbl %bl,%ebx
f0105492:	29 d8                	sub    %ebx,%eax
f0105494:	eb 0f                	jmp    f01054a5 <memcmp+0x35>
		s1++, s2++;
f0105496:	83 c0 01             	add    $0x1,%eax
f0105499:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010549c:	39 f0                	cmp    %esi,%eax
f010549e:	75 e2                	jne    f0105482 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01054a0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01054a5:	5b                   	pop    %ebx
f01054a6:	5e                   	pop    %esi
f01054a7:	5d                   	pop    %ebp
f01054a8:	c3                   	ret    

f01054a9 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01054a9:	55                   	push   %ebp
f01054aa:	89 e5                	mov    %esp,%ebp
f01054ac:	8b 45 08             	mov    0x8(%ebp),%eax
f01054af:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01054b2:	89 c2                	mov    %eax,%edx
f01054b4:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01054b7:	eb 07                	jmp    f01054c0 <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01054b9:	38 08                	cmp    %cl,(%eax)
f01054bb:	74 07                	je     f01054c4 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01054bd:	83 c0 01             	add    $0x1,%eax
f01054c0:	39 d0                	cmp    %edx,%eax
f01054c2:	72 f5                	jb     f01054b9 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01054c4:	5d                   	pop    %ebp
f01054c5:	c3                   	ret    

f01054c6 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01054c6:	55                   	push   %ebp
f01054c7:	89 e5                	mov    %esp,%ebp
f01054c9:	57                   	push   %edi
f01054ca:	56                   	push   %esi
f01054cb:	53                   	push   %ebx
f01054cc:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01054cf:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01054d2:	eb 03                	jmp    f01054d7 <strtol+0x11>
		s++;
f01054d4:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01054d7:	0f b6 01             	movzbl (%ecx),%eax
f01054da:	3c 09                	cmp    $0x9,%al
f01054dc:	74 f6                	je     f01054d4 <strtol+0xe>
f01054de:	3c 20                	cmp    $0x20,%al
f01054e0:	74 f2                	je     f01054d4 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01054e2:	3c 2b                	cmp    $0x2b,%al
f01054e4:	75 0a                	jne    f01054f0 <strtol+0x2a>
		s++;
f01054e6:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01054e9:	bf 00 00 00 00       	mov    $0x0,%edi
f01054ee:	eb 10                	jmp    f0105500 <strtol+0x3a>
f01054f0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01054f5:	3c 2d                	cmp    $0x2d,%al
f01054f7:	75 07                	jne    f0105500 <strtol+0x3a>
		s++, neg = 1;
f01054f9:	8d 49 01             	lea    0x1(%ecx),%ecx
f01054fc:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105500:	85 db                	test   %ebx,%ebx
f0105502:	0f 94 c0             	sete   %al
f0105505:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010550b:	75 19                	jne    f0105526 <strtol+0x60>
f010550d:	80 39 30             	cmpb   $0x30,(%ecx)
f0105510:	75 14                	jne    f0105526 <strtol+0x60>
f0105512:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0105516:	0f 85 82 00 00 00    	jne    f010559e <strtol+0xd8>
		s += 2, base = 16;
f010551c:	83 c1 02             	add    $0x2,%ecx
f010551f:	bb 10 00 00 00       	mov    $0x10,%ebx
f0105524:	eb 16                	jmp    f010553c <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0105526:	84 c0                	test   %al,%al
f0105528:	74 12                	je     f010553c <strtol+0x76>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010552a:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010552f:	80 39 30             	cmpb   $0x30,(%ecx)
f0105532:	75 08                	jne    f010553c <strtol+0x76>
		s++, base = 8;
f0105534:	83 c1 01             	add    $0x1,%ecx
f0105537:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f010553c:	b8 00 00 00 00       	mov    $0x0,%eax
f0105541:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0105544:	0f b6 11             	movzbl (%ecx),%edx
f0105547:	8d 72 d0             	lea    -0x30(%edx),%esi
f010554a:	89 f3                	mov    %esi,%ebx
f010554c:	80 fb 09             	cmp    $0x9,%bl
f010554f:	77 08                	ja     f0105559 <strtol+0x93>
			dig = *s - '0';
f0105551:	0f be d2             	movsbl %dl,%edx
f0105554:	83 ea 30             	sub    $0x30,%edx
f0105557:	eb 22                	jmp    f010557b <strtol+0xb5>
		else if (*s >= 'a' && *s <= 'z')
f0105559:	8d 72 9f             	lea    -0x61(%edx),%esi
f010555c:	89 f3                	mov    %esi,%ebx
f010555e:	80 fb 19             	cmp    $0x19,%bl
f0105561:	77 08                	ja     f010556b <strtol+0xa5>
			dig = *s - 'a' + 10;
f0105563:	0f be d2             	movsbl %dl,%edx
f0105566:	83 ea 57             	sub    $0x57,%edx
f0105569:	eb 10                	jmp    f010557b <strtol+0xb5>
		else if (*s >= 'A' && *s <= 'Z')
f010556b:	8d 72 bf             	lea    -0x41(%edx),%esi
f010556e:	89 f3                	mov    %esi,%ebx
f0105570:	80 fb 19             	cmp    $0x19,%bl
f0105573:	77 16                	ja     f010558b <strtol+0xc5>
			dig = *s - 'A' + 10;
f0105575:	0f be d2             	movsbl %dl,%edx
f0105578:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010557b:	3b 55 10             	cmp    0x10(%ebp),%edx
f010557e:	7d 0f                	jge    f010558f <strtol+0xc9>
			break;
		s++, val = (val * base) + dig;
f0105580:	83 c1 01             	add    $0x1,%ecx
f0105583:	0f af 45 10          	imul   0x10(%ebp),%eax
f0105587:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0105589:	eb b9                	jmp    f0105544 <strtol+0x7e>
f010558b:	89 c2                	mov    %eax,%edx
f010558d:	eb 02                	jmp    f0105591 <strtol+0xcb>
f010558f:	89 c2                	mov    %eax,%edx

	if (endptr)
f0105591:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105595:	74 0d                	je     f01055a4 <strtol+0xde>
		*endptr = (char *) s;
f0105597:	8b 75 0c             	mov    0xc(%ebp),%esi
f010559a:	89 0e                	mov    %ecx,(%esi)
f010559c:	eb 06                	jmp    f01055a4 <strtol+0xde>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010559e:	84 c0                	test   %al,%al
f01055a0:	75 92                	jne    f0105534 <strtol+0x6e>
f01055a2:	eb 98                	jmp    f010553c <strtol+0x76>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01055a4:	f7 da                	neg    %edx
f01055a6:	85 ff                	test   %edi,%edi
f01055a8:	0f 45 c2             	cmovne %edx,%eax
}
f01055ab:	5b                   	pop    %ebx
f01055ac:	5e                   	pop    %esi
f01055ad:	5f                   	pop    %edi
f01055ae:	5d                   	pop    %ebp
f01055af:	c3                   	ret    

f01055b0 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f01055b0:	fa                   	cli    

	xorw    %ax, %ax
f01055b1:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f01055b3:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01055b5:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01055b7:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f01055b9:	0f 01 16             	lgdtl  (%esi)
f01055bc:	74 70                	je     f010562e <mpsearch1+0x3>
	movl    %cr0, %eax
f01055be:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f01055c1:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f01055c5:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f01055c8:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f01055ce:	08 00                	or     %al,(%eax)

f01055d0 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f01055d0:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f01055d4:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01055d6:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01055d8:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f01055da:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f01055de:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f01055e0:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f01055e2:	b8 00 e0 11 00       	mov    $0x11e000,%eax
	movl    %eax, %cr3
f01055e7:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f01055ea:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f01055ed:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f01055f2:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f01055f5:	8b 25 c4 0e 23 f0    	mov    0xf0230ec4,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f01055fb:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0105600:	b8 b4 01 10 f0       	mov    $0xf01001b4,%eax
	call    *%eax
f0105605:	ff d0                	call   *%eax

f0105607 <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0105607:	eb fe                	jmp    f0105607 <spin>
f0105609:	8d 76 00             	lea    0x0(%esi),%esi

f010560c <gdt>:
	...
f0105614:	ff                   	(bad)  
f0105615:	ff 00                	incl   (%eax)
f0105617:	00 00                	add    %al,(%eax)
f0105619:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0105620:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

f0105624 <gdtdesc>:
f0105624:	17                   	pop    %ss
f0105625:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f010562a <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f010562a:	90                   	nop

f010562b <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f010562b:	55                   	push   %ebp
f010562c:	89 e5                	mov    %esp,%ebp
f010562e:	57                   	push   %edi
f010562f:	56                   	push   %esi
f0105630:	53                   	push   %ebx
f0105631:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105634:	8b 0d c8 0e 23 f0    	mov    0xf0230ec8,%ecx
f010563a:	89 c3                	mov    %eax,%ebx
f010563c:	c1 eb 0c             	shr    $0xc,%ebx
f010563f:	39 cb                	cmp    %ecx,%ebx
f0105641:	72 12                	jb     f0105655 <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105643:	50                   	push   %eax
f0105644:	68 a4 60 10 f0       	push   $0xf01060a4
f0105649:	6a 57                	push   $0x57
f010564b:	68 45 7d 10 f0       	push   $0xf0107d45
f0105650:	e8 eb a9 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105655:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f010565b:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010565d:	89 c2                	mov    %eax,%edx
f010565f:	c1 ea 0c             	shr    $0xc,%edx
f0105662:	39 d1                	cmp    %edx,%ecx
f0105664:	77 12                	ja     f0105678 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105666:	50                   	push   %eax
f0105667:	68 a4 60 10 f0       	push   $0xf01060a4
f010566c:	6a 57                	push   $0x57
f010566e:	68 45 7d 10 f0       	push   $0xf0107d45
f0105673:	e8 c8 a9 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105678:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f010567e:	eb 2f                	jmp    f01056af <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105680:	83 ec 04             	sub    $0x4,%esp
f0105683:	6a 04                	push   $0x4
f0105685:	68 55 7d 10 f0       	push   $0xf0107d55
f010568a:	53                   	push   %ebx
f010568b:	e8 e0 fd ff ff       	call   f0105470 <memcmp>
f0105690:	83 c4 10             	add    $0x10,%esp
f0105693:	85 c0                	test   %eax,%eax
f0105695:	75 15                	jne    f01056ac <mpsearch1+0x81>
f0105697:	89 da                	mov    %ebx,%edx
f0105699:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f010569c:	0f b6 0a             	movzbl (%edx),%ecx
f010569f:	01 c8                	add    %ecx,%eax
f01056a1:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01056a4:	39 fa                	cmp    %edi,%edx
f01056a6:	75 f4                	jne    f010569c <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01056a8:	84 c0                	test   %al,%al
f01056aa:	74 0e                	je     f01056ba <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f01056ac:	83 c3 10             	add    $0x10,%ebx
f01056af:	39 f3                	cmp    %esi,%ebx
f01056b1:	72 cd                	jb     f0105680 <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f01056b3:	b8 00 00 00 00       	mov    $0x0,%eax
f01056b8:	eb 02                	jmp    f01056bc <mpsearch1+0x91>
f01056ba:	89 d8                	mov    %ebx,%eax
}
f01056bc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01056bf:	5b                   	pop    %ebx
f01056c0:	5e                   	pop    %esi
f01056c1:	5f                   	pop    %edi
f01056c2:	5d                   	pop    %ebp
f01056c3:	c3                   	ret    

f01056c4 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f01056c4:	55                   	push   %ebp
f01056c5:	89 e5                	mov    %esp,%ebp
f01056c7:	57                   	push   %edi
f01056c8:	56                   	push   %esi
f01056c9:	53                   	push   %ebx
f01056ca:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f01056cd:	c7 05 e0 13 23 f0 40 	movl   $0xf0231040,0xf02313e0
f01056d4:	10 23 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01056d7:	83 3d c8 0e 23 f0 00 	cmpl   $0x0,0xf0230ec8
f01056de:	75 16                	jne    f01056f6 <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01056e0:	68 00 04 00 00       	push   $0x400
f01056e5:	68 a4 60 10 f0       	push   $0xf01060a4
f01056ea:	6a 6f                	push   $0x6f
f01056ec:	68 45 7d 10 f0       	push   $0xf0107d45
f01056f1:	e8 4a a9 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f01056f6:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f01056fd:	85 c0                	test   %eax,%eax
f01056ff:	74 16                	je     f0105717 <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
f0105701:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f0105704:	ba 00 04 00 00       	mov    $0x400,%edx
f0105709:	e8 1d ff ff ff       	call   f010562b <mpsearch1>
f010570e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105711:	85 c0                	test   %eax,%eax
f0105713:	75 3c                	jne    f0105751 <mp_init+0x8d>
f0105715:	eb 20                	jmp    f0105737 <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
f0105717:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f010571e:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f0105721:	2d 00 04 00 00       	sub    $0x400,%eax
f0105726:	ba 00 04 00 00       	mov    $0x400,%edx
f010572b:	e8 fb fe ff ff       	call   f010562b <mpsearch1>
f0105730:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105733:	85 c0                	test   %eax,%eax
f0105735:	75 1a                	jne    f0105751 <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f0105737:	ba 00 00 01 00       	mov    $0x10000,%edx
f010573c:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0105741:	e8 e5 fe ff ff       	call   f010562b <mpsearch1>
f0105746:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f0105749:	85 c0                	test   %eax,%eax
f010574b:	0f 84 5a 02 00 00    	je     f01059ab <mp_init+0x2e7>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f0105751:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105754:	8b 70 04             	mov    0x4(%eax),%esi
f0105757:	85 f6                	test   %esi,%esi
f0105759:	74 06                	je     f0105761 <mp_init+0x9d>
f010575b:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f010575f:	74 15                	je     f0105776 <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f0105761:	83 ec 0c             	sub    $0xc,%esp
f0105764:	68 b8 7b 10 f0       	push   $0xf0107bb8
f0105769:	e8 e3 e0 ff ff       	call   f0103851 <cprintf>
f010576e:	83 c4 10             	add    $0x10,%esp
f0105771:	e9 35 02 00 00       	jmp    f01059ab <mp_init+0x2e7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105776:	89 f0                	mov    %esi,%eax
f0105778:	c1 e8 0c             	shr    $0xc,%eax
f010577b:	3b 05 c8 0e 23 f0    	cmp    0xf0230ec8,%eax
f0105781:	72 15                	jb     f0105798 <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105783:	56                   	push   %esi
f0105784:	68 a4 60 10 f0       	push   $0xf01060a4
f0105789:	68 90 00 00 00       	push   $0x90
f010578e:	68 45 7d 10 f0       	push   $0xf0107d45
f0105793:	e8 a8 a8 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105798:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f010579e:	83 ec 04             	sub    $0x4,%esp
f01057a1:	6a 04                	push   $0x4
f01057a3:	68 5a 7d 10 f0       	push   $0xf0107d5a
f01057a8:	53                   	push   %ebx
f01057a9:	e8 c2 fc ff ff       	call   f0105470 <memcmp>
f01057ae:	83 c4 10             	add    $0x10,%esp
f01057b1:	85 c0                	test   %eax,%eax
f01057b3:	74 15                	je     f01057ca <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f01057b5:	83 ec 0c             	sub    $0xc,%esp
f01057b8:	68 e8 7b 10 f0       	push   $0xf0107be8
f01057bd:	e8 8f e0 ff ff       	call   f0103851 <cprintf>
f01057c2:	83 c4 10             	add    $0x10,%esp
f01057c5:	e9 e1 01 00 00       	jmp    f01059ab <mp_init+0x2e7>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f01057ca:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f01057ce:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f01057d2:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f01057d5:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f01057da:	b8 00 00 00 00       	mov    $0x0,%eax
f01057df:	eb 0d                	jmp    f01057ee <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f01057e1:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f01057e8:	f0 
f01057e9:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01057eb:	83 c0 01             	add    $0x1,%eax
f01057ee:	39 c7                	cmp    %eax,%edi
f01057f0:	75 ef                	jne    f01057e1 <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f01057f2:	84 d2                	test   %dl,%dl
f01057f4:	74 15                	je     f010580b <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f01057f6:	83 ec 0c             	sub    $0xc,%esp
f01057f9:	68 1c 7c 10 f0       	push   $0xf0107c1c
f01057fe:	e8 4e e0 ff ff       	call   f0103851 <cprintf>
f0105803:	83 c4 10             	add    $0x10,%esp
f0105806:	e9 a0 01 00 00       	jmp    f01059ab <mp_init+0x2e7>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f010580b:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f010580f:	3c 04                	cmp    $0x4,%al
f0105811:	74 1d                	je     f0105830 <mp_init+0x16c>
f0105813:	3c 01                	cmp    $0x1,%al
f0105815:	74 19                	je     f0105830 <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0105817:	83 ec 08             	sub    $0x8,%esp
f010581a:	0f b6 c0             	movzbl %al,%eax
f010581d:	50                   	push   %eax
f010581e:	68 40 7c 10 f0       	push   $0xf0107c40
f0105823:	e8 29 e0 ff ff       	call   f0103851 <cprintf>
f0105828:	83 c4 10             	add    $0x10,%esp
f010582b:	e9 7b 01 00 00       	jmp    f01059ab <mp_init+0x2e7>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105830:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f0105834:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105838:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f010583d:	b8 00 00 00 00       	mov    $0x0,%eax
f0105842:	01 ce                	add    %ecx,%esi
f0105844:	eb 0d                	jmp    f0105853 <mp_init+0x18f>
		sum += ((uint8_t *)addr)[i];
f0105846:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f010584d:	f0 
f010584e:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105850:	83 c0 01             	add    $0x1,%eax
f0105853:	39 c7                	cmp    %eax,%edi
f0105855:	75 ef                	jne    f0105846 <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105857:	89 d0                	mov    %edx,%eax
f0105859:	02 43 2a             	add    0x2a(%ebx),%al
f010585c:	74 15                	je     f0105873 <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f010585e:	83 ec 0c             	sub    $0xc,%esp
f0105861:	68 60 7c 10 f0       	push   $0xf0107c60
f0105866:	e8 e6 df ff ff       	call   f0103851 <cprintf>
f010586b:	83 c4 10             	add    $0x10,%esp
f010586e:	e9 38 01 00 00       	jmp    f01059ab <mp_init+0x2e7>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f0105873:	85 db                	test   %ebx,%ebx
f0105875:	0f 84 30 01 00 00    	je     f01059ab <mp_init+0x2e7>
		return;
	ismp = 1;
f010587b:	c7 05 00 10 23 f0 01 	movl   $0x1,0xf0231000
f0105882:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0105885:	8b 43 24             	mov    0x24(%ebx),%eax
f0105888:	a3 00 20 27 f0       	mov    %eax,0xf0272000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f010588d:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f0105890:	be 00 00 00 00       	mov    $0x0,%esi
f0105895:	e9 85 00 00 00       	jmp    f010591f <mp_init+0x25b>
		switch (*p) {
f010589a:	0f b6 07             	movzbl (%edi),%eax
f010589d:	84 c0                	test   %al,%al
f010589f:	74 06                	je     f01058a7 <mp_init+0x1e3>
f01058a1:	3c 04                	cmp    $0x4,%al
f01058a3:	77 55                	ja     f01058fa <mp_init+0x236>
f01058a5:	eb 4e                	jmp    f01058f5 <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f01058a7:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f01058ab:	74 11                	je     f01058be <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f01058ad:	6b 05 e4 13 23 f0 74 	imul   $0x74,0xf02313e4,%eax
f01058b4:	05 40 10 23 f0       	add    $0xf0231040,%eax
f01058b9:	a3 e0 13 23 f0       	mov    %eax,0xf02313e0
			if (ncpu < NCPU) {
f01058be:	a1 e4 13 23 f0       	mov    0xf02313e4,%eax
f01058c3:	83 f8 07             	cmp    $0x7,%eax
f01058c6:	7f 13                	jg     f01058db <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f01058c8:	6b d0 74             	imul   $0x74,%eax,%edx
f01058cb:	88 82 40 10 23 f0    	mov    %al,-0xfdcefc0(%edx)
				ncpu++;
f01058d1:	83 c0 01             	add    $0x1,%eax
f01058d4:	a3 e4 13 23 f0       	mov    %eax,0xf02313e4
f01058d9:	eb 15                	jmp    f01058f0 <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f01058db:	83 ec 08             	sub    $0x8,%esp
f01058de:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f01058e2:	50                   	push   %eax
f01058e3:	68 90 7c 10 f0       	push   $0xf0107c90
f01058e8:	e8 64 df ff ff       	call   f0103851 <cprintf>
f01058ed:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f01058f0:	83 c7 14             	add    $0x14,%edi
			continue;
f01058f3:	eb 27                	jmp    f010591c <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f01058f5:	83 c7 08             	add    $0x8,%edi
			continue;
f01058f8:	eb 22                	jmp    f010591c <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f01058fa:	83 ec 08             	sub    $0x8,%esp
f01058fd:	0f b6 c0             	movzbl %al,%eax
f0105900:	50                   	push   %eax
f0105901:	68 b8 7c 10 f0       	push   $0xf0107cb8
f0105906:	e8 46 df ff ff       	call   f0103851 <cprintf>
			ismp = 0;
f010590b:	c7 05 00 10 23 f0 00 	movl   $0x0,0xf0231000
f0105912:	00 00 00 
			i = conf->entry;
f0105915:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f0105919:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f010591c:	83 c6 01             	add    $0x1,%esi
f010591f:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f0105923:	39 c6                	cmp    %eax,%esi
f0105925:	0f 82 6f ff ff ff    	jb     f010589a <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f010592b:	a1 e0 13 23 f0       	mov    0xf02313e0,%eax
f0105930:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f0105937:	83 3d 00 10 23 f0 00 	cmpl   $0x0,0xf0231000
f010593e:	75 26                	jne    f0105966 <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0105940:	c7 05 e4 13 23 f0 01 	movl   $0x1,0xf02313e4
f0105947:	00 00 00 
		lapicaddr = 0;
f010594a:	c7 05 00 20 27 f0 00 	movl   $0x0,0xf0272000
f0105951:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0105954:	83 ec 0c             	sub    $0xc,%esp
f0105957:	68 d8 7c 10 f0       	push   $0xf0107cd8
f010595c:	e8 f0 de ff ff       	call   f0103851 <cprintf>
		return;
f0105961:	83 c4 10             	add    $0x10,%esp
f0105964:	eb 45                	jmp    f01059ab <mp_init+0x2e7>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0105966:	83 ec 04             	sub    $0x4,%esp
f0105969:	ff 35 e4 13 23 f0    	pushl  0xf02313e4
f010596f:	0f b6 00             	movzbl (%eax),%eax
f0105972:	50                   	push   %eax
f0105973:	68 5f 7d 10 f0       	push   $0xf0107d5f
f0105978:	e8 d4 de ff ff       	call   f0103851 <cprintf>

	if (mp->imcrp) {
f010597d:	83 c4 10             	add    $0x10,%esp
f0105980:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105983:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0105987:	74 22                	je     f01059ab <mp_init+0x2e7>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0105989:	83 ec 0c             	sub    $0xc,%esp
f010598c:	68 04 7d 10 f0       	push   $0xf0107d04
f0105991:	e8 bb de ff ff       	call   f0103851 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105996:	ba 22 00 00 00       	mov    $0x22,%edx
f010599b:	b8 70 00 00 00       	mov    $0x70,%eax
f01059a0:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01059a1:	b2 23                	mov    $0x23,%dl
f01059a3:	ec                   	in     (%dx),%al
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f01059a4:	83 c8 01             	or     $0x1,%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01059a7:	ee                   	out    %al,(%dx)
f01059a8:	83 c4 10             	add    $0x10,%esp
	}
}
f01059ab:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01059ae:	5b                   	pop    %ebx
f01059af:	5e                   	pop    %esi
f01059b0:	5f                   	pop    %edi
f01059b1:	5d                   	pop    %ebp
f01059b2:	c3                   	ret    

f01059b3 <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f01059b3:	55                   	push   %ebp
f01059b4:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f01059b6:	8b 0d 04 20 27 f0    	mov    0xf0272004,%ecx
f01059bc:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f01059bf:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f01059c1:	a1 04 20 27 f0       	mov    0xf0272004,%eax
f01059c6:	8b 40 20             	mov    0x20(%eax),%eax
}
f01059c9:	5d                   	pop    %ebp
f01059ca:	c3                   	ret    

f01059cb <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f01059cb:	55                   	push   %ebp
f01059cc:	89 e5                	mov    %esp,%ebp
	if (lapic)
f01059ce:	a1 04 20 27 f0       	mov    0xf0272004,%eax
f01059d3:	85 c0                	test   %eax,%eax
f01059d5:	74 08                	je     f01059df <cpunum+0x14>
		return lapic[ID] >> 24;
f01059d7:	8b 40 20             	mov    0x20(%eax),%eax
f01059da:	c1 e8 18             	shr    $0x18,%eax
f01059dd:	eb 05                	jmp    f01059e4 <cpunum+0x19>
	return 0;
f01059df:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01059e4:	5d                   	pop    %ebp
f01059e5:	c3                   	ret    

f01059e6 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f01059e6:	a1 00 20 27 f0       	mov    0xf0272000,%eax
f01059eb:	85 c0                	test   %eax,%eax
f01059ed:	0f 84 21 01 00 00    	je     f0105b14 <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f01059f3:	55                   	push   %ebp
f01059f4:	89 e5                	mov    %esp,%ebp
f01059f6:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f01059f9:	68 00 10 00 00       	push   $0x1000
f01059fe:	50                   	push   %eax
f01059ff:	e8 74 b9 ff ff       	call   f0101378 <mmio_map_region>
f0105a04:	a3 04 20 27 f0       	mov    %eax,0xf0272004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105a09:	ba 27 01 00 00       	mov    $0x127,%edx
f0105a0e:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0105a13:	e8 9b ff ff ff       	call   f01059b3 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0105a18:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105a1d:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0105a22:	e8 8c ff ff ff       	call   f01059b3 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0105a27:	ba 20 00 02 00       	mov    $0x20020,%edx
f0105a2c:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0105a31:	e8 7d ff ff ff       	call   f01059b3 <lapicw>
	lapicw(TICR, 10000000); 
f0105a36:	ba 80 96 98 00       	mov    $0x989680,%edx
f0105a3b:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0105a40:	e8 6e ff ff ff       	call   f01059b3 <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0105a45:	e8 81 ff ff ff       	call   f01059cb <cpunum>
f0105a4a:	6b c0 74             	imul   $0x74,%eax,%eax
f0105a4d:	05 40 10 23 f0       	add    $0xf0231040,%eax
f0105a52:	83 c4 10             	add    $0x10,%esp
f0105a55:	39 05 e0 13 23 f0    	cmp    %eax,0xf02313e0
f0105a5b:	74 0f                	je     f0105a6c <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f0105a5d:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105a62:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0105a67:	e8 47 ff ff ff       	call   f01059b3 <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f0105a6c:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105a71:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0105a76:	e8 38 ff ff ff       	call   f01059b3 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0105a7b:	a1 04 20 27 f0       	mov    0xf0272004,%eax
f0105a80:	8b 40 30             	mov    0x30(%eax),%eax
f0105a83:	c1 e8 10             	shr    $0x10,%eax
f0105a86:	3c 03                	cmp    $0x3,%al
f0105a88:	76 0f                	jbe    f0105a99 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f0105a8a:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105a8f:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0105a94:	e8 1a ff ff ff       	call   f01059b3 <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0105a99:	ba 33 00 00 00       	mov    $0x33,%edx
f0105a9e:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0105aa3:	e8 0b ff ff ff       	call   f01059b3 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f0105aa8:	ba 00 00 00 00       	mov    $0x0,%edx
f0105aad:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105ab2:	e8 fc fe ff ff       	call   f01059b3 <lapicw>
	lapicw(ESR, 0);
f0105ab7:	ba 00 00 00 00       	mov    $0x0,%edx
f0105abc:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105ac1:	e8 ed fe ff ff       	call   f01059b3 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0105ac6:	ba 00 00 00 00       	mov    $0x0,%edx
f0105acb:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105ad0:	e8 de fe ff ff       	call   f01059b3 <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105ad5:	ba 00 00 00 00       	mov    $0x0,%edx
f0105ada:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105adf:	e8 cf fe ff ff       	call   f01059b3 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105ae4:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105ae9:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105aee:	e8 c0 fe ff ff       	call   f01059b3 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0105af3:	8b 15 04 20 27 f0    	mov    0xf0272004,%edx
f0105af9:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105aff:	f6 c4 10             	test   $0x10,%ah
f0105b02:	75 f5                	jne    f0105af9 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0105b04:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b09:	b8 20 00 00 00       	mov    $0x20,%eax
f0105b0e:	e8 a0 fe ff ff       	call   f01059b3 <lapicw>
}
f0105b13:	c9                   	leave  
f0105b14:	f3 c3                	repz ret 

f0105b16 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105b16:	83 3d 04 20 27 f0 00 	cmpl   $0x0,0xf0272004
f0105b1d:	74 13                	je     f0105b32 <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f0105b1f:	55                   	push   %ebp
f0105b20:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0105b22:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b27:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105b2c:	e8 82 fe ff ff       	call   f01059b3 <lapicw>
}
f0105b31:	5d                   	pop    %ebp
f0105b32:	f3 c3                	repz ret 

f0105b34 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0105b34:	55                   	push   %ebp
f0105b35:	89 e5                	mov    %esp,%ebp
f0105b37:	56                   	push   %esi
f0105b38:	53                   	push   %ebx
f0105b39:	8b 75 08             	mov    0x8(%ebp),%esi
f0105b3c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105b3f:	ba 70 00 00 00       	mov    $0x70,%edx
f0105b44:	b8 0f 00 00 00       	mov    $0xf,%eax
f0105b49:	ee                   	out    %al,(%dx)
f0105b4a:	b2 71                	mov    $0x71,%dl
f0105b4c:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105b51:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105b52:	83 3d c8 0e 23 f0 00 	cmpl   $0x0,0xf0230ec8
f0105b59:	75 19                	jne    f0105b74 <lapic_startap+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105b5b:	68 67 04 00 00       	push   $0x467
f0105b60:	68 a4 60 10 f0       	push   $0xf01060a4
f0105b65:	68 98 00 00 00       	push   $0x98
f0105b6a:	68 7c 7d 10 f0       	push   $0xf0107d7c
f0105b6f:	e8 cc a4 ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0105b74:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0105b7b:	00 00 
	wrv[1] = addr >> 4;
f0105b7d:	89 d8                	mov    %ebx,%eax
f0105b7f:	c1 e8 04             	shr    $0x4,%eax
f0105b82:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0105b88:	c1 e6 18             	shl    $0x18,%esi
f0105b8b:	89 f2                	mov    %esi,%edx
f0105b8d:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105b92:	e8 1c fe ff ff       	call   f01059b3 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0105b97:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0105b9c:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105ba1:	e8 0d fe ff ff       	call   f01059b3 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0105ba6:	ba 00 85 00 00       	mov    $0x8500,%edx
f0105bab:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105bb0:	e8 fe fd ff ff       	call   f01059b3 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105bb5:	c1 eb 0c             	shr    $0xc,%ebx
f0105bb8:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105bbb:	89 f2                	mov    %esi,%edx
f0105bbd:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105bc2:	e8 ec fd ff ff       	call   f01059b3 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105bc7:	89 da                	mov    %ebx,%edx
f0105bc9:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105bce:	e8 e0 fd ff ff       	call   f01059b3 <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105bd3:	89 f2                	mov    %esi,%edx
f0105bd5:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105bda:	e8 d4 fd ff ff       	call   f01059b3 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105bdf:	89 da                	mov    %ebx,%edx
f0105be1:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105be6:	e8 c8 fd ff ff       	call   f01059b3 <lapicw>
		microdelay(200);
	}
}
f0105beb:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105bee:	5b                   	pop    %ebx
f0105bef:	5e                   	pop    %esi
f0105bf0:	5d                   	pop    %ebp
f0105bf1:	c3                   	ret    

f0105bf2 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105bf2:	55                   	push   %ebp
f0105bf3:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105bf5:	8b 55 08             	mov    0x8(%ebp),%edx
f0105bf8:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0105bfe:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c03:	e8 ab fd ff ff       	call   f01059b3 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0105c08:	8b 15 04 20 27 f0    	mov    0xf0272004,%edx
f0105c0e:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105c14:	f6 c4 10             	test   $0x10,%ah
f0105c17:	75 f5                	jne    f0105c0e <lapic_ipi+0x1c>
		;
}
f0105c19:	5d                   	pop    %ebp
f0105c1a:	c3                   	ret    

f0105c1b <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0105c1b:	55                   	push   %ebp
f0105c1c:	89 e5                	mov    %esp,%ebp
f0105c1e:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0105c21:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105c27:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105c2a:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f0105c2d:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0105c34:	5d                   	pop    %ebp
f0105c35:	c3                   	ret    

f0105c36 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0105c36:	55                   	push   %ebp
f0105c37:	89 e5                	mov    %esp,%ebp
f0105c39:	56                   	push   %esi
f0105c3a:	53                   	push   %ebx
f0105c3b:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105c3e:	83 3b 00             	cmpl   $0x0,(%ebx)
f0105c41:	74 14                	je     f0105c57 <spin_lock+0x21>
f0105c43:	8b 73 08             	mov    0x8(%ebx),%esi
f0105c46:	e8 80 fd ff ff       	call   f01059cb <cpunum>
f0105c4b:	6b c0 74             	imul   $0x74,%eax,%eax
f0105c4e:	05 40 10 23 f0       	add    $0xf0231040,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0105c53:	39 c6                	cmp    %eax,%esi
f0105c55:	74 07                	je     f0105c5e <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0105c57:	ba 01 00 00 00       	mov    $0x1,%edx
f0105c5c:	eb 20                	jmp    f0105c7e <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0105c5e:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0105c61:	e8 65 fd ff ff       	call   f01059cb <cpunum>
f0105c66:	83 ec 0c             	sub    $0xc,%esp
f0105c69:	53                   	push   %ebx
f0105c6a:	50                   	push   %eax
f0105c6b:	68 8c 7d 10 f0       	push   $0xf0107d8c
f0105c70:	6a 41                	push   $0x41
f0105c72:	68 f0 7d 10 f0       	push   $0xf0107df0
f0105c77:	e8 c4 a3 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0105c7c:	f3 90                	pause  
f0105c7e:	89 d0                	mov    %edx,%eax
f0105c80:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0105c83:	85 c0                	test   %eax,%eax
f0105c85:	75 f5                	jne    f0105c7c <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0105c87:	e8 3f fd ff ff       	call   f01059cb <cpunum>
f0105c8c:	6b c0 74             	imul   $0x74,%eax,%eax
f0105c8f:	05 40 10 23 f0       	add    $0xf0231040,%eax
f0105c94:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0105c97:	83 c3 0c             	add    $0xc,%ebx
get_caller_pcs(uint32_t pcs[])
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
f0105c9a:	89 ea                	mov    %ebp,%edx
	for (i = 0; i < 10; i++){
f0105c9c:	b8 00 00 00 00       	mov    $0x0,%eax
f0105ca1:	eb 0b                	jmp    f0105cae <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f0105ca3:	8b 4a 04             	mov    0x4(%edx),%ecx
f0105ca6:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0105ca9:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105cab:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105cae:	83 f8 09             	cmp    $0x9,%eax
f0105cb1:	7f 14                	jg     f0105cc7 <spin_lock+0x91>
f0105cb3:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0105cb9:	77 e8                	ja     f0105ca3 <spin_lock+0x6d>
f0105cbb:	eb 0a                	jmp    f0105cc7 <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0105cbd:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0105cc4:	83 c0 01             	add    $0x1,%eax
f0105cc7:	83 f8 09             	cmp    $0x9,%eax
f0105cca:	7e f1                	jle    f0105cbd <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f0105ccc:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105ccf:	5b                   	pop    %ebx
f0105cd0:	5e                   	pop    %esi
f0105cd1:	5d                   	pop    %ebp
f0105cd2:	c3                   	ret    

f0105cd3 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105cd3:	55                   	push   %ebp
f0105cd4:	89 e5                	mov    %esp,%ebp
f0105cd6:	57                   	push   %edi
f0105cd7:	56                   	push   %esi
f0105cd8:	53                   	push   %ebx
f0105cd9:	83 ec 4c             	sub    $0x4c,%esp
f0105cdc:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105cdf:	83 3e 00             	cmpl   $0x0,(%esi)
f0105ce2:	74 18                	je     f0105cfc <spin_unlock+0x29>
f0105ce4:	8b 5e 08             	mov    0x8(%esi),%ebx
f0105ce7:	e8 df fc ff ff       	call   f01059cb <cpunum>
f0105cec:	6b c0 74             	imul   $0x74,%eax,%eax
f0105cef:	05 40 10 23 f0       	add    $0xf0231040,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0105cf4:	39 c3                	cmp    %eax,%ebx
f0105cf6:	0f 84 a5 00 00 00    	je     f0105da1 <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0105cfc:	83 ec 04             	sub    $0x4,%esp
f0105cff:	6a 28                	push   $0x28
f0105d01:	8d 46 0c             	lea    0xc(%esi),%eax
f0105d04:	50                   	push   %eax
f0105d05:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0105d08:	53                   	push   %ebx
f0105d09:	e8 e7 f6 ff ff       	call   f01053f5 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105d0e:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105d11:	0f b6 38             	movzbl (%eax),%edi
f0105d14:	8b 76 04             	mov    0x4(%esi),%esi
f0105d17:	e8 af fc ff ff       	call   f01059cb <cpunum>
f0105d1c:	57                   	push   %edi
f0105d1d:	56                   	push   %esi
f0105d1e:	50                   	push   %eax
f0105d1f:	68 b8 7d 10 f0       	push   $0xf0107db8
f0105d24:	e8 28 db ff ff       	call   f0103851 <cprintf>
f0105d29:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0105d2c:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0105d2f:	eb 54                	jmp    f0105d85 <spin_unlock+0xb2>
f0105d31:	83 ec 08             	sub    $0x8,%esp
f0105d34:	57                   	push   %edi
f0105d35:	50                   	push   %eax
f0105d36:	e8 ef eb ff ff       	call   f010492a <debuginfo_eip>
f0105d3b:	83 c4 10             	add    $0x10,%esp
f0105d3e:	85 c0                	test   %eax,%eax
f0105d40:	78 27                	js     f0105d69 <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0105d42:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0105d44:	83 ec 04             	sub    $0x4,%esp
f0105d47:	89 c2                	mov    %eax,%edx
f0105d49:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0105d4c:	52                   	push   %edx
f0105d4d:	ff 75 b0             	pushl  -0x50(%ebp)
f0105d50:	ff 75 b4             	pushl  -0x4c(%ebp)
f0105d53:	ff 75 ac             	pushl  -0x54(%ebp)
f0105d56:	ff 75 a8             	pushl  -0x58(%ebp)
f0105d59:	50                   	push   %eax
f0105d5a:	68 00 7e 10 f0       	push   $0xf0107e00
f0105d5f:	e8 ed da ff ff       	call   f0103851 <cprintf>
f0105d64:	83 c4 20             	add    $0x20,%esp
f0105d67:	eb 12                	jmp    f0105d7b <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f0105d69:	83 ec 08             	sub    $0x8,%esp
f0105d6c:	ff 36                	pushl  (%esi)
f0105d6e:	68 17 7e 10 f0       	push   $0xf0107e17
f0105d73:	e8 d9 da ff ff       	call   f0103851 <cprintf>
f0105d78:	83 c4 10             	add    $0x10,%esp
f0105d7b:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0105d7e:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0105d81:	39 c3                	cmp    %eax,%ebx
f0105d83:	74 08                	je     f0105d8d <spin_unlock+0xba>
f0105d85:	89 de                	mov    %ebx,%esi
f0105d87:	8b 03                	mov    (%ebx),%eax
f0105d89:	85 c0                	test   %eax,%eax
f0105d8b:	75 a4                	jne    f0105d31 <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f0105d8d:	83 ec 04             	sub    $0x4,%esp
f0105d90:	68 1f 7e 10 f0       	push   $0xf0107e1f
f0105d95:	6a 67                	push   $0x67
f0105d97:	68 f0 7d 10 f0       	push   $0xf0107df0
f0105d9c:	e8 9f a2 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f0105da1:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0105da8:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
f0105daf:	b8 00 00 00 00       	mov    $0x0,%eax
f0105db4:	f0 87 06             	lock xchg %eax,(%esi)
	// Paper says that Intel 64 and IA-32 will not move a load
	// after a store. So lock->locked = 0 would work here.
	// The xchg being asm volatile ensures gcc emits it after
	// the above assignments (and after the critical section).
	xchg(&lk->locked, 0);
}
f0105db7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105dba:	5b                   	pop    %ebx
f0105dbb:	5e                   	pop    %esi
f0105dbc:	5f                   	pop    %edi
f0105dbd:	5d                   	pop    %ebp
f0105dbe:	c3                   	ret    
f0105dbf:	90                   	nop

f0105dc0 <__udivdi3>:
f0105dc0:	55                   	push   %ebp
f0105dc1:	57                   	push   %edi
f0105dc2:	56                   	push   %esi
f0105dc3:	83 ec 10             	sub    $0x10,%esp
f0105dc6:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f0105dca:	8b 7c 24 20          	mov    0x20(%esp),%edi
f0105dce:	8b 74 24 24          	mov    0x24(%esp),%esi
f0105dd2:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0105dd6:	85 d2                	test   %edx,%edx
f0105dd8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105ddc:	89 34 24             	mov    %esi,(%esp)
f0105ddf:	89 c8                	mov    %ecx,%eax
f0105de1:	75 35                	jne    f0105e18 <__udivdi3+0x58>
f0105de3:	39 f1                	cmp    %esi,%ecx
f0105de5:	0f 87 bd 00 00 00    	ja     f0105ea8 <__udivdi3+0xe8>
f0105deb:	85 c9                	test   %ecx,%ecx
f0105ded:	89 cd                	mov    %ecx,%ebp
f0105def:	75 0b                	jne    f0105dfc <__udivdi3+0x3c>
f0105df1:	b8 01 00 00 00       	mov    $0x1,%eax
f0105df6:	31 d2                	xor    %edx,%edx
f0105df8:	f7 f1                	div    %ecx
f0105dfa:	89 c5                	mov    %eax,%ebp
f0105dfc:	89 f0                	mov    %esi,%eax
f0105dfe:	31 d2                	xor    %edx,%edx
f0105e00:	f7 f5                	div    %ebp
f0105e02:	89 c6                	mov    %eax,%esi
f0105e04:	89 f8                	mov    %edi,%eax
f0105e06:	f7 f5                	div    %ebp
f0105e08:	89 f2                	mov    %esi,%edx
f0105e0a:	83 c4 10             	add    $0x10,%esp
f0105e0d:	5e                   	pop    %esi
f0105e0e:	5f                   	pop    %edi
f0105e0f:	5d                   	pop    %ebp
f0105e10:	c3                   	ret    
f0105e11:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105e18:	3b 14 24             	cmp    (%esp),%edx
f0105e1b:	77 7b                	ja     f0105e98 <__udivdi3+0xd8>
f0105e1d:	0f bd f2             	bsr    %edx,%esi
f0105e20:	83 f6 1f             	xor    $0x1f,%esi
f0105e23:	0f 84 97 00 00 00    	je     f0105ec0 <__udivdi3+0x100>
f0105e29:	bd 20 00 00 00       	mov    $0x20,%ebp
f0105e2e:	89 d7                	mov    %edx,%edi
f0105e30:	89 f1                	mov    %esi,%ecx
f0105e32:	29 f5                	sub    %esi,%ebp
f0105e34:	d3 e7                	shl    %cl,%edi
f0105e36:	89 c2                	mov    %eax,%edx
f0105e38:	89 e9                	mov    %ebp,%ecx
f0105e3a:	d3 ea                	shr    %cl,%edx
f0105e3c:	89 f1                	mov    %esi,%ecx
f0105e3e:	09 fa                	or     %edi,%edx
f0105e40:	8b 3c 24             	mov    (%esp),%edi
f0105e43:	d3 e0                	shl    %cl,%eax
f0105e45:	89 54 24 08          	mov    %edx,0x8(%esp)
f0105e49:	89 e9                	mov    %ebp,%ecx
f0105e4b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105e4f:	8b 44 24 04          	mov    0x4(%esp),%eax
f0105e53:	89 fa                	mov    %edi,%edx
f0105e55:	d3 ea                	shr    %cl,%edx
f0105e57:	89 f1                	mov    %esi,%ecx
f0105e59:	d3 e7                	shl    %cl,%edi
f0105e5b:	89 e9                	mov    %ebp,%ecx
f0105e5d:	d3 e8                	shr    %cl,%eax
f0105e5f:	09 c7                	or     %eax,%edi
f0105e61:	89 f8                	mov    %edi,%eax
f0105e63:	f7 74 24 08          	divl   0x8(%esp)
f0105e67:	89 d5                	mov    %edx,%ebp
f0105e69:	89 c7                	mov    %eax,%edi
f0105e6b:	f7 64 24 0c          	mull   0xc(%esp)
f0105e6f:	39 d5                	cmp    %edx,%ebp
f0105e71:	89 14 24             	mov    %edx,(%esp)
f0105e74:	72 11                	jb     f0105e87 <__udivdi3+0xc7>
f0105e76:	8b 54 24 04          	mov    0x4(%esp),%edx
f0105e7a:	89 f1                	mov    %esi,%ecx
f0105e7c:	d3 e2                	shl    %cl,%edx
f0105e7e:	39 c2                	cmp    %eax,%edx
f0105e80:	73 5e                	jae    f0105ee0 <__udivdi3+0x120>
f0105e82:	3b 2c 24             	cmp    (%esp),%ebp
f0105e85:	75 59                	jne    f0105ee0 <__udivdi3+0x120>
f0105e87:	8d 47 ff             	lea    -0x1(%edi),%eax
f0105e8a:	31 f6                	xor    %esi,%esi
f0105e8c:	89 f2                	mov    %esi,%edx
f0105e8e:	83 c4 10             	add    $0x10,%esp
f0105e91:	5e                   	pop    %esi
f0105e92:	5f                   	pop    %edi
f0105e93:	5d                   	pop    %ebp
f0105e94:	c3                   	ret    
f0105e95:	8d 76 00             	lea    0x0(%esi),%esi
f0105e98:	31 f6                	xor    %esi,%esi
f0105e9a:	31 c0                	xor    %eax,%eax
f0105e9c:	89 f2                	mov    %esi,%edx
f0105e9e:	83 c4 10             	add    $0x10,%esp
f0105ea1:	5e                   	pop    %esi
f0105ea2:	5f                   	pop    %edi
f0105ea3:	5d                   	pop    %ebp
f0105ea4:	c3                   	ret    
f0105ea5:	8d 76 00             	lea    0x0(%esi),%esi
f0105ea8:	89 f2                	mov    %esi,%edx
f0105eaa:	31 f6                	xor    %esi,%esi
f0105eac:	89 f8                	mov    %edi,%eax
f0105eae:	f7 f1                	div    %ecx
f0105eb0:	89 f2                	mov    %esi,%edx
f0105eb2:	83 c4 10             	add    $0x10,%esp
f0105eb5:	5e                   	pop    %esi
f0105eb6:	5f                   	pop    %edi
f0105eb7:	5d                   	pop    %ebp
f0105eb8:	c3                   	ret    
f0105eb9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105ec0:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f0105ec4:	76 0b                	jbe    f0105ed1 <__udivdi3+0x111>
f0105ec6:	31 c0                	xor    %eax,%eax
f0105ec8:	3b 14 24             	cmp    (%esp),%edx
f0105ecb:	0f 83 37 ff ff ff    	jae    f0105e08 <__udivdi3+0x48>
f0105ed1:	b8 01 00 00 00       	mov    $0x1,%eax
f0105ed6:	e9 2d ff ff ff       	jmp    f0105e08 <__udivdi3+0x48>
f0105edb:	90                   	nop
f0105edc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105ee0:	89 f8                	mov    %edi,%eax
f0105ee2:	31 f6                	xor    %esi,%esi
f0105ee4:	e9 1f ff ff ff       	jmp    f0105e08 <__udivdi3+0x48>
f0105ee9:	66 90                	xchg   %ax,%ax
f0105eeb:	66 90                	xchg   %ax,%ax
f0105eed:	66 90                	xchg   %ax,%ax
f0105eef:	90                   	nop

f0105ef0 <__umoddi3>:
f0105ef0:	55                   	push   %ebp
f0105ef1:	57                   	push   %edi
f0105ef2:	56                   	push   %esi
f0105ef3:	83 ec 20             	sub    $0x20,%esp
f0105ef6:	8b 44 24 34          	mov    0x34(%esp),%eax
f0105efa:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0105efe:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105f02:	89 c6                	mov    %eax,%esi
f0105f04:	89 44 24 10          	mov    %eax,0x10(%esp)
f0105f08:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0105f0c:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0105f10:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0105f14:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0105f18:	89 74 24 18          	mov    %esi,0x18(%esp)
f0105f1c:	85 c0                	test   %eax,%eax
f0105f1e:	89 c2                	mov    %eax,%edx
f0105f20:	75 1e                	jne    f0105f40 <__umoddi3+0x50>
f0105f22:	39 f7                	cmp    %esi,%edi
f0105f24:	76 52                	jbe    f0105f78 <__umoddi3+0x88>
f0105f26:	89 c8                	mov    %ecx,%eax
f0105f28:	89 f2                	mov    %esi,%edx
f0105f2a:	f7 f7                	div    %edi
f0105f2c:	89 d0                	mov    %edx,%eax
f0105f2e:	31 d2                	xor    %edx,%edx
f0105f30:	83 c4 20             	add    $0x20,%esp
f0105f33:	5e                   	pop    %esi
f0105f34:	5f                   	pop    %edi
f0105f35:	5d                   	pop    %ebp
f0105f36:	c3                   	ret    
f0105f37:	89 f6                	mov    %esi,%esi
f0105f39:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0105f40:	39 f0                	cmp    %esi,%eax
f0105f42:	77 5c                	ja     f0105fa0 <__umoddi3+0xb0>
f0105f44:	0f bd e8             	bsr    %eax,%ebp
f0105f47:	83 f5 1f             	xor    $0x1f,%ebp
f0105f4a:	75 64                	jne    f0105fb0 <__umoddi3+0xc0>
f0105f4c:	8b 6c 24 14          	mov    0x14(%esp),%ebp
f0105f50:	39 6c 24 0c          	cmp    %ebp,0xc(%esp)
f0105f54:	0f 86 f6 00 00 00    	jbe    f0106050 <__umoddi3+0x160>
f0105f5a:	3b 44 24 18          	cmp    0x18(%esp),%eax
f0105f5e:	0f 82 ec 00 00 00    	jb     f0106050 <__umoddi3+0x160>
f0105f64:	8b 44 24 14          	mov    0x14(%esp),%eax
f0105f68:	8b 54 24 18          	mov    0x18(%esp),%edx
f0105f6c:	83 c4 20             	add    $0x20,%esp
f0105f6f:	5e                   	pop    %esi
f0105f70:	5f                   	pop    %edi
f0105f71:	5d                   	pop    %ebp
f0105f72:	c3                   	ret    
f0105f73:	90                   	nop
f0105f74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105f78:	85 ff                	test   %edi,%edi
f0105f7a:	89 fd                	mov    %edi,%ebp
f0105f7c:	75 0b                	jne    f0105f89 <__umoddi3+0x99>
f0105f7e:	b8 01 00 00 00       	mov    $0x1,%eax
f0105f83:	31 d2                	xor    %edx,%edx
f0105f85:	f7 f7                	div    %edi
f0105f87:	89 c5                	mov    %eax,%ebp
f0105f89:	8b 44 24 10          	mov    0x10(%esp),%eax
f0105f8d:	31 d2                	xor    %edx,%edx
f0105f8f:	f7 f5                	div    %ebp
f0105f91:	89 c8                	mov    %ecx,%eax
f0105f93:	f7 f5                	div    %ebp
f0105f95:	eb 95                	jmp    f0105f2c <__umoddi3+0x3c>
f0105f97:	89 f6                	mov    %esi,%esi
f0105f99:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0105fa0:	89 c8                	mov    %ecx,%eax
f0105fa2:	89 f2                	mov    %esi,%edx
f0105fa4:	83 c4 20             	add    $0x20,%esp
f0105fa7:	5e                   	pop    %esi
f0105fa8:	5f                   	pop    %edi
f0105fa9:	5d                   	pop    %ebp
f0105faa:	c3                   	ret    
f0105fab:	90                   	nop
f0105fac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105fb0:	b8 20 00 00 00       	mov    $0x20,%eax
f0105fb5:	89 e9                	mov    %ebp,%ecx
f0105fb7:	29 e8                	sub    %ebp,%eax
f0105fb9:	d3 e2                	shl    %cl,%edx
f0105fbb:	89 c7                	mov    %eax,%edi
f0105fbd:	89 44 24 18          	mov    %eax,0x18(%esp)
f0105fc1:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0105fc5:	89 f9                	mov    %edi,%ecx
f0105fc7:	d3 e8                	shr    %cl,%eax
f0105fc9:	89 c1                	mov    %eax,%ecx
f0105fcb:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0105fcf:	09 d1                	or     %edx,%ecx
f0105fd1:	89 fa                	mov    %edi,%edx
f0105fd3:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0105fd7:	89 e9                	mov    %ebp,%ecx
f0105fd9:	d3 e0                	shl    %cl,%eax
f0105fdb:	89 f9                	mov    %edi,%ecx
f0105fdd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105fe1:	89 f0                	mov    %esi,%eax
f0105fe3:	d3 e8                	shr    %cl,%eax
f0105fe5:	89 e9                	mov    %ebp,%ecx
f0105fe7:	89 c7                	mov    %eax,%edi
f0105fe9:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0105fed:	d3 e6                	shl    %cl,%esi
f0105fef:	89 d1                	mov    %edx,%ecx
f0105ff1:	89 fa                	mov    %edi,%edx
f0105ff3:	d3 e8                	shr    %cl,%eax
f0105ff5:	89 e9                	mov    %ebp,%ecx
f0105ff7:	09 f0                	or     %esi,%eax
f0105ff9:	8b 74 24 1c          	mov    0x1c(%esp),%esi
f0105ffd:	f7 74 24 10          	divl   0x10(%esp)
f0106001:	d3 e6                	shl    %cl,%esi
f0106003:	89 d1                	mov    %edx,%ecx
f0106005:	f7 64 24 0c          	mull   0xc(%esp)
f0106009:	39 d1                	cmp    %edx,%ecx
f010600b:	89 74 24 14          	mov    %esi,0x14(%esp)
f010600f:	89 d7                	mov    %edx,%edi
f0106011:	89 c6                	mov    %eax,%esi
f0106013:	72 0a                	jb     f010601f <__umoddi3+0x12f>
f0106015:	39 44 24 14          	cmp    %eax,0x14(%esp)
f0106019:	73 10                	jae    f010602b <__umoddi3+0x13b>
f010601b:	39 d1                	cmp    %edx,%ecx
f010601d:	75 0c                	jne    f010602b <__umoddi3+0x13b>
f010601f:	89 d7                	mov    %edx,%edi
f0106021:	89 c6                	mov    %eax,%esi
f0106023:	2b 74 24 0c          	sub    0xc(%esp),%esi
f0106027:	1b 7c 24 10          	sbb    0x10(%esp),%edi
f010602b:	89 ca                	mov    %ecx,%edx
f010602d:	89 e9                	mov    %ebp,%ecx
f010602f:	8b 44 24 14          	mov    0x14(%esp),%eax
f0106033:	29 f0                	sub    %esi,%eax
f0106035:	19 fa                	sbb    %edi,%edx
f0106037:	d3 e8                	shr    %cl,%eax
f0106039:	0f b6 4c 24 18       	movzbl 0x18(%esp),%ecx
f010603e:	89 d7                	mov    %edx,%edi
f0106040:	d3 e7                	shl    %cl,%edi
f0106042:	89 e9                	mov    %ebp,%ecx
f0106044:	09 f8                	or     %edi,%eax
f0106046:	d3 ea                	shr    %cl,%edx
f0106048:	83 c4 20             	add    $0x20,%esp
f010604b:	5e                   	pop    %esi
f010604c:	5f                   	pop    %edi
f010604d:	5d                   	pop    %ebp
f010604e:	c3                   	ret    
f010604f:	90                   	nop
f0106050:	8b 74 24 10          	mov    0x10(%esp),%esi
f0106054:	29 f9                	sub    %edi,%ecx
f0106056:	19 c6                	sbb    %eax,%esi
f0106058:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f010605c:	89 74 24 18          	mov    %esi,0x18(%esp)
f0106060:	e9 ff fe ff ff       	jmp    f0105f64 <__umoddi3+0x74>
