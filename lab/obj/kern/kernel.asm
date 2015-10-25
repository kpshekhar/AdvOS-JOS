
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
f0100048:	83 3d 80 be 22 f0 00 	cmpl   $0x0,0xf022be80
f010004f:	75 3a                	jne    f010008b <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f0100051:	89 35 80 be 22 f0    	mov    %esi,0xf022be80

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100057:	fa                   	cli    
f0100058:	fc                   	cld    

	va_start(ap, fmt);
f0100059:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005c:	e8 68 5f 00 00       	call   f0105fc9 <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 c0 66 10 f0       	push   $0xf01066c0
f010006d:	e8 4a 40 00 00       	call   f01040bc <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 0d 40 00 00       	call   f0104089 <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 32 7f 10 f0 	movl   $0xf0107f32,(%esp)
f0100083:	e8 34 40 00 00       	call   f01040bc <cprintf>
	va_end(ap);
f0100088:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010008b:	83 ec 0c             	sub    $0xc,%esp
f010008e:	6a 00                	push   $0x0
f0100090:	e8 a0 08 00 00       	call   f0100935 <monitor>
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
f01000a1:	b8 08 d0 26 f0       	mov    $0xf026d008,%eax
f01000a6:	2d 07 ad 22 f0       	sub    $0xf022ad07,%eax
f01000ab:	50                   	push   %eax
f01000ac:	6a 00                	push   $0x0
f01000ae:	68 07 ad 22 f0       	push   $0xf022ad07
f01000b3:	e8 bf 58 00 00       	call   f0105977 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 72 05 00 00       	call   f010062f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 2c 67 10 f0       	push   $0xf010672c
f01000ca:	e8 ed 3f 00 00       	call   f01040bc <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 b1 14 00 00       	call   f0101585 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 8a 37 00 00       	call   f0103863 <env_init>
	trap_init();
f01000d9:	e8 96 40 00 00       	call   f0104174 <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 d7 5b 00 00       	call   f0105cba <mp_init>
	lapic_init();
f01000e3:	e8 fc 5e 00 00       	call   f0105fe4 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 ff 3e 00 00       	call   f0103fec <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000ed:	c7 04 24 80 04 12 f0 	movl   $0xf0120480,(%esp)
f01000f4:	e8 4e 61 00 00       	call   f0106247 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000f9:	83 c4 10             	add    $0x10,%esp
f01000fc:	83 3d 88 be 22 f0 07 	cmpl   $0x7,0xf022be88
f0100103:	77 16                	ja     f010011b <i386_init+0x81>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100105:	68 00 70 00 00       	push   $0x7000
f010010a:	68 e4 66 10 f0       	push   $0xf01066e4
f010010f:	6a 59                	push   $0x59
f0100111:	68 47 67 10 f0       	push   $0xf0106747
f0100116:	e8 25 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010011b:	83 ec 04             	sub    $0x4,%esp
f010011e:	b8 f2 5b 10 f0       	mov    $0xf0105bf2,%eax
f0100123:	2d 78 5b 10 f0       	sub    $0xf0105b78,%eax
f0100128:	50                   	push   %eax
f0100129:	68 78 5b 10 f0       	push   $0xf0105b78
f010012e:	68 00 70 00 f0       	push   $0xf0007000
f0100133:	e8 8c 58 00 00       	call   f01059c4 <memmove>
f0100138:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010013b:	bb 20 c0 22 f0       	mov    $0xf022c020,%ebx
f0100140:	eb 4e                	jmp    f0100190 <i386_init+0xf6>
		if (c == cpus + cpunum())  // We've started already.
f0100142:	e8 82 5e 00 00       	call   f0105fc9 <cpunum>
f0100147:	6b c0 74             	imul   $0x74,%eax,%eax
f010014a:	05 20 c0 22 f0       	add    $0xf022c020,%eax
f010014f:	39 c3                	cmp    %eax,%ebx
f0100151:	74 3a                	je     f010018d <i386_init+0xf3>
f0100153:	89 d8                	mov    %ebx,%eax
f0100155:	2d 20 c0 22 f0       	sub    $0xf022c020,%eax
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f010015a:	c1 f8 02             	sar    $0x2,%eax
f010015d:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100163:	c1 e0 0f             	shl    $0xf,%eax
f0100166:	8d 80 00 50 23 f0    	lea    -0xfdcb000(%eax),%eax
f010016c:	a3 84 be 22 f0       	mov    %eax,0xf022be84
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100171:	83 ec 08             	sub    $0x8,%esp
f0100174:	68 00 70 00 00       	push   $0x7000
f0100179:	0f b6 03             	movzbl (%ebx),%eax
f010017c:	50                   	push   %eax
f010017d:	e8 b2 5f 00 00       	call   f0106134 <lapic_startap>
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
f0100190:	6b 05 c4 c3 22 f0 74 	imul   $0x74,0xf022c3c4,%eax
f0100197:	05 20 c0 22 f0       	add    $0xf022c020,%eax
f010019c:	39 c3                	cmp    %eax,%ebx
f010019e:	72 a2                	jb     f0100142 <i386_init+0xa8>
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	//ENV_CREATE(user_primes, ENV_TYPE_USER);
	ENV_CREATE(user_dumbfork, ENV_TYPE_USER);
f01001a0:	83 ec 08             	sub    $0x8,%esp
f01001a3:	6a 00                	push   $0x0
f01001a5:	68 9d 10 1a f0       	push   $0xf01a109d
f01001aa:	e8 a7 38 00 00       	call   f0103a56 <env_create>

	//ENV_CREATE(user_yield, ENV_TYPE_USER);
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001af:	e8 02 47 00 00       	call   f01048b6 <sched_yield>

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
f01001ba:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001bf:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001c4:	77 12                	ja     f01001d8 <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001c6:	50                   	push   %eax
f01001c7:	68 08 67 10 f0       	push   $0xf0106708
f01001cc:	6a 70                	push   $0x70
f01001ce:	68 47 67 10 f0       	push   $0xf0106747
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
f01001e0:	e8 e4 5d 00 00       	call   f0105fc9 <cpunum>
f01001e5:	83 ec 08             	sub    $0x8,%esp
f01001e8:	50                   	push   %eax
f01001e9:	68 53 67 10 f0       	push   $0xf0106753
f01001ee:	e8 c9 3e 00 00       	call   f01040bc <cprintf>

	lapic_init();
f01001f3:	e8 ec 5d 00 00       	call   f0105fe4 <lapic_init>
	env_init_percpu();
f01001f8:	e8 3c 36 00 00       	call   f0103839 <env_init_percpu>
	trap_init_percpu();
f01001fd:	e8 de 3e 00 00       	call   f01040e0 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100202:	e8 c2 5d 00 00       	call   f0105fc9 <cpunum>
f0100207:	6b d0 74             	imul   $0x74,%eax,%edx
f010020a:	81 c2 20 c0 22 f0    	add    $0xf022c020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0100210:	b8 01 00 00 00       	mov    $0x1,%eax
f0100215:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0100219:	c7 04 24 80 04 12 f0 	movl   $0xf0120480,(%esp)
f0100220:	e8 22 60 00 00       	call   f0106247 <spin_lock>
	// to start running processes on this CPU.  But make sure that
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	lock_kernel();  //Acquire the lock
	sched_yield(); //Call the sched_yield() function to schedule and run different environments, Exercise 6
f0100225:	e8 8c 46 00 00       	call   f01048b6 <sched_yield>

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
f010023a:	68 69 67 10 f0       	push   $0xf0106769
f010023f:	e8 78 3e 00 00       	call   f01040bc <cprintf>
	vcprintf(fmt, ap);
f0100244:	83 c4 08             	add    $0x8,%esp
f0100247:	53                   	push   %ebx
f0100248:	ff 75 10             	pushl  0x10(%ebp)
f010024b:	e8 39 3e 00 00       	call   f0104089 <vcprintf>
	cprintf("\n");
f0100250:	c7 04 24 32 7f 10 f0 	movl   $0xf0107f32,(%esp)
f0100257:	e8 60 3e 00 00       	call   f01040bc <cprintf>
	va_end(ap);
f010025c:	83 c4 10             	add    $0x10,%esp
}
f010025f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100262:	c9                   	leave  
f0100263:	c3                   	ret    
f0100264:	66 90                	xchg   %ax,%ax
f0100266:	66 90                	xchg   %ax,%ax
f0100268:	66 90                	xchg   %ax,%ax
f010026a:	66 90                	xchg   %ax,%ax
f010026c:	66 90                	xchg   %ax,%ax
f010026e:	66 90                	xchg   %ax,%ax

f0100270 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100270:	55                   	push   %ebp
f0100271:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100273:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100278:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100279:	a8 01                	test   $0x1,%al
f010027b:	74 08                	je     f0100285 <serial_proc_data+0x15>
f010027d:	b2 f8                	mov    $0xf8,%dl
f010027f:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100280:	0f b6 c0             	movzbl %al,%eax
f0100283:	eb 05                	jmp    f010028a <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100285:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010028a:	5d                   	pop    %ebp
f010028b:	c3                   	ret    

f010028c <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010028c:	55                   	push   %ebp
f010028d:	89 e5                	mov    %esp,%ebp
f010028f:	53                   	push   %ebx
f0100290:	83 ec 04             	sub    $0x4,%esp
f0100293:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100295:	eb 2a                	jmp    f01002c1 <cons_intr+0x35>
		if (c == 0)
f0100297:	85 d2                	test   %edx,%edx
f0100299:	74 26                	je     f01002c1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010029b:	a1 24 b2 22 f0       	mov    0xf022b224,%eax
f01002a0:	8d 48 01             	lea    0x1(%eax),%ecx
f01002a3:	89 0d 24 b2 22 f0    	mov    %ecx,0xf022b224
f01002a9:	88 90 20 b0 22 f0    	mov    %dl,-0xfdd4fe0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01002af:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01002b5:	75 0a                	jne    f01002c1 <cons_intr+0x35>
			cons.wpos = 0;
f01002b7:	c7 05 24 b2 22 f0 00 	movl   $0x0,0xf022b224
f01002be:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002c1:	ff d3                	call   *%ebx
f01002c3:	89 c2                	mov    %eax,%edx
f01002c5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002c8:	75 cd                	jne    f0100297 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01002ca:	83 c4 04             	add    $0x4,%esp
f01002cd:	5b                   	pop    %ebx
f01002ce:	5d                   	pop    %ebp
f01002cf:	c3                   	ret    

f01002d0 <kbd_proc_data>:
f01002d0:	ba 64 00 00 00       	mov    $0x64,%edx
f01002d5:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01002d6:	a8 01                	test   $0x1,%al
f01002d8:	0f 84 ef 00 00 00    	je     f01003cd <kbd_proc_data+0xfd>
f01002de:	b2 60                	mov    $0x60,%dl
f01002e0:	ec                   	in     (%dx),%al
f01002e1:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01002e3:	3c e0                	cmp    $0xe0,%al
f01002e5:	75 0d                	jne    f01002f4 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f01002e7:	83 0d 00 b0 22 f0 40 	orl    $0x40,0xf022b000
		return 0;
f01002ee:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002f3:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01002f4:	55                   	push   %ebp
f01002f5:	89 e5                	mov    %esp,%ebp
f01002f7:	53                   	push   %ebx
f01002f8:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01002fb:	84 c0                	test   %al,%al
f01002fd:	79 37                	jns    f0100336 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01002ff:	8b 0d 00 b0 22 f0    	mov    0xf022b000,%ecx
f0100305:	89 cb                	mov    %ecx,%ebx
f0100307:	83 e3 40             	and    $0x40,%ebx
f010030a:	83 e0 7f             	and    $0x7f,%eax
f010030d:	85 db                	test   %ebx,%ebx
f010030f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100312:	0f b6 d2             	movzbl %dl,%edx
f0100315:	0f b6 82 e0 68 10 f0 	movzbl -0xfef9720(%edx),%eax
f010031c:	83 c8 40             	or     $0x40,%eax
f010031f:	0f b6 c0             	movzbl %al,%eax
f0100322:	f7 d0                	not    %eax
f0100324:	21 c1                	and    %eax,%ecx
f0100326:	89 0d 00 b0 22 f0    	mov    %ecx,0xf022b000
		return 0;
f010032c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100331:	e9 9d 00 00 00       	jmp    f01003d3 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100336:	8b 0d 00 b0 22 f0    	mov    0xf022b000,%ecx
f010033c:	f6 c1 40             	test   $0x40,%cl
f010033f:	74 0e                	je     f010034f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100341:	83 c8 80             	or     $0xffffff80,%eax
f0100344:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100346:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100349:	89 0d 00 b0 22 f0    	mov    %ecx,0xf022b000
	}

	shift |= shiftcode[data];
f010034f:	0f b6 d2             	movzbl %dl,%edx
f0100352:	0f b6 82 e0 68 10 f0 	movzbl -0xfef9720(%edx),%eax
f0100359:	0b 05 00 b0 22 f0    	or     0xf022b000,%eax
	shift ^= togglecode[data];
f010035f:	0f b6 8a e0 67 10 f0 	movzbl -0xfef9820(%edx),%ecx
f0100366:	31 c8                	xor    %ecx,%eax
f0100368:	a3 00 b0 22 f0       	mov    %eax,0xf022b000

	c = charcode[shift & (CTL | SHIFT)][data];
f010036d:	89 c1                	mov    %eax,%ecx
f010036f:	83 e1 03             	and    $0x3,%ecx
f0100372:	8b 0c 8d c0 67 10 f0 	mov    -0xfef9840(,%ecx,4),%ecx
f0100379:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010037d:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100380:	a8 08                	test   $0x8,%al
f0100382:	74 1b                	je     f010039f <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f0100384:	89 da                	mov    %ebx,%edx
f0100386:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100389:	83 f9 19             	cmp    $0x19,%ecx
f010038c:	77 05                	ja     f0100393 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f010038e:	83 eb 20             	sub    $0x20,%ebx
f0100391:	eb 0c                	jmp    f010039f <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f0100393:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100396:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100399:	83 fa 19             	cmp    $0x19,%edx
f010039c:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010039f:	f7 d0                	not    %eax
f01003a1:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003a3:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003a5:	f6 c2 06             	test   $0x6,%dl
f01003a8:	75 29                	jne    f01003d3 <kbd_proc_data+0x103>
f01003aa:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01003b0:	75 21                	jne    f01003d3 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f01003b2:	c7 04 24 83 67 10 f0 	movl   $0xf0106783,(%esp)
f01003b9:	e8 fe 3c 00 00       	call   f01040bc <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003be:	ba 92 00 00 00       	mov    $0x92,%edx
f01003c3:	b8 03 00 00 00       	mov    $0x3,%eax
f01003c8:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003c9:	89 d8                	mov    %ebx,%eax
f01003cb:	eb 06                	jmp    f01003d3 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01003cd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01003d2:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01003d3:	83 c4 14             	add    $0x14,%esp
f01003d6:	5b                   	pop    %ebx
f01003d7:	5d                   	pop    %ebp
f01003d8:	c3                   	ret    

f01003d9 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003d9:	55                   	push   %ebp
f01003da:	89 e5                	mov    %esp,%ebp
f01003dc:	57                   	push   %edi
f01003dd:	56                   	push   %esi
f01003de:	53                   	push   %ebx
f01003df:	83 ec 1c             	sub    $0x1c,%esp
f01003e2:	89 c7                	mov    %eax,%edi
f01003e4:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003e9:	be fd 03 00 00       	mov    $0x3fd,%esi
f01003ee:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003f3:	eb 06                	jmp    f01003fb <cons_putc+0x22>
f01003f5:	89 ca                	mov    %ecx,%edx
f01003f7:	ec                   	in     (%dx),%al
f01003f8:	ec                   	in     (%dx),%al
f01003f9:	ec                   	in     (%dx),%al
f01003fa:	ec                   	in     (%dx),%al
f01003fb:	89 f2                	mov    %esi,%edx
f01003fd:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01003fe:	a8 20                	test   $0x20,%al
f0100400:	75 05                	jne    f0100407 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100402:	83 eb 01             	sub    $0x1,%ebx
f0100405:	75 ee                	jne    f01003f5 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100407:	89 f8                	mov    %edi,%eax
f0100409:	0f b6 c0             	movzbl %al,%eax
f010040c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010040f:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100414:	ee                   	out    %al,(%dx)
f0100415:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010041a:	be 79 03 00 00       	mov    $0x379,%esi
f010041f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100424:	eb 06                	jmp    f010042c <cons_putc+0x53>
f0100426:	89 ca                	mov    %ecx,%edx
f0100428:	ec                   	in     (%dx),%al
f0100429:	ec                   	in     (%dx),%al
f010042a:	ec                   	in     (%dx),%al
f010042b:	ec                   	in     (%dx),%al
f010042c:	89 f2                	mov    %esi,%edx
f010042e:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010042f:	84 c0                	test   %al,%al
f0100431:	78 05                	js     f0100438 <cons_putc+0x5f>
f0100433:	83 eb 01             	sub    $0x1,%ebx
f0100436:	75 ee                	jne    f0100426 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100438:	ba 78 03 00 00       	mov    $0x378,%edx
f010043d:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100441:	ee                   	out    %al,(%dx)
f0100442:	b2 7a                	mov    $0x7a,%dl
f0100444:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100449:	ee                   	out    %al,(%dx)
f010044a:	b8 08 00 00 00       	mov    $0x8,%eax
f010044f:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100450:	89 fa                	mov    %edi,%edx
f0100452:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100458:	89 f8                	mov    %edi,%eax
f010045a:	80 cc 07             	or     $0x7,%ah
f010045d:	85 d2                	test   %edx,%edx
f010045f:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100462:	89 f8                	mov    %edi,%eax
f0100464:	0f b6 c0             	movzbl %al,%eax
f0100467:	83 f8 09             	cmp    $0x9,%eax
f010046a:	74 76                	je     f01004e2 <cons_putc+0x109>
f010046c:	83 f8 09             	cmp    $0x9,%eax
f010046f:	7f 0a                	jg     f010047b <cons_putc+0xa2>
f0100471:	83 f8 08             	cmp    $0x8,%eax
f0100474:	74 16                	je     f010048c <cons_putc+0xb3>
f0100476:	e9 9b 00 00 00       	jmp    f0100516 <cons_putc+0x13d>
f010047b:	83 f8 0a             	cmp    $0xa,%eax
f010047e:	66 90                	xchg   %ax,%ax
f0100480:	74 3a                	je     f01004bc <cons_putc+0xe3>
f0100482:	83 f8 0d             	cmp    $0xd,%eax
f0100485:	74 3d                	je     f01004c4 <cons_putc+0xeb>
f0100487:	e9 8a 00 00 00       	jmp    f0100516 <cons_putc+0x13d>
	case '\b':
		if (crt_pos > 0) {
f010048c:	0f b7 05 28 b2 22 f0 	movzwl 0xf022b228,%eax
f0100493:	66 85 c0             	test   %ax,%ax
f0100496:	0f 84 e5 00 00 00    	je     f0100581 <cons_putc+0x1a8>
			crt_pos--;
f010049c:	83 e8 01             	sub    $0x1,%eax
f010049f:	66 a3 28 b2 22 f0    	mov    %ax,0xf022b228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004a5:	0f b7 c0             	movzwl %ax,%eax
f01004a8:	66 81 e7 00 ff       	and    $0xff00,%di
f01004ad:	83 cf 20             	or     $0x20,%edi
f01004b0:	8b 15 2c b2 22 f0    	mov    0xf022b22c,%edx
f01004b6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004ba:	eb 78                	jmp    f0100534 <cons_putc+0x15b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004bc:	66 83 05 28 b2 22 f0 	addw   $0x50,0xf022b228
f01004c3:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004c4:	0f b7 05 28 b2 22 f0 	movzwl 0xf022b228,%eax
f01004cb:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004d1:	c1 e8 16             	shr    $0x16,%eax
f01004d4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004d7:	c1 e0 04             	shl    $0x4,%eax
f01004da:	66 a3 28 b2 22 f0    	mov    %ax,0xf022b228
f01004e0:	eb 52                	jmp    f0100534 <cons_putc+0x15b>
		break;
	case '\t':
		cons_putc(' ');
f01004e2:	b8 20 00 00 00       	mov    $0x20,%eax
f01004e7:	e8 ed fe ff ff       	call   f01003d9 <cons_putc>
		cons_putc(' ');
f01004ec:	b8 20 00 00 00       	mov    $0x20,%eax
f01004f1:	e8 e3 fe ff ff       	call   f01003d9 <cons_putc>
		cons_putc(' ');
f01004f6:	b8 20 00 00 00       	mov    $0x20,%eax
f01004fb:	e8 d9 fe ff ff       	call   f01003d9 <cons_putc>
		cons_putc(' ');
f0100500:	b8 20 00 00 00       	mov    $0x20,%eax
f0100505:	e8 cf fe ff ff       	call   f01003d9 <cons_putc>
		cons_putc(' ');
f010050a:	b8 20 00 00 00       	mov    $0x20,%eax
f010050f:	e8 c5 fe ff ff       	call   f01003d9 <cons_putc>
f0100514:	eb 1e                	jmp    f0100534 <cons_putc+0x15b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100516:	0f b7 05 28 b2 22 f0 	movzwl 0xf022b228,%eax
f010051d:	8d 50 01             	lea    0x1(%eax),%edx
f0100520:	66 89 15 28 b2 22 f0 	mov    %dx,0xf022b228
f0100527:	0f b7 c0             	movzwl %ax,%eax
f010052a:	8b 15 2c b2 22 f0    	mov    0xf022b22c,%edx
f0100530:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100534:	66 81 3d 28 b2 22 f0 	cmpw   $0x7cf,0xf022b228
f010053b:	cf 07 
f010053d:	76 42                	jbe    f0100581 <cons_putc+0x1a8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010053f:	a1 2c b2 22 f0       	mov    0xf022b22c,%eax
f0100544:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010054b:	00 
f010054c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100552:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100556:	89 04 24             	mov    %eax,(%esp)
f0100559:	e8 66 54 00 00       	call   f01059c4 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010055e:	8b 15 2c b2 22 f0    	mov    0xf022b22c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100564:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100569:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010056f:	83 c0 01             	add    $0x1,%eax
f0100572:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100577:	75 f0                	jne    f0100569 <cons_putc+0x190>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100579:	66 83 2d 28 b2 22 f0 	subw   $0x50,0xf022b228
f0100580:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100581:	8b 0d 30 b2 22 f0    	mov    0xf022b230,%ecx
f0100587:	b8 0e 00 00 00       	mov    $0xe,%eax
f010058c:	89 ca                	mov    %ecx,%edx
f010058e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010058f:	0f b7 1d 28 b2 22 f0 	movzwl 0xf022b228,%ebx
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
f01005af:	83 c4 1c             	add    $0x1c,%esp
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
f01005b7:	80 3d 34 b2 22 f0 00 	cmpb   $0x0,0xf022b234
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
f01005c6:	b8 70 02 10 f0       	mov    $0xf0100270,%eax
f01005cb:	e8 bc fc ff ff       	call   f010028c <cons_intr>
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
f01005d9:	b8 d0 02 10 f0       	mov    $0xf01002d0,%eax
f01005de:	e8 a9 fc ff ff       	call   f010028c <cons_intr>
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
f01005f5:	a1 20 b2 22 f0       	mov    0xf022b220,%eax
f01005fa:	3b 05 24 b2 22 f0    	cmp    0xf022b224,%eax
f0100600:	74 26                	je     f0100628 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100602:	8d 50 01             	lea    0x1(%eax),%edx
f0100605:	89 15 20 b2 22 f0    	mov    %edx,0xf022b220
f010060b:	0f b6 88 20 b0 22 f0 	movzbl -0xfdd4fe0(%eax),%ecx
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
f010061c:	c7 05 20 b2 22 f0 00 	movl   $0x0,0xf022b220
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
f0100635:	83 ec 1c             	sub    $0x1c,%esp
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
f0100655:	c7 05 30 b2 22 f0 b4 	movl   $0x3b4,0xf022b230
f010065c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010065f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100664:	eb 16                	jmp    f010067c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100666:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010066d:	c7 05 30 b2 22 f0 d4 	movl   $0x3d4,0xf022b230
f0100674:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100677:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010067c:	8b 0d 30 b2 22 f0    	mov    0xf022b230,%ecx
f0100682:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100687:	89 ca                	mov    %ecx,%edx
f0100689:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010068a:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010068d:	89 da                	mov    %ebx,%edx
f010068f:	ec                   	in     (%dx),%al
f0100690:	0f b6 f0             	movzbl %al,%esi
f0100693:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100696:	b8 0f 00 00 00       	mov    $0xf,%eax
f010069b:	89 ca                	mov    %ecx,%edx
f010069d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010069e:	89 da                	mov    %ebx,%edx
f01006a0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006a1:	89 3d 2c b2 22 f0    	mov    %edi,0xf022b22c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01006a7:	0f b6 d8             	movzbl %al,%ebx
f01006aa:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01006ac:	66 89 35 28 b2 22 f0 	mov    %si,0xf022b228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006b3:	e8 1b ff ff ff       	call   f01005d3 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<1));
f01006b8:	0f b7 05 a8 03 12 f0 	movzwl 0xf01203a8,%eax
f01006bf:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006c4:	89 04 24             	mov    %eax,(%esp)
f01006c7:	e8 b1 38 00 00       	call   f0103f7d <irq_setmask_8259A>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006cc:	be fa 03 00 00       	mov    $0x3fa,%esi
f01006d1:	b8 00 00 00 00       	mov    $0x0,%eax
f01006d6:	89 f2                	mov    %esi,%edx
f01006d8:	ee                   	out    %al,(%dx)
f01006d9:	b2 fb                	mov    $0xfb,%dl
f01006db:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006e0:	ee                   	out    %al,(%dx)
f01006e1:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01006e6:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006eb:	89 da                	mov    %ebx,%edx
f01006ed:	ee                   	out    %al,(%dx)
f01006ee:	b2 f9                	mov    $0xf9,%dl
f01006f0:	b8 00 00 00 00       	mov    $0x0,%eax
f01006f5:	ee                   	out    %al,(%dx)
f01006f6:	b2 fb                	mov    $0xfb,%dl
f01006f8:	b8 03 00 00 00       	mov    $0x3,%eax
f01006fd:	ee                   	out    %al,(%dx)
f01006fe:	b2 fc                	mov    $0xfc,%dl
f0100700:	b8 00 00 00 00       	mov    $0x0,%eax
f0100705:	ee                   	out    %al,(%dx)
f0100706:	b2 f9                	mov    $0xf9,%dl
f0100708:	b8 01 00 00 00       	mov    $0x1,%eax
f010070d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010070e:	b2 fd                	mov    $0xfd,%dl
f0100710:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100711:	3c ff                	cmp    $0xff,%al
f0100713:	0f 95 c1             	setne  %cl
f0100716:	88 0d 34 b2 22 f0    	mov    %cl,0xf022b234
f010071c:	89 f2                	mov    %esi,%edx
f010071e:	ec                   	in     (%dx),%al
f010071f:	89 da                	mov    %ebx,%edx
f0100721:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100722:	84 c9                	test   %cl,%cl
f0100724:	75 0c                	jne    f0100732 <cons_init+0x103>
		cprintf("Serial port does not exist!\n");
f0100726:	c7 04 24 8f 67 10 f0 	movl   $0xf010678f,(%esp)
f010072d:	e8 8a 39 00 00       	call   f01040bc <cprintf>
}
f0100732:	83 c4 1c             	add    $0x1c,%esp
f0100735:	5b                   	pop    %ebx
f0100736:	5e                   	pop    %esi
f0100737:	5f                   	pop    %edi
f0100738:	5d                   	pop    %ebp
f0100739:	c3                   	ret    

f010073a <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010073a:	55                   	push   %ebp
f010073b:	89 e5                	mov    %esp,%ebp
f010073d:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100740:	8b 45 08             	mov    0x8(%ebp),%eax
f0100743:	e8 91 fc ff ff       	call   f01003d9 <cons_putc>
}
f0100748:	c9                   	leave  
f0100749:	c3                   	ret    

f010074a <getchar>:

int
getchar(void)
{
f010074a:	55                   	push   %ebp
f010074b:	89 e5                	mov    %esp,%ebp
f010074d:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100750:	e8 90 fe ff ff       	call   f01005e5 <cons_getc>
f0100755:	85 c0                	test   %eax,%eax
f0100757:	74 f7                	je     f0100750 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100759:	c9                   	leave  
f010075a:	c3                   	ret    

f010075b <iscons>:

int
iscons(int fdnum)
{
f010075b:	55                   	push   %ebp
f010075c:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010075e:	b8 01 00 00 00       	mov    $0x1,%eax
f0100763:	5d                   	pop    %ebp
f0100764:	c3                   	ret    
f0100765:	66 90                	xchg   %ax,%ax
f0100767:	66 90                	xchg   %ax,%ax
f0100769:	66 90                	xchg   %ax,%ax
f010076b:	66 90                	xchg   %ax,%ax
f010076d:	66 90                	xchg   %ax,%ax
f010076f:	90                   	nop

f0100770 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100770:	55                   	push   %ebp
f0100771:	89 e5                	mov    %esp,%ebp
f0100773:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100776:	c7 44 24 08 e0 69 10 	movl   $0xf01069e0,0x8(%esp)
f010077d:	f0 
f010077e:	c7 44 24 04 fe 69 10 	movl   $0xf01069fe,0x4(%esp)
f0100785:	f0 
f0100786:	c7 04 24 03 6a 10 f0 	movl   $0xf0106a03,(%esp)
f010078d:	e8 2a 39 00 00       	call   f01040bc <cprintf>
f0100792:	c7 44 24 08 a4 6a 10 	movl   $0xf0106aa4,0x8(%esp)
f0100799:	f0 
f010079a:	c7 44 24 04 0c 6a 10 	movl   $0xf0106a0c,0x4(%esp)
f01007a1:	f0 
f01007a2:	c7 04 24 03 6a 10 f0 	movl   $0xf0106a03,(%esp)
f01007a9:	e8 0e 39 00 00       	call   f01040bc <cprintf>
f01007ae:	c7 44 24 08 15 6a 10 	movl   $0xf0106a15,0x8(%esp)
f01007b5:	f0 
f01007b6:	c7 44 24 04 32 6a 10 	movl   $0xf0106a32,0x4(%esp)
f01007bd:	f0 
f01007be:	c7 04 24 03 6a 10 f0 	movl   $0xf0106a03,(%esp)
f01007c5:	e8 f2 38 00 00       	call   f01040bc <cprintf>
	return 0;
}
f01007ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01007cf:	c9                   	leave  
f01007d0:	c3                   	ret    

f01007d1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007d1:	55                   	push   %ebp
f01007d2:	89 e5                	mov    %esp,%ebp
f01007d4:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007d7:	c7 04 24 3d 6a 10 f0 	movl   $0xf0106a3d,(%esp)
f01007de:	e8 d9 38 00 00       	call   f01040bc <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007e3:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01007ea:	00 
f01007eb:	c7 04 24 cc 6a 10 f0 	movl   $0xf0106acc,(%esp)
f01007f2:	e8 c5 38 00 00       	call   f01040bc <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007f7:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01007fe:	00 
f01007ff:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100806:	f0 
f0100807:	c7 04 24 f4 6a 10 f0 	movl   $0xf0106af4,(%esp)
f010080e:	e8 a9 38 00 00       	call   f01040bc <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100813:	c7 44 24 08 b5 66 10 	movl   $0x1066b5,0x8(%esp)
f010081a:	00 
f010081b:	c7 44 24 04 b5 66 10 	movl   $0xf01066b5,0x4(%esp)
f0100822:	f0 
f0100823:	c7 04 24 18 6b 10 f0 	movl   $0xf0106b18,(%esp)
f010082a:	e8 8d 38 00 00       	call   f01040bc <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010082f:	c7 44 24 08 07 ad 22 	movl   $0x22ad07,0x8(%esp)
f0100836:	00 
f0100837:	c7 44 24 04 07 ad 22 	movl   $0xf022ad07,0x4(%esp)
f010083e:	f0 
f010083f:	c7 04 24 3c 6b 10 f0 	movl   $0xf0106b3c,(%esp)
f0100846:	e8 71 38 00 00       	call   f01040bc <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010084b:	c7 44 24 08 08 d0 26 	movl   $0x26d008,0x8(%esp)
f0100852:	00 
f0100853:	c7 44 24 04 08 d0 26 	movl   $0xf026d008,0x4(%esp)
f010085a:	f0 
f010085b:	c7 04 24 60 6b 10 f0 	movl   $0xf0106b60,(%esp)
f0100862:	e8 55 38 00 00       	call   f01040bc <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100867:	b8 07 d4 26 f0       	mov    $0xf026d407,%eax
f010086c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100871:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100876:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010087c:	85 c0                	test   %eax,%eax
f010087e:	0f 48 c2             	cmovs  %edx,%eax
f0100881:	c1 f8 0a             	sar    $0xa,%eax
f0100884:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100888:	c7 04 24 84 6b 10 f0 	movl   $0xf0106b84,(%esp)
f010088f:	e8 28 38 00 00       	call   f01040bc <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100894:	b8 00 00 00 00       	mov    $0x0,%eax
f0100899:	c9                   	leave  
f010089a:	c3                   	ret    

f010089b <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010089b:	55                   	push   %ebp
f010089c:	89 e5                	mov    %esp,%ebp
f010089e:	57                   	push   %edi
f010089f:	56                   	push   %esi
f01008a0:	53                   	push   %ebx
f01008a1:	83 ec 6c             	sub    $0x6c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01008a4:	89 eb                	mov    %ebp,%ebx
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
f01008a6:	c7 04 24 56 6a 10 f0 	movl   $0xf0106a56,(%esp)
f01008ad:	e8 0a 38 00 00       	call   f01040bc <cprintf>
	
	while (ebp){
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
		debuginfo_eip(eip, &sym);
f01008b2:	8d 7d d0             	lea    -0x30(%ebp),%edi
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f01008b5:	eb 6d                	jmp    f0100924 <mon_backtrace+0x89>
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
f01008b7:	8b 73 04             	mov    0x4(%ebx),%esi
		debuginfo_eip(eip, &sym);
f01008ba:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01008be:	89 34 24             	mov    %esi,(%esp)
f01008c1:	e8 68 45 00 00       	call   f0104e2e <debuginfo_eip>
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n %s:%d: %.*s+%d\n",ebp,eip,
f01008c6:	89 f0                	mov    %esi,%eax
f01008c8:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01008cb:	89 44 24 30          	mov    %eax,0x30(%esp)
f01008cf:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01008d2:	89 44 24 2c          	mov    %eax,0x2c(%esp)
f01008d6:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01008d9:	89 44 24 28          	mov    %eax,0x28(%esp)
f01008dd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01008e0:	89 44 24 24          	mov    %eax,0x24(%esp)
f01008e4:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01008e7:	89 44 24 20          	mov    %eax,0x20(%esp)
f01008eb:	8b 43 18             	mov    0x18(%ebx),%eax
f01008ee:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f01008f2:	8b 43 14             	mov    0x14(%ebx),%eax
f01008f5:	89 44 24 18          	mov    %eax,0x18(%esp)
f01008f9:	8b 43 10             	mov    0x10(%ebx),%eax
f01008fc:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100900:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100903:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100907:	8b 43 08             	mov    0x8(%ebx),%eax
f010090a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010090e:	89 74 24 08          	mov    %esi,0x8(%esp)
f0100912:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100916:	c7 04 24 b0 6b 10 f0 	movl   $0xf0106bb0,(%esp)
f010091d:	e8 9a 37 00 00       	call   f01040bc <cprintf>
		*((uint32_t *)ebp + 6), sym.eip_file,
			      sym.eip_line,
			      sym.eip_fn_namelen,
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
f0100922:	8b 1b                	mov    (%ebx),%ebx
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f0100924:	85 db                	test   %ebx,%ebx
f0100926:	75 8f                	jne    f01008b7 <mon_backtrace+0x1c>
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
	}
	return 0;
}
f0100928:	b8 00 00 00 00       	mov    $0x0,%eax
f010092d:	83 c4 6c             	add    $0x6c,%esp
f0100930:	5b                   	pop    %ebx
f0100931:	5e                   	pop    %esi
f0100932:	5f                   	pop    %edi
f0100933:	5d                   	pop    %ebp
f0100934:	c3                   	ret    

f0100935 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100935:	55                   	push   %ebp
f0100936:	89 e5                	mov    %esp,%ebp
f0100938:	57                   	push   %edi
f0100939:	56                   	push   %esi
f010093a:	53                   	push   %ebx
f010093b:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010093e:	c7 04 24 f4 6b 10 f0 	movl   $0xf0106bf4,(%esp)
f0100945:	e8 72 37 00 00       	call   f01040bc <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010094a:	c7 04 24 18 6c 10 f0 	movl   $0xf0106c18,(%esp)
f0100951:	e8 66 37 00 00       	call   f01040bc <cprintf>

	if (tf != NULL)
f0100956:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010095a:	74 0b                	je     f0100967 <monitor+0x32>
		print_trapframe(tf);
f010095c:	8b 45 08             	mov    0x8(%ebp),%eax
f010095f:	89 04 24             	mov    %eax,(%esp)
f0100962:	e8 58 39 00 00       	call   f01042bf <print_trapframe>

	while (1) {
		buf = readline("K> ");
f0100967:	c7 04 24 68 6a 10 f0 	movl   $0xf0106a68,(%esp)
f010096e:	e8 ad 4d 00 00       	call   f0105720 <readline>
f0100973:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100975:	85 c0                	test   %eax,%eax
f0100977:	74 ee                	je     f0100967 <monitor+0x32>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100979:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100980:	be 00 00 00 00       	mov    $0x0,%esi
f0100985:	eb 0a                	jmp    f0100991 <monitor+0x5c>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100987:	c6 03 00             	movb   $0x0,(%ebx)
f010098a:	89 f7                	mov    %esi,%edi
f010098c:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010098f:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100991:	0f b6 03             	movzbl (%ebx),%eax
f0100994:	84 c0                	test   %al,%al
f0100996:	74 63                	je     f01009fb <monitor+0xc6>
f0100998:	0f be c0             	movsbl %al,%eax
f010099b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010099f:	c7 04 24 6c 6a 10 f0 	movl   $0xf0106a6c,(%esp)
f01009a6:	e8 8f 4f 00 00       	call   f010593a <strchr>
f01009ab:	85 c0                	test   %eax,%eax
f01009ad:	75 d8                	jne    f0100987 <monitor+0x52>
			*buf++ = 0;
		if (*buf == 0)
f01009af:	80 3b 00             	cmpb   $0x0,(%ebx)
f01009b2:	74 47                	je     f01009fb <monitor+0xc6>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01009b4:	83 fe 0f             	cmp    $0xf,%esi
f01009b7:	75 16                	jne    f01009cf <monitor+0x9a>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01009b9:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01009c0:	00 
f01009c1:	c7 04 24 71 6a 10 f0 	movl   $0xf0106a71,(%esp)
f01009c8:	e8 ef 36 00 00       	call   f01040bc <cprintf>
f01009cd:	eb 98                	jmp    f0100967 <monitor+0x32>
			return 0;
		}
		argv[argc++] = buf;
f01009cf:	8d 7e 01             	lea    0x1(%esi),%edi
f01009d2:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01009d6:	eb 03                	jmp    f01009db <monitor+0xa6>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01009d8:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01009db:	0f b6 03             	movzbl (%ebx),%eax
f01009de:	84 c0                	test   %al,%al
f01009e0:	74 ad                	je     f010098f <monitor+0x5a>
f01009e2:	0f be c0             	movsbl %al,%eax
f01009e5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009e9:	c7 04 24 6c 6a 10 f0 	movl   $0xf0106a6c,(%esp)
f01009f0:	e8 45 4f 00 00       	call   f010593a <strchr>
f01009f5:	85 c0                	test   %eax,%eax
f01009f7:	74 df                	je     f01009d8 <monitor+0xa3>
f01009f9:	eb 94                	jmp    f010098f <monitor+0x5a>
			buf++;
	}
	argv[argc] = 0;
f01009fb:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100a02:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100a03:	85 f6                	test   %esi,%esi
f0100a05:	0f 84 5c ff ff ff    	je     f0100967 <monitor+0x32>
f0100a0b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100a10:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a13:	8b 04 85 40 6c 10 f0 	mov    -0xfef93c0(,%eax,4),%eax
f0100a1a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a1e:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a21:	89 04 24             	mov    %eax,(%esp)
f0100a24:	e8 b3 4e 00 00       	call   f01058dc <strcmp>
f0100a29:	85 c0                	test   %eax,%eax
f0100a2b:	75 24                	jne    f0100a51 <monitor+0x11c>
			return commands[i].func(argc, argv, tf);
f0100a2d:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a30:	8b 55 08             	mov    0x8(%ebp),%edx
f0100a33:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100a37:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100a3a:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100a3e:	89 34 24             	mov    %esi,(%esp)
f0100a41:	ff 14 85 48 6c 10 f0 	call   *-0xfef93b8(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100a48:	85 c0                	test   %eax,%eax
f0100a4a:	78 25                	js     f0100a71 <monitor+0x13c>
f0100a4c:	e9 16 ff ff ff       	jmp    f0100967 <monitor+0x32>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100a51:	83 c3 01             	add    $0x1,%ebx
f0100a54:	83 fb 03             	cmp    $0x3,%ebx
f0100a57:	75 b7                	jne    f0100a10 <monitor+0xdb>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a59:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a5c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a60:	c7 04 24 8e 6a 10 f0 	movl   $0xf0106a8e,(%esp)
f0100a67:	e8 50 36 00 00       	call   f01040bc <cprintf>
f0100a6c:	e9 f6 fe ff ff       	jmp    f0100967 <monitor+0x32>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a71:	83 c4 5c             	add    $0x5c,%esp
f0100a74:	5b                   	pop    %ebx
f0100a75:	5e                   	pop    %esi
f0100a76:	5f                   	pop    %edi
f0100a77:	5d                   	pop    %ebp
f0100a78:	c3                   	ret    
f0100a79:	66 90                	xchg   %ax,%ax
f0100a7b:	66 90                	xchg   %ax,%ax
f0100a7d:	66 90                	xchg   %ax,%ax
f0100a7f:	90                   	nop

f0100a80 <page2kva>:
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a80:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f0100a86:	c1 f8 03             	sar    $0x3,%eax
f0100a89:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a8c:	89 c2                	mov    %eax,%edx
f0100a8e:	c1 ea 0c             	shr    $0xc,%edx
f0100a91:	3b 15 88 be 22 f0    	cmp    0xf022be88,%edx
f0100a97:	72 26                	jb     f0100abf <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100a99:	55                   	push   %ebp
f0100a9a:	89 e5                	mov    %esp,%ebp
f0100a9c:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a9f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100aa3:	c7 44 24 08 e4 66 10 	movl   $0xf01066e4,0x8(%esp)
f0100aaa:	f0 
f0100aab:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100ab2:	00 
f0100ab3:	c7 04 24 55 76 10 f0 	movl   $0xf0107655,(%esp)
f0100aba:	e8 81 f5 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100abf:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));  //page2kva returns virtual address of the 
}
f0100ac4:	c3                   	ret    

f0100ac5 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100ac5:	89 d1                	mov    %edx,%ecx
f0100ac7:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100aca:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100acd:	a8 01                	test   $0x1,%al
f0100acf:	74 5d                	je     f0100b2e <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100ad1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ad6:	89 c1                	mov    %eax,%ecx
f0100ad8:	c1 e9 0c             	shr    $0xc,%ecx
f0100adb:	3b 0d 88 be 22 f0    	cmp    0xf022be88,%ecx
f0100ae1:	72 26                	jb     f0100b09 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100ae3:	55                   	push   %ebp
f0100ae4:	89 e5                	mov    %esp,%ebp
f0100ae6:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ae9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100aed:	c7 44 24 08 e4 66 10 	movl   $0xf01066e4,0x8(%esp)
f0100af4:	f0 
f0100af5:	c7 44 24 04 10 04 00 	movl   $0x410,0x4(%esp)
f0100afc:	00 
f0100afd:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0100b04:	e8 37 f5 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100b09:	c1 ea 0c             	shr    $0xc,%edx
f0100b0c:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b12:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100b19:	89 c2                	mov    %eax,%edx
f0100b1b:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b1e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b23:	85 d2                	test   %edx,%edx
f0100b25:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b2a:	0f 44 c2             	cmove  %edx,%eax
f0100b2d:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100b2e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100b33:	c3                   	ret    

f0100b34 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100b34:	83 3d 3c b2 22 f0 00 	cmpl   $0x0,0xf022b23c
f0100b3b:	75 11                	jne    f0100b4e <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE); // Roundup function rounds according to the given functions
f0100b3d:	ba 07 e0 26 f0       	mov    $0xf026e007,%edx
f0100b42:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b48:	89 15 3c b2 22 f0    	mov    %edx,0xf022b23c
	}
	
	if (n==0){
f0100b4e:	85 c0                	test   %eax,%eax
f0100b50:	75 06                	jne    f0100b58 <boot_alloc+0x24>
	return nextfree;
f0100b52:	a1 3c b2 22 f0       	mov    0xf022b23c,%eax
f0100b57:	c3                   	ret    
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result  = nextfree;
f0100b58:	8b 0d 3c b2 22 f0    	mov    0xf022b23c,%ecx
	nextfree += ROUNDUP(n,PGSIZE);
f0100b5e:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100b64:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b6a:	01 ca                	add    %ecx,%edx
f0100b6c:	89 15 3c b2 22 f0    	mov    %edx,0xf022b23c
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100b72:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0100b78:	77 26                	ja     f0100ba0 <boot_alloc+0x6c>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100b7a:	55                   	push   %ebp
f0100b7b:	89 e5                	mov    %esp,%ebp
f0100b7d:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100b80:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100b84:	c7 44 24 08 08 67 10 	movl   $0xf0106708,0x8(%esp)
f0100b8b:	f0 
f0100b8c:	c7 44 24 04 71 00 00 	movl   $0x71,0x4(%esp)
f0100b93:	00 
f0100b94:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0100b9b:	e8 a0 f4 ff ff       	call   f0100040 <_panic>
	// LAB 2: Your code here.
	result  = nextfree;
	nextfree += ROUNDUP(n,PGSIZE);
	
	
	if ((PADDR(nextfree))>npages*PGSIZE){
f0100ba0:	a1 88 be 22 f0       	mov    0xf022be88,%eax
f0100ba5:	c1 e0 0c             	shl    $0xc,%eax
	return (physaddr_t)kva - KERNBASE;
f0100ba8:	81 c2 00 00 00 10    	add    $0x10000000,%edx
		return 0;
f0100bae:	39 c2                	cmp    %eax,%edx
f0100bb0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bb5:	0f 46 c1             	cmovbe %ecx,%eax
	}
	return result;
}
f0100bb8:	c3                   	ret    

f0100bb9 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100bb9:	55                   	push   %ebp
f0100bba:	89 e5                	mov    %esp,%ebp
f0100bbc:	57                   	push   %edi
f0100bbd:	56                   	push   %esi
f0100bbe:	53                   	push   %ebx
f0100bbf:	83 ec 4c             	sub    $0x4c,%esp
f0100bc2:	89 45 c0             	mov    %eax,-0x40(%ebp)
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bc5:	84 c0                	test   %al,%al
f0100bc7:	0f 85 47 03 00 00    	jne    f0100f14 <check_page_free_list+0x35b>
f0100bcd:	e9 54 03 00 00       	jmp    f0100f26 <check_page_free_list+0x36d>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100bd2:	c7 44 24 08 64 6c 10 	movl   $0xf0106c64,0x8(%esp)
f0100bd9:	f0 
f0100bda:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f0100be1:	00 
f0100be2:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0100be9:	e8 52 f4 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100bee:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100bf1:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100bf4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100bf7:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100bfa:	89 c2                	mov    %eax,%edx
f0100bfc:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100c02:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100c08:	0f 95 c2             	setne  %dl
f0100c0b:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100c0e:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100c12:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100c14:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c18:	8b 00                	mov    (%eax),%eax
f0100c1a:	85 c0                	test   %eax,%eax
f0100c1c:	75 dc                	jne    f0100bfa <check_page_free_list+0x41>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100c1e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c21:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100c27:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c2a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c2d:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100c2f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100c32:	a3 44 b2 22 f0       	mov    %eax,0xf022b244
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c37:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c3c:	8b 1d 44 b2 22 f0    	mov    0xf022b244,%ebx
f0100c42:	eb 63                	jmp    f0100ca7 <check_page_free_list+0xee>
f0100c44:	89 d8                	mov    %ebx,%eax
f0100c46:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f0100c4c:	c1 f8 03             	sar    $0x3,%eax
f0100c4f:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100c52:	89 c2                	mov    %eax,%edx
f0100c54:	c1 ea 16             	shr    $0x16,%edx
f0100c57:	39 f2                	cmp    %esi,%edx
f0100c59:	73 4a                	jae    f0100ca5 <check_page_free_list+0xec>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c5b:	89 c2                	mov    %eax,%edx
f0100c5d:	c1 ea 0c             	shr    $0xc,%edx
f0100c60:	3b 15 88 be 22 f0    	cmp    0xf022be88,%edx
f0100c66:	72 20                	jb     f0100c88 <check_page_free_list+0xcf>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c68:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100c6c:	c7 44 24 08 e4 66 10 	movl   $0xf01066e4,0x8(%esp)
f0100c73:	f0 
f0100c74:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100c7b:	00 
f0100c7c:	c7 04 24 55 76 10 f0 	movl   $0xf0107655,(%esp)
f0100c83:	e8 b8 f3 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100c88:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100c8f:	00 
f0100c90:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100c97:	00 
	return (void *)(pa + KERNBASE);
f0100c98:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c9d:	89 04 24             	mov    %eax,(%esp)
f0100ca0:	e8 d2 4c 00 00       	call   f0105977 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ca5:	8b 1b                	mov    (%ebx),%ebx
f0100ca7:	85 db                	test   %ebx,%ebx
f0100ca9:	75 99                	jne    f0100c44 <check_page_free_list+0x8b>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100cab:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cb0:	e8 7f fe ff ff       	call   f0100b34 <boot_alloc>
f0100cb5:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100cb8:	8b 15 44 b2 22 f0    	mov    0xf022b244,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100cbe:	8b 0d 90 be 22 f0    	mov    0xf022be90,%ecx
		assert(pp < pages + npages);
f0100cc4:	a1 88 be 22 f0       	mov    0xf022be88,%eax
f0100cc9:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100ccc:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100ccf:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100cd2:	89 4d cc             	mov    %ecx,-0x34(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100cd5:	bf 00 00 00 00       	mov    $0x0,%edi
f0100cda:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100cdd:	e9 c4 01 00 00       	jmp    f0100ea6 <check_page_free_list+0x2ed>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ce2:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100ce5:	73 24                	jae    f0100d0b <check_page_free_list+0x152>
f0100ce7:	c7 44 24 0c 6f 76 10 	movl   $0xf010766f,0xc(%esp)
f0100cee:	f0 
f0100cef:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0100cf6:	f0 
f0100cf7:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f0100cfe:	00 
f0100cff:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0100d06:	e8 35 f3 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100d0b:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0100d0e:	72 24                	jb     f0100d34 <check_page_free_list+0x17b>
f0100d10:	c7 44 24 0c 90 76 10 	movl   $0xf0107690,0xc(%esp)
f0100d17:	f0 
f0100d18:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0100d1f:	f0 
f0100d20:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f0100d27:	00 
f0100d28:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0100d2f:	e8 0c f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d34:	89 d0                	mov    %edx,%eax
f0100d36:	2b 45 cc             	sub    -0x34(%ebp),%eax
f0100d39:	a8 07                	test   $0x7,%al
f0100d3b:	74 24                	je     f0100d61 <check_page_free_list+0x1a8>
f0100d3d:	c7 44 24 0c 88 6c 10 	movl   $0xf0106c88,0xc(%esp)
f0100d44:	f0 
f0100d45:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0100d4c:	f0 
f0100d4d:	c7 44 24 04 60 03 00 	movl   $0x360,0x4(%esp)
f0100d54:	00 
f0100d55:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0100d5c:	e8 df f2 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d61:	c1 f8 03             	sar    $0x3,%eax
f0100d64:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100d67:	85 c0                	test   %eax,%eax
f0100d69:	75 24                	jne    f0100d8f <check_page_free_list+0x1d6>
f0100d6b:	c7 44 24 0c a4 76 10 	movl   $0xf01076a4,0xc(%esp)
f0100d72:	f0 
f0100d73:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0100d7a:	f0 
f0100d7b:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f0100d82:	00 
f0100d83:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0100d8a:	e8 b1 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d8f:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100d94:	75 24                	jne    f0100dba <check_page_free_list+0x201>
f0100d96:	c7 44 24 0c b5 76 10 	movl   $0xf01076b5,0xc(%esp)
f0100d9d:	f0 
f0100d9e:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0100da5:	f0 
f0100da6:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f0100dad:	00 
f0100dae:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0100db5:	e8 86 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100dba:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100dbf:	75 24                	jne    f0100de5 <check_page_free_list+0x22c>
f0100dc1:	c7 44 24 0c bc 6c 10 	movl   $0xf0106cbc,0xc(%esp)
f0100dc8:	f0 
f0100dc9:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0100dd0:	f0 
f0100dd1:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f0100dd8:	00 
f0100dd9:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0100de0:	e8 5b f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100de5:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100dea:	75 24                	jne    f0100e10 <check_page_free_list+0x257>
f0100dec:	c7 44 24 0c ce 76 10 	movl   $0xf01076ce,0xc(%esp)
f0100df3:	f0 
f0100df4:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0100dfb:	f0 
f0100dfc:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f0100e03:	00 
f0100e04:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0100e0b:	e8 30 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e10:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100e15:	0f 86 32 01 00 00    	jbe    f0100f4d <check_page_free_list+0x394>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e1b:	89 c1                	mov    %eax,%ecx
f0100e1d:	c1 e9 0c             	shr    $0xc,%ecx
f0100e20:	39 4d c4             	cmp    %ecx,-0x3c(%ebp)
f0100e23:	77 20                	ja     f0100e45 <check_page_free_list+0x28c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e25:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e29:	c7 44 24 08 e4 66 10 	movl   $0xf01066e4,0x8(%esp)
f0100e30:	f0 
f0100e31:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100e38:	00 
f0100e39:	c7 04 24 55 76 10 f0 	movl   $0xf0107655,(%esp)
f0100e40:	e8 fb f1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100e45:	8d 88 00 00 00 f0    	lea    -0x10000000(%eax),%ecx
f0100e4b:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100e4e:	0f 86 e9 00 00 00    	jbe    f0100f3d <check_page_free_list+0x384>
f0100e54:	c7 44 24 0c e0 6c 10 	movl   $0xf0106ce0,0xc(%esp)
f0100e5b:	f0 
f0100e5c:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0100e63:	f0 
f0100e64:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f0100e6b:	00 
f0100e6c:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0100e73:	e8 c8 f1 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100e78:	c7 44 24 0c e8 76 10 	movl   $0xf01076e8,0xc(%esp)
f0100e7f:	f0 
f0100e80:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0100e87:	f0 
f0100e88:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f0100e8f:	00 
f0100e90:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0100e97:	e8 a4 f1 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100e9c:	83 c3 01             	add    $0x1,%ebx
f0100e9f:	eb 03                	jmp    f0100ea4 <check_page_free_list+0x2eb>
		else
			++nfree_extmem;
f0100ea1:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ea4:	8b 12                	mov    (%edx),%edx
f0100ea6:	85 d2                	test   %edx,%edx
f0100ea8:	0f 85 34 fe ff ff    	jne    f0100ce2 <check_page_free_list+0x129>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100eae:	85 db                	test   %ebx,%ebx
f0100eb0:	7f 24                	jg     f0100ed6 <check_page_free_list+0x31d>
f0100eb2:	c7 44 24 0c 05 77 10 	movl   $0xf0107705,0xc(%esp)
f0100eb9:	f0 
f0100eba:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0100ec1:	f0 
f0100ec2:	c7 44 24 04 71 03 00 	movl   $0x371,0x4(%esp)
f0100ec9:	00 
f0100eca:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0100ed1:	e8 6a f1 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100ed6:	85 ff                	test   %edi,%edi
f0100ed8:	7f 24                	jg     f0100efe <check_page_free_list+0x345>
f0100eda:	c7 44 24 0c 17 77 10 	movl   $0xf0107717,0xc(%esp)
f0100ee1:	f0 
f0100ee2:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0100ee9:	f0 
f0100eea:	c7 44 24 04 72 03 00 	movl   $0x372,0x4(%esp)
f0100ef1:	00 
f0100ef2:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0100ef9:	e8 42 f1 ff ff       	call   f0100040 <_panic>
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
f0100efe:	0f b6 45 c0          	movzbl -0x40(%ebp),%eax
f0100f02:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f06:	c7 04 24 28 6d 10 f0 	movl   $0xf0106d28,(%esp)
f0100f0d:	e8 aa 31 00 00       	call   f01040bc <cprintf>
f0100f12:	eb 49                	jmp    f0100f5d <check_page_free_list+0x3a4>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100f14:	a1 44 b2 22 f0       	mov    0xf022b244,%eax
f0100f19:	85 c0                	test   %eax,%eax
f0100f1b:	0f 85 cd fc ff ff    	jne    f0100bee <check_page_free_list+0x35>
f0100f21:	e9 ac fc ff ff       	jmp    f0100bd2 <check_page_free_list+0x19>
f0100f26:	83 3d 44 b2 22 f0 00 	cmpl   $0x0,0xf022b244
f0100f2d:	0f 84 9f fc ff ff    	je     f0100bd2 <check_page_free_list+0x19>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100f33:	be 00 04 00 00       	mov    $0x400,%esi
f0100f38:	e9 ff fc ff ff       	jmp    f0100c3c <check_page_free_list+0x83>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100f3d:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100f42:	0f 85 59 ff ff ff    	jne    f0100ea1 <check_page_free_list+0x2e8>
f0100f48:	e9 2b ff ff ff       	jmp    f0100e78 <check_page_free_list+0x2bf>
f0100f4d:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100f52:	0f 85 44 ff ff ff    	jne    f0100e9c <check_page_free_list+0x2e3>
f0100f58:	e9 1b ff ff ff       	jmp    f0100e78 <check_page_free_list+0x2bf>
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
}
f0100f5d:	83 c4 4c             	add    $0x4c,%esp
f0100f60:	5b                   	pop    %ebx
f0100f61:	5e                   	pop    %esi
f0100f62:	5f                   	pop    %edi
f0100f63:	5d                   	pop    %ebp
f0100f64:	c3                   	ret    

f0100f65 <page_init>:
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100f65:	b8 01 00 00 00       	mov    $0x1,%eax
f0100f6a:	eb 18                	jmp    f0100f84 <page_init+0x1f>
	{
	 pages[i].pp_ref = 1; //Used Pages
f0100f6c:	8b 15 90 be 22 f0    	mov    0xf022be90,%edx
f0100f72:	8d 14 c2             	lea    (%edx,%eax,8),%edx
f0100f75:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
	 pages[i].pp_link = 0; // No links to any pages
f0100f7b:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100f81:	83 c0 01             	add    $0x1,%eax
f0100f84:	3b 05 88 be 22 f0    	cmp    0xf022be88,%eax
f0100f8a:	72 e0                	jb     f0100f6c <page_init+0x7>
//


void
page_init(void)
{
f0100f8c:	55                   	push   %ebp
f0100f8d:	89 e5                	mov    %esp,%ebp
f0100f8f:	57                   	push   %edi
f0100f90:	56                   	push   %esi
f0100f91:	53                   	push   %ebx
f0100f92:	83 ec 1c             	sub    $0x1c,%esp
	//Modification for Lab 4, We have to skip the Page that MPENTRY_PADDR is at from the page_free_list
	//Hence we can divide it with PGSIZE and whatever is the value, just skip that page. 
	size_t mpentyPg = MPENTRY_PADDR/PGSIZE;

	// 2. The rest of base memory 
	page_free_list = 0 ;
f0100f95:	c7 05 44 b2 22 f0 00 	movl   $0x0,0xf022b244
f0100f9c:	00 00 00 
	
	struct PageInfo *prev = 0;
	for (i = 1; i < npages_basemem; ++i) {
f0100f9f:	be 00 00 00 00       	mov    $0x0,%esi
	size_t mpentyPg = MPENTRY_PADDR/PGSIZE;

	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	struct PageInfo *prev = 0;
f0100fa4:	bf 00 00 00 00       	mov    $0x0,%edi
	for (i = 1; i < npages_basemem; ++i) {
f0100fa9:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100fae:	eb 73                	jmp    f0101023 <page_init+0xbe>
		if (i == mpentyPg) {
f0100fb0:	83 fb 07             	cmp    $0x7,%ebx
f0100fb3:	75 16                	jne    f0100fcb <page_init+0x66>
			cprintf("Skipped this page %d\n", i);
f0100fb5:	c7 44 24 04 07 00 00 	movl   $0x7,0x4(%esp)
f0100fbc:	00 
f0100fbd:	c7 04 24 28 77 10 f0 	movl   $0xf0107728,(%esp)
f0100fc4:	e8 f3 30 00 00       	call   f01040bc <cprintf>
			continue;	
f0100fc9:	eb 52                	jmp    f010101d <page_init+0xb8>
f0100fcb:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
		}

		pages[i].pp_ref = 0;
f0100fd2:	8b 15 90 be 22 f0    	mov    0xf022be90,%edx
f0100fd8:	66 c7 44 02 04 00 00 	movw   $0x0,0x4(%edx,%eax,1)
		pages[i].pp_link = 0;
f0100fdf:	c7 04 da 00 00 00 00 	movl   $0x0,(%edx,%ebx,8)
		if (!page_free_list) {
f0100fe6:	83 3d 44 b2 22 f0 00 	cmpl   $0x0,0xf022b244
f0100fed:	75 10                	jne    f0100fff <page_init+0x9a>
			page_free_list = &pages[i];
f0100fef:	89 c2                	mov    %eax,%edx
f0100ff1:	03 15 90 be 22 f0    	add    0xf022be90,%edx
f0100ff7:	89 15 44 b2 22 f0    	mov    %edx,0xf022b244
f0100ffd:	eb 16                	jmp    f0101015 <page_init+0xb0>
		} else {
			prev->pp_link = &pages[i];
f0100fff:	89 c2                	mov    %eax,%edx
f0101001:	03 15 90 be 22 f0    	add    0xf022be90,%edx
f0101007:	89 17                	mov    %edx,(%edi)
			pages[i-1].pp_link = &pages[i];
f0101009:	8b 15 90 be 22 f0    	mov    0xf022be90,%edx
f010100f:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
f0101012:	89 0c 32             	mov    %ecx,(%edx,%esi,1)
		}
		prev = &pages[i];
f0101015:	03 05 90 be 22 f0    	add    0xf022be90,%eax
f010101b:	89 c7                	mov    %eax,%edi

	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	struct PageInfo *prev = 0;
	for (i = 1; i < npages_basemem; ++i) {
f010101d:	83 c3 01             	add    $0x1,%ebx
f0101020:	83 c6 08             	add    $0x8,%esi
f0101023:	3b 1d 48 b2 22 f0    	cmp    0xf022b248,%ebx
f0101029:	72 85                	jb     f0100fb0 <page_init+0x4b>
		prev = &pages[i];
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
f010102b:	a1 90 be 22 f0       	mov    0xf022be90,%eax
f0101030:	8d 44 d8 f8          	lea    -0x8(%eax,%ebx,8),%eax
f0101034:	a3 38 b2 22 f0       	mov    %eax,0xf022b238
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0101039:	b8 00 00 00 00       	mov    $0x0,%eax
f010103e:	e8 f1 fa ff ff       	call   f0100b34 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101043:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101048:	77 20                	ja     f010106a <page_init+0x105>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010104a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010104e:	c7 44 24 08 08 67 10 	movl   $0xf0106708,0x8(%esp)
f0101055:	f0 
f0101056:	c7 44 24 04 75 01 00 	movl   $0x175,0x4(%esp)
f010105d:	00 
f010105e:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101065:	e8 d6 ef ff ff       	call   f0100040 <_panic>
f010106a:	05 ff 0f 00 10       	add    $0x10000fff,%eax
f010106f:	c1 e8 0c             	shr    $0xc,%eax
f0101072:	8b 1d 38 b2 22 f0    	mov    0xf022b238,%ebx
f0101078:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f010107f:	eb 2c                	jmp    f01010ad <page_init+0x148>
		pages[i].pp_ref = 0;
f0101081:	89 d1                	mov    %edx,%ecx
f0101083:	03 0d 90 be 22 f0    	add    0xf022be90,%ecx
f0101089:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = 0;
f010108f:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		track->pp_link = &pages[i];
f0101095:	89 d1                	mov    %edx,%ecx
f0101097:	03 0d 90 be 22 f0    	add    0xf022be90,%ecx
f010109d:	89 0b                	mov    %ecx,(%ebx)
		track = &pages[i];
f010109f:	89 d3                	mov    %edx,%ebx
f01010a1:	03 1d 90 be 22 f0    	add    0xf022be90,%ebx
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f01010a7:	83 c0 01             	add    $0x1,%eax
f01010aa:	83 c2 08             	add    $0x8,%edx
f01010ad:	3b 05 88 be 22 f0    	cmp    0xf022be88,%eax
f01010b3:	72 cc                	jb     f0101081 <page_init+0x11c>
f01010b5:	89 1d 38 b2 22 f0    	mov    %ebx,0xf022b238
		pages[i].pp_link = 0;
		track->pp_link = &pages[i];
		track = &pages[i];
	}
	
	cprintf("Check first entry of pages &pages[0] = %x\n", &pages[0]);
f01010bb:	a1 90 be 22 f0       	mov    0xf022be90,%eax
f01010c0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010c4:	c7 04 24 50 6d 10 f0 	movl   $0xf0106d50,(%esp)
f01010cb:	e8 ec 2f 00 00       	call   f01040bc <cprintf>
	cprintf("&pages[npages-1] = %x\n", &pages[npages-1]);
f01010d0:	a1 90 be 22 f0       	mov    0xf022be90,%eax
f01010d5:	8b 15 88 be 22 f0    	mov    0xf022be88,%edx
f01010db:	8d 44 d0 f8          	lea    -0x8(%eax,%edx,8),%eax
f01010df:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010e3:	c7 04 24 3e 77 10 f0 	movl   $0xf010773e,(%esp)
f01010ea:	e8 cd 2f 00 00       	call   f01040bc <cprintf>
}
f01010ef:	83 c4 1c             	add    $0x1c,%esp
f01010f2:	5b                   	pop    %ebx
f01010f3:	5e                   	pop    %esi
f01010f4:	5f                   	pop    %edi
f01010f5:	5d                   	pop    %ebp
f01010f6:	c3                   	ret    

f01010f7 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f01010f7:	55                   	push   %ebp
f01010f8:	89 e5                	mov    %esp,%ebp
f01010fa:	53                   	push   %ebx
f01010fb:	83 ec 14             	sub    $0x14,%esp
	// Check if there is a free_page available 
	if (!page_free_list)
f01010fe:	8b 1d 44 b2 22 f0    	mov    0xf022b244,%ebx
f0101104:	85 db                	test   %ebx,%ebx
f0101106:	74 75                	je     f010117d <page_alloc+0x86>
	return NULL;
	}
	
	struct PageInfo *allocPage = NULL;   //Create a temporary pointer 
	allocPage = page_free_list;	//Point to the current head of free_page_list
	page_free_list = allocPage ->pp_link; //Move the head to the next avaialble page
f0101108:	8b 03                	mov    (%ebx),%eax
f010110a:	a3 44 b2 22 f0       	mov    %eax,0xf022b244
	allocPage->pp_link = NULL;	//Break the link 
f010110f:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags && ALLOC_ZERO){		//ALLOC_ZERO = 1<<0; which is nothing but  = 1
f0101115:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0101119:	74 58                	je     f0101173 <page_alloc+0x7c>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010111b:	89 d8                	mov    %ebx,%eax
f010111d:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f0101123:	c1 f8 03             	sar    $0x3,%eax
f0101126:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101129:	89 c2                	mov    %eax,%edx
f010112b:	c1 ea 0c             	shr    $0xc,%edx
f010112e:	3b 15 88 be 22 f0    	cmp    0xf022be88,%edx
f0101134:	72 20                	jb     f0101156 <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101136:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010113a:	c7 44 24 08 e4 66 10 	movl   $0xf01066e4,0x8(%esp)
f0101141:	f0 
f0101142:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0101149:	00 
f010114a:	c7 04 24 55 76 10 f0 	movl   $0xf0107655,(%esp)
f0101151:	e8 ea ee ff ff       	call   f0100040 <_panic>
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
f0101156:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010115d:	00 
f010115e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101165:	00 
	return (void *)(pa + KERNBASE);
f0101166:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010116b:	89 04 24             	mov    %eax,(%esp)
f010116e:	e8 04 48 00 00       	call   f0105977 <memset>
	}
	
	allocPage->pp_ref = 0;
f0101173:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return allocPage;
f0101179:	89 d8                	mov    %ebx,%eax
f010117b:	eb 05                	jmp    f0101182 <page_alloc+0x8b>
page_alloc(int alloc_flags)
{
	// Check if there is a free_page available 
	if (!page_free_list)
	{ 
	return NULL;
f010117d:	b8 00 00 00 00       	mov    $0x0,%eax
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
	}
	
	allocPage->pp_ref = 0;
	return allocPage;
}
f0101182:	83 c4 14             	add    $0x14,%esp
f0101185:	5b                   	pop    %ebx
f0101186:	5d                   	pop    %ebp
f0101187:	c3                   	ret    

f0101188 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0101188:	55                   	push   %ebp
f0101189:	89 e5                	mov    %esp,%ebp
f010118b:	83 ec 18             	sub    $0x18,%esp
f010118e:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	
	if(pp->pp_ref)
f0101191:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101196:	74 1c                	je     f01011b4 <page_free+0x2c>
	{
	panic("Page cannot be returned to free list, as it is still refernced ");
f0101198:	c7 44 24 08 7c 6d 10 	movl   $0xf0106d7c,0x8(%esp)
f010119f:	f0 
f01011a0:	c7 44 24 04 ad 01 00 	movl   $0x1ad,0x4(%esp)
f01011a7:	00 
f01011a8:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01011af:	e8 8c ee ff ff       	call   f0100040 <_panic>
	return;
	}
	
	// pp->pp_link is not NULL.
	else if(!pp) 
f01011b4:	85 c0                	test   %eax,%eax
f01011b6:	75 1c                	jne    f01011d4 <page_free+0x4c>
	{
	panic("Page cannot be returned to free list as it is Null");
f01011b8:	c7 44 24 08 bc 6d 10 	movl   $0xf0106dbc,0x8(%esp)
f01011bf:	f0 
f01011c0:	c7 44 24 04 b4 01 00 	movl   $0x1b4,0x4(%esp)
f01011c7:	00 
f01011c8:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01011cf:	e8 6c ee ff ff       	call   f0100040 <_panic>
	return;
	}
	
       else{
	pp->pp_link = page_free_list;
f01011d4:	8b 15 44 b2 22 f0    	mov    0xf022b244,%edx
f01011da:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f01011dc:	a3 44 b2 22 f0       	mov    %eax,0xf022b244
	}


}
f01011e1:	c9                   	leave  
f01011e2:	c3                   	ret    

f01011e3 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f01011e3:	55                   	push   %ebp
f01011e4:	89 e5                	mov    %esp,%ebp
f01011e6:	83 ec 18             	sub    $0x18,%esp
f01011e9:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f01011ec:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f01011f0:	8d 51 ff             	lea    -0x1(%ecx),%edx
f01011f3:	66 89 50 04          	mov    %dx,0x4(%eax)
f01011f7:	66 85 d2             	test   %dx,%dx
f01011fa:	75 08                	jne    f0101204 <page_decref+0x21>
		page_free(pp);
f01011fc:	89 04 24             	mov    %eax,(%esp)
f01011ff:	e8 84 ff ff ff       	call   f0101188 <page_free>
}
f0101204:	c9                   	leave  
f0101205:	c3                   	ret    

f0101206 <pgdir_walk>:
// table and page directory entries.
//

pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101206:	55                   	push   %ebp
f0101207:	89 e5                	mov    %esp,%ebp
f0101209:	57                   	push   %edi
f010120a:	56                   	push   %esi
f010120b:	53                   	push   %ebx
f010120c:	83 ec 1c             	sub    $0x1c,%esp
	pte_t *pgTab;  //Page Table index variable

	//To find the index from the pgdir we need to get the MS 10 bits,
	//We get the MS 10bits of the virtual address by using PDX function (found in inc/mmu.h ) 
	//#define PDX(la)		((((uintptr_t) (la)) >> PDXSHIFT) & 0x3FF)
	pgDir = &pgdir[PDX(va)];
f010120f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101212:	c1 eb 16             	shr    $0x16,%ebx
f0101215:	c1 e3 02             	shl    $0x2,%ebx
f0101218:	03 5d 08             	add    0x8(%ebp),%ebx

	// Check if page is present, PTE_P = 0x1 means page present  
	if (*pgDir & PTE_P)  {
f010121b:	8b 3b                	mov    (%ebx),%edi
f010121d:	f7 c7 01 00 00 00    	test   $0x1,%edi
f0101223:	74 3e                	je     f0101263 <pgdir_walk+0x5d>
		//page table entry to get to the final address translation. Now using the pgDir we can use the 
		//PTE_ADDR(pde) function to get the upper 20 bits, but this function returns a physical address. 
		//Since the kernel requires a virtual address, we can use the function KADDR to get the virtual 
		//address.
		
		pgTab = (pte_t*) KADDR(PTE_ADDR(*pgDir));
f0101225:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010122b:	89 f8                	mov    %edi,%eax
f010122d:	c1 e8 0c             	shr    $0xc,%eax
f0101230:	3b 05 88 be 22 f0    	cmp    0xf022be88,%eax
f0101236:	72 20                	jb     f0101258 <pgdir_walk+0x52>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101238:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010123c:	c7 44 24 08 e4 66 10 	movl   $0xf01066e4,0x8(%esp)
f0101243:	f0 
f0101244:	c7 44 24 04 f5 01 00 	movl   $0x1f5,0x4(%esp)
f010124b:	00 
f010124c:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101253:	e8 e8 ed ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101258:	81 ef 00 00 00 10    	sub    $0x10000000,%edi
f010125e:	e9 8f 00 00 00       	jmp    f01012f2 <pgdir_walk+0xec>
	//If page is not present 
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
f0101263:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101267:	0f 84 94 00 00 00    	je     f0101301 <pgdir_walk+0xfb>
f010126d:	c7 04 24 00 10 00 00 	movl   $0x1000,(%esp)
f0101274:	e8 7e fe ff ff       	call   f01010f7 <page_alloc>
f0101279:	89 c6                	mov    %eax,%esi
f010127b:	85 c0                	test   %eax,%eax
f010127d:	0f 84 85 00 00 00    	je     f0101308 <pgdir_walk+0x102>
			return 0;
		}

		newPage->pp_ref++;  //Increment the ref pointer of the page 
f0101283:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101288:	89 c7                	mov    %eax,%edi
f010128a:	2b 3d 90 be 22 f0    	sub    0xf022be90,%edi
f0101290:	c1 ff 03             	sar    $0x3,%edi
f0101293:	c1 e7 0c             	shl    $0xc,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101296:	89 f8                	mov    %edi,%eax
f0101298:	c1 e8 0c             	shr    $0xc,%eax
f010129b:	3b 05 88 be 22 f0    	cmp    0xf022be88,%eax
f01012a1:	72 20                	jb     f01012c3 <pgdir_walk+0xbd>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01012a3:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01012a7:	c7 44 24 08 e4 66 10 	movl   $0xf01066e4,0x8(%esp)
f01012ae:	f0 
f01012af:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f01012b6:	00 
f01012b7:	c7 04 24 55 76 10 f0 	movl   $0xf0107655,(%esp)
f01012be:	e8 7d ed ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01012c3:	81 ef 00 00 00 10    	sub    $0x10000000,%edi
		//Now this section creates the bindings and updates all the flags 
		//for relevant use of the page.
		
		//First create a link on the pgTab wrt to the new page
		pgTab = (pte_t*)page2kva(newPage); // this function gets the virtual address of the new page
		memset (pgTab, 0, PGSIZE); //Clear the entire page
f01012c9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01012d0:	00 
f01012d1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01012d8:	00 
f01012d9:	89 3c 24             	mov    %edi,(%esp)
f01012dc:	e8 96 46 00 00       	call   f0105977 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012e1:	2b 35 90 be 22 f0    	sub    0xf022be90,%esi
f01012e7:	c1 fe 03             	sar    $0x3,%esi
f01012ea:	c1 e6 0c             	shl    $0xc,%esi

		//Page Table, pgTab contains the virtual address , now we need to set the permission bits.
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
f01012ed:	83 ce 07             	or     $0x7,%esi
f01012f0:	89 33                	mov    %esi,(%ebx)
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
f01012f2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012f5:	c1 e8 0a             	shr    $0xa,%eax
f01012f8:	25 fc 0f 00 00       	and    $0xffc,%eax
f01012fd:	01 f8                	add    %edi,%eax
f01012ff:	eb 0c                	jmp    f010130d <pgdir_walk+0x107>
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
			return 0;
f0101301:	b8 00 00 00 00       	mov    $0x0,%eax
f0101306:	eb 05                	jmp    f010130d <pgdir_walk+0x107>
f0101308:	b8 00 00 00 00       	mov    $0x0,%eax
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
}
f010130d:	83 c4 1c             	add    $0x1c,%esp
f0101310:	5b                   	pop    %ebx
f0101311:	5e                   	pop    %esi
f0101312:	5f                   	pop    %edi
f0101313:	5d                   	pop    %ebp
f0101314:	c3                   	ret    

f0101315 <boot_map_region>:
//
// Hint: the TA solution uses pgdir_walk

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101315:	55                   	push   %ebp
f0101316:	89 e5                	mov    %esp,%ebp
f0101318:	57                   	push   %edi
f0101319:	56                   	push   %esi
f010131a:	53                   	push   %ebx
f010131b:	83 ec 2c             	sub    $0x2c,%esp
f010131e:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f0101321:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
f0101327:	8b 45 08             	mov    0x8(%ebp),%eax
f010132a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	size = ROUNDUP(size, PGSIZE); 
f010132f:	8d b1 ff 0f 00 00    	lea    0xfff(%ecx),%esi
f0101335:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f010133b:	89 d3                	mov    %edx,%ebx
f010133d:	29 d0                	sub    %edx,%eax
f010133f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		}
		//if (*pgTbEnt & PTE_P)
		//	panic("Page is already mapped");
		
		
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
f0101342:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101345:	83 c8 01             	or     $0x1,%eax
f0101348:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f010134b:	eb 48                	jmp    f0101395 <boot_map_region+0x80>
		if (!(pgTbEnt = pgdir_walk(pgdir, (const void*)vaBegin, 1))){
f010134d:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101354:	00 
f0101355:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101359:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010135c:	89 04 24             	mov    %eax,(%esp)
f010135f:	e8 a2 fe ff ff       	call   f0101206 <pgdir_walk>
f0101364:	85 c0                	test   %eax,%eax
f0101366:	75 1c                	jne    f0101384 <boot_map_region+0x6f>
			panic("Cannot find page for the page table entry, from boot_map_region function");
f0101368:	c7 44 24 08 f0 6d 10 	movl   $0xf0106df0,0x8(%esp)
f010136f:	f0 
f0101370:	c7 44 24 04 2b 02 00 	movl   $0x22b,0x4(%esp)
f0101377:	00 
f0101378:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f010137f:	e8 bc ec ff ff       	call   f0100040 <_panic>
		}
		//if (*pgTbEnt & PTE_P)
		//	panic("Page is already mapped");
		
		
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
f0101384:	0b 7d dc             	or     -0x24(%ebp),%edi
f0101387:	89 38                	mov    %edi,(%eax)
		vaBegin += PGSIZE;
f0101389:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		paBegin += PGSIZE; 
		size -= PGSIZE;
f010138f:	81 ee 00 10 00 00    	sub    $0x1000,%esi
f0101395:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101398:	8d 3c 18             	lea    (%eax,%ebx,1),%edi
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f010139b:	85 f6                	test   %esi,%esi
f010139d:	75 ae                	jne    f010134d <boot_map_region+0x38>
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
		vaBegin += PGSIZE;
		paBegin += PGSIZE; 
		size -= PGSIZE;
	} 	
}
f010139f:	83 c4 2c             	add    $0x2c,%esp
f01013a2:	5b                   	pop    %ebx
f01013a3:	5e                   	pop    %esi
f01013a4:	5f                   	pop    %edi
f01013a5:	5d                   	pop    %ebp
f01013a6:	c3                   	ret    

f01013a7 <page_lookup>:
// Hint: the TA solution uses pgdir_walk and pa2page.
//

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01013a7:	55                   	push   %ebp
f01013a8:	89 e5                	mov    %esp,%ebp
f01013aa:	53                   	push   %ebx
f01013ab:	83 ec 14             	sub    $0x14,%esp
f01013ae:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
	pgTbEty = pgdir_walk(pgdir, va, 0);
f01013b1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01013b8:	00 
f01013b9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013bc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013c0:	8b 45 08             	mov    0x8(%ebp),%eax
f01013c3:	89 04 24             	mov    %eax,(%esp)
f01013c6:	e8 3b fe ff ff       	call   f0101206 <pgdir_walk>
f01013cb:	89 c2                	mov    %eax,%edx
	if (pgTbEty && (*pgTbEty & PTE_P)) {
f01013cd:	85 c0                	test   %eax,%eax
f01013cf:	74 1a                	je     f01013eb <page_lookup+0x44>
f01013d1:	8b 00                	mov    (%eax),%eax
f01013d3:	a8 01                	test   $0x1,%al
f01013d5:	74 1b                	je     f01013f2 <page_lookup+0x4b>
		ret = pages + (PTE_ADDR(*pgTbEty) >> PTXSHIFT);
f01013d7:	c1 e8 0c             	shr    $0xc,%eax
f01013da:	8b 0d 90 be 22 f0    	mov    0xf022be90,%ecx
f01013e0:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
		if (pte_store) {
f01013e3:	85 db                	test   %ebx,%ebx
f01013e5:	74 10                	je     f01013f7 <page_lookup+0x50>
			*pte_store = pgTbEty;
f01013e7:	89 13                	mov    %edx,(%ebx)
f01013e9:	eb 0c                	jmp    f01013f7 <page_lookup+0x50>

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
f01013eb:	b8 00 00 00 00       	mov    $0x0,%eax
f01013f0:	eb 05                	jmp    f01013f7 <page_lookup+0x50>
f01013f2:	b8 00 00 00 00       	mov    $0x0,%eax
		if (pte_store) {
			*pte_store = pgTbEty;
		}
	}
	return ret;
}
f01013f7:	83 c4 14             	add    $0x14,%esp
f01013fa:	5b                   	pop    %ebx
f01013fb:	5d                   	pop    %ebp
f01013fc:	c3                   	ret    

f01013fd <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01013fd:	55                   	push   %ebp
f01013fe:	89 e5                	mov    %esp,%ebp
f0101400:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f0101403:	e8 c1 4b 00 00       	call   f0105fc9 <cpunum>
f0101408:	6b c0 74             	imul   $0x74,%eax,%eax
f010140b:	83 b8 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%eax)
f0101412:	74 16                	je     f010142a <tlb_invalidate+0x2d>
f0101414:	e8 b0 4b 00 00       	call   f0105fc9 <cpunum>
f0101419:	6b c0 74             	imul   $0x74,%eax,%eax
f010141c:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0101422:	8b 55 08             	mov    0x8(%ebp),%edx
f0101425:	39 50 60             	cmp    %edx,0x60(%eax)
f0101428:	75 06                	jne    f0101430 <tlb_invalidate+0x33>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010142a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010142d:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f0101430:	c9                   	leave  
f0101431:	c3                   	ret    

f0101432 <page_remove>:
// 	tlb_invalidate, and page_decref.
//

void
page_remove(pde_t *pgdir, void *va)
{
f0101432:	55                   	push   %ebp
f0101433:	89 e5                	mov    %esp,%ebp
f0101435:	56                   	push   %esi
f0101436:	53                   	push   %ebx
f0101437:	83 ec 20             	sub    $0x20,%esp
f010143a:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010143d:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t *pte;
	struct PageInfo *remPage = 0;
	if (!(remPage = page_lookup(pgdir, va, &pte))) {
f0101440:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101443:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101447:	89 74 24 04          	mov    %esi,0x4(%esp)
f010144b:	89 1c 24             	mov    %ebx,(%esp)
f010144e:	e8 54 ff ff ff       	call   f01013a7 <page_lookup>
f0101453:	85 c0                	test   %eax,%eax
f0101455:	74 1d                	je     f0101474 <page_remove+0x42>
		return;
	}
	page_decref(remPage);
f0101457:	89 04 24             	mov    %eax,(%esp)
f010145a:	e8 84 fd ff ff       	call   f01011e3 <page_decref>
	*pte = 0;
f010145f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101462:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir, va);
f0101468:	89 74 24 04          	mov    %esi,0x4(%esp)
f010146c:	89 1c 24             	mov    %ebx,(%esp)
f010146f:	e8 89 ff ff ff       	call   f01013fd <tlb_invalidate>
}
f0101474:	83 c4 20             	add    $0x20,%esp
f0101477:	5b                   	pop    %ebx
f0101478:	5e                   	pop    %esi
f0101479:	5d                   	pop    %ebp
f010147a:	c3                   	ret    

f010147b <page_insert>:
// and page2pa.
//

int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010147b:	55                   	push   %ebp
f010147c:	89 e5                	mov    %esp,%ebp
f010147e:	57                   	push   %edi
f010147f:	56                   	push   %esi
f0101480:	53                   	push   %ebx
f0101481:	83 ec 1c             	sub    $0x1c,%esp
f0101484:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101487:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
f010148a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101491:	00 
f0101492:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101496:	8b 45 08             	mov    0x8(%ebp),%eax
f0101499:	89 04 24             	mov    %eax,(%esp)
f010149c:	e8 65 fd ff ff       	call   f0101206 <pgdir_walk>
f01014a1:	89 c3                	mov    %eax,%ebx
	
	if (!pte){
f01014a3:	85 c0                	test   %eax,%eax
f01014a5:	0f 84 85 00 00 00    	je     f0101530 <page_insert+0xb5>
		return -E_NO_MEM; //Page table could not be allocated	
	}

	if (*pte & PTE_P){    //if page is already present
f01014ab:	8b 00                	mov    (%eax),%eax
f01014ad:	a8 01                	test   $0x1,%al
f01014af:	74 5b                	je     f010150c <page_insert+0x91>
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
f01014b1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01014b6:	89 f2                	mov    %esi,%edx
f01014b8:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
f01014be:	c1 fa 03             	sar    $0x3,%edx
f01014c1:	c1 e2 0c             	shl    $0xc,%edx
f01014c4:	39 d0                	cmp    %edx,%eax
f01014c6:	75 11                	jne    f01014d9 <page_insert+0x5e>
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
f01014c8:	8b 55 14             	mov    0x14(%ebp),%edx
f01014cb:	83 ca 01             	or     $0x1,%edx
f01014ce:	09 d0                	or     %edx,%eax
f01014d0:	89 03                	mov    %eax,(%ebx)
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
			pp->pp_ref ++;  //incremnt the page reference
		}
		return 0;
f01014d2:	b8 00 00 00 00       	mov    $0x0,%eax
f01014d7:	eb 5c                	jmp    f0101535 <page_insert+0xba>
	if (*pte & PTE_P){    //if page is already present
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
		}
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
f01014d9:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01014dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01014e0:	89 04 24             	mov    %eax,(%esp)
f01014e3:	e8 4a ff ff ff       	call   f0101432 <page_remove>
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
f01014e8:	8b 55 14             	mov    0x14(%ebp),%edx
f01014eb:	83 ca 01             	or     $0x1,%edx
f01014ee:	89 f0                	mov    %esi,%eax
f01014f0:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f01014f6:	c1 f8 03             	sar    $0x3,%eax
f01014f9:	c1 e0 0c             	shl    $0xc,%eax
f01014fc:	09 d0                	or     %edx,%eax
f01014fe:	89 03                	mov    %eax,(%ebx)
			pp->pp_ref ++;  //incremnt the page reference
f0101500:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
		}
		return 0;
f0101505:	b8 00 00 00 00       	mov    $0x0,%eax
f010150a:	eb 29                	jmp    f0101535 <page_insert+0xba>
	}	
	else{   // if page is not present
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
f010150c:	8b 55 14             	mov    0x14(%ebp),%edx
f010150f:	83 ca 01             	or     $0x1,%edx
f0101512:	89 f0                	mov    %esi,%eax
f0101514:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f010151a:	c1 f8 03             	sar    $0x3,%eax
f010151d:	c1 e0 0c             	shl    $0xc,%eax
f0101520:	09 d0                	or     %edx,%eax
f0101522:	89 03                	mov    %eax,(%ebx)
		pp->pp_ref ++; // increment the page reference count	     
f0101524:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	}
	return 0;
f0101529:	b8 00 00 00 00       	mov    $0x0,%eax
f010152e:	eb 05                	jmp    f0101535 <page_insert+0xba>
{
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
	
	if (!pte){
		return -E_NO_MEM; //Page table could not be allocated	
f0101530:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
		pp->pp_ref ++; // increment the page reference count	     
	}
	return 0;

}
f0101535:	83 c4 1c             	add    $0x1c,%esp
f0101538:	5b                   	pop    %ebx
f0101539:	5e                   	pop    %esi
f010153a:	5f                   	pop    %edi
f010153b:	5d                   	pop    %ebp
f010153c:	c3                   	ret    

f010153d <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f010153d:	55                   	push   %ebp
f010153e:	89 e5                	mov    %esp,%ebp
f0101540:	56                   	push   %esi
f0101541:	53                   	push   %ebx
f0101542:	83 ec 10             	sub    $0x10,%esp
	//
	// Your code here:
	//panic("mmio_map_region not implemented");
	
	//Since we modify the value of the pointer, copy the value of the pointer into some variable
	void* save = (void*) base;  // USe a pointer to void, just to store the first address
f0101545:	8b 1d 00 03 12 f0    	mov    0xf0120300,%ebx
	
	//Roundup size to pgsize
	size = ROUNDUP(size,PGSIZE);
f010154b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010154e:	8d b0 ff 0f 00 00    	lea    0xfff(%eax),%esi
f0101554:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	
	//Use bootmap region to map the given region
	boot_map_region(kern_pgdir, base, size, pa, PTE_W | PTE_P |PTE_PCD|PTE_PWT);
f010155a:	c7 44 24 04 1b 00 00 	movl   $0x1b,0x4(%esp)
f0101561:	00 
f0101562:	8b 45 08             	mov    0x8(%ebp),%eax
f0101565:	89 04 24             	mov    %eax,(%esp)
f0101568:	89 f1                	mov    %esi,%ecx
f010156a:	89 da                	mov    %ebx,%edx
f010156c:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0101571:	e8 9f fd ff ff       	call   f0101315 <boot_map_region>
	
	//reserving size bytes of memory
	base += size;
f0101576:	01 35 00 03 12 f0    	add    %esi,0xf0120300
	
	return save; 
	
}
f010157c:	89 d8                	mov    %ebx,%eax
f010157e:	83 c4 10             	add    $0x10,%esp
f0101581:	5b                   	pop    %ebx
f0101582:	5e                   	pop    %esi
f0101583:	5d                   	pop    %ebp
f0101584:	c3                   	ret    

f0101585 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101585:	55                   	push   %ebp
f0101586:	89 e5                	mov    %esp,%ebp
f0101588:	57                   	push   %edi
f0101589:	56                   	push   %esi
f010158a:	53                   	push   %ebx
f010158b:	83 ec 4c             	sub    $0x4c,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010158e:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f0101595:	e8 b9 29 00 00       	call   f0103f53 <mc146818_read>
f010159a:	89 c3                	mov    %eax,%ebx
f010159c:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f01015a3:	e8 ab 29 00 00       	call   f0103f53 <mc146818_read>
f01015a8:	c1 e0 08             	shl    $0x8,%eax
f01015ab:	09 c3                	or     %eax,%ebx
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01015ad:	89 d8                	mov    %ebx,%eax
f01015af:	c1 e0 0a             	shl    $0xa,%eax
f01015b2:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01015b8:	85 c0                	test   %eax,%eax
f01015ba:	0f 48 c2             	cmovs  %edx,%eax
f01015bd:	c1 f8 0c             	sar    $0xc,%eax
f01015c0:	a3 48 b2 22 f0       	mov    %eax,0xf022b248
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01015c5:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f01015cc:	e8 82 29 00 00       	call   f0103f53 <mc146818_read>
f01015d1:	89 c3                	mov    %eax,%ebx
f01015d3:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01015da:	e8 74 29 00 00       	call   f0103f53 <mc146818_read>
f01015df:	c1 e0 08             	shl    $0x8,%eax
f01015e2:	09 c3                	or     %eax,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01015e4:	89 d8                	mov    %ebx,%eax
f01015e6:	c1 e0 0a             	shl    $0xa,%eax
f01015e9:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01015ef:	85 c0                	test   %eax,%eax
f01015f1:	0f 48 c2             	cmovs  %edx,%eax
f01015f4:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01015f7:	85 c0                	test   %eax,%eax
f01015f9:	74 0e                	je     f0101609 <mem_init+0x84>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01015fb:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101601:	89 15 88 be 22 f0    	mov    %edx,0xf022be88
f0101607:	eb 0c                	jmp    f0101615 <mem_init+0x90>
	else
		npages = npages_basemem;
f0101609:	8b 15 48 b2 22 f0    	mov    0xf022b248,%edx
f010160f:	89 15 88 be 22 f0    	mov    %edx,0xf022be88

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0101615:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101618:	c1 e8 0a             	shr    $0xa,%eax
f010161b:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f010161f:	a1 48 b2 22 f0       	mov    0xf022b248,%eax
f0101624:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101627:	c1 e8 0a             	shr    $0xa,%eax
f010162a:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f010162e:	a1 88 be 22 f0       	mov    0xf022be88,%eax
f0101633:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101636:	c1 e8 0a             	shr    $0xa,%eax
f0101639:	89 44 24 04          	mov    %eax,0x4(%esp)
f010163d:	c7 04 24 3c 6e 10 f0 	movl   $0xf0106e3c,(%esp)
f0101644:	e8 73 2a 00 00       	call   f01040bc <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101649:	b8 00 10 00 00       	mov    $0x1000,%eax
f010164e:	e8 e1 f4 ff ff       	call   f0100b34 <boot_alloc>
f0101653:	a3 8c be 22 f0       	mov    %eax,0xf022be8c
	memset(kern_pgdir, 0, PGSIZE);
f0101658:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010165f:	00 
f0101660:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101667:	00 
f0101668:	89 04 24             	mov    %eax,(%esp)
f010166b:	e8 07 43 00 00       	call   f0105977 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101670:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101675:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010167a:	77 20                	ja     f010169c <mem_init+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010167c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101680:	c7 44 24 08 08 67 10 	movl   $0xf0106708,0x8(%esp)
f0101687:	f0 
f0101688:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
f010168f:	00 
f0101690:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101697:	e8 a4 e9 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010169c:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01016a2:	83 ca 05             	or     $0x5,%edx
f01016a5:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.

	//This line creates a boot allocation of memory of the size of number of pages
	// mulitplied by size of struct Pageinfo to store metadata of the page. 
	pages = boot_alloc(sizeof(struct PageInfo) * npages);   
f01016ab:	a1 88 be 22 f0       	mov    0xf022be88,%eax
f01016b0:	c1 e0 03             	shl    $0x3,%eax
f01016b3:	e8 7c f4 ff ff       	call   f0100b34 <boot_alloc>
f01016b8:	a3 90 be 22 f0       	mov    %eax,0xf022be90
	memset(pages, 0, sizeof(struct PageInfo) * npages); //Clear the memory 
f01016bd:	8b 0d 88 be 22 f0    	mov    0xf022be88,%ecx
f01016c3:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01016ca:	89 54 24 08          	mov    %edx,0x8(%esp)
f01016ce:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01016d5:	00 
f01016d6:	89 04 24             	mov    %eax,(%esp)
f01016d9:	e8 99 42 00 00       	call   f0105977 <memset>
	// The kernel uses this array to keep track of environment array:
	// 'NENV' is the number of Environments in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = boot_alloc(sizeof(struct Env)*NENV);
f01016de:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f01016e3:	e8 4c f4 ff ff       	call   f0100b34 <boot_alloc>
f01016e8:	a3 4c b2 22 f0       	mov    %eax,0xf022b24c
	memset(envs,0,sizeof(struct Env)*NENV);
f01016ed:	c7 44 24 08 00 f0 01 	movl   $0x1f000,0x8(%esp)
f01016f4:	00 
f01016f5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01016fc:	00 
f01016fd:	89 04 24             	mov    %eax,(%esp)
f0101700:	e8 72 42 00 00       	call   f0105977 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101705:	e8 5b f8 ff ff       	call   f0100f65 <page_init>

	check_page_free_list(1);
f010170a:	b8 01 00 00 00       	mov    $0x1,%eax
f010170f:	e8 a5 f4 ff ff       	call   f0100bb9 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101714:	83 3d 90 be 22 f0 00 	cmpl   $0x0,0xf022be90
f010171b:	75 1c                	jne    f0101739 <mem_init+0x1b4>
		panic("'pages' is a null pointer!");
f010171d:	c7 44 24 08 55 77 10 	movl   $0xf0107755,0x8(%esp)
f0101724:	f0 
f0101725:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f010172c:	00 
f010172d:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101734:	e8 07 e9 ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101739:	a1 44 b2 22 f0       	mov    0xf022b244,%eax
f010173e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101743:	eb 05                	jmp    f010174a <mem_init+0x1c5>
		++nfree;
f0101745:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101748:	8b 00                	mov    (%eax),%eax
f010174a:	85 c0                	test   %eax,%eax
f010174c:	75 f7                	jne    f0101745 <mem_init+0x1c0>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010174e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101755:	e8 9d f9 ff ff       	call   f01010f7 <page_alloc>
f010175a:	89 c7                	mov    %eax,%edi
f010175c:	85 c0                	test   %eax,%eax
f010175e:	75 24                	jne    f0101784 <mem_init+0x1ff>
f0101760:	c7 44 24 0c 70 77 10 	movl   $0xf0107770,0xc(%esp)
f0101767:	f0 
f0101768:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f010176f:	f0 
f0101770:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f0101777:	00 
f0101778:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f010177f:	e8 bc e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101784:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010178b:	e8 67 f9 ff ff       	call   f01010f7 <page_alloc>
f0101790:	89 c6                	mov    %eax,%esi
f0101792:	85 c0                	test   %eax,%eax
f0101794:	75 24                	jne    f01017ba <mem_init+0x235>
f0101796:	c7 44 24 0c 86 77 10 	movl   $0xf0107786,0xc(%esp)
f010179d:	f0 
f010179e:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01017a5:	f0 
f01017a6:	c7 44 24 04 8d 03 00 	movl   $0x38d,0x4(%esp)
f01017ad:	00 
f01017ae:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01017b5:	e8 86 e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01017ba:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017c1:	e8 31 f9 ff ff       	call   f01010f7 <page_alloc>
f01017c6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01017c9:	85 c0                	test   %eax,%eax
f01017cb:	75 24                	jne    f01017f1 <mem_init+0x26c>
f01017cd:	c7 44 24 0c 9c 77 10 	movl   $0xf010779c,0xc(%esp)
f01017d4:	f0 
f01017d5:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01017dc:	f0 
f01017dd:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f01017e4:	00 
f01017e5:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01017ec:	e8 4f e8 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01017f1:	39 f7                	cmp    %esi,%edi
f01017f3:	75 24                	jne    f0101819 <mem_init+0x294>
f01017f5:	c7 44 24 0c b2 77 10 	movl   $0xf01077b2,0xc(%esp)
f01017fc:	f0 
f01017fd:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101804:	f0 
f0101805:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f010180c:	00 
f010180d:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101814:	e8 27 e8 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101819:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010181c:	39 c6                	cmp    %eax,%esi
f010181e:	74 04                	je     f0101824 <mem_init+0x29f>
f0101820:	39 c7                	cmp    %eax,%edi
f0101822:	75 24                	jne    f0101848 <mem_init+0x2c3>
f0101824:	c7 44 24 0c 78 6e 10 	movl   $0xf0106e78,0xc(%esp)
f010182b:	f0 
f010182c:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101833:	f0 
f0101834:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f010183b:	00 
f010183c:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101843:	e8 f8 e7 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101848:	8b 15 90 be 22 f0    	mov    0xf022be90,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f010184e:	a1 88 be 22 f0       	mov    0xf022be88,%eax
f0101853:	c1 e0 0c             	shl    $0xc,%eax
f0101856:	89 f9                	mov    %edi,%ecx
f0101858:	29 d1                	sub    %edx,%ecx
f010185a:	c1 f9 03             	sar    $0x3,%ecx
f010185d:	c1 e1 0c             	shl    $0xc,%ecx
f0101860:	39 c1                	cmp    %eax,%ecx
f0101862:	72 24                	jb     f0101888 <mem_init+0x303>
f0101864:	c7 44 24 0c c4 77 10 	movl   $0xf01077c4,0xc(%esp)
f010186b:	f0 
f010186c:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101873:	f0 
f0101874:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f010187b:	00 
f010187c:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101883:	e8 b8 e7 ff ff       	call   f0100040 <_panic>
f0101888:	89 f1                	mov    %esi,%ecx
f010188a:	29 d1                	sub    %edx,%ecx
f010188c:	c1 f9 03             	sar    $0x3,%ecx
f010188f:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101892:	39 c8                	cmp    %ecx,%eax
f0101894:	77 24                	ja     f01018ba <mem_init+0x335>
f0101896:	c7 44 24 0c e1 77 10 	movl   $0xf01077e1,0xc(%esp)
f010189d:	f0 
f010189e:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01018a5:	f0 
f01018a6:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f01018ad:	00 
f01018ae:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01018b5:	e8 86 e7 ff ff       	call   f0100040 <_panic>
f01018ba:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01018bd:	29 d1                	sub    %edx,%ecx
f01018bf:	89 ca                	mov    %ecx,%edx
f01018c1:	c1 fa 03             	sar    $0x3,%edx
f01018c4:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f01018c7:	39 d0                	cmp    %edx,%eax
f01018c9:	77 24                	ja     f01018ef <mem_init+0x36a>
f01018cb:	c7 44 24 0c fe 77 10 	movl   $0xf01077fe,0xc(%esp)
f01018d2:	f0 
f01018d3:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01018da:	f0 
f01018db:	c7 44 24 04 95 03 00 	movl   $0x395,0x4(%esp)
f01018e2:	00 
f01018e3:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01018ea:	e8 51 e7 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01018ef:	a1 44 b2 22 f0       	mov    0xf022b244,%eax
f01018f4:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01018f7:	c7 05 44 b2 22 f0 00 	movl   $0x0,0xf022b244
f01018fe:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101901:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101908:	e8 ea f7 ff ff       	call   f01010f7 <page_alloc>
f010190d:	85 c0                	test   %eax,%eax
f010190f:	74 24                	je     f0101935 <mem_init+0x3b0>
f0101911:	c7 44 24 0c 1b 78 10 	movl   $0xf010781b,0xc(%esp)
f0101918:	f0 
f0101919:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101920:	f0 
f0101921:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f0101928:	00 
f0101929:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101930:	e8 0b e7 ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101935:	89 3c 24             	mov    %edi,(%esp)
f0101938:	e8 4b f8 ff ff       	call   f0101188 <page_free>
	page_free(pp1);
f010193d:	89 34 24             	mov    %esi,(%esp)
f0101940:	e8 43 f8 ff ff       	call   f0101188 <page_free>
	page_free(pp2);
f0101945:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101948:	89 04 24             	mov    %eax,(%esp)
f010194b:	e8 38 f8 ff ff       	call   f0101188 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101950:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101957:	e8 9b f7 ff ff       	call   f01010f7 <page_alloc>
f010195c:	89 c6                	mov    %eax,%esi
f010195e:	85 c0                	test   %eax,%eax
f0101960:	75 24                	jne    f0101986 <mem_init+0x401>
f0101962:	c7 44 24 0c 70 77 10 	movl   $0xf0107770,0xc(%esp)
f0101969:	f0 
f010196a:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101971:	f0 
f0101972:	c7 44 24 04 a3 03 00 	movl   $0x3a3,0x4(%esp)
f0101979:	00 
f010197a:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101981:	e8 ba e6 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101986:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010198d:	e8 65 f7 ff ff       	call   f01010f7 <page_alloc>
f0101992:	89 c7                	mov    %eax,%edi
f0101994:	85 c0                	test   %eax,%eax
f0101996:	75 24                	jne    f01019bc <mem_init+0x437>
f0101998:	c7 44 24 0c 86 77 10 	movl   $0xf0107786,0xc(%esp)
f010199f:	f0 
f01019a0:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01019a7:	f0 
f01019a8:	c7 44 24 04 a4 03 00 	movl   $0x3a4,0x4(%esp)
f01019af:	00 
f01019b0:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01019b7:	e8 84 e6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01019bc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019c3:	e8 2f f7 ff ff       	call   f01010f7 <page_alloc>
f01019c8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01019cb:	85 c0                	test   %eax,%eax
f01019cd:	75 24                	jne    f01019f3 <mem_init+0x46e>
f01019cf:	c7 44 24 0c 9c 77 10 	movl   $0xf010779c,0xc(%esp)
f01019d6:	f0 
f01019d7:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01019de:	f0 
f01019df:	c7 44 24 04 a5 03 00 	movl   $0x3a5,0x4(%esp)
f01019e6:	00 
f01019e7:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01019ee:	e8 4d e6 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01019f3:	39 fe                	cmp    %edi,%esi
f01019f5:	75 24                	jne    f0101a1b <mem_init+0x496>
f01019f7:	c7 44 24 0c b2 77 10 	movl   $0xf01077b2,0xc(%esp)
f01019fe:	f0 
f01019ff:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101a06:	f0 
f0101a07:	c7 44 24 04 a7 03 00 	movl   $0x3a7,0x4(%esp)
f0101a0e:	00 
f0101a0f:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101a16:	e8 25 e6 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a1b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a1e:	39 c7                	cmp    %eax,%edi
f0101a20:	74 04                	je     f0101a26 <mem_init+0x4a1>
f0101a22:	39 c6                	cmp    %eax,%esi
f0101a24:	75 24                	jne    f0101a4a <mem_init+0x4c5>
f0101a26:	c7 44 24 0c 78 6e 10 	movl   $0xf0106e78,0xc(%esp)
f0101a2d:	f0 
f0101a2e:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101a35:	f0 
f0101a36:	c7 44 24 04 a8 03 00 	movl   $0x3a8,0x4(%esp)
f0101a3d:	00 
f0101a3e:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101a45:	e8 f6 e5 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101a4a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a51:	e8 a1 f6 ff ff       	call   f01010f7 <page_alloc>
f0101a56:	85 c0                	test   %eax,%eax
f0101a58:	74 24                	je     f0101a7e <mem_init+0x4f9>
f0101a5a:	c7 44 24 0c 1b 78 10 	movl   $0xf010781b,0xc(%esp)
f0101a61:	f0 
f0101a62:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101a69:	f0 
f0101a6a:	c7 44 24 04 a9 03 00 	movl   $0x3a9,0x4(%esp)
f0101a71:	00 
f0101a72:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101a79:	e8 c2 e5 ff ff       	call   f0100040 <_panic>
f0101a7e:	89 f0                	mov    %esi,%eax
f0101a80:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f0101a86:	c1 f8 03             	sar    $0x3,%eax
f0101a89:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101a8c:	89 c2                	mov    %eax,%edx
f0101a8e:	c1 ea 0c             	shr    $0xc,%edx
f0101a91:	3b 15 88 be 22 f0    	cmp    0xf022be88,%edx
f0101a97:	72 20                	jb     f0101ab9 <mem_init+0x534>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101a99:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101a9d:	c7 44 24 08 e4 66 10 	movl   $0xf01066e4,0x8(%esp)
f0101aa4:	f0 
f0101aa5:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0101aac:	00 
f0101aad:	c7 04 24 55 76 10 f0 	movl   $0xf0107655,(%esp)
f0101ab4:	e8 87 e5 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101ab9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101ac0:	00 
f0101ac1:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101ac8:	00 
	return (void *)(pa + KERNBASE);
f0101ac9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101ace:	89 04 24             	mov    %eax,(%esp)
f0101ad1:	e8 a1 3e 00 00       	call   f0105977 <memset>
	page_free(pp0);
f0101ad6:	89 34 24             	mov    %esi,(%esp)
f0101ad9:	e8 aa f6 ff ff       	call   f0101188 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101ade:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101ae5:	e8 0d f6 ff ff       	call   f01010f7 <page_alloc>
f0101aea:	85 c0                	test   %eax,%eax
f0101aec:	75 24                	jne    f0101b12 <mem_init+0x58d>
f0101aee:	c7 44 24 0c 2a 78 10 	movl   $0xf010782a,0xc(%esp)
f0101af5:	f0 
f0101af6:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101afd:	f0 
f0101afe:	c7 44 24 04 ae 03 00 	movl   $0x3ae,0x4(%esp)
f0101b05:	00 
f0101b06:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101b0d:	e8 2e e5 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101b12:	39 c6                	cmp    %eax,%esi
f0101b14:	74 24                	je     f0101b3a <mem_init+0x5b5>
f0101b16:	c7 44 24 0c 48 78 10 	movl   $0xf0107848,0xc(%esp)
f0101b1d:	f0 
f0101b1e:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101b25:	f0 
f0101b26:	c7 44 24 04 af 03 00 	movl   $0x3af,0x4(%esp)
f0101b2d:	00 
f0101b2e:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101b35:	e8 06 e5 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101b3a:	89 f0                	mov    %esi,%eax
f0101b3c:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f0101b42:	c1 f8 03             	sar    $0x3,%eax
f0101b45:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101b48:	89 c2                	mov    %eax,%edx
f0101b4a:	c1 ea 0c             	shr    $0xc,%edx
f0101b4d:	3b 15 88 be 22 f0    	cmp    0xf022be88,%edx
f0101b53:	72 20                	jb     f0101b75 <mem_init+0x5f0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101b55:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101b59:	c7 44 24 08 e4 66 10 	movl   $0xf01066e4,0x8(%esp)
f0101b60:	f0 
f0101b61:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0101b68:	00 
f0101b69:	c7 04 24 55 76 10 f0 	movl   $0xf0107655,(%esp)
f0101b70:	e8 cb e4 ff ff       	call   f0100040 <_panic>
f0101b75:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101b7b:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101b81:	80 38 00             	cmpb   $0x0,(%eax)
f0101b84:	74 24                	je     f0101baa <mem_init+0x625>
f0101b86:	c7 44 24 0c 58 78 10 	movl   $0xf0107858,0xc(%esp)
f0101b8d:	f0 
f0101b8e:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101b95:	f0 
f0101b96:	c7 44 24 04 b2 03 00 	movl   $0x3b2,0x4(%esp)
f0101b9d:	00 
f0101b9e:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101ba5:	e8 96 e4 ff ff       	call   f0100040 <_panic>
f0101baa:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101bad:	39 d0                	cmp    %edx,%eax
f0101baf:	75 d0                	jne    f0101b81 <mem_init+0x5fc>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101bb1:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101bb4:	a3 44 b2 22 f0       	mov    %eax,0xf022b244

	// free the pages we took
	page_free(pp0);
f0101bb9:	89 34 24             	mov    %esi,(%esp)
f0101bbc:	e8 c7 f5 ff ff       	call   f0101188 <page_free>
	page_free(pp1);
f0101bc1:	89 3c 24             	mov    %edi,(%esp)
f0101bc4:	e8 bf f5 ff ff       	call   f0101188 <page_free>
	page_free(pp2);
f0101bc9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101bcc:	89 04 24             	mov    %eax,(%esp)
f0101bcf:	e8 b4 f5 ff ff       	call   f0101188 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101bd4:	a1 44 b2 22 f0       	mov    0xf022b244,%eax
f0101bd9:	eb 05                	jmp    f0101be0 <mem_init+0x65b>
		--nfree;
f0101bdb:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101bde:	8b 00                	mov    (%eax),%eax
f0101be0:	85 c0                	test   %eax,%eax
f0101be2:	75 f7                	jne    f0101bdb <mem_init+0x656>
		--nfree;
	assert(nfree == 0);
f0101be4:	85 db                	test   %ebx,%ebx
f0101be6:	74 24                	je     f0101c0c <mem_init+0x687>
f0101be8:	c7 44 24 0c 62 78 10 	movl   $0xf0107862,0xc(%esp)
f0101bef:	f0 
f0101bf0:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101bf7:	f0 
f0101bf8:	c7 44 24 04 bf 03 00 	movl   $0x3bf,0x4(%esp)
f0101bff:	00 
f0101c00:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101c07:	e8 34 e4 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101c0c:	c7 04 24 98 6e 10 f0 	movl   $0xf0106e98,(%esp)
f0101c13:	e8 a4 24 00 00       	call   f01040bc <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101c18:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c1f:	e8 d3 f4 ff ff       	call   f01010f7 <page_alloc>
f0101c24:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101c27:	85 c0                	test   %eax,%eax
f0101c29:	75 24                	jne    f0101c4f <mem_init+0x6ca>
f0101c2b:	c7 44 24 0c 70 77 10 	movl   $0xf0107770,0xc(%esp)
f0101c32:	f0 
f0101c33:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101c3a:	f0 
f0101c3b:	c7 44 24 04 25 04 00 	movl   $0x425,0x4(%esp)
f0101c42:	00 
f0101c43:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101c4a:	e8 f1 e3 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101c4f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c56:	e8 9c f4 ff ff       	call   f01010f7 <page_alloc>
f0101c5b:	89 c3                	mov    %eax,%ebx
f0101c5d:	85 c0                	test   %eax,%eax
f0101c5f:	75 24                	jne    f0101c85 <mem_init+0x700>
f0101c61:	c7 44 24 0c 86 77 10 	movl   $0xf0107786,0xc(%esp)
f0101c68:	f0 
f0101c69:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101c70:	f0 
f0101c71:	c7 44 24 04 26 04 00 	movl   $0x426,0x4(%esp)
f0101c78:	00 
f0101c79:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101c80:	e8 bb e3 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101c85:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c8c:	e8 66 f4 ff ff       	call   f01010f7 <page_alloc>
f0101c91:	89 c6                	mov    %eax,%esi
f0101c93:	85 c0                	test   %eax,%eax
f0101c95:	75 24                	jne    f0101cbb <mem_init+0x736>
f0101c97:	c7 44 24 0c 9c 77 10 	movl   $0xf010779c,0xc(%esp)
f0101c9e:	f0 
f0101c9f:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101ca6:	f0 
f0101ca7:	c7 44 24 04 27 04 00 	movl   $0x427,0x4(%esp)
f0101cae:	00 
f0101caf:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101cb6:	e8 85 e3 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101cbb:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101cbe:	75 24                	jne    f0101ce4 <mem_init+0x75f>
f0101cc0:	c7 44 24 0c b2 77 10 	movl   $0xf01077b2,0xc(%esp)
f0101cc7:	f0 
f0101cc8:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101ccf:	f0 
f0101cd0:	c7 44 24 04 2a 04 00 	movl   $0x42a,0x4(%esp)
f0101cd7:	00 
f0101cd8:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101cdf:	e8 5c e3 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101ce4:	39 c3                	cmp    %eax,%ebx
f0101ce6:	74 05                	je     f0101ced <mem_init+0x768>
f0101ce8:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101ceb:	75 24                	jne    f0101d11 <mem_init+0x78c>
f0101ced:	c7 44 24 0c 78 6e 10 	movl   $0xf0106e78,0xc(%esp)
f0101cf4:	f0 
f0101cf5:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101cfc:	f0 
f0101cfd:	c7 44 24 04 2b 04 00 	movl   $0x42b,0x4(%esp)
f0101d04:	00 
f0101d05:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101d0c:	e8 2f e3 ff ff       	call   f0100040 <_panic>
	

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101d11:	a1 44 b2 22 f0       	mov    0xf022b244,%eax
f0101d16:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101d19:	c7 05 44 b2 22 f0 00 	movl   $0x0,0xf022b244
f0101d20:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101d23:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d2a:	e8 c8 f3 ff ff       	call   f01010f7 <page_alloc>
f0101d2f:	85 c0                	test   %eax,%eax
f0101d31:	74 24                	je     f0101d57 <mem_init+0x7d2>
f0101d33:	c7 44 24 0c 1b 78 10 	movl   $0xf010781b,0xc(%esp)
f0101d3a:	f0 
f0101d3b:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101d42:	f0 
f0101d43:	c7 44 24 04 33 04 00 	movl   $0x433,0x4(%esp)
f0101d4a:	00 
f0101d4b:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101d52:	e8 e9 e2 ff ff       	call   f0100040 <_panic>
	
	
	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101d57:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101d5a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101d5e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101d65:	00 
f0101d66:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0101d6b:	89 04 24             	mov    %eax,(%esp)
f0101d6e:	e8 34 f6 ff ff       	call   f01013a7 <page_lookup>
f0101d73:	85 c0                	test   %eax,%eax
f0101d75:	74 24                	je     f0101d9b <mem_init+0x816>
f0101d77:	c7 44 24 0c b8 6e 10 	movl   $0xf0106eb8,0xc(%esp)
f0101d7e:	f0 
f0101d7f:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101d86:	f0 
f0101d87:	c7 44 24 04 37 04 00 	movl   $0x437,0x4(%esp)
f0101d8e:	00 
f0101d8f:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101d96:	e8 a5 e2 ff ff       	call   f0100040 <_panic>
	
	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101d9b:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101da2:	00 
f0101da3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101daa:	00 
f0101dab:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101daf:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0101db4:	89 04 24             	mov    %eax,(%esp)
f0101db7:	e8 bf f6 ff ff       	call   f010147b <page_insert>
f0101dbc:	85 c0                	test   %eax,%eax
f0101dbe:	78 24                	js     f0101de4 <mem_init+0x85f>
f0101dc0:	c7 44 24 0c f0 6e 10 	movl   $0xf0106ef0,0xc(%esp)
f0101dc7:	f0 
f0101dc8:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101dcf:	f0 
f0101dd0:	c7 44 24 04 3a 04 00 	movl   $0x43a,0x4(%esp)
f0101dd7:	00 
f0101dd8:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101ddf:	e8 5c e2 ff ff       	call   f0100040 <_panic>
	
	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101de4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101de7:	89 04 24             	mov    %eax,(%esp)
f0101dea:	e8 99 f3 ff ff       	call   f0101188 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101def:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101df6:	00 
f0101df7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101dfe:	00 
f0101dff:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101e03:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0101e08:	89 04 24             	mov    %eax,(%esp)
f0101e0b:	e8 6b f6 ff ff       	call   f010147b <page_insert>
f0101e10:	85 c0                	test   %eax,%eax
f0101e12:	74 24                	je     f0101e38 <mem_init+0x8b3>
f0101e14:	c7 44 24 0c 20 6f 10 	movl   $0xf0106f20,0xc(%esp)
f0101e1b:	f0 
f0101e1c:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101e23:	f0 
f0101e24:	c7 44 24 04 3e 04 00 	movl   $0x43e,0x4(%esp)
f0101e2b:	00 
f0101e2c:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101e33:	e8 08 e2 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e38:	8b 3d 8c be 22 f0    	mov    0xf022be8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101e3e:	a1 90 be 22 f0       	mov    0xf022be90,%eax
f0101e43:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e46:	8b 17                	mov    (%edi),%edx
f0101e48:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101e4e:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101e51:	29 c1                	sub    %eax,%ecx
f0101e53:	89 c8                	mov    %ecx,%eax
f0101e55:	c1 f8 03             	sar    $0x3,%eax
f0101e58:	c1 e0 0c             	shl    $0xc,%eax
f0101e5b:	39 c2                	cmp    %eax,%edx
f0101e5d:	74 24                	je     f0101e83 <mem_init+0x8fe>
f0101e5f:	c7 44 24 0c 50 6f 10 	movl   $0xf0106f50,0xc(%esp)
f0101e66:	f0 
f0101e67:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101e6e:	f0 
f0101e6f:	c7 44 24 04 3f 04 00 	movl   $0x43f,0x4(%esp)
f0101e76:	00 
f0101e77:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101e7e:	e8 bd e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101e83:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e88:	89 f8                	mov    %edi,%eax
f0101e8a:	e8 36 ec ff ff       	call   f0100ac5 <check_va2pa>
f0101e8f:	89 da                	mov    %ebx,%edx
f0101e91:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101e94:	c1 fa 03             	sar    $0x3,%edx
f0101e97:	c1 e2 0c             	shl    $0xc,%edx
f0101e9a:	39 d0                	cmp    %edx,%eax
f0101e9c:	74 24                	je     f0101ec2 <mem_init+0x93d>
f0101e9e:	c7 44 24 0c 78 6f 10 	movl   $0xf0106f78,0xc(%esp)
f0101ea5:	f0 
f0101ea6:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101ead:	f0 
f0101eae:	c7 44 24 04 40 04 00 	movl   $0x440,0x4(%esp)
f0101eb5:	00 
f0101eb6:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101ebd:	e8 7e e1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101ec2:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ec7:	74 24                	je     f0101eed <mem_init+0x968>
f0101ec9:	c7 44 24 0c 6d 78 10 	movl   $0xf010786d,0xc(%esp)
f0101ed0:	f0 
f0101ed1:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101ed8:	f0 
f0101ed9:	c7 44 24 04 41 04 00 	movl   $0x441,0x4(%esp)
f0101ee0:	00 
f0101ee1:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101ee8:	e8 53 e1 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101eed:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ef0:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ef5:	74 24                	je     f0101f1b <mem_init+0x996>
f0101ef7:	c7 44 24 0c 7e 78 10 	movl   $0xf010787e,0xc(%esp)
f0101efe:	f0 
f0101eff:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101f06:	f0 
f0101f07:	c7 44 24 04 42 04 00 	movl   $0x442,0x4(%esp)
f0101f0e:	00 
f0101f0f:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101f16:	e8 25 e1 ff ff       	call   f0100040 <_panic>
	
	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101f1b:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f22:	00 
f0101f23:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f2a:	00 
f0101f2b:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101f2f:	89 3c 24             	mov    %edi,(%esp)
f0101f32:	e8 44 f5 ff ff       	call   f010147b <page_insert>
f0101f37:	85 c0                	test   %eax,%eax
f0101f39:	74 24                	je     f0101f5f <mem_init+0x9da>
f0101f3b:	c7 44 24 0c a8 6f 10 	movl   $0xf0106fa8,0xc(%esp)
f0101f42:	f0 
f0101f43:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101f4a:	f0 
f0101f4b:	c7 44 24 04 45 04 00 	movl   $0x445,0x4(%esp)
f0101f52:	00 
f0101f53:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101f5a:	e8 e1 e0 ff ff       	call   f0100040 <_panic>

	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101f5f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f64:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0101f69:	e8 57 eb ff ff       	call   f0100ac5 <check_va2pa>
f0101f6e:	89 f2                	mov    %esi,%edx
f0101f70:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
f0101f76:	c1 fa 03             	sar    $0x3,%edx
f0101f79:	c1 e2 0c             	shl    $0xc,%edx
f0101f7c:	39 d0                	cmp    %edx,%eax
f0101f7e:	74 24                	je     f0101fa4 <mem_init+0xa1f>
f0101f80:	c7 44 24 0c e4 6f 10 	movl   $0xf0106fe4,0xc(%esp)
f0101f87:	f0 
f0101f88:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101f8f:	f0 
f0101f90:	c7 44 24 04 47 04 00 	movl   $0x447,0x4(%esp)
f0101f97:	00 
f0101f98:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101f9f:	e8 9c e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101fa4:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101fa9:	74 24                	je     f0101fcf <mem_init+0xa4a>
f0101fab:	c7 44 24 0c 8f 78 10 	movl   $0xf010788f,0xc(%esp)
f0101fb2:	f0 
f0101fb3:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101fba:	f0 
f0101fbb:	c7 44 24 04 48 04 00 	movl   $0x448,0x4(%esp)
f0101fc2:	00 
f0101fc3:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101fca:	e8 71 e0 ff ff       	call   f0100040 <_panic>
	
	// should be no free memory
	assert(!page_alloc(0));
f0101fcf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101fd6:	e8 1c f1 ff ff       	call   f01010f7 <page_alloc>
f0101fdb:	85 c0                	test   %eax,%eax
f0101fdd:	74 24                	je     f0102003 <mem_init+0xa7e>
f0101fdf:	c7 44 24 0c 1b 78 10 	movl   $0xf010781b,0xc(%esp)
f0101fe6:	f0 
f0101fe7:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0101fee:	f0 
f0101fef:	c7 44 24 04 4b 04 00 	movl   $0x44b,0x4(%esp)
f0101ff6:	00 
f0101ff7:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0101ffe:	e8 3d e0 ff ff       	call   f0100040 <_panic>
	
	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102003:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010200a:	00 
f010200b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102012:	00 
f0102013:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102017:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f010201c:	89 04 24             	mov    %eax,(%esp)
f010201f:	e8 57 f4 ff ff       	call   f010147b <page_insert>
f0102024:	85 c0                	test   %eax,%eax
f0102026:	74 24                	je     f010204c <mem_init+0xac7>
f0102028:	c7 44 24 0c a8 6f 10 	movl   $0xf0106fa8,0xc(%esp)
f010202f:	f0 
f0102030:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102037:	f0 
f0102038:	c7 44 24 04 4e 04 00 	movl   $0x44e,0x4(%esp)
f010203f:	00 
f0102040:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102047:	e8 f4 df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010204c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102051:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102056:	e8 6a ea ff ff       	call   f0100ac5 <check_va2pa>
f010205b:	89 f2                	mov    %esi,%edx
f010205d:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
f0102063:	c1 fa 03             	sar    $0x3,%edx
f0102066:	c1 e2 0c             	shl    $0xc,%edx
f0102069:	39 d0                	cmp    %edx,%eax
f010206b:	74 24                	je     f0102091 <mem_init+0xb0c>
f010206d:	c7 44 24 0c e4 6f 10 	movl   $0xf0106fe4,0xc(%esp)
f0102074:	f0 
f0102075:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f010207c:	f0 
f010207d:	c7 44 24 04 4f 04 00 	movl   $0x44f,0x4(%esp)
f0102084:	00 
f0102085:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f010208c:	e8 af df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102091:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102096:	74 24                	je     f01020bc <mem_init+0xb37>
f0102098:	c7 44 24 0c 8f 78 10 	movl   $0xf010788f,0xc(%esp)
f010209f:	f0 
f01020a0:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01020a7:	f0 
f01020a8:	c7 44 24 04 50 04 00 	movl   $0x450,0x4(%esp)
f01020af:	00 
f01020b0:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01020b7:	e8 84 df ff ff       	call   f0100040 <_panic>
	
	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01020bc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01020c3:	e8 2f f0 ff ff       	call   f01010f7 <page_alloc>
f01020c8:	85 c0                	test   %eax,%eax
f01020ca:	74 24                	je     f01020f0 <mem_init+0xb6b>
f01020cc:	c7 44 24 0c 1b 78 10 	movl   $0xf010781b,0xc(%esp)
f01020d3:	f0 
f01020d4:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01020db:	f0 
f01020dc:	c7 44 24 04 54 04 00 	movl   $0x454,0x4(%esp)
f01020e3:	00 
f01020e4:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01020eb:	e8 50 df ff ff       	call   f0100040 <_panic>
	
	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01020f0:	8b 15 8c be 22 f0    	mov    0xf022be8c,%edx
f01020f6:	8b 02                	mov    (%edx),%eax
f01020f8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01020fd:	89 c1                	mov    %eax,%ecx
f01020ff:	c1 e9 0c             	shr    $0xc,%ecx
f0102102:	3b 0d 88 be 22 f0    	cmp    0xf022be88,%ecx
f0102108:	72 20                	jb     f010212a <mem_init+0xba5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010210a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010210e:	c7 44 24 08 e4 66 10 	movl   $0xf01066e4,0x8(%esp)
f0102115:	f0 
f0102116:	c7 44 24 04 57 04 00 	movl   $0x457,0x4(%esp)
f010211d:	00 
f010211e:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102125:	e8 16 df ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010212a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010212f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102132:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102139:	00 
f010213a:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102141:	00 
f0102142:	89 14 24             	mov    %edx,(%esp)
f0102145:	e8 bc f0 ff ff       	call   f0101206 <pgdir_walk>
f010214a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010214d:	8d 51 04             	lea    0x4(%ecx),%edx
f0102150:	39 d0                	cmp    %edx,%eax
f0102152:	74 24                	je     f0102178 <mem_init+0xbf3>
f0102154:	c7 44 24 0c 14 70 10 	movl   $0xf0107014,0xc(%esp)
f010215b:	f0 
f010215c:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102163:	f0 
f0102164:	c7 44 24 04 58 04 00 	movl   $0x458,0x4(%esp)
f010216b:	00 
f010216c:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102173:	e8 c8 de ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102178:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f010217f:	00 
f0102180:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102187:	00 
f0102188:	89 74 24 04          	mov    %esi,0x4(%esp)
f010218c:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102191:	89 04 24             	mov    %eax,(%esp)
f0102194:	e8 e2 f2 ff ff       	call   f010147b <page_insert>
f0102199:	85 c0                	test   %eax,%eax
f010219b:	74 24                	je     f01021c1 <mem_init+0xc3c>
f010219d:	c7 44 24 0c 54 70 10 	movl   $0xf0107054,0xc(%esp)
f01021a4:	f0 
f01021a5:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01021ac:	f0 
f01021ad:	c7 44 24 04 5b 04 00 	movl   $0x45b,0x4(%esp)
f01021b4:	00 
f01021b5:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01021bc:	e8 7f de ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01021c1:	8b 3d 8c be 22 f0    	mov    0xf022be8c,%edi
f01021c7:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021cc:	89 f8                	mov    %edi,%eax
f01021ce:	e8 f2 e8 ff ff       	call   f0100ac5 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01021d3:	89 f2                	mov    %esi,%edx
f01021d5:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
f01021db:	c1 fa 03             	sar    $0x3,%edx
f01021de:	c1 e2 0c             	shl    $0xc,%edx
f01021e1:	39 d0                	cmp    %edx,%eax
f01021e3:	74 24                	je     f0102209 <mem_init+0xc84>
f01021e5:	c7 44 24 0c e4 6f 10 	movl   $0xf0106fe4,0xc(%esp)
f01021ec:	f0 
f01021ed:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01021f4:	f0 
f01021f5:	c7 44 24 04 5c 04 00 	movl   $0x45c,0x4(%esp)
f01021fc:	00 
f01021fd:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102204:	e8 37 de ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102209:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010220e:	74 24                	je     f0102234 <mem_init+0xcaf>
f0102210:	c7 44 24 0c 8f 78 10 	movl   $0xf010788f,0xc(%esp)
f0102217:	f0 
f0102218:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f010221f:	f0 
f0102220:	c7 44 24 04 5d 04 00 	movl   $0x45d,0x4(%esp)
f0102227:	00 
f0102228:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f010222f:	e8 0c de ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102234:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010223b:	00 
f010223c:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102243:	00 
f0102244:	89 3c 24             	mov    %edi,(%esp)
f0102247:	e8 ba ef ff ff       	call   f0101206 <pgdir_walk>
f010224c:	f6 00 04             	testb  $0x4,(%eax)
f010224f:	75 24                	jne    f0102275 <mem_init+0xcf0>
f0102251:	c7 44 24 0c 94 70 10 	movl   $0xf0107094,0xc(%esp)
f0102258:	f0 
f0102259:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102260:	f0 
f0102261:	c7 44 24 04 5e 04 00 	movl   $0x45e,0x4(%esp)
f0102268:	00 
f0102269:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102270:	e8 cb dd ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102275:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f010227a:	f6 00 04             	testb  $0x4,(%eax)
f010227d:	75 24                	jne    f01022a3 <mem_init+0xd1e>
f010227f:	c7 44 24 0c a0 78 10 	movl   $0xf01078a0,0xc(%esp)
f0102286:	f0 
f0102287:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f010228e:	f0 
f010228f:	c7 44 24 04 5f 04 00 	movl   $0x45f,0x4(%esp)
f0102296:	00 
f0102297:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f010229e:	e8 9d dd ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01022a3:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01022aa:	00 
f01022ab:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01022b2:	00 
f01022b3:	89 74 24 04          	mov    %esi,0x4(%esp)
f01022b7:	89 04 24             	mov    %eax,(%esp)
f01022ba:	e8 bc f1 ff ff       	call   f010147b <page_insert>
f01022bf:	85 c0                	test   %eax,%eax
f01022c1:	74 24                	je     f01022e7 <mem_init+0xd62>
f01022c3:	c7 44 24 0c a8 6f 10 	movl   $0xf0106fa8,0xc(%esp)
f01022ca:	f0 
f01022cb:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01022d2:	f0 
f01022d3:	c7 44 24 04 62 04 00 	movl   $0x462,0x4(%esp)
f01022da:	00 
f01022db:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01022e2:	e8 59 dd ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01022e7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01022ee:	00 
f01022ef:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01022f6:	00 
f01022f7:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f01022fc:	89 04 24             	mov    %eax,(%esp)
f01022ff:	e8 02 ef ff ff       	call   f0101206 <pgdir_walk>
f0102304:	f6 00 02             	testb  $0x2,(%eax)
f0102307:	75 24                	jne    f010232d <mem_init+0xda8>
f0102309:	c7 44 24 0c c8 70 10 	movl   $0xf01070c8,0xc(%esp)
f0102310:	f0 
f0102311:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102318:	f0 
f0102319:	c7 44 24 04 63 04 00 	movl   $0x463,0x4(%esp)
f0102320:	00 
f0102321:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102328:	e8 13 dd ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010232d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102334:	00 
f0102335:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010233c:	00 
f010233d:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102342:	89 04 24             	mov    %eax,(%esp)
f0102345:	e8 bc ee ff ff       	call   f0101206 <pgdir_walk>
f010234a:	f6 00 04             	testb  $0x4,(%eax)
f010234d:	74 24                	je     f0102373 <mem_init+0xdee>
f010234f:	c7 44 24 0c fc 70 10 	movl   $0xf01070fc,0xc(%esp)
f0102356:	f0 
f0102357:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f010235e:	f0 
f010235f:	c7 44 24 04 64 04 00 	movl   $0x464,0x4(%esp)
f0102366:	00 
f0102367:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f010236e:	e8 cd dc ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102373:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010237a:	00 
f010237b:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0102382:	00 
f0102383:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102386:	89 44 24 04          	mov    %eax,0x4(%esp)
f010238a:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f010238f:	89 04 24             	mov    %eax,(%esp)
f0102392:	e8 e4 f0 ff ff       	call   f010147b <page_insert>
f0102397:	85 c0                	test   %eax,%eax
f0102399:	78 24                	js     f01023bf <mem_init+0xe3a>
f010239b:	c7 44 24 0c 34 71 10 	movl   $0xf0107134,0xc(%esp)
f01023a2:	f0 
f01023a3:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01023aa:	f0 
f01023ab:	c7 44 24 04 67 04 00 	movl   $0x467,0x4(%esp)
f01023b2:	00 
f01023b3:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01023ba:	e8 81 dc ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01023bf:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01023c6:	00 
f01023c7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01023ce:	00 
f01023cf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01023d3:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f01023d8:	89 04 24             	mov    %eax,(%esp)
f01023db:	e8 9b f0 ff ff       	call   f010147b <page_insert>
f01023e0:	85 c0                	test   %eax,%eax
f01023e2:	74 24                	je     f0102408 <mem_init+0xe83>
f01023e4:	c7 44 24 0c 6c 71 10 	movl   $0xf010716c,0xc(%esp)
f01023eb:	f0 
f01023ec:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01023f3:	f0 
f01023f4:	c7 44 24 04 6a 04 00 	movl   $0x46a,0x4(%esp)
f01023fb:	00 
f01023fc:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102403:	e8 38 dc ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102408:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010240f:	00 
f0102410:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102417:	00 
f0102418:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f010241d:	89 04 24             	mov    %eax,(%esp)
f0102420:	e8 e1 ed ff ff       	call   f0101206 <pgdir_walk>
f0102425:	f6 00 04             	testb  $0x4,(%eax)
f0102428:	74 24                	je     f010244e <mem_init+0xec9>
f010242a:	c7 44 24 0c fc 70 10 	movl   $0xf01070fc,0xc(%esp)
f0102431:	f0 
f0102432:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102439:	f0 
f010243a:	c7 44 24 04 6b 04 00 	movl   $0x46b,0x4(%esp)
f0102441:	00 
f0102442:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102449:	e8 f2 db ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010244e:	8b 3d 8c be 22 f0    	mov    0xf022be8c,%edi
f0102454:	ba 00 00 00 00       	mov    $0x0,%edx
f0102459:	89 f8                	mov    %edi,%eax
f010245b:	e8 65 e6 ff ff       	call   f0100ac5 <check_va2pa>
f0102460:	89 c1                	mov    %eax,%ecx
f0102462:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102465:	89 d8                	mov    %ebx,%eax
f0102467:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f010246d:	c1 f8 03             	sar    $0x3,%eax
f0102470:	c1 e0 0c             	shl    $0xc,%eax
f0102473:	39 c1                	cmp    %eax,%ecx
f0102475:	74 24                	je     f010249b <mem_init+0xf16>
f0102477:	c7 44 24 0c a8 71 10 	movl   $0xf01071a8,0xc(%esp)
f010247e:	f0 
f010247f:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102486:	f0 
f0102487:	c7 44 24 04 6e 04 00 	movl   $0x46e,0x4(%esp)
f010248e:	00 
f010248f:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102496:	e8 a5 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010249b:	ba 00 10 00 00       	mov    $0x1000,%edx
f01024a0:	89 f8                	mov    %edi,%eax
f01024a2:	e8 1e e6 ff ff       	call   f0100ac5 <check_va2pa>
f01024a7:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f01024aa:	74 24                	je     f01024d0 <mem_init+0xf4b>
f01024ac:	c7 44 24 0c d4 71 10 	movl   $0xf01071d4,0xc(%esp)
f01024b3:	f0 
f01024b4:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01024bb:	f0 
f01024bc:	c7 44 24 04 6f 04 00 	movl   $0x46f,0x4(%esp)
f01024c3:	00 
f01024c4:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01024cb:	e8 70 db ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01024d0:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f01024d5:	74 24                	je     f01024fb <mem_init+0xf76>
f01024d7:	c7 44 24 0c b6 78 10 	movl   $0xf01078b6,0xc(%esp)
f01024de:	f0 
f01024df:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01024e6:	f0 
f01024e7:	c7 44 24 04 71 04 00 	movl   $0x471,0x4(%esp)
f01024ee:	00 
f01024ef:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01024f6:	e8 45 db ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01024fb:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102500:	74 24                	je     f0102526 <mem_init+0xfa1>
f0102502:	c7 44 24 0c c7 78 10 	movl   $0xf01078c7,0xc(%esp)
f0102509:	f0 
f010250a:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102511:	f0 
f0102512:	c7 44 24 04 72 04 00 	movl   $0x472,0x4(%esp)
f0102519:	00 
f010251a:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102521:	e8 1a db ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102526:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010252d:	e8 c5 eb ff ff       	call   f01010f7 <page_alloc>
f0102532:	85 c0                	test   %eax,%eax
f0102534:	74 04                	je     f010253a <mem_init+0xfb5>
f0102536:	39 c6                	cmp    %eax,%esi
f0102538:	74 24                	je     f010255e <mem_init+0xfd9>
f010253a:	c7 44 24 0c 04 72 10 	movl   $0xf0107204,0xc(%esp)
f0102541:	f0 
f0102542:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102549:	f0 
f010254a:	c7 44 24 04 75 04 00 	movl   $0x475,0x4(%esp)
f0102551:	00 
f0102552:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102559:	e8 e2 da ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010255e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102565:	00 
f0102566:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f010256b:	89 04 24             	mov    %eax,(%esp)
f010256e:	e8 bf ee ff ff       	call   f0101432 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102573:	8b 3d 8c be 22 f0    	mov    0xf022be8c,%edi
f0102579:	ba 00 00 00 00       	mov    $0x0,%edx
f010257e:	89 f8                	mov    %edi,%eax
f0102580:	e8 40 e5 ff ff       	call   f0100ac5 <check_va2pa>
f0102585:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102588:	74 24                	je     f01025ae <mem_init+0x1029>
f010258a:	c7 44 24 0c 28 72 10 	movl   $0xf0107228,0xc(%esp)
f0102591:	f0 
f0102592:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102599:	f0 
f010259a:	c7 44 24 04 79 04 00 	movl   $0x479,0x4(%esp)
f01025a1:	00 
f01025a2:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01025a9:	e8 92 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01025ae:	ba 00 10 00 00       	mov    $0x1000,%edx
f01025b3:	89 f8                	mov    %edi,%eax
f01025b5:	e8 0b e5 ff ff       	call   f0100ac5 <check_va2pa>
f01025ba:	89 da                	mov    %ebx,%edx
f01025bc:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
f01025c2:	c1 fa 03             	sar    $0x3,%edx
f01025c5:	c1 e2 0c             	shl    $0xc,%edx
f01025c8:	39 d0                	cmp    %edx,%eax
f01025ca:	74 24                	je     f01025f0 <mem_init+0x106b>
f01025cc:	c7 44 24 0c d4 71 10 	movl   $0xf01071d4,0xc(%esp)
f01025d3:	f0 
f01025d4:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01025db:	f0 
f01025dc:	c7 44 24 04 7a 04 00 	movl   $0x47a,0x4(%esp)
f01025e3:	00 
f01025e4:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01025eb:	e8 50 da ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f01025f0:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01025f5:	74 24                	je     f010261b <mem_init+0x1096>
f01025f7:	c7 44 24 0c 6d 78 10 	movl   $0xf010786d,0xc(%esp)
f01025fe:	f0 
f01025ff:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102606:	f0 
f0102607:	c7 44 24 04 7b 04 00 	movl   $0x47b,0x4(%esp)
f010260e:	00 
f010260f:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102616:	e8 25 da ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010261b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102620:	74 24                	je     f0102646 <mem_init+0x10c1>
f0102622:	c7 44 24 0c c7 78 10 	movl   $0xf01078c7,0xc(%esp)
f0102629:	f0 
f010262a:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102631:	f0 
f0102632:	c7 44 24 04 7c 04 00 	movl   $0x47c,0x4(%esp)
f0102639:	00 
f010263a:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102641:	e8 fa d9 ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102646:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010264d:	00 
f010264e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102655:	00 
f0102656:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010265a:	89 3c 24             	mov    %edi,(%esp)
f010265d:	e8 19 ee ff ff       	call   f010147b <page_insert>
f0102662:	85 c0                	test   %eax,%eax
f0102664:	74 24                	je     f010268a <mem_init+0x1105>
f0102666:	c7 44 24 0c 4c 72 10 	movl   $0xf010724c,0xc(%esp)
f010266d:	f0 
f010266e:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102675:	f0 
f0102676:	c7 44 24 04 7f 04 00 	movl   $0x47f,0x4(%esp)
f010267d:	00 
f010267e:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102685:	e8 b6 d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f010268a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010268f:	75 24                	jne    f01026b5 <mem_init+0x1130>
f0102691:	c7 44 24 0c d8 78 10 	movl   $0xf01078d8,0xc(%esp)
f0102698:	f0 
f0102699:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01026a0:	f0 
f01026a1:	c7 44 24 04 80 04 00 	movl   $0x480,0x4(%esp)
f01026a8:	00 
f01026a9:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01026b0:	e8 8b d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f01026b5:	83 3b 00             	cmpl   $0x0,(%ebx)
f01026b8:	74 24                	je     f01026de <mem_init+0x1159>
f01026ba:	c7 44 24 0c e4 78 10 	movl   $0xf01078e4,0xc(%esp)
f01026c1:	f0 
f01026c2:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01026c9:	f0 
f01026ca:	c7 44 24 04 81 04 00 	movl   $0x481,0x4(%esp)
f01026d1:	00 
f01026d2:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01026d9:	e8 62 d9 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01026de:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01026e5:	00 
f01026e6:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f01026eb:	89 04 24             	mov    %eax,(%esp)
f01026ee:	e8 3f ed ff ff       	call   f0101432 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01026f3:	8b 3d 8c be 22 f0    	mov    0xf022be8c,%edi
f01026f9:	ba 00 00 00 00       	mov    $0x0,%edx
f01026fe:	89 f8                	mov    %edi,%eax
f0102700:	e8 c0 e3 ff ff       	call   f0100ac5 <check_va2pa>
f0102705:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102708:	74 24                	je     f010272e <mem_init+0x11a9>
f010270a:	c7 44 24 0c 28 72 10 	movl   $0xf0107228,0xc(%esp)
f0102711:	f0 
f0102712:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102719:	f0 
f010271a:	c7 44 24 04 85 04 00 	movl   $0x485,0x4(%esp)
f0102721:	00 
f0102722:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102729:	e8 12 d9 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010272e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102733:	89 f8                	mov    %edi,%eax
f0102735:	e8 8b e3 ff ff       	call   f0100ac5 <check_va2pa>
f010273a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010273d:	74 24                	je     f0102763 <mem_init+0x11de>
f010273f:	c7 44 24 0c 84 72 10 	movl   $0xf0107284,0xc(%esp)
f0102746:	f0 
f0102747:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f010274e:	f0 
f010274f:	c7 44 24 04 86 04 00 	movl   $0x486,0x4(%esp)
f0102756:	00 
f0102757:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f010275e:	e8 dd d8 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102763:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102768:	74 24                	je     f010278e <mem_init+0x1209>
f010276a:	c7 44 24 0c f9 78 10 	movl   $0xf01078f9,0xc(%esp)
f0102771:	f0 
f0102772:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102779:	f0 
f010277a:	c7 44 24 04 87 04 00 	movl   $0x487,0x4(%esp)
f0102781:	00 
f0102782:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102789:	e8 b2 d8 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010278e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102793:	74 24                	je     f01027b9 <mem_init+0x1234>
f0102795:	c7 44 24 0c c7 78 10 	movl   $0xf01078c7,0xc(%esp)
f010279c:	f0 
f010279d:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01027a4:	f0 
f01027a5:	c7 44 24 04 88 04 00 	movl   $0x488,0x4(%esp)
f01027ac:	00 
f01027ad:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01027b4:	e8 87 d8 ff ff       	call   f0100040 <_panic>
	
	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01027b9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01027c0:	e8 32 e9 ff ff       	call   f01010f7 <page_alloc>
f01027c5:	85 c0                	test   %eax,%eax
f01027c7:	74 04                	je     f01027cd <mem_init+0x1248>
f01027c9:	39 c3                	cmp    %eax,%ebx
f01027cb:	74 24                	je     f01027f1 <mem_init+0x126c>
f01027cd:	c7 44 24 0c ac 72 10 	movl   $0xf01072ac,0xc(%esp)
f01027d4:	f0 
f01027d5:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01027dc:	f0 
f01027dd:	c7 44 24 04 8b 04 00 	movl   $0x48b,0x4(%esp)
f01027e4:	00 
f01027e5:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01027ec:	e8 4f d8 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01027f1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01027f8:	e8 fa e8 ff ff       	call   f01010f7 <page_alloc>
f01027fd:	85 c0                	test   %eax,%eax
f01027ff:	74 24                	je     f0102825 <mem_init+0x12a0>
f0102801:	c7 44 24 0c 1b 78 10 	movl   $0xf010781b,0xc(%esp)
f0102808:	f0 
f0102809:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102810:	f0 
f0102811:	c7 44 24 04 8e 04 00 	movl   $0x48e,0x4(%esp)
f0102818:	00 
f0102819:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102820:	e8 1b d8 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102825:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f010282a:	8b 08                	mov    (%eax),%ecx
f010282c:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102832:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102835:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
f010283b:	c1 fa 03             	sar    $0x3,%edx
f010283e:	c1 e2 0c             	shl    $0xc,%edx
f0102841:	39 d1                	cmp    %edx,%ecx
f0102843:	74 24                	je     f0102869 <mem_init+0x12e4>
f0102845:	c7 44 24 0c 50 6f 10 	movl   $0xf0106f50,0xc(%esp)
f010284c:	f0 
f010284d:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102854:	f0 
f0102855:	c7 44 24 04 91 04 00 	movl   $0x491,0x4(%esp)
f010285c:	00 
f010285d:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102864:	e8 d7 d7 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102869:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f010286f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102872:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102877:	74 24                	je     f010289d <mem_init+0x1318>
f0102879:	c7 44 24 0c 7e 78 10 	movl   $0xf010787e,0xc(%esp)
f0102880:	f0 
f0102881:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102888:	f0 
f0102889:	c7 44 24 04 93 04 00 	movl   $0x493,0x4(%esp)
f0102890:	00 
f0102891:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102898:	e8 a3 d7 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f010289d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01028a0:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01028a6:	89 04 24             	mov    %eax,(%esp)
f01028a9:	e8 da e8 ff ff       	call   f0101188 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01028ae:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01028b5:	00 
f01028b6:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f01028bd:	00 
f01028be:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f01028c3:	89 04 24             	mov    %eax,(%esp)
f01028c6:	e8 3b e9 ff ff       	call   f0101206 <pgdir_walk>
f01028cb:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01028ce:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01028d1:	8b 15 8c be 22 f0    	mov    0xf022be8c,%edx
f01028d7:	8b 7a 04             	mov    0x4(%edx),%edi
f01028da:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01028e0:	8b 0d 88 be 22 f0    	mov    0xf022be88,%ecx
f01028e6:	89 f8                	mov    %edi,%eax
f01028e8:	c1 e8 0c             	shr    $0xc,%eax
f01028eb:	39 c8                	cmp    %ecx,%eax
f01028ed:	72 20                	jb     f010290f <mem_init+0x138a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01028ef:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01028f3:	c7 44 24 08 e4 66 10 	movl   $0xf01066e4,0x8(%esp)
f01028fa:	f0 
f01028fb:	c7 44 24 04 9a 04 00 	movl   $0x49a,0x4(%esp)
f0102902:	00 
f0102903:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f010290a:	e8 31 d7 ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010290f:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f0102915:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0102918:	74 24                	je     f010293e <mem_init+0x13b9>
f010291a:	c7 44 24 0c 0a 79 10 	movl   $0xf010790a,0xc(%esp)
f0102921:	f0 
f0102922:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102929:	f0 
f010292a:	c7 44 24 04 9b 04 00 	movl   $0x49b,0x4(%esp)
f0102931:	00 
f0102932:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102939:	e8 02 d7 ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010293e:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f0102945:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102948:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010294e:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f0102954:	c1 f8 03             	sar    $0x3,%eax
f0102957:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010295a:	89 c2                	mov    %eax,%edx
f010295c:	c1 ea 0c             	shr    $0xc,%edx
f010295f:	39 d1                	cmp    %edx,%ecx
f0102961:	77 20                	ja     f0102983 <mem_init+0x13fe>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102963:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102967:	c7 44 24 08 e4 66 10 	movl   $0xf01066e4,0x8(%esp)
f010296e:	f0 
f010296f:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0102976:	00 
f0102977:	c7 04 24 55 76 10 f0 	movl   $0xf0107655,(%esp)
f010297e:	e8 bd d6 ff ff       	call   f0100040 <_panic>
	
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102983:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010298a:	00 
f010298b:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102992:	00 
	return (void *)(pa + KERNBASE);
f0102993:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102998:	89 04 24             	mov    %eax,(%esp)
f010299b:	e8 d7 2f 00 00       	call   f0105977 <memset>
	page_free(pp0);
f01029a0:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01029a3:	89 3c 24             	mov    %edi,(%esp)
f01029a6:	e8 dd e7 ff ff       	call   f0101188 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01029ab:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01029b2:	00 
f01029b3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01029ba:	00 
f01029bb:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f01029c0:	89 04 24             	mov    %eax,(%esp)
f01029c3:	e8 3e e8 ff ff       	call   f0101206 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01029c8:	89 fa                	mov    %edi,%edx
f01029ca:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
f01029d0:	c1 fa 03             	sar    $0x3,%edx
f01029d3:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01029d6:	89 d0                	mov    %edx,%eax
f01029d8:	c1 e8 0c             	shr    $0xc,%eax
f01029db:	3b 05 88 be 22 f0    	cmp    0xf022be88,%eax
f01029e1:	72 20                	jb     f0102a03 <mem_init+0x147e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029e3:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01029e7:	c7 44 24 08 e4 66 10 	movl   $0xf01066e4,0x8(%esp)
f01029ee:	f0 
f01029ef:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f01029f6:	00 
f01029f7:	c7 04 24 55 76 10 f0 	movl   $0xf0107655,(%esp)
f01029fe:	e8 3d d6 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102a03:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102a09:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102a0c:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102a12:	f6 00 01             	testb  $0x1,(%eax)
f0102a15:	74 24                	je     f0102a3b <mem_init+0x14b6>
f0102a17:	c7 44 24 0c 22 79 10 	movl   $0xf0107922,0xc(%esp)
f0102a1e:	f0 
f0102a1f:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102a26:	f0 
f0102a27:	c7 44 24 04 a5 04 00 	movl   $0x4a5,0x4(%esp)
f0102a2e:	00 
f0102a2f:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102a36:	e8 05 d6 ff ff       	call   f0100040 <_panic>
f0102a3b:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102a3e:	39 d0                	cmp    %edx,%eax
f0102a40:	75 d0                	jne    f0102a12 <mem_init+0x148d>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102a42:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102a47:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102a4d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a50:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102a56:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102a59:	89 0d 44 b2 22 f0    	mov    %ecx,0xf022b244

	// free the pages we took
	page_free(pp0);
f0102a5f:	89 04 24             	mov    %eax,(%esp)
f0102a62:	e8 21 e7 ff ff       	call   f0101188 <page_free>
	page_free(pp1);
f0102a67:	89 1c 24             	mov    %ebx,(%esp)
f0102a6a:	e8 19 e7 ff ff       	call   f0101188 <page_free>
	page_free(pp2);
f0102a6f:	89 34 24             	mov    %esi,(%esp)
f0102a72:	e8 11 e7 ff ff       	call   f0101188 <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f0102a77:	c7 44 24 04 01 10 00 	movl   $0x1001,0x4(%esp)
f0102a7e:	00 
f0102a7f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a86:	e8 b2 ea ff ff       	call   f010153d <mmio_map_region>
f0102a8b:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f0102a8d:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102a94:	00 
f0102a95:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a9c:	e8 9c ea ff ff       	call   f010153d <mmio_map_region>
f0102aa1:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f0102aa3:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f0102aa9:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f0102aae:	77 08                	ja     f0102ab8 <mem_init+0x1533>
f0102ab0:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102ab6:	77 24                	ja     f0102adc <mem_init+0x1557>
f0102ab8:	c7 44 24 0c d0 72 10 	movl   $0xf01072d0,0xc(%esp)
f0102abf:	f0 
f0102ac0:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102ac7:	f0 
f0102ac8:	c7 44 24 04 b5 04 00 	movl   $0x4b5,0x4(%esp)
f0102acf:	00 
f0102ad0:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102ad7:	e8 64 d5 ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f0102adc:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f0102ae2:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f0102ae8:	77 08                	ja     f0102af2 <mem_init+0x156d>
f0102aea:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102af0:	77 24                	ja     f0102b16 <mem_init+0x1591>
f0102af2:	c7 44 24 0c f8 72 10 	movl   $0xf01072f8,0xc(%esp)
f0102af9:	f0 
f0102afa:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102b01:	f0 
f0102b02:	c7 44 24 04 b6 04 00 	movl   $0x4b6,0x4(%esp)
f0102b09:	00 
f0102b0a:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102b11:	e8 2a d5 ff ff       	call   f0100040 <_panic>
f0102b16:	89 da                	mov    %ebx,%edx
f0102b18:	09 f2                	or     %esi,%edx
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102b1a:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0102b20:	74 24                	je     f0102b46 <mem_init+0x15c1>
f0102b22:	c7 44 24 0c 20 73 10 	movl   $0xf0107320,0xc(%esp)
f0102b29:	f0 
f0102b2a:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102b31:	f0 
f0102b32:	c7 44 24 04 b8 04 00 	movl   $0x4b8,0x4(%esp)
f0102b39:	00 
f0102b3a:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102b41:	e8 fa d4 ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f0102b46:	39 c6                	cmp    %eax,%esi
f0102b48:	73 24                	jae    f0102b6e <mem_init+0x15e9>
f0102b4a:	c7 44 24 0c 39 79 10 	movl   $0xf0107939,0xc(%esp)
f0102b51:	f0 
f0102b52:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102b59:	f0 
f0102b5a:	c7 44 24 04 ba 04 00 	movl   $0x4ba,0x4(%esp)
f0102b61:	00 
f0102b62:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102b69:	e8 d2 d4 ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102b6e:	8b 3d 8c be 22 f0    	mov    0xf022be8c,%edi
f0102b74:	89 da                	mov    %ebx,%edx
f0102b76:	89 f8                	mov    %edi,%eax
f0102b78:	e8 48 df ff ff       	call   f0100ac5 <check_va2pa>
f0102b7d:	85 c0                	test   %eax,%eax
f0102b7f:	74 24                	je     f0102ba5 <mem_init+0x1620>
f0102b81:	c7 44 24 0c 48 73 10 	movl   $0xf0107348,0xc(%esp)
f0102b88:	f0 
f0102b89:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102b90:	f0 
f0102b91:	c7 44 24 04 bc 04 00 	movl   $0x4bc,0x4(%esp)
f0102b98:	00 
f0102b99:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102ba0:	e8 9b d4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102ba5:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0102bab:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102bae:	89 c2                	mov    %eax,%edx
f0102bb0:	89 f8                	mov    %edi,%eax
f0102bb2:	e8 0e df ff ff       	call   f0100ac5 <check_va2pa>
f0102bb7:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102bbc:	74 24                	je     f0102be2 <mem_init+0x165d>
f0102bbe:	c7 44 24 0c 6c 73 10 	movl   $0xf010736c,0xc(%esp)
f0102bc5:	f0 
f0102bc6:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102bcd:	f0 
f0102bce:	c7 44 24 04 bd 04 00 	movl   $0x4bd,0x4(%esp)
f0102bd5:	00 
f0102bd6:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102bdd:	e8 5e d4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102be2:	89 f2                	mov    %esi,%edx
f0102be4:	89 f8                	mov    %edi,%eax
f0102be6:	e8 da de ff ff       	call   f0100ac5 <check_va2pa>
f0102beb:	85 c0                	test   %eax,%eax
f0102bed:	74 24                	je     f0102c13 <mem_init+0x168e>
f0102bef:	c7 44 24 0c 9c 73 10 	movl   $0xf010739c,0xc(%esp)
f0102bf6:	f0 
f0102bf7:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102bfe:	f0 
f0102bff:	c7 44 24 04 be 04 00 	movl   $0x4be,0x4(%esp)
f0102c06:	00 
f0102c07:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102c0e:	e8 2d d4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f0102c13:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f0102c19:	89 f8                	mov    %edi,%eax
f0102c1b:	e8 a5 de ff ff       	call   f0100ac5 <check_va2pa>
f0102c20:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102c23:	74 24                	je     f0102c49 <mem_init+0x16c4>
f0102c25:	c7 44 24 0c c0 73 10 	movl   $0xf01073c0,0xc(%esp)
f0102c2c:	f0 
f0102c2d:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102c34:	f0 
f0102c35:	c7 44 24 04 bf 04 00 	movl   $0x4bf,0x4(%esp)
f0102c3c:	00 
f0102c3d:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102c44:	e8 f7 d3 ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102c49:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102c50:	00 
f0102c51:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102c55:	89 3c 24             	mov    %edi,(%esp)
f0102c58:	e8 a9 e5 ff ff       	call   f0101206 <pgdir_walk>
f0102c5d:	f6 00 1a             	testb  $0x1a,(%eax)
f0102c60:	75 24                	jne    f0102c86 <mem_init+0x1701>
f0102c62:	c7 44 24 0c ec 73 10 	movl   $0xf01073ec,0xc(%esp)
f0102c69:	f0 
f0102c6a:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102c71:	f0 
f0102c72:	c7 44 24 04 c1 04 00 	movl   $0x4c1,0x4(%esp)
f0102c79:	00 
f0102c7a:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102c81:	e8 ba d3 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102c86:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102c8d:	00 
f0102c8e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102c92:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102c97:	89 04 24             	mov    %eax,(%esp)
f0102c9a:	e8 67 e5 ff ff       	call   f0101206 <pgdir_walk>
f0102c9f:	f6 00 04             	testb  $0x4,(%eax)
f0102ca2:	74 24                	je     f0102cc8 <mem_init+0x1743>
f0102ca4:	c7 44 24 0c 30 74 10 	movl   $0xf0107430,0xc(%esp)
f0102cab:	f0 
f0102cac:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102cb3:	f0 
f0102cb4:	c7 44 24 04 c2 04 00 	movl   $0x4c2,0x4(%esp)
f0102cbb:	00 
f0102cbc:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102cc3:	e8 78 d3 ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f0102cc8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102ccf:	00 
f0102cd0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102cd4:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102cd9:	89 04 24             	mov    %eax,(%esp)
f0102cdc:	e8 25 e5 ff ff       	call   f0101206 <pgdir_walk>
f0102ce1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f0102ce7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102cee:	00 
f0102cef:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102cf2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102cf6:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102cfb:	89 04 24             	mov    %eax,(%esp)
f0102cfe:	e8 03 e5 ff ff       	call   f0101206 <pgdir_walk>
f0102d03:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f0102d09:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102d10:	00 
f0102d11:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102d15:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102d1a:	89 04 24             	mov    %eax,(%esp)
f0102d1d:	e8 e4 e4 ff ff       	call   f0101206 <pgdir_walk>
f0102d22:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f0102d28:	c7 04 24 4b 79 10 f0 	movl   $0xf010794b,(%esp)
f0102d2f:	e8 88 13 00 00       	call   f01040bc <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, ROUNDUP( (sizeof(struct PageInfo)*npages),PGSIZE), PADDR(pages), PTE_U | PTE_P);
f0102d34:	a1 90 be 22 f0       	mov    0xf022be90,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d39:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d3e:	77 20                	ja     f0102d60 <mem_init+0x17db>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d40:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d44:	c7 44 24 08 08 67 10 	movl   $0xf0106708,0x8(%esp)
f0102d4b:	f0 
f0102d4c:	c7 44 24 04 c5 00 00 	movl   $0xc5,0x4(%esp)
f0102d53:	00 
f0102d54:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102d5b:	e8 e0 d2 ff ff       	call   f0100040 <_panic>
f0102d60:	8b 15 88 be 22 f0    	mov    0xf022be88,%edx
f0102d66:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f0102d6d:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102d73:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102d7a:	00 
	return (physaddr_t)kva - KERNBASE;
f0102d7b:	05 00 00 00 10       	add    $0x10000000,%eax
f0102d80:	89 04 24             	mov    %eax,(%esp)
f0102d83:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102d88:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102d8d:	e8 83 e5 ff ff       	call   f0101315 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, sizeof(struct Env) * NENV,PADDR(envs), PTE_U);
f0102d92:	a1 4c b2 22 f0       	mov    0xf022b24c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d97:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d9c:	77 20                	ja     f0102dbe <mem_init+0x1839>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d9e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102da2:	c7 44 24 08 08 67 10 	movl   $0xf0106708,0x8(%esp)
f0102da9:	f0 
f0102daa:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
f0102db1:	00 
f0102db2:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102db9:	e8 82 d2 ff ff       	call   f0100040 <_panic>
f0102dbe:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f0102dc5:	00 
	return (physaddr_t)kva - KERNBASE;
f0102dc6:	05 00 00 00 10       	add    $0x10000000,%eax
f0102dcb:	89 04 24             	mov    %eax,(%esp)
f0102dce:	b9 00 f0 01 00       	mov    $0x1f000,%ecx
f0102dd3:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102dd8:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102ddd:	e8 33 e5 ff ff       	call   f0101315 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102de2:	b8 00 60 11 f0       	mov    $0xf0116000,%eax
f0102de7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102dec:	77 20                	ja     f0102e0e <mem_init+0x1889>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102dee:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102df2:	c7 44 24 08 08 67 10 	movl   $0xf0106708,0x8(%esp)
f0102df9:	f0 
f0102dfa:	c7 44 24 04 d9 00 00 	movl   $0xd9,0x4(%esp)
f0102e01:	00 
f0102e02:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102e09:	e8 32 d2 ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W | PTE_P);
f0102e0e:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102e15:	00 
f0102e16:	c7 04 24 00 60 11 00 	movl   $0x116000,(%esp)
f0102e1d:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102e22:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102e27:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102e2c:	e8 e4 e4 ff ff       	call   f0101315 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	size_t size = ROUNDUP(0xFFFFFFFF - KERNBASE + 1, PGSIZE);
	boot_map_region(kern_pgdir, KERNBASE, size, 0, PTE_W | PTE_P);
f0102e31:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102e38:	00 
f0102e39:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102e40:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102e45:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102e4a:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102e4f:	e8 c1 e4 ff ff       	call   f0101315 <boot_map_region>
f0102e54:	bf 00 d0 26 f0       	mov    $0xf026d000,%edi
f0102e59:	bb 00 d0 22 f0       	mov    $0xf022d000,%ebx
f0102e5e:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e63:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102e69:	77 20                	ja     f0102e8b <mem_init+0x1906>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e6b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102e6f:	c7 44 24 08 08 67 10 	movl   $0xf0106708,0x8(%esp)
f0102e76:	f0 
f0102e77:	c7 44 24 04 20 01 00 	movl   $0x120,0x4(%esp)
f0102e7e:	00 
f0102e7f:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102e86:	e8 b5 d1 ff ff       	call   f0100040 <_panic>
	uint32_t percpu_stacktop = KSTACKTOP;
	//uint32_t percpu_stackbtm;
	
	for (i=0;i<NCPU;i++)
	{	
		boot_map_region(kern_pgdir, percpu_stacktop - KSTKSIZE, KSTKSIZE,PADDR((void*)percpu_kstacks[i]), PTE_W | PTE_P);
f0102e8b:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102e92:	00 
f0102e93:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f0102e99:	89 04 24             	mov    %eax,(%esp)
f0102e9c:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102ea1:	89 f2                	mov    %esi,%edx
f0102ea3:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102ea8:	e8 68 e4 ff ff       	call   f0101315 <boot_map_region>
f0102ead:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f0102eb3:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	
	int i=0;
	uint32_t percpu_stacktop = KSTACKTOP;
	//uint32_t percpu_stackbtm;
	
	for (i=0;i<NCPU;i++)
f0102eb9:	39 fb                	cmp    %edi,%ebx
f0102ebb:	75 a6                	jne    f0102e63 <mem_init+0x18de>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102ebd:	8b 3d 8c be 22 f0    	mov    0xf022be8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102ec3:	a1 88 be 22 f0       	mov    0xf022be88,%eax
f0102ec8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102ecb:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102ed2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102ed7:	89 45 d0             	mov    %eax,-0x30(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102eda:	8b 35 90 be 22 f0    	mov    0xf022be90,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102ee0:	89 75 cc             	mov    %esi,-0x34(%ebp)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f0102ee3:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f0102ee9:	89 45 c8             	mov    %eax,-0x38(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102eec:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102ef1:	eb 6a                	jmp    f0102f5d <mem_init+0x19d8>
f0102ef3:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102ef9:	89 f8                	mov    %edi,%eax
f0102efb:	e8 c5 db ff ff       	call   f0100ac5 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f00:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f0102f07:	77 20                	ja     f0102f29 <mem_init+0x19a4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f09:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102f0d:	c7 44 24 08 08 67 10 	movl   $0xf0106708,0x8(%esp)
f0102f14:	f0 
f0102f15:	c7 44 24 04 d7 03 00 	movl   $0x3d7,0x4(%esp)
f0102f1c:	00 
f0102f1d:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102f24:	e8 17 d1 ff ff       	call   f0100040 <_panic>
f0102f29:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102f2c:	8d 14 0b             	lea    (%ebx,%ecx,1),%edx
f0102f2f:	39 d0                	cmp    %edx,%eax
f0102f31:	74 24                	je     f0102f57 <mem_init+0x19d2>
f0102f33:	c7 44 24 0c 64 74 10 	movl   $0xf0107464,0xc(%esp)
f0102f3a:	f0 
f0102f3b:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102f42:	f0 
f0102f43:	c7 44 24 04 d7 03 00 	movl   $0x3d7,0x4(%esp)
f0102f4a:	00 
f0102f4b:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102f52:	e8 e9 d0 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102f57:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102f5d:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f0102f60:	77 91                	ja     f0102ef3 <mem_init+0x196e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102f62:	8b 1d 4c b2 22 f0    	mov    0xf022b24c,%ebx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f68:	89 de                	mov    %ebx,%esi
f0102f6a:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102f6f:	89 f8                	mov    %edi,%eax
f0102f71:	e8 4f db ff ff       	call   f0100ac5 <check_va2pa>
f0102f76:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102f7c:	77 20                	ja     f0102f9e <mem_init+0x1a19>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f7e:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102f82:	c7 44 24 08 08 67 10 	movl   $0xf0106708,0x8(%esp)
f0102f89:	f0 
f0102f8a:	c7 44 24 04 dc 03 00 	movl   $0x3dc,0x4(%esp)
f0102f91:	00 
f0102f92:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102f99:	e8 a2 d0 ff ff       	call   f0100040 <_panic>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f9e:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f0102fa3:	81 c6 00 00 40 21    	add    $0x21400000,%esi
f0102fa9:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
f0102fac:	39 d0                	cmp    %edx,%eax
f0102fae:	74 24                	je     f0102fd4 <mem_init+0x1a4f>
f0102fb0:	c7 44 24 0c 98 74 10 	movl   $0xf0107498,0xc(%esp)
f0102fb7:	f0 
f0102fb8:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0102fbf:	f0 
f0102fc0:	c7 44 24 04 dc 03 00 	movl   $0x3dc,0x4(%esp)
f0102fc7:	00 
f0102fc8:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0102fcf:	e8 6c d0 ff ff       	call   f0100040 <_panic>
f0102fd4:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102fda:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f0102fe0:	0f 85 a8 05 00 00    	jne    f010358e <mem_init+0x2009>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102fe6:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102fe9:	c1 e6 0c             	shl    $0xc,%esi
f0102fec:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102ff1:	eb 3b                	jmp    f010302e <mem_init+0x1aa9>
f0102ff3:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102ff9:	89 f8                	mov    %edi,%eax
f0102ffb:	e8 c5 da ff ff       	call   f0100ac5 <check_va2pa>
f0103000:	39 c3                	cmp    %eax,%ebx
f0103002:	74 24                	je     f0103028 <mem_init+0x1aa3>
f0103004:	c7 44 24 0c cc 74 10 	movl   $0xf01074cc,0xc(%esp)
f010300b:	f0 
f010300c:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0103013:	f0 
f0103014:	c7 44 24 04 e0 03 00 	movl   $0x3e0,0x4(%esp)
f010301b:	00 
f010301c:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0103023:	e8 18 d0 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0103028:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010302e:	39 f3                	cmp    %esi,%ebx
f0103030:	72 c1                	jb     f0102ff3 <mem_init+0x1a6e>
f0103032:	c7 45 d0 00 d0 22 f0 	movl   $0xf022d000,-0x30(%ebp)
f0103039:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f0103040:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0103045:	b8 00 d0 22 f0       	mov    $0xf022d000,%eax
f010304a:	05 00 80 00 20       	add    $0x20008000,%eax
f010304f:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0103052:	8d 86 00 80 00 00    	lea    0x8000(%esi),%eax
f0103058:	89 45 cc             	mov    %eax,-0x34(%ebp)
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f010305b:	89 f2                	mov    %esi,%edx
f010305d:	89 f8                	mov    %edi,%eax
f010305f:	e8 61 da ff ff       	call   f0100ac5 <check_va2pa>
f0103064:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103067:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f010306d:	77 20                	ja     f010308f <mem_init+0x1b0a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010306f:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103073:	c7 44 24 08 08 67 10 	movl   $0xf0106708,0x8(%esp)
f010307a:	f0 
f010307b:	c7 44 24 04 e8 03 00 	movl   $0x3e8,0x4(%esp)
f0103082:	00 
f0103083:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f010308a:	e8 b1 cf ff ff       	call   f0100040 <_panic>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010308f:	89 f3                	mov    %esi,%ebx
f0103091:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0103094:	03 4d d4             	add    -0x2c(%ebp),%ecx
f0103097:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f010309a:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f010309d:	8d 14 19             	lea    (%ecx,%ebx,1),%edx
f01030a0:	39 c2                	cmp    %eax,%edx
f01030a2:	74 24                	je     f01030c8 <mem_init+0x1b43>
f01030a4:	c7 44 24 0c f4 74 10 	movl   $0xf01074f4,0xc(%esp)
f01030ab:	f0 
f01030ac:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01030b3:	f0 
f01030b4:	c7 44 24 04 e8 03 00 	movl   $0x3e8,0x4(%esp)
f01030bb:	00 
f01030bc:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01030c3:	e8 78 cf ff ff       	call   f0100040 <_panic>
f01030c8:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01030ce:	3b 5d cc             	cmp    -0x34(%ebp),%ebx
f01030d1:	0f 85 a9 04 00 00    	jne    f0103580 <mem_init+0x1ffb>
f01030d7:	8d 9e 00 80 ff ff    	lea    -0x8000(%esi),%ebx
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f01030dd:	89 da                	mov    %ebx,%edx
f01030df:	89 f8                	mov    %edi,%eax
f01030e1:	e8 df d9 ff ff       	call   f0100ac5 <check_va2pa>
f01030e6:	83 f8 ff             	cmp    $0xffffffff,%eax
f01030e9:	74 24                	je     f010310f <mem_init+0x1b8a>
f01030eb:	c7 44 24 0c 3c 75 10 	movl   $0xf010753c,0xc(%esp)
f01030f2:	f0 
f01030f3:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01030fa:	f0 
f01030fb:	c7 44 24 04 ea 03 00 	movl   $0x3ea,0x4(%esp)
f0103102:	00 
f0103103:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f010310a:	e8 31 cf ff ff       	call   f0100040 <_panic>
f010310f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f0103115:	39 f3                	cmp    %esi,%ebx
f0103117:	75 c4                	jne    f01030dd <mem_init+0x1b58>
f0103119:	81 ee 00 00 01 00    	sub    $0x10000,%esi
f010311f:	81 45 d4 00 80 01 00 	addl   $0x18000,-0x2c(%ebp)
f0103126:	81 45 d0 00 80 00 00 	addl   $0x8000,-0x30(%ebp)
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f010312d:	81 fe 00 80 f7 ef    	cmp    $0xeff78000,%esi
f0103133:	0f 85 19 ff ff ff    	jne    f0103052 <mem_init+0x1acd>
f0103139:	b8 00 00 00 00       	mov    $0x0,%eax
f010313e:	e9 c2 00 00 00       	jmp    f0103205 <mem_init+0x1c80>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0103143:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0103149:	83 fa 04             	cmp    $0x4,%edx
f010314c:	77 2e                	ja     f010317c <mem_init+0x1bf7>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f010314e:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0103152:	0f 85 aa 00 00 00    	jne    f0103202 <mem_init+0x1c7d>
f0103158:	c7 44 24 0c 64 79 10 	movl   $0xf0107964,0xc(%esp)
f010315f:	f0 
f0103160:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0103167:	f0 
f0103168:	c7 44 24 04 f5 03 00 	movl   $0x3f5,0x4(%esp)
f010316f:	00 
f0103170:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0103177:	e8 c4 ce ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010317c:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0103181:	76 55                	jbe    f01031d8 <mem_init+0x1c53>
				assert(pgdir[i] & PTE_P);
f0103183:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103186:	f6 c2 01             	test   $0x1,%dl
f0103189:	75 24                	jne    f01031af <mem_init+0x1c2a>
f010318b:	c7 44 24 0c 64 79 10 	movl   $0xf0107964,0xc(%esp)
f0103192:	f0 
f0103193:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f010319a:	f0 
f010319b:	c7 44 24 04 f9 03 00 	movl   $0x3f9,0x4(%esp)
f01031a2:	00 
f01031a3:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01031aa:	e8 91 ce ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f01031af:	f6 c2 02             	test   $0x2,%dl
f01031b2:	75 4e                	jne    f0103202 <mem_init+0x1c7d>
f01031b4:	c7 44 24 0c 75 79 10 	movl   $0xf0107975,0xc(%esp)
f01031bb:	f0 
f01031bc:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01031c3:	f0 
f01031c4:	c7 44 24 04 fa 03 00 	movl   $0x3fa,0x4(%esp)
f01031cb:	00 
f01031cc:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01031d3:	e8 68 ce ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f01031d8:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f01031dc:	74 24                	je     f0103202 <mem_init+0x1c7d>
f01031de:	c7 44 24 0c 86 79 10 	movl   $0xf0107986,0xc(%esp)
f01031e5:	f0 
f01031e6:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01031ed:	f0 
f01031ee:	c7 44 24 04 fc 03 00 	movl   $0x3fc,0x4(%esp)
f01031f5:	00 
f01031f6:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01031fd:	e8 3e ce ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0103202:	83 c0 01             	add    $0x1,%eax
f0103205:	3d 00 04 00 00       	cmp    $0x400,%eax
f010320a:	0f 85 33 ff ff ff    	jne    f0103143 <mem_init+0x1bbe>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0103210:	c7 04 24 60 75 10 f0 	movl   $0xf0107560,(%esp)
f0103217:	e8 a0 0e 00 00       	call   f01040bc <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010321c:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0103221:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103226:	77 20                	ja     f0103248 <mem_init+0x1cc3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103228:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010322c:	c7 44 24 08 08 67 10 	movl   $0xf0106708,0x8(%esp)
f0103233:	f0 
f0103234:	c7 44 24 04 f2 00 00 	movl   $0xf2,0x4(%esp)
f010323b:	00 
f010323c:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0103243:	e8 f8 cd ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103248:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010324d:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0103250:	b8 00 00 00 00       	mov    $0x0,%eax
f0103255:	e8 5f d9 ff ff       	call   f0100bb9 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f010325a:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f010325d:	83 e0 f3             	and    $0xfffffff3,%eax
f0103260:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0103265:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0103268:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010326f:	e8 83 de ff ff       	call   f01010f7 <page_alloc>
f0103274:	89 c3                	mov    %eax,%ebx
f0103276:	85 c0                	test   %eax,%eax
f0103278:	75 24                	jne    f010329e <mem_init+0x1d19>
f010327a:	c7 44 24 0c 70 77 10 	movl   $0xf0107770,0xc(%esp)
f0103281:	f0 
f0103282:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0103289:	f0 
f010328a:	c7 44 24 04 d7 04 00 	movl   $0x4d7,0x4(%esp)
f0103291:	00 
f0103292:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0103299:	e8 a2 cd ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010329e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01032a5:	e8 4d de ff ff       	call   f01010f7 <page_alloc>
f01032aa:	89 c7                	mov    %eax,%edi
f01032ac:	85 c0                	test   %eax,%eax
f01032ae:	75 24                	jne    f01032d4 <mem_init+0x1d4f>
f01032b0:	c7 44 24 0c 86 77 10 	movl   $0xf0107786,0xc(%esp)
f01032b7:	f0 
f01032b8:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01032bf:	f0 
f01032c0:	c7 44 24 04 d8 04 00 	movl   $0x4d8,0x4(%esp)
f01032c7:	00 
f01032c8:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01032cf:	e8 6c cd ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01032d4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01032db:	e8 17 de ff ff       	call   f01010f7 <page_alloc>
f01032e0:	89 c6                	mov    %eax,%esi
f01032e2:	85 c0                	test   %eax,%eax
f01032e4:	75 24                	jne    f010330a <mem_init+0x1d85>
f01032e6:	c7 44 24 0c 9c 77 10 	movl   $0xf010779c,0xc(%esp)
f01032ed:	f0 
f01032ee:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01032f5:	f0 
f01032f6:	c7 44 24 04 d9 04 00 	movl   $0x4d9,0x4(%esp)
f01032fd:	00 
f01032fe:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0103305:	e8 36 cd ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f010330a:	89 1c 24             	mov    %ebx,(%esp)
f010330d:	e8 76 de ff ff       	call   f0101188 <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0103312:	89 f8                	mov    %edi,%eax
f0103314:	e8 67 d7 ff ff       	call   f0100a80 <page2kva>
f0103319:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103320:	00 
f0103321:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0103328:	00 
f0103329:	89 04 24             	mov    %eax,(%esp)
f010332c:	e8 46 26 00 00       	call   f0105977 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0103331:	89 f0                	mov    %esi,%eax
f0103333:	e8 48 d7 ff ff       	call   f0100a80 <page2kva>
f0103338:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010333f:	00 
f0103340:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0103347:	00 
f0103348:	89 04 24             	mov    %eax,(%esp)
f010334b:	e8 27 26 00 00       	call   f0105977 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0103350:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0103357:	00 
f0103358:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010335f:	00 
f0103360:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103364:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0103369:	89 04 24             	mov    %eax,(%esp)
f010336c:	e8 0a e1 ff ff       	call   f010147b <page_insert>
	assert(pp1->pp_ref == 1);
f0103371:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0103376:	74 24                	je     f010339c <mem_init+0x1e17>
f0103378:	c7 44 24 0c 6d 78 10 	movl   $0xf010786d,0xc(%esp)
f010337f:	f0 
f0103380:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0103387:	f0 
f0103388:	c7 44 24 04 de 04 00 	movl   $0x4de,0x4(%esp)
f010338f:	00 
f0103390:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0103397:	e8 a4 cc ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010339c:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01033a3:	01 01 01 
f01033a6:	74 24                	je     f01033cc <mem_init+0x1e47>
f01033a8:	c7 44 24 0c 80 75 10 	movl   $0xf0107580,0xc(%esp)
f01033af:	f0 
f01033b0:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01033b7:	f0 
f01033b8:	c7 44 24 04 df 04 00 	movl   $0x4df,0x4(%esp)
f01033bf:	00 
f01033c0:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01033c7:	e8 74 cc ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01033cc:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01033d3:	00 
f01033d4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01033db:	00 
f01033dc:	89 74 24 04          	mov    %esi,0x4(%esp)
f01033e0:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f01033e5:	89 04 24             	mov    %eax,(%esp)
f01033e8:	e8 8e e0 ff ff       	call   f010147b <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01033ed:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01033f4:	02 02 02 
f01033f7:	74 24                	je     f010341d <mem_init+0x1e98>
f01033f9:	c7 44 24 0c a4 75 10 	movl   $0xf01075a4,0xc(%esp)
f0103400:	f0 
f0103401:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0103408:	f0 
f0103409:	c7 44 24 04 e1 04 00 	movl   $0x4e1,0x4(%esp)
f0103410:	00 
f0103411:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0103418:	e8 23 cc ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f010341d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0103422:	74 24                	je     f0103448 <mem_init+0x1ec3>
f0103424:	c7 44 24 0c 8f 78 10 	movl   $0xf010788f,0xc(%esp)
f010342b:	f0 
f010342c:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0103433:	f0 
f0103434:	c7 44 24 04 e2 04 00 	movl   $0x4e2,0x4(%esp)
f010343b:	00 
f010343c:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f0103443:	e8 f8 cb ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0103448:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010344d:	74 24                	je     f0103473 <mem_init+0x1eee>
f010344f:	c7 44 24 0c f9 78 10 	movl   $0xf01078f9,0xc(%esp)
f0103456:	f0 
f0103457:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f010345e:	f0 
f010345f:	c7 44 24 04 e3 04 00 	movl   $0x4e3,0x4(%esp)
f0103466:	00 
f0103467:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f010346e:	e8 cd cb ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0103473:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f010347a:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f010347d:	89 f0                	mov    %esi,%eax
f010347f:	e8 fc d5 ff ff       	call   f0100a80 <page2kva>
f0103484:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f010348a:	74 24                	je     f01034b0 <mem_init+0x1f2b>
f010348c:	c7 44 24 0c c8 75 10 	movl   $0xf01075c8,0xc(%esp)
f0103493:	f0 
f0103494:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f010349b:	f0 
f010349c:	c7 44 24 04 e5 04 00 	movl   $0x4e5,0x4(%esp)
f01034a3:	00 
f01034a4:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01034ab:	e8 90 cb ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01034b0:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01034b7:	00 
f01034b8:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f01034bd:	89 04 24             	mov    %eax,(%esp)
f01034c0:	e8 6d df ff ff       	call   f0101432 <page_remove>
	assert(pp2->pp_ref == 0);
f01034c5:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01034ca:	74 24                	je     f01034f0 <mem_init+0x1f6b>
f01034cc:	c7 44 24 0c c7 78 10 	movl   $0xf01078c7,0xc(%esp)
f01034d3:	f0 
f01034d4:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f01034db:	f0 
f01034dc:	c7 44 24 04 e7 04 00 	movl   $0x4e7,0x4(%esp)
f01034e3:	00 
f01034e4:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f01034eb:	e8 50 cb ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01034f0:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f01034f5:	8b 08                	mov    (%eax),%ecx
f01034f7:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01034fd:	89 da                	mov    %ebx,%edx
f01034ff:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
f0103505:	c1 fa 03             	sar    $0x3,%edx
f0103508:	c1 e2 0c             	shl    $0xc,%edx
f010350b:	39 d1                	cmp    %edx,%ecx
f010350d:	74 24                	je     f0103533 <mem_init+0x1fae>
f010350f:	c7 44 24 0c 50 6f 10 	movl   $0xf0106f50,0xc(%esp)
f0103516:	f0 
f0103517:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f010351e:	f0 
f010351f:	c7 44 24 04 ea 04 00 	movl   $0x4ea,0x4(%esp)
f0103526:	00 
f0103527:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f010352e:	e8 0d cb ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0103533:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0103539:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010353e:	74 24                	je     f0103564 <mem_init+0x1fdf>
f0103540:	c7 44 24 0c 7e 78 10 	movl   $0xf010787e,0xc(%esp)
f0103547:	f0 
f0103548:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f010354f:	f0 
f0103550:	c7 44 24 04 ec 04 00 	movl   $0x4ec,0x4(%esp)
f0103557:	00 
f0103558:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f010355f:	e8 dc ca ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0103564:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f010356a:	89 1c 24             	mov    %ebx,(%esp)
f010356d:	e8 16 dc ff ff       	call   f0101188 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0103572:	c7 04 24 f4 75 10 f0 	movl   $0xf01075f4,(%esp)
f0103579:	e8 3e 0b 00 00       	call   f01040bc <cprintf>
f010357e:	eb 1c                	jmp    f010359c <mem_init+0x2017>
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0103580:	89 da                	mov    %ebx,%edx
f0103582:	89 f8                	mov    %edi,%eax
f0103584:	e8 3c d5 ff ff       	call   f0100ac5 <check_va2pa>
f0103589:	e9 0c fb ff ff       	jmp    f010309a <mem_init+0x1b15>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f010358e:	89 da                	mov    %ebx,%edx
f0103590:	89 f8                	mov    %edi,%eax
f0103592:	e8 2e d5 ff ff       	call   f0100ac5 <check_va2pa>
f0103597:	e9 0d fa ff ff       	jmp    f0102fa9 <mem_init+0x1a24>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f010359c:	83 c4 4c             	add    $0x4c,%esp
f010359f:	5b                   	pop    %ebx
f01035a0:	5e                   	pop    %esi
f01035a1:	5f                   	pop    %edi
f01035a2:	5d                   	pop    %ebp
f01035a3:	c3                   	ret    

f01035a4 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f01035a4:	55                   	push   %ebp
f01035a5:	89 e5                	mov    %esp,%ebp
f01035a7:	57                   	push   %edi
f01035a8:	56                   	push   %esi
f01035a9:	53                   	push   %ebx
f01035aa:	83 ec 2c             	sub    $0x2c,%esp
f01035ad:	8b 75 08             	mov    0x8(%ebp),%esi
f01035b0:	8b 4d 14             	mov    0x14(%ebp),%ecx
	// LAB 3: Your code here.

	// step 1 : check below ULIM
  uintptr_t va_beg = (uintptr_t)va;
  uintptr_t va_end = va_beg + len;
f01035b3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01035b6:	03 5d 10             	add    0x10(%ebp),%ebx
  if (va_beg >= ULIM || va_end >= ULIM) {
f01035b9:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f01035bf:	77 09                	ja     f01035ca <user_mem_check+0x26>
f01035c1:	81 7d 0c ff ff 7f ef 	cmpl   $0xef7fffff,0xc(%ebp)
f01035c8:	76 1f                	jbe    f01035e9 <user_mem_check+0x45>
    user_mem_check_addr = (va_beg >= ULIM) ? va_beg : ULIM;
f01035ca:	81 7d 0c 00 00 80 ef 	cmpl   $0xef800000,0xc(%ebp)
f01035d1:	b8 00 00 80 ef       	mov    $0xef800000,%eax
f01035d6:	0f 43 45 0c          	cmovae 0xc(%ebp),%eax
f01035da:	a3 40 b2 22 f0       	mov    %eax,0xf022b240
    return -E_FAULT;
f01035df:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01035e4:	e9 b8 00 00 00       	jmp    f01036a1 <user_mem_check+0xfd>
  }

  // step 2 : check present & permission
  uintptr_t va_beg2 = ROUNDDOWN(va_beg, PGSIZE);
f01035e9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01035ec:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  uintptr_t va_end2 = ROUNDUP(va_end, PGSIZE);
f01035f1:	81 c3 ff 0f 00 00    	add    $0xfff,%ebx
f01035f7:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01035fd:	8b 15 88 be 22 f0    	mov    0xf022be88,%edx
f0103603:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103606:	89 75 08             	mov    %esi,0x8(%ebp)
  while (va_beg2 < va_end2) {
f0103609:	e9 86 00 00 00       	jmp    f0103694 <user_mem_check+0xf0>

    // check page table is present ?
    if (!(env->env_pgdir[PDX(va_beg2)] & PTE_P)) {
f010360e:	89 c7                	mov    %eax,%edi
f0103610:	c1 ef 16             	shr    $0x16,%edi
f0103613:	8b 75 08             	mov    0x8(%ebp),%esi
f0103616:	8b 56 60             	mov    0x60(%esi),%edx
f0103619:	8b 14 ba             	mov    (%edx,%edi,4),%edx
f010361c:	f6 c2 01             	test   $0x1,%dl
f010361f:	75 13                	jne    f0103634 <user_mem_check+0x90>
      user_mem_check_addr = (va_beg2 > va_beg) ? va_beg2 : va_beg;
f0103621:	3b 45 0c             	cmp    0xc(%ebp),%eax
f0103624:	0f 42 45 0c          	cmovb  0xc(%ebp),%eax
f0103628:	a3 40 b2 22 f0       	mov    %eax,0xf022b240
      return -E_FAULT;
f010362d:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0103632:	eb 6d                	jmp    f01036a1 <user_mem_check+0xfd>
    }

    // get current page table kernel va
    uint32_t* pt_kva = KADDR(PTE_ADDR(env->env_pgdir[PDX(va_beg2)]));
f0103634:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010363a:	89 d7                	mov    %edx,%edi
f010363c:	c1 ef 0c             	shr    $0xc,%edi
f010363f:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f0103642:	72 20                	jb     f0103664 <user_mem_check+0xc0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103644:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103648:	c7 44 24 08 e4 66 10 	movl   $0xf01066e4,0x8(%esp)
f010364f:	f0 
f0103650:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f0103657:	00 
f0103658:	c7 04 24 63 76 10 f0 	movl   $0xf0107663,(%esp)
f010365f:	e8 dc c9 ff ff       	call   f0100040 <_panic>

    // check page is present & permissions
    if (!((pt_kva[PTX(va_beg2)] & perm) == perm)) {
f0103664:	89 c7                	mov    %eax,%edi
f0103666:	c1 ef 0c             	shr    $0xc,%edi
f0103669:	81 e7 ff 03 00 00    	and    $0x3ff,%edi
f010366f:	89 ce                	mov    %ecx,%esi
f0103671:	23 b4 ba 00 00 00 f0 	and    -0x10000000(%edx,%edi,4),%esi
f0103678:	39 f1                	cmp    %esi,%ecx
f010367a:	74 13                	je     f010368f <user_mem_check+0xeb>
      user_mem_check_addr = (va_beg2 > va_beg) ? va_beg2 : va_beg;
f010367c:	3b 45 0c             	cmp    0xc(%ebp),%eax
f010367f:	0f 42 45 0c          	cmovb  0xc(%ebp),%eax
f0103683:	a3 40 b2 22 f0       	mov    %eax,0xf022b240
      return -E_FAULT;
f0103688:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f010368d:	eb 12                	jmp    f01036a1 <user_mem_check+0xfd>
    }

    va_beg2 += PGSIZE;
f010368f:	05 00 10 00 00       	add    $0x1000,%eax
  }

  // step 2 : check present & permission
  uintptr_t va_beg2 = ROUNDDOWN(va_beg, PGSIZE);
  uintptr_t va_end2 = ROUNDUP(va_end, PGSIZE);
  while (va_beg2 < va_end2) {
f0103694:	39 d8                	cmp    %ebx,%eax
f0103696:	0f 82 72 ff ff ff    	jb     f010360e <user_mem_check+0x6a>
      return -E_FAULT;
    }

    va_beg2 += PGSIZE;
  }
  return 0;
f010369c:	b8 00 00 00 00       	mov    $0x0,%eax

}
f01036a1:	83 c4 2c             	add    $0x2c,%esp
f01036a4:	5b                   	pop    %ebx
f01036a5:	5e                   	pop    %esi
f01036a6:	5f                   	pop    %edi
f01036a7:	5d                   	pop    %ebp
f01036a8:	c3                   	ret    

f01036a9 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f01036a9:	55                   	push   %ebp
f01036aa:	89 e5                	mov    %esp,%ebp
f01036ac:	53                   	push   %ebx
f01036ad:	83 ec 14             	sub    $0x14,%esp
f01036b0:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f01036b3:	8b 45 14             	mov    0x14(%ebp),%eax
f01036b6:	83 c8 04             	or     $0x4,%eax
f01036b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01036bd:	8b 45 10             	mov    0x10(%ebp),%eax
f01036c0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01036c4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036c7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036cb:	89 1c 24             	mov    %ebx,(%esp)
f01036ce:	e8 d1 fe ff ff       	call   f01035a4 <user_mem_check>
f01036d3:	85 c0                	test   %eax,%eax
f01036d5:	79 24                	jns    f01036fb <user_mem_assert+0x52>
		cprintf("[%08x] user_mem_check assertion failure for "
f01036d7:	a1 40 b2 22 f0       	mov    0xf022b240,%eax
f01036dc:	89 44 24 08          	mov    %eax,0x8(%esp)
f01036e0:	8b 43 48             	mov    0x48(%ebx),%eax
f01036e3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036e7:	c7 04 24 20 76 10 f0 	movl   $0xf0107620,(%esp)
f01036ee:	e8 c9 09 00 00       	call   f01040bc <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f01036f3:	89 1c 24             	mov    %ebx,(%esp)
f01036f6:	e8 e6 06 00 00       	call   f0103de1 <env_destroy>
	}
}
f01036fb:	83 c4 14             	add    $0x14,%esp
f01036fe:	5b                   	pop    %ebx
f01036ff:	5d                   	pop    %ebp
f0103700:	c3                   	ret    

f0103701 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0103701:	55                   	push   %ebp
f0103702:	89 e5                	mov    %esp,%ebp
f0103704:	57                   	push   %edi
f0103705:	56                   	push   %esi
f0103706:	53                   	push   %ebx
f0103707:	83 ec 1c             	sub    $0x1c,%esp
f010370a:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
f010370c:	89 d3                	mov    %edx,%ebx
f010370e:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
f0103714:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f010371b:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	
	while (vaBegin<vaEnd){
f0103721:	eb 6d                	jmp    f0103790 <region_alloc+0x8f>
		struct PageInfo *p = page_alloc(0);
f0103723:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010372a:	e8 c8 d9 ff ff       	call   f01010f7 <page_alloc>
		if (p == NULL)
f010372f:	85 c0                	test   %eax,%eax
f0103731:	75 1c                	jne    f010374f <region_alloc+0x4e>
			panic("Page alloc failed!");
f0103733:	c7 44 24 08 94 79 10 	movl   $0xf0107994,0x8(%esp)
f010373a:	f0 
f010373b:	c7 44 24 04 34 01 00 	movl   $0x134,0x4(%esp)
f0103742:	00 
f0103743:	c7 04 24 a7 79 10 f0 	movl   $0xf01079a7,(%esp)
f010374a:	e8 f1 c8 ff ff       	call   f0100040 <_panic>
		else if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
f010374f:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0103756:	00 
f0103757:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010375b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010375f:	8b 47 60             	mov    0x60(%edi),%eax
f0103762:	89 04 24             	mov    %eax,(%esp)
f0103765:	e8 11 dd ff ff       	call   f010147b <page_insert>
f010376a:	85 c0                	test   %eax,%eax
f010376c:	74 1c                	je     f010378a <region_alloc+0x89>
			panic("Page table couldn't be allocated!!");
f010376e:	c7 44 24 08 14 7a 10 	movl   $0xf0107a14,0x8(%esp)
f0103775:	f0 
f0103776:	c7 44 24 04 36 01 00 	movl   $0x136,0x4(%esp)
f010377d:	00 
f010377e:	c7 04 24 a7 79 10 f0 	movl   $0xf01079a7,(%esp)
f0103785:	e8 b6 c8 ff ff       	call   f0100040 <_panic>
		}
		vaBegin += PGSIZE;
f010378a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
	
	while (vaBegin<vaEnd){
f0103790:	39 f3                	cmp    %esi,%ebx
f0103792:	72 8f                	jb     f0103723 <region_alloc+0x22>
		else if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
			panic("Page table couldn't be allocated!!");
		}
		vaBegin += PGSIZE;
	}
}
f0103794:	83 c4 1c             	add    $0x1c,%esp
f0103797:	5b                   	pop    %ebx
f0103798:	5e                   	pop    %esi
f0103799:	5f                   	pop    %edi
f010379a:	5d                   	pop    %ebp
f010379b:	c3                   	ret    

f010379c <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f010379c:	55                   	push   %ebp
f010379d:	89 e5                	mov    %esp,%ebp
f010379f:	56                   	push   %esi
f01037a0:	53                   	push   %ebx
f01037a1:	8b 45 08             	mov    0x8(%ebp),%eax
f01037a4:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f01037a7:	85 c0                	test   %eax,%eax
f01037a9:	75 1a                	jne    f01037c5 <envid2env+0x29>
		*env_store = curenv;
f01037ab:	e8 19 28 00 00       	call   f0105fc9 <cpunum>
f01037b0:	6b c0 74             	imul   $0x74,%eax,%eax
f01037b3:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f01037b9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01037bc:	89 01                	mov    %eax,(%ecx)
		return 0;
f01037be:	b8 00 00 00 00       	mov    $0x0,%eax
f01037c3:	eb 70                	jmp    f0103835 <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f01037c5:	89 c3                	mov    %eax,%ebx
f01037c7:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f01037cd:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f01037d0:	03 1d 4c b2 22 f0    	add    0xf022b24c,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f01037d6:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f01037da:	74 05                	je     f01037e1 <envid2env+0x45>
f01037dc:	39 43 48             	cmp    %eax,0x48(%ebx)
f01037df:	74 10                	je     f01037f1 <envid2env+0x55>
		*env_store = 0;
f01037e1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01037e4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01037ea:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01037ef:	eb 44                	jmp    f0103835 <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01037f1:	84 d2                	test   %dl,%dl
f01037f3:	74 36                	je     f010382b <envid2env+0x8f>
f01037f5:	e8 cf 27 00 00       	call   f0105fc9 <cpunum>
f01037fa:	6b c0 74             	imul   $0x74,%eax,%eax
f01037fd:	39 98 28 c0 22 f0    	cmp    %ebx,-0xfdd3fd8(%eax)
f0103803:	74 26                	je     f010382b <envid2env+0x8f>
f0103805:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0103808:	e8 bc 27 00 00       	call   f0105fc9 <cpunum>
f010380d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103810:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103816:	3b 70 48             	cmp    0x48(%eax),%esi
f0103819:	74 10                	je     f010382b <envid2env+0x8f>
		*env_store = 0;
f010381b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010381e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103824:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103829:	eb 0a                	jmp    f0103835 <envid2env+0x99>
	}

	*env_store = e;
f010382b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010382e:	89 18                	mov    %ebx,(%eax)
	return 0;
f0103830:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103835:	5b                   	pop    %ebx
f0103836:	5e                   	pop    %esi
f0103837:	5d                   	pop    %ebp
f0103838:	c3                   	ret    

f0103839 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0103839:	55                   	push   %ebp
f010383a:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f010383c:	b8 20 03 12 f0       	mov    $0xf0120320,%eax
f0103841:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0103844:	b8 23 00 00 00       	mov    $0x23,%eax
f0103849:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f010384b:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f010384d:	b0 10                	mov    $0x10,%al
f010384f:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0103851:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0103853:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f0103855:	ea 5c 38 10 f0 08 00 	ljmp   $0x8,$0xf010385c
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f010385c:	b0 00                	mov    $0x0,%al
f010385e:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0103861:	5d                   	pop    %ebp
f0103862:	c3                   	ret    

f0103863 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0103863:	8b 0d 50 b2 22 f0    	mov    0xf022b250,%ecx
f0103869:	a1 4c b2 22 f0       	mov    0xf022b24c,%eax
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
f010386e:	ba 00 04 00 00       	mov    $0x400,%edx
f0103873:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = NULL;
f010387a:	c7 40 44 00 00 00 00 	movl   $0x0,0x44(%eax)

		if (!env_free_list){		
f0103881:	85 c9                	test   %ecx,%ecx
f0103883:	74 05                	je     f010388a <env_init+0x27>
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
		}
		else{
		envs[i-1].env_link = &envs[i];
f0103885:	89 40 c8             	mov    %eax,-0x38(%eax)
f0103888:	eb 02                	jmp    f010388c <env_init+0x29>
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
		envs[i].env_link = NULL;

		if (!env_free_list){		
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
f010388a:	89 c1                	mov    %eax,%ecx
f010388c:	83 c0 7c             	add    $0x7c,%eax
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
f010388f:	83 ea 01             	sub    $0x1,%edx
f0103892:	75 df                	jne    f0103873 <env_init+0x10>
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0103894:	55                   	push   %ebp
f0103895:	89 e5                	mov    %esp,%ebp
f0103897:	89 0d 50 b2 22 f0    	mov    %ecx,0xf022b250
		}	//Previous env is linked to this current env
	}
	

	// Per-CPU part of the initialization
	env_init_percpu();
f010389d:	e8 97 ff ff ff       	call   f0103839 <env_init_percpu>
}
f01038a2:	5d                   	pop    %ebp
f01038a3:	c3                   	ret    

f01038a4 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01038a4:	55                   	push   %ebp
f01038a5:	89 e5                	mov    %esp,%ebp
f01038a7:	53                   	push   %ebx
f01038a8:	83 ec 14             	sub    $0x14,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f01038ab:	8b 1d 50 b2 22 f0    	mov    0xf022b250,%ebx
f01038b1:	85 db                	test   %ebx,%ebx
f01038b3:	0f 84 8b 01 00 00    	je     f0103a44 <env_alloc+0x1a0>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f01038b9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01038c0:	e8 32 d8 ff ff       	call   f01010f7 <page_alloc>
f01038c5:	85 c0                	test   %eax,%eax
f01038c7:	0f 84 7e 01 00 00    	je     f0103a4b <env_alloc+0x1a7>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f01038cd:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01038d2:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f01038d8:	c1 f8 03             	sar    $0x3,%eax
f01038db:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01038de:	89 c2                	mov    %eax,%edx
f01038e0:	c1 ea 0c             	shr    $0xc,%edx
f01038e3:	3b 15 88 be 22 f0    	cmp    0xf022be88,%edx
f01038e9:	72 20                	jb     f010390b <env_alloc+0x67>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01038eb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01038ef:	c7 44 24 08 e4 66 10 	movl   $0xf01066e4,0x8(%esp)
f01038f6:	f0 
f01038f7:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f01038fe:	00 
f01038ff:	c7 04 24 55 76 10 f0 	movl   $0xf0107655,(%esp)
f0103906:	e8 35 c7 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010390b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103910:	89 43 60             	mov    %eax,0x60(%ebx)
	e->env_pgdir = (pde_t*)page2kva(p);
f0103913:	b8 00 00 00 00       	mov    $0x0,%eax

	for (i = 0; i < NPDENTRIES; ++i) {
		e->env_pgdir[i] = kern_pgdir[i];  //Mapping all 1024 entries of the kernel
f0103918:	8b 15 8c be 22 f0    	mov    0xf022be8c,%edx
f010391e:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f0103921:	8b 53 60             	mov    0x60(%ebx),%edx
f0103924:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f0103927:	83 c0 04             	add    $0x4,%eax

	// LAB 3: Your code here.
	p->pp_ref++;
	e->env_pgdir = (pde_t*)page2kva(p);

	for (i = 0; i < NPDENTRIES; ++i) {
f010392a:	3d 00 10 00 00       	cmp    $0x1000,%eax
f010392f:	75 e7                	jne    f0103918 <env_alloc+0x74>
						 //pgdir to the environment pgdir
	}
	
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0103931:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103934:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103939:	77 20                	ja     f010395b <env_alloc+0xb7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010393b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010393f:	c7 44 24 08 08 67 10 	movl   $0xf0106708,0x8(%esp)
f0103946:	f0 
f0103947:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
f010394e:	00 
f010394f:	c7 04 24 a7 79 10 f0 	movl   $0xf01079a7,(%esp)
f0103956:	e8 e5 c6 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010395b:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0103961:	83 ca 05             	or     $0x5,%edx
f0103964:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f010396a:	8b 43 48             	mov    0x48(%ebx),%eax
f010396d:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0103972:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0103977:	ba 00 10 00 00       	mov    $0x1000,%edx
f010397c:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f010397f:	89 da                	mov    %ebx,%edx
f0103981:	2b 15 4c b2 22 f0    	sub    0xf022b24c,%edx
f0103987:	c1 fa 02             	sar    $0x2,%edx
f010398a:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0103990:	09 d0                	or     %edx,%eax
f0103992:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0103995:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103998:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f010399b:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01039a2:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f01039a9:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01039b0:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f01039b7:	00 
f01039b8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01039bf:	00 
f01039c0:	89 1c 24             	mov    %ebx,(%esp)
f01039c3:	e8 af 1f 00 00       	call   f0105977 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f01039c8:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f01039ce:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f01039d4:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f01039da:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f01039e1:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f01039e7:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f01039ee:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f01039f2:	8b 43 44             	mov    0x44(%ebx),%eax
f01039f5:	a3 50 b2 22 f0       	mov    %eax,0xf022b250
	*newenv_store = e;
f01039fa:	8b 45 08             	mov    0x8(%ebp),%eax
f01039fd:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01039ff:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0103a02:	e8 c2 25 00 00       	call   f0105fc9 <cpunum>
f0103a07:	6b d0 74             	imul   $0x74,%eax,%edx
f0103a0a:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a0f:	83 ba 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%edx)
f0103a16:	74 11                	je     f0103a29 <env_alloc+0x185>
f0103a18:	e8 ac 25 00 00       	call   f0105fc9 <cpunum>
f0103a1d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a20:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103a26:	8b 40 48             	mov    0x48(%eax),%eax
f0103a29:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103a2d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a31:	c7 04 24 b2 79 10 f0 	movl   $0xf01079b2,(%esp)
f0103a38:	e8 7f 06 00 00       	call   f01040bc <cprintf>
	return 0;
f0103a3d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a42:	eb 0c                	jmp    f0103a50 <env_alloc+0x1ac>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103a44:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103a49:	eb 05                	jmp    f0103a50 <env_alloc+0x1ac>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0103a4b:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0103a50:	83 c4 14             	add    $0x14,%esp
f0103a53:	5b                   	pop    %ebx
f0103a54:	5d                   	pop    %ebp
f0103a55:	c3                   	ret    

f0103a56 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103a56:	55                   	push   %ebp
f0103a57:	89 e5                	mov    %esp,%ebp
f0103a59:	57                   	push   %edi
f0103a5a:	56                   	push   %esi
f0103a5b:	53                   	push   %ebx
f0103a5c:	83 ec 3c             	sub    $0x3c,%esp
f0103a5f:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	int r;
	struct Env *env;
	r = env_alloc( &env, 0);
f0103a62:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103a69:	00 
f0103a6a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103a6d:	89 04 24             	mov    %eax,(%esp)
f0103a70:	e8 2f fe ff ff       	call   f01038a4 <env_alloc>
	if (r){
f0103a75:	85 c0                	test   %eax,%eax
f0103a77:	74 20                	je     f0103a99 <env_create+0x43>
	panic("env_alloc: %e", r);
f0103a79:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103a7d:	c7 44 24 08 c7 79 10 	movl   $0xf01079c7,0x8(%esp)
f0103a84:	f0 
f0103a85:	c7 44 24 04 b1 01 00 	movl   $0x1b1,0x4(%esp)
f0103a8c:	00 
f0103a8d:	c7 04 24 a7 79 10 f0 	movl   $0xf01079a7,(%esp)
f0103a94:	e8 a7 c5 ff ff       	call   f0100040 <_panic>
	}
	
	load_icode(env,binary);
f0103a99:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103a9c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Get the beginning and end of program header table
	//Details of struct proghdr are in /lab/inc/elf.h

	// is this a valid ELF?
	
	if (((struct Elf*)binary)->e_magic != ELF_MAGIC)
f0103a9f:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0103aa5:	74 1c                	je     f0103ac3 <env_create+0x6d>
	{
		panic ("Not a valid ELF binary image");
f0103aa7:	c7 44 24 08 d5 79 10 	movl   $0xf01079d5,0x8(%esp)
f0103aae:	f0 
f0103aaf:	c7 44 24 04 80 01 00 	movl   $0x180,0x4(%esp)
f0103ab6:	00 
f0103ab7:	c7 04 24 a7 79 10 f0 	movl   $0xf01079a7,(%esp)
f0103abe:	e8 7d c5 ff ff       	call   f0100040 <_panic>
	}

	struct Proghdr *ph =(struct Proghdr *)(binary + ((struct Elf*)binary)->e_phoff); //phoff is the offset
f0103ac3:	89 fb                	mov    %edi,%ebx
f0103ac5:	03 5f 1c             	add    0x1c(%edi),%ebx
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
f0103ac8:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0103acc:	c1 e6 05             	shl    $0x5,%esi
f0103acf:	01 de                	add    %ebx,%esi
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));
f0103ad1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103ad4:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103ad7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103adc:	77 20                	ja     f0103afe <env_create+0xa8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103ade:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103ae2:	c7 44 24 08 08 67 10 	movl   $0xf0106708,0x8(%esp)
f0103ae9:	f0 
f0103aea:	c7 44 24 04 87 01 00 	movl   $0x187,0x4(%esp)
f0103af1:	00 
f0103af2:	c7 04 24 a7 79 10 f0 	movl   $0xf01079a7,(%esp)
f0103af9:	e8 42 c5 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103afe:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0103b03:	0f 22 d8             	mov    %eax,%cr3
f0103b06:	eb 71                	jmp    f0103b79 <env_create+0x123>

	for (;ph<phEnd;++ph){
		if (ph->p_type == ELF_PROG_LOAD){	//Check whether the type is ELF_PROG_LOAD
f0103b08:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103b0b:	75 69                	jne    f0103b76 <env_create+0x120>
		
		if(ph->p_memsz < ph->p_filesz){
f0103b0d:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103b10:	3b 4b 10             	cmp    0x10(%ebx),%ecx
f0103b13:	73 1c                	jae    f0103b31 <env_create+0xdb>
		panic ("Memory size is smaller than file size!!");
f0103b15:	c7 44 24 08 38 7a 10 	movl   $0xf0107a38,0x8(%esp)
f0103b1c:	f0 
f0103b1d:	c7 44 24 04 8d 01 00 	movl   $0x18d,0x4(%esp)
f0103b24:	00 
f0103b25:	c7 04 24 a7 79 10 f0 	movl   $0xf01079a7,(%esp)
f0103b2c:	e8 0f c5 ff ff       	call   f0100040 <_panic>
		}
		region_alloc(e, (void *)ph->p_va, ph->p_memsz);  //Allocate region per segment
f0103b31:	8b 53 08             	mov    0x8(%ebx),%edx
f0103b34:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103b37:	e8 c5 fb ff ff       	call   f0103701 <region_alloc>
	

		memcpy((void*)ph->p_va, (void*)(binary + ph->p_offset), ph->p_filesz); //Load Binary into memory
f0103b3c:	8b 43 10             	mov    0x10(%ebx),%eax
f0103b3f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103b43:	89 f8                	mov    %edi,%eax
f0103b45:	03 43 04             	add    0x4(%ebx),%eax
f0103b48:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b4c:	8b 43 08             	mov    0x8(%ebx),%eax
f0103b4f:	89 04 24             	mov    %eax,(%esp)
f0103b52:	e8 d5 1e 00 00       	call   f0105a2c <memcpy>

		memset((void*)(ph->p_va + ph->p_filesz),0,ph->p_memsz-ph->p_filesz);  //Clear the rest of the memory, i.e the bss segment
f0103b57:	8b 43 10             	mov    0x10(%ebx),%eax
f0103b5a:	8b 53 14             	mov    0x14(%ebx),%edx
f0103b5d:	29 c2                	sub    %eax,%edx
f0103b5f:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103b63:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103b6a:	00 
f0103b6b:	03 43 08             	add    0x8(%ebx),%eax
f0103b6e:	89 04 24             	mov    %eax,(%esp)
f0103b71:	e8 01 1e 00 00       	call   f0105977 <memset>
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));

	for (;ph<phEnd;++ph){
f0103b76:	83 c3 20             	add    $0x20,%ebx
f0103b79:	39 de                	cmp    %ebx,%esi
f0103b7b:	77 8b                	ja     f0103b08 <env_create+0xb2>
		}
		else{
			continue;
		}
	}
	lcr3(PADDR(kern_pgdir));   //Switch back to Kernel page directory
f0103b7d:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103b82:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103b87:	77 20                	ja     f0103ba9 <env_create+0x153>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103b89:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103b8d:	c7 44 24 08 08 67 10 	movl   $0xf0106708,0x8(%esp)
f0103b94:	f0 
f0103b95:	c7 44 24 04 9a 01 00 	movl   $0x19a,0x4(%esp)
f0103b9c:	00 
f0103b9d:	c7 04 24 a7 79 10 f0 	movl   $0xf01079a7,(%esp)
f0103ba4:	e8 97 c4 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103ba9:	05 00 00 00 10       	add    $0x10000000,%eax
f0103bae:	0f 22 d8             	mov    %eax,%cr3
	
	e->env_tf.tf_eip = ((struct Elf*)binary)->e_entry;   //Define the entry point of the env from the ELF binary entry point
f0103bb1:	8b 47 18             	mov    0x18(%edi),%eax
f0103bb4:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103bb7:	89 47 30             	mov    %eax,0x30(%edi)

	region_alloc(e,(void *)USTACKTOP - PGSIZE, PGSIZE);
f0103bba:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103bbf:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103bc4:	89 f8                	mov    %edi,%eax
f0103bc6:	e8 36 fb ff ff       	call   f0103701 <region_alloc>
	if (r){
	panic("env_alloc: %e", r);
	}
	
	load_icode(env,binary);
	env->env_type = type;
f0103bcb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103bce:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103bd1:	89 50 50             	mov    %edx,0x50(%eax)
}
f0103bd4:	83 c4 3c             	add    $0x3c,%esp
f0103bd7:	5b                   	pop    %ebx
f0103bd8:	5e                   	pop    %esi
f0103bd9:	5f                   	pop    %edi
f0103bda:	5d                   	pop    %ebp
f0103bdb:	c3                   	ret    

f0103bdc <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103bdc:	55                   	push   %ebp
f0103bdd:	89 e5                	mov    %esp,%ebp
f0103bdf:	57                   	push   %edi
f0103be0:	56                   	push   %esi
f0103be1:	53                   	push   %ebx
f0103be2:	83 ec 2c             	sub    $0x2c,%esp
f0103be5:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103be8:	e8 dc 23 00 00       	call   f0105fc9 <cpunum>
f0103bed:	6b c0 74             	imul   $0x74,%eax,%eax
f0103bf0:	39 b8 28 c0 22 f0    	cmp    %edi,-0xfdd3fd8(%eax)
f0103bf6:	75 34                	jne    f0103c2c <env_free+0x50>
		lcr3(PADDR(kern_pgdir));
f0103bf8:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103bfd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103c02:	77 20                	ja     f0103c24 <env_free+0x48>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103c04:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103c08:	c7 44 24 08 08 67 10 	movl   $0xf0106708,0x8(%esp)
f0103c0f:	f0 
f0103c10:	c7 44 24 04 c7 01 00 	movl   $0x1c7,0x4(%esp)
f0103c17:	00 
f0103c18:	c7 04 24 a7 79 10 f0 	movl   $0xf01079a7,(%esp)
f0103c1f:	e8 1c c4 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103c24:	05 00 00 00 10       	add    $0x10000000,%eax
f0103c29:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103c2c:	8b 5f 48             	mov    0x48(%edi),%ebx
f0103c2f:	e8 95 23 00 00       	call   f0105fc9 <cpunum>
f0103c34:	6b d0 74             	imul   $0x74,%eax,%edx
f0103c37:	b8 00 00 00 00       	mov    $0x0,%eax
f0103c3c:	83 ba 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%edx)
f0103c43:	74 11                	je     f0103c56 <env_free+0x7a>
f0103c45:	e8 7f 23 00 00       	call   f0105fc9 <cpunum>
f0103c4a:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c4d:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103c53:	8b 40 48             	mov    0x48(%eax),%eax
f0103c56:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103c5a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c5e:	c7 04 24 f2 79 10 f0 	movl   $0xf01079f2,(%esp)
f0103c65:	e8 52 04 00 00       	call   f01040bc <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103c6a:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103c71:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103c74:	89 c8                	mov    %ecx,%eax
f0103c76:	c1 e0 02             	shl    $0x2,%eax
f0103c79:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103c7c:	8b 47 60             	mov    0x60(%edi),%eax
f0103c7f:	8b 34 88             	mov    (%eax,%ecx,4),%esi
f0103c82:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103c88:	0f 84 b7 00 00 00    	je     f0103d45 <env_free+0x169>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103c8e:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103c94:	89 f0                	mov    %esi,%eax
f0103c96:	c1 e8 0c             	shr    $0xc,%eax
f0103c99:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103c9c:	3b 05 88 be 22 f0    	cmp    0xf022be88,%eax
f0103ca2:	72 20                	jb     f0103cc4 <env_free+0xe8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103ca4:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103ca8:	c7 44 24 08 e4 66 10 	movl   $0xf01066e4,0x8(%esp)
f0103caf:	f0 
f0103cb0:	c7 44 24 04 d6 01 00 	movl   $0x1d6,0x4(%esp)
f0103cb7:	00 
f0103cb8:	c7 04 24 a7 79 10 f0 	movl   $0xf01079a7,(%esp)
f0103cbf:	e8 7c c3 ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103cc4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103cc7:	c1 e0 16             	shl    $0x16,%eax
f0103cca:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103ccd:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103cd2:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103cd9:	01 
f0103cda:	74 17                	je     f0103cf3 <env_free+0x117>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103cdc:	89 d8                	mov    %ebx,%eax
f0103cde:	c1 e0 0c             	shl    $0xc,%eax
f0103ce1:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103ce4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ce8:	8b 47 60             	mov    0x60(%edi),%eax
f0103ceb:	89 04 24             	mov    %eax,(%esp)
f0103cee:	e8 3f d7 ff ff       	call   f0101432 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103cf3:	83 c3 01             	add    $0x1,%ebx
f0103cf6:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103cfc:	75 d4                	jne    f0103cd2 <env_free+0xf6>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103cfe:	8b 47 60             	mov    0x60(%edi),%eax
f0103d01:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103d04:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103d0b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103d0e:	3b 05 88 be 22 f0    	cmp    0xf022be88,%eax
f0103d14:	72 1c                	jb     f0103d32 <env_free+0x156>
		panic("pa2page called with invalid pa");
f0103d16:	c7 44 24 08 60 7a 10 	movl   $0xf0107a60,0x8(%esp)
f0103d1d:	f0 
f0103d1e:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
f0103d25:	00 
f0103d26:	c7 04 24 55 76 10 f0 	movl   $0xf0107655,(%esp)
f0103d2d:	e8 0e c3 ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0103d32:	a1 90 be 22 f0       	mov    0xf022be90,%eax
f0103d37:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103d3a:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		page_decref(pa2page(pa));
f0103d3d:	89 04 24             	mov    %eax,(%esp)
f0103d40:	e8 9e d4 ff ff       	call   f01011e3 <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103d45:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103d49:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f0103d50:	0f 85 1b ff ff ff    	jne    f0103c71 <env_free+0x95>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103d56:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103d59:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103d5e:	77 20                	ja     f0103d80 <env_free+0x1a4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103d60:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103d64:	c7 44 24 08 08 67 10 	movl   $0xf0106708,0x8(%esp)
f0103d6b:	f0 
f0103d6c:	c7 44 24 04 e4 01 00 	movl   $0x1e4,0x4(%esp)
f0103d73:	00 
f0103d74:	c7 04 24 a7 79 10 f0 	movl   $0xf01079a7,(%esp)
f0103d7b:	e8 c0 c2 ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f0103d80:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103d87:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103d8c:	c1 e8 0c             	shr    $0xc,%eax
f0103d8f:	3b 05 88 be 22 f0    	cmp    0xf022be88,%eax
f0103d95:	72 1c                	jb     f0103db3 <env_free+0x1d7>
		panic("pa2page called with invalid pa");
f0103d97:	c7 44 24 08 60 7a 10 	movl   $0xf0107a60,0x8(%esp)
f0103d9e:	f0 
f0103d9f:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
f0103da6:	00 
f0103da7:	c7 04 24 55 76 10 f0 	movl   $0xf0107655,(%esp)
f0103dae:	e8 8d c2 ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0103db3:	8b 15 90 be 22 f0    	mov    0xf022be90,%edx
f0103db9:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	page_decref(pa2page(pa));
f0103dbc:	89 04 24             	mov    %eax,(%esp)
f0103dbf:	e8 1f d4 ff ff       	call   f01011e3 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103dc4:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103dcb:	a1 50 b2 22 f0       	mov    0xf022b250,%eax
f0103dd0:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103dd3:	89 3d 50 b2 22 f0    	mov    %edi,0xf022b250
}
f0103dd9:	83 c4 2c             	add    $0x2c,%esp
f0103ddc:	5b                   	pop    %ebx
f0103ddd:	5e                   	pop    %esi
f0103dde:	5f                   	pop    %edi
f0103ddf:	5d                   	pop    %ebp
f0103de0:	c3                   	ret    

f0103de1 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103de1:	55                   	push   %ebp
f0103de2:	89 e5                	mov    %esp,%ebp
f0103de4:	53                   	push   %ebx
f0103de5:	83 ec 14             	sub    $0x14,%esp
f0103de8:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f0103deb:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f0103def:	75 19                	jne    f0103e0a <env_destroy+0x29>
f0103df1:	e8 d3 21 00 00       	call   f0105fc9 <cpunum>
f0103df6:	6b c0 74             	imul   $0x74,%eax,%eax
f0103df9:	39 98 28 c0 22 f0    	cmp    %ebx,-0xfdd3fd8(%eax)
f0103dff:	74 09                	je     f0103e0a <env_destroy+0x29>
		e->env_status = ENV_DYING;
f0103e01:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f0103e08:	eb 2f                	jmp    f0103e39 <env_destroy+0x58>
	}

	env_free(e);
f0103e0a:	89 1c 24             	mov    %ebx,(%esp)
f0103e0d:	e8 ca fd ff ff       	call   f0103bdc <env_free>

	if (curenv == e) {
f0103e12:	e8 b2 21 00 00       	call   f0105fc9 <cpunum>
f0103e17:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e1a:	39 98 28 c0 22 f0    	cmp    %ebx,-0xfdd3fd8(%eax)
f0103e20:	75 17                	jne    f0103e39 <env_destroy+0x58>
		curenv = NULL;
f0103e22:	e8 a2 21 00 00       	call   f0105fc9 <cpunum>
f0103e27:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e2a:	c7 80 28 c0 22 f0 00 	movl   $0x0,-0xfdd3fd8(%eax)
f0103e31:	00 00 00 
		sched_yield();
f0103e34:	e8 7d 0a 00 00       	call   f01048b6 <sched_yield>
	}
}
f0103e39:	83 c4 14             	add    $0x14,%esp
f0103e3c:	5b                   	pop    %ebx
f0103e3d:	5d                   	pop    %ebp
f0103e3e:	c3                   	ret    

f0103e3f <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103e3f:	55                   	push   %ebp
f0103e40:	89 e5                	mov    %esp,%ebp
f0103e42:	53                   	push   %ebx
f0103e43:	83 ec 14             	sub    $0x14,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f0103e46:	e8 7e 21 00 00       	call   f0105fc9 <cpunum>
f0103e4b:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e4e:	8b 98 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%ebx
f0103e54:	e8 70 21 00 00       	call   f0105fc9 <cpunum>
f0103e59:	89 43 5c             	mov    %eax,0x5c(%ebx)

	__asm __volatile("movl %0,%%esp\n"
f0103e5c:	8b 65 08             	mov    0x8(%ebp),%esp
f0103e5f:	61                   	popa   
f0103e60:	07                   	pop    %es
f0103e61:	1f                   	pop    %ds
f0103e62:	83 c4 08             	add    $0x8,%esp
f0103e65:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103e66:	c7 44 24 08 08 7a 10 	movl   $0xf0107a08,0x8(%esp)
f0103e6d:	f0 
f0103e6e:	c7 44 24 04 1a 02 00 	movl   $0x21a,0x4(%esp)
f0103e75:	00 
f0103e76:	c7 04 24 a7 79 10 f0 	movl   $0xf01079a7,(%esp)
f0103e7d:	e8 be c1 ff ff       	call   f0100040 <_panic>

f0103e82 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103e82:	55                   	push   %ebp
f0103e83:	89 e5                	mov    %esp,%ebp
f0103e85:	53                   	push   %ebx
f0103e86:	83 ec 14             	sub    $0x14,%esp
f0103e89:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	//check if this is the first call to env_run
	if (curenv == NULL){
f0103e8c:	e8 38 21 00 00       	call   f0105fc9 <cpunum>
f0103e91:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e94:	83 b8 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%eax)
f0103e9b:	75 10                	jne    f0103ead <env_run+0x2b>
	curenv = e;
f0103e9d:	e8 27 21 00 00       	call   f0105fc9 <cpunum>
f0103ea2:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ea5:	89 98 28 c0 22 f0    	mov    %ebx,-0xfdd3fd8(%eax)
f0103eab:	eb 29                	jmp    f0103ed6 <env_run+0x54>
	}
	
	//If curenv state is running mode , set it to runnable 
	else if (curenv->env_status == ENV_RUNNING){
f0103ead:	e8 17 21 00 00       	call   f0105fc9 <cpunum>
f0103eb2:	6b c0 74             	imul   $0x74,%eax,%eax
f0103eb5:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103ebb:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103ebf:	75 15                	jne    f0103ed6 <env_run+0x54>
	 curenv->env_status = ENV_RUNNABLE;
f0103ec1:	e8 03 21 00 00       	call   f0105fc9 <cpunum>
f0103ec6:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ec9:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103ecf:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	curenv = e;	//Set the current environment to the new env
f0103ed6:	e8 ee 20 00 00       	call   f0105fc9 <cpunum>
f0103edb:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ede:	89 98 28 c0 22 f0    	mov    %ebx,-0xfdd3fd8(%eax)
	curenv->env_status = ENV_RUNNING; //Set it to running state
f0103ee4:	e8 e0 20 00 00       	call   f0105fc9 <cpunum>
f0103ee9:	6b c0 74             	imul   $0x74,%eax,%eax
f0103eec:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103ef2:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;	// Increment the env_runs counter
f0103ef9:	e8 cb 20 00 00       	call   f0105fc9 <cpunum>
f0103efe:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f01:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103f07:	83 40 58 01          	addl   $0x1,0x58(%eax)
	
	lcr3(PADDR(e->env_pgdir));	//Use lcr3 to switch to the env directory
f0103f0b:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103f0e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103f13:	77 20                	ja     f0103f35 <env_run+0xb3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103f15:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103f19:	c7 44 24 08 08 67 10 	movl   $0xf0106708,0x8(%esp)
f0103f20:	f0 
f0103f21:	c7 44 24 04 46 02 00 	movl   $0x246,0x4(%esp)
f0103f28:	00 
f0103f29:	c7 04 24 a7 79 10 f0 	movl   $0xf01079a7,(%esp)
f0103f30:	e8 0b c1 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103f35:	05 00 00 00 10       	add    $0x10000000,%eax
f0103f3a:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0103f3d:	c7 04 24 80 04 12 f0 	movl   $0xf0120480,(%esp)
f0103f44:	e8 aa 23 00 00       	call   f01062f3 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0103f49:	f3 90                	pause  
	unlock_kernel();
	env_pop_tf(&e->env_tf);
f0103f4b:	89 1c 24             	mov    %ebx,(%esp)
f0103f4e:	e8 ec fe ff ff       	call   f0103e3f <env_pop_tf>

f0103f53 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103f53:	55                   	push   %ebp
f0103f54:	89 e5                	mov    %esp,%ebp
f0103f56:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103f5a:	ba 70 00 00 00       	mov    $0x70,%edx
f0103f5f:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103f60:	b2 71                	mov    $0x71,%dl
f0103f62:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103f63:	0f b6 c0             	movzbl %al,%eax
}
f0103f66:	5d                   	pop    %ebp
f0103f67:	c3                   	ret    

f0103f68 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103f68:	55                   	push   %ebp
f0103f69:	89 e5                	mov    %esp,%ebp
f0103f6b:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103f6f:	ba 70 00 00 00       	mov    $0x70,%edx
f0103f74:	ee                   	out    %al,(%dx)
f0103f75:	b2 71                	mov    $0x71,%dl
f0103f77:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103f7a:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103f7b:	5d                   	pop    %ebp
f0103f7c:	c3                   	ret    

f0103f7d <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103f7d:	55                   	push   %ebp
f0103f7e:	89 e5                	mov    %esp,%ebp
f0103f80:	56                   	push   %esi
f0103f81:	53                   	push   %ebx
f0103f82:	83 ec 10             	sub    $0x10,%esp
f0103f85:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103f88:	66 a3 a8 03 12 f0    	mov    %ax,0xf01203a8
	if (!didinit)
f0103f8e:	80 3d 54 b2 22 f0 00 	cmpb   $0x0,0xf022b254
f0103f95:	74 4e                	je     f0103fe5 <irq_setmask_8259A+0x68>
f0103f97:	89 c6                	mov    %eax,%esi
f0103f99:	ba 21 00 00 00       	mov    $0x21,%edx
f0103f9e:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
f0103f9f:	66 c1 e8 08          	shr    $0x8,%ax
f0103fa3:	b2 a1                	mov    $0xa1,%dl
f0103fa5:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f0103fa6:	c7 04 24 7f 7a 10 f0 	movl   $0xf0107a7f,(%esp)
f0103fad:	e8 0a 01 00 00       	call   f01040bc <cprintf>
	for (i = 0; i < 16; i++)
f0103fb2:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103fb7:	0f b7 f6             	movzwl %si,%esi
f0103fba:	f7 d6                	not    %esi
f0103fbc:	0f a3 de             	bt     %ebx,%esi
f0103fbf:	73 10                	jae    f0103fd1 <irq_setmask_8259A+0x54>
			cprintf(" %d", i);
f0103fc1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103fc5:	c7 04 24 97 7f 10 f0 	movl   $0xf0107f97,(%esp)
f0103fcc:	e8 eb 00 00 00       	call   f01040bc <cprintf>
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f0103fd1:	83 c3 01             	add    $0x1,%ebx
f0103fd4:	83 fb 10             	cmp    $0x10,%ebx
f0103fd7:	75 e3                	jne    f0103fbc <irq_setmask_8259A+0x3f>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f0103fd9:	c7 04 24 32 7f 10 f0 	movl   $0xf0107f32,(%esp)
f0103fe0:	e8 d7 00 00 00       	call   f01040bc <cprintf>
}
f0103fe5:	83 c4 10             	add    $0x10,%esp
f0103fe8:	5b                   	pop    %ebx
f0103fe9:	5e                   	pop    %esi
f0103fea:	5d                   	pop    %ebp
f0103feb:	c3                   	ret    

f0103fec <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f0103fec:	c6 05 54 b2 22 f0 01 	movb   $0x1,0xf022b254
f0103ff3:	ba 21 00 00 00       	mov    $0x21,%edx
f0103ff8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103ffd:	ee                   	out    %al,(%dx)
f0103ffe:	b2 a1                	mov    $0xa1,%dl
f0104000:	ee                   	out    %al,(%dx)
f0104001:	b2 20                	mov    $0x20,%dl
f0104003:	b8 11 00 00 00       	mov    $0x11,%eax
f0104008:	ee                   	out    %al,(%dx)
f0104009:	b2 21                	mov    $0x21,%dl
f010400b:	b8 20 00 00 00       	mov    $0x20,%eax
f0104010:	ee                   	out    %al,(%dx)
f0104011:	b8 04 00 00 00       	mov    $0x4,%eax
f0104016:	ee                   	out    %al,(%dx)
f0104017:	b8 03 00 00 00       	mov    $0x3,%eax
f010401c:	ee                   	out    %al,(%dx)
f010401d:	b2 a0                	mov    $0xa0,%dl
f010401f:	b8 11 00 00 00       	mov    $0x11,%eax
f0104024:	ee                   	out    %al,(%dx)
f0104025:	b2 a1                	mov    $0xa1,%dl
f0104027:	b8 28 00 00 00       	mov    $0x28,%eax
f010402c:	ee                   	out    %al,(%dx)
f010402d:	b8 02 00 00 00       	mov    $0x2,%eax
f0104032:	ee                   	out    %al,(%dx)
f0104033:	b8 01 00 00 00       	mov    $0x1,%eax
f0104038:	ee                   	out    %al,(%dx)
f0104039:	b2 20                	mov    $0x20,%dl
f010403b:	b8 68 00 00 00       	mov    $0x68,%eax
f0104040:	ee                   	out    %al,(%dx)
f0104041:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104046:	ee                   	out    %al,(%dx)
f0104047:	b2 a0                	mov    $0xa0,%dl
f0104049:	b8 68 00 00 00       	mov    $0x68,%eax
f010404e:	ee                   	out    %al,(%dx)
f010404f:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104054:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f0104055:	0f b7 05 a8 03 12 f0 	movzwl 0xf01203a8,%eax
f010405c:	66 83 f8 ff          	cmp    $0xffff,%ax
f0104060:	74 12                	je     f0104074 <pic_init+0x88>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f0104062:	55                   	push   %ebp
f0104063:	89 e5                	mov    %esp,%ebp
f0104065:	83 ec 18             	sub    $0x18,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f0104068:	0f b7 c0             	movzwl %ax,%eax
f010406b:	89 04 24             	mov    %eax,(%esp)
f010406e:	e8 0a ff ff ff       	call   f0103f7d <irq_setmask_8259A>
}
f0104073:	c9                   	leave  
f0104074:	f3 c3                	repz ret 

f0104076 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0104076:	55                   	push   %ebp
f0104077:	89 e5                	mov    %esp,%ebp
f0104079:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010407c:	8b 45 08             	mov    0x8(%ebp),%eax
f010407f:	89 04 24             	mov    %eax,(%esp)
f0104082:	e8 b3 c6 ff ff       	call   f010073a <cputchar>
	*cnt++;
}
f0104087:	c9                   	leave  
f0104088:	c3                   	ret    

f0104089 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0104089:	55                   	push   %ebp
f010408a:	89 e5                	mov    %esp,%ebp
f010408c:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f010408f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0104096:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104099:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010409d:	8b 45 08             	mov    0x8(%ebp),%eax
f01040a0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01040a4:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01040a7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01040ab:	c7 04 24 76 40 10 f0 	movl   $0xf0104076,(%esp)
f01040b2:	e8 07 12 00 00       	call   f01052be <vprintfmt>
	return cnt;
}
f01040b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01040ba:	c9                   	leave  
f01040bb:	c3                   	ret    

f01040bc <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01040bc:	55                   	push   %ebp
f01040bd:	89 e5                	mov    %esp,%ebp
f01040bf:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01040c2:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01040c5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01040c9:	8b 45 08             	mov    0x8(%ebp),%eax
f01040cc:	89 04 24             	mov    %eax,(%esp)
f01040cf:	e8 b5 ff ff ff       	call   f0104089 <vcprintf>
	va_end(ap);

	return cnt;
}
f01040d4:	c9                   	leave  
f01040d5:	c3                   	ret    
f01040d6:	66 90                	xchg   %ax,%ax
f01040d8:	66 90                	xchg   %ax,%ax
f01040da:	66 90                	xchg   %ax,%ax
f01040dc:	66 90                	xchg   %ax,%ax
f01040de:	66 90                	xchg   %ax,%ax

f01040e0 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01040e0:	55                   	push   %ebp
f01040e1:	89 e5                	mov    %esp,%ebp
f01040e3:	56                   	push   %esi
f01040e4:	53                   	push   %ebx
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);
	// Load the IDT
	lidt(&idt_pd);  */
	
	int i = cpunum();
f01040e5:	e8 df 1e 00 00       	call   f0105fc9 <cpunum>
f01040ea:	89 c3                	mov    %eax,%ebx
	

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	thiscpu->cpu_ts.ts_esp0 = (uintptr_t)(percpu_kstacks[cpunum()] + KSTKSIZE);
f01040ec:	e8 d8 1e 00 00       	call   f0105fc9 <cpunum>
f01040f1:	89 c6                	mov    %eax,%esi
f01040f3:	e8 d1 1e 00 00       	call   f0105fc9 <cpunum>
f01040f8:	6b f6 74             	imul   $0x74,%esi,%esi
f01040fb:	c1 e0 0f             	shl    $0xf,%eax
f01040fe:	8d 80 00 50 23 f0    	lea    -0xfdcb000(%eax),%eax
f0104104:	89 86 30 c0 22 f0    	mov    %eax,-0xfdd3fd0(%esi)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f010410a:	e8 ba 1e 00 00       	call   f0105fc9 <cpunum>
f010410f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104112:	66 c7 80 34 c0 22 f0 	movw   $0x10,-0xfdd3fcc(%eax)
f0104119:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3)+i] = SEG16(STS_T32A, (uint32_t) (&cpus[i].cpu_ts),  //It was (&ts) instead of &cpus[i].cpu_ts
f010411b:	8d 53 05             	lea    0x5(%ebx),%edx
f010411e:	6b c3 74             	imul   $0x74,%ebx,%eax
f0104121:	05 2c c0 22 f0       	add    $0xf022c02c,%eax
f0104126:	66 c7 04 d5 40 03 12 	movw   $0x67,-0xfedfcc0(,%edx,8)
f010412d:	f0 67 00 
f0104130:	66 89 04 d5 42 03 12 	mov    %ax,-0xfedfcbe(,%edx,8)
f0104137:	f0 
f0104138:	89 c1                	mov    %eax,%ecx
f010413a:	c1 e9 10             	shr    $0x10,%ecx
f010413d:	88 0c d5 44 03 12 f0 	mov    %cl,-0xfedfcbc(,%edx,8)
f0104144:	c6 04 d5 46 03 12 f0 	movb   $0x40,-0xfedfcba(,%edx,8)
f010414b:	40 
f010414c:	c1 e8 18             	shr    $0x18,%eax
f010414f:	88 04 d5 47 03 12 f0 	mov    %al,-0xfedfcb9(,%edx,8)
					sizeof(struct Taskstate)-1, 0);
	gdt[(GD_TSS0 >> 3)+i].sd_s = 0;
f0104156:	c6 04 d5 45 03 12 f0 	movb   $0x89,-0xfedfcbb(,%edx,8)
f010415d:	89 

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(((GD_TSS0>>3) + i) << 3);	
f010415e:	8d 1c dd 28 00 00 00 	lea    0x28(,%ebx,8),%ebx
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f0104165:	0f 00 db             	ltr    %bx
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0104168:	b8 aa 03 12 f0       	mov    $0xf01203aa,%eax
f010416d:	0f 01 18             	lidtl  (%eax)
	lidt(&idt_pd); 
	
	


}
f0104170:	5b                   	pop    %ebx
f0104171:	5e                   	pop    %esi
f0104172:	5d                   	pop    %ebp
f0104173:	c3                   	ret    

f0104174 <trap_init>:
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i; 
	for (i=0; i<= T_SIMDERR;i++){
f0104174:	b8 00 00 00 00       	mov    $0x0,%eax
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
f0104179:	8b 14 85 b0 03 12 f0 	mov    -0xfedfc50(,%eax,4),%edx
f0104180:	66 89 14 c5 60 b2 22 	mov    %dx,-0xfdd4da0(,%eax,8)
f0104187:	f0 
f0104188:	66 c7 04 c5 62 b2 22 	movw   $0x8,-0xfdd4d9e(,%eax,8)
f010418f:	f0 08 00 
f0104192:	c6 04 c5 64 b2 22 f0 	movb   $0x0,-0xfdd4d9c(,%eax,8)
f0104199:	00 
f010419a:	c6 04 c5 65 b2 22 f0 	movb   $0x8e,-0xfdd4d9b(,%eax,8)
f01041a1:	8e 
f01041a2:	c1 ea 10             	shr    $0x10,%edx
f01041a5:	66 89 14 c5 66 b2 22 	mov    %dx,-0xfdd4d9a(,%eax,8)
f01041ac:	f0 
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i; 
	for (i=0; i<= T_SIMDERR;i++){
f01041ad:	83 c0 01             	add    $0x1,%eax
f01041b0:	83 f8 14             	cmp    $0x14,%eax
f01041b3:	75 c4                	jne    f0104179 <trap_init+0x5>
}


void
trap_init(void)
{
f01041b5:	55                   	push   %ebp
f01041b6:	89 e5                	mov    %esp,%ebp
f01041b8:	83 ec 08             	sub    $0x8,%esp
	for (i=0; i<= T_SIMDERR;i++){
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
	}

	//Interrupt 3 is a soft interrupt generated by user, hence the dpl of the gate will be checked with 3
  	SETGATE(idt[3],0,GD_KT,int_vector_table[3],3);
f01041bb:	a1 bc 03 12 f0       	mov    0xf01203bc,%eax
f01041c0:	66 a3 78 b2 22 f0    	mov    %ax,0xf022b278
f01041c6:	66 c7 05 7a b2 22 f0 	movw   $0x8,0xf022b27a
f01041cd:	08 00 
f01041cf:	c6 05 7c b2 22 f0 00 	movb   $0x0,0xf022b27c
f01041d6:	c6 05 7d b2 22 f0 ee 	movb   $0xee,0xf022b27d
f01041dd:	c1 e8 10             	shr    $0x10,%eax
f01041e0:	66 a3 7e b2 22 f0    	mov    %ax,0xf022b27e

	//similarly system call is setup by the user and hence the gate should be checked with 3 
	SETGATE(idt[T_SYSCALL], 0, GD_KT, int_vector_table[T_SYSCALL], 3);// T_SYSCALL = 3
f01041e6:	a1 70 04 12 f0       	mov    0xf0120470,%eax
f01041eb:	66 a3 e0 b3 22 f0    	mov    %ax,0xf022b3e0
f01041f1:	66 c7 05 e2 b3 22 f0 	movw   $0x8,0xf022b3e2
f01041f8:	08 00 
f01041fa:	c6 05 e4 b3 22 f0 00 	movb   $0x0,0xf022b3e4
f0104201:	c6 05 e5 b3 22 f0 ee 	movb   $0xee,0xf022b3e5
f0104208:	c1 e8 10             	shr    $0x10,%eax
f010420b:	66 a3 e6 b3 22 f0    	mov    %ax,0xf022b3e6

	// Per-CPU setup 
	trap_init_percpu();
f0104211:	e8 ca fe ff ff       	call   f01040e0 <trap_init_percpu>
}
f0104216:	c9                   	leave  
f0104217:	c3                   	ret    

f0104218 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0104218:	55                   	push   %ebp
f0104219:	89 e5                	mov    %esp,%ebp
f010421b:	53                   	push   %ebx
f010421c:	83 ec 14             	sub    $0x14,%esp
f010421f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0104222:	8b 03                	mov    (%ebx),%eax
f0104224:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104228:	c7 04 24 93 7a 10 f0 	movl   $0xf0107a93,(%esp)
f010422f:	e8 88 fe ff ff       	call   f01040bc <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0104234:	8b 43 04             	mov    0x4(%ebx),%eax
f0104237:	89 44 24 04          	mov    %eax,0x4(%esp)
f010423b:	c7 04 24 a2 7a 10 f0 	movl   $0xf0107aa2,(%esp)
f0104242:	e8 75 fe ff ff       	call   f01040bc <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0104247:	8b 43 08             	mov    0x8(%ebx),%eax
f010424a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010424e:	c7 04 24 b1 7a 10 f0 	movl   $0xf0107ab1,(%esp)
f0104255:	e8 62 fe ff ff       	call   f01040bc <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f010425a:	8b 43 0c             	mov    0xc(%ebx),%eax
f010425d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104261:	c7 04 24 c0 7a 10 f0 	movl   $0xf0107ac0,(%esp)
f0104268:	e8 4f fe ff ff       	call   f01040bc <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f010426d:	8b 43 10             	mov    0x10(%ebx),%eax
f0104270:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104274:	c7 04 24 cf 7a 10 f0 	movl   $0xf0107acf,(%esp)
f010427b:	e8 3c fe ff ff       	call   f01040bc <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0104280:	8b 43 14             	mov    0x14(%ebx),%eax
f0104283:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104287:	c7 04 24 de 7a 10 f0 	movl   $0xf0107ade,(%esp)
f010428e:	e8 29 fe ff ff       	call   f01040bc <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0104293:	8b 43 18             	mov    0x18(%ebx),%eax
f0104296:	89 44 24 04          	mov    %eax,0x4(%esp)
f010429a:	c7 04 24 ed 7a 10 f0 	movl   $0xf0107aed,(%esp)
f01042a1:	e8 16 fe ff ff       	call   f01040bc <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f01042a6:	8b 43 1c             	mov    0x1c(%ebx),%eax
f01042a9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01042ad:	c7 04 24 fc 7a 10 f0 	movl   $0xf0107afc,(%esp)
f01042b4:	e8 03 fe ff ff       	call   f01040bc <cprintf>
}
f01042b9:	83 c4 14             	add    $0x14,%esp
f01042bc:	5b                   	pop    %ebx
f01042bd:	5d                   	pop    %ebp
f01042be:	c3                   	ret    

f01042bf <print_trapframe>:

}

void
print_trapframe(struct Trapframe *tf)
{
f01042bf:	55                   	push   %ebp
f01042c0:	89 e5                	mov    %esp,%ebp
f01042c2:	56                   	push   %esi
f01042c3:	53                   	push   %ebx
f01042c4:	83 ec 10             	sub    $0x10,%esp
f01042c7:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f01042ca:	e8 fa 1c 00 00       	call   f0105fc9 <cpunum>
f01042cf:	89 44 24 08          	mov    %eax,0x8(%esp)
f01042d3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01042d7:	c7 04 24 60 7b 10 f0 	movl   $0xf0107b60,(%esp)
f01042de:	e8 d9 fd ff ff       	call   f01040bc <cprintf>
	print_regs(&tf->tf_regs);
f01042e3:	89 1c 24             	mov    %ebx,(%esp)
f01042e6:	e8 2d ff ff ff       	call   f0104218 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f01042eb:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f01042ef:	89 44 24 04          	mov    %eax,0x4(%esp)
f01042f3:	c7 04 24 7e 7b 10 f0 	movl   $0xf0107b7e,(%esp)
f01042fa:	e8 bd fd ff ff       	call   f01040bc <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f01042ff:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0104303:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104307:	c7 04 24 91 7b 10 f0 	movl   $0xf0107b91,(%esp)
f010430e:	e8 a9 fd ff ff       	call   f01040bc <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0104313:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0104316:	83 f8 13             	cmp    $0x13,%eax
f0104319:	77 09                	ja     f0104324 <print_trapframe+0x65>
		return excnames[trapno];
f010431b:	8b 14 85 60 7e 10 f0 	mov    -0xfef81a0(,%eax,4),%edx
f0104322:	eb 1f                	jmp    f0104343 <print_trapframe+0x84>
	if (trapno == T_SYSCALL)
f0104324:	83 f8 30             	cmp    $0x30,%eax
f0104327:	74 15                	je     f010433e <print_trapframe+0x7f>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0104329:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
f010432c:	83 fa 0f             	cmp    $0xf,%edx
f010432f:	ba 17 7b 10 f0       	mov    $0xf0107b17,%edx
f0104334:	b9 2a 7b 10 f0       	mov    $0xf0107b2a,%ecx
f0104339:	0f 47 d1             	cmova  %ecx,%edx
f010433c:	eb 05                	jmp    f0104343 <print_trapframe+0x84>
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f010433e:	ba 0b 7b 10 f0       	mov    $0xf0107b0b,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0104343:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104347:	89 44 24 04          	mov    %eax,0x4(%esp)
f010434b:	c7 04 24 a4 7b 10 f0 	movl   $0xf0107ba4,(%esp)
f0104352:	e8 65 fd ff ff       	call   f01040bc <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0104357:	3b 1d 60 ba 22 f0    	cmp    0xf022ba60,%ebx
f010435d:	75 19                	jne    f0104378 <print_trapframe+0xb9>
f010435f:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0104363:	75 13                	jne    f0104378 <print_trapframe+0xb9>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0104365:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0104368:	89 44 24 04          	mov    %eax,0x4(%esp)
f010436c:	c7 04 24 b6 7b 10 f0 	movl   $0xf0107bb6,(%esp)
f0104373:	e8 44 fd ff ff       	call   f01040bc <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f0104378:	8b 43 2c             	mov    0x2c(%ebx),%eax
f010437b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010437f:	c7 04 24 c5 7b 10 f0 	movl   $0xf0107bc5,(%esp)
f0104386:	e8 31 fd ff ff       	call   f01040bc <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f010438b:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010438f:	75 51                	jne    f01043e2 <print_trapframe+0x123>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0104391:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0104394:	89 c2                	mov    %eax,%edx
f0104396:	83 e2 01             	and    $0x1,%edx
f0104399:	ba 39 7b 10 f0       	mov    $0xf0107b39,%edx
f010439e:	b9 44 7b 10 f0       	mov    $0xf0107b44,%ecx
f01043a3:	0f 45 ca             	cmovne %edx,%ecx
f01043a6:	89 c2                	mov    %eax,%edx
f01043a8:	83 e2 02             	and    $0x2,%edx
f01043ab:	ba 50 7b 10 f0       	mov    $0xf0107b50,%edx
f01043b0:	be 56 7b 10 f0       	mov    $0xf0107b56,%esi
f01043b5:	0f 44 d6             	cmove  %esi,%edx
f01043b8:	83 e0 04             	and    $0x4,%eax
f01043bb:	b8 5b 7b 10 f0       	mov    $0xf0107b5b,%eax
f01043c0:	be ac 7c 10 f0       	mov    $0xf0107cac,%esi
f01043c5:	0f 44 c6             	cmove  %esi,%eax
f01043c8:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01043cc:	89 54 24 08          	mov    %edx,0x8(%esp)
f01043d0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01043d4:	c7 04 24 d3 7b 10 f0 	movl   $0xf0107bd3,(%esp)
f01043db:	e8 dc fc ff ff       	call   f01040bc <cprintf>
f01043e0:	eb 0c                	jmp    f01043ee <print_trapframe+0x12f>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f01043e2:	c7 04 24 32 7f 10 f0 	movl   $0xf0107f32,(%esp)
f01043e9:	e8 ce fc ff ff       	call   f01040bc <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f01043ee:	8b 43 30             	mov    0x30(%ebx),%eax
f01043f1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01043f5:	c7 04 24 e2 7b 10 f0 	movl   $0xf0107be2,(%esp)
f01043fc:	e8 bb fc ff ff       	call   f01040bc <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0104401:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0104405:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104409:	c7 04 24 f1 7b 10 f0 	movl   $0xf0107bf1,(%esp)
f0104410:	e8 a7 fc ff ff       	call   f01040bc <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0104415:	8b 43 38             	mov    0x38(%ebx),%eax
f0104418:	89 44 24 04          	mov    %eax,0x4(%esp)
f010441c:	c7 04 24 04 7c 10 f0 	movl   $0xf0107c04,(%esp)
f0104423:	e8 94 fc ff ff       	call   f01040bc <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0104428:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f010442c:	74 27                	je     f0104455 <print_trapframe+0x196>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f010442e:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0104431:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104435:	c7 04 24 13 7c 10 f0 	movl   $0xf0107c13,(%esp)
f010443c:	e8 7b fc ff ff       	call   f01040bc <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0104441:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0104445:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104449:	c7 04 24 22 7c 10 f0 	movl   $0xf0107c22,(%esp)
f0104450:	e8 67 fc ff ff       	call   f01040bc <cprintf>
	}
}
f0104455:	83 c4 10             	add    $0x10,%esp
f0104458:	5b                   	pop    %ebx
f0104459:	5e                   	pop    %esi
f010445a:	5d                   	pop    %ebp
f010445b:	c3                   	ret    

f010445c <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f010445c:	55                   	push   %ebp
f010445d:	89 e5                	mov    %esp,%ebp
f010445f:	57                   	push   %edi
f0104460:	56                   	push   %esi
f0104461:	53                   	push   %ebx
f0104462:	83 ec 1c             	sub    $0x1c,%esp
f0104465:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104468:	0f 20 d6             	mov    %cr2,%esi
	// LAB 3: Your code here.


	//If the processor is already in kernel mode when the interrupt or exception occurs 
	//(the low 2 bits of the CS register are already zero), Hence we have to check the CS register to make sure its in kernel mode
	if ((tf->tf_cs & 0x11) == 0){
f010446b:	f6 43 34 11          	testb  $0x11,0x34(%ebx)
f010446f:	75 20                	jne    f0104491 <page_fault_handler+0x35>
		panic("Fault occured in kernel space on %08x \n",fault_va);
f0104471:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0104475:	c7 44 24 08 f8 7d 10 	movl   $0xf0107df8,0x8(%esp)
f010447c:	f0 
f010447d:	c7 44 24 04 4c 01 00 	movl   $0x14c,0x4(%esp)
f0104484:	00 
f0104485:	c7 04 24 35 7c 10 f0 	movl   $0xf0107c35,(%esp)
f010448c:	e8 af bb ff ff       	call   f0100040 <_panic>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0104491:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f0104494:	e8 30 1b 00 00       	call   f0105fc9 <cpunum>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0104499:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010449d:	89 74 24 08          	mov    %esi,0x8(%esp)
		curenv->env_id, fault_va, tf->tf_eip);
f01044a1:	6b c0 74             	imul   $0x74,%eax,%eax
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01044a4:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f01044aa:	8b 40 48             	mov    0x48(%eax),%eax
f01044ad:	89 44 24 04          	mov    %eax,0x4(%esp)
f01044b1:	c7 04 24 20 7e 10 f0 	movl   $0xf0107e20,(%esp)
f01044b8:	e8 ff fb ff ff       	call   f01040bc <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f01044bd:	89 1c 24             	mov    %ebx,(%esp)
f01044c0:	e8 fa fd ff ff       	call   f01042bf <print_trapframe>
	env_destroy(curenv);
f01044c5:	e8 ff 1a 00 00       	call   f0105fc9 <cpunum>
f01044ca:	6b c0 74             	imul   $0x74,%eax,%eax
f01044cd:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f01044d3:	89 04 24             	mov    %eax,(%esp)
f01044d6:	e8 06 f9 ff ff       	call   f0103de1 <env_destroy>
}
f01044db:	83 c4 1c             	add    $0x1c,%esp
f01044de:	5b                   	pop    %ebx
f01044df:	5e                   	pop    %esi
f01044e0:	5f                   	pop    %edi
f01044e1:	5d                   	pop    %ebp
f01044e2:	c3                   	ret    

f01044e3 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f01044e3:	55                   	push   %ebp
f01044e4:	89 e5                	mov    %esp,%ebp
f01044e6:	57                   	push   %edi
f01044e7:	56                   	push   %esi
f01044e8:	83 ec 20             	sub    $0x20,%esp
f01044eb:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f01044ee:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f01044ef:	83 3d 80 be 22 f0 00 	cmpl   $0x0,0xf022be80
f01044f6:	74 01                	je     f01044f9 <trap+0x16>
		asm volatile("hlt");
f01044f8:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f01044f9:	e8 cb 1a 00 00       	call   f0105fc9 <cpunum>
f01044fe:	6b d0 74             	imul   $0x74,%eax,%edx
f0104501:	81 c2 20 c0 22 f0    	add    $0xf022c020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0104507:	b8 01 00 00 00       	mov    $0x1,%eax
f010450c:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0104510:	83 f8 02             	cmp    $0x2,%eax
f0104513:	75 0c                	jne    f0104521 <trap+0x3e>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0104515:	c7 04 24 80 04 12 f0 	movl   $0xf0120480,(%esp)
f010451c:	e8 26 1d 00 00       	call   f0106247 <spin_lock>

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0104521:	9c                   	pushf  
f0104522:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0104523:	f6 c4 02             	test   $0x2,%ah
f0104526:	74 24                	je     f010454c <trap+0x69>
f0104528:	c7 44 24 0c 41 7c 10 	movl   $0xf0107c41,0xc(%esp)
f010452f:	f0 
f0104530:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0104537:	f0 
f0104538:	c7 44 24 04 12 01 00 	movl   $0x112,0x4(%esp)
f010453f:	00 
f0104540:	c7 04 24 35 7c 10 f0 	movl   $0xf0107c35,(%esp)
f0104547:	e8 f4 ba ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f010454c:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0104550:	83 e0 03             	and    $0x3,%eax
f0104553:	66 83 f8 03          	cmp    $0x3,%ax
f0104557:	0f 85 a7 00 00 00    	jne    f0104604 <trap+0x121>
f010455d:	c7 04 24 80 04 12 f0 	movl   $0xf0120480,(%esp)
f0104564:	e8 de 1c 00 00       	call   f0106247 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel(); //Lock Kernel
		assert(curenv);
f0104569:	e8 5b 1a 00 00       	call   f0105fc9 <cpunum>
f010456e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104571:	83 b8 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%eax)
f0104578:	75 24                	jne    f010459e <trap+0xbb>
f010457a:	c7 44 24 0c 5a 7c 10 	movl   $0xf0107c5a,0xc(%esp)
f0104581:	f0 
f0104582:	c7 44 24 08 7b 76 10 	movl   $0xf010767b,0x8(%esp)
f0104589:	f0 
f010458a:	c7 44 24 04 1a 01 00 	movl   $0x11a,0x4(%esp)
f0104591:	00 
f0104592:	c7 04 24 35 7c 10 f0 	movl   $0xf0107c35,(%esp)
f0104599:	e8 a2 ba ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f010459e:	e8 26 1a 00 00       	call   f0105fc9 <cpunum>
f01045a3:	6b c0 74             	imul   $0x74,%eax,%eax
f01045a6:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f01045ac:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f01045b0:	75 2d                	jne    f01045df <trap+0xfc>
			env_free(curenv);
f01045b2:	e8 12 1a 00 00       	call   f0105fc9 <cpunum>
f01045b7:	6b c0 74             	imul   $0x74,%eax,%eax
f01045ba:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f01045c0:	89 04 24             	mov    %eax,(%esp)
f01045c3:	e8 14 f6 ff ff       	call   f0103bdc <env_free>
			curenv = NULL;
f01045c8:	e8 fc 19 00 00       	call   f0105fc9 <cpunum>
f01045cd:	6b c0 74             	imul   $0x74,%eax,%eax
f01045d0:	c7 80 28 c0 22 f0 00 	movl   $0x0,-0xfdd3fd8(%eax)
f01045d7:	00 00 00 
			sched_yield();
f01045da:	e8 d7 02 00 00       	call   f01048b6 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f01045df:	e8 e5 19 00 00       	call   f0105fc9 <cpunum>
f01045e4:	6b c0 74             	imul   $0x74,%eax,%eax
f01045e7:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f01045ed:	b9 11 00 00 00       	mov    $0x11,%ecx
f01045f2:	89 c7                	mov    %eax,%edi
f01045f4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f01045f6:	e8 ce 19 00 00       	call   f0105fc9 <cpunum>
f01045fb:	6b c0 74             	imul   $0x74,%eax,%eax
f01045fe:	8b b0 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0104604:	89 35 60 ba 22 f0    	mov    %esi,0xf022ba60
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	//call trap_handler function for page_fault
	switch (tf->tf_trapno) {
f010460a:	8b 46 28             	mov    0x28(%esi),%eax
f010460d:	83 f8 0e             	cmp    $0xe,%eax
f0104610:	74 20                	je     f0104632 <trap+0x14f>
f0104612:	83 f8 30             	cmp    $0x30,%eax
f0104615:	74 25                	je     f010463c <trap+0x159>
f0104617:	83 f8 03             	cmp    $0x3,%eax
f010461a:	75 52                	jne    f010466e <trap+0x18b>
		case T_BRKPT:
			monitor(tf);
f010461c:	89 34 24             	mov    %esi,(%esp)
f010461f:	e8 11 c3 ff ff       	call   f0100935 <monitor>
			cprintf("return from breakpoint....\n");
f0104624:	c7 04 24 61 7c 10 f0 	movl   $0xf0107c61,(%esp)
f010462b:	e8 8c fa ff ff       	call   f01040bc <cprintf>
f0104630:	eb 3c                	jmp    f010466e <trap+0x18b>
			break;

		case T_PGFLT:
			page_fault_handler(tf);
f0104632:	89 34 24             	mov    %esi,(%esp)
f0104635:	e8 22 fe ff ff       	call   f010445c <page_fault_handler>
f010463a:	eb 32                	jmp    f010466e <trap+0x18b>
			break;

		case T_SYSCALL:
			tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax,
f010463c:	8b 46 04             	mov    0x4(%esi),%eax
f010463f:	89 44 24 14          	mov    %eax,0x14(%esp)
f0104643:	8b 06                	mov    (%esi),%eax
f0104645:	89 44 24 10          	mov    %eax,0x10(%esp)
f0104649:	8b 46 10             	mov    0x10(%esi),%eax
f010464c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104650:	8b 46 18             	mov    0x18(%esi),%eax
f0104653:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104657:	8b 46 14             	mov    0x14(%esi),%eax
f010465a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010465e:	8b 46 1c             	mov    0x1c(%esi),%eax
f0104661:	89 04 24             	mov    %eax,(%esp)
f0104664:	e8 2f 03 00 00       	call   f0104998 <syscall>
f0104669:	89 46 1c             	mov    %eax,0x1c(%esi)
f010466c:	eb 5d                	jmp    f01046cb <trap+0x1e8>
	}

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f010466e:	83 7e 28 27          	cmpl   $0x27,0x28(%esi)
f0104672:	75 16                	jne    f010468a <trap+0x1a7>
		cprintf("Spurious interrupt on irq 7\n");
f0104674:	c7 04 24 7d 7c 10 f0 	movl   $0xf0107c7d,(%esp)
f010467b:	e8 3c fa ff ff       	call   f01040bc <cprintf>
		print_trapframe(tf);
f0104680:	89 34 24             	mov    %esi,(%esp)
f0104683:	e8 37 fc ff ff       	call   f01042bf <print_trapframe>
f0104688:	eb 41                	jmp    f01046cb <trap+0x1e8>
	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f010468a:	89 34 24             	mov    %esi,(%esp)
f010468d:	e8 2d fc ff ff       	call   f01042bf <print_trapframe>
	if (tf->tf_cs == GD_KT){
f0104692:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0104697:	75 1c                	jne    f01046b5 <trap+0x1d2>
		panic("unhandled trap in kernel");
f0104699:	c7 44 24 08 9a 7c 10 	movl   $0xf0107c9a,0x8(%esp)
f01046a0:	f0 
f01046a1:	c7 44 24 04 f7 00 00 	movl   $0xf7,0x4(%esp)
f01046a8:	00 
f01046a9:	c7 04 24 35 7c 10 f0 	movl   $0xf0107c35,(%esp)
f01046b0:	e8 8b b9 ff ff       	call   f0100040 <_panic>
	}
	else {
		env_destroy(curenv);
f01046b5:	e8 0f 19 00 00       	call   f0105fc9 <cpunum>
f01046ba:	6b c0 74             	imul   $0x74,%eax,%eax
f01046bd:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f01046c3:	89 04 24             	mov    %eax,(%esp)
f01046c6:	e8 16 f7 ff ff       	call   f0103de1 <env_destroy>
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f01046cb:	e8 f9 18 00 00       	call   f0105fc9 <cpunum>
f01046d0:	6b c0 74             	imul   $0x74,%eax,%eax
f01046d3:	83 b8 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%eax)
f01046da:	74 2a                	je     f0104706 <trap+0x223>
f01046dc:	e8 e8 18 00 00       	call   f0105fc9 <cpunum>
f01046e1:	6b c0 74             	imul   $0x74,%eax,%eax
f01046e4:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f01046ea:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01046ee:	75 16                	jne    f0104706 <trap+0x223>
		env_run(curenv);
f01046f0:	e8 d4 18 00 00       	call   f0105fc9 <cpunum>
f01046f5:	6b c0 74             	imul   $0x74,%eax,%eax
f01046f8:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f01046fe:	89 04 24             	mov    %eax,(%esp)
f0104701:	e8 7c f7 ff ff       	call   f0103e82 <env_run>
	else
		sched_yield();
f0104706:	e8 ab 01 00 00       	call   f01048b6 <sched_yield>
f010470b:	90                   	nop

f010470c <handler_0>:
#define T_DEFAULT   500		// catchall
*/

//TRAPHANDLER_NOEC for traps without error code
// From 0-7 no error code requred
	TRAPHANDLER_NOEC(handler_0, 0)   #Divide error
f010470c:	6a 00                	push   $0x0
f010470e:	6a 00                	push   $0x0
f0104710:	e9 ba 00 00 00       	jmp    f01047cf <_alltraps>
f0104715:	90                   	nop

f0104716 <handler_1>:
	TRAPHANDLER_NOEC(handler_1, 1)   #Debug exceptions 
f0104716:	6a 00                	push   $0x0
f0104718:	6a 01                	push   $0x1
f010471a:	e9 b0 00 00 00       	jmp    f01047cf <_alltraps>
f010471f:	90                   	nop

f0104720 <handler_2>:
 	TRAPHANDLER_NOEC(handler_2, 2)   //NMI Interrupt
f0104720:	6a 00                	push   $0x0
f0104722:	6a 02                	push   $0x2
f0104724:	e9 a6 00 00 00       	jmp    f01047cf <_alltraps>
f0104729:	90                   	nop

f010472a <handler_3>:
	TRAPHANDLER_NOEC(handler_3, 3)   //Breakpoint
f010472a:	6a 00                	push   $0x0
f010472c:	6a 03                	push   $0x3
f010472e:	e9 9c 00 00 00       	jmp    f01047cf <_alltraps>
f0104733:	90                   	nop

f0104734 <handler_4>:
	TRAPHANDLER_NOEC(handler_4, 4)   //Overflow
f0104734:	6a 00                	push   $0x0
f0104736:	6a 04                	push   $0x4
f0104738:	e9 92 00 00 00       	jmp    f01047cf <_alltraps>
f010473d:	90                   	nop

f010473e <handler_5>:
	TRAPHANDLER_NOEC(handler_5, 5)   //Bounds check 
f010473e:	6a 00                	push   $0x0
f0104740:	6a 05                	push   $0x5
f0104742:	e9 88 00 00 00       	jmp    f01047cf <_alltraps>
f0104747:	90                   	nop

f0104748 <handler_6>:
	TRAPHANDLER_NOEC(handler_6, 6)   //Invalid opcode
f0104748:	6a 00                	push   $0x0
f010474a:	6a 06                	push   $0x6
f010474c:	e9 7e 00 00 00       	jmp    f01047cf <_alltraps>
f0104751:	90                   	nop

f0104752 <handler_7>:
	TRAPHANDLER_NOEC(handler_7, 7)   //Coprocessor not available
f0104752:	6a 00                	push   $0x0
f0104754:	6a 07                	push   $0x7
f0104756:	e9 74 00 00 00       	jmp    f01047cf <_alltraps>
f010475b:	90                   	nop

f010475c <handler_8>:
	
	TRAPHANDLER(handler_8, 8)   // double fault
f010475c:	6a 08                	push   $0x8
f010475e:	e9 6c 00 00 00       	jmp    f01047cf <_alltraps>
f0104763:	90                   	nop

f0104764 <handler_9>:
	
	TRAPHANDLER_NOEC(handler_9, 9)   //Coprocessor Segment Overrun
f0104764:	6a 00                	push   $0x0
f0104766:	6a 09                	push   $0x9
f0104768:	e9 62 00 00 00       	jmp    f01047cf <_alltraps>
f010476d:	90                   	nop

f010476e <handler_10>:

	TRAPHANDLER(handler_10, 10)   // invalid task switch segment
f010476e:	6a 0a                	push   $0xa
f0104770:	e9 5a 00 00 00       	jmp    f01047cf <_alltraps>
f0104775:	90                   	nop

f0104776 <handler_11>:
	TRAPHANDLER(handler_11, 11)   // segment not present
f0104776:	6a 0b                	push   $0xb
f0104778:	e9 52 00 00 00       	jmp    f01047cf <_alltraps>
f010477d:	90                   	nop

f010477e <handler_12>:
	TRAPHANDLER(handler_12, 12)   // stack exception
f010477e:	6a 0c                	push   $0xc
f0104780:	e9 4a 00 00 00       	jmp    f01047cf <_alltraps>
f0104785:	90                   	nop

f0104786 <handler_13>:
	TRAPHANDLER(handler_13, 13)   // general protection fault
f0104786:	6a 0d                	push   $0xd
f0104788:	e9 42 00 00 00       	jmp    f01047cf <_alltraps>
f010478d:	90                   	nop

f010478e <handler_14>:
	TRAPHANDLER(handler_14, 14)   // page fault
f010478e:	6a 0e                	push   $0xe
f0104790:	e9 3a 00 00 00       	jmp    f01047cf <_alltraps>
f0104795:	90                   	nop

f0104796 <handler_15>:

	TRAPHANDLER_NOEC(handler_15, 15)   // Reserved
f0104796:	6a 00                	push   $0x0
f0104798:	6a 0f                	push   $0xf
f010479a:	e9 30 00 00 00       	jmp    f01047cf <_alltraps>
f010479f:	90                   	nop

f01047a0 <handler_16>:

	TRAPHANDLER_NOEC(handler_16, 16)   // floating point error
f01047a0:	6a 00                	push   $0x0
f01047a2:	6a 10                	push   $0x10
f01047a4:	e9 26 00 00 00       	jmp    f01047cf <_alltraps>
f01047a9:	90                   	nop

f01047aa <handler_17>:

	TRAPHANDLER(handler_17, 17)   // aligment check
f01047aa:	6a 11                	push   $0x11
f01047ac:	e9 1e 00 00 00       	jmp    f01047cf <_alltraps>
f01047b1:	90                   	nop

f01047b2 <handler_18>:

	TRAPHANDLER_NOEC(handler_18, 18)   // machine check
f01047b2:	6a 00                	push   $0x0
f01047b4:	6a 12                	push   $0x12
f01047b6:	e9 14 00 00 00       	jmp    f01047cf <_alltraps>
f01047bb:	90                   	nop

f01047bc <handler_19>:
	TRAPHANDLER_NOEC(handler_19, 19)   // SIMD floating point error
f01047bc:	6a 00                	push   $0x0
f01047be:	6a 13                	push   $0x13
f01047c0:	e9 0a 00 00 00       	jmp    f01047cf <_alltraps>
f01047c5:	90                   	nop

f01047c6 <handler_48>:

	TRAPHANDLER_NOEC(handler_48, 48)   // system call
f01047c6:	6a 00                	push   $0x0
f01047c8:	6a 30                	push   $0x30
f01047ca:	e9 00 00 00 00       	jmp    f01047cf <_alltraps>

f01047cf <_alltraps>:
 */

.globl _alltraps
_alltraps:
	#Remaining Trap frame
	push %ds
f01047cf:	1e                   	push   %ds
	push %es
f01047d0:	06                   	push   %es
	pushal
f01047d1:	60                   	pusha  

	
	movw $GD_KD, %ax
f01047d2:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f01047d6:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f01047d8:	8e c0                	mov    %eax,%es

	#call Trap 
	pushl %esp
f01047da:	54                   	push   %esp
	call trap
f01047db:	e8 03 fd ff ff       	call   f01044e3 <trap>

f01047e0 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f01047e0:	55                   	push   %ebp
f01047e1:	89 e5                	mov    %esp,%ebp
f01047e3:	83 ec 18             	sub    $0x18,%esp
f01047e6:	8b 15 4c b2 22 f0    	mov    0xf022b24c,%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f01047ec:	b8 00 00 00 00       	mov    $0x0,%eax
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
f01047f1:	8b 4a 54             	mov    0x54(%edx),%ecx
f01047f4:	83 e9 01             	sub    $0x1,%ecx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
		if ((envs[i].env_status == ENV_RUNNABLE ||
f01047f7:	83 f9 02             	cmp    $0x2,%ecx
f01047fa:	76 0f                	jbe    f010480b <sched_halt+0x2b>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f01047fc:	83 c0 01             	add    $0x1,%eax
f01047ff:	83 c2 7c             	add    $0x7c,%edx
f0104802:	3d 00 04 00 00       	cmp    $0x400,%eax
f0104807:	75 e8                	jne    f01047f1 <sched_halt+0x11>
f0104809:	eb 07                	jmp    f0104812 <sched_halt+0x32>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f010480b:	3d 00 04 00 00       	cmp    $0x400,%eax
f0104810:	75 1a                	jne    f010482c <sched_halt+0x4c>
		cprintf("No runnable environments in the system!\n");
f0104812:	c7 04 24 b0 7e 10 f0 	movl   $0xf0107eb0,(%esp)
f0104819:	e8 9e f8 ff ff       	call   f01040bc <cprintf>
		while (1)
			monitor(NULL);
f010481e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0104825:	e8 0b c1 ff ff       	call   f0100935 <monitor>
f010482a:	eb f2                	jmp    f010481e <sched_halt+0x3e>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f010482c:	e8 98 17 00 00       	call   f0105fc9 <cpunum>
f0104831:	6b c0 74             	imul   $0x74,%eax,%eax
f0104834:	c7 80 28 c0 22 f0 00 	movl   $0x0,-0xfdd3fd8(%eax)
f010483b:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f010483e:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0104843:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0104848:	77 20                	ja     f010486a <sched_halt+0x8a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010484a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010484e:	c7 44 24 08 08 67 10 	movl   $0xf0106708,0x8(%esp)
f0104855:	f0 
f0104856:	c7 44 24 04 54 00 00 	movl   $0x54,0x4(%esp)
f010485d:	00 
f010485e:	c7 04 24 d9 7e 10 f0 	movl   $0xf0107ed9,(%esp)
f0104865:	e8 d6 b7 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010486a:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010486f:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f0104872:	e8 52 17 00 00       	call   f0105fc9 <cpunum>
f0104877:	6b d0 74             	imul   $0x74,%eax,%edx
f010487a:	81 c2 20 c0 22 f0    	add    $0xf022c020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0104880:	b8 02 00 00 00       	mov    $0x2,%eax
f0104885:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0104889:	c7 04 24 80 04 12 f0 	movl   $0xf0120480,(%esp)
f0104890:	e8 5e 1a 00 00       	call   f01062f3 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0104895:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0104897:	e8 2d 17 00 00       	call   f0105fc9 <cpunum>
f010489c:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f010489f:	8b 80 30 c0 22 f0    	mov    -0xfdd3fd0(%eax),%eax
f01048a5:	bd 00 00 00 00       	mov    $0x0,%ebp
f01048aa:	89 c4                	mov    %eax,%esp
f01048ac:	6a 00                	push   $0x0
f01048ae:	6a 00                	push   $0x0
f01048b0:	fb                   	sti    
f01048b1:	f4                   	hlt    
f01048b2:	eb fd                	jmp    f01048b1 <sched_halt+0xd1>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f01048b4:	c9                   	leave  
f01048b5:	c3                   	ret    

f01048b6 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f01048b6:	55                   	push   %ebp
f01048b7:	89 e5                	mov    %esp,%ebp
f01048b9:	53                   	push   %ebx
f01048ba:	83 ec 14             	sub    $0x14,%esp
	// below to halt the cpu.

	// LAB 4: Your code here.
	int envVal, j = 0 ;
	 
	if (curenv)
f01048bd:	e8 07 17 00 00       	call   f0105fc9 <cpunum>
f01048c2:	6b c0 74             	imul   $0x74,%eax,%eax
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
						     // we can use the value 'curenv- envs' to get the current env and +1 to get the next env
	else 
		envVal = 0; 
f01048c5:	ba 00 00 00 00       	mov    $0x0,%edx
	// below to halt the cpu.

	// LAB 4: Your code here.
	int envVal, j = 0 ;
	 
	if (curenv)
f01048ca:	83 b8 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%eax)
f01048d1:	74 32                	je     f0104905 <sched_yield+0x4f>
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
f01048d3:	e8 f1 16 00 00       	call   f0105fc9 <cpunum>
f01048d8:	6b c0 74             	imul   $0x74,%eax,%eax
f01048db:	8b 90 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%edx
f01048e1:	2b 15 4c b2 22 f0    	sub    0xf022b24c,%edx
f01048e7:	c1 fa 02             	sar    $0x2,%edx
f01048ea:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f01048f0:	83 c2 01             	add    $0x1,%edx
f01048f3:	89 d0                	mov    %edx,%eax
f01048f5:	c1 f8 1f             	sar    $0x1f,%eax
f01048f8:	c1 e8 16             	shr    $0x16,%eax
f01048fb:	01 c2                	add    %eax,%edx
f01048fd:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0104903:	29 c2                	sub    %eax,%edx
	else 
		envVal = 0; 
	
	for (j = 0; j< NENV; j++)
	{
		if (envs[envVal].env_status == ENV_RUNNABLE)
f0104905:	8b 1d 4c b2 22 f0    	mov    0xf022b24c,%ebx
f010490b:	b8 00 04 00 00       	mov    $0x400,%eax
f0104910:	6b ca 7c             	imul   $0x7c,%edx,%ecx
f0104913:	83 7c 0b 54 02       	cmpl   $0x2,0x54(%ebx,%ecx,1)
f0104918:	74 6f                	je     f0104989 <sched_yield+0xd3>
		    break;
		else
		    envVal=(envVal+1)%NENV;
f010491a:	83 c2 01             	add    $0x1,%edx
f010491d:	89 d1                	mov    %edx,%ecx
f010491f:	c1 f9 1f             	sar    $0x1f,%ecx
f0104922:	c1 e9 16             	shr    $0x16,%ecx
f0104925:	01 ca                	add    %ecx,%edx
f0104927:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010492d:	29 ca                	sub    %ecx,%edx
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
						     // we can use the value 'curenv- envs' to get the current env and +1 to get the next env
	else 
		envVal = 0; 
	
	for (j = 0; j< NENV; j++)
f010492f:	83 e8 01             	sub    $0x1,%eax
f0104932:	75 dc                	jne    f0104910 <sched_yield+0x5a>
		    break;
		else
		    envVal=(envVal+1)%NENV;
	}
	
	if (envs[envVal].env_status == ENV_RUNNABLE)
f0104934:	6b d2 7c             	imul   $0x7c,%edx,%edx
f0104937:	01 da                	add    %ebx,%edx
f0104939:	83 7a 54 02          	cmpl   $0x2,0x54(%edx)
f010493d:	75 08                	jne    f0104947 <sched_yield+0x91>
	{
	    idle = envs + envVal ;
	    env_run(idle);
f010493f:	89 14 24             	mov    %edx,(%esp)
f0104942:	e8 3b f5 ff ff       	call   f0103e82 <env_run>
	} 
	else if (!idle && (curenv) && (curenv->env_status == ENV_RUNNING) ){
f0104947:	e8 7d 16 00 00       	call   f0105fc9 <cpunum>
f010494c:	6b c0 74             	imul   $0x74,%eax,%eax
f010494f:	83 b8 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%eax)
f0104956:	74 2a                	je     f0104982 <sched_yield+0xcc>
f0104958:	e8 6c 16 00 00       	call   f0105fc9 <cpunum>
f010495d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104960:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104966:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010496a:	75 16                	jne    f0104982 <sched_yield+0xcc>
	    env_run(curenv) ;
f010496c:	e8 58 16 00 00       	call   f0105fc9 <cpunum>
f0104971:	6b c0 74             	imul   $0x74,%eax,%eax
f0104974:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f010497a:	89 04 24             	mov    %eax,(%esp)
f010497d:	e8 00 f5 ff ff       	call   f0103e82 <env_run>
	}
	// sched_halt never returns
	sched_halt();
f0104982:	e8 59 fe ff ff       	call   f01047e0 <sched_halt>
f0104987:	eb 09                	jmp    f0104992 <sched_yield+0xdc>
		    break;
		else
		    envVal=(envVal+1)%NENV;
	}
	
	if (envs[envVal].env_status == ENV_RUNNABLE)
f0104989:	6b d2 7c             	imul   $0x7c,%edx,%edx
f010498c:	01 da                	add    %ebx,%edx
f010498e:	66 90                	xchg   %ax,%ax
f0104990:	eb ad                	jmp    f010493f <sched_yield+0x89>
	else if (!idle && (curenv) && (curenv->env_status == ENV_RUNNING) ){
	    env_run(curenv) ;
	}
	// sched_halt never returns
	sched_halt();
}
f0104992:	83 c4 14             	add    $0x14,%esp
f0104995:	5b                   	pop    %ebx
f0104996:	5d                   	pop    %ebp
f0104997:	c3                   	ret    

f0104998 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104998:	55                   	push   %ebp
f0104999:	89 e5                	mov    %esp,%ebp
f010499b:	57                   	push   %edi
f010499c:	56                   	push   %esi
f010499d:	53                   	push   %ebx
f010499e:	83 ec 1c             	sub    $0x1c,%esp
f01049a1:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	

	switch (syscallno) {
f01049a4:	83 f8 0a             	cmp    $0xa,%eax
f01049a7:	0f 87 60 03 00 00    	ja     f0104d0d <syscall+0x375>
f01049ad:	ff 24 85 44 7f 10 f0 	jmp    *-0xfef80bc(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_P | PTE_U);
f01049b4:	e8 10 16 00 00       	call   f0105fc9 <cpunum>
f01049b9:	6a 05                	push   $0x5
f01049bb:	ff 75 10             	pushl  0x10(%ebp)
f01049be:	ff 75 0c             	pushl  0xc(%ebp)
f01049c1:	6b c0 74             	imul   $0x74,%eax,%eax
f01049c4:	ff b0 28 c0 22 f0    	pushl  -0xfdd3fd8(%eax)
f01049ca:	e8 da ec ff ff       	call   f01036a9 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01049cf:	83 c4 0c             	add    $0xc,%esp
f01049d2:	ff 75 0c             	pushl  0xc(%ebp)
f01049d5:	ff 75 10             	pushl  0x10(%ebp)
f01049d8:	68 e6 7e 10 f0       	push   $0xf0107ee6
f01049dd:	e8 da f6 ff ff       	call   f01040bc <cprintf>
f01049e2:	83 c4 10             	add    $0x10,%esp

	switch (syscallno) {

	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;
f01049e5:	b8 00 00 00 00       	mov    $0x0,%eax
f01049ea:	e9 35 03 00 00       	jmp    f0104d24 <syscall+0x38c>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f01049ef:	e8 f1 bb ff ff       	call   f01005e5 <cons_getc>
	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;

	case SYS_cgetc:
		return sys_cgetc();
f01049f4:	e9 2b 03 00 00       	jmp    f0104d24 <syscall+0x38c>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f01049f9:	e8 cb 15 00 00       	call   f0105fc9 <cpunum>
f01049fe:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a01:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104a07:	8b 40 48             	mov    0x48(%eax),%eax

	case SYS_cgetc:
		return sys_cgetc();
		
	case SYS_getenvid:
		return sys_getenvid();
f0104a0a:	e9 15 03 00 00       	jmp    f0104d24 <syscall+0x38c>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0104a0f:	83 ec 04             	sub    $0x4,%esp
f0104a12:	6a 01                	push   $0x1
f0104a14:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104a17:	50                   	push   %eax
f0104a18:	ff 75 0c             	pushl  0xc(%ebp)
f0104a1b:	e8 7c ed ff ff       	call   f010379c <envid2env>
f0104a20:	89 c2                	mov    %eax,%edx
f0104a22:	83 c4 10             	add    $0x10,%esp
f0104a25:	85 d2                	test   %edx,%edx
f0104a27:	0f 88 f7 02 00 00    	js     f0104d24 <syscall+0x38c>
		return r;
	if (e == curenv)
f0104a2d:	e8 97 15 00 00       	call   f0105fc9 <cpunum>
f0104a32:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104a35:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a38:	39 90 28 c0 22 f0    	cmp    %edx,-0xfdd3fd8(%eax)
f0104a3e:	75 23                	jne    f0104a63 <syscall+0xcb>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104a40:	e8 84 15 00 00       	call   f0105fc9 <cpunum>
f0104a45:	83 ec 08             	sub    $0x8,%esp
f0104a48:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a4b:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104a51:	ff 70 48             	pushl  0x48(%eax)
f0104a54:	68 eb 7e 10 f0       	push   $0xf0107eeb
f0104a59:	e8 5e f6 ff ff       	call   f01040bc <cprintf>
f0104a5e:	83 c4 10             	add    $0x10,%esp
f0104a61:	eb 25                	jmp    f0104a88 <syscall+0xf0>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0104a63:	8b 5a 48             	mov    0x48(%edx),%ebx
f0104a66:	e8 5e 15 00 00       	call   f0105fc9 <cpunum>
f0104a6b:	83 ec 04             	sub    $0x4,%esp
f0104a6e:	53                   	push   %ebx
f0104a6f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a72:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104a78:	ff 70 48             	pushl  0x48(%eax)
f0104a7b:	68 06 7f 10 f0       	push   $0xf0107f06
f0104a80:	e8 37 f6 ff ff       	call   f01040bc <cprintf>
f0104a85:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0104a88:	83 ec 0c             	sub    $0xc,%esp
f0104a8b:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104a8e:	e8 4e f3 ff ff       	call   f0103de1 <env_destroy>
f0104a93:	83 c4 10             	add    $0x10,%esp
	return 0;
f0104a96:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a9b:	e9 84 02 00 00       	jmp    f0104d24 <syscall+0x38c>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f0104aa0:	e8 11 fe ff ff       	call   f01048b6 <sched_yield>
	// from the current environment -- but tweaked so sys_exofork
	// will appear to return 0.

	// LAB 4: Your code here.
	struct Env* childenv;
	int errcode = env_alloc(&childenv, curenv->env_id);
f0104aa5:	e8 1f 15 00 00       	call   f0105fc9 <cpunum>
f0104aaa:	83 ec 08             	sub    $0x8,%esp
f0104aad:	6b c0 74             	imul   $0x74,%eax,%eax
f0104ab0:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104ab6:	ff 70 48             	pushl  0x48(%eax)
f0104ab9:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104abc:	50                   	push   %eax
f0104abd:	e8 e2 ed ff ff       	call   f01038a4 <env_alloc>
f0104ac2:	89 c2                	mov    %eax,%edx
	
	//If the error code is less than 0, that means there has been an error while creating an env	
	if (errcode < 0) {
f0104ac4:	83 c4 10             	add    $0x10,%esp
f0104ac7:	85 d2                	test   %edx,%edx
f0104ac9:	0f 88 55 02 00 00    	js     f0104d24 <syscall+0x38c>
		return errcode; //Return the environment
	}
	
	//Set the child environment as not runnable	
	childenv->env_status = ENV_NOT_RUNNABLE;
f0104acf:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104ad2:	c7 43 54 04 00 00 00 	movl   $0x4,0x54(%ebx)

	//Copy the current environemnt register data into the child
	childenv->env_tf = curenv->env_tf;
f0104ad9:	e8 eb 14 00 00       	call   f0105fc9 <cpunum>
f0104ade:	6b c0 74             	imul   $0x74,%eax,%eax
f0104ae1:	8b b0 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%esi
f0104ae7:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104aec:	89 df                	mov    %ebx,%edi
f0104aee:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

	// when the child is scheduled to run, it has to restart the trapframe. 
	//Hence we modify the register eax to be 0. 

	childenv->env_tf.tf_regs.reg_eax = 0; 
f0104af0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104af3:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

	return childenv->env_id;
f0104afa:	8b 40 48             	mov    0x48(%eax),%eax
f0104afd:	e9 22 02 00 00       	jmp    f0104d24 <syscall+0x38c>

	// LAB 4: Your code here.
	
	struct Env *env_store;
	int errcode; 
	errcode = envid2env(envid, &env_store,1);
f0104b02:	83 ec 04             	sub    $0x4,%esp
f0104b05:	6a 01                	push   $0x1
f0104b07:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104b0a:	50                   	push   %eax
f0104b0b:	ff 75 0c             	pushl  0xc(%ebp)
f0104b0e:	e8 89 ec ff ff       	call   f010379c <envid2env>
	if (errcode < 0)
f0104b13:	83 c4 10             	add    $0x10,%esp
f0104b16:	85 c0                	test   %eax,%eax
f0104b18:	0f 88 06 02 00 00    	js     f0104d24 <syscall+0x38c>
		return errcode;
	
	//Check if status is runnable or not runnable
	if (status == ENV_RUNNABLE || status == ENV_NOT_RUNNABLE)
f0104b1e:	8b 45 10             	mov    0x10(%ebp),%eax
f0104b21:	8d 50 fe             	lea    -0x2(%eax),%edx
		env_store->env_status = status;

	else
		return E_INVAL;
f0104b24:	b8 03 00 00 00       	mov    $0x3,%eax
	errcode = envid2env(envid, &env_store,1);
	if (errcode < 0)
		return errcode;
	
	//Check if status is runnable or not runnable
	if (status == ENV_RUNNABLE || status == ENV_NOT_RUNNABLE)
f0104b29:	f7 c2 fd ff ff ff    	test   $0xfffffffd,%edx
f0104b2f:	0f 85 ef 01 00 00    	jne    f0104d24 <syscall+0x38c>
		env_store->env_status = status;
f0104b35:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104b38:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104b3b:	89 48 54             	mov    %ecx,0x54(%eax)

	else
		return E_INVAL;

	return 0;
f0104b3e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104b43:	e9 dc 01 00 00       	jmp    f0104d24 <syscall+0x38c>
	struct Env *en; 
	int code;
	
	//Check for valid address and page alignment
	if((((uint32_t)va) >= UTOP) || (((uint32_t)va) % PGSIZE) !=0)
		return  E_INVAL;
f0104b48:	b8 03 00 00 00       	mov    $0x3,%eax
	
	struct Env *en; 
	int code;
	
	//Check for valid address and page alignment
	if((((uint32_t)va) >= UTOP) || (((uint32_t)va) % PGSIZE) !=0)
f0104b4d:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104b54:	0f 87 ca 01 00 00    	ja     f0104d24 <syscall+0x38c>
f0104b5a:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104b61:	0f 85 bd 01 00 00    	jne    f0104d24 <syscall+0x38c>
		return  E_INVAL;

	//Check for permissions
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
f0104b67:	f7 45 14 fd f1 ff ff 	testl  $0xfffff1fd,0x14(%ebp)
f0104b6e:	0f 84 b0 01 00 00    	je     f0104d24 <syscall+0x38c>
		return E_INVAL;

	//Page allocation check
	struct PageInfo *newpage = page_alloc(ALLOC_ZERO); 
f0104b74:	83 ec 0c             	sub    $0xc,%esp
f0104b77:	6a 01                	push   $0x1
f0104b79:	e8 79 c5 ff ff       	call   f01010f7 <page_alloc>
f0104b7e:	89 c3                	mov    %eax,%ebx
	if (!newpage)
f0104b80:	83 c4 10             	add    $0x10,%esp
		return E_NO_MEM; 
f0104b83:	b8 04 00 00 00       	mov    $0x4,%eax
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
		return E_INVAL;

	//Page allocation check
	struct PageInfo *newpage = page_alloc(ALLOC_ZERO); 
	if (!newpage)
f0104b88:	85 db                	test   %ebx,%ebx
f0104b8a:	0f 84 94 01 00 00    	je     f0104d24 <syscall+0x38c>
		return E_NO_MEM; 

	//Use environid to get the environment 
	if ((code = envid2env(envid, &en,1))<0)
f0104b90:	83 ec 04             	sub    $0x4,%esp
f0104b93:	6a 01                	push   $0x1
f0104b95:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104b98:	50                   	push   %eax
f0104b99:	ff 75 0c             	pushl  0xc(%ebp)
f0104b9c:	e8 fb eb ff ff       	call   f010379c <envid2env>
f0104ba1:	83 c4 10             	add    $0x10,%esp
f0104ba4:	85 c0                	test   %eax,%eax
f0104ba6:	0f 88 78 01 00 00    	js     f0104d24 <syscall+0x38c>
		return code;

	//Check if the page mapping is correct otherwise free the page
	code=page_insert(en->env_pgdir,newpage,(void *)va,perm);
f0104bac:	ff 75 14             	pushl  0x14(%ebp)
f0104baf:	ff 75 10             	pushl  0x10(%ebp)
f0104bb2:	53                   	push   %ebx
f0104bb3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104bb6:	ff 70 60             	pushl  0x60(%eax)
f0104bb9:	e8 bd c8 ff ff       	call   f010147b <page_insert>
f0104bbe:	89 c6                	mov    %eax,%esi
	if (code < 0)
f0104bc0:	83 c4 10             	add    $0x10,%esp
	{
		page_free(newpage);
		return code;
	}
	
	return 0;
f0104bc3:	b8 00 00 00 00       	mov    $0x0,%eax
	if ((code = envid2env(envid, &en,1))<0)
		return code;

	//Check if the page mapping is correct otherwise free the page
	code=page_insert(en->env_pgdir,newpage,(void *)va,perm);
	if (code < 0)
f0104bc8:	85 f6                	test   %esi,%esi
f0104bca:	0f 89 54 01 00 00    	jns    f0104d24 <syscall+0x38c>
	{
		page_free(newpage);
f0104bd0:	83 ec 0c             	sub    $0xc,%esp
f0104bd3:	53                   	push   %ebx
f0104bd4:	e8 af c5 ff ff       	call   f0101188 <page_free>
f0104bd9:	83 c4 10             	add    $0x10,%esp
		return code;
f0104bdc:	89 f0                	mov    %esi,%eax
f0104bde:	e9 41 01 00 00       	jmp    f0104d24 <syscall+0x38c>
	struct Env* src_env;
	struct Env* dst_env;
	int errcode;
	
	//Check for valid src env id
	errcode = envid2env(srcenvid, &src_env, 1);
f0104be3:	83 ec 04             	sub    $0x4,%esp
f0104be6:	6a 01                	push   $0x1
f0104be8:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0104beb:	50                   	push   %eax
f0104bec:	ff 75 0c             	pushl  0xc(%ebp)
f0104bef:	e8 a8 eb ff ff       	call   f010379c <envid2env>
f0104bf4:	89 c2                	mov    %eax,%edx
	if (errcode < 0) 
f0104bf6:	83 c4 10             	add    $0x10,%esp
f0104bf9:	85 d2                	test   %edx,%edx
f0104bfb:	0f 88 23 01 00 00    	js     f0104d24 <syscall+0x38c>
		return errcode;
	
	//Check for valid des env id
	errcode = envid2env(dstenvid, &dst_env, 1);
f0104c01:	83 ec 04             	sub    $0x4,%esp
f0104c04:	6a 01                	push   $0x1
f0104c06:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104c09:	50                   	push   %eax
f0104c0a:	ff 75 14             	pushl  0x14(%ebp)
f0104c0d:	e8 8a eb ff ff       	call   f010379c <envid2env>
	if (errcode < 0) 
f0104c12:	83 c4 10             	add    $0x10,%esp
f0104c15:	85 c0                	test   %eax,%eax
f0104c17:	0f 88 07 01 00 00    	js     f0104d24 <syscall+0x38c>
		return errcode;
	
	//Check if the address is below UTOP
	if (((uint32_t)srcva) >= UTOP || ((uint32_t)dstva) >= UTOP) 
f0104c1d:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104c24:	77 78                	ja     f0104c9e <syscall+0x306>
f0104c26:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f0104c2d:	77 6f                	ja     f0104c9e <syscall+0x306>
f0104c2f:	8b 45 10             	mov    0x10(%ebp),%eax
f0104c32:	0b 45 18             	or     0x18(%ebp),%eax
		return -E_INVAL;
	
	//Checking if the address is page aligned
	if ((((uint32_t)srcva)%PGSIZE != 0) || (((uint32_t)dstva)%PGSIZE != 0)) 
f0104c35:	a9 ff 0f 00 00       	test   $0xfff,%eax
f0104c3a:	75 69                	jne    f0104ca5 <syscall+0x30d>
		return -E_INVAL;

	// find the page corresponding to srcva in src_e
	pte_t* pte_src;

	struct PageInfo* srcPage = page_lookup(src_env->env_pgdir, srcva, &pte_src);
f0104c3c:	83 ec 04             	sub    $0x4,%esp
f0104c3f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104c42:	50                   	push   %eax
f0104c43:	ff 75 10             	pushl  0x10(%ebp)
f0104c46:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104c49:	ff 70 60             	pushl  0x60(%eax)
f0104c4c:	e8 56 c7 ff ff       	call   f01013a7 <page_lookup>
f0104c51:	89 c2                	mov    %eax,%edx
	if (!srcPage) 
f0104c53:	83 c4 10             	add    $0x10,%esp
f0104c56:	85 c0                	test   %eax,%eax
f0104c58:	74 52                	je     f0104cac <syscall+0x314>
		return -E_INVAL;
	

	//Check for permissions
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
		return E_INVAL; 	
f0104c5a:	b8 03 00 00 00       	mov    $0x3,%eax
	if (!srcPage) 
		return -E_INVAL;
	

	//Check for permissions
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
f0104c5f:	f7 45 1c fd f1 ff ff 	testl  $0xfffff1fd,0x1c(%ebp)
f0104c66:	0f 84 b8 00 00 00    	je     f0104d24 <syscall+0x38c>
		return E_INVAL; 	
	

	// the page is not writable but write permission is set	
	if (!(*pte_src & PTE_W) && (perm & PTE_W)) {
f0104c6c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104c6f:	f6 00 02             	testb  $0x2,(%eax)
f0104c72:	75 06                	jne    f0104c7a <syscall+0x2e2>
f0104c74:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f0104c78:	75 39                	jne    f0104cb3 <syscall+0x31b>
		return -E_INVAL;
	}

	// mapping
	errcode = page_insert(dst_env->env_pgdir, srcPage, dstva, perm);
f0104c7a:	ff 75 1c             	pushl  0x1c(%ebp)
f0104c7d:	ff 75 18             	pushl  0x18(%ebp)
f0104c80:	52                   	push   %edx
f0104c81:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104c84:	ff 70 60             	pushl  0x60(%eax)
f0104c87:	e8 ef c7 ff ff       	call   f010147b <page_insert>
f0104c8c:	83 c4 10             	add    $0x10,%esp
f0104c8f:	85 c0                	test   %eax,%eax
f0104c91:	ba 00 00 00 00       	mov    $0x0,%edx
f0104c96:	0f 4f c2             	cmovg  %edx,%eax
f0104c99:	e9 86 00 00 00       	jmp    f0104d24 <syscall+0x38c>
	if (errcode < 0) 
		return errcode;
	
	//Check if the address is below UTOP
	if (((uint32_t)srcva) >= UTOP || ((uint32_t)dstva) >= UTOP) 
		return -E_INVAL;
f0104c9e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104ca3:	eb 7f                	jmp    f0104d24 <syscall+0x38c>
	
	//Checking if the address is page aligned
	if ((((uint32_t)srcva)%PGSIZE != 0) || (((uint32_t)dstva)%PGSIZE != 0)) 
		return -E_INVAL;
f0104ca5:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104caa:	eb 78                	jmp    f0104d24 <syscall+0x38c>
	// find the page corresponding to srcva in src_e
	pte_t* pte_src;

	struct PageInfo* srcPage = page_lookup(src_env->env_pgdir, srcva, &pte_src);
	if (!srcPage) 
		return -E_INVAL;
f0104cac:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104cb1:	eb 71                	jmp    f0104d24 <syscall+0x38c>
		return E_INVAL; 	
	

	// the page is not writable but write permission is set	
	if (!(*pte_src & PTE_W) && (perm & PTE_W)) {
		return -E_INVAL;
f0104cb3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	case SYS_page_alloc:
		return sys_page_alloc( (envid_t)a1, (void *)a2, (int)a3);
	
	case SYS_page_map:
		return sys_page_map( (envid_t)a1, (void *)a2,
f0104cb8:	eb 6a                	jmp    f0104d24 <syscall+0x38c>
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	struct Env* en;
	//Check for valid envid
	int errcode = envid2env(envid, &en, 1);
f0104cba:	83 ec 04             	sub    $0x4,%esp
f0104cbd:	6a 01                	push   $0x1
f0104cbf:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104cc2:	50                   	push   %eax
f0104cc3:	ff 75 0c             	pushl  0xc(%ebp)
f0104cc6:	e8 d1 ea ff ff       	call   f010379c <envid2env>
	if (errcode < 0){ 
f0104ccb:	83 c4 10             	add    $0x10,%esp
f0104cce:	85 c0                	test   %eax,%eax
f0104cd0:	78 52                	js     f0104d24 <syscall+0x38c>
		return errcode;
	}
	
	//Checkfor valid address and page alignment
	if ((((uint32_t)va) >= UTOP) ||(((uint32_t)va)%PGSIZE != 0 ) ) {
f0104cd2:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104cd9:	77 24                	ja     f0104cff <syscall+0x367>
f0104cdb:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104ce2:	75 22                	jne    f0104d06 <syscall+0x36e>
		return -E_INVAL;
	}

	page_remove(en->env_pgdir, va);
f0104ce4:	83 ec 08             	sub    $0x8,%esp
f0104ce7:	ff 75 10             	pushl  0x10(%ebp)
f0104cea:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104ced:	ff 70 60             	pushl  0x60(%eax)
f0104cf0:	e8 3d c7 ff ff       	call   f0101432 <page_remove>
f0104cf5:	83 c4 10             	add    $0x10,%esp

	return 0;
f0104cf8:	b8 00 00 00 00       	mov    $0x0,%eax
f0104cfd:	eb 25                	jmp    f0104d24 <syscall+0x38c>
		return errcode;
	}
	
	//Checkfor valid address and page alignment
	if ((((uint32_t)va) >= UTOP) ||(((uint32_t)va)%PGSIZE != 0 ) ) {
		return -E_INVAL;
f0104cff:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104d04:	eb 1e                	jmp    f0104d24 <syscall+0x38c>
f0104d06:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	case SYS_page_map:
		return sys_page_map( (envid_t)a1, (void *)a2,
	     (envid_t) a3, (void *)a4, (int )a5);

	case SYS_page_unmap:
		return sys_page_unmap((envid_t)a1, (void *)a2);	
f0104d0b:	eb 17                	jmp    f0104d24 <syscall+0x38c>
		
	default:
		panic("Invalid System Call \n");
f0104d0d:	83 ec 04             	sub    $0x4,%esp
f0104d10:	68 1e 7f 10 f0       	push   $0xf0107f1e
f0104d15:	68 ba 01 00 00       	push   $0x1ba
f0104d1a:	68 34 7f 10 f0       	push   $0xf0107f34
f0104d1f:	e8 1c b3 ff ff       	call   f0100040 <_panic>
		return -E_INVAL;
	}
}
f0104d24:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104d27:	5b                   	pop    %ebx
f0104d28:	5e                   	pop    %esi
f0104d29:	5f                   	pop    %edi
f0104d2a:	5d                   	pop    %ebp
f0104d2b:	c3                   	ret    

f0104d2c <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104d2c:	55                   	push   %ebp
f0104d2d:	89 e5                	mov    %esp,%ebp
f0104d2f:	57                   	push   %edi
f0104d30:	56                   	push   %esi
f0104d31:	53                   	push   %ebx
f0104d32:	83 ec 14             	sub    $0x14,%esp
f0104d35:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104d38:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104d3b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104d3e:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104d41:	8b 1a                	mov    (%edx),%ebx
f0104d43:	8b 01                	mov    (%ecx),%eax
f0104d45:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104d48:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104d4f:	e9 88 00 00 00       	jmp    f0104ddc <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0104d54:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104d57:	01 d8                	add    %ebx,%eax
f0104d59:	89 c7                	mov    %eax,%edi
f0104d5b:	c1 ef 1f             	shr    $0x1f,%edi
f0104d5e:	01 c7                	add    %eax,%edi
f0104d60:	d1 ff                	sar    %edi
f0104d62:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0104d65:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104d68:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0104d6b:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104d6d:	eb 03                	jmp    f0104d72 <stab_binsearch+0x46>
			m--;
f0104d6f:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104d72:	39 c3                	cmp    %eax,%ebx
f0104d74:	7f 1f                	jg     f0104d95 <stab_binsearch+0x69>
f0104d76:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104d7a:	83 ea 0c             	sub    $0xc,%edx
f0104d7d:	39 f1                	cmp    %esi,%ecx
f0104d7f:	75 ee                	jne    f0104d6f <stab_binsearch+0x43>
f0104d81:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104d84:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104d87:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104d8a:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104d8e:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104d91:	76 18                	jbe    f0104dab <stab_binsearch+0x7f>
f0104d93:	eb 05                	jmp    f0104d9a <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104d95:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0104d98:	eb 42                	jmp    f0104ddc <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0104d9a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104d9d:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0104d9f:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104da2:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104da9:	eb 31                	jmp    f0104ddc <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0104dab:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104dae:	73 17                	jae    f0104dc7 <stab_binsearch+0x9b>
			*region_right = m - 1;
f0104db0:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0104db3:	83 e8 01             	sub    $0x1,%eax
f0104db6:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104db9:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104dbc:	89 07                	mov    %eax,(%edi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104dbe:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104dc5:	eb 15                	jmp    f0104ddc <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104dc7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104dca:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0104dcd:	89 1f                	mov    %ebx,(%edi)
			l = m;
			addr++;
f0104dcf:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104dd3:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104dd5:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0104ddc:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104ddf:	0f 8e 6f ff ff ff    	jle    f0104d54 <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0104de5:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104de9:	75 0f                	jne    f0104dfa <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0104deb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104dee:	8b 00                	mov    (%eax),%eax
f0104df0:	83 e8 01             	sub    $0x1,%eax
f0104df3:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104df6:	89 07                	mov    %eax,(%edi)
f0104df8:	eb 2c                	jmp    f0104e26 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104dfa:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104dfd:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104dff:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104e02:	8b 0f                	mov    (%edi),%ecx
f0104e04:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104e07:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0104e0a:	8d 14 97             	lea    (%edi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104e0d:	eb 03                	jmp    f0104e12 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104e0f:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104e12:	39 c8                	cmp    %ecx,%eax
f0104e14:	7e 0b                	jle    f0104e21 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0104e16:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104e1a:	83 ea 0c             	sub    $0xc,%edx
f0104e1d:	39 f3                	cmp    %esi,%ebx
f0104e1f:	75 ee                	jne    f0104e0f <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104e21:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104e24:	89 07                	mov    %eax,(%edi)
	}
}
f0104e26:	83 c4 14             	add    $0x14,%esp
f0104e29:	5b                   	pop    %ebx
f0104e2a:	5e                   	pop    %esi
f0104e2b:	5f                   	pop    %edi
f0104e2c:	5d                   	pop    %ebp
f0104e2d:	c3                   	ret    

f0104e2e <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104e2e:	55                   	push   %ebp
f0104e2f:	89 e5                	mov    %esp,%ebp
f0104e31:	57                   	push   %edi
f0104e32:	56                   	push   %esi
f0104e33:	53                   	push   %ebx
f0104e34:	83 ec 4c             	sub    $0x4c,%esp
f0104e37:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104e3a:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104e3d:	c7 07 70 7f 10 f0    	movl   $0xf0107f70,(%edi)
	info->eip_line = 0;
f0104e43:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0104e4a:	c7 47 08 70 7f 10 f0 	movl   $0xf0107f70,0x8(%edi)
	info->eip_fn_namelen = 9;
f0104e51:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0104e58:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f0104e5b:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104e62:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0104e68:	0f 87 cf 00 00 00    	ja     f0104f3d <debuginfo_eip+0x10f>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
f0104e6e:	e8 56 11 00 00       	call   f0105fc9 <cpunum>
f0104e73:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f0104e7a:	00 
f0104e7b:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0104e82:	00 
f0104e83:	c7 44 24 04 00 00 20 	movl   $0x200000,0x4(%esp)
f0104e8a:	00 
f0104e8b:	6b c0 74             	imul   $0x74,%eax,%eax
f0104e8e:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104e94:	89 04 24             	mov    %eax,(%esp)
f0104e97:	e8 08 e7 ff ff       	call   f01035a4 <user_mem_check>
f0104e9c:	85 c0                	test   %eax,%eax
f0104e9e:	0f 88 5f 02 00 00    	js     f0105103 <debuginfo_eip+0x2d5>
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
		}
		stabs = usd->stabs;
f0104ea4:	a1 00 00 20 00       	mov    0x200000,%eax
		stab_end = usd->stab_end;
f0104ea9:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f0104eaf:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f0104eb5:	89 4d c0             	mov    %ecx,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f0104eb8:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f0104ebe:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
f0104ec1:	89 f2                	mov    %esi,%edx
f0104ec3:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0104ec6:	29 c2                	sub    %eax,%edx
f0104ec8:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0104ecb:	e8 f9 10 00 00       	call   f0105fc9 <cpunum>
f0104ed0:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f0104ed7:	00 
f0104ed8:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0104edb:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104edf:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0104ee2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104ee6:	6b c0 74             	imul   $0x74,%eax,%eax
f0104ee9:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104eef:	89 04 24             	mov    %eax,(%esp)
f0104ef2:	e8 ad e6 ff ff       	call   f01035a4 <user_mem_check>
f0104ef7:	85 c0                	test   %eax,%eax
f0104ef9:	0f 88 0b 02 00 00    	js     f010510a <debuginfo_eip+0x2dc>
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
		}

		if (user_mem_check(curenv, (const void *)stabstr,
f0104eff:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104f02:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0104f05:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0104f08:	e8 bc 10 00 00       	call   f0105fc9 <cpunum>
f0104f0d:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f0104f14:	00 
f0104f15:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0104f18:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104f1c:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f0104f1f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104f23:	6b c0 74             	imul   $0x74,%eax,%eax
f0104f26:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104f2c:	89 04 24             	mov    %eax,(%esp)
f0104f2f:	e8 70 e6 ff ff       	call   f01035a4 <user_mem_check>
f0104f34:	85 c0                	test   %eax,%eax
f0104f36:	79 1f                	jns    f0104f57 <debuginfo_eip+0x129>
f0104f38:	e9 d4 01 00 00       	jmp    f0105111 <debuginfo_eip+0x2e3>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104f3d:	c7 45 bc 85 5e 11 f0 	movl   $0xf0115e85,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104f44:	c7 45 c0 91 27 11 f0 	movl   $0xf0112791,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104f4b:	be 90 27 11 f0       	mov    $0xf0112790,%esi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104f50:	c7 45 c4 58 84 10 f0 	movl   $0xf0108458,-0x3c(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104f57:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104f5a:	39 45 c0             	cmp    %eax,-0x40(%ebp)
f0104f5d:	0f 83 b5 01 00 00    	jae    f0105118 <debuginfo_eip+0x2ea>
f0104f63:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0104f67:	0f 85 b2 01 00 00    	jne    f010511f <debuginfo_eip+0x2f1>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104f6d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104f74:	2b 75 c4             	sub    -0x3c(%ebp),%esi
f0104f77:	c1 fe 02             	sar    $0x2,%esi
f0104f7a:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f0104f80:	83 e8 01             	sub    $0x1,%eax
f0104f83:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104f86:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104f8a:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0104f91:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0104f94:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104f97:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0104f9a:	89 f0                	mov    %esi,%eax
f0104f9c:	e8 8b fd ff ff       	call   f0104d2c <stab_binsearch>
	if (lfile == 0)
f0104fa1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104fa4:	85 c0                	test   %eax,%eax
f0104fa6:	0f 84 7a 01 00 00    	je     f0105126 <debuginfo_eip+0x2f8>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104fac:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104faf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104fb2:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104fb5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104fb9:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0104fc0:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0104fc3:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104fc6:	89 f0                	mov    %esi,%eax
f0104fc8:	e8 5f fd ff ff       	call   f0104d2c <stab_binsearch>

	if (lfun <= rfun) {
f0104fcd:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104fd0:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0104fd3:	39 f0                	cmp    %esi,%eax
f0104fd5:	7f 32                	jg     f0105009 <debuginfo_eip+0x1db>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104fd7:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104fda:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0104fdd:	8d 14 91             	lea    (%ecx,%edx,4),%edx
f0104fe0:	8b 0a                	mov    (%edx),%ecx
f0104fe2:	89 4d b8             	mov    %ecx,-0x48(%ebp)
f0104fe5:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0104fe8:	2b 4d c0             	sub    -0x40(%ebp),%ecx
f0104feb:	39 4d b8             	cmp    %ecx,-0x48(%ebp)
f0104fee:	73 09                	jae    f0104ff9 <debuginfo_eip+0x1cb>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104ff0:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0104ff3:	03 4d c0             	add    -0x40(%ebp),%ecx
f0104ff6:	89 4f 08             	mov    %ecx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104ff9:	8b 52 08             	mov    0x8(%edx),%edx
f0104ffc:	89 57 10             	mov    %edx,0x10(%edi)
		addr -= info->eip_fn_addr;
f0104fff:	29 d3                	sub    %edx,%ebx
		// Search within the function definition for the line number.
		lline = lfun;
f0105001:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0105004:	89 75 d0             	mov    %esi,-0x30(%ebp)
f0105007:	eb 0f                	jmp    f0105018 <debuginfo_eip+0x1ea>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0105009:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f010500c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010500f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0105012:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105015:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0105018:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f010501f:	00 
f0105020:	8b 47 08             	mov    0x8(%edi),%eax
f0105023:	89 04 24             	mov    %eax,(%esp)
f0105026:	e8 30 09 00 00       	call   f010595b <strfind>
f010502b:	2b 47 08             	sub    0x8(%edi),%eax
f010502e:	89 47 0c             	mov    %eax,0xc(%edi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
f0105031:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0105035:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f010503c:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f010503f:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0105042:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0105045:	89 f0                	mov    %esi,%eax
f0105047:	e8 e0 fc ff ff       	call   f0104d2c <stab_binsearch>
	if (lline > rline) {
f010504c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010504f:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0105052:	0f 8f d5 00 00 00    	jg     f010512d <debuginfo_eip+0x2ff>
		return -1; //Did not find the line number in the stab
	}
	info->eip_line = stabs[lline].n_desc; //If found update the info object with the correct line number
f0105058:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010505b:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0105060:	89 47 04             	mov    %eax,0x4(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0105063:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105066:	89 c3                	mov    %eax,%ebx
f0105068:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010506b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010506e:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0105071:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0105074:	89 df                	mov    %ebx,%edi
f0105076:	eb 06                	jmp    f010507e <debuginfo_eip+0x250>
f0105078:	83 e8 01             	sub    $0x1,%eax
f010507b:	83 ea 0c             	sub    $0xc,%edx
f010507e:	89 c6                	mov    %eax,%esi
f0105080:	39 c7                	cmp    %eax,%edi
f0105082:	7f 3c                	jg     f01050c0 <debuginfo_eip+0x292>
	       && stabs[lline].n_type != N_SOL
f0105084:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0105088:	80 f9 84             	cmp    $0x84,%cl
f010508b:	75 08                	jne    f0105095 <debuginfo_eip+0x267>
f010508d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0105090:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0105093:	eb 11                	jmp    f01050a6 <debuginfo_eip+0x278>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0105095:	80 f9 64             	cmp    $0x64,%cl
f0105098:	75 de                	jne    f0105078 <debuginfo_eip+0x24a>
f010509a:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f010509e:	74 d8                	je     f0105078 <debuginfo_eip+0x24a>
f01050a0:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01050a3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01050a6:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01050a9:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f01050ac:	8b 04 83             	mov    (%ebx,%eax,4),%eax
f01050af:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01050b2:	2b 55 c0             	sub    -0x40(%ebp),%edx
f01050b5:	39 d0                	cmp    %edx,%eax
f01050b7:	73 0a                	jae    f01050c3 <debuginfo_eip+0x295>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01050b9:	03 45 c0             	add    -0x40(%ebp),%eax
f01050bc:	89 07                	mov    %eax,(%edi)
f01050be:	eb 03                	jmp    f01050c3 <debuginfo_eip+0x295>
f01050c0:	8b 7d 0c             	mov    0xc(%ebp),%edi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01050c3:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01050c6:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01050c9:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01050ce:	39 da                	cmp    %ebx,%edx
f01050d0:	7d 67                	jge    f0105139 <debuginfo_eip+0x30b>
		for (lline = lfun + 1;
f01050d2:	83 c2 01             	add    $0x1,%edx
f01050d5:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01050d8:	89 d0                	mov    %edx,%eax
f01050da:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01050dd:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01050e0:	8d 14 96             	lea    (%esi,%edx,4),%edx
f01050e3:	eb 04                	jmp    f01050e9 <debuginfo_eip+0x2bb>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01050e5:	83 47 14 01          	addl   $0x1,0x14(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01050e9:	39 c3                	cmp    %eax,%ebx
f01050eb:	7e 47                	jle    f0105134 <debuginfo_eip+0x306>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01050ed:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01050f1:	83 c0 01             	add    $0x1,%eax
f01050f4:	83 c2 0c             	add    $0xc,%edx
f01050f7:	80 f9 a0             	cmp    $0xa0,%cl
f01050fa:	74 e9                	je     f01050e5 <debuginfo_eip+0x2b7>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01050fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0105101:	eb 36                	jmp    f0105139 <debuginfo_eip+0x30b>
		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
f0105103:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105108:	eb 2f                	jmp    f0105139 <debuginfo_eip+0x30b>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
f010510a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010510f:	eb 28                	jmp    f0105139 <debuginfo_eip+0x30b>
		}

		if (user_mem_check(curenv, (const void *)stabstr,
				(uintptr_t)stabstr_end - (uintptr_t)stabstr, PTE_U | PTE_P) < 0) {
			return -1;
f0105111:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105116:	eb 21                	jmp    f0105139 <debuginfo_eip+0x30b>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0105118:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010511d:	eb 1a                	jmp    f0105139 <debuginfo_eip+0x30b>
f010511f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105124:	eb 13                	jmp    f0105139 <debuginfo_eip+0x30b>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0105126:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010512b:	eb 0c                	jmp    f0105139 <debuginfo_eip+0x30b>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
	if (lline > rline) {
		return -1; //Did not find the line number in the stab
f010512d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105132:	eb 05                	jmp    f0105139 <debuginfo_eip+0x30b>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0105134:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105139:	83 c4 4c             	add    $0x4c,%esp
f010513c:	5b                   	pop    %ebx
f010513d:	5e                   	pop    %esi
f010513e:	5f                   	pop    %edi
f010513f:	5d                   	pop    %ebp
f0105140:	c3                   	ret    
f0105141:	66 90                	xchg   %ax,%ax
f0105143:	66 90                	xchg   %ax,%ax
f0105145:	66 90                	xchg   %ax,%ax
f0105147:	66 90                	xchg   %ax,%ax
f0105149:	66 90                	xchg   %ax,%ax
f010514b:	66 90                	xchg   %ax,%ax
f010514d:	66 90                	xchg   %ax,%ax
f010514f:	90                   	nop

f0105150 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0105150:	55                   	push   %ebp
f0105151:	89 e5                	mov    %esp,%ebp
f0105153:	57                   	push   %edi
f0105154:	56                   	push   %esi
f0105155:	53                   	push   %ebx
f0105156:	83 ec 3c             	sub    $0x3c,%esp
f0105159:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010515c:	89 d7                	mov    %edx,%edi
f010515e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105161:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0105164:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105167:	89 c3                	mov    %eax,%ebx
f0105169:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010516c:	8b 45 10             	mov    0x10(%ebp),%eax
f010516f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0105172:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105177:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010517a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010517d:	39 d9                	cmp    %ebx,%ecx
f010517f:	72 05                	jb     f0105186 <printnum+0x36>
f0105181:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0105184:	77 69                	ja     f01051ef <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0105186:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0105189:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010518d:	83 ee 01             	sub    $0x1,%esi
f0105190:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0105194:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105198:	8b 44 24 08          	mov    0x8(%esp),%eax
f010519c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01051a0:	89 c3                	mov    %eax,%ebx
f01051a2:	89 d6                	mov    %edx,%esi
f01051a4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01051a7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01051aa:	89 54 24 08          	mov    %edx,0x8(%esp)
f01051ae:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01051b2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01051b5:	89 04 24             	mov    %eax,(%esp)
f01051b8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01051bb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01051bf:	e8 4c 12 00 00       	call   f0106410 <__udivdi3>
f01051c4:	89 d9                	mov    %ebx,%ecx
f01051c6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01051ca:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01051ce:	89 04 24             	mov    %eax,(%esp)
f01051d1:	89 54 24 04          	mov    %edx,0x4(%esp)
f01051d5:	89 fa                	mov    %edi,%edx
f01051d7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01051da:	e8 71 ff ff ff       	call   f0105150 <printnum>
f01051df:	eb 1b                	jmp    f01051fc <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01051e1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01051e5:	8b 45 18             	mov    0x18(%ebp),%eax
f01051e8:	89 04 24             	mov    %eax,(%esp)
f01051eb:	ff d3                	call   *%ebx
f01051ed:	eb 03                	jmp    f01051f2 <printnum+0xa2>
f01051ef:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01051f2:	83 ee 01             	sub    $0x1,%esi
f01051f5:	85 f6                	test   %esi,%esi
f01051f7:	7f e8                	jg     f01051e1 <printnum+0x91>
f01051f9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01051fc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105200:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0105204:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0105207:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010520a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010520e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0105212:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105215:	89 04 24             	mov    %eax,(%esp)
f0105218:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010521b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010521f:	e8 1c 13 00 00       	call   f0106540 <__umoddi3>
f0105224:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105228:	0f be 80 7a 7f 10 f0 	movsbl -0xfef8086(%eax),%eax
f010522f:	89 04 24             	mov    %eax,(%esp)
f0105232:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105235:	ff d0                	call   *%eax
}
f0105237:	83 c4 3c             	add    $0x3c,%esp
f010523a:	5b                   	pop    %ebx
f010523b:	5e                   	pop    %esi
f010523c:	5f                   	pop    %edi
f010523d:	5d                   	pop    %ebp
f010523e:	c3                   	ret    

f010523f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010523f:	55                   	push   %ebp
f0105240:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0105242:	83 fa 01             	cmp    $0x1,%edx
f0105245:	7e 0e                	jle    f0105255 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0105247:	8b 10                	mov    (%eax),%edx
f0105249:	8d 4a 08             	lea    0x8(%edx),%ecx
f010524c:	89 08                	mov    %ecx,(%eax)
f010524e:	8b 02                	mov    (%edx),%eax
f0105250:	8b 52 04             	mov    0x4(%edx),%edx
f0105253:	eb 22                	jmp    f0105277 <getuint+0x38>
	else if (lflag)
f0105255:	85 d2                	test   %edx,%edx
f0105257:	74 10                	je     f0105269 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0105259:	8b 10                	mov    (%eax),%edx
f010525b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010525e:	89 08                	mov    %ecx,(%eax)
f0105260:	8b 02                	mov    (%edx),%eax
f0105262:	ba 00 00 00 00       	mov    $0x0,%edx
f0105267:	eb 0e                	jmp    f0105277 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0105269:	8b 10                	mov    (%eax),%edx
f010526b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010526e:	89 08                	mov    %ecx,(%eax)
f0105270:	8b 02                	mov    (%edx),%eax
f0105272:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0105277:	5d                   	pop    %ebp
f0105278:	c3                   	ret    

f0105279 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0105279:	55                   	push   %ebp
f010527a:	89 e5                	mov    %esp,%ebp
f010527c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010527f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0105283:	8b 10                	mov    (%eax),%edx
f0105285:	3b 50 04             	cmp    0x4(%eax),%edx
f0105288:	73 0a                	jae    f0105294 <sprintputch+0x1b>
		*b->buf++ = ch;
f010528a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010528d:	89 08                	mov    %ecx,(%eax)
f010528f:	8b 45 08             	mov    0x8(%ebp),%eax
f0105292:	88 02                	mov    %al,(%edx)
}
f0105294:	5d                   	pop    %ebp
f0105295:	c3                   	ret    

f0105296 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0105296:	55                   	push   %ebp
f0105297:	89 e5                	mov    %esp,%ebp
f0105299:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f010529c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010529f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01052a3:	8b 45 10             	mov    0x10(%ebp),%eax
f01052a6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01052aa:	8b 45 0c             	mov    0xc(%ebp),%eax
f01052ad:	89 44 24 04          	mov    %eax,0x4(%esp)
f01052b1:	8b 45 08             	mov    0x8(%ebp),%eax
f01052b4:	89 04 24             	mov    %eax,(%esp)
f01052b7:	e8 02 00 00 00       	call   f01052be <vprintfmt>
	va_end(ap);
}
f01052bc:	c9                   	leave  
f01052bd:	c3                   	ret    

f01052be <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01052be:	55                   	push   %ebp
f01052bf:	89 e5                	mov    %esp,%ebp
f01052c1:	57                   	push   %edi
f01052c2:	56                   	push   %esi
f01052c3:	53                   	push   %ebx
f01052c4:	83 ec 3c             	sub    $0x3c,%esp
f01052c7:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01052ca:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01052cd:	eb 14                	jmp    f01052e3 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01052cf:	85 c0                	test   %eax,%eax
f01052d1:	0f 84 b3 03 00 00    	je     f010568a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f01052d7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01052db:	89 04 24             	mov    %eax,(%esp)
f01052de:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01052e1:	89 f3                	mov    %esi,%ebx
f01052e3:	8d 73 01             	lea    0x1(%ebx),%esi
f01052e6:	0f b6 03             	movzbl (%ebx),%eax
f01052e9:	83 f8 25             	cmp    $0x25,%eax
f01052ec:	75 e1                	jne    f01052cf <vprintfmt+0x11>
f01052ee:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f01052f2:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01052f9:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0105300:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0105307:	ba 00 00 00 00       	mov    $0x0,%edx
f010530c:	eb 1d                	jmp    f010532b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010530e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0105310:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0105314:	eb 15                	jmp    f010532b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105316:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0105318:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f010531c:	eb 0d                	jmp    f010532b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f010531e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0105321:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0105324:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010532b:	8d 5e 01             	lea    0x1(%esi),%ebx
f010532e:	0f b6 0e             	movzbl (%esi),%ecx
f0105331:	0f b6 c1             	movzbl %cl,%eax
f0105334:	83 e9 23             	sub    $0x23,%ecx
f0105337:	80 f9 55             	cmp    $0x55,%cl
f010533a:	0f 87 2a 03 00 00    	ja     f010566a <vprintfmt+0x3ac>
f0105340:	0f b6 c9             	movzbl %cl,%ecx
f0105343:	ff 24 8d 40 80 10 f0 	jmp    *-0xfef7fc0(,%ecx,4)
f010534a:	89 de                	mov    %ebx,%esi
f010534c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0105351:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0105354:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0105358:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f010535b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f010535e:	83 fb 09             	cmp    $0x9,%ebx
f0105361:	77 36                	ja     f0105399 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0105363:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0105366:	eb e9                	jmp    f0105351 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0105368:	8b 45 14             	mov    0x14(%ebp),%eax
f010536b:	8d 48 04             	lea    0x4(%eax),%ecx
f010536e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0105371:	8b 00                	mov    (%eax),%eax
f0105373:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105376:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0105378:	eb 22                	jmp    f010539c <vprintfmt+0xde>
f010537a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010537d:	85 c9                	test   %ecx,%ecx
f010537f:	b8 00 00 00 00       	mov    $0x0,%eax
f0105384:	0f 49 c1             	cmovns %ecx,%eax
f0105387:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010538a:	89 de                	mov    %ebx,%esi
f010538c:	eb 9d                	jmp    f010532b <vprintfmt+0x6d>
f010538e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0105390:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0105397:	eb 92                	jmp    f010532b <vprintfmt+0x6d>
f0105399:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f010539c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01053a0:	79 89                	jns    f010532b <vprintfmt+0x6d>
f01053a2:	e9 77 ff ff ff       	jmp    f010531e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01053a7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01053aa:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01053ac:	e9 7a ff ff ff       	jmp    f010532b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01053b1:	8b 45 14             	mov    0x14(%ebp),%eax
f01053b4:	8d 50 04             	lea    0x4(%eax),%edx
f01053b7:	89 55 14             	mov    %edx,0x14(%ebp)
f01053ba:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01053be:	8b 00                	mov    (%eax),%eax
f01053c0:	89 04 24             	mov    %eax,(%esp)
f01053c3:	ff 55 08             	call   *0x8(%ebp)
			break;
f01053c6:	e9 18 ff ff ff       	jmp    f01052e3 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01053cb:	8b 45 14             	mov    0x14(%ebp),%eax
f01053ce:	8d 50 04             	lea    0x4(%eax),%edx
f01053d1:	89 55 14             	mov    %edx,0x14(%ebp)
f01053d4:	8b 00                	mov    (%eax),%eax
f01053d6:	99                   	cltd   
f01053d7:	31 d0                	xor    %edx,%eax
f01053d9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01053db:	83 f8 09             	cmp    $0x9,%eax
f01053de:	7f 0b                	jg     f01053eb <vprintfmt+0x12d>
f01053e0:	8b 14 85 a0 81 10 f0 	mov    -0xfef7e60(,%eax,4),%edx
f01053e7:	85 d2                	test   %edx,%edx
f01053e9:	75 20                	jne    f010540b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f01053eb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01053ef:	c7 44 24 08 92 7f 10 	movl   $0xf0107f92,0x8(%esp)
f01053f6:	f0 
f01053f7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01053fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01053fe:	89 04 24             	mov    %eax,(%esp)
f0105401:	e8 90 fe ff ff       	call   f0105296 <printfmt>
f0105406:	e9 d8 fe ff ff       	jmp    f01052e3 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f010540b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010540f:	c7 44 24 08 8d 76 10 	movl   $0xf010768d,0x8(%esp)
f0105416:	f0 
f0105417:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010541b:	8b 45 08             	mov    0x8(%ebp),%eax
f010541e:	89 04 24             	mov    %eax,(%esp)
f0105421:	e8 70 fe ff ff       	call   f0105296 <printfmt>
f0105426:	e9 b8 fe ff ff       	jmp    f01052e3 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010542b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010542e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0105431:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0105434:	8b 45 14             	mov    0x14(%ebp),%eax
f0105437:	8d 50 04             	lea    0x4(%eax),%edx
f010543a:	89 55 14             	mov    %edx,0x14(%ebp)
f010543d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010543f:	85 f6                	test   %esi,%esi
f0105441:	b8 8b 7f 10 f0       	mov    $0xf0107f8b,%eax
f0105446:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0105449:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010544d:	0f 84 97 00 00 00    	je     f01054ea <vprintfmt+0x22c>
f0105453:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0105457:	0f 8e 9b 00 00 00    	jle    f01054f8 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f010545d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0105461:	89 34 24             	mov    %esi,(%esp)
f0105464:	e8 9f 03 00 00       	call   f0105808 <strnlen>
f0105469:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010546c:	29 c2                	sub    %eax,%edx
f010546e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0105471:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0105475:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0105478:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010547b:	8b 75 08             	mov    0x8(%ebp),%esi
f010547e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105481:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0105483:	eb 0f                	jmp    f0105494 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0105485:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105489:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010548c:	89 04 24             	mov    %eax,(%esp)
f010548f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0105491:	83 eb 01             	sub    $0x1,%ebx
f0105494:	85 db                	test   %ebx,%ebx
f0105496:	7f ed                	jg     f0105485 <vprintfmt+0x1c7>
f0105498:	8b 75 d8             	mov    -0x28(%ebp),%esi
f010549b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010549e:	85 d2                	test   %edx,%edx
f01054a0:	b8 00 00 00 00       	mov    $0x0,%eax
f01054a5:	0f 49 c2             	cmovns %edx,%eax
f01054a8:	29 c2                	sub    %eax,%edx
f01054aa:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01054ad:	89 d7                	mov    %edx,%edi
f01054af:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01054b2:	eb 50                	jmp    f0105504 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01054b4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01054b8:	74 1e                	je     f01054d8 <vprintfmt+0x21a>
f01054ba:	0f be d2             	movsbl %dl,%edx
f01054bd:	83 ea 20             	sub    $0x20,%edx
f01054c0:	83 fa 5e             	cmp    $0x5e,%edx
f01054c3:	76 13                	jbe    f01054d8 <vprintfmt+0x21a>
					putch('?', putdat);
f01054c5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01054c8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01054cc:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01054d3:	ff 55 08             	call   *0x8(%ebp)
f01054d6:	eb 0d                	jmp    f01054e5 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f01054d8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01054db:	89 54 24 04          	mov    %edx,0x4(%esp)
f01054df:	89 04 24             	mov    %eax,(%esp)
f01054e2:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01054e5:	83 ef 01             	sub    $0x1,%edi
f01054e8:	eb 1a                	jmp    f0105504 <vprintfmt+0x246>
f01054ea:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01054ed:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01054f0:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01054f3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01054f6:	eb 0c                	jmp    f0105504 <vprintfmt+0x246>
f01054f8:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01054fb:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01054fe:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105501:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0105504:	83 c6 01             	add    $0x1,%esi
f0105507:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f010550b:	0f be c2             	movsbl %dl,%eax
f010550e:	85 c0                	test   %eax,%eax
f0105510:	74 27                	je     f0105539 <vprintfmt+0x27b>
f0105512:	85 db                	test   %ebx,%ebx
f0105514:	78 9e                	js     f01054b4 <vprintfmt+0x1f6>
f0105516:	83 eb 01             	sub    $0x1,%ebx
f0105519:	79 99                	jns    f01054b4 <vprintfmt+0x1f6>
f010551b:	89 f8                	mov    %edi,%eax
f010551d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0105520:	8b 75 08             	mov    0x8(%ebp),%esi
f0105523:	89 c3                	mov    %eax,%ebx
f0105525:	eb 1a                	jmp    f0105541 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0105527:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010552b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0105532:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0105534:	83 eb 01             	sub    $0x1,%ebx
f0105537:	eb 08                	jmp    f0105541 <vprintfmt+0x283>
f0105539:	89 fb                	mov    %edi,%ebx
f010553b:	8b 75 08             	mov    0x8(%ebp),%esi
f010553e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0105541:	85 db                	test   %ebx,%ebx
f0105543:	7f e2                	jg     f0105527 <vprintfmt+0x269>
f0105545:	89 75 08             	mov    %esi,0x8(%ebp)
f0105548:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010554b:	e9 93 fd ff ff       	jmp    f01052e3 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0105550:	83 fa 01             	cmp    $0x1,%edx
f0105553:	7e 16                	jle    f010556b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0105555:	8b 45 14             	mov    0x14(%ebp),%eax
f0105558:	8d 50 08             	lea    0x8(%eax),%edx
f010555b:	89 55 14             	mov    %edx,0x14(%ebp)
f010555e:	8b 50 04             	mov    0x4(%eax),%edx
f0105561:	8b 00                	mov    (%eax),%eax
f0105563:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0105566:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0105569:	eb 32                	jmp    f010559d <vprintfmt+0x2df>
	else if (lflag)
f010556b:	85 d2                	test   %edx,%edx
f010556d:	74 18                	je     f0105587 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010556f:	8b 45 14             	mov    0x14(%ebp),%eax
f0105572:	8d 50 04             	lea    0x4(%eax),%edx
f0105575:	89 55 14             	mov    %edx,0x14(%ebp)
f0105578:	8b 30                	mov    (%eax),%esi
f010557a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010557d:	89 f0                	mov    %esi,%eax
f010557f:	c1 f8 1f             	sar    $0x1f,%eax
f0105582:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105585:	eb 16                	jmp    f010559d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0105587:	8b 45 14             	mov    0x14(%ebp),%eax
f010558a:	8d 50 04             	lea    0x4(%eax),%edx
f010558d:	89 55 14             	mov    %edx,0x14(%ebp)
f0105590:	8b 30                	mov    (%eax),%esi
f0105592:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0105595:	89 f0                	mov    %esi,%eax
f0105597:	c1 f8 1f             	sar    $0x1f,%eax
f010559a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010559d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01055a0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01055a3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01055a8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01055ac:	0f 89 80 00 00 00    	jns    f0105632 <vprintfmt+0x374>
				putch('-', putdat);
f01055b2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01055b6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01055bd:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01055c0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01055c3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01055c6:	f7 d8                	neg    %eax
f01055c8:	83 d2 00             	adc    $0x0,%edx
f01055cb:	f7 da                	neg    %edx
			}
			base = 10;
f01055cd:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01055d2:	eb 5e                	jmp    f0105632 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01055d4:	8d 45 14             	lea    0x14(%ebp),%eax
f01055d7:	e8 63 fc ff ff       	call   f010523f <getuint>
			base = 10;
f01055dc:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01055e1:	eb 4f                	jmp    f0105632 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01055e3:	8d 45 14             	lea    0x14(%ebp),%eax
f01055e6:	e8 54 fc ff ff       	call   f010523f <getuint>
			base = 8;
f01055eb:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01055f0:	eb 40                	jmp    f0105632 <vprintfmt+0x374>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f01055f2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01055f6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01055fd:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0105600:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105604:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010560b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010560e:	8b 45 14             	mov    0x14(%ebp),%eax
f0105611:	8d 50 04             	lea    0x4(%eax),%edx
f0105614:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0105617:	8b 00                	mov    (%eax),%eax
f0105619:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010561e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0105623:	eb 0d                	jmp    f0105632 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0105625:	8d 45 14             	lea    0x14(%ebp),%eax
f0105628:	e8 12 fc ff ff       	call   f010523f <getuint>
			base = 16;
f010562d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0105632:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0105636:	89 74 24 10          	mov    %esi,0x10(%esp)
f010563a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010563d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0105641:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105645:	89 04 24             	mov    %eax,(%esp)
f0105648:	89 54 24 04          	mov    %edx,0x4(%esp)
f010564c:	89 fa                	mov    %edi,%edx
f010564e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105651:	e8 fa fa ff ff       	call   f0105150 <printnum>
			break;
f0105656:	e9 88 fc ff ff       	jmp    f01052e3 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010565b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010565f:	89 04 24             	mov    %eax,(%esp)
f0105662:	ff 55 08             	call   *0x8(%ebp)
			break;
f0105665:	e9 79 fc ff ff       	jmp    f01052e3 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010566a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010566e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0105675:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0105678:	89 f3                	mov    %esi,%ebx
f010567a:	eb 03                	jmp    f010567f <vprintfmt+0x3c1>
f010567c:	83 eb 01             	sub    $0x1,%ebx
f010567f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0105683:	75 f7                	jne    f010567c <vprintfmt+0x3be>
f0105685:	e9 59 fc ff ff       	jmp    f01052e3 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010568a:	83 c4 3c             	add    $0x3c,%esp
f010568d:	5b                   	pop    %ebx
f010568e:	5e                   	pop    %esi
f010568f:	5f                   	pop    %edi
f0105690:	5d                   	pop    %ebp
f0105691:	c3                   	ret    

f0105692 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0105692:	55                   	push   %ebp
f0105693:	89 e5                	mov    %esp,%ebp
f0105695:	83 ec 28             	sub    $0x28,%esp
f0105698:	8b 45 08             	mov    0x8(%ebp),%eax
f010569b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010569e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01056a1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01056a5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01056a8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01056af:	85 c0                	test   %eax,%eax
f01056b1:	74 30                	je     f01056e3 <vsnprintf+0x51>
f01056b3:	85 d2                	test   %edx,%edx
f01056b5:	7e 2c                	jle    f01056e3 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01056b7:	8b 45 14             	mov    0x14(%ebp),%eax
f01056ba:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01056be:	8b 45 10             	mov    0x10(%ebp),%eax
f01056c1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01056c5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01056c8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01056cc:	c7 04 24 79 52 10 f0 	movl   $0xf0105279,(%esp)
f01056d3:	e8 e6 fb ff ff       	call   f01052be <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01056d8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01056db:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01056de:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01056e1:	eb 05                	jmp    f01056e8 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01056e3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01056e8:	c9                   	leave  
f01056e9:	c3                   	ret    

f01056ea <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01056ea:	55                   	push   %ebp
f01056eb:	89 e5                	mov    %esp,%ebp
f01056ed:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01056f0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01056f3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01056f7:	8b 45 10             	mov    0x10(%ebp),%eax
f01056fa:	89 44 24 08          	mov    %eax,0x8(%esp)
f01056fe:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105701:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105705:	8b 45 08             	mov    0x8(%ebp),%eax
f0105708:	89 04 24             	mov    %eax,(%esp)
f010570b:	e8 82 ff ff ff       	call   f0105692 <vsnprintf>
	va_end(ap);

	return rc;
}
f0105710:	c9                   	leave  
f0105711:	c3                   	ret    
f0105712:	66 90                	xchg   %ax,%ax
f0105714:	66 90                	xchg   %ax,%ax
f0105716:	66 90                	xchg   %ax,%ax
f0105718:	66 90                	xchg   %ax,%ax
f010571a:	66 90                	xchg   %ax,%ax
f010571c:	66 90                	xchg   %ax,%ax
f010571e:	66 90                	xchg   %ax,%ax

f0105720 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0105720:	55                   	push   %ebp
f0105721:	89 e5                	mov    %esp,%ebp
f0105723:	57                   	push   %edi
f0105724:	56                   	push   %esi
f0105725:	53                   	push   %ebx
f0105726:	83 ec 1c             	sub    $0x1c,%esp
f0105729:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010572c:	85 c0                	test   %eax,%eax
f010572e:	74 10                	je     f0105740 <readline+0x20>
		cprintf("%s", prompt);
f0105730:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105734:	c7 04 24 8d 76 10 f0 	movl   $0xf010768d,(%esp)
f010573b:	e8 7c e9 ff ff       	call   f01040bc <cprintf>

	i = 0;
	echoing = iscons(0);
f0105740:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0105747:	e8 0f b0 ff ff       	call   f010075b <iscons>
f010574c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010574e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0105753:	e8 f2 af ff ff       	call   f010074a <getchar>
f0105758:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010575a:	85 c0                	test   %eax,%eax
f010575c:	79 17                	jns    f0105775 <readline+0x55>
			cprintf("read error: %e\n", c);
f010575e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105762:	c7 04 24 c8 81 10 f0 	movl   $0xf01081c8,(%esp)
f0105769:	e8 4e e9 ff ff       	call   f01040bc <cprintf>
			return NULL;
f010576e:	b8 00 00 00 00       	mov    $0x0,%eax
f0105773:	eb 6d                	jmp    f01057e2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0105775:	83 f8 7f             	cmp    $0x7f,%eax
f0105778:	74 05                	je     f010577f <readline+0x5f>
f010577a:	83 f8 08             	cmp    $0x8,%eax
f010577d:	75 19                	jne    f0105798 <readline+0x78>
f010577f:	85 f6                	test   %esi,%esi
f0105781:	7e 15                	jle    f0105798 <readline+0x78>
			if (echoing)
f0105783:	85 ff                	test   %edi,%edi
f0105785:	74 0c                	je     f0105793 <readline+0x73>
				cputchar('\b');
f0105787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010578e:	e8 a7 af ff ff       	call   f010073a <cputchar>
			i--;
f0105793:	83 ee 01             	sub    $0x1,%esi
f0105796:	eb bb                	jmp    f0105753 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0105798:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010579e:	7f 1c                	jg     f01057bc <readline+0x9c>
f01057a0:	83 fb 1f             	cmp    $0x1f,%ebx
f01057a3:	7e 17                	jle    f01057bc <readline+0x9c>
			if (echoing)
f01057a5:	85 ff                	test   %edi,%edi
f01057a7:	74 08                	je     f01057b1 <readline+0x91>
				cputchar(c);
f01057a9:	89 1c 24             	mov    %ebx,(%esp)
f01057ac:	e8 89 af ff ff       	call   f010073a <cputchar>
			buf[i++] = c;
f01057b1:	88 9e 80 ba 22 f0    	mov    %bl,-0xfdd4580(%esi)
f01057b7:	8d 76 01             	lea    0x1(%esi),%esi
f01057ba:	eb 97                	jmp    f0105753 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01057bc:	83 fb 0d             	cmp    $0xd,%ebx
f01057bf:	74 05                	je     f01057c6 <readline+0xa6>
f01057c1:	83 fb 0a             	cmp    $0xa,%ebx
f01057c4:	75 8d                	jne    f0105753 <readline+0x33>
			if (echoing)
f01057c6:	85 ff                	test   %edi,%edi
f01057c8:	74 0c                	je     f01057d6 <readline+0xb6>
				cputchar('\n');
f01057ca:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01057d1:	e8 64 af ff ff       	call   f010073a <cputchar>
			buf[i] = 0;
f01057d6:	c6 86 80 ba 22 f0 00 	movb   $0x0,-0xfdd4580(%esi)
			return buf;
f01057dd:	b8 80 ba 22 f0       	mov    $0xf022ba80,%eax
		}
	}
}
f01057e2:	83 c4 1c             	add    $0x1c,%esp
f01057e5:	5b                   	pop    %ebx
f01057e6:	5e                   	pop    %esi
f01057e7:	5f                   	pop    %edi
f01057e8:	5d                   	pop    %ebp
f01057e9:	c3                   	ret    
f01057ea:	66 90                	xchg   %ax,%ax
f01057ec:	66 90                	xchg   %ax,%ax
f01057ee:	66 90                	xchg   %ax,%ax

f01057f0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01057f0:	55                   	push   %ebp
f01057f1:	89 e5                	mov    %esp,%ebp
f01057f3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01057f6:	b8 00 00 00 00       	mov    $0x0,%eax
f01057fb:	eb 03                	jmp    f0105800 <strlen+0x10>
		n++;
f01057fd:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0105800:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0105804:	75 f7                	jne    f01057fd <strlen+0xd>
		n++;
	return n;
}
f0105806:	5d                   	pop    %ebp
f0105807:	c3                   	ret    

f0105808 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0105808:	55                   	push   %ebp
f0105809:	89 e5                	mov    %esp,%ebp
f010580b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010580e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105811:	b8 00 00 00 00       	mov    $0x0,%eax
f0105816:	eb 03                	jmp    f010581b <strnlen+0x13>
		n++;
f0105818:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010581b:	39 d0                	cmp    %edx,%eax
f010581d:	74 06                	je     f0105825 <strnlen+0x1d>
f010581f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0105823:	75 f3                	jne    f0105818 <strnlen+0x10>
		n++;
	return n;
}
f0105825:	5d                   	pop    %ebp
f0105826:	c3                   	ret    

f0105827 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0105827:	55                   	push   %ebp
f0105828:	89 e5                	mov    %esp,%ebp
f010582a:	53                   	push   %ebx
f010582b:	8b 45 08             	mov    0x8(%ebp),%eax
f010582e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0105831:	89 c2                	mov    %eax,%edx
f0105833:	83 c2 01             	add    $0x1,%edx
f0105836:	83 c1 01             	add    $0x1,%ecx
f0105839:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010583d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0105840:	84 db                	test   %bl,%bl
f0105842:	75 ef                	jne    f0105833 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0105844:	5b                   	pop    %ebx
f0105845:	5d                   	pop    %ebp
f0105846:	c3                   	ret    

f0105847 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0105847:	55                   	push   %ebp
f0105848:	89 e5                	mov    %esp,%ebp
f010584a:	53                   	push   %ebx
f010584b:	83 ec 08             	sub    $0x8,%esp
f010584e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0105851:	89 1c 24             	mov    %ebx,(%esp)
f0105854:	e8 97 ff ff ff       	call   f01057f0 <strlen>
	strcpy(dst + len, src);
f0105859:	8b 55 0c             	mov    0xc(%ebp),%edx
f010585c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105860:	01 d8                	add    %ebx,%eax
f0105862:	89 04 24             	mov    %eax,(%esp)
f0105865:	e8 bd ff ff ff       	call   f0105827 <strcpy>
	return dst;
}
f010586a:	89 d8                	mov    %ebx,%eax
f010586c:	83 c4 08             	add    $0x8,%esp
f010586f:	5b                   	pop    %ebx
f0105870:	5d                   	pop    %ebp
f0105871:	c3                   	ret    

f0105872 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0105872:	55                   	push   %ebp
f0105873:	89 e5                	mov    %esp,%ebp
f0105875:	56                   	push   %esi
f0105876:	53                   	push   %ebx
f0105877:	8b 75 08             	mov    0x8(%ebp),%esi
f010587a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010587d:	89 f3                	mov    %esi,%ebx
f010587f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105882:	89 f2                	mov    %esi,%edx
f0105884:	eb 0f                	jmp    f0105895 <strncpy+0x23>
		*dst++ = *src;
f0105886:	83 c2 01             	add    $0x1,%edx
f0105889:	0f b6 01             	movzbl (%ecx),%eax
f010588c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010588f:	80 39 01             	cmpb   $0x1,(%ecx)
f0105892:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105895:	39 da                	cmp    %ebx,%edx
f0105897:	75 ed                	jne    f0105886 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0105899:	89 f0                	mov    %esi,%eax
f010589b:	5b                   	pop    %ebx
f010589c:	5e                   	pop    %esi
f010589d:	5d                   	pop    %ebp
f010589e:	c3                   	ret    

f010589f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010589f:	55                   	push   %ebp
f01058a0:	89 e5                	mov    %esp,%ebp
f01058a2:	56                   	push   %esi
f01058a3:	53                   	push   %ebx
f01058a4:	8b 75 08             	mov    0x8(%ebp),%esi
f01058a7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01058aa:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01058ad:	89 f0                	mov    %esi,%eax
f01058af:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01058b3:	85 c9                	test   %ecx,%ecx
f01058b5:	75 0b                	jne    f01058c2 <strlcpy+0x23>
f01058b7:	eb 1d                	jmp    f01058d6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01058b9:	83 c0 01             	add    $0x1,%eax
f01058bc:	83 c2 01             	add    $0x1,%edx
f01058bf:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01058c2:	39 d8                	cmp    %ebx,%eax
f01058c4:	74 0b                	je     f01058d1 <strlcpy+0x32>
f01058c6:	0f b6 0a             	movzbl (%edx),%ecx
f01058c9:	84 c9                	test   %cl,%cl
f01058cb:	75 ec                	jne    f01058b9 <strlcpy+0x1a>
f01058cd:	89 c2                	mov    %eax,%edx
f01058cf:	eb 02                	jmp    f01058d3 <strlcpy+0x34>
f01058d1:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f01058d3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f01058d6:	29 f0                	sub    %esi,%eax
}
f01058d8:	5b                   	pop    %ebx
f01058d9:	5e                   	pop    %esi
f01058da:	5d                   	pop    %ebp
f01058db:	c3                   	ret    

f01058dc <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01058dc:	55                   	push   %ebp
f01058dd:	89 e5                	mov    %esp,%ebp
f01058df:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01058e2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01058e5:	eb 06                	jmp    f01058ed <strcmp+0x11>
		p++, q++;
f01058e7:	83 c1 01             	add    $0x1,%ecx
f01058ea:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01058ed:	0f b6 01             	movzbl (%ecx),%eax
f01058f0:	84 c0                	test   %al,%al
f01058f2:	74 04                	je     f01058f8 <strcmp+0x1c>
f01058f4:	3a 02                	cmp    (%edx),%al
f01058f6:	74 ef                	je     f01058e7 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01058f8:	0f b6 c0             	movzbl %al,%eax
f01058fb:	0f b6 12             	movzbl (%edx),%edx
f01058fe:	29 d0                	sub    %edx,%eax
}
f0105900:	5d                   	pop    %ebp
f0105901:	c3                   	ret    

f0105902 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0105902:	55                   	push   %ebp
f0105903:	89 e5                	mov    %esp,%ebp
f0105905:	53                   	push   %ebx
f0105906:	8b 45 08             	mov    0x8(%ebp),%eax
f0105909:	8b 55 0c             	mov    0xc(%ebp),%edx
f010590c:	89 c3                	mov    %eax,%ebx
f010590e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0105911:	eb 06                	jmp    f0105919 <strncmp+0x17>
		n--, p++, q++;
f0105913:	83 c0 01             	add    $0x1,%eax
f0105916:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0105919:	39 d8                	cmp    %ebx,%eax
f010591b:	74 15                	je     f0105932 <strncmp+0x30>
f010591d:	0f b6 08             	movzbl (%eax),%ecx
f0105920:	84 c9                	test   %cl,%cl
f0105922:	74 04                	je     f0105928 <strncmp+0x26>
f0105924:	3a 0a                	cmp    (%edx),%cl
f0105926:	74 eb                	je     f0105913 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105928:	0f b6 00             	movzbl (%eax),%eax
f010592b:	0f b6 12             	movzbl (%edx),%edx
f010592e:	29 d0                	sub    %edx,%eax
f0105930:	eb 05                	jmp    f0105937 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0105932:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0105937:	5b                   	pop    %ebx
f0105938:	5d                   	pop    %ebp
f0105939:	c3                   	ret    

f010593a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010593a:	55                   	push   %ebp
f010593b:	89 e5                	mov    %esp,%ebp
f010593d:	8b 45 08             	mov    0x8(%ebp),%eax
f0105940:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105944:	eb 07                	jmp    f010594d <strchr+0x13>
		if (*s == c)
f0105946:	38 ca                	cmp    %cl,%dl
f0105948:	74 0f                	je     f0105959 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010594a:	83 c0 01             	add    $0x1,%eax
f010594d:	0f b6 10             	movzbl (%eax),%edx
f0105950:	84 d2                	test   %dl,%dl
f0105952:	75 f2                	jne    f0105946 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0105954:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105959:	5d                   	pop    %ebp
f010595a:	c3                   	ret    

f010595b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010595b:	55                   	push   %ebp
f010595c:	89 e5                	mov    %esp,%ebp
f010595e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105961:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105965:	eb 07                	jmp    f010596e <strfind+0x13>
		if (*s == c)
f0105967:	38 ca                	cmp    %cl,%dl
f0105969:	74 0a                	je     f0105975 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010596b:	83 c0 01             	add    $0x1,%eax
f010596e:	0f b6 10             	movzbl (%eax),%edx
f0105971:	84 d2                	test   %dl,%dl
f0105973:	75 f2                	jne    f0105967 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0105975:	5d                   	pop    %ebp
f0105976:	c3                   	ret    

f0105977 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105977:	55                   	push   %ebp
f0105978:	89 e5                	mov    %esp,%ebp
f010597a:	57                   	push   %edi
f010597b:	56                   	push   %esi
f010597c:	53                   	push   %ebx
f010597d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0105980:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0105983:	85 c9                	test   %ecx,%ecx
f0105985:	74 36                	je     f01059bd <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0105987:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010598d:	75 28                	jne    f01059b7 <memset+0x40>
f010598f:	f6 c1 03             	test   $0x3,%cl
f0105992:	75 23                	jne    f01059b7 <memset+0x40>
		c &= 0xFF;
f0105994:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0105998:	89 d3                	mov    %edx,%ebx
f010599a:	c1 e3 08             	shl    $0x8,%ebx
f010599d:	89 d6                	mov    %edx,%esi
f010599f:	c1 e6 18             	shl    $0x18,%esi
f01059a2:	89 d0                	mov    %edx,%eax
f01059a4:	c1 e0 10             	shl    $0x10,%eax
f01059a7:	09 f0                	or     %esi,%eax
f01059a9:	09 c2                	or     %eax,%edx
f01059ab:	89 d0                	mov    %edx,%eax
f01059ad:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01059af:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01059b2:	fc                   	cld    
f01059b3:	f3 ab                	rep stos %eax,%es:(%edi)
f01059b5:	eb 06                	jmp    f01059bd <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01059b7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01059ba:	fc                   	cld    
f01059bb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01059bd:	89 f8                	mov    %edi,%eax
f01059bf:	5b                   	pop    %ebx
f01059c0:	5e                   	pop    %esi
f01059c1:	5f                   	pop    %edi
f01059c2:	5d                   	pop    %ebp
f01059c3:	c3                   	ret    

f01059c4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01059c4:	55                   	push   %ebp
f01059c5:	89 e5                	mov    %esp,%ebp
f01059c7:	57                   	push   %edi
f01059c8:	56                   	push   %esi
f01059c9:	8b 45 08             	mov    0x8(%ebp),%eax
f01059cc:	8b 75 0c             	mov    0xc(%ebp),%esi
f01059cf:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01059d2:	39 c6                	cmp    %eax,%esi
f01059d4:	73 35                	jae    f0105a0b <memmove+0x47>
f01059d6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01059d9:	39 d0                	cmp    %edx,%eax
f01059db:	73 2e                	jae    f0105a0b <memmove+0x47>
		s += n;
		d += n;
f01059dd:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01059e0:	89 d6                	mov    %edx,%esi
f01059e2:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01059e4:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01059ea:	75 13                	jne    f01059ff <memmove+0x3b>
f01059ec:	f6 c1 03             	test   $0x3,%cl
f01059ef:	75 0e                	jne    f01059ff <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01059f1:	83 ef 04             	sub    $0x4,%edi
f01059f4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01059f7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01059fa:	fd                   	std    
f01059fb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01059fd:	eb 09                	jmp    f0105a08 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01059ff:	83 ef 01             	sub    $0x1,%edi
f0105a02:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0105a05:	fd                   	std    
f0105a06:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105a08:	fc                   	cld    
f0105a09:	eb 1d                	jmp    f0105a28 <memmove+0x64>
f0105a0b:	89 f2                	mov    %esi,%edx
f0105a0d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105a0f:	f6 c2 03             	test   $0x3,%dl
f0105a12:	75 0f                	jne    f0105a23 <memmove+0x5f>
f0105a14:	f6 c1 03             	test   $0x3,%cl
f0105a17:	75 0a                	jne    f0105a23 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0105a19:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0105a1c:	89 c7                	mov    %eax,%edi
f0105a1e:	fc                   	cld    
f0105a1f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105a21:	eb 05                	jmp    f0105a28 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0105a23:	89 c7                	mov    %eax,%edi
f0105a25:	fc                   	cld    
f0105a26:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105a28:	5e                   	pop    %esi
f0105a29:	5f                   	pop    %edi
f0105a2a:	5d                   	pop    %ebp
f0105a2b:	c3                   	ret    

f0105a2c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0105a2c:	55                   	push   %ebp
f0105a2d:	89 e5                	mov    %esp,%ebp
f0105a2f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0105a32:	8b 45 10             	mov    0x10(%ebp),%eax
f0105a35:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105a39:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105a3c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105a40:	8b 45 08             	mov    0x8(%ebp),%eax
f0105a43:	89 04 24             	mov    %eax,(%esp)
f0105a46:	e8 79 ff ff ff       	call   f01059c4 <memmove>
}
f0105a4b:	c9                   	leave  
f0105a4c:	c3                   	ret    

f0105a4d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0105a4d:	55                   	push   %ebp
f0105a4e:	89 e5                	mov    %esp,%ebp
f0105a50:	56                   	push   %esi
f0105a51:	53                   	push   %ebx
f0105a52:	8b 55 08             	mov    0x8(%ebp),%edx
f0105a55:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105a58:	89 d6                	mov    %edx,%esi
f0105a5a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105a5d:	eb 1a                	jmp    f0105a79 <memcmp+0x2c>
		if (*s1 != *s2)
f0105a5f:	0f b6 02             	movzbl (%edx),%eax
f0105a62:	0f b6 19             	movzbl (%ecx),%ebx
f0105a65:	38 d8                	cmp    %bl,%al
f0105a67:	74 0a                	je     f0105a73 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0105a69:	0f b6 c0             	movzbl %al,%eax
f0105a6c:	0f b6 db             	movzbl %bl,%ebx
f0105a6f:	29 d8                	sub    %ebx,%eax
f0105a71:	eb 0f                	jmp    f0105a82 <memcmp+0x35>
		s1++, s2++;
f0105a73:	83 c2 01             	add    $0x1,%edx
f0105a76:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105a79:	39 f2                	cmp    %esi,%edx
f0105a7b:	75 e2                	jne    f0105a5f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0105a7d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105a82:	5b                   	pop    %ebx
f0105a83:	5e                   	pop    %esi
f0105a84:	5d                   	pop    %ebp
f0105a85:	c3                   	ret    

f0105a86 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105a86:	55                   	push   %ebp
f0105a87:	89 e5                	mov    %esp,%ebp
f0105a89:	8b 45 08             	mov    0x8(%ebp),%eax
f0105a8c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0105a8f:	89 c2                	mov    %eax,%edx
f0105a91:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0105a94:	eb 07                	jmp    f0105a9d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0105a96:	38 08                	cmp    %cl,(%eax)
f0105a98:	74 07                	je     f0105aa1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0105a9a:	83 c0 01             	add    $0x1,%eax
f0105a9d:	39 d0                	cmp    %edx,%eax
f0105a9f:	72 f5                	jb     f0105a96 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0105aa1:	5d                   	pop    %ebp
f0105aa2:	c3                   	ret    

f0105aa3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105aa3:	55                   	push   %ebp
f0105aa4:	89 e5                	mov    %esp,%ebp
f0105aa6:	57                   	push   %edi
f0105aa7:	56                   	push   %esi
f0105aa8:	53                   	push   %ebx
f0105aa9:	8b 55 08             	mov    0x8(%ebp),%edx
f0105aac:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105aaf:	eb 03                	jmp    f0105ab4 <strtol+0x11>
		s++;
f0105ab1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105ab4:	0f b6 0a             	movzbl (%edx),%ecx
f0105ab7:	80 f9 09             	cmp    $0x9,%cl
f0105aba:	74 f5                	je     f0105ab1 <strtol+0xe>
f0105abc:	80 f9 20             	cmp    $0x20,%cl
f0105abf:	74 f0                	je     f0105ab1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0105ac1:	80 f9 2b             	cmp    $0x2b,%cl
f0105ac4:	75 0a                	jne    f0105ad0 <strtol+0x2d>
		s++;
f0105ac6:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0105ac9:	bf 00 00 00 00       	mov    $0x0,%edi
f0105ace:	eb 11                	jmp    f0105ae1 <strtol+0x3e>
f0105ad0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0105ad5:	80 f9 2d             	cmp    $0x2d,%cl
f0105ad8:	75 07                	jne    f0105ae1 <strtol+0x3e>
		s++, neg = 1;
f0105ada:	8d 52 01             	lea    0x1(%edx),%edx
f0105add:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105ae1:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0105ae6:	75 15                	jne    f0105afd <strtol+0x5a>
f0105ae8:	80 3a 30             	cmpb   $0x30,(%edx)
f0105aeb:	75 10                	jne    f0105afd <strtol+0x5a>
f0105aed:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0105af1:	75 0a                	jne    f0105afd <strtol+0x5a>
		s += 2, base = 16;
f0105af3:	83 c2 02             	add    $0x2,%edx
f0105af6:	b8 10 00 00 00       	mov    $0x10,%eax
f0105afb:	eb 10                	jmp    f0105b0d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f0105afd:	85 c0                	test   %eax,%eax
f0105aff:	75 0c                	jne    f0105b0d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105b01:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105b03:	80 3a 30             	cmpb   $0x30,(%edx)
f0105b06:	75 05                	jne    f0105b0d <strtol+0x6a>
		s++, base = 8;
f0105b08:	83 c2 01             	add    $0x1,%edx
f0105b0b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f0105b0d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0105b12:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0105b15:	0f b6 0a             	movzbl (%edx),%ecx
f0105b18:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0105b1b:	89 f0                	mov    %esi,%eax
f0105b1d:	3c 09                	cmp    $0x9,%al
f0105b1f:	77 08                	ja     f0105b29 <strtol+0x86>
			dig = *s - '0';
f0105b21:	0f be c9             	movsbl %cl,%ecx
f0105b24:	83 e9 30             	sub    $0x30,%ecx
f0105b27:	eb 20                	jmp    f0105b49 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0105b29:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0105b2c:	89 f0                	mov    %esi,%eax
f0105b2e:	3c 19                	cmp    $0x19,%al
f0105b30:	77 08                	ja     f0105b3a <strtol+0x97>
			dig = *s - 'a' + 10;
f0105b32:	0f be c9             	movsbl %cl,%ecx
f0105b35:	83 e9 57             	sub    $0x57,%ecx
f0105b38:	eb 0f                	jmp    f0105b49 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0105b3a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0105b3d:	89 f0                	mov    %esi,%eax
f0105b3f:	3c 19                	cmp    $0x19,%al
f0105b41:	77 16                	ja     f0105b59 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0105b43:	0f be c9             	movsbl %cl,%ecx
f0105b46:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0105b49:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0105b4c:	7d 0f                	jge    f0105b5d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f0105b4e:	83 c2 01             	add    $0x1,%edx
f0105b51:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0105b55:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0105b57:	eb bc                	jmp    f0105b15 <strtol+0x72>
f0105b59:	89 d8                	mov    %ebx,%eax
f0105b5b:	eb 02                	jmp    f0105b5f <strtol+0xbc>
f0105b5d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0105b5f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105b63:	74 05                	je     f0105b6a <strtol+0xc7>
		*endptr = (char *) s;
f0105b65:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105b68:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0105b6a:	f7 d8                	neg    %eax
f0105b6c:	85 ff                	test   %edi,%edi
f0105b6e:	0f 44 c3             	cmove  %ebx,%eax
}
f0105b71:	5b                   	pop    %ebx
f0105b72:	5e                   	pop    %esi
f0105b73:	5f                   	pop    %edi
f0105b74:	5d                   	pop    %ebp
f0105b75:	c3                   	ret    
f0105b76:	66 90                	xchg   %ax,%ax

f0105b78 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0105b78:	fa                   	cli    

	xorw    %ax, %ax
f0105b79:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f0105b7b:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105b7d:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105b7f:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0105b81:	0f 01 16             	lgdtl  (%esi)
f0105b84:	74 70                	je     f0105bf6 <mpentry_end+0x4>
	movl    %cr0, %eax
f0105b86:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0105b89:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0105b8d:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0105b90:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f0105b96:	08 00                	or     %al,(%eax)

f0105b98 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0105b98:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0105b9c:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105b9e:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105ba0:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0105ba2:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f0105ba6:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0105ba8:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f0105baa:	b8 00 e0 11 00       	mov    $0x11e000,%eax
	movl    %eax, %cr3
f0105baf:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0105bb2:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0105bb5:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f0105bba:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0105bbd:	8b 25 84 be 22 f0    	mov    0xf022be84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0105bc3:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0105bc8:	b8 b4 01 10 f0       	mov    $0xf01001b4,%eax
	call    *%eax
f0105bcd:	ff d0                	call   *%eax

f0105bcf <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0105bcf:	eb fe                	jmp    f0105bcf <spin>
f0105bd1:	8d 76 00             	lea    0x0(%esi),%esi

f0105bd4 <gdt>:
	...
f0105bdc:	ff                   	(bad)  
f0105bdd:	ff 00                	incl   (%eax)
f0105bdf:	00 00                	add    %al,(%eax)
f0105be1:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0105be8:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

f0105bec <gdtdesc>:
f0105bec:	17                   	pop    %ss
f0105bed:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0105bf2 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0105bf2:	90                   	nop
f0105bf3:	66 90                	xchg   %ax,%ax
f0105bf5:	66 90                	xchg   %ax,%ax
f0105bf7:	66 90                	xchg   %ax,%ax
f0105bf9:	66 90                	xchg   %ax,%ax
f0105bfb:	66 90                	xchg   %ax,%ax
f0105bfd:	66 90                	xchg   %ax,%ax
f0105bff:	90                   	nop

f0105c00 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0105c00:	55                   	push   %ebp
f0105c01:	89 e5                	mov    %esp,%ebp
f0105c03:	56                   	push   %esi
f0105c04:	53                   	push   %ebx
f0105c05:	83 ec 10             	sub    $0x10,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105c08:	8b 0d 88 be 22 f0    	mov    0xf022be88,%ecx
f0105c0e:	89 c3                	mov    %eax,%ebx
f0105c10:	c1 eb 0c             	shr    $0xc,%ebx
f0105c13:	39 cb                	cmp    %ecx,%ebx
f0105c15:	72 20                	jb     f0105c37 <mpsearch1+0x37>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105c17:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105c1b:	c7 44 24 08 e4 66 10 	movl   $0xf01066e4,0x8(%esp)
f0105c22:	f0 
f0105c23:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f0105c2a:	00 
f0105c2b:	c7 04 24 65 83 10 f0 	movl   $0xf0108365,(%esp)
f0105c32:	e8 09 a4 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105c37:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0105c3d:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105c3f:	89 c2                	mov    %eax,%edx
f0105c41:	c1 ea 0c             	shr    $0xc,%edx
f0105c44:	39 d1                	cmp    %edx,%ecx
f0105c46:	77 20                	ja     f0105c68 <mpsearch1+0x68>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105c48:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105c4c:	c7 44 24 08 e4 66 10 	movl   $0xf01066e4,0x8(%esp)
f0105c53:	f0 
f0105c54:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f0105c5b:	00 
f0105c5c:	c7 04 24 65 83 10 f0 	movl   $0xf0108365,(%esp)
f0105c63:	e8 d8 a3 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105c68:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f0105c6e:	eb 36                	jmp    f0105ca6 <mpsearch1+0xa6>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105c70:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f0105c77:	00 
f0105c78:	c7 44 24 04 75 83 10 	movl   $0xf0108375,0x4(%esp)
f0105c7f:	f0 
f0105c80:	89 1c 24             	mov    %ebx,(%esp)
f0105c83:	e8 c5 fd ff ff       	call   f0105a4d <memcmp>
f0105c88:	85 c0                	test   %eax,%eax
f0105c8a:	75 17                	jne    f0105ca3 <mpsearch1+0xa3>
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105c8c:	ba 00 00 00 00       	mov    $0x0,%edx
		sum += ((uint8_t *)addr)[i];
f0105c91:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0105c95:	01 c8                	add    %ecx,%eax
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105c97:	83 c2 01             	add    $0x1,%edx
f0105c9a:	83 fa 10             	cmp    $0x10,%edx
f0105c9d:	75 f2                	jne    f0105c91 <mpsearch1+0x91>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105c9f:	84 c0                	test   %al,%al
f0105ca1:	74 0e                	je     f0105cb1 <mpsearch1+0xb1>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0105ca3:	83 c3 10             	add    $0x10,%ebx
f0105ca6:	39 f3                	cmp    %esi,%ebx
f0105ca8:	72 c6                	jb     f0105c70 <mpsearch1+0x70>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f0105caa:	b8 00 00 00 00       	mov    $0x0,%eax
f0105caf:	eb 02                	jmp    f0105cb3 <mpsearch1+0xb3>
f0105cb1:	89 d8                	mov    %ebx,%eax
}
f0105cb3:	83 c4 10             	add    $0x10,%esp
f0105cb6:	5b                   	pop    %ebx
f0105cb7:	5e                   	pop    %esi
f0105cb8:	5d                   	pop    %ebp
f0105cb9:	c3                   	ret    

f0105cba <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0105cba:	55                   	push   %ebp
f0105cbb:	89 e5                	mov    %esp,%ebp
f0105cbd:	57                   	push   %edi
f0105cbe:	56                   	push   %esi
f0105cbf:	53                   	push   %ebx
f0105cc0:	83 ec 2c             	sub    $0x2c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105cc3:	c7 05 c0 c3 22 f0 20 	movl   $0xf022c020,0xf022c3c0
f0105cca:	c0 22 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105ccd:	83 3d 88 be 22 f0 00 	cmpl   $0x0,0xf022be88
f0105cd4:	75 24                	jne    f0105cfa <mp_init+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105cd6:	c7 44 24 0c 00 04 00 	movl   $0x400,0xc(%esp)
f0105cdd:	00 
f0105cde:	c7 44 24 08 e4 66 10 	movl   $0xf01066e4,0x8(%esp)
f0105ce5:	f0 
f0105ce6:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
f0105ced:	00 
f0105cee:	c7 04 24 65 83 10 f0 	movl   $0xf0108365,(%esp)
f0105cf5:	e8 46 a3 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0105cfa:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105d01:	85 c0                	test   %eax,%eax
f0105d03:	74 16                	je     f0105d1b <mp_init+0x61>
		p <<= 4;	// Translate from segment to PA
f0105d05:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f0105d08:	ba 00 04 00 00       	mov    $0x400,%edx
f0105d0d:	e8 ee fe ff ff       	call   f0105c00 <mpsearch1>
f0105d12:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105d15:	85 c0                	test   %eax,%eax
f0105d17:	75 3c                	jne    f0105d55 <mp_init+0x9b>
f0105d19:	eb 20                	jmp    f0105d3b <mp_init+0x81>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
f0105d1b:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0105d22:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f0105d25:	2d 00 04 00 00       	sub    $0x400,%eax
f0105d2a:	ba 00 04 00 00       	mov    $0x400,%edx
f0105d2f:	e8 cc fe ff ff       	call   f0105c00 <mpsearch1>
f0105d34:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105d37:	85 c0                	test   %eax,%eax
f0105d39:	75 1a                	jne    f0105d55 <mp_init+0x9b>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f0105d3b:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105d40:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0105d45:	e8 b6 fe ff ff       	call   f0105c00 <mpsearch1>
f0105d4a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f0105d4d:	85 c0                	test   %eax,%eax
f0105d4f:	0f 84 54 02 00 00    	je     f0105fa9 <mp_init+0x2ef>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f0105d55:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105d58:	8b 70 04             	mov    0x4(%eax),%esi
f0105d5b:	85 f6                	test   %esi,%esi
f0105d5d:	74 06                	je     f0105d65 <mp_init+0xab>
f0105d5f:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f0105d63:	74 11                	je     f0105d76 <mp_init+0xbc>
		cprintf("SMP: Default configurations not implemented\n");
f0105d65:	c7 04 24 d8 81 10 f0 	movl   $0xf01081d8,(%esp)
f0105d6c:	e8 4b e3 ff ff       	call   f01040bc <cprintf>
f0105d71:	e9 33 02 00 00       	jmp    f0105fa9 <mp_init+0x2ef>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105d76:	89 f0                	mov    %esi,%eax
f0105d78:	c1 e8 0c             	shr    $0xc,%eax
f0105d7b:	3b 05 88 be 22 f0    	cmp    0xf022be88,%eax
f0105d81:	72 20                	jb     f0105da3 <mp_init+0xe9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105d83:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0105d87:	c7 44 24 08 e4 66 10 	movl   $0xf01066e4,0x8(%esp)
f0105d8e:	f0 
f0105d8f:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
f0105d96:	00 
f0105d97:	c7 04 24 65 83 10 f0 	movl   $0xf0108365,(%esp)
f0105d9e:	e8 9d a2 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105da3:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f0105da9:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f0105db0:	00 
f0105db1:	c7 44 24 04 7a 83 10 	movl   $0xf010837a,0x4(%esp)
f0105db8:	f0 
f0105db9:	89 1c 24             	mov    %ebx,(%esp)
f0105dbc:	e8 8c fc ff ff       	call   f0105a4d <memcmp>
f0105dc1:	85 c0                	test   %eax,%eax
f0105dc3:	74 11                	je     f0105dd6 <mp_init+0x11c>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0105dc5:	c7 04 24 08 82 10 f0 	movl   $0xf0108208,(%esp)
f0105dcc:	e8 eb e2 ff ff       	call   f01040bc <cprintf>
f0105dd1:	e9 d3 01 00 00       	jmp    f0105fa9 <mp_init+0x2ef>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105dd6:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f0105dda:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f0105dde:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105de1:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105de6:	b8 00 00 00 00       	mov    $0x0,%eax
f0105deb:	eb 0d                	jmp    f0105dfa <mp_init+0x140>
		sum += ((uint8_t *)addr)[i];
f0105ded:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0105df4:	f0 
f0105df5:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105df7:	83 c0 01             	add    $0x1,%eax
f0105dfa:	39 c7                	cmp    %eax,%edi
f0105dfc:	7f ef                	jg     f0105ded <mp_init+0x133>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105dfe:	84 d2                	test   %dl,%dl
f0105e00:	74 11                	je     f0105e13 <mp_init+0x159>
		cprintf("SMP: Bad MP configuration checksum\n");
f0105e02:	c7 04 24 3c 82 10 f0 	movl   $0xf010823c,(%esp)
f0105e09:	e8 ae e2 ff ff       	call   f01040bc <cprintf>
f0105e0e:	e9 96 01 00 00       	jmp    f0105fa9 <mp_init+0x2ef>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0105e13:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f0105e17:	3c 04                	cmp    $0x4,%al
f0105e19:	74 1f                	je     f0105e3a <mp_init+0x180>
f0105e1b:	3c 01                	cmp    $0x1,%al
f0105e1d:	8d 76 00             	lea    0x0(%esi),%esi
f0105e20:	74 18                	je     f0105e3a <mp_init+0x180>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0105e22:	0f b6 c0             	movzbl %al,%eax
f0105e25:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105e29:	c7 04 24 60 82 10 f0 	movl   $0xf0108260,(%esp)
f0105e30:	e8 87 e2 ff ff       	call   f01040bc <cprintf>
f0105e35:	e9 6f 01 00 00       	jmp    f0105fa9 <mp_init+0x2ef>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105e3a:	0f b7 73 28          	movzwl 0x28(%ebx),%esi
f0105e3e:	0f b7 7d e2          	movzwl -0x1e(%ebp),%edi
f0105e42:	01 df                	add    %ebx,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105e44:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105e49:	b8 00 00 00 00       	mov    $0x0,%eax
f0105e4e:	eb 09                	jmp    f0105e59 <mp_init+0x19f>
		sum += ((uint8_t *)addr)[i];
f0105e50:	0f b6 0c 07          	movzbl (%edi,%eax,1),%ecx
f0105e54:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105e56:	83 c0 01             	add    $0x1,%eax
f0105e59:	39 c6                	cmp    %eax,%esi
f0105e5b:	7f f3                	jg     f0105e50 <mp_init+0x196>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105e5d:	02 53 2a             	add    0x2a(%ebx),%dl
f0105e60:	84 d2                	test   %dl,%dl
f0105e62:	74 11                	je     f0105e75 <mp_init+0x1bb>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0105e64:	c7 04 24 80 82 10 f0 	movl   $0xf0108280,(%esp)
f0105e6b:	e8 4c e2 ff ff       	call   f01040bc <cprintf>
f0105e70:	e9 34 01 00 00       	jmp    f0105fa9 <mp_init+0x2ef>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f0105e75:	85 db                	test   %ebx,%ebx
f0105e77:	0f 84 2c 01 00 00    	je     f0105fa9 <mp_init+0x2ef>
		return;
	ismp = 1;
f0105e7d:	c7 05 00 c0 22 f0 01 	movl   $0x1,0xf022c000
f0105e84:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0105e87:	8b 43 24             	mov    0x24(%ebx),%eax
f0105e8a:	a3 00 d0 26 f0       	mov    %eax,0xf026d000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105e8f:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f0105e92:	be 00 00 00 00       	mov    $0x0,%esi
f0105e97:	e9 86 00 00 00       	jmp    f0105f22 <mp_init+0x268>
		switch (*p) {
f0105e9c:	0f b6 07             	movzbl (%edi),%eax
f0105e9f:	84 c0                	test   %al,%al
f0105ea1:	74 06                	je     f0105ea9 <mp_init+0x1ef>
f0105ea3:	3c 04                	cmp    $0x4,%al
f0105ea5:	77 57                	ja     f0105efe <mp_init+0x244>
f0105ea7:	eb 50                	jmp    f0105ef9 <mp_init+0x23f>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0105ea9:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0105ead:	8d 76 00             	lea    0x0(%esi),%esi
f0105eb0:	74 11                	je     f0105ec3 <mp_init+0x209>
				bootcpu = &cpus[ncpu];
f0105eb2:	6b 05 c4 c3 22 f0 74 	imul   $0x74,0xf022c3c4,%eax
f0105eb9:	05 20 c0 22 f0       	add    $0xf022c020,%eax
f0105ebe:	a3 c0 c3 22 f0       	mov    %eax,0xf022c3c0
			if (ncpu < NCPU) {
f0105ec3:	a1 c4 c3 22 f0       	mov    0xf022c3c4,%eax
f0105ec8:	83 f8 07             	cmp    $0x7,%eax
f0105ecb:	7f 13                	jg     f0105ee0 <mp_init+0x226>
				cpus[ncpu].cpu_id = ncpu;
f0105ecd:	6b d0 74             	imul   $0x74,%eax,%edx
f0105ed0:	88 82 20 c0 22 f0    	mov    %al,-0xfdd3fe0(%edx)
				ncpu++;
f0105ed6:	83 c0 01             	add    $0x1,%eax
f0105ed9:	a3 c4 c3 22 f0       	mov    %eax,0xf022c3c4
f0105ede:	eb 14                	jmp    f0105ef4 <mp_init+0x23a>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0105ee0:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f0105ee4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105ee8:	c7 04 24 b0 82 10 f0 	movl   $0xf01082b0,(%esp)
f0105eef:	e8 c8 e1 ff ff       	call   f01040bc <cprintf>
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0105ef4:	83 c7 14             	add    $0x14,%edi
			continue;
f0105ef7:	eb 26                	jmp    f0105f1f <mp_init+0x265>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0105ef9:	83 c7 08             	add    $0x8,%edi
			continue;
f0105efc:	eb 21                	jmp    f0105f1f <mp_init+0x265>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0105efe:	0f b6 c0             	movzbl %al,%eax
f0105f01:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105f05:	c7 04 24 d8 82 10 f0 	movl   $0xf01082d8,(%esp)
f0105f0c:	e8 ab e1 ff ff       	call   f01040bc <cprintf>
			ismp = 0;
f0105f11:	c7 05 00 c0 22 f0 00 	movl   $0x0,0xf022c000
f0105f18:	00 00 00 
			i = conf->entry;
f0105f1b:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105f1f:	83 c6 01             	add    $0x1,%esi
f0105f22:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f0105f26:	39 c6                	cmp    %eax,%esi
f0105f28:	0f 82 6e ff ff ff    	jb     f0105e9c <mp_init+0x1e2>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0105f2e:	a1 c0 c3 22 f0       	mov    0xf022c3c0,%eax
f0105f33:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f0105f3a:	83 3d 00 c0 22 f0 00 	cmpl   $0x0,0xf022c000
f0105f41:	75 22                	jne    f0105f65 <mp_init+0x2ab>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0105f43:	c7 05 c4 c3 22 f0 01 	movl   $0x1,0xf022c3c4
f0105f4a:	00 00 00 
		lapicaddr = 0;
f0105f4d:	c7 05 00 d0 26 f0 00 	movl   $0x0,0xf026d000
f0105f54:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0105f57:	c7 04 24 f8 82 10 f0 	movl   $0xf01082f8,(%esp)
f0105f5e:	e8 59 e1 ff ff       	call   f01040bc <cprintf>
		return;
f0105f63:	eb 44                	jmp    f0105fa9 <mp_init+0x2ef>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0105f65:	8b 15 c4 c3 22 f0    	mov    0xf022c3c4,%edx
f0105f6b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0105f6f:	0f b6 00             	movzbl (%eax),%eax
f0105f72:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105f76:	c7 04 24 7f 83 10 f0 	movl   $0xf010837f,(%esp)
f0105f7d:	e8 3a e1 ff ff       	call   f01040bc <cprintf>

	if (mp->imcrp) {
f0105f82:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105f85:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0105f89:	74 1e                	je     f0105fa9 <mp_init+0x2ef>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0105f8b:	c7 04 24 24 83 10 f0 	movl   $0xf0108324,(%esp)
f0105f92:	e8 25 e1 ff ff       	call   f01040bc <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105f97:	ba 22 00 00 00       	mov    $0x22,%edx
f0105f9c:	b8 70 00 00 00       	mov    $0x70,%eax
f0105fa1:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0105fa2:	b2 23                	mov    $0x23,%dl
f0105fa4:	ec                   	in     (%dx),%al
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f0105fa5:	83 c8 01             	or     $0x1,%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105fa8:	ee                   	out    %al,(%dx)
	}
}
f0105fa9:	83 c4 2c             	add    $0x2c,%esp
f0105fac:	5b                   	pop    %ebx
f0105fad:	5e                   	pop    %esi
f0105fae:	5f                   	pop    %edi
f0105faf:	5d                   	pop    %ebp
f0105fb0:	c3                   	ret    

f0105fb1 <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f0105fb1:	55                   	push   %ebp
f0105fb2:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f0105fb4:	8b 0d 04 d0 26 f0    	mov    0xf026d004,%ecx
f0105fba:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0105fbd:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0105fbf:	a1 04 d0 26 f0       	mov    0xf026d004,%eax
f0105fc4:	8b 40 20             	mov    0x20(%eax),%eax
}
f0105fc7:	5d                   	pop    %ebp
f0105fc8:	c3                   	ret    

f0105fc9 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f0105fc9:	55                   	push   %ebp
f0105fca:	89 e5                	mov    %esp,%ebp
	if (lapic)
f0105fcc:	a1 04 d0 26 f0       	mov    0xf026d004,%eax
f0105fd1:	85 c0                	test   %eax,%eax
f0105fd3:	74 08                	je     f0105fdd <cpunum+0x14>
		return lapic[ID] >> 24;
f0105fd5:	8b 40 20             	mov    0x20(%eax),%eax
f0105fd8:	c1 e8 18             	shr    $0x18,%eax
f0105fdb:	eb 05                	jmp    f0105fe2 <cpunum+0x19>
	return 0;
f0105fdd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105fe2:	5d                   	pop    %ebp
f0105fe3:	c3                   	ret    

f0105fe4 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0105fe4:	a1 00 d0 26 f0       	mov    0xf026d000,%eax
f0105fe9:	85 c0                	test   %eax,%eax
f0105feb:	0f 84 23 01 00 00    	je     f0106114 <lapic_init+0x130>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f0105ff1:	55                   	push   %ebp
f0105ff2:	89 e5                	mov    %esp,%ebp
f0105ff4:	83 ec 18             	sub    $0x18,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105ff7:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0105ffe:	00 
f0105fff:	89 04 24             	mov    %eax,(%esp)
f0106002:	e8 36 b5 ff ff       	call   f010153d <mmio_map_region>
f0106007:	a3 04 d0 26 f0       	mov    %eax,0xf026d004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f010600c:	ba 27 01 00 00       	mov    $0x127,%edx
f0106011:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0106016:	e8 96 ff ff ff       	call   f0105fb1 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f010601b:	ba 0b 00 00 00       	mov    $0xb,%edx
f0106020:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0106025:	e8 87 ff ff ff       	call   f0105fb1 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f010602a:	ba 20 00 02 00       	mov    $0x20020,%edx
f010602f:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0106034:	e8 78 ff ff ff       	call   f0105fb1 <lapicw>
	lapicw(TICR, 10000000); 
f0106039:	ba 80 96 98 00       	mov    $0x989680,%edx
f010603e:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0106043:	e8 69 ff ff ff       	call   f0105fb1 <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0106048:	e8 7c ff ff ff       	call   f0105fc9 <cpunum>
f010604d:	6b c0 74             	imul   $0x74,%eax,%eax
f0106050:	05 20 c0 22 f0       	add    $0xf022c020,%eax
f0106055:	39 05 c0 c3 22 f0    	cmp    %eax,0xf022c3c0
f010605b:	74 0f                	je     f010606c <lapic_init+0x88>
		lapicw(LINT0, MASKED);
f010605d:	ba 00 00 01 00       	mov    $0x10000,%edx
f0106062:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0106067:	e8 45 ff ff ff       	call   f0105fb1 <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f010606c:	ba 00 00 01 00       	mov    $0x10000,%edx
f0106071:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0106076:	e8 36 ff ff ff       	call   f0105fb1 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f010607b:	a1 04 d0 26 f0       	mov    0xf026d004,%eax
f0106080:	8b 40 30             	mov    0x30(%eax),%eax
f0106083:	c1 e8 10             	shr    $0x10,%eax
f0106086:	3c 03                	cmp    $0x3,%al
f0106088:	76 0f                	jbe    f0106099 <lapic_init+0xb5>
		lapicw(PCINT, MASKED);
f010608a:	ba 00 00 01 00       	mov    $0x10000,%edx
f010608f:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0106094:	e8 18 ff ff ff       	call   f0105fb1 <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0106099:	ba 33 00 00 00       	mov    $0x33,%edx
f010609e:	b8 dc 00 00 00       	mov    $0xdc,%eax
f01060a3:	e8 09 ff ff ff       	call   f0105fb1 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f01060a8:	ba 00 00 00 00       	mov    $0x0,%edx
f01060ad:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01060b2:	e8 fa fe ff ff       	call   f0105fb1 <lapicw>
	lapicw(ESR, 0);
f01060b7:	ba 00 00 00 00       	mov    $0x0,%edx
f01060bc:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01060c1:	e8 eb fe ff ff       	call   f0105fb1 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f01060c6:	ba 00 00 00 00       	mov    $0x0,%edx
f01060cb:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01060d0:	e8 dc fe ff ff       	call   f0105fb1 <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f01060d5:	ba 00 00 00 00       	mov    $0x0,%edx
f01060da:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01060df:	e8 cd fe ff ff       	call   f0105fb1 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f01060e4:	ba 00 85 08 00       	mov    $0x88500,%edx
f01060e9:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01060ee:	e8 be fe ff ff       	call   f0105fb1 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f01060f3:	8b 15 04 d0 26 f0    	mov    0xf026d004,%edx
f01060f9:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f01060ff:	f6 c4 10             	test   $0x10,%ah
f0106102:	75 f5                	jne    f01060f9 <lapic_init+0x115>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0106104:	ba 00 00 00 00       	mov    $0x0,%edx
f0106109:	b8 20 00 00 00       	mov    $0x20,%eax
f010610e:	e8 9e fe ff ff       	call   f0105fb1 <lapicw>
}
f0106113:	c9                   	leave  
f0106114:	f3 c3                	repz ret 

f0106116 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0106116:	83 3d 04 d0 26 f0 00 	cmpl   $0x0,0xf026d004
f010611d:	74 13                	je     f0106132 <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f010611f:	55                   	push   %ebp
f0106120:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0106122:	ba 00 00 00 00       	mov    $0x0,%edx
f0106127:	b8 2c 00 00 00       	mov    $0x2c,%eax
f010612c:	e8 80 fe ff ff       	call   f0105fb1 <lapicw>
}
f0106131:	5d                   	pop    %ebp
f0106132:	f3 c3                	repz ret 

f0106134 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0106134:	55                   	push   %ebp
f0106135:	89 e5                	mov    %esp,%ebp
f0106137:	56                   	push   %esi
f0106138:	53                   	push   %ebx
f0106139:	83 ec 10             	sub    $0x10,%esp
f010613c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010613f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0106142:	ba 70 00 00 00       	mov    $0x70,%edx
f0106147:	b8 0f 00 00 00       	mov    $0xf,%eax
f010614c:	ee                   	out    %al,(%dx)
f010614d:	b2 71                	mov    $0x71,%dl
f010614f:	b8 0a 00 00 00       	mov    $0xa,%eax
f0106154:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0106155:	83 3d 88 be 22 f0 00 	cmpl   $0x0,0xf022be88
f010615c:	75 24                	jne    f0106182 <lapic_startap+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010615e:	c7 44 24 0c 67 04 00 	movl   $0x467,0xc(%esp)
f0106165:	00 
f0106166:	c7 44 24 08 e4 66 10 	movl   $0xf01066e4,0x8(%esp)
f010616d:	f0 
f010616e:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
f0106175:	00 
f0106176:	c7 04 24 9c 83 10 f0 	movl   $0xf010839c,(%esp)
f010617d:	e8 be 9e ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0106182:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0106189:	00 00 
	wrv[1] = addr >> 4;
f010618b:	89 f0                	mov    %esi,%eax
f010618d:	c1 e8 04             	shr    $0x4,%eax
f0106190:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0106196:	c1 e3 18             	shl    $0x18,%ebx
f0106199:	89 da                	mov    %ebx,%edx
f010619b:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01061a0:	e8 0c fe ff ff       	call   f0105fb1 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f01061a5:	ba 00 c5 00 00       	mov    $0xc500,%edx
f01061aa:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01061af:	e8 fd fd ff ff       	call   f0105fb1 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f01061b4:	ba 00 85 00 00       	mov    $0x8500,%edx
f01061b9:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01061be:	e8 ee fd ff ff       	call   f0105fb1 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01061c3:	c1 ee 0c             	shr    $0xc,%esi
f01061c6:	81 ce 00 06 00 00    	or     $0x600,%esi
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f01061cc:	89 da                	mov    %ebx,%edx
f01061ce:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01061d3:	e8 d9 fd ff ff       	call   f0105fb1 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01061d8:	89 f2                	mov    %esi,%edx
f01061da:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01061df:	e8 cd fd ff ff       	call   f0105fb1 <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f01061e4:	89 da                	mov    %ebx,%edx
f01061e6:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01061eb:	e8 c1 fd ff ff       	call   f0105fb1 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01061f0:	89 f2                	mov    %esi,%edx
f01061f2:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01061f7:	e8 b5 fd ff ff       	call   f0105fb1 <lapicw>
		microdelay(200);
	}
}
f01061fc:	83 c4 10             	add    $0x10,%esp
f01061ff:	5b                   	pop    %ebx
f0106200:	5e                   	pop    %esi
f0106201:	5d                   	pop    %ebp
f0106202:	c3                   	ret    

f0106203 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0106203:	55                   	push   %ebp
f0106204:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0106206:	8b 55 08             	mov    0x8(%ebp),%edx
f0106209:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f010620f:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106214:	e8 98 fd ff ff       	call   f0105fb1 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0106219:	8b 15 04 d0 26 f0    	mov    0xf026d004,%edx
f010621f:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0106225:	f6 c4 10             	test   $0x10,%ah
f0106228:	75 f5                	jne    f010621f <lapic_ipi+0x1c>
		;
}
f010622a:	5d                   	pop    %ebp
f010622b:	c3                   	ret    

f010622c <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f010622c:	55                   	push   %ebp
f010622d:	89 e5                	mov    %esp,%ebp
f010622f:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0106232:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0106238:	8b 55 0c             	mov    0xc(%ebp),%edx
f010623b:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f010623e:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0106245:	5d                   	pop    %ebp
f0106246:	c3                   	ret    

f0106247 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0106247:	55                   	push   %ebp
f0106248:	89 e5                	mov    %esp,%ebp
f010624a:	56                   	push   %esi
f010624b:	53                   	push   %ebx
f010624c:	83 ec 20             	sub    $0x20,%esp
f010624f:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0106252:	83 3b 00             	cmpl   $0x0,(%ebx)
f0106255:	75 07                	jne    f010625e <spin_lock+0x17>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0106257:	ba 01 00 00 00       	mov    $0x1,%edx
f010625c:	eb 42                	jmp    f01062a0 <spin_lock+0x59>
f010625e:	8b 73 08             	mov    0x8(%ebx),%esi
f0106261:	e8 63 fd ff ff       	call   f0105fc9 <cpunum>
f0106266:	6b c0 74             	imul   $0x74,%eax,%eax
f0106269:	05 20 c0 22 f0       	add    $0xf022c020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f010626e:	39 c6                	cmp    %eax,%esi
f0106270:	75 e5                	jne    f0106257 <spin_lock+0x10>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0106272:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0106275:	e8 4f fd ff ff       	call   f0105fc9 <cpunum>
f010627a:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f010627e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0106282:	c7 44 24 08 ac 83 10 	movl   $0xf01083ac,0x8(%esp)
f0106289:	f0 
f010628a:	c7 44 24 04 41 00 00 	movl   $0x41,0x4(%esp)
f0106291:	00 
f0106292:	c7 04 24 10 84 10 f0 	movl   $0xf0108410,(%esp)
f0106299:	e8 a2 9d ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f010629e:	f3 90                	pause  
f01062a0:	89 d0                	mov    %edx,%eax
f01062a2:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f01062a5:	85 c0                	test   %eax,%eax
f01062a7:	75 f5                	jne    f010629e <spin_lock+0x57>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f01062a9:	e8 1b fd ff ff       	call   f0105fc9 <cpunum>
f01062ae:	6b c0 74             	imul   $0x74,%eax,%eax
f01062b1:	05 20 c0 22 f0       	add    $0xf022c020,%eax
f01062b6:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f01062b9:	83 c3 0c             	add    $0xc,%ebx
get_caller_pcs(uint32_t pcs[])
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
f01062bc:	89 ea                	mov    %ebp,%edx
	for (i = 0; i < 10; i++){
f01062be:	b8 00 00 00 00       	mov    $0x0,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f01062c3:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f01062c9:	76 12                	jbe    f01062dd <spin_lock+0x96>
			break;
		pcs[i] = ebp[1];          // saved %eip
f01062cb:	8b 4a 04             	mov    0x4(%edx),%ecx
f01062ce:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f01062d1:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f01062d3:	83 c0 01             	add    $0x1,%eax
f01062d6:	83 f8 0a             	cmp    $0xa,%eax
f01062d9:	75 e8                	jne    f01062c3 <spin_lock+0x7c>
f01062db:	eb 0f                	jmp    f01062ec <spin_lock+0xa5>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f01062dd:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f01062e4:	83 c0 01             	add    $0x1,%eax
f01062e7:	83 f8 09             	cmp    $0x9,%eax
f01062ea:	7e f1                	jle    f01062dd <spin_lock+0x96>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f01062ec:	83 c4 20             	add    $0x20,%esp
f01062ef:	5b                   	pop    %ebx
f01062f0:	5e                   	pop    %esi
f01062f1:	5d                   	pop    %ebp
f01062f2:	c3                   	ret    

f01062f3 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f01062f3:	55                   	push   %ebp
f01062f4:	89 e5                	mov    %esp,%ebp
f01062f6:	57                   	push   %edi
f01062f7:	56                   	push   %esi
f01062f8:	53                   	push   %ebx
f01062f9:	83 ec 6c             	sub    $0x6c,%esp
f01062fc:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f01062ff:	83 3e 00             	cmpl   $0x0,(%esi)
f0106302:	74 18                	je     f010631c <spin_unlock+0x29>
f0106304:	8b 5e 08             	mov    0x8(%esi),%ebx
f0106307:	e8 bd fc ff ff       	call   f0105fc9 <cpunum>
f010630c:	6b c0 74             	imul   $0x74,%eax,%eax
f010630f:	05 20 c0 22 f0       	add    $0xf022c020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0106314:	39 c3                	cmp    %eax,%ebx
f0106316:	0f 84 ce 00 00 00    	je     f01063ea <spin_unlock+0xf7>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f010631c:	c7 44 24 08 28 00 00 	movl   $0x28,0x8(%esp)
f0106323:	00 
f0106324:	8d 46 0c             	lea    0xc(%esi),%eax
f0106327:	89 44 24 04          	mov    %eax,0x4(%esp)
f010632b:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f010632e:	89 1c 24             	mov    %ebx,(%esp)
f0106331:	e8 8e f6 ff ff       	call   f01059c4 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0106336:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0106339:	0f b6 38             	movzbl (%eax),%edi
f010633c:	8b 76 04             	mov    0x4(%esi),%esi
f010633f:	e8 85 fc ff ff       	call   f0105fc9 <cpunum>
f0106344:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0106348:	89 74 24 08          	mov    %esi,0x8(%esp)
f010634c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106350:	c7 04 24 d8 83 10 f0 	movl   $0xf01083d8,(%esp)
f0106357:	e8 60 dd ff ff       	call   f01040bc <cprintf>
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f010635c:	8d 7d a8             	lea    -0x58(%ebp),%edi
f010635f:	eb 65                	jmp    f01063c6 <spin_unlock+0xd3>
f0106361:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0106365:	89 04 24             	mov    %eax,(%esp)
f0106368:	e8 c1 ea ff ff       	call   f0104e2e <debuginfo_eip>
f010636d:	85 c0                	test   %eax,%eax
f010636f:	78 39                	js     f01063aa <spin_unlock+0xb7>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0106371:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0106373:	89 c2                	mov    %eax,%edx
f0106375:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0106378:	89 54 24 18          	mov    %edx,0x18(%esp)
f010637c:	8b 55 b0             	mov    -0x50(%ebp),%edx
f010637f:	89 54 24 14          	mov    %edx,0x14(%esp)
f0106383:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f0106386:	89 54 24 10          	mov    %edx,0x10(%esp)
f010638a:	8b 55 ac             	mov    -0x54(%ebp),%edx
f010638d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0106391:	8b 55 a8             	mov    -0x58(%ebp),%edx
f0106394:	89 54 24 08          	mov    %edx,0x8(%esp)
f0106398:	89 44 24 04          	mov    %eax,0x4(%esp)
f010639c:	c7 04 24 20 84 10 f0 	movl   $0xf0108420,(%esp)
f01063a3:	e8 14 dd ff ff       	call   f01040bc <cprintf>
f01063a8:	eb 12                	jmp    f01063bc <spin_unlock+0xc9>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f01063aa:	8b 06                	mov    (%esi),%eax
f01063ac:	89 44 24 04          	mov    %eax,0x4(%esp)
f01063b0:	c7 04 24 37 84 10 f0 	movl   $0xf0108437,(%esp)
f01063b7:	e8 00 dd ff ff       	call   f01040bc <cprintf>
f01063bc:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f01063bf:	8d 45 e8             	lea    -0x18(%ebp),%eax
f01063c2:	39 c3                	cmp    %eax,%ebx
f01063c4:	74 08                	je     f01063ce <spin_unlock+0xdb>
f01063c6:	89 de                	mov    %ebx,%esi
f01063c8:	8b 03                	mov    (%ebx),%eax
f01063ca:	85 c0                	test   %eax,%eax
f01063cc:	75 93                	jne    f0106361 <spin_unlock+0x6e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f01063ce:	c7 44 24 08 3f 84 10 	movl   $0xf010843f,0x8(%esp)
f01063d5:	f0 
f01063d6:	c7 44 24 04 67 00 00 	movl   $0x67,0x4(%esp)
f01063dd:	00 
f01063de:	c7 04 24 10 84 10 f0 	movl   $0xf0108410,(%esp)
f01063e5:	e8 56 9c ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f01063ea:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f01063f1:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
f01063f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01063fd:	f0 87 06             	lock xchg %eax,(%esi)
	// Paper says that Intel 64 and IA-32 will not move a load
	// after a store. So lock->locked = 0 would work here.
	// The xchg being asm volatile ensures gcc emits it after
	// the above assignments (and after the critical section).
	xchg(&lk->locked, 0);
}
f0106400:	83 c4 6c             	add    $0x6c,%esp
f0106403:	5b                   	pop    %ebx
f0106404:	5e                   	pop    %esi
f0106405:	5f                   	pop    %edi
f0106406:	5d                   	pop    %ebp
f0106407:	c3                   	ret    
f0106408:	66 90                	xchg   %ax,%ax
f010640a:	66 90                	xchg   %ax,%ax
f010640c:	66 90                	xchg   %ax,%ax
f010640e:	66 90                	xchg   %ax,%ax

f0106410 <__udivdi3>:
f0106410:	55                   	push   %ebp
f0106411:	57                   	push   %edi
f0106412:	56                   	push   %esi
f0106413:	83 ec 10             	sub    $0x10,%esp
f0106416:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f010641a:	8b 7c 24 20          	mov    0x20(%esp),%edi
f010641e:	8b 74 24 24          	mov    0x24(%esp),%esi
f0106422:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0106426:	85 d2                	test   %edx,%edx
f0106428:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010642c:	89 34 24             	mov    %esi,(%esp)
f010642f:	89 c8                	mov    %ecx,%eax
f0106431:	75 35                	jne    f0106468 <__udivdi3+0x58>
f0106433:	39 f1                	cmp    %esi,%ecx
f0106435:	0f 87 bd 00 00 00    	ja     f01064f8 <__udivdi3+0xe8>
f010643b:	85 c9                	test   %ecx,%ecx
f010643d:	89 cd                	mov    %ecx,%ebp
f010643f:	75 0b                	jne    f010644c <__udivdi3+0x3c>
f0106441:	b8 01 00 00 00       	mov    $0x1,%eax
f0106446:	31 d2                	xor    %edx,%edx
f0106448:	f7 f1                	div    %ecx
f010644a:	89 c5                	mov    %eax,%ebp
f010644c:	89 f0                	mov    %esi,%eax
f010644e:	31 d2                	xor    %edx,%edx
f0106450:	f7 f5                	div    %ebp
f0106452:	89 c6                	mov    %eax,%esi
f0106454:	89 f8                	mov    %edi,%eax
f0106456:	f7 f5                	div    %ebp
f0106458:	89 f2                	mov    %esi,%edx
f010645a:	83 c4 10             	add    $0x10,%esp
f010645d:	5e                   	pop    %esi
f010645e:	5f                   	pop    %edi
f010645f:	5d                   	pop    %ebp
f0106460:	c3                   	ret    
f0106461:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106468:	3b 14 24             	cmp    (%esp),%edx
f010646b:	77 7b                	ja     f01064e8 <__udivdi3+0xd8>
f010646d:	0f bd f2             	bsr    %edx,%esi
f0106470:	83 f6 1f             	xor    $0x1f,%esi
f0106473:	0f 84 97 00 00 00    	je     f0106510 <__udivdi3+0x100>
f0106479:	bd 20 00 00 00       	mov    $0x20,%ebp
f010647e:	89 d7                	mov    %edx,%edi
f0106480:	89 f1                	mov    %esi,%ecx
f0106482:	29 f5                	sub    %esi,%ebp
f0106484:	d3 e7                	shl    %cl,%edi
f0106486:	89 c2                	mov    %eax,%edx
f0106488:	89 e9                	mov    %ebp,%ecx
f010648a:	d3 ea                	shr    %cl,%edx
f010648c:	89 f1                	mov    %esi,%ecx
f010648e:	09 fa                	or     %edi,%edx
f0106490:	8b 3c 24             	mov    (%esp),%edi
f0106493:	d3 e0                	shl    %cl,%eax
f0106495:	89 54 24 08          	mov    %edx,0x8(%esp)
f0106499:	89 e9                	mov    %ebp,%ecx
f010649b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010649f:	8b 44 24 04          	mov    0x4(%esp),%eax
f01064a3:	89 fa                	mov    %edi,%edx
f01064a5:	d3 ea                	shr    %cl,%edx
f01064a7:	89 f1                	mov    %esi,%ecx
f01064a9:	d3 e7                	shl    %cl,%edi
f01064ab:	89 e9                	mov    %ebp,%ecx
f01064ad:	d3 e8                	shr    %cl,%eax
f01064af:	09 c7                	or     %eax,%edi
f01064b1:	89 f8                	mov    %edi,%eax
f01064b3:	f7 74 24 08          	divl   0x8(%esp)
f01064b7:	89 d5                	mov    %edx,%ebp
f01064b9:	89 c7                	mov    %eax,%edi
f01064bb:	f7 64 24 0c          	mull   0xc(%esp)
f01064bf:	39 d5                	cmp    %edx,%ebp
f01064c1:	89 14 24             	mov    %edx,(%esp)
f01064c4:	72 11                	jb     f01064d7 <__udivdi3+0xc7>
f01064c6:	8b 54 24 04          	mov    0x4(%esp),%edx
f01064ca:	89 f1                	mov    %esi,%ecx
f01064cc:	d3 e2                	shl    %cl,%edx
f01064ce:	39 c2                	cmp    %eax,%edx
f01064d0:	73 5e                	jae    f0106530 <__udivdi3+0x120>
f01064d2:	3b 2c 24             	cmp    (%esp),%ebp
f01064d5:	75 59                	jne    f0106530 <__udivdi3+0x120>
f01064d7:	8d 47 ff             	lea    -0x1(%edi),%eax
f01064da:	31 f6                	xor    %esi,%esi
f01064dc:	89 f2                	mov    %esi,%edx
f01064de:	83 c4 10             	add    $0x10,%esp
f01064e1:	5e                   	pop    %esi
f01064e2:	5f                   	pop    %edi
f01064e3:	5d                   	pop    %ebp
f01064e4:	c3                   	ret    
f01064e5:	8d 76 00             	lea    0x0(%esi),%esi
f01064e8:	31 f6                	xor    %esi,%esi
f01064ea:	31 c0                	xor    %eax,%eax
f01064ec:	89 f2                	mov    %esi,%edx
f01064ee:	83 c4 10             	add    $0x10,%esp
f01064f1:	5e                   	pop    %esi
f01064f2:	5f                   	pop    %edi
f01064f3:	5d                   	pop    %ebp
f01064f4:	c3                   	ret    
f01064f5:	8d 76 00             	lea    0x0(%esi),%esi
f01064f8:	89 f2                	mov    %esi,%edx
f01064fa:	31 f6                	xor    %esi,%esi
f01064fc:	89 f8                	mov    %edi,%eax
f01064fe:	f7 f1                	div    %ecx
f0106500:	89 f2                	mov    %esi,%edx
f0106502:	83 c4 10             	add    $0x10,%esp
f0106505:	5e                   	pop    %esi
f0106506:	5f                   	pop    %edi
f0106507:	5d                   	pop    %ebp
f0106508:	c3                   	ret    
f0106509:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106510:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f0106514:	76 0b                	jbe    f0106521 <__udivdi3+0x111>
f0106516:	31 c0                	xor    %eax,%eax
f0106518:	3b 14 24             	cmp    (%esp),%edx
f010651b:	0f 83 37 ff ff ff    	jae    f0106458 <__udivdi3+0x48>
f0106521:	b8 01 00 00 00       	mov    $0x1,%eax
f0106526:	e9 2d ff ff ff       	jmp    f0106458 <__udivdi3+0x48>
f010652b:	90                   	nop
f010652c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106530:	89 f8                	mov    %edi,%eax
f0106532:	31 f6                	xor    %esi,%esi
f0106534:	e9 1f ff ff ff       	jmp    f0106458 <__udivdi3+0x48>
f0106539:	66 90                	xchg   %ax,%ax
f010653b:	66 90                	xchg   %ax,%ax
f010653d:	66 90                	xchg   %ax,%ax
f010653f:	90                   	nop

f0106540 <__umoddi3>:
f0106540:	55                   	push   %ebp
f0106541:	57                   	push   %edi
f0106542:	56                   	push   %esi
f0106543:	83 ec 20             	sub    $0x20,%esp
f0106546:	8b 44 24 34          	mov    0x34(%esp),%eax
f010654a:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010654e:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0106552:	89 c6                	mov    %eax,%esi
f0106554:	89 44 24 10          	mov    %eax,0x10(%esp)
f0106558:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f010655c:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0106560:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0106564:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0106568:	89 74 24 18          	mov    %esi,0x18(%esp)
f010656c:	85 c0                	test   %eax,%eax
f010656e:	89 c2                	mov    %eax,%edx
f0106570:	75 1e                	jne    f0106590 <__umoddi3+0x50>
f0106572:	39 f7                	cmp    %esi,%edi
f0106574:	76 52                	jbe    f01065c8 <__umoddi3+0x88>
f0106576:	89 c8                	mov    %ecx,%eax
f0106578:	89 f2                	mov    %esi,%edx
f010657a:	f7 f7                	div    %edi
f010657c:	89 d0                	mov    %edx,%eax
f010657e:	31 d2                	xor    %edx,%edx
f0106580:	83 c4 20             	add    $0x20,%esp
f0106583:	5e                   	pop    %esi
f0106584:	5f                   	pop    %edi
f0106585:	5d                   	pop    %ebp
f0106586:	c3                   	ret    
f0106587:	89 f6                	mov    %esi,%esi
f0106589:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0106590:	39 f0                	cmp    %esi,%eax
f0106592:	77 5c                	ja     f01065f0 <__umoddi3+0xb0>
f0106594:	0f bd e8             	bsr    %eax,%ebp
f0106597:	83 f5 1f             	xor    $0x1f,%ebp
f010659a:	75 64                	jne    f0106600 <__umoddi3+0xc0>
f010659c:	8b 6c 24 14          	mov    0x14(%esp),%ebp
f01065a0:	39 6c 24 0c          	cmp    %ebp,0xc(%esp)
f01065a4:	0f 86 f6 00 00 00    	jbe    f01066a0 <__umoddi3+0x160>
f01065aa:	3b 44 24 18          	cmp    0x18(%esp),%eax
f01065ae:	0f 82 ec 00 00 00    	jb     f01066a0 <__umoddi3+0x160>
f01065b4:	8b 44 24 14          	mov    0x14(%esp),%eax
f01065b8:	8b 54 24 18          	mov    0x18(%esp),%edx
f01065bc:	83 c4 20             	add    $0x20,%esp
f01065bf:	5e                   	pop    %esi
f01065c0:	5f                   	pop    %edi
f01065c1:	5d                   	pop    %ebp
f01065c2:	c3                   	ret    
f01065c3:	90                   	nop
f01065c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01065c8:	85 ff                	test   %edi,%edi
f01065ca:	89 fd                	mov    %edi,%ebp
f01065cc:	75 0b                	jne    f01065d9 <__umoddi3+0x99>
f01065ce:	b8 01 00 00 00       	mov    $0x1,%eax
f01065d3:	31 d2                	xor    %edx,%edx
f01065d5:	f7 f7                	div    %edi
f01065d7:	89 c5                	mov    %eax,%ebp
f01065d9:	8b 44 24 10          	mov    0x10(%esp),%eax
f01065dd:	31 d2                	xor    %edx,%edx
f01065df:	f7 f5                	div    %ebp
f01065e1:	89 c8                	mov    %ecx,%eax
f01065e3:	f7 f5                	div    %ebp
f01065e5:	eb 95                	jmp    f010657c <__umoddi3+0x3c>
f01065e7:	89 f6                	mov    %esi,%esi
f01065e9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f01065f0:	89 c8                	mov    %ecx,%eax
f01065f2:	89 f2                	mov    %esi,%edx
f01065f4:	83 c4 20             	add    $0x20,%esp
f01065f7:	5e                   	pop    %esi
f01065f8:	5f                   	pop    %edi
f01065f9:	5d                   	pop    %ebp
f01065fa:	c3                   	ret    
f01065fb:	90                   	nop
f01065fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106600:	b8 20 00 00 00       	mov    $0x20,%eax
f0106605:	89 e9                	mov    %ebp,%ecx
f0106607:	29 e8                	sub    %ebp,%eax
f0106609:	d3 e2                	shl    %cl,%edx
f010660b:	89 c7                	mov    %eax,%edi
f010660d:	89 44 24 18          	mov    %eax,0x18(%esp)
f0106611:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0106615:	89 f9                	mov    %edi,%ecx
f0106617:	d3 e8                	shr    %cl,%eax
f0106619:	89 c1                	mov    %eax,%ecx
f010661b:	8b 44 24 0c          	mov    0xc(%esp),%eax
f010661f:	09 d1                	or     %edx,%ecx
f0106621:	89 fa                	mov    %edi,%edx
f0106623:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0106627:	89 e9                	mov    %ebp,%ecx
f0106629:	d3 e0                	shl    %cl,%eax
f010662b:	89 f9                	mov    %edi,%ecx
f010662d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0106631:	89 f0                	mov    %esi,%eax
f0106633:	d3 e8                	shr    %cl,%eax
f0106635:	89 e9                	mov    %ebp,%ecx
f0106637:	89 c7                	mov    %eax,%edi
f0106639:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f010663d:	d3 e6                	shl    %cl,%esi
f010663f:	89 d1                	mov    %edx,%ecx
f0106641:	89 fa                	mov    %edi,%edx
f0106643:	d3 e8                	shr    %cl,%eax
f0106645:	89 e9                	mov    %ebp,%ecx
f0106647:	09 f0                	or     %esi,%eax
f0106649:	8b 74 24 1c          	mov    0x1c(%esp),%esi
f010664d:	f7 74 24 10          	divl   0x10(%esp)
f0106651:	d3 e6                	shl    %cl,%esi
f0106653:	89 d1                	mov    %edx,%ecx
f0106655:	f7 64 24 0c          	mull   0xc(%esp)
f0106659:	39 d1                	cmp    %edx,%ecx
f010665b:	89 74 24 14          	mov    %esi,0x14(%esp)
f010665f:	89 d7                	mov    %edx,%edi
f0106661:	89 c6                	mov    %eax,%esi
f0106663:	72 0a                	jb     f010666f <__umoddi3+0x12f>
f0106665:	39 44 24 14          	cmp    %eax,0x14(%esp)
f0106669:	73 10                	jae    f010667b <__umoddi3+0x13b>
f010666b:	39 d1                	cmp    %edx,%ecx
f010666d:	75 0c                	jne    f010667b <__umoddi3+0x13b>
f010666f:	89 d7                	mov    %edx,%edi
f0106671:	89 c6                	mov    %eax,%esi
f0106673:	2b 74 24 0c          	sub    0xc(%esp),%esi
f0106677:	1b 7c 24 10          	sbb    0x10(%esp),%edi
f010667b:	89 ca                	mov    %ecx,%edx
f010667d:	89 e9                	mov    %ebp,%ecx
f010667f:	8b 44 24 14          	mov    0x14(%esp),%eax
f0106683:	29 f0                	sub    %esi,%eax
f0106685:	19 fa                	sbb    %edi,%edx
f0106687:	d3 e8                	shr    %cl,%eax
f0106689:	0f b6 4c 24 18       	movzbl 0x18(%esp),%ecx
f010668e:	89 d7                	mov    %edx,%edi
f0106690:	d3 e7                	shl    %cl,%edi
f0106692:	89 e9                	mov    %ebp,%ecx
f0106694:	09 f8                	or     %edi,%eax
f0106696:	d3 ea                	shr    %cl,%edx
f0106698:	83 c4 20             	add    $0x20,%esp
f010669b:	5e                   	pop    %esi
f010669c:	5f                   	pop    %edi
f010669d:	5d                   	pop    %ebp
f010669e:	c3                   	ret    
f010669f:	90                   	nop
f01066a0:	8b 74 24 10          	mov    0x10(%esp),%esi
f01066a4:	29 f9                	sub    %edi,%ecx
f01066a6:	19 c6                	sbb    %eax,%esi
f01066a8:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f01066ac:	89 74 24 18          	mov    %esi,0x18(%esp)
f01066b0:	e9 ff fe ff ff       	jmp    f01065b4 <__umoddi3+0x74>
