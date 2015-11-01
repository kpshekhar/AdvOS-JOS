
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
f010005c:	e8 76 59 00 00       	call   f01059d7 <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 80 60 10 f0       	push   $0xf0106080
f010006d:	e8 e8 37 00 00       	call   f010385a <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 b8 37 00 00       	call   f0103834 <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 12 79 10 f0 	movl   $0xf0107912,(%esp)
f0100083:	e8 d2 37 00 00       	call   f010385a <cprintf>
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
f01000b3:	e8 fa 52 00 00       	call   f01053b2 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 72 05 00 00       	call   f010062f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 ec 60 10 f0       	push   $0xf01060ec
f01000ca:	e8 8b 37 00 00       	call   f010385a <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 ec 12 00 00       	call   f01013c0 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 bb 2f 00 00       	call   f0103094 <env_init>
	trap_init();
f01000d9:	e8 25 38 00 00       	call   f0103903 <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 ed 55 00 00       	call   f01056d0 <mp_init>
	lapic_init();
f01000e3:	e8 0a 59 00 00       	call   f01059f2 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 a9 36 00 00       	call   f0103796 <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000ed:	c7 04 24 c0 04 12 f0 	movl   $0xf01204c0,(%esp)
f01000f4:	e8 49 5b 00 00       	call   f0105c42 <spin_lock>
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
f010011e:	b8 36 56 10 f0       	mov    $0xf0105636,%eax
f0100123:	2d bc 55 10 f0       	sub    $0xf01055bc,%eax
f0100128:	50                   	push   %eax
f0100129:	68 bc 55 10 f0       	push   $0xf01055bc
f010012e:	68 00 70 00 f0       	push   $0xf0007000
f0100133:	e8 c7 52 00 00       	call   f01053ff <memmove>
f0100138:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010013b:	bb 40 10 23 f0       	mov    $0xf0231040,%ebx
f0100140:	eb 4e                	jmp    f0100190 <i386_init+0xf6>
		if (c == cpus + cpunum())  // We've started already.
f0100142:	e8 90 58 00 00       	call   f01059d7 <cpunum>
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
f010017d:	e8 be 59 00 00       	call   f0105b40 <lapic_startap>
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
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	//ENV_CREATE(user_primes, ENV_TYPE_USER);
	ENV_CREATE(user_sendpage, ENV_TYPE_USER);
f01001a0:	83 ec 08             	sub    $0x8,%esp
f01001a3:	6a 00                	push   $0x0
f01001a5:	68 1c 72 1f f0       	push   $0xf01f721c
f01001aa:	e8 bf 30 00 00       	call   f010326e <env_create>

	//ENV_CREATE(user_yield, ENV_TYPE_USER);
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001af:	e8 38 40 00 00       	call   f01041ec <sched_yield>

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
f01001e0:	e8 f2 57 00 00       	call   f01059d7 <cpunum>
f01001e5:	83 ec 08             	sub    $0x8,%esp
f01001e8:	50                   	push   %eax
f01001e9:	68 13 61 10 f0       	push   $0xf0106113
f01001ee:	e8 67 36 00 00       	call   f010385a <cprintf>

	lapic_init();
f01001f3:	e8 fa 57 00 00       	call   f01059f2 <lapic_init>
	env_init_percpu();
f01001f8:	e8 6d 2e 00 00       	call   f010306a <env_init_percpu>
	trap_init_percpu();
f01001fd:	e8 6c 36 00 00       	call   f010386e <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100202:	e8 d0 57 00 00       	call   f01059d7 <cpunum>
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
f0100220:	e8 1d 5a 00 00       	call   f0105c42 <spin_lock>
	// to start running processes on this CPU.  But make sure that
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	lock_kernel();  //Acquire the lock
	sched_yield(); //Call the sched_yield() function to schedule and run different environments, Exercise 6
f0100225:	e8 c2 3f 00 00       	call   f01041ec <sched_yield>

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
f010023f:	e8 16 36 00 00       	call   f010385a <cprintf>
	vcprintf(fmt, ap);
f0100244:	83 c4 08             	add    $0x8,%esp
f0100247:	53                   	push   %ebx
f0100248:	ff 75 10             	pushl  0x10(%ebp)
f010024b:	e8 e4 35 00 00       	call   f0103834 <vcprintf>
	cprintf("\n");
f0100250:	c7 04 24 12 79 10 f0 	movl   $0xf0107912,(%esp)
f0100257:	e8 fe 35 00 00       	call   f010385a <cprintf>
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
f01003ab:	e8 aa 34 00 00       	call   f010385a <cprintf>
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
f0100553:	e8 a7 4e 00 00       	call   f01053ff <memmove>
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
f01006cb:	e8 51 30 00 00       	call   f0103721 <irq_setmask_8259A>
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
f0100735:	e8 20 31 00 00       	call   f010385a <cprintf>
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
f0100785:	e8 d0 30 00 00       	call   f010385a <cprintf>
f010078a:	83 c4 0c             	add    $0xc,%esp
f010078d:	68 84 64 10 f0       	push   $0xf0106484
f0100792:	68 ec 63 10 f0       	push   $0xf01063ec
f0100797:	68 e3 63 10 f0       	push   $0xf01063e3
f010079c:	e8 b9 30 00 00       	call   f010385a <cprintf>
f01007a1:	83 c4 0c             	add    $0xc,%esp
f01007a4:	68 f5 63 10 f0       	push   $0xf01063f5
f01007a9:	68 12 64 10 f0       	push   $0xf0106412
f01007ae:	68 e3 63 10 f0       	push   $0xf01063e3
f01007b3:	e8 a2 30 00 00       	call   f010385a <cprintf>
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
f01007ca:	e8 8b 30 00 00       	call   f010385a <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007cf:	83 c4 08             	add    $0x8,%esp
f01007d2:	68 0c 00 10 00       	push   $0x10000c
f01007d7:	68 ac 64 10 f0       	push   $0xf01064ac
f01007dc:	e8 79 30 00 00       	call   f010385a <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007e1:	83 c4 0c             	add    $0xc,%esp
f01007e4:	68 0c 00 10 00       	push   $0x10000c
f01007e9:	68 0c 00 10 f0       	push   $0xf010000c
f01007ee:	68 d4 64 10 f0       	push   $0xf01064d4
f01007f3:	e8 62 30 00 00       	call   f010385a <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007f8:	83 c4 0c             	add    $0xc,%esp
f01007fb:	68 75 60 10 00       	push   $0x106075
f0100800:	68 75 60 10 f0       	push   $0xf0106075
f0100805:	68 f8 64 10 f0       	push   $0xf01064f8
f010080a:	e8 4b 30 00 00       	call   f010385a <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010080f:	83 c4 0c             	add    $0xc,%esp
f0100812:	68 28 f0 22 00       	push   $0x22f028
f0100817:	68 28 f0 22 f0       	push   $0xf022f028
f010081c:	68 1c 65 10 f0       	push   $0xf010651c
f0100821:	e8 34 30 00 00       	call   f010385a <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100826:	83 c4 0c             	add    $0xc,%esp
f0100829:	68 08 20 27 00       	push   $0x272008
f010082e:	68 08 20 27 f0       	push   $0xf0272008
f0100833:	68 40 65 10 f0       	push   $0xf0106540
f0100838:	e8 1d 30 00 00       	call   f010385a <cprintf>
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
f0100863:	e8 f2 2f 00 00       	call   f010385a <cprintf>
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
f010087f:	e8 d6 2f 00 00       	call   f010385a <cprintf>
	
	
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
f0100894:	e8 9b 40 00 00       	call   f0104934 <debuginfo_eip>
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
f01008c3:	e8 92 2f 00 00       	call   f010385a <cprintf>
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
f01008ec:	e8 69 2f 00 00       	call   f010385a <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008f1:	c7 04 24 f8 65 10 f0 	movl   $0xf01065f8,(%esp)
f01008f8:	e8 5d 2f 00 00       	call   f010385a <cprintf>

	if (tf != NULL)
f01008fd:	83 c4 10             	add    $0x10,%esp
f0100900:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100904:	74 0e                	je     f0100914 <monitor+0x36>
		print_trapframe(tf);
f0100906:	83 ec 0c             	sub    $0xc,%esp
f0100909:	ff 75 08             	pushl  0x8(%ebp)
f010090c:	e8 65 31 00 00       	call   f0103a76 <print_trapframe>
f0100911:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100914:	83 ec 0c             	sub    $0xc,%esp
f0100917:	68 48 64 10 f0       	push   $0xf0106448
f010091c:	e8 3a 48 00 00       	call   f010515b <readline>
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
f0100955:	e8 1b 4a 00 00       	call   f0105375 <strchr>
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
f0100975:	e8 e0 2e 00 00       	call   f010385a <cprintf>
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
f010099e:	e8 d2 49 00 00       	call   f0105375 <strchr>
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
f01009d1:	e8 41 49 00 00       	call   f0105317 <strcmp>
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
f0100a12:	e8 43 2e 00 00       	call   f010385a <cprintf>
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
f0100b0f:	0f 85 b1 02 00 00    	jne    f0100dc6 <check_page_free_list+0x2c5>
f0100b15:	e9 be 02 00 00       	jmp    f0100dd8 <check_page_free_list+0x2d7>
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
f0100bd0:	e8 dd 47 00 00       	call   f01053b2 <memset>
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
f0100cff:	0f 86 ea 00 00 00    	jbe    f0100def <check_page_free_list+0x2ee>
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
f0100d2a:	0f 86 cf 00 00 00    	jbe    f0100dff <check_page_free_list+0x2fe>
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
f0100db5:	0f b6 45 c0          	movzbl -0x40(%ebp),%eax
f0100db9:	50                   	push   %eax
f0100dba:	68 08 67 10 f0       	push   $0xf0106708
f0100dbf:	e8 96 2a 00 00       	call   f010385a <cprintf>
f0100dc4:	eb 49                	jmp    f0100e0f <check_page_free_list+0x30e>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100dc6:	a1 64 02 23 f0       	mov    0xf0230264,%eax
f0100dcb:	85 c0                	test   %eax,%eax
f0100dcd:	0f 85 5e fd ff ff    	jne    f0100b31 <check_page_free_list+0x30>
f0100dd3:	e9 42 fd ff ff       	jmp    f0100b1a <check_page_free_list+0x19>
f0100dd8:	83 3d 64 02 23 f0 00 	cmpl   $0x0,0xf0230264
f0100ddf:	0f 84 35 fd ff ff    	je     f0100b1a <check_page_free_list+0x19>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100de5:	be 00 04 00 00       	mov    $0x400,%esi
f0100dea:	e9 90 fd ff ff       	jmp    f0100b7f <check_page_free_list+0x7e>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100def:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100df4:	0f 85 68 ff ff ff    	jne    f0100d62 <check_page_free_list+0x261>
f0100dfa:	e9 4a ff ff ff       	jmp    f0100d49 <check_page_free_list+0x248>
f0100dff:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e04:	0f 85 5e ff ff ff    	jne    f0100d68 <check_page_free_list+0x267>
f0100e0a:	e9 3a ff ff ff       	jmp    f0100d49 <check_page_free_list+0x248>
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
}
f0100e0f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e12:	5b                   	pop    %ebx
f0100e13:	5e                   	pop    %esi
f0100e14:	5f                   	pop    %edi
f0100e15:	5d                   	pop    %ebp
f0100e16:	c3                   	ret    

f0100e17 <page_init>:
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100e17:	b8 01 00 00 00       	mov    $0x1,%eax
f0100e1c:	eb 18                	jmp    f0100e36 <page_init+0x1f>
	{
	 pages[i].pp_ref = 1; //Used Pages
f0100e1e:	8b 15 d0 0e 23 f0    	mov    0xf0230ed0,%edx
f0100e24:	8d 14 c2             	lea    (%edx,%eax,8),%edx
f0100e27:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
	 pages[i].pp_link = 0; // No links to any pages
f0100e2d:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100e33:	83 c0 01             	add    $0x1,%eax
f0100e36:	3b 05 c8 0e 23 f0    	cmp    0xf0230ec8,%eax
f0100e3c:	72 e0                	jb     f0100e1e <page_init+0x7>
//


void
page_init(void)
{
f0100e3e:	55                   	push   %ebp
f0100e3f:	89 e5                	mov    %esp,%ebp
f0100e41:	57                   	push   %edi
f0100e42:	56                   	push   %esi
f0100e43:	53                   	push   %ebx
f0100e44:	83 ec 0c             	sub    $0xc,%esp
	//Modification for Lab 4, We have to skip the Page that MPENTRY_PADDR is at from the page_free_list
	//Hence we can divide it with PGSIZE and whatever is the value, just skip that page. 
	size_t mpentyPg = MPENTRY_PADDR/PGSIZE;

	// 2. The rest of base memory 
	page_free_list = 0 ;
f0100e47:	c7 05 64 02 23 f0 00 	movl   $0x0,0xf0230264
f0100e4e:	00 00 00 
	
	struct PageInfo *prev = 0;
	for (i = 1; i < npages_basemem; ++i) {
f0100e51:	be 00 00 00 00       	mov    $0x0,%esi
	size_t mpentyPg = MPENTRY_PADDR/PGSIZE;

	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	struct PageInfo *prev = 0;
f0100e56:	bf 00 00 00 00       	mov    $0x0,%edi
	for (i = 1; i < npages_basemem; ++i) {
f0100e5b:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100e60:	eb 71                	jmp    f0100ed3 <page_init+0xbc>
		if (i == mpentyPg) {
f0100e62:	83 fb 07             	cmp    $0x7,%ebx
f0100e65:	75 14                	jne    f0100e7b <page_init+0x64>
			cprintf("Skipped this page %d\n", i);
f0100e67:	83 ec 08             	sub    $0x8,%esp
f0100e6a:	6a 07                	push   $0x7
f0100e6c:	68 08 71 10 f0       	push   $0xf0107108
f0100e71:	e8 e4 29 00 00       	call   f010385a <cprintf>
			continue;	
f0100e76:	83 c4 10             	add    $0x10,%esp
f0100e79:	eb 52                	jmp    f0100ecd <page_init+0xb6>
f0100e7b:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
		}

		pages[i].pp_ref = 0;
f0100e82:	8b 15 d0 0e 23 f0    	mov    0xf0230ed0,%edx
f0100e88:	66 c7 44 02 04 00 00 	movw   $0x0,0x4(%edx,%eax,1)
		pages[i].pp_link = 0;
f0100e8f:	c7 04 da 00 00 00 00 	movl   $0x0,(%edx,%ebx,8)
		if (!page_free_list) {
f0100e96:	83 3d 64 02 23 f0 00 	cmpl   $0x0,0xf0230264
f0100e9d:	75 10                	jne    f0100eaf <page_init+0x98>
			page_free_list = &pages[i];
f0100e9f:	89 c2                	mov    %eax,%edx
f0100ea1:	03 15 d0 0e 23 f0    	add    0xf0230ed0,%edx
f0100ea7:	89 15 64 02 23 f0    	mov    %edx,0xf0230264
f0100ead:	eb 16                	jmp    f0100ec5 <page_init+0xae>
		} else {
			prev->pp_link = &pages[i];
f0100eaf:	89 c2                	mov    %eax,%edx
f0100eb1:	03 15 d0 0e 23 f0    	add    0xf0230ed0,%edx
f0100eb7:	89 17                	mov    %edx,(%edi)
			pages[i-1].pp_link = &pages[i];
f0100eb9:	8b 15 d0 0e 23 f0    	mov    0xf0230ed0,%edx
f0100ebf:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
f0100ec2:	89 0c 32             	mov    %ecx,(%edx,%esi,1)
		}
		prev = &pages[i];
f0100ec5:	03 05 d0 0e 23 f0    	add    0xf0230ed0,%eax
f0100ecb:	89 c7                	mov    %eax,%edi

	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	struct PageInfo *prev = 0;
	for (i = 1; i < npages_basemem; ++i) {
f0100ecd:	83 c3 01             	add    $0x1,%ebx
f0100ed0:	83 c6 08             	add    $0x8,%esi
f0100ed3:	3b 1d 68 02 23 f0    	cmp    0xf0230268,%ebx
f0100ed9:	72 87                	jb     f0100e62 <page_init+0x4b>
		prev = &pages[i];
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
f0100edb:	8d 04 dd f8 ff ff ff 	lea    -0x8(,%ebx,8),%eax
f0100ee2:	03 05 d0 0e 23 f0    	add    0xf0230ed0,%eax
f0100ee8:	a3 58 02 23 f0       	mov    %eax,0xf0230258
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100eed:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ef2:	e8 94 fb ff ff       	call   f0100a8b <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100ef7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100efc:	77 15                	ja     f0100f13 <page_init+0xfc>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100efe:	50                   	push   %eax
f0100eff:	68 c8 60 10 f0       	push   $0xf01060c8
f0100f04:	68 75 01 00 00       	push   $0x175
f0100f09:	68 35 70 10 f0       	push   $0xf0107035
f0100f0e:	e8 2d f1 ff ff       	call   f0100040 <_panic>
f0100f13:	05 ff 0f 00 10       	add    $0x10000fff,%eax
f0100f18:	c1 e8 0c             	shr    $0xc,%eax
f0100f1b:	8b 1d 58 02 23 f0    	mov    0xf0230258,%ebx
f0100f21:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100f28:	eb 2c                	jmp    f0100f56 <page_init+0x13f>
		pages[i].pp_ref = 0;
f0100f2a:	89 d1                	mov    %edx,%ecx
f0100f2c:	03 0d d0 0e 23 f0    	add    0xf0230ed0,%ecx
f0100f32:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = 0;
f0100f38:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		track->pp_link = &pages[i];
f0100f3e:	89 d1                	mov    %edx,%ecx
f0100f40:	03 0d d0 0e 23 f0    	add    0xf0230ed0,%ecx
f0100f46:	89 0b                	mov    %ecx,(%ebx)
		track = &pages[i];
f0100f48:	89 d3                	mov    %edx,%ebx
f0100f4a:	03 1d d0 0e 23 f0    	add    0xf0230ed0,%ebx
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100f50:	83 c0 01             	add    $0x1,%eax
f0100f53:	83 c2 08             	add    $0x8,%edx
f0100f56:	3b 05 c8 0e 23 f0    	cmp    0xf0230ec8,%eax
f0100f5c:	72 cc                	jb     f0100f2a <page_init+0x113>
f0100f5e:	89 1d 58 02 23 f0    	mov    %ebx,0xf0230258
		pages[i].pp_link = 0;
		track->pp_link = &pages[i];
		track = &pages[i];
	}
	
	cprintf("Check first entry of pages &pages[0] = %x\n", &pages[0]);
f0100f64:	83 ec 08             	sub    $0x8,%esp
f0100f67:	ff 35 d0 0e 23 f0    	pushl  0xf0230ed0
f0100f6d:	68 30 67 10 f0       	push   $0xf0106730
f0100f72:	e8 e3 28 00 00       	call   f010385a <cprintf>
	cprintf("&pages[npages-1] = %x\n", &pages[npages-1]);
f0100f77:	83 c4 08             	add    $0x8,%esp
f0100f7a:	a1 c8 0e 23 f0       	mov    0xf0230ec8,%eax
f0100f7f:	8d 04 c5 f8 ff ff ff 	lea    -0x8(,%eax,8),%eax
f0100f86:	03 05 d0 0e 23 f0    	add    0xf0230ed0,%eax
f0100f8c:	50                   	push   %eax
f0100f8d:	68 1e 71 10 f0       	push   $0xf010711e
f0100f92:	e8 c3 28 00 00       	call   f010385a <cprintf>
f0100f97:	83 c4 10             	add    $0x10,%esp
}
f0100f9a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f9d:	5b                   	pop    %ebx
f0100f9e:	5e                   	pop    %esi
f0100f9f:	5f                   	pop    %edi
f0100fa0:	5d                   	pop    %ebp
f0100fa1:	c3                   	ret    

f0100fa2 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100fa2:	55                   	push   %ebp
f0100fa3:	89 e5                	mov    %esp,%ebp
f0100fa5:	53                   	push   %ebx
f0100fa6:	83 ec 04             	sub    $0x4,%esp
	// Check if there is a free_page available 
	if (!page_free_list)
f0100fa9:	8b 1d 64 02 23 f0    	mov    0xf0230264,%ebx
f0100faf:	85 db                	test   %ebx,%ebx
f0100fb1:	74 5e                	je     f0101011 <page_alloc+0x6f>
	return NULL;
	}
	
	struct PageInfo *allocPage = NULL;   //Create a temporary pointer 
	allocPage = page_free_list;	//Point to the current head of free_page_list
	page_free_list = allocPage ->pp_link; //Move the head to the next avaialble page
f0100fb3:	8b 03                	mov    (%ebx),%eax
f0100fb5:	a3 64 02 23 f0       	mov    %eax,0xf0230264
	allocPage->pp_link = NULL;	//Break the link 
f0100fba:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags && ALLOC_ZERO){		//ALLOC_ZERO = 1<<0; which is nothing but  = 1
f0100fc0:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100fc4:	74 45                	je     f010100b <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fc6:	89 d8                	mov    %ebx,%eax
f0100fc8:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f0100fce:	c1 f8 03             	sar    $0x3,%eax
f0100fd1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fd4:	89 c2                	mov    %eax,%edx
f0100fd6:	c1 ea 0c             	shr    $0xc,%edx
f0100fd9:	3b 15 c8 0e 23 f0    	cmp    0xf0230ec8,%edx
f0100fdf:	72 12                	jb     f0100ff3 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fe1:	50                   	push   %eax
f0100fe2:	68 a4 60 10 f0       	push   $0xf01060a4
f0100fe7:	6a 58                	push   $0x58
f0100fe9:	68 41 70 10 f0       	push   $0xf0107041
f0100fee:	e8 4d f0 ff ff       	call   f0100040 <_panic>
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
f0100ff3:	83 ec 04             	sub    $0x4,%esp
f0100ff6:	68 00 10 00 00       	push   $0x1000
f0100ffb:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0100ffd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101002:	50                   	push   %eax
f0101003:	e8 aa 43 00 00       	call   f01053b2 <memset>
f0101008:	83 c4 10             	add    $0x10,%esp
	}
	
	allocPage->pp_ref = 0;
f010100b:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return allocPage;
}
f0101011:	89 d8                	mov    %ebx,%eax
f0101013:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101016:	c9                   	leave  
f0101017:	c3                   	ret    

f0101018 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0101018:	55                   	push   %ebp
f0101019:	89 e5                	mov    %esp,%ebp
f010101b:	83 ec 08             	sub    $0x8,%esp
f010101e:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	
	if(pp->pp_ref)
f0101021:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101026:	74 17                	je     f010103f <page_free+0x27>
	{
	panic("Page cannot be returned to free list, as it is still refernced ");
f0101028:	83 ec 04             	sub    $0x4,%esp
f010102b:	68 5c 67 10 f0       	push   $0xf010675c
f0101030:	68 ad 01 00 00       	push   $0x1ad
f0101035:	68 35 70 10 f0       	push   $0xf0107035
f010103a:	e8 01 f0 ff ff       	call   f0100040 <_panic>
	return;
	}
	
	// pp->pp_link is not NULL.
	else if(!pp) 
f010103f:	85 c0                	test   %eax,%eax
f0101041:	75 17                	jne    f010105a <page_free+0x42>
	{
	panic("Page cannot be returned to free list as it is Null");
f0101043:	83 ec 04             	sub    $0x4,%esp
f0101046:	68 9c 67 10 f0       	push   $0xf010679c
f010104b:	68 b4 01 00 00       	push   $0x1b4
f0101050:	68 35 70 10 f0       	push   $0xf0107035
f0101055:	e8 e6 ef ff ff       	call   f0100040 <_panic>
	return;
	}
	
       else{
	pp->pp_link = page_free_list;
f010105a:	8b 15 64 02 23 f0    	mov    0xf0230264,%edx
f0101060:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0101062:	a3 64 02 23 f0       	mov    %eax,0xf0230264
	}


}
f0101067:	c9                   	leave  
f0101068:	c3                   	ret    

f0101069 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101069:	55                   	push   %ebp
f010106a:	89 e5                	mov    %esp,%ebp
f010106c:	83 ec 08             	sub    $0x8,%esp
f010106f:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101072:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101076:	83 e8 01             	sub    $0x1,%eax
f0101079:	66 89 42 04          	mov    %ax,0x4(%edx)
f010107d:	66 85 c0             	test   %ax,%ax
f0101080:	75 0c                	jne    f010108e <page_decref+0x25>
		page_free(pp);
f0101082:	83 ec 0c             	sub    $0xc,%esp
f0101085:	52                   	push   %edx
f0101086:	e8 8d ff ff ff       	call   f0101018 <page_free>
f010108b:	83 c4 10             	add    $0x10,%esp
}
f010108e:	c9                   	leave  
f010108f:	c3                   	ret    

f0101090 <pgdir_walk>:
// table and page directory entries.
//

pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101090:	55                   	push   %ebp
f0101091:	89 e5                	mov    %esp,%ebp
f0101093:	57                   	push   %edi
f0101094:	56                   	push   %esi
f0101095:	53                   	push   %ebx
f0101096:	83 ec 0c             	sub    $0xc,%esp
	pte_t *pgTab;  //Page Table index variable

	//To find the index from the pgdir we need to get the MS 10 bits,
	//We get the MS 10bits of the virtual address by using PDX function (found in inc/mmu.h ) 
	//#define PDX(la)		((((uintptr_t) (la)) >> PDXSHIFT) & 0x3FF)
	pgDir = &pgdir[PDX(va)];
f0101099:	8b 75 0c             	mov    0xc(%ebp),%esi
f010109c:	c1 ee 16             	shr    $0x16,%esi
f010109f:	c1 e6 02             	shl    $0x2,%esi
f01010a2:	03 75 08             	add    0x8(%ebp),%esi

	// Check if page is present, PTE_P = 0x1 means page present  
	if (*pgDir & PTE_P)  {
f01010a5:	8b 1e                	mov    (%esi),%ebx
f01010a7:	f6 c3 01             	test   $0x1,%bl
f01010aa:	74 30                	je     f01010dc <pgdir_walk+0x4c>
		//page table entry to get to the final address translation. Now using the pgDir we can use the 
		//PTE_ADDR(pde) function to get the upper 20 bits, but this function returns a physical address. 
		//Since the kernel requires a virtual address, we can use the function KADDR to get the virtual 
		//address.
		
		pgTab = (pte_t*) KADDR(PTE_ADDR(*pgDir));
f01010ac:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010b2:	89 d8                	mov    %ebx,%eax
f01010b4:	c1 e8 0c             	shr    $0xc,%eax
f01010b7:	3b 05 c8 0e 23 f0    	cmp    0xf0230ec8,%eax
f01010bd:	72 15                	jb     f01010d4 <pgdir_walk+0x44>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010bf:	53                   	push   %ebx
f01010c0:	68 a4 60 10 f0       	push   $0xf01060a4
f01010c5:	68 f5 01 00 00       	push   $0x1f5
f01010ca:	68 35 70 10 f0       	push   $0xf0107035
f01010cf:	e8 6c ef ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01010d4:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
f01010da:	eb 7c                	jmp    f0101158 <pgdir_walk+0xc8>
	//If page is not present 
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
f01010dc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01010e0:	0f 84 81 00 00 00    	je     f0101167 <pgdir_walk+0xd7>
f01010e6:	83 ec 0c             	sub    $0xc,%esp
f01010e9:	68 00 10 00 00       	push   $0x1000
f01010ee:	e8 af fe ff ff       	call   f0100fa2 <page_alloc>
f01010f3:	89 c7                	mov    %eax,%edi
f01010f5:	83 c4 10             	add    $0x10,%esp
f01010f8:	85 c0                	test   %eax,%eax
f01010fa:	74 72                	je     f010116e <pgdir_walk+0xde>
			return 0;
		}

		newPage->pp_ref++;  //Increment the ref pointer of the page 
f01010fc:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101101:	89 c3                	mov    %eax,%ebx
f0101103:	2b 1d d0 0e 23 f0    	sub    0xf0230ed0,%ebx
f0101109:	c1 fb 03             	sar    $0x3,%ebx
f010110c:	c1 e3 0c             	shl    $0xc,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010110f:	89 d8                	mov    %ebx,%eax
f0101111:	c1 e8 0c             	shr    $0xc,%eax
f0101114:	3b 05 c8 0e 23 f0    	cmp    0xf0230ec8,%eax
f010111a:	72 12                	jb     f010112e <pgdir_walk+0x9e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010111c:	53                   	push   %ebx
f010111d:	68 a4 60 10 f0       	push   $0xf01060a4
f0101122:	6a 58                	push   $0x58
f0101124:	68 41 70 10 f0       	push   $0xf0107041
f0101129:	e8 12 ef ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010112e:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
		//Now this section creates the bindings and updates all the flags 
		//for relevant use of the page.
		
		//First create a link on the pgTab wrt to the new page
		pgTab = (pte_t*)page2kva(newPage); // this function gets the virtual address of the new page
		memset (pgTab, 0, PGSIZE); //Clear the entire page
f0101134:	83 ec 04             	sub    $0x4,%esp
f0101137:	68 00 10 00 00       	push   $0x1000
f010113c:	6a 00                	push   $0x0
f010113e:	53                   	push   %ebx
f010113f:	e8 6e 42 00 00       	call   f01053b2 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101144:	2b 3d d0 0e 23 f0    	sub    0xf0230ed0,%edi
f010114a:	c1 ff 03             	sar    $0x3,%edi
f010114d:	c1 e7 0c             	shl    $0xc,%edi

		//Page Table, pgTab contains the virtual address , now we need to set the permission bits.
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
f0101150:	83 cf 07             	or     $0x7,%edi
f0101153:	89 3e                	mov    %edi,(%esi)
f0101155:	83 c4 10             	add    $0x10,%esp
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
f0101158:	8b 45 0c             	mov    0xc(%ebp),%eax
f010115b:	c1 e8 0a             	shr    $0xa,%eax
f010115e:	25 fc 0f 00 00       	and    $0xffc,%eax
f0101163:	01 d8                	add    %ebx,%eax
f0101165:	eb 0c                	jmp    f0101173 <pgdir_walk+0xe3>
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
			return 0;
f0101167:	b8 00 00 00 00       	mov    $0x0,%eax
f010116c:	eb 05                	jmp    f0101173 <pgdir_walk+0xe3>
f010116e:	b8 00 00 00 00       	mov    $0x0,%eax
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
}
f0101173:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101176:	5b                   	pop    %ebx
f0101177:	5e                   	pop    %esi
f0101178:	5f                   	pop    %edi
f0101179:	5d                   	pop    %ebp
f010117a:	c3                   	ret    

f010117b <boot_map_region>:
//
// Hint: the TA solution uses pgdir_walk

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f010117b:	55                   	push   %ebp
f010117c:	89 e5                	mov    %esp,%ebp
f010117e:	57                   	push   %edi
f010117f:	56                   	push   %esi
f0101180:	53                   	push   %ebx
f0101181:	83 ec 1c             	sub    $0x1c,%esp
f0101184:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f0101187:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
f010118d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101190:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	size = ROUNDUP(size, PGSIZE); 
f0101195:	8d b9 ff 0f 00 00    	lea    0xfff(%ecx),%edi
f010119b:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f01011a1:	89 d3                	mov    %edx,%ebx
f01011a3:	29 d0                	sub    %edx,%eax
f01011a5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01011a8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011ab:	83 c8 01             	or     $0x1,%eax
f01011ae:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f01011b1:	eb 3d                	jmp    f01011f0 <boot_map_region+0x75>
		if (!(pgTbEnt = pgdir_walk(pgdir, (const void*)vaBegin, 1))){
f01011b3:	83 ec 04             	sub    $0x4,%esp
f01011b6:	6a 01                	push   $0x1
f01011b8:	53                   	push   %ebx
f01011b9:	ff 75 e0             	pushl  -0x20(%ebp)
f01011bc:	e8 cf fe ff ff       	call   f0101090 <pgdir_walk>
f01011c1:	83 c4 10             	add    $0x10,%esp
f01011c4:	85 c0                	test   %eax,%eax
f01011c6:	75 17                	jne    f01011df <boot_map_region+0x64>
			panic("Cannot find page for the page table entry, from boot_map_region function");
f01011c8:	83 ec 04             	sub    $0x4,%esp
f01011cb:	68 d0 67 10 f0       	push   $0xf01067d0
f01011d0:	68 2b 02 00 00       	push   $0x22b
f01011d5:	68 35 70 10 f0       	push   $0xf0107035
f01011da:	e8 61 ee ff ff       	call   f0100040 <_panic>
		}
		//if (*pgTbEnt & PTE_P)
		//	panic("Page is already mapped");
		
		
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
f01011df:	0b 75 dc             	or     -0x24(%ebp),%esi
f01011e2:	89 30                	mov    %esi,(%eax)
		vaBegin += PGSIZE;
f01011e4:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		paBegin += PGSIZE; 
		size -= PGSIZE;
f01011ea:	81 ef 00 10 00 00    	sub    $0x1000,%edi
f01011f0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01011f3:	8d 34 18             	lea    (%eax,%ebx,1),%esi
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f01011f6:	85 ff                	test   %edi,%edi
f01011f8:	75 b9                	jne    f01011b3 <boot_map_region+0x38>
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
		vaBegin += PGSIZE;
		paBegin += PGSIZE; 
		size -= PGSIZE;
	} 	
}
f01011fa:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011fd:	5b                   	pop    %ebx
f01011fe:	5e                   	pop    %esi
f01011ff:	5f                   	pop    %edi
f0101200:	5d                   	pop    %ebp
f0101201:	c3                   	ret    

f0101202 <page_lookup>:
// Hint: the TA solution uses pgdir_walk and pa2page.
//

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101202:	55                   	push   %ebp
f0101203:	89 e5                	mov    %esp,%ebp
f0101205:	53                   	push   %ebx
f0101206:	83 ec 08             	sub    $0x8,%esp
f0101209:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
	pgTbEty = pgdir_walk(pgdir, va, 0);
f010120c:	6a 00                	push   $0x0
f010120e:	ff 75 0c             	pushl  0xc(%ebp)
f0101211:	ff 75 08             	pushl  0x8(%ebp)
f0101214:	e8 77 fe ff ff       	call   f0101090 <pgdir_walk>
f0101219:	89 c1                	mov    %eax,%ecx
	if (pgTbEty && (*pgTbEty & PTE_P)) {
f010121b:	83 c4 10             	add    $0x10,%esp
f010121e:	85 c0                	test   %eax,%eax
f0101220:	74 1a                	je     f010123c <page_lookup+0x3a>
f0101222:	8b 10                	mov    (%eax),%edx
f0101224:	f6 c2 01             	test   $0x1,%dl
f0101227:	74 1a                	je     f0101243 <page_lookup+0x41>
		ret = pages + (PTE_ADDR(*pgTbEty) >> PTXSHIFT);
f0101229:	c1 ea 0c             	shr    $0xc,%edx
f010122c:	a1 d0 0e 23 f0       	mov    0xf0230ed0,%eax
f0101231:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		if (pte_store) {
f0101234:	85 db                	test   %ebx,%ebx
f0101236:	74 10                	je     f0101248 <page_lookup+0x46>
			*pte_store = pgTbEty;
f0101238:	89 0b                	mov    %ecx,(%ebx)
f010123a:	eb 0c                	jmp    f0101248 <page_lookup+0x46>

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
f010123c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101241:	eb 05                	jmp    f0101248 <page_lookup+0x46>
f0101243:	b8 00 00 00 00       	mov    $0x0,%eax
		if (pte_store) {
			*pte_store = pgTbEty;
		}
	}
	return ret;
}
f0101248:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010124b:	c9                   	leave  
f010124c:	c3                   	ret    

f010124d <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010124d:	55                   	push   %ebp
f010124e:	89 e5                	mov    %esp,%ebp
f0101250:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f0101253:	e8 7f 47 00 00       	call   f01059d7 <cpunum>
f0101258:	6b c0 74             	imul   $0x74,%eax,%eax
f010125b:	83 b8 48 10 23 f0 00 	cmpl   $0x0,-0xfdcefb8(%eax)
f0101262:	74 16                	je     f010127a <tlb_invalidate+0x2d>
f0101264:	e8 6e 47 00 00       	call   f01059d7 <cpunum>
f0101269:	6b c0 74             	imul   $0x74,%eax,%eax
f010126c:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0101272:	8b 55 08             	mov    0x8(%ebp),%edx
f0101275:	39 50 60             	cmp    %edx,0x60(%eax)
f0101278:	75 06                	jne    f0101280 <tlb_invalidate+0x33>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010127a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010127d:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f0101280:	c9                   	leave  
f0101281:	c3                   	ret    

f0101282 <page_remove>:
// 	tlb_invalidate, and page_decref.
//

void
page_remove(pde_t *pgdir, void *va)
{
f0101282:	55                   	push   %ebp
f0101283:	89 e5                	mov    %esp,%ebp
f0101285:	56                   	push   %esi
f0101286:	53                   	push   %ebx
f0101287:	83 ec 14             	sub    $0x14,%esp
f010128a:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010128d:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t *pte;
	struct PageInfo *remPage = 0;
	if (!(remPage = page_lookup(pgdir, va, &pte))) {
f0101290:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101293:	50                   	push   %eax
f0101294:	56                   	push   %esi
f0101295:	53                   	push   %ebx
f0101296:	e8 67 ff ff ff       	call   f0101202 <page_lookup>
f010129b:	83 c4 10             	add    $0x10,%esp
f010129e:	85 c0                	test   %eax,%eax
f01012a0:	74 1f                	je     f01012c1 <page_remove+0x3f>
		return;
	}
	page_decref(remPage);
f01012a2:	83 ec 0c             	sub    $0xc,%esp
f01012a5:	50                   	push   %eax
f01012a6:	e8 be fd ff ff       	call   f0101069 <page_decref>
	*pte = 0;
f01012ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012ae:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir, va);
f01012b4:	83 c4 08             	add    $0x8,%esp
f01012b7:	56                   	push   %esi
f01012b8:	53                   	push   %ebx
f01012b9:	e8 8f ff ff ff       	call   f010124d <tlb_invalidate>
f01012be:	83 c4 10             	add    $0x10,%esp
}
f01012c1:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01012c4:	5b                   	pop    %ebx
f01012c5:	5e                   	pop    %esi
f01012c6:	5d                   	pop    %ebp
f01012c7:	c3                   	ret    

f01012c8 <page_insert>:
// and page2pa.
//

int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01012c8:	55                   	push   %ebp
f01012c9:	89 e5                	mov    %esp,%ebp
f01012cb:	57                   	push   %edi
f01012cc:	56                   	push   %esi
f01012cd:	53                   	push   %ebx
f01012ce:	83 ec 10             	sub    $0x10,%esp
f01012d1:	8b 75 0c             	mov    0xc(%ebp),%esi
f01012d4:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
f01012d7:	6a 01                	push   $0x1
f01012d9:	57                   	push   %edi
f01012da:	ff 75 08             	pushl  0x8(%ebp)
f01012dd:	e8 ae fd ff ff       	call   f0101090 <pgdir_walk>
f01012e2:	89 c3                	mov    %eax,%ebx
	
	if (!pte){
f01012e4:	83 c4 10             	add    $0x10,%esp
f01012e7:	85 c0                	test   %eax,%eax
f01012e9:	0f 84 85 00 00 00    	je     f0101374 <page_insert+0xac>
		return -E_NO_MEM; //Page table could not be allocated	
	}

	if (*pte & PTE_P){    //if page is already present
f01012ef:	8b 00                	mov    (%eax),%eax
f01012f1:	a8 01                	test   $0x1,%al
f01012f3:	74 5b                	je     f0101350 <page_insert+0x88>
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
f01012f5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01012fa:	89 f2                	mov    %esi,%edx
f01012fc:	2b 15 d0 0e 23 f0    	sub    0xf0230ed0,%edx
f0101302:	c1 fa 03             	sar    $0x3,%edx
f0101305:	c1 e2 0c             	shl    $0xc,%edx
f0101308:	39 d0                	cmp    %edx,%eax
f010130a:	75 11                	jne    f010131d <page_insert+0x55>
f010130c:	8b 55 14             	mov    0x14(%ebp),%edx
f010130f:	83 ca 01             	or     $0x1,%edx
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
f0101312:	09 d0                	or     %edx,%eax
f0101314:	89 03                	mov    %eax,(%ebx)
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
			pp->pp_ref ++;  //incremnt the page reference
		}
		return 0;
f0101316:	b8 00 00 00 00       	mov    $0x0,%eax
f010131b:	eb 5c                	jmp    f0101379 <page_insert+0xb1>
	if (*pte & PTE_P){    //if page is already present
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
		}
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
f010131d:	83 ec 08             	sub    $0x8,%esp
f0101320:	57                   	push   %edi
f0101321:	ff 75 08             	pushl  0x8(%ebp)
f0101324:	e8 59 ff ff ff       	call   f0101282 <page_remove>
f0101329:	8b 55 14             	mov    0x14(%ebp),%edx
f010132c:	83 ca 01             	or     $0x1,%edx
f010132f:	89 f0                	mov    %esi,%eax
f0101331:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f0101337:	c1 f8 03             	sar    $0x3,%eax
f010133a:	c1 e0 0c             	shl    $0xc,%eax
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
f010133d:	09 d0                	or     %edx,%eax
f010133f:	89 03                	mov    %eax,(%ebx)
			pp->pp_ref ++;  //incremnt the page reference
f0101341:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
f0101346:	83 c4 10             	add    $0x10,%esp
		}
		return 0;
f0101349:	b8 00 00 00 00       	mov    $0x0,%eax
f010134e:	eb 29                	jmp    f0101379 <page_insert+0xb1>
f0101350:	8b 55 14             	mov    0x14(%ebp),%edx
f0101353:	83 ca 01             	or     $0x1,%edx
f0101356:	89 f0                	mov    %esi,%eax
f0101358:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f010135e:	c1 f8 03             	sar    $0x3,%eax
f0101361:	c1 e0 0c             	shl    $0xc,%eax
	}	
	else{   // if page is not present
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
f0101364:	09 d0                	or     %edx,%eax
f0101366:	89 03                	mov    %eax,(%ebx)
		pp->pp_ref ++; // increment the page reference count	     
f0101368:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	}
	return 0;
f010136d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101372:	eb 05                	jmp    f0101379 <page_insert+0xb1>
{
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
	
	if (!pte){
		return -E_NO_MEM; //Page table could not be allocated	
f0101374:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
		pp->pp_ref ++; // increment the page reference count	     
	}
	return 0;

}
f0101379:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010137c:	5b                   	pop    %ebx
f010137d:	5e                   	pop    %esi
f010137e:	5f                   	pop    %edi
f010137f:	5d                   	pop    %ebp
f0101380:	c3                   	ret    

f0101381 <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f0101381:	55                   	push   %ebp
f0101382:	89 e5                	mov    %esp,%ebp
f0101384:	56                   	push   %esi
f0101385:	53                   	push   %ebx
	//
	// Your code here:
	//panic("mmio_map_region not implemented");
	
	//Since we modify the value of the pointer, copy the value of the pointer into some variable
	void* save = (void*) base;  // USe a pointer to void, just to store the first address
f0101386:	8b 35 00 03 12 f0    	mov    0xf0120300,%esi
	
	//Roundup size to pgsize
	size = ROUNDUP(size,PGSIZE);
f010138c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010138f:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f0101395:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	
	//Use bootmap region to map the given region
	boot_map_region(kern_pgdir, base, size, pa, PTE_W | PTE_P |PTE_PCD|PTE_PWT);
f010139b:	83 ec 08             	sub    $0x8,%esp
f010139e:	6a 1b                	push   $0x1b
f01013a0:	ff 75 08             	pushl  0x8(%ebp)
f01013a3:	89 d9                	mov    %ebx,%ecx
f01013a5:	89 f2                	mov    %esi,%edx
f01013a7:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
f01013ac:	e8 ca fd ff ff       	call   f010117b <boot_map_region>
	
	//reserving size bytes of memory
	base += size;
f01013b1:	01 1d 00 03 12 f0    	add    %ebx,0xf0120300
	
	return save; 
	
}
f01013b7:	89 f0                	mov    %esi,%eax
f01013b9:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01013bc:	5b                   	pop    %ebx
f01013bd:	5e                   	pop    %esi
f01013be:	5d                   	pop    %ebp
f01013bf:	c3                   	ret    

f01013c0 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01013c0:	55                   	push   %ebp
f01013c1:	89 e5                	mov    %esp,%ebp
f01013c3:	57                   	push   %edi
f01013c4:	56                   	push   %esi
f01013c5:	53                   	push   %ebx
f01013c6:	83 ec 48             	sub    $0x48,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01013c9:	6a 15                	push   $0x15
f01013cb:	e8 29 23 00 00       	call   f01036f9 <mc146818_read>
f01013d0:	89 c3                	mov    %eax,%ebx
f01013d2:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f01013d9:	e8 1b 23 00 00       	call   f01036f9 <mc146818_read>
f01013de:	c1 e0 08             	shl    $0x8,%eax
f01013e1:	09 d8                	or     %ebx,%eax
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01013e3:	c1 e0 0a             	shl    $0xa,%eax
f01013e6:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01013ec:	85 c0                	test   %eax,%eax
f01013ee:	0f 48 c2             	cmovs  %edx,%eax
f01013f1:	c1 f8 0c             	sar    $0xc,%eax
f01013f4:	a3 68 02 23 f0       	mov    %eax,0xf0230268
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01013f9:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101400:	e8 f4 22 00 00       	call   f01036f9 <mc146818_read>
f0101405:	89 c3                	mov    %eax,%ebx
f0101407:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f010140e:	e8 e6 22 00 00       	call   f01036f9 <mc146818_read>
f0101413:	c1 e0 08             	shl    $0x8,%eax
f0101416:	09 d8                	or     %ebx,%eax
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101418:	c1 e0 0a             	shl    $0xa,%eax
f010141b:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101421:	83 c4 10             	add    $0x10,%esp
f0101424:	85 c0                	test   %eax,%eax
f0101426:	0f 48 c2             	cmovs  %edx,%eax
f0101429:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f010142c:	85 c0                	test   %eax,%eax
f010142e:	74 0e                	je     f010143e <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101430:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101436:	89 15 c8 0e 23 f0    	mov    %edx,0xf0230ec8
f010143c:	eb 0c                	jmp    f010144a <mem_init+0x8a>
	else
		npages = npages_basemem;
f010143e:	8b 15 68 02 23 f0    	mov    0xf0230268,%edx
f0101444:	89 15 c8 0e 23 f0    	mov    %edx,0xf0230ec8

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f010144a:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010144d:	c1 e8 0a             	shr    $0xa,%eax
f0101450:	50                   	push   %eax
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0101451:	a1 68 02 23 f0       	mov    0xf0230268,%eax
f0101456:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101459:	c1 e8 0a             	shr    $0xa,%eax
f010145c:	50                   	push   %eax
		npages * PGSIZE / 1024,
f010145d:	a1 c8 0e 23 f0       	mov    0xf0230ec8,%eax
f0101462:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101465:	c1 e8 0a             	shr    $0xa,%eax
f0101468:	50                   	push   %eax
f0101469:	68 1c 68 10 f0       	push   $0xf010681c
f010146e:	e8 e7 23 00 00       	call   f010385a <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101473:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101478:	e8 0e f6 ff ff       	call   f0100a8b <boot_alloc>
f010147d:	a3 cc 0e 23 f0       	mov    %eax,0xf0230ecc
	memset(kern_pgdir, 0, PGSIZE);
f0101482:	83 c4 0c             	add    $0xc,%esp
f0101485:	68 00 10 00 00       	push   $0x1000
f010148a:	6a 00                	push   $0x0
f010148c:	50                   	push   %eax
f010148d:	e8 20 3f 00 00       	call   f01053b2 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101492:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101497:	83 c4 10             	add    $0x10,%esp
f010149a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010149f:	77 15                	ja     f01014b6 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01014a1:	50                   	push   %eax
f01014a2:	68 c8 60 10 f0       	push   $0xf01060c8
f01014a7:	68 98 00 00 00       	push   $0x98
f01014ac:	68 35 70 10 f0       	push   $0xf0107035
f01014b1:	e8 8a eb ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01014b6:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01014bc:	83 ca 05             	or     $0x5,%edx
f01014bf:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.

	//This line creates a boot allocation of memory of the size of number of pages
	// mulitplied by size of struct Pageinfo to store metadata of the page. 
	pages = boot_alloc(sizeof(struct PageInfo) * npages);   
f01014c5:	a1 c8 0e 23 f0       	mov    0xf0230ec8,%eax
f01014ca:	c1 e0 03             	shl    $0x3,%eax
f01014cd:	e8 b9 f5 ff ff       	call   f0100a8b <boot_alloc>
f01014d2:	a3 d0 0e 23 f0       	mov    %eax,0xf0230ed0
	memset(pages, 0, sizeof(struct PageInfo) * npages); //Clear the memory 
f01014d7:	83 ec 04             	sub    $0x4,%esp
f01014da:	8b 0d c8 0e 23 f0    	mov    0xf0230ec8,%ecx
f01014e0:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01014e7:	52                   	push   %edx
f01014e8:	6a 00                	push   $0x0
f01014ea:	50                   	push   %eax
f01014eb:	e8 c2 3e 00 00       	call   f01053b2 <memset>
	// The kernel uses this array to keep track of environment array:
	// 'NENV' is the number of Environments in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = boot_alloc(sizeof(struct Env)*NENV);
f01014f0:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f01014f5:	e8 91 f5 ff ff       	call   f0100a8b <boot_alloc>
f01014fa:	a3 6c 02 23 f0       	mov    %eax,0xf023026c
	memset(envs,0,sizeof(struct Env)*NENV);
f01014ff:	83 c4 0c             	add    $0xc,%esp
f0101502:	68 00 f0 01 00       	push   $0x1f000
f0101507:	6a 00                	push   $0x0
f0101509:	50                   	push   %eax
f010150a:	e8 a3 3e 00 00       	call   f01053b2 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010150f:	e8 03 f9 ff ff       	call   f0100e17 <page_init>

	check_page_free_list(1);
f0101514:	b8 01 00 00 00       	mov    $0x1,%eax
f0101519:	e8 e3 f5 ff ff       	call   f0100b01 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010151e:	83 c4 10             	add    $0x10,%esp
f0101521:	83 3d d0 0e 23 f0 00 	cmpl   $0x0,0xf0230ed0
f0101528:	75 17                	jne    f0101541 <mem_init+0x181>
		panic("'pages' is a null pointer!");
f010152a:	83 ec 04             	sub    $0x4,%esp
f010152d:	68 35 71 10 f0       	push   $0xf0107135
f0101532:	68 84 03 00 00       	push   $0x384
f0101537:	68 35 70 10 f0       	push   $0xf0107035
f010153c:	e8 ff ea ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101541:	a1 64 02 23 f0       	mov    0xf0230264,%eax
f0101546:	bb 00 00 00 00       	mov    $0x0,%ebx
f010154b:	eb 05                	jmp    f0101552 <mem_init+0x192>
		++nfree;
f010154d:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101550:	8b 00                	mov    (%eax),%eax
f0101552:	85 c0                	test   %eax,%eax
f0101554:	75 f7                	jne    f010154d <mem_init+0x18d>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101556:	83 ec 0c             	sub    $0xc,%esp
f0101559:	6a 00                	push   $0x0
f010155b:	e8 42 fa ff ff       	call   f0100fa2 <page_alloc>
f0101560:	89 c7                	mov    %eax,%edi
f0101562:	83 c4 10             	add    $0x10,%esp
f0101565:	85 c0                	test   %eax,%eax
f0101567:	75 19                	jne    f0101582 <mem_init+0x1c2>
f0101569:	68 50 71 10 f0       	push   $0xf0107150
f010156e:	68 5b 70 10 f0       	push   $0xf010705b
f0101573:	68 8c 03 00 00       	push   $0x38c
f0101578:	68 35 70 10 f0       	push   $0xf0107035
f010157d:	e8 be ea ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101582:	83 ec 0c             	sub    $0xc,%esp
f0101585:	6a 00                	push   $0x0
f0101587:	e8 16 fa ff ff       	call   f0100fa2 <page_alloc>
f010158c:	89 c6                	mov    %eax,%esi
f010158e:	83 c4 10             	add    $0x10,%esp
f0101591:	85 c0                	test   %eax,%eax
f0101593:	75 19                	jne    f01015ae <mem_init+0x1ee>
f0101595:	68 66 71 10 f0       	push   $0xf0107166
f010159a:	68 5b 70 10 f0       	push   $0xf010705b
f010159f:	68 8d 03 00 00       	push   $0x38d
f01015a4:	68 35 70 10 f0       	push   $0xf0107035
f01015a9:	e8 92 ea ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01015ae:	83 ec 0c             	sub    $0xc,%esp
f01015b1:	6a 00                	push   $0x0
f01015b3:	e8 ea f9 ff ff       	call   f0100fa2 <page_alloc>
f01015b8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015bb:	83 c4 10             	add    $0x10,%esp
f01015be:	85 c0                	test   %eax,%eax
f01015c0:	75 19                	jne    f01015db <mem_init+0x21b>
f01015c2:	68 7c 71 10 f0       	push   $0xf010717c
f01015c7:	68 5b 70 10 f0       	push   $0xf010705b
f01015cc:	68 8e 03 00 00       	push   $0x38e
f01015d1:	68 35 70 10 f0       	push   $0xf0107035
f01015d6:	e8 65 ea ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015db:	39 f7                	cmp    %esi,%edi
f01015dd:	75 19                	jne    f01015f8 <mem_init+0x238>
f01015df:	68 92 71 10 f0       	push   $0xf0107192
f01015e4:	68 5b 70 10 f0       	push   $0xf010705b
f01015e9:	68 91 03 00 00       	push   $0x391
f01015ee:	68 35 70 10 f0       	push   $0xf0107035
f01015f3:	e8 48 ea ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015f8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015fb:	39 c7                	cmp    %eax,%edi
f01015fd:	74 04                	je     f0101603 <mem_init+0x243>
f01015ff:	39 c6                	cmp    %eax,%esi
f0101601:	75 19                	jne    f010161c <mem_init+0x25c>
f0101603:	68 58 68 10 f0       	push   $0xf0106858
f0101608:	68 5b 70 10 f0       	push   $0xf010705b
f010160d:	68 92 03 00 00       	push   $0x392
f0101612:	68 35 70 10 f0       	push   $0xf0107035
f0101617:	e8 24 ea ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010161c:	8b 0d d0 0e 23 f0    	mov    0xf0230ed0,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101622:	8b 15 c8 0e 23 f0    	mov    0xf0230ec8,%edx
f0101628:	c1 e2 0c             	shl    $0xc,%edx
f010162b:	89 f8                	mov    %edi,%eax
f010162d:	29 c8                	sub    %ecx,%eax
f010162f:	c1 f8 03             	sar    $0x3,%eax
f0101632:	c1 e0 0c             	shl    $0xc,%eax
f0101635:	39 d0                	cmp    %edx,%eax
f0101637:	72 19                	jb     f0101652 <mem_init+0x292>
f0101639:	68 a4 71 10 f0       	push   $0xf01071a4
f010163e:	68 5b 70 10 f0       	push   $0xf010705b
f0101643:	68 93 03 00 00       	push   $0x393
f0101648:	68 35 70 10 f0       	push   $0xf0107035
f010164d:	e8 ee e9 ff ff       	call   f0100040 <_panic>
f0101652:	89 f0                	mov    %esi,%eax
f0101654:	29 c8                	sub    %ecx,%eax
f0101656:	c1 f8 03             	sar    $0x3,%eax
f0101659:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f010165c:	39 c2                	cmp    %eax,%edx
f010165e:	77 19                	ja     f0101679 <mem_init+0x2b9>
f0101660:	68 c1 71 10 f0       	push   $0xf01071c1
f0101665:	68 5b 70 10 f0       	push   $0xf010705b
f010166a:	68 94 03 00 00       	push   $0x394
f010166f:	68 35 70 10 f0       	push   $0xf0107035
f0101674:	e8 c7 e9 ff ff       	call   f0100040 <_panic>
f0101679:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010167c:	29 c8                	sub    %ecx,%eax
f010167e:	c1 f8 03             	sar    $0x3,%eax
f0101681:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f0101684:	39 c2                	cmp    %eax,%edx
f0101686:	77 19                	ja     f01016a1 <mem_init+0x2e1>
f0101688:	68 de 71 10 f0       	push   $0xf01071de
f010168d:	68 5b 70 10 f0       	push   $0xf010705b
f0101692:	68 95 03 00 00       	push   $0x395
f0101697:	68 35 70 10 f0       	push   $0xf0107035
f010169c:	e8 9f e9 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01016a1:	a1 64 02 23 f0       	mov    0xf0230264,%eax
f01016a6:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01016a9:	c7 05 64 02 23 f0 00 	movl   $0x0,0xf0230264
f01016b0:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01016b3:	83 ec 0c             	sub    $0xc,%esp
f01016b6:	6a 00                	push   $0x0
f01016b8:	e8 e5 f8 ff ff       	call   f0100fa2 <page_alloc>
f01016bd:	83 c4 10             	add    $0x10,%esp
f01016c0:	85 c0                	test   %eax,%eax
f01016c2:	74 19                	je     f01016dd <mem_init+0x31d>
f01016c4:	68 fb 71 10 f0       	push   $0xf01071fb
f01016c9:	68 5b 70 10 f0       	push   $0xf010705b
f01016ce:	68 9c 03 00 00       	push   $0x39c
f01016d3:	68 35 70 10 f0       	push   $0xf0107035
f01016d8:	e8 63 e9 ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01016dd:	83 ec 0c             	sub    $0xc,%esp
f01016e0:	57                   	push   %edi
f01016e1:	e8 32 f9 ff ff       	call   f0101018 <page_free>
	page_free(pp1);
f01016e6:	89 34 24             	mov    %esi,(%esp)
f01016e9:	e8 2a f9 ff ff       	call   f0101018 <page_free>
	page_free(pp2);
f01016ee:	83 c4 04             	add    $0x4,%esp
f01016f1:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016f4:	e8 1f f9 ff ff       	call   f0101018 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01016f9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101700:	e8 9d f8 ff ff       	call   f0100fa2 <page_alloc>
f0101705:	89 c6                	mov    %eax,%esi
f0101707:	83 c4 10             	add    $0x10,%esp
f010170a:	85 c0                	test   %eax,%eax
f010170c:	75 19                	jne    f0101727 <mem_init+0x367>
f010170e:	68 50 71 10 f0       	push   $0xf0107150
f0101713:	68 5b 70 10 f0       	push   $0xf010705b
f0101718:	68 a3 03 00 00       	push   $0x3a3
f010171d:	68 35 70 10 f0       	push   $0xf0107035
f0101722:	e8 19 e9 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101727:	83 ec 0c             	sub    $0xc,%esp
f010172a:	6a 00                	push   $0x0
f010172c:	e8 71 f8 ff ff       	call   f0100fa2 <page_alloc>
f0101731:	89 c7                	mov    %eax,%edi
f0101733:	83 c4 10             	add    $0x10,%esp
f0101736:	85 c0                	test   %eax,%eax
f0101738:	75 19                	jne    f0101753 <mem_init+0x393>
f010173a:	68 66 71 10 f0       	push   $0xf0107166
f010173f:	68 5b 70 10 f0       	push   $0xf010705b
f0101744:	68 a4 03 00 00       	push   $0x3a4
f0101749:	68 35 70 10 f0       	push   $0xf0107035
f010174e:	e8 ed e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101753:	83 ec 0c             	sub    $0xc,%esp
f0101756:	6a 00                	push   $0x0
f0101758:	e8 45 f8 ff ff       	call   f0100fa2 <page_alloc>
f010175d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101760:	83 c4 10             	add    $0x10,%esp
f0101763:	85 c0                	test   %eax,%eax
f0101765:	75 19                	jne    f0101780 <mem_init+0x3c0>
f0101767:	68 7c 71 10 f0       	push   $0xf010717c
f010176c:	68 5b 70 10 f0       	push   $0xf010705b
f0101771:	68 a5 03 00 00       	push   $0x3a5
f0101776:	68 35 70 10 f0       	push   $0xf0107035
f010177b:	e8 c0 e8 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101780:	39 fe                	cmp    %edi,%esi
f0101782:	75 19                	jne    f010179d <mem_init+0x3dd>
f0101784:	68 92 71 10 f0       	push   $0xf0107192
f0101789:	68 5b 70 10 f0       	push   $0xf010705b
f010178e:	68 a7 03 00 00       	push   $0x3a7
f0101793:	68 35 70 10 f0       	push   $0xf0107035
f0101798:	e8 a3 e8 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010179d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017a0:	39 c6                	cmp    %eax,%esi
f01017a2:	74 04                	je     f01017a8 <mem_init+0x3e8>
f01017a4:	39 c7                	cmp    %eax,%edi
f01017a6:	75 19                	jne    f01017c1 <mem_init+0x401>
f01017a8:	68 58 68 10 f0       	push   $0xf0106858
f01017ad:	68 5b 70 10 f0       	push   $0xf010705b
f01017b2:	68 a8 03 00 00       	push   $0x3a8
f01017b7:	68 35 70 10 f0       	push   $0xf0107035
f01017bc:	e8 7f e8 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01017c1:	83 ec 0c             	sub    $0xc,%esp
f01017c4:	6a 00                	push   $0x0
f01017c6:	e8 d7 f7 ff ff       	call   f0100fa2 <page_alloc>
f01017cb:	83 c4 10             	add    $0x10,%esp
f01017ce:	85 c0                	test   %eax,%eax
f01017d0:	74 19                	je     f01017eb <mem_init+0x42b>
f01017d2:	68 fb 71 10 f0       	push   $0xf01071fb
f01017d7:	68 5b 70 10 f0       	push   $0xf010705b
f01017dc:	68 a9 03 00 00       	push   $0x3a9
f01017e1:	68 35 70 10 f0       	push   $0xf0107035
f01017e6:	e8 55 e8 ff ff       	call   f0100040 <_panic>
f01017eb:	89 f0                	mov    %esi,%eax
f01017ed:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f01017f3:	c1 f8 03             	sar    $0x3,%eax
f01017f6:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01017f9:	89 c2                	mov    %eax,%edx
f01017fb:	c1 ea 0c             	shr    $0xc,%edx
f01017fe:	3b 15 c8 0e 23 f0    	cmp    0xf0230ec8,%edx
f0101804:	72 12                	jb     f0101818 <mem_init+0x458>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101806:	50                   	push   %eax
f0101807:	68 a4 60 10 f0       	push   $0xf01060a4
f010180c:	6a 58                	push   $0x58
f010180e:	68 41 70 10 f0       	push   $0xf0107041
f0101813:	e8 28 e8 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101818:	83 ec 04             	sub    $0x4,%esp
f010181b:	68 00 10 00 00       	push   $0x1000
f0101820:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0101822:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101827:	50                   	push   %eax
f0101828:	e8 85 3b 00 00       	call   f01053b2 <memset>
	page_free(pp0);
f010182d:	89 34 24             	mov    %esi,(%esp)
f0101830:	e8 e3 f7 ff ff       	call   f0101018 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101835:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010183c:	e8 61 f7 ff ff       	call   f0100fa2 <page_alloc>
f0101841:	83 c4 10             	add    $0x10,%esp
f0101844:	85 c0                	test   %eax,%eax
f0101846:	75 19                	jne    f0101861 <mem_init+0x4a1>
f0101848:	68 0a 72 10 f0       	push   $0xf010720a
f010184d:	68 5b 70 10 f0       	push   $0xf010705b
f0101852:	68 ae 03 00 00       	push   $0x3ae
f0101857:	68 35 70 10 f0       	push   $0xf0107035
f010185c:	e8 df e7 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101861:	39 c6                	cmp    %eax,%esi
f0101863:	74 19                	je     f010187e <mem_init+0x4be>
f0101865:	68 28 72 10 f0       	push   $0xf0107228
f010186a:	68 5b 70 10 f0       	push   $0xf010705b
f010186f:	68 af 03 00 00       	push   $0x3af
f0101874:	68 35 70 10 f0       	push   $0xf0107035
f0101879:	e8 c2 e7 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010187e:	89 f0                	mov    %esi,%eax
f0101880:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f0101886:	c1 f8 03             	sar    $0x3,%eax
f0101889:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010188c:	89 c2                	mov    %eax,%edx
f010188e:	c1 ea 0c             	shr    $0xc,%edx
f0101891:	3b 15 c8 0e 23 f0    	cmp    0xf0230ec8,%edx
f0101897:	72 12                	jb     f01018ab <mem_init+0x4eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101899:	50                   	push   %eax
f010189a:	68 a4 60 10 f0       	push   $0xf01060a4
f010189f:	6a 58                	push   $0x58
f01018a1:	68 41 70 10 f0       	push   $0xf0107041
f01018a6:	e8 95 e7 ff ff       	call   f0100040 <_panic>
f01018ab:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01018b1:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01018b7:	80 38 00             	cmpb   $0x0,(%eax)
f01018ba:	74 19                	je     f01018d5 <mem_init+0x515>
f01018bc:	68 38 72 10 f0       	push   $0xf0107238
f01018c1:	68 5b 70 10 f0       	push   $0xf010705b
f01018c6:	68 b2 03 00 00       	push   $0x3b2
f01018cb:	68 35 70 10 f0       	push   $0xf0107035
f01018d0:	e8 6b e7 ff ff       	call   f0100040 <_panic>
f01018d5:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01018d8:	39 d0                	cmp    %edx,%eax
f01018da:	75 db                	jne    f01018b7 <mem_init+0x4f7>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01018dc:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01018df:	a3 64 02 23 f0       	mov    %eax,0xf0230264

	// free the pages we took
	page_free(pp0);
f01018e4:	83 ec 0c             	sub    $0xc,%esp
f01018e7:	56                   	push   %esi
f01018e8:	e8 2b f7 ff ff       	call   f0101018 <page_free>
	page_free(pp1);
f01018ed:	89 3c 24             	mov    %edi,(%esp)
f01018f0:	e8 23 f7 ff ff       	call   f0101018 <page_free>
	page_free(pp2);
f01018f5:	83 c4 04             	add    $0x4,%esp
f01018f8:	ff 75 d4             	pushl  -0x2c(%ebp)
f01018fb:	e8 18 f7 ff ff       	call   f0101018 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101900:	a1 64 02 23 f0       	mov    0xf0230264,%eax
f0101905:	83 c4 10             	add    $0x10,%esp
f0101908:	eb 05                	jmp    f010190f <mem_init+0x54f>
		--nfree;
f010190a:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010190d:	8b 00                	mov    (%eax),%eax
f010190f:	85 c0                	test   %eax,%eax
f0101911:	75 f7                	jne    f010190a <mem_init+0x54a>
		--nfree;
	assert(nfree == 0);
f0101913:	85 db                	test   %ebx,%ebx
f0101915:	74 19                	je     f0101930 <mem_init+0x570>
f0101917:	68 42 72 10 f0       	push   $0xf0107242
f010191c:	68 5b 70 10 f0       	push   $0xf010705b
f0101921:	68 bf 03 00 00       	push   $0x3bf
f0101926:	68 35 70 10 f0       	push   $0xf0107035
f010192b:	e8 10 e7 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101930:	83 ec 0c             	sub    $0xc,%esp
f0101933:	68 78 68 10 f0       	push   $0xf0106878
f0101938:	e8 1d 1f 00 00       	call   f010385a <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010193d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101944:	e8 59 f6 ff ff       	call   f0100fa2 <page_alloc>
f0101949:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010194c:	83 c4 10             	add    $0x10,%esp
f010194f:	85 c0                	test   %eax,%eax
f0101951:	75 19                	jne    f010196c <mem_init+0x5ac>
f0101953:	68 50 71 10 f0       	push   $0xf0107150
f0101958:	68 5b 70 10 f0       	push   $0xf010705b
f010195d:	68 25 04 00 00       	push   $0x425
f0101962:	68 35 70 10 f0       	push   $0xf0107035
f0101967:	e8 d4 e6 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010196c:	83 ec 0c             	sub    $0xc,%esp
f010196f:	6a 00                	push   $0x0
f0101971:	e8 2c f6 ff ff       	call   f0100fa2 <page_alloc>
f0101976:	89 c3                	mov    %eax,%ebx
f0101978:	83 c4 10             	add    $0x10,%esp
f010197b:	85 c0                	test   %eax,%eax
f010197d:	75 19                	jne    f0101998 <mem_init+0x5d8>
f010197f:	68 66 71 10 f0       	push   $0xf0107166
f0101984:	68 5b 70 10 f0       	push   $0xf010705b
f0101989:	68 26 04 00 00       	push   $0x426
f010198e:	68 35 70 10 f0       	push   $0xf0107035
f0101993:	e8 a8 e6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101998:	83 ec 0c             	sub    $0xc,%esp
f010199b:	6a 00                	push   $0x0
f010199d:	e8 00 f6 ff ff       	call   f0100fa2 <page_alloc>
f01019a2:	89 c6                	mov    %eax,%esi
f01019a4:	83 c4 10             	add    $0x10,%esp
f01019a7:	85 c0                	test   %eax,%eax
f01019a9:	75 19                	jne    f01019c4 <mem_init+0x604>
f01019ab:	68 7c 71 10 f0       	push   $0xf010717c
f01019b0:	68 5b 70 10 f0       	push   $0xf010705b
f01019b5:	68 27 04 00 00       	push   $0x427
f01019ba:	68 35 70 10 f0       	push   $0xf0107035
f01019bf:	e8 7c e6 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01019c4:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01019c7:	75 19                	jne    f01019e2 <mem_init+0x622>
f01019c9:	68 92 71 10 f0       	push   $0xf0107192
f01019ce:	68 5b 70 10 f0       	push   $0xf010705b
f01019d3:	68 2a 04 00 00       	push   $0x42a
f01019d8:	68 35 70 10 f0       	push   $0xf0107035
f01019dd:	e8 5e e6 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01019e2:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01019e5:	74 04                	je     f01019eb <mem_init+0x62b>
f01019e7:	39 c3                	cmp    %eax,%ebx
f01019e9:	75 19                	jne    f0101a04 <mem_init+0x644>
f01019eb:	68 58 68 10 f0       	push   $0xf0106858
f01019f0:	68 5b 70 10 f0       	push   $0xf010705b
f01019f5:	68 2b 04 00 00       	push   $0x42b
f01019fa:	68 35 70 10 f0       	push   $0xf0107035
f01019ff:	e8 3c e6 ff ff       	call   f0100040 <_panic>
	

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101a04:	a1 64 02 23 f0       	mov    0xf0230264,%eax
f0101a09:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101a0c:	c7 05 64 02 23 f0 00 	movl   $0x0,0xf0230264
f0101a13:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101a16:	83 ec 0c             	sub    $0xc,%esp
f0101a19:	6a 00                	push   $0x0
f0101a1b:	e8 82 f5 ff ff       	call   f0100fa2 <page_alloc>
f0101a20:	83 c4 10             	add    $0x10,%esp
f0101a23:	85 c0                	test   %eax,%eax
f0101a25:	74 19                	je     f0101a40 <mem_init+0x680>
f0101a27:	68 fb 71 10 f0       	push   $0xf01071fb
f0101a2c:	68 5b 70 10 f0       	push   $0xf010705b
f0101a31:	68 33 04 00 00       	push   $0x433
f0101a36:	68 35 70 10 f0       	push   $0xf0107035
f0101a3b:	e8 00 e6 ff ff       	call   f0100040 <_panic>
	
	
	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101a40:	83 ec 04             	sub    $0x4,%esp
f0101a43:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101a46:	50                   	push   %eax
f0101a47:	6a 00                	push   $0x0
f0101a49:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0101a4f:	e8 ae f7 ff ff       	call   f0101202 <page_lookup>
f0101a54:	83 c4 10             	add    $0x10,%esp
f0101a57:	85 c0                	test   %eax,%eax
f0101a59:	74 19                	je     f0101a74 <mem_init+0x6b4>
f0101a5b:	68 98 68 10 f0       	push   $0xf0106898
f0101a60:	68 5b 70 10 f0       	push   $0xf010705b
f0101a65:	68 37 04 00 00       	push   $0x437
f0101a6a:	68 35 70 10 f0       	push   $0xf0107035
f0101a6f:	e8 cc e5 ff ff       	call   f0100040 <_panic>
	
	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a74:	6a 02                	push   $0x2
f0101a76:	6a 00                	push   $0x0
f0101a78:	53                   	push   %ebx
f0101a79:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0101a7f:	e8 44 f8 ff ff       	call   f01012c8 <page_insert>
f0101a84:	83 c4 10             	add    $0x10,%esp
f0101a87:	85 c0                	test   %eax,%eax
f0101a89:	78 19                	js     f0101aa4 <mem_init+0x6e4>
f0101a8b:	68 d0 68 10 f0       	push   $0xf01068d0
f0101a90:	68 5b 70 10 f0       	push   $0xf010705b
f0101a95:	68 3a 04 00 00       	push   $0x43a
f0101a9a:	68 35 70 10 f0       	push   $0xf0107035
f0101a9f:	e8 9c e5 ff ff       	call   f0100040 <_panic>
	
	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101aa4:	83 ec 0c             	sub    $0xc,%esp
f0101aa7:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101aaa:	e8 69 f5 ff ff       	call   f0101018 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101aaf:	6a 02                	push   $0x2
f0101ab1:	6a 00                	push   $0x0
f0101ab3:	53                   	push   %ebx
f0101ab4:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0101aba:	e8 09 f8 ff ff       	call   f01012c8 <page_insert>
f0101abf:	83 c4 20             	add    $0x20,%esp
f0101ac2:	85 c0                	test   %eax,%eax
f0101ac4:	74 19                	je     f0101adf <mem_init+0x71f>
f0101ac6:	68 00 69 10 f0       	push   $0xf0106900
f0101acb:	68 5b 70 10 f0       	push   $0xf010705b
f0101ad0:	68 3e 04 00 00       	push   $0x43e
f0101ad5:	68 35 70 10 f0       	push   $0xf0107035
f0101ada:	e8 61 e5 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101adf:	8b 3d cc 0e 23 f0    	mov    0xf0230ecc,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101ae5:	a1 d0 0e 23 f0       	mov    0xf0230ed0,%eax
f0101aea:	89 c1                	mov    %eax,%ecx
f0101aec:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101aef:	8b 17                	mov    (%edi),%edx
f0101af1:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101af7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101afa:	29 c8                	sub    %ecx,%eax
f0101afc:	c1 f8 03             	sar    $0x3,%eax
f0101aff:	c1 e0 0c             	shl    $0xc,%eax
f0101b02:	39 c2                	cmp    %eax,%edx
f0101b04:	74 19                	je     f0101b1f <mem_init+0x75f>
f0101b06:	68 30 69 10 f0       	push   $0xf0106930
f0101b0b:	68 5b 70 10 f0       	push   $0xf010705b
f0101b10:	68 3f 04 00 00       	push   $0x43f
f0101b15:	68 35 70 10 f0       	push   $0xf0107035
f0101b1a:	e8 21 e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b1f:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b24:	89 f8                	mov    %edi,%eax
f0101b26:	e8 fc ee ff ff       	call   f0100a27 <check_va2pa>
f0101b2b:	89 da                	mov    %ebx,%edx
f0101b2d:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101b30:	c1 fa 03             	sar    $0x3,%edx
f0101b33:	c1 e2 0c             	shl    $0xc,%edx
f0101b36:	39 d0                	cmp    %edx,%eax
f0101b38:	74 19                	je     f0101b53 <mem_init+0x793>
f0101b3a:	68 58 69 10 f0       	push   $0xf0106958
f0101b3f:	68 5b 70 10 f0       	push   $0xf010705b
f0101b44:	68 40 04 00 00       	push   $0x440
f0101b49:	68 35 70 10 f0       	push   $0xf0107035
f0101b4e:	e8 ed e4 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101b53:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b58:	74 19                	je     f0101b73 <mem_init+0x7b3>
f0101b5a:	68 4d 72 10 f0       	push   $0xf010724d
f0101b5f:	68 5b 70 10 f0       	push   $0xf010705b
f0101b64:	68 41 04 00 00       	push   $0x441
f0101b69:	68 35 70 10 f0       	push   $0xf0107035
f0101b6e:	e8 cd e4 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101b73:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b76:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b7b:	74 19                	je     f0101b96 <mem_init+0x7d6>
f0101b7d:	68 5e 72 10 f0       	push   $0xf010725e
f0101b82:	68 5b 70 10 f0       	push   $0xf010705b
f0101b87:	68 42 04 00 00       	push   $0x442
f0101b8c:	68 35 70 10 f0       	push   $0xf0107035
f0101b91:	e8 aa e4 ff ff       	call   f0100040 <_panic>
	
	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b96:	6a 02                	push   $0x2
f0101b98:	68 00 10 00 00       	push   $0x1000
f0101b9d:	56                   	push   %esi
f0101b9e:	57                   	push   %edi
f0101b9f:	e8 24 f7 ff ff       	call   f01012c8 <page_insert>
f0101ba4:	83 c4 10             	add    $0x10,%esp
f0101ba7:	85 c0                	test   %eax,%eax
f0101ba9:	74 19                	je     f0101bc4 <mem_init+0x804>
f0101bab:	68 88 69 10 f0       	push   $0xf0106988
f0101bb0:	68 5b 70 10 f0       	push   $0xf010705b
f0101bb5:	68 45 04 00 00       	push   $0x445
f0101bba:	68 35 70 10 f0       	push   $0xf0107035
f0101bbf:	e8 7c e4 ff ff       	call   f0100040 <_panic>

	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bc4:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bc9:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
f0101bce:	e8 54 ee ff ff       	call   f0100a27 <check_va2pa>
f0101bd3:	89 f2                	mov    %esi,%edx
f0101bd5:	2b 15 d0 0e 23 f0    	sub    0xf0230ed0,%edx
f0101bdb:	c1 fa 03             	sar    $0x3,%edx
f0101bde:	c1 e2 0c             	shl    $0xc,%edx
f0101be1:	39 d0                	cmp    %edx,%eax
f0101be3:	74 19                	je     f0101bfe <mem_init+0x83e>
f0101be5:	68 c4 69 10 f0       	push   $0xf01069c4
f0101bea:	68 5b 70 10 f0       	push   $0xf010705b
f0101bef:	68 47 04 00 00       	push   $0x447
f0101bf4:	68 35 70 10 f0       	push   $0xf0107035
f0101bf9:	e8 42 e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101bfe:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c03:	74 19                	je     f0101c1e <mem_init+0x85e>
f0101c05:	68 6f 72 10 f0       	push   $0xf010726f
f0101c0a:	68 5b 70 10 f0       	push   $0xf010705b
f0101c0f:	68 48 04 00 00       	push   $0x448
f0101c14:	68 35 70 10 f0       	push   $0xf0107035
f0101c19:	e8 22 e4 ff ff       	call   f0100040 <_panic>
	
	// should be no free memory
	assert(!page_alloc(0));
f0101c1e:	83 ec 0c             	sub    $0xc,%esp
f0101c21:	6a 00                	push   $0x0
f0101c23:	e8 7a f3 ff ff       	call   f0100fa2 <page_alloc>
f0101c28:	83 c4 10             	add    $0x10,%esp
f0101c2b:	85 c0                	test   %eax,%eax
f0101c2d:	74 19                	je     f0101c48 <mem_init+0x888>
f0101c2f:	68 fb 71 10 f0       	push   $0xf01071fb
f0101c34:	68 5b 70 10 f0       	push   $0xf010705b
f0101c39:	68 4b 04 00 00       	push   $0x44b
f0101c3e:	68 35 70 10 f0       	push   $0xf0107035
f0101c43:	e8 f8 e3 ff ff       	call   f0100040 <_panic>
	
	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c48:	6a 02                	push   $0x2
f0101c4a:	68 00 10 00 00       	push   $0x1000
f0101c4f:	56                   	push   %esi
f0101c50:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0101c56:	e8 6d f6 ff ff       	call   f01012c8 <page_insert>
f0101c5b:	83 c4 10             	add    $0x10,%esp
f0101c5e:	85 c0                	test   %eax,%eax
f0101c60:	74 19                	je     f0101c7b <mem_init+0x8bb>
f0101c62:	68 88 69 10 f0       	push   $0xf0106988
f0101c67:	68 5b 70 10 f0       	push   $0xf010705b
f0101c6c:	68 4e 04 00 00       	push   $0x44e
f0101c71:	68 35 70 10 f0       	push   $0xf0107035
f0101c76:	e8 c5 e3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c7b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c80:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
f0101c85:	e8 9d ed ff ff       	call   f0100a27 <check_va2pa>
f0101c8a:	89 f2                	mov    %esi,%edx
f0101c8c:	2b 15 d0 0e 23 f0    	sub    0xf0230ed0,%edx
f0101c92:	c1 fa 03             	sar    $0x3,%edx
f0101c95:	c1 e2 0c             	shl    $0xc,%edx
f0101c98:	39 d0                	cmp    %edx,%eax
f0101c9a:	74 19                	je     f0101cb5 <mem_init+0x8f5>
f0101c9c:	68 c4 69 10 f0       	push   $0xf01069c4
f0101ca1:	68 5b 70 10 f0       	push   $0xf010705b
f0101ca6:	68 4f 04 00 00       	push   $0x44f
f0101cab:	68 35 70 10 f0       	push   $0xf0107035
f0101cb0:	e8 8b e3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101cb5:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101cba:	74 19                	je     f0101cd5 <mem_init+0x915>
f0101cbc:	68 6f 72 10 f0       	push   $0xf010726f
f0101cc1:	68 5b 70 10 f0       	push   $0xf010705b
f0101cc6:	68 50 04 00 00       	push   $0x450
f0101ccb:	68 35 70 10 f0       	push   $0xf0107035
f0101cd0:	e8 6b e3 ff ff       	call   f0100040 <_panic>
	
	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101cd5:	83 ec 0c             	sub    $0xc,%esp
f0101cd8:	6a 00                	push   $0x0
f0101cda:	e8 c3 f2 ff ff       	call   f0100fa2 <page_alloc>
f0101cdf:	83 c4 10             	add    $0x10,%esp
f0101ce2:	85 c0                	test   %eax,%eax
f0101ce4:	74 19                	je     f0101cff <mem_init+0x93f>
f0101ce6:	68 fb 71 10 f0       	push   $0xf01071fb
f0101ceb:	68 5b 70 10 f0       	push   $0xf010705b
f0101cf0:	68 54 04 00 00       	push   $0x454
f0101cf5:	68 35 70 10 f0       	push   $0xf0107035
f0101cfa:	e8 41 e3 ff ff       	call   f0100040 <_panic>
	
	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101cff:	8b 15 cc 0e 23 f0    	mov    0xf0230ecc,%edx
f0101d05:	8b 02                	mov    (%edx),%eax
f0101d07:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101d0c:	89 c1                	mov    %eax,%ecx
f0101d0e:	c1 e9 0c             	shr    $0xc,%ecx
f0101d11:	3b 0d c8 0e 23 f0    	cmp    0xf0230ec8,%ecx
f0101d17:	72 15                	jb     f0101d2e <mem_init+0x96e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d19:	50                   	push   %eax
f0101d1a:	68 a4 60 10 f0       	push   $0xf01060a4
f0101d1f:	68 57 04 00 00       	push   $0x457
f0101d24:	68 35 70 10 f0       	push   $0xf0107035
f0101d29:	e8 12 e3 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101d2e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d33:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d36:	83 ec 04             	sub    $0x4,%esp
f0101d39:	6a 00                	push   $0x0
f0101d3b:	68 00 10 00 00       	push   $0x1000
f0101d40:	52                   	push   %edx
f0101d41:	e8 4a f3 ff ff       	call   f0101090 <pgdir_walk>
f0101d46:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101d49:	8d 51 04             	lea    0x4(%ecx),%edx
f0101d4c:	83 c4 10             	add    $0x10,%esp
f0101d4f:	39 d0                	cmp    %edx,%eax
f0101d51:	74 19                	je     f0101d6c <mem_init+0x9ac>
f0101d53:	68 f4 69 10 f0       	push   $0xf01069f4
f0101d58:	68 5b 70 10 f0       	push   $0xf010705b
f0101d5d:	68 58 04 00 00       	push   $0x458
f0101d62:	68 35 70 10 f0       	push   $0xf0107035
f0101d67:	e8 d4 e2 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101d6c:	6a 06                	push   $0x6
f0101d6e:	68 00 10 00 00       	push   $0x1000
f0101d73:	56                   	push   %esi
f0101d74:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0101d7a:	e8 49 f5 ff ff       	call   f01012c8 <page_insert>
f0101d7f:	83 c4 10             	add    $0x10,%esp
f0101d82:	85 c0                	test   %eax,%eax
f0101d84:	74 19                	je     f0101d9f <mem_init+0x9df>
f0101d86:	68 34 6a 10 f0       	push   $0xf0106a34
f0101d8b:	68 5b 70 10 f0       	push   $0xf010705b
f0101d90:	68 5b 04 00 00       	push   $0x45b
f0101d95:	68 35 70 10 f0       	push   $0xf0107035
f0101d9a:	e8 a1 e2 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d9f:	8b 3d cc 0e 23 f0    	mov    0xf0230ecc,%edi
f0101da5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101daa:	89 f8                	mov    %edi,%eax
f0101dac:	e8 76 ec ff ff       	call   f0100a27 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101db1:	89 f2                	mov    %esi,%edx
f0101db3:	2b 15 d0 0e 23 f0    	sub    0xf0230ed0,%edx
f0101db9:	c1 fa 03             	sar    $0x3,%edx
f0101dbc:	c1 e2 0c             	shl    $0xc,%edx
f0101dbf:	39 d0                	cmp    %edx,%eax
f0101dc1:	74 19                	je     f0101ddc <mem_init+0xa1c>
f0101dc3:	68 c4 69 10 f0       	push   $0xf01069c4
f0101dc8:	68 5b 70 10 f0       	push   $0xf010705b
f0101dcd:	68 5c 04 00 00       	push   $0x45c
f0101dd2:	68 35 70 10 f0       	push   $0xf0107035
f0101dd7:	e8 64 e2 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101ddc:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101de1:	74 19                	je     f0101dfc <mem_init+0xa3c>
f0101de3:	68 6f 72 10 f0       	push   $0xf010726f
f0101de8:	68 5b 70 10 f0       	push   $0xf010705b
f0101ded:	68 5d 04 00 00       	push   $0x45d
f0101df2:	68 35 70 10 f0       	push   $0xf0107035
f0101df7:	e8 44 e2 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101dfc:	83 ec 04             	sub    $0x4,%esp
f0101dff:	6a 00                	push   $0x0
f0101e01:	68 00 10 00 00       	push   $0x1000
f0101e06:	57                   	push   %edi
f0101e07:	e8 84 f2 ff ff       	call   f0101090 <pgdir_walk>
f0101e0c:	83 c4 10             	add    $0x10,%esp
f0101e0f:	f6 00 04             	testb  $0x4,(%eax)
f0101e12:	75 19                	jne    f0101e2d <mem_init+0xa6d>
f0101e14:	68 74 6a 10 f0       	push   $0xf0106a74
f0101e19:	68 5b 70 10 f0       	push   $0xf010705b
f0101e1e:	68 5e 04 00 00       	push   $0x45e
f0101e23:	68 35 70 10 f0       	push   $0xf0107035
f0101e28:	e8 13 e2 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101e2d:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
f0101e32:	f6 00 04             	testb  $0x4,(%eax)
f0101e35:	75 19                	jne    f0101e50 <mem_init+0xa90>
f0101e37:	68 80 72 10 f0       	push   $0xf0107280
f0101e3c:	68 5b 70 10 f0       	push   $0xf010705b
f0101e41:	68 5f 04 00 00       	push   $0x45f
f0101e46:	68 35 70 10 f0       	push   $0xf0107035
f0101e4b:	e8 f0 e1 ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e50:	6a 02                	push   $0x2
f0101e52:	68 00 10 00 00       	push   $0x1000
f0101e57:	56                   	push   %esi
f0101e58:	50                   	push   %eax
f0101e59:	e8 6a f4 ff ff       	call   f01012c8 <page_insert>
f0101e5e:	83 c4 10             	add    $0x10,%esp
f0101e61:	85 c0                	test   %eax,%eax
f0101e63:	74 19                	je     f0101e7e <mem_init+0xabe>
f0101e65:	68 88 69 10 f0       	push   $0xf0106988
f0101e6a:	68 5b 70 10 f0       	push   $0xf010705b
f0101e6f:	68 62 04 00 00       	push   $0x462
f0101e74:	68 35 70 10 f0       	push   $0xf0107035
f0101e79:	e8 c2 e1 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101e7e:	83 ec 04             	sub    $0x4,%esp
f0101e81:	6a 00                	push   $0x0
f0101e83:	68 00 10 00 00       	push   $0x1000
f0101e88:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0101e8e:	e8 fd f1 ff ff       	call   f0101090 <pgdir_walk>
f0101e93:	83 c4 10             	add    $0x10,%esp
f0101e96:	f6 00 02             	testb  $0x2,(%eax)
f0101e99:	75 19                	jne    f0101eb4 <mem_init+0xaf4>
f0101e9b:	68 a8 6a 10 f0       	push   $0xf0106aa8
f0101ea0:	68 5b 70 10 f0       	push   $0xf010705b
f0101ea5:	68 63 04 00 00       	push   $0x463
f0101eaa:	68 35 70 10 f0       	push   $0xf0107035
f0101eaf:	e8 8c e1 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101eb4:	83 ec 04             	sub    $0x4,%esp
f0101eb7:	6a 00                	push   $0x0
f0101eb9:	68 00 10 00 00       	push   $0x1000
f0101ebe:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0101ec4:	e8 c7 f1 ff ff       	call   f0101090 <pgdir_walk>
f0101ec9:	83 c4 10             	add    $0x10,%esp
f0101ecc:	f6 00 04             	testb  $0x4,(%eax)
f0101ecf:	74 19                	je     f0101eea <mem_init+0xb2a>
f0101ed1:	68 dc 6a 10 f0       	push   $0xf0106adc
f0101ed6:	68 5b 70 10 f0       	push   $0xf010705b
f0101edb:	68 64 04 00 00       	push   $0x464
f0101ee0:	68 35 70 10 f0       	push   $0xf0107035
f0101ee5:	e8 56 e1 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101eea:	6a 02                	push   $0x2
f0101eec:	68 00 00 40 00       	push   $0x400000
f0101ef1:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101ef4:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0101efa:	e8 c9 f3 ff ff       	call   f01012c8 <page_insert>
f0101eff:	83 c4 10             	add    $0x10,%esp
f0101f02:	85 c0                	test   %eax,%eax
f0101f04:	78 19                	js     f0101f1f <mem_init+0xb5f>
f0101f06:	68 14 6b 10 f0       	push   $0xf0106b14
f0101f0b:	68 5b 70 10 f0       	push   $0xf010705b
f0101f10:	68 67 04 00 00       	push   $0x467
f0101f15:	68 35 70 10 f0       	push   $0xf0107035
f0101f1a:	e8 21 e1 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101f1f:	6a 02                	push   $0x2
f0101f21:	68 00 10 00 00       	push   $0x1000
f0101f26:	53                   	push   %ebx
f0101f27:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0101f2d:	e8 96 f3 ff ff       	call   f01012c8 <page_insert>
f0101f32:	83 c4 10             	add    $0x10,%esp
f0101f35:	85 c0                	test   %eax,%eax
f0101f37:	74 19                	je     f0101f52 <mem_init+0xb92>
f0101f39:	68 4c 6b 10 f0       	push   $0xf0106b4c
f0101f3e:	68 5b 70 10 f0       	push   $0xf010705b
f0101f43:	68 6a 04 00 00       	push   $0x46a
f0101f48:	68 35 70 10 f0       	push   $0xf0107035
f0101f4d:	e8 ee e0 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f52:	83 ec 04             	sub    $0x4,%esp
f0101f55:	6a 00                	push   $0x0
f0101f57:	68 00 10 00 00       	push   $0x1000
f0101f5c:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0101f62:	e8 29 f1 ff ff       	call   f0101090 <pgdir_walk>
f0101f67:	83 c4 10             	add    $0x10,%esp
f0101f6a:	f6 00 04             	testb  $0x4,(%eax)
f0101f6d:	74 19                	je     f0101f88 <mem_init+0xbc8>
f0101f6f:	68 dc 6a 10 f0       	push   $0xf0106adc
f0101f74:	68 5b 70 10 f0       	push   $0xf010705b
f0101f79:	68 6b 04 00 00       	push   $0x46b
f0101f7e:	68 35 70 10 f0       	push   $0xf0107035
f0101f83:	e8 b8 e0 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101f88:	8b 3d cc 0e 23 f0    	mov    0xf0230ecc,%edi
f0101f8e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f93:	89 f8                	mov    %edi,%eax
f0101f95:	e8 8d ea ff ff       	call   f0100a27 <check_va2pa>
f0101f9a:	89 c1                	mov    %eax,%ecx
f0101f9c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f9f:	89 d8                	mov    %ebx,%eax
f0101fa1:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f0101fa7:	c1 f8 03             	sar    $0x3,%eax
f0101faa:	c1 e0 0c             	shl    $0xc,%eax
f0101fad:	39 c1                	cmp    %eax,%ecx
f0101faf:	74 19                	je     f0101fca <mem_init+0xc0a>
f0101fb1:	68 88 6b 10 f0       	push   $0xf0106b88
f0101fb6:	68 5b 70 10 f0       	push   $0xf010705b
f0101fbb:	68 6e 04 00 00       	push   $0x46e
f0101fc0:	68 35 70 10 f0       	push   $0xf0107035
f0101fc5:	e8 76 e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101fca:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fcf:	89 f8                	mov    %edi,%eax
f0101fd1:	e8 51 ea ff ff       	call   f0100a27 <check_va2pa>
f0101fd6:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101fd9:	74 19                	je     f0101ff4 <mem_init+0xc34>
f0101fdb:	68 b4 6b 10 f0       	push   $0xf0106bb4
f0101fe0:	68 5b 70 10 f0       	push   $0xf010705b
f0101fe5:	68 6f 04 00 00       	push   $0x46f
f0101fea:	68 35 70 10 f0       	push   $0xf0107035
f0101fef:	e8 4c e0 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101ff4:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101ff9:	74 19                	je     f0102014 <mem_init+0xc54>
f0101ffb:	68 96 72 10 f0       	push   $0xf0107296
f0102000:	68 5b 70 10 f0       	push   $0xf010705b
f0102005:	68 71 04 00 00       	push   $0x471
f010200a:	68 35 70 10 f0       	push   $0xf0107035
f010200f:	e8 2c e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102014:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102019:	74 19                	je     f0102034 <mem_init+0xc74>
f010201b:	68 a7 72 10 f0       	push   $0xf01072a7
f0102020:	68 5b 70 10 f0       	push   $0xf010705b
f0102025:	68 72 04 00 00       	push   $0x472
f010202a:	68 35 70 10 f0       	push   $0xf0107035
f010202f:	e8 0c e0 ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102034:	83 ec 0c             	sub    $0xc,%esp
f0102037:	6a 00                	push   $0x0
f0102039:	e8 64 ef ff ff       	call   f0100fa2 <page_alloc>
f010203e:	83 c4 10             	add    $0x10,%esp
f0102041:	85 c0                	test   %eax,%eax
f0102043:	74 04                	je     f0102049 <mem_init+0xc89>
f0102045:	39 c6                	cmp    %eax,%esi
f0102047:	74 19                	je     f0102062 <mem_init+0xca2>
f0102049:	68 e4 6b 10 f0       	push   $0xf0106be4
f010204e:	68 5b 70 10 f0       	push   $0xf010705b
f0102053:	68 75 04 00 00       	push   $0x475
f0102058:	68 35 70 10 f0       	push   $0xf0107035
f010205d:	e8 de df ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102062:	83 ec 08             	sub    $0x8,%esp
f0102065:	6a 00                	push   $0x0
f0102067:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f010206d:	e8 10 f2 ff ff       	call   f0101282 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102072:	8b 3d cc 0e 23 f0    	mov    0xf0230ecc,%edi
f0102078:	ba 00 00 00 00       	mov    $0x0,%edx
f010207d:	89 f8                	mov    %edi,%eax
f010207f:	e8 a3 e9 ff ff       	call   f0100a27 <check_va2pa>
f0102084:	83 c4 10             	add    $0x10,%esp
f0102087:	83 f8 ff             	cmp    $0xffffffff,%eax
f010208a:	74 19                	je     f01020a5 <mem_init+0xce5>
f010208c:	68 08 6c 10 f0       	push   $0xf0106c08
f0102091:	68 5b 70 10 f0       	push   $0xf010705b
f0102096:	68 79 04 00 00       	push   $0x479
f010209b:	68 35 70 10 f0       	push   $0xf0107035
f01020a0:	e8 9b df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01020a5:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020aa:	89 f8                	mov    %edi,%eax
f01020ac:	e8 76 e9 ff ff       	call   f0100a27 <check_va2pa>
f01020b1:	89 da                	mov    %ebx,%edx
f01020b3:	2b 15 d0 0e 23 f0    	sub    0xf0230ed0,%edx
f01020b9:	c1 fa 03             	sar    $0x3,%edx
f01020bc:	c1 e2 0c             	shl    $0xc,%edx
f01020bf:	39 d0                	cmp    %edx,%eax
f01020c1:	74 19                	je     f01020dc <mem_init+0xd1c>
f01020c3:	68 b4 6b 10 f0       	push   $0xf0106bb4
f01020c8:	68 5b 70 10 f0       	push   $0xf010705b
f01020cd:	68 7a 04 00 00       	push   $0x47a
f01020d2:	68 35 70 10 f0       	push   $0xf0107035
f01020d7:	e8 64 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f01020dc:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01020e1:	74 19                	je     f01020fc <mem_init+0xd3c>
f01020e3:	68 4d 72 10 f0       	push   $0xf010724d
f01020e8:	68 5b 70 10 f0       	push   $0xf010705b
f01020ed:	68 7b 04 00 00       	push   $0x47b
f01020f2:	68 35 70 10 f0       	push   $0xf0107035
f01020f7:	e8 44 df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01020fc:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102101:	74 19                	je     f010211c <mem_init+0xd5c>
f0102103:	68 a7 72 10 f0       	push   $0xf01072a7
f0102108:	68 5b 70 10 f0       	push   $0xf010705b
f010210d:	68 7c 04 00 00       	push   $0x47c
f0102112:	68 35 70 10 f0       	push   $0xf0107035
f0102117:	e8 24 df ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f010211c:	6a 00                	push   $0x0
f010211e:	68 00 10 00 00       	push   $0x1000
f0102123:	53                   	push   %ebx
f0102124:	57                   	push   %edi
f0102125:	e8 9e f1 ff ff       	call   f01012c8 <page_insert>
f010212a:	83 c4 10             	add    $0x10,%esp
f010212d:	85 c0                	test   %eax,%eax
f010212f:	74 19                	je     f010214a <mem_init+0xd8a>
f0102131:	68 2c 6c 10 f0       	push   $0xf0106c2c
f0102136:	68 5b 70 10 f0       	push   $0xf010705b
f010213b:	68 7f 04 00 00       	push   $0x47f
f0102140:	68 35 70 10 f0       	push   $0xf0107035
f0102145:	e8 f6 de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f010214a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010214f:	75 19                	jne    f010216a <mem_init+0xdaa>
f0102151:	68 b8 72 10 f0       	push   $0xf01072b8
f0102156:	68 5b 70 10 f0       	push   $0xf010705b
f010215b:	68 80 04 00 00       	push   $0x480
f0102160:	68 35 70 10 f0       	push   $0xf0107035
f0102165:	e8 d6 de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f010216a:	83 3b 00             	cmpl   $0x0,(%ebx)
f010216d:	74 19                	je     f0102188 <mem_init+0xdc8>
f010216f:	68 c4 72 10 f0       	push   $0xf01072c4
f0102174:	68 5b 70 10 f0       	push   $0xf010705b
f0102179:	68 81 04 00 00       	push   $0x481
f010217e:	68 35 70 10 f0       	push   $0xf0107035
f0102183:	e8 b8 de ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102188:	83 ec 08             	sub    $0x8,%esp
f010218b:	68 00 10 00 00       	push   $0x1000
f0102190:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0102196:	e8 e7 f0 ff ff       	call   f0101282 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010219b:	8b 3d cc 0e 23 f0    	mov    0xf0230ecc,%edi
f01021a1:	ba 00 00 00 00       	mov    $0x0,%edx
f01021a6:	89 f8                	mov    %edi,%eax
f01021a8:	e8 7a e8 ff ff       	call   f0100a27 <check_va2pa>
f01021ad:	83 c4 10             	add    $0x10,%esp
f01021b0:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021b3:	74 19                	je     f01021ce <mem_init+0xe0e>
f01021b5:	68 08 6c 10 f0       	push   $0xf0106c08
f01021ba:	68 5b 70 10 f0       	push   $0xf010705b
f01021bf:	68 85 04 00 00       	push   $0x485
f01021c4:	68 35 70 10 f0       	push   $0xf0107035
f01021c9:	e8 72 de ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01021ce:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021d3:	89 f8                	mov    %edi,%eax
f01021d5:	e8 4d e8 ff ff       	call   f0100a27 <check_va2pa>
f01021da:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021dd:	74 19                	je     f01021f8 <mem_init+0xe38>
f01021df:	68 64 6c 10 f0       	push   $0xf0106c64
f01021e4:	68 5b 70 10 f0       	push   $0xf010705b
f01021e9:	68 86 04 00 00       	push   $0x486
f01021ee:	68 35 70 10 f0       	push   $0xf0107035
f01021f3:	e8 48 de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f01021f8:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01021fd:	74 19                	je     f0102218 <mem_init+0xe58>
f01021ff:	68 d9 72 10 f0       	push   $0xf01072d9
f0102204:	68 5b 70 10 f0       	push   $0xf010705b
f0102209:	68 87 04 00 00       	push   $0x487
f010220e:	68 35 70 10 f0       	push   $0xf0107035
f0102213:	e8 28 de ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102218:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010221d:	74 19                	je     f0102238 <mem_init+0xe78>
f010221f:	68 a7 72 10 f0       	push   $0xf01072a7
f0102224:	68 5b 70 10 f0       	push   $0xf010705b
f0102229:	68 88 04 00 00       	push   $0x488
f010222e:	68 35 70 10 f0       	push   $0xf0107035
f0102233:	e8 08 de ff ff       	call   f0100040 <_panic>
	
	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102238:	83 ec 0c             	sub    $0xc,%esp
f010223b:	6a 00                	push   $0x0
f010223d:	e8 60 ed ff ff       	call   f0100fa2 <page_alloc>
f0102242:	83 c4 10             	add    $0x10,%esp
f0102245:	85 c0                	test   %eax,%eax
f0102247:	74 04                	je     f010224d <mem_init+0xe8d>
f0102249:	39 c3                	cmp    %eax,%ebx
f010224b:	74 19                	je     f0102266 <mem_init+0xea6>
f010224d:	68 8c 6c 10 f0       	push   $0xf0106c8c
f0102252:	68 5b 70 10 f0       	push   $0xf010705b
f0102257:	68 8b 04 00 00       	push   $0x48b
f010225c:	68 35 70 10 f0       	push   $0xf0107035
f0102261:	e8 da dd ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102266:	83 ec 0c             	sub    $0xc,%esp
f0102269:	6a 00                	push   $0x0
f010226b:	e8 32 ed ff ff       	call   f0100fa2 <page_alloc>
f0102270:	83 c4 10             	add    $0x10,%esp
f0102273:	85 c0                	test   %eax,%eax
f0102275:	74 19                	je     f0102290 <mem_init+0xed0>
f0102277:	68 fb 71 10 f0       	push   $0xf01071fb
f010227c:	68 5b 70 10 f0       	push   $0xf010705b
f0102281:	68 8e 04 00 00       	push   $0x48e
f0102286:	68 35 70 10 f0       	push   $0xf0107035
f010228b:	e8 b0 dd ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102290:	8b 0d cc 0e 23 f0    	mov    0xf0230ecc,%ecx
f0102296:	8b 11                	mov    (%ecx),%edx
f0102298:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010229e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022a1:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f01022a7:	c1 f8 03             	sar    $0x3,%eax
f01022aa:	c1 e0 0c             	shl    $0xc,%eax
f01022ad:	39 c2                	cmp    %eax,%edx
f01022af:	74 19                	je     f01022ca <mem_init+0xf0a>
f01022b1:	68 30 69 10 f0       	push   $0xf0106930
f01022b6:	68 5b 70 10 f0       	push   $0xf010705b
f01022bb:	68 91 04 00 00       	push   $0x491
f01022c0:	68 35 70 10 f0       	push   $0xf0107035
f01022c5:	e8 76 dd ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f01022ca:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01022d0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022d3:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01022d8:	74 19                	je     f01022f3 <mem_init+0xf33>
f01022da:	68 5e 72 10 f0       	push   $0xf010725e
f01022df:	68 5b 70 10 f0       	push   $0xf010705b
f01022e4:	68 93 04 00 00       	push   $0x493
f01022e9:	68 35 70 10 f0       	push   $0xf0107035
f01022ee:	e8 4d dd ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f01022f3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022f6:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01022fc:	83 ec 0c             	sub    $0xc,%esp
f01022ff:	50                   	push   %eax
f0102300:	e8 13 ed ff ff       	call   f0101018 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102305:	83 c4 0c             	add    $0xc,%esp
f0102308:	6a 01                	push   $0x1
f010230a:	68 00 10 40 00       	push   $0x401000
f010230f:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0102315:	e8 76 ed ff ff       	call   f0101090 <pgdir_walk>
f010231a:	89 c7                	mov    %eax,%edi
f010231c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010231f:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
f0102324:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102327:	8b 40 04             	mov    0x4(%eax),%eax
f010232a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010232f:	8b 0d c8 0e 23 f0    	mov    0xf0230ec8,%ecx
f0102335:	89 c2                	mov    %eax,%edx
f0102337:	c1 ea 0c             	shr    $0xc,%edx
f010233a:	83 c4 10             	add    $0x10,%esp
f010233d:	39 ca                	cmp    %ecx,%edx
f010233f:	72 15                	jb     f0102356 <mem_init+0xf96>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102341:	50                   	push   %eax
f0102342:	68 a4 60 10 f0       	push   $0xf01060a4
f0102347:	68 9a 04 00 00       	push   $0x49a
f010234c:	68 35 70 10 f0       	push   $0xf0107035
f0102351:	e8 ea dc ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102356:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f010235b:	39 c7                	cmp    %eax,%edi
f010235d:	74 19                	je     f0102378 <mem_init+0xfb8>
f010235f:	68 ea 72 10 f0       	push   $0xf01072ea
f0102364:	68 5b 70 10 f0       	push   $0xf010705b
f0102369:	68 9b 04 00 00       	push   $0x49b
f010236e:	68 35 70 10 f0       	push   $0xf0107035
f0102373:	e8 c8 dc ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102378:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010237b:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102382:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102385:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010238b:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f0102391:	c1 f8 03             	sar    $0x3,%eax
f0102394:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102397:	89 c2                	mov    %eax,%edx
f0102399:	c1 ea 0c             	shr    $0xc,%edx
f010239c:	39 d1                	cmp    %edx,%ecx
f010239e:	77 12                	ja     f01023b2 <mem_init+0xff2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01023a0:	50                   	push   %eax
f01023a1:	68 a4 60 10 f0       	push   $0xf01060a4
f01023a6:	6a 58                	push   $0x58
f01023a8:	68 41 70 10 f0       	push   $0xf0107041
f01023ad:	e8 8e dc ff ff       	call   f0100040 <_panic>
	
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01023b2:	83 ec 04             	sub    $0x4,%esp
f01023b5:	68 00 10 00 00       	push   $0x1000
f01023ba:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f01023bf:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01023c4:	50                   	push   %eax
f01023c5:	e8 e8 2f 00 00       	call   f01053b2 <memset>
	page_free(pp0);
f01023ca:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01023cd:	89 3c 24             	mov    %edi,(%esp)
f01023d0:	e8 43 ec ff ff       	call   f0101018 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01023d5:	83 c4 0c             	add    $0xc,%esp
f01023d8:	6a 01                	push   $0x1
f01023da:	6a 00                	push   $0x0
f01023dc:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f01023e2:	e8 a9 ec ff ff       	call   f0101090 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01023e7:	89 fa                	mov    %edi,%edx
f01023e9:	2b 15 d0 0e 23 f0    	sub    0xf0230ed0,%edx
f01023ef:	c1 fa 03             	sar    $0x3,%edx
f01023f2:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01023f5:	89 d0                	mov    %edx,%eax
f01023f7:	c1 e8 0c             	shr    $0xc,%eax
f01023fa:	83 c4 10             	add    $0x10,%esp
f01023fd:	3b 05 c8 0e 23 f0    	cmp    0xf0230ec8,%eax
f0102403:	72 12                	jb     f0102417 <mem_init+0x1057>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102405:	52                   	push   %edx
f0102406:	68 a4 60 10 f0       	push   $0xf01060a4
f010240b:	6a 58                	push   $0x58
f010240d:	68 41 70 10 f0       	push   $0xf0107041
f0102412:	e8 29 dc ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102417:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010241d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102420:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102426:	f6 00 01             	testb  $0x1,(%eax)
f0102429:	74 19                	je     f0102444 <mem_init+0x1084>
f010242b:	68 02 73 10 f0       	push   $0xf0107302
f0102430:	68 5b 70 10 f0       	push   $0xf010705b
f0102435:	68 a5 04 00 00       	push   $0x4a5
f010243a:	68 35 70 10 f0       	push   $0xf0107035
f010243f:	e8 fc db ff ff       	call   f0100040 <_panic>
f0102444:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102447:	39 d0                	cmp    %edx,%eax
f0102449:	75 db                	jne    f0102426 <mem_init+0x1066>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010244b:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
f0102450:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102456:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102459:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010245f:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102462:	89 0d 64 02 23 f0    	mov    %ecx,0xf0230264

	// free the pages we took
	page_free(pp0);
f0102468:	83 ec 0c             	sub    $0xc,%esp
f010246b:	50                   	push   %eax
f010246c:	e8 a7 eb ff ff       	call   f0101018 <page_free>
	page_free(pp1);
f0102471:	89 1c 24             	mov    %ebx,(%esp)
f0102474:	e8 9f eb ff ff       	call   f0101018 <page_free>
	page_free(pp2);
f0102479:	89 34 24             	mov    %esi,(%esp)
f010247c:	e8 97 eb ff ff       	call   f0101018 <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f0102481:	83 c4 08             	add    $0x8,%esp
f0102484:	68 01 10 00 00       	push   $0x1001
f0102489:	6a 00                	push   $0x0
f010248b:	e8 f1 ee ff ff       	call   f0101381 <mmio_map_region>
f0102490:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f0102492:	83 c4 08             	add    $0x8,%esp
f0102495:	68 00 10 00 00       	push   $0x1000
f010249a:	6a 00                	push   $0x0
f010249c:	e8 e0 ee ff ff       	call   f0101381 <mmio_map_region>
f01024a1:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f01024a3:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f01024a9:	83 c4 10             	add    $0x10,%esp
f01024ac:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f01024b1:	77 08                	ja     f01024bb <mem_init+0x10fb>
f01024b3:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f01024b9:	77 19                	ja     f01024d4 <mem_init+0x1114>
f01024bb:	68 b0 6c 10 f0       	push   $0xf0106cb0
f01024c0:	68 5b 70 10 f0       	push   $0xf010705b
f01024c5:	68 b5 04 00 00       	push   $0x4b5
f01024ca:	68 35 70 10 f0       	push   $0xf0107035
f01024cf:	e8 6c db ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f01024d4:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f01024da:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f01024e0:	77 08                	ja     f01024ea <mem_init+0x112a>
f01024e2:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01024e8:	77 19                	ja     f0102503 <mem_init+0x1143>
f01024ea:	68 d8 6c 10 f0       	push   $0xf0106cd8
f01024ef:	68 5b 70 10 f0       	push   $0xf010705b
f01024f4:	68 b6 04 00 00       	push   $0x4b6
f01024f9:	68 35 70 10 f0       	push   $0xf0107035
f01024fe:	e8 3d db ff ff       	call   f0100040 <_panic>
f0102503:	89 da                	mov    %ebx,%edx
f0102505:	09 f2                	or     %esi,%edx
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102507:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f010250d:	74 19                	je     f0102528 <mem_init+0x1168>
f010250f:	68 00 6d 10 f0       	push   $0xf0106d00
f0102514:	68 5b 70 10 f0       	push   $0xf010705b
f0102519:	68 b8 04 00 00       	push   $0x4b8
f010251e:	68 35 70 10 f0       	push   $0xf0107035
f0102523:	e8 18 db ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f0102528:	39 c6                	cmp    %eax,%esi
f010252a:	73 19                	jae    f0102545 <mem_init+0x1185>
f010252c:	68 19 73 10 f0       	push   $0xf0107319
f0102531:	68 5b 70 10 f0       	push   $0xf010705b
f0102536:	68 ba 04 00 00       	push   $0x4ba
f010253b:	68 35 70 10 f0       	push   $0xf0107035
f0102540:	e8 fb da ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102545:	8b 3d cc 0e 23 f0    	mov    0xf0230ecc,%edi
f010254b:	89 da                	mov    %ebx,%edx
f010254d:	89 f8                	mov    %edi,%eax
f010254f:	e8 d3 e4 ff ff       	call   f0100a27 <check_va2pa>
f0102554:	85 c0                	test   %eax,%eax
f0102556:	74 19                	je     f0102571 <mem_init+0x11b1>
f0102558:	68 28 6d 10 f0       	push   $0xf0106d28
f010255d:	68 5b 70 10 f0       	push   $0xf010705b
f0102562:	68 bc 04 00 00       	push   $0x4bc
f0102567:	68 35 70 10 f0       	push   $0xf0107035
f010256c:	e8 cf da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102571:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0102577:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010257a:	89 c2                	mov    %eax,%edx
f010257c:	89 f8                	mov    %edi,%eax
f010257e:	e8 a4 e4 ff ff       	call   f0100a27 <check_va2pa>
f0102583:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102588:	74 19                	je     f01025a3 <mem_init+0x11e3>
f010258a:	68 4c 6d 10 f0       	push   $0xf0106d4c
f010258f:	68 5b 70 10 f0       	push   $0xf010705b
f0102594:	68 bd 04 00 00       	push   $0x4bd
f0102599:	68 35 70 10 f0       	push   $0xf0107035
f010259e:	e8 9d da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f01025a3:	89 f2                	mov    %esi,%edx
f01025a5:	89 f8                	mov    %edi,%eax
f01025a7:	e8 7b e4 ff ff       	call   f0100a27 <check_va2pa>
f01025ac:	85 c0                	test   %eax,%eax
f01025ae:	74 19                	je     f01025c9 <mem_init+0x1209>
f01025b0:	68 7c 6d 10 f0       	push   $0xf0106d7c
f01025b5:	68 5b 70 10 f0       	push   $0xf010705b
f01025ba:	68 be 04 00 00       	push   $0x4be
f01025bf:	68 35 70 10 f0       	push   $0xf0107035
f01025c4:	e8 77 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f01025c9:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f01025cf:	89 f8                	mov    %edi,%eax
f01025d1:	e8 51 e4 ff ff       	call   f0100a27 <check_va2pa>
f01025d6:	83 f8 ff             	cmp    $0xffffffff,%eax
f01025d9:	74 19                	je     f01025f4 <mem_init+0x1234>
f01025db:	68 a0 6d 10 f0       	push   $0xf0106da0
f01025e0:	68 5b 70 10 f0       	push   $0xf010705b
f01025e5:	68 bf 04 00 00       	push   $0x4bf
f01025ea:	68 35 70 10 f0       	push   $0xf0107035
f01025ef:	e8 4c da ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f01025f4:	83 ec 04             	sub    $0x4,%esp
f01025f7:	6a 00                	push   $0x0
f01025f9:	53                   	push   %ebx
f01025fa:	57                   	push   %edi
f01025fb:	e8 90 ea ff ff       	call   f0101090 <pgdir_walk>
f0102600:	83 c4 10             	add    $0x10,%esp
f0102603:	f6 00 1a             	testb  $0x1a,(%eax)
f0102606:	75 19                	jne    f0102621 <mem_init+0x1261>
f0102608:	68 cc 6d 10 f0       	push   $0xf0106dcc
f010260d:	68 5b 70 10 f0       	push   $0xf010705b
f0102612:	68 c1 04 00 00       	push   $0x4c1
f0102617:	68 35 70 10 f0       	push   $0xf0107035
f010261c:	e8 1f da ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102621:	83 ec 04             	sub    $0x4,%esp
f0102624:	6a 00                	push   $0x0
f0102626:	53                   	push   %ebx
f0102627:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f010262d:	e8 5e ea ff ff       	call   f0101090 <pgdir_walk>
f0102632:	83 c4 10             	add    $0x10,%esp
f0102635:	f6 00 04             	testb  $0x4,(%eax)
f0102638:	74 19                	je     f0102653 <mem_init+0x1293>
f010263a:	68 10 6e 10 f0       	push   $0xf0106e10
f010263f:	68 5b 70 10 f0       	push   $0xf010705b
f0102644:	68 c2 04 00 00       	push   $0x4c2
f0102649:	68 35 70 10 f0       	push   $0xf0107035
f010264e:	e8 ed d9 ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f0102653:	83 ec 04             	sub    $0x4,%esp
f0102656:	6a 00                	push   $0x0
f0102658:	53                   	push   %ebx
f0102659:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f010265f:	e8 2c ea ff ff       	call   f0101090 <pgdir_walk>
f0102664:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f010266a:	83 c4 0c             	add    $0xc,%esp
f010266d:	6a 00                	push   $0x0
f010266f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102672:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0102678:	e8 13 ea ff ff       	call   f0101090 <pgdir_walk>
f010267d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f0102683:	83 c4 0c             	add    $0xc,%esp
f0102686:	6a 00                	push   $0x0
f0102688:	56                   	push   %esi
f0102689:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f010268f:	e8 fc e9 ff ff       	call   f0101090 <pgdir_walk>
f0102694:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f010269a:	c7 04 24 2b 73 10 f0 	movl   $0xf010732b,(%esp)
f01026a1:	e8 b4 11 00 00       	call   f010385a <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, ROUNDUP( (sizeof(struct PageInfo)*npages),PGSIZE), PADDR(pages), PTE_U | PTE_P);
f01026a6:	a1 d0 0e 23 f0       	mov    0xf0230ed0,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026ab:	83 c4 10             	add    $0x10,%esp
f01026ae:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01026b3:	77 15                	ja     f01026ca <mem_init+0x130a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026b5:	50                   	push   %eax
f01026b6:	68 c8 60 10 f0       	push   $0xf01060c8
f01026bb:	68 c5 00 00 00       	push   $0xc5
f01026c0:	68 35 70 10 f0       	push   $0xf0107035
f01026c5:	e8 76 d9 ff ff       	call   f0100040 <_panic>
f01026ca:	8b 15 c8 0e 23 f0    	mov    0xf0230ec8,%edx
f01026d0:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f01026d7:	83 ec 08             	sub    $0x8,%esp
f01026da:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01026e0:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f01026e2:	05 00 00 00 10       	add    $0x10000000,%eax
f01026e7:	50                   	push   %eax
f01026e8:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01026ed:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
f01026f2:	e8 84 ea ff ff       	call   f010117b <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, sizeof(struct Env) * NENV,PADDR(envs), PTE_U);
f01026f7:	a1 6c 02 23 f0       	mov    0xf023026c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026fc:	83 c4 10             	add    $0x10,%esp
f01026ff:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102704:	77 15                	ja     f010271b <mem_init+0x135b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102706:	50                   	push   %eax
f0102707:	68 c8 60 10 f0       	push   $0xf01060c8
f010270c:	68 cd 00 00 00       	push   $0xcd
f0102711:	68 35 70 10 f0       	push   $0xf0107035
f0102716:	e8 25 d9 ff ff       	call   f0100040 <_panic>
f010271b:	83 ec 08             	sub    $0x8,%esp
f010271e:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f0102720:	05 00 00 00 10       	add    $0x10000000,%eax
f0102725:	50                   	push   %eax
f0102726:	b9 00 f0 01 00       	mov    $0x1f000,%ecx
f010272b:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102730:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
f0102735:	e8 41 ea ff ff       	call   f010117b <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010273a:	83 c4 10             	add    $0x10,%esp
f010273d:	b8 00 60 11 f0       	mov    $0xf0116000,%eax
f0102742:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102747:	77 15                	ja     f010275e <mem_init+0x139e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102749:	50                   	push   %eax
f010274a:	68 c8 60 10 f0       	push   $0xf01060c8
f010274f:	68 d9 00 00 00       	push   $0xd9
f0102754:	68 35 70 10 f0       	push   $0xf0107035
f0102759:	e8 e2 d8 ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W | PTE_P);
f010275e:	83 ec 08             	sub    $0x8,%esp
f0102761:	6a 03                	push   $0x3
f0102763:	68 00 60 11 00       	push   $0x116000
f0102768:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010276d:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102772:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
f0102777:	e8 ff e9 ff ff       	call   f010117b <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	size_t size = ROUNDUP(0xFFFFFFFF - KERNBASE + 1, PGSIZE);
	boot_map_region(kern_pgdir, KERNBASE, size, 0, PTE_W | PTE_P);
f010277c:	83 c4 08             	add    $0x8,%esp
f010277f:	6a 03                	push   $0x3
f0102781:	6a 00                	push   $0x0
f0102783:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102788:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010278d:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
f0102792:	e8 e4 e9 ff ff       	call   f010117b <boot_map_region>
f0102797:	c7 45 c4 00 20 23 f0 	movl   $0xf0232000,-0x3c(%ebp)
f010279e:	83 c4 10             	add    $0x10,%esp
f01027a1:	bb 00 20 23 f0       	mov    $0xf0232000,%ebx
f01027a6:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027ab:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f01027b1:	77 15                	ja     f01027c8 <mem_init+0x1408>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027b3:	53                   	push   %ebx
f01027b4:	68 c8 60 10 f0       	push   $0xf01060c8
f01027b9:	68 20 01 00 00       	push   $0x120
f01027be:	68 35 70 10 f0       	push   $0xf0107035
f01027c3:	e8 78 d8 ff ff       	call   f0100040 <_panic>
	uint32_t percpu_stacktop = KSTACKTOP;
	//uint32_t percpu_stackbtm;
	
	for (i=0;i<NCPU;i++)
	{	
		boot_map_region(kern_pgdir, percpu_stacktop - KSTKSIZE, KSTKSIZE,PADDR((void*)percpu_kstacks[i]), PTE_W | PTE_P);
f01027c8:	83 ec 08             	sub    $0x8,%esp
f01027cb:	6a 03                	push   $0x3
f01027cd:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f01027d3:	50                   	push   %eax
f01027d4:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01027d9:	89 f2                	mov    %esi,%edx
f01027db:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
f01027e0:	e8 96 e9 ff ff       	call   f010117b <boot_map_region>
f01027e5:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f01027eb:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	
	int i=0;
	uint32_t percpu_stacktop = KSTACKTOP;
	//uint32_t percpu_stackbtm;
	
	for (i=0;i<NCPU;i++)
f01027f1:	83 c4 10             	add    $0x10,%esp
f01027f4:	81 fb 00 20 27 f0    	cmp    $0xf0272000,%ebx
f01027fa:	75 af                	jne    f01027ab <mem_init+0x13eb>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01027fc:	8b 3d cc 0e 23 f0    	mov    0xf0230ecc,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102802:	a1 c8 0e 23 f0       	mov    0xf0230ec8,%eax
f0102807:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010280a:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102811:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102816:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102819:	8b 35 d0 0e 23 f0    	mov    0xf0230ed0,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010281f:	89 75 d0             	mov    %esi,-0x30(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102822:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102827:	eb 55                	jmp    f010287e <mem_init+0x14be>
f0102829:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010282f:	89 f8                	mov    %edi,%eax
f0102831:	e8 f1 e1 ff ff       	call   f0100a27 <check_va2pa>
f0102836:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f010283d:	77 15                	ja     f0102854 <mem_init+0x1494>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010283f:	56                   	push   %esi
f0102840:	68 c8 60 10 f0       	push   $0xf01060c8
f0102845:	68 d7 03 00 00       	push   $0x3d7
f010284a:	68 35 70 10 f0       	push   $0xf0107035
f010284f:	e8 ec d7 ff ff       	call   f0100040 <_panic>
f0102854:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f010285b:	39 d0                	cmp    %edx,%eax
f010285d:	74 19                	je     f0102878 <mem_init+0x14b8>
f010285f:	68 44 6e 10 f0       	push   $0xf0106e44
f0102864:	68 5b 70 10 f0       	push   $0xf010705b
f0102869:	68 d7 03 00 00       	push   $0x3d7
f010286e:	68 35 70 10 f0       	push   $0xf0107035
f0102873:	e8 c8 d7 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102878:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010287e:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102881:	77 a6                	ja     f0102829 <mem_init+0x1469>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102883:	8b 35 6c 02 23 f0    	mov    0xf023026c,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102889:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010288c:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f0102891:	89 da                	mov    %ebx,%edx
f0102893:	89 f8                	mov    %edi,%eax
f0102895:	e8 8d e1 ff ff       	call   f0100a27 <check_va2pa>
f010289a:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f01028a1:	77 15                	ja     f01028b8 <mem_init+0x14f8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028a3:	56                   	push   %esi
f01028a4:	68 c8 60 10 f0       	push   $0xf01060c8
f01028a9:	68 dc 03 00 00       	push   $0x3dc
f01028ae:	68 35 70 10 f0       	push   $0xf0107035
f01028b3:	e8 88 d7 ff ff       	call   f0100040 <_panic>
f01028b8:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f01028bf:	39 d0                	cmp    %edx,%eax
f01028c1:	74 19                	je     f01028dc <mem_init+0x151c>
f01028c3:	68 78 6e 10 f0       	push   $0xf0106e78
f01028c8:	68 5b 70 10 f0       	push   $0xf010705b
f01028cd:	68 dc 03 00 00       	push   $0x3dc
f01028d2:	68 35 70 10 f0       	push   $0xf0107035
f01028d7:	e8 64 d7 ff ff       	call   f0100040 <_panic>
f01028dc:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01028e2:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f01028e8:	75 a7                	jne    f0102891 <mem_init+0x14d1>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01028ea:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01028ed:	c1 e6 0c             	shl    $0xc,%esi
f01028f0:	bb 00 00 00 00       	mov    $0x0,%ebx
f01028f5:	eb 30                	jmp    f0102927 <mem_init+0x1567>
f01028f7:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01028fd:	89 f8                	mov    %edi,%eax
f01028ff:	e8 23 e1 ff ff       	call   f0100a27 <check_va2pa>
f0102904:	39 c3                	cmp    %eax,%ebx
f0102906:	74 19                	je     f0102921 <mem_init+0x1561>
f0102908:	68 ac 6e 10 f0       	push   $0xf0106eac
f010290d:	68 5b 70 10 f0       	push   $0xf010705b
f0102912:	68 e0 03 00 00       	push   $0x3e0
f0102917:	68 35 70 10 f0       	push   $0xf0107035
f010291c:	e8 1f d7 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102921:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102927:	39 f3                	cmp    %esi,%ebx
f0102929:	72 cc                	jb     f01028f7 <mem_init+0x1537>
f010292b:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
f0102932:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102937:	89 75 cc             	mov    %esi,-0x34(%ebp)
f010293a:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f010293d:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102940:	8d 88 00 80 00 00    	lea    0x8000(%eax),%ecx
f0102946:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0102949:	89 c3                	mov    %eax,%ebx
f010294b:	8b 45 c8             	mov    -0x38(%ebp),%eax
f010294e:	05 00 80 00 20       	add    $0x20008000,%eax
f0102953:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102956:	89 da                	mov    %ebx,%edx
f0102958:	89 f8                	mov    %edi,%eax
f010295a:	e8 c8 e0 ff ff       	call   f0100a27 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010295f:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102965:	77 15                	ja     f010297c <mem_init+0x15bc>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102967:	56                   	push   %esi
f0102968:	68 c8 60 10 f0       	push   $0xf01060c8
f010296d:	68 e8 03 00 00       	push   $0x3e8
f0102972:	68 35 70 10 f0       	push   $0xf0107035
f0102977:	e8 c4 d6 ff ff       	call   f0100040 <_panic>
f010297c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010297f:	8d 94 0b 00 20 23 f0 	lea    -0xfdce000(%ebx,%ecx,1),%edx
f0102986:	39 d0                	cmp    %edx,%eax
f0102988:	74 19                	je     f01029a3 <mem_init+0x15e3>
f010298a:	68 d4 6e 10 f0       	push   $0xf0106ed4
f010298f:	68 5b 70 10 f0       	push   $0xf010705b
f0102994:	68 e8 03 00 00       	push   $0x3e8
f0102999:	68 35 70 10 f0       	push   $0xf0107035
f010299e:	e8 9d d6 ff ff       	call   f0100040 <_panic>
f01029a3:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01029a9:	3b 5d d0             	cmp    -0x30(%ebp),%ebx
f01029ac:	75 a8                	jne    f0102956 <mem_init+0x1596>
f01029ae:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01029b1:	8d 98 00 80 ff ff    	lea    -0x8000(%eax),%ebx
f01029b7:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01029ba:	89 c6                	mov    %eax,%esi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f01029bc:	89 da                	mov    %ebx,%edx
f01029be:	89 f8                	mov    %edi,%eax
f01029c0:	e8 62 e0 ff ff       	call   f0100a27 <check_va2pa>
f01029c5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01029c8:	74 19                	je     f01029e3 <mem_init+0x1623>
f01029ca:	68 1c 6f 10 f0       	push   $0xf0106f1c
f01029cf:	68 5b 70 10 f0       	push   $0xf010705b
f01029d4:	68 ea 03 00 00       	push   $0x3ea
f01029d9:	68 35 70 10 f0       	push   $0xf0107035
f01029de:	e8 5d d6 ff ff       	call   f0100040 <_panic>
f01029e3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f01029e9:	39 de                	cmp    %ebx,%esi
f01029eb:	75 cf                	jne    f01029bc <mem_init+0x15fc>
f01029ed:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f01029f0:	81 6d cc 00 00 01 00 	subl   $0x10000,-0x34(%ebp)
f01029f7:	81 45 c8 00 80 01 00 	addl   $0x18000,-0x38(%ebp)
f01029fe:	81 c6 00 80 00 00    	add    $0x8000,%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f0102a04:	81 fe 00 20 27 f0    	cmp    $0xf0272000,%esi
f0102a0a:	0f 85 2d ff ff ff    	jne    f010293d <mem_init+0x157d>
f0102a10:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a15:	eb 2a                	jmp    f0102a41 <mem_init+0x1681>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102a17:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0102a1d:	83 fa 04             	cmp    $0x4,%edx
f0102a20:	77 1f                	ja     f0102a41 <mem_init+0x1681>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f0102a22:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0102a26:	75 7e                	jne    f0102aa6 <mem_init+0x16e6>
f0102a28:	68 44 73 10 f0       	push   $0xf0107344
f0102a2d:	68 5b 70 10 f0       	push   $0xf010705b
f0102a32:	68 f5 03 00 00       	push   $0x3f5
f0102a37:	68 35 70 10 f0       	push   $0xf0107035
f0102a3c:	e8 ff d5 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102a41:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102a46:	76 3f                	jbe    f0102a87 <mem_init+0x16c7>
				assert(pgdir[i] & PTE_P);
f0102a48:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0102a4b:	f6 c2 01             	test   $0x1,%dl
f0102a4e:	75 19                	jne    f0102a69 <mem_init+0x16a9>
f0102a50:	68 44 73 10 f0       	push   $0xf0107344
f0102a55:	68 5b 70 10 f0       	push   $0xf010705b
f0102a5a:	68 f9 03 00 00       	push   $0x3f9
f0102a5f:	68 35 70 10 f0       	push   $0xf0107035
f0102a64:	e8 d7 d5 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f0102a69:	f6 c2 02             	test   $0x2,%dl
f0102a6c:	75 38                	jne    f0102aa6 <mem_init+0x16e6>
f0102a6e:	68 55 73 10 f0       	push   $0xf0107355
f0102a73:	68 5b 70 10 f0       	push   $0xf010705b
f0102a78:	68 fa 03 00 00       	push   $0x3fa
f0102a7d:	68 35 70 10 f0       	push   $0xf0107035
f0102a82:	e8 b9 d5 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102a87:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102a8b:	74 19                	je     f0102aa6 <mem_init+0x16e6>
f0102a8d:	68 66 73 10 f0       	push   $0xf0107366
f0102a92:	68 5b 70 10 f0       	push   $0xf010705b
f0102a97:	68 fc 03 00 00       	push   $0x3fc
f0102a9c:	68 35 70 10 f0       	push   $0xf0107035
f0102aa1:	e8 9a d5 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102aa6:	83 c0 01             	add    $0x1,%eax
f0102aa9:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102aae:	0f 86 63 ff ff ff    	jbe    f0102a17 <mem_init+0x1657>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102ab4:	83 ec 0c             	sub    $0xc,%esp
f0102ab7:	68 40 6f 10 f0       	push   $0xf0106f40
f0102abc:	e8 99 0d 00 00       	call   f010385a <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102ac1:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102ac6:	83 c4 10             	add    $0x10,%esp
f0102ac9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102ace:	77 15                	ja     f0102ae5 <mem_init+0x1725>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ad0:	50                   	push   %eax
f0102ad1:	68 c8 60 10 f0       	push   $0xf01060c8
f0102ad6:	68 f2 00 00 00       	push   $0xf2
f0102adb:	68 35 70 10 f0       	push   $0xf0107035
f0102ae0:	e8 5b d5 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102ae5:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102aea:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102aed:	b8 00 00 00 00       	mov    $0x0,%eax
f0102af2:	e8 0a e0 ff ff       	call   f0100b01 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102af7:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102afa:	83 e0 f3             	and    $0xfffffff3,%eax
f0102afd:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102b02:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102b05:	83 ec 0c             	sub    $0xc,%esp
f0102b08:	6a 00                	push   $0x0
f0102b0a:	e8 93 e4 ff ff       	call   f0100fa2 <page_alloc>
f0102b0f:	89 c3                	mov    %eax,%ebx
f0102b11:	83 c4 10             	add    $0x10,%esp
f0102b14:	85 c0                	test   %eax,%eax
f0102b16:	75 19                	jne    f0102b31 <mem_init+0x1771>
f0102b18:	68 50 71 10 f0       	push   $0xf0107150
f0102b1d:	68 5b 70 10 f0       	push   $0xf010705b
f0102b22:	68 d7 04 00 00       	push   $0x4d7
f0102b27:	68 35 70 10 f0       	push   $0xf0107035
f0102b2c:	e8 0f d5 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102b31:	83 ec 0c             	sub    $0xc,%esp
f0102b34:	6a 00                	push   $0x0
f0102b36:	e8 67 e4 ff ff       	call   f0100fa2 <page_alloc>
f0102b3b:	89 c7                	mov    %eax,%edi
f0102b3d:	83 c4 10             	add    $0x10,%esp
f0102b40:	85 c0                	test   %eax,%eax
f0102b42:	75 19                	jne    f0102b5d <mem_init+0x179d>
f0102b44:	68 66 71 10 f0       	push   $0xf0107166
f0102b49:	68 5b 70 10 f0       	push   $0xf010705b
f0102b4e:	68 d8 04 00 00       	push   $0x4d8
f0102b53:	68 35 70 10 f0       	push   $0xf0107035
f0102b58:	e8 e3 d4 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102b5d:	83 ec 0c             	sub    $0xc,%esp
f0102b60:	6a 00                	push   $0x0
f0102b62:	e8 3b e4 ff ff       	call   f0100fa2 <page_alloc>
f0102b67:	89 c6                	mov    %eax,%esi
f0102b69:	83 c4 10             	add    $0x10,%esp
f0102b6c:	85 c0                	test   %eax,%eax
f0102b6e:	75 19                	jne    f0102b89 <mem_init+0x17c9>
f0102b70:	68 7c 71 10 f0       	push   $0xf010717c
f0102b75:	68 5b 70 10 f0       	push   $0xf010705b
f0102b7a:	68 d9 04 00 00       	push   $0x4d9
f0102b7f:	68 35 70 10 f0       	push   $0xf0107035
f0102b84:	e8 b7 d4 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f0102b89:	83 ec 0c             	sub    $0xc,%esp
f0102b8c:	53                   	push   %ebx
f0102b8d:	e8 86 e4 ff ff       	call   f0101018 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b92:	89 f8                	mov    %edi,%eax
f0102b94:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f0102b9a:	c1 f8 03             	sar    $0x3,%eax
f0102b9d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ba0:	89 c2                	mov    %eax,%edx
f0102ba2:	c1 ea 0c             	shr    $0xc,%edx
f0102ba5:	83 c4 10             	add    $0x10,%esp
f0102ba8:	3b 15 c8 0e 23 f0    	cmp    0xf0230ec8,%edx
f0102bae:	72 12                	jb     f0102bc2 <mem_init+0x1802>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bb0:	50                   	push   %eax
f0102bb1:	68 a4 60 10 f0       	push   $0xf01060a4
f0102bb6:	6a 58                	push   $0x58
f0102bb8:	68 41 70 10 f0       	push   $0xf0107041
f0102bbd:	e8 7e d4 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102bc2:	83 ec 04             	sub    $0x4,%esp
f0102bc5:	68 00 10 00 00       	push   $0x1000
f0102bca:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102bcc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102bd1:	50                   	push   %eax
f0102bd2:	e8 db 27 00 00       	call   f01053b2 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102bd7:	89 f0                	mov    %esi,%eax
f0102bd9:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f0102bdf:	c1 f8 03             	sar    $0x3,%eax
f0102be2:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102be5:	89 c2                	mov    %eax,%edx
f0102be7:	c1 ea 0c             	shr    $0xc,%edx
f0102bea:	83 c4 10             	add    $0x10,%esp
f0102bed:	3b 15 c8 0e 23 f0    	cmp    0xf0230ec8,%edx
f0102bf3:	72 12                	jb     f0102c07 <mem_init+0x1847>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bf5:	50                   	push   %eax
f0102bf6:	68 a4 60 10 f0       	push   $0xf01060a4
f0102bfb:	6a 58                	push   $0x58
f0102bfd:	68 41 70 10 f0       	push   $0xf0107041
f0102c02:	e8 39 d4 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102c07:	83 ec 04             	sub    $0x4,%esp
f0102c0a:	68 00 10 00 00       	push   $0x1000
f0102c0f:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102c11:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102c16:	50                   	push   %eax
f0102c17:	e8 96 27 00 00       	call   f01053b2 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102c1c:	6a 02                	push   $0x2
f0102c1e:	68 00 10 00 00       	push   $0x1000
f0102c23:	57                   	push   %edi
f0102c24:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0102c2a:	e8 99 e6 ff ff       	call   f01012c8 <page_insert>
	assert(pp1->pp_ref == 1);
f0102c2f:	83 c4 20             	add    $0x20,%esp
f0102c32:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102c37:	74 19                	je     f0102c52 <mem_init+0x1892>
f0102c39:	68 4d 72 10 f0       	push   $0xf010724d
f0102c3e:	68 5b 70 10 f0       	push   $0xf010705b
f0102c43:	68 de 04 00 00       	push   $0x4de
f0102c48:	68 35 70 10 f0       	push   $0xf0107035
f0102c4d:	e8 ee d3 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102c52:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102c59:	01 01 01 
f0102c5c:	74 19                	je     f0102c77 <mem_init+0x18b7>
f0102c5e:	68 60 6f 10 f0       	push   $0xf0106f60
f0102c63:	68 5b 70 10 f0       	push   $0xf010705b
f0102c68:	68 df 04 00 00       	push   $0x4df
f0102c6d:	68 35 70 10 f0       	push   $0xf0107035
f0102c72:	e8 c9 d3 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102c77:	6a 02                	push   $0x2
f0102c79:	68 00 10 00 00       	push   $0x1000
f0102c7e:	56                   	push   %esi
f0102c7f:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0102c85:	e8 3e e6 ff ff       	call   f01012c8 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102c8a:	83 c4 10             	add    $0x10,%esp
f0102c8d:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102c94:	02 02 02 
f0102c97:	74 19                	je     f0102cb2 <mem_init+0x18f2>
f0102c99:	68 84 6f 10 f0       	push   $0xf0106f84
f0102c9e:	68 5b 70 10 f0       	push   $0xf010705b
f0102ca3:	68 e1 04 00 00       	push   $0x4e1
f0102ca8:	68 35 70 10 f0       	push   $0xf0107035
f0102cad:	e8 8e d3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102cb2:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102cb7:	74 19                	je     f0102cd2 <mem_init+0x1912>
f0102cb9:	68 6f 72 10 f0       	push   $0xf010726f
f0102cbe:	68 5b 70 10 f0       	push   $0xf010705b
f0102cc3:	68 e2 04 00 00       	push   $0x4e2
f0102cc8:	68 35 70 10 f0       	push   $0xf0107035
f0102ccd:	e8 6e d3 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102cd2:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102cd7:	74 19                	je     f0102cf2 <mem_init+0x1932>
f0102cd9:	68 d9 72 10 f0       	push   $0xf01072d9
f0102cde:	68 5b 70 10 f0       	push   $0xf010705b
f0102ce3:	68 e3 04 00 00       	push   $0x4e3
f0102ce8:	68 35 70 10 f0       	push   $0xf0107035
f0102ced:	e8 4e d3 ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102cf2:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102cf9:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102cfc:	89 f0                	mov    %esi,%eax
f0102cfe:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f0102d04:	c1 f8 03             	sar    $0x3,%eax
f0102d07:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d0a:	89 c2                	mov    %eax,%edx
f0102d0c:	c1 ea 0c             	shr    $0xc,%edx
f0102d0f:	3b 15 c8 0e 23 f0    	cmp    0xf0230ec8,%edx
f0102d15:	72 12                	jb     f0102d29 <mem_init+0x1969>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102d17:	50                   	push   %eax
f0102d18:	68 a4 60 10 f0       	push   $0xf01060a4
f0102d1d:	6a 58                	push   $0x58
f0102d1f:	68 41 70 10 f0       	push   $0xf0107041
f0102d24:	e8 17 d3 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102d29:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102d30:	03 03 03 
f0102d33:	74 19                	je     f0102d4e <mem_init+0x198e>
f0102d35:	68 a8 6f 10 f0       	push   $0xf0106fa8
f0102d3a:	68 5b 70 10 f0       	push   $0xf010705b
f0102d3f:	68 e5 04 00 00       	push   $0x4e5
f0102d44:	68 35 70 10 f0       	push   $0xf0107035
f0102d49:	e8 f2 d2 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102d4e:	83 ec 08             	sub    $0x8,%esp
f0102d51:	68 00 10 00 00       	push   $0x1000
f0102d56:	ff 35 cc 0e 23 f0    	pushl  0xf0230ecc
f0102d5c:	e8 21 e5 ff ff       	call   f0101282 <page_remove>
	assert(pp2->pp_ref == 0);
f0102d61:	83 c4 10             	add    $0x10,%esp
f0102d64:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102d69:	74 19                	je     f0102d84 <mem_init+0x19c4>
f0102d6b:	68 a7 72 10 f0       	push   $0xf01072a7
f0102d70:	68 5b 70 10 f0       	push   $0xf010705b
f0102d75:	68 e7 04 00 00       	push   $0x4e7
f0102d7a:	68 35 70 10 f0       	push   $0xf0107035
f0102d7f:	e8 bc d2 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102d84:	8b 0d cc 0e 23 f0    	mov    0xf0230ecc,%ecx
f0102d8a:	8b 11                	mov    (%ecx),%edx
f0102d8c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102d92:	89 d8                	mov    %ebx,%eax
f0102d94:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f0102d9a:	c1 f8 03             	sar    $0x3,%eax
f0102d9d:	c1 e0 0c             	shl    $0xc,%eax
f0102da0:	39 c2                	cmp    %eax,%edx
f0102da2:	74 19                	je     f0102dbd <mem_init+0x19fd>
f0102da4:	68 30 69 10 f0       	push   $0xf0106930
f0102da9:	68 5b 70 10 f0       	push   $0xf010705b
f0102dae:	68 ea 04 00 00       	push   $0x4ea
f0102db3:	68 35 70 10 f0       	push   $0xf0107035
f0102db8:	e8 83 d2 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102dbd:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102dc3:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102dc8:	74 19                	je     f0102de3 <mem_init+0x1a23>
f0102dca:	68 5e 72 10 f0       	push   $0xf010725e
f0102dcf:	68 5b 70 10 f0       	push   $0xf010705b
f0102dd4:	68 ec 04 00 00       	push   $0x4ec
f0102dd9:	68 35 70 10 f0       	push   $0xf0107035
f0102dde:	e8 5d d2 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102de3:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102de9:	83 ec 0c             	sub    $0xc,%esp
f0102dec:	53                   	push   %ebx
f0102ded:	e8 26 e2 ff ff       	call   f0101018 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102df2:	c7 04 24 d4 6f 10 f0 	movl   $0xf0106fd4,(%esp)
f0102df9:	e8 5c 0a 00 00       	call   f010385a <cprintf>
f0102dfe:	83 c4 10             	add    $0x10,%esp
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102e01:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e04:	5b                   	pop    %ebx
f0102e05:	5e                   	pop    %esi
f0102e06:	5f                   	pop    %edi
f0102e07:	5d                   	pop    %ebp
f0102e08:	c3                   	ret    

f0102e09 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102e09:	55                   	push   %ebp
f0102e0a:	89 e5                	mov    %esp,%ebp
f0102e0c:	57                   	push   %edi
f0102e0d:	56                   	push   %esi
f0102e0e:	53                   	push   %ebx
f0102e0f:	83 ec 1c             	sub    $0x1c,%esp
f0102e12:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102e15:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// LAB 3: Your code here.

	// step 1 : check below ULIM
  uintptr_t va_beg = (uintptr_t)va;
  uintptr_t va_end = va_beg + len;
f0102e18:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102e1b:	03 75 10             	add    0x10(%ebp),%esi
  if (va_beg >= ULIM || va_end >= ULIM) {
f0102e1e:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102e24:	77 09                	ja     f0102e2f <user_mem_check+0x26>
f0102e26:	81 7d 0c ff ff 7f ef 	cmpl   $0xef7fffff,0xc(%ebp)
f0102e2d:	76 1f                	jbe    f0102e4e <user_mem_check+0x45>
    user_mem_check_addr = (va_beg >= ULIM) ? va_beg : ULIM;
f0102e2f:	81 7d 0c 00 00 80 ef 	cmpl   $0xef800000,0xc(%ebp)
f0102e36:	b8 00 00 80 ef       	mov    $0xef800000,%eax
f0102e3b:	0f 43 45 0c          	cmovae 0xc(%ebp),%eax
f0102e3f:	a3 60 02 23 f0       	mov    %eax,0xf0230260
    return -E_FAULT;
f0102e44:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102e49:	e9 a7 00 00 00       	jmp    f0102ef5 <user_mem_check+0xec>
  }

  // step 2 : check present & permission
  uintptr_t va_beg2 = ROUNDDOWN(va_beg, PGSIZE);
f0102e4e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102e51:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  uintptr_t va_end2 = ROUNDUP(va_end, PGSIZE);
f0102e57:	81 c6 ff 0f 00 00    	add    $0xfff,%esi
f0102e5d:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102e63:	a1 c8 0e 23 f0       	mov    0xf0230ec8,%eax
f0102e68:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102e6b:	89 7d 08             	mov    %edi,0x8(%ebp)
  while (va_beg2 < va_end2) {
f0102e6e:	eb 7c                	jmp    f0102eec <user_mem_check+0xe3>

    // check page table is present ?
    if (!(env->env_pgdir[PDX(va_beg2)] & PTE_P)) {
f0102e70:	89 d1                	mov    %edx,%ecx
f0102e72:	c1 e9 16             	shr    $0x16,%ecx
f0102e75:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e78:	8b 40 60             	mov    0x60(%eax),%eax
f0102e7b:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0102e7e:	a8 01                	test   $0x1,%al
f0102e80:	75 14                	jne    f0102e96 <user_mem_check+0x8d>
      user_mem_check_addr = (va_beg2 > va_beg) ? va_beg2 : va_beg;
f0102e82:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102e85:	0f 42 55 0c          	cmovb  0xc(%ebp),%edx
f0102e89:	89 15 60 02 23 f0    	mov    %edx,0xf0230260
      return -E_FAULT;
f0102e8f:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102e94:	eb 5f                	jmp    f0102ef5 <user_mem_check+0xec>
    }

    // get current page table kernel va
    uint32_t* pt_kva = KADDR(PTE_ADDR(env->env_pgdir[PDX(va_beg2)]));
f0102e96:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102e9b:	89 c1                	mov    %eax,%ecx
f0102e9d:	c1 e9 0c             	shr    $0xc,%ecx
f0102ea0:	3b 4d e4             	cmp    -0x1c(%ebp),%ecx
f0102ea3:	72 15                	jb     f0102eba <user_mem_check+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ea5:	50                   	push   %eax
f0102ea6:	68 a4 60 10 f0       	push   $0xf01060a4
f0102eab:	68 14 03 00 00       	push   $0x314
f0102eb0:	68 35 70 10 f0       	push   $0xf0107035
f0102eb5:	e8 86 d1 ff ff       	call   f0100040 <_panic>

    // check page is present & permissions
    if (!((pt_kva[PTX(va_beg2)] & perm) == perm)) {
f0102eba:	89 d1                	mov    %edx,%ecx
f0102ebc:	c1 e9 0c             	shr    $0xc,%ecx
f0102ebf:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
f0102ec5:	89 df                	mov    %ebx,%edi
f0102ec7:	23 bc 88 00 00 00 f0 	and    -0x10000000(%eax,%ecx,4),%edi
f0102ece:	39 fb                	cmp    %edi,%ebx
f0102ed0:	74 14                	je     f0102ee6 <user_mem_check+0xdd>
      user_mem_check_addr = (va_beg2 > va_beg) ? va_beg2 : va_beg;
f0102ed2:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102ed5:	0f 42 55 0c          	cmovb  0xc(%ebp),%edx
f0102ed9:	89 15 60 02 23 f0    	mov    %edx,0xf0230260
      return -E_FAULT;
f0102edf:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102ee4:	eb 0f                	jmp    f0102ef5 <user_mem_check+0xec>
    }

    va_beg2 += PGSIZE;
f0102ee6:	81 c2 00 10 00 00    	add    $0x1000,%edx
  }

  // step 2 : check present & permission
  uintptr_t va_beg2 = ROUNDDOWN(va_beg, PGSIZE);
  uintptr_t va_end2 = ROUNDUP(va_end, PGSIZE);
  while (va_beg2 < va_end2) {
f0102eec:	39 f2                	cmp    %esi,%edx
f0102eee:	72 80                	jb     f0102e70 <user_mem_check+0x67>
      return -E_FAULT;
    }

    va_beg2 += PGSIZE;
  }
  return 0;
f0102ef0:	b8 00 00 00 00       	mov    $0x0,%eax

}
f0102ef5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ef8:	5b                   	pop    %ebx
f0102ef9:	5e                   	pop    %esi
f0102efa:	5f                   	pop    %edi
f0102efb:	5d                   	pop    %ebp
f0102efc:	c3                   	ret    

f0102efd <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102efd:	55                   	push   %ebp
f0102efe:	89 e5                	mov    %esp,%ebp
f0102f00:	53                   	push   %ebx
f0102f01:	83 ec 04             	sub    $0x4,%esp
f0102f04:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102f07:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f0a:	83 c8 04             	or     $0x4,%eax
f0102f0d:	50                   	push   %eax
f0102f0e:	ff 75 10             	pushl  0x10(%ebp)
f0102f11:	ff 75 0c             	pushl  0xc(%ebp)
f0102f14:	53                   	push   %ebx
f0102f15:	e8 ef fe ff ff       	call   f0102e09 <user_mem_check>
f0102f1a:	83 c4 10             	add    $0x10,%esp
f0102f1d:	85 c0                	test   %eax,%eax
f0102f1f:	79 21                	jns    f0102f42 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102f21:	83 ec 04             	sub    $0x4,%esp
f0102f24:	ff 35 60 02 23 f0    	pushl  0xf0230260
f0102f2a:	ff 73 48             	pushl  0x48(%ebx)
f0102f2d:	68 00 70 10 f0       	push   $0xf0107000
f0102f32:	e8 23 09 00 00       	call   f010385a <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102f37:	89 1c 24             	mov    %ebx,(%esp)
f0102f3a:	e8 54 06 00 00       	call   f0103593 <env_destroy>
f0102f3f:	83 c4 10             	add    $0x10,%esp
	}
}
f0102f42:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102f45:	c9                   	leave  
f0102f46:	c3                   	ret    

f0102f47 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102f47:	55                   	push   %ebp
f0102f48:	89 e5                	mov    %esp,%ebp
f0102f4a:	57                   	push   %edi
f0102f4b:	56                   	push   %esi
f0102f4c:	53                   	push   %ebx
f0102f4d:	83 ec 0c             	sub    $0xc,%esp
f0102f50:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
f0102f52:	89 d3                	mov    %edx,%ebx
f0102f54:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
f0102f5a:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102f61:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	
	while (vaBegin<vaEnd){
f0102f67:	eb 58                	jmp    f0102fc1 <region_alloc+0x7a>
		struct PageInfo *p = page_alloc(0);
f0102f69:	83 ec 0c             	sub    $0xc,%esp
f0102f6c:	6a 00                	push   $0x0
f0102f6e:	e8 2f e0 ff ff       	call   f0100fa2 <page_alloc>
		if (p == NULL)
f0102f73:	83 c4 10             	add    $0x10,%esp
f0102f76:	85 c0                	test   %eax,%eax
f0102f78:	75 17                	jne    f0102f91 <region_alloc+0x4a>
			panic("Page alloc failed!");
f0102f7a:	83 ec 04             	sub    $0x4,%esp
f0102f7d:	68 74 73 10 f0       	push   $0xf0107374
f0102f82:	68 35 01 00 00       	push   $0x135
f0102f87:	68 87 73 10 f0       	push   $0xf0107387
f0102f8c:	e8 af d0 ff ff       	call   f0100040 <_panic>
		else if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
f0102f91:	6a 06                	push   $0x6
f0102f93:	53                   	push   %ebx
f0102f94:	50                   	push   %eax
f0102f95:	ff 77 60             	pushl  0x60(%edi)
f0102f98:	e8 2b e3 ff ff       	call   f01012c8 <page_insert>
f0102f9d:	83 c4 10             	add    $0x10,%esp
f0102fa0:	85 c0                	test   %eax,%eax
f0102fa2:	74 17                	je     f0102fbb <region_alloc+0x74>
			panic("Page table couldn't be allocated!!");
f0102fa4:	83 ec 04             	sub    $0x4,%esp
f0102fa7:	68 f4 73 10 f0       	push   $0xf01073f4
f0102fac:	68 37 01 00 00       	push   $0x137
f0102fb1:	68 87 73 10 f0       	push   $0xf0107387
f0102fb6:	e8 85 d0 ff ff       	call   f0100040 <_panic>
		}
		vaBegin += PGSIZE;
f0102fbb:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
	
	while (vaBegin<vaEnd){
f0102fc1:	39 f3                	cmp    %esi,%ebx
f0102fc3:	72 a4                	jb     f0102f69 <region_alloc+0x22>
		else if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
			panic("Page table couldn't be allocated!!");
		}
		vaBegin += PGSIZE;
	}
}
f0102fc5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102fc8:	5b                   	pop    %ebx
f0102fc9:	5e                   	pop    %esi
f0102fca:	5f                   	pop    %edi
f0102fcb:	5d                   	pop    %ebp
f0102fcc:	c3                   	ret    

f0102fcd <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102fcd:	55                   	push   %ebp
f0102fce:	89 e5                	mov    %esp,%ebp
f0102fd0:	56                   	push   %esi
f0102fd1:	53                   	push   %ebx
f0102fd2:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fd5:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102fd8:	85 c0                	test   %eax,%eax
f0102fda:	75 1a                	jne    f0102ff6 <envid2env+0x29>
		*env_store = curenv;
f0102fdc:	e8 f6 29 00 00       	call   f01059d7 <cpunum>
f0102fe1:	6b c0 74             	imul   $0x74,%eax,%eax
f0102fe4:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0102fea:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102fed:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102fef:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ff4:	eb 70                	jmp    f0103066 <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102ff6:	89 c3                	mov    %eax,%ebx
f0102ff8:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0102ffe:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0103001:	03 1d 6c 02 23 f0    	add    0xf023026c,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103007:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f010300b:	74 05                	je     f0103012 <envid2env+0x45>
f010300d:	39 43 48             	cmp    %eax,0x48(%ebx)
f0103010:	74 10                	je     f0103022 <envid2env+0x55>
		*env_store = 0;
f0103012:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103015:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010301b:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103020:	eb 44                	jmp    f0103066 <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103022:	84 d2                	test   %dl,%dl
f0103024:	74 36                	je     f010305c <envid2env+0x8f>
f0103026:	e8 ac 29 00 00       	call   f01059d7 <cpunum>
f010302b:	6b c0 74             	imul   $0x74,%eax,%eax
f010302e:	39 98 48 10 23 f0    	cmp    %ebx,-0xfdcefb8(%eax)
f0103034:	74 26                	je     f010305c <envid2env+0x8f>
f0103036:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0103039:	e8 99 29 00 00       	call   f01059d7 <cpunum>
f010303e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103041:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0103047:	3b 70 48             	cmp    0x48(%eax),%esi
f010304a:	74 10                	je     f010305c <envid2env+0x8f>
		*env_store = 0;
f010304c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010304f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103055:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010305a:	eb 0a                	jmp    f0103066 <envid2env+0x99>
	}

	*env_store = e;
f010305c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010305f:	89 18                	mov    %ebx,(%eax)
	return 0;
f0103061:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103066:	5b                   	pop    %ebx
f0103067:	5e                   	pop    %esi
f0103068:	5d                   	pop    %ebp
f0103069:	c3                   	ret    

f010306a <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f010306a:	55                   	push   %ebp
f010306b:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f010306d:	b8 40 03 12 f0       	mov    $0xf0120340,%eax
f0103072:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0103075:	b8 23 00 00 00       	mov    $0x23,%eax
f010307a:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f010307c:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f010307e:	b0 10                	mov    $0x10,%al
f0103080:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0103082:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0103084:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f0103086:	ea 8d 30 10 f0 08 00 	ljmp   $0x8,$0xf010308d
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f010308d:	b0 00                	mov    $0x0,%al
f010308f:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0103092:	5d                   	pop    %ebp
f0103093:	c3                   	ret    

f0103094 <env_init>:
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
f0103094:	8b 0d 6c 02 23 f0    	mov    0xf023026c,%ecx
f010309a:	8b 15 70 02 23 f0    	mov    0xf0230270,%edx
f01030a0:	89 c8                	mov    %ecx,%eax
f01030a2:	81 c1 00 f0 01 00    	add    $0x1f000,%ecx
f01030a8:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = NULL;
f01030af:	c7 40 44 00 00 00 00 	movl   $0x0,0x44(%eax)

		if (!env_free_list){		
f01030b6:	85 d2                	test   %edx,%edx
f01030b8:	74 05                	je     f01030bf <env_init+0x2b>
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
		}
		else{
		envs[i-1].env_link = &envs[i];
f01030ba:	89 40 c8             	mov    %eax,-0x38(%eax)
f01030bd:	eb 02                	jmp    f01030c1 <env_init+0x2d>
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
		envs[i].env_link = NULL;

		if (!env_free_list){		
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
f01030bf:	89 c2                	mov    %eax,%edx
f01030c1:	83 c0 7c             	add    $0x7c,%eax
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
f01030c4:	39 c8                	cmp    %ecx,%eax
f01030c6:	75 e0                	jne    f01030a8 <env_init+0x14>
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01030c8:	55                   	push   %ebp
f01030c9:	89 e5                	mov    %esp,%ebp
f01030cb:	89 15 70 02 23 f0    	mov    %edx,0xf0230270
		}	//Previous env is linked to this current env
	}
	

	// Per-CPU part of the initialization
	env_init_percpu();
f01030d1:	e8 94 ff ff ff       	call   f010306a <env_init_percpu>
}
f01030d6:	5d                   	pop    %ebp
f01030d7:	c3                   	ret    

f01030d8 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01030d8:	55                   	push   %ebp
f01030d9:	89 e5                	mov    %esp,%ebp
f01030db:	53                   	push   %ebx
f01030dc:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f01030df:	8b 1d 70 02 23 f0    	mov    0xf0230270,%ebx
f01030e5:	85 db                	test   %ebx,%ebx
f01030e7:	0f 84 70 01 00 00    	je     f010325d <env_alloc+0x185>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f01030ed:	83 ec 0c             	sub    $0xc,%esp
f01030f0:	6a 01                	push   $0x1
f01030f2:	e8 ab de ff ff       	call   f0100fa2 <page_alloc>
f01030f7:	83 c4 10             	add    $0x10,%esp
f01030fa:	85 c0                	test   %eax,%eax
f01030fc:	0f 84 62 01 00 00    	je     f0103264 <env_alloc+0x18c>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f0103102:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0103107:	2b 05 d0 0e 23 f0    	sub    0xf0230ed0,%eax
f010310d:	c1 f8 03             	sar    $0x3,%eax
f0103110:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103113:	89 c2                	mov    %eax,%edx
f0103115:	c1 ea 0c             	shr    $0xc,%edx
f0103118:	3b 15 c8 0e 23 f0    	cmp    0xf0230ec8,%edx
f010311e:	72 12                	jb     f0103132 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103120:	50                   	push   %eax
f0103121:	68 a4 60 10 f0       	push   $0xf01060a4
f0103126:	6a 58                	push   $0x58
f0103128:	68 41 70 10 f0       	push   $0xf0107041
f010312d:	e8 0e cf ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0103132:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103137:	89 43 60             	mov    %eax,0x60(%ebx)
	e->env_pgdir = (pde_t*)page2kva(p);
f010313a:	b8 00 00 00 00       	mov    $0x0,%eax

	for (i = 0; i < NPDENTRIES; ++i) {
		e->env_pgdir[i] = kern_pgdir[i];  //Mapping all 1024 entries of the kernel
f010313f:	8b 15 cc 0e 23 f0    	mov    0xf0230ecc,%edx
f0103145:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f0103148:	8b 53 60             	mov    0x60(%ebx),%edx
f010314b:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f010314e:	83 c0 04             	add    $0x4,%eax

	// LAB 3: Your code here.
	p->pp_ref++;
	e->env_pgdir = (pde_t*)page2kva(p);

	for (i = 0; i < NPDENTRIES; ++i) {
f0103151:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0103156:	75 e7                	jne    f010313f <env_alloc+0x67>
						 //pgdir to the environment pgdir
	}
	
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0103158:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010315b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103160:	77 15                	ja     f0103177 <env_alloc+0x9f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103162:	50                   	push   %eax
f0103163:	68 c8 60 10 f0       	push   $0xf01060c8
f0103168:	68 d0 00 00 00       	push   $0xd0
f010316d:	68 87 73 10 f0       	push   $0xf0107387
f0103172:	e8 c9 ce ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103177:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010317d:	83 ca 05             	or     $0x5,%edx
f0103180:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0103186:	8b 43 48             	mov    0x48(%ebx),%eax
f0103189:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f010318e:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0103193:	ba 00 10 00 00       	mov    $0x1000,%edx
f0103198:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f010319b:	89 da                	mov    %ebx,%edx
f010319d:	2b 15 6c 02 23 f0    	sub    0xf023026c,%edx
f01031a3:	c1 fa 02             	sar    $0x2,%edx
f01031a6:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f01031ac:	09 d0                	or     %edx,%eax
f01031ae:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f01031b1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031b4:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f01031b7:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01031be:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f01031c5:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01031cc:	83 ec 04             	sub    $0x4,%esp
f01031cf:	6a 44                	push   $0x44
f01031d1:	6a 00                	push   $0x0
f01031d3:	53                   	push   %ebx
f01031d4:	e8 d9 21 00 00       	call   f01053b2 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f01031d9:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f01031df:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f01031e5:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f01031eb:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f01031f2:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.
	e->env_tf.tf_eflags |= FL_IF;  //Modification for exercise 13
f01031f8:	81 4b 38 00 02 00 00 	orl    $0x200,0x38(%ebx)

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f01031ff:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f0103206:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f010320a:	8b 43 44             	mov    0x44(%ebx),%eax
f010320d:	a3 70 02 23 f0       	mov    %eax,0xf0230270
	*newenv_store = e;
f0103212:	8b 45 08             	mov    0x8(%ebp),%eax
f0103215:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103217:	8b 5b 48             	mov    0x48(%ebx),%ebx
f010321a:	e8 b8 27 00 00       	call   f01059d7 <cpunum>
f010321f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103222:	83 c4 10             	add    $0x10,%esp
f0103225:	ba 00 00 00 00       	mov    $0x0,%edx
f010322a:	83 b8 48 10 23 f0 00 	cmpl   $0x0,-0xfdcefb8(%eax)
f0103231:	74 11                	je     f0103244 <env_alloc+0x16c>
f0103233:	e8 9f 27 00 00       	call   f01059d7 <cpunum>
f0103238:	6b c0 74             	imul   $0x74,%eax,%eax
f010323b:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0103241:	8b 50 48             	mov    0x48(%eax),%edx
f0103244:	83 ec 04             	sub    $0x4,%esp
f0103247:	53                   	push   %ebx
f0103248:	52                   	push   %edx
f0103249:	68 92 73 10 f0       	push   $0xf0107392
f010324e:	e8 07 06 00 00       	call   f010385a <cprintf>
	return 0;
f0103253:	83 c4 10             	add    $0x10,%esp
f0103256:	b8 00 00 00 00       	mov    $0x0,%eax
f010325b:	eb 0c                	jmp    f0103269 <env_alloc+0x191>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f010325d:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103262:	eb 05                	jmp    f0103269 <env_alloc+0x191>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0103264:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0103269:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010326c:	c9                   	leave  
f010326d:	c3                   	ret    

f010326e <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f010326e:	55                   	push   %ebp
f010326f:	89 e5                	mov    %esp,%ebp
f0103271:	57                   	push   %edi
f0103272:	56                   	push   %esi
f0103273:	53                   	push   %ebx
f0103274:	83 ec 34             	sub    $0x34,%esp
f0103277:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	int r;
	struct Env *env;
	r = env_alloc( &env, 0);
f010327a:	6a 00                	push   $0x0
f010327c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010327f:	50                   	push   %eax
f0103280:	e8 53 fe ff ff       	call   f01030d8 <env_alloc>
	if (r){
f0103285:	83 c4 10             	add    $0x10,%esp
f0103288:	85 c0                	test   %eax,%eax
f010328a:	74 15                	je     f01032a1 <env_create+0x33>
	panic("env_alloc: %e", r);
f010328c:	50                   	push   %eax
f010328d:	68 a7 73 10 f0       	push   $0xf01073a7
f0103292:	68 b2 01 00 00       	push   $0x1b2
f0103297:	68 87 73 10 f0       	push   $0xf0107387
f010329c:	e8 9f cd ff ff       	call   f0100040 <_panic>
	}
	
	load_icode(env,binary);
f01032a1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01032a4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Get the beginning and end of program header table
	//Details of struct proghdr are in /lab/inc/elf.h

	// is this a valid ELF?
	
	if (((struct Elf*)binary)->e_magic != ELF_MAGIC)
f01032a7:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f01032ad:	74 17                	je     f01032c6 <env_create+0x58>
	{
		panic ("Not a valid ELF binary image");
f01032af:	83 ec 04             	sub    $0x4,%esp
f01032b2:	68 b5 73 10 f0       	push   $0xf01073b5
f01032b7:	68 81 01 00 00       	push   $0x181
f01032bc:	68 87 73 10 f0       	push   $0xf0107387
f01032c1:	e8 7a cd ff ff       	call   f0100040 <_panic>
	}

	struct Proghdr *ph =(struct Proghdr *)(binary + ((struct Elf*)binary)->e_phoff); //phoff is the offset
f01032c6:	89 fb                	mov    %edi,%ebx
f01032c8:	03 5f 1c             	add    0x1c(%edi),%ebx
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
f01032cb:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f01032cf:	c1 e6 05             	shl    $0x5,%esi
f01032d2:	01 de                	add    %ebx,%esi
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));
f01032d4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01032d7:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01032da:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01032df:	77 15                	ja     f01032f6 <env_create+0x88>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01032e1:	50                   	push   %eax
f01032e2:	68 c8 60 10 f0       	push   $0xf01060c8
f01032e7:	68 88 01 00 00       	push   $0x188
f01032ec:	68 87 73 10 f0       	push   $0xf0107387
f01032f1:	e8 4a cd ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01032f6:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01032fb:	0f 22 d8             	mov    %eax,%cr3
f01032fe:	eb 60                	jmp    f0103360 <env_create+0xf2>

	for (;ph<phEnd;++ph){
		if (ph->p_type == ELF_PROG_LOAD){	//Check whether the type is ELF_PROG_LOAD
f0103300:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103303:	75 58                	jne    f010335d <env_create+0xef>
		
		if(ph->p_memsz < ph->p_filesz){
f0103305:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103308:	3b 4b 10             	cmp    0x10(%ebx),%ecx
f010330b:	73 17                	jae    f0103324 <env_create+0xb6>
		panic ("Memory size is smaller than file size!!");
f010330d:	83 ec 04             	sub    $0x4,%esp
f0103310:	68 18 74 10 f0       	push   $0xf0107418
f0103315:	68 8e 01 00 00       	push   $0x18e
f010331a:	68 87 73 10 f0       	push   $0xf0107387
f010331f:	e8 1c cd ff ff       	call   f0100040 <_panic>
		}
		region_alloc(e, (void *)ph->p_va, ph->p_memsz);  //Allocate region per segment
f0103324:	8b 53 08             	mov    0x8(%ebx),%edx
f0103327:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010332a:	e8 18 fc ff ff       	call   f0102f47 <region_alloc>
	

		memcpy((void*)ph->p_va, (void*)(binary + ph->p_offset), ph->p_filesz); //Load Binary into memory
f010332f:	83 ec 04             	sub    $0x4,%esp
f0103332:	ff 73 10             	pushl  0x10(%ebx)
f0103335:	89 f8                	mov    %edi,%eax
f0103337:	03 43 04             	add    0x4(%ebx),%eax
f010333a:	50                   	push   %eax
f010333b:	ff 73 08             	pushl  0x8(%ebx)
f010333e:	e8 24 21 00 00       	call   f0105467 <memcpy>

		memset((void*)(ph->p_va + ph->p_filesz),0,ph->p_memsz-ph->p_filesz);  //Clear the rest of the memory, i.e the bss segment
f0103343:	8b 43 10             	mov    0x10(%ebx),%eax
f0103346:	83 c4 0c             	add    $0xc,%esp
f0103349:	8b 53 14             	mov    0x14(%ebx),%edx
f010334c:	29 c2                	sub    %eax,%edx
f010334e:	52                   	push   %edx
f010334f:	6a 00                	push   $0x0
f0103351:	03 43 08             	add    0x8(%ebx),%eax
f0103354:	50                   	push   %eax
f0103355:	e8 58 20 00 00       	call   f01053b2 <memset>
f010335a:	83 c4 10             	add    $0x10,%esp
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));

	for (;ph<phEnd;++ph){
f010335d:	83 c3 20             	add    $0x20,%ebx
f0103360:	39 de                	cmp    %ebx,%esi
f0103362:	77 9c                	ja     f0103300 <env_create+0x92>
		}
		else{
			continue;
		}
	}
	lcr3(PADDR(kern_pgdir));   //Switch back to Kernel page directory
f0103364:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103369:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010336e:	77 15                	ja     f0103385 <env_create+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103370:	50                   	push   %eax
f0103371:	68 c8 60 10 f0       	push   $0xf01060c8
f0103376:	68 9b 01 00 00       	push   $0x19b
f010337b:	68 87 73 10 f0       	push   $0xf0107387
f0103380:	e8 bb cc ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103385:	05 00 00 00 10       	add    $0x10000000,%eax
f010338a:	0f 22 d8             	mov    %eax,%cr3
	
	e->env_tf.tf_eip = ((struct Elf*)binary)->e_entry;   //Define the entry point of the env from the ELF binary entry point
f010338d:	8b 47 18             	mov    0x18(%edi),%eax
f0103390:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103393:	89 47 30             	mov    %eax,0x30(%edi)

	region_alloc(e,(void *)USTACKTOP - PGSIZE, PGSIZE);
f0103396:	b9 00 10 00 00       	mov    $0x1000,%ecx
f010339b:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01033a0:	89 f8                	mov    %edi,%eax
f01033a2:	e8 a0 fb ff ff       	call   f0102f47 <region_alloc>
	if (r){
	panic("env_alloc: %e", r);
	}
	
	load_icode(env,binary);
	env->env_type = type;
f01033a7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01033aa:	8b 55 0c             	mov    0xc(%ebp),%edx
f01033ad:	89 50 50             	mov    %edx,0x50(%eax)
}
f01033b0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01033b3:	5b                   	pop    %ebx
f01033b4:	5e                   	pop    %esi
f01033b5:	5f                   	pop    %edi
f01033b6:	5d                   	pop    %ebp
f01033b7:	c3                   	ret    

f01033b8 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01033b8:	55                   	push   %ebp
f01033b9:	89 e5                	mov    %esp,%ebp
f01033bb:	57                   	push   %edi
f01033bc:	56                   	push   %esi
f01033bd:	53                   	push   %ebx
f01033be:	83 ec 1c             	sub    $0x1c,%esp
f01033c1:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01033c4:	e8 0e 26 00 00       	call   f01059d7 <cpunum>
f01033c9:	6b c0 74             	imul   $0x74,%eax,%eax
f01033cc:	39 b8 48 10 23 f0    	cmp    %edi,-0xfdcefb8(%eax)
f01033d2:	75 29                	jne    f01033fd <env_free+0x45>
		lcr3(PADDR(kern_pgdir));
f01033d4:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01033d9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01033de:	77 15                	ja     f01033f5 <env_free+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033e0:	50                   	push   %eax
f01033e1:	68 c8 60 10 f0       	push   $0xf01060c8
f01033e6:	68 c8 01 00 00       	push   $0x1c8
f01033eb:	68 87 73 10 f0       	push   $0xf0107387
f01033f0:	e8 4b cc ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01033f5:	05 00 00 00 10       	add    $0x10000000,%eax
f01033fa:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01033fd:	8b 5f 48             	mov    0x48(%edi),%ebx
f0103400:	e8 d2 25 00 00       	call   f01059d7 <cpunum>
f0103405:	6b c0 74             	imul   $0x74,%eax,%eax
f0103408:	ba 00 00 00 00       	mov    $0x0,%edx
f010340d:	83 b8 48 10 23 f0 00 	cmpl   $0x0,-0xfdcefb8(%eax)
f0103414:	74 11                	je     f0103427 <env_free+0x6f>
f0103416:	e8 bc 25 00 00       	call   f01059d7 <cpunum>
f010341b:	6b c0 74             	imul   $0x74,%eax,%eax
f010341e:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0103424:	8b 50 48             	mov    0x48(%eax),%edx
f0103427:	83 ec 04             	sub    $0x4,%esp
f010342a:	53                   	push   %ebx
f010342b:	52                   	push   %edx
f010342c:	68 d2 73 10 f0       	push   $0xf01073d2
f0103431:	e8 24 04 00 00       	call   f010385a <cprintf>
f0103436:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103439:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103440:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103443:	89 d0                	mov    %edx,%eax
f0103445:	c1 e0 02             	shl    $0x2,%eax
f0103448:	89 45 d8             	mov    %eax,-0x28(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f010344b:	8b 47 60             	mov    0x60(%edi),%eax
f010344e:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0103451:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103457:	0f 84 a8 00 00 00    	je     f0103505 <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f010345d:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103463:	89 f0                	mov    %esi,%eax
f0103465:	c1 e8 0c             	shr    $0xc,%eax
f0103468:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010346b:	3b 05 c8 0e 23 f0    	cmp    0xf0230ec8,%eax
f0103471:	72 15                	jb     f0103488 <env_free+0xd0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103473:	56                   	push   %esi
f0103474:	68 a4 60 10 f0       	push   $0xf01060a4
f0103479:	68 d7 01 00 00       	push   $0x1d7
f010347e:	68 87 73 10 f0       	push   $0xf0107387
f0103483:	e8 b8 cb ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103488:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010348b:	c1 e0 16             	shl    $0x16,%eax
f010348e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103491:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103496:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f010349d:	01 
f010349e:	74 17                	je     f01034b7 <env_free+0xff>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01034a0:	83 ec 08             	sub    $0x8,%esp
f01034a3:	89 d8                	mov    %ebx,%eax
f01034a5:	c1 e0 0c             	shl    $0xc,%eax
f01034a8:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01034ab:	50                   	push   %eax
f01034ac:	ff 77 60             	pushl  0x60(%edi)
f01034af:	e8 ce dd ff ff       	call   f0101282 <page_remove>
f01034b4:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01034b7:	83 c3 01             	add    $0x1,%ebx
f01034ba:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01034c0:	75 d4                	jne    f0103496 <env_free+0xde>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01034c2:	8b 47 60             	mov    0x60(%edi),%eax
f01034c5:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01034c8:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01034cf:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01034d2:	3b 05 c8 0e 23 f0    	cmp    0xf0230ec8,%eax
f01034d8:	72 14                	jb     f01034ee <env_free+0x136>
		panic("pa2page called with invalid pa");
f01034da:	83 ec 04             	sub    $0x4,%esp
f01034dd:	68 40 74 10 f0       	push   $0xf0107440
f01034e2:	6a 51                	push   $0x51
f01034e4:	68 41 70 10 f0       	push   $0xf0107041
f01034e9:	e8 52 cb ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f01034ee:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f01034f1:	a1 d0 0e 23 f0       	mov    0xf0230ed0,%eax
f01034f6:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01034f9:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01034fc:	50                   	push   %eax
f01034fd:	e8 67 db ff ff       	call   f0101069 <page_decref>
f0103502:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103505:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103509:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010350c:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0103511:	0f 85 29 ff ff ff    	jne    f0103440 <env_free+0x88>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103517:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010351a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010351f:	77 15                	ja     f0103536 <env_free+0x17e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103521:	50                   	push   %eax
f0103522:	68 c8 60 10 f0       	push   $0xf01060c8
f0103527:	68 e5 01 00 00       	push   $0x1e5
f010352c:	68 87 73 10 f0       	push   $0xf0107387
f0103531:	e8 0a cb ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f0103536:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
	return (physaddr_t)kva - KERNBASE;
f010353d:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103542:	c1 e8 0c             	shr    $0xc,%eax
f0103545:	3b 05 c8 0e 23 f0    	cmp    0xf0230ec8,%eax
f010354b:	72 14                	jb     f0103561 <env_free+0x1a9>
		panic("pa2page called with invalid pa");
f010354d:	83 ec 04             	sub    $0x4,%esp
f0103550:	68 40 74 10 f0       	push   $0xf0107440
f0103555:	6a 51                	push   $0x51
f0103557:	68 41 70 10 f0       	push   $0xf0107041
f010355c:	e8 df ca ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f0103561:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103564:	8b 15 d0 0e 23 f0    	mov    0xf0230ed0,%edx
f010356a:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f010356d:	50                   	push   %eax
f010356e:	e8 f6 da ff ff       	call   f0101069 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103573:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f010357a:	a1 70 02 23 f0       	mov    0xf0230270,%eax
f010357f:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103582:	89 3d 70 02 23 f0    	mov    %edi,0xf0230270
f0103588:	83 c4 10             	add    $0x10,%esp
}
f010358b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010358e:	5b                   	pop    %ebx
f010358f:	5e                   	pop    %esi
f0103590:	5f                   	pop    %edi
f0103591:	5d                   	pop    %ebp
f0103592:	c3                   	ret    

f0103593 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103593:	55                   	push   %ebp
f0103594:	89 e5                	mov    %esp,%ebp
f0103596:	53                   	push   %ebx
f0103597:	83 ec 04             	sub    $0x4,%esp
f010359a:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f010359d:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f01035a1:	75 19                	jne    f01035bc <env_destroy+0x29>
f01035a3:	e8 2f 24 00 00       	call   f01059d7 <cpunum>
f01035a8:	6b c0 74             	imul   $0x74,%eax,%eax
f01035ab:	39 98 48 10 23 f0    	cmp    %ebx,-0xfdcefb8(%eax)
f01035b1:	74 09                	je     f01035bc <env_destroy+0x29>
		e->env_status = ENV_DYING;
f01035b3:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f01035ba:	eb 33                	jmp    f01035ef <env_destroy+0x5c>
	}

	env_free(e);
f01035bc:	83 ec 0c             	sub    $0xc,%esp
f01035bf:	53                   	push   %ebx
f01035c0:	e8 f3 fd ff ff       	call   f01033b8 <env_free>

	if (curenv == e) {
f01035c5:	e8 0d 24 00 00       	call   f01059d7 <cpunum>
f01035ca:	6b c0 74             	imul   $0x74,%eax,%eax
f01035cd:	83 c4 10             	add    $0x10,%esp
f01035d0:	39 98 48 10 23 f0    	cmp    %ebx,-0xfdcefb8(%eax)
f01035d6:	75 17                	jne    f01035ef <env_destroy+0x5c>
		curenv = NULL;
f01035d8:	e8 fa 23 00 00       	call   f01059d7 <cpunum>
f01035dd:	6b c0 74             	imul   $0x74,%eax,%eax
f01035e0:	c7 80 48 10 23 f0 00 	movl   $0x0,-0xfdcefb8(%eax)
f01035e7:	00 00 00 
		sched_yield();
f01035ea:	e8 fd 0b 00 00       	call   f01041ec <sched_yield>
	}
}
f01035ef:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01035f2:	c9                   	leave  
f01035f3:	c3                   	ret    

f01035f4 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01035f4:	55                   	push   %ebp
f01035f5:	89 e5                	mov    %esp,%ebp
f01035f7:	53                   	push   %ebx
f01035f8:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f01035fb:	e8 d7 23 00 00       	call   f01059d7 <cpunum>
f0103600:	6b c0 74             	imul   $0x74,%eax,%eax
f0103603:	8b 98 48 10 23 f0    	mov    -0xfdcefb8(%eax),%ebx
f0103609:	e8 c9 23 00 00       	call   f01059d7 <cpunum>
f010360e:	89 43 5c             	mov    %eax,0x5c(%ebx)

	__asm __volatile("movl %0,%%esp\n"
f0103611:	8b 65 08             	mov    0x8(%ebp),%esp
f0103614:	61                   	popa   
f0103615:	07                   	pop    %es
f0103616:	1f                   	pop    %ds
f0103617:	83 c4 08             	add    $0x8,%esp
f010361a:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f010361b:	83 ec 04             	sub    $0x4,%esp
f010361e:	68 e8 73 10 f0       	push   $0xf01073e8
f0103623:	68 1b 02 00 00       	push   $0x21b
f0103628:	68 87 73 10 f0       	push   $0xf0107387
f010362d:	e8 0e ca ff ff       	call   f0100040 <_panic>

f0103632 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103632:	55                   	push   %ebp
f0103633:	89 e5                	mov    %esp,%ebp
f0103635:	53                   	push   %ebx
f0103636:	83 ec 04             	sub    $0x4,%esp
f0103639:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	//check if this is the first call to env_run
	if (curenv == NULL){
f010363c:	e8 96 23 00 00       	call   f01059d7 <cpunum>
f0103641:	6b c0 74             	imul   $0x74,%eax,%eax
f0103644:	83 b8 48 10 23 f0 00 	cmpl   $0x0,-0xfdcefb8(%eax)
f010364b:	75 10                	jne    f010365d <env_run+0x2b>
	curenv = e;
f010364d:	e8 85 23 00 00       	call   f01059d7 <cpunum>
f0103652:	6b c0 74             	imul   $0x74,%eax,%eax
f0103655:	89 98 48 10 23 f0    	mov    %ebx,-0xfdcefb8(%eax)
f010365b:	eb 29                	jmp    f0103686 <env_run+0x54>
	}
	
	//If curenv state is running mode , set it to runnable 
	else if (curenv->env_status == ENV_RUNNING){
f010365d:	e8 75 23 00 00       	call   f01059d7 <cpunum>
f0103662:	6b c0 74             	imul   $0x74,%eax,%eax
f0103665:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f010366b:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010366f:	75 15                	jne    f0103686 <env_run+0x54>
	 curenv->env_status = ENV_RUNNABLE;
f0103671:	e8 61 23 00 00       	call   f01059d7 <cpunum>
f0103676:	6b c0 74             	imul   $0x74,%eax,%eax
f0103679:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f010367f:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	curenv = e;	//Set the current environment to the new env
f0103686:	e8 4c 23 00 00       	call   f01059d7 <cpunum>
f010368b:	6b c0 74             	imul   $0x74,%eax,%eax
f010368e:	89 98 48 10 23 f0    	mov    %ebx,-0xfdcefb8(%eax)
	curenv->env_status = ENV_RUNNING; //Set it to running state
f0103694:	e8 3e 23 00 00       	call   f01059d7 <cpunum>
f0103699:	6b c0 74             	imul   $0x74,%eax,%eax
f010369c:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f01036a2:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;	// Increment the env_runs counter
f01036a9:	e8 29 23 00 00       	call   f01059d7 <cpunum>
f01036ae:	6b c0 74             	imul   $0x74,%eax,%eax
f01036b1:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f01036b7:	83 40 58 01          	addl   $0x1,0x58(%eax)
	
	lcr3(PADDR(e->env_pgdir));	//Use lcr3 to switch to the env directory
f01036bb:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01036be:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01036c3:	77 15                	ja     f01036da <env_run+0xa8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01036c5:	50                   	push   %eax
f01036c6:	68 c8 60 10 f0       	push   $0xf01060c8
f01036cb:	68 47 02 00 00       	push   $0x247
f01036d0:	68 87 73 10 f0       	push   $0xf0107387
f01036d5:	e8 66 c9 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01036da:	05 00 00 00 10       	add    $0x10000000,%eax
f01036df:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01036e2:	83 ec 0c             	sub    $0xc,%esp
f01036e5:	68 c0 04 12 f0       	push   $0xf01204c0
f01036ea:	e8 f0 25 00 00       	call   f0105cdf <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01036ef:	f3 90                	pause  
	unlock_kernel();
	env_pop_tf(&e->env_tf);
f01036f1:	89 1c 24             	mov    %ebx,(%esp)
f01036f4:	e8 fb fe ff ff       	call   f01035f4 <env_pop_tf>

f01036f9 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01036f9:	55                   	push   %ebp
f01036fa:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01036fc:	ba 70 00 00 00       	mov    $0x70,%edx
f0103701:	8b 45 08             	mov    0x8(%ebp),%eax
f0103704:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103705:	b2 71                	mov    $0x71,%dl
f0103707:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103708:	0f b6 c0             	movzbl %al,%eax
}
f010370b:	5d                   	pop    %ebp
f010370c:	c3                   	ret    

f010370d <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010370d:	55                   	push   %ebp
f010370e:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103710:	ba 70 00 00 00       	mov    $0x70,%edx
f0103715:	8b 45 08             	mov    0x8(%ebp),%eax
f0103718:	ee                   	out    %al,(%dx)
f0103719:	b2 71                	mov    $0x71,%dl
f010371b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010371e:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010371f:	5d                   	pop    %ebp
f0103720:	c3                   	ret    

f0103721 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103721:	55                   	push   %ebp
f0103722:	89 e5                	mov    %esp,%ebp
f0103724:	56                   	push   %esi
f0103725:	53                   	push   %ebx
f0103726:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103729:	66 a3 e8 03 12 f0    	mov    %ax,0xf01203e8
	if (!didinit)
f010372f:	80 3d 74 02 23 f0 00 	cmpb   $0x0,0xf0230274
f0103736:	74 57                	je     f010378f <irq_setmask_8259A+0x6e>
f0103738:	89 c6                	mov    %eax,%esi
f010373a:	ba 21 00 00 00       	mov    $0x21,%edx
f010373f:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
f0103740:	66 c1 e8 08          	shr    $0x8,%ax
f0103744:	b2 a1                	mov    $0xa1,%dl
f0103746:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f0103747:	83 ec 0c             	sub    $0xc,%esp
f010374a:	68 5f 74 10 f0       	push   $0xf010745f
f010374f:	e8 06 01 00 00       	call   f010385a <cprintf>
f0103754:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f0103757:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f010375c:	0f b7 f6             	movzwl %si,%esi
f010375f:	f7 d6                	not    %esi
f0103761:	0f a3 de             	bt     %ebx,%esi
f0103764:	73 11                	jae    f0103777 <irq_setmask_8259A+0x56>
			cprintf(" %d", i);
f0103766:	83 ec 08             	sub    $0x8,%esp
f0103769:	53                   	push   %ebx
f010376a:	68 7f 79 10 f0       	push   $0xf010797f
f010376f:	e8 e6 00 00 00       	call   f010385a <cprintf>
f0103774:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f0103777:	83 c3 01             	add    $0x1,%ebx
f010377a:	83 fb 10             	cmp    $0x10,%ebx
f010377d:	75 e2                	jne    f0103761 <irq_setmask_8259A+0x40>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f010377f:	83 ec 0c             	sub    $0xc,%esp
f0103782:	68 12 79 10 f0       	push   $0xf0107912
f0103787:	e8 ce 00 00 00       	call   f010385a <cprintf>
f010378c:	83 c4 10             	add    $0x10,%esp
}
f010378f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103792:	5b                   	pop    %ebx
f0103793:	5e                   	pop    %esi
f0103794:	5d                   	pop    %ebp
f0103795:	c3                   	ret    

f0103796 <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f0103796:	c6 05 74 02 23 f0 01 	movb   $0x1,0xf0230274
f010379d:	ba 21 00 00 00       	mov    $0x21,%edx
f01037a2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01037a7:	ee                   	out    %al,(%dx)
f01037a8:	b2 a1                	mov    $0xa1,%dl
f01037aa:	ee                   	out    %al,(%dx)
f01037ab:	b2 20                	mov    $0x20,%dl
f01037ad:	b8 11 00 00 00       	mov    $0x11,%eax
f01037b2:	ee                   	out    %al,(%dx)
f01037b3:	b2 21                	mov    $0x21,%dl
f01037b5:	b8 20 00 00 00       	mov    $0x20,%eax
f01037ba:	ee                   	out    %al,(%dx)
f01037bb:	b8 04 00 00 00       	mov    $0x4,%eax
f01037c0:	ee                   	out    %al,(%dx)
f01037c1:	b8 03 00 00 00       	mov    $0x3,%eax
f01037c6:	ee                   	out    %al,(%dx)
f01037c7:	b2 a0                	mov    $0xa0,%dl
f01037c9:	b8 11 00 00 00       	mov    $0x11,%eax
f01037ce:	ee                   	out    %al,(%dx)
f01037cf:	b2 a1                	mov    $0xa1,%dl
f01037d1:	b8 28 00 00 00       	mov    $0x28,%eax
f01037d6:	ee                   	out    %al,(%dx)
f01037d7:	b8 02 00 00 00       	mov    $0x2,%eax
f01037dc:	ee                   	out    %al,(%dx)
f01037dd:	b8 01 00 00 00       	mov    $0x1,%eax
f01037e2:	ee                   	out    %al,(%dx)
f01037e3:	b2 20                	mov    $0x20,%dl
f01037e5:	b8 68 00 00 00       	mov    $0x68,%eax
f01037ea:	ee                   	out    %al,(%dx)
f01037eb:	b8 0a 00 00 00       	mov    $0xa,%eax
f01037f0:	ee                   	out    %al,(%dx)
f01037f1:	b2 a0                	mov    $0xa0,%dl
f01037f3:	b8 68 00 00 00       	mov    $0x68,%eax
f01037f8:	ee                   	out    %al,(%dx)
f01037f9:	b8 0a 00 00 00       	mov    $0xa,%eax
f01037fe:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f01037ff:	0f b7 05 e8 03 12 f0 	movzwl 0xf01203e8,%eax
f0103806:	66 83 f8 ff          	cmp    $0xffff,%ax
f010380a:	74 13                	je     f010381f <pic_init+0x89>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f010380c:	55                   	push   %ebp
f010380d:	89 e5                	mov    %esp,%ebp
f010380f:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f0103812:	0f b7 c0             	movzwl %ax,%eax
f0103815:	50                   	push   %eax
f0103816:	e8 06 ff ff ff       	call   f0103721 <irq_setmask_8259A>
f010381b:	83 c4 10             	add    $0x10,%esp
}
f010381e:	c9                   	leave  
f010381f:	f3 c3                	repz ret 

f0103821 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103821:	55                   	push   %ebp
f0103822:	89 e5                	mov    %esp,%ebp
f0103824:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0103827:	ff 75 08             	pushl  0x8(%ebp)
f010382a:	e8 16 cf ff ff       	call   f0100745 <cputchar>
f010382f:	83 c4 10             	add    $0x10,%esp
	*cnt++;
}
f0103832:	c9                   	leave  
f0103833:	c3                   	ret    

f0103834 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103834:	55                   	push   %ebp
f0103835:	89 e5                	mov    %esp,%ebp
f0103837:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010383a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103841:	ff 75 0c             	pushl  0xc(%ebp)
f0103844:	ff 75 08             	pushl  0x8(%ebp)
f0103847:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010384a:	50                   	push   %eax
f010384b:	68 21 38 10 f0       	push   $0xf0103821
f0103850:	e8 ea 14 00 00       	call   f0104d3f <vprintfmt>
	return cnt;
}
f0103855:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103858:	c9                   	leave  
f0103859:	c3                   	ret    

f010385a <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010385a:	55                   	push   %ebp
f010385b:	89 e5                	mov    %esp,%ebp
f010385d:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103860:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103863:	50                   	push   %eax
f0103864:	ff 75 08             	pushl  0x8(%ebp)
f0103867:	e8 c8 ff ff ff       	call   f0103834 <vcprintf>
	va_end(ap);

	return cnt;
}
f010386c:	c9                   	leave  
f010386d:	c3                   	ret    

f010386e <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f010386e:	55                   	push   %ebp
f010386f:	89 e5                	mov    %esp,%ebp
f0103871:	56                   	push   %esi
f0103872:	53                   	push   %ebx
	// user space on that CPU.
	//
	// LAB 4: Your code here:

	
	int i = cpunum();
f0103873:	e8 5f 21 00 00       	call   f01059d7 <cpunum>
f0103878:	89 c3                	mov    %eax,%ebx
	

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	thiscpu->cpu_ts.ts_esp0 = (uintptr_t)(percpu_kstacks[cpunum()] + KSTKSIZE);
f010387a:	e8 58 21 00 00       	call   f01059d7 <cpunum>
f010387f:	89 c6                	mov    %eax,%esi
f0103881:	e8 51 21 00 00       	call   f01059d7 <cpunum>
f0103886:	6b f6 74             	imul   $0x74,%esi,%esi
f0103889:	c1 e0 0f             	shl    $0xf,%eax
f010388c:	8d 80 00 a0 23 f0    	lea    -0xfdc6000(%eax),%eax
f0103892:	89 86 50 10 23 f0    	mov    %eax,-0xfdcefb0(%esi)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f0103898:	e8 3a 21 00 00       	call   f01059d7 <cpunum>
f010389d:	6b c0 74             	imul   $0x74,%eax,%eax
f01038a0:	66 c7 80 54 10 23 f0 	movw   $0x10,-0xfdcefac(%eax)
f01038a7:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3)+i] = SEG16(STS_T32A, (uint32_t) (&cpus[i].cpu_ts),  //It was (&ts) instead of &cpus[i].cpu_ts
f01038a9:	8d 43 05             	lea    0x5(%ebx),%eax
f01038ac:	6b d3 74             	imul   $0x74,%ebx,%edx
f01038af:	81 c2 4c 10 23 f0    	add    $0xf023104c,%edx
f01038b5:	66 c7 04 c5 80 03 12 	movw   $0x67,-0xfedfc80(,%eax,8)
f01038bc:	f0 67 00 
f01038bf:	66 89 14 c5 82 03 12 	mov    %dx,-0xfedfc7e(,%eax,8)
f01038c6:	f0 
f01038c7:	89 d1                	mov    %edx,%ecx
f01038c9:	c1 e9 10             	shr    $0x10,%ecx
f01038cc:	88 0c c5 84 03 12 f0 	mov    %cl,-0xfedfc7c(,%eax,8)
f01038d3:	c6 04 c5 86 03 12 f0 	movb   $0x40,-0xfedfc7a(,%eax,8)
f01038da:	40 
f01038db:	c1 ea 18             	shr    $0x18,%edx
f01038de:	88 14 c5 87 03 12 f0 	mov    %dl,-0xfedfc79(,%eax,8)
					sizeof(struct Taskstate)-1, 0);
	gdt[(GD_TSS0 >> 3)+i].sd_s = 0;
f01038e5:	c6 04 c5 85 03 12 f0 	movb   $0x89,-0xfedfc7b(,%eax,8)
f01038ec:	89 

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(((GD_TSS0>>3) + i) << 3);	
f01038ed:	8d 1c dd 28 00 00 00 	lea    0x28(,%ebx,8),%ebx
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f01038f4:	0f 00 db             	ltr    %bx
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f01038f7:	b8 ea 03 12 f0       	mov    $0xf01203ea,%eax
f01038fc:	0f 01 18             	lidtl  (%eax)
	lidt(&idt_pd); 
	
	


}
f01038ff:	5b                   	pop    %ebx
f0103900:	5e                   	pop    %esi
f0103901:	5d                   	pop    %ebp
f0103902:	c3                   	ret    

f0103903 <trap_init>:
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i,j; 
	for (i=0; i<= T_SIMDERR;i++){
f0103903:	b8 00 00 00 00       	mov    $0x0,%eax
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
f0103908:	8b 14 85 f0 03 12 f0 	mov    -0xfedfc10(,%eax,4),%edx
f010390f:	66 89 14 c5 80 02 23 	mov    %dx,-0xfdcfd80(,%eax,8)
f0103916:	f0 
f0103917:	66 c7 04 c5 82 02 23 	movw   $0x8,-0xfdcfd7e(,%eax,8)
f010391e:	f0 08 00 
f0103921:	c6 04 c5 84 02 23 f0 	movb   $0x0,-0xfdcfd7c(,%eax,8)
f0103928:	00 
f0103929:	c6 04 c5 85 02 23 f0 	movb   $0x8e,-0xfdcfd7b(,%eax,8)
f0103930:	8e 
f0103931:	c1 ea 10             	shr    $0x10,%edx
f0103934:	66 89 14 c5 86 02 23 	mov    %dx,-0xfdcfd7a(,%eax,8)
f010393b:	f0 
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i,j; 
	for (i=0; i<= T_SIMDERR;i++){
f010393c:	83 c0 01             	add    $0x1,%eax
f010393f:	83 f8 14             	cmp    $0x14,%eax
f0103942:	75 c4                	jne    f0103908 <trap_init+0x5>
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
	}

	//Interrupt 3 is a soft interrupt generated by user, hence the dpl of the gate will be checked with 3
  	SETGATE(idt[3],0,GD_KT,int_vector_table[3],3);
f0103944:	a1 fc 03 12 f0       	mov    0xf01203fc,%eax
f0103949:	66 a3 98 02 23 f0    	mov    %ax,0xf0230298
f010394f:	66 c7 05 9a 02 23 f0 	movw   $0x8,0xf023029a
f0103956:	08 00 
f0103958:	c6 05 9c 02 23 f0 00 	movb   $0x0,0xf023029c
f010395f:	c6 05 9d 02 23 f0 ee 	movb   $0xee,0xf023029d
f0103966:	c1 e8 10             	shr    $0x10,%eax
f0103969:	66 a3 9e 02 23 f0    	mov    %ax,0xf023029e

	//similarly system call is setup by the user and hence the gate should be checked with 3 
	SETGATE(idt[T_SYSCALL], 0, GD_KT, int_vector_table[T_SYSCALL], 3);// T_SYSCALL = 3
f010396f:	a1 b0 04 12 f0       	mov    0xf01204b0,%eax
f0103974:	66 a3 00 04 23 f0    	mov    %ax,0xf0230400
f010397a:	66 c7 05 02 04 23 f0 	movw   $0x8,0xf0230402
f0103981:	08 00 
f0103983:	c6 05 04 04 23 f0 00 	movb   $0x0,0xf0230404
f010398a:	c6 05 05 04 23 f0 ee 	movb   $0xee,0xf0230405
f0103991:	c1 e8 10             	shr    $0x10,%eax
f0103994:	66 a3 06 04 23 f0    	mov    %ax,0xf0230406
f010399a:	b8 20 00 00 00       	mov    $0x20,%eax

	//For IRQ interrupts
	for(j=0;j<16;j++)
	    SETGATE(idt[IRQ_OFFSET + j], 0, GD_KT, int_vector_table[IRQ_OFFSET + j], 3);
f010399f:	8b 14 85 f0 03 12 f0 	mov    -0xfedfc10(,%eax,4),%edx
f01039a6:	66 89 14 c5 80 02 23 	mov    %dx,-0xfdcfd80(,%eax,8)
f01039ad:	f0 
f01039ae:	66 c7 04 c5 82 02 23 	movw   $0x8,-0xfdcfd7e(,%eax,8)
f01039b5:	f0 08 00 
f01039b8:	c6 04 c5 84 02 23 f0 	movb   $0x0,-0xfdcfd7c(,%eax,8)
f01039bf:	00 
f01039c0:	c6 04 c5 85 02 23 f0 	movb   $0xee,-0xfdcfd7b(,%eax,8)
f01039c7:	ee 
f01039c8:	c1 ea 10             	shr    $0x10,%edx
f01039cb:	66 89 14 c5 86 02 23 	mov    %dx,-0xfdcfd7a(,%eax,8)
f01039d2:	f0 
f01039d3:	83 c0 01             	add    $0x1,%eax

	//similarly system call is setup by the user and hence the gate should be checked with 3 
	SETGATE(idt[T_SYSCALL], 0, GD_KT, int_vector_table[T_SYSCALL], 3);// T_SYSCALL = 3

	//For IRQ interrupts
	for(j=0;j<16;j++)
f01039d6:	83 f8 30             	cmp    $0x30,%eax
f01039d9:	75 c4                	jne    f010399f <trap_init+0x9c>
}


void
trap_init(void)
{
f01039db:	55                   	push   %ebp
f01039dc:	89 e5                	mov    %esp,%ebp
f01039de:	83 ec 08             	sub    $0x8,%esp
	//For IRQ interrupts
	for(j=0;j<16;j++)
	    SETGATE(idt[IRQ_OFFSET + j], 0, GD_KT, int_vector_table[IRQ_OFFSET + j], 3);

	// Per-CPU setup 
	trap_init_percpu();
f01039e1:	e8 88 fe ff ff       	call   f010386e <trap_init_percpu>
}
f01039e6:	c9                   	leave  
f01039e7:	c3                   	ret    

f01039e8 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01039e8:	55                   	push   %ebp
f01039e9:	89 e5                	mov    %esp,%ebp
f01039eb:	53                   	push   %ebx
f01039ec:	83 ec 0c             	sub    $0xc,%esp
f01039ef:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01039f2:	ff 33                	pushl  (%ebx)
f01039f4:	68 73 74 10 f0       	push   $0xf0107473
f01039f9:	e8 5c fe ff ff       	call   f010385a <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01039fe:	83 c4 08             	add    $0x8,%esp
f0103a01:	ff 73 04             	pushl  0x4(%ebx)
f0103a04:	68 82 74 10 f0       	push   $0xf0107482
f0103a09:	e8 4c fe ff ff       	call   f010385a <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103a0e:	83 c4 08             	add    $0x8,%esp
f0103a11:	ff 73 08             	pushl  0x8(%ebx)
f0103a14:	68 91 74 10 f0       	push   $0xf0107491
f0103a19:	e8 3c fe ff ff       	call   f010385a <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103a1e:	83 c4 08             	add    $0x8,%esp
f0103a21:	ff 73 0c             	pushl  0xc(%ebx)
f0103a24:	68 a0 74 10 f0       	push   $0xf01074a0
f0103a29:	e8 2c fe ff ff       	call   f010385a <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103a2e:	83 c4 08             	add    $0x8,%esp
f0103a31:	ff 73 10             	pushl  0x10(%ebx)
f0103a34:	68 af 74 10 f0       	push   $0xf01074af
f0103a39:	e8 1c fe ff ff       	call   f010385a <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103a3e:	83 c4 08             	add    $0x8,%esp
f0103a41:	ff 73 14             	pushl  0x14(%ebx)
f0103a44:	68 be 74 10 f0       	push   $0xf01074be
f0103a49:	e8 0c fe ff ff       	call   f010385a <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103a4e:	83 c4 08             	add    $0x8,%esp
f0103a51:	ff 73 18             	pushl  0x18(%ebx)
f0103a54:	68 cd 74 10 f0       	push   $0xf01074cd
f0103a59:	e8 fc fd ff ff       	call   f010385a <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103a5e:	83 c4 08             	add    $0x8,%esp
f0103a61:	ff 73 1c             	pushl  0x1c(%ebx)
f0103a64:	68 dc 74 10 f0       	push   $0xf01074dc
f0103a69:	e8 ec fd ff ff       	call   f010385a <cprintf>
f0103a6e:	83 c4 10             	add    $0x10,%esp
}
f0103a71:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103a74:	c9                   	leave  
f0103a75:	c3                   	ret    

f0103a76 <print_trapframe>:

}

void
print_trapframe(struct Trapframe *tf)
{
f0103a76:	55                   	push   %ebp
f0103a77:	89 e5                	mov    %esp,%ebp
f0103a79:	56                   	push   %esi
f0103a7a:	53                   	push   %ebx
f0103a7b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103a7e:	e8 54 1f 00 00       	call   f01059d7 <cpunum>
f0103a83:	83 ec 04             	sub    $0x4,%esp
f0103a86:	50                   	push   %eax
f0103a87:	53                   	push   %ebx
f0103a88:	68 40 75 10 f0       	push   $0xf0107540
f0103a8d:	e8 c8 fd ff ff       	call   f010385a <cprintf>
	print_regs(&tf->tf_regs);
f0103a92:	89 1c 24             	mov    %ebx,(%esp)
f0103a95:	e8 4e ff ff ff       	call   f01039e8 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103a9a:	83 c4 08             	add    $0x8,%esp
f0103a9d:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103aa1:	50                   	push   %eax
f0103aa2:	68 5e 75 10 f0       	push   $0xf010755e
f0103aa7:	e8 ae fd ff ff       	call   f010385a <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103aac:	83 c4 08             	add    $0x8,%esp
f0103aaf:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103ab3:	50                   	push   %eax
f0103ab4:	68 71 75 10 f0       	push   $0xf0107571
f0103ab9:	e8 9c fd ff ff       	call   f010385a <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103abe:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103ac1:	83 c4 10             	add    $0x10,%esp
f0103ac4:	83 f8 13             	cmp    $0x13,%eax
f0103ac7:	77 09                	ja     f0103ad2 <print_trapframe+0x5c>
		return excnames[trapno];
f0103ac9:	8b 14 85 40 78 10 f0 	mov    -0xfef87c0(,%eax,4),%edx
f0103ad0:	eb 1f                	jmp    f0103af1 <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103ad2:	83 f8 30             	cmp    $0x30,%eax
f0103ad5:	74 15                	je     f0103aec <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103ad7:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103ada:	83 fa 10             	cmp    $0x10,%edx
f0103add:	b9 0a 75 10 f0       	mov    $0xf010750a,%ecx
f0103ae2:	ba f7 74 10 f0       	mov    $0xf01074f7,%edx
f0103ae7:	0f 43 d1             	cmovae %ecx,%edx
f0103aea:	eb 05                	jmp    f0103af1 <print_trapframe+0x7b>
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103aec:	ba eb 74 10 f0       	mov    $0xf01074eb,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103af1:	83 ec 04             	sub    $0x4,%esp
f0103af4:	52                   	push   %edx
f0103af5:	50                   	push   %eax
f0103af6:	68 84 75 10 f0       	push   $0xf0107584
f0103afb:	e8 5a fd ff ff       	call   f010385a <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103b00:	83 c4 10             	add    $0x10,%esp
f0103b03:	3b 1d 80 0a 23 f0    	cmp    0xf0230a80,%ebx
f0103b09:	75 1a                	jne    f0103b25 <print_trapframe+0xaf>
f0103b0b:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103b0f:	75 14                	jne    f0103b25 <print_trapframe+0xaf>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103b11:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103b14:	83 ec 08             	sub    $0x8,%esp
f0103b17:	50                   	push   %eax
f0103b18:	68 96 75 10 f0       	push   $0xf0107596
f0103b1d:	e8 38 fd ff ff       	call   f010385a <cprintf>
f0103b22:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103b25:	83 ec 08             	sub    $0x8,%esp
f0103b28:	ff 73 2c             	pushl  0x2c(%ebx)
f0103b2b:	68 a5 75 10 f0       	push   $0xf01075a5
f0103b30:	e8 25 fd ff ff       	call   f010385a <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103b35:	83 c4 10             	add    $0x10,%esp
f0103b38:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103b3c:	75 49                	jne    f0103b87 <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103b3e:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103b41:	89 c2                	mov    %eax,%edx
f0103b43:	83 e2 01             	and    $0x1,%edx
f0103b46:	ba 24 75 10 f0       	mov    $0xf0107524,%edx
f0103b4b:	b9 19 75 10 f0       	mov    $0xf0107519,%ecx
f0103b50:	0f 44 ca             	cmove  %edx,%ecx
f0103b53:	89 c2                	mov    %eax,%edx
f0103b55:	83 e2 02             	and    $0x2,%edx
f0103b58:	ba 36 75 10 f0       	mov    $0xf0107536,%edx
f0103b5d:	be 30 75 10 f0       	mov    $0xf0107530,%esi
f0103b62:	0f 45 d6             	cmovne %esi,%edx
f0103b65:	83 e0 04             	and    $0x4,%eax
f0103b68:	be 8c 76 10 f0       	mov    $0xf010768c,%esi
f0103b6d:	b8 3b 75 10 f0       	mov    $0xf010753b,%eax
f0103b72:	0f 44 c6             	cmove  %esi,%eax
f0103b75:	51                   	push   %ecx
f0103b76:	52                   	push   %edx
f0103b77:	50                   	push   %eax
f0103b78:	68 b3 75 10 f0       	push   $0xf01075b3
f0103b7d:	e8 d8 fc ff ff       	call   f010385a <cprintf>
f0103b82:	83 c4 10             	add    $0x10,%esp
f0103b85:	eb 10                	jmp    f0103b97 <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103b87:	83 ec 0c             	sub    $0xc,%esp
f0103b8a:	68 12 79 10 f0       	push   $0xf0107912
f0103b8f:	e8 c6 fc ff ff       	call   f010385a <cprintf>
f0103b94:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103b97:	83 ec 08             	sub    $0x8,%esp
f0103b9a:	ff 73 30             	pushl  0x30(%ebx)
f0103b9d:	68 c2 75 10 f0       	push   $0xf01075c2
f0103ba2:	e8 b3 fc ff ff       	call   f010385a <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103ba7:	83 c4 08             	add    $0x8,%esp
f0103baa:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103bae:	50                   	push   %eax
f0103baf:	68 d1 75 10 f0       	push   $0xf01075d1
f0103bb4:	e8 a1 fc ff ff       	call   f010385a <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103bb9:	83 c4 08             	add    $0x8,%esp
f0103bbc:	ff 73 38             	pushl  0x38(%ebx)
f0103bbf:	68 e4 75 10 f0       	push   $0xf01075e4
f0103bc4:	e8 91 fc ff ff       	call   f010385a <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103bc9:	83 c4 10             	add    $0x10,%esp
f0103bcc:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103bd0:	74 25                	je     f0103bf7 <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103bd2:	83 ec 08             	sub    $0x8,%esp
f0103bd5:	ff 73 3c             	pushl  0x3c(%ebx)
f0103bd8:	68 f3 75 10 f0       	push   $0xf01075f3
f0103bdd:	e8 78 fc ff ff       	call   f010385a <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103be2:	83 c4 08             	add    $0x8,%esp
f0103be5:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103be9:	50                   	push   %eax
f0103bea:	68 02 76 10 f0       	push   $0xf0107602
f0103bef:	e8 66 fc ff ff       	call   f010385a <cprintf>
f0103bf4:	83 c4 10             	add    $0x10,%esp
	}
}
f0103bf7:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103bfa:	5b                   	pop    %ebx
f0103bfb:	5e                   	pop    %esi
f0103bfc:	5d                   	pop    %ebp
f0103bfd:	c3                   	ret    

f0103bfe <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103bfe:	55                   	push   %ebp
f0103bff:	89 e5                	mov    %esp,%ebp
f0103c01:	57                   	push   %edi
f0103c02:	56                   	push   %esi
f0103c03:	53                   	push   %ebx
f0103c04:	83 ec 1c             	sub    $0x1c,%esp
f0103c07:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103c0a:	0f 20 d6             	mov    %cr2,%esi
	// LAB 3: Your code here.


	//If the processor is already in kernel mode when the interrupt or exception occurs 
	//(the low 2 bits of the CS register are already zero), Hence we have to check the CS register to make sure its in kernel mode
	if ((tf->tf_cs & 0x11) == 0){
f0103c0d:	f6 43 34 11          	testb  $0x11,0x34(%ebx)
f0103c11:	75 15                	jne    f0103c28 <page_fault_handler+0x2a>
		panic("Fault occured in kernel space on %08x \n",fault_va);
f0103c13:	56                   	push   %esi
f0103c14:	68 d8 77 10 f0       	push   $0xf01077d8
f0103c19:	68 47 01 00 00       	push   $0x147
f0103c1e:	68 15 76 10 f0       	push   $0xf0107615
f0103c23:	e8 18 c4 ff ff       	call   f0100040 <_panic>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	//Store the current env's stack tf_esp for use, if the call occurs inside UXtrapframe  
	const uint32_t cur_tf_esp_addr = (uint32_t)(tf->tf_esp); 	// trap-time esp
f0103c28:	8b 7b 3c             	mov    0x3c(%ebx),%edi

	

	// If there is no env_pgfault_upcall or no page fault handler for the curenv follow the original procedure
	if (!curenv->env_pgfault_upcall)
f0103c2b:	e8 a7 1d 00 00       	call   f01059d7 <cpunum>
f0103c30:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c33:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0103c39:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f0103c3d:	75 46                	jne    f0103c85 <page_fault_handler+0x87>
	{
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c3f:	8b 43 30             	mov    0x30(%ebx),%eax
f0103c42:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			curenv->env_id, fault_va, tf->tf_eip);
f0103c45:	e8 8d 1d 00 00       	call   f01059d7 <cpunum>
	

	// If there is no env_pgfault_upcall or no page fault handler for the curenv follow the original procedure
	if (!curenv->env_pgfault_upcall)
	{
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c4a:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103c4d:	56                   	push   %esi
			curenv->env_id, fault_va, tf->tf_eip);
f0103c4e:	6b c0 74             	imul   $0x74,%eax,%eax
	

	// If there is no env_pgfault_upcall or no page fault handler for the curenv follow the original procedure
	if (!curenv->env_pgfault_upcall)
	{
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c51:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0103c57:	ff 70 48             	pushl  0x48(%eax)
f0103c5a:	68 00 78 10 f0       	push   $0xf0107800
f0103c5f:	e8 f6 fb ff ff       	call   f010385a <cprintf>
			curenv->env_id, fault_va, tf->tf_eip);
		print_trapframe(tf);
f0103c64:	89 1c 24             	mov    %ebx,(%esp)
f0103c67:	e8 0a fe ff ff       	call   f0103a76 <print_trapframe>
		env_destroy(curenv);	// Destroy the environment that caused the fault.
f0103c6c:	e8 66 1d 00 00       	call   f01059d7 <cpunum>
f0103c71:	83 c4 04             	add    $0x4,%esp
f0103c74:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c77:	ff b0 48 10 23 f0    	pushl  -0xfdcefb8(%eax)
f0103c7d:	e8 11 f9 ff ff       	call   f0103593 <env_destroy>
f0103c82:	83 c4 10             	add    $0x10,%esp
	}
	
	//Check if the	
	struct UTrapframe* usertf = NULL; //As defined in inc/trap.h
	
	if((cur_tf_esp_addr < UXSTACKTOP) && (cur_tf_esp_addr >=(UXSTACKTOP - PGSIZE)))
f0103c85:	8d 97 00 10 40 11    	lea    0x11401000(%edi),%edx
	{
		//If its already inside the exception stack
		//Allocate the address by leaving space for 32-bit word
		usertf = (struct UTrapframe*)(cur_tf_esp_addr - 4 - sizeof(struct UTrapframe));
f0103c8b:	8d 47 c8             	lea    -0x38(%edi),%eax
f0103c8e:	81 fa ff 0f 00 00    	cmp    $0xfff,%edx
f0103c94:	ba cc ff bf ee       	mov    $0xeebfffcc,%edx
f0103c99:	0f 46 d0             	cmovbe %eax,%edx
f0103c9c:	89 d7                	mov    %edx,%edi
		usertf = (struct UTrapframe*)(UXSTACKTOP - sizeof(struct UTrapframe));
	}
	
	//Check whether the usertf memory is valid
	//This function will not return if there is a fault and it will also destroy the environment
	user_mem_assert(curenv, (void*)usertf, sizeof(struct UTrapframe), PTE_U | PTE_P | PTE_W);
f0103c9e:	e8 34 1d 00 00       	call   f01059d7 <cpunum>
f0103ca3:	6a 07                	push   $0x7
f0103ca5:	6a 34                	push   $0x34
f0103ca7:	57                   	push   %edi
f0103ca8:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cab:	ff b0 48 10 23 f0    	pushl  -0xfdcefb8(%eax)
f0103cb1:	e8 47 f2 ff ff       	call   f0102efd <user_mem_assert>
	
	
	// User exeception trapframe
	usertf->utf_fault_va = fault_va;
f0103cb6:	89 fa                	mov    %edi,%edx
f0103cb8:	89 37                	mov    %esi,(%edi)
	usertf->utf_err = tf->tf_err;
f0103cba:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103cbd:	89 47 04             	mov    %eax,0x4(%edi)
	usertf->utf_regs = tf->tf_regs;
f0103cc0:	8d 7f 08             	lea    0x8(%edi),%edi
f0103cc3:	b9 08 00 00 00       	mov    $0x8,%ecx
f0103cc8:	89 de                	mov    %ebx,%esi
f0103cca:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	usertf->utf_eip = tf->tf_eip;
f0103ccc:	8b 43 30             	mov    0x30(%ebx),%eax
f0103ccf:	89 42 28             	mov    %eax,0x28(%edx)
	usertf->utf_esp = tf->tf_esp;
f0103cd2:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103cd5:	89 42 30             	mov    %eax,0x30(%edx)
	usertf->utf_eflags = tf->tf_eflags;
f0103cd8:	8b 43 38             	mov    0x38(%ebx),%eax
f0103cdb:	89 42 2c             	mov    %eax,0x2c(%edx)
	
	//Setup the tf with Exception stack frame
	
	tf->tf_esp= (uintptr_t)usertf;
f0103cde:	89 53 3c             	mov    %edx,0x3c(%ebx)
	tf->tf_eip = (uintptr_t)curenv->env_pgfault_upcall; 
f0103ce1:	e8 f1 1c 00 00       	call   f01059d7 <cpunum>
f0103ce6:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ce9:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0103cef:	8b 40 64             	mov    0x64(%eax),%eax
f0103cf2:	89 43 30             	mov    %eax,0x30(%ebx)

	env_run(curenv);
f0103cf5:	e8 dd 1c 00 00       	call   f01059d7 <cpunum>
f0103cfa:	83 c4 04             	add    $0x4,%esp
f0103cfd:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d00:	ff b0 48 10 23 f0    	pushl  -0xfdcefb8(%eax)
f0103d06:	e8 27 f9 ff ff       	call   f0103632 <env_run>

f0103d0b <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103d0b:	55                   	push   %ebp
f0103d0c:	89 e5                	mov    %esp,%ebp
f0103d0e:	57                   	push   %edi
f0103d0f:	56                   	push   %esi
f0103d10:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103d13:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103d14:	83 3d c0 0e 23 f0 00 	cmpl   $0x0,0xf0230ec0
f0103d1b:	74 01                	je     f0103d1e <trap+0x13>
		asm volatile("hlt");
f0103d1d:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103d1e:	e8 b4 1c 00 00       	call   f01059d7 <cpunum>
f0103d23:	6b d0 74             	imul   $0x74,%eax,%edx
f0103d26:	81 c2 40 10 23 f0    	add    $0xf0231040,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0103d2c:	b8 01 00 00 00       	mov    $0x1,%eax
f0103d31:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103d35:	83 f8 02             	cmp    $0x2,%eax
f0103d38:	75 10                	jne    f0103d4a <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103d3a:	83 ec 0c             	sub    $0xc,%esp
f0103d3d:	68 c0 04 12 f0       	push   $0xf01204c0
f0103d42:	e8 fb 1e 00 00       	call   f0105c42 <spin_lock>
f0103d47:	83 c4 10             	add    $0x10,%esp

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103d4a:	9c                   	pushf  
f0103d4b:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103d4c:	f6 c4 02             	test   $0x2,%ah
f0103d4f:	74 19                	je     f0103d6a <trap+0x5f>
f0103d51:	68 21 76 10 f0       	push   $0xf0107621
f0103d56:	68 5b 70 10 f0       	push   $0xf010705b
f0103d5b:	68 0d 01 00 00       	push   $0x10d
f0103d60:	68 15 76 10 f0       	push   $0xf0107615
f0103d65:	e8 d6 c2 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103d6a:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103d6e:	83 e0 03             	and    $0x3,%eax
f0103d71:	66 83 f8 03          	cmp    $0x3,%ax
f0103d75:	0f 85 a0 00 00 00    	jne    f0103e1b <trap+0x110>
f0103d7b:	83 ec 0c             	sub    $0xc,%esp
f0103d7e:	68 c0 04 12 f0       	push   $0xf01204c0
f0103d83:	e8 ba 1e 00 00       	call   f0105c42 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel(); //Lock Kernel
		assert(curenv);
f0103d88:	e8 4a 1c 00 00       	call   f01059d7 <cpunum>
f0103d8d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d90:	83 c4 10             	add    $0x10,%esp
f0103d93:	83 b8 48 10 23 f0 00 	cmpl   $0x0,-0xfdcefb8(%eax)
f0103d9a:	75 19                	jne    f0103db5 <trap+0xaa>
f0103d9c:	68 3a 76 10 f0       	push   $0xf010763a
f0103da1:	68 5b 70 10 f0       	push   $0xf010705b
f0103da6:	68 15 01 00 00       	push   $0x115
f0103dab:	68 15 76 10 f0       	push   $0xf0107615
f0103db0:	e8 8b c2 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103db5:	e8 1d 1c 00 00       	call   f01059d7 <cpunum>
f0103dba:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dbd:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0103dc3:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103dc7:	75 2d                	jne    f0103df6 <trap+0xeb>
			env_free(curenv);
f0103dc9:	e8 09 1c 00 00       	call   f01059d7 <cpunum>
f0103dce:	83 ec 0c             	sub    $0xc,%esp
f0103dd1:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dd4:	ff b0 48 10 23 f0    	pushl  -0xfdcefb8(%eax)
f0103dda:	e8 d9 f5 ff ff       	call   f01033b8 <env_free>
			curenv = NULL;
f0103ddf:	e8 f3 1b 00 00       	call   f01059d7 <cpunum>
f0103de4:	6b c0 74             	imul   $0x74,%eax,%eax
f0103de7:	c7 80 48 10 23 f0 00 	movl   $0x0,-0xfdcefb8(%eax)
f0103dee:	00 00 00 
			sched_yield();
f0103df1:	e8 f6 03 00 00       	call   f01041ec <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103df6:	e8 dc 1b 00 00       	call   f01059d7 <cpunum>
f0103dfb:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dfe:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0103e04:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103e09:	89 c7                	mov    %eax,%edi
f0103e0b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103e0d:	e8 c5 1b 00 00       	call   f01059d7 <cpunum>
f0103e12:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e15:	8b b0 48 10 23 f0    	mov    -0xfdcefb8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103e1b:	89 35 80 0a 23 f0    	mov    %esi,0xf0230a80
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	//call trap_handler function for page_fault
	switch (tf->tf_trapno) {
f0103e21:	8b 46 28             	mov    0x28(%esi),%eax
f0103e24:	83 f8 0e             	cmp    $0xe,%eax
f0103e27:	74 24                	je     f0103e4d <trap+0x142>
f0103e29:	83 f8 30             	cmp    $0x30,%eax
f0103e2c:	74 28                	je     f0103e56 <trap+0x14b>
f0103e2e:	83 f8 03             	cmp    $0x3,%eax
f0103e31:	75 44                	jne    f0103e77 <trap+0x16c>
		case T_BRKPT:
			monitor(tf);
f0103e33:	83 ec 0c             	sub    $0xc,%esp
f0103e36:	56                   	push   %esi
f0103e37:	e8 a2 ca ff ff       	call   f01008de <monitor>
			cprintf("return from breakpoint....\n");
f0103e3c:	c7 04 24 41 76 10 f0 	movl   $0xf0107641,(%esp)
f0103e43:	e8 12 fa ff ff       	call   f010385a <cprintf>
f0103e48:	83 c4 10             	add    $0x10,%esp
f0103e4b:	eb 2a                	jmp    f0103e77 <trap+0x16c>
			break;

		case T_PGFLT:
			page_fault_handler(tf);
f0103e4d:	83 ec 0c             	sub    $0xc,%esp
f0103e50:	56                   	push   %esi
f0103e51:	e8 a8 fd ff ff       	call   f0103bfe <page_fault_handler>
			break;

		case T_SYSCALL:
			tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax,
f0103e56:	83 ec 08             	sub    $0x8,%esp
f0103e59:	ff 76 04             	pushl  0x4(%esi)
f0103e5c:	ff 36                	pushl  (%esi)
f0103e5e:	ff 76 10             	pushl  0x10(%esi)
f0103e61:	ff 76 18             	pushl  0x18(%esi)
f0103e64:	ff 76 14             	pushl  0x14(%esi)
f0103e67:	ff 76 1c             	pushl  0x1c(%esi)
f0103e6a:	e8 5d 04 00 00       	call   f01042cc <syscall>
f0103e6f:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103e72:	83 c4 20             	add    $0x20,%esp
f0103e75:	eb 74                	jmp    f0103eeb <trap+0x1e0>
	}

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0103e77:	8b 46 28             	mov    0x28(%esi),%eax
f0103e7a:	83 f8 27             	cmp    $0x27,%eax
f0103e7d:	75 1a                	jne    f0103e99 <trap+0x18e>
		cprintf("Spurious interrupt on irq 7\n");
f0103e7f:	83 ec 0c             	sub    $0xc,%esp
f0103e82:	68 5d 76 10 f0       	push   $0xf010765d
f0103e87:	e8 ce f9 ff ff       	call   f010385a <cprintf>
		print_trapframe(tf);
f0103e8c:	89 34 24             	mov    %esi,(%esp)
f0103e8f:	e8 e2 fb ff ff       	call   f0103a76 <print_trapframe>
f0103e94:	83 c4 10             	add    $0x10,%esp
f0103e97:	eb 52                	jmp    f0103eeb <trap+0x1e0>
	}

	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_TIMER) {
f0103e99:	83 f8 20             	cmp    $0x20,%eax
f0103e9c:	75 0a                	jne    f0103ea8 <trap+0x19d>
		lapic_eoi();
f0103e9e:	e8 7f 1c 00 00       	call   f0105b22 <lapic_eoi>
		sched_yield();
f0103ea3:	e8 44 03 00 00       	call   f01041ec <sched_yield>
	}
	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103ea8:	83 ec 0c             	sub    $0xc,%esp
f0103eab:	56                   	push   %esi
f0103eac:	e8 c5 fb ff ff       	call   f0103a76 <print_trapframe>
	if (tf->tf_cs == GD_KT){
f0103eb1:	83 c4 10             	add    $0x10,%esp
f0103eb4:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103eb9:	75 17                	jne    f0103ed2 <trap+0x1c7>
		panic("unhandled trap in kernel");
f0103ebb:	83 ec 04             	sub    $0x4,%esp
f0103ebe:	68 7a 76 10 f0       	push   $0xf010767a
f0103ec3:	68 f2 00 00 00       	push   $0xf2
f0103ec8:	68 15 76 10 f0       	push   $0xf0107615
f0103ecd:	e8 6e c1 ff ff       	call   f0100040 <_panic>
	}
	else {
		env_destroy(curenv);
f0103ed2:	e8 00 1b 00 00       	call   f01059d7 <cpunum>
f0103ed7:	83 ec 0c             	sub    $0xc,%esp
f0103eda:	6b c0 74             	imul   $0x74,%eax,%eax
f0103edd:	ff b0 48 10 23 f0    	pushl  -0xfdcefb8(%eax)
f0103ee3:	e8 ab f6 ff ff       	call   f0103593 <env_destroy>
f0103ee8:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103eeb:	e8 e7 1a 00 00       	call   f01059d7 <cpunum>
f0103ef0:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ef3:	83 b8 48 10 23 f0 00 	cmpl   $0x0,-0xfdcefb8(%eax)
f0103efa:	74 2a                	je     f0103f26 <trap+0x21b>
f0103efc:	e8 d6 1a 00 00       	call   f01059d7 <cpunum>
f0103f01:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f04:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0103f0a:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103f0e:	75 16                	jne    f0103f26 <trap+0x21b>
		env_run(curenv);
f0103f10:	e8 c2 1a 00 00       	call   f01059d7 <cpunum>
f0103f15:	83 ec 0c             	sub    $0xc,%esp
f0103f18:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f1b:	ff b0 48 10 23 f0    	pushl  -0xfdcefb8(%eax)
f0103f21:	e8 0c f7 ff ff       	call   f0103632 <env_run>
	else
		sched_yield();
f0103f26:	e8 c1 02 00 00       	call   f01041ec <sched_yield>
f0103f2b:	90                   	nop

f0103f2c <handler_0>:
#define T_DEFAULT   500		// catchall
*/

//TRAPHANDLER_NOEC for traps without error code
// From 0-7 no error code requred
	TRAPHANDLER_NOEC(handler_0, 0)   #Divide error
f0103f2c:	6a 00                	push   $0x0
f0103f2e:	6a 00                	push   $0x0
f0103f30:	e9 d2 01 00 00       	jmp    f0104107 <_alltraps>
f0103f35:	90                   	nop

f0103f36 <handler_1>:
	TRAPHANDLER_NOEC(handler_1, 1)   #Debug exceptions 
f0103f36:	6a 00                	push   $0x0
f0103f38:	6a 01                	push   $0x1
f0103f3a:	e9 c8 01 00 00       	jmp    f0104107 <_alltraps>
f0103f3f:	90                   	nop

f0103f40 <handler_2>:
 	TRAPHANDLER_NOEC(handler_2, 2)   //NMI Interrupt
f0103f40:	6a 00                	push   $0x0
f0103f42:	6a 02                	push   $0x2
f0103f44:	e9 be 01 00 00       	jmp    f0104107 <_alltraps>
f0103f49:	90                   	nop

f0103f4a <handler_3>:
	TRAPHANDLER_NOEC(handler_3, 3)   //Breakpoint
f0103f4a:	6a 00                	push   $0x0
f0103f4c:	6a 03                	push   $0x3
f0103f4e:	e9 b4 01 00 00       	jmp    f0104107 <_alltraps>
f0103f53:	90                   	nop

f0103f54 <handler_4>:
	TRAPHANDLER_NOEC(handler_4, 4)   //Overflow
f0103f54:	6a 00                	push   $0x0
f0103f56:	6a 04                	push   $0x4
f0103f58:	e9 aa 01 00 00       	jmp    f0104107 <_alltraps>
f0103f5d:	90                   	nop

f0103f5e <handler_5>:
	TRAPHANDLER_NOEC(handler_5, 5)   //Bounds check 
f0103f5e:	6a 00                	push   $0x0
f0103f60:	6a 05                	push   $0x5
f0103f62:	e9 a0 01 00 00       	jmp    f0104107 <_alltraps>
f0103f67:	90                   	nop

f0103f68 <handler_6>:
	TRAPHANDLER_NOEC(handler_6, 6)   //Invalid opcode
f0103f68:	6a 00                	push   $0x0
f0103f6a:	6a 06                	push   $0x6
f0103f6c:	e9 96 01 00 00       	jmp    f0104107 <_alltraps>
f0103f71:	90                   	nop

f0103f72 <handler_7>:
	TRAPHANDLER_NOEC(handler_7, 7)   //Coprocessor not available
f0103f72:	6a 00                	push   $0x0
f0103f74:	6a 07                	push   $0x7
f0103f76:	e9 8c 01 00 00       	jmp    f0104107 <_alltraps>
f0103f7b:	90                   	nop

f0103f7c <handler_8>:
	
	TRAPHANDLER(handler_8, 8)   // double fault
f0103f7c:	6a 08                	push   $0x8
f0103f7e:	e9 84 01 00 00       	jmp    f0104107 <_alltraps>
f0103f83:	90                   	nop

f0103f84 <handler_9>:
	
	TRAPHANDLER_NOEC(handler_9, 9)   //Coprocessor Segment Overrun
f0103f84:	6a 00                	push   $0x0
f0103f86:	6a 09                	push   $0x9
f0103f88:	e9 7a 01 00 00       	jmp    f0104107 <_alltraps>
f0103f8d:	90                   	nop

f0103f8e <handler_10>:

	TRAPHANDLER(handler_10, 10)   // invalid task switch segment
f0103f8e:	6a 0a                	push   $0xa
f0103f90:	e9 72 01 00 00       	jmp    f0104107 <_alltraps>
f0103f95:	90                   	nop

f0103f96 <handler_11>:
	TRAPHANDLER(handler_11, 11)   // segment not present
f0103f96:	6a 0b                	push   $0xb
f0103f98:	e9 6a 01 00 00       	jmp    f0104107 <_alltraps>
f0103f9d:	90                   	nop

f0103f9e <handler_12>:
	TRAPHANDLER(handler_12, 12)   // stack exception
f0103f9e:	6a 0c                	push   $0xc
f0103fa0:	e9 62 01 00 00       	jmp    f0104107 <_alltraps>
f0103fa5:	90                   	nop

f0103fa6 <handler_13>:
	TRAPHANDLER(handler_13, 13)   // general protection fault
f0103fa6:	6a 0d                	push   $0xd
f0103fa8:	e9 5a 01 00 00       	jmp    f0104107 <_alltraps>
f0103fad:	90                   	nop

f0103fae <handler_14>:
	TRAPHANDLER(handler_14, 14)   // page fault
f0103fae:	6a 0e                	push   $0xe
f0103fb0:	e9 52 01 00 00       	jmp    f0104107 <_alltraps>
f0103fb5:	90                   	nop

f0103fb6 <handler_15>:

	TRAPHANDLER_NOEC(handler_15, 15)   // Reserved
f0103fb6:	6a 00                	push   $0x0
f0103fb8:	6a 0f                	push   $0xf
f0103fba:	e9 48 01 00 00       	jmp    f0104107 <_alltraps>
f0103fbf:	90                   	nop

f0103fc0 <handler_16>:

	TRAPHANDLER_NOEC(handler_16, 16)   // floating point error
f0103fc0:	6a 00                	push   $0x0
f0103fc2:	6a 10                	push   $0x10
f0103fc4:	e9 3e 01 00 00       	jmp    f0104107 <_alltraps>
f0103fc9:	90                   	nop

f0103fca <handler_17>:

	TRAPHANDLER(handler_17, 17)   // aligment check
f0103fca:	6a 11                	push   $0x11
f0103fcc:	e9 36 01 00 00       	jmp    f0104107 <_alltraps>
f0103fd1:	90                   	nop

f0103fd2 <handler_18>:

	TRAPHANDLER_NOEC(handler_18, 18)   // machine check
f0103fd2:	6a 00                	push   $0x0
f0103fd4:	6a 12                	push   $0x12
f0103fd6:	e9 2c 01 00 00       	jmp    f0104107 <_alltraps>
f0103fdb:	90                   	nop

f0103fdc <handler_19>:
	TRAPHANDLER_NOEC(handler_19, 19)   // SIMD floating point error
f0103fdc:	6a 00                	push   $0x0
f0103fde:	6a 13                	push   $0x13
f0103fe0:	e9 22 01 00 00       	jmp    f0104107 <_alltraps>
f0103fe5:	90                   	nop

f0103fe6 <handler_20>:

	TRAPHANDLER_NOEC(handler_20, 20)
f0103fe6:	6a 00                	push   $0x0
f0103fe8:	6a 14                	push   $0x14
f0103fea:	e9 18 01 00 00       	jmp    f0104107 <_alltraps>
f0103fef:	90                   	nop

f0103ff0 <handler_21>:
	TRAPHANDLER_NOEC(handler_21, 21)
f0103ff0:	6a 00                	push   $0x0
f0103ff2:	6a 15                	push   $0x15
f0103ff4:	e9 0e 01 00 00       	jmp    f0104107 <_alltraps>
f0103ff9:	90                   	nop

f0103ffa <handler_22>:
	TRAPHANDLER_NOEC(handler_22, 22)
f0103ffa:	6a 00                	push   $0x0
f0103ffc:	6a 16                	push   $0x16
f0103ffe:	e9 04 01 00 00       	jmp    f0104107 <_alltraps>
f0104003:	90                   	nop

f0104004 <handler_23>:
	TRAPHANDLER_NOEC(handler_23, 23)
f0104004:	6a 00                	push   $0x0
f0104006:	6a 17                	push   $0x17
f0104008:	e9 fa 00 00 00       	jmp    f0104107 <_alltraps>
f010400d:	90                   	nop

f010400e <handler_24>:
	TRAPHANDLER_NOEC(handler_24, 24)
f010400e:	6a 00                	push   $0x0
f0104010:	6a 18                	push   $0x18
f0104012:	e9 f0 00 00 00       	jmp    f0104107 <_alltraps>
f0104017:	90                   	nop

f0104018 <handler_25>:
	TRAPHANDLER_NOEC(handler_25, 25)
f0104018:	6a 00                	push   $0x0
f010401a:	6a 19                	push   $0x19
f010401c:	e9 e6 00 00 00       	jmp    f0104107 <_alltraps>
f0104021:	90                   	nop

f0104022 <handler_26>:
	TRAPHANDLER_NOEC(handler_26, 26)
f0104022:	6a 00                	push   $0x0
f0104024:	6a 1a                	push   $0x1a
f0104026:	e9 dc 00 00 00       	jmp    f0104107 <_alltraps>
f010402b:	90                   	nop

f010402c <handler_27>:
	TRAPHANDLER_NOEC(handler_27, 27)
f010402c:	6a 00                	push   $0x0
f010402e:	6a 1b                	push   $0x1b
f0104030:	e9 d2 00 00 00       	jmp    f0104107 <_alltraps>
f0104035:	90                   	nop

f0104036 <handler_28>:
	TRAPHANDLER_NOEC(handler_28, 28)
f0104036:	6a 00                	push   $0x0
f0104038:	6a 1c                	push   $0x1c
f010403a:	e9 c8 00 00 00       	jmp    f0104107 <_alltraps>
f010403f:	90                   	nop

f0104040 <handler_29>:
	TRAPHANDLER_NOEC(handler_29, 29)
f0104040:	6a 00                	push   $0x0
f0104042:	6a 1d                	push   $0x1d
f0104044:	e9 be 00 00 00       	jmp    f0104107 <_alltraps>
f0104049:	90                   	nop

f010404a <handler_30>:
	TRAPHANDLER_NOEC(handler_30, 30)
f010404a:	6a 00                	push   $0x0
f010404c:	6a 1e                	push   $0x1e
f010404e:	e9 b4 00 00 00       	jmp    f0104107 <_alltraps>
f0104053:	90                   	nop

f0104054 <handler_31>:
	TRAPHANDLER_NOEC(handler_31, 31)
f0104054:	6a 00                	push   $0x0
f0104056:	6a 1f                	push   $0x1f
f0104058:	e9 aa 00 00 00       	jmp    f0104107 <_alltraps>
f010405d:	90                   	nop

f010405e <handler_32>:
	TRAPHANDLER_NOEC(handler_32, 32)
f010405e:	6a 00                	push   $0x0
f0104060:	6a 20                	push   $0x20
f0104062:	e9 a0 00 00 00       	jmp    f0104107 <_alltraps>
f0104067:	90                   	nop

f0104068 <handler_33>:
	TRAPHANDLER_NOEC(handler_33, 33)
f0104068:	6a 00                	push   $0x0
f010406a:	6a 21                	push   $0x21
f010406c:	e9 96 00 00 00       	jmp    f0104107 <_alltraps>
f0104071:	90                   	nop

f0104072 <handler_34>:
	TRAPHANDLER_NOEC(handler_34, 34)
f0104072:	6a 00                	push   $0x0
f0104074:	6a 22                	push   $0x22
f0104076:	e9 8c 00 00 00       	jmp    f0104107 <_alltraps>
f010407b:	90                   	nop

f010407c <handler_35>:
	TRAPHANDLER_NOEC(handler_35, 35)
f010407c:	6a 00                	push   $0x0
f010407e:	6a 23                	push   $0x23
f0104080:	e9 82 00 00 00       	jmp    f0104107 <_alltraps>
f0104085:	90                   	nop

f0104086 <handler_36>:
	TRAPHANDLER_NOEC(handler_36, 36)
f0104086:	6a 00                	push   $0x0
f0104088:	6a 24                	push   $0x24
f010408a:	e9 78 00 00 00       	jmp    f0104107 <_alltraps>
f010408f:	90                   	nop

f0104090 <handler_37>:
	TRAPHANDLER_NOEC(handler_37, 37)
f0104090:	6a 00                	push   $0x0
f0104092:	6a 25                	push   $0x25
f0104094:	e9 6e 00 00 00       	jmp    f0104107 <_alltraps>
f0104099:	90                   	nop

f010409a <handler_38>:
	TRAPHANDLER_NOEC(handler_38, 38)
f010409a:	6a 00                	push   $0x0
f010409c:	6a 26                	push   $0x26
f010409e:	e9 64 00 00 00       	jmp    f0104107 <_alltraps>
f01040a3:	90                   	nop

f01040a4 <handler_39>:
	TRAPHANDLER_NOEC(handler_39, 39)
f01040a4:	6a 00                	push   $0x0
f01040a6:	6a 27                	push   $0x27
f01040a8:	e9 5a 00 00 00       	jmp    f0104107 <_alltraps>
f01040ad:	90                   	nop

f01040ae <handler_40>:
	TRAPHANDLER_NOEC(handler_40, 40)
f01040ae:	6a 00                	push   $0x0
f01040b0:	6a 28                	push   $0x28
f01040b2:	e9 50 00 00 00       	jmp    f0104107 <_alltraps>
f01040b7:	90                   	nop

f01040b8 <handler_41>:
	TRAPHANDLER_NOEC(handler_41, 41)
f01040b8:	6a 00                	push   $0x0
f01040ba:	6a 29                	push   $0x29
f01040bc:	e9 46 00 00 00       	jmp    f0104107 <_alltraps>
f01040c1:	90                   	nop

f01040c2 <handler_42>:
	TRAPHANDLER_NOEC(handler_42, 42)
f01040c2:	6a 00                	push   $0x0
f01040c4:	6a 2a                	push   $0x2a
f01040c6:	e9 3c 00 00 00       	jmp    f0104107 <_alltraps>
f01040cb:	90                   	nop

f01040cc <handler_43>:
	TRAPHANDLER_NOEC(handler_43, 43)
f01040cc:	6a 00                	push   $0x0
f01040ce:	6a 2b                	push   $0x2b
f01040d0:	e9 32 00 00 00       	jmp    f0104107 <_alltraps>
f01040d5:	90                   	nop

f01040d6 <handler_44>:
	TRAPHANDLER_NOEC(handler_44, 44)
f01040d6:	6a 00                	push   $0x0
f01040d8:	6a 2c                	push   $0x2c
f01040da:	e9 28 00 00 00       	jmp    f0104107 <_alltraps>
f01040df:	90                   	nop

f01040e0 <handler_45>:
	TRAPHANDLER_NOEC(handler_45, 45)
f01040e0:	6a 00                	push   $0x0
f01040e2:	6a 2d                	push   $0x2d
f01040e4:	e9 1e 00 00 00       	jmp    f0104107 <_alltraps>
f01040e9:	90                   	nop

f01040ea <handler_46>:
	TRAPHANDLER_NOEC(handler_46, 46)
f01040ea:	6a 00                	push   $0x0
f01040ec:	6a 2e                	push   $0x2e
f01040ee:	e9 14 00 00 00       	jmp    f0104107 <_alltraps>
f01040f3:	90                   	nop

f01040f4 <handler_47>:
	TRAPHANDLER_NOEC(handler_47, 47)
f01040f4:	6a 00                	push   $0x0
f01040f6:	6a 2f                	push   $0x2f
f01040f8:	e9 0a 00 00 00       	jmp    f0104107 <_alltraps>
f01040fd:	90                   	nop

f01040fe <handler_48>:

	TRAPHANDLER_NOEC(handler_48, 48)   // system call
f01040fe:	6a 00                	push   $0x0
f0104100:	6a 30                	push   $0x30
f0104102:	e9 00 00 00 00       	jmp    f0104107 <_alltraps>

f0104107 <_alltraps>:
 */

.globl _alltraps
_alltraps:
	#Remaining Trap frame
	push %ds
f0104107:	1e                   	push   %ds
	push %es
f0104108:	06                   	push   %es
	pushal
f0104109:	60                   	pusha  

	
	movw $GD_KD, %ax
f010410a:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f010410e:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f0104110:	8e c0                	mov    %eax,%es

	#call Trap 
	pushl %esp
f0104112:	54                   	push   %esp
	call trap
f0104113:	e8 f3 fb ff ff       	call   f0103d0b <trap>

f0104118 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0104118:	55                   	push   %ebp
f0104119:	89 e5                	mov    %esp,%ebp
f010411b:	83 ec 08             	sub    $0x8,%esp
f010411e:	a1 6c 02 23 f0       	mov    0xf023026c,%eax
f0104123:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104126:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
f010412b:	8b 02                	mov    (%edx),%eax
f010412d:	83 e8 01             	sub    $0x1,%eax
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0104130:	83 f8 02             	cmp    $0x2,%eax
f0104133:	76 10                	jbe    f0104145 <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104135:	83 c1 01             	add    $0x1,%ecx
f0104138:	83 c2 7c             	add    $0x7c,%edx
f010413b:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0104141:	75 e8                	jne    f010412b <sched_halt+0x13>
f0104143:	eb 08                	jmp    f010414d <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f0104145:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f010414b:	75 1f                	jne    f010416c <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f010414d:	83 ec 0c             	sub    $0xc,%esp
f0104150:	68 90 78 10 f0       	push   $0xf0107890
f0104155:	e8 00 f7 ff ff       	call   f010385a <cprintf>
f010415a:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f010415d:	83 ec 0c             	sub    $0xc,%esp
f0104160:	6a 00                	push   $0x0
f0104162:	e8 77 c7 ff ff       	call   f01008de <monitor>
f0104167:	83 c4 10             	add    $0x10,%esp
f010416a:	eb f1                	jmp    f010415d <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f010416c:	e8 66 18 00 00       	call   f01059d7 <cpunum>
f0104171:	6b c0 74             	imul   $0x74,%eax,%eax
f0104174:	c7 80 48 10 23 f0 00 	movl   $0x0,-0xfdcefb8(%eax)
f010417b:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f010417e:	a1 cc 0e 23 f0       	mov    0xf0230ecc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0104183:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0104188:	77 12                	ja     f010419c <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010418a:	50                   	push   %eax
f010418b:	68 c8 60 10 f0       	push   $0xf01060c8
f0104190:	6a 54                	push   $0x54
f0104192:	68 b9 78 10 f0       	push   $0xf01078b9
f0104197:	e8 a4 be ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010419c:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01041a1:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f01041a4:	e8 2e 18 00 00       	call   f01059d7 <cpunum>
f01041a9:	6b d0 74             	imul   $0x74,%eax,%edx
f01041ac:	81 c2 40 10 23 f0    	add    $0xf0231040,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f01041b2:	b8 02 00 00 00       	mov    $0x2,%eax
f01041b7:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01041bb:	83 ec 0c             	sub    $0xc,%esp
f01041be:	68 c0 04 12 f0       	push   $0xf01204c0
f01041c3:	e8 17 1b 00 00       	call   f0105cdf <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01041c8:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f01041ca:	e8 08 18 00 00       	call   f01059d7 <cpunum>
f01041cf:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f01041d2:	8b 80 50 10 23 f0    	mov    -0xfdcefb0(%eax),%eax
f01041d8:	bd 00 00 00 00       	mov    $0x0,%ebp
f01041dd:	89 c4                	mov    %eax,%esp
f01041df:	6a 00                	push   $0x0
f01041e1:	6a 00                	push   $0x0
f01041e3:	fb                   	sti    
f01041e4:	f4                   	hlt    
f01041e5:	eb fd                	jmp    f01041e4 <sched_halt+0xcc>
f01041e7:	83 c4 10             	add    $0x10,%esp
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f01041ea:	c9                   	leave  
f01041eb:	c3                   	ret    

f01041ec <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f01041ec:	55                   	push   %ebp
f01041ed:	89 e5                	mov    %esp,%ebp
f01041ef:	53                   	push   %ebx
f01041f0:	83 ec 04             	sub    $0x4,%esp
	// below to halt the cpu.

	// LAB 4: Your code here.
	int envVal, j = 0 ;
	 
	if (curenv)
f01041f3:	e8 df 17 00 00       	call   f01059d7 <cpunum>
f01041f8:	6b c0 74             	imul   $0x74,%eax,%eax
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
						     // we can use the value 'curenv- envs' to get the current env and +1 to get the next env
	else 
		envVal = 0; 
f01041fb:	ba 00 00 00 00       	mov    $0x0,%edx
	// below to halt the cpu.

	// LAB 4: Your code here.
	int envVal, j = 0 ;
	 
	if (curenv)
f0104200:	83 b8 48 10 23 f0 00 	cmpl   $0x0,-0xfdcefb8(%eax)
f0104207:	74 33                	je     f010423c <sched_yield+0x50>
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
f0104209:	e8 c9 17 00 00       	call   f01059d7 <cpunum>
f010420e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104211:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0104217:	2b 05 6c 02 23 f0    	sub    0xf023026c,%eax
f010421d:	c1 f8 02             	sar    $0x2,%eax
f0104220:	69 c0 df 7b ef bd    	imul   $0xbdef7bdf,%eax,%eax
f0104226:	83 c0 01             	add    $0x1,%eax
f0104229:	89 c1                	mov    %eax,%ecx
f010422b:	c1 f9 1f             	sar    $0x1f,%ecx
f010422e:	c1 e9 16             	shr    $0x16,%ecx
f0104231:	8d 14 08             	lea    (%eax,%ecx,1),%edx
f0104234:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010423a:	29 ca                	sub    %ecx,%edx
	else 
		envVal = 0; 
	
	for (j = 0; j< NENV; j++)
	{
		if (envs[envVal].env_status == ENV_RUNNABLE)
f010423c:	a1 6c 02 23 f0       	mov    0xf023026c,%eax
f0104241:	b9 00 04 00 00       	mov    $0x400,%ecx
f0104246:	6b da 7c             	imul   $0x7c,%edx,%ebx
f0104249:	83 7c 18 54 02       	cmpl   $0x2,0x54(%eax,%ebx,1)
f010424e:	74 70                	je     f01042c0 <sched_yield+0xd4>
		    break;
		else
		    envVal=(envVal+1)%NENV;
f0104250:	83 c2 01             	add    $0x1,%edx
f0104253:	89 d3                	mov    %edx,%ebx
f0104255:	c1 fb 1f             	sar    $0x1f,%ebx
f0104258:	c1 eb 16             	shr    $0x16,%ebx
f010425b:	01 da                	add    %ebx,%edx
f010425d:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0104263:	29 da                	sub    %ebx,%edx
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
						     // we can use the value 'curenv- envs' to get the current env and +1 to get the next env
	else 
		envVal = 0; 
	
	for (j = 0; j< NENV; j++)
f0104265:	83 e9 01             	sub    $0x1,%ecx
f0104268:	75 dc                	jne    f0104246 <sched_yield+0x5a>
		    break;
		else
		    envVal=(envVal+1)%NENV;
	}
	
	if (envs[envVal].env_status == ENV_RUNNABLE)
f010426a:	6b d2 7c             	imul   $0x7c,%edx,%edx
f010426d:	01 c2                	add    %eax,%edx
f010426f:	83 7a 54 02          	cmpl   $0x2,0x54(%edx)
f0104273:	75 09                	jne    f010427e <sched_yield+0x92>
	{
	    idle = envs + envVal ;
	    env_run(idle);
f0104275:	83 ec 0c             	sub    $0xc,%esp
f0104278:	52                   	push   %edx
f0104279:	e8 b4 f3 ff ff       	call   f0103632 <env_run>
	} 
	else if (!idle && (curenv) && (curenv->env_status == ENV_RUNNING) ){
f010427e:	e8 54 17 00 00       	call   f01059d7 <cpunum>
f0104283:	6b c0 74             	imul   $0x74,%eax,%eax
f0104286:	83 b8 48 10 23 f0 00 	cmpl   $0x0,-0xfdcefb8(%eax)
f010428d:	74 2a                	je     f01042b9 <sched_yield+0xcd>
f010428f:	e8 43 17 00 00       	call   f01059d7 <cpunum>
f0104294:	6b c0 74             	imul   $0x74,%eax,%eax
f0104297:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f010429d:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01042a1:	75 16                	jne    f01042b9 <sched_yield+0xcd>
	    env_run(curenv) ;
f01042a3:	e8 2f 17 00 00       	call   f01059d7 <cpunum>
f01042a8:	83 ec 0c             	sub    $0xc,%esp
f01042ab:	6b c0 74             	imul   $0x74,%eax,%eax
f01042ae:	ff b0 48 10 23 f0    	pushl  -0xfdcefb8(%eax)
f01042b4:	e8 79 f3 ff ff       	call   f0103632 <env_run>
	}
	// sched_halt never returns
	sched_halt();
f01042b9:	e8 5a fe ff ff       	call   f0104118 <sched_halt>
f01042be:	eb 07                	jmp    f01042c7 <sched_yield+0xdb>
		    break;
		else
		    envVal=(envVal+1)%NENV;
	}
	
	if (envs[envVal].env_status == ENV_RUNNABLE)
f01042c0:	6b d2 7c             	imul   $0x7c,%edx,%edx
f01042c3:	01 c2                	add    %eax,%edx
f01042c5:	eb ae                	jmp    f0104275 <sched_yield+0x89>
	else if (!idle && (curenv) && (curenv->env_status == ENV_RUNNING) ){
	    env_run(curenv) ;
	}
	// sched_halt never returns
	sched_halt();
}
f01042c7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01042ca:	c9                   	leave  
f01042cb:	c3                   	ret    

f01042cc <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01042cc:	55                   	push   %ebp
f01042cd:	89 e5                	mov    %esp,%ebp
f01042cf:	57                   	push   %edi
f01042d0:	56                   	push   %esi
f01042d1:	53                   	push   %ebx
f01042d2:	83 ec 1c             	sub    $0x1c,%esp
f01042d5:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	

	switch (syscallno) {
f01042d8:	83 f8 0c             	cmp    $0xc,%eax
f01042db:	0f 87 2d 05 00 00    	ja     f010480e <syscall+0x542>
f01042e1:	ff 24 85 24 79 10 f0 	jmp    *-0xfef86dc(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_P | PTE_U);
f01042e8:	e8 ea 16 00 00       	call   f01059d7 <cpunum>
f01042ed:	6a 05                	push   $0x5
f01042ef:	ff 75 10             	pushl  0x10(%ebp)
f01042f2:	ff 75 0c             	pushl  0xc(%ebp)
f01042f5:	6b c0 74             	imul   $0x74,%eax,%eax
f01042f8:	ff b0 48 10 23 f0    	pushl  -0xfdcefb8(%eax)
f01042fe:	e8 fa eb ff ff       	call   f0102efd <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0104303:	83 c4 0c             	add    $0xc,%esp
f0104306:	ff 75 0c             	pushl  0xc(%ebp)
f0104309:	ff 75 10             	pushl  0x10(%ebp)
f010430c:	68 c6 78 10 f0       	push   $0xf01078c6
f0104311:	e8 44 f5 ff ff       	call   f010385a <cprintf>
f0104316:	83 c4 10             	add    $0x10,%esp

	switch (syscallno) {

	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;
f0104319:	b8 00 00 00 00       	mov    $0x0,%eax
f010431e:	e9 07 05 00 00       	jmp    f010482a <syscall+0x55e>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0104323:	e8 bd c2 ff ff       	call   f01005e5 <cons_getc>
	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;

	case SYS_cgetc:
		return sys_cgetc();
f0104328:	e9 fd 04 00 00       	jmp    f010482a <syscall+0x55e>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f010432d:	e8 a5 16 00 00       	call   f01059d7 <cpunum>
f0104332:	6b c0 74             	imul   $0x74,%eax,%eax
f0104335:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f010433b:	8b 40 48             	mov    0x48(%eax),%eax

	case SYS_cgetc:
		return sys_cgetc();
		
	case SYS_getenvid:
		return sys_getenvid();
f010433e:	e9 e7 04 00 00       	jmp    f010482a <syscall+0x55e>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0104343:	83 ec 04             	sub    $0x4,%esp
f0104346:	6a 01                	push   $0x1
f0104348:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010434b:	50                   	push   %eax
f010434c:	ff 75 0c             	pushl  0xc(%ebp)
f010434f:	e8 79 ec ff ff       	call   f0102fcd <envid2env>
f0104354:	89 c2                	mov    %eax,%edx
f0104356:	83 c4 10             	add    $0x10,%esp
f0104359:	85 d2                	test   %edx,%edx
f010435b:	0f 88 c9 04 00 00    	js     f010482a <syscall+0x55e>
		return r;
	if (e == curenv)
f0104361:	e8 71 16 00 00       	call   f01059d7 <cpunum>
f0104366:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104369:	6b c0 74             	imul   $0x74,%eax,%eax
f010436c:	39 90 48 10 23 f0    	cmp    %edx,-0xfdcefb8(%eax)
f0104372:	75 23                	jne    f0104397 <syscall+0xcb>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104374:	e8 5e 16 00 00       	call   f01059d7 <cpunum>
f0104379:	83 ec 08             	sub    $0x8,%esp
f010437c:	6b c0 74             	imul   $0x74,%eax,%eax
f010437f:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0104385:	ff 70 48             	pushl  0x48(%eax)
f0104388:	68 cb 78 10 f0       	push   $0xf01078cb
f010438d:	e8 c8 f4 ff ff       	call   f010385a <cprintf>
f0104392:	83 c4 10             	add    $0x10,%esp
f0104395:	eb 25                	jmp    f01043bc <syscall+0xf0>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0104397:	8b 5a 48             	mov    0x48(%edx),%ebx
f010439a:	e8 38 16 00 00       	call   f01059d7 <cpunum>
f010439f:	83 ec 04             	sub    $0x4,%esp
f01043a2:	53                   	push   %ebx
f01043a3:	6b c0 74             	imul   $0x74,%eax,%eax
f01043a6:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f01043ac:	ff 70 48             	pushl  0x48(%eax)
f01043af:	68 e6 78 10 f0       	push   $0xf01078e6
f01043b4:	e8 a1 f4 ff ff       	call   f010385a <cprintf>
f01043b9:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f01043bc:	83 ec 0c             	sub    $0xc,%esp
f01043bf:	ff 75 e4             	pushl  -0x1c(%ebp)
f01043c2:	e8 cc f1 ff ff       	call   f0103593 <env_destroy>
f01043c7:	83 c4 10             	add    $0x10,%esp
	return 0;
f01043ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01043cf:	e9 56 04 00 00       	jmp    f010482a <syscall+0x55e>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f01043d4:	e8 13 fe ff ff       	call   f01041ec <sched_yield>
	// from the current environment -- but tweaked so sys_exofork
	// will appear to return 0.

	// LAB 4: Your code here.
	struct Env* childenv;
	int errcode = env_alloc(&childenv, curenv->env_id);
f01043d9:	e8 f9 15 00 00       	call   f01059d7 <cpunum>
f01043de:	83 ec 08             	sub    $0x8,%esp
f01043e1:	6b c0 74             	imul   $0x74,%eax,%eax
f01043e4:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f01043ea:	ff 70 48             	pushl  0x48(%eax)
f01043ed:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01043f0:	50                   	push   %eax
f01043f1:	e8 e2 ec ff ff       	call   f01030d8 <env_alloc>
f01043f6:	89 c2                	mov    %eax,%edx
	
	//If the error code is less than 0, that means there has been an error while creating an env	
	if (errcode < 0) {
f01043f8:	83 c4 10             	add    $0x10,%esp
f01043fb:	85 d2                	test   %edx,%edx
f01043fd:	0f 88 27 04 00 00    	js     f010482a <syscall+0x55e>
		return errcode; //Return the environment
	}
	
	//Set the child environment as not runnable	
	childenv->env_status = ENV_NOT_RUNNABLE;
f0104403:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104406:	c7 43 54 04 00 00 00 	movl   $0x4,0x54(%ebx)

	//Copy the current environemnt register data into the child
	childenv->env_tf = curenv->env_tf;
f010440d:	e8 c5 15 00 00       	call   f01059d7 <cpunum>
f0104412:	6b c0 74             	imul   $0x74,%eax,%eax
f0104415:	8b b0 48 10 23 f0    	mov    -0xfdcefb8(%eax),%esi
f010441b:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104420:	89 df                	mov    %ebx,%edi
f0104422:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

	// when the child is scheduled to run, it has to restart the trapframe. 
	//Hence we modify the register eax to be 0. 

	childenv->env_tf.tf_regs.reg_eax = 0; 
f0104424:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104427:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

	return childenv->env_id;
f010442e:	8b 40 48             	mov    0x48(%eax),%eax
f0104431:	e9 f4 03 00 00       	jmp    f010482a <syscall+0x55e>

	// LAB 4: Your code here.
	
	struct Env *env_store;
	int errcode; 
	errcode = envid2env(envid, &env_store,1);
f0104436:	83 ec 04             	sub    $0x4,%esp
f0104439:	6a 01                	push   $0x1
f010443b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010443e:	50                   	push   %eax
f010443f:	ff 75 0c             	pushl  0xc(%ebp)
f0104442:	e8 86 eb ff ff       	call   f0102fcd <envid2env>
	if (errcode < 0)
f0104447:	83 c4 10             	add    $0x10,%esp
f010444a:	85 c0                	test   %eax,%eax
f010444c:	0f 88 d8 03 00 00    	js     f010482a <syscall+0x55e>
		return errcode;
	
	//Check if status is runnable or not runnable
	if (status == ENV_RUNNABLE || status == ENV_NOT_RUNNABLE)
f0104452:	8b 45 10             	mov    0x10(%ebp),%eax
f0104455:	8d 50 fe             	lea    -0x2(%eax),%edx
		env_store->env_status = status;

	else
		return E_INVAL;
f0104458:	b8 03 00 00 00       	mov    $0x3,%eax
	errcode = envid2env(envid, &env_store,1);
	if (errcode < 0)
		return errcode;
	
	//Check if status is runnable or not runnable
	if (status == ENV_RUNNABLE || status == ENV_NOT_RUNNABLE)
f010445d:	f7 c2 fd ff ff ff    	test   $0xfffffffd,%edx
f0104463:	0f 85 c1 03 00 00    	jne    f010482a <syscall+0x55e>
		env_store->env_status = status;
f0104469:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010446c:	8b 75 10             	mov    0x10(%ebp),%esi
f010446f:	89 70 54             	mov    %esi,0x54(%eax)

	else
		return E_INVAL;

	return 0;
f0104472:	b8 00 00 00 00       	mov    $0x0,%eax
f0104477:	e9 ae 03 00 00       	jmp    f010482a <syscall+0x55e>
	struct Env *en; 
	int code;
	
	//Check for valid address and page alignment
	if((((uint32_t)va) >= UTOP) || (((uint32_t)va) % PGSIZE) !=0)
		return  E_INVAL;
f010447c:	b8 03 00 00 00       	mov    $0x3,%eax
	
	struct Env *en; 
	int code;
	
	//Check for valid address and page alignment
	if((((uint32_t)va) >= UTOP) || (((uint32_t)va) % PGSIZE) !=0)
f0104481:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104488:	0f 87 9c 03 00 00    	ja     f010482a <syscall+0x55e>
f010448e:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104495:	0f 85 8f 03 00 00    	jne    f010482a <syscall+0x55e>
		return  E_INVAL;

	//Check for permissions
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
f010449b:	f7 45 14 fd f1 ff ff 	testl  $0xfffff1fd,0x14(%ebp)
f01044a2:	0f 84 82 03 00 00    	je     f010482a <syscall+0x55e>
		return E_INVAL;

	//Page allocation check
	struct PageInfo *newpage = page_alloc(ALLOC_ZERO); 
f01044a8:	83 ec 0c             	sub    $0xc,%esp
f01044ab:	6a 01                	push   $0x1
f01044ad:	e8 f0 ca ff ff       	call   f0100fa2 <page_alloc>
f01044b2:	89 c3                	mov    %eax,%ebx
	if (!newpage)
f01044b4:	83 c4 10             	add    $0x10,%esp
		return E_NO_MEM; 
f01044b7:	b8 04 00 00 00       	mov    $0x4,%eax
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
		return E_INVAL;

	//Page allocation check
	struct PageInfo *newpage = page_alloc(ALLOC_ZERO); 
	if (!newpage)
f01044bc:	85 db                	test   %ebx,%ebx
f01044be:	0f 84 66 03 00 00    	je     f010482a <syscall+0x55e>
		return E_NO_MEM; 

	//Use environid to get the environment 
	if ((code = envid2env(envid, &en,1))<0)
f01044c4:	83 ec 04             	sub    $0x4,%esp
f01044c7:	6a 01                	push   $0x1
f01044c9:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01044cc:	50                   	push   %eax
f01044cd:	ff 75 0c             	pushl  0xc(%ebp)
f01044d0:	e8 f8 ea ff ff       	call   f0102fcd <envid2env>
f01044d5:	83 c4 10             	add    $0x10,%esp
f01044d8:	85 c0                	test   %eax,%eax
f01044da:	0f 88 4a 03 00 00    	js     f010482a <syscall+0x55e>
		return code;

	//Check if the page mapping is correct otherwise free the page
	code=page_insert(en->env_pgdir,newpage,(void *)va,perm);
f01044e0:	ff 75 14             	pushl  0x14(%ebp)
f01044e3:	ff 75 10             	pushl  0x10(%ebp)
f01044e6:	53                   	push   %ebx
f01044e7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01044ea:	ff 70 60             	pushl  0x60(%eax)
f01044ed:	e8 d6 cd ff ff       	call   f01012c8 <page_insert>
f01044f2:	89 c6                	mov    %eax,%esi
	if (code < 0)
f01044f4:	83 c4 10             	add    $0x10,%esp
	{
		page_free(newpage);
		return code;
	}
	
	return 0;
f01044f7:	b8 00 00 00 00       	mov    $0x0,%eax
	if ((code = envid2env(envid, &en,1))<0)
		return code;

	//Check if the page mapping is correct otherwise free the page
	code=page_insert(en->env_pgdir,newpage,(void *)va,perm);
	if (code < 0)
f01044fc:	85 f6                	test   %esi,%esi
f01044fe:	0f 89 26 03 00 00    	jns    f010482a <syscall+0x55e>
	{
		page_free(newpage);
f0104504:	83 ec 0c             	sub    $0xc,%esp
f0104507:	53                   	push   %ebx
f0104508:	e8 0b cb ff ff       	call   f0101018 <page_free>
f010450d:	83 c4 10             	add    $0x10,%esp
		return code;
f0104510:	89 f0                	mov    %esi,%eax
f0104512:	e9 13 03 00 00       	jmp    f010482a <syscall+0x55e>
	struct Env* src_env;
	struct Env* dst_env;
	int errcode;
	
	//Check for valid src env id
	errcode = envid2env(srcenvid, &src_env, 1);
f0104517:	83 ec 04             	sub    $0x4,%esp
f010451a:	6a 01                	push   $0x1
f010451c:	8d 45 dc             	lea    -0x24(%ebp),%eax
f010451f:	50                   	push   %eax
f0104520:	ff 75 0c             	pushl  0xc(%ebp)
f0104523:	e8 a5 ea ff ff       	call   f0102fcd <envid2env>
f0104528:	89 c2                	mov    %eax,%edx
	if (errcode < 0) 
f010452a:	83 c4 10             	add    $0x10,%esp
f010452d:	85 d2                	test   %edx,%edx
f010452f:	0f 88 f5 02 00 00    	js     f010482a <syscall+0x55e>
		return errcode;
	
	//Check for valid des env id
	errcode = envid2env(dstenvid, &dst_env, 1);
f0104535:	83 ec 04             	sub    $0x4,%esp
f0104538:	6a 01                	push   $0x1
f010453a:	8d 45 e0             	lea    -0x20(%ebp),%eax
f010453d:	50                   	push   %eax
f010453e:	ff 75 14             	pushl  0x14(%ebp)
f0104541:	e8 87 ea ff ff       	call   f0102fcd <envid2env>
	if (errcode < 0) 
f0104546:	83 c4 10             	add    $0x10,%esp
f0104549:	85 c0                	test   %eax,%eax
f010454b:	0f 88 d9 02 00 00    	js     f010482a <syscall+0x55e>
		return errcode;
	
	//Check if the address is below UTOP
	if (((uint32_t)srcva) >= UTOP || ((uint32_t)dstva) >= UTOP) 
f0104551:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104558:	77 6d                	ja     f01045c7 <syscall+0x2fb>
f010455a:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f0104561:	77 64                	ja     f01045c7 <syscall+0x2fb>
f0104563:	8b 45 10             	mov    0x10(%ebp),%eax
f0104566:	0b 45 18             	or     0x18(%ebp),%eax
		return -E_INVAL;
	
	//Checking if the address is page aligned
	if ((((uint32_t)srcva)%PGSIZE != 0) || (((uint32_t)dstva)%PGSIZE != 0)) 
f0104569:	a9 ff 0f 00 00       	test   $0xfff,%eax
f010456e:	75 61                	jne    f01045d1 <syscall+0x305>
		return -E_INVAL;

	// find the page corresponding to srcva in src_e
	pte_t* pte_src;

	struct PageInfo* srcPage = page_lookup(src_env->env_pgdir, srcva, &pte_src);
f0104570:	83 ec 04             	sub    $0x4,%esp
f0104573:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104576:	50                   	push   %eax
f0104577:	ff 75 10             	pushl  0x10(%ebp)
f010457a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010457d:	ff 70 60             	pushl  0x60(%eax)
f0104580:	e8 7d cc ff ff       	call   f0101202 <page_lookup>
	if (!srcPage) 
f0104585:	83 c4 10             	add    $0x10,%esp
f0104588:	85 c0                	test   %eax,%eax
f010458a:	74 4f                	je     f01045db <syscall+0x30f>
		return -E_INVAL;
	

	//Check for permissions
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
f010458c:	f7 45 1c fd f1 ff ff 	testl  $0xfffff1fd,0x1c(%ebp)
f0104593:	74 50                	je     f01045e5 <syscall+0x319>
		return -E_INVAL; 	
	

	// the page is not writable but write permission is set	
	if (!(*pte_src & PTE_W) && (perm & PTE_W)) {
f0104595:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104598:	f6 02 02             	testb  $0x2,(%edx)
f010459b:	75 06                	jne    f01045a3 <syscall+0x2d7>
f010459d:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f01045a1:	75 4c                	jne    f01045ef <syscall+0x323>
		return -E_INVAL;
	}

	// mapping
	errcode = page_insert(dst_env->env_pgdir, srcPage, dstva, perm);
f01045a3:	ff 75 1c             	pushl  0x1c(%ebp)
f01045a6:	ff 75 18             	pushl  0x18(%ebp)
f01045a9:	50                   	push   %eax
f01045aa:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01045ad:	ff 70 60             	pushl  0x60(%eax)
f01045b0:	e8 13 cd ff ff       	call   f01012c8 <page_insert>
f01045b5:	83 c4 10             	add    $0x10,%esp
f01045b8:	85 c0                	test   %eax,%eax
f01045ba:	ba 00 00 00 00       	mov    $0x0,%edx
f01045bf:	0f 4f c2             	cmovg  %edx,%eax
f01045c2:	e9 63 02 00 00       	jmp    f010482a <syscall+0x55e>
	if (errcode < 0) 
		return errcode;
	
	//Check if the address is below UTOP
	if (((uint32_t)srcva) >= UTOP || ((uint32_t)dstva) >= UTOP) 
		return -E_INVAL;
f01045c7:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01045cc:	e9 59 02 00 00       	jmp    f010482a <syscall+0x55e>
	
	//Checking if the address is page aligned
	if ((((uint32_t)srcva)%PGSIZE != 0) || (((uint32_t)dstva)%PGSIZE != 0)) 
		return -E_INVAL;
f01045d1:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01045d6:	e9 4f 02 00 00       	jmp    f010482a <syscall+0x55e>
	// find the page corresponding to srcva in src_e
	pte_t* pte_src;

	struct PageInfo* srcPage = page_lookup(src_env->env_pgdir, srcva, &pte_src);
	if (!srcPage) 
		return -E_INVAL;
f01045db:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01045e0:	e9 45 02 00 00       	jmp    f010482a <syscall+0x55e>
	

	//Check for permissions
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
		return -E_INVAL; 	
f01045e5:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01045ea:	e9 3b 02 00 00       	jmp    f010482a <syscall+0x55e>
	

	// the page is not writable but write permission is set	
	if (!(*pte_src & PTE_W) && (perm & PTE_W)) {
		return -E_INVAL;
f01045ef:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	case SYS_page_alloc:
		return sys_page_alloc( (envid_t)a1, (void *)a2, (int)a3);
	
	case SYS_page_map:
		return sys_page_map( (envid_t)a1, (void *)a2,
f01045f4:	e9 31 02 00 00       	jmp    f010482a <syscall+0x55e>
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	struct Env* en;
	//Check for valid envid
	int errcode = envid2env(envid, &en, 1);
f01045f9:	83 ec 04             	sub    $0x4,%esp
f01045fc:	6a 01                	push   $0x1
f01045fe:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104601:	50                   	push   %eax
f0104602:	ff 75 0c             	pushl  0xc(%ebp)
f0104605:	e8 c3 e9 ff ff       	call   f0102fcd <envid2env>
	if (errcode < 0){ 
f010460a:	83 c4 10             	add    $0x10,%esp
f010460d:	85 c0                	test   %eax,%eax
f010460f:	0f 88 15 02 00 00    	js     f010482a <syscall+0x55e>
		return errcode;
	}
	
	//Checkfor valid address and page alignment
	if ((((uint32_t)va) >= UTOP) ||(((uint32_t)va)%PGSIZE != 0 ) ) {
f0104615:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f010461c:	77 27                	ja     f0104645 <syscall+0x379>
f010461e:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104625:	75 28                	jne    f010464f <syscall+0x383>
		return -E_INVAL;
	}

	page_remove(en->env_pgdir, va);
f0104627:	83 ec 08             	sub    $0x8,%esp
f010462a:	ff 75 10             	pushl  0x10(%ebp)
f010462d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104630:	ff 70 60             	pushl  0x60(%eax)
f0104633:	e8 4a cc ff ff       	call   f0101282 <page_remove>
f0104638:	83 c4 10             	add    $0x10,%esp

	return 0;
f010463b:	b8 00 00 00 00       	mov    $0x0,%eax
f0104640:	e9 e5 01 00 00       	jmp    f010482a <syscall+0x55e>
		return errcode;
	}
	
	//Checkfor valid address and page alignment
	if ((((uint32_t)va) >= UTOP) ||(((uint32_t)va)%PGSIZE != 0 ) ) {
		return -E_INVAL;
f0104645:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010464a:	e9 db 01 00 00       	jmp    f010482a <syscall+0x55e>
f010464f:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	case SYS_page_map:
		return sys_page_map( (envid_t)a1, (void *)a2,
	     (envid_t) a3, (void *)a4, (int )a5);

	case SYS_page_unmap:
		return sys_page_unmap((envid_t)a1, (void *)a2);	
f0104654:	e9 d1 01 00 00       	jmp    f010482a <syscall+0x55e>
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here. //Exercise 8 code
	struct Env* en;
	int errcode = envid2env(envid, &en, 1);
f0104659:	83 ec 04             	sub    $0x4,%esp
f010465c:	6a 01                	push   $0x1
f010465e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104661:	50                   	push   %eax
f0104662:	ff 75 0c             	pushl  0xc(%ebp)
f0104665:	e8 63 e9 ff ff       	call   f0102fcd <envid2env>
	if (errcode < 0) {
f010466a:	83 c4 10             	add    $0x10,%esp
f010466d:	85 c0                	test   %eax,%eax
f010466f:	0f 88 b5 01 00 00    	js     f010482a <syscall+0x55e>
		return errcode;
	}

	//Set the pgfault_upcall to func
	en->env_pgfault_upcall = func;
f0104675:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104678:	8b 7d 10             	mov    0x10(%ebp),%edi
f010467b:	89 78 64             	mov    %edi,0x64(%eax)
	return 0;
f010467e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104683:	e9 a2 01 00 00       	jmp    f010482a <syscall+0x55e>
	// LAB 4: Your code here.
	int r; 
	struct Env* target_env; 
	
	//Bad Environment
	if ((r = envid2env(envid, &target_env, 0)) < 0)
f0104688:	83 ec 04             	sub    $0x4,%esp
f010468b:	6a 00                	push   $0x0
f010468d:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104690:	50                   	push   %eax
f0104691:	ff 75 0c             	pushl  0xc(%ebp)
f0104694:	e8 34 e9 ff ff       	call   f0102fcd <envid2env>
f0104699:	83 c4 10             	add    $0x10,%esp
f010469c:	85 c0                	test   %eax,%eax
f010469e:	0f 88 0a 01 00 00    	js     f01047ae <syscall+0x4e2>
		return -E_BAD_ENV; 
	
	//If target is not receiving
	if(!target_env->env_ipc_recving)
f01046a4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01046a7:	80 78 68 00          	cmpb   $0x0,0x68(%eax)
f01046ab:	0f 84 04 01 00 00    	je     f01047b5 <syscall+0x4e9>
		return -E_IPC_NOT_RECV;
	
	//If src and dst addesses are below UTOP
	if (((uint32_t)srcva) < UTOP && (uint32_t)target_env->env_ipc_dstva < UTOP)
f01046b1:	81 7d 14 ff ff bf ee 	cmpl   $0xeebfffff,0x14(%ebp)
f01046b8:	0f 87 b0 00 00 00    	ja     f010476e <syscall+0x4a2>
f01046be:	81 78 6c ff ff bf ee 	cmpl   $0xeebfffff,0x6c(%eax)
f01046c5:	0f 87 a3 00 00 00    	ja     f010476e <syscall+0x4a2>
	{
		
		//Check if srcva is page aligned
		if ((uint32_t)srcva % PGSIZE !=0)
			return -E_INVAL;
f01046cb:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	//If src and dst addesses are below UTOP
	if (((uint32_t)srcva) < UTOP && (uint32_t)target_env->env_ipc_dstva < UTOP)
	{
		
		//Check if srcva is page aligned
		if ((uint32_t)srcva % PGSIZE !=0)
f01046d0:	f7 45 14 ff 0f 00 00 	testl  $0xfff,0x14(%ebp)
f01046d7:	0f 85 4d 01 00 00    	jne    f010482a <syscall+0x55e>
			return -E_INVAL;
	
		//Check for permissions
		if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
f01046dd:	f7 45 18 fd f1 ff ff 	testl  $0xfffff1fd,0x18(%ebp)
f01046e4:	0f 84 40 01 00 00    	je     f010482a <syscall+0x55e>
			return -E_INVAL;

		struct PageInfo* srcpage = NULL;

		pte_t* pte = NULL;
f01046ea:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		//Lookup the page and get a pte
		if (!(srcpage = page_lookup(curenv->env_pgdir, srcva,&pte)))
f01046f1:	e8 e1 12 00 00       	call   f01059d7 <cpunum>
f01046f6:	83 ec 04             	sub    $0x4,%esp
f01046f9:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01046fc:	52                   	push   %edx
f01046fd:	ff 75 14             	pushl  0x14(%ebp)
f0104700:	6b c0 74             	imul   $0x74,%eax,%eax
f0104703:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0104709:	ff 70 60             	pushl  0x60(%eax)
f010470c:	e8 f1 ca ff ff       	call   f0101202 <page_lookup>
f0104711:	89 c2                	mov    %eax,%edx
f0104713:	83 c4 10             	add    $0x10,%esp
f0104716:	85 c0                	test   %eax,%eax
f0104718:	74 40                	je     f010475a <syscall+0x48e>
			return -E_INVAL;
		
		//if (perm & PTE_W), but srcva is read-only in the
		//current environment's address space.
		if ((perm & PTE_W) && !(*pte & PTE_W))
f010471a:	f6 45 18 02          	testb  $0x2,0x18(%ebp)
f010471e:	74 11                	je     f0104731 <syscall+0x465>
			return -E_INVAL; 
f0104720:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		if (!(srcpage = page_lookup(curenv->env_pgdir, srcva,&pte)))
			return -E_INVAL;
		
		//if (perm & PTE_W), but srcva is read-only in the
		//current environment's address space.
		if ((perm & PTE_W) && !(*pte & PTE_W))
f0104725:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0104728:	f6 01 02             	testb  $0x2,(%ecx)
f010472b:	0f 84 f9 00 00 00    	je     f010482a <syscall+0x55e>
			return -E_INVAL; 
		
		//Page mappingto destination
		if (target_env->env_ipc_dstva)
f0104731:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104734:	8b 48 6c             	mov    0x6c(%eax),%ecx
f0104737:	85 c9                	test   %ecx,%ecx
f0104739:	74 14                	je     f010474f <syscall+0x483>
		{
			//map the page
			if ((r = page_insert(target_env->env_pgdir, srcpage, (void *)target_env->env_ipc_dstva,perm) )< 0)
f010473b:	ff 75 18             	pushl  0x18(%ebp)
f010473e:	51                   	push   %ecx
f010473f:	52                   	push   %edx
f0104740:	ff 70 60             	pushl  0x60(%eax)
f0104743:	e8 80 cb ff ff       	call   f01012c8 <page_insert>
f0104748:	83 c4 10             	add    $0x10,%esp
f010474b:	85 c0                	test   %eax,%eax
f010474d:	78 15                	js     f0104764 <syscall+0x498>
				return -E_NO_MEM;
			
		}
		
		target_env->env_ipc_perm = perm; // is set to 'perm' if a page was transferred, 0 otherwise. 
f010474f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104752:	8b 75 18             	mov    0x18(%ebp),%esi
f0104755:	89 70 78             	mov    %esi,0x78(%eax)
f0104758:	eb 1b                	jmp    f0104775 <syscall+0x4a9>
		struct PageInfo* srcpage = NULL;

		pte_t* pte = NULL;
		//Lookup the page and get a pte
		if (!(srcpage = page_lookup(curenv->env_pgdir, srcva,&pte)))
			return -E_INVAL;
f010475a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010475f:	e9 c6 00 00 00       	jmp    f010482a <syscall+0x55e>
		//Page mappingto destination
		if (target_env->env_ipc_dstva)
		{
			//map the page
			if ((r = page_insert(target_env->env_pgdir, srcpage, (void *)target_env->env_ipc_dstva,perm) )< 0)
				return -E_NO_MEM;
f0104764:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0104769:	e9 bc 00 00 00       	jmp    f010482a <syscall+0x55e>
		}
		
		target_env->env_ipc_perm = perm; // is set to 'perm' if a page was transferred, 0 otherwise. 
	}
	else{
		target_env->env_ipc_perm = 0; //  0 otherwise. 
f010476e:	c7 40 78 00 00 00 00 	movl   $0x0,0x78(%eax)
	}
	
	target_env->env_ipc_recving  = 0; //is set to 0 to block future sends
f0104775:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104778:	c6 43 68 00          	movb   $0x0,0x68(%ebx)
	target_env->env_ipc_from = curenv->env_id; // is set to the sending envid;
f010477c:	e8 56 12 00 00       	call   f01059d7 <cpunum>
f0104781:	6b c0 74             	imul   $0x74,%eax,%eax
f0104784:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f010478a:	8b 40 48             	mov    0x48(%eax),%eax
f010478d:	89 43 74             	mov    %eax,0x74(%ebx)
	target_env->env_tf.tf_regs.reg_eax = 0;
f0104790:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104793:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	target_env->env_ipc_value = value; // is set to the 'value' parameter;
f010479a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010479d:	89 48 70             	mov    %ecx,0x70(%eax)
	target_env->env_status = ENV_RUNNABLE; 
f01047a0:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	
	return 0;
f01047a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01047ac:	eb 7c                	jmp    f010482a <syscall+0x55e>
	int r; 
	struct Env* target_env; 
	
	//Bad Environment
	if ((r = envid2env(envid, &target_env, 0)) < 0)
		return -E_BAD_ENV; 
f01047ae:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01047b3:	eb 75                	jmp    f010482a <syscall+0x55e>
	
	//If target is not receiving
	if(!target_env->env_ipc_recving)
		return -E_IPC_NOT_RECV;
f01047b5:	b8 f8 ff ff ff       	mov    $0xfffffff8,%eax

	case SYS_env_set_pgfault_upcall:
		return sys_env_set_pgfault_upcall((envid_t) a1, (void *)a2);

	case SYS_ipc_try_send:
		return sys_ipc_try_send(a1,a2,(void*)a3, a4);
f01047ba:	eb 6e                	jmp    f010482a <syscall+0x55e>
	//panic("sys_ipc_recv not implemented");

	//check if dstva is below UTOP
	
	
	if ((uint32_t)dstva < UTOP)
f01047bc:	81 7d 0c ff ff bf ee 	cmpl   $0xeebfffff,0xc(%ebp)
f01047c3:	77 1d                	ja     f01047e2 <syscall+0x516>
	{
		if ((uint32_t)dstva % PGSIZE !=0)
f01047c5:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
f01047cc:	75 57                	jne    f0104825 <syscall+0x559>
			return -E_INVAL;
		curenv->env_ipc_dstva = dstva;
f01047ce:	e8 04 12 00 00       	call   f01059d7 <cpunum>
f01047d3:	6b c0 74             	imul   $0x74,%eax,%eax
f01047d6:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f01047dc:	8b 75 0c             	mov    0xc(%ebp),%esi
f01047df:	89 70 6c             	mov    %esi,0x6c(%eax)
	}
	
	//Enable receiving
	curenv->env_ipc_recving = 1;
f01047e2:	e8 f0 11 00 00       	call   f01059d7 <cpunum>
f01047e7:	6b c0 74             	imul   $0x74,%eax,%eax
f01047ea:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f01047f0:	c6 40 68 01          	movb   $0x1,0x68(%eax)
	curenv->env_status = ENV_NOT_RUNNABLE;
f01047f4:	e8 de 11 00 00       	call   f01059d7 <cpunum>
f01047f9:	6b c0 74             	imul   $0x74,%eax,%eax
f01047fc:	8b 80 48 10 23 f0    	mov    -0xfdcefb8(%eax),%eax
f0104802:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	sched_yield();
f0104809:	e8 de f9 ff ff       	call   f01041ec <sched_yield>

	case SYS_ipc_recv:
		return sys_ipc_recv((void*)a1);
		
	default:
		panic("Invalid System Call \n");
f010480e:	83 ec 04             	sub    $0x4,%esp
f0104811:	68 fe 78 10 f0       	push   $0xf01078fe
f0104816:	68 15 02 00 00       	push   $0x215
f010481b:	68 14 79 10 f0       	push   $0xf0107914
f0104820:	e8 1b b8 ff ff       	call   f0100040 <_panic>

	case SYS_ipc_try_send:
		return sys_ipc_try_send(a1,a2,(void*)a3, a4);

	case SYS_ipc_recv:
		return sys_ipc_recv((void*)a1);
f0104825:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		
	default:
		panic("Invalid System Call \n");
		return -E_INVAL;
	}
}
f010482a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010482d:	5b                   	pop    %ebx
f010482e:	5e                   	pop    %esi
f010482f:	5f                   	pop    %edi
f0104830:	5d                   	pop    %ebp
f0104831:	c3                   	ret    

f0104832 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104832:	55                   	push   %ebp
f0104833:	89 e5                	mov    %esp,%ebp
f0104835:	57                   	push   %edi
f0104836:	56                   	push   %esi
f0104837:	53                   	push   %ebx
f0104838:	83 ec 14             	sub    $0x14,%esp
f010483b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010483e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104841:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104844:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104847:	8b 1a                	mov    (%edx),%ebx
f0104849:	8b 01                	mov    (%ecx),%eax
f010484b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010484e:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104855:	e9 88 00 00 00       	jmp    f01048e2 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f010485a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010485d:	01 d8                	add    %ebx,%eax
f010485f:	89 c6                	mov    %eax,%esi
f0104861:	c1 ee 1f             	shr    $0x1f,%esi
f0104864:	01 c6                	add    %eax,%esi
f0104866:	d1 fe                	sar    %esi
f0104868:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010486b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010486e:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0104871:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104873:	eb 03                	jmp    f0104878 <stab_binsearch+0x46>
			m--;
f0104875:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104878:	39 c3                	cmp    %eax,%ebx
f010487a:	7f 1f                	jg     f010489b <stab_binsearch+0x69>
f010487c:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104880:	83 ea 0c             	sub    $0xc,%edx
f0104883:	39 f9                	cmp    %edi,%ecx
f0104885:	75 ee                	jne    f0104875 <stab_binsearch+0x43>
f0104887:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010488a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010488d:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104890:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104894:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104897:	76 18                	jbe    f01048b1 <stab_binsearch+0x7f>
f0104899:	eb 05                	jmp    f01048a0 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010489b:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f010489e:	eb 42                	jmp    f01048e2 <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01048a0:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01048a3:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01048a5:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01048a8:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01048af:	eb 31                	jmp    f01048e2 <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01048b1:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01048b4:	73 17                	jae    f01048cd <stab_binsearch+0x9b>
			*region_right = m - 1;
f01048b6:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01048b9:	83 e8 01             	sub    $0x1,%eax
f01048bc:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01048bf:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01048c2:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01048c4:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01048cb:	eb 15                	jmp    f01048e2 <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01048cd:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01048d0:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f01048d3:	89 1e                	mov    %ebx,(%esi)
			l = m;
			addr++;
f01048d5:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01048d9:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01048db:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01048e2:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01048e5:	0f 8e 6f ff ff ff    	jle    f010485a <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01048eb:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01048ef:	75 0f                	jne    f0104900 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f01048f1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01048f4:	8b 00                	mov    (%eax),%eax
f01048f6:	83 e8 01             	sub    $0x1,%eax
f01048f9:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01048fc:	89 06                	mov    %eax,(%esi)
f01048fe:	eb 2c                	jmp    f010492c <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104900:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104903:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104905:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104908:	8b 0e                	mov    (%esi),%ecx
f010490a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010490d:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0104910:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104913:	eb 03                	jmp    f0104918 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104915:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104918:	39 c8                	cmp    %ecx,%eax
f010491a:	7e 0b                	jle    f0104927 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f010491c:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104920:	83 ea 0c             	sub    $0xc,%edx
f0104923:	39 fb                	cmp    %edi,%ebx
f0104925:	75 ee                	jne    f0104915 <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104927:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010492a:	89 06                	mov    %eax,(%esi)
	}
}
f010492c:	83 c4 14             	add    $0x14,%esp
f010492f:	5b                   	pop    %ebx
f0104930:	5e                   	pop    %esi
f0104931:	5f                   	pop    %edi
f0104932:	5d                   	pop    %ebp
f0104933:	c3                   	ret    

f0104934 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104934:	55                   	push   %ebp
f0104935:	89 e5                	mov    %esp,%ebp
f0104937:	57                   	push   %edi
f0104938:	56                   	push   %esi
f0104939:	53                   	push   %ebx
f010493a:	83 ec 3c             	sub    $0x3c,%esp
f010493d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104940:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104943:	c7 06 58 79 10 f0    	movl   $0xf0107958,(%esi)
	info->eip_line = 0;
f0104949:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0104950:	c7 46 08 58 79 10 f0 	movl   $0xf0107958,0x8(%esi)
	info->eip_fn_namelen = 9;
f0104957:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f010495e:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0104961:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104968:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f010496e:	0f 87 a4 00 00 00    	ja     f0104a18 <debuginfo_eip+0xe4>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
f0104974:	e8 5e 10 00 00       	call   f01059d7 <cpunum>
f0104979:	6a 05                	push   $0x5
f010497b:	6a 10                	push   $0x10
f010497d:	68 00 00 20 00       	push   $0x200000
f0104982:	6b c0 74             	imul   $0x74,%eax,%eax
f0104985:	ff b0 48 10 23 f0    	pushl  -0xfdcefb8(%eax)
f010498b:	e8 79 e4 ff ff       	call   f0102e09 <user_mem_check>
f0104990:	83 c4 10             	add    $0x10,%esp
f0104993:	85 c0                	test   %eax,%eax
f0104995:	0f 88 24 02 00 00    	js     f0104bbf <debuginfo_eip+0x28b>
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
		}
		stabs = usd->stabs;
f010499b:	a1 00 00 20 00       	mov    0x200000,%eax
		stab_end = usd->stab_end;
f01049a0:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f01049a6:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f01049ac:	89 4d c0             	mov    %ecx,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f01049af:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f01049b5:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
f01049b8:	89 d9                	mov    %ebx,%ecx
f01049ba:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01049bd:	29 c1                	sub    %eax,%ecx
f01049bf:	89 4d b8             	mov    %ecx,-0x48(%ebp)
f01049c2:	e8 10 10 00 00       	call   f01059d7 <cpunum>
f01049c7:	6a 05                	push   $0x5
f01049c9:	ff 75 b8             	pushl  -0x48(%ebp)
f01049cc:	ff 75 c4             	pushl  -0x3c(%ebp)
f01049cf:	6b c0 74             	imul   $0x74,%eax,%eax
f01049d2:	ff b0 48 10 23 f0    	pushl  -0xfdcefb8(%eax)
f01049d8:	e8 2c e4 ff ff       	call   f0102e09 <user_mem_check>
f01049dd:	83 c4 10             	add    $0x10,%esp
f01049e0:	85 c0                	test   %eax,%eax
f01049e2:	0f 88 de 01 00 00    	js     f0104bc6 <debuginfo_eip+0x292>
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
		}

		if (user_mem_check(curenv, (const void *)stabstr,
f01049e8:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01049eb:	2b 55 c0             	sub    -0x40(%ebp),%edx
f01049ee:	89 55 b8             	mov    %edx,-0x48(%ebp)
f01049f1:	e8 e1 0f 00 00       	call   f01059d7 <cpunum>
f01049f6:	6a 05                	push   $0x5
f01049f8:	ff 75 b8             	pushl  -0x48(%ebp)
f01049fb:	ff 75 c0             	pushl  -0x40(%ebp)
f01049fe:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a01:	ff b0 48 10 23 f0    	pushl  -0xfdcefb8(%eax)
f0104a07:	e8 fd e3 ff ff       	call   f0102e09 <user_mem_check>
f0104a0c:	83 c4 10             	add    $0x10,%esp
f0104a0f:	85 c0                	test   %eax,%eax
f0104a11:	79 1f                	jns    f0104a32 <debuginfo_eip+0xfe>
f0104a13:	e9 b5 01 00 00       	jmp    f0104bcd <debuginfo_eip+0x299>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104a18:	c7 45 bc 63 5d 11 f0 	movl   $0xf0115d63,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104a1f:	c7 45 c0 69 26 11 f0 	movl   $0xf0112669,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104a26:	bb 68 26 11 f0       	mov    $0xf0112668,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104a2b:	c7 45 c4 38 7e 10 f0 	movl   $0xf0107e38,-0x3c(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104a32:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104a35:	39 45 c0             	cmp    %eax,-0x40(%ebp)
f0104a38:	0f 83 96 01 00 00    	jae    f0104bd4 <debuginfo_eip+0x2a0>
f0104a3e:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0104a42:	0f 85 93 01 00 00    	jne    f0104bdb <debuginfo_eip+0x2a7>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104a48:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104a4f:	89 d8                	mov    %ebx,%eax
f0104a51:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0104a54:	29 d8                	sub    %ebx,%eax
f0104a56:	c1 f8 02             	sar    $0x2,%eax
f0104a59:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0104a5f:	83 e8 01             	sub    $0x1,%eax
f0104a62:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104a65:	83 ec 08             	sub    $0x8,%esp
f0104a68:	57                   	push   %edi
f0104a69:	6a 64                	push   $0x64
f0104a6b:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0104a6e:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104a71:	89 d8                	mov    %ebx,%eax
f0104a73:	e8 ba fd ff ff       	call   f0104832 <stab_binsearch>
	if (lfile == 0)
f0104a78:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104a7b:	83 c4 10             	add    $0x10,%esp
f0104a7e:	85 c0                	test   %eax,%eax
f0104a80:	0f 84 5c 01 00 00    	je     f0104be2 <debuginfo_eip+0x2ae>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104a86:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104a89:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104a8c:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104a8f:	83 ec 08             	sub    $0x8,%esp
f0104a92:	57                   	push   %edi
f0104a93:	6a 24                	push   $0x24
f0104a95:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0104a98:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104a9b:	89 d8                	mov    %ebx,%eax
f0104a9d:	e8 90 fd ff ff       	call   f0104832 <stab_binsearch>

	if (lfun <= rfun) {
f0104aa2:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104aa5:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0104aa8:	83 c4 10             	add    $0x10,%esp
f0104aab:	39 d8                	cmp    %ebx,%eax
f0104aad:	7f 32                	jg     f0104ae1 <debuginfo_eip+0x1ad>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104aaf:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104ab2:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0104ab5:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f0104ab8:	8b 11                	mov    (%ecx),%edx
f0104aba:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0104abd:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104ac0:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0104ac3:	39 55 b8             	cmp    %edx,-0x48(%ebp)
f0104ac6:	73 09                	jae    f0104ad1 <debuginfo_eip+0x19d>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104ac8:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0104acb:	03 55 c0             	add    -0x40(%ebp),%edx
f0104ace:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104ad1:	8b 51 08             	mov    0x8(%ecx),%edx
f0104ad4:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0104ad7:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0104ad9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104adc:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0104adf:	eb 0f                	jmp    f0104af0 <debuginfo_eip+0x1bc>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104ae1:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0104ae4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104ae7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104aea:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104aed:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104af0:	83 ec 08             	sub    $0x8,%esp
f0104af3:	6a 3a                	push   $0x3a
f0104af5:	ff 76 08             	pushl  0x8(%esi)
f0104af8:	e8 99 08 00 00       	call   f0105396 <strfind>
f0104afd:	2b 46 08             	sub    0x8(%esi),%eax
f0104b00:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
f0104b03:	83 c4 08             	add    $0x8,%esp
f0104b06:	57                   	push   %edi
f0104b07:	6a 44                	push   $0x44
f0104b09:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104b0c:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0104b0f:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0104b12:	89 d8                	mov    %ebx,%eax
f0104b14:	e8 19 fd ff ff       	call   f0104832 <stab_binsearch>
	if (lline > rline) {
f0104b19:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104b1c:	83 c4 10             	add    $0x10,%esp
f0104b1f:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0104b22:	0f 8f c1 00 00 00    	jg     f0104be9 <debuginfo_eip+0x2b5>
		return -1; //Did not find the line number in the stab
	}
	info->eip_line = stabs[lline].n_desc; //If found update the info object with the correct line number
f0104b28:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104b2b:	0f b7 44 83 06       	movzwl 0x6(%ebx,%eax,4),%eax
f0104b30:	89 46 04             	mov    %eax,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104b33:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104b36:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104b39:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104b3c:	8d 14 93             	lea    (%ebx,%edx,4),%edx
f0104b3f:	89 75 0c             	mov    %esi,0xc(%ebp)
f0104b42:	eb 06                	jmp    f0104b4a <debuginfo_eip+0x216>
f0104b44:	83 e8 01             	sub    $0x1,%eax
f0104b47:	83 ea 0c             	sub    $0xc,%edx
f0104b4a:	39 c7                	cmp    %eax,%edi
f0104b4c:	7f 2a                	jg     f0104b78 <debuginfo_eip+0x244>
	       && stabs[lline].n_type != N_SOL
f0104b4e:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104b52:	80 f9 84             	cmp    $0x84,%cl
f0104b55:	0f 84 9c 00 00 00    	je     f0104bf7 <debuginfo_eip+0x2c3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104b5b:	80 f9 64             	cmp    $0x64,%cl
f0104b5e:	75 e4                	jne    f0104b44 <debuginfo_eip+0x210>
f0104b60:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0104b64:	74 de                	je     f0104b44 <debuginfo_eip+0x210>
f0104b66:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104b69:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104b6c:	e9 8c 00 00 00       	jmp    f0104bfd <debuginfo_eip+0x2c9>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104b71:	03 55 c0             	add    -0x40(%ebp),%edx
f0104b74:	89 16                	mov    %edx,(%esi)
f0104b76:	eb 03                	jmp    f0104b7b <debuginfo_eip+0x247>
f0104b78:	8b 75 0c             	mov    0xc(%ebp),%esi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104b7b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104b7e:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104b81:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104b86:	39 da                	cmp    %ebx,%edx
f0104b88:	0f 8d 8b 00 00 00    	jge    f0104c19 <debuginfo_eip+0x2e5>
		for (lline = lfun + 1;
f0104b8e:	83 c2 01             	add    $0x1,%edx
f0104b91:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104b94:	89 d0                	mov    %edx,%eax
f0104b96:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104b99:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0104b9c:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0104b9f:	eb 04                	jmp    f0104ba5 <debuginfo_eip+0x271>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104ba1:	83 46 14 01          	addl   $0x1,0x14(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104ba5:	39 c3                	cmp    %eax,%ebx
f0104ba7:	7e 47                	jle    f0104bf0 <debuginfo_eip+0x2bc>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104ba9:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104bad:	83 c0 01             	add    $0x1,%eax
f0104bb0:	83 c2 0c             	add    $0xc,%edx
f0104bb3:	80 f9 a0             	cmp    $0xa0,%cl
f0104bb6:	74 e9                	je     f0104ba1 <debuginfo_eip+0x26d>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104bb8:	b8 00 00 00 00       	mov    $0x0,%eax
f0104bbd:	eb 5a                	jmp    f0104c19 <debuginfo_eip+0x2e5>
		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
f0104bbf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104bc4:	eb 53                	jmp    f0104c19 <debuginfo_eip+0x2e5>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
f0104bc6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104bcb:	eb 4c                	jmp    f0104c19 <debuginfo_eip+0x2e5>
		}

		if (user_mem_check(curenv, (const void *)stabstr,
				(uintptr_t)stabstr_end - (uintptr_t)stabstr, PTE_U | PTE_P) < 0) {
			return -1;
f0104bcd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104bd2:	eb 45                	jmp    f0104c19 <debuginfo_eip+0x2e5>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104bd4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104bd9:	eb 3e                	jmp    f0104c19 <debuginfo_eip+0x2e5>
f0104bdb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104be0:	eb 37                	jmp    f0104c19 <debuginfo_eip+0x2e5>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104be2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104be7:	eb 30                	jmp    f0104c19 <debuginfo_eip+0x2e5>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
	if (lline > rline) {
		return -1; //Did not find the line number in the stab
f0104be9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104bee:	eb 29                	jmp    f0104c19 <debuginfo_eip+0x2e5>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104bf0:	b8 00 00 00 00       	mov    $0x0,%eax
f0104bf5:	eb 22                	jmp    f0104c19 <debuginfo_eip+0x2e5>
f0104bf7:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104bfa:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104bfd:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104c00:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0104c03:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0104c06:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104c09:	2b 45 c0             	sub    -0x40(%ebp),%eax
f0104c0c:	39 c2                	cmp    %eax,%edx
f0104c0e:	0f 82 5d ff ff ff    	jb     f0104b71 <debuginfo_eip+0x23d>
f0104c14:	e9 62 ff ff ff       	jmp    f0104b7b <debuginfo_eip+0x247>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
}
f0104c19:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104c1c:	5b                   	pop    %ebx
f0104c1d:	5e                   	pop    %esi
f0104c1e:	5f                   	pop    %edi
f0104c1f:	5d                   	pop    %ebp
f0104c20:	c3                   	ret    

f0104c21 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104c21:	55                   	push   %ebp
f0104c22:	89 e5                	mov    %esp,%ebp
f0104c24:	57                   	push   %edi
f0104c25:	56                   	push   %esi
f0104c26:	53                   	push   %ebx
f0104c27:	83 ec 1c             	sub    $0x1c,%esp
f0104c2a:	89 c7                	mov    %eax,%edi
f0104c2c:	89 d6                	mov    %edx,%esi
f0104c2e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c31:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104c34:	89 d1                	mov    %edx,%ecx
f0104c36:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104c39:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104c3c:	8b 45 10             	mov    0x10(%ebp),%eax
f0104c3f:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104c42:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104c45:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0104c4c:	39 4d e4             	cmp    %ecx,-0x1c(%ebp)
f0104c4f:	72 05                	jb     f0104c56 <printnum+0x35>
f0104c51:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0104c54:	77 3e                	ja     f0104c94 <printnum+0x73>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104c56:	83 ec 0c             	sub    $0xc,%esp
f0104c59:	ff 75 18             	pushl  0x18(%ebp)
f0104c5c:	83 eb 01             	sub    $0x1,%ebx
f0104c5f:	53                   	push   %ebx
f0104c60:	50                   	push   %eax
f0104c61:	83 ec 08             	sub    $0x8,%esp
f0104c64:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104c67:	ff 75 e0             	pushl  -0x20(%ebp)
f0104c6a:	ff 75 dc             	pushl  -0x24(%ebp)
f0104c6d:	ff 75 d8             	pushl  -0x28(%ebp)
f0104c70:	e8 5b 11 00 00       	call   f0105dd0 <__udivdi3>
f0104c75:	83 c4 18             	add    $0x18,%esp
f0104c78:	52                   	push   %edx
f0104c79:	50                   	push   %eax
f0104c7a:	89 f2                	mov    %esi,%edx
f0104c7c:	89 f8                	mov    %edi,%eax
f0104c7e:	e8 9e ff ff ff       	call   f0104c21 <printnum>
f0104c83:	83 c4 20             	add    $0x20,%esp
f0104c86:	eb 13                	jmp    f0104c9b <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104c88:	83 ec 08             	sub    $0x8,%esp
f0104c8b:	56                   	push   %esi
f0104c8c:	ff 75 18             	pushl  0x18(%ebp)
f0104c8f:	ff d7                	call   *%edi
f0104c91:	83 c4 10             	add    $0x10,%esp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104c94:	83 eb 01             	sub    $0x1,%ebx
f0104c97:	85 db                	test   %ebx,%ebx
f0104c99:	7f ed                	jg     f0104c88 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104c9b:	83 ec 08             	sub    $0x8,%esp
f0104c9e:	56                   	push   %esi
f0104c9f:	83 ec 04             	sub    $0x4,%esp
f0104ca2:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104ca5:	ff 75 e0             	pushl  -0x20(%ebp)
f0104ca8:	ff 75 dc             	pushl  -0x24(%ebp)
f0104cab:	ff 75 d8             	pushl  -0x28(%ebp)
f0104cae:	e8 4d 12 00 00       	call   f0105f00 <__umoddi3>
f0104cb3:	83 c4 14             	add    $0x14,%esp
f0104cb6:	0f be 80 62 79 10 f0 	movsbl -0xfef869e(%eax),%eax
f0104cbd:	50                   	push   %eax
f0104cbe:	ff d7                	call   *%edi
f0104cc0:	83 c4 10             	add    $0x10,%esp
}
f0104cc3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104cc6:	5b                   	pop    %ebx
f0104cc7:	5e                   	pop    %esi
f0104cc8:	5f                   	pop    %edi
f0104cc9:	5d                   	pop    %ebp
f0104cca:	c3                   	ret    

f0104ccb <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0104ccb:	55                   	push   %ebp
f0104ccc:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104cce:	83 fa 01             	cmp    $0x1,%edx
f0104cd1:	7e 0e                	jle    f0104ce1 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0104cd3:	8b 10                	mov    (%eax),%edx
f0104cd5:	8d 4a 08             	lea    0x8(%edx),%ecx
f0104cd8:	89 08                	mov    %ecx,(%eax)
f0104cda:	8b 02                	mov    (%edx),%eax
f0104cdc:	8b 52 04             	mov    0x4(%edx),%edx
f0104cdf:	eb 22                	jmp    f0104d03 <getuint+0x38>
	else if (lflag)
f0104ce1:	85 d2                	test   %edx,%edx
f0104ce3:	74 10                	je     f0104cf5 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104ce5:	8b 10                	mov    (%eax),%edx
f0104ce7:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104cea:	89 08                	mov    %ecx,(%eax)
f0104cec:	8b 02                	mov    (%edx),%eax
f0104cee:	ba 00 00 00 00       	mov    $0x0,%edx
f0104cf3:	eb 0e                	jmp    f0104d03 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104cf5:	8b 10                	mov    (%eax),%edx
f0104cf7:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104cfa:	89 08                	mov    %ecx,(%eax)
f0104cfc:	8b 02                	mov    (%edx),%eax
f0104cfe:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104d03:	5d                   	pop    %ebp
f0104d04:	c3                   	ret    

f0104d05 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104d05:	55                   	push   %ebp
f0104d06:	89 e5                	mov    %esp,%ebp
f0104d08:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104d0b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104d0f:	8b 10                	mov    (%eax),%edx
f0104d11:	3b 50 04             	cmp    0x4(%eax),%edx
f0104d14:	73 0a                	jae    f0104d20 <sprintputch+0x1b>
		*b->buf++ = ch;
f0104d16:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104d19:	89 08                	mov    %ecx,(%eax)
f0104d1b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d1e:	88 02                	mov    %al,(%edx)
}
f0104d20:	5d                   	pop    %ebp
f0104d21:	c3                   	ret    

f0104d22 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104d22:	55                   	push   %ebp
f0104d23:	89 e5                	mov    %esp,%ebp
f0104d25:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0104d28:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104d2b:	50                   	push   %eax
f0104d2c:	ff 75 10             	pushl  0x10(%ebp)
f0104d2f:	ff 75 0c             	pushl  0xc(%ebp)
f0104d32:	ff 75 08             	pushl  0x8(%ebp)
f0104d35:	e8 05 00 00 00       	call   f0104d3f <vprintfmt>
	va_end(ap);
f0104d3a:	83 c4 10             	add    $0x10,%esp
}
f0104d3d:	c9                   	leave  
f0104d3e:	c3                   	ret    

f0104d3f <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104d3f:	55                   	push   %ebp
f0104d40:	89 e5                	mov    %esp,%ebp
f0104d42:	57                   	push   %edi
f0104d43:	56                   	push   %esi
f0104d44:	53                   	push   %ebx
f0104d45:	83 ec 2c             	sub    $0x2c,%esp
f0104d48:	8b 75 08             	mov    0x8(%ebp),%esi
f0104d4b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104d4e:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104d51:	eb 12                	jmp    f0104d65 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104d53:	85 c0                	test   %eax,%eax
f0104d55:	0f 84 90 03 00 00    	je     f01050eb <vprintfmt+0x3ac>
				return;
			putch(ch, putdat);
f0104d5b:	83 ec 08             	sub    $0x8,%esp
f0104d5e:	53                   	push   %ebx
f0104d5f:	50                   	push   %eax
f0104d60:	ff d6                	call   *%esi
f0104d62:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104d65:	83 c7 01             	add    $0x1,%edi
f0104d68:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104d6c:	83 f8 25             	cmp    $0x25,%eax
f0104d6f:	75 e2                	jne    f0104d53 <vprintfmt+0x14>
f0104d71:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0104d75:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0104d7c:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104d83:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0104d8a:	ba 00 00 00 00       	mov    $0x0,%edx
f0104d8f:	eb 07                	jmp    f0104d98 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104d91:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104d94:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104d98:	8d 47 01             	lea    0x1(%edi),%eax
f0104d9b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104d9e:	0f b6 07             	movzbl (%edi),%eax
f0104da1:	0f b6 c8             	movzbl %al,%ecx
f0104da4:	83 e8 23             	sub    $0x23,%eax
f0104da7:	3c 55                	cmp    $0x55,%al
f0104da9:	0f 87 21 03 00 00    	ja     f01050d0 <vprintfmt+0x391>
f0104daf:	0f b6 c0             	movzbl %al,%eax
f0104db2:	ff 24 85 20 7a 10 f0 	jmp    *-0xfef85e0(,%eax,4)
f0104db9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104dbc:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0104dc0:	eb d6                	jmp    f0104d98 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104dc2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104dc5:	b8 00 00 00 00       	mov    $0x0,%eax
f0104dca:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104dcd:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104dd0:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0104dd4:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0104dd7:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0104dda:	83 fa 09             	cmp    $0x9,%edx
f0104ddd:	77 39                	ja     f0104e18 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104ddf:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104de2:	eb e9                	jmp    f0104dcd <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104de4:	8b 45 14             	mov    0x14(%ebp),%eax
f0104de7:	8d 48 04             	lea    0x4(%eax),%ecx
f0104dea:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104ded:	8b 00                	mov    (%eax),%eax
f0104def:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104df2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104df5:	eb 27                	jmp    f0104e1e <vprintfmt+0xdf>
f0104df7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104dfa:	85 c0                	test   %eax,%eax
f0104dfc:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104e01:	0f 49 c8             	cmovns %eax,%ecx
f0104e04:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e07:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104e0a:	eb 8c                	jmp    f0104d98 <vprintfmt+0x59>
f0104e0c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104e0f:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0104e16:	eb 80                	jmp    f0104d98 <vprintfmt+0x59>
f0104e18:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104e1b:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0104e1e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104e22:	0f 89 70 ff ff ff    	jns    f0104d98 <vprintfmt+0x59>
				width = precision, precision = -1;
f0104e28:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104e2b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104e2e:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104e35:	e9 5e ff ff ff       	jmp    f0104d98 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104e3a:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e3d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0104e40:	e9 53 ff ff ff       	jmp    f0104d98 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104e45:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e48:	8d 50 04             	lea    0x4(%eax),%edx
f0104e4b:	89 55 14             	mov    %edx,0x14(%ebp)
f0104e4e:	83 ec 08             	sub    $0x8,%esp
f0104e51:	53                   	push   %ebx
f0104e52:	ff 30                	pushl  (%eax)
f0104e54:	ff d6                	call   *%esi
			break;
f0104e56:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e59:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0104e5c:	e9 04 ff ff ff       	jmp    f0104d65 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104e61:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e64:	8d 50 04             	lea    0x4(%eax),%edx
f0104e67:	89 55 14             	mov    %edx,0x14(%ebp)
f0104e6a:	8b 00                	mov    (%eax),%eax
f0104e6c:	99                   	cltd   
f0104e6d:	31 d0                	xor    %edx,%eax
f0104e6f:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104e71:	83 f8 09             	cmp    $0x9,%eax
f0104e74:	7f 0b                	jg     f0104e81 <vprintfmt+0x142>
f0104e76:	8b 14 85 80 7b 10 f0 	mov    -0xfef8480(,%eax,4),%edx
f0104e7d:	85 d2                	test   %edx,%edx
f0104e7f:	75 18                	jne    f0104e99 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0104e81:	50                   	push   %eax
f0104e82:	68 7a 79 10 f0       	push   $0xf010797a
f0104e87:	53                   	push   %ebx
f0104e88:	56                   	push   %esi
f0104e89:	e8 94 fe ff ff       	call   f0104d22 <printfmt>
f0104e8e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e91:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0104e94:	e9 cc fe ff ff       	jmp    f0104d65 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0104e99:	52                   	push   %edx
f0104e9a:	68 6d 70 10 f0       	push   $0xf010706d
f0104e9f:	53                   	push   %ebx
f0104ea0:	56                   	push   %esi
f0104ea1:	e8 7c fe ff ff       	call   f0104d22 <printfmt>
f0104ea6:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104ea9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104eac:	e9 b4 fe ff ff       	jmp    f0104d65 <vprintfmt+0x26>
f0104eb1:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0104eb4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104eb7:	89 45 cc             	mov    %eax,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104eba:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ebd:	8d 50 04             	lea    0x4(%eax),%edx
f0104ec0:	89 55 14             	mov    %edx,0x14(%ebp)
f0104ec3:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104ec5:	85 ff                	test   %edi,%edi
f0104ec7:	ba 73 79 10 f0       	mov    $0xf0107973,%edx
f0104ecc:	0f 44 fa             	cmove  %edx,%edi
			if (width > 0 && padc != '-')
f0104ecf:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0104ed3:	0f 84 92 00 00 00    	je     f0104f6b <vprintfmt+0x22c>
f0104ed9:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0104edd:	0f 8e 96 00 00 00    	jle    f0104f79 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104ee3:	83 ec 08             	sub    $0x8,%esp
f0104ee6:	51                   	push   %ecx
f0104ee7:	57                   	push   %edi
f0104ee8:	e8 5f 03 00 00       	call   f010524c <strnlen>
f0104eed:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104ef0:	29 c1                	sub    %eax,%ecx
f0104ef2:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0104ef5:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104ef8:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104efc:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104eff:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104f02:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104f04:	eb 0f                	jmp    f0104f15 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0104f06:	83 ec 08             	sub    $0x8,%esp
f0104f09:	53                   	push   %ebx
f0104f0a:	ff 75 e0             	pushl  -0x20(%ebp)
f0104f0d:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104f0f:	83 ef 01             	sub    $0x1,%edi
f0104f12:	83 c4 10             	add    $0x10,%esp
f0104f15:	85 ff                	test   %edi,%edi
f0104f17:	7f ed                	jg     f0104f06 <vprintfmt+0x1c7>
f0104f19:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104f1c:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104f1f:	85 c9                	test   %ecx,%ecx
f0104f21:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f26:	0f 49 c1             	cmovns %ecx,%eax
f0104f29:	29 c1                	sub    %eax,%ecx
f0104f2b:	89 75 08             	mov    %esi,0x8(%ebp)
f0104f2e:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104f31:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104f34:	89 cb                	mov    %ecx,%ebx
f0104f36:	eb 4d                	jmp    f0104f85 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104f38:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104f3c:	74 1b                	je     f0104f59 <vprintfmt+0x21a>
f0104f3e:	0f be c0             	movsbl %al,%eax
f0104f41:	83 e8 20             	sub    $0x20,%eax
f0104f44:	83 f8 5e             	cmp    $0x5e,%eax
f0104f47:	76 10                	jbe    f0104f59 <vprintfmt+0x21a>
					putch('?', putdat);
f0104f49:	83 ec 08             	sub    $0x8,%esp
f0104f4c:	ff 75 0c             	pushl  0xc(%ebp)
f0104f4f:	6a 3f                	push   $0x3f
f0104f51:	ff 55 08             	call   *0x8(%ebp)
f0104f54:	83 c4 10             	add    $0x10,%esp
f0104f57:	eb 0d                	jmp    f0104f66 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0104f59:	83 ec 08             	sub    $0x8,%esp
f0104f5c:	ff 75 0c             	pushl  0xc(%ebp)
f0104f5f:	52                   	push   %edx
f0104f60:	ff 55 08             	call   *0x8(%ebp)
f0104f63:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104f66:	83 eb 01             	sub    $0x1,%ebx
f0104f69:	eb 1a                	jmp    f0104f85 <vprintfmt+0x246>
f0104f6b:	89 75 08             	mov    %esi,0x8(%ebp)
f0104f6e:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104f71:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104f74:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104f77:	eb 0c                	jmp    f0104f85 <vprintfmt+0x246>
f0104f79:	89 75 08             	mov    %esi,0x8(%ebp)
f0104f7c:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104f7f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104f82:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104f85:	83 c7 01             	add    $0x1,%edi
f0104f88:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104f8c:	0f be d0             	movsbl %al,%edx
f0104f8f:	85 d2                	test   %edx,%edx
f0104f91:	74 23                	je     f0104fb6 <vprintfmt+0x277>
f0104f93:	85 f6                	test   %esi,%esi
f0104f95:	78 a1                	js     f0104f38 <vprintfmt+0x1f9>
f0104f97:	83 ee 01             	sub    $0x1,%esi
f0104f9a:	79 9c                	jns    f0104f38 <vprintfmt+0x1f9>
f0104f9c:	89 df                	mov    %ebx,%edi
f0104f9e:	8b 75 08             	mov    0x8(%ebp),%esi
f0104fa1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104fa4:	eb 18                	jmp    f0104fbe <vprintfmt+0x27f>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104fa6:	83 ec 08             	sub    $0x8,%esp
f0104fa9:	53                   	push   %ebx
f0104faa:	6a 20                	push   $0x20
f0104fac:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104fae:	83 ef 01             	sub    $0x1,%edi
f0104fb1:	83 c4 10             	add    $0x10,%esp
f0104fb4:	eb 08                	jmp    f0104fbe <vprintfmt+0x27f>
f0104fb6:	89 df                	mov    %ebx,%edi
f0104fb8:	8b 75 08             	mov    0x8(%ebp),%esi
f0104fbb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104fbe:	85 ff                	test   %edi,%edi
f0104fc0:	7f e4                	jg     f0104fa6 <vprintfmt+0x267>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104fc2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104fc5:	e9 9b fd ff ff       	jmp    f0104d65 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104fca:	83 fa 01             	cmp    $0x1,%edx
f0104fcd:	7e 16                	jle    f0104fe5 <vprintfmt+0x2a6>
		return va_arg(*ap, long long);
f0104fcf:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fd2:	8d 50 08             	lea    0x8(%eax),%edx
f0104fd5:	89 55 14             	mov    %edx,0x14(%ebp)
f0104fd8:	8b 50 04             	mov    0x4(%eax),%edx
f0104fdb:	8b 00                	mov    (%eax),%eax
f0104fdd:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104fe0:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104fe3:	eb 32                	jmp    f0105017 <vprintfmt+0x2d8>
	else if (lflag)
f0104fe5:	85 d2                	test   %edx,%edx
f0104fe7:	74 18                	je     f0105001 <vprintfmt+0x2c2>
		return va_arg(*ap, long);
f0104fe9:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fec:	8d 50 04             	lea    0x4(%eax),%edx
f0104fef:	89 55 14             	mov    %edx,0x14(%ebp)
f0104ff2:	8b 00                	mov    (%eax),%eax
f0104ff4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104ff7:	89 c1                	mov    %eax,%ecx
f0104ff9:	c1 f9 1f             	sar    $0x1f,%ecx
f0104ffc:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104fff:	eb 16                	jmp    f0105017 <vprintfmt+0x2d8>
	else
		return va_arg(*ap, int);
f0105001:	8b 45 14             	mov    0x14(%ebp),%eax
f0105004:	8d 50 04             	lea    0x4(%eax),%edx
f0105007:	89 55 14             	mov    %edx,0x14(%ebp)
f010500a:	8b 00                	mov    (%eax),%eax
f010500c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010500f:	89 c1                	mov    %eax,%ecx
f0105011:	c1 f9 1f             	sar    $0x1f,%ecx
f0105014:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0105017:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010501a:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010501d:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0105022:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0105026:	79 74                	jns    f010509c <vprintfmt+0x35d>
				putch('-', putdat);
f0105028:	83 ec 08             	sub    $0x8,%esp
f010502b:	53                   	push   %ebx
f010502c:	6a 2d                	push   $0x2d
f010502e:	ff d6                	call   *%esi
				num = -(long long) num;
f0105030:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0105033:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0105036:	f7 d8                	neg    %eax
f0105038:	83 d2 00             	adc    $0x0,%edx
f010503b:	f7 da                	neg    %edx
f010503d:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0105040:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0105045:	eb 55                	jmp    f010509c <vprintfmt+0x35d>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0105047:	8d 45 14             	lea    0x14(%ebp),%eax
f010504a:	e8 7c fc ff ff       	call   f0104ccb <getuint>
			base = 10;
f010504f:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0105054:	eb 46                	jmp    f010509c <vprintfmt+0x35d>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0105056:	8d 45 14             	lea    0x14(%ebp),%eax
f0105059:	e8 6d fc ff ff       	call   f0104ccb <getuint>
			base = 8;
f010505e:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0105063:	eb 37                	jmp    f010509c <vprintfmt+0x35d>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f0105065:	83 ec 08             	sub    $0x8,%esp
f0105068:	53                   	push   %ebx
f0105069:	6a 30                	push   $0x30
f010506b:	ff d6                	call   *%esi
			putch('x', putdat);
f010506d:	83 c4 08             	add    $0x8,%esp
f0105070:	53                   	push   %ebx
f0105071:	6a 78                	push   $0x78
f0105073:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0105075:	8b 45 14             	mov    0x14(%ebp),%eax
f0105078:	8d 50 04             	lea    0x4(%eax),%edx
f010507b:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f010507e:	8b 00                	mov    (%eax),%eax
f0105080:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0105085:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0105088:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f010508d:	eb 0d                	jmp    f010509c <vprintfmt+0x35d>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010508f:	8d 45 14             	lea    0x14(%ebp),%eax
f0105092:	e8 34 fc ff ff       	call   f0104ccb <getuint>
			base = 16;
f0105097:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f010509c:	83 ec 0c             	sub    $0xc,%esp
f010509f:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01050a3:	57                   	push   %edi
f01050a4:	ff 75 e0             	pushl  -0x20(%ebp)
f01050a7:	51                   	push   %ecx
f01050a8:	52                   	push   %edx
f01050a9:	50                   	push   %eax
f01050aa:	89 da                	mov    %ebx,%edx
f01050ac:	89 f0                	mov    %esi,%eax
f01050ae:	e8 6e fb ff ff       	call   f0104c21 <printnum>
			break;
f01050b3:	83 c4 20             	add    $0x20,%esp
f01050b6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01050b9:	e9 a7 fc ff ff       	jmp    f0104d65 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01050be:	83 ec 08             	sub    $0x8,%esp
f01050c1:	53                   	push   %ebx
f01050c2:	51                   	push   %ecx
f01050c3:	ff d6                	call   *%esi
			break;
f01050c5:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01050c8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01050cb:	e9 95 fc ff ff       	jmp    f0104d65 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01050d0:	83 ec 08             	sub    $0x8,%esp
f01050d3:	53                   	push   %ebx
f01050d4:	6a 25                	push   $0x25
f01050d6:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01050d8:	83 c4 10             	add    $0x10,%esp
f01050db:	eb 03                	jmp    f01050e0 <vprintfmt+0x3a1>
f01050dd:	83 ef 01             	sub    $0x1,%edi
f01050e0:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01050e4:	75 f7                	jne    f01050dd <vprintfmt+0x39e>
f01050e6:	e9 7a fc ff ff       	jmp    f0104d65 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01050eb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01050ee:	5b                   	pop    %ebx
f01050ef:	5e                   	pop    %esi
f01050f0:	5f                   	pop    %edi
f01050f1:	5d                   	pop    %ebp
f01050f2:	c3                   	ret    

f01050f3 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01050f3:	55                   	push   %ebp
f01050f4:	89 e5                	mov    %esp,%ebp
f01050f6:	83 ec 18             	sub    $0x18,%esp
f01050f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01050fc:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01050ff:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105102:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0105106:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0105109:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0105110:	85 c0                	test   %eax,%eax
f0105112:	74 26                	je     f010513a <vsnprintf+0x47>
f0105114:	85 d2                	test   %edx,%edx
f0105116:	7e 22                	jle    f010513a <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0105118:	ff 75 14             	pushl  0x14(%ebp)
f010511b:	ff 75 10             	pushl  0x10(%ebp)
f010511e:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0105121:	50                   	push   %eax
f0105122:	68 05 4d 10 f0       	push   $0xf0104d05
f0105127:	e8 13 fc ff ff       	call   f0104d3f <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010512c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010512f:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0105132:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105135:	83 c4 10             	add    $0x10,%esp
f0105138:	eb 05                	jmp    f010513f <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010513a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010513f:	c9                   	leave  
f0105140:	c3                   	ret    

f0105141 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0105141:	55                   	push   %ebp
f0105142:	89 e5                	mov    %esp,%ebp
f0105144:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0105147:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010514a:	50                   	push   %eax
f010514b:	ff 75 10             	pushl  0x10(%ebp)
f010514e:	ff 75 0c             	pushl  0xc(%ebp)
f0105151:	ff 75 08             	pushl  0x8(%ebp)
f0105154:	e8 9a ff ff ff       	call   f01050f3 <vsnprintf>
	va_end(ap);

	return rc;
}
f0105159:	c9                   	leave  
f010515a:	c3                   	ret    

f010515b <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010515b:	55                   	push   %ebp
f010515c:	89 e5                	mov    %esp,%ebp
f010515e:	57                   	push   %edi
f010515f:	56                   	push   %esi
f0105160:	53                   	push   %ebx
f0105161:	83 ec 0c             	sub    $0xc,%esp
f0105164:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0105167:	85 c0                	test   %eax,%eax
f0105169:	74 11                	je     f010517c <readline+0x21>
		cprintf("%s", prompt);
f010516b:	83 ec 08             	sub    $0x8,%esp
f010516e:	50                   	push   %eax
f010516f:	68 6d 70 10 f0       	push   $0xf010706d
f0105174:	e8 e1 e6 ff ff       	call   f010385a <cprintf>
f0105179:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010517c:	83 ec 0c             	sub    $0xc,%esp
f010517f:	6a 00                	push   $0x0
f0105181:	e8 e0 b5 ff ff       	call   f0100766 <iscons>
f0105186:	89 c7                	mov    %eax,%edi
f0105188:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010518b:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0105190:	e8 c0 b5 ff ff       	call   f0100755 <getchar>
f0105195:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0105197:	85 c0                	test   %eax,%eax
f0105199:	79 18                	jns    f01051b3 <readline+0x58>
			cprintf("read error: %e\n", c);
f010519b:	83 ec 08             	sub    $0x8,%esp
f010519e:	50                   	push   %eax
f010519f:	68 a8 7b 10 f0       	push   $0xf0107ba8
f01051a4:	e8 b1 e6 ff ff       	call   f010385a <cprintf>
			return NULL;
f01051a9:	83 c4 10             	add    $0x10,%esp
f01051ac:	b8 00 00 00 00       	mov    $0x0,%eax
f01051b1:	eb 79                	jmp    f010522c <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01051b3:	83 f8 7f             	cmp    $0x7f,%eax
f01051b6:	0f 94 c2             	sete   %dl
f01051b9:	83 f8 08             	cmp    $0x8,%eax
f01051bc:	0f 94 c0             	sete   %al
f01051bf:	08 c2                	or     %al,%dl
f01051c1:	74 1a                	je     f01051dd <readline+0x82>
f01051c3:	85 f6                	test   %esi,%esi
f01051c5:	7e 16                	jle    f01051dd <readline+0x82>
			if (echoing)
f01051c7:	85 ff                	test   %edi,%edi
f01051c9:	74 0d                	je     f01051d8 <readline+0x7d>
				cputchar('\b');
f01051cb:	83 ec 0c             	sub    $0xc,%esp
f01051ce:	6a 08                	push   $0x8
f01051d0:	e8 70 b5 ff ff       	call   f0100745 <cputchar>
f01051d5:	83 c4 10             	add    $0x10,%esp
			i--;
f01051d8:	83 ee 01             	sub    $0x1,%esi
f01051db:	eb b3                	jmp    f0105190 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01051dd:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01051e3:	7f 20                	jg     f0105205 <readline+0xaa>
f01051e5:	83 fb 1f             	cmp    $0x1f,%ebx
f01051e8:	7e 1b                	jle    f0105205 <readline+0xaa>
			if (echoing)
f01051ea:	85 ff                	test   %edi,%edi
f01051ec:	74 0c                	je     f01051fa <readline+0x9f>
				cputchar(c);
f01051ee:	83 ec 0c             	sub    $0xc,%esp
f01051f1:	53                   	push   %ebx
f01051f2:	e8 4e b5 ff ff       	call   f0100745 <cputchar>
f01051f7:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01051fa:	88 9e c0 0a 23 f0    	mov    %bl,-0xfdcf540(%esi)
f0105200:	8d 76 01             	lea    0x1(%esi),%esi
f0105203:	eb 8b                	jmp    f0105190 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0105205:	83 fb 0d             	cmp    $0xd,%ebx
f0105208:	74 05                	je     f010520f <readline+0xb4>
f010520a:	83 fb 0a             	cmp    $0xa,%ebx
f010520d:	75 81                	jne    f0105190 <readline+0x35>
			if (echoing)
f010520f:	85 ff                	test   %edi,%edi
f0105211:	74 0d                	je     f0105220 <readline+0xc5>
				cputchar('\n');
f0105213:	83 ec 0c             	sub    $0xc,%esp
f0105216:	6a 0a                	push   $0xa
f0105218:	e8 28 b5 ff ff       	call   f0100745 <cputchar>
f010521d:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0105220:	c6 86 c0 0a 23 f0 00 	movb   $0x0,-0xfdcf540(%esi)
			return buf;
f0105227:	b8 c0 0a 23 f0       	mov    $0xf0230ac0,%eax
		}
	}
}
f010522c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010522f:	5b                   	pop    %ebx
f0105230:	5e                   	pop    %esi
f0105231:	5f                   	pop    %edi
f0105232:	5d                   	pop    %ebp
f0105233:	c3                   	ret    

f0105234 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0105234:	55                   	push   %ebp
f0105235:	89 e5                	mov    %esp,%ebp
f0105237:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010523a:	b8 00 00 00 00       	mov    $0x0,%eax
f010523f:	eb 03                	jmp    f0105244 <strlen+0x10>
		n++;
f0105241:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0105244:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0105248:	75 f7                	jne    f0105241 <strlen+0xd>
		n++;
	return n;
}
f010524a:	5d                   	pop    %ebp
f010524b:	c3                   	ret    

f010524c <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010524c:	55                   	push   %ebp
f010524d:	89 e5                	mov    %esp,%ebp
f010524f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105252:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105255:	ba 00 00 00 00       	mov    $0x0,%edx
f010525a:	eb 03                	jmp    f010525f <strnlen+0x13>
		n++;
f010525c:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010525f:	39 c2                	cmp    %eax,%edx
f0105261:	74 08                	je     f010526b <strnlen+0x1f>
f0105263:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0105267:	75 f3                	jne    f010525c <strnlen+0x10>
f0105269:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010526b:	5d                   	pop    %ebp
f010526c:	c3                   	ret    

f010526d <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010526d:	55                   	push   %ebp
f010526e:	89 e5                	mov    %esp,%ebp
f0105270:	53                   	push   %ebx
f0105271:	8b 45 08             	mov    0x8(%ebp),%eax
f0105274:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0105277:	89 c2                	mov    %eax,%edx
f0105279:	83 c2 01             	add    $0x1,%edx
f010527c:	83 c1 01             	add    $0x1,%ecx
f010527f:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0105283:	88 5a ff             	mov    %bl,-0x1(%edx)
f0105286:	84 db                	test   %bl,%bl
f0105288:	75 ef                	jne    f0105279 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010528a:	5b                   	pop    %ebx
f010528b:	5d                   	pop    %ebp
f010528c:	c3                   	ret    

f010528d <strcat>:

char *
strcat(char *dst, const char *src)
{
f010528d:	55                   	push   %ebp
f010528e:	89 e5                	mov    %esp,%ebp
f0105290:	53                   	push   %ebx
f0105291:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0105294:	53                   	push   %ebx
f0105295:	e8 9a ff ff ff       	call   f0105234 <strlen>
f010529a:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010529d:	ff 75 0c             	pushl  0xc(%ebp)
f01052a0:	01 d8                	add    %ebx,%eax
f01052a2:	50                   	push   %eax
f01052a3:	e8 c5 ff ff ff       	call   f010526d <strcpy>
	return dst;
}
f01052a8:	89 d8                	mov    %ebx,%eax
f01052aa:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01052ad:	c9                   	leave  
f01052ae:	c3                   	ret    

f01052af <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01052af:	55                   	push   %ebp
f01052b0:	89 e5                	mov    %esp,%ebp
f01052b2:	56                   	push   %esi
f01052b3:	53                   	push   %ebx
f01052b4:	8b 75 08             	mov    0x8(%ebp),%esi
f01052b7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01052ba:	89 f3                	mov    %esi,%ebx
f01052bc:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01052bf:	89 f2                	mov    %esi,%edx
f01052c1:	eb 0f                	jmp    f01052d2 <strncpy+0x23>
		*dst++ = *src;
f01052c3:	83 c2 01             	add    $0x1,%edx
f01052c6:	0f b6 01             	movzbl (%ecx),%eax
f01052c9:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01052cc:	80 39 01             	cmpb   $0x1,(%ecx)
f01052cf:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01052d2:	39 da                	cmp    %ebx,%edx
f01052d4:	75 ed                	jne    f01052c3 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01052d6:	89 f0                	mov    %esi,%eax
f01052d8:	5b                   	pop    %ebx
f01052d9:	5e                   	pop    %esi
f01052da:	5d                   	pop    %ebp
f01052db:	c3                   	ret    

f01052dc <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01052dc:	55                   	push   %ebp
f01052dd:	89 e5                	mov    %esp,%ebp
f01052df:	56                   	push   %esi
f01052e0:	53                   	push   %ebx
f01052e1:	8b 75 08             	mov    0x8(%ebp),%esi
f01052e4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01052e7:	8b 55 10             	mov    0x10(%ebp),%edx
f01052ea:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01052ec:	85 d2                	test   %edx,%edx
f01052ee:	74 21                	je     f0105311 <strlcpy+0x35>
f01052f0:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01052f4:	89 f2                	mov    %esi,%edx
f01052f6:	eb 09                	jmp    f0105301 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01052f8:	83 c2 01             	add    $0x1,%edx
f01052fb:	83 c1 01             	add    $0x1,%ecx
f01052fe:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0105301:	39 c2                	cmp    %eax,%edx
f0105303:	74 09                	je     f010530e <strlcpy+0x32>
f0105305:	0f b6 19             	movzbl (%ecx),%ebx
f0105308:	84 db                	test   %bl,%bl
f010530a:	75 ec                	jne    f01052f8 <strlcpy+0x1c>
f010530c:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010530e:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105311:	29 f0                	sub    %esi,%eax
}
f0105313:	5b                   	pop    %ebx
f0105314:	5e                   	pop    %esi
f0105315:	5d                   	pop    %ebp
f0105316:	c3                   	ret    

f0105317 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0105317:	55                   	push   %ebp
f0105318:	89 e5                	mov    %esp,%ebp
f010531a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010531d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105320:	eb 06                	jmp    f0105328 <strcmp+0x11>
		p++, q++;
f0105322:	83 c1 01             	add    $0x1,%ecx
f0105325:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0105328:	0f b6 01             	movzbl (%ecx),%eax
f010532b:	84 c0                	test   %al,%al
f010532d:	74 04                	je     f0105333 <strcmp+0x1c>
f010532f:	3a 02                	cmp    (%edx),%al
f0105331:	74 ef                	je     f0105322 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105333:	0f b6 c0             	movzbl %al,%eax
f0105336:	0f b6 12             	movzbl (%edx),%edx
f0105339:	29 d0                	sub    %edx,%eax
}
f010533b:	5d                   	pop    %ebp
f010533c:	c3                   	ret    

f010533d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010533d:	55                   	push   %ebp
f010533e:	89 e5                	mov    %esp,%ebp
f0105340:	53                   	push   %ebx
f0105341:	8b 45 08             	mov    0x8(%ebp),%eax
f0105344:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105347:	89 c3                	mov    %eax,%ebx
f0105349:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010534c:	eb 06                	jmp    f0105354 <strncmp+0x17>
		n--, p++, q++;
f010534e:	83 c0 01             	add    $0x1,%eax
f0105351:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0105354:	39 d8                	cmp    %ebx,%eax
f0105356:	74 15                	je     f010536d <strncmp+0x30>
f0105358:	0f b6 08             	movzbl (%eax),%ecx
f010535b:	84 c9                	test   %cl,%cl
f010535d:	74 04                	je     f0105363 <strncmp+0x26>
f010535f:	3a 0a                	cmp    (%edx),%cl
f0105361:	74 eb                	je     f010534e <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105363:	0f b6 00             	movzbl (%eax),%eax
f0105366:	0f b6 12             	movzbl (%edx),%edx
f0105369:	29 d0                	sub    %edx,%eax
f010536b:	eb 05                	jmp    f0105372 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010536d:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0105372:	5b                   	pop    %ebx
f0105373:	5d                   	pop    %ebp
f0105374:	c3                   	ret    

f0105375 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0105375:	55                   	push   %ebp
f0105376:	89 e5                	mov    %esp,%ebp
f0105378:	8b 45 08             	mov    0x8(%ebp),%eax
f010537b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010537f:	eb 07                	jmp    f0105388 <strchr+0x13>
		if (*s == c)
f0105381:	38 ca                	cmp    %cl,%dl
f0105383:	74 0f                	je     f0105394 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0105385:	83 c0 01             	add    $0x1,%eax
f0105388:	0f b6 10             	movzbl (%eax),%edx
f010538b:	84 d2                	test   %dl,%dl
f010538d:	75 f2                	jne    f0105381 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010538f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105394:	5d                   	pop    %ebp
f0105395:	c3                   	ret    

f0105396 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0105396:	55                   	push   %ebp
f0105397:	89 e5                	mov    %esp,%ebp
f0105399:	8b 45 08             	mov    0x8(%ebp),%eax
f010539c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01053a0:	eb 03                	jmp    f01053a5 <strfind+0xf>
f01053a2:	83 c0 01             	add    $0x1,%eax
f01053a5:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01053a8:	84 d2                	test   %dl,%dl
f01053aa:	74 04                	je     f01053b0 <strfind+0x1a>
f01053ac:	38 ca                	cmp    %cl,%dl
f01053ae:	75 f2                	jne    f01053a2 <strfind+0xc>
			break;
	return (char *) s;
}
f01053b0:	5d                   	pop    %ebp
f01053b1:	c3                   	ret    

f01053b2 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01053b2:	55                   	push   %ebp
f01053b3:	89 e5                	mov    %esp,%ebp
f01053b5:	57                   	push   %edi
f01053b6:	56                   	push   %esi
f01053b7:	53                   	push   %ebx
f01053b8:	8b 7d 08             	mov    0x8(%ebp),%edi
f01053bb:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01053be:	85 c9                	test   %ecx,%ecx
f01053c0:	74 36                	je     f01053f8 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01053c2:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01053c8:	75 28                	jne    f01053f2 <memset+0x40>
f01053ca:	f6 c1 03             	test   $0x3,%cl
f01053cd:	75 23                	jne    f01053f2 <memset+0x40>
		c &= 0xFF;
f01053cf:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01053d3:	89 d3                	mov    %edx,%ebx
f01053d5:	c1 e3 08             	shl    $0x8,%ebx
f01053d8:	89 d6                	mov    %edx,%esi
f01053da:	c1 e6 18             	shl    $0x18,%esi
f01053dd:	89 d0                	mov    %edx,%eax
f01053df:	c1 e0 10             	shl    $0x10,%eax
f01053e2:	09 f0                	or     %esi,%eax
f01053e4:	09 c2                	or     %eax,%edx
f01053e6:	89 d0                	mov    %edx,%eax
f01053e8:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01053ea:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01053ed:	fc                   	cld    
f01053ee:	f3 ab                	rep stos %eax,%es:(%edi)
f01053f0:	eb 06                	jmp    f01053f8 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01053f2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01053f5:	fc                   	cld    
f01053f6:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01053f8:	89 f8                	mov    %edi,%eax
f01053fa:	5b                   	pop    %ebx
f01053fb:	5e                   	pop    %esi
f01053fc:	5f                   	pop    %edi
f01053fd:	5d                   	pop    %ebp
f01053fe:	c3                   	ret    

f01053ff <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01053ff:	55                   	push   %ebp
f0105400:	89 e5                	mov    %esp,%ebp
f0105402:	57                   	push   %edi
f0105403:	56                   	push   %esi
f0105404:	8b 45 08             	mov    0x8(%ebp),%eax
f0105407:	8b 75 0c             	mov    0xc(%ebp),%esi
f010540a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010540d:	39 c6                	cmp    %eax,%esi
f010540f:	73 35                	jae    f0105446 <memmove+0x47>
f0105411:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105414:	39 d0                	cmp    %edx,%eax
f0105416:	73 2e                	jae    f0105446 <memmove+0x47>
		s += n;
		d += n;
f0105418:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f010541b:	89 d6                	mov    %edx,%esi
f010541d:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010541f:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105425:	75 13                	jne    f010543a <memmove+0x3b>
f0105427:	f6 c1 03             	test   $0x3,%cl
f010542a:	75 0e                	jne    f010543a <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f010542c:	83 ef 04             	sub    $0x4,%edi
f010542f:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105432:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0105435:	fd                   	std    
f0105436:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105438:	eb 09                	jmp    f0105443 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010543a:	83 ef 01             	sub    $0x1,%edi
f010543d:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0105440:	fd                   	std    
f0105441:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105443:	fc                   	cld    
f0105444:	eb 1d                	jmp    f0105463 <memmove+0x64>
f0105446:	89 f2                	mov    %esi,%edx
f0105448:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010544a:	f6 c2 03             	test   $0x3,%dl
f010544d:	75 0f                	jne    f010545e <memmove+0x5f>
f010544f:	f6 c1 03             	test   $0x3,%cl
f0105452:	75 0a                	jne    f010545e <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0105454:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0105457:	89 c7                	mov    %eax,%edi
f0105459:	fc                   	cld    
f010545a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010545c:	eb 05                	jmp    f0105463 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010545e:	89 c7                	mov    %eax,%edi
f0105460:	fc                   	cld    
f0105461:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105463:	5e                   	pop    %esi
f0105464:	5f                   	pop    %edi
f0105465:	5d                   	pop    %ebp
f0105466:	c3                   	ret    

f0105467 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0105467:	55                   	push   %ebp
f0105468:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010546a:	ff 75 10             	pushl  0x10(%ebp)
f010546d:	ff 75 0c             	pushl  0xc(%ebp)
f0105470:	ff 75 08             	pushl  0x8(%ebp)
f0105473:	e8 87 ff ff ff       	call   f01053ff <memmove>
}
f0105478:	c9                   	leave  
f0105479:	c3                   	ret    

f010547a <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010547a:	55                   	push   %ebp
f010547b:	89 e5                	mov    %esp,%ebp
f010547d:	56                   	push   %esi
f010547e:	53                   	push   %ebx
f010547f:	8b 45 08             	mov    0x8(%ebp),%eax
f0105482:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105485:	89 c6                	mov    %eax,%esi
f0105487:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010548a:	eb 1a                	jmp    f01054a6 <memcmp+0x2c>
		if (*s1 != *s2)
f010548c:	0f b6 08             	movzbl (%eax),%ecx
f010548f:	0f b6 1a             	movzbl (%edx),%ebx
f0105492:	38 d9                	cmp    %bl,%cl
f0105494:	74 0a                	je     f01054a0 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0105496:	0f b6 c1             	movzbl %cl,%eax
f0105499:	0f b6 db             	movzbl %bl,%ebx
f010549c:	29 d8                	sub    %ebx,%eax
f010549e:	eb 0f                	jmp    f01054af <memcmp+0x35>
		s1++, s2++;
f01054a0:	83 c0 01             	add    $0x1,%eax
f01054a3:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01054a6:	39 f0                	cmp    %esi,%eax
f01054a8:	75 e2                	jne    f010548c <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01054aa:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01054af:	5b                   	pop    %ebx
f01054b0:	5e                   	pop    %esi
f01054b1:	5d                   	pop    %ebp
f01054b2:	c3                   	ret    

f01054b3 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01054b3:	55                   	push   %ebp
f01054b4:	89 e5                	mov    %esp,%ebp
f01054b6:	8b 45 08             	mov    0x8(%ebp),%eax
f01054b9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01054bc:	89 c2                	mov    %eax,%edx
f01054be:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01054c1:	eb 07                	jmp    f01054ca <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01054c3:	38 08                	cmp    %cl,(%eax)
f01054c5:	74 07                	je     f01054ce <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01054c7:	83 c0 01             	add    $0x1,%eax
f01054ca:	39 d0                	cmp    %edx,%eax
f01054cc:	72 f5                	jb     f01054c3 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01054ce:	5d                   	pop    %ebp
f01054cf:	c3                   	ret    

f01054d0 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01054d0:	55                   	push   %ebp
f01054d1:	89 e5                	mov    %esp,%ebp
f01054d3:	57                   	push   %edi
f01054d4:	56                   	push   %esi
f01054d5:	53                   	push   %ebx
f01054d6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01054d9:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01054dc:	eb 03                	jmp    f01054e1 <strtol+0x11>
		s++;
f01054de:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01054e1:	0f b6 01             	movzbl (%ecx),%eax
f01054e4:	3c 09                	cmp    $0x9,%al
f01054e6:	74 f6                	je     f01054de <strtol+0xe>
f01054e8:	3c 20                	cmp    $0x20,%al
f01054ea:	74 f2                	je     f01054de <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01054ec:	3c 2b                	cmp    $0x2b,%al
f01054ee:	75 0a                	jne    f01054fa <strtol+0x2a>
		s++;
f01054f0:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01054f3:	bf 00 00 00 00       	mov    $0x0,%edi
f01054f8:	eb 10                	jmp    f010550a <strtol+0x3a>
f01054fa:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01054ff:	3c 2d                	cmp    $0x2d,%al
f0105501:	75 07                	jne    f010550a <strtol+0x3a>
		s++, neg = 1;
f0105503:	8d 49 01             	lea    0x1(%ecx),%ecx
f0105506:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010550a:	85 db                	test   %ebx,%ebx
f010550c:	0f 94 c0             	sete   %al
f010550f:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0105515:	75 19                	jne    f0105530 <strtol+0x60>
f0105517:	80 39 30             	cmpb   $0x30,(%ecx)
f010551a:	75 14                	jne    f0105530 <strtol+0x60>
f010551c:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0105520:	0f 85 82 00 00 00    	jne    f01055a8 <strtol+0xd8>
		s += 2, base = 16;
f0105526:	83 c1 02             	add    $0x2,%ecx
f0105529:	bb 10 00 00 00       	mov    $0x10,%ebx
f010552e:	eb 16                	jmp    f0105546 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0105530:	84 c0                	test   %al,%al
f0105532:	74 12                	je     f0105546 <strtol+0x76>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105534:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105539:	80 39 30             	cmpb   $0x30,(%ecx)
f010553c:	75 08                	jne    f0105546 <strtol+0x76>
		s++, base = 8;
f010553e:	83 c1 01             	add    $0x1,%ecx
f0105541:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0105546:	b8 00 00 00 00       	mov    $0x0,%eax
f010554b:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010554e:	0f b6 11             	movzbl (%ecx),%edx
f0105551:	8d 72 d0             	lea    -0x30(%edx),%esi
f0105554:	89 f3                	mov    %esi,%ebx
f0105556:	80 fb 09             	cmp    $0x9,%bl
f0105559:	77 08                	ja     f0105563 <strtol+0x93>
			dig = *s - '0';
f010555b:	0f be d2             	movsbl %dl,%edx
f010555e:	83 ea 30             	sub    $0x30,%edx
f0105561:	eb 22                	jmp    f0105585 <strtol+0xb5>
		else if (*s >= 'a' && *s <= 'z')
f0105563:	8d 72 9f             	lea    -0x61(%edx),%esi
f0105566:	89 f3                	mov    %esi,%ebx
f0105568:	80 fb 19             	cmp    $0x19,%bl
f010556b:	77 08                	ja     f0105575 <strtol+0xa5>
			dig = *s - 'a' + 10;
f010556d:	0f be d2             	movsbl %dl,%edx
f0105570:	83 ea 57             	sub    $0x57,%edx
f0105573:	eb 10                	jmp    f0105585 <strtol+0xb5>
		else if (*s >= 'A' && *s <= 'Z')
f0105575:	8d 72 bf             	lea    -0x41(%edx),%esi
f0105578:	89 f3                	mov    %esi,%ebx
f010557a:	80 fb 19             	cmp    $0x19,%bl
f010557d:	77 16                	ja     f0105595 <strtol+0xc5>
			dig = *s - 'A' + 10;
f010557f:	0f be d2             	movsbl %dl,%edx
f0105582:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0105585:	3b 55 10             	cmp    0x10(%ebp),%edx
f0105588:	7d 0f                	jge    f0105599 <strtol+0xc9>
			break;
		s++, val = (val * base) + dig;
f010558a:	83 c1 01             	add    $0x1,%ecx
f010558d:	0f af 45 10          	imul   0x10(%ebp),%eax
f0105591:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0105593:	eb b9                	jmp    f010554e <strtol+0x7e>
f0105595:	89 c2                	mov    %eax,%edx
f0105597:	eb 02                	jmp    f010559b <strtol+0xcb>
f0105599:	89 c2                	mov    %eax,%edx

	if (endptr)
f010559b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010559f:	74 0d                	je     f01055ae <strtol+0xde>
		*endptr = (char *) s;
f01055a1:	8b 75 0c             	mov    0xc(%ebp),%esi
f01055a4:	89 0e                	mov    %ecx,(%esi)
f01055a6:	eb 06                	jmp    f01055ae <strtol+0xde>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01055a8:	84 c0                	test   %al,%al
f01055aa:	75 92                	jne    f010553e <strtol+0x6e>
f01055ac:	eb 98                	jmp    f0105546 <strtol+0x76>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01055ae:	f7 da                	neg    %edx
f01055b0:	85 ff                	test   %edi,%edi
f01055b2:	0f 45 c2             	cmovne %edx,%eax
}
f01055b5:	5b                   	pop    %ebx
f01055b6:	5e                   	pop    %esi
f01055b7:	5f                   	pop    %edi
f01055b8:	5d                   	pop    %ebp
f01055b9:	c3                   	ret    
f01055ba:	66 90                	xchg   %ax,%ax

f01055bc <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f01055bc:	fa                   	cli    

	xorw    %ax, %ax
f01055bd:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f01055bf:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01055c1:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01055c3:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f01055c5:	0f 01 16             	lgdtl  (%esi)
f01055c8:	74 70                	je     f010563a <mpsearch1+0x3>
	movl    %cr0, %eax
f01055ca:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f01055cd:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f01055d1:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f01055d4:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f01055da:	08 00                	or     %al,(%eax)

f01055dc <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f01055dc:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f01055e0:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01055e2:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01055e4:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f01055e6:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f01055ea:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f01055ec:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f01055ee:	b8 00 e0 11 00       	mov    $0x11e000,%eax
	movl    %eax, %cr3
f01055f3:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f01055f6:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f01055f9:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f01055fe:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0105601:	8b 25 c4 0e 23 f0    	mov    0xf0230ec4,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0105607:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f010560c:	b8 b4 01 10 f0       	mov    $0xf01001b4,%eax
	call    *%eax
f0105611:	ff d0                	call   *%eax

f0105613 <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0105613:	eb fe                	jmp    f0105613 <spin>
f0105615:	8d 76 00             	lea    0x0(%esi),%esi

f0105618 <gdt>:
	...
f0105620:	ff                   	(bad)  
f0105621:	ff 00                	incl   (%eax)
f0105623:	00 00                	add    %al,(%eax)
f0105625:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f010562c:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

f0105630 <gdtdesc>:
f0105630:	17                   	pop    %ss
f0105631:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0105636 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0105636:	90                   	nop

f0105637 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0105637:	55                   	push   %ebp
f0105638:	89 e5                	mov    %esp,%ebp
f010563a:	57                   	push   %edi
f010563b:	56                   	push   %esi
f010563c:	53                   	push   %ebx
f010563d:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105640:	8b 0d c8 0e 23 f0    	mov    0xf0230ec8,%ecx
f0105646:	89 c3                	mov    %eax,%ebx
f0105648:	c1 eb 0c             	shr    $0xc,%ebx
f010564b:	39 cb                	cmp    %ecx,%ebx
f010564d:	72 12                	jb     f0105661 <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010564f:	50                   	push   %eax
f0105650:	68 a4 60 10 f0       	push   $0xf01060a4
f0105655:	6a 57                	push   $0x57
f0105657:	68 45 7d 10 f0       	push   $0xf0107d45
f010565c:	e8 df a9 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105661:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0105667:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105669:	89 c2                	mov    %eax,%edx
f010566b:	c1 ea 0c             	shr    $0xc,%edx
f010566e:	39 d1                	cmp    %edx,%ecx
f0105670:	77 12                	ja     f0105684 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105672:	50                   	push   %eax
f0105673:	68 a4 60 10 f0       	push   $0xf01060a4
f0105678:	6a 57                	push   $0x57
f010567a:	68 45 7d 10 f0       	push   $0xf0107d45
f010567f:	e8 bc a9 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105684:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f010568a:	eb 2f                	jmp    f01056bb <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f010568c:	83 ec 04             	sub    $0x4,%esp
f010568f:	6a 04                	push   $0x4
f0105691:	68 55 7d 10 f0       	push   $0xf0107d55
f0105696:	53                   	push   %ebx
f0105697:	e8 de fd ff ff       	call   f010547a <memcmp>
f010569c:	83 c4 10             	add    $0x10,%esp
f010569f:	85 c0                	test   %eax,%eax
f01056a1:	75 15                	jne    f01056b8 <mpsearch1+0x81>
f01056a3:	89 da                	mov    %ebx,%edx
f01056a5:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f01056a8:	0f b6 0a             	movzbl (%edx),%ecx
f01056ab:	01 c8                	add    %ecx,%eax
f01056ad:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01056b0:	39 fa                	cmp    %edi,%edx
f01056b2:	75 f4                	jne    f01056a8 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01056b4:	84 c0                	test   %al,%al
f01056b6:	74 0e                	je     f01056c6 <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f01056b8:	83 c3 10             	add    $0x10,%ebx
f01056bb:	39 f3                	cmp    %esi,%ebx
f01056bd:	72 cd                	jb     f010568c <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f01056bf:	b8 00 00 00 00       	mov    $0x0,%eax
f01056c4:	eb 02                	jmp    f01056c8 <mpsearch1+0x91>
f01056c6:	89 d8                	mov    %ebx,%eax
}
f01056c8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01056cb:	5b                   	pop    %ebx
f01056cc:	5e                   	pop    %esi
f01056cd:	5f                   	pop    %edi
f01056ce:	5d                   	pop    %ebp
f01056cf:	c3                   	ret    

f01056d0 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f01056d0:	55                   	push   %ebp
f01056d1:	89 e5                	mov    %esp,%ebp
f01056d3:	57                   	push   %edi
f01056d4:	56                   	push   %esi
f01056d5:	53                   	push   %ebx
f01056d6:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f01056d9:	c7 05 e0 13 23 f0 40 	movl   $0xf0231040,0xf02313e0
f01056e0:	10 23 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01056e3:	83 3d c8 0e 23 f0 00 	cmpl   $0x0,0xf0230ec8
f01056ea:	75 16                	jne    f0105702 <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01056ec:	68 00 04 00 00       	push   $0x400
f01056f1:	68 a4 60 10 f0       	push   $0xf01060a4
f01056f6:	6a 6f                	push   $0x6f
f01056f8:	68 45 7d 10 f0       	push   $0xf0107d45
f01056fd:	e8 3e a9 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0105702:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105709:	85 c0                	test   %eax,%eax
f010570b:	74 16                	je     f0105723 <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
f010570d:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f0105710:	ba 00 04 00 00       	mov    $0x400,%edx
f0105715:	e8 1d ff ff ff       	call   f0105637 <mpsearch1>
f010571a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010571d:	85 c0                	test   %eax,%eax
f010571f:	75 3c                	jne    f010575d <mp_init+0x8d>
f0105721:	eb 20                	jmp    f0105743 <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
f0105723:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f010572a:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f010572d:	2d 00 04 00 00       	sub    $0x400,%eax
f0105732:	ba 00 04 00 00       	mov    $0x400,%edx
f0105737:	e8 fb fe ff ff       	call   f0105637 <mpsearch1>
f010573c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010573f:	85 c0                	test   %eax,%eax
f0105741:	75 1a                	jne    f010575d <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f0105743:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105748:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f010574d:	e8 e5 fe ff ff       	call   f0105637 <mpsearch1>
f0105752:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f0105755:	85 c0                	test   %eax,%eax
f0105757:	0f 84 5a 02 00 00    	je     f01059b7 <mp_init+0x2e7>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f010575d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105760:	8b 70 04             	mov    0x4(%eax),%esi
f0105763:	85 f6                	test   %esi,%esi
f0105765:	74 06                	je     f010576d <mp_init+0x9d>
f0105767:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f010576b:	74 15                	je     f0105782 <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f010576d:	83 ec 0c             	sub    $0xc,%esp
f0105770:	68 b8 7b 10 f0       	push   $0xf0107bb8
f0105775:	e8 e0 e0 ff ff       	call   f010385a <cprintf>
f010577a:	83 c4 10             	add    $0x10,%esp
f010577d:	e9 35 02 00 00       	jmp    f01059b7 <mp_init+0x2e7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105782:	89 f0                	mov    %esi,%eax
f0105784:	c1 e8 0c             	shr    $0xc,%eax
f0105787:	3b 05 c8 0e 23 f0    	cmp    0xf0230ec8,%eax
f010578d:	72 15                	jb     f01057a4 <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010578f:	56                   	push   %esi
f0105790:	68 a4 60 10 f0       	push   $0xf01060a4
f0105795:	68 90 00 00 00       	push   $0x90
f010579a:	68 45 7d 10 f0       	push   $0xf0107d45
f010579f:	e8 9c a8 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01057a4:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f01057aa:	83 ec 04             	sub    $0x4,%esp
f01057ad:	6a 04                	push   $0x4
f01057af:	68 5a 7d 10 f0       	push   $0xf0107d5a
f01057b4:	53                   	push   %ebx
f01057b5:	e8 c0 fc ff ff       	call   f010547a <memcmp>
f01057ba:	83 c4 10             	add    $0x10,%esp
f01057bd:	85 c0                	test   %eax,%eax
f01057bf:	74 15                	je     f01057d6 <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f01057c1:	83 ec 0c             	sub    $0xc,%esp
f01057c4:	68 e8 7b 10 f0       	push   $0xf0107be8
f01057c9:	e8 8c e0 ff ff       	call   f010385a <cprintf>
f01057ce:	83 c4 10             	add    $0x10,%esp
f01057d1:	e9 e1 01 00 00       	jmp    f01059b7 <mp_init+0x2e7>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f01057d6:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f01057da:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f01057de:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f01057e1:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f01057e6:	b8 00 00 00 00       	mov    $0x0,%eax
f01057eb:	eb 0d                	jmp    f01057fa <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f01057ed:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f01057f4:	f0 
f01057f5:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01057f7:	83 c0 01             	add    $0x1,%eax
f01057fa:	39 c7                	cmp    %eax,%edi
f01057fc:	75 ef                	jne    f01057ed <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f01057fe:	84 d2                	test   %dl,%dl
f0105800:	74 15                	je     f0105817 <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f0105802:	83 ec 0c             	sub    $0xc,%esp
f0105805:	68 1c 7c 10 f0       	push   $0xf0107c1c
f010580a:	e8 4b e0 ff ff       	call   f010385a <cprintf>
f010580f:	83 c4 10             	add    $0x10,%esp
f0105812:	e9 a0 01 00 00       	jmp    f01059b7 <mp_init+0x2e7>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0105817:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f010581b:	3c 04                	cmp    $0x4,%al
f010581d:	74 1d                	je     f010583c <mp_init+0x16c>
f010581f:	3c 01                	cmp    $0x1,%al
f0105821:	74 19                	je     f010583c <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0105823:	83 ec 08             	sub    $0x8,%esp
f0105826:	0f b6 c0             	movzbl %al,%eax
f0105829:	50                   	push   %eax
f010582a:	68 40 7c 10 f0       	push   $0xf0107c40
f010582f:	e8 26 e0 ff ff       	call   f010385a <cprintf>
f0105834:	83 c4 10             	add    $0x10,%esp
f0105837:	e9 7b 01 00 00       	jmp    f01059b7 <mp_init+0x2e7>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f010583c:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f0105840:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105844:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105849:	b8 00 00 00 00       	mov    $0x0,%eax
f010584e:	01 ce                	add    %ecx,%esi
f0105850:	eb 0d                	jmp    f010585f <mp_init+0x18f>
		sum += ((uint8_t *)addr)[i];
f0105852:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f0105859:	f0 
f010585a:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f010585c:	83 c0 01             	add    $0x1,%eax
f010585f:	39 c7                	cmp    %eax,%edi
f0105861:	75 ef                	jne    f0105852 <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105863:	89 d0                	mov    %edx,%eax
f0105865:	02 43 2a             	add    0x2a(%ebx),%al
f0105868:	74 15                	je     f010587f <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f010586a:	83 ec 0c             	sub    $0xc,%esp
f010586d:	68 60 7c 10 f0       	push   $0xf0107c60
f0105872:	e8 e3 df ff ff       	call   f010385a <cprintf>
f0105877:	83 c4 10             	add    $0x10,%esp
f010587a:	e9 38 01 00 00       	jmp    f01059b7 <mp_init+0x2e7>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f010587f:	85 db                	test   %ebx,%ebx
f0105881:	0f 84 30 01 00 00    	je     f01059b7 <mp_init+0x2e7>
		return;
	ismp = 1;
f0105887:	c7 05 00 10 23 f0 01 	movl   $0x1,0xf0231000
f010588e:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0105891:	8b 43 24             	mov    0x24(%ebx),%eax
f0105894:	a3 00 20 27 f0       	mov    %eax,0xf0272000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105899:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f010589c:	be 00 00 00 00       	mov    $0x0,%esi
f01058a1:	e9 85 00 00 00       	jmp    f010592b <mp_init+0x25b>
		switch (*p) {
f01058a6:	0f b6 07             	movzbl (%edi),%eax
f01058a9:	84 c0                	test   %al,%al
f01058ab:	74 06                	je     f01058b3 <mp_init+0x1e3>
f01058ad:	3c 04                	cmp    $0x4,%al
f01058af:	77 55                	ja     f0105906 <mp_init+0x236>
f01058b1:	eb 4e                	jmp    f0105901 <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f01058b3:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f01058b7:	74 11                	je     f01058ca <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f01058b9:	6b 05 e4 13 23 f0 74 	imul   $0x74,0xf02313e4,%eax
f01058c0:	05 40 10 23 f0       	add    $0xf0231040,%eax
f01058c5:	a3 e0 13 23 f0       	mov    %eax,0xf02313e0
			if (ncpu < NCPU) {
f01058ca:	a1 e4 13 23 f0       	mov    0xf02313e4,%eax
f01058cf:	83 f8 07             	cmp    $0x7,%eax
f01058d2:	7f 13                	jg     f01058e7 <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f01058d4:	6b d0 74             	imul   $0x74,%eax,%edx
f01058d7:	88 82 40 10 23 f0    	mov    %al,-0xfdcefc0(%edx)
				ncpu++;
f01058dd:	83 c0 01             	add    $0x1,%eax
f01058e0:	a3 e4 13 23 f0       	mov    %eax,0xf02313e4
f01058e5:	eb 15                	jmp    f01058fc <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f01058e7:	83 ec 08             	sub    $0x8,%esp
f01058ea:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f01058ee:	50                   	push   %eax
f01058ef:	68 90 7c 10 f0       	push   $0xf0107c90
f01058f4:	e8 61 df ff ff       	call   f010385a <cprintf>
f01058f9:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f01058fc:	83 c7 14             	add    $0x14,%edi
			continue;
f01058ff:	eb 27                	jmp    f0105928 <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0105901:	83 c7 08             	add    $0x8,%edi
			continue;
f0105904:	eb 22                	jmp    f0105928 <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0105906:	83 ec 08             	sub    $0x8,%esp
f0105909:	0f b6 c0             	movzbl %al,%eax
f010590c:	50                   	push   %eax
f010590d:	68 b8 7c 10 f0       	push   $0xf0107cb8
f0105912:	e8 43 df ff ff       	call   f010385a <cprintf>
			ismp = 0;
f0105917:	c7 05 00 10 23 f0 00 	movl   $0x0,0xf0231000
f010591e:	00 00 00 
			i = conf->entry;
f0105921:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f0105925:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105928:	83 c6 01             	add    $0x1,%esi
f010592b:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f010592f:	39 c6                	cmp    %eax,%esi
f0105931:	0f 82 6f ff ff ff    	jb     f01058a6 <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0105937:	a1 e0 13 23 f0       	mov    0xf02313e0,%eax
f010593c:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f0105943:	83 3d 00 10 23 f0 00 	cmpl   $0x0,0xf0231000
f010594a:	75 26                	jne    f0105972 <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f010594c:	c7 05 e4 13 23 f0 01 	movl   $0x1,0xf02313e4
f0105953:	00 00 00 
		lapicaddr = 0;
f0105956:	c7 05 00 20 27 f0 00 	movl   $0x0,0xf0272000
f010595d:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0105960:	83 ec 0c             	sub    $0xc,%esp
f0105963:	68 d8 7c 10 f0       	push   $0xf0107cd8
f0105968:	e8 ed de ff ff       	call   f010385a <cprintf>
		return;
f010596d:	83 c4 10             	add    $0x10,%esp
f0105970:	eb 45                	jmp    f01059b7 <mp_init+0x2e7>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0105972:	83 ec 04             	sub    $0x4,%esp
f0105975:	ff 35 e4 13 23 f0    	pushl  0xf02313e4
f010597b:	0f b6 00             	movzbl (%eax),%eax
f010597e:	50                   	push   %eax
f010597f:	68 5f 7d 10 f0       	push   $0xf0107d5f
f0105984:	e8 d1 de ff ff       	call   f010385a <cprintf>

	if (mp->imcrp) {
f0105989:	83 c4 10             	add    $0x10,%esp
f010598c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010598f:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0105993:	74 22                	je     f01059b7 <mp_init+0x2e7>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0105995:	83 ec 0c             	sub    $0xc,%esp
f0105998:	68 04 7d 10 f0       	push   $0xf0107d04
f010599d:	e8 b8 de ff ff       	call   f010385a <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01059a2:	ba 22 00 00 00       	mov    $0x22,%edx
f01059a7:	b8 70 00 00 00       	mov    $0x70,%eax
f01059ac:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01059ad:	b2 23                	mov    $0x23,%dl
f01059af:	ec                   	in     (%dx),%al
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f01059b0:	83 c8 01             	or     $0x1,%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01059b3:	ee                   	out    %al,(%dx)
f01059b4:	83 c4 10             	add    $0x10,%esp
	}
}
f01059b7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01059ba:	5b                   	pop    %ebx
f01059bb:	5e                   	pop    %esi
f01059bc:	5f                   	pop    %edi
f01059bd:	5d                   	pop    %ebp
f01059be:	c3                   	ret    

f01059bf <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f01059bf:	55                   	push   %ebp
f01059c0:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f01059c2:	8b 0d 04 20 27 f0    	mov    0xf0272004,%ecx
f01059c8:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f01059cb:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f01059cd:	a1 04 20 27 f0       	mov    0xf0272004,%eax
f01059d2:	8b 40 20             	mov    0x20(%eax),%eax
}
f01059d5:	5d                   	pop    %ebp
f01059d6:	c3                   	ret    

f01059d7 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f01059d7:	55                   	push   %ebp
f01059d8:	89 e5                	mov    %esp,%ebp
	if (lapic)
f01059da:	a1 04 20 27 f0       	mov    0xf0272004,%eax
f01059df:	85 c0                	test   %eax,%eax
f01059e1:	74 08                	je     f01059eb <cpunum+0x14>
		return lapic[ID] >> 24;
f01059e3:	8b 40 20             	mov    0x20(%eax),%eax
f01059e6:	c1 e8 18             	shr    $0x18,%eax
f01059e9:	eb 05                	jmp    f01059f0 <cpunum+0x19>
	return 0;
f01059eb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01059f0:	5d                   	pop    %ebp
f01059f1:	c3                   	ret    

f01059f2 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f01059f2:	a1 00 20 27 f0       	mov    0xf0272000,%eax
f01059f7:	85 c0                	test   %eax,%eax
f01059f9:	0f 84 21 01 00 00    	je     f0105b20 <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f01059ff:	55                   	push   %ebp
f0105a00:	89 e5                	mov    %esp,%ebp
f0105a02:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105a05:	68 00 10 00 00       	push   $0x1000
f0105a0a:	50                   	push   %eax
f0105a0b:	e8 71 b9 ff ff       	call   f0101381 <mmio_map_region>
f0105a10:	a3 04 20 27 f0       	mov    %eax,0xf0272004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105a15:	ba 27 01 00 00       	mov    $0x127,%edx
f0105a1a:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0105a1f:	e8 9b ff ff ff       	call   f01059bf <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0105a24:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105a29:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0105a2e:	e8 8c ff ff ff       	call   f01059bf <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0105a33:	ba 20 00 02 00       	mov    $0x20020,%edx
f0105a38:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0105a3d:	e8 7d ff ff ff       	call   f01059bf <lapicw>
	lapicw(TICR, 10000000); 
f0105a42:	ba 80 96 98 00       	mov    $0x989680,%edx
f0105a47:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0105a4c:	e8 6e ff ff ff       	call   f01059bf <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0105a51:	e8 81 ff ff ff       	call   f01059d7 <cpunum>
f0105a56:	6b c0 74             	imul   $0x74,%eax,%eax
f0105a59:	05 40 10 23 f0       	add    $0xf0231040,%eax
f0105a5e:	83 c4 10             	add    $0x10,%esp
f0105a61:	39 05 e0 13 23 f0    	cmp    %eax,0xf02313e0
f0105a67:	74 0f                	je     f0105a78 <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f0105a69:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105a6e:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0105a73:	e8 47 ff ff ff       	call   f01059bf <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f0105a78:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105a7d:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0105a82:	e8 38 ff ff ff       	call   f01059bf <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0105a87:	a1 04 20 27 f0       	mov    0xf0272004,%eax
f0105a8c:	8b 40 30             	mov    0x30(%eax),%eax
f0105a8f:	c1 e8 10             	shr    $0x10,%eax
f0105a92:	3c 03                	cmp    $0x3,%al
f0105a94:	76 0f                	jbe    f0105aa5 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f0105a96:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105a9b:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0105aa0:	e8 1a ff ff ff       	call   f01059bf <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0105aa5:	ba 33 00 00 00       	mov    $0x33,%edx
f0105aaa:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0105aaf:	e8 0b ff ff ff       	call   f01059bf <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f0105ab4:	ba 00 00 00 00       	mov    $0x0,%edx
f0105ab9:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105abe:	e8 fc fe ff ff       	call   f01059bf <lapicw>
	lapicw(ESR, 0);
f0105ac3:	ba 00 00 00 00       	mov    $0x0,%edx
f0105ac8:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105acd:	e8 ed fe ff ff       	call   f01059bf <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0105ad2:	ba 00 00 00 00       	mov    $0x0,%edx
f0105ad7:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105adc:	e8 de fe ff ff       	call   f01059bf <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105ae1:	ba 00 00 00 00       	mov    $0x0,%edx
f0105ae6:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105aeb:	e8 cf fe ff ff       	call   f01059bf <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105af0:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105af5:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105afa:	e8 c0 fe ff ff       	call   f01059bf <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0105aff:	8b 15 04 20 27 f0    	mov    0xf0272004,%edx
f0105b05:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105b0b:	f6 c4 10             	test   $0x10,%ah
f0105b0e:	75 f5                	jne    f0105b05 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0105b10:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b15:	b8 20 00 00 00       	mov    $0x20,%eax
f0105b1a:	e8 a0 fe ff ff       	call   f01059bf <lapicw>
}
f0105b1f:	c9                   	leave  
f0105b20:	f3 c3                	repz ret 

f0105b22 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105b22:	83 3d 04 20 27 f0 00 	cmpl   $0x0,0xf0272004
f0105b29:	74 13                	je     f0105b3e <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f0105b2b:	55                   	push   %ebp
f0105b2c:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0105b2e:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b33:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105b38:	e8 82 fe ff ff       	call   f01059bf <lapicw>
}
f0105b3d:	5d                   	pop    %ebp
f0105b3e:	f3 c3                	repz ret 

f0105b40 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0105b40:	55                   	push   %ebp
f0105b41:	89 e5                	mov    %esp,%ebp
f0105b43:	56                   	push   %esi
f0105b44:	53                   	push   %ebx
f0105b45:	8b 75 08             	mov    0x8(%ebp),%esi
f0105b48:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105b4b:	ba 70 00 00 00       	mov    $0x70,%edx
f0105b50:	b8 0f 00 00 00       	mov    $0xf,%eax
f0105b55:	ee                   	out    %al,(%dx)
f0105b56:	b2 71                	mov    $0x71,%dl
f0105b58:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105b5d:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105b5e:	83 3d c8 0e 23 f0 00 	cmpl   $0x0,0xf0230ec8
f0105b65:	75 19                	jne    f0105b80 <lapic_startap+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105b67:	68 67 04 00 00       	push   $0x467
f0105b6c:	68 a4 60 10 f0       	push   $0xf01060a4
f0105b71:	68 98 00 00 00       	push   $0x98
f0105b76:	68 7c 7d 10 f0       	push   $0xf0107d7c
f0105b7b:	e8 c0 a4 ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0105b80:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0105b87:	00 00 
	wrv[1] = addr >> 4;
f0105b89:	89 d8                	mov    %ebx,%eax
f0105b8b:	c1 e8 04             	shr    $0x4,%eax
f0105b8e:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0105b94:	c1 e6 18             	shl    $0x18,%esi
f0105b97:	89 f2                	mov    %esi,%edx
f0105b99:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105b9e:	e8 1c fe ff ff       	call   f01059bf <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0105ba3:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0105ba8:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105bad:	e8 0d fe ff ff       	call   f01059bf <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0105bb2:	ba 00 85 00 00       	mov    $0x8500,%edx
f0105bb7:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105bbc:	e8 fe fd ff ff       	call   f01059bf <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105bc1:	c1 eb 0c             	shr    $0xc,%ebx
f0105bc4:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105bc7:	89 f2                	mov    %esi,%edx
f0105bc9:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105bce:	e8 ec fd ff ff       	call   f01059bf <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105bd3:	89 da                	mov    %ebx,%edx
f0105bd5:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105bda:	e8 e0 fd ff ff       	call   f01059bf <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105bdf:	89 f2                	mov    %esi,%edx
f0105be1:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105be6:	e8 d4 fd ff ff       	call   f01059bf <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105beb:	89 da                	mov    %ebx,%edx
f0105bed:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105bf2:	e8 c8 fd ff ff       	call   f01059bf <lapicw>
		microdelay(200);
	}
}
f0105bf7:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105bfa:	5b                   	pop    %ebx
f0105bfb:	5e                   	pop    %esi
f0105bfc:	5d                   	pop    %ebp
f0105bfd:	c3                   	ret    

f0105bfe <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105bfe:	55                   	push   %ebp
f0105bff:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105c01:	8b 55 08             	mov    0x8(%ebp),%edx
f0105c04:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0105c0a:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c0f:	e8 ab fd ff ff       	call   f01059bf <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0105c14:	8b 15 04 20 27 f0    	mov    0xf0272004,%edx
f0105c1a:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105c20:	f6 c4 10             	test   $0x10,%ah
f0105c23:	75 f5                	jne    f0105c1a <lapic_ipi+0x1c>
		;
}
f0105c25:	5d                   	pop    %ebp
f0105c26:	c3                   	ret    

f0105c27 <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0105c27:	55                   	push   %ebp
f0105c28:	89 e5                	mov    %esp,%ebp
f0105c2a:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0105c2d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105c33:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105c36:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f0105c39:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0105c40:	5d                   	pop    %ebp
f0105c41:	c3                   	ret    

f0105c42 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0105c42:	55                   	push   %ebp
f0105c43:	89 e5                	mov    %esp,%ebp
f0105c45:	56                   	push   %esi
f0105c46:	53                   	push   %ebx
f0105c47:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105c4a:	83 3b 00             	cmpl   $0x0,(%ebx)
f0105c4d:	74 14                	je     f0105c63 <spin_lock+0x21>
f0105c4f:	8b 73 08             	mov    0x8(%ebx),%esi
f0105c52:	e8 80 fd ff ff       	call   f01059d7 <cpunum>
f0105c57:	6b c0 74             	imul   $0x74,%eax,%eax
f0105c5a:	05 40 10 23 f0       	add    $0xf0231040,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0105c5f:	39 c6                	cmp    %eax,%esi
f0105c61:	74 07                	je     f0105c6a <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0105c63:	ba 01 00 00 00       	mov    $0x1,%edx
f0105c68:	eb 20                	jmp    f0105c8a <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0105c6a:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0105c6d:	e8 65 fd ff ff       	call   f01059d7 <cpunum>
f0105c72:	83 ec 0c             	sub    $0xc,%esp
f0105c75:	53                   	push   %ebx
f0105c76:	50                   	push   %eax
f0105c77:	68 8c 7d 10 f0       	push   $0xf0107d8c
f0105c7c:	6a 41                	push   $0x41
f0105c7e:	68 f0 7d 10 f0       	push   $0xf0107df0
f0105c83:	e8 b8 a3 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0105c88:	f3 90                	pause  
f0105c8a:	89 d0                	mov    %edx,%eax
f0105c8c:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0105c8f:	85 c0                	test   %eax,%eax
f0105c91:	75 f5                	jne    f0105c88 <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0105c93:	e8 3f fd ff ff       	call   f01059d7 <cpunum>
f0105c98:	6b c0 74             	imul   $0x74,%eax,%eax
f0105c9b:	05 40 10 23 f0       	add    $0xf0231040,%eax
f0105ca0:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0105ca3:	83 c3 0c             	add    $0xc,%ebx
get_caller_pcs(uint32_t pcs[])
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
f0105ca6:	89 ea                	mov    %ebp,%edx
	for (i = 0; i < 10; i++){
f0105ca8:	b8 00 00 00 00       	mov    $0x0,%eax
f0105cad:	eb 0b                	jmp    f0105cba <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f0105caf:	8b 4a 04             	mov    0x4(%edx),%ecx
f0105cb2:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0105cb5:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105cb7:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105cba:	83 f8 09             	cmp    $0x9,%eax
f0105cbd:	7f 14                	jg     f0105cd3 <spin_lock+0x91>
f0105cbf:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0105cc5:	77 e8                	ja     f0105caf <spin_lock+0x6d>
f0105cc7:	eb 0a                	jmp    f0105cd3 <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0105cc9:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0105cd0:	83 c0 01             	add    $0x1,%eax
f0105cd3:	83 f8 09             	cmp    $0x9,%eax
f0105cd6:	7e f1                	jle    f0105cc9 <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f0105cd8:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105cdb:	5b                   	pop    %ebx
f0105cdc:	5e                   	pop    %esi
f0105cdd:	5d                   	pop    %ebp
f0105cde:	c3                   	ret    

f0105cdf <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105cdf:	55                   	push   %ebp
f0105ce0:	89 e5                	mov    %esp,%ebp
f0105ce2:	57                   	push   %edi
f0105ce3:	56                   	push   %esi
f0105ce4:	53                   	push   %ebx
f0105ce5:	83 ec 4c             	sub    $0x4c,%esp
f0105ce8:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105ceb:	83 3e 00             	cmpl   $0x0,(%esi)
f0105cee:	74 18                	je     f0105d08 <spin_unlock+0x29>
f0105cf0:	8b 5e 08             	mov    0x8(%esi),%ebx
f0105cf3:	e8 df fc ff ff       	call   f01059d7 <cpunum>
f0105cf8:	6b c0 74             	imul   $0x74,%eax,%eax
f0105cfb:	05 40 10 23 f0       	add    $0xf0231040,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0105d00:	39 c3                	cmp    %eax,%ebx
f0105d02:	0f 84 a5 00 00 00    	je     f0105dad <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0105d08:	83 ec 04             	sub    $0x4,%esp
f0105d0b:	6a 28                	push   $0x28
f0105d0d:	8d 46 0c             	lea    0xc(%esi),%eax
f0105d10:	50                   	push   %eax
f0105d11:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0105d14:	53                   	push   %ebx
f0105d15:	e8 e5 f6 ff ff       	call   f01053ff <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105d1a:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105d1d:	0f b6 38             	movzbl (%eax),%edi
f0105d20:	8b 76 04             	mov    0x4(%esi),%esi
f0105d23:	e8 af fc ff ff       	call   f01059d7 <cpunum>
f0105d28:	57                   	push   %edi
f0105d29:	56                   	push   %esi
f0105d2a:	50                   	push   %eax
f0105d2b:	68 b8 7d 10 f0       	push   $0xf0107db8
f0105d30:	e8 25 db ff ff       	call   f010385a <cprintf>
f0105d35:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0105d38:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0105d3b:	eb 54                	jmp    f0105d91 <spin_unlock+0xb2>
f0105d3d:	83 ec 08             	sub    $0x8,%esp
f0105d40:	57                   	push   %edi
f0105d41:	50                   	push   %eax
f0105d42:	e8 ed eb ff ff       	call   f0104934 <debuginfo_eip>
f0105d47:	83 c4 10             	add    $0x10,%esp
f0105d4a:	85 c0                	test   %eax,%eax
f0105d4c:	78 27                	js     f0105d75 <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0105d4e:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0105d50:	83 ec 04             	sub    $0x4,%esp
f0105d53:	89 c2                	mov    %eax,%edx
f0105d55:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0105d58:	52                   	push   %edx
f0105d59:	ff 75 b0             	pushl  -0x50(%ebp)
f0105d5c:	ff 75 b4             	pushl  -0x4c(%ebp)
f0105d5f:	ff 75 ac             	pushl  -0x54(%ebp)
f0105d62:	ff 75 a8             	pushl  -0x58(%ebp)
f0105d65:	50                   	push   %eax
f0105d66:	68 00 7e 10 f0       	push   $0xf0107e00
f0105d6b:	e8 ea da ff ff       	call   f010385a <cprintf>
f0105d70:	83 c4 20             	add    $0x20,%esp
f0105d73:	eb 12                	jmp    f0105d87 <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f0105d75:	83 ec 08             	sub    $0x8,%esp
f0105d78:	ff 36                	pushl  (%esi)
f0105d7a:	68 17 7e 10 f0       	push   $0xf0107e17
f0105d7f:	e8 d6 da ff ff       	call   f010385a <cprintf>
f0105d84:	83 c4 10             	add    $0x10,%esp
f0105d87:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0105d8a:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0105d8d:	39 c3                	cmp    %eax,%ebx
f0105d8f:	74 08                	je     f0105d99 <spin_unlock+0xba>
f0105d91:	89 de                	mov    %ebx,%esi
f0105d93:	8b 03                	mov    (%ebx),%eax
f0105d95:	85 c0                	test   %eax,%eax
f0105d97:	75 a4                	jne    f0105d3d <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f0105d99:	83 ec 04             	sub    $0x4,%esp
f0105d9c:	68 1f 7e 10 f0       	push   $0xf0107e1f
f0105da1:	6a 67                	push   $0x67
f0105da3:	68 f0 7d 10 f0       	push   $0xf0107df0
f0105da8:	e8 93 a2 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f0105dad:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0105db4:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
f0105dbb:	b8 00 00 00 00       	mov    $0x0,%eax
f0105dc0:	f0 87 06             	lock xchg %eax,(%esi)
	// Paper says that Intel 64 and IA-32 will not move a load
	// after a store. So lock->locked = 0 would work here.
	// The xchg being asm volatile ensures gcc emits it after
	// the above assignments (and after the critical section).
	xchg(&lk->locked, 0);
}
f0105dc3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105dc6:	5b                   	pop    %ebx
f0105dc7:	5e                   	pop    %esi
f0105dc8:	5f                   	pop    %edi
f0105dc9:	5d                   	pop    %ebp
f0105dca:	c3                   	ret    
f0105dcb:	66 90                	xchg   %ax,%ax
f0105dcd:	66 90                	xchg   %ax,%ax
f0105dcf:	90                   	nop

f0105dd0 <__udivdi3>:
f0105dd0:	55                   	push   %ebp
f0105dd1:	57                   	push   %edi
f0105dd2:	56                   	push   %esi
f0105dd3:	83 ec 10             	sub    $0x10,%esp
f0105dd6:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f0105dda:	8b 7c 24 20          	mov    0x20(%esp),%edi
f0105dde:	8b 74 24 24          	mov    0x24(%esp),%esi
f0105de2:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0105de6:	85 d2                	test   %edx,%edx
f0105de8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105dec:	89 34 24             	mov    %esi,(%esp)
f0105def:	89 c8                	mov    %ecx,%eax
f0105df1:	75 35                	jne    f0105e28 <__udivdi3+0x58>
f0105df3:	39 f1                	cmp    %esi,%ecx
f0105df5:	0f 87 bd 00 00 00    	ja     f0105eb8 <__udivdi3+0xe8>
f0105dfb:	85 c9                	test   %ecx,%ecx
f0105dfd:	89 cd                	mov    %ecx,%ebp
f0105dff:	75 0b                	jne    f0105e0c <__udivdi3+0x3c>
f0105e01:	b8 01 00 00 00       	mov    $0x1,%eax
f0105e06:	31 d2                	xor    %edx,%edx
f0105e08:	f7 f1                	div    %ecx
f0105e0a:	89 c5                	mov    %eax,%ebp
f0105e0c:	89 f0                	mov    %esi,%eax
f0105e0e:	31 d2                	xor    %edx,%edx
f0105e10:	f7 f5                	div    %ebp
f0105e12:	89 c6                	mov    %eax,%esi
f0105e14:	89 f8                	mov    %edi,%eax
f0105e16:	f7 f5                	div    %ebp
f0105e18:	89 f2                	mov    %esi,%edx
f0105e1a:	83 c4 10             	add    $0x10,%esp
f0105e1d:	5e                   	pop    %esi
f0105e1e:	5f                   	pop    %edi
f0105e1f:	5d                   	pop    %ebp
f0105e20:	c3                   	ret    
f0105e21:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105e28:	3b 14 24             	cmp    (%esp),%edx
f0105e2b:	77 7b                	ja     f0105ea8 <__udivdi3+0xd8>
f0105e2d:	0f bd f2             	bsr    %edx,%esi
f0105e30:	83 f6 1f             	xor    $0x1f,%esi
f0105e33:	0f 84 97 00 00 00    	je     f0105ed0 <__udivdi3+0x100>
f0105e39:	bd 20 00 00 00       	mov    $0x20,%ebp
f0105e3e:	89 d7                	mov    %edx,%edi
f0105e40:	89 f1                	mov    %esi,%ecx
f0105e42:	29 f5                	sub    %esi,%ebp
f0105e44:	d3 e7                	shl    %cl,%edi
f0105e46:	89 c2                	mov    %eax,%edx
f0105e48:	89 e9                	mov    %ebp,%ecx
f0105e4a:	d3 ea                	shr    %cl,%edx
f0105e4c:	89 f1                	mov    %esi,%ecx
f0105e4e:	09 fa                	or     %edi,%edx
f0105e50:	8b 3c 24             	mov    (%esp),%edi
f0105e53:	d3 e0                	shl    %cl,%eax
f0105e55:	89 54 24 08          	mov    %edx,0x8(%esp)
f0105e59:	89 e9                	mov    %ebp,%ecx
f0105e5b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105e5f:	8b 44 24 04          	mov    0x4(%esp),%eax
f0105e63:	89 fa                	mov    %edi,%edx
f0105e65:	d3 ea                	shr    %cl,%edx
f0105e67:	89 f1                	mov    %esi,%ecx
f0105e69:	d3 e7                	shl    %cl,%edi
f0105e6b:	89 e9                	mov    %ebp,%ecx
f0105e6d:	d3 e8                	shr    %cl,%eax
f0105e6f:	09 c7                	or     %eax,%edi
f0105e71:	89 f8                	mov    %edi,%eax
f0105e73:	f7 74 24 08          	divl   0x8(%esp)
f0105e77:	89 d5                	mov    %edx,%ebp
f0105e79:	89 c7                	mov    %eax,%edi
f0105e7b:	f7 64 24 0c          	mull   0xc(%esp)
f0105e7f:	39 d5                	cmp    %edx,%ebp
f0105e81:	89 14 24             	mov    %edx,(%esp)
f0105e84:	72 11                	jb     f0105e97 <__udivdi3+0xc7>
f0105e86:	8b 54 24 04          	mov    0x4(%esp),%edx
f0105e8a:	89 f1                	mov    %esi,%ecx
f0105e8c:	d3 e2                	shl    %cl,%edx
f0105e8e:	39 c2                	cmp    %eax,%edx
f0105e90:	73 5e                	jae    f0105ef0 <__udivdi3+0x120>
f0105e92:	3b 2c 24             	cmp    (%esp),%ebp
f0105e95:	75 59                	jne    f0105ef0 <__udivdi3+0x120>
f0105e97:	8d 47 ff             	lea    -0x1(%edi),%eax
f0105e9a:	31 f6                	xor    %esi,%esi
f0105e9c:	89 f2                	mov    %esi,%edx
f0105e9e:	83 c4 10             	add    $0x10,%esp
f0105ea1:	5e                   	pop    %esi
f0105ea2:	5f                   	pop    %edi
f0105ea3:	5d                   	pop    %ebp
f0105ea4:	c3                   	ret    
f0105ea5:	8d 76 00             	lea    0x0(%esi),%esi
f0105ea8:	31 f6                	xor    %esi,%esi
f0105eaa:	31 c0                	xor    %eax,%eax
f0105eac:	89 f2                	mov    %esi,%edx
f0105eae:	83 c4 10             	add    $0x10,%esp
f0105eb1:	5e                   	pop    %esi
f0105eb2:	5f                   	pop    %edi
f0105eb3:	5d                   	pop    %ebp
f0105eb4:	c3                   	ret    
f0105eb5:	8d 76 00             	lea    0x0(%esi),%esi
f0105eb8:	89 f2                	mov    %esi,%edx
f0105eba:	31 f6                	xor    %esi,%esi
f0105ebc:	89 f8                	mov    %edi,%eax
f0105ebe:	f7 f1                	div    %ecx
f0105ec0:	89 f2                	mov    %esi,%edx
f0105ec2:	83 c4 10             	add    $0x10,%esp
f0105ec5:	5e                   	pop    %esi
f0105ec6:	5f                   	pop    %edi
f0105ec7:	5d                   	pop    %ebp
f0105ec8:	c3                   	ret    
f0105ec9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105ed0:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f0105ed4:	76 0b                	jbe    f0105ee1 <__udivdi3+0x111>
f0105ed6:	31 c0                	xor    %eax,%eax
f0105ed8:	3b 14 24             	cmp    (%esp),%edx
f0105edb:	0f 83 37 ff ff ff    	jae    f0105e18 <__udivdi3+0x48>
f0105ee1:	b8 01 00 00 00       	mov    $0x1,%eax
f0105ee6:	e9 2d ff ff ff       	jmp    f0105e18 <__udivdi3+0x48>
f0105eeb:	90                   	nop
f0105eec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105ef0:	89 f8                	mov    %edi,%eax
f0105ef2:	31 f6                	xor    %esi,%esi
f0105ef4:	e9 1f ff ff ff       	jmp    f0105e18 <__udivdi3+0x48>
f0105ef9:	66 90                	xchg   %ax,%ax
f0105efb:	66 90                	xchg   %ax,%ax
f0105efd:	66 90                	xchg   %ax,%ax
f0105eff:	90                   	nop

f0105f00 <__umoddi3>:
f0105f00:	55                   	push   %ebp
f0105f01:	57                   	push   %edi
f0105f02:	56                   	push   %esi
f0105f03:	83 ec 20             	sub    $0x20,%esp
f0105f06:	8b 44 24 34          	mov    0x34(%esp),%eax
f0105f0a:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0105f0e:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105f12:	89 c6                	mov    %eax,%esi
f0105f14:	89 44 24 10          	mov    %eax,0x10(%esp)
f0105f18:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0105f1c:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0105f20:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0105f24:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0105f28:	89 74 24 18          	mov    %esi,0x18(%esp)
f0105f2c:	85 c0                	test   %eax,%eax
f0105f2e:	89 c2                	mov    %eax,%edx
f0105f30:	75 1e                	jne    f0105f50 <__umoddi3+0x50>
f0105f32:	39 f7                	cmp    %esi,%edi
f0105f34:	76 52                	jbe    f0105f88 <__umoddi3+0x88>
f0105f36:	89 c8                	mov    %ecx,%eax
f0105f38:	89 f2                	mov    %esi,%edx
f0105f3a:	f7 f7                	div    %edi
f0105f3c:	89 d0                	mov    %edx,%eax
f0105f3e:	31 d2                	xor    %edx,%edx
f0105f40:	83 c4 20             	add    $0x20,%esp
f0105f43:	5e                   	pop    %esi
f0105f44:	5f                   	pop    %edi
f0105f45:	5d                   	pop    %ebp
f0105f46:	c3                   	ret    
f0105f47:	89 f6                	mov    %esi,%esi
f0105f49:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0105f50:	39 f0                	cmp    %esi,%eax
f0105f52:	77 5c                	ja     f0105fb0 <__umoddi3+0xb0>
f0105f54:	0f bd e8             	bsr    %eax,%ebp
f0105f57:	83 f5 1f             	xor    $0x1f,%ebp
f0105f5a:	75 64                	jne    f0105fc0 <__umoddi3+0xc0>
f0105f5c:	8b 6c 24 14          	mov    0x14(%esp),%ebp
f0105f60:	39 6c 24 0c          	cmp    %ebp,0xc(%esp)
f0105f64:	0f 86 f6 00 00 00    	jbe    f0106060 <__umoddi3+0x160>
f0105f6a:	3b 44 24 18          	cmp    0x18(%esp),%eax
f0105f6e:	0f 82 ec 00 00 00    	jb     f0106060 <__umoddi3+0x160>
f0105f74:	8b 44 24 14          	mov    0x14(%esp),%eax
f0105f78:	8b 54 24 18          	mov    0x18(%esp),%edx
f0105f7c:	83 c4 20             	add    $0x20,%esp
f0105f7f:	5e                   	pop    %esi
f0105f80:	5f                   	pop    %edi
f0105f81:	5d                   	pop    %ebp
f0105f82:	c3                   	ret    
f0105f83:	90                   	nop
f0105f84:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105f88:	85 ff                	test   %edi,%edi
f0105f8a:	89 fd                	mov    %edi,%ebp
f0105f8c:	75 0b                	jne    f0105f99 <__umoddi3+0x99>
f0105f8e:	b8 01 00 00 00       	mov    $0x1,%eax
f0105f93:	31 d2                	xor    %edx,%edx
f0105f95:	f7 f7                	div    %edi
f0105f97:	89 c5                	mov    %eax,%ebp
f0105f99:	8b 44 24 10          	mov    0x10(%esp),%eax
f0105f9d:	31 d2                	xor    %edx,%edx
f0105f9f:	f7 f5                	div    %ebp
f0105fa1:	89 c8                	mov    %ecx,%eax
f0105fa3:	f7 f5                	div    %ebp
f0105fa5:	eb 95                	jmp    f0105f3c <__umoddi3+0x3c>
f0105fa7:	89 f6                	mov    %esi,%esi
f0105fa9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0105fb0:	89 c8                	mov    %ecx,%eax
f0105fb2:	89 f2                	mov    %esi,%edx
f0105fb4:	83 c4 20             	add    $0x20,%esp
f0105fb7:	5e                   	pop    %esi
f0105fb8:	5f                   	pop    %edi
f0105fb9:	5d                   	pop    %ebp
f0105fba:	c3                   	ret    
f0105fbb:	90                   	nop
f0105fbc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105fc0:	b8 20 00 00 00       	mov    $0x20,%eax
f0105fc5:	89 e9                	mov    %ebp,%ecx
f0105fc7:	29 e8                	sub    %ebp,%eax
f0105fc9:	d3 e2                	shl    %cl,%edx
f0105fcb:	89 c7                	mov    %eax,%edi
f0105fcd:	89 44 24 18          	mov    %eax,0x18(%esp)
f0105fd1:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0105fd5:	89 f9                	mov    %edi,%ecx
f0105fd7:	d3 e8                	shr    %cl,%eax
f0105fd9:	89 c1                	mov    %eax,%ecx
f0105fdb:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0105fdf:	09 d1                	or     %edx,%ecx
f0105fe1:	89 fa                	mov    %edi,%edx
f0105fe3:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0105fe7:	89 e9                	mov    %ebp,%ecx
f0105fe9:	d3 e0                	shl    %cl,%eax
f0105feb:	89 f9                	mov    %edi,%ecx
f0105fed:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105ff1:	89 f0                	mov    %esi,%eax
f0105ff3:	d3 e8                	shr    %cl,%eax
f0105ff5:	89 e9                	mov    %ebp,%ecx
f0105ff7:	89 c7                	mov    %eax,%edi
f0105ff9:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0105ffd:	d3 e6                	shl    %cl,%esi
f0105fff:	89 d1                	mov    %edx,%ecx
f0106001:	89 fa                	mov    %edi,%edx
f0106003:	d3 e8                	shr    %cl,%eax
f0106005:	89 e9                	mov    %ebp,%ecx
f0106007:	09 f0                	or     %esi,%eax
f0106009:	8b 74 24 1c          	mov    0x1c(%esp),%esi
f010600d:	f7 74 24 10          	divl   0x10(%esp)
f0106011:	d3 e6                	shl    %cl,%esi
f0106013:	89 d1                	mov    %edx,%ecx
f0106015:	f7 64 24 0c          	mull   0xc(%esp)
f0106019:	39 d1                	cmp    %edx,%ecx
f010601b:	89 74 24 14          	mov    %esi,0x14(%esp)
f010601f:	89 d7                	mov    %edx,%edi
f0106021:	89 c6                	mov    %eax,%esi
f0106023:	72 0a                	jb     f010602f <__umoddi3+0x12f>
f0106025:	39 44 24 14          	cmp    %eax,0x14(%esp)
f0106029:	73 10                	jae    f010603b <__umoddi3+0x13b>
f010602b:	39 d1                	cmp    %edx,%ecx
f010602d:	75 0c                	jne    f010603b <__umoddi3+0x13b>
f010602f:	89 d7                	mov    %edx,%edi
f0106031:	89 c6                	mov    %eax,%esi
f0106033:	2b 74 24 0c          	sub    0xc(%esp),%esi
f0106037:	1b 7c 24 10          	sbb    0x10(%esp),%edi
f010603b:	89 ca                	mov    %ecx,%edx
f010603d:	89 e9                	mov    %ebp,%ecx
f010603f:	8b 44 24 14          	mov    0x14(%esp),%eax
f0106043:	29 f0                	sub    %esi,%eax
f0106045:	19 fa                	sbb    %edi,%edx
f0106047:	d3 e8                	shr    %cl,%eax
f0106049:	0f b6 4c 24 18       	movzbl 0x18(%esp),%ecx
f010604e:	89 d7                	mov    %edx,%edi
f0106050:	d3 e7                	shl    %cl,%edi
f0106052:	89 e9                	mov    %ebp,%ecx
f0106054:	09 f8                	or     %edi,%eax
f0106056:	d3 ea                	shr    %cl,%edx
f0106058:	83 c4 20             	add    $0x20,%esp
f010605b:	5e                   	pop    %esi
f010605c:	5f                   	pop    %edi
f010605d:	5d                   	pop    %ebp
f010605e:	c3                   	ret    
f010605f:	90                   	nop
f0106060:	8b 74 24 10          	mov    0x10(%esp),%esi
f0106064:	29 f9                	sub    %edi,%ecx
f0106066:	19 c6                	sbb    %eax,%esi
f0106068:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f010606c:	89 74 24 18          	mov    %esi,0x18(%esp)
f0106070:	e9 ff fe ff ff       	jmp    f0105f74 <__umoddi3+0x74>
