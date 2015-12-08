
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
f0100015:	b8 00 20 12 00       	mov    $0x122000,%eax
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
f0100034:	bc 00 20 12 f0       	mov    $0xf0122000,%esp

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
f0100048:	83 3d cc 9e 2a f0 00 	cmpl   $0x0,0xf02a9ecc
f010004f:	75 3a                	jne    f010008b <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f0100051:	89 35 cc 9e 2a f0    	mov    %esi,0xf02a9ecc

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100057:	fa                   	cli    
f0100058:	fc                   	cld    

	va_start(ap, fmt);
f0100059:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005c:	e8 16 5a 00 00       	call   f0105a77 <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 00 6b 10 f0       	push   $0xf0106b00
f010006d:	e8 e7 37 00 00       	call   f0103859 <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 b7 37 00 00       	call   f0103833 <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 2e 83 10 f0 	movl   $0xf010832e,(%esp)
f0100083:	e8 d1 37 00 00       	call   f0103859 <cprintf>
	va_end(ap);
f0100088:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010008b:	83 ec 0c             	sub    $0xc,%esp
f010008e:	6a 00                	push   $0x0
f0100090:	e8 9a 08 00 00       	call   f010092f <monitor>
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
f01000a1:	b8 c0 37 34 f0       	mov    $0xf03437c0,%eax
f01000a6:	2d 3c 83 2a f0       	sub    $0xf02a833c,%eax
f01000ab:	50                   	push   %eax
f01000ac:	6a 00                	push   $0x0
f01000ae:	68 3c 83 2a f0       	push   $0xf02a833c
f01000b3:	e8 9a 53 00 00       	call   f0105452 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 a2 05 00 00       	call   f010065f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 6c 6b 10 f0       	push   $0xf0106b6c
f01000ca:	e8 8a 37 00 00       	call   f0103859 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 3d 13 00 00       	call   f0101411 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 0c 30 00 00       	call   f01030e5 <env_init>
	trap_init();
f01000d9:	e8 24 38 00 00       	call   f0103902 <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 8d 56 00 00       	call   f0105770 <mp_init>
	lapic_init();
f01000e3:	e8 aa 59 00 00       	call   f0105a92 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 95 36 00 00       	call   f0103782 <pic_init>

	// Lab 6 hardware initialization functions
	time_init();
f01000ed:	e8 09 67 00 00       	call   f01067fb <time_init>
	pci_init();
f01000f2:	e8 e4 66 00 00       	call   f01067db <pci_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000f7:	c7 04 24 c0 44 12 f0 	movl   $0xf01244c0,(%esp)
f01000fe:	e8 df 5b 00 00       	call   f0105ce2 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100103:	83 c4 10             	add    $0x10,%esp
f0100106:	83 3d d8 9e 2a f0 07 	cmpl   $0x7,0xf02a9ed8
f010010d:	77 16                	ja     f0100125 <i386_init+0x8b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010010f:	68 00 70 00 00       	push   $0x7000
f0100114:	68 24 6b 10 f0       	push   $0xf0106b24
f0100119:	6a 74                	push   $0x74
f010011b:	68 87 6b 10 f0       	push   $0xf0106b87
f0100120:	e8 1b ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f0100125:	83 ec 04             	sub    $0x4,%esp
f0100128:	b8 d6 56 10 f0       	mov    $0xf01056d6,%eax
f010012d:	2d 5c 56 10 f0       	sub    $0xf010565c,%eax
f0100132:	50                   	push   %eax
f0100133:	68 5c 56 10 f0       	push   $0xf010565c
f0100138:	68 00 70 00 f0       	push   $0xf0007000
f010013d:	e8 5d 53 00 00       	call   f010549f <memmove>
f0100142:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f0100145:	bb 40 a0 2a f0       	mov    $0xf02aa040,%ebx
f010014a:	eb 4e                	jmp    f010019a <i386_init+0x100>
		if (c == cpus + cpunum())  // We've started already.
f010014c:	e8 26 59 00 00       	call   f0105a77 <cpunum>
f0100151:	6b c0 74             	imul   $0x74,%eax,%eax
f0100154:	05 40 a0 2a f0       	add    $0xf02aa040,%eax
f0100159:	39 c3                	cmp    %eax,%ebx
f010015b:	74 3a                	je     f0100197 <i386_init+0xfd>
f010015d:	89 d8                	mov    %ebx,%eax
f010015f:	2d 40 a0 2a f0       	sub    $0xf02aa040,%eax
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100164:	c1 f8 02             	sar    $0x2,%eax
f0100167:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f010016d:	c1 e0 0f             	shl    $0xf,%eax
f0100170:	8d 80 00 30 2b f0    	lea    -0xfd4d000(%eax),%eax
f0100176:	a3 d0 9e 2a f0       	mov    %eax,0xf02a9ed0
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f010017b:	83 ec 08             	sub    $0x8,%esp
f010017e:	68 00 70 00 00       	push   $0x7000
f0100183:	0f b6 03             	movzbl (%ebx),%eax
f0100186:	50                   	push   %eax
f0100187:	e8 54 5a 00 00       	call   f0105be0 <lapic_startap>
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
f010019a:	6b 05 e4 a3 2a f0 74 	imul   $0x74,0xf02aa3e4,%eax
f01001a1:	05 40 a0 2a f0       	add    $0xf02aa040,%eax
f01001a6:	39 c3                	cmp    %eax,%ebx
f01001a8:	72 a2                	jb     f010014c <i386_init+0xb2>

	// Starting non-boot CPUs
	boot_aps();

	// Start fs.
	ENV_CREATE(fs_fs, ENV_TYPE_FS);
f01001aa:	83 ec 08             	sub    $0x8,%esp
f01001ad:	6a 01                	push   $0x1
f01001af:	68 24 3d 1d f0       	push   $0xf01d3d24
f01001b4:	e8 ca 30 00 00       	call   f0103283 <env_create>
	
	
	
#if !defined(TEST_NO_NS)
	// Start ns.
	ENV_CREATE(net_ns, ENV_TYPE_NS);
f01001b9:	83 c4 08             	add    $0x8,%esp
f01001bc:	6a 02                	push   $0x2
f01001be:	68 6c c9 22 f0       	push   $0xf022c96c
f01001c3:	e8 bb 30 00 00       	call   f0103283 <env_create>

	
	
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f01001c8:	83 c4 08             	add    $0x8,%esp
f01001cb:	6a 00                	push   $0x0
f01001cd:	68 88 47 1f f0       	push   $0xf01f4788
f01001d2:	e8 ac 30 00 00       	call   f0103283 <env_create>
	//ENV_CREATE(user_yield, ENV_TYPE_USER);

#endif // TEST*

	// Should not be necessary - drains keyboard because interrupt has given up.
	kbd_intr();
f01001d7:	e8 27 04 00 00       	call   f0100603 <kbd_intr>

	// Schedule and run the first user environment!
	sched_yield();
f01001dc:	e8 33 40 00 00       	call   f0104214 <sched_yield>

f01001e1 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001e1:	55                   	push   %ebp
f01001e2:	89 e5                	mov    %esp,%ebp
f01001e4:	83 ec 08             	sub    $0x8,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001e7:	a1 dc 9e 2a f0       	mov    0xf02a9edc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001ec:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001f1:	77 15                	ja     f0100208 <mp_main+0x27>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001f3:	50                   	push   %eax
f01001f4:	68 48 6b 10 f0       	push   $0xf0106b48
f01001f9:	68 8b 00 00 00       	push   $0x8b
f01001fe:	68 87 6b 10 f0       	push   $0xf0106b87
f0100203:	e8 38 fe ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100208:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010020d:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f0100210:	e8 62 58 00 00       	call   f0105a77 <cpunum>
f0100215:	83 ec 08             	sub    $0x8,%esp
f0100218:	50                   	push   %eax
f0100219:	68 93 6b 10 f0       	push   $0xf0106b93
f010021e:	e8 36 36 00 00       	call   f0103859 <cprintf>

	lapic_init();
f0100223:	e8 6a 58 00 00       	call   f0105a92 <lapic_init>
	env_init_percpu();
f0100228:	e8 8e 2e 00 00       	call   f01030bb <env_init_percpu>
	trap_init_percpu();
f010022d:	e8 3b 36 00 00       	call   f010386d <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100232:	e8 40 58 00 00       	call   f0105a77 <cpunum>
f0100237:	6b d0 74             	imul   $0x74,%eax,%edx
f010023a:	81 c2 40 a0 2a f0    	add    $0xf02aa040,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0100240:	b8 01 00 00 00       	mov    $0x1,%eax
f0100245:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0100249:	c7 04 24 c0 44 12 f0 	movl   $0xf01244c0,(%esp)
f0100250:	e8 8d 5a 00 00       	call   f0105ce2 <spin_lock>
	// to start running processes on this CPU.  But make sure that
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	lock_kernel();  //Acquire the lock
	sched_yield(); //Call the sched_yield() function to schedule and run different environments, Exercise 6
f0100255:	e8 ba 3f 00 00       	call   f0104214 <sched_yield>

f010025a <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010025a:	55                   	push   %ebp
f010025b:	89 e5                	mov    %esp,%ebp
f010025d:	53                   	push   %ebx
f010025e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100261:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100264:	ff 75 0c             	pushl  0xc(%ebp)
f0100267:	ff 75 08             	pushl  0x8(%ebp)
f010026a:	68 a9 6b 10 f0       	push   $0xf0106ba9
f010026f:	e8 e5 35 00 00       	call   f0103859 <cprintf>
	vcprintf(fmt, ap);
f0100274:	83 c4 08             	add    $0x8,%esp
f0100277:	53                   	push   %ebx
f0100278:	ff 75 10             	pushl  0x10(%ebp)
f010027b:	e8 b3 35 00 00       	call   f0103833 <vcprintf>
	cprintf("\n");
f0100280:	c7 04 24 2e 83 10 f0 	movl   $0xf010832e,(%esp)
f0100287:	e8 cd 35 00 00       	call   f0103859 <cprintf>
	va_end(ap);
f010028c:	83 c4 10             	add    $0x10,%esp
}
f010028f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100292:	c9                   	leave  
f0100293:	c3                   	ret    

f0100294 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100294:	55                   	push   %ebp
f0100295:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100297:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010029c:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010029d:	a8 01                	test   $0x1,%al
f010029f:	74 08                	je     f01002a9 <serial_proc_data+0x15>
f01002a1:	b2 f8                	mov    $0xf8,%dl
f01002a3:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01002a4:	0f b6 c0             	movzbl %al,%eax
f01002a7:	eb 05                	jmp    f01002ae <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01002a9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01002ae:	5d                   	pop    %ebp
f01002af:	c3                   	ret    

f01002b0 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01002b0:	55                   	push   %ebp
f01002b1:	89 e5                	mov    %esp,%ebp
f01002b3:	53                   	push   %ebx
f01002b4:	83 ec 04             	sub    $0x4,%esp
f01002b7:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01002b9:	eb 2a                	jmp    f01002e5 <cons_intr+0x35>
		if (c == 0)
f01002bb:	85 d2                	test   %edx,%edx
f01002bd:	74 26                	je     f01002e5 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01002bf:	a1 44 92 2a f0       	mov    0xf02a9244,%eax
f01002c4:	8d 48 01             	lea    0x1(%eax),%ecx
f01002c7:	89 0d 44 92 2a f0    	mov    %ecx,0xf02a9244
f01002cd:	88 90 40 90 2a f0    	mov    %dl,-0xfd56fc0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01002d3:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01002d9:	75 0a                	jne    f01002e5 <cons_intr+0x35>
			cons.wpos = 0;
f01002db:	c7 05 44 92 2a f0 00 	movl   $0x0,0xf02a9244
f01002e2:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002e5:	ff d3                	call   *%ebx
f01002e7:	89 c2                	mov    %eax,%edx
f01002e9:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002ec:	75 cd                	jne    f01002bb <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01002ee:	83 c4 04             	add    $0x4,%esp
f01002f1:	5b                   	pop    %ebx
f01002f2:	5d                   	pop    %ebp
f01002f3:	c3                   	ret    

f01002f4 <kbd_proc_data>:
f01002f4:	ba 64 00 00 00       	mov    $0x64,%edx
f01002f9:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01002fa:	a8 01                	test   $0x1,%al
f01002fc:	0f 84 f0 00 00 00    	je     f01003f2 <kbd_proc_data+0xfe>
f0100302:	b2 60                	mov    $0x60,%dl
f0100304:	ec                   	in     (%dx),%al
f0100305:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100307:	3c e0                	cmp    $0xe0,%al
f0100309:	75 0d                	jne    f0100318 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f010030b:	83 0d 00 90 2a f0 40 	orl    $0x40,0xf02a9000
		return 0;
f0100312:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100317:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100318:	55                   	push   %ebp
f0100319:	89 e5                	mov    %esp,%ebp
f010031b:	53                   	push   %ebx
f010031c:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010031f:	84 c0                	test   %al,%al
f0100321:	79 36                	jns    f0100359 <kbd_proc_data+0x65>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100323:	8b 0d 00 90 2a f0    	mov    0xf02a9000,%ecx
f0100329:	89 cb                	mov    %ecx,%ebx
f010032b:	83 e3 40             	and    $0x40,%ebx
f010032e:	83 e0 7f             	and    $0x7f,%eax
f0100331:	85 db                	test   %ebx,%ebx
f0100333:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100336:	0f b6 d2             	movzbl %dl,%edx
f0100339:	0f b6 82 40 6d 10 f0 	movzbl -0xfef92c0(%edx),%eax
f0100340:	83 c8 40             	or     $0x40,%eax
f0100343:	0f b6 c0             	movzbl %al,%eax
f0100346:	f7 d0                	not    %eax
f0100348:	21 c8                	and    %ecx,%eax
f010034a:	a3 00 90 2a f0       	mov    %eax,0xf02a9000
		return 0;
f010034f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100354:	e9 a1 00 00 00       	jmp    f01003fa <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f0100359:	8b 0d 00 90 2a f0    	mov    0xf02a9000,%ecx
f010035f:	f6 c1 40             	test   $0x40,%cl
f0100362:	74 0e                	je     f0100372 <kbd_proc_data+0x7e>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100364:	83 c8 80             	or     $0xffffff80,%eax
f0100367:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100369:	83 e1 bf             	and    $0xffffffbf,%ecx
f010036c:	89 0d 00 90 2a f0    	mov    %ecx,0xf02a9000
	}

	shift |= shiftcode[data];
f0100372:	0f b6 c2             	movzbl %dl,%eax
f0100375:	0f b6 90 40 6d 10 f0 	movzbl -0xfef92c0(%eax),%edx
f010037c:	0b 15 00 90 2a f0    	or     0xf02a9000,%edx
	shift ^= togglecode[data];
f0100382:	0f b6 88 40 6c 10 f0 	movzbl -0xfef93c0(%eax),%ecx
f0100389:	31 ca                	xor    %ecx,%edx
f010038b:	89 15 00 90 2a f0    	mov    %edx,0xf02a9000

	c = charcode[shift & (CTL | SHIFT)][data];
f0100391:	89 d1                	mov    %edx,%ecx
f0100393:	83 e1 03             	and    $0x3,%ecx
f0100396:	8b 0c 8d 00 6c 10 f0 	mov    -0xfef9400(,%ecx,4),%ecx
f010039d:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f01003a1:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f01003a4:	f6 c2 08             	test   $0x8,%dl
f01003a7:	74 1b                	je     f01003c4 <kbd_proc_data+0xd0>
		if ('a' <= c && c <= 'z')
f01003a9:	89 d8                	mov    %ebx,%eax
f01003ab:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01003ae:	83 f9 19             	cmp    $0x19,%ecx
f01003b1:	77 05                	ja     f01003b8 <kbd_proc_data+0xc4>
			c += 'A' - 'a';
f01003b3:	83 eb 20             	sub    $0x20,%ebx
f01003b6:	eb 0c                	jmp    f01003c4 <kbd_proc_data+0xd0>
		else if ('A' <= c && c <= 'Z')
f01003b8:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f01003bb:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01003be:	83 f8 19             	cmp    $0x19,%eax
f01003c1:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003c4:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01003ca:	75 2c                	jne    f01003f8 <kbd_proc_data+0x104>
f01003cc:	f7 d2                	not    %edx
f01003ce:	f6 c2 06             	test   $0x6,%dl
f01003d1:	75 25                	jne    f01003f8 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01003d3:	83 ec 0c             	sub    $0xc,%esp
f01003d6:	68 c3 6b 10 f0       	push   $0xf0106bc3
f01003db:	e8 79 34 00 00       	call   f0103859 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003e0:	ba 92 00 00 00       	mov    $0x92,%edx
f01003e5:	b8 03 00 00 00       	mov    $0x3,%eax
f01003ea:	ee                   	out    %al,(%dx)
f01003eb:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003ee:	89 d8                	mov    %ebx,%eax
f01003f0:	eb 08                	jmp    f01003fa <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01003f2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01003f7:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003f8:	89 d8                	mov    %ebx,%eax
}
f01003fa:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01003fd:	c9                   	leave  
f01003fe:	c3                   	ret    

f01003ff <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003ff:	55                   	push   %ebp
f0100400:	89 e5                	mov    %esp,%ebp
f0100402:	57                   	push   %edi
f0100403:	56                   	push   %esi
f0100404:	53                   	push   %ebx
f0100405:	83 ec 1c             	sub    $0x1c,%esp
f0100408:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010040a:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010040f:	be fd 03 00 00       	mov    $0x3fd,%esi
f0100414:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100419:	eb 09                	jmp    f0100424 <cons_putc+0x25>
f010041b:	89 ca                	mov    %ecx,%edx
f010041d:	ec                   	in     (%dx),%al
f010041e:	ec                   	in     (%dx),%al
f010041f:	ec                   	in     (%dx),%al
f0100420:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100421:	83 c3 01             	add    $0x1,%ebx
f0100424:	89 f2                	mov    %esi,%edx
f0100426:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100427:	a8 20                	test   $0x20,%al
f0100429:	75 08                	jne    f0100433 <cons_putc+0x34>
f010042b:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100431:	7e e8                	jle    f010041b <cons_putc+0x1c>
f0100433:	89 f8                	mov    %edi,%eax
f0100435:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100438:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010043d:	89 f8                	mov    %edi,%eax
f010043f:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100440:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100445:	be 79 03 00 00       	mov    $0x379,%esi
f010044a:	b9 84 00 00 00       	mov    $0x84,%ecx
f010044f:	eb 09                	jmp    f010045a <cons_putc+0x5b>
f0100451:	89 ca                	mov    %ecx,%edx
f0100453:	ec                   	in     (%dx),%al
f0100454:	ec                   	in     (%dx),%al
f0100455:	ec                   	in     (%dx),%al
f0100456:	ec                   	in     (%dx),%al
f0100457:	83 c3 01             	add    $0x1,%ebx
f010045a:	89 f2                	mov    %esi,%edx
f010045c:	ec                   	in     (%dx),%al
f010045d:	84 c0                	test   %al,%al
f010045f:	78 08                	js     f0100469 <cons_putc+0x6a>
f0100461:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100467:	7e e8                	jle    f0100451 <cons_putc+0x52>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100469:	ba 78 03 00 00       	mov    $0x378,%edx
f010046e:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100472:	ee                   	out    %al,(%dx)
f0100473:	b2 7a                	mov    $0x7a,%dl
f0100475:	b8 0d 00 00 00       	mov    $0xd,%eax
f010047a:	ee                   	out    %al,(%dx)
f010047b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100480:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100481:	89 fa                	mov    %edi,%edx
f0100483:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100489:	89 f8                	mov    %edi,%eax
f010048b:	80 cc 07             	or     $0x7,%ah
f010048e:	85 d2                	test   %edx,%edx
f0100490:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100493:	89 f8                	mov    %edi,%eax
f0100495:	0f b6 c0             	movzbl %al,%eax
f0100498:	83 f8 09             	cmp    $0x9,%eax
f010049b:	74 74                	je     f0100511 <cons_putc+0x112>
f010049d:	83 f8 09             	cmp    $0x9,%eax
f01004a0:	7f 0a                	jg     f01004ac <cons_putc+0xad>
f01004a2:	83 f8 08             	cmp    $0x8,%eax
f01004a5:	74 14                	je     f01004bb <cons_putc+0xbc>
f01004a7:	e9 99 00 00 00       	jmp    f0100545 <cons_putc+0x146>
f01004ac:	83 f8 0a             	cmp    $0xa,%eax
f01004af:	74 3a                	je     f01004eb <cons_putc+0xec>
f01004b1:	83 f8 0d             	cmp    $0xd,%eax
f01004b4:	74 3d                	je     f01004f3 <cons_putc+0xf4>
f01004b6:	e9 8a 00 00 00       	jmp    f0100545 <cons_putc+0x146>
	case '\b':
		if (crt_pos > 0) {
f01004bb:	0f b7 05 48 92 2a f0 	movzwl 0xf02a9248,%eax
f01004c2:	66 85 c0             	test   %ax,%ax
f01004c5:	0f 84 e6 00 00 00    	je     f01005b1 <cons_putc+0x1b2>
			crt_pos--;
f01004cb:	83 e8 01             	sub    $0x1,%eax
f01004ce:	66 a3 48 92 2a f0    	mov    %ax,0xf02a9248
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004d4:	0f b7 c0             	movzwl %ax,%eax
f01004d7:	66 81 e7 00 ff       	and    $0xff00,%di
f01004dc:	83 cf 20             	or     $0x20,%edi
f01004df:	8b 15 4c 92 2a f0    	mov    0xf02a924c,%edx
f01004e5:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004e9:	eb 78                	jmp    f0100563 <cons_putc+0x164>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004eb:	66 83 05 48 92 2a f0 	addw   $0x50,0xf02a9248
f01004f2:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004f3:	0f b7 05 48 92 2a f0 	movzwl 0xf02a9248,%eax
f01004fa:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100500:	c1 e8 16             	shr    $0x16,%eax
f0100503:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100506:	c1 e0 04             	shl    $0x4,%eax
f0100509:	66 a3 48 92 2a f0    	mov    %ax,0xf02a9248
f010050f:	eb 52                	jmp    f0100563 <cons_putc+0x164>
		break;
	case '\t':
		cons_putc(' ');
f0100511:	b8 20 00 00 00       	mov    $0x20,%eax
f0100516:	e8 e4 fe ff ff       	call   f01003ff <cons_putc>
		cons_putc(' ');
f010051b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100520:	e8 da fe ff ff       	call   f01003ff <cons_putc>
		cons_putc(' ');
f0100525:	b8 20 00 00 00       	mov    $0x20,%eax
f010052a:	e8 d0 fe ff ff       	call   f01003ff <cons_putc>
		cons_putc(' ');
f010052f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100534:	e8 c6 fe ff ff       	call   f01003ff <cons_putc>
		cons_putc(' ');
f0100539:	b8 20 00 00 00       	mov    $0x20,%eax
f010053e:	e8 bc fe ff ff       	call   f01003ff <cons_putc>
f0100543:	eb 1e                	jmp    f0100563 <cons_putc+0x164>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100545:	0f b7 05 48 92 2a f0 	movzwl 0xf02a9248,%eax
f010054c:	8d 50 01             	lea    0x1(%eax),%edx
f010054f:	66 89 15 48 92 2a f0 	mov    %dx,0xf02a9248
f0100556:	0f b7 c0             	movzwl %ax,%eax
f0100559:	8b 15 4c 92 2a f0    	mov    0xf02a924c,%edx
f010055f:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100563:	66 81 3d 48 92 2a f0 	cmpw   $0x7cf,0xf02a9248
f010056a:	cf 07 
f010056c:	76 43                	jbe    f01005b1 <cons_putc+0x1b2>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010056e:	a1 4c 92 2a f0       	mov    0xf02a924c,%eax
f0100573:	83 ec 04             	sub    $0x4,%esp
f0100576:	68 00 0f 00 00       	push   $0xf00
f010057b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100581:	52                   	push   %edx
f0100582:	50                   	push   %eax
f0100583:	e8 17 4f 00 00       	call   f010549f <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100588:	8b 15 4c 92 2a f0    	mov    0xf02a924c,%edx
f010058e:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100594:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010059a:	83 c4 10             	add    $0x10,%esp
f010059d:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01005a2:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005a5:	39 d0                	cmp    %edx,%eax
f01005a7:	75 f4                	jne    f010059d <cons_putc+0x19e>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01005a9:	66 83 2d 48 92 2a f0 	subw   $0x50,0xf02a9248
f01005b0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01005b1:	8b 0d 50 92 2a f0    	mov    0xf02a9250,%ecx
f01005b7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005bc:	89 ca                	mov    %ecx,%edx
f01005be:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01005bf:	0f b7 1d 48 92 2a f0 	movzwl 0xf02a9248,%ebx
f01005c6:	8d 71 01             	lea    0x1(%ecx),%esi
f01005c9:	89 d8                	mov    %ebx,%eax
f01005cb:	66 c1 e8 08          	shr    $0x8,%ax
f01005cf:	89 f2                	mov    %esi,%edx
f01005d1:	ee                   	out    %al,(%dx)
f01005d2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005d7:	89 ca                	mov    %ecx,%edx
f01005d9:	ee                   	out    %al,(%dx)
f01005da:	89 d8                	mov    %ebx,%eax
f01005dc:	89 f2                	mov    %esi,%edx
f01005de:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005df:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005e2:	5b                   	pop    %ebx
f01005e3:	5e                   	pop    %esi
f01005e4:	5f                   	pop    %edi
f01005e5:	5d                   	pop    %ebp
f01005e6:	c3                   	ret    

f01005e7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01005e7:	80 3d 54 92 2a f0 00 	cmpb   $0x0,0xf02a9254
f01005ee:	74 11                	je     f0100601 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01005f0:	55                   	push   %ebp
f01005f1:	89 e5                	mov    %esp,%ebp
f01005f3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01005f6:	b8 94 02 10 f0       	mov    $0xf0100294,%eax
f01005fb:	e8 b0 fc ff ff       	call   f01002b0 <cons_intr>
}
f0100600:	c9                   	leave  
f0100601:	f3 c3                	repz ret 

f0100603 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100603:	55                   	push   %ebp
f0100604:	89 e5                	mov    %esp,%ebp
f0100606:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100609:	b8 f4 02 10 f0       	mov    $0xf01002f4,%eax
f010060e:	e8 9d fc ff ff       	call   f01002b0 <cons_intr>
}
f0100613:	c9                   	leave  
f0100614:	c3                   	ret    

f0100615 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100615:	55                   	push   %ebp
f0100616:	89 e5                	mov    %esp,%ebp
f0100618:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010061b:	e8 c7 ff ff ff       	call   f01005e7 <serial_intr>
	kbd_intr();
f0100620:	e8 de ff ff ff       	call   f0100603 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100625:	a1 40 92 2a f0       	mov    0xf02a9240,%eax
f010062a:	3b 05 44 92 2a f0    	cmp    0xf02a9244,%eax
f0100630:	74 26                	je     f0100658 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100632:	8d 50 01             	lea    0x1(%eax),%edx
f0100635:	89 15 40 92 2a f0    	mov    %edx,0xf02a9240
f010063b:	0f b6 88 40 90 2a f0 	movzbl -0xfd56fc0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100642:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100644:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010064a:	75 11                	jne    f010065d <cons_getc+0x48>
			cons.rpos = 0;
f010064c:	c7 05 40 92 2a f0 00 	movl   $0x0,0xf02a9240
f0100653:	00 00 00 
f0100656:	eb 05                	jmp    f010065d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100658:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010065d:	c9                   	leave  
f010065e:	c3                   	ret    

f010065f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010065f:	55                   	push   %ebp
f0100660:	89 e5                	mov    %esp,%ebp
f0100662:	57                   	push   %edi
f0100663:	56                   	push   %esi
f0100664:	53                   	push   %ebx
f0100665:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100668:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010066f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100676:	5a a5 
	if (*cp != 0xA55A) {
f0100678:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010067f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100683:	74 11                	je     f0100696 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100685:	c7 05 50 92 2a f0 b4 	movl   $0x3b4,0xf02a9250
f010068c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010068f:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100694:	eb 16                	jmp    f01006ac <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100696:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010069d:	c7 05 50 92 2a f0 d4 	movl   $0x3d4,0xf02a9250
f01006a4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006a7:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01006ac:	8b 3d 50 92 2a f0    	mov    0xf02a9250,%edi
f01006b2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01006b7:	89 fa                	mov    %edi,%edx
f01006b9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01006ba:	8d 4f 01             	lea    0x1(%edi),%ecx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006bd:	89 ca                	mov    %ecx,%edx
f01006bf:	ec                   	in     (%dx),%al
f01006c0:	0f b6 c0             	movzbl %al,%eax
f01006c3:	c1 e0 08             	shl    $0x8,%eax
f01006c6:	89 c3                	mov    %eax,%ebx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006c8:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006cd:	89 fa                	mov    %edi,%edx
f01006cf:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006d0:	89 ca                	mov    %ecx,%edx
f01006d2:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006d3:	89 35 4c 92 2a f0    	mov    %esi,0xf02a924c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01006d9:	0f b6 c8             	movzbl %al,%ecx
f01006dc:	89 d8                	mov    %ebx,%eax
f01006de:	09 c8                	or     %ecx,%eax

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01006e0:	66 a3 48 92 2a f0    	mov    %ax,0xf02a9248

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006e6:	e8 18 ff ff ff       	call   f0100603 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<1));
f01006eb:	83 ec 0c             	sub    $0xc,%esp
f01006ee:	0f b7 05 e8 43 12 f0 	movzwl 0xf01243e8,%eax
f01006f5:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006fa:	50                   	push   %eax
f01006fb:	e8 0d 30 00 00       	call   f010370d <irq_setmask_8259A>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100700:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f0100705:	b8 00 00 00 00       	mov    $0x0,%eax
f010070a:	89 da                	mov    %ebx,%edx
f010070c:	ee                   	out    %al,(%dx)
f010070d:	b2 fb                	mov    $0xfb,%dl
f010070f:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100714:	ee                   	out    %al,(%dx)
f0100715:	be f8 03 00 00       	mov    $0x3f8,%esi
f010071a:	b8 0c 00 00 00       	mov    $0xc,%eax
f010071f:	89 f2                	mov    %esi,%edx
f0100721:	ee                   	out    %al,(%dx)
f0100722:	b2 f9                	mov    $0xf9,%dl
f0100724:	b8 00 00 00 00       	mov    $0x0,%eax
f0100729:	ee                   	out    %al,(%dx)
f010072a:	b2 fb                	mov    $0xfb,%dl
f010072c:	b8 03 00 00 00       	mov    $0x3,%eax
f0100731:	ee                   	out    %al,(%dx)
f0100732:	b2 fc                	mov    $0xfc,%dl
f0100734:	b8 00 00 00 00       	mov    $0x0,%eax
f0100739:	ee                   	out    %al,(%dx)
f010073a:	b2 f9                	mov    $0xf9,%dl
f010073c:	b8 01 00 00 00       	mov    $0x1,%eax
f0100741:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100742:	b2 fd                	mov    $0xfd,%dl
f0100744:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100745:	83 c4 10             	add    $0x10,%esp
f0100748:	3c ff                	cmp    $0xff,%al
f010074a:	0f 95 c1             	setne  %cl
f010074d:	88 0d 54 92 2a f0    	mov    %cl,0xf02a9254
f0100753:	89 da                	mov    %ebx,%edx
f0100755:	ec                   	in     (%dx),%al
f0100756:	89 f2                	mov    %esi,%edx
f0100758:	ec                   	in     (%dx),%al
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);

	// Enable serial interrupts
	if (serial_exists)
f0100759:	84 c9                	test   %cl,%cl
f010075b:	74 21                	je     f010077e <cons_init+0x11f>
		irq_setmask_8259A(irq_mask_8259A & ~(1<<4));
f010075d:	83 ec 0c             	sub    $0xc,%esp
f0100760:	0f b7 05 e8 43 12 f0 	movzwl 0xf01243e8,%eax
f0100767:	25 ef ff 00 00       	and    $0xffef,%eax
f010076c:	50                   	push   %eax
f010076d:	e8 9b 2f 00 00       	call   f010370d <irq_setmask_8259A>
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100772:	83 c4 10             	add    $0x10,%esp
f0100775:	80 3d 54 92 2a f0 00 	cmpb   $0x0,0xf02a9254
f010077c:	75 10                	jne    f010078e <cons_init+0x12f>
		cprintf("Serial port does not exist!\n");
f010077e:	83 ec 0c             	sub    $0xc,%esp
f0100781:	68 cf 6b 10 f0       	push   $0xf0106bcf
f0100786:	e8 ce 30 00 00       	call   f0103859 <cprintf>
f010078b:	83 c4 10             	add    $0x10,%esp
}
f010078e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100791:	5b                   	pop    %ebx
f0100792:	5e                   	pop    %esi
f0100793:	5f                   	pop    %edi
f0100794:	5d                   	pop    %ebp
f0100795:	c3                   	ret    

f0100796 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100796:	55                   	push   %ebp
f0100797:	89 e5                	mov    %esp,%ebp
f0100799:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010079c:	8b 45 08             	mov    0x8(%ebp),%eax
f010079f:	e8 5b fc ff ff       	call   f01003ff <cons_putc>
}
f01007a4:	c9                   	leave  
f01007a5:	c3                   	ret    

f01007a6 <getchar>:

int
getchar(void)
{
f01007a6:	55                   	push   %ebp
f01007a7:	89 e5                	mov    %esp,%ebp
f01007a9:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01007ac:	e8 64 fe ff ff       	call   f0100615 <cons_getc>
f01007b1:	85 c0                	test   %eax,%eax
f01007b3:	74 f7                	je     f01007ac <getchar+0x6>
		/* do nothing */;
	return c;
}
f01007b5:	c9                   	leave  
f01007b6:	c3                   	ret    

f01007b7 <iscons>:

int
iscons(int fdnum)
{
f01007b7:	55                   	push   %ebp
f01007b8:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01007ba:	b8 01 00 00 00       	mov    $0x1,%eax
f01007bf:	5d                   	pop    %ebp
f01007c0:	c3                   	ret    

f01007c1 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01007c1:	55                   	push   %ebp
f01007c2:	89 e5                	mov    %esp,%ebp
f01007c4:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007c7:	68 40 6e 10 f0       	push   $0xf0106e40
f01007cc:	68 5e 6e 10 f0       	push   $0xf0106e5e
f01007d1:	68 63 6e 10 f0       	push   $0xf0106e63
f01007d6:	e8 7e 30 00 00       	call   f0103859 <cprintf>
f01007db:	83 c4 0c             	add    $0xc,%esp
f01007de:	68 04 6f 10 f0       	push   $0xf0106f04
f01007e3:	68 6c 6e 10 f0       	push   $0xf0106e6c
f01007e8:	68 63 6e 10 f0       	push   $0xf0106e63
f01007ed:	e8 67 30 00 00       	call   f0103859 <cprintf>
f01007f2:	83 c4 0c             	add    $0xc,%esp
f01007f5:	68 75 6e 10 f0       	push   $0xf0106e75
f01007fa:	68 92 6e 10 f0       	push   $0xf0106e92
f01007ff:	68 63 6e 10 f0       	push   $0xf0106e63
f0100804:	e8 50 30 00 00       	call   f0103859 <cprintf>
	return 0;
}
f0100809:	b8 00 00 00 00       	mov    $0x0,%eax
f010080e:	c9                   	leave  
f010080f:	c3                   	ret    

f0100810 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100810:	55                   	push   %ebp
f0100811:	89 e5                	mov    %esp,%ebp
f0100813:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100816:	68 9d 6e 10 f0       	push   $0xf0106e9d
f010081b:	e8 39 30 00 00       	call   f0103859 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100820:	83 c4 08             	add    $0x8,%esp
f0100823:	68 0c 00 10 00       	push   $0x10000c
f0100828:	68 2c 6f 10 f0       	push   $0xf0106f2c
f010082d:	e8 27 30 00 00       	call   f0103859 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100832:	83 c4 0c             	add    $0xc,%esp
f0100835:	68 0c 00 10 00       	push   $0x10000c
f010083a:	68 0c 00 10 f0       	push   $0xf010000c
f010083f:	68 54 6f 10 f0       	push   $0xf0106f54
f0100844:	e8 10 30 00 00       	call   f0103859 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100849:	83 c4 0c             	add    $0xc,%esp
f010084c:	68 f5 6a 10 00       	push   $0x106af5
f0100851:	68 f5 6a 10 f0       	push   $0xf0106af5
f0100856:	68 78 6f 10 f0       	push   $0xf0106f78
f010085b:	e8 f9 2f 00 00       	call   f0103859 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100860:	83 c4 0c             	add    $0xc,%esp
f0100863:	68 3c 83 2a 00       	push   $0x2a833c
f0100868:	68 3c 83 2a f0       	push   $0xf02a833c
f010086d:	68 9c 6f 10 f0       	push   $0xf0106f9c
f0100872:	e8 e2 2f 00 00       	call   f0103859 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100877:	83 c4 0c             	add    $0xc,%esp
f010087a:	68 c0 37 34 00       	push   $0x3437c0
f010087f:	68 c0 37 34 f0       	push   $0xf03437c0
f0100884:	68 c0 6f 10 f0       	push   $0xf0106fc0
f0100889:	e8 cb 2f 00 00       	call   f0103859 <cprintf>
f010088e:	b8 bf 3b 34 f0       	mov    $0xf0343bbf,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100893:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100898:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f010089b:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01008a0:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01008a6:	85 c0                	test   %eax,%eax
f01008a8:	0f 48 c2             	cmovs  %edx,%eax
f01008ab:	c1 f8 0a             	sar    $0xa,%eax
f01008ae:	50                   	push   %eax
f01008af:	68 e4 6f 10 f0       	push   $0xf0106fe4
f01008b4:	e8 a0 2f 00 00       	call   f0103859 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01008b9:	b8 00 00 00 00       	mov    $0x0,%eax
f01008be:	c9                   	leave  
f01008bf:	c3                   	ret    

f01008c0 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008c0:	55                   	push   %ebp
f01008c1:	89 e5                	mov    %esp,%ebp
f01008c3:	57                   	push   %edi
f01008c4:	56                   	push   %esi
f01008c5:	53                   	push   %ebx
f01008c6:	83 ec 38             	sub    $0x38,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01008c9:	89 eb                	mov    %ebp,%ebx
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
f01008cb:	68 b6 6e 10 f0       	push   $0xf0106eb6
f01008d0:	e8 84 2f 00 00       	call   f0103859 <cprintf>
	
	
	while (ebp){
f01008d5:	83 c4 10             	add    $0x10,%esp
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
		debuginfo_eip(eip, &sym);
f01008d8:	8d 7d d0             	lea    -0x30(%ebp),%edi
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f01008db:	eb 41                	jmp    f010091e <mon_backtrace+0x5e>
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
f01008dd:	8b 73 04             	mov    0x4(%ebx),%esi
		debuginfo_eip(eip, &sym);
f01008e0:	83 ec 08             	sub    $0x8,%esp
f01008e3:	57                   	push   %edi
f01008e4:	56                   	push   %esi
f01008e5:	e8 d2 40 00 00       	call   f01049bc <debuginfo_eip>
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n %s:%d: %.*s+%d\n",ebp,eip,
f01008ea:	89 f0                	mov    %esi,%eax
f01008ec:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01008ef:	89 04 24             	mov    %eax,(%esp)
f01008f2:	ff 75 d8             	pushl  -0x28(%ebp)
f01008f5:	ff 75 dc             	pushl  -0x24(%ebp)
f01008f8:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008fb:	ff 75 d0             	pushl  -0x30(%ebp)
f01008fe:	ff 73 18             	pushl  0x18(%ebx)
f0100901:	ff 73 14             	pushl  0x14(%ebx)
f0100904:	ff 73 10             	pushl  0x10(%ebx)
f0100907:	ff 73 0c             	pushl  0xc(%ebx)
f010090a:	ff 73 08             	pushl  0x8(%ebx)
f010090d:	56                   	push   %esi
f010090e:	53                   	push   %ebx
f010090f:	68 10 70 10 f0       	push   $0xf0107010
f0100914:	e8 40 2f 00 00       	call   f0103859 <cprintf>
		*((uint32_t *)ebp + 6), sym.eip_file,
			      sym.eip_line,
			      sym.eip_fn_namelen,
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
f0100919:	8b 1b                	mov    (%ebx),%ebx
f010091b:	83 c4 40             	add    $0x40,%esp
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f010091e:	85 db                	test   %ebx,%ebx
f0100920:	75 bb                	jne    f01008dd <mon_backtrace+0x1d>
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
	}
	return 0;
}
f0100922:	b8 00 00 00 00       	mov    $0x0,%eax
f0100927:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010092a:	5b                   	pop    %ebx
f010092b:	5e                   	pop    %esi
f010092c:	5f                   	pop    %edi
f010092d:	5d                   	pop    %ebp
f010092e:	c3                   	ret    

f010092f <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010092f:	55                   	push   %ebp
f0100930:	89 e5                	mov    %esp,%ebp
f0100932:	57                   	push   %edi
f0100933:	56                   	push   %esi
f0100934:	53                   	push   %ebx
f0100935:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100938:	68 54 70 10 f0       	push   $0xf0107054
f010093d:	e8 17 2f 00 00       	call   f0103859 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100942:	c7 04 24 78 70 10 f0 	movl   $0xf0107078,(%esp)
f0100949:	e8 0b 2f 00 00       	call   f0103859 <cprintf>

	if (tf != NULL)
f010094e:	83 c4 10             	add    $0x10,%esp
f0100951:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100955:	74 0e                	je     f0100965 <monitor+0x36>
		print_trapframe(tf);
f0100957:	83 ec 0c             	sub    $0xc,%esp
f010095a:	ff 75 08             	pushl  0x8(%ebp)
f010095d:	e8 13 31 00 00       	call   f0103a75 <print_trapframe>
f0100962:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100965:	83 ec 0c             	sub    $0xc,%esp
f0100968:	68 c8 6e 10 f0       	push   $0xf0106ec8
f010096d:	e8 71 48 00 00       	call   f01051e3 <readline>
f0100972:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100974:	83 c4 10             	add    $0x10,%esp
f0100977:	85 c0                	test   %eax,%eax
f0100979:	74 ea                	je     f0100965 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010097b:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100982:	be 00 00 00 00       	mov    $0x0,%esi
f0100987:	eb 0a                	jmp    f0100993 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100989:	c6 03 00             	movb   $0x0,(%ebx)
f010098c:	89 f7                	mov    %esi,%edi
f010098e:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100991:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100993:	0f b6 03             	movzbl (%ebx),%eax
f0100996:	84 c0                	test   %al,%al
f0100998:	74 63                	je     f01009fd <monitor+0xce>
f010099a:	83 ec 08             	sub    $0x8,%esp
f010099d:	0f be c0             	movsbl %al,%eax
f01009a0:	50                   	push   %eax
f01009a1:	68 cc 6e 10 f0       	push   $0xf0106ecc
f01009a6:	e8 6a 4a 00 00       	call   f0105415 <strchr>
f01009ab:	83 c4 10             	add    $0x10,%esp
f01009ae:	85 c0                	test   %eax,%eax
f01009b0:	75 d7                	jne    f0100989 <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f01009b2:	80 3b 00             	cmpb   $0x0,(%ebx)
f01009b5:	74 46                	je     f01009fd <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01009b7:	83 fe 0f             	cmp    $0xf,%esi
f01009ba:	75 14                	jne    f01009d0 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01009bc:	83 ec 08             	sub    $0x8,%esp
f01009bf:	6a 10                	push   $0x10
f01009c1:	68 d1 6e 10 f0       	push   $0xf0106ed1
f01009c6:	e8 8e 2e 00 00       	call   f0103859 <cprintf>
f01009cb:	83 c4 10             	add    $0x10,%esp
f01009ce:	eb 95                	jmp    f0100965 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f01009d0:	8d 7e 01             	lea    0x1(%esi),%edi
f01009d3:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01009d7:	eb 03                	jmp    f01009dc <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01009d9:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01009dc:	0f b6 03             	movzbl (%ebx),%eax
f01009df:	84 c0                	test   %al,%al
f01009e1:	74 ae                	je     f0100991 <monitor+0x62>
f01009e3:	83 ec 08             	sub    $0x8,%esp
f01009e6:	0f be c0             	movsbl %al,%eax
f01009e9:	50                   	push   %eax
f01009ea:	68 cc 6e 10 f0       	push   $0xf0106ecc
f01009ef:	e8 21 4a 00 00       	call   f0105415 <strchr>
f01009f4:	83 c4 10             	add    $0x10,%esp
f01009f7:	85 c0                	test   %eax,%eax
f01009f9:	74 de                	je     f01009d9 <monitor+0xaa>
f01009fb:	eb 94                	jmp    f0100991 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f01009fd:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100a04:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100a05:	85 f6                	test   %esi,%esi
f0100a07:	0f 84 58 ff ff ff    	je     f0100965 <monitor+0x36>
f0100a0d:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a12:	83 ec 08             	sub    $0x8,%esp
f0100a15:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a18:	ff 34 85 a0 70 10 f0 	pushl  -0xfef8f60(,%eax,4)
f0100a1f:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a22:	e8 90 49 00 00       	call   f01053b7 <strcmp>
f0100a27:	83 c4 10             	add    $0x10,%esp
f0100a2a:	85 c0                	test   %eax,%eax
f0100a2c:	75 22                	jne    f0100a50 <monitor+0x121>
			return commands[i].func(argc, argv, tf);
f0100a2e:	83 ec 04             	sub    $0x4,%esp
f0100a31:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a34:	ff 75 08             	pushl  0x8(%ebp)
f0100a37:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a3a:	52                   	push   %edx
f0100a3b:	56                   	push   %esi
f0100a3c:	ff 14 85 a8 70 10 f0 	call   *-0xfef8f58(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100a43:	83 c4 10             	add    $0x10,%esp
f0100a46:	85 c0                	test   %eax,%eax
f0100a48:	0f 89 17 ff ff ff    	jns    f0100965 <monitor+0x36>
f0100a4e:	eb 20                	jmp    f0100a70 <monitor+0x141>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100a50:	83 c3 01             	add    $0x1,%ebx
f0100a53:	83 fb 03             	cmp    $0x3,%ebx
f0100a56:	75 ba                	jne    f0100a12 <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a58:	83 ec 08             	sub    $0x8,%esp
f0100a5b:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a5e:	68 ee 6e 10 f0       	push   $0xf0106eee
f0100a63:	e8 f1 2d 00 00       	call   f0103859 <cprintf>
f0100a68:	83 c4 10             	add    $0x10,%esp
f0100a6b:	e9 f5 fe ff ff       	jmp    f0100965 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a70:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a73:	5b                   	pop    %ebx
f0100a74:	5e                   	pop    %esi
f0100a75:	5f                   	pop    %edi
f0100a76:	5d                   	pop    %ebp
f0100a77:	c3                   	ret    

f0100a78 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100a78:	89 d1                	mov    %edx,%ecx
f0100a7a:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100a7d:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100a80:	a8 01                	test   $0x1,%al
f0100a82:	74 52                	je     f0100ad6 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a84:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a89:	89 c1                	mov    %eax,%ecx
f0100a8b:	c1 e9 0c             	shr    $0xc,%ecx
f0100a8e:	3b 0d d8 9e 2a f0    	cmp    0xf02a9ed8,%ecx
f0100a94:	72 1b                	jb     f0100ab1 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a96:	55                   	push   %ebp
f0100a97:	89 e5                	mov    %esp,%ebp
f0100a99:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a9c:	50                   	push   %eax
f0100a9d:	68 24 6b 10 f0       	push   $0xf0106b24
f0100aa2:	68 10 04 00 00       	push   $0x410
f0100aa7:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0100aac:	e8 8f f5 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100ab1:	c1 ea 0c             	shr    $0xc,%edx
f0100ab4:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100aba:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100ac1:	89 c2                	mov    %eax,%edx
f0100ac3:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100ac6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100acb:	85 d2                	test   %edx,%edx
f0100acd:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100ad2:	0f 44 c2             	cmove  %edx,%eax
f0100ad5:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100ad6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100adb:	c3                   	ret    

f0100adc <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100adc:	83 3d 5c 92 2a f0 00 	cmpl   $0x0,0xf02a925c
f0100ae3:	75 11                	jne    f0100af6 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE); // Roundup function rounds according to the given functions
f0100ae5:	ba bf 47 34 f0       	mov    $0xf03447bf,%edx
f0100aea:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100af0:	89 15 5c 92 2a f0    	mov    %edx,0xf02a925c
	}
	
	if (n==0){
f0100af6:	85 c0                	test   %eax,%eax
f0100af8:	75 06                	jne    f0100b00 <boot_alloc+0x24>
	return nextfree;
f0100afa:	a1 5c 92 2a f0       	mov    0xf02a925c,%eax
f0100aff:	c3                   	ret    
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result  = nextfree;
f0100b00:	8b 0d 5c 92 2a f0    	mov    0xf02a925c,%ecx
	nextfree += ROUNDUP(n,PGSIZE);
f0100b06:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100b0b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b10:	8d 14 01             	lea    (%ecx,%eax,1),%edx
f0100b13:	89 15 5c 92 2a f0    	mov    %edx,0xf02a925c
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100b19:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0100b1f:	77 18                	ja     f0100b39 <boot_alloc+0x5d>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100b21:	55                   	push   %ebp
f0100b22:	89 e5                	mov    %esp,%ebp
f0100b24:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100b27:	52                   	push   %edx
f0100b28:	68 48 6b 10 f0       	push   $0xf0106b48
f0100b2d:	6a 71                	push   $0x71
f0100b2f:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0100b34:	e8 07 f5 ff ff       	call   f0100040 <_panic>
	// LAB 2: Your code here.
	result  = nextfree;
	nextfree += ROUNDUP(n,PGSIZE);
	
	
	if ((PADDR(nextfree))>npages*PGSIZE){
f0100b39:	a1 d8 9e 2a f0       	mov    0xf02a9ed8,%eax
f0100b3e:	c1 e0 0c             	shl    $0xc,%eax
	return (physaddr_t)kva - KERNBASE;
f0100b41:	81 c2 00 00 00 10    	add    $0x10000000,%edx
		return 0;
	}
	return result;
f0100b47:	39 c2                	cmp    %eax,%edx
f0100b49:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b4e:	0f 46 c1             	cmovbe %ecx,%eax
}
f0100b51:	c3                   	ret    

f0100b52 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100b52:	55                   	push   %ebp
f0100b53:	89 e5                	mov    %esp,%ebp
f0100b55:	57                   	push   %edi
f0100b56:	56                   	push   %esi
f0100b57:	53                   	push   %ebx
f0100b58:	83 ec 3c             	sub    $0x3c,%esp
f0100b5b:	89 45 c0             	mov    %eax,-0x40(%ebp)
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b5e:	84 c0                	test   %al,%al
f0100b60:	0f 85 b1 02 00 00    	jne    f0100e17 <check_page_free_list+0x2c5>
f0100b66:	e9 be 02 00 00       	jmp    f0100e29 <check_page_free_list+0x2d7>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100b6b:	83 ec 04             	sub    $0x4,%esp
f0100b6e:	68 c4 70 10 f0       	push   $0xf01070c4
f0100b73:	68 44 03 00 00       	push   $0x344
f0100b78:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0100b7d:	e8 be f4 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100b82:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100b85:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100b88:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b8b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b8e:	89 c2                	mov    %eax,%edx
f0100b90:	2b 15 e0 9e 2a f0    	sub    0xf02a9ee0,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100b96:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100b9c:	0f 95 c2             	setne  %dl
f0100b9f:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100ba2:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100ba6:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100ba8:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bac:	8b 00                	mov    (%eax),%eax
f0100bae:	85 c0                	test   %eax,%eax
f0100bb0:	75 dc                	jne    f0100b8e <check_page_free_list+0x3c>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100bb2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bb5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100bbb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bbe:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100bc1:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100bc3:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100bc6:	a3 64 92 2a f0       	mov    %eax,0xf02a9264
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bcb:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bd0:	8b 1d 64 92 2a f0    	mov    0xf02a9264,%ebx
f0100bd6:	eb 53                	jmp    f0100c2b <check_page_free_list+0xd9>
f0100bd8:	89 d8                	mov    %ebx,%eax
f0100bda:	2b 05 e0 9e 2a f0    	sub    0xf02a9ee0,%eax
f0100be0:	c1 f8 03             	sar    $0x3,%eax
f0100be3:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100be6:	89 c2                	mov    %eax,%edx
f0100be8:	c1 ea 16             	shr    $0x16,%edx
f0100beb:	39 f2                	cmp    %esi,%edx
f0100bed:	73 3a                	jae    f0100c29 <check_page_free_list+0xd7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bef:	89 c2                	mov    %eax,%edx
f0100bf1:	c1 ea 0c             	shr    $0xc,%edx
f0100bf4:	3b 15 d8 9e 2a f0    	cmp    0xf02a9ed8,%edx
f0100bfa:	72 12                	jb     f0100c0e <check_page_free_list+0xbc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bfc:	50                   	push   %eax
f0100bfd:	68 24 6b 10 f0       	push   $0xf0106b24
f0100c02:	6a 58                	push   $0x58
f0100c04:	68 c1 7a 10 f0       	push   $0xf0107ac1
f0100c09:	e8 32 f4 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100c0e:	83 ec 04             	sub    $0x4,%esp
f0100c11:	68 80 00 00 00       	push   $0x80
f0100c16:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100c1b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c20:	50                   	push   %eax
f0100c21:	e8 2c 48 00 00       	call   f0105452 <memset>
f0100c26:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c29:	8b 1b                	mov    (%ebx),%ebx
f0100c2b:	85 db                	test   %ebx,%ebx
f0100c2d:	75 a9                	jne    f0100bd8 <check_page_free_list+0x86>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100c2f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c34:	e8 a3 fe ff ff       	call   f0100adc <boot_alloc>
f0100c39:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c3c:	8b 15 64 92 2a f0    	mov    0xf02a9264,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c42:	8b 0d e0 9e 2a f0    	mov    0xf02a9ee0,%ecx
		assert(pp < pages + npages);
f0100c48:	a1 d8 9e 2a f0       	mov    0xf02a9ed8,%eax
f0100c4d:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100c50:	8d 34 c1             	lea    (%ecx,%eax,8),%esi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c53:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c56:	bf 00 00 00 00       	mov    $0x0,%edi
f0100c5b:	89 5d cc             	mov    %ebx,-0x34(%ebp)
f0100c5e:	89 f0                	mov    %esi,%eax
f0100c60:	89 ce                	mov    %ecx,%esi
f0100c62:	89 c1                	mov    %eax,%ecx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c64:	e9 55 01 00 00       	jmp    f0100dbe <check_page_free_list+0x26c>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c69:	39 f2                	cmp    %esi,%edx
f0100c6b:	73 19                	jae    f0100c86 <check_page_free_list+0x134>
f0100c6d:	68 cf 7a 10 f0       	push   $0xf0107acf
f0100c72:	68 db 7a 10 f0       	push   $0xf0107adb
f0100c77:	68 5e 03 00 00       	push   $0x35e
f0100c7c:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0100c81:	e8 ba f3 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100c86:	39 ca                	cmp    %ecx,%edx
f0100c88:	72 19                	jb     f0100ca3 <check_page_free_list+0x151>
f0100c8a:	68 f0 7a 10 f0       	push   $0xf0107af0
f0100c8f:	68 db 7a 10 f0       	push   $0xf0107adb
f0100c94:	68 5f 03 00 00       	push   $0x35f
f0100c99:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0100c9e:	e8 9d f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ca3:	89 d0                	mov    %edx,%eax
f0100ca5:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100ca8:	a8 07                	test   $0x7,%al
f0100caa:	74 19                	je     f0100cc5 <check_page_free_list+0x173>
f0100cac:	68 e8 70 10 f0       	push   $0xf01070e8
f0100cb1:	68 db 7a 10 f0       	push   $0xf0107adb
f0100cb6:	68 60 03 00 00       	push   $0x360
f0100cbb:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0100cc0:	e8 7b f3 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100cc5:	c1 f8 03             	sar    $0x3,%eax
f0100cc8:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100ccb:	85 c0                	test   %eax,%eax
f0100ccd:	75 19                	jne    f0100ce8 <check_page_free_list+0x196>
f0100ccf:	68 04 7b 10 f0       	push   $0xf0107b04
f0100cd4:	68 db 7a 10 f0       	push   $0xf0107adb
f0100cd9:	68 63 03 00 00       	push   $0x363
f0100cde:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0100ce3:	e8 58 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ce8:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100ced:	75 19                	jne    f0100d08 <check_page_free_list+0x1b6>
f0100cef:	68 15 7b 10 f0       	push   $0xf0107b15
f0100cf4:	68 db 7a 10 f0       	push   $0xf0107adb
f0100cf9:	68 64 03 00 00       	push   $0x364
f0100cfe:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0100d03:	e8 38 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d08:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100d0d:	75 19                	jne    f0100d28 <check_page_free_list+0x1d6>
f0100d0f:	68 1c 71 10 f0       	push   $0xf010711c
f0100d14:	68 db 7a 10 f0       	push   $0xf0107adb
f0100d19:	68 65 03 00 00       	push   $0x365
f0100d1e:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0100d23:	e8 18 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d28:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100d2d:	75 19                	jne    f0100d48 <check_page_free_list+0x1f6>
f0100d2f:	68 2e 7b 10 f0       	push   $0xf0107b2e
f0100d34:	68 db 7a 10 f0       	push   $0xf0107adb
f0100d39:	68 66 03 00 00       	push   $0x366
f0100d3e:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0100d43:	e8 f8 f2 ff ff       	call   f0100040 <_panic>
f0100d48:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d4b:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d50:	0f 86 ea 00 00 00    	jbe    f0100e40 <check_page_free_list+0x2ee>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d56:	89 c3                	mov    %eax,%ebx
f0100d58:	c1 eb 0c             	shr    $0xc,%ebx
f0100d5b:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f0100d5e:	77 12                	ja     f0100d72 <check_page_free_list+0x220>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d60:	50                   	push   %eax
f0100d61:	68 24 6b 10 f0       	push   $0xf0106b24
f0100d66:	6a 58                	push   $0x58
f0100d68:	68 c1 7a 10 f0       	push   $0xf0107ac1
f0100d6d:	e8 ce f2 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100d72:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
f0100d78:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100d7b:	0f 86 cf 00 00 00    	jbe    f0100e50 <check_page_free_list+0x2fe>
f0100d81:	68 40 71 10 f0       	push   $0xf0107140
f0100d86:	68 db 7a 10 f0       	push   $0xf0107adb
f0100d8b:	68 67 03 00 00       	push   $0x367
f0100d90:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0100d95:	e8 a6 f2 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100d9a:	68 48 7b 10 f0       	push   $0xf0107b48
f0100d9f:	68 db 7a 10 f0       	push   $0xf0107adb
f0100da4:	68 69 03 00 00       	push   $0x369
f0100da9:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0100dae:	e8 8d f2 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100db3:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0100db7:	eb 03                	jmp    f0100dbc <check_page_free_list+0x26a>
		else
			++nfree_extmem;
f0100db9:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100dbc:	8b 12                	mov    (%edx),%edx
f0100dbe:	85 d2                	test   %edx,%edx
f0100dc0:	0f 85 a3 fe ff ff    	jne    f0100c69 <check_page_free_list+0x117>
f0100dc6:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100dc9:	85 db                	test   %ebx,%ebx
f0100dcb:	7f 19                	jg     f0100de6 <check_page_free_list+0x294>
f0100dcd:	68 65 7b 10 f0       	push   $0xf0107b65
f0100dd2:	68 db 7a 10 f0       	push   $0xf0107adb
f0100dd7:	68 71 03 00 00       	push   $0x371
f0100ddc:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0100de1:	e8 5a f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100de6:	85 ff                	test   %edi,%edi
f0100de8:	7f 19                	jg     f0100e03 <check_page_free_list+0x2b1>
f0100dea:	68 77 7b 10 f0       	push   $0xf0107b77
f0100def:	68 db 7a 10 f0       	push   $0xf0107adb
f0100df4:	68 72 03 00 00       	push   $0x372
f0100df9:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0100dfe:	e8 3d f2 ff ff       	call   f0100040 <_panic>
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
f0100e03:	83 ec 08             	sub    $0x8,%esp
f0100e06:	0f b6 45 c0          	movzbl -0x40(%ebp),%eax
f0100e0a:	50                   	push   %eax
f0100e0b:	68 88 71 10 f0       	push   $0xf0107188
f0100e10:	e8 44 2a 00 00       	call   f0103859 <cprintf>
f0100e15:	eb 49                	jmp    f0100e60 <check_page_free_list+0x30e>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100e17:	a1 64 92 2a f0       	mov    0xf02a9264,%eax
f0100e1c:	85 c0                	test   %eax,%eax
f0100e1e:	0f 85 5e fd ff ff    	jne    f0100b82 <check_page_free_list+0x30>
f0100e24:	e9 42 fd ff ff       	jmp    f0100b6b <check_page_free_list+0x19>
f0100e29:	83 3d 64 92 2a f0 00 	cmpl   $0x0,0xf02a9264
f0100e30:	0f 84 35 fd ff ff    	je     f0100b6b <check_page_free_list+0x19>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e36:	be 00 04 00 00       	mov    $0x400,%esi
f0100e3b:	e9 90 fd ff ff       	jmp    f0100bd0 <check_page_free_list+0x7e>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100e40:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e45:	0f 85 68 ff ff ff    	jne    f0100db3 <check_page_free_list+0x261>
f0100e4b:	e9 4a ff ff ff       	jmp    f0100d9a <check_page_free_list+0x248>
f0100e50:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e55:	0f 85 5e ff ff ff    	jne    f0100db9 <check_page_free_list+0x267>
f0100e5b:	e9 3a ff ff ff       	jmp    f0100d9a <check_page_free_list+0x248>
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
}
f0100e60:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e63:	5b                   	pop    %ebx
f0100e64:	5e                   	pop    %esi
f0100e65:	5f                   	pop    %edi
f0100e66:	5d                   	pop    %ebp
f0100e67:	c3                   	ret    

f0100e68 <page_init>:
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100e68:	b8 01 00 00 00       	mov    $0x1,%eax
f0100e6d:	eb 18                	jmp    f0100e87 <page_init+0x1f>
	{
	 pages[i].pp_ref = 1; //Used Pages
f0100e6f:	8b 15 e0 9e 2a f0    	mov    0xf02a9ee0,%edx
f0100e75:	8d 14 c2             	lea    (%edx,%eax,8),%edx
f0100e78:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
	 pages[i].pp_link = 0; // No links to any pages
f0100e7e:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100e84:	83 c0 01             	add    $0x1,%eax
f0100e87:	3b 05 d8 9e 2a f0    	cmp    0xf02a9ed8,%eax
f0100e8d:	72 e0                	jb     f0100e6f <page_init+0x7>
//


void
page_init(void)
{
f0100e8f:	55                   	push   %ebp
f0100e90:	89 e5                	mov    %esp,%ebp
f0100e92:	57                   	push   %edi
f0100e93:	56                   	push   %esi
f0100e94:	53                   	push   %ebx
f0100e95:	83 ec 0c             	sub    $0xc,%esp
	//Modification for Lab 4, We have to skip the Page that MPENTRY_PADDR is at from the page_free_list
	//Hence we can divide it with PGSIZE and whatever is the value, just skip that page. 
	size_t mpentyPg = MPENTRY_PADDR/PGSIZE;

	// 2. The rest of base memory 
	page_free_list = 0 ;
f0100e98:	c7 05 64 92 2a f0 00 	movl   $0x0,0xf02a9264
f0100e9f:	00 00 00 
	
	struct PageInfo *prev = 0;
	for (i = 1; i < npages_basemem; ++i) {
f0100ea2:	be 00 00 00 00       	mov    $0x0,%esi
	size_t mpentyPg = MPENTRY_PADDR/PGSIZE;

	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	struct PageInfo *prev = 0;
f0100ea7:	bf 00 00 00 00       	mov    $0x0,%edi
	for (i = 1; i < npages_basemem; ++i) {
f0100eac:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100eb1:	eb 71                	jmp    f0100f24 <page_init+0xbc>
		if (i == mpentyPg) {
f0100eb3:	83 fb 07             	cmp    $0x7,%ebx
f0100eb6:	75 14                	jne    f0100ecc <page_init+0x64>
			cprintf("Skipped this page %d\n", i);
f0100eb8:	83 ec 08             	sub    $0x8,%esp
f0100ebb:	6a 07                	push   $0x7
f0100ebd:	68 88 7b 10 f0       	push   $0xf0107b88
f0100ec2:	e8 92 29 00 00       	call   f0103859 <cprintf>
			continue;	
f0100ec7:	83 c4 10             	add    $0x10,%esp
f0100eca:	eb 52                	jmp    f0100f1e <page_init+0xb6>
f0100ecc:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
		}

		pages[i].pp_ref = 0;
f0100ed3:	8b 15 e0 9e 2a f0    	mov    0xf02a9ee0,%edx
f0100ed9:	66 c7 44 02 04 00 00 	movw   $0x0,0x4(%edx,%eax,1)
		pages[i].pp_link = 0;
f0100ee0:	c7 04 da 00 00 00 00 	movl   $0x0,(%edx,%ebx,8)
		if (!page_free_list) {
f0100ee7:	83 3d 64 92 2a f0 00 	cmpl   $0x0,0xf02a9264
f0100eee:	75 10                	jne    f0100f00 <page_init+0x98>
			page_free_list = &pages[i];
f0100ef0:	89 c2                	mov    %eax,%edx
f0100ef2:	03 15 e0 9e 2a f0    	add    0xf02a9ee0,%edx
f0100ef8:	89 15 64 92 2a f0    	mov    %edx,0xf02a9264
f0100efe:	eb 16                	jmp    f0100f16 <page_init+0xae>
		} else {
			prev->pp_link = &pages[i];
f0100f00:	89 c2                	mov    %eax,%edx
f0100f02:	03 15 e0 9e 2a f0    	add    0xf02a9ee0,%edx
f0100f08:	89 17                	mov    %edx,(%edi)
			pages[i-1].pp_link = &pages[i];
f0100f0a:	8b 15 e0 9e 2a f0    	mov    0xf02a9ee0,%edx
f0100f10:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
f0100f13:	89 0c 32             	mov    %ecx,(%edx,%esi,1)
		}
		prev = &pages[i];
f0100f16:	03 05 e0 9e 2a f0    	add    0xf02a9ee0,%eax
f0100f1c:	89 c7                	mov    %eax,%edi

	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	struct PageInfo *prev = 0;
	for (i = 1; i < npages_basemem; ++i) {
f0100f1e:	83 c3 01             	add    $0x1,%ebx
f0100f21:	83 c6 08             	add    $0x8,%esi
f0100f24:	3b 1d 68 92 2a f0    	cmp    0xf02a9268,%ebx
f0100f2a:	72 87                	jb     f0100eb3 <page_init+0x4b>
		prev = &pages[i];
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
f0100f2c:	8d 04 dd f8 ff ff ff 	lea    -0x8(,%ebx,8),%eax
f0100f33:	03 05 e0 9e 2a f0    	add    0xf02a9ee0,%eax
f0100f39:	a3 58 92 2a f0       	mov    %eax,0xf02a9258
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100f3e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f43:	e8 94 fb ff ff       	call   f0100adc <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100f48:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100f4d:	77 15                	ja     f0100f64 <page_init+0xfc>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100f4f:	50                   	push   %eax
f0100f50:	68 48 6b 10 f0       	push   $0xf0106b48
f0100f55:	68 75 01 00 00       	push   $0x175
f0100f5a:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0100f5f:	e8 dc f0 ff ff       	call   f0100040 <_panic>
f0100f64:	05 ff 0f 00 10       	add    $0x10000fff,%eax
f0100f69:	c1 e8 0c             	shr    $0xc,%eax
f0100f6c:	8b 1d 58 92 2a f0    	mov    0xf02a9258,%ebx
f0100f72:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100f79:	eb 2c                	jmp    f0100fa7 <page_init+0x13f>
		pages[i].pp_ref = 0;
f0100f7b:	89 d1                	mov    %edx,%ecx
f0100f7d:	03 0d e0 9e 2a f0    	add    0xf02a9ee0,%ecx
f0100f83:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = 0;
f0100f89:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		track->pp_link = &pages[i];
f0100f8f:	89 d1                	mov    %edx,%ecx
f0100f91:	03 0d e0 9e 2a f0    	add    0xf02a9ee0,%ecx
f0100f97:	89 0b                	mov    %ecx,(%ebx)
		track = &pages[i];
f0100f99:	89 d3                	mov    %edx,%ebx
f0100f9b:	03 1d e0 9e 2a f0    	add    0xf02a9ee0,%ebx
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100fa1:	83 c0 01             	add    $0x1,%eax
f0100fa4:	83 c2 08             	add    $0x8,%edx
f0100fa7:	3b 05 d8 9e 2a f0    	cmp    0xf02a9ed8,%eax
f0100fad:	72 cc                	jb     f0100f7b <page_init+0x113>
f0100faf:	89 1d 58 92 2a f0    	mov    %ebx,0xf02a9258
		pages[i].pp_link = 0;
		track->pp_link = &pages[i];
		track = &pages[i];
	}
	
	cprintf("Check first entry of pages &pages[0] = %x\n", &pages[0]);
f0100fb5:	83 ec 08             	sub    $0x8,%esp
f0100fb8:	ff 35 e0 9e 2a f0    	pushl  0xf02a9ee0
f0100fbe:	68 b0 71 10 f0       	push   $0xf01071b0
f0100fc3:	e8 91 28 00 00       	call   f0103859 <cprintf>
	cprintf("&pages[npages-1] = %x\n", &pages[npages-1]);
f0100fc8:	83 c4 08             	add    $0x8,%esp
f0100fcb:	a1 d8 9e 2a f0       	mov    0xf02a9ed8,%eax
f0100fd0:	8d 04 c5 f8 ff ff ff 	lea    -0x8(,%eax,8),%eax
f0100fd7:	03 05 e0 9e 2a f0    	add    0xf02a9ee0,%eax
f0100fdd:	50                   	push   %eax
f0100fde:	68 9e 7b 10 f0       	push   $0xf0107b9e
f0100fe3:	e8 71 28 00 00       	call   f0103859 <cprintf>
f0100fe8:	83 c4 10             	add    $0x10,%esp
}
f0100feb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fee:	5b                   	pop    %ebx
f0100fef:	5e                   	pop    %esi
f0100ff0:	5f                   	pop    %edi
f0100ff1:	5d                   	pop    %ebp
f0100ff2:	c3                   	ret    

f0100ff3 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100ff3:	55                   	push   %ebp
f0100ff4:	89 e5                	mov    %esp,%ebp
f0100ff6:	53                   	push   %ebx
f0100ff7:	83 ec 04             	sub    $0x4,%esp
	// Check if there is a free_page available 
	if (!page_free_list)
f0100ffa:	8b 1d 64 92 2a f0    	mov    0xf02a9264,%ebx
f0101000:	85 db                	test   %ebx,%ebx
f0101002:	74 5e                	je     f0101062 <page_alloc+0x6f>
	return NULL;
	}
	
	struct PageInfo *allocPage = NULL;   //Create a temporary pointer 
	allocPage = page_free_list;	//Point to the current head of free_page_list
	page_free_list = allocPage ->pp_link; //Move the head to the next avaialble page
f0101004:	8b 03                	mov    (%ebx),%eax
f0101006:	a3 64 92 2a f0       	mov    %eax,0xf02a9264
	allocPage->pp_link = NULL;	//Break the link 
f010100b:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags && ALLOC_ZERO){		//ALLOC_ZERO = 1<<0; which is nothing but  = 1
f0101011:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0101015:	74 45                	je     f010105c <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101017:	89 d8                	mov    %ebx,%eax
f0101019:	2b 05 e0 9e 2a f0    	sub    0xf02a9ee0,%eax
f010101f:	c1 f8 03             	sar    $0x3,%eax
f0101022:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101025:	89 c2                	mov    %eax,%edx
f0101027:	c1 ea 0c             	shr    $0xc,%edx
f010102a:	3b 15 d8 9e 2a f0    	cmp    0xf02a9ed8,%edx
f0101030:	72 12                	jb     f0101044 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101032:	50                   	push   %eax
f0101033:	68 24 6b 10 f0       	push   $0xf0106b24
f0101038:	6a 58                	push   $0x58
f010103a:	68 c1 7a 10 f0       	push   $0xf0107ac1
f010103f:	e8 fc ef ff ff       	call   f0100040 <_panic>
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
f0101044:	83 ec 04             	sub    $0x4,%esp
f0101047:	68 00 10 00 00       	push   $0x1000
f010104c:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f010104e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101053:	50                   	push   %eax
f0101054:	e8 f9 43 00 00       	call   f0105452 <memset>
f0101059:	83 c4 10             	add    $0x10,%esp
	}
	
	allocPage->pp_ref = 0;
f010105c:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return allocPage;
}
f0101062:	89 d8                	mov    %ebx,%eax
f0101064:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101067:	c9                   	leave  
f0101068:	c3                   	ret    

f0101069 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0101069:	55                   	push   %ebp
f010106a:	89 e5                	mov    %esp,%ebp
f010106c:	83 ec 08             	sub    $0x8,%esp
f010106f:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	
	if(pp->pp_ref)
f0101072:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101077:	74 17                	je     f0101090 <page_free+0x27>
	{
	panic("Page cannot be returned to free list, as it is still refernced ");
f0101079:	83 ec 04             	sub    $0x4,%esp
f010107c:	68 dc 71 10 f0       	push   $0xf01071dc
f0101081:	68 ad 01 00 00       	push   $0x1ad
f0101086:	68 b5 7a 10 f0       	push   $0xf0107ab5
f010108b:	e8 b0 ef ff ff       	call   f0100040 <_panic>
	return;
	}
	
	// pp->pp_link is not NULL.
	else if(!pp) 
f0101090:	85 c0                	test   %eax,%eax
f0101092:	75 17                	jne    f01010ab <page_free+0x42>
	{
	panic("Page cannot be returned to free list as it is Null");
f0101094:	83 ec 04             	sub    $0x4,%esp
f0101097:	68 1c 72 10 f0       	push   $0xf010721c
f010109c:	68 b4 01 00 00       	push   $0x1b4
f01010a1:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01010a6:	e8 95 ef ff ff       	call   f0100040 <_panic>
	return;
	}
	
       else{
	pp->pp_link = page_free_list;
f01010ab:	8b 15 64 92 2a f0    	mov    0xf02a9264,%edx
f01010b1:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f01010b3:	a3 64 92 2a f0       	mov    %eax,0xf02a9264
	}


}
f01010b8:	c9                   	leave  
f01010b9:	c3                   	ret    

f01010ba <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f01010ba:	55                   	push   %ebp
f01010bb:	89 e5                	mov    %esp,%ebp
f01010bd:	83 ec 08             	sub    $0x8,%esp
f01010c0:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f01010c3:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f01010c7:	83 e8 01             	sub    $0x1,%eax
f01010ca:	66 89 42 04          	mov    %ax,0x4(%edx)
f01010ce:	66 85 c0             	test   %ax,%ax
f01010d1:	75 0c                	jne    f01010df <page_decref+0x25>
		page_free(pp);
f01010d3:	83 ec 0c             	sub    $0xc,%esp
f01010d6:	52                   	push   %edx
f01010d7:	e8 8d ff ff ff       	call   f0101069 <page_free>
f01010dc:	83 c4 10             	add    $0x10,%esp
}
f01010df:	c9                   	leave  
f01010e0:	c3                   	ret    

f01010e1 <pgdir_walk>:
// table and page directory entries.
//

pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01010e1:	55                   	push   %ebp
f01010e2:	89 e5                	mov    %esp,%ebp
f01010e4:	57                   	push   %edi
f01010e5:	56                   	push   %esi
f01010e6:	53                   	push   %ebx
f01010e7:	83 ec 0c             	sub    $0xc,%esp
	pte_t *pgTab;  //Page Table index variable

	//To find the index from the pgdir we need to get the MS 10 bits,
	//We get the MS 10bits of the virtual address by using PDX function (found in inc/mmu.h ) 
	//#define PDX(la)		((((uintptr_t) (la)) >> PDXSHIFT) & 0x3FF)
	pgDir = &pgdir[PDX(va)];
f01010ea:	8b 75 0c             	mov    0xc(%ebp),%esi
f01010ed:	c1 ee 16             	shr    $0x16,%esi
f01010f0:	c1 e6 02             	shl    $0x2,%esi
f01010f3:	03 75 08             	add    0x8(%ebp),%esi

	// Check if page is present, PTE_P = 0x1 means page present  
	if (*pgDir & PTE_P)  {
f01010f6:	8b 1e                	mov    (%esi),%ebx
f01010f8:	f6 c3 01             	test   $0x1,%bl
f01010fb:	74 30                	je     f010112d <pgdir_walk+0x4c>
		//page table entry to get to the final address translation. Now using the pgDir we can use the 
		//PTE_ADDR(pde) function to get the upper 20 bits, but this function returns a physical address. 
		//Since the kernel requires a virtual address, we can use the function KADDR to get the virtual 
		//address.
		
		pgTab = (pte_t*) KADDR(PTE_ADDR(*pgDir));
f01010fd:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101103:	89 d8                	mov    %ebx,%eax
f0101105:	c1 e8 0c             	shr    $0xc,%eax
f0101108:	3b 05 d8 9e 2a f0    	cmp    0xf02a9ed8,%eax
f010110e:	72 15                	jb     f0101125 <pgdir_walk+0x44>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101110:	53                   	push   %ebx
f0101111:	68 24 6b 10 f0       	push   $0xf0106b24
f0101116:	68 f5 01 00 00       	push   $0x1f5
f010111b:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101120:	e8 1b ef ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101125:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
f010112b:	eb 7c                	jmp    f01011a9 <pgdir_walk+0xc8>
	//If page is not present 
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
f010112d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101131:	0f 84 81 00 00 00    	je     f01011b8 <pgdir_walk+0xd7>
f0101137:	83 ec 0c             	sub    $0xc,%esp
f010113a:	68 00 10 00 00       	push   $0x1000
f010113f:	e8 af fe ff ff       	call   f0100ff3 <page_alloc>
f0101144:	89 c7                	mov    %eax,%edi
f0101146:	83 c4 10             	add    $0x10,%esp
f0101149:	85 c0                	test   %eax,%eax
f010114b:	74 72                	je     f01011bf <pgdir_walk+0xde>
			return 0;
		}

		newPage->pp_ref++;  //Increment the ref pointer of the page 
f010114d:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101152:	89 c3                	mov    %eax,%ebx
f0101154:	2b 1d e0 9e 2a f0    	sub    0xf02a9ee0,%ebx
f010115a:	c1 fb 03             	sar    $0x3,%ebx
f010115d:	c1 e3 0c             	shl    $0xc,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101160:	89 d8                	mov    %ebx,%eax
f0101162:	c1 e8 0c             	shr    $0xc,%eax
f0101165:	3b 05 d8 9e 2a f0    	cmp    0xf02a9ed8,%eax
f010116b:	72 12                	jb     f010117f <pgdir_walk+0x9e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010116d:	53                   	push   %ebx
f010116e:	68 24 6b 10 f0       	push   $0xf0106b24
f0101173:	6a 58                	push   $0x58
f0101175:	68 c1 7a 10 f0       	push   $0xf0107ac1
f010117a:	e8 c1 ee ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010117f:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
		//Now this section creates the bindings and updates all the flags 
		//for relevant use of the page.
		
		//First create a link on the pgTab wrt to the new page
		pgTab = (pte_t*)page2kva(newPage); // this function gets the virtual address of the new page
		memset (pgTab, 0, PGSIZE); //Clear the entire page
f0101185:	83 ec 04             	sub    $0x4,%esp
f0101188:	68 00 10 00 00       	push   $0x1000
f010118d:	6a 00                	push   $0x0
f010118f:	53                   	push   %ebx
f0101190:	e8 bd 42 00 00       	call   f0105452 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101195:	2b 3d e0 9e 2a f0    	sub    0xf02a9ee0,%edi
f010119b:	c1 ff 03             	sar    $0x3,%edi
f010119e:	c1 e7 0c             	shl    $0xc,%edi

		//Page Table, pgTab contains the virtual address , now we need to set the permission bits.
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
f01011a1:	83 cf 07             	or     $0x7,%edi
f01011a4:	89 3e                	mov    %edi,(%esi)
f01011a6:	83 c4 10             	add    $0x10,%esp
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
f01011a9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011ac:	c1 e8 0a             	shr    $0xa,%eax
f01011af:	25 fc 0f 00 00       	and    $0xffc,%eax
f01011b4:	01 d8                	add    %ebx,%eax
f01011b6:	eb 0c                	jmp    f01011c4 <pgdir_walk+0xe3>
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
			return 0;
f01011b8:	b8 00 00 00 00       	mov    $0x0,%eax
f01011bd:	eb 05                	jmp    f01011c4 <pgdir_walk+0xe3>
f01011bf:	b8 00 00 00 00       	mov    $0x0,%eax
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
}
f01011c4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011c7:	5b                   	pop    %ebx
f01011c8:	5e                   	pop    %esi
f01011c9:	5f                   	pop    %edi
f01011ca:	5d                   	pop    %ebp
f01011cb:	c3                   	ret    

f01011cc <boot_map_region>:
//
// Hint: the TA solution uses pgdir_walk

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01011cc:	55                   	push   %ebp
f01011cd:	89 e5                	mov    %esp,%ebp
f01011cf:	57                   	push   %edi
f01011d0:	56                   	push   %esi
f01011d1:	53                   	push   %ebx
f01011d2:	83 ec 1c             	sub    $0x1c,%esp
f01011d5:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f01011d8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
f01011de:	8b 45 08             	mov    0x8(%ebp),%eax
f01011e1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	size = ROUNDUP(size, PGSIZE); 
f01011e6:	8d b9 ff 0f 00 00    	lea    0xfff(%ecx),%edi
f01011ec:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f01011f2:	89 d3                	mov    %edx,%ebx
f01011f4:	29 d0                	sub    %edx,%eax
f01011f6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01011f9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011fc:	83 c8 01             	or     $0x1,%eax
f01011ff:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f0101202:	eb 3d                	jmp    f0101241 <boot_map_region+0x75>
		if (!(pgTbEnt = pgdir_walk(pgdir, (const void*)vaBegin, 1))){
f0101204:	83 ec 04             	sub    $0x4,%esp
f0101207:	6a 01                	push   $0x1
f0101209:	53                   	push   %ebx
f010120a:	ff 75 e0             	pushl  -0x20(%ebp)
f010120d:	e8 cf fe ff ff       	call   f01010e1 <pgdir_walk>
f0101212:	83 c4 10             	add    $0x10,%esp
f0101215:	85 c0                	test   %eax,%eax
f0101217:	75 17                	jne    f0101230 <boot_map_region+0x64>
			panic("Cannot find page for the page table entry, from boot_map_region function");
f0101219:	83 ec 04             	sub    $0x4,%esp
f010121c:	68 50 72 10 f0       	push   $0xf0107250
f0101221:	68 2b 02 00 00       	push   $0x22b
f0101226:	68 b5 7a 10 f0       	push   $0xf0107ab5
f010122b:	e8 10 ee ff ff       	call   f0100040 <_panic>
		}
		//if (*pgTbEnt & PTE_P)
		//	panic("Page is already mapped");
		
		
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
f0101230:	0b 75 dc             	or     -0x24(%ebp),%esi
f0101233:	89 30                	mov    %esi,(%eax)
		vaBegin += PGSIZE;
f0101235:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		paBegin += PGSIZE; 
		size -= PGSIZE;
f010123b:	81 ef 00 10 00 00    	sub    $0x1000,%edi
f0101241:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101244:	8d 34 18             	lea    (%eax,%ebx,1),%esi
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f0101247:	85 ff                	test   %edi,%edi
f0101249:	75 b9                	jne    f0101204 <boot_map_region+0x38>
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
		vaBegin += PGSIZE;
		paBegin += PGSIZE; 
		size -= PGSIZE;
	} 	
}
f010124b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010124e:	5b                   	pop    %ebx
f010124f:	5e                   	pop    %esi
f0101250:	5f                   	pop    %edi
f0101251:	5d                   	pop    %ebp
f0101252:	c3                   	ret    

f0101253 <page_lookup>:
// Hint: the TA solution uses pgdir_walk and pa2page.
//

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101253:	55                   	push   %ebp
f0101254:	89 e5                	mov    %esp,%ebp
f0101256:	53                   	push   %ebx
f0101257:	83 ec 08             	sub    $0x8,%esp
f010125a:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
	pgTbEty = pgdir_walk(pgdir, va, 0);
f010125d:	6a 00                	push   $0x0
f010125f:	ff 75 0c             	pushl  0xc(%ebp)
f0101262:	ff 75 08             	pushl  0x8(%ebp)
f0101265:	e8 77 fe ff ff       	call   f01010e1 <pgdir_walk>
f010126a:	89 c1                	mov    %eax,%ecx
	if (pgTbEty && (*pgTbEty & PTE_P)) {
f010126c:	83 c4 10             	add    $0x10,%esp
f010126f:	85 c0                	test   %eax,%eax
f0101271:	74 1a                	je     f010128d <page_lookup+0x3a>
f0101273:	8b 10                	mov    (%eax),%edx
f0101275:	f6 c2 01             	test   $0x1,%dl
f0101278:	74 1a                	je     f0101294 <page_lookup+0x41>
		ret = pages + (PTE_ADDR(*pgTbEty) >> PTXSHIFT);
f010127a:	c1 ea 0c             	shr    $0xc,%edx
f010127d:	a1 e0 9e 2a f0       	mov    0xf02a9ee0,%eax
f0101282:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		if (pte_store) {
f0101285:	85 db                	test   %ebx,%ebx
f0101287:	74 10                	je     f0101299 <page_lookup+0x46>
			*pte_store = pgTbEty;
f0101289:	89 0b                	mov    %ecx,(%ebx)
f010128b:	eb 0c                	jmp    f0101299 <page_lookup+0x46>

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
f010128d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101292:	eb 05                	jmp    f0101299 <page_lookup+0x46>
f0101294:	b8 00 00 00 00       	mov    $0x0,%eax
		if (pte_store) {
			*pte_store = pgTbEty;
		}
	}
	return ret;
}
f0101299:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010129c:	c9                   	leave  
f010129d:	c3                   	ret    

f010129e <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010129e:	55                   	push   %ebp
f010129f:	89 e5                	mov    %esp,%ebp
f01012a1:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f01012a4:	e8 ce 47 00 00       	call   f0105a77 <cpunum>
f01012a9:	6b c0 74             	imul   $0x74,%eax,%eax
f01012ac:	83 b8 48 a0 2a f0 00 	cmpl   $0x0,-0xfd55fb8(%eax)
f01012b3:	74 16                	je     f01012cb <tlb_invalidate+0x2d>
f01012b5:	e8 bd 47 00 00       	call   f0105a77 <cpunum>
f01012ba:	6b c0 74             	imul   $0x74,%eax,%eax
f01012bd:	8b 80 48 a0 2a f0    	mov    -0xfd55fb8(%eax),%eax
f01012c3:	8b 55 08             	mov    0x8(%ebp),%edx
f01012c6:	39 50 60             	cmp    %edx,0x60(%eax)
f01012c9:	75 06                	jne    f01012d1 <tlb_invalidate+0x33>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01012cb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012ce:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f01012d1:	c9                   	leave  
f01012d2:	c3                   	ret    

f01012d3 <page_remove>:
// 	tlb_invalidate, and page_decref.
//

void
page_remove(pde_t *pgdir, void *va)
{
f01012d3:	55                   	push   %ebp
f01012d4:	89 e5                	mov    %esp,%ebp
f01012d6:	56                   	push   %esi
f01012d7:	53                   	push   %ebx
f01012d8:	83 ec 14             	sub    $0x14,%esp
f01012db:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01012de:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t *pte;
	struct PageInfo *remPage = 0;
	if (!(remPage = page_lookup(pgdir, va, &pte))) {
f01012e1:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01012e4:	50                   	push   %eax
f01012e5:	56                   	push   %esi
f01012e6:	53                   	push   %ebx
f01012e7:	e8 67 ff ff ff       	call   f0101253 <page_lookup>
f01012ec:	83 c4 10             	add    $0x10,%esp
f01012ef:	85 c0                	test   %eax,%eax
f01012f1:	74 1f                	je     f0101312 <page_remove+0x3f>
		return;
	}
	page_decref(remPage);
f01012f3:	83 ec 0c             	sub    $0xc,%esp
f01012f6:	50                   	push   %eax
f01012f7:	e8 be fd ff ff       	call   f01010ba <page_decref>
	*pte = 0;
f01012fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012ff:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir, va);
f0101305:	83 c4 08             	add    $0x8,%esp
f0101308:	56                   	push   %esi
f0101309:	53                   	push   %ebx
f010130a:	e8 8f ff ff ff       	call   f010129e <tlb_invalidate>
f010130f:	83 c4 10             	add    $0x10,%esp
}
f0101312:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101315:	5b                   	pop    %ebx
f0101316:	5e                   	pop    %esi
f0101317:	5d                   	pop    %ebp
f0101318:	c3                   	ret    

f0101319 <page_insert>:
// and page2pa.
//

int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101319:	55                   	push   %ebp
f010131a:	89 e5                	mov    %esp,%ebp
f010131c:	57                   	push   %edi
f010131d:	56                   	push   %esi
f010131e:	53                   	push   %ebx
f010131f:	83 ec 10             	sub    $0x10,%esp
f0101322:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101325:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
f0101328:	6a 01                	push   $0x1
f010132a:	57                   	push   %edi
f010132b:	ff 75 08             	pushl  0x8(%ebp)
f010132e:	e8 ae fd ff ff       	call   f01010e1 <pgdir_walk>
f0101333:	89 c3                	mov    %eax,%ebx
	
	if (!pte){
f0101335:	83 c4 10             	add    $0x10,%esp
f0101338:	85 c0                	test   %eax,%eax
f010133a:	0f 84 85 00 00 00    	je     f01013c5 <page_insert+0xac>
		return -E_NO_MEM; //Page table could not be allocated	
	}

	if (*pte & PTE_P){    //if page is already present
f0101340:	8b 00                	mov    (%eax),%eax
f0101342:	a8 01                	test   $0x1,%al
f0101344:	74 5b                	je     f01013a1 <page_insert+0x88>
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
f0101346:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010134b:	89 f2                	mov    %esi,%edx
f010134d:	2b 15 e0 9e 2a f0    	sub    0xf02a9ee0,%edx
f0101353:	c1 fa 03             	sar    $0x3,%edx
f0101356:	c1 e2 0c             	shl    $0xc,%edx
f0101359:	39 d0                	cmp    %edx,%eax
f010135b:	75 11                	jne    f010136e <page_insert+0x55>
f010135d:	8b 55 14             	mov    0x14(%ebp),%edx
f0101360:	83 ca 01             	or     $0x1,%edx
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
f0101363:	09 d0                	or     %edx,%eax
f0101365:	89 03                	mov    %eax,(%ebx)
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
			pp->pp_ref ++;  //incremnt the page reference
		}
		return 0;
f0101367:	b8 00 00 00 00       	mov    $0x0,%eax
f010136c:	eb 5c                	jmp    f01013ca <page_insert+0xb1>
	if (*pte & PTE_P){    //if page is already present
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
		}
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
f010136e:	83 ec 08             	sub    $0x8,%esp
f0101371:	57                   	push   %edi
f0101372:	ff 75 08             	pushl  0x8(%ebp)
f0101375:	e8 59 ff ff ff       	call   f01012d3 <page_remove>
f010137a:	8b 55 14             	mov    0x14(%ebp),%edx
f010137d:	83 ca 01             	or     $0x1,%edx
f0101380:	89 f0                	mov    %esi,%eax
f0101382:	2b 05 e0 9e 2a f0    	sub    0xf02a9ee0,%eax
f0101388:	c1 f8 03             	sar    $0x3,%eax
f010138b:	c1 e0 0c             	shl    $0xc,%eax
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
f010138e:	09 d0                	or     %edx,%eax
f0101390:	89 03                	mov    %eax,(%ebx)
			pp->pp_ref ++;  //incremnt the page reference
f0101392:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
f0101397:	83 c4 10             	add    $0x10,%esp
		}
		return 0;
f010139a:	b8 00 00 00 00       	mov    $0x0,%eax
f010139f:	eb 29                	jmp    f01013ca <page_insert+0xb1>
f01013a1:	8b 55 14             	mov    0x14(%ebp),%edx
f01013a4:	83 ca 01             	or     $0x1,%edx
f01013a7:	89 f0                	mov    %esi,%eax
f01013a9:	2b 05 e0 9e 2a f0    	sub    0xf02a9ee0,%eax
f01013af:	c1 f8 03             	sar    $0x3,%eax
f01013b2:	c1 e0 0c             	shl    $0xc,%eax
	}	
	else{   // if page is not present
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
f01013b5:	09 d0                	or     %edx,%eax
f01013b7:	89 03                	mov    %eax,(%ebx)
		pp->pp_ref ++; // increment the page reference count	     
f01013b9:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	}
	return 0;
f01013be:	b8 00 00 00 00       	mov    $0x0,%eax
f01013c3:	eb 05                	jmp    f01013ca <page_insert+0xb1>
{
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
	
	if (!pte){
		return -E_NO_MEM; //Page table could not be allocated	
f01013c5:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
		pp->pp_ref ++; // increment the page reference count	     
	}
	return 0;

}
f01013ca:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01013cd:	5b                   	pop    %ebx
f01013ce:	5e                   	pop    %esi
f01013cf:	5f                   	pop    %edi
f01013d0:	5d                   	pop    %ebp
f01013d1:	c3                   	ret    

f01013d2 <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f01013d2:	55                   	push   %ebp
f01013d3:	89 e5                	mov    %esp,%ebp
f01013d5:	56                   	push   %esi
f01013d6:	53                   	push   %ebx
	//
	// Your code here:
	//panic("mmio_map_region not implemented");
	
	//Since we modify the value of the pointer, copy the value of the pointer into some variable
	void* save = (void*) base;  // USe a pointer to void, just to store the first address
f01013d7:	8b 35 00 43 12 f0    	mov    0xf0124300,%esi
	
	//Roundup size to pgsize
	size = ROUNDUP(size,PGSIZE);
f01013dd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013e0:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f01013e6:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	
	//Use bootmap region to map the given region
	boot_map_region(kern_pgdir, base, size, pa, PTE_W | PTE_P |PTE_PCD|PTE_PWT);
f01013ec:	83 ec 08             	sub    $0x8,%esp
f01013ef:	6a 1b                	push   $0x1b
f01013f1:	ff 75 08             	pushl  0x8(%ebp)
f01013f4:	89 d9                	mov    %ebx,%ecx
f01013f6:	89 f2                	mov    %esi,%edx
f01013f8:	a1 dc 9e 2a f0       	mov    0xf02a9edc,%eax
f01013fd:	e8 ca fd ff ff       	call   f01011cc <boot_map_region>
	
	//reserving size bytes of memory
	base += size;
f0101402:	01 1d 00 43 12 f0    	add    %ebx,0xf0124300
	
	return save; 
	
}
f0101408:	89 f0                	mov    %esi,%eax
f010140a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010140d:	5b                   	pop    %ebx
f010140e:	5e                   	pop    %esi
f010140f:	5d                   	pop    %ebp
f0101410:	c3                   	ret    

f0101411 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101411:	55                   	push   %ebp
f0101412:	89 e5                	mov    %esp,%ebp
f0101414:	57                   	push   %edi
f0101415:	56                   	push   %esi
f0101416:	53                   	push   %ebx
f0101417:	83 ec 48             	sub    $0x48,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010141a:	6a 15                	push   $0x15
f010141c:	e8 c4 22 00 00       	call   f01036e5 <mc146818_read>
f0101421:	89 c3                	mov    %eax,%ebx
f0101423:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f010142a:	e8 b6 22 00 00       	call   f01036e5 <mc146818_read>
f010142f:	c1 e0 08             	shl    $0x8,%eax
f0101432:	09 d8                	or     %ebx,%eax
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101434:	c1 e0 0a             	shl    $0xa,%eax
f0101437:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010143d:	85 c0                	test   %eax,%eax
f010143f:	0f 48 c2             	cmovs  %edx,%eax
f0101442:	c1 f8 0c             	sar    $0xc,%eax
f0101445:	a3 68 92 2a f0       	mov    %eax,0xf02a9268
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010144a:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101451:	e8 8f 22 00 00       	call   f01036e5 <mc146818_read>
f0101456:	89 c3                	mov    %eax,%ebx
f0101458:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f010145f:	e8 81 22 00 00       	call   f01036e5 <mc146818_read>
f0101464:	c1 e0 08             	shl    $0x8,%eax
f0101467:	09 d8                	or     %ebx,%eax
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101469:	c1 e0 0a             	shl    $0xa,%eax
f010146c:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101472:	83 c4 10             	add    $0x10,%esp
f0101475:	85 c0                	test   %eax,%eax
f0101477:	0f 48 c2             	cmovs  %edx,%eax
f010147a:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f010147d:	85 c0                	test   %eax,%eax
f010147f:	74 0e                	je     f010148f <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101481:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101487:	89 15 d8 9e 2a f0    	mov    %edx,0xf02a9ed8
f010148d:	eb 0c                	jmp    f010149b <mem_init+0x8a>
	else
		npages = npages_basemem;
f010148f:	8b 15 68 92 2a f0    	mov    0xf02a9268,%edx
f0101495:	89 15 d8 9e 2a f0    	mov    %edx,0xf02a9ed8

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f010149b:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010149e:	c1 e8 0a             	shr    $0xa,%eax
f01014a1:	50                   	push   %eax
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f01014a2:	a1 68 92 2a f0       	mov    0xf02a9268,%eax
f01014a7:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01014aa:	c1 e8 0a             	shr    $0xa,%eax
f01014ad:	50                   	push   %eax
		npages * PGSIZE / 1024,
f01014ae:	a1 d8 9e 2a f0       	mov    0xf02a9ed8,%eax
f01014b3:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01014b6:	c1 e8 0a             	shr    $0xa,%eax
f01014b9:	50                   	push   %eax
f01014ba:	68 9c 72 10 f0       	push   $0xf010729c
f01014bf:	e8 95 23 00 00       	call   f0103859 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01014c4:	b8 00 10 00 00       	mov    $0x1000,%eax
f01014c9:	e8 0e f6 ff ff       	call   f0100adc <boot_alloc>
f01014ce:	a3 dc 9e 2a f0       	mov    %eax,0xf02a9edc
	memset(kern_pgdir, 0, PGSIZE);
f01014d3:	83 c4 0c             	add    $0xc,%esp
f01014d6:	68 00 10 00 00       	push   $0x1000
f01014db:	6a 00                	push   $0x0
f01014dd:	50                   	push   %eax
f01014de:	e8 6f 3f 00 00       	call   f0105452 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01014e3:	a1 dc 9e 2a f0       	mov    0xf02a9edc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01014e8:	83 c4 10             	add    $0x10,%esp
f01014eb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01014f0:	77 15                	ja     f0101507 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01014f2:	50                   	push   %eax
f01014f3:	68 48 6b 10 f0       	push   $0xf0106b48
f01014f8:	68 98 00 00 00       	push   $0x98
f01014fd:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101502:	e8 39 eb ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101507:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010150d:	83 ca 05             	or     $0x5,%edx
f0101510:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.

	//This line creates a boot allocation of memory of the size of number of pages
	// mulitplied by size of struct Pageinfo to store metadata of the page. 
	pages = boot_alloc(sizeof(struct PageInfo) * npages);   
f0101516:	a1 d8 9e 2a f0       	mov    0xf02a9ed8,%eax
f010151b:	c1 e0 03             	shl    $0x3,%eax
f010151e:	e8 b9 f5 ff ff       	call   f0100adc <boot_alloc>
f0101523:	a3 e0 9e 2a f0       	mov    %eax,0xf02a9ee0
	memset(pages, 0, sizeof(struct PageInfo) * npages); //Clear the memory 
f0101528:	83 ec 04             	sub    $0x4,%esp
f010152b:	8b 0d d8 9e 2a f0    	mov    0xf02a9ed8,%ecx
f0101531:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101538:	52                   	push   %edx
f0101539:	6a 00                	push   $0x0
f010153b:	50                   	push   %eax
f010153c:	e8 11 3f 00 00       	call   f0105452 <memset>
	// The kernel uses this array to keep track of environment array:
	// 'NENV' is the number of Environments in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = boot_alloc(sizeof(struct Env)*NENV);
f0101541:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101546:	e8 91 f5 ff ff       	call   f0100adc <boot_alloc>
f010154b:	a3 6c 92 2a f0       	mov    %eax,0xf02a926c
	memset(envs,0,sizeof(struct Env)*NENV);
f0101550:	83 c4 0c             	add    $0xc,%esp
f0101553:	68 00 f0 01 00       	push   $0x1f000
f0101558:	6a 00                	push   $0x0
f010155a:	50                   	push   %eax
f010155b:	e8 f2 3e 00 00       	call   f0105452 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101560:	e8 03 f9 ff ff       	call   f0100e68 <page_init>

	check_page_free_list(1);
f0101565:	b8 01 00 00 00       	mov    $0x1,%eax
f010156a:	e8 e3 f5 ff ff       	call   f0100b52 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010156f:	83 c4 10             	add    $0x10,%esp
f0101572:	83 3d e0 9e 2a f0 00 	cmpl   $0x0,0xf02a9ee0
f0101579:	75 17                	jne    f0101592 <mem_init+0x181>
		panic("'pages' is a null pointer!");
f010157b:	83 ec 04             	sub    $0x4,%esp
f010157e:	68 b5 7b 10 f0       	push   $0xf0107bb5
f0101583:	68 84 03 00 00       	push   $0x384
f0101588:	68 b5 7a 10 f0       	push   $0xf0107ab5
f010158d:	e8 ae ea ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101592:	a1 64 92 2a f0       	mov    0xf02a9264,%eax
f0101597:	bb 00 00 00 00       	mov    $0x0,%ebx
f010159c:	eb 05                	jmp    f01015a3 <mem_init+0x192>
		++nfree;
f010159e:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01015a1:	8b 00                	mov    (%eax),%eax
f01015a3:	85 c0                	test   %eax,%eax
f01015a5:	75 f7                	jne    f010159e <mem_init+0x18d>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015a7:	83 ec 0c             	sub    $0xc,%esp
f01015aa:	6a 00                	push   $0x0
f01015ac:	e8 42 fa ff ff       	call   f0100ff3 <page_alloc>
f01015b1:	89 c7                	mov    %eax,%edi
f01015b3:	83 c4 10             	add    $0x10,%esp
f01015b6:	85 c0                	test   %eax,%eax
f01015b8:	75 19                	jne    f01015d3 <mem_init+0x1c2>
f01015ba:	68 d0 7b 10 f0       	push   $0xf0107bd0
f01015bf:	68 db 7a 10 f0       	push   $0xf0107adb
f01015c4:	68 8c 03 00 00       	push   $0x38c
f01015c9:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01015ce:	e8 6d ea ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01015d3:	83 ec 0c             	sub    $0xc,%esp
f01015d6:	6a 00                	push   $0x0
f01015d8:	e8 16 fa ff ff       	call   f0100ff3 <page_alloc>
f01015dd:	89 c6                	mov    %eax,%esi
f01015df:	83 c4 10             	add    $0x10,%esp
f01015e2:	85 c0                	test   %eax,%eax
f01015e4:	75 19                	jne    f01015ff <mem_init+0x1ee>
f01015e6:	68 e6 7b 10 f0       	push   $0xf0107be6
f01015eb:	68 db 7a 10 f0       	push   $0xf0107adb
f01015f0:	68 8d 03 00 00       	push   $0x38d
f01015f5:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01015fa:	e8 41 ea ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01015ff:	83 ec 0c             	sub    $0xc,%esp
f0101602:	6a 00                	push   $0x0
f0101604:	e8 ea f9 ff ff       	call   f0100ff3 <page_alloc>
f0101609:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010160c:	83 c4 10             	add    $0x10,%esp
f010160f:	85 c0                	test   %eax,%eax
f0101611:	75 19                	jne    f010162c <mem_init+0x21b>
f0101613:	68 fc 7b 10 f0       	push   $0xf0107bfc
f0101618:	68 db 7a 10 f0       	push   $0xf0107adb
f010161d:	68 8e 03 00 00       	push   $0x38e
f0101622:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101627:	e8 14 ea ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010162c:	39 f7                	cmp    %esi,%edi
f010162e:	75 19                	jne    f0101649 <mem_init+0x238>
f0101630:	68 12 7c 10 f0       	push   $0xf0107c12
f0101635:	68 db 7a 10 f0       	push   $0xf0107adb
f010163a:	68 91 03 00 00       	push   $0x391
f010163f:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101644:	e8 f7 e9 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101649:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010164c:	39 c7                	cmp    %eax,%edi
f010164e:	74 04                	je     f0101654 <mem_init+0x243>
f0101650:	39 c6                	cmp    %eax,%esi
f0101652:	75 19                	jne    f010166d <mem_init+0x25c>
f0101654:	68 d8 72 10 f0       	push   $0xf01072d8
f0101659:	68 db 7a 10 f0       	push   $0xf0107adb
f010165e:	68 92 03 00 00       	push   $0x392
f0101663:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101668:	e8 d3 e9 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010166d:	8b 0d e0 9e 2a f0    	mov    0xf02a9ee0,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101673:	8b 15 d8 9e 2a f0    	mov    0xf02a9ed8,%edx
f0101679:	c1 e2 0c             	shl    $0xc,%edx
f010167c:	89 f8                	mov    %edi,%eax
f010167e:	29 c8                	sub    %ecx,%eax
f0101680:	c1 f8 03             	sar    $0x3,%eax
f0101683:	c1 e0 0c             	shl    $0xc,%eax
f0101686:	39 d0                	cmp    %edx,%eax
f0101688:	72 19                	jb     f01016a3 <mem_init+0x292>
f010168a:	68 24 7c 10 f0       	push   $0xf0107c24
f010168f:	68 db 7a 10 f0       	push   $0xf0107adb
f0101694:	68 93 03 00 00       	push   $0x393
f0101699:	68 b5 7a 10 f0       	push   $0xf0107ab5
f010169e:	e8 9d e9 ff ff       	call   f0100040 <_panic>
f01016a3:	89 f0                	mov    %esi,%eax
f01016a5:	29 c8                	sub    %ecx,%eax
f01016a7:	c1 f8 03             	sar    $0x3,%eax
f01016aa:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f01016ad:	39 c2                	cmp    %eax,%edx
f01016af:	77 19                	ja     f01016ca <mem_init+0x2b9>
f01016b1:	68 41 7c 10 f0       	push   $0xf0107c41
f01016b6:	68 db 7a 10 f0       	push   $0xf0107adb
f01016bb:	68 94 03 00 00       	push   $0x394
f01016c0:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01016c5:	e8 76 e9 ff ff       	call   f0100040 <_panic>
f01016ca:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016cd:	29 c8                	sub    %ecx,%eax
f01016cf:	c1 f8 03             	sar    $0x3,%eax
f01016d2:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f01016d5:	39 c2                	cmp    %eax,%edx
f01016d7:	77 19                	ja     f01016f2 <mem_init+0x2e1>
f01016d9:	68 5e 7c 10 f0       	push   $0xf0107c5e
f01016de:	68 db 7a 10 f0       	push   $0xf0107adb
f01016e3:	68 95 03 00 00       	push   $0x395
f01016e8:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01016ed:	e8 4e e9 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01016f2:	a1 64 92 2a f0       	mov    0xf02a9264,%eax
f01016f7:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01016fa:	c7 05 64 92 2a f0 00 	movl   $0x0,0xf02a9264
f0101701:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101704:	83 ec 0c             	sub    $0xc,%esp
f0101707:	6a 00                	push   $0x0
f0101709:	e8 e5 f8 ff ff       	call   f0100ff3 <page_alloc>
f010170e:	83 c4 10             	add    $0x10,%esp
f0101711:	85 c0                	test   %eax,%eax
f0101713:	74 19                	je     f010172e <mem_init+0x31d>
f0101715:	68 7b 7c 10 f0       	push   $0xf0107c7b
f010171a:	68 db 7a 10 f0       	push   $0xf0107adb
f010171f:	68 9c 03 00 00       	push   $0x39c
f0101724:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101729:	e8 12 e9 ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f010172e:	83 ec 0c             	sub    $0xc,%esp
f0101731:	57                   	push   %edi
f0101732:	e8 32 f9 ff ff       	call   f0101069 <page_free>
	page_free(pp1);
f0101737:	89 34 24             	mov    %esi,(%esp)
f010173a:	e8 2a f9 ff ff       	call   f0101069 <page_free>
	page_free(pp2);
f010173f:	83 c4 04             	add    $0x4,%esp
f0101742:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101745:	e8 1f f9 ff ff       	call   f0101069 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010174a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101751:	e8 9d f8 ff ff       	call   f0100ff3 <page_alloc>
f0101756:	89 c6                	mov    %eax,%esi
f0101758:	83 c4 10             	add    $0x10,%esp
f010175b:	85 c0                	test   %eax,%eax
f010175d:	75 19                	jne    f0101778 <mem_init+0x367>
f010175f:	68 d0 7b 10 f0       	push   $0xf0107bd0
f0101764:	68 db 7a 10 f0       	push   $0xf0107adb
f0101769:	68 a3 03 00 00       	push   $0x3a3
f010176e:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101773:	e8 c8 e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101778:	83 ec 0c             	sub    $0xc,%esp
f010177b:	6a 00                	push   $0x0
f010177d:	e8 71 f8 ff ff       	call   f0100ff3 <page_alloc>
f0101782:	89 c7                	mov    %eax,%edi
f0101784:	83 c4 10             	add    $0x10,%esp
f0101787:	85 c0                	test   %eax,%eax
f0101789:	75 19                	jne    f01017a4 <mem_init+0x393>
f010178b:	68 e6 7b 10 f0       	push   $0xf0107be6
f0101790:	68 db 7a 10 f0       	push   $0xf0107adb
f0101795:	68 a4 03 00 00       	push   $0x3a4
f010179a:	68 b5 7a 10 f0       	push   $0xf0107ab5
f010179f:	e8 9c e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01017a4:	83 ec 0c             	sub    $0xc,%esp
f01017a7:	6a 00                	push   $0x0
f01017a9:	e8 45 f8 ff ff       	call   f0100ff3 <page_alloc>
f01017ae:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01017b1:	83 c4 10             	add    $0x10,%esp
f01017b4:	85 c0                	test   %eax,%eax
f01017b6:	75 19                	jne    f01017d1 <mem_init+0x3c0>
f01017b8:	68 fc 7b 10 f0       	push   $0xf0107bfc
f01017bd:	68 db 7a 10 f0       	push   $0xf0107adb
f01017c2:	68 a5 03 00 00       	push   $0x3a5
f01017c7:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01017cc:	e8 6f e8 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01017d1:	39 fe                	cmp    %edi,%esi
f01017d3:	75 19                	jne    f01017ee <mem_init+0x3dd>
f01017d5:	68 12 7c 10 f0       	push   $0xf0107c12
f01017da:	68 db 7a 10 f0       	push   $0xf0107adb
f01017df:	68 a7 03 00 00       	push   $0x3a7
f01017e4:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01017e9:	e8 52 e8 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017ee:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017f1:	39 c6                	cmp    %eax,%esi
f01017f3:	74 04                	je     f01017f9 <mem_init+0x3e8>
f01017f5:	39 c7                	cmp    %eax,%edi
f01017f7:	75 19                	jne    f0101812 <mem_init+0x401>
f01017f9:	68 d8 72 10 f0       	push   $0xf01072d8
f01017fe:	68 db 7a 10 f0       	push   $0xf0107adb
f0101803:	68 a8 03 00 00       	push   $0x3a8
f0101808:	68 b5 7a 10 f0       	push   $0xf0107ab5
f010180d:	e8 2e e8 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101812:	83 ec 0c             	sub    $0xc,%esp
f0101815:	6a 00                	push   $0x0
f0101817:	e8 d7 f7 ff ff       	call   f0100ff3 <page_alloc>
f010181c:	83 c4 10             	add    $0x10,%esp
f010181f:	85 c0                	test   %eax,%eax
f0101821:	74 19                	je     f010183c <mem_init+0x42b>
f0101823:	68 7b 7c 10 f0       	push   $0xf0107c7b
f0101828:	68 db 7a 10 f0       	push   $0xf0107adb
f010182d:	68 a9 03 00 00       	push   $0x3a9
f0101832:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101837:	e8 04 e8 ff ff       	call   f0100040 <_panic>
f010183c:	89 f0                	mov    %esi,%eax
f010183e:	2b 05 e0 9e 2a f0    	sub    0xf02a9ee0,%eax
f0101844:	c1 f8 03             	sar    $0x3,%eax
f0101847:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010184a:	89 c2                	mov    %eax,%edx
f010184c:	c1 ea 0c             	shr    $0xc,%edx
f010184f:	3b 15 d8 9e 2a f0    	cmp    0xf02a9ed8,%edx
f0101855:	72 12                	jb     f0101869 <mem_init+0x458>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101857:	50                   	push   %eax
f0101858:	68 24 6b 10 f0       	push   $0xf0106b24
f010185d:	6a 58                	push   $0x58
f010185f:	68 c1 7a 10 f0       	push   $0xf0107ac1
f0101864:	e8 d7 e7 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101869:	83 ec 04             	sub    $0x4,%esp
f010186c:	68 00 10 00 00       	push   $0x1000
f0101871:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0101873:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101878:	50                   	push   %eax
f0101879:	e8 d4 3b 00 00       	call   f0105452 <memset>
	page_free(pp0);
f010187e:	89 34 24             	mov    %esi,(%esp)
f0101881:	e8 e3 f7 ff ff       	call   f0101069 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101886:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010188d:	e8 61 f7 ff ff       	call   f0100ff3 <page_alloc>
f0101892:	83 c4 10             	add    $0x10,%esp
f0101895:	85 c0                	test   %eax,%eax
f0101897:	75 19                	jne    f01018b2 <mem_init+0x4a1>
f0101899:	68 8a 7c 10 f0       	push   $0xf0107c8a
f010189e:	68 db 7a 10 f0       	push   $0xf0107adb
f01018a3:	68 ae 03 00 00       	push   $0x3ae
f01018a8:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01018ad:	e8 8e e7 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f01018b2:	39 c6                	cmp    %eax,%esi
f01018b4:	74 19                	je     f01018cf <mem_init+0x4be>
f01018b6:	68 a8 7c 10 f0       	push   $0xf0107ca8
f01018bb:	68 db 7a 10 f0       	push   $0xf0107adb
f01018c0:	68 af 03 00 00       	push   $0x3af
f01018c5:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01018ca:	e8 71 e7 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01018cf:	89 f0                	mov    %esi,%eax
f01018d1:	2b 05 e0 9e 2a f0    	sub    0xf02a9ee0,%eax
f01018d7:	c1 f8 03             	sar    $0x3,%eax
f01018da:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01018dd:	89 c2                	mov    %eax,%edx
f01018df:	c1 ea 0c             	shr    $0xc,%edx
f01018e2:	3b 15 d8 9e 2a f0    	cmp    0xf02a9ed8,%edx
f01018e8:	72 12                	jb     f01018fc <mem_init+0x4eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01018ea:	50                   	push   %eax
f01018eb:	68 24 6b 10 f0       	push   $0xf0106b24
f01018f0:	6a 58                	push   $0x58
f01018f2:	68 c1 7a 10 f0       	push   $0xf0107ac1
f01018f7:	e8 44 e7 ff ff       	call   f0100040 <_panic>
f01018fc:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101902:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101908:	80 38 00             	cmpb   $0x0,(%eax)
f010190b:	74 19                	je     f0101926 <mem_init+0x515>
f010190d:	68 b8 7c 10 f0       	push   $0xf0107cb8
f0101912:	68 db 7a 10 f0       	push   $0xf0107adb
f0101917:	68 b2 03 00 00       	push   $0x3b2
f010191c:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101921:	e8 1a e7 ff ff       	call   f0100040 <_panic>
f0101926:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101929:	39 d0                	cmp    %edx,%eax
f010192b:	75 db                	jne    f0101908 <mem_init+0x4f7>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010192d:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101930:	a3 64 92 2a f0       	mov    %eax,0xf02a9264

	// free the pages we took
	page_free(pp0);
f0101935:	83 ec 0c             	sub    $0xc,%esp
f0101938:	56                   	push   %esi
f0101939:	e8 2b f7 ff ff       	call   f0101069 <page_free>
	page_free(pp1);
f010193e:	89 3c 24             	mov    %edi,(%esp)
f0101941:	e8 23 f7 ff ff       	call   f0101069 <page_free>
	page_free(pp2);
f0101946:	83 c4 04             	add    $0x4,%esp
f0101949:	ff 75 d4             	pushl  -0x2c(%ebp)
f010194c:	e8 18 f7 ff ff       	call   f0101069 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101951:	a1 64 92 2a f0       	mov    0xf02a9264,%eax
f0101956:	83 c4 10             	add    $0x10,%esp
f0101959:	eb 05                	jmp    f0101960 <mem_init+0x54f>
		--nfree;
f010195b:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010195e:	8b 00                	mov    (%eax),%eax
f0101960:	85 c0                	test   %eax,%eax
f0101962:	75 f7                	jne    f010195b <mem_init+0x54a>
		--nfree;
	assert(nfree == 0);
f0101964:	85 db                	test   %ebx,%ebx
f0101966:	74 19                	je     f0101981 <mem_init+0x570>
f0101968:	68 c2 7c 10 f0       	push   $0xf0107cc2
f010196d:	68 db 7a 10 f0       	push   $0xf0107adb
f0101972:	68 bf 03 00 00       	push   $0x3bf
f0101977:	68 b5 7a 10 f0       	push   $0xf0107ab5
f010197c:	e8 bf e6 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101981:	83 ec 0c             	sub    $0xc,%esp
f0101984:	68 f8 72 10 f0       	push   $0xf01072f8
f0101989:	e8 cb 1e 00 00       	call   f0103859 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010198e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101995:	e8 59 f6 ff ff       	call   f0100ff3 <page_alloc>
f010199a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010199d:	83 c4 10             	add    $0x10,%esp
f01019a0:	85 c0                	test   %eax,%eax
f01019a2:	75 19                	jne    f01019bd <mem_init+0x5ac>
f01019a4:	68 d0 7b 10 f0       	push   $0xf0107bd0
f01019a9:	68 db 7a 10 f0       	push   $0xf0107adb
f01019ae:	68 25 04 00 00       	push   $0x425
f01019b3:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01019b8:	e8 83 e6 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01019bd:	83 ec 0c             	sub    $0xc,%esp
f01019c0:	6a 00                	push   $0x0
f01019c2:	e8 2c f6 ff ff       	call   f0100ff3 <page_alloc>
f01019c7:	89 c3                	mov    %eax,%ebx
f01019c9:	83 c4 10             	add    $0x10,%esp
f01019cc:	85 c0                	test   %eax,%eax
f01019ce:	75 19                	jne    f01019e9 <mem_init+0x5d8>
f01019d0:	68 e6 7b 10 f0       	push   $0xf0107be6
f01019d5:	68 db 7a 10 f0       	push   $0xf0107adb
f01019da:	68 26 04 00 00       	push   $0x426
f01019df:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01019e4:	e8 57 e6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01019e9:	83 ec 0c             	sub    $0xc,%esp
f01019ec:	6a 00                	push   $0x0
f01019ee:	e8 00 f6 ff ff       	call   f0100ff3 <page_alloc>
f01019f3:	89 c6                	mov    %eax,%esi
f01019f5:	83 c4 10             	add    $0x10,%esp
f01019f8:	85 c0                	test   %eax,%eax
f01019fa:	75 19                	jne    f0101a15 <mem_init+0x604>
f01019fc:	68 fc 7b 10 f0       	push   $0xf0107bfc
f0101a01:	68 db 7a 10 f0       	push   $0xf0107adb
f0101a06:	68 27 04 00 00       	push   $0x427
f0101a0b:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101a10:	e8 2b e6 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a15:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101a18:	75 19                	jne    f0101a33 <mem_init+0x622>
f0101a1a:	68 12 7c 10 f0       	push   $0xf0107c12
f0101a1f:	68 db 7a 10 f0       	push   $0xf0107adb
f0101a24:	68 2a 04 00 00       	push   $0x42a
f0101a29:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101a2e:	e8 0d e6 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a33:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101a36:	74 04                	je     f0101a3c <mem_init+0x62b>
f0101a38:	39 c3                	cmp    %eax,%ebx
f0101a3a:	75 19                	jne    f0101a55 <mem_init+0x644>
f0101a3c:	68 d8 72 10 f0       	push   $0xf01072d8
f0101a41:	68 db 7a 10 f0       	push   $0xf0107adb
f0101a46:	68 2b 04 00 00       	push   $0x42b
f0101a4b:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101a50:	e8 eb e5 ff ff       	call   f0100040 <_panic>
	

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101a55:	a1 64 92 2a f0       	mov    0xf02a9264,%eax
f0101a5a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101a5d:	c7 05 64 92 2a f0 00 	movl   $0x0,0xf02a9264
f0101a64:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101a67:	83 ec 0c             	sub    $0xc,%esp
f0101a6a:	6a 00                	push   $0x0
f0101a6c:	e8 82 f5 ff ff       	call   f0100ff3 <page_alloc>
f0101a71:	83 c4 10             	add    $0x10,%esp
f0101a74:	85 c0                	test   %eax,%eax
f0101a76:	74 19                	je     f0101a91 <mem_init+0x680>
f0101a78:	68 7b 7c 10 f0       	push   $0xf0107c7b
f0101a7d:	68 db 7a 10 f0       	push   $0xf0107adb
f0101a82:	68 33 04 00 00       	push   $0x433
f0101a87:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101a8c:	e8 af e5 ff ff       	call   f0100040 <_panic>
	
	
	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101a91:	83 ec 04             	sub    $0x4,%esp
f0101a94:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101a97:	50                   	push   %eax
f0101a98:	6a 00                	push   $0x0
f0101a9a:	ff 35 dc 9e 2a f0    	pushl  0xf02a9edc
f0101aa0:	e8 ae f7 ff ff       	call   f0101253 <page_lookup>
f0101aa5:	83 c4 10             	add    $0x10,%esp
f0101aa8:	85 c0                	test   %eax,%eax
f0101aaa:	74 19                	je     f0101ac5 <mem_init+0x6b4>
f0101aac:	68 18 73 10 f0       	push   $0xf0107318
f0101ab1:	68 db 7a 10 f0       	push   $0xf0107adb
f0101ab6:	68 37 04 00 00       	push   $0x437
f0101abb:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101ac0:	e8 7b e5 ff ff       	call   f0100040 <_panic>
	
	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101ac5:	6a 02                	push   $0x2
f0101ac7:	6a 00                	push   $0x0
f0101ac9:	53                   	push   %ebx
f0101aca:	ff 35 dc 9e 2a f0    	pushl  0xf02a9edc
f0101ad0:	e8 44 f8 ff ff       	call   f0101319 <page_insert>
f0101ad5:	83 c4 10             	add    $0x10,%esp
f0101ad8:	85 c0                	test   %eax,%eax
f0101ada:	78 19                	js     f0101af5 <mem_init+0x6e4>
f0101adc:	68 50 73 10 f0       	push   $0xf0107350
f0101ae1:	68 db 7a 10 f0       	push   $0xf0107adb
f0101ae6:	68 3a 04 00 00       	push   $0x43a
f0101aeb:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101af0:	e8 4b e5 ff ff       	call   f0100040 <_panic>
	
	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101af5:	83 ec 0c             	sub    $0xc,%esp
f0101af8:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101afb:	e8 69 f5 ff ff       	call   f0101069 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101b00:	6a 02                	push   $0x2
f0101b02:	6a 00                	push   $0x0
f0101b04:	53                   	push   %ebx
f0101b05:	ff 35 dc 9e 2a f0    	pushl  0xf02a9edc
f0101b0b:	e8 09 f8 ff ff       	call   f0101319 <page_insert>
f0101b10:	83 c4 20             	add    $0x20,%esp
f0101b13:	85 c0                	test   %eax,%eax
f0101b15:	74 19                	je     f0101b30 <mem_init+0x71f>
f0101b17:	68 80 73 10 f0       	push   $0xf0107380
f0101b1c:	68 db 7a 10 f0       	push   $0xf0107adb
f0101b21:	68 3e 04 00 00       	push   $0x43e
f0101b26:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101b2b:	e8 10 e5 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101b30:	8b 3d dc 9e 2a f0    	mov    0xf02a9edc,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101b36:	a1 e0 9e 2a f0       	mov    0xf02a9ee0,%eax
f0101b3b:	89 c1                	mov    %eax,%ecx
f0101b3d:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101b40:	8b 17                	mov    (%edi),%edx
f0101b42:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101b48:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b4b:	29 c8                	sub    %ecx,%eax
f0101b4d:	c1 f8 03             	sar    $0x3,%eax
f0101b50:	c1 e0 0c             	shl    $0xc,%eax
f0101b53:	39 c2                	cmp    %eax,%edx
f0101b55:	74 19                	je     f0101b70 <mem_init+0x75f>
f0101b57:	68 b0 73 10 f0       	push   $0xf01073b0
f0101b5c:	68 db 7a 10 f0       	push   $0xf0107adb
f0101b61:	68 3f 04 00 00       	push   $0x43f
f0101b66:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101b6b:	e8 d0 e4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b70:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b75:	89 f8                	mov    %edi,%eax
f0101b77:	e8 fc ee ff ff       	call   f0100a78 <check_va2pa>
f0101b7c:	89 da                	mov    %ebx,%edx
f0101b7e:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101b81:	c1 fa 03             	sar    $0x3,%edx
f0101b84:	c1 e2 0c             	shl    $0xc,%edx
f0101b87:	39 d0                	cmp    %edx,%eax
f0101b89:	74 19                	je     f0101ba4 <mem_init+0x793>
f0101b8b:	68 d8 73 10 f0       	push   $0xf01073d8
f0101b90:	68 db 7a 10 f0       	push   $0xf0107adb
f0101b95:	68 40 04 00 00       	push   $0x440
f0101b9a:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101b9f:	e8 9c e4 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101ba4:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ba9:	74 19                	je     f0101bc4 <mem_init+0x7b3>
f0101bab:	68 cd 7c 10 f0       	push   $0xf0107ccd
f0101bb0:	68 db 7a 10 f0       	push   $0xf0107adb
f0101bb5:	68 41 04 00 00       	push   $0x441
f0101bba:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101bbf:	e8 7c e4 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101bc4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101bc7:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101bcc:	74 19                	je     f0101be7 <mem_init+0x7d6>
f0101bce:	68 de 7c 10 f0       	push   $0xf0107cde
f0101bd3:	68 db 7a 10 f0       	push   $0xf0107adb
f0101bd8:	68 42 04 00 00       	push   $0x442
f0101bdd:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101be2:	e8 59 e4 ff ff       	call   f0100040 <_panic>
	
	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101be7:	6a 02                	push   $0x2
f0101be9:	68 00 10 00 00       	push   $0x1000
f0101bee:	56                   	push   %esi
f0101bef:	57                   	push   %edi
f0101bf0:	e8 24 f7 ff ff       	call   f0101319 <page_insert>
f0101bf5:	83 c4 10             	add    $0x10,%esp
f0101bf8:	85 c0                	test   %eax,%eax
f0101bfa:	74 19                	je     f0101c15 <mem_init+0x804>
f0101bfc:	68 08 74 10 f0       	push   $0xf0107408
f0101c01:	68 db 7a 10 f0       	push   $0xf0107adb
f0101c06:	68 45 04 00 00       	push   $0x445
f0101c0b:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101c10:	e8 2b e4 ff ff       	call   f0100040 <_panic>

	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c15:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c1a:	a1 dc 9e 2a f0       	mov    0xf02a9edc,%eax
f0101c1f:	e8 54 ee ff ff       	call   f0100a78 <check_va2pa>
f0101c24:	89 f2                	mov    %esi,%edx
f0101c26:	2b 15 e0 9e 2a f0    	sub    0xf02a9ee0,%edx
f0101c2c:	c1 fa 03             	sar    $0x3,%edx
f0101c2f:	c1 e2 0c             	shl    $0xc,%edx
f0101c32:	39 d0                	cmp    %edx,%eax
f0101c34:	74 19                	je     f0101c4f <mem_init+0x83e>
f0101c36:	68 44 74 10 f0       	push   $0xf0107444
f0101c3b:	68 db 7a 10 f0       	push   $0xf0107adb
f0101c40:	68 47 04 00 00       	push   $0x447
f0101c45:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101c4a:	e8 f1 e3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101c4f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c54:	74 19                	je     f0101c6f <mem_init+0x85e>
f0101c56:	68 ef 7c 10 f0       	push   $0xf0107cef
f0101c5b:	68 db 7a 10 f0       	push   $0xf0107adb
f0101c60:	68 48 04 00 00       	push   $0x448
f0101c65:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101c6a:	e8 d1 e3 ff ff       	call   f0100040 <_panic>
	
	// should be no free memory
	assert(!page_alloc(0));
f0101c6f:	83 ec 0c             	sub    $0xc,%esp
f0101c72:	6a 00                	push   $0x0
f0101c74:	e8 7a f3 ff ff       	call   f0100ff3 <page_alloc>
f0101c79:	83 c4 10             	add    $0x10,%esp
f0101c7c:	85 c0                	test   %eax,%eax
f0101c7e:	74 19                	je     f0101c99 <mem_init+0x888>
f0101c80:	68 7b 7c 10 f0       	push   $0xf0107c7b
f0101c85:	68 db 7a 10 f0       	push   $0xf0107adb
f0101c8a:	68 4b 04 00 00       	push   $0x44b
f0101c8f:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101c94:	e8 a7 e3 ff ff       	call   f0100040 <_panic>
	
	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c99:	6a 02                	push   $0x2
f0101c9b:	68 00 10 00 00       	push   $0x1000
f0101ca0:	56                   	push   %esi
f0101ca1:	ff 35 dc 9e 2a f0    	pushl  0xf02a9edc
f0101ca7:	e8 6d f6 ff ff       	call   f0101319 <page_insert>
f0101cac:	83 c4 10             	add    $0x10,%esp
f0101caf:	85 c0                	test   %eax,%eax
f0101cb1:	74 19                	je     f0101ccc <mem_init+0x8bb>
f0101cb3:	68 08 74 10 f0       	push   $0xf0107408
f0101cb8:	68 db 7a 10 f0       	push   $0xf0107adb
f0101cbd:	68 4e 04 00 00       	push   $0x44e
f0101cc2:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101cc7:	e8 74 e3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ccc:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cd1:	a1 dc 9e 2a f0       	mov    0xf02a9edc,%eax
f0101cd6:	e8 9d ed ff ff       	call   f0100a78 <check_va2pa>
f0101cdb:	89 f2                	mov    %esi,%edx
f0101cdd:	2b 15 e0 9e 2a f0    	sub    0xf02a9ee0,%edx
f0101ce3:	c1 fa 03             	sar    $0x3,%edx
f0101ce6:	c1 e2 0c             	shl    $0xc,%edx
f0101ce9:	39 d0                	cmp    %edx,%eax
f0101ceb:	74 19                	je     f0101d06 <mem_init+0x8f5>
f0101ced:	68 44 74 10 f0       	push   $0xf0107444
f0101cf2:	68 db 7a 10 f0       	push   $0xf0107adb
f0101cf7:	68 4f 04 00 00       	push   $0x44f
f0101cfc:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101d01:	e8 3a e3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101d06:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d0b:	74 19                	je     f0101d26 <mem_init+0x915>
f0101d0d:	68 ef 7c 10 f0       	push   $0xf0107cef
f0101d12:	68 db 7a 10 f0       	push   $0xf0107adb
f0101d17:	68 50 04 00 00       	push   $0x450
f0101d1c:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101d21:	e8 1a e3 ff ff       	call   f0100040 <_panic>
	
	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101d26:	83 ec 0c             	sub    $0xc,%esp
f0101d29:	6a 00                	push   $0x0
f0101d2b:	e8 c3 f2 ff ff       	call   f0100ff3 <page_alloc>
f0101d30:	83 c4 10             	add    $0x10,%esp
f0101d33:	85 c0                	test   %eax,%eax
f0101d35:	74 19                	je     f0101d50 <mem_init+0x93f>
f0101d37:	68 7b 7c 10 f0       	push   $0xf0107c7b
f0101d3c:	68 db 7a 10 f0       	push   $0xf0107adb
f0101d41:	68 54 04 00 00       	push   $0x454
f0101d46:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101d4b:	e8 f0 e2 ff ff       	call   f0100040 <_panic>
	
	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101d50:	8b 15 dc 9e 2a f0    	mov    0xf02a9edc,%edx
f0101d56:	8b 02                	mov    (%edx),%eax
f0101d58:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101d5d:	89 c1                	mov    %eax,%ecx
f0101d5f:	c1 e9 0c             	shr    $0xc,%ecx
f0101d62:	3b 0d d8 9e 2a f0    	cmp    0xf02a9ed8,%ecx
f0101d68:	72 15                	jb     f0101d7f <mem_init+0x96e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d6a:	50                   	push   %eax
f0101d6b:	68 24 6b 10 f0       	push   $0xf0106b24
f0101d70:	68 57 04 00 00       	push   $0x457
f0101d75:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101d7a:	e8 c1 e2 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101d7f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d84:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d87:	83 ec 04             	sub    $0x4,%esp
f0101d8a:	6a 00                	push   $0x0
f0101d8c:	68 00 10 00 00       	push   $0x1000
f0101d91:	52                   	push   %edx
f0101d92:	e8 4a f3 ff ff       	call   f01010e1 <pgdir_walk>
f0101d97:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101d9a:	8d 51 04             	lea    0x4(%ecx),%edx
f0101d9d:	83 c4 10             	add    $0x10,%esp
f0101da0:	39 d0                	cmp    %edx,%eax
f0101da2:	74 19                	je     f0101dbd <mem_init+0x9ac>
f0101da4:	68 74 74 10 f0       	push   $0xf0107474
f0101da9:	68 db 7a 10 f0       	push   $0xf0107adb
f0101dae:	68 58 04 00 00       	push   $0x458
f0101db3:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101db8:	e8 83 e2 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101dbd:	6a 06                	push   $0x6
f0101dbf:	68 00 10 00 00       	push   $0x1000
f0101dc4:	56                   	push   %esi
f0101dc5:	ff 35 dc 9e 2a f0    	pushl  0xf02a9edc
f0101dcb:	e8 49 f5 ff ff       	call   f0101319 <page_insert>
f0101dd0:	83 c4 10             	add    $0x10,%esp
f0101dd3:	85 c0                	test   %eax,%eax
f0101dd5:	74 19                	je     f0101df0 <mem_init+0x9df>
f0101dd7:	68 b4 74 10 f0       	push   $0xf01074b4
f0101ddc:	68 db 7a 10 f0       	push   $0xf0107adb
f0101de1:	68 5b 04 00 00       	push   $0x45b
f0101de6:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101deb:	e8 50 e2 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101df0:	8b 3d dc 9e 2a f0    	mov    0xf02a9edc,%edi
f0101df6:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dfb:	89 f8                	mov    %edi,%eax
f0101dfd:	e8 76 ec ff ff       	call   f0100a78 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101e02:	89 f2                	mov    %esi,%edx
f0101e04:	2b 15 e0 9e 2a f0    	sub    0xf02a9ee0,%edx
f0101e0a:	c1 fa 03             	sar    $0x3,%edx
f0101e0d:	c1 e2 0c             	shl    $0xc,%edx
f0101e10:	39 d0                	cmp    %edx,%eax
f0101e12:	74 19                	je     f0101e2d <mem_init+0xa1c>
f0101e14:	68 44 74 10 f0       	push   $0xf0107444
f0101e19:	68 db 7a 10 f0       	push   $0xf0107adb
f0101e1e:	68 5c 04 00 00       	push   $0x45c
f0101e23:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101e28:	e8 13 e2 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101e2d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e32:	74 19                	je     f0101e4d <mem_init+0xa3c>
f0101e34:	68 ef 7c 10 f0       	push   $0xf0107cef
f0101e39:	68 db 7a 10 f0       	push   $0xf0107adb
f0101e3e:	68 5d 04 00 00       	push   $0x45d
f0101e43:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101e48:	e8 f3 e1 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101e4d:	83 ec 04             	sub    $0x4,%esp
f0101e50:	6a 00                	push   $0x0
f0101e52:	68 00 10 00 00       	push   $0x1000
f0101e57:	57                   	push   %edi
f0101e58:	e8 84 f2 ff ff       	call   f01010e1 <pgdir_walk>
f0101e5d:	83 c4 10             	add    $0x10,%esp
f0101e60:	f6 00 04             	testb  $0x4,(%eax)
f0101e63:	75 19                	jne    f0101e7e <mem_init+0xa6d>
f0101e65:	68 f4 74 10 f0       	push   $0xf01074f4
f0101e6a:	68 db 7a 10 f0       	push   $0xf0107adb
f0101e6f:	68 5e 04 00 00       	push   $0x45e
f0101e74:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101e79:	e8 c2 e1 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101e7e:	a1 dc 9e 2a f0       	mov    0xf02a9edc,%eax
f0101e83:	f6 00 04             	testb  $0x4,(%eax)
f0101e86:	75 19                	jne    f0101ea1 <mem_init+0xa90>
f0101e88:	68 00 7d 10 f0       	push   $0xf0107d00
f0101e8d:	68 db 7a 10 f0       	push   $0xf0107adb
f0101e92:	68 5f 04 00 00       	push   $0x45f
f0101e97:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101e9c:	e8 9f e1 ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ea1:	6a 02                	push   $0x2
f0101ea3:	68 00 10 00 00       	push   $0x1000
f0101ea8:	56                   	push   %esi
f0101ea9:	50                   	push   %eax
f0101eaa:	e8 6a f4 ff ff       	call   f0101319 <page_insert>
f0101eaf:	83 c4 10             	add    $0x10,%esp
f0101eb2:	85 c0                	test   %eax,%eax
f0101eb4:	74 19                	je     f0101ecf <mem_init+0xabe>
f0101eb6:	68 08 74 10 f0       	push   $0xf0107408
f0101ebb:	68 db 7a 10 f0       	push   $0xf0107adb
f0101ec0:	68 62 04 00 00       	push   $0x462
f0101ec5:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101eca:	e8 71 e1 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101ecf:	83 ec 04             	sub    $0x4,%esp
f0101ed2:	6a 00                	push   $0x0
f0101ed4:	68 00 10 00 00       	push   $0x1000
f0101ed9:	ff 35 dc 9e 2a f0    	pushl  0xf02a9edc
f0101edf:	e8 fd f1 ff ff       	call   f01010e1 <pgdir_walk>
f0101ee4:	83 c4 10             	add    $0x10,%esp
f0101ee7:	f6 00 02             	testb  $0x2,(%eax)
f0101eea:	75 19                	jne    f0101f05 <mem_init+0xaf4>
f0101eec:	68 28 75 10 f0       	push   $0xf0107528
f0101ef1:	68 db 7a 10 f0       	push   $0xf0107adb
f0101ef6:	68 63 04 00 00       	push   $0x463
f0101efb:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101f00:	e8 3b e1 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f05:	83 ec 04             	sub    $0x4,%esp
f0101f08:	6a 00                	push   $0x0
f0101f0a:	68 00 10 00 00       	push   $0x1000
f0101f0f:	ff 35 dc 9e 2a f0    	pushl  0xf02a9edc
f0101f15:	e8 c7 f1 ff ff       	call   f01010e1 <pgdir_walk>
f0101f1a:	83 c4 10             	add    $0x10,%esp
f0101f1d:	f6 00 04             	testb  $0x4,(%eax)
f0101f20:	74 19                	je     f0101f3b <mem_init+0xb2a>
f0101f22:	68 5c 75 10 f0       	push   $0xf010755c
f0101f27:	68 db 7a 10 f0       	push   $0xf0107adb
f0101f2c:	68 64 04 00 00       	push   $0x464
f0101f31:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101f36:	e8 05 e1 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101f3b:	6a 02                	push   $0x2
f0101f3d:	68 00 00 40 00       	push   $0x400000
f0101f42:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101f45:	ff 35 dc 9e 2a f0    	pushl  0xf02a9edc
f0101f4b:	e8 c9 f3 ff ff       	call   f0101319 <page_insert>
f0101f50:	83 c4 10             	add    $0x10,%esp
f0101f53:	85 c0                	test   %eax,%eax
f0101f55:	78 19                	js     f0101f70 <mem_init+0xb5f>
f0101f57:	68 94 75 10 f0       	push   $0xf0107594
f0101f5c:	68 db 7a 10 f0       	push   $0xf0107adb
f0101f61:	68 67 04 00 00       	push   $0x467
f0101f66:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101f6b:	e8 d0 e0 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101f70:	6a 02                	push   $0x2
f0101f72:	68 00 10 00 00       	push   $0x1000
f0101f77:	53                   	push   %ebx
f0101f78:	ff 35 dc 9e 2a f0    	pushl  0xf02a9edc
f0101f7e:	e8 96 f3 ff ff       	call   f0101319 <page_insert>
f0101f83:	83 c4 10             	add    $0x10,%esp
f0101f86:	85 c0                	test   %eax,%eax
f0101f88:	74 19                	je     f0101fa3 <mem_init+0xb92>
f0101f8a:	68 cc 75 10 f0       	push   $0xf01075cc
f0101f8f:	68 db 7a 10 f0       	push   $0xf0107adb
f0101f94:	68 6a 04 00 00       	push   $0x46a
f0101f99:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101f9e:	e8 9d e0 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101fa3:	83 ec 04             	sub    $0x4,%esp
f0101fa6:	6a 00                	push   $0x0
f0101fa8:	68 00 10 00 00       	push   $0x1000
f0101fad:	ff 35 dc 9e 2a f0    	pushl  0xf02a9edc
f0101fb3:	e8 29 f1 ff ff       	call   f01010e1 <pgdir_walk>
f0101fb8:	83 c4 10             	add    $0x10,%esp
f0101fbb:	f6 00 04             	testb  $0x4,(%eax)
f0101fbe:	74 19                	je     f0101fd9 <mem_init+0xbc8>
f0101fc0:	68 5c 75 10 f0       	push   $0xf010755c
f0101fc5:	68 db 7a 10 f0       	push   $0xf0107adb
f0101fca:	68 6b 04 00 00       	push   $0x46b
f0101fcf:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0101fd4:	e8 67 e0 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101fd9:	8b 3d dc 9e 2a f0    	mov    0xf02a9edc,%edi
f0101fdf:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fe4:	89 f8                	mov    %edi,%eax
f0101fe6:	e8 8d ea ff ff       	call   f0100a78 <check_va2pa>
f0101feb:	89 c1                	mov    %eax,%ecx
f0101fed:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101ff0:	89 d8                	mov    %ebx,%eax
f0101ff2:	2b 05 e0 9e 2a f0    	sub    0xf02a9ee0,%eax
f0101ff8:	c1 f8 03             	sar    $0x3,%eax
f0101ffb:	c1 e0 0c             	shl    $0xc,%eax
f0101ffe:	39 c1                	cmp    %eax,%ecx
f0102000:	74 19                	je     f010201b <mem_init+0xc0a>
f0102002:	68 08 76 10 f0       	push   $0xf0107608
f0102007:	68 db 7a 10 f0       	push   $0xf0107adb
f010200c:	68 6e 04 00 00       	push   $0x46e
f0102011:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102016:	e8 25 e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010201b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102020:	89 f8                	mov    %edi,%eax
f0102022:	e8 51 ea ff ff       	call   f0100a78 <check_va2pa>
f0102027:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f010202a:	74 19                	je     f0102045 <mem_init+0xc34>
f010202c:	68 34 76 10 f0       	push   $0xf0107634
f0102031:	68 db 7a 10 f0       	push   $0xf0107adb
f0102036:	68 6f 04 00 00       	push   $0x46f
f010203b:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102040:	e8 fb df ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102045:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f010204a:	74 19                	je     f0102065 <mem_init+0xc54>
f010204c:	68 16 7d 10 f0       	push   $0xf0107d16
f0102051:	68 db 7a 10 f0       	push   $0xf0107adb
f0102056:	68 71 04 00 00       	push   $0x471
f010205b:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102060:	e8 db df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102065:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010206a:	74 19                	je     f0102085 <mem_init+0xc74>
f010206c:	68 27 7d 10 f0       	push   $0xf0107d27
f0102071:	68 db 7a 10 f0       	push   $0xf0107adb
f0102076:	68 72 04 00 00       	push   $0x472
f010207b:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102080:	e8 bb df ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102085:	83 ec 0c             	sub    $0xc,%esp
f0102088:	6a 00                	push   $0x0
f010208a:	e8 64 ef ff ff       	call   f0100ff3 <page_alloc>
f010208f:	83 c4 10             	add    $0x10,%esp
f0102092:	85 c0                	test   %eax,%eax
f0102094:	74 04                	je     f010209a <mem_init+0xc89>
f0102096:	39 c6                	cmp    %eax,%esi
f0102098:	74 19                	je     f01020b3 <mem_init+0xca2>
f010209a:	68 64 76 10 f0       	push   $0xf0107664
f010209f:	68 db 7a 10 f0       	push   $0xf0107adb
f01020a4:	68 75 04 00 00       	push   $0x475
f01020a9:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01020ae:	e8 8d df ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f01020b3:	83 ec 08             	sub    $0x8,%esp
f01020b6:	6a 00                	push   $0x0
f01020b8:	ff 35 dc 9e 2a f0    	pushl  0xf02a9edc
f01020be:	e8 10 f2 ff ff       	call   f01012d3 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01020c3:	8b 3d dc 9e 2a f0    	mov    0xf02a9edc,%edi
f01020c9:	ba 00 00 00 00       	mov    $0x0,%edx
f01020ce:	89 f8                	mov    %edi,%eax
f01020d0:	e8 a3 e9 ff ff       	call   f0100a78 <check_va2pa>
f01020d5:	83 c4 10             	add    $0x10,%esp
f01020d8:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020db:	74 19                	je     f01020f6 <mem_init+0xce5>
f01020dd:	68 88 76 10 f0       	push   $0xf0107688
f01020e2:	68 db 7a 10 f0       	push   $0xf0107adb
f01020e7:	68 79 04 00 00       	push   $0x479
f01020ec:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01020f1:	e8 4a df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01020f6:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020fb:	89 f8                	mov    %edi,%eax
f01020fd:	e8 76 e9 ff ff       	call   f0100a78 <check_va2pa>
f0102102:	89 da                	mov    %ebx,%edx
f0102104:	2b 15 e0 9e 2a f0    	sub    0xf02a9ee0,%edx
f010210a:	c1 fa 03             	sar    $0x3,%edx
f010210d:	c1 e2 0c             	shl    $0xc,%edx
f0102110:	39 d0                	cmp    %edx,%eax
f0102112:	74 19                	je     f010212d <mem_init+0xd1c>
f0102114:	68 34 76 10 f0       	push   $0xf0107634
f0102119:	68 db 7a 10 f0       	push   $0xf0107adb
f010211e:	68 7a 04 00 00       	push   $0x47a
f0102123:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102128:	e8 13 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f010212d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102132:	74 19                	je     f010214d <mem_init+0xd3c>
f0102134:	68 cd 7c 10 f0       	push   $0xf0107ccd
f0102139:	68 db 7a 10 f0       	push   $0xf0107adb
f010213e:	68 7b 04 00 00       	push   $0x47b
f0102143:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102148:	e8 f3 de ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010214d:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102152:	74 19                	je     f010216d <mem_init+0xd5c>
f0102154:	68 27 7d 10 f0       	push   $0xf0107d27
f0102159:	68 db 7a 10 f0       	push   $0xf0107adb
f010215e:	68 7c 04 00 00       	push   $0x47c
f0102163:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102168:	e8 d3 de ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f010216d:	6a 00                	push   $0x0
f010216f:	68 00 10 00 00       	push   $0x1000
f0102174:	53                   	push   %ebx
f0102175:	57                   	push   %edi
f0102176:	e8 9e f1 ff ff       	call   f0101319 <page_insert>
f010217b:	83 c4 10             	add    $0x10,%esp
f010217e:	85 c0                	test   %eax,%eax
f0102180:	74 19                	je     f010219b <mem_init+0xd8a>
f0102182:	68 ac 76 10 f0       	push   $0xf01076ac
f0102187:	68 db 7a 10 f0       	push   $0xf0107adb
f010218c:	68 7f 04 00 00       	push   $0x47f
f0102191:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102196:	e8 a5 de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f010219b:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01021a0:	75 19                	jne    f01021bb <mem_init+0xdaa>
f01021a2:	68 38 7d 10 f0       	push   $0xf0107d38
f01021a7:	68 db 7a 10 f0       	push   $0xf0107adb
f01021ac:	68 80 04 00 00       	push   $0x480
f01021b1:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01021b6:	e8 85 de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f01021bb:	83 3b 00             	cmpl   $0x0,(%ebx)
f01021be:	74 19                	je     f01021d9 <mem_init+0xdc8>
f01021c0:	68 44 7d 10 f0       	push   $0xf0107d44
f01021c5:	68 db 7a 10 f0       	push   $0xf0107adb
f01021ca:	68 81 04 00 00       	push   $0x481
f01021cf:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01021d4:	e8 67 de ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01021d9:	83 ec 08             	sub    $0x8,%esp
f01021dc:	68 00 10 00 00       	push   $0x1000
f01021e1:	ff 35 dc 9e 2a f0    	pushl  0xf02a9edc
f01021e7:	e8 e7 f0 ff ff       	call   f01012d3 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01021ec:	8b 3d dc 9e 2a f0    	mov    0xf02a9edc,%edi
f01021f2:	ba 00 00 00 00       	mov    $0x0,%edx
f01021f7:	89 f8                	mov    %edi,%eax
f01021f9:	e8 7a e8 ff ff       	call   f0100a78 <check_va2pa>
f01021fe:	83 c4 10             	add    $0x10,%esp
f0102201:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102204:	74 19                	je     f010221f <mem_init+0xe0e>
f0102206:	68 88 76 10 f0       	push   $0xf0107688
f010220b:	68 db 7a 10 f0       	push   $0xf0107adb
f0102210:	68 85 04 00 00       	push   $0x485
f0102215:	68 b5 7a 10 f0       	push   $0xf0107ab5
f010221a:	e8 21 de ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010221f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102224:	89 f8                	mov    %edi,%eax
f0102226:	e8 4d e8 ff ff       	call   f0100a78 <check_va2pa>
f010222b:	83 f8 ff             	cmp    $0xffffffff,%eax
f010222e:	74 19                	je     f0102249 <mem_init+0xe38>
f0102230:	68 e4 76 10 f0       	push   $0xf01076e4
f0102235:	68 db 7a 10 f0       	push   $0xf0107adb
f010223a:	68 86 04 00 00       	push   $0x486
f010223f:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102244:	e8 f7 dd ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102249:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010224e:	74 19                	je     f0102269 <mem_init+0xe58>
f0102250:	68 59 7d 10 f0       	push   $0xf0107d59
f0102255:	68 db 7a 10 f0       	push   $0xf0107adb
f010225a:	68 87 04 00 00       	push   $0x487
f010225f:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102264:	e8 d7 dd ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102269:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010226e:	74 19                	je     f0102289 <mem_init+0xe78>
f0102270:	68 27 7d 10 f0       	push   $0xf0107d27
f0102275:	68 db 7a 10 f0       	push   $0xf0107adb
f010227a:	68 88 04 00 00       	push   $0x488
f010227f:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102284:	e8 b7 dd ff ff       	call   f0100040 <_panic>
	
	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102289:	83 ec 0c             	sub    $0xc,%esp
f010228c:	6a 00                	push   $0x0
f010228e:	e8 60 ed ff ff       	call   f0100ff3 <page_alloc>
f0102293:	83 c4 10             	add    $0x10,%esp
f0102296:	85 c0                	test   %eax,%eax
f0102298:	74 04                	je     f010229e <mem_init+0xe8d>
f010229a:	39 c3                	cmp    %eax,%ebx
f010229c:	74 19                	je     f01022b7 <mem_init+0xea6>
f010229e:	68 0c 77 10 f0       	push   $0xf010770c
f01022a3:	68 db 7a 10 f0       	push   $0xf0107adb
f01022a8:	68 8b 04 00 00       	push   $0x48b
f01022ad:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01022b2:	e8 89 dd ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01022b7:	83 ec 0c             	sub    $0xc,%esp
f01022ba:	6a 00                	push   $0x0
f01022bc:	e8 32 ed ff ff       	call   f0100ff3 <page_alloc>
f01022c1:	83 c4 10             	add    $0x10,%esp
f01022c4:	85 c0                	test   %eax,%eax
f01022c6:	74 19                	je     f01022e1 <mem_init+0xed0>
f01022c8:	68 7b 7c 10 f0       	push   $0xf0107c7b
f01022cd:	68 db 7a 10 f0       	push   $0xf0107adb
f01022d2:	68 8e 04 00 00       	push   $0x48e
f01022d7:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01022dc:	e8 5f dd ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01022e1:	8b 0d dc 9e 2a f0    	mov    0xf02a9edc,%ecx
f01022e7:	8b 11                	mov    (%ecx),%edx
f01022e9:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01022ef:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022f2:	2b 05 e0 9e 2a f0    	sub    0xf02a9ee0,%eax
f01022f8:	c1 f8 03             	sar    $0x3,%eax
f01022fb:	c1 e0 0c             	shl    $0xc,%eax
f01022fe:	39 c2                	cmp    %eax,%edx
f0102300:	74 19                	je     f010231b <mem_init+0xf0a>
f0102302:	68 b0 73 10 f0       	push   $0xf01073b0
f0102307:	68 db 7a 10 f0       	push   $0xf0107adb
f010230c:	68 91 04 00 00       	push   $0x491
f0102311:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102316:	e8 25 dd ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f010231b:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102321:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102324:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102329:	74 19                	je     f0102344 <mem_init+0xf33>
f010232b:	68 de 7c 10 f0       	push   $0xf0107cde
f0102330:	68 db 7a 10 f0       	push   $0xf0107adb
f0102335:	68 93 04 00 00       	push   $0x493
f010233a:	68 b5 7a 10 f0       	push   $0xf0107ab5
f010233f:	e8 fc dc ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102344:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102347:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010234d:	83 ec 0c             	sub    $0xc,%esp
f0102350:	50                   	push   %eax
f0102351:	e8 13 ed ff ff       	call   f0101069 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102356:	83 c4 0c             	add    $0xc,%esp
f0102359:	6a 01                	push   $0x1
f010235b:	68 00 10 40 00       	push   $0x401000
f0102360:	ff 35 dc 9e 2a f0    	pushl  0xf02a9edc
f0102366:	e8 76 ed ff ff       	call   f01010e1 <pgdir_walk>
f010236b:	89 c7                	mov    %eax,%edi
f010236d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102370:	a1 dc 9e 2a f0       	mov    0xf02a9edc,%eax
f0102375:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102378:	8b 40 04             	mov    0x4(%eax),%eax
f010237b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102380:	8b 0d d8 9e 2a f0    	mov    0xf02a9ed8,%ecx
f0102386:	89 c2                	mov    %eax,%edx
f0102388:	c1 ea 0c             	shr    $0xc,%edx
f010238b:	83 c4 10             	add    $0x10,%esp
f010238e:	39 ca                	cmp    %ecx,%edx
f0102390:	72 15                	jb     f01023a7 <mem_init+0xf96>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102392:	50                   	push   %eax
f0102393:	68 24 6b 10 f0       	push   $0xf0106b24
f0102398:	68 9a 04 00 00       	push   $0x49a
f010239d:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01023a2:	e8 99 dc ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01023a7:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f01023ac:	39 c7                	cmp    %eax,%edi
f01023ae:	74 19                	je     f01023c9 <mem_init+0xfb8>
f01023b0:	68 6a 7d 10 f0       	push   $0xf0107d6a
f01023b5:	68 db 7a 10 f0       	push   $0xf0107adb
f01023ba:	68 9b 04 00 00       	push   $0x49b
f01023bf:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01023c4:	e8 77 dc ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01023c9:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01023cc:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f01023d3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01023d6:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01023dc:	2b 05 e0 9e 2a f0    	sub    0xf02a9ee0,%eax
f01023e2:	c1 f8 03             	sar    $0x3,%eax
f01023e5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01023e8:	89 c2                	mov    %eax,%edx
f01023ea:	c1 ea 0c             	shr    $0xc,%edx
f01023ed:	39 d1                	cmp    %edx,%ecx
f01023ef:	77 12                	ja     f0102403 <mem_init+0xff2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01023f1:	50                   	push   %eax
f01023f2:	68 24 6b 10 f0       	push   $0xf0106b24
f01023f7:	6a 58                	push   $0x58
f01023f9:	68 c1 7a 10 f0       	push   $0xf0107ac1
f01023fe:	e8 3d dc ff ff       	call   f0100040 <_panic>
	
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102403:	83 ec 04             	sub    $0x4,%esp
f0102406:	68 00 10 00 00       	push   $0x1000
f010240b:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0102410:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102415:	50                   	push   %eax
f0102416:	e8 37 30 00 00       	call   f0105452 <memset>
	page_free(pp0);
f010241b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010241e:	89 3c 24             	mov    %edi,(%esp)
f0102421:	e8 43 ec ff ff       	call   f0101069 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102426:	83 c4 0c             	add    $0xc,%esp
f0102429:	6a 01                	push   $0x1
f010242b:	6a 00                	push   $0x0
f010242d:	ff 35 dc 9e 2a f0    	pushl  0xf02a9edc
f0102433:	e8 a9 ec ff ff       	call   f01010e1 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102438:	89 fa                	mov    %edi,%edx
f010243a:	2b 15 e0 9e 2a f0    	sub    0xf02a9ee0,%edx
f0102440:	c1 fa 03             	sar    $0x3,%edx
f0102443:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102446:	89 d0                	mov    %edx,%eax
f0102448:	c1 e8 0c             	shr    $0xc,%eax
f010244b:	83 c4 10             	add    $0x10,%esp
f010244e:	3b 05 d8 9e 2a f0    	cmp    0xf02a9ed8,%eax
f0102454:	72 12                	jb     f0102468 <mem_init+0x1057>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102456:	52                   	push   %edx
f0102457:	68 24 6b 10 f0       	push   $0xf0106b24
f010245c:	6a 58                	push   $0x58
f010245e:	68 c1 7a 10 f0       	push   $0xf0107ac1
f0102463:	e8 d8 db ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102468:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010246e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102471:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102477:	f6 00 01             	testb  $0x1,(%eax)
f010247a:	74 19                	je     f0102495 <mem_init+0x1084>
f010247c:	68 82 7d 10 f0       	push   $0xf0107d82
f0102481:	68 db 7a 10 f0       	push   $0xf0107adb
f0102486:	68 a5 04 00 00       	push   $0x4a5
f010248b:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102490:	e8 ab db ff ff       	call   f0100040 <_panic>
f0102495:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102498:	39 d0                	cmp    %edx,%eax
f010249a:	75 db                	jne    f0102477 <mem_init+0x1066>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010249c:	a1 dc 9e 2a f0       	mov    0xf02a9edc,%eax
f01024a1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01024a7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01024aa:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01024b0:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01024b3:	89 0d 64 92 2a f0    	mov    %ecx,0xf02a9264

	// free the pages we took
	page_free(pp0);
f01024b9:	83 ec 0c             	sub    $0xc,%esp
f01024bc:	50                   	push   %eax
f01024bd:	e8 a7 eb ff ff       	call   f0101069 <page_free>
	page_free(pp1);
f01024c2:	89 1c 24             	mov    %ebx,(%esp)
f01024c5:	e8 9f eb ff ff       	call   f0101069 <page_free>
	page_free(pp2);
f01024ca:	89 34 24             	mov    %esi,(%esp)
f01024cd:	e8 97 eb ff ff       	call   f0101069 <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f01024d2:	83 c4 08             	add    $0x8,%esp
f01024d5:	68 01 10 00 00       	push   $0x1001
f01024da:	6a 00                	push   $0x0
f01024dc:	e8 f1 ee ff ff       	call   f01013d2 <mmio_map_region>
f01024e1:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f01024e3:	83 c4 08             	add    $0x8,%esp
f01024e6:	68 00 10 00 00       	push   $0x1000
f01024eb:	6a 00                	push   $0x0
f01024ed:	e8 e0 ee ff ff       	call   f01013d2 <mmio_map_region>
f01024f2:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f01024f4:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f01024fa:	83 c4 10             	add    $0x10,%esp
f01024fd:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f0102502:	77 08                	ja     f010250c <mem_init+0x10fb>
f0102504:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f010250a:	77 19                	ja     f0102525 <mem_init+0x1114>
f010250c:	68 30 77 10 f0       	push   $0xf0107730
f0102511:	68 db 7a 10 f0       	push   $0xf0107adb
f0102516:	68 b5 04 00 00       	push   $0x4b5
f010251b:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102520:	e8 1b db ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f0102525:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f010252b:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f0102531:	77 08                	ja     f010253b <mem_init+0x112a>
f0102533:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102539:	77 19                	ja     f0102554 <mem_init+0x1143>
f010253b:	68 58 77 10 f0       	push   $0xf0107758
f0102540:	68 db 7a 10 f0       	push   $0xf0107adb
f0102545:	68 b6 04 00 00       	push   $0x4b6
f010254a:	68 b5 7a 10 f0       	push   $0xf0107ab5
f010254f:	e8 ec da ff ff       	call   f0100040 <_panic>
f0102554:	89 da                	mov    %ebx,%edx
f0102556:	09 f2                	or     %esi,%edx
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102558:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f010255e:	74 19                	je     f0102579 <mem_init+0x1168>
f0102560:	68 80 77 10 f0       	push   $0xf0107780
f0102565:	68 db 7a 10 f0       	push   $0xf0107adb
f010256a:	68 b8 04 00 00       	push   $0x4b8
f010256f:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102574:	e8 c7 da ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f0102579:	39 c6                	cmp    %eax,%esi
f010257b:	73 19                	jae    f0102596 <mem_init+0x1185>
f010257d:	68 99 7d 10 f0       	push   $0xf0107d99
f0102582:	68 db 7a 10 f0       	push   $0xf0107adb
f0102587:	68 ba 04 00 00       	push   $0x4ba
f010258c:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102591:	e8 aa da ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102596:	8b 3d dc 9e 2a f0    	mov    0xf02a9edc,%edi
f010259c:	89 da                	mov    %ebx,%edx
f010259e:	89 f8                	mov    %edi,%eax
f01025a0:	e8 d3 e4 ff ff       	call   f0100a78 <check_va2pa>
f01025a5:	85 c0                	test   %eax,%eax
f01025a7:	74 19                	je     f01025c2 <mem_init+0x11b1>
f01025a9:	68 a8 77 10 f0       	push   $0xf01077a8
f01025ae:	68 db 7a 10 f0       	push   $0xf0107adb
f01025b3:	68 bc 04 00 00       	push   $0x4bc
f01025b8:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01025bd:	e8 7e da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f01025c2:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f01025c8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01025cb:	89 c2                	mov    %eax,%edx
f01025cd:	89 f8                	mov    %edi,%eax
f01025cf:	e8 a4 e4 ff ff       	call   f0100a78 <check_va2pa>
f01025d4:	3d 00 10 00 00       	cmp    $0x1000,%eax
f01025d9:	74 19                	je     f01025f4 <mem_init+0x11e3>
f01025db:	68 cc 77 10 f0       	push   $0xf01077cc
f01025e0:	68 db 7a 10 f0       	push   $0xf0107adb
f01025e5:	68 bd 04 00 00       	push   $0x4bd
f01025ea:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01025ef:	e8 4c da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f01025f4:	89 f2                	mov    %esi,%edx
f01025f6:	89 f8                	mov    %edi,%eax
f01025f8:	e8 7b e4 ff ff       	call   f0100a78 <check_va2pa>
f01025fd:	85 c0                	test   %eax,%eax
f01025ff:	74 19                	je     f010261a <mem_init+0x1209>
f0102601:	68 fc 77 10 f0       	push   $0xf01077fc
f0102606:	68 db 7a 10 f0       	push   $0xf0107adb
f010260b:	68 be 04 00 00       	push   $0x4be
f0102610:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102615:	e8 26 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f010261a:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f0102620:	89 f8                	mov    %edi,%eax
f0102622:	e8 51 e4 ff ff       	call   f0100a78 <check_va2pa>
f0102627:	83 f8 ff             	cmp    $0xffffffff,%eax
f010262a:	74 19                	je     f0102645 <mem_init+0x1234>
f010262c:	68 20 78 10 f0       	push   $0xf0107820
f0102631:	68 db 7a 10 f0       	push   $0xf0107adb
f0102636:	68 bf 04 00 00       	push   $0x4bf
f010263b:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102640:	e8 fb d9 ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102645:	83 ec 04             	sub    $0x4,%esp
f0102648:	6a 00                	push   $0x0
f010264a:	53                   	push   %ebx
f010264b:	57                   	push   %edi
f010264c:	e8 90 ea ff ff       	call   f01010e1 <pgdir_walk>
f0102651:	83 c4 10             	add    $0x10,%esp
f0102654:	f6 00 1a             	testb  $0x1a,(%eax)
f0102657:	75 19                	jne    f0102672 <mem_init+0x1261>
f0102659:	68 4c 78 10 f0       	push   $0xf010784c
f010265e:	68 db 7a 10 f0       	push   $0xf0107adb
f0102663:	68 c1 04 00 00       	push   $0x4c1
f0102668:	68 b5 7a 10 f0       	push   $0xf0107ab5
f010266d:	e8 ce d9 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102672:	83 ec 04             	sub    $0x4,%esp
f0102675:	6a 00                	push   $0x0
f0102677:	53                   	push   %ebx
f0102678:	ff 35 dc 9e 2a f0    	pushl  0xf02a9edc
f010267e:	e8 5e ea ff ff       	call   f01010e1 <pgdir_walk>
f0102683:	83 c4 10             	add    $0x10,%esp
f0102686:	f6 00 04             	testb  $0x4,(%eax)
f0102689:	74 19                	je     f01026a4 <mem_init+0x1293>
f010268b:	68 90 78 10 f0       	push   $0xf0107890
f0102690:	68 db 7a 10 f0       	push   $0xf0107adb
f0102695:	68 c2 04 00 00       	push   $0x4c2
f010269a:	68 b5 7a 10 f0       	push   $0xf0107ab5
f010269f:	e8 9c d9 ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f01026a4:	83 ec 04             	sub    $0x4,%esp
f01026a7:	6a 00                	push   $0x0
f01026a9:	53                   	push   %ebx
f01026aa:	ff 35 dc 9e 2a f0    	pushl  0xf02a9edc
f01026b0:	e8 2c ea ff ff       	call   f01010e1 <pgdir_walk>
f01026b5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f01026bb:	83 c4 0c             	add    $0xc,%esp
f01026be:	6a 00                	push   $0x0
f01026c0:	ff 75 d4             	pushl  -0x2c(%ebp)
f01026c3:	ff 35 dc 9e 2a f0    	pushl  0xf02a9edc
f01026c9:	e8 13 ea ff ff       	call   f01010e1 <pgdir_walk>
f01026ce:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f01026d4:	83 c4 0c             	add    $0xc,%esp
f01026d7:	6a 00                	push   $0x0
f01026d9:	56                   	push   %esi
f01026da:	ff 35 dc 9e 2a f0    	pushl  0xf02a9edc
f01026e0:	e8 fc e9 ff ff       	call   f01010e1 <pgdir_walk>
f01026e5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f01026eb:	c7 04 24 ab 7d 10 f0 	movl   $0xf0107dab,(%esp)
f01026f2:	e8 62 11 00 00       	call   f0103859 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, ROUNDUP( (sizeof(struct PageInfo)*npages),PGSIZE), PADDR(pages), PTE_U | PTE_P);
f01026f7:	a1 e0 9e 2a f0       	mov    0xf02a9ee0,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026fc:	83 c4 10             	add    $0x10,%esp
f01026ff:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102704:	77 15                	ja     f010271b <mem_init+0x130a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102706:	50                   	push   %eax
f0102707:	68 48 6b 10 f0       	push   $0xf0106b48
f010270c:	68 c5 00 00 00       	push   $0xc5
f0102711:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102716:	e8 25 d9 ff ff       	call   f0100040 <_panic>
f010271b:	8b 15 d8 9e 2a f0    	mov    0xf02a9ed8,%edx
f0102721:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f0102728:	83 ec 08             	sub    $0x8,%esp
f010272b:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102731:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f0102733:	05 00 00 00 10       	add    $0x10000000,%eax
f0102738:	50                   	push   %eax
f0102739:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010273e:	a1 dc 9e 2a f0       	mov    0xf02a9edc,%eax
f0102743:	e8 84 ea ff ff       	call   f01011cc <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, sizeof(struct Env) * NENV,PADDR(envs), PTE_U);
f0102748:	a1 6c 92 2a f0       	mov    0xf02a926c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010274d:	83 c4 10             	add    $0x10,%esp
f0102750:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102755:	77 15                	ja     f010276c <mem_init+0x135b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102757:	50                   	push   %eax
f0102758:	68 48 6b 10 f0       	push   $0xf0106b48
f010275d:	68 cd 00 00 00       	push   $0xcd
f0102762:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102767:	e8 d4 d8 ff ff       	call   f0100040 <_panic>
f010276c:	83 ec 08             	sub    $0x8,%esp
f010276f:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f0102771:	05 00 00 00 10       	add    $0x10000000,%eax
f0102776:	50                   	push   %eax
f0102777:	b9 00 f0 01 00       	mov    $0x1f000,%ecx
f010277c:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102781:	a1 dc 9e 2a f0       	mov    0xf02a9edc,%eax
f0102786:	e8 41 ea ff ff       	call   f01011cc <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010278b:	83 c4 10             	add    $0x10,%esp
f010278e:	b8 00 a0 11 f0       	mov    $0xf011a000,%eax
f0102793:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102798:	77 15                	ja     f01027af <mem_init+0x139e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010279a:	50                   	push   %eax
f010279b:	68 48 6b 10 f0       	push   $0xf0106b48
f01027a0:	68 d9 00 00 00       	push   $0xd9
f01027a5:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01027aa:	e8 91 d8 ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W | PTE_P);
f01027af:	83 ec 08             	sub    $0x8,%esp
f01027b2:	6a 03                	push   $0x3
f01027b4:	68 00 a0 11 00       	push   $0x11a000
f01027b9:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01027be:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01027c3:	a1 dc 9e 2a f0       	mov    0xf02a9edc,%eax
f01027c8:	e8 ff e9 ff ff       	call   f01011cc <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	size_t size = ROUNDUP(0xFFFFFFFF - KERNBASE + 1, PGSIZE);
	boot_map_region(kern_pgdir, KERNBASE, size, 0, PTE_W | PTE_P);
f01027cd:	83 c4 08             	add    $0x8,%esp
f01027d0:	6a 03                	push   $0x3
f01027d2:	6a 00                	push   $0x0
f01027d4:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01027d9:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01027de:	a1 dc 9e 2a f0       	mov    0xf02a9edc,%eax
f01027e3:	e8 e4 e9 ff ff       	call   f01011cc <boot_map_region>
f01027e8:	c7 45 c4 00 b0 2a f0 	movl   $0xf02ab000,-0x3c(%ebp)
f01027ef:	83 c4 10             	add    $0x10,%esp
f01027f2:	bb 00 b0 2a f0       	mov    $0xf02ab000,%ebx
f01027f7:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027fc:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102802:	77 15                	ja     f0102819 <mem_init+0x1408>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102804:	53                   	push   %ebx
f0102805:	68 48 6b 10 f0       	push   $0xf0106b48
f010280a:	68 20 01 00 00       	push   $0x120
f010280f:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102814:	e8 27 d8 ff ff       	call   f0100040 <_panic>
	uint32_t percpu_stacktop = KSTACKTOP;
	//uint32_t percpu_stackbtm;
	
	for (i=0;i<NCPU;i++)
	{	
		boot_map_region(kern_pgdir, percpu_stacktop - KSTKSIZE, KSTKSIZE,PADDR((void*)percpu_kstacks[i]), PTE_W | PTE_P);
f0102819:	83 ec 08             	sub    $0x8,%esp
f010281c:	6a 03                	push   $0x3
f010281e:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f0102824:	50                   	push   %eax
f0102825:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010282a:	89 f2                	mov    %esi,%edx
f010282c:	a1 dc 9e 2a f0       	mov    0xf02a9edc,%eax
f0102831:	e8 96 e9 ff ff       	call   f01011cc <boot_map_region>
f0102836:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f010283c:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	
	int i=0;
	uint32_t percpu_stacktop = KSTACKTOP;
	//uint32_t percpu_stackbtm;
	
	for (i=0;i<NCPU;i++)
f0102842:	83 c4 10             	add    $0x10,%esp
f0102845:	81 fb 00 b0 2e f0    	cmp    $0xf02eb000,%ebx
f010284b:	75 af                	jne    f01027fc <mem_init+0x13eb>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010284d:	8b 3d dc 9e 2a f0    	mov    0xf02a9edc,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102853:	a1 d8 9e 2a f0       	mov    0xf02a9ed8,%eax
f0102858:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010285b:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102862:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102867:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010286a:	8b 35 e0 9e 2a f0    	mov    0xf02a9ee0,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102870:	89 75 d0             	mov    %esi,-0x30(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102873:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102878:	eb 55                	jmp    f01028cf <mem_init+0x14be>
f010287a:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102880:	89 f8                	mov    %edi,%eax
f0102882:	e8 f1 e1 ff ff       	call   f0100a78 <check_va2pa>
f0102887:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f010288e:	77 15                	ja     f01028a5 <mem_init+0x1494>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102890:	56                   	push   %esi
f0102891:	68 48 6b 10 f0       	push   $0xf0106b48
f0102896:	68 d7 03 00 00       	push   $0x3d7
f010289b:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01028a0:	e8 9b d7 ff ff       	call   f0100040 <_panic>
f01028a5:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f01028ac:	39 d0                	cmp    %edx,%eax
f01028ae:	74 19                	je     f01028c9 <mem_init+0x14b8>
f01028b0:	68 c4 78 10 f0       	push   $0xf01078c4
f01028b5:	68 db 7a 10 f0       	push   $0xf0107adb
f01028ba:	68 d7 03 00 00       	push   $0x3d7
f01028bf:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01028c4:	e8 77 d7 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01028c9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01028cf:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01028d2:	77 a6                	ja     f010287a <mem_init+0x1469>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01028d4:	8b 35 6c 92 2a f0    	mov    0xf02a926c,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028da:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01028dd:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f01028e2:	89 da                	mov    %ebx,%edx
f01028e4:	89 f8                	mov    %edi,%eax
f01028e6:	e8 8d e1 ff ff       	call   f0100a78 <check_va2pa>
f01028eb:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f01028f2:	77 15                	ja     f0102909 <mem_init+0x14f8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028f4:	56                   	push   %esi
f01028f5:	68 48 6b 10 f0       	push   $0xf0106b48
f01028fa:	68 dc 03 00 00       	push   $0x3dc
f01028ff:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102904:	e8 37 d7 ff ff       	call   f0100040 <_panic>
f0102909:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f0102910:	39 d0                	cmp    %edx,%eax
f0102912:	74 19                	je     f010292d <mem_init+0x151c>
f0102914:	68 f8 78 10 f0       	push   $0xf01078f8
f0102919:	68 db 7a 10 f0       	push   $0xf0107adb
f010291e:	68 dc 03 00 00       	push   $0x3dc
f0102923:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102928:	e8 13 d7 ff ff       	call   f0100040 <_panic>
f010292d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102933:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f0102939:	75 a7                	jne    f01028e2 <mem_init+0x14d1>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010293b:	8b 75 cc             	mov    -0x34(%ebp),%esi
f010293e:	c1 e6 0c             	shl    $0xc,%esi
f0102941:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102946:	eb 30                	jmp    f0102978 <mem_init+0x1567>
f0102948:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010294e:	89 f8                	mov    %edi,%eax
f0102950:	e8 23 e1 ff ff       	call   f0100a78 <check_va2pa>
f0102955:	39 c3                	cmp    %eax,%ebx
f0102957:	74 19                	je     f0102972 <mem_init+0x1561>
f0102959:	68 2c 79 10 f0       	push   $0xf010792c
f010295e:	68 db 7a 10 f0       	push   $0xf0107adb
f0102963:	68 e0 03 00 00       	push   $0x3e0
f0102968:	68 b5 7a 10 f0       	push   $0xf0107ab5
f010296d:	e8 ce d6 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102972:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102978:	39 f3                	cmp    %esi,%ebx
f010297a:	72 cc                	jb     f0102948 <mem_init+0x1537>
f010297c:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
f0102983:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102988:	89 75 cc             	mov    %esi,-0x34(%ebp)
f010298b:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f010298e:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102991:	8d 88 00 80 00 00    	lea    0x8000(%eax),%ecx
f0102997:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f010299a:	89 c3                	mov    %eax,%ebx
f010299c:	8b 45 c8             	mov    -0x38(%ebp),%eax
f010299f:	05 00 80 00 20       	add    $0x20008000,%eax
f01029a4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f01029a7:	89 da                	mov    %ebx,%edx
f01029a9:	89 f8                	mov    %edi,%eax
f01029ab:	e8 c8 e0 ff ff       	call   f0100a78 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01029b0:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f01029b6:	77 15                	ja     f01029cd <mem_init+0x15bc>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029b8:	56                   	push   %esi
f01029b9:	68 48 6b 10 f0       	push   $0xf0106b48
f01029be:	68 e8 03 00 00       	push   $0x3e8
f01029c3:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01029c8:	e8 73 d6 ff ff       	call   f0100040 <_panic>
f01029cd:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01029d0:	8d 94 0b 00 b0 2a f0 	lea    -0xfd55000(%ebx,%ecx,1),%edx
f01029d7:	39 d0                	cmp    %edx,%eax
f01029d9:	74 19                	je     f01029f4 <mem_init+0x15e3>
f01029db:	68 54 79 10 f0       	push   $0xf0107954
f01029e0:	68 db 7a 10 f0       	push   $0xf0107adb
f01029e5:	68 e8 03 00 00       	push   $0x3e8
f01029ea:	68 b5 7a 10 f0       	push   $0xf0107ab5
f01029ef:	e8 4c d6 ff ff       	call   f0100040 <_panic>
f01029f4:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01029fa:	3b 5d d0             	cmp    -0x30(%ebp),%ebx
f01029fd:	75 a8                	jne    f01029a7 <mem_init+0x1596>
f01029ff:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102a02:	8d 98 00 80 ff ff    	lea    -0x8000(%eax),%ebx
f0102a08:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0102a0b:	89 c6                	mov    %eax,%esi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f0102a0d:	89 da                	mov    %ebx,%edx
f0102a0f:	89 f8                	mov    %edi,%eax
f0102a11:	e8 62 e0 ff ff       	call   f0100a78 <check_va2pa>
f0102a16:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102a19:	74 19                	je     f0102a34 <mem_init+0x1623>
f0102a1b:	68 9c 79 10 f0       	push   $0xf010799c
f0102a20:	68 db 7a 10 f0       	push   $0xf0107adb
f0102a25:	68 ea 03 00 00       	push   $0x3ea
f0102a2a:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102a2f:	e8 0c d6 ff ff       	call   f0100040 <_panic>
f0102a34:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f0102a3a:	39 de                	cmp    %ebx,%esi
f0102a3c:	75 cf                	jne    f0102a0d <mem_init+0x15fc>
f0102a3e:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102a41:	81 6d cc 00 00 01 00 	subl   $0x10000,-0x34(%ebp)
f0102a48:	81 45 c8 00 80 01 00 	addl   $0x18000,-0x38(%ebp)
f0102a4f:	81 c6 00 80 00 00    	add    $0x8000,%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f0102a55:	81 fe 00 b0 2e f0    	cmp    $0xf02eb000,%esi
f0102a5b:	0f 85 2d ff ff ff    	jne    f010298e <mem_init+0x157d>
f0102a61:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a66:	eb 2a                	jmp    f0102a92 <mem_init+0x1681>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102a68:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0102a6e:	83 fa 04             	cmp    $0x4,%edx
f0102a71:	77 1f                	ja     f0102a92 <mem_init+0x1681>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f0102a73:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0102a77:	75 7e                	jne    f0102af7 <mem_init+0x16e6>
f0102a79:	68 c4 7d 10 f0       	push   $0xf0107dc4
f0102a7e:	68 db 7a 10 f0       	push   $0xf0107adb
f0102a83:	68 f5 03 00 00       	push   $0x3f5
f0102a88:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102a8d:	e8 ae d5 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102a92:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102a97:	76 3f                	jbe    f0102ad8 <mem_init+0x16c7>
				assert(pgdir[i] & PTE_P);
f0102a99:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0102a9c:	f6 c2 01             	test   $0x1,%dl
f0102a9f:	75 19                	jne    f0102aba <mem_init+0x16a9>
f0102aa1:	68 c4 7d 10 f0       	push   $0xf0107dc4
f0102aa6:	68 db 7a 10 f0       	push   $0xf0107adb
f0102aab:	68 f9 03 00 00       	push   $0x3f9
f0102ab0:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102ab5:	e8 86 d5 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f0102aba:	f6 c2 02             	test   $0x2,%dl
f0102abd:	75 38                	jne    f0102af7 <mem_init+0x16e6>
f0102abf:	68 d5 7d 10 f0       	push   $0xf0107dd5
f0102ac4:	68 db 7a 10 f0       	push   $0xf0107adb
f0102ac9:	68 fa 03 00 00       	push   $0x3fa
f0102ace:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102ad3:	e8 68 d5 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102ad8:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102adc:	74 19                	je     f0102af7 <mem_init+0x16e6>
f0102ade:	68 e6 7d 10 f0       	push   $0xf0107de6
f0102ae3:	68 db 7a 10 f0       	push   $0xf0107adb
f0102ae8:	68 fc 03 00 00       	push   $0x3fc
f0102aed:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102af2:	e8 49 d5 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102af7:	83 c0 01             	add    $0x1,%eax
f0102afa:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102aff:	0f 86 63 ff ff ff    	jbe    f0102a68 <mem_init+0x1657>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102b05:	83 ec 0c             	sub    $0xc,%esp
f0102b08:	68 c0 79 10 f0       	push   $0xf01079c0
f0102b0d:	e8 47 0d 00 00       	call   f0103859 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102b12:	a1 dc 9e 2a f0       	mov    0xf02a9edc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b17:	83 c4 10             	add    $0x10,%esp
f0102b1a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b1f:	77 15                	ja     f0102b36 <mem_init+0x1725>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b21:	50                   	push   %eax
f0102b22:	68 48 6b 10 f0       	push   $0xf0106b48
f0102b27:	68 f2 00 00 00       	push   $0xf2
f0102b2c:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102b31:	e8 0a d5 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102b36:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102b3b:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102b3e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b43:	e8 0a e0 ff ff       	call   f0100b52 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102b48:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102b4b:	83 e0 f3             	and    $0xfffffff3,%eax
f0102b4e:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102b53:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102b56:	83 ec 0c             	sub    $0xc,%esp
f0102b59:	6a 00                	push   $0x0
f0102b5b:	e8 93 e4 ff ff       	call   f0100ff3 <page_alloc>
f0102b60:	89 c3                	mov    %eax,%ebx
f0102b62:	83 c4 10             	add    $0x10,%esp
f0102b65:	85 c0                	test   %eax,%eax
f0102b67:	75 19                	jne    f0102b82 <mem_init+0x1771>
f0102b69:	68 d0 7b 10 f0       	push   $0xf0107bd0
f0102b6e:	68 db 7a 10 f0       	push   $0xf0107adb
f0102b73:	68 d7 04 00 00       	push   $0x4d7
f0102b78:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102b7d:	e8 be d4 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102b82:	83 ec 0c             	sub    $0xc,%esp
f0102b85:	6a 00                	push   $0x0
f0102b87:	e8 67 e4 ff ff       	call   f0100ff3 <page_alloc>
f0102b8c:	89 c7                	mov    %eax,%edi
f0102b8e:	83 c4 10             	add    $0x10,%esp
f0102b91:	85 c0                	test   %eax,%eax
f0102b93:	75 19                	jne    f0102bae <mem_init+0x179d>
f0102b95:	68 e6 7b 10 f0       	push   $0xf0107be6
f0102b9a:	68 db 7a 10 f0       	push   $0xf0107adb
f0102b9f:	68 d8 04 00 00       	push   $0x4d8
f0102ba4:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102ba9:	e8 92 d4 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102bae:	83 ec 0c             	sub    $0xc,%esp
f0102bb1:	6a 00                	push   $0x0
f0102bb3:	e8 3b e4 ff ff       	call   f0100ff3 <page_alloc>
f0102bb8:	89 c6                	mov    %eax,%esi
f0102bba:	83 c4 10             	add    $0x10,%esp
f0102bbd:	85 c0                	test   %eax,%eax
f0102bbf:	75 19                	jne    f0102bda <mem_init+0x17c9>
f0102bc1:	68 fc 7b 10 f0       	push   $0xf0107bfc
f0102bc6:	68 db 7a 10 f0       	push   $0xf0107adb
f0102bcb:	68 d9 04 00 00       	push   $0x4d9
f0102bd0:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102bd5:	e8 66 d4 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f0102bda:	83 ec 0c             	sub    $0xc,%esp
f0102bdd:	53                   	push   %ebx
f0102bde:	e8 86 e4 ff ff       	call   f0101069 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102be3:	89 f8                	mov    %edi,%eax
f0102be5:	2b 05 e0 9e 2a f0    	sub    0xf02a9ee0,%eax
f0102beb:	c1 f8 03             	sar    $0x3,%eax
f0102bee:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bf1:	89 c2                	mov    %eax,%edx
f0102bf3:	c1 ea 0c             	shr    $0xc,%edx
f0102bf6:	83 c4 10             	add    $0x10,%esp
f0102bf9:	3b 15 d8 9e 2a f0    	cmp    0xf02a9ed8,%edx
f0102bff:	72 12                	jb     f0102c13 <mem_init+0x1802>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c01:	50                   	push   %eax
f0102c02:	68 24 6b 10 f0       	push   $0xf0106b24
f0102c07:	6a 58                	push   $0x58
f0102c09:	68 c1 7a 10 f0       	push   $0xf0107ac1
f0102c0e:	e8 2d d4 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102c13:	83 ec 04             	sub    $0x4,%esp
f0102c16:	68 00 10 00 00       	push   $0x1000
f0102c1b:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102c1d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102c22:	50                   	push   %eax
f0102c23:	e8 2a 28 00 00       	call   f0105452 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c28:	89 f0                	mov    %esi,%eax
f0102c2a:	2b 05 e0 9e 2a f0    	sub    0xf02a9ee0,%eax
f0102c30:	c1 f8 03             	sar    $0x3,%eax
f0102c33:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c36:	89 c2                	mov    %eax,%edx
f0102c38:	c1 ea 0c             	shr    $0xc,%edx
f0102c3b:	83 c4 10             	add    $0x10,%esp
f0102c3e:	3b 15 d8 9e 2a f0    	cmp    0xf02a9ed8,%edx
f0102c44:	72 12                	jb     f0102c58 <mem_init+0x1847>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c46:	50                   	push   %eax
f0102c47:	68 24 6b 10 f0       	push   $0xf0106b24
f0102c4c:	6a 58                	push   $0x58
f0102c4e:	68 c1 7a 10 f0       	push   $0xf0107ac1
f0102c53:	e8 e8 d3 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102c58:	83 ec 04             	sub    $0x4,%esp
f0102c5b:	68 00 10 00 00       	push   $0x1000
f0102c60:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102c62:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102c67:	50                   	push   %eax
f0102c68:	e8 e5 27 00 00       	call   f0105452 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102c6d:	6a 02                	push   $0x2
f0102c6f:	68 00 10 00 00       	push   $0x1000
f0102c74:	57                   	push   %edi
f0102c75:	ff 35 dc 9e 2a f0    	pushl  0xf02a9edc
f0102c7b:	e8 99 e6 ff ff       	call   f0101319 <page_insert>
	assert(pp1->pp_ref == 1);
f0102c80:	83 c4 20             	add    $0x20,%esp
f0102c83:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102c88:	74 19                	je     f0102ca3 <mem_init+0x1892>
f0102c8a:	68 cd 7c 10 f0       	push   $0xf0107ccd
f0102c8f:	68 db 7a 10 f0       	push   $0xf0107adb
f0102c94:	68 de 04 00 00       	push   $0x4de
f0102c99:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102c9e:	e8 9d d3 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102ca3:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102caa:	01 01 01 
f0102cad:	74 19                	je     f0102cc8 <mem_init+0x18b7>
f0102caf:	68 e0 79 10 f0       	push   $0xf01079e0
f0102cb4:	68 db 7a 10 f0       	push   $0xf0107adb
f0102cb9:	68 df 04 00 00       	push   $0x4df
f0102cbe:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102cc3:	e8 78 d3 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102cc8:	6a 02                	push   $0x2
f0102cca:	68 00 10 00 00       	push   $0x1000
f0102ccf:	56                   	push   %esi
f0102cd0:	ff 35 dc 9e 2a f0    	pushl  0xf02a9edc
f0102cd6:	e8 3e e6 ff ff       	call   f0101319 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102cdb:	83 c4 10             	add    $0x10,%esp
f0102cde:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102ce5:	02 02 02 
f0102ce8:	74 19                	je     f0102d03 <mem_init+0x18f2>
f0102cea:	68 04 7a 10 f0       	push   $0xf0107a04
f0102cef:	68 db 7a 10 f0       	push   $0xf0107adb
f0102cf4:	68 e1 04 00 00       	push   $0x4e1
f0102cf9:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102cfe:	e8 3d d3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102d03:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102d08:	74 19                	je     f0102d23 <mem_init+0x1912>
f0102d0a:	68 ef 7c 10 f0       	push   $0xf0107cef
f0102d0f:	68 db 7a 10 f0       	push   $0xf0107adb
f0102d14:	68 e2 04 00 00       	push   $0x4e2
f0102d19:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102d1e:	e8 1d d3 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102d23:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102d28:	74 19                	je     f0102d43 <mem_init+0x1932>
f0102d2a:	68 59 7d 10 f0       	push   $0xf0107d59
f0102d2f:	68 db 7a 10 f0       	push   $0xf0107adb
f0102d34:	68 e3 04 00 00       	push   $0x4e3
f0102d39:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102d3e:	e8 fd d2 ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102d43:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102d4a:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102d4d:	89 f0                	mov    %esi,%eax
f0102d4f:	2b 05 e0 9e 2a f0    	sub    0xf02a9ee0,%eax
f0102d55:	c1 f8 03             	sar    $0x3,%eax
f0102d58:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d5b:	89 c2                	mov    %eax,%edx
f0102d5d:	c1 ea 0c             	shr    $0xc,%edx
f0102d60:	3b 15 d8 9e 2a f0    	cmp    0xf02a9ed8,%edx
f0102d66:	72 12                	jb     f0102d7a <mem_init+0x1969>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102d68:	50                   	push   %eax
f0102d69:	68 24 6b 10 f0       	push   $0xf0106b24
f0102d6e:	6a 58                	push   $0x58
f0102d70:	68 c1 7a 10 f0       	push   $0xf0107ac1
f0102d75:	e8 c6 d2 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102d7a:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102d81:	03 03 03 
f0102d84:	74 19                	je     f0102d9f <mem_init+0x198e>
f0102d86:	68 28 7a 10 f0       	push   $0xf0107a28
f0102d8b:	68 db 7a 10 f0       	push   $0xf0107adb
f0102d90:	68 e5 04 00 00       	push   $0x4e5
f0102d95:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102d9a:	e8 a1 d2 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102d9f:	83 ec 08             	sub    $0x8,%esp
f0102da2:	68 00 10 00 00       	push   $0x1000
f0102da7:	ff 35 dc 9e 2a f0    	pushl  0xf02a9edc
f0102dad:	e8 21 e5 ff ff       	call   f01012d3 <page_remove>
	assert(pp2->pp_ref == 0);
f0102db2:	83 c4 10             	add    $0x10,%esp
f0102db5:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102dba:	74 19                	je     f0102dd5 <mem_init+0x19c4>
f0102dbc:	68 27 7d 10 f0       	push   $0xf0107d27
f0102dc1:	68 db 7a 10 f0       	push   $0xf0107adb
f0102dc6:	68 e7 04 00 00       	push   $0x4e7
f0102dcb:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102dd0:	e8 6b d2 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102dd5:	8b 0d dc 9e 2a f0    	mov    0xf02a9edc,%ecx
f0102ddb:	8b 11                	mov    (%ecx),%edx
f0102ddd:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102de3:	89 d8                	mov    %ebx,%eax
f0102de5:	2b 05 e0 9e 2a f0    	sub    0xf02a9ee0,%eax
f0102deb:	c1 f8 03             	sar    $0x3,%eax
f0102dee:	c1 e0 0c             	shl    $0xc,%eax
f0102df1:	39 c2                	cmp    %eax,%edx
f0102df3:	74 19                	je     f0102e0e <mem_init+0x19fd>
f0102df5:	68 b0 73 10 f0       	push   $0xf01073b0
f0102dfa:	68 db 7a 10 f0       	push   $0xf0107adb
f0102dff:	68 ea 04 00 00       	push   $0x4ea
f0102e04:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102e09:	e8 32 d2 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102e0e:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102e14:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102e19:	74 19                	je     f0102e34 <mem_init+0x1a23>
f0102e1b:	68 de 7c 10 f0       	push   $0xf0107cde
f0102e20:	68 db 7a 10 f0       	push   $0xf0107adb
f0102e25:	68 ec 04 00 00       	push   $0x4ec
f0102e2a:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102e2f:	e8 0c d2 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102e34:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102e3a:	83 ec 0c             	sub    $0xc,%esp
f0102e3d:	53                   	push   %ebx
f0102e3e:	e8 26 e2 ff ff       	call   f0101069 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102e43:	c7 04 24 54 7a 10 f0 	movl   $0xf0107a54,(%esp)
f0102e4a:	e8 0a 0a 00 00       	call   f0103859 <cprintf>
f0102e4f:	83 c4 10             	add    $0x10,%esp
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102e52:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e55:	5b                   	pop    %ebx
f0102e56:	5e                   	pop    %esi
f0102e57:	5f                   	pop    %edi
f0102e58:	5d                   	pop    %ebp
f0102e59:	c3                   	ret    

f0102e5a <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102e5a:	55                   	push   %ebp
f0102e5b:	89 e5                	mov    %esp,%ebp
f0102e5d:	57                   	push   %edi
f0102e5e:	56                   	push   %esi
f0102e5f:	53                   	push   %ebx
f0102e60:	83 ec 1c             	sub    $0x1c,%esp
f0102e63:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102e66:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// LAB 3: Your code here.

	// step 1 : check below ULIM
  uintptr_t va_beg = (uintptr_t)va;
  uintptr_t va_end = va_beg + len;
f0102e69:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102e6c:	03 75 10             	add    0x10(%ebp),%esi
  if (va_beg >= ULIM || va_end >= ULIM) {
f0102e6f:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102e75:	77 09                	ja     f0102e80 <user_mem_check+0x26>
f0102e77:	81 7d 0c ff ff 7f ef 	cmpl   $0xef7fffff,0xc(%ebp)
f0102e7e:	76 1f                	jbe    f0102e9f <user_mem_check+0x45>
    user_mem_check_addr = (va_beg >= ULIM) ? va_beg : ULIM;
f0102e80:	81 7d 0c 00 00 80 ef 	cmpl   $0xef800000,0xc(%ebp)
f0102e87:	b8 00 00 80 ef       	mov    $0xef800000,%eax
f0102e8c:	0f 43 45 0c          	cmovae 0xc(%ebp),%eax
f0102e90:	a3 60 92 2a f0       	mov    %eax,0xf02a9260
    return -E_FAULT;
f0102e95:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102e9a:	e9 a7 00 00 00       	jmp    f0102f46 <user_mem_check+0xec>
  }

  // step 2 : check present & permission
  uintptr_t va_beg2 = ROUNDDOWN(va_beg, PGSIZE);
f0102e9f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102ea2:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  uintptr_t va_end2 = ROUNDUP(va_end, PGSIZE);
f0102ea8:	81 c6 ff 0f 00 00    	add    $0xfff,%esi
f0102eae:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102eb4:	a1 d8 9e 2a f0       	mov    0xf02a9ed8,%eax
f0102eb9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102ebc:	89 7d 08             	mov    %edi,0x8(%ebp)
  while (va_beg2 < va_end2) {
f0102ebf:	eb 7c                	jmp    f0102f3d <user_mem_check+0xe3>

    // check page table is present ?
    if (!(env->env_pgdir[PDX(va_beg2)] & PTE_P)) {
f0102ec1:	89 d1                	mov    %edx,%ecx
f0102ec3:	c1 e9 16             	shr    $0x16,%ecx
f0102ec6:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ec9:	8b 40 60             	mov    0x60(%eax),%eax
f0102ecc:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0102ecf:	a8 01                	test   $0x1,%al
f0102ed1:	75 14                	jne    f0102ee7 <user_mem_check+0x8d>
      user_mem_check_addr = (va_beg2 > va_beg) ? va_beg2 : va_beg;
f0102ed3:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102ed6:	0f 42 55 0c          	cmovb  0xc(%ebp),%edx
f0102eda:	89 15 60 92 2a f0    	mov    %edx,0xf02a9260
      return -E_FAULT;
f0102ee0:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102ee5:	eb 5f                	jmp    f0102f46 <user_mem_check+0xec>
    }

    // get current page table kernel va
    uint32_t* pt_kva = KADDR(PTE_ADDR(env->env_pgdir[PDX(va_beg2)]));
f0102ee7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102eec:	89 c1                	mov    %eax,%ecx
f0102eee:	c1 e9 0c             	shr    $0xc,%ecx
f0102ef1:	3b 4d e4             	cmp    -0x1c(%ebp),%ecx
f0102ef4:	72 15                	jb     f0102f0b <user_mem_check+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ef6:	50                   	push   %eax
f0102ef7:	68 24 6b 10 f0       	push   $0xf0106b24
f0102efc:	68 14 03 00 00       	push   $0x314
f0102f01:	68 b5 7a 10 f0       	push   $0xf0107ab5
f0102f06:	e8 35 d1 ff ff       	call   f0100040 <_panic>

    // check page is present & permissions
    if (!((pt_kva[PTX(va_beg2)] & perm) == perm)) {
f0102f0b:	89 d1                	mov    %edx,%ecx
f0102f0d:	c1 e9 0c             	shr    $0xc,%ecx
f0102f10:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
f0102f16:	89 df                	mov    %ebx,%edi
f0102f18:	23 bc 88 00 00 00 f0 	and    -0x10000000(%eax,%ecx,4),%edi
f0102f1f:	39 fb                	cmp    %edi,%ebx
f0102f21:	74 14                	je     f0102f37 <user_mem_check+0xdd>
      user_mem_check_addr = (va_beg2 > va_beg) ? va_beg2 : va_beg;
f0102f23:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102f26:	0f 42 55 0c          	cmovb  0xc(%ebp),%edx
f0102f2a:	89 15 60 92 2a f0    	mov    %edx,0xf02a9260
      return -E_FAULT;
f0102f30:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102f35:	eb 0f                	jmp    f0102f46 <user_mem_check+0xec>
    }

    va_beg2 += PGSIZE;
f0102f37:	81 c2 00 10 00 00    	add    $0x1000,%edx
  }

  // step 2 : check present & permission
  uintptr_t va_beg2 = ROUNDDOWN(va_beg, PGSIZE);
  uintptr_t va_end2 = ROUNDUP(va_end, PGSIZE);
  while (va_beg2 < va_end2) {
f0102f3d:	39 f2                	cmp    %esi,%edx
f0102f3f:	72 80                	jb     f0102ec1 <user_mem_check+0x67>
      return -E_FAULT;
    }

    va_beg2 += PGSIZE;
  }
  return 0;
f0102f41:	b8 00 00 00 00       	mov    $0x0,%eax

}
f0102f46:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f49:	5b                   	pop    %ebx
f0102f4a:	5e                   	pop    %esi
f0102f4b:	5f                   	pop    %edi
f0102f4c:	5d                   	pop    %ebp
f0102f4d:	c3                   	ret    

f0102f4e <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102f4e:	55                   	push   %ebp
f0102f4f:	89 e5                	mov    %esp,%ebp
f0102f51:	53                   	push   %ebx
f0102f52:	83 ec 04             	sub    $0x4,%esp
f0102f55:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102f58:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f5b:	83 c8 04             	or     $0x4,%eax
f0102f5e:	50                   	push   %eax
f0102f5f:	ff 75 10             	pushl  0x10(%ebp)
f0102f62:	ff 75 0c             	pushl  0xc(%ebp)
f0102f65:	53                   	push   %ebx
f0102f66:	e8 ef fe ff ff       	call   f0102e5a <user_mem_check>
f0102f6b:	83 c4 10             	add    $0x10,%esp
f0102f6e:	85 c0                	test   %eax,%eax
f0102f70:	79 21                	jns    f0102f93 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102f72:	83 ec 04             	sub    $0x4,%esp
f0102f75:	ff 35 60 92 2a f0    	pushl  0xf02a9260
f0102f7b:	ff 73 48             	pushl  0x48(%ebx)
f0102f7e:	68 80 7a 10 f0       	push   $0xf0107a80
f0102f83:	e8 d1 08 00 00       	call   f0103859 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102f88:	89 1c 24             	mov    %ebx,(%esp)
f0102f8b:	e8 ef 05 00 00       	call   f010357f <env_destroy>
f0102f90:	83 c4 10             	add    $0x10,%esp
	}
}
f0102f93:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102f96:	c9                   	leave  
f0102f97:	c3                   	ret    

f0102f98 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102f98:	55                   	push   %ebp
f0102f99:	89 e5                	mov    %esp,%ebp
f0102f9b:	57                   	push   %edi
f0102f9c:	56                   	push   %esi
f0102f9d:	53                   	push   %ebx
f0102f9e:	83 ec 0c             	sub    $0xc,%esp
f0102fa1:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
f0102fa3:	89 d3                	mov    %edx,%ebx
f0102fa5:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
f0102fab:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102fb2:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	
	while (vaBegin<vaEnd){
f0102fb8:	eb 58                	jmp    f0103012 <region_alloc+0x7a>
		struct PageInfo *p = page_alloc(0);
f0102fba:	83 ec 0c             	sub    $0xc,%esp
f0102fbd:	6a 00                	push   $0x0
f0102fbf:	e8 2f e0 ff ff       	call   f0100ff3 <page_alloc>
		if (p == NULL)
f0102fc4:	83 c4 10             	add    $0x10,%esp
f0102fc7:	85 c0                	test   %eax,%eax
f0102fc9:	75 17                	jne    f0102fe2 <region_alloc+0x4a>
			panic("Page alloc failed!");
f0102fcb:	83 ec 04             	sub    $0x4,%esp
f0102fce:	68 f4 7d 10 f0       	push   $0xf0107df4
f0102fd3:	68 35 01 00 00       	push   $0x135
f0102fd8:	68 07 7e 10 f0       	push   $0xf0107e07
f0102fdd:	e8 5e d0 ff ff       	call   f0100040 <_panic>
		else if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
f0102fe2:	6a 06                	push   $0x6
f0102fe4:	53                   	push   %ebx
f0102fe5:	50                   	push   %eax
f0102fe6:	ff 77 60             	pushl  0x60(%edi)
f0102fe9:	e8 2b e3 ff ff       	call   f0101319 <page_insert>
f0102fee:	83 c4 10             	add    $0x10,%esp
f0102ff1:	85 c0                	test   %eax,%eax
f0102ff3:	74 17                	je     f010300c <region_alloc+0x74>
			panic("Page table couldn't be allocated!!");
f0102ff5:	83 ec 04             	sub    $0x4,%esp
f0102ff8:	68 4c 7e 10 f0       	push   $0xf0107e4c
f0102ffd:	68 37 01 00 00       	push   $0x137
f0103002:	68 07 7e 10 f0       	push   $0xf0107e07
f0103007:	e8 34 d0 ff ff       	call   f0100040 <_panic>
		}
		vaBegin += PGSIZE;
f010300c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
	
	while (vaBegin<vaEnd){
f0103012:	39 f3                	cmp    %esi,%ebx
f0103014:	72 a4                	jb     f0102fba <region_alloc+0x22>
		else if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
			panic("Page table couldn't be allocated!!");
		}
		vaBegin += PGSIZE;
	}
}
f0103016:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103019:	5b                   	pop    %ebx
f010301a:	5e                   	pop    %esi
f010301b:	5f                   	pop    %edi
f010301c:	5d                   	pop    %ebp
f010301d:	c3                   	ret    

f010301e <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f010301e:	55                   	push   %ebp
f010301f:	89 e5                	mov    %esp,%ebp
f0103021:	56                   	push   %esi
f0103022:	53                   	push   %ebx
f0103023:	8b 45 08             	mov    0x8(%ebp),%eax
f0103026:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0103029:	85 c0                	test   %eax,%eax
f010302b:	75 1a                	jne    f0103047 <envid2env+0x29>
		*env_store = curenv;
f010302d:	e8 45 2a 00 00       	call   f0105a77 <cpunum>
f0103032:	6b c0 74             	imul   $0x74,%eax,%eax
f0103035:	8b 80 48 a0 2a f0    	mov    -0xfd55fb8(%eax),%eax
f010303b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010303e:	89 01                	mov    %eax,(%ecx)
		return 0;
f0103040:	b8 00 00 00 00       	mov    $0x0,%eax
f0103045:	eb 70                	jmp    f01030b7 <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0103047:	89 c3                	mov    %eax,%ebx
f0103049:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f010304f:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0103052:	03 1d 6c 92 2a f0    	add    0xf02a926c,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103058:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f010305c:	74 05                	je     f0103063 <envid2env+0x45>
f010305e:	39 43 48             	cmp    %eax,0x48(%ebx)
f0103061:	74 10                	je     f0103073 <envid2env+0x55>
		*env_store = 0;
f0103063:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103066:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010306c:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103071:	eb 44                	jmp    f01030b7 <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103073:	84 d2                	test   %dl,%dl
f0103075:	74 36                	je     f01030ad <envid2env+0x8f>
f0103077:	e8 fb 29 00 00       	call   f0105a77 <cpunum>
f010307c:	6b c0 74             	imul   $0x74,%eax,%eax
f010307f:	39 98 48 a0 2a f0    	cmp    %ebx,-0xfd55fb8(%eax)
f0103085:	74 26                	je     f01030ad <envid2env+0x8f>
f0103087:	8b 73 4c             	mov    0x4c(%ebx),%esi
f010308a:	e8 e8 29 00 00       	call   f0105a77 <cpunum>
f010308f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103092:	8b 80 48 a0 2a f0    	mov    -0xfd55fb8(%eax),%eax
f0103098:	3b 70 48             	cmp    0x48(%eax),%esi
f010309b:	74 10                	je     f01030ad <envid2env+0x8f>
		*env_store = 0;
f010309d:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030a0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01030a6:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01030ab:	eb 0a                	jmp    f01030b7 <envid2env+0x99>
	}

	*env_store = e;
f01030ad:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030b0:	89 18                	mov    %ebx,(%eax)
	return 0;
f01030b2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01030b7:	5b                   	pop    %ebx
f01030b8:	5e                   	pop    %esi
f01030b9:	5d                   	pop    %ebp
f01030ba:	c3                   	ret    

f01030bb <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01030bb:	55                   	push   %ebp
f01030bc:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f01030be:	b8 40 43 12 f0       	mov    $0xf0124340,%eax
f01030c3:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f01030c6:	b8 23 00 00 00       	mov    $0x23,%eax
f01030cb:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f01030cd:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f01030cf:	b0 10                	mov    $0x10,%al
f01030d1:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f01030d3:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01030d5:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f01030d7:	ea de 30 10 f0 08 00 	ljmp   $0x8,$0xf01030de
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f01030de:	b0 00                	mov    $0x0,%al
f01030e0:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01030e3:	5d                   	pop    %ebp
f01030e4:	c3                   	ret    

f01030e5 <env_init>:
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
f01030e5:	8b 0d 6c 92 2a f0    	mov    0xf02a926c,%ecx
f01030eb:	8b 15 70 92 2a f0    	mov    0xf02a9270,%edx
f01030f1:	89 c8                	mov    %ecx,%eax
f01030f3:	81 c1 00 f0 01 00    	add    $0x1f000,%ecx
f01030f9:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = NULL;
f0103100:	c7 40 44 00 00 00 00 	movl   $0x0,0x44(%eax)

		if (!env_free_list){		
f0103107:	85 d2                	test   %edx,%edx
f0103109:	74 05                	je     f0103110 <env_init+0x2b>
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
		}
		else{
		envs[i-1].env_link = &envs[i];
f010310b:	89 40 c8             	mov    %eax,-0x38(%eax)
f010310e:	eb 02                	jmp    f0103112 <env_init+0x2d>
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
		envs[i].env_link = NULL;

		if (!env_free_list){		
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
f0103110:	89 c2                	mov    %eax,%edx
f0103112:	83 c0 7c             	add    $0x7c,%eax
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
f0103115:	39 c8                	cmp    %ecx,%eax
f0103117:	75 e0                	jne    f01030f9 <env_init+0x14>
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0103119:	55                   	push   %ebp
f010311a:	89 e5                	mov    %esp,%ebp
f010311c:	89 15 70 92 2a f0    	mov    %edx,0xf02a9270
		}	//Previous env is linked to this current env
	}
	

	// Per-CPU part of the initialization
	env_init_percpu();
f0103122:	e8 94 ff ff ff       	call   f01030bb <env_init_percpu>
}
f0103127:	5d                   	pop    %ebp
f0103128:	c3                   	ret    

f0103129 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0103129:	55                   	push   %ebp
f010312a:	89 e5                	mov    %esp,%ebp
f010312c:	53                   	push   %ebx
f010312d:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0103130:	8b 1d 70 92 2a f0    	mov    0xf02a9270,%ebx
f0103136:	85 db                	test   %ebx,%ebx
f0103138:	0f 84 34 01 00 00    	je     f0103272 <env_alloc+0x149>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f010313e:	83 ec 0c             	sub    $0xc,%esp
f0103141:	6a 01                	push   $0x1
f0103143:	e8 ab de ff ff       	call   f0100ff3 <page_alloc>
f0103148:	83 c4 10             	add    $0x10,%esp
f010314b:	85 c0                	test   %eax,%eax
f010314d:	0f 84 26 01 00 00    	je     f0103279 <env_alloc+0x150>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f0103153:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0103158:	2b 05 e0 9e 2a f0    	sub    0xf02a9ee0,%eax
f010315e:	c1 f8 03             	sar    $0x3,%eax
f0103161:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103164:	89 c2                	mov    %eax,%edx
f0103166:	c1 ea 0c             	shr    $0xc,%edx
f0103169:	3b 15 d8 9e 2a f0    	cmp    0xf02a9ed8,%edx
f010316f:	72 12                	jb     f0103183 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103171:	50                   	push   %eax
f0103172:	68 24 6b 10 f0       	push   $0xf0106b24
f0103177:	6a 58                	push   $0x58
f0103179:	68 c1 7a 10 f0       	push   $0xf0107ac1
f010317e:	e8 bd ce ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0103183:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103188:	89 43 60             	mov    %eax,0x60(%ebx)
	e->env_pgdir = (pde_t*)page2kva(p);
f010318b:	b8 00 00 00 00       	mov    $0x0,%eax

	for (i = 0; i < NPDENTRIES; ++i) {
		e->env_pgdir[i] = kern_pgdir[i];  //Mapping all 1024 entries of the kernel
f0103190:	8b 15 dc 9e 2a f0    	mov    0xf02a9edc,%edx
f0103196:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f0103199:	8b 53 60             	mov    0x60(%ebx),%edx
f010319c:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f010319f:	83 c0 04             	add    $0x4,%eax

	// LAB 3: Your code here.
	p->pp_ref++;
	e->env_pgdir = (pde_t*)page2kva(p);

	for (i = 0; i < NPDENTRIES; ++i) {
f01031a2:	3d 00 10 00 00       	cmp    $0x1000,%eax
f01031a7:	75 e7                	jne    f0103190 <env_alloc+0x67>
						 //pgdir to the environment pgdir
	}
	
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01031a9:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01031ac:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031b1:	77 15                	ja     f01031c8 <env_alloc+0x9f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031b3:	50                   	push   %eax
f01031b4:	68 48 6b 10 f0       	push   $0xf0106b48
f01031b9:	68 d0 00 00 00       	push   $0xd0
f01031be:	68 07 7e 10 f0       	push   $0xf0107e07
f01031c3:	e8 78 ce ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01031c8:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01031ce:	83 ca 05             	or     $0x5,%edx
f01031d1:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01031d7:	8b 43 48             	mov    0x48(%ebx),%eax
f01031da:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01031df:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01031e4:	ba 00 10 00 00       	mov    $0x1000,%edx
f01031e9:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01031ec:	89 da                	mov    %ebx,%edx
f01031ee:	2b 15 6c 92 2a f0    	sub    0xf02a926c,%edx
f01031f4:	c1 fa 02             	sar    $0x2,%edx
f01031f7:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f01031fd:	09 d0                	or     %edx,%eax
f01031ff:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0103202:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103205:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0103208:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f010320f:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0103216:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f010321d:	83 ec 04             	sub    $0x4,%esp
f0103220:	6a 44                	push   $0x44
f0103222:	6a 00                	push   $0x0
f0103224:	53                   	push   %ebx
f0103225:	e8 28 22 00 00       	call   f0105452 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f010322a:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103230:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103236:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f010323c:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0103243:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.
	e->env_tf.tf_eflags |= FL_IF;  //Modification for exercise 13
f0103249:	81 4b 38 00 02 00 00 	orl    $0x200,0x38(%ebx)

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f0103250:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f0103257:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f010325b:	8b 43 44             	mov    0x44(%ebx),%eax
f010325e:	a3 70 92 2a f0       	mov    %eax,0xf02a9270
	*newenv_store = e;
f0103263:	8b 45 08             	mov    0x8(%ebp),%eax
f0103266:	89 18                	mov    %ebx,(%eax)

	// cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
f0103268:	83 c4 10             	add    $0x10,%esp
f010326b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103270:	eb 0c                	jmp    f010327e <env_alloc+0x155>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103272:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103277:	eb 05                	jmp    f010327e <env_alloc+0x155>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0103279:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	// cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f010327e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103281:	c9                   	leave  
f0103282:	c3                   	ret    

f0103283 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103283:	55                   	push   %ebp
f0103284:	89 e5                	mov    %esp,%ebp
f0103286:	57                   	push   %edi
f0103287:	56                   	push   %esi
f0103288:	53                   	push   %ebx
f0103289:	83 ec 34             	sub    $0x34,%esp
f010328c:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	int r;
	struct Env *env;
	r = env_alloc( &env, 0);
f010328f:	6a 00                	push   $0x0
f0103291:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103294:	50                   	push   %eax
f0103295:	e8 8f fe ff ff       	call   f0103129 <env_alloc>
	if (r){
f010329a:	83 c4 10             	add    $0x10,%esp
f010329d:	85 c0                	test   %eax,%eax
f010329f:	74 15                	je     f01032b6 <env_create+0x33>
	panic("env_alloc: %e", r);
f01032a1:	50                   	push   %eax
f01032a2:	68 12 7e 10 f0       	push   $0xf0107e12
f01032a7:	68 b2 01 00 00       	push   $0x1b2
f01032ac:	68 07 7e 10 f0       	push   $0xf0107e07
f01032b1:	e8 8a cd ff ff       	call   f0100040 <_panic>
	}
	
	load_icode(env,binary);
f01032b6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01032b9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Get the beginning and end of program header table
	//Details of struct proghdr are in /lab/inc/elf.h

	// is this a valid ELF?
	
	if (((struct Elf*)binary)->e_magic != ELF_MAGIC)
f01032bc:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f01032c2:	74 17                	je     f01032db <env_create+0x58>
	{
		panic ("Not a valid ELF binary image");
f01032c4:	83 ec 04             	sub    $0x4,%esp
f01032c7:	68 20 7e 10 f0       	push   $0xf0107e20
f01032cc:	68 81 01 00 00       	push   $0x181
f01032d1:	68 07 7e 10 f0       	push   $0xf0107e07
f01032d6:	e8 65 cd ff ff       	call   f0100040 <_panic>
	}

	struct Proghdr *ph =(struct Proghdr *)(binary + ((struct Elf*)binary)->e_phoff); //phoff is the offset
f01032db:	89 fb                	mov    %edi,%ebx
f01032dd:	03 5f 1c             	add    0x1c(%edi),%ebx
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
f01032e0:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f01032e4:	c1 e6 05             	shl    $0x5,%esi
f01032e7:	01 de                	add    %ebx,%esi
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));
f01032e9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01032ec:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01032ef:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01032f4:	77 15                	ja     f010330b <env_create+0x88>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01032f6:	50                   	push   %eax
f01032f7:	68 48 6b 10 f0       	push   $0xf0106b48
f01032fc:	68 88 01 00 00       	push   $0x188
f0103301:	68 07 7e 10 f0       	push   $0xf0107e07
f0103306:	e8 35 cd ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010330b:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0103310:	0f 22 d8             	mov    %eax,%cr3
f0103313:	eb 60                	jmp    f0103375 <env_create+0xf2>

	for (;ph<phEnd;++ph){
		if (ph->p_type == ELF_PROG_LOAD){	//Check whether the type is ELF_PROG_LOAD
f0103315:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103318:	75 58                	jne    f0103372 <env_create+0xef>
		
		if(ph->p_memsz < ph->p_filesz){
f010331a:	8b 4b 14             	mov    0x14(%ebx),%ecx
f010331d:	3b 4b 10             	cmp    0x10(%ebx),%ecx
f0103320:	73 17                	jae    f0103339 <env_create+0xb6>
		panic ("Memory size is smaller than file size!!");
f0103322:	83 ec 04             	sub    $0x4,%esp
f0103325:	68 70 7e 10 f0       	push   $0xf0107e70
f010332a:	68 8e 01 00 00       	push   $0x18e
f010332f:	68 07 7e 10 f0       	push   $0xf0107e07
f0103334:	e8 07 cd ff ff       	call   f0100040 <_panic>
		}
		region_alloc(e, (void *)ph->p_va, ph->p_memsz);  //Allocate region per segment
f0103339:	8b 53 08             	mov    0x8(%ebx),%edx
f010333c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010333f:	e8 54 fc ff ff       	call   f0102f98 <region_alloc>
	

		memcpy((void*)ph->p_va, (void*)(binary + ph->p_offset), ph->p_filesz); //Load Binary into memory
f0103344:	83 ec 04             	sub    $0x4,%esp
f0103347:	ff 73 10             	pushl  0x10(%ebx)
f010334a:	89 f8                	mov    %edi,%eax
f010334c:	03 43 04             	add    0x4(%ebx),%eax
f010334f:	50                   	push   %eax
f0103350:	ff 73 08             	pushl  0x8(%ebx)
f0103353:	e8 af 21 00 00       	call   f0105507 <memcpy>

		memset((void*)(ph->p_va + ph->p_filesz),0,ph->p_memsz-ph->p_filesz);  //Clear the rest of the memory, i.e the bss segment
f0103358:	8b 43 10             	mov    0x10(%ebx),%eax
f010335b:	83 c4 0c             	add    $0xc,%esp
f010335e:	8b 53 14             	mov    0x14(%ebx),%edx
f0103361:	29 c2                	sub    %eax,%edx
f0103363:	52                   	push   %edx
f0103364:	6a 00                	push   $0x0
f0103366:	03 43 08             	add    0x8(%ebx),%eax
f0103369:	50                   	push   %eax
f010336a:	e8 e3 20 00 00       	call   f0105452 <memset>
f010336f:	83 c4 10             	add    $0x10,%esp
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));

	for (;ph<phEnd;++ph){
f0103372:	83 c3 20             	add    $0x20,%ebx
f0103375:	39 de                	cmp    %ebx,%esi
f0103377:	77 9c                	ja     f0103315 <env_create+0x92>
		}
		else{
			continue;
		}
	}
	lcr3(PADDR(kern_pgdir));   //Switch back to Kernel page directory
f0103379:	a1 dc 9e 2a f0       	mov    0xf02a9edc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010337e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103383:	77 15                	ja     f010339a <env_create+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103385:	50                   	push   %eax
f0103386:	68 48 6b 10 f0       	push   $0xf0106b48
f010338b:	68 9b 01 00 00       	push   $0x19b
f0103390:	68 07 7e 10 f0       	push   $0xf0107e07
f0103395:	e8 a6 cc ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010339a:	05 00 00 00 10       	add    $0x10000000,%eax
f010339f:	0f 22 d8             	mov    %eax,%cr3
	
	e->env_tf.tf_eip = ((struct Elf*)binary)->e_entry;   //Define the entry point of the env from the ELF binary entry point
f01033a2:	8b 47 18             	mov    0x18(%edi),%eax
f01033a5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01033a8:	89 47 30             	mov    %eax,0x30(%edi)

	region_alloc(e,(void *)USTACKTOP - PGSIZE, PGSIZE);
f01033ab:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01033b0:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01033b5:	89 f8                	mov    %edi,%eax
f01033b7:	e8 dc fb ff ff       	call   f0102f98 <region_alloc>
	if (r){
	panic("env_alloc: %e", r);
	}
	
	load_icode(env,binary);
	env->env_type = type;
f01033bc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01033bf:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01033c2:	89 78 50             	mov    %edi,0x50(%eax)

	// If this is the file server (type == ENV_TYPE_FS) give it I/O privileges.
	// LAB 5: Your code here.
	//IOPL = IO privelege level, for this to be user accessible, the IOPL<=CPL, Since CPL =3 we set IOPL=3
	if (type == ENV_TYPE_FS) {
f01033c5:	83 ff 01             	cmp    $0x1,%edi
f01033c8:	75 07                	jne    f01033d1 <env_create+0x14e>
		env->env_tf.tf_eflags |= FL_IOPL_3; //FL_IOPL_3 in inc/mmu.h
f01033ca:	81 48 38 00 30 00 00 	orl    $0x3000,0x38(%eax)
	}

}
f01033d1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01033d4:	5b                   	pop    %ebx
f01033d5:	5e                   	pop    %esi
f01033d6:	5f                   	pop    %edi
f01033d7:	5d                   	pop    %ebp
f01033d8:	c3                   	ret    

f01033d9 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01033d9:	55                   	push   %ebp
f01033da:	89 e5                	mov    %esp,%ebp
f01033dc:	57                   	push   %edi
f01033dd:	56                   	push   %esi
f01033de:	53                   	push   %ebx
f01033df:	83 ec 1c             	sub    $0x1c,%esp
f01033e2:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01033e5:	e8 8d 26 00 00       	call   f0105a77 <cpunum>
f01033ea:	6b c0 74             	imul   $0x74,%eax,%eax
f01033ed:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01033f4:	39 b8 48 a0 2a f0    	cmp    %edi,-0xfd55fb8(%eax)
f01033fa:	75 30                	jne    f010342c <env_free+0x53>
		lcr3(PADDR(kern_pgdir));
f01033fc:	a1 dc 9e 2a f0       	mov    0xf02a9edc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103401:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103406:	77 15                	ja     f010341d <env_free+0x44>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103408:	50                   	push   %eax
f0103409:	68 48 6b 10 f0       	push   $0xf0106b48
f010340e:	68 d0 01 00 00       	push   $0x1d0
f0103413:	68 07 7e 10 f0       	push   $0xf0107e07
f0103418:	e8 23 cc ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010341d:	05 00 00 00 10       	add    $0x10000000,%eax
f0103422:	0f 22 d8             	mov    %eax,%cr3
f0103425:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f010342c:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010342f:	89 d0                	mov    %edx,%eax
f0103431:	c1 e0 02             	shl    $0x2,%eax
f0103434:	89 45 d8             	mov    %eax,-0x28(%ebp)
	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103437:	8b 47 60             	mov    0x60(%edi),%eax
f010343a:	8b 34 90             	mov    (%eax,%edx,4),%esi
f010343d:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103443:	0f 84 a8 00 00 00    	je     f01034f1 <env_free+0x118>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103449:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010344f:	89 f0                	mov    %esi,%eax
f0103451:	c1 e8 0c             	shr    $0xc,%eax
f0103454:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103457:	3b 05 d8 9e 2a f0    	cmp    0xf02a9ed8,%eax
f010345d:	72 15                	jb     f0103474 <env_free+0x9b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010345f:	56                   	push   %esi
f0103460:	68 24 6b 10 f0       	push   $0xf0106b24
f0103465:	68 df 01 00 00       	push   $0x1df
f010346a:	68 07 7e 10 f0       	push   $0xf0107e07
f010346f:	e8 cc cb ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103474:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103477:	c1 e0 16             	shl    $0x16,%eax
f010347a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010347d:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103482:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103489:	01 
f010348a:	74 17                	je     f01034a3 <env_free+0xca>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010348c:	83 ec 08             	sub    $0x8,%esp
f010348f:	89 d8                	mov    %ebx,%eax
f0103491:	c1 e0 0c             	shl    $0xc,%eax
f0103494:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103497:	50                   	push   %eax
f0103498:	ff 77 60             	pushl  0x60(%edi)
f010349b:	e8 33 de ff ff       	call   f01012d3 <page_remove>
f01034a0:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01034a3:	83 c3 01             	add    $0x1,%ebx
f01034a6:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01034ac:	75 d4                	jne    f0103482 <env_free+0xa9>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01034ae:	8b 47 60             	mov    0x60(%edi),%eax
f01034b1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01034b4:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01034bb:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01034be:	3b 05 d8 9e 2a f0    	cmp    0xf02a9ed8,%eax
f01034c4:	72 14                	jb     f01034da <env_free+0x101>
		panic("pa2page called with invalid pa");
f01034c6:	83 ec 04             	sub    $0x4,%esp
f01034c9:	68 98 7e 10 f0       	push   $0xf0107e98
f01034ce:	6a 51                	push   $0x51
f01034d0:	68 c1 7a 10 f0       	push   $0xf0107ac1
f01034d5:	e8 66 cb ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f01034da:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f01034dd:	a1 e0 9e 2a f0       	mov    0xf02a9ee0,%eax
f01034e2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01034e5:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01034e8:	50                   	push   %eax
f01034e9:	e8 cc db ff ff       	call   f01010ba <page_decref>
f01034ee:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	// cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01034f1:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f01034f5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01034f8:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01034fd:	0f 85 29 ff ff ff    	jne    f010342c <env_free+0x53>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103503:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103506:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010350b:	77 15                	ja     f0103522 <env_free+0x149>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010350d:	50                   	push   %eax
f010350e:	68 48 6b 10 f0       	push   $0xf0106b48
f0103513:	68 ed 01 00 00       	push   $0x1ed
f0103518:	68 07 7e 10 f0       	push   $0xf0107e07
f010351d:	e8 1e cb ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f0103522:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103529:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010352e:	c1 e8 0c             	shr    $0xc,%eax
f0103531:	3b 05 d8 9e 2a f0    	cmp    0xf02a9ed8,%eax
f0103537:	72 14                	jb     f010354d <env_free+0x174>
		panic("pa2page called with invalid pa");
f0103539:	83 ec 04             	sub    $0x4,%esp
f010353c:	68 98 7e 10 f0       	push   $0xf0107e98
f0103541:	6a 51                	push   $0x51
f0103543:	68 c1 7a 10 f0       	push   $0xf0107ac1
f0103548:	e8 f3 ca ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f010354d:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103550:	8b 15 e0 9e 2a f0    	mov    0xf02a9ee0,%edx
f0103556:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0103559:	50                   	push   %eax
f010355a:	e8 5b db ff ff       	call   f01010ba <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f010355f:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103566:	a1 70 92 2a f0       	mov    0xf02a9270,%eax
f010356b:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f010356e:	89 3d 70 92 2a f0    	mov    %edi,0xf02a9270
f0103574:	83 c4 10             	add    $0x10,%esp
}
f0103577:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010357a:	5b                   	pop    %ebx
f010357b:	5e                   	pop    %esi
f010357c:	5f                   	pop    %edi
f010357d:	5d                   	pop    %ebp
f010357e:	c3                   	ret    

f010357f <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f010357f:	55                   	push   %ebp
f0103580:	89 e5                	mov    %esp,%ebp
f0103582:	53                   	push   %ebx
f0103583:	83 ec 04             	sub    $0x4,%esp
f0103586:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f0103589:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f010358d:	75 19                	jne    f01035a8 <env_destroy+0x29>
f010358f:	e8 e3 24 00 00       	call   f0105a77 <cpunum>
f0103594:	6b c0 74             	imul   $0x74,%eax,%eax
f0103597:	39 98 48 a0 2a f0    	cmp    %ebx,-0xfd55fb8(%eax)
f010359d:	74 09                	je     f01035a8 <env_destroy+0x29>
		e->env_status = ENV_DYING;
f010359f:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f01035a6:	eb 33                	jmp    f01035db <env_destroy+0x5c>
	}

	env_free(e);
f01035a8:	83 ec 0c             	sub    $0xc,%esp
f01035ab:	53                   	push   %ebx
f01035ac:	e8 28 fe ff ff       	call   f01033d9 <env_free>

	if (curenv == e) {
f01035b1:	e8 c1 24 00 00       	call   f0105a77 <cpunum>
f01035b6:	6b c0 74             	imul   $0x74,%eax,%eax
f01035b9:	83 c4 10             	add    $0x10,%esp
f01035bc:	39 98 48 a0 2a f0    	cmp    %ebx,-0xfd55fb8(%eax)
f01035c2:	75 17                	jne    f01035db <env_destroy+0x5c>
		curenv = NULL;
f01035c4:	e8 ae 24 00 00       	call   f0105a77 <cpunum>
f01035c9:	6b c0 74             	imul   $0x74,%eax,%eax
f01035cc:	c7 80 48 a0 2a f0 00 	movl   $0x0,-0xfd55fb8(%eax)
f01035d3:	00 00 00 
		sched_yield();
f01035d6:	e8 39 0c 00 00       	call   f0104214 <sched_yield>
	}
}
f01035db:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01035de:	c9                   	leave  
f01035df:	c3                   	ret    

f01035e0 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01035e0:	55                   	push   %ebp
f01035e1:	89 e5                	mov    %esp,%ebp
f01035e3:	53                   	push   %ebx
f01035e4:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f01035e7:	e8 8b 24 00 00       	call   f0105a77 <cpunum>
f01035ec:	6b c0 74             	imul   $0x74,%eax,%eax
f01035ef:	8b 98 48 a0 2a f0    	mov    -0xfd55fb8(%eax),%ebx
f01035f5:	e8 7d 24 00 00       	call   f0105a77 <cpunum>
f01035fa:	89 43 5c             	mov    %eax,0x5c(%ebx)

	__asm __volatile("movl %0,%%esp\n"
f01035fd:	8b 65 08             	mov    0x8(%ebp),%esp
f0103600:	61                   	popa   
f0103601:	07                   	pop    %es
f0103602:	1f                   	pop    %ds
f0103603:	83 c4 08             	add    $0x8,%esp
f0103606:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103607:	83 ec 04             	sub    $0x4,%esp
f010360a:	68 3d 7e 10 f0       	push   $0xf0107e3d
f010360f:	68 23 02 00 00       	push   $0x223
f0103614:	68 07 7e 10 f0       	push   $0xf0107e07
f0103619:	e8 22 ca ff ff       	call   f0100040 <_panic>

f010361e <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f010361e:	55                   	push   %ebp
f010361f:	89 e5                	mov    %esp,%ebp
f0103621:	53                   	push   %ebx
f0103622:	83 ec 04             	sub    $0x4,%esp
f0103625:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	//check if this is the first call to env_run
	if (curenv == NULL){
f0103628:	e8 4a 24 00 00       	call   f0105a77 <cpunum>
f010362d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103630:	83 b8 48 a0 2a f0 00 	cmpl   $0x0,-0xfd55fb8(%eax)
f0103637:	75 10                	jne    f0103649 <env_run+0x2b>
	curenv = e;
f0103639:	e8 39 24 00 00       	call   f0105a77 <cpunum>
f010363e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103641:	89 98 48 a0 2a f0    	mov    %ebx,-0xfd55fb8(%eax)
f0103647:	eb 29                	jmp    f0103672 <env_run+0x54>
	}
	
	//If curenv state is running mode , set it to runnable 
	else if (curenv->env_status == ENV_RUNNING){
f0103649:	e8 29 24 00 00       	call   f0105a77 <cpunum>
f010364e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103651:	8b 80 48 a0 2a f0    	mov    -0xfd55fb8(%eax),%eax
f0103657:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010365b:	75 15                	jne    f0103672 <env_run+0x54>
	 curenv->env_status = ENV_RUNNABLE;
f010365d:	e8 15 24 00 00       	call   f0105a77 <cpunum>
f0103662:	6b c0 74             	imul   $0x74,%eax,%eax
f0103665:	8b 80 48 a0 2a f0    	mov    -0xfd55fb8(%eax),%eax
f010366b:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	curenv = e;	//Set the current environment to the new env
f0103672:	e8 00 24 00 00       	call   f0105a77 <cpunum>
f0103677:	6b c0 74             	imul   $0x74,%eax,%eax
f010367a:	89 98 48 a0 2a f0    	mov    %ebx,-0xfd55fb8(%eax)
	curenv->env_status = ENV_RUNNING; //Set it to running state
f0103680:	e8 f2 23 00 00       	call   f0105a77 <cpunum>
f0103685:	6b c0 74             	imul   $0x74,%eax,%eax
f0103688:	8b 80 48 a0 2a f0    	mov    -0xfd55fb8(%eax),%eax
f010368e:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;	// Increment the env_runs counter
f0103695:	e8 dd 23 00 00       	call   f0105a77 <cpunum>
f010369a:	6b c0 74             	imul   $0x74,%eax,%eax
f010369d:	8b 80 48 a0 2a f0    	mov    -0xfd55fb8(%eax),%eax
f01036a3:	83 40 58 01          	addl   $0x1,0x58(%eax)
	
	lcr3(PADDR(e->env_pgdir));	//Use lcr3 to switch to the env directory
f01036a7:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01036aa:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01036af:	77 15                	ja     f01036c6 <env_run+0xa8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01036b1:	50                   	push   %eax
f01036b2:	68 48 6b 10 f0       	push   $0xf0106b48
f01036b7:	68 4f 02 00 00       	push   $0x24f
f01036bc:	68 07 7e 10 f0       	push   $0xf0107e07
f01036c1:	e8 7a c9 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01036c6:	05 00 00 00 10       	add    $0x10000000,%eax
f01036cb:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01036ce:	83 ec 0c             	sub    $0xc,%esp
f01036d1:	68 c0 44 12 f0       	push   $0xf01244c0
f01036d6:	e8 a4 26 00 00       	call   f0105d7f <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01036db:	f3 90                	pause  
	unlock_kernel();
	env_pop_tf(&e->env_tf);
f01036dd:	89 1c 24             	mov    %ebx,(%esp)
f01036e0:	e8 fb fe ff ff       	call   f01035e0 <env_pop_tf>

f01036e5 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01036e5:	55                   	push   %ebp
f01036e6:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01036e8:	ba 70 00 00 00       	mov    $0x70,%edx
f01036ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01036f0:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01036f1:	b2 71                	mov    $0x71,%dl
f01036f3:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01036f4:	0f b6 c0             	movzbl %al,%eax
}
f01036f7:	5d                   	pop    %ebp
f01036f8:	c3                   	ret    

f01036f9 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
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
f0103705:	b2 71                	mov    $0x71,%dl
f0103707:	8b 45 0c             	mov    0xc(%ebp),%eax
f010370a:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010370b:	5d                   	pop    %ebp
f010370c:	c3                   	ret    

f010370d <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f010370d:	55                   	push   %ebp
f010370e:	89 e5                	mov    %esp,%ebp
f0103710:	56                   	push   %esi
f0103711:	53                   	push   %ebx
f0103712:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103715:	66 a3 e8 43 12 f0    	mov    %ax,0xf01243e8
	if (!didinit)
f010371b:	80 3d 74 92 2a f0 00 	cmpb   $0x0,0xf02a9274
f0103722:	74 57                	je     f010377b <irq_setmask_8259A+0x6e>
f0103724:	89 c6                	mov    %eax,%esi
f0103726:	ba 21 00 00 00       	mov    $0x21,%edx
f010372b:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
f010372c:	66 c1 e8 08          	shr    $0x8,%ax
f0103730:	b2 a1                	mov    $0xa1,%dl
f0103732:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f0103733:	83 ec 0c             	sub    $0xc,%esp
f0103736:	68 b7 7e 10 f0       	push   $0xf0107eb7
f010373b:	e8 19 01 00 00       	call   f0103859 <cprintf>
f0103740:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f0103743:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103748:	0f b7 f6             	movzwl %si,%esi
f010374b:	f7 d6                	not    %esi
f010374d:	0f a3 de             	bt     %ebx,%esi
f0103750:	73 11                	jae    f0103763 <irq_setmask_8259A+0x56>
			cprintf(" %d", i);
f0103752:	83 ec 08             	sub    $0x8,%esp
f0103755:	53                   	push   %ebx
f0103756:	68 df 83 10 f0       	push   $0xf01083df
f010375b:	e8 f9 00 00 00       	call   f0103859 <cprintf>
f0103760:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f0103763:	83 c3 01             	add    $0x1,%ebx
f0103766:	83 fb 10             	cmp    $0x10,%ebx
f0103769:	75 e2                	jne    f010374d <irq_setmask_8259A+0x40>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f010376b:	83 ec 0c             	sub    $0xc,%esp
f010376e:	68 2e 83 10 f0       	push   $0xf010832e
f0103773:	e8 e1 00 00 00       	call   f0103859 <cprintf>
f0103778:	83 c4 10             	add    $0x10,%esp
}
f010377b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010377e:	5b                   	pop    %ebx
f010377f:	5e                   	pop    %esi
f0103780:	5d                   	pop    %ebp
f0103781:	c3                   	ret    

f0103782 <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f0103782:	c6 05 74 92 2a f0 01 	movb   $0x1,0xf02a9274
f0103789:	ba 21 00 00 00       	mov    $0x21,%edx
f010378e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103793:	ee                   	out    %al,(%dx)
f0103794:	b2 a1                	mov    $0xa1,%dl
f0103796:	ee                   	out    %al,(%dx)
f0103797:	b2 20                	mov    $0x20,%dl
f0103799:	b8 11 00 00 00       	mov    $0x11,%eax
f010379e:	ee                   	out    %al,(%dx)
f010379f:	b2 21                	mov    $0x21,%dl
f01037a1:	b8 20 00 00 00       	mov    $0x20,%eax
f01037a6:	ee                   	out    %al,(%dx)
f01037a7:	b8 04 00 00 00       	mov    $0x4,%eax
f01037ac:	ee                   	out    %al,(%dx)
f01037ad:	b8 03 00 00 00       	mov    $0x3,%eax
f01037b2:	ee                   	out    %al,(%dx)
f01037b3:	b2 a0                	mov    $0xa0,%dl
f01037b5:	b8 11 00 00 00       	mov    $0x11,%eax
f01037ba:	ee                   	out    %al,(%dx)
f01037bb:	b2 a1                	mov    $0xa1,%dl
f01037bd:	b8 28 00 00 00       	mov    $0x28,%eax
f01037c2:	ee                   	out    %al,(%dx)
f01037c3:	b8 02 00 00 00       	mov    $0x2,%eax
f01037c8:	ee                   	out    %al,(%dx)
f01037c9:	b8 01 00 00 00       	mov    $0x1,%eax
f01037ce:	ee                   	out    %al,(%dx)
f01037cf:	b2 20                	mov    $0x20,%dl
f01037d1:	b8 68 00 00 00       	mov    $0x68,%eax
f01037d6:	ee                   	out    %al,(%dx)
f01037d7:	b8 0a 00 00 00       	mov    $0xa,%eax
f01037dc:	ee                   	out    %al,(%dx)
f01037dd:	b2 a0                	mov    $0xa0,%dl
f01037df:	b8 68 00 00 00       	mov    $0x68,%eax
f01037e4:	ee                   	out    %al,(%dx)
f01037e5:	b8 0a 00 00 00       	mov    $0xa,%eax
f01037ea:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f01037eb:	0f b7 05 e8 43 12 f0 	movzwl 0xf01243e8,%eax
f01037f2:	66 83 f8 ff          	cmp    $0xffff,%ax
f01037f6:	74 13                	je     f010380b <pic_init+0x89>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f01037f8:	55                   	push   %ebp
f01037f9:	89 e5                	mov    %esp,%ebp
f01037fb:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f01037fe:	0f b7 c0             	movzwl %ax,%eax
f0103801:	50                   	push   %eax
f0103802:	e8 06 ff ff ff       	call   f010370d <irq_setmask_8259A>
f0103807:	83 c4 10             	add    $0x10,%esp
}
f010380a:	c9                   	leave  
f010380b:	f3 c3                	repz ret 

f010380d <irq_eoi>:
	cprintf("\n");
}

void
irq_eoi(void)
{
f010380d:	55                   	push   %ebp
f010380e:	89 e5                	mov    %esp,%ebp
f0103810:	ba 20 00 00 00       	mov    $0x20,%edx
f0103815:	b8 20 00 00 00       	mov    $0x20,%eax
f010381a:	ee                   	out    %al,(%dx)
f010381b:	b2 a0                	mov    $0xa0,%dl
f010381d:	ee                   	out    %al,(%dx)
	//   s: specific
	//   e: end-of-interrupt
	// xxx: specific interrupt line
	outb(IO_PIC1, 0x20);
	outb(IO_PIC2, 0x20);
}
f010381e:	5d                   	pop    %ebp
f010381f:	c3                   	ret    

f0103820 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103820:	55                   	push   %ebp
f0103821:	89 e5                	mov    %esp,%ebp
f0103823:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0103826:	ff 75 08             	pushl  0x8(%ebp)
f0103829:	e8 68 cf ff ff       	call   f0100796 <cputchar>
f010382e:	83 c4 10             	add    $0x10,%esp
	*cnt++;
}
f0103831:	c9                   	leave  
f0103832:	c3                   	ret    

f0103833 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103833:	55                   	push   %ebp
f0103834:	89 e5                	mov    %esp,%ebp
f0103836:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0103839:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103840:	ff 75 0c             	pushl  0xc(%ebp)
f0103843:	ff 75 08             	pushl  0x8(%ebp)
f0103846:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103849:	50                   	push   %eax
f010384a:	68 20 38 10 f0       	push   $0xf0103820
f010384f:	e8 73 15 00 00       	call   f0104dc7 <vprintfmt>
	return cnt;
}
f0103854:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103857:	c9                   	leave  
f0103858:	c3                   	ret    

f0103859 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103859:	55                   	push   %ebp
f010385a:	89 e5                	mov    %esp,%ebp
f010385c:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010385f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103862:	50                   	push   %eax
f0103863:	ff 75 08             	pushl  0x8(%ebp)
f0103866:	e8 c8 ff ff ff       	call   f0103833 <vcprintf>
	va_end(ap);

	return cnt;
}
f010386b:	c9                   	leave  
f010386c:	c3                   	ret    

f010386d <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f010386d:	55                   	push   %ebp
f010386e:	89 e5                	mov    %esp,%ebp
f0103870:	56                   	push   %esi
f0103871:	53                   	push   %ebx
	// user space on that CPU.
	//
	// LAB 4: Your code here:

	
	int i = cpunum();
f0103872:	e8 00 22 00 00       	call   f0105a77 <cpunum>
f0103877:	89 c3                	mov    %eax,%ebx
	

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	thiscpu->cpu_ts.ts_esp0 = (uintptr_t)(percpu_kstacks[cpunum()] + KSTKSIZE);
f0103879:	e8 f9 21 00 00       	call   f0105a77 <cpunum>
f010387e:	89 c6                	mov    %eax,%esi
f0103880:	e8 f2 21 00 00       	call   f0105a77 <cpunum>
f0103885:	6b f6 74             	imul   $0x74,%esi,%esi
f0103888:	c1 e0 0f             	shl    $0xf,%eax
f010388b:	8d 80 00 30 2b f0    	lea    -0xfd4d000(%eax),%eax
f0103891:	89 86 50 a0 2a f0    	mov    %eax,-0xfd55fb0(%esi)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f0103897:	e8 db 21 00 00       	call   f0105a77 <cpunum>
f010389c:	6b c0 74             	imul   $0x74,%eax,%eax
f010389f:	66 c7 80 54 a0 2a f0 	movw   $0x10,-0xfd55fac(%eax)
f01038a6:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3)+i] = SEG16(STS_T32A, (uint32_t) (&cpus[i].cpu_ts),  //It was (&ts) instead of &cpus[i].cpu_ts
f01038a8:	8d 43 05             	lea    0x5(%ebx),%eax
f01038ab:	6b d3 74             	imul   $0x74,%ebx,%edx
f01038ae:	81 c2 4c a0 2a f0    	add    $0xf02aa04c,%edx
f01038b4:	66 c7 04 c5 80 43 12 	movw   $0x67,-0xfedbc80(,%eax,8)
f01038bb:	f0 67 00 
f01038be:	66 89 14 c5 82 43 12 	mov    %dx,-0xfedbc7e(,%eax,8)
f01038c5:	f0 
f01038c6:	89 d1                	mov    %edx,%ecx
f01038c8:	c1 e9 10             	shr    $0x10,%ecx
f01038cb:	88 0c c5 84 43 12 f0 	mov    %cl,-0xfedbc7c(,%eax,8)
f01038d2:	c6 04 c5 86 43 12 f0 	movb   $0x40,-0xfedbc7a(,%eax,8)
f01038d9:	40 
f01038da:	c1 ea 18             	shr    $0x18,%edx
f01038dd:	88 14 c5 87 43 12 f0 	mov    %dl,-0xfedbc79(,%eax,8)
					sizeof(struct Taskstate)-1, 0);
	gdt[(GD_TSS0 >> 3)+i].sd_s = 0;
f01038e4:	c6 04 c5 85 43 12 f0 	movb   $0x89,-0xfedbc7b(,%eax,8)
f01038eb:	89 

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(((GD_TSS0>>3) + i) << 3);	
f01038ec:	8d 1c dd 28 00 00 00 	lea    0x28(,%ebx,8),%ebx
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f01038f3:	0f 00 db             	ltr    %bx
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f01038f6:	b8 ea 43 12 f0       	mov    $0xf01243ea,%eax
f01038fb:	0f 01 18             	lidtl  (%eax)
	lidt(&idt_pd); 
	
	


}
f01038fe:	5b                   	pop    %ebx
f01038ff:	5e                   	pop    %esi
f0103900:	5d                   	pop    %ebp
f0103901:	c3                   	ret    

f0103902 <trap_init>:
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i,j; 
	for (i=0; i<= T_SIMDERR;i++){
f0103902:	b8 00 00 00 00       	mov    $0x0,%eax
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
f0103907:	8b 14 85 f0 43 12 f0 	mov    -0xfedbc10(,%eax,4),%edx
f010390e:	66 89 14 c5 80 92 2a 	mov    %dx,-0xfd56d80(,%eax,8)
f0103915:	f0 
f0103916:	66 c7 04 c5 82 92 2a 	movw   $0x8,-0xfd56d7e(,%eax,8)
f010391d:	f0 08 00 
f0103920:	c6 04 c5 84 92 2a f0 	movb   $0x0,-0xfd56d7c(,%eax,8)
f0103927:	00 
f0103928:	c6 04 c5 85 92 2a f0 	movb   $0x8e,-0xfd56d7b(,%eax,8)
f010392f:	8e 
f0103930:	c1 ea 10             	shr    $0x10,%edx
f0103933:	66 89 14 c5 86 92 2a 	mov    %dx,-0xfd56d7a(,%eax,8)
f010393a:	f0 
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i,j; 
	for (i=0; i<= T_SIMDERR;i++){
f010393b:	83 c0 01             	add    $0x1,%eax
f010393e:	83 f8 14             	cmp    $0x14,%eax
f0103941:	75 c4                	jne    f0103907 <trap_init+0x5>
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
	}

	//Interrupt 3 is a soft interrupt generated by user, hence the dpl of the gate will be checked with 3
  	SETGATE(idt[3],0,GD_KT,int_vector_table[3],3);
f0103943:	a1 fc 43 12 f0       	mov    0xf01243fc,%eax
f0103948:	66 a3 98 92 2a f0    	mov    %ax,0xf02a9298
f010394e:	66 c7 05 9a 92 2a f0 	movw   $0x8,0xf02a929a
f0103955:	08 00 
f0103957:	c6 05 9c 92 2a f0 00 	movb   $0x0,0xf02a929c
f010395e:	c6 05 9d 92 2a f0 ee 	movb   $0xee,0xf02a929d
f0103965:	c1 e8 10             	shr    $0x10,%eax
f0103968:	66 a3 9e 92 2a f0    	mov    %ax,0xf02a929e

	//similarly system call is setup by the user and hence the gate should be checked with 3 
	SETGATE(idt[T_SYSCALL], 0, GD_KT, int_vector_table[T_SYSCALL], 3);// T_SYSCALL = 3
f010396e:	a1 b0 44 12 f0       	mov    0xf01244b0,%eax
f0103973:	66 a3 00 94 2a f0    	mov    %ax,0xf02a9400
f0103979:	66 c7 05 02 94 2a f0 	movw   $0x8,0xf02a9402
f0103980:	08 00 
f0103982:	c6 05 04 94 2a f0 00 	movb   $0x0,0xf02a9404
f0103989:	c6 05 05 94 2a f0 ee 	movb   $0xee,0xf02a9405
f0103990:	c1 e8 10             	shr    $0x10,%eax
f0103993:	66 a3 06 94 2a f0    	mov    %ax,0xf02a9406
f0103999:	b8 20 00 00 00       	mov    $0x20,%eax

	//For IRQ interrupts
	for(j=0;j<16;j++)
	    SETGATE(idt[IRQ_OFFSET + j], 0, GD_KT, int_vector_table[IRQ_OFFSET + j], 3);
f010399e:	8b 14 85 f0 43 12 f0 	mov    -0xfedbc10(,%eax,4),%edx
f01039a5:	66 89 14 c5 80 92 2a 	mov    %dx,-0xfd56d80(,%eax,8)
f01039ac:	f0 
f01039ad:	66 c7 04 c5 82 92 2a 	movw   $0x8,-0xfd56d7e(,%eax,8)
f01039b4:	f0 08 00 
f01039b7:	c6 04 c5 84 92 2a f0 	movb   $0x0,-0xfd56d7c(,%eax,8)
f01039be:	00 
f01039bf:	c6 04 c5 85 92 2a f0 	movb   $0xee,-0xfd56d7b(,%eax,8)
f01039c6:	ee 
f01039c7:	c1 ea 10             	shr    $0x10,%edx
f01039ca:	66 89 14 c5 86 92 2a 	mov    %dx,-0xfd56d7a(,%eax,8)
f01039d1:	f0 
f01039d2:	83 c0 01             	add    $0x1,%eax

	//similarly system call is setup by the user and hence the gate should be checked with 3 
	SETGATE(idt[T_SYSCALL], 0, GD_KT, int_vector_table[T_SYSCALL], 3);// T_SYSCALL = 3

	//For IRQ interrupts
	for(j=0;j<16;j++)
f01039d5:	83 f8 30             	cmp    $0x30,%eax
f01039d8:	75 c4                	jne    f010399e <trap_init+0x9c>
}


void
trap_init(void)
{
f01039da:	55                   	push   %ebp
f01039db:	89 e5                	mov    %esp,%ebp
f01039dd:	83 ec 08             	sub    $0x8,%esp
	//For IRQ interrupts
	for(j=0;j<16;j++)
	    SETGATE(idt[IRQ_OFFSET + j], 0, GD_KT, int_vector_table[IRQ_OFFSET + j], 3);

	// Per-CPU setup 
	trap_init_percpu();
f01039e0:	e8 88 fe ff ff       	call   f010386d <trap_init_percpu>
}
f01039e5:	c9                   	leave  
f01039e6:	c3                   	ret    

f01039e7 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01039e7:	55                   	push   %ebp
f01039e8:	89 e5                	mov    %esp,%ebp
f01039ea:	53                   	push   %ebx
f01039eb:	83 ec 0c             	sub    $0xc,%esp
f01039ee:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01039f1:	ff 33                	pushl  (%ebx)
f01039f3:	68 cb 7e 10 f0       	push   $0xf0107ecb
f01039f8:	e8 5c fe ff ff       	call   f0103859 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01039fd:	83 c4 08             	add    $0x8,%esp
f0103a00:	ff 73 04             	pushl  0x4(%ebx)
f0103a03:	68 da 7e 10 f0       	push   $0xf0107eda
f0103a08:	e8 4c fe ff ff       	call   f0103859 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103a0d:	83 c4 08             	add    $0x8,%esp
f0103a10:	ff 73 08             	pushl  0x8(%ebx)
f0103a13:	68 e9 7e 10 f0       	push   $0xf0107ee9
f0103a18:	e8 3c fe ff ff       	call   f0103859 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103a1d:	83 c4 08             	add    $0x8,%esp
f0103a20:	ff 73 0c             	pushl  0xc(%ebx)
f0103a23:	68 f8 7e 10 f0       	push   $0xf0107ef8
f0103a28:	e8 2c fe ff ff       	call   f0103859 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103a2d:	83 c4 08             	add    $0x8,%esp
f0103a30:	ff 73 10             	pushl  0x10(%ebx)
f0103a33:	68 07 7f 10 f0       	push   $0xf0107f07
f0103a38:	e8 1c fe ff ff       	call   f0103859 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103a3d:	83 c4 08             	add    $0x8,%esp
f0103a40:	ff 73 14             	pushl  0x14(%ebx)
f0103a43:	68 16 7f 10 f0       	push   $0xf0107f16
f0103a48:	e8 0c fe ff ff       	call   f0103859 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103a4d:	83 c4 08             	add    $0x8,%esp
f0103a50:	ff 73 18             	pushl  0x18(%ebx)
f0103a53:	68 25 7f 10 f0       	push   $0xf0107f25
f0103a58:	e8 fc fd ff ff       	call   f0103859 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103a5d:	83 c4 08             	add    $0x8,%esp
f0103a60:	ff 73 1c             	pushl  0x1c(%ebx)
f0103a63:	68 34 7f 10 f0       	push   $0xf0107f34
f0103a68:	e8 ec fd ff ff       	call   f0103859 <cprintf>
f0103a6d:	83 c4 10             	add    $0x10,%esp
}
f0103a70:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103a73:	c9                   	leave  
f0103a74:	c3                   	ret    

f0103a75 <print_trapframe>:

}

void
print_trapframe(struct Trapframe *tf)
{
f0103a75:	55                   	push   %ebp
f0103a76:	89 e5                	mov    %esp,%ebp
f0103a78:	56                   	push   %esi
f0103a79:	53                   	push   %ebx
f0103a7a:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103a7d:	e8 f5 1f 00 00       	call   f0105a77 <cpunum>
f0103a82:	83 ec 04             	sub    $0x4,%esp
f0103a85:	50                   	push   %eax
f0103a86:	53                   	push   %ebx
f0103a87:	68 98 7f 10 f0       	push   $0xf0107f98
f0103a8c:	e8 c8 fd ff ff       	call   f0103859 <cprintf>
	print_regs(&tf->tf_regs);
f0103a91:	89 1c 24             	mov    %ebx,(%esp)
f0103a94:	e8 4e ff ff ff       	call   f01039e7 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103a99:	83 c4 08             	add    $0x8,%esp
f0103a9c:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103aa0:	50                   	push   %eax
f0103aa1:	68 b6 7f 10 f0       	push   $0xf0107fb6
f0103aa6:	e8 ae fd ff ff       	call   f0103859 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103aab:	83 c4 08             	add    $0x8,%esp
f0103aae:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103ab2:	50                   	push   %eax
f0103ab3:	68 c9 7f 10 f0       	push   $0xf0107fc9
f0103ab8:	e8 9c fd ff ff       	call   f0103859 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103abd:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103ac0:	83 c4 10             	add    $0x10,%esp
f0103ac3:	83 f8 13             	cmp    $0x13,%eax
f0103ac6:	77 09                	ja     f0103ad1 <print_trapframe+0x5c>
		return excnames[trapno];
f0103ac8:	8b 14 85 80 82 10 f0 	mov    -0xfef7d80(,%eax,4),%edx
f0103acf:	eb 1f                	jmp    f0103af0 <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103ad1:	83 f8 30             	cmp    $0x30,%eax
f0103ad4:	74 15                	je     f0103aeb <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103ad6:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103ad9:	83 fa 10             	cmp    $0x10,%edx
f0103adc:	b9 62 7f 10 f0       	mov    $0xf0107f62,%ecx
f0103ae1:	ba 4f 7f 10 f0       	mov    $0xf0107f4f,%edx
f0103ae6:	0f 43 d1             	cmovae %ecx,%edx
f0103ae9:	eb 05                	jmp    f0103af0 <print_trapframe+0x7b>
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103aeb:	ba 43 7f 10 f0       	mov    $0xf0107f43,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103af0:	83 ec 04             	sub    $0x4,%esp
f0103af3:	52                   	push   %edx
f0103af4:	50                   	push   %eax
f0103af5:	68 dc 7f 10 f0       	push   $0xf0107fdc
f0103afa:	e8 5a fd ff ff       	call   f0103859 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103aff:	83 c4 10             	add    $0x10,%esp
f0103b02:	3b 1d 80 9a 2a f0    	cmp    0xf02a9a80,%ebx
f0103b08:	75 1a                	jne    f0103b24 <print_trapframe+0xaf>
f0103b0a:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103b0e:	75 14                	jne    f0103b24 <print_trapframe+0xaf>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103b10:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103b13:	83 ec 08             	sub    $0x8,%esp
f0103b16:	50                   	push   %eax
f0103b17:	68 ee 7f 10 f0       	push   $0xf0107fee
f0103b1c:	e8 38 fd ff ff       	call   f0103859 <cprintf>
f0103b21:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103b24:	83 ec 08             	sub    $0x8,%esp
f0103b27:	ff 73 2c             	pushl  0x2c(%ebx)
f0103b2a:	68 fd 7f 10 f0       	push   $0xf0107ffd
f0103b2f:	e8 25 fd ff ff       	call   f0103859 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103b34:	83 c4 10             	add    $0x10,%esp
f0103b37:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103b3b:	75 49                	jne    f0103b86 <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103b3d:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103b40:	89 c2                	mov    %eax,%edx
f0103b42:	83 e2 01             	and    $0x1,%edx
f0103b45:	ba 7c 7f 10 f0       	mov    $0xf0107f7c,%edx
f0103b4a:	b9 71 7f 10 f0       	mov    $0xf0107f71,%ecx
f0103b4f:	0f 44 ca             	cmove  %edx,%ecx
f0103b52:	89 c2                	mov    %eax,%edx
f0103b54:	83 e2 02             	and    $0x2,%edx
f0103b57:	ba 8e 7f 10 f0       	mov    $0xf0107f8e,%edx
f0103b5c:	be 88 7f 10 f0       	mov    $0xf0107f88,%esi
f0103b61:	0f 45 d6             	cmovne %esi,%edx
f0103b64:	83 e0 04             	and    $0x4,%eax
f0103b67:	be e4 80 10 f0       	mov    $0xf01080e4,%esi
f0103b6c:	b8 93 7f 10 f0       	mov    $0xf0107f93,%eax
f0103b71:	0f 44 c6             	cmove  %esi,%eax
f0103b74:	51                   	push   %ecx
f0103b75:	52                   	push   %edx
f0103b76:	50                   	push   %eax
f0103b77:	68 0b 80 10 f0       	push   $0xf010800b
f0103b7c:	e8 d8 fc ff ff       	call   f0103859 <cprintf>
f0103b81:	83 c4 10             	add    $0x10,%esp
f0103b84:	eb 10                	jmp    f0103b96 <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103b86:	83 ec 0c             	sub    $0xc,%esp
f0103b89:	68 2e 83 10 f0       	push   $0xf010832e
f0103b8e:	e8 c6 fc ff ff       	call   f0103859 <cprintf>
f0103b93:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103b96:	83 ec 08             	sub    $0x8,%esp
f0103b99:	ff 73 30             	pushl  0x30(%ebx)
f0103b9c:	68 1a 80 10 f0       	push   $0xf010801a
f0103ba1:	e8 b3 fc ff ff       	call   f0103859 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103ba6:	83 c4 08             	add    $0x8,%esp
f0103ba9:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103bad:	50                   	push   %eax
f0103bae:	68 29 80 10 f0       	push   $0xf0108029
f0103bb3:	e8 a1 fc ff ff       	call   f0103859 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103bb8:	83 c4 08             	add    $0x8,%esp
f0103bbb:	ff 73 38             	pushl  0x38(%ebx)
f0103bbe:	68 3c 80 10 f0       	push   $0xf010803c
f0103bc3:	e8 91 fc ff ff       	call   f0103859 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103bc8:	83 c4 10             	add    $0x10,%esp
f0103bcb:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103bcf:	74 25                	je     f0103bf6 <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103bd1:	83 ec 08             	sub    $0x8,%esp
f0103bd4:	ff 73 3c             	pushl  0x3c(%ebx)
f0103bd7:	68 4b 80 10 f0       	push   $0xf010804b
f0103bdc:	e8 78 fc ff ff       	call   f0103859 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103be1:	83 c4 08             	add    $0x8,%esp
f0103be4:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103be8:	50                   	push   %eax
f0103be9:	68 5a 80 10 f0       	push   $0xf010805a
f0103bee:	e8 66 fc ff ff       	call   f0103859 <cprintf>
f0103bf3:	83 c4 10             	add    $0x10,%esp
	}
}
f0103bf6:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103bf9:	5b                   	pop    %ebx
f0103bfa:	5e                   	pop    %esi
f0103bfb:	5d                   	pop    %ebp
f0103bfc:	c3                   	ret    

f0103bfd <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103bfd:	55                   	push   %ebp
f0103bfe:	89 e5                	mov    %esp,%ebp
f0103c00:	57                   	push   %edi
f0103c01:	56                   	push   %esi
f0103c02:	53                   	push   %ebx
f0103c03:	83 ec 1c             	sub    $0x1c,%esp
f0103c06:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103c09:	0f 20 d6             	mov    %cr2,%esi
	// LAB 3: Your code here.


	//If the processor is already in kernel mode when the interrupt or exception occurs 
	//(the low 2 bits of the CS register are already zero), Hence we have to check the CS register to make sure its in kernel mode
	if ((tf->tf_cs & 0x11) == 0){
f0103c0c:	f6 43 34 11          	testb  $0x11,0x34(%ebx)
f0103c10:	75 15                	jne    f0103c27 <page_fault_handler+0x2a>
		panic("Fault occured in kernel space on %08x \n",fault_va);
f0103c12:	56                   	push   %esi
f0103c13:	68 30 82 10 f0       	push   $0xf0108230
f0103c18:	68 5f 01 00 00       	push   $0x15f
f0103c1d:	68 6d 80 10 f0       	push   $0xf010806d
f0103c22:	e8 19 c4 ff ff       	call   f0100040 <_panic>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	//Store the current env's stack tf_esp for use, if the call occurs inside UXtrapframe  
	const uint32_t cur_tf_esp_addr = (uint32_t)(tf->tf_esp); 	// trap-time esp
f0103c27:	8b 7b 3c             	mov    0x3c(%ebx),%edi

	

	// If there is no env_pgfault_upcall or no page fault handler for the curenv follow the original procedure
	if (!curenv->env_pgfault_upcall)
f0103c2a:	e8 48 1e 00 00       	call   f0105a77 <cpunum>
f0103c2f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c32:	8b 80 48 a0 2a f0    	mov    -0xfd55fb8(%eax),%eax
f0103c38:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f0103c3c:	75 46                	jne    f0103c84 <page_fault_handler+0x87>
	{
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c3e:	8b 43 30             	mov    0x30(%ebx),%eax
f0103c41:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			curenv->env_id, fault_va, tf->tf_eip);
f0103c44:	e8 2e 1e 00 00       	call   f0105a77 <cpunum>
	

	// If there is no env_pgfault_upcall or no page fault handler for the curenv follow the original procedure
	if (!curenv->env_pgfault_upcall)
	{
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c49:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103c4c:	56                   	push   %esi
			curenv->env_id, fault_va, tf->tf_eip);
f0103c4d:	6b c0 74             	imul   $0x74,%eax,%eax
	

	// If there is no env_pgfault_upcall or no page fault handler for the curenv follow the original procedure
	if (!curenv->env_pgfault_upcall)
	{
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c50:	8b 80 48 a0 2a f0    	mov    -0xfd55fb8(%eax),%eax
f0103c56:	ff 70 48             	pushl  0x48(%eax)
f0103c59:	68 58 82 10 f0       	push   $0xf0108258
f0103c5e:	e8 f6 fb ff ff       	call   f0103859 <cprintf>
			curenv->env_id, fault_va, tf->tf_eip);
		print_trapframe(tf);
f0103c63:	89 1c 24             	mov    %ebx,(%esp)
f0103c66:	e8 0a fe ff ff       	call   f0103a75 <print_trapframe>
		env_destroy(curenv);	// Destroy the environment that caused the fault.
f0103c6b:	e8 07 1e 00 00       	call   f0105a77 <cpunum>
f0103c70:	83 c4 04             	add    $0x4,%esp
f0103c73:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c76:	ff b0 48 a0 2a f0    	pushl  -0xfd55fb8(%eax)
f0103c7c:	e8 fe f8 ff ff       	call   f010357f <env_destroy>
f0103c81:	83 c4 10             	add    $0x10,%esp
	}
	
	//Check if the	
	struct UTrapframe* usertf = NULL; //As defined in inc/trap.h
	
	if((cur_tf_esp_addr < UXSTACKTOP) && (cur_tf_esp_addr >=(UXSTACKTOP - PGSIZE)))
f0103c84:	8d 97 00 10 40 11    	lea    0x11401000(%edi),%edx
	{
		//If its already inside the exception stack
		//Allocate the address by leaving space for 32-bit word
		usertf = (struct UTrapframe*)(cur_tf_esp_addr - 4 - sizeof(struct UTrapframe));
f0103c8a:	8d 47 c8             	lea    -0x38(%edi),%eax
f0103c8d:	81 fa ff 0f 00 00    	cmp    $0xfff,%edx
f0103c93:	ba cc ff bf ee       	mov    $0xeebfffcc,%edx
f0103c98:	0f 46 d0             	cmovbe %eax,%edx
f0103c9b:	89 d7                	mov    %edx,%edi
		usertf = (struct UTrapframe*)(UXSTACKTOP - sizeof(struct UTrapframe));
	}
	
	//Check whether the usertf memory is valid
	//This function will not return if there is a fault and it will also destroy the environment
	user_mem_assert(curenv, (void*)usertf, sizeof(struct UTrapframe), PTE_U | PTE_P | PTE_W);
f0103c9d:	e8 d5 1d 00 00       	call   f0105a77 <cpunum>
f0103ca2:	6a 07                	push   $0x7
f0103ca4:	6a 34                	push   $0x34
f0103ca6:	57                   	push   %edi
f0103ca7:	6b c0 74             	imul   $0x74,%eax,%eax
f0103caa:	ff b0 48 a0 2a f0    	pushl  -0xfd55fb8(%eax)
f0103cb0:	e8 99 f2 ff ff       	call   f0102f4e <user_mem_assert>
	
	
	// User exeception trapframe
	usertf->utf_fault_va = fault_va;
f0103cb5:	89 fa                	mov    %edi,%edx
f0103cb7:	89 37                	mov    %esi,(%edi)
	usertf->utf_err = tf->tf_err;
f0103cb9:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103cbc:	89 47 04             	mov    %eax,0x4(%edi)
	usertf->utf_regs = tf->tf_regs;
f0103cbf:	8d 7f 08             	lea    0x8(%edi),%edi
f0103cc2:	b9 08 00 00 00       	mov    $0x8,%ecx
f0103cc7:	89 de                	mov    %ebx,%esi
f0103cc9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	usertf->utf_eip = tf->tf_eip;
f0103ccb:	8b 43 30             	mov    0x30(%ebx),%eax
f0103cce:	89 42 28             	mov    %eax,0x28(%edx)
	usertf->utf_esp = tf->tf_esp;
f0103cd1:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103cd4:	89 42 30             	mov    %eax,0x30(%edx)
	usertf->utf_eflags = tf->tf_eflags;
f0103cd7:	8b 43 38             	mov    0x38(%ebx),%eax
f0103cda:	89 42 2c             	mov    %eax,0x2c(%edx)
	
	//Setup the tf with Exception stack frame
	
	tf->tf_esp= (uintptr_t)usertf;
f0103cdd:	89 53 3c             	mov    %edx,0x3c(%ebx)
	tf->tf_eip = (uintptr_t)curenv->env_pgfault_upcall; 
f0103ce0:	e8 92 1d 00 00       	call   f0105a77 <cpunum>
f0103ce5:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ce8:	8b 80 48 a0 2a f0    	mov    -0xfd55fb8(%eax),%eax
f0103cee:	8b 40 64             	mov    0x64(%eax),%eax
f0103cf1:	89 43 30             	mov    %eax,0x30(%ebx)

	env_run(curenv);
f0103cf4:	e8 7e 1d 00 00       	call   f0105a77 <cpunum>
f0103cf9:	83 c4 04             	add    $0x4,%esp
f0103cfc:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cff:	ff b0 48 a0 2a f0    	pushl  -0xfd55fb8(%eax)
f0103d05:	e8 14 f9 ff ff       	call   f010361e <env_run>

f0103d0a <trap>:
	
}

void
trap(struct Trapframe *tf)
{
f0103d0a:	55                   	push   %ebp
f0103d0b:	89 e5                	mov    %esp,%ebp
f0103d0d:	57                   	push   %edi
f0103d0e:	56                   	push   %esi
f0103d0f:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103d12:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103d13:	83 3d cc 9e 2a f0 00 	cmpl   $0x0,0xf02a9ecc
f0103d1a:	74 01                	je     f0103d1d <trap+0x13>
		asm volatile("hlt");
f0103d1c:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103d1d:	e8 55 1d 00 00       	call   f0105a77 <cpunum>
f0103d22:	6b d0 74             	imul   $0x74,%eax,%edx
f0103d25:	81 c2 40 a0 2a f0    	add    $0xf02aa040,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0103d2b:	b8 01 00 00 00       	mov    $0x1,%eax
f0103d30:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103d34:	83 f8 02             	cmp    $0x2,%eax
f0103d37:	75 10                	jne    f0103d49 <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103d39:	83 ec 0c             	sub    $0xc,%esp
f0103d3c:	68 c0 44 12 f0       	push   $0xf01244c0
f0103d41:	e8 9c 1f 00 00       	call   f0105ce2 <spin_lock>
f0103d46:	83 c4 10             	add    $0x10,%esp

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103d49:	9c                   	pushf  
f0103d4a:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103d4b:	f6 c4 02             	test   $0x2,%ah
f0103d4e:	74 19                	je     f0103d69 <trap+0x5f>
f0103d50:	68 79 80 10 f0       	push   $0xf0108079
f0103d55:	68 db 7a 10 f0       	push   $0xf0107adb
f0103d5a:	68 25 01 00 00       	push   $0x125
f0103d5f:	68 6d 80 10 f0       	push   $0xf010806d
f0103d64:	e8 d7 c2 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103d69:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103d6d:	83 e0 03             	and    $0x3,%eax
f0103d70:	66 83 f8 03          	cmp    $0x3,%ax
f0103d74:	0f 85 a0 00 00 00    	jne    f0103e1a <trap+0x110>
f0103d7a:	83 ec 0c             	sub    $0xc,%esp
f0103d7d:	68 c0 44 12 f0       	push   $0xf01244c0
f0103d82:	e8 5b 1f 00 00       	call   f0105ce2 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel(); //Lock Kernel
		assert(curenv);
f0103d87:	e8 eb 1c 00 00       	call   f0105a77 <cpunum>
f0103d8c:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d8f:	83 c4 10             	add    $0x10,%esp
f0103d92:	83 b8 48 a0 2a f0 00 	cmpl   $0x0,-0xfd55fb8(%eax)
f0103d99:	75 19                	jne    f0103db4 <trap+0xaa>
f0103d9b:	68 92 80 10 f0       	push   $0xf0108092
f0103da0:	68 db 7a 10 f0       	push   $0xf0107adb
f0103da5:	68 2d 01 00 00       	push   $0x12d
f0103daa:	68 6d 80 10 f0       	push   $0xf010806d
f0103daf:	e8 8c c2 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103db4:	e8 be 1c 00 00       	call   f0105a77 <cpunum>
f0103db9:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dbc:	8b 80 48 a0 2a f0    	mov    -0xfd55fb8(%eax),%eax
f0103dc2:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103dc6:	75 2d                	jne    f0103df5 <trap+0xeb>
			env_free(curenv);
f0103dc8:	e8 aa 1c 00 00       	call   f0105a77 <cpunum>
f0103dcd:	83 ec 0c             	sub    $0xc,%esp
f0103dd0:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dd3:	ff b0 48 a0 2a f0    	pushl  -0xfd55fb8(%eax)
f0103dd9:	e8 fb f5 ff ff       	call   f01033d9 <env_free>
			curenv = NULL;
f0103dde:	e8 94 1c 00 00       	call   f0105a77 <cpunum>
f0103de3:	6b c0 74             	imul   $0x74,%eax,%eax
f0103de6:	c7 80 48 a0 2a f0 00 	movl   $0x0,-0xfd55fb8(%eax)
f0103ded:	00 00 00 
			sched_yield();
f0103df0:	e8 1f 04 00 00       	call   f0104214 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103df5:	e8 7d 1c 00 00       	call   f0105a77 <cpunum>
f0103dfa:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dfd:	8b 80 48 a0 2a f0    	mov    -0xfd55fb8(%eax),%eax
f0103e03:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103e08:	89 c7                	mov    %eax,%edi
f0103e0a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103e0c:	e8 66 1c 00 00       	call   f0105a77 <cpunum>
f0103e11:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e14:	8b b0 48 a0 2a f0    	mov    -0xfd55fb8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103e1a:	89 35 80 9a 2a f0    	mov    %esi,0xf02a9a80
{

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0103e20:	8b 46 28             	mov    0x28(%esi),%eax
f0103e23:	83 f8 27             	cmp    $0x27,%eax
f0103e26:	75 1d                	jne    f0103e45 <trap+0x13b>
		cprintf("Spurious interrupt on irq 7\n");
f0103e28:	83 ec 0c             	sub    $0xc,%esp
f0103e2b:	68 99 80 10 f0       	push   $0xf0108099
f0103e30:	e8 24 fa ff ff       	call   f0103859 <cprintf>
		print_trapframe(tf);
f0103e35:	89 34 24             	mov    %esi,(%esp)
f0103e38:	e8 38 fc ff ff       	call   f0103a75 <print_trapframe>
f0103e3d:	83 c4 10             	add    $0x10,%esp
f0103e40:	e9 ce 00 00 00       	jmp    f0103f13 <trap+0x209>
	}

	// Handle processor exceptions.
	// LAB 3: Your code here.
	//call trap_handler function for page_fault
	switch (tf->tf_trapno) {
f0103e45:	83 f8 20             	cmp    $0x20,%eax
f0103e48:	74 69                	je     f0103eb3 <trap+0x1a9>
f0103e4a:	83 f8 20             	cmp    $0x20,%eax
f0103e4d:	77 0c                	ja     f0103e5b <trap+0x151>
f0103e4f:	83 f8 03             	cmp    $0x3,%eax
f0103e52:	74 18                	je     f0103e6c <trap+0x162>
f0103e54:	83 f8 0e             	cmp    $0xe,%eax
f0103e57:	74 30                	je     f0103e89 <trap+0x17f>
f0103e59:	eb 75                	jmp    f0103ed0 <trap+0x1c6>
f0103e5b:	83 f8 24             	cmp    $0x24,%eax
f0103e5e:	74 69                	je     f0103ec9 <trap+0x1bf>
f0103e60:	83 f8 30             	cmp    $0x30,%eax
f0103e63:	74 2d                	je     f0103e92 <trap+0x188>
f0103e65:	83 f8 21             	cmp    $0x21,%eax
f0103e68:	75 66                	jne    f0103ed0 <trap+0x1c6>
f0103e6a:	eb 56                	jmp    f0103ec2 <trap+0x1b8>
		case T_BRKPT:
			monitor(tf);
f0103e6c:	83 ec 0c             	sub    $0xc,%esp
f0103e6f:	56                   	push   %esi
f0103e70:	e8 ba ca ff ff       	call   f010092f <monitor>
			cprintf("return from breakpoint....\n");
f0103e75:	c7 04 24 b6 80 10 f0 	movl   $0xf01080b6,(%esp)
f0103e7c:	e8 d8 f9 ff ff       	call   f0103859 <cprintf>
f0103e81:	83 c4 10             	add    $0x10,%esp
f0103e84:	e9 8a 00 00 00       	jmp    f0103f13 <trap+0x209>
			break;

		case T_PGFLT:
			page_fault_handler(tf);
f0103e89:	83 ec 0c             	sub    $0xc,%esp
f0103e8c:	56                   	push   %esi
f0103e8d:	e8 6b fd ff ff       	call   f0103bfd <page_fault_handler>
			break;

		case T_SYSCALL:
			tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax,
f0103e92:	83 ec 08             	sub    $0x8,%esp
f0103e95:	ff 76 04             	pushl  0x4(%esi)
f0103e98:	ff 36                	pushl  (%esi)
f0103e9a:	ff 76 10             	pushl  0x10(%esi)
f0103e9d:	ff 76 18             	pushl  0x18(%esi)
f0103ea0:	ff 76 14             	pushl  0x14(%esi)
f0103ea3:	ff 76 1c             	pushl  0x1c(%esi)
f0103ea6:	e8 49 04 00 00       	call   f01042f4 <syscall>
f0103eab:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103eae:	83 c4 20             	add    $0x20,%esp
f0103eb1:	eb 60                	jmp    f0103f13 <trap+0x209>

		// Handle clock interrupts. Don't forget to acknowledge the
		// interrupt using lapic_eoi() before calling the scheduler!
		// LAB 4: Your code here.
		case IRQ_OFFSET+IRQ_TIMER:
			time_tick();
f0103eb3:	e8 52 29 00 00       	call   f010680a <time_tick>
			lapic_eoi();
f0103eb8:	e8 05 1d 00 00       	call   f0105bc2 <lapic_eoi>
			sched_yield();
f0103ebd:	e8 52 03 00 00       	call   f0104214 <sched_yield>
			break;
		
		// Handle keyboard and serial interrupts.
		// LAB 5: Your code here.
		case IRQ_OFFSET+IRQ_KBD:
			kbd_intr();
f0103ec2:	e8 3c c7 ff ff       	call   f0100603 <kbd_intr>
f0103ec7:	eb 4a                	jmp    f0103f13 <trap+0x209>
			break;

		case IRQ_OFFSET+IRQ_SERIAL:
			serial_intr();
f0103ec9:	e8 19 c7 ff ff       	call   f01005e7 <serial_intr>
f0103ece:	eb 43                	jmp    f0103f13 <trap+0x209>
	

	
		default:
		// Unexpected trap: The user process or the kernel has a bug.
			print_trapframe(tf);
f0103ed0:	83 ec 0c             	sub    $0xc,%esp
f0103ed3:	56                   	push   %esi
f0103ed4:	e8 9c fb ff ff       	call   f0103a75 <print_trapframe>
			if (tf->tf_cs == GD_KT){
f0103ed9:	83 c4 10             	add    $0x10,%esp
f0103edc:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103ee1:	75 17                	jne    f0103efa <trap+0x1f0>
			panic("unhandled trap in kernel");
f0103ee3:	83 ec 04             	sub    $0x4,%esp
f0103ee6:	68 d2 80 10 f0       	push   $0xf01080d2
f0103eeb:	68 02 01 00 00       	push   $0x102
f0103ef0:	68 6d 80 10 f0       	push   $0xf010806d
f0103ef5:	e8 46 c1 ff ff       	call   f0100040 <_panic>
			}
		else {
			env_destroy(curenv);
f0103efa:	e8 78 1b 00 00       	call   f0105a77 <cpunum>
f0103eff:	83 ec 0c             	sub    $0xc,%esp
f0103f02:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f05:	ff b0 48 a0 2a f0    	pushl  -0xfd55fb8(%eax)
f0103f0b:	e8 6f f6 ff ff       	call   f010357f <env_destroy>
f0103f10:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103f13:	e8 5f 1b 00 00       	call   f0105a77 <cpunum>
f0103f18:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f1b:	83 b8 48 a0 2a f0 00 	cmpl   $0x0,-0xfd55fb8(%eax)
f0103f22:	74 2a                	je     f0103f4e <trap+0x244>
f0103f24:	e8 4e 1b 00 00       	call   f0105a77 <cpunum>
f0103f29:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f2c:	8b 80 48 a0 2a f0    	mov    -0xfd55fb8(%eax),%eax
f0103f32:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103f36:	75 16                	jne    f0103f4e <trap+0x244>
		env_run(curenv);
f0103f38:	e8 3a 1b 00 00       	call   f0105a77 <cpunum>
f0103f3d:	83 ec 0c             	sub    $0xc,%esp
f0103f40:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f43:	ff b0 48 a0 2a f0    	pushl  -0xfd55fb8(%eax)
f0103f49:	e8 d0 f6 ff ff       	call   f010361e <env_run>
	else
		sched_yield();
f0103f4e:	e8 c1 02 00 00       	call   f0104214 <sched_yield>
f0103f53:	90                   	nop

f0103f54 <handler_0>:
#define T_DEFAULT   500		// catchall
*/

//TRAPHANDLER_NOEC for traps without error code
// From 0-7 no error code requred
	TRAPHANDLER_NOEC(handler_0, 0)   #Divide error
f0103f54:	6a 00                	push   $0x0
f0103f56:	6a 00                	push   $0x0
f0103f58:	e9 d2 01 00 00       	jmp    f010412f <_alltraps>
f0103f5d:	90                   	nop

f0103f5e <handler_1>:
	TRAPHANDLER_NOEC(handler_1, 1)   #Debug exceptions 
f0103f5e:	6a 00                	push   $0x0
f0103f60:	6a 01                	push   $0x1
f0103f62:	e9 c8 01 00 00       	jmp    f010412f <_alltraps>
f0103f67:	90                   	nop

f0103f68 <handler_2>:
 	TRAPHANDLER_NOEC(handler_2, 2)   //NMI Interrupt
f0103f68:	6a 00                	push   $0x0
f0103f6a:	6a 02                	push   $0x2
f0103f6c:	e9 be 01 00 00       	jmp    f010412f <_alltraps>
f0103f71:	90                   	nop

f0103f72 <handler_3>:
	TRAPHANDLER_NOEC(handler_3, 3)   //Breakpoint
f0103f72:	6a 00                	push   $0x0
f0103f74:	6a 03                	push   $0x3
f0103f76:	e9 b4 01 00 00       	jmp    f010412f <_alltraps>
f0103f7b:	90                   	nop

f0103f7c <handler_4>:
	TRAPHANDLER_NOEC(handler_4, 4)   //Overflow
f0103f7c:	6a 00                	push   $0x0
f0103f7e:	6a 04                	push   $0x4
f0103f80:	e9 aa 01 00 00       	jmp    f010412f <_alltraps>
f0103f85:	90                   	nop

f0103f86 <handler_5>:
	TRAPHANDLER_NOEC(handler_5, 5)   //Bounds check 
f0103f86:	6a 00                	push   $0x0
f0103f88:	6a 05                	push   $0x5
f0103f8a:	e9 a0 01 00 00       	jmp    f010412f <_alltraps>
f0103f8f:	90                   	nop

f0103f90 <handler_6>:
	TRAPHANDLER_NOEC(handler_6, 6)   //Invalid opcode
f0103f90:	6a 00                	push   $0x0
f0103f92:	6a 06                	push   $0x6
f0103f94:	e9 96 01 00 00       	jmp    f010412f <_alltraps>
f0103f99:	90                   	nop

f0103f9a <handler_7>:
	TRAPHANDLER_NOEC(handler_7, 7)   //Coprocessor not available
f0103f9a:	6a 00                	push   $0x0
f0103f9c:	6a 07                	push   $0x7
f0103f9e:	e9 8c 01 00 00       	jmp    f010412f <_alltraps>
f0103fa3:	90                   	nop

f0103fa4 <handler_8>:
	
	TRAPHANDLER(handler_8, 8)   // double fault
f0103fa4:	6a 08                	push   $0x8
f0103fa6:	e9 84 01 00 00       	jmp    f010412f <_alltraps>
f0103fab:	90                   	nop

f0103fac <handler_9>:
	
	TRAPHANDLER_NOEC(handler_9, 9)   //Coprocessor Segment Overrun
f0103fac:	6a 00                	push   $0x0
f0103fae:	6a 09                	push   $0x9
f0103fb0:	e9 7a 01 00 00       	jmp    f010412f <_alltraps>
f0103fb5:	90                   	nop

f0103fb6 <handler_10>:

	TRAPHANDLER(handler_10, 10)   // invalid task switch segment
f0103fb6:	6a 0a                	push   $0xa
f0103fb8:	e9 72 01 00 00       	jmp    f010412f <_alltraps>
f0103fbd:	90                   	nop

f0103fbe <handler_11>:
	TRAPHANDLER(handler_11, 11)   // segment not present
f0103fbe:	6a 0b                	push   $0xb
f0103fc0:	e9 6a 01 00 00       	jmp    f010412f <_alltraps>
f0103fc5:	90                   	nop

f0103fc6 <handler_12>:
	TRAPHANDLER(handler_12, 12)   // stack exception
f0103fc6:	6a 0c                	push   $0xc
f0103fc8:	e9 62 01 00 00       	jmp    f010412f <_alltraps>
f0103fcd:	90                   	nop

f0103fce <handler_13>:
	TRAPHANDLER(handler_13, 13)   // general protection fault
f0103fce:	6a 0d                	push   $0xd
f0103fd0:	e9 5a 01 00 00       	jmp    f010412f <_alltraps>
f0103fd5:	90                   	nop

f0103fd6 <handler_14>:
	TRAPHANDLER(handler_14, 14)   // page fault
f0103fd6:	6a 0e                	push   $0xe
f0103fd8:	e9 52 01 00 00       	jmp    f010412f <_alltraps>
f0103fdd:	90                   	nop

f0103fde <handler_15>:

	TRAPHANDLER_NOEC(handler_15, 15)   // Reserved
f0103fde:	6a 00                	push   $0x0
f0103fe0:	6a 0f                	push   $0xf
f0103fe2:	e9 48 01 00 00       	jmp    f010412f <_alltraps>
f0103fe7:	90                   	nop

f0103fe8 <handler_16>:

	TRAPHANDLER_NOEC(handler_16, 16)   // floating point error
f0103fe8:	6a 00                	push   $0x0
f0103fea:	6a 10                	push   $0x10
f0103fec:	e9 3e 01 00 00       	jmp    f010412f <_alltraps>
f0103ff1:	90                   	nop

f0103ff2 <handler_17>:

	TRAPHANDLER(handler_17, 17)   // aligment check
f0103ff2:	6a 11                	push   $0x11
f0103ff4:	e9 36 01 00 00       	jmp    f010412f <_alltraps>
f0103ff9:	90                   	nop

f0103ffa <handler_18>:

	TRAPHANDLER_NOEC(handler_18, 18)   // machine check
f0103ffa:	6a 00                	push   $0x0
f0103ffc:	6a 12                	push   $0x12
f0103ffe:	e9 2c 01 00 00       	jmp    f010412f <_alltraps>
f0104003:	90                   	nop

f0104004 <handler_19>:
	TRAPHANDLER_NOEC(handler_19, 19)   // SIMD floating point error
f0104004:	6a 00                	push   $0x0
f0104006:	6a 13                	push   $0x13
f0104008:	e9 22 01 00 00       	jmp    f010412f <_alltraps>
f010400d:	90                   	nop

f010400e <handler_20>:

	TRAPHANDLER_NOEC(handler_20, 20)
f010400e:	6a 00                	push   $0x0
f0104010:	6a 14                	push   $0x14
f0104012:	e9 18 01 00 00       	jmp    f010412f <_alltraps>
f0104017:	90                   	nop

f0104018 <handler_21>:
	TRAPHANDLER_NOEC(handler_21, 21)
f0104018:	6a 00                	push   $0x0
f010401a:	6a 15                	push   $0x15
f010401c:	e9 0e 01 00 00       	jmp    f010412f <_alltraps>
f0104021:	90                   	nop

f0104022 <handler_22>:
	TRAPHANDLER_NOEC(handler_22, 22)
f0104022:	6a 00                	push   $0x0
f0104024:	6a 16                	push   $0x16
f0104026:	e9 04 01 00 00       	jmp    f010412f <_alltraps>
f010402b:	90                   	nop

f010402c <handler_23>:
	TRAPHANDLER_NOEC(handler_23, 23)
f010402c:	6a 00                	push   $0x0
f010402e:	6a 17                	push   $0x17
f0104030:	e9 fa 00 00 00       	jmp    f010412f <_alltraps>
f0104035:	90                   	nop

f0104036 <handler_24>:
	TRAPHANDLER_NOEC(handler_24, 24)
f0104036:	6a 00                	push   $0x0
f0104038:	6a 18                	push   $0x18
f010403a:	e9 f0 00 00 00       	jmp    f010412f <_alltraps>
f010403f:	90                   	nop

f0104040 <handler_25>:
	TRAPHANDLER_NOEC(handler_25, 25)
f0104040:	6a 00                	push   $0x0
f0104042:	6a 19                	push   $0x19
f0104044:	e9 e6 00 00 00       	jmp    f010412f <_alltraps>
f0104049:	90                   	nop

f010404a <handler_26>:
	TRAPHANDLER_NOEC(handler_26, 26)
f010404a:	6a 00                	push   $0x0
f010404c:	6a 1a                	push   $0x1a
f010404e:	e9 dc 00 00 00       	jmp    f010412f <_alltraps>
f0104053:	90                   	nop

f0104054 <handler_27>:
	TRAPHANDLER_NOEC(handler_27, 27)
f0104054:	6a 00                	push   $0x0
f0104056:	6a 1b                	push   $0x1b
f0104058:	e9 d2 00 00 00       	jmp    f010412f <_alltraps>
f010405d:	90                   	nop

f010405e <handler_28>:
	TRAPHANDLER_NOEC(handler_28, 28)
f010405e:	6a 00                	push   $0x0
f0104060:	6a 1c                	push   $0x1c
f0104062:	e9 c8 00 00 00       	jmp    f010412f <_alltraps>
f0104067:	90                   	nop

f0104068 <handler_29>:
	TRAPHANDLER_NOEC(handler_29, 29)
f0104068:	6a 00                	push   $0x0
f010406a:	6a 1d                	push   $0x1d
f010406c:	e9 be 00 00 00       	jmp    f010412f <_alltraps>
f0104071:	90                   	nop

f0104072 <handler_30>:
	TRAPHANDLER_NOEC(handler_30, 30)
f0104072:	6a 00                	push   $0x0
f0104074:	6a 1e                	push   $0x1e
f0104076:	e9 b4 00 00 00       	jmp    f010412f <_alltraps>
f010407b:	90                   	nop

f010407c <handler_31>:
	TRAPHANDLER_NOEC(handler_31, 31)
f010407c:	6a 00                	push   $0x0
f010407e:	6a 1f                	push   $0x1f
f0104080:	e9 aa 00 00 00       	jmp    f010412f <_alltraps>
f0104085:	90                   	nop

f0104086 <handler_32>:
	TRAPHANDLER_NOEC(handler_32, 32)
f0104086:	6a 00                	push   $0x0
f0104088:	6a 20                	push   $0x20
f010408a:	e9 a0 00 00 00       	jmp    f010412f <_alltraps>
f010408f:	90                   	nop

f0104090 <handler_33>:
	TRAPHANDLER_NOEC(handler_33, 33)
f0104090:	6a 00                	push   $0x0
f0104092:	6a 21                	push   $0x21
f0104094:	e9 96 00 00 00       	jmp    f010412f <_alltraps>
f0104099:	90                   	nop

f010409a <handler_34>:
	TRAPHANDLER_NOEC(handler_34, 34)
f010409a:	6a 00                	push   $0x0
f010409c:	6a 22                	push   $0x22
f010409e:	e9 8c 00 00 00       	jmp    f010412f <_alltraps>
f01040a3:	90                   	nop

f01040a4 <handler_35>:
	TRAPHANDLER_NOEC(handler_35, 35)
f01040a4:	6a 00                	push   $0x0
f01040a6:	6a 23                	push   $0x23
f01040a8:	e9 82 00 00 00       	jmp    f010412f <_alltraps>
f01040ad:	90                   	nop

f01040ae <handler_36>:
	TRAPHANDLER_NOEC(handler_36, 36)
f01040ae:	6a 00                	push   $0x0
f01040b0:	6a 24                	push   $0x24
f01040b2:	e9 78 00 00 00       	jmp    f010412f <_alltraps>
f01040b7:	90                   	nop

f01040b8 <handler_37>:
	TRAPHANDLER_NOEC(handler_37, 37)
f01040b8:	6a 00                	push   $0x0
f01040ba:	6a 25                	push   $0x25
f01040bc:	e9 6e 00 00 00       	jmp    f010412f <_alltraps>
f01040c1:	90                   	nop

f01040c2 <handler_38>:
	TRAPHANDLER_NOEC(handler_38, 38)
f01040c2:	6a 00                	push   $0x0
f01040c4:	6a 26                	push   $0x26
f01040c6:	e9 64 00 00 00       	jmp    f010412f <_alltraps>
f01040cb:	90                   	nop

f01040cc <handler_39>:
	TRAPHANDLER_NOEC(handler_39, 39)
f01040cc:	6a 00                	push   $0x0
f01040ce:	6a 27                	push   $0x27
f01040d0:	e9 5a 00 00 00       	jmp    f010412f <_alltraps>
f01040d5:	90                   	nop

f01040d6 <handler_40>:
	TRAPHANDLER_NOEC(handler_40, 40)
f01040d6:	6a 00                	push   $0x0
f01040d8:	6a 28                	push   $0x28
f01040da:	e9 50 00 00 00       	jmp    f010412f <_alltraps>
f01040df:	90                   	nop

f01040e0 <handler_41>:
	TRAPHANDLER_NOEC(handler_41, 41)
f01040e0:	6a 00                	push   $0x0
f01040e2:	6a 29                	push   $0x29
f01040e4:	e9 46 00 00 00       	jmp    f010412f <_alltraps>
f01040e9:	90                   	nop

f01040ea <handler_42>:
	TRAPHANDLER_NOEC(handler_42, 42)
f01040ea:	6a 00                	push   $0x0
f01040ec:	6a 2a                	push   $0x2a
f01040ee:	e9 3c 00 00 00       	jmp    f010412f <_alltraps>
f01040f3:	90                   	nop

f01040f4 <handler_43>:
	TRAPHANDLER_NOEC(handler_43, 43)
f01040f4:	6a 00                	push   $0x0
f01040f6:	6a 2b                	push   $0x2b
f01040f8:	e9 32 00 00 00       	jmp    f010412f <_alltraps>
f01040fd:	90                   	nop

f01040fe <handler_44>:
	TRAPHANDLER_NOEC(handler_44, 44)
f01040fe:	6a 00                	push   $0x0
f0104100:	6a 2c                	push   $0x2c
f0104102:	e9 28 00 00 00       	jmp    f010412f <_alltraps>
f0104107:	90                   	nop

f0104108 <handler_45>:
	TRAPHANDLER_NOEC(handler_45, 45)
f0104108:	6a 00                	push   $0x0
f010410a:	6a 2d                	push   $0x2d
f010410c:	e9 1e 00 00 00       	jmp    f010412f <_alltraps>
f0104111:	90                   	nop

f0104112 <handler_46>:
	TRAPHANDLER_NOEC(handler_46, 46)
f0104112:	6a 00                	push   $0x0
f0104114:	6a 2e                	push   $0x2e
f0104116:	e9 14 00 00 00       	jmp    f010412f <_alltraps>
f010411b:	90                   	nop

f010411c <handler_47>:
	TRAPHANDLER_NOEC(handler_47, 47)
f010411c:	6a 00                	push   $0x0
f010411e:	6a 2f                	push   $0x2f
f0104120:	e9 0a 00 00 00       	jmp    f010412f <_alltraps>
f0104125:	90                   	nop

f0104126 <handler_48>:

	TRAPHANDLER_NOEC(handler_48, 48)   // system call
f0104126:	6a 00                	push   $0x0
f0104128:	6a 30                	push   $0x30
f010412a:	e9 00 00 00 00       	jmp    f010412f <_alltraps>

f010412f <_alltraps>:
 */

.globl _alltraps
_alltraps:
	#Remaining Trap frame
	push %ds
f010412f:	1e                   	push   %ds
	push %es
f0104130:	06                   	push   %es
	pushal
f0104131:	60                   	pusha  

	
	movw $GD_KD, %ax
f0104132:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f0104136:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f0104138:	8e c0                	mov    %eax,%es

	#call Trap 
	pushl %esp
f010413a:	54                   	push   %esp
	call trap
f010413b:	e8 ca fb ff ff       	call   f0103d0a <trap>

f0104140 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0104140:	55                   	push   %ebp
f0104141:	89 e5                	mov    %esp,%ebp
f0104143:	83 ec 08             	sub    $0x8,%esp
f0104146:	a1 6c 92 2a f0       	mov    0xf02a926c,%eax
f010414b:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f010414e:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
f0104153:	8b 02                	mov    (%edx),%eax
f0104155:	83 e8 01             	sub    $0x1,%eax
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0104158:	83 f8 02             	cmp    $0x2,%eax
f010415b:	76 10                	jbe    f010416d <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f010415d:	83 c1 01             	add    $0x1,%ecx
f0104160:	83 c2 7c             	add    $0x7c,%edx
f0104163:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0104169:	75 e8                	jne    f0104153 <sched_halt+0x13>
f010416b:	eb 08                	jmp    f0104175 <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f010416d:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0104173:	75 1f                	jne    f0104194 <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f0104175:	83 ec 0c             	sub    $0xc,%esp
f0104178:	68 d0 82 10 f0       	push   $0xf01082d0
f010417d:	e8 d7 f6 ff ff       	call   f0103859 <cprintf>
f0104182:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f0104185:	83 ec 0c             	sub    $0xc,%esp
f0104188:	6a 00                	push   $0x0
f010418a:	e8 a0 c7 ff ff       	call   f010092f <monitor>
f010418f:	83 c4 10             	add    $0x10,%esp
f0104192:	eb f1                	jmp    f0104185 <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0104194:	e8 de 18 00 00       	call   f0105a77 <cpunum>
f0104199:	6b c0 74             	imul   $0x74,%eax,%eax
f010419c:	c7 80 48 a0 2a f0 00 	movl   $0x0,-0xfd55fb8(%eax)
f01041a3:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f01041a6:	a1 dc 9e 2a f0       	mov    0xf02a9edc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01041ab:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01041b0:	77 12                	ja     f01041c4 <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01041b2:	50                   	push   %eax
f01041b3:	68 48 6b 10 f0       	push   $0xf0106b48
f01041b8:	6a 54                	push   $0x54
f01041ba:	68 f9 82 10 f0       	push   $0xf01082f9
f01041bf:	e8 7c be ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01041c4:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01041c9:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f01041cc:	e8 a6 18 00 00       	call   f0105a77 <cpunum>
f01041d1:	6b d0 74             	imul   $0x74,%eax,%edx
f01041d4:	81 c2 40 a0 2a f0    	add    $0xf02aa040,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f01041da:	b8 02 00 00 00       	mov    $0x2,%eax
f01041df:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01041e3:	83 ec 0c             	sub    $0xc,%esp
f01041e6:	68 c0 44 12 f0       	push   $0xf01244c0
f01041eb:	e8 8f 1b 00 00       	call   f0105d7f <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01041f0:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f01041f2:	e8 80 18 00 00       	call   f0105a77 <cpunum>
f01041f7:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f01041fa:	8b 80 50 a0 2a f0    	mov    -0xfd55fb0(%eax),%eax
f0104200:	bd 00 00 00 00       	mov    $0x0,%ebp
f0104205:	89 c4                	mov    %eax,%esp
f0104207:	6a 00                	push   $0x0
f0104209:	6a 00                	push   $0x0
f010420b:	fb                   	sti    
f010420c:	f4                   	hlt    
f010420d:	eb fd                	jmp    f010420c <sched_halt+0xcc>
f010420f:	83 c4 10             	add    $0x10,%esp
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f0104212:	c9                   	leave  
f0104213:	c3                   	ret    

f0104214 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f0104214:	55                   	push   %ebp
f0104215:	89 e5                	mov    %esp,%ebp
f0104217:	53                   	push   %ebx
f0104218:	83 ec 04             	sub    $0x4,%esp
	// below to halt the cpu.

	// LAB 4: Your code here.
	int envVal, j = 0 ;
	 
	if (curenv)
f010421b:	e8 57 18 00 00       	call   f0105a77 <cpunum>
f0104220:	6b c0 74             	imul   $0x74,%eax,%eax
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
						     // we can use the value 'curenv- envs' to get the current env and +1 to get the next env
	else 
		envVal = 0; 
f0104223:	ba 00 00 00 00       	mov    $0x0,%edx
	// below to halt the cpu.

	// LAB 4: Your code here.
	int envVal, j = 0 ;
	 
	if (curenv)
f0104228:	83 b8 48 a0 2a f0 00 	cmpl   $0x0,-0xfd55fb8(%eax)
f010422f:	74 33                	je     f0104264 <sched_yield+0x50>
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
f0104231:	e8 41 18 00 00       	call   f0105a77 <cpunum>
f0104236:	6b c0 74             	imul   $0x74,%eax,%eax
f0104239:	8b 80 48 a0 2a f0    	mov    -0xfd55fb8(%eax),%eax
f010423f:	2b 05 6c 92 2a f0    	sub    0xf02a926c,%eax
f0104245:	c1 f8 02             	sar    $0x2,%eax
f0104248:	69 c0 df 7b ef bd    	imul   $0xbdef7bdf,%eax,%eax
f010424e:	83 c0 01             	add    $0x1,%eax
f0104251:	89 c1                	mov    %eax,%ecx
f0104253:	c1 f9 1f             	sar    $0x1f,%ecx
f0104256:	c1 e9 16             	shr    $0x16,%ecx
f0104259:	8d 14 08             	lea    (%eax,%ecx,1),%edx
f010425c:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0104262:	29 ca                	sub    %ecx,%edx
	else 
		envVal = 0; 
	
	for (j = 0; j< NENV; j++)
	{
		if (envs[envVal].env_status == ENV_RUNNABLE)
f0104264:	a1 6c 92 2a f0       	mov    0xf02a926c,%eax
f0104269:	b9 00 04 00 00       	mov    $0x400,%ecx
f010426e:	6b da 7c             	imul   $0x7c,%edx,%ebx
f0104271:	83 7c 18 54 02       	cmpl   $0x2,0x54(%eax,%ebx,1)
f0104276:	74 70                	je     f01042e8 <sched_yield+0xd4>
		    break;
		else
		    envVal=(envVal+1)%NENV;
f0104278:	83 c2 01             	add    $0x1,%edx
f010427b:	89 d3                	mov    %edx,%ebx
f010427d:	c1 fb 1f             	sar    $0x1f,%ebx
f0104280:	c1 eb 16             	shr    $0x16,%ebx
f0104283:	01 da                	add    %ebx,%edx
f0104285:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010428b:	29 da                	sub    %ebx,%edx
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
						     // we can use the value 'curenv- envs' to get the current env and +1 to get the next env
	else 
		envVal = 0; 
	
	for (j = 0; j< NENV; j++)
f010428d:	83 e9 01             	sub    $0x1,%ecx
f0104290:	75 dc                	jne    f010426e <sched_yield+0x5a>
		    break;
		else
		    envVal=(envVal+1)%NENV;
	}
	
	if (envs[envVal].env_status == ENV_RUNNABLE)
f0104292:	6b d2 7c             	imul   $0x7c,%edx,%edx
f0104295:	01 c2                	add    %eax,%edx
f0104297:	83 7a 54 02          	cmpl   $0x2,0x54(%edx)
f010429b:	75 09                	jne    f01042a6 <sched_yield+0x92>
	{
	    idle = envs + envVal ;
	    env_run(idle);
f010429d:	83 ec 0c             	sub    $0xc,%esp
f01042a0:	52                   	push   %edx
f01042a1:	e8 78 f3 ff ff       	call   f010361e <env_run>
	} 
	else if (!idle && (curenv) && (curenv->env_status == ENV_RUNNING) ){
f01042a6:	e8 cc 17 00 00       	call   f0105a77 <cpunum>
f01042ab:	6b c0 74             	imul   $0x74,%eax,%eax
f01042ae:	83 b8 48 a0 2a f0 00 	cmpl   $0x0,-0xfd55fb8(%eax)
f01042b5:	74 2a                	je     f01042e1 <sched_yield+0xcd>
f01042b7:	e8 bb 17 00 00       	call   f0105a77 <cpunum>
f01042bc:	6b c0 74             	imul   $0x74,%eax,%eax
f01042bf:	8b 80 48 a0 2a f0    	mov    -0xfd55fb8(%eax),%eax
f01042c5:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01042c9:	75 16                	jne    f01042e1 <sched_yield+0xcd>
	    env_run(curenv) ;
f01042cb:	e8 a7 17 00 00       	call   f0105a77 <cpunum>
f01042d0:	83 ec 0c             	sub    $0xc,%esp
f01042d3:	6b c0 74             	imul   $0x74,%eax,%eax
f01042d6:	ff b0 48 a0 2a f0    	pushl  -0xfd55fb8(%eax)
f01042dc:	e8 3d f3 ff ff       	call   f010361e <env_run>
	}
	// sched_halt never returns
	sched_halt();
f01042e1:	e8 5a fe ff ff       	call   f0104140 <sched_halt>
f01042e6:	eb 07                	jmp    f01042ef <sched_yield+0xdb>
		    break;
		else
		    envVal=(envVal+1)%NENV;
	}
	
	if (envs[envVal].env_status == ENV_RUNNABLE)
f01042e8:	6b d2 7c             	imul   $0x7c,%edx,%edx
f01042eb:	01 c2                	add    %eax,%edx
f01042ed:	eb ae                	jmp    f010429d <sched_yield+0x89>
	else if (!idle && (curenv) && (curenv->env_status == ENV_RUNNING) ){
	    env_run(curenv) ;
	}
	// sched_halt never returns
	sched_halt();
}
f01042ef:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01042f2:	c9                   	leave  
f01042f3:	c3                   	ret    

f01042f4 <syscall>:


// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01042f4:	55                   	push   %ebp
f01042f5:	89 e5                	mov    %esp,%ebp
f01042f7:	57                   	push   %edi
f01042f8:	56                   	push   %esi
f01042f9:	53                   	push   %ebx
f01042fa:	83 ec 1c             	sub    $0x1c,%esp
f01042fd:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	

	switch (syscallno) {
f0104300:	83 f8 10             	cmp    $0x10,%eax
f0104303:	0f 87 7f 05 00 00    	ja     f0104888 <syscall+0x594>
f0104309:	ff 24 85 74 83 10 f0 	jmp    *-0xfef7c8c(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_P | PTE_U);
f0104310:	e8 62 17 00 00       	call   f0105a77 <cpunum>
f0104315:	6a 05                	push   $0x5
f0104317:	ff 75 10             	pushl  0x10(%ebp)
f010431a:	ff 75 0c             	pushl  0xc(%ebp)
f010431d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104320:	ff b0 48 a0 2a f0    	pushl  -0xfd55fb8(%eax)
f0104326:	e8 23 ec ff ff       	call   f0102f4e <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f010432b:	83 c4 0c             	add    $0xc,%esp
f010432e:	ff 75 0c             	pushl  0xc(%ebp)
f0104331:	ff 75 10             	pushl  0x10(%ebp)
f0104334:	68 06 83 10 f0       	push   $0xf0108306
f0104339:	e8 1b f5 ff ff       	call   f0103859 <cprintf>
f010433e:	83 c4 10             	add    $0x10,%esp

	switch (syscallno) {

	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;
f0104341:	b8 00 00 00 00       	mov    $0x0,%eax
f0104346:	e9 67 05 00 00       	jmp    f01048b2 <syscall+0x5be>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f010434b:	e8 c5 c2 ff ff       	call   f0100615 <cons_getc>
	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;

	case SYS_cgetc:
		return sys_cgetc();
f0104350:	e9 5d 05 00 00       	jmp    f01048b2 <syscall+0x5be>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0104355:	e8 1d 17 00 00       	call   f0105a77 <cpunum>
f010435a:	6b c0 74             	imul   $0x74,%eax,%eax
f010435d:	8b 80 48 a0 2a f0    	mov    -0xfd55fb8(%eax),%eax
f0104363:	8b 40 48             	mov    0x48(%eax),%eax

	case SYS_cgetc:
		return sys_cgetc();
		
	case SYS_getenvid:
		return sys_getenvid();
f0104366:	e9 47 05 00 00       	jmp    f01048b2 <syscall+0x5be>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f010436b:	83 ec 04             	sub    $0x4,%esp
f010436e:	6a 01                	push   $0x1
f0104370:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104373:	50                   	push   %eax
f0104374:	ff 75 0c             	pushl  0xc(%ebp)
f0104377:	e8 a2 ec ff ff       	call   f010301e <envid2env>
f010437c:	89 c2                	mov    %eax,%edx
f010437e:	83 c4 10             	add    $0x10,%esp
f0104381:	85 d2                	test   %edx,%edx
f0104383:	0f 88 29 05 00 00    	js     f01048b2 <syscall+0x5be>
		return r;
	env_destroy(e);
f0104389:	83 ec 0c             	sub    $0xc,%esp
f010438c:	ff 75 e4             	pushl  -0x1c(%ebp)
f010438f:	e8 eb f1 ff ff       	call   f010357f <env_destroy>
f0104394:	83 c4 10             	add    $0x10,%esp
	return 0;
f0104397:	b8 00 00 00 00       	mov    $0x0,%eax
f010439c:	e9 11 05 00 00       	jmp    f01048b2 <syscall+0x5be>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f01043a1:	e8 6e fe ff ff       	call   f0104214 <sched_yield>
	// from the current environment -- but tweaked so sys_exofork
	// will appear to return 0.

	// LAB 4: Your code here.
	struct Env* childenv;
	int errcode = env_alloc(&childenv, curenv->env_id);
f01043a6:	e8 cc 16 00 00       	call   f0105a77 <cpunum>
f01043ab:	83 ec 08             	sub    $0x8,%esp
f01043ae:	6b c0 74             	imul   $0x74,%eax,%eax
f01043b1:	8b 80 48 a0 2a f0    	mov    -0xfd55fb8(%eax),%eax
f01043b7:	ff 70 48             	pushl  0x48(%eax)
f01043ba:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01043bd:	50                   	push   %eax
f01043be:	e8 66 ed ff ff       	call   f0103129 <env_alloc>
f01043c3:	89 c2                	mov    %eax,%edx
	
	//If the error code is less than 0, that means there has been an error while creating an env	
	if (errcode < 0) {
f01043c5:	83 c4 10             	add    $0x10,%esp
f01043c8:	85 d2                	test   %edx,%edx
f01043ca:	0f 88 e2 04 00 00    	js     f01048b2 <syscall+0x5be>
		return errcode; //Return the environment
	}
	
	//Set the child environment as not runnable	
	childenv->env_status = ENV_NOT_RUNNABLE;
f01043d0:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01043d3:	c7 43 54 04 00 00 00 	movl   $0x4,0x54(%ebx)

	//Copy the current environemnt register data into the child
	childenv->env_tf = curenv->env_tf;
f01043da:	e8 98 16 00 00       	call   f0105a77 <cpunum>
f01043df:	6b c0 74             	imul   $0x74,%eax,%eax
f01043e2:	8b b0 48 a0 2a f0    	mov    -0xfd55fb8(%eax),%esi
f01043e8:	b9 11 00 00 00       	mov    $0x11,%ecx
f01043ed:	89 df                	mov    %ebx,%edi
f01043ef:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

	// when the child is scheduled to run, it has to restart the trapframe. 
	//Hence we modify the register eax to be 0. 

	childenv->env_tf.tf_regs.reg_eax = 0; 
f01043f1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01043f4:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

	return childenv->env_id;
f01043fb:	8b 40 48             	mov    0x48(%eax),%eax
f01043fe:	e9 af 04 00 00       	jmp    f01048b2 <syscall+0x5be>

	// LAB 4: Your code here.
	
	struct Env *env_store;
	int errcode; 
	errcode = envid2env(envid, &env_store,1);
f0104403:	83 ec 04             	sub    $0x4,%esp
f0104406:	6a 01                	push   $0x1
f0104408:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010440b:	50                   	push   %eax
f010440c:	ff 75 0c             	pushl  0xc(%ebp)
f010440f:	e8 0a ec ff ff       	call   f010301e <envid2env>
	if (errcode < 0)
f0104414:	83 c4 10             	add    $0x10,%esp
f0104417:	85 c0                	test   %eax,%eax
f0104419:	0f 88 93 04 00 00    	js     f01048b2 <syscall+0x5be>
		return errcode;
	
	//Check if status is runnable or not runnable
	if (status == ENV_RUNNABLE || status == ENV_NOT_RUNNABLE)
f010441f:	8b 45 10             	mov    0x10(%ebp),%eax
f0104422:	8d 50 fe             	lea    -0x2(%eax),%edx
		env_store->env_status = status;

	else
		return E_INVAL;
f0104425:	b8 03 00 00 00       	mov    $0x3,%eax
	errcode = envid2env(envid, &env_store,1);
	if (errcode < 0)
		return errcode;
	
	//Check if status is runnable or not runnable
	if (status == ENV_RUNNABLE || status == ENV_NOT_RUNNABLE)
f010442a:	f7 c2 fd ff ff ff    	test   $0xfffffffd,%edx
f0104430:	0f 85 7c 04 00 00    	jne    f01048b2 <syscall+0x5be>
		env_store->env_status = status;
f0104436:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104439:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010443c:	89 58 54             	mov    %ebx,0x54(%eax)

	else
		return E_INVAL;

	return 0;
f010443f:	b8 00 00 00 00       	mov    $0x0,%eax
f0104444:	e9 69 04 00 00       	jmp    f01048b2 <syscall+0x5be>
	struct Env *en; 
	int code;
	
	//Check for valid address and page alignment
	if((((uint32_t)va) >= UTOP) || (((uint32_t)va) % PGSIZE) !=0)
		return  E_INVAL;
f0104449:	b8 03 00 00 00       	mov    $0x3,%eax
	
	struct Env *en; 
	int code;
	
	//Check for valid address and page alignment
	if((((uint32_t)va) >= UTOP) || (((uint32_t)va) % PGSIZE) !=0)
f010444e:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104455:	0f 87 57 04 00 00    	ja     f01048b2 <syscall+0x5be>
f010445b:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104462:	0f 85 4a 04 00 00    	jne    f01048b2 <syscall+0x5be>
		return  E_INVAL;

	//Check for permissions
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
f0104468:	f7 45 14 fd f1 ff ff 	testl  $0xfffff1fd,0x14(%ebp)
f010446f:	0f 84 3d 04 00 00    	je     f01048b2 <syscall+0x5be>
		return E_INVAL;

	//Page allocation check
	struct PageInfo *newpage = page_alloc(ALLOC_ZERO); 
f0104475:	83 ec 0c             	sub    $0xc,%esp
f0104478:	6a 01                	push   $0x1
f010447a:	e8 74 cb ff ff       	call   f0100ff3 <page_alloc>
f010447f:	89 c3                	mov    %eax,%ebx
	if (!newpage)
f0104481:	83 c4 10             	add    $0x10,%esp
		return E_NO_MEM; 
f0104484:	b8 04 00 00 00       	mov    $0x4,%eax
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
		return E_INVAL;

	//Page allocation check
	struct PageInfo *newpage = page_alloc(ALLOC_ZERO); 
	if (!newpage)
f0104489:	85 db                	test   %ebx,%ebx
f010448b:	0f 84 21 04 00 00    	je     f01048b2 <syscall+0x5be>
		return E_NO_MEM; 

	//Use environid to get the environment 
	if ((code = envid2env(envid, &en,1))<0)
f0104491:	83 ec 04             	sub    $0x4,%esp
f0104494:	6a 01                	push   $0x1
f0104496:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104499:	50                   	push   %eax
f010449a:	ff 75 0c             	pushl  0xc(%ebp)
f010449d:	e8 7c eb ff ff       	call   f010301e <envid2env>
f01044a2:	83 c4 10             	add    $0x10,%esp
f01044a5:	85 c0                	test   %eax,%eax
f01044a7:	0f 88 05 04 00 00    	js     f01048b2 <syscall+0x5be>
		return code;

	//Check if the page mapping is correct otherwise free the page
	code=page_insert(en->env_pgdir,newpage,(void *)va,perm);
f01044ad:	ff 75 14             	pushl  0x14(%ebp)
f01044b0:	ff 75 10             	pushl  0x10(%ebp)
f01044b3:	53                   	push   %ebx
f01044b4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01044b7:	ff 70 60             	pushl  0x60(%eax)
f01044ba:	e8 5a ce ff ff       	call   f0101319 <page_insert>
f01044bf:	89 c6                	mov    %eax,%esi
	if (code < 0)
f01044c1:	83 c4 10             	add    $0x10,%esp
	{
		page_free(newpage);
		return code;
	}
	
	return 0;
f01044c4:	b8 00 00 00 00       	mov    $0x0,%eax
	if ((code = envid2env(envid, &en,1))<0)
		return code;

	//Check if the page mapping is correct otherwise free the page
	code=page_insert(en->env_pgdir,newpage,(void *)va,perm);
	if (code < 0)
f01044c9:	85 f6                	test   %esi,%esi
f01044cb:	0f 89 e1 03 00 00    	jns    f01048b2 <syscall+0x5be>
	{
		page_free(newpage);
f01044d1:	83 ec 0c             	sub    $0xc,%esp
f01044d4:	53                   	push   %ebx
f01044d5:	e8 8f cb ff ff       	call   f0101069 <page_free>
f01044da:	83 c4 10             	add    $0x10,%esp
		return code;
f01044dd:	89 f0                	mov    %esi,%eax
f01044df:	e9 ce 03 00 00       	jmp    f01048b2 <syscall+0x5be>
	struct Env* src_env;
	struct Env* dst_env;
	int errcode;
	
	//Check for valid src env id
	errcode = envid2env(srcenvid, &src_env, 1);
f01044e4:	83 ec 04             	sub    $0x4,%esp
f01044e7:	6a 01                	push   $0x1
f01044e9:	8d 45 dc             	lea    -0x24(%ebp),%eax
f01044ec:	50                   	push   %eax
f01044ed:	ff 75 0c             	pushl  0xc(%ebp)
f01044f0:	e8 29 eb ff ff       	call   f010301e <envid2env>
f01044f5:	89 c2                	mov    %eax,%edx
	if (errcode < 0) 
f01044f7:	83 c4 10             	add    $0x10,%esp
f01044fa:	85 d2                	test   %edx,%edx
f01044fc:	0f 88 b0 03 00 00    	js     f01048b2 <syscall+0x5be>
		return errcode;
	
	//Check for valid des env id
	errcode = envid2env(dstenvid, &dst_env, 1);
f0104502:	83 ec 04             	sub    $0x4,%esp
f0104505:	6a 01                	push   $0x1
f0104507:	8d 45 e0             	lea    -0x20(%ebp),%eax
f010450a:	50                   	push   %eax
f010450b:	ff 75 14             	pushl  0x14(%ebp)
f010450e:	e8 0b eb ff ff       	call   f010301e <envid2env>
	if (errcode < 0) 
f0104513:	83 c4 10             	add    $0x10,%esp
f0104516:	85 c0                	test   %eax,%eax
f0104518:	0f 88 94 03 00 00    	js     f01048b2 <syscall+0x5be>
		return errcode;
	
	//Check if the address is below UTOP
	if (((uint32_t)srcva) >= UTOP || ((uint32_t)dstva) >= UTOP) 
f010451e:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104525:	77 6d                	ja     f0104594 <syscall+0x2a0>
f0104527:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f010452e:	77 64                	ja     f0104594 <syscall+0x2a0>
f0104530:	8b 45 10             	mov    0x10(%ebp),%eax
f0104533:	0b 45 18             	or     0x18(%ebp),%eax
		return -E_INVAL;
	
	//Checking if the address is page aligned
	if ((((uint32_t)srcva)%PGSIZE != 0) || (((uint32_t)dstva)%PGSIZE != 0)) 
f0104536:	a9 ff 0f 00 00       	test   $0xfff,%eax
f010453b:	75 61                	jne    f010459e <syscall+0x2aa>
		return -E_INVAL;

	// find the page corresponding to srcva in src_e
	pte_t* pte_src;

	struct PageInfo* srcPage = page_lookup(src_env->env_pgdir, srcva, &pte_src);
f010453d:	83 ec 04             	sub    $0x4,%esp
f0104540:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104543:	50                   	push   %eax
f0104544:	ff 75 10             	pushl  0x10(%ebp)
f0104547:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010454a:	ff 70 60             	pushl  0x60(%eax)
f010454d:	e8 01 cd ff ff       	call   f0101253 <page_lookup>
	if (!srcPage) 
f0104552:	83 c4 10             	add    $0x10,%esp
f0104555:	85 c0                	test   %eax,%eax
f0104557:	74 4f                	je     f01045a8 <syscall+0x2b4>
		return -E_INVAL;
	

	//Check for permissions
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
f0104559:	f7 45 1c fd f1 ff ff 	testl  $0xfffff1fd,0x1c(%ebp)
f0104560:	74 50                	je     f01045b2 <syscall+0x2be>
		return -E_INVAL; 	
	

	// the page is not writable but write permission is set	
	if (!(*pte_src & PTE_W) && (perm & PTE_W)) {
f0104562:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104565:	f6 02 02             	testb  $0x2,(%edx)
f0104568:	75 06                	jne    f0104570 <syscall+0x27c>
f010456a:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f010456e:	75 4c                	jne    f01045bc <syscall+0x2c8>
		return -E_INVAL;
	}

	// mapping
	errcode = page_insert(dst_env->env_pgdir, srcPage, dstva, perm);
f0104570:	ff 75 1c             	pushl  0x1c(%ebp)
f0104573:	ff 75 18             	pushl  0x18(%ebp)
f0104576:	50                   	push   %eax
f0104577:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010457a:	ff 70 60             	pushl  0x60(%eax)
f010457d:	e8 97 cd ff ff       	call   f0101319 <page_insert>
f0104582:	83 c4 10             	add    $0x10,%esp
f0104585:	85 c0                	test   %eax,%eax
f0104587:	ba 00 00 00 00       	mov    $0x0,%edx
f010458c:	0f 4f c2             	cmovg  %edx,%eax
f010458f:	e9 1e 03 00 00       	jmp    f01048b2 <syscall+0x5be>
	if (errcode < 0) 
		return errcode;
	
	//Check if the address is below UTOP
	if (((uint32_t)srcva) >= UTOP || ((uint32_t)dstva) >= UTOP) 
		return -E_INVAL;
f0104594:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104599:	e9 14 03 00 00       	jmp    f01048b2 <syscall+0x5be>
	
	//Checking if the address is page aligned
	if ((((uint32_t)srcva)%PGSIZE != 0) || (((uint32_t)dstva)%PGSIZE != 0)) 
		return -E_INVAL;
f010459e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01045a3:	e9 0a 03 00 00       	jmp    f01048b2 <syscall+0x5be>
	// find the page corresponding to srcva in src_e
	pte_t* pte_src;

	struct PageInfo* srcPage = page_lookup(src_env->env_pgdir, srcva, &pte_src);
	if (!srcPage) 
		return -E_INVAL;
f01045a8:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01045ad:	e9 00 03 00 00       	jmp    f01048b2 <syscall+0x5be>
	

	//Check for permissions
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
		return -E_INVAL; 	
f01045b2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01045b7:	e9 f6 02 00 00       	jmp    f01048b2 <syscall+0x5be>
	

	// the page is not writable but write permission is set	
	if (!(*pte_src & PTE_W) && (perm & PTE_W)) {
		return -E_INVAL;
f01045bc:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	case SYS_page_alloc:
		return sys_page_alloc( (envid_t)a1, (void *)a2, (int)a3);
	
	case SYS_page_map:
		return sys_page_map( (envid_t)a1, (void *)a2,
f01045c1:	e9 ec 02 00 00       	jmp    f01048b2 <syscall+0x5be>
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	struct Env* en;
	//Check for valid envid
	int errcode = envid2env(envid, &en, 1);
f01045c6:	83 ec 04             	sub    $0x4,%esp
f01045c9:	6a 01                	push   $0x1
f01045cb:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01045ce:	50                   	push   %eax
f01045cf:	ff 75 0c             	pushl  0xc(%ebp)
f01045d2:	e8 47 ea ff ff       	call   f010301e <envid2env>
	if (errcode < 0){ 
f01045d7:	83 c4 10             	add    $0x10,%esp
f01045da:	85 c0                	test   %eax,%eax
f01045dc:	0f 88 d0 02 00 00    	js     f01048b2 <syscall+0x5be>
		return errcode;
	}
	
	//Checkfor valid address and page alignment
	if ((((uint32_t)va) >= UTOP) ||(((uint32_t)va)%PGSIZE != 0 ) ) {
f01045e2:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f01045e9:	77 27                	ja     f0104612 <syscall+0x31e>
f01045eb:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f01045f2:	75 28                	jne    f010461c <syscall+0x328>
		return -E_INVAL;
	}

	page_remove(en->env_pgdir, va);
f01045f4:	83 ec 08             	sub    $0x8,%esp
f01045f7:	ff 75 10             	pushl  0x10(%ebp)
f01045fa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01045fd:	ff 70 60             	pushl  0x60(%eax)
f0104600:	e8 ce cc ff ff       	call   f01012d3 <page_remove>
f0104605:	83 c4 10             	add    $0x10,%esp

	return 0;
f0104608:	b8 00 00 00 00       	mov    $0x0,%eax
f010460d:	e9 a0 02 00 00       	jmp    f01048b2 <syscall+0x5be>
		return errcode;
	}
	
	//Checkfor valid address and page alignment
	if ((((uint32_t)va) >= UTOP) ||(((uint32_t)va)%PGSIZE != 0 ) ) {
		return -E_INVAL;
f0104612:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104617:	e9 96 02 00 00       	jmp    f01048b2 <syscall+0x5be>
f010461c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	case SYS_page_map:
		return sys_page_map( (envid_t)a1, (void *)a2,
	     (envid_t) a3, (void *)a4, (int )a5);

	case SYS_page_unmap:
		return sys_page_unmap((envid_t)a1, (void *)a2);	
f0104621:	e9 8c 02 00 00       	jmp    f01048b2 <syscall+0x5be>
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here. //Exercise 8 code
	struct Env* en;
	int errcode = envid2env(envid, &en, 1);
f0104626:	83 ec 04             	sub    $0x4,%esp
f0104629:	6a 01                	push   $0x1
f010462b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010462e:	50                   	push   %eax
f010462f:	ff 75 0c             	pushl  0xc(%ebp)
f0104632:	e8 e7 e9 ff ff       	call   f010301e <envid2env>
	if (errcode < 0) {
f0104637:	83 c4 10             	add    $0x10,%esp
f010463a:	85 c0                	test   %eax,%eax
f010463c:	0f 88 70 02 00 00    	js     f01048b2 <syscall+0x5be>
		return errcode;
	}

	//Set the pgfault_upcall to func
	en->env_pgfault_upcall = func;
f0104642:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104645:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104648:	89 78 64             	mov    %edi,0x64(%eax)
	return 0;
f010464b:	b8 00 00 00 00       	mov    $0x0,%eax
f0104650:	e9 5d 02 00 00       	jmp    f01048b2 <syscall+0x5be>
	// LAB 4: Your code here.
	int r; 
	struct Env* target_env; 
	
	//Bad Environment
	if ((r = envid2env(envid, &target_env, 0)) < 0)
f0104655:	83 ec 04             	sub    $0x4,%esp
f0104658:	6a 00                	push   $0x0
f010465a:	8d 45 e0             	lea    -0x20(%ebp),%eax
f010465d:	50                   	push   %eax
f010465e:	ff 75 0c             	pushl  0xc(%ebp)
f0104661:	e8 b8 e9 ff ff       	call   f010301e <envid2env>
f0104666:	83 c4 10             	add    $0x10,%esp
f0104669:	85 c0                	test   %eax,%eax
f010466b:	0f 88 0d 01 00 00    	js     f010477e <syscall+0x48a>
		return -E_BAD_ENV; 
	
	//If target is not receiving
	if(!target_env->env_ipc_recving)
f0104671:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104674:	80 78 68 00          	cmpb   $0x0,0x68(%eax)
f0104678:	0f 84 0a 01 00 00    	je     f0104788 <syscall+0x494>
		return -E_IPC_NOT_RECV;
	
	//If src and dst addesses are below UTOP
	if (((uint32_t)srcva) < UTOP && (uint32_t)target_env->env_ipc_dstva < UTOP)
f010467e:	81 7d 14 ff ff bf ee 	cmpl   $0xeebfffff,0x14(%ebp)
f0104685:	0f 87 b0 00 00 00    	ja     f010473b <syscall+0x447>
f010468b:	81 78 6c ff ff bf ee 	cmpl   $0xeebfffff,0x6c(%eax)
f0104692:	0f 87 a3 00 00 00    	ja     f010473b <syscall+0x447>
	{
		
		//Check if srcva is page aligned
		if ((uint32_t)srcva % PGSIZE !=0)
			return -E_INVAL;
f0104698:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	//If src and dst addesses are below UTOP
	if (((uint32_t)srcva) < UTOP && (uint32_t)target_env->env_ipc_dstva < UTOP)
	{
		
		//Check if srcva is page aligned
		if ((uint32_t)srcva % PGSIZE !=0)
f010469d:	f7 45 14 ff 0f 00 00 	testl  $0xfff,0x14(%ebp)
f01046a4:	0f 85 08 02 00 00    	jne    f01048b2 <syscall+0x5be>
			return -E_INVAL;
	
		//Check for permissions
		if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
f01046aa:	f7 45 18 fd f1 ff ff 	testl  $0xfffff1fd,0x18(%ebp)
f01046b1:	0f 84 fb 01 00 00    	je     f01048b2 <syscall+0x5be>
			return -E_INVAL;

		struct PageInfo* srcpage = NULL;

		pte_t* pte = NULL;
f01046b7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		//Lookup the page and get a pte
		if (!(srcpage = page_lookup(curenv->env_pgdir, srcva,&pte)))
f01046be:	e8 b4 13 00 00       	call   f0105a77 <cpunum>
f01046c3:	83 ec 04             	sub    $0x4,%esp
f01046c6:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01046c9:	52                   	push   %edx
f01046ca:	ff 75 14             	pushl  0x14(%ebp)
f01046cd:	6b c0 74             	imul   $0x74,%eax,%eax
f01046d0:	8b 80 48 a0 2a f0    	mov    -0xfd55fb8(%eax),%eax
f01046d6:	ff 70 60             	pushl  0x60(%eax)
f01046d9:	e8 75 cb ff ff       	call   f0101253 <page_lookup>
f01046de:	89 c2                	mov    %eax,%edx
f01046e0:	83 c4 10             	add    $0x10,%esp
f01046e3:	85 c0                	test   %eax,%eax
f01046e5:	74 40                	je     f0104727 <syscall+0x433>
			return -E_INVAL;
		
		//if (perm & PTE_W), but srcva is read-only in the
		//current environment's address space.
		if ((perm & PTE_W) && !(*pte & PTE_W))
f01046e7:	f6 45 18 02          	testb  $0x2,0x18(%ebp)
f01046eb:	74 11                	je     f01046fe <syscall+0x40a>
			return -E_INVAL; 
f01046ed:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		if (!(srcpage = page_lookup(curenv->env_pgdir, srcva,&pte)))
			return -E_INVAL;
		
		//if (perm & PTE_W), but srcva is read-only in the
		//current environment's address space.
		if ((perm & PTE_W) && !(*pte & PTE_W))
f01046f2:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01046f5:	f6 01 02             	testb  $0x2,(%ecx)
f01046f8:	0f 84 b4 01 00 00    	je     f01048b2 <syscall+0x5be>
			return -E_INVAL; 
		
		//Page mappingto destination
		if (target_env->env_ipc_dstva)
f01046fe:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104701:	8b 48 6c             	mov    0x6c(%eax),%ecx
f0104704:	85 c9                	test   %ecx,%ecx
f0104706:	74 14                	je     f010471c <syscall+0x428>
		{
			//map the page
			if ((r = page_insert(target_env->env_pgdir, srcpage, (void *)target_env->env_ipc_dstva,perm) )< 0)
f0104708:	ff 75 18             	pushl  0x18(%ebp)
f010470b:	51                   	push   %ecx
f010470c:	52                   	push   %edx
f010470d:	ff 70 60             	pushl  0x60(%eax)
f0104710:	e8 04 cc ff ff       	call   f0101319 <page_insert>
f0104715:	83 c4 10             	add    $0x10,%esp
f0104718:	85 c0                	test   %eax,%eax
f010471a:	78 15                	js     f0104731 <syscall+0x43d>
				return -E_NO_MEM;
			
		}
		
		target_env->env_ipc_perm = perm; // is set to 'perm' if a page was transferred, 0 otherwise. 
f010471c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010471f:	8b 5d 18             	mov    0x18(%ebp),%ebx
f0104722:	89 58 78             	mov    %ebx,0x78(%eax)
f0104725:	eb 1b                	jmp    f0104742 <syscall+0x44e>
		struct PageInfo* srcpage = NULL;

		pte_t* pte = NULL;
		//Lookup the page and get a pte
		if (!(srcpage = page_lookup(curenv->env_pgdir, srcva,&pte)))
			return -E_INVAL;
f0104727:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010472c:	e9 81 01 00 00       	jmp    f01048b2 <syscall+0x5be>
		//Page mappingto destination
		if (target_env->env_ipc_dstva)
		{
			//map the page
			if ((r = page_insert(target_env->env_pgdir, srcpage, (void *)target_env->env_ipc_dstva,perm) )< 0)
				return -E_NO_MEM;
f0104731:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0104736:	e9 77 01 00 00       	jmp    f01048b2 <syscall+0x5be>
		}
		
		target_env->env_ipc_perm = perm; // is set to 'perm' if a page was transferred, 0 otherwise. 
	}
	else{
		target_env->env_ipc_perm = 0; //  0 otherwise. 
f010473b:	c7 40 78 00 00 00 00 	movl   $0x0,0x78(%eax)
	}
	
	target_env->env_ipc_recving  = 0; //is set to 0 to block future sends
f0104742:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104745:	c6 43 68 00          	movb   $0x0,0x68(%ebx)
	target_env->env_ipc_from = curenv->env_id; // is set to the sending envid;
f0104749:	e8 29 13 00 00       	call   f0105a77 <cpunum>
f010474e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104751:	8b 80 48 a0 2a f0    	mov    -0xfd55fb8(%eax),%eax
f0104757:	8b 40 48             	mov    0x48(%eax),%eax
f010475a:	89 43 74             	mov    %eax,0x74(%ebx)
	target_env->env_tf.tf_regs.reg_eax = 0;
f010475d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104760:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	target_env->env_ipc_value = value; // is set to the 'value' parameter;
f0104767:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010476a:	89 48 70             	mov    %ecx,0x70(%eax)
	target_env->env_status = ENV_RUNNABLE; 
f010476d:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	
	return 0;
f0104774:	b8 00 00 00 00       	mov    $0x0,%eax
f0104779:	e9 34 01 00 00       	jmp    f01048b2 <syscall+0x5be>
	int r; 
	struct Env* target_env; 
	
	//Bad Environment
	if ((r = envid2env(envid, &target_env, 0)) < 0)
		return -E_BAD_ENV; 
f010477e:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0104783:	e9 2a 01 00 00       	jmp    f01048b2 <syscall+0x5be>
	
	//If target is not receiving
	if(!target_env->env_ipc_recving)
		return -E_IPC_NOT_RECV;
f0104788:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax

	case SYS_env_set_pgfault_upcall:
		return sys_env_set_pgfault_upcall((envid_t) a1, (void *)a2);

	case SYS_ipc_try_send:
		return sys_ipc_try_send(a1,a2,(void*)a3, a4);
f010478d:	e9 20 01 00 00       	jmp    f01048b2 <syscall+0x5be>
	//panic("sys_ipc_recv not implemented");

	//check if dstva is below UTOP
	
	
	if ((uint32_t)dstva < UTOP)
f0104792:	81 7d 0c ff ff bf ee 	cmpl   $0xeebfffff,0xc(%ebp)
f0104799:	77 21                	ja     f01047bc <syscall+0x4c8>
	{
		if ((uint32_t)dstva % PGSIZE !=0)
f010479b:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
f01047a2:	0f 85 f7 00 00 00    	jne    f010489f <syscall+0x5ab>
			return -E_INVAL;
		curenv->env_ipc_dstva = dstva;
f01047a8:	e8 ca 12 00 00       	call   f0105a77 <cpunum>
f01047ad:	6b c0 74             	imul   $0x74,%eax,%eax
f01047b0:	8b 80 48 a0 2a f0    	mov    -0xfd55fb8(%eax),%eax
f01047b6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01047b9:	89 58 6c             	mov    %ebx,0x6c(%eax)
	}
	
	//Enable receiving
	curenv->env_ipc_recving = 1;
f01047bc:	e8 b6 12 00 00       	call   f0105a77 <cpunum>
f01047c1:	6b c0 74             	imul   $0x74,%eax,%eax
f01047c4:	8b 80 48 a0 2a f0    	mov    -0xfd55fb8(%eax),%eax
f01047ca:	c6 40 68 01          	movb   $0x1,0x68(%eax)
	curenv->env_status = ENV_NOT_RUNNABLE;
f01047ce:	e8 a4 12 00 00       	call   f0105a77 <cpunum>
f01047d3:	6b c0 74             	imul   $0x74,%eax,%eax
f01047d6:	8b 80 48 a0 2a f0    	mov    -0xfd55fb8(%eax),%eax
f01047dc:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	sched_yield();
f01047e3:	e8 2c fa ff ff       	call   f0104214 <sched_yield>

	case SYS_ipc_recv:
		return sys_ipc_recv((void*)a1);

	case SYS_env_set_trapframe:
		return sys_env_set_trapframe(a1, (struct Trapframe *)a2);
f01047e8:	8b 75 10             	mov    0x10(%ebp),%esi
	struct Env *e;
	int r;

	//user_mem_assert(curenv, tf, sizeof(struct Trapframe), 0);
	
	if  ( (r= envid2env(envid, &e, 1)) < 0 ) {
f01047eb:	83 ec 04             	sub    $0x4,%esp
f01047ee:	6a 01                	push   $0x1
f01047f0:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01047f3:	50                   	push   %eax
f01047f4:	ff 75 0c             	pushl  0xc(%ebp)
f01047f7:	e8 22 e8 ff ff       	call   f010301e <envid2env>
f01047fc:	83 c4 10             	add    $0x10,%esp
f01047ff:	85 c0                	test   %eax,%eax
f0104801:	79 15                	jns    f0104818 <syscall+0x524>
	    panic("Bad or stale environment in kern/syscall.c/sys_env_set_st : %e \n",r); 
f0104803:	50                   	push   %eax
f0104804:	68 30 83 10 f0       	push   $0xf0108330
f0104809:	68 a4 00 00 00       	push   $0xa4
f010480e:	68 0b 83 10 f0       	push   $0xf010830b
f0104813:	e8 28 b8 ff ff       	call   f0100040 <_panic>
	    return r;	
	}
	e->env_tf = *tf;
f0104818:	b9 11 00 00 00       	mov    $0x11,%ecx
f010481d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104820:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	e->env_tf.tf_ds |= 3;
f0104822:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104825:	66 83 48 24 03       	orw    $0x3,0x24(%eax)
	e->env_tf.tf_es |= 3;
f010482a:	66 83 48 20 03       	orw    $0x3,0x20(%eax)
	e->env_tf.tf_ss |= 3;
f010482f:	66 83 48 40 03       	orw    $0x3,0x40(%eax)
	e->env_tf.tf_cs |= 3;
f0104834:	66 83 48 34 03       	orw    $0x3,0x34(%eax)
	// Make sure CPL = 3, interrupts enabled.
	e->env_tf.tf_eflags |= FL_IF;
	e->env_tf.tf_eflags &= ~(FL_IOPL_MASK);
f0104839:	8b 50 38             	mov    0x38(%eax),%edx
f010483c:	80 e6 cf             	and    $0xcf,%dh
f010483f:	80 ce 02             	or     $0x2,%dh
f0104842:	89 50 38             	mov    %edx,0x38(%eax)

	case SYS_ipc_recv:
		return sys_ipc_recv((void*)a1);

	case SYS_env_set_trapframe:
		return sys_env_set_trapframe(a1, (struct Trapframe *)a2);
f0104845:	b8 00 00 00 00       	mov    $0x0,%eax
f010484a:	eb 66                	jmp    f01048b2 <syscall+0x5be>
sys_time_msec(void)
{
	// LAB 6: Your code here.
	//panic("sys_time_msec not implemented");
	
	return time_msec();
f010484c:	e8 e8 1f 00 00       	call   f0106839 <time_msec>

	case SYS_env_set_trapframe:
		return sys_env_set_trapframe(a1, (struct Trapframe *)a2);

	case SYS_time_msec:
		return sys_time_msec();
f0104851:	eb 5f                	jmp    f01048b2 <syscall+0x5be>

//Set
static int
sys_net_tx_packet(char *data, int length)
{
	if ((uintptr_t) data >= UTOP)
f0104853:	81 7d 0c ff ff bf ee 	cmpl   $0xeebfffff,0xc(%ebp)
f010485a:	77 4a                	ja     f01048a6 <syscall+0x5b2>
		return -E_INVAL;

	return e1000_Transmit_packet(data, length);
f010485c:	83 ec 08             	sub    $0x8,%esp
f010485f:	ff 75 10             	pushl  0x10(%ebp)
f0104862:	ff 75 0c             	pushl  0xc(%ebp)
f0104865:	e8 57 19 00 00       	call   f01061c1 <e1000_Transmit_packet>
f010486a:	83 c4 10             	add    $0x10,%esp
f010486d:	eb 43                	jmp    f01048b2 <syscall+0x5be>

//Set
static int
sys_net_rx_data(char *data)
{
	if ((uintptr_t) data >= UTOP)
f010486f:	81 7d 0c ff ff bf ee 	cmpl   $0xeebfffff,0xc(%ebp)
f0104876:	77 35                	ja     f01048ad <syscall+0x5b9>
		return -E_INVAL;

	return  e1000_Receive_data(data);
f0104878:	83 ec 0c             	sub    $0xc,%esp
f010487b:	ff 75 0c             	pushl  0xc(%ebp)
f010487e:	e8 c6 19 00 00       	call   f0106249 <e1000_Receive_data>
f0104883:	83 c4 10             	add    $0x10,%esp
f0104886:	eb 2a                	jmp    f01048b2 <syscall+0x5be>
	
	case SYS_net_rx_data:
		return sys_net_rx_data((char *)a1);
		
	default:
		panic("Invalid System Call \n");
f0104888:	83 ec 04             	sub    $0x4,%esp
f010488b:	68 1a 83 10 f0       	push   $0xf010831a
f0104890:	68 65 02 00 00       	push   $0x265
f0104895:	68 0b 83 10 f0       	push   $0xf010830b
f010489a:	e8 a1 b7 ff ff       	call   f0100040 <_panic>

	case SYS_ipc_try_send:
		return sys_ipc_try_send(a1,a2,(void*)a3, a4);

	case SYS_ipc_recv:
		return sys_ipc_recv((void*)a1);
f010489f:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01048a4:	eb 0c                	jmp    f01048b2 <syscall+0x5be>
//Set
static int
sys_net_tx_packet(char *data, int length)
{
	if ((uintptr_t) data >= UTOP)
		return -E_INVAL;
f01048a6:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01048ab:	eb 05                	jmp    f01048b2 <syscall+0x5be>
//Set
static int
sys_net_rx_data(char *data)
{
	if ((uintptr_t) data >= UTOP)
		return -E_INVAL;
f01048ad:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		
	default:
		panic("Invalid System Call \n");
		return -E_INVAL;
	}
}
f01048b2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01048b5:	5b                   	pop    %ebx
f01048b6:	5e                   	pop    %esi
f01048b7:	5f                   	pop    %edi
f01048b8:	5d                   	pop    %ebp
f01048b9:	c3                   	ret    

f01048ba <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01048ba:	55                   	push   %ebp
f01048bb:	89 e5                	mov    %esp,%ebp
f01048bd:	57                   	push   %edi
f01048be:	56                   	push   %esi
f01048bf:	53                   	push   %ebx
f01048c0:	83 ec 14             	sub    $0x14,%esp
f01048c3:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01048c6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01048c9:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01048cc:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01048cf:	8b 1a                	mov    (%edx),%ebx
f01048d1:	8b 01                	mov    (%ecx),%eax
f01048d3:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01048d6:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01048dd:	e9 88 00 00 00       	jmp    f010496a <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f01048e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01048e5:	01 d8                	add    %ebx,%eax
f01048e7:	89 c6                	mov    %eax,%esi
f01048e9:	c1 ee 1f             	shr    $0x1f,%esi
f01048ec:	01 c6                	add    %eax,%esi
f01048ee:	d1 fe                	sar    %esi
f01048f0:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01048f3:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01048f6:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01048f9:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01048fb:	eb 03                	jmp    f0104900 <stab_binsearch+0x46>
			m--;
f01048fd:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104900:	39 c3                	cmp    %eax,%ebx
f0104902:	7f 1f                	jg     f0104923 <stab_binsearch+0x69>
f0104904:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104908:	83 ea 0c             	sub    $0xc,%edx
f010490b:	39 f9                	cmp    %edi,%ecx
f010490d:	75 ee                	jne    f01048fd <stab_binsearch+0x43>
f010490f:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104912:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104915:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104918:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010491c:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010491f:	76 18                	jbe    f0104939 <stab_binsearch+0x7f>
f0104921:	eb 05                	jmp    f0104928 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104923:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0104926:	eb 42                	jmp    f010496a <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0104928:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010492b:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010492d:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104930:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104937:	eb 31                	jmp    f010496a <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0104939:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010493c:	73 17                	jae    f0104955 <stab_binsearch+0x9b>
			*region_right = m - 1;
f010493e:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0104941:	83 e8 01             	sub    $0x1,%eax
f0104944:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104947:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010494a:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010494c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104953:	eb 15                	jmp    f010496a <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104955:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104958:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f010495b:	89 1e                	mov    %ebx,(%esi)
			l = m;
			addr++;
f010495d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104961:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104963:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010496a:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010496d:	0f 8e 6f ff ff ff    	jle    f01048e2 <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0104973:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104977:	75 0f                	jne    f0104988 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0104979:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010497c:	8b 00                	mov    (%eax),%eax
f010497e:	83 e8 01             	sub    $0x1,%eax
f0104981:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104984:	89 06                	mov    %eax,(%esi)
f0104986:	eb 2c                	jmp    f01049b4 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104988:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010498b:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010498d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104990:	8b 0e                	mov    (%esi),%ecx
f0104992:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104995:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0104998:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010499b:	eb 03                	jmp    f01049a0 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010499d:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01049a0:	39 c8                	cmp    %ecx,%eax
f01049a2:	7e 0b                	jle    f01049af <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f01049a4:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01049a8:	83 ea 0c             	sub    $0xc,%edx
f01049ab:	39 fb                	cmp    %edi,%ebx
f01049ad:	75 ee                	jne    f010499d <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f01049af:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01049b2:	89 06                	mov    %eax,(%esi)
	}
}
f01049b4:	83 c4 14             	add    $0x14,%esp
f01049b7:	5b                   	pop    %ebx
f01049b8:	5e                   	pop    %esi
f01049b9:	5f                   	pop    %edi
f01049ba:	5d                   	pop    %ebp
f01049bb:	c3                   	ret    

f01049bc <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01049bc:	55                   	push   %ebp
f01049bd:	89 e5                	mov    %esp,%ebp
f01049bf:	57                   	push   %edi
f01049c0:	56                   	push   %esi
f01049c1:	53                   	push   %ebx
f01049c2:	83 ec 3c             	sub    $0x3c,%esp
f01049c5:	8b 7d 08             	mov    0x8(%ebp),%edi
f01049c8:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01049cb:	c7 06 b8 83 10 f0    	movl   $0xf01083b8,(%esi)
	info->eip_line = 0;
f01049d1:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f01049d8:	c7 46 08 b8 83 10 f0 	movl   $0xf01083b8,0x8(%esi)
	info->eip_fn_namelen = 9;
f01049df:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01049e6:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f01049e9:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01049f0:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01049f6:	0f 87 a4 00 00 00    	ja     f0104aa0 <debuginfo_eip+0xe4>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
f01049fc:	e8 76 10 00 00       	call   f0105a77 <cpunum>
f0104a01:	6a 05                	push   $0x5
f0104a03:	6a 10                	push   $0x10
f0104a05:	68 00 00 20 00       	push   $0x200000
f0104a0a:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a0d:	ff b0 48 a0 2a f0    	pushl  -0xfd55fb8(%eax)
f0104a13:	e8 42 e4 ff ff       	call   f0102e5a <user_mem_check>
f0104a18:	83 c4 10             	add    $0x10,%esp
f0104a1b:	85 c0                	test   %eax,%eax
f0104a1d:	0f 88 24 02 00 00    	js     f0104c47 <debuginfo_eip+0x28b>
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
		}
		stabs = usd->stabs;
f0104a23:	a1 00 00 20 00       	mov    0x200000,%eax
		stab_end = usd->stab_end;
f0104a28:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f0104a2e:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f0104a34:	89 4d c0             	mov    %ecx,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f0104a37:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f0104a3d:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
f0104a40:	89 d9                	mov    %ebx,%ecx
f0104a42:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0104a45:	29 c1                	sub    %eax,%ecx
f0104a47:	89 4d b8             	mov    %ecx,-0x48(%ebp)
f0104a4a:	e8 28 10 00 00       	call   f0105a77 <cpunum>
f0104a4f:	6a 05                	push   $0x5
f0104a51:	ff 75 b8             	pushl  -0x48(%ebp)
f0104a54:	ff 75 c4             	pushl  -0x3c(%ebp)
f0104a57:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a5a:	ff b0 48 a0 2a f0    	pushl  -0xfd55fb8(%eax)
f0104a60:	e8 f5 e3 ff ff       	call   f0102e5a <user_mem_check>
f0104a65:	83 c4 10             	add    $0x10,%esp
f0104a68:	85 c0                	test   %eax,%eax
f0104a6a:	0f 88 de 01 00 00    	js     f0104c4e <debuginfo_eip+0x292>
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
		}

		if (user_mem_check(curenv, (const void *)stabstr,
f0104a70:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104a73:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0104a76:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0104a79:	e8 f9 0f 00 00       	call   f0105a77 <cpunum>
f0104a7e:	6a 05                	push   $0x5
f0104a80:	ff 75 b8             	pushl  -0x48(%ebp)
f0104a83:	ff 75 c0             	pushl  -0x40(%ebp)
f0104a86:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a89:	ff b0 48 a0 2a f0    	pushl  -0xfd55fb8(%eax)
f0104a8f:	e8 c6 e3 ff ff       	call   f0102e5a <user_mem_check>
f0104a94:	83 c4 10             	add    $0x10,%esp
f0104a97:	85 c0                	test   %eax,%eax
f0104a99:	79 1f                	jns    f0104aba <debuginfo_eip+0xfe>
f0104a9b:	e9 b5 01 00 00       	jmp    f0104c55 <debuginfo_eip+0x299>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104aa0:	c7 45 bc 6a 90 11 f0 	movl   $0xf011906a,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104aa7:	c7 45 c0 d9 4a 11 f0 	movl   $0xf0114ad9,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104aae:	bb d8 4a 11 f0       	mov    $0xf0114ad8,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104ab3:	c7 45 c4 4c 8c 10 f0 	movl   $0xf0108c4c,-0x3c(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104aba:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104abd:	39 45 c0             	cmp    %eax,-0x40(%ebp)
f0104ac0:	0f 83 96 01 00 00    	jae    f0104c5c <debuginfo_eip+0x2a0>
f0104ac6:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0104aca:	0f 85 93 01 00 00    	jne    f0104c63 <debuginfo_eip+0x2a7>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104ad0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104ad7:	89 d8                	mov    %ebx,%eax
f0104ad9:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0104adc:	29 d8                	sub    %ebx,%eax
f0104ade:	c1 f8 02             	sar    $0x2,%eax
f0104ae1:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0104ae7:	83 e8 01             	sub    $0x1,%eax
f0104aea:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104aed:	83 ec 08             	sub    $0x8,%esp
f0104af0:	57                   	push   %edi
f0104af1:	6a 64                	push   $0x64
f0104af3:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0104af6:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104af9:	89 d8                	mov    %ebx,%eax
f0104afb:	e8 ba fd ff ff       	call   f01048ba <stab_binsearch>
	if (lfile == 0)
f0104b00:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104b03:	83 c4 10             	add    $0x10,%esp
f0104b06:	85 c0                	test   %eax,%eax
f0104b08:	0f 84 5c 01 00 00    	je     f0104c6a <debuginfo_eip+0x2ae>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104b0e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104b11:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104b14:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104b17:	83 ec 08             	sub    $0x8,%esp
f0104b1a:	57                   	push   %edi
f0104b1b:	6a 24                	push   $0x24
f0104b1d:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0104b20:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104b23:	89 d8                	mov    %ebx,%eax
f0104b25:	e8 90 fd ff ff       	call   f01048ba <stab_binsearch>

	if (lfun <= rfun) {
f0104b2a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104b2d:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0104b30:	83 c4 10             	add    $0x10,%esp
f0104b33:	39 d8                	cmp    %ebx,%eax
f0104b35:	7f 32                	jg     f0104b69 <debuginfo_eip+0x1ad>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104b37:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104b3a:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0104b3d:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f0104b40:	8b 11                	mov    (%ecx),%edx
f0104b42:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0104b45:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104b48:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0104b4b:	39 55 b8             	cmp    %edx,-0x48(%ebp)
f0104b4e:	73 09                	jae    f0104b59 <debuginfo_eip+0x19d>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104b50:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0104b53:	03 55 c0             	add    -0x40(%ebp),%edx
f0104b56:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104b59:	8b 51 08             	mov    0x8(%ecx),%edx
f0104b5c:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0104b5f:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0104b61:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104b64:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0104b67:	eb 0f                	jmp    f0104b78 <debuginfo_eip+0x1bc>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104b69:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0104b6c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104b6f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104b72:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104b75:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104b78:	83 ec 08             	sub    $0x8,%esp
f0104b7b:	6a 3a                	push   $0x3a
f0104b7d:	ff 76 08             	pushl  0x8(%esi)
f0104b80:	e8 b1 08 00 00       	call   f0105436 <strfind>
f0104b85:	2b 46 08             	sub    0x8(%esi),%eax
f0104b88:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
f0104b8b:	83 c4 08             	add    $0x8,%esp
f0104b8e:	57                   	push   %edi
f0104b8f:	6a 44                	push   $0x44
f0104b91:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104b94:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0104b97:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0104b9a:	89 d8                	mov    %ebx,%eax
f0104b9c:	e8 19 fd ff ff       	call   f01048ba <stab_binsearch>
	if (lline > rline) {
f0104ba1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104ba4:	83 c4 10             	add    $0x10,%esp
f0104ba7:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0104baa:	0f 8f c1 00 00 00    	jg     f0104c71 <debuginfo_eip+0x2b5>
		return -1; //Did not find the line number in the stab
	}
	info->eip_line = stabs[lline].n_desc; //If found update the info object with the correct line number
f0104bb0:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104bb3:	0f b7 44 83 06       	movzwl 0x6(%ebx,%eax,4),%eax
f0104bb8:	89 46 04             	mov    %eax,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104bbb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104bbe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104bc1:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104bc4:	8d 14 93             	lea    (%ebx,%edx,4),%edx
f0104bc7:	89 75 0c             	mov    %esi,0xc(%ebp)
f0104bca:	eb 06                	jmp    f0104bd2 <debuginfo_eip+0x216>
f0104bcc:	83 e8 01             	sub    $0x1,%eax
f0104bcf:	83 ea 0c             	sub    $0xc,%edx
f0104bd2:	39 c7                	cmp    %eax,%edi
f0104bd4:	7f 2a                	jg     f0104c00 <debuginfo_eip+0x244>
	       && stabs[lline].n_type != N_SOL
f0104bd6:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104bda:	80 f9 84             	cmp    $0x84,%cl
f0104bdd:	0f 84 9c 00 00 00    	je     f0104c7f <debuginfo_eip+0x2c3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104be3:	80 f9 64             	cmp    $0x64,%cl
f0104be6:	75 e4                	jne    f0104bcc <debuginfo_eip+0x210>
f0104be8:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0104bec:	74 de                	je     f0104bcc <debuginfo_eip+0x210>
f0104bee:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104bf1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104bf4:	e9 8c 00 00 00       	jmp    f0104c85 <debuginfo_eip+0x2c9>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104bf9:	03 55 c0             	add    -0x40(%ebp),%edx
f0104bfc:	89 16                	mov    %edx,(%esi)
f0104bfe:	eb 03                	jmp    f0104c03 <debuginfo_eip+0x247>
f0104c00:	8b 75 0c             	mov    0xc(%ebp),%esi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104c03:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104c06:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104c09:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104c0e:	39 da                	cmp    %ebx,%edx
f0104c10:	0f 8d 8b 00 00 00    	jge    f0104ca1 <debuginfo_eip+0x2e5>
		for (lline = lfun + 1;
f0104c16:	83 c2 01             	add    $0x1,%edx
f0104c19:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104c1c:	89 d0                	mov    %edx,%eax
f0104c1e:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104c21:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0104c24:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0104c27:	eb 04                	jmp    f0104c2d <debuginfo_eip+0x271>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104c29:	83 46 14 01          	addl   $0x1,0x14(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104c2d:	39 c3                	cmp    %eax,%ebx
f0104c2f:	7e 47                	jle    f0104c78 <debuginfo_eip+0x2bc>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104c31:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104c35:	83 c0 01             	add    $0x1,%eax
f0104c38:	83 c2 0c             	add    $0xc,%edx
f0104c3b:	80 f9 a0             	cmp    $0xa0,%cl
f0104c3e:	74 e9                	je     f0104c29 <debuginfo_eip+0x26d>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104c40:	b8 00 00 00 00       	mov    $0x0,%eax
f0104c45:	eb 5a                	jmp    f0104ca1 <debuginfo_eip+0x2e5>
		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
f0104c47:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104c4c:	eb 53                	jmp    f0104ca1 <debuginfo_eip+0x2e5>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
f0104c4e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104c53:	eb 4c                	jmp    f0104ca1 <debuginfo_eip+0x2e5>
		}

		if (user_mem_check(curenv, (const void *)stabstr,
				(uintptr_t)stabstr_end - (uintptr_t)stabstr, PTE_U | PTE_P) < 0) {
			return -1;
f0104c55:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104c5a:	eb 45                	jmp    f0104ca1 <debuginfo_eip+0x2e5>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104c5c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104c61:	eb 3e                	jmp    f0104ca1 <debuginfo_eip+0x2e5>
f0104c63:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104c68:	eb 37                	jmp    f0104ca1 <debuginfo_eip+0x2e5>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104c6a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104c6f:	eb 30                	jmp    f0104ca1 <debuginfo_eip+0x2e5>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
	if (lline > rline) {
		return -1; //Did not find the line number in the stab
f0104c71:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104c76:	eb 29                	jmp    f0104ca1 <debuginfo_eip+0x2e5>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104c78:	b8 00 00 00 00       	mov    $0x0,%eax
f0104c7d:	eb 22                	jmp    f0104ca1 <debuginfo_eip+0x2e5>
f0104c7f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104c82:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104c85:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104c88:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0104c8b:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0104c8e:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104c91:	2b 45 c0             	sub    -0x40(%ebp),%eax
f0104c94:	39 c2                	cmp    %eax,%edx
f0104c96:	0f 82 5d ff ff ff    	jb     f0104bf9 <debuginfo_eip+0x23d>
f0104c9c:	e9 62 ff ff ff       	jmp    f0104c03 <debuginfo_eip+0x247>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
}
f0104ca1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104ca4:	5b                   	pop    %ebx
f0104ca5:	5e                   	pop    %esi
f0104ca6:	5f                   	pop    %edi
f0104ca7:	5d                   	pop    %ebp
f0104ca8:	c3                   	ret    

f0104ca9 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104ca9:	55                   	push   %ebp
f0104caa:	89 e5                	mov    %esp,%ebp
f0104cac:	57                   	push   %edi
f0104cad:	56                   	push   %esi
f0104cae:	53                   	push   %ebx
f0104caf:	83 ec 1c             	sub    $0x1c,%esp
f0104cb2:	89 c7                	mov    %eax,%edi
f0104cb4:	89 d6                	mov    %edx,%esi
f0104cb6:	8b 45 08             	mov    0x8(%ebp),%eax
f0104cb9:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104cbc:	89 d1                	mov    %edx,%ecx
f0104cbe:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104cc1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104cc4:	8b 45 10             	mov    0x10(%ebp),%eax
f0104cc7:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104cca:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104ccd:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0104cd4:	39 4d e4             	cmp    %ecx,-0x1c(%ebp)
f0104cd7:	72 05                	jb     f0104cde <printnum+0x35>
f0104cd9:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0104cdc:	77 3e                	ja     f0104d1c <printnum+0x73>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104cde:	83 ec 0c             	sub    $0xc,%esp
f0104ce1:	ff 75 18             	pushl  0x18(%ebp)
f0104ce4:	83 eb 01             	sub    $0x1,%ebx
f0104ce7:	53                   	push   %ebx
f0104ce8:	50                   	push   %eax
f0104ce9:	83 ec 08             	sub    $0x8,%esp
f0104cec:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104cef:	ff 75 e0             	pushl  -0x20(%ebp)
f0104cf2:	ff 75 dc             	pushl  -0x24(%ebp)
f0104cf5:	ff 75 d8             	pushl  -0x28(%ebp)
f0104cf8:	e8 53 1b 00 00       	call   f0106850 <__udivdi3>
f0104cfd:	83 c4 18             	add    $0x18,%esp
f0104d00:	52                   	push   %edx
f0104d01:	50                   	push   %eax
f0104d02:	89 f2                	mov    %esi,%edx
f0104d04:	89 f8                	mov    %edi,%eax
f0104d06:	e8 9e ff ff ff       	call   f0104ca9 <printnum>
f0104d0b:	83 c4 20             	add    $0x20,%esp
f0104d0e:	eb 13                	jmp    f0104d23 <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104d10:	83 ec 08             	sub    $0x8,%esp
f0104d13:	56                   	push   %esi
f0104d14:	ff 75 18             	pushl  0x18(%ebp)
f0104d17:	ff d7                	call   *%edi
f0104d19:	83 c4 10             	add    $0x10,%esp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104d1c:	83 eb 01             	sub    $0x1,%ebx
f0104d1f:	85 db                	test   %ebx,%ebx
f0104d21:	7f ed                	jg     f0104d10 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104d23:	83 ec 08             	sub    $0x8,%esp
f0104d26:	56                   	push   %esi
f0104d27:	83 ec 04             	sub    $0x4,%esp
f0104d2a:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104d2d:	ff 75 e0             	pushl  -0x20(%ebp)
f0104d30:	ff 75 dc             	pushl  -0x24(%ebp)
f0104d33:	ff 75 d8             	pushl  -0x28(%ebp)
f0104d36:	e8 45 1c 00 00       	call   f0106980 <__umoddi3>
f0104d3b:	83 c4 14             	add    $0x14,%esp
f0104d3e:	0f be 80 c2 83 10 f0 	movsbl -0xfef7c3e(%eax),%eax
f0104d45:	50                   	push   %eax
f0104d46:	ff d7                	call   *%edi
f0104d48:	83 c4 10             	add    $0x10,%esp
}
f0104d4b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104d4e:	5b                   	pop    %ebx
f0104d4f:	5e                   	pop    %esi
f0104d50:	5f                   	pop    %edi
f0104d51:	5d                   	pop    %ebp
f0104d52:	c3                   	ret    

f0104d53 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0104d53:	55                   	push   %ebp
f0104d54:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104d56:	83 fa 01             	cmp    $0x1,%edx
f0104d59:	7e 0e                	jle    f0104d69 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0104d5b:	8b 10                	mov    (%eax),%edx
f0104d5d:	8d 4a 08             	lea    0x8(%edx),%ecx
f0104d60:	89 08                	mov    %ecx,(%eax)
f0104d62:	8b 02                	mov    (%edx),%eax
f0104d64:	8b 52 04             	mov    0x4(%edx),%edx
f0104d67:	eb 22                	jmp    f0104d8b <getuint+0x38>
	else if (lflag)
f0104d69:	85 d2                	test   %edx,%edx
f0104d6b:	74 10                	je     f0104d7d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104d6d:	8b 10                	mov    (%eax),%edx
f0104d6f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104d72:	89 08                	mov    %ecx,(%eax)
f0104d74:	8b 02                	mov    (%edx),%eax
f0104d76:	ba 00 00 00 00       	mov    $0x0,%edx
f0104d7b:	eb 0e                	jmp    f0104d8b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104d7d:	8b 10                	mov    (%eax),%edx
f0104d7f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104d82:	89 08                	mov    %ecx,(%eax)
f0104d84:	8b 02                	mov    (%edx),%eax
f0104d86:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104d8b:	5d                   	pop    %ebp
f0104d8c:	c3                   	ret    

f0104d8d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104d8d:	55                   	push   %ebp
f0104d8e:	89 e5                	mov    %esp,%ebp
f0104d90:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104d93:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104d97:	8b 10                	mov    (%eax),%edx
f0104d99:	3b 50 04             	cmp    0x4(%eax),%edx
f0104d9c:	73 0a                	jae    f0104da8 <sprintputch+0x1b>
		*b->buf++ = ch;
f0104d9e:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104da1:	89 08                	mov    %ecx,(%eax)
f0104da3:	8b 45 08             	mov    0x8(%ebp),%eax
f0104da6:	88 02                	mov    %al,(%edx)
}
f0104da8:	5d                   	pop    %ebp
f0104da9:	c3                   	ret    

f0104daa <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104daa:	55                   	push   %ebp
f0104dab:	89 e5                	mov    %esp,%ebp
f0104dad:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0104db0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104db3:	50                   	push   %eax
f0104db4:	ff 75 10             	pushl  0x10(%ebp)
f0104db7:	ff 75 0c             	pushl  0xc(%ebp)
f0104dba:	ff 75 08             	pushl  0x8(%ebp)
f0104dbd:	e8 05 00 00 00       	call   f0104dc7 <vprintfmt>
	va_end(ap);
f0104dc2:	83 c4 10             	add    $0x10,%esp
}
f0104dc5:	c9                   	leave  
f0104dc6:	c3                   	ret    

f0104dc7 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104dc7:	55                   	push   %ebp
f0104dc8:	89 e5                	mov    %esp,%ebp
f0104dca:	57                   	push   %edi
f0104dcb:	56                   	push   %esi
f0104dcc:	53                   	push   %ebx
f0104dcd:	83 ec 2c             	sub    $0x2c,%esp
f0104dd0:	8b 75 08             	mov    0x8(%ebp),%esi
f0104dd3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104dd6:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104dd9:	eb 12                	jmp    f0104ded <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104ddb:	85 c0                	test   %eax,%eax
f0104ddd:	0f 84 90 03 00 00    	je     f0105173 <vprintfmt+0x3ac>
				return;
			putch(ch, putdat);
f0104de3:	83 ec 08             	sub    $0x8,%esp
f0104de6:	53                   	push   %ebx
f0104de7:	50                   	push   %eax
f0104de8:	ff d6                	call   *%esi
f0104dea:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104ded:	83 c7 01             	add    $0x1,%edi
f0104df0:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104df4:	83 f8 25             	cmp    $0x25,%eax
f0104df7:	75 e2                	jne    f0104ddb <vprintfmt+0x14>
f0104df9:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0104dfd:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0104e04:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104e0b:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0104e12:	ba 00 00 00 00       	mov    $0x0,%edx
f0104e17:	eb 07                	jmp    f0104e20 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e19:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104e1c:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e20:	8d 47 01             	lea    0x1(%edi),%eax
f0104e23:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104e26:	0f b6 07             	movzbl (%edi),%eax
f0104e29:	0f b6 c8             	movzbl %al,%ecx
f0104e2c:	83 e8 23             	sub    $0x23,%eax
f0104e2f:	3c 55                	cmp    $0x55,%al
f0104e31:	0f 87 21 03 00 00    	ja     f0105158 <vprintfmt+0x391>
f0104e37:	0f b6 c0             	movzbl %al,%eax
f0104e3a:	ff 24 85 00 85 10 f0 	jmp    *-0xfef7b00(,%eax,4)
f0104e41:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104e44:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0104e48:	eb d6                	jmp    f0104e20 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e4a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104e4d:	b8 00 00 00 00       	mov    $0x0,%eax
f0104e52:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104e55:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104e58:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0104e5c:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0104e5f:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0104e62:	83 fa 09             	cmp    $0x9,%edx
f0104e65:	77 39                	ja     f0104ea0 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104e67:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104e6a:	eb e9                	jmp    f0104e55 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104e6c:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e6f:	8d 48 04             	lea    0x4(%eax),%ecx
f0104e72:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104e75:	8b 00                	mov    (%eax),%eax
f0104e77:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e7a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104e7d:	eb 27                	jmp    f0104ea6 <vprintfmt+0xdf>
f0104e7f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104e82:	85 c0                	test   %eax,%eax
f0104e84:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104e89:	0f 49 c8             	cmovns %eax,%ecx
f0104e8c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e8f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104e92:	eb 8c                	jmp    f0104e20 <vprintfmt+0x59>
f0104e94:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104e97:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0104e9e:	eb 80                	jmp    f0104e20 <vprintfmt+0x59>
f0104ea0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104ea3:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0104ea6:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104eaa:	0f 89 70 ff ff ff    	jns    f0104e20 <vprintfmt+0x59>
				width = precision, precision = -1;
f0104eb0:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104eb3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104eb6:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104ebd:	e9 5e ff ff ff       	jmp    f0104e20 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104ec2:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104ec5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0104ec8:	e9 53 ff ff ff       	jmp    f0104e20 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104ecd:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ed0:	8d 50 04             	lea    0x4(%eax),%edx
f0104ed3:	89 55 14             	mov    %edx,0x14(%ebp)
f0104ed6:	83 ec 08             	sub    $0x8,%esp
f0104ed9:	53                   	push   %ebx
f0104eda:	ff 30                	pushl  (%eax)
f0104edc:	ff d6                	call   *%esi
			break;
f0104ede:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104ee1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0104ee4:	e9 04 ff ff ff       	jmp    f0104ded <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104ee9:	8b 45 14             	mov    0x14(%ebp),%eax
f0104eec:	8d 50 04             	lea    0x4(%eax),%edx
f0104eef:	89 55 14             	mov    %edx,0x14(%ebp)
f0104ef2:	8b 00                	mov    (%eax),%eax
f0104ef4:	99                   	cltd   
f0104ef5:	31 d0                	xor    %edx,%eax
f0104ef7:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104ef9:	83 f8 12             	cmp    $0x12,%eax
f0104efc:	7f 0b                	jg     f0104f09 <vprintfmt+0x142>
f0104efe:	8b 14 85 80 86 10 f0 	mov    -0xfef7980(,%eax,4),%edx
f0104f05:	85 d2                	test   %edx,%edx
f0104f07:	75 18                	jne    f0104f21 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0104f09:	50                   	push   %eax
f0104f0a:	68 da 83 10 f0       	push   $0xf01083da
f0104f0f:	53                   	push   %ebx
f0104f10:	56                   	push   %esi
f0104f11:	e8 94 fe ff ff       	call   f0104daa <printfmt>
f0104f16:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104f19:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0104f1c:	e9 cc fe ff ff       	jmp    f0104ded <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0104f21:	52                   	push   %edx
f0104f22:	68 ed 7a 10 f0       	push   $0xf0107aed
f0104f27:	53                   	push   %ebx
f0104f28:	56                   	push   %esi
f0104f29:	e8 7c fe ff ff       	call   f0104daa <printfmt>
f0104f2e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104f31:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104f34:	e9 b4 fe ff ff       	jmp    f0104ded <vprintfmt+0x26>
f0104f39:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0104f3c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104f3f:	89 45 cc             	mov    %eax,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104f42:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f45:	8d 50 04             	lea    0x4(%eax),%edx
f0104f48:	89 55 14             	mov    %edx,0x14(%ebp)
f0104f4b:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104f4d:	85 ff                	test   %edi,%edi
f0104f4f:	ba d3 83 10 f0       	mov    $0xf01083d3,%edx
f0104f54:	0f 44 fa             	cmove  %edx,%edi
			if (width > 0 && padc != '-')
f0104f57:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0104f5b:	0f 84 92 00 00 00    	je     f0104ff3 <vprintfmt+0x22c>
f0104f61:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0104f65:	0f 8e 96 00 00 00    	jle    f0105001 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104f6b:	83 ec 08             	sub    $0x8,%esp
f0104f6e:	51                   	push   %ecx
f0104f6f:	57                   	push   %edi
f0104f70:	e8 77 03 00 00       	call   f01052ec <strnlen>
f0104f75:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104f78:	29 c1                	sub    %eax,%ecx
f0104f7a:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0104f7d:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104f80:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104f84:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104f87:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104f8a:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104f8c:	eb 0f                	jmp    f0104f9d <vprintfmt+0x1d6>
					putch(padc, putdat);
f0104f8e:	83 ec 08             	sub    $0x8,%esp
f0104f91:	53                   	push   %ebx
f0104f92:	ff 75 e0             	pushl  -0x20(%ebp)
f0104f95:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104f97:	83 ef 01             	sub    $0x1,%edi
f0104f9a:	83 c4 10             	add    $0x10,%esp
f0104f9d:	85 ff                	test   %edi,%edi
f0104f9f:	7f ed                	jg     f0104f8e <vprintfmt+0x1c7>
f0104fa1:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104fa4:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104fa7:	85 c9                	test   %ecx,%ecx
f0104fa9:	b8 00 00 00 00       	mov    $0x0,%eax
f0104fae:	0f 49 c1             	cmovns %ecx,%eax
f0104fb1:	29 c1                	sub    %eax,%ecx
f0104fb3:	89 75 08             	mov    %esi,0x8(%ebp)
f0104fb6:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104fb9:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104fbc:	89 cb                	mov    %ecx,%ebx
f0104fbe:	eb 4d                	jmp    f010500d <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104fc0:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104fc4:	74 1b                	je     f0104fe1 <vprintfmt+0x21a>
f0104fc6:	0f be c0             	movsbl %al,%eax
f0104fc9:	83 e8 20             	sub    $0x20,%eax
f0104fcc:	83 f8 5e             	cmp    $0x5e,%eax
f0104fcf:	76 10                	jbe    f0104fe1 <vprintfmt+0x21a>
					putch('?', putdat);
f0104fd1:	83 ec 08             	sub    $0x8,%esp
f0104fd4:	ff 75 0c             	pushl  0xc(%ebp)
f0104fd7:	6a 3f                	push   $0x3f
f0104fd9:	ff 55 08             	call   *0x8(%ebp)
f0104fdc:	83 c4 10             	add    $0x10,%esp
f0104fdf:	eb 0d                	jmp    f0104fee <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0104fe1:	83 ec 08             	sub    $0x8,%esp
f0104fe4:	ff 75 0c             	pushl  0xc(%ebp)
f0104fe7:	52                   	push   %edx
f0104fe8:	ff 55 08             	call   *0x8(%ebp)
f0104feb:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104fee:	83 eb 01             	sub    $0x1,%ebx
f0104ff1:	eb 1a                	jmp    f010500d <vprintfmt+0x246>
f0104ff3:	89 75 08             	mov    %esi,0x8(%ebp)
f0104ff6:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104ff9:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104ffc:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104fff:	eb 0c                	jmp    f010500d <vprintfmt+0x246>
f0105001:	89 75 08             	mov    %esi,0x8(%ebp)
f0105004:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0105007:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010500a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010500d:	83 c7 01             	add    $0x1,%edi
f0105010:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0105014:	0f be d0             	movsbl %al,%edx
f0105017:	85 d2                	test   %edx,%edx
f0105019:	74 23                	je     f010503e <vprintfmt+0x277>
f010501b:	85 f6                	test   %esi,%esi
f010501d:	78 a1                	js     f0104fc0 <vprintfmt+0x1f9>
f010501f:	83 ee 01             	sub    $0x1,%esi
f0105022:	79 9c                	jns    f0104fc0 <vprintfmt+0x1f9>
f0105024:	89 df                	mov    %ebx,%edi
f0105026:	8b 75 08             	mov    0x8(%ebp),%esi
f0105029:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010502c:	eb 18                	jmp    f0105046 <vprintfmt+0x27f>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010502e:	83 ec 08             	sub    $0x8,%esp
f0105031:	53                   	push   %ebx
f0105032:	6a 20                	push   $0x20
f0105034:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0105036:	83 ef 01             	sub    $0x1,%edi
f0105039:	83 c4 10             	add    $0x10,%esp
f010503c:	eb 08                	jmp    f0105046 <vprintfmt+0x27f>
f010503e:	89 df                	mov    %ebx,%edi
f0105040:	8b 75 08             	mov    0x8(%ebp),%esi
f0105043:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105046:	85 ff                	test   %edi,%edi
f0105048:	7f e4                	jg     f010502e <vprintfmt+0x267>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010504a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010504d:	e9 9b fd ff ff       	jmp    f0104ded <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0105052:	83 fa 01             	cmp    $0x1,%edx
f0105055:	7e 16                	jle    f010506d <vprintfmt+0x2a6>
		return va_arg(*ap, long long);
f0105057:	8b 45 14             	mov    0x14(%ebp),%eax
f010505a:	8d 50 08             	lea    0x8(%eax),%edx
f010505d:	89 55 14             	mov    %edx,0x14(%ebp)
f0105060:	8b 50 04             	mov    0x4(%eax),%edx
f0105063:	8b 00                	mov    (%eax),%eax
f0105065:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105068:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010506b:	eb 32                	jmp    f010509f <vprintfmt+0x2d8>
	else if (lflag)
f010506d:	85 d2                	test   %edx,%edx
f010506f:	74 18                	je     f0105089 <vprintfmt+0x2c2>
		return va_arg(*ap, long);
f0105071:	8b 45 14             	mov    0x14(%ebp),%eax
f0105074:	8d 50 04             	lea    0x4(%eax),%edx
f0105077:	89 55 14             	mov    %edx,0x14(%ebp)
f010507a:	8b 00                	mov    (%eax),%eax
f010507c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010507f:	89 c1                	mov    %eax,%ecx
f0105081:	c1 f9 1f             	sar    $0x1f,%ecx
f0105084:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0105087:	eb 16                	jmp    f010509f <vprintfmt+0x2d8>
	else
		return va_arg(*ap, int);
f0105089:	8b 45 14             	mov    0x14(%ebp),%eax
f010508c:	8d 50 04             	lea    0x4(%eax),%edx
f010508f:	89 55 14             	mov    %edx,0x14(%ebp)
f0105092:	8b 00                	mov    (%eax),%eax
f0105094:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105097:	89 c1                	mov    %eax,%ecx
f0105099:	c1 f9 1f             	sar    $0x1f,%ecx
f010509c:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010509f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01050a2:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01050a5:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01050aa:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01050ae:	79 74                	jns    f0105124 <vprintfmt+0x35d>
				putch('-', putdat);
f01050b0:	83 ec 08             	sub    $0x8,%esp
f01050b3:	53                   	push   %ebx
f01050b4:	6a 2d                	push   $0x2d
f01050b6:	ff d6                	call   *%esi
				num = -(long long) num;
f01050b8:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01050bb:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01050be:	f7 d8                	neg    %eax
f01050c0:	83 d2 00             	adc    $0x0,%edx
f01050c3:	f7 da                	neg    %edx
f01050c5:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01050c8:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01050cd:	eb 55                	jmp    f0105124 <vprintfmt+0x35d>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01050cf:	8d 45 14             	lea    0x14(%ebp),%eax
f01050d2:	e8 7c fc ff ff       	call   f0104d53 <getuint>
			base = 10;
f01050d7:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01050dc:	eb 46                	jmp    f0105124 <vprintfmt+0x35d>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01050de:	8d 45 14             	lea    0x14(%ebp),%eax
f01050e1:	e8 6d fc ff ff       	call   f0104d53 <getuint>
			base = 8;
f01050e6:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01050eb:	eb 37                	jmp    f0105124 <vprintfmt+0x35d>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f01050ed:	83 ec 08             	sub    $0x8,%esp
f01050f0:	53                   	push   %ebx
f01050f1:	6a 30                	push   $0x30
f01050f3:	ff d6                	call   *%esi
			putch('x', putdat);
f01050f5:	83 c4 08             	add    $0x8,%esp
f01050f8:	53                   	push   %ebx
f01050f9:	6a 78                	push   $0x78
f01050fb:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01050fd:	8b 45 14             	mov    0x14(%ebp),%eax
f0105100:	8d 50 04             	lea    0x4(%eax),%edx
f0105103:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0105106:	8b 00                	mov    (%eax),%eax
f0105108:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010510d:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0105110:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0105115:	eb 0d                	jmp    f0105124 <vprintfmt+0x35d>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0105117:	8d 45 14             	lea    0x14(%ebp),%eax
f010511a:	e8 34 fc ff ff       	call   f0104d53 <getuint>
			base = 16;
f010511f:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0105124:	83 ec 0c             	sub    $0xc,%esp
f0105127:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010512b:	57                   	push   %edi
f010512c:	ff 75 e0             	pushl  -0x20(%ebp)
f010512f:	51                   	push   %ecx
f0105130:	52                   	push   %edx
f0105131:	50                   	push   %eax
f0105132:	89 da                	mov    %ebx,%edx
f0105134:	89 f0                	mov    %esi,%eax
f0105136:	e8 6e fb ff ff       	call   f0104ca9 <printnum>
			break;
f010513b:	83 c4 20             	add    $0x20,%esp
f010513e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0105141:	e9 a7 fc ff ff       	jmp    f0104ded <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0105146:	83 ec 08             	sub    $0x8,%esp
f0105149:	53                   	push   %ebx
f010514a:	51                   	push   %ecx
f010514b:	ff d6                	call   *%esi
			break;
f010514d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105150:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0105153:	e9 95 fc ff ff       	jmp    f0104ded <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0105158:	83 ec 08             	sub    $0x8,%esp
f010515b:	53                   	push   %ebx
f010515c:	6a 25                	push   $0x25
f010515e:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0105160:	83 c4 10             	add    $0x10,%esp
f0105163:	eb 03                	jmp    f0105168 <vprintfmt+0x3a1>
f0105165:	83 ef 01             	sub    $0x1,%edi
f0105168:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f010516c:	75 f7                	jne    f0105165 <vprintfmt+0x39e>
f010516e:	e9 7a fc ff ff       	jmp    f0104ded <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0105173:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105176:	5b                   	pop    %ebx
f0105177:	5e                   	pop    %esi
f0105178:	5f                   	pop    %edi
f0105179:	5d                   	pop    %ebp
f010517a:	c3                   	ret    

f010517b <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010517b:	55                   	push   %ebp
f010517c:	89 e5                	mov    %esp,%ebp
f010517e:	83 ec 18             	sub    $0x18,%esp
f0105181:	8b 45 08             	mov    0x8(%ebp),%eax
f0105184:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0105187:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010518a:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010518e:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0105191:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0105198:	85 c0                	test   %eax,%eax
f010519a:	74 26                	je     f01051c2 <vsnprintf+0x47>
f010519c:	85 d2                	test   %edx,%edx
f010519e:	7e 22                	jle    f01051c2 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01051a0:	ff 75 14             	pushl  0x14(%ebp)
f01051a3:	ff 75 10             	pushl  0x10(%ebp)
f01051a6:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01051a9:	50                   	push   %eax
f01051aa:	68 8d 4d 10 f0       	push   $0xf0104d8d
f01051af:	e8 13 fc ff ff       	call   f0104dc7 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01051b4:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01051b7:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01051ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01051bd:	83 c4 10             	add    $0x10,%esp
f01051c0:	eb 05                	jmp    f01051c7 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01051c2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01051c7:	c9                   	leave  
f01051c8:	c3                   	ret    

f01051c9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01051c9:	55                   	push   %ebp
f01051ca:	89 e5                	mov    %esp,%ebp
f01051cc:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01051cf:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01051d2:	50                   	push   %eax
f01051d3:	ff 75 10             	pushl  0x10(%ebp)
f01051d6:	ff 75 0c             	pushl  0xc(%ebp)
f01051d9:	ff 75 08             	pushl  0x8(%ebp)
f01051dc:	e8 9a ff ff ff       	call   f010517b <vsnprintf>
	va_end(ap);

	return rc;
}
f01051e1:	c9                   	leave  
f01051e2:	c3                   	ret    

f01051e3 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01051e3:	55                   	push   %ebp
f01051e4:	89 e5                	mov    %esp,%ebp
f01051e6:	57                   	push   %edi
f01051e7:	56                   	push   %esi
f01051e8:	53                   	push   %ebx
f01051e9:	83 ec 0c             	sub    $0xc,%esp
f01051ec:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

#if JOS_KERNEL
	if (prompt != NULL)
f01051ef:	85 c0                	test   %eax,%eax
f01051f1:	74 11                	je     f0105204 <readline+0x21>
		cprintf("%s", prompt);
f01051f3:	83 ec 08             	sub    $0x8,%esp
f01051f6:	50                   	push   %eax
f01051f7:	68 ed 7a 10 f0       	push   $0xf0107aed
f01051fc:	e8 58 e6 ff ff       	call   f0103859 <cprintf>
f0105201:	83 c4 10             	add    $0x10,%esp
	if (prompt != NULL)
		fprintf(1, "%s", prompt);
#endif

	i = 0;
	echoing = iscons(0);
f0105204:	83 ec 0c             	sub    $0xc,%esp
f0105207:	6a 00                	push   $0x0
f0105209:	e8 a9 b5 ff ff       	call   f01007b7 <iscons>
f010520e:	89 c7                	mov    %eax,%edi
f0105210:	83 c4 10             	add    $0x10,%esp
#else
	if (prompt != NULL)
		fprintf(1, "%s", prompt);
#endif

	i = 0;
f0105213:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0105218:	e8 89 b5 ff ff       	call   f01007a6 <getchar>
f010521d:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010521f:	85 c0                	test   %eax,%eax
f0105221:	79 29                	jns    f010524c <readline+0x69>
			if (c != -E_EOF)
				cprintf("read error: %e\n", c);
			return NULL;
f0105223:	b8 00 00 00 00       	mov    $0x0,%eax
	i = 0;
	echoing = iscons(0);
	while (1) {
		c = getchar();
		if (c < 0) {
			if (c != -E_EOF)
f0105228:	83 fb f8             	cmp    $0xfffffff8,%ebx
f010522b:	0f 84 9b 00 00 00    	je     f01052cc <readline+0xe9>
				cprintf("read error: %e\n", c);
f0105231:	83 ec 08             	sub    $0x8,%esp
f0105234:	53                   	push   %ebx
f0105235:	68 eb 86 10 f0       	push   $0xf01086eb
f010523a:	e8 1a e6 ff ff       	call   f0103859 <cprintf>
f010523f:	83 c4 10             	add    $0x10,%esp
			return NULL;
f0105242:	b8 00 00 00 00       	mov    $0x0,%eax
f0105247:	e9 80 00 00 00       	jmp    f01052cc <readline+0xe9>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010524c:	83 f8 7f             	cmp    $0x7f,%eax
f010524f:	0f 94 c2             	sete   %dl
f0105252:	83 f8 08             	cmp    $0x8,%eax
f0105255:	0f 94 c0             	sete   %al
f0105258:	08 c2                	or     %al,%dl
f010525a:	74 1a                	je     f0105276 <readline+0x93>
f010525c:	85 f6                	test   %esi,%esi
f010525e:	7e 16                	jle    f0105276 <readline+0x93>
			if (echoing)
f0105260:	85 ff                	test   %edi,%edi
f0105262:	74 0d                	je     f0105271 <readline+0x8e>
				cputchar('\b');
f0105264:	83 ec 0c             	sub    $0xc,%esp
f0105267:	6a 08                	push   $0x8
f0105269:	e8 28 b5 ff ff       	call   f0100796 <cputchar>
f010526e:	83 c4 10             	add    $0x10,%esp
			i--;
f0105271:	83 ee 01             	sub    $0x1,%esi
f0105274:	eb a2                	jmp    f0105218 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0105276:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010527c:	7f 23                	jg     f01052a1 <readline+0xbe>
f010527e:	83 fb 1f             	cmp    $0x1f,%ebx
f0105281:	7e 1e                	jle    f01052a1 <readline+0xbe>
			if (echoing)
f0105283:	85 ff                	test   %edi,%edi
f0105285:	74 0c                	je     f0105293 <readline+0xb0>
				cputchar(c);
f0105287:	83 ec 0c             	sub    $0xc,%esp
f010528a:	53                   	push   %ebx
f010528b:	e8 06 b5 ff ff       	call   f0100796 <cputchar>
f0105290:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0105293:	88 9e c0 9a 2a f0    	mov    %bl,-0xfd56540(%esi)
f0105299:	8d 76 01             	lea    0x1(%esi),%esi
f010529c:	e9 77 ff ff ff       	jmp    f0105218 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01052a1:	83 fb 0d             	cmp    $0xd,%ebx
f01052a4:	74 09                	je     f01052af <readline+0xcc>
f01052a6:	83 fb 0a             	cmp    $0xa,%ebx
f01052a9:	0f 85 69 ff ff ff    	jne    f0105218 <readline+0x35>
			if (echoing)
f01052af:	85 ff                	test   %edi,%edi
f01052b1:	74 0d                	je     f01052c0 <readline+0xdd>
				cputchar('\n');
f01052b3:	83 ec 0c             	sub    $0xc,%esp
f01052b6:	6a 0a                	push   $0xa
f01052b8:	e8 d9 b4 ff ff       	call   f0100796 <cputchar>
f01052bd:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01052c0:	c6 86 c0 9a 2a f0 00 	movb   $0x0,-0xfd56540(%esi)
			return buf;
f01052c7:	b8 c0 9a 2a f0       	mov    $0xf02a9ac0,%eax
		}
	}
}
f01052cc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01052cf:	5b                   	pop    %ebx
f01052d0:	5e                   	pop    %esi
f01052d1:	5f                   	pop    %edi
f01052d2:	5d                   	pop    %ebp
f01052d3:	c3                   	ret    

f01052d4 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01052d4:	55                   	push   %ebp
f01052d5:	89 e5                	mov    %esp,%ebp
f01052d7:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01052da:	b8 00 00 00 00       	mov    $0x0,%eax
f01052df:	eb 03                	jmp    f01052e4 <strlen+0x10>
		n++;
f01052e1:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01052e4:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01052e8:	75 f7                	jne    f01052e1 <strlen+0xd>
		n++;
	return n;
}
f01052ea:	5d                   	pop    %ebp
f01052eb:	c3                   	ret    

f01052ec <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01052ec:	55                   	push   %ebp
f01052ed:	89 e5                	mov    %esp,%ebp
f01052ef:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01052f2:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01052f5:	ba 00 00 00 00       	mov    $0x0,%edx
f01052fa:	eb 03                	jmp    f01052ff <strnlen+0x13>
		n++;
f01052fc:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01052ff:	39 c2                	cmp    %eax,%edx
f0105301:	74 08                	je     f010530b <strnlen+0x1f>
f0105303:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0105307:	75 f3                	jne    f01052fc <strnlen+0x10>
f0105309:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010530b:	5d                   	pop    %ebp
f010530c:	c3                   	ret    

f010530d <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010530d:	55                   	push   %ebp
f010530e:	89 e5                	mov    %esp,%ebp
f0105310:	53                   	push   %ebx
f0105311:	8b 45 08             	mov    0x8(%ebp),%eax
f0105314:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0105317:	89 c2                	mov    %eax,%edx
f0105319:	83 c2 01             	add    $0x1,%edx
f010531c:	83 c1 01             	add    $0x1,%ecx
f010531f:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0105323:	88 5a ff             	mov    %bl,-0x1(%edx)
f0105326:	84 db                	test   %bl,%bl
f0105328:	75 ef                	jne    f0105319 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010532a:	5b                   	pop    %ebx
f010532b:	5d                   	pop    %ebp
f010532c:	c3                   	ret    

f010532d <strcat>:

char *
strcat(char *dst, const char *src)
{
f010532d:	55                   	push   %ebp
f010532e:	89 e5                	mov    %esp,%ebp
f0105330:	53                   	push   %ebx
f0105331:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0105334:	53                   	push   %ebx
f0105335:	e8 9a ff ff ff       	call   f01052d4 <strlen>
f010533a:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010533d:	ff 75 0c             	pushl  0xc(%ebp)
f0105340:	01 d8                	add    %ebx,%eax
f0105342:	50                   	push   %eax
f0105343:	e8 c5 ff ff ff       	call   f010530d <strcpy>
	return dst;
}
f0105348:	89 d8                	mov    %ebx,%eax
f010534a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010534d:	c9                   	leave  
f010534e:	c3                   	ret    

f010534f <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010534f:	55                   	push   %ebp
f0105350:	89 e5                	mov    %esp,%ebp
f0105352:	56                   	push   %esi
f0105353:	53                   	push   %ebx
f0105354:	8b 75 08             	mov    0x8(%ebp),%esi
f0105357:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010535a:	89 f3                	mov    %esi,%ebx
f010535c:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010535f:	89 f2                	mov    %esi,%edx
f0105361:	eb 0f                	jmp    f0105372 <strncpy+0x23>
		*dst++ = *src;
f0105363:	83 c2 01             	add    $0x1,%edx
f0105366:	0f b6 01             	movzbl (%ecx),%eax
f0105369:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010536c:	80 39 01             	cmpb   $0x1,(%ecx)
f010536f:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105372:	39 da                	cmp    %ebx,%edx
f0105374:	75 ed                	jne    f0105363 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0105376:	89 f0                	mov    %esi,%eax
f0105378:	5b                   	pop    %ebx
f0105379:	5e                   	pop    %esi
f010537a:	5d                   	pop    %ebp
f010537b:	c3                   	ret    

f010537c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010537c:	55                   	push   %ebp
f010537d:	89 e5                	mov    %esp,%ebp
f010537f:	56                   	push   %esi
f0105380:	53                   	push   %ebx
f0105381:	8b 75 08             	mov    0x8(%ebp),%esi
f0105384:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105387:	8b 55 10             	mov    0x10(%ebp),%edx
f010538a:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010538c:	85 d2                	test   %edx,%edx
f010538e:	74 21                	je     f01053b1 <strlcpy+0x35>
f0105390:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0105394:	89 f2                	mov    %esi,%edx
f0105396:	eb 09                	jmp    f01053a1 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0105398:	83 c2 01             	add    $0x1,%edx
f010539b:	83 c1 01             	add    $0x1,%ecx
f010539e:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01053a1:	39 c2                	cmp    %eax,%edx
f01053a3:	74 09                	je     f01053ae <strlcpy+0x32>
f01053a5:	0f b6 19             	movzbl (%ecx),%ebx
f01053a8:	84 db                	test   %bl,%bl
f01053aa:	75 ec                	jne    f0105398 <strlcpy+0x1c>
f01053ac:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01053ae:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01053b1:	29 f0                	sub    %esi,%eax
}
f01053b3:	5b                   	pop    %ebx
f01053b4:	5e                   	pop    %esi
f01053b5:	5d                   	pop    %ebp
f01053b6:	c3                   	ret    

f01053b7 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01053b7:	55                   	push   %ebp
f01053b8:	89 e5                	mov    %esp,%ebp
f01053ba:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01053bd:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01053c0:	eb 06                	jmp    f01053c8 <strcmp+0x11>
		p++, q++;
f01053c2:	83 c1 01             	add    $0x1,%ecx
f01053c5:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01053c8:	0f b6 01             	movzbl (%ecx),%eax
f01053cb:	84 c0                	test   %al,%al
f01053cd:	74 04                	je     f01053d3 <strcmp+0x1c>
f01053cf:	3a 02                	cmp    (%edx),%al
f01053d1:	74 ef                	je     f01053c2 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01053d3:	0f b6 c0             	movzbl %al,%eax
f01053d6:	0f b6 12             	movzbl (%edx),%edx
f01053d9:	29 d0                	sub    %edx,%eax
}
f01053db:	5d                   	pop    %ebp
f01053dc:	c3                   	ret    

f01053dd <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01053dd:	55                   	push   %ebp
f01053de:	89 e5                	mov    %esp,%ebp
f01053e0:	53                   	push   %ebx
f01053e1:	8b 45 08             	mov    0x8(%ebp),%eax
f01053e4:	8b 55 0c             	mov    0xc(%ebp),%edx
f01053e7:	89 c3                	mov    %eax,%ebx
f01053e9:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01053ec:	eb 06                	jmp    f01053f4 <strncmp+0x17>
		n--, p++, q++;
f01053ee:	83 c0 01             	add    $0x1,%eax
f01053f1:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01053f4:	39 d8                	cmp    %ebx,%eax
f01053f6:	74 15                	je     f010540d <strncmp+0x30>
f01053f8:	0f b6 08             	movzbl (%eax),%ecx
f01053fb:	84 c9                	test   %cl,%cl
f01053fd:	74 04                	je     f0105403 <strncmp+0x26>
f01053ff:	3a 0a                	cmp    (%edx),%cl
f0105401:	74 eb                	je     f01053ee <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105403:	0f b6 00             	movzbl (%eax),%eax
f0105406:	0f b6 12             	movzbl (%edx),%edx
f0105409:	29 d0                	sub    %edx,%eax
f010540b:	eb 05                	jmp    f0105412 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010540d:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0105412:	5b                   	pop    %ebx
f0105413:	5d                   	pop    %ebp
f0105414:	c3                   	ret    

f0105415 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0105415:	55                   	push   %ebp
f0105416:	89 e5                	mov    %esp,%ebp
f0105418:	8b 45 08             	mov    0x8(%ebp),%eax
f010541b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010541f:	eb 07                	jmp    f0105428 <strchr+0x13>
		if (*s == c)
f0105421:	38 ca                	cmp    %cl,%dl
f0105423:	74 0f                	je     f0105434 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0105425:	83 c0 01             	add    $0x1,%eax
f0105428:	0f b6 10             	movzbl (%eax),%edx
f010542b:	84 d2                	test   %dl,%dl
f010542d:	75 f2                	jne    f0105421 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010542f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105434:	5d                   	pop    %ebp
f0105435:	c3                   	ret    

f0105436 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0105436:	55                   	push   %ebp
f0105437:	89 e5                	mov    %esp,%ebp
f0105439:	8b 45 08             	mov    0x8(%ebp),%eax
f010543c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105440:	eb 03                	jmp    f0105445 <strfind+0xf>
f0105442:	83 c0 01             	add    $0x1,%eax
f0105445:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0105448:	84 d2                	test   %dl,%dl
f010544a:	74 04                	je     f0105450 <strfind+0x1a>
f010544c:	38 ca                	cmp    %cl,%dl
f010544e:	75 f2                	jne    f0105442 <strfind+0xc>
			break;
	return (char *) s;
}
f0105450:	5d                   	pop    %ebp
f0105451:	c3                   	ret    

f0105452 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105452:	55                   	push   %ebp
f0105453:	89 e5                	mov    %esp,%ebp
f0105455:	57                   	push   %edi
f0105456:	56                   	push   %esi
f0105457:	53                   	push   %ebx
f0105458:	8b 7d 08             	mov    0x8(%ebp),%edi
f010545b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010545e:	85 c9                	test   %ecx,%ecx
f0105460:	74 36                	je     f0105498 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0105462:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0105468:	75 28                	jne    f0105492 <memset+0x40>
f010546a:	f6 c1 03             	test   $0x3,%cl
f010546d:	75 23                	jne    f0105492 <memset+0x40>
		c &= 0xFF;
f010546f:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0105473:	89 d3                	mov    %edx,%ebx
f0105475:	c1 e3 08             	shl    $0x8,%ebx
f0105478:	89 d6                	mov    %edx,%esi
f010547a:	c1 e6 18             	shl    $0x18,%esi
f010547d:	89 d0                	mov    %edx,%eax
f010547f:	c1 e0 10             	shl    $0x10,%eax
f0105482:	09 f0                	or     %esi,%eax
f0105484:	09 c2                	or     %eax,%edx
f0105486:	89 d0                	mov    %edx,%eax
f0105488:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010548a:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f010548d:	fc                   	cld    
f010548e:	f3 ab                	rep stos %eax,%es:(%edi)
f0105490:	eb 06                	jmp    f0105498 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105492:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105495:	fc                   	cld    
f0105496:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0105498:	89 f8                	mov    %edi,%eax
f010549a:	5b                   	pop    %ebx
f010549b:	5e                   	pop    %esi
f010549c:	5f                   	pop    %edi
f010549d:	5d                   	pop    %ebp
f010549e:	c3                   	ret    

f010549f <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010549f:	55                   	push   %ebp
f01054a0:	89 e5                	mov    %esp,%ebp
f01054a2:	57                   	push   %edi
f01054a3:	56                   	push   %esi
f01054a4:	8b 45 08             	mov    0x8(%ebp),%eax
f01054a7:	8b 75 0c             	mov    0xc(%ebp),%esi
f01054aa:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01054ad:	39 c6                	cmp    %eax,%esi
f01054af:	73 35                	jae    f01054e6 <memmove+0x47>
f01054b1:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01054b4:	39 d0                	cmp    %edx,%eax
f01054b6:	73 2e                	jae    f01054e6 <memmove+0x47>
		s += n;
		d += n;
f01054b8:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01054bb:	89 d6                	mov    %edx,%esi
f01054bd:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01054bf:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01054c5:	75 13                	jne    f01054da <memmove+0x3b>
f01054c7:	f6 c1 03             	test   $0x3,%cl
f01054ca:	75 0e                	jne    f01054da <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01054cc:	83 ef 04             	sub    $0x4,%edi
f01054cf:	8d 72 fc             	lea    -0x4(%edx),%esi
f01054d2:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01054d5:	fd                   	std    
f01054d6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01054d8:	eb 09                	jmp    f01054e3 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01054da:	83 ef 01             	sub    $0x1,%edi
f01054dd:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01054e0:	fd                   	std    
f01054e1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01054e3:	fc                   	cld    
f01054e4:	eb 1d                	jmp    f0105503 <memmove+0x64>
f01054e6:	89 f2                	mov    %esi,%edx
f01054e8:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01054ea:	f6 c2 03             	test   $0x3,%dl
f01054ed:	75 0f                	jne    f01054fe <memmove+0x5f>
f01054ef:	f6 c1 03             	test   $0x3,%cl
f01054f2:	75 0a                	jne    f01054fe <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01054f4:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01054f7:	89 c7                	mov    %eax,%edi
f01054f9:	fc                   	cld    
f01054fa:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01054fc:	eb 05                	jmp    f0105503 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01054fe:	89 c7                	mov    %eax,%edi
f0105500:	fc                   	cld    
f0105501:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105503:	5e                   	pop    %esi
f0105504:	5f                   	pop    %edi
f0105505:	5d                   	pop    %ebp
f0105506:	c3                   	ret    

f0105507 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0105507:	55                   	push   %ebp
f0105508:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010550a:	ff 75 10             	pushl  0x10(%ebp)
f010550d:	ff 75 0c             	pushl  0xc(%ebp)
f0105510:	ff 75 08             	pushl  0x8(%ebp)
f0105513:	e8 87 ff ff ff       	call   f010549f <memmove>
}
f0105518:	c9                   	leave  
f0105519:	c3                   	ret    

f010551a <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010551a:	55                   	push   %ebp
f010551b:	89 e5                	mov    %esp,%ebp
f010551d:	56                   	push   %esi
f010551e:	53                   	push   %ebx
f010551f:	8b 45 08             	mov    0x8(%ebp),%eax
f0105522:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105525:	89 c6                	mov    %eax,%esi
f0105527:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010552a:	eb 1a                	jmp    f0105546 <memcmp+0x2c>
		if (*s1 != *s2)
f010552c:	0f b6 08             	movzbl (%eax),%ecx
f010552f:	0f b6 1a             	movzbl (%edx),%ebx
f0105532:	38 d9                	cmp    %bl,%cl
f0105534:	74 0a                	je     f0105540 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0105536:	0f b6 c1             	movzbl %cl,%eax
f0105539:	0f b6 db             	movzbl %bl,%ebx
f010553c:	29 d8                	sub    %ebx,%eax
f010553e:	eb 0f                	jmp    f010554f <memcmp+0x35>
		s1++, s2++;
f0105540:	83 c0 01             	add    $0x1,%eax
f0105543:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105546:	39 f0                	cmp    %esi,%eax
f0105548:	75 e2                	jne    f010552c <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010554a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010554f:	5b                   	pop    %ebx
f0105550:	5e                   	pop    %esi
f0105551:	5d                   	pop    %ebp
f0105552:	c3                   	ret    

f0105553 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105553:	55                   	push   %ebp
f0105554:	89 e5                	mov    %esp,%ebp
f0105556:	8b 45 08             	mov    0x8(%ebp),%eax
f0105559:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010555c:	89 c2                	mov    %eax,%edx
f010555e:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0105561:	eb 07                	jmp    f010556a <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0105563:	38 08                	cmp    %cl,(%eax)
f0105565:	74 07                	je     f010556e <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0105567:	83 c0 01             	add    $0x1,%eax
f010556a:	39 d0                	cmp    %edx,%eax
f010556c:	72 f5                	jb     f0105563 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010556e:	5d                   	pop    %ebp
f010556f:	c3                   	ret    

f0105570 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105570:	55                   	push   %ebp
f0105571:	89 e5                	mov    %esp,%ebp
f0105573:	57                   	push   %edi
f0105574:	56                   	push   %esi
f0105575:	53                   	push   %ebx
f0105576:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105579:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010557c:	eb 03                	jmp    f0105581 <strtol+0x11>
		s++;
f010557e:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105581:	0f b6 01             	movzbl (%ecx),%eax
f0105584:	3c 09                	cmp    $0x9,%al
f0105586:	74 f6                	je     f010557e <strtol+0xe>
f0105588:	3c 20                	cmp    $0x20,%al
f010558a:	74 f2                	je     f010557e <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010558c:	3c 2b                	cmp    $0x2b,%al
f010558e:	75 0a                	jne    f010559a <strtol+0x2a>
		s++;
f0105590:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0105593:	bf 00 00 00 00       	mov    $0x0,%edi
f0105598:	eb 10                	jmp    f01055aa <strtol+0x3a>
f010559a:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010559f:	3c 2d                	cmp    $0x2d,%al
f01055a1:	75 07                	jne    f01055aa <strtol+0x3a>
		s++, neg = 1;
f01055a3:	8d 49 01             	lea    0x1(%ecx),%ecx
f01055a6:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01055aa:	85 db                	test   %ebx,%ebx
f01055ac:	0f 94 c0             	sete   %al
f01055af:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01055b5:	75 19                	jne    f01055d0 <strtol+0x60>
f01055b7:	80 39 30             	cmpb   $0x30,(%ecx)
f01055ba:	75 14                	jne    f01055d0 <strtol+0x60>
f01055bc:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01055c0:	0f 85 82 00 00 00    	jne    f0105648 <strtol+0xd8>
		s += 2, base = 16;
f01055c6:	83 c1 02             	add    $0x2,%ecx
f01055c9:	bb 10 00 00 00       	mov    $0x10,%ebx
f01055ce:	eb 16                	jmp    f01055e6 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f01055d0:	84 c0                	test   %al,%al
f01055d2:	74 12                	je     f01055e6 <strtol+0x76>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01055d4:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01055d9:	80 39 30             	cmpb   $0x30,(%ecx)
f01055dc:	75 08                	jne    f01055e6 <strtol+0x76>
		s++, base = 8;
f01055de:	83 c1 01             	add    $0x1,%ecx
f01055e1:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01055e6:	b8 00 00 00 00       	mov    $0x0,%eax
f01055eb:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01055ee:	0f b6 11             	movzbl (%ecx),%edx
f01055f1:	8d 72 d0             	lea    -0x30(%edx),%esi
f01055f4:	89 f3                	mov    %esi,%ebx
f01055f6:	80 fb 09             	cmp    $0x9,%bl
f01055f9:	77 08                	ja     f0105603 <strtol+0x93>
			dig = *s - '0';
f01055fb:	0f be d2             	movsbl %dl,%edx
f01055fe:	83 ea 30             	sub    $0x30,%edx
f0105601:	eb 22                	jmp    f0105625 <strtol+0xb5>
		else if (*s >= 'a' && *s <= 'z')
f0105603:	8d 72 9f             	lea    -0x61(%edx),%esi
f0105606:	89 f3                	mov    %esi,%ebx
f0105608:	80 fb 19             	cmp    $0x19,%bl
f010560b:	77 08                	ja     f0105615 <strtol+0xa5>
			dig = *s - 'a' + 10;
f010560d:	0f be d2             	movsbl %dl,%edx
f0105610:	83 ea 57             	sub    $0x57,%edx
f0105613:	eb 10                	jmp    f0105625 <strtol+0xb5>
		else if (*s >= 'A' && *s <= 'Z')
f0105615:	8d 72 bf             	lea    -0x41(%edx),%esi
f0105618:	89 f3                	mov    %esi,%ebx
f010561a:	80 fb 19             	cmp    $0x19,%bl
f010561d:	77 16                	ja     f0105635 <strtol+0xc5>
			dig = *s - 'A' + 10;
f010561f:	0f be d2             	movsbl %dl,%edx
f0105622:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0105625:	3b 55 10             	cmp    0x10(%ebp),%edx
f0105628:	7d 0f                	jge    f0105639 <strtol+0xc9>
			break;
		s++, val = (val * base) + dig;
f010562a:	83 c1 01             	add    $0x1,%ecx
f010562d:	0f af 45 10          	imul   0x10(%ebp),%eax
f0105631:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0105633:	eb b9                	jmp    f01055ee <strtol+0x7e>
f0105635:	89 c2                	mov    %eax,%edx
f0105637:	eb 02                	jmp    f010563b <strtol+0xcb>
f0105639:	89 c2                	mov    %eax,%edx

	if (endptr)
f010563b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010563f:	74 0d                	je     f010564e <strtol+0xde>
		*endptr = (char *) s;
f0105641:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105644:	89 0e                	mov    %ecx,(%esi)
f0105646:	eb 06                	jmp    f010564e <strtol+0xde>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105648:	84 c0                	test   %al,%al
f010564a:	75 92                	jne    f01055de <strtol+0x6e>
f010564c:	eb 98                	jmp    f01055e6 <strtol+0x76>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010564e:	f7 da                	neg    %edx
f0105650:	85 ff                	test   %edi,%edi
f0105652:	0f 45 c2             	cmovne %edx,%eax
}
f0105655:	5b                   	pop    %ebx
f0105656:	5e                   	pop    %esi
f0105657:	5f                   	pop    %edi
f0105658:	5d                   	pop    %ebp
f0105659:	c3                   	ret    
f010565a:	66 90                	xchg   %ax,%ax

f010565c <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f010565c:	fa                   	cli    

	xorw    %ax, %ax
f010565d:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f010565f:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105661:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105663:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0105665:	0f 01 16             	lgdtl  (%esi)
f0105668:	74 70                	je     f01056da <mpsearch1+0x3>
	movl    %cr0, %eax
f010566a:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f010566d:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0105671:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0105674:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f010567a:	08 00                	or     %al,(%eax)

f010567c <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f010567c:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0105680:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105682:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105684:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0105686:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f010568a:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f010568c:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f010568e:	b8 00 20 12 00       	mov    $0x122000,%eax
	movl    %eax, %cr3
f0105693:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0105696:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0105699:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f010569e:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f01056a1:	8b 25 d0 9e 2a f0    	mov    0xf02a9ed0,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f01056a7:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f01056ac:	b8 e1 01 10 f0       	mov    $0xf01001e1,%eax
	call    *%eax
f01056b1:	ff d0                	call   *%eax

f01056b3 <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f01056b3:	eb fe                	jmp    f01056b3 <spin>
f01056b5:	8d 76 00             	lea    0x0(%esi),%esi

f01056b8 <gdt>:
	...
f01056c0:	ff                   	(bad)  
f01056c1:	ff 00                	incl   (%eax)
f01056c3:	00 00                	add    %al,(%eax)
f01056c5:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f01056cc:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

f01056d0 <gdtdesc>:
f01056d0:	17                   	pop    %ss
f01056d1:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f01056d6 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f01056d6:	90                   	nop

f01056d7 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f01056d7:	55                   	push   %ebp
f01056d8:	89 e5                	mov    %esp,%ebp
f01056da:	57                   	push   %edi
f01056db:	56                   	push   %esi
f01056dc:	53                   	push   %ebx
f01056dd:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01056e0:	8b 0d d8 9e 2a f0    	mov    0xf02a9ed8,%ecx
f01056e6:	89 c3                	mov    %eax,%ebx
f01056e8:	c1 eb 0c             	shr    $0xc,%ebx
f01056eb:	39 cb                	cmp    %ecx,%ebx
f01056ed:	72 12                	jb     f0105701 <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01056ef:	50                   	push   %eax
f01056f0:	68 24 6b 10 f0       	push   $0xf0106b24
f01056f5:	6a 57                	push   $0x57
f01056f7:	68 89 88 10 f0       	push   $0xf0108889
f01056fc:	e8 3f a9 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105701:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0105707:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105709:	89 c2                	mov    %eax,%edx
f010570b:	c1 ea 0c             	shr    $0xc,%edx
f010570e:	39 d1                	cmp    %edx,%ecx
f0105710:	77 12                	ja     f0105724 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105712:	50                   	push   %eax
f0105713:	68 24 6b 10 f0       	push   $0xf0106b24
f0105718:	6a 57                	push   $0x57
f010571a:	68 89 88 10 f0       	push   $0xf0108889
f010571f:	e8 1c a9 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105724:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f010572a:	eb 2f                	jmp    f010575b <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f010572c:	83 ec 04             	sub    $0x4,%esp
f010572f:	6a 04                	push   $0x4
f0105731:	68 99 88 10 f0       	push   $0xf0108899
f0105736:	53                   	push   %ebx
f0105737:	e8 de fd ff ff       	call   f010551a <memcmp>
f010573c:	83 c4 10             	add    $0x10,%esp
f010573f:	85 c0                	test   %eax,%eax
f0105741:	75 15                	jne    f0105758 <mpsearch1+0x81>
f0105743:	89 da                	mov    %ebx,%edx
f0105745:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f0105748:	0f b6 0a             	movzbl (%edx),%ecx
f010574b:	01 c8                	add    %ecx,%eax
f010574d:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105750:	39 fa                	cmp    %edi,%edx
f0105752:	75 f4                	jne    f0105748 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105754:	84 c0                	test   %al,%al
f0105756:	74 0e                	je     f0105766 <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0105758:	83 c3 10             	add    $0x10,%ebx
f010575b:	39 f3                	cmp    %esi,%ebx
f010575d:	72 cd                	jb     f010572c <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f010575f:	b8 00 00 00 00       	mov    $0x0,%eax
f0105764:	eb 02                	jmp    f0105768 <mpsearch1+0x91>
f0105766:	89 d8                	mov    %ebx,%eax
}
f0105768:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010576b:	5b                   	pop    %ebx
f010576c:	5e                   	pop    %esi
f010576d:	5f                   	pop    %edi
f010576e:	5d                   	pop    %ebp
f010576f:	c3                   	ret    

f0105770 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0105770:	55                   	push   %ebp
f0105771:	89 e5                	mov    %esp,%ebp
f0105773:	57                   	push   %edi
f0105774:	56                   	push   %esi
f0105775:	53                   	push   %ebx
f0105776:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105779:	c7 05 e0 a3 2a f0 40 	movl   $0xf02aa040,0xf02aa3e0
f0105780:	a0 2a f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105783:	83 3d d8 9e 2a f0 00 	cmpl   $0x0,0xf02a9ed8
f010578a:	75 16                	jne    f01057a2 <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010578c:	68 00 04 00 00       	push   $0x400
f0105791:	68 24 6b 10 f0       	push   $0xf0106b24
f0105796:	6a 6f                	push   $0x6f
f0105798:	68 89 88 10 f0       	push   $0xf0108889
f010579d:	e8 9e a8 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f01057a2:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f01057a9:	85 c0                	test   %eax,%eax
f01057ab:	74 16                	je     f01057c3 <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
f01057ad:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f01057b0:	ba 00 04 00 00       	mov    $0x400,%edx
f01057b5:	e8 1d ff ff ff       	call   f01056d7 <mpsearch1>
f01057ba:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01057bd:	85 c0                	test   %eax,%eax
f01057bf:	75 3c                	jne    f01057fd <mp_init+0x8d>
f01057c1:	eb 20                	jmp    f01057e3 <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
f01057c3:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f01057ca:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f01057cd:	2d 00 04 00 00       	sub    $0x400,%eax
f01057d2:	ba 00 04 00 00       	mov    $0x400,%edx
f01057d7:	e8 fb fe ff ff       	call   f01056d7 <mpsearch1>
f01057dc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01057df:	85 c0                	test   %eax,%eax
f01057e1:	75 1a                	jne    f01057fd <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f01057e3:	ba 00 00 01 00       	mov    $0x10000,%edx
f01057e8:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f01057ed:	e8 e5 fe ff ff       	call   f01056d7 <mpsearch1>
f01057f2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f01057f5:	85 c0                	test   %eax,%eax
f01057f7:	0f 84 5a 02 00 00    	je     f0105a57 <mp_init+0x2e7>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f01057fd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105800:	8b 70 04             	mov    0x4(%eax),%esi
f0105803:	85 f6                	test   %esi,%esi
f0105805:	74 06                	je     f010580d <mp_init+0x9d>
f0105807:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f010580b:	74 15                	je     f0105822 <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f010580d:	83 ec 0c             	sub    $0xc,%esp
f0105810:	68 fc 86 10 f0       	push   $0xf01086fc
f0105815:	e8 3f e0 ff ff       	call   f0103859 <cprintf>
f010581a:	83 c4 10             	add    $0x10,%esp
f010581d:	e9 35 02 00 00       	jmp    f0105a57 <mp_init+0x2e7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105822:	89 f0                	mov    %esi,%eax
f0105824:	c1 e8 0c             	shr    $0xc,%eax
f0105827:	3b 05 d8 9e 2a f0    	cmp    0xf02a9ed8,%eax
f010582d:	72 15                	jb     f0105844 <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010582f:	56                   	push   %esi
f0105830:	68 24 6b 10 f0       	push   $0xf0106b24
f0105835:	68 90 00 00 00       	push   $0x90
f010583a:	68 89 88 10 f0       	push   $0xf0108889
f010583f:	e8 fc a7 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105844:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f010584a:	83 ec 04             	sub    $0x4,%esp
f010584d:	6a 04                	push   $0x4
f010584f:	68 9e 88 10 f0       	push   $0xf010889e
f0105854:	53                   	push   %ebx
f0105855:	e8 c0 fc ff ff       	call   f010551a <memcmp>
f010585a:	83 c4 10             	add    $0x10,%esp
f010585d:	85 c0                	test   %eax,%eax
f010585f:	74 15                	je     f0105876 <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0105861:	83 ec 0c             	sub    $0xc,%esp
f0105864:	68 2c 87 10 f0       	push   $0xf010872c
f0105869:	e8 eb df ff ff       	call   f0103859 <cprintf>
f010586e:	83 c4 10             	add    $0x10,%esp
f0105871:	e9 e1 01 00 00       	jmp    f0105a57 <mp_init+0x2e7>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105876:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f010587a:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f010587e:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105881:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105886:	b8 00 00 00 00       	mov    $0x0,%eax
f010588b:	eb 0d                	jmp    f010589a <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f010588d:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0105894:	f0 
f0105895:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105897:	83 c0 01             	add    $0x1,%eax
f010589a:	39 c7                	cmp    %eax,%edi
f010589c:	75 ef                	jne    f010588d <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f010589e:	84 d2                	test   %dl,%dl
f01058a0:	74 15                	je     f01058b7 <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f01058a2:	83 ec 0c             	sub    $0xc,%esp
f01058a5:	68 60 87 10 f0       	push   $0xf0108760
f01058aa:	e8 aa df ff ff       	call   f0103859 <cprintf>
f01058af:	83 c4 10             	add    $0x10,%esp
f01058b2:	e9 a0 01 00 00       	jmp    f0105a57 <mp_init+0x2e7>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f01058b7:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f01058bb:	3c 04                	cmp    $0x4,%al
f01058bd:	74 1d                	je     f01058dc <mp_init+0x16c>
f01058bf:	3c 01                	cmp    $0x1,%al
f01058c1:	74 19                	je     f01058dc <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f01058c3:	83 ec 08             	sub    $0x8,%esp
f01058c6:	0f b6 c0             	movzbl %al,%eax
f01058c9:	50                   	push   %eax
f01058ca:	68 84 87 10 f0       	push   $0xf0108784
f01058cf:	e8 85 df ff ff       	call   f0103859 <cprintf>
f01058d4:	83 c4 10             	add    $0x10,%esp
f01058d7:	e9 7b 01 00 00       	jmp    f0105a57 <mp_init+0x2e7>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f01058dc:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f01058e0:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f01058e4:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f01058e9:	b8 00 00 00 00       	mov    $0x0,%eax
f01058ee:	01 ce                	add    %ecx,%esi
f01058f0:	eb 0d                	jmp    f01058ff <mp_init+0x18f>
		sum += ((uint8_t *)addr)[i];
f01058f2:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f01058f9:	f0 
f01058fa:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01058fc:	83 c0 01             	add    $0x1,%eax
f01058ff:	39 c7                	cmp    %eax,%edi
f0105901:	75 ef                	jne    f01058f2 <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105903:	89 d0                	mov    %edx,%eax
f0105905:	02 43 2a             	add    0x2a(%ebx),%al
f0105908:	74 15                	je     f010591f <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f010590a:	83 ec 0c             	sub    $0xc,%esp
f010590d:	68 a4 87 10 f0       	push   $0xf01087a4
f0105912:	e8 42 df ff ff       	call   f0103859 <cprintf>
f0105917:	83 c4 10             	add    $0x10,%esp
f010591a:	e9 38 01 00 00       	jmp    f0105a57 <mp_init+0x2e7>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f010591f:	85 db                	test   %ebx,%ebx
f0105921:	0f 84 30 01 00 00    	je     f0105a57 <mp_init+0x2e7>
		return;
	ismp = 1;
f0105927:	c7 05 00 a0 2a f0 01 	movl   $0x1,0xf02aa000
f010592e:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0105931:	8b 43 24             	mov    0x24(%ebx),%eax
f0105934:	a3 00 b0 2e f0       	mov    %eax,0xf02eb000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105939:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f010593c:	be 00 00 00 00       	mov    $0x0,%esi
f0105941:	e9 85 00 00 00       	jmp    f01059cb <mp_init+0x25b>
		switch (*p) {
f0105946:	0f b6 07             	movzbl (%edi),%eax
f0105949:	84 c0                	test   %al,%al
f010594b:	74 06                	je     f0105953 <mp_init+0x1e3>
f010594d:	3c 04                	cmp    $0x4,%al
f010594f:	77 55                	ja     f01059a6 <mp_init+0x236>
f0105951:	eb 4e                	jmp    f01059a1 <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0105953:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0105957:	74 11                	je     f010596a <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f0105959:	6b 05 e4 a3 2a f0 74 	imul   $0x74,0xf02aa3e4,%eax
f0105960:	05 40 a0 2a f0       	add    $0xf02aa040,%eax
f0105965:	a3 e0 a3 2a f0       	mov    %eax,0xf02aa3e0
			if (ncpu < NCPU) {
f010596a:	a1 e4 a3 2a f0       	mov    0xf02aa3e4,%eax
f010596f:	83 f8 07             	cmp    $0x7,%eax
f0105972:	7f 13                	jg     f0105987 <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f0105974:	6b d0 74             	imul   $0x74,%eax,%edx
f0105977:	88 82 40 a0 2a f0    	mov    %al,-0xfd55fc0(%edx)
				ncpu++;
f010597d:	83 c0 01             	add    $0x1,%eax
f0105980:	a3 e4 a3 2a f0       	mov    %eax,0xf02aa3e4
f0105985:	eb 15                	jmp    f010599c <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0105987:	83 ec 08             	sub    $0x8,%esp
f010598a:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f010598e:	50                   	push   %eax
f010598f:	68 d4 87 10 f0       	push   $0xf01087d4
f0105994:	e8 c0 de ff ff       	call   f0103859 <cprintf>
f0105999:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f010599c:	83 c7 14             	add    $0x14,%edi
			continue;
f010599f:	eb 27                	jmp    f01059c8 <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f01059a1:	83 c7 08             	add    $0x8,%edi
			continue;
f01059a4:	eb 22                	jmp    f01059c8 <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f01059a6:	83 ec 08             	sub    $0x8,%esp
f01059a9:	0f b6 c0             	movzbl %al,%eax
f01059ac:	50                   	push   %eax
f01059ad:	68 fc 87 10 f0       	push   $0xf01087fc
f01059b2:	e8 a2 de ff ff       	call   f0103859 <cprintf>
			ismp = 0;
f01059b7:	c7 05 00 a0 2a f0 00 	movl   $0x0,0xf02aa000
f01059be:	00 00 00 
			i = conf->entry;
f01059c1:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f01059c5:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f01059c8:	83 c6 01             	add    $0x1,%esi
f01059cb:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f01059cf:	39 c6                	cmp    %eax,%esi
f01059d1:	0f 82 6f ff ff ff    	jb     f0105946 <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f01059d7:	a1 e0 a3 2a f0       	mov    0xf02aa3e0,%eax
f01059dc:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f01059e3:	83 3d 00 a0 2a f0 00 	cmpl   $0x0,0xf02aa000
f01059ea:	75 26                	jne    f0105a12 <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f01059ec:	c7 05 e4 a3 2a f0 01 	movl   $0x1,0xf02aa3e4
f01059f3:	00 00 00 
		lapicaddr = 0;
f01059f6:	c7 05 00 b0 2e f0 00 	movl   $0x0,0xf02eb000
f01059fd:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0105a00:	83 ec 0c             	sub    $0xc,%esp
f0105a03:	68 1c 88 10 f0       	push   $0xf010881c
f0105a08:	e8 4c de ff ff       	call   f0103859 <cprintf>
		return;
f0105a0d:	83 c4 10             	add    $0x10,%esp
f0105a10:	eb 45                	jmp    f0105a57 <mp_init+0x2e7>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0105a12:	83 ec 04             	sub    $0x4,%esp
f0105a15:	ff 35 e4 a3 2a f0    	pushl  0xf02aa3e4
f0105a1b:	0f b6 00             	movzbl (%eax),%eax
f0105a1e:	50                   	push   %eax
f0105a1f:	68 a3 88 10 f0       	push   $0xf01088a3
f0105a24:	e8 30 de ff ff       	call   f0103859 <cprintf>

	if (mp->imcrp) {
f0105a29:	83 c4 10             	add    $0x10,%esp
f0105a2c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105a2f:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0105a33:	74 22                	je     f0105a57 <mp_init+0x2e7>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0105a35:	83 ec 0c             	sub    $0xc,%esp
f0105a38:	68 48 88 10 f0       	push   $0xf0108848
f0105a3d:	e8 17 de ff ff       	call   f0103859 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105a42:	ba 22 00 00 00       	mov    $0x22,%edx
f0105a47:	b8 70 00 00 00       	mov    $0x70,%eax
f0105a4c:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0105a4d:	b2 23                	mov    $0x23,%dl
f0105a4f:	ec                   	in     (%dx),%al
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f0105a50:	83 c8 01             	or     $0x1,%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105a53:	ee                   	out    %al,(%dx)
f0105a54:	83 c4 10             	add    $0x10,%esp
	}
}
f0105a57:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105a5a:	5b                   	pop    %ebx
f0105a5b:	5e                   	pop    %esi
f0105a5c:	5f                   	pop    %edi
f0105a5d:	5d                   	pop    %ebp
f0105a5e:	c3                   	ret    

f0105a5f <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f0105a5f:	55                   	push   %ebp
f0105a60:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f0105a62:	8b 0d 04 b0 2e f0    	mov    0xf02eb004,%ecx
f0105a68:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0105a6b:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0105a6d:	a1 04 b0 2e f0       	mov    0xf02eb004,%eax
f0105a72:	8b 40 20             	mov    0x20(%eax),%eax
}
f0105a75:	5d                   	pop    %ebp
f0105a76:	c3                   	ret    

f0105a77 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f0105a77:	55                   	push   %ebp
f0105a78:	89 e5                	mov    %esp,%ebp
	if (lapic)
f0105a7a:	a1 04 b0 2e f0       	mov    0xf02eb004,%eax
f0105a7f:	85 c0                	test   %eax,%eax
f0105a81:	74 08                	je     f0105a8b <cpunum+0x14>
		return lapic[ID] >> 24;
f0105a83:	8b 40 20             	mov    0x20(%eax),%eax
f0105a86:	c1 e8 18             	shr    $0x18,%eax
f0105a89:	eb 05                	jmp    f0105a90 <cpunum+0x19>
	return 0;
f0105a8b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105a90:	5d                   	pop    %ebp
f0105a91:	c3                   	ret    

f0105a92 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0105a92:	a1 00 b0 2e f0       	mov    0xf02eb000,%eax
f0105a97:	85 c0                	test   %eax,%eax
f0105a99:	0f 84 21 01 00 00    	je     f0105bc0 <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f0105a9f:	55                   	push   %ebp
f0105aa0:	89 e5                	mov    %esp,%ebp
f0105aa2:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105aa5:	68 00 10 00 00       	push   $0x1000
f0105aaa:	50                   	push   %eax
f0105aab:	e8 22 b9 ff ff       	call   f01013d2 <mmio_map_region>
f0105ab0:	a3 04 b0 2e f0       	mov    %eax,0xf02eb004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105ab5:	ba 27 01 00 00       	mov    $0x127,%edx
f0105aba:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0105abf:	e8 9b ff ff ff       	call   f0105a5f <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0105ac4:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105ac9:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0105ace:	e8 8c ff ff ff       	call   f0105a5f <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0105ad3:	ba 20 00 02 00       	mov    $0x20020,%edx
f0105ad8:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0105add:	e8 7d ff ff ff       	call   f0105a5f <lapicw>
	lapicw(TICR, 10000000); 
f0105ae2:	ba 80 96 98 00       	mov    $0x989680,%edx
f0105ae7:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0105aec:	e8 6e ff ff ff       	call   f0105a5f <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0105af1:	e8 81 ff ff ff       	call   f0105a77 <cpunum>
f0105af6:	6b c0 74             	imul   $0x74,%eax,%eax
f0105af9:	05 40 a0 2a f0       	add    $0xf02aa040,%eax
f0105afe:	83 c4 10             	add    $0x10,%esp
f0105b01:	39 05 e0 a3 2a f0    	cmp    %eax,0xf02aa3e0
f0105b07:	74 0f                	je     f0105b18 <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f0105b09:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105b0e:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0105b13:	e8 47 ff ff ff       	call   f0105a5f <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f0105b18:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105b1d:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0105b22:	e8 38 ff ff ff       	call   f0105a5f <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0105b27:	a1 04 b0 2e f0       	mov    0xf02eb004,%eax
f0105b2c:	8b 40 30             	mov    0x30(%eax),%eax
f0105b2f:	c1 e8 10             	shr    $0x10,%eax
f0105b32:	3c 03                	cmp    $0x3,%al
f0105b34:	76 0f                	jbe    f0105b45 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f0105b36:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105b3b:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0105b40:	e8 1a ff ff ff       	call   f0105a5f <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0105b45:	ba 33 00 00 00       	mov    $0x33,%edx
f0105b4a:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0105b4f:	e8 0b ff ff ff       	call   f0105a5f <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f0105b54:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b59:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105b5e:	e8 fc fe ff ff       	call   f0105a5f <lapicw>
	lapicw(ESR, 0);
f0105b63:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b68:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105b6d:	e8 ed fe ff ff       	call   f0105a5f <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0105b72:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b77:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105b7c:	e8 de fe ff ff       	call   f0105a5f <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105b81:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b86:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105b8b:	e8 cf fe ff ff       	call   f0105a5f <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105b90:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105b95:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105b9a:	e8 c0 fe ff ff       	call   f0105a5f <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0105b9f:	8b 15 04 b0 2e f0    	mov    0xf02eb004,%edx
f0105ba5:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105bab:	f6 c4 10             	test   $0x10,%ah
f0105bae:	75 f5                	jne    f0105ba5 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0105bb0:	ba 00 00 00 00       	mov    $0x0,%edx
f0105bb5:	b8 20 00 00 00       	mov    $0x20,%eax
f0105bba:	e8 a0 fe ff ff       	call   f0105a5f <lapicw>
}
f0105bbf:	c9                   	leave  
f0105bc0:	f3 c3                	repz ret 

f0105bc2 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105bc2:	83 3d 04 b0 2e f0 00 	cmpl   $0x0,0xf02eb004
f0105bc9:	74 13                	je     f0105bde <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f0105bcb:	55                   	push   %ebp
f0105bcc:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0105bce:	ba 00 00 00 00       	mov    $0x0,%edx
f0105bd3:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105bd8:	e8 82 fe ff ff       	call   f0105a5f <lapicw>
}
f0105bdd:	5d                   	pop    %ebp
f0105bde:	f3 c3                	repz ret 

f0105be0 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0105be0:	55                   	push   %ebp
f0105be1:	89 e5                	mov    %esp,%ebp
f0105be3:	56                   	push   %esi
f0105be4:	53                   	push   %ebx
f0105be5:	8b 75 08             	mov    0x8(%ebp),%esi
f0105be8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105beb:	ba 70 00 00 00       	mov    $0x70,%edx
f0105bf0:	b8 0f 00 00 00       	mov    $0xf,%eax
f0105bf5:	ee                   	out    %al,(%dx)
f0105bf6:	b2 71                	mov    $0x71,%dl
f0105bf8:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105bfd:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105bfe:	83 3d d8 9e 2a f0 00 	cmpl   $0x0,0xf02a9ed8
f0105c05:	75 19                	jne    f0105c20 <lapic_startap+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105c07:	68 67 04 00 00       	push   $0x467
f0105c0c:	68 24 6b 10 f0       	push   $0xf0106b24
f0105c11:	68 98 00 00 00       	push   $0x98
f0105c16:	68 c0 88 10 f0       	push   $0xf01088c0
f0105c1b:	e8 20 a4 ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0105c20:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0105c27:	00 00 
	wrv[1] = addr >> 4;
f0105c29:	89 d8                	mov    %ebx,%eax
f0105c2b:	c1 e8 04             	shr    $0x4,%eax
f0105c2e:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0105c34:	c1 e6 18             	shl    $0x18,%esi
f0105c37:	89 f2                	mov    %esi,%edx
f0105c39:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105c3e:	e8 1c fe ff ff       	call   f0105a5f <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0105c43:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0105c48:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c4d:	e8 0d fe ff ff       	call   f0105a5f <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0105c52:	ba 00 85 00 00       	mov    $0x8500,%edx
f0105c57:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c5c:	e8 fe fd ff ff       	call   f0105a5f <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105c61:	c1 eb 0c             	shr    $0xc,%ebx
f0105c64:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105c67:	89 f2                	mov    %esi,%edx
f0105c69:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105c6e:	e8 ec fd ff ff       	call   f0105a5f <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105c73:	89 da                	mov    %ebx,%edx
f0105c75:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c7a:	e8 e0 fd ff ff       	call   f0105a5f <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105c7f:	89 f2                	mov    %esi,%edx
f0105c81:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105c86:	e8 d4 fd ff ff       	call   f0105a5f <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105c8b:	89 da                	mov    %ebx,%edx
f0105c8d:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c92:	e8 c8 fd ff ff       	call   f0105a5f <lapicw>
		microdelay(200);
	}
}
f0105c97:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105c9a:	5b                   	pop    %ebx
f0105c9b:	5e                   	pop    %esi
f0105c9c:	5d                   	pop    %ebp
f0105c9d:	c3                   	ret    

f0105c9e <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105c9e:	55                   	push   %ebp
f0105c9f:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105ca1:	8b 55 08             	mov    0x8(%ebp),%edx
f0105ca4:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0105caa:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105caf:	e8 ab fd ff ff       	call   f0105a5f <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0105cb4:	8b 15 04 b0 2e f0    	mov    0xf02eb004,%edx
f0105cba:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105cc0:	f6 c4 10             	test   $0x10,%ah
f0105cc3:	75 f5                	jne    f0105cba <lapic_ipi+0x1c>
		;
}
f0105cc5:	5d                   	pop    %ebp
f0105cc6:	c3                   	ret    

f0105cc7 <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0105cc7:	55                   	push   %ebp
f0105cc8:	89 e5                	mov    %esp,%ebp
f0105cca:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0105ccd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105cd3:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105cd6:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f0105cd9:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0105ce0:	5d                   	pop    %ebp
f0105ce1:	c3                   	ret    

f0105ce2 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0105ce2:	55                   	push   %ebp
f0105ce3:	89 e5                	mov    %esp,%ebp
f0105ce5:	56                   	push   %esi
f0105ce6:	53                   	push   %ebx
f0105ce7:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105cea:	83 3b 00             	cmpl   $0x0,(%ebx)
f0105ced:	74 14                	je     f0105d03 <spin_lock+0x21>
f0105cef:	8b 73 08             	mov    0x8(%ebx),%esi
f0105cf2:	e8 80 fd ff ff       	call   f0105a77 <cpunum>
f0105cf7:	6b c0 74             	imul   $0x74,%eax,%eax
f0105cfa:	05 40 a0 2a f0       	add    $0xf02aa040,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0105cff:	39 c6                	cmp    %eax,%esi
f0105d01:	74 07                	je     f0105d0a <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0105d03:	ba 01 00 00 00       	mov    $0x1,%edx
f0105d08:	eb 20                	jmp    f0105d2a <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0105d0a:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0105d0d:	e8 65 fd ff ff       	call   f0105a77 <cpunum>
f0105d12:	83 ec 0c             	sub    $0xc,%esp
f0105d15:	53                   	push   %ebx
f0105d16:	50                   	push   %eax
f0105d17:	68 d0 88 10 f0       	push   $0xf01088d0
f0105d1c:	6a 41                	push   $0x41
f0105d1e:	68 32 89 10 f0       	push   $0xf0108932
f0105d23:	e8 18 a3 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0105d28:	f3 90                	pause  
f0105d2a:	89 d0                	mov    %edx,%eax
f0105d2c:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0105d2f:	85 c0                	test   %eax,%eax
f0105d31:	75 f5                	jne    f0105d28 <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0105d33:	e8 3f fd ff ff       	call   f0105a77 <cpunum>
f0105d38:	6b c0 74             	imul   $0x74,%eax,%eax
f0105d3b:	05 40 a0 2a f0       	add    $0xf02aa040,%eax
f0105d40:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0105d43:	83 c3 0c             	add    $0xc,%ebx
get_caller_pcs(uint32_t pcs[])
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
f0105d46:	89 ea                	mov    %ebp,%edx
	for (i = 0; i < 10; i++){
f0105d48:	b8 00 00 00 00       	mov    $0x0,%eax
f0105d4d:	eb 0b                	jmp    f0105d5a <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f0105d4f:	8b 4a 04             	mov    0x4(%edx),%ecx
f0105d52:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0105d55:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105d57:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105d5a:	83 f8 09             	cmp    $0x9,%eax
f0105d5d:	7f 14                	jg     f0105d73 <spin_lock+0x91>
f0105d5f:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0105d65:	77 e8                	ja     f0105d4f <spin_lock+0x6d>
f0105d67:	eb 0a                	jmp    f0105d73 <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0105d69:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0105d70:	83 c0 01             	add    $0x1,%eax
f0105d73:	83 f8 09             	cmp    $0x9,%eax
f0105d76:	7e f1                	jle    f0105d69 <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f0105d78:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105d7b:	5b                   	pop    %ebx
f0105d7c:	5e                   	pop    %esi
f0105d7d:	5d                   	pop    %ebp
f0105d7e:	c3                   	ret    

f0105d7f <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105d7f:	55                   	push   %ebp
f0105d80:	89 e5                	mov    %esp,%ebp
f0105d82:	57                   	push   %edi
f0105d83:	56                   	push   %esi
f0105d84:	53                   	push   %ebx
f0105d85:	83 ec 4c             	sub    $0x4c,%esp
f0105d88:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105d8b:	83 3e 00             	cmpl   $0x0,(%esi)
f0105d8e:	74 18                	je     f0105da8 <spin_unlock+0x29>
f0105d90:	8b 5e 08             	mov    0x8(%esi),%ebx
f0105d93:	e8 df fc ff ff       	call   f0105a77 <cpunum>
f0105d98:	6b c0 74             	imul   $0x74,%eax,%eax
f0105d9b:	05 40 a0 2a f0       	add    $0xf02aa040,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0105da0:	39 c3                	cmp    %eax,%ebx
f0105da2:	0f 84 a5 00 00 00    	je     f0105e4d <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0105da8:	83 ec 04             	sub    $0x4,%esp
f0105dab:	6a 28                	push   $0x28
f0105dad:	8d 46 0c             	lea    0xc(%esi),%eax
f0105db0:	50                   	push   %eax
f0105db1:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0105db4:	53                   	push   %ebx
f0105db5:	e8 e5 f6 ff ff       	call   f010549f <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105dba:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105dbd:	0f b6 38             	movzbl (%eax),%edi
f0105dc0:	8b 76 04             	mov    0x4(%esi),%esi
f0105dc3:	e8 af fc ff ff       	call   f0105a77 <cpunum>
f0105dc8:	57                   	push   %edi
f0105dc9:	56                   	push   %esi
f0105dca:	50                   	push   %eax
f0105dcb:	68 fc 88 10 f0       	push   $0xf01088fc
f0105dd0:	e8 84 da ff ff       	call   f0103859 <cprintf>
f0105dd5:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0105dd8:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0105ddb:	eb 54                	jmp    f0105e31 <spin_unlock+0xb2>
f0105ddd:	83 ec 08             	sub    $0x8,%esp
f0105de0:	57                   	push   %edi
f0105de1:	50                   	push   %eax
f0105de2:	e8 d5 eb ff ff       	call   f01049bc <debuginfo_eip>
f0105de7:	83 c4 10             	add    $0x10,%esp
f0105dea:	85 c0                	test   %eax,%eax
f0105dec:	78 27                	js     f0105e15 <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0105dee:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0105df0:	83 ec 04             	sub    $0x4,%esp
f0105df3:	89 c2                	mov    %eax,%edx
f0105df5:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0105df8:	52                   	push   %edx
f0105df9:	ff 75 b0             	pushl  -0x50(%ebp)
f0105dfc:	ff 75 b4             	pushl  -0x4c(%ebp)
f0105dff:	ff 75 ac             	pushl  -0x54(%ebp)
f0105e02:	ff 75 a8             	pushl  -0x58(%ebp)
f0105e05:	50                   	push   %eax
f0105e06:	68 42 89 10 f0       	push   $0xf0108942
f0105e0b:	e8 49 da ff ff       	call   f0103859 <cprintf>
f0105e10:	83 c4 20             	add    $0x20,%esp
f0105e13:	eb 12                	jmp    f0105e27 <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f0105e15:	83 ec 08             	sub    $0x8,%esp
f0105e18:	ff 36                	pushl  (%esi)
f0105e1a:	68 59 89 10 f0       	push   $0xf0108959
f0105e1f:	e8 35 da ff ff       	call   f0103859 <cprintf>
f0105e24:	83 c4 10             	add    $0x10,%esp
f0105e27:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0105e2a:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0105e2d:	39 c3                	cmp    %eax,%ebx
f0105e2f:	74 08                	je     f0105e39 <spin_unlock+0xba>
f0105e31:	89 de                	mov    %ebx,%esi
f0105e33:	8b 03                	mov    (%ebx),%eax
f0105e35:	85 c0                	test   %eax,%eax
f0105e37:	75 a4                	jne    f0105ddd <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f0105e39:	83 ec 04             	sub    $0x4,%esp
f0105e3c:	68 61 89 10 f0       	push   $0xf0108961
f0105e41:	6a 67                	push   $0x67
f0105e43:	68 32 89 10 f0       	push   $0xf0108932
f0105e48:	e8 f3 a1 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f0105e4d:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0105e54:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
f0105e5b:	b8 00 00 00 00       	mov    $0x0,%eax
f0105e60:	f0 87 06             	lock xchg %eax,(%esi)
	// Paper says that Intel 64 and IA-32 will not move a load
	// after a store. So lock->locked = 0 would work here.
	// The xchg being asm volatile ensures gcc emits it after
	// the above assignments (and after the critical section).
	xchg(&lk->locked, 0);
}
f0105e63:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105e66:	5b                   	pop    %ebx
f0105e67:	5e                   	pop    %esi
f0105e68:	5f                   	pop    %edi
f0105e69:	5d                   	pop    %ebp
f0105e6a:	c3                   	ret    

f0105e6b <e1000_attach_device>:
struct rx_desc rx_descArray[E1000_RX_DESCTR] __attribute__ ((aligned (16)));
struct rx_pckt rx_pcktBuffer[E1000_RX_DESCTR];

int
e1000_attach_device(struct pci_func *pcif)
{
f0105e6b:	55                   	push   %ebp
f0105e6c:	89 e5                	mov    %esp,%ebp
f0105e6e:	53                   	push   %ebx
f0105e6f:	83 ec 10             	sub    $0x10,%esp
f0105e72:	8b 5d 08             	mov    0x8(%ebp),%ebx
	uint32_t i;

	// Enable PCI device
	pci_func_enable(pcif);
f0105e75:	53                   	push   %ebx
f0105e76:	e8 2d 08 00 00       	call   f01066a8 <pci_func_enable>
	
	//Mapping MMIO region 
	//boot_map_region(kern_pgdir, E1000_MMIO_ADDR,
	//		pcif->reg_size[0], pcif->reg_base[0], 
	//		PTE_PCD | PTE_PWT | PTE_W);
	e1000 = (void *) mmio_map_region(pcif->reg_base[0], pcif->reg_size[0]);
f0105e7b:	83 c4 08             	add    $0x8,%esp
f0105e7e:	ff 73 2c             	pushl  0x2c(%ebx)
f0105e81:	ff 73 14             	pushl  0x14(%ebx)
f0105e84:	e8 49 b5 ff ff       	call   f01013d2 <mmio_map_region>
f0105e89:	a3 d4 9e 2a f0       	mov    %eax,0xf02a9ed4
	
	assert(e1000[E1000_STATUS] == 0x80080783);
f0105e8e:	8b 50 08             	mov    0x8(%eax),%edx
f0105e91:	83 c4 10             	add    $0x10,%esp
f0105e94:	81 fa 83 07 08 80    	cmp    $0x80080783,%edx
f0105e9a:	74 16                	je     f0105eb2 <e1000_attach_device+0x47>
f0105e9c:	68 7c 89 10 f0       	push   $0xf010897c
f0105ea1:	68 db 7a 10 f0       	push   $0xf0107adb
f0105ea6:	6a 1d                	push   $0x1d
f0105ea8:	68 9e 89 10 f0       	push   $0xf010899e
f0105ead:	e8 8e a1 ff ff       	call   f0100040 <_panic>
	cprintf("E1000 status value: %08x\n", e1000[E1000_STATUS]);
f0105eb2:	8b 40 08             	mov    0x8(%eax),%eax
f0105eb5:	83 ec 08             	sub    $0x8,%esp
f0105eb8:	50                   	push   %eax
f0105eb9:	68 ab 89 10 f0       	push   $0xf01089ab
f0105ebe:	e8 96 d9 ff ff       	call   f0103859 <cprintf>


	//Transmit Initlialization
	//Clear the areas allocated by the software for the descriptors and buffers 
	memset(tx_descArray, 0x0, sizeof(struct tx_desc) * E1000_TX_DESCTR);
f0105ec3:	83 c4 0c             	add    $0xc,%esp
f0105ec6:	68 00 04 00 00       	push   $0x400
f0105ecb:	6a 00                	push   $0x0
f0105ecd:	68 40 b0 32 f0       	push   $0xf032b040
f0105ed2:	e8 7b f5 ff ff       	call   f0105452 <memset>
	memset(tx_pcktBuffer, 0x0, sizeof(struct tx_pckt) * E1000_TX_DESCTR);
f0105ed7:	83 c4 0c             	add    $0xc,%esp
f0105eda:	68 80 7b 01 00       	push   $0x17b80
f0105edf:	6a 00                	push   $0x0
f0105ee1:	68 40 b4 32 f0       	push   $0xf032b440
f0105ee6:	e8 67 f5 ff ff       	call   f0105452 <memset>
f0105eeb:	b8 40 b4 32 f0       	mov    $0xf032b440,%eax
f0105ef0:	ba 4c b0 32 f0       	mov    $0xf032b04c,%edx
f0105ef5:	bb c0 2f 34 f0       	mov    $0xf0342fc0,%ebx
f0105efa:	83 c4 10             	add    $0x10,%esp
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0105efd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0105f02:	77 12                	ja     f0105f16 <e1000_attach_device+0xab>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0105f04:	50                   	push   %eax
f0105f05:	68 48 6b 10 f0       	push   $0xf0106b48
f0105f0a:	6a 26                	push   $0x26
f0105f0c:	68 9e 89 10 f0       	push   $0xf010899e
f0105f11:	e8 2a a1 ff ff       	call   f0100040 <_panic>
f0105f16:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
	for (i = 0; i < E1000_TX_DESCTR; i++) {
		tx_descArray[i].addr = PADDR(tx_pcktBuffer[i].buf);
f0105f1c:	89 4a f4             	mov    %ecx,-0xc(%edx)
f0105f1f:	c7 42 f8 00 00 00 00 	movl   $0x0,-0x8(%edx)
		tx_descArray[i].status |= E1000_TXD_STAT_DD;
f0105f26:	80 0a 01             	orb    $0x1,(%edx)
f0105f29:	05 ee 05 00 00       	add    $0x5ee,%eax
f0105f2e:	83 c2 10             	add    $0x10,%edx

	//Transmit Initlialization
	//Clear the areas allocated by the software for the descriptors and buffers 
	memset(tx_descArray, 0x0, sizeof(struct tx_desc) * E1000_TX_DESCTR);
	memset(tx_pcktBuffer, 0x0, sizeof(struct tx_pckt) * E1000_TX_DESCTR);
	for (i = 0; i < E1000_TX_DESCTR; i++) {
f0105f31:	39 d8                	cmp    %ebx,%eax
f0105f33:	75 c8                	jne    f0105efd <e1000_attach_device+0x92>
		tx_descArray[i].status |= E1000_TXD_STAT_DD;
	}


	/*Program the Transmit Descriptor Base Address (TDBAL/TDBAH) register(s) with the address of the region.*/
	e1000[E1000_TDBAL] = PADDR(tx_descArray);	
f0105f35:	a1 d4 9e 2a f0       	mov    0xf02a9ed4,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0105f3a:	ba 40 b0 32 f0       	mov    $0xf032b040,%edx
f0105f3f:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0105f45:	77 12                	ja     f0105f59 <e1000_attach_device+0xee>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0105f47:	52                   	push   %edx
f0105f48:	68 48 6b 10 f0       	push   $0xf0106b48
f0105f4d:	6a 2c                	push   $0x2c
f0105f4f:	68 9e 89 10 f0       	push   $0xf010899e
f0105f54:	e8 e7 a0 ff ff       	call   f0100040 <_panic>
f0105f59:	c7 80 00 38 00 00 40 	movl   $0x32b040,0x3800(%eax)
f0105f60:	b0 32 00 
	e1000[E1000_TDBAH] = 0x0;
f0105f63:	c7 80 04 38 00 00 00 	movl   $0x0,0x3804(%eax)
f0105f6a:	00 00 00 

	/*Set the Transmit Descriptor Length (TDLEN) register to the size (in bytes) of the descriptor ring.
	This register must be 128-byte aligned.*/
	e1000[E1000_TDLEN] = sizeof(struct tx_desc) * E1000_TX_DESCTR;
f0105f6d:	c7 80 08 38 00 00 00 	movl   $0x400,0x3808(%eax)
f0105f74:	04 00 00 

	/*The Transmit Descriptor Head and Tail (TDH/TDT) registers are initialized (by hardware) to 0.
	Software should write 0b to both these registers to ensure this.*/
	e1000[E1000_TDH] = 0x0;
f0105f77:	c7 80 10 38 00 00 00 	movl   $0x0,0x3810(%eax)
f0105f7e:	00 00 00 
	e1000[E1000_TDT] = 0x0;
f0105f81:	c7 80 18 38 00 00 00 	movl   $0x0,0x3818(%eax)
f0105f88:	00 00 00 

	/*Initialize the Transmit Control Register (TCTL) for desired operation to include the following:

	• Set the Enable (TCTL.EN) bit to 1b for normal operation. */
	e1000[E1000_TCTL] |= E1000_TCTL_EN;
f0105f8b:	8b 90 00 04 00 00    	mov    0x400(%eax),%edx
f0105f91:	83 ca 02             	or     $0x2,%edx
f0105f94:	89 90 00 04 00 00    	mov    %edx,0x400(%eax)

	/*• Set the Pad Short Packets (TCTL.PSP) bit to 1b.*/
	e1000[E1000_TCTL] |= E1000_TCTL_PSP;
f0105f9a:	8b 90 00 04 00 00    	mov    0x400(%eax),%edx
f0105fa0:	83 ca 08             	or     $0x8,%edx
f0105fa3:	89 90 00 04 00 00    	mov    %edx,0x400(%eax)

	/*Configure the Collision Threshold (TCTL.CT) to the desired value.The value is 10h*/
	e1000[E1000_TCTL] &= ~E1000_TCTL_CT;	//Clear the specified bits first
f0105fa9:	8b 90 00 04 00 00    	mov    0x400(%eax),%edx
f0105faf:	81 e2 0f f0 ff ff    	and    $0xfffff00f,%edx
f0105fb5:	89 90 00 04 00 00    	mov    %edx,0x400(%eax)
	e1000[E1000_TCTL] |= (0x10) << 4;		//Set the values as required to 10h
f0105fbb:	8b 90 00 04 00 00    	mov    0x400(%eax),%edx
f0105fc1:	80 ce 01             	or     $0x1,%dh
f0105fc4:	89 90 00 04 00 00    	mov    %edx,0x400(%eax)

	/*Configure the Collision Distance (TCTL.COLD) to its expected value.For full duplex
	operation, this value should be set to 40h */
	e1000[E1000_TCTL] &= ~E1000_TCTL_COLD;	//Clear the specified bits first
f0105fca:	8b 90 00 04 00 00    	mov    0x400(%eax),%edx
f0105fd0:	81 e2 ff 0f c0 ff    	and    $0xffc00fff,%edx
f0105fd6:	89 90 00 04 00 00    	mov    %edx,0x400(%eax)
	e1000[E1000_TCTL] |= (0x40) << 12;		//Set the value to 40h for full duplex
f0105fdc:	8b 90 00 04 00 00    	mov    0x400(%eax),%edx
f0105fe2:	81 ca 00 00 04 00    	or     $0x40000,%edx
f0105fe8:	89 90 00 04 00 00    	mov    %edx,0x400(%eax)

	/*Program the Transmit IPG (TIPG) register*/
	e1000[E1000_TIPG] = 0x0;
f0105fee:	c7 80 10 04 00 00 00 	movl   $0x0,0x410(%eax)
f0105ff5:	00 00 00 
	
	/*IPG Receive Time 2
	Specifies the total length of the IPG time for non back-to-back
	transmissions.
	IPGR2 In order to calculate the actual IPG value, a value of six should be added to the IPGR2 value*/
	e1000[E1000_TIPG] |= (0x6) << 20; 
f0105ff8:	8b 90 10 04 00 00    	mov    0x410(%eax),%edx
f0105ffe:	81 ca 00 00 60 00    	or     $0x600000,%edx
f0106004:	89 90 10 04 00 00    	mov    %edx,0x410(%eax)
	to-back transmissions. During this time, the internal IPG counter
	restarts if any carrier event occurs. Once the time specified in
	IPGR1 has elapsed, carrier sense does not affect the IPG
	counter.
	According to the IEEE802.3 standard, IPGR1 should be 2/3 of IPGR2 value.*/
	e1000[E1000_TIPG] |= (0x4) << 10; // IPGR1
f010600a:	8b 90 10 04 00 00    	mov    0x410(%eax),%edx
f0106010:	80 ce 10             	or     $0x10,%dh
f0106013:	89 90 10 04 00 00    	mov    %edx,0x410(%eax)

	/*PG Transmit Time
	Specifies the IPG time for back-to-back packet transmissions*/
	e1000[E1000_TIPG] |= 0xA; // IPGT should be 10
f0106019:	8b 90 10 04 00 00    	mov    0x410(%eax),%edx
f010601f:	83 ca 0a             	or     $0xa,%edx
f0106022:	89 90 10 04 00 00    	mov    %edx,0x410(%eax)
	
	//Receive initalization
	// Initialize rcv desc buffer array
	memset(rx_descArray, 0x0, sizeof(struct rx_desc) * E1000_RX_DESCTR);
f0106028:	83 ec 04             	sub    $0x4,%esp
f010602b:	68 00 08 00 00       	push   $0x800
f0106030:	6a 00                	push   $0x0
f0106032:	68 c0 2f 34 f0       	push   $0xf0342fc0
f0106037:	e8 16 f4 ff ff       	call   f0105452 <memset>
	memset(rx_pcktBuffer, 0x0, sizeof(struct rx_pckt) * E1000_RX_DESCTR);
f010603c:	83 c4 0c             	add    $0xc,%esp
f010603f:	68 00 00 04 00       	push   $0x40000
f0106044:	6a 00                	push   $0x0
f0106046:	68 40 b0 2e f0       	push   $0xf02eb040
f010604b:	e8 02 f4 ff ff       	call   f0105452 <memset>
f0106050:	b8 40 b0 2e f0       	mov    $0xf02eb040,%eax
f0106055:	bb 40 b0 32 f0       	mov    $0xf032b040,%ebx
f010605a:	83 c4 10             	add    $0x10,%esp
f010605d:	ba c0 2f 34 f0       	mov    $0xf0342fc0,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0106062:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0106067:	77 12                	ja     f010607b <e1000_attach_device+0x210>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0106069:	50                   	push   %eax
f010606a:	68 48 6b 10 f0       	push   $0xf0106b48
f010606f:	6a 64                	push   $0x64
f0106071:	68 9e 89 10 f0       	push   $0xf010899e
f0106076:	e8 c5 9f ff ff       	call   f0100040 <_panic>
f010607b:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
	for (i = 0; i < E1000_RX_DESCTR; i++) {
		rx_descArray[i].addr = PADDR(rx_pcktBuffer[i].buffer);
f0106081:	89 0a                	mov    %ecx,(%edx)
f0106083:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
f010608a:	05 00 08 00 00       	add    $0x800,%eax
f010608f:	83 c2 10             	add    $0x10,%edx
	
	//Receive initalization
	// Initialize rcv desc buffer array
	memset(rx_descArray, 0x0, sizeof(struct rx_desc) * E1000_RX_DESCTR);
	memset(rx_pcktBuffer, 0x0, sizeof(struct rx_pckt) * E1000_RX_DESCTR);
	for (i = 0; i < E1000_RX_DESCTR; i++) {
f0106092:	39 d8                	cmp    %ebx,%eax
f0106094:	75 cc                	jne    f0106062 <e1000_attach_device+0x1f7>

	//Receive program initalization 

	/*Program the Receive Address Register(s) (RAL/RAH) with the desired Ethernet addresses. 
	RAL[0]/RAH[0] should always be used to store the Individual Ethernet MAC address of the Ethernet controller.*/
	e1000[E1000_RAL] |= 0x12005452;  //52:54:00:12
f0106096:	a1 d4 9e 2a f0       	mov    0xf02a9ed4,%eax
f010609b:	8b 90 00 54 00 00    	mov    0x5400(%eax),%edx
f01060a1:	81 ca 52 54 00 12    	or     $0x12005452,%edx
f01060a7:	89 90 00 54 00 00    	mov    %edx,0x5400(%eax)
 	e1000[E1000_RAH] |= 0x5634;  //34:56
f01060ad:	8b 90 04 54 00 00    	mov    0x5404(%eax),%edx
f01060b3:	81 ca 34 56 00 00    	or     $0x5634,%edx
f01060b9:	89 90 04 54 00 00    	mov    %edx,0x5404(%eax)
	e1000[E1000_RAH] |= E1000_RAH_AV;  //Enable Address Valid, given as a hint in the LAB writeup
f01060bf:	8b 90 04 54 00 00    	mov    0x5404(%eax),%edx
f01060c5:	81 ca 00 00 00 80    	or     $0x80000000,%edx
f01060cb:	89 90 04 54 00 00    	mov    %edx,0x5404(%eax)

	//Initialize the MTA (Multicast Table Array) to 0b
	e1000[E1000_MTA] = 0;
f01060d1:	c7 80 00 52 00 00 00 	movl   $0x0,0x5200(%eax)
f01060d8:	00 00 00 
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01060db:	ba c0 2f 34 f0       	mov    $0xf0342fc0,%edx
f01060e0:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01060e6:	77 12                	ja     f01060fa <e1000_attach_device+0x28f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01060e8:	52                   	push   %edx
f01060e9:	68 48 6b 10 f0       	push   $0xf0106b48
f01060ee:	6a 77                	push   $0x77
f01060f0:	68 9e 89 10 f0       	push   $0xf010899e
f01060f5:	e8 46 9f ff ff       	call   f0100040 <_panic>
	/*Allocate a region of memory for the receive descriptor list. Software should insure this memory is
aligned on a paragraph (16-byte) boundary. Program the Receive Descriptor Base Address
(RDBAL/RDBAH) register(s) with the address of the region. RDBAL is used for 32-bit addresses
and both RDBAL and RDBAH are used for 64-bit addresses.*/

	e1000[E1000_RDBAL] = PADDR(rx_descArray);     
f01060fa:	c7 80 00 28 00 00 c0 	movl   $0x342fc0,0x2800(%eax)
f0106101:	2f 34 00 
	e1000[E1000_RDBAH] = 0;
f0106104:	c7 80 04 28 00 00 00 	movl   $0x0,0x2804(%eax)
f010610b:	00 00 00 
	
/*Set the Receive Descriptor Length (RDLEN) register to the size (in bytes) of the descriptor ring.
This register must be 128-byte aligned.*/
	e1000[E1000_RDLEN] = sizeof(struct rx_desc) * E1000_RX_DESCTR ;
f010610e:	c7 80 08 28 00 00 00 	movl   $0x800,0x2808(%eax)
f0106115:	08 00 00 
allocated and pointers to these buffers should be stored in the receive descriptor ring. Software
initializes the Receive Descriptor Head (RDH) register and Receive Descriptor Tail (RDT) with the
appropriate head and tail addresses. Head should point to the first valid receive descriptor in the
descriptor ring and tail should point to one descriptor beyond the last valid descriptor in the
descriptor ring.*/
	e1000[E1000_RDH] = 0;
f0106118:	c7 80 10 28 00 00 00 	movl   $0x0,0x2810(%eax)
f010611f:	00 00 00 
	e1000[E1000_RDT] = E1000_RX_DESCTR -1;
f0106122:	c7 80 18 28 00 00 7f 	movl   $0x7f,0x2818(%eax)
f0106129:	00 00 00 


//Register settings

	e1000[E1000_RCTL] =0;
f010612c:	c7 80 00 01 00 00 00 	movl   $0x0,0x100(%eax)
f0106133:	00 00 00 


	e1000[E1000_RCTL] |= E1000_RCTL_EN ;  //Set the receiver Enable (RCTL.EN) bit to 1b for normal operation.
f0106136:	8b 90 00 01 00 00    	mov    0x100(%eax),%edx
f010613c:	83 ca 02             	or     $0x2,%edx
f010613f:	89 90 00 01 00 00    	mov    %edx,0x100(%eax)
	e1000[E1000_RCTL] &= ~E1000_RCTL_LPE; //Set the Long Packet Enable (RCTL.LPE) bit to 1b
f0106145:	8b 90 00 01 00 00    	mov    0x100(%eax),%edx
f010614b:	83 e2 df             	and    $0xffffffdf,%edx
f010614e:	89 90 00 01 00 00    	mov    %edx,0x100(%eax)
	e1000[E1000_RCTL] |= E1000_RCTL_LBM_NO ; //Loopback Mode (RCTL.LBM) should be set to 00b
f0106154:	8b 90 00 01 00 00    	mov    0x100(%eax),%edx
f010615a:	89 90 00 01 00 00    	mov    %edx,0x100(%eax)

	e1000[E1000_RCTL] |= E1000_RCTL_RDMTS_HALF;  //Configure the Receive Descriptor Minimum Threshold Size (RCTL.RDMTS) bits to the desired value.
f0106160:	8b 90 00 01 00 00    	mov    0x100(%eax),%edx
f0106166:	89 90 00 01 00 00    	mov    %edx,0x100(%eax)
	e1000[E1000_RCTL] |= E1000_RCTL_MO_0;//Configure the Multicast Offset (RCTL.MO) bits to the desired value.
f010616c:	8b 90 00 01 00 00    	mov    0x100(%eax),%edx
f0106172:	89 90 00 01 00 00    	mov    %edx,0x100(%eax)

	e1000[E1000_RCTL] |= E1000_RCTL_BAM ; // Set the Broadcast Accept Mode (RCTL.BAM) bit to 1b allowing the hardware to accept broadcast packets.
f0106178:	8b 90 00 01 00 00    	mov    0x100(%eax),%edx
f010617e:	80 ce 80             	or     $0x80,%dh
f0106181:	89 90 00 01 00 00    	mov    %edx,0x100(%eax)

/*Configure the Receive Buffer Size (RCTL.BSIZE) bits to reflect the size of the receive buffers
software provides to hardware. Also configure the Buffer Extension Size (RCTL.BSEX) bits if
receive buffer needs to be larger than 2048 bytes.*/
 	e1000[E1000_RCTL] |= E1000_RCTL_SZ_2048 ; //buffer size 2048bytes
f0106187:	8b 90 00 01 00 00    	mov    0x100(%eax),%edx
f010618d:	89 90 00 01 00 00    	mov    %edx,0x100(%eax)
	e1000[E1000_RCTL] &= ~E1000_RCTL_BSEX ;  //no size extension
f0106193:	8b 90 00 01 00 00    	mov    0x100(%eax),%edx
f0106199:	81 e2 ff ff ff fd    	and    $0xfdffffff,%edx
f010619f:	89 90 00 01 00 00    	mov    %edx,0x100(%eax)
	
/*Set the Strip Ethernet CRC (RCTL.SECRC) bit if the desire is for hardware to strip the CRC
prior to DMA-ing the receive packet to host memory.*/
	e1000[E1000_RCTL] |= E1000_RCTL_SECRC;  //Strip CRC from incoming packet
f01061a5:	8b 90 00 01 00 00    	mov    0x100(%eax),%edx
f01061ab:	81 ca 00 00 00 04    	or     $0x4000000,%edx
f01061b1:	89 90 00 01 00 00    	mov    %edx,0x100(%eax)
	char b[] = "This is a test function";
	e1000_Transmit_packet(a, sizeof(a));
	e1000_Transmit_packet(b, sizeof(b));
	*/
	return 0;
}
f01061b7:	b8 00 00 00 00       	mov    $0x0,%eax
f01061bc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01061bf:	c9                   	leave  
f01061c0:	c3                   	ret    

f01061c1 <e1000_Transmit_packet>:



int e1000_Transmit_packet(char *data, int length) //Transmit a packet of length and data
{
f01061c1:	55                   	push   %ebp
f01061c2:	89 e5                	mov    %esp,%ebp
f01061c4:	56                   	push   %esi
f01061c5:	53                   	push   %ebx
f01061c6:	8b 75 0c             	mov    0xc(%ebp),%esi
	//Make sure the length is within the limits
	if (length > E1000_TX_PCKT_SIZE)
f01061c9:	81 fe ee 05 00 00    	cmp    $0x5ee,%esi
f01061cf:	7f 65                	jg     f0106236 <e1000_Transmit_packet+0x75>
		return -E_PCKT_LONG;

	/*Note that TDT is an index into the transmit descriptor array, not a byte offset;*/
	uint32_t tdt = e1000[E1000_TDT]; //Transmit descriptor tail register. 
f01061d1:	a1 d4 9e 2a f0       	mov    0xf02a9ed4,%eax
f01061d6:	8b 98 18 38 00 00    	mov    0x3818(%eax),%ebx
	
	//Checking if the TX queue has descriptors available
	if (tx_descArray[tdt].status & E1000_TXD_STAT_DD) {
f01061dc:	89 d8                	mov    %ebx,%eax
f01061de:	c1 e0 04             	shl    $0x4,%eax
f01061e1:	f6 80 4c b0 32 f0 01 	testb  $0x1,-0xfcd4fb4(%eax)
f01061e8:	74 53                	je     f010623d <e1000_Transmit_packet+0x7c>
		memmove(tx_pcktBuffer[tdt].buf, data, length);
f01061ea:	83 ec 04             	sub    $0x4,%esp
f01061ed:	56                   	push   %esi
f01061ee:	ff 75 08             	pushl  0x8(%ebp)
f01061f1:	69 c3 ee 05 00 00    	imul   $0x5ee,%ebx,%eax
f01061f7:	05 40 b4 32 f0       	add    $0xf032b440,%eax
f01061fc:	50                   	push   %eax
f01061fd:	e8 9d f2 ff ff       	call   f010549f <memmove>
		tx_descArray[tdt].length = length;
f0106202:	89 d8                	mov    %ebx,%eax
f0106204:	c1 e0 04             	shl    $0x4,%eax
f0106207:	66 89 b0 48 b0 32 f0 	mov    %si,-0xfcd4fb8(%eax)
f010620e:	05 40 b0 32 f0       	add    $0xf032b040,%eax

		tx_descArray[tdt].status &= ~E1000_TXD_STAT_DD;
f0106213:	80 60 0c fe          	andb   $0xfe,0xc(%eax)
		tx_descArray[tdt].cmd |= E1000_TXD_CMD_RS;
		tx_descArray[tdt].cmd |= E1000_TXD_CMD_EOP;
f0106217:	80 48 0b 09          	orb    $0x9,0xb(%eax)

		//Update the TDT register to point to next array
		e1000[E1000_TDT] = (tdt + 1) % E1000_TX_DESCTR;
f010621b:	83 c3 01             	add    $0x1,%ebx
f010621e:	83 e3 3f             	and    $0x3f,%ebx
f0106221:	a1 d4 9e 2a f0       	mov    0xf02a9ed4,%eax
f0106226:	89 98 18 38 00 00    	mov    %ebx,0x3818(%eax)
	}
	
	else
		return -E_TX_Q_FULL;
	
	return 0;
f010622c:	83 c4 10             	add    $0x10,%esp
f010622f:	b8 00 00 00 00       	mov    $0x0,%eax
f0106234:	eb 0c                	jmp    f0106242 <e1000_Transmit_packet+0x81>

int e1000_Transmit_packet(char *data, int length) //Transmit a packet of length and data
{
	//Make sure the length is within the limits
	if (length > E1000_TX_PCKT_SIZE)
		return -E_PCKT_LONG;
f0106236:	b8 ee ff ff ff       	mov    $0xffffffee,%eax
f010623b:	eb 05                	jmp    f0106242 <e1000_Transmit_packet+0x81>
		//Update the TDT register to point to next array
		e1000[E1000_TDT] = (tdt + 1) % E1000_TX_DESCTR;
	}
	
	else
		return -E_TX_Q_FULL;
f010623d:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
	
	return 0;
}
f0106242:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0106245:	5b                   	pop    %ebx
f0106246:	5e                   	pop    %esi
f0106247:	5d                   	pop    %ebp
f0106248:	c3                   	ret    

f0106249 <e1000_Receive_data>:


int e1000_Receive_data(char *data) //Receive a packet of data
{
f0106249:	55                   	push   %ebp
f010624a:	89 e5                	mov    %esp,%ebp
f010624c:	57                   	push   %edi
f010624d:	56                   	push   %esi
f010624e:	53                   	push   %ebx
f010624f:	83 ec 0c             	sub    $0xc,%esp
	
	uint32_t rdt_tail;
	uint32_t length;
	rdt_tail = e1000[E1000_RDT];  //Tail
f0106252:	a1 d4 9e 2a f0       	mov    0xf02a9ed4,%eax
f0106257:	8b 98 18 28 00 00    	mov    0x2818(%eax),%ebx
	rdt_tail = (rdt_tail+1)%E1000_RX_DESCTR;  //assign the tail 
f010625d:	83 c3 01             	add    $0x1,%ebx
f0106260:	83 e3 7f             	and    $0x7f,%ebx
	
	if (rx_descArray[rdt_tail].status & E1000_RXD_STAT_DD) {  //Check if the buffer is empty
f0106263:	89 d8                	mov    %ebx,%eax
f0106265:	c1 e0 04             	shl    $0x4,%eax
f0106268:	0f b6 80 cc 2f 34 f0 	movzbl -0xfcbd034(%eax),%eax
f010626f:	a8 01                	test   $0x1,%al
f0106271:	74 68                	je     f01062db <e1000_Receive_data+0x92>
		if (!(rx_descArray[rdt_tail].status & E1000_RXD_STAT_EOP)) { //Condition for jumbo frame check
f0106273:	a8 02                	test   $0x2,%al
f0106275:	75 17                	jne    f010628e <e1000_Receive_data+0x45>
			panic("Don't allow extended frames!\n");
f0106277:	83 ec 04             	sub    $0x4,%esp
f010627a:	68 c5 89 10 f0       	push   $0xf01089c5
f010627f:	68 d6 00 00 00       	push   $0xd6
f0106284:	68 9e 89 10 f0       	push   $0xf010899e
f0106289:	e8 b2 9d ff ff       	call   f0100040 <_panic>
		}
		length = rx_descArray[rdt_tail].length; 
f010628e:	89 df                	mov    %ebx,%edi
f0106290:	c1 e7 04             	shl    $0x4,%edi
f0106293:	0f b7 b7 c8 2f 34 f0 	movzwl -0xfcbd038(%edi),%esi
f010629a:	81 c7 c0 2f 34 f0    	add    $0xf0342fc0,%edi
		cprintf ("Length is: %d\n",length);
f01062a0:	83 ec 08             	sub    $0x8,%esp
f01062a3:	56                   	push   %esi
f01062a4:	68 e3 89 10 f0       	push   $0xf01089e3
f01062a9:	e8 ab d5 ff ff       	call   f0103859 <cprintf>
		memcpy(data, rx_pcktBuffer[rdt_tail].buffer, length); //Copy the data from the buffer
f01062ae:	83 c4 0c             	add    $0xc,%esp
f01062b1:	56                   	push   %esi
f01062b2:	89 d8                	mov    %ebx,%eax
f01062b4:	c1 e0 0b             	shl    $0xb,%eax
f01062b7:	05 40 b0 2e f0       	add    $0xf02eb040,%eax
f01062bc:	50                   	push   %eax
f01062bd:	ff 75 08             	pushl  0x8(%ebp)
f01062c0:	e8 42 f2 ff ff       	call   f0105507 <memcpy>
		
		rx_descArray[rdt_tail].status &= ~E1000_RXD_STAT_DD;
		rx_descArray[rdt_tail].status &= ~E1000_RXD_STAT_EOP;
f01062c5:	80 67 0c fc          	andb   $0xfc,0xc(%edi)
		e1000[E1000_RDT] = rdt_tail;	//Update the tail
f01062c9:	a1 d4 9e 2a f0       	mov    0xf02a9ed4,%eax
f01062ce:	89 98 18 28 00 00    	mov    %ebx,0x2818(%eax)

		return length;	//Return the number of bytes
f01062d4:	89 f0                	mov    %esi,%eax
f01062d6:	83 c4 10             	add    $0x10,%esp
f01062d9:	eb 05                	jmp    f01062e0 <e1000_Receive_data+0x97>
	}

	return -E_RX_Q_EMPTY;  //Buffer is empty 
f01062db:	b8 ef ff ff ff       	mov    $0xffffffef,%eax

}
f01062e0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01062e3:	5b                   	pop    %ebx
f01062e4:	5e                   	pop    %esi
f01062e5:	5f                   	pop    %edi
f01062e6:	5d                   	pop    %ebp
f01062e7:	c3                   	ret    

f01062e8 <pci_attach_match>:
}

static int __attribute__((warn_unused_result))
pci_attach_match(uint32_t key1, uint32_t key2,
		 struct pci_driver *list, struct pci_func *pcif)
{
f01062e8:	55                   	push   %ebp
f01062e9:	89 e5                	mov    %esp,%ebp
f01062eb:	57                   	push   %edi
f01062ec:	56                   	push   %esi
f01062ed:	53                   	push   %ebx
f01062ee:	83 ec 0c             	sub    $0xc,%esp
f01062f1:	8b 7d 08             	mov    0x8(%ebp),%edi
f01062f4:	8b 45 10             	mov    0x10(%ebp),%eax
f01062f7:	8d 58 08             	lea    0x8(%eax),%ebx
	uint32_t i;

	for (i = 0; list[i].attachfn; i++) {
f01062fa:	eb 3a                	jmp    f0106336 <pci_attach_match+0x4e>
		if (list[i].key1 == key1 && list[i].key2 == key2) {
f01062fc:	39 7b f8             	cmp    %edi,-0x8(%ebx)
f01062ff:	75 32                	jne    f0106333 <pci_attach_match+0x4b>
f0106301:	8b 55 0c             	mov    0xc(%ebp),%edx
f0106304:	39 56 fc             	cmp    %edx,-0x4(%esi)
f0106307:	75 2a                	jne    f0106333 <pci_attach_match+0x4b>
			int r = list[i].attachfn(pcif);
f0106309:	83 ec 0c             	sub    $0xc,%esp
f010630c:	ff 75 14             	pushl  0x14(%ebp)
f010630f:	ff d0                	call   *%eax
			if (r > 0)
f0106311:	83 c4 10             	add    $0x10,%esp
f0106314:	85 c0                	test   %eax,%eax
f0106316:	7f 26                	jg     f010633e <pci_attach_match+0x56>
				return r;
			if (r < 0)
f0106318:	85 c0                	test   %eax,%eax
f010631a:	79 17                	jns    f0106333 <pci_attach_match+0x4b>
				cprintf("pci_attach_match: attaching "
f010631c:	83 ec 0c             	sub    $0xc,%esp
f010631f:	50                   	push   %eax
f0106320:	ff 36                	pushl  (%esi)
f0106322:	ff 75 0c             	pushl  0xc(%ebp)
f0106325:	57                   	push   %edi
f0106326:	68 f4 89 10 f0       	push   $0xf01089f4
f010632b:	e8 29 d5 ff ff       	call   f0103859 <cprintf>
f0106330:	83 c4 20             	add    $0x20,%esp
f0106333:	83 c3 0c             	add    $0xc,%ebx
f0106336:	89 de                	mov    %ebx,%esi
pci_attach_match(uint32_t key1, uint32_t key2,
		 struct pci_driver *list, struct pci_func *pcif)
{
	uint32_t i;

	for (i = 0; list[i].attachfn; i++) {
f0106338:	8b 03                	mov    (%ebx),%eax
f010633a:	85 c0                	test   %eax,%eax
f010633c:	75 be                	jne    f01062fc <pci_attach_match+0x14>
					"%x.%x (%p): e\n",
					key1, key2, list[i].attachfn, r);
		}
	}
	return 0;
}
f010633e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0106341:	5b                   	pop    %ebx
f0106342:	5e                   	pop    %esi
f0106343:	5f                   	pop    %edi
f0106344:	5d                   	pop    %ebp
f0106345:	c3                   	ret    

f0106346 <pci_conf1_set_addr>:
static void
pci_conf1_set_addr(uint32_t bus,
		   uint32_t dev,
		   uint32_t func,
		   uint32_t offset)
{
f0106346:	55                   	push   %ebp
f0106347:	89 e5                	mov    %esp,%ebp
f0106349:	53                   	push   %ebx
f010634a:	83 ec 04             	sub    $0x4,%esp
f010634d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	assert(bus < 256);
f0106350:	3d ff 00 00 00       	cmp    $0xff,%eax
f0106355:	76 16                	jbe    f010636d <pci_conf1_set_addr+0x27>
f0106357:	68 4c 8b 10 f0       	push   $0xf0108b4c
f010635c:	68 db 7a 10 f0       	push   $0xf0107adb
f0106361:	6a 2c                	push   $0x2c
f0106363:	68 56 8b 10 f0       	push   $0xf0108b56
f0106368:	e8 d3 9c ff ff       	call   f0100040 <_panic>
	assert(dev < 32);
f010636d:	83 fa 1f             	cmp    $0x1f,%edx
f0106370:	76 16                	jbe    f0106388 <pci_conf1_set_addr+0x42>
f0106372:	68 61 8b 10 f0       	push   $0xf0108b61
f0106377:	68 db 7a 10 f0       	push   $0xf0107adb
f010637c:	6a 2d                	push   $0x2d
f010637e:	68 56 8b 10 f0       	push   $0xf0108b56
f0106383:	e8 b8 9c ff ff       	call   f0100040 <_panic>
	assert(func < 8);
f0106388:	83 f9 07             	cmp    $0x7,%ecx
f010638b:	76 16                	jbe    f01063a3 <pci_conf1_set_addr+0x5d>
f010638d:	68 6a 8b 10 f0       	push   $0xf0108b6a
f0106392:	68 db 7a 10 f0       	push   $0xf0107adb
f0106397:	6a 2e                	push   $0x2e
f0106399:	68 56 8b 10 f0       	push   $0xf0108b56
f010639e:	e8 9d 9c ff ff       	call   f0100040 <_panic>
	assert(offset < 256);
f01063a3:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f01063a9:	76 16                	jbe    f01063c1 <pci_conf1_set_addr+0x7b>
f01063ab:	68 73 8b 10 f0       	push   $0xf0108b73
f01063b0:	68 db 7a 10 f0       	push   $0xf0107adb
f01063b5:	6a 2f                	push   $0x2f
f01063b7:	68 56 8b 10 f0       	push   $0xf0108b56
f01063bc:	e8 7f 9c ff ff       	call   f0100040 <_panic>
	assert((offset & 0x3) == 0);
f01063c1:	f6 c3 03             	test   $0x3,%bl
f01063c4:	74 16                	je     f01063dc <pci_conf1_set_addr+0x96>
f01063c6:	68 80 8b 10 f0       	push   $0xf0108b80
f01063cb:	68 db 7a 10 f0       	push   $0xf0107adb
f01063d0:	6a 30                	push   $0x30
f01063d2:	68 56 8b 10 f0       	push   $0xf0108b56
f01063d7:	e8 64 9c ff ff       	call   f0100040 <_panic>
f01063dc:	81 cb 00 00 00 80    	or     $0x80000000,%ebx

	uint32_t v = (1 << 31) |		// config-space
		(bus << 16) | (dev << 11) | (func << 8) | (offset);
f01063e2:	c1 e1 08             	shl    $0x8,%ecx
f01063e5:	09 d9                	or     %ebx,%ecx
f01063e7:	c1 e2 0b             	shl    $0xb,%edx
f01063ea:	09 ca                	or     %ecx,%edx
f01063ec:	c1 e0 10             	shl    $0x10,%eax
	assert(dev < 32);
	assert(func < 8);
	assert(offset < 256);
	assert((offset & 0x3) == 0);

	uint32_t v = (1 << 31) |		// config-space
f01063ef:	09 d0                	or     %edx,%eax
}

static __inline void
outl(int port, uint32_t data)
{
	__asm __volatile("outl %0,%w1" : : "a" (data), "d" (port));
f01063f1:	ba f8 0c 00 00       	mov    $0xcf8,%edx
f01063f6:	ef                   	out    %eax,(%dx)
		(bus << 16) | (dev << 11) | (func << 8) | (offset);
	outl(pci_conf1_addr_ioport, v);
}
f01063f7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01063fa:	c9                   	leave  
f01063fb:	c3                   	ret    

f01063fc <pci_conf_read>:

static uint32_t
pci_conf_read(struct pci_func *f, uint32_t off)
{
f01063fc:	55                   	push   %ebp
f01063fd:	89 e5                	mov    %esp,%ebp
f01063ff:	53                   	push   %ebx
f0106400:	83 ec 10             	sub    $0x10,%esp
	pci_conf1_set_addr(f->bus->busno, f->dev, f->func, off);
f0106403:	8b 48 08             	mov    0x8(%eax),%ecx
f0106406:	8b 58 04             	mov    0x4(%eax),%ebx
f0106409:	8b 00                	mov    (%eax),%eax
f010640b:	8b 40 04             	mov    0x4(%eax),%eax
f010640e:	52                   	push   %edx
f010640f:	89 da                	mov    %ebx,%edx
f0106411:	e8 30 ff ff ff       	call   f0106346 <pci_conf1_set_addr>

static __inline uint32_t
inl(int port)
{
	uint32_t data;
	__asm __volatile("inl %w1,%0" : "=a" (data) : "d" (port));
f0106416:	ba fc 0c 00 00       	mov    $0xcfc,%edx
f010641b:	ed                   	in     (%dx),%eax
	return inl(pci_conf1_data_ioport);
}
f010641c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010641f:	c9                   	leave  
f0106420:	c3                   	ret    

f0106421 <pci_scan_bus>:
		f->irq_line);
}

static int
pci_scan_bus(struct pci_bus *bus)
{
f0106421:	55                   	push   %ebp
f0106422:	89 e5                	mov    %esp,%ebp
f0106424:	57                   	push   %edi
f0106425:	56                   	push   %esi
f0106426:	53                   	push   %ebx
f0106427:	81 ec 00 01 00 00    	sub    $0x100,%esp
f010642d:	89 c3                	mov    %eax,%ebx
	int totaldev = 0;
	struct pci_func df;
	memset(&df, 0, sizeof(df));
f010642f:	6a 48                	push   $0x48
f0106431:	6a 00                	push   $0x0
f0106433:	8d 45 a0             	lea    -0x60(%ebp),%eax
f0106436:	50                   	push   %eax
f0106437:	e8 16 f0 ff ff       	call   f0105452 <memset>
	df.bus = bus;
f010643c:	89 5d a0             	mov    %ebx,-0x60(%ebp)

	for (df.dev = 0; df.dev < 32; df.dev++) {
f010643f:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f0106446:	83 c4 10             	add    $0x10,%esp
}

static int
pci_scan_bus(struct pci_bus *bus)
{
	int totaldev = 0;
f0106449:	c7 85 00 ff ff ff 00 	movl   $0x0,-0x100(%ebp)
f0106450:	00 00 00 
	struct pci_func df;
	memset(&df, 0, sizeof(df));
	df.bus = bus;

	for (df.dev = 0; df.dev < 32; df.dev++) {
		uint32_t bhlc = pci_conf_read(&df, PCI_BHLC_REG);
f0106453:	ba 0c 00 00 00       	mov    $0xc,%edx
f0106458:	8d 45 a0             	lea    -0x60(%ebp),%eax
f010645b:	e8 9c ff ff ff       	call   f01063fc <pci_conf_read>
		if (PCI_HDRTYPE_TYPE(bhlc) > 1)	    // Unsupported or no device
f0106460:	89 c2                	mov    %eax,%edx
f0106462:	c1 ea 10             	shr    $0x10,%edx
f0106465:	83 e2 7f             	and    $0x7f,%edx
f0106468:	83 fa 01             	cmp    $0x1,%edx
f010646b:	0f 87 45 01 00 00    	ja     f01065b6 <pci_scan_bus+0x195>
			continue;

		totaldev++;
f0106471:	83 85 00 ff ff ff 01 	addl   $0x1,-0x100(%ebp)

		struct pci_func f = df;
f0106478:	b9 12 00 00 00       	mov    $0x12,%ecx
f010647d:	8d bd 10 ff ff ff    	lea    -0xf0(%ebp),%edi
f0106483:	8d 75 a0             	lea    -0x60(%ebp),%esi
f0106486:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		for (f.func = 0; f.func < (PCI_HDRTYPE_MULTIFN(bhlc) ? 8 : 1);
f0106488:	c7 85 18 ff ff ff 00 	movl   $0x0,-0xe8(%ebp)
f010648f:	00 00 00 
f0106492:	25 00 00 80 00       	and    $0x800000,%eax
f0106497:	89 85 04 ff ff ff    	mov    %eax,-0xfc(%ebp)
		     f.func++) {
			struct pci_func af = f;
f010649d:	8d 9d 58 ff ff ff    	lea    -0xa8(%ebp),%ebx
			continue;

		totaldev++;

		struct pci_func f = df;
		for (f.func = 0; f.func < (PCI_HDRTYPE_MULTIFN(bhlc) ? 8 : 1);
f01064a3:	e9 f3 00 00 00       	jmp    f010659b <pci_scan_bus+0x17a>
		     f.func++) {
			struct pci_func af = f;
f01064a8:	b9 12 00 00 00       	mov    $0x12,%ecx
f01064ad:	89 df                	mov    %ebx,%edi
f01064af:	8d b5 10 ff ff ff    	lea    -0xf0(%ebp),%esi
f01064b5:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

			af.dev_id = pci_conf_read(&f, PCI_ID_REG);
f01064b7:	ba 00 00 00 00       	mov    $0x0,%edx
f01064bc:	8d 85 10 ff ff ff    	lea    -0xf0(%ebp),%eax
f01064c2:	e8 35 ff ff ff       	call   f01063fc <pci_conf_read>
f01064c7:	89 85 64 ff ff ff    	mov    %eax,-0x9c(%ebp)
			if (PCI_VENDOR(af.dev_id) == 0xffff)
f01064cd:	66 83 f8 ff          	cmp    $0xffff,%ax
f01064d1:	0f 84 bd 00 00 00    	je     f0106594 <pci_scan_bus+0x173>
				continue;

			uint32_t intr = pci_conf_read(&af, PCI_INTERRUPT_REG);
f01064d7:	ba 3c 00 00 00       	mov    $0x3c,%edx
f01064dc:	89 d8                	mov    %ebx,%eax
f01064de:	e8 19 ff ff ff       	call   f01063fc <pci_conf_read>
			af.irq_line = PCI_INTERRUPT_LINE(intr);
f01064e3:	88 45 9c             	mov    %al,-0x64(%ebp)

			af.dev_class = pci_conf_read(&af, PCI_CLASS_REG);
f01064e6:	ba 08 00 00 00       	mov    $0x8,%edx
f01064eb:	89 d8                	mov    %ebx,%eax
f01064ed:	e8 0a ff ff ff       	call   f01063fc <pci_conf_read>
f01064f2:	89 85 68 ff ff ff    	mov    %eax,-0x98(%ebp)

static void
pci_print_func(struct pci_func *f)
{
	const char *class = pci_class[0];
	if (PCI_CLASS(f->dev_class) < sizeof(pci_class) / sizeof(pci_class[0]))
f01064f8:	89 c2                	mov    %eax,%edx
f01064fa:	c1 ea 18             	shr    $0x18,%edx
};

static void
pci_print_func(struct pci_func *f)
{
	const char *class = pci_class[0];
f01064fd:	be 94 8b 10 f0       	mov    $0xf0108b94,%esi
	if (PCI_CLASS(f->dev_class) < sizeof(pci_class) / sizeof(pci_class[0]))
f0106502:	83 fa 06             	cmp    $0x6,%edx
f0106505:	77 07                	ja     f010650e <pci_scan_bus+0xed>
		class = pci_class[PCI_CLASS(f->dev_class)];
f0106507:	8b 34 95 08 8c 10 f0 	mov    -0xfef73f8(,%edx,4),%esi

	cprintf("PCI: %02x:%02x.%d: %04x:%04x: class: %x.%x (%s) irq: %d\n",
		f->bus->busno, f->dev, f->func,
		PCI_VENDOR(f->dev_id), PCI_PRODUCT(f->dev_id),
f010650e:	8b 8d 64 ff ff ff    	mov    -0x9c(%ebp),%ecx
{
	const char *class = pci_class[0];
	if (PCI_CLASS(f->dev_class) < sizeof(pci_class) / sizeof(pci_class[0]))
		class = pci_class[PCI_CLASS(f->dev_class)];

	cprintf("PCI: %02x:%02x.%d: %04x:%04x: class: %x.%x (%s) irq: %d\n",
f0106514:	83 ec 08             	sub    $0x8,%esp
f0106517:	0f b6 7d 9c          	movzbl -0x64(%ebp),%edi
f010651b:	57                   	push   %edi
f010651c:	56                   	push   %esi
		f->bus->busno, f->dev, f->func,
		PCI_VENDOR(f->dev_id), PCI_PRODUCT(f->dev_id),
		PCI_CLASS(f->dev_class), PCI_SUBCLASS(f->dev_class), class,
f010651d:	c1 e8 10             	shr    $0x10,%eax
{
	const char *class = pci_class[0];
	if (PCI_CLASS(f->dev_class) < sizeof(pci_class) / sizeof(pci_class[0]))
		class = pci_class[PCI_CLASS(f->dev_class)];

	cprintf("PCI: %02x:%02x.%d: %04x:%04x: class: %x.%x (%s) irq: %d\n",
f0106520:	0f b6 c0             	movzbl %al,%eax
f0106523:	50                   	push   %eax
f0106524:	52                   	push   %edx
f0106525:	89 c8                	mov    %ecx,%eax
f0106527:	c1 e8 10             	shr    $0x10,%eax
f010652a:	50                   	push   %eax
f010652b:	0f b7 c9             	movzwl %cx,%ecx
f010652e:	51                   	push   %ecx
f010652f:	ff b5 60 ff ff ff    	pushl  -0xa0(%ebp)
f0106535:	ff b5 5c ff ff ff    	pushl  -0xa4(%ebp)
f010653b:	8b 85 58 ff ff ff    	mov    -0xa8(%ebp),%eax
f0106541:	ff 70 04             	pushl  0x4(%eax)
f0106544:	68 20 8a 10 f0       	push   $0xf0108a20
f0106549:	e8 0b d3 ff ff       	call   f0103859 <cprintf>
static int
pci_attach(struct pci_func *f)
{
	return
		pci_attach_match(PCI_CLASS(f->dev_class),
				 PCI_SUBCLASS(f->dev_class),
f010654e:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax

static int
pci_attach(struct pci_func *f)
{
	return
		pci_attach_match(PCI_CLASS(f->dev_class),
f0106554:	83 c4 30             	add    $0x30,%esp
f0106557:	53                   	push   %ebx
f0106558:	68 0c 45 12 f0       	push   $0xf012450c
				 PCI_SUBCLASS(f->dev_class),
f010655d:	89 c2                	mov    %eax,%edx
f010655f:	c1 ea 10             	shr    $0x10,%edx

static int
pci_attach(struct pci_func *f)
{
	return
		pci_attach_match(PCI_CLASS(f->dev_class),
f0106562:	0f b6 d2             	movzbl %dl,%edx
f0106565:	52                   	push   %edx
f0106566:	c1 e8 18             	shr    $0x18,%eax
f0106569:	50                   	push   %eax
f010656a:	e8 79 fd ff ff       	call   f01062e8 <pci_attach_match>
				 PCI_SUBCLASS(f->dev_class),
				 &pci_attach_class[0], f) ||
f010656f:	83 c4 10             	add    $0x10,%esp
f0106572:	85 c0                	test   %eax,%eax
f0106574:	75 1e                	jne    f0106594 <pci_scan_bus+0x173>
		pci_attach_match(PCI_VENDOR(f->dev_id),
				 PCI_PRODUCT(f->dev_id),
f0106576:	8b 85 64 ff ff ff    	mov    -0x9c(%ebp),%eax
{
	return
		pci_attach_match(PCI_CLASS(f->dev_class),
				 PCI_SUBCLASS(f->dev_class),
				 &pci_attach_class[0], f) ||
		pci_attach_match(PCI_VENDOR(f->dev_id),
f010657c:	53                   	push   %ebx
f010657d:	68 f4 44 12 f0       	push   $0xf01244f4
f0106582:	89 c2                	mov    %eax,%edx
f0106584:	c1 ea 10             	shr    $0x10,%edx
f0106587:	52                   	push   %edx
f0106588:	0f b7 c0             	movzwl %ax,%eax
f010658b:	50                   	push   %eax
f010658c:	e8 57 fd ff ff       	call   f01062e8 <pci_attach_match>
f0106591:	83 c4 10             	add    $0x10,%esp

		totaldev++;

		struct pci_func f = df;
		for (f.func = 0; f.func < (PCI_HDRTYPE_MULTIFN(bhlc) ? 8 : 1);
		     f.func++) {
f0106594:	83 85 18 ff ff ff 01 	addl   $0x1,-0xe8(%ebp)
			continue;

		totaldev++;

		struct pci_func f = df;
		for (f.func = 0; f.func < (PCI_HDRTYPE_MULTIFN(bhlc) ? 8 : 1);
f010659b:	83 bd 04 ff ff ff 01 	cmpl   $0x1,-0xfc(%ebp)
f01065a2:	19 c0                	sbb    %eax,%eax
f01065a4:	83 e0 f9             	and    $0xfffffff9,%eax
f01065a7:	83 c0 08             	add    $0x8,%eax
f01065aa:	3b 85 18 ff ff ff    	cmp    -0xe8(%ebp),%eax
f01065b0:	0f 87 f2 fe ff ff    	ja     f01064a8 <pci_scan_bus+0x87>
	int totaldev = 0;
	struct pci_func df;
	memset(&df, 0, sizeof(df));
	df.bus = bus;

	for (df.dev = 0; df.dev < 32; df.dev++) {
f01065b6:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01065b9:	83 c0 01             	add    $0x1,%eax
f01065bc:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f01065bf:	83 f8 1f             	cmp    $0x1f,%eax
f01065c2:	0f 86 8b fe ff ff    	jbe    f0106453 <pci_scan_bus+0x32>
			pci_attach(&af);
		}
	}

	return totaldev;
}
f01065c8:	8b 85 00 ff ff ff    	mov    -0x100(%ebp),%eax
f01065ce:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01065d1:	5b                   	pop    %ebx
f01065d2:	5e                   	pop    %esi
f01065d3:	5f                   	pop    %edi
f01065d4:	5d                   	pop    %ebp
f01065d5:	c3                   	ret    

f01065d6 <pci_bridge_attach>:

static int
pci_bridge_attach(struct pci_func *pcif)
{
f01065d6:	55                   	push   %ebp
f01065d7:	89 e5                	mov    %esp,%ebp
f01065d9:	57                   	push   %edi
f01065da:	56                   	push   %esi
f01065db:	53                   	push   %ebx
f01065dc:	83 ec 1c             	sub    $0x1c,%esp
f01065df:	8b 5d 08             	mov    0x8(%ebp),%ebx
	uint32_t ioreg  = pci_conf_read(pcif, PCI_BRIDGE_STATIO_REG);
f01065e2:	ba 1c 00 00 00       	mov    $0x1c,%edx
f01065e7:	89 d8                	mov    %ebx,%eax
f01065e9:	e8 0e fe ff ff       	call   f01063fc <pci_conf_read>
f01065ee:	89 c7                	mov    %eax,%edi
	uint32_t busreg = pci_conf_read(pcif, PCI_BRIDGE_BUS_REG);
f01065f0:	ba 18 00 00 00       	mov    $0x18,%edx
f01065f5:	89 d8                	mov    %ebx,%eax
f01065f7:	e8 00 fe ff ff       	call   f01063fc <pci_conf_read>

	if (PCI_BRIDGE_IO_32BITS(ioreg)) {
f01065fc:	83 e7 0f             	and    $0xf,%edi
f01065ff:	83 ff 01             	cmp    $0x1,%edi
f0106602:	75 1f                	jne    f0106623 <pci_bridge_attach+0x4d>
		cprintf("PCI: %02x:%02x.%d: 32-bit bridge IO not supported.\n",
f0106604:	ff 73 08             	pushl  0x8(%ebx)
f0106607:	ff 73 04             	pushl  0x4(%ebx)
f010660a:	8b 03                	mov    (%ebx),%eax
f010660c:	ff 70 04             	pushl  0x4(%eax)
f010660f:	68 5c 8a 10 f0       	push   $0xf0108a5c
f0106614:	e8 40 d2 ff ff       	call   f0103859 <cprintf>
			pcif->bus->busno, pcif->dev, pcif->func);
		return 0;
f0106619:	83 c4 10             	add    $0x10,%esp
f010661c:	b8 00 00 00 00       	mov    $0x0,%eax
f0106621:	eb 4e                	jmp    f0106671 <pci_bridge_attach+0x9b>
f0106623:	89 c6                	mov    %eax,%esi
	}

	struct pci_bus nbus;
	memset(&nbus, 0, sizeof(nbus));
f0106625:	83 ec 04             	sub    $0x4,%esp
f0106628:	6a 08                	push   $0x8
f010662a:	6a 00                	push   $0x0
f010662c:	8d 7d e0             	lea    -0x20(%ebp),%edi
f010662f:	57                   	push   %edi
f0106630:	e8 1d ee ff ff       	call   f0105452 <memset>
	nbus.parent_bridge = pcif;
f0106635:	89 5d e0             	mov    %ebx,-0x20(%ebp)
	nbus.busno = (busreg >> PCI_BRIDGE_BUS_SECONDARY_SHIFT) & 0xff;
f0106638:	89 f0                	mov    %esi,%eax
f010663a:	0f b6 c4             	movzbl %ah,%eax
f010663d:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	if (pci_show_devs)
		cprintf("PCI: %02x:%02x.%d: bridge to PCI bus %d--%d\n",
f0106640:	83 c4 08             	add    $0x8,%esp
			pcif->bus->busno, pcif->dev, pcif->func,
			nbus.busno,
			(busreg >> PCI_BRIDGE_BUS_SUBORDINATE_SHIFT) & 0xff);
f0106643:	89 f2                	mov    %esi,%edx
f0106645:	c1 ea 10             	shr    $0x10,%edx
	memset(&nbus, 0, sizeof(nbus));
	nbus.parent_bridge = pcif;
	nbus.busno = (busreg >> PCI_BRIDGE_BUS_SECONDARY_SHIFT) & 0xff;

	if (pci_show_devs)
		cprintf("PCI: %02x:%02x.%d: bridge to PCI bus %d--%d\n",
f0106648:	0f b6 f2             	movzbl %dl,%esi
f010664b:	56                   	push   %esi
f010664c:	50                   	push   %eax
f010664d:	ff 73 08             	pushl  0x8(%ebx)
f0106650:	ff 73 04             	pushl  0x4(%ebx)
f0106653:	8b 03                	mov    (%ebx),%eax
f0106655:	ff 70 04             	pushl  0x4(%eax)
f0106658:	68 90 8a 10 f0       	push   $0xf0108a90
f010665d:	e8 f7 d1 ff ff       	call   f0103859 <cprintf>
			pcif->bus->busno, pcif->dev, pcif->func,
			nbus.busno,
			(busreg >> PCI_BRIDGE_BUS_SUBORDINATE_SHIFT) & 0xff);

	pci_scan_bus(&nbus);
f0106662:	83 c4 20             	add    $0x20,%esp
f0106665:	89 f8                	mov    %edi,%eax
f0106667:	e8 b5 fd ff ff       	call   f0106421 <pci_scan_bus>
	return 1;
f010666c:	b8 01 00 00 00       	mov    $0x1,%eax
}
f0106671:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0106674:	5b                   	pop    %ebx
f0106675:	5e                   	pop    %esi
f0106676:	5f                   	pop    %edi
f0106677:	5d                   	pop    %ebp
f0106678:	c3                   	ret    

f0106679 <pci_conf_write>:
	return inl(pci_conf1_data_ioport);
}

static void
pci_conf_write(struct pci_func *f, uint32_t off, uint32_t v)
{
f0106679:	55                   	push   %ebp
f010667a:	89 e5                	mov    %esp,%ebp
f010667c:	56                   	push   %esi
f010667d:	53                   	push   %ebx
f010667e:	89 cb                	mov    %ecx,%ebx
	pci_conf1_set_addr(f->bus->busno, f->dev, f->func, off);
f0106680:	83 ec 0c             	sub    $0xc,%esp
f0106683:	8b 48 08             	mov    0x8(%eax),%ecx
f0106686:	8b 70 04             	mov    0x4(%eax),%esi
f0106689:	8b 00                	mov    (%eax),%eax
f010668b:	8b 40 04             	mov    0x4(%eax),%eax
f010668e:	52                   	push   %edx
f010668f:	89 f2                	mov    %esi,%edx
f0106691:	e8 b0 fc ff ff       	call   f0106346 <pci_conf1_set_addr>
}

static __inline void
outl(int port, uint32_t data)
{
	__asm __volatile("outl %0,%w1" : : "a" (data), "d" (port));
f0106696:	ba fc 0c 00 00       	mov    $0xcfc,%edx
f010669b:	89 d8                	mov    %ebx,%eax
f010669d:	ef                   	out    %eax,(%dx)
f010669e:	83 c4 10             	add    $0x10,%esp
	outl(pci_conf1_data_ioport, v);
}
f01066a1:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01066a4:	5b                   	pop    %ebx
f01066a5:	5e                   	pop    %esi
f01066a6:	5d                   	pop    %ebp
f01066a7:	c3                   	ret    

f01066a8 <pci_func_enable>:

// External PCI subsystem interface

void
pci_func_enable(struct pci_func *f)
{
f01066a8:	55                   	push   %ebp
f01066a9:	89 e5                	mov    %esp,%ebp
f01066ab:	57                   	push   %edi
f01066ac:	56                   	push   %esi
f01066ad:	53                   	push   %ebx
f01066ae:	83 ec 1c             	sub    $0x1c,%esp
f01066b1:	8b 7d 08             	mov    0x8(%ebp),%edi
	pci_conf_write(f, PCI_COMMAND_STATUS_REG,
f01066b4:	b9 07 00 00 00       	mov    $0x7,%ecx
f01066b9:	ba 04 00 00 00       	mov    $0x4,%edx
f01066be:	89 f8                	mov    %edi,%eax
f01066c0:	e8 b4 ff ff ff       	call   f0106679 <pci_conf_write>
		       PCI_COMMAND_MEM_ENABLE |
		       PCI_COMMAND_MASTER_ENABLE);

	uint32_t bar_width;
	uint32_t bar;
	for (bar = PCI_MAPREG_START; bar < PCI_MAPREG_END;
f01066c5:	be 10 00 00 00       	mov    $0x10,%esi
	     bar += bar_width)
	{
		uint32_t oldv = pci_conf_read(f, bar);
f01066ca:	89 f2                	mov    %esi,%edx
f01066cc:	89 f8                	mov    %edi,%eax
f01066ce:	e8 29 fd ff ff       	call   f01063fc <pci_conf_read>
f01066d3:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		bar_width = 4;
		pci_conf_write(f, bar, 0xffffffff);
f01066d6:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
f01066db:	89 f2                	mov    %esi,%edx
f01066dd:	89 f8                	mov    %edi,%eax
f01066df:	e8 95 ff ff ff       	call   f0106679 <pci_conf_write>
		uint32_t rv = pci_conf_read(f, bar);
f01066e4:	89 f2                	mov    %esi,%edx
f01066e6:	89 f8                	mov    %edi,%eax
f01066e8:	e8 0f fd ff ff       	call   f01063fc <pci_conf_read>
	for (bar = PCI_MAPREG_START; bar < PCI_MAPREG_END;
	     bar += bar_width)
	{
		uint32_t oldv = pci_conf_read(f, bar);

		bar_width = 4;
f01066ed:	bb 04 00 00 00       	mov    $0x4,%ebx
		pci_conf_write(f, bar, 0xffffffff);
		uint32_t rv = pci_conf_read(f, bar);

		if (rv == 0)
f01066f2:	85 c0                	test   %eax,%eax
f01066f4:	0f 84 a6 00 00 00    	je     f01067a0 <pci_func_enable+0xf8>
			continue;

		int regnum = PCI_MAPREG_NUM(bar);
f01066fa:	8d 56 f0             	lea    -0x10(%esi),%edx
f01066fd:	c1 ea 02             	shr    $0x2,%edx
f0106700:	89 55 e0             	mov    %edx,-0x20(%ebp)
		uint32_t base, size;
		if (PCI_MAPREG_TYPE(rv) == PCI_MAPREG_TYPE_MEM) {
f0106703:	a8 01                	test   $0x1,%al
f0106705:	75 2c                	jne    f0106733 <pci_func_enable+0x8b>
			if (PCI_MAPREG_MEM_TYPE(rv) == PCI_MAPREG_MEM_TYPE_64BIT)
f0106707:	89 c2                	mov    %eax,%edx
f0106709:	83 e2 06             	and    $0x6,%edx
				bar_width = 8;
f010670c:	83 fa 04             	cmp    $0x4,%edx
f010670f:	0f 94 c3             	sete   %bl
f0106712:	0f b6 db             	movzbl %bl,%ebx
f0106715:	8d 1c 9d 04 00 00 00 	lea    0x4(,%ebx,4),%ebx

			size = PCI_MAPREG_MEM_SIZE(rv);
f010671c:	83 e0 f0             	and    $0xfffffff0,%eax
f010671f:	89 c2                	mov    %eax,%edx
f0106721:	f7 da                	neg    %edx
f0106723:	21 d0                	and    %edx,%eax
f0106725:	89 45 d8             	mov    %eax,-0x28(%ebp)
			base = PCI_MAPREG_MEM_ADDR(oldv);
f0106728:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010672b:	83 e0 f0             	and    $0xfffffff0,%eax
f010672e:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0106731:	eb 1a                	jmp    f010674d <pci_func_enable+0xa5>
			if (pci_show_addrs)
				cprintf("  mem region %d: %d bytes at 0x%x\n",
					regnum, size, base);
		} else {
			size = PCI_MAPREG_IO_SIZE(rv);
f0106733:	83 e0 fc             	and    $0xfffffffc,%eax
f0106736:	89 c2                	mov    %eax,%edx
f0106738:	f7 da                	neg    %edx
f010673a:	21 d0                	and    %edx,%eax
f010673c:	89 45 d8             	mov    %eax,-0x28(%ebp)
			base = PCI_MAPREG_IO_ADDR(oldv);
f010673f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0106742:	83 e0 fc             	and    $0xfffffffc,%eax
f0106745:	89 45 dc             	mov    %eax,-0x24(%ebp)
	for (bar = PCI_MAPREG_START; bar < PCI_MAPREG_END;
	     bar += bar_width)
	{
		uint32_t oldv = pci_conf_read(f, bar);

		bar_width = 4;
f0106748:	bb 04 00 00 00       	mov    $0x4,%ebx
			if (pci_show_addrs)
				cprintf("  io region %d: %d bytes at 0x%x\n",
					regnum, size, base);
		}

		pci_conf_write(f, bar, oldv);
f010674d:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0106750:	89 f2                	mov    %esi,%edx
f0106752:	89 f8                	mov    %edi,%eax
f0106754:	e8 20 ff ff ff       	call   f0106679 <pci_conf_write>
f0106759:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010675c:	8d 04 87             	lea    (%edi,%eax,4),%eax
		f->reg_base[regnum] = base;
f010675f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0106762:	89 48 14             	mov    %ecx,0x14(%eax)
		f->reg_size[regnum] = size;
f0106765:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0106768:	89 50 2c             	mov    %edx,0x2c(%eax)

		if (size && !base)
f010676b:	85 c9                	test   %ecx,%ecx
f010676d:	75 31                	jne    f01067a0 <pci_func_enable+0xf8>
f010676f:	85 d2                	test   %edx,%edx
f0106771:	74 2d                	je     f01067a0 <pci_func_enable+0xf8>
			cprintf("PCI device %02x:%02x.%d (%04x:%04x) "
				"may be misconfigured: "
				"region %d: base 0x%x, size %d\n",
				f->bus->busno, f->dev, f->func,
				PCI_VENDOR(f->dev_id), PCI_PRODUCT(f->dev_id),
f0106773:	8b 47 0c             	mov    0xc(%edi),%eax
		pci_conf_write(f, bar, oldv);
		f->reg_base[regnum] = base;
		f->reg_size[regnum] = size;

		if (size && !base)
			cprintf("PCI device %02x:%02x.%d (%04x:%04x) "
f0106776:	83 ec 0c             	sub    $0xc,%esp
f0106779:	52                   	push   %edx
f010677a:	51                   	push   %ecx
f010677b:	ff 75 e0             	pushl  -0x20(%ebp)
f010677e:	89 c2                	mov    %eax,%edx
f0106780:	c1 ea 10             	shr    $0x10,%edx
f0106783:	52                   	push   %edx
f0106784:	0f b7 c0             	movzwl %ax,%eax
f0106787:	50                   	push   %eax
f0106788:	ff 77 08             	pushl  0x8(%edi)
f010678b:	ff 77 04             	pushl  0x4(%edi)
f010678e:	8b 07                	mov    (%edi),%eax
f0106790:	ff 70 04             	pushl  0x4(%eax)
f0106793:	68 c0 8a 10 f0       	push   $0xf0108ac0
f0106798:	e8 bc d0 ff ff       	call   f0103859 <cprintf>
f010679d:	83 c4 30             	add    $0x30,%esp
		       PCI_COMMAND_MASTER_ENABLE);

	uint32_t bar_width;
	uint32_t bar;
	for (bar = PCI_MAPREG_START; bar < PCI_MAPREG_END;
	     bar += bar_width)
f01067a0:	01 de                	add    %ebx,%esi
		       PCI_COMMAND_MEM_ENABLE |
		       PCI_COMMAND_MASTER_ENABLE);

	uint32_t bar_width;
	uint32_t bar;
	for (bar = PCI_MAPREG_START; bar < PCI_MAPREG_END;
f01067a2:	83 fe 27             	cmp    $0x27,%esi
f01067a5:	0f 86 1f ff ff ff    	jbe    f01066ca <pci_func_enable+0x22>
				regnum, base, size);
	}

	cprintf("PCI function %02x:%02x.%d (%04x:%04x) enabled\n",
		f->bus->busno, f->dev, f->func,
		PCI_VENDOR(f->dev_id), PCI_PRODUCT(f->dev_id));
f01067ab:	8b 47 0c             	mov    0xc(%edi),%eax
				f->bus->busno, f->dev, f->func,
				PCI_VENDOR(f->dev_id), PCI_PRODUCT(f->dev_id),
				regnum, base, size);
	}

	cprintf("PCI function %02x:%02x.%d (%04x:%04x) enabled\n",
f01067ae:	83 ec 08             	sub    $0x8,%esp
f01067b1:	89 c2                	mov    %eax,%edx
f01067b3:	c1 ea 10             	shr    $0x10,%edx
f01067b6:	52                   	push   %edx
f01067b7:	0f b7 c0             	movzwl %ax,%eax
f01067ba:	50                   	push   %eax
f01067bb:	ff 77 08             	pushl  0x8(%edi)
f01067be:	ff 77 04             	pushl  0x4(%edi)
f01067c1:	8b 07                	mov    (%edi),%eax
f01067c3:	ff 70 04             	pushl  0x4(%eax)
f01067c6:	68 1c 8b 10 f0       	push   $0xf0108b1c
f01067cb:	e8 89 d0 ff ff       	call   f0103859 <cprintf>
f01067d0:	83 c4 20             	add    $0x20,%esp
		f->bus->busno, f->dev, f->func,
		PCI_VENDOR(f->dev_id), PCI_PRODUCT(f->dev_id));
}
f01067d3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01067d6:	5b                   	pop    %ebx
f01067d7:	5e                   	pop    %esi
f01067d8:	5f                   	pop    %edi
f01067d9:	5d                   	pop    %ebp
f01067da:	c3                   	ret    

f01067db <pci_init>:

int
pci_init(void)
{
f01067db:	55                   	push   %ebp
f01067dc:	89 e5                	mov    %esp,%ebp
f01067de:	83 ec 0c             	sub    $0xc,%esp
	static struct pci_bus root_bus;
	memset(&root_bus, 0, sizeof(root_bus));
f01067e1:	6a 08                	push   $0x8
f01067e3:	6a 00                	push   $0x0
f01067e5:	68 c0 9e 2a f0       	push   $0xf02a9ec0
f01067ea:	e8 63 ec ff ff       	call   f0105452 <memset>

	return pci_scan_bus(&root_bus);
f01067ef:	b8 c0 9e 2a f0       	mov    $0xf02a9ec0,%eax
f01067f4:	e8 28 fc ff ff       	call   f0106421 <pci_scan_bus>
}
f01067f9:	c9                   	leave  
f01067fa:	c3                   	ret    

f01067fb <time_init>:

static unsigned int ticks;

void
time_init(void)
{
f01067fb:	55                   	push   %ebp
f01067fc:	89 e5                	mov    %esp,%ebp
	ticks = 0;
f01067fe:	c7 05 c8 9e 2a f0 00 	movl   $0x0,0xf02a9ec8
f0106805:	00 00 00 
}
f0106808:	5d                   	pop    %ebp
f0106809:	c3                   	ret    

f010680a <time_tick>:
// This should be called once per timer interrupt.  A timer interrupt
// fires every 10 ms.
void
time_tick(void)
{
	ticks++;
f010680a:	a1 c8 9e 2a f0       	mov    0xf02a9ec8,%eax
f010680f:	83 c0 01             	add    $0x1,%eax
f0106812:	a3 c8 9e 2a f0       	mov    %eax,0xf02a9ec8
	if (ticks * 10 < ticks)
f0106817:	8d 14 80             	lea    (%eax,%eax,4),%edx
f010681a:	01 d2                	add    %edx,%edx
f010681c:	39 d0                	cmp    %edx,%eax
f010681e:	76 17                	jbe    f0106837 <time_tick+0x2d>

// This should be called once per timer interrupt.  A timer interrupt
// fires every 10 ms.
void
time_tick(void)
{
f0106820:	55                   	push   %ebp
f0106821:	89 e5                	mov    %esp,%ebp
f0106823:	83 ec 0c             	sub    $0xc,%esp
	ticks++;
	if (ticks * 10 < ticks)
		panic("time_tick: time overflowed");
f0106826:	68 24 8c 10 f0       	push   $0xf0108c24
f010682b:	6a 13                	push   $0x13
f010682d:	68 3f 8c 10 f0       	push   $0xf0108c3f
f0106832:	e8 09 98 ff ff       	call   f0100040 <_panic>
f0106837:	f3 c3                	repz ret 

f0106839 <time_msec>:
}

unsigned int
time_msec(void)
{
f0106839:	55                   	push   %ebp
f010683a:	89 e5                	mov    %esp,%ebp
	return ticks * 10;
f010683c:	a1 c8 9e 2a f0       	mov    0xf02a9ec8,%eax
f0106841:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0106844:	01 c0                	add    %eax,%eax
}
f0106846:	5d                   	pop    %ebp
f0106847:	c3                   	ret    
f0106848:	66 90                	xchg   %ax,%ax
f010684a:	66 90                	xchg   %ax,%ax
f010684c:	66 90                	xchg   %ax,%ax
f010684e:	66 90                	xchg   %ax,%ax

f0106850 <__udivdi3>:
f0106850:	55                   	push   %ebp
f0106851:	57                   	push   %edi
f0106852:	56                   	push   %esi
f0106853:	83 ec 10             	sub    $0x10,%esp
f0106856:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f010685a:	8b 7c 24 20          	mov    0x20(%esp),%edi
f010685e:	8b 74 24 24          	mov    0x24(%esp),%esi
f0106862:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0106866:	85 d2                	test   %edx,%edx
f0106868:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010686c:	89 34 24             	mov    %esi,(%esp)
f010686f:	89 c8                	mov    %ecx,%eax
f0106871:	75 35                	jne    f01068a8 <__udivdi3+0x58>
f0106873:	39 f1                	cmp    %esi,%ecx
f0106875:	0f 87 bd 00 00 00    	ja     f0106938 <__udivdi3+0xe8>
f010687b:	85 c9                	test   %ecx,%ecx
f010687d:	89 cd                	mov    %ecx,%ebp
f010687f:	75 0b                	jne    f010688c <__udivdi3+0x3c>
f0106881:	b8 01 00 00 00       	mov    $0x1,%eax
f0106886:	31 d2                	xor    %edx,%edx
f0106888:	f7 f1                	div    %ecx
f010688a:	89 c5                	mov    %eax,%ebp
f010688c:	89 f0                	mov    %esi,%eax
f010688e:	31 d2                	xor    %edx,%edx
f0106890:	f7 f5                	div    %ebp
f0106892:	89 c6                	mov    %eax,%esi
f0106894:	89 f8                	mov    %edi,%eax
f0106896:	f7 f5                	div    %ebp
f0106898:	89 f2                	mov    %esi,%edx
f010689a:	83 c4 10             	add    $0x10,%esp
f010689d:	5e                   	pop    %esi
f010689e:	5f                   	pop    %edi
f010689f:	5d                   	pop    %ebp
f01068a0:	c3                   	ret    
f01068a1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01068a8:	3b 14 24             	cmp    (%esp),%edx
f01068ab:	77 7b                	ja     f0106928 <__udivdi3+0xd8>
f01068ad:	0f bd f2             	bsr    %edx,%esi
f01068b0:	83 f6 1f             	xor    $0x1f,%esi
f01068b3:	0f 84 97 00 00 00    	je     f0106950 <__udivdi3+0x100>
f01068b9:	bd 20 00 00 00       	mov    $0x20,%ebp
f01068be:	89 d7                	mov    %edx,%edi
f01068c0:	89 f1                	mov    %esi,%ecx
f01068c2:	29 f5                	sub    %esi,%ebp
f01068c4:	d3 e7                	shl    %cl,%edi
f01068c6:	89 c2                	mov    %eax,%edx
f01068c8:	89 e9                	mov    %ebp,%ecx
f01068ca:	d3 ea                	shr    %cl,%edx
f01068cc:	89 f1                	mov    %esi,%ecx
f01068ce:	09 fa                	or     %edi,%edx
f01068d0:	8b 3c 24             	mov    (%esp),%edi
f01068d3:	d3 e0                	shl    %cl,%eax
f01068d5:	89 54 24 08          	mov    %edx,0x8(%esp)
f01068d9:	89 e9                	mov    %ebp,%ecx
f01068db:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01068df:	8b 44 24 04          	mov    0x4(%esp),%eax
f01068e3:	89 fa                	mov    %edi,%edx
f01068e5:	d3 ea                	shr    %cl,%edx
f01068e7:	89 f1                	mov    %esi,%ecx
f01068e9:	d3 e7                	shl    %cl,%edi
f01068eb:	89 e9                	mov    %ebp,%ecx
f01068ed:	d3 e8                	shr    %cl,%eax
f01068ef:	09 c7                	or     %eax,%edi
f01068f1:	89 f8                	mov    %edi,%eax
f01068f3:	f7 74 24 08          	divl   0x8(%esp)
f01068f7:	89 d5                	mov    %edx,%ebp
f01068f9:	89 c7                	mov    %eax,%edi
f01068fb:	f7 64 24 0c          	mull   0xc(%esp)
f01068ff:	39 d5                	cmp    %edx,%ebp
f0106901:	89 14 24             	mov    %edx,(%esp)
f0106904:	72 11                	jb     f0106917 <__udivdi3+0xc7>
f0106906:	8b 54 24 04          	mov    0x4(%esp),%edx
f010690a:	89 f1                	mov    %esi,%ecx
f010690c:	d3 e2                	shl    %cl,%edx
f010690e:	39 c2                	cmp    %eax,%edx
f0106910:	73 5e                	jae    f0106970 <__udivdi3+0x120>
f0106912:	3b 2c 24             	cmp    (%esp),%ebp
f0106915:	75 59                	jne    f0106970 <__udivdi3+0x120>
f0106917:	8d 47 ff             	lea    -0x1(%edi),%eax
f010691a:	31 f6                	xor    %esi,%esi
f010691c:	89 f2                	mov    %esi,%edx
f010691e:	83 c4 10             	add    $0x10,%esp
f0106921:	5e                   	pop    %esi
f0106922:	5f                   	pop    %edi
f0106923:	5d                   	pop    %ebp
f0106924:	c3                   	ret    
f0106925:	8d 76 00             	lea    0x0(%esi),%esi
f0106928:	31 f6                	xor    %esi,%esi
f010692a:	31 c0                	xor    %eax,%eax
f010692c:	89 f2                	mov    %esi,%edx
f010692e:	83 c4 10             	add    $0x10,%esp
f0106931:	5e                   	pop    %esi
f0106932:	5f                   	pop    %edi
f0106933:	5d                   	pop    %ebp
f0106934:	c3                   	ret    
f0106935:	8d 76 00             	lea    0x0(%esi),%esi
f0106938:	89 f2                	mov    %esi,%edx
f010693a:	31 f6                	xor    %esi,%esi
f010693c:	89 f8                	mov    %edi,%eax
f010693e:	f7 f1                	div    %ecx
f0106940:	89 f2                	mov    %esi,%edx
f0106942:	83 c4 10             	add    $0x10,%esp
f0106945:	5e                   	pop    %esi
f0106946:	5f                   	pop    %edi
f0106947:	5d                   	pop    %ebp
f0106948:	c3                   	ret    
f0106949:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106950:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f0106954:	76 0b                	jbe    f0106961 <__udivdi3+0x111>
f0106956:	31 c0                	xor    %eax,%eax
f0106958:	3b 14 24             	cmp    (%esp),%edx
f010695b:	0f 83 37 ff ff ff    	jae    f0106898 <__udivdi3+0x48>
f0106961:	b8 01 00 00 00       	mov    $0x1,%eax
f0106966:	e9 2d ff ff ff       	jmp    f0106898 <__udivdi3+0x48>
f010696b:	90                   	nop
f010696c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106970:	89 f8                	mov    %edi,%eax
f0106972:	31 f6                	xor    %esi,%esi
f0106974:	e9 1f ff ff ff       	jmp    f0106898 <__udivdi3+0x48>
f0106979:	66 90                	xchg   %ax,%ax
f010697b:	66 90                	xchg   %ax,%ax
f010697d:	66 90                	xchg   %ax,%ax
f010697f:	90                   	nop

f0106980 <__umoddi3>:
f0106980:	55                   	push   %ebp
f0106981:	57                   	push   %edi
f0106982:	56                   	push   %esi
f0106983:	83 ec 20             	sub    $0x20,%esp
f0106986:	8b 44 24 34          	mov    0x34(%esp),%eax
f010698a:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010698e:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0106992:	89 c6                	mov    %eax,%esi
f0106994:	89 44 24 10          	mov    %eax,0x10(%esp)
f0106998:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f010699c:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f01069a0:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01069a4:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f01069a8:	89 74 24 18          	mov    %esi,0x18(%esp)
f01069ac:	85 c0                	test   %eax,%eax
f01069ae:	89 c2                	mov    %eax,%edx
f01069b0:	75 1e                	jne    f01069d0 <__umoddi3+0x50>
f01069b2:	39 f7                	cmp    %esi,%edi
f01069b4:	76 52                	jbe    f0106a08 <__umoddi3+0x88>
f01069b6:	89 c8                	mov    %ecx,%eax
f01069b8:	89 f2                	mov    %esi,%edx
f01069ba:	f7 f7                	div    %edi
f01069bc:	89 d0                	mov    %edx,%eax
f01069be:	31 d2                	xor    %edx,%edx
f01069c0:	83 c4 20             	add    $0x20,%esp
f01069c3:	5e                   	pop    %esi
f01069c4:	5f                   	pop    %edi
f01069c5:	5d                   	pop    %ebp
f01069c6:	c3                   	ret    
f01069c7:	89 f6                	mov    %esi,%esi
f01069c9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f01069d0:	39 f0                	cmp    %esi,%eax
f01069d2:	77 5c                	ja     f0106a30 <__umoddi3+0xb0>
f01069d4:	0f bd e8             	bsr    %eax,%ebp
f01069d7:	83 f5 1f             	xor    $0x1f,%ebp
f01069da:	75 64                	jne    f0106a40 <__umoddi3+0xc0>
f01069dc:	8b 6c 24 14          	mov    0x14(%esp),%ebp
f01069e0:	39 6c 24 0c          	cmp    %ebp,0xc(%esp)
f01069e4:	0f 86 f6 00 00 00    	jbe    f0106ae0 <__umoddi3+0x160>
f01069ea:	3b 44 24 18          	cmp    0x18(%esp),%eax
f01069ee:	0f 82 ec 00 00 00    	jb     f0106ae0 <__umoddi3+0x160>
f01069f4:	8b 44 24 14          	mov    0x14(%esp),%eax
f01069f8:	8b 54 24 18          	mov    0x18(%esp),%edx
f01069fc:	83 c4 20             	add    $0x20,%esp
f01069ff:	5e                   	pop    %esi
f0106a00:	5f                   	pop    %edi
f0106a01:	5d                   	pop    %ebp
f0106a02:	c3                   	ret    
f0106a03:	90                   	nop
f0106a04:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106a08:	85 ff                	test   %edi,%edi
f0106a0a:	89 fd                	mov    %edi,%ebp
f0106a0c:	75 0b                	jne    f0106a19 <__umoddi3+0x99>
f0106a0e:	b8 01 00 00 00       	mov    $0x1,%eax
f0106a13:	31 d2                	xor    %edx,%edx
f0106a15:	f7 f7                	div    %edi
f0106a17:	89 c5                	mov    %eax,%ebp
f0106a19:	8b 44 24 10          	mov    0x10(%esp),%eax
f0106a1d:	31 d2                	xor    %edx,%edx
f0106a1f:	f7 f5                	div    %ebp
f0106a21:	89 c8                	mov    %ecx,%eax
f0106a23:	f7 f5                	div    %ebp
f0106a25:	eb 95                	jmp    f01069bc <__umoddi3+0x3c>
f0106a27:	89 f6                	mov    %esi,%esi
f0106a29:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0106a30:	89 c8                	mov    %ecx,%eax
f0106a32:	89 f2                	mov    %esi,%edx
f0106a34:	83 c4 20             	add    $0x20,%esp
f0106a37:	5e                   	pop    %esi
f0106a38:	5f                   	pop    %edi
f0106a39:	5d                   	pop    %ebp
f0106a3a:	c3                   	ret    
f0106a3b:	90                   	nop
f0106a3c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106a40:	b8 20 00 00 00       	mov    $0x20,%eax
f0106a45:	89 e9                	mov    %ebp,%ecx
f0106a47:	29 e8                	sub    %ebp,%eax
f0106a49:	d3 e2                	shl    %cl,%edx
f0106a4b:	89 c7                	mov    %eax,%edi
f0106a4d:	89 44 24 18          	mov    %eax,0x18(%esp)
f0106a51:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0106a55:	89 f9                	mov    %edi,%ecx
f0106a57:	d3 e8                	shr    %cl,%eax
f0106a59:	89 c1                	mov    %eax,%ecx
f0106a5b:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0106a5f:	09 d1                	or     %edx,%ecx
f0106a61:	89 fa                	mov    %edi,%edx
f0106a63:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0106a67:	89 e9                	mov    %ebp,%ecx
f0106a69:	d3 e0                	shl    %cl,%eax
f0106a6b:	89 f9                	mov    %edi,%ecx
f0106a6d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0106a71:	89 f0                	mov    %esi,%eax
f0106a73:	d3 e8                	shr    %cl,%eax
f0106a75:	89 e9                	mov    %ebp,%ecx
f0106a77:	89 c7                	mov    %eax,%edi
f0106a79:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0106a7d:	d3 e6                	shl    %cl,%esi
f0106a7f:	89 d1                	mov    %edx,%ecx
f0106a81:	89 fa                	mov    %edi,%edx
f0106a83:	d3 e8                	shr    %cl,%eax
f0106a85:	89 e9                	mov    %ebp,%ecx
f0106a87:	09 f0                	or     %esi,%eax
f0106a89:	8b 74 24 1c          	mov    0x1c(%esp),%esi
f0106a8d:	f7 74 24 10          	divl   0x10(%esp)
f0106a91:	d3 e6                	shl    %cl,%esi
f0106a93:	89 d1                	mov    %edx,%ecx
f0106a95:	f7 64 24 0c          	mull   0xc(%esp)
f0106a99:	39 d1                	cmp    %edx,%ecx
f0106a9b:	89 74 24 14          	mov    %esi,0x14(%esp)
f0106a9f:	89 d7                	mov    %edx,%edi
f0106aa1:	89 c6                	mov    %eax,%esi
f0106aa3:	72 0a                	jb     f0106aaf <__umoddi3+0x12f>
f0106aa5:	39 44 24 14          	cmp    %eax,0x14(%esp)
f0106aa9:	73 10                	jae    f0106abb <__umoddi3+0x13b>
f0106aab:	39 d1                	cmp    %edx,%ecx
f0106aad:	75 0c                	jne    f0106abb <__umoddi3+0x13b>
f0106aaf:	89 d7                	mov    %edx,%edi
f0106ab1:	89 c6                	mov    %eax,%esi
f0106ab3:	2b 74 24 0c          	sub    0xc(%esp),%esi
f0106ab7:	1b 7c 24 10          	sbb    0x10(%esp),%edi
f0106abb:	89 ca                	mov    %ecx,%edx
f0106abd:	89 e9                	mov    %ebp,%ecx
f0106abf:	8b 44 24 14          	mov    0x14(%esp),%eax
f0106ac3:	29 f0                	sub    %esi,%eax
f0106ac5:	19 fa                	sbb    %edi,%edx
f0106ac7:	d3 e8                	shr    %cl,%eax
f0106ac9:	0f b6 4c 24 18       	movzbl 0x18(%esp),%ecx
f0106ace:	89 d7                	mov    %edx,%edi
f0106ad0:	d3 e7                	shl    %cl,%edi
f0106ad2:	89 e9                	mov    %ebp,%ecx
f0106ad4:	09 f8                	or     %edi,%eax
f0106ad6:	d3 ea                	shr    %cl,%edx
f0106ad8:	83 c4 20             	add    $0x20,%esp
f0106adb:	5e                   	pop    %esi
f0106adc:	5f                   	pop    %edi
f0106add:	5d                   	pop    %ebp
f0106ade:	c3                   	ret    
f0106adf:	90                   	nop
f0106ae0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0106ae4:	29 f9                	sub    %edi,%ecx
f0106ae6:	19 c6                	sbb    %eax,%esi
f0106ae8:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0106aec:	89 74 24 18          	mov    %esi,0x18(%esp)
f0106af0:	e9 ff fe ff ff       	jmp    f01069f4 <__umoddi3+0x74>
