
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
f0100015:	b8 00 10 12 00       	mov    $0x121000,%eax
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
f0100034:	bc 00 10 12 f0       	mov    $0xf0121000,%esp

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
f0100048:	83 3d cc 6e 2a f0 00 	cmpl   $0x0,0xf02a6ecc
f010004f:	75 3a                	jne    f010008b <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f0100051:	89 35 cc 6e 2a f0    	mov    %esi,0xf02a6ecc

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100057:	fa                   	cli    
f0100058:	fc                   	cld    

	va_start(ap, fmt);
f0100059:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005c:	e8 e6 59 00 00       	call   f0105a47 <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 c0 68 10 f0       	push   $0xf01068c0
f010006d:	e8 d8 37 00 00       	call   f010384a <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 a8 37 00 00       	call   f0103824 <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 ee 80 10 f0 	movl   $0xf01080ee,(%esp)
f0100083:	e8 c2 37 00 00       	call   f010384a <cprintf>
	va_end(ap);
f0100088:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010008b:	83 ec 0c             	sub    $0xc,%esp
f010008e:	6a 00                	push   $0x0
f0100090:	e8 8b 08 00 00       	call   f0100920 <monitor>
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
f01000a1:	b8 c0 ff 2f f0       	mov    $0xf02fffc0,%eax
f01000a6:	2d fc 5c 2a f0       	sub    $0xf02a5cfc,%eax
f01000ab:	50                   	push   %eax
f01000ac:	6a 00                	push   $0x0
f01000ae:	68 fc 5c 2a f0       	push   $0xf02a5cfc
f01000b3:	e8 6a 53 00 00       	call   f0105422 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 93 05 00 00       	call   f0100650 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 2c 69 10 f0       	push   $0xf010692c
f01000ca:	e8 7b 37 00 00       	call   f010384a <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 2e 13 00 00       	call   f0101402 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 fd 2f 00 00       	call   f01030d6 <env_init>
	trap_init();
f01000d9:	e8 15 38 00 00       	call   f01038f3 <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 5d 56 00 00       	call   f0105740 <mp_init>
	lapic_init();
f01000e3:	e8 7a 59 00 00       	call   f0105a62 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 86 36 00 00       	call   f0103773 <pic_init>

	// Lab 6 hardware initialization functions
	time_init();
f01000ed:	e8 ab 64 00 00       	call   f010659d <time_init>
	pci_init();
f01000f2:	e8 86 64 00 00       	call   f010657d <pci_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000f7:	c7 04 24 c0 34 12 f0 	movl   $0xf01234c0,(%esp)
f01000fe:	e8 af 5b 00 00       	call   f0105cb2 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100103:	83 c4 10             	add    $0x10,%esp
f0100106:	83 3d d8 6e 2a f0 07 	cmpl   $0x7,0xf02a6ed8
f010010d:	77 16                	ja     f0100125 <i386_init+0x8b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010010f:	68 00 70 00 00       	push   $0x7000
f0100114:	68 e4 68 10 f0       	push   $0xf01068e4
f0100119:	6a 74                	push   $0x74
f010011b:	68 47 69 10 f0       	push   $0xf0106947
f0100120:	e8 1b ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f0100125:	83 ec 04             	sub    $0x4,%esp
f0100128:	b8 a6 56 10 f0       	mov    $0xf01056a6,%eax
f010012d:	2d 2c 56 10 f0       	sub    $0xf010562c,%eax
f0100132:	50                   	push   %eax
f0100133:	68 2c 56 10 f0       	push   $0xf010562c
f0100138:	68 00 70 00 f0       	push   $0xf0007000
f010013d:	e8 2d 53 00 00       	call   f010546f <memmove>
f0100142:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f0100145:	bb 40 70 2a f0       	mov    $0xf02a7040,%ebx
f010014a:	eb 4e                	jmp    f010019a <i386_init+0x100>
		if (c == cpus + cpunum())  // We've started already.
f010014c:	e8 f6 58 00 00       	call   f0105a47 <cpunum>
f0100151:	6b c0 74             	imul   $0x74,%eax,%eax
f0100154:	05 40 70 2a f0       	add    $0xf02a7040,%eax
f0100159:	39 c3                	cmp    %eax,%ebx
f010015b:	74 3a                	je     f0100197 <i386_init+0xfd>
f010015d:	89 d8                	mov    %ebx,%eax
f010015f:	2d 40 70 2a f0       	sub    $0xf02a7040,%eax
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100164:	c1 f8 02             	sar    $0x2,%eax
f0100167:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f010016d:	c1 e0 0f             	shl    $0xf,%eax
f0100170:	8d 80 00 00 2b f0    	lea    -0xfd50000(%eax),%eax
f0100176:	a3 d0 6e 2a f0       	mov    %eax,0xf02a6ed0
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f010017b:	83 ec 08             	sub    $0x8,%esp
f010017e:	68 00 70 00 00       	push   $0x7000
f0100183:	0f b6 03             	movzbl (%ebx),%eax
f0100186:	50                   	push   %eax
f0100187:	e8 24 5a 00 00       	call   f0105bb0 <lapic_startap>
f010018c:	83 c4 10             	add    $0x10,%esp
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f010018f:	8b 43 04             	mov    0x4(%ebx),%eax
f0100192:	83 f8 01             	cmp    $0x1,%eax
f0100195:	75 f8                	jne    f010018f <i386_init+0xf5>
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f0100197:	83 c3 74             	add    $0x74,%ebx
f010019a:	6b 05 e4 73 2a f0 74 	imul   $0x74,0xf02a73e4,%eax
f01001a1:	05 40 70 2a f0       	add    $0xf02a7040,%eax
f01001a6:	39 c3                	cmp    %eax,%ebx
f01001a8:	72 a2                	jb     f010014c <i386_init+0xb2>

	// Starting non-boot CPUs
	boot_aps();

	// Start fs.
	ENV_CREATE(fs_fs, ENV_TYPE_FS);
f01001aa:	83 ec 08             	sub    $0x8,%esp
f01001ad:	6a 01                	push   $0x1
f01001af:	68 e4 28 1d f0       	push   $0xf01d28e4
f01001b4:	e8 bb 30 00 00       	call   f0103274 <env_create>

	
	
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f01001b9:	83 c4 08             	add    $0x8,%esp
f01001bc:	6a 00                	push   $0x0
f01001be:	68 88 5f 21 f0       	push   $0xf0215f88
f01001c3:	e8 ac 30 00 00       	call   f0103274 <env_create>
	//ENV_CREATE(user_yield, ENV_TYPE_USER);

#endif // TEST*

	// Should not be necessary - drains keyboard because interrupt has given up.
	kbd_intr();
f01001c8:	e8 27 04 00 00       	call   f01005f4 <kbd_intr>

	// Schedule and run the first user environment!
	sched_yield();
f01001cd:	e8 32 40 00 00       	call   f0104204 <sched_yield>

f01001d2 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001d2:	55                   	push   %ebp
f01001d3:	89 e5                	mov    %esp,%ebp
f01001d5:	83 ec 08             	sub    $0x8,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001d8:	a1 dc 6e 2a f0       	mov    0xf02a6edc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001dd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001e2:	77 15                	ja     f01001f9 <mp_main+0x27>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001e4:	50                   	push   %eax
f01001e5:	68 08 69 10 f0       	push   $0xf0106908
f01001ea:	68 8b 00 00 00       	push   $0x8b
f01001ef:	68 47 69 10 f0       	push   $0xf0106947
f01001f4:	e8 47 fe ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01001f9:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01001fe:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f0100201:	e8 41 58 00 00       	call   f0105a47 <cpunum>
f0100206:	83 ec 08             	sub    $0x8,%esp
f0100209:	50                   	push   %eax
f010020a:	68 53 69 10 f0       	push   $0xf0106953
f010020f:	e8 36 36 00 00       	call   f010384a <cprintf>

	lapic_init();
f0100214:	e8 49 58 00 00       	call   f0105a62 <lapic_init>
	env_init_percpu();
f0100219:	e8 8e 2e 00 00       	call   f01030ac <env_init_percpu>
	trap_init_percpu();
f010021e:	e8 3b 36 00 00       	call   f010385e <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100223:	e8 1f 58 00 00       	call   f0105a47 <cpunum>
f0100228:	6b d0 74             	imul   $0x74,%eax,%edx
f010022b:	81 c2 40 70 2a f0    	add    $0xf02a7040,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0100231:	b8 01 00 00 00       	mov    $0x1,%eax
f0100236:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f010023a:	c7 04 24 c0 34 12 f0 	movl   $0xf01234c0,(%esp)
f0100241:	e8 6c 5a 00 00       	call   f0105cb2 <spin_lock>
	// to start running processes on this CPU.  But make sure that
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	lock_kernel();  //Acquire the lock
	sched_yield(); //Call the sched_yield() function to schedule and run different environments, Exercise 6
f0100246:	e8 b9 3f 00 00       	call   f0104204 <sched_yield>

f010024b <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010024b:	55                   	push   %ebp
f010024c:	89 e5                	mov    %esp,%ebp
f010024e:	53                   	push   %ebx
f010024f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100252:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100255:	ff 75 0c             	pushl  0xc(%ebp)
f0100258:	ff 75 08             	pushl  0x8(%ebp)
f010025b:	68 69 69 10 f0       	push   $0xf0106969
f0100260:	e8 e5 35 00 00       	call   f010384a <cprintf>
	vcprintf(fmt, ap);
f0100265:	83 c4 08             	add    $0x8,%esp
f0100268:	53                   	push   %ebx
f0100269:	ff 75 10             	pushl  0x10(%ebp)
f010026c:	e8 b3 35 00 00       	call   f0103824 <vcprintf>
	cprintf("\n");
f0100271:	c7 04 24 ee 80 10 f0 	movl   $0xf01080ee,(%esp)
f0100278:	e8 cd 35 00 00       	call   f010384a <cprintf>
	va_end(ap);
f010027d:	83 c4 10             	add    $0x10,%esp
}
f0100280:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100283:	c9                   	leave  
f0100284:	c3                   	ret    

f0100285 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100285:	55                   	push   %ebp
f0100286:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100288:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010028d:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010028e:	a8 01                	test   $0x1,%al
f0100290:	74 08                	je     f010029a <serial_proc_data+0x15>
f0100292:	b2 f8                	mov    $0xf8,%dl
f0100294:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100295:	0f b6 c0             	movzbl %al,%eax
f0100298:	eb 05                	jmp    f010029f <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010029a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010029f:	5d                   	pop    %ebp
f01002a0:	c3                   	ret    

f01002a1 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01002a1:	55                   	push   %ebp
f01002a2:	89 e5                	mov    %esp,%ebp
f01002a4:	53                   	push   %ebx
f01002a5:	83 ec 04             	sub    $0x4,%esp
f01002a8:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01002aa:	eb 2a                	jmp    f01002d6 <cons_intr+0x35>
		if (c == 0)
f01002ac:	85 d2                	test   %edx,%edx
f01002ae:	74 26                	je     f01002d6 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01002b0:	a1 44 62 2a f0       	mov    0xf02a6244,%eax
f01002b5:	8d 48 01             	lea    0x1(%eax),%ecx
f01002b8:	89 0d 44 62 2a f0    	mov    %ecx,0xf02a6244
f01002be:	88 90 40 60 2a f0    	mov    %dl,-0xfd59fc0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01002c4:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01002ca:	75 0a                	jne    f01002d6 <cons_intr+0x35>
			cons.wpos = 0;
f01002cc:	c7 05 44 62 2a f0 00 	movl   $0x0,0xf02a6244
f01002d3:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002d6:	ff d3                	call   *%ebx
f01002d8:	89 c2                	mov    %eax,%edx
f01002da:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002dd:	75 cd                	jne    f01002ac <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01002df:	83 c4 04             	add    $0x4,%esp
f01002e2:	5b                   	pop    %ebx
f01002e3:	5d                   	pop    %ebp
f01002e4:	c3                   	ret    

f01002e5 <kbd_proc_data>:
f01002e5:	ba 64 00 00 00       	mov    $0x64,%edx
f01002ea:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01002eb:	a8 01                	test   $0x1,%al
f01002ed:	0f 84 f0 00 00 00    	je     f01003e3 <kbd_proc_data+0xfe>
f01002f3:	b2 60                	mov    $0x60,%dl
f01002f5:	ec                   	in     (%dx),%al
f01002f6:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01002f8:	3c e0                	cmp    $0xe0,%al
f01002fa:	75 0d                	jne    f0100309 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f01002fc:	83 0d 00 60 2a f0 40 	orl    $0x40,0xf02a6000
		return 0;
f0100303:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100308:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100309:	55                   	push   %ebp
f010030a:	89 e5                	mov    %esp,%ebp
f010030c:	53                   	push   %ebx
f010030d:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100310:	84 c0                	test   %al,%al
f0100312:	79 36                	jns    f010034a <kbd_proc_data+0x65>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100314:	8b 0d 00 60 2a f0    	mov    0xf02a6000,%ecx
f010031a:	89 cb                	mov    %ecx,%ebx
f010031c:	83 e3 40             	and    $0x40,%ebx
f010031f:	83 e0 7f             	and    $0x7f,%eax
f0100322:	85 db                	test   %ebx,%ebx
f0100324:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100327:	0f b6 d2             	movzbl %dl,%edx
f010032a:	0f b6 82 00 6b 10 f0 	movzbl -0xfef9500(%edx),%eax
f0100331:	83 c8 40             	or     $0x40,%eax
f0100334:	0f b6 c0             	movzbl %al,%eax
f0100337:	f7 d0                	not    %eax
f0100339:	21 c8                	and    %ecx,%eax
f010033b:	a3 00 60 2a f0       	mov    %eax,0xf02a6000
		return 0;
f0100340:	b8 00 00 00 00       	mov    $0x0,%eax
f0100345:	e9 a1 00 00 00       	jmp    f01003eb <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f010034a:	8b 0d 00 60 2a f0    	mov    0xf02a6000,%ecx
f0100350:	f6 c1 40             	test   $0x40,%cl
f0100353:	74 0e                	je     f0100363 <kbd_proc_data+0x7e>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100355:	83 c8 80             	or     $0xffffff80,%eax
f0100358:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010035a:	83 e1 bf             	and    $0xffffffbf,%ecx
f010035d:	89 0d 00 60 2a f0    	mov    %ecx,0xf02a6000
	}

	shift |= shiftcode[data];
f0100363:	0f b6 c2             	movzbl %dl,%eax
f0100366:	0f b6 90 00 6b 10 f0 	movzbl -0xfef9500(%eax),%edx
f010036d:	0b 15 00 60 2a f0    	or     0xf02a6000,%edx
	shift ^= togglecode[data];
f0100373:	0f b6 88 00 6a 10 f0 	movzbl -0xfef9600(%eax),%ecx
f010037a:	31 ca                	xor    %ecx,%edx
f010037c:	89 15 00 60 2a f0    	mov    %edx,0xf02a6000

	c = charcode[shift & (CTL | SHIFT)][data];
f0100382:	89 d1                	mov    %edx,%ecx
f0100384:	83 e1 03             	and    $0x3,%ecx
f0100387:	8b 0c 8d c0 69 10 f0 	mov    -0xfef9640(,%ecx,4),%ecx
f010038e:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f0100392:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f0100395:	f6 c2 08             	test   $0x8,%dl
f0100398:	74 1b                	je     f01003b5 <kbd_proc_data+0xd0>
		if ('a' <= c && c <= 'z')
f010039a:	89 d8                	mov    %ebx,%eax
f010039c:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010039f:	83 f9 19             	cmp    $0x19,%ecx
f01003a2:	77 05                	ja     f01003a9 <kbd_proc_data+0xc4>
			c += 'A' - 'a';
f01003a4:	83 eb 20             	sub    $0x20,%ebx
f01003a7:	eb 0c                	jmp    f01003b5 <kbd_proc_data+0xd0>
		else if ('A' <= c && c <= 'Z')
f01003a9:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f01003ac:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01003af:	83 f8 19             	cmp    $0x19,%eax
f01003b2:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003b5:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01003bb:	75 2c                	jne    f01003e9 <kbd_proc_data+0x104>
f01003bd:	f7 d2                	not    %edx
f01003bf:	f6 c2 06             	test   $0x6,%dl
f01003c2:	75 25                	jne    f01003e9 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01003c4:	83 ec 0c             	sub    $0xc,%esp
f01003c7:	68 83 69 10 f0       	push   $0xf0106983
f01003cc:	e8 79 34 00 00       	call   f010384a <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003d1:	ba 92 00 00 00       	mov    $0x92,%edx
f01003d6:	b8 03 00 00 00       	mov    $0x3,%eax
f01003db:	ee                   	out    %al,(%dx)
f01003dc:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003df:	89 d8                	mov    %ebx,%eax
f01003e1:	eb 08                	jmp    f01003eb <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01003e3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01003e8:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003e9:	89 d8                	mov    %ebx,%eax
}
f01003eb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01003ee:	c9                   	leave  
f01003ef:	c3                   	ret    

f01003f0 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003f0:	55                   	push   %ebp
f01003f1:	89 e5                	mov    %esp,%ebp
f01003f3:	57                   	push   %edi
f01003f4:	56                   	push   %esi
f01003f5:	53                   	push   %ebx
f01003f6:	83 ec 1c             	sub    $0x1c,%esp
f01003f9:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01003fb:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100400:	be fd 03 00 00       	mov    $0x3fd,%esi
f0100405:	b9 84 00 00 00       	mov    $0x84,%ecx
f010040a:	eb 09                	jmp    f0100415 <cons_putc+0x25>
f010040c:	89 ca                	mov    %ecx,%edx
f010040e:	ec                   	in     (%dx),%al
f010040f:	ec                   	in     (%dx),%al
f0100410:	ec                   	in     (%dx),%al
f0100411:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100412:	83 c3 01             	add    $0x1,%ebx
f0100415:	89 f2                	mov    %esi,%edx
f0100417:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100418:	a8 20                	test   $0x20,%al
f010041a:	75 08                	jne    f0100424 <cons_putc+0x34>
f010041c:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100422:	7e e8                	jle    f010040c <cons_putc+0x1c>
f0100424:	89 f8                	mov    %edi,%eax
f0100426:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100429:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010042e:	89 f8                	mov    %edi,%eax
f0100430:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100431:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100436:	be 79 03 00 00       	mov    $0x379,%esi
f010043b:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100440:	eb 09                	jmp    f010044b <cons_putc+0x5b>
f0100442:	89 ca                	mov    %ecx,%edx
f0100444:	ec                   	in     (%dx),%al
f0100445:	ec                   	in     (%dx),%al
f0100446:	ec                   	in     (%dx),%al
f0100447:	ec                   	in     (%dx),%al
f0100448:	83 c3 01             	add    $0x1,%ebx
f010044b:	89 f2                	mov    %esi,%edx
f010044d:	ec                   	in     (%dx),%al
f010044e:	84 c0                	test   %al,%al
f0100450:	78 08                	js     f010045a <cons_putc+0x6a>
f0100452:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100458:	7e e8                	jle    f0100442 <cons_putc+0x52>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010045a:	ba 78 03 00 00       	mov    $0x378,%edx
f010045f:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100463:	ee                   	out    %al,(%dx)
f0100464:	b2 7a                	mov    $0x7a,%dl
f0100466:	b8 0d 00 00 00       	mov    $0xd,%eax
f010046b:	ee                   	out    %al,(%dx)
f010046c:	b8 08 00 00 00       	mov    $0x8,%eax
f0100471:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100472:	89 fa                	mov    %edi,%edx
f0100474:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010047a:	89 f8                	mov    %edi,%eax
f010047c:	80 cc 07             	or     $0x7,%ah
f010047f:	85 d2                	test   %edx,%edx
f0100481:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100484:	89 f8                	mov    %edi,%eax
f0100486:	0f b6 c0             	movzbl %al,%eax
f0100489:	83 f8 09             	cmp    $0x9,%eax
f010048c:	74 74                	je     f0100502 <cons_putc+0x112>
f010048e:	83 f8 09             	cmp    $0x9,%eax
f0100491:	7f 0a                	jg     f010049d <cons_putc+0xad>
f0100493:	83 f8 08             	cmp    $0x8,%eax
f0100496:	74 14                	je     f01004ac <cons_putc+0xbc>
f0100498:	e9 99 00 00 00       	jmp    f0100536 <cons_putc+0x146>
f010049d:	83 f8 0a             	cmp    $0xa,%eax
f01004a0:	74 3a                	je     f01004dc <cons_putc+0xec>
f01004a2:	83 f8 0d             	cmp    $0xd,%eax
f01004a5:	74 3d                	je     f01004e4 <cons_putc+0xf4>
f01004a7:	e9 8a 00 00 00       	jmp    f0100536 <cons_putc+0x146>
	case '\b':
		if (crt_pos > 0) {
f01004ac:	0f b7 05 48 62 2a f0 	movzwl 0xf02a6248,%eax
f01004b3:	66 85 c0             	test   %ax,%ax
f01004b6:	0f 84 e6 00 00 00    	je     f01005a2 <cons_putc+0x1b2>
			crt_pos--;
f01004bc:	83 e8 01             	sub    $0x1,%eax
f01004bf:	66 a3 48 62 2a f0    	mov    %ax,0xf02a6248
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004c5:	0f b7 c0             	movzwl %ax,%eax
f01004c8:	66 81 e7 00 ff       	and    $0xff00,%di
f01004cd:	83 cf 20             	or     $0x20,%edi
f01004d0:	8b 15 4c 62 2a f0    	mov    0xf02a624c,%edx
f01004d6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004da:	eb 78                	jmp    f0100554 <cons_putc+0x164>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004dc:	66 83 05 48 62 2a f0 	addw   $0x50,0xf02a6248
f01004e3:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004e4:	0f b7 05 48 62 2a f0 	movzwl 0xf02a6248,%eax
f01004eb:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004f1:	c1 e8 16             	shr    $0x16,%eax
f01004f4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004f7:	c1 e0 04             	shl    $0x4,%eax
f01004fa:	66 a3 48 62 2a f0    	mov    %ax,0xf02a6248
f0100500:	eb 52                	jmp    f0100554 <cons_putc+0x164>
		break;
	case '\t':
		cons_putc(' ');
f0100502:	b8 20 00 00 00       	mov    $0x20,%eax
f0100507:	e8 e4 fe ff ff       	call   f01003f0 <cons_putc>
		cons_putc(' ');
f010050c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100511:	e8 da fe ff ff       	call   f01003f0 <cons_putc>
		cons_putc(' ');
f0100516:	b8 20 00 00 00       	mov    $0x20,%eax
f010051b:	e8 d0 fe ff ff       	call   f01003f0 <cons_putc>
		cons_putc(' ');
f0100520:	b8 20 00 00 00       	mov    $0x20,%eax
f0100525:	e8 c6 fe ff ff       	call   f01003f0 <cons_putc>
		cons_putc(' ');
f010052a:	b8 20 00 00 00       	mov    $0x20,%eax
f010052f:	e8 bc fe ff ff       	call   f01003f0 <cons_putc>
f0100534:	eb 1e                	jmp    f0100554 <cons_putc+0x164>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100536:	0f b7 05 48 62 2a f0 	movzwl 0xf02a6248,%eax
f010053d:	8d 50 01             	lea    0x1(%eax),%edx
f0100540:	66 89 15 48 62 2a f0 	mov    %dx,0xf02a6248
f0100547:	0f b7 c0             	movzwl %ax,%eax
f010054a:	8b 15 4c 62 2a f0    	mov    0xf02a624c,%edx
f0100550:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100554:	66 81 3d 48 62 2a f0 	cmpw   $0x7cf,0xf02a6248
f010055b:	cf 07 
f010055d:	76 43                	jbe    f01005a2 <cons_putc+0x1b2>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010055f:	a1 4c 62 2a f0       	mov    0xf02a624c,%eax
f0100564:	83 ec 04             	sub    $0x4,%esp
f0100567:	68 00 0f 00 00       	push   $0xf00
f010056c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100572:	52                   	push   %edx
f0100573:	50                   	push   %eax
f0100574:	e8 f6 4e 00 00       	call   f010546f <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100579:	8b 15 4c 62 2a f0    	mov    0xf02a624c,%edx
f010057f:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100585:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010058b:	83 c4 10             	add    $0x10,%esp
f010058e:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100593:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100596:	39 d0                	cmp    %edx,%eax
f0100598:	75 f4                	jne    f010058e <cons_putc+0x19e>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010059a:	66 83 2d 48 62 2a f0 	subw   $0x50,0xf02a6248
f01005a1:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01005a2:	8b 0d 50 62 2a f0    	mov    0xf02a6250,%ecx
f01005a8:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005ad:	89 ca                	mov    %ecx,%edx
f01005af:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01005b0:	0f b7 1d 48 62 2a f0 	movzwl 0xf02a6248,%ebx
f01005b7:	8d 71 01             	lea    0x1(%ecx),%esi
f01005ba:	89 d8                	mov    %ebx,%eax
f01005bc:	66 c1 e8 08          	shr    $0x8,%ax
f01005c0:	89 f2                	mov    %esi,%edx
f01005c2:	ee                   	out    %al,(%dx)
f01005c3:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005c8:	89 ca                	mov    %ecx,%edx
f01005ca:	ee                   	out    %al,(%dx)
f01005cb:	89 d8                	mov    %ebx,%eax
f01005cd:	89 f2                	mov    %esi,%edx
f01005cf:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005d0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005d3:	5b                   	pop    %ebx
f01005d4:	5e                   	pop    %esi
f01005d5:	5f                   	pop    %edi
f01005d6:	5d                   	pop    %ebp
f01005d7:	c3                   	ret    

f01005d8 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01005d8:	80 3d 54 62 2a f0 00 	cmpb   $0x0,0xf02a6254
f01005df:	74 11                	je     f01005f2 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01005e1:	55                   	push   %ebp
f01005e2:	89 e5                	mov    %esp,%ebp
f01005e4:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01005e7:	b8 85 02 10 f0       	mov    $0xf0100285,%eax
f01005ec:	e8 b0 fc ff ff       	call   f01002a1 <cons_intr>
}
f01005f1:	c9                   	leave  
f01005f2:	f3 c3                	repz ret 

f01005f4 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01005f4:	55                   	push   %ebp
f01005f5:	89 e5                	mov    %esp,%ebp
f01005f7:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01005fa:	b8 e5 02 10 f0       	mov    $0xf01002e5,%eax
f01005ff:	e8 9d fc ff ff       	call   f01002a1 <cons_intr>
}
f0100604:	c9                   	leave  
f0100605:	c3                   	ret    

f0100606 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100606:	55                   	push   %ebp
f0100607:	89 e5                	mov    %esp,%ebp
f0100609:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010060c:	e8 c7 ff ff ff       	call   f01005d8 <serial_intr>
	kbd_intr();
f0100611:	e8 de ff ff ff       	call   f01005f4 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100616:	a1 40 62 2a f0       	mov    0xf02a6240,%eax
f010061b:	3b 05 44 62 2a f0    	cmp    0xf02a6244,%eax
f0100621:	74 26                	je     f0100649 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100623:	8d 50 01             	lea    0x1(%eax),%edx
f0100626:	89 15 40 62 2a f0    	mov    %edx,0xf02a6240
f010062c:	0f b6 88 40 60 2a f0 	movzbl -0xfd59fc0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100633:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100635:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010063b:	75 11                	jne    f010064e <cons_getc+0x48>
			cons.rpos = 0;
f010063d:	c7 05 40 62 2a f0 00 	movl   $0x0,0xf02a6240
f0100644:	00 00 00 
f0100647:	eb 05                	jmp    f010064e <cons_getc+0x48>
		return c;
	}
	return 0;
f0100649:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010064e:	c9                   	leave  
f010064f:	c3                   	ret    

f0100650 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100650:	55                   	push   %ebp
f0100651:	89 e5                	mov    %esp,%ebp
f0100653:	57                   	push   %edi
f0100654:	56                   	push   %esi
f0100655:	53                   	push   %ebx
f0100656:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100659:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100660:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100667:	5a a5 
	if (*cp != 0xA55A) {
f0100669:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100670:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100674:	74 11                	je     f0100687 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100676:	c7 05 50 62 2a f0 b4 	movl   $0x3b4,0xf02a6250
f010067d:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100680:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100685:	eb 16                	jmp    f010069d <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100687:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010068e:	c7 05 50 62 2a f0 d4 	movl   $0x3d4,0xf02a6250
f0100695:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100698:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010069d:	8b 3d 50 62 2a f0    	mov    0xf02a6250,%edi
f01006a3:	b8 0e 00 00 00       	mov    $0xe,%eax
f01006a8:	89 fa                	mov    %edi,%edx
f01006aa:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01006ab:	8d 4f 01             	lea    0x1(%edi),%ecx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006ae:	89 ca                	mov    %ecx,%edx
f01006b0:	ec                   	in     (%dx),%al
f01006b1:	0f b6 c0             	movzbl %al,%eax
f01006b4:	c1 e0 08             	shl    $0x8,%eax
f01006b7:	89 c3                	mov    %eax,%ebx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006b9:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006be:	89 fa                	mov    %edi,%edx
f01006c0:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006c1:	89 ca                	mov    %ecx,%edx
f01006c3:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006c4:	89 35 4c 62 2a f0    	mov    %esi,0xf02a624c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01006ca:	0f b6 c8             	movzbl %al,%ecx
f01006cd:	89 d8                	mov    %ebx,%eax
f01006cf:	09 c8                	or     %ecx,%eax

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01006d1:	66 a3 48 62 2a f0    	mov    %ax,0xf02a6248

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006d7:	e8 18 ff ff ff       	call   f01005f4 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<1));
f01006dc:	83 ec 0c             	sub    $0xc,%esp
f01006df:	0f b7 05 e8 33 12 f0 	movzwl 0xf01233e8,%eax
f01006e6:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006eb:	50                   	push   %eax
f01006ec:	e8 0d 30 00 00       	call   f01036fe <irq_setmask_8259A>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006f1:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01006f6:	b8 00 00 00 00       	mov    $0x0,%eax
f01006fb:	89 da                	mov    %ebx,%edx
f01006fd:	ee                   	out    %al,(%dx)
f01006fe:	b2 fb                	mov    $0xfb,%dl
f0100700:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100705:	ee                   	out    %al,(%dx)
f0100706:	be f8 03 00 00       	mov    $0x3f8,%esi
f010070b:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100710:	89 f2                	mov    %esi,%edx
f0100712:	ee                   	out    %al,(%dx)
f0100713:	b2 f9                	mov    $0xf9,%dl
f0100715:	b8 00 00 00 00       	mov    $0x0,%eax
f010071a:	ee                   	out    %al,(%dx)
f010071b:	b2 fb                	mov    $0xfb,%dl
f010071d:	b8 03 00 00 00       	mov    $0x3,%eax
f0100722:	ee                   	out    %al,(%dx)
f0100723:	b2 fc                	mov    $0xfc,%dl
f0100725:	b8 00 00 00 00       	mov    $0x0,%eax
f010072a:	ee                   	out    %al,(%dx)
f010072b:	b2 f9                	mov    $0xf9,%dl
f010072d:	b8 01 00 00 00       	mov    $0x1,%eax
f0100732:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100733:	b2 fd                	mov    $0xfd,%dl
f0100735:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100736:	83 c4 10             	add    $0x10,%esp
f0100739:	3c ff                	cmp    $0xff,%al
f010073b:	0f 95 c1             	setne  %cl
f010073e:	88 0d 54 62 2a f0    	mov    %cl,0xf02a6254
f0100744:	89 da                	mov    %ebx,%edx
f0100746:	ec                   	in     (%dx),%al
f0100747:	89 f2                	mov    %esi,%edx
f0100749:	ec                   	in     (%dx),%al
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);

	// Enable serial interrupts
	if (serial_exists)
f010074a:	84 c9                	test   %cl,%cl
f010074c:	74 21                	je     f010076f <cons_init+0x11f>
		irq_setmask_8259A(irq_mask_8259A & ~(1<<4));
f010074e:	83 ec 0c             	sub    $0xc,%esp
f0100751:	0f b7 05 e8 33 12 f0 	movzwl 0xf01233e8,%eax
f0100758:	25 ef ff 00 00       	and    $0xffef,%eax
f010075d:	50                   	push   %eax
f010075e:	e8 9b 2f 00 00       	call   f01036fe <irq_setmask_8259A>
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100763:	83 c4 10             	add    $0x10,%esp
f0100766:	80 3d 54 62 2a f0 00 	cmpb   $0x0,0xf02a6254
f010076d:	75 10                	jne    f010077f <cons_init+0x12f>
		cprintf("Serial port does not exist!\n");
f010076f:	83 ec 0c             	sub    $0xc,%esp
f0100772:	68 8f 69 10 f0       	push   $0xf010698f
f0100777:	e8 ce 30 00 00       	call   f010384a <cprintf>
f010077c:	83 c4 10             	add    $0x10,%esp
}
f010077f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100782:	5b                   	pop    %ebx
f0100783:	5e                   	pop    %esi
f0100784:	5f                   	pop    %edi
f0100785:	5d                   	pop    %ebp
f0100786:	c3                   	ret    

f0100787 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100787:	55                   	push   %ebp
f0100788:	89 e5                	mov    %esp,%ebp
f010078a:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010078d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100790:	e8 5b fc ff ff       	call   f01003f0 <cons_putc>
}
f0100795:	c9                   	leave  
f0100796:	c3                   	ret    

f0100797 <getchar>:

int
getchar(void)
{
f0100797:	55                   	push   %ebp
f0100798:	89 e5                	mov    %esp,%ebp
f010079a:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010079d:	e8 64 fe ff ff       	call   f0100606 <cons_getc>
f01007a2:	85 c0                	test   %eax,%eax
f01007a4:	74 f7                	je     f010079d <getchar+0x6>
		/* do nothing */;
	return c;
}
f01007a6:	c9                   	leave  
f01007a7:	c3                   	ret    

f01007a8 <iscons>:

int
iscons(int fdnum)
{
f01007a8:	55                   	push   %ebp
f01007a9:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01007ab:	b8 01 00 00 00       	mov    $0x1,%eax
f01007b0:	5d                   	pop    %ebp
f01007b1:	c3                   	ret    

f01007b2 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01007b2:	55                   	push   %ebp
f01007b3:	89 e5                	mov    %esp,%ebp
f01007b5:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007b8:	68 00 6c 10 f0       	push   $0xf0106c00
f01007bd:	68 1e 6c 10 f0       	push   $0xf0106c1e
f01007c2:	68 23 6c 10 f0       	push   $0xf0106c23
f01007c7:	e8 7e 30 00 00       	call   f010384a <cprintf>
f01007cc:	83 c4 0c             	add    $0xc,%esp
f01007cf:	68 c4 6c 10 f0       	push   $0xf0106cc4
f01007d4:	68 2c 6c 10 f0       	push   $0xf0106c2c
f01007d9:	68 23 6c 10 f0       	push   $0xf0106c23
f01007de:	e8 67 30 00 00       	call   f010384a <cprintf>
f01007e3:	83 c4 0c             	add    $0xc,%esp
f01007e6:	68 35 6c 10 f0       	push   $0xf0106c35
f01007eb:	68 52 6c 10 f0       	push   $0xf0106c52
f01007f0:	68 23 6c 10 f0       	push   $0xf0106c23
f01007f5:	e8 50 30 00 00       	call   f010384a <cprintf>
	return 0;
}
f01007fa:	b8 00 00 00 00       	mov    $0x0,%eax
f01007ff:	c9                   	leave  
f0100800:	c3                   	ret    

f0100801 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100801:	55                   	push   %ebp
f0100802:	89 e5                	mov    %esp,%ebp
f0100804:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100807:	68 5d 6c 10 f0       	push   $0xf0106c5d
f010080c:	e8 39 30 00 00       	call   f010384a <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100811:	83 c4 08             	add    $0x8,%esp
f0100814:	68 0c 00 10 00       	push   $0x10000c
f0100819:	68 ec 6c 10 f0       	push   $0xf0106cec
f010081e:	e8 27 30 00 00       	call   f010384a <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100823:	83 c4 0c             	add    $0xc,%esp
f0100826:	68 0c 00 10 00       	push   $0x10000c
f010082b:	68 0c 00 10 f0       	push   $0xf010000c
f0100830:	68 14 6d 10 f0       	push   $0xf0106d14
f0100835:	e8 10 30 00 00       	call   f010384a <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010083a:	83 c4 0c             	add    $0xc,%esp
f010083d:	68 95 68 10 00       	push   $0x106895
f0100842:	68 95 68 10 f0       	push   $0xf0106895
f0100847:	68 38 6d 10 f0       	push   $0xf0106d38
f010084c:	e8 f9 2f 00 00       	call   f010384a <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100851:	83 c4 0c             	add    $0xc,%esp
f0100854:	68 fc 5c 2a 00       	push   $0x2a5cfc
f0100859:	68 fc 5c 2a f0       	push   $0xf02a5cfc
f010085e:	68 5c 6d 10 f0       	push   $0xf0106d5c
f0100863:	e8 e2 2f 00 00       	call   f010384a <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100868:	83 c4 0c             	add    $0xc,%esp
f010086b:	68 c0 ff 2f 00       	push   $0x2fffc0
f0100870:	68 c0 ff 2f f0       	push   $0xf02fffc0
f0100875:	68 80 6d 10 f0       	push   $0xf0106d80
f010087a:	e8 cb 2f 00 00       	call   f010384a <cprintf>
f010087f:	b8 bf 03 30 f0       	mov    $0xf03003bf,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100884:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100889:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f010088c:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100891:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100897:	85 c0                	test   %eax,%eax
f0100899:	0f 48 c2             	cmovs  %edx,%eax
f010089c:	c1 f8 0a             	sar    $0xa,%eax
f010089f:	50                   	push   %eax
f01008a0:	68 a4 6d 10 f0       	push   $0xf0106da4
f01008a5:	e8 a0 2f 00 00       	call   f010384a <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01008aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01008af:	c9                   	leave  
f01008b0:	c3                   	ret    

f01008b1 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008b1:	55                   	push   %ebp
f01008b2:	89 e5                	mov    %esp,%ebp
f01008b4:	57                   	push   %edi
f01008b5:	56                   	push   %esi
f01008b6:	53                   	push   %ebx
f01008b7:	83 ec 38             	sub    $0x38,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01008ba:	89 eb                	mov    %ebp,%ebx
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
f01008bc:	68 76 6c 10 f0       	push   $0xf0106c76
f01008c1:	e8 84 2f 00 00       	call   f010384a <cprintf>
	
	
	while (ebp){
f01008c6:	83 c4 10             	add    $0x10,%esp
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
		debuginfo_eip(eip, &sym);
f01008c9:	8d 7d d0             	lea    -0x30(%ebp),%edi
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f01008cc:	eb 41                	jmp    f010090f <mon_backtrace+0x5e>
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
f01008ce:	8b 73 04             	mov    0x4(%ebx),%esi
		debuginfo_eip(eip, &sym);
f01008d1:	83 ec 08             	sub    $0x8,%esp
f01008d4:	57                   	push   %edi
f01008d5:	56                   	push   %esi
f01008d6:	e8 b1 40 00 00       	call   f010498c <debuginfo_eip>
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n %s:%d: %.*s+%d\n",ebp,eip,
f01008db:	89 f0                	mov    %esi,%eax
f01008dd:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01008e0:	89 04 24             	mov    %eax,(%esp)
f01008e3:	ff 75 d8             	pushl  -0x28(%ebp)
f01008e6:	ff 75 dc             	pushl  -0x24(%ebp)
f01008e9:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008ec:	ff 75 d0             	pushl  -0x30(%ebp)
f01008ef:	ff 73 18             	pushl  0x18(%ebx)
f01008f2:	ff 73 14             	pushl  0x14(%ebx)
f01008f5:	ff 73 10             	pushl  0x10(%ebx)
f01008f8:	ff 73 0c             	pushl  0xc(%ebx)
f01008fb:	ff 73 08             	pushl  0x8(%ebx)
f01008fe:	56                   	push   %esi
f01008ff:	53                   	push   %ebx
f0100900:	68 d0 6d 10 f0       	push   $0xf0106dd0
f0100905:	e8 40 2f 00 00       	call   f010384a <cprintf>
		*((uint32_t *)ebp + 6), sym.eip_file,
			      sym.eip_line,
			      sym.eip_fn_namelen,
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
f010090a:	8b 1b                	mov    (%ebx),%ebx
f010090c:	83 c4 40             	add    $0x40,%esp
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f010090f:	85 db                	test   %ebx,%ebx
f0100911:	75 bb                	jne    f01008ce <mon_backtrace+0x1d>
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
	}
	return 0;
}
f0100913:	b8 00 00 00 00       	mov    $0x0,%eax
f0100918:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010091b:	5b                   	pop    %ebx
f010091c:	5e                   	pop    %esi
f010091d:	5f                   	pop    %edi
f010091e:	5d                   	pop    %ebp
f010091f:	c3                   	ret    

f0100920 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100920:	55                   	push   %ebp
f0100921:	89 e5                	mov    %esp,%ebp
f0100923:	57                   	push   %edi
f0100924:	56                   	push   %esi
f0100925:	53                   	push   %ebx
f0100926:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100929:	68 14 6e 10 f0       	push   $0xf0106e14
f010092e:	e8 17 2f 00 00       	call   f010384a <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100933:	c7 04 24 38 6e 10 f0 	movl   $0xf0106e38,(%esp)
f010093a:	e8 0b 2f 00 00       	call   f010384a <cprintf>

	if (tf != NULL)
f010093f:	83 c4 10             	add    $0x10,%esp
f0100942:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100946:	74 0e                	je     f0100956 <monitor+0x36>
		print_trapframe(tf);
f0100948:	83 ec 0c             	sub    $0xc,%esp
f010094b:	ff 75 08             	pushl  0x8(%ebp)
f010094e:	e8 13 31 00 00       	call   f0103a66 <print_trapframe>
f0100953:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100956:	83 ec 0c             	sub    $0xc,%esp
f0100959:	68 88 6c 10 f0       	push   $0xf0106c88
f010095e:	e8 50 48 00 00       	call   f01051b3 <readline>
f0100963:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100965:	83 c4 10             	add    $0x10,%esp
f0100968:	85 c0                	test   %eax,%eax
f010096a:	74 ea                	je     f0100956 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010096c:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100973:	be 00 00 00 00       	mov    $0x0,%esi
f0100978:	eb 0a                	jmp    f0100984 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010097a:	c6 03 00             	movb   $0x0,(%ebx)
f010097d:	89 f7                	mov    %esi,%edi
f010097f:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100982:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100984:	0f b6 03             	movzbl (%ebx),%eax
f0100987:	84 c0                	test   %al,%al
f0100989:	74 63                	je     f01009ee <monitor+0xce>
f010098b:	83 ec 08             	sub    $0x8,%esp
f010098e:	0f be c0             	movsbl %al,%eax
f0100991:	50                   	push   %eax
f0100992:	68 8c 6c 10 f0       	push   $0xf0106c8c
f0100997:	e8 49 4a 00 00       	call   f01053e5 <strchr>
f010099c:	83 c4 10             	add    $0x10,%esp
f010099f:	85 c0                	test   %eax,%eax
f01009a1:	75 d7                	jne    f010097a <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f01009a3:	80 3b 00             	cmpb   $0x0,(%ebx)
f01009a6:	74 46                	je     f01009ee <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01009a8:	83 fe 0f             	cmp    $0xf,%esi
f01009ab:	75 14                	jne    f01009c1 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01009ad:	83 ec 08             	sub    $0x8,%esp
f01009b0:	6a 10                	push   $0x10
f01009b2:	68 91 6c 10 f0       	push   $0xf0106c91
f01009b7:	e8 8e 2e 00 00       	call   f010384a <cprintf>
f01009bc:	83 c4 10             	add    $0x10,%esp
f01009bf:	eb 95                	jmp    f0100956 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f01009c1:	8d 7e 01             	lea    0x1(%esi),%edi
f01009c4:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01009c8:	eb 03                	jmp    f01009cd <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01009ca:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01009cd:	0f b6 03             	movzbl (%ebx),%eax
f01009d0:	84 c0                	test   %al,%al
f01009d2:	74 ae                	je     f0100982 <monitor+0x62>
f01009d4:	83 ec 08             	sub    $0x8,%esp
f01009d7:	0f be c0             	movsbl %al,%eax
f01009da:	50                   	push   %eax
f01009db:	68 8c 6c 10 f0       	push   $0xf0106c8c
f01009e0:	e8 00 4a 00 00       	call   f01053e5 <strchr>
f01009e5:	83 c4 10             	add    $0x10,%esp
f01009e8:	85 c0                	test   %eax,%eax
f01009ea:	74 de                	je     f01009ca <monitor+0xaa>
f01009ec:	eb 94                	jmp    f0100982 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f01009ee:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01009f5:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01009f6:	85 f6                	test   %esi,%esi
f01009f8:	0f 84 58 ff ff ff    	je     f0100956 <monitor+0x36>
f01009fe:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a03:	83 ec 08             	sub    $0x8,%esp
f0100a06:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a09:	ff 34 85 60 6e 10 f0 	pushl  -0xfef91a0(,%eax,4)
f0100a10:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a13:	e8 6f 49 00 00       	call   f0105387 <strcmp>
f0100a18:	83 c4 10             	add    $0x10,%esp
f0100a1b:	85 c0                	test   %eax,%eax
f0100a1d:	75 22                	jne    f0100a41 <monitor+0x121>
			return commands[i].func(argc, argv, tf);
f0100a1f:	83 ec 04             	sub    $0x4,%esp
f0100a22:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a25:	ff 75 08             	pushl  0x8(%ebp)
f0100a28:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a2b:	52                   	push   %edx
f0100a2c:	56                   	push   %esi
f0100a2d:	ff 14 85 68 6e 10 f0 	call   *-0xfef9198(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100a34:	83 c4 10             	add    $0x10,%esp
f0100a37:	85 c0                	test   %eax,%eax
f0100a39:	0f 89 17 ff ff ff    	jns    f0100956 <monitor+0x36>
f0100a3f:	eb 20                	jmp    f0100a61 <monitor+0x141>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100a41:	83 c3 01             	add    $0x1,%ebx
f0100a44:	83 fb 03             	cmp    $0x3,%ebx
f0100a47:	75 ba                	jne    f0100a03 <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a49:	83 ec 08             	sub    $0x8,%esp
f0100a4c:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a4f:	68 ae 6c 10 f0       	push   $0xf0106cae
f0100a54:	e8 f1 2d 00 00       	call   f010384a <cprintf>
f0100a59:	83 c4 10             	add    $0x10,%esp
f0100a5c:	e9 f5 fe ff ff       	jmp    f0100956 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a61:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a64:	5b                   	pop    %ebx
f0100a65:	5e                   	pop    %esi
f0100a66:	5f                   	pop    %edi
f0100a67:	5d                   	pop    %ebp
f0100a68:	c3                   	ret    

f0100a69 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100a69:	89 d1                	mov    %edx,%ecx
f0100a6b:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100a6e:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100a71:	a8 01                	test   $0x1,%al
f0100a73:	74 52                	je     f0100ac7 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a75:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a7a:	89 c1                	mov    %eax,%ecx
f0100a7c:	c1 e9 0c             	shr    $0xc,%ecx
f0100a7f:	3b 0d d8 6e 2a f0    	cmp    0xf02a6ed8,%ecx
f0100a85:	72 1b                	jb     f0100aa2 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a87:	55                   	push   %ebp
f0100a88:	89 e5                	mov    %esp,%ebp
f0100a8a:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a8d:	50                   	push   %eax
f0100a8e:	68 e4 68 10 f0       	push   $0xf01068e4
f0100a93:	68 10 04 00 00       	push   $0x410
f0100a98:	68 75 78 10 f0       	push   $0xf0107875
f0100a9d:	e8 9e f5 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100aa2:	c1 ea 0c             	shr    $0xc,%edx
f0100aa5:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100aab:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100ab2:	89 c2                	mov    %eax,%edx
f0100ab4:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100ab7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100abc:	85 d2                	test   %edx,%edx
f0100abe:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100ac3:	0f 44 c2             	cmove  %edx,%eax
f0100ac6:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100ac7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100acc:	c3                   	ret    

f0100acd <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100acd:	83 3d 5c 62 2a f0 00 	cmpl   $0x0,0xf02a625c
f0100ad4:	75 11                	jne    f0100ae7 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE); // Roundup function rounds according to the given functions
f0100ad6:	ba bf 0f 30 f0       	mov    $0xf0300fbf,%edx
f0100adb:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100ae1:	89 15 5c 62 2a f0    	mov    %edx,0xf02a625c
	}
	
	if (n==0){
f0100ae7:	85 c0                	test   %eax,%eax
f0100ae9:	75 06                	jne    f0100af1 <boot_alloc+0x24>
	return nextfree;
f0100aeb:	a1 5c 62 2a f0       	mov    0xf02a625c,%eax
f0100af0:	c3                   	ret    
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result  = nextfree;
f0100af1:	8b 0d 5c 62 2a f0    	mov    0xf02a625c,%ecx
	nextfree += ROUNDUP(n,PGSIZE);
f0100af7:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100afc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b01:	8d 14 01             	lea    (%ecx,%eax,1),%edx
f0100b04:	89 15 5c 62 2a f0    	mov    %edx,0xf02a625c
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100b0a:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0100b10:	77 18                	ja     f0100b2a <boot_alloc+0x5d>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100b12:	55                   	push   %ebp
f0100b13:	89 e5                	mov    %esp,%ebp
f0100b15:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100b18:	52                   	push   %edx
f0100b19:	68 08 69 10 f0       	push   $0xf0106908
f0100b1e:	6a 71                	push   $0x71
f0100b20:	68 75 78 10 f0       	push   $0xf0107875
f0100b25:	e8 16 f5 ff ff       	call   f0100040 <_panic>
	// LAB 2: Your code here.
	result  = nextfree;
	nextfree += ROUNDUP(n,PGSIZE);
	
	
	if ((PADDR(nextfree))>npages*PGSIZE){
f0100b2a:	a1 d8 6e 2a f0       	mov    0xf02a6ed8,%eax
f0100b2f:	c1 e0 0c             	shl    $0xc,%eax
	return (physaddr_t)kva - KERNBASE;
f0100b32:	81 c2 00 00 00 10    	add    $0x10000000,%edx
		return 0;
	}
	return result;
f0100b38:	39 c2                	cmp    %eax,%edx
f0100b3a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b3f:	0f 46 c1             	cmovbe %ecx,%eax
}
f0100b42:	c3                   	ret    

f0100b43 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100b43:	55                   	push   %ebp
f0100b44:	89 e5                	mov    %esp,%ebp
f0100b46:	57                   	push   %edi
f0100b47:	56                   	push   %esi
f0100b48:	53                   	push   %ebx
f0100b49:	83 ec 3c             	sub    $0x3c,%esp
f0100b4c:	89 45 c0             	mov    %eax,-0x40(%ebp)
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b4f:	84 c0                	test   %al,%al
f0100b51:	0f 85 b1 02 00 00    	jne    f0100e08 <check_page_free_list+0x2c5>
f0100b57:	e9 be 02 00 00       	jmp    f0100e1a <check_page_free_list+0x2d7>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100b5c:	83 ec 04             	sub    $0x4,%esp
f0100b5f:	68 84 6e 10 f0       	push   $0xf0106e84
f0100b64:	68 44 03 00 00       	push   $0x344
f0100b69:	68 75 78 10 f0       	push   $0xf0107875
f0100b6e:	e8 cd f4 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100b73:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100b76:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100b79:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b7c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b7f:	89 c2                	mov    %eax,%edx
f0100b81:	2b 15 e0 6e 2a f0    	sub    0xf02a6ee0,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100b87:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100b8d:	0f 95 c2             	setne  %dl
f0100b90:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100b93:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100b97:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100b99:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b9d:	8b 00                	mov    (%eax),%eax
f0100b9f:	85 c0                	test   %eax,%eax
f0100ba1:	75 dc                	jne    f0100b7f <check_page_free_list+0x3c>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100ba3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ba6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100bac:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100baf:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100bb2:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100bb4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100bb7:	a3 64 62 2a f0       	mov    %eax,0xf02a6264
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bbc:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bc1:	8b 1d 64 62 2a f0    	mov    0xf02a6264,%ebx
f0100bc7:	eb 53                	jmp    f0100c1c <check_page_free_list+0xd9>
f0100bc9:	89 d8                	mov    %ebx,%eax
f0100bcb:	2b 05 e0 6e 2a f0    	sub    0xf02a6ee0,%eax
f0100bd1:	c1 f8 03             	sar    $0x3,%eax
f0100bd4:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100bd7:	89 c2                	mov    %eax,%edx
f0100bd9:	c1 ea 16             	shr    $0x16,%edx
f0100bdc:	39 f2                	cmp    %esi,%edx
f0100bde:	73 3a                	jae    f0100c1a <check_page_free_list+0xd7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100be0:	89 c2                	mov    %eax,%edx
f0100be2:	c1 ea 0c             	shr    $0xc,%edx
f0100be5:	3b 15 d8 6e 2a f0    	cmp    0xf02a6ed8,%edx
f0100beb:	72 12                	jb     f0100bff <check_page_free_list+0xbc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bed:	50                   	push   %eax
f0100bee:	68 e4 68 10 f0       	push   $0xf01068e4
f0100bf3:	6a 58                	push   $0x58
f0100bf5:	68 81 78 10 f0       	push   $0xf0107881
f0100bfa:	e8 41 f4 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100bff:	83 ec 04             	sub    $0x4,%esp
f0100c02:	68 80 00 00 00       	push   $0x80
f0100c07:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100c0c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c11:	50                   	push   %eax
f0100c12:	e8 0b 48 00 00       	call   f0105422 <memset>
f0100c17:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c1a:	8b 1b                	mov    (%ebx),%ebx
f0100c1c:	85 db                	test   %ebx,%ebx
f0100c1e:	75 a9                	jne    f0100bc9 <check_page_free_list+0x86>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100c20:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c25:	e8 a3 fe ff ff       	call   f0100acd <boot_alloc>
f0100c2a:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c2d:	8b 15 64 62 2a f0    	mov    0xf02a6264,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c33:	8b 0d e0 6e 2a f0    	mov    0xf02a6ee0,%ecx
		assert(pp < pages + npages);
f0100c39:	a1 d8 6e 2a f0       	mov    0xf02a6ed8,%eax
f0100c3e:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100c41:	8d 34 c1             	lea    (%ecx,%eax,8),%esi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c44:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c47:	bf 00 00 00 00       	mov    $0x0,%edi
f0100c4c:	89 5d cc             	mov    %ebx,-0x34(%ebp)
f0100c4f:	89 f0                	mov    %esi,%eax
f0100c51:	89 ce                	mov    %ecx,%esi
f0100c53:	89 c1                	mov    %eax,%ecx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c55:	e9 55 01 00 00       	jmp    f0100daf <check_page_free_list+0x26c>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c5a:	39 f2                	cmp    %esi,%edx
f0100c5c:	73 19                	jae    f0100c77 <check_page_free_list+0x134>
f0100c5e:	68 8f 78 10 f0       	push   $0xf010788f
f0100c63:	68 9b 78 10 f0       	push   $0xf010789b
f0100c68:	68 5e 03 00 00       	push   $0x35e
f0100c6d:	68 75 78 10 f0       	push   $0xf0107875
f0100c72:	e8 c9 f3 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100c77:	39 ca                	cmp    %ecx,%edx
f0100c79:	72 19                	jb     f0100c94 <check_page_free_list+0x151>
f0100c7b:	68 b0 78 10 f0       	push   $0xf01078b0
f0100c80:	68 9b 78 10 f0       	push   $0xf010789b
f0100c85:	68 5f 03 00 00       	push   $0x35f
f0100c8a:	68 75 78 10 f0       	push   $0xf0107875
f0100c8f:	e8 ac f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c94:	89 d0                	mov    %edx,%eax
f0100c96:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100c99:	a8 07                	test   $0x7,%al
f0100c9b:	74 19                	je     f0100cb6 <check_page_free_list+0x173>
f0100c9d:	68 a8 6e 10 f0       	push   $0xf0106ea8
f0100ca2:	68 9b 78 10 f0       	push   $0xf010789b
f0100ca7:	68 60 03 00 00       	push   $0x360
f0100cac:	68 75 78 10 f0       	push   $0xf0107875
f0100cb1:	e8 8a f3 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100cb6:	c1 f8 03             	sar    $0x3,%eax
f0100cb9:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100cbc:	85 c0                	test   %eax,%eax
f0100cbe:	75 19                	jne    f0100cd9 <check_page_free_list+0x196>
f0100cc0:	68 c4 78 10 f0       	push   $0xf01078c4
f0100cc5:	68 9b 78 10 f0       	push   $0xf010789b
f0100cca:	68 63 03 00 00       	push   $0x363
f0100ccf:	68 75 78 10 f0       	push   $0xf0107875
f0100cd4:	e8 67 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100cd9:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100cde:	75 19                	jne    f0100cf9 <check_page_free_list+0x1b6>
f0100ce0:	68 d5 78 10 f0       	push   $0xf01078d5
f0100ce5:	68 9b 78 10 f0       	push   $0xf010789b
f0100cea:	68 64 03 00 00       	push   $0x364
f0100cef:	68 75 78 10 f0       	push   $0xf0107875
f0100cf4:	e8 47 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cf9:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100cfe:	75 19                	jne    f0100d19 <check_page_free_list+0x1d6>
f0100d00:	68 dc 6e 10 f0       	push   $0xf0106edc
f0100d05:	68 9b 78 10 f0       	push   $0xf010789b
f0100d0a:	68 65 03 00 00       	push   $0x365
f0100d0f:	68 75 78 10 f0       	push   $0xf0107875
f0100d14:	e8 27 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d19:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100d1e:	75 19                	jne    f0100d39 <check_page_free_list+0x1f6>
f0100d20:	68 ee 78 10 f0       	push   $0xf01078ee
f0100d25:	68 9b 78 10 f0       	push   $0xf010789b
f0100d2a:	68 66 03 00 00       	push   $0x366
f0100d2f:	68 75 78 10 f0       	push   $0xf0107875
f0100d34:	e8 07 f3 ff ff       	call   f0100040 <_panic>
f0100d39:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d3c:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d41:	0f 86 ea 00 00 00    	jbe    f0100e31 <check_page_free_list+0x2ee>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d47:	89 c3                	mov    %eax,%ebx
f0100d49:	c1 eb 0c             	shr    $0xc,%ebx
f0100d4c:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f0100d4f:	77 12                	ja     f0100d63 <check_page_free_list+0x220>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d51:	50                   	push   %eax
f0100d52:	68 e4 68 10 f0       	push   $0xf01068e4
f0100d57:	6a 58                	push   $0x58
f0100d59:	68 81 78 10 f0       	push   $0xf0107881
f0100d5e:	e8 dd f2 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100d63:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
f0100d69:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100d6c:	0f 86 cf 00 00 00    	jbe    f0100e41 <check_page_free_list+0x2fe>
f0100d72:	68 00 6f 10 f0       	push   $0xf0106f00
f0100d77:	68 9b 78 10 f0       	push   $0xf010789b
f0100d7c:	68 67 03 00 00       	push   $0x367
f0100d81:	68 75 78 10 f0       	push   $0xf0107875
f0100d86:	e8 b5 f2 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100d8b:	68 08 79 10 f0       	push   $0xf0107908
f0100d90:	68 9b 78 10 f0       	push   $0xf010789b
f0100d95:	68 69 03 00 00       	push   $0x369
f0100d9a:	68 75 78 10 f0       	push   $0xf0107875
f0100d9f:	e8 9c f2 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100da4:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0100da8:	eb 03                	jmp    f0100dad <check_page_free_list+0x26a>
		else
			++nfree_extmem;
f0100daa:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100dad:	8b 12                	mov    (%edx),%edx
f0100daf:	85 d2                	test   %edx,%edx
f0100db1:	0f 85 a3 fe ff ff    	jne    f0100c5a <check_page_free_list+0x117>
f0100db7:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100dba:	85 db                	test   %ebx,%ebx
f0100dbc:	7f 19                	jg     f0100dd7 <check_page_free_list+0x294>
f0100dbe:	68 25 79 10 f0       	push   $0xf0107925
f0100dc3:	68 9b 78 10 f0       	push   $0xf010789b
f0100dc8:	68 71 03 00 00       	push   $0x371
f0100dcd:	68 75 78 10 f0       	push   $0xf0107875
f0100dd2:	e8 69 f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100dd7:	85 ff                	test   %edi,%edi
f0100dd9:	7f 19                	jg     f0100df4 <check_page_free_list+0x2b1>
f0100ddb:	68 37 79 10 f0       	push   $0xf0107937
f0100de0:	68 9b 78 10 f0       	push   $0xf010789b
f0100de5:	68 72 03 00 00       	push   $0x372
f0100dea:	68 75 78 10 f0       	push   $0xf0107875
f0100def:	e8 4c f2 ff ff       	call   f0100040 <_panic>
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
f0100df4:	83 ec 08             	sub    $0x8,%esp
f0100df7:	0f b6 45 c0          	movzbl -0x40(%ebp),%eax
f0100dfb:	50                   	push   %eax
f0100dfc:	68 48 6f 10 f0       	push   $0xf0106f48
f0100e01:	e8 44 2a 00 00       	call   f010384a <cprintf>
f0100e06:	eb 49                	jmp    f0100e51 <check_page_free_list+0x30e>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100e08:	a1 64 62 2a f0       	mov    0xf02a6264,%eax
f0100e0d:	85 c0                	test   %eax,%eax
f0100e0f:	0f 85 5e fd ff ff    	jne    f0100b73 <check_page_free_list+0x30>
f0100e15:	e9 42 fd ff ff       	jmp    f0100b5c <check_page_free_list+0x19>
f0100e1a:	83 3d 64 62 2a f0 00 	cmpl   $0x0,0xf02a6264
f0100e21:	0f 84 35 fd ff ff    	je     f0100b5c <check_page_free_list+0x19>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e27:	be 00 04 00 00       	mov    $0x400,%esi
f0100e2c:	e9 90 fd ff ff       	jmp    f0100bc1 <check_page_free_list+0x7e>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100e31:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e36:	0f 85 68 ff ff ff    	jne    f0100da4 <check_page_free_list+0x261>
f0100e3c:	e9 4a ff ff ff       	jmp    f0100d8b <check_page_free_list+0x248>
f0100e41:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e46:	0f 85 5e ff ff ff    	jne    f0100daa <check_page_free_list+0x267>
f0100e4c:	e9 3a ff ff ff       	jmp    f0100d8b <check_page_free_list+0x248>
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
}
f0100e51:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e54:	5b                   	pop    %ebx
f0100e55:	5e                   	pop    %esi
f0100e56:	5f                   	pop    %edi
f0100e57:	5d                   	pop    %ebp
f0100e58:	c3                   	ret    

f0100e59 <page_init>:
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100e59:	b8 01 00 00 00       	mov    $0x1,%eax
f0100e5e:	eb 18                	jmp    f0100e78 <page_init+0x1f>
	{
	 pages[i].pp_ref = 1; //Used Pages
f0100e60:	8b 15 e0 6e 2a f0    	mov    0xf02a6ee0,%edx
f0100e66:	8d 14 c2             	lea    (%edx,%eax,8),%edx
f0100e69:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
	 pages[i].pp_link = 0; // No links to any pages
f0100e6f:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100e75:	83 c0 01             	add    $0x1,%eax
f0100e78:	3b 05 d8 6e 2a f0    	cmp    0xf02a6ed8,%eax
f0100e7e:	72 e0                	jb     f0100e60 <page_init+0x7>
//


void
page_init(void)
{
f0100e80:	55                   	push   %ebp
f0100e81:	89 e5                	mov    %esp,%ebp
f0100e83:	57                   	push   %edi
f0100e84:	56                   	push   %esi
f0100e85:	53                   	push   %ebx
f0100e86:	83 ec 0c             	sub    $0xc,%esp
	//Modification for Lab 4, We have to skip the Page that MPENTRY_PADDR is at from the page_free_list
	//Hence we can divide it with PGSIZE and whatever is the value, just skip that page. 
	size_t mpentyPg = MPENTRY_PADDR/PGSIZE;

	// 2. The rest of base memory 
	page_free_list = 0 ;
f0100e89:	c7 05 64 62 2a f0 00 	movl   $0x0,0xf02a6264
f0100e90:	00 00 00 
	
	struct PageInfo *prev = 0;
	for (i = 1; i < npages_basemem; ++i) {
f0100e93:	be 00 00 00 00       	mov    $0x0,%esi
	size_t mpentyPg = MPENTRY_PADDR/PGSIZE;

	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	struct PageInfo *prev = 0;
f0100e98:	bf 00 00 00 00       	mov    $0x0,%edi
	for (i = 1; i < npages_basemem; ++i) {
f0100e9d:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100ea2:	eb 71                	jmp    f0100f15 <page_init+0xbc>
		if (i == mpentyPg) {
f0100ea4:	83 fb 07             	cmp    $0x7,%ebx
f0100ea7:	75 14                	jne    f0100ebd <page_init+0x64>
			cprintf("Skipped this page %d\n", i);
f0100ea9:	83 ec 08             	sub    $0x8,%esp
f0100eac:	6a 07                	push   $0x7
f0100eae:	68 48 79 10 f0       	push   $0xf0107948
f0100eb3:	e8 92 29 00 00       	call   f010384a <cprintf>
			continue;	
f0100eb8:	83 c4 10             	add    $0x10,%esp
f0100ebb:	eb 52                	jmp    f0100f0f <page_init+0xb6>
f0100ebd:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
		}

		pages[i].pp_ref = 0;
f0100ec4:	8b 15 e0 6e 2a f0    	mov    0xf02a6ee0,%edx
f0100eca:	66 c7 44 02 04 00 00 	movw   $0x0,0x4(%edx,%eax,1)
		pages[i].pp_link = 0;
f0100ed1:	c7 04 da 00 00 00 00 	movl   $0x0,(%edx,%ebx,8)
		if (!page_free_list) {
f0100ed8:	83 3d 64 62 2a f0 00 	cmpl   $0x0,0xf02a6264
f0100edf:	75 10                	jne    f0100ef1 <page_init+0x98>
			page_free_list = &pages[i];
f0100ee1:	89 c2                	mov    %eax,%edx
f0100ee3:	03 15 e0 6e 2a f0    	add    0xf02a6ee0,%edx
f0100ee9:	89 15 64 62 2a f0    	mov    %edx,0xf02a6264
f0100eef:	eb 16                	jmp    f0100f07 <page_init+0xae>
		} else {
			prev->pp_link = &pages[i];
f0100ef1:	89 c2                	mov    %eax,%edx
f0100ef3:	03 15 e0 6e 2a f0    	add    0xf02a6ee0,%edx
f0100ef9:	89 17                	mov    %edx,(%edi)
			pages[i-1].pp_link = &pages[i];
f0100efb:	8b 15 e0 6e 2a f0    	mov    0xf02a6ee0,%edx
f0100f01:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
f0100f04:	89 0c 32             	mov    %ecx,(%edx,%esi,1)
		}
		prev = &pages[i];
f0100f07:	03 05 e0 6e 2a f0    	add    0xf02a6ee0,%eax
f0100f0d:	89 c7                	mov    %eax,%edi

	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	struct PageInfo *prev = 0;
	for (i = 1; i < npages_basemem; ++i) {
f0100f0f:	83 c3 01             	add    $0x1,%ebx
f0100f12:	83 c6 08             	add    $0x8,%esi
f0100f15:	3b 1d 68 62 2a f0    	cmp    0xf02a6268,%ebx
f0100f1b:	72 87                	jb     f0100ea4 <page_init+0x4b>
		prev = &pages[i];
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
f0100f1d:	8d 04 dd f8 ff ff ff 	lea    -0x8(,%ebx,8),%eax
f0100f24:	03 05 e0 6e 2a f0    	add    0xf02a6ee0,%eax
f0100f2a:	a3 58 62 2a f0       	mov    %eax,0xf02a6258
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100f2f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f34:	e8 94 fb ff ff       	call   f0100acd <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100f39:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100f3e:	77 15                	ja     f0100f55 <page_init+0xfc>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100f40:	50                   	push   %eax
f0100f41:	68 08 69 10 f0       	push   $0xf0106908
f0100f46:	68 75 01 00 00       	push   $0x175
f0100f4b:	68 75 78 10 f0       	push   $0xf0107875
f0100f50:	e8 eb f0 ff ff       	call   f0100040 <_panic>
f0100f55:	05 ff 0f 00 10       	add    $0x10000fff,%eax
f0100f5a:	c1 e8 0c             	shr    $0xc,%eax
f0100f5d:	8b 1d 58 62 2a f0    	mov    0xf02a6258,%ebx
f0100f63:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100f6a:	eb 2c                	jmp    f0100f98 <page_init+0x13f>
		pages[i].pp_ref = 0;
f0100f6c:	89 d1                	mov    %edx,%ecx
f0100f6e:	03 0d e0 6e 2a f0    	add    0xf02a6ee0,%ecx
f0100f74:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = 0;
f0100f7a:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		track->pp_link = &pages[i];
f0100f80:	89 d1                	mov    %edx,%ecx
f0100f82:	03 0d e0 6e 2a f0    	add    0xf02a6ee0,%ecx
f0100f88:	89 0b                	mov    %ecx,(%ebx)
		track = &pages[i];
f0100f8a:	89 d3                	mov    %edx,%ebx
f0100f8c:	03 1d e0 6e 2a f0    	add    0xf02a6ee0,%ebx
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100f92:	83 c0 01             	add    $0x1,%eax
f0100f95:	83 c2 08             	add    $0x8,%edx
f0100f98:	3b 05 d8 6e 2a f0    	cmp    0xf02a6ed8,%eax
f0100f9e:	72 cc                	jb     f0100f6c <page_init+0x113>
f0100fa0:	89 1d 58 62 2a f0    	mov    %ebx,0xf02a6258
		pages[i].pp_link = 0;
		track->pp_link = &pages[i];
		track = &pages[i];
	}
	
	cprintf("Check first entry of pages &pages[0] = %x\n", &pages[0]);
f0100fa6:	83 ec 08             	sub    $0x8,%esp
f0100fa9:	ff 35 e0 6e 2a f0    	pushl  0xf02a6ee0
f0100faf:	68 70 6f 10 f0       	push   $0xf0106f70
f0100fb4:	e8 91 28 00 00       	call   f010384a <cprintf>
	cprintf("&pages[npages-1] = %x\n", &pages[npages-1]);
f0100fb9:	83 c4 08             	add    $0x8,%esp
f0100fbc:	a1 d8 6e 2a f0       	mov    0xf02a6ed8,%eax
f0100fc1:	8d 04 c5 f8 ff ff ff 	lea    -0x8(,%eax,8),%eax
f0100fc8:	03 05 e0 6e 2a f0    	add    0xf02a6ee0,%eax
f0100fce:	50                   	push   %eax
f0100fcf:	68 5e 79 10 f0       	push   $0xf010795e
f0100fd4:	e8 71 28 00 00       	call   f010384a <cprintf>
f0100fd9:	83 c4 10             	add    $0x10,%esp
}
f0100fdc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fdf:	5b                   	pop    %ebx
f0100fe0:	5e                   	pop    %esi
f0100fe1:	5f                   	pop    %edi
f0100fe2:	5d                   	pop    %ebp
f0100fe3:	c3                   	ret    

f0100fe4 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100fe4:	55                   	push   %ebp
f0100fe5:	89 e5                	mov    %esp,%ebp
f0100fe7:	53                   	push   %ebx
f0100fe8:	83 ec 04             	sub    $0x4,%esp
	// Check if there is a free_page available 
	if (!page_free_list)
f0100feb:	8b 1d 64 62 2a f0    	mov    0xf02a6264,%ebx
f0100ff1:	85 db                	test   %ebx,%ebx
f0100ff3:	74 5e                	je     f0101053 <page_alloc+0x6f>
	return NULL;
	}
	
	struct PageInfo *allocPage = NULL;   //Create a temporary pointer 
	allocPage = page_free_list;	//Point to the current head of free_page_list
	page_free_list = allocPage ->pp_link; //Move the head to the next avaialble page
f0100ff5:	8b 03                	mov    (%ebx),%eax
f0100ff7:	a3 64 62 2a f0       	mov    %eax,0xf02a6264
	allocPage->pp_link = NULL;	//Break the link 
f0100ffc:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags && ALLOC_ZERO){		//ALLOC_ZERO = 1<<0; which is nothing but  = 1
f0101002:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0101006:	74 45                	je     f010104d <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101008:	89 d8                	mov    %ebx,%eax
f010100a:	2b 05 e0 6e 2a f0    	sub    0xf02a6ee0,%eax
f0101010:	c1 f8 03             	sar    $0x3,%eax
f0101013:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101016:	89 c2                	mov    %eax,%edx
f0101018:	c1 ea 0c             	shr    $0xc,%edx
f010101b:	3b 15 d8 6e 2a f0    	cmp    0xf02a6ed8,%edx
f0101021:	72 12                	jb     f0101035 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101023:	50                   	push   %eax
f0101024:	68 e4 68 10 f0       	push   $0xf01068e4
f0101029:	6a 58                	push   $0x58
f010102b:	68 81 78 10 f0       	push   $0xf0107881
f0101030:	e8 0b f0 ff ff       	call   f0100040 <_panic>
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
f0101035:	83 ec 04             	sub    $0x4,%esp
f0101038:	68 00 10 00 00       	push   $0x1000
f010103d:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f010103f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101044:	50                   	push   %eax
f0101045:	e8 d8 43 00 00       	call   f0105422 <memset>
f010104a:	83 c4 10             	add    $0x10,%esp
	}
	
	allocPage->pp_ref = 0;
f010104d:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return allocPage;
}
f0101053:	89 d8                	mov    %ebx,%eax
f0101055:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101058:	c9                   	leave  
f0101059:	c3                   	ret    

f010105a <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f010105a:	55                   	push   %ebp
f010105b:	89 e5                	mov    %esp,%ebp
f010105d:	83 ec 08             	sub    $0x8,%esp
f0101060:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	
	if(pp->pp_ref)
f0101063:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101068:	74 17                	je     f0101081 <page_free+0x27>
	{
	panic("Page cannot be returned to free list, as it is still refernced ");
f010106a:	83 ec 04             	sub    $0x4,%esp
f010106d:	68 9c 6f 10 f0       	push   $0xf0106f9c
f0101072:	68 ad 01 00 00       	push   $0x1ad
f0101077:	68 75 78 10 f0       	push   $0xf0107875
f010107c:	e8 bf ef ff ff       	call   f0100040 <_panic>
	return;
	}
	
	// pp->pp_link is not NULL.
	else if(!pp) 
f0101081:	85 c0                	test   %eax,%eax
f0101083:	75 17                	jne    f010109c <page_free+0x42>
	{
	panic("Page cannot be returned to free list as it is Null");
f0101085:	83 ec 04             	sub    $0x4,%esp
f0101088:	68 dc 6f 10 f0       	push   $0xf0106fdc
f010108d:	68 b4 01 00 00       	push   $0x1b4
f0101092:	68 75 78 10 f0       	push   $0xf0107875
f0101097:	e8 a4 ef ff ff       	call   f0100040 <_panic>
	return;
	}
	
       else{
	pp->pp_link = page_free_list;
f010109c:	8b 15 64 62 2a f0    	mov    0xf02a6264,%edx
f01010a2:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f01010a4:	a3 64 62 2a f0       	mov    %eax,0xf02a6264
	}


}
f01010a9:	c9                   	leave  
f01010aa:	c3                   	ret    

f01010ab <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f01010ab:	55                   	push   %ebp
f01010ac:	89 e5                	mov    %esp,%ebp
f01010ae:	83 ec 08             	sub    $0x8,%esp
f01010b1:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f01010b4:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f01010b8:	83 e8 01             	sub    $0x1,%eax
f01010bb:	66 89 42 04          	mov    %ax,0x4(%edx)
f01010bf:	66 85 c0             	test   %ax,%ax
f01010c2:	75 0c                	jne    f01010d0 <page_decref+0x25>
		page_free(pp);
f01010c4:	83 ec 0c             	sub    $0xc,%esp
f01010c7:	52                   	push   %edx
f01010c8:	e8 8d ff ff ff       	call   f010105a <page_free>
f01010cd:	83 c4 10             	add    $0x10,%esp
}
f01010d0:	c9                   	leave  
f01010d1:	c3                   	ret    

f01010d2 <pgdir_walk>:
// table and page directory entries.
//

pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01010d2:	55                   	push   %ebp
f01010d3:	89 e5                	mov    %esp,%ebp
f01010d5:	57                   	push   %edi
f01010d6:	56                   	push   %esi
f01010d7:	53                   	push   %ebx
f01010d8:	83 ec 0c             	sub    $0xc,%esp
	pte_t *pgTab;  //Page Table index variable

	//To find the index from the pgdir we need to get the MS 10 bits,
	//We get the MS 10bits of the virtual address by using PDX function (found in inc/mmu.h ) 
	//#define PDX(la)		((((uintptr_t) (la)) >> PDXSHIFT) & 0x3FF)
	pgDir = &pgdir[PDX(va)];
f01010db:	8b 75 0c             	mov    0xc(%ebp),%esi
f01010de:	c1 ee 16             	shr    $0x16,%esi
f01010e1:	c1 e6 02             	shl    $0x2,%esi
f01010e4:	03 75 08             	add    0x8(%ebp),%esi

	// Check if page is present, PTE_P = 0x1 means page present  
	if (*pgDir & PTE_P)  {
f01010e7:	8b 1e                	mov    (%esi),%ebx
f01010e9:	f6 c3 01             	test   $0x1,%bl
f01010ec:	74 30                	je     f010111e <pgdir_walk+0x4c>
		//page table entry to get to the final address translation. Now using the pgDir we can use the 
		//PTE_ADDR(pde) function to get the upper 20 bits, but this function returns a physical address. 
		//Since the kernel requires a virtual address, we can use the function KADDR to get the virtual 
		//address.
		
		pgTab = (pte_t*) KADDR(PTE_ADDR(*pgDir));
f01010ee:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010f4:	89 d8                	mov    %ebx,%eax
f01010f6:	c1 e8 0c             	shr    $0xc,%eax
f01010f9:	3b 05 d8 6e 2a f0    	cmp    0xf02a6ed8,%eax
f01010ff:	72 15                	jb     f0101116 <pgdir_walk+0x44>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101101:	53                   	push   %ebx
f0101102:	68 e4 68 10 f0       	push   $0xf01068e4
f0101107:	68 f5 01 00 00       	push   $0x1f5
f010110c:	68 75 78 10 f0       	push   $0xf0107875
f0101111:	e8 2a ef ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101116:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
f010111c:	eb 7c                	jmp    f010119a <pgdir_walk+0xc8>
	//If page is not present 
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
f010111e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101122:	0f 84 81 00 00 00    	je     f01011a9 <pgdir_walk+0xd7>
f0101128:	83 ec 0c             	sub    $0xc,%esp
f010112b:	68 00 10 00 00       	push   $0x1000
f0101130:	e8 af fe ff ff       	call   f0100fe4 <page_alloc>
f0101135:	89 c7                	mov    %eax,%edi
f0101137:	83 c4 10             	add    $0x10,%esp
f010113a:	85 c0                	test   %eax,%eax
f010113c:	74 72                	je     f01011b0 <pgdir_walk+0xde>
			return 0;
		}

		newPage->pp_ref++;  //Increment the ref pointer of the page 
f010113e:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101143:	89 c3                	mov    %eax,%ebx
f0101145:	2b 1d e0 6e 2a f0    	sub    0xf02a6ee0,%ebx
f010114b:	c1 fb 03             	sar    $0x3,%ebx
f010114e:	c1 e3 0c             	shl    $0xc,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101151:	89 d8                	mov    %ebx,%eax
f0101153:	c1 e8 0c             	shr    $0xc,%eax
f0101156:	3b 05 d8 6e 2a f0    	cmp    0xf02a6ed8,%eax
f010115c:	72 12                	jb     f0101170 <pgdir_walk+0x9e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010115e:	53                   	push   %ebx
f010115f:	68 e4 68 10 f0       	push   $0xf01068e4
f0101164:	6a 58                	push   $0x58
f0101166:	68 81 78 10 f0       	push   $0xf0107881
f010116b:	e8 d0 ee ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101170:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
		//Now this section creates the bindings and updates all the flags 
		//for relevant use of the page.
		
		//First create a link on the pgTab wrt to the new page
		pgTab = (pte_t*)page2kva(newPage); // this function gets the virtual address of the new page
		memset (pgTab, 0, PGSIZE); //Clear the entire page
f0101176:	83 ec 04             	sub    $0x4,%esp
f0101179:	68 00 10 00 00       	push   $0x1000
f010117e:	6a 00                	push   $0x0
f0101180:	53                   	push   %ebx
f0101181:	e8 9c 42 00 00       	call   f0105422 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101186:	2b 3d e0 6e 2a f0    	sub    0xf02a6ee0,%edi
f010118c:	c1 ff 03             	sar    $0x3,%edi
f010118f:	c1 e7 0c             	shl    $0xc,%edi

		//Page Table, pgTab contains the virtual address , now we need to set the permission bits.
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
f0101192:	83 cf 07             	or     $0x7,%edi
f0101195:	89 3e                	mov    %edi,(%esi)
f0101197:	83 c4 10             	add    $0x10,%esp
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
f010119a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010119d:	c1 e8 0a             	shr    $0xa,%eax
f01011a0:	25 fc 0f 00 00       	and    $0xffc,%eax
f01011a5:	01 d8                	add    %ebx,%eax
f01011a7:	eb 0c                	jmp    f01011b5 <pgdir_walk+0xe3>
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
			return 0;
f01011a9:	b8 00 00 00 00       	mov    $0x0,%eax
f01011ae:	eb 05                	jmp    f01011b5 <pgdir_walk+0xe3>
f01011b0:	b8 00 00 00 00       	mov    $0x0,%eax
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
}
f01011b5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011b8:	5b                   	pop    %ebx
f01011b9:	5e                   	pop    %esi
f01011ba:	5f                   	pop    %edi
f01011bb:	5d                   	pop    %ebp
f01011bc:	c3                   	ret    

f01011bd <boot_map_region>:
//
// Hint: the TA solution uses pgdir_walk

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01011bd:	55                   	push   %ebp
f01011be:	89 e5                	mov    %esp,%ebp
f01011c0:	57                   	push   %edi
f01011c1:	56                   	push   %esi
f01011c2:	53                   	push   %ebx
f01011c3:	83 ec 1c             	sub    $0x1c,%esp
f01011c6:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f01011c9:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
f01011cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01011d2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	size = ROUNDUP(size, PGSIZE); 
f01011d7:	8d b9 ff 0f 00 00    	lea    0xfff(%ecx),%edi
f01011dd:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f01011e3:	89 d3                	mov    %edx,%ebx
f01011e5:	29 d0                	sub    %edx,%eax
f01011e7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01011ea:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011ed:	83 c8 01             	or     $0x1,%eax
f01011f0:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f01011f3:	eb 3d                	jmp    f0101232 <boot_map_region+0x75>
		if (!(pgTbEnt = pgdir_walk(pgdir, (const void*)vaBegin, 1))){
f01011f5:	83 ec 04             	sub    $0x4,%esp
f01011f8:	6a 01                	push   $0x1
f01011fa:	53                   	push   %ebx
f01011fb:	ff 75 e0             	pushl  -0x20(%ebp)
f01011fe:	e8 cf fe ff ff       	call   f01010d2 <pgdir_walk>
f0101203:	83 c4 10             	add    $0x10,%esp
f0101206:	85 c0                	test   %eax,%eax
f0101208:	75 17                	jne    f0101221 <boot_map_region+0x64>
			panic("Cannot find page for the page table entry, from boot_map_region function");
f010120a:	83 ec 04             	sub    $0x4,%esp
f010120d:	68 10 70 10 f0       	push   $0xf0107010
f0101212:	68 2b 02 00 00       	push   $0x22b
f0101217:	68 75 78 10 f0       	push   $0xf0107875
f010121c:	e8 1f ee ff ff       	call   f0100040 <_panic>
		}
		//if (*pgTbEnt & PTE_P)
		//	panic("Page is already mapped");
		
		
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
f0101221:	0b 75 dc             	or     -0x24(%ebp),%esi
f0101224:	89 30                	mov    %esi,(%eax)
		vaBegin += PGSIZE;
f0101226:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		paBegin += PGSIZE; 
		size -= PGSIZE;
f010122c:	81 ef 00 10 00 00    	sub    $0x1000,%edi
f0101232:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101235:	8d 34 18             	lea    (%eax,%ebx,1),%esi
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f0101238:	85 ff                	test   %edi,%edi
f010123a:	75 b9                	jne    f01011f5 <boot_map_region+0x38>
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
		vaBegin += PGSIZE;
		paBegin += PGSIZE; 
		size -= PGSIZE;
	} 	
}
f010123c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010123f:	5b                   	pop    %ebx
f0101240:	5e                   	pop    %esi
f0101241:	5f                   	pop    %edi
f0101242:	5d                   	pop    %ebp
f0101243:	c3                   	ret    

f0101244 <page_lookup>:
// Hint: the TA solution uses pgdir_walk and pa2page.
//

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101244:	55                   	push   %ebp
f0101245:	89 e5                	mov    %esp,%ebp
f0101247:	53                   	push   %ebx
f0101248:	83 ec 08             	sub    $0x8,%esp
f010124b:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
	pgTbEty = pgdir_walk(pgdir, va, 0);
f010124e:	6a 00                	push   $0x0
f0101250:	ff 75 0c             	pushl  0xc(%ebp)
f0101253:	ff 75 08             	pushl  0x8(%ebp)
f0101256:	e8 77 fe ff ff       	call   f01010d2 <pgdir_walk>
f010125b:	89 c1                	mov    %eax,%ecx
	if (pgTbEty && (*pgTbEty & PTE_P)) {
f010125d:	83 c4 10             	add    $0x10,%esp
f0101260:	85 c0                	test   %eax,%eax
f0101262:	74 1a                	je     f010127e <page_lookup+0x3a>
f0101264:	8b 10                	mov    (%eax),%edx
f0101266:	f6 c2 01             	test   $0x1,%dl
f0101269:	74 1a                	je     f0101285 <page_lookup+0x41>
		ret = pages + (PTE_ADDR(*pgTbEty) >> PTXSHIFT);
f010126b:	c1 ea 0c             	shr    $0xc,%edx
f010126e:	a1 e0 6e 2a f0       	mov    0xf02a6ee0,%eax
f0101273:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		if (pte_store) {
f0101276:	85 db                	test   %ebx,%ebx
f0101278:	74 10                	je     f010128a <page_lookup+0x46>
			*pte_store = pgTbEty;
f010127a:	89 0b                	mov    %ecx,(%ebx)
f010127c:	eb 0c                	jmp    f010128a <page_lookup+0x46>

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
f010127e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101283:	eb 05                	jmp    f010128a <page_lookup+0x46>
f0101285:	b8 00 00 00 00       	mov    $0x0,%eax
		if (pte_store) {
			*pte_store = pgTbEty;
		}
	}
	return ret;
}
f010128a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010128d:	c9                   	leave  
f010128e:	c3                   	ret    

f010128f <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010128f:	55                   	push   %ebp
f0101290:	89 e5                	mov    %esp,%ebp
f0101292:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f0101295:	e8 ad 47 00 00       	call   f0105a47 <cpunum>
f010129a:	6b c0 74             	imul   $0x74,%eax,%eax
f010129d:	83 b8 48 70 2a f0 00 	cmpl   $0x0,-0xfd58fb8(%eax)
f01012a4:	74 16                	je     f01012bc <tlb_invalidate+0x2d>
f01012a6:	e8 9c 47 00 00       	call   f0105a47 <cpunum>
f01012ab:	6b c0 74             	imul   $0x74,%eax,%eax
f01012ae:	8b 80 48 70 2a f0    	mov    -0xfd58fb8(%eax),%eax
f01012b4:	8b 55 08             	mov    0x8(%ebp),%edx
f01012b7:	39 50 60             	cmp    %edx,0x60(%eax)
f01012ba:	75 06                	jne    f01012c2 <tlb_invalidate+0x33>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01012bc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012bf:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f01012c2:	c9                   	leave  
f01012c3:	c3                   	ret    

f01012c4 <page_remove>:
// 	tlb_invalidate, and page_decref.
//

void
page_remove(pde_t *pgdir, void *va)
{
f01012c4:	55                   	push   %ebp
f01012c5:	89 e5                	mov    %esp,%ebp
f01012c7:	56                   	push   %esi
f01012c8:	53                   	push   %ebx
f01012c9:	83 ec 14             	sub    $0x14,%esp
f01012cc:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01012cf:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t *pte;
	struct PageInfo *remPage = 0;
	if (!(remPage = page_lookup(pgdir, va, &pte))) {
f01012d2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01012d5:	50                   	push   %eax
f01012d6:	56                   	push   %esi
f01012d7:	53                   	push   %ebx
f01012d8:	e8 67 ff ff ff       	call   f0101244 <page_lookup>
f01012dd:	83 c4 10             	add    $0x10,%esp
f01012e0:	85 c0                	test   %eax,%eax
f01012e2:	74 1f                	je     f0101303 <page_remove+0x3f>
		return;
	}
	page_decref(remPage);
f01012e4:	83 ec 0c             	sub    $0xc,%esp
f01012e7:	50                   	push   %eax
f01012e8:	e8 be fd ff ff       	call   f01010ab <page_decref>
	*pte = 0;
f01012ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012f0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir, va);
f01012f6:	83 c4 08             	add    $0x8,%esp
f01012f9:	56                   	push   %esi
f01012fa:	53                   	push   %ebx
f01012fb:	e8 8f ff ff ff       	call   f010128f <tlb_invalidate>
f0101300:	83 c4 10             	add    $0x10,%esp
}
f0101303:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101306:	5b                   	pop    %ebx
f0101307:	5e                   	pop    %esi
f0101308:	5d                   	pop    %ebp
f0101309:	c3                   	ret    

f010130a <page_insert>:
// and page2pa.
//

int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010130a:	55                   	push   %ebp
f010130b:	89 e5                	mov    %esp,%ebp
f010130d:	57                   	push   %edi
f010130e:	56                   	push   %esi
f010130f:	53                   	push   %ebx
f0101310:	83 ec 10             	sub    $0x10,%esp
f0101313:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101316:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
f0101319:	6a 01                	push   $0x1
f010131b:	57                   	push   %edi
f010131c:	ff 75 08             	pushl  0x8(%ebp)
f010131f:	e8 ae fd ff ff       	call   f01010d2 <pgdir_walk>
f0101324:	89 c3                	mov    %eax,%ebx
	
	if (!pte){
f0101326:	83 c4 10             	add    $0x10,%esp
f0101329:	85 c0                	test   %eax,%eax
f010132b:	0f 84 85 00 00 00    	je     f01013b6 <page_insert+0xac>
		return -E_NO_MEM; //Page table could not be allocated	
	}

	if (*pte & PTE_P){    //if page is already present
f0101331:	8b 00                	mov    (%eax),%eax
f0101333:	a8 01                	test   $0x1,%al
f0101335:	74 5b                	je     f0101392 <page_insert+0x88>
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
f0101337:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010133c:	89 f2                	mov    %esi,%edx
f010133e:	2b 15 e0 6e 2a f0    	sub    0xf02a6ee0,%edx
f0101344:	c1 fa 03             	sar    $0x3,%edx
f0101347:	c1 e2 0c             	shl    $0xc,%edx
f010134a:	39 d0                	cmp    %edx,%eax
f010134c:	75 11                	jne    f010135f <page_insert+0x55>
f010134e:	8b 55 14             	mov    0x14(%ebp),%edx
f0101351:	83 ca 01             	or     $0x1,%edx
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
f0101354:	09 d0                	or     %edx,%eax
f0101356:	89 03                	mov    %eax,(%ebx)
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
			pp->pp_ref ++;  //incremnt the page reference
		}
		return 0;
f0101358:	b8 00 00 00 00       	mov    $0x0,%eax
f010135d:	eb 5c                	jmp    f01013bb <page_insert+0xb1>
	if (*pte & PTE_P){    //if page is already present
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
		}
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
f010135f:	83 ec 08             	sub    $0x8,%esp
f0101362:	57                   	push   %edi
f0101363:	ff 75 08             	pushl  0x8(%ebp)
f0101366:	e8 59 ff ff ff       	call   f01012c4 <page_remove>
f010136b:	8b 55 14             	mov    0x14(%ebp),%edx
f010136e:	83 ca 01             	or     $0x1,%edx
f0101371:	89 f0                	mov    %esi,%eax
f0101373:	2b 05 e0 6e 2a f0    	sub    0xf02a6ee0,%eax
f0101379:	c1 f8 03             	sar    $0x3,%eax
f010137c:	c1 e0 0c             	shl    $0xc,%eax
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
f010137f:	09 d0                	or     %edx,%eax
f0101381:	89 03                	mov    %eax,(%ebx)
			pp->pp_ref ++;  //incremnt the page reference
f0101383:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
f0101388:	83 c4 10             	add    $0x10,%esp
		}
		return 0;
f010138b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101390:	eb 29                	jmp    f01013bb <page_insert+0xb1>
f0101392:	8b 55 14             	mov    0x14(%ebp),%edx
f0101395:	83 ca 01             	or     $0x1,%edx
f0101398:	89 f0                	mov    %esi,%eax
f010139a:	2b 05 e0 6e 2a f0    	sub    0xf02a6ee0,%eax
f01013a0:	c1 f8 03             	sar    $0x3,%eax
f01013a3:	c1 e0 0c             	shl    $0xc,%eax
	}	
	else{   // if page is not present
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
f01013a6:	09 d0                	or     %edx,%eax
f01013a8:	89 03                	mov    %eax,(%ebx)
		pp->pp_ref ++; // increment the page reference count	     
f01013aa:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	}
	return 0;
f01013af:	b8 00 00 00 00       	mov    $0x0,%eax
f01013b4:	eb 05                	jmp    f01013bb <page_insert+0xb1>
{
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
	
	if (!pte){
		return -E_NO_MEM; //Page table could not be allocated	
f01013b6:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
		pp->pp_ref ++; // increment the page reference count	     
	}
	return 0;

}
f01013bb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01013be:	5b                   	pop    %ebx
f01013bf:	5e                   	pop    %esi
f01013c0:	5f                   	pop    %edi
f01013c1:	5d                   	pop    %ebp
f01013c2:	c3                   	ret    

f01013c3 <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f01013c3:	55                   	push   %ebp
f01013c4:	89 e5                	mov    %esp,%ebp
f01013c6:	56                   	push   %esi
f01013c7:	53                   	push   %ebx
	//
	// Your code here:
	//panic("mmio_map_region not implemented");
	
	//Since we modify the value of the pointer, copy the value of the pointer into some variable
	void* save = (void*) base;  // USe a pointer to void, just to store the first address
f01013c8:	8b 35 00 33 12 f0    	mov    0xf0123300,%esi
	
	//Roundup size to pgsize
	size = ROUNDUP(size,PGSIZE);
f01013ce:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013d1:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f01013d7:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	
	//Use bootmap region to map the given region
	boot_map_region(kern_pgdir, base, size, pa, PTE_W | PTE_P |PTE_PCD|PTE_PWT);
f01013dd:	83 ec 08             	sub    $0x8,%esp
f01013e0:	6a 1b                	push   $0x1b
f01013e2:	ff 75 08             	pushl  0x8(%ebp)
f01013e5:	89 d9                	mov    %ebx,%ecx
f01013e7:	89 f2                	mov    %esi,%edx
f01013e9:	a1 dc 6e 2a f0       	mov    0xf02a6edc,%eax
f01013ee:	e8 ca fd ff ff       	call   f01011bd <boot_map_region>
	
	//reserving size bytes of memory
	base += size;
f01013f3:	01 1d 00 33 12 f0    	add    %ebx,0xf0123300
	
	return save; 
	
}
f01013f9:	89 f0                	mov    %esi,%eax
f01013fb:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01013fe:	5b                   	pop    %ebx
f01013ff:	5e                   	pop    %esi
f0101400:	5d                   	pop    %ebp
f0101401:	c3                   	ret    

f0101402 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101402:	55                   	push   %ebp
f0101403:	89 e5                	mov    %esp,%ebp
f0101405:	57                   	push   %edi
f0101406:	56                   	push   %esi
f0101407:	53                   	push   %ebx
f0101408:	83 ec 48             	sub    $0x48,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010140b:	6a 15                	push   $0x15
f010140d:	e8 c4 22 00 00       	call   f01036d6 <mc146818_read>
f0101412:	89 c3                	mov    %eax,%ebx
f0101414:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f010141b:	e8 b6 22 00 00       	call   f01036d6 <mc146818_read>
f0101420:	c1 e0 08             	shl    $0x8,%eax
f0101423:	09 d8                	or     %ebx,%eax
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101425:	c1 e0 0a             	shl    $0xa,%eax
f0101428:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010142e:	85 c0                	test   %eax,%eax
f0101430:	0f 48 c2             	cmovs  %edx,%eax
f0101433:	c1 f8 0c             	sar    $0xc,%eax
f0101436:	a3 68 62 2a f0       	mov    %eax,0xf02a6268
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010143b:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101442:	e8 8f 22 00 00       	call   f01036d6 <mc146818_read>
f0101447:	89 c3                	mov    %eax,%ebx
f0101449:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101450:	e8 81 22 00 00       	call   f01036d6 <mc146818_read>
f0101455:	c1 e0 08             	shl    $0x8,%eax
f0101458:	09 d8                	or     %ebx,%eax
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010145a:	c1 e0 0a             	shl    $0xa,%eax
f010145d:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101463:	83 c4 10             	add    $0x10,%esp
f0101466:	85 c0                	test   %eax,%eax
f0101468:	0f 48 c2             	cmovs  %edx,%eax
f010146b:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f010146e:	85 c0                	test   %eax,%eax
f0101470:	74 0e                	je     f0101480 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101472:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101478:	89 15 d8 6e 2a f0    	mov    %edx,0xf02a6ed8
f010147e:	eb 0c                	jmp    f010148c <mem_init+0x8a>
	else
		npages = npages_basemem;
f0101480:	8b 15 68 62 2a f0    	mov    0xf02a6268,%edx
f0101486:	89 15 d8 6e 2a f0    	mov    %edx,0xf02a6ed8

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f010148c:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010148f:	c1 e8 0a             	shr    $0xa,%eax
f0101492:	50                   	push   %eax
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0101493:	a1 68 62 2a f0       	mov    0xf02a6268,%eax
f0101498:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010149b:	c1 e8 0a             	shr    $0xa,%eax
f010149e:	50                   	push   %eax
		npages * PGSIZE / 1024,
f010149f:	a1 d8 6e 2a f0       	mov    0xf02a6ed8,%eax
f01014a4:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01014a7:	c1 e8 0a             	shr    $0xa,%eax
f01014aa:	50                   	push   %eax
f01014ab:	68 5c 70 10 f0       	push   $0xf010705c
f01014b0:	e8 95 23 00 00       	call   f010384a <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01014b5:	b8 00 10 00 00       	mov    $0x1000,%eax
f01014ba:	e8 0e f6 ff ff       	call   f0100acd <boot_alloc>
f01014bf:	a3 dc 6e 2a f0       	mov    %eax,0xf02a6edc
	memset(kern_pgdir, 0, PGSIZE);
f01014c4:	83 c4 0c             	add    $0xc,%esp
f01014c7:	68 00 10 00 00       	push   $0x1000
f01014cc:	6a 00                	push   $0x0
f01014ce:	50                   	push   %eax
f01014cf:	e8 4e 3f 00 00       	call   f0105422 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01014d4:	a1 dc 6e 2a f0       	mov    0xf02a6edc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01014d9:	83 c4 10             	add    $0x10,%esp
f01014dc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01014e1:	77 15                	ja     f01014f8 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01014e3:	50                   	push   %eax
f01014e4:	68 08 69 10 f0       	push   $0xf0106908
f01014e9:	68 98 00 00 00       	push   $0x98
f01014ee:	68 75 78 10 f0       	push   $0xf0107875
f01014f3:	e8 48 eb ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01014f8:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01014fe:	83 ca 05             	or     $0x5,%edx
f0101501:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.

	//This line creates a boot allocation of memory of the size of number of pages
	// mulitplied by size of struct Pageinfo to store metadata of the page. 
	pages = boot_alloc(sizeof(struct PageInfo) * npages);   
f0101507:	a1 d8 6e 2a f0       	mov    0xf02a6ed8,%eax
f010150c:	c1 e0 03             	shl    $0x3,%eax
f010150f:	e8 b9 f5 ff ff       	call   f0100acd <boot_alloc>
f0101514:	a3 e0 6e 2a f0       	mov    %eax,0xf02a6ee0
	memset(pages, 0, sizeof(struct PageInfo) * npages); //Clear the memory 
f0101519:	83 ec 04             	sub    $0x4,%esp
f010151c:	8b 0d d8 6e 2a f0    	mov    0xf02a6ed8,%ecx
f0101522:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101529:	52                   	push   %edx
f010152a:	6a 00                	push   $0x0
f010152c:	50                   	push   %eax
f010152d:	e8 f0 3e 00 00       	call   f0105422 <memset>
	// The kernel uses this array to keep track of environment array:
	// 'NENV' is the number of Environments in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = boot_alloc(sizeof(struct Env)*NENV);
f0101532:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101537:	e8 91 f5 ff ff       	call   f0100acd <boot_alloc>
f010153c:	a3 6c 62 2a f0       	mov    %eax,0xf02a626c
	memset(envs,0,sizeof(struct Env)*NENV);
f0101541:	83 c4 0c             	add    $0xc,%esp
f0101544:	68 00 f0 01 00       	push   $0x1f000
f0101549:	6a 00                	push   $0x0
f010154b:	50                   	push   %eax
f010154c:	e8 d1 3e 00 00       	call   f0105422 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101551:	e8 03 f9 ff ff       	call   f0100e59 <page_init>

	check_page_free_list(1);
f0101556:	b8 01 00 00 00       	mov    $0x1,%eax
f010155b:	e8 e3 f5 ff ff       	call   f0100b43 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101560:	83 c4 10             	add    $0x10,%esp
f0101563:	83 3d e0 6e 2a f0 00 	cmpl   $0x0,0xf02a6ee0
f010156a:	75 17                	jne    f0101583 <mem_init+0x181>
		panic("'pages' is a null pointer!");
f010156c:	83 ec 04             	sub    $0x4,%esp
f010156f:	68 75 79 10 f0       	push   $0xf0107975
f0101574:	68 84 03 00 00       	push   $0x384
f0101579:	68 75 78 10 f0       	push   $0xf0107875
f010157e:	e8 bd ea ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101583:	a1 64 62 2a f0       	mov    0xf02a6264,%eax
f0101588:	bb 00 00 00 00       	mov    $0x0,%ebx
f010158d:	eb 05                	jmp    f0101594 <mem_init+0x192>
		++nfree;
f010158f:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101592:	8b 00                	mov    (%eax),%eax
f0101594:	85 c0                	test   %eax,%eax
f0101596:	75 f7                	jne    f010158f <mem_init+0x18d>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101598:	83 ec 0c             	sub    $0xc,%esp
f010159b:	6a 00                	push   $0x0
f010159d:	e8 42 fa ff ff       	call   f0100fe4 <page_alloc>
f01015a2:	89 c7                	mov    %eax,%edi
f01015a4:	83 c4 10             	add    $0x10,%esp
f01015a7:	85 c0                	test   %eax,%eax
f01015a9:	75 19                	jne    f01015c4 <mem_init+0x1c2>
f01015ab:	68 90 79 10 f0       	push   $0xf0107990
f01015b0:	68 9b 78 10 f0       	push   $0xf010789b
f01015b5:	68 8c 03 00 00       	push   $0x38c
f01015ba:	68 75 78 10 f0       	push   $0xf0107875
f01015bf:	e8 7c ea ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01015c4:	83 ec 0c             	sub    $0xc,%esp
f01015c7:	6a 00                	push   $0x0
f01015c9:	e8 16 fa ff ff       	call   f0100fe4 <page_alloc>
f01015ce:	89 c6                	mov    %eax,%esi
f01015d0:	83 c4 10             	add    $0x10,%esp
f01015d3:	85 c0                	test   %eax,%eax
f01015d5:	75 19                	jne    f01015f0 <mem_init+0x1ee>
f01015d7:	68 a6 79 10 f0       	push   $0xf01079a6
f01015dc:	68 9b 78 10 f0       	push   $0xf010789b
f01015e1:	68 8d 03 00 00       	push   $0x38d
f01015e6:	68 75 78 10 f0       	push   $0xf0107875
f01015eb:	e8 50 ea ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01015f0:	83 ec 0c             	sub    $0xc,%esp
f01015f3:	6a 00                	push   $0x0
f01015f5:	e8 ea f9 ff ff       	call   f0100fe4 <page_alloc>
f01015fa:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015fd:	83 c4 10             	add    $0x10,%esp
f0101600:	85 c0                	test   %eax,%eax
f0101602:	75 19                	jne    f010161d <mem_init+0x21b>
f0101604:	68 bc 79 10 f0       	push   $0xf01079bc
f0101609:	68 9b 78 10 f0       	push   $0xf010789b
f010160e:	68 8e 03 00 00       	push   $0x38e
f0101613:	68 75 78 10 f0       	push   $0xf0107875
f0101618:	e8 23 ea ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010161d:	39 f7                	cmp    %esi,%edi
f010161f:	75 19                	jne    f010163a <mem_init+0x238>
f0101621:	68 d2 79 10 f0       	push   $0xf01079d2
f0101626:	68 9b 78 10 f0       	push   $0xf010789b
f010162b:	68 91 03 00 00       	push   $0x391
f0101630:	68 75 78 10 f0       	push   $0xf0107875
f0101635:	e8 06 ea ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010163a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010163d:	39 c7                	cmp    %eax,%edi
f010163f:	74 04                	je     f0101645 <mem_init+0x243>
f0101641:	39 c6                	cmp    %eax,%esi
f0101643:	75 19                	jne    f010165e <mem_init+0x25c>
f0101645:	68 98 70 10 f0       	push   $0xf0107098
f010164a:	68 9b 78 10 f0       	push   $0xf010789b
f010164f:	68 92 03 00 00       	push   $0x392
f0101654:	68 75 78 10 f0       	push   $0xf0107875
f0101659:	e8 e2 e9 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010165e:	8b 0d e0 6e 2a f0    	mov    0xf02a6ee0,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101664:	8b 15 d8 6e 2a f0    	mov    0xf02a6ed8,%edx
f010166a:	c1 e2 0c             	shl    $0xc,%edx
f010166d:	89 f8                	mov    %edi,%eax
f010166f:	29 c8                	sub    %ecx,%eax
f0101671:	c1 f8 03             	sar    $0x3,%eax
f0101674:	c1 e0 0c             	shl    $0xc,%eax
f0101677:	39 d0                	cmp    %edx,%eax
f0101679:	72 19                	jb     f0101694 <mem_init+0x292>
f010167b:	68 e4 79 10 f0       	push   $0xf01079e4
f0101680:	68 9b 78 10 f0       	push   $0xf010789b
f0101685:	68 93 03 00 00       	push   $0x393
f010168a:	68 75 78 10 f0       	push   $0xf0107875
f010168f:	e8 ac e9 ff ff       	call   f0100040 <_panic>
f0101694:	89 f0                	mov    %esi,%eax
f0101696:	29 c8                	sub    %ecx,%eax
f0101698:	c1 f8 03             	sar    $0x3,%eax
f010169b:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f010169e:	39 c2                	cmp    %eax,%edx
f01016a0:	77 19                	ja     f01016bb <mem_init+0x2b9>
f01016a2:	68 01 7a 10 f0       	push   $0xf0107a01
f01016a7:	68 9b 78 10 f0       	push   $0xf010789b
f01016ac:	68 94 03 00 00       	push   $0x394
f01016b1:	68 75 78 10 f0       	push   $0xf0107875
f01016b6:	e8 85 e9 ff ff       	call   f0100040 <_panic>
f01016bb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016be:	29 c8                	sub    %ecx,%eax
f01016c0:	c1 f8 03             	sar    $0x3,%eax
f01016c3:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f01016c6:	39 c2                	cmp    %eax,%edx
f01016c8:	77 19                	ja     f01016e3 <mem_init+0x2e1>
f01016ca:	68 1e 7a 10 f0       	push   $0xf0107a1e
f01016cf:	68 9b 78 10 f0       	push   $0xf010789b
f01016d4:	68 95 03 00 00       	push   $0x395
f01016d9:	68 75 78 10 f0       	push   $0xf0107875
f01016de:	e8 5d e9 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01016e3:	a1 64 62 2a f0       	mov    0xf02a6264,%eax
f01016e8:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01016eb:	c7 05 64 62 2a f0 00 	movl   $0x0,0xf02a6264
f01016f2:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01016f5:	83 ec 0c             	sub    $0xc,%esp
f01016f8:	6a 00                	push   $0x0
f01016fa:	e8 e5 f8 ff ff       	call   f0100fe4 <page_alloc>
f01016ff:	83 c4 10             	add    $0x10,%esp
f0101702:	85 c0                	test   %eax,%eax
f0101704:	74 19                	je     f010171f <mem_init+0x31d>
f0101706:	68 3b 7a 10 f0       	push   $0xf0107a3b
f010170b:	68 9b 78 10 f0       	push   $0xf010789b
f0101710:	68 9c 03 00 00       	push   $0x39c
f0101715:	68 75 78 10 f0       	push   $0xf0107875
f010171a:	e8 21 e9 ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f010171f:	83 ec 0c             	sub    $0xc,%esp
f0101722:	57                   	push   %edi
f0101723:	e8 32 f9 ff ff       	call   f010105a <page_free>
	page_free(pp1);
f0101728:	89 34 24             	mov    %esi,(%esp)
f010172b:	e8 2a f9 ff ff       	call   f010105a <page_free>
	page_free(pp2);
f0101730:	83 c4 04             	add    $0x4,%esp
f0101733:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101736:	e8 1f f9 ff ff       	call   f010105a <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010173b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101742:	e8 9d f8 ff ff       	call   f0100fe4 <page_alloc>
f0101747:	89 c6                	mov    %eax,%esi
f0101749:	83 c4 10             	add    $0x10,%esp
f010174c:	85 c0                	test   %eax,%eax
f010174e:	75 19                	jne    f0101769 <mem_init+0x367>
f0101750:	68 90 79 10 f0       	push   $0xf0107990
f0101755:	68 9b 78 10 f0       	push   $0xf010789b
f010175a:	68 a3 03 00 00       	push   $0x3a3
f010175f:	68 75 78 10 f0       	push   $0xf0107875
f0101764:	e8 d7 e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101769:	83 ec 0c             	sub    $0xc,%esp
f010176c:	6a 00                	push   $0x0
f010176e:	e8 71 f8 ff ff       	call   f0100fe4 <page_alloc>
f0101773:	89 c7                	mov    %eax,%edi
f0101775:	83 c4 10             	add    $0x10,%esp
f0101778:	85 c0                	test   %eax,%eax
f010177a:	75 19                	jne    f0101795 <mem_init+0x393>
f010177c:	68 a6 79 10 f0       	push   $0xf01079a6
f0101781:	68 9b 78 10 f0       	push   $0xf010789b
f0101786:	68 a4 03 00 00       	push   $0x3a4
f010178b:	68 75 78 10 f0       	push   $0xf0107875
f0101790:	e8 ab e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101795:	83 ec 0c             	sub    $0xc,%esp
f0101798:	6a 00                	push   $0x0
f010179a:	e8 45 f8 ff ff       	call   f0100fe4 <page_alloc>
f010179f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01017a2:	83 c4 10             	add    $0x10,%esp
f01017a5:	85 c0                	test   %eax,%eax
f01017a7:	75 19                	jne    f01017c2 <mem_init+0x3c0>
f01017a9:	68 bc 79 10 f0       	push   $0xf01079bc
f01017ae:	68 9b 78 10 f0       	push   $0xf010789b
f01017b3:	68 a5 03 00 00       	push   $0x3a5
f01017b8:	68 75 78 10 f0       	push   $0xf0107875
f01017bd:	e8 7e e8 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01017c2:	39 fe                	cmp    %edi,%esi
f01017c4:	75 19                	jne    f01017df <mem_init+0x3dd>
f01017c6:	68 d2 79 10 f0       	push   $0xf01079d2
f01017cb:	68 9b 78 10 f0       	push   $0xf010789b
f01017d0:	68 a7 03 00 00       	push   $0x3a7
f01017d5:	68 75 78 10 f0       	push   $0xf0107875
f01017da:	e8 61 e8 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017df:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017e2:	39 c6                	cmp    %eax,%esi
f01017e4:	74 04                	je     f01017ea <mem_init+0x3e8>
f01017e6:	39 c7                	cmp    %eax,%edi
f01017e8:	75 19                	jne    f0101803 <mem_init+0x401>
f01017ea:	68 98 70 10 f0       	push   $0xf0107098
f01017ef:	68 9b 78 10 f0       	push   $0xf010789b
f01017f4:	68 a8 03 00 00       	push   $0x3a8
f01017f9:	68 75 78 10 f0       	push   $0xf0107875
f01017fe:	e8 3d e8 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101803:	83 ec 0c             	sub    $0xc,%esp
f0101806:	6a 00                	push   $0x0
f0101808:	e8 d7 f7 ff ff       	call   f0100fe4 <page_alloc>
f010180d:	83 c4 10             	add    $0x10,%esp
f0101810:	85 c0                	test   %eax,%eax
f0101812:	74 19                	je     f010182d <mem_init+0x42b>
f0101814:	68 3b 7a 10 f0       	push   $0xf0107a3b
f0101819:	68 9b 78 10 f0       	push   $0xf010789b
f010181e:	68 a9 03 00 00       	push   $0x3a9
f0101823:	68 75 78 10 f0       	push   $0xf0107875
f0101828:	e8 13 e8 ff ff       	call   f0100040 <_panic>
f010182d:	89 f0                	mov    %esi,%eax
f010182f:	2b 05 e0 6e 2a f0    	sub    0xf02a6ee0,%eax
f0101835:	c1 f8 03             	sar    $0x3,%eax
f0101838:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010183b:	89 c2                	mov    %eax,%edx
f010183d:	c1 ea 0c             	shr    $0xc,%edx
f0101840:	3b 15 d8 6e 2a f0    	cmp    0xf02a6ed8,%edx
f0101846:	72 12                	jb     f010185a <mem_init+0x458>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101848:	50                   	push   %eax
f0101849:	68 e4 68 10 f0       	push   $0xf01068e4
f010184e:	6a 58                	push   $0x58
f0101850:	68 81 78 10 f0       	push   $0xf0107881
f0101855:	e8 e6 e7 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010185a:	83 ec 04             	sub    $0x4,%esp
f010185d:	68 00 10 00 00       	push   $0x1000
f0101862:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0101864:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101869:	50                   	push   %eax
f010186a:	e8 b3 3b 00 00       	call   f0105422 <memset>
	page_free(pp0);
f010186f:	89 34 24             	mov    %esi,(%esp)
f0101872:	e8 e3 f7 ff ff       	call   f010105a <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101877:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010187e:	e8 61 f7 ff ff       	call   f0100fe4 <page_alloc>
f0101883:	83 c4 10             	add    $0x10,%esp
f0101886:	85 c0                	test   %eax,%eax
f0101888:	75 19                	jne    f01018a3 <mem_init+0x4a1>
f010188a:	68 4a 7a 10 f0       	push   $0xf0107a4a
f010188f:	68 9b 78 10 f0       	push   $0xf010789b
f0101894:	68 ae 03 00 00       	push   $0x3ae
f0101899:	68 75 78 10 f0       	push   $0xf0107875
f010189e:	e8 9d e7 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f01018a3:	39 c6                	cmp    %eax,%esi
f01018a5:	74 19                	je     f01018c0 <mem_init+0x4be>
f01018a7:	68 68 7a 10 f0       	push   $0xf0107a68
f01018ac:	68 9b 78 10 f0       	push   $0xf010789b
f01018b1:	68 af 03 00 00       	push   $0x3af
f01018b6:	68 75 78 10 f0       	push   $0xf0107875
f01018bb:	e8 80 e7 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01018c0:	89 f0                	mov    %esi,%eax
f01018c2:	2b 05 e0 6e 2a f0    	sub    0xf02a6ee0,%eax
f01018c8:	c1 f8 03             	sar    $0x3,%eax
f01018cb:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01018ce:	89 c2                	mov    %eax,%edx
f01018d0:	c1 ea 0c             	shr    $0xc,%edx
f01018d3:	3b 15 d8 6e 2a f0    	cmp    0xf02a6ed8,%edx
f01018d9:	72 12                	jb     f01018ed <mem_init+0x4eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01018db:	50                   	push   %eax
f01018dc:	68 e4 68 10 f0       	push   $0xf01068e4
f01018e1:	6a 58                	push   $0x58
f01018e3:	68 81 78 10 f0       	push   $0xf0107881
f01018e8:	e8 53 e7 ff ff       	call   f0100040 <_panic>
f01018ed:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01018f3:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01018f9:	80 38 00             	cmpb   $0x0,(%eax)
f01018fc:	74 19                	je     f0101917 <mem_init+0x515>
f01018fe:	68 78 7a 10 f0       	push   $0xf0107a78
f0101903:	68 9b 78 10 f0       	push   $0xf010789b
f0101908:	68 b2 03 00 00       	push   $0x3b2
f010190d:	68 75 78 10 f0       	push   $0xf0107875
f0101912:	e8 29 e7 ff ff       	call   f0100040 <_panic>
f0101917:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010191a:	39 d0                	cmp    %edx,%eax
f010191c:	75 db                	jne    f01018f9 <mem_init+0x4f7>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010191e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101921:	a3 64 62 2a f0       	mov    %eax,0xf02a6264

	// free the pages we took
	page_free(pp0);
f0101926:	83 ec 0c             	sub    $0xc,%esp
f0101929:	56                   	push   %esi
f010192a:	e8 2b f7 ff ff       	call   f010105a <page_free>
	page_free(pp1);
f010192f:	89 3c 24             	mov    %edi,(%esp)
f0101932:	e8 23 f7 ff ff       	call   f010105a <page_free>
	page_free(pp2);
f0101937:	83 c4 04             	add    $0x4,%esp
f010193a:	ff 75 d4             	pushl  -0x2c(%ebp)
f010193d:	e8 18 f7 ff ff       	call   f010105a <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101942:	a1 64 62 2a f0       	mov    0xf02a6264,%eax
f0101947:	83 c4 10             	add    $0x10,%esp
f010194a:	eb 05                	jmp    f0101951 <mem_init+0x54f>
		--nfree;
f010194c:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010194f:	8b 00                	mov    (%eax),%eax
f0101951:	85 c0                	test   %eax,%eax
f0101953:	75 f7                	jne    f010194c <mem_init+0x54a>
		--nfree;
	assert(nfree == 0);
f0101955:	85 db                	test   %ebx,%ebx
f0101957:	74 19                	je     f0101972 <mem_init+0x570>
f0101959:	68 82 7a 10 f0       	push   $0xf0107a82
f010195e:	68 9b 78 10 f0       	push   $0xf010789b
f0101963:	68 bf 03 00 00       	push   $0x3bf
f0101968:	68 75 78 10 f0       	push   $0xf0107875
f010196d:	e8 ce e6 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101972:	83 ec 0c             	sub    $0xc,%esp
f0101975:	68 b8 70 10 f0       	push   $0xf01070b8
f010197a:	e8 cb 1e 00 00       	call   f010384a <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010197f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101986:	e8 59 f6 ff ff       	call   f0100fe4 <page_alloc>
f010198b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010198e:	83 c4 10             	add    $0x10,%esp
f0101991:	85 c0                	test   %eax,%eax
f0101993:	75 19                	jne    f01019ae <mem_init+0x5ac>
f0101995:	68 90 79 10 f0       	push   $0xf0107990
f010199a:	68 9b 78 10 f0       	push   $0xf010789b
f010199f:	68 25 04 00 00       	push   $0x425
f01019a4:	68 75 78 10 f0       	push   $0xf0107875
f01019a9:	e8 92 e6 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01019ae:	83 ec 0c             	sub    $0xc,%esp
f01019b1:	6a 00                	push   $0x0
f01019b3:	e8 2c f6 ff ff       	call   f0100fe4 <page_alloc>
f01019b8:	89 c3                	mov    %eax,%ebx
f01019ba:	83 c4 10             	add    $0x10,%esp
f01019bd:	85 c0                	test   %eax,%eax
f01019bf:	75 19                	jne    f01019da <mem_init+0x5d8>
f01019c1:	68 a6 79 10 f0       	push   $0xf01079a6
f01019c6:	68 9b 78 10 f0       	push   $0xf010789b
f01019cb:	68 26 04 00 00       	push   $0x426
f01019d0:	68 75 78 10 f0       	push   $0xf0107875
f01019d5:	e8 66 e6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01019da:	83 ec 0c             	sub    $0xc,%esp
f01019dd:	6a 00                	push   $0x0
f01019df:	e8 00 f6 ff ff       	call   f0100fe4 <page_alloc>
f01019e4:	89 c6                	mov    %eax,%esi
f01019e6:	83 c4 10             	add    $0x10,%esp
f01019e9:	85 c0                	test   %eax,%eax
f01019eb:	75 19                	jne    f0101a06 <mem_init+0x604>
f01019ed:	68 bc 79 10 f0       	push   $0xf01079bc
f01019f2:	68 9b 78 10 f0       	push   $0xf010789b
f01019f7:	68 27 04 00 00       	push   $0x427
f01019fc:	68 75 78 10 f0       	push   $0xf0107875
f0101a01:	e8 3a e6 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a06:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101a09:	75 19                	jne    f0101a24 <mem_init+0x622>
f0101a0b:	68 d2 79 10 f0       	push   $0xf01079d2
f0101a10:	68 9b 78 10 f0       	push   $0xf010789b
f0101a15:	68 2a 04 00 00       	push   $0x42a
f0101a1a:	68 75 78 10 f0       	push   $0xf0107875
f0101a1f:	e8 1c e6 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a24:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101a27:	74 04                	je     f0101a2d <mem_init+0x62b>
f0101a29:	39 c3                	cmp    %eax,%ebx
f0101a2b:	75 19                	jne    f0101a46 <mem_init+0x644>
f0101a2d:	68 98 70 10 f0       	push   $0xf0107098
f0101a32:	68 9b 78 10 f0       	push   $0xf010789b
f0101a37:	68 2b 04 00 00       	push   $0x42b
f0101a3c:	68 75 78 10 f0       	push   $0xf0107875
f0101a41:	e8 fa e5 ff ff       	call   f0100040 <_panic>
	

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101a46:	a1 64 62 2a f0       	mov    0xf02a6264,%eax
f0101a4b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101a4e:	c7 05 64 62 2a f0 00 	movl   $0x0,0xf02a6264
f0101a55:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101a58:	83 ec 0c             	sub    $0xc,%esp
f0101a5b:	6a 00                	push   $0x0
f0101a5d:	e8 82 f5 ff ff       	call   f0100fe4 <page_alloc>
f0101a62:	83 c4 10             	add    $0x10,%esp
f0101a65:	85 c0                	test   %eax,%eax
f0101a67:	74 19                	je     f0101a82 <mem_init+0x680>
f0101a69:	68 3b 7a 10 f0       	push   $0xf0107a3b
f0101a6e:	68 9b 78 10 f0       	push   $0xf010789b
f0101a73:	68 33 04 00 00       	push   $0x433
f0101a78:	68 75 78 10 f0       	push   $0xf0107875
f0101a7d:	e8 be e5 ff ff       	call   f0100040 <_panic>
	
	
	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101a82:	83 ec 04             	sub    $0x4,%esp
f0101a85:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101a88:	50                   	push   %eax
f0101a89:	6a 00                	push   $0x0
f0101a8b:	ff 35 dc 6e 2a f0    	pushl  0xf02a6edc
f0101a91:	e8 ae f7 ff ff       	call   f0101244 <page_lookup>
f0101a96:	83 c4 10             	add    $0x10,%esp
f0101a99:	85 c0                	test   %eax,%eax
f0101a9b:	74 19                	je     f0101ab6 <mem_init+0x6b4>
f0101a9d:	68 d8 70 10 f0       	push   $0xf01070d8
f0101aa2:	68 9b 78 10 f0       	push   $0xf010789b
f0101aa7:	68 37 04 00 00       	push   $0x437
f0101aac:	68 75 78 10 f0       	push   $0xf0107875
f0101ab1:	e8 8a e5 ff ff       	call   f0100040 <_panic>
	
	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101ab6:	6a 02                	push   $0x2
f0101ab8:	6a 00                	push   $0x0
f0101aba:	53                   	push   %ebx
f0101abb:	ff 35 dc 6e 2a f0    	pushl  0xf02a6edc
f0101ac1:	e8 44 f8 ff ff       	call   f010130a <page_insert>
f0101ac6:	83 c4 10             	add    $0x10,%esp
f0101ac9:	85 c0                	test   %eax,%eax
f0101acb:	78 19                	js     f0101ae6 <mem_init+0x6e4>
f0101acd:	68 10 71 10 f0       	push   $0xf0107110
f0101ad2:	68 9b 78 10 f0       	push   $0xf010789b
f0101ad7:	68 3a 04 00 00       	push   $0x43a
f0101adc:	68 75 78 10 f0       	push   $0xf0107875
f0101ae1:	e8 5a e5 ff ff       	call   f0100040 <_panic>
	
	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101ae6:	83 ec 0c             	sub    $0xc,%esp
f0101ae9:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101aec:	e8 69 f5 ff ff       	call   f010105a <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101af1:	6a 02                	push   $0x2
f0101af3:	6a 00                	push   $0x0
f0101af5:	53                   	push   %ebx
f0101af6:	ff 35 dc 6e 2a f0    	pushl  0xf02a6edc
f0101afc:	e8 09 f8 ff ff       	call   f010130a <page_insert>
f0101b01:	83 c4 20             	add    $0x20,%esp
f0101b04:	85 c0                	test   %eax,%eax
f0101b06:	74 19                	je     f0101b21 <mem_init+0x71f>
f0101b08:	68 40 71 10 f0       	push   $0xf0107140
f0101b0d:	68 9b 78 10 f0       	push   $0xf010789b
f0101b12:	68 3e 04 00 00       	push   $0x43e
f0101b17:	68 75 78 10 f0       	push   $0xf0107875
f0101b1c:	e8 1f e5 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101b21:	8b 3d dc 6e 2a f0    	mov    0xf02a6edc,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101b27:	a1 e0 6e 2a f0       	mov    0xf02a6ee0,%eax
f0101b2c:	89 c1                	mov    %eax,%ecx
f0101b2e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101b31:	8b 17                	mov    (%edi),%edx
f0101b33:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101b39:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b3c:	29 c8                	sub    %ecx,%eax
f0101b3e:	c1 f8 03             	sar    $0x3,%eax
f0101b41:	c1 e0 0c             	shl    $0xc,%eax
f0101b44:	39 c2                	cmp    %eax,%edx
f0101b46:	74 19                	je     f0101b61 <mem_init+0x75f>
f0101b48:	68 70 71 10 f0       	push   $0xf0107170
f0101b4d:	68 9b 78 10 f0       	push   $0xf010789b
f0101b52:	68 3f 04 00 00       	push   $0x43f
f0101b57:	68 75 78 10 f0       	push   $0xf0107875
f0101b5c:	e8 df e4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b61:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b66:	89 f8                	mov    %edi,%eax
f0101b68:	e8 fc ee ff ff       	call   f0100a69 <check_va2pa>
f0101b6d:	89 da                	mov    %ebx,%edx
f0101b6f:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101b72:	c1 fa 03             	sar    $0x3,%edx
f0101b75:	c1 e2 0c             	shl    $0xc,%edx
f0101b78:	39 d0                	cmp    %edx,%eax
f0101b7a:	74 19                	je     f0101b95 <mem_init+0x793>
f0101b7c:	68 98 71 10 f0       	push   $0xf0107198
f0101b81:	68 9b 78 10 f0       	push   $0xf010789b
f0101b86:	68 40 04 00 00       	push   $0x440
f0101b8b:	68 75 78 10 f0       	push   $0xf0107875
f0101b90:	e8 ab e4 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101b95:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b9a:	74 19                	je     f0101bb5 <mem_init+0x7b3>
f0101b9c:	68 8d 7a 10 f0       	push   $0xf0107a8d
f0101ba1:	68 9b 78 10 f0       	push   $0xf010789b
f0101ba6:	68 41 04 00 00       	push   $0x441
f0101bab:	68 75 78 10 f0       	push   $0xf0107875
f0101bb0:	e8 8b e4 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101bb5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101bb8:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101bbd:	74 19                	je     f0101bd8 <mem_init+0x7d6>
f0101bbf:	68 9e 7a 10 f0       	push   $0xf0107a9e
f0101bc4:	68 9b 78 10 f0       	push   $0xf010789b
f0101bc9:	68 42 04 00 00       	push   $0x442
f0101bce:	68 75 78 10 f0       	push   $0xf0107875
f0101bd3:	e8 68 e4 ff ff       	call   f0100040 <_panic>
	
	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bd8:	6a 02                	push   $0x2
f0101bda:	68 00 10 00 00       	push   $0x1000
f0101bdf:	56                   	push   %esi
f0101be0:	57                   	push   %edi
f0101be1:	e8 24 f7 ff ff       	call   f010130a <page_insert>
f0101be6:	83 c4 10             	add    $0x10,%esp
f0101be9:	85 c0                	test   %eax,%eax
f0101beb:	74 19                	je     f0101c06 <mem_init+0x804>
f0101bed:	68 c8 71 10 f0       	push   $0xf01071c8
f0101bf2:	68 9b 78 10 f0       	push   $0xf010789b
f0101bf7:	68 45 04 00 00       	push   $0x445
f0101bfc:	68 75 78 10 f0       	push   $0xf0107875
f0101c01:	e8 3a e4 ff ff       	call   f0100040 <_panic>

	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c06:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c0b:	a1 dc 6e 2a f0       	mov    0xf02a6edc,%eax
f0101c10:	e8 54 ee ff ff       	call   f0100a69 <check_va2pa>
f0101c15:	89 f2                	mov    %esi,%edx
f0101c17:	2b 15 e0 6e 2a f0    	sub    0xf02a6ee0,%edx
f0101c1d:	c1 fa 03             	sar    $0x3,%edx
f0101c20:	c1 e2 0c             	shl    $0xc,%edx
f0101c23:	39 d0                	cmp    %edx,%eax
f0101c25:	74 19                	je     f0101c40 <mem_init+0x83e>
f0101c27:	68 04 72 10 f0       	push   $0xf0107204
f0101c2c:	68 9b 78 10 f0       	push   $0xf010789b
f0101c31:	68 47 04 00 00       	push   $0x447
f0101c36:	68 75 78 10 f0       	push   $0xf0107875
f0101c3b:	e8 00 e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101c40:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c45:	74 19                	je     f0101c60 <mem_init+0x85e>
f0101c47:	68 af 7a 10 f0       	push   $0xf0107aaf
f0101c4c:	68 9b 78 10 f0       	push   $0xf010789b
f0101c51:	68 48 04 00 00       	push   $0x448
f0101c56:	68 75 78 10 f0       	push   $0xf0107875
f0101c5b:	e8 e0 e3 ff ff       	call   f0100040 <_panic>
	
	// should be no free memory
	assert(!page_alloc(0));
f0101c60:	83 ec 0c             	sub    $0xc,%esp
f0101c63:	6a 00                	push   $0x0
f0101c65:	e8 7a f3 ff ff       	call   f0100fe4 <page_alloc>
f0101c6a:	83 c4 10             	add    $0x10,%esp
f0101c6d:	85 c0                	test   %eax,%eax
f0101c6f:	74 19                	je     f0101c8a <mem_init+0x888>
f0101c71:	68 3b 7a 10 f0       	push   $0xf0107a3b
f0101c76:	68 9b 78 10 f0       	push   $0xf010789b
f0101c7b:	68 4b 04 00 00       	push   $0x44b
f0101c80:	68 75 78 10 f0       	push   $0xf0107875
f0101c85:	e8 b6 e3 ff ff       	call   f0100040 <_panic>
	
	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c8a:	6a 02                	push   $0x2
f0101c8c:	68 00 10 00 00       	push   $0x1000
f0101c91:	56                   	push   %esi
f0101c92:	ff 35 dc 6e 2a f0    	pushl  0xf02a6edc
f0101c98:	e8 6d f6 ff ff       	call   f010130a <page_insert>
f0101c9d:	83 c4 10             	add    $0x10,%esp
f0101ca0:	85 c0                	test   %eax,%eax
f0101ca2:	74 19                	je     f0101cbd <mem_init+0x8bb>
f0101ca4:	68 c8 71 10 f0       	push   $0xf01071c8
f0101ca9:	68 9b 78 10 f0       	push   $0xf010789b
f0101cae:	68 4e 04 00 00       	push   $0x44e
f0101cb3:	68 75 78 10 f0       	push   $0xf0107875
f0101cb8:	e8 83 e3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101cbd:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cc2:	a1 dc 6e 2a f0       	mov    0xf02a6edc,%eax
f0101cc7:	e8 9d ed ff ff       	call   f0100a69 <check_va2pa>
f0101ccc:	89 f2                	mov    %esi,%edx
f0101cce:	2b 15 e0 6e 2a f0    	sub    0xf02a6ee0,%edx
f0101cd4:	c1 fa 03             	sar    $0x3,%edx
f0101cd7:	c1 e2 0c             	shl    $0xc,%edx
f0101cda:	39 d0                	cmp    %edx,%eax
f0101cdc:	74 19                	je     f0101cf7 <mem_init+0x8f5>
f0101cde:	68 04 72 10 f0       	push   $0xf0107204
f0101ce3:	68 9b 78 10 f0       	push   $0xf010789b
f0101ce8:	68 4f 04 00 00       	push   $0x44f
f0101ced:	68 75 78 10 f0       	push   $0xf0107875
f0101cf2:	e8 49 e3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101cf7:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101cfc:	74 19                	je     f0101d17 <mem_init+0x915>
f0101cfe:	68 af 7a 10 f0       	push   $0xf0107aaf
f0101d03:	68 9b 78 10 f0       	push   $0xf010789b
f0101d08:	68 50 04 00 00       	push   $0x450
f0101d0d:	68 75 78 10 f0       	push   $0xf0107875
f0101d12:	e8 29 e3 ff ff       	call   f0100040 <_panic>
	
	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101d17:	83 ec 0c             	sub    $0xc,%esp
f0101d1a:	6a 00                	push   $0x0
f0101d1c:	e8 c3 f2 ff ff       	call   f0100fe4 <page_alloc>
f0101d21:	83 c4 10             	add    $0x10,%esp
f0101d24:	85 c0                	test   %eax,%eax
f0101d26:	74 19                	je     f0101d41 <mem_init+0x93f>
f0101d28:	68 3b 7a 10 f0       	push   $0xf0107a3b
f0101d2d:	68 9b 78 10 f0       	push   $0xf010789b
f0101d32:	68 54 04 00 00       	push   $0x454
f0101d37:	68 75 78 10 f0       	push   $0xf0107875
f0101d3c:	e8 ff e2 ff ff       	call   f0100040 <_panic>
	
	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101d41:	8b 15 dc 6e 2a f0    	mov    0xf02a6edc,%edx
f0101d47:	8b 02                	mov    (%edx),%eax
f0101d49:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101d4e:	89 c1                	mov    %eax,%ecx
f0101d50:	c1 e9 0c             	shr    $0xc,%ecx
f0101d53:	3b 0d d8 6e 2a f0    	cmp    0xf02a6ed8,%ecx
f0101d59:	72 15                	jb     f0101d70 <mem_init+0x96e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d5b:	50                   	push   %eax
f0101d5c:	68 e4 68 10 f0       	push   $0xf01068e4
f0101d61:	68 57 04 00 00       	push   $0x457
f0101d66:	68 75 78 10 f0       	push   $0xf0107875
f0101d6b:	e8 d0 e2 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101d70:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d75:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d78:	83 ec 04             	sub    $0x4,%esp
f0101d7b:	6a 00                	push   $0x0
f0101d7d:	68 00 10 00 00       	push   $0x1000
f0101d82:	52                   	push   %edx
f0101d83:	e8 4a f3 ff ff       	call   f01010d2 <pgdir_walk>
f0101d88:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101d8b:	8d 51 04             	lea    0x4(%ecx),%edx
f0101d8e:	83 c4 10             	add    $0x10,%esp
f0101d91:	39 d0                	cmp    %edx,%eax
f0101d93:	74 19                	je     f0101dae <mem_init+0x9ac>
f0101d95:	68 34 72 10 f0       	push   $0xf0107234
f0101d9a:	68 9b 78 10 f0       	push   $0xf010789b
f0101d9f:	68 58 04 00 00       	push   $0x458
f0101da4:	68 75 78 10 f0       	push   $0xf0107875
f0101da9:	e8 92 e2 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101dae:	6a 06                	push   $0x6
f0101db0:	68 00 10 00 00       	push   $0x1000
f0101db5:	56                   	push   %esi
f0101db6:	ff 35 dc 6e 2a f0    	pushl  0xf02a6edc
f0101dbc:	e8 49 f5 ff ff       	call   f010130a <page_insert>
f0101dc1:	83 c4 10             	add    $0x10,%esp
f0101dc4:	85 c0                	test   %eax,%eax
f0101dc6:	74 19                	je     f0101de1 <mem_init+0x9df>
f0101dc8:	68 74 72 10 f0       	push   $0xf0107274
f0101dcd:	68 9b 78 10 f0       	push   $0xf010789b
f0101dd2:	68 5b 04 00 00       	push   $0x45b
f0101dd7:	68 75 78 10 f0       	push   $0xf0107875
f0101ddc:	e8 5f e2 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101de1:	8b 3d dc 6e 2a f0    	mov    0xf02a6edc,%edi
f0101de7:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dec:	89 f8                	mov    %edi,%eax
f0101dee:	e8 76 ec ff ff       	call   f0100a69 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101df3:	89 f2                	mov    %esi,%edx
f0101df5:	2b 15 e0 6e 2a f0    	sub    0xf02a6ee0,%edx
f0101dfb:	c1 fa 03             	sar    $0x3,%edx
f0101dfe:	c1 e2 0c             	shl    $0xc,%edx
f0101e01:	39 d0                	cmp    %edx,%eax
f0101e03:	74 19                	je     f0101e1e <mem_init+0xa1c>
f0101e05:	68 04 72 10 f0       	push   $0xf0107204
f0101e0a:	68 9b 78 10 f0       	push   $0xf010789b
f0101e0f:	68 5c 04 00 00       	push   $0x45c
f0101e14:	68 75 78 10 f0       	push   $0xf0107875
f0101e19:	e8 22 e2 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101e1e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e23:	74 19                	je     f0101e3e <mem_init+0xa3c>
f0101e25:	68 af 7a 10 f0       	push   $0xf0107aaf
f0101e2a:	68 9b 78 10 f0       	push   $0xf010789b
f0101e2f:	68 5d 04 00 00       	push   $0x45d
f0101e34:	68 75 78 10 f0       	push   $0xf0107875
f0101e39:	e8 02 e2 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101e3e:	83 ec 04             	sub    $0x4,%esp
f0101e41:	6a 00                	push   $0x0
f0101e43:	68 00 10 00 00       	push   $0x1000
f0101e48:	57                   	push   %edi
f0101e49:	e8 84 f2 ff ff       	call   f01010d2 <pgdir_walk>
f0101e4e:	83 c4 10             	add    $0x10,%esp
f0101e51:	f6 00 04             	testb  $0x4,(%eax)
f0101e54:	75 19                	jne    f0101e6f <mem_init+0xa6d>
f0101e56:	68 b4 72 10 f0       	push   $0xf01072b4
f0101e5b:	68 9b 78 10 f0       	push   $0xf010789b
f0101e60:	68 5e 04 00 00       	push   $0x45e
f0101e65:	68 75 78 10 f0       	push   $0xf0107875
f0101e6a:	e8 d1 e1 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101e6f:	a1 dc 6e 2a f0       	mov    0xf02a6edc,%eax
f0101e74:	f6 00 04             	testb  $0x4,(%eax)
f0101e77:	75 19                	jne    f0101e92 <mem_init+0xa90>
f0101e79:	68 c0 7a 10 f0       	push   $0xf0107ac0
f0101e7e:	68 9b 78 10 f0       	push   $0xf010789b
f0101e83:	68 5f 04 00 00       	push   $0x45f
f0101e88:	68 75 78 10 f0       	push   $0xf0107875
f0101e8d:	e8 ae e1 ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e92:	6a 02                	push   $0x2
f0101e94:	68 00 10 00 00       	push   $0x1000
f0101e99:	56                   	push   %esi
f0101e9a:	50                   	push   %eax
f0101e9b:	e8 6a f4 ff ff       	call   f010130a <page_insert>
f0101ea0:	83 c4 10             	add    $0x10,%esp
f0101ea3:	85 c0                	test   %eax,%eax
f0101ea5:	74 19                	je     f0101ec0 <mem_init+0xabe>
f0101ea7:	68 c8 71 10 f0       	push   $0xf01071c8
f0101eac:	68 9b 78 10 f0       	push   $0xf010789b
f0101eb1:	68 62 04 00 00       	push   $0x462
f0101eb6:	68 75 78 10 f0       	push   $0xf0107875
f0101ebb:	e8 80 e1 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101ec0:	83 ec 04             	sub    $0x4,%esp
f0101ec3:	6a 00                	push   $0x0
f0101ec5:	68 00 10 00 00       	push   $0x1000
f0101eca:	ff 35 dc 6e 2a f0    	pushl  0xf02a6edc
f0101ed0:	e8 fd f1 ff ff       	call   f01010d2 <pgdir_walk>
f0101ed5:	83 c4 10             	add    $0x10,%esp
f0101ed8:	f6 00 02             	testb  $0x2,(%eax)
f0101edb:	75 19                	jne    f0101ef6 <mem_init+0xaf4>
f0101edd:	68 e8 72 10 f0       	push   $0xf01072e8
f0101ee2:	68 9b 78 10 f0       	push   $0xf010789b
f0101ee7:	68 63 04 00 00       	push   $0x463
f0101eec:	68 75 78 10 f0       	push   $0xf0107875
f0101ef1:	e8 4a e1 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ef6:	83 ec 04             	sub    $0x4,%esp
f0101ef9:	6a 00                	push   $0x0
f0101efb:	68 00 10 00 00       	push   $0x1000
f0101f00:	ff 35 dc 6e 2a f0    	pushl  0xf02a6edc
f0101f06:	e8 c7 f1 ff ff       	call   f01010d2 <pgdir_walk>
f0101f0b:	83 c4 10             	add    $0x10,%esp
f0101f0e:	f6 00 04             	testb  $0x4,(%eax)
f0101f11:	74 19                	je     f0101f2c <mem_init+0xb2a>
f0101f13:	68 1c 73 10 f0       	push   $0xf010731c
f0101f18:	68 9b 78 10 f0       	push   $0xf010789b
f0101f1d:	68 64 04 00 00       	push   $0x464
f0101f22:	68 75 78 10 f0       	push   $0xf0107875
f0101f27:	e8 14 e1 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101f2c:	6a 02                	push   $0x2
f0101f2e:	68 00 00 40 00       	push   $0x400000
f0101f33:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101f36:	ff 35 dc 6e 2a f0    	pushl  0xf02a6edc
f0101f3c:	e8 c9 f3 ff ff       	call   f010130a <page_insert>
f0101f41:	83 c4 10             	add    $0x10,%esp
f0101f44:	85 c0                	test   %eax,%eax
f0101f46:	78 19                	js     f0101f61 <mem_init+0xb5f>
f0101f48:	68 54 73 10 f0       	push   $0xf0107354
f0101f4d:	68 9b 78 10 f0       	push   $0xf010789b
f0101f52:	68 67 04 00 00       	push   $0x467
f0101f57:	68 75 78 10 f0       	push   $0xf0107875
f0101f5c:	e8 df e0 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101f61:	6a 02                	push   $0x2
f0101f63:	68 00 10 00 00       	push   $0x1000
f0101f68:	53                   	push   %ebx
f0101f69:	ff 35 dc 6e 2a f0    	pushl  0xf02a6edc
f0101f6f:	e8 96 f3 ff ff       	call   f010130a <page_insert>
f0101f74:	83 c4 10             	add    $0x10,%esp
f0101f77:	85 c0                	test   %eax,%eax
f0101f79:	74 19                	je     f0101f94 <mem_init+0xb92>
f0101f7b:	68 8c 73 10 f0       	push   $0xf010738c
f0101f80:	68 9b 78 10 f0       	push   $0xf010789b
f0101f85:	68 6a 04 00 00       	push   $0x46a
f0101f8a:	68 75 78 10 f0       	push   $0xf0107875
f0101f8f:	e8 ac e0 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f94:	83 ec 04             	sub    $0x4,%esp
f0101f97:	6a 00                	push   $0x0
f0101f99:	68 00 10 00 00       	push   $0x1000
f0101f9e:	ff 35 dc 6e 2a f0    	pushl  0xf02a6edc
f0101fa4:	e8 29 f1 ff ff       	call   f01010d2 <pgdir_walk>
f0101fa9:	83 c4 10             	add    $0x10,%esp
f0101fac:	f6 00 04             	testb  $0x4,(%eax)
f0101faf:	74 19                	je     f0101fca <mem_init+0xbc8>
f0101fb1:	68 1c 73 10 f0       	push   $0xf010731c
f0101fb6:	68 9b 78 10 f0       	push   $0xf010789b
f0101fbb:	68 6b 04 00 00       	push   $0x46b
f0101fc0:	68 75 78 10 f0       	push   $0xf0107875
f0101fc5:	e8 76 e0 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101fca:	8b 3d dc 6e 2a f0    	mov    0xf02a6edc,%edi
f0101fd0:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fd5:	89 f8                	mov    %edi,%eax
f0101fd7:	e8 8d ea ff ff       	call   f0100a69 <check_va2pa>
f0101fdc:	89 c1                	mov    %eax,%ecx
f0101fde:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101fe1:	89 d8                	mov    %ebx,%eax
f0101fe3:	2b 05 e0 6e 2a f0    	sub    0xf02a6ee0,%eax
f0101fe9:	c1 f8 03             	sar    $0x3,%eax
f0101fec:	c1 e0 0c             	shl    $0xc,%eax
f0101fef:	39 c1                	cmp    %eax,%ecx
f0101ff1:	74 19                	je     f010200c <mem_init+0xc0a>
f0101ff3:	68 c8 73 10 f0       	push   $0xf01073c8
f0101ff8:	68 9b 78 10 f0       	push   $0xf010789b
f0101ffd:	68 6e 04 00 00       	push   $0x46e
f0102002:	68 75 78 10 f0       	push   $0xf0107875
f0102007:	e8 34 e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010200c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102011:	89 f8                	mov    %edi,%eax
f0102013:	e8 51 ea ff ff       	call   f0100a69 <check_va2pa>
f0102018:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f010201b:	74 19                	je     f0102036 <mem_init+0xc34>
f010201d:	68 f4 73 10 f0       	push   $0xf01073f4
f0102022:	68 9b 78 10 f0       	push   $0xf010789b
f0102027:	68 6f 04 00 00       	push   $0x46f
f010202c:	68 75 78 10 f0       	push   $0xf0107875
f0102031:	e8 0a e0 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102036:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f010203b:	74 19                	je     f0102056 <mem_init+0xc54>
f010203d:	68 d6 7a 10 f0       	push   $0xf0107ad6
f0102042:	68 9b 78 10 f0       	push   $0xf010789b
f0102047:	68 71 04 00 00       	push   $0x471
f010204c:	68 75 78 10 f0       	push   $0xf0107875
f0102051:	e8 ea df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102056:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010205b:	74 19                	je     f0102076 <mem_init+0xc74>
f010205d:	68 e7 7a 10 f0       	push   $0xf0107ae7
f0102062:	68 9b 78 10 f0       	push   $0xf010789b
f0102067:	68 72 04 00 00       	push   $0x472
f010206c:	68 75 78 10 f0       	push   $0xf0107875
f0102071:	e8 ca df ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102076:	83 ec 0c             	sub    $0xc,%esp
f0102079:	6a 00                	push   $0x0
f010207b:	e8 64 ef ff ff       	call   f0100fe4 <page_alloc>
f0102080:	83 c4 10             	add    $0x10,%esp
f0102083:	85 c0                	test   %eax,%eax
f0102085:	74 04                	je     f010208b <mem_init+0xc89>
f0102087:	39 c6                	cmp    %eax,%esi
f0102089:	74 19                	je     f01020a4 <mem_init+0xca2>
f010208b:	68 24 74 10 f0       	push   $0xf0107424
f0102090:	68 9b 78 10 f0       	push   $0xf010789b
f0102095:	68 75 04 00 00       	push   $0x475
f010209a:	68 75 78 10 f0       	push   $0xf0107875
f010209f:	e8 9c df ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f01020a4:	83 ec 08             	sub    $0x8,%esp
f01020a7:	6a 00                	push   $0x0
f01020a9:	ff 35 dc 6e 2a f0    	pushl  0xf02a6edc
f01020af:	e8 10 f2 ff ff       	call   f01012c4 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01020b4:	8b 3d dc 6e 2a f0    	mov    0xf02a6edc,%edi
f01020ba:	ba 00 00 00 00       	mov    $0x0,%edx
f01020bf:	89 f8                	mov    %edi,%eax
f01020c1:	e8 a3 e9 ff ff       	call   f0100a69 <check_va2pa>
f01020c6:	83 c4 10             	add    $0x10,%esp
f01020c9:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020cc:	74 19                	je     f01020e7 <mem_init+0xce5>
f01020ce:	68 48 74 10 f0       	push   $0xf0107448
f01020d3:	68 9b 78 10 f0       	push   $0xf010789b
f01020d8:	68 79 04 00 00       	push   $0x479
f01020dd:	68 75 78 10 f0       	push   $0xf0107875
f01020e2:	e8 59 df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01020e7:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020ec:	89 f8                	mov    %edi,%eax
f01020ee:	e8 76 e9 ff ff       	call   f0100a69 <check_va2pa>
f01020f3:	89 da                	mov    %ebx,%edx
f01020f5:	2b 15 e0 6e 2a f0    	sub    0xf02a6ee0,%edx
f01020fb:	c1 fa 03             	sar    $0x3,%edx
f01020fe:	c1 e2 0c             	shl    $0xc,%edx
f0102101:	39 d0                	cmp    %edx,%eax
f0102103:	74 19                	je     f010211e <mem_init+0xd1c>
f0102105:	68 f4 73 10 f0       	push   $0xf01073f4
f010210a:	68 9b 78 10 f0       	push   $0xf010789b
f010210f:	68 7a 04 00 00       	push   $0x47a
f0102114:	68 75 78 10 f0       	push   $0xf0107875
f0102119:	e8 22 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f010211e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102123:	74 19                	je     f010213e <mem_init+0xd3c>
f0102125:	68 8d 7a 10 f0       	push   $0xf0107a8d
f010212a:	68 9b 78 10 f0       	push   $0xf010789b
f010212f:	68 7b 04 00 00       	push   $0x47b
f0102134:	68 75 78 10 f0       	push   $0xf0107875
f0102139:	e8 02 df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010213e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102143:	74 19                	je     f010215e <mem_init+0xd5c>
f0102145:	68 e7 7a 10 f0       	push   $0xf0107ae7
f010214a:	68 9b 78 10 f0       	push   $0xf010789b
f010214f:	68 7c 04 00 00       	push   $0x47c
f0102154:	68 75 78 10 f0       	push   $0xf0107875
f0102159:	e8 e2 de ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f010215e:	6a 00                	push   $0x0
f0102160:	68 00 10 00 00       	push   $0x1000
f0102165:	53                   	push   %ebx
f0102166:	57                   	push   %edi
f0102167:	e8 9e f1 ff ff       	call   f010130a <page_insert>
f010216c:	83 c4 10             	add    $0x10,%esp
f010216f:	85 c0                	test   %eax,%eax
f0102171:	74 19                	je     f010218c <mem_init+0xd8a>
f0102173:	68 6c 74 10 f0       	push   $0xf010746c
f0102178:	68 9b 78 10 f0       	push   $0xf010789b
f010217d:	68 7f 04 00 00       	push   $0x47f
f0102182:	68 75 78 10 f0       	push   $0xf0107875
f0102187:	e8 b4 de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f010218c:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102191:	75 19                	jne    f01021ac <mem_init+0xdaa>
f0102193:	68 f8 7a 10 f0       	push   $0xf0107af8
f0102198:	68 9b 78 10 f0       	push   $0xf010789b
f010219d:	68 80 04 00 00       	push   $0x480
f01021a2:	68 75 78 10 f0       	push   $0xf0107875
f01021a7:	e8 94 de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f01021ac:	83 3b 00             	cmpl   $0x0,(%ebx)
f01021af:	74 19                	je     f01021ca <mem_init+0xdc8>
f01021b1:	68 04 7b 10 f0       	push   $0xf0107b04
f01021b6:	68 9b 78 10 f0       	push   $0xf010789b
f01021bb:	68 81 04 00 00       	push   $0x481
f01021c0:	68 75 78 10 f0       	push   $0xf0107875
f01021c5:	e8 76 de ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01021ca:	83 ec 08             	sub    $0x8,%esp
f01021cd:	68 00 10 00 00       	push   $0x1000
f01021d2:	ff 35 dc 6e 2a f0    	pushl  0xf02a6edc
f01021d8:	e8 e7 f0 ff ff       	call   f01012c4 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01021dd:	8b 3d dc 6e 2a f0    	mov    0xf02a6edc,%edi
f01021e3:	ba 00 00 00 00       	mov    $0x0,%edx
f01021e8:	89 f8                	mov    %edi,%eax
f01021ea:	e8 7a e8 ff ff       	call   f0100a69 <check_va2pa>
f01021ef:	83 c4 10             	add    $0x10,%esp
f01021f2:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021f5:	74 19                	je     f0102210 <mem_init+0xe0e>
f01021f7:	68 48 74 10 f0       	push   $0xf0107448
f01021fc:	68 9b 78 10 f0       	push   $0xf010789b
f0102201:	68 85 04 00 00       	push   $0x485
f0102206:	68 75 78 10 f0       	push   $0xf0107875
f010220b:	e8 30 de ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102210:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102215:	89 f8                	mov    %edi,%eax
f0102217:	e8 4d e8 ff ff       	call   f0100a69 <check_va2pa>
f010221c:	83 f8 ff             	cmp    $0xffffffff,%eax
f010221f:	74 19                	je     f010223a <mem_init+0xe38>
f0102221:	68 a4 74 10 f0       	push   $0xf01074a4
f0102226:	68 9b 78 10 f0       	push   $0xf010789b
f010222b:	68 86 04 00 00       	push   $0x486
f0102230:	68 75 78 10 f0       	push   $0xf0107875
f0102235:	e8 06 de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f010223a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010223f:	74 19                	je     f010225a <mem_init+0xe58>
f0102241:	68 19 7b 10 f0       	push   $0xf0107b19
f0102246:	68 9b 78 10 f0       	push   $0xf010789b
f010224b:	68 87 04 00 00       	push   $0x487
f0102250:	68 75 78 10 f0       	push   $0xf0107875
f0102255:	e8 e6 dd ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010225a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010225f:	74 19                	je     f010227a <mem_init+0xe78>
f0102261:	68 e7 7a 10 f0       	push   $0xf0107ae7
f0102266:	68 9b 78 10 f0       	push   $0xf010789b
f010226b:	68 88 04 00 00       	push   $0x488
f0102270:	68 75 78 10 f0       	push   $0xf0107875
f0102275:	e8 c6 dd ff ff       	call   f0100040 <_panic>
	
	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010227a:	83 ec 0c             	sub    $0xc,%esp
f010227d:	6a 00                	push   $0x0
f010227f:	e8 60 ed ff ff       	call   f0100fe4 <page_alloc>
f0102284:	83 c4 10             	add    $0x10,%esp
f0102287:	85 c0                	test   %eax,%eax
f0102289:	74 04                	je     f010228f <mem_init+0xe8d>
f010228b:	39 c3                	cmp    %eax,%ebx
f010228d:	74 19                	je     f01022a8 <mem_init+0xea6>
f010228f:	68 cc 74 10 f0       	push   $0xf01074cc
f0102294:	68 9b 78 10 f0       	push   $0xf010789b
f0102299:	68 8b 04 00 00       	push   $0x48b
f010229e:	68 75 78 10 f0       	push   $0xf0107875
f01022a3:	e8 98 dd ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01022a8:	83 ec 0c             	sub    $0xc,%esp
f01022ab:	6a 00                	push   $0x0
f01022ad:	e8 32 ed ff ff       	call   f0100fe4 <page_alloc>
f01022b2:	83 c4 10             	add    $0x10,%esp
f01022b5:	85 c0                	test   %eax,%eax
f01022b7:	74 19                	je     f01022d2 <mem_init+0xed0>
f01022b9:	68 3b 7a 10 f0       	push   $0xf0107a3b
f01022be:	68 9b 78 10 f0       	push   $0xf010789b
f01022c3:	68 8e 04 00 00       	push   $0x48e
f01022c8:	68 75 78 10 f0       	push   $0xf0107875
f01022cd:	e8 6e dd ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01022d2:	8b 0d dc 6e 2a f0    	mov    0xf02a6edc,%ecx
f01022d8:	8b 11                	mov    (%ecx),%edx
f01022da:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01022e0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022e3:	2b 05 e0 6e 2a f0    	sub    0xf02a6ee0,%eax
f01022e9:	c1 f8 03             	sar    $0x3,%eax
f01022ec:	c1 e0 0c             	shl    $0xc,%eax
f01022ef:	39 c2                	cmp    %eax,%edx
f01022f1:	74 19                	je     f010230c <mem_init+0xf0a>
f01022f3:	68 70 71 10 f0       	push   $0xf0107170
f01022f8:	68 9b 78 10 f0       	push   $0xf010789b
f01022fd:	68 91 04 00 00       	push   $0x491
f0102302:	68 75 78 10 f0       	push   $0xf0107875
f0102307:	e8 34 dd ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f010230c:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102312:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102315:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010231a:	74 19                	je     f0102335 <mem_init+0xf33>
f010231c:	68 9e 7a 10 f0       	push   $0xf0107a9e
f0102321:	68 9b 78 10 f0       	push   $0xf010789b
f0102326:	68 93 04 00 00       	push   $0x493
f010232b:	68 75 78 10 f0       	push   $0xf0107875
f0102330:	e8 0b dd ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102335:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102338:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010233e:	83 ec 0c             	sub    $0xc,%esp
f0102341:	50                   	push   %eax
f0102342:	e8 13 ed ff ff       	call   f010105a <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102347:	83 c4 0c             	add    $0xc,%esp
f010234a:	6a 01                	push   $0x1
f010234c:	68 00 10 40 00       	push   $0x401000
f0102351:	ff 35 dc 6e 2a f0    	pushl  0xf02a6edc
f0102357:	e8 76 ed ff ff       	call   f01010d2 <pgdir_walk>
f010235c:	89 c7                	mov    %eax,%edi
f010235e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102361:	a1 dc 6e 2a f0       	mov    0xf02a6edc,%eax
f0102366:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102369:	8b 40 04             	mov    0x4(%eax),%eax
f010236c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102371:	8b 0d d8 6e 2a f0    	mov    0xf02a6ed8,%ecx
f0102377:	89 c2                	mov    %eax,%edx
f0102379:	c1 ea 0c             	shr    $0xc,%edx
f010237c:	83 c4 10             	add    $0x10,%esp
f010237f:	39 ca                	cmp    %ecx,%edx
f0102381:	72 15                	jb     f0102398 <mem_init+0xf96>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102383:	50                   	push   %eax
f0102384:	68 e4 68 10 f0       	push   $0xf01068e4
f0102389:	68 9a 04 00 00       	push   $0x49a
f010238e:	68 75 78 10 f0       	push   $0xf0107875
f0102393:	e8 a8 dc ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102398:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f010239d:	39 c7                	cmp    %eax,%edi
f010239f:	74 19                	je     f01023ba <mem_init+0xfb8>
f01023a1:	68 2a 7b 10 f0       	push   $0xf0107b2a
f01023a6:	68 9b 78 10 f0       	push   $0xf010789b
f01023ab:	68 9b 04 00 00       	push   $0x49b
f01023b0:	68 75 78 10 f0       	push   $0xf0107875
f01023b5:	e8 86 dc ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01023ba:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01023bd:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f01023c4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01023c7:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01023cd:	2b 05 e0 6e 2a f0    	sub    0xf02a6ee0,%eax
f01023d3:	c1 f8 03             	sar    $0x3,%eax
f01023d6:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01023d9:	89 c2                	mov    %eax,%edx
f01023db:	c1 ea 0c             	shr    $0xc,%edx
f01023de:	39 d1                	cmp    %edx,%ecx
f01023e0:	77 12                	ja     f01023f4 <mem_init+0xff2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01023e2:	50                   	push   %eax
f01023e3:	68 e4 68 10 f0       	push   $0xf01068e4
f01023e8:	6a 58                	push   $0x58
f01023ea:	68 81 78 10 f0       	push   $0xf0107881
f01023ef:	e8 4c dc ff ff       	call   f0100040 <_panic>
	
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01023f4:	83 ec 04             	sub    $0x4,%esp
f01023f7:	68 00 10 00 00       	push   $0x1000
f01023fc:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0102401:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102406:	50                   	push   %eax
f0102407:	e8 16 30 00 00       	call   f0105422 <memset>
	page_free(pp0);
f010240c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010240f:	89 3c 24             	mov    %edi,(%esp)
f0102412:	e8 43 ec ff ff       	call   f010105a <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102417:	83 c4 0c             	add    $0xc,%esp
f010241a:	6a 01                	push   $0x1
f010241c:	6a 00                	push   $0x0
f010241e:	ff 35 dc 6e 2a f0    	pushl  0xf02a6edc
f0102424:	e8 a9 ec ff ff       	call   f01010d2 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102429:	89 fa                	mov    %edi,%edx
f010242b:	2b 15 e0 6e 2a f0    	sub    0xf02a6ee0,%edx
f0102431:	c1 fa 03             	sar    $0x3,%edx
f0102434:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102437:	89 d0                	mov    %edx,%eax
f0102439:	c1 e8 0c             	shr    $0xc,%eax
f010243c:	83 c4 10             	add    $0x10,%esp
f010243f:	3b 05 d8 6e 2a f0    	cmp    0xf02a6ed8,%eax
f0102445:	72 12                	jb     f0102459 <mem_init+0x1057>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102447:	52                   	push   %edx
f0102448:	68 e4 68 10 f0       	push   $0xf01068e4
f010244d:	6a 58                	push   $0x58
f010244f:	68 81 78 10 f0       	push   $0xf0107881
f0102454:	e8 e7 db ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102459:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010245f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102462:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102468:	f6 00 01             	testb  $0x1,(%eax)
f010246b:	74 19                	je     f0102486 <mem_init+0x1084>
f010246d:	68 42 7b 10 f0       	push   $0xf0107b42
f0102472:	68 9b 78 10 f0       	push   $0xf010789b
f0102477:	68 a5 04 00 00       	push   $0x4a5
f010247c:	68 75 78 10 f0       	push   $0xf0107875
f0102481:	e8 ba db ff ff       	call   f0100040 <_panic>
f0102486:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102489:	39 d0                	cmp    %edx,%eax
f010248b:	75 db                	jne    f0102468 <mem_init+0x1066>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010248d:	a1 dc 6e 2a f0       	mov    0xf02a6edc,%eax
f0102492:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102498:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010249b:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01024a1:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01024a4:	89 0d 64 62 2a f0    	mov    %ecx,0xf02a6264

	// free the pages we took
	page_free(pp0);
f01024aa:	83 ec 0c             	sub    $0xc,%esp
f01024ad:	50                   	push   %eax
f01024ae:	e8 a7 eb ff ff       	call   f010105a <page_free>
	page_free(pp1);
f01024b3:	89 1c 24             	mov    %ebx,(%esp)
f01024b6:	e8 9f eb ff ff       	call   f010105a <page_free>
	page_free(pp2);
f01024bb:	89 34 24             	mov    %esi,(%esp)
f01024be:	e8 97 eb ff ff       	call   f010105a <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f01024c3:	83 c4 08             	add    $0x8,%esp
f01024c6:	68 01 10 00 00       	push   $0x1001
f01024cb:	6a 00                	push   $0x0
f01024cd:	e8 f1 ee ff ff       	call   f01013c3 <mmio_map_region>
f01024d2:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f01024d4:	83 c4 08             	add    $0x8,%esp
f01024d7:	68 00 10 00 00       	push   $0x1000
f01024dc:	6a 00                	push   $0x0
f01024de:	e8 e0 ee ff ff       	call   f01013c3 <mmio_map_region>
f01024e3:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f01024e5:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f01024eb:	83 c4 10             	add    $0x10,%esp
f01024ee:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f01024f3:	77 08                	ja     f01024fd <mem_init+0x10fb>
f01024f5:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f01024fb:	77 19                	ja     f0102516 <mem_init+0x1114>
f01024fd:	68 f0 74 10 f0       	push   $0xf01074f0
f0102502:	68 9b 78 10 f0       	push   $0xf010789b
f0102507:	68 b5 04 00 00       	push   $0x4b5
f010250c:	68 75 78 10 f0       	push   $0xf0107875
f0102511:	e8 2a db ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f0102516:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f010251c:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f0102522:	77 08                	ja     f010252c <mem_init+0x112a>
f0102524:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010252a:	77 19                	ja     f0102545 <mem_init+0x1143>
f010252c:	68 18 75 10 f0       	push   $0xf0107518
f0102531:	68 9b 78 10 f0       	push   $0xf010789b
f0102536:	68 b6 04 00 00       	push   $0x4b6
f010253b:	68 75 78 10 f0       	push   $0xf0107875
f0102540:	e8 fb da ff ff       	call   f0100040 <_panic>
f0102545:	89 da                	mov    %ebx,%edx
f0102547:	09 f2                	or     %esi,%edx
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102549:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f010254f:	74 19                	je     f010256a <mem_init+0x1168>
f0102551:	68 40 75 10 f0       	push   $0xf0107540
f0102556:	68 9b 78 10 f0       	push   $0xf010789b
f010255b:	68 b8 04 00 00       	push   $0x4b8
f0102560:	68 75 78 10 f0       	push   $0xf0107875
f0102565:	e8 d6 da ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f010256a:	39 c6                	cmp    %eax,%esi
f010256c:	73 19                	jae    f0102587 <mem_init+0x1185>
f010256e:	68 59 7b 10 f0       	push   $0xf0107b59
f0102573:	68 9b 78 10 f0       	push   $0xf010789b
f0102578:	68 ba 04 00 00       	push   $0x4ba
f010257d:	68 75 78 10 f0       	push   $0xf0107875
f0102582:	e8 b9 da ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102587:	8b 3d dc 6e 2a f0    	mov    0xf02a6edc,%edi
f010258d:	89 da                	mov    %ebx,%edx
f010258f:	89 f8                	mov    %edi,%eax
f0102591:	e8 d3 e4 ff ff       	call   f0100a69 <check_va2pa>
f0102596:	85 c0                	test   %eax,%eax
f0102598:	74 19                	je     f01025b3 <mem_init+0x11b1>
f010259a:	68 68 75 10 f0       	push   $0xf0107568
f010259f:	68 9b 78 10 f0       	push   $0xf010789b
f01025a4:	68 bc 04 00 00       	push   $0x4bc
f01025a9:	68 75 78 10 f0       	push   $0xf0107875
f01025ae:	e8 8d da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f01025b3:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f01025b9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01025bc:	89 c2                	mov    %eax,%edx
f01025be:	89 f8                	mov    %edi,%eax
f01025c0:	e8 a4 e4 ff ff       	call   f0100a69 <check_va2pa>
f01025c5:	3d 00 10 00 00       	cmp    $0x1000,%eax
f01025ca:	74 19                	je     f01025e5 <mem_init+0x11e3>
f01025cc:	68 8c 75 10 f0       	push   $0xf010758c
f01025d1:	68 9b 78 10 f0       	push   $0xf010789b
f01025d6:	68 bd 04 00 00       	push   $0x4bd
f01025db:	68 75 78 10 f0       	push   $0xf0107875
f01025e0:	e8 5b da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f01025e5:	89 f2                	mov    %esi,%edx
f01025e7:	89 f8                	mov    %edi,%eax
f01025e9:	e8 7b e4 ff ff       	call   f0100a69 <check_va2pa>
f01025ee:	85 c0                	test   %eax,%eax
f01025f0:	74 19                	je     f010260b <mem_init+0x1209>
f01025f2:	68 bc 75 10 f0       	push   $0xf01075bc
f01025f7:	68 9b 78 10 f0       	push   $0xf010789b
f01025fc:	68 be 04 00 00       	push   $0x4be
f0102601:	68 75 78 10 f0       	push   $0xf0107875
f0102606:	e8 35 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f010260b:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f0102611:	89 f8                	mov    %edi,%eax
f0102613:	e8 51 e4 ff ff       	call   f0100a69 <check_va2pa>
f0102618:	83 f8 ff             	cmp    $0xffffffff,%eax
f010261b:	74 19                	je     f0102636 <mem_init+0x1234>
f010261d:	68 e0 75 10 f0       	push   $0xf01075e0
f0102622:	68 9b 78 10 f0       	push   $0xf010789b
f0102627:	68 bf 04 00 00       	push   $0x4bf
f010262c:	68 75 78 10 f0       	push   $0xf0107875
f0102631:	e8 0a da ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102636:	83 ec 04             	sub    $0x4,%esp
f0102639:	6a 00                	push   $0x0
f010263b:	53                   	push   %ebx
f010263c:	57                   	push   %edi
f010263d:	e8 90 ea ff ff       	call   f01010d2 <pgdir_walk>
f0102642:	83 c4 10             	add    $0x10,%esp
f0102645:	f6 00 1a             	testb  $0x1a,(%eax)
f0102648:	75 19                	jne    f0102663 <mem_init+0x1261>
f010264a:	68 0c 76 10 f0       	push   $0xf010760c
f010264f:	68 9b 78 10 f0       	push   $0xf010789b
f0102654:	68 c1 04 00 00       	push   $0x4c1
f0102659:	68 75 78 10 f0       	push   $0xf0107875
f010265e:	e8 dd d9 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102663:	83 ec 04             	sub    $0x4,%esp
f0102666:	6a 00                	push   $0x0
f0102668:	53                   	push   %ebx
f0102669:	ff 35 dc 6e 2a f0    	pushl  0xf02a6edc
f010266f:	e8 5e ea ff ff       	call   f01010d2 <pgdir_walk>
f0102674:	83 c4 10             	add    $0x10,%esp
f0102677:	f6 00 04             	testb  $0x4,(%eax)
f010267a:	74 19                	je     f0102695 <mem_init+0x1293>
f010267c:	68 50 76 10 f0       	push   $0xf0107650
f0102681:	68 9b 78 10 f0       	push   $0xf010789b
f0102686:	68 c2 04 00 00       	push   $0x4c2
f010268b:	68 75 78 10 f0       	push   $0xf0107875
f0102690:	e8 ab d9 ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f0102695:	83 ec 04             	sub    $0x4,%esp
f0102698:	6a 00                	push   $0x0
f010269a:	53                   	push   %ebx
f010269b:	ff 35 dc 6e 2a f0    	pushl  0xf02a6edc
f01026a1:	e8 2c ea ff ff       	call   f01010d2 <pgdir_walk>
f01026a6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f01026ac:	83 c4 0c             	add    $0xc,%esp
f01026af:	6a 00                	push   $0x0
f01026b1:	ff 75 d4             	pushl  -0x2c(%ebp)
f01026b4:	ff 35 dc 6e 2a f0    	pushl  0xf02a6edc
f01026ba:	e8 13 ea ff ff       	call   f01010d2 <pgdir_walk>
f01026bf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f01026c5:	83 c4 0c             	add    $0xc,%esp
f01026c8:	6a 00                	push   $0x0
f01026ca:	56                   	push   %esi
f01026cb:	ff 35 dc 6e 2a f0    	pushl  0xf02a6edc
f01026d1:	e8 fc e9 ff ff       	call   f01010d2 <pgdir_walk>
f01026d6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f01026dc:	c7 04 24 6b 7b 10 f0 	movl   $0xf0107b6b,(%esp)
f01026e3:	e8 62 11 00 00       	call   f010384a <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, ROUNDUP( (sizeof(struct PageInfo)*npages),PGSIZE), PADDR(pages), PTE_U | PTE_P);
f01026e8:	a1 e0 6e 2a f0       	mov    0xf02a6ee0,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026ed:	83 c4 10             	add    $0x10,%esp
f01026f0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01026f5:	77 15                	ja     f010270c <mem_init+0x130a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026f7:	50                   	push   %eax
f01026f8:	68 08 69 10 f0       	push   $0xf0106908
f01026fd:	68 c5 00 00 00       	push   $0xc5
f0102702:	68 75 78 10 f0       	push   $0xf0107875
f0102707:	e8 34 d9 ff ff       	call   f0100040 <_panic>
f010270c:	8b 15 d8 6e 2a f0    	mov    0xf02a6ed8,%edx
f0102712:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f0102719:	83 ec 08             	sub    $0x8,%esp
f010271c:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102722:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f0102724:	05 00 00 00 10       	add    $0x10000000,%eax
f0102729:	50                   	push   %eax
f010272a:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010272f:	a1 dc 6e 2a f0       	mov    0xf02a6edc,%eax
f0102734:	e8 84 ea ff ff       	call   f01011bd <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, sizeof(struct Env) * NENV,PADDR(envs), PTE_U);
f0102739:	a1 6c 62 2a f0       	mov    0xf02a626c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010273e:	83 c4 10             	add    $0x10,%esp
f0102741:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102746:	77 15                	ja     f010275d <mem_init+0x135b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102748:	50                   	push   %eax
f0102749:	68 08 69 10 f0       	push   $0xf0106908
f010274e:	68 cd 00 00 00       	push   $0xcd
f0102753:	68 75 78 10 f0       	push   $0xf0107875
f0102758:	e8 e3 d8 ff ff       	call   f0100040 <_panic>
f010275d:	83 ec 08             	sub    $0x8,%esp
f0102760:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f0102762:	05 00 00 00 10       	add    $0x10000000,%eax
f0102767:	50                   	push   %eax
f0102768:	b9 00 f0 01 00       	mov    $0x1f000,%ecx
f010276d:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102772:	a1 dc 6e 2a f0       	mov    0xf02a6edc,%eax
f0102777:	e8 41 ea ff ff       	call   f01011bd <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010277c:	83 c4 10             	add    $0x10,%esp
f010277f:	b8 00 90 11 f0       	mov    $0xf0119000,%eax
f0102784:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102789:	77 15                	ja     f01027a0 <mem_init+0x139e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010278b:	50                   	push   %eax
f010278c:	68 08 69 10 f0       	push   $0xf0106908
f0102791:	68 d9 00 00 00       	push   $0xd9
f0102796:	68 75 78 10 f0       	push   $0xf0107875
f010279b:	e8 a0 d8 ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W | PTE_P);
f01027a0:	83 ec 08             	sub    $0x8,%esp
f01027a3:	6a 03                	push   $0x3
f01027a5:	68 00 90 11 00       	push   $0x119000
f01027aa:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01027af:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01027b4:	a1 dc 6e 2a f0       	mov    0xf02a6edc,%eax
f01027b9:	e8 ff e9 ff ff       	call   f01011bd <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	size_t size = ROUNDUP(0xFFFFFFFF - KERNBASE + 1, PGSIZE);
	boot_map_region(kern_pgdir, KERNBASE, size, 0, PTE_W | PTE_P);
f01027be:	83 c4 08             	add    $0x8,%esp
f01027c1:	6a 03                	push   $0x3
f01027c3:	6a 00                	push   $0x0
f01027c5:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01027ca:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01027cf:	a1 dc 6e 2a f0       	mov    0xf02a6edc,%eax
f01027d4:	e8 e4 e9 ff ff       	call   f01011bd <boot_map_region>
f01027d9:	c7 45 c4 00 80 2a f0 	movl   $0xf02a8000,-0x3c(%ebp)
f01027e0:	83 c4 10             	add    $0x10,%esp
f01027e3:	bb 00 80 2a f0       	mov    $0xf02a8000,%ebx
f01027e8:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027ed:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f01027f3:	77 15                	ja     f010280a <mem_init+0x1408>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027f5:	53                   	push   %ebx
f01027f6:	68 08 69 10 f0       	push   $0xf0106908
f01027fb:	68 20 01 00 00       	push   $0x120
f0102800:	68 75 78 10 f0       	push   $0xf0107875
f0102805:	e8 36 d8 ff ff       	call   f0100040 <_panic>
	uint32_t percpu_stacktop = KSTACKTOP;
	//uint32_t percpu_stackbtm;
	
	for (i=0;i<NCPU;i++)
	{	
		boot_map_region(kern_pgdir, percpu_stacktop - KSTKSIZE, KSTKSIZE,PADDR((void*)percpu_kstacks[i]), PTE_W | PTE_P);
f010280a:	83 ec 08             	sub    $0x8,%esp
f010280d:	6a 03                	push   $0x3
f010280f:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f0102815:	50                   	push   %eax
f0102816:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010281b:	89 f2                	mov    %esi,%edx
f010281d:	a1 dc 6e 2a f0       	mov    0xf02a6edc,%eax
f0102822:	e8 96 e9 ff ff       	call   f01011bd <boot_map_region>
f0102827:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f010282d:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	
	int i=0;
	uint32_t percpu_stacktop = KSTACKTOP;
	//uint32_t percpu_stackbtm;
	
	for (i=0;i<NCPU;i++)
f0102833:	83 c4 10             	add    $0x10,%esp
f0102836:	81 fb 00 80 2e f0    	cmp    $0xf02e8000,%ebx
f010283c:	75 af                	jne    f01027ed <mem_init+0x13eb>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010283e:	8b 3d dc 6e 2a f0    	mov    0xf02a6edc,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102844:	a1 d8 6e 2a f0       	mov    0xf02a6ed8,%eax
f0102849:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010284c:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102853:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102858:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010285b:	8b 35 e0 6e 2a f0    	mov    0xf02a6ee0,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102861:	89 75 d0             	mov    %esi,-0x30(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102864:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102869:	eb 55                	jmp    f01028c0 <mem_init+0x14be>
f010286b:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102871:	89 f8                	mov    %edi,%eax
f0102873:	e8 f1 e1 ff ff       	call   f0100a69 <check_va2pa>
f0102878:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f010287f:	77 15                	ja     f0102896 <mem_init+0x1494>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102881:	56                   	push   %esi
f0102882:	68 08 69 10 f0       	push   $0xf0106908
f0102887:	68 d7 03 00 00       	push   $0x3d7
f010288c:	68 75 78 10 f0       	push   $0xf0107875
f0102891:	e8 aa d7 ff ff       	call   f0100040 <_panic>
f0102896:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f010289d:	39 d0                	cmp    %edx,%eax
f010289f:	74 19                	je     f01028ba <mem_init+0x14b8>
f01028a1:	68 84 76 10 f0       	push   $0xf0107684
f01028a6:	68 9b 78 10 f0       	push   $0xf010789b
f01028ab:	68 d7 03 00 00       	push   $0x3d7
f01028b0:	68 75 78 10 f0       	push   $0xf0107875
f01028b5:	e8 86 d7 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01028ba:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01028c0:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01028c3:	77 a6                	ja     f010286b <mem_init+0x1469>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01028c5:	8b 35 6c 62 2a f0    	mov    0xf02a626c,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028cb:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01028ce:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f01028d3:	89 da                	mov    %ebx,%edx
f01028d5:	89 f8                	mov    %edi,%eax
f01028d7:	e8 8d e1 ff ff       	call   f0100a69 <check_va2pa>
f01028dc:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f01028e3:	77 15                	ja     f01028fa <mem_init+0x14f8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028e5:	56                   	push   %esi
f01028e6:	68 08 69 10 f0       	push   $0xf0106908
f01028eb:	68 dc 03 00 00       	push   $0x3dc
f01028f0:	68 75 78 10 f0       	push   $0xf0107875
f01028f5:	e8 46 d7 ff ff       	call   f0100040 <_panic>
f01028fa:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f0102901:	39 d0                	cmp    %edx,%eax
f0102903:	74 19                	je     f010291e <mem_init+0x151c>
f0102905:	68 b8 76 10 f0       	push   $0xf01076b8
f010290a:	68 9b 78 10 f0       	push   $0xf010789b
f010290f:	68 dc 03 00 00       	push   $0x3dc
f0102914:	68 75 78 10 f0       	push   $0xf0107875
f0102919:	e8 22 d7 ff ff       	call   f0100040 <_panic>
f010291e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102924:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f010292a:	75 a7                	jne    f01028d3 <mem_init+0x14d1>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010292c:	8b 75 cc             	mov    -0x34(%ebp),%esi
f010292f:	c1 e6 0c             	shl    $0xc,%esi
f0102932:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102937:	eb 30                	jmp    f0102969 <mem_init+0x1567>
f0102939:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010293f:	89 f8                	mov    %edi,%eax
f0102941:	e8 23 e1 ff ff       	call   f0100a69 <check_va2pa>
f0102946:	39 c3                	cmp    %eax,%ebx
f0102948:	74 19                	je     f0102963 <mem_init+0x1561>
f010294a:	68 ec 76 10 f0       	push   $0xf01076ec
f010294f:	68 9b 78 10 f0       	push   $0xf010789b
f0102954:	68 e0 03 00 00       	push   $0x3e0
f0102959:	68 75 78 10 f0       	push   $0xf0107875
f010295e:	e8 dd d6 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102963:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102969:	39 f3                	cmp    %esi,%ebx
f010296b:	72 cc                	jb     f0102939 <mem_init+0x1537>
f010296d:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
f0102974:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102979:	89 75 cc             	mov    %esi,-0x34(%ebp)
f010297c:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f010297f:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102982:	8d 88 00 80 00 00    	lea    0x8000(%eax),%ecx
f0102988:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f010298b:	89 c3                	mov    %eax,%ebx
f010298d:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102990:	05 00 80 00 20       	add    $0x20008000,%eax
f0102995:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102998:	89 da                	mov    %ebx,%edx
f010299a:	89 f8                	mov    %edi,%eax
f010299c:	e8 c8 e0 ff ff       	call   f0100a69 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01029a1:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f01029a7:	77 15                	ja     f01029be <mem_init+0x15bc>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029a9:	56                   	push   %esi
f01029aa:	68 08 69 10 f0       	push   $0xf0106908
f01029af:	68 e8 03 00 00       	push   $0x3e8
f01029b4:	68 75 78 10 f0       	push   $0xf0107875
f01029b9:	e8 82 d6 ff ff       	call   f0100040 <_panic>
f01029be:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01029c1:	8d 94 0b 00 80 2a f0 	lea    -0xfd58000(%ebx,%ecx,1),%edx
f01029c8:	39 d0                	cmp    %edx,%eax
f01029ca:	74 19                	je     f01029e5 <mem_init+0x15e3>
f01029cc:	68 14 77 10 f0       	push   $0xf0107714
f01029d1:	68 9b 78 10 f0       	push   $0xf010789b
f01029d6:	68 e8 03 00 00       	push   $0x3e8
f01029db:	68 75 78 10 f0       	push   $0xf0107875
f01029e0:	e8 5b d6 ff ff       	call   f0100040 <_panic>
f01029e5:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01029eb:	3b 5d d0             	cmp    -0x30(%ebp),%ebx
f01029ee:	75 a8                	jne    f0102998 <mem_init+0x1596>
f01029f0:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01029f3:	8d 98 00 80 ff ff    	lea    -0x8000(%eax),%ebx
f01029f9:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01029fc:	89 c6                	mov    %eax,%esi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f01029fe:	89 da                	mov    %ebx,%edx
f0102a00:	89 f8                	mov    %edi,%eax
f0102a02:	e8 62 e0 ff ff       	call   f0100a69 <check_va2pa>
f0102a07:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102a0a:	74 19                	je     f0102a25 <mem_init+0x1623>
f0102a0c:	68 5c 77 10 f0       	push   $0xf010775c
f0102a11:	68 9b 78 10 f0       	push   $0xf010789b
f0102a16:	68 ea 03 00 00       	push   $0x3ea
f0102a1b:	68 75 78 10 f0       	push   $0xf0107875
f0102a20:	e8 1b d6 ff ff       	call   f0100040 <_panic>
f0102a25:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f0102a2b:	39 de                	cmp    %ebx,%esi
f0102a2d:	75 cf                	jne    f01029fe <mem_init+0x15fc>
f0102a2f:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102a32:	81 6d cc 00 00 01 00 	subl   $0x10000,-0x34(%ebp)
f0102a39:	81 45 c8 00 80 01 00 	addl   $0x18000,-0x38(%ebp)
f0102a40:	81 c6 00 80 00 00    	add    $0x8000,%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f0102a46:	81 fe 00 80 2e f0    	cmp    $0xf02e8000,%esi
f0102a4c:	0f 85 2d ff ff ff    	jne    f010297f <mem_init+0x157d>
f0102a52:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a57:	eb 2a                	jmp    f0102a83 <mem_init+0x1681>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102a59:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0102a5f:	83 fa 04             	cmp    $0x4,%edx
f0102a62:	77 1f                	ja     f0102a83 <mem_init+0x1681>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f0102a64:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0102a68:	75 7e                	jne    f0102ae8 <mem_init+0x16e6>
f0102a6a:	68 84 7b 10 f0       	push   $0xf0107b84
f0102a6f:	68 9b 78 10 f0       	push   $0xf010789b
f0102a74:	68 f5 03 00 00       	push   $0x3f5
f0102a79:	68 75 78 10 f0       	push   $0xf0107875
f0102a7e:	e8 bd d5 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102a83:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102a88:	76 3f                	jbe    f0102ac9 <mem_init+0x16c7>
				assert(pgdir[i] & PTE_P);
f0102a8a:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0102a8d:	f6 c2 01             	test   $0x1,%dl
f0102a90:	75 19                	jne    f0102aab <mem_init+0x16a9>
f0102a92:	68 84 7b 10 f0       	push   $0xf0107b84
f0102a97:	68 9b 78 10 f0       	push   $0xf010789b
f0102a9c:	68 f9 03 00 00       	push   $0x3f9
f0102aa1:	68 75 78 10 f0       	push   $0xf0107875
f0102aa6:	e8 95 d5 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f0102aab:	f6 c2 02             	test   $0x2,%dl
f0102aae:	75 38                	jne    f0102ae8 <mem_init+0x16e6>
f0102ab0:	68 95 7b 10 f0       	push   $0xf0107b95
f0102ab5:	68 9b 78 10 f0       	push   $0xf010789b
f0102aba:	68 fa 03 00 00       	push   $0x3fa
f0102abf:	68 75 78 10 f0       	push   $0xf0107875
f0102ac4:	e8 77 d5 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102ac9:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102acd:	74 19                	je     f0102ae8 <mem_init+0x16e6>
f0102acf:	68 a6 7b 10 f0       	push   $0xf0107ba6
f0102ad4:	68 9b 78 10 f0       	push   $0xf010789b
f0102ad9:	68 fc 03 00 00       	push   $0x3fc
f0102ade:	68 75 78 10 f0       	push   $0xf0107875
f0102ae3:	e8 58 d5 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102ae8:	83 c0 01             	add    $0x1,%eax
f0102aeb:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102af0:	0f 86 63 ff ff ff    	jbe    f0102a59 <mem_init+0x1657>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102af6:	83 ec 0c             	sub    $0xc,%esp
f0102af9:	68 80 77 10 f0       	push   $0xf0107780
f0102afe:	e8 47 0d 00 00       	call   f010384a <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102b03:	a1 dc 6e 2a f0       	mov    0xf02a6edc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b08:	83 c4 10             	add    $0x10,%esp
f0102b0b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b10:	77 15                	ja     f0102b27 <mem_init+0x1725>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b12:	50                   	push   %eax
f0102b13:	68 08 69 10 f0       	push   $0xf0106908
f0102b18:	68 f2 00 00 00       	push   $0xf2
f0102b1d:	68 75 78 10 f0       	push   $0xf0107875
f0102b22:	e8 19 d5 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102b27:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102b2c:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102b2f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b34:	e8 0a e0 ff ff       	call   f0100b43 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102b39:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102b3c:	83 e0 f3             	and    $0xfffffff3,%eax
f0102b3f:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102b44:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102b47:	83 ec 0c             	sub    $0xc,%esp
f0102b4a:	6a 00                	push   $0x0
f0102b4c:	e8 93 e4 ff ff       	call   f0100fe4 <page_alloc>
f0102b51:	89 c3                	mov    %eax,%ebx
f0102b53:	83 c4 10             	add    $0x10,%esp
f0102b56:	85 c0                	test   %eax,%eax
f0102b58:	75 19                	jne    f0102b73 <mem_init+0x1771>
f0102b5a:	68 90 79 10 f0       	push   $0xf0107990
f0102b5f:	68 9b 78 10 f0       	push   $0xf010789b
f0102b64:	68 d7 04 00 00       	push   $0x4d7
f0102b69:	68 75 78 10 f0       	push   $0xf0107875
f0102b6e:	e8 cd d4 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102b73:	83 ec 0c             	sub    $0xc,%esp
f0102b76:	6a 00                	push   $0x0
f0102b78:	e8 67 e4 ff ff       	call   f0100fe4 <page_alloc>
f0102b7d:	89 c7                	mov    %eax,%edi
f0102b7f:	83 c4 10             	add    $0x10,%esp
f0102b82:	85 c0                	test   %eax,%eax
f0102b84:	75 19                	jne    f0102b9f <mem_init+0x179d>
f0102b86:	68 a6 79 10 f0       	push   $0xf01079a6
f0102b8b:	68 9b 78 10 f0       	push   $0xf010789b
f0102b90:	68 d8 04 00 00       	push   $0x4d8
f0102b95:	68 75 78 10 f0       	push   $0xf0107875
f0102b9a:	e8 a1 d4 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102b9f:	83 ec 0c             	sub    $0xc,%esp
f0102ba2:	6a 00                	push   $0x0
f0102ba4:	e8 3b e4 ff ff       	call   f0100fe4 <page_alloc>
f0102ba9:	89 c6                	mov    %eax,%esi
f0102bab:	83 c4 10             	add    $0x10,%esp
f0102bae:	85 c0                	test   %eax,%eax
f0102bb0:	75 19                	jne    f0102bcb <mem_init+0x17c9>
f0102bb2:	68 bc 79 10 f0       	push   $0xf01079bc
f0102bb7:	68 9b 78 10 f0       	push   $0xf010789b
f0102bbc:	68 d9 04 00 00       	push   $0x4d9
f0102bc1:	68 75 78 10 f0       	push   $0xf0107875
f0102bc6:	e8 75 d4 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f0102bcb:	83 ec 0c             	sub    $0xc,%esp
f0102bce:	53                   	push   %ebx
f0102bcf:	e8 86 e4 ff ff       	call   f010105a <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102bd4:	89 f8                	mov    %edi,%eax
f0102bd6:	2b 05 e0 6e 2a f0    	sub    0xf02a6ee0,%eax
f0102bdc:	c1 f8 03             	sar    $0x3,%eax
f0102bdf:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102be2:	89 c2                	mov    %eax,%edx
f0102be4:	c1 ea 0c             	shr    $0xc,%edx
f0102be7:	83 c4 10             	add    $0x10,%esp
f0102bea:	3b 15 d8 6e 2a f0    	cmp    0xf02a6ed8,%edx
f0102bf0:	72 12                	jb     f0102c04 <mem_init+0x1802>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bf2:	50                   	push   %eax
f0102bf3:	68 e4 68 10 f0       	push   $0xf01068e4
f0102bf8:	6a 58                	push   $0x58
f0102bfa:	68 81 78 10 f0       	push   $0xf0107881
f0102bff:	e8 3c d4 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102c04:	83 ec 04             	sub    $0x4,%esp
f0102c07:	68 00 10 00 00       	push   $0x1000
f0102c0c:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102c0e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102c13:	50                   	push   %eax
f0102c14:	e8 09 28 00 00       	call   f0105422 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c19:	89 f0                	mov    %esi,%eax
f0102c1b:	2b 05 e0 6e 2a f0    	sub    0xf02a6ee0,%eax
f0102c21:	c1 f8 03             	sar    $0x3,%eax
f0102c24:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c27:	89 c2                	mov    %eax,%edx
f0102c29:	c1 ea 0c             	shr    $0xc,%edx
f0102c2c:	83 c4 10             	add    $0x10,%esp
f0102c2f:	3b 15 d8 6e 2a f0    	cmp    0xf02a6ed8,%edx
f0102c35:	72 12                	jb     f0102c49 <mem_init+0x1847>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c37:	50                   	push   %eax
f0102c38:	68 e4 68 10 f0       	push   $0xf01068e4
f0102c3d:	6a 58                	push   $0x58
f0102c3f:	68 81 78 10 f0       	push   $0xf0107881
f0102c44:	e8 f7 d3 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102c49:	83 ec 04             	sub    $0x4,%esp
f0102c4c:	68 00 10 00 00       	push   $0x1000
f0102c51:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102c53:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102c58:	50                   	push   %eax
f0102c59:	e8 c4 27 00 00       	call   f0105422 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102c5e:	6a 02                	push   $0x2
f0102c60:	68 00 10 00 00       	push   $0x1000
f0102c65:	57                   	push   %edi
f0102c66:	ff 35 dc 6e 2a f0    	pushl  0xf02a6edc
f0102c6c:	e8 99 e6 ff ff       	call   f010130a <page_insert>
	assert(pp1->pp_ref == 1);
f0102c71:	83 c4 20             	add    $0x20,%esp
f0102c74:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102c79:	74 19                	je     f0102c94 <mem_init+0x1892>
f0102c7b:	68 8d 7a 10 f0       	push   $0xf0107a8d
f0102c80:	68 9b 78 10 f0       	push   $0xf010789b
f0102c85:	68 de 04 00 00       	push   $0x4de
f0102c8a:	68 75 78 10 f0       	push   $0xf0107875
f0102c8f:	e8 ac d3 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102c94:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102c9b:	01 01 01 
f0102c9e:	74 19                	je     f0102cb9 <mem_init+0x18b7>
f0102ca0:	68 a0 77 10 f0       	push   $0xf01077a0
f0102ca5:	68 9b 78 10 f0       	push   $0xf010789b
f0102caa:	68 df 04 00 00       	push   $0x4df
f0102caf:	68 75 78 10 f0       	push   $0xf0107875
f0102cb4:	e8 87 d3 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102cb9:	6a 02                	push   $0x2
f0102cbb:	68 00 10 00 00       	push   $0x1000
f0102cc0:	56                   	push   %esi
f0102cc1:	ff 35 dc 6e 2a f0    	pushl  0xf02a6edc
f0102cc7:	e8 3e e6 ff ff       	call   f010130a <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102ccc:	83 c4 10             	add    $0x10,%esp
f0102ccf:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102cd6:	02 02 02 
f0102cd9:	74 19                	je     f0102cf4 <mem_init+0x18f2>
f0102cdb:	68 c4 77 10 f0       	push   $0xf01077c4
f0102ce0:	68 9b 78 10 f0       	push   $0xf010789b
f0102ce5:	68 e1 04 00 00       	push   $0x4e1
f0102cea:	68 75 78 10 f0       	push   $0xf0107875
f0102cef:	e8 4c d3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102cf4:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102cf9:	74 19                	je     f0102d14 <mem_init+0x1912>
f0102cfb:	68 af 7a 10 f0       	push   $0xf0107aaf
f0102d00:	68 9b 78 10 f0       	push   $0xf010789b
f0102d05:	68 e2 04 00 00       	push   $0x4e2
f0102d0a:	68 75 78 10 f0       	push   $0xf0107875
f0102d0f:	e8 2c d3 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102d14:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102d19:	74 19                	je     f0102d34 <mem_init+0x1932>
f0102d1b:	68 19 7b 10 f0       	push   $0xf0107b19
f0102d20:	68 9b 78 10 f0       	push   $0xf010789b
f0102d25:	68 e3 04 00 00       	push   $0x4e3
f0102d2a:	68 75 78 10 f0       	push   $0xf0107875
f0102d2f:	e8 0c d3 ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102d34:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102d3b:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102d3e:	89 f0                	mov    %esi,%eax
f0102d40:	2b 05 e0 6e 2a f0    	sub    0xf02a6ee0,%eax
f0102d46:	c1 f8 03             	sar    $0x3,%eax
f0102d49:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d4c:	89 c2                	mov    %eax,%edx
f0102d4e:	c1 ea 0c             	shr    $0xc,%edx
f0102d51:	3b 15 d8 6e 2a f0    	cmp    0xf02a6ed8,%edx
f0102d57:	72 12                	jb     f0102d6b <mem_init+0x1969>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102d59:	50                   	push   %eax
f0102d5a:	68 e4 68 10 f0       	push   $0xf01068e4
f0102d5f:	6a 58                	push   $0x58
f0102d61:	68 81 78 10 f0       	push   $0xf0107881
f0102d66:	e8 d5 d2 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102d6b:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102d72:	03 03 03 
f0102d75:	74 19                	je     f0102d90 <mem_init+0x198e>
f0102d77:	68 e8 77 10 f0       	push   $0xf01077e8
f0102d7c:	68 9b 78 10 f0       	push   $0xf010789b
f0102d81:	68 e5 04 00 00       	push   $0x4e5
f0102d86:	68 75 78 10 f0       	push   $0xf0107875
f0102d8b:	e8 b0 d2 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102d90:	83 ec 08             	sub    $0x8,%esp
f0102d93:	68 00 10 00 00       	push   $0x1000
f0102d98:	ff 35 dc 6e 2a f0    	pushl  0xf02a6edc
f0102d9e:	e8 21 e5 ff ff       	call   f01012c4 <page_remove>
	assert(pp2->pp_ref == 0);
f0102da3:	83 c4 10             	add    $0x10,%esp
f0102da6:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102dab:	74 19                	je     f0102dc6 <mem_init+0x19c4>
f0102dad:	68 e7 7a 10 f0       	push   $0xf0107ae7
f0102db2:	68 9b 78 10 f0       	push   $0xf010789b
f0102db7:	68 e7 04 00 00       	push   $0x4e7
f0102dbc:	68 75 78 10 f0       	push   $0xf0107875
f0102dc1:	e8 7a d2 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102dc6:	8b 0d dc 6e 2a f0    	mov    0xf02a6edc,%ecx
f0102dcc:	8b 11                	mov    (%ecx),%edx
f0102dce:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102dd4:	89 d8                	mov    %ebx,%eax
f0102dd6:	2b 05 e0 6e 2a f0    	sub    0xf02a6ee0,%eax
f0102ddc:	c1 f8 03             	sar    $0x3,%eax
f0102ddf:	c1 e0 0c             	shl    $0xc,%eax
f0102de2:	39 c2                	cmp    %eax,%edx
f0102de4:	74 19                	je     f0102dff <mem_init+0x19fd>
f0102de6:	68 70 71 10 f0       	push   $0xf0107170
f0102deb:	68 9b 78 10 f0       	push   $0xf010789b
f0102df0:	68 ea 04 00 00       	push   $0x4ea
f0102df5:	68 75 78 10 f0       	push   $0xf0107875
f0102dfa:	e8 41 d2 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102dff:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102e05:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102e0a:	74 19                	je     f0102e25 <mem_init+0x1a23>
f0102e0c:	68 9e 7a 10 f0       	push   $0xf0107a9e
f0102e11:	68 9b 78 10 f0       	push   $0xf010789b
f0102e16:	68 ec 04 00 00       	push   $0x4ec
f0102e1b:	68 75 78 10 f0       	push   $0xf0107875
f0102e20:	e8 1b d2 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102e25:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102e2b:	83 ec 0c             	sub    $0xc,%esp
f0102e2e:	53                   	push   %ebx
f0102e2f:	e8 26 e2 ff ff       	call   f010105a <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102e34:	c7 04 24 14 78 10 f0 	movl   $0xf0107814,(%esp)
f0102e3b:	e8 0a 0a 00 00       	call   f010384a <cprintf>
f0102e40:	83 c4 10             	add    $0x10,%esp
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102e43:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e46:	5b                   	pop    %ebx
f0102e47:	5e                   	pop    %esi
f0102e48:	5f                   	pop    %edi
f0102e49:	5d                   	pop    %ebp
f0102e4a:	c3                   	ret    

f0102e4b <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102e4b:	55                   	push   %ebp
f0102e4c:	89 e5                	mov    %esp,%ebp
f0102e4e:	57                   	push   %edi
f0102e4f:	56                   	push   %esi
f0102e50:	53                   	push   %ebx
f0102e51:	83 ec 1c             	sub    $0x1c,%esp
f0102e54:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102e57:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// LAB 3: Your code here.

	// step 1 : check below ULIM
  uintptr_t va_beg = (uintptr_t)va;
  uintptr_t va_end = va_beg + len;
f0102e5a:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102e5d:	03 75 10             	add    0x10(%ebp),%esi
  if (va_beg >= ULIM || va_end >= ULIM) {
f0102e60:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102e66:	77 09                	ja     f0102e71 <user_mem_check+0x26>
f0102e68:	81 7d 0c ff ff 7f ef 	cmpl   $0xef7fffff,0xc(%ebp)
f0102e6f:	76 1f                	jbe    f0102e90 <user_mem_check+0x45>
    user_mem_check_addr = (va_beg >= ULIM) ? va_beg : ULIM;
f0102e71:	81 7d 0c 00 00 80 ef 	cmpl   $0xef800000,0xc(%ebp)
f0102e78:	b8 00 00 80 ef       	mov    $0xef800000,%eax
f0102e7d:	0f 43 45 0c          	cmovae 0xc(%ebp),%eax
f0102e81:	a3 60 62 2a f0       	mov    %eax,0xf02a6260
    return -E_FAULT;
f0102e86:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102e8b:	e9 a7 00 00 00       	jmp    f0102f37 <user_mem_check+0xec>
  }

  // step 2 : check present & permission
  uintptr_t va_beg2 = ROUNDDOWN(va_beg, PGSIZE);
f0102e90:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102e93:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  uintptr_t va_end2 = ROUNDUP(va_end, PGSIZE);
f0102e99:	81 c6 ff 0f 00 00    	add    $0xfff,%esi
f0102e9f:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ea5:	a1 d8 6e 2a f0       	mov    0xf02a6ed8,%eax
f0102eaa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102ead:	89 7d 08             	mov    %edi,0x8(%ebp)
  while (va_beg2 < va_end2) {
f0102eb0:	eb 7c                	jmp    f0102f2e <user_mem_check+0xe3>

    // check page table is present ?
    if (!(env->env_pgdir[PDX(va_beg2)] & PTE_P)) {
f0102eb2:	89 d1                	mov    %edx,%ecx
f0102eb4:	c1 e9 16             	shr    $0x16,%ecx
f0102eb7:	8b 45 08             	mov    0x8(%ebp),%eax
f0102eba:	8b 40 60             	mov    0x60(%eax),%eax
f0102ebd:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0102ec0:	a8 01                	test   $0x1,%al
f0102ec2:	75 14                	jne    f0102ed8 <user_mem_check+0x8d>
      user_mem_check_addr = (va_beg2 > va_beg) ? va_beg2 : va_beg;
f0102ec4:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102ec7:	0f 42 55 0c          	cmovb  0xc(%ebp),%edx
f0102ecb:	89 15 60 62 2a f0    	mov    %edx,0xf02a6260
      return -E_FAULT;
f0102ed1:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102ed6:	eb 5f                	jmp    f0102f37 <user_mem_check+0xec>
    }

    // get current page table kernel va
    uint32_t* pt_kva = KADDR(PTE_ADDR(env->env_pgdir[PDX(va_beg2)]));
f0102ed8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102edd:	89 c1                	mov    %eax,%ecx
f0102edf:	c1 e9 0c             	shr    $0xc,%ecx
f0102ee2:	3b 4d e4             	cmp    -0x1c(%ebp),%ecx
f0102ee5:	72 15                	jb     f0102efc <user_mem_check+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ee7:	50                   	push   %eax
f0102ee8:	68 e4 68 10 f0       	push   $0xf01068e4
f0102eed:	68 14 03 00 00       	push   $0x314
f0102ef2:	68 75 78 10 f0       	push   $0xf0107875
f0102ef7:	e8 44 d1 ff ff       	call   f0100040 <_panic>

    // check page is present & permissions
    if (!((pt_kva[PTX(va_beg2)] & perm) == perm)) {
f0102efc:	89 d1                	mov    %edx,%ecx
f0102efe:	c1 e9 0c             	shr    $0xc,%ecx
f0102f01:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
f0102f07:	89 df                	mov    %ebx,%edi
f0102f09:	23 bc 88 00 00 00 f0 	and    -0x10000000(%eax,%ecx,4),%edi
f0102f10:	39 fb                	cmp    %edi,%ebx
f0102f12:	74 14                	je     f0102f28 <user_mem_check+0xdd>
      user_mem_check_addr = (va_beg2 > va_beg) ? va_beg2 : va_beg;
f0102f14:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102f17:	0f 42 55 0c          	cmovb  0xc(%ebp),%edx
f0102f1b:	89 15 60 62 2a f0    	mov    %edx,0xf02a6260
      return -E_FAULT;
f0102f21:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102f26:	eb 0f                	jmp    f0102f37 <user_mem_check+0xec>
    }

    va_beg2 += PGSIZE;
f0102f28:	81 c2 00 10 00 00    	add    $0x1000,%edx
  }

  // step 2 : check present & permission
  uintptr_t va_beg2 = ROUNDDOWN(va_beg, PGSIZE);
  uintptr_t va_end2 = ROUNDUP(va_end, PGSIZE);
  while (va_beg2 < va_end2) {
f0102f2e:	39 f2                	cmp    %esi,%edx
f0102f30:	72 80                	jb     f0102eb2 <user_mem_check+0x67>
      return -E_FAULT;
    }

    va_beg2 += PGSIZE;
  }
  return 0;
f0102f32:	b8 00 00 00 00       	mov    $0x0,%eax

}
f0102f37:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f3a:	5b                   	pop    %ebx
f0102f3b:	5e                   	pop    %esi
f0102f3c:	5f                   	pop    %edi
f0102f3d:	5d                   	pop    %ebp
f0102f3e:	c3                   	ret    

f0102f3f <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102f3f:	55                   	push   %ebp
f0102f40:	89 e5                	mov    %esp,%ebp
f0102f42:	53                   	push   %ebx
f0102f43:	83 ec 04             	sub    $0x4,%esp
f0102f46:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102f49:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f4c:	83 c8 04             	or     $0x4,%eax
f0102f4f:	50                   	push   %eax
f0102f50:	ff 75 10             	pushl  0x10(%ebp)
f0102f53:	ff 75 0c             	pushl  0xc(%ebp)
f0102f56:	53                   	push   %ebx
f0102f57:	e8 ef fe ff ff       	call   f0102e4b <user_mem_check>
f0102f5c:	83 c4 10             	add    $0x10,%esp
f0102f5f:	85 c0                	test   %eax,%eax
f0102f61:	79 21                	jns    f0102f84 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102f63:	83 ec 04             	sub    $0x4,%esp
f0102f66:	ff 35 60 62 2a f0    	pushl  0xf02a6260
f0102f6c:	ff 73 48             	pushl  0x48(%ebx)
f0102f6f:	68 40 78 10 f0       	push   $0xf0107840
f0102f74:	e8 d1 08 00 00       	call   f010384a <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102f79:	89 1c 24             	mov    %ebx,(%esp)
f0102f7c:	e8 ef 05 00 00       	call   f0103570 <env_destroy>
f0102f81:	83 c4 10             	add    $0x10,%esp
	}
}
f0102f84:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102f87:	c9                   	leave  
f0102f88:	c3                   	ret    

f0102f89 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102f89:	55                   	push   %ebp
f0102f8a:	89 e5                	mov    %esp,%ebp
f0102f8c:	57                   	push   %edi
f0102f8d:	56                   	push   %esi
f0102f8e:	53                   	push   %ebx
f0102f8f:	83 ec 0c             	sub    $0xc,%esp
f0102f92:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
f0102f94:	89 d3                	mov    %edx,%ebx
f0102f96:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
f0102f9c:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102fa3:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	
	while (vaBegin<vaEnd){
f0102fa9:	eb 58                	jmp    f0103003 <region_alloc+0x7a>
		struct PageInfo *p = page_alloc(0);
f0102fab:	83 ec 0c             	sub    $0xc,%esp
f0102fae:	6a 00                	push   $0x0
f0102fb0:	e8 2f e0 ff ff       	call   f0100fe4 <page_alloc>
		if (p == NULL)
f0102fb5:	83 c4 10             	add    $0x10,%esp
f0102fb8:	85 c0                	test   %eax,%eax
f0102fba:	75 17                	jne    f0102fd3 <region_alloc+0x4a>
			panic("Page alloc failed!");
f0102fbc:	83 ec 04             	sub    $0x4,%esp
f0102fbf:	68 b4 7b 10 f0       	push   $0xf0107bb4
f0102fc4:	68 35 01 00 00       	push   $0x135
f0102fc9:	68 c7 7b 10 f0       	push   $0xf0107bc7
f0102fce:	e8 6d d0 ff ff       	call   f0100040 <_panic>
		else if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
f0102fd3:	6a 06                	push   $0x6
f0102fd5:	53                   	push   %ebx
f0102fd6:	50                   	push   %eax
f0102fd7:	ff 77 60             	pushl  0x60(%edi)
f0102fda:	e8 2b e3 ff ff       	call   f010130a <page_insert>
f0102fdf:	83 c4 10             	add    $0x10,%esp
f0102fe2:	85 c0                	test   %eax,%eax
f0102fe4:	74 17                	je     f0102ffd <region_alloc+0x74>
			panic("Page table couldn't be allocated!!");
f0102fe6:	83 ec 04             	sub    $0x4,%esp
f0102fe9:	68 0c 7c 10 f0       	push   $0xf0107c0c
f0102fee:	68 37 01 00 00       	push   $0x137
f0102ff3:	68 c7 7b 10 f0       	push   $0xf0107bc7
f0102ff8:	e8 43 d0 ff ff       	call   f0100040 <_panic>
		}
		vaBegin += PGSIZE;
f0102ffd:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
	
	while (vaBegin<vaEnd){
f0103003:	39 f3                	cmp    %esi,%ebx
f0103005:	72 a4                	jb     f0102fab <region_alloc+0x22>
		else if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
			panic("Page table couldn't be allocated!!");
		}
		vaBegin += PGSIZE;
	}
}
f0103007:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010300a:	5b                   	pop    %ebx
f010300b:	5e                   	pop    %esi
f010300c:	5f                   	pop    %edi
f010300d:	5d                   	pop    %ebp
f010300e:	c3                   	ret    

f010300f <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f010300f:	55                   	push   %ebp
f0103010:	89 e5                	mov    %esp,%ebp
f0103012:	56                   	push   %esi
f0103013:	53                   	push   %ebx
f0103014:	8b 45 08             	mov    0x8(%ebp),%eax
f0103017:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f010301a:	85 c0                	test   %eax,%eax
f010301c:	75 1a                	jne    f0103038 <envid2env+0x29>
		*env_store = curenv;
f010301e:	e8 24 2a 00 00       	call   f0105a47 <cpunum>
f0103023:	6b c0 74             	imul   $0x74,%eax,%eax
f0103026:	8b 80 48 70 2a f0    	mov    -0xfd58fb8(%eax),%eax
f010302c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010302f:	89 01                	mov    %eax,(%ecx)
		return 0;
f0103031:	b8 00 00 00 00       	mov    $0x0,%eax
f0103036:	eb 70                	jmp    f01030a8 <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0103038:	89 c3                	mov    %eax,%ebx
f010303a:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0103040:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0103043:	03 1d 6c 62 2a f0    	add    0xf02a626c,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103049:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f010304d:	74 05                	je     f0103054 <envid2env+0x45>
f010304f:	39 43 48             	cmp    %eax,0x48(%ebx)
f0103052:	74 10                	je     f0103064 <envid2env+0x55>
		*env_store = 0;
f0103054:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103057:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010305d:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103062:	eb 44                	jmp    f01030a8 <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103064:	84 d2                	test   %dl,%dl
f0103066:	74 36                	je     f010309e <envid2env+0x8f>
f0103068:	e8 da 29 00 00       	call   f0105a47 <cpunum>
f010306d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103070:	39 98 48 70 2a f0    	cmp    %ebx,-0xfd58fb8(%eax)
f0103076:	74 26                	je     f010309e <envid2env+0x8f>
f0103078:	8b 73 4c             	mov    0x4c(%ebx),%esi
f010307b:	e8 c7 29 00 00       	call   f0105a47 <cpunum>
f0103080:	6b c0 74             	imul   $0x74,%eax,%eax
f0103083:	8b 80 48 70 2a f0    	mov    -0xfd58fb8(%eax),%eax
f0103089:	3b 70 48             	cmp    0x48(%eax),%esi
f010308c:	74 10                	je     f010309e <envid2env+0x8f>
		*env_store = 0;
f010308e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103091:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103097:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010309c:	eb 0a                	jmp    f01030a8 <envid2env+0x99>
	}

	*env_store = e;
f010309e:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030a1:	89 18                	mov    %ebx,(%eax)
	return 0;
f01030a3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01030a8:	5b                   	pop    %ebx
f01030a9:	5e                   	pop    %esi
f01030aa:	5d                   	pop    %ebp
f01030ab:	c3                   	ret    

f01030ac <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01030ac:	55                   	push   %ebp
f01030ad:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f01030af:	b8 40 33 12 f0       	mov    $0xf0123340,%eax
f01030b4:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f01030b7:	b8 23 00 00 00       	mov    $0x23,%eax
f01030bc:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f01030be:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f01030c0:	b0 10                	mov    $0x10,%al
f01030c2:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f01030c4:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01030c6:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f01030c8:	ea cf 30 10 f0 08 00 	ljmp   $0x8,$0xf01030cf
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f01030cf:	b0 00                	mov    $0x0,%al
f01030d1:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01030d4:	5d                   	pop    %ebp
f01030d5:	c3                   	ret    

f01030d6 <env_init>:
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
f01030d6:	8b 0d 6c 62 2a f0    	mov    0xf02a626c,%ecx
f01030dc:	8b 15 70 62 2a f0    	mov    0xf02a6270,%edx
f01030e2:	89 c8                	mov    %ecx,%eax
f01030e4:	81 c1 00 f0 01 00    	add    $0x1f000,%ecx
f01030ea:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = NULL;
f01030f1:	c7 40 44 00 00 00 00 	movl   $0x0,0x44(%eax)

		if (!env_free_list){		
f01030f8:	85 d2                	test   %edx,%edx
f01030fa:	74 05                	je     f0103101 <env_init+0x2b>
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
		}
		else{
		envs[i-1].env_link = &envs[i];
f01030fc:	89 40 c8             	mov    %eax,-0x38(%eax)
f01030ff:	eb 02                	jmp    f0103103 <env_init+0x2d>
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
		envs[i].env_link = NULL;

		if (!env_free_list){		
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
f0103101:	89 c2                	mov    %eax,%edx
f0103103:	83 c0 7c             	add    $0x7c,%eax
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
f0103106:	39 c8                	cmp    %ecx,%eax
f0103108:	75 e0                	jne    f01030ea <env_init+0x14>
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f010310a:	55                   	push   %ebp
f010310b:	89 e5                	mov    %esp,%ebp
f010310d:	89 15 70 62 2a f0    	mov    %edx,0xf02a6270
		}	//Previous env is linked to this current env
	}
	

	// Per-CPU part of the initialization
	env_init_percpu();
f0103113:	e8 94 ff ff ff       	call   f01030ac <env_init_percpu>
}
f0103118:	5d                   	pop    %ebp
f0103119:	c3                   	ret    

f010311a <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f010311a:	55                   	push   %ebp
f010311b:	89 e5                	mov    %esp,%ebp
f010311d:	53                   	push   %ebx
f010311e:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0103121:	8b 1d 70 62 2a f0    	mov    0xf02a6270,%ebx
f0103127:	85 db                	test   %ebx,%ebx
f0103129:	0f 84 34 01 00 00    	je     f0103263 <env_alloc+0x149>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f010312f:	83 ec 0c             	sub    $0xc,%esp
f0103132:	6a 01                	push   $0x1
f0103134:	e8 ab de ff ff       	call   f0100fe4 <page_alloc>
f0103139:	83 c4 10             	add    $0x10,%esp
f010313c:	85 c0                	test   %eax,%eax
f010313e:	0f 84 26 01 00 00    	je     f010326a <env_alloc+0x150>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f0103144:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0103149:	2b 05 e0 6e 2a f0    	sub    0xf02a6ee0,%eax
f010314f:	c1 f8 03             	sar    $0x3,%eax
f0103152:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103155:	89 c2                	mov    %eax,%edx
f0103157:	c1 ea 0c             	shr    $0xc,%edx
f010315a:	3b 15 d8 6e 2a f0    	cmp    0xf02a6ed8,%edx
f0103160:	72 12                	jb     f0103174 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103162:	50                   	push   %eax
f0103163:	68 e4 68 10 f0       	push   $0xf01068e4
f0103168:	6a 58                	push   $0x58
f010316a:	68 81 78 10 f0       	push   $0xf0107881
f010316f:	e8 cc ce ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0103174:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103179:	89 43 60             	mov    %eax,0x60(%ebx)
	e->env_pgdir = (pde_t*)page2kva(p);
f010317c:	b8 00 00 00 00       	mov    $0x0,%eax

	for (i = 0; i < NPDENTRIES; ++i) {
		e->env_pgdir[i] = kern_pgdir[i];  //Mapping all 1024 entries of the kernel
f0103181:	8b 15 dc 6e 2a f0    	mov    0xf02a6edc,%edx
f0103187:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f010318a:	8b 53 60             	mov    0x60(%ebx),%edx
f010318d:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f0103190:	83 c0 04             	add    $0x4,%eax

	// LAB 3: Your code here.
	p->pp_ref++;
	e->env_pgdir = (pde_t*)page2kva(p);

	for (i = 0; i < NPDENTRIES; ++i) {
f0103193:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0103198:	75 e7                	jne    f0103181 <env_alloc+0x67>
						 //pgdir to the environment pgdir
	}
	
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f010319a:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010319d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031a2:	77 15                	ja     f01031b9 <env_alloc+0x9f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031a4:	50                   	push   %eax
f01031a5:	68 08 69 10 f0       	push   $0xf0106908
f01031aa:	68 d0 00 00 00       	push   $0xd0
f01031af:	68 c7 7b 10 f0       	push   $0xf0107bc7
f01031b4:	e8 87 ce ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01031b9:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01031bf:	83 ca 05             	or     $0x5,%edx
f01031c2:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01031c8:	8b 43 48             	mov    0x48(%ebx),%eax
f01031cb:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01031d0:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01031d5:	ba 00 10 00 00       	mov    $0x1000,%edx
f01031da:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01031dd:	89 da                	mov    %ebx,%edx
f01031df:	2b 15 6c 62 2a f0    	sub    0xf02a626c,%edx
f01031e5:	c1 fa 02             	sar    $0x2,%edx
f01031e8:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f01031ee:	09 d0                	or     %edx,%eax
f01031f0:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f01031f3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031f6:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f01031f9:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0103200:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0103207:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f010320e:	83 ec 04             	sub    $0x4,%esp
f0103211:	6a 44                	push   $0x44
f0103213:	6a 00                	push   $0x0
f0103215:	53                   	push   %ebx
f0103216:	e8 07 22 00 00       	call   f0105422 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f010321b:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103221:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103227:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f010322d:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0103234:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.
	e->env_tf.tf_eflags |= FL_IF;  //Modification for exercise 13
f010323a:	81 4b 38 00 02 00 00 	orl    $0x200,0x38(%ebx)

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f0103241:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f0103248:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f010324c:	8b 43 44             	mov    0x44(%ebx),%eax
f010324f:	a3 70 62 2a f0       	mov    %eax,0xf02a6270
	*newenv_store = e;
f0103254:	8b 45 08             	mov    0x8(%ebp),%eax
f0103257:	89 18                	mov    %ebx,(%eax)

	// cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
f0103259:	83 c4 10             	add    $0x10,%esp
f010325c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103261:	eb 0c                	jmp    f010326f <env_alloc+0x155>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103263:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103268:	eb 05                	jmp    f010326f <env_alloc+0x155>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f010326a:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	// cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f010326f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103272:	c9                   	leave  
f0103273:	c3                   	ret    

f0103274 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103274:	55                   	push   %ebp
f0103275:	89 e5                	mov    %esp,%ebp
f0103277:	57                   	push   %edi
f0103278:	56                   	push   %esi
f0103279:	53                   	push   %ebx
f010327a:	83 ec 34             	sub    $0x34,%esp
f010327d:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	int r;
	struct Env *env;
	r = env_alloc( &env, 0);
f0103280:	6a 00                	push   $0x0
f0103282:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103285:	50                   	push   %eax
f0103286:	e8 8f fe ff ff       	call   f010311a <env_alloc>
	if (r){
f010328b:	83 c4 10             	add    $0x10,%esp
f010328e:	85 c0                	test   %eax,%eax
f0103290:	74 15                	je     f01032a7 <env_create+0x33>
	panic("env_alloc: %e", r);
f0103292:	50                   	push   %eax
f0103293:	68 d2 7b 10 f0       	push   $0xf0107bd2
f0103298:	68 b2 01 00 00       	push   $0x1b2
f010329d:	68 c7 7b 10 f0       	push   $0xf0107bc7
f01032a2:	e8 99 cd ff ff       	call   f0100040 <_panic>
	}
	
	load_icode(env,binary);
f01032a7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01032aa:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Get the beginning and end of program header table
	//Details of struct proghdr are in /lab/inc/elf.h

	// is this a valid ELF?
	
	if (((struct Elf*)binary)->e_magic != ELF_MAGIC)
f01032ad:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f01032b3:	74 17                	je     f01032cc <env_create+0x58>
	{
		panic ("Not a valid ELF binary image");
f01032b5:	83 ec 04             	sub    $0x4,%esp
f01032b8:	68 e0 7b 10 f0       	push   $0xf0107be0
f01032bd:	68 81 01 00 00       	push   $0x181
f01032c2:	68 c7 7b 10 f0       	push   $0xf0107bc7
f01032c7:	e8 74 cd ff ff       	call   f0100040 <_panic>
	}

	struct Proghdr *ph =(struct Proghdr *)(binary + ((struct Elf*)binary)->e_phoff); //phoff is the offset
f01032cc:	89 fb                	mov    %edi,%ebx
f01032ce:	03 5f 1c             	add    0x1c(%edi),%ebx
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
f01032d1:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f01032d5:	c1 e6 05             	shl    $0x5,%esi
f01032d8:	01 de                	add    %ebx,%esi
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));
f01032da:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01032dd:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01032e0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01032e5:	77 15                	ja     f01032fc <env_create+0x88>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01032e7:	50                   	push   %eax
f01032e8:	68 08 69 10 f0       	push   $0xf0106908
f01032ed:	68 88 01 00 00       	push   $0x188
f01032f2:	68 c7 7b 10 f0       	push   $0xf0107bc7
f01032f7:	e8 44 cd ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01032fc:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0103301:	0f 22 d8             	mov    %eax,%cr3
f0103304:	eb 60                	jmp    f0103366 <env_create+0xf2>

	for (;ph<phEnd;++ph){
		if (ph->p_type == ELF_PROG_LOAD){	//Check whether the type is ELF_PROG_LOAD
f0103306:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103309:	75 58                	jne    f0103363 <env_create+0xef>
		
		if(ph->p_memsz < ph->p_filesz){
f010330b:	8b 4b 14             	mov    0x14(%ebx),%ecx
f010330e:	3b 4b 10             	cmp    0x10(%ebx),%ecx
f0103311:	73 17                	jae    f010332a <env_create+0xb6>
		panic ("Memory size is smaller than file size!!");
f0103313:	83 ec 04             	sub    $0x4,%esp
f0103316:	68 30 7c 10 f0       	push   $0xf0107c30
f010331b:	68 8e 01 00 00       	push   $0x18e
f0103320:	68 c7 7b 10 f0       	push   $0xf0107bc7
f0103325:	e8 16 cd ff ff       	call   f0100040 <_panic>
		}
		region_alloc(e, (void *)ph->p_va, ph->p_memsz);  //Allocate region per segment
f010332a:	8b 53 08             	mov    0x8(%ebx),%edx
f010332d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103330:	e8 54 fc ff ff       	call   f0102f89 <region_alloc>
	

		memcpy((void*)ph->p_va, (void*)(binary + ph->p_offset), ph->p_filesz); //Load Binary into memory
f0103335:	83 ec 04             	sub    $0x4,%esp
f0103338:	ff 73 10             	pushl  0x10(%ebx)
f010333b:	89 f8                	mov    %edi,%eax
f010333d:	03 43 04             	add    0x4(%ebx),%eax
f0103340:	50                   	push   %eax
f0103341:	ff 73 08             	pushl  0x8(%ebx)
f0103344:	e8 8e 21 00 00       	call   f01054d7 <memcpy>

		memset((void*)(ph->p_va + ph->p_filesz),0,ph->p_memsz-ph->p_filesz);  //Clear the rest of the memory, i.e the bss segment
f0103349:	8b 43 10             	mov    0x10(%ebx),%eax
f010334c:	83 c4 0c             	add    $0xc,%esp
f010334f:	8b 53 14             	mov    0x14(%ebx),%edx
f0103352:	29 c2                	sub    %eax,%edx
f0103354:	52                   	push   %edx
f0103355:	6a 00                	push   $0x0
f0103357:	03 43 08             	add    0x8(%ebx),%eax
f010335a:	50                   	push   %eax
f010335b:	e8 c2 20 00 00       	call   f0105422 <memset>
f0103360:	83 c4 10             	add    $0x10,%esp
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));

	for (;ph<phEnd;++ph){
f0103363:	83 c3 20             	add    $0x20,%ebx
f0103366:	39 de                	cmp    %ebx,%esi
f0103368:	77 9c                	ja     f0103306 <env_create+0x92>
		}
		else{
			continue;
		}
	}
	lcr3(PADDR(kern_pgdir));   //Switch back to Kernel page directory
f010336a:	a1 dc 6e 2a f0       	mov    0xf02a6edc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010336f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103374:	77 15                	ja     f010338b <env_create+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103376:	50                   	push   %eax
f0103377:	68 08 69 10 f0       	push   $0xf0106908
f010337c:	68 9b 01 00 00       	push   $0x19b
f0103381:	68 c7 7b 10 f0       	push   $0xf0107bc7
f0103386:	e8 b5 cc ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010338b:	05 00 00 00 10       	add    $0x10000000,%eax
f0103390:	0f 22 d8             	mov    %eax,%cr3
	
	e->env_tf.tf_eip = ((struct Elf*)binary)->e_entry;   //Define the entry point of the env from the ELF binary entry point
f0103393:	8b 47 18             	mov    0x18(%edi),%eax
f0103396:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103399:	89 47 30             	mov    %eax,0x30(%edi)

	region_alloc(e,(void *)USTACKTOP - PGSIZE, PGSIZE);
f010339c:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01033a1:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01033a6:	89 f8                	mov    %edi,%eax
f01033a8:	e8 dc fb ff ff       	call   f0102f89 <region_alloc>
	if (r){
	panic("env_alloc: %e", r);
	}
	
	load_icode(env,binary);
	env->env_type = type;
f01033ad:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01033b0:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01033b3:	89 78 50             	mov    %edi,0x50(%eax)

	// If this is the file server (type == ENV_TYPE_FS) give it I/O privileges.
	// LAB 5: Your code here.
	//IOPL = IO privelege level, for this to be user accessible, the IOPL<=CPL, Since CPL =3 we set IOPL=3
	if (type == ENV_TYPE_FS) {
f01033b6:	83 ff 01             	cmp    $0x1,%edi
f01033b9:	75 07                	jne    f01033c2 <env_create+0x14e>
		env->env_tf.tf_eflags |= FL_IOPL_3; //FL_IOPL_3 in inc/mmu.h
f01033bb:	81 48 38 00 30 00 00 	orl    $0x3000,0x38(%eax)
	}

}
f01033c2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01033c5:	5b                   	pop    %ebx
f01033c6:	5e                   	pop    %esi
f01033c7:	5f                   	pop    %edi
f01033c8:	5d                   	pop    %ebp
f01033c9:	c3                   	ret    

f01033ca <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01033ca:	55                   	push   %ebp
f01033cb:	89 e5                	mov    %esp,%ebp
f01033cd:	57                   	push   %edi
f01033ce:	56                   	push   %esi
f01033cf:	53                   	push   %ebx
f01033d0:	83 ec 1c             	sub    $0x1c,%esp
f01033d3:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01033d6:	e8 6c 26 00 00       	call   f0105a47 <cpunum>
f01033db:	6b c0 74             	imul   $0x74,%eax,%eax
f01033de:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01033e5:	39 b8 48 70 2a f0    	cmp    %edi,-0xfd58fb8(%eax)
f01033eb:	75 30                	jne    f010341d <env_free+0x53>
		lcr3(PADDR(kern_pgdir));
f01033ed:	a1 dc 6e 2a f0       	mov    0xf02a6edc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01033f2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01033f7:	77 15                	ja     f010340e <env_free+0x44>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033f9:	50                   	push   %eax
f01033fa:	68 08 69 10 f0       	push   $0xf0106908
f01033ff:	68 d0 01 00 00       	push   $0x1d0
f0103404:	68 c7 7b 10 f0       	push   $0xf0107bc7
f0103409:	e8 32 cc ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010340e:	05 00 00 00 10       	add    $0x10000000,%eax
f0103413:	0f 22 d8             	mov    %eax,%cr3
f0103416:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f010341d:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103420:	89 d0                	mov    %edx,%eax
f0103422:	c1 e0 02             	shl    $0x2,%eax
f0103425:	89 45 d8             	mov    %eax,-0x28(%ebp)
	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103428:	8b 47 60             	mov    0x60(%edi),%eax
f010342b:	8b 34 90             	mov    (%eax,%edx,4),%esi
f010342e:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103434:	0f 84 a8 00 00 00    	je     f01034e2 <env_free+0x118>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f010343a:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103440:	89 f0                	mov    %esi,%eax
f0103442:	c1 e8 0c             	shr    $0xc,%eax
f0103445:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103448:	3b 05 d8 6e 2a f0    	cmp    0xf02a6ed8,%eax
f010344e:	72 15                	jb     f0103465 <env_free+0x9b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103450:	56                   	push   %esi
f0103451:	68 e4 68 10 f0       	push   $0xf01068e4
f0103456:	68 df 01 00 00       	push   $0x1df
f010345b:	68 c7 7b 10 f0       	push   $0xf0107bc7
f0103460:	e8 db cb ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103465:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103468:	c1 e0 16             	shl    $0x16,%eax
f010346b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010346e:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103473:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f010347a:	01 
f010347b:	74 17                	je     f0103494 <env_free+0xca>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010347d:	83 ec 08             	sub    $0x8,%esp
f0103480:	89 d8                	mov    %ebx,%eax
f0103482:	c1 e0 0c             	shl    $0xc,%eax
f0103485:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103488:	50                   	push   %eax
f0103489:	ff 77 60             	pushl  0x60(%edi)
f010348c:	e8 33 de ff ff       	call   f01012c4 <page_remove>
f0103491:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103494:	83 c3 01             	add    $0x1,%ebx
f0103497:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f010349d:	75 d4                	jne    f0103473 <env_free+0xa9>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f010349f:	8b 47 60             	mov    0x60(%edi),%eax
f01034a2:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01034a5:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01034ac:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01034af:	3b 05 d8 6e 2a f0    	cmp    0xf02a6ed8,%eax
f01034b5:	72 14                	jb     f01034cb <env_free+0x101>
		panic("pa2page called with invalid pa");
f01034b7:	83 ec 04             	sub    $0x4,%esp
f01034ba:	68 58 7c 10 f0       	push   $0xf0107c58
f01034bf:	6a 51                	push   $0x51
f01034c1:	68 81 78 10 f0       	push   $0xf0107881
f01034c6:	e8 75 cb ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f01034cb:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f01034ce:	a1 e0 6e 2a f0       	mov    0xf02a6ee0,%eax
f01034d3:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01034d6:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01034d9:	50                   	push   %eax
f01034da:	e8 cc db ff ff       	call   f01010ab <page_decref>
f01034df:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	// cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01034e2:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f01034e6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01034e9:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01034ee:	0f 85 29 ff ff ff    	jne    f010341d <env_free+0x53>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f01034f4:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01034f7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01034fc:	77 15                	ja     f0103513 <env_free+0x149>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034fe:	50                   	push   %eax
f01034ff:	68 08 69 10 f0       	push   $0xf0106908
f0103504:	68 ed 01 00 00       	push   $0x1ed
f0103509:	68 c7 7b 10 f0       	push   $0xf0107bc7
f010350e:	e8 2d cb ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f0103513:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
	return (physaddr_t)kva - KERNBASE;
f010351a:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010351f:	c1 e8 0c             	shr    $0xc,%eax
f0103522:	3b 05 d8 6e 2a f0    	cmp    0xf02a6ed8,%eax
f0103528:	72 14                	jb     f010353e <env_free+0x174>
		panic("pa2page called with invalid pa");
f010352a:	83 ec 04             	sub    $0x4,%esp
f010352d:	68 58 7c 10 f0       	push   $0xf0107c58
f0103532:	6a 51                	push   $0x51
f0103534:	68 81 78 10 f0       	push   $0xf0107881
f0103539:	e8 02 cb ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f010353e:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103541:	8b 15 e0 6e 2a f0    	mov    0xf02a6ee0,%edx
f0103547:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f010354a:	50                   	push   %eax
f010354b:	e8 5b db ff ff       	call   f01010ab <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103550:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103557:	a1 70 62 2a f0       	mov    0xf02a6270,%eax
f010355c:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f010355f:	89 3d 70 62 2a f0    	mov    %edi,0xf02a6270
f0103565:	83 c4 10             	add    $0x10,%esp
}
f0103568:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010356b:	5b                   	pop    %ebx
f010356c:	5e                   	pop    %esi
f010356d:	5f                   	pop    %edi
f010356e:	5d                   	pop    %ebp
f010356f:	c3                   	ret    

f0103570 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103570:	55                   	push   %ebp
f0103571:	89 e5                	mov    %esp,%ebp
f0103573:	53                   	push   %ebx
f0103574:	83 ec 04             	sub    $0x4,%esp
f0103577:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f010357a:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f010357e:	75 19                	jne    f0103599 <env_destroy+0x29>
f0103580:	e8 c2 24 00 00       	call   f0105a47 <cpunum>
f0103585:	6b c0 74             	imul   $0x74,%eax,%eax
f0103588:	39 98 48 70 2a f0    	cmp    %ebx,-0xfd58fb8(%eax)
f010358e:	74 09                	je     f0103599 <env_destroy+0x29>
		e->env_status = ENV_DYING;
f0103590:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f0103597:	eb 33                	jmp    f01035cc <env_destroy+0x5c>
	}

	env_free(e);
f0103599:	83 ec 0c             	sub    $0xc,%esp
f010359c:	53                   	push   %ebx
f010359d:	e8 28 fe ff ff       	call   f01033ca <env_free>

	if (curenv == e) {
f01035a2:	e8 a0 24 00 00       	call   f0105a47 <cpunum>
f01035a7:	6b c0 74             	imul   $0x74,%eax,%eax
f01035aa:	83 c4 10             	add    $0x10,%esp
f01035ad:	39 98 48 70 2a f0    	cmp    %ebx,-0xfd58fb8(%eax)
f01035b3:	75 17                	jne    f01035cc <env_destroy+0x5c>
		curenv = NULL;
f01035b5:	e8 8d 24 00 00       	call   f0105a47 <cpunum>
f01035ba:	6b c0 74             	imul   $0x74,%eax,%eax
f01035bd:	c7 80 48 70 2a f0 00 	movl   $0x0,-0xfd58fb8(%eax)
f01035c4:	00 00 00 
		sched_yield();
f01035c7:	e8 38 0c 00 00       	call   f0104204 <sched_yield>
	}
}
f01035cc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01035cf:	c9                   	leave  
f01035d0:	c3                   	ret    

f01035d1 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01035d1:	55                   	push   %ebp
f01035d2:	89 e5                	mov    %esp,%ebp
f01035d4:	53                   	push   %ebx
f01035d5:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f01035d8:	e8 6a 24 00 00       	call   f0105a47 <cpunum>
f01035dd:	6b c0 74             	imul   $0x74,%eax,%eax
f01035e0:	8b 98 48 70 2a f0    	mov    -0xfd58fb8(%eax),%ebx
f01035e6:	e8 5c 24 00 00       	call   f0105a47 <cpunum>
f01035eb:	89 43 5c             	mov    %eax,0x5c(%ebx)

	__asm __volatile("movl %0,%%esp\n"
f01035ee:	8b 65 08             	mov    0x8(%ebp),%esp
f01035f1:	61                   	popa   
f01035f2:	07                   	pop    %es
f01035f3:	1f                   	pop    %ds
f01035f4:	83 c4 08             	add    $0x8,%esp
f01035f7:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f01035f8:	83 ec 04             	sub    $0x4,%esp
f01035fb:	68 fd 7b 10 f0       	push   $0xf0107bfd
f0103600:	68 23 02 00 00       	push   $0x223
f0103605:	68 c7 7b 10 f0       	push   $0xf0107bc7
f010360a:	e8 31 ca ff ff       	call   f0100040 <_panic>

f010360f <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f010360f:	55                   	push   %ebp
f0103610:	89 e5                	mov    %esp,%ebp
f0103612:	53                   	push   %ebx
f0103613:	83 ec 04             	sub    $0x4,%esp
f0103616:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	//check if this is the first call to env_run
	if (curenv == NULL){
f0103619:	e8 29 24 00 00       	call   f0105a47 <cpunum>
f010361e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103621:	83 b8 48 70 2a f0 00 	cmpl   $0x0,-0xfd58fb8(%eax)
f0103628:	75 10                	jne    f010363a <env_run+0x2b>
	curenv = e;
f010362a:	e8 18 24 00 00       	call   f0105a47 <cpunum>
f010362f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103632:	89 98 48 70 2a f0    	mov    %ebx,-0xfd58fb8(%eax)
f0103638:	eb 29                	jmp    f0103663 <env_run+0x54>
	}
	
	//If curenv state is running mode , set it to runnable 
	else if (curenv->env_status == ENV_RUNNING){
f010363a:	e8 08 24 00 00       	call   f0105a47 <cpunum>
f010363f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103642:	8b 80 48 70 2a f0    	mov    -0xfd58fb8(%eax),%eax
f0103648:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010364c:	75 15                	jne    f0103663 <env_run+0x54>
	 curenv->env_status = ENV_RUNNABLE;
f010364e:	e8 f4 23 00 00       	call   f0105a47 <cpunum>
f0103653:	6b c0 74             	imul   $0x74,%eax,%eax
f0103656:	8b 80 48 70 2a f0    	mov    -0xfd58fb8(%eax),%eax
f010365c:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	curenv = e;	//Set the current environment to the new env
f0103663:	e8 df 23 00 00       	call   f0105a47 <cpunum>
f0103668:	6b c0 74             	imul   $0x74,%eax,%eax
f010366b:	89 98 48 70 2a f0    	mov    %ebx,-0xfd58fb8(%eax)
	curenv->env_status = ENV_RUNNING; //Set it to running state
f0103671:	e8 d1 23 00 00       	call   f0105a47 <cpunum>
f0103676:	6b c0 74             	imul   $0x74,%eax,%eax
f0103679:	8b 80 48 70 2a f0    	mov    -0xfd58fb8(%eax),%eax
f010367f:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;	// Increment the env_runs counter
f0103686:	e8 bc 23 00 00       	call   f0105a47 <cpunum>
f010368b:	6b c0 74             	imul   $0x74,%eax,%eax
f010368e:	8b 80 48 70 2a f0    	mov    -0xfd58fb8(%eax),%eax
f0103694:	83 40 58 01          	addl   $0x1,0x58(%eax)
	
	lcr3(PADDR(e->env_pgdir));	//Use lcr3 to switch to the env directory
f0103698:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010369b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01036a0:	77 15                	ja     f01036b7 <env_run+0xa8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01036a2:	50                   	push   %eax
f01036a3:	68 08 69 10 f0       	push   $0xf0106908
f01036a8:	68 4f 02 00 00       	push   $0x24f
f01036ad:	68 c7 7b 10 f0       	push   $0xf0107bc7
f01036b2:	e8 89 c9 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01036b7:	05 00 00 00 10       	add    $0x10000000,%eax
f01036bc:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01036bf:	83 ec 0c             	sub    $0xc,%esp
f01036c2:	68 c0 34 12 f0       	push   $0xf01234c0
f01036c7:	e8 83 26 00 00       	call   f0105d4f <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01036cc:	f3 90                	pause  
	unlock_kernel();
	env_pop_tf(&e->env_tf);
f01036ce:	89 1c 24             	mov    %ebx,(%esp)
f01036d1:	e8 fb fe ff ff       	call   f01035d1 <env_pop_tf>

f01036d6 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01036d6:	55                   	push   %ebp
f01036d7:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01036d9:	ba 70 00 00 00       	mov    $0x70,%edx
f01036de:	8b 45 08             	mov    0x8(%ebp),%eax
f01036e1:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01036e2:	b2 71                	mov    $0x71,%dl
f01036e4:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01036e5:	0f b6 c0             	movzbl %al,%eax
}
f01036e8:	5d                   	pop    %ebp
f01036e9:	c3                   	ret    

f01036ea <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01036ea:	55                   	push   %ebp
f01036eb:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01036ed:	ba 70 00 00 00       	mov    $0x70,%edx
f01036f2:	8b 45 08             	mov    0x8(%ebp),%eax
f01036f5:	ee                   	out    %al,(%dx)
f01036f6:	b2 71                	mov    $0x71,%dl
f01036f8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036fb:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01036fc:	5d                   	pop    %ebp
f01036fd:	c3                   	ret    

f01036fe <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f01036fe:	55                   	push   %ebp
f01036ff:	89 e5                	mov    %esp,%ebp
f0103701:	56                   	push   %esi
f0103702:	53                   	push   %ebx
f0103703:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103706:	66 a3 e8 33 12 f0    	mov    %ax,0xf01233e8
	if (!didinit)
f010370c:	80 3d 74 62 2a f0 00 	cmpb   $0x0,0xf02a6274
f0103713:	74 57                	je     f010376c <irq_setmask_8259A+0x6e>
f0103715:	89 c6                	mov    %eax,%esi
f0103717:	ba 21 00 00 00       	mov    $0x21,%edx
f010371c:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
f010371d:	66 c1 e8 08          	shr    $0x8,%ax
f0103721:	b2 a1                	mov    $0xa1,%dl
f0103723:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f0103724:	83 ec 0c             	sub    $0xc,%esp
f0103727:	68 77 7c 10 f0       	push   $0xf0107c77
f010372c:	e8 19 01 00 00       	call   f010384a <cprintf>
f0103731:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f0103734:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103739:	0f b7 f6             	movzwl %si,%esi
f010373c:	f7 d6                	not    %esi
f010373e:	0f a3 de             	bt     %ebx,%esi
f0103741:	73 11                	jae    f0103754 <irq_setmask_8259A+0x56>
			cprintf(" %d", i);
f0103743:	83 ec 08             	sub    $0x8,%esp
f0103746:	53                   	push   %ebx
f0103747:	68 9b 81 10 f0       	push   $0xf010819b
f010374c:	e8 f9 00 00 00       	call   f010384a <cprintf>
f0103751:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f0103754:	83 c3 01             	add    $0x1,%ebx
f0103757:	83 fb 10             	cmp    $0x10,%ebx
f010375a:	75 e2                	jne    f010373e <irq_setmask_8259A+0x40>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f010375c:	83 ec 0c             	sub    $0xc,%esp
f010375f:	68 ee 80 10 f0       	push   $0xf01080ee
f0103764:	e8 e1 00 00 00       	call   f010384a <cprintf>
f0103769:	83 c4 10             	add    $0x10,%esp
}
f010376c:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010376f:	5b                   	pop    %ebx
f0103770:	5e                   	pop    %esi
f0103771:	5d                   	pop    %ebp
f0103772:	c3                   	ret    

f0103773 <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f0103773:	c6 05 74 62 2a f0 01 	movb   $0x1,0xf02a6274
f010377a:	ba 21 00 00 00       	mov    $0x21,%edx
f010377f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103784:	ee                   	out    %al,(%dx)
f0103785:	b2 a1                	mov    $0xa1,%dl
f0103787:	ee                   	out    %al,(%dx)
f0103788:	b2 20                	mov    $0x20,%dl
f010378a:	b8 11 00 00 00       	mov    $0x11,%eax
f010378f:	ee                   	out    %al,(%dx)
f0103790:	b2 21                	mov    $0x21,%dl
f0103792:	b8 20 00 00 00       	mov    $0x20,%eax
f0103797:	ee                   	out    %al,(%dx)
f0103798:	b8 04 00 00 00       	mov    $0x4,%eax
f010379d:	ee                   	out    %al,(%dx)
f010379e:	b8 03 00 00 00       	mov    $0x3,%eax
f01037a3:	ee                   	out    %al,(%dx)
f01037a4:	b2 a0                	mov    $0xa0,%dl
f01037a6:	b8 11 00 00 00       	mov    $0x11,%eax
f01037ab:	ee                   	out    %al,(%dx)
f01037ac:	b2 a1                	mov    $0xa1,%dl
f01037ae:	b8 28 00 00 00       	mov    $0x28,%eax
f01037b3:	ee                   	out    %al,(%dx)
f01037b4:	b8 02 00 00 00       	mov    $0x2,%eax
f01037b9:	ee                   	out    %al,(%dx)
f01037ba:	b8 01 00 00 00       	mov    $0x1,%eax
f01037bf:	ee                   	out    %al,(%dx)
f01037c0:	b2 20                	mov    $0x20,%dl
f01037c2:	b8 68 00 00 00       	mov    $0x68,%eax
f01037c7:	ee                   	out    %al,(%dx)
f01037c8:	b8 0a 00 00 00       	mov    $0xa,%eax
f01037cd:	ee                   	out    %al,(%dx)
f01037ce:	b2 a0                	mov    $0xa0,%dl
f01037d0:	b8 68 00 00 00       	mov    $0x68,%eax
f01037d5:	ee                   	out    %al,(%dx)
f01037d6:	b8 0a 00 00 00       	mov    $0xa,%eax
f01037db:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f01037dc:	0f b7 05 e8 33 12 f0 	movzwl 0xf01233e8,%eax
f01037e3:	66 83 f8 ff          	cmp    $0xffff,%ax
f01037e7:	74 13                	je     f01037fc <pic_init+0x89>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f01037e9:	55                   	push   %ebp
f01037ea:	89 e5                	mov    %esp,%ebp
f01037ec:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f01037ef:	0f b7 c0             	movzwl %ax,%eax
f01037f2:	50                   	push   %eax
f01037f3:	e8 06 ff ff ff       	call   f01036fe <irq_setmask_8259A>
f01037f8:	83 c4 10             	add    $0x10,%esp
}
f01037fb:	c9                   	leave  
f01037fc:	f3 c3                	repz ret 

f01037fe <irq_eoi>:
	cprintf("\n");
}

void
irq_eoi(void)
{
f01037fe:	55                   	push   %ebp
f01037ff:	89 e5                	mov    %esp,%ebp
f0103801:	ba 20 00 00 00       	mov    $0x20,%edx
f0103806:	b8 20 00 00 00       	mov    $0x20,%eax
f010380b:	ee                   	out    %al,(%dx)
f010380c:	b2 a0                	mov    $0xa0,%dl
f010380e:	ee                   	out    %al,(%dx)
	//   s: specific
	//   e: end-of-interrupt
	// xxx: specific interrupt line
	outb(IO_PIC1, 0x20);
	outb(IO_PIC2, 0x20);
}
f010380f:	5d                   	pop    %ebp
f0103810:	c3                   	ret    

f0103811 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103811:	55                   	push   %ebp
f0103812:	89 e5                	mov    %esp,%ebp
f0103814:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0103817:	ff 75 08             	pushl  0x8(%ebp)
f010381a:	e8 68 cf ff ff       	call   f0100787 <cputchar>
f010381f:	83 c4 10             	add    $0x10,%esp
	*cnt++;
}
f0103822:	c9                   	leave  
f0103823:	c3                   	ret    

f0103824 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103824:	55                   	push   %ebp
f0103825:	89 e5                	mov    %esp,%ebp
f0103827:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010382a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103831:	ff 75 0c             	pushl  0xc(%ebp)
f0103834:	ff 75 08             	pushl  0x8(%ebp)
f0103837:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010383a:	50                   	push   %eax
f010383b:	68 11 38 10 f0       	push   $0xf0103811
f0103840:	e8 52 15 00 00       	call   f0104d97 <vprintfmt>
	return cnt;
}
f0103845:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103848:	c9                   	leave  
f0103849:	c3                   	ret    

f010384a <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010384a:	55                   	push   %ebp
f010384b:	89 e5                	mov    %esp,%ebp
f010384d:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103850:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103853:	50                   	push   %eax
f0103854:	ff 75 08             	pushl  0x8(%ebp)
f0103857:	e8 c8 ff ff ff       	call   f0103824 <vcprintf>
	va_end(ap);

	return cnt;
}
f010385c:	c9                   	leave  
f010385d:	c3                   	ret    

f010385e <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f010385e:	55                   	push   %ebp
f010385f:	89 e5                	mov    %esp,%ebp
f0103861:	56                   	push   %esi
f0103862:	53                   	push   %ebx
	// user space on that CPU.
	//
	// LAB 4: Your code here:

	
	int i = cpunum();
f0103863:	e8 df 21 00 00       	call   f0105a47 <cpunum>
f0103868:	89 c3                	mov    %eax,%ebx
	

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	thiscpu->cpu_ts.ts_esp0 = (uintptr_t)(percpu_kstacks[cpunum()] + KSTKSIZE);
f010386a:	e8 d8 21 00 00       	call   f0105a47 <cpunum>
f010386f:	89 c6                	mov    %eax,%esi
f0103871:	e8 d1 21 00 00       	call   f0105a47 <cpunum>
f0103876:	6b f6 74             	imul   $0x74,%esi,%esi
f0103879:	c1 e0 0f             	shl    $0xf,%eax
f010387c:	8d 80 00 00 2b f0    	lea    -0xfd50000(%eax),%eax
f0103882:	89 86 50 70 2a f0    	mov    %eax,-0xfd58fb0(%esi)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f0103888:	e8 ba 21 00 00       	call   f0105a47 <cpunum>
f010388d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103890:	66 c7 80 54 70 2a f0 	movw   $0x10,-0xfd58fac(%eax)
f0103897:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3)+i] = SEG16(STS_T32A, (uint32_t) (&cpus[i].cpu_ts),  //It was (&ts) instead of &cpus[i].cpu_ts
f0103899:	8d 43 05             	lea    0x5(%ebx),%eax
f010389c:	6b d3 74             	imul   $0x74,%ebx,%edx
f010389f:	81 c2 4c 70 2a f0    	add    $0xf02a704c,%edx
f01038a5:	66 c7 04 c5 80 33 12 	movw   $0x67,-0xfedcc80(,%eax,8)
f01038ac:	f0 67 00 
f01038af:	66 89 14 c5 82 33 12 	mov    %dx,-0xfedcc7e(,%eax,8)
f01038b6:	f0 
f01038b7:	89 d1                	mov    %edx,%ecx
f01038b9:	c1 e9 10             	shr    $0x10,%ecx
f01038bc:	88 0c c5 84 33 12 f0 	mov    %cl,-0xfedcc7c(,%eax,8)
f01038c3:	c6 04 c5 86 33 12 f0 	movb   $0x40,-0xfedcc7a(,%eax,8)
f01038ca:	40 
f01038cb:	c1 ea 18             	shr    $0x18,%edx
f01038ce:	88 14 c5 87 33 12 f0 	mov    %dl,-0xfedcc79(,%eax,8)
					sizeof(struct Taskstate)-1, 0);
	gdt[(GD_TSS0 >> 3)+i].sd_s = 0;
f01038d5:	c6 04 c5 85 33 12 f0 	movb   $0x89,-0xfedcc7b(,%eax,8)
f01038dc:	89 

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(((GD_TSS0>>3) + i) << 3);	
f01038dd:	8d 1c dd 28 00 00 00 	lea    0x28(,%ebx,8),%ebx
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f01038e4:	0f 00 db             	ltr    %bx
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f01038e7:	b8 ea 33 12 f0       	mov    $0xf01233ea,%eax
f01038ec:	0f 01 18             	lidtl  (%eax)
	lidt(&idt_pd); 
	
	


}
f01038ef:	5b                   	pop    %ebx
f01038f0:	5e                   	pop    %esi
f01038f1:	5d                   	pop    %ebp
f01038f2:	c3                   	ret    

f01038f3 <trap_init>:
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i,j; 
	for (i=0; i<= T_SIMDERR;i++){
f01038f3:	b8 00 00 00 00       	mov    $0x0,%eax
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
f01038f8:	8b 14 85 f0 33 12 f0 	mov    -0xfedcc10(,%eax,4),%edx
f01038ff:	66 89 14 c5 80 62 2a 	mov    %dx,-0xfd59d80(,%eax,8)
f0103906:	f0 
f0103907:	66 c7 04 c5 82 62 2a 	movw   $0x8,-0xfd59d7e(,%eax,8)
f010390e:	f0 08 00 
f0103911:	c6 04 c5 84 62 2a f0 	movb   $0x0,-0xfd59d7c(,%eax,8)
f0103918:	00 
f0103919:	c6 04 c5 85 62 2a f0 	movb   $0x8e,-0xfd59d7b(,%eax,8)
f0103920:	8e 
f0103921:	c1 ea 10             	shr    $0x10,%edx
f0103924:	66 89 14 c5 86 62 2a 	mov    %dx,-0xfd59d7a(,%eax,8)
f010392b:	f0 
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i,j; 
	for (i=0; i<= T_SIMDERR;i++){
f010392c:	83 c0 01             	add    $0x1,%eax
f010392f:	83 f8 14             	cmp    $0x14,%eax
f0103932:	75 c4                	jne    f01038f8 <trap_init+0x5>
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
	}

	//Interrupt 3 is a soft interrupt generated by user, hence the dpl of the gate will be checked with 3
  	SETGATE(idt[3],0,GD_KT,int_vector_table[3],3);
f0103934:	a1 fc 33 12 f0       	mov    0xf01233fc,%eax
f0103939:	66 a3 98 62 2a f0    	mov    %ax,0xf02a6298
f010393f:	66 c7 05 9a 62 2a f0 	movw   $0x8,0xf02a629a
f0103946:	08 00 
f0103948:	c6 05 9c 62 2a f0 00 	movb   $0x0,0xf02a629c
f010394f:	c6 05 9d 62 2a f0 ee 	movb   $0xee,0xf02a629d
f0103956:	c1 e8 10             	shr    $0x10,%eax
f0103959:	66 a3 9e 62 2a f0    	mov    %ax,0xf02a629e

	//similarly system call is setup by the user and hence the gate should be checked with 3 
	SETGATE(idt[T_SYSCALL], 0, GD_KT, int_vector_table[T_SYSCALL], 3);// T_SYSCALL = 3
f010395f:	a1 b0 34 12 f0       	mov    0xf01234b0,%eax
f0103964:	66 a3 00 64 2a f0    	mov    %ax,0xf02a6400
f010396a:	66 c7 05 02 64 2a f0 	movw   $0x8,0xf02a6402
f0103971:	08 00 
f0103973:	c6 05 04 64 2a f0 00 	movb   $0x0,0xf02a6404
f010397a:	c6 05 05 64 2a f0 ee 	movb   $0xee,0xf02a6405
f0103981:	c1 e8 10             	shr    $0x10,%eax
f0103984:	66 a3 06 64 2a f0    	mov    %ax,0xf02a6406
f010398a:	b8 20 00 00 00       	mov    $0x20,%eax

	//For IRQ interrupts
	for(j=0;j<16;j++)
	    SETGATE(idt[IRQ_OFFSET + j], 0, GD_KT, int_vector_table[IRQ_OFFSET + j], 3);
f010398f:	8b 14 85 f0 33 12 f0 	mov    -0xfedcc10(,%eax,4),%edx
f0103996:	66 89 14 c5 80 62 2a 	mov    %dx,-0xfd59d80(,%eax,8)
f010399d:	f0 
f010399e:	66 c7 04 c5 82 62 2a 	movw   $0x8,-0xfd59d7e(,%eax,8)
f01039a5:	f0 08 00 
f01039a8:	c6 04 c5 84 62 2a f0 	movb   $0x0,-0xfd59d7c(,%eax,8)
f01039af:	00 
f01039b0:	c6 04 c5 85 62 2a f0 	movb   $0xee,-0xfd59d7b(,%eax,8)
f01039b7:	ee 
f01039b8:	c1 ea 10             	shr    $0x10,%edx
f01039bb:	66 89 14 c5 86 62 2a 	mov    %dx,-0xfd59d7a(,%eax,8)
f01039c2:	f0 
f01039c3:	83 c0 01             	add    $0x1,%eax

	//similarly system call is setup by the user and hence the gate should be checked with 3 
	SETGATE(idt[T_SYSCALL], 0, GD_KT, int_vector_table[T_SYSCALL], 3);// T_SYSCALL = 3

	//For IRQ interrupts
	for(j=0;j<16;j++)
f01039c6:	83 f8 30             	cmp    $0x30,%eax
f01039c9:	75 c4                	jne    f010398f <trap_init+0x9c>
}


void
trap_init(void)
{
f01039cb:	55                   	push   %ebp
f01039cc:	89 e5                	mov    %esp,%ebp
f01039ce:	83 ec 08             	sub    $0x8,%esp
	//For IRQ interrupts
	for(j=0;j<16;j++)
	    SETGATE(idt[IRQ_OFFSET + j], 0, GD_KT, int_vector_table[IRQ_OFFSET + j], 3);

	// Per-CPU setup 
	trap_init_percpu();
f01039d1:	e8 88 fe ff ff       	call   f010385e <trap_init_percpu>
}
f01039d6:	c9                   	leave  
f01039d7:	c3                   	ret    

f01039d8 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01039d8:	55                   	push   %ebp
f01039d9:	89 e5                	mov    %esp,%ebp
f01039db:	53                   	push   %ebx
f01039dc:	83 ec 0c             	sub    $0xc,%esp
f01039df:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01039e2:	ff 33                	pushl  (%ebx)
f01039e4:	68 8b 7c 10 f0       	push   $0xf0107c8b
f01039e9:	e8 5c fe ff ff       	call   f010384a <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01039ee:	83 c4 08             	add    $0x8,%esp
f01039f1:	ff 73 04             	pushl  0x4(%ebx)
f01039f4:	68 9a 7c 10 f0       	push   $0xf0107c9a
f01039f9:	e8 4c fe ff ff       	call   f010384a <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01039fe:	83 c4 08             	add    $0x8,%esp
f0103a01:	ff 73 08             	pushl  0x8(%ebx)
f0103a04:	68 a9 7c 10 f0       	push   $0xf0107ca9
f0103a09:	e8 3c fe ff ff       	call   f010384a <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103a0e:	83 c4 08             	add    $0x8,%esp
f0103a11:	ff 73 0c             	pushl  0xc(%ebx)
f0103a14:	68 b8 7c 10 f0       	push   $0xf0107cb8
f0103a19:	e8 2c fe ff ff       	call   f010384a <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103a1e:	83 c4 08             	add    $0x8,%esp
f0103a21:	ff 73 10             	pushl  0x10(%ebx)
f0103a24:	68 c7 7c 10 f0       	push   $0xf0107cc7
f0103a29:	e8 1c fe ff ff       	call   f010384a <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103a2e:	83 c4 08             	add    $0x8,%esp
f0103a31:	ff 73 14             	pushl  0x14(%ebx)
f0103a34:	68 d6 7c 10 f0       	push   $0xf0107cd6
f0103a39:	e8 0c fe ff ff       	call   f010384a <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103a3e:	83 c4 08             	add    $0x8,%esp
f0103a41:	ff 73 18             	pushl  0x18(%ebx)
f0103a44:	68 e5 7c 10 f0       	push   $0xf0107ce5
f0103a49:	e8 fc fd ff ff       	call   f010384a <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103a4e:	83 c4 08             	add    $0x8,%esp
f0103a51:	ff 73 1c             	pushl  0x1c(%ebx)
f0103a54:	68 f4 7c 10 f0       	push   $0xf0107cf4
f0103a59:	e8 ec fd ff ff       	call   f010384a <cprintf>
f0103a5e:	83 c4 10             	add    $0x10,%esp
}
f0103a61:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103a64:	c9                   	leave  
f0103a65:	c3                   	ret    

f0103a66 <print_trapframe>:

}

void
print_trapframe(struct Trapframe *tf)
{
f0103a66:	55                   	push   %ebp
f0103a67:	89 e5                	mov    %esp,%ebp
f0103a69:	56                   	push   %esi
f0103a6a:	53                   	push   %ebx
f0103a6b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103a6e:	e8 d4 1f 00 00       	call   f0105a47 <cpunum>
f0103a73:	83 ec 04             	sub    $0x4,%esp
f0103a76:	50                   	push   %eax
f0103a77:	53                   	push   %ebx
f0103a78:	68 58 7d 10 f0       	push   $0xf0107d58
f0103a7d:	e8 c8 fd ff ff       	call   f010384a <cprintf>
	print_regs(&tf->tf_regs);
f0103a82:	89 1c 24             	mov    %ebx,(%esp)
f0103a85:	e8 4e ff ff ff       	call   f01039d8 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103a8a:	83 c4 08             	add    $0x8,%esp
f0103a8d:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103a91:	50                   	push   %eax
f0103a92:	68 76 7d 10 f0       	push   $0xf0107d76
f0103a97:	e8 ae fd ff ff       	call   f010384a <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103a9c:	83 c4 08             	add    $0x8,%esp
f0103a9f:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103aa3:	50                   	push   %eax
f0103aa4:	68 89 7d 10 f0       	push   $0xf0107d89
f0103aa9:	e8 9c fd ff ff       	call   f010384a <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103aae:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103ab1:	83 c4 10             	add    $0x10,%esp
f0103ab4:	83 f8 13             	cmp    $0x13,%eax
f0103ab7:	77 09                	ja     f0103ac2 <print_trapframe+0x5c>
		return excnames[trapno];
f0103ab9:	8b 14 85 40 80 10 f0 	mov    -0xfef7fc0(,%eax,4),%edx
f0103ac0:	eb 1f                	jmp    f0103ae1 <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103ac2:	83 f8 30             	cmp    $0x30,%eax
f0103ac5:	74 15                	je     f0103adc <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103ac7:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103aca:	83 fa 10             	cmp    $0x10,%edx
f0103acd:	b9 22 7d 10 f0       	mov    $0xf0107d22,%ecx
f0103ad2:	ba 0f 7d 10 f0       	mov    $0xf0107d0f,%edx
f0103ad7:	0f 43 d1             	cmovae %ecx,%edx
f0103ada:	eb 05                	jmp    f0103ae1 <print_trapframe+0x7b>
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103adc:	ba 03 7d 10 f0       	mov    $0xf0107d03,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103ae1:	83 ec 04             	sub    $0x4,%esp
f0103ae4:	52                   	push   %edx
f0103ae5:	50                   	push   %eax
f0103ae6:	68 9c 7d 10 f0       	push   $0xf0107d9c
f0103aeb:	e8 5a fd ff ff       	call   f010384a <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103af0:	83 c4 10             	add    $0x10,%esp
f0103af3:	3b 1d 80 6a 2a f0    	cmp    0xf02a6a80,%ebx
f0103af9:	75 1a                	jne    f0103b15 <print_trapframe+0xaf>
f0103afb:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103aff:	75 14                	jne    f0103b15 <print_trapframe+0xaf>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103b01:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103b04:	83 ec 08             	sub    $0x8,%esp
f0103b07:	50                   	push   %eax
f0103b08:	68 ae 7d 10 f0       	push   $0xf0107dae
f0103b0d:	e8 38 fd ff ff       	call   f010384a <cprintf>
f0103b12:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103b15:	83 ec 08             	sub    $0x8,%esp
f0103b18:	ff 73 2c             	pushl  0x2c(%ebx)
f0103b1b:	68 bd 7d 10 f0       	push   $0xf0107dbd
f0103b20:	e8 25 fd ff ff       	call   f010384a <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103b25:	83 c4 10             	add    $0x10,%esp
f0103b28:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103b2c:	75 49                	jne    f0103b77 <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103b2e:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103b31:	89 c2                	mov    %eax,%edx
f0103b33:	83 e2 01             	and    $0x1,%edx
f0103b36:	ba 3c 7d 10 f0       	mov    $0xf0107d3c,%edx
f0103b3b:	b9 31 7d 10 f0       	mov    $0xf0107d31,%ecx
f0103b40:	0f 44 ca             	cmove  %edx,%ecx
f0103b43:	89 c2                	mov    %eax,%edx
f0103b45:	83 e2 02             	and    $0x2,%edx
f0103b48:	ba 4e 7d 10 f0       	mov    $0xf0107d4e,%edx
f0103b4d:	be 48 7d 10 f0       	mov    $0xf0107d48,%esi
f0103b52:	0f 45 d6             	cmovne %esi,%edx
f0103b55:	83 e0 04             	and    $0x4,%eax
f0103b58:	be a4 7e 10 f0       	mov    $0xf0107ea4,%esi
f0103b5d:	b8 53 7d 10 f0       	mov    $0xf0107d53,%eax
f0103b62:	0f 44 c6             	cmove  %esi,%eax
f0103b65:	51                   	push   %ecx
f0103b66:	52                   	push   %edx
f0103b67:	50                   	push   %eax
f0103b68:	68 cb 7d 10 f0       	push   $0xf0107dcb
f0103b6d:	e8 d8 fc ff ff       	call   f010384a <cprintf>
f0103b72:	83 c4 10             	add    $0x10,%esp
f0103b75:	eb 10                	jmp    f0103b87 <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103b77:	83 ec 0c             	sub    $0xc,%esp
f0103b7a:	68 ee 80 10 f0       	push   $0xf01080ee
f0103b7f:	e8 c6 fc ff ff       	call   f010384a <cprintf>
f0103b84:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103b87:	83 ec 08             	sub    $0x8,%esp
f0103b8a:	ff 73 30             	pushl  0x30(%ebx)
f0103b8d:	68 da 7d 10 f0       	push   $0xf0107dda
f0103b92:	e8 b3 fc ff ff       	call   f010384a <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103b97:	83 c4 08             	add    $0x8,%esp
f0103b9a:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103b9e:	50                   	push   %eax
f0103b9f:	68 e9 7d 10 f0       	push   $0xf0107de9
f0103ba4:	e8 a1 fc ff ff       	call   f010384a <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103ba9:	83 c4 08             	add    $0x8,%esp
f0103bac:	ff 73 38             	pushl  0x38(%ebx)
f0103baf:	68 fc 7d 10 f0       	push   $0xf0107dfc
f0103bb4:	e8 91 fc ff ff       	call   f010384a <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103bb9:	83 c4 10             	add    $0x10,%esp
f0103bbc:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103bc0:	74 25                	je     f0103be7 <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103bc2:	83 ec 08             	sub    $0x8,%esp
f0103bc5:	ff 73 3c             	pushl  0x3c(%ebx)
f0103bc8:	68 0b 7e 10 f0       	push   $0xf0107e0b
f0103bcd:	e8 78 fc ff ff       	call   f010384a <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103bd2:	83 c4 08             	add    $0x8,%esp
f0103bd5:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103bd9:	50                   	push   %eax
f0103bda:	68 1a 7e 10 f0       	push   $0xf0107e1a
f0103bdf:	e8 66 fc ff ff       	call   f010384a <cprintf>
f0103be4:	83 c4 10             	add    $0x10,%esp
	}
}
f0103be7:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103bea:	5b                   	pop    %ebx
f0103beb:	5e                   	pop    %esi
f0103bec:	5d                   	pop    %ebp
f0103bed:	c3                   	ret    

f0103bee <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103bee:	55                   	push   %ebp
f0103bef:	89 e5                	mov    %esp,%ebp
f0103bf1:	57                   	push   %edi
f0103bf2:	56                   	push   %esi
f0103bf3:	53                   	push   %ebx
f0103bf4:	83 ec 1c             	sub    $0x1c,%esp
f0103bf7:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103bfa:	0f 20 d6             	mov    %cr2,%esi
	// LAB 3: Your code here.


	//If the processor is already in kernel mode when the interrupt or exception occurs 
	//(the low 2 bits of the CS register are already zero), Hence we have to check the CS register to make sure its in kernel mode
	if ((tf->tf_cs & 0x11) == 0){
f0103bfd:	f6 43 34 11          	testb  $0x11,0x34(%ebx)
f0103c01:	75 15                	jne    f0103c18 <page_fault_handler+0x2a>
		panic("Fault occured in kernel space on %08x \n",fault_va);
f0103c03:	56                   	push   %esi
f0103c04:	68 f0 7f 10 f0       	push   $0xf0107ff0
f0103c09:	68 5f 01 00 00       	push   $0x15f
f0103c0e:	68 2d 7e 10 f0       	push   $0xf0107e2d
f0103c13:	e8 28 c4 ff ff       	call   f0100040 <_panic>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	//Store the current env's stack tf_esp for use, if the call occurs inside UXtrapframe  
	const uint32_t cur_tf_esp_addr = (uint32_t)(tf->tf_esp); 	// trap-time esp
f0103c18:	8b 7b 3c             	mov    0x3c(%ebx),%edi

	

	// If there is no env_pgfault_upcall or no page fault handler for the curenv follow the original procedure
	if (!curenv->env_pgfault_upcall)
f0103c1b:	e8 27 1e 00 00       	call   f0105a47 <cpunum>
f0103c20:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c23:	8b 80 48 70 2a f0    	mov    -0xfd58fb8(%eax),%eax
f0103c29:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f0103c2d:	75 46                	jne    f0103c75 <page_fault_handler+0x87>
	{
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c2f:	8b 43 30             	mov    0x30(%ebx),%eax
f0103c32:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			curenv->env_id, fault_va, tf->tf_eip);
f0103c35:	e8 0d 1e 00 00       	call   f0105a47 <cpunum>
	

	// If there is no env_pgfault_upcall or no page fault handler for the curenv follow the original procedure
	if (!curenv->env_pgfault_upcall)
	{
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c3a:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103c3d:	56                   	push   %esi
			curenv->env_id, fault_va, tf->tf_eip);
f0103c3e:	6b c0 74             	imul   $0x74,%eax,%eax
	

	// If there is no env_pgfault_upcall or no page fault handler for the curenv follow the original procedure
	if (!curenv->env_pgfault_upcall)
	{
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c41:	8b 80 48 70 2a f0    	mov    -0xfd58fb8(%eax),%eax
f0103c47:	ff 70 48             	pushl  0x48(%eax)
f0103c4a:	68 18 80 10 f0       	push   $0xf0108018
f0103c4f:	e8 f6 fb ff ff       	call   f010384a <cprintf>
			curenv->env_id, fault_va, tf->tf_eip);
		print_trapframe(tf);
f0103c54:	89 1c 24             	mov    %ebx,(%esp)
f0103c57:	e8 0a fe ff ff       	call   f0103a66 <print_trapframe>
		env_destroy(curenv);	// Destroy the environment that caused the fault.
f0103c5c:	e8 e6 1d 00 00       	call   f0105a47 <cpunum>
f0103c61:	83 c4 04             	add    $0x4,%esp
f0103c64:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c67:	ff b0 48 70 2a f0    	pushl  -0xfd58fb8(%eax)
f0103c6d:	e8 fe f8 ff ff       	call   f0103570 <env_destroy>
f0103c72:	83 c4 10             	add    $0x10,%esp
	}
	
	//Check if the	
	struct UTrapframe* usertf = NULL; //As defined in inc/trap.h
	
	if((cur_tf_esp_addr < UXSTACKTOP) && (cur_tf_esp_addr >=(UXSTACKTOP - PGSIZE)))
f0103c75:	8d 97 00 10 40 11    	lea    0x11401000(%edi),%edx
	{
		//If its already inside the exception stack
		//Allocate the address by leaving space for 32-bit word
		usertf = (struct UTrapframe*)(cur_tf_esp_addr - 4 - sizeof(struct UTrapframe));
f0103c7b:	8d 47 c8             	lea    -0x38(%edi),%eax
f0103c7e:	81 fa ff 0f 00 00    	cmp    $0xfff,%edx
f0103c84:	ba cc ff bf ee       	mov    $0xeebfffcc,%edx
f0103c89:	0f 46 d0             	cmovbe %eax,%edx
f0103c8c:	89 d7                	mov    %edx,%edi
		usertf = (struct UTrapframe*)(UXSTACKTOP - sizeof(struct UTrapframe));
	}
	
	//Check whether the usertf memory is valid
	//This function will not return if there is a fault and it will also destroy the environment
	user_mem_assert(curenv, (void*)usertf, sizeof(struct UTrapframe), PTE_U | PTE_P | PTE_W);
f0103c8e:	e8 b4 1d 00 00       	call   f0105a47 <cpunum>
f0103c93:	6a 07                	push   $0x7
f0103c95:	6a 34                	push   $0x34
f0103c97:	57                   	push   %edi
f0103c98:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c9b:	ff b0 48 70 2a f0    	pushl  -0xfd58fb8(%eax)
f0103ca1:	e8 99 f2 ff ff       	call   f0102f3f <user_mem_assert>
	
	
	// User exeception trapframe
	usertf->utf_fault_va = fault_va;
f0103ca6:	89 fa                	mov    %edi,%edx
f0103ca8:	89 37                	mov    %esi,(%edi)
	usertf->utf_err = tf->tf_err;
f0103caa:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103cad:	89 47 04             	mov    %eax,0x4(%edi)
	usertf->utf_regs = tf->tf_regs;
f0103cb0:	8d 7f 08             	lea    0x8(%edi),%edi
f0103cb3:	b9 08 00 00 00       	mov    $0x8,%ecx
f0103cb8:	89 de                	mov    %ebx,%esi
f0103cba:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	usertf->utf_eip = tf->tf_eip;
f0103cbc:	8b 43 30             	mov    0x30(%ebx),%eax
f0103cbf:	89 42 28             	mov    %eax,0x28(%edx)
	usertf->utf_esp = tf->tf_esp;
f0103cc2:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103cc5:	89 42 30             	mov    %eax,0x30(%edx)
	usertf->utf_eflags = tf->tf_eflags;
f0103cc8:	8b 43 38             	mov    0x38(%ebx),%eax
f0103ccb:	89 42 2c             	mov    %eax,0x2c(%edx)
	
	//Setup the tf with Exception stack frame
	
	tf->tf_esp= (uintptr_t)usertf;
f0103cce:	89 53 3c             	mov    %edx,0x3c(%ebx)
	tf->tf_eip = (uintptr_t)curenv->env_pgfault_upcall; 
f0103cd1:	e8 71 1d 00 00       	call   f0105a47 <cpunum>
f0103cd6:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cd9:	8b 80 48 70 2a f0    	mov    -0xfd58fb8(%eax),%eax
f0103cdf:	8b 40 64             	mov    0x64(%eax),%eax
f0103ce2:	89 43 30             	mov    %eax,0x30(%ebx)

	env_run(curenv);
f0103ce5:	e8 5d 1d 00 00       	call   f0105a47 <cpunum>
f0103cea:	83 c4 04             	add    $0x4,%esp
f0103ced:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cf0:	ff b0 48 70 2a f0    	pushl  -0xfd58fb8(%eax)
f0103cf6:	e8 14 f9 ff ff       	call   f010360f <env_run>

f0103cfb <trap>:
	
}

void
trap(struct Trapframe *tf)
{
f0103cfb:	55                   	push   %ebp
f0103cfc:	89 e5                	mov    %esp,%ebp
f0103cfe:	57                   	push   %edi
f0103cff:	56                   	push   %esi
f0103d00:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103d03:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103d04:	83 3d cc 6e 2a f0 00 	cmpl   $0x0,0xf02a6ecc
f0103d0b:	74 01                	je     f0103d0e <trap+0x13>
		asm volatile("hlt");
f0103d0d:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103d0e:	e8 34 1d 00 00       	call   f0105a47 <cpunum>
f0103d13:	6b d0 74             	imul   $0x74,%eax,%edx
f0103d16:	81 c2 40 70 2a f0    	add    $0xf02a7040,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0103d1c:	b8 01 00 00 00       	mov    $0x1,%eax
f0103d21:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103d25:	83 f8 02             	cmp    $0x2,%eax
f0103d28:	75 10                	jne    f0103d3a <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103d2a:	83 ec 0c             	sub    $0xc,%esp
f0103d2d:	68 c0 34 12 f0       	push   $0xf01234c0
f0103d32:	e8 7b 1f 00 00       	call   f0105cb2 <spin_lock>
f0103d37:	83 c4 10             	add    $0x10,%esp

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103d3a:	9c                   	pushf  
f0103d3b:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103d3c:	f6 c4 02             	test   $0x2,%ah
f0103d3f:	74 19                	je     f0103d5a <trap+0x5f>
f0103d41:	68 39 7e 10 f0       	push   $0xf0107e39
f0103d46:	68 9b 78 10 f0       	push   $0xf010789b
f0103d4b:	68 25 01 00 00       	push   $0x125
f0103d50:	68 2d 7e 10 f0       	push   $0xf0107e2d
f0103d55:	e8 e6 c2 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103d5a:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103d5e:	83 e0 03             	and    $0x3,%eax
f0103d61:	66 83 f8 03          	cmp    $0x3,%ax
f0103d65:	0f 85 a0 00 00 00    	jne    f0103e0b <trap+0x110>
f0103d6b:	83 ec 0c             	sub    $0xc,%esp
f0103d6e:	68 c0 34 12 f0       	push   $0xf01234c0
f0103d73:	e8 3a 1f 00 00       	call   f0105cb2 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel(); //Lock Kernel
		assert(curenv);
f0103d78:	e8 ca 1c 00 00       	call   f0105a47 <cpunum>
f0103d7d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d80:	83 c4 10             	add    $0x10,%esp
f0103d83:	83 b8 48 70 2a f0 00 	cmpl   $0x0,-0xfd58fb8(%eax)
f0103d8a:	75 19                	jne    f0103da5 <trap+0xaa>
f0103d8c:	68 52 7e 10 f0       	push   $0xf0107e52
f0103d91:	68 9b 78 10 f0       	push   $0xf010789b
f0103d96:	68 2d 01 00 00       	push   $0x12d
f0103d9b:	68 2d 7e 10 f0       	push   $0xf0107e2d
f0103da0:	e8 9b c2 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103da5:	e8 9d 1c 00 00       	call   f0105a47 <cpunum>
f0103daa:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dad:	8b 80 48 70 2a f0    	mov    -0xfd58fb8(%eax),%eax
f0103db3:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103db7:	75 2d                	jne    f0103de6 <trap+0xeb>
			env_free(curenv);
f0103db9:	e8 89 1c 00 00       	call   f0105a47 <cpunum>
f0103dbe:	83 ec 0c             	sub    $0xc,%esp
f0103dc1:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dc4:	ff b0 48 70 2a f0    	pushl  -0xfd58fb8(%eax)
f0103dca:	e8 fb f5 ff ff       	call   f01033ca <env_free>
			curenv = NULL;
f0103dcf:	e8 73 1c 00 00       	call   f0105a47 <cpunum>
f0103dd4:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dd7:	c7 80 48 70 2a f0 00 	movl   $0x0,-0xfd58fb8(%eax)
f0103dde:	00 00 00 
			sched_yield();
f0103de1:	e8 1e 04 00 00       	call   f0104204 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103de6:	e8 5c 1c 00 00       	call   f0105a47 <cpunum>
f0103deb:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dee:	8b 80 48 70 2a f0    	mov    -0xfd58fb8(%eax),%eax
f0103df4:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103df9:	89 c7                	mov    %eax,%edi
f0103dfb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103dfd:	e8 45 1c 00 00       	call   f0105a47 <cpunum>
f0103e02:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e05:	8b b0 48 70 2a f0    	mov    -0xfd58fb8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103e0b:	89 35 80 6a 2a f0    	mov    %esi,0xf02a6a80
{

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0103e11:	8b 46 28             	mov    0x28(%esi),%eax
f0103e14:	83 f8 27             	cmp    $0x27,%eax
f0103e17:	75 1d                	jne    f0103e36 <trap+0x13b>
		cprintf("Spurious interrupt on irq 7\n");
f0103e19:	83 ec 0c             	sub    $0xc,%esp
f0103e1c:	68 59 7e 10 f0       	push   $0xf0107e59
f0103e21:	e8 24 fa ff ff       	call   f010384a <cprintf>
		print_trapframe(tf);
f0103e26:	89 34 24             	mov    %esi,(%esp)
f0103e29:	e8 38 fc ff ff       	call   f0103a66 <print_trapframe>
f0103e2e:	83 c4 10             	add    $0x10,%esp
f0103e31:	e9 ce 00 00 00       	jmp    f0103f04 <trap+0x209>
	}

	// Handle processor exceptions.
	// LAB 3: Your code here.
	//call trap_handler function for page_fault
	switch (tf->tf_trapno) {
f0103e36:	83 f8 20             	cmp    $0x20,%eax
f0103e39:	74 69                	je     f0103ea4 <trap+0x1a9>
f0103e3b:	83 f8 20             	cmp    $0x20,%eax
f0103e3e:	77 0c                	ja     f0103e4c <trap+0x151>
f0103e40:	83 f8 03             	cmp    $0x3,%eax
f0103e43:	74 18                	je     f0103e5d <trap+0x162>
f0103e45:	83 f8 0e             	cmp    $0xe,%eax
f0103e48:	74 30                	je     f0103e7a <trap+0x17f>
f0103e4a:	eb 75                	jmp    f0103ec1 <trap+0x1c6>
f0103e4c:	83 f8 24             	cmp    $0x24,%eax
f0103e4f:	74 69                	je     f0103eba <trap+0x1bf>
f0103e51:	83 f8 30             	cmp    $0x30,%eax
f0103e54:	74 2d                	je     f0103e83 <trap+0x188>
f0103e56:	83 f8 21             	cmp    $0x21,%eax
f0103e59:	75 66                	jne    f0103ec1 <trap+0x1c6>
f0103e5b:	eb 56                	jmp    f0103eb3 <trap+0x1b8>
		case T_BRKPT:
			monitor(tf);
f0103e5d:	83 ec 0c             	sub    $0xc,%esp
f0103e60:	56                   	push   %esi
f0103e61:	e8 ba ca ff ff       	call   f0100920 <monitor>
			cprintf("return from breakpoint....\n");
f0103e66:	c7 04 24 76 7e 10 f0 	movl   $0xf0107e76,(%esp)
f0103e6d:	e8 d8 f9 ff ff       	call   f010384a <cprintf>
f0103e72:	83 c4 10             	add    $0x10,%esp
f0103e75:	e9 8a 00 00 00       	jmp    f0103f04 <trap+0x209>
			break;

		case T_PGFLT:
			page_fault_handler(tf);
f0103e7a:	83 ec 0c             	sub    $0xc,%esp
f0103e7d:	56                   	push   %esi
f0103e7e:	e8 6b fd ff ff       	call   f0103bee <page_fault_handler>
			break;

		case T_SYSCALL:
			tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax,
f0103e83:	83 ec 08             	sub    $0x8,%esp
f0103e86:	ff 76 04             	pushl  0x4(%esi)
f0103e89:	ff 36                	pushl  (%esi)
f0103e8b:	ff 76 10             	pushl  0x10(%esi)
f0103e8e:	ff 76 18             	pushl  0x18(%esi)
f0103e91:	ff 76 14             	pushl  0x14(%esi)
f0103e94:	ff 76 1c             	pushl  0x1c(%esi)
f0103e97:	e8 48 04 00 00       	call   f01042e4 <syscall>
f0103e9c:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103e9f:	83 c4 20             	add    $0x20,%esp
f0103ea2:	eb 60                	jmp    f0103f04 <trap+0x209>

		// Handle clock interrupts. Don't forget to acknowledge the
		// interrupt using lapic_eoi() before calling the scheduler!
		// LAB 4: Your code here.
		case IRQ_OFFSET+IRQ_TIMER:
			time_tick();
f0103ea4:	e8 03 27 00 00       	call   f01065ac <time_tick>
			lapic_eoi();
f0103ea9:	e8 e4 1c 00 00       	call   f0105b92 <lapic_eoi>
			sched_yield();
f0103eae:	e8 51 03 00 00       	call   f0104204 <sched_yield>
			break;
		
		// Handle keyboard and serial interrupts.
		// LAB 5: Your code here.
		case IRQ_OFFSET+IRQ_KBD:
			kbd_intr();
f0103eb3:	e8 3c c7 ff ff       	call   f01005f4 <kbd_intr>
f0103eb8:	eb 4a                	jmp    f0103f04 <trap+0x209>
			break;

		case IRQ_OFFSET+IRQ_SERIAL:
			serial_intr();
f0103eba:	e8 19 c7 ff ff       	call   f01005d8 <serial_intr>
f0103ebf:	eb 43                	jmp    f0103f04 <trap+0x209>
	

	
		default:
		// Unexpected trap: The user process or the kernel has a bug.
			print_trapframe(tf);
f0103ec1:	83 ec 0c             	sub    $0xc,%esp
f0103ec4:	56                   	push   %esi
f0103ec5:	e8 9c fb ff ff       	call   f0103a66 <print_trapframe>
			if (tf->tf_cs == GD_KT){
f0103eca:	83 c4 10             	add    $0x10,%esp
f0103ecd:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103ed2:	75 17                	jne    f0103eeb <trap+0x1f0>
			panic("unhandled trap in kernel");
f0103ed4:	83 ec 04             	sub    $0x4,%esp
f0103ed7:	68 92 7e 10 f0       	push   $0xf0107e92
f0103edc:	68 02 01 00 00       	push   $0x102
f0103ee1:	68 2d 7e 10 f0       	push   $0xf0107e2d
f0103ee6:	e8 55 c1 ff ff       	call   f0100040 <_panic>
			}
		else {
			env_destroy(curenv);
f0103eeb:	e8 57 1b 00 00       	call   f0105a47 <cpunum>
f0103ef0:	83 ec 0c             	sub    $0xc,%esp
f0103ef3:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ef6:	ff b0 48 70 2a f0    	pushl  -0xfd58fb8(%eax)
f0103efc:	e8 6f f6 ff ff       	call   f0103570 <env_destroy>
f0103f01:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103f04:	e8 3e 1b 00 00       	call   f0105a47 <cpunum>
f0103f09:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f0c:	83 b8 48 70 2a f0 00 	cmpl   $0x0,-0xfd58fb8(%eax)
f0103f13:	74 2a                	je     f0103f3f <trap+0x244>
f0103f15:	e8 2d 1b 00 00       	call   f0105a47 <cpunum>
f0103f1a:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f1d:	8b 80 48 70 2a f0    	mov    -0xfd58fb8(%eax),%eax
f0103f23:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103f27:	75 16                	jne    f0103f3f <trap+0x244>
		env_run(curenv);
f0103f29:	e8 19 1b 00 00       	call   f0105a47 <cpunum>
f0103f2e:	83 ec 0c             	sub    $0xc,%esp
f0103f31:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f34:	ff b0 48 70 2a f0    	pushl  -0xfd58fb8(%eax)
f0103f3a:	e8 d0 f6 ff ff       	call   f010360f <env_run>
	else
		sched_yield();
f0103f3f:	e8 c0 02 00 00       	call   f0104204 <sched_yield>

f0103f44 <handler_0>:
#define T_DEFAULT   500		// catchall
*/

//TRAPHANDLER_NOEC for traps without error code
// From 0-7 no error code requred
	TRAPHANDLER_NOEC(handler_0, 0)   #Divide error
f0103f44:	6a 00                	push   $0x0
f0103f46:	6a 00                	push   $0x0
f0103f48:	e9 d2 01 00 00       	jmp    f010411f <_alltraps>
f0103f4d:	90                   	nop

f0103f4e <handler_1>:
	TRAPHANDLER_NOEC(handler_1, 1)   #Debug exceptions 
f0103f4e:	6a 00                	push   $0x0
f0103f50:	6a 01                	push   $0x1
f0103f52:	e9 c8 01 00 00       	jmp    f010411f <_alltraps>
f0103f57:	90                   	nop

f0103f58 <handler_2>:
 	TRAPHANDLER_NOEC(handler_2, 2)   //NMI Interrupt
f0103f58:	6a 00                	push   $0x0
f0103f5a:	6a 02                	push   $0x2
f0103f5c:	e9 be 01 00 00       	jmp    f010411f <_alltraps>
f0103f61:	90                   	nop

f0103f62 <handler_3>:
	TRAPHANDLER_NOEC(handler_3, 3)   //Breakpoint
f0103f62:	6a 00                	push   $0x0
f0103f64:	6a 03                	push   $0x3
f0103f66:	e9 b4 01 00 00       	jmp    f010411f <_alltraps>
f0103f6b:	90                   	nop

f0103f6c <handler_4>:
	TRAPHANDLER_NOEC(handler_4, 4)   //Overflow
f0103f6c:	6a 00                	push   $0x0
f0103f6e:	6a 04                	push   $0x4
f0103f70:	e9 aa 01 00 00       	jmp    f010411f <_alltraps>
f0103f75:	90                   	nop

f0103f76 <handler_5>:
	TRAPHANDLER_NOEC(handler_5, 5)   //Bounds check 
f0103f76:	6a 00                	push   $0x0
f0103f78:	6a 05                	push   $0x5
f0103f7a:	e9 a0 01 00 00       	jmp    f010411f <_alltraps>
f0103f7f:	90                   	nop

f0103f80 <handler_6>:
	TRAPHANDLER_NOEC(handler_6, 6)   //Invalid opcode
f0103f80:	6a 00                	push   $0x0
f0103f82:	6a 06                	push   $0x6
f0103f84:	e9 96 01 00 00       	jmp    f010411f <_alltraps>
f0103f89:	90                   	nop

f0103f8a <handler_7>:
	TRAPHANDLER_NOEC(handler_7, 7)   //Coprocessor not available
f0103f8a:	6a 00                	push   $0x0
f0103f8c:	6a 07                	push   $0x7
f0103f8e:	e9 8c 01 00 00       	jmp    f010411f <_alltraps>
f0103f93:	90                   	nop

f0103f94 <handler_8>:
	
	TRAPHANDLER(handler_8, 8)   // double fault
f0103f94:	6a 08                	push   $0x8
f0103f96:	e9 84 01 00 00       	jmp    f010411f <_alltraps>
f0103f9b:	90                   	nop

f0103f9c <handler_9>:
	
	TRAPHANDLER_NOEC(handler_9, 9)   //Coprocessor Segment Overrun
f0103f9c:	6a 00                	push   $0x0
f0103f9e:	6a 09                	push   $0x9
f0103fa0:	e9 7a 01 00 00       	jmp    f010411f <_alltraps>
f0103fa5:	90                   	nop

f0103fa6 <handler_10>:

	TRAPHANDLER(handler_10, 10)   // invalid task switch segment
f0103fa6:	6a 0a                	push   $0xa
f0103fa8:	e9 72 01 00 00       	jmp    f010411f <_alltraps>
f0103fad:	90                   	nop

f0103fae <handler_11>:
	TRAPHANDLER(handler_11, 11)   // segment not present
f0103fae:	6a 0b                	push   $0xb
f0103fb0:	e9 6a 01 00 00       	jmp    f010411f <_alltraps>
f0103fb5:	90                   	nop

f0103fb6 <handler_12>:
	TRAPHANDLER(handler_12, 12)   // stack exception
f0103fb6:	6a 0c                	push   $0xc
f0103fb8:	e9 62 01 00 00       	jmp    f010411f <_alltraps>
f0103fbd:	90                   	nop

f0103fbe <handler_13>:
	TRAPHANDLER(handler_13, 13)   // general protection fault
f0103fbe:	6a 0d                	push   $0xd
f0103fc0:	e9 5a 01 00 00       	jmp    f010411f <_alltraps>
f0103fc5:	90                   	nop

f0103fc6 <handler_14>:
	TRAPHANDLER(handler_14, 14)   // page fault
f0103fc6:	6a 0e                	push   $0xe
f0103fc8:	e9 52 01 00 00       	jmp    f010411f <_alltraps>
f0103fcd:	90                   	nop

f0103fce <handler_15>:

	TRAPHANDLER_NOEC(handler_15, 15)   // Reserved
f0103fce:	6a 00                	push   $0x0
f0103fd0:	6a 0f                	push   $0xf
f0103fd2:	e9 48 01 00 00       	jmp    f010411f <_alltraps>
f0103fd7:	90                   	nop

f0103fd8 <handler_16>:

	TRAPHANDLER_NOEC(handler_16, 16)   // floating point error
f0103fd8:	6a 00                	push   $0x0
f0103fda:	6a 10                	push   $0x10
f0103fdc:	e9 3e 01 00 00       	jmp    f010411f <_alltraps>
f0103fe1:	90                   	nop

f0103fe2 <handler_17>:

	TRAPHANDLER(handler_17, 17)   // aligment check
f0103fe2:	6a 11                	push   $0x11
f0103fe4:	e9 36 01 00 00       	jmp    f010411f <_alltraps>
f0103fe9:	90                   	nop

f0103fea <handler_18>:

	TRAPHANDLER_NOEC(handler_18, 18)   // machine check
f0103fea:	6a 00                	push   $0x0
f0103fec:	6a 12                	push   $0x12
f0103fee:	e9 2c 01 00 00       	jmp    f010411f <_alltraps>
f0103ff3:	90                   	nop

f0103ff4 <handler_19>:
	TRAPHANDLER_NOEC(handler_19, 19)   // SIMD floating point error
f0103ff4:	6a 00                	push   $0x0
f0103ff6:	6a 13                	push   $0x13
f0103ff8:	e9 22 01 00 00       	jmp    f010411f <_alltraps>
f0103ffd:	90                   	nop

f0103ffe <handler_20>:

	TRAPHANDLER_NOEC(handler_20, 20)
f0103ffe:	6a 00                	push   $0x0
f0104000:	6a 14                	push   $0x14
f0104002:	e9 18 01 00 00       	jmp    f010411f <_alltraps>
f0104007:	90                   	nop

f0104008 <handler_21>:
	TRAPHANDLER_NOEC(handler_21, 21)
f0104008:	6a 00                	push   $0x0
f010400a:	6a 15                	push   $0x15
f010400c:	e9 0e 01 00 00       	jmp    f010411f <_alltraps>
f0104011:	90                   	nop

f0104012 <handler_22>:
	TRAPHANDLER_NOEC(handler_22, 22)
f0104012:	6a 00                	push   $0x0
f0104014:	6a 16                	push   $0x16
f0104016:	e9 04 01 00 00       	jmp    f010411f <_alltraps>
f010401b:	90                   	nop

f010401c <handler_23>:
	TRAPHANDLER_NOEC(handler_23, 23)
f010401c:	6a 00                	push   $0x0
f010401e:	6a 17                	push   $0x17
f0104020:	e9 fa 00 00 00       	jmp    f010411f <_alltraps>
f0104025:	90                   	nop

f0104026 <handler_24>:
	TRAPHANDLER_NOEC(handler_24, 24)
f0104026:	6a 00                	push   $0x0
f0104028:	6a 18                	push   $0x18
f010402a:	e9 f0 00 00 00       	jmp    f010411f <_alltraps>
f010402f:	90                   	nop

f0104030 <handler_25>:
	TRAPHANDLER_NOEC(handler_25, 25)
f0104030:	6a 00                	push   $0x0
f0104032:	6a 19                	push   $0x19
f0104034:	e9 e6 00 00 00       	jmp    f010411f <_alltraps>
f0104039:	90                   	nop

f010403a <handler_26>:
	TRAPHANDLER_NOEC(handler_26, 26)
f010403a:	6a 00                	push   $0x0
f010403c:	6a 1a                	push   $0x1a
f010403e:	e9 dc 00 00 00       	jmp    f010411f <_alltraps>
f0104043:	90                   	nop

f0104044 <handler_27>:
	TRAPHANDLER_NOEC(handler_27, 27)
f0104044:	6a 00                	push   $0x0
f0104046:	6a 1b                	push   $0x1b
f0104048:	e9 d2 00 00 00       	jmp    f010411f <_alltraps>
f010404d:	90                   	nop

f010404e <handler_28>:
	TRAPHANDLER_NOEC(handler_28, 28)
f010404e:	6a 00                	push   $0x0
f0104050:	6a 1c                	push   $0x1c
f0104052:	e9 c8 00 00 00       	jmp    f010411f <_alltraps>
f0104057:	90                   	nop

f0104058 <handler_29>:
	TRAPHANDLER_NOEC(handler_29, 29)
f0104058:	6a 00                	push   $0x0
f010405a:	6a 1d                	push   $0x1d
f010405c:	e9 be 00 00 00       	jmp    f010411f <_alltraps>
f0104061:	90                   	nop

f0104062 <handler_30>:
	TRAPHANDLER_NOEC(handler_30, 30)
f0104062:	6a 00                	push   $0x0
f0104064:	6a 1e                	push   $0x1e
f0104066:	e9 b4 00 00 00       	jmp    f010411f <_alltraps>
f010406b:	90                   	nop

f010406c <handler_31>:
	TRAPHANDLER_NOEC(handler_31, 31)
f010406c:	6a 00                	push   $0x0
f010406e:	6a 1f                	push   $0x1f
f0104070:	e9 aa 00 00 00       	jmp    f010411f <_alltraps>
f0104075:	90                   	nop

f0104076 <handler_32>:
	TRAPHANDLER_NOEC(handler_32, 32)
f0104076:	6a 00                	push   $0x0
f0104078:	6a 20                	push   $0x20
f010407a:	e9 a0 00 00 00       	jmp    f010411f <_alltraps>
f010407f:	90                   	nop

f0104080 <handler_33>:
	TRAPHANDLER_NOEC(handler_33, 33)
f0104080:	6a 00                	push   $0x0
f0104082:	6a 21                	push   $0x21
f0104084:	e9 96 00 00 00       	jmp    f010411f <_alltraps>
f0104089:	90                   	nop

f010408a <handler_34>:
	TRAPHANDLER_NOEC(handler_34, 34)
f010408a:	6a 00                	push   $0x0
f010408c:	6a 22                	push   $0x22
f010408e:	e9 8c 00 00 00       	jmp    f010411f <_alltraps>
f0104093:	90                   	nop

f0104094 <handler_35>:
	TRAPHANDLER_NOEC(handler_35, 35)
f0104094:	6a 00                	push   $0x0
f0104096:	6a 23                	push   $0x23
f0104098:	e9 82 00 00 00       	jmp    f010411f <_alltraps>
f010409d:	90                   	nop

f010409e <handler_36>:
	TRAPHANDLER_NOEC(handler_36, 36)
f010409e:	6a 00                	push   $0x0
f01040a0:	6a 24                	push   $0x24
f01040a2:	e9 78 00 00 00       	jmp    f010411f <_alltraps>
f01040a7:	90                   	nop

f01040a8 <handler_37>:
	TRAPHANDLER_NOEC(handler_37, 37)
f01040a8:	6a 00                	push   $0x0
f01040aa:	6a 25                	push   $0x25
f01040ac:	e9 6e 00 00 00       	jmp    f010411f <_alltraps>
f01040b1:	90                   	nop

f01040b2 <handler_38>:
	TRAPHANDLER_NOEC(handler_38, 38)
f01040b2:	6a 00                	push   $0x0
f01040b4:	6a 26                	push   $0x26
f01040b6:	e9 64 00 00 00       	jmp    f010411f <_alltraps>
f01040bb:	90                   	nop

f01040bc <handler_39>:
	TRAPHANDLER_NOEC(handler_39, 39)
f01040bc:	6a 00                	push   $0x0
f01040be:	6a 27                	push   $0x27
f01040c0:	e9 5a 00 00 00       	jmp    f010411f <_alltraps>
f01040c5:	90                   	nop

f01040c6 <handler_40>:
	TRAPHANDLER_NOEC(handler_40, 40)
f01040c6:	6a 00                	push   $0x0
f01040c8:	6a 28                	push   $0x28
f01040ca:	e9 50 00 00 00       	jmp    f010411f <_alltraps>
f01040cf:	90                   	nop

f01040d0 <handler_41>:
	TRAPHANDLER_NOEC(handler_41, 41)
f01040d0:	6a 00                	push   $0x0
f01040d2:	6a 29                	push   $0x29
f01040d4:	e9 46 00 00 00       	jmp    f010411f <_alltraps>
f01040d9:	90                   	nop

f01040da <handler_42>:
	TRAPHANDLER_NOEC(handler_42, 42)
f01040da:	6a 00                	push   $0x0
f01040dc:	6a 2a                	push   $0x2a
f01040de:	e9 3c 00 00 00       	jmp    f010411f <_alltraps>
f01040e3:	90                   	nop

f01040e4 <handler_43>:
	TRAPHANDLER_NOEC(handler_43, 43)
f01040e4:	6a 00                	push   $0x0
f01040e6:	6a 2b                	push   $0x2b
f01040e8:	e9 32 00 00 00       	jmp    f010411f <_alltraps>
f01040ed:	90                   	nop

f01040ee <handler_44>:
	TRAPHANDLER_NOEC(handler_44, 44)
f01040ee:	6a 00                	push   $0x0
f01040f0:	6a 2c                	push   $0x2c
f01040f2:	e9 28 00 00 00       	jmp    f010411f <_alltraps>
f01040f7:	90                   	nop

f01040f8 <handler_45>:
	TRAPHANDLER_NOEC(handler_45, 45)
f01040f8:	6a 00                	push   $0x0
f01040fa:	6a 2d                	push   $0x2d
f01040fc:	e9 1e 00 00 00       	jmp    f010411f <_alltraps>
f0104101:	90                   	nop

f0104102 <handler_46>:
	TRAPHANDLER_NOEC(handler_46, 46)
f0104102:	6a 00                	push   $0x0
f0104104:	6a 2e                	push   $0x2e
f0104106:	e9 14 00 00 00       	jmp    f010411f <_alltraps>
f010410b:	90                   	nop

f010410c <handler_47>:
	TRAPHANDLER_NOEC(handler_47, 47)
f010410c:	6a 00                	push   $0x0
f010410e:	6a 2f                	push   $0x2f
f0104110:	e9 0a 00 00 00       	jmp    f010411f <_alltraps>
f0104115:	90                   	nop

f0104116 <handler_48>:

	TRAPHANDLER_NOEC(handler_48, 48)   // system call
f0104116:	6a 00                	push   $0x0
f0104118:	6a 30                	push   $0x30
f010411a:	e9 00 00 00 00       	jmp    f010411f <_alltraps>

f010411f <_alltraps>:
 */

.globl _alltraps
_alltraps:
	#Remaining Trap frame
	push %ds
f010411f:	1e                   	push   %ds
	push %es
f0104120:	06                   	push   %es
	pushal
f0104121:	60                   	pusha  

	
	movw $GD_KD, %ax
f0104122:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f0104126:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f0104128:	8e c0                	mov    %eax,%es

	#call Trap 
	pushl %esp
f010412a:	54                   	push   %esp
	call trap
f010412b:	e8 cb fb ff ff       	call   f0103cfb <trap>

f0104130 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0104130:	55                   	push   %ebp
f0104131:	89 e5                	mov    %esp,%ebp
f0104133:	83 ec 08             	sub    $0x8,%esp
f0104136:	a1 6c 62 2a f0       	mov    0xf02a626c,%eax
f010413b:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f010413e:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
f0104143:	8b 02                	mov    (%edx),%eax
f0104145:	83 e8 01             	sub    $0x1,%eax
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0104148:	83 f8 02             	cmp    $0x2,%eax
f010414b:	76 10                	jbe    f010415d <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f010414d:	83 c1 01             	add    $0x1,%ecx
f0104150:	83 c2 7c             	add    $0x7c,%edx
f0104153:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0104159:	75 e8                	jne    f0104143 <sched_halt+0x13>
f010415b:	eb 08                	jmp    f0104165 <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f010415d:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0104163:	75 1f                	jne    f0104184 <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f0104165:	83 ec 0c             	sub    $0xc,%esp
f0104168:	68 90 80 10 f0       	push   $0xf0108090
f010416d:	e8 d8 f6 ff ff       	call   f010384a <cprintf>
f0104172:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f0104175:	83 ec 0c             	sub    $0xc,%esp
f0104178:	6a 00                	push   $0x0
f010417a:	e8 a1 c7 ff ff       	call   f0100920 <monitor>
f010417f:	83 c4 10             	add    $0x10,%esp
f0104182:	eb f1                	jmp    f0104175 <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0104184:	e8 be 18 00 00       	call   f0105a47 <cpunum>
f0104189:	6b c0 74             	imul   $0x74,%eax,%eax
f010418c:	c7 80 48 70 2a f0 00 	movl   $0x0,-0xfd58fb8(%eax)
f0104193:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0104196:	a1 dc 6e 2a f0       	mov    0xf02a6edc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010419b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01041a0:	77 12                	ja     f01041b4 <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01041a2:	50                   	push   %eax
f01041a3:	68 08 69 10 f0       	push   $0xf0106908
f01041a8:	6a 54                	push   $0x54
f01041aa:	68 b9 80 10 f0       	push   $0xf01080b9
f01041af:	e8 8c be ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01041b4:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01041b9:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f01041bc:	e8 86 18 00 00       	call   f0105a47 <cpunum>
f01041c1:	6b d0 74             	imul   $0x74,%eax,%edx
f01041c4:	81 c2 40 70 2a f0    	add    $0xf02a7040,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f01041ca:	b8 02 00 00 00       	mov    $0x2,%eax
f01041cf:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01041d3:	83 ec 0c             	sub    $0xc,%esp
f01041d6:	68 c0 34 12 f0       	push   $0xf01234c0
f01041db:	e8 6f 1b 00 00       	call   f0105d4f <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01041e0:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f01041e2:	e8 60 18 00 00       	call   f0105a47 <cpunum>
f01041e7:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f01041ea:	8b 80 50 70 2a f0    	mov    -0xfd58fb0(%eax),%eax
f01041f0:	bd 00 00 00 00       	mov    $0x0,%ebp
f01041f5:	89 c4                	mov    %eax,%esp
f01041f7:	6a 00                	push   $0x0
f01041f9:	6a 00                	push   $0x0
f01041fb:	fb                   	sti    
f01041fc:	f4                   	hlt    
f01041fd:	eb fd                	jmp    f01041fc <sched_halt+0xcc>
f01041ff:	83 c4 10             	add    $0x10,%esp
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f0104202:	c9                   	leave  
f0104203:	c3                   	ret    

f0104204 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f0104204:	55                   	push   %ebp
f0104205:	89 e5                	mov    %esp,%ebp
f0104207:	53                   	push   %ebx
f0104208:	83 ec 04             	sub    $0x4,%esp
	// below to halt the cpu.

	// LAB 4: Your code here.
	int envVal, j = 0 ;
	 
	if (curenv)
f010420b:	e8 37 18 00 00       	call   f0105a47 <cpunum>
f0104210:	6b c0 74             	imul   $0x74,%eax,%eax
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
						     // we can use the value 'curenv- envs' to get the current env and +1 to get the next env
	else 
		envVal = 0; 
f0104213:	ba 00 00 00 00       	mov    $0x0,%edx
	// below to halt the cpu.

	// LAB 4: Your code here.
	int envVal, j = 0 ;
	 
	if (curenv)
f0104218:	83 b8 48 70 2a f0 00 	cmpl   $0x0,-0xfd58fb8(%eax)
f010421f:	74 33                	je     f0104254 <sched_yield+0x50>
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
f0104221:	e8 21 18 00 00       	call   f0105a47 <cpunum>
f0104226:	6b c0 74             	imul   $0x74,%eax,%eax
f0104229:	8b 80 48 70 2a f0    	mov    -0xfd58fb8(%eax),%eax
f010422f:	2b 05 6c 62 2a f0    	sub    0xf02a626c,%eax
f0104235:	c1 f8 02             	sar    $0x2,%eax
f0104238:	69 c0 df 7b ef bd    	imul   $0xbdef7bdf,%eax,%eax
f010423e:	83 c0 01             	add    $0x1,%eax
f0104241:	89 c1                	mov    %eax,%ecx
f0104243:	c1 f9 1f             	sar    $0x1f,%ecx
f0104246:	c1 e9 16             	shr    $0x16,%ecx
f0104249:	8d 14 08             	lea    (%eax,%ecx,1),%edx
f010424c:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0104252:	29 ca                	sub    %ecx,%edx
	else 
		envVal = 0; 
	
	for (j = 0; j< NENV; j++)
	{
		if (envs[envVal].env_status == ENV_RUNNABLE)
f0104254:	a1 6c 62 2a f0       	mov    0xf02a626c,%eax
f0104259:	b9 00 04 00 00       	mov    $0x400,%ecx
f010425e:	6b da 7c             	imul   $0x7c,%edx,%ebx
f0104261:	83 7c 18 54 02       	cmpl   $0x2,0x54(%eax,%ebx,1)
f0104266:	74 70                	je     f01042d8 <sched_yield+0xd4>
		    break;
		else
		    envVal=(envVal+1)%NENV;
f0104268:	83 c2 01             	add    $0x1,%edx
f010426b:	89 d3                	mov    %edx,%ebx
f010426d:	c1 fb 1f             	sar    $0x1f,%ebx
f0104270:	c1 eb 16             	shr    $0x16,%ebx
f0104273:	01 da                	add    %ebx,%edx
f0104275:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010427b:	29 da                	sub    %ebx,%edx
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
						     // we can use the value 'curenv- envs' to get the current env and +1 to get the next env
	else 
		envVal = 0; 
	
	for (j = 0; j< NENV; j++)
f010427d:	83 e9 01             	sub    $0x1,%ecx
f0104280:	75 dc                	jne    f010425e <sched_yield+0x5a>
		    break;
		else
		    envVal=(envVal+1)%NENV;
	}
	
	if (envs[envVal].env_status == ENV_RUNNABLE)
f0104282:	6b d2 7c             	imul   $0x7c,%edx,%edx
f0104285:	01 c2                	add    %eax,%edx
f0104287:	83 7a 54 02          	cmpl   $0x2,0x54(%edx)
f010428b:	75 09                	jne    f0104296 <sched_yield+0x92>
	{
	    idle = envs + envVal ;
	    env_run(idle);
f010428d:	83 ec 0c             	sub    $0xc,%esp
f0104290:	52                   	push   %edx
f0104291:	e8 79 f3 ff ff       	call   f010360f <env_run>
	} 
	else if (!idle && (curenv) && (curenv->env_status == ENV_RUNNING) ){
f0104296:	e8 ac 17 00 00       	call   f0105a47 <cpunum>
f010429b:	6b c0 74             	imul   $0x74,%eax,%eax
f010429e:	83 b8 48 70 2a f0 00 	cmpl   $0x0,-0xfd58fb8(%eax)
f01042a5:	74 2a                	je     f01042d1 <sched_yield+0xcd>
f01042a7:	e8 9b 17 00 00       	call   f0105a47 <cpunum>
f01042ac:	6b c0 74             	imul   $0x74,%eax,%eax
f01042af:	8b 80 48 70 2a f0    	mov    -0xfd58fb8(%eax),%eax
f01042b5:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01042b9:	75 16                	jne    f01042d1 <sched_yield+0xcd>
	    env_run(curenv) ;
f01042bb:	e8 87 17 00 00       	call   f0105a47 <cpunum>
f01042c0:	83 ec 0c             	sub    $0xc,%esp
f01042c3:	6b c0 74             	imul   $0x74,%eax,%eax
f01042c6:	ff b0 48 70 2a f0    	pushl  -0xfd58fb8(%eax)
f01042cc:	e8 3e f3 ff ff       	call   f010360f <env_run>
	}
	// sched_halt never returns
	sched_halt();
f01042d1:	e8 5a fe ff ff       	call   f0104130 <sched_halt>
f01042d6:	eb 07                	jmp    f01042df <sched_yield+0xdb>
		    break;
		else
		    envVal=(envVal+1)%NENV;
	}
	
	if (envs[envVal].env_status == ENV_RUNNABLE)
f01042d8:	6b d2 7c             	imul   $0x7c,%edx,%edx
f01042db:	01 c2                	add    %eax,%edx
f01042dd:	eb ae                	jmp    f010428d <sched_yield+0x89>
	else if (!idle && (curenv) && (curenv->env_status == ENV_RUNNING) ){
	    env_run(curenv) ;
	}
	// sched_halt never returns
	sched_halt();
}
f01042df:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01042e2:	c9                   	leave  
f01042e3:	c3                   	ret    

f01042e4 <syscall>:


// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01042e4:	55                   	push   %ebp
f01042e5:	89 e5                	mov    %esp,%ebp
f01042e7:	57                   	push   %edi
f01042e8:	56                   	push   %esi
f01042e9:	53                   	push   %ebx
f01042ea:	83 ec 1c             	sub    $0x1c,%esp
f01042ed:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	

	switch (syscallno) {
f01042f0:	83 f8 0f             	cmp    $0xf,%eax
f01042f3:	0f 87 66 05 00 00    	ja     f010485f <syscall+0x57b>
f01042f9:	ff 24 85 34 81 10 f0 	jmp    *-0xfef7ecc(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_P | PTE_U);
f0104300:	e8 42 17 00 00       	call   f0105a47 <cpunum>
f0104305:	6a 05                	push   $0x5
f0104307:	ff 75 10             	pushl  0x10(%ebp)
f010430a:	ff 75 0c             	pushl  0xc(%ebp)
f010430d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104310:	ff b0 48 70 2a f0    	pushl  -0xfd58fb8(%eax)
f0104316:	e8 24 ec ff ff       	call   f0102f3f <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f010431b:	83 c4 0c             	add    $0xc,%esp
f010431e:	ff 75 0c             	pushl  0xc(%ebp)
f0104321:	ff 75 10             	pushl  0x10(%ebp)
f0104324:	68 c6 80 10 f0       	push   $0xf01080c6
f0104329:	e8 1c f5 ff ff       	call   f010384a <cprintf>
f010432e:	83 c4 10             	add    $0x10,%esp

	switch (syscallno) {

	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;
f0104331:	b8 00 00 00 00       	mov    $0x0,%eax
f0104336:	e9 47 05 00 00       	jmp    f0104882 <syscall+0x59e>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f010433b:	e8 c6 c2 ff ff       	call   f0100606 <cons_getc>
	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;

	case SYS_cgetc:
		return sys_cgetc();
f0104340:	e9 3d 05 00 00       	jmp    f0104882 <syscall+0x59e>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0104345:	e8 fd 16 00 00       	call   f0105a47 <cpunum>
f010434a:	6b c0 74             	imul   $0x74,%eax,%eax
f010434d:	8b 80 48 70 2a f0    	mov    -0xfd58fb8(%eax),%eax
f0104353:	8b 40 48             	mov    0x48(%eax),%eax

	case SYS_cgetc:
		return sys_cgetc();
		
	case SYS_getenvid:
		return sys_getenvid();
f0104356:	e9 27 05 00 00       	jmp    f0104882 <syscall+0x59e>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f010435b:	83 ec 04             	sub    $0x4,%esp
f010435e:	6a 01                	push   $0x1
f0104360:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104363:	50                   	push   %eax
f0104364:	ff 75 0c             	pushl  0xc(%ebp)
f0104367:	e8 a3 ec ff ff       	call   f010300f <envid2env>
f010436c:	89 c2                	mov    %eax,%edx
f010436e:	83 c4 10             	add    $0x10,%esp
f0104371:	85 d2                	test   %edx,%edx
f0104373:	0f 88 09 05 00 00    	js     f0104882 <syscall+0x59e>
		return r;
	env_destroy(e);
f0104379:	83 ec 0c             	sub    $0xc,%esp
f010437c:	ff 75 e4             	pushl  -0x1c(%ebp)
f010437f:	e8 ec f1 ff ff       	call   f0103570 <env_destroy>
f0104384:	83 c4 10             	add    $0x10,%esp
	return 0;
f0104387:	b8 00 00 00 00       	mov    $0x0,%eax
f010438c:	e9 f1 04 00 00       	jmp    f0104882 <syscall+0x59e>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f0104391:	e8 6e fe ff ff       	call   f0104204 <sched_yield>
	// from the current environment -- but tweaked so sys_exofork
	// will appear to return 0.

	// LAB 4: Your code here.
	struct Env* childenv;
	int errcode = env_alloc(&childenv, curenv->env_id);
f0104396:	e8 ac 16 00 00       	call   f0105a47 <cpunum>
f010439b:	83 ec 08             	sub    $0x8,%esp
f010439e:	6b c0 74             	imul   $0x74,%eax,%eax
f01043a1:	8b 80 48 70 2a f0    	mov    -0xfd58fb8(%eax),%eax
f01043a7:	ff 70 48             	pushl  0x48(%eax)
f01043aa:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01043ad:	50                   	push   %eax
f01043ae:	e8 67 ed ff ff       	call   f010311a <env_alloc>
f01043b3:	89 c2                	mov    %eax,%edx
	
	//If the error code is less than 0, that means there has been an error while creating an env	
	if (errcode < 0) {
f01043b5:	83 c4 10             	add    $0x10,%esp
f01043b8:	85 d2                	test   %edx,%edx
f01043ba:	0f 88 c2 04 00 00    	js     f0104882 <syscall+0x59e>
		return errcode; //Return the environment
	}
	
	//Set the child environment as not runnable	
	childenv->env_status = ENV_NOT_RUNNABLE;
f01043c0:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01043c3:	c7 43 54 04 00 00 00 	movl   $0x4,0x54(%ebx)

	//Copy the current environemnt register data into the child
	childenv->env_tf = curenv->env_tf;
f01043ca:	e8 78 16 00 00       	call   f0105a47 <cpunum>
f01043cf:	6b c0 74             	imul   $0x74,%eax,%eax
f01043d2:	8b b0 48 70 2a f0    	mov    -0xfd58fb8(%eax),%esi
f01043d8:	b9 11 00 00 00       	mov    $0x11,%ecx
f01043dd:	89 df                	mov    %ebx,%edi
f01043df:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

	// when the child is scheduled to run, it has to restart the trapframe. 
	//Hence we modify the register eax to be 0. 

	childenv->env_tf.tf_regs.reg_eax = 0; 
f01043e1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01043e4:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

	return childenv->env_id;
f01043eb:	8b 40 48             	mov    0x48(%eax),%eax
f01043ee:	e9 8f 04 00 00       	jmp    f0104882 <syscall+0x59e>

	// LAB 4: Your code here.
	
	struct Env *env_store;
	int errcode; 
	errcode = envid2env(envid, &env_store,1);
f01043f3:	83 ec 04             	sub    $0x4,%esp
f01043f6:	6a 01                	push   $0x1
f01043f8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01043fb:	50                   	push   %eax
f01043fc:	ff 75 0c             	pushl  0xc(%ebp)
f01043ff:	e8 0b ec ff ff       	call   f010300f <envid2env>
	if (errcode < 0)
f0104404:	83 c4 10             	add    $0x10,%esp
f0104407:	85 c0                	test   %eax,%eax
f0104409:	0f 88 73 04 00 00    	js     f0104882 <syscall+0x59e>
		return errcode;
	
	//Check if status is runnable or not runnable
	if (status == ENV_RUNNABLE || status == ENV_NOT_RUNNABLE)
f010440f:	8b 45 10             	mov    0x10(%ebp),%eax
f0104412:	8d 50 fe             	lea    -0x2(%eax),%edx
		env_store->env_status = status;

	else
		return E_INVAL;
f0104415:	b8 03 00 00 00       	mov    $0x3,%eax
	errcode = envid2env(envid, &env_store,1);
	if (errcode < 0)
		return errcode;
	
	//Check if status is runnable or not runnable
	if (status == ENV_RUNNABLE || status == ENV_NOT_RUNNABLE)
f010441a:	f7 c2 fd ff ff ff    	test   $0xfffffffd,%edx
f0104420:	0f 85 5c 04 00 00    	jne    f0104882 <syscall+0x59e>
		env_store->env_status = status;
f0104426:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104429:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010442c:	89 58 54             	mov    %ebx,0x54(%eax)

	else
		return E_INVAL;

	return 0;
f010442f:	b8 00 00 00 00       	mov    $0x0,%eax
f0104434:	e9 49 04 00 00       	jmp    f0104882 <syscall+0x59e>
	struct Env *en; 
	int code;
	
	//Check for valid address and page alignment
	if((((uint32_t)va) >= UTOP) || (((uint32_t)va) % PGSIZE) !=0)
		return  E_INVAL;
f0104439:	b8 03 00 00 00       	mov    $0x3,%eax
	
	struct Env *en; 
	int code;
	
	//Check for valid address and page alignment
	if((((uint32_t)va) >= UTOP) || (((uint32_t)va) % PGSIZE) !=0)
f010443e:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104445:	0f 87 37 04 00 00    	ja     f0104882 <syscall+0x59e>
f010444b:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104452:	0f 85 2a 04 00 00    	jne    f0104882 <syscall+0x59e>
		return  E_INVAL;

	//Check for permissions
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
f0104458:	f7 45 14 fd f1 ff ff 	testl  $0xfffff1fd,0x14(%ebp)
f010445f:	0f 84 1d 04 00 00    	je     f0104882 <syscall+0x59e>
		return E_INVAL;

	//Page allocation check
	struct PageInfo *newpage = page_alloc(ALLOC_ZERO); 
f0104465:	83 ec 0c             	sub    $0xc,%esp
f0104468:	6a 01                	push   $0x1
f010446a:	e8 75 cb ff ff       	call   f0100fe4 <page_alloc>
f010446f:	89 c3                	mov    %eax,%ebx
	if (!newpage)
f0104471:	83 c4 10             	add    $0x10,%esp
		return E_NO_MEM; 
f0104474:	b8 04 00 00 00       	mov    $0x4,%eax
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
		return E_INVAL;

	//Page allocation check
	struct PageInfo *newpage = page_alloc(ALLOC_ZERO); 
	if (!newpage)
f0104479:	85 db                	test   %ebx,%ebx
f010447b:	0f 84 01 04 00 00    	je     f0104882 <syscall+0x59e>
		return E_NO_MEM; 

	//Use environid to get the environment 
	if ((code = envid2env(envid, &en,1))<0)
f0104481:	83 ec 04             	sub    $0x4,%esp
f0104484:	6a 01                	push   $0x1
f0104486:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104489:	50                   	push   %eax
f010448a:	ff 75 0c             	pushl  0xc(%ebp)
f010448d:	e8 7d eb ff ff       	call   f010300f <envid2env>
f0104492:	83 c4 10             	add    $0x10,%esp
f0104495:	85 c0                	test   %eax,%eax
f0104497:	0f 88 e5 03 00 00    	js     f0104882 <syscall+0x59e>
		return code;

	//Check if the page mapping is correct otherwise free the page
	code=page_insert(en->env_pgdir,newpage,(void *)va,perm);
f010449d:	ff 75 14             	pushl  0x14(%ebp)
f01044a0:	ff 75 10             	pushl  0x10(%ebp)
f01044a3:	53                   	push   %ebx
f01044a4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01044a7:	ff 70 60             	pushl  0x60(%eax)
f01044aa:	e8 5b ce ff ff       	call   f010130a <page_insert>
f01044af:	89 c6                	mov    %eax,%esi
	if (code < 0)
f01044b1:	83 c4 10             	add    $0x10,%esp
	{
		page_free(newpage);
		return code;
	}
	
	return 0;
f01044b4:	b8 00 00 00 00       	mov    $0x0,%eax
	if ((code = envid2env(envid, &en,1))<0)
		return code;

	//Check if the page mapping is correct otherwise free the page
	code=page_insert(en->env_pgdir,newpage,(void *)va,perm);
	if (code < 0)
f01044b9:	85 f6                	test   %esi,%esi
f01044bb:	0f 89 c1 03 00 00    	jns    f0104882 <syscall+0x59e>
	{
		page_free(newpage);
f01044c1:	83 ec 0c             	sub    $0xc,%esp
f01044c4:	53                   	push   %ebx
f01044c5:	e8 90 cb ff ff       	call   f010105a <page_free>
f01044ca:	83 c4 10             	add    $0x10,%esp
		return code;
f01044cd:	89 f0                	mov    %esi,%eax
f01044cf:	e9 ae 03 00 00       	jmp    f0104882 <syscall+0x59e>
	struct Env* src_env;
	struct Env* dst_env;
	int errcode;
	
	//Check for valid src env id
	errcode = envid2env(srcenvid, &src_env, 1);
f01044d4:	83 ec 04             	sub    $0x4,%esp
f01044d7:	6a 01                	push   $0x1
f01044d9:	8d 45 dc             	lea    -0x24(%ebp),%eax
f01044dc:	50                   	push   %eax
f01044dd:	ff 75 0c             	pushl  0xc(%ebp)
f01044e0:	e8 2a eb ff ff       	call   f010300f <envid2env>
f01044e5:	89 c2                	mov    %eax,%edx
	if (errcode < 0) 
f01044e7:	83 c4 10             	add    $0x10,%esp
f01044ea:	85 d2                	test   %edx,%edx
f01044ec:	0f 88 90 03 00 00    	js     f0104882 <syscall+0x59e>
		return errcode;
	
	//Check for valid des env id
	errcode = envid2env(dstenvid, &dst_env, 1);
f01044f2:	83 ec 04             	sub    $0x4,%esp
f01044f5:	6a 01                	push   $0x1
f01044f7:	8d 45 e0             	lea    -0x20(%ebp),%eax
f01044fa:	50                   	push   %eax
f01044fb:	ff 75 14             	pushl  0x14(%ebp)
f01044fe:	e8 0c eb ff ff       	call   f010300f <envid2env>
	if (errcode < 0) 
f0104503:	83 c4 10             	add    $0x10,%esp
f0104506:	85 c0                	test   %eax,%eax
f0104508:	0f 88 74 03 00 00    	js     f0104882 <syscall+0x59e>
		return errcode;
	
	//Check if the address is below UTOP
	if (((uint32_t)srcva) >= UTOP || ((uint32_t)dstva) >= UTOP) 
f010450e:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104515:	77 6d                	ja     f0104584 <syscall+0x2a0>
f0104517:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f010451e:	77 64                	ja     f0104584 <syscall+0x2a0>
f0104520:	8b 45 10             	mov    0x10(%ebp),%eax
f0104523:	0b 45 18             	or     0x18(%ebp),%eax
		return -E_INVAL;
	
	//Checking if the address is page aligned
	if ((((uint32_t)srcva)%PGSIZE != 0) || (((uint32_t)dstva)%PGSIZE != 0)) 
f0104526:	a9 ff 0f 00 00       	test   $0xfff,%eax
f010452b:	75 61                	jne    f010458e <syscall+0x2aa>
		return -E_INVAL;

	// find the page corresponding to srcva in src_e
	pte_t* pte_src;

	struct PageInfo* srcPage = page_lookup(src_env->env_pgdir, srcva, &pte_src);
f010452d:	83 ec 04             	sub    $0x4,%esp
f0104530:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104533:	50                   	push   %eax
f0104534:	ff 75 10             	pushl  0x10(%ebp)
f0104537:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010453a:	ff 70 60             	pushl  0x60(%eax)
f010453d:	e8 02 cd ff ff       	call   f0101244 <page_lookup>
	if (!srcPage) 
f0104542:	83 c4 10             	add    $0x10,%esp
f0104545:	85 c0                	test   %eax,%eax
f0104547:	74 4f                	je     f0104598 <syscall+0x2b4>
		return -E_INVAL;
	

	//Check for permissions
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
f0104549:	f7 45 1c fd f1 ff ff 	testl  $0xfffff1fd,0x1c(%ebp)
f0104550:	74 50                	je     f01045a2 <syscall+0x2be>
		return -E_INVAL; 	
	

	// the page is not writable but write permission is set	
	if (!(*pte_src & PTE_W) && (perm & PTE_W)) {
f0104552:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104555:	f6 02 02             	testb  $0x2,(%edx)
f0104558:	75 06                	jne    f0104560 <syscall+0x27c>
f010455a:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f010455e:	75 4c                	jne    f01045ac <syscall+0x2c8>
		return -E_INVAL;
	}

	// mapping
	errcode = page_insert(dst_env->env_pgdir, srcPage, dstva, perm);
f0104560:	ff 75 1c             	pushl  0x1c(%ebp)
f0104563:	ff 75 18             	pushl  0x18(%ebp)
f0104566:	50                   	push   %eax
f0104567:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010456a:	ff 70 60             	pushl  0x60(%eax)
f010456d:	e8 98 cd ff ff       	call   f010130a <page_insert>
f0104572:	83 c4 10             	add    $0x10,%esp
f0104575:	85 c0                	test   %eax,%eax
f0104577:	ba 00 00 00 00       	mov    $0x0,%edx
f010457c:	0f 4f c2             	cmovg  %edx,%eax
f010457f:	e9 fe 02 00 00       	jmp    f0104882 <syscall+0x59e>
	if (errcode < 0) 
		return errcode;
	
	//Check if the address is below UTOP
	if (((uint32_t)srcva) >= UTOP || ((uint32_t)dstva) >= UTOP) 
		return -E_INVAL;
f0104584:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104589:	e9 f4 02 00 00       	jmp    f0104882 <syscall+0x59e>
	
	//Checking if the address is page aligned
	if ((((uint32_t)srcva)%PGSIZE != 0) || (((uint32_t)dstva)%PGSIZE != 0)) 
		return -E_INVAL;
f010458e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104593:	e9 ea 02 00 00       	jmp    f0104882 <syscall+0x59e>
	// find the page corresponding to srcva in src_e
	pte_t* pte_src;

	struct PageInfo* srcPage = page_lookup(src_env->env_pgdir, srcva, &pte_src);
	if (!srcPage) 
		return -E_INVAL;
f0104598:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010459d:	e9 e0 02 00 00       	jmp    f0104882 <syscall+0x59e>
	

	//Check for permissions
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
		return -E_INVAL; 	
f01045a2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01045a7:	e9 d6 02 00 00       	jmp    f0104882 <syscall+0x59e>
	

	// the page is not writable but write permission is set	
	if (!(*pte_src & PTE_W) && (perm & PTE_W)) {
		return -E_INVAL;
f01045ac:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	case SYS_page_alloc:
		return sys_page_alloc( (envid_t)a1, (void *)a2, (int)a3);
	
	case SYS_page_map:
		return sys_page_map( (envid_t)a1, (void *)a2,
f01045b1:	e9 cc 02 00 00       	jmp    f0104882 <syscall+0x59e>
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	struct Env* en;
	//Check for valid envid
	int errcode = envid2env(envid, &en, 1);
f01045b6:	83 ec 04             	sub    $0x4,%esp
f01045b9:	6a 01                	push   $0x1
f01045bb:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01045be:	50                   	push   %eax
f01045bf:	ff 75 0c             	pushl  0xc(%ebp)
f01045c2:	e8 48 ea ff ff       	call   f010300f <envid2env>
	if (errcode < 0){ 
f01045c7:	83 c4 10             	add    $0x10,%esp
f01045ca:	85 c0                	test   %eax,%eax
f01045cc:	0f 88 b0 02 00 00    	js     f0104882 <syscall+0x59e>
		return errcode;
	}
	
	//Checkfor valid address and page alignment
	if ((((uint32_t)va) >= UTOP) ||(((uint32_t)va)%PGSIZE != 0 ) ) {
f01045d2:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f01045d9:	77 27                	ja     f0104602 <syscall+0x31e>
f01045db:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f01045e2:	75 28                	jne    f010460c <syscall+0x328>
		return -E_INVAL;
	}

	page_remove(en->env_pgdir, va);
f01045e4:	83 ec 08             	sub    $0x8,%esp
f01045e7:	ff 75 10             	pushl  0x10(%ebp)
f01045ea:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01045ed:	ff 70 60             	pushl  0x60(%eax)
f01045f0:	e8 cf cc ff ff       	call   f01012c4 <page_remove>
f01045f5:	83 c4 10             	add    $0x10,%esp

	return 0;
f01045f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01045fd:	e9 80 02 00 00       	jmp    f0104882 <syscall+0x59e>
		return errcode;
	}
	
	//Checkfor valid address and page alignment
	if ((((uint32_t)va) >= UTOP) ||(((uint32_t)va)%PGSIZE != 0 ) ) {
		return -E_INVAL;
f0104602:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104607:	e9 76 02 00 00       	jmp    f0104882 <syscall+0x59e>
f010460c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	case SYS_page_map:
		return sys_page_map( (envid_t)a1, (void *)a2,
	     (envid_t) a3, (void *)a4, (int )a5);

	case SYS_page_unmap:
		return sys_page_unmap((envid_t)a1, (void *)a2);	
f0104611:	e9 6c 02 00 00       	jmp    f0104882 <syscall+0x59e>
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here. //Exercise 8 code
	struct Env* en;
	int errcode = envid2env(envid, &en, 1);
f0104616:	83 ec 04             	sub    $0x4,%esp
f0104619:	6a 01                	push   $0x1
f010461b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010461e:	50                   	push   %eax
f010461f:	ff 75 0c             	pushl  0xc(%ebp)
f0104622:	e8 e8 e9 ff ff       	call   f010300f <envid2env>
	if (errcode < 0) {
f0104627:	83 c4 10             	add    $0x10,%esp
f010462a:	85 c0                	test   %eax,%eax
f010462c:	0f 88 50 02 00 00    	js     f0104882 <syscall+0x59e>
		return errcode;
	}

	//Set the pgfault_upcall to func
	en->env_pgfault_upcall = func;
f0104632:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104635:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104638:	89 78 64             	mov    %edi,0x64(%eax)
	return 0;
f010463b:	b8 00 00 00 00       	mov    $0x0,%eax
f0104640:	e9 3d 02 00 00       	jmp    f0104882 <syscall+0x59e>
	// LAB 4: Your code here.
	int r; 
	struct Env* target_env; 
	
	//Bad Environment
	if ((r = envid2env(envid, &target_env, 0)) < 0)
f0104645:	83 ec 04             	sub    $0x4,%esp
f0104648:	6a 00                	push   $0x0
f010464a:	8d 45 e0             	lea    -0x20(%ebp),%eax
f010464d:	50                   	push   %eax
f010464e:	ff 75 0c             	pushl  0xc(%ebp)
f0104651:	e8 b9 e9 ff ff       	call   f010300f <envid2env>
f0104656:	83 c4 10             	add    $0x10,%esp
f0104659:	85 c0                	test   %eax,%eax
f010465b:	0f 88 0d 01 00 00    	js     f010476e <syscall+0x48a>
		return -E_BAD_ENV; 
	
	//If target is not receiving
	if(!target_env->env_ipc_recving)
f0104661:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104664:	80 78 68 00          	cmpb   $0x0,0x68(%eax)
f0104668:	0f 84 0a 01 00 00    	je     f0104778 <syscall+0x494>
		return -E_IPC_NOT_RECV;
	
	//If src and dst addesses are below UTOP
	if (((uint32_t)srcva) < UTOP && (uint32_t)target_env->env_ipc_dstva < UTOP)
f010466e:	81 7d 14 ff ff bf ee 	cmpl   $0xeebfffff,0x14(%ebp)
f0104675:	0f 87 b0 00 00 00    	ja     f010472b <syscall+0x447>
f010467b:	81 78 6c ff ff bf ee 	cmpl   $0xeebfffff,0x6c(%eax)
f0104682:	0f 87 a3 00 00 00    	ja     f010472b <syscall+0x447>
	{
		
		//Check if srcva is page aligned
		if ((uint32_t)srcva % PGSIZE !=0)
			return -E_INVAL;
f0104688:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	//If src and dst addesses are below UTOP
	if (((uint32_t)srcva) < UTOP && (uint32_t)target_env->env_ipc_dstva < UTOP)
	{
		
		//Check if srcva is page aligned
		if ((uint32_t)srcva % PGSIZE !=0)
f010468d:	f7 45 14 ff 0f 00 00 	testl  $0xfff,0x14(%ebp)
f0104694:	0f 85 e8 01 00 00    	jne    f0104882 <syscall+0x59e>
			return -E_INVAL;
	
		//Check for permissions
		if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
f010469a:	f7 45 18 fd f1 ff ff 	testl  $0xfffff1fd,0x18(%ebp)
f01046a1:	0f 84 db 01 00 00    	je     f0104882 <syscall+0x59e>
			return -E_INVAL;

		struct PageInfo* srcpage = NULL;

		pte_t* pte = NULL;
f01046a7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		//Lookup the page and get a pte
		if (!(srcpage = page_lookup(curenv->env_pgdir, srcva,&pte)))
f01046ae:	e8 94 13 00 00       	call   f0105a47 <cpunum>
f01046b3:	83 ec 04             	sub    $0x4,%esp
f01046b6:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01046b9:	52                   	push   %edx
f01046ba:	ff 75 14             	pushl  0x14(%ebp)
f01046bd:	6b c0 74             	imul   $0x74,%eax,%eax
f01046c0:	8b 80 48 70 2a f0    	mov    -0xfd58fb8(%eax),%eax
f01046c6:	ff 70 60             	pushl  0x60(%eax)
f01046c9:	e8 76 cb ff ff       	call   f0101244 <page_lookup>
f01046ce:	89 c2                	mov    %eax,%edx
f01046d0:	83 c4 10             	add    $0x10,%esp
f01046d3:	85 c0                	test   %eax,%eax
f01046d5:	74 40                	je     f0104717 <syscall+0x433>
			return -E_INVAL;
		
		//if (perm & PTE_W), but srcva is read-only in the
		//current environment's address space.
		if ((perm & PTE_W) && !(*pte & PTE_W))
f01046d7:	f6 45 18 02          	testb  $0x2,0x18(%ebp)
f01046db:	74 11                	je     f01046ee <syscall+0x40a>
			return -E_INVAL; 
f01046dd:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		if (!(srcpage = page_lookup(curenv->env_pgdir, srcva,&pte)))
			return -E_INVAL;
		
		//if (perm & PTE_W), but srcva is read-only in the
		//current environment's address space.
		if ((perm & PTE_W) && !(*pte & PTE_W))
f01046e2:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01046e5:	f6 01 02             	testb  $0x2,(%ecx)
f01046e8:	0f 84 94 01 00 00    	je     f0104882 <syscall+0x59e>
			return -E_INVAL; 
		
		//Page mappingto destination
		if (target_env->env_ipc_dstva)
f01046ee:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01046f1:	8b 48 6c             	mov    0x6c(%eax),%ecx
f01046f4:	85 c9                	test   %ecx,%ecx
f01046f6:	74 14                	je     f010470c <syscall+0x428>
		{
			//map the page
			if ((r = page_insert(target_env->env_pgdir, srcpage, (void *)target_env->env_ipc_dstva,perm) )< 0)
f01046f8:	ff 75 18             	pushl  0x18(%ebp)
f01046fb:	51                   	push   %ecx
f01046fc:	52                   	push   %edx
f01046fd:	ff 70 60             	pushl  0x60(%eax)
f0104700:	e8 05 cc ff ff       	call   f010130a <page_insert>
f0104705:	83 c4 10             	add    $0x10,%esp
f0104708:	85 c0                	test   %eax,%eax
f010470a:	78 15                	js     f0104721 <syscall+0x43d>
				return -E_NO_MEM;
			
		}
		
		target_env->env_ipc_perm = perm; // is set to 'perm' if a page was transferred, 0 otherwise. 
f010470c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010470f:	8b 5d 18             	mov    0x18(%ebp),%ebx
f0104712:	89 58 78             	mov    %ebx,0x78(%eax)
f0104715:	eb 1b                	jmp    f0104732 <syscall+0x44e>
		struct PageInfo* srcpage = NULL;

		pte_t* pte = NULL;
		//Lookup the page and get a pte
		if (!(srcpage = page_lookup(curenv->env_pgdir, srcva,&pte)))
			return -E_INVAL;
f0104717:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010471c:	e9 61 01 00 00       	jmp    f0104882 <syscall+0x59e>
		//Page mappingto destination
		if (target_env->env_ipc_dstva)
		{
			//map the page
			if ((r = page_insert(target_env->env_pgdir, srcpage, (void *)target_env->env_ipc_dstva,perm) )< 0)
				return -E_NO_MEM;
f0104721:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0104726:	e9 57 01 00 00       	jmp    f0104882 <syscall+0x59e>
		}
		
		target_env->env_ipc_perm = perm; // is set to 'perm' if a page was transferred, 0 otherwise. 
	}
	else{
		target_env->env_ipc_perm = 0; //  0 otherwise. 
f010472b:	c7 40 78 00 00 00 00 	movl   $0x0,0x78(%eax)
	}
	
	target_env->env_ipc_recving  = 0; //is set to 0 to block future sends
f0104732:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104735:	c6 43 68 00          	movb   $0x0,0x68(%ebx)
	target_env->env_ipc_from = curenv->env_id; // is set to the sending envid;
f0104739:	e8 09 13 00 00       	call   f0105a47 <cpunum>
f010473e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104741:	8b 80 48 70 2a f0    	mov    -0xfd58fb8(%eax),%eax
f0104747:	8b 40 48             	mov    0x48(%eax),%eax
f010474a:	89 43 74             	mov    %eax,0x74(%ebx)
	target_env->env_tf.tf_regs.reg_eax = 0;
f010474d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104750:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	target_env->env_ipc_value = value; // is set to the 'value' parameter;
f0104757:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010475a:	89 48 70             	mov    %ecx,0x70(%eax)
	target_env->env_status = ENV_RUNNABLE; 
f010475d:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	
	return 0;
f0104764:	b8 00 00 00 00       	mov    $0x0,%eax
f0104769:	e9 14 01 00 00       	jmp    f0104882 <syscall+0x59e>
	int r; 
	struct Env* target_env; 
	
	//Bad Environment
	if ((r = envid2env(envid, &target_env, 0)) < 0)
		return -E_BAD_ENV; 
f010476e:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0104773:	e9 0a 01 00 00       	jmp    f0104882 <syscall+0x59e>
	
	//If target is not receiving
	if(!target_env->env_ipc_recving)
		return -E_IPC_NOT_RECV;
f0104778:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax

	case SYS_env_set_pgfault_upcall:
		return sys_env_set_pgfault_upcall((envid_t) a1, (void *)a2);

	case SYS_ipc_try_send:
		return sys_ipc_try_send(a1,a2,(void*)a3, a4);
f010477d:	e9 00 01 00 00       	jmp    f0104882 <syscall+0x59e>
	//panic("sys_ipc_recv not implemented");

	//check if dstva is below UTOP
	
	
	if ((uint32_t)dstva < UTOP)
f0104782:	81 7d 0c ff ff bf ee 	cmpl   $0xeebfffff,0xc(%ebp)
f0104789:	77 21                	ja     f01047ac <syscall+0x4c8>
	{
		if ((uint32_t)dstva % PGSIZE !=0)
f010478b:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
f0104792:	0f 85 de 00 00 00    	jne    f0104876 <syscall+0x592>
			return -E_INVAL;
		curenv->env_ipc_dstva = dstva;
f0104798:	e8 aa 12 00 00       	call   f0105a47 <cpunum>
f010479d:	6b c0 74             	imul   $0x74,%eax,%eax
f01047a0:	8b 80 48 70 2a f0    	mov    -0xfd58fb8(%eax),%eax
f01047a6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01047a9:	89 58 6c             	mov    %ebx,0x6c(%eax)
	}
	
	//Enable receiving
	curenv->env_ipc_recving = 1;
f01047ac:	e8 96 12 00 00       	call   f0105a47 <cpunum>
f01047b1:	6b c0 74             	imul   $0x74,%eax,%eax
f01047b4:	8b 80 48 70 2a f0    	mov    -0xfd58fb8(%eax),%eax
f01047ba:	c6 40 68 01          	movb   $0x1,0x68(%eax)
	curenv->env_status = ENV_NOT_RUNNABLE;
f01047be:	e8 84 12 00 00       	call   f0105a47 <cpunum>
f01047c3:	6b c0 74             	imul   $0x74,%eax,%eax
f01047c6:	8b 80 48 70 2a f0    	mov    -0xfd58fb8(%eax),%eax
f01047cc:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	sched_yield();
f01047d3:	e8 2c fa ff ff       	call   f0104204 <sched_yield>

	case SYS_ipc_recv:
		return sys_ipc_recv((void*)a1);

	case SYS_env_set_trapframe:
		return sys_env_set_trapframe(a1, (struct Trapframe *)a2);
f01047d8:	8b 75 10             	mov    0x10(%ebp),%esi
	struct Env *e;
	int r;

	//user_mem_assert(curenv, tf, sizeof(struct Trapframe), 0);
	
	if  ( (r= envid2env(envid, &e, 1)) < 0 ) {
f01047db:	83 ec 04             	sub    $0x4,%esp
f01047de:	6a 01                	push   $0x1
f01047e0:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01047e3:	50                   	push   %eax
f01047e4:	ff 75 0c             	pushl  0xc(%ebp)
f01047e7:	e8 23 e8 ff ff       	call   f010300f <envid2env>
f01047ec:	83 c4 10             	add    $0x10,%esp
f01047ef:	85 c0                	test   %eax,%eax
f01047f1:	79 15                	jns    f0104808 <syscall+0x524>
	    panic("Bad or stale environment in kern/syscall.c/sys_env_set_st : %e \n",r); 
f01047f3:	50                   	push   %eax
f01047f4:	68 f0 80 10 f0       	push   $0xf01080f0
f01047f9:	68 a4 00 00 00       	push   $0xa4
f01047fe:	68 cb 80 10 f0       	push   $0xf01080cb
f0104803:	e8 38 b8 ff ff       	call   f0100040 <_panic>
	    return r;	
	}
	e->env_tf = *tf;
f0104808:	b9 11 00 00 00       	mov    $0x11,%ecx
f010480d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104810:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	e->env_tf.tf_ds |= 3;
f0104812:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104815:	66 83 48 24 03       	orw    $0x3,0x24(%eax)
	e->env_tf.tf_es |= 3;
f010481a:	66 83 48 20 03       	orw    $0x3,0x20(%eax)
	e->env_tf.tf_ss |= 3;
f010481f:	66 83 48 40 03       	orw    $0x3,0x40(%eax)
	e->env_tf.tf_cs |= 3;
f0104824:	66 83 48 34 03       	orw    $0x3,0x34(%eax)
	// Make sure CPL = 3, interrupts enabled.
	e->env_tf.tf_eflags |= FL_IF;
	e->env_tf.tf_eflags &= ~(FL_IOPL_MASK);
f0104829:	8b 50 38             	mov    0x38(%eax),%edx
f010482c:	80 e6 cf             	and    $0xcf,%dh
f010482f:	80 ce 02             	or     $0x2,%dh
f0104832:	89 50 38             	mov    %edx,0x38(%eax)

	case SYS_ipc_recv:
		return sys_ipc_recv((void*)a1);

	case SYS_env_set_trapframe:
		return sys_env_set_trapframe(a1, (struct Trapframe *)a2);
f0104835:	b8 00 00 00 00       	mov    $0x0,%eax
f010483a:	eb 46                	jmp    f0104882 <syscall+0x59e>
sys_time_msec(void)
{
	// LAB 6: Your code here.
	//panic("sys_time_msec not implemented");
	
	return time_msec();
f010483c:	e8 9a 1d 00 00       	call   f01065db <time_msec>

	case SYS_env_set_trapframe:
		return sys_env_set_trapframe(a1, (struct Trapframe *)a2);

	case SYS_time_msec:
		return sys_time_msec();
f0104841:	eb 3f                	jmp    f0104882 <syscall+0x59e>

//Set
static int
sys_net_tx_packet(char *data, int length)
{
	if ((uintptr_t) data >= UTOP)
f0104843:	81 7d 0c ff ff bf ee 	cmpl   $0xeebfffff,0xc(%ebp)
f010484a:	77 31                	ja     f010487d <syscall+0x599>
		return -E_INVAL;

	return e1000_Transmit_packet(data, length);
f010484c:	83 ec 08             	sub    $0x8,%esp
f010484f:	ff 75 10             	pushl  0x10(%ebp)
f0104852:	ff 75 0c             	pushl  0xc(%ebp)
f0104855:	e8 a8 17 00 00       	call   f0106002 <e1000_Transmit_packet>
f010485a:	83 c4 10             	add    $0x10,%esp
f010485d:	eb 23                	jmp    f0104882 <syscall+0x59e>

	case SYS_net_tx_packet:
		return sys_net_tx_packet((char *)a1, (int)a2);
		
	default:
		panic("Invalid System Call \n");
f010485f:	83 ec 04             	sub    $0x4,%esp
f0104862:	68 da 80 10 f0       	push   $0xf01080da
f0104867:	68 56 02 00 00       	push   $0x256
f010486c:	68 cb 80 10 f0       	push   $0xf01080cb
f0104871:	e8 ca b7 ff ff       	call   f0100040 <_panic>

	case SYS_ipc_try_send:
		return sys_ipc_try_send(a1,a2,(void*)a3, a4);

	case SYS_ipc_recv:
		return sys_ipc_recv((void*)a1);
f0104876:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010487b:	eb 05                	jmp    f0104882 <syscall+0x59e>
//Set
static int
sys_net_tx_packet(char *data, int length)
{
	if ((uintptr_t) data >= UTOP)
		return -E_INVAL;
f010487d:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		
	default:
		panic("Invalid System Call \n");
		return -E_INVAL;
	}
}
f0104882:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104885:	5b                   	pop    %ebx
f0104886:	5e                   	pop    %esi
f0104887:	5f                   	pop    %edi
f0104888:	5d                   	pop    %ebp
f0104889:	c3                   	ret    

f010488a <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010488a:	55                   	push   %ebp
f010488b:	89 e5                	mov    %esp,%ebp
f010488d:	57                   	push   %edi
f010488e:	56                   	push   %esi
f010488f:	53                   	push   %ebx
f0104890:	83 ec 14             	sub    $0x14,%esp
f0104893:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104896:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104899:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010489c:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010489f:	8b 1a                	mov    (%edx),%ebx
f01048a1:	8b 01                	mov    (%ecx),%eax
f01048a3:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01048a6:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01048ad:	e9 88 00 00 00       	jmp    f010493a <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f01048b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01048b5:	01 d8                	add    %ebx,%eax
f01048b7:	89 c6                	mov    %eax,%esi
f01048b9:	c1 ee 1f             	shr    $0x1f,%esi
f01048bc:	01 c6                	add    %eax,%esi
f01048be:	d1 fe                	sar    %esi
f01048c0:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01048c3:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01048c6:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01048c9:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01048cb:	eb 03                	jmp    f01048d0 <stab_binsearch+0x46>
			m--;
f01048cd:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01048d0:	39 c3                	cmp    %eax,%ebx
f01048d2:	7f 1f                	jg     f01048f3 <stab_binsearch+0x69>
f01048d4:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01048d8:	83 ea 0c             	sub    $0xc,%edx
f01048db:	39 f9                	cmp    %edi,%ecx
f01048dd:	75 ee                	jne    f01048cd <stab_binsearch+0x43>
f01048df:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01048e2:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01048e5:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01048e8:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01048ec:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01048ef:	76 18                	jbe    f0104909 <stab_binsearch+0x7f>
f01048f1:	eb 05                	jmp    f01048f8 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01048f3:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01048f6:	eb 42                	jmp    f010493a <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01048f8:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01048fb:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01048fd:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104900:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104907:	eb 31                	jmp    f010493a <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0104909:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010490c:	73 17                	jae    f0104925 <stab_binsearch+0x9b>
			*region_right = m - 1;
f010490e:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0104911:	83 e8 01             	sub    $0x1,%eax
f0104914:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104917:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010491a:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010491c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104923:	eb 15                	jmp    f010493a <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104925:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104928:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f010492b:	89 1e                	mov    %ebx,(%esi)
			l = m;
			addr++;
f010492d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104931:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104933:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010493a:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010493d:	0f 8e 6f ff ff ff    	jle    f01048b2 <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0104943:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104947:	75 0f                	jne    f0104958 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0104949:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010494c:	8b 00                	mov    (%eax),%eax
f010494e:	83 e8 01             	sub    $0x1,%eax
f0104951:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104954:	89 06                	mov    %eax,(%esi)
f0104956:	eb 2c                	jmp    f0104984 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104958:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010495b:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010495d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104960:	8b 0e                	mov    (%esi),%ecx
f0104962:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104965:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0104968:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010496b:	eb 03                	jmp    f0104970 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010496d:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104970:	39 c8                	cmp    %ecx,%eax
f0104972:	7e 0b                	jle    f010497f <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0104974:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104978:	83 ea 0c             	sub    $0xc,%edx
f010497b:	39 fb                	cmp    %edi,%ebx
f010497d:	75 ee                	jne    f010496d <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f010497f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104982:	89 06                	mov    %eax,(%esi)
	}
}
f0104984:	83 c4 14             	add    $0x14,%esp
f0104987:	5b                   	pop    %ebx
f0104988:	5e                   	pop    %esi
f0104989:	5f                   	pop    %edi
f010498a:	5d                   	pop    %ebp
f010498b:	c3                   	ret    

f010498c <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010498c:	55                   	push   %ebp
f010498d:	89 e5                	mov    %esp,%ebp
f010498f:	57                   	push   %edi
f0104990:	56                   	push   %esi
f0104991:	53                   	push   %ebx
f0104992:	83 ec 3c             	sub    $0x3c,%esp
f0104995:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104998:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010499b:	c7 06 74 81 10 f0    	movl   $0xf0108174,(%esi)
	info->eip_line = 0;
f01049a1:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f01049a8:	c7 46 08 74 81 10 f0 	movl   $0xf0108174,0x8(%esi)
	info->eip_fn_namelen = 9;
f01049af:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01049b6:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f01049b9:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01049c0:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01049c6:	0f 87 a4 00 00 00    	ja     f0104a70 <debuginfo_eip+0xe4>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
f01049cc:	e8 76 10 00 00       	call   f0105a47 <cpunum>
f01049d1:	6a 05                	push   $0x5
f01049d3:	6a 10                	push   $0x10
f01049d5:	68 00 00 20 00       	push   $0x200000
f01049da:	6b c0 74             	imul   $0x74,%eax,%eax
f01049dd:	ff b0 48 70 2a f0    	pushl  -0xfd58fb8(%eax)
f01049e3:	e8 63 e4 ff ff       	call   f0102e4b <user_mem_check>
f01049e8:	83 c4 10             	add    $0x10,%esp
f01049eb:	85 c0                	test   %eax,%eax
f01049ed:	0f 88 24 02 00 00    	js     f0104c17 <debuginfo_eip+0x28b>
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
		}
		stabs = usd->stabs;
f01049f3:	a1 00 00 20 00       	mov    0x200000,%eax
		stab_end = usd->stab_end;
f01049f8:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f01049fe:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f0104a04:	89 4d c0             	mov    %ecx,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f0104a07:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f0104a0d:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
f0104a10:	89 d9                	mov    %ebx,%ecx
f0104a12:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0104a15:	29 c1                	sub    %eax,%ecx
f0104a17:	89 4d b8             	mov    %ecx,-0x48(%ebp)
f0104a1a:	e8 28 10 00 00       	call   f0105a47 <cpunum>
f0104a1f:	6a 05                	push   $0x5
f0104a21:	ff 75 b8             	pushl  -0x48(%ebp)
f0104a24:	ff 75 c4             	pushl  -0x3c(%ebp)
f0104a27:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a2a:	ff b0 48 70 2a f0    	pushl  -0xfd58fb8(%eax)
f0104a30:	e8 16 e4 ff ff       	call   f0102e4b <user_mem_check>
f0104a35:	83 c4 10             	add    $0x10,%esp
f0104a38:	85 c0                	test   %eax,%eax
f0104a3a:	0f 88 de 01 00 00    	js     f0104c1e <debuginfo_eip+0x292>
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
		}

		if (user_mem_check(curenv, (const void *)stabstr,
f0104a40:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104a43:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0104a46:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0104a49:	e8 f9 0f 00 00       	call   f0105a47 <cpunum>
f0104a4e:	6a 05                	push   $0x5
f0104a50:	ff 75 b8             	pushl  -0x48(%ebp)
f0104a53:	ff 75 c0             	pushl  -0x40(%ebp)
f0104a56:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a59:	ff b0 48 70 2a f0    	pushl  -0xfd58fb8(%eax)
f0104a5f:	e8 e7 e3 ff ff       	call   f0102e4b <user_mem_check>
f0104a64:	83 c4 10             	add    $0x10,%esp
f0104a67:	85 c0                	test   %eax,%eax
f0104a69:	79 1f                	jns    f0104a8a <debuginfo_eip+0xfe>
f0104a6b:	e9 b5 01 00 00       	jmp    f0104c25 <debuginfo_eip+0x299>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104a70:	c7 45 bc 0e 89 11 f0 	movl   $0xf011890e,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104a77:	c7 45 c0 9d 45 11 f0 	movl   $0xf011459d,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104a7e:	bb 9c 45 11 f0       	mov    $0xf011459c,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104a83:	c7 45 c4 e0 89 10 f0 	movl   $0xf01089e0,-0x3c(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104a8a:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104a8d:	39 45 c0             	cmp    %eax,-0x40(%ebp)
f0104a90:	0f 83 96 01 00 00    	jae    f0104c2c <debuginfo_eip+0x2a0>
f0104a96:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0104a9a:	0f 85 93 01 00 00    	jne    f0104c33 <debuginfo_eip+0x2a7>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104aa0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104aa7:	89 d8                	mov    %ebx,%eax
f0104aa9:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0104aac:	29 d8                	sub    %ebx,%eax
f0104aae:	c1 f8 02             	sar    $0x2,%eax
f0104ab1:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0104ab7:	83 e8 01             	sub    $0x1,%eax
f0104aba:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104abd:	83 ec 08             	sub    $0x8,%esp
f0104ac0:	57                   	push   %edi
f0104ac1:	6a 64                	push   $0x64
f0104ac3:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0104ac6:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104ac9:	89 d8                	mov    %ebx,%eax
f0104acb:	e8 ba fd ff ff       	call   f010488a <stab_binsearch>
	if (lfile == 0)
f0104ad0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104ad3:	83 c4 10             	add    $0x10,%esp
f0104ad6:	85 c0                	test   %eax,%eax
f0104ad8:	0f 84 5c 01 00 00    	je     f0104c3a <debuginfo_eip+0x2ae>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104ade:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104ae1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104ae4:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104ae7:	83 ec 08             	sub    $0x8,%esp
f0104aea:	57                   	push   %edi
f0104aeb:	6a 24                	push   $0x24
f0104aed:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0104af0:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104af3:	89 d8                	mov    %ebx,%eax
f0104af5:	e8 90 fd ff ff       	call   f010488a <stab_binsearch>

	if (lfun <= rfun) {
f0104afa:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104afd:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0104b00:	83 c4 10             	add    $0x10,%esp
f0104b03:	39 d8                	cmp    %ebx,%eax
f0104b05:	7f 32                	jg     f0104b39 <debuginfo_eip+0x1ad>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104b07:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104b0a:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0104b0d:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f0104b10:	8b 11                	mov    (%ecx),%edx
f0104b12:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0104b15:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104b18:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0104b1b:	39 55 b8             	cmp    %edx,-0x48(%ebp)
f0104b1e:	73 09                	jae    f0104b29 <debuginfo_eip+0x19d>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104b20:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0104b23:	03 55 c0             	add    -0x40(%ebp),%edx
f0104b26:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104b29:	8b 51 08             	mov    0x8(%ecx),%edx
f0104b2c:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0104b2f:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0104b31:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104b34:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0104b37:	eb 0f                	jmp    f0104b48 <debuginfo_eip+0x1bc>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104b39:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0104b3c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104b3f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104b42:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104b45:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104b48:	83 ec 08             	sub    $0x8,%esp
f0104b4b:	6a 3a                	push   $0x3a
f0104b4d:	ff 76 08             	pushl  0x8(%esi)
f0104b50:	e8 b1 08 00 00       	call   f0105406 <strfind>
f0104b55:	2b 46 08             	sub    0x8(%esi),%eax
f0104b58:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
f0104b5b:	83 c4 08             	add    $0x8,%esp
f0104b5e:	57                   	push   %edi
f0104b5f:	6a 44                	push   $0x44
f0104b61:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104b64:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0104b67:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0104b6a:	89 d8                	mov    %ebx,%eax
f0104b6c:	e8 19 fd ff ff       	call   f010488a <stab_binsearch>
	if (lline > rline) {
f0104b71:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104b74:	83 c4 10             	add    $0x10,%esp
f0104b77:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0104b7a:	0f 8f c1 00 00 00    	jg     f0104c41 <debuginfo_eip+0x2b5>
		return -1; //Did not find the line number in the stab
	}
	info->eip_line = stabs[lline].n_desc; //If found update the info object with the correct line number
f0104b80:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104b83:	0f b7 44 83 06       	movzwl 0x6(%ebx,%eax,4),%eax
f0104b88:	89 46 04             	mov    %eax,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104b8b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104b8e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104b91:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104b94:	8d 14 93             	lea    (%ebx,%edx,4),%edx
f0104b97:	89 75 0c             	mov    %esi,0xc(%ebp)
f0104b9a:	eb 06                	jmp    f0104ba2 <debuginfo_eip+0x216>
f0104b9c:	83 e8 01             	sub    $0x1,%eax
f0104b9f:	83 ea 0c             	sub    $0xc,%edx
f0104ba2:	39 c7                	cmp    %eax,%edi
f0104ba4:	7f 2a                	jg     f0104bd0 <debuginfo_eip+0x244>
	       && stabs[lline].n_type != N_SOL
f0104ba6:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104baa:	80 f9 84             	cmp    $0x84,%cl
f0104bad:	0f 84 9c 00 00 00    	je     f0104c4f <debuginfo_eip+0x2c3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104bb3:	80 f9 64             	cmp    $0x64,%cl
f0104bb6:	75 e4                	jne    f0104b9c <debuginfo_eip+0x210>
f0104bb8:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0104bbc:	74 de                	je     f0104b9c <debuginfo_eip+0x210>
f0104bbe:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104bc1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104bc4:	e9 8c 00 00 00       	jmp    f0104c55 <debuginfo_eip+0x2c9>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104bc9:	03 55 c0             	add    -0x40(%ebp),%edx
f0104bcc:	89 16                	mov    %edx,(%esi)
f0104bce:	eb 03                	jmp    f0104bd3 <debuginfo_eip+0x247>
f0104bd0:	8b 75 0c             	mov    0xc(%ebp),%esi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104bd3:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104bd6:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104bd9:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104bde:	39 da                	cmp    %ebx,%edx
f0104be0:	0f 8d 8b 00 00 00    	jge    f0104c71 <debuginfo_eip+0x2e5>
		for (lline = lfun + 1;
f0104be6:	83 c2 01             	add    $0x1,%edx
f0104be9:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104bec:	89 d0                	mov    %edx,%eax
f0104bee:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104bf1:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0104bf4:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0104bf7:	eb 04                	jmp    f0104bfd <debuginfo_eip+0x271>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104bf9:	83 46 14 01          	addl   $0x1,0x14(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104bfd:	39 c3                	cmp    %eax,%ebx
f0104bff:	7e 47                	jle    f0104c48 <debuginfo_eip+0x2bc>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104c01:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104c05:	83 c0 01             	add    $0x1,%eax
f0104c08:	83 c2 0c             	add    $0xc,%edx
f0104c0b:	80 f9 a0             	cmp    $0xa0,%cl
f0104c0e:	74 e9                	je     f0104bf9 <debuginfo_eip+0x26d>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104c10:	b8 00 00 00 00       	mov    $0x0,%eax
f0104c15:	eb 5a                	jmp    f0104c71 <debuginfo_eip+0x2e5>
		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
f0104c17:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104c1c:	eb 53                	jmp    f0104c71 <debuginfo_eip+0x2e5>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
f0104c1e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104c23:	eb 4c                	jmp    f0104c71 <debuginfo_eip+0x2e5>
		}

		if (user_mem_check(curenv, (const void *)stabstr,
				(uintptr_t)stabstr_end - (uintptr_t)stabstr, PTE_U | PTE_P) < 0) {
			return -1;
f0104c25:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104c2a:	eb 45                	jmp    f0104c71 <debuginfo_eip+0x2e5>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104c2c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104c31:	eb 3e                	jmp    f0104c71 <debuginfo_eip+0x2e5>
f0104c33:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104c38:	eb 37                	jmp    f0104c71 <debuginfo_eip+0x2e5>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104c3a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104c3f:	eb 30                	jmp    f0104c71 <debuginfo_eip+0x2e5>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
	if (lline > rline) {
		return -1; //Did not find the line number in the stab
f0104c41:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104c46:	eb 29                	jmp    f0104c71 <debuginfo_eip+0x2e5>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104c48:	b8 00 00 00 00       	mov    $0x0,%eax
f0104c4d:	eb 22                	jmp    f0104c71 <debuginfo_eip+0x2e5>
f0104c4f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104c52:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104c55:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104c58:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0104c5b:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0104c5e:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104c61:	2b 45 c0             	sub    -0x40(%ebp),%eax
f0104c64:	39 c2                	cmp    %eax,%edx
f0104c66:	0f 82 5d ff ff ff    	jb     f0104bc9 <debuginfo_eip+0x23d>
f0104c6c:	e9 62 ff ff ff       	jmp    f0104bd3 <debuginfo_eip+0x247>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
}
f0104c71:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104c74:	5b                   	pop    %ebx
f0104c75:	5e                   	pop    %esi
f0104c76:	5f                   	pop    %edi
f0104c77:	5d                   	pop    %ebp
f0104c78:	c3                   	ret    

f0104c79 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104c79:	55                   	push   %ebp
f0104c7a:	89 e5                	mov    %esp,%ebp
f0104c7c:	57                   	push   %edi
f0104c7d:	56                   	push   %esi
f0104c7e:	53                   	push   %ebx
f0104c7f:	83 ec 1c             	sub    $0x1c,%esp
f0104c82:	89 c7                	mov    %eax,%edi
f0104c84:	89 d6                	mov    %edx,%esi
f0104c86:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c89:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104c8c:	89 d1                	mov    %edx,%ecx
f0104c8e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104c91:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104c94:	8b 45 10             	mov    0x10(%ebp),%eax
f0104c97:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104c9a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104c9d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0104ca4:	39 4d e4             	cmp    %ecx,-0x1c(%ebp)
f0104ca7:	72 05                	jb     f0104cae <printnum+0x35>
f0104ca9:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0104cac:	77 3e                	ja     f0104cec <printnum+0x73>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104cae:	83 ec 0c             	sub    $0xc,%esp
f0104cb1:	ff 75 18             	pushl  0x18(%ebp)
f0104cb4:	83 eb 01             	sub    $0x1,%ebx
f0104cb7:	53                   	push   %ebx
f0104cb8:	50                   	push   %eax
f0104cb9:	83 ec 08             	sub    $0x8,%esp
f0104cbc:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104cbf:	ff 75 e0             	pushl  -0x20(%ebp)
f0104cc2:	ff 75 dc             	pushl  -0x24(%ebp)
f0104cc5:	ff 75 d8             	pushl  -0x28(%ebp)
f0104cc8:	e8 23 19 00 00       	call   f01065f0 <__udivdi3>
f0104ccd:	83 c4 18             	add    $0x18,%esp
f0104cd0:	52                   	push   %edx
f0104cd1:	50                   	push   %eax
f0104cd2:	89 f2                	mov    %esi,%edx
f0104cd4:	89 f8                	mov    %edi,%eax
f0104cd6:	e8 9e ff ff ff       	call   f0104c79 <printnum>
f0104cdb:	83 c4 20             	add    $0x20,%esp
f0104cde:	eb 13                	jmp    f0104cf3 <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104ce0:	83 ec 08             	sub    $0x8,%esp
f0104ce3:	56                   	push   %esi
f0104ce4:	ff 75 18             	pushl  0x18(%ebp)
f0104ce7:	ff d7                	call   *%edi
f0104ce9:	83 c4 10             	add    $0x10,%esp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104cec:	83 eb 01             	sub    $0x1,%ebx
f0104cef:	85 db                	test   %ebx,%ebx
f0104cf1:	7f ed                	jg     f0104ce0 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104cf3:	83 ec 08             	sub    $0x8,%esp
f0104cf6:	56                   	push   %esi
f0104cf7:	83 ec 04             	sub    $0x4,%esp
f0104cfa:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104cfd:	ff 75 e0             	pushl  -0x20(%ebp)
f0104d00:	ff 75 dc             	pushl  -0x24(%ebp)
f0104d03:	ff 75 d8             	pushl  -0x28(%ebp)
f0104d06:	e8 15 1a 00 00       	call   f0106720 <__umoddi3>
f0104d0b:	83 c4 14             	add    $0x14,%esp
f0104d0e:	0f be 80 7e 81 10 f0 	movsbl -0xfef7e82(%eax),%eax
f0104d15:	50                   	push   %eax
f0104d16:	ff d7                	call   *%edi
f0104d18:	83 c4 10             	add    $0x10,%esp
}
f0104d1b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104d1e:	5b                   	pop    %ebx
f0104d1f:	5e                   	pop    %esi
f0104d20:	5f                   	pop    %edi
f0104d21:	5d                   	pop    %ebp
f0104d22:	c3                   	ret    

f0104d23 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0104d23:	55                   	push   %ebp
f0104d24:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104d26:	83 fa 01             	cmp    $0x1,%edx
f0104d29:	7e 0e                	jle    f0104d39 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0104d2b:	8b 10                	mov    (%eax),%edx
f0104d2d:	8d 4a 08             	lea    0x8(%edx),%ecx
f0104d30:	89 08                	mov    %ecx,(%eax)
f0104d32:	8b 02                	mov    (%edx),%eax
f0104d34:	8b 52 04             	mov    0x4(%edx),%edx
f0104d37:	eb 22                	jmp    f0104d5b <getuint+0x38>
	else if (lflag)
f0104d39:	85 d2                	test   %edx,%edx
f0104d3b:	74 10                	je     f0104d4d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104d3d:	8b 10                	mov    (%eax),%edx
f0104d3f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104d42:	89 08                	mov    %ecx,(%eax)
f0104d44:	8b 02                	mov    (%edx),%eax
f0104d46:	ba 00 00 00 00       	mov    $0x0,%edx
f0104d4b:	eb 0e                	jmp    f0104d5b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104d4d:	8b 10                	mov    (%eax),%edx
f0104d4f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104d52:	89 08                	mov    %ecx,(%eax)
f0104d54:	8b 02                	mov    (%edx),%eax
f0104d56:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104d5b:	5d                   	pop    %ebp
f0104d5c:	c3                   	ret    

f0104d5d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104d5d:	55                   	push   %ebp
f0104d5e:	89 e5                	mov    %esp,%ebp
f0104d60:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104d63:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104d67:	8b 10                	mov    (%eax),%edx
f0104d69:	3b 50 04             	cmp    0x4(%eax),%edx
f0104d6c:	73 0a                	jae    f0104d78 <sprintputch+0x1b>
		*b->buf++ = ch;
f0104d6e:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104d71:	89 08                	mov    %ecx,(%eax)
f0104d73:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d76:	88 02                	mov    %al,(%edx)
}
f0104d78:	5d                   	pop    %ebp
f0104d79:	c3                   	ret    

f0104d7a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104d7a:	55                   	push   %ebp
f0104d7b:	89 e5                	mov    %esp,%ebp
f0104d7d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0104d80:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104d83:	50                   	push   %eax
f0104d84:	ff 75 10             	pushl  0x10(%ebp)
f0104d87:	ff 75 0c             	pushl  0xc(%ebp)
f0104d8a:	ff 75 08             	pushl  0x8(%ebp)
f0104d8d:	e8 05 00 00 00       	call   f0104d97 <vprintfmt>
	va_end(ap);
f0104d92:	83 c4 10             	add    $0x10,%esp
}
f0104d95:	c9                   	leave  
f0104d96:	c3                   	ret    

f0104d97 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104d97:	55                   	push   %ebp
f0104d98:	89 e5                	mov    %esp,%ebp
f0104d9a:	57                   	push   %edi
f0104d9b:	56                   	push   %esi
f0104d9c:	53                   	push   %ebx
f0104d9d:	83 ec 2c             	sub    $0x2c,%esp
f0104da0:	8b 75 08             	mov    0x8(%ebp),%esi
f0104da3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104da6:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104da9:	eb 12                	jmp    f0104dbd <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104dab:	85 c0                	test   %eax,%eax
f0104dad:	0f 84 90 03 00 00    	je     f0105143 <vprintfmt+0x3ac>
				return;
			putch(ch, putdat);
f0104db3:	83 ec 08             	sub    $0x8,%esp
f0104db6:	53                   	push   %ebx
f0104db7:	50                   	push   %eax
f0104db8:	ff d6                	call   *%esi
f0104dba:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104dbd:	83 c7 01             	add    $0x1,%edi
f0104dc0:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104dc4:	83 f8 25             	cmp    $0x25,%eax
f0104dc7:	75 e2                	jne    f0104dab <vprintfmt+0x14>
f0104dc9:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0104dcd:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0104dd4:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104ddb:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0104de2:	ba 00 00 00 00       	mov    $0x0,%edx
f0104de7:	eb 07                	jmp    f0104df0 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104de9:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104dec:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104df0:	8d 47 01             	lea    0x1(%edi),%eax
f0104df3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104df6:	0f b6 07             	movzbl (%edi),%eax
f0104df9:	0f b6 c8             	movzbl %al,%ecx
f0104dfc:	83 e8 23             	sub    $0x23,%eax
f0104dff:	3c 55                	cmp    $0x55,%al
f0104e01:	0f 87 21 03 00 00    	ja     f0105128 <vprintfmt+0x391>
f0104e07:	0f b6 c0             	movzbl %al,%eax
f0104e0a:	ff 24 85 c0 82 10 f0 	jmp    *-0xfef7d40(,%eax,4)
f0104e11:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104e14:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0104e18:	eb d6                	jmp    f0104df0 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e1a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104e1d:	b8 00 00 00 00       	mov    $0x0,%eax
f0104e22:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104e25:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104e28:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0104e2c:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0104e2f:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0104e32:	83 fa 09             	cmp    $0x9,%edx
f0104e35:	77 39                	ja     f0104e70 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104e37:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104e3a:	eb e9                	jmp    f0104e25 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104e3c:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e3f:	8d 48 04             	lea    0x4(%eax),%ecx
f0104e42:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104e45:	8b 00                	mov    (%eax),%eax
f0104e47:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e4a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104e4d:	eb 27                	jmp    f0104e76 <vprintfmt+0xdf>
f0104e4f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104e52:	85 c0                	test   %eax,%eax
f0104e54:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104e59:	0f 49 c8             	cmovns %eax,%ecx
f0104e5c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e5f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104e62:	eb 8c                	jmp    f0104df0 <vprintfmt+0x59>
f0104e64:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104e67:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0104e6e:	eb 80                	jmp    f0104df0 <vprintfmt+0x59>
f0104e70:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104e73:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0104e76:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104e7a:	0f 89 70 ff ff ff    	jns    f0104df0 <vprintfmt+0x59>
				width = precision, precision = -1;
f0104e80:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104e83:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104e86:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104e8d:	e9 5e ff ff ff       	jmp    f0104df0 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104e92:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e95:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0104e98:	e9 53 ff ff ff       	jmp    f0104df0 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104e9d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ea0:	8d 50 04             	lea    0x4(%eax),%edx
f0104ea3:	89 55 14             	mov    %edx,0x14(%ebp)
f0104ea6:	83 ec 08             	sub    $0x8,%esp
f0104ea9:	53                   	push   %ebx
f0104eaa:	ff 30                	pushl  (%eax)
f0104eac:	ff d6                	call   *%esi
			break;
f0104eae:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104eb1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0104eb4:	e9 04 ff ff ff       	jmp    f0104dbd <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104eb9:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ebc:	8d 50 04             	lea    0x4(%eax),%edx
f0104ebf:	89 55 14             	mov    %edx,0x14(%ebp)
f0104ec2:	8b 00                	mov    (%eax),%eax
f0104ec4:	99                   	cltd   
f0104ec5:	31 d0                	xor    %edx,%eax
f0104ec7:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104ec9:	83 f8 12             	cmp    $0x12,%eax
f0104ecc:	7f 0b                	jg     f0104ed9 <vprintfmt+0x142>
f0104ece:	8b 14 85 40 84 10 f0 	mov    -0xfef7bc0(,%eax,4),%edx
f0104ed5:	85 d2                	test   %edx,%edx
f0104ed7:	75 18                	jne    f0104ef1 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0104ed9:	50                   	push   %eax
f0104eda:	68 96 81 10 f0       	push   $0xf0108196
f0104edf:	53                   	push   %ebx
f0104ee0:	56                   	push   %esi
f0104ee1:	e8 94 fe ff ff       	call   f0104d7a <printfmt>
f0104ee6:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104ee9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0104eec:	e9 cc fe ff ff       	jmp    f0104dbd <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0104ef1:	52                   	push   %edx
f0104ef2:	68 ad 78 10 f0       	push   $0xf01078ad
f0104ef7:	53                   	push   %ebx
f0104ef8:	56                   	push   %esi
f0104ef9:	e8 7c fe ff ff       	call   f0104d7a <printfmt>
f0104efe:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104f01:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104f04:	e9 b4 fe ff ff       	jmp    f0104dbd <vprintfmt+0x26>
f0104f09:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0104f0c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104f0f:	89 45 cc             	mov    %eax,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104f12:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f15:	8d 50 04             	lea    0x4(%eax),%edx
f0104f18:	89 55 14             	mov    %edx,0x14(%ebp)
f0104f1b:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104f1d:	85 ff                	test   %edi,%edi
f0104f1f:	ba 8f 81 10 f0       	mov    $0xf010818f,%edx
f0104f24:	0f 44 fa             	cmove  %edx,%edi
			if (width > 0 && padc != '-')
f0104f27:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0104f2b:	0f 84 92 00 00 00    	je     f0104fc3 <vprintfmt+0x22c>
f0104f31:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0104f35:	0f 8e 96 00 00 00    	jle    f0104fd1 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104f3b:	83 ec 08             	sub    $0x8,%esp
f0104f3e:	51                   	push   %ecx
f0104f3f:	57                   	push   %edi
f0104f40:	e8 77 03 00 00       	call   f01052bc <strnlen>
f0104f45:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104f48:	29 c1                	sub    %eax,%ecx
f0104f4a:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0104f4d:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104f50:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104f54:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104f57:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104f5a:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104f5c:	eb 0f                	jmp    f0104f6d <vprintfmt+0x1d6>
					putch(padc, putdat);
f0104f5e:	83 ec 08             	sub    $0x8,%esp
f0104f61:	53                   	push   %ebx
f0104f62:	ff 75 e0             	pushl  -0x20(%ebp)
f0104f65:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104f67:	83 ef 01             	sub    $0x1,%edi
f0104f6a:	83 c4 10             	add    $0x10,%esp
f0104f6d:	85 ff                	test   %edi,%edi
f0104f6f:	7f ed                	jg     f0104f5e <vprintfmt+0x1c7>
f0104f71:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104f74:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104f77:	85 c9                	test   %ecx,%ecx
f0104f79:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f7e:	0f 49 c1             	cmovns %ecx,%eax
f0104f81:	29 c1                	sub    %eax,%ecx
f0104f83:	89 75 08             	mov    %esi,0x8(%ebp)
f0104f86:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104f89:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104f8c:	89 cb                	mov    %ecx,%ebx
f0104f8e:	eb 4d                	jmp    f0104fdd <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104f90:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104f94:	74 1b                	je     f0104fb1 <vprintfmt+0x21a>
f0104f96:	0f be c0             	movsbl %al,%eax
f0104f99:	83 e8 20             	sub    $0x20,%eax
f0104f9c:	83 f8 5e             	cmp    $0x5e,%eax
f0104f9f:	76 10                	jbe    f0104fb1 <vprintfmt+0x21a>
					putch('?', putdat);
f0104fa1:	83 ec 08             	sub    $0x8,%esp
f0104fa4:	ff 75 0c             	pushl  0xc(%ebp)
f0104fa7:	6a 3f                	push   $0x3f
f0104fa9:	ff 55 08             	call   *0x8(%ebp)
f0104fac:	83 c4 10             	add    $0x10,%esp
f0104faf:	eb 0d                	jmp    f0104fbe <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0104fb1:	83 ec 08             	sub    $0x8,%esp
f0104fb4:	ff 75 0c             	pushl  0xc(%ebp)
f0104fb7:	52                   	push   %edx
f0104fb8:	ff 55 08             	call   *0x8(%ebp)
f0104fbb:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104fbe:	83 eb 01             	sub    $0x1,%ebx
f0104fc1:	eb 1a                	jmp    f0104fdd <vprintfmt+0x246>
f0104fc3:	89 75 08             	mov    %esi,0x8(%ebp)
f0104fc6:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104fc9:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104fcc:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104fcf:	eb 0c                	jmp    f0104fdd <vprintfmt+0x246>
f0104fd1:	89 75 08             	mov    %esi,0x8(%ebp)
f0104fd4:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104fd7:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104fda:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104fdd:	83 c7 01             	add    $0x1,%edi
f0104fe0:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104fe4:	0f be d0             	movsbl %al,%edx
f0104fe7:	85 d2                	test   %edx,%edx
f0104fe9:	74 23                	je     f010500e <vprintfmt+0x277>
f0104feb:	85 f6                	test   %esi,%esi
f0104fed:	78 a1                	js     f0104f90 <vprintfmt+0x1f9>
f0104fef:	83 ee 01             	sub    $0x1,%esi
f0104ff2:	79 9c                	jns    f0104f90 <vprintfmt+0x1f9>
f0104ff4:	89 df                	mov    %ebx,%edi
f0104ff6:	8b 75 08             	mov    0x8(%ebp),%esi
f0104ff9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104ffc:	eb 18                	jmp    f0105016 <vprintfmt+0x27f>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104ffe:	83 ec 08             	sub    $0x8,%esp
f0105001:	53                   	push   %ebx
f0105002:	6a 20                	push   $0x20
f0105004:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0105006:	83 ef 01             	sub    $0x1,%edi
f0105009:	83 c4 10             	add    $0x10,%esp
f010500c:	eb 08                	jmp    f0105016 <vprintfmt+0x27f>
f010500e:	89 df                	mov    %ebx,%edi
f0105010:	8b 75 08             	mov    0x8(%ebp),%esi
f0105013:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105016:	85 ff                	test   %edi,%edi
f0105018:	7f e4                	jg     f0104ffe <vprintfmt+0x267>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010501a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010501d:	e9 9b fd ff ff       	jmp    f0104dbd <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0105022:	83 fa 01             	cmp    $0x1,%edx
f0105025:	7e 16                	jle    f010503d <vprintfmt+0x2a6>
		return va_arg(*ap, long long);
f0105027:	8b 45 14             	mov    0x14(%ebp),%eax
f010502a:	8d 50 08             	lea    0x8(%eax),%edx
f010502d:	89 55 14             	mov    %edx,0x14(%ebp)
f0105030:	8b 50 04             	mov    0x4(%eax),%edx
f0105033:	8b 00                	mov    (%eax),%eax
f0105035:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105038:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010503b:	eb 32                	jmp    f010506f <vprintfmt+0x2d8>
	else if (lflag)
f010503d:	85 d2                	test   %edx,%edx
f010503f:	74 18                	je     f0105059 <vprintfmt+0x2c2>
		return va_arg(*ap, long);
f0105041:	8b 45 14             	mov    0x14(%ebp),%eax
f0105044:	8d 50 04             	lea    0x4(%eax),%edx
f0105047:	89 55 14             	mov    %edx,0x14(%ebp)
f010504a:	8b 00                	mov    (%eax),%eax
f010504c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010504f:	89 c1                	mov    %eax,%ecx
f0105051:	c1 f9 1f             	sar    $0x1f,%ecx
f0105054:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0105057:	eb 16                	jmp    f010506f <vprintfmt+0x2d8>
	else
		return va_arg(*ap, int);
f0105059:	8b 45 14             	mov    0x14(%ebp),%eax
f010505c:	8d 50 04             	lea    0x4(%eax),%edx
f010505f:	89 55 14             	mov    %edx,0x14(%ebp)
f0105062:	8b 00                	mov    (%eax),%eax
f0105064:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105067:	89 c1                	mov    %eax,%ecx
f0105069:	c1 f9 1f             	sar    $0x1f,%ecx
f010506c:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010506f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0105072:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0105075:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f010507a:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010507e:	79 74                	jns    f01050f4 <vprintfmt+0x35d>
				putch('-', putdat);
f0105080:	83 ec 08             	sub    $0x8,%esp
f0105083:	53                   	push   %ebx
f0105084:	6a 2d                	push   $0x2d
f0105086:	ff d6                	call   *%esi
				num = -(long long) num;
f0105088:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010508b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010508e:	f7 d8                	neg    %eax
f0105090:	83 d2 00             	adc    $0x0,%edx
f0105093:	f7 da                	neg    %edx
f0105095:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0105098:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010509d:	eb 55                	jmp    f01050f4 <vprintfmt+0x35d>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010509f:	8d 45 14             	lea    0x14(%ebp),%eax
f01050a2:	e8 7c fc ff ff       	call   f0104d23 <getuint>
			base = 10;
f01050a7:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01050ac:	eb 46                	jmp    f01050f4 <vprintfmt+0x35d>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01050ae:	8d 45 14             	lea    0x14(%ebp),%eax
f01050b1:	e8 6d fc ff ff       	call   f0104d23 <getuint>
			base = 8;
f01050b6:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01050bb:	eb 37                	jmp    f01050f4 <vprintfmt+0x35d>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f01050bd:	83 ec 08             	sub    $0x8,%esp
f01050c0:	53                   	push   %ebx
f01050c1:	6a 30                	push   $0x30
f01050c3:	ff d6                	call   *%esi
			putch('x', putdat);
f01050c5:	83 c4 08             	add    $0x8,%esp
f01050c8:	53                   	push   %ebx
f01050c9:	6a 78                	push   $0x78
f01050cb:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01050cd:	8b 45 14             	mov    0x14(%ebp),%eax
f01050d0:	8d 50 04             	lea    0x4(%eax),%edx
f01050d3:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01050d6:	8b 00                	mov    (%eax),%eax
f01050d8:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01050dd:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01050e0:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01050e5:	eb 0d                	jmp    f01050f4 <vprintfmt+0x35d>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01050e7:	8d 45 14             	lea    0x14(%ebp),%eax
f01050ea:	e8 34 fc ff ff       	call   f0104d23 <getuint>
			base = 16;
f01050ef:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01050f4:	83 ec 0c             	sub    $0xc,%esp
f01050f7:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01050fb:	57                   	push   %edi
f01050fc:	ff 75 e0             	pushl  -0x20(%ebp)
f01050ff:	51                   	push   %ecx
f0105100:	52                   	push   %edx
f0105101:	50                   	push   %eax
f0105102:	89 da                	mov    %ebx,%edx
f0105104:	89 f0                	mov    %esi,%eax
f0105106:	e8 6e fb ff ff       	call   f0104c79 <printnum>
			break;
f010510b:	83 c4 20             	add    $0x20,%esp
f010510e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0105111:	e9 a7 fc ff ff       	jmp    f0104dbd <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0105116:	83 ec 08             	sub    $0x8,%esp
f0105119:	53                   	push   %ebx
f010511a:	51                   	push   %ecx
f010511b:	ff d6                	call   *%esi
			break;
f010511d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105120:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0105123:	e9 95 fc ff ff       	jmp    f0104dbd <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0105128:	83 ec 08             	sub    $0x8,%esp
f010512b:	53                   	push   %ebx
f010512c:	6a 25                	push   $0x25
f010512e:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0105130:	83 c4 10             	add    $0x10,%esp
f0105133:	eb 03                	jmp    f0105138 <vprintfmt+0x3a1>
f0105135:	83 ef 01             	sub    $0x1,%edi
f0105138:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f010513c:	75 f7                	jne    f0105135 <vprintfmt+0x39e>
f010513e:	e9 7a fc ff ff       	jmp    f0104dbd <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0105143:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105146:	5b                   	pop    %ebx
f0105147:	5e                   	pop    %esi
f0105148:	5f                   	pop    %edi
f0105149:	5d                   	pop    %ebp
f010514a:	c3                   	ret    

f010514b <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010514b:	55                   	push   %ebp
f010514c:	89 e5                	mov    %esp,%ebp
f010514e:	83 ec 18             	sub    $0x18,%esp
f0105151:	8b 45 08             	mov    0x8(%ebp),%eax
f0105154:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0105157:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010515a:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010515e:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0105161:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0105168:	85 c0                	test   %eax,%eax
f010516a:	74 26                	je     f0105192 <vsnprintf+0x47>
f010516c:	85 d2                	test   %edx,%edx
f010516e:	7e 22                	jle    f0105192 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0105170:	ff 75 14             	pushl  0x14(%ebp)
f0105173:	ff 75 10             	pushl  0x10(%ebp)
f0105176:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0105179:	50                   	push   %eax
f010517a:	68 5d 4d 10 f0       	push   $0xf0104d5d
f010517f:	e8 13 fc ff ff       	call   f0104d97 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0105184:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105187:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010518a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010518d:	83 c4 10             	add    $0x10,%esp
f0105190:	eb 05                	jmp    f0105197 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0105192:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0105197:	c9                   	leave  
f0105198:	c3                   	ret    

f0105199 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0105199:	55                   	push   %ebp
f010519a:	89 e5                	mov    %esp,%ebp
f010519c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010519f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01051a2:	50                   	push   %eax
f01051a3:	ff 75 10             	pushl  0x10(%ebp)
f01051a6:	ff 75 0c             	pushl  0xc(%ebp)
f01051a9:	ff 75 08             	pushl  0x8(%ebp)
f01051ac:	e8 9a ff ff ff       	call   f010514b <vsnprintf>
	va_end(ap);

	return rc;
}
f01051b1:	c9                   	leave  
f01051b2:	c3                   	ret    

f01051b3 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01051b3:	55                   	push   %ebp
f01051b4:	89 e5                	mov    %esp,%ebp
f01051b6:	57                   	push   %edi
f01051b7:	56                   	push   %esi
f01051b8:	53                   	push   %ebx
f01051b9:	83 ec 0c             	sub    $0xc,%esp
f01051bc:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

#if JOS_KERNEL
	if (prompt != NULL)
f01051bf:	85 c0                	test   %eax,%eax
f01051c1:	74 11                	je     f01051d4 <readline+0x21>
		cprintf("%s", prompt);
f01051c3:	83 ec 08             	sub    $0x8,%esp
f01051c6:	50                   	push   %eax
f01051c7:	68 ad 78 10 f0       	push   $0xf01078ad
f01051cc:	e8 79 e6 ff ff       	call   f010384a <cprintf>
f01051d1:	83 c4 10             	add    $0x10,%esp
	if (prompt != NULL)
		fprintf(1, "%s", prompt);
#endif

	i = 0;
	echoing = iscons(0);
f01051d4:	83 ec 0c             	sub    $0xc,%esp
f01051d7:	6a 00                	push   $0x0
f01051d9:	e8 ca b5 ff ff       	call   f01007a8 <iscons>
f01051de:	89 c7                	mov    %eax,%edi
f01051e0:	83 c4 10             	add    $0x10,%esp
#else
	if (prompt != NULL)
		fprintf(1, "%s", prompt);
#endif

	i = 0;
f01051e3:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01051e8:	e8 aa b5 ff ff       	call   f0100797 <getchar>
f01051ed:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01051ef:	85 c0                	test   %eax,%eax
f01051f1:	79 29                	jns    f010521c <readline+0x69>
			if (c != -E_EOF)
				cprintf("read error: %e\n", c);
			return NULL;
f01051f3:	b8 00 00 00 00       	mov    $0x0,%eax
	i = 0;
	echoing = iscons(0);
	while (1) {
		c = getchar();
		if (c < 0) {
			if (c != -E_EOF)
f01051f8:	83 fb f8             	cmp    $0xfffffff8,%ebx
f01051fb:	0f 84 9b 00 00 00    	je     f010529c <readline+0xe9>
				cprintf("read error: %e\n", c);
f0105201:	83 ec 08             	sub    $0x8,%esp
f0105204:	53                   	push   %ebx
f0105205:	68 ab 84 10 f0       	push   $0xf01084ab
f010520a:	e8 3b e6 ff ff       	call   f010384a <cprintf>
f010520f:	83 c4 10             	add    $0x10,%esp
			return NULL;
f0105212:	b8 00 00 00 00       	mov    $0x0,%eax
f0105217:	e9 80 00 00 00       	jmp    f010529c <readline+0xe9>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010521c:	83 f8 7f             	cmp    $0x7f,%eax
f010521f:	0f 94 c2             	sete   %dl
f0105222:	83 f8 08             	cmp    $0x8,%eax
f0105225:	0f 94 c0             	sete   %al
f0105228:	08 c2                	or     %al,%dl
f010522a:	74 1a                	je     f0105246 <readline+0x93>
f010522c:	85 f6                	test   %esi,%esi
f010522e:	7e 16                	jle    f0105246 <readline+0x93>
			if (echoing)
f0105230:	85 ff                	test   %edi,%edi
f0105232:	74 0d                	je     f0105241 <readline+0x8e>
				cputchar('\b');
f0105234:	83 ec 0c             	sub    $0xc,%esp
f0105237:	6a 08                	push   $0x8
f0105239:	e8 49 b5 ff ff       	call   f0100787 <cputchar>
f010523e:	83 c4 10             	add    $0x10,%esp
			i--;
f0105241:	83 ee 01             	sub    $0x1,%esi
f0105244:	eb a2                	jmp    f01051e8 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0105246:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010524c:	7f 23                	jg     f0105271 <readline+0xbe>
f010524e:	83 fb 1f             	cmp    $0x1f,%ebx
f0105251:	7e 1e                	jle    f0105271 <readline+0xbe>
			if (echoing)
f0105253:	85 ff                	test   %edi,%edi
f0105255:	74 0c                	je     f0105263 <readline+0xb0>
				cputchar(c);
f0105257:	83 ec 0c             	sub    $0xc,%esp
f010525a:	53                   	push   %ebx
f010525b:	e8 27 b5 ff ff       	call   f0100787 <cputchar>
f0105260:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0105263:	88 9e c0 6a 2a f0    	mov    %bl,-0xfd59540(%esi)
f0105269:	8d 76 01             	lea    0x1(%esi),%esi
f010526c:	e9 77 ff ff ff       	jmp    f01051e8 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0105271:	83 fb 0d             	cmp    $0xd,%ebx
f0105274:	74 09                	je     f010527f <readline+0xcc>
f0105276:	83 fb 0a             	cmp    $0xa,%ebx
f0105279:	0f 85 69 ff ff ff    	jne    f01051e8 <readline+0x35>
			if (echoing)
f010527f:	85 ff                	test   %edi,%edi
f0105281:	74 0d                	je     f0105290 <readline+0xdd>
				cputchar('\n');
f0105283:	83 ec 0c             	sub    $0xc,%esp
f0105286:	6a 0a                	push   $0xa
f0105288:	e8 fa b4 ff ff       	call   f0100787 <cputchar>
f010528d:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0105290:	c6 86 c0 6a 2a f0 00 	movb   $0x0,-0xfd59540(%esi)
			return buf;
f0105297:	b8 c0 6a 2a f0       	mov    $0xf02a6ac0,%eax
		}
	}
}
f010529c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010529f:	5b                   	pop    %ebx
f01052a0:	5e                   	pop    %esi
f01052a1:	5f                   	pop    %edi
f01052a2:	5d                   	pop    %ebp
f01052a3:	c3                   	ret    

f01052a4 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01052a4:	55                   	push   %ebp
f01052a5:	89 e5                	mov    %esp,%ebp
f01052a7:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01052aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01052af:	eb 03                	jmp    f01052b4 <strlen+0x10>
		n++;
f01052b1:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01052b4:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01052b8:	75 f7                	jne    f01052b1 <strlen+0xd>
		n++;
	return n;
}
f01052ba:	5d                   	pop    %ebp
f01052bb:	c3                   	ret    

f01052bc <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01052bc:	55                   	push   %ebp
f01052bd:	89 e5                	mov    %esp,%ebp
f01052bf:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01052c2:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01052c5:	ba 00 00 00 00       	mov    $0x0,%edx
f01052ca:	eb 03                	jmp    f01052cf <strnlen+0x13>
		n++;
f01052cc:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01052cf:	39 c2                	cmp    %eax,%edx
f01052d1:	74 08                	je     f01052db <strnlen+0x1f>
f01052d3:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01052d7:	75 f3                	jne    f01052cc <strnlen+0x10>
f01052d9:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01052db:	5d                   	pop    %ebp
f01052dc:	c3                   	ret    

f01052dd <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01052dd:	55                   	push   %ebp
f01052de:	89 e5                	mov    %esp,%ebp
f01052e0:	53                   	push   %ebx
f01052e1:	8b 45 08             	mov    0x8(%ebp),%eax
f01052e4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01052e7:	89 c2                	mov    %eax,%edx
f01052e9:	83 c2 01             	add    $0x1,%edx
f01052ec:	83 c1 01             	add    $0x1,%ecx
f01052ef:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01052f3:	88 5a ff             	mov    %bl,-0x1(%edx)
f01052f6:	84 db                	test   %bl,%bl
f01052f8:	75 ef                	jne    f01052e9 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01052fa:	5b                   	pop    %ebx
f01052fb:	5d                   	pop    %ebp
f01052fc:	c3                   	ret    

f01052fd <strcat>:

char *
strcat(char *dst, const char *src)
{
f01052fd:	55                   	push   %ebp
f01052fe:	89 e5                	mov    %esp,%ebp
f0105300:	53                   	push   %ebx
f0105301:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0105304:	53                   	push   %ebx
f0105305:	e8 9a ff ff ff       	call   f01052a4 <strlen>
f010530a:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010530d:	ff 75 0c             	pushl  0xc(%ebp)
f0105310:	01 d8                	add    %ebx,%eax
f0105312:	50                   	push   %eax
f0105313:	e8 c5 ff ff ff       	call   f01052dd <strcpy>
	return dst;
}
f0105318:	89 d8                	mov    %ebx,%eax
f010531a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010531d:	c9                   	leave  
f010531e:	c3                   	ret    

f010531f <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010531f:	55                   	push   %ebp
f0105320:	89 e5                	mov    %esp,%ebp
f0105322:	56                   	push   %esi
f0105323:	53                   	push   %ebx
f0105324:	8b 75 08             	mov    0x8(%ebp),%esi
f0105327:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010532a:	89 f3                	mov    %esi,%ebx
f010532c:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010532f:	89 f2                	mov    %esi,%edx
f0105331:	eb 0f                	jmp    f0105342 <strncpy+0x23>
		*dst++ = *src;
f0105333:	83 c2 01             	add    $0x1,%edx
f0105336:	0f b6 01             	movzbl (%ecx),%eax
f0105339:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010533c:	80 39 01             	cmpb   $0x1,(%ecx)
f010533f:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105342:	39 da                	cmp    %ebx,%edx
f0105344:	75 ed                	jne    f0105333 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0105346:	89 f0                	mov    %esi,%eax
f0105348:	5b                   	pop    %ebx
f0105349:	5e                   	pop    %esi
f010534a:	5d                   	pop    %ebp
f010534b:	c3                   	ret    

f010534c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010534c:	55                   	push   %ebp
f010534d:	89 e5                	mov    %esp,%ebp
f010534f:	56                   	push   %esi
f0105350:	53                   	push   %ebx
f0105351:	8b 75 08             	mov    0x8(%ebp),%esi
f0105354:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105357:	8b 55 10             	mov    0x10(%ebp),%edx
f010535a:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010535c:	85 d2                	test   %edx,%edx
f010535e:	74 21                	je     f0105381 <strlcpy+0x35>
f0105360:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0105364:	89 f2                	mov    %esi,%edx
f0105366:	eb 09                	jmp    f0105371 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0105368:	83 c2 01             	add    $0x1,%edx
f010536b:	83 c1 01             	add    $0x1,%ecx
f010536e:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0105371:	39 c2                	cmp    %eax,%edx
f0105373:	74 09                	je     f010537e <strlcpy+0x32>
f0105375:	0f b6 19             	movzbl (%ecx),%ebx
f0105378:	84 db                	test   %bl,%bl
f010537a:	75 ec                	jne    f0105368 <strlcpy+0x1c>
f010537c:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010537e:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105381:	29 f0                	sub    %esi,%eax
}
f0105383:	5b                   	pop    %ebx
f0105384:	5e                   	pop    %esi
f0105385:	5d                   	pop    %ebp
f0105386:	c3                   	ret    

f0105387 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0105387:	55                   	push   %ebp
f0105388:	89 e5                	mov    %esp,%ebp
f010538a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010538d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105390:	eb 06                	jmp    f0105398 <strcmp+0x11>
		p++, q++;
f0105392:	83 c1 01             	add    $0x1,%ecx
f0105395:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0105398:	0f b6 01             	movzbl (%ecx),%eax
f010539b:	84 c0                	test   %al,%al
f010539d:	74 04                	je     f01053a3 <strcmp+0x1c>
f010539f:	3a 02                	cmp    (%edx),%al
f01053a1:	74 ef                	je     f0105392 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01053a3:	0f b6 c0             	movzbl %al,%eax
f01053a6:	0f b6 12             	movzbl (%edx),%edx
f01053a9:	29 d0                	sub    %edx,%eax
}
f01053ab:	5d                   	pop    %ebp
f01053ac:	c3                   	ret    

f01053ad <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01053ad:	55                   	push   %ebp
f01053ae:	89 e5                	mov    %esp,%ebp
f01053b0:	53                   	push   %ebx
f01053b1:	8b 45 08             	mov    0x8(%ebp),%eax
f01053b4:	8b 55 0c             	mov    0xc(%ebp),%edx
f01053b7:	89 c3                	mov    %eax,%ebx
f01053b9:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01053bc:	eb 06                	jmp    f01053c4 <strncmp+0x17>
		n--, p++, q++;
f01053be:	83 c0 01             	add    $0x1,%eax
f01053c1:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01053c4:	39 d8                	cmp    %ebx,%eax
f01053c6:	74 15                	je     f01053dd <strncmp+0x30>
f01053c8:	0f b6 08             	movzbl (%eax),%ecx
f01053cb:	84 c9                	test   %cl,%cl
f01053cd:	74 04                	je     f01053d3 <strncmp+0x26>
f01053cf:	3a 0a                	cmp    (%edx),%cl
f01053d1:	74 eb                	je     f01053be <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01053d3:	0f b6 00             	movzbl (%eax),%eax
f01053d6:	0f b6 12             	movzbl (%edx),%edx
f01053d9:	29 d0                	sub    %edx,%eax
f01053db:	eb 05                	jmp    f01053e2 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01053dd:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01053e2:	5b                   	pop    %ebx
f01053e3:	5d                   	pop    %ebp
f01053e4:	c3                   	ret    

f01053e5 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01053e5:	55                   	push   %ebp
f01053e6:	89 e5                	mov    %esp,%ebp
f01053e8:	8b 45 08             	mov    0x8(%ebp),%eax
f01053eb:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01053ef:	eb 07                	jmp    f01053f8 <strchr+0x13>
		if (*s == c)
f01053f1:	38 ca                	cmp    %cl,%dl
f01053f3:	74 0f                	je     f0105404 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01053f5:	83 c0 01             	add    $0x1,%eax
f01053f8:	0f b6 10             	movzbl (%eax),%edx
f01053fb:	84 d2                	test   %dl,%dl
f01053fd:	75 f2                	jne    f01053f1 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01053ff:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105404:	5d                   	pop    %ebp
f0105405:	c3                   	ret    

f0105406 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0105406:	55                   	push   %ebp
f0105407:	89 e5                	mov    %esp,%ebp
f0105409:	8b 45 08             	mov    0x8(%ebp),%eax
f010540c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105410:	eb 03                	jmp    f0105415 <strfind+0xf>
f0105412:	83 c0 01             	add    $0x1,%eax
f0105415:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0105418:	84 d2                	test   %dl,%dl
f010541a:	74 04                	je     f0105420 <strfind+0x1a>
f010541c:	38 ca                	cmp    %cl,%dl
f010541e:	75 f2                	jne    f0105412 <strfind+0xc>
			break;
	return (char *) s;
}
f0105420:	5d                   	pop    %ebp
f0105421:	c3                   	ret    

f0105422 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105422:	55                   	push   %ebp
f0105423:	89 e5                	mov    %esp,%ebp
f0105425:	57                   	push   %edi
f0105426:	56                   	push   %esi
f0105427:	53                   	push   %ebx
f0105428:	8b 7d 08             	mov    0x8(%ebp),%edi
f010542b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010542e:	85 c9                	test   %ecx,%ecx
f0105430:	74 36                	je     f0105468 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0105432:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0105438:	75 28                	jne    f0105462 <memset+0x40>
f010543a:	f6 c1 03             	test   $0x3,%cl
f010543d:	75 23                	jne    f0105462 <memset+0x40>
		c &= 0xFF;
f010543f:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0105443:	89 d3                	mov    %edx,%ebx
f0105445:	c1 e3 08             	shl    $0x8,%ebx
f0105448:	89 d6                	mov    %edx,%esi
f010544a:	c1 e6 18             	shl    $0x18,%esi
f010544d:	89 d0                	mov    %edx,%eax
f010544f:	c1 e0 10             	shl    $0x10,%eax
f0105452:	09 f0                	or     %esi,%eax
f0105454:	09 c2                	or     %eax,%edx
f0105456:	89 d0                	mov    %edx,%eax
f0105458:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010545a:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f010545d:	fc                   	cld    
f010545e:	f3 ab                	rep stos %eax,%es:(%edi)
f0105460:	eb 06                	jmp    f0105468 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105462:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105465:	fc                   	cld    
f0105466:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0105468:	89 f8                	mov    %edi,%eax
f010546a:	5b                   	pop    %ebx
f010546b:	5e                   	pop    %esi
f010546c:	5f                   	pop    %edi
f010546d:	5d                   	pop    %ebp
f010546e:	c3                   	ret    

f010546f <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010546f:	55                   	push   %ebp
f0105470:	89 e5                	mov    %esp,%ebp
f0105472:	57                   	push   %edi
f0105473:	56                   	push   %esi
f0105474:	8b 45 08             	mov    0x8(%ebp),%eax
f0105477:	8b 75 0c             	mov    0xc(%ebp),%esi
f010547a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010547d:	39 c6                	cmp    %eax,%esi
f010547f:	73 35                	jae    f01054b6 <memmove+0x47>
f0105481:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105484:	39 d0                	cmp    %edx,%eax
f0105486:	73 2e                	jae    f01054b6 <memmove+0x47>
		s += n;
		d += n;
f0105488:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f010548b:	89 d6                	mov    %edx,%esi
f010548d:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010548f:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105495:	75 13                	jne    f01054aa <memmove+0x3b>
f0105497:	f6 c1 03             	test   $0x3,%cl
f010549a:	75 0e                	jne    f01054aa <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f010549c:	83 ef 04             	sub    $0x4,%edi
f010549f:	8d 72 fc             	lea    -0x4(%edx),%esi
f01054a2:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01054a5:	fd                   	std    
f01054a6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01054a8:	eb 09                	jmp    f01054b3 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01054aa:	83 ef 01             	sub    $0x1,%edi
f01054ad:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01054b0:	fd                   	std    
f01054b1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01054b3:	fc                   	cld    
f01054b4:	eb 1d                	jmp    f01054d3 <memmove+0x64>
f01054b6:	89 f2                	mov    %esi,%edx
f01054b8:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01054ba:	f6 c2 03             	test   $0x3,%dl
f01054bd:	75 0f                	jne    f01054ce <memmove+0x5f>
f01054bf:	f6 c1 03             	test   $0x3,%cl
f01054c2:	75 0a                	jne    f01054ce <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01054c4:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01054c7:	89 c7                	mov    %eax,%edi
f01054c9:	fc                   	cld    
f01054ca:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01054cc:	eb 05                	jmp    f01054d3 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01054ce:	89 c7                	mov    %eax,%edi
f01054d0:	fc                   	cld    
f01054d1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01054d3:	5e                   	pop    %esi
f01054d4:	5f                   	pop    %edi
f01054d5:	5d                   	pop    %ebp
f01054d6:	c3                   	ret    

f01054d7 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01054d7:	55                   	push   %ebp
f01054d8:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01054da:	ff 75 10             	pushl  0x10(%ebp)
f01054dd:	ff 75 0c             	pushl  0xc(%ebp)
f01054e0:	ff 75 08             	pushl  0x8(%ebp)
f01054e3:	e8 87 ff ff ff       	call   f010546f <memmove>
}
f01054e8:	c9                   	leave  
f01054e9:	c3                   	ret    

f01054ea <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01054ea:	55                   	push   %ebp
f01054eb:	89 e5                	mov    %esp,%ebp
f01054ed:	56                   	push   %esi
f01054ee:	53                   	push   %ebx
f01054ef:	8b 45 08             	mov    0x8(%ebp),%eax
f01054f2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01054f5:	89 c6                	mov    %eax,%esi
f01054f7:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01054fa:	eb 1a                	jmp    f0105516 <memcmp+0x2c>
		if (*s1 != *s2)
f01054fc:	0f b6 08             	movzbl (%eax),%ecx
f01054ff:	0f b6 1a             	movzbl (%edx),%ebx
f0105502:	38 d9                	cmp    %bl,%cl
f0105504:	74 0a                	je     f0105510 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0105506:	0f b6 c1             	movzbl %cl,%eax
f0105509:	0f b6 db             	movzbl %bl,%ebx
f010550c:	29 d8                	sub    %ebx,%eax
f010550e:	eb 0f                	jmp    f010551f <memcmp+0x35>
		s1++, s2++;
f0105510:	83 c0 01             	add    $0x1,%eax
f0105513:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105516:	39 f0                	cmp    %esi,%eax
f0105518:	75 e2                	jne    f01054fc <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010551a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010551f:	5b                   	pop    %ebx
f0105520:	5e                   	pop    %esi
f0105521:	5d                   	pop    %ebp
f0105522:	c3                   	ret    

f0105523 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105523:	55                   	push   %ebp
f0105524:	89 e5                	mov    %esp,%ebp
f0105526:	8b 45 08             	mov    0x8(%ebp),%eax
f0105529:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010552c:	89 c2                	mov    %eax,%edx
f010552e:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0105531:	eb 07                	jmp    f010553a <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0105533:	38 08                	cmp    %cl,(%eax)
f0105535:	74 07                	je     f010553e <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0105537:	83 c0 01             	add    $0x1,%eax
f010553a:	39 d0                	cmp    %edx,%eax
f010553c:	72 f5                	jb     f0105533 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010553e:	5d                   	pop    %ebp
f010553f:	c3                   	ret    

f0105540 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105540:	55                   	push   %ebp
f0105541:	89 e5                	mov    %esp,%ebp
f0105543:	57                   	push   %edi
f0105544:	56                   	push   %esi
f0105545:	53                   	push   %ebx
f0105546:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105549:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010554c:	eb 03                	jmp    f0105551 <strtol+0x11>
		s++;
f010554e:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105551:	0f b6 01             	movzbl (%ecx),%eax
f0105554:	3c 09                	cmp    $0x9,%al
f0105556:	74 f6                	je     f010554e <strtol+0xe>
f0105558:	3c 20                	cmp    $0x20,%al
f010555a:	74 f2                	je     f010554e <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010555c:	3c 2b                	cmp    $0x2b,%al
f010555e:	75 0a                	jne    f010556a <strtol+0x2a>
		s++;
f0105560:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0105563:	bf 00 00 00 00       	mov    $0x0,%edi
f0105568:	eb 10                	jmp    f010557a <strtol+0x3a>
f010556a:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010556f:	3c 2d                	cmp    $0x2d,%al
f0105571:	75 07                	jne    f010557a <strtol+0x3a>
		s++, neg = 1;
f0105573:	8d 49 01             	lea    0x1(%ecx),%ecx
f0105576:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010557a:	85 db                	test   %ebx,%ebx
f010557c:	0f 94 c0             	sete   %al
f010557f:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0105585:	75 19                	jne    f01055a0 <strtol+0x60>
f0105587:	80 39 30             	cmpb   $0x30,(%ecx)
f010558a:	75 14                	jne    f01055a0 <strtol+0x60>
f010558c:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0105590:	0f 85 82 00 00 00    	jne    f0105618 <strtol+0xd8>
		s += 2, base = 16;
f0105596:	83 c1 02             	add    $0x2,%ecx
f0105599:	bb 10 00 00 00       	mov    $0x10,%ebx
f010559e:	eb 16                	jmp    f01055b6 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f01055a0:	84 c0                	test   %al,%al
f01055a2:	74 12                	je     f01055b6 <strtol+0x76>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01055a4:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01055a9:	80 39 30             	cmpb   $0x30,(%ecx)
f01055ac:	75 08                	jne    f01055b6 <strtol+0x76>
		s++, base = 8;
f01055ae:	83 c1 01             	add    $0x1,%ecx
f01055b1:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01055b6:	b8 00 00 00 00       	mov    $0x0,%eax
f01055bb:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01055be:	0f b6 11             	movzbl (%ecx),%edx
f01055c1:	8d 72 d0             	lea    -0x30(%edx),%esi
f01055c4:	89 f3                	mov    %esi,%ebx
f01055c6:	80 fb 09             	cmp    $0x9,%bl
f01055c9:	77 08                	ja     f01055d3 <strtol+0x93>
			dig = *s - '0';
f01055cb:	0f be d2             	movsbl %dl,%edx
f01055ce:	83 ea 30             	sub    $0x30,%edx
f01055d1:	eb 22                	jmp    f01055f5 <strtol+0xb5>
		else if (*s >= 'a' && *s <= 'z')
f01055d3:	8d 72 9f             	lea    -0x61(%edx),%esi
f01055d6:	89 f3                	mov    %esi,%ebx
f01055d8:	80 fb 19             	cmp    $0x19,%bl
f01055db:	77 08                	ja     f01055e5 <strtol+0xa5>
			dig = *s - 'a' + 10;
f01055dd:	0f be d2             	movsbl %dl,%edx
f01055e0:	83 ea 57             	sub    $0x57,%edx
f01055e3:	eb 10                	jmp    f01055f5 <strtol+0xb5>
		else if (*s >= 'A' && *s <= 'Z')
f01055e5:	8d 72 bf             	lea    -0x41(%edx),%esi
f01055e8:	89 f3                	mov    %esi,%ebx
f01055ea:	80 fb 19             	cmp    $0x19,%bl
f01055ed:	77 16                	ja     f0105605 <strtol+0xc5>
			dig = *s - 'A' + 10;
f01055ef:	0f be d2             	movsbl %dl,%edx
f01055f2:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01055f5:	3b 55 10             	cmp    0x10(%ebp),%edx
f01055f8:	7d 0f                	jge    f0105609 <strtol+0xc9>
			break;
		s++, val = (val * base) + dig;
f01055fa:	83 c1 01             	add    $0x1,%ecx
f01055fd:	0f af 45 10          	imul   0x10(%ebp),%eax
f0105601:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0105603:	eb b9                	jmp    f01055be <strtol+0x7e>
f0105605:	89 c2                	mov    %eax,%edx
f0105607:	eb 02                	jmp    f010560b <strtol+0xcb>
f0105609:	89 c2                	mov    %eax,%edx

	if (endptr)
f010560b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010560f:	74 0d                	je     f010561e <strtol+0xde>
		*endptr = (char *) s;
f0105611:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105614:	89 0e                	mov    %ecx,(%esi)
f0105616:	eb 06                	jmp    f010561e <strtol+0xde>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105618:	84 c0                	test   %al,%al
f010561a:	75 92                	jne    f01055ae <strtol+0x6e>
f010561c:	eb 98                	jmp    f01055b6 <strtol+0x76>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010561e:	f7 da                	neg    %edx
f0105620:	85 ff                	test   %edi,%edi
f0105622:	0f 45 c2             	cmovne %edx,%eax
}
f0105625:	5b                   	pop    %ebx
f0105626:	5e                   	pop    %esi
f0105627:	5f                   	pop    %edi
f0105628:	5d                   	pop    %ebp
f0105629:	c3                   	ret    
f010562a:	66 90                	xchg   %ax,%ax

f010562c <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f010562c:	fa                   	cli    

	xorw    %ax, %ax
f010562d:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f010562f:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105631:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105633:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0105635:	0f 01 16             	lgdtl  (%esi)
f0105638:	74 70                	je     f01056aa <mpsearch1+0x3>
	movl    %cr0, %eax
f010563a:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f010563d:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0105641:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0105644:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f010564a:	08 00                	or     %al,(%eax)

f010564c <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f010564c:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0105650:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105652:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105654:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0105656:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f010565a:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f010565c:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f010565e:	b8 00 10 12 00       	mov    $0x121000,%eax
	movl    %eax, %cr3
f0105663:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0105666:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0105669:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f010566e:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0105671:	8b 25 d0 6e 2a f0    	mov    0xf02a6ed0,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0105677:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f010567c:	b8 d2 01 10 f0       	mov    $0xf01001d2,%eax
	call    *%eax
f0105681:	ff d0                	call   *%eax

f0105683 <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0105683:	eb fe                	jmp    f0105683 <spin>
f0105685:	8d 76 00             	lea    0x0(%esi),%esi

f0105688 <gdt>:
	...
f0105690:	ff                   	(bad)  
f0105691:	ff 00                	incl   (%eax)
f0105693:	00 00                	add    %al,(%eax)
f0105695:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f010569c:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

f01056a0 <gdtdesc>:
f01056a0:	17                   	pop    %ss
f01056a1:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f01056a6 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f01056a6:	90                   	nop

f01056a7 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f01056a7:	55                   	push   %ebp
f01056a8:	89 e5                	mov    %esp,%ebp
f01056aa:	57                   	push   %edi
f01056ab:	56                   	push   %esi
f01056ac:	53                   	push   %ebx
f01056ad:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01056b0:	8b 0d d8 6e 2a f0    	mov    0xf02a6ed8,%ecx
f01056b6:	89 c3                	mov    %eax,%ebx
f01056b8:	c1 eb 0c             	shr    $0xc,%ebx
f01056bb:	39 cb                	cmp    %ecx,%ebx
f01056bd:	72 12                	jb     f01056d1 <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01056bf:	50                   	push   %eax
f01056c0:	68 e4 68 10 f0       	push   $0xf01068e4
f01056c5:	6a 57                	push   $0x57
f01056c7:	68 49 86 10 f0       	push   $0xf0108649
f01056cc:	e8 6f a9 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01056d1:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f01056d7:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01056d9:	89 c2                	mov    %eax,%edx
f01056db:	c1 ea 0c             	shr    $0xc,%edx
f01056de:	39 d1                	cmp    %edx,%ecx
f01056e0:	77 12                	ja     f01056f4 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01056e2:	50                   	push   %eax
f01056e3:	68 e4 68 10 f0       	push   $0xf01068e4
f01056e8:	6a 57                	push   $0x57
f01056ea:	68 49 86 10 f0       	push   $0xf0108649
f01056ef:	e8 4c a9 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01056f4:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f01056fa:	eb 2f                	jmp    f010572b <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01056fc:	83 ec 04             	sub    $0x4,%esp
f01056ff:	6a 04                	push   $0x4
f0105701:	68 59 86 10 f0       	push   $0xf0108659
f0105706:	53                   	push   %ebx
f0105707:	e8 de fd ff ff       	call   f01054ea <memcmp>
f010570c:	83 c4 10             	add    $0x10,%esp
f010570f:	85 c0                	test   %eax,%eax
f0105711:	75 15                	jne    f0105728 <mpsearch1+0x81>
f0105713:	89 da                	mov    %ebx,%edx
f0105715:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f0105718:	0f b6 0a             	movzbl (%edx),%ecx
f010571b:	01 c8                	add    %ecx,%eax
f010571d:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105720:	39 fa                	cmp    %edi,%edx
f0105722:	75 f4                	jne    f0105718 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105724:	84 c0                	test   %al,%al
f0105726:	74 0e                	je     f0105736 <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0105728:	83 c3 10             	add    $0x10,%ebx
f010572b:	39 f3                	cmp    %esi,%ebx
f010572d:	72 cd                	jb     f01056fc <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f010572f:	b8 00 00 00 00       	mov    $0x0,%eax
f0105734:	eb 02                	jmp    f0105738 <mpsearch1+0x91>
f0105736:	89 d8                	mov    %ebx,%eax
}
f0105738:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010573b:	5b                   	pop    %ebx
f010573c:	5e                   	pop    %esi
f010573d:	5f                   	pop    %edi
f010573e:	5d                   	pop    %ebp
f010573f:	c3                   	ret    

f0105740 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0105740:	55                   	push   %ebp
f0105741:	89 e5                	mov    %esp,%ebp
f0105743:	57                   	push   %edi
f0105744:	56                   	push   %esi
f0105745:	53                   	push   %ebx
f0105746:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105749:	c7 05 e0 73 2a f0 40 	movl   $0xf02a7040,0xf02a73e0
f0105750:	70 2a f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105753:	83 3d d8 6e 2a f0 00 	cmpl   $0x0,0xf02a6ed8
f010575a:	75 16                	jne    f0105772 <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010575c:	68 00 04 00 00       	push   $0x400
f0105761:	68 e4 68 10 f0       	push   $0xf01068e4
f0105766:	6a 6f                	push   $0x6f
f0105768:	68 49 86 10 f0       	push   $0xf0108649
f010576d:	e8 ce a8 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0105772:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105779:	85 c0                	test   %eax,%eax
f010577b:	74 16                	je     f0105793 <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
f010577d:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f0105780:	ba 00 04 00 00       	mov    $0x400,%edx
f0105785:	e8 1d ff ff ff       	call   f01056a7 <mpsearch1>
f010578a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010578d:	85 c0                	test   %eax,%eax
f010578f:	75 3c                	jne    f01057cd <mp_init+0x8d>
f0105791:	eb 20                	jmp    f01057b3 <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
f0105793:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f010579a:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f010579d:	2d 00 04 00 00       	sub    $0x400,%eax
f01057a2:	ba 00 04 00 00       	mov    $0x400,%edx
f01057a7:	e8 fb fe ff ff       	call   f01056a7 <mpsearch1>
f01057ac:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01057af:	85 c0                	test   %eax,%eax
f01057b1:	75 1a                	jne    f01057cd <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f01057b3:	ba 00 00 01 00       	mov    $0x10000,%edx
f01057b8:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f01057bd:	e8 e5 fe ff ff       	call   f01056a7 <mpsearch1>
f01057c2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f01057c5:	85 c0                	test   %eax,%eax
f01057c7:	0f 84 5a 02 00 00    	je     f0105a27 <mp_init+0x2e7>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f01057cd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01057d0:	8b 70 04             	mov    0x4(%eax),%esi
f01057d3:	85 f6                	test   %esi,%esi
f01057d5:	74 06                	je     f01057dd <mp_init+0x9d>
f01057d7:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f01057db:	74 15                	je     f01057f2 <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f01057dd:	83 ec 0c             	sub    $0xc,%esp
f01057e0:	68 bc 84 10 f0       	push   $0xf01084bc
f01057e5:	e8 60 e0 ff ff       	call   f010384a <cprintf>
f01057ea:	83 c4 10             	add    $0x10,%esp
f01057ed:	e9 35 02 00 00       	jmp    f0105a27 <mp_init+0x2e7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01057f2:	89 f0                	mov    %esi,%eax
f01057f4:	c1 e8 0c             	shr    $0xc,%eax
f01057f7:	3b 05 d8 6e 2a f0    	cmp    0xf02a6ed8,%eax
f01057fd:	72 15                	jb     f0105814 <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01057ff:	56                   	push   %esi
f0105800:	68 e4 68 10 f0       	push   $0xf01068e4
f0105805:	68 90 00 00 00       	push   $0x90
f010580a:	68 49 86 10 f0       	push   $0xf0108649
f010580f:	e8 2c a8 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105814:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f010581a:	83 ec 04             	sub    $0x4,%esp
f010581d:	6a 04                	push   $0x4
f010581f:	68 5e 86 10 f0       	push   $0xf010865e
f0105824:	53                   	push   %ebx
f0105825:	e8 c0 fc ff ff       	call   f01054ea <memcmp>
f010582a:	83 c4 10             	add    $0x10,%esp
f010582d:	85 c0                	test   %eax,%eax
f010582f:	74 15                	je     f0105846 <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0105831:	83 ec 0c             	sub    $0xc,%esp
f0105834:	68 ec 84 10 f0       	push   $0xf01084ec
f0105839:	e8 0c e0 ff ff       	call   f010384a <cprintf>
f010583e:	83 c4 10             	add    $0x10,%esp
f0105841:	e9 e1 01 00 00       	jmp    f0105a27 <mp_init+0x2e7>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105846:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f010584a:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f010584e:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105851:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105856:	b8 00 00 00 00       	mov    $0x0,%eax
f010585b:	eb 0d                	jmp    f010586a <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f010585d:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0105864:	f0 
f0105865:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105867:	83 c0 01             	add    $0x1,%eax
f010586a:	39 c7                	cmp    %eax,%edi
f010586c:	75 ef                	jne    f010585d <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f010586e:	84 d2                	test   %dl,%dl
f0105870:	74 15                	je     f0105887 <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f0105872:	83 ec 0c             	sub    $0xc,%esp
f0105875:	68 20 85 10 f0       	push   $0xf0108520
f010587a:	e8 cb df ff ff       	call   f010384a <cprintf>
f010587f:	83 c4 10             	add    $0x10,%esp
f0105882:	e9 a0 01 00 00       	jmp    f0105a27 <mp_init+0x2e7>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0105887:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f010588b:	3c 04                	cmp    $0x4,%al
f010588d:	74 1d                	je     f01058ac <mp_init+0x16c>
f010588f:	3c 01                	cmp    $0x1,%al
f0105891:	74 19                	je     f01058ac <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0105893:	83 ec 08             	sub    $0x8,%esp
f0105896:	0f b6 c0             	movzbl %al,%eax
f0105899:	50                   	push   %eax
f010589a:	68 44 85 10 f0       	push   $0xf0108544
f010589f:	e8 a6 df ff ff       	call   f010384a <cprintf>
f01058a4:	83 c4 10             	add    $0x10,%esp
f01058a7:	e9 7b 01 00 00       	jmp    f0105a27 <mp_init+0x2e7>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f01058ac:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f01058b0:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f01058b4:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f01058b9:	b8 00 00 00 00       	mov    $0x0,%eax
f01058be:	01 ce                	add    %ecx,%esi
f01058c0:	eb 0d                	jmp    f01058cf <mp_init+0x18f>
		sum += ((uint8_t *)addr)[i];
f01058c2:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f01058c9:	f0 
f01058ca:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01058cc:	83 c0 01             	add    $0x1,%eax
f01058cf:	39 c7                	cmp    %eax,%edi
f01058d1:	75 ef                	jne    f01058c2 <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f01058d3:	89 d0                	mov    %edx,%eax
f01058d5:	02 43 2a             	add    0x2a(%ebx),%al
f01058d8:	74 15                	je     f01058ef <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f01058da:	83 ec 0c             	sub    $0xc,%esp
f01058dd:	68 64 85 10 f0       	push   $0xf0108564
f01058e2:	e8 63 df ff ff       	call   f010384a <cprintf>
f01058e7:	83 c4 10             	add    $0x10,%esp
f01058ea:	e9 38 01 00 00       	jmp    f0105a27 <mp_init+0x2e7>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f01058ef:	85 db                	test   %ebx,%ebx
f01058f1:	0f 84 30 01 00 00    	je     f0105a27 <mp_init+0x2e7>
		return;
	ismp = 1;
f01058f7:	c7 05 00 70 2a f0 01 	movl   $0x1,0xf02a7000
f01058fe:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0105901:	8b 43 24             	mov    0x24(%ebx),%eax
f0105904:	a3 00 80 2e f0       	mov    %eax,0xf02e8000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105909:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f010590c:	be 00 00 00 00       	mov    $0x0,%esi
f0105911:	e9 85 00 00 00       	jmp    f010599b <mp_init+0x25b>
		switch (*p) {
f0105916:	0f b6 07             	movzbl (%edi),%eax
f0105919:	84 c0                	test   %al,%al
f010591b:	74 06                	je     f0105923 <mp_init+0x1e3>
f010591d:	3c 04                	cmp    $0x4,%al
f010591f:	77 55                	ja     f0105976 <mp_init+0x236>
f0105921:	eb 4e                	jmp    f0105971 <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0105923:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0105927:	74 11                	je     f010593a <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f0105929:	6b 05 e4 73 2a f0 74 	imul   $0x74,0xf02a73e4,%eax
f0105930:	05 40 70 2a f0       	add    $0xf02a7040,%eax
f0105935:	a3 e0 73 2a f0       	mov    %eax,0xf02a73e0
			if (ncpu < NCPU) {
f010593a:	a1 e4 73 2a f0       	mov    0xf02a73e4,%eax
f010593f:	83 f8 07             	cmp    $0x7,%eax
f0105942:	7f 13                	jg     f0105957 <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f0105944:	6b d0 74             	imul   $0x74,%eax,%edx
f0105947:	88 82 40 70 2a f0    	mov    %al,-0xfd58fc0(%edx)
				ncpu++;
f010594d:	83 c0 01             	add    $0x1,%eax
f0105950:	a3 e4 73 2a f0       	mov    %eax,0xf02a73e4
f0105955:	eb 15                	jmp    f010596c <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0105957:	83 ec 08             	sub    $0x8,%esp
f010595a:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f010595e:	50                   	push   %eax
f010595f:	68 94 85 10 f0       	push   $0xf0108594
f0105964:	e8 e1 de ff ff       	call   f010384a <cprintf>
f0105969:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f010596c:	83 c7 14             	add    $0x14,%edi
			continue;
f010596f:	eb 27                	jmp    f0105998 <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0105971:	83 c7 08             	add    $0x8,%edi
			continue;
f0105974:	eb 22                	jmp    f0105998 <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0105976:	83 ec 08             	sub    $0x8,%esp
f0105979:	0f b6 c0             	movzbl %al,%eax
f010597c:	50                   	push   %eax
f010597d:	68 bc 85 10 f0       	push   $0xf01085bc
f0105982:	e8 c3 de ff ff       	call   f010384a <cprintf>
			ismp = 0;
f0105987:	c7 05 00 70 2a f0 00 	movl   $0x0,0xf02a7000
f010598e:	00 00 00 
			i = conf->entry;
f0105991:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f0105995:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105998:	83 c6 01             	add    $0x1,%esi
f010599b:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f010599f:	39 c6                	cmp    %eax,%esi
f01059a1:	0f 82 6f ff ff ff    	jb     f0105916 <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f01059a7:	a1 e0 73 2a f0       	mov    0xf02a73e0,%eax
f01059ac:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f01059b3:	83 3d 00 70 2a f0 00 	cmpl   $0x0,0xf02a7000
f01059ba:	75 26                	jne    f01059e2 <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f01059bc:	c7 05 e4 73 2a f0 01 	movl   $0x1,0xf02a73e4
f01059c3:	00 00 00 
		lapicaddr = 0;
f01059c6:	c7 05 00 80 2e f0 00 	movl   $0x0,0xf02e8000
f01059cd:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f01059d0:	83 ec 0c             	sub    $0xc,%esp
f01059d3:	68 dc 85 10 f0       	push   $0xf01085dc
f01059d8:	e8 6d de ff ff       	call   f010384a <cprintf>
		return;
f01059dd:	83 c4 10             	add    $0x10,%esp
f01059e0:	eb 45                	jmp    f0105a27 <mp_init+0x2e7>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f01059e2:	83 ec 04             	sub    $0x4,%esp
f01059e5:	ff 35 e4 73 2a f0    	pushl  0xf02a73e4
f01059eb:	0f b6 00             	movzbl (%eax),%eax
f01059ee:	50                   	push   %eax
f01059ef:	68 63 86 10 f0       	push   $0xf0108663
f01059f4:	e8 51 de ff ff       	call   f010384a <cprintf>

	if (mp->imcrp) {
f01059f9:	83 c4 10             	add    $0x10,%esp
f01059fc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01059ff:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0105a03:	74 22                	je     f0105a27 <mp_init+0x2e7>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0105a05:	83 ec 0c             	sub    $0xc,%esp
f0105a08:	68 08 86 10 f0       	push   $0xf0108608
f0105a0d:	e8 38 de ff ff       	call   f010384a <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105a12:	ba 22 00 00 00       	mov    $0x22,%edx
f0105a17:	b8 70 00 00 00       	mov    $0x70,%eax
f0105a1c:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0105a1d:	b2 23                	mov    $0x23,%dl
f0105a1f:	ec                   	in     (%dx),%al
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f0105a20:	83 c8 01             	or     $0x1,%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105a23:	ee                   	out    %al,(%dx)
f0105a24:	83 c4 10             	add    $0x10,%esp
	}
}
f0105a27:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105a2a:	5b                   	pop    %ebx
f0105a2b:	5e                   	pop    %esi
f0105a2c:	5f                   	pop    %edi
f0105a2d:	5d                   	pop    %ebp
f0105a2e:	c3                   	ret    

f0105a2f <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f0105a2f:	55                   	push   %ebp
f0105a30:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f0105a32:	8b 0d 04 80 2e f0    	mov    0xf02e8004,%ecx
f0105a38:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0105a3b:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0105a3d:	a1 04 80 2e f0       	mov    0xf02e8004,%eax
f0105a42:	8b 40 20             	mov    0x20(%eax),%eax
}
f0105a45:	5d                   	pop    %ebp
f0105a46:	c3                   	ret    

f0105a47 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f0105a47:	55                   	push   %ebp
f0105a48:	89 e5                	mov    %esp,%ebp
	if (lapic)
f0105a4a:	a1 04 80 2e f0       	mov    0xf02e8004,%eax
f0105a4f:	85 c0                	test   %eax,%eax
f0105a51:	74 08                	je     f0105a5b <cpunum+0x14>
		return lapic[ID] >> 24;
f0105a53:	8b 40 20             	mov    0x20(%eax),%eax
f0105a56:	c1 e8 18             	shr    $0x18,%eax
f0105a59:	eb 05                	jmp    f0105a60 <cpunum+0x19>
	return 0;
f0105a5b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105a60:	5d                   	pop    %ebp
f0105a61:	c3                   	ret    

f0105a62 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0105a62:	a1 00 80 2e f0       	mov    0xf02e8000,%eax
f0105a67:	85 c0                	test   %eax,%eax
f0105a69:	0f 84 21 01 00 00    	je     f0105b90 <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f0105a6f:	55                   	push   %ebp
f0105a70:	89 e5                	mov    %esp,%ebp
f0105a72:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105a75:	68 00 10 00 00       	push   $0x1000
f0105a7a:	50                   	push   %eax
f0105a7b:	e8 43 b9 ff ff       	call   f01013c3 <mmio_map_region>
f0105a80:	a3 04 80 2e f0       	mov    %eax,0xf02e8004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105a85:	ba 27 01 00 00       	mov    $0x127,%edx
f0105a8a:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0105a8f:	e8 9b ff ff ff       	call   f0105a2f <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0105a94:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105a99:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0105a9e:	e8 8c ff ff ff       	call   f0105a2f <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0105aa3:	ba 20 00 02 00       	mov    $0x20020,%edx
f0105aa8:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0105aad:	e8 7d ff ff ff       	call   f0105a2f <lapicw>
	lapicw(TICR, 10000000); 
f0105ab2:	ba 80 96 98 00       	mov    $0x989680,%edx
f0105ab7:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0105abc:	e8 6e ff ff ff       	call   f0105a2f <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0105ac1:	e8 81 ff ff ff       	call   f0105a47 <cpunum>
f0105ac6:	6b c0 74             	imul   $0x74,%eax,%eax
f0105ac9:	05 40 70 2a f0       	add    $0xf02a7040,%eax
f0105ace:	83 c4 10             	add    $0x10,%esp
f0105ad1:	39 05 e0 73 2a f0    	cmp    %eax,0xf02a73e0
f0105ad7:	74 0f                	je     f0105ae8 <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f0105ad9:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105ade:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0105ae3:	e8 47 ff ff ff       	call   f0105a2f <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f0105ae8:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105aed:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0105af2:	e8 38 ff ff ff       	call   f0105a2f <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0105af7:	a1 04 80 2e f0       	mov    0xf02e8004,%eax
f0105afc:	8b 40 30             	mov    0x30(%eax),%eax
f0105aff:	c1 e8 10             	shr    $0x10,%eax
f0105b02:	3c 03                	cmp    $0x3,%al
f0105b04:	76 0f                	jbe    f0105b15 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f0105b06:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105b0b:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0105b10:	e8 1a ff ff ff       	call   f0105a2f <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0105b15:	ba 33 00 00 00       	mov    $0x33,%edx
f0105b1a:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0105b1f:	e8 0b ff ff ff       	call   f0105a2f <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f0105b24:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b29:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105b2e:	e8 fc fe ff ff       	call   f0105a2f <lapicw>
	lapicw(ESR, 0);
f0105b33:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b38:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105b3d:	e8 ed fe ff ff       	call   f0105a2f <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0105b42:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b47:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105b4c:	e8 de fe ff ff       	call   f0105a2f <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105b51:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b56:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105b5b:	e8 cf fe ff ff       	call   f0105a2f <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105b60:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105b65:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105b6a:	e8 c0 fe ff ff       	call   f0105a2f <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0105b6f:	8b 15 04 80 2e f0    	mov    0xf02e8004,%edx
f0105b75:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105b7b:	f6 c4 10             	test   $0x10,%ah
f0105b7e:	75 f5                	jne    f0105b75 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0105b80:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b85:	b8 20 00 00 00       	mov    $0x20,%eax
f0105b8a:	e8 a0 fe ff ff       	call   f0105a2f <lapicw>
}
f0105b8f:	c9                   	leave  
f0105b90:	f3 c3                	repz ret 

f0105b92 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105b92:	83 3d 04 80 2e f0 00 	cmpl   $0x0,0xf02e8004
f0105b99:	74 13                	je     f0105bae <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f0105b9b:	55                   	push   %ebp
f0105b9c:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0105b9e:	ba 00 00 00 00       	mov    $0x0,%edx
f0105ba3:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105ba8:	e8 82 fe ff ff       	call   f0105a2f <lapicw>
}
f0105bad:	5d                   	pop    %ebp
f0105bae:	f3 c3                	repz ret 

f0105bb0 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0105bb0:	55                   	push   %ebp
f0105bb1:	89 e5                	mov    %esp,%ebp
f0105bb3:	56                   	push   %esi
f0105bb4:	53                   	push   %ebx
f0105bb5:	8b 75 08             	mov    0x8(%ebp),%esi
f0105bb8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105bbb:	ba 70 00 00 00       	mov    $0x70,%edx
f0105bc0:	b8 0f 00 00 00       	mov    $0xf,%eax
f0105bc5:	ee                   	out    %al,(%dx)
f0105bc6:	b2 71                	mov    $0x71,%dl
f0105bc8:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105bcd:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105bce:	83 3d d8 6e 2a f0 00 	cmpl   $0x0,0xf02a6ed8
f0105bd5:	75 19                	jne    f0105bf0 <lapic_startap+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105bd7:	68 67 04 00 00       	push   $0x467
f0105bdc:	68 e4 68 10 f0       	push   $0xf01068e4
f0105be1:	68 98 00 00 00       	push   $0x98
f0105be6:	68 80 86 10 f0       	push   $0xf0108680
f0105beb:	e8 50 a4 ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0105bf0:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0105bf7:	00 00 
	wrv[1] = addr >> 4;
f0105bf9:	89 d8                	mov    %ebx,%eax
f0105bfb:	c1 e8 04             	shr    $0x4,%eax
f0105bfe:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0105c04:	c1 e6 18             	shl    $0x18,%esi
f0105c07:	89 f2                	mov    %esi,%edx
f0105c09:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105c0e:	e8 1c fe ff ff       	call   f0105a2f <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0105c13:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0105c18:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c1d:	e8 0d fe ff ff       	call   f0105a2f <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0105c22:	ba 00 85 00 00       	mov    $0x8500,%edx
f0105c27:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c2c:	e8 fe fd ff ff       	call   f0105a2f <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105c31:	c1 eb 0c             	shr    $0xc,%ebx
f0105c34:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105c37:	89 f2                	mov    %esi,%edx
f0105c39:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105c3e:	e8 ec fd ff ff       	call   f0105a2f <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105c43:	89 da                	mov    %ebx,%edx
f0105c45:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c4a:	e8 e0 fd ff ff       	call   f0105a2f <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105c4f:	89 f2                	mov    %esi,%edx
f0105c51:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105c56:	e8 d4 fd ff ff       	call   f0105a2f <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105c5b:	89 da                	mov    %ebx,%edx
f0105c5d:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c62:	e8 c8 fd ff ff       	call   f0105a2f <lapicw>
		microdelay(200);
	}
}
f0105c67:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105c6a:	5b                   	pop    %ebx
f0105c6b:	5e                   	pop    %esi
f0105c6c:	5d                   	pop    %ebp
f0105c6d:	c3                   	ret    

f0105c6e <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105c6e:	55                   	push   %ebp
f0105c6f:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105c71:	8b 55 08             	mov    0x8(%ebp),%edx
f0105c74:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0105c7a:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c7f:	e8 ab fd ff ff       	call   f0105a2f <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0105c84:	8b 15 04 80 2e f0    	mov    0xf02e8004,%edx
f0105c8a:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105c90:	f6 c4 10             	test   $0x10,%ah
f0105c93:	75 f5                	jne    f0105c8a <lapic_ipi+0x1c>
		;
}
f0105c95:	5d                   	pop    %ebp
f0105c96:	c3                   	ret    

f0105c97 <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0105c97:	55                   	push   %ebp
f0105c98:	89 e5                	mov    %esp,%ebp
f0105c9a:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0105c9d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105ca3:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105ca6:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f0105ca9:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0105cb0:	5d                   	pop    %ebp
f0105cb1:	c3                   	ret    

f0105cb2 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0105cb2:	55                   	push   %ebp
f0105cb3:	89 e5                	mov    %esp,%ebp
f0105cb5:	56                   	push   %esi
f0105cb6:	53                   	push   %ebx
f0105cb7:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105cba:	83 3b 00             	cmpl   $0x0,(%ebx)
f0105cbd:	74 14                	je     f0105cd3 <spin_lock+0x21>
f0105cbf:	8b 73 08             	mov    0x8(%ebx),%esi
f0105cc2:	e8 80 fd ff ff       	call   f0105a47 <cpunum>
f0105cc7:	6b c0 74             	imul   $0x74,%eax,%eax
f0105cca:	05 40 70 2a f0       	add    $0xf02a7040,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0105ccf:	39 c6                	cmp    %eax,%esi
f0105cd1:	74 07                	je     f0105cda <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0105cd3:	ba 01 00 00 00       	mov    $0x1,%edx
f0105cd8:	eb 20                	jmp    f0105cfa <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0105cda:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0105cdd:	e8 65 fd ff ff       	call   f0105a47 <cpunum>
f0105ce2:	83 ec 0c             	sub    $0xc,%esp
f0105ce5:	53                   	push   %ebx
f0105ce6:	50                   	push   %eax
f0105ce7:	68 90 86 10 f0       	push   $0xf0108690
f0105cec:	6a 41                	push   $0x41
f0105cee:	68 f2 86 10 f0       	push   $0xf01086f2
f0105cf3:	e8 48 a3 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0105cf8:	f3 90                	pause  
f0105cfa:	89 d0                	mov    %edx,%eax
f0105cfc:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0105cff:	85 c0                	test   %eax,%eax
f0105d01:	75 f5                	jne    f0105cf8 <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0105d03:	e8 3f fd ff ff       	call   f0105a47 <cpunum>
f0105d08:	6b c0 74             	imul   $0x74,%eax,%eax
f0105d0b:	05 40 70 2a f0       	add    $0xf02a7040,%eax
f0105d10:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0105d13:	83 c3 0c             	add    $0xc,%ebx
get_caller_pcs(uint32_t pcs[])
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
f0105d16:	89 ea                	mov    %ebp,%edx
	for (i = 0; i < 10; i++){
f0105d18:	b8 00 00 00 00       	mov    $0x0,%eax
f0105d1d:	eb 0b                	jmp    f0105d2a <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f0105d1f:	8b 4a 04             	mov    0x4(%edx),%ecx
f0105d22:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0105d25:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105d27:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105d2a:	83 f8 09             	cmp    $0x9,%eax
f0105d2d:	7f 14                	jg     f0105d43 <spin_lock+0x91>
f0105d2f:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0105d35:	77 e8                	ja     f0105d1f <spin_lock+0x6d>
f0105d37:	eb 0a                	jmp    f0105d43 <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0105d39:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0105d40:	83 c0 01             	add    $0x1,%eax
f0105d43:	83 f8 09             	cmp    $0x9,%eax
f0105d46:	7e f1                	jle    f0105d39 <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f0105d48:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105d4b:	5b                   	pop    %ebx
f0105d4c:	5e                   	pop    %esi
f0105d4d:	5d                   	pop    %ebp
f0105d4e:	c3                   	ret    

f0105d4f <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105d4f:	55                   	push   %ebp
f0105d50:	89 e5                	mov    %esp,%ebp
f0105d52:	57                   	push   %edi
f0105d53:	56                   	push   %esi
f0105d54:	53                   	push   %ebx
f0105d55:	83 ec 4c             	sub    $0x4c,%esp
f0105d58:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105d5b:	83 3e 00             	cmpl   $0x0,(%esi)
f0105d5e:	74 18                	je     f0105d78 <spin_unlock+0x29>
f0105d60:	8b 5e 08             	mov    0x8(%esi),%ebx
f0105d63:	e8 df fc ff ff       	call   f0105a47 <cpunum>
f0105d68:	6b c0 74             	imul   $0x74,%eax,%eax
f0105d6b:	05 40 70 2a f0       	add    $0xf02a7040,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0105d70:	39 c3                	cmp    %eax,%ebx
f0105d72:	0f 84 a5 00 00 00    	je     f0105e1d <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0105d78:	83 ec 04             	sub    $0x4,%esp
f0105d7b:	6a 28                	push   $0x28
f0105d7d:	8d 46 0c             	lea    0xc(%esi),%eax
f0105d80:	50                   	push   %eax
f0105d81:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0105d84:	53                   	push   %ebx
f0105d85:	e8 e5 f6 ff ff       	call   f010546f <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105d8a:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105d8d:	0f b6 38             	movzbl (%eax),%edi
f0105d90:	8b 76 04             	mov    0x4(%esi),%esi
f0105d93:	e8 af fc ff ff       	call   f0105a47 <cpunum>
f0105d98:	57                   	push   %edi
f0105d99:	56                   	push   %esi
f0105d9a:	50                   	push   %eax
f0105d9b:	68 bc 86 10 f0       	push   $0xf01086bc
f0105da0:	e8 a5 da ff ff       	call   f010384a <cprintf>
f0105da5:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0105da8:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0105dab:	eb 54                	jmp    f0105e01 <spin_unlock+0xb2>
f0105dad:	83 ec 08             	sub    $0x8,%esp
f0105db0:	57                   	push   %edi
f0105db1:	50                   	push   %eax
f0105db2:	e8 d5 eb ff ff       	call   f010498c <debuginfo_eip>
f0105db7:	83 c4 10             	add    $0x10,%esp
f0105dba:	85 c0                	test   %eax,%eax
f0105dbc:	78 27                	js     f0105de5 <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0105dbe:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0105dc0:	83 ec 04             	sub    $0x4,%esp
f0105dc3:	89 c2                	mov    %eax,%edx
f0105dc5:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0105dc8:	52                   	push   %edx
f0105dc9:	ff 75 b0             	pushl  -0x50(%ebp)
f0105dcc:	ff 75 b4             	pushl  -0x4c(%ebp)
f0105dcf:	ff 75 ac             	pushl  -0x54(%ebp)
f0105dd2:	ff 75 a8             	pushl  -0x58(%ebp)
f0105dd5:	50                   	push   %eax
f0105dd6:	68 02 87 10 f0       	push   $0xf0108702
f0105ddb:	e8 6a da ff ff       	call   f010384a <cprintf>
f0105de0:	83 c4 20             	add    $0x20,%esp
f0105de3:	eb 12                	jmp    f0105df7 <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f0105de5:	83 ec 08             	sub    $0x8,%esp
f0105de8:	ff 36                	pushl  (%esi)
f0105dea:	68 19 87 10 f0       	push   $0xf0108719
f0105def:	e8 56 da ff ff       	call   f010384a <cprintf>
f0105df4:	83 c4 10             	add    $0x10,%esp
f0105df7:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0105dfa:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0105dfd:	39 c3                	cmp    %eax,%ebx
f0105dff:	74 08                	je     f0105e09 <spin_unlock+0xba>
f0105e01:	89 de                	mov    %ebx,%esi
f0105e03:	8b 03                	mov    (%ebx),%eax
f0105e05:	85 c0                	test   %eax,%eax
f0105e07:	75 a4                	jne    f0105dad <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f0105e09:	83 ec 04             	sub    $0x4,%esp
f0105e0c:	68 21 87 10 f0       	push   $0xf0108721
f0105e11:	6a 67                	push   $0x67
f0105e13:	68 f2 86 10 f0       	push   $0xf01086f2
f0105e18:	e8 23 a2 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f0105e1d:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0105e24:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
f0105e2b:	b8 00 00 00 00       	mov    $0x0,%eax
f0105e30:	f0 87 06             	lock xchg %eax,(%esi)
	// Paper says that Intel 64 and IA-32 will not move a load
	// after a store. So lock->locked = 0 would work here.
	// The xchg being asm volatile ensures gcc emits it after
	// the above assignments (and after the critical section).
	xchg(&lk->locked, 0);
}
f0105e33:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105e36:	5b                   	pop    %ebx
f0105e37:	5e                   	pop    %esi
f0105e38:	5f                   	pop    %edi
f0105e39:	5d                   	pop    %ebp
f0105e3a:	c3                   	ret    

f0105e3b <e1000_attach_device>:
struct tx_desc tx_descArray[E1000_TX_DESCTR] __attribute__ ((aligned (16)));
struct tx_pckt tx_pcktBuffer[E1000_TX_DESCTR];

int
e1000_attach_device(struct pci_func *pcif)
{
f0105e3b:	55                   	push   %ebp
f0105e3c:	89 e5                	mov    %esp,%ebp
f0105e3e:	53                   	push   %ebx
f0105e3f:	83 ec 10             	sub    $0x10,%esp
f0105e42:	8b 5d 08             	mov    0x8(%ebp),%ebx
	uint32_t i;

	// Enable PCI device
	pci_func_enable(pcif);
f0105e45:	53                   	push   %ebx
f0105e46:	e8 ff 05 00 00       	call   f010644a <pci_func_enable>
	
	//Mapping MMIO region 
	//boot_map_region(kern_pgdir, E1000_MMIO_ADDR,
	//		pcif->reg_size[0], pcif->reg_base[0], 
	//		PTE_PCD | PTE_PWT | PTE_W);
	e1000 = (void *) mmio_map_region(pcif->reg_base[0], pcif->reg_size[0]);
f0105e4b:	83 c4 08             	add    $0x8,%esp
f0105e4e:	ff 73 2c             	pushl  0x2c(%ebx)
f0105e51:	ff 73 14             	pushl  0x14(%ebx)
f0105e54:	e8 6a b5 ff ff       	call   f01013c3 <mmio_map_region>
f0105e59:	a3 d4 6e 2a f0       	mov    %eax,0xf02a6ed4
	
	assert(e1000[E1000_STATUS] == 0x80080783);
f0105e5e:	8b 50 08             	mov    0x8(%eax),%edx
f0105e61:	83 c4 10             	add    $0x10,%esp
f0105e64:	81 fa 83 07 08 80    	cmp    $0x80080783,%edx
f0105e6a:	74 16                	je     f0105e82 <e1000_attach_device+0x47>
f0105e6c:	68 3c 87 10 f0       	push   $0xf010873c
f0105e71:	68 9b 78 10 f0       	push   $0xf010789b
f0105e76:	6a 1b                	push   $0x1b
f0105e78:	68 5e 87 10 f0       	push   $0xf010875e
f0105e7d:	e8 be a1 ff ff       	call   f0100040 <_panic>
	cprintf("E1000 status value: %08x\n", e1000[E1000_STATUS]);
f0105e82:	8b 40 08             	mov    0x8(%eax),%eax
f0105e85:	83 ec 08             	sub    $0x8,%esp
f0105e88:	50                   	push   %eax
f0105e89:	68 6b 87 10 f0       	push   $0xf010876b
f0105e8e:	e8 b7 d9 ff ff       	call   f010384a <cprintf>


	//Transmit Initlialization
	//Clear the areas allocated by the software for the descriptors and buffers 
	memset(tx_descArray, 0x0, sizeof(struct tx_desc) * E1000_TX_DESCTR);
f0105e93:	83 c4 0c             	add    $0xc,%esp
f0105e96:	68 00 04 00 00       	push   $0x400
f0105e9b:	6a 00                	push   $0x0
f0105e9d:	68 40 80 2e f0       	push   $0xf02e8040
f0105ea2:	e8 7b f5 ff ff       	call   f0105422 <memset>
	memset(tx_pcktBuffer, 0x0, sizeof(struct tx_pckt) * E1000_TX_DESCTR);
f0105ea7:	83 c4 0c             	add    $0xc,%esp
f0105eaa:	68 80 7b 01 00       	push   $0x17b80
f0105eaf:	6a 00                	push   $0x0
f0105eb1:	68 40 84 2e f0       	push   $0xf02e8440
f0105eb6:	e8 67 f5 ff ff       	call   f0105422 <memset>
f0105ebb:	b8 40 84 2e f0       	mov    $0xf02e8440,%eax
f0105ec0:	ba 4c 80 2e f0       	mov    $0xf02e804c,%edx
f0105ec5:	bb c0 ff 2f f0       	mov    $0xf02fffc0,%ebx
f0105eca:	83 c4 10             	add    $0x10,%esp
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0105ecd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0105ed2:	77 12                	ja     f0105ee6 <e1000_attach_device+0xab>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0105ed4:	50                   	push   %eax
f0105ed5:	68 08 69 10 f0       	push   $0xf0106908
f0105eda:	6a 24                	push   $0x24
f0105edc:	68 5e 87 10 f0       	push   $0xf010875e
f0105ee1:	e8 5a a1 ff ff       	call   f0100040 <_panic>
f0105ee6:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
	for (i = 0; i < E1000_TX_DESCTR; i++) {
		tx_descArray[i].addr = PADDR(tx_pcktBuffer[i].buf);
f0105eec:	89 4a f4             	mov    %ecx,-0xc(%edx)
f0105eef:	c7 42 f8 00 00 00 00 	movl   $0x0,-0x8(%edx)
		tx_descArray[i].status |= E1000_TXD_STAT_DD;
f0105ef6:	80 0a 01             	orb    $0x1,(%edx)
f0105ef9:	05 ee 05 00 00       	add    $0x5ee,%eax
f0105efe:	83 c2 10             	add    $0x10,%edx

	//Transmit Initlialization
	//Clear the areas allocated by the software for the descriptors and buffers 
	memset(tx_descArray, 0x0, sizeof(struct tx_desc) * E1000_TX_DESCTR);
	memset(tx_pcktBuffer, 0x0, sizeof(struct tx_pckt) * E1000_TX_DESCTR);
	for (i = 0; i < E1000_TX_DESCTR; i++) {
f0105f01:	39 d8                	cmp    %ebx,%eax
f0105f03:	75 c8                	jne    f0105ecd <e1000_attach_device+0x92>
		tx_descArray[i].status |= E1000_TXD_STAT_DD;
	}


	/*Program the Transmit Descriptor Base Address (TDBAL/TDBAH) register(s) with the address of the region.*/
	e1000[E1000_TDBAL] = PADDR(tx_descArray);	
f0105f05:	a1 d4 6e 2a f0       	mov    0xf02a6ed4,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0105f0a:	ba 40 80 2e f0       	mov    $0xf02e8040,%edx
f0105f0f:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0105f15:	77 12                	ja     f0105f29 <e1000_attach_device+0xee>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0105f17:	52                   	push   %edx
f0105f18:	68 08 69 10 f0       	push   $0xf0106908
f0105f1d:	6a 2a                	push   $0x2a
f0105f1f:	68 5e 87 10 f0       	push   $0xf010875e
f0105f24:	e8 17 a1 ff ff       	call   f0100040 <_panic>
f0105f29:	c7 80 00 38 00 00 40 	movl   $0x2e8040,0x3800(%eax)
f0105f30:	80 2e 00 
	e1000[E1000_TDBAH] = 0x0;
f0105f33:	c7 80 04 38 00 00 00 	movl   $0x0,0x3804(%eax)
f0105f3a:	00 00 00 

	/*Set the Transmit Descriptor Length (TDLEN) register to the size (in bytes) of the descriptor ring.
	This register must be 128-byte aligned.*/
	e1000[E1000_TDLEN] = sizeof(struct tx_desc) * E1000_TX_DESCTR;
f0105f3d:	c7 80 08 38 00 00 00 	movl   $0x400,0x3808(%eax)
f0105f44:	04 00 00 

	/*The Transmit Descriptor Head and Tail (TDH/TDT) registers are initialized (by hardware) to 0.
	Software should write 0b to both these registers to ensure this.*/
	e1000[E1000_TDH] = 0x0;
f0105f47:	c7 80 10 38 00 00 00 	movl   $0x0,0x3810(%eax)
f0105f4e:	00 00 00 
	e1000[E1000_TDT] = 0x0;
f0105f51:	c7 80 18 38 00 00 00 	movl   $0x0,0x3818(%eax)
f0105f58:	00 00 00 

	/*Initialize the Transmit Control Register (TCTL) for desired operation to include the following:

	• Set the Enable (TCTL.EN) bit to 1b for normal operation. */
	e1000[E1000_TCTL] |= E1000_TCTL_EN;
f0105f5b:	8b 90 00 04 00 00    	mov    0x400(%eax),%edx
f0105f61:	83 ca 02             	or     $0x2,%edx
f0105f64:	89 90 00 04 00 00    	mov    %edx,0x400(%eax)

	/*• Set the Pad Short Packets (TCTL.PSP) bit to 1b.*/
	e1000[E1000_TCTL] |= E1000_TCTL_PSP;
f0105f6a:	8b 90 00 04 00 00    	mov    0x400(%eax),%edx
f0105f70:	83 ca 08             	or     $0x8,%edx
f0105f73:	89 90 00 04 00 00    	mov    %edx,0x400(%eax)

	/*Configure the Collision Threshold (TCTL.CT) to the desired value.The value is 10h*/
	e1000[E1000_TCTL] &= ~E1000_TCTL_CT;	//Clear the specified bits first
f0105f79:	8b 90 00 04 00 00    	mov    0x400(%eax),%edx
f0105f7f:	81 e2 0f f0 ff ff    	and    $0xfffff00f,%edx
f0105f85:	89 90 00 04 00 00    	mov    %edx,0x400(%eax)
	e1000[E1000_TCTL] |= (0x10) << 4;		//Set the values as required to 10h
f0105f8b:	8b 90 00 04 00 00    	mov    0x400(%eax),%edx
f0105f91:	80 ce 01             	or     $0x1,%dh
f0105f94:	89 90 00 04 00 00    	mov    %edx,0x400(%eax)

	/*Configure the Collision Distance (TCTL.COLD) to its expected value.For full duplex
	operation, this value should be set to 40h */
	e1000[E1000_TCTL] &= ~E1000_TCTL_COLD;	//Clear the specified bits first
f0105f9a:	8b 90 00 04 00 00    	mov    0x400(%eax),%edx
f0105fa0:	81 e2 ff 0f c0 ff    	and    $0xffc00fff,%edx
f0105fa6:	89 90 00 04 00 00    	mov    %edx,0x400(%eax)
	e1000[E1000_TCTL] |= (0x40) << 12;		//Set the value to 40h for full duplex
f0105fac:	8b 90 00 04 00 00    	mov    0x400(%eax),%edx
f0105fb2:	81 ca 00 00 04 00    	or     $0x40000,%edx
f0105fb8:	89 90 00 04 00 00    	mov    %edx,0x400(%eax)

	/*Program the Transmit IPG (TIPG) register*/
	e1000[E1000_TIPG] = 0x0;
f0105fbe:	c7 80 10 04 00 00 00 	movl   $0x0,0x410(%eax)
f0105fc5:	00 00 00 
	
	/*IPG Receive Time 2
	Specifies the total length of the IPG time for non back-to-back
	transmissions.
	IPGR2 In order to calculate the actual IPG value, a value of six should be added to the IPGR2 value*/
	e1000[E1000_TIPG] |= (0x6) << 20; 
f0105fc8:	8b 90 10 04 00 00    	mov    0x410(%eax),%edx
f0105fce:	81 ca 00 00 60 00    	or     $0x600000,%edx
f0105fd4:	89 90 10 04 00 00    	mov    %edx,0x410(%eax)
	to-back transmissions. During this time, the internal IPG counter
	restarts if any carrier event occurs. Once the time specified in
	IPGR1 has elapsed, carrier sense does not affect the IPG
	counter.
	According to the IEEE802.3 standard, IPGR1 should be 2/3 of IPGR2 value.*/
	e1000[E1000_TIPG] |= (0x4) << 10; // IPGR1
f0105fda:	8b 90 10 04 00 00    	mov    0x410(%eax),%edx
f0105fe0:	80 ce 10             	or     $0x10,%dh
f0105fe3:	89 90 10 04 00 00    	mov    %edx,0x410(%eax)

	/*PG Transmit Time
	Specifies the IPG time for back-to-back packet transmissions*/
	e1000[E1000_TIPG] |= 0xA; // IPGT should be 10
f0105fe9:	8b 90 10 04 00 00    	mov    0x410(%eax),%edx
f0105fef:	83 ca 0a             	or     $0xa,%edx
f0105ff2:	89 90 10 04 00 00    	mov    %edx,0x410(%eax)
	char b[] = "This is a test function";
	e1000_Transmit_packet(a, sizeof(a));
	e1000_Transmit_packet(b, sizeof(b));
	*/
	return 0;
}
f0105ff8:	b8 00 00 00 00       	mov    $0x0,%eax
f0105ffd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0106000:	c9                   	leave  
f0106001:	c3                   	ret    

f0106002 <e1000_Transmit_packet>:



int e1000_Transmit_packet(char *data, int length) //Transmit a packet of length and data
{
f0106002:	55                   	push   %ebp
f0106003:	89 e5                	mov    %esp,%ebp
f0106005:	56                   	push   %esi
f0106006:	53                   	push   %ebx
f0106007:	8b 75 0c             	mov    0xc(%ebp),%esi
	//Make sure the length is within the limits
	if (length > E1000_TX_PCKT_SIZE)
f010600a:	81 fe ee 05 00 00    	cmp    $0x5ee,%esi
f0106010:	7f 65                	jg     f0106077 <e1000_Transmit_packet+0x75>
		return -E_PCKT_LONG;

	/*Note that TDT is an index into the transmit descriptor array, not a byte offset;*/
	uint32_t tdt = e1000[E1000_TDT]; //Transmit descriptor tail register. 
f0106012:	a1 d4 6e 2a f0       	mov    0xf02a6ed4,%eax
f0106017:	8b 98 18 38 00 00    	mov    0x3818(%eax),%ebx
	
	//Checking if the TX queue has descriptors available
	if (tx_descArray[tdt].status & E1000_TXD_STAT_DD) {
f010601d:	89 d8                	mov    %ebx,%eax
f010601f:	c1 e0 04             	shl    $0x4,%eax
f0106022:	f6 80 4c 80 2e f0 01 	testb  $0x1,-0xfd17fb4(%eax)
f0106029:	74 53                	je     f010607e <e1000_Transmit_packet+0x7c>
		memmove(tx_pcktBuffer[tdt].buf, data, length);
f010602b:	83 ec 04             	sub    $0x4,%esp
f010602e:	56                   	push   %esi
f010602f:	ff 75 08             	pushl  0x8(%ebp)
f0106032:	69 c3 ee 05 00 00    	imul   $0x5ee,%ebx,%eax
f0106038:	05 40 84 2e f0       	add    $0xf02e8440,%eax
f010603d:	50                   	push   %eax
f010603e:	e8 2c f4 ff ff       	call   f010546f <memmove>
		tx_descArray[tdt].length = length;
f0106043:	89 d8                	mov    %ebx,%eax
f0106045:	c1 e0 04             	shl    $0x4,%eax
f0106048:	66 89 b0 48 80 2e f0 	mov    %si,-0xfd17fb8(%eax)
f010604f:	05 40 80 2e f0       	add    $0xf02e8040,%eax

		tx_descArray[tdt].status &= ~E1000_TXD_STAT_DD;
f0106054:	80 60 0c fe          	andb   $0xfe,0xc(%eax)
		tx_descArray[tdt].cmd |= E1000_TXD_CMD_RS;
		tx_descArray[tdt].cmd |= E1000_TXD_CMD_EOP;
f0106058:	80 48 0b 09          	orb    $0x9,0xb(%eax)

		//Update the TDT register to point to next array
		e1000[E1000_TDT] = (tdt + 1) % E1000_TX_DESCTR;
f010605c:	83 c3 01             	add    $0x1,%ebx
f010605f:	83 e3 3f             	and    $0x3f,%ebx
f0106062:	a1 d4 6e 2a f0       	mov    0xf02a6ed4,%eax
f0106067:	89 98 18 38 00 00    	mov    %ebx,0x3818(%eax)
	}
	
	else
		return -E_TX_Q_FULL;
	
	return 0;
f010606d:	83 c4 10             	add    $0x10,%esp
f0106070:	b8 00 00 00 00       	mov    $0x0,%eax
f0106075:	eb 0c                	jmp    f0106083 <e1000_Transmit_packet+0x81>

int e1000_Transmit_packet(char *data, int length) //Transmit a packet of length and data
{
	//Make sure the length is within the limits
	if (length > E1000_TX_PCKT_SIZE)
		return -E_PCKT_LONG;
f0106077:	b8 ee ff ff ff       	mov    $0xffffffee,%eax
f010607c:	eb 05                	jmp    f0106083 <e1000_Transmit_packet+0x81>
		//Update the TDT register to point to next array
		e1000[E1000_TDT] = (tdt + 1) % E1000_TX_DESCTR;
	}
	
	else
		return -E_TX_Q_FULL;
f010607e:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
	
	return 0;
}
f0106083:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0106086:	5b                   	pop    %ebx
f0106087:	5e                   	pop    %esi
f0106088:	5d                   	pop    %ebp
f0106089:	c3                   	ret    

f010608a <pci_attach_match>:
}

static int __attribute__((warn_unused_result))
pci_attach_match(uint32_t key1, uint32_t key2,
		 struct pci_driver *list, struct pci_func *pcif)
{
f010608a:	55                   	push   %ebp
f010608b:	89 e5                	mov    %esp,%ebp
f010608d:	57                   	push   %edi
f010608e:	56                   	push   %esi
f010608f:	53                   	push   %ebx
f0106090:	83 ec 0c             	sub    $0xc,%esp
f0106093:	8b 7d 08             	mov    0x8(%ebp),%edi
f0106096:	8b 45 10             	mov    0x10(%ebp),%eax
f0106099:	8d 58 08             	lea    0x8(%eax),%ebx
	uint32_t i;

	for (i = 0; list[i].attachfn; i++) {
f010609c:	eb 3a                	jmp    f01060d8 <pci_attach_match+0x4e>
		if (list[i].key1 == key1 && list[i].key2 == key2) {
f010609e:	39 7b f8             	cmp    %edi,-0x8(%ebx)
f01060a1:	75 32                	jne    f01060d5 <pci_attach_match+0x4b>
f01060a3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01060a6:	39 56 fc             	cmp    %edx,-0x4(%esi)
f01060a9:	75 2a                	jne    f01060d5 <pci_attach_match+0x4b>
			int r = list[i].attachfn(pcif);
f01060ab:	83 ec 0c             	sub    $0xc,%esp
f01060ae:	ff 75 14             	pushl  0x14(%ebp)
f01060b1:	ff d0                	call   *%eax
			if (r > 0)
f01060b3:	83 c4 10             	add    $0x10,%esp
f01060b6:	85 c0                	test   %eax,%eax
f01060b8:	7f 26                	jg     f01060e0 <pci_attach_match+0x56>
				return r;
			if (r < 0)
f01060ba:	85 c0                	test   %eax,%eax
f01060bc:	79 17                	jns    f01060d5 <pci_attach_match+0x4b>
				cprintf("pci_attach_match: attaching "
f01060be:	83 ec 0c             	sub    $0xc,%esp
f01060c1:	50                   	push   %eax
f01060c2:	ff 36                	pushl  (%esi)
f01060c4:	ff 75 0c             	pushl  0xc(%ebp)
f01060c7:	57                   	push   %edi
f01060c8:	68 88 87 10 f0       	push   $0xf0108788
f01060cd:	e8 78 d7 ff ff       	call   f010384a <cprintf>
f01060d2:	83 c4 20             	add    $0x20,%esp
f01060d5:	83 c3 0c             	add    $0xc,%ebx
f01060d8:	89 de                	mov    %ebx,%esi
pci_attach_match(uint32_t key1, uint32_t key2,
		 struct pci_driver *list, struct pci_func *pcif)
{
	uint32_t i;

	for (i = 0; list[i].attachfn; i++) {
f01060da:	8b 03                	mov    (%ebx),%eax
f01060dc:	85 c0                	test   %eax,%eax
f01060de:	75 be                	jne    f010609e <pci_attach_match+0x14>
					"%x.%x (%p): e\n",
					key1, key2, list[i].attachfn, r);
		}
	}
	return 0;
}
f01060e0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01060e3:	5b                   	pop    %ebx
f01060e4:	5e                   	pop    %esi
f01060e5:	5f                   	pop    %edi
f01060e6:	5d                   	pop    %ebp
f01060e7:	c3                   	ret    

f01060e8 <pci_conf1_set_addr>:
static void
pci_conf1_set_addr(uint32_t bus,
		   uint32_t dev,
		   uint32_t func,
		   uint32_t offset)
{
f01060e8:	55                   	push   %ebp
f01060e9:	89 e5                	mov    %esp,%ebp
f01060eb:	53                   	push   %ebx
f01060ec:	83 ec 04             	sub    $0x4,%esp
f01060ef:	8b 5d 08             	mov    0x8(%ebp),%ebx
	assert(bus < 256);
f01060f2:	3d ff 00 00 00       	cmp    $0xff,%eax
f01060f7:	76 16                	jbe    f010610f <pci_conf1_set_addr+0x27>
f01060f9:	68 e0 88 10 f0       	push   $0xf01088e0
f01060fe:	68 9b 78 10 f0       	push   $0xf010789b
f0106103:	6a 2c                	push   $0x2c
f0106105:	68 ea 88 10 f0       	push   $0xf01088ea
f010610a:	e8 31 9f ff ff       	call   f0100040 <_panic>
	assert(dev < 32);
f010610f:	83 fa 1f             	cmp    $0x1f,%edx
f0106112:	76 16                	jbe    f010612a <pci_conf1_set_addr+0x42>
f0106114:	68 f5 88 10 f0       	push   $0xf01088f5
f0106119:	68 9b 78 10 f0       	push   $0xf010789b
f010611e:	6a 2d                	push   $0x2d
f0106120:	68 ea 88 10 f0       	push   $0xf01088ea
f0106125:	e8 16 9f ff ff       	call   f0100040 <_panic>
	assert(func < 8);
f010612a:	83 f9 07             	cmp    $0x7,%ecx
f010612d:	76 16                	jbe    f0106145 <pci_conf1_set_addr+0x5d>
f010612f:	68 fe 88 10 f0       	push   $0xf01088fe
f0106134:	68 9b 78 10 f0       	push   $0xf010789b
f0106139:	6a 2e                	push   $0x2e
f010613b:	68 ea 88 10 f0       	push   $0xf01088ea
f0106140:	e8 fb 9e ff ff       	call   f0100040 <_panic>
	assert(offset < 256);
f0106145:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f010614b:	76 16                	jbe    f0106163 <pci_conf1_set_addr+0x7b>
f010614d:	68 07 89 10 f0       	push   $0xf0108907
f0106152:	68 9b 78 10 f0       	push   $0xf010789b
f0106157:	6a 2f                	push   $0x2f
f0106159:	68 ea 88 10 f0       	push   $0xf01088ea
f010615e:	e8 dd 9e ff ff       	call   f0100040 <_panic>
	assert((offset & 0x3) == 0);
f0106163:	f6 c3 03             	test   $0x3,%bl
f0106166:	74 16                	je     f010617e <pci_conf1_set_addr+0x96>
f0106168:	68 14 89 10 f0       	push   $0xf0108914
f010616d:	68 9b 78 10 f0       	push   $0xf010789b
f0106172:	6a 30                	push   $0x30
f0106174:	68 ea 88 10 f0       	push   $0xf01088ea
f0106179:	e8 c2 9e ff ff       	call   f0100040 <_panic>
f010617e:	81 cb 00 00 00 80    	or     $0x80000000,%ebx

	uint32_t v = (1 << 31) |		// config-space
		(bus << 16) | (dev << 11) | (func << 8) | (offset);
f0106184:	c1 e1 08             	shl    $0x8,%ecx
f0106187:	09 d9                	or     %ebx,%ecx
f0106189:	c1 e2 0b             	shl    $0xb,%edx
f010618c:	09 ca                	or     %ecx,%edx
f010618e:	c1 e0 10             	shl    $0x10,%eax
	assert(dev < 32);
	assert(func < 8);
	assert(offset < 256);
	assert((offset & 0x3) == 0);

	uint32_t v = (1 << 31) |		// config-space
f0106191:	09 d0                	or     %edx,%eax
}

static __inline void
outl(int port, uint32_t data)
{
	__asm __volatile("outl %0,%w1" : : "a" (data), "d" (port));
f0106193:	ba f8 0c 00 00       	mov    $0xcf8,%edx
f0106198:	ef                   	out    %eax,(%dx)
		(bus << 16) | (dev << 11) | (func << 8) | (offset);
	outl(pci_conf1_addr_ioport, v);
}
f0106199:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010619c:	c9                   	leave  
f010619d:	c3                   	ret    

f010619e <pci_conf_read>:

static uint32_t
pci_conf_read(struct pci_func *f, uint32_t off)
{
f010619e:	55                   	push   %ebp
f010619f:	89 e5                	mov    %esp,%ebp
f01061a1:	53                   	push   %ebx
f01061a2:	83 ec 10             	sub    $0x10,%esp
	pci_conf1_set_addr(f->bus->busno, f->dev, f->func, off);
f01061a5:	8b 48 08             	mov    0x8(%eax),%ecx
f01061a8:	8b 58 04             	mov    0x4(%eax),%ebx
f01061ab:	8b 00                	mov    (%eax),%eax
f01061ad:	8b 40 04             	mov    0x4(%eax),%eax
f01061b0:	52                   	push   %edx
f01061b1:	89 da                	mov    %ebx,%edx
f01061b3:	e8 30 ff ff ff       	call   f01060e8 <pci_conf1_set_addr>

static __inline uint32_t
inl(int port)
{
	uint32_t data;
	__asm __volatile("inl %w1,%0" : "=a" (data) : "d" (port));
f01061b8:	ba fc 0c 00 00       	mov    $0xcfc,%edx
f01061bd:	ed                   	in     (%dx),%eax
	return inl(pci_conf1_data_ioport);
}
f01061be:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01061c1:	c9                   	leave  
f01061c2:	c3                   	ret    

f01061c3 <pci_scan_bus>:
		f->irq_line);
}

static int
pci_scan_bus(struct pci_bus *bus)
{
f01061c3:	55                   	push   %ebp
f01061c4:	89 e5                	mov    %esp,%ebp
f01061c6:	57                   	push   %edi
f01061c7:	56                   	push   %esi
f01061c8:	53                   	push   %ebx
f01061c9:	81 ec 00 01 00 00    	sub    $0x100,%esp
f01061cf:	89 c3                	mov    %eax,%ebx
	int totaldev = 0;
	struct pci_func df;
	memset(&df, 0, sizeof(df));
f01061d1:	6a 48                	push   $0x48
f01061d3:	6a 00                	push   $0x0
f01061d5:	8d 45 a0             	lea    -0x60(%ebp),%eax
f01061d8:	50                   	push   %eax
f01061d9:	e8 44 f2 ff ff       	call   f0105422 <memset>
	df.bus = bus;
f01061de:	89 5d a0             	mov    %ebx,-0x60(%ebp)

	for (df.dev = 0; df.dev < 32; df.dev++) {
f01061e1:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f01061e8:	83 c4 10             	add    $0x10,%esp
}

static int
pci_scan_bus(struct pci_bus *bus)
{
	int totaldev = 0;
f01061eb:	c7 85 00 ff ff ff 00 	movl   $0x0,-0x100(%ebp)
f01061f2:	00 00 00 
	struct pci_func df;
	memset(&df, 0, sizeof(df));
	df.bus = bus;

	for (df.dev = 0; df.dev < 32; df.dev++) {
		uint32_t bhlc = pci_conf_read(&df, PCI_BHLC_REG);
f01061f5:	ba 0c 00 00 00       	mov    $0xc,%edx
f01061fa:	8d 45 a0             	lea    -0x60(%ebp),%eax
f01061fd:	e8 9c ff ff ff       	call   f010619e <pci_conf_read>
		if (PCI_HDRTYPE_TYPE(bhlc) > 1)	    // Unsupported or no device
f0106202:	89 c2                	mov    %eax,%edx
f0106204:	c1 ea 10             	shr    $0x10,%edx
f0106207:	83 e2 7f             	and    $0x7f,%edx
f010620a:	83 fa 01             	cmp    $0x1,%edx
f010620d:	0f 87 45 01 00 00    	ja     f0106358 <pci_scan_bus+0x195>
			continue;

		totaldev++;
f0106213:	83 85 00 ff ff ff 01 	addl   $0x1,-0x100(%ebp)

		struct pci_func f = df;
f010621a:	b9 12 00 00 00       	mov    $0x12,%ecx
f010621f:	8d bd 10 ff ff ff    	lea    -0xf0(%ebp),%edi
f0106225:	8d 75 a0             	lea    -0x60(%ebp),%esi
f0106228:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		for (f.func = 0; f.func < (PCI_HDRTYPE_MULTIFN(bhlc) ? 8 : 1);
f010622a:	c7 85 18 ff ff ff 00 	movl   $0x0,-0xe8(%ebp)
f0106231:	00 00 00 
f0106234:	25 00 00 80 00       	and    $0x800000,%eax
f0106239:	89 85 04 ff ff ff    	mov    %eax,-0xfc(%ebp)
		     f.func++) {
			struct pci_func af = f;
f010623f:	8d 9d 58 ff ff ff    	lea    -0xa8(%ebp),%ebx
			continue;

		totaldev++;

		struct pci_func f = df;
		for (f.func = 0; f.func < (PCI_HDRTYPE_MULTIFN(bhlc) ? 8 : 1);
f0106245:	e9 f3 00 00 00       	jmp    f010633d <pci_scan_bus+0x17a>
		     f.func++) {
			struct pci_func af = f;
f010624a:	b9 12 00 00 00       	mov    $0x12,%ecx
f010624f:	89 df                	mov    %ebx,%edi
f0106251:	8d b5 10 ff ff ff    	lea    -0xf0(%ebp),%esi
f0106257:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

			af.dev_id = pci_conf_read(&f, PCI_ID_REG);
f0106259:	ba 00 00 00 00       	mov    $0x0,%edx
f010625e:	8d 85 10 ff ff ff    	lea    -0xf0(%ebp),%eax
f0106264:	e8 35 ff ff ff       	call   f010619e <pci_conf_read>
f0106269:	89 85 64 ff ff ff    	mov    %eax,-0x9c(%ebp)
			if (PCI_VENDOR(af.dev_id) == 0xffff)
f010626f:	66 83 f8 ff          	cmp    $0xffff,%ax
f0106273:	0f 84 bd 00 00 00    	je     f0106336 <pci_scan_bus+0x173>
				continue;

			uint32_t intr = pci_conf_read(&af, PCI_INTERRUPT_REG);
f0106279:	ba 3c 00 00 00       	mov    $0x3c,%edx
f010627e:	89 d8                	mov    %ebx,%eax
f0106280:	e8 19 ff ff ff       	call   f010619e <pci_conf_read>
			af.irq_line = PCI_INTERRUPT_LINE(intr);
f0106285:	88 45 9c             	mov    %al,-0x64(%ebp)

			af.dev_class = pci_conf_read(&af, PCI_CLASS_REG);
f0106288:	ba 08 00 00 00       	mov    $0x8,%edx
f010628d:	89 d8                	mov    %ebx,%eax
f010628f:	e8 0a ff ff ff       	call   f010619e <pci_conf_read>
f0106294:	89 85 68 ff ff ff    	mov    %eax,-0x98(%ebp)

static void
pci_print_func(struct pci_func *f)
{
	const char *class = pci_class[0];
	if (PCI_CLASS(f->dev_class) < sizeof(pci_class) / sizeof(pci_class[0]))
f010629a:	89 c2                	mov    %eax,%edx
f010629c:	c1 ea 18             	shr    $0x18,%edx
};

static void
pci_print_func(struct pci_func *f)
{
	const char *class = pci_class[0];
f010629f:	be 28 89 10 f0       	mov    $0xf0108928,%esi
	if (PCI_CLASS(f->dev_class) < sizeof(pci_class) / sizeof(pci_class[0]))
f01062a4:	83 fa 06             	cmp    $0x6,%edx
f01062a7:	77 07                	ja     f01062b0 <pci_scan_bus+0xed>
		class = pci_class[PCI_CLASS(f->dev_class)];
f01062a9:	8b 34 95 9c 89 10 f0 	mov    -0xfef7664(,%edx,4),%esi

	cprintf("PCI: %02x:%02x.%d: %04x:%04x: class: %x.%x (%s) irq: %d\n",
		f->bus->busno, f->dev, f->func,
		PCI_VENDOR(f->dev_id), PCI_PRODUCT(f->dev_id),
f01062b0:	8b 8d 64 ff ff ff    	mov    -0x9c(%ebp),%ecx
{
	const char *class = pci_class[0];
	if (PCI_CLASS(f->dev_class) < sizeof(pci_class) / sizeof(pci_class[0]))
		class = pci_class[PCI_CLASS(f->dev_class)];

	cprintf("PCI: %02x:%02x.%d: %04x:%04x: class: %x.%x (%s) irq: %d\n",
f01062b6:	83 ec 08             	sub    $0x8,%esp
f01062b9:	0f b6 7d 9c          	movzbl -0x64(%ebp),%edi
f01062bd:	57                   	push   %edi
f01062be:	56                   	push   %esi
		f->bus->busno, f->dev, f->func,
		PCI_VENDOR(f->dev_id), PCI_PRODUCT(f->dev_id),
		PCI_CLASS(f->dev_class), PCI_SUBCLASS(f->dev_class), class,
f01062bf:	c1 e8 10             	shr    $0x10,%eax
{
	const char *class = pci_class[0];
	if (PCI_CLASS(f->dev_class) < sizeof(pci_class) / sizeof(pci_class[0]))
		class = pci_class[PCI_CLASS(f->dev_class)];

	cprintf("PCI: %02x:%02x.%d: %04x:%04x: class: %x.%x (%s) irq: %d\n",
f01062c2:	0f b6 c0             	movzbl %al,%eax
f01062c5:	50                   	push   %eax
f01062c6:	52                   	push   %edx
f01062c7:	89 c8                	mov    %ecx,%eax
f01062c9:	c1 e8 10             	shr    $0x10,%eax
f01062cc:	50                   	push   %eax
f01062cd:	0f b7 c9             	movzwl %cx,%ecx
f01062d0:	51                   	push   %ecx
f01062d1:	ff b5 60 ff ff ff    	pushl  -0xa0(%ebp)
f01062d7:	ff b5 5c ff ff ff    	pushl  -0xa4(%ebp)
f01062dd:	8b 85 58 ff ff ff    	mov    -0xa8(%ebp),%eax
f01062e3:	ff 70 04             	pushl  0x4(%eax)
f01062e6:	68 b4 87 10 f0       	push   $0xf01087b4
f01062eb:	e8 5a d5 ff ff       	call   f010384a <cprintf>
static int
pci_attach(struct pci_func *f)
{
	return
		pci_attach_match(PCI_CLASS(f->dev_class),
				 PCI_SUBCLASS(f->dev_class),
f01062f0:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax

static int
pci_attach(struct pci_func *f)
{
	return
		pci_attach_match(PCI_CLASS(f->dev_class),
f01062f6:	83 c4 30             	add    $0x30,%esp
f01062f9:	53                   	push   %ebx
f01062fa:	68 0c 35 12 f0       	push   $0xf012350c
				 PCI_SUBCLASS(f->dev_class),
f01062ff:	89 c2                	mov    %eax,%edx
f0106301:	c1 ea 10             	shr    $0x10,%edx

static int
pci_attach(struct pci_func *f)
{
	return
		pci_attach_match(PCI_CLASS(f->dev_class),
f0106304:	0f b6 d2             	movzbl %dl,%edx
f0106307:	52                   	push   %edx
f0106308:	c1 e8 18             	shr    $0x18,%eax
f010630b:	50                   	push   %eax
f010630c:	e8 79 fd ff ff       	call   f010608a <pci_attach_match>
				 PCI_SUBCLASS(f->dev_class),
				 &pci_attach_class[0], f) ||
f0106311:	83 c4 10             	add    $0x10,%esp
f0106314:	85 c0                	test   %eax,%eax
f0106316:	75 1e                	jne    f0106336 <pci_scan_bus+0x173>
		pci_attach_match(PCI_VENDOR(f->dev_id),
				 PCI_PRODUCT(f->dev_id),
f0106318:	8b 85 64 ff ff ff    	mov    -0x9c(%ebp),%eax
{
	return
		pci_attach_match(PCI_CLASS(f->dev_class),
				 PCI_SUBCLASS(f->dev_class),
				 &pci_attach_class[0], f) ||
		pci_attach_match(PCI_VENDOR(f->dev_id),
f010631e:	53                   	push   %ebx
f010631f:	68 f4 34 12 f0       	push   $0xf01234f4
f0106324:	89 c2                	mov    %eax,%edx
f0106326:	c1 ea 10             	shr    $0x10,%edx
f0106329:	52                   	push   %edx
f010632a:	0f b7 c0             	movzwl %ax,%eax
f010632d:	50                   	push   %eax
f010632e:	e8 57 fd ff ff       	call   f010608a <pci_attach_match>
f0106333:	83 c4 10             	add    $0x10,%esp

		totaldev++;

		struct pci_func f = df;
		for (f.func = 0; f.func < (PCI_HDRTYPE_MULTIFN(bhlc) ? 8 : 1);
		     f.func++) {
f0106336:	83 85 18 ff ff ff 01 	addl   $0x1,-0xe8(%ebp)
			continue;

		totaldev++;

		struct pci_func f = df;
		for (f.func = 0; f.func < (PCI_HDRTYPE_MULTIFN(bhlc) ? 8 : 1);
f010633d:	83 bd 04 ff ff ff 01 	cmpl   $0x1,-0xfc(%ebp)
f0106344:	19 c0                	sbb    %eax,%eax
f0106346:	83 e0 f9             	and    $0xfffffff9,%eax
f0106349:	83 c0 08             	add    $0x8,%eax
f010634c:	3b 85 18 ff ff ff    	cmp    -0xe8(%ebp),%eax
f0106352:	0f 87 f2 fe ff ff    	ja     f010624a <pci_scan_bus+0x87>
	int totaldev = 0;
	struct pci_func df;
	memset(&df, 0, sizeof(df));
	df.bus = bus;

	for (df.dev = 0; df.dev < 32; df.dev++) {
f0106358:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f010635b:	83 c0 01             	add    $0x1,%eax
f010635e:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f0106361:	83 f8 1f             	cmp    $0x1f,%eax
f0106364:	0f 86 8b fe ff ff    	jbe    f01061f5 <pci_scan_bus+0x32>
			pci_attach(&af);
		}
	}

	return totaldev;
}
f010636a:	8b 85 00 ff ff ff    	mov    -0x100(%ebp),%eax
f0106370:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0106373:	5b                   	pop    %ebx
f0106374:	5e                   	pop    %esi
f0106375:	5f                   	pop    %edi
f0106376:	5d                   	pop    %ebp
f0106377:	c3                   	ret    

f0106378 <pci_bridge_attach>:

static int
pci_bridge_attach(struct pci_func *pcif)
{
f0106378:	55                   	push   %ebp
f0106379:	89 e5                	mov    %esp,%ebp
f010637b:	57                   	push   %edi
f010637c:	56                   	push   %esi
f010637d:	53                   	push   %ebx
f010637e:	83 ec 1c             	sub    $0x1c,%esp
f0106381:	8b 5d 08             	mov    0x8(%ebp),%ebx
	uint32_t ioreg  = pci_conf_read(pcif, PCI_BRIDGE_STATIO_REG);
f0106384:	ba 1c 00 00 00       	mov    $0x1c,%edx
f0106389:	89 d8                	mov    %ebx,%eax
f010638b:	e8 0e fe ff ff       	call   f010619e <pci_conf_read>
f0106390:	89 c7                	mov    %eax,%edi
	uint32_t busreg = pci_conf_read(pcif, PCI_BRIDGE_BUS_REG);
f0106392:	ba 18 00 00 00       	mov    $0x18,%edx
f0106397:	89 d8                	mov    %ebx,%eax
f0106399:	e8 00 fe ff ff       	call   f010619e <pci_conf_read>

	if (PCI_BRIDGE_IO_32BITS(ioreg)) {
f010639e:	83 e7 0f             	and    $0xf,%edi
f01063a1:	83 ff 01             	cmp    $0x1,%edi
f01063a4:	75 1f                	jne    f01063c5 <pci_bridge_attach+0x4d>
		cprintf("PCI: %02x:%02x.%d: 32-bit bridge IO not supported.\n",
f01063a6:	ff 73 08             	pushl  0x8(%ebx)
f01063a9:	ff 73 04             	pushl  0x4(%ebx)
f01063ac:	8b 03                	mov    (%ebx),%eax
f01063ae:	ff 70 04             	pushl  0x4(%eax)
f01063b1:	68 f0 87 10 f0       	push   $0xf01087f0
f01063b6:	e8 8f d4 ff ff       	call   f010384a <cprintf>
			pcif->bus->busno, pcif->dev, pcif->func);
		return 0;
f01063bb:	83 c4 10             	add    $0x10,%esp
f01063be:	b8 00 00 00 00       	mov    $0x0,%eax
f01063c3:	eb 4e                	jmp    f0106413 <pci_bridge_attach+0x9b>
f01063c5:	89 c6                	mov    %eax,%esi
	}

	struct pci_bus nbus;
	memset(&nbus, 0, sizeof(nbus));
f01063c7:	83 ec 04             	sub    $0x4,%esp
f01063ca:	6a 08                	push   $0x8
f01063cc:	6a 00                	push   $0x0
f01063ce:	8d 7d e0             	lea    -0x20(%ebp),%edi
f01063d1:	57                   	push   %edi
f01063d2:	e8 4b f0 ff ff       	call   f0105422 <memset>
	nbus.parent_bridge = pcif;
f01063d7:	89 5d e0             	mov    %ebx,-0x20(%ebp)
	nbus.busno = (busreg >> PCI_BRIDGE_BUS_SECONDARY_SHIFT) & 0xff;
f01063da:	89 f0                	mov    %esi,%eax
f01063dc:	0f b6 c4             	movzbl %ah,%eax
f01063df:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	if (pci_show_devs)
		cprintf("PCI: %02x:%02x.%d: bridge to PCI bus %d--%d\n",
f01063e2:	83 c4 08             	add    $0x8,%esp
			pcif->bus->busno, pcif->dev, pcif->func,
			nbus.busno,
			(busreg >> PCI_BRIDGE_BUS_SUBORDINATE_SHIFT) & 0xff);
f01063e5:	89 f2                	mov    %esi,%edx
f01063e7:	c1 ea 10             	shr    $0x10,%edx
	memset(&nbus, 0, sizeof(nbus));
	nbus.parent_bridge = pcif;
	nbus.busno = (busreg >> PCI_BRIDGE_BUS_SECONDARY_SHIFT) & 0xff;

	if (pci_show_devs)
		cprintf("PCI: %02x:%02x.%d: bridge to PCI bus %d--%d\n",
f01063ea:	0f b6 f2             	movzbl %dl,%esi
f01063ed:	56                   	push   %esi
f01063ee:	50                   	push   %eax
f01063ef:	ff 73 08             	pushl  0x8(%ebx)
f01063f2:	ff 73 04             	pushl  0x4(%ebx)
f01063f5:	8b 03                	mov    (%ebx),%eax
f01063f7:	ff 70 04             	pushl  0x4(%eax)
f01063fa:	68 24 88 10 f0       	push   $0xf0108824
f01063ff:	e8 46 d4 ff ff       	call   f010384a <cprintf>
			pcif->bus->busno, pcif->dev, pcif->func,
			nbus.busno,
			(busreg >> PCI_BRIDGE_BUS_SUBORDINATE_SHIFT) & 0xff);

	pci_scan_bus(&nbus);
f0106404:	83 c4 20             	add    $0x20,%esp
f0106407:	89 f8                	mov    %edi,%eax
f0106409:	e8 b5 fd ff ff       	call   f01061c3 <pci_scan_bus>
	return 1;
f010640e:	b8 01 00 00 00       	mov    $0x1,%eax
}
f0106413:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0106416:	5b                   	pop    %ebx
f0106417:	5e                   	pop    %esi
f0106418:	5f                   	pop    %edi
f0106419:	5d                   	pop    %ebp
f010641a:	c3                   	ret    

f010641b <pci_conf_write>:
	return inl(pci_conf1_data_ioport);
}

static void
pci_conf_write(struct pci_func *f, uint32_t off, uint32_t v)
{
f010641b:	55                   	push   %ebp
f010641c:	89 e5                	mov    %esp,%ebp
f010641e:	56                   	push   %esi
f010641f:	53                   	push   %ebx
f0106420:	89 cb                	mov    %ecx,%ebx
	pci_conf1_set_addr(f->bus->busno, f->dev, f->func, off);
f0106422:	83 ec 0c             	sub    $0xc,%esp
f0106425:	8b 48 08             	mov    0x8(%eax),%ecx
f0106428:	8b 70 04             	mov    0x4(%eax),%esi
f010642b:	8b 00                	mov    (%eax),%eax
f010642d:	8b 40 04             	mov    0x4(%eax),%eax
f0106430:	52                   	push   %edx
f0106431:	89 f2                	mov    %esi,%edx
f0106433:	e8 b0 fc ff ff       	call   f01060e8 <pci_conf1_set_addr>
}

static __inline void
outl(int port, uint32_t data)
{
	__asm __volatile("outl %0,%w1" : : "a" (data), "d" (port));
f0106438:	ba fc 0c 00 00       	mov    $0xcfc,%edx
f010643d:	89 d8                	mov    %ebx,%eax
f010643f:	ef                   	out    %eax,(%dx)
f0106440:	83 c4 10             	add    $0x10,%esp
	outl(pci_conf1_data_ioport, v);
}
f0106443:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0106446:	5b                   	pop    %ebx
f0106447:	5e                   	pop    %esi
f0106448:	5d                   	pop    %ebp
f0106449:	c3                   	ret    

f010644a <pci_func_enable>:

// External PCI subsystem interface

void
pci_func_enable(struct pci_func *f)
{
f010644a:	55                   	push   %ebp
f010644b:	89 e5                	mov    %esp,%ebp
f010644d:	57                   	push   %edi
f010644e:	56                   	push   %esi
f010644f:	53                   	push   %ebx
f0106450:	83 ec 1c             	sub    $0x1c,%esp
f0106453:	8b 7d 08             	mov    0x8(%ebp),%edi
	pci_conf_write(f, PCI_COMMAND_STATUS_REG,
f0106456:	b9 07 00 00 00       	mov    $0x7,%ecx
f010645b:	ba 04 00 00 00       	mov    $0x4,%edx
f0106460:	89 f8                	mov    %edi,%eax
f0106462:	e8 b4 ff ff ff       	call   f010641b <pci_conf_write>
		       PCI_COMMAND_MEM_ENABLE |
		       PCI_COMMAND_MASTER_ENABLE);

	uint32_t bar_width;
	uint32_t bar;
	for (bar = PCI_MAPREG_START; bar < PCI_MAPREG_END;
f0106467:	be 10 00 00 00       	mov    $0x10,%esi
	     bar += bar_width)
	{
		uint32_t oldv = pci_conf_read(f, bar);
f010646c:	89 f2                	mov    %esi,%edx
f010646e:	89 f8                	mov    %edi,%eax
f0106470:	e8 29 fd ff ff       	call   f010619e <pci_conf_read>
f0106475:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		bar_width = 4;
		pci_conf_write(f, bar, 0xffffffff);
f0106478:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
f010647d:	89 f2                	mov    %esi,%edx
f010647f:	89 f8                	mov    %edi,%eax
f0106481:	e8 95 ff ff ff       	call   f010641b <pci_conf_write>
		uint32_t rv = pci_conf_read(f, bar);
f0106486:	89 f2                	mov    %esi,%edx
f0106488:	89 f8                	mov    %edi,%eax
f010648a:	e8 0f fd ff ff       	call   f010619e <pci_conf_read>
	for (bar = PCI_MAPREG_START; bar < PCI_MAPREG_END;
	     bar += bar_width)
	{
		uint32_t oldv = pci_conf_read(f, bar);

		bar_width = 4;
f010648f:	bb 04 00 00 00       	mov    $0x4,%ebx
		pci_conf_write(f, bar, 0xffffffff);
		uint32_t rv = pci_conf_read(f, bar);

		if (rv == 0)
f0106494:	85 c0                	test   %eax,%eax
f0106496:	0f 84 a6 00 00 00    	je     f0106542 <pci_func_enable+0xf8>
			continue;

		int regnum = PCI_MAPREG_NUM(bar);
f010649c:	8d 56 f0             	lea    -0x10(%esi),%edx
f010649f:	c1 ea 02             	shr    $0x2,%edx
f01064a2:	89 55 e0             	mov    %edx,-0x20(%ebp)
		uint32_t base, size;
		if (PCI_MAPREG_TYPE(rv) == PCI_MAPREG_TYPE_MEM) {
f01064a5:	a8 01                	test   $0x1,%al
f01064a7:	75 2c                	jne    f01064d5 <pci_func_enable+0x8b>
			if (PCI_MAPREG_MEM_TYPE(rv) == PCI_MAPREG_MEM_TYPE_64BIT)
f01064a9:	89 c2                	mov    %eax,%edx
f01064ab:	83 e2 06             	and    $0x6,%edx
				bar_width = 8;
f01064ae:	83 fa 04             	cmp    $0x4,%edx
f01064b1:	0f 94 c3             	sete   %bl
f01064b4:	0f b6 db             	movzbl %bl,%ebx
f01064b7:	8d 1c 9d 04 00 00 00 	lea    0x4(,%ebx,4),%ebx

			size = PCI_MAPREG_MEM_SIZE(rv);
f01064be:	83 e0 f0             	and    $0xfffffff0,%eax
f01064c1:	89 c2                	mov    %eax,%edx
f01064c3:	f7 da                	neg    %edx
f01064c5:	21 d0                	and    %edx,%eax
f01064c7:	89 45 d8             	mov    %eax,-0x28(%ebp)
			base = PCI_MAPREG_MEM_ADDR(oldv);
f01064ca:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01064cd:	83 e0 f0             	and    $0xfffffff0,%eax
f01064d0:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01064d3:	eb 1a                	jmp    f01064ef <pci_func_enable+0xa5>
			if (pci_show_addrs)
				cprintf("  mem region %d: %d bytes at 0x%x\n",
					regnum, size, base);
		} else {
			size = PCI_MAPREG_IO_SIZE(rv);
f01064d5:	83 e0 fc             	and    $0xfffffffc,%eax
f01064d8:	89 c2                	mov    %eax,%edx
f01064da:	f7 da                	neg    %edx
f01064dc:	21 d0                	and    %edx,%eax
f01064de:	89 45 d8             	mov    %eax,-0x28(%ebp)
			base = PCI_MAPREG_IO_ADDR(oldv);
f01064e1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01064e4:	83 e0 fc             	and    $0xfffffffc,%eax
f01064e7:	89 45 dc             	mov    %eax,-0x24(%ebp)
	for (bar = PCI_MAPREG_START; bar < PCI_MAPREG_END;
	     bar += bar_width)
	{
		uint32_t oldv = pci_conf_read(f, bar);

		bar_width = 4;
f01064ea:	bb 04 00 00 00       	mov    $0x4,%ebx
			if (pci_show_addrs)
				cprintf("  io region %d: %d bytes at 0x%x\n",
					regnum, size, base);
		}

		pci_conf_write(f, bar, oldv);
f01064ef:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01064f2:	89 f2                	mov    %esi,%edx
f01064f4:	89 f8                	mov    %edi,%eax
f01064f6:	e8 20 ff ff ff       	call   f010641b <pci_conf_write>
f01064fb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01064fe:	8d 04 87             	lea    (%edi,%eax,4),%eax
		f->reg_base[regnum] = base;
f0106501:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0106504:	89 48 14             	mov    %ecx,0x14(%eax)
		f->reg_size[regnum] = size;
f0106507:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010650a:	89 50 2c             	mov    %edx,0x2c(%eax)

		if (size && !base)
f010650d:	85 c9                	test   %ecx,%ecx
f010650f:	75 31                	jne    f0106542 <pci_func_enable+0xf8>
f0106511:	85 d2                	test   %edx,%edx
f0106513:	74 2d                	je     f0106542 <pci_func_enable+0xf8>
			cprintf("PCI device %02x:%02x.%d (%04x:%04x) "
				"may be misconfigured: "
				"region %d: base 0x%x, size %d\n",
				f->bus->busno, f->dev, f->func,
				PCI_VENDOR(f->dev_id), PCI_PRODUCT(f->dev_id),
f0106515:	8b 47 0c             	mov    0xc(%edi),%eax
		pci_conf_write(f, bar, oldv);
		f->reg_base[regnum] = base;
		f->reg_size[regnum] = size;

		if (size && !base)
			cprintf("PCI device %02x:%02x.%d (%04x:%04x) "
f0106518:	83 ec 0c             	sub    $0xc,%esp
f010651b:	52                   	push   %edx
f010651c:	51                   	push   %ecx
f010651d:	ff 75 e0             	pushl  -0x20(%ebp)
f0106520:	89 c2                	mov    %eax,%edx
f0106522:	c1 ea 10             	shr    $0x10,%edx
f0106525:	52                   	push   %edx
f0106526:	0f b7 c0             	movzwl %ax,%eax
f0106529:	50                   	push   %eax
f010652a:	ff 77 08             	pushl  0x8(%edi)
f010652d:	ff 77 04             	pushl  0x4(%edi)
f0106530:	8b 07                	mov    (%edi),%eax
f0106532:	ff 70 04             	pushl  0x4(%eax)
f0106535:	68 54 88 10 f0       	push   $0xf0108854
f010653a:	e8 0b d3 ff ff       	call   f010384a <cprintf>
f010653f:	83 c4 30             	add    $0x30,%esp
		       PCI_COMMAND_MASTER_ENABLE);

	uint32_t bar_width;
	uint32_t bar;
	for (bar = PCI_MAPREG_START; bar < PCI_MAPREG_END;
	     bar += bar_width)
f0106542:	01 de                	add    %ebx,%esi
		       PCI_COMMAND_MEM_ENABLE |
		       PCI_COMMAND_MASTER_ENABLE);

	uint32_t bar_width;
	uint32_t bar;
	for (bar = PCI_MAPREG_START; bar < PCI_MAPREG_END;
f0106544:	83 fe 27             	cmp    $0x27,%esi
f0106547:	0f 86 1f ff ff ff    	jbe    f010646c <pci_func_enable+0x22>
				regnum, base, size);
	}

	cprintf("PCI function %02x:%02x.%d (%04x:%04x) enabled\n",
		f->bus->busno, f->dev, f->func,
		PCI_VENDOR(f->dev_id), PCI_PRODUCT(f->dev_id));
f010654d:	8b 47 0c             	mov    0xc(%edi),%eax
				f->bus->busno, f->dev, f->func,
				PCI_VENDOR(f->dev_id), PCI_PRODUCT(f->dev_id),
				regnum, base, size);
	}

	cprintf("PCI function %02x:%02x.%d (%04x:%04x) enabled\n",
f0106550:	83 ec 08             	sub    $0x8,%esp
f0106553:	89 c2                	mov    %eax,%edx
f0106555:	c1 ea 10             	shr    $0x10,%edx
f0106558:	52                   	push   %edx
f0106559:	0f b7 c0             	movzwl %ax,%eax
f010655c:	50                   	push   %eax
f010655d:	ff 77 08             	pushl  0x8(%edi)
f0106560:	ff 77 04             	pushl  0x4(%edi)
f0106563:	8b 07                	mov    (%edi),%eax
f0106565:	ff 70 04             	pushl  0x4(%eax)
f0106568:	68 b0 88 10 f0       	push   $0xf01088b0
f010656d:	e8 d8 d2 ff ff       	call   f010384a <cprintf>
f0106572:	83 c4 20             	add    $0x20,%esp
		f->bus->busno, f->dev, f->func,
		PCI_VENDOR(f->dev_id), PCI_PRODUCT(f->dev_id));
}
f0106575:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0106578:	5b                   	pop    %ebx
f0106579:	5e                   	pop    %esi
f010657a:	5f                   	pop    %edi
f010657b:	5d                   	pop    %ebp
f010657c:	c3                   	ret    

f010657d <pci_init>:

int
pci_init(void)
{
f010657d:	55                   	push   %ebp
f010657e:	89 e5                	mov    %esp,%ebp
f0106580:	83 ec 0c             	sub    $0xc,%esp
	static struct pci_bus root_bus;
	memset(&root_bus, 0, sizeof(root_bus));
f0106583:	6a 08                	push   $0x8
f0106585:	6a 00                	push   $0x0
f0106587:	68 c0 6e 2a f0       	push   $0xf02a6ec0
f010658c:	e8 91 ee ff ff       	call   f0105422 <memset>

	return pci_scan_bus(&root_bus);
f0106591:	b8 c0 6e 2a f0       	mov    $0xf02a6ec0,%eax
f0106596:	e8 28 fc ff ff       	call   f01061c3 <pci_scan_bus>
}
f010659b:	c9                   	leave  
f010659c:	c3                   	ret    

f010659d <time_init>:

static unsigned int ticks;

void
time_init(void)
{
f010659d:	55                   	push   %ebp
f010659e:	89 e5                	mov    %esp,%ebp
	ticks = 0;
f01065a0:	c7 05 c8 6e 2a f0 00 	movl   $0x0,0xf02a6ec8
f01065a7:	00 00 00 
}
f01065aa:	5d                   	pop    %ebp
f01065ab:	c3                   	ret    

f01065ac <time_tick>:
// This should be called once per timer interrupt.  A timer interrupt
// fires every 10 ms.
void
time_tick(void)
{
	ticks++;
f01065ac:	a1 c8 6e 2a f0       	mov    0xf02a6ec8,%eax
f01065b1:	83 c0 01             	add    $0x1,%eax
f01065b4:	a3 c8 6e 2a f0       	mov    %eax,0xf02a6ec8
	if (ticks * 10 < ticks)
f01065b9:	8d 14 80             	lea    (%eax,%eax,4),%edx
f01065bc:	01 d2                	add    %edx,%edx
f01065be:	39 d0                	cmp    %edx,%eax
f01065c0:	76 17                	jbe    f01065d9 <time_tick+0x2d>

// This should be called once per timer interrupt.  A timer interrupt
// fires every 10 ms.
void
time_tick(void)
{
f01065c2:	55                   	push   %ebp
f01065c3:	89 e5                	mov    %esp,%ebp
f01065c5:	83 ec 0c             	sub    $0xc,%esp
	ticks++;
	if (ticks * 10 < ticks)
		panic("time_tick: time overflowed");
f01065c8:	68 b8 89 10 f0       	push   $0xf01089b8
f01065cd:	6a 13                	push   $0x13
f01065cf:	68 d3 89 10 f0       	push   $0xf01089d3
f01065d4:	e8 67 9a ff ff       	call   f0100040 <_panic>
f01065d9:	f3 c3                	repz ret 

f01065db <time_msec>:
}

unsigned int
time_msec(void)
{
f01065db:	55                   	push   %ebp
f01065dc:	89 e5                	mov    %esp,%ebp
	return ticks * 10;
f01065de:	a1 c8 6e 2a f0       	mov    0xf02a6ec8,%eax
f01065e3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01065e6:	01 c0                	add    %eax,%eax
}
f01065e8:	5d                   	pop    %ebp
f01065e9:	c3                   	ret    
f01065ea:	66 90                	xchg   %ax,%ax
f01065ec:	66 90                	xchg   %ax,%ax
f01065ee:	66 90                	xchg   %ax,%ax

f01065f0 <__udivdi3>:
f01065f0:	55                   	push   %ebp
f01065f1:	57                   	push   %edi
f01065f2:	56                   	push   %esi
f01065f3:	83 ec 10             	sub    $0x10,%esp
f01065f6:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f01065fa:	8b 7c 24 20          	mov    0x20(%esp),%edi
f01065fe:	8b 74 24 24          	mov    0x24(%esp),%esi
f0106602:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0106606:	85 d2                	test   %edx,%edx
f0106608:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010660c:	89 34 24             	mov    %esi,(%esp)
f010660f:	89 c8                	mov    %ecx,%eax
f0106611:	75 35                	jne    f0106648 <__udivdi3+0x58>
f0106613:	39 f1                	cmp    %esi,%ecx
f0106615:	0f 87 bd 00 00 00    	ja     f01066d8 <__udivdi3+0xe8>
f010661b:	85 c9                	test   %ecx,%ecx
f010661d:	89 cd                	mov    %ecx,%ebp
f010661f:	75 0b                	jne    f010662c <__udivdi3+0x3c>
f0106621:	b8 01 00 00 00       	mov    $0x1,%eax
f0106626:	31 d2                	xor    %edx,%edx
f0106628:	f7 f1                	div    %ecx
f010662a:	89 c5                	mov    %eax,%ebp
f010662c:	89 f0                	mov    %esi,%eax
f010662e:	31 d2                	xor    %edx,%edx
f0106630:	f7 f5                	div    %ebp
f0106632:	89 c6                	mov    %eax,%esi
f0106634:	89 f8                	mov    %edi,%eax
f0106636:	f7 f5                	div    %ebp
f0106638:	89 f2                	mov    %esi,%edx
f010663a:	83 c4 10             	add    $0x10,%esp
f010663d:	5e                   	pop    %esi
f010663e:	5f                   	pop    %edi
f010663f:	5d                   	pop    %ebp
f0106640:	c3                   	ret    
f0106641:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106648:	3b 14 24             	cmp    (%esp),%edx
f010664b:	77 7b                	ja     f01066c8 <__udivdi3+0xd8>
f010664d:	0f bd f2             	bsr    %edx,%esi
f0106650:	83 f6 1f             	xor    $0x1f,%esi
f0106653:	0f 84 97 00 00 00    	je     f01066f0 <__udivdi3+0x100>
f0106659:	bd 20 00 00 00       	mov    $0x20,%ebp
f010665e:	89 d7                	mov    %edx,%edi
f0106660:	89 f1                	mov    %esi,%ecx
f0106662:	29 f5                	sub    %esi,%ebp
f0106664:	d3 e7                	shl    %cl,%edi
f0106666:	89 c2                	mov    %eax,%edx
f0106668:	89 e9                	mov    %ebp,%ecx
f010666a:	d3 ea                	shr    %cl,%edx
f010666c:	89 f1                	mov    %esi,%ecx
f010666e:	09 fa                	or     %edi,%edx
f0106670:	8b 3c 24             	mov    (%esp),%edi
f0106673:	d3 e0                	shl    %cl,%eax
f0106675:	89 54 24 08          	mov    %edx,0x8(%esp)
f0106679:	89 e9                	mov    %ebp,%ecx
f010667b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010667f:	8b 44 24 04          	mov    0x4(%esp),%eax
f0106683:	89 fa                	mov    %edi,%edx
f0106685:	d3 ea                	shr    %cl,%edx
f0106687:	89 f1                	mov    %esi,%ecx
f0106689:	d3 e7                	shl    %cl,%edi
f010668b:	89 e9                	mov    %ebp,%ecx
f010668d:	d3 e8                	shr    %cl,%eax
f010668f:	09 c7                	or     %eax,%edi
f0106691:	89 f8                	mov    %edi,%eax
f0106693:	f7 74 24 08          	divl   0x8(%esp)
f0106697:	89 d5                	mov    %edx,%ebp
f0106699:	89 c7                	mov    %eax,%edi
f010669b:	f7 64 24 0c          	mull   0xc(%esp)
f010669f:	39 d5                	cmp    %edx,%ebp
f01066a1:	89 14 24             	mov    %edx,(%esp)
f01066a4:	72 11                	jb     f01066b7 <__udivdi3+0xc7>
f01066a6:	8b 54 24 04          	mov    0x4(%esp),%edx
f01066aa:	89 f1                	mov    %esi,%ecx
f01066ac:	d3 e2                	shl    %cl,%edx
f01066ae:	39 c2                	cmp    %eax,%edx
f01066b0:	73 5e                	jae    f0106710 <__udivdi3+0x120>
f01066b2:	3b 2c 24             	cmp    (%esp),%ebp
f01066b5:	75 59                	jne    f0106710 <__udivdi3+0x120>
f01066b7:	8d 47 ff             	lea    -0x1(%edi),%eax
f01066ba:	31 f6                	xor    %esi,%esi
f01066bc:	89 f2                	mov    %esi,%edx
f01066be:	83 c4 10             	add    $0x10,%esp
f01066c1:	5e                   	pop    %esi
f01066c2:	5f                   	pop    %edi
f01066c3:	5d                   	pop    %ebp
f01066c4:	c3                   	ret    
f01066c5:	8d 76 00             	lea    0x0(%esi),%esi
f01066c8:	31 f6                	xor    %esi,%esi
f01066ca:	31 c0                	xor    %eax,%eax
f01066cc:	89 f2                	mov    %esi,%edx
f01066ce:	83 c4 10             	add    $0x10,%esp
f01066d1:	5e                   	pop    %esi
f01066d2:	5f                   	pop    %edi
f01066d3:	5d                   	pop    %ebp
f01066d4:	c3                   	ret    
f01066d5:	8d 76 00             	lea    0x0(%esi),%esi
f01066d8:	89 f2                	mov    %esi,%edx
f01066da:	31 f6                	xor    %esi,%esi
f01066dc:	89 f8                	mov    %edi,%eax
f01066de:	f7 f1                	div    %ecx
f01066e0:	89 f2                	mov    %esi,%edx
f01066e2:	83 c4 10             	add    $0x10,%esp
f01066e5:	5e                   	pop    %esi
f01066e6:	5f                   	pop    %edi
f01066e7:	5d                   	pop    %ebp
f01066e8:	c3                   	ret    
f01066e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01066f0:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f01066f4:	76 0b                	jbe    f0106701 <__udivdi3+0x111>
f01066f6:	31 c0                	xor    %eax,%eax
f01066f8:	3b 14 24             	cmp    (%esp),%edx
f01066fb:	0f 83 37 ff ff ff    	jae    f0106638 <__udivdi3+0x48>
f0106701:	b8 01 00 00 00       	mov    $0x1,%eax
f0106706:	e9 2d ff ff ff       	jmp    f0106638 <__udivdi3+0x48>
f010670b:	90                   	nop
f010670c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106710:	89 f8                	mov    %edi,%eax
f0106712:	31 f6                	xor    %esi,%esi
f0106714:	e9 1f ff ff ff       	jmp    f0106638 <__udivdi3+0x48>
f0106719:	66 90                	xchg   %ax,%ax
f010671b:	66 90                	xchg   %ax,%ax
f010671d:	66 90                	xchg   %ax,%ax
f010671f:	90                   	nop

f0106720 <__umoddi3>:
f0106720:	55                   	push   %ebp
f0106721:	57                   	push   %edi
f0106722:	56                   	push   %esi
f0106723:	83 ec 20             	sub    $0x20,%esp
f0106726:	8b 44 24 34          	mov    0x34(%esp),%eax
f010672a:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010672e:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0106732:	89 c6                	mov    %eax,%esi
f0106734:	89 44 24 10          	mov    %eax,0x10(%esp)
f0106738:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f010673c:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0106740:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0106744:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0106748:	89 74 24 18          	mov    %esi,0x18(%esp)
f010674c:	85 c0                	test   %eax,%eax
f010674e:	89 c2                	mov    %eax,%edx
f0106750:	75 1e                	jne    f0106770 <__umoddi3+0x50>
f0106752:	39 f7                	cmp    %esi,%edi
f0106754:	76 52                	jbe    f01067a8 <__umoddi3+0x88>
f0106756:	89 c8                	mov    %ecx,%eax
f0106758:	89 f2                	mov    %esi,%edx
f010675a:	f7 f7                	div    %edi
f010675c:	89 d0                	mov    %edx,%eax
f010675e:	31 d2                	xor    %edx,%edx
f0106760:	83 c4 20             	add    $0x20,%esp
f0106763:	5e                   	pop    %esi
f0106764:	5f                   	pop    %edi
f0106765:	5d                   	pop    %ebp
f0106766:	c3                   	ret    
f0106767:	89 f6                	mov    %esi,%esi
f0106769:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0106770:	39 f0                	cmp    %esi,%eax
f0106772:	77 5c                	ja     f01067d0 <__umoddi3+0xb0>
f0106774:	0f bd e8             	bsr    %eax,%ebp
f0106777:	83 f5 1f             	xor    $0x1f,%ebp
f010677a:	75 64                	jne    f01067e0 <__umoddi3+0xc0>
f010677c:	8b 6c 24 14          	mov    0x14(%esp),%ebp
f0106780:	39 6c 24 0c          	cmp    %ebp,0xc(%esp)
f0106784:	0f 86 f6 00 00 00    	jbe    f0106880 <__umoddi3+0x160>
f010678a:	3b 44 24 18          	cmp    0x18(%esp),%eax
f010678e:	0f 82 ec 00 00 00    	jb     f0106880 <__umoddi3+0x160>
f0106794:	8b 44 24 14          	mov    0x14(%esp),%eax
f0106798:	8b 54 24 18          	mov    0x18(%esp),%edx
f010679c:	83 c4 20             	add    $0x20,%esp
f010679f:	5e                   	pop    %esi
f01067a0:	5f                   	pop    %edi
f01067a1:	5d                   	pop    %ebp
f01067a2:	c3                   	ret    
f01067a3:	90                   	nop
f01067a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01067a8:	85 ff                	test   %edi,%edi
f01067aa:	89 fd                	mov    %edi,%ebp
f01067ac:	75 0b                	jne    f01067b9 <__umoddi3+0x99>
f01067ae:	b8 01 00 00 00       	mov    $0x1,%eax
f01067b3:	31 d2                	xor    %edx,%edx
f01067b5:	f7 f7                	div    %edi
f01067b7:	89 c5                	mov    %eax,%ebp
f01067b9:	8b 44 24 10          	mov    0x10(%esp),%eax
f01067bd:	31 d2                	xor    %edx,%edx
f01067bf:	f7 f5                	div    %ebp
f01067c1:	89 c8                	mov    %ecx,%eax
f01067c3:	f7 f5                	div    %ebp
f01067c5:	eb 95                	jmp    f010675c <__umoddi3+0x3c>
f01067c7:	89 f6                	mov    %esi,%esi
f01067c9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f01067d0:	89 c8                	mov    %ecx,%eax
f01067d2:	89 f2                	mov    %esi,%edx
f01067d4:	83 c4 20             	add    $0x20,%esp
f01067d7:	5e                   	pop    %esi
f01067d8:	5f                   	pop    %edi
f01067d9:	5d                   	pop    %ebp
f01067da:	c3                   	ret    
f01067db:	90                   	nop
f01067dc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01067e0:	b8 20 00 00 00       	mov    $0x20,%eax
f01067e5:	89 e9                	mov    %ebp,%ecx
f01067e7:	29 e8                	sub    %ebp,%eax
f01067e9:	d3 e2                	shl    %cl,%edx
f01067eb:	89 c7                	mov    %eax,%edi
f01067ed:	89 44 24 18          	mov    %eax,0x18(%esp)
f01067f1:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01067f5:	89 f9                	mov    %edi,%ecx
f01067f7:	d3 e8                	shr    %cl,%eax
f01067f9:	89 c1                	mov    %eax,%ecx
f01067fb:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01067ff:	09 d1                	or     %edx,%ecx
f0106801:	89 fa                	mov    %edi,%edx
f0106803:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0106807:	89 e9                	mov    %ebp,%ecx
f0106809:	d3 e0                	shl    %cl,%eax
f010680b:	89 f9                	mov    %edi,%ecx
f010680d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0106811:	89 f0                	mov    %esi,%eax
f0106813:	d3 e8                	shr    %cl,%eax
f0106815:	89 e9                	mov    %ebp,%ecx
f0106817:	89 c7                	mov    %eax,%edi
f0106819:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f010681d:	d3 e6                	shl    %cl,%esi
f010681f:	89 d1                	mov    %edx,%ecx
f0106821:	89 fa                	mov    %edi,%edx
f0106823:	d3 e8                	shr    %cl,%eax
f0106825:	89 e9                	mov    %ebp,%ecx
f0106827:	09 f0                	or     %esi,%eax
f0106829:	8b 74 24 1c          	mov    0x1c(%esp),%esi
f010682d:	f7 74 24 10          	divl   0x10(%esp)
f0106831:	d3 e6                	shl    %cl,%esi
f0106833:	89 d1                	mov    %edx,%ecx
f0106835:	f7 64 24 0c          	mull   0xc(%esp)
f0106839:	39 d1                	cmp    %edx,%ecx
f010683b:	89 74 24 14          	mov    %esi,0x14(%esp)
f010683f:	89 d7                	mov    %edx,%edi
f0106841:	89 c6                	mov    %eax,%esi
f0106843:	72 0a                	jb     f010684f <__umoddi3+0x12f>
f0106845:	39 44 24 14          	cmp    %eax,0x14(%esp)
f0106849:	73 10                	jae    f010685b <__umoddi3+0x13b>
f010684b:	39 d1                	cmp    %edx,%ecx
f010684d:	75 0c                	jne    f010685b <__umoddi3+0x13b>
f010684f:	89 d7                	mov    %edx,%edi
f0106851:	89 c6                	mov    %eax,%esi
f0106853:	2b 74 24 0c          	sub    0xc(%esp),%esi
f0106857:	1b 7c 24 10          	sbb    0x10(%esp),%edi
f010685b:	89 ca                	mov    %ecx,%edx
f010685d:	89 e9                	mov    %ebp,%ecx
f010685f:	8b 44 24 14          	mov    0x14(%esp),%eax
f0106863:	29 f0                	sub    %esi,%eax
f0106865:	19 fa                	sbb    %edi,%edx
f0106867:	d3 e8                	shr    %cl,%eax
f0106869:	0f b6 4c 24 18       	movzbl 0x18(%esp),%ecx
f010686e:	89 d7                	mov    %edx,%edi
f0106870:	d3 e7                	shl    %cl,%edi
f0106872:	89 e9                	mov    %ebp,%ecx
f0106874:	09 f8                	or     %edi,%eax
f0106876:	d3 ea                	shr    %cl,%edx
f0106878:	83 c4 20             	add    $0x20,%esp
f010687b:	5e                   	pop    %esi
f010687c:	5f                   	pop    %edi
f010687d:	5d                   	pop    %ebp
f010687e:	c3                   	ret    
f010687f:	90                   	nop
f0106880:	8b 74 24 10          	mov    0x10(%esp),%esi
f0106884:	29 f9                	sub    %edi,%ecx
f0106886:	19 c6                	sbb    %eax,%esi
f0106888:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f010688c:	89 74 24 18          	mov    %esi,0x18(%esp)
f0106890:	e9 ff fe ff ff       	jmp    f0106794 <__umoddi3+0x74>
